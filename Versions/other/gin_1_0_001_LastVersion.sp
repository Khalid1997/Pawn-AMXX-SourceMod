#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.0.001"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <matchsystem_stocks>
#include <matchsystem_const>
#include <cstrike>

/*
- V 1.0.001: (Do not ask why version number is like this, i just felt it should be that way. LOL)
	New:
		* CMDS:
			- sm_match_force_start
		* Implemented ban system
		* Complete Match End Reasons.
		* Stats Enable/Disable.
		* Overtime support. (Last thing to do)
		* Total Jumps to the stats
		
	To Do:
		* Clan Tag timer.
		* sm_match_restart_round.	-- will do as an external plugin.
		* Ban System
		* Bot Support - Done
		* Team  - Team Choose Menu, if round ended it crashs the server.
		* Team Menu - Choose another player.
		* Team Menu, Timer.
		* Hud (players remaining to ready)

- V 0.1.006:
	New:
		* Natives & Forwards - Done
		* Late Load - Done
		* Damage report added - Done
		* SQL Support - Done
		* Code Cleaned! - Done
		* Code improvement(s) - Done
		* Added a matchstate when the server is waiting to recieve a match. - Done
		* Support for outside clients (can be turned on and off) - Partially done (only admins done)
		* Kick all players on match end. - Done.
		* Added Test version Support - Done.
		* Stats	- Done
		* UPDATE STATS QUERY FIX (Local STATS ARE 0 WHEN UPDATED AT GAME END). - Done
		* Crash Detect	 - Done
		* CMDs: 
			- sm_match_end - Done
		* Custom Query stocks (functions)
		
	To Do: (Priority by order- First is high)
		* Ask murshid about data type for time. - Done
		* Transfer to sockets - Canclled
		
- V 0.1.005: 
	New:
		* First 'stable' version
		* Team score notification.
		* Custom PrintToChat function
		* Added Prefix support
		* A lot of chat messages
		
	To Do:
		* Late load / reload support. - done
		* Natives - done
		* Check Ready and not ready clan tag if working properly
		* Implement Ban system.
		* Add check for match end (prop shutdown server) - done
		* Add check for match players and how many are in a match (incase one of them abandoned) - Done
*/

public Plugin myinfo = 
{
	name = "Match System", 
	author = PLUGIN_AUTHOR, 
	description = "Hi", 
	version = PLUGIN_VERSION, 
	url = "None"
};

//#define OLD_DAMAGE_REPORT
#define PrintDebug	PrintToServer
#define CheckMatchState(%1)	( gMatchState == ( %1 ) )
//#define SetMatchId(%1)		strcopy(gMatchId, sizeof g_szMatchId, %1)
#define SetMatchId(%1)		gMatchId = %1
//#define CheckMatchId(%1) 	StrEqual(g_szMatchId, %1)
#define CheckMatchId(%1)	( gMatchId == ( %1 ) )

//#define TEST_VERSION

// -------------------------------------------
// 				Start: SQL Stuff
// -------------------------------------------
Database g_hSql;

char g_szQuery[MAX_QUERY_LENGTH], g_szError[MAX_ERROR_LENGTH];

enum
{
	ServersField_IP, 
	ServersField_Port, 
	ServersField_MatchId, 
	
	ServersFieldsCount
};
new String:g_szServersTableName[] = "match_servers";
new String:g_szServersTableFields[ServersFieldsCount][] =  {
	"server_ip", 
	"server_port", 
	"current_match_id"
};

enum
{
	MatchField_MatchId = 0, 
	MatchField_Map, 
	MatchField_RecordStats, 
	MatchField_AcceptTime, 
	MatchField_StartTime, 
	MatchField_EndTime, 
	MatchField_TeamId_First, 
	MatchField_TeamId_Second, 
	MatchField_Winner, 
	MatchField_MatchEndCode, 
	//	MatchField_MatchEndReason,
	
	MatchTableFields
};

new const String:g_szMatchTableName[] = "match_list";
new const String:g_szMatchTableFields[MatchTableFields][] =  {
	"matchid", 
	"map_name", 
	"recorded_stats", 
	"match_accept_time", 
	"start_time", 
	"end_time", 
	"team1_id", 
	"team2_id", 
	"winner_team", 
	"match_end_code", 
	//"match_end_reason"
};

enum
{
	MatchPlayersField_PlayerId, 
	MatchPlayersField_MatchId, 
	MatchPlayersField_AuthId,  // SteamID
	MatchPlayersField_TeamId, 
	MatchPlayersField_TeamName, 
	
	MatchPlayersFields
};

new const String:g_szMatchPlayersTableName[] = "match_players";
new const String:g_szMatchPlayersTableFields[MatchPlayersFields][] =  {
	"id", 
	"matchid", 
	"steam", 
	"team_id", 
	"team_name"
};


enum
{
	BanReasonCode_Cheater = 1,
	BanReasonCode_Abandon = 5,  // 2 - Player abandoned the match.
	
	//	BanReasonCode_Accept_Fail,						// 3 - Player failed to accept the match.
};

enum
{	
	BanSubCode_Abandon_Normal = 1,						// Disconnected, and then Abandoned the game.
	BanSubCode_Abandon_ConnectFailure_MatchStart = 2,	// Never connected.
	BanSubCode_Abandon_ConnectFailure_Disconnect = 3, 	// Disconnected, never connected back to the game.
	
	BanSubCode_Cheater_Normal = 1 // Cheater.
}

enum
{
	//	PlayerBanField_Id
	PlayerBanField_BanId, 
	PlayerBanField_MatchId, 
	PlayerBanField_AuthId, 
	PlayerBanField_BannedName, 
	PlayerBanField_BanCode, 
	PlayerBanField_BanCodeText, 
	PlayerBanField_BanTime, 
	PlayerBanField_StartTime, 
	PlayerBanField_EndTime, 
	
	PlayerBanField_Count
};

new const String:g_szPlayersBansTableName[] = "player_bans";
new const String:g_szPlayersBansTableFields[PlayerBanField_Count][] =  {
	//	"id",
	"banid", 
	"matchid", 
	"banned_name", 
	"ban_code", 
	"ban_code_txt", 
	"ban_time", 
	"start_time", 
	"end_time"
};

enum
{
	//	BanStepsField_Id,
	BanStepsField_BanCode, 
	BanStepsField_BanStep, 
	BanStepsField_BanTime, 
	BanStepsField_MatchesCount, 
	
	BanStepsField_Count
};
new const String:g_szBanStepsTableName[] = "bans_steps";
new const String:g_szBanStepsTableFields[BanStepsField_Count][] =  {
	//	"id",
	"ban_code", 
	"ban_step", 
	"ban_time", 
	"downgrade_matches"
};

enum
{
	//	PlayersBanDataField_Id,
	PlayersBanDataField_AuthId, 
	PlayersBanDataField_BanCode, 
	PlayersBanDataField_BanStep, 
	PlayersBanDataField_MatchesLeft,
	
	PlayersBanDataField_Count
};

new const String:g_szPlayersBanDataTableName[] = "players_ban_data";
new const String:g_szPlayersBanTableFields[PlayerBanField_Count][] =  {
		"id",
	"steam", 
	"ban_code",
	//"last_ban_id", 
//	"ban_step", 
	"matches_left", 
};

// -------------------------------------------
// 				Start: Local stats save.
// -------------------------------------------
enum
{
	Stats_MatchId = 0, 
	// Below are the ones that are used
	// In both local SQLite Table and SQL table.
	Stats_AuthId, 
	Stats_Kills, 
	Stats_Headshots, 
	Stats_Deaths, 
	Stats_Assists, 
	
	Stats_BombPlants, 
	Stats_BombDefuses, 
	
	Stats_2Kills, 
	Stats_3Kills, 
	Stats_4Kills, 
	Stats_Aces, 
	
	Stats_TotalShots, 
	Stats_TotalHits, 
	Stats_TotalDamage, 
	
	Stats_TotalMVPs, 
	Stats_TotalJumps, 
	
	Stats_RoundsPlayed, 
	
	Stats_Count
};

enum RecordStats( <<  = 1)
{
	RecordStats_DoNotRecord = -1, 
	RecordStats_None = 0, 
	RecordStats_Kills = 1, 
	RecordStats_Headshots, 
	RecordStats_Deaths, 
	RecordStats_Assists, 
	RecordStats_BombPlants, 
	RecordStats_BombDefuses, 
	RecordStats_2Kills, 
	RecordStats_3Kills, 
	RecordStats_4Kills, 
	RecordStats_Aces, 
	RecordStats_TotalShots, 
	RecordStats_TotalHits, 
	RecordStats_TotalDamage, 
	RecordStats_MVP, 
	RecordStats_TotalJumps, 
	RecordStats_RoundsPlayed
};

const RecordStats RecordStats_All = (RecordStats_Kills | RecordStats_Headshots | RecordStats_Deaths | RecordStats_Assists
	 | RecordStats_BombPlants | RecordStats_BombDefuses | RecordStats_2Kills | RecordStats_3Kills
	 | RecordStats_4Kills | RecordStats_Aces | RecordStats_TotalShots | RecordStats_TotalHits
	 | RecordStats_TotalDamage | RecordStats_MVP | RecordStats_RoundsPlayed);

RecordStats g_iStatsRecorded;
Handle g_hSqliteStats = INVALID_HANDLE;
new const String:g_szSqliteTablePrefix[] = "match_";

new const String:g_szStatsDBName[] = "match_stats"; // Used for SQLite
new const String:g_szStatsTableName[] = "match_stats";
new const String:g_szStatsTableFields[Stats_Count][] =  {
	"matchid", 
	"steam", 
	
	"kills", 
	"headshots", 
	"deaths", 
	"assists", 
	
	"bomb_plants", 
	"bomb_defuses", 
	
	"2k", 
	"3k", 
	"4k", 
	"ace", 
	
	"total_shots", 
	"total_hits", 
	"total_damage", 
	
	"total_mvps", 
	"total_jumps", 
	
	"rounds_played"
};

int g_iKillsThisRound[MAXPLAYERS];
int g_iKills[MAXPLAYERS], 
g_iHeadshots[MAXPLAYERS], 
g_iDeaths[MAXPLAYERS], 
g_iAssists[MAXPLAYERS], 

g_iBombPlants[MAXPLAYERS], 
g_iBombDefuses[MAXPLAYERS];
g_i2Kills[MAXPLAYERS], 
g_i3Kills[MAXPLAYERS], 
g_i4Kills[MAXPLAYERS], 
g_iAces[MAXPLAYERS], 

g_iTotalShots[MAXPLAYERS], 
g_iTotalHits[MAXPLAYERS];
float g_flTotalDamage[MAXPLAYERS];

int g_iTotalMVPs[MAXPLAYERS], 
g_iTotalJumps[MAXPLAYERS], 
g_iRoundsPlayed[MAXPLAYERS];

// -------------------------------------------
// 				Start: Constants
// -------------------------------------------
#define NUMBER_RESTARTS		3

#define DELAY_RESTART_KNIFE_ROUND 5

#define ALLOW_OUTSIDE_CLIENTS
#define ALLOW_ADMINS
//#define ALLOW_SPECS
#define MAX_OUTSIDE_CLIENTS 1

#if defined ALLOW_OUTSIDE_CLIENTS
int g_iOutsideClients;
#endif

#define WARMUP_RESPAWN_TIME	3.0

const int MATCH_END_KICK_TIME = 15;

new const String:KICK_MESSAGE_OUTSIDE_CLIENTS_EXCEEDED[] = "Maximum outside clients limit has been exceeded";
new const String:KICK_MESSAGE_NOT_ALLOWED[] = "You are not allowed to join the server.";
new const String:KICK_MESSAGE_MATCH_CANCELED[] = "The match was canceled.";
new const String:KICK_MESSAGE_MATCH_ENDED[] = "The match has ended.";

