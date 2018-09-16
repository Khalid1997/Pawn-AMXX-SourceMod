/*

--- multimod.ini ---
[Gun Game]:[gungame-plugins.ini]:[gungame-config.cfg]
[Paint Ball]:[paintball-plugins.ini]:[paintball-config.cfg]
[Hid'N Seek]:[hns-plugins.ini]:[hns-config.cfg]
[Death Run]:[deathrun-plugins.ini]:[deathrun-config.cfg]
[Zombie Plague]:[zombieplague-plugins.ini]:[zombieplague-config.cfg]
[Biohazard]:[biohazard-plugins.ini]:[biohazard-config.cfg]
--------------------

TODO
* add some commands for admins

v0.1
* The very first release
v0.2
* Fixed warning 204 with one unused symbol
v0.3
* Fixed wrong use of cvar amx_nextmod instead of amx_mm_nextmod
* Added admin command amx_votemod
v0.4
* Added hud message every 15 seconds to display current mod name
* Added check for connected players before mod votting
* Added control to remove task avoiding duplicate amx_votemod commands
v0.5
* Added say nextmod command
* Added say /votemod command
* Execute cfg files in first round instead of game_commencing
v0.6
* Added multilangual support (thanks crazyeffect!)
* Added intermission at map change to show scoreboard
* Added timer to execute *.cfg
* Modified where I do sv_restart
* Deleted unused cvar amx_mm_nextmap
* Changed cvar amx_mm_nextmod to amx_nextmod
v0.8
* Added 30 seconds of warmup to avoid conflict/crash with other plugins
* Changed all cvars to amx_xxx format (removed _mm_ part)
* Fixed and improved pcvar usage
v2.0
* Removed a lot of code
* Removed map voting code
* Added compatibility with galileo
* Added semi-compatibility with mapchooser (requires mapchooser patch)
v2.1
* Tested under czero
* Fixed all issues with languaje change
* Pending tests withing Galileo
v2.2
* Fixed votemod DoS
* Fixed galileo plugin lookup problem
* Fixed mapchooser_multimod plugin lookup problem
* Fixed nextmod client command problem
* Added currentmod client command
* Added cvar to disallow votemod client command

Credits:

fysiks: The first to realize the idea and some code improvements
crazyeffect: Colaborate with multilangual support
dark vador 008: Time and server for testing under czero

*/

#include <amxmodx>
#include <amxmisc>

#define COLORED
#define UNLIMITED_MODS

new g_iCount = 16

#if defined COLORED
	#include <colorchat>
#endif

#if defined UNLIMITED_MODS
	#define MAXMODS 200
	new const Float:VOTE_TIME = 25.0
#else
	#define MAXMODS 10
	new g_coloredmenus
#endif


#define PLUGIN_NAME	"MultiMod Manager"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"2.2"

#define AMX_MULTIMOD	"amx_multimod"
#define AMX_PLUGINS	"amxx_plugins"
#define AMX_MAPCYCLE	"mapcyclefile"
#define AMX_LASTCYCLE	"lastmapcycle"

#define AMX_DEFAULTCYCLE	"mapcycle.txt"
#define AMX_DEFAULTPLUGINS	"addons/amxmodx/configs/plugins.ini"
#define	AMX_BASECONFDIR		"multimod"

#define TASK_VOTEMOD 2487002
#define TASK_CHVOMOD 2487004
#define TASK_COUNTDOWN 68784
#define TASK_HUD 17261

#define LSTRING 193
#define SSTRING 33

new g_menuname[] = "Choose the next mod:"
new g_votemodcount[MAXMODS]
new g_modnames[MAXMODS][SSTRING]	// Per-mod Mod Names
new g_filemaps[MAXMODS][LSTRING]	// Per-mod Maps Files
new g_fileplugins[MAXMODS][LSTRING]	// Per-mod Plugin Files

new g_fileconf[LSTRING]
new g_modcount = -1			// integer with configured mods count
new g_alreadyvoted
new g_nextmodid
new g_currentmodid
new g_multimod[SSTRING]
new g_nextmap[SSTRING]
new g_currentmod[SSTRING]
new g_confdir[LSTRING]

