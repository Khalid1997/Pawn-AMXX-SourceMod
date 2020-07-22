#if defined _daysapi_included_
	#endinput
#endif
#define _daysapi_included_

#include <sourcemod>

#define MAX_INTERNAL_NAME_LENGTH	32
#define MAX_DISPLAY_NAME_LENGTH		32
#define MAX_WINNER_GROUP_NAME_LENGTH 32

#define No_Day -1
#define No_Day_Keyword "none"

enum DayStartReturn
{
	DSR_Success = 0,
	DSR_Stop
};

forward void DaysAPI_OnDayAdded(char[] szInternalName);
forward void DaysAPI_OnDayRemoved(char[] szInternalName);

forward DayStartReturn DaysAPI_OnDayStart_Pre(char[] szInternalName, bool bWasPlanned, any data);
forward void DaysAPI_OnDayStart(char[] szInternalName, bool bWasPlanned, any data);

forward void DaysAPI_OnDayEnd_Pre(char[] szInternalName, any data);
forward void DaysAPI_OnDayEnd(char[] szInternalName, any data);

forward void DaysAPI_OnAddPlannedDay(char[] szInternalName);
forward void DaysAPI_OnCancelPlannedDay(char[] szInternalName);

// Return data is passed to the forwards
enum DayStartState	(+= -1)
{
	DSS_Success,
	DSS_Failure_AlreadyRunning,		// Day is already running
	DSS_Failure_DayRunning,			// Another day is running (And this day only wants to start a solo day)
	DSS_Failure_RoundEnd,				// Round is ending, can't start
	DSS_Failure_Halted,				// A plugin halted the start
	DSS_Failure_StartPrepareOnly		// Can only be started by preparing (new round)
};

typeset DayStartFunction
{
	function DayStartReturn();
	function DayStartReturn(bool bWasPlanned);
	function DayStartReturn(bool bWasPlanned, any data);
}

typeset DayEndFunction
{
	function void();
	function void(any data);
}

native void DaysAPI_AddDay(char [] szInternalName, 
							DayStartFunction StartDayFunc = INVALID_FUNCTION, DayEndFunction EndDayFunction = INVALID_FUNCTION);
native bool DaysAPI_RemoveDay(char [] szInternalName);

enum DayInfo
{
	DayInfo_DisplayName,	// Set char[], Get char[], size
	DayInfo_Flags	// See below, Set int, Get int
};

enum DayFlag (<<= 1)
{
	DayFlag_NoFlags = 0,
	DayFlag_Disabled = 1,			// Disable This day
	DayFlag_StartPrepareOnly,		// Day can only be started at a new round start
	DayFlag_StartAlone,				// No days can be started alongside this one
	DayFlag_NoEndRoundEnd,		 		// Will not end at round end and will only end when DaysAPI_EndDay is called or Map End.
	DayFlag_EndTerminateRound,		// Terminate the round when DaysAPI_EndDay is called for that day
	DayFlag_CanStartAtRoundEnd,		// Ignore round end and start regardless.
	DayFlag_HealingAllowed,			// Allow healing during that day
	DayFlag_DontDisplayPanel
};

native void DaysAPI_GetDayInfo(char[] szInternalName, DayInfo info, any & ...);
native void DaysAPI_SetDayInfo(char[] szInternalName, DayInfo info, any ...);

native DayStartState DaysAPI_StartDay(char[] szInternalName, any data = INVALID_HANDLE);
native bool DaysAPI_EndDay(char[] szInternalName, any data = INVALID_HANDLE);
native void DaysAPI_EndAllDays();

// szWinnersTag is to allow multiple groups of winners.
// Maximums size of the array is MAXPLAYERS
typedef GetDayWinnersGroupCallback = function void(char[] szInternalName, char[] szGroupName, int[] ArrayPlayers, int iCount, any data);
native void DaysAPI_GetDayWinnersGroups(GetDayWinnersGroupCallback func, any data = INVALID_HANDLE);
native void DaysAPI_SetDayWinners(char[] szWinnersTag, int[] ArrayPlayers, int iCount);	// Return true - success, false - fail
native int DaysAPI_GetDayWinners(char[] szWinnersTag, int[] ArrayPlayers, int iSize);	// Return is actual number of players
native void DaysAPI_ResetDayWinners(); // Clears everything;

// Cancel Planned Day
// A planned day is a day that will start next round.
native void DaysAPI_AddPlannedDay(char[] szInternalName);
native bool DaysAPI_CancelPlannedDay(char[] szInternalName);
native void DaysAPI_CancelAllPlannedDays();

