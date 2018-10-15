#include <amxmodx>  
#include <amxmisc>  
#include <sqlx>  

#define PLUGIN "Played Time"  
#define VERSION "0.1"  
#define AUTHOR "DIS"  

#define host "127.0.0.1"  
#define user "root"  
#define pass ""  
#define db "time"  

new Handle:sql, g_query[512]  
new PlayedTime[33]  
new showpt;  
new g_iMaxPlayers

#define IsPlayer(%0) ( 1 <= %0 <= g_iMaxPlayers )

new g_szName[33][32]

public plugin_init()   
{  
	register_plugin(PLUGIN, VERSION, AUTHOR );  
	
	if(is_module_loaded("sqlite") != -1)
	{
		set_fail_state("Only MySQL can be used. You can't use SQLITE")
		return;
	}
		
	sql = SQL_MakeDbTuple(host,user,pass,db)  
	formatex(g_query,511,"CREATE TABLE IF NOT EXISTS `played_time` (name VARCHAR(32), playedtime INT, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);")  
	SQL_ThreadQuery(sql,"query", g_query)  
	
	if(sql == Empty_Handle)
	{
		set_fail_state("Can't connect to database")
		return;
	}

	register_clcmd("say", "handle_say");  
	register_concmd("amx_playedtime", "admin_showptime", ADMIN_RCON," <#Player Name> - Details about playedtime.");  
	
	showpt = register_cvar("amx_pt_mod","1");  
	
	g_iMaxPlayers = get_maxplayers()
}

