#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <multicolors>
#include <cstrike>
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

float g_flOrigins[MAXPLAYERS][3];
float g_flAngles[MAXPLAYERS][3];
bool g_bSpawnedOnce[MAXPLAYERS];

public void OnPluginStart()
{
	RegAdminCmd("sm_rev", Revive, ADMFLAG_BAN, "<target> [0/1 - return to death/spawn origin]");
	RegAdminCmd("sm_revive", Revive, ADMFLAG_BAN, "<target> [0/1 - return to death/spawn origin]");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientPutInServer(int client)
{
	g_bSpawnedOnce[client] = false;
}

public Action Revive(int client, int args)
{
	char szCmdArg[25];
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	char szPos[25];
	GetCmdArg(2, szPos, sizeof szPos);
	
	bool bPos = true;
	if(szPos[0])
	{
		bPos = view_as<bool>(StringToInt(szPos));
	}
	
	char szTargetName[35];
	int iTargets[MAXPLAYERS], iCount;
	bool bIsMl;
	iCount = ProcessTargetString(szCmdArg, client, iTargets, sizeof iTargets, 0, szTargetName, sizeof szTargetName, bIsMl);
	
	if(iCount <= 0)
	{
		CReplyToCommand(client, "\x04[SM] \x01Could not find a (dead) target client.");
		return Plugin_Handled;
	}
	
	float vVelZero[3] = { 0.0, 0.0, 0.0 };
	for(int i, iPlayer; i < iCount; i++)
	{
		iPlayer = iTargets[i];
		CS_RespawnPlayer(iPlayer);
		
		if(bPos && g_bSpawnedOnce[client])
		{
			TeleportEntity(iPlayer, g_flOrigins[iPlayer], g_flAngles[iPlayer], vVelZero);
		}
	}
	
	CPrintToChatAll("\x04[SM] \x01ADMIN \x05%N \x01revived \x03%s\x01.", client, szTargetName);
	return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, char[] szEventName, bool bDontBroadcast)
{
	int iUserId = GetEventInt(event, "userid");
	RequestFrame(NextFrame_GetOrigins, iUserId);
}

public void NextFrame_GetOrigins(int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	
	if(!client)
	{
		return;
	}
	
	g_bSpawnedOnce[client] = true;
	
	GetClientEyePosition(client, g_flOrigins[client]);
	GetClientAbsAngles(client, g_flAngles[client]);
}

public void Event_PlayerDeath(Event event, char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client)
	{
		return;
	}
	
	GetClientEyePosition(client, g_flOrigins[client]);
	GetClientAbsAngles(client, g_flAngles[client]);
}