new gp_voteanswers

new gp_mode
new gp_mapcyclefile

// galileo specific cvars
new gp_galileo_nommapfile
new gp_galileo_votemapfile

// Admin next mod
new bool:nextmodchoosed = false

// Rock the mod vote...
new g_iHasRTMV[33], g_iPlayersLeft
new g_iStartSysTime
new g_pMins, g_pRTMV, g_pPercent
new g_iVotes

new gsz_Commands[][] = {
	"rtmv",
	"/rtmv",
	
	"rtv",
	"/rtm",
	
	"rockthevote",
	"/rockthevote",
	
	"rockthemodvote",
	"/rockthemodvote"
}	

new const PREFIX[] = "[Dubai-Gamerz]"

#if defined UNLIMITED_MODS
new gMenu

Build()
{
	gMenu = menu_create(g_menuname, "player_vote")

	new szItem[50], szInfo[10]
	for(new i=0; i<= g_modcount; i++)
	{	
		formatex(szInfo, charsmax(szInfo), "%d", i)
		
		if(i == g_currentmodid)
		{
			formatex(szItem, charsmax(szItem), "%s (Current Mod)", g_modnames[i])
			menu_additem(gMenu, szItem, szInfo, (1<<26))
		}
		
		else 	menu_additem(gMenu, g_modnames[i], szInfo)
	}
}
#endif

