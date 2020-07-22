#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <matchsystem_stocks>
#include <matchsystem_const>

#define RECONNECT_TIME 60.0 * 0.5

public Plugin myinfo = 
{
	name = "Ban System",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

int g_iMatchId;

//StringMap g_hHandleTrie;
Database g_hSql;
Database g_hSqlite
bool g_bLate;

char g_szQuery[512];

enum
{
	BanField_BanId,
	BanField_AuthId,
	BanField_Name,
	BanField_Reason,
	BanField_BanTime,
	BanField_StartTime,
	BanField_EndTime,
	
	BanField_Count
};

const char g_szBanTableName[] = "bans";
new String:g_szTableFields[TABLE_FIELDS][] = {
	"banid",
	"steam",
	"ban_name",
	"ban_reason",
	"ban_time",
	"start_time",
	"end_time"
};

public APLRes AskPluginLoad2(Handle plugin, bool bLate, char[] szError, int iErrorMax)
{
	g_bLate = bLate;
	
	//CreateNative("Match_IsPlayerBanned", Native_IsBanned);
	//CreateNative("Match_BanPlayer", Native_BanClient);
	//CreateNative("Match_PutPlayerInPendingBan", Native_PutClientInPendingBan);
	
	return APLRes_Success;	
}

// INSERTION QUERY:
// INSERT INTO banned_players VALUES (DEFAULT, 'steam', 'KHALID', 86400, DEFAULT, NOW() + INTERVAL 86400 SECOND)
public void OnPluginStart()
{
	CreateTables();
	//g_hHandleTrie = CreateTrie();
	
	if(g_bLate)
	{
		CheckClients();
	}
}

void CheckClients()
{
	PrintToServer("CheckClients Callled (LATE)");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		CheckClient_IsBanned(i);
	}
}

public void OnMapEnd()
{

}

public void OnClientAuthorized(int client, const char[] szAuthId)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	CheckClient_IsBanned(client);
}

public void OnClientDisconnect(int client)
{
	if(Match_GetMatchState() == Match_Running && Match_IsPlayerInMatch(client))
	{
		Custom_PrintToChat(0, "", "\x03%N has %d minutes left to reconnect", client, RoundFloat(RECONNECT_TIME / 60.0));
	}
}

public Action Timer_BanPlayer(Handle hTimer, Handle hData)
{
	iMatchId = ReadPackCell(hData);
	
	if(iMatchId != g_iMatchId)
	{
		return Plugin_Stop;
	}
	
	char szSteamId[35], szName[MAX_NAME_LENGTH + 1];
	ReadPackString(hData, szSteamId, sizeof szSteamId);
	ReadPackString(hData, szName, sizeof szName);
	
	// Check if he is not connected.
	int client;
	if( ( client = FindTarget(0, szSteamId, true, false) ) != -1)
	{
		// If connected, then stop everything.
		return Plugin_Stop;
	}
	
	int iBanTime = GetNextBanDuration(szSteamId);
	
	char szBanPeriodString[50];
	GetTimeLength(iBanTime, szBanPeriodString, sizeof szBanPeriodString)
	
	BanPlayer(szSteamId, iBanTime, "Abandon");
	Custom_PrintToChat(0, PLUGIN_CHAT_PREFIX, "\x03Player %s has been banned for %s for abandoning the game.", szPlayerName, szBanPeriodString)
}

bool CheckClient_IsBanned(client)
{
	char szAuthId[35]; GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	
	// Do 2 queries
	//SELECT * FROM `banned_players` WHERE ( TIME_TO_SEC(`ban_time_end`) < NOW() ) OR ( `ban_time_end` IS NULL );
	// UNIX_TIMESTAMP if you want to compare values.
	
	FormatEx(g_szQuery, sizeof g_szQuery, "SELECT (`%s`, `%s`, `%s`, `%s`, `%s`, `%s`) FROM `%s` WHERE `%s` = '%s' AND ( (  ( TIME_TO_SEC(`%s`) + `%s` )  < NOW() ) OR ( `%s` = -1 ) )",
	g_szTableFields[TBF_ID], g_szTableFields[TBF_BANTIME], g_szTableFields[TBF_BAN_START], g_szTableFields[TBF_BAN_END], g_szTableFields[TBF_REASON], g_szTableFields[TBF_Name]),
	g_szTableFields[TABLE_NAME], g_szTableField[TBF_AUTHID], szAuthId, g_szTableField[TBF_BAN_START], g_szTableField[TBF_BANTIME], g_szTableField[TBF_BANTIME]);
	
	SQL_TQuery(g_hSql, SQLCallback_IsBannedCheck, client);
}

public void SQLCallback_IsBannedCheck(Handle owner, Handle hndl, const char[] error, int client)
{
	if(!IsValidPlayer(client, false))
	{
		return;
	}
	// bantime, ban_time_start, ban_time_end, ban_reason, banned_name
	//int iBanTime, iBanTimeStart, iBanTimeEnd;
	//char szBanReason[128], szBannedName[MAX_NAME_LENGTH];
	
	bool bKick = false;
	int iBanId
	
	if(SQL_GetRowCount(hndl) > 0)
	{
		//SQL_FetchRow(hndle);
		//	iBanTime = SQL_FetchInt(hndle, 0);
		//	if(iBanTime
		
		iBanId = SQL_FetchInt(hndle, 0);
		bKick = true;
	}

	if(CheckClient_PendingDisconnectBan(client))
	{
		RemoveClient_PendingDisconnectBan(client);
	}
	
	if(bKick)
	{
		KickPlayer(client, iBanId);
	}
}

