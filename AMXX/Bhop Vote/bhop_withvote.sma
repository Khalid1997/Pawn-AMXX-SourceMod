/*
 *
 *	Author:		Cheesy Peteza- Vote added by Khalid
 *
 *
 *	Description:	Enable bunny hopping in Counter-Strike.
 *			It also shows a vote after 20 secs of a new map loaded to enable bhop or disable it.
			- Added by me :)
 *
 */
 
 /*
 ++++++++ CVARS ++++++ 
// Same old ones .... 
bh_enabled "1"        // Bhop enabled? 
bh_autojump "1"        // Hold space for auto jump enabled? 
bh_showusage "1"    // Show the message - Auto Bunny hop is enabled .... 

// New ones ... for new features 
bh_rtbh "1"        // Rocking the vote for the bhop vote enabled? 1 = Yes ... 2 = No 

bh_percent "75"        // Percentage of players that need to rtbh for the vote to start 
// Example: 
// There are 8 players in the server 
// 8 * 0.75 = 6 players that need to rock the bhop vote 

bh_minutes_until_rtbh "10"    // How many minutes that need to pass since last map change so players can rock the vote 



+++++++  New Commands +++++++ 
----  Admin Commands 
// Admin Command - Access flag letter - Flag bitsum required 
amx_rtbh    -    "l"    -     ADMIN_RCON 


----  Client Commands ... 
// All of these are for rocking the bhop vote and they are for team say and all say .. 
    "rtbh" 
    ,"/rtbh" 
    ,"rtb" 
    ,"/rtb" 
    ,"rockthebhopvote" 
    ,"/rockthebhopvote" 
    ,"rocktbh" 
    ,"/rocktbh"  
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define	FL_WATERJUMP	(1<<11)	// player jumping out of water
#define	FL_ONGROUND	(1<<9)	// At rest / on the ground

// +++ Menu Stuff +++
new gKeys = (MENU_KEY_0|MENU_KEY_1|MENU_KEY_2)
new g_iVoteRunning

// +++ Vote Stuff +++
new BhEnabled, BhDisabled

// +++ pcvars +++
new bhmode, bhauto, bhusage

// +++ RTBH Stuff +++
//#define WITH_RTBH
//#define WITH_TIME
#if defined WITH_RTBH
new g_pPercent, g_iVotes, g_iPlayersLeft
new g_pRTBH, g_iHasRTBH[33]
	#if defined WITH_TIME
		new g_iStartSysTime
		, g_pMins
	#endif
#endif

#if defined WITH_RTBH
new gsz_RockTheBhopCommands[][] = {
	"rtbh"
	,"/rtbh"
	,"rtb"
	,"/rtb"
	,"rockthebhopvote"
	,"/rockthebhopvote"
	,"rocktbh"
	,"/rocktbh"
}
#endif

public plugin_init()
{
	register_plugin("Super Bunny Hopper", "1.2", "Cheesy Peteza")
	register_cvar("sbhopper_version", "1.2", FCVAR_SERVER)

	bhmode 		=	register_cvar("bh_enabled", "1")
	bhauto		=	register_cvar("bh_autojump", "1")
	bhusage		=	register_cvar("bh_showusage", "1")
	
	register_concmd("amx_rtbh", "Admin_StartVote", ADMIN_RCON)
	
	#if defined WITH_RTBH
	new szCommand[30]
	for(new i; i < sizeof(gsz_RockTheBhopCommands); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", gsz_RockTheBhopCommands[i])
		register_clcmd(szCommand, "Cmd_RockBh")
		formatex(szCommand, charsmax(szCommand), "say_team %s", gsz_RockTheBhopCommands[i])
		register_clcmd(szCommand, "Cmd_RockBh")
	}
	
	#endif
		
	register_menucmd(register_menuid("\yVoting on \wBhop:"), gKeys, "vote_handler")
	set_task(30.0, "VoteBhop")
	
	g_iVoteRunning = 1
	
	#if defined WITH_RTBH
	g_pRTBH 	=	register_cvar("bh_rtbh", "1")
	g_pPercent 	=	register_cvar("bh_percent", "75")
	#if defined WITH_TIME
	g_pMins 	=	register_cvar("bh_minutes_until_rtbh", "10")
	g_iStartSysTime = get_systime()
	#endif
	#endif
	
	new szName[100]
	get_user_name(0, szName, charsmax(szName))
}	

#if defined WITH_RTBH
PlayersLeft(iCurrentVoteNum)
//iCurrentVoteNum /* iLeftPercent , iNeededPlayers*/)
{
	//new iPNum = get_playersnum()
	//new iRequiredVotes =  ( (iPNum * iPercent) / 100 )  
	//return ((get_playersnum() * get_pcvar_num(g_pPercent) / 100) - iNum)
	//iLeftPercent = (iPercent - ( iCurrentVoteNum * 100 / ( (get_playersnum() * iPercent) / 100 ) ) )
	//return (iNeededPlayers - iCurrentVoteNum)

	new iPercent = get_pcvar_num(g_pPercent)
	new iNum =  get_playersnum()
	new something = ( (iNum * iPercent) / 100) - iCurrentVoteNum
	server_print("%d ... Players Num %d", something, iNum)
	return something
}
#if defined WITH_TIME
Allow_RTBH(&iMin, &iSec)
{	
	new iNum = get_systime()
	
	if((g_iStartSysTime + ( get_pcvar_num(g_pMins) * 60 ) ) <= iNum)
	//iNum - ( get_pcvar_num(g_pMins) * 60 ) > g_iStartSysTime)
		return 1	// Means Allow

	iNum = (g_iStartSysTime + ( get_pcvar_num(g_pMins) * 60 ) ) - iNum
	iMin = (iNum / 60); iSec = (iNum % 60)
	
	server_print("%d ..... %d", iMin, iSec)
	//return -1			// Means DON'T ALLOW!
	return 0
}
#endif
#endif

