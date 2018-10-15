#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <emitsoundany>
#include <smartjaildoors>

public Plugin myinfo = 
{	author = PLUGIN_AUTHOR,
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

//#define GIVE_WINNING_CREDITS

#if defined GIVE_WINNING_CREDITS
#include <jail_shop>
#endif

#define DISABLE_RADAR

#if defined DISABLE_RADAR
native bool DisableRadar_Status(int client, int bStatus);
#endif

new const String:SOUND_FOLDER[] = "teamwar";

#define MAXTEAMS		12
#define PLAYER_NONE		0
#define TEAM_NONE		-1

// NOT IN MOOD TO PUT 65 DIFFERENT COLORS
enum TeamColor
{
	TC_R, 
	TC_G, 
	TC_B, 
	String:TC_Name[65]
};

any gTeamColor[MAXTEAMS][TeamColor] =  {
	{ 255, 0, 0, "Red" }, 
	{ 0, 255, 0, "Green (Light Green)" }, 
	{ 0, 0, 255, "Blue" }, 
	
	{ 0, 255, 255, "Cyan (Light Blue)" }, 
	{ 255, 255, 0, "Yellow" }, 
	
	{ 128, 0, 128, "Purple" }, 
	{ 128, 128, 0, "Olive" }, 
	{ 128, 128, 128, "Grey" }, 
	{ 0, 128, 0, "Dark Green" }, 
	{ 240, 230, 140, "Khaki" }, 
	{ 255, 192, 203, "Pink" },
	{ 255, 255, 255, "No Color (Normal Bodies)" }
};

bool g_bRunning = false;
bool g_bWarStarted = false;
bool g_bNext = false;

bool g_bCountDownPlayed = false;

int g_iTeamsCount;
int g_iPlayerTeam[MAXPLAYERS + 1];

int g_iTeamPlayersCount[MAXTEAMS];
int g_iTeamPlayersId[MAXTEAMS][MAXPLAYERS]; // Not Maxplayers + 1 because we are going to loop from 0 to g_iTeamPlayersCount.
int g_iTeamPlayersAlive[MAXTEAMS];

int g_iMaxTeams;
float g_flPrepTime;

int g_iTeam_TeamsEliminated[MAXTEAMS];

float g_flEndTime;

Handle g_hTimer;

// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
ConVar ConVar_MinTeamPlayers, 
ConVar_TeammatesAreEnemies, 
ConVar_EnableDamageCT, 
ConVar_FriendlyFire,
ConVar_PreparationTime,
ConVar_MaxTeams;

// -------------------------------
int g_iMinTeamPlayers, 
g_iOldTeammatesAreEnemies;
bool g_bEnableDamageCT, 
g_bFriendlyFire;

#if defined GIVE_WINNING_CREDITS
int g_iWinCredits;
ConVar ConVar_WinCredits;
#endif

// ------------- Sounds ------------------
enum GameSounds
{
	GS_Elimination, 
	GS_CountDown, 
	GS_Lose, 
	GS_Start, 
	GS_Win
};

enum PlayTo
{
	PT_Client, 
	PT_Team, 
	PT_All
};

new const String:g_szBeginSounds[][] =  {
	"Let_The_Game_Begin1.mp3", 
	"Let-the-games-begin2.mp3", 
	"let-the-games-begin3.mp3"
};

new const String:g_szWinSounds[][] =  {
	"MLG_Horns.mp3"
};

new const String:g_szTeamLoseSounds[][] =  {
	"Sound_Fail.mp3", 
	"You_Lose.mp3"
};

new const String:g_szCountDownSound[] = "countdown.mp3";

enum EliminationSounds
{
	ES_Count, 
	String:ES_Sound[55]
};

new const g_szEliminationSounds[][EliminationSounds] =  {
	{ 3, "mst7eel-faris-al3w'9.mp3" }, 
	{ 2, "Shots_Fired.mp3" }, 
	{ 1, "MLG_Wow.mp3" }
};

public void OnPluginStart()
{
	HookEvent("round_prestart", Event_PreRoundStart, EventHookMode_Post);
	HookEvent("round_poststart", Event_PostRoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	RegAdminCmd("sm_teamwar", AdminCmd_TeamWar, ADMFLAG_BAN);
	
	#if defined GIVE_WINNING_CREDITS
	HookConVarChange((ConVar_WinCredits = CreateConVar("days_teamwar_win_credits", "50000")), ConVar_Changed);
	#endif
	HookConVarChange((ConVar_EnableDamageCT = CreateConVar("days_teamwar_enable_ct_damage", "0")), ConVar_Changed);
	HookConVarChange((ConVar_MinTeamPlayers = CreateConVar("days_teamwar_minplayers_perteam", "2")), ConVar_Changed);
	HookConVarChange((ConVar_FriendlyFire = CreateConVar("days_teamwar_friendlyfire", "1")), ConVar_Changed);
	HookConVarChange((ConVar_MaxTeams = CreateConVar("days_teamwar_maxteams", "12")), ConVar_Changed);
	HookConVarChange((ConVar_PreparationTime = CreateConVar("days_teamwar_preptime", "15")), ConVar_Changed);
	HookConVarChange((ConVar_TeammatesAreEnemies = CreateConVar("mp_teammates_are_enemies", "0")), ConVar_Changed);
	
	g_bEnableDamageCT = ConVar_EnableDamageCT.BoolValue;
	g_iMinTeamPlayers = ConVar_MinTeamPlayers.IntValue;
	g_bFriendlyFire = ConVar_FriendlyFire.BoolValue;
	g_iMaxTeams = ConVar_MaxTeams.IntValue;
	g_flPrepTime = ConVar_PreparationTime.FloatValue;
	#if defined GIVE_WINNING_CREDITS
	g_iWinCredits = ConVar_WinCredits.IntValue;
	#endif
}

public void OnMapStart()
{
	g_bRunning = false;
	g_bWarStarted = false;
	g_bNext = false;
	
	PrecacheSoundFiles();
	
	AutoExecConfig(true, "team_war");
}

public void OnMapEnd()
{
	if (g_bRunning)
	{
		Hooks(false);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, SDKCallback_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
	
	g_iPlayerTeam[client] = -1;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, SDKCallback_TraceAttack);
	SDKUnhook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
	
	if (g_bRunning)
	{
		if (g_iPlayerTeam[client] != TEAM_NONE && IsPlayerAlive(client))
		{
			g_iTeamPlayersAlive[g_iPlayerTeam[client]]--;
			
			CheckWin();
		}
	}
}

public Action AdminCmd_TeamWar(int client, int iArgs)
{
	g_bNext = !g_bNext;
	
	if (g_bNext)
	{
		int iCount = GetPlayersCustom();
		if (iCount < (g_iMinTeamPlayers * 2))
		{
			g_bNext = false;
			PrintToChatAll("TeamWar: Disabled Next ( Not enough players )");
			return Plugin_Handled;
		}
	}
	
	PrintToChatAll("TeamWar: %s Next", g_bNext ? "Enabled" : "Disabled");
	return Plugin_Handled;
}

int GetPlayersCustom(int iPlayers[MAXPLAYERS] = 0, bool bAlive = false)
{
	int iCount;
	for(int i = 1; i < MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		if(GetClientTeam(i) != CS_TEAM_T)
		{
			continue;
		}
		
		if(bAlive && !IsPlayerAlive(i))
		{
			continue;
		}
		
		iPlayers[iCount] = i;
		iCount++;
	}
	
	return iCount;
}

int GetPlayersCustom2(int iPlayers[MAXPLAYERS] = 0, bool bAlive = false)
{
	int iCount;
	for(int i = 1; i < MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		if(bAlive && !IsPlayerAlive(i))
		{
			continue;
		}
		
		iPlayers[iCount] = i;
		iCount++;
	}
	
	return iCount;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Revive or fresh player (just joined the server and respawned) ?
	//PrintToServer("Called on %d ::: %d %d %d", client, IsClientConnected(client), IsClientInGame(client), IsPlayerAlive(client));
	if (GetClientTeam(client) != CS_TEAM_T)
	{
		return;
	}
	
	int iTeam = g_iPlayerTeam[client];
	if (iTeam == TEAM_NONE)
	{
		iTeam = PutPlayerInTeam(client, true);
		DisableRadar_Status(client, true);
	}
	
	PrintToChat(client, " \x01Your team color is: \x04%s", gTeamColor[iTeam][TC_Name]);
	CreateTimer(0.0, Timer_ChangeRenderColor, client); // DO it next frame
}

public Action Timer_ChangeRenderColor(Handle hTimer, int client)
{
	int iTeam = g_iPlayerTeam[client];
	SetEntityRenderColor(client, gTeamColor[iTeam][TC_R], gTeamColor[iTeam][TC_G], gTeamColor[iTeam][TC_B], 255);
	
	SetPlayerThirdPerson(client, true);
	
	GivePlayerItem(client, "weapon_m4a1");
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetPlayerThirdPerson(client, false);
	
	if (GetClientTeam(client) != CS_TEAM_T)
	{
		return;
	}
	
	int iTeam = g_iPlayerTeam[client];
	int iCount = g_iTeamPlayersCount[iTeam];
	int iAliveCount = --g_iTeamPlayersAlive[iTeam];
	
	char szPrintText[256];
	if (iAliveCount)
	{
		FormatEx(szPrintText, sizeof szPrintText, " \x03** Teammate \x05%N \x03has just DIED!", client);
	} else
	{
		FormatEx(szPrintText, sizeof szPrintText, " \x04** ALL TEAM PLAYERS HAVE DIED! Your team has lost!");
		PlaySound(GS_Lose, 0, PT_Team, iTeam);
	}
	
	for (int i; i < iCount; i++)
	{
		if (IsClientInGame(g_iTeamPlayersId[iTeam][i]))
		{
			PrintToChat(g_iTeamPlayersId[iTeam][i], szPrintText);
		}
	}
	
	if (!CheckWin())
	{
		// Play sounds.
		if (!iAliveCount)
		{
			int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			
			if (!IsValidPlayer(attacker))
			{
				return;
			}
			
			int iOtherTeam = g_iPlayerTeam[attacker];
			int iOtherCount = g_iTeamPlayersCount[iOtherTeam];
			
			for (int i; i < iOtherCount; i++)
			{
				if (!IsClientInGame(g_iTeamPlayersId[iOtherTeam][i]))
				{
					continue;
				}
				
				PrintToChat(g_iTeamPlayersId[iOtherTeam][i], " ** Your team has just eliminated team \x06%s", gTeamColor[iTeam][TC_Name]);
			}
			
			++g_iTeam_TeamsEliminated[iOtherTeam];
			PrintToChatAll(" ** Team \x06%s \x01has eliminated team \x03%s \x01and they are on a \x05%d \x07Team Elimination Streak\x01!!", gTeamColor[iOtherTeam][TC_Name], gTeamColor[iTeam][TC_Name], g_iTeam_TeamsEliminated[iOtherTeam]);
			
			PlaySound(GS_Elimination, iOtherTeam, PT_All, _);
		}
	}
}

public void Event_PreRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bNext)
	{
		g_bNext = false;
		Hooks(true);
		StartDay();
	}
}

