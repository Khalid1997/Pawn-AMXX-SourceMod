#include <amxmodx>
#include <amxmisc>

new const VERSION[] = "0.1"

enum
{
	SQL = 1,
	VAULT
}

// 1 = SQL
// 2 = nVault
#define SAVETYPE 2

#if SAVETYPE == SQL
	#include <sqlx>
	new Handle:g_hSql
	new gsz_Query[256]
		
	enum
	{
		HOST,
		USER,
		PASS,
		DB
	}
#else
	#include <nvault_util>
	new const SPECIAL_CHAR[2] = "-"
	new gVault
#endif

/* ************ EDIT STARTS HERE ************ */
#define MAX_TIME_LENGTH		25

#if SAVETYPE == SQL
// IF using sql, edit these..
new const gsz_SQLINFO[][] = {
	{ "127.0.0.1" },		// HOST
	{ "root" },		// USER
	{ "" },	// User's password
	{ "amxx" }		// Database Name
}
#endif

new gsz_MyTimeStrings[][] = {
	"/mytime",
	"mytime",
	"my_time",
	"/mytime",
	"my_total_time",
	"mytotaltime"
}

#define COLORED_MESSAGES
/* ************ EDIT ENDS HERE ************** */

#if defined COLORED_MESSAGES
	#include <colorchat>
#endif

new g_iPlayedTime[33], g_iDonateTo[33]
new g_pDonate, g_pConnectMessages

public plugin_init()
{
	register_plugin("Played Time: Extended", VERSION, "Khalid :)")
	
	register_clcmd("say /donate", "Cmd_Donate")
	register_concmd("Type", "DonateAmount")
	
	g_pDonate = register_cvar("pte_allow_donate", "1")
	g_pConnectMessages = register_cvar("pte_show_connect_messages", "1")
	
	new szCommand[40]
	for(new i; i < sizeof(gsz_MyTimeStrings); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", gsz_MyTimeStrings[i])
		register_clcmd(szCommand, "ShowUserTime")
		formatex(szCommand, charsmax(szCommand), "say_team %s", gsz_MyTimeStrings[i])
		register_clcmd(szCommand, "ShowUserTime")
	}

	register_clcmd("say", "HookSaid")
	register_clcmd("say_team", "HookSaid")
	
	register_concmd("amx_show_player_time", "show_players_times", ADMIN_KICK)

	#if SAVETYPE == SQL
	CheckSqlConnection()
	#else
	gVault = nvault_open("played_time")
	#endif
}

public plugin_natives()
{
	register_library("played_time")
	
	register_native("get_user_played_time", "native_get_user_played_time", 1)
	register_native("set_user_played_time", "native_set_user_played_time", 1)
	register_native("pt_get_save_type", "native_get_save_type", 1)
}

public show_players_times(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	new szName[32], iPlayer
	if(read_argc() == 1)
	{
		console_print(id, "Showing players times of all connected players")
		new iPlayers[32], iNum, iPlayer, szName[32]
		get_players(iPlayers, iNum, "h")
	
		for(new i; i < iNum; i++)
		{
			iPlayer = iPlayers[i]
			get_user_name(iPlayer, szName, 31)
		
			console_print(id, "%d. %s %22.22d", i + 1, szName, (g_iPlayedTime[iPlayer] + get_user_time(iPlayer)) / 60)
		}
	}
	
	else
	{
		new szArg[32]
		read_argv(1, szArg, charsmax(szArg))
		
		if(szArg[0] == '@')
		{
			new iPlayers[32], iNum
			if( equali(szArg, "@TERRORIST") || equali(szArg, "@T") || equal(szArg, "@TERR") )
			{
				console_print(id, "Showing players times for team Terrorist")
				get_players(iPlayers, iNum, "eh", "TERRORIST")
			}
				
			else if( equali(szArg, "@COUNTERTERRORIST") || equali(szArg, "@CT") || equali(szArg, "@COUNTER") )
			{
				console_print(id, "Showing players times for team Counter-Terrorist")
				get_players(iPlayers, iNum, "eh", "CT")
			}
				
			else	return console_print(id, "That's not a correct team")
			
			for(new i; i < iNum; i++)
			{
				iPlayer = iPlayers[i]
				get_user_name(iPlayer, szName, 31)
				console_print(id, "%d. %s %22.22d", i + 1, szName, (g_iPlayedTime[iPlayer] + get_user_time(iPlayer)) / 60)
			}
		}
		
		else
		{
			iPlayer = cmd_target(id, szArg, CMDTARGET_OBEY_IMMUNITY)
			if(!iPlayer)
			{
				console_print(id, "Player could not be targetted.")
				return PLUGIN_HANDLED
			}
			
			get_user_name(iPlayer, szName, charsmax(szName))
			console_print(id, "%s total played time is %d", szName, g_iPlayedTime[iPlayer])
		}
	}
	
	return PLUGIN_HANDLED
}
		
