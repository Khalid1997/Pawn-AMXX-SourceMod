#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <cstrike>
#include <getplayers>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

bool g_bRoundEnd, g_bAllowTerminate;

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client)
	{
		return;
	}
	
	int iCount = GetPlayers(_, GP_Flag_Alive, GP_Team_First | GP_Team_Second);
	
	//PrintToChatAll("Event");
	if(!iCount && !g_bRoundEnd)
	{
		g_bAllowTerminate = true;
	}
}

public Action CS_OnTerminateRound(float &flDelay, CSRoundEndReason &reason)
{
	//PrintToChatAll("Terminate");
	if(!g_bAllowTerminate)
	{
		return Plugin_Handled;
	}
	
	g_bAllowTerminate = false;
	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_bRoundEnd = true;
	g_bAllowTerminate = false;
}

public void Event_RoundStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_bRoundEnd = false;
	g_bAllowTerminate = false;
}