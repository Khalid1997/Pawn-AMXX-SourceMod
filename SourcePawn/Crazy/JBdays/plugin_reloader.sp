#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
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

char g_szPlugin[50];

public void OnPluginStart()
{
	RegConsoleCmd("sp", Command_SetPlugin);
	RegConsoleCmd("rp", Command_ReloadPlugin);
}

public Action Command_SetPlugin(int client, int iArgs)
{
	if (iArgs)
	{
		GetCmdArg(1, g_szPlugin, sizeof g_szPlugin);
	}
	
	ReplyToCommand(client, "Plugin set to %s", g_szPlugin);
}

public Action Command_ReloadPlugin(int client, int iArgs)
{
	//PrintToServer("%d", iArgs);
	if(iArgs == 0)
	{
		ServerCommand("sm plugins reload %s", g_szPlugin);
	}
	
	else
	{
		char szArg[50];
		GetCmdArg(1, szArg, sizeof szArg);
		ServerCommand("sm plugins reload %s", szArg);
	}
}
