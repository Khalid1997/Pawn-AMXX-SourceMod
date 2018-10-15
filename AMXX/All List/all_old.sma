#include <amxmodx> 
//#include <vip>

/*---------------EDIT ME------------------*/ 
#define HEAD_ADMIN_CHECK ADMIN_IMMUNITY // flag A
#define ADMIN_CHECK ADMIN_RESERVATION // flag B
#define GOLDEN_CHECK ADMIN_LEVEL_H // Flag t
#define SILVER_CHECK ADMIN_LEVEL_G // flag s

static const COLOR_PREFIX[] = "^x04"
static const COLOR_ADMIN[] = "^x04" //green 
static const COLOR_GOLDEN[] = "^x01"
static const COLOR_SILVER[] = "^x03"
static const PREFIX[] = "[UaE-Gaming]"
static const CONTACT[] = "" 
/*----------------------------------------*/ 

new maxplayers 
new gmsgSayText 

public plugin_init() { 
	register_plugin("admin/golden/silver check", "1.0", "EvAn") 
	maxplayers = get_maxplayers() 
	gmsgSayText = get_user_msgid("SayText") 
	
	//register_c
	
	register_clcmd("say /all", "PrintAll")
	//register_clcmd("say /admins", "print_adminslist") 
	
	register_clcmd("say /goldens", "print_goldenlist") 
	register_clcmd("say /goldenplayers", "print_goldenlist") 
	
	register_clcmd("say /silvers", "print_silverlist") 
	register_clcmd("say /silverplayers", "print_silverlist") 
	register_cvar("amx_contactinfo", CONTACT, FCVAR_SERVER) 
} 

public PrintAll(id)
{
	print_headadminlist(id)
	print_adminslist(id)
	print_goldenlist(id)
	print_silverlist(id)
	
	new contact[64], contactinfo[112];
	get_cvar_string("amx_contactinfo", contact, 63) 
	if(contact[0])  { 
		format(contactinfo, 111, "%s Contact Server Admin -- %s", COLOR_PREFIX, contact) 
		//print_message(id, contactinfo) 
		client_print_color(id, print_team_default, contactinfo);
	} 
	//print_vips(id)
}

public print_adminslist(user)  
{ 
	new adminnames[33][32] 
	new message[256] 
	new id, count, x, len 
	
	for(id = 1 ; id <= maxplayers ; id++) 
		if(is_user_connected(id)) 
		if(get_user_flags(id) & ADMIN_CHECK) 
		get_user_name(id, adminnames[count++], 31) 
	
	len = format(message, 255, "^x01%s%s %sAdmins online: ", COLOR_PREFIX, PREFIX, COLOR_ADMIN) 
	if(count > 0) { 
		for(x = 0 ; x < count ; x++) { 
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"") 
			if(len > 96 ) { 
				//print_message(user, message) 
				client_print_color(id, print_team_default, message);
				len = format(message, 255, "%s ",COLOR_PREFIX) 
			} 
		} 
		client_print_color(id, print_team_default, message);
	} 
	else { 
		len += format(message[len], 255-len, "No admins online.") 
		client_print_color(id, print_team_default, message);
	} 
} 

public print_goldenlist(user)  
{ 
	new adminnames[33][32] 
	new message[256] 
	new id, count, x, len 
	
	for(id = 1 ; id <= maxplayers ; id++) 
		if(is_user_connected(id)) 
		if(get_user_flags(id) & GOLDEN_CHECK) 
		get_user_name(id, adminnames[count++], 31) 
	
	len = format(message, 255, "^x01%s%s %sGolden players online: ", COLOR_PREFIX, PREFIX, COLOR_GOLDEN) 
	if(count > 0) { 
		for(x = 0 ; x < count ; x++) { 
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"") 
			if(len > 96 ) { 
				client_print_color(id, print_team_default, message);
				len = format(message, 255, "%s ",COLOR_PREFIX) 
			} 
		} 
		client_print_color(id, print_team_default, message);
	} 
	else { 
		len += format(message[len], 255-len, "No golden players online.") 
		client_print_color(id, print_team_default, message);
	}  
} 

public print_silverlist(user)  
{ 
	new adminnames[33][32] 
	new message[256] 
	new id, count, x, len 
	
	for(id = 1 ; id <= maxplayers ; id++) 
		if(is_user_connected(id)) 
		if(get_user_flags(id) & SILVER_CHECK) 
		get_user_name(id, adminnames[count++], 31) 
	
	len = format(message, 255, "^x01%s%s %sSilver players online: ", COLOR_PREFIX, PREFIX, COLOR_SILVER) 
	if(count > 0) { 
		for(x = 0 ; x < count ; x++) { 
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"") 
			if(len > 96 ) { 
				client_print_color(id, print_team_grey, message);
				len = format(message, 255, "%s ",COLOR_PREFIX) 
			} 
		} 
		client_print_color(id, print_team_grey, message);
	} 
	else { 
		len += format(message[len], 255-len, "No silver players online.") 
		client_print_color(id, print_team_grey, message); 
	} 
} 

public print_headadminlist(user)  
{ 
	new adminnames[33][32] 
	new message[256] 
	new id, count, x, len 
	
	for(id = 1 ; id <= maxplayers ; id++) 
		if(is_user_connected(id)) 
		if(get_user_flags(id) & HEAD_ADMIN_CHECK) 
		get_user_name(id, adminnames[count++], 31) 
	
	len = format(message, 255, "^x01%s%s %sHead Admins online: ", COLOR_PREFIX, PREFIX, COLOR_SILVER) 
	if(count > 0) { 
		for(x = 0 ; x < count ; x++) { 
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"") 
			if(len > 96 ) { 
				client_print_color(id, print_team_blue, message);
				len = format(message, 255, "%s ",COLOR_PREFIX) 
			} 
		} 
		client_print_color(id, print_team_blue, message);
	} 
	else { 
		len += format(message[len], 255-len, "No silver players online.") 
		client_print_color(id, print_team_blue, message); 
	} 
} 

stock print_message(id, msg[]) { 
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id) 
	write_byte(id) 
	write_string(msg) 
	message_end() 
} 
