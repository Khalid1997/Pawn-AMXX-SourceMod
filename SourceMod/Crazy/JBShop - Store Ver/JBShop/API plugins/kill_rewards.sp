#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <multicolors>
#include <jail_shop>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <myjailbreak>
#include <daysapi>
#include <simonapi>
#include <warden>

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

bool g_bDaysAPI;
bool g_bMyJailBreak;
bool g_bSimonAPI;

public void OnPluginStart()
{
	HookConVarChange((ConVar_CTKillCredits = CreateConVar("ct_kill_credits", "5")), ConVarChangeHook);
	g_iCTKillCredits = ConVar_CTKillCredits.IntValue;
	HookConVarChange((ConVar_SimonKillCredits = CreateConVar("simon_kill_credits", "5")), ConVarChangeHook);
	g_iSimonKillCredits = ConVar_SimonKillCredits.IntValue;
	
	HookEvent("player_death", Event_PlayerDeath);
	
	AutoExecConfig(true, "kill_rewards");
}

public void OnAllPluginsLoaded()
{
	g_bDaysAPI = LibraryExists("daysapi");
	g_bMyJailBreak = LibraryExists("myjailbreak");
	g_bSimonAPI = LibraryExists("simonapi");
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
	
	else if( StrEqual(szName, "simonapi") )
	{
		g_bSimonAPI = true;
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
	
	else if( StrEqual(szName, "simonapi") )
	{
		g_bSimonAPI = false;
	}
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
	if (g_bDaysAPI && DaysAPI_IsDayRunning())
	{
		return;
	}
	
	else if(g_bMyJailBreak && MyJailbreak_IsEventDayRunning())
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
	
	if( ( g_bMyJailBreak && warden_iswarden(iVictim) ) || ( g_bSimonAPI && SimonAPI_GetSimon() == iVictim ) )
	{
		CPrintToChat(iKiller, "\x01You gained\x05 %d credits\x01 for killing the \x07Simon", g_iSimonKillCredits);
		JBShop_GiveCredits(iKiller, g_iSimonKillCredits, false, "Kill Simon");
	}
	
	else
	{
		CPrintToChat(iKiller, "\x01You gained\x05 %d credits\x01 for killing a \x07CT", g_iCTKillCredits);
		JBShop_GiveCredits(iKiller, g_iCTKillCredits, false, "Kill CT");
	}
}

