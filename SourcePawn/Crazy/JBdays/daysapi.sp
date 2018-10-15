#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <multicolors>
#include <daysapi>

#undef REQUIRE_PLUGIN
#include <hosties>
#include <simonapi>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "DaysAPI: Core", 
	author = "Khalid", 
	description = "Natives for days handling", 
	version = "1.0", 
	url = ""
};

char g_szPanelsTextPath[] = "cfg/sourcemod/daysapi/daysapi_panel.ini";

ConVar ConVar_RandomDayRounds, 
ConVar_DisableMedic, 
ConVar_NativeStartResetRounds;

bool g_bHostiesRunning, 
g_bRoundEnd;

bool g_bHealDisabled = false;

int g_iRoundNumber = 0;
//			g_iRandomArraySize = 0;

Handle g_Forward_OnEventDayStart_Pre, 
g_Forward_OnEventDayStart, 

g_Forward_OnEventDayEnd_Pre, 
g_Forward_OnEventDayEnd, 

g_Forward_OnAddPlannedDay, 
g_Forward_OnRemovePlannedDay, 

g_Forward_OnEventDayAdded, 
g_Forward_OnEventDayRemoved;


ArrayList g_Array_InternalNames, 
g_Array_DataPacks, 
g_Array_DisplayNames, 
g_Array_Flags, 
g_Array_RunningDays, 
g_Array_PlannedDays;

// SetDayWinner Stuff
ArrayList g_Array_WinnersGroups = null;
ArrayList g_Array_WinnersList = null;
ArrayList g_Array_WinnersListCount = null;
char g_szCurrentEndingDay[MAX_INTERNAL_NAME_LENGTH];

// Hosites Stuff
ConVar Cvar_sm_hosties_announce_rebel_down;
ConVar Cvar_sm_hosties_rebel_color;
ConVar Cvar_sm_hosties_mute;
ConVar Cvar_sm_hosties_announce_attack;
ConVar Cvar_sm_hosties_announce_wpn_attack;
ConVar Cvar_sm_hosties_freekill_notify;
ConVar Cvar_sm_hosties_freekill_treshold;

int OldCvar_sm_hosties_rebel_color;
int OldCvar_sm_hosties_announce_rebel_down;
int OldCvar_sm_hosties_mute;
int OldCvar_sm_hosties_announce_attack;
int OldCvar_sm_hosties_announce_wpn_attack;
int OldCvar_sm_hosties_freekill_notify;
int OldCvar_sm_hosties_freekill_treshold;

// Register Natives
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Game is not supported. CS:GO ONLY");
	}
	
	CreateNative("DaysAPI_AddDay", Native_AddDay);
	CreateNative("DaysAPI_RemoveDay", Native_RemoveDay);
	
	CreateNative("DaysAPI_GetDayInfo", Native_GetDayInfo);
	CreateNative("DaysAPI_SetDayInfo", Native_SetDayInfo);
	
	CreateNative("DaysAPI_GetDays", Native_GetDays);
	
	CreateNative("DaysAPI_IsDayRunning", Native_IsDayRunning);
	CreateNative("DaysAPI_IsDayPlanned", Native_IsDayPlanned);
	
	CreateNative("DaysAPI_GetRunningDays", Native_GetRunningDays);
	CreateNative("DaysAPI_GetPlannedDays", Native_GetPlannedDays);
	
	//CreateNative("DaysAPI_GetRunningDaysCount", Native_GetRunningDaysCount);
	//CreateNative("DaysAPI_GetPlannedDaysCount", Native_GetPlannedDaysCount);
	
	CreateNative("DaysAPI_StartDay", Native_StartDay);
	CreateNative("DaysAPI_EndDay", Native_EndDay);
	CreateNative("DaysAPI_EndAllDays", Native_EndAllDays);
	
	CreateNative("DaysAPI_AddPlannedDay", Native_AddPlannedDay);
	CreateNative("DaysAPI_CancelPlannedDay", Native_CancelPlannedDay);
	CreateNative("DaysAPI_CancelAllPlannedDays", Native_CancelAllPlannedDays);
	
	//CreateNative("DaysAPI_HasAccess", Native_HasAccess);
	
	CreateNative("DaysAPI_ShowDayPanel", Native_ShowDayPanel);
	
	CreateNative("DaysAPI_ResetDayWinners", Native_ResetDayWinners);
	CreateNative("DaysAPI_SetDayWinners", Native_SetDayWinners);
	CreateNative("DaysAPI_GetDayWinners", Native_GetDayWinners);
	CreateNative("DaysAPI_GetDayWinnersGroups", Native_GetDayWinnersGroups);
	
	g_Forward_OnEventDayAdded = CreateGlobalForward("DaysAPI_OnDayAdded", ET_Ignore, Param_String);
	g_Forward_OnEventDayRemoved = CreateGlobalForward("DaysAPI_OnDayRemoved", ET_Ignore, Param_String);
	
	g_Forward_OnEventDayStart = CreateGlobalForward("DaysAPI_OnDayStart", ET_Ignore, Param_String, Param_Cell, Param_Cell);
	g_Forward_OnEventDayStart_Pre = CreateGlobalForward("DaysAPI_OnDayStart_Pre", ET_Event, Param_String, Param_Cell, Param_Cell);
	
	g_Forward_OnEventDayEnd = CreateGlobalForward("DaysAPI_OnDayEnd", ET_Ignore, Param_String, Param_Cell);
	g_Forward_OnEventDayEnd_Pre = CreateGlobalForward("DaysAPI_OnDayEnd_Pre", ET_Ignore, Param_String, Param_Cell);
	
	g_Forward_OnAddPlannedDay = CreateGlobalForward("DaysAPI_OnAddPlannedDay", ET_Ignore, Param_String);
	g_Forward_OnRemovePlannedDay = CreateGlobalForward("DaysAPI_OnCancelPlannedDay", ET_Ignore, Param_String);
	
	RegPluginLibrary("daysapi");
	
	return APLRes_Success;
}

