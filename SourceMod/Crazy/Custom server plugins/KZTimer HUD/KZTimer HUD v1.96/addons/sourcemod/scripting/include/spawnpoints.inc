#include <sourcemod>
#include <sdktools>

ArrayList __spawns,
__rotations;

int __showSpawnsSprite,
__maxSpawns;

bool __canShowSpawns;

Handle __showSpawnsTimer;

int __nextSpawnpoint;

char __configDir[PLATFORM_MAX_PATH-64-7] // PLATFORM_MAX_PATH - max mapname length - strlen(".spawns")
	, __configFile[PLATFORM_MAX_PATH]
	, __pluginName[100];

bool __showingSpawns[MAXPLAYERS+1]
/*	, __hasAddCmd
	, __hasDelCmd
	, __hasShowCmd*/
	, __initialized = false;

enum SCError {
	SC_NoError
	,SC_AlreadyInitialized
	,SC_NotInitialized
	,SC_InvalidPluginName
	,SC_CantShowSpawns
	,SC_MaxSpawnsSaved
	,SC_NoSpawns
};

/** Call this to initialize the library.
 *
 * @param pluginName Plugin name shown to clients on menus, chat messages, etc
 *
 * @param menuCmdName Name of the admin command to show the spawn point editing menu. If this param is empty ("") the command won't be registered.
 * @param menuAdmFlag Menu command admin flags
 *
 * @param addSpawnCmdName Name of the admin command to add a spawn point on the current player location. If this param is empty ("") the command won't be registered.
 * @param addSpawnAdmFlag Add spawn command admin flags
 *
 * @param delSpawnCmdName Name of the admin command to delete the nearest spawn point (on a 64 units radius) to the player. If this param is empty ("") the command won't be registered.
 * @param delSpawnAdmFlag Delete spawn command admin flags
 *
 * @param showSpawnsCmdName Name of the admin command to show the saved spawn points to the player. If this param is empty ("") the command won't be registered.
 * @param showSpawnAdmFlag Show spawns command admin flags
 *
 * @param configFileDir Directory to save .spawns files to.
 *
 * @param maxSpawns Maximum number of spawn points to load/save/allow creation. -1 = infinite.
 *
 * @param showSpawnsSprite Sprite index to use when showing saved spawns. Default is "materials/sprites/glow.vmt".
 *
 * @return SC_NoError if everything went fine
 * @return SC_AlreadyInitialized if the library has already been initialized
 * @return SC_InvalidPluginName if pluginName is not valid
 */
stock SCError SC_Initialize(const char[] pluginName
				   , const char[] menuCmdName
				   , int menuAdmFlag
				   , const char[] addSpawnCmdName
				   , int addSpawnAdmFlag
				   , const char[] delSpawnCmdName
				   , int delSpawnAdmFlag
				   , const char[] showSpawnsCmdName
				   , int showSpawnsAdmFlag
				   , const char[] configFileDir
				   , int maxSpawns = -1
				   )
{
	if (__initialized) {
		return SC_AlreadyInitialized;
	}
	
	__spawns = CreateArray(3);
	__rotations = CreateArray(3);
	
	if (!strlen(pluginName)) {
		__initialized = false;
		return SC_InvalidPluginName;
	}
	
	__maxSpawns = maxSpawns;
	
	if (!strlen(pluginName)) {
		return SC_InvalidPluginName;
	}
	
	strcopy(__pluginName, sizeof __pluginName, pluginName);
	ReplaceString(__pluginName, sizeof __pluginName, " ", "_");
	
	if (strlen(configFileDir) > 1) {
		strcopy(__configDir, sizeof __configDir, configFileDir);
	} else {
		
		strcopy(__configDir, sizeof __configDir, __pluginName); // guarantee per-plugin config isolation
	}
	
	BuildPath(Path_SM, __configDir, sizeof __configDir, __configDir);
	if (!DirExists(__configDir)) {
		CreateDirectory(__configDir, 0x0265);
	}
	
	HookEvent("player_connect", __sc_playerConnect);
	
	char cmdDescription[50];
	
	if (strlen(menuCmdName)) {
		FormatEx(cmdDescription, sizeof cmdDescription, "Spawn point editting menu for plugin %s", pluginName);
		RegAdminCmd(menuCmdName, __sc_menu, menuAdmFlag, cmdDescription);
	}
	
	if ((/*__hasAddCmd = */view_as<bool>(strlen(addSpawnCmdName)))) {
		FormatEx(cmdDescription, sizeof cmdDescription, "Save current position as a spawn point for plugin %s", pluginName);	
		RegAdminCmd(addSpawnCmdName, __sc_addSpawn, addSpawnAdmFlag, cmdDescription);
	}
	
	if ((/*__hasDelCmd = */view_as<bool>(strlen(delSpawnCmdName)))) {
		FormatEx(cmdDescription, sizeof cmdDescription, "Remove nearest saved spawn point for plugin %s", pluginName);
		RegAdminCmd(delSpawnCmdName, __sc_delSpawn, delSpawnAdmFlag, cmdDescription);
	}
	
	if ((/*__hasShowCmd = */view_as<bool>(strlen(showSpawnsCmdName)))) {
		FormatEx(cmdDescription, sizeof cmdDescription, "Show/hide saved spawns for plugin %s", pluginName);
		RegAdminCmd(showSpawnsCmdName, __sc_showSpawns, showSpawnsAdmFlag, cmdDescription);	
	}
	
	__initialized = true;
	return SC_NoError;
}

