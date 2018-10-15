/*
 * MyJailbreak - No Scope Event Day Plugin.
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

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Booleans
bool g_bIsLateLoad = false;
bool g_bIsNoScope = false;
bool g_bLadder[MAXPLAYERS + 1] = false;

// Console Variables
ConVar gc_bGrav;
ConVar gc_fGravValue;
ConVar gc_bSpawnCell;
ConVar gc_iWeapon;
ConVar gc_bRandom;
ConVar gc_fBeaconTime;
ConVar gc_iTruceTime;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;
ConVar gc_bSounds;
ConVar gc_sSoundStartPath;


// Integers
int m_flNextSecondaryAttack;
int g_iCollision_Offset;
int g_iTruceTime;

// Handles
Handle g_hTimerTruce;
Handle g_hTimerBeacon;

// Floats
float g_fPos[3];

// Strings
char g_sSoundStartPath[256];
char g_sWeapon[32];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo =  {
	name = "MyJailbreak - NoScope", 
	author = "shanapu", 
	description = "Event Day for Jailbreak Server", 
	version = MYJB_VERSION, 
	url = MYJB_URL_LINK
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bIsLateLoad = late;
	
	return APLRes_Success;
}

// Start
public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.NoScope.phrases");
	
	// AutoExecConfig
	AutoExecConfig_SetFile("NoScope", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_noscope_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gc_bSpawnCell = AutoExecConfig_CreateConVar("sm_noscope_spawn", "0", "0 - T teleport to CT spawn, 1 - cell doors auto open", _, true, 0.0, true, 1.0);
	
	gc_iWeapon = AutoExecConfig_CreateConVar("sm_noscope_weapon", "1", "1 - ssg08 / 2 - awp / 3 - scar20 / 4 - g3sg1", _, true, 1.0, true, 4.0);
	gc_bRandom = AutoExecConfig_CreateConVar("sm_noscope_random", "1", "get a random weapon (ssg08, awp, scar20, g3sg1) ignore: sm_noscope_weapon", _, true, 0.0, true, 1.0);
	gc_bGrav = AutoExecConfig_CreateConVar("sm_noscope_gravity", "1", "0 - disabled, 1 - enable low Gravity for noscope", _, true, 0.0, true, 1.0);
	gc_fGravValue = AutoExecConfig_CreateConVar("sm_noscope_gravity_value", "0.3", "Ratio for Gravity 1.0 earth 0.5 moon", _, true, 0.1, true, 1.0);
	gc_fBeaconTime = AutoExecConfig_CreateConVar("sm_noscope_beacon_time", "240", "Time in seconds until the beacon turned on (set to 0 to disable)", _, true, 0.0);
	gc_iTruceTime = AutoExecConfig_CreateConVar("sm_noscope_trucetime", "15", "Time in seconds players can't deal damage", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_noscope_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.1, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_noscope_sounds_start", "music/MyJailbreak/start.mp3", "Path to the soundfile which should be played for a start.");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_noscope_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_noscope_overlays_start", "overlays/MyJailbreak/start", "Path to the start Overlay DONT TYPE .vmt or .vft");

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	
	// Find
	m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	
	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	// Logs
	SetLogFile(g_sEventsLogFile, "Events", "MyJailbreak");
	
	// Late loading
	if (g_bIsLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
		
		g_bIsLateLoad = false;
	}
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
}

public void OnAllPluginsLoaded()
{
	DaysAPI_AddDay("noscope");
	DaysAPI_SetDayInfo("noscope", DayInfo_DisplayName, "No Scope");
}

// Initialize Plugin
public void OnConfigsExecuted()
{
	g_iTruceTime = gc_iTruceTime.IntValue;
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay("noscope");
}

/******************************************************************************
                   EVENTS
******************************************************************************/

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_bIsNoScope = false;
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	if (gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundStartPath); // Add sound to download and precache table
	}
	if (gc_bOverlays.BoolValue)
	{
		PrecacheDecalAnyDownload(g_sOverlayStartPath); // Add overlay to download and precache table
	}
}

public void DaysAPI_OnDayStart(char[] szInt)
{
	if (StrEqual(szInt, "noscope"))
	{
		StartEventRound();
	}
}

public void DaysAPI_OnDayEnd_Pre(char[] szInt)
{
	if (!StrEqual(szInt, "noscope"))
	{
		return;
	}
	
	int iWinners[MAXPLAYERS], iCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if(IsPlayerAlive(i))
		{
			iWinners[iCount++] = i;
		}
	}
	
	DaysAPI_ResetDayWinners();
	if (iCount == 1)
	{
		DaysAPI_SetDayWinners("winner", iWinners, iCount);
	}
}

public void DaysAPI_OnDayEnd(char[] szInt)
{
	if (StrEqual(szInt, "noscope"))
	{
		ResetEventDay();
	}
}

void ResetEventDay()
{	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		SetEntData(i, g_iCollision_Offset, 0, 4, true);
		SetEntityGravity(i, 1.0);
		
		StripAllPlayerWeapons(i);
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			FakeClientCommand(i, "sm_weapons");
		}
		
		GivePlayerItem(i, "weapon_knife");
		
		SetEntityMoveType(i, MOVETYPE_WALK);
		
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
	}
	
	delete g_hTimerBeacon;
	delete g_hTimerTruce;
	
	g_bIsNoScope = false;
	
	SetCvar("sv_infinite_ammo", 0);
	SetCvar("mp_teammates_are_enemies", 0);
	
	CPrintToChatAll("%t %t", "noscope_tag", "noscope_end");
}


