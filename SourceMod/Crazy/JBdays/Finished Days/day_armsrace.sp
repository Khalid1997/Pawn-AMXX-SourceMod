/*
 * MyJailbreak - Arms Race Event Day Plugin.
 * by: shanapu
 * https://github.com/shanapu/MyJailbreak/
 * 
 * Copyright (C) 2016-2017 Thomas Schmidt (shanapu)
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <emitsoundany>
#include <multicolors>
#include <autoexecconfig>
#include <mystocks>
#include <myjailbreak_e>
#include <daysapi>

// Optional Plugins
#undef REQUIRE_PLUGIN
#include <hosties>
#include <lastrequest>
#include <smartjaildoors>
#define REQUIRE_PLUGIN

// Compiler Options
#pragma semicolon 1
#pragma newdecls required
#include <spawnpoints>

// Booleans
bool g_bIsArmsRace = false;

// Plugin bools
bool gp_bHosties;
bool gp_bSmartJailDoors;

char g_sAdminFlag[25];

// Console Variables
ConVar gc_bSpawnCell;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;
ConVar gc_bSounds;
ConVar gc_sSoundStartPath;
ConVar gc_iTruceTime;
ConVar gc_sCustomCommandSet;
ConVar gc_bKillLoser;
ConVar gc_sAdminFlag;
ConVar gc_bSpawnRandom;

int g_iMaxLevel;

//ConVar gc_bTeleportSpawn;

// Extern Convars

// Integers
int g_iTruceTime;
int g_iCollision_Offset;

int g_iLevel[MAXPLAYERS + 1];

// Floats
float g_fPos[3];

// Handles
Handle g_hTimerTruce;
Handle g_aWeapons;

// Strings
char g_sSoundStartPath[256];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo = 
{
	name = "MyJailbreak - Arms Race", 
	author = "shanapu", 
	description = "Event Day for Jailbreak Server", 
	version = MYJB_VERSION, 
	url = MYJB_URL_LINK
};

// Start
public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.ArmsRace.phrases");
	
	// Client Commands
	RegConsoleCmd("sm_setarmsrace", Command_Setarmsrace, "Allows the Admin or Warden to set ArmsRace");
	
	// AutoExecConfig
	AutoExecConfig_SetFile("ArmsRace", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_armsrace_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gc_sCustomCommandSet = AutoExecConfig_CreateConVar("sm_armsrace_cmds_set", "sar, setarms", "Set your custom chat command for set Event(!setarmsrace (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands))");
	gc_sAdminFlag = AutoExecConfig_CreateConVar("sm_armsrace_flag", "g", "Set flag for admin/vip to set this Event Day.");
	gc_bSpawnCell = AutoExecConfig_CreateConVar("sm_armsrace_spawn", "0", "0 - T teleport to CT spawn, 1 - cell doors auto open", _, true, 0.0, true, 1.0);
	gc_bSpawnRandom = AutoExecConfig_CreateConVar("sm_armsrace_randomspawn", "1", "0 - disabled, 1 - use random spawns on map (sm_armsrace_spawn 1)", _, true, 0.0, true, 1.0);
	
	//gc_bTeleportSpawn = AutoExecConfig_CreateConVar("sm_armsrace_teleport_spawn", "0", "0 - start event in current round from current player positions, 1 - teleport players to spawn when start event on current round(only when sm_*_begin_admin, sm_*_begin_warden, sm_*_begin_vote or sm_*_begin_daysvote is on '1')", _, true, 0.0, true, 1.0);
	
	//gc_iRoundTime = AutoExecConfig_CreateConVar("sm_armsrace_roundtime", "10", "Round time in minutes for a single armsrace round", _, true, 1.0);
	gc_iTruceTime = AutoExecConfig_CreateConVar("sm_armsrace_trucetime", "8", "Time in seconds players can't deal damage", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_armsrace_sounds_enable", "1", "0 - disabled, 1 - enable sounds", _, true, 0.0, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_armsrace_sounds_start", "music/MyJailbreak/start.mp3", "Path to the soundfile which should be played for a start.");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_armsrace_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_armsrace_overlays_start", "overlays/MyJailbreak/start", "Path to the start Overlay DONT TYPE .vmt or .vft");
	gc_bKillLoser = AutoExecConfig_CreateConVar("sm_armsrace_kill_loser", "0", "0 - disabled, 1 - Kill loserteam on event end / not for sm_armsrace_allow_lr '1'", _, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	// Hooks
	HookEvent("player_death", Event_PlayerDeath);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	HookConVarChange(gc_sAdminFlag, OnSettingChanged);
	
	// FindConVar
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sAdminFlag.GetString(g_sAdminFlag, sizeof(g_sAdminFlag));
	
	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	// Logs
	SetLogFile(g_sEventsLogFile, "Events", "MyJailbreak");
	
	SC_Initialize("Respawns", "sm_spawns", ADMFLAG_ROOT, "sm_addspawn", ADMFLAG_ROOT, "sm_removespawn", ADMFLAG_ROOT, "sm_showspawn", ADMFLAG_ROOT
	, "configs/spawnpoints", -1);
}

// ConVarChange for Strings
public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sOverlayStartPath)
	{
		strcopy(g_sOverlayStartPath, sizeof(g_sOverlayStartPath), newValue);
		if (gc_bOverlays.BoolValue)
		{
			PrecacheDecalAnyDownload(g_sOverlayStartPath);
		}
	}
	else if (convar == gc_sSoundStartPath)
	{
		strcopy(g_sSoundStartPath, sizeof(g_sSoundStartPath), newValue);
		if (gc_bSounds.BoolValue)
		{
			PrecacheSoundAnyDownload(g_sSoundStartPath);
		}
	}
	else if (convar == gc_sAdminFlag)
	{
		strcopy(g_sAdminFlag, sizeof(g_sAdminFlag), newValue);
	}
}

public void OnAllPluginsLoaded()
{
	gp_bHosties = LibraryExists("lastrequest");
	gp_bSmartJailDoors = LibraryExists("smartjaildoors");
	
	DaysAPI_AddDay("armsrace");
	DaysAPI_SetDayInfo("armsrace", DayInfo_DisplayName, "Arms Race");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "lastrequest"))
		gp_bHosties = false;
	
	if (StrEqual(name, "smartjaildoors"))
		gp_bSmartJailDoors = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "lastrequest"))
		gp_bHosties = true;
	
	if (StrEqual(name, "smartjaildoors"))
		gp_bSmartJailDoors = true;
}

// Initialize Plugin
public void OnConfigsExecuted()
{
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	GetWeapons();
	
	// Set custom Commands
	int iCount = 0;
	char sCommands[128], sCommandsL[12][32], sCommand[32];
	
	// Set
	gc_sCustomCommandSet.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ", "");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS) // if command not already exist
		{
			RegConsoleCmd(sCommand, Command_Setarmsrace, "Allows the Admin or Warden to set a armsrace");
		}
	}
}

public void OnPluginEnd()
{
	SC_SaveMapConfig();
	DaysAPI_RemoveDay("armsrace");
}

/******************************************************************************
                   COMMANDS
******************************************************************************/

