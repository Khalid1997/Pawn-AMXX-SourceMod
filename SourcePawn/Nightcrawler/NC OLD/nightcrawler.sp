#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
//#include <the_khalid_inc>
#include <getplayers>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

#define CS_TEAM_NC			CS_TEAM_T
#define CS_TEAM_SURVIVOR	CS_TEAM_CT

new const String:PLUGIN_LOG_FILE[] = "addons/sourcemod/logs/nightcrawler.log";
new const String:PLUGIN_CHAT_PREFIX[] = "\x04[NightCrawlers]";
new const String:g_szManaName[] = "Mana";
new const String:g_szNightcrawlerTeamName[] = "NightCrawlers";
new const String:g_szNightcrawlerName[] = "Nightcrawler";
new const String:g_szSurvivorTeamName[] = "Survivors";
new const String:g_szSurvivorName[] = "Survivor";

new const String:MODEL_BEAM[] = "materials/sprites/laserbeam.vmt";

// -- Game State --
bool g_bRunning = false;
bool g_bRoundEnd = false;

#define MODE_RANDOM 0
#define MODE_KILL	1
#define MODE_QUEUE	2

#define WEAPONTYPE_SECONDARY 2
#define WEAPONTYPE_PRIMARY 1

#define HINTMSG_UPDATE_TIME 0.5

// -- Settings --
int g_iMinPlayers = 2;
int g_iChooseNCPlayersMode = MODE_RANDOM;
float g_flNCRatio = 3.0;
float g_flLaserRatio = 3.0;
int g_iPointsPerKill_NC = 3;
int g_iPointsHSBonus = 1;
int g_iPointsPerKill_Survivor = 1;

float g_flMaxMana = 200.0;
float g_flManaRegenTime = 1.5;
float g_flManaRegenAmount = 3.5;
float g_flTeleportManaCost = 75.0;

float g_flChooseWeaponTime = 25.0;

char g_szLightStyle[3] = "b";

float g_flNCVisibleTime = 2.3;
bool g_bBlockFallDamge_NC = true;

bool g_bRemoveShadows = true;
bool g_bMakeFog = true;

// -- Player Data --
bool g_bDontShowPlayer[MAXPLAYERS];
bool g_bKilledNC[MAXPLAYERS];
bool g_bLaser[MAXPLAYERS];
int g_iLaserEnt[MAXPLAYERS];
int g_iLaserCount;

// WeaponMenu;
bool g_bHasChosenWeaponsThisRound[MAXPLAYERS];
int g_iWeaponMenuStep[MAXPLAYERS];
int g_iLastWeapons[MAXPLAYERS][2];
bool g_bSaveLastWeapons[MAXPLAYERS];

// ManaStuff;
float g_flNextManaGain[MAXPLAYERS];
int g_iPlayerPoints[MAXPLAYERS];
float g_flPlayerMana[MAXPLAYERS];

// -- Misc --
bool g_bVIPPlugin = false;
Handle g_hTimer, g_hHintMessageTimer;
bool g_bLate;
int g_iFogEnt;

Menu g_hShopMenu;
Menu g_hMainMenu;
Menu g_hWeaponMenu_Main, g_hWeaponMenu_Primary, g_hWeaponMenu_Sec;

StringMap g_Trie_WeaponSuffix;
ArrayList g_Array_WeaponName, 
g_Array_WeaponGiveName, 
g_Array_WeaponSuffix, 
g_Array_WeaponType;

float g_flWeaponMenuExpireTime;

// --- Shop Items ---
#define MAX_SHOP_ITEMS 1
bool g_bShopItemEnabled[MAX_SHOP_ITEMS];
int g_szShopItemName[MAX_SHOP_ITEMS], g_iShopItemCost[MAX_SHOP_ITEMS];

char g_szNightcrawlerPlayerModels[1][PLATFORM_MAX_PATH];
char g_szSurvivorPlayerModels[1][PLATFORM_MAX_PATH];
char g_szPrecacheFiles[1][PLATFORM_MAX_PATH];

// --------------------------------------------------------------------------
//								Plugin Start
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
//								Essential forwards (Plugin forwards)
// --------------------------------------------------------------------------
public void OnLibraryAdded(const char[] szLibName)
{
	g_bVIPPlugin = true;
}

public void OnLibraryRemoved(const char[] szLibName)
{
	g_bVIPPlugin = false;
}

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrMax)
{
	g_bLate = bLate;
}

// This is essential for laser and climb functions.
public void OnGameFrame()
{
	static int iPlayers[MAXPLAYERS];
	static int iCount;
	
	iCount = GetPlayers(iPlayers, GP_Flag_Alive, GP_Team_First | GP_Team_Second);
	
	for (int i; i < iCount; i++)
	{
		OnThink(iPlayers[i]);
	}
}

