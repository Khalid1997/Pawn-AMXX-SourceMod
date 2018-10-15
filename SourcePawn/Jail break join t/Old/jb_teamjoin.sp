#include <cstrike>
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Join team T",
	author = "Khalid",
	version = "Stupid"
}

public void OnPluginStart()
{
	AddCommandListener(ClCmd_JoinTeam, "jointeam");
}

public OnClientPutInServer(client)
{
	ChangeClientTeam(client, CS_TEAM_T);
}

public Action:ClCmd_JoinTeam(client, const String:szCommand[], iArgCount)
{
	new String:szJoiningTeam[3], iTeam;
	GetCmdArg(1, szJoiningTeam, sizeof szJoiningTeam);
	
	iTeam = StringToInt(szJoiningTeam);
	return ClientConnect(client, iTeam);
}

stock Action:ClientConnect(client, iTeam)
{
	PrintToServer("joining team:-- %d", iTeam);
	
	if(iTeam != CS_TEAM_T)
	{
		ClientCommand(client, "jointeam %d", CS_TEAM_T);
		PrintToServer("Blocked, %d", CS_TEAM_T);
		return Plugin_Handled;
	}
	
	if(iTeam != 0 && (iTeam == GetClientTeam(client) || iTeam == CS_TEAM_SPECTATOR) )
	{
		return Plugin_Continue;
	}

	return Plugin_Continue;
}
