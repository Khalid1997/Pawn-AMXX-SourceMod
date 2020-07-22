/* --- TO DO ---
- Fix Intermission and do the change log -- DOOOONE
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <nextmap>
#include <multimod>

public Plugin myinfo = 
{
	name = "Multimod Plugin: Core", 
	author = MM_PLUGIN_AUTHOR, 
	description = "Allows multiple mods to be loaded on the server", 
	version = MM_VERSION_STR, 
	url = "No URL"
};

// Maximum number of Mods the server can allow from the multimod base file.
// 0 = Infinite
#define MM_MAX_MODS				0

bool g_bFirstLoad = false;

// Macro instead of a function is easier
#define IsNextModChoosed()		(g_iNextModId != ModIndex_Null)

int g_iModsCount;

int g_iLocked_ModsCount;
int g_iLocked_Save_ModsCount;
int g_iTotalLockedModsCount;

int g_iCurrentModId = ModIndex_Null;
char g_szCurrentModProps[Mod_Props_Total][MM_MAX_MOD_PROP_LENGTH];

char g_szMultiModFolderPath[PLATFORM_MAX_PATH];
char g_szMultiModFolderPath_Mods[PLATFORM_MAX_PATH];
char g_szMultiModBaseFile[] = "multimod.ini";

int g_iNextModId = ModIndex_Null;

ArrayList gModsArrays[Mod_Props_Total];
StringMap gDefaultPluginsTrie;
ArrayList gModsLockArray;

Handle g_hLoadForward;
Handle g_hNextModChangedForward;

bool g_bVotePlugin;
bool g_bHookedIntermission;

enum LoadStatus
{
	LS_None, 
	LS_Restarting, 
	LS_Loaded, 
	LS_Reload
};

LoadStatus g_iLoadStatus = LS_None;

// Settings Values;
bool g_bSetting_RandomFirstMod;
bool g_bSetting_RandomFirstMap;
bool g_bSetting_BlockCurrentMod;

public void OnLibraryRemoved(const char[] szLibName)
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		HookEvent("cs_intermission", EventHook_Intermission, EventHookMode_Post);
		g_bHookedIntermission = true;
		g_bVotePlugin = false;
	}
}

public void OnLibraryAdded(const char[] szLibName)
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		// Unhook as the mm vote plugin will handle the mod changing system.
		if(g_bHookedIntermission == true)
		{
			UnhookEvent("cs_intermission", EventHook_Intermission, EventHookMode_Post);
		}
		
		g_bVotePlugin = true;
	}
}

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrMax)
{
	if(bLate)
	{
		SetFailState("[MultiMod] Please restart map, this plugin cannot be loaded late.");
		return APLRes_Failure;
	}
	
	if(szError[0])
	{
		SetFailState("[MultiMode] Plugin Failed Loading due to error: %s", szError);
		return APLRes_Failure;
	}
	
	
	
	// Initialize before any native call
	FormatEx(g_szMultiModFolderPath, sizeof(g_szMultiModFolderPath), "cfg/%s/", MM_FOLDER_MAIN);
	FormatEx(g_szMultiModFolderPath_Mods, sizeof(g_szMultiModFolderPath_Mods), "cfg/%s/%s/", MM_FOLDER_MAIN, MM_FOLDER_MODS);
	
	CreateNative("MultiMod_BuildPath", Native_BuildPath);
	
	//PrintToServer("[*********************] AskPluginLoad2 Loaded!!!!!! ---- MAIN %d", GetFeatureStatus(FeatureType_Native, "MultiMod_BuildPath") == FeatureStatus_Available);
	
	CreateNative("MultiMod_GetBaseFile", Native_GetBaseFile);
	
	CreateNative("MultiMod_FindModIndex", Native_FindModIndex);
	CreateNative("MultiMod_GetNextModId", Native_GetNextModId);
	CreateNative("MultiMod_GetCurrentModId", Native_GetCurrentModId);
	CreateNative("MultiMod_GetModsCount", Native_GetModsCount);
	
	CreateNative("MultiMod_SetNextMod", Native_SetNextMod);
	
	CreateNative("MultiMod_GetModProp", Native_GetModProp);
	
	CreateNative("MultiMod_GetModFile", Native_GetModFilePath);
	CreateNative("MultiMod_GetModFileEx", Native_GetModFilePathEx);
	
	CreateNative("MultiMod_IsLoaded", Native_IsLoaded);
	
	CreateNative("MultiMod_CanLockMod", Native_CanLockMod);
	CreateNative("MultiMod_GetModLock", Native_GetModBlock);
	CreateNative("MultiMod_SetModLock", Native_SetModBlock);
	CreateNative("MultiMod_GetLockedModsCount", Native_GetBlockedModCount);
	CreateNative("MultiMod_GetBlockArray", Native_GetBlockArray);
	
	CreateNative("MultiMod_IsValidModId", Native_IsValidModId);
	
	CreateNative("MultiMod_PassDifferentModListFromMod", Native_PassDifferentModListFromMod);
	CreateNative("MultiMod_PassDifferentModListFromDifferentMods", Native_PassDifferentModListFromDifferentMods);
	CreateNative("MultiMod_PassModListFromMod", Native_PassModListFromMod);
	
	CreateNative("MultiMod_IsValidFileLine", Native_IsValidFileLine);
	
	g_hLoadForward = CreateGlobalForward("MultiMod_OnLoaded", ET_Ignore, Param_Cell);
	
	// This will only be called when the Multimod is actually loaded.
	g_hNextModChangedForward = CreateGlobalForward("MultiMod_OnNextModChanged", ET_Ignore, Param_Cell, Param_Cell);
	
	RegPluginLibrary(MM_LIB_BASE);
	
	return APLRes_Success;
}

// Do this later, if next mod was not choosed, change to a random map from the map file, and then change to that random mod
public Action EventHook_Intermission(Handle hEvent, char[] szEventName, bool bDontBroadcast)
{
	if (g_iLoadStatus != LS_Loaded)
	{
		return;
	}
	
	if (!IsNextModChoosed())
	{
		char szModName[MM_MAX_MOD_PROP_LENGTH];
		SetNextMod(GetRandomInt(0, g_iModsCount - 1));
		
		GetModProp(g_iNextModId, MultiModProp_Name, szModName, sizeof szModName);
		
		char szMap[MM_MAX_MAP_NAME];
		
		if(!MM_GetRandomMapFromMod(g_iNextModId, szMap, sizeof szMap))
		{
			GetCurrentMap(szMap, sizeof szMap);
		}
		
		MultiMod_PrintToChatAll("The next \x05MOD \x01was randomly chosen to be \x04%s \x01and the next map will be: \x04%s", szModName, szMap);
		SetNextMap(szMap);
	}
}

public void OnAllPluginsLoaded()
{
	//LogMessage("First load 1");
	MultiMod_Settings_Create(MM_SETTING_RANDOM_FIRST_MOD, "1", true, true);
		
	///LogMessage("First load 2");
	MultiMod_Settings_Create(MM_SETTING_RAMDOM_FIRST_MAP, "1", true, true);
		
	//LogMessage("First load 3");
	MultiMod_Settings_Create(MM_SETTING_BLOCK_CURRENT_MOD, "1", true, true);
	
	if (!g_bVotePlugin)
	{
		if(!g_bHookedIntermission)
		{
			HookEvent("cs_intermission", EventHook_Intermission, EventHookMode_Post);
		}
	}
}

public void OnPluginStart()
{	
	// Admin commands
	RegAdminCmd("sm_mm_nextmod", AdminCmdSetNextMod, MM_ACCESS_FLAG_NEXTMOD_BIT, "Set Next Mod", "MultiMod");
	RegAdminCmd("sm_mm_reload", AdminCmdReload, MM_ACCESS_FLAG_ROOT_BIT, "Reload Multimod File", "MultiMod");
	
	gModsArrays[MultiModProp_Name] = CreateArray(MM_MAX_MOD_PROP_LENGTH);
	gModsArrays[MultiModProp_InfoKey] = CreateArray(MM_MAX_MOD_PROP_LENGTH);
	
	gDefaultPluginsTrie = CreateTrie();
	gModsLockArray = CreateArray(1);
	
	g_iNextModId = ModIndex_Null;
	g_iCurrentModId = ModIndex_Null;
	
	CreateMultiModDirectories();
}

public void MultiMod_Settings_OnValueChange(char[] szSettingName, char[] szOldValue, char[] szNewValue)
{
	//LogMessage("MM Main: %s %s", szSettingName, szNewValue);
	
	if(StrEqual(szSettingName, MM_SETTING_RANDOM_FIRST_MOD))
	{
		g_bSetting_RandomFirstMod = view_as<bool>(!!StringToInt(szNewValue));
		//LogMessage("**** called with %d %d", g_bSetting_RandomFirstMod, StringToInt(szNewValue));
	}
	
	else if(StrEqual(szSettingName, MM_SETTING_RAMDOM_FIRST_MAP))
	{
		g_bSetting_RandomFirstMap = view_as<bool>(!!StringToInt(szNewValue));
	}
	
	else if(StrEqual(szSettingName, MM_SETTING_BLOCK_CURRENT_MOD))
	{
		g_bSetting_BlockCurrentMod = view_as<bool>(!!StringToInt(szNewValue));
		
		if(g_iCurrentModId != ModIndex_Null)
		{
			MultiMod_SetModLock(g_iCurrentModId, g_bSetting_BlockCurrentMod ? MultiModLock_Locked : MultiModLock_NotLocked);
		}
	}
}

public void OnPluginEnd()
{
	if (!g_iModsCount)
	{
		return;
	}
	
	// Move Current Mod plugins to disabled
	ChangePlugins(ModIndex_Null);
}

public void OnConfigsExecuted()
{
	ExecCurrentModCfg();
}

void ExecCurrentModCfg()
{
	if (g_iCurrentModId == ModIndex_Null)
	{
		return;
	}
	
	char szModConfigFile[PLATFORM_MAX_PATH];
	//GetMultiModFilePath(g_iCurrentModId, MultiModFile_Config, szModConfigFile, sizeof szModConfigFile, false, true, false);
	
	//Format(szModConfigFile, sizeof(szModConfigFile), "%s/%s/%s", MM_FOLDER_MAIN, MM_FOLDER_MODS, szModConfigFile);
	GetModProp(g_iCurrentModId, MultiModProp_InfoKey, szModConfigFile, sizeof szModConfigFile);
	
	/*
	GetMultiModFilePath(int iModId, MultiModFile iFileType, char[] szFile, int iSize, 
						bool bPath = true, 
						bool bIncludeKey = true, 
						bool bIncludeExt = true)
	*/
	
	//FormatEx(g_szMultiModFolderPath_Mods, sizeof(g_szMultiModFolderPath_Mods), "cfg/%s/%s", MM_FOLDER_MAIN, MM_FOLDER_MODS);
	ServerCommand("exec \"%s/%s/%s/%s.cfg\"", MM_FOLDER_MAIN, MM_FOLDER_MODS, szModConfigFile, szModConfigFile);
}

