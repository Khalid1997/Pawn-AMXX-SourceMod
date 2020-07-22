#if defined _matchsystem_const_included
 #endinput
#endif
#define _matchsystem_const_included

#define INDEFINITE_BAN -1
#define TEAM_ID_NONE -1

//#define MATCHID_MAX_LENGTH 21
//stock const String:MATCHID_NO_MATCH[] = "";
stock int MATCHID_NO_MATCH = 0;

stock String:TEAM_NAME_CT[] = "Counter-Terrorists";
stock String:TEAM_NAME_T[] = "Terrorists";

#define MAX_QUERY_LENGTH 625
#define MAX_ERROR_LENGTH 512

stock const String:PLUGIN_CHAT_PREFIX[] = "\x04[CEL]";
stock const String:PLUGIN_LOG_FILE[] = "addons/sourcemod/logs/matchsystem.txt";