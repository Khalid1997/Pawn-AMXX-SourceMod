#include <amxmodx>
#include <amxmisc>
#include <played_time>

#define PLUGIN "Set User Time"
#define VERSION "1.0"
#define AUTHOR "Khalid :)"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_concmd("pt_set_time", "admin_set_time", ADMIN_KICK, "<name> <time> - Set's player time to <time> value")
}

public admin_set_time(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new szArg[32]
	read_argv(1, szArg, charsmax(szArg))
	
	new iPlayer = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF)
	if(!iPlayer)
	{
		console_print(id, "Player could not be found")
		return PLUGIN_HANDLED
	}
	
	read_argv(2, szArg, charsmax(szArg))
	
	new iTime = str_to_num(szArg)
	if(!iTime)
	{
		console_print(id, "You can't do that!.")
		return PLUGIN_HANDLED
	}
	get_user_name(id, szArg, charsmax(szArg))
	server_print("%s's current played time is: %d", szArg, get_user_ptime(iPlayer))
	set_user_ptime(iPlayer, iTime)
	new szAdminName[32]
	
	get_user_name(id, szAdminName, charsmax(szAdminName))
	
	client_print(0, print_chat, "[AMXX] Admin %s: set user %s played time to %d", szAdminName, szArg, iTime)
	return PLUGIN_HANDLED
}
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