public plugin_natives()
{
	register_library("played_time")
	
	register_native("get_user_playedtime", "_get_user_playedtime")
	
	register_native("get_user_played_time", "_get_user_playedtime")
	
	register_native("set_user_playedtime", "_set_user_playedtime")
	
	register_native("set_user_played_time", "_set_user_playedtime")
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

public handle_say(id)   
{  
	static said[12]  
	read_argv(1, said, 11)  
	
	if(equali(said, "/my_time"))  
	{  
		static ctime[64], timep;  
		
		timep = get_user_time(id, 1) / 60;  
		get_time("%H:%M:%S", ctime, 63);  
		
		switch(get_pcvar_num(showpt))  
		{  
			case 0: return PLUGIN_HANDLED;  
				
			case 1 :  
			{  
				client_print(id, print_chat, "[Played-Time] You have been playing on the server for: %d minute%s.", timep, timep == 1 ? "" : "s");   
				client_print(id, print_chat, "[Played-Time] Your total played time on the server: %d minute%s.", timep+PlayedTime[id], timep+PlayedTime[id] == 1 ? "" : "s");  
			}  
			case 2 :  
			{  
				set_hudmessage(255, 50, 50, 0.34, 0.50, 0, 6.0, 4.0, 0.1, 0.2, -1);  
				show_hudmessage(id, "[Elite-Gaming] You have been playing on the server for: %d minute%s.^n[AMXX]Current time: %s", timep, timep == 1 ? "" : "s", ctime);  
			}  
		}  
		return PLUGIN_HANDLED;  
	}  
	else if(equal(said,"/time")){  
		new data[1];data[0]=id  
		
		formatex(g_query,511,"SELECT * FROM played_time ORDER BY playedtime DESC LIMIT 15")  
		SQL_ThreadQuery(sql,"show_top15",g_query,data,1)  
		
	}  
	return PLUGIN_CONTINUE;  
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
	console_print(id, "[Played-Time] %s have been playing on the server for %d minute%s.",name, timep, timep == 1 ? "" : "s");  
	console_print(id, "[Played-Time] %s's total played time on the server %d minute%s.",name, timep+PlayedTime[player], timep == 1 ? "" : "s"); // new  
	console_print(id, "-----------------------------------------------------------------");  
	
	return PLUGIN_HANDLED;  
}  

public client_disconnect(id){  
	
	//get_user_name(id,name,31)      
	//replace_all(name,31,"'","")  
	//replace_all(name,31,"^"","")  
	
	//server_print("PlayedTime[id] = %d <> name = %s <> get_user_time(id, 1) = %d <> (get_user_time(id, 1) / 60) = %d", PlayedTime[id], name, get_user_time(id, 1), get_user_time(id, 1) / 60)
	
	formatex(g_query,511,"UPDATE played_time SET playedtime='%d' WHERE name='%s'", PlayedTime[id] + (get_user_time(id, 1) / 60), g_szName[id])  
	SQL_ThreadQuery(sql,"query",g_query)  
	
	PlayedTime[id] = 0  
}  

public client_putinserver(id)
{  
	PlayedTime[id] = get_playedtime(id)
	get_user_name(id, g_szName[id], 31)
	
	client_print(id, print_chat, "[PLAYED TIME] Player %s connected with %d minutes!", g_szName[id], PlayedTime[id])
}  

public plugin_end()
{  
	SQL_FreeHandle(sql)  
}  

enum _:QUERY_DATA
{
	I_ID,
	SZ_QUERY[512]
}

#if !defined NEW_WAY
get_playedtime(id){  
	new err,error[128]  
	
	new Handle:connect = SQL_Connect(sql,err,error,127)  
	
	if(err){  
		log_amx("--> MySQL Connection Failed - [%d][%s]",err,error)  
		set_fail_state("mysql connection failed")  
	}  
	
	new name[32],Handle:query,pt  
	get_user_name(id,name,31)  
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
	
	log_amx("--> Get %d minutes for %s",pt,name)  
	
	SQL_FreeHandle(connect)  
	SQL_FreeHandle(query)  
	
	return pt  
}  

#else
get_playedtime(id)
{  
	//new err,error[128]  
	
	//new Handle:connect = SQL_Connect(sql,err,error,127)  
	
	/*if(err)
	{  
		log_amx("--> MySQL Connection Failed - [%d][%s]",err,error)  
		set_fail_state("mysql connection failed")  
	}  */
	
	new name[32]
	get_user_name(id,name,31)  
	replace_all(name, 32, "'" , "")  
	replace_all(name, 32, "^"", "")  
	
	formatex(g_query, charsmax(g_query), "SELECT playedtime FROM `played_time` WHERE name = '%s'",  name)
	
	new data[QUERY_DATA]
	data[I_ID] = id
	data[SZ_QUERY] = g_query
	SQL_ThreadQuery(sql, "GetPlayedTimeQuery", g_query, data, sizeof data)
	
	// new Handle:query,pt  
	//query = SQL_PrepareQuery(connect,"SELECT playedtime FROM played_time WHERE name='%s'",name)  
	//SQL_Execute(query)  
	
	SQL_FreeHandle(connect)  
	SQL_FreeHandle(query)  
	
	return pt  
}  

public GetPlayedTimeQuery(iFs, Handle:hQuery, szError[], iErrN, Data[QUERY_DATA], iSize)//, Float:queuetime)
{
	if(iFs || iErrN)
	{
		log_amx("**(Get)**PlayedTime Query Error!^n\
		----  Query #%d ----^n\
		FailState : %d^n\
		ErrorCode %d^n\
		Error: %s^n\
		^n\
		Query: %s^n\
		Id: %d^n\
		--------------------", hQuery, iFs, iErrN, szError, Data[SZ_QUERY], Data[I_ID])
		
		return;
	}
	
	new iNumResults = SQL_NumResults(hQuery)
	
	if(iNumResults)
	{
		new szName[32]; get_user_name(Data[I_ID], szName, 31)
		log_amx("Client %s has %d results!", szName, iNumResults)
		if(iNumResults > 1)
		{
			new szName[32]; get_user_name(Data[I_ID], szName, 31)
			
			new i
			while(SQL_MoreResults(hQuery))
			{
				log_amx("Results #%d: %d", ++i, SQL_ReadResult(hQuery, 0))
				SQL_NextRow(hQuery)
			}
		}
		
		else
		{
			PlayedTime[Data[I_ID]] = ( SQL_ReadResult(hQuery, 0) + (get_user_time(Data[I_ID], 1) / 60) )
		}
	}

	else
	{
		new szName[32]; get_user_name(Data[I_ID], szName, 31)
		formatex(g_query, charsmax(g_query), "INSERT INTO `played_time` ( name, playedtime ) VALUES ( '%s', 0 )", szName)
		SQL_ThreadQuery(sql, "query", g_query)
	}
}

#endif

public show_top15(FailState, Handle:Query, Error[], Errcode,Data[], DataSize){  
	static name[32]  
	
	new id=Data[0]  
	new good,motd[1024],len,place  
	
	if(!SQL_MoreResults(Query)){  
		client_print(id,print_chat,"[PT] No entries")  
		return PLUGIN_HANDLED  
	}  
	
	len = format(motd, 1023,"<body bgcolor=#000000><font color=#FFB000><pre>")  
	len += format(motd[len], 1023-len,"%s %-22.22s %3s^n", "#", "Name", "Time")  
	
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
	if(FailState || Errcode)
	{
		log_amx("Query Error!^n\
		----  Query #%d ----^n\
		FailState : %d^n\
		ErrorCode %d^n\
		Error: %s^n\
		--------------------", Query, FailState, Errcode, Error)
	}
}  
