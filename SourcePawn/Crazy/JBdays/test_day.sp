#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <myjailbreak_e>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

char DayName[] = "Test1";

public void OnPluginStart()
{
	
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay(DayName);
}

public void OnAllPluginsLoaded()
{
	DaysAPI_AddDay(DayName, TestDayStartFunction, TestDayEndFunction);
	//DaysAPI_SetDayDisplayName(DayName)
}

public void TestDayStartFunction()
{
	DaysAPI_OnDayStart(DayName);
}

public void TestDayEndFunction()
{
	DaysAPI_OnDayEnd(DayName);
}
	
public void DaysAPI_OnDayStart(char[] szIntName)
{
	PrintToChatAll("%s Started", szIntName);
}

public void DaysAPI_OnDayEnd(char[] szIntName)
{
	PrintToChatAll("%s Ended", szIntName);
}
