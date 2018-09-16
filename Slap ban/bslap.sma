/* Slap Ban Plugin by Khalid :)
This plugin is provided with absolute no warranties!

Description:
With the provided command, you can slap the user until he dies then it will automatically ban him.

Commands:
Just one command, which is:
amx_bslap <user> <Time to ban> <Ban Reason>

Cvars:
bs_slap_delay "0.1" // Delay between each slap

*/

#include <amxmodx>
#include <amxmisc>

#define ACCESS ADMIN_BAN

new const AUTHOR[] = "Khalid"
new const PLUGIN[] = "Slap Ban"
new const VERSION[] = "2.0"

new bool:InSlap[32]
new gVictimId, gpSlapDelay
new gsReason[50], giBanTime

new Float:fDelay

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_concmd("amx_bslap", "admin_slap", ACCESS, "<nick> <ban time> <reason> - Slaps user until death then bans him")
	gpSlapDelay = register_cvar("bs_slap_delay", "0.1")		// Must be Float
}

public admin_slap(id, level, cid)
{
	if( !cmd_access(id, level, cid, 4) )
		return PLUGIN_HANDLED
	
	new sVictimName[32], sAdminName[32], sBanTime[4]
	
	read_argv(1, sVictimName, 31)
	read_argv(2, sBanTime, 3)
	read_argv(3, gsReason, 49)
	
	giBanTime = str_to_num(sBanTime)
	
	gVictimId = cmd_target( id, sVictimName, CMDTARGET_ALLOW_SELF)
	
	if( !is_user_alive(gVictimId) || get_user_team(gVictimId) == 3 || !gVictimId )
	{
		console_print(id, "You can't slap-ban on the dead client, therefore, he will be banned !")
		
		new iVictimUserid = get_user_userid(gVictimId)
		new SteamId[20]
		get_user_authid(gVictimId, SteamId, 19)
		
		if( equali(SteamId, "STEAM_ID_LAN") || equali(SteamId, "VALVE_ID_PENDING"))
			server_cmd(";amx_banip #%i %i ^"%s^"", iVictimUserid, giBanTime, gsReason)		// No steam ban
		
		else 
			server_cmd(";amx_ban #%i %i ^"%s^"", iVictimUserid, giBanTime, gsReason)
		
		return PLUGIN_HANDLED
	}
	
	get_user_name(id, sAdminName, 31)
	get_user_name(gVictimId, sVictimName, 31)
	
	ChatColor(id, "^4[AMXX] Admin ^3%s ^4Slapped-ban player ^3%s", sAdminName, sVictimName)
	
	InSlap[gVictimId] = true
	fDelay = get_pcvar_float(gpSlapDelay)
	set_task(fDelay, "victim_slap", gVictimId)
	
	return PLUGIN_CONTINUE
}

public victim_slap(gVictimId)
{
	if( !gVictimId )
		return PLUGIN_HANDLED
	
	if( !is_user_alive(gVictimId) && is_user_connected(gVictimId) )
	{
		new iVictimUserid = get_user_userid(gVictimId)
		new SteamId[30]
		get_user_authid(gVictimId, SteamId, 19)
		
		if( equali(SteamId, "STEAM_ID_LAN") || equali(SteamId, "VALVE_ID_PENDING"))
			server_cmd(";amx_banip #%i %i ^"%s^"", iVictimUserid, giBanTime, gsReason)		// No steam ban
		
		else 
			server_cmd(";amx_ban #%i %i ^"%s^"", iVictimUserid, giBanTime, gsReason)
		
		InSlap[gVictimId] = false
		
		return PLUGIN_HANDLED
	}
	
	else
	{
		user_slap(gVictimId, 1)
		set_task(fDelay, "victim_slap", gVictimId)
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	if( id == gVictimId && InSlap[gVictimId] == true )
	{
		new iVictimUserid = get_user_userid(gVictimId)
		new SteamId[20]
		get_user_authid(gVictimId, SteamId, 19)
		
		if( equali(SteamId, "STEAM_ID_LAN") || equali(SteamId, "VALVE_ID_PENDING"))
			server_cmd(";amx_banip #%i %i ^"%s^"", iVictimUserid, giBanTime, gsReason)		// No steam ban
		
		else 
			server_cmd(";amx_ban #%i %i ^"%s^"", iVictimUserid, giBanTime, gsReason)
		
		InSlap[gVictimId] = false
		
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

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
