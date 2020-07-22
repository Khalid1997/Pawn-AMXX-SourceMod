#include <sourcemod>
#include <basecomm>
#include <simonapi>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = 
{
	name = "[CS:GO] Jailbreak Mute Prisoners", 
	author = "Vaggelis", 
	description = "Simple plugin that mutes prisoners, except admins.", 
	version = "1.0", 
	url = ""
}

bool g_bMuteState, 
g_bIsAdmin[MAXPLAYERS];
g_bIsInGame[MAXPLAYERS];
int g_iSimonId;

public void OnPluginStart()
{
	RegConsoleCmd("sm_tmute", ConCmd_MuteTerr);
	RegConsoleCmd("sm_mutet", ConCmd_MuteTerr);
	
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_TeamChange);
}

public void OnPluginEnd()
{
	ApplyMuteState(false);
}

public void OnMapEnd()
{
	g_bMuteState = false;
}

public void SimonAPI_OnSimonChanged(int newClient, int oldClient, SimonChangedReason iReason)
{
	if (oldClient != No_Simon && IsClientInGame(oldClient) && CanBeMuted(oldClient))
	{
		SetClientMuteState(oldClient, g_bMuteState);
	}
	
	g_iSimonId = newClient;
	if (newClient != No_Simon)
	{
		SetClientMuteState(newClient, false);
	}
}

public Action ConCmd_MuteTerr(int client, int args)
{
	if (!SimonAPI_HasAccess(client, true))
	{
		ReplyToCommand(client, "You do not have access to this command.");
		return Plugin_Handled;
	}
	
	ApplyMuteState(!g_bMuteState);
	
	ReplyToCommand(client, "* You have '%s' voice comms for the prisoners. Write !tmute to toggle again.", g_bMuteState ? "Enabled" : "Disabled");
	return Plugin_Handled;
}

public void Event_RoundEnd(Event event, char[] szEvent, bool bDontBroadcast)
{
	ApplyMuteState(false);
}

public void Event_TeamChange(Event event, char[] szEvent, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetClientMuteState(client, CanBeMuted(client) ? g_bMuteState : false);
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if (AdminCache_Admins != part)
	{
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bIsInGame[i])
		{
			continue;
		}
		
		if (SimonAPI_HasAccess(i, false))
		{
			g_bIsAdmin[i] = false;
			continue;
		}
		
		g_bIsAdmin[i] = true;
	}
}

public void OnClientPutInServer(int client)
{
	g_bIsInGame[client] = true;
}

public void OnClientDisconnect(int client)
{
	g_bIsInGame[client] = false;
}

public void OnClientPostAdminCheck(int client)
{
	if (SimonAPI_HasAccess(client, false))
	{
		g_bIsAdmin[client] = true;
	}
	
	else g_bIsAdmin[client] = false;
	
	SetClientMuteState(client, CanBeMuted(client) ? g_bMuteState : false);
}

void ApplyMuteState(bool state)
{
	g_bMuteState = state;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bIsInGame[i])
		{
			continue;
		}
		
		if (!CanBeMuted(i))
		{
			SetClientMuteState(i, false);
		}
		
		else
		{
			SetClientMuteState(i, g_bMuteState);
		}
	}
}

bool CanBeMuted(int client)
{
	if (GetClientTeam(client) == CS_TEAM_CT || g_iSimonId == client)
	{
		return false;
	}
	
	if (g_bIsAdmin[client])
	{
		return false;
	}

	
	return true;
}

void SetClientMuteState(int client, bool bStatus)
{
	BaseComm_SetClientMute(client, bStatus);
} 
