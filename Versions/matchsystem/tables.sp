enum
{
	ServersField_IP,
	ServersField_Port,
	ServersField_MatchId,
	
	ServersFieldsCount
};
new String:g_szServersTableName[] = "match_servers";
new String:g_szServersTableFields[ServersFieldsCount][] = {
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
new const String:g_szMatchTableFields[MatchTableFields][] = {
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
	MatchPlayersField_AuthId,		// SteamID
	MatchPlayersField_TeamId,
	MatchPlayersField_TeamName,
	
	MatchPlayersFields
};

new const String:g_szMatchPlayersTableName[] = "match_players";
new const String:g_szMatchPlayersTableFields[MatchPlayersFields][] = {
	"id",
	"matchid",
	"steam",
	"team_id",
	"team_name"
};

	new const String:g_szTeamsTableName[] = "match_teams";
	new const String:g_szTeamsTableFields[TeamField_Count][] = {
		"id",
		"name",
		"founded_on",
		"founder_id",
		"cached_wins",
		"cached_losses",
		"chached_rating"
	};
	
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
	
	new const String:g_szTeamsTableName[] = "match_teams";
	new const String:g_szTeamsTableFields[TeamField_Count][] = {
		"id",
		"name",
		"founded_on",
		"founder_id",
		"cached_wins",
		"cached_losses",
		"chached_rating"
	};