public void OnMapStart()
{
	//LogMessage("Called OnMap");
	if(!g_bFirstLoad)
	{	
		//LogMessage("First load 4");
		
		g_bFirstLoad = true;
		//LogMessage("First load 5");
		// Start Loading and preparing the plugin.
		g_iLoadStatus = LS_None;
		
		//LogMessage("**** READ");
		ReadFiles();
	}
	
	if (!IsPluginProperlyLoaded())
	{
		return;
	}
	
	if (g_iCurrentModId != ModIndex_Null)
	{
		if (g_bSetting_BlockCurrentMod)
		{
			MultiMod_SetModLock(g_iCurrentModId, MultiModLock_Locked);
		}
		
		char szMapName[MM_MAX_MAP_NAME]; GetCurrentMap(szMapName, sizeof szMapName);
		
		char szModProps[Mod_Props_Total][MM_MAX_MOD_PROP_LENGTH];
		GetModProp(g_iCurrentModId, MultiModProp_Name, szModProps[MultiModProp_Name], sizeof(szModProps[]));
		GetModProp(g_iCurrentModId, MultiModProp_InfoKey, szModProps[MultiModProp_InfoKey], sizeof(szModProps[]));
		
		MultiMod_LogMessage("[MultiMod] Loaded Mod \"%s\" on map \"%s\" with Data: %s:%s", 
			szModProps[MultiModProp_Name], szMapName, 
			szModProps[MultiModProp_Name], szModProps[MultiModProp_InfoKey]);
		
		char szMapListPath[PLATFORM_MAX_PATH];
		GetMultiModFilePath(g_iCurrentModId, MultiModFile_Maps, szMapListPath, sizeof szMapListPath, true, true, true);
		
		SetMapListCompatBind("sm_map menu", szMapListPath);
		SetMapListCompatBind("sm_votemap menu", szMapListPath);
	}
}

