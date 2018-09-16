#include <amxmodx>

#define PLUGIN "Donate time"
#define VERSION "1.0"
#define AUTHOR "author"

native get_user_playedtime(id)
native set_user_playedtime(id, iNewTime)

new g_tempid[33]; // Played Id of target

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd( "say /donate", "CmdDonate", ADMIN_KICK ); //Opens the menu
	register_clcmd( "pt_donate", "CmdDonateTime", ADMIN_KICK );
}


// Messagemode pt_donate
public CmdDonateTime( id, level ) 
{ 
	if( !( get_user_flags(id) & level ) )
	{
		return PLUGIN_HANDLED
	}

	if(!is_user_connected(g_tempid[id]))
	{
		client_print(id, print_chat, "* Client no longer connected")
		return PLUGIN_HANDLED
	}
	
	new amount[ 21 ]; 
	read_argv( 1, amount, charsmax( amount )  ); 
	
	new szSenderName[ 32 ], szReceiverName[ 32 ];
	get_user_name( id, szSenderName, charsmax( szSenderName ) ); 
	get_user_name( g_tempid[id], szReceiverName, charsmax( szReceiverName ) );
	
	new timenum = str_to_num( amount ); 
	
	new iUserTime = get_user_playedtime(id)
	
	if( timenum > iUserTime )
	{
		client_print( id, print_chat, "* You don't have enough time to give." );
		return PLUGIN_HANDLED;
	}
	
	set_user_playedtime(g_tempid[id], get_user_playedtime(g_tempid[id]) + timenum);
	set_user_playedtime( id, iUserTime - timenum);
	
	client_print( g_tempid[id], print_chat, "* You received %i minutes from %s", timenum, szSenderName ); 
	client_print( id, print_chat, "* You gave %i minutes to %s leaving you %i minutes", timenum, szReceiverName, ( get_user_playedtime(id)) );
	
	return PLUGIN_HANDLED; 
}

public CmdDonate( id, level )
{
	if( !( get_user_flags(id) & level ) )
	{
		return PLUGIN_HANDLED
	}
	
	new frm[ 125 ];
	format( frm, charsmax( frm ), "\yDonate time to player ( Your time in minutes: \w%i )", get_user_playedtime( id ) );	
	new menu = menu_create( frm, "menu_handler" );
	
	new players[ 32 ], pnum, tempid;
	
	new szName[ 32 ], szTempid[ 10 ];
	
	get_players( players, pnum );
	
	for( new i; i < pnum; i++ )
	{
		tempid = players[ i ];
		
		get_user_name( tempid, szName, charsmax( szName ) );
		num_to_str( tempid, szTempid, charsmax( szTempid ) );
		
		menu_additem( menu, szName, szTempid, 0 );
		
	}
	menu_display( id, menu, 0 );
	
	return PLUGIN_HANDLED
}

public menu_handler( id, menu, item )
{
	if( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return;
	}
	
	new data[ 6 ], szName[ 64 ];
	new access, callback;
	menu_item_getinfo( menu, item, access, data, charsmax( data ), szName, charsmax( szName ), callback );
	
	menu_destroy( menu );
	
	g_tempid[id] = str_to_num( data );
	if(!is_user_connected(g_tempid[id]))
	{
		return;
	}
	
	new szTargetName[ 32 ];
	get_user_name( g_tempid[id], szTargetName, charsmax( szTargetName ) );
	
	client_print( id, print_chat, "* Write amount you want to donate to %s", szTargetName );
	
	client_cmd( id, "messagemode pt_donate" );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
