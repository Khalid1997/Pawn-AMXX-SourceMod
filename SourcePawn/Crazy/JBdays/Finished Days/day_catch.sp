/*
 * MyJailbreak - Catch & Freeze Event Day Plugin.
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
#include <getplayers>
#include <emitsoundany>
#include <multicolors>
#include <autoexecconfig>
#include <myjailbreak_e>
#include <mystocks>
#include <daysapi>

// Optional Plugins
#undef REQUIRE_PLUGIN
#include <CustomPlayerSkins>
#define REQUIRE_PLUGIN

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Defines
#define IsSprintUsing    (1 << 0)
#define IsSprintCoolDown (1 << 1)

// Booleans
bool g_bIsLateLoad = false;
bool g_bIsCatch = false;
bool g_bCatched[MAXPLAYERS + 1] = false;

bool gp_bCustomPlayerSkins;

// Console Variables
ConVar gc_bSounds;
ConVar gc_bOverlays;
ConVar gc_bStayOverlay;
ConVar gc_sOverlayStartPath;
ConVar gc_bWallhack;
ConVar gc_fBeaconTime;
ConVar gc_iFreezeTime;
ConVar gc_sOverlayFreeze;
ConVar gc_bSprintUse;
ConVar gc_iSprintCooldown;
ConVar gc_bSprint;
ConVar gc_fSprintSpeed;
ConVar gc_fSprintTime;
ConVar gc_sSoundStartPath;
ConVar gc_sSoundFreezePath;
ConVar gc_sSoundUnFreezePath;
ConVar gc_iCatchCount;
//ConVar gc_bTeleportSpawn;


// Integers
int g_iSprintStatus[MAXPLAYERS+1];
int g_iCatchCounter[MAXPLAYERS+1];
int g_iFreezeTime;
int g_iCollision_Offset;

// Handles
Handle g_hTimerSprint[MAXPLAYERS+1];
Handle g_hTimerFreeze;
Handle g_hTimerBeacon;

// Strings
char g_sSoundUnFreezePath[256];
char g_sSoundFreezePath[256];
char g_sOverlayFreeze[256];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sSoundStartPath[256];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo = {
	name = "MyJailbreak - Catch & Freeze",
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
	LoadTranslations("MyJailbreak.Catch.phrases");

	// Client Commands
	RegConsoleCmd("sm_sprint", Command_StartSprint, "Start sprinting!");

	// AutoExecConfig
	AutoExecConfig_SetFile("Catch", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);

	AutoExecConfig_CreateConVar("sm_catch_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gc_iCatchCount = AutoExecConfig_CreateConVar("sm_catch_count", "0", "How many times a terror can be catched before he get killed. 0 = T dont get killed ever all T must be catched", _, true, 0.0);
	gc_fBeaconTime = AutoExecConfig_CreateConVar("sm_catch_beacon_time", "240", "Time in seconds until the beacon turned on (set to 0 to disable)", _, true, 0.0);
	gc_bWallhack = AutoExecConfig_CreateConVar("sm_catch_wallhack", "1", "0 - disabled, 1 - enable wallhack for CT to see freezed enemeys", _, true,  0.0, true, 1.0);

	//gc_bTeleportSpawn = AutoExecConfig_CreateConVar("sm_catch_teleport_spawn", "0", "0 - start event in current round from current player positions, 1 - teleport players to spawn when start event on current round(only when sm_*_begin_admin, sm_*_begin_warden, sm_*_begin_vote or sm_*_begin_daysvote is on '1')", _, true, 0.0, true, 1.0);

	//gc_iRoundTime = AutoExecConfig_CreateConVar("sm_catch_roundtime", "5", "Round time in minutes for a single catch round", _, true, 1.0);
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_catch_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_catch_overlays_start", "overlays/MyJailbreak/start", "Path to the start Overlay DONT TYPE .vmt or .vft");
	gc_sOverlayFreeze = AutoExecConfig_CreateConVar("sm_catch_overlayfreeze_path", "overlays/MyJailbreak/frozen", "Path to the Freeze Overlay DONT TYPE .vmt or .vft");
	gc_bStayOverlay = AutoExecConfig_CreateConVar("sm_catch_stayoverlay", "1", "0 - overlays will removed after 3sec., 1 - overlays will stay until unfreeze", _, true, 0.0, true, 1.0);
	gc_iFreezeTime = AutoExecConfig_CreateConVar("sm_catch_freezetime", "15", "Time in seconds CTs are freezed", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_catch_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.0, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_catch_sounds_start", "music/MyJailbreak/start.mp3", "Path to the soundfile which should be played for a start.");
	gc_sSoundFreezePath = AutoExecConfig_CreateConVar("sm_catch_sounds_freeze", "music/MyJailbreak/freeze.mp3", "Path to the soundfile which should be played on freeze.");
	gc_sSoundUnFreezePath = AutoExecConfig_CreateConVar("sm_catch_sounds_unfreeze", "music/MyJailbreak/unfreeze.mp3", "Path to the soundfile which should be played on unfreeze.");
	gc_bSprint = AutoExecConfig_CreateConVar("sm_catch_sprint_enable", "1", "0 - disabled, 1 - enable ShortSprint", _, true, 0.0, true, 1.0);
	gc_bSprintUse = AutoExecConfig_CreateConVar("sm_catch_sprint_button", "1", "0 - disabled, 1 - enable +use button for sprint", _, true, 0.0, true, 1.0);
	gc_iSprintCooldown= AutoExecConfig_CreateConVar("sm_catch_sprint_cooldown", "10", "Time in seconds the player must wait for the next sprint", _, true, 0.0);
	gc_fSprintSpeed = AutoExecConfig_CreateConVar("sm_catch_sprint_speed", "1.25", "Ratio for how fast the player will sprint", _, true, 1.01);
	gc_fSprintTime = AutoExecConfig_CreateConVar("sm_catch_sprint_time", "3.0", "Time in seconds the player will sprint", _, true, 1.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	HookConVarChange(gc_sOverlayFreeze, OnSettingChanged);
	HookConVarChange(gc_sSoundFreezePath, OnSettingChanged);
	HookConVarChange(gc_sSoundUnFreezePath, OnSettingChanged);

	// Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerTeam);

	// FindConVar
	g_iFreezeTime = gc_iFreezeTime.IntValue;
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	gc_sSoundFreezePath.GetString(g_sSoundFreezePath, sizeof(g_sSoundFreezePath));
	gc_sSoundUnFreezePath.GetString(g_sSoundUnFreezePath, sizeof(g_sSoundUnFreezePath));
	gc_sOverlayFreeze.GetString(g_sOverlayFreeze, sizeof(g_sOverlayFreeze));

	// Logs
	SetLogFile(g_sEventsLogFile, "Events", "MyJailbreak");

	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

	// Late loading
	if (g_bIsLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}

		g_bIsLateLoad = false;
	}
}

// ConVarChange for Strings
public void OnSettingChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sSoundFreezePath)
	{
		strcopy(g_sSoundFreezePath, sizeof(g_sSoundFreezePath), newValue);
		if (gc_bSounds.BoolValue)
		{
			PrecacheSoundAnyDownload(g_sSoundFreezePath);
		}
	}
	else if (convar == gc_sSoundUnFreezePath)
	{
		strcopy(g_sSoundUnFreezePath, sizeof(g_sSoundUnFreezePath), newValue);
		if (gc_bSounds.BoolValue)
		{
			PrecacheSoundAnyDownload(g_sSoundUnFreezePath);
		}
	}
	else if (convar == gc_sOverlayFreeze)
	{
		strcopy(g_sOverlayFreeze, sizeof(g_sOverlayFreeze), newValue);
		if (gc_bOverlays.BoolValue)
		{
			PrecacheDecalAnyDownload(g_sOverlayFreeze);
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
	else if (convar == gc_sOverlayStartPath)
	{
		strcopy(g_sOverlayStartPath, sizeof(g_sOverlayStartPath), newValue);
		if (gc_bOverlays.BoolValue)
		{
			PrecacheDecalAnyDownload(g_sOverlayStartPath);
		}
	}
}

public void OnAllPluginsLoaded()
{
	PrintToServer("Reloaded ALL PLUGINS");
	
	gp_bCustomPlayerSkins = LibraryExists("CustomPlayerSkins");
	
	DaysAPI_AddDay("catch");
	DaysAPI_SetDayInfo("catch", DayInfo_DisplayName, "Freeze Tag");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "CustomPlayerSkins"))
		gp_bCustomPlayerSkins = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "CustomPlayerSkins"))
		gp_bCustomPlayerSkins = true;
}

// Initialize Plugin
public void OnConfigsExecuted()
{
	g_iFreezeTime = gc_iFreezeTime.IntValue;
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay("catch");
}

/******************************************************************************
                   EVENTS
******************************************************************************/

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsCatch)
	{
		return;
	}

	CheckStatus();

	int client = GetClientOfUserId(event.GetInt("userid"));

	g_bCatched[client] = false,
	ResetSprint(client);
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_bIsCatch = false;

	if (gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundFreezePath);
		PrecacheSoundAnyDownload(g_sSoundUnFreezePath);
	}

	if (gc_bOverlays.BoolValue)
	{
		PrecacheDecalAnyDownload(g_sOverlayFreeze);
	}

	PrecacheSound("player/suit_sprint.wav", true);
}

