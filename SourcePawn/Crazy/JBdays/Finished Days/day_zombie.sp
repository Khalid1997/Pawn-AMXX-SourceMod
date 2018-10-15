/*
 * MyJailbreak - Zombie Event Day Plugin.
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
#include <smartdm>
#include <daysapi>
#include <myjailbreak_e>

// Optional Plugins
#undef REQUIRE_PLUGIN
#include <CustomPlayerSkins>
#define REQUIRE_PLUGIN

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

#define RESERVE_AMMO_COUNT	200

// Booleans
bool g_bIsZombie = false;

// Plugin bools
bool gp_bCustomPlayerSkins;

bool g_bTerrorZombies[MAXPLAYERS + 1];

// Console Variables
ConVar gc_fBeaconTime;
ConVar gc_iFreezeTime;
ConVar gc_bSpawnCell;
ConVar gc_bAmmo;
ConVar gc_iZombieHP;
ConVar gc_iZombieHPincrease;
ConVar gc_iHumanHP;
ConVar gc_bDark;
ConVar gc_bVision;
ConVar gc_bGlow;
ConVar gc_iGlowMode;
ConVar gc_sModelPathZombie;
ConVar gc_bSounds;
ConVar gc_sSoundStartPath;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;
ConVar gc_fKnockbackAmount;
ConVar gc_iRegen;
ConVar gc_bTerrorZombie;
ConVar gc_bTerrorInfect;

// Extern Convars
ConVar g_sOldSkyName;

// Integers
int g_iFreezeTime;
int g_iCollision_Offset;

// Handles
Handle g_hTimerFreeze;
Handle g_hTimerBeacon;
Handle g_hTimerRegen;

// floats
float g_fPos[3];

// Strings
char g_sModelPathZombie[256];
char g_sSoundStartPath[256];
char g_sSkyName[256];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sModelPathPrevious[MAXPLAYERS + 1][256];
char g_sOverlayStartPath[256];

// Info
public Plugin myinfo =  {
	name = "MyJailbreak - Zombie", 
	author = "shanapu", 
	description = "Event Day for Jailbreak Server", 
	version = MYJB_VERSION, 
	url = MYJB_URL_LINK
};

// Start
public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.Zombie.phrases");
	
	// Client Commands
	
	// AutoExecConfig
	AutoExecConfig_SetFile("Zombie", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_zombie_version", MYJB_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	gc_bSpawnCell = AutoExecConfig_CreateConVar("sm_zombie_spawn", "0", "0 - T teleport to CT spawn, 1 - cell doors auto open", _, true, 0.0, true, 1.0);
	gc_bAmmo = AutoExecConfig_CreateConVar("sm_zombie_ammo", "0", "0 - disabled, 1 - enable infinty ammo (with reload) for humans", _, true, 0.0, true, 1.0);
	gc_fBeaconTime = AutoExecConfig_CreateConVar("sm_zombie_beacon_time", "240", "Time in seconds until the beacon turned on (set to 0 to disable)", _, true, 0.0);
	gc_iFreezeTime = AutoExecConfig_CreateConVar("sm_zombie_freezetime", "35", "Time in seconds the zombies freezed", _, true, 0.0);
	gc_iZombieHP = AutoExecConfig_CreateConVar("sm_zombie_zombie_hp", "4000", "HP the Zombies got on Spawn", _, true, 1.0);
	gc_iZombieHPincrease = AutoExecConfig_CreateConVar("sm_zombie_zombie_hp_extra", "1000", "HP the Zombies get additional per extra Human", _, true, 1.0);
	gc_iHumanHP = AutoExecConfig_CreateConVar("sm_zombie_human_hp", "65", "HP the Humans got on Spawn", _, true, 1.0);
	gc_iRegen = AutoExecConfig_CreateConVar("sm_zombie_zombie_regen", "5", "0 - disabled, HPs a Zombie regenerates every 5 seconds", _, true, 0.0);
	gc_bDark = AutoExecConfig_CreateConVar("sm_zombie_dark", "1", "0 - disabled, 1 - enable Map Darkness", _, true, 0.0, true, 1.0);
	gc_bGlow = AutoExecConfig_CreateConVar("sm_zombie_glow", "1", "0 - disabled, 1 - enable Glow effect for humans", _, true, 0.0, true, 1.0);
	gc_iGlowMode = AutoExecConfig_CreateConVar("sm_zombie_glow_mode", "1", "1 - human contours with wallhack for zombies, 2 - human glow effect without wallhack for zombies", _, true, 1.0, true, 2.0);
	gc_bVision = AutoExecConfig_CreateConVar("sm_zombie_vision", "1", "0 - disabled, 1 - enable NightVision View for Zombies", _, true, 0.0, true, 1.0);
	gc_fKnockbackAmount = AutoExecConfig_CreateConVar("sm_zombie_knockback", "20.0", "Force of the knockback when shot at. Zombies only", _, true, 1.0, true, 100.0);
	gc_bTerrorZombie = AutoExecConfig_CreateConVar("sm_zombie_terror", "0", "0 - disabled, 1 - transform terrors into Zombie on death - experimental!", _, true, 0.0, true, 1.0);
	gc_bTerrorInfect = AutoExecConfig_CreateConVar("sm_zombie_terror_infect", "0", "0 - all dead terrors become zombie, 1 - only terrors killed by zombie transform into Zombie", _, true, 0.0, true, 1.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_zombie_sounds_enable", "1", "0 - disabled, 1 - enable sounds", _, true, 0.0, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_zombie_sounds_start", "music/MyJailbreak/zombie.mp3", "Path to the soundfile which should be played for a start.");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_zombie_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_zombie_overlays_start", "overlays/MyJailbreak/zombie", "Path to the start Overlay DONT TYPE .vmt or .vft");
	gc_sModelPathZombie = AutoExecConfig_CreateConVar("sm_zombie_model", "models/player/custom_player/zombie/revenant/revenant_v2.mdl", "Path to the model for zombies.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	// Hooks
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sModelPathZombie, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	
	// FindConVar
	gc_sOverlayStartPath.GetString(g_sOverlayStartPath, sizeof(g_sOverlayStartPath));
	gc_sModelPathZombie.GetString(g_sModelPathZombie, sizeof(g_sModelPathZombie));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	
	// Offsets
	g_iCollision_Offset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	// Logs
	SetLogFile(g_sEventsLogFile, "Events", "MyJailbreak");
}

// ConVarChange for Strings
public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sModelPathZombie)
	{
		strcopy(g_sModelPathZombie, sizeof(g_sModelPathZombie), newValue);
		Downloader_AddFileToDownloadsTable(g_sModelPathZombie);
		PrecacheModel(g_sModelPathZombie);
	}
	else if (convar == gc_sOverlayStartPath)
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
	gp_bCustomPlayerSkins = LibraryExists("CustomPlayerSkins");
	
	DaysAPI_AddDay("zombie");
	DaysAPI_SetDayInfo("zombie", DayInfo_DisplayName, "Zombie");
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
	DaysAPI_RemoveDay("zombie");
}

/******************************************************************************
                   EVENTS
******************************************************************************/