// Admin & Warden set Event
public Action Command_Setarmsrace(int client, int args)
{
	if (CheckVipFlag(client, g_sAdminFlag)) // Called by admin/VIP
	{
		DaysAPI_StartDay("armsrace");
		
		if (MyJailbreak_ActiveLogging())
		{
			LogToFileEx(g_sEventsLogFile, "Event Free for all was started by admin %L", client);
		}
	}
	
	return Plugin_Handled;
}

/******************************************************************************
                   EVENTS
******************************************************************************/
// Round End
public void Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	if (g_bIsArmsRace)
	{
		if (gc_bKillLoser.BoolValue)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i, true, true))
				{
					SetEntData(i, g_iCollision_Offset, 0, 4, true);
					
					if (g_iLevel[i] != g_iMaxLevel)
					{
						ForcePlayerSuicide(i);
					}
				}
			}
		}
	}
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	SC_LoadMapConfig();
	SC_SetSpawnSprite();
	
	g_bIsArmsRace = false;
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	if (gc_bOverlays.BoolValue)
	{
		PrecacheDecalAnyDownload(g_sOverlayStartPath);
	}
	
	if (gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundStartPath);
	}
}

// Map End
public void OnMapEnd()
{
	SC_SaveMapConfig();
	
	g_bIsArmsRace = false;
	delete g_hTimerTruce;
}

