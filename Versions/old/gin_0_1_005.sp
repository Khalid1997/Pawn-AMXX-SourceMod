#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "0.1.005"

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <matchsystem_stocks>
#include <matchsystem_const>

/*
New:
	* First 'stable' version
	* Team score notification.
	* Custom PrintToChat function
	* Added Prefix support
	* A lot of chat messages
	
To Do:
	* Late load / reload support.
	* Natives
	* Check Ready and not ready clan tag if working properly
	* Implement Ban system.
	* Add check for match end (prop shutdown server)
	* Add check for match players and how many are in a match (incase one of them abandoned)
*/

public Plugin myinfo = 
{
	name = "Match System",
	author = PLUGIN_AUTHOR,
	description = "Hi",
	version = PLUGIN_VERSION,
	url = "None"
};

// -------------------------------------------
// 				Start: Constants
// -------------------------------------------
#define MAX_TEAM_PLAYERS 1
stock const int MATCH_PLAYERS_COUNT = (MAX_TEAM_PLAYERS * 2);

#define NUMBER_RESTARTS		3
//#define ALLOW_ADMINS_JOIN

#define DELAY_RESTART_KNIFE_ROUND 5

#define MAX_OUTSIDE_CLIENTS	2
int g_iOutsideClients;

#define WARMUP_RESPAWN_TIME	3.0

new const String:g_szConfigFolder[] = "matchsystem";
new const String:g_szWarmUpConfig[] = "warmup.cfg";
new const String:g_szMatchConfig[] = "match.cfg";
new const String:g_szKnifeRoundConfig[] = "knife_round.cfg";

// -------------------------------------------
// 				Start: Match Vars
// -------------------------------------------
enum MatchState
{
	Match_Waiting,
	Match_KnifeRound,
	Match_TeamChoose,
	Match_WaitingSecond,			// This is after the team choose.
	Match_Restarts,
	Match_Running
};

MatchState gMatchState = Match_Waiting;

Database g_hSql;
char	g_szQuery[512];

bool g_bAllowRespawn = false;

int g_iChoosingTeam;

// -------------------------------------------
// 				Start: Player Vars
// -------------------------------------------
enum Players
{
	Player_None,
	Player_Checking,		// Still connecting to the database to check the player. // Do later
	Player_Player,			// Player who partipates in match.
	Player_Admin,			// Admin
	Player_Spectator		// Do this later (Spectators defined in database)
};

Players gPlayerState[MAXPLAYERS];

bool g_bReady[MAXPLAYERS + 1];
int g_iReadyCount;

int	g_iTeam[MAXPLAYERS + 1];


// Do later
//Trie DisconnectInfo;
bool g_bKicked[MAXPLAYERS + 1];

char g_szOriginalClanTag[MAXPLAYERS + 1][MAX_NAME_LENGTH];


DataPack g_hRestartsPack;
int g_iRestarts;
int g_iNumRestarts;
int g_bRestarting;

// -------------------------------------------
// 				Start: ConVars
// -------------------------------------------
ConVar	ConVar_ServerAddress,
		ConVar_KnifeRound_Enabled,
		ConVar_KnifeRound_DisarmC4;
		
char	g_szServerAddress[20];
bool	g_bKnifeRound_Enabled,
		g_bKnifeRound_DisarmC4;
		
//ConVar	ConVar_RestartGame;

bool g_bLate;

float	g_flDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int 	g_iHits[MAXPLAYERS + 1][MAXPLAYERS + 1];
int		g_iKiller[MAXPLAYERS + 1];