public ShowUserTime(id)
{
	new iTime = get_user_time(id)
	new iTotalTime = (g_iPlayedTime[id] + iTime) / 60
	
	iTime /= 60
	
	#if defined COLORED_MESSAGES
	ColorChat(id, GREEN, "[PTE] You have been playing for ^3%d ^4minute%s", iTime, iTime ? "" : "s")
	ColorChat(id, GREEN, "[PTE] Your total played time is ^3%d ^4minute%s", iTotalTime, iTime == 1 ? "" : "s")
	#else
	client_print(id, print_chat, "[PTE] You have been playing for %d minute%s", iTime, iTime == 1 ? "" : "s")
	client_print(id, print_chat, "[PTE] Your total played time is %d minute%s", iTotalTime, iTime == 1 ? "" : "s")
	#endif	
	return PLUGIN_HANDLED
}

public client_infochanged(id)
{
	new szOldName[34], szNewName[32]
	get_user_name(id, szOldName, charsmax(szOldName))
	get_user_info(id, "name", szNewName, charsmax(szNewName))
	
	if(!equal(szOldName, szNewName))
	{
		#if SAVETYPE == SQL
		replace_all(szNewName, charsmax(szNewName), "'", "")
		replace_all(szNewName, charsmax(szNewName), "^"", "")
		
		formatex(gsz_Query, charsmax(gsz_Query), "UPDATE `played_time` SET name = '%s' WHERE name = '%s'", szNewName, szOldName)
		SQL_ThreadQuery(g_hSql, "Query_Handler", gsz_Query)
		#else
		new szAuthId[33]; get_user_authid(id, szAuthId, 32)
		formatex(szOldName, charsmax(szOldName), "%s%s", szAuthId, SPECIAL_CHAR)
		nvault_remove(gVault, szAuthId)
		nvault_set(gVault, szOldName, szNewName)
		#endif
	}
}

public client_putinserver(id)
{
	if( is_user_hltv(id)  || is_user_bot(id) )
		return;

	g_iPlayedTime[id] = get_user_totaltime(id)
	
	if(get_pcvar_num(g_pConnectMessages))
	{
		new szName[32]; get_user_name(id, szName, charsmax(szName))
		new iTime = g_iPlayedTime[id] / 60
		
		#if defined COLORED_MESSAGES
		ColorChat(0, GREEN, "[PTE] Player ^3%s ^4Connected with a total time of ^3%d ^4minute%s", szName, iTime, iTime == 1 ? "" : "s")
		#else
		client_print(0, print_chat, "[PTE] Player %s Connected with a total time of %d minute%s", szName, iTime, iTime == 1 ? "" : "s")
		#endif
	}
}

public client_disconnect(id)
{
	// CZ bots steam id is the same (BOT)
	// Prevent them from saving time
	if( is_user_hltv(id)  || is_user_bot(id) )
		return;
	
	Save(id)
}

Save(id)
{
	new szAuthId[35]; get_user_authid(id, szAuthId, charsmax(szAuthId))
	#if SAVETYPE == SQL
		formatex(gsz_Query, charsmax(gsz_Query), "UPDATE `played_time` SET time = %d WHERE steamid = '%s'", g_iPlayedTime[id] + get_user_time(id), szAuthId)
		SQL_ThreadQuery(g_hSql, "Query_Handler", gsz_Query)
	#else
		new szTime[MAX_TIME_LENGTH]; num_to_str(g_iPlayedTime[id] + get_user_time(id), szTime, charsmax(szTime))
		nvault_remove(gVault, szAuthId)
		nvault_set(gVault, szAuthId, szTime)
	#endif
	
	g_iPlayedTime[id] = 0
}

public Cmd_Donate(id)
{
	if(!get_pcvar_num(g_pDonate))
	{
		#if defined COLORED_MESSAGES
		ColorChat(id, GREEN, "[PTE] Donating is disabled at the moment.")
		#else
		client_print(id, print_chat, "[PTE] Donating is disabled at the moment.")
		#endif
		return PLUGIN_HANDLED
	}
	
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "h")
	
	new szTitle[70]
	formatex(szTitle, charsmax(szTitle), "\rDonate Menu^n\yYour total time is: \w%d \yminute%s^n\rBy Khalid :)^n", g_iPlayedTime[id], g_iPlayedTime[id] == 1 ? "" : "s" )
	new iMenu = menu_create(szTitle, "DonateMenuHandler")
	new szName[32], szInfo[4]
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(iPlayer != id)
		{
			get_user_name(iPlayer, szName, charsmax(szName))
			num_to_str(iPlayer, szInfo, 3)
			menu_additem(iMenu, szName, szInfo)
		}
	}
	
	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public DonateMenuHandler(id, menu, item)
{
	if(!get_pcvar_num(g_pDonate))
	{
		#if defined COLORED_MESSAGES
		ColorChat(id, GREEN, "[PTE] Donating is disabled at the moment.")
		#else
		client_print(id, print_chat, "[PTE] Donating is disabled at the moment.")
		#endif
		return;
	}
	
	if(item < 0)
		return;
	
	new id2, callback, iAccess, szInfo[4]
	menu_item_getinfo(menu, item,iAccess, szInfo, 3, .callback = callback)
	
	id2 = str_to_num(szInfo)
	menu_destroy(menu)
	
	if(!is_user_connected(id2))
	{
		#if defined COLORED_MESSAGES
		ColorChat(id, GREEN, "[PTE] You can't donate to a disconnected player..")
		#else
		client_print(id, print_chat, "[PTE] You can't donate to a disconnected player..")
		#endif
		return;
	}
	
	g_iDonateTo[id] = id2
	new szName[32]; get_user_name(id2, szName, 31)
	
	client_cmd(id, "messagemode ^"Type the amount that you want to donate^"")
	#if defined COLORED_MESSAGES
	ColorChat(id, GREEN, "*** Type the amount that you want to donate to ^3%s", szName)
	#else
	client_print(id, print_chat, "*** Type the amount that you want to donate to %s", szName)
	#endif
}