// boolean return is to whether add the day to the total returned count or not
typedef GetDaysFilterFunction = function bool(char[] szInternalName, char[] szDisplayName, DayFlag flags, any data);
native int DaysAPI_GetDays(GetDaysFilterFunction func, bool bAddDisabled = true, any data = INVALID_HANDLE);
native int DaysAPI_GetRunningDays(GetDaysFilterFunction func, any data = INVALID_HANDLE);
native int DaysAPI_GetPlannedDays(GetDaysFilterFunction func, any data = INVALID_HANDLE);

// Empty string will just check if any day is running or planned and return is count;
// else return is 1 or 0 if its planned/running or not
native int DaysAPI_IsDayPlanned(char[] szPlannedDayIntName = "");
native int DaysAPI_IsDayRunning(char[] szRunningDayIntName = "");

native void DaysAPI_ShowDayPanel(int[] clients, int size, int iDuration, char[] szInternalName);
stock void DaysAPI_ShowDayPanelAll(int iDuration, char[] szInternalName)
{
	int clients[MAXPLAYERS];
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			clients[count++] = i;
		}
	}
	
	DaysAPI_ShowDayPanel(clients, count, szInternalName);
}

stock void DaysAPI_ShowDayPanelEx(int client, int iDuration, char[] szInternalName)
{
	int clients[1];
	clients[0] = client;
	DaysAPI_ShowDayPanel(clients, 1, szInternalName);
}

stock int DaysAPI_RegisterChatCommands(ArrayList Commands, Function CallbackFunction, int iAdminFlags = 0, bool bAppendSM = true)
{
	char szCommandString[32];
	int iRegisteredCommands;
	for (int i; i < Commands.Length; i++)
	{
		int iLen;
		if(bAppendSM)
		{
			iLen = FormatEx(szCommandString, sizeof szCommandString, "sm_");
		}
		
		Commands.GetString(szCommandString, szCommandString[iLen], sizeof(szCommandString) - iLen);
		if(AdminAccess > 0)
		{
			iRegisteredCommands++;
			RegAdminCmd(szCommandString, CallbackFunction, iAdminFlags);
		}
		
		else
		{
			iRegisteredCommands++;
			RegConsoleCmd(szCommandString, CallbackFunction);
		}
	}
	
	return iRegisteredCommands;
}

stock void DaysAPI_GetStartFailureReason(DayStartReturn ret, char[] szString, int size)
{
	switch(ret)
	{
		case DayStart_Failure_AlreadyRunning:
		{
			FormatEx(szString, size, "* This day is already running");
		}
		
		case DayStartState_Failure_DayRunning:
		{
			FormatEx(szString, size, "* Another day is already running");
		}
		
		case DayStartState_Failure_Halted:
		{
			FormatEx(szString, size, "* Another plugin stopped the Day from running");
		}
		case DayStart_Failure_StartPrepareOnly:
		{
			FormatEx(szString, size, "* This day can only start at a new round");
		}
		case DayStart_RoundEnd:
		{
			FormatEx(szString, size, "* You can't start at round end");
		}
	}
}

public SharedPlugin __pl_daysapi =
{
	name = "daysapi",
	file = "daysapi.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_daysapi_SetNTVOptional()
{
	MarkNativeAsOptional("DaysAPI_AddDay");
	MarkNativeAsOptional("DaysAPI_RemoveDay");
	
	MarkNativeAsOptional("DaysAPI_GetDayInfo");
	MarkNativeAsOptional("DaysAPI_SetDayInfo");
	
	MarkNativeAsOptional("DaysAPI_StartDay");
	MarkNativeAsOptional("DaysAPI_EndDay");
	MarkNativeAsOptional("DaysAPI_EndAllDays");
	
	MarkNativeAsOptional("DaysAPI_GetDayWinnersGroups");
	MarkNativeAsOptional("DaysAPI_SetDayWinners");
	MarkNativeAsOptional("DaysAPI_GetDayWinners");
	MarkNativeAsOptional("DaysAPI_ResetDayWinners");
	
	MarkNativeAsOptional("DaysAPI_AddPlannedDay");
	MarkNativeAsOptional("DaysAPI_CancelPlannedDay");
	MarkNativeAsOptional("DaysAPI_CancelAllPlannedDays");
	
	MarkNativeAsOptional("DaysAPI_GetDays");
	MarkNativeAsOptional("DaysAPI_GetRunningDays");
	MarkNativeAsOptional("DaysAPI_GetPlannedDays");	
	
	//MarkNativeAsOptional("DaysAPI_GetRunningDaysCount");
	//MarkNativeAsOptional("DaysAPI_GetPlannedDaysCount");
	
	MarkNativeAsOptional("DaysAPI_IsDayPlanned");
	MarkNativeAsOptional("DaysAPI_IsDayRunning");
	
	MarkNativeAsOptional("DaysAPI_ShowDayPanel");
}
#endif