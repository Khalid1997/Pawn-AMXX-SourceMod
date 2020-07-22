#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

Database g_hSql, g_hSqliteBans;

enum
{
	BanReasonCode_ConnectFailure = 1,	// 1 - Failed to connect BEFORE the match even started.
	BanReasonCode_Abandon = 2,							// 2 - Player abandoned the match.
	BanReasonCode_Cheater = 3

//	BanReasonCode_Accept_Fail,						// 3 - Player failed to accept the match.
}

enum
{
	BanSubCode_ConnectFailure_MatchStart = 1,	// Never even connected.
	
	BanSubCode_Abandon_Normal = 1,
	BanSubCode_Abandon_Disconnect = 2,	// Disconnected, never connected back to the game.

	BanSubCode_Cheater_Normal = 1	// Cheater.
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
new const String:g_szPlayersBansTableFields[PlayerBanField_Count][] = {
//	"id",
	"banid",
	"matchid",
	"banned_name",
	"ban_code",
	"ban_code_txt",
	"ban_time",
	"start_time",
	"end_time"
}

enum
{
//	BanStepsField_Id,
	BanStepsField_BanCode,
	BanStepsField_BanStep,
	BanStepsField_BanTime,
	BanStepsField_MatchesCount,
	
	BanStepsField_Count
}
new const String:g_szBanStepsTableName[] = "bans_steps";
new const String:g_szBanStepsTableFields[BanStepsField_Count][] = {
//	"id",
	"ban_code",
	"ban_step",
	"ban_time",
	"downgrade_matches"
}

enum
{
//	PlayersBanDataField_Id,
	PlayersBanDataField_AuthId,
	PlayersBanDataField_BanCode,
	PlayersBanDataField_BanStep,
	PlayersBanDataField_MatchesLeft
}
new const String:g_szPlayersBanDataTableName[] = "players_ban_data";
new const String:g_szPlayersBanTableFields[PlayerBanField_Count][] = {
//	"id",
	"steam",
	"ban_code",
	"ban_step",
	"ban_step",
	"matches_left",
}

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrMax)
{
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(!ConnectToDatabases())
	{
		SetFailState("Could not connect to databases");
		return;
	}
}

bool ConnectToDatabases()
{
	if(!SQL_CheckConfig("match_system"))
	{
		SetFailState("Could not find match_system in databases.cfg");
		return false
	}
	
	g_hSql = SQL_Connect("match_system", true, g_szError, sizeof g_szError);
	if(g_hSql == INVALID_HANDLE)
	{
		SetFailState("Failed to connect to SQL DB: %s", szError);
		return false;
	}
	
	g_hSqliteBans = SQLite_UseDatabase("banned_players", g_szError, sizeof g_szError);
	if(g_hSqliteBans == INVALID_HANDLE)
	{
		SetFailState("Failed to connect to SQLite DB: %s", szError);
		return false;
	}
	
	return true
}

public void OnClientAuthorized(int client, const char[] szAuthId)
{
	CheckIfClientIsBanned(client);
}

public void OnClientDisconnect(int client)
{
	if(g_bKicked[client])
	{
		g_bKicked[client] = false;
		return;
	}
	
	if(CheckMatchState(Match_Running))
	{
		AddPlayerToDisconnectTable(client);
	}
}

public void Match_OnMatchEnd(int iMatchId, int iMatchEndCode, int iWinnerTeamIndex)
{
	UpdateMatchesLeft_All();
}

void AddPlayerToDisconnectTable(int client)
{
	
}

void BanClient(const int client, const int iCode, const int iSubCode, const int iTime = DEFAULT_TIME)
{
	char szAuthId[35]; 
	GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	
	BanAuthId(szAuthId, iCode, iTime);
}

void BanAuthId(const char[] szAuthId, const int iCode, int iCustomTime = -1)
{
	ArrayList hData;
	
	PushArrayString(hData, szAuthId);
	PushArrayCell(hData, iCode);
	PushArrayCell(hData, iCustomTime);
/*
	SELECT ban_steps.ban_code, ban_steps.ban_step, ban_steps.ban_time FROM ban_steps 
					JOIN player_bans_steps	ON ban_steps.ban_code = player_bans_steps.ban_code 
											AND ( ban_steps.ban_step = player_bans_steps.ban_step
                                            OR  ban_steps.ban_step = player_bans_steps.ban_step + 1)
	WHERE player_bans_steps.steam = 'STEAM' ORDER BY `ban_code`, `ban_step` DESC;
*/
	g_szPlayersBanDataTableName.g_szPlayersBanTableFields[PlayerBanField_AuthId]
	g_szBanStepsTableName.g_szBanStepsTableFields[BanStepsTableField_
	
	SQL_TQuery_Custom(g_hSql, SQLCallback_GetBanSteps, hData,_, "Get Ban Data",
	"SELECT `%s`.`%s`, `%s`.`%s`, `%s`.`%s` FROM `%s`\
					JOIN `%s` ON `%s`.`%s` = `%s`.`%s`\
	WHERE `%s`.`%s` = '%s' ORDER BY `%s`, `%s` ASC;", g_szPlayersBanDataTableName, g_szPlayersBanTableFields[PlayerBanField_AuthId], 
		
}

