#include <sourcemod>

#define HIDE_RADAR_CSGO 1<<12

new String:strGame[10];

public Plugin:myinfo = 
{
    name = "Disable Radar",
    author = "Internet Bully",
    description = "Turns off Radar on spawn",
	version     = "1.2 EDIT",
    url = "http://www.sourcemod.net/"
}

bool g_bStatus[MAXPLAYERS + 1] = false;

public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] szError, int iErrMax)
{
	CreateNative("DisableRadar_Status", Native_Status);
	return APLRes_Success;
}

public OnPluginStart() 
{
	HookEvent("player_spawn", Player_Spawn);
	
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(StrContains(strGame, "cstrike") != -1) 
		HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
}

public void OnClientDisconnect(int client)
{
	g_bStatus[client] = false;
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_bStatus[client])
	{
		CreateTimer(0.0, RemoveRadar, client);
	}
}  

public Action:RemoveRadar(Handle:timer, any:client) 
{    
	RadarRemove(client, true)
} 

void RadarRemove(int client, bool bStatus)
{
	
	if(StrContains(strGame, "csgo") != -1) 
	{
		if(bStatus)
		{
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
		}
		
		else
		{
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
		}
	}
	
	else if(StrContains(strGame, "cstrike") != -1) 
	{
		CSSHideRadar(client, bStatus);
	}
}

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)  // from GoD-Tony's "Radar Config" https://forums.alliedmods.net/showthread.php?p=1471473
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if(!g_bStatus[client])
	{
		return;
	}
	
	if (client && GetClientTeam(client) > 1)
	{
		new Float:fDuration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
		CreateTimer(fDuration, RemoveRadar, client);
	}
}

CSSHideRadar(client, bStatus)
{
	if(bStatus)
	{
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	}
	
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
	}
}

public Native_Status(Handle hPlugin, int iArgs)
{
	if(iArgs > 2)
	{
		ThrowNativeError(SP_ERROR_NONE, "???");
		return false;
	}
	
	int client = GetNativeCell(1);
	if(!(0 < client <= MAXPLAYERS) || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Client %d is not in game", client);
		return false;
	}
	
	bool bOldStatus = g_bStatus[client];
	g_bStatus[client] = GetNativeCell(2);
	
	if(bOldStatus != g_bStatus[client] && IsPlayerAlive(client))
	{
		RadarRemove(client, g_bStatus[client]);
	}
	
	return true;
}