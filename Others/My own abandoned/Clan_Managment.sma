#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Clan Members"
#define VERSION "1.0"
#define AUTHOR "Khalid"

#define FILE_NAME	"/Clan_Members.txt"	// Keep the '/' character

#define CLAN_NAME	"[LoveYA]"
#define MAX_MEMBERS	500


new g_iIsMember[33]

new ClanMembersAuthIds[MAX_MEMBERS + 1][33]

new 	 szFile[60]
new 	 g_Keys 			= (MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2)
new bool:g_bAcceptNewMembers 	= true

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new szMenuTitle[50]
	formatex(szMenuTitle, charsmax(szMenuTitle), "Would you like to join my clan (%s)?", CLAN_NAME)
	register_menu(szMenuTitle, g_Keys, "menu_handler") 
	
	register_clcmd("say /joinclan", "join_clan")
	
	set_task(60.0, "advertise", .flags="b")
}

public advertise()
{
	client_print(0, print_chat, "* You can join our clan (%s) by typing /joinclan in chat!", CLAN_NAME)
}

public join_clan(id)
{
	new szAuthId[33]
	get_user_authid(id, szAuthId, charsmax(szAuthId))
	
	if(!g_bAcceptNewMembers)
	{
		client_print(id, print_chat, "The clan is full right now, please try again later.")
		return PLUGIN_CONTINUE
	}
	
	Add_Member(szAuthId)
	Change_Name(id)
	
	return PLUGIN_HANDLED
}

public plugin_cfg()
{
	get_datadir(szFile, charsmax(szFile))
	add(szFile, charsmax(szFile), FILE_NAME)
	
	if(!file_exists(szFile))
		write_file(szFile, "")
	
	Load_Members()
}
	

public client_putinserver(id)
{
	g_iIsMember[id] = 0

	if(is_member(id))
	if(is_member(id))
	{
		Change_Name(id)
		return;
	}
		
	if(g_bAcceptNewMembers)
		set_task(15.0, "show_menu_to_player", id)
}
	
public show_menu_to_player(id)
{
	new szMenu[100]
	formatex(szMenu, charsmax(szMenu), "Would you like to join my clan (%s)?^n\r1. \wYes^n\r2. \wNo", CLAN_NAME)
	show_menu(id, g_Keys, szMenu)
}

public menu_handler(id, key)
{
	if(key == 0)
	{
		new szAuthId[33]
		get_user_authid(id, szAuthId, charsmax(szAuthId))
		
		if(!g_bAcceptNewMembers)
		{
			client_print(id, print_chat, "Sorry, our clan is full right now. Please try again later.")
			return;
		}
		
		Add_Member(szAuthId)
		Change_Name(id)
	}
}
	
public client_infochanged(id)
{
	if(g_iIsMember[id])
		Change_Name(id)
}
	
Load_Members()
{
	new iTxtLen, AuthId[33]
	new iSize = file_size(szFile, 1)
	
	if(iSize > MAX_MEMBERS)
	{
		iSize = MAX_MEMBERS
		g_bAcceptNewMembers = false
	}
	
	for(new i; i <= iSize; i++)
	{
		read_file(szFile, i, AuthId, 32, iTxtLen)
		copy(AuthId, 32, ClanMembersAuthIds[i])
	}
}

Add_Member(const szAuthId[])
{
	if(g_bAcceptNewMembers)
	{
		write_file(szFile, szAuthId)
		Load_Members()
	}
}

is_member(id)
{
	new szAuthId[33], iMember
	get_user_authid(id, szAuthId, charsmax(szAuthId))
	
	
	for(new i; i < sizeof(ClanMembersAuthIds); i++)
	{
		if(equal(szAuthId, ClanMembersAuthIds[i]))
		{
			iMember = 1
			g_iIsMember[id] = 1
			break;
		}
	}
	
	return iMember
}
	
Change_Name(id)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	formatex(szName, charsmax(szName), "%s %s", CLAN_NAME, szName)
	set_user_info(id, "name", szName)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
