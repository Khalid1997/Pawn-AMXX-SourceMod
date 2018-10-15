#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

public Plugin myinfo = 
{
	name = "Slash admins",
	author = "Khalid",
	description = "/admins in chat",
	version = PLUGIN_VERSION,
	url = "No"
};

ConVar ConVar_AdminAccess;
ConVar ConVar_AdminNotify;

char g_szAdminString[256];
int g_iLen = 0;
int g_iAdd = 0;

int g_iAdminsCount = 0;

public void OnPluginStart()
{
	ConVar_AdminAccess = CreateConVar("slashadmins_access_flag", "g");
	ConVar_AdminNotify = CreateConVar("slashadmins_notify_on_connect", "1");
	
	AddCommandListener(CMDListener_Say, "say");
	AddCommandListener(CMDListener_Say, "say_team");
}

public OnClientPostAdminCheck(client)
{
	if(ConVar_AdminNotify.IntValue == 0)
	{
		return;
	}
	
	if(!IsClientAdmin(client))
	{
		return;
	}
	
	AddToAdminNames(client);
	
	PrintToChatAll(" \x03*** ADMIN \x04%N \x03 has connected.", client);
}

public OnRebuildAdminCache(AdminCachePart part)
{
	RebuildAdminString();
}

public OnClientDisconnect(client)
{
	if(IsClientAdmin(client))
	{
		RebuildAdminString();
	}
}

int GetFlagsFromBit(AdminFlag:iFlagArray[AdminFlags_TOTAL], iFlagBit)
{
	if(iFlagBit & ADMFLAG_ROOT)
	{
		iFlagArray[0] = Admin_Root;
		return 1;
	}
	
	else
	{
		int iCount;
		
		for (new i = 0; i < view_as<int> AdminFlag; i++)
		{
			if( iFlagBit & (1<<i) )
			{
				iFlagArray[iCount++] = AdminFlag:i;
			}
		}
		
		return iCount;
	}
}

bool IsClientAdmin(client)
{
	static AdminId iAdminId; 
	iAdminId = GetUserAdmin(client);
	
	if(iAdminId == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	static String:szConVarFlag[ AdminFlags_TOTAL + 1];
	GetConVarString(ConVar_AdminAccess, szConVarFlag, sizeof szConVarFlag);
	
	static int iFlagBit;
	iFlagBit = FlagArrayToBits(AdminFlag:szConVarFlag, strlen(szConVarFlag));
	
	static AdminFlag iFlagArray[ AdminFlags_TOTAL ];
	static int iCount;  
	iCount = GetFlagsFromBit(iFlagArray, iFlagBit);
	
	for (new i; i < iCount; i++)
	{
		if(!GetAdminFlag(iAdminId, iFlagArray[i], Access_Effective))
		{
			return false;
		}
	}
	
	return true;
}

public Action CMDListener_Say(int client, char[] szCmd, int iArgsC)
{
	char szCmdArg[25];
	int iSuccess;
	
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	static const String:szTriggerCmds[][] = {
		"admins",
		"showadmin",
		"showadmins",
		"onlineadmins",
		"administrators"
	};
	
	if( szCmdArg[0] == '!' || szCmdArg[0] == '/' )
	{
		for (new i; i < sizeof szTriggerCmds; i++)
		{
			if(StrEqual(szCmdArg[1], szTriggerCmds[i], false))
			{
				ShowOnlineAdmins(client);
				iSuccess = 1;
				break;
			}
		}
		
		return iSuccess ? (szCmdArg[0] == '!' ? Plugin_Continue : Plugin_Handled) : Plugin_Continue;
	}
	
	return Plugin_Continue;
}

AddToAdminNames(client)
{
	g_iLen += FormatEx(g_szAdminString[g_iLen], sizeof(g_szAdminString) - g_iLen, "%s%N", g_iAdd ? ", " : "", client);
	g_iAdminsCount++;

	switch(g_iAdd)
	{
		case 0:	g_iAdd = 1;
	}
}

RebuildAdminString()
{
	g_iLen = 0; g_iAdd = 0; g_iAdminsCount = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientAdmin(i))
		{
			AddToAdminNames(i);
		}
	}
}

ShowOnlineAdmins(client)
{
	PrintToChat(client, " Total Online \x03Admins\x01: \x05%d\x01.", g_iAdminsCount);
	PrintToChat(client, " Online \x03ADMINS\x01: \x05%s\x01.", g_szAdminString);
}