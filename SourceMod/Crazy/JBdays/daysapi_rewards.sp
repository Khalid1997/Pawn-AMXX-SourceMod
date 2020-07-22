#pragma semicolon 1

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <daysapi>
#include <cstrike>
#include <multicolors>
#include <jail_shop>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

KeyValues kv;
char g_szPath[] = "cfg/sourcemod/daysapi/daysapi_rewards.ini";

char Key_Default[] = "default";
char Key_Message[] = "message";
char Key_Credits[] = "credits";
char Key_Parent[] = "Day_Rewards";
char Key_Participation[] = "participation";

char Key_Message_Participation[] = "message_participation";
char Key_Message_Win[] = "message_winning";

#define MAX_WIN_MESSAGE_LENGTH 	256
char g_szDefaultWinningMessage[MAX_WIN_MESSAGE_LENGTH];
char g_szDefaultParticipationMessage[MAX_WIN_MESSAGE_LENGTH];
int g_iDefaultWinningReward;
/* 
"Day_Rewards"
{
	"default"
	{
		"credits"			"5"
		"message_win"			"You have won %reward% credits for winning in this day."
		"message_participate"	"You have won %reward% credits for participating in this day."
	}
		
	"day_hegrenade"
	{
		"participation"
		{
			"credits"	"default"
			"message"	"default"
		}
		
		"firstplace"
		{
			"credits"	"1"
			"message"	"You have gained %reward% credits for winning this day"
		}
	}
}
*/

public void OnPluginStart()
{
	RegAdminCmd("daysapi_reloadrewards", ConCmd_ReloadRewards, ADMFLAG_ROOT);
}

public Action ConCmd_ReloadRewards(int client, int argc)
{
	ReadRewardsFile();
	CReplyToCommand(client, "* You have reloaded the rewards file.");
	return Plugin_Handled;
}

public void OnMapStart()
{
	ReadRewardsFile();
}

void ReadRewardsFile()
{
	if(kv != null)
	{
		delete kv;
	}
	
	kv = CreateKeyValues(Key_Parent);
	if(!FileExists(g_szPath))
	{
		kv.JumpToKey(Key_Default, true);
		kv.SetNum(Key_Credits, 0);
		kv.SetString(Key_Message_Win, "{green}* You were granted {red}{reward} credits{green} for {red}winning{green} this day.");
		kv.GetString(Key_Message_Win, g_szDefaultWinningMessage, sizeof g_szDefaultWinningMessage);
		
		kv.SetString(Key_Message_Participation, "{green}* You were granted {red}{reward} credits{green} for {red}participating{green} in this day.");
		kv.GetString(Key_Message_Participation, g_szDefaultWinningMessage, sizeof g_szDefaultWinningMessage);
		
		kv.GoBack();
		
		g_iDefaultWinningReward = 0;
	
		kv.ExportToFile(g_szPath);
		return;
	}
	
	kv.ImportFromFile(g_szPath);
	
	if(!kv.JumpToKey(Key_Default, false))
	{
		kv.JumpToKey(Key_Default, true);
		kv.SetNum(Key_Credits, 0);
		
		kv.SetString(Key_Message_Win, "{green}* You were granted {red}{reward} credits{green} for {red}winning{green} this day.");
		kv.GetString(Key_Message_Win, g_szDefaultWinningMessage, sizeof g_szDefaultWinningMessage);
		
		kv.SetString(Key_Message_Participation, "{green}* You were granted {red}{reward} credits{green} for {red}participating{green} in this day.");
		kv.GetString(Key_Message_Participation, g_szDefaultParticipationMessage, sizeof g_szDefaultParticipationMessage);
		
		g_iDefaultWinningReward = 0;
	}
	
	else
	{
		g_iDefaultWinningReward = kv.GetNum(Key_Credits, 0);
		kv.GetString(Key_Message_Win, g_szDefaultWinningMessage, sizeof g_szDefaultWinningMessage);
		kv.GetString(Key_Message_Participation, g_szDefaultParticipationMessage, sizeof g_szDefaultParticipationMessage);
	}
	
	kv.Rewind();
}

bool GetReward(char[] szDayName, char[] szWinnerGroup, char[] szBuffer, int iSize, int &iReward)
{
	if(!kv.JumpToKey(szDayName, false))
	{
		return false;
	}
	
	if(!kv.JumpToKey(szWinnerGroup, false))
	{
		kv.Rewind();
		return false;
	}
	
	char szMessage[MAX_WIN_MESSAGE_LENGTH];
	if(!kv.GetString(Key_Credits, szMessage, sizeof szMessage))
	{
		kv.Rewind();
		return false;
	}
	
	if(StrEqual(szMessage, Key_Default))
	{
		iReward = g_iDefaultWinningReward;
	}
	
	else
	{
		iReward = StringToInt(szMessage);
	}
	
	kv.GetString(Key_Message, szMessage, sizeof szMessage, "");
	
	if (StrEqual(szMessage, Key_Default))
	{
		char szSectionName[25];
		kv.GetSectionName(szSectionName, sizeof szSectionName);
		
		if(!StrEqual(szSectionName, Key_Participation))
		{
			strcopy(szMessage, sizeof szMessage, g_szDefaultWinningMessage);
		}
		
		else
		{
			strcopy(szMessage, sizeof szMessage, g_szDefaultParticipationMessage);
		}
	}
	
	if(szMessage[0])
	{
		char szCredits[5];
		FormatEx(szCredits, sizeof szCredits, "%d", iReward);
		ReplaceString(szMessage, sizeof szMessage, "{reward}", szCredits, true);
	}
	
	strcopy(szBuffer, iSize, szMessage);
	kv.Rewind();
	
	return true;
}

public void DaysAPI_OnDayStart(char[] szIntName)
{
	char szMessage[MAX_WIN_MESSAGE_LENGTH];
	int iReward;
	if (!GetReward(szIntName, Key_Participation, szMessage, sizeof szMessage, iReward))
	{
		return;
	}
	
	char szLogReason[256];
	FormatEx(szLogReason, sizeof szLogReason, "Day Participation: %s", szIntName);
	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))
		{
			continue;
		}
		
		if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
		{
			continue;
		}
		
		JBShop_GiveCredits(client, iReward, false, szIntName);
		
		if(szMessage[0])
		{
			CPrintToChat(client, szMessage);
		}
	}
}

public void DaysAPI_OnDayEnd(char[] szIntName, any data)
{
	DaysAPI_GetDayWinnersGroups(GetDayWinnersCallback);
}

public void GetDayWinnersCallback(char[] szDayName, char[] szWinnersGroup, int[] iWinnersList, int iCount, any data)
{
	char szMessage[MAX_WIN_MESSAGE_LENGTH];
	int iReward;
	if (!GetReward(szDayName, szWinnersGroup, szMessage, sizeof szMessage, iReward))
	{
		return;
	}
	
	char szLogReason[256];
	FormatEx(szLogReason, sizeof szLogReason, "Day Win: %s", szDayName);
	for (int i = 0, client; i < iCount; i++)
	{
		client = iWinnersList[i];
		
		if(!IsClientInGame(client))
		{
			continue;
		}
		
		
		JBShop_GiveCredits(client, iReward, false, szLogReason);
		CPrintToChat(client, szMessage);
	}
	
	//CPrintToChatAll(szMessage);
}