// -------------------------------------------
// 				Start: Plugin
// -------------------------------------------
// Do compatibility for late load (final thing)
public APLRes AskPluginLoad2(Handle plugin, bool bLate, char[] szError, int iErrMax)
{
	if(bLate)
	{
		LogError("Plugin cannot run late. Please restart the map");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hRestartsPack = CreateDataPack();
	
	AddCommandListener(ClCmd_JoinTeam, "jointeam");
	AddCommandListener(ClCmd_Say, "say");
	AddCommandListener(ClCmd_Say, "say_team");
	
	ConVar_ServerAddress = CreateConVar("ms_server_address", "", "Leave blank to try to auto detect. (IP:Port)");
	ConVar_KnifeRound_Enabled = CreateConVar("ms_kniferound_enabled", "1", "Enable knife rounds for choosing sides");
	ConVar_KnifeRound_DisarmC4 = CreateConVar("ms_kniferound_disarm_c4", "1", "Disarm C4 during knife round");
	
	ConVar_ServerAddress.AddChangeHook(ConVarHook_Changed);
	ConVar_KnifeRound_Enabled.AddChangeHook(ConVarHook_Changed);
	ConVar_KnifeRound_DisarmC4.AddChangeHook(ConVarHook_Changed);
	
	g_bKnifeRound_Enabled = GetConVarBool(ConVar_KnifeRound_Enabled);
	g_bKnifeRound_DisarmC4 = GetConVarBool(ConVar_KnifeRound_DisarmC4);
	
	//ConVar_RestartGame = CreateConVar("mp_restartgame", "");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end",	Event_RoundEnd, EventHookMode_Post);
	
	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
}

public void OnMapStart()
{
	SetMatchState(Match_Waiting);
	
	g_iReadyCount = 0;
	g_iRestarts = 0;
	g_bRestarting = false;
	g_iNumRestarts = 0;
}

public void OnConfigsExecuted()
{
	ExecuteConfig(g_szWarmUpConfig);
}

public void Event_PlayerTeam(Event event, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(gPlayerState[client] != Player_Player)
	{
		return;
	}
	
	if(gMatchState == Match_Waiting || gMatchState == Match_WaitingSecond)
	{
		ChangeToReadyClanTag(client);
	}
}

public Action Event_PlayerChangeName(Event event, const char[] szEventName, bool bDontBroadcast)
{
	PrintToServer("Called Name Change");	
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] szEventName, bool bDontBroadcast)
{
	PrintToServer("Round Start");
	
	PrintToServer("Restarting %d, iRestart : %d %d", g_bRestarting, g_iRestarts + 1, g_iNumRestarts);
	PrintToServer("gMatchState = %d", gMatchState);
	
	if(g_bRestarting)
	{
		PrintToServer("Restarting, iRestart : %d %d", g_iRestarts + 1, g_iNumRestarts);
		if(++g_iRestarts < g_iNumRestarts)
		{	
			//SetConVarInt(ConVar_RestartGame, 1);
		
			int iDelay = ReadPackCell(g_hRestartsPack);
			ServerCommand("mp_restartgame %d", iDelay);
		}
		
		else if(g_iRestarts >= g_iNumRestarts)
		{
			RestartsDone();
			return;
		}
	}
	
	if(gMatchState == Match_Running)
	{
		int iCTScore = GetTeamScore(CS_TEAM_CT), iTScore = GetTeamScore(CS_TEAM_T);
		
		if(iCTScore == iTScore)
		{
			//PrintToChatAll(" %d", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
			Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "Score is tied: %d-%d", iCTScore, iTScore);
		}
		
		else if(iCTScore > iTScore)
		{
			Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "The Counter-Terrorists team is winning: %d-%d", iCTScore, iTScore);
		}
		
		else
		{
			Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "The Terrorists team is winning: %d-%d", iTScore, iCTScore);
		}
	}
	
	else if(gMatchState == Match_TeamChoose)
	{
		int client = GetRandomClient(g_iChoosingTeam);
	
		Custom_PrintToChat(client, PLUGIN_CHAT_PREFIX, "Choose the starting team");
	
		Menu hMenu = CreateMenu(MenuHandler_TeamChoose, MENU_ACTIONS_DEFAULT);
		char szInfo[3];
		IntToString(CS_TEAM_T, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Terrorists");
		
		IntToString(CS_TEAM_CT, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Counter-Terrorists");
		
		IntToString(CS_TEAM_SPECTATOR, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Random");
		
		hMenu.ExitBackButton = false;
		
		hMenu.Display(client, MENU_TIME_FOREVER);
		
		PrintToServer("---- MENU DISPLAYED");
	}
	
	SetArrayValue(g_iKiller, sizeof g_iKiller, 0, 0);
	for(int i = 1, j; i <= MaxClients; i++)
	{
		for(j = 1; j <= MaxClients; j++)
		{
			g_flDamage[i][j] = 0.0;
			g_iHits[i][j] = 0;
		}
	}
}

RestartsDone()
{
	g_bRestarting = false;
	
	if(gMatchState == Match_Restarts)
	{
		SetMatchState(Match_Running);
		//ExecuteConfig(g_szMatchConfig);
		
		Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX,"Match is live, Good luck & Have fun.");
	}
	
	else if(gMatchState == Match_KnifeRound)
	{
		Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "--- Knife Round ---");
		Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "Win to choose the starting team.");
	}
}