public void DaysAPI_OnDayEnd_Pre(char[] szIntName)
{
	if(!StrEqual(szIntName, "zombie"))
	{
		return;
	}
	
	int iWinnerTeam = CS_TEAM_NONE;
	int iWinners[MAXPLAYERS], iCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		if(!IsPlayerAlive(i))
		{
			continue;
		}
		
		if(iWinnerTeam == CS_TEAM_NONE)
		{
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
		CPrintToChatAll("\x04* team \x03'%s' \x04won the \x04day.", iWinnerTeam == CS_TEAM_CT ? "Zombies" : "Survivors");
		DaysAPI_SetDayWinners(iWinnerTeam == CS_TEAM_CT ? "winner_zombie" : "winner_survivor", iWinners, iCount);
	}
}

public void DaysAPI_OnDayEnd(char[] szIntName)
{
	if(StrEqual(szIntName, "zombie"))
	{
		ResetEventDay();
	}
}

void ResetEventDay()
{
	UnhookEvent("weapon_fire", Event_WeaponFire);
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, true))
	{
		SetEntData(i, g_iCollision_Offset, 0, 4, true);
		SetEntProp(i, Prop_Send, "m_bNightVisionOn", 0);
		
		if (gp_bCustomPlayerSkins && gc_bGlow.BoolValue)
		{
			UnhookGlow(i);
		}
		
		if (g_bTerrorZombies[i])
		{
			ChangeClientTeam(i, CS_TEAM_T);
		}
	}
	
	delete g_hTimerFreeze;
	delete g_hTimerBeacon;
	delete g_hTimerRegen;
	
	g_bIsZombie = false;
	
	SetCvarString("sv_skyname", g_sSkyName);
	SetCvar("sv_infinite_ammo", 0);
	
	MyJailbreak_FogOff();
	CPrintToChatAll("%t %t", "zombie_tag", "zombie_end");
}

