 //                          ==========================================================================
//	                    |     Plugin By Tair Azoulay                                             |
//                          |                                                                        |
//                          |     Profile : http://steamcommunity.com/profiles/76561198013150925/    |                                         |
//                          |                                                                        |
//	                    |     Name : Grenades On Spawn                                           |
//                          |                                                                        |
//	                    |     Version : 1.0                                                      |
//                          |                                                                        |
//	                    |     Description : Flash + Smoke + HeGrenade on spawn (+ Molotov in csgo)|                       |     
//                          ==========================================================================

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

ConVar gs_Cvar_hegrenade 
ConVar gs_Cvar_flashbang
ConVar gs_Cvar_smoke
ConVar gs_Cvar_molotov

public Plugin myinfo = 
{
	name = "Grenades On Spawn", 
	author = "Tair", 
	description = "Gives Grenades On Spawn (Flash , Smoke , HeGrenade ,Molotov)", 
	version = "1.1", 
	url = "Www.sourcemod.net"
}

int g_iMolotov, g_iHeGrenade, g_iFlashbang, g_iSmoke;

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);

	gs_Cvar_molotov = CreateConVar("sm_gs_molotov", "1", "Enables or Disables Molotov");
	gs_Cvar_hegrenade = CreateConVar("sm_gs_hegrenade", "1", "Enables or Disables HeGrenade");
	gs_Cvar_flashbang = CreateConVar("sm_gs_flashbang", "1", "Enables or Disables Flashbang");
	gs_Cvar_smoke = CreateConVar("sm_gs_smoke", "0", "Enables or Disables Smoke Grenade");
	
	HookConVarChange(gs_Cvar_molotov, OnConVarChanged);
	HookConVarChange(gs_Cvar_hegrenade, OnConVarChanged);
	HookConVarChange(gs_Cvar_flashbang, OnConVarChanged);
	HookConVarChange(gs_Cvar_smoke, OnConVarChanged);
	
	g_iMolotov = gs_Cvar_molotov.IntValue;
	g_iHeGrenade = gs_Cvar_hegrenade.IntValue;
	g_iFlashbang = gs_Cvar_flashbang.IntValue;
	g_iSmoke = gs_Cvar_smoke.IntValue;
}

public void OnConVarChanged(ConVar convar, char[] szNewValue, char[] szOldValue)
{
	if(convar == gs_Cvar_molotov)
	{
		g_iMolotov = StringToInt(szNewValue);
	}
	
	else if (convar == gs_Cvar_hegrenade)
	{
		g_iHeGrenade = StringToInt(szNewValue);
	}
	
	else if (convar == gs_Cvar_flashbang)
	{
		g_iFlashbang = StringToInt(szNewValue);
	}
	
	else if (convar == gs_Cvar_smoke)
	{
		g_iSmoke = StringToInt(szNewValue);
	}
}

public Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	RequestFrame(Frame_GiveNames, GetEventInt(event, "userid"));
}

public void Frame_GiveNames(int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	
	if(!client)
	{
		return;
	}
	
	int iGiven;
	
	iGiven = 0;
	
	int iTeam = GetClientTeam(client);
	if(iTeam == CS_TEAM_CT)
	{
		while(iGiven++ < g_iMolotov)
		{
			GivePlayerItem(client, "weapon_incgrenade");
		}
	}
	
	else if(iTeam == CS_TEAM_T)
	{
		while(iGiven++ < g_iMolotov)
		{
			GivePlayerItem(client, "weapon_molotov");
		}
	}
	
	iGiven = 0;
	while(iGiven++ < g_iHeGrenade)
	{
		GivePlayerItem(client, "weapon_hegrenade");
	}
	
	iGiven = 0;
	while(iGiven++ < g_iFlashbang)
	{
		GivePlayerItem(client, "weapon_flashbang");
	}
	
	iGiven = 0;
	while(iGiven++ < g_iSmoke)
	{
		GivePlayerItem(client, "weapon_smokegrenade");
	}
}