public void OnMapEnd()
{
	if (!IsNextModChoosed())
	{
		SetNextMod(g_iCurrentModId);
		MultiMod_PrintDebug("2 Next Mod Set to %d", g_iCurrentModId);
	}
	
	ChangePlugins(g_iNextModId);
	
	if (IsNextModChoosed())
	{
		// Set current mod to the "was" next mod
		g_iCurrentModId = g_iNextModId;
		
		// Cancel next mod because the next mod has already been changed to current mod.
		SetNextMod(ModIndex_Null);
		
		GetModProp(g_iCurrentModId, MultiModProp_Name, g_szCurrentModProps[MultiModProp_Name], sizeof g_szCurrentModProps[]);
		GetModProp(g_iCurrentModId, MultiModProp_InfoKey, g_szCurrentModProps[MultiModProp_InfoKey], sizeof g_szCurrentModProps[]);
	}
	
	// Reset locked mods, except saved
	for (int i; i < g_iModsCount; i++)
	{
		switch(view_as<MultiModLock>( GetArrayCell(gModsLockArray, i) ) )
		{
			case MultiModLock_Locked_Save:
			{
				continue;
			}
			
			case MultiModLock_NotLocked:
			{
				continue;
			}
			
			case MultiModLock_Locked:
			{
				--g_iLocked_ModsCount;
				--g_iTotalLockedModsCount;
				SetArrayCell(gModsLockArray, i, MultiModLock_NotLocked);
			}
		}
	}
}

bool IsPluginProperlyLoaded()
{
	// If the server was already running, and we no longer have mods running now.
	if (g_iLoadStatus == LS_Reload)
	{
		g_iLoadStatus = LS_Loaded;
		
		if (!g_iModsCount)
		{
			MultiMod_LogMessage("[MultiMod] Could not find any MODs to start. ERRCDE: 3");
			g_iLoadStatus = LS_None;
			return false;
		}
		
		CallLoadForward(true);
		
		// We finally loaded the plugin properly.
		return true;
	}
	
	if (g_iLoadStatus == LS_Loaded)
	{
		if (!g_iModsCount)
		{
			MultiMod_LogMessage("[MultiMod] Could not find any MODs to start. ERRCDE: 1");
			g_iLoadStatus = LS_None;
			return false;
		}
		
		return true;
	}
	
	// Plugin just started, check if we have mods to actually start.
	if (g_iLoadStatus == LS_None)
	{
		if (!g_iModsCount)
		{
			MultiMod_LogMessage("[MultiMod] Could not find any MODs to start. ERRCDE: 2");
			return false;
		}
		
		g_iLoadStatus = LS_Restarting;
		
		// Set the first MOD
		//LogMessage("*** Random FirstMod: %d", g_bSetting_RandomFirstMod);
		if(g_bSetting_RandomFirstMod)
		{
			SetNextMod(GetRandomInt(0, g_iModsCount - 1));
		}
		
		else
		{
			SetNextMod(0);
		}
		
		MultiMod_PrintDebug("NextMod Set To %d", g_iNextModId);
		
		// Set the first map.
		char szRestartMap[MM_MAX_MAP_NAME];
		
		if(g_bSetting_RandomFirstMap)
		{
			if (!MM_GetRandomMapFromMod(g_iNextModId, szRestartMap, sizeof szRestartMap))
			{
				GetCurrentMap(szRestartMap, sizeof szRestartMap);
			}
		}
		
		else
		{
			GetCurrentMap(szRestartMap, sizeof szRestartMap);
		}
		
		DataPack hPack = CreateDataPack();
		WritePackString(hPack, szRestartMap);
		CreateTimer(0.0, Timer_ChangeToMap, hPack);
		
		// Plugin is not properly loaded yet
		return false;
	}
	
	if (g_iLoadStatus == LS_Restarting)
	{
		g_iLoadStatus = LS_Loaded;
		CallLoadForward(false);
		
		// We finally loaded the plugin properly.
		return true;
	}
	
	return false;
}

public Action Timer_ChangeToMap(Handle hPlugin, DataPack hPack)
{
	char szMap[MM_MAX_MAP_NAME];
	ResetPack(hPack);
	ReadPackString(hPack, szMap, sizeof szMap);
	
	delete hPack;
	
	MultiMod_PrintDebug("Changed Map to %s", szMap);
	//ServerCommand("changelevel %s", szMap);
	ForceChangeLevel(szMap, "Mod Change");
}

public Action AdminCmdSetNextMod(int client, int iArgsCount)
{
	if (!g_iModsCount)
	{
		ReplyToCommand(client, "** There are no MODs to choose from.");
		return Plugin_Handled;
	}
	
	/*
	if (g_bVotePlugin && MultiMod_Vote_GetVoteStatus() == MultiModVoteStatus_Running)
	{
		ReplyToCommand(client, "** Voting has already started. Can't set the next mod.");
		return Plugin_Handled;
	}*/
	
	if (iArgsCount < 1)
	{
		ReplyToCommand(client, "Usage: sm_mm_nextmod [\"Mod Number\"-or-\"cancel\"]");
		
		char szModName[MM_MAX_MOD_PROP_LENGTH];
		int iArraySize = GetArraySize(gModsArrays[MultiModProp_Name]);
		
		ReplyToCommand(client, "Current ModId: %d", g_iCurrentModId + 1);
		ReplyToCommand(client, "#. [Mod Name]");
		
		for (int i; i < iArraySize; i++)
		{
			GetArrayString(gModsArrays[MultiModProp_Name], i, szModName, sizeof(szModName));
			ReplyToCommand(client, "%d. %s %s", i + 1, szModName, i == g_iCurrentModId ? "[Current Mod]" : "");
		}
		
		return Plugin_Handled;
	}
	
	char szModNum[5];
	GetCmdArg(1, szModNum, sizeof(szModNum));
	
	if(StrEqual(szModNum, "cancel"))
	{
		if(g_iNextModId != ModIndex_Null)
		{
			SetNextMod(ModIndex_Null);
			ReplyToCommand(client, "Canceled the chosen next Mod.");
		}
		
		return Plugin_Handled;
	}
	
	int iModNum = StringToInt(szModNum) - 1;
	
	if (!IsValidModId(iModNum))
	{
		ReplyToCommand(client, "** You must use a valid mod number");
		return Plugin_Handled;
	}
	
	SetNextMod(iModNum);
	
	char szNextModName[MM_MAX_MOD_PROP_LENGTH], szAdminName[MAX_NAME_LENGTH];
	GetClientName(client, szAdminName, sizeof(szAdminName));
	GetArrayString(gModsArrays[MultiModProp_Name], iModNum - 1, szNextModName, sizeof(szNextModName));
	
	//ShowActivity(client, "\x01%s ADMIN %s: Set next mod to: %s", szAdminName, szNextModName);
	ReplyToCommand(client, "Next mod successfully set to %s", szNextModName);
	MultiMod_PrintToChat(client, "ADMIN \x04%s\x01: Set next mod to: \x05%s", szAdminName, szNextModName);
	
	return Plugin_Handled;
}

