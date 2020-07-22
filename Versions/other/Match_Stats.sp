#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <dbi>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

enum
{
	Stats_MatchId,
	Stats_AuthId,
	
	Stats_Kills,
	Stats_Headshots,
	Stats_Deaths,
	Stats_Assists,
	
	Stats_BombPlants,
	Stats_BombDefuses,
	
	Stats_2K,
	Stats_3K,
	Stats_4K,
	Stats_Ace,
	
	Stats_TotalShots,
	Stats_TotalHits,
	Stats_TotalDamage,
	
	Stats_MVP,
	
	Stats_RoundsPlayed,	
	
	Stats_Count
}

//int g_iStats[MAXPLAYERS][Stats_Count];
new const String:MATCHID_NO_MATCH[] = "NO_MATCH";
new String:g_szMatchId[20];

Handle g_hSqliteStats = INVALID_HANDLE;

new const String:g_szStatsDBName[] = "match_stats";
new const String:g_szStatsTableFields[Stats_Count][] = {
	"matchid",
	"steam",
	
	"kills",
	"headshots",
	"deaths",
	"assits",
	
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
	
	"rounds_played"
};

int		g_iKillsThisRound[MAXPLAYERS];
int		g_iKills[MAXPLAYERS],
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
float	g_flTotalDamage[MAXPLAYERS];
	
int 	g_iTotalMVPs[MAXPLAYERS],
		g_iRoundsPlayed[MAXPLAYERS];
	
bool g_bRecordData = false;

public void OnPluginStart()
{
	strcopy(g_szMatchId, sizeof g_szMatchId, MATCHID_NO_MATCH);
	
	RegConsoleCmd("sm_set_id", CmdSetMatchId, "-TEST");
	RegConsoleCmd("sm_data", CmdRecordData, "[on - off] - Toggles data recording");
	RegConsoleCmd("sm_upload_stats", CmdUploadStats, "-Test");
	
	RegConsoleCmd("sm_stats", CmdShowStats, "");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_mvp", Event_PlayerMVP);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	char szError[256];
	g_hSqliteStats = SQLite_UseDatabase(g_szStatsDBName, szError, sizeof szError);
	
	if(szError[0])
	{
		SetFailState("Could not connect to SQLite DB: %s", szError);
		return;
	}
}

public void Event_RoundStart(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		// Do is valid player;
		if(IsClientInGame(i))
		{
			g_iRoundsPlayed[i]++;
		}
	}
}

public void Event_RoundEnd(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	for(int i = 1, iKills; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		iKills = g_iKillsThisRound[i];
		g_iKillsThisRound[i] = 0;
		switch(iKills)
		{
			case 1: continue;
			case 2: g_i2Kills[i]++;
			case 3: g_i3Kills[i]++;
			case 4: g_i4Kills[i]++;
			case 5: g_iAces[i]++;
		}		
	}
}

public void Event_BombPlanted(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	
	g_iBombPlants[client]++;
}

public void Event_BombDefused(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	
	g_iBombDefuses[client]++;
}

public void Event_PlayerDeath(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	int iKiller = ( GetClientOfUserId( GetEventInt(event, "attacker") ) );
	
	g_iDeaths[client]++;
	
	if(IsValidPlayer(iKiller))
	{
		g_iKills[iKiller]++;
		g_iKillsThisRound[iKiller]++;
		
		if( GetEventBool(event, "headshot") )
		{
			g_iHeadshots[client]++;
		}
	}
	
	int iAssister = GetClientOfUserId( GetEventInt(event, "assister") );
	if(IsValidPlayer(iAssister))
	{
		g_iAssists[iAssister]++;
	}
}

public void Event_WeaponFire(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	PrintToChatAll("WeaponFired");
	
	g_iTotalShots[client]++;
}

public Action SDKCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	if(IsValidPlayer(attacker))
	{
		g_flTotalDamage[attacker] += damage;
		g_iTotalHits[attacker]++;
	}
}

public void Event_PlayerMVP(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(!g_bRecordData)
	{
		return;
	}
	
	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	
	g_iTotalMVPs[client]++;
}