// Map End
public void OnMapEnd()
{
	g_bIsNoScope = false;
	
	delete g_hTimerTruce;
	delete g_hTimerBeacon;
}

// Scout only
public Action OnWeaponCanUse(int client, int weapon)
{
	if (!g_bIsNoScope)
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if (!StrEqual(sWeapon, g_sWeapon) && IsValidClient(client, true, false))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// Set Client Hooks
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/


// Prepare Event
void StartEventRound()
{
	g_bIsNoScope = true;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
	}
	
	CreateTimer(3.0, Timer_PrepareEvent);
	
	CPrintToChatAll("%t %t", "noscope_tag", "noscope_now");
	PrintCenterTextAll("%t", "noscope_now_nc");
}

public Action Timer_PrepareEvent(Handle timer)
{
	if (!g_bIsNoScope)
		return Plugin_Handled;
	
	PrepareDay();
	
	return Plugin_Handled;
}

void PrepareDay()
{
	if (/*(thisround && gc_bTeleportSpawn.BoolValue) ||*/ !gc_bSpawnCell.BoolValue) // spawn Terrors to CT Spawn 
	{
		int RandomCT = 0;
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
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
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
			{
				GetClientAbsOrigin(RandomCT, g_fPos);
				
				g_fPos[2] = g_fPos[2] + 5;
				
				TeleportEntity(i, g_fPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	
	if (gc_iWeapon.IntValue == 1)
	{
		g_sWeapon = "weapon_ssg08";
	}
	else if (gc_iWeapon.IntValue == 2)
	{
		g_sWeapon = "weapon_awp";
	}
	else if (gc_iWeapon.IntValue == 3)
	{
		g_sWeapon = "weapon_scar20";
	}
	else if (gc_iWeapon.IntValue == 4)
	{
		g_sWeapon = "weapon_g3sg1";
	}
	
	if (gc_bRandom.BoolValue)
	{
		int randomnum = GetRandomInt(0, 3);
		
		if (randomnum == 0)
		{
			g_sWeapon = "weapon_ssg08";
		}
		else if (randomnum == 1)
		{
			g_sWeapon = "weapon_awp";
		}
		else if (randomnum == 2)
		{
			g_sWeapon = "weapon_scar20";
		}
		else if (randomnum == 3)
		{
			g_sWeapon = "weapon_g3sg1";
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntData(i, g_iCollision_Offset, 2, 4, true);
		
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
		
		//CreateInfoPanel(i);
		
		StripAllPlayerWeapons(i);
		
		GivePlayerItem(i, g_sWeapon);
		
		SDKHook(i, SDKHook_PreThink, OnPreThink);
		
		if (gc_bGrav.BoolValue)
		{
			SetEntityGravity(i, gc_fGravValue.FloatValue);
		}
	}
	
	if (gc_fBeaconTime.FloatValue > 0.0)
	{
		g_hTimerBeacon = CreateTimer(gc_fBeaconTime.FloatValue, Timer_BeaconOn, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	SetCvar("sv_infinite_ammo", 2);
	SetCvar("mp_teammates_are_enemies", 1);
	
	g_hTimerTruce = CreateTimer(1.0, Timer_StartEvent, _, TIMER_REPEAT);
}

// No Scope
void MakeNoScope(int weapon)
{
	if (!g_bIsNoScope)
	{
		return;
	}
	
	if (!IsValidEdict(weapon))
	{
		return;
	}
	
	char classname[MAX_NAME_LENGTH];
	if (GetEdictClassname(weapon, classname, sizeof(classname)) || StrEqual(classname[7], g_sWeapon))
	{
		SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 1.0);
	}
}

public Action OnPreThink(int client)
{
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	MakeNoScope(iWeapon);
	
	return Plugin_Continue;
}

/******************************************************************************
                   MENUS
******************************************************************************/

stock void CreateInfoPanel(int client)
{
	// Create info Panel
	char info[255];
	
	Panel InfoPanel = new Panel();
	
	Format(info, sizeof(info), "%T", "noscope_info_title", client);
	InfoPanel.SetTitle(info);
	
	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "noscope_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "noscope_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "noscope_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "noscope_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "noscope_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "noscope_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "noscope_info_line7", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	
	Format(info, sizeof(info), "%T", "warden_close", client);
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
		
		PrintCenterTextAll("%t", "noscope_timeuntilstart_nc", g_iTruceTime);
		
		return Plugin_Continue;
	}
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		
		if (gc_bGrav.BoolValue)
		{
			SetEntityGravity(i, gc_fGravValue.FloatValue);
		}
		
		if (gc_bOverlays.BoolValue)
		{
			ShowOverlay(i, g_sOverlayStartPath, 2.0);
		}
	}
	
	if (gc_bSounds.BoolValue)
	{
		EmitSoundToAllAny(g_sSoundStartPath);
	}
	
	PrintCenterTextAll("%t", "noscope_start_nc");
	
	CPrintToChatAll("%t %t", "noscope_tag", "noscope_start");
	
	g_hTimerTruce = null;
	
	return Plugin_Stop;
}


// Only right click attack for chicken
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (g_bIsNoScope && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (GetEntityMoveType(client) == MOVETYPE_LADDER)
		{
			g_bLadder[client] = true;
		}
		else
		{
			if (g_bLadder[client])
			{
				SetEntityGravity(client, gc_fGravValue.FloatValue);
				g_bLadder[client] = false;
			}
		}
	}
	
	return Plugin_Continue;
}

// Beacon Timer
public Action Timer_BeaconOn(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		MyJailbreak_BeaconOn(i, 2.0);
	}
	
	g_hTimerBeacon = null;
} 