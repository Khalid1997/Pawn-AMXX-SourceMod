#include <sourcemod>
#include <multimod_const>

new AdminFlag:ACCESS_FLAG

new const String:g_szMultiModFolder[] = "multimod"
new const String:DEFAULT_PLUGINS_KEY[] = "[DEFAULT PLUGINS]";	// DO NOT EDIT
new const String:MODS_KEY[] = "[MODS]"							// DO NOT EDIT

enum
{
	Handle:MP_NAME,
	Handle:MP_PLUGIN,
	Handle:MP_MAP,
	Handle:MP_CFG,
	Handle:MP_BLOCK,
	
	MODS_PROPS
};

new g_bVoteStarted;

new g_iModsCount;
new g_iBlockedModsCount;

new g_iCurrModId = -1;
new String:g_szCurrModProps[MODS_PROPS][60] = {
	"DEFAULT MOD (NO MODS)",
	"",
	"",
	"",
	""
}; // dont make decl

new g_iNextModId = -1;
new String:g_szNextModProps[MODS_PROPS][60];
new bool:g_bNextModChoosed = false;

new Handle:gModsArrays[MODS_PROPS];
new Handle:gDefaultPluginsArray;

new Handle:g_hMultiModMainMenu;
new Handle:g_hMultiModBlockMenu;
new Handle:g_hMultiModNextModMenu;

new bool:g_bFirstRun = true

public Plugin:myinfo = 
{
	name = "Multimod",
	author = "Khalid",
	description = "Allows multiple mods to be loaded on the server",
	version = "1.5.2",
	url = "No URL"
};

//new Handle:g_pConVars_szInfo[MODS_PROPS]

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLate, String:szError[], iErrMax)
{
	CreateNative("MultiMod_GetNextModId", Native_GetNextModId);
	CreateNative("MultiMod_GetCurrentModId", Native_GetCurrentModId);
	CreateNative("MultiMod_GetModsCount", Native_GetModsCount);
	
	CreateNative("MultiMod_SetNextMod", Native_SetNextMod);
	
	CreateNative("MultiMod_GetNameArray", Native_GetNameArray);
	CreateNative("MultiMod_GetPluginFolderArray", Native_GetPluginFolderArray);
	CreateNative("MultiMod_GetMapFileArray", Native_GetMapFileArray);
	CreateNative("MultiMod_GetConfigFileArray", Native_GetConfigFileArray);
	
	CreateNative("MultiMod_GetModBlockStatus", Native_GetModBlock);
	
	CreateNative("MultiMod_GetModProps", Native_GetModProps);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	/*for(new i; i < sizeof(g_szInfo); i++)
	{
		g_pConVars_szInfo[i] = CreateConVar(g_szInfo[i], "", "Please DONT mess with this");
	}*/
	
	RegAdminCmd("sm_nextmod", AdminCmdSetNextMod, ACCESS_FLAG_BIT, "Set Next mod", "MultiMod");
	RegAdminCmd("sm_mm_reload", AdminCmdReload, ACCESS_FLAG_BIT, "Set Next mod", "MultiMod");
	
	// for use in mm_menu
	BitToFlag(ACCESS_FLAG_BIT, ACCESS_FLAG)
	
	//RegConsoleCmd("say !currentmod", CmdCurrentMod);
	//RegConsoleCmd("say !nextmod", CmdCurrentMod);
	AddCommandListener(Cmd_Say, "say")
	AddCommandListener(Cmd_Say, "say_team")
	
	gModsArrays[MP_NAME] = CreateArray(MAX_MOD_NAME);
	gModsArrays[MP_PLUGIN] = CreateArray(60);
	gModsArrays[MP_CFG] = CreateArray(60);
	gModsArrays[MP_MAP] = CreateArray(60);
	gModsArrays[MP_BLOCK] = CreateArray(1);
	gDefaultPluginsArray = CreateArray(60);
	
	ReadFiles();
}

public Action:Cmd_Say(client, const String:szCommand[], iArgCount)
{
	static String:szMMCmd[20];
	GetCmdArgString(szMMCmd, sizeof szMMCmd)
	StripQuotes(szMMCmd);
	
	if(StrEqual(szMMCmd[1], "currentmod", false))
	{
		MM_PrintToChat(client, "Current MOD: \x04%s", g_szCurrModProps[MP_NAME]);
	}
	
	else if(StrEqual(szMMCmd[1], "nextmod", false))
	{
		MM_PrintToChat(client, "Next MOD: \x04%s",  g_iNextModId == -1 ? "Not chosen yet." : g_szNextModProps[MP_NAME]);
	}
	
	else if(StrEqual(szMMCmd[1], "mm_menu", false))
	{
		//static AdminId:iAdminId;
	//	iAdminId = GetUserAdmin(client);
		
		//if(iAdminId == INVALID_ADMIN_ID)
		//{
		//	DisplayMultiModMenu(client, false);
		//	return Plugin_Continue;
		//}
		
		DisplayMultiModMenu(client);
	}
	
	return Plugin_Continue;
}

