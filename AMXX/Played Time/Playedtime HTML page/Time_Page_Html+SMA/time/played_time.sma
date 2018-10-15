/*Played Time with "Current(Total) played Time" on server.*/
/*Many thanks to hackziner & Deviance for show how to use "nvault".*/
/*Thanks to Avalanche for Prune function*/


#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define NEW_STYLE
#define COLORED


#define PLUGIN "Played Time"
#define VERSION "0.1"
#define AUTHOR "[LF] | Dr.Freeman"

#define host "abudhabi-gaming.net"
#define user "khalid14_test"
#define pass "Khalid123"
#define db "khalid14_test"

#if defined COLORED
new const PREFIX[] = "^4[^1Played Time^4]"
#else
new const PREFIX[] = "[Played Time]"
#endif

new Handle:sql, g_query[512]

new PlayedTime[33]

new showpt;

new const TABLE_NAME[] = "played_time_multimod"

enum _:LEVELS
{
	PLAYER_NORMAL,
	ADMIN,
	GOLDEN,
	SILVER
}

// Edit in php script
new const g_szLevels[LEVELS][] = {
	"Normal Player",
	"Adminstrator",
	"Golden Player",
	"Silver Player"
}

new const FLAGS[LEVELS] = {
	0, // No flags
	ADMIN_RESERVATION,
	ADMIN_LEVEL_H,
	ADMIN_LEVEL_G
}

enum Color
{
    NORMAL = 1, // clients scr_concolor cvar color
    GREEN, // Green Color
    TEAM_COLOR, // Red, grey, blue
    GREY, // grey
    RED, // Red
    BLUE, // Blue
}


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR );
	
	register_clcmd("say", "handle_say");
	register_concmd("amx_playedtime", "admin_showptime", ADMIN_KICK,"<#Player Name> - Details about playedtime.");
	
	showpt = register_cvar("amx_pt_mod","1");
	
	sql = SQL_MakeDbTuple(host,user,pass,db)
	formatex(g_query,511,"CREATE TABLE IF NOT EXISTS `%s` (name VARCHAR(32), playedtime INT, status INT, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)", TABLE_NAME)
	SQL_ThreadQuery(sql,"query",g_query)
	
	// Add new column
	//formatex(g_query, 511, "ALTER TABLE `%s` ADD status INT DEFAULT 0")
	//SQL_ThreadQuery(sql, "query", g_query)
}