// Start
public void OnPluginStart()
{	
	ConVar_RandomDayRounds = CreateConVar("days_random_rounds", "6", "0 = Disable, How many rounds in a row should pass\nwithout a day to start a random day");
	ConVar_DisableMedic = CreateConVar("days_disable_medic", "0", "0 - disabled, 1 - disable medic room when event day running, 2 = let plugins decide");
	ConVar_NativeStartResetRounds = CreateConVar("days_reset_rounds_after_start", "1");
	
	// Hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	g_Array_InternalNames = new ArrayList(MAX_INTERNAL_NAME_LENGTH);
	g_Array_DataPacks = new ArrayList(1);
	g_Array_DisplayNames = new ArrayList(MAX_DISPLAY_NAME_LENGTH);
	g_Array_Flags = new ArrayList(2);
	g_Array_RunningDays = new ArrayList(MAX_INTERNAL_NAME_LENGTH);
	g_Array_PlannedDays = new ArrayList(MAX_INTERNAL_NAME_LENGTH);
	
	g_Array_WinnersGroups = new ArrayList(MAX_WINNER_GROUP_NAME_LENGTH);
	g_Array_WinnersList = new ArrayList(MAXPLAYERS);
	g_Array_WinnersListCount = new ArrayList(1);
	
	AutoExecConfig(true, "daysapi");
}

public void OnPluginEnd()
{
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	for (int i; i < g_Array_RunningDays.Length; i++)
	{
		g_Array_RunningDays.GetString(i, szIntName, sizeof szIntName);
		
		EndDayEx(szIntName, No_Day, INVALID_HANDLE);
	}
}

public void OnAllPluginsLoaded()
{
	g_bHostiesRunning = LibraryExists("lastrequest");
}

public void OnMapStart()
{
	g_iRoundNumber = 0;
}

public void OnMapEnd()
{
	// End All days
	g_bHealDisabled = false;
	EndAllDays();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = false;
	
	if (IsDayPlanned())
	{
		char szIntName[MAX_INTERNAL_NAME_LENGTH];
		int iDayIndex;
		while (g_Array_PlannedDays.Length > 0)
		{
			g_Array_PlannedDays.GetString(0, szIntName, sizeof szIntName);
			iDayIndex = FindDayIndex(szIntName);
			g_Array_PlannedDays.Erase(0);
			
			if (iDayIndex != No_Day)
			{
				StartDay(iDayIndex, true);
			}
		}
		
		//g_iRoundNumber = 0;
		return;
	}
	
	++g_iRoundNumber;
	if (!ConVar_RandomDayRounds.IntValue)
	{
		return;
	}
	
	if (g_iRoundNumber <= ConVar_RandomDayRounds.IntValue)
	{
		return;
	}

	ArrayList array = new ArrayList(MAX_INTERNAL_NAME_LENGTH);
	array = GetDaysArrayList(false);
	if (!(array.Length))
	{
		delete array;
		return;
	}
	
	int iIndex = GetRandomInt(0, array.Length - 1);
	char szName[MAX_DISPLAY_NAME_LENGTH];
	array.GetString(iIndex, szName, sizeof szName);
	iIndex = FindDayIndex(szName);
	g_Array_DisplayNames.GetString(iIndex, szName, sizeof szName);
	
	delete array;
	
	if (StartDay(iIndex, true) == DSS_Success)
	{
		CPrintToChatAll("\x04Event Day \x03'%s' \x04was started randomly!", szName);
		g_iRoundNumber = 0;
	}
}

ArrayList GetDaysArrayList(bool bAddDisabled)
{
	ArrayList array = new ArrayList(MAX_INTERNAL_NAME_LENGTH);
	GetDays(GetMyHandle(), GetDaysToChooseRandom, bAddDisabled, array);
	return array;
}