public plugin_init()
{
	new MenuName[63]
	
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("MultiModManager", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	register_dictionary("mapchooser.txt")
	register_dictionary("multimod.txt")

	gp_mode = register_cvar("amx_multimod_mode", "0")	// 0=auto ; 1=mapchooser ; 2=galileo

	get_configsdir(g_confdir, charsmax(g_confdir))
	
	register_clcmd("say nextmod", "user_nextmod")
	register_clcmd("say_team nextmod", "user_nextmod")
	register_clcmd("say currentmod", "user_currentmod")
	register_clcmd("say_team currentmod", "user_currentmod")
	
	new szCommand[50]
	for(new i; i < sizeof(gsz_Commands); i++)
	{
		formatex(szCommand, charsmax(szCommand), "say %s", gsz_Commands[i])
		register_clcmd(szCommand, "rock_modvote")
		formatex(szCommand, charsmax(szCommand), "say_team %s", gsz_Commands[i])
		register_clcmd(szCommand, "rock_modvote")
	}
	
	g_iStartSysTime = get_systime()
	g_pMins = register_cvar("mm_mins_for_rtmv", "10")
	g_pRTMV = register_cvar("mm_allow_rtmv", "1")
	g_pPercent = register_cvar("mm_rtmv_percent", "75")
	
	register_concmd("amx_votemod", "admin_check", ADMIN_MAP, "Vote for the next mod")
	register_concmd("amx_nextmod", "define_nextmod", ADMIN_RCON, "<Number of the mod> - Chooses the next mod")
	register_concmd("amx_cancelnextmod", "cancel_nextmod", ADMIN_RCON, "Cancels the defined next mod, and allows mod vote to run.")
	
	formatex(MenuName, charsmax(MenuName), "%L", LANG_PLAYER, "MM_VOTE")
	register_menucmd(register_menuid(g_menuname), 1023, "player_vote")
	
	#if !defined UNLIMITED_MODS
	g_coloredmenus = colored_menus()
	#endif
	
	set_task(random_float(45.0, 120.0), "show_hud", TASK_HUD, .flags = "b")
}

public plugin_cfg()
{
	gp_voteanswers = get_cvar_pointer("amx_vote_answers")
	gp_mapcyclefile = get_cvar_pointer(AMX_MAPCYCLE)

	if(!get_pcvar_num(gp_mode))
	{
		if(find_plugin_byfile("mapchooser_multimod.amxx") != -1)
			set_pcvar_num(gp_mode, 1)
		else if(find_plugin_byfile("galileo.amxx") != -1)
			set_pcvar_num(gp_mode, 2)
	}
	
	get_localinfo(AMX_MULTIMOD, g_multimod, charsmax(g_multimod))
	load_cfg()

	if(!equal(g_currentmod, g_multimod) || (g_multimod[0] == 0))
	{
		set_multimod(0)
		get_firstmap(0)
		server_print("Server restart - First Run")
		server_cmd("changelevel %s", g_nextmap)
	}
	else
	{
		server_cmd("exec %s", g_fileconf)
	}
	
	#if defined UNLIMITED_MODS
	Build()
	#endif
}

public load_cfg()
{
	new szData[LSTRING]
	new szFilename[LSTRING]

	formatex(szFilename, charsmax(szFilename), "%s/%s", AMX_BASECONFDIR, "multimod.ini")

	new f = fopen(szFilename, "rt")
	new szTemp[SSTRING],szModName[SSTRING], szTag[SSTRING], szCfg[SSTRING]
	while(!feof(f)) {
		fgets(f, szData, charsmax(szData))
		trim(szData)
		if(!szData[0] || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/')) continue

		if(szData[0] == '[') {
			g_modcount++
			replace_all(szData, charsmax(szData), "[", "")
			replace_all(szData, charsmax(szData), "]", "")

			strtok(szData, szModName, charsmax(szModName), szTemp, charsmax(szTemp), ':', 0)
			strtok(szTemp, szTag, charsmax(szTag), szCfg, charsmax(szCfg), ':', 0)

			if(equal(szModName, g_multimod)) {
				formatex(g_fileconf, 192, "%s/%s", AMX_BASECONFDIR, szCfg)
				copy(g_currentmod, charsmax(g_currentmod), szModName)
				g_currentmodid = g_modcount
				server_print("[AMX MultiMod] %L", LANG_PLAYER, "MM_WILL_BE", g_multimod, szTag, szCfg)
			}
			formatex(g_modnames[g_modcount], 32, "%s", szModName)
			formatex(g_filemaps[g_modcount], 192, "%s/%s-maps.ini", AMX_BASECONFDIR, szTag)
			formatex(g_fileplugins[g_modcount], 192, "%s/%s-plugins.ini", AMX_BASECONFDIR, szTag)
			server_print("MOD Loaded: %s %s %s", g_modnames[g_modcount], g_filemaps[g_modcount], g_fileconf)
			
			if(g_modcount == (MAXMODS - 1))
				break;
		}
	}
	fclose(f)
	set_task(1.0, "check_task", TASK_VOTEMOD, "", 0, "b")
}

public get_firstmap(modid)
{
	new ilen

	if(!file_exists(g_filemaps[modid]))
		get_mapname(g_nextmap, charsmax(g_nextmap))
	else	read_file(g_filemaps[modid], 0, g_nextmap, charsmax(g_nextmap), ilen)
}

public set_multimod(modid)
{
	server_print("Setting multimod to %i - %s", modid, g_modnames[modid])
	set_localinfo("amx_multimod", g_modnames[modid])
	//server_cmd("localinfo amxx_plugins ^"^"")
	//server_cmd("localinfo lastmapcycle ^"^"")
	set_localinfo("amxx_plugins", "")
	set_localinfo("lastmapcycle", "")
	
	set_localinfo(AMX_PLUGINS, file_exists(g_fileplugins[modid]) ? g_fileplugins[modid] : AMX_DEFAULTPLUGINS)
	set_localinfo(AMX_LASTCYCLE, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)
	set_pcvar_string(gp_mapcyclefile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)
	
	switch(get_pcvar_num(gp_mode))
	{
		case 2:
		{
			if(gp_galileo_nommapfile)
				set_pcvar_string(gp_galileo_nommapfile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)

			if(gp_galileo_votemapfile)
				set_pcvar_string(gp_galileo_votemapfile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)
		}
		case 1:
		{
			callfunc_begin("plugin_init", "mapchooser_multimod.amxx");
			callfunc_end();
		}
	}
}

public check_task()
{
	new timeleft = get_timeleft()
	if(timeleft < 1 || timeleft > 180)
	{
		if( 180 <= timeleft <= 195)
		{
			set_hudmessage(200, 100, 0,_,_, 0, 0.0, 1.1, 0.0, 0.0, -1)
			show_hudmessage(0, "Vote will start in %d seconds!", --g_iCount)
		}
		
		return;
	}

	start_vote()
}

public show_hud(iTaskID)
{
	set_hudmessage(0, 255, 255, 0.65, 0.15, 0, 6.0, 12.0)
	show_hudmessage(0, "Current Mod: %s^nNext mod: %s", g_modnames[g_currentmodid], g_nextmodid ? g_modnames[g_nextmodid] : "Not choosen yet.")
	
	if(get_pcvar_num(g_pRTMV))
	{
		static iNum
		iNum++
		
		if(iNum % 2)
		{
			#if defined COLORED
			ColorChat(0, BLUE, "%s ^4Type '^3rtmv^4' or '^3rtv^4'to rock the mod vote!", PREFIX)
			#else
			client_print(0, print_chat, "%s Type 'rtmv' or 'rtv' to rock the mod vote!", PREFIX)
			#endif
		}
		
		else
		{
			#if defined COLORED
			ColorChat(0, BLUE, "%s ^4Type '^3nextmod^4' to see the next mod. Type '^3currentmod^4' to see the current mod!", PREFIX)
			#else
			client_print(0, print_chat, "%s Type 'rtmv' or 'rtv' to rock the mod vote!", PREFIX)
			#endif
		}
	}
	
	#if defined COLORED
	else ColorChat(0, BLUE, "%s ^4Type '^3nextmod^4' to see the next mod. Type '^3currentmod^4' to see the current mod!", PREFIX)
	#else
	else client_print(id, print_chat, "%s Type 'nextmod' to see the next mod. Type 'currentmod' to see the current mod!", PREFIX)
	#endif
	
	change_task(TASK_HUD, random_float(45.0, 120.0))
}

public client_putinserver(id)
{
	if(is_user_bot(id))
		return;
	
	if(get_pcvar_num(g_pRTMV))
		g_iPlayersLeft = PlayersLeft(g_iVotes)
}

public client_disconnect(id)
{
	if(g_iHasRTMV[id] && get_pcvar_num(g_pRTMV))
	{
		g_iHasRTMV[id] = 0
		g_iPlayersLeft = PlayersLeft(--g_iVotes)
	}
}

public rock_modvote(id)
{
	if(!get_pcvar_num(g_pRTMV))
	{		
		#if defined COLORED
		ColorChat(id, BLUE, "%s ^4Rocking the mod vote is disabled at the moment.", PREFIX)
		#else 
		client_print(id, print_chat, "%s Rocking the mod vote is disabled at the moment.", PREFIX)
		#endif
		return PLUGIN_HANDLED
	}
	
	if( g_alreadyvoted )
	{
		#if defined COLORED
		ColorChat(id, BLUE, "%s ^4The mod vote is already running.", PREFIX)
		#else 
		client_print(id, print_chat, "%s The mod vote is already running.", PREFIX)
		#endif
		return PLUGIN_HANDLED
	}
	
	if( nextmodchoosed )
	{
		#if defined COLORED
		ColorChat(id, BLUE, "%s ^4An Admin has already chose the next mod. You can't rock the mod vote...", PREFIX)
		#else
		client_print(id, print_chat, "%s An Admin has already chose the next mod. You can't rock the mod vote...", PREFIX)
		#endif
		return PLUGIN_HANDLED
	}
	
	static iMinutes, iSecoundsLeft
	if(!Allow_RTMV(iMinutes, iSecoundsLeft))
	{
		#if defined COLORED
		ColorChat(id, BLUE, "%s ^4You need to wait ^3%d ^4minutes and ^3%d ^4seconds before you can rock the mod vote!", PREFIX, iMinutes, iSecoundsLeft)
		#else
		client_print(id, print_chat, "%s You need to wait %d minutes and %d secounds before you can rock the mod vote!", PREFIX, iMinutes, iSecoundsLeft)
		#endif
		return PLUGIN_HANDLED
	}
	
	if( g_iHasRTMV[id] )
	{
		#if defined COLORED
		
		ColorChat(id, BLUE, "%s ^4You have already rocked the mod!", PREFIX)
		ColorChat(id, BLUE, "%s ^3%d ^4players left to rock the mod vote!", PREFIX, g_iPlayersLeft)
		
		#else
		
		client_print(id, print_chat, "%s ^4You have already rocked the mod!", PREFIX)
		client_print(id, print_chat, "%s %d players left to rock the mod vote!", PREFIX, g_iPlayersLeft)
		
		#endif
		return PLUGIN_HANDLED
	}
	
	g_iPlayersLeft = PlayersLeft(++g_iVotes)
	g_iHasRTMV[id] = 1
		
	#if defined COLORED
	ColorChat(id, BLUE, "%s ^4You have rocked the mod vote!", PREFIX)
	
	if(!g_iPlayersLeft)
	{
		ColorChat(0, BLUE, "%s ^4Enough players have rocked the mod vote, vote will run in 5 secounds!", PREFIX)
		
		set_task(5.0, "start_vote")
		
		g_alreadyvoted = true
		
		return PLUGIN_HANDLED
	}
	
	ColorChat(0, BLUE, "%s ^3%d ^4players left to rock the mod vote!", PREFIX, g_iPlayersLeft)
	#else
	
	client_print(id, print_chat, "%s You have rocked the mod vote!", PREFIX)
	
	if(!g_iPlayersLeft)
	{
		client_print(0, print_chat, "%s Enough players have rocked the mod vote, vote will run in 5 secounds!", PREFIX)
		
		set_task(5.0, "start_vote")
		
		g_alreadyvoted = true
		
		return PLUGIN_HANDLED
	}
	
	client_print(0, print_chat, "%s %d players left to rock the mod vote!", PREFIX, g_iPlayersLeft)
	#endif
	
	return PLUGIN_CONTINUE
}

PlayersLeft(iCurrentVoteNum)
{
	return floatround( ( float( get_playersnum() ) * ( get_pcvar_float(g_pPercent) / 100.0 ) ) ) - iCurrentVoteNum;
}

Allow_RTMV(&iMin, &iSec)
{	
	new iNum = get_systime()
	
	if((g_iStartSysTime + ( get_pcvar_num(g_pMins) * 60 ) ) <= iNum)
		return 1

	iNum = (g_iStartSysTime + ( get_pcvar_num(g_pMins) * 60 ) ) - iNum
	iMin = (iNum / 60); iSec = (iNum % 60)
	return 0
}

public admin_check(id, level, cid)
{	
	if( !cmd_access(id, level, cid, 1) )
		return PLUGIN_HANDLED
		
	if( g_alreadyvoted )
	{
		console_print(id, "The Mod vote is already in progress")
		return PLUGIN_HANDLED
	}
	
	if(nextmodchoosed)
	{
		console_print(id, "An Admin has already choosen the next mod.")
		return PLUGIN_HANDLED
	}
	
	new fmt[200], szAdminName[32], authid[33], IP[14]//, szTime[50]
	
	//get_time("%m/%d/%Y - %H:%M:%S", szTime, 49)
	get_user_name(id, szAdminName, 31)
	get_user_authid(id, authid, 32)
	get_user_ip(id, IP, 13, 1)
	
	formatex(fmt, 199, "Admin %s <%s> [%s] Started Mod Vote!", szAdminName, authid, IP)
	//server_print(fmt)
	log_amx(fmt)
	
	#if defined COLORED
	ColorChat(0, GREEN, "%s ^1ADMIN ^3%s: ^4Start mod vote!", PREFIX, szAdminName)
	#else
	client_print(0, print_chat, "%s ADMIN %s: Start mod vote!", PREFIX, szAdminName)
	#endif
	
	console_print(id, "You have started the mod vote")
	start_vote()
	
	return PLUGIN_HANDLED
}

public define_nextmod(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	/*if( (get_cvar_num("mp_timelimit") * 60) - get_timeleft() > get_pcvar_num(g_pMinsMustPass) * 60)
	{
		console_print(id, "10 minutes must pass before selecting the next mod")
		return PLUGIN_HANDLED
	}*/
	
	if( nextmodchoosed || g_alreadyvoted )
	{
		console_print(id, "The next mod has been already choosen or he vote is already in progress")
		return PLUGIN_HANDLED
	}
	
	if(read_argc() == 1)
	{
		console_print(id, "Listing mods:")
		console_print(id, "#  %s", "Mod Name")
		
		for(new i; i <= g_modcount; i++)
		{
			console_print(id, "%d  %s", i + 1, g_modnames[i])
		}
		
		return PLUGIN_HANDLED
	}
	
	new arg1[3]
	read_argv(1, arg1, 2)
	
	if(!is_str_num(arg1))
	{
		console_print(id, "That is not a mod number -.-'' !")
		return PLUGIN_HANDLED
	}
	
	new _modnum = str_to_num(arg1)
	_modnum = _modnum - 1
	
	if( !( 0 <= _modnum <=  g_modcount) )
	{
		console_print(id, "That is not a valid mod number!")
		return PLUGIN_HANDLED
	}
	
	if( _modnum == g_currentmodid )
	{
		console_print(id, "You can't choose the current mod!")
		return PLUGIN_HANDLED
	}
	
	console_print(id, "You have choosed number %d which is %s", _modnum + 1, g_modnames[_modnum])
	
	set_multimod(_modnum)
	
	new name[32]
	get_user_name(id, name, 31)
	
	g_nextmodid = _modnum
	
	#if defined COLORED
	ColorChat(0, BLUE, "%s ^4Admin ^3%s ^4choosed the next mod, it will be: ^3%s", PREFIX, name, g_modnames[g_nextmodid])
	#else
	client_print(0, print_chat, "%s Admin %s ^4choosed the next mod, it will be: %s", PREFIX, name, g_modnames[g_nextmodid])
	#endif
	
	nextmodchoosed = true
	
	return PLUGIN_HANDLED
}

public cancel_nextmod(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	if(g_alreadyvoted)
	{
		console_print(id, "Too late to cancel the next mod. The mod vote is already running.")
		return PLUGIN_HANDLED
	}
	
	if( !nextmodchoosed )
	{
		console_print(id, "Next mod has not been choosen to be canceled.")
		return PLUGIN_HANDLED
	}
	
	nextmodchoosed = false
	g_nextmodid = 0
	set_multimod(g_currentmodid)
	
	new szName[32]; get_user_name(id, szName, charsmax(szName))
	
	#if defined COLORED
	ColorChat(0, BLUE, "%s ^4Admin ^3%s has canceled the next mod force.", PREFIX, szName)
	#else
	client_print(0, print_chat, "[AMXX] Admin %s has canceled the next mod force.", PREFIX, szName)
	#endif
	
	console_print(id, "You have successfully canceled the next mod.")
	return PLUGIN_HANDLED
}

public start_vote()
{
	remove_task(TASK_VOTEMOD)
	remove_task(TASK_CHVOMOD)
	
	if(nextmodchoosed)
	{
		//set_multimod(g_nextmodid)
		
		#if defined COLORED
		ColorChat(0, BLUE, "%s ^4Since Admins has choosed the next mod, skipping to map vote immediately.", PREFIX)
		#else
		client_print(0, print_chat, "%s Since Admins has choosed the next mod, skipping to map vote immediately.", PREFIX)
		#endif
		
		callfunc_begin("doVoteNextmap", "mapchooser_multimod.amxx");
		callfunc_end();
		
		return;
	}
	
	server_print("Voting for the next Mod has started!")
	g_alreadyvoted = true

	#if defined UNLIMITED_MODS
	arrayset(g_votemodcount, sizeof(g_votemodcount), 0)
	
	client_cmd(0, "spk Gman/Gman_Choose2")
	
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "ch")
	
	for(new i; i < iNum; i++)
		menu_display(iPlayers[i], gMenu)

	set_task(VOTE_TIME, "check_vote", TASK_CHVOMOD)
	#else
	
	new menu[512], mkeys, i
	new pos = format(menu, 511, g_coloredmenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_PLAYER, "MM_CHOOSE")

	for(i=0; i<= g_modcount; i++)
	{
		if(i != g_currentmodid)
		{
			pos += format(menu[pos], 511, "%d. %s^n", i + 1, g_modnames[i])
			g_votemodcount[i] = 0
			mkeys |= (1<<i)
		}
	}
	
	new szMenuName[63]
	formatex(szMenuName, charsmax(szMenuName), "%L", LANG_PLAYER, "MM_VOTE")
	show_menu(0, mkeys, menu, 15, g_menuname)
	client_cmd(0, "spk Gman/Gman_Choose2")

	set_task(15.0, "check_vote", TASK_CHVOMOD)
	#endif
	return
}

public user_nextmod(id)
{
	if(nextmodchoosed)
	#if defined COLORED
		ColorChat(id, GREEN, "The next mod is %s", g_modnames[g_nextmodid])
	#else
		client_print(id, print_chat, "%L", LANG_PLAYER, "MM_NEXTMOD", g_modnames[g_nextmodid])
	#endif
		
	else
	#if defined COLORED
		ColorChat(id, GREEN, "No mod has been choosed yet.")
	#else
		client_print(id, "No mod has been choosed yet.")
	#endif
	
	return PLUGIN_CONTINUE
}

public user_currentmod(id)
{
	#if defined COLORED
	ColorChat(id, GREEN, "%s ^4The current mod is: %s", PREFIX, g_modnames[g_currentmodid])
	#else
	ColorChat(id, GREEN, "%s The current mod is: %s", PREFIX, g_modnames[g_currentmodid])
	#endif
	
	return PLUGIN_CONTINUE
}

#if defined UNLIMITED_MODS
public player_vote(id, menu, item)
{
	if(item < 0)
	{
		return;
	}
	
	static szInfo[10], key, icallback
	if(get_pcvar_num(gp_voteanswers))
	{
		
		new player[SSTRING]
		get_user_name(id, player, charsmax(player))
			
		menu_item_getinfo(menu, item, key, szInfo, charsmax(szInfo), .callback = icallback)
		
		key = str_to_num(szInfo)

		#if defined COLORED
		ColorChat(0, get_user_team(id) == 1 ? RED : BLUE, "%s ^1chose ^4%s", player, g_modnames[key])
		#else
		client_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", player, g_modnames[key])
		#endif
	}
	g_votemodcount[key]++
}
#else
public player_vote(id, key)
{
	if(key <= g_modcount)
	{
		if(get_pcvar_num(gp_voteanswers))
		{
			new player[SSTRING]
			get_user_name(id, player, charsmax(player))
			
			#if defined COLORED
			ColorChat(0, get_user_team(id) == 1 ? RED : BLUE, "%s ^1chose ^4%s", player, g_modnames[key])
			#else
			client_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", player, g_modnames[key])
			#endif
		}
		g_votemodcount[key]++
	}
}
#endif

public check_vote()
{
	new b = 0
	for(new a = 0; a <= g_modcount; a++)
		if(g_votemodcount[b] < g_votemodcount[a]) b = a

	client_print(0, print_chat, "%L", LANG_PLAYER, "MM_VOTEMOD", g_modnames[b])
	server_print("%L", LANG_PLAYER, "MM_VOTEMOD", g_modnames[b])
	if(b != g_currentmodid)
		set_multimod(b)

	callfunc_begin("doVoteNextmap", "mapchooser_multimod.amxx");
	callfunc_end();
	g_nextmodid = b
}
                                                                                     