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

ConVar ConVar_RestartGame;

public void OnPluginStart()
{
	RegServerCmd("restart", SrvCmd_Restart);
	RegServerCmd("rr", SrvCmd_Restart);
	RegAdminCmd("sm_restart", RestartRound, ADMFLAG_ROOT);
	
	ConVar_RestartGame = FindConVar("mp_restartgame");
}

public Action RestartRound(int client, int iArgs)
{
	SetConVarInt(ConVar_RestartGame, 1);
	return Plugin_Handled;
}

public Action SrvCmd_Restart(int iArgs)
{
	char szMapName[PLATFORM_MAX_PATH];
	GetCurrentMap(szMapName, sizeof szMapName);
	
	ServerCommand("map \"%s\"", szMapName);
	return Plugin_Handled;
}
