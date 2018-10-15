#include <amxmodx>
#include <amxmisc>

#define COLORED

#define SHOW_VOTE_PERCENT
//#define SHOW_PERCENT_AFTER_CHOOSING		// still under work

// Not done yet.
#if defined RECENT_MODS
	#define MAX_RECENT_MODS			5
#endif

#if defined COLORED
	#include <colorchat>
#endif

// For unlimited Mods xD easy way than using an cell array :D
#define MAXMODS 200

// Galileo Support?
//#define GALILEO_SUPPORT

// Add Natives?
#define MM_NATIVES

// Only check this if you want to use my mapchooser edition.
//#define EDITED_MAPCHOOSER

#if defined GALILEO_SUPPORT
new const GALILEO_PLUGIN[] = "galileo.amxx"
#else
new const MAPCHOOSER_PLUGIN[] = "mapchooser_multimod.amxx"
#endif

new g_iCount = 16

#define PLUGIN_NAME			"MultiMod Manager"
#define PLUGIN_AUTHOR			"Khalid & JoRoPiTo"
#define PLUGIN_VERSION			"3.1"

#define AMX_MULTIMOD			"amx_multimod"
#define AMX_PLUGINS			"amxx_plugins"
#define AMX_MAPCYCLE			"mapcyclefile"
#define AMX_LASTCYCLE			"lastmapcycle"

#define AMX_DEFAULTCYCLE		"mapcycle.txt"
#define AMX_DEFAULTPLUGINS		"addons/amxmodx/configs/plugins.ini"
#define AMX_BASECONFDIR			"multimod"

#define TASK_VOTEMOD 			2487002
#define TASK_CHVOMOD 			2487004
#define TASK_COUNTDOWN 			68784
#define TASK_HUD 			17261

#define LSTRING 			193
#define SSTRING 			33

#if defined SHOW_VOTE_PERCENT
new g_iHasVoted[33]
#endif
new g_iVoteTime

#if defined RECENT_MODS
new g_iRecentModsCount
new g_szRecentMods[MAX_RECENT_MODS][LSTRING]
#endif

new bool:g_bVoteEnded = false

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

new gp_mapcyclefile

// galileo specific cvars
#if defined GALILEO_SUPPORT
new gp_galileo_nommapfile
new gp_galileo_votemapfile
#endif

enum _:TIME_BLOCK
{
	TB_HOUR,
	TB_MINUTE
};

new g_iTimeBlock[MAXMODS][TIME_BLOCK];

// Admin next mod
new bool:nextmodchoosed = false

new g_iAdminVote = 0

// Rock the mod vote...
new g_iHasRTMV[33], g_iPlayersLeft
new g_iStartSysTime
new g_pMins, g_pRTMV, g_pPercent
new g_iVotes

#define HEAD_FLAG ADMIN_RCON
new g_iNextModByHead

/*enum _:TIMES
{
	START,
	END
}

//new g_iModTimeBlock[MAXMODX][TIMES]*/

new gsz_Commands[][] = {
	"rtmv",
	"/rtmv",
	
	"rtv",
	"/rtv",
	
	"rockthevote",
	"/rockthevote",
	
	"rockthemodvote",
	"/rockthemodvote"
}

new const PREFIX[] = "[Elektro-MM]"
new g_pVoteTime, g_pRunOffVote

new gSyncHud

new gMenu
new g_pMM_Menu

#if defined SHOW_VOTE_PERCENT
	#if defined SHOW_PERCENT_AFTER_CHOOSING
		new gPercentMenu
	#endif
#endif

new g_iMainMM_Menu
new g_iChooseNextModMenu
new g_iBlockModMenu

new g_iModBlocked[MAXMODS] = 0, g_iBlockedModsAmount = -1
new g_iBlocked[33] = 0

enum _:MAIN_MENU_ITEMS
{
	BLOCK_MOD,
	CHOOSE_NEXT_MOD,
	CANCEL_NEXT_MOD
}

