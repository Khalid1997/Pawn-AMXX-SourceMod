#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Login"
#define VERSION "1.0"
#define AUTHOR "Khalid"

new const DEFAULT_MSG[] = "***** !t%rank% !gLogin !t%name% !gCONNECTED !n*****"

new Trie:g_hTrie
new Array:g_hFlagsArray

new g_iArraySize

new g_szMsg[100]
new g_iMsgId

enum _:FLAGS
{
	I_BIT,
	S_RANK[60]
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new iRet
	g_hTrie = TrieCreate()
	g_hFlagsArray = ArrayCreate(FLAGS, 1)
	g_iMsgId = get_user_msgid("SayText")
	
	ReadFile(iRet)
	register_concmd("amx_reload_login_file", "CmdReload", ADMIN_BAN)
	
	log_amx("Got %d ranks and logins", iRet)
}

public CmdReload(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}
	
	g_szMsg[0] = EOS
	g_iArraySize = 0
	TrieClear(g_hTrie)
	ArrayClear(g_hFlagsArray)
	
	new iReturn
	ReadFile(iReturn)
	
	console_print(id, "Successfully reloaded!^nGot %d ranks and logins", iReturn)
	return PLUGIN_HANDLED
}

ReadFile(&iRet)
{
	new szFile[60]
	get_configsdir(szFile, charsmax(szFile))
	
	add(szFile, charsmax(szFile), "/login_extra_ranks.ini")
	
	new f = fopen(szFile, "r")
	
	if(!f)
	{
		fclose(f)
		f = fopen(szFile, "a+")
		
		fputs(f, "; -------------------------------------------------------------------------------------------------------------^n")
		fputs(f, "; Lines starting with ; are comments and are ignored.^n")
		fputs(f, "; the first line is the message that gets shown when a player that has a login rank connects^n")
		fputs(f, "; Colors are !g, !n, !t. !g is green, !n is normal color and !t is team color.^n")
		fputs(f, "; File format for ranks:^n")
		fputs(f, "; ^"STEAM ID^" ^"RANK^"^n")
		fputs(f, "; Or:^n")
		fputs(f, "; ^"FLAGS^" ^"RANK^"^n")
		fputs(f, "; Use %name% or %steamid% or %ip% or %rank% in login msg (Rank for example is Administrator, silver or golden)^n")
		fputs(f, "; Notes:^n")
		fputs(f, "; Plugin checks first steamid the the flags from the top to the end^n")
		fputs(f, "; -------------------------------------------------------------------------------------------------------------^n")
		fprintf(f, "; Message is:^n%s^n", DEFAULT_MSG)
		
		fclose(f)
		fclose(f)
		
		copy(g_szMsg, charsmax(g_szMsg), DEFAULT_MSG)
		
		while( replace(g_szMsg, charsmax(g_szMsg), "!g", "^4") ) { }
		while( replace(g_szMsg, charsmax(g_szMsg), "!n", "^1") ) { }
		while( replace(g_szMsg, charsmax(g_szMsg), "!t", "^3") ) { }
		
		return;
	}
	
	new szLine[100], szRank[65], szSteamId[35]
	new bool:bGotMsg = false
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szFile))
		replace(szLine, charsmax(szLine), "^n", "")
		
		if(!szLine[0] || szLine[0] == ';')
		{
			continue;
		}
		
		if(!bGotMsg)
		{
			copy(g_szMsg, charsmax(g_szMsg), szLine)
			bGotMsg = true
			continue;
		}
		
		parse(szLine, szSteamId, 34, szRank, 64)
		
		remove_quotes(szRank)
		remove_quotes(szSteamId)
		
		if(contain(szSteamId, "STEAM_") != -1)
		{
			TrieSetString(g_hTrie, szSteamId, szRank)
			
			iRet++
		}
		
		else
		{
			new iArray[FLAGS]
			iArray[I_BIT] = read_flags(szSteamId)
			copy(iArray[S_RANK], charsmax(iArray) - I_BIT, szRank)
			
			ArrayPushArray(g_hFlagsArray, iArray)
			
			iRet++
		}
	}
	
	fclose(f)
	fclose(f)
	
	g_iArraySize = ArraySize(g_hFlagsArray)

	replace_all(g_szMsg, charsmax(g_szMsg), "!g", "^x04")
	replace_all(g_szMsg, charsmax(g_szMsg), "!n", "^x01")
	replace_all(g_szMsg, charsmax(g_szMsg), "!t", "^x03")
}

public client_authorized(id)
{
	if(!g_szMsg[0] || !is_user_admin(id))
	{
		return;
	}
	
	new szAuthId[35], iFound = 0
	get_user_authid(id, szAuthId, charsmax(szAuthId))
	
	new szLogin[65]
	
	if(TrieKeyExists(g_hTrie, szAuthId))
	{
		TrieGetString(g_hTrie, szAuthId, szLogin, 64)
		iFound = 1
	}
	
	else
	{
		new iArray[FLAGS]
		
		for( new i, iFlag; i < g_iArraySize; i++)
		{
			ArrayGetArray(g_hFlagsArray, i, iArray)
			iFlag = iArray[I_BIT]
			
			if(get_user_flags(id) & iFlag)
			{
				copy(szLogin, 64, iArray[S_RANK])
				
				iFound = 1
				break;
			}
		}
	}

	if(!iFound)
	{
		return;
	}
	
	new szMsg[100]
	copy(szMsg, charsmax(szMsg), g_szMsg)
	
	new szName[32]; get_user_name(id, szName, 31)
	new szIp[15]; get_user_ip(id, szIp, charsmax(szIp), 1)
	
	while( replace(szMsg, charsmax(szMsg), "%name%", szName) ) { }
	while( replace(szMsg, charsmax(szMsg), "%rank%", szLogin) ) { }
	while( replace(szMsg, charsmax(szMsg), "%ip%", szIp) ) { }
	while( replace(szMsg, charsmax(szMsg), "%steamid%", szAuthId) ) { }
	
	ColorChat(szMsg)
}

stock ColorChat(szMsg[])
{
	new szFmt[191]
	szFmt[0] = '^x01'
	
	copy(szFmt[1], charsmax(szFmt) - 1, szMsg)
	
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "ch")
	
	for(new i; i < iNum; i++)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgId, .player = iPlayers[i])
		write_byte(iPlayers[i])
		write_string(szFmt)
		message_end()
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
