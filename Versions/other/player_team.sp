#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	
}

public Action Event_PlayerTeam(Event event, char[] name, bool dontBroadcast)
{
	int i, j, k;
	bool l, m, o;
	char dump[32];
	
	i = GetEventInt(event, "userid");
	j = GetEventInt(event, "team");
	k = GetEventInt(event, "oldteam");
	l = GetEventBool(event, "disconnect");
	m = GetEventBool(event, "autoteam");
	o = GetEventBool(event, "silent");
	
	GetEventString(event, "name", dump, sizeof dump);
	
	PrintToServer(
	"userid - %d\n\
	team - %d\n\
	oldteam - %d\n\
	disconnect - %d\n\
	autoteam - %d\n\
	silent - %d\n\
	name - %s", i, j, k, l, m, o, dump);
}