public bool GetDaysToChooseRandom(char[] szIntName, char[] szDispName, DayFlag flags, ArrayList array)
{
	array.PushString(szIntName);
	return true;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = true;
	RequestFrame(RoundEnd_NextFrame, 0);
}

// I use next frame to allow plugins to manually end at round end and specify winners if they would like.
public void RoundEnd_NextFrame(any data)
{
	if (IsDayRunning())
	{
		char szIntName[MAX_INTERNAL_NAME_LENGTH];
		int iDayIndex;
		
		// Why didnt i just do this in a while loop ?
		for (int i; i < g_Array_RunningDays.Length; )
		{
			g_Array_RunningDays.GetString(i, szIntName, sizeof szIntName);
			iDayIndex = FindDayIndex(szIntName);
			if (iDayIndex != No_Day)
			{
				if (((g_Array_Flags.Get(iDayIndex)) & DayFlag_NoEndRoundEnd))
				{
					++i;
					continue;
				}
				
				else
				{
					EndDay(iDayIndex, INVALID_HANDLE);
				}
			}
			
			g_Array_RunningDays.Erase(i);
		}
	}
}

int IsDayRunning(char[] szIntCheckName = "")
{
	if (!szIntCheckName[0])
	{
		return (g_Array_RunningDays.Length);
	}
	
	int iSize = g_Array_RunningDays.Length;
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	
	for (int i; i < iSize; i++)
	{
		g_Array_RunningDays.GetString(i, szIntName, sizeof szIntName);
		if (StrEqual(szIntName, szIntCheckName))
		{
			return 1;
		}
	}
	
	return 0;
}

int IsDayPlanned(char[] szIntCheckName = "")
{
	if (!szIntCheckName[0])
	{
		return (g_Array_PlannedDays.Length);
	}
	
	int iSize = g_Array_PlannedDays.Length;
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	
	for (int i; i < iSize; i++)
	{
		g_Array_PlannedDays.GetString(i, szIntName, sizeof szIntName);
		if (StrEqual(szIntName, szIntCheckName))
		{
			return 1;
		}
	}
	
	return 0;
}

int FindDayIndex(char[] szCheckEventName)
{
	int iSize = g_Array_InternalNames.Length;
	
	char szEventName[MAX_INTERNAL_NAME_LENGTH];
	for (int i; i < iSize; i++)
	{
		g_Array_InternalNames.GetString(i, szEventName, sizeof szEventName);
		
		if (StrEqual(szEventName, szCheckEventName))
		{
			return i;
		}
	}
	
	return No_Day;
}

void ToggleConVars(bool IsEventDay)
{
	if (!g_bHostiesRunning)
	{
		return;
	}
	
	if (IsEventDay)
	{
		// Get the Cvar Value
		Cvar_sm_hosties_announce_rebel_down = FindConVar("sm_hosties_announce_rebel_down");
		Cvar_sm_hosties_rebel_color = FindConVar("sm_hosties_rebel_color");
		Cvar_sm_hosties_mute = FindConVar("sm_hosties_mute");
		Cvar_sm_hosties_announce_attack = FindConVar("sm_hosties_announce_attack");
		Cvar_sm_hosties_announce_wpn_attack = FindConVar("sm_hosties_announce_wpn_attack");
		Cvar_sm_hosties_freekill_notify = FindConVar("sm_hosties_freekill_notify");
		Cvar_sm_hosties_freekill_treshold = FindConVar("sm_hosties_freekill_treshold");
		
		// Save the Cvar Value
		OldCvar_sm_hosties_rebel_color = Cvar_sm_hosties_rebel_color.IntValue;
		OldCvar_sm_hosties_announce_rebel_down = Cvar_sm_hosties_announce_rebel_down.IntValue;
		OldCvar_sm_hosties_mute = Cvar_sm_hosties_mute.IntValue;
		OldCvar_sm_hosties_announce_attack = Cvar_sm_hosties_announce_attack.IntValue;
		OldCvar_sm_hosties_announce_wpn_attack = Cvar_sm_hosties_announce_wpn_attack.IntValue;
		OldCvar_sm_hosties_freekill_notify = Cvar_sm_hosties_freekill_notify.IntValue;
		OldCvar_sm_hosties_freekill_treshold = Cvar_sm_hosties_freekill_treshold.IntValue;
		
		// Change the Cvar Value
		Cvar_sm_hosties_announce_rebel_down.IntValue = 0;
		Cvar_sm_hosties_rebel_color.IntValue = 0;
		Cvar_sm_hosties_mute.IntValue = 0;
		Cvar_sm_hosties_announce_attack.IntValue = 0;
		Cvar_sm_hosties_announce_wpn_attack.IntValue = 0;
		Cvar_sm_hosties_freekill_notify.IntValue = 0;
		Cvar_sm_hosties_freekill_treshold.IntValue = 0;
	}
	else
	{
		// Replace the Cvar Value with old value
		Cvar_sm_hosties_announce_rebel_down.IntValue = OldCvar_sm_hosties_announce_rebel_down;
		Cvar_sm_hosties_rebel_color.IntValue = OldCvar_sm_hosties_rebel_color;
		Cvar_sm_hosties_mute.IntValue = OldCvar_sm_hosties_mute;
		Cvar_sm_hosties_announce_attack.IntValue = OldCvar_sm_hosties_announce_attack;
		Cvar_sm_hosties_announce_wpn_attack.IntValue = OldCvar_sm_hosties_announce_wpn_attack;
		Cvar_sm_hosties_freekill_notify.IntValue = OldCvar_sm_hosties_freekill_notify;
		Cvar_sm_hosties_freekill_treshold.IntValue = OldCvar_sm_hosties_freekill_treshold;
	}
}

