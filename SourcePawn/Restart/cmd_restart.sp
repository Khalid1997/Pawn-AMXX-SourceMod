#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Server Cmd Restart",
	author = "Khalid",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegServerCmd("restart", SrvCmd_Restart);
	RegServerCmd("rr", SrvCmd_Restart);
}

public Action SrvCmd_Restart(int iArgs)
{
	char szMapName[100];
	GetCurrentMap(szMapName, sizeof szMapName);
	
	ServerCommand("changelevel \"%s\"", szMapName);
	return Plugin_Handled;
}