#if defined WITH_RTBH
public Cmd_RockBh(id)
{
	if(get_pcvar_num(g_pRTBH) && !g_iVoteRunning && !g_iHasRTBH[id])
	{
		#if defined WITH_TIME
		new iMinutes, iSecoundsLeft
		new iNum = Allow_RTBH(iMinutes, iSecoundsLeft)
		server_print("%d ...... %d ... 2", iMinutes, iSecoundsLeft)
		
		if(!iNum)
		{
			client_print(id, print_chat, "You need to wait %d minutes and %d secounds before you can RTBH!", iMinutes, iSecoundsLeft)
			return PLUGIN_HANDLED
		}
		#endif
		
		g_iHasRTBH[id] = 1
		client_print(id, print_chat, "You have rocked the Bhop vote...")
		g_iPlayersLeft = PlayersLeft(g_iVotes)
		++g_iVotes
		
		if(!g_iPlayersLeft)
		{
			client_print(0, print_chat, "*** Enough players have rocked the bhop vote, vote will run in 5 secounds!")
			set_task(5.0, "VoteBhop")
			g_iVoteRunning = 1; g_iVotes = 0; g_iPlayersLeft = PlayersLeft(g_iVotes)
			// Reset ALL
			arrayset(g_iHasRTBH, 0, sizeof(g_iHasRTBH))
		}
		
		else	//client_print(0, print_chat, "%d Players left to rock the bhop vote!", g_iPlayersLeft)
			client_print(0, print_chat, "%d Players left need to rtbh to start the vote! (Needed: %d, Current votes: %d)", g_iPlayersLeft, g_iVotes + g_iPlayersLeft, g_iVotes)
		
		return PLUGIN_CONTINUE
	}
	
	if(g_iHasRTBH[id])
	{
		client_print(id, print_chat, "You have already rocked the vote!")
		client_print(id, print_chat, "%d Players left need to rtbh to start the vote! (Needed: %d, Current votes: %d)", g_iPlayersLeft, g_iVotes + g_iPlayersLeft, g_iVotes)
	}
	
	else	client_print(id, print_chat, "*** Rocking the bhop vote is disabled right now!")
	return PLUGIN_HANDLED
}
#endif

#if defined WITH_RTBH
public client_putinserver(id)
{
	if(get_pcvar_num(g_pRTBH))
		g_iPlayersLeft = PlayersLeft(g_iVotes)
}
		
