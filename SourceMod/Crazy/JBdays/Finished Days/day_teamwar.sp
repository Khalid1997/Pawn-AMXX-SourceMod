#pragma semicolon 1


#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#include <emitsoundany>

#pragma newdecls required

#undef REQUIRE_PLUGIN
#include <daysapi>
#include <smartjaildoors>
#include <thirdperson>
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
	name = "DaysAPI: Team War Day", 
	author = "Khalid", 
	description = "Team War", 
	version = "1.0", 
	url = ""
};

#define ADMFLAG_ACCESS	ADMFLAG_BAN
//#define DISABLE_RADAR

#if defined DISABLE_RADAR
native bool DisableRadar_Status(int client, int bStatus);
#endif

char SOUND_FOLDER[] = "teamwar";

#define MAXTEAMS		12
#define PLAYER_NONE		0
#define Team_None		-1

int g_iWinningTeam = Team_None;

// NOT IN MOOD TO PUT 65 DIFFERENT COLORS
enum TeamColor
{
	TC_R, 
	TC_G, 
	TC_B
};

any gTeamColor[MAXTEAMS][TeamColor] =  {
	{ 255, 0, 0 }, 
	{ 0, 255, 0 }, 
	{ 0, 0, 255 }, 
	
	{ 0, 255, 255 }, 
	{ 255, 255, 0 }, 
	
	{ 128, 0, 128 }, 
	{ 128, 128, 0  }, 
	{ 128, 128, 128 }, 
	{ 0, 128, 0 }, 
	{ 240, 230, 140 }, 
	{ 255, 192, 203 }, 
	{ 255, 255, 255 }
};

char g_szTeamColorName[MAXTEAMS][] = {
	"Red", 
	"Green (Light Green)", 
	"Blue", 
	
	"Cyan (Light Blue)", 
	"Yellow", 
	
	"Purple", 
	"Olive", 
	"Grey", 
	"Dark Green", 
	"Khaki", 
	"Pink", 
	"No Color (Normal Bodies)"
};

char g_szIntName[] = "teamwar";

bool g_bRunning = false;
bool g_bWarStarted = false;

bool g_bCountDownPlayed = false;

int g_iTeamsCount;
int g_iPlayerTeam[MAXPLAYERS + 1];

int g_iTeamPlayersCount[MAXTEAMS];
int g_iTeamPlayersIds[MAXTEAMS][MAXPLAYERS]; // Not Maxplayers + 1 because we are going to loop from 0 to g_iTeamPlayersCount.
int g_iTeamPlayersAlive[MAXTEAMS];

int g_iMaxTeams;
float g_flPrepTime;

int g_iTeam_TeamsEliminated[MAXTEAMS];

char g_szTeamWarWeapon[] = "weapon_taser";

float g_flEndTime;

Handle g_hTimer;
bool g_bHooks;

// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
ConVar ConVar_MinTeamPlayers, 
ConVar_TeammatesAreEnemies, 
ConVar_FriendlyFire, 
ConVar_PreparationTime, 
ConVar_MaxTeams;

// -------------------------------
int g_iMinTeamPlayers, 
g_iOldTeammatesAreEnemies;
bool g_bFriendlyFire;

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

char g_szBeginSounds[][] =  {
	"Let_The_Game_Begin1.mp3", 
	"Let-the-games-begin2.mp3", 
	"let-the-games-begin3.mp3"
};

char g_szWinSounds[][] =  {
	"MLG_Horns.mp3"
};

char g_szTeamLoseSounds[][] =  {
	"Sound_Fail.mp3", 
	"You_Lose.mp3"
};

char g_szCountDownSound[] = "countdown.mp3";

char g_szEliminationSounds[][] =  {
	"mst7eel-faris-al3w'9.mp3", 
	"Shots_Fired.mp3", 
	"MLG_Wow.mp3"
};

int g_iEliminationSoundsElimCount[] =  {
	3, 
	2, 
	1
};

bool g_bLate = false;
bool g_bThirdPersonPlugin = false;
bool g_bDaysAPI = false;
bool g_bSJD = false;

