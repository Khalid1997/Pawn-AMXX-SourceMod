#include <amxmodx> 

new const gsz_PasswordCommand[] = "Password_For_Guard_Join" 

#define PASSWORD_CASE_SENSITIVE 

//#define PASS_BY_STEAMID 
#if defined PASS_BY_STEAMID 
new const PASSWORD_FILE[] = "addons/amxmodx/configs/gaurd_passwords.ini" 
new Trie:g_PWTrie 
#else 
new g_pPassWord 
#endif 

const TEAM_NUM = 2 
new gAllowBit = 0 

//#define DEBUG
#if defined DEBUG 
#include <fakemeta> 
#include <cstrike> 
const OFFSET_TEAM = 114 

new g_iFirst = 1 
#endif 

public plugin_init() 
{ 
	register_plugin("Join Gaurds with a Password", "1.0", "Khalid :)") 
	register_clcmd("jointeam", "CmdJoinTeam") 
	register_concmd(gsz_PasswordCommand, "PassWord") 
	
	register_message(get_user_msgid("TeamInfo"), "MessageTeamInfo") 
	register_message(get_user_msgid("ShowMenu"), "MessageShowMenu") 
	
	#if defined PASS_BY_STEAMID 
	g_PWTrie = TrieCreate() 
	
	read_passwords() 
	#else 
	g_pPassWord = register_cvar("gaurds_password", "001122334455") 
	#endif 
	
} 

public MessageTeamInfo(msgid, dest, id) 
{ 
	if(is_user_bot(id)) 
		return PLUGIN_CONTINUE 
	
	
	static szTeamChar[2] 
	get_msg_arg_string(2, szTeamChar, charsmax(szTeamChar)) 
	
	#if defined DEBUG 
	server_print("TeamChar = %s", szTeamChar) 
	#endif 
	
	if(szTeamChar[0] != 'C') 
	{ 
		#if defined DEBUG 
		server_print("Continue on Team choose") 
		#endif 
		return PLUGIN_CONTINUE 
	} 
	
	if( !( gAllowBit & (1<<id) ) ) 
	{ 
		#if defined DEBUG 
		server_print("Called %s", g_iFirst == 1 ? "First" : "Secound" ) 
		server_print("STOPPED!") 
		#endif 
		return PLUGIN_HANDLED 
	} 
	
	return PLUGIN_CONTINUE 
} 

public MessageShowMenu(msgid, dest, id) 
{ 
	static const CT_MENU_CODE[] = "#CT_Select" 
	
	new szMenuText[13] 
	get_msg_arg_string(4, szMenuText, charsmax(szMenuText)) 
	
	#if defined DEBUG 
	server_print("Called %s", g_iFirst == 1 ? "First" : "Secound" ) 
	#endif 
	
	if(equal(szMenuText, CT_MENU_CODE)) 
	{ 
		#if defined DEBUG 
		server_print( "TEAM : %d .. get_user_team = %d ... cs_get_user_team == %d", get_pdata_int(id, OFFSET_TEAM), get_user_team(id), cs_get_user_team(id)) 
		#endif 
		Ask(id) 
		return PLUGIN_HANDLED 
	} 
	return PLUGIN_CONTINUE 
} 

public CmdJoinTeam(id) 
{ 
	if(is_user_bot(id)) 
		return PLUGIN_CONTINUE 
	
	if(gAllowBit & (1<<id)) 
	{ 
		gAllowBit &= ~(1<<id)    // Remove id from bit 
		return PLUGIN_CONTINUE 
	} 
	
	new szTeamNum[2] 
	read_argv(1, szTeamNum, charsmax(szTeamNum)) 
	
	#if defined DEBUG 
	server_print("Attempt to join team...") 
	server_print("Team Num == %s", szTeamNum) 
	#endif 
	
	if(str_to_num(szTeamNum) == TEAM_NUM) 
		Ask(id) 
	
	return PLUGIN_HANDLED 
} 

Ask(id) 
{ 
	#if defined PASS_BY_STEAMID 
	new szAuthId[33] 
	get_user_authid(id, szAuthId, charsmax(szAuthId)) 
	
	if(TrieKeyExists(g_PWTrie, szAuthId)) 
		client_cmd(id, "messagemode %s", gsz_PasswordCommand) 
		
	else    client_print(id, print_chat, "You have no access to join this team..") 
	#else 
	client_cmd(id, "messagemode %s", gsz_PasswordCommand) 
	#endif 
} 

