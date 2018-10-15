#include <amxmodx> 
#include <amxmisc> 

#define PLUGIN "Connect annouce" 
#define VERSION "1.0" 
#define AUTHOR "Khalid :)" 

new Trie:gNames

new const PREFIX[] = "[AMXX]"
new const FILE[] = "addons/amxmodx/configs/connection_announce.ini"
new const LOGFILE[] = "addons/amxmodx/testlog.log"

public plugin_init() { 
	register_plugin(PLUGIN, VERSION, AUTHOR) 
	gNames = TrieCreate() 
	
	ReadFile()
	
	if(!file_exists(LOGFILE))
		write_file(LOGFILE, "; This file is for troubleshooting only.")
	
	register_concmd("amx_reload_connect_file", "CheckAdmin", ADMIN_BAN) 
} 

public client_authorized(id) 
{ 
	new szName[32]; get_user_name(id, szName, charsmax(szName)) 
	log_to_file(LOGFILE, "Got Name: szName")
	if(TrieKeyExists(gNames, szName))
	{
		log_to_file(LOGFILE, "Success")
		set_task(15.0, "Print",_, szName, 31)
	}
} 

public Print(szName[])
	ChatColor(0, "^3%s ^4Player ^3%s ^1connected.", PREFIX, szName)

public CheckAdmin(id, level, cid) 
{ 
	if(!cmd_access(id, level, cid, 1)) 
		return PLUGIN_HANDLED 
	
	TrieClear(gNames) 
	console_print(id, "Successfully reloaded file")
	ReadFile() 
	return PLUGIN_HANDLED 
} 

ReadFile() 
{ 
	if(!file_exists(FILE)) 
	{ 
		write_file(FILE, "; Any line starting with ; is a comment") 
		write_file(FILE, "; FORMAT: (JUST PUT THE NAME)") 
		write_file(FILE, "; Khalid :)") 
	}
	
	new file = fopen(FILE, "r") 
	
	new szLine[40], iLen = charsmax(szLine) 
	while(!feof(file)) 
	{ 
		fgets(file, szLine, iLen)
		replace_all(szLine, iLen, "^n", "")
		log_to_file(LOGFILE, "Line is: %s", szLine)
		
		if(szLine[0] && szLine[0] != ';') 
		{
			log_to_file(LOGFILE, "Line %s		Has been added to the trie", szLine)
			TrieSetCell(gNames, szLine, 1) 
		}
	} 
	
	fclose(file) 
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

public plugin_end()
	TrieDestroy(gNames)
