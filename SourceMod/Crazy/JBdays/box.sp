#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <simonapi>
#include <cstrike>
#include <daysapi>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "SimonAPI: Box",
	author = PLUGIN_AUTHOR,
	description = "!box command",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar ConVar_TeammatesAreEnemies;
bool g_bBoxEnabled = false;

#define IsBoxEnabled() 	(g_bBoxEnabled == true)
bool g_bLate = false;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int ErrMax)
{
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar_TeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	ConVar_TeammatesAreEnemies.AddChangeHook(ConVar_OnChanged);
	//g_bTeammatesAreEnemies = ConVar_TeammatesAreEnemies.BoolValue;
	
	HookEvent("round_start", Event_RoundStart);
	
	RegConsoleCmd("sm_box", ConCommand_Box);
	
	if(g_bLate)
	{
		g_bLate = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, SDKCallback_TraceAttack);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, SDKCallback_TraceAttack);
}

public Action SDKCallback_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(!IsBoxEnabled())
	{
		return Plugin_Continue;
	}
	
	if ( !(0 < attacker <= MaxClients ))
	{
		return Plugin_Continue;
	}
	
	int iTeam;
	if( ( iTeam = GetClientTeam(victim) ) == GetClientTeam(attacker) && iTeam == CS_TEAM_CT )
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action ConCommand_Box(int client, int args)
{
	if(!SimonAPI_HasAccess(client, true))
	{
		CPrintToChat(client, "\x04* You do not have access to this command.");
		return Plugin_Handled;
	}
	
	if(DaysAPI_IsDayRunning())
	{
		CPrintToChat(client, "\x04* You can't do that while a day is running");
		return Plugin_Handled;
	}
	
	g_bBoxEnabled = !g_bBoxEnabled;
	ConVar_TeammatesAreEnemies.BoolValue = IsBoxEnabled();
	CPrintToChatAll("\x07'%N' has \x03'%s' \x07Box mode!", client, IsBoxEnabled() ? "Enabled" : "Disabled");
	return Plugin_Handled;
}

public DayStartReturn DaysAPI_OnDayStart_Pre()
{
	// Should also change the var g_bTeammatesAreEnemies
	// From change hook
	g_bBoxEnabled = false;
	ConVar_TeammatesAreEnemies.BoolValue = false;
}

public void Event_RoundStart(Event event, char[] szEvent, bool bDontbroadcast)
{
	if(DaysAPI_IsDayRunning())
	{
		return;
	}
	
	// Reset
	g_bBoxEnabled = false;
	ConVar_TeammatesAreEnemies.BoolValue = false;
}

public void ConVar_OnChanged(ConVar convar, char[] szOldValue, char[] szNewValue)
{
	//g_bTeammatesAreEnemies = ConVar_TeammatesAreEnemies.BoolValue;
}