// Map End
public void OnMapEnd()
{
	g_bIsCatch = false;

	delete g_hTimerFreeze;
	delete g_hTimerBeacon;
}

public void Event_OnRoundEnd(Event event, char[] szEventName, bool bDontBroadcast)
{
	if(g_bIsCatch)
	{
		//DaysAPI_EndDay("catch");
	}
}

// Terror win Round if time runs out
public Action CS_OnTerminateRound(float &delay,  CSRoundEndReason &reason)
{
	if (g_bIsCatch)   // TODO: does this trigger??
	{
		if (reason == CSRoundEnd_Draw)
		{
			reason = CSRoundEnd_TerroristWin;
			return Plugin_Changed;
		}

		return Plugin_Continue;
	}

	return Plugin_Continue;
}

// Catch & Freeze
public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!g_bIsCatch)
	{
		return Plugin_Continue;
	}

	if (!IsValidClient(victim, true, false) || attacker == victim || !IsValidClient(attacker, true, false))
	{
		return Plugin_Continue;
	}

	if (GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT && !g_bCatched[victim])
	{
		if (gc_iCatchCount.IntValue != 0 && g_iCatchCounter[victim] >= gc_iCatchCount.IntValue)
		{
			ForcePlayerSuicide(victim);
		}
		else
		{
			CatchEm(victim, attacker);
		}

		CheckStatus();
	}
	else if (GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_T && g_bCatched[victim] && !g_bCatched[attacker])
	{
		FreeEm(victim, attacker);
		CheckStatus();
	}

	return Plugin_Handled;
}