public void DaysAPI_OnDayStart(char[] szDay)
{
	if (!StrEqual(szDay, "armsrace"))
	{
		return;
	}
	
	StartEventRound();
}

public void DaysAPI_OnDayEnd_Pre(char[] szDay, any data)
{
	if (StrEqual(szDay, "armsrace"))
	{	
		int Levels[MAXPLAYERS][2];
		
		int iAdd;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				continue;
			}
			
			Levels[iAdd][0] = g_iLevel[i];
			Levels[iAdd][1] = i;
			iAdd++;
		}
		
		SortCustom2D(Levels, iAdd, SortFunc);
		
		int iHighestLevel = Levels[0][0];
		int iSecondHighestLevel = -1;
		int iThirdHighestLevel = -1;
		
		for (int i; i < iAdd; i++)
		{
			if (iSecondHighestLevel < Levels[i][0] < iHighestLevel)
			{
				iSecondHighestLevel = Levels[i][0];
			}
			
			else if (iThirdHighestLevel < Levels[i][0] < iSecondHighestLevel)
			{
				iThirdHighestLevel = Levels[i][0];
			}
		}
		
		int iArrayFirstPlace[1]; iArrayFirstPlace[0] = Levels[0][1];
		int iArraySecondPlace[MAXPLAYERS], iSCount;
		int iArrayThirdPlace[MAXPLAYERS], iTCount;
		
		for (int i; i < iAdd; i++)
		{
			if(iSecondHighestLevel > 0 && Levels[i][0] == iSecondHighestLevel)
			{
				iArraySecondPlace[iSCount++] = Levels[i][1];
			}
			
			else if(iThirdHighestLevel > 0 && Levels[i][0] == iThirdHighestLevel)
			{
				iArrayThirdPlace[iTCount++] = Levels[i][1];
			}
		}
		
		DaysAPI_ResetDayWinners();
		
		if(iHighestLevel > 0)
		{
			DaysAPI_SetDayWinners("firstplace", iArrayFirstPlace, 1);
		}
		
		if(iSecondHighestLevel > 0)
		{
			DaysAPI_SetDayWinners("secondplace", iArraySecondPlace, iSCount);
		}
		
		if(iThirdHighestLevel > 0)
		{
			DaysAPI_SetDayWinners("thirdplace", iArrayThirdPlace, iTCount);
		}
	}
}

public void DaysAPI_OnDayEnd(char[] szIntName, any data)
{
	if(!StrEqual(szIntName, "armsrace"))
	{
		return;
	}
	
	ResetEventDay();
}

public int SortFunc(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if(elem1[0] > elem2[0])
	{
		return -1;
	}
	
	if(elem1[0] < elem2[0])
	{
		return 1;
	}
	
	return 0;
}

void ResetEventDay()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, true, true))
		{
			SetEntData(i, g_iCollision_Offset, 0, 4, true);
			
			StripAllPlayerWeapons(i);
			
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				FakeClientCommand(i, "sm_weapons");
			}
			
			GivePlayerItem(i, "weapon_knife");
			
			SetEntityMoveType(i, MOVETYPE_WALK);
			
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		}
	}
	
	delete g_hTimerTruce;
	MyJailbreak_FogOff();
	g_bIsArmsRace = false;
	
	if (gp_bHosties)
	{
		SetCvar("sm_hosties_lr", 1);
	}
	
	if (gc_bSpawnRandom.BoolValue)
	{
		SetCvar("mp_randomspawn", 0);
		SetCvar("mp_randomspawn_los", 0);
	}
	
	SetCvar("mp_friendlyfire", 0);
	SetCvar("sm_menu_enable", 1);
	SetCvar("mp_death_drop_gun", 1);
	SetCvar("mp_teammates_are_enemies", 0);
	
	CPrintToChatAll("%t %t", "armsrace_tag", "armsrace_end");
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

// Prepare Event for next round
void StartEventRound()
{
	g_bIsArmsRace = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, true, false))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}
	
	CreateTimer(3.0, Timer_PrepareEvent);
	
	CPrintToChatAll("%t %t", "armsrace_tag", "armsrace_now");
	PrintCenterTextAll("%t", "armsrace_now_nc");
}