// Only without days API
bool g_bPlannedNext = false;

bool g_bPluginLoaded = false;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate)
{
	g_bLate = bLate;
	
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] szName)
{
	if (StrEqual(szName, "thirdperson"))
	{
		g_bThirdPersonPlugin = true;
	}
	
	else if (StrEqual(szName, "smartjaildoors"))
	{
		g_bSJD = true;
	}
	
	else if (StrEqual(szName, "daysapi"))
	{
		if(g_bPluginLoaded)
		{
			DaysAPI_AddDay(g_szIntName, DaysAPI_TeamWarStart, DaysAPI_TeamWarEnd);
			DaysAPI_SetDayInfo(g_szIntName, DayInfo_DisplayName, "Team Wars");
			DaysAPI_SetDayInfo(g_szIntName, DayInfo_Flags, DayFlag_EndTerminateRound); // Terminate the round on end.
		}
		
		g_bDaysAPI = true;
	}
}

public void OnLibraryRemoved(const char[] szName)
{
	if (StrEqual(szName, "thirdperson"))
	{
		g_bThirdPersonPlugin = false;
	}
	
	else if (StrEqual(szName, "smartjaildoors"))
	{
		g_bSJD = false;
	}
	
	else if (StrEqual(szName, "daysapi"))
	{
		g_bDaysAPI = false;
	}
}

public void OnAllPluginsLoaded()
{
	g_bPluginLoaded = true;
	
	g_bThirdPersonPlugin = LibraryExists("thirdperson");
	g_bSJD = LibraryExists("smartjaildoors");
	g_bDaysAPI = LibraryExists("daysapi");
	
	if (g_bDaysAPI)
	{
		DaysAPI_AddDay(g_szIntName, DaysAPI_TeamWarStart, DaysAPI_TeamWarEnd);
		DaysAPI_SetDayInfo(g_szIntName, DayInfo_DisplayName, "Team Wars");
		DaysAPI_SetDayInfo(g_szIntName, DayInfo_Flags, DayFlag_EndTerminateRound); // Terminate the round on end.
	}
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	// Admin commands
	RegAdminCmd("sm_teamwar", Command_StartTeamWar, ADMFLAG_ACCESS);
	
	HookConVarChange((ConVar_MinTeamPlayers = CreateConVar("day_teamwar_minplayers_perteam", "2")), ConVar_Changed);
	HookConVarChange((ConVar_FriendlyFire = CreateConVar("day_teamwar_friendlyfire", "1")), ConVar_Changed);
	HookConVarChange((ConVar_MaxTeams = CreateConVar("day_teamwar_maxteams", "12", "", _, true, 2.0, true, float(MAXTEAMS))), ConVar_Changed);
	HookConVarChange((ConVar_PreparationTime = CreateConVar("day_teamwar_preptime", "30")), ConVar_Changed);
	HookConVarChange((ConVar_TeammatesAreEnemies = FindConVar("mp_teammates_are_enemies")), ConVar_Changed);
	
	g_iMinTeamPlayers = ConVar_MinTeamPlayers.IntValue;
	g_bFriendlyFire = ConVar_FriendlyFire.BoolValue;
	g_iMaxTeams = ConVar_MaxTeams.IntValue;
	g_flPrepTime = ConVar_PreparationTime.FloatValue;
	
	if (g_bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	if (g_bDaysAPI)
	{
		DaysAPI_RemoveDay(g_szIntName);
	}
	
	else
	{
		if(g_bRunning)
		{
			EndGame(Team_None);
		}
	}
}

public Action Command_StartTeamWar(int client, int argc)
{
	if (g_bDaysAPI)
	{
		return Plugin_Handled;
	}
	
	g_bPlannedNext = !g_bPlannedNext;
	CPrintToChat(client, "\x04* Team was is \x03'%s'\x04 for the next round.", g_bPlannedNext ? "Enabled" : "Disabled");
	return Plugin_Handled;
}

public void OnMapStart()
{
	PrecacheSoundFiles();
	AutoExecConfig(true, "daysapi_teamwar");
}

public void OnMapEnd()
{
	if (g_bRunning)
	{
		ResetGame();
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, SDKCallback_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
	SDKHook(client, SDKHook_WeaponEquip, SDKCallback_WeaponEquip);
	
	g_iPlayerTeam[client] = Team_None;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, SDKCallback_TraceAttack);
	SDKUnhook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponEquip, SDKCallback_WeaponEquip);
	
	if (g_bRunning)
	{
		int iTeam = g_iPlayerTeam[client];
		if (iTeam != Team_None)
		{
			if (IsPlayerAlive(client))
			{
				--g_iTeamPlayersAlive[iTeam];
			}
			
			RemoveEntryFromArray(g_iTeamPlayersIds[iTeam], g_iTeamPlayersCount[iTeam], client);
			CheckWin();
		}
	}
}

