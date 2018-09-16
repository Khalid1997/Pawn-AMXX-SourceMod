#include <amxmodx>
#include <amxmisc>
#include <colorchat>

#define PLUGIN "Tags"
#define VERSION "1.0"
#define AUTHOR "Khalid"

new Trie:gTrie

new const FILE[] = "addons/amxmodx/configs/tags.ini"

#define MAX_TAG_CHARACTERS	20

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say", "HookSaid")
	
	gTrie = TrieCreate()
	
	ReadFile()
	
	register_concmd("amx_reload_tags", "AdminReloadTags", ADMIN_RCON)
	register_concmd("amx_add_tag", "AdminAddTag", ADMIN_RCON, "<name> <tag> - Adds a tag for a player")
}

public AdminAddTag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
		
	new szName[32], szTag[13], iPlayer
	read_argv(1, szName, 31); read_argv(2, szTag, 12)
	
	if( !( iPlayer = cmd_target(id, szName, CMDTARGET_ALLOW_SELF) ) )
	{
		console_print(id, "Player must be connected")
		return PLUGIN_HANDLED
	}
	
	get_user_name(iPlayer, szName, 31)
	
	new f = fopen(FILE, "w")
	fseek(f, 0, SEEK_END)
	
	fprintf(f, "^"%s^" ^"%s^"", szName, szTag)
	fclose(f)
	
	TrieSetString(gTrie, szName, szTag)
	
	
	console_print(id, "Successfully added tag %s for player %s", szTag, szName)
	return PLUGIN_HANDLED
}

public AdminReloadTags(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	TrieClear(gTrie)
	
	console_print(id, "Successfully reloaded file")
	ReadFile()
	
	return PLUGIN_HANDLED
}

ReadFile()
{
	new szLine[100]
	if(!file_exists(FILE))
	{
		write_file(FILE, "; Tags File -> By Khalid :)")
		write_file(FILE, "; Any line starting with ; is a comment")
		write_file(FILE, "; How to put tags?")
		write_file(FILE, "; ^"NAME^"	^"TAG^"")
		formatex(szLine, charsmax(szLine), "; TAG CAN BE ONLY %d CHARACTERS!", MAX_TAG_CHARACTERS)
		write_file(FILE, szLine)
		
		return;
	}
	
	new f = fopen(FILE, "r")
	new szName[32], szTag[MAX_TAG_CHARACTERS + 1]
	
	while(!feof(f))
	{
		fgets(f, szLine, 99)
		
		if(!szLine[0] || szLine[0] == ';')
			continue;
		
		strbreak(szLine, szName, 31, szTag, charsmax(szTag))
		
		remove_quotes(szName)
		remove_quotes(szTag)
		
		TrieSetString(gTrie, szName, szTag)
	}
	
	fclose(f)
}

public HookSaid(id)
{
	new szName[32]; get_user_name(id, szName, charsmax(szName))
	
	if(!TrieKeyExists(gTrie, szName))
		return PLUGIN_CONTINUE
	
	static szMessage[200]
	new szLastFormat[300]
	read_argv(1, szMessage, 300)
	
	new iAlive, Spec
	
	if(is_user_alive(id))
		iAlive = 1
		
	if(get_user_team(id) == 3)
		Spec = 1
	
	new szTag[MAX_TAG_CHARACTERS + 1]
	
	TrieGetString(gTrie, szName, szTag, charsmax(szTag))
	
	formatex(szLastFormat, charsmax(szLastFormat), "%s^4%s ^3%s ^1: %s", ( iAlive ? "" : ( Spec ? "^1*SPEC* " : "^1*DEAD ") ), szTag, szName, szMessage)

	Print(id, szLastFormat, iAlive)
	
	return PLUGIN_HANDLED_MAIN
}

Print(id, Message[], iAlive)
{
	static SayText
	
	if(!SayText)
		SayText = get_user_msgid("SayText")
		
	new players[32], iNum
	
	get_players(players, iNum, iAlive ? "ach" : "bch")
	
	for(new i; i < iNum; i++)
	{
		message_begin(MSG_ONE, SayText,_, players[i])
		write_byte(id)
		write_string(Message)
		message_end()
	}
}
		
		
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