public void OnClientDisconnect_Post(int client)
{
	if (!g_bIsCatch)
	{
		return;
	}

	CheckStatus();
}

// Set Client Hook
public void OnClientPutInServer(int client)
{
	g_bCatched[client] = false;

	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

// Knife only
public Action OnWeaponCanUse(int client, int weapon)
{
	if (!g_bIsCatch)
	{
		return Plugin_Continue;
	}

	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "weapon_knife") && IsValidClient(client, true, false))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void DaysAPI_OnDayEnd_Pre(char[] szDay, any data)
{
	if (!StrEqual(szDay, "catch"))
	{
		return;
	}
	
	bool bNotCatched = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
			
		if(GetClientTeam(i) != CS_TEAM_T)
		{
			continue;
		}
		
		if(!g_bCatched[i])
		{
			bNotCatched = true;
			break;
		}
	}
	
	DaysAPI_ResetDayWinners();
	int iWinners[MAXPLAYERS], iCount;
	if(bNotCatched)
	{
		iCount = GetPlayers(iWinners, _, GP_Team_First);
		DaysAPI_SetDayWinners("terrorist_survive", iWinners, iCount);
	}
	
	else
	{
		iCount = GetPlayers(iWinners, _, GP_Team_Second);
		DaysAPI_SetDayWinners("ct_survive", iWinners, iCount);
	}
}

