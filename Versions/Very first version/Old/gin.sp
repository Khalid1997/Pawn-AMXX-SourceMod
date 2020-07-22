#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "0.1.003"

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

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
#define NUMBER_RESTARTS		3
//#define ALLOW_ADMINS_JOIN

#define MAX_TEAM_PLAYERS 1
const int MATCH_PLAYERS_COUNT = (MAX_TEAM_PLAYERS * 2);

#define MAX_OUTSIDE_CLIENTS	2
int g_iOutsideClients;

#define WARMUP_RESPAWN_TIME	3.0

new const String:g_szConfigFolder[] = "matchsystem";
new const String:g_szWarmUpConfig[] = "warmup.cfg";
new const String:g_szMatchConfig[] = "match.cfg";
new const String:g_szKnifeRoundConfig[] = "knife_round.cfg";

#define TEAM_NONE 0

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

int g_iRestarts;
// Do later
//Trie DisconnectInfo;
bool g_bKicked[MAXPLAYERS + 1];

char g_szOriginalClanTag[MAXPLAYERS + 1][MAX_NAME_LENGTH];

// -------------------------------------------
// 				Start: ConVars
// -------------------------------------------
ConVar	ConVar_ServerAddress,
		ConVar_KnifeRound_Enabled,
		ConVar_KnifeRound_DisarmC4;
		
char	g_szServerAddress[20];
bool	g_bKnifeRound_Enabled,
		g_bKnifeRound_DisarmC4;
		
ConVar	ConVar_RestartGame;

// -------------------------------------------
// 				Start: Plugin
// -------------------------------------------
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
	AddCommandListener(ClCmd_JoinTeam, "jointeam");
	AddCommandListener(ClCmd_Say, "say");
	AddCommandListener(ClCmd_Say, "say_team");
	
	ConVar_ServerAddress = CreateConVar("ms_server_address", "", "Leave blank to try to auto detect. (IP:Port)");
	ConVar_KnifeRound_Enabled = CreateConVar("ms_kniferound_enabled", "1", "Enable knife rounds for choosing sides");
	ConVar_KnifeRound_DisarmC4 = CreateConVar("ms_kniferound_disarm_c4", "1", "Disarm C4 during knife round");
	
	ConVar_ServerAddress.AddChangeHook(ConVarHook_Changed);
	ConVar_KnifeRound_Enabled.AddChangeHook(ConVarHook_Changed);
	ConVar_KnifeRound_DisarmC4.AddChangeHook(ConVarHook_Changed);
	
	ConVar_RestartGame = CreateConVar("mp_restartgame", "");
	
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
	if(gMatchState == Match_Restarts)
	{
		if(g_iRestarts < NUMBER_RESTARTS - 1)
		{
			g_iRestarts++;
		
			SetConVarInt(ConVar_RestartGame, 1);
		}
	
		else if(g_iRestarts == NUMBER_RESTARTS)
		{
			g_iRestarts++;
		
			SetConVarInt(ConVar_RestartGame, 3);
		}
		
		else if(g_iRestarts > NUMBER_RESTARTS)
		{
			SetMatchState(Match_Running);
			ExecuteConfig(g_szMatchConfig);
			
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client))
				{
					PrintToChat(client, " ** \x04Live");
					PrintToChat(client, " ** \x04Live");
					PrintToChat(client, " ** \x04Live");
					PrintToChat(client, " ** \x04Live");
				}
			}
		}
	}
	
	if(gMatchState == Match_KnifeRound)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				PrintToChat(client, " ** \x04Knife Round");
				PrintToChat(client, " ** Eliminate the other team to get the advantage of choosing the Starting Team.");
			}
		}
	}
	
	if(gMatchState == Match_TeamChoose)
	{
		int client = GetRandomClient(g_iChoosingTeam);
		Menu hMenu = CreateMenu(MenuHandler_TeamChoose, MENU_ACTIONS_DEFAULT);
		
		hMenu.AddItem("1", "Terrorists");
		hMenu.AddItem("2", "Counter-Terrorists");
		hMenu.AddItem("3", "Random");
		
		hMenu.ExitBackButton = false;
		
		hMenu.Display(client, MENU_TIME_FOREVER);
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
			
			if(iTeamSelection == 3)
			{
				iTeamSelection = GetRandomInt(1, 2);
			}
			
			int iOtherTeam = iTeamSelection == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
			
			for(int client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client) || gPlayerState[client] != Player_Player)
				{
					return;
				}
				
				if(g_iTeam[client] == g_iChoosingTeam)
				{
					g_iTeam[client] = iTeamSelection;
				}
				
				else	g_iTeam[client] = iOtherTeam;
			}
			
			PutPlayersInTeams();
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
		CSRoundEndReason iEndReason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
		int iWinningTeam = GetEventInt(event, "winner");
		
		if(iEndReason == CSRoundEnd_TerroristWin || iEndReason == CSRoundEnd_CTWin || iEndReason == CSRoundEnd_CTWin)
		{
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
						bEliminated = false;
						break;
					}
				}
			}
			
			if(bEliminated)
			{
				g_iChoosingTeam = iWinningTeam;
				SetMatchState(Match_TeamChoose);
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
	if(g_bAllowRespawn)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(WARMUP_RESPAWN_TIME, RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
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

public void OnClientPostAdminCheck(client)
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
	if(gMatchState != Match_Waiting)
	{
		return;
	}
	
	if(!gPlayerState[client])
	{
		return;
	}
	
	char szCmdArg[12];
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	if(StrEqual(szCmdArg, ".ready", false))
	{
		if(g_bReady[client])
		{
			PrintToChat(client, "** You have already declared yourself as ready");
			return;
		}
		
		g_bReady[client] = true;
		g_iReadyCount++;
		
		PrintToChat(client, "* You are now ready");
		PrintToChatAll("Player %N is now ready", client);
				
		CheckStart();		
	}
}

void CheckStart()
{
	PrintToChatAll("g_iReadyCount = %d ... MATCH_TEAM_PLAYERS = %d", g_iReadyCount, MATCH_PLAYERS_COUNT);
	if(g_iReadyCount == MATCH_PLAYERS_COUNT)
	{
		PrintToChatAll("Starting");
		
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
			
			g_iRestarts = 0;
			ExecuteConfig(g_szKnifeRoundConfig);
			
			SetConVarInt(ConVar_RestartGame, 3);
			
			//PrintToChatAll(" ** \x04--- Knife Round ---");
			//PrintToChatAll(" ** Win to choose that starting team of the match");
		}
	}
	
	else
	{
		gMatchState = Match_Restarts;
	}
}

// Credits: zeusround.sp by "TnTSCS aka ClarkKent"
void CS_RemoveWeapons(int client, bool bStripKnife, bool bStripBomb)
{
	int weapon_index = -1;
	#define MAX_WEAPON_SLOTS 5
	
	for (int slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
		{
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