int GetRandomClient(int iTeam = -1)
{
	int iPlayers[MAXPLAYERS + 1], iCount;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))
		{
			continue;
		}
			
		if(iTeam != -1 && GetClientTeam(client) != g_iChoosingTeam)
		{
			continue;
		}
			
		iPlayers[iCount++] = client;
	}
	
	return iCount ? iPlayers[GetRandomInt(0, iCount - 1)] : -1;
}

public int MenuHandler_TeamChoose(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			if(param1 == MenuEnd_Selected)
			{
				delete menu;
			}
		}
		
		case MenuAction_Select:
		{
			int iTeamSelection;
			char szDump[3];
			
			menu.GetItem(param2, szDump, sizeof szDump);
			iTeamSelection = StringToInt(szDump);
			
			if(iTeamSelection == CS_TEAM_SPECTATOR)
			{
				iTeamSelection = GetRandomInt(0, 1) ? CS_TEAM_CT : CS_TEAM_T;
			}
			
			int iOtherTeam = iTeamSelection == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
			Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "The %s team chose %s", g_iTeam[param1] == CS_TEAM_T ? "Terrorist" : "Counter-Terrorists", iTeamSelection == CS_TEAM_T ? "Terrorist" : "Counter-Terrorists");
			
			for(int client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client) || gPlayerState[client] != Player_Player)
				{
					continue;
				}
				
				if(g_iTeam[client] == g_iChoosingTeam)
				{
					g_iTeam[client] = iTeamSelection;
				}
				
				else	g_iTeam[client] = iOtherTeam;
			}
			
			

			//PutPlayersInTeams();
			SetMatchState(Match_WaitingSecond);
		}
		
		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_Disconnected:
				{
					// Do if no other play is connected.
					menu.Display(GetRandomClient(g_iChoosingTeam), MENU_TIME_FOREVER);
				}
				
				default:
				{
					menu.Display(param1, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] szEventName, bool bDontBroadcast)
{
	// Do compatibility for hostage maps
	if(gMatchState == Match_KnifeRound)
	{
		//PrintToServer("MatchState Knife Roun #1d");
		
		CSRoundEndReason iEndReason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
		int iWinningTeam = GetEventInt(event, "winner");
		
		//PrintToChatAll("RoundEnd End Reason = %d", iEndReason);
		if(iEndReason == 8 || iEndReason == 7 || iEndReason == 9)
		{
			PrintToServer("Ennd Reason Valid");
			int iOtherTeam = (iWinningTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T);
			
			bool bEliminated = true;
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i))
				{
					continue;
				}
				
				if(GetClientTeam(i) == iOtherTeam)
				{
					if(IsPlayerAlive(i))
					{
						PrintToServer("%N not eliminated", i);
						bEliminated = false;
						break;
					}
				}
			}
			
			if(bEliminated)
			{
				g_iChoosingTeam = iWinningTeam;
				SetMatchState(Match_TeamChoose);
				
				Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "The %s team won the knife round. They will be choosing the starting team.", iWinningTeam == CS_TEAM_CT ? "Counter-Terrorists" : "Terrorist");
			}
		}
	}
	
	if(gMatchState == Match_KnifeRound || gMatchState == Match_Running)
	{
		for(int i= 1; i<= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				{	
					PrintDamageReport(i);
				}
			}
		}
	}
}

/*
// Do test for this
public Action CS_OnTerminateRound(float &flDelay, CSRoundEndReason &Reason)
{
	PrintToServer("Called end on %d", Reason);
	if(gMatchState == Match_Waiting)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
*/

public void Event_PlayerDeath(Event event, const char[] szEventName, bool bDontBroadcast)
{
	//if(g_bAllowRespawn)
//	{
//		int client = GetClientOfUserId(GetEventInt(event, "userid"));
//		CreateTimer(WARMUP_RESPAWN_TIME, RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
//	}

	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	int iKiller = ( GetClientOfUserId( GetEventInt(event, "attacker") ) );
	g_iKiller[client] = iKiller;
	
	if(!client)
	{
		return;
	}
	
	PrintDamageReport(client);
}

