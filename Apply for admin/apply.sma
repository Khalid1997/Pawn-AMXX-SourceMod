#include <amxmodx>
#tryinclude <played_time>

#define MOTD_BY_FILE

new const VERSION[] = "1.0"

enum
{
	EN = 1,
	AR,
	LANG,
	
	MENUS
}

enum
{
	START = 0,
	HELP = 1,
	LANGMENU = 2
}

enum
{
	NAME = 0,
	STEAMID,
}

enum
{
	WHY = STEAMID + 1,
	#if !defined _played_time_included_
	HOW,
	#endif
	WHERE,
	WHAT,
	
	YAY
}

#define IsInBit(%1,%2)		( %1 & 	(1<<%2)  )
#define AddToBit(%1,%2)		( %1 |= (1<<%2)  )
#define RemoveFromBit(%1,%2)	( %1 &= ~(1<<%2) )

new gMenu[MENUS + 1]
new g_iLang[33], g_iApplying[33]
new gszInfo[33][YAY][255]

new g_iApplyed, g_iNoSteamer

#if !defined MOTD_BY_FILE
new g_szArMotd[1024], g_szEnMotd[1024]
#else
new szArMotd[] = "motds/apply_ar.txt"
new szEnMotd[] = "motds/apply_en.txt"
#endif

new szDir[200]
new szApplyedFile[] = "addons/amxmodx/data/apply/applyed_people.txt"

new Trie:gTrie

new const COMMANDS[] = 
{
	"Why do you want to be admin?",
#if !defined _played_time_included_
	"How many minutes do you have?",
#endif
	"Where were you admin before?",
	"What do you know about amxx?"
}

public plugin_init() {
	register_plugin("Admin Apply", VERSION, "Khalid :)")
	
	gTrie = TrieCreate()
	
	register_clcmd("say /apply", "CmdApply")
	register_clcmd("Why", "CmdWhy")
	
#if !defined _played_time_included_
	register_clcmd("How", "CmdHow")
#endif

	register_clcmd("Where", "CmdWhere")
	register_clcmd("What", "CmdWhat")

	Build()
}

public client_putinserver(id)
{
	static szAuthId[35]; get_user_authid(id, szAuthId, 34)
	
	if(TrieKeyExists(gTrie, szAuthId))
		AddToBit(g_iApplyed, id)
		
	else if( equal(szAuthId, "STEAM_ID_LAN") || equal(szAuthId, "VALVE_ID_LAN") || equal(szAuthId, "STEAM_ID_PENDING") || equal(szAuthId, "VALVE_ID_LAN") )
		AddToBit(g_iNoSteamer, id)		
}	

public client_disconnect(id)
{
	if(IsInBit(g_iApplyed, id))
		RemoveFromBit(g_iApplyed, id)
		
	if(IsInBit(g_iNoSteamer, id))
		RemoveFromBit(g_iNoSteamer, id)
}

public CmdApply(id)
{
	new iFlags = get_user_flags(id)
	if( iFlags > 0 && !(iFlags & ADMIN_USER) && !(iFlags & ADMIN_RCON) )
	{
		client_print(id, print_chat, "Hey ! You are already an admin! :@")
		return PLUGIN_HANDLED
	}
	
	if(IsInBit(g_iNoSteamer, id))
	{
		client_print(id, print_chat, "Sorry. No-Steamers are not allowed to apply :)")
		return PLUGIN_HANDLED
	}
	
	if(IsInBit(g_iApplyed, id))
	{
		client_print(id, print_chat, "You have already applied")
		return PLUGIN_HANDLED
	}

	new iNum = g_iLang[id]
	if(!iNum)
	{
		menu_display(id, gMenu[LANG])
		return PLUGIN_HANDLED
	}
	
	if(g_iApplying[id])
	{
		Start(id)
		return PLUGIN_HANDLED
	}

	menu_display(id, gMenu[iNum])
	return PLUGIN_HANDLED
}

public CmdWhy(id)
{
	new szArg[255]
	
	read_argv(read_argc() - 1, szArg, charsmax(szArg))
	
	FormatIsCorrect(id, szArg, WHY)
	copy(gszInfo[id][WHY], charsmax(gszInfo[][]), szArg)
}

