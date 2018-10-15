#pragma semicolon 1

#include <sourcemod>
#include <multimod>

public Plugin myinfo = 
{
	name = "Multimod: Currentmod and NextMod",
	author = "Khalid",
	description = "Add currentmod and nextmod chat commands",
	version = MM_VERSION_STR,
	url = ""
};

public OnPluginStart()
{
	AddCommandListener(Cmd_Say, "say");
	AddCommandListener(Cmd_Say, "say_team");
}

public Action:Cmd_Say(client, const String:szCommand[], iArgCount)
{
	static String:szMMCmd[20];
	GetCmdArgString(szMMCmd, sizeof szMMCmd);
	StripQuotes(szMMCmd);
	
	ReplaceString(szMMCmd, sizeof szMMCmd, "!", "");
	ReplaceString(szMMCmd, sizeof szMMCmd, "/", "");
	
	new String:szModName[MAX_MOD_NAME];
	
	if(StrEqual(szMMCmd, "currentmod", false))
	{
		//new iNextModId = MultiMod_GetNextModId();
		MultiMod_GetModProp(MultiMod_GetCurrentModId(), MultiModProp_Name, szModName, sizeof szModName);
		MM_PrintToChat(client, "Current MOD: \x04%s", szModName);
	}
	
	else if(StrEqual(szMMCmd, "nextmod", false))
	{
		new iNextModId = MultiMod_GetNextModId();
		
		if(iNextModId == -1)	szModName = "Not chosen yet.";
		else MultiMod_GetModProp(iNextModId, MultiModProp_Name, szModName, sizeof szModName);
		
		MM_PrintToChat(client, "Next MOD: \x04%s",  szModName);
	}
	
	return Plugin_Continue;
}