public client_disconnect(id)
{
	if(g_iHasRTBH[id] && get_pcvar_num(g_pRTBH))
	{
		g_iHasRTBH[id] = 0
		g_iVotes--
		g_iPlayersLeft = PlayersLeft(g_iVotes)
	}
}
#endif

public Admin_StartVote(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	if(!g_iVoteRunning)
		VoteBhop(id)
	
	else	console_print(id, "Vote is already running!")
	return PLUGIN_HANDLED
}

public client_PreThink(id) {
	if (!get_pcvar_num(bhmode))
		return PLUGIN_CONTINUE

	entity_set_float(id, EV_FL_fuser2, 0.0)		// Disable slow down after jumping

	if (!get_pcvar_num(bhauto))
		return PLUGIN_CONTINUE

// Code from CBasePlayer::Jump (player.cpp)		Make a player jump automatically
	if (entity_get_int(id, EV_INT_button) & 2) {	// If holding jump
		new flags = entity_get_int(id, EV_INT_flags)

		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		if ( !(flags & FL_ONGROUND) )
			return PLUGIN_CONTINUE

		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		velocity[2] += 250.0
		entity_set_vector(id, EV_VEC_velocity, velocity)

		entity_set_int(id, EV_INT_gaitsequence, 6)	// Play the Jump Animation
	}
	return PLUGIN_CONTINUE
}

public client_authorized(id)
	set_task(30.0, "showUsage", id)

public showUsage(id) {
	if ( !get_pcvar_num(bhmode) || !get_pcvar_num(bhusage) )
		return PLUGIN_HANDLED

	if ( !get_pcvar_num(bhauto) ) {
		client_print(id, print_chat, "Bunny hopping is enabled on this server. You will not slow down after jumping.")
	}
	
	else {
		client_print(id, print_chat, "Auto bunny hopping is enabled on this server. Just hold down jump to bunny hop.")
	}
	return PLUGIN_HANDLED
}

public VoteBhop(id)
{
	if( !get_playersnum() )
	{
		server_print("Bunnyhop vote stopped as there are no players connected!")
		g_iVoteRunning = 0
		return PLUGIN_HANDLED
	}
	
	if(id > 0)
	{
		new szAdminName[32]
		get_user_name(id, szAdminName, 31)
		client_print(0, print_chat, "ADMIN %s started voting for bhop!", szAdminName)
	}
	
	else	client_print(0, print_chat, "Voting for bhop has started!")
	
	
	g_iVoteRunning = 1; BhEnabled = 0; BhDisabled = 0
	
	server_print("Voting for bhop has started!")
	//client_print(0, print_chat, "Voting for bhop has started!")

	new players[32], count, player
	get_players(players, count)
	
	new menu[100]
	formatex(menu, 99, "\yVoting on \wBhop:^n^n\r1. \wEnabled^n\r2. \wDisabled")
	
	for(new i; i < count; i++)
	{
		player = players[i]
		show_menu(player, gKeys, menu)
	}
	
	set_task(15.0, "check_votes")
	return PLUGIN_CONTINUE
}

public vote_handler(id, key)
{
	if(!g_iVoteRunning)
		return;
		
	new name[32]
	get_user_name(id, name, 31)
	
	switch(key)
	{
		case 0:
		{
			BhEnabled++
			client_print(0, print_chat, "%s chose to enable bhop", name)
		}

		case 1:
		{
			BhDisabled++
			client_print(0, print_chat, "%s chose to disable bhop", name)
		}
	}
}

public check_votes()
{
	
	g_iVoteRunning = 0
	server_print("Voting for bhop has stopped!")
	
	if( BhEnabled < BhDisabled )
	{
		set_pcvar_num(bhmode, 0)
		client_print(0, print_chat, "Bhop will be disabled! (Enabled: %d   Disabled: %d)", BhEnabled, BhDisabled)
	}
	
	if( BhEnabled > BhDisabled )
	{
		set_pcvar_num(bhmode, 1)
		client_print(0, print_chat, "Bhop will be enabled! (Enabled: %d   Disabled: %d)", BhEnabled, BhDisabled)
	}
	
	if( BhEnabled == BhDisabled )
	{
		client_print(0, print_chat, "The vote was a tie! Vote will run again in 15 secs! (Both results are: %d)", BhEnabled)
		g_iVoteRunning = 1
		set_task(15.0, "VoteBhop")
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