public void DaysAPI_OnDayEnd(char[] szDay, any data)
{
	if (!StrEqual(szDay, "catch"))
	{
		return;
	}
	
	ResetEventDay();
}

public void DaysAPI_OnDayStart(char[] szDay, bool bWasPlanned, any data)
{
	if (!StrEqual(szDay, "catch"))
	{
		return;
	}
	
	StartEventRound();
}

void ResetEventDay()
{
	for (int i = 1; i <= MaxClients; i++)
	{	
		if (IsValidClient(i, false, true))
		{
			g_iSprintStatus[i] = 0;
			g_bCatched[i] = false;
	
			SetEntData(i, g_iCollision_Offset, 0, 4, true);
	
			CreateTimer(0.0, DeleteOverlay, GetClientUserId(i));
	
			SetEntityRenderColor(i, 255, 255, 255, 0);
			SetEntityHealth(i, 100);
	
			StripAllPlayerWeapons(i);
	
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				FakeClientCommand(i, "sm_weapons");
			}
	
			GivePlayerItem(i, "weapon_knife");
	
			if (gc_bWallhack.BoolValue && gp_bCustomPlayerSkins)
			{
				UnhookWallhack(i);
			}
	
			SetEntityMoveType(i, MOVETYPE_WALK);
	
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		}
	}

	delete g_hTimerFreeze;
	delete g_hTimerBeacon;

	g_bIsCatch = false;

	CPrintToChatAll("%t %t", "catch_tag", "catch_end");
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

// Prepare Event
void StartEventRound()
{
		g_bIsCatch = true;

		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, false))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);

			SetEntityMoveType(i, MOVETYPE_NONE);
		}

		CreateTimer(3.0, Timer_PrepareEvent);

		CPrintToChatAll("%t %t", "catch_tag", "catch_now");
		PrintCenterTextAll("%t", "catch_now_nc");
}

public Action Timer_PrepareEvent(Handle timer)
{
	if (!g_bIsCatch)
		return Plugin_Handled;

	PrepareDay();

	return Plugin_Handled;
}

