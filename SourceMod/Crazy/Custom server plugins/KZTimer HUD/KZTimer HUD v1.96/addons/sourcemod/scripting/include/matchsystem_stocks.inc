#include <multicolors>
#include "matchsystem/constants.sp"

stock void LogMessage_Custom(char[] szLogFile, char[] szPluginPos, char[] szDesc, char[] szMessage, any ...)
{
	char szBuffer[512];
	VFormat(szBuffer, sizeof szBuffer, szMessage, 4);
	
	char szFileLine[1024];
	char szTime[35];	// XX YYY ZZZZ
	//  12 3 8 = 23
	// 35, 128
	FormatTime(szTime, sizeof szTime, "%d %b %Y - %H:%M:%S", -1);
	FormatEx(szFileLine, sizeof szFileLine, 
	
	//LogToFile(g_iLogFiles[iLogFile]
	File f = OpenFile(szLogFile, "a+");
	WriteFileLine(f, "%s | %s | %s :\n\
	%25s", szTime, szPluginPos, szDesc, szBuffer);
	PrintToServer("%s | %s | %s :\n\
	%25s", szTime, szPluginPos, szDesc, szBuffer);
	delete f;
}

stock void PrintToChat_Custom(int client, const char[] szPrefix = "", char[] szMsg, any ...)
{
	static bool bInit = false
	if(!bInit)
	{
		bInit = true;
		CSetPrefix(PLUGIN_CHAT_PREFIX);
	}
	
	char szBuffer[192];
	VFormat(szBuffer, sizeof(szBuffer), szMsg, 4);
	
	PrintToServer( szPrefix );
	
	if(client > 0)
	{
		CPrintToChat(client, "\x01%s", szBuffer);
	}
	
	else CPrintToChatAll("\x01%s", szBuffer);
}

stock void SQL_TQuery_Custom(Handle hHandle, SQLTCallback callback, any data, DBPriority prio = DBPrio_Normal, char[] szQueryDesc,
						char[] szQuery, any ...)
{
	char g_szQuery_Plugin_Functions[MAX_QUERY_LENGTH];
	//char g_s[625];
	VFormat(g_szQuery_Plugin_Functions, sizeof g_szQuery_Plugin_Functions, szQuery, 7);
	
	LogMessage("%s %s", szQueryDesc, g_szQuery_Plugin_Functions);
	SQL_TQuery(hHandle, callback, g_szQuery_Plugin_Functions, data, prio);
}

// Handle must be freed.
stock Handle SQL_ExecuteQuery(Handle hMain, char[] szError, int iErrSize, const char[] szQueryDesc, const char[] szQuery, any:...)
{
	//char szBuffer[512];
	VFormat(g_szQuery_Plugin_Functions, sizeof(g_szQuery_Plugin_Functions), szQuery, 6);
	
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
		SQL_GetError(hQuery, szError, iErrSize);
		LogError("Failed to execute (%s) prepared query: %s", szQueryDesc, szError);
		
		delete hQuery;
		
		return INVALID_HANDLE;
	}
	
	return hQuery;
}

// --------------------------------------------------------------------------------------------------------------------
enum
{
	timeunit_seconds = 0, 
	timeunit_minutes, 
	timeunit_hours, 
	timeunit_days, 
	timeunit_weeks
};

// seconds are in each time unit
#define SECONDS_IN_MINUTE 60
#define SECONDS_IN_HOUR   3600
#define SECONDS_IN_DAY    86400
#define SECONDS_IN_WEEK   604800

/* Stock by Brad */
/* credits from Amx Mod X Brad .. I think - although this function was easy to make xD .. too lazy */
stock void GetTimeLength(int id, int unitCnt, int type, String:output[], int outputLen)
{
	// IMPORTANT: 	You must add register_dictionary("time.txt") in plugin_init()
	
	// id:          The player whose language the length should be translated to (or 0 for server language).
	// unitCnt:     The number of time units you want translated into verbose text.
	// type:        The type of unit (i.e. seconds, minutes, hours, days, weeks) that you are passing in.
	// output:      The variable you want the verbose text to be placed in.
	// outputLen:	The length of the output variable.
	
	if (unitCnt > 0)
	{
		// determine the number of each time unit there are
		int weekCnt = 0, dayCnt = 0, hourCnt = 0, minuteCnt = 0, secondCnt = 0;
		
		switch (type)
		{
			case timeunit_seconds:	secondCnt = unitCnt;
			case timeunit_minutes:	secondCnt = unitCnt * SECONDS_IN_MINUTE;
			case timeunit_hours:	secondCnt = unitCnt * SECONDS_IN_HOUR;
			case timeunit_days:		secondCnt = unitCnt * SECONDS_IN_DAY;
			case timeunit_weeks:	secondCnt = unitCnt * SECONDS_IN_WEEK;
		}
		
		weekCnt = secondCnt / SECONDS_IN_WEEK;
		secondCnt -= (weekCnt * SECONDS_IN_WEEK);
		
		dayCnt = secondCnt / SECONDS_IN_DAY;
		secondCnt -= (dayCnt * SECONDS_IN_DAY);
		
		hourCnt = secondCnt / SECONDS_IN_HOUR;
		secondCnt -= (hourCnt * SECONDS_IN_HOUR);
		
		minuteCnt = secondCnt / SECONDS_IN_MINUTE;
		secondCnt -= (minuteCnt * SECONDS_IN_MINUTE);
		
		// translate the unit counts into verbose text
		int maxElementIdx = -1;
		new String:timeElement[5][33];
		
		if (weekCnt > 0)
			Format(timeElement[++maxElementIdx], 32, "%i %L", weekCnt, id, (weekCnt == 1) ? "TIME_ELEMENT_WEEK" : "TIME_ELEMENT_WEEKS");
		if (dayCnt > 0)
			Format(timeElement[++maxElementIdx], 32, "%i %L", dayCnt, id, (dayCnt == 1) ? "TIME_ELEMENT_DAY" : "TIME_ELEMENT_DAYS");
		if (hourCnt > 0)
			Format(timeElement[++maxElementIdx], 32, "%i %L", hourCnt, id, (hourCnt == 1) ? "TIME_ELEMENT_HOUR" : "TIME_ELEMENT_HOURS");
		if (minuteCnt > 0)
			Format(timeElement[++maxElementIdx], 32, "%i %L", minuteCnt, id, (minuteCnt == 1) ? "TIME_ELEMENT_MINUTE" : "TIME_ELEMENT_MINUTES");
		if (secondCnt > 0)
			Format(timeElement[++maxElementIdx], 32, "%i %L", secondCnt, id, (secondCnt == 1) ? "TIME_ELEMENT_SECOND" : "TIME_ELEMENT_SECONDS");
		
		switch (maxElementIdx)
		{
			case 0:Format(output, outputLen, "%s", timeElement[0]);
			case 1:Format(output, outputLen, "%s and %s", timeElement[0], id, timeElement[1]);
			case 2:Format(output, outputLen, "%s, %s and %s", timeElement[0], timeElement[1], id, timeElement[2]);
			case 3:Format(output, outputLen, "%s, %s, %s and %s", timeElement[0], timeElement[1], timeElement[2], id, timeElement[3]);
			case 4:Format(output, outputLen, "%s, %s, %s, %s and %s", timeElement[0], timeElement[1], timeElement[2], timeElement[3], id, timeElement[4]);
		}
	}
} 