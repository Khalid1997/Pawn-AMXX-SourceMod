#pragma semicolon 1 
#pragma newdecls required

#include <sourcemod> 
#include <jail_shop>

public Plugin myinfo =  
{ 
    name = "Round win earn credit", 
    author = "Haider", 
    description = "", 
    version = "1.0", 
    url = "" 
}; 

ConVar ConVar_Bonus;

public void OnPluginStart() 
{ 
    HookEvent("round_end", Event_RoundEnd);
    
    ConVar_Bonus = CreateConVar("jailshop_roundwin_bonus", "150", "Bonus credits given to prisoners for winning the round");
    ConVar_Bonus.AddChangeHook(ConVar_ChangeHook);
} 

public void OnMapStart()
{
	AutoExecConfig(true, "jailshop_roundwin_bonus");	
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
	int iWinningTeam = GetEventInt(hEvent, "winner");
	
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
			JBShop_SetCredits(client, JBShop_GetCredits(client) + iCvarBonus);
		}
	}
	
	PrintToChatAll(" \x05All \x03Prisoners \x05have been awarded \x03%d \x05credits for winning the round!", iCvarBonus);
}