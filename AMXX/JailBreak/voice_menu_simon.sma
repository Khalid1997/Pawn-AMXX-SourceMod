#include < amxmodx > 
#include < fakemeta > 
#include <hamsandwich>
#include <colorchat>

enum Options
{
	MUTE,
	TALK,
	TALK_SAVE
}

new Options:CanTalk[ 33 ] = MUTE
new g_iPlugin = 1
new g_iXVar

#define FLAG ADMIN_KICK

new gAdmin, gAlive

#define SetAlive(%1) ( gAlive |= (1<<%1) )
#define SetDead(%1) ( gAlive &= ~(1<<%1) )
#define IsAlive(%1) ( gAlive & (1<<%1) )

#define SetAdmin(%1) ( gAdmin |= (1<<%1) )
#define SetPlayer(%1) ( gAdmin &= ~(1<<%1) )
#define IsAdmin(%1) ( gAdmin & (1<<%1) )

public plugin_init( ) 
{ 
	register_plugin( "JailBreak Voice Manager", "0.1", "HAHA" ) 
	register_logevent("round_end", 2, "1=Round_End")  
	register_clcmd( "say /voice", "voice_menu" ) 
	
	register_clcmd( "say /vm", "VoiceSettings")
	
	register_forward( FM_Voice_SetClientListening, "fn_voice" )
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_Killed", 1)
	
	g_iXVar = get_xvar_id("g_Simon")
	
	if(g_iXVar == -1)
	{
		
		g_iPlugin = 0
	}
	
	register_logevent("RoundStart", 2, "1=Round_Start")
} 

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	SetAlive(id)
	
	if( IsAdmin(id) && !(get_user_flags(id) & FLAG) )
	{
		SetPlayer(id)
	}
}

public fw_Killed(id, iKiller, iShouldGib)
{
	SetDead(id)
}

public client_disconnect(id)
{
	CanTalk[id] = MUTE;
	SetDead(id);
	SetPlayer(id);
}

public VoiceSettings(id)
{
	ColorChat(id, NORMAL, "^3[ JailBreak ] ^4Simons ^1and ^4admins ^1can enable voice for prisoners")
	ColorChat(id, NORMAL, "^3[ JailBreak ] ^4Deads ^1can't talk. ^4Admins ^1can talk at any situation")
}

public RoundStart()
{
	ColorChat(0, NORMAL, "^3[ JailBreak ] ^1Simons can use command /voice to toggle voice chat for prisoners")
}

public round_end( ) 
{ 
	//arrayset(_:CanTalk, 0, 33)
	new iPlayers[32], iNum
	get_players(iPlayers, iNum)

	for(new i; i < iNum; i++)
	{
		if(CanTalk[iPlayers[i]] == TALK_SAVE)
		{
			continue;
		}
		
		CanTalk[iPlayers[i]] = MUTE
	}
} 

public client_putinserver(id)
{
	CanTalk[id] = MUTE
	
	if( (get_user_flags(id) & FLAG ) )
	{
		SetAdmin(id)
	}
}

public fn_voice( reciver, sender, bool:listen ) 
{ 
	if(!g_iPlugin)
	{
		return FMRES_IGNORED
	}
	
	if(!is_user_connected(sender))
	{
		return FMRES_IGNORED
	}
	
	/*new iPlayers[32], iNum
	get_players(iPlayers, iNum, "ae", "TERRORIST")
	
	if(iNum == 1 && iPlayers[0] == sender)
	{
		return FMRES_IGNORED
	}*/
	
	if( IsAdmin(sender) 
	|| ( get_user_team( sender ) == 2 && IsAlive(sender) )
	|| ( IsAlive(sender) && CanTalk[ sender ] ) ) 
	{ 
		//server_print("Talk %d %d", sender, reciver)
		return FMRES_IGNORED 
	} 

	engfunc( EngFunc_SetClientListening, reciver, sender, false ) 
	return FMRES_SUPERCEDE
} 