new const String:g_szConfigFolder[] = "matchsystem";
new const String:g_szWarmUpConfig[] = "warmup.cfg";
new const String:g_szMatchConfig[] = "match.cfg";
new const String:g_szKnifeRoundConfig[] = "knife_round.cfg";

// -------------------------------------------
// 				Start: Match Vars
// -------------------------------------------
enum MatchState
{
	Match_Waiting = 0, 
	
	Match_FirstReadyPhase, 
	Match_KnifeRound, 
	Match_TeamChoose, 
	Match_SecondReadyPhase,  // This is after the team choose.
	Match_Restarts, 
	Match_Running
};

MatchState gMatchState = Match_Waiting;
//char g_szMatchId[MATCHID_MAX_LENGTH];
int gMatchId;

#if !defined TEST_VERSION
int g_iMatchPlayersCount;
#else
int g_iMatchPlayersCount = 10;
#endif

bool g_bHalfTimeReached = false;

char g_szMatchMap[35];
int g_iKickTime;

// -------------------------------------------
// 				Start: Team Info
// -------------------------------------------
enum TeamInfo
{
	TeamInfo_TeamId = 0,  // From Table
	TeamInfo_CurrentTeam,  // CS_TEAM_CT, CS_TEAM_T;
}

enum TeamsIndexes
{
	TeamIndex_None = -1, 
	TeamIndex_First = 0, 
	TeamIndex_Second
}

int gTeams[TeamsIndexes][TeamInfo];
char g_szTeamNames[TeamsIndexes][32];
// Team Menu, PutPlayersInTeams()
TeamsIndexes g_iChoosingTeamIndex;
TeamsIndexes g_iTeamIndex[MAXPLAYERS + 1];

// -------------------------------------------
// 				Start: Player Vars
// -------------------------------------------
// Player State
enum PlayerState
{
	PlayerState_Error = -1, 
	
	PlayerState_None, 
	PlayerState_Checking,  // Still connecting to the database to check the player. // Do later
	PlayerState_Player,  // Player who partipates in match.
	PlayerState_Bot, 
	PlayerState_Admin,  // Admin
	PlayerState_Spectator // Do this later (Spectators defined in database)
};

PlayerState gPlayerState[MAXPLAYERS];

// ReadyUp
bool g_bReady[MAXPLAYERS + 1];
int g_iReadyCount;

// Clan Tags
char g_szOriginalClanTag[MAXPLAYERS + 1][MAX_NAME_LENGTH];

// Damage Report
float g_flDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iHits[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iKiller[MAXPLAYERS + 1];
// -------------------------------------------
// 				Start: ConVars
// -------------------------------------------
ConVar ConVar_ServerAddress, ConVar_KnifeRound_Enabled, 
ConVar_ServerPort, ConVar_KnifeRound_DisarmC4;

char g_szServerAddress[20];
int g_iServerPort;
bool g_bKnifeRound_Enabled, g_bKnifeRound_DisarmC4;

// -------------------------------------------
// 				Start: Other
// -------------------------------------------
DataPack g_hRestartsPack;
int g_iRestarts, g_iNumRestarts, 
g_bRestarting;

Handle g_hForward_MatchStateChanged, 
g_hForward_MatchPlayer_Joined, g_hForward_MatchPlayer_Disconnect, 
g_hForward_MatchStart, g_hForward_MatchEnd, 
g_hForward_MatchRecieved;

bool g_bLate;

enum
{
	MatchEndCode_None = 0, 
	MatchEndCode_End,  // 1 - Match Ended normally. Winner will be passed.
	MatchEndCode_Surrender,  // 2 - Match Ended by a team surrenderring.	Winner will be passed.
	MatchEndCode_ConnectFailure,  // 3 - Players failed to connect within the given time. No winner. (Match Canceled)
	MatchEndCode_Cancelled_Crash,  // 4 - Server has crashed.
	MatchEndCode_Cancelled_Admin,  // 5 - The match was cancelled by a superior admin. Winner can be passed or not (depending on the admin).
	
	MatchEndReason_Count
};

/*
char g_szMatchEndReasonString[MatchEndReason_Count][] = {
	"No Reason Provided",
	"Match ended normally",
	"A team has surrendered",
	"A player or more failed to connect",
	"Cancelled -> Server crashed",
	"Cancelled -> Admin Command"
};*/
/*
int g_iMatchEndCode = MatchEndCode_None;
int g_iWinnerTeam;
*/
// -------------------------------------------
// 		Plugin Initialization
// -------------------------------------------
// Do compatibility for late load (final thing)
public APLRes AskPluginLoad2(Handle plugin, bool bLate, char[] szError, int iErrMax)
{
	g_bLate = bLate;
	
	CreateNative("Match_GetMatchId", Native_GetMatchId);
	CreateNative("Match_GetMatchState", Native_GetMatchState);
	CreateNative("Match_GetPlayerState", Native_GetPlayerState);
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hRestartsPack = CreateDataPack();
	
	// Match Players Commands
	AddCommandListener(ClCmd_JoinTeam, "jointeam");
	AddCommandListener(ClCmd_Say, "say");
	AddCommandListener(ClCmd_Say, "say_team");
	
	// AdminCommands
	RegAdminCmd("sm_match_end", AdmCmd_EndMatch, ADMFLAG_RCON, "[confirm] <winner team> - End the current match");
	RegAdminCmd("sm_match_force_start", AdmCmd_ForceMatchStart, ADMFLAG_RCON, "[confirm] - Forces everyone to ready up.");
	//RegAdminCmd("sm_match_restartround", AdmCmd_RestartRound, ADMFLAG_RCON, "[confirm] <round number> - Restarts a round.");
	// Only for test
	RegAdminCmd("sm_check_match_id", AdmCmd_CheckMatchId, ADMFLAG_RCON, "Retrieves the match id from the database.");
	RegAdminCmd("start_match", AdmCmd_CheckMatchId, ADMFLAG_RCON, "Retrieves the match id from the database.");
	
	// ConVars
	ConVar_ServerAddress = FindConVar("hostip");
	ConVar_ServerPort = FindConVar("hostport");
	ConVar_KnifeRound_Enabled = CreateConVar("ms_kniferound_enabled", "1", "Enable knife rounds for choosing sides");
	ConVar_KnifeRound_DisarmC4 = CreateConVar("ms_kniferound_disarm_c4", "1", "Disarm C4 during knife round");
	
	HookConVarChange(ConVar_ServerAddress, ConVarHook_Changed);
	HookConVarChange(ConVar_KnifeRound_Enabled, ConVarHook_Changed);
	HookConVarChange(ConVar_KnifeRound_DisarmC4, ConVarHook_Changed);
	
	new pieces[4];
	new longip = GetConVarInt(ConVar_ServerAddress);
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	
	// Do
	//FormatEx(g_szServerAddress, sizeof(g_szServerAddress), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	FormatEx(g_szServerAddress, sizeof(g_szServerAddress), "75.118.154.5");
	g_iServerPort = GetConVarInt(ConVar_ServerPort);
	
	PrintDebug("HostIP: %s:%d", g_szServerAddress, g_iServerPort);
	g_bKnifeRound_Enabled = GetConVarBool(ConVar_KnifeRound_Enabled);
	g_bKnifeRound_DisarmC4 = GetConVarBool(ConVar_KnifeRound_DisarmC4);
	
	// Needed for main system
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Pre);
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	// Needed for stats
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("round_mvp", Event_PlayerMVP);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
	
	g_hForward_MatchStateChanged = CreateGlobalForward("Match_OnMatchStateChanged", ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_MatchPlayer_Joined = CreateGlobalForward("Match_OnMatchPlayerJoined", ET_Ignore, Param_Cell);
	g_hForward_MatchPlayer_Disconnect = CreateGlobalForward("Match_OnMatchPlayerDisconnect", ET_Ignore, Param_Cell);
	g_hForward_MatchRecieved = CreateGlobalForward("Match_OnMatchRecieved", ET_Ignore, Param_Cell);
	g_hForward_MatchStart = CreateGlobalForward("Match_OnMatchStart", ET_Ignore, Param_Cell);
	g_hForward_MatchEnd = CreateGlobalForward("Match_OnMatchEnd", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	// SQlite & SQL
	ConnectToSQLDatabases();
	ResetMatchStuff(false);
	
	// Do later
	if (g_bLate)
	{
		//ResetMatchStuff();
		CheckClients();
	}
}

public Action AdmCmd_CheckMatchId(int client, int iArgs)
{
	char szArg[20];
	GetCmdArg(1, szArg, sizeof szArg);
	
	if (StrEqual(szArg, "cancel", false))
	{
		GetCmdArg(2, szArg, sizeof szArg);
		RecordStats iStats;
		if (!strlen(szArg))iStats = RecordStats_None;
		else iStats = view_as<RecordStats>(StringToInt(szArg));
		
		if (!CheckMatchId(MATCHID_NO_MATCH))
		{
			// Do later
			DropTable();
		}
		
		//g_iMatchEndCode = MatchEndCode_Canclled;
		//g_iWinner = StrToInt(szArg);
		
		MatchEndStuff(true, iStats, MatchEndCode_Cancelled_Admin, TeamIndex_None);
		
		//ResetMatchStuff(false);
		KickAllClients(KICK_MESSAGE_MATCH_CANCELED);
		ServerCommand("mp_restartgame 1");
		ReplyToCommand(client, "MatchID set to: NO MATCH");
		
		return Plugin_Handled;
	}
	
	if (!CheckMatchId(MATCHID_NO_MATCH))
	{
		ReplyToCommand(client, "There is a match running already.");
		return Plugin_Handled;
	}
	
	SQL_TQuery_Custom(g_hSql, SQLCallback_CheckMatch, client, _, "Check Match Query", "SELECT `%s` FROM `%s` WHERE `%s` = '%s' AND `%s` = %d", 
		g_szServersTableFields[ServersField_MatchId], g_szServersTableName, 
		g_szServersTableFields[ServersField_IP], g_szServerAddress, g_szServersTableFields[ServersField_Port], g_iServerPort);
	//CheckClients();
	
	return Plugin_Handled;
}

void DropTable()
{
	SQL_TQuery_Custom(g_hSqliteStats, SQLiteCallback_Dump, 0, _, "Drop Table Query", "DROP TABLE `%s%d`;", g_szSqliteTablePrefix, gMatchId);
}

public void SQLCallback_CheckMatch(Handle hSql, Handle hResult, char[] szError, any data)
{
	if (CheckError(szError))
	{
		LogError("Check Match Error: %s", szError);
		return;
	}
	
	if (!SQL_GetRowCount(hResult))
	{
		LogError("Check Match Error: SERVER IP %s NOT REGISTERED IN THE DATABASE", g_szServerAddress);
		return;
	}
	
	//char szMatchId[MATCHID_MAX_LENGTH];
	int iMatchId;
	SQL_FetchRow(hResult);
	
	if (SQL_IsFieldNull(hResult, 0))
	{
		if (!CheckMatchId(MATCHID_NO_MATCH))
		{
			ResetMatchStuff(false);
			KickAllClients(KICK_MESSAGE_MATCH_CANCELED);
			return;
		}
		
		return;
	}
	
	//SQL_FetchString(hResult, 0, szMatchId, sizeof szMatchId);
	iMatchId = SQL_FetchInt(hResult, 0);
	
	// New MatchId, not the current one
	// Do update data instead here
	if (!CheckMatchId(iMatchId))
	{
		//DropTable();
		ResetMatchStuff(true);
	}
	
	SetMatchId(iMatchId);
	
	if (!GetMatchData())
	{
		return;
	}
	
	if (!CreateSQLiteTable())
	{
		return;
	}
	
	SetMatchState(Match_FirstReadyPhase);
	PrintDebug("Players Count = %d", g_iMatchPlayersCount);
	
	Call_StartForward(g_hForward_MatchRecieved);
	Call_PushCell(gMatchId);
	Call_Finish();
	
	ServerCommand("changelevel \"%s\"", g_szMatchMap);
}

bool CheckError(char[] szError)
{
	if (StrContains(szError, "no error", false) == -1 && szError[0])
	{
		
		return true;
	}
	
	return false;
}

bool GetMatchData()
{
	SQL_LockDatabase(g_hSql);
	
	// Get Players Count;
	char szError[128];
	Handle hQuery = SQL_ExecuteQuery(g_hSql, szError, sizeof szError, "Players Count", "SELECT COUNT(*) FROM `%s` WHERE `%s` = '%d'", 
		g_szMatchPlayersTableName, g_szMatchPlayersTableFields[MatchPlayersField_MatchId], gMatchId);
	
	if (hQuery == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(g_hSql);
		SetFailState("Check ERROR logs");
		return false;
	}
	
	SQL_FetchRow(hQuery);
	g_iMatchPlayersCount = SQL_FetchInt(hQuery, 0);
	
	delete hQuery;
	
	// Match Data (map, savestats)
	//hQuery = SQL_ExecuteQuery(g_hSql, szError, sizeof szError, "Map, Stats, TeamIds", "SELECT `%s`,`%s`,`%s`,`%s` FROM `%s` WHERE `%s` = %d",
	hQuery = SQL_ExecuteQuery(g_hSql, szError, sizeof szError, "Map, Stats, TeamIds", "SELECT `%s`,`%s` FROM `%s` WHERE `%s` = %d", 
		g_szMatchTableFields[MatchField_Map], g_szMatchTableFields[MatchField_RecordStats], 
		//g_szMatchTableFields[MatchField_TeamId_First], g_szMatchTableFields[MatchField_TeamId_Second],
		g_szMatchTableName, g_szMatchTableFields[MatchField_MatchId], gMatchId);
	
	if (hQuery == INVALID_HANDLE)
	{
		SetFailState("Check ERROR logs: %s", g_szError);
		
		SQL_UnlockDatabase(g_hSql);
		
		return false;
	}
	
	if (!SQL_FetchRow(hQuery))
	{
		LogError("Could not find a result set for MatchData");
		
		SQL_UnlockDatabase(g_hSql);
		delete hQuery;
		
		return false;
	}
	
	//SQL_FetchRow(hQuery);
	SQL_FetchString(hQuery, 0, g_szMatchMap, sizeof g_szMatchMap);
	
	g_iStatsRecorded = view_as<RecordStats>(SQL_FetchInt(hQuery, 1));
	PrintDebug("g_iStatsRecorded = %d, RecordStats_All = %d", g_iStatsRecorded, RecordStats_All);
	
	int iFirstTeam = GetRandomInt(0, 1) ? CS_TEAM_T : CS_TEAM_CT;
	
	gTeams[TeamIndex_First][TeamInfo_TeamId] = 1; //SQL_FetchInt(hQuery, 2);
	gTeams[TeamIndex_First][TeamInfo_CurrentTeam] = iFirstTeam;
	
	gTeams[TeamIndex_Second][TeamInfo_TeamId] = 2; //SQL_FetchInt(hQuery, 3);
	gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] = iFirstTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T;
	
	delete hQuery;
	
	enum
	{
		TeamField_TeamId, 
		TeamField_TeamName, 
		/*		TeamField_FoundedOn,
		TeamField_FoudnerId,
		TeamField_CachedWins,
		TeamField_Cached_Losses,
		TeamField_CachedRating,
*/
		TeamField_Count
	};
	
	new const String:g_szTeamsTableName[] = "teams";
	new const String:g_szTeamsTableFields[TeamField_Count][] =  {
		"id", 
		"name", 
		/*		"founded_on",
		"founder_id",
		"cached_wins",
		"cached_losses",
		"chached_rating"
*/
	};
	
	hQuery = SQL_ExecuteQuery(g_hSql, g_szError, sizeof g_szError, "Get team name query", 
		"SELECT `%s`, `%s` FROM `%s` WHERE `%s` = %d OR `%s` = %d", 
		g_szTeamsTableFields[TeamField_TeamId], g_szTeamsTableFields[TeamField_TeamName], g_szTeamsTableName, 
		g_szTeamsTableFields[TeamField_TeamId], gTeams[TeamIndex_First][TeamInfo_TeamId], 
		g_szTeamsTableFields[TeamField_TeamId], gTeams[TeamIndex_Second][TeamInfo_TeamId]);
	
	if (hQuery == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(g_hSql);
		return false;
	}
	
	if (SQL_GetRowCount(hQuery) < 2)
	{
		LogError("Get team name query returned less than two rows.");
		
		delete hQuery;
		SQL_UnlockDatabase(g_hSql);
		return false;
	}
	
	int iTeamId;
	TeamsIndexes iTeamIndex;
	while (SQL_FetchRow(hQuery))
	{
		iTeamId = SQL_FetchInt(hQuery, 0);
		iTeamIndex = gTeams[TeamIndex_First][TeamInfo_TeamId] == iTeamId ? TeamIndex_First : TeamIndex_Second;
		
		SQL_FetchString(hQuery, 1, g_szTeamNames[iTeamIndex], sizeof g_szTeamNames[]);
	}
	
	delete hQuery;
	SQL_UnlockDatabase(g_hSql);
	
	FixTeamNames();
	
	return true;
}

public Action AdmCmd_EndMatch(int client, int iArgs)
{
	char szConfirmArg[10];
	GetCmdArg(1, szConfirmArg, sizeof szConfirmArg);
	
	if (!StrEqual(szConfirmArg, "confirm", false))
	{
		ReplyToCommand(client, "This command will end the match. Please confirm the command by writing \"confirm\" as the first arg");
		return Plugin_Handled;
	}
	
	//g_iMatchEndCode = MatchEndCode_Cancelled_Admin;
	//g_iWinnerTeam = TEAM_NONE;
	
	int iOldScore = GetTeamScore(CS_TEAM_CT);
	SetTeamScore(CS_TEAM_CT, 1);
	SetConVarInt(CreateConVar("mp_maxrounds", ""), 1);
	SetTeamScore(CS_TEAM_CT, iOldScore);
	
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "An admin has ended the match.");
	
	MatchEndStuff(true, RecordStats_All, MatchEndCode_Cancelled_Admin, TeamIndex_None);
	
	//g_iKickTimer = MATCH_END_KICK_TIME;
	
	//KickAllClients();
	//CreateTimer(1.0, Timer_KickAll, 0, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	return Plugin_Handled;
}

