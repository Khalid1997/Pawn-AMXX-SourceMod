/*Played Time with "Current(Total) played Time" on server.
Many thanks to hackziner & Deviance for show how to use "nvault"
Thanks to Avalanche for Prune function*/

#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <nvault>

#define PLUGIN "Played Time"
#define VERSION "2.13"
#define AUTHOR "Freeman & Khalid"

#define host "localhost"
#define user "root"
#define pass ""
#define db "amxx"

new Handle:sql, g_query[512]

new PlayedTime[33], g_tempid;
new g_iDonates[33]

new showpt;

new vault;

// *** Admin/Silver/Golden Flags ***
#define ADMIN		ADMIN_BAN
#define GOLDEN		ADMIN_LEVEL_H
#define SILVER		ADMIN_LEVEL_G
// Final Flag
#define FLAGS		(ADMIN|GOLDEN|SILVER)


#define SILVER_MAX_DTIME	700
#define GOLDEN_MAX_DTIME	1400
#define ADMIN_MAX_DTIME		1700

new g_iMaxPlayers
#define IsPlayer(%1) (1 <= %1 <= g_iMaxPlayers)

public plugin_precache()
{
	precache_sound("played_time/clap.wav")
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR );
	register_clcmd("say /mytime", "show_mytime");
	register_clcmd("say /my_time", "show_mytime");
	
	register_clcmd("say /top15_time", "player_show_top15")
	
	register_concmd("amx_playedtime", "admin_showptime", ADMIN_BAN," <#Player Name> - Details about playedtime.");
	
	register_concmd("spt_donate", "CmdDonate", FLAGS); //Opens the menu
	register_clcmd("pt_donate", "CmdDonateTime", FLAGS, "<amount>" );
	
	g_iMaxPlayers = get_maxplayers()

	showpt = register_cvar("amx_pt_mod","1");
	
	vault = nvault_open("donated_time")
}

public client_infochanged(id)
{
	static szName[32], szOldName[32]
	get_user_name(id, szOldName, charsmax(szOldName))
	get_user_info(id, "name", szName, charsmax(szName))
	
	if(!equal(szOldName, szName))
	{	
		PlayedTime[id] = get_playedtime(id, 1)
		
		add(szName, charsmax(szName), "_donatedtime")
		add(szOldName, charsmax(szOldName), "_donatedtime")
		
		new szDonates[25]
		formatex(szDonates, charsmax(szDonates), "%d", g_iDonates[id])
		
		nvault_remove(vault, szOldName)
		nvault_set(vault, szOldName, szDonates)
		
		g_iDonates[id] = nvault_get(vault, szName)
	}
}	

public plugin_natives()
{
	register_library("played_time")
	
	register_native("get_user_playedtime", "_get_user_playedtime")
	register_native("set_user_playedtime", "_set_user_playedtime")
}

public _get_user_playedtime(iPlugin, iParams)
{
	if(iParams != 1)
		return -1
	
	new id = get_param(1)
	
	if(!IsPlayer(id))
		return -1
		
	if(!is_user_connected(id))
		return -1
		
	return PlayedTime[id]
}

public _set_user_playedtime(iPlugin, iParams)
{
	if(iParams != 2)
		return 0
	
	new id = get_param(1)
	
	if(!IsPlayer(id))
	{
		log_error(AMX_ERR_NATIVE, "Index out of bounds %d", id)
		return 0
	}
		
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "User not connected %d", id)
		return 0
	}
		
	new iTime = get_param(2)
	
	if(iTime < 0)
		iTime = 0
		
	PlayedTime[id] = iTime
	return 1
}

public plugin_cfg(){
	//sql = SQL_MakeDbTuple(host,user,pass,db)
	
	sql = SQL_MakeDbTuple(host, user, pass, db)
	formatex(g_query,511,"CREATE TABLE IF NOT EXISTS `played_time` (name VARCHAR(32), playedtime INT, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)")
	SQL_ThreadQuery(sql,"query",g_query)
	
	new day = nvault_get(vault, "day")
	new fmt[5]
	get_time("%d", fmt, 4)
	
	if(!day)
	{
		nvault_set(vault, "day", fmt)
	}
	
	new currentday = str_to_num(fmt)
	
	if(currentday != day)
	{
		//nvault_remove(vault, "day")
		nvault_prune( vault, 0, 0 )
		nvault_set(vault, "day", fmt)
	}
}