public Action AdminCmdReload(int client, int iArgsCount)
{
	if (g_bVotePlugin && MultiMod_Vote_GetVoteStatus() >= MultiModVoteStatus_Running)
	{
		ReplyToCommand(client, "** Voting has already started. Can't reload now.");
		return Plugin_Handled;
	}
	
	if (iArgsCount < 1)
	{
		ReplyToCommand(client, "This will reload the MM file, and will cancel any next Mod choosen\
								\nIf you want to procceed, write sm_mm_reload \"confirm\" to continue.");
		return Plugin_Handled;
	}
	
	char szArg[10];
	GetCmdArg(1, szArg, sizeof szArg);
	
	if (!StrEqual(szArg, "confirm", false))
	{
		ReplyToCommand(client, "Fail: Arg is not \"confirm\". Write sm_mm_reload for more info.");
		return Plugin_Handled;
	}
	
	ResetMultiMod();
	// Read Files
	
	g_iLoadStatus = LS_Reload;
	ReadFiles(true);
	
	ReplyToCommand(client, "Successfully loaded %d mods", g_iModsCount);
	return Plugin_Handled;
}

void ResetMultiMod()
{
	for (int i; i < Mod_Props_Total; i++)
	{
		ClearArray(gModsArrays[i]);
	}
	
	ClearTrie(gDefaultPluginsTrie);
	ClearArray(gModsLockArray);
	
	g_iLocked_ModsCount = 0;
	g_iLocked_Save_ModsCount = 0;
	g_iTotalLockedModsCount = 0;
	
	g_iModsCount = 0;
	
	SetNextMod(ModIndex_Null);
}

/* 
1. Server will run
2. Serevr will check for mods
3. 
	a. If there are mods, server will restart using that mod and map.
	b. If there are no mods, server will wwait until the plugin is reloaded or map restarted, and check again. until a happens

*/

void ReadFiles(bool bCheckCurrModID = false)
{
	char szMultiModINI[PLATFORM_MAX_PATH];
	GetMultiModFilePath(ModIndex_Null, view_as<MultiModFile>(0), szMultiModINI, sizeof szMultiModINI, true);
	
	CreateMultiModDirectories();
	
	ReadFiles_ModFiles(szMultiModINI, bCheckCurrModID);
	
	if (bCheckCurrModID)
	{
		IsPluginProperlyLoaded();
	}
}

void CreateMultiModDirectories()
{
	char szMultiModINI[PLATFORM_MAX_PATH];
	GetMultiModFilePath(ModIndex_Null, view_as<MultiModFile>(0), szMultiModINI, sizeof szMultiModINI, true);
	
	if (!FileExists(szMultiModINI))
	{
		if (!DirExists(g_szMultiModFolderPath))
		{
			//PrintToServer("********************** CREATED FILE ***********************");
			//PrintToServer("%s", g_szMultiModFolderPath);
			CreateDirectory(g_szMultiModFolderPath, 0);
			CreateDirectory(g_szMultiModFolderPath_Mods, 0);
			//PrintToServer("%s", g_szMultiModFolderPath_Mods);
			//PrintToServer("********************** CREATED FILE ***********************");
		}
		
		MM_CreateMultiModFile(FILE_BASE, szMultiModINI);
		return;
	}
}

void ReadFiles_ModFiles(char[] szMMFile, bool bCheckCurrModID = false)
{
	File f = OpenFile(szMMFile, "r");
	
	char szLine[MM_MAX_FILE_LINE_LENGTH];
	char szModStuff[Mod_Props_Total][MM_MAX_MOD_PROP_LENGTH];
	
	int iPhase;
	
	#define PHASE_SEARCH_MODS 1
	#define PHASE_SEARCH_PLUGINS 2
	
	bool bFound = false;
	int iLen;
	
	while ( ReadFileLine(f, szLine, sizeof(szLine) ) )
	{
		TrimString(szLine);
		ReplaceString(szLine, sizeof szLine, "\"", "");
		
		if (!IsValidFileLine(szLine))
		{
			continue;
		}
		
		if( ( iLen = StrContains(szLine, "#") ) != -1 )
		{
			szLine[iLen] = 0;
		}
		
		if( ( iLen = StrContains(szLine, ";") ) != -1 )
		{
			szLine[iLen] = 0;
		}
		
		if( ( iLen = StrContains(szLine, "//") ) != -1 )
		{
			szLine[iLen] = 0;
		}
		
		if (StrEqual(szLine, DEFAULT_PLUGINS_KEY))
		{
			iPhase = PHASE_SEARCH_PLUGINS;
			continue;
		}
		
		else if (StrEqual(szLine, MODS_KEY))
		{
			iPhase = PHASE_SEARCH_MODS;
			continue;
		}
		
		switch (iPhase)
		{
			case PHASE_SEARCH_MODS:
			{
				//PrintToServer(szLine);
				ExplodeString(szLine, ":", szModStuff, sizeof(szModStuff), sizeof(szModStuff[]), true);
				//PrintToServer("iSplit: %d", iSplit);
				
				++g_iModsCount;
				
				PushArrayString(gModsArrays[MultiModProp_Name], szModStuff[MultiModProp_Name]);
				PushArrayString(gModsArrays[MultiModProp_InfoKey], szModStuff[MultiModProp_InfoKey]);

				PushArrayCell(gModsLockArray, 0);
				
				if (bCheckCurrModID && !bFound)
				{
					if (StrEqual(szModStuff[MultiModProp_InfoKey], g_szCurrentModProps[MultiModProp_InfoKey], false))
					{
						bFound = true;
						
						g_iCurrentModId = g_iModsCount - 1;
						g_szCurrentModProps[MultiModProp_Name] = szModStuff[MultiModProp_Name];
						
						// Execute this since its reloaded.
						ExecCurrentModCfg();
					}
				}
				
				MultiMod_LogMessage("%s %d MOD Loaded: [%s] - [%s]", 
				"[MultiMod]", g_iModsCount, szModStuff[MultiModProp_Name], szModStuff[MultiModProp_InfoKey]);
				
				CheckMissingModFiles(g_iModsCount - 1);
				
				if (MM_MAX_MODS && g_iModsCount >= MM_MAX_MODS)
				{
					iPhase = 2;
				}
			}
			
			case PHASE_SEARCH_PLUGINS:
			{
				if (StrContains(szLine, ".smx", false) != -1)
				{
					MultiMod_PrintDebug("*** Default plugin add: %s", szLine);
					SetTrieValue(gDefaultPluginsTrie, szLine, 1, true);
				}
			}
		}
	}
	
	MultiMod_LogMessage("Total MOD count: %d MOD(s)", g_iModsCount);
	
	CloseHandle(f);
}