public handle_say(id) 
{
	static said[12]
	read_argv(1, said, 11)

	if(equali(said, "/my_time") || equali(said, "my_time") || equali(said, "mytime") || equali(said, "/mytime"))
	{
		static ctime[64], timep;
		
		timep = get_user_time(id, 1) / 60;
		
		#if defined COLORED
		get_time("^1%H^4:^1%M^4:^1%S", ctime, 63);
		#else
		get_time("%H:%M:%S", ctime, 63);
		#endif
		
		switch(get_pcvar_num(showpt))
		{
			case 0: return PLUGIN_HANDLED;
				
			case 1 :
			{
				#if !defined COLORED
				client_print(id, print_chat, "%s You have been playing on the server for: %d minute%s.", PREFIX, timep, timep == 1 ? "" : "s"); 
				client_print(id, print_chat, "%s Your total played time on the server: %d minute%s.", PREFIX, timep+PlayedTime[id], timep+PlayedTime[id] == 1 ? "" : "s");
				client_print(id, print_chat, "%s Current time: %s", PREFIX, ctime);
				#endif
					
				#if defined COLORED
				ColorChat(id, GREEN, "%s ^1Your time statics:", PREFIX)
				ColorChat(id, GREEN, "%s ^1You have played for ^4%d minute%s", PREFIX, timep, timep == 1 ? "" : "s")
				ColorChat(id, GREEN, "%s ^1Your total played time is ^4%d minutes%s", PREFIX, timep + PlayedTime[id], timep + PlayedTime[id] == 1 ? "" : "s")
				ColorChat(id, GREEN, "%s ^1Current time: %s", PREFIX, ctime)
				#endif
			}
			
			case 2 :
			{
				set_hudmessage(255, 50, 50, 0.34, 0.50, 0, 6.0, 4.0, 0.1, 0.2, -1);
				show_hudmessage(id, "[PT] You have been playing on the server for: %d minute%s.^n[PT]Current time: %s", timep, timep == 1 ? "" : "s", ctime);
			}
		}
		
		return PLUGIN_HANDLED;
	}
	
	else if(equal(said,"/top15_time"))
	{
		new data[1];data[0]=id
		
		formatex(g_query,511,"SELECT * FROM `%s` ORDER BY playedtime DESC LIMIT 15", TABLE_NAME)
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
	console_print(id, "[PT] %s have been playing on the server for %d minute%s.",name, timep, timep == 1 ? "" : "s");
	console_print(id, "[PT] %s's total played time on the server %d minute%s.",name, timep+PlayedTime[id], timep+PlayedTime[id] == 1 ? "" : "s"); // new
	console_print(id, "[PT] Current time: %s", ctime);
	console_print(id, "-----------------------------------------------------------------");
	
	return PLUGIN_HANDLED;
}

public client_disconnect(id){
	
	SaveTime(id)
}

/*
public client_infochanged(id)
{
	static szName[32], szOldName[32]
	
	get_user_name(id, szOldName, 31)
	get_user_info(id, "name", szName, 31)
	
	if(!equal(szOldName, szName))
	{
		client_print(id, print_chat, "** Your time has changed because you changed name")
		PlayedTime[id] = get_playedtime(id, 1)
	}
}*/

stock SaveTime(id, iNewName = 0)
{
	new name[32]
	
	switch(iNewName)
	{
		case 0:
		{
			get_user_name(id,name,31)
		}
		
		default:
		{
			get_user_info(id, "name", name, 31)
		}
	}
	
	replace_all(name,31,"'","")
	replace_all(name,31,"^"","")
	
	formatex(g_query,511,"UPDATE `%s` SET playedtime='%d' WHERE name='%s'", TABLE_NAME, PlayedTime[id] + ( get_user_time(id) / 60 ),name)
	SQL_ThreadQuery(sql,"query",g_query)
}

public client_putinserver(id)
{
	PlayedTime[id] = get_playedtime(id)
}

public plugin_end()
{
	SQL_FreeHandle(sql)
}

get_playedtime(id, iNewName = 0)
{
	new err,error[128]
	
	new Handle:connect = SQL_Connect(sql,err,error,127)
	
	if(err)
	{
		log_amx("--> MySQL Connection Failed - [%d][%s]",err,error)
		set_fail_state("mysql connection failed")
	}
	
	new name[32],Handle:query,pt
	switch(iNewName)
	{
			case 0: get_user_name(id,name,31)
			default: get_user_info(id, "name", name, 31)
	}
		
	replace_all(name,31,"'","")
	replace_all(name,31,"^"","")
		
	query = SQL_PrepareQuery(connect,"SELECT playedtime, status FROM %s WHERE name='%s'", TABLE_NAME, name)
	SQL_Execute(query)
		
	if(!SQL_MoreResults(query))
	{
		new iLevel = get_level_id(id)
		formatex(g_query,511,"INSERT INTO `%s` (name , playedtime, status) VALUES('%s', '%d', '%d')", TABLE_NAME, name, get_user_time(id,1)/60, iLevel)
		SQL_ThreadQuery(sql,"query",g_query)
			
		pt = get_user_time(id,1)/60
	}
	
	else
	{
		pt = SQL_ReadResult(query,0)+(get_user_time(id,1)/60)
		
		new iLevel = get_level_id(id)
		
		if( SQL_ReadResult(query, 1) != iLevel )
		{
			formatex(g_query, 511, "UPDATE `%s` SET status = %d WHERE name = '%s'", TABLE_NAME, iLevel, name)
			SQL_ThreadQuery(sql, "query", g_query)
		}
	}
	
	SQL_FreeHandle(connect)
	SQL_FreeHandle(query)
	
	return pt
}

stock get_level_id(id)
{
	new iFlags = get_user_flags(id)
	
	if(!is_user_admin(id))
	{
		return PLAYER_NORMAL
	}
	
	for(new i = 1; i < LEVELS; i++)
	{
		if(iFlags & FLAGS[i])
		{
			return i
		}
	}
	
	return -1
}

public show_top15(FailState, Handle:Query, Error[], Errcode,Data[], DataSize)
{
	static name[32]
	
	new id=Data[0]
	new good,motd[1524],len,place, iStatus
	
	if(!SQL_MoreResults(Query)){
		#if defined COLORCHAT
		ColorChat(id, RED, "%s ^1No Data")
		#else
		client_print(id,print_chat,"[PT] No Data")
		#endif
		return PLUGIN_HANDLED
	}
	
	#if !defined NEW_STYLE
	len = formatex(motd, charsmax(motd),"<body bgcolor=#000000><font color=#FFB000><pre>")
	len += formatex(motd[len], charsmax(motd) - len,"%s %-22.22s %3s %3s^n", "#", "Name", "Time", "Player Status")
	#else
	len = formatex(motd, charsmax(motd),"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{border-style:solid;border-width:1px;border-color:#FFFFFF;font-size:13px}</STYLE><table align=center width=100%% cellpadding=2 cellspacing=0");
	len += formatex(motd[len], charsmax(motd) - len, "<tr align=center bgcolor=#52697B><th width=4%% > # <th width=24%%> Name <th  width=24%%> Minute Played <th width=24%%> Player Status");	
	#endif
	
	while(SQL_MoreResults(Query))
	{
		place++
		
		SQL_ReadResult(Query, 0, name, 32)
		good = SQL_ReadResult(Query,1)
		iStatus = SQL_ReadResult(Query, 2)
		
		replace_all(name, 32,"<","&lt;")
		replace_all(name, 32,">","&gt;")
		
		#if defined NEW_STYLE
		len += formatex(motd[len], charsmax(motd) - len, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %d <td> %s", place, name, good, g_szLevels[iStatus])
		#else
		len += formatex(motd[len], charsmax(motd) - len,"%d %-22.22s %d minute%s %3s^n",place,name,good,good == 1 ? "" : "s", g_szLevels[iStatus])
		#endif
		
		SQL_NextRow(Query)
	}
	
	#if !defined NEW_STYLE
	len += format(motd[len], charsmax(motd) - len,"</body></font></pre>")
	#else
	len += format(motd[len], charsmax(motd) - len, "</table>");
	len += formatex(motd[len], charsmax(motd) - len, "</body>");
	#endif
	
	show_motd(id, motd,"Played-Time Top 15")
	
	return PLUGIN_CONTINUE
}

public query(FailState, Handle:Query, Error[], Errcode)
{
	if(Errcode)
	{
		log_amx(Error)
	}
}

#if defined COLORED
new TeamName[][] = {
    "",
    "TERRORIST",
    "CT",
    "SPECTATOR"
}

stock ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
    if( !get_playersnum() ) return;
    
    new message[256];

    switch(type)
    {
        case NORMAL: // clients scr_concolor cvar color
        {
            message[0] = 0x01;
        }
        case GREEN: // Green
        {
            message[0] = 0x04;
        }
        default: // White, Red, Blue
        {
            message[0] = 0x03;
        }
    }

    vformat(message[1], 251, msg, 4);

    // Make sure message is not longer than 192 character. Will crash the server.
    message[192] = '^0';

    new team, ColorChange, index, MSG_Type;
    
    if(id)
    {
        MSG_Type = MSG_ONE;
        index = id;
    } else {
        index = FindPlayer();
        MSG_Type = MSG_ALL;
    }
    
    team = get_user_team(index);
    ColorChange = ColorSelection(index, MSG_Type, type);

    ShowColorMessage(index, MSG_Type, message);
        
    if(ColorChange)
    {
        Team_Info(index, MSG_Type, TeamName[team]);
    }
}

stock ShowColorMessage(id, type, message[])
{
    static bool:saytext_used;
    static get_user_msgid_saytext;
    if(!saytext_used)
    {
        get_user_msgid_saytext = get_user_msgid("SayText");
        saytext_used = true;
    }
    message_begin(type, get_user_msgid_saytext, _, id);
    write_byte(id)        
    write_string(message);
    message_end();    
}

stock Team_Info(id, type, team[])
{
    static bool:teaminfo_used;
    static get_user_msgid_teaminfo;
    if(!teaminfo_used)
    {
        get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
        teaminfo_used = true;
    }
    message_begin(type, get_user_msgid_teaminfo, _, id);
    write_byte(id);
    write_string(team);
    message_end();

    return 1;
}

stock ColorSelection(index, type, Color:Type)
{
    switch(Type)
    {
        case RED:
        {
            return Team_Info(index, type, TeamName[1]);
        }
        case BLUE:
        {
            return Team_Info(index, type, TeamName[2]);
        }
        case GREY:
        {
            return Team_Info(index, type, TeamName[0]);
        }
    }

    return 0;
}

stock FindPlayer()
{
    new i = -1;

    while(i <= get_maxplayers())
    {
        if(is_user_connected(++i))
            return i;
    }

    return -1;
}
#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
