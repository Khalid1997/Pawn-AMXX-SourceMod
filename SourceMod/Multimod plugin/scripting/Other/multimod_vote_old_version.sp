#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multimod>

MultiModVoteStatus g_iVoteStatus = MultiModVoteStatus_NoVote;
bool g_bForceChange;

char g_szNextMap[MM_MAX_MAP_NAME];

Menu g_VoteMenu;
ArrayList g_Array_VoteItems;

#define CheckVoteStatus(%1) (g_iVoteStatus == %1)

public Plugin myinfo = 
{
	name = "Multimod Plugin: Voting", 
	author = "Khalid", 
	description = "Voting system for Multimod plugin", 
	version = MM_VERSION_STR, 
	url = "No"
};

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int err_max)
{
	CreateNative("MultiMod_StartVote", Native_StartVote);
	CreateNative("MultiMod_GetVoteStatus", Native_GetVoteStatus);
	CreateNative("MultiMod_IsCurrentModBlockedInVote", Native_IsCurrentModBlockedInVote);
	
	RegPluginLibrary(MM_LIB_VOTE);
	
	if (bLate)
	{
		if (MultiMod_IsLoaded())
		{
			OnMapStart();
		}
	}
	
	//g_hForward_VotingStarted = CreateGlobalForward("MultiMod_OnVotingStarted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForward_VoteStarted_Pre = CreateGlobalForward("MultiMod_OnVoteStart_Pre", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForward_VoteStarted_Post = CreateGlobalForward("MultiMod_OnVoteStart_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_mm_startvote", AdminCmdStartVote, MM_ACCESS_FLAG_BIT, "[vote type: mod, map (typing help here will display usage)] [Change map immidetly after vote: noforce, no (anything else will force change)]");
	RegAdminCmd("sm_votemod", AdminCmdVoteMod, MM_ACCESS_FLAG_BIT, "Will start the mod/map vote");
	
	gArray_MapsInVote = CreateArray(MM_MAX_MAP_NAME);
}

