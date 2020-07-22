#include <sourcemod>

#define MAX_MOD_NAME	60
#define MAX_MODS		8

new const String:DEFAULT_PLUGINS_KEY[] = "[DEFAULT PLUGINS]";
new const String:MODS_KEY[] = "[MODS]"
new const String:szPrefix[] = " \x01\x0B\x04[Multimod]\x01";
new const String:g_szMultiModFolder[] = "multimod"

enum
{
	Handle:MP_NAME,
	Handle:MP_PLUGIN,
	Handle:MP_MAP,
	Handle:MP_CFG,
	MODS_PROPS
};

new g_bVoteStarted;

new g_iModsCount;

new g_iCurrModId = -1;
new String:g_szCurrModProps[MODS_PROPS][60]; // dont make decl

new g_iNextModId = -1;
new String:g_szNextModProps[MODS_PROPS][60];
new bool:g_bNextModChoosed = false;

new Handle:gModsArrays[MODS_PROPS];
new Handle:gDefaultPluginsArray;

new bool:g_bFirstRun = true

public Plugin:myinfo = 
{
	name = "Multimod",
	author = "Khalid",
	description = "Allows multiple mods to be loaded on the server",
	version = "1.0",
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
	
	CreateNative("MultiMod_GetModProps", Native_GetModProps);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	/*for(new i; i < sizeof(g_szInfo); i++)
	{
		g_pConVars_szInfo[i] = CreateConVar(g_szInfo[i], "", "Please DONT mess with this");
	}*/
	
	RegAdminCmd("sm_nextmod", AdminCmdSetNextMod, ADMFLAG_ROOT, "Set Next mod", "MultiMod");
	RegAdminCmd("sm_mm_reload", AdminCmdReload, ADMFLAG_ROOT, "Set Next mod", "MultiMod");
	//RegConsoleCmd("say !currentmod", CmdCurrentMod);
	//RegConsoleCmd("say !nextmod", CmdCurrentMod);
	AddCommandListener(Cmd_Say, "say")
	AddCommandListener(Cmd_Say, "say_team")
	
	gModsArrays[MP_NAME] = CreateArray(MAX_MOD_NAME);
	gModsArrays[MP_PLUGIN] = CreateArray(60);
	gModsArrays[MP_CFG] = CreateArray(60);
	gModsArrays[MP_MAP] = CreateArray(60);
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
		PrintToChat(client, "%s Current MOD: %s", szPrefix, g_szCurrModProps[MP_NAME]);
	}
	
	else if(StrEqual(szMMCmd[1], "nextmod", false))
	{
		PrintToChat(client, "%s Next MOD: %s",  szPrefix, g_iNextModId == -1 ? "Not chosen yet." : g_szNextModProps[MP_NAME]);
	}
}

public OnPluginEnd()
{
	ChangePlugins(1);
}

public OnMapStart()
{
	//g_iModsCount = 0;
	//ReadFiles();
	for(new i ; i < MODS_PROPS; i++)
	{
		PrintToServer("** %s", g_szCurrModProps[i]);
	}
	
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
	if(!g_iModsCount)
	{
		return;
	}
	
	// Randomize next mod
	if(!g_bNextModChoosed)
	{
		SetNextMod(GetRandomInt(0, g_iModsCount - 1));
	}
	
	PrintToServer("********* MAP END CALLED");
	
	ChangePlugins(0);
	if(g_bFirstRun) // keep after changeplugins
	{
		g_bFirstRun = false;
	}
	
	/*for(new i; i < 3; i++)
	{
		//ServerCommand("setinfo \"%s\" \"%s\"", g_szInfo[i], g_szNextModProps[i])
		SetConVarString(g_pConVars_szInfo[i], g_szNextModProps[i]);
	}*/

	for(new i; i < MODS_PROPS; i++)
	{
		strcopy(g_szCurrModProps[i], sizeof(g_szCurrModProps[]), g_szNextModProps[i]);
		g_szNextModProps[i][0] = 0;
	}
	
	g_iCurrModId = g_iNextModId;
	g_iNextModId = -1;
	g_bNextModChoosed = false;
	g_bVoteStarted = false;
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
		
		PrintToConsole(client, "#. %s", "Mod-Name");
		
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
	
	SetNextMod(iModNum - 1, 0);
	
	new String:szNextModName[60], String:szAdminName[60];
	GetClientName(client, szAdminName, sizeof(szAdminName));
	GetArrayString(gModsArrays[MP_NAME], iModNum - 1, szNextModName, sizeof(szNextModName));
	
	ShowActivity(client, "ADMIN %s: Set next mod to: %s", szAdminName, szNextModName);
	
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
	
	g_iModsCount = 0
	g_bNextModChoosed = false

	ReadFiles();
	PrintToConsole(client, "Successfully loaded %d mods", g_iModsCount);
	
	return Plugin_Handled;
}

