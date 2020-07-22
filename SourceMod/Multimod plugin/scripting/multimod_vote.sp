#pragma semicolon 1

#include <sourcemod>
#include <multimod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Multimod Plugin: Voting", 
	author = "Khalid", 
	description = "Voting system for Multimod plugin", 
	version = MM_VERSION_STR, 
	url = "No"
};

#define VOTE_MAP_END_GRACE	1.7

bool g_bLate;

MultiModVoteStatus g_iVoteStatus = MultiModVoteStatus_NoVote;
bool g_bForceChange = true;

char g_szNextMap[MM_MAX_MAP_NAME];

MultiModVote g_iVoteBit_Progress = MultiModVote_None, 
g_iVoteBit_Total = MultiModVote_None, 
g_iVoteBit_Current = MultiModVote_None;

int g_iVoteItemCount;
Menu g_VoteMenu;

int g_iTotalVotes_WithoutPower;
int g_iTotalVotes;

ArrayList g_Array_VoteItems,  // Name
g_Array_VoteItems_Original,  // Original Name
g_Array_VoteItems_OriginalIndexes,  // MultiMod Mod Index
g_Array_VoteItems_Enabled,  // Enabled item?
g_Array_VoteItems_Votes,  // Votes for that item (with power)
g_Array_VoteItems_Votes_WithoutPower; // Votes for that item (without)

#define CheckVoteStatus(%1) (g_iVoteStatus == %1)

int g_iClientVotingPower[MAXPLAYERS] = 1;

Handle g_hForward_OnClientVote, 

g_hForward_OnAddMenuItem_Pre, 
g_hForward_OnAddMenuItem, 

g_hForward_OnVoteStart_Pre, 
g_hForward_OnVoteStart, 

g_hForward_OnVoteFinished;

// Settings
bool g_bSetting_ForceChange;
int g_iSetting_VotingTime_Mod;
int g_iSetting_VotingTime_Map;
int g_iSetting_MaxMapsInVote;
int g_iSetting_MaxModsInVote;
bool g_bSetting_RandomizeModsInVote;
bool g_bSetting_HideDisabledItems;

bool g_bCanSetNextMap;

Handle g_hCurrentTimer = null;

