#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.00"

public Plugin myinfo = 
{
	name = "RemoveRoundStartWeapons", 
	author = "Khalid!", 
	description = "Name", 
	version = PLUGIN_VERSION, 
	url = "blabla"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("item_pickup", OnItemPickUp);
}

public void Event_OnRoundStart(Event event, const char[] szName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		for (int j = 0; j < 2; j++)
		{
			RemoveWeaponBySlot(i, j);
		}
	}
}

public void OnItemPickUp(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (GetClientTeam(client) == 3)
	{
		for (int i = 0; i < 2; i++)
		{
			RemoveWeaponBySlot(client, i);
		}
	}
	
	return;
}

bool RemoveWeaponBySlot(int iClient, int iSlot)
{
	int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
	if (IsValidEdict(iEntity)) {
		RemovePlayerItem(iClient, iEntity);
		AcceptEntityInput(iEntity, "Kill");
		return true;
	}
	
	return false;
}