void PrepareDay()
{
	/*
	if ((thisround && gc_bTeleportSpawn.BoolValue) || !gp_bSmartJailDoors ) // spawn Terrors to CT Spawn 
	{
		int RandomCT = 0;
		int RandomT = 0;

		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, false))
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

			for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
			{
				if (!gp_bSmartJailDoors || (SJD_IsCurrentMapConfigured() != true))
				{
					TeleportEntity(i, g_fPosCT, NULL_VECTOR, NULL_VECTOR);
				}
				else if (GetClientTeam(i) == CS_TEAM_T)
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

	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		SetEntData(i, g_iCollision_Offset, 2, 4, true);

		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);

		SetEntityMoveType(i, MOVETYPE_NONE);

		//CreateInfoPanel(i);

		StripAllPlayerWeapons(i);

		GivePlayerItem(i, "weapon_knife");

		g_iSprintStatus[i] = 0;
		g_iCatchCounter[i] = 0;
		g_bCatched[i] = false;
	}

	if (gc_fBeaconTime.FloatValue > 0.0)
	{
		g_hTimerBeacon = CreateTimer(gc_fBeaconTime.FloatValue, Timer_BeaconOn, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	//GameRules_SetProp("m_iRoundTime", gc_iRoundTime.IntValue*60, 4, 0, true);

	g_hTimerFreeze = CreateTimer(1.0, Timer_StartEvent, _, TIMER_REPEAT);
}

void CatchEm(int client, int attacker)
{
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	SetEntityRenderColor(client, 0, 0, 205, 255);

	g_bCatched[client] = true;
	g_iCatchCounter[client] += 1;

	ShowOverlay(client, g_sOverlayFreeze, 0.0);

	if (gc_bSounds.BoolValue)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) EmitSoundToAllAny(g_sSoundFreezePath);
	}

	if (!gc_bStayOverlay.BoolValue)
	{
		CreateTimer(3.0, DeleteOverlay, GetClientUserId(client));
	}

	CPrintToChatAll("%t %t", "catch_tag", "catch_catch", attacker, client);
}


void FreeEm(int client, int attacker)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityRenderColor(client, 255, 255, 255, 0);

	g_bCatched[client] = false;

	CreateTimer(0.0, DeleteOverlay, GetClientUserId(client));

	if (gc_bSounds.BoolValue)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) EmitSoundToAllAny(g_sSoundUnFreezePath);
	}

	CPrintToChatAll("%t %t", "catch_tag", "catch_unfreeze", attacker, client);
}


bool CheckStatus()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		if (IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T && !g_bCatched[i])
		{
			count++;
		}
	}

	if (count == 0)
	{
		CPrintToChatAll("%t %t", "catch_tag", "catch_win");
		
		DaysAPI_EndDay("catch");
		CS_TerminateRound(5.0, CSRoundEnd_CTWin);
		return true;
	}
	
	return false;
}


// Perpare client for wallhack
void Setup_WallhackSkin(int client)
{
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));

	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	if (iSkin == -1)
	{
		return;
	}

	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_Wallhack))
	{
		Setup_Wallhack(iSkin);
	}
}


// set client wallhacked
void Setup_Wallhack(int iSkin)
{
	int iOffset;

	if ((iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
		return;

	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);

	int iRed = 60;
	int iGreen = 60;
	int iBlue = 200;

	SetEntData(iSkin, iOffset, iRed, _, true);
	SetEntData(iSkin, iOffset + 1, iGreen, _, true);
	SetEntData(iSkin, iOffset + 2, iBlue, _, true);
	SetEntData(iSkin, iOffset + 3, 255, _, true);
}

// Who can see wallhack if vaild
public Action OnSetTransmit_Wallhack(int iSkin, int client)
{
	if (!IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_CT)
	{
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		if (!CPS_HasSkin(i) || !g_bCatched[i])
		{
			continue;
		}

		if (EntRefToEntIndex(CPS_GetSkin(i)) != iSkin)
		{
			continue;
		}

		return Plugin_Continue;
	}

	return Plugin_Handled;
}


// remove wallhack
void UnhookWallhack(int client)
{
	if (IsValidClient(client, false, true))
	{
		int iSkin = CPS_GetSkin(client);
		if (iSkin != INVALID_ENT_REFERENCE)
		{
			SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", false, true);
			SDKUnhook(iSkin, SDKHook_SetTransmit, OnSetTransmit_Wallhack);
		}
	}
}


/******************************************************************************
                   TIMER
******************************************************************************/

// Start Timer
public Action Timer_StartEvent(Handle timer)
{
	if (g_iFreezeTime > 0)
	{
		g_iFreezeTime--;
		
		if (g_iFreezeTime == gc_iFreezeTime.IntValue-3)
		{
			for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, false))
			{
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					SetEntityMoveType(i, MOVETYPE_WALK);
				}
			}
		}

		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, false))
		{
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				PrintCenterText(i, "%t", "catch_timetounfreeze_nc", g_iFreezeTime);
			}
			else if (GetClientTeam(i) == CS_TEAM_T)
			{
				PrintCenterText(i, "%t", "catch_timeuntilstart_nc", g_iFreezeTime);
			}
		}

		return Plugin_Continue;
	}

	for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, false))
	{
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			SetEntityMoveType(i, MOVETYPE_WALK);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.4);
		}

		if (gc_bOverlays.BoolValue)
		{
			ShowOverlay(i, g_sOverlayStartPath, 2.0);
		}

		if (gc_bWallhack.BoolValue && gp_bCustomPlayerSkins)
		{
			Setup_WallhackSkin(i);
		}
	}

	if (gc_bSounds.BoolValue)
	{
		EmitSoundToAllAny(g_sSoundStartPath);
	}

	PrintCenterTextAll("%t", "catch_start_nc");

	CPrintToChatAll("%t %t", "catch_tag", "catch_start");

	g_hTimerFreeze = null;

	return Plugin_Stop;
}

