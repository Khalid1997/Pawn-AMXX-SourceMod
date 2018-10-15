#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Server CVar Change Message Blocker",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre); // http://wiki.alliedmods.net/Generic_Source_Server_Events#server_cvar
}

public Action Event_ServerCvar(Event event, char[] name, bool dontBroadcast)
{
	char sConVarName[64];
    
	GetEventString(event, "cvarname", sConVarName, sizeof(sConVarName));
    
    /*
	if (StrContains(sConVarName, "bot_difficulty", false) >= 0 ||
		StrContains(sConVarName, "bot_quota", false) >= 0)*/
	{
		return Plugin_Handled;
	}
    
	//return Plugin_Continue;
}  
