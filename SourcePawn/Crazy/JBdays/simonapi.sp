#pragma semicolon 1 
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <simonapi>
#include <multicolors>

#undef REQUIRE_PLUGIN
	#include <daysapi>
#define REQUIRE_PLUGIN

public Plugin myinfo =  
{ 
    name = "SimonAPI", 
    author = "Khalid", 
    description = "Natives for plugins using Simon functionality", 
    version = "1.0", 
    url = "" 
}; 

#define ADMIN_ACCESS	ADMFLAG_BAN

int g_iSimonId = No_Simon;
Handle g_hForward;

char SIMON_NAME_C[] = "\x05Simon";
bool g_bRetireEnabled = true;

//bool g_bDaysAPI;

public APLRes AskPluginLoad2(Handle plugin, bool bLate, char[] error, int err_max)
{
	RegPluginLibrary("simonapi");
	
	CreateNative("SimonAPI_GetSimon", Native_GetSimonId);
	CreateNative("SimonAPI_SetSimon", Native_SetSimonId);
	CreateNative("SimonAPI_HasAccess", Native_HasAccess);
	
	g_hForward = CreateGlobalForward("SimonAPI_OnSimonChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] szName)
{
	if(StrEqual(szName, "daysapi"))
	{
		//g_bDaysAPI = true;
	}
}

public void OnLibraryRemoved(const char[] szName)
{
	if(StrEqual(szName, "daysapi"))
	{
		//g_bDaysAPI = false;
	}
}

public void OnAllPluginsLoaded()
{
	//g_bDaysAPI = LibraryExists("daysapi");
}

public OnPluginStart() 
{ 
	RegConsoleCmd("sm_simon", Command_Simon, ""); 
	RegConsoleCmd("sm_s", Command_Simon, ""); 
	RegConsoleCmd("sm_warden", Command_Simon, ""); 
	RegConsoleCmd("sm_w", Command_Simon, ""); 
	RegConsoleCmd("sm_retire", Command_RetireSimon, ""); 
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerChangeTeam);
} 

public void DaysAPI_OnDayStart(char[] szIntName, bool bWasPlanned, any data)
{
	if(g_iSimonId == No_Simon)
	{
		return;
	}
	
	SetSimon(No_Simon, SCR_DayStart);
}

public void OnClientDisconnect(int client)
{
	if(client == g_iSimonId)
	{
		SetSimon(No_Simon, SCR_Disconnect);
	}
}

public void Event_PlayerChangeTeam(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iNewTeam = GetEventInt(hEvent, "team");
	int iOldTeam = GetEventInt(hEvent, "oldteam");
	if(iOldTeam == CS_TEAM_CT)
	{
		if(iNewTeam != CS_TEAM_CT)
		{
			if(client == g_iSimonId)
			{
				SetSimon(No_Simon, SCR_TeamChange);
			}
		}
	}
}

public void Event_PlayerDeath(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	int iVictimUserId = GetEventInt(hEvent, "userid");
	int iVictimClientId = GetClientOfUserId(iVictimUserId);
	
	if(iVictimClientId == g_iSimonId)
	{
		SetSimon(No_Simon, SCR_Dead);
	}
}

public Action Event_RoundStart(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	SetSimon(No_Simon, SCR_RoundRestart);
}

public Action Command_RetireSimon(int client, int iArgs)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}
	
	if(iArgs >= 1)
	{
		if( !(GetUserFlagBits(client) & (ADMIN_ACCESS | ADMFLAG_ROOT)) )
		{
			return Plugin_Handled;
		}
		
		char szPatternArg[MAX_NAME_LENGTH];
		GetCmdArg(1, szPatternArg, sizeof szPatternArg);
		
		if (StrContains(szPatternArg, "disable", false) != -1)
		{
			g_bRetireEnabled = false;
			CReplyToCommand(client, "* You have \x04Disabled\x01 retiring");
			return Plugin_Handled;
		}
		
		if(StrContains(szPatternArg, "enable", false) != -1)
		{
			g_bRetireEnabled = false;
			CReplyToCommand(client, "* You have \x04Enabled \x01retiring");
			return Plugin_Handled;
		}
		
		if(StrContains(szPatternArg, "simon", false) != -1)
		{
			if(g_iSimonId == No_Simon)
			{
				CReplyToCommand(client, "* There is no one to retire.");
				return Plugin_Handled;
			}
			
			int iOldSimonId = g_iSimonId;
			SetSimon(No_Simon, SCR_Retire);
			
			CPrintToChatAll("ADMIN \x05%N\x01 has retired the %s (%N)\x01!", client, SIMON_NAME_C, iOldSimonId);
			return Plugin_Handled;
		}
		
		CReplyToCommand(client, "\x04* \x01sm_retire <enable/disable/simon>");
		return Plugin_Handled;
	}
	
	if(!g_bRetireEnabled)
	{
		CPrintToChat(client, "* Retiring is disabled.");
		return Plugin_Handled;
	}
	
	if(g_iSimonId == No_Simon)
	{
		return Plugin_Handled;
	}
	
	if(g_iSimonId != client)
	{
		CReplyToCommand(client, "\x04* You are not the %s\x04.", SIMON_NAME_C);
		return Plugin_Handled;
	}
	
	int iOldSimonId = g_iSimonId;
	SetSimon(No_Simon, SCR_Retire);
	CReplyToCommand(client, "\x04* You have retired from being %s\x04.", SIMON_NAME_C);
	PrintToChatAll("* The %s (%N)\x01 has retired! The position is available to any Guards by typing \x07!simon\x01.", SIMON_NAME_C, iOldSimonId);
	
	return Plugin_Handled;
}