Build()
{ 
	gMenu = menu_create(g_menuname, "player_vote")
	#if defined SHOW_VOTE_PERCENT
		#if defined SHOW_PERCENT_AFTER_CHOOSING
		gPercentMenu = menu_create(g_menuname, "menu_handler_dump")
		#else
		new iCallBack = menu_makecallback("menu_voteCallBack")
		#endif
	#endif

	new szItem[50], szInfo[10]
	
	#if defined SHOW_VOTE_PERCENT
	new szPercentModName[SSTRING]
	#endif
	
	for(new i=0; i <= g_modcount; i++)
	{	
		formatex(szInfo, charsmax(szInfo), "%d", i)
		
		if(i == g_currentmodid)
		{
			formatex(szItem, charsmax(szItem), "%s (Current Mod)", g_modnames[i])
			menu_additem(gMenu, szItem, szInfo, (1<<26))
			
			#if defined SHOW_VOTE_PERCENT
				#if defined SHOW_PERCENT_AFTER_CHOOSING
				menu_additem(gPercentMenu, szItem, szInfo, (1<<26))
				#endif
			#endif
		}
		
		else 
		{
			#if defined SHOW_VOTE_PERCENT
			formatex(szPercentModName, charsmax(szPercentModName), "%s (0%%)", g_modnames[i])
				#if defined SHOW_PERCENT_AFTER_CHOOSING
				menu_additem(gPercentMenu, szPercentModName, szInfo, (1<<26))
				#else
				menu_additem(gMenu, szPercentModName, szInfo, .callback = iCallBack)
				#endif
			#else
			menu_additem(gMenu, szItem, szInfo)
			#endif
		}
	}
	
	new iMenuCallBack = menu_makecallback("MainMenuCallBack")
	g_iMainMM_Menu = menu_create("Multimod Menu^nBy Khalid :)", "MainMenuHandler")
	
	{
		menu_additem(g_iMainMM_Menu, "Block a mod from being choosed at the vote"/*, .callback = iMenuCallBack*/)
		formatex(szItem, charsmax(szItem), "Choose Next Mod \y[\r%s\y]", nextmodchoosed ? "Already Chosen" : "Not Chosen")
		menu_additem(g_iMainMM_Menu, szItem, .callback = iMenuCallBack)
		menu_additem(g_iMainMM_Menu, "Cancel Nextmod choosed", .callback = iMenuCallBack)
	}
	
	new iNextModCallBack = menu_makecallback("ChooseNextModCallBack")
	g_iChooseNextModMenu = menu_create("Choose the next mod", "ChooseNextModHandler")
	
	new iBlockModCallBack = menu_makecallback("BlockModCallBack")
	g_iBlockModMenu = menu_create("Choose a mod to block/Unblock", "BlockModMenu")
	
	for(new i; i <= g_modcount; i++)
	{
		if(i == g_currentmodid)
		{
			formatex(szItem, charsmax(szItem), "%s (Current Mod)", g_modnames[i])
			menu_additem(g_iChooseNextModMenu, szItem,_, 1<<26)
			menu_additem(g_iBlockModMenu, szItem,_, 1<<26)
		}
		
		else
		{
			menu_additem(g_iChooseNextModMenu, g_modnames[i],_, .callback = iNextModCallBack)
			
			formatex(szItem, charsmax(szItem), "%s \y[\rNot Blocked\y]", g_modnames[i])
			menu_additem(g_iBlockModMenu, szItem, .callback = iBlockModCallBack)
		}
	}
}

public BlockModCallBack(id, menu, item)
{
	if(g_iBlocked[id])
	{
		return ITEM_DISABLED
	}
	
	return ITEM_ENABLED
}

public MainMenuCallBack(id, menu, item)
{
	if(g_iBlocked[id] && item != CHOOSE_NEXT_MOD)
	{
		return ITEM_DISABLED
	}
	
	switch(item)
	{
		case CANCEL_NEXT_MOD:
		{
			if(nextmodchoosed)
			{
				return ITEM_ENABLED
			}
		
			return ITEM_DISABLED
		}
		
		case CHOOSE_NEXT_MOD:
		{
			if(nextmodchoosed)
			{
				return ITEM_DISABLED
			}
			
			if(g_alreadyvoted)
			{
				return ITEM_DISABLED
			}
			
			return ITEM_ENABLED
		}
	}
	
	return ITEM_ENABLED
}

