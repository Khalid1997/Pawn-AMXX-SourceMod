#pragma semicolon 1 
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <jail_shop>

#undef REQUIRE_PLUGIN
#include <daysapi>
#include <myjailbreak>

public Plugin myinfo =  
{ 
    name = "Round win earn credit", 
    author = "Haider", 
    description = "", 
    version = "1.0", 
    url = "" 
}; 

bool g_bDaysAPI;
bool g_bMyJailBreak;


ConVar ConVar_Bonus;

public void OnPluginStart() 
{ 
    HookEvent("round_end", Event_RoundEnd);
    
    ConVar_Bonus = CreateConVar("jailshop_roundwin_bonus", "150", "Bonus credits given to prisoners for winning the round");
    ConVar_Bonus.AddChangeHook(ConVar_ChangeHook);
    
    AutoExecConfig(true, "win_credit");
}

public void OnAllPluginsLoaded()
{
	g_bDaysAPI = LibraryExists("daysapi");
	g_bMyJailBreak = LibraryExists("myjailbreak");
}

public void OnLibraryAdded(const char[] szName)
{
	if (StrEqual(szName, "daysapi"))
	{
		g_bDaysAPI = true;
	}
	
	else if( StrEqual(szName, "myjailbreak"))
	{
		g_bMyJailBreak = true;
	}
}

public void OnLibraryRemoved(const char[] szName)
{
	if (StrEqual(szName, "daysapi"))
	{
		g_bDaysAPI = false;
	}
	
	else if( StrEqual(szName, "myjailbreak"))
	{
		g_bMyJailBreak = false;
	}
}

public void ConVar_ChangeHook(ConVar hVar, char[] szOldValue, char[] szNewValue)
{
	int iNewValue = StringToInt(szNewValue);
	
	if(iNewValue < 0)
	{
		iNewValue *= -1;
		ConVar_Bonus.IntValue = iNewValue;
	}
}

public void Event_RoundEnd(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	if (g_bDaysAPI && DaysAPI_IsDayRunning())
	{
		return;
	}
	
	else if(g_bMyJailBreak && MyJailbreak_IsEventDayRunning())
	{
		return;
	}
	
	int iWinningTeam = GetEventInt(hEvent, "winner");
	//PrintToServer("Winning team: %d", iWinningTeam);
	
	char szWinMessage[256];
	//GetEventString(hEvent, "reason", szWinMessage, sizeof szWinMessage);
	//PrintToServer("Reason: %s", szWinMessage);
	
	GetEventString(hEvent, "message", szWinMessage, sizeof szWinMessage);
	//PrintToServer("Message: %s", szWinMessage);
	
	#define _CS_TEAM_T		2
	
	if(iWinningTeam != _CS_TEAM_T)
	{
		return;
	}
	
	if(!StrEqual(szWinMessage, "#SFUI_Notice_Terrorists_Win"))
	{
		return;
	}
	
	int iCvarBonus = ConVar_Bonus.IntValue;
	for (int client = 1; client <= MaxClients; client++)
	{
		if( IsClientInGame(client) && GetClientTeam(client) == _CS_TEAM_T )
		{
			JBShop_GiveCredits(client, iCvarBonus, true, "Round Win");
		}
	}
	
	CPrintToChatAll("\x05All \x03Prisoners \x05have been awarded \x03%d \x05credits for winning the round!", iCvarBonus);
}