/* ******************** Do not touch anything here execpt chats! ****************************** */
public CmdDonateTime( id, level, cid ) 
{ 
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
		
	new amount[ 21 ]; 
	
	read_argv( 1, amount, 20 ); 
	
	if(!is_str_num(amount) || amount[0] == '-')
	{
		client_print(id, print_chat, "* You can't donate that!")
		return PLUGIN_HANDLED
	}
	
	new timenum = str_to_num( amount );
	
	if( timenum > PlayedTime[ id ] )
	{
		client_print( id, print_chat, "* You don't have enough time to give." );
		return PLUGIN_HANDLED;
	}
	
	new allow = allow_donate(id, timenum)
	
	if( allow == -1 )
	{
		client_print(id, print_chat, "*** You have exeeded the amount of minutes that can be donated per day.")
		return PLUGIN_HANDLED
	}
	
	donate(id, g_tempid, allow)

	//donate(id, g_tempid, timenum)
	
	client_cmd(0, "spk ^"played_time/clap.wav^"")
	
	return PLUGIN_CONTINUE; 
}

donate(id, reciverid, amount)
{
	new name[32], name2[32]
	get_user_name(id, name, 31)
	get_user_name(reciverid, name2, 31)

	/*formatex(g_query, charsmax(g_query), "UPDATE played_time SET playedtime=playedtime-%d WHERE name='%s'", amount, name)
	SQL_ThreadQuery(sql, "query", g_query)
		
	formatex(g_query, charsmax(g_query), "UPDATE played_time SET playedtime=playedtime+%d WHERE name='%s'", amount, name2)
	SQL_ThreadQuery(sql, "query", g_query)*/

	PlayedTime[id] -= amount
	PlayedTime[reciverid] += amount
	
	// Limits
	add_to_donated_time(id, amount)
	
	new flags = get_user_flags(id)
	if(flags & ADMIN)
	{
		client_print(0, print_chat, "*** Admin %s donated %d minutes to %s.", name, amount, name2)
	}
	
	else if(flags & SILVER)
	{
		client_print(0, print_chat, "*** Silver Player %s donated %d minutes to %s.", name, amount, name2)
	}
	
	else if(flags & GOLDEN)
	{
		client_print(0, print_chat, "*** Golden Player %s donated %d minutes to %s.", name, amount, name2)
	}
}

add_to_donated_time(id, dtime)
{
	g_iDonates[id] += dtime
	g_iDonates[id] += dtime
}

allow_donate(id, amount)
{	
	new something
	
	new donated_time = g_iDonates[id]
	new flags = get_user_flags(id)
	
	if(flags & SILVER)
	{
		if( donated_time >= SILVER_MAX_DTIME )
			return -1
	
		if( (donated_time + amount) > SILVER_MAX_DTIME && (SILVER_MAX_DTIME - donated_time != 0))
		{
			something = SILVER_MAX_DTIME - donated_time
			return something
		}
	}
	
	else if(flags & GOLDEN)
	{
		if( donated_time == GOLDEN_MAX_DTIME )
			return -1
	
		if( (donated_time + amount) > GOLDEN_MAX_DTIME && (GOLDEN_MAX_DTIME - donated_time != 0))
		{
			something = GOLDEN_MAX_DTIME - donated_time
			return something
		}
	}
	
	else if(flags & ADMIN)
	{
		if( donated_time == ADMIN_MAX_DTIME )
			return -1
	
		if( (donated_time + amount) > ADMIN_MAX_DTIME && (ADMIN_MAX_DTIME - donated_time != 0))
		{
			something = ADMIN_MAX_DTIME - donated_time
			return something
		}
	}
	
	return amount
}