void ToggleHeal(bool bDisabled)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "trigger_hurt")) != -1)
	{
		if (GetEntPropFloat(ent, Prop_Data, "m_flDamage") < 0)
		{
			AcceptEntityInput(ent, bDisabled ? "Disable" : "Enable");
		}
	}
}

stock void SortEventDays()
{
	char sBuffer[64];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "cfg/sourcemod/daysapi/daysapi_sorting.ini");
	File hFile = OpenFile(sBuffer, "r");
	if (hFile == null)
	{
		LogError("couldn't read from file: %s", sBuffer);
		return;
	}
	
	int ActualPos = -1;
	
	while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
	{
		TrimString(sBuffer);
		
		int index = g_aEventDayList.FindString(sBuffer);
		if (index == -1)
		{
			continue;
		}
		
		ActualPos++;
		if (index == ActualPos)
		{
			continue;
		}
		
		g_aEventDayList.SwapAt(index, ActualPos);
		g_aEventDayListDisplayName.SwapAt(index, ActualPos);
	}
}


// native void DaysAPI_AddDay(char[] szInternalName, 
//				DayStartEndFunction StartFunction = INVALID_FUNCTION, DayStartEndFunction EndFunction = INVALID_FUNCTION);
public int Native_AddDay(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	if (StrEqual(szInternalName, No_Day_Keyword))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Internal Name '%s' is reserved", No_Day_Keyword);
		return;
	}
	
	int iIndex = FindDayIndex(szInternalName);
	
	Function StartFunction = GetNativeFunction(2);
	Function EndFunction = GetNativeFunction(3);
	
	DataPack dp = new DataPack();
	dp.WriteCell(hPlugin);
	dp.WriteFunction(StartFunction);
	dp.WriteFunction(EndFunction);
	
	if (iIndex == No_Day)
	{
		g_Array_InternalNames.PushString(szInternalName);
		g_Array_DataPacks.Push(dp);
		g_Array_DisplayNames.PushString(szInternalName);
		g_Array_Flags.Push(DayFlag_NoFlags);
	}
	
	else
	{
		delete view_as<DataPack>(g_Array_DataPacks.Get(iIndex));
		g_Array_DataPacks.Set(iIndex, dp);
	}
	
	KeyValues kv = new KeyValues("DaysAPI_Panel");
	if (!FileExists(g_szPanelsTextPath))
	{
		KeyValuesToFile(kv, g_szPanelsTextPath);
	}
	
	else FileToKeyValues(kv, g_szPanelsTextPath);
	if (!kv.JumpToKey(szInternalName, false))
	{
		kv.JumpToKey(szInternalName, true);
		kv.SetString("title", "Put title here");
		kv.SetString("disable", "1");
		kv.SetString("1", "Line1");
		kv.Rewind();
		
		KeyValuesToFile(kv, g_szPanelsTextPath);
	}
	
	delete kv;
	
	Call_StartForward(g_Forward_OnEventDayAdded);
	Call_PushString(szInternalName);
	Call_Finish();
}

// native bool DaysAPI_RemoveDay(char[] szInternalName);
public int Native_RemoveDay(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	int iIndex = FindDayIndex(szInternalName);
	if (iIndex == -1)
	{
		return 0;
	}
	
	if (IsDayRunning(szInternalName))
	{
		EndDayEx(szInternalName, No_Day, INVALID_HANDLE);
	}
	
	if (IsDayPlanned(szInternalName))
	{
		CancelPlannedDayEx(szInternalName);
	}
	
	Call_StartForward(g_Forward_OnEventDayRemoved);
	{
		Call_PushString(szInternalName);
		Call_Finish();
	}
	
	LogMessage("Deleted day %s", szInternalName);
	g_Array_InternalNames.Erase(iIndex);
	delete view_as<DataPack>(g_Array_DataPacks.Get(iIndex));
	g_Array_DataPacks.Erase(iIndex);
	g_Array_DisplayNames.Erase(iIndex);
	g_Array_Flags.Erase(iIndex);
	return 1;
}