PrintDamageReport(client)
{
	static int TeamBit = (1<<( CS_TEAM_CT + 1 )) | (1<<( CS_TEAM_T + 1 ));
	
	Custom_PrintToChat(client, PLUGIN_CHAT_PREFIX, "-------- Damage Report --------");
	
	char iColorLeft, iColorRight;
	int iClientTeamBit;
	int iOtherTeamBit;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) )
		{
			iClientTeamBit	= (1<< (GetClientTeam(client) + 1) );
			iOtherTeamBit	= (1<< (GetClientTeam(i) + 1) );
			
			if( !(iClientTeamBit & TeamBit && iOtherTeamBit & TeamBit && iClientTeamBit != iOtherTeamBit) )
			{
				continue;
			}
			
		#if defined OLD
		
			if(g_flDamage[client][i] > 0.0)	iColorLeft = '\x04';
			else	iColorLeft = '\x01';
			
			if(g_flDamage[i][client] > 0.0)	iColorRight = '\x07';
			else	iColorRight = '\x01';
			
		#else
			
			if(g_iKiller[i] == client)	iColorLeft = '\x04';
			else	iColorLeft = '\x01';
			
			if(g_iKiller[client] == i)	iColorRight = '\x07';
			else	iColorRight = '\x01';
			
		#endif	
			
			Custom_PrintToChat(client, PLUGIN_CHAT_PREFIX, "%s[\x01%d in %d%s] \
			\x01<-> \
			%s[\x01%d in %d%s] \
			\x01- %d HP %N", 

			iColorLeft,
			RoundFloat(g_flDamage[client][i]),
			g_iHits[client][i],
			iColorLeft,
			
			iColorRight,
			RoundFloat(g_flDamage[i][client]),
			g_iHits[i][client],
			iColorRight,
			
			GetClientHealth(i),
			i
			);
		}
	}
}

public Action RespawnPlayer(Handle hTimer, int client)
{
	if(!g_bAllowRespawn)
	{
		return;
	}
	
	if(!IsClientInGame(client) || IsPlayerAlive(client))
	{
		return;
	}
	
	SetEntProp(client, Prop_Send, "m_iAccount", 16000);
	CS_RespawnPlayer(client);
}

public void Event_PlayerSpawn(Event event, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(gMatchState == Match_KnifeRound)
	{
		CS_RemoveWeapons(client, false, g_bKnifeRound_DisarmC4);
	}
	
	else if(gMatchState == Match_Waiting || gMatchState == Match_WaitingSecond)
	{
		ChangeToReadyClanTag(client);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
}

public Action SDKCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	g_flDamage[attacker][victim] += damage;
	g_iHits[attacker][victim]++;
}


public void OnClientPostAdminCheck(int client)
{	
	if(!CheckPlayer(client))
	{
	#if defined ALLOW_ADMINS_JOIN
		if(GetUserAdmin(client))
		{
			if(g_iOutsideSpecsNumber < MAX_OUTSIDE_SPECS)
			{
				g_iOutsideSpecsNumber++;
				gPlayerState = Player_Admin;
				return;
			}
		}
	#endif
	
		char szAuthId[35]; GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
		
		g_bKicked[client] = true;
		KickClient(client, "%s is not authorized to connect to this server.", szAuthId);
		
		return;
	}
	
	gPlayerState[client] = Player_Player;
	
	g_bReady[client] = false;
	if(gMatchState == Match_Waiting || gMatchState == Match_WaitingSecond)
	{
		CS_GetClientClanTag(client, g_szOriginalClanTag[client], sizeof g_szOriginalClanTag[]);
		ChangeToReadyClanTag(client);
	}
	
	Hooks(client, true);
}

public void OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
	
	if(gPlayerState[client] == Player_Admin)
	{
		if(!g_bKicked[client])
		{
			if(GetUserAdmin(client))
			{
				g_iOutsideClients--;
			}
		}
		
		return;
	}
	
	if(g_bKicked[client] || gPlayerState[client] == Player_None)
	{
		g_bKicked[client] = false;
		return;
	}
	
	gPlayerState[client] = Player_None;
	g_iTeam[client] = 0;
	
	if(g_bReady[client])
	{
		g_iReadyCount--;
		g_bReady[client] = false;
	}
	
	Hooks(client, false);
}