#if !defined _played_time_included_
public CmdHow(id)
{
	new szArg[255]
	
	read_argv(read_argc() - 1, szArg, charsmax(szArg))
	
	FormatIsCorrect(id, szArg, HOW)
	copy(gszInfo[id][HOW], charsmax(gszInfo[][]), szArg)
}
#endif

public CmdWhere(id)
{
	new szArg[255]
	
	read_argv(read_argc() - 1, szArg, charsmax(szArg))
	
	FormatIsCorrect(id, szArg, WHERE)
	copy(gszInfo[id][WHERE], charsmax(gszInfo[][]), szArg)
}

public CmdWhat(id)
{
	new szArg[255]
	
	read_argv(read_argc() - 1, szArg, charsmax(szArg))
	
	FormatIsCorrect(id, szArg, WHAT)
	copy(gszInfo[id][WHAT], charsmax(gszInfo[][]), szArg)
}

public CorrectMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		g_iApplying[id] = 0
		menu_destroy(menu)
	}
	
	new szInfo[3], access, callback, iCont;
	
	menu_item_getinfo(menu, item, access, szInfo, 2, .callback=callback)
	menu_destroy(menu)
	
	switch(str_to_num(szInfo))
	{
		case 0:
		{
			iCont = 1
			g_iApplying[id] += 1	// Go to next step
		}
		
		case 1:
		{
			iCont = 1
		}
		
		case 2:
		{
			g_iApplying[id] = 0
			client_print(id, print_chat, "You have canceled the applying form.")
		}
	}
	
	
	if(iCont)
		Start(id)
}

public lang_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
		return

	new szItem[3], callback, access, iNum
	menu_item_getinfo(menu, item, access, szItem, charsmax(szItem), .callback = callback)
	
	
	g_iLang[id] = ( iNum = str_to_num(szItem) )
	menu_display(id, gMenu[iNum])
}

public menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
		return
	
	new szItem[3], callback, access
	menu_item_getinfo(menu, item, access, szItem, charsmax(szItem), .callback = callback)
	
	switch(str_to_num(szItem))
	{
		case START:
		{
			g_iApplying[id] = WHY
			Start(id)
		}
		
		case HELP:
		{
			switch(g_iLang[id])
			{
				case EN:
				{
					#if defined MOTD_BY_FILE
					show_motd(id, szEnMotd, "Appling for adminship help")
					#else
					show_motd(id, g_szEnMotd, "Appling for adminship help")
					#endif
					menu_display(id, gMenu[g_iLang[id]])
				}
				case AR:
				{
					#if defined MOTD_BY_FILE
					show_motd(id, szArMotd, "ﺐﻠﻄﻟﺍ ﻢﻳﺪﻘﺗ ﺓﺪﻋﺎﺴﻣ")
					#else
					show_motd(id, g_szArMotd, "ﺐﻠﻄﻟﺍ ﻢﻳﺪﻘﺗ ﺓﺪﻋﺎﺴﻣ")
					#endif
					menu_display(id, gMenu[g_iLang[id]])
				}
			}
		}
		
		case LANGMENU:	menu_display(id, gMenu[LANG])
	}
}

FormatIsCorrect(id, Arg[], Num)
{
	new menu = menu_create("Is this correct?", "CorrectMenuHandler")
		
	menu_additem(menu, "Yes", "0")
	menu_additem(menu, "No, I will type it again..", "1")
	menu_addblank(menu, 0)
	menu_additem(menu, "Cancel the whole proccess", "2")
	client_print(id, print_chat, "You were asked %s. And your answer was:", COMMANDS[Num - 2])
	client_print(id, print_chat, Arg)
	client_print(id, print_chat, "Is this correct?")
	
	menu_display(id, menu)
}

