
/* --- TO DO ---
- Fix Intermission and do the change log
*/
#pragma semicolon 1

#include <sourcemod>
#include <nextmap>
#include <multimod_const>
#include <multimod_stocks>

enum
{
	Handle:MP_NAME, 
	Handle:MP_PLUGIN, 
	Handle:MP_MAP, 
	Handle:MP_CFG, 
	
	MODS_PROPS
};

#if !defined MultiModLoad
enum MultiModLoad
{
	MultiModLoad_Loaded, 
	MultiModLoad_Reload, 
	MultiModLoad_ModChange
};
#endif

#if !defined MultiModLock
enum MultiModLock
{
	MultiModLock_NotLocked = 0, 
	MultiModLock_Locked, 
	MultiModLock_Locked_Save, 
	
	MultiModLock_All // For use in GetBlockedModCount
}
#endif

new g_bVoteStarted;

new g_iModsCount;

new g_iLocked_ModsCount;
new g_iLocked_Save_ModsCount;
new g_iTotalLockedModsCount;

new g_iCurrModId = -1;
new String:g_szCurrModProps[MODS_PROPS][60] =  {
	"DEFAULT MOD (NO MODS)", 
	"", 
	"", 
	""
}; // dont make decl

new g_iNextModId = -1;
new String:g_szNextModProps[MODS_PROPS][60];
new bool:g_bNextModChoosed = false;

new Handle:gModsArrays[MODS_PROPS];
new Handle:gDefaultPluginsArray;
new Handle:gModsLockArray;

new Handle:g_hLoadForward;
new Handle:g_hNextModChangedForward;

new MultiModLoad:g_iLoadForward_LoadStatus;
new bool:g_bRestarting = false; // Needed for first run and loadstatus
new bool:g_bLoaded = false;
new bool:g_bFirstRun = true;

public Plugin:myinfo = 
{
	name = "Multimod Plugin: Base", 
	author = "Khalid", 
	description = "Allows multiple mods to be loaded on the server", 
	version = MM_VERSION_STR, 
	url = "No URL"
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLate, String:szError[], iErrMax)
{
	if (bLate)
	{
		LogError("Please unload plugin and changemap.");
		return APLRes_Failure;
	}
	
	CreateNative("MultiMod_GetNextModId", Native_GetNextModId);
	CreateNative("MultiMod_GetCurrentModId", Native_GetCurrentModId);
	CreateNative("MultiMod_GetModsCount", Native_GetModsCount);
	
	CreateNative("MultiMod_SetNextMod", Native_SetNextMod);
	
	CreateNative("MultiMod_GetNameArray", Native_GetNameArray);
	CreateNative("MultiMod_GetPluginFolderArray", Native_GetPluginFolderArray);
	CreateNative("MultiMod_GetMapFileArray", Native_GetMapFileArray);
	CreateNative("MultiMod_GetConfigFileArray", Native_GetConfigFileArray);
	
	CreateNative("MultiMod_GetModProp", Native_GetModProp);
	
	CreateNative("MultiMod_IsLoaded", Native_IsLoaded);
	
	CreateNative("MultiMod_GetModLock", Native_GetModBlock);
	CreateNative("MultiMod_SetModLock", Native_SetModBlock);
	CreateNative("MultiMod_GetLockedModsCount", Native_GetBlockedModCount);
	CreateNative("MultiMod_GetBlockArray", Native_GetBlockArray);
	
	RegPluginLibrary(MM_LIB_BASE);
	
	HookEvent("cs_intermission", EventHook_Intermission, EventHookMode_Post);
	
	return APLRes_Success;
}

public OnLibraryRemoved(const String:szLibName[])
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		HookEvent("cs_intermission", EventHook_Intermission, EventHookMode_Post);
	}
}

public OnLibraryAdded(const String:szLibName[])
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		UnhookEvent("cs_intermission", EventHook_Intermission, EventHookMode_Post);
	}
}

