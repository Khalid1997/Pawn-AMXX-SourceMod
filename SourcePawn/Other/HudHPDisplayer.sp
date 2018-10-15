#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdkhooks>
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

Handle g_hHud;
public void OnPluginStart()
{
	g_hHud = CreateHudSynchronizer();
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	SDKHook(client, SDKHook_PostThink, SDKCallBack_PostThink);
}

public void SDKCallBack_PostThink(int client)
{
	int iOther = GetClientAimTarget(client, true);
	
	if( !( 0 < iOther <= MaxClients) )
	{
		return;
	}
	
	SetHudTextParams(-1.0, -1.0, 0.1, 255, 0, 0, 0, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_hHud, "%N: %d", iOther, GetClientHealth(iOther));
}