public void OnPluginStart()
{
	AddCommandListener(Command_Teleport, "drop");
	//RegConsoleCmd("jointeam", Command_JoinTeam);
	
	//RegConsoleCmd("sm_shop", Command_DisplayShopMenu);
	
	RegConsoleCmd("sm_guns", Command_DisplayWeaponsMenu);
	RegConsoleCmd("sm_gun", Command_DisplayWeaponsMenu);
	
	RegConsoleCmd("sm_menu", Command_DisplayMainMenu);
	RegConsoleCmd("sm_modmenu", Command_DisplayMainMenu);
	RegConsoleCmd("sm_mm", Command_DisplayMainMenu);
	
	HookEvent("round_prestart", Event_RoundPreStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	if (g_bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				//esht'3l allah yr'90a 3lek
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnMapStart()
{
	LoadSettingsFromFile();
	PrecacheFiles();
	
	g_hTimer = CreateTimer(10.0, Timer_CheckGameState, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	g_bRunning = false;
	
	// Light?
	SetLightStyle(0, g_szLightStyle);
	
	if (g_bMakeFog)
	{
		// Make Fog
		g_iFogEnt = CreateFog();
	}
	
	if (g_bRemoveShadows)
	{
		// Remove Shadows
		CreateEntityByName("shadow_control");
		int iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "shadow_control")) != -1)
		{
			// I hope I'm doing it right 
			// Also may not work because "This feature is only available in the Half Life 2 engine" 
			SetVariantInt(1);
			AcceptEntityInput(iEnt, "SetShadowsDisabled");
		}
	}
}

public void OnMapEnd()
{
	g_bRunning = false;
	
	delete g_hTimer;
	RemoveEdict(g_iFogEnt);
}

public void OnConfigsExecuted()
{
	//LoadSettingsFromFile();
}

public void OnClientDisconnect(int client)
{
	if(g_bLaser[client])
	{
		if(IsValidEntity(g_iLaserEnt[client]))
		{
			RemoveEdict(g_iLaserEnt[client]);
		}
	}
	
	if (GetClientTeam(client) == CS_TEAM_SURVIVOR && IsPlayerAlive(client))
	{
		CheckLastSurvivor();
	}
	
	MakeHooks(client, false);
}

public OnClientPutInServer(client)
{
	g_iLastWeapons[client][0] = -1;
	g_iLastWeapons[client][1] = -1;
	g_bSaveLastWeapons[client] = false;
	g_bHasChosenWeaponsThisRound[client] = false;
	
	ResetRoundVars(client, CS_TEAM_NONE);
	MakeHooks(client, true);
	
	SetVariantString("MyFog");
	AcceptEntityInput(client, "SetFogController");
}

void LoadSettingsFromFile()
{
	//Handle hKv = CreateKeyValues("NightCrawler");
	//StringMap hWeaponSuffix = CreateTrie();
	//FileToKeyValues(hKv, "addons/sourcemod/cfg/nightcrawler.cfg");
	
	//delete hKv;
	//KvJumpToKey(hKv, 
	
	g_Array_WeaponName = CreateArray(25);
	g_Array_WeaponGiveName = CreateArray(25);
	g_Array_WeaponSuffix = CreateArray(1);
	g_Array_WeaponType = CreateArray(1);
	
	g_Trie_WeaponSuffix = CreateTrie();
	ParseWeaponsMenuFile();
	BuildMenus();
}

void ParseWeaponsMenuFile()
{
	PrintToServer("----------------------------------------------------- Yes");
	char szFile[PLATFORM_MAX_PATH];
	char szLine[125];
	
	new String:szStringParts[4][35];
	
	int iStep = 0;
	
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/nightcrawler_weaponmenu.ini");
	
	PrintToServer("Path: %s", szFile);
	
	File f = OpenFile(szFile, "r");
	
	if (f == INVALID_HANDLE)
	{
		CreateWeaponsMenuFile(szFile);
		ParseWeaponsMenuFile();
		return;
	}
	
	// Format:
	// Order Matters
	// Type:Suffix:"give_name":"Menu Name"
	while (ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		PrintToServer("Read Line: %s", szLine);
		
		if (szLine[0] == ';' || szLine[0] == '#' || (szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		if (StrEqual(szLine, "[Weapon Suffixes]", false))
		{
			iStep = 1;
		}
		
		else if (StrEqual(szLine, "[Weapons]", false))
		{
			iStep = 2;
		}
		
		switch (iStep)
		{
			case 0:
			{
				continue;
			}
			case 1:
			{
				ExplodeString(szLine, ":", szStringParts, 2, sizeof szStringParts[], true);
				CleanStrings(szStringParts, 2, sizeof szStringParts[]);
				
				SetTrieString(g_Trie_WeaponSuffix, szStringParts[0], szStringParts[1]);
			}
			case 2:
			{
				PrintToServer("Add Line to gun menu %s", szLine);
				ExplodeString(szLine, ":", szStringParts, sizeof szStringParts, sizeof szStringParts[], true);
				CleanStrings(szStringParts, sizeof szStringParts, sizeof szStringParts[]);
				
				PushArrayCell(g_Array_WeaponType, StringToInt(szStringParts[0]));
				PushArrayCell(g_Array_WeaponSuffix, StringToInt(szStringParts[1]));
				PushArrayString(g_Array_WeaponGiveName, szStringParts[2]);
				PushArrayString(g_Array_WeaponName, szStringParts[3]);
			}
		}
	}
}

void CreateWeaponsMenuFile(char[] szFile)
{
	File f = OpenFile(szFile, "w+");
	
	if (f == INVALID_HANDLE)
	{
		LogError("Wrong path: %s", szFile);
		return;
	}
	
	WriteFileLine(f, "# Auto-Generated File");
	WriteFileLine(f, "# The Weapons menu will be generated based on this file.");
	WriteFileLine(f, "[Weapon Suffixes]");
	WriteFileLine(f, "# In this part, you will assign a number and a suffix using the following format (A value of 0 means no suffix):");
	WriteFileLine(f, "1:Rifle");
	WriteFileLine(f, "2:Sniper Rifle");
	WriteFileLine(f, "3:Shotgun");
	WriteFileLine(f, "4:SMG");
	WriteFileLine(f, "5:Pistol");
	WriteFileLine(f, "");
	WriteFileLine(f, "[Weapons]");
	WriteFileLine(f, "# Order matters! First weapons appear first in menu");
	WriteFileLine(f, "# Format:");
	WriteFileLine(f, "# WeaponType(1 for primary, 2 for secondary):WeaponSuffixNumber:WeaponGiveName:WeaponName");
	WriteFileLine(f, "# Examples:");
	WriteFileLine(f, "1:1:weapon_m4a1:M4A4");
	WriteFileLine(f, "1:1:weapon_ak47:AK-47");
	WriteFileLine(f, "1:2:weapon_awp:AWP");
	WriteFileLine(f, "1:4:weapon_p90:P90");
	WriteFileLine(f, "2:5:weapon_glock:Glock-18");
	
	delete f;
}

void CleanStrings(String:szStringParts[][], int iArraySize, int iStringSize)
{
	for (int i; i < iArraySize; i++)
	{
		TrimString(szStringParts[i]);
		ReplaceString(szStringParts[i], iStringSize, "\"", "");
	}
}

// --------------------------------------------------------------------------
//						Registered Commands callbacks
// --------------------------------------------------------------------------
public Action Command_DisplayMainMenu(int client, int iArgCount)
{
	DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
}

public Action Command_DisplayWeaponsMenu(int client, int iArgCount)
{
	if (!CanDisplayWeaponMenu(client, true))
	{
		return;
	}
	
	DisplayMenu(g_hWeaponMenu_Main, client, MENU_TIME_FOREVER);
}

bool CanDisplayWeaponMenu(int client, bool bPrintChat = false)
{
	if (IsPlayerAlive(client))
	{
		if (GetGameTime() > g_flWeaponMenuExpireTime)
		{
			if (bPrintChat)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Choosing weapons time has expired. You won't be able to choose new weapons until you die or next round.");
			}
			
			return false;
		}
		
		if (g_bHasChosenWeaponsThisRound[client])
		{
			if (bPrintChat)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have already chosen weapons for this round.");
			}
			
			return false;
		}
	}
	
	PrintToServer("Can Display Gun Menu Return: TRUE");
	return true;
}

bool CanDisplayShopMenu(int client, bool bPrintChat = false)
{
	if (!IsPlayerAlive(client))
	{
		if (bPrintChat)
		{
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Shop is only available to alive players.");
		}
		
		return false;
	}
	
	if (GetClientTeam(client) != CS_TEAM_SURVIVOR)
	{
		if (bPrintChat)
		{
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Shop is only available to survivors.");
		}
		
		return false;
	}
	
	return true;
}

public Action Command_DisplayShopMenu(int client, int iArgCount)
{
	if (!CanDisplayShopMenu(client, true))
	{
		return;
	}
	
	DisplayMenu(g_hShopMenu, client, MENU_TIME_FOREVER);
}

public Action Command_JoinTeam(int client, int iArgs)
{
	char szArg[3];
	GetCmdArg(1, szArg, sizeof szArg);
	
	int iJoinTeam = StringToInt(szArg);
	int iTeam = GetClientTeam(client);
	
	if (iJoinTeam == iTeam)
	{
		return Plugin_Continue;
	}
	
	if (iTeam == CS_TEAM_NONE || iTeam == CS_TEAM_SPECTATOR)
	{
		if (iJoinTeam == CS_TEAM_SPECTATOR || iJoinTeam == CS_TEAM_SURVIVOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	if (iTeam == CS_TEAM_NC)
	{
		if (iJoinTeam == CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_Teleport(int client, const char[] szCommand, int iArgCount)
{
	if (GetClientTeam(client) == CS_TEAM_NC && IsPlayerAlive(client))
	{
		if (g_flPlayerMana[client] > g_flTeleportManaCost || g_bRoundEnd)
		{
			if (TeleportClient(client))
			{
				if (!g_bRoundEnd)
				{
					g_flPlayerMana[client] -= g_flTeleportManaCost;
				}
			}
			
			else PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Teleport failed. Try to aim somewhere else");
		}
		
		else PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are missing %0.1f %s to teleport", g_flTeleportManaCost - g_flPlayerMana[client], g_szManaName);
	}
}

public void OnThink(int client)
{
	switch (GetClientTeam(client))
	{
		case CS_TEAM_NC:
		{
			static float flGameTime;
			flGameTime = GetGameTime();
			if (g_flNextManaGain[client] < flGameTime)
			{
				g_flNextManaGain[client] = flGameTime + g_flManaRegenTime;
				
				if (g_flPlayerMana[client] < g_flMaxMana)
				{
					if (g_flPlayerMana[client] + g_flManaRegenAmount > g_flMaxMana)
					{
						g_flPlayerMana[client] = g_flMaxMana;
					}
					
					else g_flPlayerMana[client] += g_flManaRegenAmount;
				}
			}
			
			if (GetClientButtons(client) & IN_USE)
			{
				DoClimb(client);
			}
		}
		
		case CS_TEAM_SURVIVOR:
		{
			MoveLaserEnt(client);
		}
	}
}

public bool TraceFilter_Callback(int iEnt, int iContentMask, int client)
{
	if (iEnt == client)
	{
		return false;
	}
	
	return true;
}

// --------------------------------------------------------------------------
//								Events
// --------------------------------------------------------------------------
public void Event_PlayerSpawn(Event event, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsPlayerAlive(client))
	{
		return;
	}
	
	if (GetClientTeam(client) == CS_TEAM_NC)
	{
		//SetEntityModel(client, g_szNightcrawlerPlayerModel);
		SetEntityRenderColor(client, 0, 255, 0, 128);
		
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are a %s", g_szNightcrawlerName);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are invisible; You invisibility will break if you get shot!");
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Your objective is to kill the %ss", g_szSurvivorTeamName);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You can press G to teleport (drop weapon button) or E to climb walls (+use key)");
	}
	
	else
	{
		//SetEntityModel(client, g_szSurvivorPlayerModel[GetRandomInt(0, sizeof(g_szSurvivorPlayerModel) - 1)]);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are a %s", g_szSurvivorName);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You objective is to kill the %ss", g_szNightcrawlerName);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You can press G to teleport (drop weapon button) or E to climb walls (+use key)");
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Use your items to assist you to complete your objective.");
		
		if(g_bSaveLastWeapons[client])
		{
			GiveLastWeapons(client);
		}
		
		else
		{
			if(CanDisplayWeaponMenu(client, true))
			{
				g_iWeaponMenuStep[client] = WEAPONTYPE_PRIMARY;
				DisplayMenu(g_hWeaponMenu_Main, client, MENU_TIME_FOREVER);
				PrintToServer("Gun Menu Displayed");
			}
			
			PrintToServer("Didnt Display");
		}
	}
}

public void Event_RoundPreStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_flWeaponMenuExpireTime = GetGameTime() + g_flChooseWeaponTime;
	SetArrayValue(g_bHasChosenWeaponsThisRound, sizeof g_bHasChosenWeaponsThisRound, false);
}

public void Event_RoundStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_bRoundEnd = false;
	
	PluginLog("RoundStart #1");
	
	if (!g_bRunning)
	{
		return;
	}
	
	int iHumans[MAXPLAYERS];
	int iCount;
	
	PluginLog("RoundStart #2");
	for (int client = 1, iTeam; client <= MaxClients; client++)
	{
		if (!(IsClientInGame(client) && IsPlayerAlive(client)))
		{
			continue;
		}
		
		if ((iTeam = GetClientTeam(client)) == CS_TEAM_SURVIVOR)
		{
			iHumans[iCount++] = client;
		}
		
		ResetRoundVars(client, iTeam);
	}
	
	PluginLog("RoundStart #3");
	g_hHintMessageTimer = CreateTimer(HINTMSG_UPDATE_TIME, Timer_HintMessage, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	GiveLasers(iHumans, iCount);
	CheckLastSurvivor();
	PluginLog("RoundStart #4");
}

public void Event_RoundEnd(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_bRoundEnd = true;
	delete g_hHintMessageTimer;
	
	if (!g_bRunning)
	{
		return;
	}
	
	ChooseNCPlayers();
	//ChangePlayersTeams();
}

public void Event_PlayerDeath(Event event, char[] szEventName, bool bDontBroadcast)
{
	int iKiller = GetClientOfUserId(GetEventInt(event, "attacker"));
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(iVictim) == CS_TEAM_SURVIVOR)
	{
		CheckLastSurvivor();
	}
	
	if (IsValidPlayer(iKiller))
	{
		switch (GetClientTeam(iKiller))
		{
			case CS_TEAM_NC:
			{
				g_iPlayerPoints[iKiller] += g_iPointsPerKill_NC;
				
				PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", g_iPointsPerKill_NC, g_szSurvivorName);
			}
			case CS_TEAM_SURVIVOR:
			{
				g_bKilledNC[iKiller] = true;
				if (GetEventInt(event, "headshot"))
				{
					PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", g_iPointsPerKill_Survivor + g_iPointsHSBonus, g_szNightcrawlerName);
					g_iPlayerPoints[iKiller] += (g_iPointsPerKill_Survivor + g_iPointsHSBonus);
				}
				
				else PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", g_iPointsPerKill_Survivor, g_szNightcrawlerName);
			}
		}
	}
}
// --------------------------------------------------------------------------
//								SDK Hooks
// --------------------------------------------------------------------------

void MakeHooks(int client, bool bStatus)
{
	if (bStatus)
	{
		SDKHook(client, SDKHook_OnTakeDamage, SDKHookCallback_OnTakeDamage);
		SDKHook(client, SDKHook_SetTransmit, SDKHookCallback_SetTransmit);
		
		SDKHook(client, SDKHook_Touch, SDKHookCallback_Touch);
		
		SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKHookCallback_WeaponSwitch);
		SDKHook(client, SDKHook_WeaponCanUse, SDKHookCallback_WeaponSwitch);
		SDKHook(client, SDKHook_WeaponEquip, SDKHookCallback_WeaponSwitch);
		
		//SDKHook(client, SDKHook_ThinkPost, SDKHookCallback_ThinkPost);
	}
	
	else
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, SDKHookCallback_OnTakeDamage);
		SDKUnhook(client, SDKHook_SetTransmit, SDKHookCallback_SetTransmit);
		
		SDKUnhook(client, SDKHook_Touch, SDKHookCallback_Touch);
		
		SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDKHookCallback_WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponCanUse, SDKHookCallback_WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponEquip, SDKHookCallback_WeaponSwitch);
		
		//SDKUnhook(client, SDKHook_ThinkPost, SDKHookCallback_ThinkPost);
	}
}