public void Event_WeaponFire(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client)
	{
		return;
	}
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (weapon < 0 || (weapon != GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) && weapon != GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)))
	{
		return;
	}

	if (GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount") != RESERVE_AMMO_COUNT)
	{
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", RESERVE_AMMO_COUNT);
	}
}

public Action Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!g_bIsZombie || !IsValidClient(attacker) || GetClientTeam(victim) == CS_TEAM_T)
		return;
	
	int damage = GetEventInt(event, "dmg_health");
	
	float knockback = gc_fKnockbackAmount.FloatValue; // knockback amount
	float clientloc[3];
	float attackerloc[3];
	
	GetClientAbsOrigin(victim, clientloc);
	
	// Get attackers eye position.
	GetClientEyePosition(attacker, attackerloc);
	
	// Get attackers eye angles.
	float attackerang[3];
	GetClientEyeAngles(attacker, attackerang);
	
	// Calculate knockback end-vector.
	TR_TraceRayFilter(attackerloc, attackerang, MASK_ALL, RayType_Infinite, KnockbackTRFilter);
	TR_GetEndPosition(clientloc);
	
	// Apply damage knockback multiplier.
	knockback *= damage;
	
	if (GetEntPropEnt(victim, Prop_Send, "m_hGroundEntity") == -1)knockback *= 0.5;
	
	// Apply knockback.
	KnockbackSetVelocity(victim, attackerloc, clientloc, knockback);
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!g_bIsZombie || !gc_bTerrorZombie.BoolValue || (gc_bTerrorInfect.BoolValue && !IsValidClient(attacker, true, false)))
		return;
	
	if (GetClientTeam(victim) == CS_TEAM_CT || GetAlivePlayersCount(CS_TEAM_T) <= 1)
		return;
	
	g_bTerrorZombies[victim] = true;
	
	CreateTimer(4.0, Timer_MakeZombie, victim, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_MakeZombie(Handle hTimer, any client)
{
	if (IsValidClient(client, true, true))
	{
		ChangeClientTeam(client, CS_TEAM_CT);
		CS_RespawnPlayer(client);
		
		int zombieHP = gc_iZombieHP.IntValue;
		int difference = (GetAlivePlayersCount(CS_TEAM_T) - GetAlivePlayersCount(CS_TEAM_CT));
		if (difference > 0)
		{
			zombieHP = zombieHP + (gc_iZombieHPincrease.IntValue * difference);
		}
		
		SetEntityHealth(client, zombieHP);
		
		StripAllPlayerWeapons(client);
		GivePlayerItem(client, "weapon_knife");
		
		if (gc_bVision.BoolValue)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
		}
		
		if (gc_bOverlays.BoolValue)
		{
			ShowOverlay(client, g_sOverlayStartPath, 2.0);
		}
		
		if (gc_bSounds.BoolValue)
		{
			EmitSoundToClientAny(client, g_sSoundStartPath);
		}
		
		CreateTimer(0.1, Timer_SetModel, client);
	}
	
	return Plugin_Stop;
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_bIsZombie = false;
	
	g_iFreezeTime = gc_iFreezeTime.IntValue;
	g_sOldSkyName = FindConVar("sv_skyname");
	g_sOldSkyName.GetString(g_sSkyName, sizeof(g_sSkyName));
	
	if (gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundStartPath); // Add sound to download and precache table
	}
	
	if (gc_bOverlays.BoolValue)
	{
		PrecacheDecalAnyDownload(g_sOverlayStartPath); // Add overlay to download and precache table
	}
	
	Downloader_AddFileToDownloadsTable(g_sModelPathZombie);
	PrecacheModel(g_sModelPathZombie);
}

