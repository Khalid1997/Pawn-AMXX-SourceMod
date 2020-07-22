/*
 * MyJailbreak - Duckhunt Event Day Plugin.
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
#include <thirdperson>
#include <daysapi>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Booleans
bool g_bIsLateLoad = false;
bool g_bIsDuckHunt = false;
bool g_bLadder[MAXPLAYERS + 1] = false;

// Console Variables
ConVar gc_iHunterHP;
ConVar gc_iHunterHPincrease;
ConVar gc_iChickenHP;
ConVar gc_bFlyMode;
ConVar gc_bSounds;
ConVar gc_fBeaconTime;
ConVar gc_sSoundStartPath;
ConVar gc_iTruceTime;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;

// Integers
int g_iTruceTime;
int g_iCollision_Offset;

// Handles
Handle g_hTimerTruce;
Handle g_hTimerBeacon;

// Strings
char g_sSoundStartPath[256];
char g_sHunterModel[256] = "models/player/custom_player/legacy/tm_phoenix_heavy.mdl";
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sModelPathCTPrevious[MAXPLAYERS + 1][256];
char g_sModelPathTPrevious[MAXPLAYERS + 1][256];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo =  {
	name = "MyJailbreak - DuckHunt", 
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
	LoadTranslations("MyJailbreak.DuckHunt.phrases");
	
	// Client Commands
	RegConsoleCmd("drop", Command_ToggleFly);
	
	// AutoExecConfig
	AutoExecConfig_SetFile("DuckHunt", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_duckhunt_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	gc_fBeaconTime = AutoExecConfig_CreateConVar("sm_duckhunt_beacon_time", "240", "Time in seconds until the beacon turned on (set to 0 to disable)", _, true, 0.0);
	gc_bFlyMode = AutoExecConfig_CreateConVar("sm_duckhunt_flymode", "1", "0 - Low gravity, 1 - 'Flymode' (like a slow noclip with clipping). Bit difficult", _, true, 0.0, true, 1.0);
	gc_iHunterHP = AutoExecConfig_CreateConVar("sm_duckhunt_hunter_hp", "850", "HP the hunters got on Spawn", _, true, 1.0);
	gc_iHunterHPincrease = AutoExecConfig_CreateConVar("sm_duckhunt_hunter_hp_extra", "100", "HP the Hunter get additional per extra duck", _, true, 1.0);
	gc_iChickenHP = AutoExecConfig_CreateConVar("sm_duckhunt_chicken_hp", "100", "HP the chicken got on Spawn", _, true, 1.0);
	gc_iTruceTime = AutoExecConfig_CreateConVar("sm_duckhunt_trucetime", "15", "Time in seconds until cells open / players can't deal damage", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_duckhunt_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.0, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_duckhunt_sounds_start", "music/MyJailbreak/duckhunt.mp3", "Path to the soundfile which should be played for start");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_duckhunt_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_duckhunt_overlays_start", "overlays/MyJailbreak/start", "Path to the start Overlay DONT TYPE .vmt or .vft");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_reload", Event_WeaponReload);
	HookEvent("weapon_outofammo", Event_WeaponReload);
	HookEvent("hegrenade_detonate", Event_HE_Detonate);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	
	// FindConVar
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	
	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
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
	DaysAPI_AddDay("duckhunt");
	DaysAPI_SetDayInfo("duckhunt", DayInfo_DisplayName, "Duck Hunt");
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
	g_iTruceTime = gc_iTruceTime.IntValue;

}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay("duckhunt");
}


/******************************************************************************
                   COMMANDS
******************************************************************************/

