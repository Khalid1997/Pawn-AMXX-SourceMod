/*
 * MyJailbreak - Cowboy Event Day Plugin.
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
#include <getplayers>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Booleans
bool g_bIsLateLoad = false;
bool g_bIsCowBoy = false;

// Console Variables
ConVar gc_bSpawnCell;
ConVar gc_fBeaconTime;
ConVar gc_iWeapon;
ConVar gc_bRandom;
//ConVar gc_iRoundTime;
ConVar gc_iTruceTime;
ConVar gc_bOverlays;
ConVar gc_bSoundsHit;
ConVar gc_sOverlayStartPath;
ConVar gc_bSounds;
ConVar gc_sSoundStartPath;
ConVar gc_sAdminFlag;

//ConVar gc_bTeleportSpawn;

// Integers
int g_iTruceTime;
int g_iCollision_Offset;

// Handles
Handle g_hTimerTruce;
Handle g_hTimerBeacon;

// Floats
float g_fPos[3];

// Strings
char g_sSoundStartPath[256];
char g_sWeapon[32];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sAdminFlag[64];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo =  {
	name = "MyJailbreak - CowBoy", 
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
	LoadTranslations("MyJailbreak.CowBoy.phrases");
	
	// AutoExecConfig
	AutoExecConfig_SetFile("CowBoy", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_cowboy_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gc_sAdminFlag = AutoExecConfig_CreateConVar("sm_cowboy_flag", "g", "Set flag for admin/vip to set this Event Day.");
	gc_bSpawnCell = AutoExecConfig_CreateConVar("sm_cowboy_spawn", "1", "0 - T teleport to CT spawn, 1 - cell doors auto open", _, true, 0.0, true, 1.0);
	
	//gc_bTeleportSpawn = AutoExecConfig_CreateConVar("sm_cowboy_teleport_spawn", "0", "0 - start event in current round from current player positions, 1 - teleport players to spawn when start event on current round(only when sm_*_begin_admin, sm_*_begin_warden, sm_*_begin_vote or sm_*_begin_daysvote is on '1')", _, true, 0.0, true, 1.0);
	
	gc_iWeapon = AutoExecConfig_CreateConVar("sm_cowboy_weapon", "1", "1 - Revolver / 2 - Dual Barettas", _, true, 1.0, true, 2.0);
	gc_bRandom = AutoExecConfig_CreateConVar("sm_cowboy_random", "1", "get a random weapon (revolver, duals) ignore: sm_cowboy_weapon", _, true, 0.0, true, 1.0);
	//gc_iRoundTime = AutoExecConfig_CreateConVar("sm_cowboy_roundtime", "5", "Round time in minutes for a single cowboy round", _, true, 1.0);
	gc_fBeaconTime = AutoExecConfig_CreateConVar("sm_cowboy_beacon_time", "240", "Time in seconds until the beacon turned on (set to 0 to disable)", _, true, 0.0);
	gc_iTruceTime = AutoExecConfig_CreateConVar("sm_cowboy_trucetime", "15", "Time in seconds players can't deal damage", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_cowboy_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.1, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_cowboy_sounds_start", "music/MyJailbreak/Yeehaw.mp3", "Path to the soundfile which should be played for a start.");
	gc_bSoundsHit = AutoExecConfig_CreateConVar("sm_cowboy_sounds_bling", "1", "0 - disabled, 1 - enable bling - hitsound sounds ", _, true, 0.1, true, 1.0);
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_cowboy_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_cowboy_overlays_start", "overlays/MyJailbreak/start", "Path to the start Overlay DONT TYPE .vmt or .vft");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	// Hooks
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	HookConVarChange(gc_sAdminFlag, OnSettingChanged);
	
	// Find
	g_iTruceTime = gc_iTruceTime.IntValue;
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	gc_sAdminFlag.GetString(g_sAdminFlag, sizeof(g_sAdminFlag));
	
	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	//Logs
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
	else if (convar == gc_sAdminFlag)
	{
		strcopy(g_sAdminFlag, sizeof(g_sAdminFlag), newValue);
	}
}

public void OnAllPluginsLoaded()
{
	DaysAPI_AddDay("cowboy");
	DaysAPI_SetDayInfo("cowboy", DayInfo_DisplayName, "Cowboy");
}

// Initialize Plugin
public void OnConfigsExecuted()
{
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	if (gc_iWeapon.IntValue == 1)
	{
		g_sWeapon = "weapon_revolver";
	}
	
	if (gc_iWeapon.IntValue == 2)
	{
		g_sWeapon = "weapon_elite";
	}
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay("cowboy");
}

/******************************************************************************
                   COMMANDS
******************************************************************************/

