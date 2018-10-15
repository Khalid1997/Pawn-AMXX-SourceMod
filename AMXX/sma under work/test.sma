#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <colorchat>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "author"

// --| Delay after map start to start the vote.
#define START_TIME 20.0
#define g_flPlayerPercent 0.75

#define TIMER_COUNT 10

#define GREEN 0

new const PREFIX[] = "^4[AMXX]"

// --| Don't Edit
new const TASKID_VOTE_MAP_START = 187515;
new const TASKID_COUNTER = 19715781

// --| The menu which says choose ct amount
new const VOTE_CT_AMOUNT[] = { 1, 2, 3, 4 };

// --| Don't edit.
enum VOTE_TYPE
{
	VOTE_NONE,
	VOTE_AMOUNT,
	VOTE_CHOOSE,
	VOTE_MAP_START
};

new VOTE_TYPE:g_iVoteRunning = VOTE_NONE;

new g_iLastItem;


new g_iHasVoted[33];
new g_iVotes
new g_iTimer
new g_iPlayerVotes[33]

new g_iGaurdAmount;
new g_iCurrGaurdAmount;

new g_iMenu;
new g_iMenuOther;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("TeamInfo", "Event_TeamInfo", "a", "2=CT");
	
	register_clcmd("say /votect", "CmdVoteCT");
	
	g_iVoteRunning = VOTE_MAP_START;
	set_task(20.0, "StartVoting", TASKID_VOTE_MAP_START);
}

public Event_TeamInfo()
{
	if(g_iVoteRunning)
	{
		static id; id = read_data(1);
		client_disconnect(id);
	}
}

public client_disconnect(id)
{
	if(g_iHasVoted[id])
	{
		g_iHasVoted[id] = 0;
		
		if(!g_iVoteRunning)
		{
			--g_iVotes;
		}
	}
}

public CmdVoteCT(id)
{
	static iPlayers[32], iNum;
	
	if(!CanVote(id))
	{
		return;
	}
	
	g_iHasVoted[id] = 1;
	
	get_players(iPlayers, iNum, "e", "TERRORIST");
	
	if( ++g_iVotes < (iNum = floatround( g_flPlayerPercent * float(iNum) ) ) )
	{
		server_print("g_iVotes = %d", g_iVotes);
		server_print("%d", floatround( g_flPlayerPercent * float(iNum) ) )
		ColorChat(0, GREEN, "%s ^3%d Players ^1are still needed to vote.", PREFIX, iNum - g_iVotes);
		
		return;
	}

	g_iVotes = 0;
	arrayset(g_iHasVoted, 0, sizeof(g_iHasVoted));
	arrayset(g_iPlayerVotes, 0, sizeof(g_iPlayerVotes));
	
	g_iTimer = TIMER_COUNT + 1;
	ColorChat(0, GREEN, "%s ^3VOTE SUCCEEDED ^1and will start in %d seconds!", PREFIX, g_iTimer - 1);
	StartVoting();
}

public StartVoting()
{
	new iPlayers[32], iTNum, iCTNum
	get_players(iPlayers, iTNum, "e", "TERRORIST")
	get_players(iPlayers, iCTNum, "e", "CT")
	
	if(! (iTNum + iCTNum ) )
	{
		g_iVoteRunning = VOTE_NONE
		return;
	}
	
	g_iVoteRunning = VOTE_AMOUNT
	g_iTimer = TIMER_COUNT + 1;
	
	VoteWillRunCounter(TASKID_COUNTER);
	set_task(1.0, "VoteWillRunCounter", TASKID_COUNTER,_,_, "a", g_iTimer);
}