public ChooseNextModCallBack(id, menu, item)
{
	if(g_iBlocked[id])
	{
		return ITEM_DISABLED
	}
	
	return ITEM_ENABLED
}

public MainMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	switch(item)
	{
		case BLOCK_MOD:
		{
			menu_display(id, g_iBlockModMenu)
		}
		
		case CHOOSE_NEXT_MOD:
		{
			if(nextmodchoosed)
			{
				menu_display(id, menu)
			}
			
			else
			{
				menu_display(id, g_iChooseNextModMenu)
			}
		}
		
		case CANCEL_NEXT_MOD:
		{
			if(!nextmodchoosed)
			{
				menu_display(id, menu)
			}
			
			if(CancelNextMod(id))
			{
				menu_item_setname(menu, CHOOSE_NEXT_MOD, "Choose Next Mod \y[\rNot Chosen\y]")
			}
		}
	}
}

public ChooseNextModHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
		
	if(g_alreadyvoted)
	{
		client_print(id, print_chat, "** The mod vote has already started!")
		client_print(id, print_center, "** The mod vote has already started!")
		return;
	}
	
	if(nextmodchoosed)
	{
		client_print(id, print_chat, "** The next mod has been already choosen")
		client_print(id, print_center, "** The next mod has been already choosen")
		return;
	}
	
	ChooseNextMod(id, item)
	menu_item_setname(g_iMainMM_Menu, CHOOSE_NEXT_MOD, "Choose Next Mod \y[\rAlready Chosen\y]")
}

public BlockModMenu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	g_iModBlocked[item] = !g_iModBlocked[item]
	
	new szItem[50], szStatus[] = "UNBLOCKED"
	
	if(g_iModBlocked[item])
	{
		formatex(szItem, charsmax(szItem), "%s \y[\rBlocked\y]", g_modnames[item])
		g_iBlockedModsAmount++
		
		szStatus = "BLOCKED"
	}
	
	else
	{
		formatex(szItem, charsmax(szItem), "%s \y[\rNot Blocked\y]", g_modnames[item])
		g_iBlockedModsAmount--
		
		szStatus = "UNBLOCKED"
	}
	
	if( g_iBlockedModsAmount == ( g_modcount - 1 ) )
	{
		g_iModBlocked[item] = !g_iModBlocked[item]
		g_iBlockedModsAmount--
		
		client_print(id, print_chat, "** You need atleast one mod not blocked to be choosed in the vote!")
		menu_display(id, menu)
		return;
	}
	
	new szName[32]; get_user_name(id, szName, charsmax(szName))
	
	#if defined COLORED
	ColorChat(0, BLUE, "%s ^4Admin ^3%s ^4has ^3%s ^4the mod ^1'^3%s^1' ^4from being choosed in the vote.", PREFIX, szName, g_modnames[item], szStatus)
	#else
	client_print(0, print_chat, "%s Admin %s has %s the mod '%s' from being choosed in the mod vote.", PREFIX, szName, g_modnames[item], szStatus)
	#endif
	
	menu_item_setname(menu, item, szItem)
	
	new iDump, iPage
	player_menu_info(id, iDump, iDump, iPage)
	menu_display(id, menu, iPage)
}	

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	
	//register_cvar("MultiModManager", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	
	register_dictionary("mapchooser.txt")
	register_dictionary("multimod.txt")

	get_configsdir(g_confdir, charsmax(g_confdir))
	
	register_clcmd("say nextmod", "user_nextmod")
	register_clcmd("say_team nextmod", "user_nextmod")
	register_clcmd("say currentmod", "user_currentmod")
	register_clcmd("say_team currentmod", "user_currentmod")
	
	#if defined RECENT_MODS
	register_clcmd("say recentmods", "CmdRecentMods")
	register_clcmd("say /recentmods", "CmdRecentMods")
	register_clcmd("say /recent", "CmdRecentMods")
	#endif
	
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
	g_pVoteTime = register_cvar("mm_vote_time", "30")
	g_pMM_Menu = register_cvar("mm_allow_menu_access", "1")
	g_pRunOffVote = register_cvar("mm_allow_runoff_vote", "1")
	
	if(!cvar_exists("amx_gamename"))
	{
		register_cvar("amx_gamename", "Counter-Strike");
	}
	
	register_concmd("amx_votemod", "admin_check", ADMIN_MAP, "Vote for the next mod")
	register_concmd("amx_nextmod", "define_nextmod", ADMIN_BAN, "<Number of the mod> - Chooses the next mod")
	register_concmd("amx_cancelnextmod", "cancel_nextmod", ADMIN_BAN, "Cancels the defined next mod, and allows mod vote to run.")
	
	register_clcmd("say /mm_menu", "AdminCmdMM_Menu", ADMIN_BAN)
	register_clcmd("say /mods", "CmdMods");
	
	gSyncHud = CreateHudSyncObj()
	
	set_task(random_float(45.0, 120.0), "show_hud", TASK_HUD, .flags = "b")
	plugin_cfg_execute()
}