bool IsValidPlayer(int client, bool bInGame = true)
{
	if( !(0 < client <= MaxClients) )
	{
		return false;
	}
	
	if(bInGame)
	{
		if(!IsClientInGame(client))
		{
			return false;
		}
	}
	
	else if(!IsClientConnected(client))
	{
		return false;
	}
	
	return true;
}

void KickPlayer(int client, iBanId)
{
			/*
		GetTimeLength(timeunit_seconds, iBanTime, szBanTime);
		//GetTimeLength(timeunit_seconds,
		FormatTime(szBanEnd, sizeof szBanEnd, "%F %T", iBanEnd);
		FormatTime(szBanStart, sizeof szBanStart, "%F %T", iBanStart);
		
		GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
		
		PrintToConsole(client, "------------- Ban Info ------------")
		PrintToConsole(client, "Ban ID: %0.16d", iBanId);
		PrintToConsole(client, "Current Name: %0.16N", client);
		PrintToConsole(client, "Banned Name: %0.16s", szBannedName);
		PrintToConsole(client, "Banned SteamID: %0.16s", szAuthId);
		PrintToConsole(client, "Ban Time: %0.16s", szBanTime);
		PrintToConsole(client, "Ban issued at: %0.16s", szBanStart);
		PrintToConsole(client, "Ban Ends at: %0.16s", szBanEnd);
		PrintToConsole(client, "Ban reason: %0.16s", szBanReason);
		PrintToConsole(client, "- If you want to protest, feel free to do so at our website.");
		PrintToConsole(client, "-----------------------------------")
		*/
	KickClient(client, "You have been banned from this server. [BanID: %d]", iBanId);
}

bool CheckClient_PendingDisconnectBan(int client, bool bRemove = false)
{
	char szSteamId[35]; GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof szSteamId);
	
	any hData[TrieData];
	if(!GetTrieArray(g_hHandleArray, szSteamId, hData, sizeof hData))
	{
		PrintToServer("Not Pending %N", client);
		return false;
	}
	
	if(!bRemove)
	{
		return true;
	}
	
	RemoveFromTrie(g_hHandleTrie, szSteamId);
	
	for(int i; i < hData; i++)
	{
		delete hData[i];
	}
	
	PrintToServer("Deleted Handle %N", client);
	return true;
}

public void Match_OnMatchEnd()
{
	for(int i; i <= sizeof g_hBanTimerHandle; i++)
	{
		if(g_bBanTimerHandle[i] != INVALID_HANDLE)
		{
			delete g_hBanTimerHandle[i];
			g_hBanTimerHandle[i] = INVALID_HANDLE;
		}
	}
}

void CreateTables()
{
	char szError[128];
	g_hSql = SQL_Connect("matchsystem", true, szError, sizeof szError);
	
	if(g_hSql == INVALID_HANDLE)
	{
		LogError("Could not connect to SQL database: %s", szError);
		SetFailState("Could not connect to the SQL database.");
		return;
	}
	
	SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0, _, "Create Table", CREATE TABLE IF NOT EXISTS `%s` ( `%s` INT NOT NULL AUTO_INCREMENT primary key, `%s` VARCHAR(35), `%s` VARCHAR(35), `%s` VARCHAR(128),\
	 `%s` INT, `%s` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, `%s` TIMESTAMP DEFAULT NULL",
	g_szTableFields[TABLE_NAME], g_szTableFields[TBF_ID], g_szTableFields[TBF_AUTHID],  g_szTableFields[TBF_NAME], g_szTableFields[TBF_REASON], g_szTableFields[TBF_BANTIME],
	g_szTableFields[TBF_BAN_START], g_szTableFields[TBF_BAN_END]);
	
	g_hSqlite = SQLite_UseDatabase("pending_players", szError, sizeof szError);
	
	SQL_ExecuteQuery(
	
}

public void SQLCallback_Dump(Handle owner, Handle hndl, const char[] error, any data)
{
	if(error[0])
	{
		LogError("Dump Error: %s", szError);
	}
}

void SQL_TQuery_Custom(Handle hHandle, SQLTCallback callback, any data, DBPriority prio = DBPrio_Normal, char[] szQueryDesc,
						char[] szQuery, any ...)
{
	//char g_s[625];
	VFormat(g_szQuery_Plugin_Functions, sizeof g_szQuery, szQuery, 7);
	
	LogMessage("%s %s", szQueryDesc, g_szQuery);
	SQL_TQuery(hHandle, callback, g_szQuery, data, prio);
}

// Handle must be freed.
Handle SQL_ExecuteQuery(Handle hMain, char[] szError, int iErrSize, const char[] szQueryDesc, const char[] szQuery, any:...)
{
	//char szBuffer[512];
	VFormat(g_szQuery_Plugin_Functions, sizeof(g_szQuery), szQuery, 6);
	
	LogMessage("(%s) %s", szQueryDesc, g_szQuery_Plugin_Functions);
	
	DBStatement hQuery = SQL_PrepareQuery(hMain, g_szQuery_Plugin_Functions, szError, iErrSize);
	if(hQuery == INVALID_HANDLE || szError[0])
	{
		LogError("(%s) Error: %s", szQueryDesc, szError);
		SetFailState("SQL Error. Check error log.");
	
		delete hQuery;
		
		return INVALID_HANDLE;
	}
	
	if(!SQL_Execute(hQuery))
	{
		LogError("Failed to execute (%s) prepared query", szQueryDesc);
		
		delete hQuery;
		
		return INVALID_HANDLE;
	}
	
	return hQuery;
}


/* Time unit types for get_time_length() */