public void Event_PostRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bRunning)
	{
		SJD_OpenDoors();
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRunning)
	{
		EndGame(TEAM_NONE);
	}
}

public Action SDKCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, 
	int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_bRunning)
	{
		return Plugin_Continue;
	}
	
	if (g_bWarStarted)
	{
		return Plugin_Continue;
	}

	// Block all kinds of damage, even world when the war has not started yet (but it is in the process)
	return Plugin_Handled;
}

public Action SDKCallback_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, 
	int &ammotype, int hitbox, int hitgroup)
{
	if (!g_bRunning)
	{
		return Plugin_Continue;
	}
	
	// Stop anyone from dealing any kind of damage (Even falls)
	if (!g_bWarStarted)
	{
		return Plugin_Handled;
	}
	
	if(!(0 < attacker <= MaxClients))
	{
		return Plugin_Continue;
	}
	
	int iTeam = GetClientTeam(victim);
	
	if(iTeam == CS_TEAM_CT)
	{
		int iOtherTeam;
		if((iOtherTeam = GetClientTeam(attacker)) == CS_TEAM_CT)
		{
			return Plugin_Handled;
		}
	
		if (g_bEnableDamageCT && iOtherTeam == CS_TEAM_T)
		{
			return Plugin_Continue;
		}
	}
	
	//if(iTeam == CS_TEAM_T  && GetClientTeam(attacker) == CS_TEAM_T &&
	else if (g_iPlayerTeam[victim] == g_iPlayerTeam[attacker])
	{
		switch (g_bFriendlyFire)
		{
			case false:
			{
				return Plugin_Handled;
			}
			
			case true:
			{
				damage *= 0.20; // Why not ? :)
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

void StartDay()
{
	int iPlayers[MAXPLAYERS];
	int iCount = GetPlayersCustom(iPlayers, false);
	
	if (iCount < g_iMinTeamPlayers * 2)
	{
		PrintToChatAll("** Day aborted as there are not enough players to form atleast two teams (%d).", g_iMinTeamPlayers);
		EndGame(TEAM_NONE);
		return;
	}
	
	//Reset();
	//Hooks(true);
	g_bRunning = true;
	g_bWarStarted = false; 
	
	int iCustomTeamPlayers = g_iMinTeamPlayers;
	while ((g_iTeamsCount = iCount / iCustomTeamPlayers + ((iCount % iCustomTeamPlayers) ? 1 : 0)) > g_iMaxTeams)
	{
		iCustomTeamPlayers += 1;
	}
	
	//PrintToServer("Team count : %d ::: iCustomTeamPlayers = %d", g_iTeamsCount, iCustomTeamPlayers);
	
	PrintToChatAll(" \x04-------------------------------------------");
	PrintToChatAll(" \x04|             \x07TEAM WAR DAY                               \x04|");
	PrintToChatAll(" \x04-------------------------------------------");
	
	// I did it this way to make it fair for the players who last joined
	// cause I don't want them to be in a team with missing players 
	// just because they joined late.
	for (int i, client, iTeam; i < iCount; i++)
	{
		client = iPlayers[i];
		while ((iTeam = GetRandomInt(TEAM_NONE + 1, g_iTeamsCount - 1)) >= 0)
		{
			if (g_iTeamPlayersCount[iTeam] >= iCustomTeamPlayers)
			{
				//PrintToServer("Stop");
				continue;
			}
			
			/*
			// Random Chance 50% to join that team
			if (!GetRandomInt(0, 1))
			{
				continue;
			}*/
			
			break;
		}
		
		g_iPlayerTeam[client] = iTeam;
		g_iTeamPlayersId[iTeam][g_iTeamPlayersCount[iTeam]++] = client;
		g_iTeamPlayersAlive[iTeam]++;
		
		#if defined DISABLE_RADAR
		DisableRadar_Status(client, true);
		#endif
		
		//PrintToServer("iTeam = %d - Count %d - Alive %d", iTeam, g_iTeamPlayersCount[iTeam], g_iTeamPlayersAlive[iTeam]);
		
		//SetEntityRenderColor(client, gTeamColor[iTeam][TC_R], gTeamColor[iTeam][TC_G], gTeamColor[iTeam][TC_B], 255);
		//PrintToChat(client, " \x01Your team color is: \x04%s", gTeamColor[iTeam][TC_Name]);
		
		//SetPlayerThirdPerson(client, true);
	}
	
	// ----------------------------------------------
	// ----------------------------------------------
	// ADD OPEN JAIL DOORS HEREEEE!
	// ----------------------------------------------
	// ----------------------------------------------
	// ADD REMOVE RADAR HERE -- DONE UP IN LOOP
	
	g_flEndTime = GetGameTime() + g_flPrepTime; // START IN 30 SEC
	
	g_hTimer = CreateTimer(0.1, Timer_Prepare, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_Prepare(Handle hTimer)
{
	if (!g_bRunning || g_bWarStarted)
	{
		return Plugin_Stop;
	}
	
	float flGameTime;
	flGameTime = GetGameTime();
	//PrintToServer("%0.2f", flGameTime - g_flEndTime);
	
	if (!g_bCountDownPlayed && (g_flEndTime - flGameTime <= 10.0))
	{
		g_bCountDownPlayed = true;
		PlaySound(GS_CountDown, _, PT_All, _);
	}
	
	if (flGameTime >= g_flEndTime)
	{
		StartTheWar();
		return Plugin_Stop;
	}
	
	PrintHintTextToAll("War will start in: <font color=\"#FF0000\">%0.1f seconds", g_flEndTime - flGameTime, g_flEndTime - flGameTime);
	
	// Add count down sound effects.
	return Plugin_Continue;
}

StartTheWar()
{
	// Add Sounds.
	// Give Guns.
	
	g_bWarStarted = true;
	PrintToChatAll(" \x06----- LET THE HUNT BEGIN --------");
	
	PlaySound(GS_Start, _, PT_All);
	
	Timer_UpdateHintText(g_hTimer);
	g_hTimer = CreateTimer(1.0, Timer_UpdateHintText, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	int iCount;
	for (int i; i < g_iTeamsCount; i++)
	{
		iCount = g_iTeamPlayersCount[i];
		for (int j; j < iCount; j++)
		{
			SetPlayerThirdPerson(g_iTeamPlayersId[i][j], false);
		}
	}
	
	g_iOldTeammatesAreEnemies = ConVar_TeammatesAreEnemies.IntValue;
	ConVar_TeammatesAreEnemies.IntValue = 1;
}

public Action Timer_UpdateHintText(Handle hTimer)
{
	if (!g_bRunning || !g_bWarStarted)
	{
		return Plugin_Stop;
	}
	
	for (int i, j, client; i < g_iTeamsCount + 1; i++)
	{
		for (j = 0; j < g_iTeamPlayersCount[i]; j++)
		{
			client = g_iTeamPlayersId[i][j];
			UpdateHintText(client);
		}
	}
	
	return Plugin_Continue;
}

void UpdateHintText(int client)
{
	int iTeam = g_iPlayerTeam[client];
	int iAliveCount = g_iTeamPlayersAlive[iTeam];
	int iTeamCount = g_iTeamPlayersCount[iTeam];
	char szPrintText[256];
	
	// --- Format - Update this later to include teammates names.
	if (iAliveCount)
	{
		int iLen;
		iLen += FormatEx(szPrintText, sizeof szPrintText, "Team <font color=\"#%02X%02X%02X\">%s</font><br>\
		<font color=\"#00FF00\">ALIVE</font> Team Players: %d<br>", 
			gTeamColor[g_iPlayerTeam[client]][TC_R], gTeamColor[g_iPlayerTeam[client]][TC_G], gTeamColor[g_iPlayerTeam[client]][TC_B], 
			gTeamColor[g_iPlayerTeam[client]][TC_Name], iAliveCount);
		int iStart = iLen, iC;
		
		for (int i, otherclient; i < iTeamCount; i++)
		{
			otherclient = g_iTeamPlayersId[iTeam][i];
			if (IsClientInGame(otherclient) && IsPlayerAlive(otherclient))
			{
				if (iLen - iStart > 100)
				{
					iStart = iLen;
					iLen += FormatEx(szPrintText[iLen], sizeof(szPrintText) - iLen, "<br>");
				}
				
				iLen += FormatEx(szPrintText[iLen], sizeof(szPrintText) - iLen, "%N%s", otherclient, ++iC < iAliveCount ? ", " : "");
			}
		}
	}
	
	else szPrintText = "Your team has LOST! All members died!";
	
	PrintHintText(client, szPrintText);
}

bool CheckWin()
{
	int iCount, iPlayers[MAXPLAYERS];
	iCount = GetPlayersCustom(iPlayers, true);
	
	if (iCount < 1)
	{
		EndGame(TEAM_NONE);
		return false;
	}
	
	if (iCount == 1)
	{
		EndGame(g_iPlayerTeam[iPlayers[0]]);
		return true;
	}
	
	int iTeam = g_iPlayerTeam[iPlayers[0]];
	for (int i = 1; i < iCount; i++)
	{
		if (iTeam != g_iPlayerTeam[iPlayers[i]])
		{
			// Other players of different teams are still alive.
			return false;
		}
	}
	
	EndGame(iTeam);
	return true;
}

void EndGame(iTeam)
{
	Reset();
	Hooks(false);
	SetConVarInt(ConVar_TeammatesAreEnemies, g_iOldTeammatesAreEnemies, false, false);
	
	int iPlayers[MAXPLAYERS], iCount;
	iCount = GetPlayersCustom(iPlayers, true);
	
	int client;
	
	for (int i; i < iCount; i++)
	{
		client = iPlayers[i];
		#if defined DISABLE_RADAR
		DisableRadar_Status(client, false);
		#endif
		
		StripWeapons(client);
	}
	
	if (TEAM_NONE == iTeam)
	{
		return;
	}
	
	PrintToChatAll("** The war has ended. Team \x03%s \x01has won the WAAAR!", gTeamColor[iTeam][TC_Name]);
	
	// Add win stuff here.
	// Win sounds, effects, fireworks, bla bla.
	PlaySound(GS_Win, 0, PT_All, 0);
	
	#if defined GIVE_WINNING_CREDITS
	iCount = g_iTeamPlayersCount[iTeam];
	for (int i, client; i < iCount; i++)
	{
		client = g_iTeamPlayersId[iTeam][i];
		if (!IsClientInGame(client))
		{
			continue;
		}
		
		JBShop_SetCredits(client, JBShop_GetCredits(client) + g_iWinCredits);
	}
	
	PrintToChatAll(" ** Team \x07%s \x01has gained \x03%d \x01credits for winning the war and eliminating all other teams", gTeamColor[iTeam][TC_Name], g_iWinCredits);
	#endif
}

int PutPlayerInTeam(client, bool bAlive)
{
	int iTeam = TEAM_NONE, iCount, iLastCount;
	for (int i, j; i < g_iTeamsCount; i++)
	{
		for (j = 0; j < g_iTeamPlayersCount[i]; j++)
		{
			if (IsClientInGame(g_iTeamPlayersId[i][j]))
			{
				iCount++;
			}
		}
		
		if (iCount < iLastCount)
		{
			iTeam = i;
			iLastCount = iCount;
		}
	}
	
	if (iTeam == TEAM_NONE)
	{
		iTeam = GetRandomInt(TEAM_NONE + 1, g_iTeamsCount - 1);
	}
	
	g_iPlayerTeam[client] = iTeam;
	g_iTeamPlayersId[iTeam][g_iTeamPlayersCount[iTeam]++] = client;
	
	if (bAlive)
	{
		g_iTeamPlayersAlive[iTeam]++;
	}
	
	return iTeam;
}

void Reset()
{
	SetArrayValue(g_iPlayerTeam, sizeof g_iPlayerTeam, TEAM_NONE, 0);
	SetArrayValue(g_iTeamPlayersCount, sizeof g_iTeamPlayersCount, 0, 0);
	SetArrayValue(g_iTeamPlayersAlive, sizeof g_iTeamPlayersAlive, 0, 0);
	SetArrayValue(g_iTeam_TeamsEliminated, sizeof g_iTeam_TeamsEliminated, 0, 0);
	
	g_bRunning = false;
	g_bWarStarted = false;
	g_bCountDownPlayed = false;
	
	delete g_hTimer;
}

void SetArrayValue(any[] iArray, int iSize, any value, int iStart)
{
	for(int i = iStart; i < iSize; i++)
	{
		iArray[i] = value;
	}
}

void Hooks(bool bStatus)
{
	switch (bStatus)
	{
		case true:
		{
			HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
			HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
			HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		}
		
		case false:
		{
			UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
			UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
			UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		}
	}
}

public Action Event_PlayerHurt(Event hEvent, char[] szEvent, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (GetClientTeam(client) != CS_TEAM_T)
	{
		return;
	}
	
	float flHealth = GetEventFloat(hEvent, "health");
	if(flHealth <= 0.0)
	{
		StripWeapons(client);
	}
}

void PlaySound(GameSounds Sound, int iTeam = TEAM_NONE, PlayTo iPlayTo = PT_Client, int iDestination = 0)
{
	char szSound[PLATFORM_MAX_PATH];
	switch (Sound)
	{
		case GS_Elimination:
		{
			int iEliminationsThisRound = g_iTeam_TeamsEliminated[iTeam] + 1; // Because loop starts with pre --
			
			#define MAX_SOUNDS_INDEXES 7
			int iSoundIndex[MAX_SOUNDS_INDEXES];
			int iSoundsCount = 0;
			
			do
			{
				--iEliminationsThisRound;
				for (int i; i < sizeof(g_szEliminationSounds); i++)
				{
					if (g_szEliminationSounds[i][ES_Count] == iEliminationsThisRound)
					{
						iSoundIndex[iSoundsCount++] = i;
					}
				}
			}
			while (!iSoundsCount && iEliminationsThisRound);
			
			if (!iSoundsCount)
			{
				return;
			}
			
			FormatEx(szSound, sizeof szSound, "%s/%s", SOUND_FOLDER, g_szEliminationSounds[iSoundIndex[GetRandomInt(0, iSoundsCount - 1)]][ES_Sound]);
		}
		case GS_Lose:
		{
			FormatEx(szSound, sizeof szSound, "%s/%s", SOUND_FOLDER, g_szTeamLoseSounds[GetRandomInt(0, sizeof(g_szTeamLoseSounds) - 1)]);
		}
		case GS_Start:
		{
			FormatEx(szSound, sizeof szSound, "%s/%s", SOUND_FOLDER, g_szBeginSounds[GetRandomInt(0, sizeof(g_szBeginSounds) - 1)]);
		}
		case GS_Win:
		{
			FormatEx(szSound, sizeof szSound, "%s/%s", SOUND_FOLDER, g_szWinSounds[GetRandomInt(0, sizeof(g_szWinSounds) - 1)]);
		}
		
		case GS_CountDown:
		{
			FormatEx(szSound, sizeof szSound, "%s/%s", SOUND_FOLDER, g_szCountDownSound);
		}
	}
	
	int client;
	int iPlayers[MAXPLAYERS], iCount;
	switch (iPlayTo)
	{
		case PT_All:
		{
			iCount = GetPlayersCustom2(iPlayers);
		}
		
		case PT_Client:
		{
			iCount = 1;
			iPlayers[0] = iDestination;
		}
		
		case PT_Team:
		{
			for (int i; i < g_iTeamPlayersCount[iDestination]; i++)
			{
				if (!IsClientInGame((client = g_iTeamPlayersId[iDestination][i])))
				{
					continue;
				}
				
				iPlayers[iCount++] = client;
			}
		}
	}
	
	for (int i; i < iCount; i++)
	{
		client = iPlayers[i];
		// Do Play Sounds here
		EmitSoundToClientAny(client, szSound);
		//EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}
}

public void ConVar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == ConVar_TeammatesAreEnemies)
	{
		if (g_bWarStarted)
		{
			//convar.IntValue = 1;
			SetConVarInt(convar, 1, false, false);
		}
	}
	
	else if (convar == ConVar_MinTeamPlayers)
	{
		g_iMinTeamPlayers = convar.IntValue;
	}
	
	else if (convar == ConVar_EnableDamageCT)
	{
		g_bEnableDamageCT = convar.BoolValue;
	}
	
	else if (convar == ConVar_FriendlyFire)
	{
		g_bFriendlyFire = convar.BoolValue;
	}
	
	else if (convar == ConVar_FriendlyFire)
	{
		g_bFriendlyFire = convar.BoolValue;
	}
	
	else if (convar == ConVar_PreparationTime)
	{
		g_flPrepTime = convar.FloatValue;
	}
	
	else if (convar == ConVar_MaxTeams)
	{
		g_iMaxTeams = convar.IntValue;
		if(g_iMaxTeams > MAXTEAMS || g_iMaxTeams <= 1)
		{
			g_iMaxTeams = MAXTEAMS;
		}
	}
	#if defined GIVE_WINNING_CREDITS
	else if (convar == ConVar_WinCredits)
	{
		g_iWinCredits = convar.IntValue;
	}
	#endif
}

void PrecacheSoundFiles()
{
	int iSize, i;
	char szFile[PLATFORM_MAX_PATH];
	
	iSize = sizeof g_szEliminationSounds;
	
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szEliminationSounds[i][ES_Sound]);
		PrecacheSoundAny(szFile);
		
		Format(szFile, sizeof szFile, "sound/%s", szFile);
		AddFileToDownloadsTable(szFile);
	}
	
	iSize = sizeof g_szWinSounds;
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szWinSounds[i]);
		PrecacheSoundAny(szFile);
		
		Format(szFile, sizeof szFile, "sound/%s", szFile);
		AddFileToDownloadsTable(szFile);
	}
	
	iSize = sizeof g_szBeginSounds;
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szBeginSounds[i]);
		PrecacheSoundAny(szFile);
		
		Format(szFile, sizeof szFile, "sound/%s", szFile);
		AddFileToDownloadsTable(szFile);
	}
	
	iSize = sizeof g_szTeamLoseSounds;
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szTeamLoseSounds[i]);
		PrecacheSoundAny(szFile);
		
		Format(szFile, sizeof szFile, "sound/%s", szFile);
		AddFileToDownloadsTable(szFile);
	}
	
	FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szCountDownSound);
	PrecacheSoundAny(szFile);
		
	Format(szFile, sizeof szFile, "sound/%s", szFile);
	AddFileToDownloadsTable(szFile);
}

