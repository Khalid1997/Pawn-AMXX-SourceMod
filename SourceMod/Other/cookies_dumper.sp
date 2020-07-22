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

char g_szLastQuery[512];

ConVar ConVar_PrintMethod;

int g_iDumpFileNumber = 0;

#define PrintMessage PrintToConsole

public void OnPluginStart()
{
	ConVar_PrintMethod = CreateConVar("cookie_dump_printmode", "1", "0 - Print Nothing; 1 - Print on console; 2 - Print in logs");
	
	RegAdminCmd("cookies_list", ServerCmd_ListCookies, ADMFLAG_ROOT);
	RegAdminCmd("cookies_dump", ServerCmd_Dump, ADMFLAG_ROOT, "<cookieid> - Dumps all data to a MySQL file format");
	
	//ConnectToSQLiteDatabase();
}

Database ConnectToSQLiteDatabase()
{
	if(!LibraryExists("clientprefs"))
	{
		SetFailState("Plugin encountered fatal error (1)");
		return null;
	}
	
	char error[PLATFORM_MAX_PATH];
	Database hSQL = SQL_Connect("clientprefs", true, error, sizeof(error));

	if (hSQL == INVALID_HANDLE)
	{
		SetFailState("Plugin encountered fatal error (2): %s", error);
		return null;
	}
	
	return hSQL;
}

public void OnPluginEnd()
{
	
}

public Action ServerCmd_ListCookies(int client, int args)
{
	Database hSQL = ConnectToSQLiteDatabase();
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "SELECT `id`, `access`, `name`, `description` FROM `sm_cookies`");
	hSQL.Query(SQLCallback_ListCookies, g_szLastQuery, client);
	
	return Plugin_Handled;
}

public void SQLCallback_ListCookies(Database hSQL, DBResultSet hResult, const char[] szError, int client)
{
	if(!CheckQuery(hResult, szError))
	{
		delete hSQL;
		return;
	}
	
	int iCookieID, iAccess, i;
	char szName[30], szDescription[255], szAccess[50];
	
	PrintToConsole(client, "Listing Cookies:");
	PrintToConsole(client, "#. <Cookie ID> <Cookie Name> - <Access> - <Description>");
	
	while(hResult.FetchRow())
	{
		iCookieID = hResult.FetchInt(0);
		iAccess = hResult.FetchInt(1);
		
		hResult.FetchString(2, szName, sizeof szName);
		hResult.FetchString(3, szDescription, sizeof szDescription);
		
		ConvertAccess(iAccess, szAccess, sizeof szAccess);
		PrintToConsole(client, "%2d. %4d %31s - %30s - %s", ++i, iCookieID, szName, szAccess, szDescription);
	}
	
	delete hSQL;
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

public Action ServerCmd_Dump(int client, int args)
{
	if(args < 1)
	{
		PrintToServer("Missing arguments");
		return Plugin_Handled;
	}
	
	Database hSQL = ConnectToSQLiteDatabase();
	
	char szArg[5];
	GetCmdArg(1, szArg, sizeof szArg);
	
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "SELECT `player`,`value` FROM `sm_cookie_cache` WHERE `cookie_id` = '%s'", szArg);
	hSQL.Query(SQLCallback_DumpCookiesToFile, g_szLastQuery, client);
	
	return Plugin_Handled;
}

public void SQLCallback_DumpCookiesToFile(Database hSQL, DBResultSet hResult, const char[] szError, int client)
{
	if(!CheckQuery(hResult, szError))
	{
		delete hSQL;
		return;
	}
	
	char szPlayerAuthId[65], szValue[100];
	
	if(!(hResult.RowCount))
	{
		PrintMessage(client, "No Results to dump.");
		return;
	}
	
	char szFile[PLATFORM_MAX_PATH];
	GetFileName(szFile, sizeof szFile, client);
	
	File f = OpenFile(szFile, "a+");
	
	if(f == INVALID_HANDLE)
	{
		PrintMessage(client, "Failed to make file");
		
		delete hSQL;
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
	
	delete hSQL;
	
	PrintMessage(client, "Dumped %d rows to file: %s", iCount, szFile);
}

void GetFileName(char[] szFile, int iSize, int client)
{
	//FormatEx(szFileName, iSize, "%04d_cookiedump.txt", g_iDumpFileNumber);
	
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof szPath, "cookiedump");
	
	
	
	if(!DirExists(szPath))
	{
		CreateDirectory(szPath, 0);
	}
	
	do
	{
		FormatEx(szFile, iSize, "%s/%04d_cookiedump.txt", szPath, ++g_iDumpFileNumber);
	}
	
	while (FileExists(szFile));
	
	PrintMessage(client, szFile);
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
/*
void PrintMessage(int client, char[] szMessage, any ...)
{
	char szBuffer[512];
	VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
	
	PrintToConsole(client, szMessage);
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
}*/