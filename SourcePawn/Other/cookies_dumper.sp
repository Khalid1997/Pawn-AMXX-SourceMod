#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#define PLUGIN_NAME    "Cookies dumper"
#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Khalid",
	version		= PLUGIN_VERSION,
	description = "Dumps Cookies data",
	url         = "nope."
};

Database g_hSQL;
char g_szLastQuery[512];

ConVar ConVar_PrintMethod;

int g_iDumpFileNumber = 0;

public void OnPluginStart()
{
	ConVar_PrintMethod = CreateConVar("cookie_dump_printmode", "2", "0 - Print Nothing; 1 - Print on console; 2 - Print in logs");
	
	RegServerCmd("cookies_list", ServerCmd_ListCookies);
	RegServerCmd("cookies_dump", ServerCmd_Dump, "<cookieid> - Dumps all data to a MySQL file format");
	
	ConnectToSQLiteDatabase();
}

void ConnectToSQLiteDatabase()
{
	char error[PLATFORM_MAX_PATH];
	g_hSQL = SQL_Connect("clientprefs", true, error, sizeof(error));

	if (!LibraryExists("clientprefs") || g_hSQL == INVALID_HANDLE)
	{
		SetFailState("Plugin encountered fatal error: %s", error);
	}
}

public void OnPluginEnd()
{
	delete g_hSQL;
}

public Action ServerCmd_ListCookies(int args)
{
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "SELECT `id`, `access`, `name`, `description` FROM `sm_cookies`");
	g_hSQL.Query(SQLCallback_ListCookies, g_szLastQuery);
	
	return Plugin_Handled;
}

public void SQLCallback_ListCookies(Database hSQL, DBResultSet hResult, const char[] szError, any data)
{
	if(!CheckQuery(hResult, szError))
	{
		return;
	}
	
	int iCookieID, iAccess, i;
	char szName[30], szDescription[255], szAccess[50];
	
	PrintMessage("Listing Cookies:");
	PrintMessage("#. <Cookie ID> <Cookie Name> - <Access> - <Description>");
	while(hResult.FetchRow())
	{
		iCookieID = hResult.FetchInt(0);
		iAccess = hResult.FetchInt(1);
		
		hResult.FetchString(2, szName, sizeof szName);
		hResult.FetchString(3, szDescription, sizeof szDescription);
		
		ConvertAccess(iAccess, szAccess, sizeof szAccess);
		PrintMessage("%2d. %4d %31s - %30s - %s", ++i, iCookieID, szName, szAccess, szDescription);
	}
}

void ConvertAccess(int iAccess, char[] szString, int iSize)
{
	char szAccessString[][] = {
		"Read and Write",
		"Read Only",
		"Hidden"
	};
	
	FormatEx(szString, iSize, szAccessString[iAccess]);
}

public Action ServerCmd_Dump(int args)
{
	if(args < 1)
	{
		PrintToServer("Missing arguments");
		return Plugin_Handled;
	}
	
	char szArg[5];
	GetCmdArg(1, szArg, sizeof szArg);
	
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "SELECT `player`,`value` FROM `sm_cookie_cache` WHERE `cookie_id` = '%s'", szArg);
	g_hSQL.Query(SQLCallback_DumpCookiesToFile, g_szLastQuery);
	
	return Plugin_Handled;
}

public void SQLCallback_DumpCookiesToFile(Database hSQL, DBResultSet hResult, const char[] szError, any data)
{
	if(!CheckQuery(hResult, szError))
	{
		return;
	}
	
	char szPlayerAuthId[65], szValue[100];
	
	if(!(hResult.RowCount))
	{
		PrintMessage("No Results to dump.");
		return;
	}
	
	char szFile[PLATFORM_MAX_PATH];
	GetFileName(szFile, sizeof szFile);
	
	File f = OpenFile(szFile, "a+");
	
	if(f == INVALID_HANDLE)
	{
		PrintMessage("Failed to make file");
		return;
	}
	
	char szTimeFmt[512];
	FormatTime(szTimeFmt, sizeof szTimeFmt, "-- Dumped at: %c", GetTime());
	WriteFileLine(f, szTimeFmt);
	WriteFileLine(f, 
	"-- Query:\n\
	-- %s\n\
	-- ------------------------------------------------------------------------------------------\n", g_szLastQuery);
	WriteFileLine(f, "-- Results: \n");
	
	WriteFileLine(f, "INSERT INTO `My Table` ( `steamid`, `value` ) VALUES");
	
	int iCount = hResult.RowCount;
	int iCurrentFetchIndex;
	while(hResult.FetchRow())
	{
		hResult.FetchString(0, szPlayerAuthId, sizeof szPlayerAuthId);
		hResult.FetchString(1, szValue, sizeof szValue);
		
		WriteFileLine(f, "( '%d', '%s' )%s", GetSteamAccountIDFromSteamID(szPlayerAuthId), szValue, ++iCurrentFetchIndex != iCount ? "," : ";");
		//PrintToServer("MoreRows %d", hResult.MoreRows);
	}
	
	WriteFileLine(f, "-- End.");
	
	delete f;
	
	PrintMessage("Dumped %d rows to file: %s", iCount, szFile);
}

void GetFileName(char[] szFile, int iSize)
{
	//FormatEx(szFileName, iSize, "%04d_cookiedump.txt", g_iDumpFileNumber);
	
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof szPath, "cookiedump");
	
	PrintMessage(szPath);
	
	if(!DirExists(szPath))
	{
		CreateDirectory(szPath, 0);
	}
	
	do
	{
		FormatEx(szFile, iSize, "%s/%04d_cookiedump.txt", szPath, ++g_iDumpFileNumber);
	}
	
	while (FileExists(szFile));
}

int GetSteamAccountIDFromSteamID(char[] szSteamIDOriginal)
{
	char szSteamID[35];
	strcopy(szSteamID, sizeof szSteamID, szSteamIDOriginal);
	
	ReplaceStringEx(szSteamID, sizeof szSteamID, "STEAM_", "");
	
	char szStringParts[3][20];
	// STEAM_X:Y:Z
	// 0 - X - Universe
	// 1 - Y - Type
	// 2 - Z - Account
	ExplodeString(szSteamID, ":", szStringParts, sizeof szStringParts, sizeof szStringParts[], true);
	
	int Y = StringToInt(szStringParts[1]);
	int Z = StringToInt(szStringParts[2]);
	
	return ( Z * 2 + Y );
}

bool CheckQuery(DBResultSet hResults, const char[] szError)
{
	if(!hResults)
	{
		LogMessage("Results handle is null, Error: %s", szError);
		return false;
	}
	
	if(szError[0])
	{
		LogMessage("SQL Query Error: %s", szError);
		return false;
	}
	
	return true;
}

void PrintMessage(char[] szMessage, any:...)
{
	char szBuffer[512];
	VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
	
	switch(ConVar_PrintMethod.IntValue)
	{
		case 0:
		{
			return;
		}
		
		case 1:
		{
			PrintToServer(szBuffer);
		}
		
		case 2:
		{
			LogMessage(szBuffer);
		}
	}
}