public CmdMods(id)
{
	console_print(id, "------------------------------");
	console_print(id, "Available mods in Server are:");
	console_print(id, "------------------------------");
	
	for(new i; i <= g_modcount; i++)
	{
		console_print(id, "%i. %s", i + 1, g_modnames[i]);
	}
	
	console_print(id, "------------------------------");
	console_print(id, "------------------------------");
	
	#if defined COLORED
	ColorChat(id, BLUE, "%s ^4Check your console for all available ^3MODs ^4in server.", PREFIX)
	#else
	client_print(id, print_chat, "%s Check your console for all available MODs in server.", PREFIX)
	#endif
}

#if defined MM_NATIVES
public plugin_natives()
{
	register_native("mm_get_current_mod", "native_get_current_mod", 1);
	register_native("mm_get_next_mod", "native_get_next_mod", 1);
}

public native_get_current_mod(szModName[], iLen)
{
	param_convert(1);
	
	copy(szModName, iLen, g_modnames[g_currentmodid]);
	
	return g_currentmodid;
}

public native_get_next_mod(szModName[], iLen)
{
	param_convert(1);
	
	copy(szModName, iLen, g_modnames[g_nextmodid]);
	
	return g_nextmodid;
}
#endif

#if defined RECENT_MODS
public GetRecentMaps()
{
	gRecentMods = TrieCreate()
	get_configsdir(g_szRecentModsFile, charsmax(g_szRecentModsFile))
	
	add(g_szRecentModsFile, charsmax(g_szRecentModsFile), "/recentmods.ini")
	
	new f = fopen(g_szRecentModsFile, "a+")
	new iSysTime = get_systime()
	new iTimeStamp
	
	if(!f)
	{
		return;
	}
	
	new szLine[70], iModNum
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		trim(szLine)
		
		//parse(szLine, szModPrefix, charsmax(szModPrefix), szTimeStamp, charsmax(szTimeStamp))
		
		iModNum = GetModNum(szLine)
		g_iRecentMods[g_iRecentModsCount++] = 
	}
	
}
#endif

public plugin_cfg_execute()
{
	gp_voteanswers = get_cvar_pointer("amx_vote_answers")
	gp_mapcyclefile = get_cvar_pointer(AMX_MAPCYCLE)
	
	#if defined GALILEO_SUPPORT
	gp_galileo_votemapfile = get_cvar_pointer("gal_vote_mapfile")
	gp_galileo_nommapfile = get_cvar_pointer("gal_nom_mapfile")
	#endif
	
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
		set_task(0.5, "ExecCfg");
	}
	
	Build()
	
	#if defined RECENT_MODS
	GetRecentMaps()
	#endif
}

public ExecCfg()
{
	server_cmd("exec %s", g_fileconf)
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
			
			server_print("MOD Loaded: %s %s %s", g_modnames[g_modcount], g_filemaps[g_modcount], szCfg)
			
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

	#if defined GALILEO_SUPPORT
	if(gp_galileo_nommapfile)
		set_pcvar_string(gp_galileo_nommapfile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)
	
	if(gp_galileo_votemapfile)
		set_pcvar_string(gp_galileo_votemapfile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)
	#else
	
		#if defined EDITED_MAPCHOOSER
			callfunc_begin("CheckMapsFile", "mapchooser_multimod.amxx");
		#else
			callfunc_begin("plugin_init", "mapchooser_multimod.amxx");
		#endif
		
	callfunc_end();
	#endif
}