/*
ReadFiles_ModMaps(iModId, &Handle:hMapListHandle = INVALID_HANDLE)
{
	#define MAX_MAP_NAME_LENGTH		60
	
	new String:szMapsFile[60];
	MultiMod_GetModProp(iModId, MultiModProp_Map, szMapsFile, sizeof szMapsFile, true);
	
	new String:szFile[120];
	FormatEx(szFile, sizeof szFile, "cfg/%s/%s", szMapsFile, MM_FOLDER_MAIN, szMapsFile);
	
	new Handle:f = OpenFile(szFile, "r");
	if(f == INVALID_HANDLE)
	{
		LogMessage("****** File not found %s", szFile);
		if(!szMapsFile[0])
		{
			return 0;
		}
		
		f = OpenFile(szFile, "w");
		
		WriteFileLine(f,
		 "# --------------------------------------------------------------------------------------------------\
		\n# |                                    MultiMod Maps File                                            |\
		\n# --------------------------------------------------------------------------------------------------\
		\n# Any line beginning with a ';', '#' or '//' is a comment.\
		\n# Write each map in one line without the .bsp extension.");
		
		CloseHandle(f);
		
		return 0;
	}

	hMapListHandle = CreateArray(MAX_MAP_NAME_LENGTH + 1);
	
	new String:szLine[MAX_MAP_NAME_LENGTH + 1], iMaps;
	while(!IsEndOfFile(f) && ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		
		if(!szLine[0])
		{
			continue;
		}
		
		if(szLine[0] == ';' || szLine[0] == '#' || ( szLine[0] == '/' && szLine[1] == '/' ))
		{
			continue;
		}
		
		if(StrContains(szLine, ".bsp", false) != -1)
		{
			ReplaceString(szLine, sizeof szLine, ".bsp", "");
		}
		
		if(IsMapValid(szLine))
		{
			PushArrayString(hMapListHandle, szLine);
			++iMaps;
		}
	}
	
	CloseHandle(f);
	
	return iMaps;
}*/

public Action:EventHook_Intermission(Handle:hEvent, String:szEventName[], bool:bDontBroadcast)
{
	if (!g_bNextModChoosed)
	{
		//ReadMapsFile(
	}
}

public OnPluginStart()
{
	RegAdminCmd("sm_nextmod", AdminCmdSetNextMod, MM_ACCESS_FLAG_BIT, "Set Next mod", "MultiMod");
	RegAdminCmd("sm_mm_reload", AdminCmdReload, MM_ACCESS_FLAG_BIT, "Set Next mod", "MultiMod");
	
	g_hLoadForward = CreateGlobalForward("MultiMod_Loaded", ET_Ignore, Param_Cell);
	g_hNextModChangedForward = CreateGlobalForward("MultiMod_NextModChanged", ET_Ignore, Param_Cell, Param_Cell);
	
	gModsArrays[MP_NAME] = CreateArray(MAX_MOD_NAME);
	gModsArrays[MP_PLUGIN] = CreateArray(60);
	gModsArrays[MP_CFG] = CreateArray(60);
	gModsArrays[MP_MAP] = CreateArray(60);
	
	gDefaultPluginsArray = CreateArray(60);
	gModsLockArray = CreateArray(1);
	
	g_iLoadForward_LoadStatus = MultiModLoad_Loaded;
	ReadFiles();
}