public Action ClCmd_Say(int client, const char[] szCommand, int iArgCount)
{	
	if(!gPlayerState[client])
	{
		return;
	}
	
	char szCmdArg[12];
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	if(StrEqual(szCmdArg, ".ready", false))
	{
		if(gMatchState != Match_Waiting && gMatchState != Match_WaitingSecond)
		{
			return;
		}
		
		if(g_bReady[client])
		{
			Custom_PrintToChat(client, PLUGIN_CHAT_PREFIX, "You have already declared yourself as ready");
			return;
		}
		
		g_bReady[client] = true;
		g_iReadyCount++;
		
		ChangeToReadyClanTag(client);
		
		//PrintToChat(client, "* You are now ready");
		Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "%N is now ready", client);
				
		CheckStart();
	}
	
	if(StrEqual(szCmdArg, ".dmg", false))
	{
		if(!IsPlayerAlive(client))
		{
			PrintDamageReport(client);
		}
	}
}

void CheckStart()
{
	//PrintToChatAll("g_iReadyCount = %d ... MATCH_TEAM_PLAYERS = %d", g_iReadyCount, MATCH_PLAYERS_COUNT);
	if(g_iReadyCount == MATCH_PLAYERS_COUNT)
	{
		//PrintToChatAll("Starting");
		Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "-- Starting --");
		
		ChangeToOriginalClanTag();
		StartMatch();
	}
}

void ChangeToReadyClanTag(int client = 0)
{
	switch(client)
	{
		case 0:
		{
			for(client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client) || gPlayerState[client] != Player_Player)
				{
					continue;
				}
				
				CS_SetClientClanTag(client, g_bReady[client] ? "[READY]" : "[NOT READY]");
			}
		}
		
		default:
		{
			CS_SetClientClanTag(client, g_bReady[client] ? "[READY]" : "[NOT READY]");
		}
	}
}

void ChangeToOriginalClanTag(int client = 0)
{
	switch(client)
	{
		case 0:
		{
			for(client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client) || gPlayerState[client] != Player_Player)
				{
					continue;
				}
				
				CS_SetClientClanTag(client, g_szOriginalClanTag[client]);
			}
		}
		
		default:
		{
			CS_SetClientClanTag(client, g_szOriginalClanTag[client]);
		}
	}
}