public voice_menu( id ) 
{ 
	if(!g_iPlugin)
	{
		return;
	}
	
	if( !( get_user_flags( id ) & FLAG ) && get_xvar_num(g_iXVar) != id) 
	{ 
		client_print(id, print_chat, "** This menu is only available for admins and simons")
		return;
	} 
	
	server_print("Continue")
	
	new menu = DoMenu()
	
	if(menu == -1)
	{
		client_print(id, print_chat, "** There are no alive Terrorist")
		return;
	}
	
	menu_display( id, menu, 0 ); 
}

stock DoMenu()
{
	new players[ 32 ], players_count, player, num[ 10 ], name[ 32 ] 
	get_players( players, players_count, "ae", "TERRORIST" ) 
	
	if(players_count) 
	{
		new mPlayer[ 60 ] , szStatus[20]
		new menu = menu_create( "\r[JailBreak]\y Voice Menu", "voice_menu_handler" ); 
		
		new iAdded
		for( new i; i < players_count; i++ ) 
		{ 
			player = players[ i ] 
			//if( get_user_team( player ) == 1 ) 
			if( !(get_user_flags(player) & FLAG) )
			{ 
				get_user_name( player, name, 31 ) 
				
				GetStatus(players[i], szStatus)
				formatex( mPlayer, charsmax( mPlayer ), "%s %s", name, szStatus)
				num_to_str( player, num, 9 ) 
				menu_additem( menu, mPlayer, num, 0 ) 
				
				iAdded++
			} 
		} 
		
		if(!iAdded)
		{
			menu_destroy(menu)
			return -1
		}
		
		menu_setprop( menu, MPROP_EXIT, MEXIT_NORMAL ); 
	
		return menu
	}
	
	return -1;
}

GetStatus(id, szStatus[20])
{
	switch(CanTalk[id])
	{
		case MUTE: szStatus = "\r[MUTED]"
		case TALK: szStatus = "\r[VOICE]"
		case TALK_SAVE: szStatus = "\r[VOICE] \y[SAVED]"
	}
}

public voice_menu_handler( id, menu, item ) 
{ 
	if( item == MENU_EXIT ) 
	{ 
		menu_destroy( menu ); 
		return
	} 
	
	new data[ 64 ], names[ 64 ], name[ 32 ], guard_name[ 32 ]; 
	new access, callback; 
	menu_item_getinfo( menu, item, access, data, 63, names, 63, callback ); 
	
	new key = str_to_num( data ); 
	
	get_user_name( id, guard_name, 31 ) 
	get_user_name( key, name, 31 ) 
	
	if(!is_user_alive(key))
	{
		menu_destroy(menu)
		
		menu = DoMenu()
		
		if(menu == -1)
		{
			client_print(id, print_chat, "** There are no alive Terrorist")
			return;
		}
		
		menu_display(id, menu)
		return;
	}
	
	new iMsg = 1
	new szItemName[32]
	
	if( CanTalk[ key ] == TALK) 
	{ 
		formatex(szItemName, charsmax(szItemName), "%s \r[VOICE] \y[SAVED]", name)
		iMsg = 0
		CanTalk[ key ] = TALK_SAVE
	} 
	
	else if( CanTalk[ key ] == TALK_SAVE) 
	{ 
		formatex(szItemName, charsmax(szItemName), "%s", name)
		CanTalk[ key ] = MUTE
	} 
	
	else 
	{ 
		formatex(szItemName, charsmax(szItemName), "%s \r[VOICE]", name )
		CanTalk[ key ] = TALK
	} 
	
	menu_item_setname(menu, item, szItemName)
	
	if(iMsg)
	{
		ColorChat( 0, NORMAL, "^3[ JailBreak ] ^4Guard %s ^1%s ^4Prisoner %s ^1The Ability To Talk.", guard_name, CanTalk[ key ] ? "Gave" : "Took", name ) 
	}
	
	menu_display(id, menu)
	//menu_destroy( menu ) 
}  
