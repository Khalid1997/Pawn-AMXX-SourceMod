#if defined _multimod_const_included_
  #endinput
#endif
#define _multimod_const_included_

// -----------------------------------------------------------------------------
// DO NOT EDIT THESE UNLESS YOU RECOMPILE ALL PLUGINS THAT ARE USING MULTIMOD
#define MM_VERSION_STR		"1.6.01a"
#define MM_VERSION_NUM		1601

// THIS SHOULD NOT BE EDITED AT ALL COSTS UNLESS YOU KNOW WHAT YOU ARE DOING

#define MM_FOLDER_MAIN		"multimod"
#define DEFAULT_PLUGINS_KEY	"[DEFAULT PLUGINS]"				// DO NOT EDIT
#define MODS_KEY 			"[MODS]"						// DO NOT EDIT

#define MM_LIB_BASE			"multimod"
#define MM_LIB_VOTE			"multimod_vote"

#define MM_MAPS_FILE_KEY	"-maps"
#define MM_PLUGIN_FILE_KEY "-plugins"
#define MM_PLUGIN_FILE_EXT "ini"
#define MM_MAPS_FILE_EXT	"ini"

#define MM_CFG_FILE_EXT		"cfg"
// -----------------------------------------------------------------------------

// Chat Prefix
#define	CHAT_PREFIX				"\x04[MultiMod]"

// Voting plugin.
// This defines whether to immidiately change the map after the vote is done (true),
// or to wait for the time limit\map end to arrive (false).
#define MM_DEFAULT_FORCE_CHANGE	true

// Access flag for most functions (or all?).
#define MM_ACCESS_FLAG_BIT 		ADMFLAG_ROOT

// Max MOD name length
#define MAX_MOD_NAME 			35

// MAX MODS that the multimod plugin can register\save
#define MAX_MODS 				8

// Voting plugin's voting time.
#define VOTING_TIME 			17

// How many maps in maps' vote
#define MAX_VOTE_MAPS 			5

// Voting plugin Block the current MOD in vote
#define BLOCK_CURRENT_MOD_IN_VOTE