// Beacon Timer
public Action Timer_BeaconOn(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, false))
	{
		MyJailbreak_BeaconOn(i, 2.0);
	}

	g_hTimerBeacon = null;
}

/******************************************************************************
                   MENUS
******************************************************************************/

stock void CreateInfoPanel(int client)
{
	// Create info Panel
	char info[255];

	Panel InfoPanel = new Panel();

	Format(info, sizeof(info), "%T", "catch_info_title", client);
	InfoPanel.SetTitle(info);

	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "catch_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "catch_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "catch_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "catch_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "catch_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "catch_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "catch_info_line7", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");

	Format(info, sizeof(info), "%T", "warden_close", client);
	InfoPanel.DrawItem(info);

	InfoPanel.Send(client, Handler_NullCancel, 20);
}

/******************************************************************************
                   SPRINT MODULE
******************************************************************************/

// Sprint
public Action Command_StartSprint(int client, int args)
{
	if (!g_bIsCatch)
	{
		CReplyToCommand(client, "%t %t", "catch_tag", "catch_disabled");
		return Plugin_Handled;
	}

	if (!gc_bSprint.BoolValue || GetClientTeam(client) != CS_TEAM_T || g_bCatched[client])
	{
		return Plugin_Handled;
	}

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1 && !(g_iSprintStatus[client] & IsSprintUsing) && !(g_iSprintStatus[client] & IsSprintCoolDown))
	{
		g_iSprintStatus[client] |= IsSprintUsing | IsSprintCoolDown;

		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", gc_fSprintSpeed.FloatValue);
		EmitSoundToClient(client, "player/suit_sprint.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);

		CReplyToCommand(client, "%t %t", "catch_tag", "catch_sprint");

		g_hTimerSprint[client] = CreateTimer(gc_fSprintTime.FloatValue, Timer_SprintEnd, client);
	}

	return Plugin_Handled;
}

public void OnGameFrame()
{
	if (!g_bIsCatch || !gc_bSprintUse.BoolValue)
	{
		return;
	}

	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		if (GetClientButtons(i) & IN_USE)
		{
			Command_StartSprint(i, 0);
		}
	}
}

void ResetSprint(int client)
{
	if (g_hTimerSprint[client] != null)
	{
		KillTimer(g_hTimerSprint[client]);
		g_hTimerSprint[client] = null;
	}

	if (GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") != 1)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}

	if (g_iSprintStatus[client] & IsSprintUsing)
	{
		g_iSprintStatus[client] &= ~ IsSprintUsing;
	}
}

public Action Timer_SprintEnd(Handle timer, any client)
{
	g_hTimerSprint[client] = null;

	if (IsClientInGame(client) && (g_iSprintStatus[client] & IsSprintUsing))
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		g_iSprintStatus[client] &= ~ IsSprintUsing;

		if (IsPlayerAlive(client) && GetClientTeam(client) > 1)
		{
			g_hTimerSprint[client] = CreateTimer(gc_iSprintCooldown.FloatValue, Timer_SprintCooldown, client);
			CPrintToChat(client, "%t %t", "catch_tag", "catch_sprintend", gc_iSprintCooldown.IntValue);
		}
	}

	return Plugin_Handled;
}

public Action Timer_SprintCooldown(Handle timer, any client)
{
	g_hTimerSprint[client] = null;

	if (IsClientInGame(client) && (g_iSprintStatus[client] & IsSprintCoolDown))
	{
		g_iSprintStatus[client] &= ~ IsSprintCoolDown;
		CPrintToChat(client, "%t %t", "catch_tag", "catch_sprintagain", gc_iSprintCooldown.IntValue);
	}

	return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	ResetSprint(client);
	g_iSprintStatus[client] &= ~ IsSprintCoolDown;
}