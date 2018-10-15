#include <amxmodx>
#include <amxmisc>
#include <colorchat>

new const PREFIX[] = "[EP1C-GAMERZ]"

new gMenu

enum (=1<<)
{
	ADMIN,
	GOLDEN,
	SILVER
}

new gsz_Motds[][][] = {
	{ "http://ep1c-gamerz.com/server_rules/admins.htm", "Admin Rules", ADMIN },
	{ "http://ep1c-gamerz.com/server_rules/goldens.htm", "Golden Rules", GOLDEN },
	{ "http://ep1c-gamerz.com/server_rules/silvers.htm", "Silver Rules", SILVER },
	{ "http://ep1c-gamerz.com/server_rules/server_rules.htm", "Server Rules", 0 }
}

public plugin_init()
{
	register_plugin("Rules", "1.0", "Khalid :)")
	
	register_clcmd("say /rules", "CmdShowRules")
	register_concmd("amx_show_rules", "admin_show_rules", ADMIN_RCON, "<player/@TEAM/*/#userid> <menu to show> - Shows rules to a player")
	
	set_task(75.0, "Advertise", .flags = "b")

	BuildMenu()
}

BuildMenu()
{
	gMenu = menu_create("Rules Menu", "menu_handler")
	
	new iCallBack = menu_makecallback("handle_callback")
	
	new szInfo[4]
	new iSize = sizeof ( gsz_Motds )
	
	for(new i; i < iSize; i++)
	{
		formatex(szInfo, charsmax(szInfo), "%d", i)
		menu_additem(gMenu, gsz_Motds[i][1], szInfo, 0, gsz_Motds[i][2][0] == 1 ? iCallBack : -1)
	}
}

public admin_show_rules(id, level, cid)
{
	if(id && !(get_user_flags(id) & level))
	{
		console_print(id, "You don't have access to this command.")
		return PLUGIN_HANDLED
	}
	
	if(read_argc() < 3)
	{
		console_print(id, "Usage: <player/@TEAM/*/#userid> <rules number to show> - Shows rules to a player")
		console_print(id, "Menu to show:")
		
		for(new i; i < sizeof(gsz_Motds); i++)
			console_print(id, "#%d %s", i, gsz_Motds[i][1])
		
		return PLUGIN_HANDLED
	}
	
	new iPlayer, szArg[32], iPlayers[32], iCount, szArg2[4], iNum
	
	read_argv(1, szArg, charsmax(szArg))
	read_argv(2, szArg2, charsmax(szArg2))
	
	
	
	if( !is_str_num(szArg2) || ! ( 0 <= (iNum = str_to_num(szArg2)) < sizeof(gsz_Motds) ) )
	{
		console_print(id, "Invalid rules motd number")
		return PLUGIN_HANDLED
	}
	
	if(szArg[0] == '@')
	{
			
		if(szArg[1] == 'T' || szArg[0] == 't')
		{
			get_players(iPlayers, iCount, "e", "TERRORIST")
			
			if(iCount == 0)
			{
				console_print(id, "No players connected.")
				return PLUGIN_HANDLED
			}
		}
			
		else if(szArg[1] == 'C' || szArg[0] == 'c')
		{
			get_players(iPlayers, iCount, "e", "CT")
			
			if(iCount == 0)
			{
				console_print(id, "No players connected.")
				return PLUGIN_HANDLED
			}
		}
			
		else if(szArg[1] == 'A' || szArg[0] == 'a')
		{
			get_players(iPlayers, iCount, "ch")
			
			if(iCount == 0)
			{
				console_print(id, "No players connected.")
				return PLUGIN_HANDLED
			}
		}
			
		else iCount = -1
	
	}
		
	if(szArg[0] == '*' && szArg[1] == EOS)
	{
		get_players(iPlayers, iCount, "ch")
		
		if(iCount == 0)
		{
			console_print(id, "No players connected.")
			return PLUGIN_HANDLED
		}
	}
	
	if(iCount == -1)
	{
		console_print(id, "Invalid team ..")
		return PLUGIN_HANDLED
	}
			
	if(iCount > 0)
	{
		for(new i; i < iCount; i++)
			show_motd(iPlayers[i], gsz_Motds[iNum][0], gsz_Motds[i][1])
					
		return PLUGIN_HANDLED
	}
	
	iPlayer = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF)
	
	if(!iPlayer)
		return PLUGIN_HANDLED
	
	show_motd(iPlayer, gsz_Motds[iNum][0], gsz_Motds[iNum][1])
	return PLUGIN_HANDLED
}
	

public Advertise()
	ColorChat(0, TEAM_COLOR, "%s ^4Type ^3/rules ^4to see the server rules.", PREFIX)

public CmdShowRules(id)
{	
	menu_display(id, gMenu)
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
		return;
	
	new szInfo[4], callback, access
	menu_item_getinfo(menu, item, access, szInfo, charsmax(szInfo), .callback = callback)
	
	show_motd(id, gsz_Motds[(access = str_to_num(szInfo))][0], gsz_Motds[access][1])

}