public Action SDKHookCallback_Touch(int client, int iEnt)
{
	//PrintToServer("Touch %d", iEnt);
}

public Action SDKHookCallback_WeaponSwitch(int client, int iWeapon)
{
	if (GetClientTeam(client) == CS_TEAM_NC)
	{
		char szWeaponName[35];
		GetEntityClassname(iWeapon, szWeaponName, sizeof szWeaponName);
		
		if (!StrEqual(szWeaponName, "weapon_knife"))
		{
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (GetClientTeam(victim) == CS_TEAM_NC)
	{
		if (damagetype & DMG_FALL)
		{
			if (g_bBlockFallDamge_NC)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
		else
		{
			g_bDontShowPlayer[victim] = false;
			CreateTimer(g_flNCVisibleTime, Timer_MakeNCInvisibleAgain, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCallback_SetTransmit(client, entity)
{
	if (client == entity)
	{
		return Plugin_Continue;
	}
	
	if (g_bRoundEnd)
	{
		return Plugin_Continue;
	}
	
	if (GetClientTeam(client) == GetClientTeam(entity))
	{
		return Plugin_Continue;
	}
	
	if (g_bDontShowPlayer[client])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// --------------------------------------------------------------------------
//								Menu Stuff
// --------------------------------------------------------------------------
void BuildMenus()
{
	BuildMainMenu();
	BuildWeaponsMenu();
	//sBuildItemMenu();
	BuildShopMenu();
}

void BuildMainMenu()
{
	g_hMainMenu = CreateMenu(MenuHandler_MainMenu, MENU_ACTIONS_DEFAULT);
	
	//SetMenuExitButton(g_hMainMenu, true);
	SetMenuTitle(g_hMainMenu, "Nightcrawler Menu - [By: Khalid]");
	
	AddMenuItem(g_hMainMenu, "0", "Choose Weapons");
	AddMenuItem(g_hMainMenu, "1", "Items Menu");
	AddMenuItem(g_hMainMenu, "2", "Shop Menu");
	
	if (g_iChooseNCPlayersMode == MODE_QUEUE)
	{
		AddMenuItem(g_hMainMenu, "3", "Enter Nightcrawler Queue");
	}

	AddMenuItem(g_hMainMenu, "998", "Help");
	AddMenuItem(g_hMainMenu, "999", "Admin Menu");
}

enum
{
	WPNMenu_NewWeapons, 
	WPNMenu_LastWeapons, 
	WPNMenu_LastWeaponsAndSave
};

void BuildWeaponsMenu()
{
	g_hWeaponMenu_Main = CreateMenu(MenuHandler_WeaponMenu_Main, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(g_hWeaponMenu_Main, "Select Weapons:");
	AddMenuItem(g_hWeaponMenu_Main, "0", "Select New Weapons");
	AddMenuItem(g_hWeaponMenu_Main, "1", "Select Last Weapons");
	AddMenuItem(g_hWeaponMenu_Main, "2", "Select Last Weapons and Save (Auto Give)");
	
	char szDisplayName[35], szWeaponName[25];
	int iWeaponSuffix;
	
	char szInfo[3];
	char szWeaponSuffix[18];
	
	g_hWeaponMenu_Primary = CreateMenu(MenuHandler_WeaponMenu_ChooseWeapon, MENU_ACTIONS_DEFAULT | MenuAction_Display);
	//SetMenuTitle(g_hWeaponsMenu_Primary, "Select Primary Weapon:");
	
	g_hWeaponMenu_Sec = CreateMenu(MenuHandler_WeaponMenu_ChooseWeapon, MENU_ACTIONS_DEFAULT | MenuAction_Display);
	//SetMenuTitle(g_hWeaponsMenu_Primary, "Select Seconadry Weapon:");
	
	int iSize = GetArraySize(g_Array_WeaponName);
	for (int i; i < iSize; i++)
	{
		GetArrayString(g_Array_WeaponName, i, szWeaponName, sizeof szWeaponName);
		
		iWeaponSuffix = GetArrayCell(g_Array_WeaponSuffix, i);
		if (iWeaponSuffix != 0)
		{
			IntToString(iWeaponSuffix, szInfo, sizeof szInfo);
			if (!GetTrieString(g_Trie_WeaponSuffix, szInfo, szWeaponSuffix, sizeof szWeaponSuffix))
			{
				FormatEx(szDisplayName, sizeof szDisplayName, "%s", szWeaponName);
			}
			
			else FormatEx(szDisplayName, sizeof szDisplayName, "%-12s [%s]", szWeaponName, szWeaponSuffix);
		}
		
		else FormatEx(szDisplayName, sizeof szDisplayName, "%s", szWeaponName);
		
		IntToString(i, szInfo, sizeof szInfo);
		switch (GetArrayCell(g_Array_WeaponType, i))
		{
			case WEAPONTYPE_PRIMARY:
			{
				AddMenuItem(g_hWeaponMenu_Primary, szInfo, szDisplayName);
			}
			
			case WEAPONTYPE_SECONDARY:
			{
				AddMenuItem(g_hWeaponMenu_Sec, szInfo, szDisplayName);
			}
		}
	}
	
	delete g_Array_WeaponName;
	//delete g_Array_WeaponGiveName;
	delete g_Array_WeaponType;
	delete g_Array_WeaponSuffix;
	
	delete g_Trie_WeaponSuffix;
}

public int MenuHandler_WeaponMenu_Main(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		bool bShowAgain = false;
		bool bAlive = IsPlayerAlive(param1);
		if (bAlive && GetGameTime() > g_flWeaponMenuExpireTime)
		{
			PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "The time to choose the weapons has expired. You will need to wait for a new round.");
			return;
		}
		
		char szInfo[3];
		int iItemInfo;
		
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		iItemInfo = StringToInt(szInfo);
		
		switch (iItemInfo)
		{
			case WPNMenu_NewWeapons:
			{
				g_iWeaponMenuStep[param1] = WEAPONTYPE_PRIMARY;
				DisplayMenu(g_hWeaponMenu_Primary, param1, MENU_TIME_FOREVER);
			}
			
			case WPNMenu_LastWeapons:
			{
				if (g_iLastWeapons[param1][0] == -1 || g_iLastWeapons[param1][1] == -1)
				{
					PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You haven't even choosen a weapon!");
					bShowAgain = true;
				}
				
				else
				{
					if (bAlive)
					{
						g_bHasChosenWeaponsThisRound[param1] = true;
						GiveLastWeapons(param1);
					}
				}
			}
			
			case WPNMenu_LastWeaponsAndSave:
			{
				if (g_iLastWeapons[param1][0] == -1 || g_iLastWeapons[param1][1] == -1)
				{
					PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You haven't even choosen a weapon!");
					bShowAgain = true;
				}
				
				else
				{
					g_bSaveLastWeapons[param1] = true;
					
					if (bAlive)
					{
						g_bHasChosenWeaponsThisRound[param1] = true;
						GiveLastWeapons(param1);
					}
				}
			}
		}
		
		if (bShowAgain)
		{
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

public int MenuHandler_WeaponMenu_ChooseWeapon(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Display)
	{
		PrintToServer("Has chosen weapons.");
		g_bHasChosenWeaponsThisRound[param1] = true;
		
		switch (g_iWeaponMenuStep[param1])
		{
			case WEAPONTYPE_PRIMARY:
			{
				SetMenuTitle(menu, "Choose Primary:");
			}
			case WEAPONTYPE_SECONDARY:
			{
				SetMenuTitle(menu, "Choose Secondary:");
			}
		}
	}
	
	else if (action == MenuAction_Select)
	{
		int iItemInfo;
		char szInfo[3];
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		
		iItemInfo = StringToInt(szInfo);
		
		switch (g_iWeaponMenuStep[param1])
		{
			case WEAPONTYPE_PRIMARY:
			{
				CS_RemoveWeapon(param1, CS_SLOT_PRIMARY);
				
				g_iLastWeapons[param1][0] = iItemInfo;
				g_iWeaponMenuStep[param1] = WEAPONTYPE_SECONDARY;
				
				DisplayMenu(g_hWeaponMenu_Sec, param1, MENU_TIME_FOREVER);
			}
			case WEAPONTYPE_SECONDARY:
			{
				CS_RemoveWeapon(param1, CS_SLOT_SECONDARY);
				
				g_iLastWeapons[param1][1] = iItemInfo;
				g_iWeaponMenuStep[param1] = WEAPONTYPE_PRIMARY;
				//DisplayMenu(g_hItemMenu, param1, MENU_TIME_FOREVER);
			}
		}
		
		char szWeaponGiveName[35];
		GetArrayString(g_Array_WeaponGiveName, iItemInfo, szWeaponGiveName, sizeof szWeaponGiveName);
		GivePlayerItem(param1, szWeaponGiveName);
	}
}

bool GiveLastWeapons(int client)
{
	DisarmPlayer(client);
	
	char szWeaponGiveName[35];
	GetArrayString(g_Array_WeaponGiveName, g_iLastWeapons[client][0], szWeaponGiveName, sizeof szWeaponGiveName);
	GivePlayerItem(client, szWeaponGiveName);
	
	GetArrayString(g_Array_WeaponGiveName, g_iLastWeapons[client][1], szWeaponGiveName, sizeof szWeaponGiveName);
	GivePlayerItem(client, szWeaponGiveName);
}

void DisarmPlayer(int client)
{
	CS_RemoveAllWeapons(client, true, false);
}

void CS_RemoveWeapon(client, slot)
{
	int weapon_index = -1;
	while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		if (IsValidEntity(weapon_index))
		{
			/*
				if(slot == CS_SLOT_KNIFE )
				{
					break;
				}*/
			
			RemovePlayerItem(client, weapon_index);
			AcceptEntityInput(weapon_index, "kill");
		}
	}
}

void CS_RemoveAllWeapons(int client, bool StripBomb = false, bool bStripKnife = false)
{
	int weapon_index = -1;
	#define MAX_WEAPON_SLOTS 5
	
	for (int slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			if (IsValidEntity(weapon_index))
			{
				if ((slot == CS_SLOT_C4 && !StripBomb))
				{
					return;
				}
				
				if(slot == CS_SLOT_KNIFE && !bStripKnife)
				{
					break;
				}
				
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}


public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char szInfo[3];
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		
		bool bDisplayAgain;
		
		switch (StringToInt(szInfo))
		{
			case 0:
			{
				if (!CanDisplayWeaponMenu(param1, true))
				{
					bDisplayAgain = true;
				}
			}
			
			case 1:
			{
				/*
				if (!CanDisplayShopMenu(param1, true))
				{
					bDisplayAgain = true;
				}
				*/
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "The shop is still under developement.");
			}
			
			case 2:
			{
				
			}
			
			case 3:
			{
				PrintHelpMessagesInConsole(param1);
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "Everything you need to know about this mod has been printed in your console.");
				
				bDisplayAgain = true;
			}
			
			case 10:
			{
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "The admin menu is still under developement.");
			}
		}
		
		if (bDisplayAgain)
		{
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

void PrintHelpMessagesInConsole(client)
{
	PrintToConsole(client, "-------------------------------");
	PrintToConsole(client, "------  Nightcrawlers Mod -----");
	PrintToConsole(client, "-------------------------------");
	PrintToConsole(client, "Nightcrawlers are aliens that invaded the earth. Their objective is to hunt down the human surivors and obliterate them.");
	PrintToConsole(client, "--- How to play:");
	PrintToConsole(client, "-- As a %s:", g_szSurvivorName);
	PrintToConsole(client, "You are a %s. You have to survive until the end of the round or kill all the %s.", g_szSurvivorName, g_szNightcrawlerTeamName);
	PrintToConsole(client, "You can choose your guns, your (assisting) items, or buy upgrades from the shop.", g_szSurvivorName, g_szNightcrawlerTeamName);
	PrintToConsole(client, "The %s are invisible. They only turn visible when you hurt them.", g_szNightcrawlerTeamName);
	PrintToConsole(client, "-- As a %s:", g_szNightcrawlerName);
	PrintToConsole(client, "You are invisible, and you are only visible (for a limited amount of time) when you get hurt!");
	PrintToConsole(client, "You can climb walls using your '+use' key.");
	PrintToConsole(client, "You can teleport by clicking on the 'drop' button (the button that drops a gun). Teleporting costs you %0.2f %s", g_flTeleportManaCost, g_szManaName);
}

void BuildShopMenu()
{
	g_hShopMenu = CreateMenu(MenuHandler_Shop, MENU_ACTIONS_ALL);
	char szDisplayName[35];
	char szInfo[3];
	
	for (int i; i < MAX_SHOP_ITEMS; i++)
	{
		if (!g_bShopItemEnabled[i])
		{
			continue;
		}
		
		FormatEx(szDisplayName, sizeof szDisplayName, "%s [%d Points]", g_szShopItemName[i], g_iShopItemCost[i]);
		FormatEx(szInfo, sizeof szInfo, "%d", i);
		
		AddMenuItem(g_hShopMenu, szInfo, szDisplayName);
	}
}

public int MenuHandler_Shop(Menu menu, MenuAction action, int param1, int param2)
{
	char szInfo[3];
	int iItemIndex;
	
	bool bDisplayAgain = false;
	
	switch (action)
	{
		case MenuAction_End:
		{
			
		}
		
		case MenuAction_Cancel:
		{
			
		}
		
		case MenuAction_DisplayItem:
		{
			return 0;
		}
		
		case MenuAction_DrawItem:
		{
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iItemIndex = StringToInt(szInfo);
			
			if (!g_bShopItemEnabled[iItemIndex])
			{
				//RemoveMenuItem(menu, iItemIndex);
				return ITEMDRAW_DEFAULT;
			}
			
			if (g_iShopItemCost[iItemIndex] > 0 && g_iShopItemCost[iItemIndex] > g_iPlayerPoints[param1])
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Display:
		{
			SetMenuTitle(menu, "Nightcrawler Shop: [%d Points]", g_iPlayerPoints[param1]);
			return 0;
		}
		
		case MenuAction_Select:
		{
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iItemIndex = StringToInt(szInfo);
			
			if (!g_bShopItemEnabled[iItemIndex])
			{
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You are missing %d points to buy this item.", g_iShopItemCost[iItemIndex] - g_iPlayerPoints[param1]);
				bDisplayAgain = true;
			}
			
			if (g_iShopItemCost[iItemIndex] > g_iPlayerPoints[param1])
			{
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You are missing %d points to buy this item.", g_iShopItemCost[iItemIndex] - g_iPlayerPoints[param1]);
				bDisplayAgain = true;
			}
			
			else
			{
				g_iPlayerPoints[param1] -= g_iShopItemCost[iItemIndex];
				GivePlayerShopItem(param1, iItemIndex, false, 0);
			}
		}
	}
	
	if (bDisplayAgain)
	{
		DisplayMenu(menu, param1, MENU_TIME_FOREVER);
	}
	
	return 0;
}

// --------------------------------------------------------------------------
//								Timers
// --------------------------------------------------------------------------
public Action Timer_HintMessage(Handle hTimer)
{
	//int iPlayers[MAXPLAYERS], iCount;
	//iCount = GetPlayers(iPlayers, GetPlayersFlag_Alive, GP_TEAM_FIRST | GP_TEAM_SECOND);
	
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (!IsClientInGame(iPlayer) || !IsPlayerAlive(iPlayer))
		{
			continue;
		}
		
		switch (GetClientTeam(iPlayer))
		{
			case CS_TEAM_NC:
			{
				PrintHintText(iPlayer, "Mana: %0.2f|%0.2f\nRegeneration Rate: %0.1f", g_flPlayerMana[iPlayer], g_flMaxMana, g_flManaRegenAmount);
			}
			
			case CS_TEAM_SURVIVOR:
			{
				
			}
		}
	}
}

public Action Timer_MakeNCInvisibleAgain(Handle hTimer, int client)
{
	if (IsClientInGame(client))
	{
		g_bDontShowPlayer[client] = true;
	}
}

public Action Timer_CheckGameState(Handle hTimer)
{
	if (g_bRunning)
	{
		int iPlayersCT[MAXPLAYERS];
		int iPlayersT[MAXPLAYERS];
		
		int iCountCT = GetPlayers(iPlayersCT, GP_Flag_None, GP_Team_Second);
		int iCountT = GetPlayers(iPlayersT, GP_Flag_None, GP_Team_First);
		
		if (iCountT + iCountCT < g_iMinPlayers)
		{
			g_bRunning = false;
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Stopped the game: not enough players players", g_szNightcrawlerTeamName);
			return Plugin_Continue;
		}
		
		if (iCountT <= 0 || iCountCT <= 0)
		{
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Restarting the round as there are no players in the %s team.", g_szNightcrawlerTeamName);
			CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
		}
		
		return Plugin_Continue;
	}
	
	int iCount = GetPlayers(_, GP_Flag_None, GP_Team_First | GP_Team_Second);
	
	if (iCount >= g_iMinPlayers)
	{
		//ChooseNCPlayers();
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "--- Starting ---", g_szNightcrawlerTeamName);
		CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
		g_bRunning = true;
	}
	
	else PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Waiting for at least %d players to join to start the game.", g_iMinPlayers);
	
	return Plugin_Continue;
}

// --------------------------------------------------------------------------
//								Other Funcs
// --------------------------------------------------------------------------
void ChooseNCPlayers()
{
	int iPlayers[MAXPLAYERS];
	int iCount = GetPlayers(iPlayers, _, GP_Team_First | GP_Team_Second);
	
	int iNCCount = RoundFloat(float(iCount) / g_flNCRatio);
	
	int iChosenPlayersCount;
	int bChosenPlayers[MAXPLAYERS];
	
	int iPlayer;
	
	bool bFillRandom = false;
	
	if (g_iChooseNCPlayersMode == MODE_KILL)
	{
		for (int i; i < iCount; i++)
		{
			iPlayer = iPlayers[GetRandomInt(1, iCount - 1)];
			
			// Survivor Killed NC or NC survived
			if (g_bKilledNC[iPlayer] || (IsPlayerAlive(iPlayer) && GetClientTeam(iPlayer) == CS_TEAM_NC))
			{
				if (iChosenPlayersCount < iNCCount)
				{
					bChosenPlayers[iPlayer] = true;
					iChosenPlayersCount++;
				}
				
				else break;
			}
		}
		
		if (iChosenPlayersCount < iNCCount)
		{
			bFillRandom = true;
		}
	}
	
	// Random
	if (g_iChooseNCPlayersMode == MODE_RANDOM || bFillRandom)
	{
		int iMaxTries = 1000;
		int iTries;
		while (iChosenPlayersCount < iNCCount)
		{
			iTries++;
			
			iPlayer = iPlayers[GetRandomInt(1, iCount - 1)];
			
			if (!bChosenPlayers[iPlayer])
			{
				bChosenPlayers[iPlayer] = true;
				iChosenPlayersCount++;
			}
			
			if (iTries >= iMaxTries)
			{
				break;
			}
		}
	}
	
	else
	{
		LogToFile(PLUGIN_LOG_FILE, "g_iChooseNCPlayersMode value fail %d", g_iChooseNCPlayersMode);
	}
	
	for (int i; i < iCount; i++)
	{
		iPlayer = iPlayers[i];
		
		if (bChosenPlayers[iPlayer] && GetClientTeam(iPlayer) != CS_TEAM_NC)
		{
			CS_SwitchTeam(iPlayer, CS_TEAM_NC);
			//	g_bDontShowPlayer[client] = true;
		}
		
		else if (!bChosenPlayers[iPlayer] && GetClientTeam(iPlayer) != CS_TEAM_SURVIVOR)
		{
			CS_SwitchTeam(iPlayer, CS_TEAM_SURVIVOR);
			//	g_bShowPlayer[client] = true;
		}
		
		else PluginLog("LOL? Client : %d", iPlayer);
	}
	
	PluginLog("Players Count: %d - NC Expected Count %d - Chosen NC Count %d", iCount, iNCCount, iChosenPlayersCount);
}

void PrecacheFiles()
{
	PrecacheModel(MODEL_BEAM);
	//PrecacheModel(g_szNightcrawlerPlayerModels);
	
	/*
	for (int i; i < sizeof g_szNightcrawlerPlayerModel; i++)
	{
		if (g_szNightcrawlerPlayerModel[i][0])
		{
			if (!FileExists(g_szSurvivorPlayerModel[i]))
			{
				PluginLog("File not exits %s", g_szNightcrawlerPlayerModel[i]);
			}
			
			PrecacheModel(g_szNightcrawlerPlayerModel[i]);
		}
	}
	
	for (int i; i < sizeof g_szSurvivorPlayerModel; i++)
	{
		if (g_szSurvivorPlayerModel[i][0])
		{
			if (!FileExists(g_szSurvivorPlayerModel[i]))
			{
				PluginLog("File not exits %s", g_szSurvivorPlayerModel[i]);
			}
			
			PrecacheModel(g_szSurvivorPlayerModel[i]);
		}
	}
	
	for (int i; i < sizeof g_szNightcrawlerPlayerModelFiles; i++)
	{
		if (g_szNightcrawlerPlayerModelFiles[i][0])
		{
			if (!FileExists(g_szNightcrawlerPlayerModelFiles[i]))
			{
				PluginLog("File not exits %s", g_szNightcrawlerPlayerModelFiles[i]);
			}
			
			AddFileToDownloadsTable(g_szNightcrawlerPlayerModelFiles[i]);
		}
	}
	
	for (int i; i < sizeof g_szSurvivorPlayerModelFiles; i++)
	{
		if (g_szSurvivorPlayerModelFiles[i][0])
		{
			if (!FileExists(g_szSurvivorPlayerModelFiles[i]))
			{
				PluginLog("File not exits %s", g_szSurvivorPlayerModelFiles[i]);
			}
			AddFileToDownloadsTable(g_szSurvivorPlayerModelFiles[i]);
		}
	}
	*/
}

int CreateFog()
{
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "env_fog_controller")) > -1)
	{
		RemoveEdict(iEnt);
		iEnt += 1;
		PrintToServer("Removed Fog ent %d", iEnt);
	}
	
	iEnt = CreateEntityByName("env_fog_controller");
	if (iEnt > -1)
	{
		/*
		DispatchKeyValue(iEnt, "fogenable", "true");
		DispatchKeyValue(iEnt, "fogstart", "150.0");
		DispatchKeyValue(iEnt, "fogend", "1000.0");
		DispatchKeyValue(iEnt, "fogmaxdensity", "0.5");
		DispatchKeyValue(iEnt, "farz", "1150.0");
		DispatchKeyValue(iEnt, "fogcolor", "204 204 255");
		DispatchKeyValue(iEnt, "fogblend", "false");
		//DispatchKeyValue(iEnt, "fogstart", "150.0");
		DispatchSpawn(iEnt);
		*/
		
		DispatchKeyValue(iEnt, "targetname", "MyFog");
		DispatchKeyValue(iEnt, "fogenable", "1");
		DispatchKeyValue(iEnt, "spawnflags", "1");
		DispatchKeyValue(iEnt, "fogblend", "0");
		DispatchKeyValue(iEnt, "fogcolor", "150 150 255");
		DispatchKeyValue(iEnt, "fogcolor2", "255 0 0");
		DispatchKeyValueFloat(iEnt, "fogstart", 175.0);
		DispatchKeyValueFloat(iEnt, "fogend", 1250.0);
		//		DispatchKeyValueFloat(iEnt, "farz", 400.0);
		DispatchKeyValueFloat(iEnt, "fogmaxdensity", 1.0);
		DispatchSpawn(iEnt);
		
		AcceptEntityInput(iEnt, "TurnOn");
	}
	
	return iEnt;
}

bool TeleportClient(client)
{
	float vEyePosition[3];
	float vEyeAngles[3];
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	
	float vVector1[3]; //, vVector2[3], vVector3[3];
	GetAngleVectors(vEyeAngles, vVector1, NULL_VECTOR, NULL_VECTOR);
	
	float vOtherPosition[3];
	NormalizeVector(vVector1, vVector1);
	
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilter_Callback, client);
	if (!TR_DidHit(hTr))
	{
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Please aim somewhere else to teleport");
		delete hTr;
		return false;
	}
	
	TR_GetEndPosition(vOtherPosition, hTr);
	if (TR_PointOutsideWorld(vOtherPosition))
	{
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Please aim somewhere INSIDE THE MAP to teleport");
		delete hTr;
		return false;
	}
	
	delete hTr;
	ScaleVector(vVector1, 32.0);
	
	// Move the player model back based on mins/maxes;
	// Subtract because in the opposite direction;
	SubtractVectors(vOtherPosition, vVector1, vOtherPosition);
	//CreateLaser(vEyePosition, vOtherPosition);
	
	TeleportEntity(client, vOtherPosition, NULL_VECTOR, Float: { 0.0, 0.0, 0.0 } );
	UnStuckEntity(client);
	
	return true;
}

#define START_DISTANCE  32   // --| The first search distance for finding a free location in the map.
#define MAX_ATTEMPTS    128  // --| How many times to search in an area for a free

enum
{
	x = 0, y, z, Coord_e
};

bool UnStuckEntity(int client, int i_StartDistance = START_DISTANCE, int i_MaxAttempts = MAX_ATTEMPTS)
{
	int iMaxTries = 30;
	int iTries;
	
	static float vf_OriginalOrigin[Coord_e];
	static float vf_NewOrigin[Coord_e];
	static int i_Attempts, i_Distance;
	static float vEndPosition[3];
	static float vMins[Coord_e];
	static float vMaxs[Coord_e];
	
	GetClientAbsOrigin(client, vf_OriginalOrigin);
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	
	while (CheckIfClientIsStuck(client))
	{
		if (iTries++ >= iMaxTries)
		{
			break;
		}
		
		i_Distance = i_StartDistance;
		
		while (i_Distance < 1000)
		{
			i_Attempts = i_MaxAttempts;
			
			while (i_Attempts--)
			{
				vf_NewOrigin[x] = GetRandomFloat(vf_OriginalOrigin[x] - i_Distance, vf_OriginalOrigin[x] + i_Distance);
				vf_NewOrigin[y] = GetRandomFloat(vf_OriginalOrigin[y] - i_Distance, vf_OriginalOrigin[y] + i_Distance);
				vf_NewOrigin[z] = GetRandomFloat(vf_OriginalOrigin[z] - i_Distance, vf_OriginalOrigin[z] + i_Distance);
				
				//engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, hull, id, 0 );
				TR_TraceHullFilter(vf_NewOrigin, vf_NewOrigin, vMins, vMaxs, MASK_ALL, TraceFilter_Callback, client);
				
				// --| Free space found.
				TR_GetEndPosition(vEndPosition);
				if (!TR_PointOutsideWorld(vEndPosition) && TR_GetFraction() == 1.0)
				{
					// --| Set the new origin .
					TeleportEntity(client, vEndPosition, NULL_VECTOR, NULL_VECTOR);
					return true;
				}
			}
			
			i_Distance += i_StartDistance;
		}
	}
	
	// --| Could not be found.
	return false;
}

bool CheckIfClientIsStuck(int client)
{
	static float fOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
	
	static float fMins[3];
	static float fMaxs[3];
	
	GetClientMins(client, fMins);
	GetClientMaxs(client, fMaxs);
	
	TR_TraceHullFilter(fOrigin, fOrigin, fMins, fMaxs, MASK_ALL, TraceFilter_Callback, client);
	
	//engfunc(EngFunc_TraceHull, Origin, Origin, IGNORE_MONSTERS,  : (hull = HULL_HUMAN), 0, 0)
	
	if (TR_DidHit())
	{
		return true;
	}
	
	return false;
}

void CheckLastSurvivor()
{
	int iCount;
	int iLastId;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_SURVIVOR)
		{
			iCount++;
			iLastId = client;
		}
	}
	
	PrintToServer("Last Survivor Count: %d", iCount);
	if (iCount == 1)
	{
		GiveLaser(iLastId, true);
	}
}

void GivePlayerShopItem(int param1, int iItemIndex, bool bFree = false, int iAdminIndex)
{
	switch (iItemIndex)
	{
		
	}
}

void GiveLasers(int iHumans[MAXPLAYERS], int iCount)
{
	DeleteLaserEntities();
	SetArrayValue(g_bLaser, sizeof g_bLaser, false, 0);
	
	g_iLaserCount = RoundFloat(float(iCount) / g_flLaserRatio);
	
	int iChosenCount;
	if (!g_iLaserCount && iCount)
	{
		g_iLaserCount = 1;
	}
	
	int client;
	while (iChosenCount < g_iLaserCount)
	{
		client = iHumans[GetRandomInt(0, iCount - 1)];
		
		if (g_bLaser[client])
		{
			continue;
		}
		
		GiveLaser(client, true);
		iChosenCount++;
	}
	
	PluginLog("iLaserCount: %d - iChosenCount: %d", g_iLaserCount, iChosenCount);
}

void DeleteLaserEntities()
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (g_iLaserEnt[client] && IsValidEntity(g_iLaserEnt[client]))
		{
			RemoveEdict(g_iLaserEnt[client]);
			g_iLaserEnt[client] = 0;
			g_bLaser[client] = false;
		}
	}
}

