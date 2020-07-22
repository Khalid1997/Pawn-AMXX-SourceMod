/*
 * MyJailbreak - HE Battle Event Day Plugin.
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
#include <simonapi>
#include <myjailbreak_e>
#include <mystocks>
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
bool g_bIsLateLoad = false;
bool g_bIsHEbattle = false;

// Console Variables
ConVar gc_fGravValue;
ConVar gc_iPlayerHP;
ConVar gc_bSpawnCell;
ConVar gc_iTruceTime;
ConVar gc_bSounds;
ConVar gc_sSoundStartPath;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;

// Integers
int g_iTruceTime;
int g_iCollision_Offset;


// Handles
Handle g_hTimerTruce;
Handle g_hTimerGravity;

// Floats
float g_fPos[3];

// Strings
char g_sSoundStartPath[256];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo =  {
	name = "MyJailbreak - HE Battle", 
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
	LoadTranslations("MyJailbreak.HEbattle.phrases");
	
	// AutoExecConfig
	AutoExecConfig_SetFile("HEbattle", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_hebattle_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gc_bSpawnCell = AutoExecConfig_CreateConVar("sm_hebattle_spawn", "1", "0 - T teleport to CT spawn, 1 - cell doors auto open", _, true, 0.0, true, 1.0);
	
	//gc_bTeleportSpawn = AutoExecConfig_CreateConVar("sm_hebattle_teleport_spawn", "0", "0 - start event in current round from current player positions, 1 - teleport players to spawn when start event on current round(only when sm_*_begin_admin, sm_*_begin_warden, sm_*_begin_vote or sm_*_begin_daysvote is on '1')", _, true, 0.0, true, 1.0);
	gc_iPlayerHP = AutoExecConfig_CreateConVar("sm_hebattle_hp", "100", "HP a Player get on Spawn", _, true, 1.0);
	gc_fGravValue = AutoExecConfig_CreateConVar("sm_hebattle_gravity_value", "0.5", "Ratio for gravity 0.5 moon / 1.0 earth ", _, true, 0.1, true, 1.0);
	gc_iTruceTime = AutoExecConfig_CreateConVar("sm_hebattle_trucetime", "15", "Time in seconds players can't deal damage", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_hebattle_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.0, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_hebattle_sounds_start", "music/MyJailbreak/start.mp3", "Path to the soundfile which should be played for start");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_hebattle_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_hebattle_overlays_start", "overlays/MyJailbreak/start", "Path to the start Overlay DONT TYPE .vmt or .vft");

	//ConVar gc_bTeleportSpawn;
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	// Hooks
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("hegrenade_detonate", Event_HE_Detonate);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	
	// Find
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	
	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
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

public void Event_PlayerDeath(Event event, char[] szName, bool bDontbroadcast)
{
	int iCount;
	for (int i = 1; i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		if(!IsPlayerAlive(i))
		{
			continue;
		}
		
		iCount++;
	}
	
	if(iCount == 1)
	{
		CS_TerminateRound(5.0, CSRoundEnd_Draw);
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
	DaysAPI_AddDay("hebattle");
	DaysAPI_SetDayInfo("hebattle", DayInfo_DisplayName, "HE Battle");
}

// Initialize Plugin
public void OnConfigsExecuted()
{
	g_iTruceTime = gc_iTruceTime.IntValue;
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay("hebattle");
}

/******************************************************************************
                   EVENTS
******************************************************************************/

// Give new Nades after detonation
public void Event_HE_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bIsHEbattle)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
		{
			return;
		}
		
		//SetEntProp(client, Prop_Send, "m_iAmmo", 0, 4, 13);
		int iEnt = GetPlayerWeaponSlot(client, 3);
		
		if(iEnt != -1)
		{
			EquipPlayerWeapon(client, iEnt);
			RemovePlayerItem(client, iEnt);
			RemoveEdict(iEnt);
		}
		
		GivePlayerItem(client, "weapon_hegrenade");
		//EquipPlayerWeapon(client, iEnt);
		//EquipPlayerWeapon(client, iEnt);
	}
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_bIsHEbattle = false;
	
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
	g_bIsHEbattle = false;
	
	delete g_hTimerTruce;
	delete g_hTimerGravity;
}