/******************************************************************************
                   EVENTS
******************************************************************************/

int g_iEliminations[MAXPLAYERS];
int g_iFirstPlace, g_iSecondPlace, g_iThirdPlace;
int g_iHighestEliminationsPlayer = 0, g_iHighestEliminations = 0;

public void Event_PlayerDeath(Event event, char[] szEvent, bool bDontBroadcast)
{
	if(!g_bIsCowBoy)
	{
		return;
	}
	
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(iAttacker > 0)
	{
		g_iEliminations[iAttacker]++;
		if(g_iHighestEliminations < g_iEliminations[iAttacker])
		{
			g_iHighestEliminations = g_iEliminations[iAttacker];
			g_iHighestEliminationsPlayer = iAttacker;
		}
	}
	
	int iPlayers[MAXPLAYERS];
	int iCount = GetPlayers(iPlayers, GP_Flag_Alive, GP_Team_First | GP_Team_Second);
	if(iCount == 2)
	{
		g_iThirdPlace = iVictim;
		CPrintToChat(iVictim, "* You have placed third in this day.");
	}
	
	else if(iCount == 1)
	{
		if(iAttacker)
		{
			g_iFirstPlace = iAttacker;
			g_iSecondPlace = iVictim;
			
		}
		
		else
		{
			g_iFirstPlace = iPlayers[0];
			g_iSecondPlace = iVictim;
		}
		
		CPrintToChat(g_iFirstPlace, "\x04* You have placed \x03FIRST \x04in this day. Congratulations");
		CPrintToChat(g_iSecondPlace, "\x04* You have placed \x03Second \x04in this day. Tough luck!");
	}
}

public void DaysAPI_OnDayEnd_Pre(char[] szDay)
{
	if (StrEqual(szDay, "cowboy"))
	{
		DaysAPI_ResetDayWinners();
		
		int iArray[1];
		if(g_iFirstPlace)
		{
			iArray[0] = g_iFirstPlace;
			DaysAPI_SetDayWinners("firstplace", iArray, 1);
		}
		
		if(g_iSecondPlace)
		{
			iArray[0] = g_iSecondPlace;
			DaysAPI_SetDayWinners("secondplace", iArray, 1);
		}
	
		if(g_iThirdPlace)
		{
			iArray[0] = g_iThirdPlace;
			DaysAPI_SetDayWinners("thirdplace", iArray, 1);
		}
		
		if(g_iHighestEliminationsPlayer)
		{
			iArray[0] = g_iHighestEliminationsPlayer;
			DaysAPI_SetDayWinners("bonus_most_eliminations", iArray, 1);
		}
	}
}

public void DaysAPI_OnDayEnd(char[] szIntName, any data)
{
	if (StrEqual(szIntName, "cowboy"))
	{
		ResetEventDay();
	}
}

public void DaysAPI_OnDayStart(char[] szIntName)
{
	if (StrEqual(szIntName, "cowboy"))
	{
		StartEventRound();
	}
}