DisplayMultiModMenu(client)
{
	//PrintToChat(client, "Success %d", iAccess);
	DisplayMenu(g_hMultiModMainMenu, client, MENU_TIME_FOREVER);
}

public OnPluginEnd()
{
	if(!g_iModsCount)
	{
		return;
	}
	
	PrintToServer("((!()!)%!%(!% PLUGIN END (!%!*!*T!");
	/*
	// Randomize next mod
	if(!g_bNextModChoosed)
	{
		SetNextMod(GetRandomInt(0, g_iModsCount - 1));
	}*/
	
	g_iCurrModId = g_iNextModId;
	
	// Move mod's plugins to their folders
	ChangePlugins(1);
}

public OnMapStart()
{
	if(g_bFirstRun)
	{
		// Restart
		new String:szCurrMapName[60];
		GetCurrentMap(szCurrMapName, sizeof(szCurrMapName));
		PrintToServer("CHANGED MAP ###############################");
		ServerCommand("changelevel %s", szCurrMapName);
		return;
	}
	
	//g_iModsCount = 0;
	//ReadFiles();
	for(new i ; i < MODS_PROPS; i++)
	{
		PrintToServer("** %s", g_szCurrModProps[i]);
	}
	
	ExecCurrentModCfg()
}

ExecCurrentModCfg()
{
	if(g_szCurrModProps[MP_CFG][0])
	{
		new String:szModConfigFile[100];
		FormatEx(szModConfigFile, sizeof(szModConfigFile), "%s/%s", g_szMultiModFolder, g_szCurrModProps[MP_CFG]);
		
		if(StrContains(szModConfigFile, ".cfg", false))
		{
			ReplaceString(szModConfigFile, sizeof(szModConfigFile), ".cfg", "", false);
		}
		
		//AutoExecConfig(true, szMultiModINI, "multimod");
		ServerCommand("exec %s", szModConfigFile);
	}
}

public OnMapEnd()
{
	PrintToServer("********* MAP END CALLED");
	
	/*
	// Randomize next mod
	if(!g_bNextModChoosed)
	{
		SetNextMod(GetRandomInt(0, g_iModsCount - 1));
	}*/
	
	if(!g_iModsCount)
	{
		// Move plugins that are already in plugins folder to their original folder (crash protect);
		ChangePlugins(1);
		if(g_bFirstRun) // keep after changeplugins
		{
			g_bFirstRun = false;
		}
		
		return;
	}
	
	
	/*if(g_bFirstRun) // keep after changeplugins
	{
		ChangePlugins(0);
		for(new i; i < MODS_PROPS; i++)
		{
			strcopy(g_szCurrModProps[i], sizeof(g_szCurrModProps[]), g_szNextModProps[i]);
			g_szNextModProps[i][0] = 0;
		}
		
		g_bFirstRun = false;
		return;
	}*/
	
	if(g_bNextModChoosed)
	{
		ChangePlugins(0);
		// Keep here (if same mod, dont move and reput.)
		for(new i; i < MODS_PROPS; i++)
		{
			strcopy(g_szCurrModProps[i], sizeof(g_szCurrModProps[]), g_szNextModProps[i]);
			g_szNextModProps[i][0] = 0;
		}
		
		g_iCurrModId = g_iNextModId;
		g_iNextModId = -1;
		g_bNextModChoosed = false;
	}
	
	g_bFirstRun = false;
	g_bVoteStarted = false;
	g_iBlockedModsCount = 0
	
	for (new i; i < g_iModsCount; i++)
	{
		SetArrayCell(gModsArrays[MP_BLOCK], i, 0);
	}
}

/*
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:szError[], iErrLen)
{
	return APLRes_Success;
}*/