public CmdDonate( id, level, cid )
{
	if(!cmd_access(id, level, cid, 1))
	{
		client_print(id, print_chat, "*** You don't have access to this command!")
		return PLUGIN_HANDLED
	}

	new frm[ 125 ];

	new dtimeleft = g_iDonates[id]

	new flag = get_user_flags(id)
	if(flag & SILVER)
		dtimeleft = SILVER_MAX_DTIME - dtimeleft
	
	else if(flag & GOLDEN)
		dtimeleft = GOLDEN_MAX_DTIME - dtimeleft
	
	else if(flag & ADMIN)
		dtimeleft = ADMIN_MAX_DTIME - dtimeleft
	
	format( frm, charsmax( frm ), "\wDonate time to player \y( \rMinutes left: \w%d \y)", dtimeleft)
	//format( frm, charsmax( frm ), "\wDonate time to player \y( \rYour Current Played Time: \w%d \y)", PlayedTime[id] );

	
	new menu = menu_create( frm, "menu_handler" );
	
	new players[ 32 ], pnum, tempid;
	
	new szName[ 32 ], szTempid[ 10 ];
	
	get_players( players, pnum );
	
	for( new i; i < pnum; i++ )
	{
		tempid = players[ i ];
		
		if( tempid != id )
		{	
			get_user_name( tempid, szName, charsmax( szName ) );
			num_to_str( tempid, szTempid, charsmax( szTempid ) );
			menu_additem( menu, szName, szTempid, 0 );
		}
		
	}
	menu_display( id, menu, 0 );
	
	return PLUGIN_HANDLED
}

public menu_handler( id, menu, item )
{
	if( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[ 6 ], szName[ 64 ];
	new _access, callback;
	menu_item_getinfo( menu, item, _access, data, charsmax( data ), szName, charsmax( szName ), callback );
	
	g_tempid = str_to_num( data );
	
	new szTargetName[ 32 ];
	get_user_name( g_tempid, szTargetName, charsmax( szTargetName ) );
	
	client_print( id, print_chat, "* Write amount you want to donate to %s", szTargetName );
	
	client_cmd( id, "messagemode pt_donate" );
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}


public show_mytime(id) 
{
	/*static said[12]
	read_argv(1, said, 11)
	
	if(equali(said, "/my_time") || equali(said, "/mytime") || equali(said, "my_time") || equali(said, "mytime"))
	{*/
	static ctime[64], timep;
		
	timep = get_user_time(id, 1) / 60;
	//get_time("%H:%M:%S", ctime, 63);
		
	switch(get_pcvar_num(showpt))
	{
		case 0: return PLUGIN_HANDLED;
				
		case 1 :
		{
			client_print(id, print_chat, "[Played Time] You have been playing on the server for: %d minute%s.", timep, timep == 1 ? "" : "s"); 
			client_print(id, print_chat, "[Played Time] Your total played time on the server: %d minute%s.", timep + PlayedTime[id], timep + PlayedTime[id] == 1 ? "" : "s");
		}
		case 2 :
		{
			set_hudmessage(255, 50, 50, 0.34, 0.50, 0, 6.0, 4.0, 0.1, 0.2, -1);
			show_hudmessage(id, "[PT] You have been playing on the server for: %d minute%s.^n[PT]Current time: %s", timep, timep == 1 ? "" : "s", ctime);
		}
	}
	return PLUGIN_HANDLED;
	//}
}

public player_show_top15(id)
{
	new data[1];data[0]=id
		
	formatex(g_query,511,"SELECT * FROM played_time ORDER BY playedtime DESC LIMIT 15")
	SQL_ThreadQuery(sql,"show_top15",g_query,data,1)
	return PLUGIN_CONTINUE
}

public admin_showptime(id,level,cid) 
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	static arg[32];
	read_argv(1, arg, 31);
	
	new player = cmd_target(id, arg, 2);
	
	if(!player)
		return PLUGIN_HANDLED;
	
	static name[32];
	get_user_name(player, name, 31);
	
	static timep, ctime[64];
	
	timep = get_user_time(player, 1) / 60;
	get_time("%H:%M:%S", ctime, 63);
	
	console_print(id, "-----------------------(#PlayedTime#)-----------------------");
	console_print(id, "[Played Time] %s have been playing on the server for %d minute%s.",name, timep, timep == 1 ? "" : "s");
	console_print(id, "[Played Time] %s's total played time on the server %d minute%s.",name, timep+PlayedTime[player], timep == 1 ? "" : "s"); // new
	console_print(id, "-----------------------------------------------------------------");
	
	return PLUGIN_HANDLED;
}

