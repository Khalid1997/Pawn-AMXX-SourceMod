#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <multicolors>

char FILE_URL_PATH[] = "http://khaleejigaming.com/webshortcuts_f.html";

public Plugin myinfo = 
{
	name = "VIP List and MOTD",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "No URL"
};

ConVar ConVar_VIPFlags, ConVar_VIPMOTDLink;

public void OnPluginStart()
{
	AddCommandListener(ChatCmdCallback, "say");
	AddCommandListener(ChatCmdCallback, "say_team");
	
	ConVar_VIPFlags = CreateConVar("vip_flags", "ot");
	ConVar_VIPMOTDLink = CreateConVar("vip_motd_link", "http://khaleejigaming.com/buyvip.html");
}

public Action ChatCmdCallback(int client, const char[] command, int argc)
{
	char szStuff[32];
	GetCmdArg(1, szStuff, sizeof szStuff);
	
	if(StrEqual(szStuff[1], "vip", false))
	{
		ShowVIPMotdLink(client);
	}
	
	else if(StrEqual(szStuff[1], "vips", false))
	{
		PrintOnlineVIPs(client);
	}

	return szStuff[0] == '/' ? Plugin_Handled : Plugin_Continue;
}

void ShowVIPMotdLink(client)
{
	char szURL[512];
	GetConVarString(ConVar_VIPMOTDLink, szURL, sizeof(szURL));
	
	FixMotdCSGO(szURL);
	ShowMOTDPanel(client, "Buy VIP", szURL, MOTDPANEL_TYPE_URL);
}

stock FixMotdCSGO(String:web[512], String:title[256] = "")
{
	Format(web, sizeof(web), "%s?web=%s", FILE_URL_PATH, web);
}

void PrintOnlineVIPs(client)
{
	char szPrintMessage[192];
	int iLen = FormatEx(szPrintMessage, sizeof szPrintMessage, " \x03VIPs Online: \x05");
	
	bool bGotFirst = false;
	char szName[MAX_NAME_LENGTH];
	
	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientVIP(i))
		{
			iCount++;
			GetClientName(i, szName, sizeof(szName));
			iLen += FormatEx(szPrintMessage[iLen], sizeof(szPrintMessage) - iLen,
			"%s\x05%s", bGotFirst ? "\x06," : "", szName);
			bGotFirst = true;
		}
	}
	
	if(!iCount)
	{
		iLen += FormatEx(szPrintMessage[iLen], sizeof(szPrintMessage) - iLen, "\x05No VIPs Online.");
	}
	
	else
	{
		iLen += FormatEx(szPrintMessage[iLen], sizeof(szPrintMessage) - iLen, ".");
	}
	
	CPrintToChat(client, szPrintMessage);
}

bool IsClientVIP(client)
{
	char szFlags[16];
	GetConVarString(ConVar_VIPFlags, szFlags, sizeof(szFlags));
	
	int iDump;
	int iFlags = ReadFlagString(szFlags, iDump);
	if( (GetUserFlagBits(client) &  iFlags ) == iFlags )
	{
		return true;
	}
	
	return false;
}