void RemoveEntryFromArray(int[ ] array, int &size, int entry)
{
	int i, j = -1;
	for(; i < size; i++)
	{
		if(j == -1)
		{
			if(array[i] == entry)
			{
				j = i;
			}
			
			continue;
		}
		
		array[j++] = array[i];
	}
	
	if(j != -1)
	{
		array[j] = 0;
	}
	
	--size;
}

int GetPlayersCustom(int iPlayers[MAXPLAYERS] = 0, bool bAliveOnly = false)
{
	int iCount;
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (bAliveOnly && !IsPlayerAlive(i))
		{
			continue;
		}
		
		iPlayers[iCount] = i;
		iCount++;
	}
	
	return iCount;
}

// Block weapon pickup
public Action SDKCallback_WeaponEquip(int client, int weapon)
{
	if (!g_bRunning)
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if (!StrEqual(sWeapon, "weapon_knife") && !StrEqual(sWeapon, g_szTeamWarWeapon))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// Just incase someone revived for some reason.
// Or someone joined late and spawned.
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Revive or fresh player (just joined the server and respawned) ?
	int iTeam = g_iPlayerTeam[client];
	if (iTeam == Team_None)
	{
		iTeam = PutPlayerInTeam(client, true);
	}
	
	CPrintToChat(client, "\x04Your team color is: \x03%s", g_szTeamColorName[iTeam]);
	//RequestFrame(NextFrame_ApplyEffects, client); // Do it next frame
}

