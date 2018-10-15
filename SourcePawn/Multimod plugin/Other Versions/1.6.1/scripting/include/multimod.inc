#if defined _multimod_included_
  #endinput
#endif
#define _multimod_included_

#include <multimod_const>
#include <multimod_vote>
#include <multimod_stocks>

/**
 * Returns the count of the currently registered MODs in the multimod arrays.
 * 
 * @return				MODs count
 */
native MultiMod_GetModsCount();

/**
 * Returns the current MOD index.
 * 
 * @return				current MOD Index
 */
native MultiMod_GetCurrentModId();

enum MultiModLock
{
	MultiModLock_NotLocked = 0,		/* Is not locked */
	MultiModLock_Locked,			/* Locked by an external plugin */
	MultiModLock_Locked_Save,		/* Locked by an external plugin, will stay locked even after map change */
		
	MultiModLock_All				/* For use in GetBlockedModCount */
} 

/**
 * Return the MOD's lock status.
 *
 * @param iModId		the MOD's index.
 * @error 				MOD index out of bounds.
 */
native MultiModLock:MultiMod_GetModLock(iModId);

/**
 * Sets the MOD's lock status.
 *
 * @param iModId		the MOD's index.
 * @param iLock			locking type (look at MultiModLock enum).
 * @return				true on success, false on failure.
 * @error 				MOD index out of bounds.
 */
native bool:MultiMod_SetModLock(iModId, MultiModLock:iLock);

/**
 * Get the amount of MODs that are locked.
 *
 * @param iLock			locking type (look at MultiModLock enum).
 * @return				number of locked mods.
 */
native MultiMod_GetLockedModsCount(MultiModLock:iLock = MultiModLock_All);

/**
 * Returns the chosen next MOD index.
 *
 * @return				MOD's index number on success, -1 on failure (no next MOD choosen)
 */
native MultiMod_GetNextModId();

/**
 * Value for the cancellation of next MOD.
 */
#define MM_NEXTMOD_CANCEL		-1

/**
 * Sets the next MOD
 *
 * @param iModId		The MOD's index. Pass MM_NEXTMOD_CANCEL to cancel the currently chosen next MOD
 * @return				true on success, false on failure.
 * @error 				MOD index out of bounds.
 */
native bool:MultiMod_SetNextMod(iModId);

/**
 * Called whenever the next chosen MOD is changed (even from the native above, from a command, literally anything).
 *
 * @param iNewNextModId		new next MOD index.
 * @param iOldNextModId		old next MOD index.
 * @noreturn
 */
forward MultiMod_NextModChanged(iNewNextModId, iOldNextModId);

enum MultiModProp
{
	MultiModProp_Name,			/* Name of the MOD */
	MultiModProp_Plugin,		/* MOD's plugin folder */
	MultiModProp_Map,			/* MOD's map file */
	MultiModProp_Cfg			/* MOD's CFG file */
};

native Handle:MultiMod_GetNameArray();
native Handle:MultiMod_GetPluginFolderArray();
native Handle:MultiMod_GetMapFileArray();
native Handle:MultiMod_GetConfigFileArray();

/**
 * Called whenever the next chosen MOD is changed.
 *
 * @param iModId 		MOD's index
 * @param iProp			property to store in szInfo (look at MultiModProp enum)
 * @param szInfo		string to store the property.
 * @param iSize			string size.
 * @param bFileExt		if true, the file extension will be included for maps file and CFG file
 * @return				true on success, false on failure.
 */
native bool:MultiMod_GetModProp(iModId, MultiModProp:iProp, String:szInfo[], iSize, bool:bFileExt = false);

enum MultiModLoad
{
	//MultiModLoad_None,			// Called whenever the plugin has alread been loaded, and the map changed. So basicly, no change.
	MultiModLoad_Loaded,  			// Called After the first map change, when the plugin is fully loaded
	MultiModLoad_Reload,			// called whenever the command sm_mm_reload is executed.
	//MultiModLoad_ModChange		// Called before map change, when the mod has been changed.
};

/**
 * Called once the base multimod plugin has loaded the MOD's and their plugins
   on first run from OnMapStart. Also called whenever the reload command was used.
 *
 * @param iLoad		load type (check MultiModLoad enum for more details)
 * @noreturn
 */
forward MultiMod_Loaded(MultiModLoad:iLoad);

/**
 * Insert description here if needed
 *
 * @return				true if loaded, false otherwise.
 */
native bool:MultiMod_IsLoaded();