public Action Command_ToggleFly(int client, int args)
{
	if (g_bIsDuckHunt && (GetClientTeam(client) == CS_TEAM_T) && gc_bFlyMode.BoolValue)
	{
		MoveType movetype = GetEntityMoveType(client);
		
		if (movetype != MOVETYPE_FLY)
		{
			SetEntityMoveType(client, MOVETYPE_FLY);
			
			return Plugin_Handled;
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/******************************************************************************
                   EVENTS
******************************************************************************/

public void DaysAPI_OnDayEnd_Pre(char[] szIntName)
{
	if(!StrEqual(szIntName, "duckhunt"))
	{
		return;
	}
	
	bool bFoundFirstTeam = false;
	int iWinnerTeam = CS_TEAM_NONE;
	int iWinners[MAXPLAYERS], iCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if(!IsPlayerAlive(i))
		{
			continue;
		}
		
		if(!bFoundFirstTeam)
		{
			bFoundFirstTeam = true;
			iWinnerTeam = GetClientTeam(i);
			
			iWinners[iCount++] = i;
			continue;
		}
		
		if(GetClientTeam(i) != iWinnerTeam)
		{
			iWinnerTeam = CS_TEAM_NONE;
			break;
		}
		
		iWinners[iCount++] = i;
	}
	
	DaysAPI_ResetDayWinners();
	if(iWinnerTeam == CS_TEAM_NONE)
	{
		CPrintToChatAll("\x04* No one won the day.");
	}
	
	else
	{
		CPrintToChatAll("\x04* team \x03'%s' \x04won the \x05Duck Hunt \x04day.", iWinnerTeam == CS_TEAM_CT ? "Counter-Terrorists" : "Terrorsits");
		DaysAPI_SetDayWinners(iWinnerTeam == CS_TEAM_CT ? "winner_ct" : "winner_t", iWinners, iCount);
	}
}

public void DaysAPI_OnDayEnd(char[] name)
{
	if (StrEqual(name, "duckhunt"))
	{
		ResetEventDay();
	}
}

void ResetEventDay()
{
	ThirdPerson_SetGlobalLockMode(TPT_None);
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, false, true))
	{
		SetEntData(i, g_iCollision_Offset, 0, 4, true);
		
		SetEntityGravity(i, 1.0);
		
		FirstPerson(i);
		
		SetEntityMoveType(i, MOVETYPE_WALK);
	}
	
	delete g_hTimerBeacon;
	delete g_hTimerTruce;
	
	g_bIsDuckHunt = false;
	
	CPrintToChatAll("%t %t", "duckhunt_tag", "duckhunt_end");
}

// Give new Nades after detonation to chicken
public void Event_HE_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bIsDuckHunt)
	{
		int target = GetClientOfUserId(event.GetInt("userid"));
		
		if (GetClientTeam(target) == 1 && !IsPlayerAlive(target))
		{
			return;
		}
		
		GivePlayerItem(target, "weapon_hegrenade");
	}
	
	return;
}

// Give new Ammo to Hunter
public void Event_WeaponReload(Event event, char[] name, bool dontBroadcast)
{
	if (g_bIsDuckHunt)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		
		if (IsValidClient(client, false, false) && (GetClientTeam(client) == CS_TEAM_CT))
		{
			int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 32);
		}
	}
}

public void Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	if (g_bIsDuckHunt)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		
		FirstPerson(client);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_bIsDuckHunt = false;
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	// Precache Sound & Overlay
	if (gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundStartPath);
	}
	
	if (gc_bOverlays.BoolValue)
	{
		PrecacheDecalAnyDownload(g_sOverlayStartPath);
	}
	
	PrecacheModel("models/chicken/chicken.mdl", true);
	PrecacheModel(g_sHunterModel, true);
	AddFileToDownloadsTable("materials/models/props_farm/chicken_white.vmt");
	AddFileToDownloadsTable("materials/models/props_farm/chicken_white.vtf");
	AddFileToDownloadsTable("models/chicken/chicken.dx90.vtx");
	AddFileToDownloadsTable("models/chicken/chicken.phy");
	AddFileToDownloadsTable("models/chicken/chicken.vvd");
	AddFileToDownloadsTable("models/chicken/chicken.mdl");
}

// Map End
public void OnMapEnd()
{
	g_bIsDuckHunt = false;
	delete g_hTimerTruce;
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		FirstPerson(i);
		SetEntityMoveType(i, MOVETYPE_WALK);
	}
}

// Set Client Hook
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