Start(id)
{
	switch(g_iApplying[id])
	{
		case WHY:		// NEW START	( Why )
		{
			client_print(id, print_center, "You have started the Applying form! you can type 'cancel' at any step in the applying form to stop :)")
			client_cmd(id, "messagemode ^"Why do you want to be admin?^"", COMMANDS[0])
			
			get_user_name(id, gszInfo[id][NAME], 32)
			get_user_authid(id, gszInfo[id][STEAMID], 35)
		}
		
#if !defined _played_time_included_
		case HOW:		// In step 2	( How )
		{
			client_cmd(id, "messagemode ^"How many minutes do you currently have?^"", COMMANDS[1])
		}
#endif
		
		case WHERE:		// In step 3		( WHERE )
		{
			client_cmd(id, "messagemode ^"Where were you admin before?^"", COMMANDS[2])
		}
		
		case WHAT:		// WHAT
		{
			client_cmd(id, "messagemode ^"What do you know about amxx^"", COMMANDS[3])
		}
		
		case YAY:		// DONE
		{
			if(get_user_flags(id) & ADMIN_RCON)
			{
				g_iApplying[id] = 0
				return;
			}
			
			client_print(id, print_chat, "Congratulations, You have finished the applying form ... You will be informed if you were choosen as admin")
			
			static szFile[100], szInfo[100]
			formatex(szFile, charsmax(szFile), "%s.txt", gszInfo[id][NAME])
			ClearFileName(szFile, charsmax(szFile))
			
			format(szFile, charsmax(szFile), "%s/%s", szDir, szFile)
			
			formatex(szInfo, charsmax(szInfo), "Name: %s^n", gszInfo[id][NAME])
			write_file(szFile, szInfo)
#if !defined _played_time_included
			formatex(szInfo, charsmax(szInfo), "Minutes player have: %s^n^n", gszInfo[id][HOW])
#else
			formatex(szInfo, charsmax(szInfo), "Minutes player have: %d^n^n", get_user_playedtime(id))
#endif
			write_file(szFile, szInfo)
			
			formatex(szInfo, charsmax(szInfo), "STEAMID: %s^n^n", gszInfo[id][STEAMID])
			write_file(szFile, szInfo)
			
			formatex(szInfo, charsmax(szInfo), "Why I want to be admin:^n%s^n^n", gszInfo[id][WHY])
			write_file(szFile, szInfo)

			formatex(szInfo, charsmax(szInfo), "Where I have been admin before:^n%s^n^n", gszInfo[id][WHERE])
			write_file(szFile, szInfo)
			
			formatex(szInfo, charsmax(szInfo), "What do I know about amxx:^n%s", gszInfo[id][WHAT])
			write_file(szFile, szInfo)
			
			AddToBit(g_iApplyed, id)

			TrieSetCell(gTrie, gszInfo[id][STEAMID], 1)
			
			format(szInfo, charsmax(szInfo), "[%s]", gszInfo[id][STEAMID])

			write_file(szApplyedFile, szInfo)
			write_file(szApplyedFile, szFile)
			write_file(szApplyedFile, "")
		}
	}
}

stock ClearFileName(File[], len)
{
	static const invalid_chars[][] =
	{
		"/", "\", "*", ":", "?", "^"", "<", ">", "|"
	}
	
	for( new i = 0; i < sizeof(invalid_chars); i++ )
	{
		replace_all(File, len, invalid_chars[i], "_")
	}
}

LoadApplyed()
{
	if(!file_exists(szApplyedFile))
	{
		write_file(szApplyedFile, "")
		return;
	}
	
	new f = fopen(szApplyedFile, "r")
	
	if(!f)
		return;
		
	new szLine[50]
		
	while(!feof(f))
	{
		fgets(f, szLine, 49)
		
		if(!szLine[0] || szLine[0] == ' ' || szLine[0] == ';' || szLine[0] != '[')
			continue;
			
		server_print(szLine)
		replace(szLine, 49, "[", "")
		replace(szLine, 49, "]", "")
		
		TrieSetCell(gTrie, szLine, 1)
	}
	
	fclose(f)
}

