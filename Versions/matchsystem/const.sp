//#define OLD_DAMAGE_REPORT

#define MAX_AUTHID_LENGTH 35

#define MAX_MATCH_PLAYERS	32
#define PrintDebug	PrintToServer

#define NUMBER_RESTARTS		3

#define DELAY_RESTART_KNIFE_ROUND 5
#define WARMUP_RESPAWN_TIME	3.0
const int MATCH_END_KICK_TIME = 15;

// Ready Not Ready
//#define RNR_PHASE_ENABLED

//#define ALLOW_OUTSIDE_CLIENTS
#define ALLOW_ADMINS
//#define ALLOW_SPECS
#define MAX_OUTSIDE_CLIENTS 1

#define MATCH_PLAYERS 3

#if defined ALLOW_OUTSIDE_CLIENTS
char KICK_MESSAGE_OUTSIDE_CLIENTS_EXCEEDED[] = "Maximum outside clients limit has been exceeded";
#endif
char KICK_MESSAGE_NOT_ALLOWED[] = "You are not allowed to join the server.";
char KICK_MESSAGE_MATCH_CANCELED[] = "The match was canceled.";
char KICK_MESSAGE_MATCH_ENDED[] = "The match has ended.";

char g_szConfigFolder[] = "matchsystem";
char g_szWarmUpConfig[] = "warmup.cfg";
char g_szMatchConfig[] = "match.cfg";
char g_szKnifeRoundConfig[] = "knife_round.cfg";

#define KNIFE_ROUND_ENABLED
#define KNIFE_ROUND_DISARM_C4

char MatchEndCode_None[] = "none",
	MatchEndCode_End[] = "win",			// 1 - Match Ended normally. Winner will be passed.
	MatchEndCode_Surrender[] = "surrender",				// 2 - Match Ended by a team surrenderring.	Winner will be passed.
	MatchEndCode_ConnectFailure[]	= "cancel_connect_failure",		// 3 - Players failed to connect within the given time. No winner. (Match Canceled)
	MatchEndCode_Cancelled_Crash[] = "cancel_crash",	// 4 - Server has crashed.
	MatchEndCode_Cancelled_Admin[] = "cancel_admin";	// 5 - The match was cancelled by a superior admin. Winner can be passed or not (depending on the admin).
	
#define LoopClients(%1)  for(%1 = 1; %1 <= MaxClients; %1++)