#pragma semicolon 1

#include <sourcemod>
#include <multimod>

new bool:g_bVotingStarted = false;
new bool:g_bForceChange = MM_DEFAULT_FORCE_CHANGE;

new String:g_szNextMap[60];

new Handle:gMapsVoteMenu;
new Handle:gModVoteMenu;

new g_iNextModId = -1;
new g_iCurrModId;

//new Handle:gForwardHandle;
//new Handle:g_hTimer;

new Handle:g_hForward;

public Plugin:myinfo = 
{
	name = "Multimod Plugin: Voting",
	author = "Khalid",
	description = "Voting system for Multimod plugin",
	version = MM_VERSION_STR,
	url = "No"
};

enum MultiModVoteTypes
{
	MultiModVoteType_Mod,
	MultiModVoteType_Map,
	MultiModVoteType_Normal
}

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLate, String:szError[], err_max)
{	
	CreateNative("MultiMod_StartVote", Native_StartVote);	
	
	RegPluginLibrary(MM_LIB_VOTE);
	
	if(bLate)
	{
		if(MultiMod_IsLoaded())
		{
			OnMapStart();
		}
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	//g_iMaxPlayers = GetMaxClients();
	
	RegAdminCmd("sm_startvote", AdminCmdStartVote, MM_ACCESS_FLAG_BIT, "[vote type: mod, map (typing help here will display usage)] [Change map immidetly after vote: noforce, no (anything else will force change)]");
	RegAdminCmd("sm_votemod", AdminCmdVoteMod, MM_ACCESS_FLAG_BIT, "Will start the mod/map vote");
	
	g_hForward = CreateGlobalForward("MultiMod_VotingStarted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

/*
public MultiMod_Loaded(MultiModLoad:iLoad)
{
	if(bLate)
	{
		if(iLoad == MultiModLoad_Loaded)
		{
			OnMapStart();
		}
	}	
}*/

public OnMapStart()
{
	g_bVotingStarted = false;
	g_bForceChange = false;
	g_iNextModId = -1;
	
	g_iCurrModId = MultiMod_GetCurrentModId();
	
	CreateTimer(3.0, Func_Timer,_, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	//CloseHandle(g_hTimer);
}

public Action:AdminCmdVoteMod(client, iArgs)
{
	if(g_bVotingStarted)
	{
		PrintToConsole(client, "** Voting has already started.");
		return Plugin_Handled;
	}
	
	//g_bVotingStarted = false;
	
	new MultiModVoteTypes:iType = MultiModVoteType_Normal;
	new bool:bForce = true;
	
	Func_PrepareVote(iType, bForce);
	PrintToConsole(client, "** Started the vote");
	return Plugin_Handled;
}

public Action:AdminCmdStartVote(client, iArgs)
{
	if(g_bVotingStarted)
	{
		PrintToConsole(client, "** Voting has already started.");
		return Plugin_Handled;
	}
	
	//g_bVotingStarted = false;
	
	new MultiModVoteTypes:iType = MultiModVoteType_Normal;
	new bool:bForce = true;
	
	if(iArgs > 0)
	{
		new String:szVoteTypeArg[10], String:szForceArg[10];
		GetCmdArg(1, szVoteTypeArg, sizeof szVoteTypeArg);
		GetCmdArg(2, szForceArg, sizeof szForceArg);
		
		if(StrEqual(szVoteTypeArg, "help", false))
		{
			PrintToConsole(client, "Usage: \nsm_startvote [vote type: mod, map (typing help here will display usage)] [Change map immidetly after vote: noforce, no (anything else will force change)]");
			return Plugin_Handled;
		}
		
		if(StrEqual(szForceArg, "no", false) || StrEqual(szForceArg, "noforce", false))
		{
			bForce = false;
		}
		
		if(StrEqual(szVoteTypeArg, "mod", false))
		{
			iType = MultiModVoteType_Mod;
		}
		else if(StrEqual(szVoteTypeArg, "map", false))
		{
			iType = MultiModVoteType_Map;
		}
	}
	
	Func_PrepareVote(iType, bForce);
	PrintToConsole(client, "** Started the vote");
	return Plugin_Handled;
}

// Edit this for mp_timelimit
public Action:Func_Timer(Handle:hTimer)
{
	if(g_bVotingStarted)
	{
		return Plugin_Stop;
	}
	
	static iTime;
	if(GetMapTimeLeft(iTime) && iTime > 0)
	{
		if( iTime <= (3 * 60) )
		{
			Func_PrepareVote(MultiModVoteType_Normal, MM_DEFAULT_FORCE_CHANGE);
			
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

Func_PrepareVote(MultiModVoteTypes:iVoteType, bool:bForce)
{
	g_bVotingStarted = true;
	g_bForceChange = bForce;
	
	switch(iVoteType)
	{
		case MultiModVoteType_Mod:
		{
			if(g_iNextModId != -1)
			{
				MultiMod_SetNextMod(MM_NEXTMOD_CANCEL);
				g_iNextModId = -1;
			}
			
			Func_StartModVote();
			
		}
		
		case MultiModVoteType_Map:
		{
			if( (g_iNextModId = MultiMod_GetNextModId() ) == -1 )
			{
				g_iNextModId = g_iCurrModId;
			}
			
			Func_StartMapVote();
		}
		
		case MultiModVoteType_Normal:
		{
			new iNum;
			if( ( iNum = MultiMod_GetNextModId() ) != -1)
			{
				MM_PrintToChat(0, "Skipped MOD voting as the next MOD was chosen by an ADMIN");
		
				g_iNextModId = iNum;
				Func_StartMapVote();
			}
			
			else
			{
				Func_StartModVote();
			}
		}
	}
	
	Call_StartForward(g_hForward);
	Call_PushCell(iVoteType);
	Call_PushCell(bForce);
	Call_PushCell(g_iNextModId);
	Call_Finish();
}

Func_StartModVote()
{
	new Handle:hModsNames = MultiMod_GetNameArray();
	
	//new iDrawType
	
	gModVoteMenu = CreateMenu(VotingHandler, MENU_ACTIONS_ALL);
	SetMenuExitButton(gModVoteMenu, false);
	SetMenuTitle(gModVoteMenu, "Choose the next MOD:");
	
	new iSize = GetArraySize(hModsNames);
	
	//new iCurrModId = MultiMod_GetCurrentModId();
	
	new i, String:szInfo[5], String:szName[MAX_MOD_NAME], String:szDisplayName[MAX_MOD_NAME + 10];
	for(i = 0; i < iSize; i++)
	{
		GetArrayString(hModsNames, i, szName, sizeof(szName));
		IntToString(i, szInfo, sizeof(szInfo));
		
		if( i == g_iCurrModId )
		{
			FormatEx(szDisplayName, sizeof szDisplayName, "%s (Current Mod)", szName);
		}
		
		else if(MultiMod_GetModLock(i) != MultiModLock_NotLocked)
		{
			FormatEx(szDisplayName, sizeof szDisplayName, "%s [BLOCKED]", szName);
		}
		
		else 
		{ 
			FormatEx(szDisplayName, sizeof szDisplayName, szName);
		}
		
		AddMenuItem(gModVoteMenu, szInfo, szDisplayName, ITEMDRAW_DEFAULT);
	}
	
	VoteMenuToAll(gModVoteMenu, VOTING_TIME);
	
	MM_PrintToChat(0, "Voting for the next MOD has started!");
	LogMessage("[MultiMod] Voting for the next MOD has started!");
}

public VotingHandler(Handle:menu, MenuAction:iAction, iParam1, iParam2)
{
	switch (iAction)
	{
		case MenuAction_DrawItem:
		{
			if(menu == gMapsVoteMenu)
			{
				return 0;
			}
			
			#if defined BLOCK_CURRENT_MOD_IN_VOTE
			if(iParam2 == g_iCurrModId)
			{
				return ITEMDRAW_DISABLED;
			}
			#endif
			
			return MultiMod_GetModLock(iParam2) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
				
		}
		
		case MenuAction_Select:
		{
			new String:szInfo[60], String:szName[60], iDump;
			GetMenuItem(menu, iParam2, szInfo, sizeof szInfo, iDump, szName, sizeof szName);
			
			//new String:szModProps[4][60];
			//MultiMod_GetModProps(StringToInt(szInfo), szModProps[0], sizeof szModProps[]);
			
			new String:szPlayerName[60];
			GetClientName(iParam1, szPlayerName, sizeof szPlayerName);
			
			if(menu == gMapsVoteMenu)
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
			
			if(menu == gMapsVoteMenu)
			{
				DecideNextMap(g_szNextMap);
			}
			
			else 
			{
				CreateTimer(5.0, Timer_StartMapVote);
			}
		}
		
		case MenuAction_VoteCancel:
		{
			SetWinner(menu, GetRandomInt(0, GetMenuItemCount(menu)), 0, false);
			LogMessage("[MULTIMOD] Randomizing next mod/map as not one has voted!");
		}
	}
	
	return 0;
}

public Action:Timer_StartMapVote(Handle:hTimer)
{
	Func_StartMapVote();
}

SetWinner(Handle:menu, iParam1, iParam2, bool:iSuccess)
{
	new String:szInfo[60], String:szName[60], iDump;
	GetMenuItem(menu, iParam1, szInfo, sizeof szInfo, iDump, szName, sizeof szName);
			
	if(menu == gModVoteMenu)
	{
		new iWinner;
		iWinner = StringToInt(szInfo);
				
		MultiMod_SetNextMod(iWinner);
		g_iNextModId = iWinner;
	}
		
	else if(gMapsVoteMenu == menu)
	{
		g_szNextMap = szInfo;
	}
		
	if(iSuccess)
	{
		new iWinningVotes, iTotal;
		GetMenuVoteInfo(iParam2, iWinningVotes, iTotal);
		MM_PrintToChat(0, "The next \x04%s \x01will be: \x03%s \x01(won by %d votes out of %d)", menu == gMapsVoteMenu ? "map" : "MOD", szName, iWinningVotes, iTotal);
	}
}

Func_StartMapVote()
{
	gMapsVoteMenu = CreateMenu(VotingHandler, MENU_ACTIONS_ALL);
	
	new Handle:hMaps;
	
	new iMapsCount = ReadFiles_ModMaps(g_iNextModId, hMaps);
	if(!iMapsCount)
	{
		MM_PrintToChat(0, "Map voting was cancelled as there are no available maps to vote on.");
		DecideNextMap("");
		return;
	}
	
	new iVoteMapsCount = iMapsCount > MAX_VOTE_MAPS ? MAX_VOTE_MAPS : iMapsCount;
	
	new Array[iMapsCount];
	new String:szMapName[60];
	
	new iMapsAdded, iMapIndex;
	while (iMapsAdded < iVoteMapsCount)
	{
		iMapIndex = GetRandomInt(0, iMapsCount - 1);
		if(Array[iMapIndex])
		{
			continue;
		}
		
		Array[iMapIndex] = 1;
		GetArrayString(hMaps, iMapIndex, szMapName, sizeof szMapName);
		AddMenuItem(gMapsVoteMenu, szMapName, szMapName);
		iMapsAdded++;
	}
	
	CloseHandle(hMaps);
	
	MM_PrintToChat(0, "Voting for the next map has started!");
	LogMessage("[MultiMod] Voting for the next map has started!");
	
	VoteMenuToAll(gMapsVoteMenu, VOTING_TIME);
}

DecideNextMap(String:szInfo[])
{
	if(!szInfo[0])
	{
		GetCurrentMap(g_szNextMap, sizeof g_szNextMap);
	}
	
	SetNextMap(g_szNextMap);
	
	if(g_bForceChange)
	{
		CreateTimer(4.0, Func_ChangeMap);
	}
}

public Action:Func_ChangeMap(Handle:hTimer)
{
	ServerCommand("changelevel %s", g_szNextMap);
}

stock ReadFiles_ModMaps(iModId, &Handle:hMapListHandle = INVALID_HANDLE)
{
	#define MAX_MAP_NAME_LENGTH		60
	
	new String:szMapsFile[60];
	MultiMod_GetModProp(iModId, MultiModProp_Map, szMapsFile, sizeof szMapsFile, true);
	
	new String:szFile[120];
	FormatEx(szFile, sizeof szFile, "cfg/%s/%s", MM_FOLDER_MAIN, szMapsFile);
	
	new Handle:f = OpenFile(szFile, "r");
	if(f == INVALID_HANDLE)
	{
		LogMessage("Maps file not found: %s", szFile);
		if(!szMapsFile[0])
		{
			return 0;
		}
		
		LogMessage("Creating a new maps file: %s", szFile);
		f = OpenFile(szFile, "w");
		
		WriteFileLine(f,
		 "# --------------------------------------------------------------------------------------------------\
		\n# |                                    MultiMod Maps File                                            |\
		\n# --------------------------------------------------------------------------------------------------\
		\n# Any line beginning with a ';', '#' or '//' is a comment.\
		\n# Write each map in one line without the .bsp extension.");
		
		CloseHandle(f);
		
		return 0;
	}
	
	hMapListHandle = CreateArray(MAX_MAP_NAME_LENGTH + 1);
	
	new String:szLine[200], iMaps;
	while(!IsEndOfFile(f) && ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		
		if(!szLine[0])
		{
			continue;
		}
		
		if(szLine[0] == ';' || szLine[0] == '#' || ( szLine[0] == '/' && szLine[1] == '/' ))
		{
			continue;
		}
		
		if(StrContains(szLine, ".bsp", false) != -1)
		{
			ReplaceString(szLine, sizeof szLine, ".bsp", "");
		}
		
		if(IsMapValid(szLine))
		{
			if(strlen(szLine) > MAX_MAP_NAME_LENGTH)
			{
				continue;
			}
			
			PushArrayString(hMapListHandle, szLine);
			++iMaps;
		}
	}
	
	CloseHandle(f);
	
	return iMaps;
}

public Native_StartVote(Handle:hPlugin, iParamCount)
{
	if(g_bVotingStarted)
	{
		return 0;
	}
	
	Func_PrepareVote(MultiModVoteTypes:GetNativeCell(1), bool:GetNativeCell(2));
	return 1;
}