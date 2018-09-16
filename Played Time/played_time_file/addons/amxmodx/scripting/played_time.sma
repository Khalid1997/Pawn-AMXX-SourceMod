#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Played time"
#define VERSION "1.0"
#define AUTHOR "Khalid :)"

#define SAVE_BY_NAME

#if defined SAVE_BY_NAME
new g_szFile[60] = "addons/amxmodx/data/played_time_names.ini"
#else
new g_szFile[60] = "addons/amxmodx/data/played_time_steamid.ini"
#endif

new const PREFIX[] = "[Played Time]"

new g_iPlayedTime[33], g_iPlayerArrayNum[33]

new g_szTopMotd[1024]

new Array:gTimes
new Array:gCodeArray
new g_iSize
new Trie:gCode

public plugin_init()
{	
	gTimes = ArrayCreate(1, 1)
	gCodeArray = ArrayCreate(36, 1)
	gCode = TrieCreate()
	
	if(gTimes == Invalid_Array || gCode == Invalid_Trie)
	{
		set_fail_state("Failed to create array or trie")
	}
	
	LoadTimesInFile()
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new const szMyTimeCommands[][] = {
		"/mytime",
		"mytime",
		"/my_time",
		"my_time",
		"/my_total_time",
		"my_total_time"
	}
	
	new szCommand[50]
	for(new i; i < sizeof(szMyTimeCommands); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", szMyTimeCommands[i])
		register_clcmd(szCommand, "ShowMyTime")
	}
	
	register_concmd("amx_playedtime", "cmdShowTime")
	
	register_clcmd("say /top15_time", "Top15Time")
	register_clcmd("say top15_time", "Top15Time")
}

public plugin_natives()
{
	register_library("played_time")
	
	register_native("get_user_played_time", "native_get_user_played_time", 1)
	register_native("set_user_played_time", "native_set_user_played_time", 1)
}

// NATIVES
public native_get_user_played_time(id)
{
	if(!is_user_connected(id) || is_user_hltv(id) || !id)
		return -1

	return g_iPlayedTime[id]
}
	
public native_set_user_played_time(id, iNewTime)
{
	if(!is_user_connected(id) || is_user_hltv(id) || !id)
		return 1
	
	g_iPlayedTime[id] = iNewTime
	return 1
}

public plugin_end()
{
	SaveTimesInFile()
}

public cmdShowTime(id, level, cid)
{
	if( !( id && is_user_admin(id) ) )
	{
		console_print(id, "You don't have access to this command :)")
		return PLUGIN_HANDLED
	}
	
	new szName[32]; read_argv(1, szName, charsmax(szName))
	new iPlayer = cmd_target(id, szName, CMDTARGET_NO_BOTS)
	get_user_name(iPlayer, szName, charsmax(szName))
	
	console_print(id, "Player %s has played in the server for %d minutes", szName, (get_user_time(id) / 60))
	console_print(id, "Player %s's total played time is %d", szName, g_iPlayedTime[id])
	
	return PLUGIN_HANDLED
}

#if defined SAVE_BY_NAME
public client_infochanged(id)
{
	if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id))
	{
		return;
	}
	
	static szOldName[32], szNewName[32];
	
	get_user_name(id, szOldName, charsmax(szOldName))
	get_user_info(id, "name", szNewName, charsmax(szNewName))
	
	if(!equal(szOldName, szNewName))
	{
		SaveTime(id)
		g_iPlayedTime[id] = LoadTime(id, szNewName)
	}
}
#endif

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
	{
		return;
	}
	
	new szCode[35]
	
	#if defined SAVE_BY_NAME
	get_user_name(id, szCode, 34)
	#else
	get_user_authid(id, szCode, 34)
	#endif
	
	g_iPlayedTime[id] = LoadTime(id, szCode)
}

public client_disconnect(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
	{
		return;
	}
	
	SaveTime(id)
}

public Top15Time(id)
{
	show_motd(id, g_szTopMotd, "Top15 Played Time")
}

public ShowMyTime(id)
{
	new iTime = get_user_time(id) / 60
	client_print(id, print_chat, "%s You have played for %d minute%s in the server.", PREFIX, iTime, iTime == 1 ? "" : "s")
	client_print(id, print_chat, "%s Your total played time in the server is %d minute%s", PREFIX, iTime + g_iPlayedTime[id], iTime + g_iPlayedTime[id] == 1 ? "" : "s")
}

