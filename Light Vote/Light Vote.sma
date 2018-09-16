/* zp_lighting_vote v0.3 */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "zp_lighting_vote"
#define VERSION "1.2a"
#define AUTHOR "Khalid"

new const TASKID_FIRST_VOTE = 15518186
new const TASKID_COUNT_VOTES = 15156125

new const g_iVoteTime = 15
new g_iCountDown;

new Array:g_hArrayLightNames;
new Array:g_hArrayLightDegree;

new g_iMenu;

new Array:g_hArrayVoteCount;
new bool:g_bVoteRunning;

public plugin_init() {
	register_plugin(PLUGIN,VERSION,AUTHOR)
	
	g_hArrayLightNames = ArrayCreate(40, 1);
	g_hArrayLightDegree = ArrayCreate(3, 1);
	
	if(!g_hArrayLightDegree || !g_hArrayLightNames)
	{
		set_fail_state(" Failed to create dynamic arrays " );
	}
	
	register_concmd("amx_add_lighting_vote_option", "CmdAddLighting", ADMIN_RCON, "<Lighting Name> <a-z>");
	register_concmd("amx_lighting_vote", "StartLightingVote", ADMIN_CVAR);

	set_task(120.0, "StartVote", TASKID_FIRST_VOTE);
}

public StartLightingVote(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}
	
	if(g_bVoteRunning)
	{
		console_print(id, "* Vote is already running.");
		return PLUGIN_HANDLED;
	}
	
	remove_task(TASKID_COUNT_VOTES);
	remove_task(TASKID_FIRST_VOTE);
	
	StartVote(0);
	return PLUGIN_HANDLED;
}

public CmdAddLighting(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
	{
		return PLUGIN_HANDLED
	}
	
	new szLightNameArg[40], szLightDegreeArg[2];
	read_argv(1, szLightNameArg, charsmax(szLightNameArg));
	read_argv(2, szLightDegreeArg, charsmax(szLightDegreeArg));
	
	ArrayPushString(g_hArrayLightNames, szLightNameArg);
	ArrayPushString(g_hArrayLightDegree, szLightDegreeArg);
	
	console_print(id, "Added light '%s' with degree '%s'", szLightNameArg, szLightDegreeArg);
	return PLUGIN_HANDLED;
}

public StartVote(iTaskId)
{
	if(g_bVoteRunning)
	{
		return;
	}
	
	new iArraySize = ArraySize(g_hArrayLightNames);
	
	if(!iArraySize)
	{
		set_task(25.0, "StartVote", TASKID_FIRST_VOTE);
		return;
	}
	
	new szMenuName[70];
	formatex(szMenuName, charsmax(szMenuName), "\wSelect lighting for this map^nVote will end in \y%d \rSeconds", g_iVoteTime);
	g_iMenu = menu_create(szMenuName, "SelectLightingHandler");
	
	if(g_hArrayVoteCount)
	{
		ArrayClear(g_hArrayVoteCount);
	}

	else
	{
		g_hArrayVoteCount = ArrayCreate(1, 1);
		if (! g_hArrayVoteCount )
		{
			set_fail_state("Failed to make Vote Count dynamic array");
			return;
		}
	}
	
	new szItemName[40];
	for(new i; i < iArraySize; i++)
	{
		ArrayGetString(g_hArrayLightNames, i, szItemName, charsmax(szItemName));
		menu_additem(g_iMenu, szItemName);
		ArrayPushCell(g_hArrayVoteCount, 0);
	}
	
	g_bVoteRunning = true;
	
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ch");
	
	for(new i; i < iNum; i++)
	{
		menu_display(iPlayers[i], g_iMenu);
	}
	
	set_task(1.0, "CountVotes", TASKID_COUNT_VOTES,_,_, "a", ( g_iCountDown = g_iVoteTime ) );
}

public SelectLightingHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	new szItemName[40], iDump, szDump[1], szName[32];
	menu_item_getinfo(menu, item, iDump, szDump, 0, szItemName, charsmax(szItemName), iDump);
	
	get_user_name(id, szName, 31);
	
	ArraySetCell(g_hArrayVoteCount, item, ( ArrayGetCell(g_hArrayVoteCount, item) + 1) );
	client_print(0, print_chat, "%s vote for %s", szName, szItemName);
}

public CountVotes(iTaskId)
{
	static iPlayers[32], iNum, i, iMenu, iDump, id;
	static szTitle[70]
	get_players(iPlayers, iNum, "ch");
	
	if(--g_iCountDown)
	{
		formatex(szTitle, charsmax(szTitle), "\wSelect lighting for this map^nVote will end in \y%d \rSeconds", g_iCountDown);
		menu_setprop(g_iMenu, MPROP_TITLE, szTitle, charsmax(szTitle));
	
		for(i = 0; i < iNum; i++)
		{
			id = iPlayers[i]
			player_menu_info(id, iDump, iMenu, iDump)
			if(iMenu == g_iMenu)
			{
				menu_display(id, iMenu);
			}
		}
		
		return;
	}
	
	formatex(szTitle, charsmax(szTitle), "\wSelect lighting for this map^nVote has \rENDED");
	menu_setprop(g_iMenu, MPROP_TITLE, szTitle, charsmax(szTitle));
	
	for(i = 0; i < iNum; i++)
	{
		id = iPlayers[i]
		player_menu_info(id, iDump, iMenu, iDump)
		if(iMenu == g_iMenu)
		{
			menu_display(id, iMenu);
		}
	}		
		
	menu_destroy(g_iMenu);
	g_bVoteRunning = false;
	
	new iArraySize = ArraySize(g_hArrayVoteCount)
	
	new iTopArrayItem, iTopNum, iCurr
	for(i = 0; i < iArraySize; i++)
	{
		if( ( iCurr = ArrayGetCell(g_hArrayVoteCount, i) ) >= iTopNum )
		{
			iTopNum = iCurr; iTopArrayItem = i;
		}
	}
	
	if(!iTopNum)
	{
		client_print(0, print_chat, "No one voted. Cancelling vote.");
		return;
	}
	
	ArrayDestroy(g_hArrayVoteCount);
	
	new szWinnerName[40];
	ArrayGetString(g_hArrayLightNames, iTopArrayItem, szWinnerName, charsmax(szWinnerName));
	
	client_print(0, print_chat, "The Selected Light is: %s", szWinnerName);
	ArrayGetString(g_hArrayLightDegree, iTopArrayItem, szWinnerName, charsmax(szWinnerName));
	
	server_cmd("zp_lighting %s", szWinnerName);
	server_print("zp_lighting %s", szWinnerName);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