public Action:AdminCmdSetNextMod(client, iArgs)
{
	if(iArgs < 1)
	{
		PrintToConsole(client, "Usage: sm_nextmod \"Mod Number\"");
		
		new String:szModName[MAX_MOD_NAME];
		new iArraySize = GetArraySize(gModsArrays[MP_NAME]);
		
		PrintToConsole(client, "#. [Mod Name]");
		
		for(new i; i < iArraySize; i++)
		{
			GetArrayString(gModsArrays[MP_NAME], i, szModName, sizeof(szModName));
			PrintToConsole(client, "%d. %s", i + 1, szModName);
		}
		
		return Plugin_Handled;
	}
	
	if(!g_iModsCount)
	{
		PrintToConsole(client, "** There are no mods to choose from.");
		return Plugin_Handled
	}
	
	if(g_bVoteStarted)
	{
		PrintToConsole(client, "** Voting has already started. Can't set the next mod.");
		return Plugin_Handled;
	}
	
	new String:szModNum[5]
	GetCmdArg(1, szModNum, sizeof(szModNum));
	
	new iModNum = StringToInt(szModNum);
	
	if( !( 1 <= iModNum <= g_iModsCount ) )
	{
		PrintToConsole(client, "** You must use a valid mod number");
		return Plugin_Handled;
	}
	
	SetNextMod(iModNum - 1);
	
	new String:szNextModName[60], String:szAdminName[60];
	GetClientName(client, szAdminName, sizeof(szAdminName));
	GetArrayString(gModsArrays[MP_NAME], iModNum - 1, szNextModName, sizeof(szNextModName));
	
	//ShowActivity(client, "\x01%s ADMIN %s: Set next mod to: %s", szAdminName, szNextModName);
	PrintToConsole(client, "Next mod successfully set to %s", szNextModName);
	MM_PrintToChat(client, "ADMIN \x04%s\x01: Set next mod to: \x05%s", szAdminName, szNextModName);
	
	return Plugin_Handled;
}

public Action:AdminCmdReload(client, args)
{
	if(g_bVoteStarted)
	{
		PrintToConsole(client, "** Voting has already started. Can't reload now.");
		return Plugin_Handled;
	}
	
	if(args < 1)
	{
		PrintToConsole(client, "This will reload the MM file, and will cancel any next mod choosed\
		\nIf you want to procceed, write sm_mm_reload \"confirm\" to continue.");
		
		return Plugin_Handled;
	}
	
	for(new i; i < MODS_PROPS; i++)
	{
		ClearArray(gModsArrays[i]);
	}
	
	ClearArray(gDefaultPluginsArray)
	
	CloseHandle(g_hMultiModMainMenu);
	CloseHandle(g_hMultiModBlockMenu);
	CloseHandle(g_hMultiModNextModMenu);
	
	g_iBlockedModsCount = 0
	g_iModsCount = 0
	g_bNextModChoosed = false
	g_iNextModId = -1
	
	for (new i; i < MODS_PROPS; i++)
	{
		g_szNextModProps[i][0] = 0;
	}
	
	// Read Files will build the menu
	ReadFiles(true);
	
	PrintToConsole(client, "Successfully loaded %d mods", g_iModsCount);
	
	return Plugin_Handled;
}

public Voting_VoteStarted()
{
	g_bVoteStarted = true;
}

ReadFiles(bool:bCheckCurrModID = false)
{
	new String:szMultiModINI[60];
	new String:szMultiModPath[60];
	
	FormatEx(szMultiModPath, sizeof(szMultiModPath), "cfg/%s", g_szMultiModFolder);
	FormatEx(szMultiModINI, sizeof(szMultiModINI), "%s/multimod.ini", szMultiModPath);
	
	new Handle:f = OpenFile(szMultiModINI, "r");
	if(!f)
	{
		CloseHandle(f);
		
		if(!DirExists(szMultiModPath))
		{
			CreateDirectory(szMultiModPath, 0);
		}
		
		f = OpenFile(szMultiModINI, "w");
		WriteFileLine(f, 
		 "; --------------------------------------------------------------------------------------------------\
		\n; |                                    MultiMod Plugin File                                          |\
		\n; --------------------------------------------------------------------------------------------------\
		\n; Any line beginning with a ';', '#' or '//' is a comment\
		\n; Write Mods under %s tag\
		\n; Syntax:\
		\n; Mod Name:Plugin-Folder-Name:MapFileName:CFG\
		\n%s\
		\n\
		\n\
		\n\
		\n; Write Default Plugins under %s tag\
		\n; Default Plugins are plugins that run for ALL MODs\
		\n; They must be placed in plugins folder to work\
		\n%s",
		MODS_KEY, MODS_KEY, DEFAULT_PLUGINS_KEY, DEFAULT_PLUGINS_KEY);
		
		// Default plugins
		WriteFileLine(f,
		"admin-flatfile.smx\n\
		adminhelp.smx\n\
		adminmenu.smx\n\
		antiflood.smx\n\
		basebans.smx\n\
		basechat.smx\n\
		basecomm.smx\n\
		basecommands.smx\n\
		basetriggers.smx\n\
		basevotes.smx\n\
		clientprefs.smx\n\
		funcommands.smx\n\
		funvotes.smx\n\
		generator.smx\n\
		voting.smx\n\
		multimod.smx\n\
		rockthevote_mm.smx\n\
		nextmap.smx\n\
		playercommands.smx\n\
		reservedslots.smx\n\
		sounds.smx");

		CloseHandle(f);
		return;
	}
	
	ReadFilesModFiles(szMultiModINI, bCheckCurrModID);
	BuildMultiModMenu();
	
	if( g_bFirstRun )
	{
		StartFirstMod();
		return;
	}
}