public Action CmdShowStats(int client, int iArgs)
{
	PrintToConsole(client, "%-0.14s %0.18s", "Field", "Value");
	PrintToConsole(client, "%-0.14s %0.18s", "--------------", "-----");
	PrintToConsole(client, "%-0.14s %0.18d", "Kills", g_iKills[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Assists", g_iAssists[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Deaths", g_iDeaths[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Plants", g_iBombPlants[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Defuses", g_iBombDefuses[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "2K", g_i2Kills[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "3K", g_i3Kills[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "4K", g_i4Kills[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Aces", g_iAces[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Total Shots", g_iTotalShots[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Total Hits", g_iTotalHits[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Damage", RoundFloat(g_flTotalDamage[client]));
	PrintToConsole(client, "%-0.14s %0.18d", "MVPs", g_iTotalMVPs[client]);
	PrintToConsole(client, "%-0.14s %0.18d", "Rounds Played", g_iRoundsPlayed[client]); 
	
	return Plugin_Handled;
}

public Action CmdSetMatchId(int client, int iArgs)
{
	if(iArgs < 1)
	{
		ReplyToCommand(client, "Matchid: %d", g_szMatchId);
		return Plugin_Handled;
	}
	
	char szArg[20];
	GetCmdArg(1, szArg, sizeof szArg);
	
	if(StrEqual(szArg, "cancel", false))
	{
		DropTable();
		
		strcopy(g_szMatchId, sizeof g_szMatchId, MATCHID_NO_MATCH);
		ReplyToCommand(client, "MatchID set to: NO MATCH", g_szMatchId);
		
		return Plugin_Handled;
	}
	
	strcopy(g_szMatchId, sizeof g_szMatchId, szArg);
	ReplyToCommand(client, "MatchID set to: %s", g_szMatchId);
	CreateSQLiteTable();

	return Plugin_Handled;
}

void DropTable()
{
	SQL_TQuery_Custom(g_hSqliteStats, SQLCallback_Dump, 0,_, "Drop Table", "DROP TABLE `%s`", g_szMatchId);
}

public Action CmdRecordData(int client, int iArgs)
{
	if(iArgs < 1)
	{
		g_bRecordData = !g_bRecordData;	
	}
	
	else
	{
		char szCmd[5];
		GetCmdArg(1, szCmd, sizeof szCmd);
		
		if(StrEqual(szCmd, "on", false))
		{
			g_bRecordData = true;
		}
		
		if(StrEqual(szCmd, "off", false))
		{
			g_bRecordData = false;
		}
	}
	
	ReplyToCommand(client, "* Data recording: %s", g_bRecordData ? "Enabled" : "Disabled");
	return Plugin_Handled;
}

public Action CmdUploadStats(int client, int iArgs)
{
	if(g_hSqliteStats == INVALID_HANDLE)
	{
		ReplyToCommand(client, "Invalid Handle");
		return Plugin_Handled;
	}
	
	UploadAllStats();
	return Plugin_Handled;
}

void CreateSQLiteTable()
{
	if(StrEqual(g_szMatchId, MATCHID_NO_MATCH))
	{
		//DropTable();
		return;
	}
	
	SQL_TQuery_Custom(g_hSqliteStats, SQLCallback_CreateTable, 0,_, "Create Table", "CREATE TABLE IF NOT EXISTS `%s` (\
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
	`%s`	INTEGER DEFAULT (0));",
	g_szMatchId,
	g_szStatsTableFields[Stats_AuthId],
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
	g_szStatsTableFields[Stats_RoundsPlayed]
	);
}

public void SQLCallback_Dump(Handle hHandle, Handle hResults, char[] szError, any data)
{
	if(szError[0])
	{
		LogMessage("Dump Error: %s", szError);
		return;
	}
}

public void SQLCallback_CreateTable(Handle hHandle, Handle hResults, char[] szError, any data)
{
	if(szError[0])
	{
		LogMessage("Error: %s", szError);
		SetFailState("Failed to create the table %s", g_szMatchId);
		return;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			GetClientStats(i);
		}
	}
}

void AddClientToTable(int client)
{
	char szAuthId[35]; GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	SQL_TQuery_Custom(g_hSqliteStats, SQLCallback_Dump, 0,_, "Insert Query:", "INSERT INTO `%s` (`%s`) VALUES ( '%s' );", g_szMatchId, g_szStatsTableFields[Stats_AuthId], szAuthId);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
		
	if(StrEqual(g_szMatchId, MATCHID_NO_MATCH))
	{	
		return;
	}
	
	switch(g_iKillsThisRound[client])
	{
		case 2: g_i2Kills[client]++;
		case 3: g_i3Kills[client]++;
		case 4: g_i4Kills[client]++;
		case 5: g_iAces[client]++;
	}
	
	UploadClientStats(client);
}

public void OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
	
	if(StrEqual(g_szMatchId, MATCHID_NO_MATCH))
	{
		return;
	}
	
	GetClientStats(client);
}



public void SQLCallback_GetStats(Handle hHndl, Handle hResult, char[] szError, int client)
{
	if(szError[0])
	{
		LogMessage("Error in GetStats: %s", szError);
		return;
	}
	
	if(!SQL_GetRowCount(hResult))
	{
		AddClientToTable(client);
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
	g_flTotalDamage[client] = float( SQL_FetchInt(hResult, 12) );
	
	g_iTotalMVPs[client] = SQL_FetchInt(hResult, 13);
	g_iRoundsPlayed[client] = SQL_FetchInt(hResult, 14);
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
	g_iRoundsPlayed[client] = 0;
}

void UploadClientStats(client)
{
	char szAuthId[35]; GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	char szQuery[512];
	int iLen;
	
	iLen += FormatEx(szQuery[iLen], sizeof(szQuery) - iLen, "UPDATE `%s` SET `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, ",
	g_szMatchId,
	g_szStatsTableFields[Stats_Kills], g_iKills[client],
	g_szStatsTableFields[Stats_Headshots], g_iHeadshots[client],
	g_szStatsTableFields[Stats_Deaths], g_iDeaths[client],
	g_szStatsTableFields[Stats_Assists], g_iAssists[client]);
	
	iLen += FormatEx(szQuery[iLen], sizeof(szQuery) - iLen, "`%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, ", 	
	g_szStatsTableFields[Stats_BombPlants], g_iBombPlants[client],
	g_szStatsTableFields[Stats_BombDefuses], g_iBombDefuses[client],
	g_szStatsTableFields[Stats_2K], g_i2Kills[client],
	g_szStatsTableFields[Stats_3K], g_i3Kills[client],
	g_szStatsTableFields[Stats_4K], g_i4Kills[client],
	g_szStatsTableFields[Stats_Ace], g_iAces[client]);
	
	iLen += FormatEx(szQuery[iLen], sizeof(szQuery) - iLen, "`%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d, `%s` = %d WHERE `%s` = '%s';", 
	g_szStatsTableFields[Stats_TotalShots], g_iTotalShots[client],
	g_szStatsTableFields[Stats_TotalHits], g_iTotalHits[client],
	g_szStatsTableFields[Stats_TotalDamage], RoundFloat(g_flTotalDamage[client]),
	g_szStatsTableFields[Stats_MVP], g_iTotalMVPs[client],
	g_szStatsTableFields[Stats_RoundsPlayed], g_iRoundsPlayed[client],
	g_szStatsTableFields[Stats_AuthId], szAuthId);
	
	SQL_TQuery_Custom(g_hSqliteStats, SQLCallback_Dump, 0,_, "Update Query:", szQuery);
}

void SQL_TQuery_Custom(Handle hHandle, SQLTCallback callback, any data, DBPriority prio = DBPrio_Normal, char[] szQueryDesc,
						char[] szQuery, any ...)
{
	char szBuffer[625];
	VFormat(szBuffer, sizeof szBuffer, szQuery, 7);
	
	LogMessage("%s %s", szQueryDesc, szBuffer);
	SQL_TQuery(hHandle, callback, szBuffer, data, prio);
}

void UploadAllStats()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			UploadClientStats(i);
		}
	}
}

bool IsValidPlayer(int client)
{
	if( 0 < client <= MaxClients )
	{
		return false;
	}
	
	return true;
}