// Map End
public void OnMapEnd()
{
	g_bIsZombie = false;
	
	delete g_hTimerFreeze;
	delete g_hTimerBeacon;
	delete g_hTimerRegen;
}

public void DaysAPI_OnDayStart(char[] szIntName)
{
	if(StrEqual(szIntName, "zombie"))
	{
		StartEventRound();
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

// Knife only for Zombies
public Action OnWeaponCanUse(int client, int weapon)
{
	if (!g_bIsZombie)
	{
		return Plugin_Continue;
	}
	
	if (GetClientTeam(client) != CS_TEAM_CT)
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

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

// Prepare Event
void StartEventRound()
{
	g_bIsZombie = true;
		
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			
		SetEntityMoveType(i, MOVETYPE_NONE);
	}
		
	CreateTimer(3.0, Timer_PrepareEvent);
		
	CPrintToChatAll("%t %t", "zombie_tag", "zombie_now");
	PrintCenterTextAll("%t", "zombie_now_nc");
}

public Action Timer_PrepareEvent(Handle timer)
{
	if (!g_bIsZombie)
		return Plugin_Handled;
	
	PrepareDay();
	
	return Plugin_Handled;
}

void PrepareDay()
{
	HookEvent("weapon_fire", Event_WeaponFire);
	
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
	
	int zombieHP = gc_iZombieHP.IntValue;
	int difference = (GetAlivePlayersCount(CS_TEAM_T) - GetAlivePlayersCount(CS_TEAM_CT));
	if (difference > 0)
	{
		zombieHP = zombieHP + (gc_iZombieHPincrease.IntValue * difference);
	}
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		SetEntData(i, g_iCollision_Offset, 2, 4, true);
		
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityMoveType(i, MOVETYPE_NONE);
		
		//CreateInfoPanel(i);
		
		StripAllPlayerWeapons(i);
		
		g_bTerrorZombies[i] = false;
		
		GivePlayerItem(i, "weapon_knife");
		
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			SetEntityHealth(i, zombieHP);
			
			CreateTimer(1.1, Timer_SetModel, i);
			
			DarkenScreen(i, true);
		}
		else if (GetClientTeam(i) == CS_TEAM_T)
		{
			SetEntityHealth(i, gc_iHumanHP.IntValue);
			
			GivePlayerItem(i, "weapon_negev");
		}
	}
	
	if (gc_fBeaconTime.FloatValue > 0.0)
	{
		g_hTimerBeacon = CreateTimer(gc_fBeaconTime.FloatValue, Timer_BeaconOn, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (gc_bAmmo.BoolValue)
	{
		SetCvar("sv_infinite_ammo", 2);
	}
	
	SetCvarString("sv_skyname", "cs_baggage_skybox_");
	g_hTimerFreeze = CreateTimer(1.0, Timer_StartEvent, _, TIMER_REPEAT);
}

// Perpare client for glow
void SetupGlowSkin(int client)
{
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));
	
	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	if (iSkin == -1)
	{
		return;
	}
	
	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin))
	{
		GlowSkin(iSkin);
	}
}