void CheckMissingModFiles(int iModIndex)
{
	char szFilePath[PLATFORM_MAX_PATH];
	MultiMod_BuildPath(MultiModPath_ModFolder, iModIndex, szFilePath, sizeof szFilePath);
	
	if(!DirExists(szFilePath))
	{
		if(!CreateDirectory(szFilePath, 0))
		{
			MultiMod_PrintDebug("Could not create Mod folder: %s", szFilePath);
			return;
		}
	}

	//GetModProp(iModIndex, MultiModProp_Plugins, szFilePath, sizeof szFilePath, true, true, true);
	GetMultiModFilePath(iModIndex, MultiModFile_PluginsDisabled, szFilePath, sizeof szFilePath, true, true, true);
	MM_CreateMultiModFile(FILE_PLUGIN, szFilePath, false, iModIndex);
	PrintToServer("*********** CREDTED FILES %s", szFilePath);
	
	GetMultiModFilePath(iModIndex, MultiModFile_Plugins, szFilePath, sizeof szFilePath, true, true, true);
	MM_CreateMultiModFile(FILE_PLUGIN, szFilePath, false, iModIndex);
	PrintToServer("*********** CREDTED FILES %s", szFilePath);
	
	GetMultiModFilePath(iModIndex, MultiModFile_Maps, szFilePath, sizeof szFilePath, true, true, true);
	MM_CreateMultiModFile(FILE_MAP, szFilePath, false, iModIndex);
	PrintToServer("*********** CREDTED FILES %s", szFilePath);
	
	GetMultiModFilePath(iModIndex, MultiModFile_Config, szFilePath, sizeof szFilePath, true, true, true);
	MM_CreateMultiModFile(FILE_CONFIG, szFilePath, false, iModIndex);
	PrintToServer("*********** CREDTED FILES %s", szFilePath);
}

void SetNextMod(int iModNum)
{
	int iOldNextMod = g_iNextModId;
	g_iNextModId = iModNum;
	
	if (g_iNextModId != iOldNextMod)
	{
		Call_StartForward(g_hNextModChangedForward);
		Call_PushCell(g_iNextModId);
		Call_PushCell(iOldNextMod);
		Call_Finish();
	}
}

void CallLoadForward(bool bReload)
{
	Call_StartForward(g_hLoadForward);
	Call_PushCell(bReload);
	
	Call_Finish();
}

void ChangePlugins(int iModIndex)
{
	if (!g_iModsCount)
	{
		return;
	}
	
	StringMap hTrie = null, hTrieDisabled = null;
	if (iModIndex != ModIndex_Null)
	{
		// void CreatePluginsList(int iModId, HandleType iHandleType, any hHandle, int &iOptionalCount)
		hTrie = CreateTrie();
		CreatePluginsList(iModIndex, HandleType_Trie, hTrie, _, false);
		
		hTrieDisabled = CreateTrie();
		CreatePluginsList(iModIndex, HandleType_Trie, hTrieDisabled, _, true);
	}
	
	char szSourceModPluginsPath[PLATFORM_MAX_PATH];
	char szSourceModPluginsDisabledPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szSourceModPluginsPath, sizeof szSourceModPluginsPath, "plugins");
	BuildPath(Path_SM, szSourceModPluginsDisabledPath, sizeof szSourceModPluginsDisabledPath, "plugins/disabled");
	
	// Make sure disabled folder exists before moving plugins to there;
	
	if (!DirExists(szSourceModPluginsDisabledPath))
	{
		if (!CreateDirectory(szSourceModPluginsDisabledPath, 511))
		{
			delete hTrie;
			SetFailState("Could not create disabled folder in sourcemod/plugins ??!!");
			
			return;
		}
	}
	
	FileType iFileType;
	char szFileName[MM_MAX_PLUGIN_FILE_NAME];
	char szFilePath[PLATFORM_MAX_PATH];
	char szFilePathNew[PLATFORM_MAX_PATH];
	
	DirectoryListing hDir;
	hDir = OpenDirectory(szSourceModPluginsDisabledPath);
	
	while (ReadDirEntry(hDir, szFileName, sizeof szFileName, iFileType))
	{
		MultiMod_PrintDebug("File %s", szFileName);
		if (iFileType != FileType_File)
		{
			MultiMod_PrintDebug("MultiMod: File %s is not of a known type", szFileName);
			continue;
		}
		
		if (!StrContains(szFileName, ".smx", false))
		{
			MultiMod_PrintDebug("Multimod: File %s is not a sourcemod plugin", szFileName);
			continue;
		}
		
		// IN disabled OR ( NOT IN default AND NOT IN List)
		if (
				IsPluginInTrie(hTrieDisabled, szFileName) || 
				(
					!IsPluginInTrie(gDefaultPluginsTrie, szFileName) && 
					!IsPluginInTrie(hTrie, szFileName)
				)
			)
		{
			// Do not move from disabled to plugins
			MultiMod_PrintDebug("Skip On Here: #1 %d %d %d", IsPluginInTrie(hTrieDisabled, szFileName), IsPluginInTrie(gDefaultPluginsTrie, szFileName), IsPluginInTrie(hTrie, szFileName));
			continue;
		}
		
		FormatEx(szFilePath, sizeof szFilePath, "%s/%s", szSourceModPluginsDisabledPath, szFileName);
		FormatEx(szFilePathNew, sizeof szFilePathNew, "%s/%s", szSourceModPluginsPath, szFileName);
		// Move it to plugins
		if (!RenameFile(szFilePathNew, szFilePath))
		{
			MultiMod_PrintDebug("Failed to transfer %s to %s", szFilePath, szFilePathNew);
		}
		
		else
		{
			MultiMod_PrintDebug("Moved file from %s to %s", szFilePath, szFilePathNew);
		}
	}
	
	delete hDir;
	hDir = OpenDirectory(szSourceModPluginsPath);
	
	while (ReadDirEntry(hDir, szFileName, sizeof szFileName, iFileType))
	{
		MultiMod_PrintDebug("File %s", szFileName);
		if (iFileType != FileType_File)
		{
			MultiMod_PrintDebug("MultiMod: File %s is not of a known type", szFileName);
			continue;
		}
		
		if (StrContains(szFileName, ".smx", false) == -1)
		{
			//PrintDebug("Skipped file on #2");
			MultiMod_PrintDebug("Multimod: File %s is not a sourcemod plugin", szFileName);
			continue;
		}
		
		// NOT IN disabled, AND ( IN default OR IN List)
		if (!IsPluginInTrie(hTrieDisabled, szFileName) && 
			(
				IsPluginInTrie(gDefaultPluginsTrie, szFileName) || 
				IsPluginInTrie(hTrie, szFileName)
				)
			)
		{
			MultiMod_PrintDebug("Skip On Here: #2 %d %d %d", IsPluginInTrie(hTrieDisabled, szFileName), IsPluginInTrie(gDefaultPluginsTrie, szFileName), IsPluginInTrie(hTrie, szFileName));
			continue;
		}
		
		FormatEx(szFilePath, sizeof szFilePath, "%s/%s", szSourceModPluginsPath, szFileName);
		FormatEx(szFilePathNew, sizeof szFilePathNew, "%s/%s", szSourceModPluginsDisabledPath, szFileName);
		// Move it to disabled
		if (!RenameFile(szFilePathNew, szFilePath))
		{
			MultiMod_PrintDebug("Failed to transfer %s to %s", szFilePath, szFilePathNew);
		}
		
		else
		{
			MultiMod_PrintDebug("Moved file from %s to %s", szFilePath, szFilePathNew);
		}
	}
	
	delete hDir;
	delete hTrie;
	delete hTrieDisabled;
}

