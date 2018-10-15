/*
 * MyJailbreak - Drunken Event Day Plugin.
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

// Booleans
bool g_bIsDrunk = false;

// Console Variables    gc_i = global convar integer / gc_b = global convar bool ...
ConVar gc_bSpawnCell;
ConVar gc_fBeaconTime;
ConVar gc_iTruceTime;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;
ConVar gc_bSounds;
ConVar gc_sSoundStartPath;
ConVar gc_bInvertX;
ConVar gc_bInvertY;
ConVar gc_bWiggle;

//ConVar gc_bTeleportSpawn;

// Integers    g_i = global integer
int g_iTruceTime;
int g_iCollision_Offset;

// Floats    g_i = global float
float g_fPos[3];
float g_DrunkAngles[20] =  { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };

// Handles
Handle g_hTimerTruce;

Handle g_hTimerWiggle;
Handle g_hTimerBeacon;

// Strings    g_s = global string
char g_sSoundStartPath[256];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sAdminFlag[64];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo =  {
	name = "MyJailbreak - Drunk", 
	author = "shanapu", 
	description = "Event Day for Jailbreak Server", 
	version = MYJB_VERSION, 
	url = MYJB_URL_LINK
};

// Start
public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.Drunk.phrases");
	
	// Client Commands
	RegConsoleCmd("sm_setdrunk", Command_SetDrunk, "Allows the Admin or Warden to set drunk as next round");
	
	// AutoExecConfig
	AutoExecConfig_SetFile("Drunk", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_drunk_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gc_bSpawnCell = AutoExecConfig_CreateConVar("sm_drunk_spawn", "1", "0 - T teleport to CT spawn, 1 - cell doors auto open", _, true, 0.0, true, 1.0);
	
	gc_bInvertX = AutoExecConfig_CreateConVar("sm_drunk_invert_x", "1", "Invert movement on the x-axis (left & right)", _, true, 0.0, true, 1.0);
	gc_bInvertY = AutoExecConfig_CreateConVar("sm_drunk_invert_y", "1", "Invert movement on the y-axis (forward & back)", _, true, 0.0, true, 1.0);
	gc_bWiggle = AutoExecConfig_CreateConVar("sm_drunk_wiggle", "1", "Wiggle with the screen", _, true, 0.0, true, 1.0);
	gc_fBeaconTime = AutoExecConfig_CreateConVar("sm_drunk_beacon_time", "240", "Time in seconds until the beacon turned on (set to 0 to disable)", _, true, 0.0);
	gc_iTruceTime = AutoExecConfig_CreateConVar("sm_drunk_trucetime", "15", "Time in seconds players can't deal damage", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_drunk_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.1, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_drunk_sounds_start", "music/MyJailbreak/drunk.mp3", "Path to the soundfile which should be played for a start.");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_drunk_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_drunk_overlays_start", "overlays/MyJailbreak/drunk", "Path to the start Overlay DONT TYPE .vmt or .vft");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	// Hooks
	HookEvent("player_death", Event_PlayerDeath);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	
	// Find
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	
	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	// Logs
	SetLogFile(g_sEventsLogFile, "Events", "MyJailbreak");
}

// ConVarChange for Strings
public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sOverlayStartPath) // Add overlay to download and precache table if changed
	{
		strcopy(g_sOverlayStartPath, sizeof(g_sOverlayStartPath), newValue);
		if (gc_bOverlays.BoolValue)
		{
			PrecacheDecalAnyDownload(g_sOverlayStartPath);
		}
	}
	else if (convar == gc_sSoundStartPath) // Add sound to download and precache table if changed
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
	DaysAPI_AddDay("drunk");
	DaysAPI_SetDayInfo("drunk", DayInfo_DisplayName, "Drunk");
}

public void OnLibraryRemoved(const char[] name)
{
	
}

public void OnLibraryAdded(const char[] name)
{
	
}

// Initialize Plugin
public void OnConfigsExecuted()
{
	// Find Convar Times
	g_iTruceTime = gc_iTruceTime.IntValue;
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay("drunk");
}


/******************************************************************************
                   COMMANDS
******************************************************************************/

// Admin & Warden set Event
public Action Command_SetDrunk(int client, int args)
{
	if (CheckVipFlag(client, g_sAdminFlag)) // Called by admin/VIP
	{
		if (DaysAPI_IsDayRunning())
		{
			CReplyToCommand(client, "* A Day is already running");
			return Plugin_Handled;
		}
		
		StartEventRound();
		
		if (MyJailbreak_ActiveLogging())
		{
			LogToFileEx(g_sEventsLogFile, "Event Drunk was started by admin %L", client);
		}
	}
	
	return Plugin_Handled;
}

/******************************************************************************
                   EVENTS
******************************************************************************/

public void DaysAPI_OnDayEnd_Pre(char[] szName)
{
	if (!StrEqual(szName, "drunk"))
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
	
	if(iCount == 1)
	{
		DaysAPI_SetDayWinners("winner", iWinners, iCount);
	}
}

public void DaysAPI_OnDayEnd(char[] szName)
{
	if (StrEqual(szName, "drunk"))
	{
		ResetEventDay();
	}
}

void ResetEventDay()
{
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
		SetEntData(i, g_iCollision_Offset, 0, 4, true); // disbale noblock
		KillDrunk(i);
	}
	
	if(iCount == 1)
	{	
		CPrintToChatAll("\x04* \x03'%N' \x04won the \x05Drunk \x04day.", iWinners[0]);
	}
	
	g_hTimerWiggle = null;
	
	delete g_hTimerWiggle;
	delete g_hTimerBeacon;
	delete g_hTimerTruce; // kill start time if still running
	
	// return to default start values
	g_bIsDrunk = false;
	
	SetCvar("sv_infinite_ammo", 0);
	SetCvar("mp_teammates_are_enemies", 0);
	
	CPrintToChatAll("%t %t", "drunk_tag", "drunk_end");
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")); // Get the dead clients id
	
	KillDrunk(client);
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_bIsDrunk = false;
	
	// Precache Sound & Overlay
	if (gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundStartPath);
	}
	
	if (gc_bOverlays.BoolValue)
	{
		PrecacheDecalAnyDownload(g_sOverlayStartPath);
	}
}