public OnPluginEnd()
{
	if (!g_iModsCount)
	{
		return;
	}
	
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

ExecCurrentModCfg()
{
	if (g_szCurrModProps[MP_CFG][0])
	{
		new String:szModConfigFile[100];
		FormatEx(szModConfigFile, sizeof(szModConfigFile), "%s/%s", MM_FOLDER_MAIN, g_szCurrModProps[MP_CFG]);
		
		if (StrContains(szModConfigFile, ".cfg", false))
		{
			ReplaceString(szModConfigFile, sizeof(szModConfigFile), ".cfg", "", false);
		}
		
		//AutoExecConfig(true, szMultiModINI, "multimod");
		ServerCommand("exec %s", szModConfigFile);
	}
}

public OnMapStart()
{
	if (g_bFirstRun)
	{
		// Restart
		new String:szCurrMapName[60];
		GetCurrentMap(szCurrMapName, sizeof(szCurrMapName));
		ServerCommand("changelevel %s", szCurrMapName);
		
		g_bRestarting = true;
		return;
	}
	
	if (g_bRestarting)
	{
		g_bRestarting = false;
		
		g_bLoaded = true;
		
		g_iLoadForward_LoadStatus = MultiModLoad_Loaded;
		CallLoadForward();
	}
	
	for (new i; i < MODS_PROPS; i++)
	{
		PrintToServer("** %s", g_szCurrModProps[i]);
	}
	
	for (new i; i < g_iModsCount; i++)
	{
		if (MultiModLock:GetArrayCell(gModsLockArray, i) != MultiModLock_Locked_Save)
		{
			SetArrayCell(gModsLockArray, i, MultiModLock_NotLocked);
		}
	}
	
	ExecCurrentModCfg();
}

public OnMapEnd()
{
	if (!g_iModsCount)
	{
		// Move plugins that are already in plugins folder to their original folder (crash protect);
		ChangePlugins(1);
		if (g_bFirstRun) // keep after changeplugins
		{
			g_bFirstRun = false;
		}
		
		return;
	}
	
	if (g_bNextModChoosed)
	{
		ChangePlugins(0);
		// Keep here (if same mod, dont move and reput.)
		for (new i; i < MODS_PROPS; i++)
		{
			strcopy(g_szCurrModProps[i], sizeof(g_szCurrModProps[]), g_szNextModProps[i]);
			g_szNextModProps[i][0] = 0;
		}
		
		g_iCurrModId = g_iNextModId;
		
		SetNextMod(MM_NEXTMOD_CANCEL);
		
		// NO
		//g_iLoadForward_LoadStatus = MultiModLoad_ModChange;
		//CallLoadForward();
	}
	
	g_bFirstRun = false;
	g_bVoteStarted = false;
}

/*
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:szError[], iErrLen)
{
	return APLRes_Success;
}*/

public Action:AdminCmdSetNextMod(client, iArgs)
{
	if (iArgs < 1)
	{
		PrintToConsole(client, "Usage: sm_nextmod \"Mod Number\"");
		
		new String:szModName[MAX_MOD_NAME];
		new iArraySize = GetArraySize(gModsArrays[MP_NAME]);
		
		PrintToConsole(client, "#. [Mod Name]");
		
		for (new i; i < iArraySize; i++)
		{
			GetArrayString(gModsArrays[MP_NAME], i, szModName, sizeof(szModName));
			PrintToConsole(client, "%d. %s", i + 1, szModName);
		}
		
		return Plugin_Handled;
	}
	
	if (!g_iModsCount)
	{
		PrintToConsole(client, "** There are no mods to choose from.");
		return Plugin_Handled;
	}
	
	if (g_bVoteStarted)
	{
		PrintToConsole(client, "** Voting has already started. Can't set the next mod.");
		return Plugin_Handled;
	}
	
	new String:szModNum[5];
	GetCmdArg(1, szModNum, sizeof(szModNum));
	
	new iModNum = StringToInt(szModNum);
	
	if (!(1 <= iModNum <= g_iModsCount))
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
	if (g_bVoteStarted)
	{
		PrintToConsole(client, "** Voting has already started. Can't reload now.");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		PrintToConsole(client, "This will reload the MM file, and will cancel any next mod choosed\
		\nIf you want to procceed, write sm_mm_reload \"confirm\" to continue.");
		
		return Plugin_Handled;
	}
	
	new String:szArg[10];
	GetCmdArg(1, szArg, sizeof szArg);
	
	if (!StrEqual(szArg, "confirm", false))
	{
		PrintToConsole(client, "Fail: Arg is not \"confirm\". Write sm_mm_reload for more info.");
		return Plugin_Handled;
	}
	
	ResetMultiMod();
	// Read Files
	ReadFiles(true);
	
	g_iLoadForward_LoadStatus = MultiModLoad_Reload;
	CallLoadForward();
	
	PrintToConsole(client, "Successfully loaded %d mods", g_iModsCount);
	
	return Plugin_Handled;
}

ResetMultiMod()
{
	for (new i; i < MODS_PROPS; i++)
	{
		ClearArray(gModsArrays[i]);
	}
	
	ClearArray(gDefaultPluginsArray);
	ClearArray(gModsLockArray);
	
	g_iLocked_ModsCount = 0;
	g_iLocked_Save_ModsCount = 0;
	g_iTotalLockedModsCount = 0;
	
	g_iModsCount = 0;
	
	g_bNextModChoosed = false;
	g_iNextModId = -1;
	
	for (new i; i < MODS_PROPS; i++)
	{
		g_szNextModProps[i][0] = 0;
	}
}

ReadFiles(bool:bCheckCurrModID = false)
{
	new String:szMultiModINI[60];
	new String:szMultiModPath[60];
	
	FormatEx(szMultiModPath, sizeof(szMultiModPath), "cfg/%s", MM_FOLDER_MAIN);
	FormatEx(szMultiModINI, sizeof(szMultiModINI), "%s/multimod.ini", szMultiModPath);
	
	new Handle:f = OpenFile(szMultiModINI, "r");
	if (!f)
	{
		CloseHandle(f);
		
		if (!DirExists(szMultiModPath))
		{
			CreateDirectory(szMultiModPath, 0);
		}
		
		f = OpenFile(szMultiModINI, "w");
		WriteFileLine(f, 
			"# --------------------------------------------------------------------------------------------------\
		\n# |                                    MultiMod Plugin File                                        |\
		\n# --------------------------------------------------------------------------------------------------\
		\n# Any line beginning with a ';', '#' or '//' is a comment\
		\n# Write Mods under %s tag\
		\n# Syntax:\
		\n# Mod Name:Plugin-Folder-Name:MapFileName:CFG\
		\n%s\
		\n\
		\n\
		\n\
		\n# Write Default Plugins under %s tag\
		\n# Default Plugins are plugins that run for ALL MODs\
		\n# They must be placed in plugins folder to work\
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
		nextmap.smx\n\
		playercommands.smx\n\
		reservedslots.smx\n\
		sounds.smx\n\
		multimod.smx\n\
		multimod_vote.smx\n\
		multimod_menu.smx\n\
		multimod_rockthevote.smx\n\
		multimod_nextcurrentmod.smx");
		
		CloseHandle(f);
		return;
	}
	
	ReadFiles_ModFiles(szMultiModINI, bCheckCurrModID);
	
	if (g_bFirstRun)
	{
		StartFirstMod();
		return;
	}
}

ReadFiles_ModFiles(String:szFile[], bool:bCheck = false)
{
	new Handle:f = OpenFile(szFile, "r");
	
	decl String:szLine[200];
	decl String:szModStuff[MODS_PROPS][60];
	
	decl iPhase;
	
	while (!IsEndOfFile(f))
	{
		ReadFileLine(f, szLine, sizeof(szLine));
		TrimString(szLine);
		
		if (!szLine[0])
		{
			continue;
		}
		
		if (szLine[0] == ';' || szLine[0] == '#' || (szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		if (StrEqual(szLine, DEFAULT_PLUGINS_KEY))
		{
			iPhase = 2;
			continue;
		}
		
		else if (StrEqual(szLine, MODS_KEY))
		{
			iPhase = 1;
			continue;
		}
		
		switch (iPhase)
		{
			case 1:
			{
				ExplodeString(szLine, ":", szModStuff, sizeof(szModStuff), sizeof(szModStuff[]), true);
				
				++g_iModsCount;
				
				PushArrayString(gModsArrays[MP_NAME], szModStuff[MP_NAME]);
				PushArrayString(gModsArrays[MP_PLUGIN], szModStuff[MP_PLUGIN]);
				
				PushArrayCell(gModsLockArray, 0);
				
				// maps file does not contain -maps, let the plugin add it
				
				//ClearFileExt(szModStuff[MP_MAP], sizeof szModStuff[MP_MAP]);
				if (StrContains(szModStuff[MP_MAP], MM_MAPS_FILE_KEY) == -1)
				{
					Format(szModStuff[MP_MAP], sizeof szModStuff[], "%s%s", szModStuff[MP_MAP], MM_MAPS_FILE_KEY);
				}
				
				PushArrayString(gModsArrays[MP_MAP], szModStuff[MP_MAP]);
				
				if (StrContains(szModStuff[MP_MAP], MM_MAPS_FILE_KEY))
					PushArrayString(gModsArrays[MP_CFG], szModStuff[MP_CFG]);
				
				
				if (bCheck)
				{
					if (StrEqual(szModStuff[MP_PLUGIN], g_szCurrModProps[MP_PLUGIN], false))
					{
						g_iCurrModId = g_iModsCount - 1;
						g_szCurrModProps[MP_NAME] = szModStuff[MP_NAME];
						g_szCurrModProps[MP_CFG] = szModStuff[MP_CFG];
						g_szCurrModProps[MP_MAP] = szModStuff[MP_MAP];
						
						ExecCurrentModCfg();
					}
				}
				
				LogMessage("%s MOD Loaded: [%s] - [%s] - [%s] - [%s]", "[MultiMod]", szModStuff[MP_NAME], szModStuff[MP_PLUGIN], szModStuff[MP_MAP], szModStuff[MP_CFG]);
				
				if (g_iModsCount >= MAX_MODS)
				{
					iPhase = 2;
				}
			}
			
			case 2:
			{
				if (StrContains(szLine, ".smx", false) != -1)
				{
					LogMessage("*** Default plugin add: %s", szLine);
					PushArrayString(gDefaultPluginsArray, szLine);
				}
			}
		}
	}
	
	LogMessage("%s Total MOD count: %d MOD(s)", "[MULTIMOD]", g_iModsCount);
	
	CloseHandle(f);
}

StartFirstMod()
{
	if (!g_iModsCount)
	{
		LogMessage("[MultiMod] Failed to start first MOD because there are no available MODS to start (Mod count: 0)");
		return;
	}
	
	SetNextMod(0);
	LogMessage("[MultiMod] (First Run) Starting First Mod on the list: %s", g_szNextModProps[MP_NAME]);
}

SetNextMod(iModNum)
{
	new iOldNextMod = g_iNextModId;
	g_iNextModId = iModNum;
	
	if (g_iNextModId == -1)
	{
		g_szNextModProps[MP_NAME] = "";
		g_szNextModProps[MP_PLUGIN] = "";
		g_szNextModProps[MP_MAP] = "";
		g_szNextModProps[MP_CFG] = "";
		
		g_bNextModChoosed = false;
	}
	
	else
	{
		GetArrayString(gModsArrays[MP_NAME], g_iNextModId, g_szNextModProps[MP_NAME], sizeof(g_szNextModProps[]));
		GetArrayString(gModsArrays[MP_PLUGIN], g_iNextModId, g_szNextModProps[MP_PLUGIN], sizeof(g_szNextModProps[]));
		GetArrayString(gModsArrays[MP_MAP], g_iNextModId, g_szNextModProps[MP_MAP], sizeof(g_szNextModProps[]));
		GetArrayString(gModsArrays[MP_CFG], g_iNextModId, g_szNextModProps[MP_CFG], sizeof(g_szNextModProps[]));
		
		g_bNextModChoosed = true;
	}
	
	Call_StartForward(g_hNextModChangedForward);
	Call_PushCell(g_iNextModId);
	Call_PushCell(iOldNextMod);
	Call_Finish();
	
}

public MultiMod_VotingStarted(MultiModVote:iVote, bool:bInstantChange, iNextMod)
{
	g_bVoteStarted = true;
}

CallLoadForward()
{
	Call_StartForward(g_hLoadForward);
	Call_PushCell(g_iLoadForward_LoadStatus);
	
	Call_Finish();
}

ChangePlugins(iDontMoveNextMod = 0)
{
	if (!g_iModsCount)
	{
		return;
	}
	
	new String:szFile[60];
	new String:szSMPath[60];
	
	BuildPath(Path_SM, szSMPath, sizeof(szSMPath), "plugins");
	//FormatEx(szFolder, szSMPath, sizeof(szSMPath), "plugins/%s", g_szNextModProps[1]);
	
	if (!DirExists(szSMPath))
	{
		LogMessage("Plugins folder does not exist?: %s", szFile);
		return;
	}
	
	FormatEx(szFile, sizeof(szFile), "%s/disabled/%s", szSMPath, g_szNextModProps[MP_PLUGIN]);
	if (!DirExists(szFile))
	{
		LogMessage("Directory does not exist: %s", szFile);
		iDontMoveNextMod = 1;
	}
	
	new Handle:hDir = OpenDirectory(szSMPath);
	new FileType:iFileType;
	new String:szOldPath[100], String:szNewPath[100], String:szModPluginFolder[60];
	
	decl Handle:f;
	
	// Crash protect (First Run)
	if (g_bFirstRun)
	{
		if (!g_szCurrModProps[1][0])
		{
			FormatEx(szFile, sizeof(szFile), "%s/lastmod.ini", szSMPath);
			
			if ((f = OpenFile(szFile, "r")))
			{
				ReadFileString(f, g_szCurrModProps[MP_PLUGIN], sizeof(g_szCurrModProps[]));
				TrimString(g_szCurrModProps[MP_PLUGIN]);
				CloseHandle(f);
				
				FormatEx(szFile, sizeof(szFile), "%s/disabled/%s", szSMPath, g_szCurrModProps[MP_PLUGIN]);
				
				if (!DirExists(szFile))
				{
					LogMessage("Crash Protect: Last mod plugin folder does not exist -> %s", szFile);
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
		
		if (!DirExists(szFile))
		{
			FormatEx(szModPluginFolder, sizeof szModPluginFolder, "disabled");
			//FormatEx(szFile, sizeof szFile, "%s/%s", szSMPath, szModPluginFolder); // not needed
		}
	}
	
	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType);
	ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType);
	
	while (ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType))
	{
		if (iFileType != FileType_File)
		{
			continue;
		}
		
		PrintToServer("[1] Plugin Name: %s", szFile);
		
		if (StrContains(szFile, ".smx", false) == -1)
		{
			continue;
		}
		
		if (FindStringInArray(gDefaultPluginsArray, szFile) != -1)
		{
			continue;
		}
		
		FormatEx(szOldPath, sizeof(szOldPath), "%s/%s", szSMPath, szFile);
		FormatEx(szNewPath, sizeof(szNewPath), "%s/%s/%s", szSMPath, szModPluginFolder, szFile);
		
		PrintToServer("*** Rename [%s] -- [%s]", szOldPath, szNewPath);
		if (RenameFile(szNewPath, szOldPath))
		{
			PrintToServer("Moved %s to current mod plugins", szFile);
		}
	}
	
	CloseHandle(hDir);
	
	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	
	if (iDontMoveNextMod)
	{
		PrintToServer("*** Dont move");
		return;
	}
	
	FormatEx(szFile, sizeof(szFile), "%s/disabled/%s", szSMPath, g_szNextModProps[MP_PLUGIN]);
	hDir = OpenDirectory(szFile);
	
	if (hDir == INVALID_HANDLE)
	{
		LogMessage("Next Mod plugin folder does not exist: %s", szFile);
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
	
	while (ReadDirEntry(hDir, szFile, sizeof(szFile), iFileType))
	{
		PrintToServer("[2] Plugin Name: %s", szFile);
		if (iFileType != FileType_File)
		{
			continue;
		}
		
		if (StrContains(szFile, ".smx", false) == -1)
		{
			PrintToServer("** Warning: Not a plugin");
			continue;
		}
		
		FormatEx(szNewPath, sizeof(szOldPath), "%s/%s", szSMPath, szFile);
		FormatEx(szOldPath, sizeof(szOldPath), "%s/disabled/%s/%s", szSMPath, g_szNextModProps[MP_PLUGIN], szFile);
		
		PrintToServer("** szNewPath: %s", szNewPath);
		PrintToServer("** szOldPath %s", szOldPath);
		
		if (RenameFile(szNewPath, szOldPath))
		{
			PrintToServer("Moved %s to plugins", szFile);
		}
		
		else PrintToServer("** Fail move file!");
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
	if (!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Aborted setting next MOD as there are no available MODs");
		return 0;
	}
	
	iArgs = GetNativeCell(1);
	if (!(-1 <= iArgs < g_iModsCount))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iArgs);
		return 0;
	}
	
	SetNextMod(iArgs);
	return 1;
}

public Native_GetModProp(Handle:hPlugin, iArgs)
{
	if (!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Aborted setting next MOD as there are no available MODs");
		return 0;
	}
	
	new iIndex = GetNativeCell(1);
	if (!(0 <= iIndex < g_iModsCount))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iIndex);
		return 0;
	}
	
	new iProp = GetNativeCell(2);
	if (!(0 <= iProp < MODS_PROPS))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iIndex);
		return 0;
	}
	
	new iSize = GetNativeCell(4);
	new String:szData[iSize];
	GetArrayString(gModsArrays[iProp], iIndex, szData, iSize);
	
	if (iProp == _:MultiModProp_Map || iProp == _:MultiModProp_Cfg)
	{
		if (GetNativeCell(5))
		{
			switch (iProp)
			{
				case MultiModProp_Map:
				{
					Format(szData, iSize, "%s.%s", szData, MM_MAPS_FILE_EXT);
				}
				
				case MultiModProp_Cfg:
				{
					Format(szData, iSize, "%s.%s", szData, MM_CFG_FILE_EXT);
				}
			}
		}
	}
	
	SetNativeString(3, szData, iSize);
	return 1;
}