ReadFilesModFiles(String:szFile[], bool:bCheck = false)
{
	new Handle:f = OpenFile(szFile, "r");
	
	decl String:szLine[60];
	decl String:szModStuff[MODS_PROPS][60];
	
	decl iPhase;
	
	while(!IsEndOfFile(f))
	{
		ReadFileLine(f, szLine, sizeof(szLine));
		TrimString(szLine);
		
		PrintToServer(szLine);
		if(!szLine[0] || szLine[0] == ';' || szLine[0] == '#' || ( szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		if(StrEqual(szLine, DEFAULT_PLUGINS_KEY))
		{
			iPhase = 2;
			continue;
		}
		
		else if(StrEqual(szLine, MODS_KEY))
		{
			iPhase = 1
			continue;
		}
		
		switch(iPhase)
		{
			case 1:
			{
				ExplodeString(szLine, ":", szModStuff, sizeof(szModStuff), sizeof(szModStuff[]), true);
				
				++g_iModsCount;
				PushArrayString(gModsArrays[MP_CFG], szModStuff[MP_CFG]);
				PushArrayString(gModsArrays[MP_NAME], szModStuff[MP_NAME]);
				PushArrayString(gModsArrays[MP_PLUGIN], szModStuff[MP_PLUGIN]);
				PushArrayString(gModsArrays[MP_MAP], szModStuff[MP_MAP]);
				PushArrayCell(gModsArrays[MP_BLOCK], 0);
				
				if(bCheck)
				{
					if(StrEqual(szModStuff[MP_PLUGIN], g_szCurrModProps[MP_PLUGIN], false))
					{
						g_iCurrModId = g_iModsCount - 1
						g_szCurrModProps[MP_NAME] = szModStuff[MP_NAME];
						g_szCurrModProps[MP_CFG] = szModStuff[MP_CFG];
						g_szCurrModProps[MP_MAP] = szModStuff[MP_MAP];
						
						ExecCurrentModCfg()
					}
				}
				
				PrintToServer("%s MOD Loaded: [%s] - [%s] - [%s] - [%s]", "[MultiMod]", szModStuff[MP_NAME], szModStuff[MP_PLUGIN], szModStuff[MP_MAP], szModStuff[MP_CFG]);
				
				if(g_iModsCount >= MAX_MODS)
				{
					iPhase = 2
				}
			}
			
			case 2:
			{
				if(StrContains(szLine, ".smx", false) != -1)
				{
					PrintToServer("*** Default plugin add: %s", szLine);
					PushArrayString(gDefaultPluginsArray, szLine);
				}
			}
		}
	}
	
	PrintToServer("%s Total MOD count: %d MOD(s)", "[MULTIMOD]", g_iModsCount);
	
	CloseHandle(f);
}

StartFirstMod()
{
	if(!g_iModsCount)
	{
		LogMessage("[MultiMod] Failed to start first MOD because there are no available MODS to start (Mod count: 0)");
		return;
	}
	
	SetNextMod(0);
	LogMessage("[MultiMod] (Server Run) Starting First Mod on the list: %s", g_szNextModProps[MP_NAME]);
}

SetNextMod(iModNum)
{
	g_iNextModId = iModNum
	GetArrayString(gModsArrays[MP_NAME], 	g_iNextModId, 		g_szNextModProps[MP_NAME], 		sizeof(g_szNextModProps[]))
	GetArrayString(gModsArrays[MP_PLUGIN], 	g_iNextModId, 		g_szNextModProps[MP_PLUGIN], 	sizeof(g_szNextModProps[]))
	GetArrayString(gModsArrays[MP_MAP], 	g_iNextModId, 		g_szNextModProps[MP_MAP], 		sizeof(g_szNextModProps[]))
	GetArrayString(gModsArrays[MP_CFG], 	g_iNextModId, 		g_szNextModProps[MP_CFG], 		sizeof(g_szNextModProps[]))
	
	g_bNextModChoosed = true;
}

CancelNextMod()
{
	g_iNextModId = -1
	g_bNextModChoosed = false;
	for (new i; i < MODS_PROPS; i++)
	{
		g_szNextModProps[i][0] = 0;
	}
}

new const String:g_szMM_MenuInfo[4][] = {
	"BLOCK",
	"NEXT",
	"CANCEL",
	"START"
}
// keep in order
enum
{
	MM_BLOCK,
	MM_NEXT,
	MM_CANCEL,
	MM_STARTVOTE
}

BuildMultiModMenu()
{
	g_hMultiModMainMenu = CreateMenu(MultiMod_Main_MenuHandler, MENU_ACTIONS_ALL);
	SetMenuTitle(g_hMultiModMainMenu, "MultiMod Menu:    - By Khalid");
	
	// Keep in order
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_BLOCK], "Block a MOD", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_NEXT], "Choose Next Mod", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_CANCEL], "Cancel Next Mod", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_STARTVOTE], "Start Mod Vote", ITEMDRAW_DEFAULT);
	
	g_hMultiModBlockMenu = CreateMenu(MultiModMenu_Block_Handler, MENU_ACTIONS_ALL);
	g_hMultiModNextModMenu = CreateMenu(MultiModMenu_NextMod_Handler, MENU_ACTIONS_ALL);
	AddMenusItems();
}