// Map End
public void OnMapEnd()
{
	// return to default start values
	g_bIsDrunk = false;
	
	delete g_hTimerWiggle;
	delete g_hTimerBeacon;
	delete g_hTimerTruce; // kill start time if still running
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

public void DaysAPI_OnDayStart(char[] name)
{
	if (StrEqual(name, "drunk"))
	{
		StartEventRound();
	}
}

// Prepare Event
void StartEventRound()
{
	g_bIsDrunk = true;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
	}
	
	CreateTimer(3.0, Timer_PrepareEvent);
	
	CPrintToChatAll("%t %t", "drunk_tag", "drunk_now");
	PrintCenterTextAll("%t", "drunk_now_nc");
}

public Action Timer_PrepareEvent(Handle timer)
{
	if (!g_bIsDrunk)
		return Plugin_Handled;
	
	PrepareDay();
	
	return Plugin_Handled;
}

void PrepareDay()
{
	if (/*(thisround && gc_bTeleportSpawn.BoolValue) ||*/!gc_bSpawnCell.BoolValue) // spawn Terrors to CT Spawn 
	{
		int RandomCT = 0;
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
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
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		SetEntData(i, g_iCollision_Offset, 2, 4, true);
		
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
		
		//CreateInfoPanel(i);
		
		StripAllPlayerWeapons(i);
		
		GivePlayerItem(i, "weapon_knife"); // give Knife
		
		if (gc_bWiggle.BoolValue)
		{
			g_hTimerWiggle = CreateTimer(1.0, Timer_Drunk, i, TIMER_REPEAT);
		}
	}
	
	if (gc_fBeaconTime.FloatValue > 0.0)
	{
		g_hTimerBeacon = CreateTimer(gc_fBeaconTime.FloatValue, Timer_BeaconOn, TIMER_FLAG_NO_MAPCHANGE);
	}	
	
	//GameRules_SetProp("m_iRoundTime", gc_iRoundTime.IntValue * 60, 4, 0, true);
	
	SetCvar("mp_teammates_are_enemies", 1);
	g_hTimerTruce = CreateTimer(1.0, Timer_StartEvent, _, TIMER_REPEAT);
}


// drunk
void KillDrunk(int client)
{
	float angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
}

// Switch WSAD
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (g_bIsDrunk)
	{
		if (gc_bInvertX.BoolValue)
		{
			vel[1] = -vel[1]; // Will always equal to the opposite value, according to rules of arithmetic.
			
			if (buttons & IN_MOVELEFT) // Fixes walking animations for CS:GO.
			{
				buttons &= ~IN_MOVELEFT;
				buttons |= IN_MOVERIGHT;
			}
			else if (buttons & IN_MOVERIGHT)
			{
				buttons &= ~IN_MOVERIGHT;
				buttons |= IN_MOVELEFT;
			}
		}
		
		if (gc_bInvertY.BoolValue)
		{
			vel[0] = -vel[0];
			
			if (buttons & IN_FORWARD)
			{
				buttons &= ~IN_FORWARD;
				buttons |= IN_BACK;
			}
			else if (buttons & IN_BACK)
			{
				buttons &= ~IN_BACK;
				buttons |= IN_FORWARD;
			}
		}
		
		return Plugin_Changed;
	}
	
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
	
	Format(info, sizeof(info), "%T", "drunk_info_title", client);
	InfoPanel.SetTitle(info);
	
	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "drunk_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "drunk_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "drunk_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "drunk_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "drunk_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "drunk_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "drunk_info_line7", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");

	InfoPanel.DrawItem(info);
	
	InfoPanel.Send(client, Handler_NullCancel, 20); // open info Panel
}

/******************************************************************************
                   TIMER
******************************************************************************/

// Start Timer
public Action Timer_StartEvent(Handle timer)
{
	if (g_iTruceTime > 0) // countdown to start
	{
		g_iTruceTime--;
		
		if (g_iTruceTime == gc_iTruceTime.IntValue - 3)
		{
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
		}
		
		PrintCenterTextAll("%t", "drunk_timeuntilstart_nc", g_iTruceTime);
		
		return Plugin_Continue;
	}
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		
		if (gc_bOverlays.BoolValue)
		{
			ShowOverlay(i, g_sOverlayStartPath, 5.0);
		}
	}
	
	if (gc_bSounds.BoolValue)
	{
		EmitSoundToAllAny(g_sSoundStartPath);
	}
	
	PrintCenterTextAll("%t", "drunk_start_nc");
	
	CPrintToChatAll("%t %t", "drunk_tag", "drunk_start");
	
	g_hTimerTruce = null;
	
	return Plugin_Stop;
}

public Action Timer_BeaconOn(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		float random = GetRandomFloat(0.5, 4.0);
		MyJailbreak_BeaconOn(i, random);
	}
	
	g_hTimerBeacon = null;
}

public Action Timer_Drunk(Handle timer, any client)
{
	if (g_bIsDrunk && IsValidClient(client, false, false))
	{
		float angs[3];
		GetClientEyeAngles(client, angs);
		
		angs[2] = g_DrunkAngles[GetRandomInt(0, 100) % 20];
		
		TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
	}
	
	return Plugin_Handled;
} 