public VoteWillRunCounter(iTaskId)
{
	if(!--g_iTimer)
	{
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum);
		
		if(!iNum)
		{
			return;
		}
		
		g_iVoteRunning = VOTE_AMOUNT;
		
		g_iMenu = menu_create("Choose amount of Gaurds", "MenuHandler_Gaurds");
		g_iMenuOther = menu_create("Choose amount of Gaurds", "MenuHandler_Dump");
		
		//menu_setprop(g_iMenu, MPROP_EXIT, MEXIT_NEVER);
		new i, iPlayer
		for(new szItem[13]; i < sizeof VOTE_CT_AMOUNT; i++)
		{
			formatex(szItem, charsmax(szItem), "%d (%%0)", VOTE_CT_AMOUNT[i]);
			menu_additem(g_iMenu, szItem);
			menu_additem(g_iMenuOther, szItem);
		}
		
		for(i = 0; i < iNum; i++)
		{
			iPlayer = iPlayers[i];
			
			switch(cs_get_user_team(iPlayer))
			{
				case CS_TEAM_CT:
				{
					cs_set_user_team(iPlayer, CS_TEAM_T);
				}
				
				case CS_TEAM_UNASSIGNED:
				{
					continue;
				}
				
				case CS_TEAM_SPECTATOR:
				{
					continue;
				}
			}
			
			menu_display(iPlayer, g_iMenu);
		}
		
		set_task(15.0, "CalcWinner");
	}
	
	else
	{
		new szNumWord[7];
		num_to_word(g_iTimer, szNumWord, 6);
		
		client_cmd(0, "spk ^"fvox/%s", szNumWord);
	}
}

public MenuHandler_Gaurds(id, menu, item)
{
	if(g_iVoteRunning == VOTE_NONE)
	{
		DestroyMenu()
		return;
	}
	
	new iOldPage, iDump;
	player_menu_info(id, iDump, iDump, iOldPage);
	if(g_iHasVoted[id] == 1)
	{
		if(!is_user_connected(id))
		{
			return;
		}
		
		server_print("g_iMenu == %d", g_iMenu);
		if(g_iMenu != -1)
		{
			menu_display(id, g_iMenuOther, iOldPage);
		}
		
		return;
	}
	
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	if(item == MENU_EXIT)
	{
		if(!is_user_connected(id))
		{
			return;
		}
		
		if(g_iHasVoted[id] == 2)
		{
			g_iHasVoted[id] = 0
			return;
		}
		
		g_iHasVoted[id] = 1;
		server_print("Here");
		ColorChat(id, GREEN, "%s ^3%s ^1chose not to vote.", PREFIX, szName);
		
		//menu_display(id, g_iMenuOther, iOldPage);
		return;
	}
	
	g_iHasVoted[id] = 1;
	
	++g_iVotes
	new szItemName[32];
	
	new iVotedPlayerID;
	
	switch(g_iVoteRunning)
	{
		case VOTE_NONE:
		{
			DestroyMenu();
			return;
		}
		
		case VOTE_AMOUNT:
		{
			++g_iPlayerVotes[item]
	
			for(new i; i < sizeof VOTE_CT_AMOUNT; i++)
			{
				formatex(szItemName, charsmax(szItemName), "%d (%%%d)", VOTE_CT_AMOUNT[i], floatround( ( float(g_iPlayerVotes[i]) / float(g_iVotes) ) * 100.0 ) )
				menu_item_setname(menu, i, szItemName);
				menu_item_setname(g_iMenuOther, i, szItemName);
			}
			
			ColorChat(0, GREEN, "%s ^3%s ^1chose ^3%d ^1as amount of ^3Gaurds.", PREFIX, get_player_name(id), VOTE_CT_AMOUNT[item]);
		}
		
		case VOTE_CHOOSE:
		{
			new szInfo[6], iDump;
			menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo),_,_, iDump);
			
			iVotedPlayerID  = str_to_num(szInfo);
			++g_iPlayerVotes[iVotedPlayerID];
			
			new szVoterName[32], szVotedName[32];
			get_user_name(id, szVoterName, 31);
			get_user_name(iVotedPlayerID, szVotedName, 31);
			
			formatex(szItemName, charsmax(szItemName), "%s (%%%d)", szVotedName, floatround( ( float(g_iPlayerVotes[iVotedPlayerID]) / float(g_iVotes) ) * 100.0 ) )
			menu_item_setname(g_iMenuOther, item, szItemName);
			menu_item_setname(menu, item, szItemName);
			
			ColorChat(0, GREEN, "%s ^3%s ^1chose ^3%s ^1as a ^3Gaurd.", PREFIX, szVoterName, szVotedName);
			
			for(new i; i < g_iLastItem && i != item; i++)
			{
				menu_item_getinfo(menu, i, iDump, szInfo, charsmax(szInfo),_,_, iDump);
				
				iVotedPlayerID = str_to_num(szInfo);
				
				formatex(szItemName, charsmax(szItemName), "%s (%%%d)", get_player_name(iVotedPlayerID, szVotedName), floatround( ( float(g_iPlayerVotes[iVotedPlayerID]) / float(g_iVotes) ) * 100.0 ))
				menu_item_setname(menu, i, szItemName);
				menu_item_setname(g_iMenuOther, i, szItemName);
			}
		}
	}

	//server_print("szItemName = %s", szItemName);
	//server_print("g_iVotes %d .. g_iPlayerVotes %d", g_iVotes, g_iPlayerVotes[ g_iVoteRunning == VOTE_AMOUNT ? item : iVotedPlayerID ] );
	
	menu_display(id, g_iMenuOther, iOldPage);
	Update(id)
}