/*
public void MyJailbreak_ResetEventDay()
{
	g_bStartHEbattle = false;

	if (g_bIsHEbattle)
	{
		g_iRound = g_iMaxRound;
		ResetEventDay();
	}
}*/

void ResetEventDay()
{	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		SetEntityGravity(i, 1.0);
		SetEntData(i, g_iCollision_Offset, 0, 4, true);
		StripAllPlayerWeapons(i);
		
		GivePlayerItem(i, "weapon_knife");
		
		SetEntityMoveType(i, MOVETYPE_WALK);
		
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
	}
	
	delete g_hTimerTruce;
	delete g_hTimerGravity;
	
	g_bIsHEbattle = false;
	
	SetCvar("sm_hosties_lr", 1);
	SetCvar("mp_teammates_are_enemies", 0);
	
	CPrintToChatAll("%t %t", "hebattle_tag", "hebattle_end");
}


// Set Client Hook
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
}

// HE Grenade only
public Action OnWeaponCanUse(int client, int weapon)
{
	if (g_bIsHEbattle)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		//PrintToServer("sWeapon %s", sWeapon);
		if (StrEqual(sWeapon, "weapon_hegrenade"))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				return Plugin_Continue;
			}
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

public void DaysAPI_OnDayStart(char[] szDay)
{
	if (StrEqual(szDay, "hebattle"))
	{
		StartEventRound();
	}
}

public void DaysAPI_OnDayEnd_Pre(char[] szDay)
{
	if (!StrEqual(szDay, "hebattle"))
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
	
	if (iCount == 1)
	{
		DaysAPI_ResetDayWinners();
		DaysAPI_SetDayWinners("winner", iWinners, iCount);
	}
}


public void DaysAPI_OnDayEnd(char[] szDay)
{
	if (StrEqual(szDay, "hebattle"))
	{	
		ResetEventDay();
	}
}

// Prepare Event
void StartEventRound()
{
	g_bIsHEbattle = true;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
	}
	
	CreateTimer(3.0, Timer_PrepareEvent);
	
	CPrintToChatAll("%t %t", "hebattle_tag", "hebattle_now");
	PrintCenterTextAll("%t", "hebattle_now_nc");
}

public Action Timer_PrepareEvent(Handle timer)
{
	if (!g_bIsHEbattle)
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
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			//CreateInfoPanel(i);
			
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			
			StripAllPlayerWeapons(i);
			//GivePlayerItem(i, "weapon_knife");
			GivePlayerItem(i, "weapon_hegrenade");
			
			SetEntityHealth(i, gc_iPlayerHP.IntValue);
			
			SetEntData(i, g_iCollision_Offset, 2, 4, true);
			
			SetEntityGravity(i, gc_fGravValue.FloatValue);
		}
	}
	
	//GameRules_SetProp("m_iRoundTime", gc_iRoundTime.IntValue*60, 4, 0, true);
	
	SetCvar("mp_teammates_are_enemies", 1);
	
	g_hTimerTruce = CreateTimer(1.0, Timer_StartEvent, _, TIMER_REPEAT);
	g_hTimerGravity = CreateTimer(1.0, Timer_CheckGravity, _, TIMER_REPEAT);
}

/******************************************************************************
                   MENUS
******************************************************************************/

stock void CreateInfoPanel(int client)
{
	// Create info Panel
	char info[255];
	
	Panel InfoPanel = new Panel();
	
	Format(info, sizeof(info), "%T", "hebattle_info_title", client);
	InfoPanel.SetTitle(info);
	
	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "hebattle_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "hebattle_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "hebattle_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "hebattle_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "hebattle_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "hebattle_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "hebattle_info_line7", client);
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
		
		PrintCenterTextAll("%t", "hebattle_timeuntilstart_nc", g_iTruceTime);
		
		return Plugin_Continue;
	}
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, true, false))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			
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
	
	PrintCenterTextAll("%t", "hebattle_start_nc");
	
	CPrintToChatAll("%t %t", "hebattle_tag", "hebattle_start");
	
	g_hTimerTruce = null;
	
	return Plugin_Stop;
}

// Give back Gravity if it gone -> ladders
public Action Timer_CheckGravity(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, false, false))
	{
		if (GetEntityGravity(i) != 1.0)
		{
			SetEntityGravity(i, gc_fGravValue.FloatValue);
		}
	}
} 