public Voting_VoteStarted()
{
	g_bVoteStarted = true;
}

ReadFiles(iCheckCurrModID = 0)
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
		\n;|                                    MultiMod Plugin File                                          |\
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
		nextmap.smx\n\
		playercommands.smx\n\
		reservedslots.smx\n\
		sounds.smx");

		CloseHandle(f);
		return;
	}
	
	ReadFiles2(szMultiModINI, iCheckCurrModID ? true : false);
	
	if( g_bFirstRun )
	{
		StartFirstMod();
		return;
	}
	
	//GetConVarString(g_pConVars_szInfo[1], g_szCurrModProps[1], sizeof(g_szCurrModProps[]) );
	//GetConVarString(g_pConVars_szInfo[2], g_szCurrModProps[2], sizeof(g_szCurrModProps[]) );
}

ReadFiles2(String:szFile[], bool:bCheck = false)
{
	new Handle:f = OpenFile(szFile, "r");
	
	decl String:szLine[60];
	decl String:szModStuff[MODS_PROPS][120];
	
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
				
				if(bCheck)
				{
					if(StrEqual(szModStuff[MP_PLUGIN], g_szCurrModProps[MP_PLUGIN], false))
					{
						g_iCurrModId = g_iModsCount - 1
					}
				}
				
				PrintToServer("%s MOD Loaded: [%s] - [%s] - [%s] - [%s]", szPrefix, szModStuff[MP_NAME], szModStuff[MP_PLUGIN], szModStuff[MP_MAP], szModStuff[MP_CFG]);
				
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
	
	PrintToServer("%s Total MOD count: %d MOD(s)", szPrefix, g_iModsCount);
	
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
	
	// Restart
	new String:szCurrMapName[60];
	GetCurrentMap(szCurrMapName, sizeof(szCurrMapName));
	ServerCommand("changelevel %s", szCurrMapName);
}

SetNextMod(iModNum, iVote = 0)
{
	g_iNextModId = iModNum
	GetArrayString(gModsArrays[MP_NAME], 	g_iNextModId, 		g_szNextModProps[MP_NAME], 		sizeof(g_szNextModProps[]))
	GetArrayString(gModsArrays[MP_PLUGIN], 	g_iNextModId, 		g_szNextModProps[MP_PLUGIN], 	sizeof(g_szNextModProps[]))
	GetArrayString(gModsArrays[MP_MAP], 	g_iNextModId, 		g_szNextModProps[MP_MAP], 		sizeof(g_szNextModProps[]))
	GetArrayString(gModsArrays[MP_CFG], 	g_iNextModId, 		g_szNextModProps[MP_CFG], 		sizeof(g_szNextModProps[]))
	
	g_bNextModChoosed = true;
	if(iVote)
	{
		PrintToChatAll("[SM] Nextmod will be: %s", g_szNextModProps[MP_NAME]);
	}
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
		return;
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
				ReadFileString(f, g_szCurrModProps[MP_PLUGIN], sizeof(g_szCurrModProps[]));
				TrimString(g_szCurrModProps[MP_PLUGIN]);
				CloseHandle(f);
				
				FormatEx(szFile, sizeof(szFile), "%s/disabled/%s", szSMPath, g_szCurrModProps[MP_PLUGIN]);
				FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled/%s", g_szCurrModProps[MP_PLUGIN]);
				if(!DirExists(szFile))
				{
					PrintToServer(" ****** %s", szFile);
					// Move old mods file to disabled
					
					FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled");
				}
			}
		}
	}
	
	else
	{
		FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled/%s", g_szCurrModProps[MP_PLUGIN]);
		FormatEx(szFile, sizeof szFile, "%s/%s", szSMPath, szModPluginFolder);
		
		PrintToServer("** Test: %s", szFile);
		if(!DirExists(szFile))
		{
			FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled");
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
		FormatEx(szNewPath, sizeof(szOldPath), "%s/%s/%s", szSMPath, szModPluginFolder, szFile);
		
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
		
		PrintToServer("** Fail move file!")
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
	
	SetNextMod(iArgs, 0);
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