Update(id)
{
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "e", "TERRORIST");
	
	for(new i, iDump, iOldPage, iNew; i < iNum; i++)
	{
		if(iPlayers[i] == id)
		{
			continue;
		}
		
		player_menu_info(iPlayers[i], iDump, iNew, iOldPage);
		
		if(g_iHasVoted[iPlayers[i]] == 0)
		{
			g_iHasVoted[iPlayers[i]] = 2
		}
		
		if( g_iMenu == iNew )		menu_display(iPlayers[i], g_iMenu, iOldPage);
		else if( g_iMenuOther == iNew )	menu_display(iPlayers[i], g_iMenuOther, iOldPage);
	}
}

public MenuHandler_Dump(id, menu, item) {
	if(item == MENU_EXIT)
	{
		return;
	}
	
	menu_display(id, menu);
}

public CalcWinner()
{
	DestroyMenu()
	
	new iArray[33][2], i
	for(i = 0; i < 33; i++)
	{
		iArray[i][0] = g_iPlayerVotes[i]
		iArray[i][1] = i
	}
	
	switch(g_iVoteRunning)
	{
		// |||| ---------------------------------------------||||
		// |||| ---------------------------------------------||||
		// |||| ---------------  Vote_Amount  ---------------||||
		// |||| ---------------------------------------------||||
		// |||| ---------------------------------------------||||
		case VOTE_AMOUNT:
		{
			SortCustom2D(iArray, sizeof VOTE_CT_AMOUNT, "SortingFunc")
	
			new iSame
			for(i = 1; i < sizeof( VOTE_CT_AMOUNT ); i++)
			{
				if(iArray[0][0] == iArray[i][0])
				{
					++iSame;
					continue;
				}
				
				break;
			}
			
			new iWinner;
			if(iSame)
			{
				iWinner = random(iSame + 1);
				ColorChat(0, GREEN, "%s ^1Vote ended with a tie. Choosing a random number.", PREFIX);
			}
			
			new iPlayers[32], iNum;
			get_players(iPlayers, iNum, "e", "TERRORIST");
			
			g_iGaurdAmount = VOTE_CT_AMOUNT[iArray[iWinner][1]];
			
			if(g_iGaurdAmount >= iNum)
			{
				g_iGaurdAmount = iNum - 1;
				server_print( " iNum == %d", iNum);
				server_print( " GaurdAmount == %d", g_iGaurdAmount);
				
				if(!g_iGaurdAmount)
				{
					StopVote();
					
					cs_set_user_team(iPlayers[0], CS_TEAM_CT);
					return;
				}
					
				ColorChat(0, GREEN, "%s ^3VOTE HAS ENEDED. ^1Choosen ^3Gaurds ^1number is more than current joined players.", PREFIX);
				ColorChat(0, GREEN, "%s ^1Changing choosen ^3Gaurds amount ^1to ^3%d.", PREFIX, g_iGaurdAmount);
			}
			
			else	ColorChat(0, GREEN, "%s ^3VOTE HAS ENEDED. ^1There will be ^3%d Gaurds. ^1(Won by %d votes).", PREFIX, g_iGaurdAmount , iArray[iWinner][0]);
			
			g_iCurrGaurdAmount = 0;
			set_task(2.0, "StartPlayersVote");
		}
		
		// |||| ---------------------------------------------||||
		// |||| ---------------------------------------------||||
		// |||| ---------------  Vote_Choose  ---------------||||
		// |||| ---------------------------------------------||||
		// |||| ---------------------------------------------||||
		case VOTE_CHOOSE:
		{
			SortCustom2D(iArray, sizeof(iArray), "SortingFunc");
			
			new iSame = 1
			for(i = 1; i < sizeof( VOTE_CT_AMOUNT ); i++)
			{
				if(iArray[0][0] == iArray[i][0])
				{
					++iSame
					continue;
				}
				
				break;
			}
			
			new iPlayers[32], iNum;
			get_players(iPlayers, iNum, "e", "TERRORIST");
			
			if(!iNum)
			{
				StopVote();
				return;
			}
			
			new iWinner, iCount;
			
			for(new i; i < iSame; i ++)
			{
				if(is_user_connected(iArray[i][1]))
				{
					iCount++
					if(random_num(0, 1))
					{
						iWinner = iArray[i][1];
						break;
					}
				}
			}
			
			if(!iWinner)
			{
				if(iCount)
				{
					while( ( iWinner = iArray[random(iSame)][1] ) )
					{
						if(is_user_connected(iWinner))
						{
							break;
						}
					}
				}
					
				else 
				{
					for(new i = iSame; i < sizeof iArray; i++)
					{
						if(is_user_connected(iArray[i][1]))
						{
							iWinner = iArray[i][1];
							break;
						}
					}
				}
			}
				
			ColorChat(0, GREEN,
			iSame > 1 ? "%s ^1Vote ended with a tie. Choosing a random player." : "%s ^3%s ^1will be a ^3Gaurd.",
			PREFIX, get_player_name(iWinner));
			
			cs_set_user_team(iWinner, CS_TEAM_CT);
			
			++g_iCurrGaurdAmount
			
			// Make sure there is atleast 1 TERRORIST
			if( (iNum - 1 ) == 1)
			{
				ColorChat(0, GREEN, "%s ^1Stopped voting to make sure there are terrorists left.", PREFIX);
				StopVote();
				return;
			}
			
			if(g_iCurrGaurdAmount < g_iGaurdAmount)
			{
				set_task(1.0, "StartPlayersVote");
			}
			
			else
			{
				StopVote()
				server_cmd("sv_restart 1")
				
				arrayset(g_iHasVoted, 0 , 33)
				g_iVotes = 0
				
				user_kill(iPlayers[0]);
			}	
		}
	}
}