stock void SC_SetSpawnSprite(int showSpawnsSprite = -1) {
	if (showSpawnsSprite == -1) {
		__showSpawnsSprite = PrecacheModel("materials/sprites/glow.vmt");
	} else {
		__showSpawnsSprite = showSpawnsSprite;
	}
}

/// Loads saved spawn points for this map.
stock SCError SC_LoadMapConfig() {
	if (!__initialized)
		return SC_NotInitialized;
	
	for (int i = 1; i <= MaxClients; ++i)
		__showingSpawns[i] = false;
			
	__showSpawnsTimer = CreateTimer(1.0, __sc_spawnsTimer, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	__canShowSpawns = (__showSpawnsTimer != INVALID_HANDLE);
	
	if (!__canShowSpawns) {
		LogMessage("Can't show spawns (couldn't create timer)");
	}
	
	char mapName[64];
	GetCurrentMap_Custom(mapName, sizeof mapName);
	FormatEx(__configFile, sizeof __configFile, "%s/%s.spawns", __configDir, mapName);
	
	ClearArray(__spawns);
	ClearArray(__rotations);
	
	if (!FileExists(__configFile)) {
		LogMessage("No spawns file (%s).", __configFile);
		return SC_NoError;
	}
	
	FormatEx(mapName, sizeof mapName, "SC_%s", __pluginName); // multi-use strings FTW!
	
	KeyValues KV = CreateKeyValues(mapName);
	if (FileToKeyValues(KV, __configFile) && KvGotoFirstSubKey(KV)) {
		float vec[3];
		do { // load spawns
			KvGetVector(KV, "origin", vec);
			PushArrayArray(__spawns, vec);
			KvGetVector(KV, "rotation", vec);
			PushArrayArray(__rotations, vec);
		} while (KvGotoNextKey(KV));
	}
	delete KV;
	
	if (__maxSpawns != -1 && GetArraySize(__spawns) > __maxSpawns) {
		LogMessage("File '%s' has more spawns (%d) than configured max spawns (%d), truncating.", __configFile, GetArraySize(__spawns), __maxSpawns);
		ResizeArray(__spawns, __maxSpawns);
	}
	
	LogMessage("Loaded %d spawns.", GetArraySize(__spawns));
	return SC_NoError;
}

void GetCurrentMap_Custom(char[] szMap, int iSize)
{
	GetCurrentMap(szMap, iSize);
	
	int iLen, iPos;
	while((iPos = StrContains(szMap[iLen], "/")) != -1)
	{
		iPos += 1;
		iLen += iPos;
	}
	
	strcopy(szMap, iSize, szMap[iLen]);
}

/// Saves spawn points.
stock SCError SC_SaveMapConfig() {
	if (!__initialized)
		return SC_NotInitialized;
		
	LogMessage("Saving %d spawns.", GetArraySize(__spawns));
	LogMessage("Saving To %s", __configFile);
	
	char kvName[103], keyName[10]; // sizeof(__pluginName) + strlen("SC_")
	FormatEx(kvName, sizeof kvName, "SC_%s", __pluginName);
	
	KeyValues KV = CreateKeyValues(kvName); 
	float spawn[3];
	for (int i = 0; i < GetArraySize(__spawns); ++i) {
		IntToString(i, keyName, sizeof keyName);
		KvJumpToKey(KV, keyName, true);
		
		GetArrayArray(__spawns, i, spawn);
		KvSetVector(KV, "origin", spawn);
		GetArrayArray(__rotations, i, spawn);
		KvSetVector(KV, "rotation", spawn);
		KvRewind(KV);
	}
	
	DeleteFile(__configFile);
	
	if (GetArraySize(__spawns))
		KeyValuesToFile(KV, __configFile);
	delete KV;
		
	return SC_NoError;
}

stock ArrayList SC_GetSpawnsArray() {
	if (!__initialized)
		ThrowError("Spawnpoint Creator not initialized");
		
	return __spawns;
}

stock ArrayList SC_GetRotationsArray() {
	if (!__initialized)
		ThrowError("Spawnpoint Creator not initialized");
		
	return __rotations;
}

int __lastspawn = -1;
stock SCError SC_GetRandomSpawn(float spawn[3], float rotation[3], bool bNotLastSpawn = true) {
	if (!__initialized)
		ThrowError("Spawnpoint Creator not initialized");
	
	int iSize = GetArraySize(__spawns);
	if (!iSize)
		return SC_NoSpawns;
		
	int i;
	
	if(bNotLastSpawn && iSize > 1)
	{
		do
		{
			i = GetURandomInt()%GetArraySize(__spawns);
		}
		while (i == __lastspawn);
	}
	
	else
	{
		i = GetURandomInt()%GetArraySize(__spawns);
	}
	
	GetArrayArray(__spawns, i, spawn);
	GetArrayArray(__rotations, i, rotation);
	return SC_NoError;
}

stock SCError SC_AddSpawnPoint(float spawn[3], float rotation[3]) {
	if (!__initialized)
		ThrowError("Spawnpoint Creator not initialized");
	
	if (GetArraySize(__spawns) == __maxSpawns)
		return SC_MaxSavedSpawns;
		
	PushArrayArray(__spawns, spawn);
	PushArrayArray(__rotations, rotation);
	return SC_NoError;
}

stock SCError SC_ShowSpawnsToClient(int client, bool show=true) {
	if (!__canShowSpawns)
		return SC_CantShowSpawns;
		
	__showingSpawns[client] = show;
	return SC_NoError;
}

public void __sc_playerConnect(Event event, const char[] name, bool dontBroadcast) {
	__showingSpawns[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
}

public Action __sc_menu(int client, int args) {
	Menu menu = CreateMenu(__sc_menuHandler);
	char menuTitle[150];
	int arraySize = GetArraySize(__spawns);
	
	FormatEx(menuTitle, sizeof menuTitle, "%s - Edit spawn points (%d)", __pluginName, arraySize);
	SetMenuTitle(menu, menuTitle);
	
	{
	//if (__hasShowCmd)
		AddMenuItem(menu, "0", __showingSpawns[client] ? "Hide spawn points" : "Show spawn points");
	//if (__hasAddCmd)
		AddMenuItem(menu, "1", "Create spawn point here", arraySize != __maxSpawns ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	//if (__hasDelCmd)
		AddMenuItem(menu, "2", "Delete nearest spawn point", GetArraySize(__spawns) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(menu, "3", "Delete all spawn points", GetArraySize(__spawns) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int __sc_menuHandler(Menu menu, MenuAction action, int client, int selection) {
	if (action == MenuAction_Select) {
		char data[2];
		int choice;
		GetMenuItem(menu, selection, data, sizeof data);
		choice = StringToInt(data);
		switch (choice) {
		case 0:
			__sc_showSpawns(client, 0);
		case 1:
			__sc_addSpawn(client, 0);
		case 2:
			__sc_delSpawn(client, 0);
		case 3:
			__sc_delAllSpawns(client);
		}
		__sc_menu(client, 0);
	}
}

public Action __sc_addSpawn(int client, int args) {
	if (GetArraySize(__spawns) == __maxSpawns) {
		ReplyToCommand(client, "(%s) - Can't add spawn. Maximum number of saved spawn points (%d).", __pluginName, __maxSpawns);
		return Plugin_Handled;
	}
	
	float clientPos[3];
	
	GetClientAbsOrigin(client, clientPos);
	PushArrayArray(__spawns, clientPos);
	GetClientAbsAngles(client, clientPos);
	PushArrayArray(__rotations, clientPos);
	
	ReplyToCommand(client, "(%s) - Spawn point saved (%d total saved spawns).", __pluginName, GetArraySize(__spawns));
	
	return Plugin_Handled;
}

public Action __sc_delSpawn(int client, int args) {
	if (!GetArraySize(__spawns)) {
		ReplyToCommand(client, "(%s) - There aren't any saved spawn points.", __pluginName);
		return Plugin_Handled;
	}
	
	float clientPos[3], spawnPos[3], smallestDistance, candidate;
	int nearestSpawn;
	GetClientAbsOrigin(client, clientPos);
	smallestDistance = 999999999999.9;
	
	for (int i = 0; i < GetArraySize(__spawns); ++i) {
		GetArrayArray(__spawns, i, spawnPos);
		candidate = GetVectorDistance(clientPos, spawnPos);
		if (candidate < smallestDistance) {
			smallestDistance = candidate;
			nearestSpawn = i;
		}
	}
	
	if (smallestDistance > 64.0) {
		ReplyToCommand(client, "(%s) - Couldn't locate a spawn point near you (nearest spawn is %.2f units away)", __pluginName, smallestDistance);
	} else {
		RemoveFromArray(__spawns, nearestSpawn);
		RemoveFromArray(__rotations, nearestSpawn);
		ReplyToCommand(client, "(%s) - Spawn point removed successfully.", __pluginName);
	}
	
	/*if (!GetArraySize(__spawns)) {
		for (new i = 1; i <= MaxClients; ++i)
			__showingSpawns[i] = false;
	}*/
	
	return Plugin_Handled;
}

public Action __sc_showSpawns(int client, int args) {
	if (!__canShowSpawns) {
		ReplyToCommand(client, "(%s) - The spawn points showing feature is disabled for this plugin (couldn't create Timer)", __pluginName);
		return Plugin_Handled;
	}

	bool enable;
	if (args == 1) {
		char arg[2];
		GetCmdArg(1, arg, sizeof arg);
		enable = view_as<bool>(StringToInt(arg));
	} else {
		enable = !__showingSpawns[client];
	}
	
	if (enable != __showingSpawns[client]) {
		__showingSpawns[client] = enable;
		ReplyToCommand(client, "(%s) - %s %d spawn points.", __pluginName, enable ? "Showing" : "Hiding", GetArraySize(__spawns));
	} else {
		ReplyToCommand(client, "(%s) - Already %s spawn points.", __pluginName, enable ? "showing" : "hiding");
	}
	
	return Plugin_Handled;
}

public Action __sc_spawnsTimer(Handle timer) {
	if (!GetArraySize(__spawns))
		return Plugin_Continue;
	
	float spawnPos[3];

	for (int i = 1; i < MaxClients; ++i) {
		if (!__showingSpawns[i] || !IsClientInGame(i)) continue;
		
		for (int j = 0; j < GetArraySize(__spawns); ++j) {
			GetArrayArray(__spawns, j, spawnPos);
			spawnPos[2] += 16.0;
			TE_SetupGlowSprite(spawnPos, __showSpawnsSprite, 1.0, 0.4, 217);
			TE_SendToClient(i);
		}
	}
	
	return Plugin_Continue;
}

stock void __sc_delAllSpawns(int client) {
	ClearArray(__spawns);
	ClearArray(__rotations);
	//for (new i = 1; i <= MaxClients; ++i)
			//__showingSpawns[i] = false;
	ReplyToCommand(client, "(%s) - Deleted all spawn points", __pluginName);
}

stock SCError SC_GetNextSpawnPoint(float spawn[3], float rotation[3]) {
    if (!__initialized)
        ThrowError("Spawnpoint Creator not initialized");
    
    int __array = GetArraySize(__spawns);
        
    if (!__array)
        return SC_NoSpawns;
    
    if (__nextSpawnpoint >= __array)
    {
        __nextSpawnpoint = 0;
    }
    GetArrayArray(__spawns, __nextSpawnpoint, spawn);
    GetArrayArray(__rotations, __nextSpawnpoint, rotation);
    __nextSpawnpoint++;
    return SC_NoError;
}  