stock const MultiModVote VOTE_ORDER[MultiModVote_TotalVotes] =  {
	MultiModVote_Mod, 
	MultiModVote_Map
};

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrorMax)
{
	// Natives
	CreateNative("MultiMod_Vote_StartVote", Native_StartVote);
	
	CreateNative("MultiMod_Vote_GetVoteItemName", Native_GetVoteItemName);
	CreateNative("MultiMod_Vote_GetVoteItemCount", Native_GetVoteItemCount);
	
	CreateNative("MultiMod_Vote_GetTotalVotes", Native_GetTotalVotes);
	
	CreateNative("MultiMod_Vote_GetVoteStatus", Native_GetVoteStatus);
	
	CreateNative("MultiMod_Vote_GetAllVoteBit", Native_GetAllVoteBit);
	CreateNative("MultiMod_Vote_GetVoteProgressBit", Native_GetVoteProgressBit);
	CreateNative("MultiMod_Vote_GetCurrentVote", Native_GetCurrentVote);
	CreateNative("MultiMod_Vote_GetCurrentVoteType", Native_GetCurrentVoteType);
	CreateNative("MultiMod_Vote_CancelOngoingVote", Native_CancelOngoingVote);
	
	// Voting powers are added after the vote has finished.
	CreateNative("MultiMod_Vote_SetClientVotingPower", Native_SetClientVotingPower);
	CreateNative("MultiMod_Vote_GetClientVotingPower", Native_GetClientVotingPower);
	
	// Forwards
	g_hForward_OnClientVote = CreateGlobalForward("MultiMod_Vote_OnClientVote", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	g_hForward_OnAddMenuItem_Pre = CreateGlobalForward("MultiMod_Vote_OnAddMenuItem_Pre", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_CellByRef);
	g_hForward_OnAddMenuItem = CreateGlobalForward("MultiMod_Vote_OnAddMenuItem", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Cell);
	
	g_hForward_OnVoteStart_Pre = CreateGlobalForward("MultiMod_Vote_OnVoteStart_Pre", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
	g_hForward_OnVoteStart = CreateGlobalForward("MultiMod_Vote_OnVoteStart", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	g_hForward_OnVoteFinished = CreateGlobalForward("MultiMod_Vote_OnVoteFinished", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	RegPluginLibrary(MM_LIB_VOTE);
	
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_mm_startvote", AdminCmdStartVote, MM_ACCESS_FLAG_NEXTMOD_BIT, "Type sm_mm_startvote \"help\" for more info");
	RegAdminCmd("sm_votemod", AdminCmdVoteMod, MM_ACCESS_FLAG_NEXTMOD_BIT, "Will start the mod/map vote");
	RegAdminCmd("sm_mm_cancelvote", AdminCmdCancelVote, MM_ACCESS_FLAG_NEXTMOD_BIT);
	//RegAdminCmd("sm_cancelvote", AdminCmdCancelVote, MM_ACCESS_FLAG_NEXTMOD_BIT, "Will cancel any votes that happened");
	
	g_Array_VoteItems = CreateArray(MM_MAX_MAP_NAME + MM_MAX_MOD_PROP_LENGTH);
	g_Array_VoteItems_Original = CreateArray(MM_MAX_MAP_NAME + MM_MAX_MOD_PROP_LENGTH);
	g_Array_VoteItems_OriginalIndexes = CreateArray(1);
	g_Array_VoteItems_Enabled = CreateArray(1);
	g_Array_VoteItems_Votes = CreateArray(1);
	g_Array_VoteItems_Votes_WithoutPower = CreateArray(1);
	
	SetArrayValue(g_iClientVotingPower, sizeof g_iClientVotingPower, 1, 0);
	
	if (g_bLate)
	{
		if (MultiMod_IsLoaded())
		{
			// Not Needed as OnMapStart (which is under MultiMode_OnLoaded callback) is called on every plugin load to keep coupling with OnMapEnd.
			//MultiMod_OnLoaded(false);
		}
	}
}

public int Native_CancelOngoingVote(Handle hPlugin, int args)
{
	if(g_iVoteStatus != MultiModVoteStatus_NoVote)
	{
		CancelOngoingVote();
		return 1;
	}
	
	return 0;
}

public Action AdminCmdCancelVote(int client, int args)
{
	if(g_iVoteStatus == MultiModVoteStatus_NoVote)
	{
		ReplyToCommand(client, "* There is no on-going vote to cancel!");
		return Plugin_Handled;
	}
	
	CancelOngoingVote();
	
	MultiMod_PrintToChatAll("ADMIN \x03%N \x01Canceled the on-going vote!", client);
	
	return Plugin_Handled;
}

void CancelOngoingVote()
{
	if(MultiMod_GetNextModId() != ModIndex_Null)
	{
		MultiMod_SetNextMod(ModIndex_Null);
	}
	
	ResetVote();
}

public void OnAllPluginsLoaded()
{
	MultiMod_Settings_Create(MM_SETTING_DEFAULT_FORCE_CHANGE, "1", true, true);
	MultiMod_Settings_Create(MM_SETTING_VOTETIME_MOD, "15", true, true);
	MultiMod_Settings_Create(MM_SETTING_VOTETIME_MAP, "15", true, true);
	MultiMod_Settings_Create(MM_SETTING_MAX_MODS_IN_VOTE, "0", true, true);
	MultiMod_Settings_Create(MM_SETTING_MAX_MAPS_IN_VOTE, "0", true, true);
	MultiMod_Settings_Create(MM_SETTING_RANDOMIZE_MODS_IN_VOTE, "0", true, true);
	MultiMod_Settings_Create(MM_SETTING_VOTE_HIDE_DISABLED_ITEMS, "0", true, true);
}

public void MultiMod_Settings_OnValueChange(char[] szSettingName, char[] szOldValue, char[] szNewValue)
{
	LogMessage("Change : %s : %s : %s ", szSettingName, szOldValue, szNewValue);
	if (StrEqual(szSettingName, MM_SETTING_RANDOMIZE_MODS_IN_VOTE))
	{
		g_bSetting_RandomizeModsInVote = view_as<bool>(!!StringToInt(szNewValue));
	}
	
	else if (StrEqual(szSettingName, MM_SETTING_DEFAULT_FORCE_CHANGE))
	{
		g_bSetting_ForceChange = view_as<bool>(!!StringToInt(szNewValue));
	}
	
	else if (StrEqual(szSettingName, MM_SETTING_VOTETIME_MOD))
	{
		g_iSetting_VotingTime_Mod = StringToInt(szNewValue);
	}
	
	else if (StrEqual(szSettingName, MM_SETTING_VOTETIME_MAP))
	{
		g_iSetting_VotingTime_Map = StringToInt(szNewValue);
	}
	
	else if (StrEqual(szSettingName, MM_SETTING_MAX_MAPS_IN_VOTE))
	{
		g_iSetting_MaxMapsInVote = GetCorrectValue(StringToInt(szNewValue));
	}
	
	else if (StrEqual(szSettingName, MM_SETTING_MAX_MODS_IN_VOTE))
	{
		g_iSetting_MaxModsInVote = GetCorrectValue(StringToInt(szNewValue));
	}
	
	else if (StrEqual(szSettingName, MM_SETTING_VOTE_HIDE_DISABLED_ITEMS))
	{
		g_bSetting_HideDisabledItems = view_as<bool>(!!StringToInt(szNewValue));
	}
}

int GetCorrectValue(int iInt)
{
	if (iInt < 0)
	{
		return 0;
	}
	
	return iInt;
}

public void MultiMod_OnLoaded(bool bReload)
{
	OnMapStart();
}

// to do, add a forward for player connect in multimod plugin.
public void OnClientDisconnect(int client)
{
	g_iClientVotingPower[client] = 1;
}

public void OnMapStart()
{
	ServerCommand("mp_match_end_restart 0; mp_match_end_changelevel 1; mp_endmatch_votenextmap 0");
	/*
	No longer needed
	if(g_bSetting_BlockCurrentModInVote)
	{
		MultiMod_SetModLock(MultiMod_GetCurrentModId(), MultiModLock_Locked);
	}*/
	
	g_hCurrentTimer = null;
	
	if (!MultiMod_IsLoaded())
	{
		return;
	}
	
	g_bCanSetNextMap = true;
	
	ResetVote();
	
	CreateTimer(3.0, Func_Timer, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void ResetVote()
{
	g_iVoteStatus = MultiModVoteStatus_NoVote;
	
	g_iVoteItemCount = 0;
	
	g_iVoteBit_Progress = MultiModVote_None;
	g_iVoteBit_Total = MultiModVote_None;
	g_iVoteBit_Current = MultiModVote_None;
	
	ClearArray(g_Array_VoteItems_Original);
	ClearArray(g_Array_VoteItems_OriginalIndexes);
	ClearArray(g_Array_VoteItems_Enabled);
	ClearArray(g_Array_VoteItems);
	
	ClearArray(g_Array_VoteItems_Votes_WithoutPower);
	ClearArray(g_Array_VoteItems_Votes);
	
	g_bForceChange = false;
	
	if(g_hCurrentTimer != null)
	{
		PrintToServer("Destroyed");
		delete g_hCurrentTimer;
	}
	
	DecideNextMap("", false);
	PrintToServer("Called");
	
	
	g_hCurrentTimer = null;
}

public void OnMapEnd()
{
	g_bCanSetNextMap = false;
}

public Action AdminCmdVoteMod(int client, int iArgs)
{
	if (CheckVoteStatus(MultiModVoteStatus_Running))
	{
		ReplyToCommand(client, "** Voting has already started.");
		return Plugin_Handled;
	}
	
	MultiModVote iParentVoteType = MultiMod_GetNextModId() != ModIndex_Null ? MultiModVote_Map : MultiModVote_Normal;
	bool bForce = true;
	
	if (Func_PrepareVote(iParentVoteType, bForce))
	{
		ReplyToCommand(client, "** Started the vote");
	}
	
	else
	{
		ReplyToCommand(client, "Couldn't Start the mod vote");
	}
	
	return Plugin_Handled;
}

bool CanStartVote()
{
	if (CheckVoteStatus(MultiModVoteStatus_Running))
	{
		return false;
	}
	
	if (CheckVoteStatus(MultiModVoteStatus_Done) && MultiMod_GetNextModId() != ModIndex_Null)
	{
		return false;
	}
	
	return true;
}

public Action AdminCmdStartVote(int client, int iArgs)
{
	if (!CanStartVote())
	{
		ReplyToCommand(client, "** Cannot start a vote as there is already a mod chosen as next mod or a vote is running.");
		return Plugin_Handled;
	}
	
	bool bForce = true;
	MultiModVote iParentVoteType;
	
	char szArg[20];
	
	if (iArgs > 0)
	{
		GetCmdArg(1, szArg, sizeof szArg);
	}
	
	if (!iArgs || iArgs == 1 && StrEqual(szArg, "help", false))
	{
		ReplyToCommand(client, "Usage: \nsm_mm_startvote \"Args1\" \"Arg2\" ... \n\
			Args can be mod, map, normal, or noforce\n\
			mod - Mod vote only\n\
			map - Map vote only\n\
			normal - Normal Vote (Start by mod, then map)\n\
			nochange, noforce - Do not imediately change to that map/mod");
		return Plugin_Handled;
	}
	
	for (int i = 1; i < iArgs + 1; i++)
	{
		GetCmdArg(i, szArg, sizeof szArg);
		if (StrEqual(szArg, "mod", false))
		{
			iParentVoteType |= MultiModVote_Mod;
		}
		
		else if (StrEqual(szArg, "map", false))
		{
			iParentVoteType |= MultiModVote_Map;
			//PrintToServer("Map True");
		}
		
		else if (StrEqual(szArg, "normal", false))
		{
			iParentVoteType |= MultiModVote_Normal;
		}
		
		else if (StrEqual(szArg, "noforce", false) || StrEqual(szArg, "nochange", false))
		{
			bForce = false;
		}
		
		else if (StrEqual(szArg, "force", false))
		{
			bForce = true;
		}
	}
	
	/*
	if(!iParentVoteType || ( (iParentVoteType & MultiModVote_Normal) == MultiModVote_Normal) )
	{
		PrintToServer("Here");
		iParentVoteType = MultiMod_GetNextModId() != ModIndex_Null ? MultiModVote_Map : MultiModVote_Normal;
	}*/
	
	if (Func_PrepareVote(iParentVoteType, bForce))
	{
		ReplyToCommand(client, "** Started the vote");
	}
	
	else
	{
		ReplyToCommand(client, "** Couldn't Start the mod");
	}
	return Plugin_Handled;
}

public Action Func_Timer(Handle hTimer)
{
	if (g_iVoteStatus >= MultiModVoteStatus_Running)
	{
		return Plugin_Stop;
	}
	
	static int iTime;
	if (GetMapTimeLeft(iTime) && iTime > 0)
	{
		if (iTime <= (VOTE_MAP_END_GRACE * 60))
		{
			Func_PrepareVote(MultiModVote_Normal, g_bSetting_ForceChange);
			return Plugin_Stop;
		}
	}
	
	else
	{
		// Edit this for Round Score
		// ( Timeleft < 0 ) ----> MaxRounds
		//return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

bool Func_PrepareVote(MultiModVote iVoteBit, bool bForce)
{
	if (g_iVoteStatus >= MultiModVoteStatus_Running)
	{
		return false;
	}
	
	g_iVoteBit_Total = iVoteBit;
	g_iVoteBit_Current = MultiModVote_None;
	g_iVoteBit_Progress = MultiModVote_None;
	
	g_iVoteItemCount = 0;
	
	g_bForceChange = bForce;
	
	return Func_CheckNextVoteAndStart();
}

MultiModVote Func_CheckVote_ReturnNextVote()
{
	for (int i = 0; i < sizeof VOTE_ORDER; i++)
	{
		if (VOTE_ORDER[i] & g_iVoteBit_Total && !(VOTE_ORDER[i] & g_iVoteBit_Progress))
		{
			return VOTE_ORDER[i];
		}
	}
	
	return MultiModVote_None;
}

bool Func_CheckNextVoteAndStart()
{
	if (g_iVoteBit_Progress == g_iVoteBit_Total)
	{
		//PrintToServer("Return 2");
		g_iVoteStatus = MultiModVoteStatus_Done;
		
		return false;
	}
	
	g_iVoteBit_Current = Func_CheckVote_ReturnNextVote();
	
	if (g_iVoteBit_Current == MultiModVote_None)
	{
		// No votes left.
		//PrintToServer("Return 3");
		return false;
	}
	
	ClearArray(g_Array_VoteItems_Original);
	ClearArray(g_Array_VoteItems_OriginalIndexes);
	ClearArray(g_Array_VoteItems_Enabled);
	ClearArray(g_Array_VoteItems);
	
	ClearArray(g_Array_VoteItems_Votes_WithoutPower);
	ClearArray(g_Array_VoteItems_Votes);
	
	//PrintToServer("Started");
	Func_StartVote();
	return true;
}

void Func_StartVote()
{
	g_iVoteStatus = MultiModVoteStatus_Running;
	// MultiMod_Vote_OnVoteStart_Pre(MultiModVote iAllVoteBit, MultiModVote iCurrentVote, MultiModVoteType iVoteType, bool &bForceChange);
	MMReturn iRet;
	Call_StartForward(g_hForward_OnVoteStart_Pre);
	{
		Call_PushCell(g_iVoteBit_Total);
		Call_PushCell(g_iVoteBit_Current);
		Call_PushCell(MultiModVoteType_Normal);
		Call_PushCellRef(g_bForceChange);
		Call_Finish(iRet);
	}
	
	if (iRet == MMReturn_Stop)
	{
		return;
	}
	
	g_VoteMenu = CreateMenu(MenuHandler_Vote, MENU_ACTIONS_DEFAULT);
	
	switch (g_iVoteBit_Current)
	{
		case MultiModVote_Map:
		{
			int iMod = MultiMod_GetNextModId();
			char szModName[MM_MAX_MOD_PROP_LENGTH];
			
			if (iMod == ModIndex_Null)
			{
				iMod = MultiMod_GetCurrentModId();
			}
			
			MultiMod_GetModProp(iMod, MultiModProp_Name, szModName, sizeof szModName);
			
			g_iVoteItemCount = GetRandomMaps(iMod);
			
			if (!g_iVoteItemCount)
			{
				delete g_VoteMenu;
				MultiMod_PrintToChatAll("Map vote was cancelled as there are no maps for MOD\x04 %s", szModName);
				
				// Make next map the current map.
				DecideNextMap("", true);
				
				return;
			}
			
			SetMenuTitle(g_VoteMenu, "Choose the Next Map for Mod [%s]:", szModName);
		}
		
		case MultiModVote_Mod:
		{
			SetMenuTitle(g_VoteMenu, "Choose the Next MOD:");
			
			g_iVoteItemCount = GetMods();
			
			// We don't need to check for the mods count in the vote
			// because we are gauranteed to get atleast one mod or the multimod_base plugin will fail which makes
			// all other plugins fail.
		}
	}
	
	char szName[MM_MAX_MOD_PROP_LENGTH + MM_MAX_MAP_NAME];
	char szInfo[4];
	
	bool bEnabled;
	MultiModVote hVote = g_iVoteBit_Current == MultiModVote_Mod ? MultiModVote_Mod : MultiModVote_Map;
	
	for (int i; i < g_iVoteItemCount; i++)
	{
		GetArrayString(g_Array_VoteItems, i, szName, sizeof szName);
		bEnabled = GetArrayCell(g_Array_VoteItems_Enabled, i);
		FormatEx(szInfo, sizeof szInfo, "%d", i);
		
		AddMenuItem(g_VoteMenu, szInfo, szName, bEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		iRet = CallForward_OnAddItem(g_hForward_OnAddMenuItem, hVote, hVote == MultiModVote_Mod ? GetArrayCell(g_Array_VoteItems_OriginalIndexes, i) : ModIndex_Null, szName, sizeof szName, bEnabled);
	}
	
	SetVoteResultCallback(g_VoteMenu, VoteCallback_Results);
	
	if (IsVoteInProgress())
	{
		CancelVote();
	}
	
	//PrintToServer("Vote Time: %d", hVote == MultiModVote_Mod ? g_iSetting_VotingTime_Mod : g_iSetting_VotingTime_Map);
	VoteMenuToAll(g_VoteMenu, hVote == MultiModVote_Mod ? g_iSetting_VotingTime_Mod : g_iSetting_VotingTime_Map);
	
	Call_StartForward(g_hForward_OnVoteStart);
	{
		Call_PushCell(g_iVoteBit_Total);
		Call_PushCell(g_iVoteBit_Current);
		Call_PushCell(MultiModVoteType_Normal);
		Call_PushCell(g_bForceChange);
		Call_Finish();
	}
}

public MMReturn function1(int iModId, ModList iListType, char[] szString, any data)
{
	//PrintToServer("MAp %s ModId %d", szString, iModId);
	return MMReturn_Continue;
}

int GetRandomMaps(int iModId)
{
	ArrayList hTempArray = new ArrayList(MM_MAX_MAP_NAME);
	//ArrayList hWasChosenArray = new ArrayList(1);
	
	int iCount;
	MultiMod_PassModListFromMod(iModId, ModList_Maps, HandleType_ArrayList, hTempArray, iCount, function1);
	
	int iMaxCount;
	if (g_iSetting_MaxMapsInVote)
	{
		iMaxCount = (iCount < g_iSetting_MaxMapsInVote) ? iCount : g_iSetting_MaxMapsInVote;
	}
	
	else
	{
		iMaxCount = iCount;
	}
	
	
	int iChosenCount;
	int iIndex;
	
	bool bEnabled;
	
	char szName[MM_MAX_MAP_NAME];
	char szOriginalName[MM_MAX_MAP_NAME];
	
	MMReturn iRet;
	
	int iSize = hTempArray.Length;
	while (iChosenCount < iMaxCount && iSize > 0)
	{
		iIndex = GetRandomInt(0, iSize - 1);
		
		GetArrayString(hTempArray, iIndex, szName, sizeof szName);
		GetArrayString(hTempArray, iIndex, szOriginalName, sizeof szOriginalName);
		
		bEnabled = true;
		iRet = CallForward_OnAddItem(g_hForward_OnAddMenuItem_Pre, MultiModVote_Map, ModIndex_Null, szName, sizeof szName, bEnabled);
		
		hTempArray.Erase(iIndex);
		--iSize;
		
		if (iRet == MMReturn_Stop)
		{
			continue;
		}
		
		//PrintToServer("szName %s szOriginal %s", szName, szOriginalName);
		PushArrayString(g_Array_VoteItems, szName);
		PushArrayString(g_Array_VoteItems_Original, szOriginalName);
		PushArrayCell(g_Array_VoteItems_Enabled, bEnabled);
		
		PushArrayCell(g_Array_VoteItems_Votes, 0);
		PushArrayCell(g_Array_VoteItems_Votes_WithoutPower, 0);
		
		iChosenCount++;
	}
	
	//PrintToServer("iChosenCount: %d", iChosenCount);
	delete hTempArray;
	
	return iChosenCount;
}

/*
MM_SETTING_MAX_MODS_IN_VOTE
MM_SETTING_RANDOMIZE_MODS_IN_VOTE
*/
int GetMods()
{
	int iModsCount = MultiMod_GetModsCount();
	
	int iLockedModsCount = MultiMod_GetLockedModsCount(MultiModLock_All);
	
	int iMaxVoteModsCount;
	if (!g_iSetting_MaxModsInVote)
	{
		iMaxVoteModsCount = iModsCount - iLockedModsCount;
	}
	
	else
	{
		iMaxVoteModsCount = g_iSetting_MaxModsInVote;
		if (g_iSetting_MaxModsInVote > (iModsCount - iLockedModsCount))
		{
			iMaxVoteModsCount = iModsCount - iLockedModsCount;
		}
	}
	
	//PrintToServer("iMaxCount : %d %d", iMaxCount, iCount);
	bool[] bWasChosen = new bool[iModsCount];
	
	int iChosenCount;
	int iModIndex;
	
	if (iMaxVoteModsCount < (iModsCount - iLockedModsCount))
	{
		SetArrayValue(bWasChosen, iModsCount, false, 0);
		
		while (iChosenCount < iMaxVoteModsCount)
		{
			iModIndex = GetRandomInt(0, iModsCount - 1);
			
			if (bWasChosen[iModIndex])
			{
				continue;
			}
			
			if (MultiMod_GetModLock(iModIndex) != MultiModLock_NotLocked)
			{
				continue;
			}
			
			if (GetRandomInt(0, 1))
			{
				iChosenCount++;
				bWasChosen[iModIndex] = true;
			}
		}
	}
	
	else
	{
		for (iModIndex = 0; iModIndex < iModsCount; iModIndex++)
		{
			if (MultiMod_GetModLock(iModIndex) != MultiModLock_NotLocked)
			{
				continue;
			}
			
			bWasChosen[iModIndex] = true;
		}
	}
	
	bool bEnabled;
	char szName[MM_MAX_MOD_PROP_LENGTH];
	char szOriginalName[MM_MAX_MOD_PROP_LENGTH];
	int iSize = sizeof szOriginalName;
	int iArraySize;
	
	MMReturn iRet;
	
	switch (g_bSetting_RandomizeModsInVote)
	{
		case false:
		{
			for (iModIndex = 0; iModIndex < iModsCount; iModIndex++)
			{
				bEnabled = bWasChosen[iModIndex] ? true : false;
				
				MultiMod_GetModProp(iModIndex, MultiModProp_Name, szName, iSize);
				MultiMod_GetModProp(iModIndex, MultiModProp_Name, szOriginalName, iSize);
				
				iRet = CallForward_OnAddItem(g_hForward_OnAddMenuItem_Pre, MultiModVote_Mod, iModIndex, szName, iSize, bEnabled);
				
				if (iRet == MMReturn_Stop)
				{
					continue;
				}
				
				if (g_bSetting_HideDisabledItems == true)
				{
					if (bEnabled == false)
					{
						continue;
					}
				}
				
				PushArrayCell(g_Array_VoteItems_OriginalIndexes, iModIndex);
				PushArrayCell(g_Array_VoteItems_Enabled, bEnabled);
				PushArrayString(g_Array_VoteItems_Original, szOriginalName);
				PushArrayString(g_Array_VoteItems, szName);
				
				PushArrayCell(g_Array_VoteItems_Votes, 0);
				PushArrayCell(g_Array_VoteItems_Votes_WithoutPower, 0);
				iArraySize++;
			}
		}
		
		case true:
		{
			iChosenCount = 0;
			bool[] bWasChecked = new bool[iModsCount];
			while (iChosenCount < iModsCount)
			{
				iModIndex = GetRandomInt(0, iModsCount - 1);
				
				if (bWasChecked[iModIndex])
				{
					continue;
				}
				
				// The MOST IMPORTANT LINES
				iChosenCount++;
				bWasChecked[iModIndex] = true;
				
				bEnabled = bWasChosen[iModIndex] ? true : false;
				
				if (g_bSetting_HideDisabledItems == true)
				{
					if (bEnabled == false)
					{
						continue;
					}
				}
				
				MultiMod_GetModProp(iModIndex, MultiModProp_Name, szName, iSize);
				MultiMod_GetModProp(iModIndex, MultiModProp_Name, szOriginalName, iSize);
				
				iRet = CallForward_OnAddItem(g_hForward_OnAddMenuItem_Pre, MultiModVote_Mod, iModIndex, szName, iSize, bEnabled);
				
				if (iRet == MMReturn_Stop)
				{
					//PrintToServer("Continued #1");
					continue;
				}
				
				//PrintToServer("Added #1 %d", iIndex);
				PushArrayCell(g_Array_VoteItems_OriginalIndexes, iModIndex);
				PushArrayCell(g_Array_VoteItems_Enabled, bEnabled);
				PushArrayString(g_Array_VoteItems_Original, szOriginalName);
				PushArrayString(g_Array_VoteItems, szName);
				
				//PrintToServer("Pushed");
				PushArrayCell(g_Array_VoteItems_Votes, 0);
				PushArrayCell(g_Array_VoteItems_Votes_WithoutPower, 0);
				iArraySize++;
			}
		}
	}
	
	return iArraySize;
}

MMReturn CallForward_OnAddItem(Handle hForward, MultiModVote iVoteBitCurrent, int iModId, char[] szName, int iSize, bool &bEnabled)
{
	MMReturn iRet;
	
	if (hForward == g_hForward_OnAddMenuItem_Pre)
	{
		Call_StartForward(hForward);
		Call_PushCell(iVoteBitCurrent);
		Call_PushCell(iModId);
		Call_PushStringEx(szName, iSize, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(iSize);
		Call_PushCellRef(bEnabled);
		Call_Finish(iRet);
	}
	
	else
	{
		Call_StartForward(hForward);
		Call_PushCell(iVoteBitCurrent);
		Call_PushCell(iModId);
		Call_PushString(szName);
		Call_PushCell(iSize);
		Call_PushCell(bEnabled);
		Call_Finish(iRet);
	}
	
	return iRet;
}

public int MenuHandler_Vote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if(g_iVoteStatus == MultiModVoteStatus_NoVote)
			{
				return 0;
			}
			
			char szInfo[5], szName[60];
			int iDump;
			
			GetMenuItem(menu, param2, szInfo, sizeof szInfo, iDump, szName, sizeof szName);
			int iIndex = StringToInt(szInfo);
			
			if (g_iClientVotingPower[param1] != 1)
			{
				PrintToChatAll(" \x04%N \x01chose \x03%s \x05(x%d votes)", param1, szName, g_iClientVotingPower[param1]);
				//PrintToServer("Vote Power: %d", g_iClientVotingPower[param1]);
			}
			
			else
			{
				PrintToChatAll(" \x04%N \x01chose \x03%s", param1, szName);
			}
			
			// (MultiModVote iVote, int client, int iVoteItemIndex, int iVoteItemRealIndex);
			Call_StartForward(g_hForward_OnClientVote);
			{
				Call_PushCell(g_iVoteBit_Current);
				Call_PushCell(param1);
				Call_PushCell(iIndex);
				Call_PushCell(g_iVoteBit_Current == MultiModVote_Mod ? GetArrayCell(g_Array_VoteItems_OriginalIndexes, iIndex) : ModIndex_Null);
				Call_Finish();
			}
		}
		
		case MenuAction_VoteEnd:
		{
			LogMessage("[MultiMod] Voting has ended! Vote: %s", g_iVoteBit_Current == MultiModVote_Mod ? "Mod" : "Map");
		}
		
		case MenuAction_End:
		{
			//PrintToServer("Menu End: Destroyed");
			CloseHandle(menu);
		}
		
		case MenuAction_VoteCancel:
		{
			PrintToServer("Cancel %d %d", param1, param2);
			
			if(g_iVoteStatus == MultiModVoteStatus_NoVote)
			{
				return 0;
			}
			
			int iTries = -1, iMaxTries = 50;
			bool bFound = false;
			int iIndex;
			
			while (++iTries < iMaxTries)
			{
				iIndex = GetRandomInt(0, g_iVoteItemCount - 1);
				if (GetArrayCell(g_Array_VoteItems_Enabled, iIndex) == true)
				{
					bFound = true;
					break;
				}
			}
			
			if (!bFound)
			{
				// Force it up
				iIndex = GetRandomInt(0, g_iVoteItemCount - 1);
				LogMessage("[MultiMod] Forcing random MOD as winner as a Winner could not be found.");
			}
			
			switch (g_iVoteBit_Current)
			{
				case MultiModVote_Map:
				{
					SetLastVoteWinner(iIndex, ModIndex_Null, 0, 0, false);
				}
				
				case MultiModVote_Mod:
				{
					SetLastVoteWinner(iIndex, GetArrayCell(g_Array_VoteItems_OriginalIndexes, iIndex), 0, 0, false);
				}
			}
			
			LogMessage("[MultiMod] Randomizing next mod/map as noone one has voted!");
		}
	}
	
	return 0;
}

void SetLastVoteWinner(int iIndex, int iModId, int iWinningVotes, int iTotalVotes, bool bSuccess)
{
	if(g_iVoteStatus == MultiModVoteStatus_NoVote)
	{
		return;
	}
	
	//PrintToServer("Second");
	g_iVoteBit_Progress |= g_iVoteBit_Current;
	
	char szName[MM_MAX_MAP_NAME];
	float flDelay = 0.0;
	
	switch (g_iVoteBit_Current)
	{
		case MultiModVote_Mod:
		{
			MultiMod_SetNextMod(iModId);
			MultiMod_GetModProp(iModId, MultiModProp_Name, szName, sizeof szName);
			
			if (bSuccess)
			{
				MultiMod_PrintToChatAll("The next \x04MOD \x01will be: \x03%s \x01(won by %d votes out of %d)", szName, iWinningVotes, iTotalVotes);
			}
			
			else
			{
				MultiMod_PrintToChatAll("The next MOD was chosen randomly as no one has voted. It will be \x04%s", szName);
			}
			
			if (Func_CheckVote_ReturnNextVote() == MultiModVote_Map)
			{
				flDelay = 5.0;
				MultiMod_PrintToChatAll("The\x04 Map \x1vote will start in \x04%0.1f \x01seconds", flDelay);
			}
		}
		
		case MultiModVote_Map:
		{
			GetArrayString(g_Array_VoteItems, iIndex, szName, sizeof szName);
			
			if (bSuccess)
			{
				MultiMod_PrintToChatAll("The next \x04Map\x01 will be: \x03%s \x01(won by %d votes out of %d)", szName, iWinningVotes, iTotalVotes);
			}
			
			else
			{
				MultiMod_PrintToChatAll("The next\x04 Map \x01was chosen randomly as no one has voted. It will be\x04 %s", szName);
			}
			
			GetArrayString(g_Array_VoteItems_Original, iIndex, szName, sizeof szName);
			PrintToServer("** Next Map %s", szName);
			DecideNextMap(szName, true);
		}
	}
	
	Call_StartForward(g_hForward_OnVoteFinished);
	{
		Call_PushCell(g_iVoteBit_Total);
		Call_PushCell(g_iVoteBit_Progress);
		Call_PushCell(g_iVoteBit_Current);
		Call_PushCell(MultiModVoteType_Normal);
		Call_PushCell(iIndex);
		Call_PushCell(iModId);
		Call_PushCell(iTotalVotes);
		Call_Finish();
	}
	
	g_iVoteBit_Current = MultiModVote_None;
	
	PrintToServer("Timer #1");
	CreateTimer(flDelay, Timer_CheckVotes, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckVotes(Handle hTimer)
{
	PrintToServer("TimerEnd #1");
	
	if(g_iVoteStatus == MultiModVoteStatus_NoVote)
	{
		return;
	}
	
	Func_CheckNextVoteAndStart();
}

public void VoteCallback_Results(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	if(g_iVoteStatus == MultiModVoteStatus_NoVote)
	{
		return;
	}
	
	//PrintToServer("First");
	//int[] iItemTotalVotes_WithPower = new int[g_iVoteItemsCount];
	//int[] iItemTotalVotes = new int[g_iVoteItemsCount];
	
	char szInfo[5];
	// Add votes to arrays
	for (int i, client, iItem; i < num_clients; i++)
	{
		client = client_info[i][VOTEINFO_CLIENT_INDEX];
		iItem = client_info[i][VOTEINFO_CLIENT_ITEM];
		
		//PrintToServer("Client %N voted %d", client, iItem);
		
		if (iItem == -1)
		{
			continue;
		}
		
		GetMenuItem(menu, iItem, szInfo, sizeof szInfo);
		
		iItem = StringToInt(szInfo);
		
		SetArrayCell(g_Array_VoteItems_Votes, iItem, GetArrayCell(g_Array_VoteItems_Votes, iItem) + g_iClientVotingPower[client]);
		SetArrayCell(g_Array_VoteItems_Votes_WithoutPower, iItem, GetArrayCell(g_Array_VoteItems_Votes_WithoutPower, iItem) + 1);
	}
	
	int iTopNumber = 0;
	int iVotes;
	int iTotalVotes;
	
	for (int i; i < g_iVoteItemCount; i++)
	{
		iVotes = GetArrayCell(g_Array_VoteItems_Votes, i);
		iTotalVotes += iVotes;
		
		if (iVotes >= iTopNumber)
		{
			iTopNumber = iVotes;
		}
	}
	
	int[] iTiedItemIndexes = new int[g_iVoteItemCount];
	int iTiedCount;
	for (int i; i < g_iVoteItemCount; i++)
	{
		iVotes = GetArrayCell(g_Array_VoteItems_Votes, i);
		
		if (iVotes == iTopNumber)
		{
			iTiedItemIndexes[iTiedCount++] = i;
		}
	}
	
	int iWinner = iTiedItemIndexes[GetRandomInt(0, iTiedCount - 1)];
	
	//delete menu;
	
	switch (g_iVoteBit_Current)
	{
		case MultiModVote_Map:
		{
			SetLastVoteWinner(iWinner, ModIndex_Null, iTopNumber, iTotalVotes, true);
		}
		
		case MultiModVote_Mod:
		{
			SetLastVoteWinner(iWinner, GetArrayCell(g_Array_VoteItems_OriginalIndexes, iWinner), iTopNumber, iTotalVotes, true);
		}
	}
}

void DecideNextMap(char[] szInfo, bool bChange)
{
	if (!szInfo[0])
	{
		GetCurrentMap(g_szNextMap, sizeof g_szNextMap);
	}
	
	else
	{
		strcopy(g_szNextMap, sizeof g_szNextMap, szInfo);
	}
	
	if(g_bCanSetNextMap)
	{
		SetNextMap(g_szNextMap);
	}
	
	if(bChange)
	{
		if (g_bForceChange)
		{
			PrintToServer("Timer #2");
			g_hCurrentTimer = CreateTimer(4.0, Func_ChangeMap,_, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Func_ChangeMap(Handle hTimer)
{
	PrintToServer("TimerEnd #2");
	g_hCurrentTimer = null;
	//ServerCommand("changelevel %s", g_szNextMap);
	ForceChangeLevel(g_szNextMap, "MMVote");
}

public int Native_GetVoteItemName(Handle hPlugin, int iParamCount)
{
	// native void MultiMod_Vote_GetVoteItemName(int iVoteItem, char[] szItemName, int iMaxSize, bool bUnedited = true);
	int iVoteItem = GetNativeCell(1);
	int iSize = GetNativeCell(3);
	char[] szItemName = new char[iSize];
	switch (GetNativeCell(4))
	{
		case true:
		{
			GetArrayString(g_Array_VoteItems_Original, iVoteItem, szItemName, iSize);
		}
		
		case false:
		{
			GetArrayString(g_Array_VoteItems_Original, iVoteItem, szItemName, iSize);
		}
	}
	
	SetNativeString(2, szItemName, iSize);
}

public int Native_GetVoteItemCount(Handle hPlugin, int iParamCount)
{
	return g_iVoteItemCount;
}

public int Native_GetVoteItemVotes(Handle hPlugin, int iParamCount)
{
	switch (GetNativeCell(2))
	{
		case true:
		{
			return GetArrayCell(g_Array_VoteItems_Votes_WithoutPower, GetNativeCell(1));
		}
		
		case false:
		{
			return GetArrayCell(g_Array_VoteItems_Votes, GetNativeCell(1));
		}
	}
	
	return 0;
}

public int Native_GetTotalVotes(Handle hPlugin, int iParamCount)
{
	switch (GetNativeCell(1))
	{
		case true:
		{
			return g_iTotalVotes_WithoutPower;
		}
		
		case false:
		{
			return g_iTotalVotes;
		}
	}
	
	return 0;
}

// (MultiModVote iAllVoteBit, MultiModVote iStartingVote, bool bForceChange);
public int Native_StartVote(Handle hPlugin, int iParamCount)
{
	return Func_PrepareVote(GetNativeCell(1), GetNativeCell(2));
}

public int Native_SetClientVotingPower(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	if (!IsValidPlayer(client))
	{
		return 0;
	}
	
	int iPower = GetNativeCell(2);
	if (iPower < 0)
	{
		return 0;
	}
	
	g_iClientVotingPower[client] = iPower;
	//ThrowNativeError(SP_ERROR_ABORTED, "Native Set Vote Power: %d", g_iClientVotingPower[client]);
	return 1;
}

public int Native_GetClientVotingPower(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	if (!IsValidPlayer(client))
	{
		return -1;
	}
	
	return g_iClientVotingPower[client];
}

bool IsValidPlayer(int client)
{
	if (!(1 <= client <= MaxClients))
	{
		return false;
	}
	
	return true;
}

public int Native_GetVoteStatus(Handle hPlugin, int iParams)
{
	return view_as<int>(g_iVoteStatus);
}

public int Native_GetAllVoteBit(Handle hPlugin, int iParams)
{
	return view_as<int>(g_iVoteBit_Total);
}

public int Native_GetVoteProgressBit(Handle hPlugin, int iParams)
{
	return view_as<int>(g_iVoteBit_Progress);
}

public int Native_GetCurrentVote(Handle hPlugin, int iParams)
{
	return view_as<int>(g_iVoteBit_Current);
}

public int Native_GetCurrentVoteType(Handle hPlugin, int iParams)
{
	return view_as<int>(MultiModVoteType_Normal);
}

void SetArrayValue(any[] Array, int iSize, any Value, int iStart)
{
	for (int i = iStart; i < iSize; i++)
	{
		Array[i] = Value;
	}
} 