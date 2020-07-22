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

// This is useful for the mod after bhop (Influx Timer removes replicating flag)

char szCvars[][] = {
	"sv_autobunnyhopping",
	"sv_enablebunnyhopping",
	"sv_gravity",
	"sv_airaccelerate",
	"sv_friction"
};

public void OnPluginStart()
{	
	//SetConVarFlags(cvar, GetConVarFlags(cvar) & FCVAR_REPLICATED);
	
	//RegConsoleCmd("sm_test", Test);
}

public void OnMapStart()
{
	ConVar hCvar;
	for (int i; i < sizeof szCvars; i++)
	{
		hCvar = FindConVar(szCvars[i]);
		
		if(hCvar != null)
		{
			SetConVarFlags(hCvar, GetConVarFlags(hCvar) | FCVAR_REPLICATED);
		}
	}
}

/*
public void OnConfigsExecuted()
{
	//RequestFrame(NextFrame);
}

public void NextFrame()
{
	SetConVarFlags(cvar1, GetConVarFlags(cvar1) | FCVAR_REPLICATED);
	SetConVarFlags(cvar2, GetConVarFlags(cvar2) | FCVAR_REPLICATED);
}

public Action Test(int client, int Args)
{
	//SetConVarFlags(cvar, GetConVarFlags(cvar) | FCVAR_REPLICATED);
	if(GetConVarFlags(cvar1) & FCVAR_REPLICATED)
	{
		PrintToChatAll("N Yes");
	}
	
	else
	{
		PrintToChatAll("N No");
	}
}

public void OnClientPutInServer(int client)
{
	//cvar.ReplicateToClient(client, "1");	
	
}*/