public int Native_SetDayInfo(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	int iIndex = FindDayIndex(szInternalName);
	if (iIndex == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Couldn't find Day Internal Name '%s'", szInternalName);
		return;
	}
	
	DayInfo info = GetNativeCell(2);
	
	switch (info)
	{
		case DayInfo_DisplayName:
		{
			char szDispName[MAX_DISPLAY_NAME_LENGTH];
			GetNativeString(3, szDispName, sizeof szDispName);
			g_Array_DisplayNames.SetString(iIndex, szDispName);
		}
		
		case DayInfo_Flags:
		{
			// Apparently, any ... in the nativee needs GetNativeCellRef, took me like 3 hours to find this error ..
			g_Array_Flags.Set(iIndex, GetNativeCellRef(3));
		}
	}
}

public int Native_GetDayInfo(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	int iIndex = FindDayIndex(szInternalName);
	if (iIndex == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Couldn't find Day Internal Name '%s'", szInternalName);
		return;
	}
	
	DayInfo info = GetNativeCell(2);
	switch (info)
	{
		case DayInfo_DisplayName:
		{
			g_Array_DisplayNames.GetString(iIndex, szInternalName, sizeof szInternalName);
			SetNativeString(3, szInternalName, GetNativeCell(4));
		}
		
		case DayInfo_Flags:
		{
			SetNativeCellRef(3, g_Array_Flags.Get(iIndex));
		}
	}
}

public int Native_GetDays(Handle hPlugin, int argc)
{
	return GetDays(hPlugin, GetNativeFunction(1), GetNativeCell(2), GetNativeCell(3));
}

int GetDays(Handle hPlugin = INVALID_HANDLE, Function func = INVALID_FUNCTION, bool bAddDisabled = false, any data = 0)
{
	int iSize = g_Array_InternalNames.Length;
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	char szDisplayName[MAX_DISPLAY_NAME_LENGTH];
	bool bRet;
	int iCount;
	
	for (int i; i < iSize; i++)
	{
		if (!bAddDisabled && (g_Array_Flags.Get(i) & DayFlag_Disabled))
		{
			continue;
		}
		
		g_Array_InternalNames.GetString(i, szInternalName, sizeof szInternalName);
		g_Array_DisplayNames.GetString(i, szDisplayName, sizeof szDisplayName);
		
		bRet = true;
		Call_StartFunction(hPlugin, func);
		{
			Call_PushString(szInternalName);
			Call_PushString(szDisplayName);
			Call_PushCell(g_Array_Flags.Get(i));
			Call_PushCell(data);
			Call_Finish(bRet);
		}
		
		if (bRet)
		{
			iCount++;
		}
	}
	
	return iCount;
}

public int Native_IsDayRunning(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	return IsDayRunning(szInternalName);
}

public int Native_IsDayPlanned(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	return IsDayPlanned(szInternalName);
}

public int Native_AddPlannedDay(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	if (FindDayIndex(szInternalName) == No_Day)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Couldn't find internal name '%s'", szInternalName);
		return;
	}
	
	if (IsDayPlanned(szInternalName))
	{
		return;
	}
	
	g_Array_PlannedDays.PushString(szInternalName);
	
	Call_StartForward(g_Forward_OnAddPlannedDay);
	Call_PushString(szInternalName);
	Call_Finish();
}

public int Native_StartDay(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	int iIndex = FindDayIndex(szInternalName);
	if (iIndex == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Couldn't find Day Internal Name '%s'", szInternalName);
		return 0;
	}
	
	return view_as<int>(StartDay(iIndex, false, GetNativeCell(2)));
}

DayStartState StartDay(int iIndex, bool bWasPrepared, any data = INVALID_HANDLE)
{
	DayStartReturn iRet = DSR_Success;
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	g_Array_InternalNames.GetString(iIndex, szInternalName, sizeof szInternalName);
	
	if (IsDayRunning(szInternalName))
	{
		return DSS_Failure_AlreadyRunning;
	}
	
	if (g_bRoundEnd)
	{
		if (!(g_Array_Flags.Get(iIndex) & DayFlag_CanStartAtRoundEnd))
		{
			return DSS_Failure_RoundEnd;
		}
	}
	
	DayFlag iFlags = g_Array_Flags.Get(iIndex);
	if (iFlags & DayFlag_StartAlone)
	{
		if (IsDayRunning())
		{
			return DSS_Failure_DayRunning;
		}
	}
	
	if (iFlags & DayFlag_StartPrepareOnly)
	{
		if (!bWasPrepared)
		{
			return DSS_Failure_StartPrepareOnly;
		}
	}
	
	DataPack dp = g_Array_DataPacks.Get(iIndex);
	dp.Reset();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	
	Call_StartForward(g_Forward_OnEventDayStart_Pre);
	{
		Call_PushString(szInternalName);
		Call_PushCell(bWasPrepared);
		Call_PushCell(data);
		Call_Finish(iRet);
	}
	
	
	if (iRet == DSR_Stop)
	{
		return DSS_Failure_Halted;
	}
	
	if (func != INVALID_FUNCTION)
	{
		Call_StartFunction(hPlugin, func);
		{
			Call_PushCell(bWasPrepared);
			Call_PushCell(data);
			Call_Finish(iRet);
		}
		
		if (iRet == DSR_Stop)
		{
			return DSS_Failure_Halted;
		}
	}
	
	g_Array_RunningDays.PushString(szInternalName);
	
	if (g_bHostiesRunning)
	{
		ToggleConVars(true);
	}
	
	
	if (ConVar_DisableMedic.IntValue)
	{
		g_bHealDisabled = true;
		ToggleHeal(true);
	}
	
	if (ConVar_NativeStartResetRounds.BoolValue)
	{
		g_iRoundNumber = 0;
	}
	
	Call_StartForward(g_Forward_OnEventDayStart);
	{
		Call_PushString(szInternalName);
		Call_PushCell(bWasPrepared);
		Call_PushCell(data);
		Call_Finish();
	}
	
	if (!(iFlags & DayFlag_DontDisplayPanel))
	{
		CreateTimer(1.0, Timer_ShowPanel, iIndex, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return DSS_Success;
}

public Action Timer_ShowPanel(Handle hTimer, int iIndex)
{
	int clients[MAXPLAYERS];
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			clients[count++] = i;
		}
	}
	
	if (count)
	{
		ShowDayPanel(clients, count, MENU_TIME_FOREVER, iIndex);
	}
}

