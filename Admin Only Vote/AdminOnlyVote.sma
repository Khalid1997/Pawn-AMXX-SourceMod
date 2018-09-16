#include <amxmodx>
#include <amxmisc>

#define LEVEL ADMIN_KICK
#define MAX_ANSWERS 4

#define MAX_CHARS 50
#define CharsMax (MAX_CHARS - 1)

#define TASKID_VOTE 18551

const Float:VOTE_TIME = 20.0

new g_iInVote, g_hVoteMenu, g_iVoteAnswersCount
new g_iVoteAnswers[MAX_ANSWERS], g_iVoteStarter

public plugin_init()
{
	register_plugin "Admin Vote", "1.0", "Khalid :)"
	
	new szInfo[250], iLen
	
	iLen = formatex(szInfo, charsmax(szInfo), "<question>")
	
	for(new i; i < MAX_ANSWERS; i++)
	{
		iLen += formatex(szInfo[iLen], charsmax(szInfo) - iLen, " <answer #%d>", i + 1)
	}
	
	iLen += formatex(szInfo[iLen], charsmax(szInfo) - iLen, " - Admin only vote^n** two ANSWERS at least must be written")
	
	register_concmd("amx_admin_vote", "AdminCmdVote", LEVEL, szInfo)
	register_concmd("amx_admin_vote_cancel", "AdminCmdVoteCancel", LEVEL, "Cancels current admin only vote if active")
}

public AdminCmdVoteCancel(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}
	
	if(!g_iInVote)
	{
		console_print(id, "There is no vote running to be canceled")
		return PLUGIN_HANDLED
	}
	
	if(id != g_iVoteStarter)
	{
		console_print(id, "You are not the vote starter to cancel the vote")
		return PLUGIN_HANDLED
	}
	
	remove_task(TASKID_VOTE)
	g_iInVote = 0
	menu_destroy(g_hVoteMenu)
	
	new szName[32]; get_user_name(id, szName, 31)
	
	client_print(0, print_chat, "ADMIN %s canceled admin only vote", szName)
	return PLUGIN_HANDLED
}

public AdminCmdVote(id, level, cid)
{
	if(!cmd_access(id, level, cid, 4 /* command + question + answer 1 + answer 2 */))
	{
		
		return PLUGIN_HANDLED
	}
	
	if(g_iInVote)
	{
		console_print(id, "An admin vote is already in progress")
		return PLUGIN_HANDLED
	}
	
	static szTitle[MAX_CHARS]; read_argv(1, szTitle, CharsMax)
	new iArgCount = read_argc(), i = 1 /* command (0) + question (1) */
	
	new iMenu = menu_create(szTitle, "vote_handler")
	
	g_iVoteAnswersCount = 0
	while(++i < iArgCount)
	{
		g_iVoteAnswersCount++
		read_argv(i, szTitle, CharsMax)
		menu_additem(iMenu, szTitle)
	}
	
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "ch")
	
	for(i = 0; i < iNum; i++)
	{
		if(get_user_flags( ( iPlayer = iPlayers[i] ) ) & LEVEL)
		{
			menu_display(iPlayer, iMenu)
		}
	}
	
	set_task(VOTE_TIME, "CountVotes", TASKID_VOTE)
	
	g_iInVote = 1; g_hVoteMenu = iMenu, g_iVoteStarter = id
	arrayset(g_iVoteAnswers, 0, MAX_ANSWERS)
	
	new szName[32]; get_user_name(id, szName, 31)
	client_print(0, print_chat, "ADMIN %s: start custom admin only vote", szName)
	
	return PLUGIN_HANDLED
}

public vote_handler(id, menu, item)
{
	static szName[32]; get_user_name(id, szName, 31)
	
	if(item == MENU_EXIT)
	{
		client_print(0, print_chat, "ADMIN %s chose not to take part in the admin vote", szName)
		return;
	}
	
	static iDump, szDump[1], szItemName[MAX_CHARS]
	menu_item_getinfo(menu, item, iDump, szDump, 1, szItemName, CharsMax, iDump)
	
	client_print(0, print_chat, "ADMIN %s chose answer ^"%s^"", szName, szItemName)
	g_iVoteAnswers[item]++
}

public CountVotes(iTaskId)
{
	// Stop anyone from choosing anything
	new b
	for(new i; i < g_iVoteAnswersCount; i++)
	{
		if( i != b && g_iVoteAnswers[i] > g_iVoteAnswers[b])
		{
			b = i
		}
	}
	
	// No one voted
	if(!g_iVoteAnswers[b])
	{
		menu_destroy(g_hVoteMenu); g_iInVote = 0
		client_print(0, print_chat, "** There vote was canceled as no admin has choosed an answer")
		
		return;
	}
	
	new szDump[1], iDump, szItemName[MAX_CHARS]
	menu_item_getinfo(g_hVoteMenu, b, iDump, szDump, 1, szItemName, CharsMax, iDump)
	
	menu_destroy(g_hVoteMenu)
	g_iInVote = 0
	
	client_print(0, print_chat, "** The winning answer is %s with %d votes.", szItemName, g_iVoteAnswers[b])
}
