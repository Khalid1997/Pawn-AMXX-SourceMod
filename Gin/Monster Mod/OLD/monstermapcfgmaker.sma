// Savage Timmi's monster mod map cfg creator v1.0
//
// I just seen someone needing this and I needed it to so here it is.

///////********DO NOT CHANGE THIS*********///////////

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define HMCHAN_PLAYERINFO 1089

#define INFINITE_NUM	815710
#define ACCESS ADMIN_KICK

new monstername[33]
new delay
new ammount

new g_iMonsterMenu;
new g_iMonsterAmountMenu;
new g_iMonsterDelayMenu;

new g_szMonsterNames[][] = {
	"snark",
	"headcrab",
	"bullsquid",
	"bigmomma",
	"hgrunt",
	"hassassin",
	"scientist",
	"barney",
	"zombie" ,
	"houndeye",
	"islave",
	"apache",
	"agrunt",
	"gargantua",
	"nihilanth",
	"icthyosaur",
	"leech"
}

new g_iDelays[] = {
	0,
	5,
	10,
	15,
	20,
	25, 
	30,
	35,
	40,
	45
}

new g_iMonsterNums[] = {
	1, 2, 3, 4, 5, 6, 7, 8, 9
}	

public makemapfile(id) {
	new vaultdata2[512] 
	new vaultdata1[512]
	new directory[200]
	new allowfilepath[251]
	
	new i_origin[3]
	new mapname[32]
	get_mapname(mapname,32)
	get_user_origin( id, i_origin )
	//
	//Writes the Precache.cfg for the map
	
	format(directory,199,"addons/monster/config/%s_precache.cfg", mapname) 
	
	format ( vaultdata1, 511, "%s", monstername )
	write_file(directory,vaultdata1,-1)
	//
	// Writes the monster.cfg for the map
	format(allowfilepath,250,"addons/monster/config/%s_monster.cfg", mapname) 
	format (vaultdata2, 511, " { ")
	write_file(allowfilepath,vaultdata2,-1)
	
	format (vaultdata2, 511, "origin/%d %d %d", i_origin[0], i_origin[1], i_origin[2] )
	write_file(allowfilepath,vaultdata2,-1)
	if (delay ==0 ) delay = 20
	format (vaultdata2, 511, "delay/%d" ,delay)
	write_file(allowfilepath,vaultdata2,-1)
	
	format (vaultdata2, 511, "monster/%s",monstername)
	if ( ammount >= 1 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 2 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 3 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 4 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 5 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 6 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 7 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 8 ) write_file(allowfilepath,vaultdata2,-1)
	if ( ammount >= 9 ) write_file(allowfilepath,vaultdata2,-1)
	
	format (vaultdata2, 511, " } ")
	write_file(allowfilepath,vaultdata2,-1)
	
	set_hudmessage(75,200,200,-1.0,0.86,0,6.0,2.0,0.1,0.5,HMCHAN_PLAYERINFO)
	show_hudmessage(id, "Coordinates and monster name written.^n %s.cfg  in the monster config folder.^n /cstrike/addons/monster/configs.  ", mapname)
	client_print(id, print_chat, "** Written Monster %s with Number of spawns %d and spawn delay of %d seconds", monstername, ammount, delay);
	
	menu_display(id, g_iMonsterMenu);
	return PLUGIN_CONTINUE 
}

public ammounttospawnkey(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	ammount = g_iMonsterNums[item]
	menu_display(id, g_iMonsterDelayMenu);
}

public selectdelaykey(id, menu, item)
{

	if(item == MENU_EXIT)
	{
		return;
	}
	
	if(!item)
	{
		delay = INFINITE_NUM
	}
	
	else
	{
		delay = g_iDelays[item]
	}
	
	makemapfile(id)
}

public monsterkey(id, menu, item) {
	if(item == MENU_EXIT)
	{
		return;
	}
	copy(monstername, charsmax(monstername), g_szMonsterNames[item]);
	menu_display(id, g_iMonsterAmountMenu);
}

public writehandler(id) {
	if( !( get_user_flags(id) & ACCESS ) )
	{
		return client_print(id, print_chat, "* You don't have the required access");
	}
	
	set_hudmessage(75,200,200,-1.0,0.86,0,6.0,2.0,0.1,0.5,HMCHAN_PLAYERINFO)
	show_hudmessage(id, "Where ever you are standin will be the new coordinates^n for the monster you pick to place into you .cfg . ")
	
	menu_display(id, g_iMonsterMenu);
	return PLUGIN_CONTINUE
}

public plugin_init() {
	register_concmd("say write", "writehandler")
	register_concmd("say makecfg", "writehandler")
	register_concmd("say makemapcfg", "writehandler")
	register_concmd("say createcfg", "writehandler")

	new i, szItemName[30]
	g_iMonsterMenu = menu_create("Choose a Monster", "monsterkey");
	{
		for(i = 0; i < sizeof(g_szMonsterNames);i++)
		{
			copy(szItemName, charsmax(szItemName), g_szMonsterNames[i]);
			ucfirst(szItemName);
			
			menu_additem(g_iMonsterMenu, szItemName);
		}
	}
	
	g_iMonsterAmountMenu = menu_create("How many monsters do you want to spawn?", "ammounttospawnkey");
	{
		for(i = 0; i < sizeof(g_iMonsterNums);i++)
		{
			formatex(szItemName, charsmax(szItemName), "%d", g_iMonsterNums[i]);
			menu_additem(g_iMonsterAmountMenu, szItemName);
		}
	}
	
	g_iMonsterDelayMenu = menu_create("Choose Spawn Delay", "selectdelaykey");
	{
		for(i = 0; i < sizeof(g_iDelays);i++)
		{
			if(!g_iDelays[i])
			{
				formatex(szItemName, charsmax(szItemName), "Infinite %d", INFINITE_NUM);
			}
			
			else	formatex(szItemName, charsmax(szItemName), "%d", g_iDelays[i]);
			menu_additem(g_iMonsterDelayMenu, szItemName);
		}
	}
	
	register_plugin("Monster Map Cfg creator", "1.0", "Timmi the savage")
}