public client_disconnect(id){
	new name[32], szValue[5], szKey[55]
	
	get_user_name(id,name,charsmax(name))
	
	formatex(szKey, charsmax(szKey), "%s_donatedtime", name)
	nvault_remove(vault, szKey)
	
	formatex(szValue, charsmax(szValue), "%d", g_iDonates[id])
	nvault_set(vault, name, szKey)
	
	replace_all(name,32,"'","")
	replace_all(name,32,"^"","")
	
	formatex(g_query,511,"UPDATE played_time SET playedtime='%d' WHERE name='%s'", PlayedTime[id] + (get_user_time(id) / 60), name)

	SQL_ThreadQuery(sql,"query",g_query)
	
	PlayedTime[id] = 0
}

public client_putinserver(id)
{	
	static name[32]
	get_user_name(id, name, 31)
	new szkey[50]
	formatex(szkey, 49, "%s_donatedtime", name)
	
	g_iDonates[id] = nvault_get(vault, szkey, charsmax(szkey))
	PlayedTime[id] = get_playedtime(id)
}

public plugin_end(){
	SQL_FreeHandle(sql)

	nvault_close(vault)
}


get_playedtime(id, iNewName = 0){
	new err,error[128]
	
	new Handle:connect = SQL_Connect(sql,err,error,127)
	
	if(err){
		log_amx("--> MySQL Connection Failed - [%d][%s]",err,error)
		set_fail_state("mysql connection failed")
	}
	
	new name[32],Handle:query,pt
	if(iNewName)
	{
		get_user_info(id, "name", name, charsmax(name))
	}
	
	else get_user_name(id,name,31)
	
	replace_all(name,32,"'","")
	replace_all(name,32,"^"","")
	
	query = SQL_PrepareQuery(connect,"SELECT playedtime FROM played_time WHERE name='%s'",name)
	SQL_Execute(query)
	
	if(!SQL_MoreResults(query)){
		formatex(g_query,511,"INSERT INTO played_time (name,playedtime) VALUES('%s','%d')",name,get_user_time(id,1)/60)
		SQL_ThreadQuery(sql,"query",g_query)
		
		pt = (get_user_time(id,1)/60)
		}else{
		pt = SQL_ReadResult(query,0)+(get_user_time(id,1)/60)
	}
	
	SQL_FreeHandle(connect)
	SQL_FreeHandle(query)
	
	return pt
}

public show_top15(FailState, Handle:Query, Error[], Errcode,Data[], DataSize){
	static name[32]
	
	new id=Data[0]
	new good,motd[1024],len,place
	
	if(!SQL_MoreResults(Query)){
		client_print(id,print_chat,"[PT] No Data")
		return PLUGIN_HANDLED
	}
	
	len = format(motd, 1023,"<body bgcolor=#000000><font color=#FFB000><pre>")
	len += format(motd[len], 1023-len,"%s %-22.22s %3s^n", "#", "Name", "Time in minutes")
	
	while(SQL_MoreResults(Query)){
		place++
		
		SQL_ReadResult(Query,0,name, 32)
		good = SQL_ReadResult(Query,1)
		
		replace_all(name, 32,"<","")
		replace_all(name, 32,">","")
		
		len += format(motd[len], 1023-len,"%d %-22.22s %d minute%s^n",place,name,good,good == 1 ? "" : "s")
		
		SQL_NextRow(Query)
	}
	
	len += format(motd[len], 1023-len,"</body></font></pre>")
	show_motd(id, motd,"Top 15 Players By Time")
	
	return PLUGIN_CONTINUE
}

public query(FailState, Handle:Query, Error[], Errcode)
{
	if( Errcode )
	{
		server_print("ERROR IN PLAYEDTIME SQL:")
		server_print("%s", Error)
		
		set_fail_state("Sql connection failed")
	}
} 
