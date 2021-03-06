#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multimod>

public Plugin myinfo = 
{
	name = "Multimod Plugin: Currentmod and NextMod",
	author = "Khalid",
	description = "Add currentmod and nextmod chat commands",
	version = MM_VERSION_STR,
	url = ""
};

public void OnPluginStart()
{
	//RegConsoleCmd("sm_nextmod", ConsoleCmd_PrintNextMod);
	//RegConsoleCmd("sm_currentmod", ConsoleCmd_PrintCurrentMod);
	
	AddCommandListener(CallBack_CheckCurrentNextMod, "say");
	AddCommandListener(CallBack_CheckCurrentNextMod, "say_team");
}

public Action CallBack_CheckCurrentNextMod(int client, const char[] szCommand, int iArgC)
{
	if(!iArgC)
	{
		return;
	}
	
	char szArg[25];
	GetCmdArg(1, szArg, sizeof szArg);
	
	if(StrEqual(szArg, "currentmod", false))
	{
		ConsoleCmd_PrintCurrentMod(client, 0);
	}
	
	else if(StrEqual(szArg, "nextmod", false))
	{
		ConsoleCmd_PrintNextMod(client, 0);
	}
}

public Action ConsoleCmd_PrintCurrentMod(int client, int iArgs)
{
	char szModName[MM_MAX_MOD_PROP_LENGTH];
	
	MultiMod_GetModProp(MultiMod_GetCurrentModId(), MultiModProp_Name, szModName, sizeof szModName);
	MultiMod_PrintToChat(client, "Current MOD: \x04%s", szModName);
}

public Action ConsoleCmd_PrintNextMod(int client, int iArgs)
{
	char szModName[MM_MAX_MOD_PROP_LENGTH];
	
	int iNextModId = MultiMod_GetNextModId();
		
	if(iNextModId == -1)	szModName = "Not chosen yet.";
	else MultiMod_GetModProp(iNextModId, MultiModProp_Name, szModName, sizeof szModName);
		
	MultiMod_PrintToChat(client, "Next MOD: \x04%s",  szModName);
}