public void NextFrame_ApplyEffects(int client)
{
	if (!g_bRunning)
	{
		return;
	}
	
	if (IsPlayerAlive(client))
	{
		ApplyPlayerEffects(client, true);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	ApplyPlayerEffects(client, false);
	
	int iTeam = g_iPlayerTeam[client];
	int iCount = g_iTeamPlayersCount[iTeam];
	int iAliveCount = --g_iTeamPlayersAlive[iTeam];
	
	char szPrintText[192];
	FormatEx(szPrintText, sizeof szPrintText, "\x03** Teammate \x05%N \x03has just DIED!", client);
	
	if (!iAliveCount)
	{
		FormatEx(szPrintText, sizeof szPrintText, "\x04** ALL TEAM PLAYERS HAVE DIED! Your team has lost!");
		PlaySound(GS_Lose, 0, PT_Team, iTeam);
	}
	
	for (int i; i < iCount; i++)
	{
		if (IsClientInGame(g_iTeamPlayersIds[iTeam][i]))
		{
			CPrintToChat(g_iTeamPlayersIds[iTeam][i], szPrintText);
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
				if (!IsClientInGame(g_iTeamPlayersIds[iOtherTeam][i]))
				{
					continue;
				}
				
				CPrintToChat(g_iTeamPlayersIds[iOtherTeam][i], "\x04** Your team has just eliminated team \x06%s", g_szTeamColorName[iTeam]);
			}
			
			++g_iTeam_TeamsEliminated[iOtherTeam];
			CPrintToChatAll("\x04** Team \x06%s \x04has eliminated team \x03%s \x04and they are on a \x05%d \x07Team Elimination Streak\x04!!", g_szTeamColorName[iOtherTeam], g_szTeamColorName[iTeam], g_iTeam_TeamsEliminated[iOtherTeam]);
			
			PlaySound(GS_Elimination, iOtherTeam, PT_All, _);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	if (g_bRunning)
	{
		return;
	}
	
	if (!g_bDaysAPI)
	{
		if (g_bPlannedNext)
		{
			g_bPlannedNext = false;
			StartDay();
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRunning)
	{
		if (!g_bDaysAPI)
		{
			EndGame(Team_None);
		}
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
	
	// Stop anyone from dealing any kind of damage
	if (!g_bWarStarted)
	{
		return Plugin_Handled;
	}
	
	if (!(0 < attacker <= MaxClients))
	{
		return Plugin_Continue;
	}
	
	if (g_iPlayerTeam[victim] == g_iPlayerTeam[attacker])
	{
		CPrintToChat(attacker, "\x04* Friendly Fire! You attacked teammate \x03%N", victim);
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

DayStartReturn StartDay()
{
	int iPlayers[MAXPLAYERS];
	int iCount = GetPlayersCustom(iPlayers, true);
	
	if (iCount < g_iMinTeamPlayers * 2)
	{
		CPrintToChatAll("\x04** Day aborted as there are not enough players to form atleast two teams (%d min players).", g_iMinTeamPlayers);
		return DSR_Stop;
	}
	
	g_bRunning = true;
	g_bWarStarted = false;
	
	Hooks(true);
	
	int iCustomTeamPlayers = g_iMinTeamPlayers;
	while ((g_iTeamsCount = iCount / iCustomTeamPlayers + ((iCount % iCustomTeamPlayers) ? 1 : 0)) > g_iMaxTeams)
	{
		iCustomTeamPlayers += 1;
	}
	
	PrintToServer("g_iTeamsCount %d", g_iTeamsCount);
	
	ArrayList array = new ArrayList(1);
	for (int i; i < g_iTeamsCount; i++)
	{
		array.Push(i);
	}
	
	CPrintToChatAll("\x04-------------------------------------------");
	CPrintToChatAll("\x04|           \x07TEAM WAR DAY           \x04|");
	CPrintToChatAll("\x04-------------------------------------------");
	
	int iSize = array.Length;
	int iIndex, client, iTeam;
	for (int i; i < iCount; i++)
	{
		client = iPlayers[i];
		iIndex = GetRandomInt(0, iSize - 1);
		iTeam = array.Get(iIndex);
		
		g_iPlayerTeam[client] = iTeam;
		g_iTeamPlayersIds[iTeam][ g_iTeamPlayersCount[iTeam]++ ] = client;
		g_iTeamPlayersAlive[iTeam]++;
		
		if (g_iTeamPlayersCount[iTeam] == iCustomTeamPlayers)
		{
			array.Erase(iIndex);
			--iSize;
		}
		
		// Apply Effect on spawn if it was planned
		ApplyPlayerEffects(client, true);
	}
	
	delete array;
	
	if (g_bThirdPersonPlugin)
	{
		ThirdPerson_SetGlobalLockMode(TPT_ThirdPerson);
	}
	
	//PrintToServer("Team count : %d ::: iCustomTeamPlayers = %d", g_iTeamsCount, iCustomTeamPlayers);
	
	// I did it this way to make it fair for the players who last joined
	// cause I don't want them to be in a team with missing players 
	// just because they joined late.
	
	// ----------------------------------------------
	// ----------------------------------------------
	// ADD OPEN JAIL DOORS HEREEEE!
	// ----------------------------------------------
	// ----------------------------------------------
	// ADD REMOVE RADAR HERE -- DONE UP IN LOOP
	
	// Open Jail Doors
	
	if (g_bSJD)
	{
		SJD_OpenDoors();
	}
	
	g_iWinningTeam = Team_None;
	g_flEndTime = GetGameTime() + g_flPrepTime; // START IN 30 SEC
	
	g_hTimer = CreateTimer(0.1, Timer_Prepare, _, TIMER_REPEAT);
	return DSR_Success;
}

void ApplyPlayerEffects(int client, bool bEnable)
{
	switch (bEnable)
	{
		case true:
		{
			#if defined DISABLE_RADAR
			DisableRadar_Status(client, true);
			#endif
			
			int iTeam = g_iPlayerTeam[client];
			SetEntityRenderColor(client, gTeamColor[iTeam][TC_R], gTeamColor[iTeam][TC_G], gTeamColor[iTeam][TC_B], 255);
			CPrintToChat(client, "Your team color is: \x04%s", g_szTeamColorName[iTeam]);
			
			StripWeapons(client);
			int iWeapon = GivePlayerItem(client, g_szTeamWarWeapon);
			if (iWeapon != -1)
			{
				// This thing crashes the server
				//				EquipPlayerWeapon(client, iWeapon);
			}
		}
		
		case false:
		{
			#if defined DISABLE_RADAR
			DisableRadar_Status(client, false);
			#endif
			
			SetEntityRenderColor(client);
		}
	}
}

public Action Timer_Prepare(Handle hTimer)
{
	if (!g_bRunning || g_bWarStarted)
	{
		g_hTimer = null;
		return Plugin_Stop;
	}
	
	float flGameTime;
	flGameTime = GetGameTime();
	
	if (!g_bCountDownPlayed && (g_flEndTime - flGameTime <= 10.0))
	{
		g_bCountDownPlayed = true;
		PlaySound(GS_CountDown, _, PT_All, _);
	}
	
	if (flGameTime >= g_flEndTime)
	{
		g_hTimer = null;
		StartTheWar();
		return Plugin_Stop;
	}
	
	for (int i, j, client; i < g_iTeamsCount; i++)
	{
		for (j = 0; j < g_iTeamPlayersCount[i]; j++)
		{
			client = g_iTeamPlayersIds[i][j];
			SetHudTextParams(0.1, 0.65, 0.1, 0, 255, 255, 128, 0, 1.0, 0.1, 0.1);
			ShowHudText(client, 0, "Your team color is: %s", g_szTeamColorName[ g_iPlayerTeam[client] ]);
		}
	}
	
	PrintHintTextToAll("War will start in: <font color=\"#FF0000\">%0.1f seconds", g_flEndTime - flGameTime, g_flEndTime - flGameTime);
	
	
	// Add count down sound effects.
	return Plugin_Continue;
}

void StartTheWar()
{
	// Give Guns.
	g_bWarStarted = true;
	CPrintToChatAll("\x06----- LET THE HUNT BEGIN --------");
	
	PlaySound(GS_Start, _, PT_All);
	
	Timer_UpdateHintText(g_hTimer);
	g_hTimer = CreateTimer(1.0, Timer_UpdateHintText, _, TIMER_REPEAT);
	
	g_iOldTeammatesAreEnemies = ConVar_TeammatesAreEnemies.IntValue;
	ConVar_TeammatesAreEnemies.IntValue = 1;
	
	if (g_bThirdPersonPlugin)
	{
		ThirdPerson_SetGlobalLockMode(TPT_None);
	}
}

public Action Timer_UpdateHintText(Handle hTimer)
{
	if (!g_bRunning || !g_bWarStarted)
	{
		g_hTimer = null;
		return Plugin_Stop;
	}
	
	for (int i, j, client; i < g_iTeamsCount; i++)
	{
		for (j = 0; j < g_iTeamPlayersCount[i]; j++)
		{
			client = g_iTeamPlayersIds[i][j];
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
	char szPrintText[512];
	
	// --- Format - Update this later to include teammates names.
	if (iAliveCount)
	{
		int iLen;
		iLen += FormatEx(szPrintText, sizeof szPrintText, 
			// Old Method wiht hint text
			//"Team <font color=\"#%02X%02X%02X\">%s</font><br>
			//<font color=\"#00FF00\">ALIVE</font>
			//Team Players: %d<br>", 
			// New
			"Team '%s'\n\
			ALIVE players: %d\n", 
			//gTeamColor[g_iPlayerTeam[client]][TC_R], gTeamColor[g_iPlayerTeam[client]][TC_G], gTeamColor[g_iPlayerTeam[client]][TC_B],
			g_szTeamColorName[ g_iPlayerTeam[client] ],
			iAliveCount);
		//int iStart = iLen
		int iC;
		
		for (int i, otherclient; i < iTeamCount; i++)
		{
			otherclient = g_iTeamPlayersIds[iTeam][i];
			if (IsClientInGame(otherclient) && IsPlayerAlive(otherclient))
			{
				/*
				if (iLen - iStart > 100)
				{
					iStart = iLen;
					iLen += FormatEx(szPrintText[iLen], sizeof(szPrintText) - iLen, "<br>");
				}*/
				
				iLen += FormatEx(szPrintText[iLen], sizeof(szPrintText) - iLen, "%N%s", otherclient, ++iC < iAliveCount ? ", " : "");
			}
		}
	}
	
	else
	{
		FormatEx(szPrintText, sizeof szPrintText, "Your team has LOST! All members died!");
	}
	
	SetHudTextParams(0.1, 0.65, 1.0, 0, 255, 255, 128, 0, 1.0, 0.1, 0.1);
	ShowHudText(client, 0, szPrintText);
}

bool CheckWin()
{
	int iCount, iPlayers[MAXPLAYERS];
	iCount = GetPlayersCustom(iPlayers, true);
	
	if (!iCount)
	{
		if (g_bDaysAPI)
		{
			g_iWinningTeam = Team_None;
			DaysAPI_EndDay(g_szIntName);
		}
		
		else
		{
			EndGame(Team_None);
		}
		return true;
	}
	
	/*/ / Not needed
	if (iCount == 1)
	{
		//EndGame(g_iPlayerTeam[iPlayers[0]]);
		int iTeam = g_iPlayerTeam[iPlayers[0]];
		DaysAPI_EndDay(g_szIntName, g_iTeamPlayersIds[iTeam], g_iTeamPlayersCount[iTeam], iTeam);
		return true;
	}  */
	
	int iTeam = g_iPlayerTeam[iPlayers[0]];
	for (int i = 1; i < iCount; i++)
	{
		if (iTeam != g_iPlayerTeam[iPlayers[i]])
		{
			// Other players of different teams are still alive.
			return false;
		}
	}
	
	if (g_bDaysAPI)
	{
		g_iWinningTeam = iTeam;
		DaysAPI_EndDay(g_szIntName);
	}
	
	else
	{
		EndGame(iTeam);
	}
	
	return true;
}

public DayStartReturn DaysAPI_TeamWarStart(bool bWasPlanned)
{
	PrintToServer("************************************************ START DAY ****************************");
	return StartDay();
}

public void DaysAPI_TeamWarEnd(any data)
{
	if(g_iWinningTeam != Team_None)
	{
		DaysAPI_ResetDayWinners(); 
		DaysAPI_SetDayWinners("winner", g_iTeamPlayersIds[g_iWinningTeam], g_iTeamPlayersCount[g_iWinningTeam]);
		
		int iHighestElimTeam = Team_None;
		int iElims = 0; // Initialize at 0 because we want it to be more than 0;
		
		for (int i; i < g_iTeamsCount; i++)
		{
			if(g_iTeam_TeamsEliminated[i] > iElims)
			{
				iElims = g_iTeam_TeamsEliminated[i];
				iHighestElimTeam = i;
			}
		}
		
		if (iHighestElimTeam != Team_None)
		{
			DaysAPI_SetDayWinners("bonus_most_eliminations", g_iTeamPlayersIds[iHighestElimTeam], g_iTeamPlayersCount[iHighestElimTeam]);
		}
	}
	
	EndGame(g_iWinningTeam);
}

void EndGame(int iTeam)
{	
	ResetGame();
	Hooks(false);
	SetConVarInt(ConVar_TeammatesAreEnemies, g_iOldTeammatesAreEnemies, false, false);
	
	int iPlayers[MAXPLAYERS], iCount;
	iCount = GetPlayersCustom(iPlayers, true);
	
	for (int i; i < iCount; i++)
	{
		ApplyPlayerEffects(iPlayers[i], false);
	}
	
	if (Team_None == iTeam)
	{
		CPrintToChatAll("\x04*** No one won the \x03team war\x04!");
		return;
	}
	
	CPrintToChatAll("\x05** The war has ended. Team \x03%s \x05has won the WAAAR!", g_szTeamColorName[iTeam]);
	
	// Add win stuff here.
	// Win sounds, effects, fireworks, bla bla.
	PlaySound(GS_Win, 0, PT_All, 0);
}

int PutPlayerInTeam(int client, bool bAlive)
{
	int iTeam = Team_None, iCount, iLastCount;
	for (int i, j; i < g_iTeamsCount; i++)
	{
		for (j = 0; j < g_iTeamPlayersCount[i]; j++)
		{
			if (IsClientInGame(g_iTeamPlayersIds[i][j]))
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
	
	if (iTeam == Team_None)
	{
		iTeam = GetRandomInt(Team_None + 1, g_iTeamsCount - 1);
	}
	
	g_iPlayerTeam[client] = iTeam;
	g_iTeamPlayersIds[iTeam][g_iTeamPlayersCount[iTeam]++] = client;
	
	if (bAlive)
	{
		g_iTeamPlayersAlive[iTeam]++;
	}
	
	return iTeam;
}

void ResetGame()
{
	SetArrayValue(g_iPlayerTeam, sizeof g_iPlayerTeam, Team_None, 0);
	SetArrayValue(g_iTeamPlayersCount, sizeof g_iTeamPlayersCount, 0, 0);
	SetArrayValue(g_iTeamPlayersAlive, sizeof g_iTeamPlayersAlive, 0, 0);
	SetArrayValue(g_iTeam_TeamsEliminated, sizeof g_iTeam_TeamsEliminated, 0, 0);
	
	g_bRunning = false;
	g_bWarStarted = false;
	g_bCountDownPlayed = false;
	
	DestroyHandle(g_hTimer);
}

void DestroyHandle(Handle &handle)
{
	if (handle != null)
	{
		delete handle;
		handle = null;
	}
}

void SetArrayValue(any[] iArray, int iSize, any value, int iStart)
{
	for (int i = iStart; i < iSize; i++)
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
			g_bHooks = true;
			HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
			HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		}
		
		case false:
		{
			if (g_bHooks)
			{
				UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
				UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
				g_bHooks = false;
			}
		}
	}
}

void PlaySound(GameSounds Sound, int iTeam = Team_None, PlayTo iPlayTo = PT_Client, int iDestination = 0)
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
					if (g_iEliminationSoundsElimCount[i] == iEliminationsThisRound)
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
			
			FormatEx(szSound, sizeof szSound, "%s/%s", SOUND_FOLDER, g_szEliminationSounds[iSoundIndex[GetRandomInt(0, iSoundsCount - 1)]]);
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
			iCount = GetPlayersCustom(iPlayers);
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
				if (!IsClientInGame((client = g_iTeamPlayersIds[iDestination][i])))
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
		EmitSoundToClientAny(client, szSound);
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
		if (g_iMaxTeams > MAXTEAMS || g_iMaxTeams <= 1)
		{
			g_iMaxTeams = MAXTEAMS;
		}
	}
}

void PrecacheSoundFiles()
{
	int iSize, i;
	char szFile[PLATFORM_MAX_PATH];
	
	iSize = sizeof g_szEliminationSounds;
	
	for (i = 0; i < iSize; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", SOUND_FOLDER, g_szEliminationSounds[i]);
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

stock bool IsValidPlayer(int client)
{
	if (0 < client <= MAXPLAYERS)
	{
		if (IsClientInGame(client))
			return true;
	}
	
	return false;
}

stock void StripWeapons(int client)
{
	int iPrimaryWeapon = GetPlayerWeaponSlot(client, 0);
	int iSecondaryWeapon = GetPlayerWeaponSlot(client, 1);
	
	if (IsValidEdict(iPrimaryWeapon))
	{
		RemovePlayerItem(client, iPrimaryWeapon);
		RemoveEdict(iPrimaryWeapon);
	}
	
	if (IsValidEdict(iSecondaryWeapon))
	{
		RemovePlayerItem(client, iSecondaryWeapon);
		RemoveEdict(iSecondaryWeapon);
	}
} 