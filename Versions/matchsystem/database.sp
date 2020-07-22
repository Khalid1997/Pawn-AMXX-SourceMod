void Database_ConnectToSQL()
{
	char szError[MAX_ERROR_LENGTH];
	/*if(SQL_CheckConfig("match_system"))
	{
		g_hSql = SQL_Connect("match_system", true, szError, sizeof szError);
	}
	
	else*/
	{
		LogMessage("DB Config 'matchsystem' is missing from databases.cfg. Connecting to values in plugin.");
		
		Handle hKv = CreateKeyValues("");
		KvSetString(hKv, "driver", "mysql");
		KvSetString(hKv, "host", "cyberesports.net");
		KvSetString(hKv, "user", "saif_admin");
		KvSetString(hKv, "pass", "Au9Y}/^(10m&i\"i"); // Au9Y}/^(10m&i"i
		KvSetString(hKv, "database", "saif_database");
		//g_hSql = SQL_Connects (hDriver, "", "", "", "", szError, sizeof szError);
		
		g_hSql = SQL_ConnectCustom(hKv, szError, sizeof szError, true);
		delete hKv;
	}

	if(g_hSql == null)
	{
		LogError("MySQL CONNECT ERROR: %s", szError);
		SetFailState("SQL Connection failed. Check error logs");
		
		return;
	}
	
	CheckIfServerHasCrashed();
}

void Database_CheckIncomingMatch()
{
	if(!CheckMatchId(MatchId_NoMatch))
	{
		return;
	}
	
	DBResultSet result = SQL_ExecuteQuery(g_hSql, "Check Match Query", g_szQuery_CheckIncomingMatch, g_szServerAddress, g_iServerPort);
	
	if(result == null)
	{
		return;
	}
	
	if(!SQL_FetchRow(result) || SQL_IsFieldNull(result, 0))
	{
		delete result;
		return;
	}
	
	g_iMatchId = SQL_FetchInt(g_hSql, 0);
	delete result;
	
	GetMatchData();
}

bool GetMatchData()
{
	DBResultSet result = SQL_ExecuteQuery(g_hSql, "Get Match Data", g_szQury_GetMatchData_GetData, gMatchId);
	
	if(result == null)
	{
		SetFailState("Check ERROR logs");
		return false;
	}
	
	if(!SQL_FetchRow(result))
	{
		LogError("Could not fetch team results for match data");
		delete result;
		
		return false;
	}
	
	//SQL_FetchRow(hQuery);
	if(result.IsFieldNull(0)
	{
		g_szMatchMap[0] = 0;
	}
	
	else
	{
		result.FetchString(0, g_szMatchMap, sizeof g_szMatchMap);
	}
	
	g_iStatsRecorded = view_as<RecordStats>(result.FetchInt(1));
	PrintDebug("g_iStatsRecorded = %d, RecordStats_All = %d", g_iStatsRecorded, RecordStats_All);
	
	int iFirstTeam = GetRandomInt(0, 1) ? CS_TEAM_T : CS_TEAM_CT;
	
	eTeamData[TeamIndex_First][TeamInfo_TeamId] = result.FetchInt(2);
	eTeamData[TeamIndex_First][TeamInfo_CurrentTeam] = iFirstTeam;
	
	eTeamData[TeamIndex_Second][TeamInfo_TeamId] =  result.FetchInt(3);
	eTeamData[TeamIndex_Second][TeamInfo_CurrentTeam] = iFirstTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T;
	
	delete result;
	
	result = SQL_ExecuteQuery(g_hSql, "Get team1 name query", g_szQuery_GetMatchData_GetTeamName,
	eTeamData[TeamIndex_First][TeamData_TeamId], eTeamData[TeamIndex_Second][TeamData_TeamId]);
	
	if(result == null)
	{
		return false;
	}
	
	if(SQL_GetRowCount(result) < 2)
	{
		LogError("Get team name query returned less than two rows.");
		
		delete result;
		return false;
	}
	
	while(SQL_FetchRow(hQuery))
	{
		iTeamId = result.FetchInt(0);
		iTeamIndex = eTeamData[TeamIndex_First][TeamInfo_TeamId] == iTeamId ? TeamIndex_First : TeamIndex_Second; 
		
		if(!result.IsFieldNull(1))
		{
			result.FetchString(1, eTeamData[iTeamIndex][TeamData_Name], MAX_TEAM_NAME_LENGTH);
		}
		
		else
		{
			eTeamData[iTeamIndex][TeamData_Name][0] = 0;
		}
	}
	
	delete result;
	
	result = SQL_ExecuteQuery(g_hSql, "Players Count", g_szQuery_GetMatchData_GetPlayersCount, g_iMatchId);
	if(result == null)
	{
		SetFailState("Check ERROR logs");
		return false;
	}
	
	SQL_FetchRow(result);
	g_iMatchPlayersCount = SQL_FetchInt(hQuery, 0);
	delete result;
	
	result = SQL_ExecuteQuery(g_hSql, "Get Players Data", g_szQuery_GetMatchData_GetPlayersData, g_iMatchId);
	
	if(result == null)
	{
		return;
	}
	
	int iPlayersCount;
	while(result.FetchRow())
	{
		iPlayersCount++;
		ePlayerData[iPlayersCount][PD_PlayerDBId] = result.FetchInt(0)
		ePlayerData[iPlayersCount][PD_PlayerTeamId]= result.FetchInt(1);
		result.FetchString(2, ePlayerAuth[iPlayersCount], sizeof ePlayerAuth[]);
	}
	
	FixTeamNames();
	return true;
}

bool CheckError(char[] szError)
{
	if( (szError[0] )
	{
		if( StrContains(szError, "no error", false) != -1 )
		{
			return true;
		}
	}
	
	return false;
}

public void SQLCallback_Dump(Handle hSql, Handle hResult, char[] szError, any data)
{
	if(CheckError(szError))
	{
		LogError("SQL DUMP ERROR: %s", szError);
		return;
	}
}

// Handle must be freed.
stock DBResultSet SQL_ExecuteQuery(Database hSql, const char[] szQueryDesc, const char[] szQuery, any ...)
{
	char szBuffer[MAX_QUERY_LENGTH];
	VFormat(szBuffer, sizeof(szBuffer), szQuery, 6);
	LogMessage("(%s): %s", szQueryDesc, szBuffer);
	
	char szError[MAX_ERROR_LENGTH];
	
	SQL_LockDatabase(hSql);
	DBResultSet result = SQL_Query(hSql, szBuffer, szError, sizeof szError);
	SQL_UnlockDatabase(hSql);
	
	if(result == null)
	{
		LogError("(%s) Error: %s", szQueryDesc, szError);
		return null;
	}
	
	return hQuery;
}