// set client glow
void GlowSkin(int iSkin)
{
	int iOffset;
	
	if ((iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
		return;
	
	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", true, true);
	if (gc_iGlowMode.IntValue == 1)SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	if (gc_iGlowMode.IntValue == 2)SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	int iRed = 155;
	int iGreen = 0;
	int iBlue = 10;
	
	SetEntData(iSkin, iOffset, iRed, _, true);
	SetEntData(iSkin, iOffset + 1, iGreen, _, true);
	SetEntData(iSkin, iOffset + 2, iBlue, _, true);
	SetEntData(iSkin, iOffset + 3, 255, _, true);
}

// Who can see the glow if vaild
public Action OnSetTransmit_GlowSkin(int iSkin, int client)
{
	if (!IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_CT)
		return Plugin_Handled;
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		if (!CPS_HasSkin(i))
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

// remove glow
void UnhookGlow(int client)
{
	if (IsValidClient(client, false, true))
	{
		int iSkin = CPS_GetSkin(client);
		if (iSkin != INVALID_ENT_REFERENCE)
		{
			SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", false, true);
			SDKUnhook(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin);
		}
	}
}

void KnockbackSetVelocity(int client, const float startpoint[3], const float endpoint[3], float magnitude)
{
	// Create vector from the given starting and ending points.
	float vector[3];
	MakeVectorFromPoints(startpoint, endpoint, vector);
	
	// Normalize the vector (equal magnitude at varying distances).
	NormalizeVector(vector, vector);
	
	// Apply the magnitude by scaling the vector (multiplying each of its components).
	ScaleVector(vector, magnitude);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
}

public bool KnockbackTRFilter(int entity, int contentsMask)
{
	// If entity is a player, continue tracing.
	if (entity > 0 && entity < MAXPLAYERS)
	{
		return false;
	}
	
	// Allow hit.
	return true;
}

/******************************************************************************
                   MENUS
******************************************************************************/

stock void CreateInfoPanel(int client)
{
	// Create info Panel
	char info[255];
	
	Panel InfoPanel = new Panel();
	
	Format(info, sizeof(info), "%T", "zombie_info_title", client);
	InfoPanel.SetTitle(info);
	
	InfoPanel.DrawText("                                   ");
	Format(info, sizeof(info), "%T", "zombie_info_line1", client);
	InfoPanel.DrawText(info);
	InfoPanel.DrawText("-----------------------------------");
	Format(info, sizeof(info), "%T", "zombie_info_line2", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "zombie_info_line3", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "zombie_info_line4", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "zombie_info_line5", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "zombie_info_line6", client);
	InfoPanel.DrawText(info);
	Format(info, sizeof(info), "%T", "zombie_info_line7", client);
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
	if (g_iFreezeTime > 0)
	{
		g_iFreezeTime--;
		
		if (g_iFreezeTime == gc_iFreezeTime.IntValue - 3)
		{
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
			{
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					SetEntityMoveType(i, MOVETYPE_WALK);
				}
			}
		}
		
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
		{
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				PrintCenterText(i, "%t", "zombie_timetounfreeze_nc", g_iFreezeTime);
			}
			else if (GetClientTeam(i) == CS_TEAM_T)
			{
				PrintCenterText(i, "%t", "zombie_timeuntilzombie_nc", g_iFreezeTime);
			}
		}
		
		return Plugin_Continue;
	}
	
	g_iFreezeTime = gc_iFreezeTime.IntValue;
	
	
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			SetEntityMoveType(i, MOVETYPE_WALK);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.4);
			DarkenScreen(i, false);
			
			if (gc_bVision.BoolValue)
			{
				SetEntProp(i, Prop_Send, "m_bNightVisionOn", 1);
			}
		}
		
		if (gp_bCustomPlayerSkins && gc_bGlow.BoolValue && (IsValidClient(i, true, true)) && (GetClientTeam(i) == CS_TEAM_T))
		{
			SetupGlowSkin(i);
		}
		
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
	
	if (gc_bDark.BoolValue)
	{
		MyJailbreak_FogOn();
	}
	
	if (gc_iRegen.IntValue != 0)
	{
		g_hTimerRegen = CreateTimer(5.0, Timer_ReGenHealth, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	PrintCenterTextAll("%t", "zombie_start_nc");
	
	CPrintToChatAll("%t %t", "zombie_tag", "zombie_start");
	
	g_hTimerFreeze = null;
	
	return Plugin_Stop;
}

// Delay Set model for sm_skinchooser
public Action Timer_SetModel(Handle timer, int client)
{
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		GetEntPropString(client, Prop_Data, "m_ModelName", g_sModelPathPrevious[client], sizeof(g_sModelPathPrevious[]));
		SetEntityModel(client, g_sModelPathZombie);
	}
}

public Action Timer_BeaconOn(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		MyJailbreak_BeaconOn(i, 2.0);
	}
	
	g_hTimerBeacon = null;
}

public Action Timer_ReGenHealth(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true, false))
	{
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			SetEntityHealth(i, GetClientHealth(i) + gc_iRegen.IntValue);
		}
	}
} 