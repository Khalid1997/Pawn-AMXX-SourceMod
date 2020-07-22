#include <sourcemod>
#include <cstrike>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <ctban>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =  {
	name = "Team Join Managment", 
	author = "Khalid", 
	description = "", 
	version = "2.0", 
	url = ""
}

public void OnPluginStart()
{	
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	//HookEvent("player_connect_full", Event_OnFullConnect, EventHookMode_Post);

}

public void OnPluginEnd()
{

}

public Action CommandListener_JoinTeam(int client, const char[] command, int args)
{
	char szTeam[2];
	GetCmdArg(1, szTeam, sizeof(szTeam));
	int iNewTeam = StringToInt(szTeam);
	
	int iCurrentTeam = GetClientTeam(client);
	
	//PrintToServer("Called %s %s", command, szTeam);
	if (iNewTeam == iCurrentTeam)
	{
		return Plugin_Continue;
	}
	
	if(CS_TEAM_SPECTATOR <= iNewTeam <= CS_TEAM_CT)
	{
		return Plugin_Continue;
	}
	
	if(iNewTeam == CS_TEAM_T)
	{
		return Plugin_Handled;
	}
	
	// The fix is actually here
	ForcePlayerSuicide(client);
	PutPlayerInTeam(client, iNewTeam);
	
	return Plugin_Handled;
}

// Auto join team;
void PutPlayerInTeam(int client, int iTeam)
{
	ChangeClientTeam(client, iTeam);
}