public Action AdmCmd_ForceMatchStart(int client, int iArgs)
{
	
}

void ConnectToSQLDatabases()
{
	char szError[256];
	if (SQL_CheckConfig("match_system"))
	{
		g_hSql = SQL_Connect("match_system", true, szError, sizeof szError);
	}
	
	else
	{
		LogMessage("DB Config 'matchsystem' is missing from databases.cfg. Connecting to values in plugin.");
		
		 / Handle hKv = CreateKeyValues("");
		//KvSetString(hKv, "driver", "mysql");
		//KvSetString(hKv, "host", "cyberesports.net");
		//KvSetString(hKv, "user", "saif_admin");
		//KvSetString(hKv, "pass", "Au9Y}/^(10m&i\"i"); // Au9Y}/^(10m&i"i
		//KvSetString(hKv, "database", "saif_database");
		//g_hSql = SQL_Connects (hDriver, "", "", "", "", szError, sizeof szError);
		
		g_hSql = SQL_ConnectCustom(hKv, szError, sizeof szError, true);
		delete hKv;
	}
	
	if (szError[0])
	{
		LogError("MySQL CONNECT ERROR: %s", szError);
		SetFailState("SQL Connection failed. Check error logs");
		
		return;
	}
	
	g_hSqliteStats = SQLite_UseDatabase(g_szStatsDBName, szError, sizeof szError);
	
	if (szError[0])
	{
		LogError("SQLite CONNECT ERROR: %s", szError);
		SetFailState("SQL Connection failed. Check error logs");
		return;
	}
	
	CheckIfServerHasCrashed();
}

void CheckIfServerHasCrashed()
{
	SQL_LockDatabase(g_hSql);
	
	Handle hResult = SQL_ExecuteQuery(g_hSql, g_szError, sizeof g_szError, "Check Crash Query #1", 
		"SELECT `%s` FROM `%s` WHERE `%s` = '%s' AND `%s` = %d", 
		g_szServersTableFields[ServersField_MatchId], g_szServersTableName, g_szServersTableFields[ServersField_IP], g_szServerAddress, 
		g_szServersTableFields[ServersField_Port], g_iServerPort);
	
	if (hResult == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(g_hSql);
		return;
	}
	
	SQL_FetchRow(hResult);
	int iMatchId = SQL_FetchInt(hResult, 0);
	
	if (SQL_IsFieldNull(hResult, 0) || iMatchId == MATCHID_NO_MATCH)
	{
		SQL_UnlockDatabase(g_hSql);
		delete hResult;
		
		PrintDebug(" NO +++++++++++++++++");
		return;
	}
	
	delete hResult;
	hResult = SQL_ExecuteQuery(g_hSql, g_szError, sizeof g_szError, "Check Crash Query #2", 
		"SELECT COUNT(*) FROM `%s` WHERE `%s` = %d AND `%s` IS NOT NULL AND `%s` < UNIX_TIMESTAMP()", 
		g_szMatchTableName, g_szMatchTableFields[MatchField_MatchId], iMatchId, g_szMatchTableFields[MatchField_StartTime], g_szMatchTableFields[MatchField_StartTime]);
	
	if (hResult == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(g_hSql);
		delete hResult;
		
		return;
	}
	
	SQL_FetchRow(hResult);
	if (SQL_FetchInt(hResult, 0) <= 0)
	{
		SQL_UnlockDatabase(g_hSql);
		delete hResult;
		
		return;
	}
	
	delete hResult;
	SQL_UnlockDatabase(g_hSql);
	
	SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0, _, "Check Crash Query #3", 
		"UPDATE `%s` \
	SET `%s` = UNIX_TIMESTAMP(), \
	`%s` = %d, \
	`%s` = %d \
	WHERE `%s` = %d", 
		//	`%s` = '%s'
		g_szMatchTableName, 
		g_szMatchTableFields[MatchField_EndTime], 
		g_szMatchTableFields[MatchField_Winner], TEAM_ID_NONE, 
		g_szMatchTableFields[MatchField_MatchEndCode], MatchEndCode_Cancelled_Crash, 
		//	g_szMatchTableFields[MatchField_MatchEndReason], g_szMatchEndReasonString[MatchEndCode_Cancelled_Crash],
		g_szMatchTableFields[MatchField_MatchId], iMatchId);
	
	SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0, _, "Check Crash Query #4", 
		"UPDATE `%s` \
	SET `%s` = NULL \
	WHERE `%s` = %d AND `%s` = '%s' AND `%s` = %d", 
		g_szServersTableName, 
		g_szServersTableFields[ServersField_MatchId], 
		g_szServersTableFields[ServersField_MatchId], iMatchId, 
		g_szServersTableFields[ServersField_IP], g_szServerAddress, 
		g_szServersTableFields[ServersField_Port], g_iServerPort);
	
	PrintDebug("------- ////////// Server crashed, fixed");
}

void CheckClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientAuthorized(i))
		{
			CheckIfClientIsAllowed(i);
		}
	}
}