AddMenusItems()
{
	new String:szInfo[5]; //,String:szModName[MAX_MOD_NAME], String:szMenuItemName[MAX_MOD_NAME + 15];
	for (new i; i < g_iModsCount; i++)
	{
		//GetArrayString(gModsArrays[MP_NAME], i, szModName, sizeof szModName);
		IntToString(i, szInfo, sizeof szInfo);
		//FormatEx(szMenuItemName, sizeof szMenuItemName, "%s [Not Blocked]", szModName);
		//AddMenuItem(g_hMultiModBlockMenu, szInfo, szMenuItemName, ITEMDRAW_DEFAULT);
		//AddMenuItem(g_hMultiModNextModMenu, szInfo, szModName, ITEMDRAW_DEFAULT);
		AddMenuItem(g_hMultiModBlockMenu, szInfo, "", ITEMDRAW_DEFAULT);	// Display Name altered later in handler
		AddMenuItem(g_hMultiModNextModMenu, szInfo, "", ITEMDRAW_DEFAULT);
	}
}

public MultiMod_Main_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	static String:szInfo[10];
	switch(action)
	{
		case MenuAction_DisplayItem:
		{
			// param1 = client, param2 =  item number for use with GetMenuItem 
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			if (StrEqual(szInfo, g_szMM_MenuInfo[MM_NEXT], true))
			{
				static String:szItemTitle[MAX_MOD_NAME + 25];
				FormatEx(szItemTitle, sizeof szItemTitle, "Choose Next Mod (Current: %s)", g_iNextModId == -1 ? "Not chosen yet" : g_szNextModProps[MP_NAME]);
				
				return RedrawMenuItem(szItemTitle);
			}
		}
		
		case MenuAction_DrawItem:
		{
			// param1: client index
			// param2: item number for use with GetMenuItem
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			if(StrEqual(szInfo, g_szMM_MenuInfo[MM_CANCEL]))
			{
				if(!g_bNextModChoosed)
				{
					return ITEMDRAW_DISABLED;
				}
				
				else
				{
					static AdminId:iAdminId;
					iAdminId = GetUserAdmin(param1);
		
					if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
					{
						return ITEMDRAW_DISABLED;
					}
					
					return ITEMDRAW_DEFAULT;
				}
					
			}
			
			if (StrEqual(szInfo, g_szMM_MenuInfo[MM_STARTVOTE]))
			{
				static AdminId:iAdminId;
				iAdminId = GetUserAdmin(param1);
		
				if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
				{
					return ITEMDRAW_DISABLED;
				}
				
				return ITEMDRAW_DEFAULT;
			}
		}
		
		case MenuAction_End: {  }
		case MenuAction_Select:
		{
			switch(param2)
			{
				case MM_BLOCK:
				{
					DisplayMenu(g_hMultiModBlockMenu, param1, MENU_TIME_FOREVER);
				}
				
				case MM_NEXT:
				{
					DisplayMenu(g_hMultiModNextModMenu, param1, MENU_TIME_FOREVER);
				}
				
				case MM_CANCEL: 
				{
					CancelNextMod();
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
					
					static String:szAdminName[MAX_NAME_LENGTH];
					GetClientName(param1, szAdminName, sizeof szAdminName);
			
					MM_PrintToChat(0, "ADMIN \x04%s \x01canceled the next chosen MOD.", szAdminName);
				}
				case MM_STARTVOTE:
				{
					//MM_PrintToChat(param1, "Starting vote (Fake- not done yet)");
					//new Function:hFuncId = GetFunctionByName(
					//Call_StartFunction(INVALID_HANDLE, Vote_StartVote);
					//Call_PushCell(param1);
					new Handle:hForward = CreateGlobalForward("MultiMod_VotingStarted", ET_Single, Param_Cell);
					Call_StartForward(hForward);
					Call_PushCell(g_iNextMod);
					
					new iResult
					Call_Finish(iResult);
					CloseHandle(hForward);
					
					if(iResult)
					{
						new String:szAdminName[MAX_NAME_LENGTH];
						GetClientName(param1, szAdminName, sizeof szAdminName);
						
						MM_PrintToChat(0, "ADMIN \x04%s\x01: Start the MOD vote.", szAdminName);
					}	else	{
						MM_PrintToChat(param1, "The vote has already started!");
					}
				}
			}
		}
	}
	
	return 0;
}