void DoClimb(int client)
{
	static float vOrigin[3]; GetClientAbsOrigin(client, vOrigin);
	static float vEyeAngles[3]; static float vEyePosition[3];
	
	//TeleportEntity(iLaserEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	
	static float vEndPosition[3];
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilter_Callback, client);
	
	if (TR_GetFraction(hTr) == 1.0)
	{
		delete hTr;
		PrintToServer("Fraction == 1.0");
		return;
	}
	
	TR_GetEndPosition(vEndPosition, hTr);
	delete hTr;
	
	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		return;
	}
	
	//CreateLaser(vEyePosition, vEndPosition);
	if (GetVectorDistance(vEyePosition, vEndPosition) >= 45.0)
	{
		return;
	}
	
	static float vVelocity[3];
	GetAngleVectors(vEyeAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(vVelocity, vVelocity);
	ScaleVector(vVelocity, 250.0);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

void MoveLaserEnt(int client)
{
	//Handle hPf = CreateProfiler();
	//StartProfiling(hPf);
	
	static int iLaserEnt;
	iLaserEnt = g_iLaserEnt[client];
	
	if (!iLaserEnt)
	{
		return;
	}
	
	if (!IsValidEntity(iLaserEnt))
	{
		g_iLaserEnt[client] = 0;
		return;
	}
	
	static float vOrigin[3]; GetClientAbsOrigin(client, vOrigin);
	static float vEyeAngles[3]; GetClientEyeAngles(client, vEyeAngles);
	static float vEyePosition[3]; GetClientEyePosition(client, vEyePosition);
	
	TeleportEntity(iLaserEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	static float vEndPosition[3];
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilter_Callback, client);
	
	if (!TR_DidHit(hTr))
	{
		delete hTr;
		return;
	}
	
	static int iHit;
	iHit = TR_GetEntityIndex(hTr);
	TR_GetEndPosition(vEndPosition, hTr);
	
	delete hTr;
	
	if (IsValidPlayer(iHit, true) && GetClientTeam(iHit) == CS_TEAM_NC)
	{
		SetEntityRenderColor(iLaserEnt, 255, 0, 0, 255);
	}
	
	else SetEntityRenderColor(iLaserEnt, 0, 255, 0, 255);
	
	SetEntPropVector(iLaserEnt, Prop_Data, "m_vecEndPos", vEndPosition);
	
	//StopProfiling(hPf);
	//PluginLog("Took %f seconds", GetProfilerTime(hPf));
	
	//delete hPf;
}

void GiveLaser(int client, bool bStatus)
{
	switch (bStatus)
	{
		case true:
		{
			g_bLaser[client] = true;
			g_iLaserEnt[client] = MakeLaserEntity();
		}
		
		case false:
		{
			g_bLaser[client] = false;
			
			if (IsValidEntity(g_iLaserEnt[client]))
			{
				RemoveEdict(g_iLaserEnt[client]);
			}
			
			g_iLaserEnt[client] = 0;
		}
	}
}

int MakeLaserEntity()
{
	int iEnt;
	
	#define LASER_COLOR_CT	"255 255 255"
	iEnt = CreateEntityByName("env_beam");
	if (IsValidEntity(iEnt))
	{
		new String:color[16] = LASER_COLOR_CT;
		
		//TeleportEntity(iEnt, start, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(iEnt, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
		//SetEntPropVector(iEnt, Prop_Data, "m_vecEndPos", end);
		DispatchKeyValue(iEnt, "targetname", "bla");
		DispatchKeyValue(iEnt, "rendercolor", color);
		DispatchKeyValue(iEnt, "renderamt", "255");
		DispatchKeyValue(iEnt, "decalname", "Bigshot");
		DispatchKeyValue(iEnt, "life", "0");
		DispatchKeyValue(iEnt, "TouchType", "0");
		DispatchSpawn(iEnt);
		SetEntPropFloat(iEnt, Prop_Data, "m_fWidth", 1.0);
		SetEntPropFloat(iEnt, Prop_Data, "m_fEndWidth", 1.0);
		ActivateEntity(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		
		PrintToChatAll("Made laser");
		//CreateTimer(3.0, Timer_DeleteLaser, ent, TIMER_FLAG_NO_MAPCHANGE);
		
		return iEnt;
	}
	
	return 0;
}

void ResetRoundVars(int client, int iTeam)
{
	switch (iTeam)
	{
		case CS_TEAM_NC:
		{
			g_flPlayerMana[client] = g_flMaxMana;
			g_bDontShowPlayer[client] = true;
		}
		case CS_TEAM_SURVIVOR:
		{
			g_bDontShowPlayer[client] = false;
		}
	}
	
	g_bLaser[client] = false;
	g_bKilledNC[client] = false;
	
	if (g_iLaserEnt[client] && IsValidEntity(g_iLaserEnt[client]))
	{
		RemoveEdict(g_iLaserEnt[client]);
	}
	
	g_iLaserEnt[client] = 0;
}

bool IsValidPlayer(int client, bool bAlive = false)
{
	if (!(0 < client <= MaxClients))
	{
		return false;
	}
	
	if (!IsClientInGame(client))
	{
		return false;
	}
	
	if (bAlive)
	{
		if (!IsPlayerAlive(client))
		{
			return false;
		}
	}
	
	return true;
}

// --------------------------------------------------------------------------
//								Custom Funcs
// --------------------------------------------------------------------------
void PluginLog(char[] szMessage, any...)
{
	char szBuffer[1024];
	VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
	
	LogToFileEx(PLUGIN_LOG_FILE, szBuffer);
}

stock void PrintToChat_Custom(int client, const char[] szPrefix = "", char[] szMsg, any...)
{
	char szBuffer[192];
	VFormat(szBuffer, sizeof(szBuffer), szMsg, 4);
	
	PrintToServer(szPrefix);
	
	if (client > 0)
	{
		CPrintToChat(client, "%s \x01%s", szPrefix, szBuffer);
	}
	
	else CPrintToChatAll("%s \x01%s", szPrefix, szBuffer);
} 

stock void SetArrayValue(any[] array, int size, any value, int start = 0)
{
	for(int i = start; i < size; i++)
	{
		array[i] = value;
	}
}