stock LoadTime(id, szCode[])
{
	if(TrieKeyExists(gCode, szCode))
	{
		new iNum; TrieGetCell(gCode, szCode, iNum)
		g_iPlayerArrayNum[id] = iNum
		return ArrayGetCell(gTimes, iNum)
	}
	
	g_iPlayerArrayNum[id] = ++g_iSize
	
	TrieSetCell(gCode, szCode, g_iPlayerArrayNum[id])
	ArrayPushString(gCodeArray, szCode)
	ArrayPushCell(gTimes, 0)
	return 0
}

stock SaveTime(id)
{
	ArraySetCell(gTimes, g_iPlayerArrayNum[id], g_iPlayedTime[id] + (get_user_time(id) / 60))
	
	g_iPlayedTime[id] = 0; g_iPlayerArrayNum[id] = 0
}

stock LoadTimesInFile()
{
	new f = fopen(g_szFile, "r")
	
	if(!f)
	{
		return;
	}
	
	new iSize = -1
	
	new szLine[35+60], szTime[60], szCode[35]
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		trim(szLine)
		
		if(!szLine[0] || szLine[0] == ';')
		{
			continue;
		}
		
		parse(szLine, szCode, 34, szTime, 59)
		
		remove_quotes(szCode)
		
		TrieSetCell(gCode, szCode, (++iSize))
		ArrayPushCell(gTimes, str_to_num(szTime))
		ArrayPushString(gCodeArray, szCode)
	}
	
	g_iSize = iSize
	fclose(f)
	
	LoadTop()
}

stock SaveTimesInFile()
{
	new f = fopen(g_szFile, "w+")
	
	if(!f)
	{
		return;
	}
	
	new szLine[35+60], szCode[35], iSize = ArraySize(gTimes)
	new i
	
	while(i < iSize)
	{
		server_print("i is %d", i)
		
		if(ArrayGetString(gCodeArray, i, szCode, 34))
		{
			formatex(szLine, charsmax(szLine), "^"%s^" %d^n", szCode, ArrayGetCell(gTimes, i))
			fputs(f, szLine)
			++i
		}
	}
	
	fclose(f)
}

enum _:Data {
	Key[64],
	Value
};

stock LoadTop()
{
	// maximum number of entries to save in array
	static const MAX_ENTRIES = 15
	
	// create our array to hold entries and keep track of its size
	new Array:entries = ArrayCreate(Data);
	new sizeEntries;
	
	// count entries in vault and prepare variables
	new numEntries = ArraySize(gTimes)
	new data[Data], data2[Data]
	
	// iterate through all entries
	for(new timestamp, i = 0; i < numEntries; i++)
	{
		// grab entry data from current position
		//pos = nvault_util_read(vault, pos, data[VD_Key], charsmax(data[VD_Key]), value, charsmax(value), timestamp);
		ArrayGetString(gCodeArray, i, data[Key], charsmax(data[Key]))
		
		// turn value string into integer
		data[Value] = ArrayGetCell(gTimes, i)
		
		// if this is the first entry
		if(sizeEntries == 0)
		{
			// go ahead and add it
			ArrayPushArray(entries, data);
			sizeEntries++;
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
					if(sizeEntries < MAX_ENTRIES)
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
				if(data[Value] >= data2[Value])
				{
					// insert before
					ArrayInsertArrayBefore(entries, timestamp, data);
					
					// if we aren't maxxed out
					if(sizeEntries < MAX_ENTRIES)
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
	
	new iLen, len = charsmax(g_szTopMotd)
	iLen = formatex(g_szTopMotd, len, "<body bgcolor=#000000><font color=#FFB00><pre>")
	iLen += formatex(g_szTopMotd[iLen], len - iLen, "%s. %-22.22s %s^n", "#", "Name", "Time in minutes")
	
	for(new i = 0; i < sizeEntries; i++)
	{
		// grab current entry
		ArrayGetArray(entries, i, data);
		
		// truncate entry key for output
		data[Key][20] = 0;
		data[Key][32] = 0;
		
		replace_all(data[Key], charsmax(data[Key]), "<", "&lt;")
		replace_all(data[Key], charsmax(data[Key]), ">", "&gt;")
		
		iLen += formatex(g_szTopMotd[iLen], len - iLen, "%d. %-22.22s %d^n", (i+1), data[Key], data[Value])
		
	}
	
	// destroy the entry array from cache
	ArrayDestroy(entries);
}