StopVote()
{
	g_iVoteRunning = VOTE_NONE
	if(task_exists(TASKID_VOTE_MAP_START))
	{
		remove_task(TASKID_VOTE_MAP_START);
	}
	
	if(task_exists(TASKID_COUNTER))
	{
		remove_task(TASKID_COUNTER);
	}
	
	server_cmd("sv_restart 1")
}

public StartPlayersVote()
{
	g_iVotes = 0;
	arrayset(g_iHasVoted, 0, 33);
	arrayset(g_iPlayerVotes, 0, 33);
	g_iLastItem = 0;
	
	g_iVoteRunning = VOTE_CHOOSE
	DoPlayersMenu()
}

DoPlayersMenu()
{
	new iPlayers[32], iPlayer, iNum, i, szInfo[4], szItemName[40];
	get_players(iPlayers, iNum, "e", "TERRORIST");
	
	g_iMenu = menu_create(GetGaurdPosTitle(), "MenuHandler_Gaurds")
	g_iMenuOther = menu_create(GetGaurdPosTitle(), "MenuHandler_Dump")
	//menu_setprop(g_iMenu, MPROP_EXIT, MEXIT_NEVER);
	
	for(i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		formatex(szItemName, charsmax(szItemName), "%s (%%0)", get_player_name(iPlayer));
		num_to_str(iPlayer, szInfo, charsmax(szInfo));
		
		menu_additem(g_iMenu, szItemName, szInfo);
		
		g_iLastItem ++
	}
	
	for(i = 0; i < iNum; i++)
	{
		menu_display(iPlayers[i], g_iMenu);
	}
	
	set_task(16.0, "CalcWinner") 
}