// native bool DaysAPI_StartDay(char[] szInternalName)
public int Native_EndDay(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	if (IsDayRunning(szInternalName))
	{
		EndDayEx(szInternalName, No_Day, GetNativeCell(2));
		return true;
	}
	
	return false;
}

public int Native_EndAllDays(Handle hPlugin, int argc)
{
	EndAllDays();
}

void EndAllDays()
{
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	
	while (g_Array_RunningDays.Length > 0)
	{
		g_Array_RunningDays.GetString(0, szIntName, sizeof szIntName);
		EndDayEx(szIntName, 0, INVALID_HANDLE);
	}
}

void EndDayEx(char[] szInternalName, int iIndexInRunningDayArray, any data = INVALID_HANDLE)
{
	if (iIndexInRunningDayArray == No_Day)
	{
		int iSize = g_Array_RunningDays.Length;
		char szIntCheckName[MAX_INTERNAL_NAME_LENGTH];
		for (int i; i < iSize; i++)
		{
			g_Array_RunningDays.GetString(i, szIntCheckName, sizeof szIntCheckName);
			
			if (StrEqual(szInternalName, szIntCheckName))
			{
				g_Array_RunningDays.Erase(i);
				break;
			}
		}
	}
	
	else
	{
		g_Array_RunningDays.Erase(iIndexInRunningDayArray);
	}
	
	int iDayIndex = FindDayIndex(szInternalName);
	if (iDayIndex != No_Day)
	{
		EndDay(iDayIndex, data);
	}
}

void EndDay(int iModIndex, any data)
{
	DataPack dp = g_Array_DataPacks.Get(iModIndex);
	dp.Reset();
	Handle hPlugin = dp.ReadCell();
	dp.ReadFunction();
	Function func = dp.ReadFunction();
	
	if (func != INVALID_FUNCTION)
	{
		Call_StartFunction(hPlugin, func);
		Call_PushCell(data);
		Call_Finish();
	}
	
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	g_Array_InternalNames.GetString(iModIndex, szInternalName, sizeof szInternalName);
	strcopy(g_szCurrentEndingDay, sizeof g_szCurrentEndingDay, szInternalName);
	
	Call_StartForward(g_Forward_OnEventDayEnd_Pre);
	Call_PushString(szInternalName);
	Call_PushCell(data);
	Call_Finish();
	
	Call_StartForward(g_Forward_OnEventDayEnd);
	Call_PushString(szInternalName);
	Call_PushCell(data);
	Call_Finish();
	
	if (g_bHostiesRunning)
	{
		ToggleConVars(true);
	}
	
	if (!IsDayRunning())
	{
		if (g_bHealDisabled)
		{
			g_bHealDisabled = false;
			ToggleHeal(false);
		}
	}
	
	if (g_Array_Flags.Get(iModIndex) & DayFlag_EndTerminateRound)
	{
		if (!g_bRoundEnd)
		{
			CS_TerminateRound(5.5, CSRoundEnd_Draw, true/* force terminate */);
		}
	}
}

int FindWinnersGroupIndex(char[] szWinnersGroup)
{
	int iSize = g_Array_WinnersGroups.Length;
	char szCheckWinnerGroup[MAX_WINNER_GROUP_NAME_LENGTH];
	
	for (int i; i < iSize; i++)
	{
		g_Array_WinnersGroups.GetString(i, szCheckWinnerGroup, sizeof szCheckWinnerGroup);
		
		if (StrEqual(szWinnersGroup, szCheckWinnerGroup))
		{
			return i;
		}
	}
	
	return -1;
}

