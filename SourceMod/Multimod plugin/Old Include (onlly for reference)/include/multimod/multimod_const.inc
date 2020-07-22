#if defined _multimod_const_included_
#endinput
#endif
#define _multimod_const_included_

#include <multimod>

// -----------------------------------------------------------------------------
// DO NOT EDIT THESE UNLESS YOU RECOMPILE ALL PLUGINS THAT ARE USING MULTIMOD
#define MM_DEBUG			false
#define MM_LOG_FILE			"addons/sourcemod/logs/multimod.log"

#define MM_VERSION_STR		"1.7.00"
#define MM_VERSION_NUM		1700

// THIS SHOULD NOT BE EDITED UNLESS YOU KNOW WHAT YOU ARE DOING
// if you edit these, you need to recompile every plugin that uses the API of multimod plugin.
#define MM_FOLDER_MAIN		"multimod"
#define DEFAULT_PLUGINS_KEY	"[DEFAULT PLUGINS]"				// DO NOT EDIT
#define MODS_KEY 			"[MODS]"						// DO NOT EDIT

#define MM_LIB_BASE			"multimod_base"
#define MM_LIB_VOTE			"multimod_vote"

#define MM_MAPS_FILE_KEY	"-maps"
#define MM_MAPS_FILE_EXT	"ini"

#define MM_PLUGIN_FILE_KEY	"-plugins"
#define MM_PLUGIN_DISABLE_FILE_KEY "-disabled"
#define MM_PLUGIN_FILE_EXT	"ini"

// No ext here cause it is known already
#define MM_CFG_FILE_KEY		""

// Name, File names, map file name, config file name.
#define MM_MAX_MOD_PROP_LENGTH	30
#define MM_MAX_MAP_NAME			50

#define MM_MAX_FILE_LINE_LENGTH 256
#define MM_MAX_PLUGIN_FILE_NAME 50

// -----------------------------------------------------------------------------
// Chat Prefix
#define	CHAT_PREFIX				"\x04[MultiMod]"

// Voting plugin.
// This defines whether to immidiately change the map after the vote is done (true),
// or to wait for the time limit\map end to arrive (false).
#define MM_DEFAULT_FORCE_CHANGE	false

// Access flag for most functions (or all?).
#define MM_ACCESS_FLAG_BIT 		ADMFLAG_ROOT

// Maximum Mods number
#define MAX_MODS 				8

// Voting plugin's voting time.
#define VOTING_TIME 			17

// How many maps in maps' vote
#define MAX_VOTE_MAPS 			5

// Voting plugin Block the current MOD in vote
//#define BLOCK_CURRENT_MOD_IN_VOTE

// If false, will use the first mod listed in the file
//#define RANDOMIZE_FIRST_MOD

// If false, will use the map that the plugin has started on
#define RANDOMIZE_FIRST_MAP

#define MAX_VOTE_MODS		8
#define RANDOMIZE_MODS_IN_VOTE

// DO NO USE, REMOVED
// Lock current mod from being chosen in mod vote, multimod menu, and main base plugin.
//#define LOCK_CURRENT_MOD