void MatchEndStuff(bool bDoQuerys = true, RecordStats iStatsBit = RecordStats_None, int iCode = MatchEndCode_None, TeamsIndexes iWinnerTeamIndex)
{
	if (bDoQuerys)
	{
		SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0, _, "MatchEnd Time Update Query", "UPDATE `%s` SET `%s` = UNIX_TIMESTAMP(), `%s` = %d, `%s` = %d WHERE `%s` = %d", 
			g_szMatchTableName, 
			g_szMatchTableFields[MatchField_EndTime],  // UNIX_TIMESTAMP()
			g_szMatchTableFields[MatchField_Winner], iWinnerTeamIndex == TeamIndex_None ? TEAM_ID_NONE : gTeams[iWinnerTeamIndex][TeamInfo_TeamId], 
			g_szMatchTableFields[MatchField_MatchEndCode], iCode, 
			//		g_szMatchTableFields[MatchField_MatchEndReason], g_szMatchEndReasonString[iCode],
			g_szMatchTableFields[MatchField_MatchId], gMatchId);
		
		SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0, _, "MatchEnd ID Update Query", "UPDATE `%s` SET `%s` = NULL WHERE `%s` = %d", 
			g_szServersTableName, 
			g_szServersTableFields[ServersField_MatchId], 
			g_szServersTableFields[ServersField_MatchId], gMatchId);
	}
	
	if (iStatsBit != RecordStats_DoNotRecord)
	{
		PrintDebug("Uploading Stats");
		UploadAllPlayersStats(iStatsBit);
	}
	
	Call_StartForward(g_hForward_MatchEnd);
	Call_PushCell(gMatchId);
	Call_PushCell(iCode);
	Call_PushCell(iWinnerTeamIndex);
	Call_Finish();
	
	ResetMatchStuff(false);
	
	g_iKickTime = MATCH_END_KICK_TIME;
	CreateTimer(1.0, Timer_KickAll, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void UploadAllPlayersStats(RecordStats iStatsBit)
{
	// We will get all stats from SQLite Table.
	// Gotta update all values in it.
	UpdateAllLocalStats();
	
	char szAuthId[35];
	//char szQuery[512];
	int iLen;
	
	SQL_LockDatabase(g_hSqliteStats);
	
	char szError[128];
	Handle hResult = SQL_ExecuteQuery(g_hSqliteStats, szError, sizeof szError, "SQLite-> Stats Select Query", 
		"SELECT `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s` FROM `%s%d`", 
		g_szStatsTableFields[Stats_AuthId], 
		g_szStatsTableFields[Stats_Kills], g_szStatsTableFields[Stats_Deaths], g_szStatsTableFields[Stats_Headshots], 
		g_szStatsTableFields[Stats_Assists], g_szStatsTableFields[Stats_BombPlants], g_szStatsTableFields[Stats_BombDefuses], 
		g_szStatsTableFields[Stats_2Kills], g_szStatsTableFields[Stats_3Kills], g_szStatsTableFields[Stats_4Kills], 
		g_szStatsTableFields[Stats_Aces], g_szStatsTableFields[Stats_TotalHits], g_szStatsTableFields[Stats_TotalShots], 
		g_szStatsTableFields[Stats_TotalDamage], g_szStatsTableFields[Stats_TotalMVPs], g_szStatsTableFields[Stats_TotalJumps], 
		g_szStatsTableFields[Stats_RoundsPlayed], g_szSqliteTablePrefix, gMatchId);
	//SQL_ExecuteQuery(Handle hMain, char[] szError, int iErrSize, const char[] szQueryDesc, char[] szQuery, any ...);
	
	if (hResult == INVALID_HANDLE)
	{
		LogError("Handle Invalid");
		SQL_UnlockDatabase(g_hSqliteStats);
		
		return;
	}
	
	//int iDump;
	//while(SQL_MoreRows(hResult))
	while (SQL_FetchRow(hResult))
	{
		PrintDebug("SQL_MoreRows = %d, iStatsBit %d", SQL_MoreRows(hResult), iStatsBit);
		// TO DO FIX - Fixed, i think, needs test
		//SQL_FetchRow(hResult);
		
		SQL_FetchString(hResult, 0, szAuthId, sizeof szAuthId);
		/*if(GetTrieValue(Trie_hUploadedAuthId, szAuthId, iDump))
		{
			continue;
		} */
		
		iLen = FormatEx(g_szQuery, sizeof g_szQuery, "INSERT INTO `%s` (`%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`) ", 
			g_szStatsTableName, g_szStatsTableFields[Stats_MatchId], g_szStatsTableFields[Stats_AuthId], 
			g_szStatsTableFields[Stats_Kills], g_szStatsTableFields[Stats_Deaths], g_szStatsTableFields[Stats_Headshots], 
			g_szStatsTableFields[Stats_Assists], g_szStatsTableFields[Stats_BombPlants], g_szStatsTableFields[Stats_BombDefuses], 
			g_szStatsTableFields[Stats_2Kills], g_szStatsTableFields[Stats_3Kills], g_szStatsTableFields[Stats_4Kills], 
			g_szStatsTableFields[Stats_Aces], g_szStatsTableFields[Stats_TotalHits], g_szStatsTableFields[Stats_TotalShots], 
			g_szStatsTableFields[Stats_TotalDamage], g_szStatsTableFields[Stats_TotalMVPs], g_szStatsTableFields[Stats_TotalJumps], g_szStatsTableFields[Stats_RoundsPlayed]);
		
		iLen += FormatEx(g_szQuery[iLen], sizeof(g_szQuery) - iLen, "VALUES ( %d, '%s', %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d );", 
			gMatchId, szAuthId, 
			((iStatsBit & RecordStats_Kills) ? SQL_FetchInt(hResult, 1) : -5614), 
			((iStatsBit & RecordStats_Deaths) ? SQL_FetchInt(hResult, 2) : -5614), 
			((iStatsBit & RecordStats_Headshots) ? SQL_FetchInt(hResult, 3) : -5614), 
			((iStatsBit & RecordStats_Assists) ? SQL_FetchInt(hResult, 4) : -5614), 
			((iStatsBit & RecordStats_BombPlants) ? SQL_FetchInt(hResult, 5) : -5614), 
			((iStatsBit & RecordStats_BombDefuses) ? SQL_FetchInt(hResult, 6) : -5614), 
			((iStatsBit & RecordStats_2Kills) ? SQL_FetchInt(hResult, 7) : -5614), 
			((iStatsBit & RecordStats_3Kills) ? SQL_FetchInt(hResult, 8) : -5614), 
			((iStatsBit & RecordStats_4Kills) ? SQL_FetchInt(hResult, 9) : -5614), 
			((iStatsBit & RecordStats_Aces) ? SQL_FetchInt(hResult, 10) : -5614), 
			((iStatsBit & RecordStats_TotalHits) ? SQL_FetchInt(hResult, 11) : -5614), 
			((iStatsBit & RecordStats_TotalShots) ? SQL_FetchInt(hResult, 12) : -5614), 
			((iStatsBit & RecordStats_TotalDamage) ? SQL_FetchInt(hResult, 13) : -5614), 
			((iStatsBit & RecordStats_MVP) ? SQL_FetchInt(hResult, 14) : -5614), 
			((iStatsBit & RecordStats_TotalJumps) ? SQL_FetchInt(hResult, 15) : -5614), 
			((iStatsBit & RecordStats_RoundsPlayed) ? SQL_FetchInt(hResult, 16) : -5614));
		
		LogMessage("QUERY BEFORE REPLACE: %s", g_szQuery);
		ReplaceString(g_szQuery, sizeof g_szQuery, "-5614", "NULL", false);
		
		SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0, _, "SQL-> Insert Stats", g_szQuery);
	}
	
	delete hResult;
	SQL_UnlockDatabase(g_hSqliteStats);
}

void ResetMatchStuff(bool bNewMatch)
{
	if (!CheckMatchId(MATCHID_NO_MATCH))
	{
		DropTable();
	}
	
	if (!bNewMatch)
	{
		SetMatchState(Match_Waiting);
		SetMatchId(MATCHID_NO_MATCH);
	}
	
	g_iReadyCount = 0;
	g_iRestarts = 0;
	g_bRestarting = false;
	g_iNumRestarts = 0;
	g_bHalfTimeReached = false;
	
	//g_iWinnerTeam = TEAM_NONE;
	//g_iMatchEndCode = MatchEndCode_None;
}

/*
public void OnMapStart()
{
	PrintDebug("MapStart Called");
	ResetMatchStuff();
}*/

public void OnConfigsExecuted()
{
	//ExecuteConfig(g_szWarmUpConfig);
}

// ----------------------------------------
// 		Events
// ----------------------------------------
public void Event_WeaponFire(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if (gMatchState != Match_Running)
	{
		return;
	}
	
	int client = (GetClientOfUserId(GetEventInt(event, "userid")));
	//PrintToChatAll("WeaponFired");
	g_iTotalShots[client]++;
}

public void Event_PlayerTeam(Event event, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (gPlayerState[client] != PlayerState_Player)
	{
		return;
	}
	
	if (CheckMatchState(Match_FirstReadyPhase) || CheckMatchState(Match_SecondReadyPhase))
	{
		ChangeToReadyClanTag(client);
	}
}

