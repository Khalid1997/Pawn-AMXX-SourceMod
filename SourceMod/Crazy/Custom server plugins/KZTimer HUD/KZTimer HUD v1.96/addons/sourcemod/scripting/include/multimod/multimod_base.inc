#if defined _multimod_base_included
 #endinput
#endif
#define _multimod_base_included

#include <multimod>

/**
 * Value for invalid MOD index.
 *
 */
#define ModIndex_Null -1

/**
 * Returns the count of the currently registered MODs in the multimod arrays.
 * 
 * @return				MODs count
 */
native int MultiMod_GetModsCount();

/**
 * Returns the current MOD index.
 * 
 * @return				current MOD Index
 */
native int MultiMod_GetCurrentModId();

enum MultiModLock
{
	MultiModLock_NotLocked = 0, /* Is not locked */
	MultiModLock_Locked, /* Locked by an external plugin */
	MultiModLock_Locked_Save, /* Locked by an external plugin, will stay locked even after map change */
	
	MultiModLock_All/* To be used in GetBlockedModCount */
}

native bool MultiMod_CanLockMod();

/**
 * Return the MOD's lock status.
 *
 * @param iModId		the MOD's index.
 * @error 				MOD index out of bounds.
 */
native MultiModLock MultiMod_GetModLock(int iModId);

/**
 * Sets the MOD's lock status.
 *
 * @param iModId		the MOD's index.
 * @param iLock			locking type (look at MultiModLock enum).
 * @return				true on success, false on failure.
 * @error 				MOD index out of bounds.
 */
native bool MultiMod_SetModLock(int iModId, MultiModLock iLock);

/**
 * Get the amount of MODs that are locked.
 *
 * @param iLock			locking type (look at MultiModLock enum).
 * @return				number of locked mods.
 */
native int MultiMod_GetLockedModsCount(MultiModLock iLock = MultiModLock_All);

/**
 * Returns the chosen next MOD index.
 *
 * @return				MOD's index number on success, -1 on failure (no next MOD choosen)
 */
native int MultiMod_GetNextModId();

/**
 * Sets the next MOD
 *
 * @param iModId		The MOD's index. Pass ModIndex_Null to cancel the currently chosen next MOD
 * @return				true on success, false on failure.
 * @error 				MOD index out of bounds.
 */
native bool MultiMod_SetNextMod(int iModId);

/**
 * Called whenever the next chosen MOD is changed (even from the native above, from a command, literally anything).
 *
 * @param iNewNextModId		new next MOD index.
 * @param iOldNextModId		old next MOD index.
 * @noreturn
 */


// MultiMod_GetModProp Stuff

enum
{
	MultiModProp_Name = 0, 			// Name of the MODs	
	MultiModProp_InfoKey, 		// MOD's plugin file
	
	Mod_Props_Total
};

/**
 * Can be used to get the properties of the mod. Properties consist of:
 * Mod Name, Plugin file, Map File, and Config File
 *
 * @param iModId 			MOD's index
 * @param iProp				property to store in szInfo (look at MultiModProp_* enum)
 * @param szPropReturn		string to store the property.
 * @param iSize				string size.
 * @return					true on success, false on failure.
 * @error					Invalid Prop, Invalid ModId
 */
native void MultiMod_GetModProp(int iModId, int iModProp, char[] szPropReturn, int iSize);

enum MultiModFile
{
	MultiModFile_Plugins,
	MultiModFile_PluginsDisabled,
	MultiModFile_Maps,
	MultiModFile_Config
};

enum MultiModPath
{
	MultiModPath_Base,
	MultiModPath_Mods,
	MultiModPath_ModFolder
};

native void MultiMod_BuildPath(MultiModPath iPath = MultiModPath_Base, int iModIndex = ModIndex_Null, char[] szPath, int iSize, char[] szFormat = "", any ...);
native void MultiMod_GetBaseFile(char[] szFile, int iSize, bool bIncludePath = true);

