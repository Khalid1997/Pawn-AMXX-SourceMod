#define serverName		"match_server_list"
#define serverId		"id"
#define serverIP		"server_ip"
#define serverPort		"server_port"
#define serverMatchId	"matchid"
#define serverEnabled	"enabled"

#define matchName 			"match_list"
#define matchMatchId		"id"
#define matchServerId		"serverid"
#define matchMap  			"map"
#define matchRecorededStats "recorded_stats"
#define matchTeam1			"teamid_1"
#define matchTeam2			"teamid_2"
#define matchTeam1Score 	"team1_score"
#define matchTeam2Score 	"team2_score"
#define matchTeamWinner		"teamid_winner"
#define matchIssueTime		"issue_time"
#define matchStartTime		"start_time"
#define matchEndTime		"end_time"
#define matchEndCode		"match_end_code"

#define teamName			"match_team_list"
#define teamId				"id"
#define teamTeamName		"team_name"

#define teamplayersName		"match_team_players_list"
#define teamplayersPlayerId	"playerid"
#define teamplayersTeamId	"teamid"
#define teamplayersAuth		"auth"

#define statsName			"match_stats"
#define statsAuth			"auth"
#define statsMatchId		"matchid"
#define statsKills			"kills"
#define statsAssists		"assists"
#define statsDeaths			"deaths"
#define statsHeadshots		"headshots"
#define statsJumps			"jumps"
#define statsShots			"shots"
#define stats2Kills			"2kills"
#define stats3Kills			"3kills"
#define stats4Kills			"4kills"
#define stats5Kills			"5kills"
#define statsBombPlants		"bombplants"
#define statsBombDefuses	"bombdefuses"
#define statsRoundsPlayed	"roundplayed"
#define statsMVP			"mvp_num"


#define qCheckCrash1 "SELECT "..serverMatchId.." FROM "..serverName.." WHERE " ..serverIP.. " = %d AND "..serverPort.." = %d;"
char g_szQuery_CheckCrash1[] = qCheckCrash1;

#define qCheckCrash2 "SELECT COUNT(*) FROM "..matchName.." WHERE "..matchMatchId.." = %d AND "..matchStartTime.." IS NOT NULL AND "..matchStartTime.." < UNIX_TIMESTAMP();"
char g_szQuery_CheckCrash2[] = qCheckCrash2;
	
#define qCheckCrashCanceMatch "UPDATE "..matchName.." SET "..matchEndTime.." = UNIX_TIMESTAMP(), "..matchTeamWinner.." = %d, "..matchEndCode.." = '%s' WHERE "..matchMatchId.." = %d;"
char g_szQuery_CheckCrash_CancelMatchCrash[] = qCheckCrashCanceMatch;
	
#define qCheckCrashUpdateServer "UPDATE "`match_server_list`" SET "`current_match_id`" = NULL WHERE "`server_ip`" = '%s' AND "`server_port`" = %d;"
char g_szQuery_CheckCrash_CancelMatchCrash_UpdateServer[] = qCheckCrashUpdateServer;

#define qCheckIncomingMatch "SELECT "`matchid`" FROM "`server_list`" WHERE "`server_ip`" = '%s' AND "`server_port`" = %d AND "`enabled`" = 1;"
char g_szQuery_CheckIncomingMatch[] = 
	"SELECT `matchid` FROM `server_list` WHERE `server_ip` = '%s' AND `server_port` = %d AND `enabled` = 1;";

#define qGetMatchData_GetData "SELECT "`map`", "`recorded_stats`", "`team1_id`", "`team2_id`" FROM "`match_list`" WHERE "`id`" = %d;"
char g_szQuery_GetMatchData_GetData[] = qGetMatchData_GetData
	
#define qGetMatchData_GetTeamNames "SELECT "`id`", "`team_name`" FROM "`match_team_list`" WHERE "`id`" = %d OR "`id`" = %d;"
char g_szQuery_GetMatchData_GetTeamNames[] = qGetMatchData_GetTeamNames;
	
#define qGetMatchData_GetPlayersCount "SELECT COUNT(*) FROM "`match_team_player_list`" WHERE "`match_id`" = %d;";
char g_szQuery_GetMatchData_GetPlayersCount[] = qGetMatchData_GetPlayersCount;
	
#define qGetMatchData_GetPlayersData "SELECT "`playerid`", "`teamid`", "`auth`"  FROM "`match_team_player_list`" WHERE "`match_id`" = %d;";
char g_szQuery_GetMatchData_GetPlayersData[] = qGetMatchData_GetPlayersData;