public PassWord(id) 
{ 
	new szPassWord[32] 
	#if defined PASS_BY_STEAMID 
	new szAuthId[33] 
	get_user_authid(id, szAuthId, charsmax(szAuthId)) 
	read_argv(1, szPassWord, charsmax(szPassWord)) 
	
	if(TrieKeyExists(g_PWTrie, szAuthId)) 
	{ 
		new szRequired_Pass[33] 
		TrieGetString(g_PWTrie, szAuthId, szRequired_Pass, charsmax(szRequired_Pass)) 
		
		#if defined PASSWORD_CASE_SENSITIVE 
		if(equal(szRequired_Pass, szPassWord)) 
			#else 
		if(equali(szRequired_Pass, szPassWord)) 
			#endif 
		{ 
			gAllowBit |= (1<<id) 
			client_cmd(id, "jointeam %d", TEAM_NUM) 
			return PLUGIN_HANDLED 
		} 
	
		else 
		{ 
			client_print(id, print_chat, "*** The PassWord is wrong!") 
			return PLUGIN_HANDLED 
		} 
	} 

	else 
	{ 
		client_print(id, print_chat, "You can't join the team as you are not in the LIST") 
		client_print(id, print_chat, "You will join the terrorists.") 
		client_cmd(id, "jointeam 1") 
		return PLUGIN_HANDLED 
	} 
	
	#else 
	new szInput[32] 
	read_argv(1, szInput, charsmax(szInput)) 
	
	get_pcvar_string(g_pPassWord, szPassWord, charsmax(szPassWord)) 
	
	#if defined PASSWORD_CASE_SENSITIVE 
	if(equal(szPassWord, szInput)) 
	#else 
	if(equali(szPassWord, szInput)) 
	#endif 
	{ 
		gAllowBit |= (1<<id) 
		client_cmd(id, "jointeam %d", TEAM_NUM) 
		return PLUGIN_HANDLED 
	} 
	#endif 
	
	return PLUGIN_HANDLED 
} 

#if defined PASS_BY_STEAMID 
read_passwords() 
{ 
	new file 
	#if defined DEBUG 
	server_print("Continue 1") 
	#endif 
	
	if(!( file = fopen(PASSWORD_FILE, "r+") ) ) 
	{ 
		#if defined DEBUG 
		server_print("************ File did not open ...") 
		#endif 
		
		write_file(PASSWORD_FILE, "") 
		file = fopen(PASSWORD_FILE, "r+") 
		
		#if defined DEBUG 
		server_print("FILE : %d ... %s", file, file) 
		#endif 
		
		fprintf(file, "; Any lines starting with ; are comments^n") 
		fprintf(file, "; Format:^n") 
		fprintf(file, "; ^"STEAM_0:0:11827616^" ^"PASSWORD! HERE^"^n") 
		fprintf(file, "; NOTE: Never use double quotas in a password ..^n") 
		
		fclose(file) 
		return; 
	} 
	
	#if defined DEBUG 
	server_print("Continue 2") 
	#endif 
	
	new szLine[33 + 32 + 2], szAuthId[33], szPass[32] 
	
	// MY FIRST ATTEMPT TO USE TRIES AND NEW FILE COMMANDS :DDDD 
	while(!feof(file)) 
	{ 
		fgets(file, szLine, charsmax(szLine)) 
	
		if(!szLine[0] || szLine[0] == ';' || szLine[0] != '^"') 
			continue; 
		
		strbreak(szLine, szAuthId, charsmax(szAuthId), szPass, charsmax(szPass)) 
		replace_all(szAuthId, charsmax(szAuthId), "^"", "") 
		replace_all(szPass, charsmax(szPass), "^"", "") 
		
		TrieSetString(g_PWTrie, szAuthId, szPass) 
		
		#if defined DEBUG 
		server_print("SteamId: %s ..... Password: %s", szAuthId, szPass) 
		#endif 
	} 
	
	fclose(file) 
} 
#endif  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