public void OnMapStart()
{
	g_bForceChange = false;
	g_iVoteStatus = MultiModVoteStatus_NoVote;
	
	ClearArray(gArray_MapsInVote);
	
	CreateTimer(3.0, Func_Timer, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/* ***
public void OnMapEnd()
{
	// Not needed as we set the flag TIMER_FLAG_NO_MAPCHANGE for the timer.
	// CloseHandle(g_hTimer);
} *** */

public Action AdminCmdVoteMod(int client, int iArgs)
{
	if (CheckVoteStatus(MultiModVoteStatus_Running))
	{
		ReplyToCommand(client, "** Voting has already started.");
		return Plugin_Handled;
	}
	
	if (CheckVoteStatus(MultiModVoteStatus_VoteEnded))
	{
		ReplyToCommand(client, "** Voting has already finished.");
		return Plugin_Handled;
	}
	
	MultiModVote iParentVoteType = MultiModVote_Normal;
	bool bForce = true;
	
	Func_PrepareVote(iParentVoteType, bForce);
	ReplyToCommand(client, "** Started the vote");
	return Plugin_Handled;
}

public Action AdminCmdStartVote(int client, int iArgs)
{
	if (CheckVoteStatus(MultiModVoteStatus_Running))
	{
		ReplyToCommand(client, "** Voting has already started.");
		return Plugin_Handled;
	}
	
	if (CheckVoteStatus(MultiModVoteStatus_VoteEnded))
	{
		ReplyToCommand(client, "** Voting has already finished.");
		return Plugin_Handled;
	}
	
	bool bForce = true;
	MultiModVote iParentVoteType = MultiModVote_Normal;
	
	if (iArgs > 0)
	{
		char szArg[20];
		for (int i = 1; i < iArgs; i++)
		{
			GetCmdArg(i, szArg, sizeof szArg);
			
			if (StrEqual(szArg, "help", false))
			{
				ReplyToCommand(client, "Usage: \nsm_mm_startvote \"Args1\" \"Arg2\" ... \n\
				Args can be mod, map, normal, or noforce");
				return Plugin_Handled;
			}
			
			if (StrEqual(szArg, "mod", false))
			{
				iParentVoteType = MultiModVote_Mod;
			}
			
			else if (StrEqual(szArg, "map", false))
			{
				iParentVoteType = MultiModVote_Map;
			}
			
			else if (StrEqual(szArg, "normal", false))
			{
				iParentVoteType = MultiModVote_Normal;
			}
			
			else if (StrEqual(szArg, "noforce", false) || StrEqual(szArg, "nochange", false))
			{
				bForce = false;
			}
		}
	}
	
	Func_PrepareVote(iParentVoteType, bForce);
	ReplyToCommand(client, "** Started the vote");
	return Plugin_Handled;
}

// Edit this for mp_timelimit
public Action Func_Timer(Handle hTimer)
{
	if (g_iVoteStatus >= MultiModVoteStatus_Running)
	{
		return Plugin_Stop;
	}
	
	static int iTime;
	if (GetMapTimeLeft(iTime) && iTime > 0)
	{
		if (iTime <= (3 * 60))
		{
			Func_PrepareVote(MultiModVote_Normal, MM_DEFAULT_FORCE_CHANGE);
			return Plugin_Stop;
		}
	}
	
	else
	{
		// ( Timeleft < 0 ) ----> MaxRounds
		//return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void Func_PrepareVote(MultiModVote iParentVoteType, bool bForce)
{
	bool bResetNextMod = false;
	MultiModVote iCurrentVoteType;
	
	switch (iParentVoteType)
	{
		case MultiModVote_Mod:
		{
			if (MultiMod_GetNextModId() != ModIndex_Null)
			{
				// Cancel the next mod that was set
				bResetNextMod = true;
			}
			
			iCurrentVoteType = MultiModVote_Mod;
			Func_StartModVote();
		}
		
		case MultiModVote_Map:
		{
			iCurrentVoteType = MultiModVote_Map;
			Func_StartMapVote();
		}
		
		case MultiModVote_Normal:
		{
			if (MultiMod_GetNextModId() != ModIndex_Null)
			{
				MultiMod_PrintToChat(0, "Skipped MOD voting as the next MOD was chosen by an ADMIN");
				
				iCurrentVoteType = MultiModVote_Map;
				Func_StartMapVote();
			}
			
			else
			{
				iCurrentVoteType = MultiModVote_Mod;
				Func_StartModVote();
			}
		}
	}
	
	Action iRet;
	Call_StartForward(g_hForward_VoteStarted_Pre);
	Call_PushCell(iParentVoteType);
	Call_PushCell(iCurrentVoteType);
	Call_PushCell(bForce);
	Call_Finish(iRet);
	
	if (iRet == Plugin_Handled || iRet == Plugin_Stop)
	{
		return;
	}
	
	g_iParentVoteType = iParentVoteType;
	g_iCurrentVoteType = iCurrentVoteType;
	g_bForceChange = bForce;
	
	g_iVoteStatus = MultiModVoteStatus_Running;
	
	if (bResetNextMod)
	{
		MultiMod_SetNextMod(ModIndex_Null);
	}
	
	switch (iCurrentVoteType)
	{
		case MultiModVote_Mod:
		{
			Func_StartModVote();
		}
		
		case MultiModVote_Map:
		{
			Func_StartMapVote();
		}
	}
	
	Call_StartForward(g_hForward_VoteStarted_Post);
	Call_PushCell(iParentVoteType);
	Call_PushCell(iCurrentVoteType);
	Call_PushCell(bForce);
	Call_Finish(iRet);
}

void Func_StartModVote()
{
	Handle hModsNames = MultiMod_GetMultiModArray(MultiModProp_Name);
	
	//new iDrawType
	
	gModVoteMenu = CreateMenu(VotingHandler, MENU_ACTIONS_ALL);
	SetMenuExitButton(gModVoteMenu, false);
	SetMenuTitle(gModVoteMenu, "Choose the next MOD:");
	
	int iSize = GetArraySize(hModsNames);
	int iCurrentModId = MultiMod_GetCurrentModId();
	int i;
	char szInfo[5], szName[MM_MAX_MOD_PROP_LENGTH], szDisplayName[MM_MAX_MOD_PROP_LENGTH + 10];
	
	for (i = 0; i < iSize; i++)
	{
		GetArrayString(hModsNames, i, szName, sizeof(szName));
		IntToString(i, szInfo, sizeof(szInfo));
		
		if (i == iCurrentModId)
		{
			FormatEx(szDisplayName, sizeof szDisplayName, "%s (Current Mod)", szName);
		}
		
		if (MultiMod_GetModLock(i) != MultiModLock_NotLocked)
		{
			FormatEx(szDisplayName, sizeof szDisplayName, "%s [BLOCKED]", szName);
		}
		
		else
		{
			FormatEx(szDisplayName, sizeof szDisplayName, szName);
		}
		
		AddMenuItem(gModVoteMenu, szInfo, szDisplayName, ITEMDRAW_DEFAULT);
	}
	
	if (IsVoteInProgress())
	{
		CancelVote();
	}
	
	VoteMenuToAll(gModVoteMenu, VOTING_TIME);
	
	MultiMod_PrintToChat(0, "Voting for the next MOD has started!");
	LogMessage("[MultiMod] Voting for the next MOD has started!");
}

public int VotingHandler(Menu menu, MenuAction iAction, int iParam1, int iParam2)
{
	switch (iAction)
	{
		case MenuAction_DrawItem:
		{
			if (menu == gMapsVoteMenu)
			{
				return ITEMDRAW_DEFAULT;
			}
			
			#if defined BLOCK_CURRENT_MOD_IN_VOTE
			char szInfo[5];
			GetMenuItem(menu, iParam2, szInfo, sizeof szInfo);
			
			if (StringToInt(szInfo) == MultiMod_GetCurrentModId())
			{
				return ITEMDRAW_DISABLED;
			}
			#endif
			
			return MultiMod_GetModLock(iParam2) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			char szInfo[5], szName[60];
			int iDump;
			
			GetMenuItem(menu, iParam2, szInfo, sizeof szInfo, iDump, szName, sizeof szName);
			
			char szPlayerName[MAX_NAME_LENGTH];
			GetClientName(iParam1, szPlayerName, sizeof szPlayerName);
			
			if (menu == gMapsVoteMenu)
			{
				PrintToChatAll(" \x04%s \x01chose \x03%s", szPlayerName, szName);
			}
			
			else
			{
				PrintToChatAll(" \x04%s \x01chose \x03%s", szPlayerName, szName);
			}
		}
		
		case MenuAction_VoteEnd:
		{
			SetWinner(menu, iParam1, iParam2, true);
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_VoteCancel:
		{
			SetWinner(menu, GetRandomInt(0, GetMenuItemCount(menu) - 1), 0, false);
			PrintDebug("[MULTIMOD] Randomizing next mod/map as noone one has voted!");
		}
	}
	
	return 0;
}

public Action Timer_StartMapVote(Handle hTimer)
{
	Func_StartMapVote();
}

void SetWinner(Menu menu, int iParam1, int iParam2, bool iSuccess)
{
	char szInfo[5], szName[MM_MAX_MAP_NAME];
	int iDump;
	GetMenuItem(menu, iParam1, szInfo, sizeof szInfo, iDump);
	
	int iWinnerIndex;
	iWinnerIndex = StringToInt(szInfo);
	PrintToServer("WinnerIndex %s", szInfo);
	
	int iWinningVotes, iTotal;
	if (iSuccess)
	{
		GetMenuVoteInfo(iParam2, iWinningVotes, iTotal);
	}
	
	if (menu == gModVoteMenu)
	{
		MultiMod_SetNextMod(iWinnerIndex);
		MultiMod_GetModProp(iWinnerIndex, MultiModProp_Name, szName, sizeof szName);
		
		float flDelay = 5.0;
		CreateTimer(flDelay, Timer_StartMapVote);
		
		if (iSuccess)
		{
			MultiMod_PrintToChat(0, "The next \x04MOD \x01will be: \x03%s \x01(won by %d votes out of %d)", szName, iWinningVotes, iTotal);
		}
		
		else
		{
			MultiMod_PrintToChat(0, "The next MOD was chosen randomly as no one has voted. It will be \x04%s", szName);
		}
		
		MultiMod_PrintToChat(0, "Voting for the next Map for MOD %s will start in %0.1f seconds!", szName, flDelay);
	}
	
	else if (gMapsVoteMenu == menu)
	{
		//strcopy(g_szNextMap, sizeof g_szNextMap, szInfo);
		GetArrayString(gArray_MapsInVote, iWinnerIndex, szName, sizeof szName);
		DecideNextMap(szName);
		
		if (iSuccess)
		{
			MultiMod_PrintToChat(0, "The next \x04Map\x01 will be: \x03%s \x01(won by %d votes out of %d)", szName, iWinningVotes, iTotal);
		}
		
		else
		{
			MultiMod_PrintToChat(0, "The next Map was chosen randomly as no one has voted. It will be \x04%s", szName);
		}
	}
}

void Func_StartMapVote()
{
	gMapsVoteMenu = CreateMenu(VotingHandler, MENU_ACTIONS_ALL);
	
	ClearArray(gArray_MapsInVote);
	int iMapsCount;
	
	int iModId = MultiMod_GetNextModId();
	if (iModId == ModIndex_Null)
	{
		iModId = MultiMod_GetCurrentModId();
	}
	
	MultiMod_PassModListFromMod(iModId, ModList_Maps, HandleType_ArrayList, gArray_MapsInVote, iMapsCount);
	if (iMapsCount <= 0)
	{
		MultiMod_PrintToChat(0, "Map voting was cancelled as there are no available maps to vote on.");
		LogMessage("[MultiMod] Map voting was cancelled as there are no available maps to vote on.");
		DecideNextMap("");
		return;
	}
	
	char szNextModName[MM_MAX_MOD_PROP_LENGTH];
	MultiMod_GetModProp(iModId, MultiModProp_Name, szNextModName, sizeof szNextModName);
	
	SetMenuTitle(gMapsVoteMenu, "Choose the Next Map for Mod [%s]:", szNextModName);
	
	int iVoteMapsCount = iMapsCount > MAX_VOTE_MAPS ? MAX_VOTE_MAPS : iMapsCount;
	
	int[] Array = new int[iMapsCount];
	
	char szMapName[MM_MAX_MAP_NAME];
	
	int iMapsAdded, iMapIndex;
	char szInfo[5];
	while (iMapsAdded < iVoteMapsCount)
	{
		iMapIndex = GetRandomInt(0, iMapsCount - 1);
		if (Array[iMapIndex])
		{
			continue;
		}
		
		Array[iMapIndex] = 1;
		GetArrayString(gArray_MapsInVote, iMapIndex, szMapName, sizeof szMapName);
		
		IntToString(iMapIndex, szInfo, sizeof szInfo);
		AddMenuItem(gMapsVoteMenu, szInfo, szMapName);
		iMapsAdded++;
	}
	
	MultiMod_PrintToChat(0, "Voting for the next map has started!");
	LogMessage("[MultiMod] Voting for the next map has started!");
	
	if (IsVoteInProgress())
	{
		CancelVote();
	}
	
	VoteMenuToAll(gMapsVoteMenu, VOTING_TIME);
}

void DecideNextMap(char[] szInfo)
{
	if (!szInfo[0])
	{
		GetCurrentMap(g_szNextMap, sizeof g_szNextMap);
	}
	
	else
	{
		strcopy(g_szNextMap, sizeof g_szNextMap, szInfo);
		SetNextMap(g_szNextMap);
	}
	
	if (g_bForceChange)
	{
		CreateTimer(4.0, Func_ChangeMap);
	}
}

public Action Func_ChangeMap(Handle hTimer)
{
	ServerCommand("changelevel %s", g_szNextMap);
}

public int Native_StartVote(Handle hPlugin, int iParamCount)
{
	if (g_iVoteStatus >= MultiModVoteStatus_Running)
	{
		return 0;
	}
	
	Func_PrepareVote(view_as<MultiModVote>(GetNativeCell(1)), view_as<bool>(GetNativeCell(2)));
	return 1;
}

public int Native_GetVoteStatus(Handle hPlugin, int iParams)
{
	return view_as<int>(g_iVoteStatus);
}

public int Native_IsCurrentModBlockedInVote(Handle hPlugin, int iParams)
{
	#if defined BLOCK_CURRENT_MOD_IN_VOTE
	return true;
	#else
	return false;
	#endif
} 