public Action ClCmd_JoinTeam(int client, const char[] szCommand, int iArgCount)
{
	char szCmdArg[6]; GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	int iJoinTeam = StringToInt(szCmdArg);
	int iTeam = GetClientTeam(client);
	
	PrintToServer("iJoinTeam = %d - iTeam %d", iJoinTeam, iTeam);
	
	if(gPlayerState[client] != Player_Player)
	{
		if(iJoinTeam == CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	if(gMatchState == Match_Waiting)
	{
		if(iJoinTeam != CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	// Any other match state
	if( iJoinTeam == iTeam )
	{
		return Plugin_Continue;
	}
	
	if(iTeam == 0 && iJoinTeam == g_iTeam[client])
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

void StartMatch()
{
	PutPlayersInTeams();
	
	if(gMatchState == Match_Waiting)
	{
		if(g_bKnifeRound_Enabled)
		{
			gMatchState = Match_KnifeRound;
			
			ExecuteConfig(g_szKnifeRoundConfig);
			
			//SetConVarInt(ConVar_RestartGame, 3);
			Func_RestartGame( true, 1, { DELAY_RESTART_KNIFE_ROUND } );
		}
	}
	
	else
	{
		gMatchState = Match_Restarts;
		ExecuteConfig(g_szMatchConfig);
		
		Func_RestartGame( true, 3, { 3, 3, 5 } );
		
		Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "Live on THREE restarts");
	}
}

void Func_RestartGame( bool bReset, int iNumRestarts, int[] iDelay )
{
	if(bReset)
	{
		g_iRestarts = 0;
		//g_iNumRestarts = 0;
		//g_iNumRestarts = 0;
		g_hRestartsPack.Reset(true);
	}
	
	//g_iNumRestarts = iNumRestarts;
	
	g_iNumRestarts = iNumRestarts;
	g_bRestarting = true;
	
	if(iNumRestarts > 1)
	{
		for(int i; i < iNumRestarts; i++)
		{
			g_hRestartsPack.WriteCell(iDelay[i]);
		}
		
		g_hRestartsPack.Reset();
	}
	
	ServerCommand("mp_restartgame %d", iDelay[0]);
	PrintToServer("iDelay %d", iDelay);
}

// Credits: zeusround.sp by "TnTSCS aka ClarkKent"
void CS_RemoveWeapons(int client, bool bStripKnife, bool bStripBomb)
{
	int weapon_index = -1;
	#define MAX_WEAPON_SLOTS 5
	
	for (int slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		weapon_index = GetPlayerWeaponSlot(client, slot);
		{
			PrintToServer("ent %d", weapon_index);
			if (IsValidEntity(weapon_index))
			{
				if(slot == CS_SLOT_KNIFE && !bStripKnife)
				{
					continue;
				}
				
				if (slot == CS_SLOT_C4 && !bStripBomb)
				{
					return;
				}
				
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

void PutPlayersInTeams()
{
	// Do later
	int iCTCount, iTCount;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || gPlayerState[client] != Player_Player)
		{
			continue;
		}
		
		if(!g_iTeam[client])
		{
			if(iCTCount > iTCount)
			{
				g_iTeam[client] = CS_TEAM_T;
			}
			
			else if(iTCount > iCTCount)
			{
				g_iTeam[client] = CS_TEAM_CT;
			}
			
			else g_iTeam[client] = GetRandomInt(CS_TEAM_T, CS_TEAM_CT);
		}
		
		switch(g_iTeam[client])
		{
			case CS_TEAM_CT:	iCTCount++;
			case CS_TEAM_T:		iTCount++;
		}
		
		CS_SwitchTeam(client, g_iTeam[client]);
	}
}

public void ConVarHook_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == ConVar_ServerAddress)
	{
		convar.GetString(g_szServerAddress, sizeof (g_szServerAddress));
			
		if(!g_szServerAddress[0])
		{
			GetClientIP(0, g_szServerAddress, sizeof g_szServerAddress, true);
		}
	}
		
	else if(convar == ConVar_KnifeRound_Enabled)
	{
		g_bKnifeRound_Enabled = convar.BoolValue;
	}
		
	else if(convar == ConVar_KnifeRound_DisarmC4)
	{
		g_bKnifeRound_DisarmC4 = convar.BoolValue;
	}
}

public Action SDKCallback_WeaponSwitch(int client, int iWeapon)
{
	if(gMatchState == Match_KnifeRound)
	{
		char szWeaponName[35];
		GetEntityClassname(iWeapon, szWeaponName, sizeof szWeaponName); 
		
		if(!StrEqual(szWeaponName, "weapon_knife"))
		{
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

void Hooks(int client, bool bOn)
{
	switch(bOn)
	{
		case true:
		{
			SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_WeaponCanUse, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_WeaponEquip, SDKCallback_WeaponSwitch);
		}

		case false:
		{
			SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponCanUse, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponEquip, SDKCallback_WeaponSwitch);
		}	
	}
}

void SetMatchState(MatchState State)
{
	gMatchState = State;
	
	switch(State)
	{
		case Match_Restarts:
		{
			g_bAllowRespawn = false;
		}
		
		case Match_Waiting:
		{
			g_bAllowRespawn = true;
			
			SetArrayValue(g_bReady, sizeof g_bReady, false, 1);
			g_iReadyCount = 0;
			
			ChangeToReadyClanTag();
		}
		
		case Match_WaitingSecond:
		{
			g_bAllowRespawn = true;
			
			SetArrayValue(g_bReady, sizeof g_bReady, false, 1);
			g_iReadyCount = 0;
			
			ChangeToReadyClanTag();
		}
		
		case Match_KnifeRound:
		{
			g_bAllowRespawn = false;
		}
		
		case Match_TeamChoose:
		{
			g_bAllowRespawn = true;
		}
		
		case Match_Running:
		{
			g_bAllowRespawn = false;
		}
	}
}

void ExecuteConfig(const char[] szConfig)
{
	ServerCommand("exec \"%s/%s\"", g_szConfigFolder, szConfig);
}

stock void SQLStuff()
{
	g_hSql = SQL_Connect("MatchSystem", true, szError, sizeof szError);
	
	if(g_hSql == INVALID_HANDLE || szError[0])
	{
		SetFailState("Failed to connect to SQL database");
	}
	
	FormatEx(g_szQuery, sizeof g_szQuery, "SELECT `servers`.`ip` FROM `servers` WHERE `servers`.`ip` = '%s'", g_szServerAddress);
	g_hSql.TQuery(SQLQueryCallback_Connect, g_szQuery);
}

bool CheckPlayer(client)
{
	// Do this later
	g_iTeam[client] = TEAM_NONE;
	
	return true;
}

// from the_khalid_inc.inc (my own code)
stock void SetArrayValue(any[] Array, int iSize, any Value, int iStartingIndex = 0)
{
	for (int i = iStartingIndex; i < iSize; i++)
	{
		Array[i] = Value;
	}
}
