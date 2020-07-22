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
		g_iTotalJumps[MAXPLAYERS],
		g_iRoundsPlayed[MAXPLAYERS];

new const String:g_szSqliteTablePrefix[] = "match_";

new const String:g_szStatsDBName[] = "match_stats"; // Used for SQLite
new const String:g_szStatsTableName[] = "match_stats";
new const String:g_szStatsTableFields[Stats_Count][] = {
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

const RecordStats RecordStats_All = (RecordStats_Kills | RecordStats_Headshots | RecordStats_Deaths | RecordStats_Assists
							| RecordStats_BombPlants | RecordStats_BombDefuses | RecordStats_2Kills | RecordStats_3Kills
							| RecordStats_4Kills| RecordStats_Aces | RecordStats_TotalShots | RecordStats_TotalHits
							| RecordStats_TotalDamage | RecordStats_MVP | RecordStats_RoundsPlayed );		
							
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
}

enum RecordStats (<<= 1)
{
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

RecordStats g_iStatsRecorded;

void Stats_OnPluginStart()
{
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("round_mvp", Event_PlayerMVP);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
}

void Stats_OnPlayerDeath()
{
	// Stats Stuff
	if( CheckMatchState(Match_Running) )
	{
		g_iDeaths[client]++;

		if(IsValidPlayer(iKiller) && gPlayerState[iKiller] == PlayerState_Player)
		{
			// Avoid calculating team kills as +1;
			if(GetClientTeam(iKiller) != GetClientTeam(client))
			{
				g_iKills[iKiller]++;
				PrintDebug("Added kill to %N", iKiller);
				
				g_iKillsThisRound[iKiller]++;
			}
			
			if( GetEventBool(event, "headshot") )
			{
				g_iHeadshots[iKiller]++;
			}
		}
		
		int iAssister = GetClientOfUserId( GetEventInt(event, "assister") );
		if(IsValidPlayer(iAssister) && gPlayerState[iAssister] == PlayerState_Player)
		{
			g_iAssists[iAssister]++;
		}
	}
}

public void Event_WeaponFire(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(gMatchState != Match_Running)
	{
		return;
	}
	
	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	//PrintToChatAll("WeaponFired");
	g_iTotalShots[client]++;
}

public void Event_BombPlanted(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(CheckMatchState(Match_Running))
	{
		int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
		g_iBombPlants[client]++;
	}
}

public void Event_BombDefused(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(CheckMatchState(Match_Running))
	{
		int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
		g_iBombDefuses[client]++;
	}
}

public void Event_PlayerMVP(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(CheckMatchState(Match_Running))
	{
		int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
		g_iTotalMVPs[client]++;
	}
}
public void Event_PlayerJump(Event event, const char[] szEventName, bool bDontBroadcast)
{
	if(CheckMatchState(Match_Running))
	{
		int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
		g_iTotalJumps[client]++;
	}
}

void Stats_OnTakeDamage(int attacker)
{
	g_flTotalDamage[attacker] += damage;
	g_iTotalHits[attacker]++;
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
	g_szStatsTableFields[Stats_Assists],g_szStatsTableFields[Stats_BombPlants], g_szStatsTableFields[Stats_BombDefuses], 
	g_szStatsTableFields[Stats_2Kills], g_szStatsTableFields[Stats_3Kills], g_szStatsTableFields[Stats_4Kills],
	g_szStatsTableFields[Stats_Aces], g_szStatsTableFields[Stats_TotalHits], g_szStatsTableFields[Stats_TotalShots], 
	g_szStatsTableFields[Stats_TotalDamage], g_szStatsTableFields[Stats_TotalMVPs],	g_szStatsTableFields[Stats_TotalJumps],
	g_szStatsTableFields[Stats_RoundsPlayed], g_szSqliteTablePrefix, gMatchId);
	//SQL_ExecuteQuery(Handle hMain, char[] szError, int iErrSize, const char[] szQueryDesc, char[] szQuery, any ...);
	
	if(hResult == INVALID_HANDLE)
	{
		LogError("Handle Invalid");
		SQL_UnlockDatabase(g_hSqliteStats);
		
		return;
	}
	
	//int iDump;
	//while(SQL_MoreRows(hResult))
	while(SQL_FetchRow(hResult))
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
		g_szStatsTableFields[Stats_TotalDamage], g_szStatsTableFields[Stats_TotalMVPs],	g_szStatsTableFields[Stats_TotalJumps], g_szStatsTableFields[Stats_RoundsPlayed]);
		
		iLen += FormatEx(g_szQuery[iLen], sizeof(g_szQuery) - iLen, "VALUES ( %d, '%s', %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d );",
		gMatchId, szAuthId, 
		( ( iStatsBit & RecordStats_Kills ) ? SQL_FetchInt(hResult, 1) : -5614 ),
		( ( iStatsBit & RecordStats_Deaths ) ? SQL_FetchInt(hResult, 2) : -5614 ),
	 	( ( iStatsBit & RecordStats_Headshots ) ? SQL_FetchInt(hResult, 3) : -5614 ),
	 	( ( iStatsBit & RecordStats_Assists ) ? SQL_FetchInt(hResult, 4) : -5614 ), 
		( ( iStatsBit & RecordStats_BombPlants ) ? SQL_FetchInt(hResult, 5) : -5614 ),
		( ( iStatsBit & RecordStats_BombDefuses ) ? SQL_FetchInt(hResult, 6) : -5614 ),
		( ( iStatsBit & RecordStats_2Kills ) ?	SQL_FetchInt(hResult, 7) : -5614 ),
		( ( iStatsBit & RecordStats_3Kills ) ? SQL_FetchInt(hResult, 8) : -5614 ),
		( ( iStatsBit & RecordStats_4Kills ) ? SQL_FetchInt(hResult, 9) : -5614 ), 
		( ( iStatsBit & RecordStats_Aces ) ? SQL_FetchInt(hResult, 10) : -5614 ),
		( ( iStatsBit & RecordStats_TotalHits ) ? SQL_FetchInt(hResult, 11) : -5614 ),
		( ( iStatsBit & RecordStats_TotalShots ) ? SQL_FetchInt(hResult, 12) : -5614 ),
		( ( iStatsBit & RecordStats_TotalDamage ) ? SQL_FetchInt(hResult, 13) : -5614 ),
		( ( iStatsBit & RecordStats_MVP ) ? SQL_FetchInt(hResult, 14) : -5614 ),
		( ( iStatsBit & RecordStats_TotalJumps ) ? SQL_FetchInt(hResult, 15) : -5614 ),
		( ( iStatsBit & RecordStats_RoundsPlayed ) ? SQL_FetchInt(hResult, 16) : -5614) );
		
		LogMessage("QUERY BEFORE REPLACE: %s", g_szQuery);
		ReplaceString(g_szQuery, sizeof g_szQuery, "-5614", "NULL", false);
		
		SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0,_, "SQL-> Insert Stats", g_szQuery);
	}
	
	delete hResult;
	SQL_UnlockDatabase(g_hSqliteStats);
}