#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <smartjaildoors>
#include <daysapi>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "DaysAPI: Jail Doors Opener",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	
}

public void DaysAPI_OnDayStart()
{
	SJD_OpenDoors();
}