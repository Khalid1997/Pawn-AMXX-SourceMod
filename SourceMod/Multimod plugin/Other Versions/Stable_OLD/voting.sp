/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <multimod>

new bool:g_bVotingStarted = false;
new bool:g_bForceChange = true;

new String:g_szNextMap[60];

new Handle:gMapsVoteMenu;
new Handle:gModVoteMenu;

new g_iNextMod = -1
new g_iCurrModId

new Handle:gMapsList;

new Handle:gForwardHandle;

public Plugin:myinfo = 
{
	name = "MapChooser Multimod",
	author = "Khalid",
	description = "Voting system for Multimod plugin",
	version = "1.5.2",
	url = "No"
}

/*
public OnMapTimeLeftChanged()
{
	if (GetArraySize(g_MapList))
	{
		SetupTimeleftTimer();
	}
}*/

public OnPluginStart()
{
	gForwardHandle = CreateGlobalForward("Voting_VoteStarted", ET_Ignore, Param_Cell);
	//gForwardHandle = CreateGlobalForward("Voting_VoteEnded", ET_Ignore, Param_Cell);
	gMapsList = CreateArray(60);
	
	//g_iMaxPlayers = GetMaxClients();
	
	RegAdminCmd("sm_votemod", AdminCmdStartVote, ADMFLAG_ROOT, "Starts mod voting");
}

public OnMapEnd()
{
	// Not needed
	//CloseHandle(gTimer);
}