public DonateAmount(id)
{
	if(!get_pcvar_num(g_pDonate))
	{
		#if defined COLORED_MESSAGES
		ColorChat(id, GREEN, "[PTE] Donating is disabled at the moment.")
		#else
		client_print(id, print_chat, "[PTE] Donating is disabled at the moment.")
		#endif
		return PLUGIN_HANDLED
	}

	
	new id2 = g_iDonateTo[id]
	if(!id2 || !is_user_connected(id2))
		return PLUGIN_HANDLED
	
	new szAmount[50], iAmount
	read_argv(read_argc() - 1, szAmount, charsmax(szAmount))
	
	//replace(szAmount, charsmax(szAmount), "the", "")
	new iTime = g_iPlayedTime[id]
	
	if( is_str_num(szAmount) )
	{
		iAmount = (str_to_num(szAmount) * 60)
		if(iAmount < 0)
		{
			client_print(id, print_center, "You can't donate that")
			return PLUGIN_HANDLED
		}
		
		if(iAmount > iTime)
			iAmount = iTime
	}
	
	else if(szAmount[0] == '*' && szAmount[1] == EOS)
		iAmount = iTime
		
	else
	{
		client_print(id, print_center, "You can't donate that")
		return PLUGIN_HANDLED
	}
	
	if( g_iPlayedTime[id] - iAmount < 0 )
		iAmount -= g_iPlayedTime[id]
	
	g_iPlayedTime[id] -= iAmount
	g_iPlayedTime[id2] += iAmount
	
	new szName[32], szName2[32]
	get_user_name(id, szName, 31); get_user_name(id2, szName2, 31)
	
	#if defined COLORED_MESSAGES
	ColorChat(0, GREEN, "[PTE] Player ^3%s ^4donated to ^3%s ^1%d ^4minutes", szName, szName2, iAmount / 60)
	#else
	client_print(0, print_chat, "[PTE] Played %s donated to %s %d minutes", szName, szName2, iAmount / 60)
	#endif
	
	return PLUGIN_HANDLED
}

