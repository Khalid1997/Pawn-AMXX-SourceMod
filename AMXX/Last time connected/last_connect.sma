#include <amxmodx>
#include <amxmisc>

#define VERSION "1.0"

new Trie:gAdmins

new const FILE[] = "addons/amxmodx/data/connections.ini"

enum _:DATA
{
	NAME[32],
	STEAMID[35],
	LAST_CONNECT[50]
}

public plugin_init()
{
	register_plugin("Admin Last Connection Time", VERSION, "Khalid :)")
	register_concmd("amx_adminconnection", "admin_cmd", ADMIN_RCON)
	
	gAdmins = TrieCreate()
	LoadAddedAdmins()
}

public client_putinserver(id)
{
	if(is_user_admin(id))
		update_time(id)
}

public admin_cmd(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	CheckFile()
	
	console_print(id, "# %-25.25s %-25.25s %s", "Name", "SteamId", "Last Connect Time")
	
	new f = fopen(FILE, "r")
	
	if(!f)
		return console_print(id, "Couldn't open file")
	
	new szLine[150], Data[DATA], i
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		replace(szLine , charsmax(szLine), "^n", "")

		if(!szLine[0] || szLine[0] == ';')
			continue;
			
		parse(szLine, Data[STEAMID], charsmax(Data[STEAMID]), Data[NAME], charsmax(Data[NAME]), Data[LAST_CONNECT], charsmax(Data[LAST_CONNECT]) )
		replace_all(Data[STEAMID], charsmax(Data[STEAMID]), "^"", "")
		replace_all(Data[NAME], charsmax(Data[NAME]), "^"", "")
			
		format_time(Data[LAST_CONNECT], charsmax(Data[LAST_CONNECT]), "%m/%d/%Y - %H:%M:%S", str_to_num(Data[LAST_CONNECT]))
		
		console_print(id, "%d %-25.25s %-25.25s %s", ++i, Data[NAME], Data[STEAMID], Data[LAST_CONNECT])
	}
	
	fclose(f)
	
	return PLUGIN_HANDLED
}

CheckFile()
	if(!file_exists(FILE))
		write_file(FILE, "")
		
LoadAddedAdmins()
{
	CheckFile()
	
	new f = fopen(FILE, "r")
	
	new szLine[150], szSteamId[35], szLeft[3]
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		replace(szLine, charsmax(szLine), "^n", "")

		if(!szLine[0] || szLine[0] == ';')
			continue;
			
		parse(szLine, szSteamId, charsmax(szSteamId), szLeft, charsmax(szLeft))
		
		remove_quotes(szSteamId)

		TrieSetCell(gAdmins, szSteamId, 1)
	}
	
	fclose(f)
}
		
update_time(id)
{
	CheckFile()
	
	static szAuthId[35], szName[32]
	static szAuthId2[35], szName2[32], szTimeStamp[20], szLeft[60]
	get_user_authid(id, szAuthId, charsmax(szAuthId))
	get_user_name(id, szName, 31)
	
	new f, szLine[150], i = -1
	if(TrieKeyExists(gAdmins, szAuthId))
	{
		f = fopen(FILE, "r+")
		
		while(!feof(f))
		{
			++i
			
			fgets(f, szLine, charsmax(szLine))
			replace_all(szLine, charsmax(szLine), "^n", "")
			
			if(!szLine[0] || szLine[0] == ';')
				continue;

			parse(szLine, szAuthId2, charsmax(szAuthId), szLeft, charsmax(szLeft))
			
			remove_quotes(szAuthId2)

			if(equal(szAuthId2, szAuthId))
			{
				parse(szLeft, charsmax(szLeft), szName2, charsmax(szName2), szTimeStamp, charsmax(szTimeStamp))
				remove_quotes(szName2)
				
				formatex(szLine, charsmax(szLine), "^"%s^" ^"%s^" %d^n", szAuthId, szName, get_systime())
				
				write_file(FILE, szLine, i)
				break;
			}	
		}
		
		fclose(f)
		return;
		
	}
	
	TrieSetCell(gAdmins, szAuthId, 1)
	
	CheckFile()
	formatex(szLine, charsmax(szLine), "^"%s^" ^"%s^" %d^n", szAuthId, szName, get_systime())
	
	f = fopen(FILE, "a")
	fputs(f, szLine)
	
	fclose(f)
}