/*
void PrecacheSoundFiles()
{
	int iSize, i;
	char szFile[PLATFORM_MAX_PATH];
	
	iSize = sizeof g_szEliminationSounds;
	
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szEliminationSounds[i][ES_Sound]);
		//PrecacheSound(szFile);
		PrecacheSoundAny(szFile);
		//Format(szFile, sizeof szFile, "sound/%s", szFile);
		//AddFileToDownloadsTable(szFile);
	}
	
	iSize = sizeof g_szWinSounds;
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szWinSounds[i]);
		//PrecacheSound(szFile);
		PrecacheSoundAny(szFile);
		//Format(szFile, sizeof szFile, "sound/%s", szFile);
		//AddFileToDownloadsTable(szFile);
	}
	
	iSize = sizeof g_szBeginSounds;
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szBeginSounds[i]);
		//PrecacheSound(szFile);
		PrecacheSoundAny(szFile);
		//Format(szFile, sizeof szFile, "sound/%s", szFile);
		//AddFileToDownloadsTable(szFile);
	}
	
	iSize = sizeof g_szTeamLoseSounds;
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szTeamLoseSounds[i]);
		PrecacheSound(szFile);
		Format(szFile, sizeof szFile, "sound/%s", szFile);
		AddFileToDownloadsTable(szFile);
	}
	
	FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szCountDownSound);
	PrecacheSound(szFile);
	Format(szFile, sizeof szFile, "sound/%s", szFile);
	AddFileToDownloadsTable(szFile);
}*/