public HookSaid(id)
{
	new szSaid[25]
	read_argv(1, szSaid, charsmax(szSaid))
	
	if( containi(szSaid, "/top") != -1 && containi(szSaid, "_time") != -1 )
	{
		replace(szSaid, charsmax(szSaid), "/top", ""); replace(szSaid, charsmax(szSaid), "_time", "")
		
		if(!is_str_num(szSaid))		// If it has more other words than /top*_time
			return PLUGIN_CONTINUE	// stop plugin and continue to show the words
			
		new iNum = str_to_num(szSaid)
		Top(id, iNum)
	}
	
	return PLUGIN_CONTINUE
}

#if SAVETYPE == SQL
CheckSqlConnection()
{
	g_hSql = SQL_MakeDbTuple(gsz_SQLINFO[HOST], gsz_SQLINFO[USER], gsz_SQLINFO[PASS], gsz_SQLINFO[DB])
	SQL_ThreadQuery(g_hSql, "Query_Handler", "CREATE TABLE IF NOT EXISTS `played_time` (steamid VARCHAR(33), name VARCHAR(32), time INT)")
}
#endif

Top(id, NUM)
{
	if(NUM < 0)
		NUM *= -1
	
	new iSize
	#if SAVETYPE == SQL
	new iErrorCode, szError[50]
	new Handle:iConnection = SQL_Connect(g_hSql, iErrorCode, szError, charsmax(szError))
	new Handle:iQuery = SQL_PrepareQuery(iConnection, "SELECT COUNT(*) FROM `played_time`")
	
	if(!SQL_Execute(iQuery))
		log_amx(szError)
	
	if(!SQL_MoreResults(iQuery))
	{
		#if defined COLORED_MESSAGES
		ColorChat(id, GREEN, "[PTE] No etnries yet")
		#else
		client_print(id, print_chat, "[PTE] No entries yet")
		#endif
		return;
	}
	
	iSize = SQL_ReadResult(iQuery, 0)
	
	SQL_FreeHandle(iConnection); SQL_FreeHandle(iQuery)
	#else
	new Vault2 = nvault_util_open("played_time")
	iSize = nvault_util_count(Vault2)
	
	if(!iSize)
	{
		#if defined COLORED_MESSAGES
		ColorChat(id, GREEN, "[PTE] No etnries yet")
		#else
		client_print(id, print_chat, "[PTE] No entries yet")
		#endif
		nvault_util_close(Vault2)
		return;
	}
	
	nvault_util_close(Vault2)
	
	#endif
	
	if( NUM > iSize )
		NUM = iSize
	
	#if SAVETYPE == SQL
	new data[3]
	data[0] = id
	data[1] = NUM
	formatex(gsz_Query, charsmax(gsz_Query), "SELECT * FROM played_time ORDER BY time DESC LIMIT %d", NUM)
	SQL_ThreadQuery(g_hSql, "FormatTop", gsz_Query, data, 1)
	#else
	FormatTop(id, NUM, iSize)
	#endif
}