public Action Event_PlayerChangeName(Event event, const char[] szEventName, bool bDontBroadcast)
{
	PrintDebug("Called Name Change");
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] szEventName, bool bDontBroadcast)
{
	PrintDebug("Round Start");
	
	PrintDebug("Restarting %d, iRestart : %d %d", g_bRestarting, g_iRestarts + 1, g_iNumRestarts);
	PrintDebug("gMatchState = %d", gMatchState);
	
	for (int i = 1, j; i <= MaxClients; i++)
	{
		g_iKiller[i] = 0;
		
		for (j = 1; j <= MaxClients; j++)
		{
			g_flDamage[i][j] = 0.0;
			g_iHits[i][j] = 0;
		}
	}
	
	if (g_bRestarting)
	{
		PrintDebug("Restarting, iRestart : %d %d", g_iRestarts + 1, g_iNumRestarts);
		if (++g_iRestarts < g_iNumRestarts)
		{
			//SetConVarInt(ConVar_RestartGame, 1);
			
			int iDelay = ReadPackCell(g_hRestartsPack);
			ServerCommand("mp_restartgame %d", iDelay);
		}
		
		else if (g_iRestarts >= g_iNumRestarts)
		{
			RestartsDone();
		}
		
		return;
	}
	
	if (CheckMatchState(Match_Running))
	{
		int iCTScore = GetTeamScore(CS_TEAM_CT), iTScore = GetTeamScore(CS_TEAM_T);
		if (iCTScore == iTScore)
		{
			//PrintToChatAll(" %d", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Score is tied: %d-%d", iCTScore, iTScore);
		}
		
		else if (iCTScore > iTScore)
		{
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "The Counter-Terrorists team is winning: %d-%d", iCTScore, iTScore);
		}
		
		else
		{
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "The Terrorists team is winning: %d-%d", iTScore, iCTScore);
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			// Do is valid player;
			if (IsClientInGame(i))
			{
				g_iRoundsPlayed[i]++;
			}
		}
	}
	
	else if (CheckMatchState(Match_TeamChoose))
	{
		int client;
		
		PrintDebug("Done1");
		// Do show menu to other player if no player is in game.
		while ((client = GetRandomClient(g_iChoosingTeamIndex)) > 0)
		{
			break;
		}
		
		PrintDebug("Done2 %d", client);
		
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Player %N will be choosing the starting team for team %s", client, g_szTeamNames[g_iTeamIndex[client]]);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Choose the starting team");
		
		PrintDebug("Done3");
		
		Menu hMenu = CreateMenu(MenuHandler_TeamChoose, MENU_ACTIONS_DEFAULT);
		char szInfo[3];
		
		PrintDebug("Done4");
		
		IntToString(CS_TEAM_T, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Terrorists");
		
		IntToString(CS_TEAM_CT, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Counter-Terrorists");
		
		IntToString(CS_TEAM_SPECTATOR, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Random");
		
		hMenu.ExitBackButton = false;
		
		PrintDebug("Done5");
		
		hMenu.Display(client, MENU_TIME_FOREVER);
		
		PrintDebug("---- MENU DISPLAYED");
	}
}

public void Event_RoundEnd(Event event, const char[] szEventName, bool bDontBroadcast)
{
	// Do compatibility for hostage maps
	if (CheckMatchState(Match_KnifeRound))
	{
		PrintDebug("MatchState Knife Roun #1d");
		
		PrintDamageReportAll(true);
		
		CSRoundEndReason iEndReason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
		int iWinningTeam = GetEventInt(event, "winner");
		
		PrintDebug("RoundEnd End Reason = %d", iEndReason);
		
		// Do this efficiently
		if (iEndReason == CSRoundEnd_TerroristWin || iEndReason == CSRoundEnd_CTWin || iEndReason == CSRoundEnd_Draw)
		{
			PrintDebug("End Reason Valid");
			int iOtherTeam = (iWinningTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T);
			
			bool bEliminated = true;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
				{
					continue;
				}
				
				if (GetClientTeam(i) == iOtherTeam)
				{
					if (IsPlayerAlive(i))
					{
						PrintDebug("%N not eliminated", i);
						bEliminated = false;
						break;
					}
				}
			}
			
			if (bEliminated)
			{
				g_iChoosingTeamIndex = iWinningTeam == gTeams[TeamIndex_First][TeamInfo_CurrentTeam] ? TeamIndex_First : TeamIndex_Second;
				SetMatchState(Match_TeamChoose);
				
				PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "The %s team won the knife round. They will be choosing the starting team.", iWinningTeam == CS_TEAM_CT ? "Counter-Terrorists" : "Terrorist");
			}
		}
		
		return;
	}
	
	if (CheckMatchState(Match_Running))
	{
		PrintDamageReportAll(true);
		
		for (int i = 1, iKills; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || gPlayerState[i] != PlayerState_Player)
			{
				continue;
			}
			
			iKills = g_iKillsThisRound[i];
			g_iKillsThisRound[i] = 0;
			switch (iKills)
			{
				case 1:continue;
				case 2:g_i2Kills[i]++;
				case 3:g_i3Kills[i]++;
				case 4:g_i4Kills[i]++;
				case 5:g_iAces[i]++;
			}
		}
		
		CheckMatchEnd();
	}
}

void CheckMatchEnd()
{
	ConVar ConVar_MaxRounds = CreateConVar("mp_maxrounds", "");
	//ConVar ConVar_OverTime_Enabled = CreateConVar("mp_overtime_enabled", "");
	//ConVar ConVar_OverTime_MaxRounds = CreateConVar("mp_overtime_maxrounds", "");
	
	int iMaxRounds = GetConVarInt(ConVar_MaxRounds);
	int iHalfMaxRounds = iMaxRounds / 2;
	
	//bool bOverTime_Enabled = GetConVarBool(ConVar_OverTime_Enabled);
	//int iOverTimeMaxRounds = GetConVarInt(ConVar_OverTime_MaxRounds);
	//int iOverTimeHalfMaxRounds = iOverTimeMaxRounds / 2;
	
	int iCTScore = GetTeamScore(CS_TEAM_CT), iTScore = GetTeamScore(CS_TEAM_T);
	
	PrintDebug("Scores CT : %d T %d", iCTScore, iTScore);
	
	if (!g_bHalfTimeReached && (iCTScore + iTScore) == iHalfMaxRounds)
	{
		g_bHalfTimeReached = true;
		
		gTeams[TeamIndex_First][TeamInfo_CurrentTeam] = gTeams[TeamIndex_First][TeamInfo_CurrentTeam] == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
		gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] = gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
		
		FixTeamNames();
		
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "--- Half Time ---");
	}
	
	if (iCTScore > iHalfMaxRounds || iTScore > iHalfMaxRounds || (iCTScore == iHalfMaxRounds && iTScore == iHalfMaxRounds))
	{
		//if(!bOverTime_Enabled)
		//{
		PrintDebug("The Match Has Ended!");
		
		int iWinner = iCTScore > iTScore ? CS_TEAM_CT : ((iTScore > iCTScore) ? CS_TEAM_T : CS_TEAM_NONE);
		
		TeamsIndexes iWinnerTeamIndex = TeamIndex_None;
		if (iWinner != CS_TEAM_NONE)
		{
			iWinnerTeamIndex = gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == iWinner ? TeamIndex_Second : TeamIndex_Second;
		}
		
		MatchEndStuff(true, g_iStatsRecorded, MatchEndCode_End, iWinnerTeamIndex);
		//}
		
		//else
		//{
		
		//}
	}
}

public Action Timer_KickAll(Handle hTimer, any szReason)
{
	//KickAllClients(KICK_MESSAGE_NOT_ALLOWED);
	
	if (g_iKickTime <= 0)
	{
		KickAllClients(KICK_MESSAGE_MATCH_ENDED);
		return;
	}
	
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Kicking everyone in \x05%d \x01seconds", g_iKickTime--);
}

void KickAllClients(const char[] szReason)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		KickClient_Custom(i, szReason);
	}
}

