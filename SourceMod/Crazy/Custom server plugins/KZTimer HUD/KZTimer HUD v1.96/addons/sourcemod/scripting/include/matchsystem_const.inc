#if defined matchsystem_constants_included
	#endinput
#endif

#define matchsystem_constants_included

#define MAX_AUTHID_LENGTH 35

#define INDEFINITE_BAN -1
#define TEAM_ID_NONE -1

stock int MATCHID_NO_MATCH = 0;

char TEAM_NAME_CT[] = "Counter-Terrorists";
char TEAM_NAME_T[] = "Terrorists";

#define MAX_QUERY_LENGTH	625
#define MAX_ERROR_LENGTH	512

char PLUGIN_CHAT_PREFIX[] = "\x04[CEL]";
char PLUGIN_LOG_FILE[] = "addons/sourcemod/logs/matchsystem.txt";