public check_task()
{
	new timeleft = get_timeleft()
	if(timeleft < 1 || timeleft > 180)
	{
		if( 180 <= timeleft <= 195)
		{
			set_hudmessage(200, 100, 0,_,_, 0, 0.0, 1.1, 0.0, 0.0, -1)
			ShowSyncHudMsg(0, gSyncHud, "Vote will start in %d seconds!", --g_iCount)
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
	else client_print(0, print_chat, "%s Type 'nextmod' to see the next mod. Type 'currentmod' to see the current mod!", PREFIX)
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

public AdminCmdMM_Menu(id, level, cid)
{
	if(!get_pcvar_num(g_pMM_Menu))
	{
		#if defined COLORED
		ColorChat(id, BLUE, "%s ^4Sorry, but the menu is disabled right now. Please use commands instead.", PREFIX)
		#else
		client_print(id, print_chat, "%s Sorry, but the menu is disabled right now. Please use commands instead.", PREFIX)
		#endif
		
		return PLUGIN_HANDLED
	}
	
	if( !(get_user_flags(id) & level) )
	{
		g_iBlocked[id] = 1
	}
	
	else
	{
		g_iBlocked[id] = 0
	}
	
	menu_display(id, g_iMainMM_Menu)
	return PLUGIN_CONTINUE
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
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "ch")
	return floatround( ( float( iNum ) * ( get_pcvar_float(g_pPercent) / 100.0 ) ) ) - iCurrentVoteNum;
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
	
	/*if(nextmodchoosed)
	{
		console_print(id, "An Admin has already choosen the next mod.")
		return PLUGIN_HANDLED
	}*/
	
	new fmt[200], szAdminName[32], authid[33], IP[14]//, szTime[50]
	
	//get_time("%m/%d/%Y - %H:%M:%S", szTime, 49)
	get_user_name(id, szAdminName, 31)
	get_user_authid(id, authid, 32)
	get_user_ip(id, IP, 13, 1)
	
	formatex(fmt, 199, "Admin %s <%s> [%s] Started Mod Vote!", szAdminName, authid, IP)
	//server_print(fmt)
	log_amx(fmt)
	
	#if defined COLORED
	ColorChat(0, 0, "%s ^1ADMIN ^3%s: ^4Start mod vote!", PREFIX, szAdminName)
	#else
	client_print(0, print_chat, "%s ADMIN %s: Start mod vote!", PREFIX, szAdminName)
	#endif
	
	g_iAdminVote = 1
	
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
	
	ChooseNextMod(id, _modnum)

	return PLUGIN_HANDLED
}

stock ChooseNextMod(id, iModNum)
{	
	set_multimod(iModNum)
	g_nextmodid = iModNum
	nextmodchoosed = true
	
	new name[32]
	get_user_name(id, name, 31)
	
	g_iNextModByHead = !!( get_user_flags(id) & HEAD_FLAG )
	
	#if defined COLORED
	ColorChat(0, BLUE, "%s ^4Admin ^3%s ^4choosed the next mod, it will be: ^3%s", PREFIX, name, g_modnames[g_nextmodid])
	#else
	client_print(0, print_chat, "%s Admin %s ^4choosed the next mod, it will be: %s", PREFIX, name, g_modnames[g_nextmodid])
	#endif
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
	
	CancelNextMod(id)
	return PLUGIN_HANDLED
}

stock CancelNextMod(id)
{
	if(g_iNextModByHead && !(get_user_flags(id) & HEAD_FLAG))
	{
		console_print(id,  "This mod was choosed by a head admin. You can't cancel it.");
		
		
		#if defined COLORED
		ColorChat(id, BLUE, "%s ^4This mod was choosed by a head admin. You can't cancel it.", PREFIX)
		#else
		client_print(id, print_chat, "%s This mod was choosed by a head admin. You can't cancel it.", PREFIX)
		#endif
		
		return 0;
	}
	
	nextmodchoosed = false
	g_nextmodid = 0
	set_multimod(g_currentmodid)
	
	new szName[32]; get_user_name(id, szName, charsmax(szName))
	
	#if defined COLORED
	ColorChat(0, BLUE, "%s ^4Admin ^3%s has canceled the next mod force.", PREFIX, szName)
	#else
	client_print(0, print_chat, "%s Admin %s has canceled the next mod force.", PREFIX, szName)
	#endif
	
	console_print(id, "You have successfully canceled the next mod.")
	return 1;
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
		/*
		#if defined GALILEO_SUPPORT
		
		#else
		callfunc_begin("doVoteNextmap", "mapchooser_multimod.amxx");
		callfunc_push_int(g_iAdminVote)
		callfunc_end();
		#endif*/
		
		StartMapVote();
		
		return;
	}
	
	server_print("Voting for the next Mod has started!")
	g_bVoteEnded = false
	g_alreadyvoted = true
	
	arrayset(g_votemodcount, sizeof(g_votemodcount), 0)

	new szTitle[60], Float:flVoteTime
	g_iVoteTime = floatround( ( flVoteTime = get_pcvar_float( g_pVoteTime ) ) )
	
	formatex(szTitle, charsmax(szTitle), "%s^n\wTime Remaining: \y%d", g_menuname, g_iVoteTime)
	menu_setprop(gMenu, MPROP_TITLE, szTitle)
	
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "ch")
	
	for(new i; i < iNum; i++)
	{
		menu_display(iPlayers[i], gMenu)
	}
	
	set_task(1.0, "VoteTimeDecrementInMenu", 0,_,_,  "a", g_iVoteTime)
	
	client_cmd(0, "spk Gman/Gman_Choose2")
	set_task(flVoteTime, "check_vote", TASK_CHVOMOD)
}

