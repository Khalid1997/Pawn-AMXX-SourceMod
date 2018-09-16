#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Tags"
#define VERSION "1.0"
#define AUTHOR "Khalid"

#define MAX_TAG_CHARACTERS	20

#define USE_STEAMID

new Trie:gTrie
new g_szTag[33][MAX_TAG_CHARACTERS + 1]
new const FILE[] = "addons/amxmodx/configs/tags.ini"
new iAllChat, iProChat

enum Action
{
	ADD = 1,
	REPLACE,
	REMOVE,
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say", "HookSaid")
	
	gTrie = TrieCreate()
	
	ReadFile()
	
	register_concmd("amx_reload_tags", "AdminReloadTags", ADMIN_RCON)
	register_concmd("amx_add_tag", "AdminAddTag", ADMIN_RCON, "<name> <tag> - Adds a tag for a player")
	register_concmd("amx_change_tag", "AdminChangeTag", ADMIN_RCON, "<name> <newtag> - Changes the current tag of a player^n**If Player doesn't have tag, it will add a new tag for him")
	register_concmd("amx_remove_tag", "AdminRemoveTag", ADMIN_RCON, "<name> - Removes the current tag of a player")
	
	iAllChat = find_plugin_byfile("allchat.amxx", 1) == INVALID_PLUGIN_ID ? 0 : 1
	iProChat = find_plugin_byfile("prochat_noviewer.amxx", 1) == INVALID_PLUGIN_ID ? (find_plugin_byfile("prochat.amxx", 1) == INVALID_PLUGIN_ID ? 0 : 1) : 1
	
	if(iAllChat)
	{
		server_print("Detected Allchat plugin, changing method of tags!")
	}
	
	if(iProChat)
	{
		server_print("Detected iProChat plugin! Changing method of tags")
	}
}

public client_putinserver(id)
{
	new szAccessCode[35]; 
	
	#if defined USE_STEAMID
	get_user_authid(id, szAccessCode, charsmax(szAccessCode))
	#else
	get_user_name(id, szAccessCode, charsmax(szAccessCode))
	#endif
	
	if(TrieKeyExists(gTrie, szAccessCode))
		TrieGetString(gTrie, szAccessCode, g_szTag[id], charsmax(g_szTag[]))
}

public client_disconnect(id)
	g_szTag[id][0] = EOS

public AdminRemoveTag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
	{
		return PLUGIN_HANDLED
	}
	
	static szName[32], iPlayer
	
	read_argv(1, szName, charsmax(szName))
	
	if( ! ( iPlayer = cmd_target(id, szName, CMDTARGET_ALLOW_SELF) ) )
	{
		return PLUGIN_HANDLED
	}
	
	if(!g_szTag[iPlayer][0])
	{
		console_print(id, "Player %s already doesn't have a tag to be removed", szName)
		return PLUGIN_HANDLED
	}
	
	get_user_name(iPlayer, szName, charsmax(szName))
	new iNum
	
#if defined USE_STEAMID
	new szAuthId[35]; get_user_authid(iPlayer, szAuthId, charsmax(szAuthId))
	iNum = FileAction(REMOVE, szAuthId)
	
	TrieDeleteKey(gTrie, szAuthId)
#else
	iNum = FileAction(REMOVE, szName)
	TrieDeleteKey(gTrie, szName)
#endif
	
	if(!iNum)
	{
		console_print(id, "Failed to remove player %s tag", szName)
	}
	
	g_szTag[iPlayer][0] = EOS
	
	console_print(id, "Successfully removed player %s tag", szName)
	return PLUGIN_HANDLED
}

public AdminChangeTag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
	{
		return PLUGIN_HANDLED
	}
	
	static szName[32], szTag[MAX_TAG_CHARACTERS + 1]
	read_argv(1, szName, charsmax(szName))
	read_argv(2, szTag, charsmax(szTag))
	
	new iPlayer
	
	if(! ( iPlayer = cmd_target(id, szName, CMDTARGET_ALLOW_SELF) ) )
	{
		return PLUGIN_HANDLED
	}
	
	new iNum
	get_user_name(iPlayer, szName, charsmax(szName))
	
