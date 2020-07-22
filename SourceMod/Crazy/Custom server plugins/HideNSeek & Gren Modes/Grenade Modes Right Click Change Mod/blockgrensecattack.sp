#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

public Plugin myinfo = 
{
	name = "Block Gren Secondary Attack", 
	author = "Khalid", 
	description = "xD", 
	version = PLUGIN_VERSION, 
	url = "Bla Bla"
};

//Grenade consts
char g_saGrenadeWeaponNames[][] =  {
	"weapon_flashbang", 
	"weapon_molotov", 
	"weapon_smokegrenade", 
	"weapon_hegrenade", 
	"weapon_decoy", 
	"weapon_incgrenade"
};

public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnWeaponSwitchPost(int iClient, int iWeapon)
{
	//PrintToChatAll("OnWeaponSwitch Called");
	
	if (IsWeaponGrenade(iWeapon))
	{
		// Dont let him throw!!!
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9001.0);
	}
}

bool IsWeaponGrenade(int iWeapon)
{
	char sWeaponName[64];
	GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
	
	for (int i = 0; i < sizeof(g_saGrenadeWeaponNames); i++)
	{
		if (StrEqual(g_saGrenadeWeaponNames[i], sWeaponName))
			return true;
	}
	
	return false;
} 