public Action Timer_PrepareEvent(Handle timer)
{
	if (!g_bIsArmsRace)
		return Plugin_Handled;
	
	PrepareDay();
	
	return Plugin_Handled;
}


void PrepareDay()
{
	if (gp_bSmartJailDoors)
	{
		SJD_OpenDoors();
	}
	
	if (/*(thisround && gc_bTeleportSpawn.BoolValue) ||*/!gc_bSpawnRandom.BoolValue && !gc_bSpawnCell.BoolValue || !gp_bSmartJailDoors || (gc_bSpawnCell.BoolValue && (SJD_IsCurrentMapConfigured() != true))) // spawn Terrors to CT Spawn 
	{
		int RandomCT = 0;
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
		{
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				CS_RespawnPlayer(i);
				RandomCT = i;
				break;
			}
		}
		
		if (RandomCT)
		{
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
			{
				GetClientAbsOrigin(RandomCT, g_fPos);
				
				g_fPos[2] = g_fPos[2] + 5;
				
				TeleportEntity(i, g_fPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	
	char buffer[32];
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		SetEntData(i, g_iCollision_Offset, 2, 4, true);
		
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		//CreateInfoPanel(i);
		
		g_iLevel[i] = 0;
		
		StripAllPlayerWeapons(i);
		
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			GivePlayerItem(i, "weapon_knife");
		}
		else
		{
			GivePlayerItem(i, "weapon_knife_t");
		}
		
		GetArrayString(g_aWeapons, g_iLevel[i], buffer, sizeof(buffer));
		GivePlayerItem(i, buffer);
	}
	
	MyJailbreak_FogOn();
	
	if (gp_bHosties)
	{
		SetCvar("sm_hosties_lr", 0);
	}
	
	//GameRules_SetProp("m_iRoundTime", gc_iRoundTime.IntValue * 60, 4, 0, true);
	
	SetCvar("mp_death_drop_gun", 0);
	SetCvar("mp_teammates_are_enemies", 1);
	SetCvar("mp_friendlyfire", 1);
	
	g_hTimerTruce = CreateTimer(1.0, Timer_StartEvent, _, TIMER_REPEAT);
}

/******************************************************************************
                   MENUS
******************************************************************************/

stock void CreateInfoPanel(int client)
{
	// Create info Panel
	char info[255];
	
	Panel InfoPanel = new Panel();
	
	Format(info, sizeof(info), "%T", "armsrace_info_title", client);
	InfoPanel.SetTitle(info);
	
	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "armsrace_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "armsrace_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "armsrace_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "armsrace_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "armsrace_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "armsrace_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "armsrace_info_line7", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	
	InfoPanel.DrawItem(info);
	
	InfoPanel.Send(client, Handler_NullCancel, 20);
}

/******************************************************************************
                   TIMER
******************************************************************************/

// Start Timer
public Action Timer_StartEvent(Handle timer)
{
	if (g_iTruceTime > 0)
	{
		g_iTruceTime--;
		
		if (g_iTruceTime == gc_iTruceTime.IntValue - 3)
		{
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
		}
		
		PrintCenterTextAll("%t", "armsrace_damage_nc", g_iTruceTime);
		
		return Plugin_Continue;
	}
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		
		if (gc_bOverlays.BoolValue)
		{
			ShowOverlay(i, g_sOverlayStartPath, 2.0);
		}
	}
	
	if (gc_bSounds.BoolValue)
	{
		EmitSoundToAllAny(g_sSoundStartPath);
	}
	
	MyJailbreak_FogOff();
	
	g_hTimerTruce = null;
	
	PrintCenterTextAll("%t", "armsrace_start_nc");
	CPrintToChatAll("%t %t", "armsrace_tag", "armsrace_start");
	
	return Plugin_Stop;
}