public VoteTimeDecrementInMenu()
{
	g_iVoteTime--
	static szMenuName[60]
	formatex(szMenuName, charsmax(szMenuName), "%s^n\wTime Remaining: \y%d", g_menuname, g_iVoteTime)
	
	menu_setprop(gMenu, MPROP_TITLE, szMenuName)
	#if defined SHOW_PERCENT_AFTER_CHOOSING
	menu_setprop(gPercentMenu, MPROP_TITLE, szMenuName)
	#endif
	
	new iPlayers[32], iNum, iPlayer, iDump, iMenu, iPage
	get_players(iPlayers, iNum, "ch")
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		player_menu_info(iPlayer, iDump, iMenu, iPage)
		
		#if defined SHOW_PERCENT_AFTER_CHOOSING
		if(iMenu == gMenu || iMenu == gPercentMenu)
		#else
		if(iMenu == gMenu)
		#endif
		{
			menu_display(iPlayer, iMenu, iPage)
		}
	}
}		

public user_nextmod(id)
{
	if(nextmodchoosed)
	#if defined COLORED
		ColorChat(id, 0, "The next mod is %s", g_modnames[g_nextmodid])
	#else
		client_print(id, print_chat, "%L", LANG_PLAYER, "MM_NEXTMOD", g_modnames[g_nextmodid])
	#endif
		
	else
	#if defined COLORED
		ColorChat(id, 0, "No mod has been choosed yet.")
	#else
		client_print(id, print_chat, "No mod has been choosed yet.")
	#endif
	
	return PLUGIN_CONTINUE
}

public user_currentmod(id)
{
	#if defined COLORED
	ColorChat(id, 0, "%s ^4The current mod is: %s", PREFIX, g_modnames[g_currentmodid])
	#else
	client_print(id, print_chat, "%s The current mod is: %s", PREFIX, g_modnames[g_currentmodid])
	#endif
	
	return PLUGIN_CONTINUE
}

public player_vote(id, menu, item)
{
	#if defined SHOW_VOTE_PERCENT
	if(item < 0 || g_bVoteEnded || g_iHasVoted[id])
	#else
	if(item < 0 || g_bVoteEnded)
	#endif
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
	
	#if defined SHOW_VOTE_PERCENT
	g_iHasVoted[id] = 1
	UpdateMenuPercent(item, key)
	#endif
}

public menu_voteCallBack(id, menu, item)
{
	static szItem[50]
	if(g_iModBlocked[item])
	{
		formatex(szItem, charsmax(szItem), "%s (BLOCKED)", g_modnames[item])
		menu_item_setname(menu, item, szItem)
		return ITEM_DISABLED
	}
	
	#if defined SHOW_VOTE_PERCENT
	if(!g_iHasVoted[id])
	{
		return ITEM_ENABLED
	}
	#endif
	return ITEM_DISABLED
}

