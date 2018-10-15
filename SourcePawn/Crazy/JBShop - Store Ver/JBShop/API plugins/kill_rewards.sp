#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <store>
#include <jail_shop>
#include <daysapi>
#include <cstrike>
#include <simonapi>

public Plugin myinfo = 
{
	name = "Prisoner Kill Credit", 
	author = PLUGIN_AUTHOR, 
	description = "Gives credits for killing guards", 
	version = PLUGIN_VERSION, 
	url = "No URL"
};

ConVar ConVar_CTKillCredits;
int g_iCTKillCredits;

ConVar ConVar_SimonKillCredits;
int g_iSimonKillCredits;

public void OnPluginStart()
{
	HookConVarChange((ConVar_CTKillCredits = CreateConVar("ct_kill_credits", "5")), ConVarChangeHook);
	g_iCTKillCredits = ConVar_CTKillCredits.IntValue;
	HookConVarChange((ConVar_SimonKillCredits = CreateConVar("simon_kill_credits", "5")), ConVarChangeHook);
	g_iSimonKillCredits = ConVar_SimonKillCredits.IntValue;
	
	HookEvent("player_death", Event_PlayerDeath);
	
	AutoExecConfig(true, "kill_rewards");
}

public void ConVarChangeHook(ConVar convar, const char[] szOldValue, const char[] szNewValue)
{
	if(convar == ConVar_CTKillCredits)
	{
		g_iCTKillCredits = StringToInt(szNewValue);
	}
	
	else if(convar == ConVar_SimonKillCredits)
	{
		g_iSimonKillCredits = StringToInt(szNewValue);
	}
}

public void Event_PlayerDeath(Event hEvent, char[] szEvent, bool bDontBroadcast)
{
	if (DaysAPI_IsDayRunning())
	{
		return;
	}
	
	int iKiller = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!(0 < iKiller <= MaxClients) || iKiller == iVictim || !IsClientInGame(iKiller))
	{
		return;
	}
	
	int iVictimTeam = GetClientTeam(iVictim);
	int iKillerTeam = GetClientTeam(iKiller);
	if (iVictimTeam == iKillerTeam)
	{
		return;
	}
	
	if (iVictimTeam != CS_TEAM_CT)
	{
		return;
	}
	
	char szCurrency[25];
	Store_GetCurrencyName(szCurrency, sizeof szCurrency);
	if(SimonAPI_GetSimon() == iVictim)
	{
		CPrintToChat(iKiller, "\x01You gained\x05 %d %s\x01 for killing the \x07Simon", g_iSimonKillCredits, szCurrency);
		JBShop_GiveCredits(iKiller, g_iSimonKillCredits, false, "Kill Simon");
	}
	
	else
	{
		CPrintToChat(iKiller, "\x01You gained\x05 %d %s\x01 for killing a \x07CT", g_iCTKillCredits, szCurrency);
		JBShop_GiveCredits(iKiller, g_iCTKillCredits, false, "Kill CT");
	}
}

