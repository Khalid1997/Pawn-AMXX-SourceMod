#include <amxmodx>

/*---------------EDIT ME------------------*/
#define ADMIN_CHECK ADMIN_RESERVATION
#define SILVER		ADMIN_LEVEL_H
#define GOLDEN		ADMIN_LEVEL_G

static const COLOR[] = "^x04" //green
static const CONTACT[] = ""
/*----------------------------------------*/

new maxplayers
new gmsgSayText

new bool:all

new gpInfo

public plugin_init() {
	register_plugin("Admin Check", "1.51", "OneEyed")
	maxplayers = get_maxplayers()
	gmsgSayText = get_user_msgid("SayText")
	register_clcmd("say /goldenplayers", "print_goldens")
	register_clcmd("say /goldens", "print_goldens")
	register_clcmd("say /silverplayers", "print_silvers")
	register_clcmd("say /silvers", "print_silvers")
	register_clcmd("say /all", "print_all")
	gpInfo = register_cvar("amx_contactinfo", CONTACT, FCVAR_SERVER)
}

/*public handle_say(id) {
	new said[192]
	read_args(said,192)
	if( ( containi(said, "who") != -1 && containi(said, "admin") != -1 ) || contain(said, "/admin") != -1 )
		set_task(0.1,"print_adminlist",id)
	return PLUGIN_CONTINUE
}*/

public print_goldens(user) 
{
	new adminnames[33][32]
	new message[256]
	new contactinfo[256], contact[112]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id))
			if(get_user_flags(id) & GOLDEN)
				get_user_name(id, adminnames[count++], 31)

	len = format(message, 255, "%s GOLDENS ONLINE: ",COLOR)
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "%s ",COLOR)
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "No goldens online.")
		print_message(user, message)
	}
	
	if( all != true )
	{
		get_pcvar_string(gpInfo, contact, 63)
		if(contact[0])  {
			format(contactinfo, 111, "%s Contact Server Admin -- %s", COLOR, contact)
			print_message(user, contactinfo)
		}
	}

}

public print_silvers(user) 
{
	new adminnames[33][32]
	new message[256]
	new contactinfo[256], contact[112]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id))
			if(get_user_flags(id) & SILVER)
				get_user_name(id, adminnames[count++], 31)

	len = format(message, 255, "%s SILVERS ONLINE: ",COLOR)
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "%s ",COLOR)
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "No silvers online.")
		print_message(user, message)
	}
	
	if( all != true )
	{
		get_pcvar_string(gpInfo, contact, 63)
		if(contact[0])  {
			format(contactinfo, 111, "%s Contact Server Admin -- %s", COLOR, contact)
			print_message(user, contactinfo)
		}
	}

}

public print_all(user) 
{
	new adminnames[33][32]
	new message[256]
	new contactinfo[256], contact[112]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id))
			if(get_user_flags(id) & ADMIN_CHECK)
				get_user_name(id, adminnames[count++], 31)

	len = format(message, 255, "%s ADMINS ONLINE: ",COLOR)
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "%s ",COLOR)
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "No admins online.")
		print_message(user, message)
	}
	all = true
	//set_task(0.1, "print_goldens", user)
	//set_task(0.1, "print_silvers", user)
	print_goldens(user)
	print_silvers(user)
	
	get_pcvar_string(gpInfo, contact, 63)
	if(contact[0])  {
		format(contactinfo, 111, "%s Contact Server Admin -- %s", COLOR, contact)
		print_message(user, contactinfo)
	}
	all = false
}

print_message(id, msg[]) {
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}
