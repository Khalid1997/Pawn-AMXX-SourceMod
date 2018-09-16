#include <amxmodx>
#include <amxmisc>
#include <colorchat>

new const PREFIX[] = "[EP1C-GAMERZ]"

new gCallBack

enum
{
	ADMIN,
	GOLDEN,
	SILVER
}

public plugin_init()
{
	register_plugin("Rules", "1.0", "Khalid :)")
	register_clcmd("say /rules", "CmdShowRules")
	
	set_task(75.0, "Advertise", .flags = "b")
	
	gCallBack = menu_makecallback("handle_callback")
}

public Advertise()
	ColorChat(0, TEAM_COLOR, "%s ^4Type ^3/rules ^4to see the server rules.", PREFIX)

public CmdShowRules(id)
{
	new menu = menu_create("Rules Menu:^nBy Khalid :)", "menu_handler")
	
	menu_additem(menu, "Admin Rules", "0", 0, gCallBack)
	menu_additem(menu, "Golden Rules", "1", 0, gCallBack)
	menu_additem(menu, "Silver Rules", "2", 0, gCallBack)
	menu_additem(menu, "Server Rules", "3")
	
	menu_display(id, menu)
	//show_motd(id, "http://ep1c-gamerz.com/server_rules.htm", "Rules")
}

public handle_callback(id, menu, item)
{
	new szInfo[4], callback, access
	menu_item_getinfo(menu, item, access, szInfo, charsmax(szInfo), .callback = callback)
	
	new iFlags = get_user_flags(id)
	callback = str_to_num(szInfo)
	
	if(!is_user_admin(id))
		return ITEM_DISABLED
	
	if(iFlags & ADMIN_BAN)
		access = ADMIN
		
	if(iFlags & read_flags("t"))
		access = GOLDEN
		
	if(iFlags & read_flags("s"))
		access = SILVER
		
	switch(access)
	{
		case ADMIN:	return ITEM_ENABLED
		
		case GOLDEN:
		{
			if(callback > 0)
				return ITEM_ENABLED
				
			return ITEM_DISABLED
		}
		
		case SILVER:
		{
			if(callback > 1)
				return ITEM_ENABLED
				
			return ITEM_DISABLED
		}
	}
	
	return ITEM_DISABLED
}

public menu_handler(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu)
		return;
	}
		
	new szInfo[4], callback, access
	menu_item_getinfo(menu, item, access, szInfo, charsmax(szInfo), .callback = callback)
	
	switch(str_to_num(szInfo))
	{
		case 0:	show_motd(id, "http://ep1c-gamerz.com/server_rules/admins.htm", "Admin Rules")
		case 1:	show_motd(id, "http://ep1c-gamerz.com/server_rules/goldens.htm", "Golden Rules")
		case 2:	show_motd(id, "http://ep1c-gamerz.com/server_rules/silvers.htm", "Silver Rules")
		case 3:	show_motd(id, "http://ep1c-gamerz.com/server_rules/server_rules.htm", "Server Rules")
		
	}
	
	menu_destroy(menu)
}

	/*switch(str_to_num(szInfo))
	{
		case 0:
		{	
			if( iFlags & ADMIN_BAN && !(iFlags & read_flags("t")) )
				return ITEM_ENABLED
				
			return ITEM_DISABLED
		}
		
		case 1:
		{
			if( is_user_admin(id) && (iFlags & read_flags("t")) )
				return ITEM_ENABLED
			
			return ITEM_DISABLED
		}
		
		case 2:
		{
			if( iFlags & read_flags("s") )
				return ITEM_ENABLED
			
			return ITEM_DISABLED
		}
	}*/
