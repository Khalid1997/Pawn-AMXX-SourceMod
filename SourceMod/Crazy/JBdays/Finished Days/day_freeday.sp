#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <daysapi>
#include <smartjaildoors>
#include <multicolors>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "DaysAPI: FreeDay",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

char FreeDay_IntName[] = "freeday";

Handle g_hDisplayTextTimer;
Handle g_hSyncObject;

public void OnPluginStart()
{
	g_hSyncObject = CreateHudSynchronizer();
}

public void OnAllPluginsLoaded()
{
	DaysAPI_AddDay(FreeDay_IntName, FreeDayStart, FreeDayEnd);
	DaysAPI_SetDayInfo(FreeDay_IntName, DayInfo_DisplayName, "FreeDay");
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay(FreeDay_IntName);
}

public DayStartReturn FreeDayStart()
{
	g_hDisplayTextTimer = CreateTimer(0.1, Timer_DisplayText, _, TIMER_REPEAT);
	
	SJD_OpenDoors();
	
	SetHudTextParams(0.7, 0.0, 0.1, 255, 0, 0, 255);
	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))
		{
			continue;
		}
		
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			SetEntityRenderColor(client, 0, 255, 0, 255);
		}
		
		CPrintToChat(client, "\x04Today is a \x03FreeDay");
		ShowSyncHudText(client, g_hSyncObject, "Today's Event FreeDay");
		PrintHintText(client, "<size = '18'>Today is a <font color='#FF0000'>FreeDay</font>");
	}
}

public Action Timer_DisplayText(Handle hTimer, any data)
{
	SetHudTextParams(0.8, 0.2, 0.1, 255, 0, 0, 255);
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		
		ShowSyncHudText(client, g_hSyncObject, "Today's Event FreeDay");
	}
}

public void FreeDayEnd()
{
	delete g_hDisplayTextTimer;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		
		SetEntityRenderColor(client);
		CPrintToChat(client, "\x04The \x03FreeDay \x04has ended.");
	}
}