public MultiModMenu_Block_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			static AdminId:iAdminId;
			iAdminId = GetUserAdmin(param1);
		
			if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
			{
				return ITEMDRAW_DISABLED;
			}
			
			#if defined BLOCK_CURRENT_MOD_IN_VOTE
			if(param2 == g_iCurrModId)
			{
				return ITEMDRAW_DISABLED;
			}
			#endif
			
			#if defined BLOCK_CURRENT_MOD_IN_VOTE
			if(g_iBlockedModsCount + 2 >= g_iModsCount)
			#else
			if(g_iBlockedModsCount + 1 >= g_iModsCount)
			#endif
			{
				if (GetArrayCell(gModsArrays[MP_BLOCK], param2) == 0 )
				{
					return ITEMDRAW_DISABLED;		// Do not allow blocking of last mod.
				}
			}
			
			return ITEMDRAW_DEFAULT;
		}
				
		case MenuAction_DisplayItem:
		{
			if(g_bVoteStarted)
			{
				return ITEMDRAW_DISABLED;
			}
			
			static bool:bBlockStatus
			bBlockStatus = bool:GetArrayCell(gModsArrays[MP_BLOCK], param2);
			
			//GetMenuItem(menu, param2, szInfo, sizeof szInfo
			static String:szItemDisplayName[MAX_MOD_NAME + 35], String:szModName[MAX_MOD_NAME];
			GetArrayString(gModsArrays[MP_NAME], param2, szModName, sizeof szModName);
			
			#if defined BLOCK_CURRENT_MOD_IN_VOTE
				if(param2 == g_iCurrModId)
				{
					FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s %s", szModName, "[BLOCKED BY VOTING PLUGIN (Current MOD)]");
				}
			
				else	FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s %s", szModName, bBlockStatus ? "[Blocked]" : "[Not Blocked]");
			#else
				FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s %s", szModName, bBlockStatus ? "[Blocked]" : "[Not Blocked]");
			#endif
				
			return RedrawMenuItem(szItemDisplayName);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Exit)
			{
				DisplayMenu(g_hMultiModMainMenu, param1, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_End: 
		{
			// param1: MenuEnd reason
			// param2: If param1 is MenuEnd_Cancelled, the MenuCancel reason 
			//if( MenuEnd_Cancelled
		}
		
		case MenuAction_Select:
		{
			if(g_bVoteStarted)
			{
				MM_PrintToChat(param1, "You cannot block any MODs as the vote has started.");
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				return 0;
			}
			
			int iBlockStatus
			iBlockStatus = GetArrayCell(gModsArrays[MP_BLOCK], param2);
			iBlockStatus = !iBlockStatus
			SetArrayCell(gModsArrays[MP_BLOCK], param2, iBlockStatus);
			
			static String:szAdminName[MAX_NAME_LENGTH], String:szModName[MAX_MOD_NAME];
			GetArrayString(gModsArrays[MP_NAME], param2, szModName, sizeof szModName);
			GetClientName(param1, szAdminName, sizeof szAdminName);
			
			MM_PrintToChat(0, "ADMIN \x04%s \x06%s \x01the MOD \x04%s.", szAdminName, iBlockStatus ? "BLOCKED" : "UNBLOCKED", szModName);
			
			g_iBlockedModsCount += (iBlockStatus ? 1 : -1);
			
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			//CancelClientMenu(
		}
	}
	
	return 0;
}