public Action Command_Simon(int client, int args) 
{ 
	if(client == 0)
	{
		return Plugin_Handled;
	}

	bool bAssignedByAdmin = false;
	int iNewSimonId = client; // Player by default, unless it is an admin setting a new simon;

	char szSimonName[MAX_NAME_LENGTH];
	if(args >=  1)
	{
		if( (GetUserFlagBits(client) & (ADMIN_ACCESS | ADMFLAG_ROOT)) )
		{
			char szPatternArg[MAX_NAME_LENGTH];
			bool bIsML;
			int iTargets[MAXPLAYERS];
			GetCmdArg(1, szPatternArg, sizeof szPatternArg);
			
			int iTargetCount = ProcessTargetString(szPatternArg, 0, iTargets, sizeof iTargets,
						COMMAND_FILTER_CONNECTED, szSimonName, sizeof szSimonName, bIsML);
			
			if(iTargetCount > 1 || !iTargetCount)
			{
				CReplyToCommand(client, "* Couldn't find specific target with pattern \x04'%s'", szPatternArg);
				return Plugin_Handled;
			}
			
			iNewSimonId = iTargets[0];
			if(!IsPlayerAlive(iNewSimonId) || GetClientTeam(iNewSimonId) != CS_TEAM_CT )
			{
				CReplyToCommand(client, "* Player %s is not alive or is not in team \x04CT", szSimonName);
				return Plugin_Handled;
			}
			
			bAssignedByAdmin = true;
		}
	}
	
	if(g_iSimonId != No_Simon)
	{
		CReplyToCommand(client, "* A %s \x01has already been assigned. The current %s \x01is \x05%N", SIMON_NAME_C, SIMON_NAME_C, g_iSimonId);
		return Plugin_Continue;
	}
	
	if(!SetSimon(iNewSimonId, SCR_Generic))
	{
		CReplyToCommand(client, " \x05You must be CT and ALIVE in order to be a simon."); 
		return Plugin_Handled;
	}
	
	if(bAssignedByAdmin)
	{
		CReplyToCommand(client, "* You have selected \x04%s\x01 as the new %s\x01.", szSimonName, SIMON_NAME_C);
		CPrintToChatAll("ADMIN \x04%N\x01 selected \x04%s\x01 as the new %s\x01!", client, szSimonName, SIMON_NAME_C);
	}
	
	CReplyToCommand(iNewSimonId, "\x01* You have been selected as %s\x01. You can type \x03!retire\x01 to retire.", SIMON_NAME_C);
	return Plugin_Handled;
}  

public int Native_GetSimonId(Handle hPlugin, int args)
{
	return g_iSimonId;
}

public int Native_SetSimonId(Handle hPlugin, int args)
{
	return SetSimon(GetNativeCell(1), GetNativeCell(2));
}

int SetSimon(int client, SimonChangedReason iReason)
{
	int iOldSimon = g_iSimonId;
	
	if(client == No_Simon)
	{
		g_iSimonId = client;
	}
		
	else if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_CT) 
	{
    	return 0;
	}
	
	else
	{
		g_iSimonId = client;
	}
	
	Call_StartForward(g_hForward);
	Call_PushCell(g_iSimonId);
	Call_PushCell(iOldSimon);
	Call_PushCell(iReason);
	Call_Finish();
	
	return 1;
}

public int Native_HasAccess(Handle hPlugin, int argc)
{
	AccessType iAccess;
	CanAccessCommandClient(GetNativeCell(1), GetNativeCell(2), iAccess);
	return view_as<int>(iAccess);
}

bool CanAccessCommandClient(int client, bool bAllowSimon, AccessType &iAccess)
{
	bool bAccess = false;
	iAccess = AT_NoAccess;
	if (bAllowSimon && SimonAPI_GetSimon() == client)
	{
		bAccess = true;
		iAccess = AT_Simon;
	}
	
	else if (GetUserFlagBits(client) & ( ADMIN_ACCESS | ADMFLAG_ROOT ) )
	{
		bAccess = true;
		iAccess = AT_Admin;
	}
	
	return bAccess;
}