public Native_GetModBlock(Handle:hPlugin, iArgs)
{
	if (g_iModsCount == 0)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "There are no available MODs (Mods count = 0)");
		return false;
	}
	
	new iModId;
	iModId = GetNativeCell(1);
	
	if (!(-1 < iModId < g_iModsCount))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iModId);
		return false;
	}
	
	return GetArrayCell(gModsLockArray, iModId);
}

public Native_SetModBlock(Handle:hPlugin, iArgs)
{
	if (g_iModsCount == 0)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "There are no available MODs (Mods count = 0)");
		return false;
	}
	
	new iModId;
	iModId = GetNativeCell(1);
	
	if (!(-1 < iModId < g_iModsCount))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iModId);
		return false;
	}
	
	new MultiModLock:iNewLockStatus = MultiModLock:GetNativeCell(2);
	if (!(MultiModLock_NotLocked <= iNewLockStatus <= MultiModLock_Locked_Save))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid Lock type argument. (%d)", iNewLockStatus);
		return false;
	}
	
	new MultiModLock:iOldLockStatus = GetArrayCell(gModsLockArray, iModId);
	
	switch (iOldLockStatus)
	{
		case MultiModLock_Locked:
		{
			--g_iLocked_ModsCount;
			--g_iTotalLockedModsCount;
		}
		
		case MultiModLock_Locked_Save:
		{
			--g_iLocked_Save_ModsCount;
			--g_iTotalLockedModsCount;
		}
	}
	
	switch (iNewLockStatus)
	{
		case MultiModLock_Locked:
		{
			++g_iLocked_ModsCount;
			++g_iTotalLockedModsCount;
		}
		
		case MultiModLock_Locked_Save:
		{
			++g_iLocked_Save_ModsCount;
			++g_iTotalLockedModsCount;
		}
	}
	
	//PrintToServer("g_iTotalLockedModsCount = %d .. %d .. %d", g_iTotalLockedModsCount, g_iLocked_Save_ModsCount, g_iLocked_ModsCount);
	
	SetArrayCell(gModsLockArray, iModId, iNewLockStatus);
	return true;
}

public Native_GetBlockedModCount(Handle:hPlugin, iArgs)
{
	new MultiModLock:iLockType = GetNativeCell(1);
	
	if (!(MultiModLock_NotLocked < iLockType <= MultiModLock_All))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid Lock type argument. (%d)", iLockType);
		return -1;
	}
	
	switch (iLockType)
	{
		case MultiModLock_All:return g_iTotalLockedModsCount;
		case MultiModLock_Locked:return g_iLocked_ModsCount;
		case MultiModLock_Locked_Save:return g_iLocked_Save_ModsCount;
	}
	
	return -1;
}

public Native_IsLoaded(Handle:hPlugin, iArgs)
{
	return g_bLoaded;
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
	return _:gModsLockArray;
}