#if SAVETYPE == SQL
public FormatTop(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("[SQL ERROR] Error on query: %s", Error)
		return;
	}
	
	new szMotd[1024], iLen, szName[32], iPlace, iTime
	iLen = formatex(szMotd, charsmax(szMotd), "<body bgcolor=#000000><font color=#FFB00><pre>")
	iLen += format(szMotd[iLen], charsmax(szMotd) - iLen,"%s %-22.22s %3s^n", "#", "Name", "Time in minutes")
	
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query, 1, szName, charsmax(szName))
		iTime = SQL_ReadResult(Query, 2)

		replace_all(szName, charsmax(szName), "<", "&lt;")
		replace_all(szName, charsmax(szName), ">", "&gt;")

		iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "%d %-22.22s %d^n", ++iPlace, szName, iTime / 60)
		SQL_NextRow(Query)
	}
	
	iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "</pre></font></body>")
	
	new szTitle[25]
	formatex(szTitle, charsmax(szTitle), "Time Top%d", Data[1])
	show_motd(Data[0], szMotd, szTitle)
}
#else
public FormatTop(id, iNum, const iSize)	// TOP Motd.... TY Exolent!
{	
	enum _:VaultData
	{
		VD_Key[33],
		VD_Value,
		VD_szName[33]
	};
	
	new Vault2 = nvault_util_open("played_time")
	// create our array to hold entries and keep track of its size
	new Array:entries = ArrayCreate(VaultData);
	new sizeEntries
	
	// count entries in vault and prepare variables
	new data[VaultData], value[MAX_TIME_LENGTH], data2[VaultData]
	// iterate through all entries
	for(new i = 0, pos, timestamp; i < iSize; i++)
	{
		// grab entry data from current position
		pos = nvault_util_read(Vault2, pos, data[VD_Key], charsmax(data[VD_Key]), value, charsmax(value), timestamp);
		
		/*for(new i; i < sizeof(data[VD_Key]); i++)
			if(!data[VD_Key][i])
				data[VD_Key][i] = EOS*/
	
		if(contain(data[VD_Key], SPECIAL_CHAR) != -1)
			continue;
		
		else
		{
			formatex(data[VD_szName], charsmax(data[VD_szName]), "%s%s", data[VD_Key], SPECIAL_CHAR)
			nvault_get(gVault, data[VD_szName], data[VD_szName], charsmax(data[VD_szName]))
		}

		// turn value string into integer
		data[VD_Value] = str_to_num(value);
        
		// if this is the first entry
		if(sizeEntries == 0)
		{
			// go ahead and add it
			ArrayPushArray(entries, data);
			sizeEntries++;
			continue;
		}
		
		else
		{
			// loop through other entries to see where this one should be placed (sorted from HIGH->LOW)
			for(timestamp = 0; timestamp <= sizeEntries; timestamp++)
			{
				// if we looped through all entries without finding a place
				if(timestamp == sizeEntries)
				{
					// this entry value is too low to fit before any others
					// if we have room at the end of the array
					if(sizeEntries < iNum)
					{
						// add it to the end
						ArrayPushArray(entries, data);
						sizeEntries++;
					}
                    
					// don't continue with code below
					break;
				}

                
				// grab current entry to compare it with
				ArrayGetArray(entries, timestamp, data2);
                
				// if this new entry should be placed before the compared entry
				if(data[VD_Value] >= data2[VD_Value])
				{
					// insert before
					ArrayInsertArrayBefore(entries, timestamp, data);
                    
					// if we aren't maxxed out
					if(sizeEntries < iNum)
					{
						// increase entry size
						sizeEntries++;
					} 
					else 
					{
						// delete the last entry to keep the size at maximum
						ArrayDeleteItem(entries, sizeEntries);
					}
                    
					break;
				}
			}
		}
	}
	
	new szMotd[1024], iLen, len = charsmax(szMotd)
	iLen = formatex(szMotd, len, "<body bgcolor=#000000><font color=#FFB00><pre>")
	iLen += formatex(szMotd[iLen], len - iLen, "%s. %-22.22s %s^n", "#", "Name", "Time in minutes")
	
	new i
	for(i = 0; i < sizeEntries; i++)
	{
		// grab current entry
		ArrayGetArray(entries, i, data);
        
		// truncate entry key for output
		data[VD_Key][32] = 0;
		data[VD_szName][32] = 0
		
		replace_all(data[VD_szName], charsmax(data[VD_szName]), "<", "&lt;")
		replace_all(data[VD_szName], charsmax(data[VD_szName]), ">", "&gt;")
        
		// display data
		iLen += formatex(szMotd[iLen], len - iLen, "%d. %-22.22s %d^n", (i+1), data[VD_szName], data[VD_Value] / 60)
	}
    
	// destroy the entry array from cache
	ArrayDestroy(entries);
	nvault_util_close(Vault2)
	
	iLen += formatex(szMotd[iLen], len - iLen, "</pre></font></body>")
	new szTitle[50]; formatex(szTitle, charsmax(szTitle), "Time Top%d", i)
	show_motd(id, szMotd, szTitle)
	
}
#endif