// Return true if exists, false if not
// Return Path file
native void MultiMod_GetModFile(int iModId, MultiModFile iFileType, char[] szFile, int iSize);
native void MultiMod_GetModFileEx(int iModId, MultiModFile iFileType, char[] szFile, int iSize,
									bool bPath = true,		// Include File path
									bool bFileKey = true, // Include File Key: Example for plugins file it will be modpluginsidentifier-plugins (-plugins is the Key)
									bool bFileExt = true);  // Include file extention
// MultiMod_GetFilePathEx(iModId, iFileType, szFile, iSize, false, false, false) will give MultiModProp_InfoKey's results

/**
 * Called once the base multimod plugin has loaded the first MOD successfully(or reloaded, with mods available).
 * Therefore, this won't be called unless there is at least one MOD in the base multimod file.
 * 
 * @param bReload		Is it a reload?
 * @noreturn
 */
forward void MultiMod_OnLoaded(bool bReload);

/**
 * Insert description here if needed
 *
 * @return				true if loaded, false otherwise.
 */
native bool MultiMod_IsLoaded();

enum HandleType
{
	HandleType_Trie,
	HandleType_DataPack,
	HandleType_ArrayList
}

enum ModList
{
	ModList_Plugins,
	ModList_PluginsDisabled,
	ModList_Maps
}

enum MMReturn
{
	MMReturn_Continue = 0,
	MMReturn_Stop
}	

typedef MultiModListCallback = function MMReturn (int iModId, ModList iListType, char[] szString, any data);

// sizeof(iList) == iSize
/**
 * @note		Handles must be pre-made! The native will not create the Handles for you
 * @note 		All sizes of the arrays must match
 * @note		The order of the Maps_Name and Maps_Alias is gauranteed to be the same as long as they are retrieved together at the same time
 * @note		Requirements:
 *				sizeof(iListType) == iSize == sizeof(hHandles) == sizeof(iHandleType)
 * @noreturn
 */
// Use First style
native void MultiMod_PassModListFromMod(int iModId, ModList iListType, HandleType iHandleType, any hHandle, int &iOptionalCount = 0, MultiModListCallback Callback = INVALID_FUNCTION, any Data = INVALID_HANDLE);
native void MultiMod_PassDifferentModListFromMod(int iModId, int iSize, ModList[] iListType, int[] iHandleType, HandleType[] hHandles, int[] iOptionalCount = 0, MultiModListCallback Callback = INVALID_FUNCTION, any Data = INVALID_HANDLE);
native void MultiMod_PassDifferentModListFromDifferentMods(int[] iModId, int iSize, ModList[] iListType, HandleType[] iHandleType, any[] hHandles, int[] iOptionalCount = 0, MultiModListCallback Callback = INVALID_FUNCTION, any Data = INVALID_HANDLE);

// Is valid file line according to the multimod plugins, kinda useless, will still keep it.
native void MultiMod_IsValidFileLine(char[] szLine);


public SharedPlugin __pl_multimod_base =
{
	name = MM_LIB_BASE,
	file = "multimod.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __multimod_base_SetNTVOptional()
{
	MarkNativeAsOptional("MultiMod_GetModsCount");
	MarkNativeAsOptional("MultiMod_GetCurrentModId");
	
	MarkNativeAsOptional("MultiMod_CanLockMod");
	MarkNativeAsOptional("MultiMod_GetModLock");
	MarkNativeAsOptional("MultiMod_SetModLock");
	MarkNativeAsOptional("MultiMod_GetLockedModsCount");
	
	MarkNativeAsOptional("MultiMod_GetNextModId");
	MarkNativeAsOptional("MultiMod_SetNextMod");
	
	MarkNativeAsOptional("MultiMod_GetModProp");
	MarkNativeAsOptional("MultiMod_BuildPath");
	MarkNativeAsOptional("MultiMod_GetBaseFile");
	MarkNativeAsOptional("MultiMod_GetModFile");
	MarkNativeAsOptional("MultiMod_GetModFileEx");
	MarkNativeAsOptional("MultiMod_OnLoaded");
	MarkNativeAsOptional("MultiMod_PassModListFromMod");
	MarkNativeAsOptional("MultiMod_PassDifferentModListFromMod");
	MarkNativeAsOptional("MultiMod_PassDifferentModListFromDifferentMods");
	MarkNativeAsOptional("MultiMod_IsValidFileLine");
}
#endif