// Round End
void ResetEventDay()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetEntData(i, g_iCollision_Offset, 0, 4, true);
		}
		
		g_iEliminations[i] = 0;
	}
	
	g_iHighestEliminationsPlayer = 0;
	g_iHighestEliminations = 0;
	g_iFirstPlace = 0;
	g_iSecondPlace = 0;
	g_iThirdPlace = 0;
	
	delete g_hTimerTruce;
	delete g_hTimerBeacon;
	
	g_bIsCowBoy = false;
	
	SetCvar("sv_infinite_ammo", 0);
	SetCvar("mp_teammates_are_enemies", 0);
	
	CPrintToChatAll("%t %t", "cowboy_tag", "cowboy_end");
}

// ding sound
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (gc_bSoundsHit.BoolValue && g_bIsCowBoy)
	{
		Handle data; // Delay it to a frame later. If we use IsPlayerAlive(victim) here, it would always return true.
		CreateDataTimer(0.0, Timer_Hitsound, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, event.GetInt("attacker"));
		WritePackCell(data, event.GetInt("userid"));
		ResetPack(data);
	}
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_bIsCowBoy = false;
	
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

// Map End
public void OnMapEnd()
{
	g_bIsCowBoy = false;
	
	delete g_hTimerTruce;
	delete g_hTimerBeacon;
}

// Set Client Hook
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

// Scout only
public Action OnWeaponCanUse(int client, int weapon)
{
	if (g_bIsCowBoy)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		if (index == 64 || (StrEqual(sWeapon, "weapon_elite")))
			return Plugin_Continue;
		else return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

// Prepare Event
void StartEventRound()
{
	g_bIsCowBoy = true;
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
	}
	
	CreateTimer(3.0, Timer_PrepareEvent);
	
	CPrintToChatAll("%t %t", "cowboy_tag", "cowboy_now");
	PrintCenterTextAll("%t", "cowboy_now_nc");
}

public Action Timer_PrepareEvent(Handle timer)
{
	if (!g_bIsCowBoy)
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
	
	if (gc_bRandom.BoolValue)
	{
		int randomnum = GetRandomInt(0, 1);
		
		if (randomnum == 0)
		{
			g_sWeapon = "weapon_revolver";
		}
		if (randomnum == 1)
		{
			g_sWeapon = "weapon_elite";
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetEntData(i, g_iCollision_Offset, 2, 4, true);
			
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			
			SetEntityMoveType(i, MOVETYPE_NONE);
			
			//CreateInfoPanel(i);
			
			StripAllPlayerWeapons(i);
			GivePlayerItem(i, g_sWeapon);
		}
	}

	if (gc_fBeaconTime.FloatValue > 0.0)
	{
		g_hTimerBeacon = CreateTimer(gc_fBeaconTime.FloatValue, Timer_BeaconOn, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	//GameRules_SetProp("m_iRoundTime", gc_iRoundTime.IntValue * 60, 4, 0, true);
	
	SetCvar("sv_infinite_ammo", 2);
	SetCvar("mp_teammates_are_enemies", 1);
	
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
	
	Format(info, sizeof(info), "%T", "cowboy_info_title", client);
	InfoPanel.SetTitle(info);
	
	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "cowboy_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "cowboy_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "cowboy_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "cowboy_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "cowboy_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "cowboy_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "cowboy_info_line7", client);
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
		
		PrintCenterTextAll("%t", "cowboy_timeuntilstart_nc", g_iTruceTime);
		
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
	
	PrintCenterTextAll("%t", "cowboy_start_nc");
	
	CPrintToChatAll("%t %t", "cowboy_tag", "cowboy_start");
	
	g_hTimerTruce = null;
	
	return Plugin_Stop;
}

public Action Timer_BeaconOn(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		MyJailbreak_BeaconOn(i, 2.0);
	}
	
	g_hTimerBeacon = null;
}

public Action Timer_Hitsound(Handle timer, Handle data)
{
	int attacker = GetClientOfUserId(ReadPackCell(data));
	int victim = GetClientOfUserId(ReadPackCell(data));
	
	if (attacker <= 0 || attacker > MaxClients || victim <= 0 || victim > MaxClients || attacker == victim)
		return;
	ClientCommand(attacker, "playgamesound training/bell_normal.wav");
} 