bool IsPluginInTrie(StringMap hTrie, char[] szPlugin)
{
	int iValue;
	
	if (hTrie == null)
	{
		return false;
	}
	
	return GetTrieValue(hTrie, szPlugin, iValue);
}

public int Native_FindModIndex(Handle hPlugin, int iArgs)
{
	char szSearchInfoKey[MM_MAX_MOD_PROP_LENGTH];
	GetNativeString(1, szSearchInfoKey, sizeof szSearchInfoKey);
	
	char szInfoKey[MM_MAX_MOD_PROP_LENGTH];
	
	for(int i; i < g_iModsCount; i++)
	{
		GetArrayString(gModsArrays[MultiModProp_InfoKey], i, szInfoKey, sizeof szInfoKey);
		
		if(StrEqual(szInfoKey, szSearchInfoKey))
		{
			return i;
		}
	}
	
	return ModIndex_Null;
}

public int Native_GetNextModId(Handle hPlugin, int iArgs)
{
	return g_iNextModId;
}

public int Native_GetCurrentModId(Handle hPlugin, int iArgs)
{
	return g_iCurrentModId;
}

public int Native_GetModsCount(Handle hPlugin, int iArgs)
{
	return g_iModsCount;
}

public int Native_SetNextMod(Handle hPlugin, int iArgs)
{
	if (!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Aborted setting next MOD as there are no available MODs");
		return 0;
	}
	
	int iModId = GetNativeCell(1);
	if (iModId != ModIndex_Null && !IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iModId);
		return 0;
	}
	
	SetNextMod(iModId);
	return 1;
}

// native bool MultiMod_GetModProp(int iModId, int iProp, char[] szPropReturn, int iSize);
public int Native_GetModProp(Handle hPlugin, int iArgs)
{	
	int iModId = GetNativeCell(1);
	if (!IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iModId);
		return;
	}
	
	int iProp = GetNativeCell(2);
	if (!(0 <= iProp < Mod_Props_Total))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong Prop Index passed (%d)", iProp);
		return;
	}
	
	int iSize = GetNativeCell(4);
	char[] szData = new char[iSize];
	
	GetModProp(iModId, iProp, szData, iSize);
	SetNativeString(3, szData, iSize);
}

public int Native_BuildPath(Handle hPlugin, int iArgs)
{
	MultiModPath iPath = view_as<MultiModPath>(GetNativeCell(1));
	
	int iSize = GetNativeCell(4);
	char szFormatOutput[128];
	
	int iLen;
	FormatNativeString(0, 5, 6, sizeof szFormatOutput, iLen, szFormatOutput, _);
	
	char[] szBuildString = new char[iSize];
	
	switch (iPath)
	{
		case MultiModPath_Base:
		{
			iLen = FormatEx(szBuildString, iSize, "%s%s", g_szMultiModFolderPath, szFormatOutput);
		}
		
		case MultiModPath_Mods:
		{
			iLen = FormatEx(szBuildString, iSize, "%s%s", g_szMultiModFolderPath_Mods, szFormatOutput);

		}
		
		case MultiModPath_ModFolder:
		{
			char szModProp[MM_MAX_MOD_PROP_LENGTH];
			GetModProp(GetNativeCell(2), MultiModProp_InfoKey, szModProp, sizeof szModProp);
			iLen = FormatEx(szBuildString, iSize, "%s/%s/%s", g_szMultiModFolderPath_Mods, szModProp, szFormatOutput);
		}
	}

	SetNativeString(3, szBuildString, iSize);
	return iLen;
}

public int Native_GetBaseFile(Handle hPlugin, int iArgs)
{
	char szFormat[PLATFORM_MAX_PATH];
	GetMultiModFilePath(ModIndex_Null, view_as<MultiModFile>(0), szFormat, sizeof szFormat, GetNativeCell(3));
	SetNativeString(1, szFormat, GetNativeCell(2));
}

public int Native_GetModFilePath(Handle hPlugin, int iArgs)
{
	int iModId = GetNativeCell(1);
	
	if (!IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid Mod Index (%d) (Max: %d)", iModId, g_iModsCount);
		return;
	}
	
	int iSize = GetNativeCell(4);
	char[] szFilePath = new char[iSize];
	GetMultiModFilePath(iModId, view_as<MultiModFile>(GetNativeCell(2)), szFilePath, iSize, true, true, true);
	
	SetNativeString(3, szFilePath, iSize);
}

public int Native_GetModFilePathEx(Handle hPlugin, int iArgs)
{
	int iModId = GetNativeCell(1);
	
	if (!IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid Mod Index (%d) (Max: %d)", iModId, g_iModsCount);
		return;
	}
	
	int iSize = GetNativeCell(4);
	char[] szFilePath = new char[iSize];
	GetMultiModFilePath(iModId, view_as<MultiModFile>(GetNativeCell(2)), szFilePath, iSize, 
		view_as<bool>(GetNativeCell(5)), view_as<bool>(GetNativeCell(6)), view_as<bool>(GetNativeCell(7)));
	
	SetNativeString(3, szFilePath, iSize);
}

void GetModProp(int iIndex, int iProp, char[] szData, int iSize)
{
	GetArrayString(gModsArrays[iProp], iIndex, szData, iSize);
}