get_user_totaltime(id)
{
	new iNum, szSavedName[32]
	new szName[32]; get_user_name(id, szName, 31)
	new szAuthId[33]; get_user_authid(id, szAuthId, charsmax(szAuthId))
	#if SAVETYPE == SQL
	new iErrorCode, szError[50]
	new Handle:hConnection = SQL_Connect(g_hSql, iErrorCode, szError, charsmax(szError))
	new Handle:hQuery = SQL_PrepareQuery(hConnection, "SELECT * FROM `played_time` WHERE steamid='%s'", szAuthId)
	
	SQL_Execute(hQuery)

	if(!SQL_MoreResults(hQuery))
	{
		formatex(gsz_Query, charsmax(gsz_Query), "INSERT INTO `played_time` VALUES ('%s', '%s', %d)", szAuthId, szName, 0)
		SQL_ThreadQuery(g_hSql, "Query_Handler", gsz_Query)
		
		SQL_FreeHandle(hConnection); SQL_FreeHandle(hQuery)
		return iNum
	}
	
	SQL_ReadResult(hQuery, 2, szSavedName, 31)
	replace_all(szSavedName, charsmax(szSavedName), "'", "")
	replace_all(szSavedName, charsmax(szSavedName), "^"", "")
	
	if(!equal(szName, szSavedName))
		SQL_ThreadQuery(g_hSql, "Query_Handler", "UPDATE `played_time` SET name = '%s' WHERE name = '%s'")
	
	iNum = SQL_ReadResult(hQuery, 2)
	SQL_FreeHandle(hConnection); SQL_FreeHandle(hQuery)
	
	#else
	if( !( iNum =  nvault_get(gVault, szAuthId) ) )
	{
		nvault_set(gVault, szAuthId, "0")
		format(szAuthId, charsmax(szAuthId), "%s%s", szAuthId, SPECIAL_CHAR)
		nvault_set(gVault, szAuthId, szName)
		return 0
	}
	
	format(szAuthId, charsmax(szAuthId), "%s%s", szAuthId, SPECIAL_CHAR)
	nvault_get(gVault, szAuthId, szSavedName)
	if(!equal(szName, szSavedName))
	{
		nvault_remove(gVault, szAuthId)
		nvault_set(gVault, szAuthId, szName)
	}
	#endif
	
	return iNum
}

#if SAVETYPE == SQL
public Query_Handler(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if(FailState < 0)
		return log_amx("%s", FailState == TQUERY_CONNECT_FAILED ? "Could not connect to SQL database." : "Query failed")
   
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	return -1	// Any number so we can get off the warning ...
}
#endif

// NATIVES
public native_get_user_played_time(const id)
{
	if(!is_user_connected(id) || is_user_hltv(id) || !id)
		return -1

	return g_iPlayedTime[id]
}
	
public native_set_user_played_time(const id, iNewTime)
{
	if(!is_user_connected(id) || is_user_hltv(id) || !id)
		return 1
	
	g_iPlayedTime[id] = iNewTime
	return 1
}

public native_get_save_type()
	return SAVETYPE

public plugin_end()
{
	#if SAVETYPE == SQL
	SQL_FreeHandle(g_hSql)
	#else
	nvault_close(gVault)
	#endif
}
