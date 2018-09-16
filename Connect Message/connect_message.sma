#include <amxmodx>

#define PLUGIN "Welcome message"
#define VERSION "1.0"
#define AUTHOR "Khalid :)"

new g_pMessage, g_pEnabled
new gMsgId

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_pMessage = register_cvar("connect_message", "")
	g_pEnabled = register_cvar("connect_message_enabled", "1")
	
	gMsgId = get_user_msgid("SayText")
}

public client_putinserver(id)
	if(!is_user_bot(id) && !is_user_hltv(id))
		set_task(7.5, "Print", id + 1335)
	
public Print(id)
{
	id -= 1335
	if(is_user_connected(id) && get_pcvar_num(g_pEnabled))
	{
		static szMessage[301]
		get_pcvar_string(g_pMessage, szMessage, charsmax(szMessage))
		
		if(!szMessage[0])
			return;
		
		replace_all(szMessage, charsmax(szMessage), "!g", "^4")
		replace_all(szMessage, charsmax(szMessage), "!t", "^3")
		replace_all(szMessage, charsmax(szMessage), "!n", "^1")
		
		if(containi(szMessage, "%name%") != -1)
		{
			static szName[33]; get_user_name(id, szName, charsmax(szName))
			replace_all(szMessage, charsmax(szMessage), "%name%", szName)
		}
		
		if(containi(szMessage, "%ip%") != -1)
		{
			static szIp[25]; get_user_ip(id, szIp, charsmax(szIp), 1)
			replace_all(szMessage, charsmax(szMessage), "%ip%", szIp)
		}
		
		if(containi(szMessage, "%steamid%") != -1)
		{
			static szAuthId[35]; get_user_authid(id, szAuthId, charsmax(szAuthId))
			replace_all(szMessage, charsmax(szMessage), "%steamid%", szAuthId)
		}
		
		if(containi(szMessage, "/n") != -1)
		{
			replace_all(szMessage, charsmax(szMessage), "/n", "+")
			
			static szPrint[193]
			
			while(contain(szMessage, "+") != -1)
			{
				strtok(szMessage, szPrint, charsmax(szPrint), szMessage, charsmax(szMessage), '+')
			//	replace(szPrint, charsmax(szPrint), "+", "^n")
			
				server_print("Message one: %s", szMessage)
				server_print("Message two: %s", szPrint)
				
				message_begin(MSG_ONE, gMsgId, .player = id)
				write_byte(id)
				write_string(szPrint)
				message_end()
				
				if(contain(szMessage, "+") == -1 && szMessage[0])
				{
					message_begin(MSG_ONE, gMsgId, .player = id)
					write_byte(id)
					write_string(szMessage)
					message_end()
					
					break;
				}
			}
			
			return;
		}
		
		server_print("Message: %s", szMessage)
		message_begin(MSG_ONE, gMsgId, .player = id)
		write_byte(id)
		write_string(szMessage)
		message_end()
	}
}
		