Build()
{
	gMenu[EN] = menu_create("Choose an item", "menu_handler")
	gMenu[AR] = menu_create("ﺪﻨﺑ ﺮﺘﺧﺇ", "menu_handler")
	gMenu[LANG] = menu_create("\wChoose your language    ﻚﺘﻐﻟ ﺮﺘﺧﺇ^n^nBy \yKhalid :)", "lang_menu_handler")
	
	menu_additem(gMenu[EN], "Start applying form.", "0")
	menu_additem(gMenu[EN], "Help page", "1")
	menu_additem(gMenu[EN], "Switch between languages", "2")
	
	menu_additem(gMenu[AR], "ﺐﻠﻄﻟﺍ ﻢﻳﺪﻘﺗ ﻲﻓ ﺀﺪﺒﻟﺍ", "0")
	menu_additem(gMenu[AR], "ﺓﺪﻋﺎﺴﻤﻟﺍ", "1")
	menu_additem(gMenu[AR], "ﺕﺎﻐﻠﻟﺍ ﻦﻴﺑ ﻞﻳﺪﺒﺘﻟﺍ", "2")
	
	menu_additem(gMenu[LANG], "English ﺔﻳﺰﻴﻠﺠﻧﻹﺍ", "1")
	menu_additem(gMenu[LANG], "Arabic ﺔﻴﺑﺮﻌﻟﺍ", "2")

	formatex(szDir, charsmax(szDir), "addons/amxmodx/data/apply")

	if(!dir_exists(szDir))
		mkdir(szDir)
	
	
	new szTime[20]
	get_time("%d_%m_%Y", szTime, charsmax(szTime))
	format(szDir, charsmax(szDir), "%s/%s", szDir, szTime)
	
	if(!dir_exists(szDir))
		mkdir(szDir)
	
#if defined MOTD_BY_FILE
	if(!dir_exists("motds"))
		mkdir("motds")
#endif
	
	LoadApplyed()
	
	new szMotd[1024], len
	
#if defined MOTD_BY_FILE
	if(!file_exists(szArMotd))
#endif
	{

		len = formatex(szMotd, charsmax(szMotd), "<body bgcolor=^"#000000^">^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p align=^"center^"><span style=^"background-color: #00FF00^" lang=^"ar-kw^"><font size=^"5^" color=^"#FFFF00^">القوانين:</font></span></p>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p align=^"right^"><span lang=^"ar-kw^"><font color=^"#FFFFFF^">* الترجي من أجل الأدمن ممنوع منعا باتا. <br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "* أبدا!! لا تسأل أي أدمن ليجعلك أدمن. <br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "* تقديم طلبات كثيرة سيؤدي إلى حرمانك من هذه الخاصية.<br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "* .</font></span></p>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p align=^"center^"><span style=^"background-color: #00FF00^" lang=^"ar-kw^"><font size=^"5^" color=^"#FFFF00^">كيفية التقديم:</font></span></p>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p align=^"right^"><span lang=^"ar-kw^"><font color=^"#FFFFFF^">بعد اغلاق هذه :الصفحة سوف تظهر لك قائمة كالتالي<br>اختر من القائمة<br>1. البدء في تقديم الطلب.<br>2. المساعدة.<br>3. التبديل بين اللغات<br> فقط اختر البدء في تقديم الطلب و اتبع التعليمات.</font></span></p></body>");
		
#if defined MOTD_BY_FILE
		write_file(szArMotd, szMotd)
#else
		g_szArMotd = szMotd
#endif
	}
	
#if defined MOTD_BY_FILE
	if(!file_exists(szEnMotd))
#endif
	{

		len = formatex(szMotd, charsmax(szMotd), "<body bgcolor=^"#000000^">^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p align=^"center^"><span style=^"background-color: #000000^">^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<font color=^"#FFFF00^" size=^"5^">Rules:</font></span></p>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p align=^"left^"><font color=^"#FFFFFF^">* No begging for admin.<br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "* Never ask any admin to make you admin.<br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "* Spamming in the applying form will result in banning you from using it.<br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "* Admins can't beg for the </font>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<font color=^"#FFFF00^">owner/manager</font> <font color=^"#FFFFFF^">to make a player admin.<br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "* Admins can only recommend players to the^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<font color=^"#FFFF00^">owner/manager</font> to be admin</font></p>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p align=^"center^"><span style=^"background-color: #00FF00^"><font color=^"#FFFF00^">^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "How to apply:</font></span></p>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<font color=^"#FFFFFF^">^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "<p>After closing this page, a menu will come-up like this:<br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "Choose an item:<br>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "1. Start applying form.<br>2. Show help page.<br>3. Switch Between Languages<br>Just choose the Start applying form to start.</p>^n")
		len += formatex(szMotd[len], charsmax(szMotd) - len, "</font></body>")
		
#if defined MOTD_BY_FILE
		write_file(szEnMotd, szMotd)
#else
		g_szEnMotd = szMotd
#endif
	}
}