// Nova & Grenade only
public Action OnWeaponCanUse(int client, int weapon)
{
	if (g_bIsDuckHunt)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		
		if ((GetClientTeam(client) == CS_TEAM_T && StrEqual(sWeapon, "weapon_hegrenade")) || (GetClientTeam(client) == CS_TEAM_CT && StrEqual(sWeapon, "weapon_nova")))
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

// Only right click attack for chicken
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (g_bIsDuckHunt && (GetClientTeam(client) == CS_TEAM_T) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (buttons & IN_ATTACK)
		{
			return Plugin_Handled;
		}
		if (!gc_bFlyMode.BoolValue)
		{
			if (GetEntityMoveType(client) == MOVETYPE_LADDER)
			{
				g_bLadder[client] = true;
			}
			else
			{
				if (g_bLadder[client])
				{
					SetEntityGravity(client, 0.3);
					g_bLadder[client] = false;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (g_bIsDuckHunt)
	{
		FirstPerson(client);
	}
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

// Back to First Person
void FirstPerson(int client)
{
	if (IsValidClient(client, false, true))
	{
		ClientCommand(client, "firstperson");
	}
}

public void DaysAPI_OnDayStart(char[] name)
{
	if (StrEqual(name, "duckhunt"))
	{
		StartEventRound();
	}
}

// Prepare Event
void StartEventRound()
{
	g_bIsDuckHunt = true;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
	}
	
	CreateTimer(3.0, Timer_PrepareEvent);
	
	CPrintToChatAll("%t %t", "duckhunt_tag", "duckhunt_now");
	PrintCenterTextAll("%t", "duckhunt_now_nc");
}

public Action Timer_PrepareEvent(Handle htimer)
{
	if (g_bIsDuckHunt)
	{
		PrepareDay();
	}
}

void PrepareDay()
{
	ThirdPerson_SetGlobalLockMode(TPT_ThirdPerson);
	
	/*
	if (!gp_bSmartJailDoors || (SJD_IsCurrentMapConfigured() != true)) // spawn Terrors to CT Spawn 
	{
		int RandomCT = 0;
		int RandomT = 0;
		
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
		{
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				CS_RespawnPlayer(i);
				RandomCT = i;
			}
			else if (GetClientTeam(i) == CS_TEAM_T)
			{
				CS_RespawnPlayer(i);
				RandomT = i;
			}
			
			if (RandomCT != 0 && RandomT != 0)
			{
				break;
			}
		}
		
		if (RandomCT && RandomT)
		{
			float g_fPosT[3], g_fPosCT[3];
			GetClientAbsOrigin(RandomT, g_fPosT);
			GetClientAbsOrigin(RandomCT, g_fPosCT);
			g_fPosT[2] = g_fPosT[2] + 5;
			g_fPosCT[2] = g_fPosCT[2] + 5;
			
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					TeleportEntity(i, g_fPosT, NULL_VECTOR, NULL_VECTOR);
				}
				else if (GetClientTeam(i) == CS_TEAM_CT)
				{
					TeleportEntity(i, g_fPosCT, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}*/
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		SetEntData(i, g_iCollision_Offset, 2, 4, true);
		
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		//CreateInfoPanel(i);
		
		StripAllPlayerWeapons(i);
		
		if (GetClientTeam(i) == CS_TEAM_CT && IsValidClient(i, false, false))
		{
			int HunterHP = gc_iHunterHP.IntValue;
			int difference = (GetAlivePlayersCount(CS_TEAM_T) - GetAlivePlayersCount(CS_TEAM_CT));
			
			if (difference > 0)HunterHP = HunterHP + (gc_iHunterHPincrease.IntValue * difference);
			
			SetEntityHealth(i, HunterHP);
			GivePlayerItem(i, "weapon_nova");
		}
		else if (GetClientTeam(i) == CS_TEAM_T && IsValidClient(i, false, false))
		{
			if (gc_bFlyMode.BoolValue)
			{
				SetEntityMoveType(i, MOVETYPE_FLY);
			}
			else
			{
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.2);
				SetEntityGravity(i, 0.3);
			}
			
			SetEntityHealth(i, gc_iChickenHP.IntValue);
			GivePlayerItem(i, "weapon_hegrenade");
		}
	}
	
	if (gc_fBeaconTime.FloatValue > 0.0)
	{
		g_hTimerBeacon = CreateTimer(gc_fBeaconTime.FloatValue, Timer_BeaconOn, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	CreateTimer(1.1, Timer_SetModel);
	
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
	
	Format(info, sizeof(info), "%T", "duckhunt_info_title", client);
	InfoPanel.SetTitle(info);
	
	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "duckhunt_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "duckhunt_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "duckhunt_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "duckhunt_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "duckhunt_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "duckhunt_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "duckhunt_info_line7", client);
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
				if (GetClientTeam(i) == CS_TEAM_CT)
				{
					SetEntityMoveType(i, MOVETYPE_WALK);
				}
			}
		}
		
		PrintCenterTextAll("%t", "duckhunt_timeuntilstart_nc", g_iTruceTime);
		
		return Plugin_Continue;
	}
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		
		if (GetClientTeam(i) == CS_TEAM_T)
		{
			SetEntityGravity(i, 0.3);
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
	
	PrintCenterTextAll("%t", "duckhunt_start_nc");
	
	CPrintToChatAll("%t %t", "duckhunt_tag", "duckhunt_start");
	
	g_hTimerTruce = null;
	
	return Plugin_Stop;
}

// Delay Set model for sm_skinchooser
public Action Timer_SetModel(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", g_sModelPathCTPrevious[i], sizeof(g_sModelPathCTPrevious[]));
			SetEntityModel(i, g_sHunterModel);
		}
		else if (GetClientTeam(i) == CS_TEAM_T)
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", g_sModelPathTPrevious[i], sizeof(g_sModelPathTPrevious[]));
			SetEntityModel(i, "models/chicken/chicken.mdl");
		}
	}
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