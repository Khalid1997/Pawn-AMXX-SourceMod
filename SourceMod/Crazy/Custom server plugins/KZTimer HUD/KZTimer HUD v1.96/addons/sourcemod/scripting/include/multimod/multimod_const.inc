#if defined _multimod_const_included_
#endinput
#endif
#define _multimod_const_included_

// -----------------------------------------------------------------------------
// DO NOT EDIT THESE UNLESS YOU RECOMPILE ALL PLUGINS THAT ARE USING MULTIMOD
#define MM_PLUGIN_AUTHOR	"Khalid"

#define MM_VERSION_STR		"1.9.0a"
#define MM_VERSION_NUM		190

#define MM_LOG_FILE			"addons/sourcemod/logs/multimod.log"

// THIS SHOULD NOT BE EDITED UNLESS YOU KNOW WHAT YOU ARE DOING
// if you edit these, you need to recompile every plugin that uses the API of multimod plugin.
#define MM_FOLDER_MAIN		"multimod"
#define MM_FOLDER_MODS		"mods"

#define DEFAULT_PLUGINS_KEY	"[DEFAULT PLUGINS]"				// DO NOT EDIT
#define MODS_KEY 			"[MODS]"						// DO NOT EDIT

#define MM_LIB_BASE			"multimod_base"
#define MM_LIB_SETTINGS		"multimod_settings"
#define MM_LIB_LOGGING		"multimod_logging"
#define MM_LIB_VOTE			"multimod_vote"

#define MM_MAPS_FILE_KEY	"-maps"
#define MM_MAPS_FILE_EXT	".ini"

#define MM_PLUGIN_FILE_KEY	"-plugins"
#define MM_PLUGIN_DISABLE_FILE_KEY "-disabled"
#define MM_PLUGIN_FILE_EXT	".ini"

// No ext here cause it is known already
#define MM_CFG_FILE_KEY		""

// Name, File names, map file name, config file name.
#define MM_MAX_MOD_PROP_LENGTH	30
#define MM_MAX_MAP_NAME			50

#define MM_MAX_FILE_LINE_LENGTH 256
#define MM_MAX_PLUGIN_FILE_NAME 50

// Chat Prefix Max length
#define MM_MAX_PREFIX_LENGTH	25

// Settings Plugin
#define MM_SETTING_NAME_LENGTH 256
#define MM_SETTING_VALUE_LENGTH 256

// -----------------------------------------------------------------------------

#define MM_ACCESS_FLAG_ROOT_BIT		ADMFLAG_ROOT
#define MM_ACCESS_FLAG_NEXTMOD_BIT	ADMFLAG_BAN
#define MM_MENU_ACCESS_FLAG_BIT 	MM_ACCESS_FLAG_NEXTMOD_BIT

// Keys for settings
#define MM_SETTING_RANDOM_FIRST_MOD				"RandomFirstMod"
#define MM_SETTING_CHAT_PREFIX					"ChatPrefix"
#define MM_SETTING_DEBUG						"Debug"
#define MM_SETTING_RAMDOM_FIRST_MAP				"RandomFirstMap"
#define MM_SETTING_BLOCK_CURRENT_MOD			"BlockCurrentMod"
#define MM_SETTING_DEFAULT_FORCE_CHANGE			"ForceChangeAfterVote"
#define MM_SETTING_VOTETIME_MOD					"VoteTimeMod"
#define MM_SETTING_VOTETIME_MAP					"VoteTimeMap"
#define MM_SETTING_MAX_MAPS_IN_VOTE				"VoteMaxMaps"
#define MM_SETTING_MAX_MODS_IN_VOTE				"VoteMaxMods"
#define MM_SETTING_RANDOMIZE_MODS_IN_VOTE		"VoteRandomOrder"
#define MM_SETTING_VOTE_HIDE_DISABLED_ITEMS		"VoteHideDisabledItems"