public void Event_PlayerDeath(Event event, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int iKiller = GetClientOfUserId(GetEventInt(event, "attacker"));
	g_iKiller[client] = iKiller;
	
	if (!(0 < client <= MaxClients))
	{
		return;
	}
	
	// Damage report stuff.
	PrintDamageReport(client);
	
	// Stats Stuff
	if (CheckMatchState(Match_Running))
	{
		g_iDeaths[client]++;
		
		if (IsValidPlayer(iKiller) && gPlayerState[iKiller] == PlayerState_Player)
		{
			// Avoid calculating team kills as +1;
			if (GetClientTeam(iKiller) != GetClientTeam(client))
			{
				g_iKills[iKiller]++;
				PrintDebug("Added kill to %N", iKiller);
				
				g_iKillsThisRound[iKiller]++;
			}
			
			if (GetEventBool(event, "headshot"))
			{
				g_iHeadshots[iKiller]++;
			}
		}
		
		int iAssister = GetClientOfUserId(GetEventInt(event, "assister"));
		if (IsValidPlayer(iAssister) && gPlayerState[iAssister] == PlayerState_Player)
		{
			g_iAssists[iAssister]++;
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (CheckMatchState(Match_KnifeRound))
	{
		CS_RemoveWeapons(client, false, g_bKnifeRound_DisarmC4);
	}
	
	else if (CheckMatchState(Match_FirstReadyPhase) || CheckMatchState(Match_SecondReadyPhase))
	{
		ChangeToReadyClanTag(client);
	}
}

public void Event_BombPlanted(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if (CheckMatchState(Match_Running))
	{
		int client = (GetClientOfUserId(GetEventInt(event, "userid")));
		g_iBombPlants[client]++;
	}
}

public void Event_BombDefused(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if (CheckMatchState(Match_Running))
	{
		int client = (GetClientOfUserId(GetEventInt(event, "userid")));
		g_iBombDefuses[client]++;
	}
}

public void Event_PlayerMVP(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if (CheckMatchState(Match_Running))
	{
		int client = (GetClientOfUserId(GetEventInt(event, "userid")));
		g_iTotalMVPs[client]++;
	}
}
public void Event_PlayerJump(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if (CheckMatchState(Match_Running))
	{
		int client = (GetClientOfUserId(GetEventInt(event, "userid")));
		g_iTotalJumps[client]++;
	}
}
// ----------------------------------------
// 		Forwards
// ----------------------------------------
public void OnClientAuthorized(int client, const char[] szAuth)
{
	g_iTeamIndex[client] = TeamIndex_None;
	g_bReady[client] = false;
	gPlayerState[client] = PlayerState_None;
	
	CheckIfClientIsAllowed(client);
}

public void OnClientPutInServer(client)
{
	Hooks(client, true);
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (CheckMatchState(Match_FirstReadyPhase) || CheckMatchState(Match_SecondReadyPhase))
	{
		CS_GetClientClanTag(client, g_szOriginalClanTag[client], sizeof g_szOriginalClanTag[]);
		ChangeToReadyClanTag(client);
	}
}

public void OnClientDisconnect(client)
{
	Hooks(client, false);
	
	if (CheckMatchState(Match_Waiting))
	{
		gPlayerState[client] = PlayerState_None;
		g_bReady[client] = false;
		g_iTeamIndex[client] = TeamIndex_None;
		
		return;
	}
	
	#if defined ALLOW_OUTSIDE_CLIENTS
	#if defined ALLOW_ADMINS
	if (gPlayerState[client] == PlayerState_Admin)
	{
		g_iOutsideClients--;
		gPlayerState[client] = PlayerState_None;
		return;
	}
	#endif
	
	#if defined ALLOW_SPECS
	if (gPlayerState[client] == PlayerState_Spec)
	{
		g_iOutsideClients--;
		gPlayerState[client] = PlayerState_None;
		return;
	}
	#endif
	#endif
	
	if (gPlayerState[client] == PlayerState_Player)
	{
		UpdateClientLocalStats(client);
		
		Call_StartForward(g_hForward_MatchPlayer_Disconnect);
		Call_PushCell(client);
		Call_Finish();
		
		if (CheckMatchState(Match_Running))
		{
			AddPlayerToDisconnectTable(client);
		}
	}
	
	gPlayerState[client] = PlayerState_None;
	g_iTeamIndex[client] = TeamIndex_None;
	
	if (g_bReady[client])
	{
		g_iReadyCount--;
		g_bReady[client] = false;
	}
}

enum
{
	DisconnectData_MatchId, 
	DisconnectData_PlayerName, 
	DisconnectData_AuthId, 
	DisconnectData_DisconnectTime, 
	DisconnectData_BanAfterTimeStamp, 
	
	DisconnectData_Total
}

new const String:g_szDisconnectDataTableName[] = "disconnect_data";
new const String:g_szDisconnectDataTableFields[DisconnectData_Total][] =  {
	"matchid", 
	"name", 
	"authid", 
	"disconnect_timestamp", 
	"ban_after"
}

void AddPlayerToDisconnectTable(int client)
{
	char szAuthId[35]; GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	char szName[MAX_NAME_LENGTH]; GetClientName(client, szName, sizeof szName)
	
	Handle hQuery = SQL_ExecuteQuery(g_hSqlite, g_szError, sizeof g_szError, "Add to disconnect Table #1", 
		"SELECT * FROM `%s` WHERE `%s` = '%s' AND `%s` = %d", g_szDisconnectDataTableName, g_szDisconnectDataTableFields[DisconnectData_AuthId], 
		szAuthId, g_szDisconnectDataTableFields[DisconnectData_MatchId], g_iMatchId);
	
	if (hQuery == INVALID_HANDLE)
	{
		return;
	}
	
	delete hQuery;
	if (SQL_GetRowCount(hQuery) > 1)
	{
		hQuery = SQL_ExecuteQuery(g_hSqlite, g_szError, sizeof g_szError, "Add to disconnect Table #2", 
			"UPDATE `%s` SET `%s` = CURRENT_TIMESTAMP, `%s` = CURRENT_TIMESTAMP() + (%d) WHERE `%s` = '%s' AND `%s` = %d", 
			g_szDisconnectDataTableName, BAN_AFTER_TIME, g_szDisconnectDataTableFields[DisconnectData_DisconnectTime], szAuthId, 
			g_szDisconnectDataTableFields[DisconnectData_MatchId], g_iMatchId);
		
		delete hQuery;
		
		return;
	}
	
	hQuery = SQL_ExecuteQuery(g_hSqlite, g_szError, sizeof g_szError, "Add to disconnect Table #3", 
		"INSERT INTO `%s` (`%s`, `%s`, `%s`, `%s`, `%s`) VALUES ( %d, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + (%d), '%s', '%s')", 
		g_szDisconnectDataTableName, g_szDisconnectDataTableFields[DisconnectData_MatchId, g_szDisconnectDataTableFields[DisconnectData_DisconnectTime], 
		g_szDisconnectDataTableFields[DisconnectData_BanAfterTimeStamp], g_szDisconnectDataTableFields[DisconnectData_AuthId], g_szDisconnectDataTableFields[DisconnectData_PlayerName], 
		gMatchId, BAN_AFTER_TIME, szAuthId, szName)
	delete hQuery;
}

public Action Timer_CheckDisconnectDataTable(Handle hTimer, any data)
{
	Handle hQuery = SQL_ExecuteQuery(g_hSqlite, g_SzError, sizeof szError, "Check Disconnect Data", 
		"SELECT (`%s`, `%s`) FROM `%s` WHERE `%s` = %d AND `%s` < CURRENT_TIMESTAMP", 
		g_szDisconnectDataTableFields[DisconnectData_AuthId], g_szDisconnectDataTableFields[DisconnectData_PlayerName], 
		g_szDisconnectDataTableName, , g_MatchId, g_szDisconnectDataFields[DisconnectData_BanAfterTimeStamp]);
	
	if (hQuery == INVALID_HANDLE)
	{
		return;
	}
	
	char szAuthId[35], szName[MAX_NAME_LENGTH];
	while (SQL_FetchRow(hQuery))
	{
		SQL_FetchString(hQuery, 0, szAuthId, sizeof szAuthId);
		SQL_FetchString(hQuery, 1, szName, sizeof szName);
		
		delete SQL_ExecuteQuery(g_hSqlite, g_szError, sizeof g_szError, "Delete from disconnect data", 
			"DELETE FROM `%s` WHERE `%s` = %d AND `%s` = '%s'", g_szDisconnectDataTableName, g_szDisconnectDataFields[DisconnectData_MatchId], gMatchId, 
			g_szDisconnectDataTableFields[DisconnectData_AuthId], szAuthId);
		
		BanAuthId(szAuthId, BanReasonCode_Abandon, BanSubCode_Abandon_Disconnect, szName);
	}
	
	delete hQuery;
}

void BanAuthId(const char[] szAuthId, const int iCode, int iSubCode, int iCustomTime = -1, char[] szName = "")
{
	DataPack hData;
	
	/*
	SELECT ban_steps.ban_code, ban_steps.ban_step, ban_steps.ban_time FROM ban_steps 
					JOIN player_bans_steps	ON ban_steps.ban_code = player_bans_steps.ban_code 
											AND ( ban_steps.ban_step = player_bans_steps.ban_step
                                            OR  ban_steps.ban_step = player_bans_steps.ban_step + 1)
	WHERE player_bans_steps.steam = 'STEAM' ORDER BY `ban_code`, `ban_step` DESC;
*/
	g_szPlayersBanDataTableName.g_szPlayersBanTableFields[PlayerBanField_AuthId]
	g_szBanStepsTableName.g_szBanStepsTableFields[BanStepsTableField_
	
	SQL_TQuery_Custom(g_hSql, SQLCallback_GetBanSteps, hData, _, "Get Ban Data", 
		"SELECT `%s`, `%s`,`%s`,`%s` FROM `%s`\
				JOIN `%s` ON `%s`.`%s` = `%s`.`%s` \
				AND ( `%s`.`%s` = `%s`.`%s` OR `%s`.`%s` = `%s`.`%s` + 1)\
		WHERE `%s`.`%s` = '%s' ORDER BY `%s`, `%s` DESC", );
}

public void SQLCallback_GetBanSteps(Handle hSql, Handle hResult, char[] szError,
// ----------------------------------------
// 		Callbacks
// ----------------------------------------
public Action ClCmd_Say(int client, const char[] szCommand, int iArgCount)
{
	if (!gPlayerState[client])
	{
		return;
	}
	
	char szCmdArg[12];
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	if (StrEqual(szCmdArg, ".ready", false))
	{
		if (gMatchState != Match_FirstReadyPhase && gMatchState != Match_SecondReadyPhase)
		{
			return;
		}
		
		if (g_bReady[client])
		{
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have already declared yourself as ready");
			return;
		}
		
		g_bReady[client] = true;
		g_iReadyCount++;
		
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "%N is now ready", client);
		
		PrintDebug("g_iReadyCount %d .. g_iMatchPlayersCount %d", g_iReadyCount, g_iMatchPlayersCount);
		
		CheckStart();
		//PrintToChat(client, "* You are now ready");
	}
}

public Action ClCmd_JoinTeam(int client, const char[] szCommand, int iArgCount)
{
	if (gPlayerState[client] == PlayerState_Bot)
	{
		return Plugin_Continue;
	}
	
	char szCmdArg[6]; GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	int iJoinTeam = StringToInt(szCmdArg);
	int iTeam = GetClientTeam(client);
	
	PrintDebug("iJoinTeam = %d - iTeam %d", iJoinTeam, iTeam);
	
	if (gPlayerState[client] != PlayerState_Player)
	{
		if (iJoinTeam == CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You do not have premission to join a team except Spectators.");
		return Plugin_Handled;
	}
	
	// Is a match player ->>
	if (CheckMatchState(Match_FirstReadyPhase) || CheckMatchState(Match_SecondReadyPhase))
	{
		if (iJoinTeam != CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	// Any other match state
	if (iJoinTeam == iTeam)
	{
		return Plugin_Continue;
	}
	
	if (iTeam == 0 && iJoinTeam == gTeams[g_iTeamIndex[client]][TeamInfo_CurrentTeam])
	{
		return Plugin_Continue;
	}
	
	// Disable Changing teams.
	return Plugin_Handled;
}

// ----------------------------------------
// 		SQL Callbacks
// ----------------------------------------
public void SQLCallback_CheckClient(Handle hSQL, Handle hResultSet, char[] szError, int client)
{
	if (!IsClientConnected(client))
	{
		return;
	}
	
	if (CheckError(szError))
	{
		LogError("SQL Callback Error (CheckClient): %s", szError);
		return;
	}
	
	if (!SQL_GetRowCount(hResultSet))
	{
		#if defined ALLOW_OUTSIDE_CLIENTS
		#if defined ALLOW_ADMINS
		if (GetUserAdmin(client))
		{
			if (g_iOutsideClients < MAX_OUTSIDE_CLIENTS)
			{
				g_iOutsideClients++;
				gPlayerState[client] = PlayerState_Admin;
				
				PrintDebug("Player %N is an admin", client);
				return;
			}
			
			KickClient_Custom(client, KICK_MESSAGE_OUTSIDE_CLIENTS_EXCEEDED);
			return;
		}
		#endif
		
		#if defined ALLOW_SPECS
		// Do support for specs later
		if (IsSpec(client))
		{
			gPlayerState[client] = PlayerState_Spectator;
			return;
		}
		#endif
		
		#endif
		KickClient_Custom(client, KICK_MESSAGE_NOT_ALLOWED); // OnClientdisconnet Stuff will happen later
		return;
	}
	
	gPlayerState[client] = PlayerState_Player;
	
	SQL_FetchRow(hResultSet);
	//g_iTeam[client] = SQL_FetchInt(hResultSet, 0);
	g_iTeamIndex[client] = GetTeamIndexFromTeamId(SQL_FetchInt(hResultSet, 0));
	
	GetClientLocalStats(client);
	
	Call_StartForward(g_hForward_MatchPlayer_Joined);
	Call_PushCell(client);
	Call_Finish();
}

TeamsIndexes GetTeamIndexFromTeamId(int iTeamId)
{
	if (iTeamId == gTeams[TeamIndex_First][TeamInfo_TeamId])
	{
		return TeamIndex_First;
	}
	
	return TeamIndex_Second;
}

bool CreateSQLiteTable()
{
	//if(StrEqual(g_szMatchId, MATCHID_NO_MATCH))
	if (CheckMatchId(MATCHID_NO_MATCH))
	{
		//DropTable();
		return false;
	}
	
	SQL_TQuery_Custom(g_hSqliteStats, SQLiteCallback_CreateTable, 0, _, "Create Table", "CREATE TABLE IF NOT EXISTS `%s%d` (\
	`%s`	TEXT NOT NULL UNIQUE,\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0),\
	`%s`	INTEGER DEFAULT (0));", 
		g_szSqliteTablePrefix, gMatchId, 
		g_szStatsTableFields[Stats_AuthId], 
		g_szStatsTableFields[Stats_Kills], 
		g_szStatsTableFields[Stats_Headshots], 
		g_szStatsTableFields[Stats_Deaths], 
		g_szStatsTableFields[Stats_Assists], 
		g_szStatsTableFields[Stats_BombPlants], 
		g_szStatsTableFields[Stats_BombDefuses], 
		g_szStatsTableFields[Stats_2Kills], 
		g_szStatsTableFields[Stats_3Kills], 
		g_szStatsTableFields[Stats_4Kills], 
		g_szStatsTableFields[Stats_Aces], 
		g_szStatsTableFields[Stats_TotalShots], 
		g_szStatsTableFields[Stats_TotalHits], 
		g_szStatsTableFields[Stats_TotalDamage], 
		g_szStatsTableFields[Stats_TotalMVPs], 
		g_szStatsTableFields[Stats_TotalJumps], 
		g_szStatsTableFields[Stats_RoundsPlayed]
		);
	
	return true;
}

public void SQLiteCallback_CreateTable(Handle hHandle, Handle hResults, char[] szError, any data)
{
	if (CheckError(szError))
	{
		LogMessage("Error: %s", szError);
		SetFailState("Failed to create the table match_%d", gMatchId);
		return;
	}
	
	/*
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			GetClientLocalStats(i);
		}
	}*/
}

void GetClientLocalStats(client)
{
	char szAuthId[35]; GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	SQL_TQuery_Custom(g_hSqliteStats, SQLiteCallback_GetLocalStats, client, _, "SQLite Select Query:", 
		"SELECT `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s` FROM `%s%d` WHERE `%s` = '%s'", 
		g_szStatsTableFields[Stats_Kills], 
		g_szStatsTableFields[Stats_Headshots], 
		g_szStatsTableFields[Stats_Deaths], 
		g_szStatsTableFields[Stats_Assists], 
		g_szStatsTableFields[Stats_BombPlants], 
		g_szStatsTableFields[Stats_BombDefuses], 
		g_szStatsTableFields[Stats_2Kills], 
		g_szStatsTableFields[Stats_3Kills], 
		g_szStatsTableFields[Stats_4Kills], 
		g_szStatsTableFields[Stats_Aces], 
		g_szStatsTableFields[Stats_TotalShots], 
		g_szStatsTableFields[Stats_TotalHits], 
		g_szStatsTableFields[Stats_TotalDamage], 
		g_szStatsTableFields[Stats_TotalMVPs], 
		g_szStatsTableFields[Stats_TotalJumps], 
		g_szStatsTableFields[Stats_RoundsPlayed], 
		
		g_szSqliteTablePrefix, gMatchId, 
		g_szStatsTableFields[Stats_AuthId], 
		szAuthId);
}

public void SQLiteCallback_GetLocalStats(Handle hHndl, Handle hResult, char[] szError, int client)
{
	if (szError[0])
	{
		LogMessage("Error in GetStats: %s", szError);
		return;
	}
	
	if (!SQL_GetRowCount(hResult))
	{
		if (IsClientAuthorized(client))
		{
			AddClientToLocalStatsTable(client);
		}
		
		ResetStats(client);
		return;
	}
	
	SQL_FetchRow(hResult);
	
	/*
	g_szStatsTableFields[Stats_Kills],
	g_szStatsTableFields[Stats_Headshots],
	g_szStatsTableFields[Stats_Deaths],
	g_szStatsTableFields[Stats_Assists],
	
	g_szStatsTableFields[Stats_BombPlants],
	g_szStatsTableFields[Stats_BombDefuses],
	
	g_szStatsTableFields[Stats_2K],
	g_szStatsTableFields[Stats_3K],
	g_szStatsTableFields[Stats_4K],
	g_szStatsTableFields[Stats_Ace],
	
	g_szStatsTableFields[Stats_TotalShots],
	g_szStatsTableFields[Stats_TotalHits],
	g_szStatsTableFields[Stats_TotalDamage],
	
	g_szStatsTableFields[Stats_MVP],
	g_szStatsTableFields[Stats_RoundsPlayed],
	*/
	
	g_iKills[client] = SQL_FetchInt(hResult, 0);
	g_iHeadshots[client] = SQL_FetchInt(hResult, 1);
	g_iDeaths[client] = SQL_FetchInt(hResult, 2);
	g_iAssists[client] = SQL_FetchInt(hResult, 3);
	
	g_iBombPlants[client] = SQL_FetchInt(hResult, 4);
	g_iBombDefuses[client] = SQL_FetchInt(hResult, 5);
	
	g_i2Kills[client] = SQL_FetchInt(hResult, 6);
	g_i3Kills[client] = SQL_FetchInt(hResult, 7);
	g_i4Kills[client] = SQL_FetchInt(hResult, 8);
	g_iAces[client] = SQL_FetchInt(hResult, 9);
	
	g_iTotalShots[client] = SQL_FetchInt(hResult, 10);
	g_iTotalHits[client] = SQL_FetchInt(hResult, 11);
	g_flTotalDamage[client] = float(SQL_FetchInt(hResult, 12));
	
	g_iTotalMVPs[client] = SQL_FetchInt(hResult, 13);
	g_iTotalJumps[client] = SQL_FetchInt(hResult, 14);
	
	g_iRoundsPlayed[client] = SQL_FetchInt(hResult, 15);
}

void AddClientToLocalStatsTable(int client)
{
	char szAuthId[35]; GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	SQL_TQuery_Custom(g_hSqliteStats, SQLiteCallback_Dump, 0, _, "Insert Query:", "INSERT INTO `%s%d` (`%s`) VALUES ( '%s' );", g_szSqliteTablePrefix, gMatchId, g_szStatsTableFields[Stats_AuthId], szAuthId);
}

void ResetStats(client)
{
	g_iKillsThisRound[client] = 0;
	g_iKills[client] = 0;
	g_iHeadshots[client] = 0;
	g_iDeaths[client] = 0;
	g_iAssists[client] = 0;
	
	g_iBombPlants[client] = 0;
	g_iBombDefuses[client] = 0;
	g_i2Kills[client] = 0;
	g_i3Kills[client] = 0;
	g_i4Kills[client] = 0;
	g_iAces[client] = 0;
	
	g_iTotalShots[client] = 0;
	g_iTotalHits[client] = 0;
	g_flTotalDamage[client] = 0.0;
	
	g_iTotalMVPs[client] = 0;
	g_iTotalJumps[client] = 0;
	
	g_iRoundsPlayed[client] = 0;
}

void UpdateAllLocalStats()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && gPlayerState[i] == PlayerState_Player)
		{
			UpdateClientLocalStats(i);
		}
	}
}

void UpdateClientLocalStats(client)
{
	SQL_LockDatabase(g_hSqliteStats);
	
	char szAuthId[35];
	GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	//char szQuery[512];
	int iLen;
	
	iLen += FormatEx(g_szQuery[iLen], sizeof(g_szQuery) - iLen, "UPDATE `%s%d` SET `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, ", 
		g_szSqliteTablePrefix, gMatchId, 
		g_szStatsTableFields[Stats_Kills], g_iKills[client], 
		g_szStatsTableFields[Stats_Headshots], g_iHeadshots[client], 
		g_szStatsTableFields[Stats_Deaths], g_iDeaths[client], 
		g_szStatsTableFields[Stats_Assists], g_iAssists[client]);
	
	iLen += FormatEx(g_szQuery[iLen], sizeof(g_szQuery) - iLen, "`%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, ", 
		g_szStatsTableFields[Stats_BombPlants], g_iBombPlants[client], 
		g_szStatsTableFields[Stats_BombDefuses], g_iBombDefuses[client], 
		g_szStatsTableFields[Stats_2Kills], g_i2Kills[client], 
		g_szStatsTableFields[Stats_3Kills], g_i3Kills[client], 
		g_szStatsTableFields[Stats_4Kills], g_i4Kills[client], 
		g_szStatsTableFields[Stats_Aces], g_iAces[client]);
	
	iLen += FormatEx(g_szQuery[iLen], sizeof(g_szQuery) - iLen, "`%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d WHERE `%s` = '%s';", 
		g_szStatsTableFields[Stats_TotalShots], g_iTotalShots[client], 
		g_szStatsTableFields[Stats_TotalHits], g_iTotalHits[client], 
		g_szStatsTableFields[Stats_TotalDamage], RoundFloat(g_flTotalDamage[client]), 
		g_szStatsTableFields[Stats_TotalMVPs], g_iTotalMVPs[client], 
		g_szStatsTableFields[Stats_TotalJumps], g_iTotalJumps[client], 
		g_szStatsTableFields[Stats_RoundsPlayed], g_iRoundsPlayed[client], 
		g_szStatsTableFields[Stats_AuthId], szAuthId);
	
	//SQL_TQuery_Custom(g_hSqliteStats, SQLCallback_Dump, 0,_, "SQLite Update Query", szQuery);
	//char szError[512];
	delete SQL_ExecuteQuery(g_hSqliteStats, g_szError, sizeof g_szError, "SQLite Update Query", g_szQuery);
	
	if (g_szError[0])
	{
		LogError("ERROR: %s");
	}
	
	SQL_UnlockDatabase(g_hSqliteStats);
}

public void SQLCallback_Dump(Handle hSql, Handle hResult, char[] szError, any data)
{
	if (CheckError(szError))
	{
		LogError("SQL DUMP ERROR: %s", szError);
		return;
	}
}

public void SQLiteCallback_Dump(Handle hSql, Handle hResult, char[] szError, any data)
{
	if (CheckError(szError))
	{
		LogError("SQLite DUMP ERROR: %s", szError);
		return;
	}
}

// ----------------------------------------
// 		SDK Hooks
// ----------------------------------------
public Action SDKCallback_WeaponSwitch(int client, int iWeapon)
{
	if (CheckMatchState(Match_KnifeRound))
	{
		char szWeaponName[35];
		GetEntityClassname(iWeapon, szWeaponName, sizeof szWeaponName);
		
		if (!StrEqual(szWeaponName, "weapon_knife"))
		{
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action SDKCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Damage Report
	g_flDamage[attacker][victim] += damage;
	g_iHits[attacker][victim]++;
	
	// Stats
	if (IsValidPlayer(attacker))
	{
		g_flTotalDamage[attacker] += damage;
		g_iTotalHits[attacker]++;
	}
}

// ----------------------------------------
// 		Menu Handlers
// ----------------------------------------
public int MenuHandler_TeamChoose(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			if (param1 == MenuEnd_Selected)
			{
				delete menu;
			}
		}
		
		case MenuAction_Select:
		{
			int iTeamSelection;
			char szDump[3];
			
			menu.GetItem(param2, szDump, sizeof szDump);
			iTeamSelection = StringToInt(szDump);
			
			if (iTeamSelection == CS_TEAM_SPECTATOR)
			{
				iTeamSelection = GetRandomInt(0, 1) ? CS_TEAM_CT : CS_TEAM_T;
			}
			
			int iOtherTeam = iTeamSelection == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
			TeamsIndexes iOtherIndex = g_iChoosingTeamIndex == TeamIndex_First ? TeamIndex_Second : TeamIndex_First;
			
			gTeams[g_iChoosingTeamIndex][TeamInfo_CurrentTeam] = iTeamSelection;
			gTeams[iOtherIndex][TeamInfo_CurrentTeam] = iOtherTeam;
			
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Team %s chose %s", 
				g_szTeamNames[g_iChoosingTeamIndex], iTeamSelection == CS_TEAM_T ? "Terrorist" : "Counter-Terrorists");
			
			FixTeamNames();
			SetMatchState(Match_SecondReadyPhase);
		}
		
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_Disconnected:
				{
					// Do if no other play is connected.
					int client = GetRandomClient(g_iChoosingTeamIndex);
					while ((client = GetRandomClient(g_iChoosingTeamIndex)))
					{
						break;
					}
					
					menu.Display(client, MENU_TIME_FOREVER);
				}
				
				default:
				{
					menu.Display(param1, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

void FixTeamNames()
{
	if (!g_szTeamNames[TeamIndex_First][0] || 
		StrEqual(g_szTeamNames[TeamIndex_First], TEAM_NAME_CT) || 
		StrEqual(g_szTeamNames[TeamIndex_First], TEAM_NAME_T))
	{
		strcopy(g_szTeamNames[TeamIndex_First], sizeof(g_szTeamNames[]), 
			gTeams[TeamIndex_First][TeamInfo_CurrentTeam] == CS_TEAM_CT ? TEAM_NAME_CT : TEAM_NAME_T);
	}
	
	if (!g_szTeamNames[TeamIndex_Second][0] || 
		StrEqual(g_szTeamNames[TeamIndex_Second], TEAM_NAME_CT) || 
		StrEqual(g_szTeamNames[TeamIndex_Second], TEAM_NAME_T))
	{
		strcopy(g_szTeamNames[TeamIndex_Second], sizeof(g_szTeamNames[]), 
			gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == CS_TEAM_CT ? TEAM_NAME_CT : TEAM_NAME_T);
	}
	
	ServerCommand("mp_teamname_%d \"%s\"", gTeams[TeamIndex_First][TeamInfo_CurrentTeam] == CS_TEAM_CT ? 1 : 2, g_szTeamNames[TeamIndex_First]);
	ServerCommand("mp_teamname_%d \"%s\"", gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == CS_TEAM_CT ? 1 : 2, g_szTeamNames[TeamIndex_Second]);
}

// ----------------------------------------
// 		Cvars
// ----------------------------------------
public void ConVarHook_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == ConVar_ServerAddress)
	{
		convar.GetString(g_szServerAddress, sizeof(g_szServerAddress));
		
		if (!g_szServerAddress[0])
		{
			GetClientIP(0, g_szServerAddress, sizeof g_szServerAddress, true);
		}
	}
	
	else if (convar == ConVar_KnifeRound_Enabled)
	{
		g_bKnifeRound_Enabled = convar.BoolValue;
	}
	
	else if (convar == ConVar_KnifeRound_DisarmC4)
	{
		g_bKnifeRound_DisarmC4 = convar.BoolValue;
	}
}

// ----------------------------------------
// 		Stocks, Custom functions, etc
// ----------------------------------------
void Hooks(int client, bool bOn)
{
	switch (bOn)
	{
		case true:
		{
			SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_WeaponCanUse, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_WeaponEquip, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
		}
		
		case false:
		{
			SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponCanUse, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponEquip, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
		}
	}
}

void ChangeToReadyClanTag(int client = 0)
{
	switch (client)
	{
		case 0:
		{
			for (client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client) || gPlayerState[client] != PlayerState_Player)
				{
					continue;
				}
				
				CS_SetClientClanTag(client, g_bReady[client] ? "[READY]" : "[NOT READY]");
			}
		}
		
		default:
		{
			CS_SetClientClanTag(client, g_bReady[client] ? "[READY]" : "[NOT READY]");
		}
	}
}

void ChangeToOriginalClanTag(int client = 0)
{
	switch (client)
	{
		case 0:
		{
			for (client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client) || gPlayerState[client] != PlayerState_Player)
				{
					continue;
				}
				
				CS_SetClientClanTag(client, g_szOriginalClanTag[client]);
			}
		}
		
		default:
		{
			CS_SetClientClanTag(client, g_szOriginalClanTag[client]);
		}
	}
}

void StartMatch()
{
	PutPlayersInTeams();
	
	if (CheckMatchState(Match_FirstReadyPhase) && g_bKnifeRound_Enabled)
	{
		SetMatchState(Match_KnifeRound);
		
		//SetConVarInt(ConVar_RestartGame, 3);
		Func_RestartGame(true, 1, { DELAY_RESTART_KNIFE_ROUND } );
		
		return;
	}
	
	// if knife round i
	SetMatchState(Match_Restarts);
	Func_RestartGame(true, 3, { 3, 3, 5 } );
	
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Live on THREE restarts");
	
}

void CheckStart()
{
	//PrintToChatAll("g_iReadyCount = %d ... MATCH_TEAM_PLAYERS = %d", g_iReadyCount, MATCH_PLAYERS_COUNT);
	if (g_iReadyCount >= g_iMatchPlayersCount)
	{
		//PrintToChatAll("Starting");
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "-- Starting --");
		
		ChangeToOriginalClanTag();
		StartMatch();
	}
}