void GetWeapons()
{
	char g_filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, g_filename, sizeof(g_filename), "configs/MyJailbreak/armsrace.ini");
	
	Handle file = OpenFile(g_filename, "rt");
	
	if (file == INVALID_HANDLE)
	{
		SetFailState("MyJailbreak Arms Race - Can't read %s correctly! (ImportFromFile)", g_filename);
	}
	
	g_aWeapons = CreateArray(32);
	
	while (!IsEndOfFile(file))
	{
		char line[128];
		
		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}
		
		TrimString(line);
		
		if (StrContains(line, "/", false) != -1)
		{
			continue;
		}
		
		if (!line[0])
		{
			continue;
		}
		
		PushArrayString(g_aWeapons, line);
	}
	
	CloseHandle(file);
	
	g_iMaxLevel = GetArraySize(g_aWeapons);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsArmsRace)
		return;
	
	int victim = GetClientOfUserId(event.GetInt("userid")); // Get the dead clients id
	int attacker = GetClientOfUserId(event.GetInt("attacker")); // Get the attacker clients id
	
	if (IsValidClient(attacker, true, false) && (attacker != victim) && IsValidClient(victim, true, true))
	{
		g_iLevel[attacker] += 1;
		
		char sWeaponUsed[50];
		event.GetString("weapon", sWeaponUsed, sizeof(sWeaponUsed));
		
		if (StrContains(sWeaponUsed, "knife", false) != -1)
		{
			g_iLevel[victim] -= 1;
			if (g_iLevel[victim] <= -1)
			{
				g_iLevel[victim] = 0;
			}
			
			CPrintToChat(victim, "%t %t", "armsrace_tag", "armsrace_downgraded");
			CPrintToChat(attacker, "%t %t", "armsrace_tag", "armsrace_downgrade", victim);
		}
		
		if (g_iLevel[attacker] == g_iMaxLevel)
		{
			CPrintToChat(attacker, "%t %t", "armsrace_tag", "armsrace_youwon");
			CPrintToChatAll("%t %t", "armsrace_tag", "armsrace_winner", attacker);
			
			DaysAPI_EndDay("armsrace");
			
			CS_TerminateRound(5.0, CSRoundEnd_Draw);
			return;
		}
		
		StripAllPlayerWeapons(attacker);
			
		char buffer[32];
		GetArrayString(g_aWeapons, g_iLevel[attacker], buffer, sizeof(buffer));
		GivePlayerItem(attacker, buffer);
			
		if (g_iLevel[attacker] != g_iMaxLevel)
		{
			if (GetClientTeam(attacker) == CS_TEAM_CT)
			{
				GivePlayerItem(attacker, "weapon_knife");
			}
			else
			{
				GivePlayerItem(attacker, "weapon_knife_t");
			}
		}
			
		ReplaceString(buffer, sizeof(buffer), "weapon_", "", false);
		StringToUpper(buffer);
		CPrintToChat(attacker, "%t %t", "armsrace_tag", "armsrace_levelup", buffer);
	}
	
	CreateTimer(2.0, Timer_Respawn, GetClientUserId(victim));
}

public Action Timer_Respawn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	CS_RespawnPlayer(client);
	
	float flSpawnPoint[3], flAngles[3];
	if(SC_GetNextSpawnPoint(flSpawnPoint, flAngles) == SC_NoError)
	{
		TeleportEntity(client, flSpawnPoint, flAngles, NULL_VECTOR);
	}
	
	StripAllPlayerWeapons(client);
	
	char buffer[32];
	GetArrayString(g_aWeapons, g_iLevel[client], buffer, sizeof(buffer));
	GivePlayerItem(client, buffer);
	
	if (g_iLevel[client] != g_iMaxLevel)
	{
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			GivePlayerItem(client, "weapon_knife");
		}
		else
		{
			GivePlayerItem(client, "weapon_knife_t");
		}
	}
	
	return Plugin_Handled;
}

// Set Client Hook
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

// Knife only
public Action OnWeaponCanUse(int client, int weapon)
{
	if (!g_bIsArmsRace)
	{
		return Plugin_Continue;
	}
	
	if (g_iLevel[client] == g_iMaxLevel)
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	char buffer[32];
	GetArrayString(g_aWeapons, g_iLevel[client], buffer, sizeof(buffer));
	
	if ((StrEqual(sWeapon, buffer) || StrEqual(sWeapon, "weapon_knife") || StrEqual(sWeapon, "weapon_knife_t")) && IsValidClient(client, true, false))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

//Deny weapon drops
public Action OnWeaponDrop(int client, int weapon)
{
	if (!g_bIsArmsRace)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if (!g_bIsArmsRace)
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iLevel[i] >= g_iMaxLevel)
		{
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}