#if defined SHOW_VOTE_PERCENT
stock UpdateMenuPercent(iItem, iModNum)
{
	static iPlayers[32], iNum, szNewName[SSTRING]
	get_players(iPlayers, iNum, "ch")
			
	new iPercent = (g_votemodcount[iModNum] * 100) / iNum

	formatex(szNewName, charsmax(szNewName), "%s (%d%%)", g_modnames[iModNum], iPercent)
	
	#if defined SHOW_PERCENT_AFTER_CHOOSING
	menu_item_setname(gPercentMenu, iItem, szNewName)
	#else
	menu_item_setname(gMenu, iItem, szNewName)
	#endif
	
	new iDump, menu, iPage
	for(new i; i < iNum; i++)
	{
		player_menu_info(iPlayers[i], iDump, menu, iPage)
		#if defined SHOW_PERCENT_AFTER_CHOOSING
		if(!g_iHasVoted[iPlayers[i]])
		{
			continue;
		}

		menu_display(iPlayers[i], gPercentMenu, menu == gMenu ? iPage : 0)
		#else
		menu_display(iPlayers[i], gMenu, menu == gMenu ? iPage : 0)
		#endif
	}
}
#endif

#if defined SHOW_VOTE_PERCENT
public menu_handler_dump(id, menu, item)
{
	
}
#endif

public check_vote()
{	
	menu_destroy(gMenu)
	#if defined SHOW_VOTE_PERCENT
		#if defined SHOW_PERCENT_AFTER_CHOOSING
			menu_destroy(gPercentMenu)
		#endif
	#endif
	
	client_cmd(0, "slot10")
	
	new b, c, a, iTotalVotes
	for(a = 0; a <= g_modcount; a++)
	{
		iTotalVotes += g_votemodcount[a]
		/*if(b != a && g_votemodcount[b] <= g_votemodcount[a])
		{ 
			c = b
			b = a
		}*/
		
		if( g_votemodcount[b] <= g_votemodcount[a] )
		{
			c = b
			b = a
		}
		
		else if(g_votemodcount[c] <= g_votemodcount[a])
		{
			c = a
		}
	}
	
	if(!g_votemodcount[b])
	{
		b = random_num(0, g_modcount)
	}
	
	new iRunOffMods[2]
	
	// Run voting off ..
	if(!get_pcvar_num(g_pRunOffVote))
	{
		g_bVoteEnded = true
		SetNextModFromVote(b);
		return;
	}
	
	if(g_votemodcount[b] && g_votemodcount[b] <= ( iTotalVotes / 2 ) )
	{
		client_cmd(0, "spk ^"run officer(e40) voltage(e30) accelerating(s70) is required^"")
		iRunOffMods[0] = b
		iRunOffMods[1] = c
		
		set_hudmessage(0, 255, 0, -1.0, 0.20, 0, 0.0, 5.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(0, gSyncHud, "Running off voting as no mod has recevied over 50%% of the votes^nNew vote will start in 5 seconds!^n^nThe mods will be %s and %s", g_modnames[b], g_modnames[c])

		
		set_task(5.0, "RunOffVote", 0, iRunOffMods, 2)
		return;
	}
	
	// Else start map vote for new mod.
	g_bVoteEnded = true
	SetNextModFromVote(b)
}

public RunOffVote(iParams[])
{
	new szTitle[60];
	new Float:flTime
	formatex(szTitle, charsmax(szTitle), "%s^nTime remaining: %d", g_menuname, ( g_iVoteTime = floatround( ( flTime = get_pcvar_float(g_pVoteTime) ) ) ) )
	
	gMenu = menu_create(szTitle, "player_vote")
	arrayset(g_iHasVoted, 0, sizeof(g_iHasVoted))
	arrayset(g_votemodcount, 0, sizeof(g_votemodcount))
	
	new iCallBack = menu_makecallback("menu_voteCallBack2")
	
	new szInfo[3]
	
	for(new i; i < 2; i++)
	{
		num_to_str(iParams[i], szInfo, charsmax(szInfo))
		#if defined SHOW_VOTE_PERCENT
			formatex(szTitle, charsmax(szTitle), "%s (0%%)", g_modnames[iParams[i]])
			
			
			#if defined SHOW_PERCENT_AFTER_CHOOSING
			
			menu_additem(gPercentMenu, szTitle, szInfo, .callback = iCallBack)
			menu_additem(gMenu, g_modnames[iParams[i]], szInfo, .callback = iCallBack) 
			#else
			
			menu_additem(gMenu, szTitle, szInfo, .callback = iCallBack)
			#endif
			
		#else
		
		menu_additem(gMenu, g_modnames[iParams[i]], szInfo, .callback = iCallBack) 
		#endif
	}
	
	// something crashs the server here -.- ....
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "ch")
	
	for(new i; i < iNum; i++)
	{
		menu_display(iPlayers[i], gMenu)
	}
	
	set_task(1.0, "VoteTimeDecrementInMenu", 0,_,_, "a", g_iVoteTime)
	set_task(flTime, "check_votes_runoff", 0, iParams, 2)
}

