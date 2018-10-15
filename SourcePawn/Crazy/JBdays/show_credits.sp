#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <jail_shop>
#include <store>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Show Credits",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

bool g_bLate = false;
int g_iLastRoundCredits[MAXPLAYERS], g_iThisRoundCredits[MAXPLAYERS], g_iTotalCreditsThisMap[MAXPLAYERS], g_iPlayerCredits[MAXPLAYERS];

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int ErrorMax)
{
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_showcredits", ConCmd_ShowCredits, ADMFLAG_ROOT);
	HookEvent("round_start", Event_RoundStart);
}

public Action ConCmd_ShowCredits(int client, int args)
{
	ReplyToCommand(client, "* Check Console for results.");
	char szName[17];
	PrintToConsole(client, "----------------------------------------------");
	PrintToConsole(client, "%-16s %-10s %-10s %-10s %-10s", "Name", "ThisRound", "LastRound", "Total", "CurrCredits");
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		GetClientName(i, szName, sizeof szName);
		int iLen = strlen(szName); 
		int iMBLen;
		if(iLen == (iMBLen = StrLenMB2(szName)))
		{
			PrintToConsole(client, "%-16s %-10d %-10d %-10d %-10d", szName, 
			g_iThisRoundCredits[i], g_iLastRoundCredits[i], g_iTotalCreditsThisMap[i], 
			g_iPlayerCredits[i]);
		}
		
		else
		{
			char szFmt[32];
			FormatEx(szFmt, sizeof szFmt, szName);
			AppendSpace(szFmt, sizeof szFmt, iLen, iMBLen, 16);
			
			PrintToConsole(client, "%-16s %-10d %-10d %-10d %-10d", szFmt, 
			g_iThisRoundCredits[i], g_iLastRoundCredits[i], g_iTotalCreditsThisMap[i], 
			g_iPlayerCredits[i]);
		}
	}
	PrintToConsole(client, "----------------------------------------------");
	return Plugin_Handled;
}

void AppendSpace(char[] szBuffer, int iSize, int iLen, int iMBLen, int iJustify)
{
	int iCount = iJustify - iMBLen;
	while(iCount-- && iLen < iSize)
	{
		szBuffer[iLen++] = ' ';
	}
	
	if(iLen < iSize)
	{
		szBuffer[iLen] = 0;
	}
}

stock int StrLenMB2(const char[] str)
{
    int len = strlen(str);
    int count;
    int bytes;
    
    for(int i; i < len; i++)
    {
        bytes = IsCharMB(str[i]);
        
        if(bytes > 0)
        {
            i += (bytes - 1);
        } 
        
        count ++;
    }
    
    
    return count;
}  

public void OnMapStart()
{
	if(g_bLate)
	{
		g_bLate = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
	
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		g_iThisRoundCredits[i] = 0;
		g_iLastRoundCredits[i] = 0;
		g_iTotalCreditsThisMap[i] = 0;
	}
}

public void OnClientPutInServer(int client)
{
	Store_GetCredits(GetSteamAccountID(client), GetCreditsCallback, client);
}

public void GetCreditsCallback(int credits, int client)
{
	g_iPlayerCredits[client] = credits;
}

public void JBShop_OnCreditChange(int client, int iCredits)
{
	if(iCredits > 0)
	{
		g_iThisRoundCredits[client] += iCredits;
		g_iTotalCreditsThisMap[client] += iCredits;
	}
	
	g_iPlayerCredits[client] += iCredits;
}


public void Event_RoundStart(Event event, const char[] szEventName, bool bDontbroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iLastRoundCredits[i] = g_iThisRoundCredits[i];
		g_iThisRoundCredits[i] = 0;
	}
}