void GetMultiModFilePath(int iModId, MultiModFile iFileType, char[] szFile, int iSize, 
	bool bPath = true, 
	bool bIncludeKey = true, 
	bool bIncludeExt = true)
{	
	if (iModId == ModIndex_Null)
	{
		if (bPath)
		{
			FormatEx(szFile, iSize, "%s/%s", g_szMultiModFolderPath, g_szMultiModBaseFile);
		}
		
		else
		{
			FormatEx(szFile, iSize, g_szMultiModBaseFile);
		}
		
		return;
	}
	
	char szData[PLATFORM_MAX_PATH];
	char szModProp[MM_MAX_MOD_PROP_LENGTH];
	GetModProp(iModId, MultiModProp_InfoKey, szModProp, sizeof szModProp);
	
	switch (iFileType)
	{
		case MultiModFile_Plugins:
		{
			
			FormatEx(szData, sizeof szData, "%s%s%s", szModProp, bIncludeKey ? MM_PLUGIN_FILE_KEY : "", bIncludeExt ? MM_PLUGIN_FILE_EXT : "");
			//bPath = true;
		}
		
		case MultiModFile_PluginsDisabled:
		{
			FormatEx(szData, sizeof szData, "%s%s%s%s", szModProp, bIncludeKey ? MM_PLUGIN_FILE_KEY : "", bIncludeKey ? MM_PLUGIN_DISABLE_FILE_KEY : "",  bIncludeExt ? MM_PLUGIN_FILE_EXT : "");
			//bPath = true;
		}
		
		case MultiModFile_Maps:
		{
			FormatEx(szData, sizeof szData, "%s%s%s", szModProp, bIncludeKey ? MM_MAPS_FILE_KEY : "", bIncludeExt ? MM_MAPS_FILE_EXT : "");
			//bPath = true;
		}
		
		case MultiModFile_Config:
		{
			FormatEx(szData, sizeof szData, "%s%s%s", szModProp, bIncludeKey ? MM_CFG_FILE_KEY : "", bIncludeExt ? ".cfg" : "");
			//bPath = true;
		}
		
		/*
		case MultiModProp_ConfigPost:
		{
			FormatEx(szData, sizeof szData, "%s%s%s%s", szModProp, bIncludeKey ? MM_CFG_FILE_KEY : "", bIncludeExt ? "." : "", bIncludeExt ? "cfg" : "");
			bPath = true;
		}
		
		case MultiModProp_ConfigDeactivation:
		{
			FormatEx(szData, sizeof szData, "%s%s%s%s", szModProp, bIncludeKey ? MM_CFG_FILE_KEY : "", bIncludeExt ? "." : "", bIncludeExt ? "cfg" : "");
			bPath = true;
		}
		*/
	}
	
	if (bPath)
	{
		// Use MODS FOLDER PATH
		FormatEx(szFile, iSize, "%s/%s/%s", g_szMultiModFolderPath_Mods, szModProp, szData);
	}
	
	else
	{
		FormatEx(szFile, iSize, "%s", szData);
	}
}

public int Native_GetModBlock(Handle hPlugin, int iArgs)
{
	if (!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "There are no available MODs (Mods count = 0)");
		return -1;
	}
	
	int iModId = GetNativeCell(1);
	if (!IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iModId);
		return 0;
	}
	
	return GetArrayCell(gModsLockArray, iModId);
}

public int Native_CanLockMod(Handle hPlugin, int iArgs)
{
	if (!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "There are no available MODs (Mods count = 0)");
		return 0;
	}
	
	return view_as<int>(CanLockMod());
}

public int Native_SetModBlock(Handle hPlugin, int iArgs)
{
	if (!g_iModsCount)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "There are no available MODs (Mods count = 0)");
		return 0;
	}
	
	int iModId = GetNativeCell(1);
	if (!IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Wrong MOD index passed (%d)", iModId);
		return 0;
	}
	
	MultiModLock iNewLockStatus = view_as<MultiModLock>(GetNativeCell(2));
	if (!(MultiModLock_NotLocked <= iNewLockStatus <= MultiModLock_Locked_Save))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid Lock type argument. (%d)", iNewLockStatus);
		return 0;
	}
	
	MultiModLock iOldLockStatus = GetArrayCell(gModsLockArray, iModId);
	
	switch (iOldLockStatus)
	{
		case MultiModLock_NotLocked:
		{
			// I can't lock new mods.
			// I can however, change the lock type of other mods.
			if(!CanLockMod())
			{
				return 0;
			}
		}
		
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
		case MultiModLock_NotLocked:
		{
			// Do nothing.
		}
		
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
	
	SetArrayCell(gModsLockArray, iModId, iNewLockStatus);
	return 1;
}

bool CanLockMod()
{
	// Keep atleast 1 mod not locked.
	if(g_iTotalLockedModsCount + 1 == g_iModsCount)
	{
		return false;
	}
	
	return true;
}

public int Native_GetBlockedModCount(Handle hPlugin, int iArgs)
{
	MultiModLock iLockType = GetNativeCell(1);
	
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

public int Native_IsLoaded(Handle hPlugin, int iArgs)
{
	return view_as<int>(g_iLoadStatus == LS_Loaded);
}

public int Native_GetBlockArray(Handle hPlugin, int iArgs)
{
	return view_as<int>(gModsLockArray);
}

public int Native_IsValidFileLine(Handle hPlugin, int iArgs)
{
	int iLen;
	if (GetNativeStringLength(1, iLen) == SP_ERROR_NONE)
	{
		char[] szLine = new char[iLen];
		GetNativeString(1, szLine, iLen);
		
		return view_as<int>(IsValidFileLine(szLine));
	}
	
	return false;
}

/*
void MM_PrintToChat(int client, char[] szMessage, any...)
{
	char szBuffer[256];
	int iLen = FormatEx(szBuffer, sizeof szBuffer, " \x01%s \x01", CHAT_PREFIX);
	
	VFormat(szBuffer[iLen], sizeof(szBuffer) - iLen, szMessage, 3);
	
	if (client == 0)
	{
		PrintToChatAll(szBuffer);
	}
	
	else
	{
		PrintToChat(client, szBuffer);
	}
}
*/

public int Native_IsValidModId(Handle hPlugin, int iArgs)
{
	return view_as<int>(IsValidModId(GetNativeCell(1)));
}

stock bool IsValidModId(int iModId)
{
	//if( 0 <= iModId < MultiMod_GetModsCount() )
	if (0 <= iModId < g_iModsCount)
	{
		return true;
	}
	
	return false;
}

public int Native_PassDifferentModListFromDifferentMods(Handle hPlugin, int iArgs)
{
	int iSize = GetNativeCell(2);
	
	int[] iMods = new int[iSize];
	HandleType[] iHandleTypes = new HandleType[iSize];
	any[] hHandles = new any[iSize];
	ModList[] iListTypes = new ModList[iSize];
	int[] iOptionalCount = new int[iSize];
	
	GetNativeArray(1, iMods, iSize);
	GetNativeArray(3, iListTypes, iSize);
	GetNativeArray(4, iHandleTypes, iSize);
	GetNativeArray(5, hHandles, iSize);
	
	GetModArrayLists(1, iMods, iListTypes, iHandleTypes, hHandles, iOptionalCount, hPlugin, GetNativeFunction(7), GetNativeCell(8));
	
	SetNativeArray(6, iOptionalCount, iSize);
}

public int Native_PassDifferentModListFromMod(Handle hPlugin, int iArgs)
{
	int iModId = GetNativeCell(1);
	if (!IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid MOD index: passed (%d), MODs count (%d)", iModId, g_iModsCount);
		return;
	}
	
	int iSize = GetNativeCell(2);
	
	int[] iMods = new int[iSize]; SetArrayValue(iMods, iSize, iModId);
	HandleType[] iHandleTypes = new HandleType[iSize];
	any[] hHandles = new any[iSize];
	ModList[] iListTypes = new ModList[iSize];
	int[] iOptionalCount = new int[iSize];
	
	GetNativeArray(3, iListTypes, iSize);
	GetNativeArray(4, iHandleTypes, iSize);
	GetNativeArray(5, hHandles, iSize);
	
	GetModArrayLists(1, iMods, iListTypes, iHandleTypes, hHandles, iOptionalCount, hPlugin, GetNativeFunction(7), GetNativeCell(8));
	
	SetNativeArray(6, iOptionalCount, iSize);
}

public int Native_PassModListFromMod(Handle hPlugin, int iArgs)
{
	int iModId = GetNativeCell(1);
	if (!IsValidModId(iModId))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid MOD index: passed (%d), MODs count (%d)", iModId, g_iModsCount);
		return;
	}
	
	int iMods[1];
	HandleType iHandleTypes[1];
	any hHandles[1];
	ModList iListTypes[1];
	int iOptionalCount[1];
	
	iMods[0] = iModId;
	iListTypes[0] = GetNativeCell(2);
	iHandleTypes[0] = GetNativeCell(3);
	hHandles[0] = GetNativeCell(4);
	
	GetModArrayLists(1, iMods, iListTypes, iHandleTypes, hHandles, iOptionalCount, hPlugin, GetNativeFunction(6), GetNativeCell(7));
	SetNativeCellRef(5, iOptionalCount[0]);
}

