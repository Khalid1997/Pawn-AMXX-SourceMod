#include <amxmodx>
#include <cstrike>
#include <colorchat>

#define DONATE_START_AMOUNT	1000
#define MAX_DONATE_AMOUNT	16000

new const szPrefix[] = "[staNioN-MM]"

new const g_szDonateCmds[][] = {
	"/donate",
	"donate",
	"donate_money",
	"/donate_money",
	"money_donate",
	"/money_donate"
};	

new g_iMenu[33];
new g_iDonateTo[33];
new g_iDonationAmount[33];

new g_pDonateIncreaseAmount;

stock CreateMenu(id, szTitle[] = "", szHandler[])
{
	if(g_iMenu[id])
	{
		DestroyMenu(id);
	}
		
	return ( g_iMenu[id] = menu_create(szTitle, szHandler) );
}

stock DestroyMenu(id)
{
	if(!g_iMenu[id])
	{
		return;
	}
	
	menu_destroy(g_iMenu[id]);
	g_iMenu[id] = 0;
}

public plugin_init() 
{ 
	register_plugin("MONEY-GIVE","1.05","+ARUKARI-") 

	for(new i, szCmd[60]; i < sizeof g_szDonateCmds; i++)
	{
		formatex(szCmd, charsmax(szCmd), "say %s", g_szDonateCmds[i]);
		register_clcmd(szCmd, "cmdDonateMenu");
		
		formatex(szCmd, charsmax(szCmd), "say_team %s", g_szDonateCmds[i]);
		register_clcmd(szCmd, "cmdDonateMenu");
	}
	
	register_clcmd("DonateTo", "Donate_CmdCustomAmount");
	g_pDonateIncreaseAmount = register_cvar("donate_increase_money", "1000");
} 

public cmdDonateMenu(id,level,cid)
{	
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "ch");
	
	if(iNum == 1)
	{
		ColorChat(id, TEAM_COLOR, "^4%s ^1You Cant ^3Donate ^1when You'r ^4Alone.", szPrefix);
		return;
	}
	
	new szTitle[60]
	formatex(szTitle, charsmax(szTitle), "\r%s \yDonate To:", szPrefix);
	CreateMenu(id, szTitle, "Donate_ChoosePlayerHandler");
	
	for(new i, szInfo[3], iPlayer, iAccess, szName[32]; i < iNum; i++, iAccess = 0)
	{
		iPlayer = iPlayers[i]
		if( ( iPlayer ) == id )
		{
			iAccess = (1<<27);
		}
		
		get_user_name(iPlayer, szName, 31);
		num_to_str(iPlayer, szInfo, charsmax(szInfo));
		menu_additem(g_iMenu[id], szName, szInfo, iAccess);
	}
	
	menu_display(id, g_iMenu[id]);
}  

public Donate_ChoosePlayerHandler(id, menu, item)
{
	if(item < 0)
	{
		DestroyMenu(id);
		return;
	}
	
	new szInfo[3], iPlayer, szDonateToName[32];
	menu_item_getinfo(menu, item, iPlayer, szInfo, charsmax(szInfo), szDonateToName, 31, iPlayer);
	
	g_iDonateTo[id] = ( iPlayer = str_to_num(szInfo) );
	DestroyMenu(id);
	
	new szTitle[60];
	formatex(szTitle, charsmax(szTitle), "\r%s \yDonations", szPrefix);
	
	CreateMenu(id, szTitle, "Donate_ChooseDonateOption");
	
	formatex(szTitle, charsmax(szTitle), "\wDonate To: \y%s", szDonateToName);
	menu_additem(g_iMenu[id], szTitle);
	
	menu_additem(g_iMenu[id], "Type A Custom Amount");
	
	formatex(szTitle, charsmax(szTitle), "Donation Amount: \y%d", ( g_iDonationAmount[id] = DONATE_START_AMOUNT ) );
	menu_additem(g_iMenu[id], szTitle);
	
	menu_display(id, g_iMenu[id]);
}

public Donate_ChooseDonateOption(id, menu, item)
{
	if(item < 0)
	{
		DestroyMenu(id);
		return;
	}
	
	
	enum
	{
		ITEM_DONATE_TO,
		ITEM_CUSTOM_AMOUNT,
		ITEM_DONATION_AMOUNT
	};
	
	switch(item)
	{
		case ITEM_DONATE_TO:
		{
			DestroyMenu(id);
			DoDonate(id);
		}
		
		case ITEM_DONATION_AMOUNT:
		{
			if( ( g_iDonationAmount[id] += get_pcvar_num(g_pDonateIncreaseAmount) ) > MAX_DONATE_AMOUNT)
			{
				g_iDonationAmount[id] = DONATE_START_AMOUNT
			}
			
			new szNewName[60];
			formatex(szNewName, charsmax(szNewName), "Donation Amount: \y%d", ( g_iDonationAmount[id] ) )
			menu_item_setname(menu, item, szNewName);
			
			menu_display(id, menu);
		}
		
		case ITEM_CUSTOM_AMOUNT:
		{
			DestroyMenu(id);
			
			client_cmd(id, "messagemode ^"DonateTo^"");
			ColorChat(id, TEAM_COLOR, "^4%s ^1Please type your ^4Amount ^1to give. It ^3MUST ^1be an ^3integer!", szPrefix);
		}
	}
}

public Donate_CmdCustomAmount(id)
{
	new szAmount[16];
	read_argv(read_argc() - 1, szAmount, charsmax(szAmount));
	
	if(!is_str_num(szAmount))
	{
		ColorChat(id, TEAM_COLOR, "^4%s ^1Invalid ^3Value!", szPrefix);
		return;
	}
	
	g_iDonationAmount[id] = str_to_num(szAmount);
	
	if(g_iDonationAmount[id] < 0)
	{
		g_iDonationAmount[id] *= -1;
	}
		
	DoDonate(id);
}

stock DoDonate(id)
{
	new iDonateTo = g_iDonateTo[id];
	new iDonatedMoney = g_iDonationAmount[id];
	
	if(!is_user_connected(iDonateTo))
	{
		ColorChat(id, TEAM_COLOR, "^4%s^1Player is no longer ^3Connected.", szPrefix);
		return;
	}
	
	new iUserMoney = cs_get_user_money(id);
	if(iUserMoney < iDonatedMoney)
	{
		ColorChat(id, TEAM_COLOR, "^4%s ^1You Dont have ^3Enough Money ^1to ^4Donate.", szPrefix);
		return;
	}
	
	cs_set_user_money(id, iUserMoney - iDonatedMoney);
	cs_set_user_money(iDonateTo, cs_get_user_money(iDonateTo) + iDonatedMoney);
	
	new szName1[32], szName2[32];
	get_user_name(id, szName1, 31);
	get_user_name(iDonateTo, szName2, 31);
	
	ColorChat(id, TEAM_COLOR, "^4%s ^3%s ^1You have just ^3donated $%d ^1to ^3%s.", szPrefix, iDonatedMoney, szName2);
	ColorChat(0, TEAM_COLOR, "^4%s ^3%s ^1just ^3donated $%d ^1to ^3%s", szPrefix, szName1, iDonatedMoney, szName2);
	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