public int Native_ResetDayWinners(Handle hPlugin, int argc)
{
	g_Array_WinnersGroups.Clear();
	g_Array_WinnersList.Clear();
	g_Array_WinnersListCount.Clear();
}

public int Native_SetDayWinners(Handle hPlugin, int argc)
{
	int iWinnersList[MAXPLAYERS], iCount;
	GetNativeArray(2, iWinnersList, MAXPLAYERS);
	iCount = GetNativeCell(3);
	
	char szWinnerGroupName[MAX_WINNER_GROUP_NAME_LENGTH];
	GetNativeString(1, szWinnerGroupName, sizeof szWinnerGroupName);
	
	int iIndex;
	if ((iIndex = FindWinnersGroupIndex(szWinnerGroupName)) != -1)
	{
		g_Array_WinnersList.SetArray(iIndex, iWinnersList);
		g_Array_WinnersListCount.Set(iIndex, iCount);
	}
	
	else
	{
		g_Array_WinnersGroups.PushString(szWinnerGroupName);
		g_Array_WinnersList.PushArray(iWinnersList);
		g_Array_WinnersListCount.Push(iCount);
	}
	//ThrowNativeError(SP_ERROR_NATIVE, "This function can only be used during the day's own End function or OnEndDay_Pre");
}

public int Native_GetDayWinners(Handle hPlugin, int argc)
{
	int iWinnersList[MAXPLAYERS], iCount;
	int iSize = GetNativeCell(3);
	
	char szWinnerGroupName[MAX_WINNER_GROUP_NAME_LENGTH];
	GetNativeString(1, szWinnerGroupName, sizeof szWinnerGroupName);
	
	int iIndex;
	if ((iIndex = FindWinnersGroupIndex(szWinnerGroupName)) != -1)
	{
		g_Array_WinnersList.GetArray(iIndex, iWinnersList, sizeof iWinnersList);
		iCount = g_Array_WinnersListCount.Get(iIndex);
		
		SetNativeArray(2, iWinnersList, iSize);
	}
	
	return iCount;
	//ThrowNativeError(SP_ERROR_NATIVE, "This function can only be used during the day's own End function or OnEndDay_Pre");
}

public int Native_GetDayWinnersGroups(Handle hPlugin, int argc)
{
	int iWinnersList[MAXPLAYERS], iCount;
	char szWinnerGroupName[MAX_WINNER_GROUP_NAME_LENGTH];
	
	Function func = GetNativeFunction(1);
	any data = GetNativeCell(2);
	
	int iSize = g_Array_WinnersList.Length;
	
	for (int i; i < iSize; i++)
	{
		g_Array_WinnersGroups.GetString(i, szWinnerGroupName, sizeof szWinnerGroupName);
		g_Array_WinnersList.GetArray(i, iWinnersList, sizeof iWinnersList);
		iCount = g_Array_WinnersListCount.Get(i);
		
		Call_StartFunction(hPlugin, func);
		{
			Call_PushString(g_szCurrentEndingDay);
			Call_PushString(szWinnerGroupName);
			Call_PushArray(iWinnersList, iCount);
			Call_PushCell(iCount);
			Call_PushCell(data);
			Call_Finish();
		}
	}
	
	//ThrowNativeError(SP_ERROR_NATIVE, "This function can only be used during the day's own End function or OnEndDay_Pre");
}

public int Native_CancelPlannedDay(Handle hPlugin, int argc)
{
	char szInternalName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(1, szInternalName, sizeof szInternalName);
	
	if (IsDayPlanned(szInternalName))
	{
		CancelPlannedDayEx(szInternalName);
		return true;
	}
	
	return false;
}

public int Native_CancelAllPlannedDays(Handle hPlugin, int argc)
{
	CancelAllPlannedDays();
}

void CancelAllPlannedDays()
{
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	while (g_Array_PlannedDays.Length > 0)
	{
		g_Array_PlannedDays.GetString(0, szIntName, sizeof szIntName);
		CancelPlannedDayEx(szIntName, 0);
	}
}

void CancelPlannedDayEx(char[] szInternalName, int iIndexInPlannedDayArray = No_Day)
{
	if (iIndexInPlannedDayArray == No_Day)
	{
		int iSize = g_Array_PlannedDays.Length;
		char szIntCheckName[MAX_INTERNAL_NAME_LENGTH];
		for (int i; i < iSize; i++)
		{
			g_Array_PlannedDays.GetString(i, szIntCheckName, sizeof szIntCheckName);
			
			if (StrEqual(szInternalName, szIntCheckName))
			{
				g_Array_PlannedDays.Erase(i);
				break;
			}
		}
	}
	
	else
	{
		g_Array_PlannedDays.Erase(iIndexInPlannedDayArray);
	}
	
	int iDayIndex = FindDayIndex(szInternalName);
	if (iDayIndex != No_Day)
	{
		CancelPlannedDay(szInternalName);
	}
}

void CancelPlannedDay(char[] szIntName)
{
	// Add forwards later ?
	Call_StartForward(g_Forward_OnRemovePlannedDay);
	{
		Call_PushString(szIntName);
		Call_Finish();
	}
}