stock bool IsValidPlayer(client)
{
	if (0 < client <= MAXPLAYERS)
	{
		if (IsClientInGame(client))
			return true;
	}
	
	return false;
}

stock void SetPlayerThirdPerson(int client, bool bEnable = true)
{
	switch(bEnable)
	{
		case true:
		{
			SetThirdPerson(client);
		}
		
		case false:
		{
			SetFirstPerson(client);
		}
	}
}

stock void SetThirdPerson(int client)
{
	if (IsValidEntity(client) && IsClientInGame(client))
	{
		//if (game == Game_CSGO)
		{
			ClientCommand(client, "thirdperson");
		}
		/*
		else
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
			SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
			SetEntProp(client, Prop_Send, "m_iFOV", 120);
		}*/
	}
}

stock void SetFirstPerson(int client)
{
	if (IsValidEntity(client) && IsClientInGame(client))
	{
		//if (game == Game_CSGO)
		{
			ClientCommand(client, "firstperson");
		}
		/*
		else
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 1);
			SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
		}*/
	}
}

stock void StripWeapons(int client)
{
	int iPrimaryWeapon = GetPlayerWeaponSlot(client, 0);
	int iSecondaryWeapon = GetPlayerWeaponSlot(client, 1);
		
	if(IsValidEdict(iPrimaryWeapon))
	{
		RemovePlayerItem(client, iPrimaryWeapon);
		RemoveEdict(iPrimaryWeapon);
	}
		
		
	if(IsValidEdict(iSecondaryWeapon))
	{
		RemovePlayerItem(client, iSecondaryWeapon);
		RemoveEdict(iPrimaryWeapon);
	}	
}