void GetModArrayLists(int iSize, int[] iMods, ModList[] iListTypes, HandleType[] iHandleTypes, int[] hHandles, int[] iOptionalCount, Handle hPlugin, 
	Function Callback, any data)
{
	for (int i; i < iSize; i++)
	{
		if (!IsValidModId(iMods[i]))
		{
			iOptionalCount[i] = 0;
			continue;
		}
		
		switch (iListTypes[i])
		{
			case ModList_Plugins:
			{
				CreatePluginsList(iMods[i], iHandleTypes[i], hHandles[i], iOptionalCount[i], false, hPlugin, Callback, data);
			}
			
			case ModList_PluginsDisabled:
			{
				CreatePluginsList(iMods[i], iHandleTypes[i], hHandles[i], iOptionalCount[i], true, hPlugin, Callback, data);
			}
			
			case ModList_Maps:
			{
				CreateMapList(iMods[i], iHandleTypes[i], hHandles[i], iOptionalCount[i], hPlugin, Callback, data);
			}
		}
	}
}

void CreatePluginsList(int iModId, HandleType iHandleType, any hHandle, int &iOptionalCount = 0, bool bDisabled = false, 
	Handle hPlugin = INVALID_HANDLE, Function Callback = INVALID_FUNCTION, any data = 0)
{
	char szPluginFilePath[PLATFORM_MAX_PATH];
	
	ModList iList;
	switch (bDisabled)
	{
		case false:
		{
			iList = ModList_Plugins;
			GetMultiModFilePath(iModId, MultiModFile_Plugins, szPluginFilePath, sizeof szPluginFilePath, true, true, true);
		}
		
		case true:
		{
			iList = ModList_PluginsDisabled;
			GetMultiModFilePath(iModId, MultiModFile_PluginsDisabled, szPluginFilePath, sizeof szPluginFilePath, true, true, true);
		}
	}
	
	iOptionalCount = 0;
	if (!FileExists(szPluginFilePath))
	{
		iOptionalCount = 0;
		MultiMod_PrintDebug("Could not open %s", szPluginFilePath);
		return;
	}
	
	File f = OpenFile(szPluginFilePath, "r");
	char szLine[MM_MAX_FILE_LINE_LENGTH];
	
	MMReturn iRet;
	
	while (!IsEndOfFile(f))
	{
		ReadFileLine(f, szLine, sizeof szLine);
		TrimString(szLine);
		
		MultiMod_PrintDebug("Line %s", szLine);
		if (!IsValidFileLine(szLine))
		{
			continue;
		}
		
		if (!StrContains(szLine, ".smx", true))
		{
			continue;
		}
		
		if (Callback != INVALID_FUNCTION)
		{
			iRet = MMReturn_Continue;
			
			Call_StartFunction(hPlugin, Callback);
			Call_PushCell(iModId);
			Call_PushCell(iList);
			Call_PushString(szLine);
			Call_PushCell(data);
			Call_Finish(iRet);
			
			if (iRet == MMReturn_Stop)
			{
				continue;
			}
		}
		
		iOptionalCount++;
		switch (iHandleType)
		{
			case HandleType_ArrayList:
			{
				PushArrayString(hHandle, szLine);
			}
			
			case HandleType_Trie:
			{
				SetTrieValue(hHandle, szLine, 1, true);
			}
			
			case HandleType_DataPack:
			{
				WritePackString(hHandle, szLine);
			}
		}
		
		MultiMod_PrintDebug("Added %s", szLine);
	}
	
	delete f;
}

// You are supposed to create the Array your self in this.
void CreateMapList(int iModId, HandleType iHandleType, any hHandle, int &iOptionalCount = 0, 
	Handle hPlugin = INVALID_HANDLE, Function Callback = INVALID_FUNCTION, any data = 0)
{
	char szMapsFile[PLATFORM_MAX_PATH];
	GetMultiModFilePath(iModId, MultiModFile_Maps, szMapsFile, sizeof szMapsFile, true, true, true);
	
	iOptionalCount = 0;
	File f = OpenFile(szMapsFile, "r");
	if (f == null)
	{
		return;
	}
	
	char szLine[MM_MAX_MAP_NAME];
	MMReturn iRet;
	
	while(ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		
		if (!IsValidFileLine(szLine))
		{
			continue;
		}
		
		if (StrContains(szLine, ".bsp", false) != -1)
		{
			ReplaceString(szLine, sizeof szLine, ".bsp", "");
		}
		
		if (!IsMapValid(szLine))
		{
			continue;
		}
		
		if (Callback != INVALID_FUNCTION)
		{
			iRet = MMReturn_Continue;
			
			Call_StartFunction(hPlugin, Callback);
			Call_PushCell(iModId);
			Call_PushCell(ModList_Maps);
			Call_PushString(szLine);
			Call_PushCell(data);
			Call_Finish(iRet);
			
			if (iRet == MMReturn_Stop)
			{
				continue;
			}
		}
		
		++iOptionalCount;
		switch (iHandleType)
		{
			case HandleType_ArrayList:
			{
				PushArrayString(hHandle, szLine);
			}
			
			case HandleType_Trie:
			{
				SetTrieValue(hHandle, szLine, 1, true);
			}
			
			case HandleType_DataPack:
			{
				WritePackString(hHandle, szLine);
			}
		}
	}
	
	delete f;
}

bool IsValidFileLine(char[] szLine)
{
	if (!szLine[0])
	{
		return false;
	}
	
	if (szLine[0] == '#')
	{
		return false;
	}
	
	if (szLine[0] == ';')
	{
		return false;
	}
	
	if (szLine[0] == '/' && szLine[1] == '/')
	{
		return false;
	}
	
	return true;
}

void SetArrayValue(any[] Array, int iSize, any Value)
{
	for (int i = 0; i < iSize; i++)
	{
		Array[i] = Value;
	}
}

