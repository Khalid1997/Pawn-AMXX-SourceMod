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

public plugin_init()
{
	register_plugin("Super Bunny Hopper", "1.2", "Cheesy Peteza")
	register_cvar("sbhopper_version", "1.2", FCVAR_SERVER)

	bhmode 		=	register_cvar("bh_enabled", "1")
	bhauto		=	register_cvar("bh_autojump", "1")
	bhusage		=	register_cvar("bh_showusage", "1")
	
	register_concmd("amx_rtbh", "Admin_StartVote", ADMIN_RCON)
		
	register_menucmd(register_menuid("\yVoting on \wBhop:"), gKeys, "vote_handler")
	set_task(30.0, "VoteBhop")
	
	g_iVoteRunning = 1
}	

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
	if (entity_get_int(id, EV_INT_button) & 2)
	{	// If holding jump
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