#if defined USE_STEAMID
	static szAuthId[35]; get_user_authid(iPlayer, szAuthId, charsmax(szAuthId))
	TrieSetString(gTrie, szAuthId, szTag)
	
	iNum = FileAction(REPLACE, szAuthId, szTag, szName)
#else
	TrieSetString(gTrie, szName, szTag)
	iNum =FileAction(REPLACE, szName, szName, szName)
#endif
	
	if(!iNum)
	{
		console_print(id, "Failed to change player %s tag to %s", szName, szTag)
		return PLUGIN_HANDLED
	}

	copy(g_szTag[iPlayer], charsmax(g_szTag[]), szTag)
	
	console_print(id, "Successfully changed player %s tag to %s", szName, szTag)
	
	return PLUGIN_HANDLED
}

public AdminAddTag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
		
	new szName[32], iPlayer, szTag[MAX_TAG_CHARACTERS + 1]
	read_argv(1, szName, 31); read_argv(2, szTag, charsmax(szTag))
	
	if( !( iPlayer = cmd_target(id, szName, CMDTARGET_ALLOW_SELF) ) )
	{
		return PLUGIN_HANDLED
	}
	
	if(g_szTag[iPlayer][0])
	{
		console_print(id, "Player already have a tag")
		return PLUGIN_HANDLED
	}
	
	#if defined USE_STEAMID
	new szAuthId[35]
	get_user_authid(iPlayer, szAuthId, charsmax(szAuthId))
	#endif
	
	get_user_name(iPlayer, szName, charsmax(szName))
	
	#if defined USE_STEAMID
	FileAction(ADD, szAuthId, szTag, szName)
	#else
	FileAction(ADD, szName, szTag, szName)
	#endif
	
	copy(g_szTag[iPlayer], charsmax(g_szTag[]), szTag)
	
	console_print(id, "Successfully added tag %s for player %s", g_szTag[iPlayer], szName)
	return PLUGIN_HANDLED
}

public AdminReloadTags(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	for(new i; i < sizeof(g_szTag); i++)
	{
		setc(g_szTag[i], charsmax(g_szTag[]), 0)
	}
	
	console_print(id, "Successfully reloaded file")
	
	TrieClear(gTrie)
	ReadFile()
	
	new iPlayers[32], iNum, iPlayer
	
	new szAccessCode[35]
	
	get_players(iPlayers, iNum, "ch")
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		#if defined USE_STEAMID
		get_user_authid(iPlayer, szAccessCode, charsmax(szAccessCode))
		#else
		get_user_name(iPlayer, szAccessCode, charsmax(szAccessCode))
		#endif
		
		if(TrieKeyExists(gTrie, szAccessCode))
		{
			TrieGetString(gTrie, szAccessCode, g_szTag[iPlayer], charsmax(g_szTag[]))
		}
	}
	
	return PLUGIN_HANDLED
}

ReadFile()
{
	new szLine[100]
	if(!file_exists(FILE))
	{
		WriteFile()
		return;
	}
	
	new f = fopen(FILE, "r")
	new szAccessCode[35], szTag[MAX_TAG_CHARACTERS + 1], szDump[2]
	
	while(!feof(f))
	{
		fgets(f, szLine, 99)
		
		replace(szLine, charsmax(szLine), "^n", "")
		
		if(!szLine[0] || szLine[0] == ';')
			continue;
		
		parse(szLine, szAccessCode, charsmax(szAccessCode), szTag, charsmax(szTag), szDump, charsmax(szDump))
		
		remove_quotes(szAccessCode)
		remove_quotes(szTag)
		
		if(TrieKeyExists(gTrie, szAccessCode))
		{
			#if defined USE_STEAMID
			log_amx("Failed to add Tag for player with SteamID: '%s' as he already has a tag.", szAccessCode)
			#else
			log_amx("Failed to add tag for player with the name '%s' as he already has a tag.", szAccessCode)
			#endif
			continue;
		}
		
		TrieSetString(gTrie, szAccessCode, szTag)
	}
	
	fclose(f)
}