public MultiModMenu_NextMod_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			if(g_bVoteStarted)
			{
				return ITEMDRAW_DISABLED;
			}
			
			static AdminId:iAdminId;
			iAdminId = GetUserAdmin(param1);
		
			if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_DisplayItem:
		{
			static String:szItemDisplayName[MAX_MOD_NAME + 20], String:szModName[MAX_MOD_NAME];
			GetArrayString(gModsArrays[MP_NAME], param2, szModName, sizeof szModName);
			
			if(g_iNextModId == param2)
			{
				//GetMenuItem(menu, param2, szInfo, sizeof szInfo
				FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s (Chosen as next mod)", szModName);
			}
			
			else
			{
				FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s", szModName);
			}
			
			return RedrawMenuItem(szItemDisplayName);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Exit)
			{
				DisplayMenu(g_hMultiModMainMenu, param1, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_End: {   }
		case MenuAction_Select:
		{
			if(g_bVoteStarted)
			{
				MM_PrintToChat(param1, "You cannot select the next MOD as the vote has started.");
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				return 0;
			}
				
			static String:szAdminName[MAX_NAME_LENGTH], String:szModName[MAX_MOD_NAME];
			GetArrayString(gModsArrays[MP_NAME], param2, szModName, sizeof szModName);
			GetClientName(param1, szAdminName, sizeof szAdminName);
			
			MM_PrintToChat(0, "ADMIN \x04%s \x01chose MOD \x04%s as the next MOD.", szAdminName, szModName);
			
			SetNextMod(param2);
			
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

ChangePlugins(iDontMoveNextMod = 0)
{
	if(!g_iModsCount)
	{
		PrintToServer("*** nO MODS ");
		return;
	}
	
	new String:szFile[60];
	new String:szSMPath[60];
	
	BuildPath(Path_SM, szSMPath, sizeof(szSMPath), "plugins");
	PrintToServer("SM_PATH %s", szSMPath);
	//FormatEx(szFolder, szSMPath, sizeof(szSMPath), "plugins/%s", g_szNextModProps[1]);
	
	if(!DirExists(szSMPath))
	{
		PrintToServer("************ DIR NOT EXIST %s", szSMPath);
		return;
	}
	
	FormatEx(szFile, sizeof(szFile), "%s/disabled/%s", szSMPath, g_szNextModProps[MP_PLUGIN]);
	if(!DirExists(szFile))
	{
		PrintToServer("************ DIR NOT EXIST %s", szFile);
		iDontMoveNextMod = 1
	}
	
	new Handle:hDir = OpenDirectory(szSMPath);
	new FileType:iFileType;
	new String:szOldPath[100], String:szNewPath[100], String:szModPluginFolder[60];

	decl Handle:f;
	
	// Crash protect (First Run)
	if(g_bFirstRun)
	{
		if(!g_szCurrModProps[1][0])
		{
			FormatEx(szFile, sizeof(szFile), "%s/lastmod.ini", szSMPath);
			
			PrintToServer(szFile);
			
			if( (f = OpenFile(szFile, "r") ) )
			{
				PrintToServer("------------------------- CRASH PROTECT MADRY SHO");
				ReadFileString(f, g_szCurrModProps[MP_PLUGIN], sizeof(g_szCurrModProps[]));
				TrimString(g_szCurrModProps[MP_PLUGIN]);
				CloseHandle(f);
				
				FormatEx(szFile, sizeof(szFile), "%s/disabled/%s", szSMPath, g_szCurrModProps[MP_PLUGIN]);
				
				if(!DirExists(szFile))
				{
					PrintToServer("**** Doesnt Exist %s", szFile);
					// Move old mods file to disabled
					
					FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled");
				}
				
				else 
				{
					FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled/%s", g_szCurrModProps[MP_PLUGIN]);
				}
			}
		}
	}
	
	else
	{
		FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled/%s", g_szCurrModProps[MP_PLUGIN]);
		FormatEx(szFile, sizeof szFile, "%s/%s", szSMPath, szModPluginFolder); // use szFile only to check if the directory exists
		
		PrintToServer("** Test: %s", szFile);
		if(!DirExists(szFile))
		{
			FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled");
			//FormatEx(szFile, sizeof szFile, "%s/%s", szSMPath, szModPluginFolder); // not needed
		}
	}
	
	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType);
	ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType);

	while( ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType) )
	{
		if(iFileType != FileType_File)
		{
			continue;
		}
		
		PrintToServer("[1] Plugin Name: %s", szFile);
		
		if(StrContains(szFile, ".smx", false) == -1)
		{
			continue;
		}
		
		if(FindStringInArray(gDefaultPluginsArray, szFile) != -1)
		{
			continue;
		}
		
		FormatEx(szOldPath, sizeof(szOldPath), "%s/%s", szSMPath, szFile);
		FormatEx(szNewPath, sizeof(szNewPath), "%s/%s/%s", szSMPath, szModPluginFolder, szFile);
		
		PrintToServer("*** Rename [%s] -- [%s]", szOldPath, szNewPath);
		if(RenameFile(szNewPath, szOldPath))
		{
			PrintToServer("Moved %s to current mod plugins", szFile);
		}
	}
	
	CloseHandle(hDir)
	
	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	
	if(iDontMoveNextMod)
	{
		PrintToServer("*** Dont move");
		return;
	}
	
	FormatEx(szFile, sizeof(szFile), "%s/disabled/%s", szSMPath, g_szNextModProps[MP_PLUGIN]);
	hDir = OpenDirectory(szFile);
	
	if(hDir == INVALID_HANDLE)
	{
		PrintToServer("*** Not exist %s", szFile);
		return;
	}
	
	// Crash Protect
	//BuildPath(Path_SM, szFile, sizeof szFile, "pluginslastmod.ini");
	FormatEx(szFile, sizeof(szFile), "%s/lastmod.ini", szSMPath);
	f = OpenFile(szFile, "w");
	WriteFileString(f, g_szNextModProps[MP_PLUGIN], true);
	CloseHandle(f);
	
	ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType);
	ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType);
	
	while( ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType) )
	{
		PrintToServer("[2] Plugin Name: %s", szFile);
		if(iFileType != FileType_File)
		{
			continue;
		}
		
		if(StrContains(szFile, ".smx", false) == -1)
		{
			PrintToServer("** Warning: Not a plugin");
			continue;
		}
		
		FormatEx(szNewPath, sizeof(szOldPath), "%s/%s", szSMPath, szFile);
		FormatEx(szOldPath, sizeof(szOldPath), "%s/disabled/%s/%s", szSMPath, g_szNextModProps[MP_PLUGIN], szFile);
		
		PrintToServer("** szNewPath: %s", szNewPath);
		PrintToServer("** szOldPath %s", szOldPath);
		
		if(RenameFile(szNewPath, szOldPath))
		{
			PrintToServer("Moved %s to plugins", szFile);
		}
		
		else PrintToServer("** Fail move file!")
	}
	
	CloseHandle(hDir);
}

