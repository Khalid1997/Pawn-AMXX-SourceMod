#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Players Login info"
#define VERSION "1.0"
#define AUTHOR "Khalid"

#define ADMIN_LEVEL		ADMIN_CVAR
#define SILVER_LEVEL		ADMIN_LEVEL_H
#define GOLDEN_LEVEL		ADMIN_LEVEL_G

#define COLORED

new const szLevel[][] = {
	"Administrator",// 2
	"Golden Player",// 3
	"Silver Player" // 4
}

enum (+= 1)
{
	ADMIN,
	GOLDEN,
	SILVER
}
	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public client_authorized(id)
{
	static szName[32]
	get_user_name(id, szName, charsmax(szName))

	new level = get_level(id)
	
	if(level != -1)
	{
		#if defined COLORED
		ChatColor(0, "^1***** ^3%s ^4Login ^3%s ^4CONNECTED ^1*****", szLevel[level], szName)
		#else
		client_print(0, print_chat, "***** %s Login %s CONNECTED *****", szLevel[level], szName)
		#endif
	}

	return PLUGIN_HANDLED

}

get_level(id)
{
	new iFlags = get_user_flags(id)
	new authid[33]
	get_user_authid(id, authid, charsmax(authid))

	if( iFlags & ADMIN_LEVEL )
		return ADMIN
	
	else if( iFlags & GOLDEN_LEVEL )
		return GOLDEN
	
	else if( iFlags & SILVER_LEVEL )
		return SILVER
	
	else
		return -1
	
	return -1
}

#if defined COLORED
stock ChatColor(id, const fmt[], any:...) 
{ 
	new msg[191]; 
	vformat(msg, charsmax(msg), fmt, 3); 
	static msgSayText; 
	if( !msgSayText ) 
	{ 
		msgSayText = get_user_msgid("SayText"); 
	} 
	
	if( id ) 
	{ 
		message_begin(MSG_ONE_UNRELIABLE, msgSayText, _, id); 
		write_byte(id); 
		write_string(msg); 
		message_end(); 
	} 
	else 
	{ 
		new players[32], num 
		get_players(players, num, "ch") 
		for(--num; num>=0; num--) 
		{ 
			id = players[num] 
			message_begin(MSG_ONE_UNRELIABLE, msgSayText, _, id); 
			write_byte(id); 
			write_string(msg); 
			message_end(); 
		} 
	} 
}
#endif