GetGaurdPosTitle()
{
	new iGaurdNum = g_iCurrGaurdAmount + 1;
	new iNew;
	
	new szTitle[40];
	
	if(iGaurdNum > 10)
	{
		iNew = iGaurdNum % 10;
		server_print(" iNew = %d", iNew);
		server_print(" iGaurdNum = %d", iGaurdNum);
	}
	
	new szPos[6]
	switch(iNew)
	{
		case 1:		szPos = "st";
		case 2:		szPos = "nd";
		case 3:		szPos = "rd";
		default:	szPos = "th";
	}
	
	formatex(szTitle, charsmax(szTitle), "Choose the %d%s Gaurd.", iGaurdNum, szPos);
	
	return szTitle;
}

public SortingFunc(iEntry1[], iEntry2[])
{
	if(iEntry1[0] > iEntry2[0])
	{
		return -1;
	}
	
	if(iEntry1[0] < iEntry2[0])
	{
		return 1;
	}
	
	return 0;
}

CanVote(id)
{
	if(g_iVoteRunning)
	{
		ColorChat(id, GREEN, "%s ^3Vote ^1is already running or will run.", PREFIX);
		return 0;
	}
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		ColorChat(id, GREEN, "%s ^3Gaurds ^1can't vote.", PREFIX);
		return 0;
	}
	
	/*get_players(iCTPlayers, iNum, "e", "CT");
	
	if(iNum)
	{
		ColorChat(id, GREEN, "%s ^1The ^3Gaurds team must be empty to vote.", PREFIX);
		return 0;
	}*/
	
	if(g_iHasVoted[id])
	{
		ColorChat(id, GREEN, "%s ^1You have already ^3voted.", PREFIX);
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "e", "TERRORIST");
	
		server_print("iNum = %d", iNum);
		
		server_print("g_iVotes = %d", g_iVotes);
		
		iNum = floatround( g_flPlayerPercent * float(iNum) )
		
		server_print("%d", floatround( g_flPlayerPercent * float(iNum) ) )
		ColorChat(id, GREEN, "%s ^3%d players ^1are still needed to start the vote.", PREFIX, iNum - g_iVotes);
		return 0;
	}
	
	return 1;
}

get_player_name(id, szName[32] = "")
{
	get_user_name(id, szName, 31);
	return szName;
}

DestroyMenu()
{
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	
	/*for(new i, iMenu, iDump, iPlayer; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		player_menu_info(iPlayer, iDump, iMenu, iDump);
		
		if(iMenu == g_iMenu)
		{
			menu_cancel(iPlayer);
		}
	}*/
	
	server_print("DESTROY");
	new iOld = g_iMenu
	g_iMenu = -1;
	arrayset(g_iHasVoted, 2, 33);
	menu_destroy(iOld);
	menu_destroy(g_iMenuOther);
	client_cmd(0, "slot0");
	arrayset(g_iHasVoted, 0, 33);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