public Native_GetNextModId(Handle:hPlugin, iArgs)
{
	return g_iNextModId;
}

public Native_GetCurrentModId(Handle:hPlugin, iArgs)
{
	return g_iCurrModId;
}

public Native_GetModsCount(Handle:hPlugin, iArgs)
{
	return g_iModsCount;
}

public Native_SetNextMod(Handle:hPlugin, iArgs)
{
	if(!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Aborted setting next MOD as there are no available MODs");
		return 0;
	}
	
	iArgs = GetNativeCell(1)
	if( !( 0 <= iArgs < g_iModsCount ) )
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iArgs);
		return 0;
	}
	
	SetNextMod(iArgs);
	return 1;
}

public Native_GetModProps(Handle:hPlugin, iArgs)
{
	if(!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Aborted setting next MOD as there are no available MODs");
		return 0;
	}
	
	new iIndex = GetNativeCell(1);
	if( !( 0 <= iIndex < g_iModsCount ) )
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iIndex);
		return 0;
	}
	
	new iProp = GetNativeCell(2);
	if( !( 0 <= iProp < MODS_PROPS ) )
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iIndex);
		return 0;
	}
	
	new iSize = GetNativeCell(4)
	new String:szData[iSize];
	GetArrayString(gModsArrays[iProp], iIndex, szData, iSize);
	SetNativeString(3, szData, iSize);
	
	PrintToServer("** i = %d | %d - %s", iIndex, iSize, szData);
	
	/*for(new i, iArg, iSize; i < MODS_PROPS; i++)
	{
		iArg = ( (i + 1) * 2 ) + 1
		new String:szData[ ( iSize = GetNativeCell( iArg ) ) ];
		GetArrayString(gModsArrays[i], iIndex, szData, iSize);
		PrintToServer("** i = %d  - %s", i, szData);
		
		if(SetNativeString(iArg, szData, iSize, false) == SP_ERROR_NONE)
		{
			PrintToServer("No Error");
		}
	}*/
	
	return 1;
}

public Native_GetModBlock(Handle:hPlugin, iArgs)
{
	if(g_iModsCount == 0)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "There are no available MODs (Mods count = 0)");
		return false;
	}
		
	new iModId
	iModId = GetNativeCell(1)
	
	if(!(-1 < iModId < g_iModsCount))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iModId);
		return false;
	}
	
	return GetArrayCell(gModsArrays[MP_BLOCK], iModId);
}

public Native_GetNameArray(Handle:hPlugin, iArgs)
{
	return _:gModsArrays[MP_NAME];
}

public Native_GetPluginFolderArray(Handle:hPlugin, iArgs)
{
	return _:gModsArrays[MP_PLUGIN];
}

public Native_GetMapFileArray(Handle:hPlugin, iArgs)
{
	return _:gModsArrays[MP_MAP];
}

public Native_GetConfigFileArray(Handle:hPlugin, iArgs)
{
	return _:gModsArrays[MP_CFG];
}

public Native_GetBlockArray(Handle:hPlugin, iArgs)
{
	return _:gModsArrays[MP_BLOCK];
}