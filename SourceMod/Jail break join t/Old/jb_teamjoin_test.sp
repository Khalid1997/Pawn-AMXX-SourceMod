#include <cstrike>
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Join team T",
	author = "Khalid",
	version = "Stupid"
}

new g_iCheck[MAXPLAYERS + 1];

public void OnPluginStart()
{
	//HookUserMessage(GetUserMessageId("VGUIMenu"), Hook_TeamMenu, true);
	AddCommandListener(ClCmd_JoinTeam, "jointeam");
	//HookEvent("player_team", EventHook_Team, EventHookMode_Pre);
}

public OnClientPutInServer(client)
{
	ChangeClientTeam(client, CS_TEAM_T);
}

public Action:EventHook_Team(Handle hEvent, const char[] name, bool dontBroadcast)
{
	new userid = GetEventInt(hEvent, "userid");
	new client = GetClientOfUserId(userid);
	
	new iTeamId = GetEventInt(hEvent, "team");
	new iOldTeam = GetEventInt(hEvent, "oldteam");
	
	PrintToServer("%d %d", iTeamId, iOldTeam);
	
	if(iOldTeam == CS_TEAM_NONE)
	{
		if(iTeamId != CS_TEAM_T)
		{
			SetEventInt(hEvent, "team", CS_TEAM_T);
			//DispatchKeyValue(client, "m_iTeamNum", "2");
			ChangeClientTeam(client, CS_TEAM_T);
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}
 /*
Name:	player_team
	
short	userid	user ID on the server
byte	team	team id
byte	oldteam	old team id
bool	disconnect	team change because player disconnects
bool	autoteam	true if the player was auto assigned to the team (OB only)
bool	silent	if true wont print the team join messages (OB only)
string	name	player's name (OB only)
*/

public Action:ClCmd_JoinTeam(client, const String:szCommand[], iArgCount)
{
	new String:szJoiningTeam[3], iTeam;
	GetCmdArg(1, szJoiningTeam, sizeof szJoiningTeam);
	
	iTeam = StringToInt(szJoiningTeam);
	return ClientConnect(client, iTeam);
}

public Action Hook_TeamMenu(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	new String:szString[50]
	PbReadString(msg, "name", szString, sizeof szString);
	
	PrintToServer("name: %s", szString);
	PrintToServer("show: %d", _:PbReadBool(msg, "show"));
	
	if(StrEqual(szString, "team"))
	{
		PbSetBool(msg, "show", false);
		
		//CreateTimer(0.1, JoinTeam, players[0]);
		
		return Plugin_Changed;
	}

	return Plugin_Continue;
	
	//PbGetRepeatedFieldCount(msg, "subkey");
	//PrintToServer("
}

stock Action:ClientConnect(client, iTeam)
{
	PrintToServer("joining team:-- %d", iTeam);
	
	if(iTeam != 0 && (iTeam == GetClientTeam(client) || iTeam == CS_TEAM_SPECTATOR) )
	{
		return Plugin_Continue;
	}
	
	if(iTeam != CS_TEAM_T)
	{
		if(iTeam == 0)
		{
			//g_iCheck[client] = 1;
			PrintToServer("bLOCKs");
			return Plugin_Handled;
		}
		
		ClientCommand(client, "jointeam 2");
		//UTIL_TeamMenu(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

stock UTIL_TeamMenu(client)
{
	new clients[1];
	new Handle:bf;
	clients[0] = client;
	bf = StartMessage("VGUIMenu", clients, 1);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(bf, "name", "team");
		PbSetBool(bf, "show", true);
	}
	else
	{
		BfWriteString(bf, "team"); // panel name
		BfWriteByte(bf, 1); // bShow
		BfWriteByte(bf, 0); // count
	}
	
	EndMessage();
}
