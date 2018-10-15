#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "End Round Command",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

//ConVar ConVar_IgnoreRoundWinCond;

public void OnPluginStart()
{
	//ConVar_IgnoreRoundWinCond = FindConVar("mp_ignore_round_win_conditions");
	RegAdminCmd("sm_endround", AdmCmd_EndRound, ADMFLAG_BAN );
}

public Action AdmCmd_EndRound(int client, int argc)
{
	//int iOld = ConVar_IgnoreRoundWinCond.IntValue;
	//ConVar_IgnoreRoundWinCond.IntValue = 0;
	
	CS_TerminateRound(0.1, CSRoundEnd_Draw, true);
//	ConVar_IgnoreRoundWinCond.IntValue = iOld;
	
	ReplyToCommand(client, "* You have ended the round.");
	return Plugin_Handled;
}