public OnMapStart()
{
	g_bVotingStarted = false;
	g_bForceChange = false;
	g_iNextMod = -1;
	
	g_iCurrModId = MultiMod_GetCurrentModId();
	
	ClearArray(gMapsList);
	
	CreateTimer(3.0, Func_Timer,_, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:AdminCmdStartVote(client, iArgs)
{
	if(Vote_StartVote())
	{
		PrintToConsole(client, "** Started the vote");
	}
	
	else
	{
		PrintToConsole(client, "** Voting has already started.");
	}
	
	return Plugin_Handled;
}

public Vote_StartVote()
{
	if(g_bVotingStarted)
	{
		
		return 0;
	}
	
	// IMPORTANT
	g_bForceChange = true;
	StartVoting();
	return 1;
}


public Action:Func_Timer(Handle:hTimer)
{
	if(g_bVotingStarted)
	{
		return Plugin_Stop;
	}
	
	PrintToServer("Timer");
	static iTime;
	if(GetMapTimeLeft(iTime) && iTime > 0)
	{
		if( iTime <= (3 * 60) )
		{
			PrintToServer("StartVote");
			StartVoting();
			return Plugin_Stop;
		}
	}
	
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

StartVoting()
{
	g_bVotingStarted = true;
	new iNum
	if( ( iNum = MultiMod_GetNextModId() ) != -1)
	{
		MM_PrintToChat(0, "Skipped MOD voting as the next MOD was chosen by an ADMIN");
		
		g_iNextMod = iNum
		Func_StartMapVote(Handle:0);
		return;
	}
	
	new Handle:hModsNames = MultiMod_GetNameArray()
	
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
			
			/*#if defined BLOCK_CURRENT_MOD_IN_VOTE
			iDrawType = ITEMDRAW_DISABLED;
			#else
			iDrawType = ITEMDRAW_DEFAULT;
			#endif*/
		}
		
		else if(MultiMod_GetModBlockStatus(i))
		{
			PrintToServer("** Block status %d", MultiMod_GetModBlockStatus(i));
			//iDrawType = ITEMDRAW_DISABLED
			FormatEx(szDisplayName, sizeof szDisplayName, "%s [BLOCKED]", szName);
		}
		
		else 
		{ 
			FormatEx(szDisplayName, sizeof szDisplayName, szName);
			//iDrawType = ITEMDRAW_DEFAULT; 
		}
		
		AddMenuItem(gModVoteMenu, szInfo, szDisplayName, ITEMDRAW_DEFAULT);
	}
		
	/*
	for(i = 1; i <= g_iMaxPlayers; i++)
	{
		if(IsClientInGame(i))
		{
			
		}
	}*/
	
	VoteMenuToAll(gModVoteMenu, VOTING_TIME);
	MM_PrintToChat(0, "Voting for the next MOD has started!");
	LogMessage("[MultiMod] Voting for the next MOD has started!");

	//DisplayMenu(gVotingMenu, 
	
	Call_StartForward(gForwardHandle);
	Call_PushCell(0);
	Call_Finish();
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
			
			return MultiMod_GetModBlockStatus(iParam2) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
				
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
				CreateTimer(5.0, Func_StartMapVote);
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

SetWinner(Handle:menu, iParam1, iParam2, bool:iSuccess)
{
	new String:szInfo[60], String:szName[60], iDump;
	GetMenuItem(menu, iParam1, szInfo, sizeof szInfo, iDump, szName, sizeof szName);
			
	if(menu == gModVoteMenu)
	{
		new iWinner;
		iWinner = StringToInt(szInfo);
				
		MultiMod_SetNextMod(iWinner);
		g_iNextMod = iWinner
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

public Action:Func_StartMapVote(Handle:hTimer)
{
	gMapsVoteMenu = CreateMenu(VotingHandler, MENU_ACTIONS_ALL)
	new iMapsCount = ReadMapsFile()
	if(!iMapsCount)
	{
		MM_PrintToChat(0, "Map voting was cancelled as there are no available maps to vote on.");
		DecideNextMap("")
		return;
	}
	
	new iVoteMapsCount = iMapsCount > MAX_VOTE_MAPS ? MAX_VOTE_MAPS : iMapsCount;
	
	new Array[GetArraySize(gMapsList)];
	new String:szMapName[60];
	
	new iMapsAdded, iMapIndex;
	while(iMapsAdded < iVoteMapsCount)
	{
		iMapIndex = GetRandomInt(0, iMapsCount - 1);
		if(Array[iMapIndex])
		{
			continue;
		}
		
		Array[iMapIndex] = 1;
		GetArrayString(gMapsList, iMapIndex, szMapName, sizeof szMapName);
		AddMenuItem(gMapsVoteMenu, szMapName, szMapName);
		iMapsAdded++
	}
	
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

ReadMapsFile()
{
	new String:szMapsFile[60];
	MultiMod_GetModProps(g_iNextMod, MP_MAP, szMapsFile, sizeof szMapsFile);
	
	new String:szFile[120];
	FormatEx(szFile, sizeof szFile, "cfg/multimod/%s-maps.ini", szMapsFile);
	
	new Handle:f = OpenFile(szFile, "r");
	if(f == INVALID_HANDLE)
	{
		PrintToServer("****** File not found %s", szFile);
		if(!szMapsFile[0])
		{
			
			return 0;
		}
		
		f = OpenFile(szFile, "w");
		
		WriteFileLine(f,
		 "; --------------------------------------------------------------------------------------------------\
		\n;|                                    MultiMod Maps File                                          |\
		\n; --------------------------------------------------------------------------------------------------\
		\n; Any line beginning with a ';', '#' or '//' is a comment.\
		\n; Write each map in one line without the .bsp extension.");
		
		CloseHandle(f);
		
		return 0;
	}
	
	PrintToServer("** File Read");
	
	new String:szLine[200], iMaps;
	while(!IsEndOfFile(f) && ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		
		if(!szLine[0] || szLine[0] == ';' || szLine[0] == '#' || ( szLine[0] == '/' && szLine[1] == '/' ) )
		{
			continue;
		}
		
		if(StrContains(szLine, ".bsp", false) != -1)
		{
			ReplaceString(szLine, sizeof szLine, ".bsp", "");
		}
		
		if(IsMapValid(szLine))
		{
			PrintToServer("MAP FOUND: %s", szLine);
			PushArrayString(gMapsList, szLine);
			++iMaps;
		}
	}
	
	CloseHandle(f);
	
	return iMaps;
}