public int Native_GetRunningDays(Handle hPlugin, int argc)
{
	int iSize = g_Array_RunningDays.Length;
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	
	bool bRet;
	char szDisplayName[MAX_DISPLAY_NAME_LENGTH];
	Function func = GetNativeFunction(1);
	any data = GetNativeCell(2);
	int iIndex, iCount;
	
	for (int i; i < iSize; i++)
	{
		g_Array_RunningDays.GetString(i, szIntName, sizeof szIntName);
		iIndex = FindDayIndex(szIntName);
		
		if (iIndex == No_Day)
		{
			continue;
		}
		
		g_Array_DisplayNames.GetString(iIndex, szDisplayName, sizeof szDisplayName);
		
		bRet = true;
		Call_StartFunction(hPlugin, func);
		{
			Call_PushString(szIntName);
			Call_PushString(szDisplayName);
			Call_PushCell(g_Array_Flags.Get(iIndex));
			Call_PushCell(data);
			Call_Finish(bRet);
		}
		
		if (bRet)
		{
			iCount++;
		}
	}
	
	return iCount;
}

public int Native_GetPlannedDays(Handle hPlugin, int argc)
{
	int iSize = g_Array_PlannedDays.Length;
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	
	bool bRet;
	char szDisplayName[MAX_DISPLAY_NAME_LENGTH];
	Function func = GetNativeFunction(1);
	any data = GetNativeCell(2);
	int iIndex, iCount;
	
	for (int i; i < iSize; i++)
	{
		g_Array_PlannedDays.GetString(i, szIntName, sizeof szIntName);
		iIndex = FindDayIndex(szIntName);
		
		if (iIndex == No_Day)
		{
			continue;
		}
		
		g_Array_DisplayNames.GetString(iIndex, szDisplayName, sizeof szDisplayName);
		
		bRet = true;
		Call_StartFunction(hPlugin, func);
		{
			Call_PushString(szIntName);
			Call_PushString(szDisplayName);
			Call_PushCell(g_Array_Flags.Get(iIndex));
			Call_PushCell(data);
			Call_Finish(bRet);
		}
		
		if (bRet)
		{
			iCount++;
		}
	}
	
	return iCount;
}

public int Native_ShowDayPanel(Handle hPlugin, int argc)
{
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	GetNativeString(4, szIntName, sizeof szIntName);
	
	int iIndex = FindDayIndex(szIntName);
	if (iIndex == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Couldn't find Day Internal Name '%s'", szIntName);
		return;
	}
	
	int clients[MAXPLAYERS];
	GetNativeArray(1, clients, sizeof clients);
	ShowDayPanel(clients, GetNativeCell(2), GetNativeCell(3), iIndex);
}

void ShowDayPanel(int[] clients, int iSize, int iDuration, int iIndex)
{
	char szIntName[MAX_INTERNAL_NAME_LENGTH];
	g_Array_InternalNames.GetString(iIndex, szIntName, sizeof szIntName);
	
	KeyValues kv = new KeyValues("DaysAPI_Panel");
	
	if (!FileExists(g_szPanelsTextPath))
	{
		KeyValuesToFile(kv, g_szPanelsTextPath);
		return;
	}
	
	char szValue[192];
	FileToKeyValues(kv, g_szPanelsTextPath);
	
	kv.GetSectionName(szValue, sizeof szValue);
	
	Panel panel = new Panel();
	
	kv.GetSectionName(szValue, sizeof szValue);
	
	int iLines;
	
	if (KvJumpToKey(kv, szIntName, false))
	{
		kv.GotoFirstSubKey(false);
		bool bFoundTitle = false;
		bool bFoundDisable = false;
		
		do
		{
			kv.GetSectionName(szValue, sizeof szValue);
			if (!bFoundTitle && StrEqual(szValue, "title"))
			{
				bFoundTitle = true;
				kv.GetString(NULL_STRING, szValue, sizeof szValue);
				panel.SetTitle(szValue);
				
				continue;
			}
			
			if (!bFoundDisable && StrEqual(szValue, "disable"))
			{
				bFoundDisable = true;
				if (kv.GetNum(NULL_STRING))
				{
					delete kv;
					delete panel;
					
					return;
				}
				
				continue;
			}
			
			iLines++;
			kv.GetString(NULL_STRING, szValue, sizeof szValue);
			panel.DrawText(szValue);
		}
		while (KvGotoNextKey(kv, false));
		
		kv.GoBack();
	}
	
	delete kv;
	
	if (!iLines)
	{
		delete panel;
		return;
	}
	
	panel.DrawItem("Close", ITEMDRAW_DEFAULT);
	
	for (int i; i < iSize; i++)
	{
		panel.Send(clients[i], MenuHandler_Dummy, iDuration);
	}
}

public int MenuHandler_Dummy(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Select)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Cancel)
	{
		delete menu;
	}
}