FileAction(Action:iAction = ADD, szKey[] = "", szTag[] = "", szName[] = "")
{
	static szLine[35 + MAX_TAG_CHARACTERS + 1], szFKey[35], i
	
	new f = fopen(FILE, iAction != ADD ? "r+" : "a" )

	if(!f)
	{
		fclose(f)
		WriteFile()
		
		static const ADD_2 = ( (1<<_:ADD) | (1<<_:REPLACE) )
		if( (1<<_:iAction) & ADD_2)
		{
			formatex(szLine, charsmax(szLine), "^"%s^" ^"%s^" ; %s^n", szKey, szTag, szName)
			write_file(FILE, szLine)
		}
		
		return 1
	}
	
	if(iAction == ADD)
	{
		fprintf(f,  "^"%s^" ^"%s^" ; %s^n", szKey, szTag, szName)
		fclose(f)
		
		return 1
	}
	
	new iRet
	i = -1
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		i++
		replace(szLine, charsmax(szLine), "^n", "")
		
		if(!szLine[0] || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		parse(szLine, szFKey, charsmax(szFKey), szLine, charsmax(szLine))
		
		if(equal(szFKey, szKey))
		{
			switch(iAction)
			{
				case (REMOVE):
				{
					//formatex(szLine, charsmax(szLine)
					write_file(FILE, "", i)
					iRet = 1
				}
				
				case (REPLACE):
				{
					//fprintf(f, "^"%s^" ^"%s^"^n", szKey, szTag)
					formatex(szLine, charsmax(szLine), "^"%s^" ^"%s^" ; %s^n", szKey, szTag, szName)
					write_file(FILE, szLine, i)
					iRet = 1
				}
			}
			break;
		}
	}
	
	if(!iRet)
	{
		switch(iAction)
		{
			case REMOVE:
			{
				iRet = 1
			}
			
			case REPLACE:
			{
				fseek(f, SEEK_END, 0)
				fprintf(f, "^"%s^" ^"%s^"^n", szKey, szTag)
			}
		}
	}
	
	fclose(f)
	return iRet
}

WriteFile()
{
	new f = fopen(FILE, "a+")
	fputs(f, "; Tags File -> By Khalid :)^n")
	fputs(f, "; Any line starting with ; is a comment^n")
	fputs(f, "; How to put tags?^n")
	
	#if defined USE_STEAMID
	//write_file(FILE, "; ^"SteamID^"	^"Tag^"")
	fputs(f, "; ^"SteamID^" ^"Tag^"^n")
	#else
	fputs(f, "; ^"Name^" ^"Tag^"^n")
	#endif
		
	static szLine[60]
	
	if(!szLine[0])
		formatex(szLine, charsmax(szLine), "; Tags cannot exceed more than %d characters.^n", MAX_TAG_CHARACTERS)
		
	fputs(f, szLine)
	fputs(f, "; If you want more, edit the sma at line 8^n")
	
	fclose(f)
}
	
public HookSaid(id)
{
	if(!g_szTag[id][0])
		return PLUGIN_CONTINUE
	
	static szMessage[191], szLastFormat[200], szName[32]
	new iAlive
	
	read_argv(1, szMessage, charsmax(szMessage))
	
	if(!szMessage[0])
		return PLUGIN_CONTINUE
	
	get_user_name(id, szName, 31)
	formatex(szLastFormat, charsmax(szLastFormat), "%s^4%s ^3%s %s: ^1%s", ( ( iAlive = is_user_alive(id) ) ? "" : ( get_user_team(id) == 3 ? "^1*SPEC* " : "^1*DEAD* ") ), g_szTag[id], szName, iProChat ? "^4" : "^1", szMessage)

	Print(id, szLastFormat, !iAllChat ? ( iAlive ? "ach" : "bch" ) : "ch" )
	
	return PLUGIN_HANDLED_MAIN
}

Print(id, Message[], szFlags[] = "")
{
	static SayText
	
	if(!SayText)
		SayText = get_user_msgid("SayText")
		
	new players[32], iNum
	
	get_players(players, iNum, szFlags)//iAlive ? "ach" /* Skip Dead */ : "bch" /* Skip Alive */)

	for(new i; i < iNum; i++)
	{
		message_begin(MSG_ONE, SayText,_, players[i])
		write_byte(id)
		write_string(Message)
		message_end()
	}
}