public menu_voteCallBack2(id, menu, item)
{
	return menu_voteCallBack(id, menu, item)
}

public check_votes_runoff(iParams[])
{
	menu_destroy(gMenu)
	
	#if defined SHOW_PERCENT_AFTER_CHOOSING
	menu_destroy(gPercentMenu)
	#endif
	g_bVoteEnded = true
	
	new c, b
	c = iParams[1]
	b = iParams[0]
	
	new iWinningOption

	if(g_votemodcount[b] == g_votemodcount[c])
	{
		if( random_num(0, 1) )
		{
			iWinningOption = b
		}
		
		else
		{
			iWinningOption = c
		}
		
		ClearSyncHud(0, gSyncHud)
		set_hudmessage(0, 255, 0, -1.0, 0.20, 0, 0.0, 5.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(0, gSyncHud, "The two mods got the same votes!^nChoosing a random mod!^n^nThe NEXT MOD WILL BE %s^n^nThe map vote will start in 5 seconds!", g_modnames[iWinningOption])
		SetNextModFromVote(iWinningOption, 0)
		return;
	}
	
	if(g_votemodcount[b] > g_votemodcount[c])
	{
		iWinningOption = b
	}
	
	else
	{
		iWinningOption = c
	}
	
	SetNextModFromVote(iWinningOption, 1)
}

stock SetNextModFromVote(b, iMessage = 1)
{
	client_print(0, print_chat, "%L", LANG_PLAYER, "MM_VOTEMOD", g_modnames[b])
	server_print("%L", LANG_PLAYER, "MM_VOTEMOD", g_modnames[b])
	if(b != g_currentmodid)
		set_multimod(b)
	
	nextmodchoosed = true
	g_nextmodid = b
	
	if(iMessage)
	{
		ClearSyncHud(0, gSyncHud)
		set_hudmessage(0, 255, 0, -1.0, 0.30, 1, 5.0, 5.0, 0.1, 0.1, -1);
		//show_hudmessage(0, "The voting has finsihed!^nThe next mod will be %s^nThe map vote will start in 5 seconds", g_modnames[b]);
		ShowSyncHudMsg(0, gSyncHud, "The voting has finsihed!^nThe next mod will be %s^nThe map vote will start in 5 seconds", g_modnames[b]);
	}
	
	set_task(5.0, "StartMapVote")
}

public StartMapVote()
{
	new iNum
	#if defined GALILEO_SUPPORT
	iNum = callfunc_begin("vote_startDirector", GALILEO_PLUGIN);
	#else
	iNum = callfunc_begin("doVoteNextmap", MAPCHOOSER_PLUGIN);
	#endif
	
	switch(iNum)
	{
		case 0:
		{
			abort(AMX_ERR_GENERAL, "Runtime error")
		}
		
		case -1:
		{
			abort(AMX_ERR_GENERAL, "Plugin not found")
		}
		
		case -2:
		{
			abort(AMX_ERR_GENERAL, "Function not found")
		}
		
		case 1:
		{
			#if defined GALILEO_SUPPORT
			// FORCE VOTE
			callfunc_push_int(g_iAdminVote)
			#else
			callfunc_push_int(g_iAdminVote)
			#endif
			callfunc_end();
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
