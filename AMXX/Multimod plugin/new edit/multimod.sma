#include <amxmodx>
#include <amxmisc>

// --------------------------
//  ** Stuff to edit here **

#define PRINT_LOGS
// --------------------------

#define PLUGIN_NAME	"MultiMod Manager"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"2.2"

#define AMX_MULTIMOD	"amx_multimod"
#define AMX_PLUGINS	"amxx_plugins"
#define AMX_MAPCYCLE	"mapcyclefile"
#define AMX_LASTCYCLE	"lastmapcycle"

#define AMX_DEFAULTCYCLE	"mapcycle.txt"
#define AMX_DEFAULTPLUGINS	"addons/amxmodx/configs/plugins.ini"
#define	AMX_BASECONFDIR		"multimod"

#define NULL_MOD_ID	-1

new g_iModCount = -1;			// integer with configured mods count
new g_iNextModId = -1;
new g_iCurrentModId;

new g_hMMInitForward;

new bool:g_bVotePluginRunning;

new const MM_SETTINGS_FILE[] = "multimod/multimod_settings.ini";
new const MM_MODS_FILE[] = "multimod/multimod.ini";

/*
# MultiMod File
# Plugin By Khalid
[Settings]
# First mod to be run on first run
# Use mod_identifier for a specific mod, or RANDOM for a random mod.
MM_FIRST_MOD = RANDOM

# Change map to a random map from the file list of the first mod
# or keep the map that the server started with.
# Valid values:
# ENABLED, DISABLED
MM_FIRST_MOD_CHANGE_MAP = ENABLED

# Time before end of map to start the mod
# Value in seconds
# Valid Values:
# Seconds such as: 60.0, 180.0, 300.05
MM_ENDVOTE_START_TIME = 180.0
# 3 Minutes.

# Mod Vote Length
# Value in seconds
MM_VOTE_LENGTH = 30.0

# Enable /mm_menu
# Valid Values:
# ENABLED, DISABLED
MM_MENU = ENABLED

# Enable showing voting percentage in the mod vote
# Valid Values:
# ENABLED, DISABLED
MM_VOTE_SHOW_PERCENTAGE = ENABLED
MM_VOTE_SHOW_PERCENTAGE_AFTER_CHOOSING = DISABLED

# Advertise Hud Loop time
# Valid Values:
# Floating numbers in seconds such as: 60.0, 120.5, 180.0
MM_ADVERTISE_LOOP_TIME = 60.0

# RTV
# Time before actually allowing people to rtmv after the start of the map
# Valid Values:
# Numbers in seconds such as: 60.0, 120.5, 180.0
# NOTE: Putting a value of 0.0 will disable this feature.
MM_RTV_DELAY = 300.0

# Percentage of players required to start the vote.
# Valid Values:
# Numbers between 0.1 and 1;
MM_RTV_PERCENTAGE = 0.75

[Mod List]
# Format:
# "Mod Name":"mod_identifier"
# Notes:
# Mod identifier is the prefix that you will be using for the files. 
# It cannot have spaces.
# Example
# "Soccer Mod":"soccer"
*/

public plugin_natives()
{	
	// MM_GetCurrentModId();
	// MM_SetNextMod(iModIndex);
	register_native("MM_GetCurrentModId", "Native_GetCurrentMod");
	register_native("MM_SetNextModId", "Native_MM_SetNextMod");
	
	// MM_GetModInfo(iModIndex, szModName[], iModNameMaxLength, szModIdentifier[], szModIdentifierMaxLength);
	register_native("MM_GetModInfo", "Native_MM_GetNextMod");
	
	// MM_GetSetting(szSetting[], szValue[], iValueMaxSize);
	register_native("MM_GetSetting", "Native_MM_GetSetting");
	
	// Forward that declares that the MM plugin is ready.
	// forward MM_Init();
}

public plugin_init()
{
	register_plugin("MultiMod E: Main", "1.0", "Khalid");
	
	// Read the config
	ReadConfig();
	ApplySettings();
	
	// Check for first run.
	if(IsFirstRunRestart())
	{
		return;
	}
	
	if(LibraryExists("multimod_vote_plugin", LibType_Library))
	{
		g_bVotePluginRunning = true;
	}
	
	Execute_ModConfig(MODConfig_Pre);
	new iRet;
	ExecuteForward(g_hMMInitForward, iRet);
	
	register_event("30", "Event_ChangeMod", "a")
}

public plugin_cfg()
{
	Execute_ModConfig(MODConfig_Post);
}

public Event_ChangeMod()
{
	if(g_bVotePluginRunning)
	{
		GetNextMapName(szMap, charsmax(szMap));
		set_task(flChatTime, "delayedChange", 0, szMap, charsmax(szMap))	// change with 1.5 sec. delay
		return;
	}
	
	if(g_iNextModId == g_iCurrentModId || g_iNextModId == NULL_MOD_ID)
	{
		if(g_bSetting_RandomizeMap)
		{
			GetRandomMapFromModId(g_iCurrentModId, szMap, charsmax(szMap));
		}
		
		new Float:flChatTime = g_pChatTime ? get_pcvar_float(g_pChatTime) : 10.0;	// mp_chattime defaults to 10 in other mods
	
		if (g_pChatTime)
		{
			set_pcvar_float(g_pChatTime, flChatTime + 2.0)		// make sure mp_chattime is long
		}
		
		set_task(flChatTime, "DelayedChange", 0, szMap, charsmax(szMap))	// change with 1.5 sec. delay
	}
}

ReadConfig()
{
	
}

public DelayedChange(szData[], iTaskId)
{
	server_cmd("changelevel %s", szData);
	server_exec();
}

stock IsFirstRunRestart()
{
	new szLastModIdentifier[IDENTIFIER_MAX_LENGTH];
	if(GetLastModIdentifier(szLastModIdentifier))
	{
		if(!equal(szLastModIdentifier, g_szCurrentModIdentifier))
		{
			log_amx("[MultiMod] First Run. Restarting");
			SetNextMod(GetModIdFromIdentifier(g_iSetting_FirstMod));
			
			if(g_iSetting_FirstMap == FM_RANDOM_MAP)
			{
				new szMap[MAX_MAP_LENGTH];
				if(!GetRandomMapFromModId(g_iSetting_FirstMod, szMap, charsmax(szMap)))
				{
					server_cmd("restart");
				}
				
				else
				{
					server_cmd("changelevel %s", szMap);
				}
			}
			
			else if(g_iSetting_FirstMap == FM_KEEP_MAP)
			{
				server_cmd("restart");
			}
			
			return true;
		}
	}
	
	return false;
}

GetRandomMapFromModId(iModId, szMap[], iLen)
{
	new szMapFile[MAX_PAT_LENGTH];
	GetModMapFilePath(GetModIdFromIdentifier(g_iSetting_FirstMod), szMapFile, charsmax(szMapFile));
				
	new f = fopen(szMapFile, "r");
	
	new bool:bGot = false;
	new iTry;
	
	while(!bGot)
	{
		fseek(f, SEEK_SET, 0);
		
		new szLine[MAX_MAP_LENGTH];
		while(!feof(f))
		{
			fgets(f, szLine, charsmax(szLine));
			trim(szLine);
							
			if(!IsValidLine(szLine))
			{
				continue;
			}
							
			if(IsValidMap(szLine))
			{
				if(random_num(0, 1))
				{
					bGot = true;
				}
			}
		}
		
		if(++iTry >= MAX_TRIES)
		{
			break;
		}
	}
	
	return bGot;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