void Func_RestartGame(bool bReset, int iNumRestarts, int[] iDelay)
{
	if (bReset)
	{
		g_iRestarts = 0;
		g_hRestartsPack.Reset(true);
	}
	
	//g_iNumRestarts = iNumRestarts;
	
	g_iNumRestarts = iNumRestarts;
	g_bRestarting = true;
	
	if (iNumRestarts > 1)
	{
		for (int i; i < iNumRestarts; i++)
		{
			g_hRestartsPack.WriteCell(iDelay[i]);
		}
		
		g_hRestartsPack.Reset();
	}
	
	ServerCommand("mp_restartgame %d", iDelay[0]);
	PrintDebug("iDelay %d", iDelay);
}

void SetMatchState(MatchState State)
{
	MatchState iOldMatchState = gMatchState;
	gMatchState = State;
	
	switch (State)
	{
		case Match_Waiting:
		{
			ExecuteConfig(g_szWarmUpConfig);
			//strcopy(g_szMatchId, sizeof g_szMatchId, MATCHID_NO_MATCH);
			SetMatchId(MATCHID_NO_MATCH);
		}
		
		case Match_Restarts:
		{
			ExecuteConfig(g_szMatchConfig);
		}
		
		case Match_FirstReadyPhase:
		{
			SetArrayValue(g_bReady, sizeof g_bReady, false, 1);
			g_iReadyCount = 0;
			
			ChangeToReadyClanTag();
			
			ExecuteConfig(g_szWarmUpConfig);
		}
		
		case Match_SecondReadyPhase:
		{
			SetArrayValue(g_bReady, sizeof g_bReady, false, 1);
			g_iReadyCount = 0;
			
			ChangeToReadyClanTag();
			
			ExecuteConfig(g_szWarmUpConfig);
		}
		
		case Match_KnifeRound:
		{
			ExecuteConfig(g_szKnifeRoundConfig);
		}
		
		case Match_TeamChoose:
		{
			ExecuteConfig(g_szWarmUpConfig);
		}
		
		case Match_Running:
		{
			ExecuteConfig(g_szMatchConfig);
		}
	}
	
	Call_StartForward(g_hForward_MatchStateChanged);
	Call_PushCell(iOldMatchState);
	Call_PushCell(State);
	Call_Finish();
}

