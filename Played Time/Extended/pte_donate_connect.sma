#include <amxmodx>
#include <amxmisc>
#include <played_time>

#define PLUGIN "Donate Time"
#define VERSION "1.0b"
#define AUTHOR "Khalid"

#if AMXX_VERSION_NUM < 183
	#include <colorchat>
	#define print_team_default Blue
	#define print_team_red Red
	#define print_team_grey Grey
	#define print_team_blue Blue
	
	#define MAX_NAME_LENGTH 32
	#define client_disconnected client_disconnect
#endif

new g_iDonateTo[33];
new g_pDonate, g_pConnectMessages;
new const PREFIX[] = "^x04[Played-Time]";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Donate Stuff
	register_clcmd("say /donate_time", "ClCmd_Donate");
	register_concmd("Type", "DonateAmount");
	
	g_pDonate = register_cvar("pte_allow_donate", "1");
	g_pConnectMessages = register_cvar("pte_show_connect_messages", "1");
}

public client_putinserver(id)
{
	if( is_user_hltv(id)  || is_user_bot(id) )
		return;
	
	if(get_pcvar_num(g_pConnectMessages))
	{
		new szName[32]; get_user_name(id, szName, charsmax(szName))
		new iTime = pt_get_user_played_time(id) / 60
		
		client_print_color(id, print_team_default, "%s ^x01Player ^3%s ^4Connected with a total time of ^3%d ^4minute%s", PREFIX, szName, iTime, iTime == 1 ? "" : "s")
	}
}

public ClCmd_Donate(id)
{
	if(!get_pcvar_num(g_pDonate))
	{
		client_print_color(id, print_team_default, "%s ^x01Donating is disabled at the moment.", PREFIX)
		return PLUGIN_HANDLED
	}
	
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "h")
	
	if(iNum < 2)
	{
		client_print_color(id, print_team_default, "%s ^x01Sorry, There are no other players to donate to ..", PREFIX)
		return PLUGIN_HANDLED
	}
	
	new iTime = get_user_played_time(id) / 60;
	new szTitle[70];
	
	formatex(szTitle, charsmax(szTitle), "\rDonate Menu^n\yYour total time is: \w%d \yminute%s^n", iTime, iTime  == 1 ? "" : "s" );
	new iMenu = menu_create(szTitle, "DonateMenuHandler");
	
	new szName[32], szInfo[4];
	new szMenuItem[45];
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(iPlayer != id)
		{
			get_user_name(iPlayer, szName, charsmax(szName))
			formatex(szMenuItem, charsmax(szMenuItem), "%s \r(\y%d \wminutes\r)", szName, pt_get_user_played_time(iPlayer) / 60);
			num_to_str(iPlayer, szInfo, charsmax(szInfo))
			menu_additem(iMenu, szMenuItem, szInfo)
		}
	}
	
	menu_display(id, iMenu)
	return PLUGIN_CONTINUE
}


public DonateMenuHandler(id, menu, item)
{
	if(!get_pcvar_num(g_pDonate))
	{
		client_print_color(id, print_team_default, "%s ^x01Donating is disabled at the moment.", PREFIX)
		return;
	}
	
	if(item < 0)
	{
		return;
	}
	
	new id2, callback, iAccess, szInfo[4];
	menu_item_getinfo(menu, item,iAccess, szInfo, 3, .callback = callback);
	
	id2 = str_to_num(szInfo);
	menu_destroy(menu);
	
	if(!is_user_connected(id2))
	{
		client_print_color(id, print_team_default, "%s ^x01You can't donate to a disconnected player..", PREFIX);
		return;
	}
	
	g_iDonateTo[id] = id2;
	new szName[32]; get_user_name(id2, szName, 31);
	
	client_cmd(id, "messagemode ^"Type the amount to donate^"");
	client_print_color(id, print_team_default, "%s ^x01Type the amount that you want to donate to %s", PREFIX, szName);
}

public DonateAmount(id)
{
	if(!get_pcvar_num(g_pDonate))
	{
		client_print_color(id, print_team_default, "%s ^x01Donating is disabled at the moment.", PREFIX);
		return PLUGIN_HANDLED;
	}

	
	new id2 = g_iDonateTo[id];
	if(!id2 || !is_user_connected(id2))
	{
		return PLUGIN_HANDLED;
	}
	
	new szAmount[50], iAmount;
	read_argv(read_argc() - 1, szAmount, charsmax(szAmount));
	new iDonaterTime = pt_get_user_played_time(id);
	
	if( is_str_num(szAmount) )
	{
		iAmount = (str_to_num(szAmount) * 60);
		if(iAmount < 0)
		{
			client_print_color(id, print_team_default, "%s ^x01You can't donate that", PREFIX)
			return PLUGIN_HANDLED
		}
	}
	
	else if(szAmount[0] == '*' && szAmount[1] == EOS)
	{
		iAmount = iDonaterTime;
	}
		
	else
	{
		client_print_color(id, print_team_default, "%s ^x01You can't donate that", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	if( iDonaterTime - iAmount < 0 )
	{
		iAmount = iDonaterTime;
	}
	
	pt_set_user_played_time(id, iDonaterTime - iAmount);
	pt_set_user_played_time(id2, pt_get_user_played_time(id2) + iAmount);
	
	new szName[32], szName2[32];
	get_user_name(id, szName, 31); get_user_name(id2, szName2, 31);
	
	client_print_color(0, print_team_default, "%s ^x01Player ^x03%s^4 donated to ^x03%s ^x01%d ^x04minutes", PREFIX, szName, szName2, iAmount / 60);
	
	return PLUGIN_HANDLED
}