void PutPlayersInTeams()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || gPlayerState[client] != PlayerState_Player)
		{
			continue;
		}
		
		CS_SwitchTeam(client, gTeams[g_iTeamIndex[client]][TeamInfo_CurrentTeam]);
	}
}

void ExecuteConfig(const char[] szConfig)
{
	ServerCommand("exec \"%s/%s\"", g_szConfigFolder, szConfig);
}

void CheckIfClientIsAllowed(client)
{
	if (IsFakeClient(client))
	{
		gPlayerState[client] = PlayerState_Bot;
		g_iTeamIndex[client] = TeamIndex_None;
		
		/*
		g_bReady[client] = true;
		g_iReadyCount++;
		*/
		
		//CheckStart();
		
		PrintDebug("* Bot %N ignored", client);
		
		return;
	}
	
	if (CheckMatchState(Match_Waiting))
	{
		KickClient_Custom(client, KICK_MESSAGE_NOT_ALLOWED);
		return;
	}
	
	gPlayerState[client] = PlayerState_Checking;
	
	char szAuthId[35];
	GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	
	//SELECT (`match_players`.`playerteam`) FROM `match_players` WHERE `match_players`.`match_token` = 'TOKEN' AND `match_players`.`playerid` = 'STEAMID'";
	
	SQL_TQuery_Custom(g_hSql, SQLCallback_CheckClient, client, _, "Select Player Query:", "SELECT `%s` FROM `%s` WHERE `%s` = %d AND `%s` = '%s'", 
		g_szMatchPlayersTableFields[MatchPlayersField_TeamId], 
		g_szMatchPlayersTableName,  // FROM %s
		g_szMatchPlayersTableFields[MatchPlayersField_MatchId], gMatchId,  // WHERE `%s` = '%s'
		g_szMatchPlayersTableFields[MatchPlayersField_AuthId], szAuthId); //AND `%s` = '%s');
}

RestartsDone()
{
	g_bRestarting = false;
	
	if (CheckMatchState(Match_Restarts))
	{
		SetMatchState(Match_Running);
		MatchStartStuff();
	}
	
	else if (CheckMatchState(Match_KnifeRound))
	{
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "--- Knife Round ---");
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Win to choose the starting team.");
	}
}

void MatchStartStuff()
{
	SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0, _, "Update Match Start Timestamp", 
		"UPDATE `%s` SET `%s` = UNIX_TIMESTAMP() WHERE `%s` = %d", 
		g_szMatchTableName, g_szMatchTableFields[MatchField_StartTime], g_szMatchTableFields[MatchField_MatchId], gMatchId);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && gPlayerState[i] == PlayerState_Player)
		{
			g_iRoundsPlayed[i]++;
		}
	}
	
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Match is live, Good luck & Have fun.");
	
	Call_StartForward(g_hForward_MatchStart);
	Call_PushCell(gMatchId);
	Call_Finish();
}

int GetRandomClient(TeamsIndexes iTeamIndex = TeamIndex_None, bool bOnlyAlive = false, bool bInATeam = false)
{
	int iPlayers[MAXPLAYERS + 1], iCount;
	for (int client = 1, iPlayerTeam; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		
		if (iTeamIndex != TeamIndex_None && g_iTeamIndex[client] != iTeamIndex)
		{
			PrintDebug("Skipped %N", client);
			continue;
		}
		
		if (bOnlyAlive && !IsPlayerAlive(client))
		{
			continue;
		}
		
		if (bInATeam && !((iPlayerTeam = GetClientTeam(client)) == CS_TEAM_CT || iPlayerTeam == CS_TEAM_T))
		{
			continue;
		}
		
		iPlayers[iCount++] = client;
	}
	
	PrintDebug("Count %d", iCount);
	if (iCount == 1)
	{
		return iPlayers[0];
	}
	
	return iCount ? iPlayers[GetRandomInt(0, iCount - 1)] : 0;
}

void PrintDamageReportAll(bool bAliveOnly)
{
	if (bAliveOnly)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				PrintDamageReport(i);
			}
		}
	}
	
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				PrintDamageReport(i);
			}
		}
	}
}

PrintDamageReport(client)
{
	static int TeamBit = (1 << (CS_TEAM_CT + 1)) | (1 << (CS_TEAM_T + 1));
	
	PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "-------- Damage Report --------");
	
	char iColorLeft, iColorRight;
	int iClientTeamBit;
	int iOtherTeamBit;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iClientTeamBit = (1 << (GetClientTeam(client) + 1));
			iOtherTeamBit = (1 << (GetClientTeam(i) + 1));
			
			if (!(iClientTeamBit & TeamBit && iOtherTeamBit & TeamBit && iClientTeamBit != iOtherTeamBit))
			{
				continue;
			}
			
			#if defined OLD_DAMAGE_REPORT
			
			if (g_flDamage[client][i] > 0.0)iColorLeft = '\x04';
			else iColorLeft = '\x01';
			
			if (g_flDamage[i][client] > 0.0)iColorRight = '\x07';
			else iColorRight = '\x01';
			
			#else
			
			if (g_iKiller[i] == client)iColorLeft = '\x04';
			else iColorLeft = '\x01';
			
			if (g_iKiller[client] == i)iColorRight = '\x07';
			else iColorRight = '\x01';
			
			#endif	
			
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "%s[\x01%d in %d%s] \
			\x01<-> \
			%s[\x01%d in %d%s] \
			\x01- %d HP %N", 
				
				iColorLeft, 
				RoundFloat(g_flDamage[client][i]), 
				g_iHits[client][i], 
				iColorLeft, 
				
				iColorRight, 
				RoundFloat(g_flDamage[i][client]), 
				g_iHits[i][client], 
				iColorRight, 
				
				GetClientHealth(i), 
				i
				);
		}
	}
}

// Credits: zeusround.sp by "TnTSCS aka ClarkKent"
void CS_RemoveWeapons(int client, bool bStripKnife, bool bStripBomb)
{
	int weapon_index = -1;
	#define MAX_WEAPON_SLOTS 5
	
	for (int slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		weapon_index = GetPlayerWeaponSlot(client, slot);
		{
			PrintDebug("ent %d", weapon_index);
			if (IsValidEntity(weapon_index))
			{
				if (slot == CS_SLOT_KNIFE && !bStripKnife)
				{
					continue;
				}
				
				if (slot == CS_SLOT_C4 && !bStripBomb)
				{
					return;
				}
				
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

// from the_khalid_inc.inc (my own code)
stock void SetArrayValue(any[] Array, int iSize, any Value, int iStartingIndex = 0)
{
	for (int i = iStartingIndex; i < iSize; i++)
	{
		Array[i] = Value;
	}
}

// Since KickClient is not working properly, this is an alternative.
void KickClient_Custom(int client, const char[] szReason)
{
	ServerCommand("kickid %d \"%s\"", GetClientUserId(client), szReason);
}

bool IsValidPlayer(int client)
{
	if (0 < client <= MaxClients)
	{
		return true;
	}
	
	return false;
}

public int Native_GetMatchState(Handle hPlugin, int iArgs)
{
	return view_as<int>(gMatchState);
}

public int Native_GetPlayerState(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if (!(0 < client <= MaxClients))
	{
		ThrowError("Index out of bounds. (%d)", client);
		return view_as<int>(PlayerState_Error);
	}
	
	return view_as<int>(gPlayerState[client]);
}

public int Native_GetMatchId(Handle hPlugin, int iArgs)
{
	/*
	//if(StrEqual(g_szMatchId, MATCHID_NO_MATCH))
	if(CheckMatchId(MATCHID_NO_MATCH))
	{
		return 0;
	}
	
	SetNativeString(1, g_szMatchId, GetNativeCell(2), false);
	//return gMatchId;
	return 1;
	*/
	
	return gMatchId;
}
