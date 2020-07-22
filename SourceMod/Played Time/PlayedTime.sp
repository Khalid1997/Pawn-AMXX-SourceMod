#pragma semicolon 1

#define DEBUG

#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Played Time",
	author = "Khalid",
	description = "",
	version = PLUGIN_VERSION,
	url = "No"
};

bool g_bLate = false;

#define METHOD_MOTD 1
#define METHOD_MENU 2

#define TOP_TIME_METHOD	METHOD_MENU
//#define TOP_WEB

#define WEBSITE 		"http://khalid14.site.nfoservers.com/time.php"
#define REDIR_WEBSITE	"http://dubaigamerz.site.nfoservers.com/redirect/redirect.php"

#define TOP_NUMBER 			15

char g_szPrefix[] =	"\x04[Played Time]";


/* Time unit types for get_time_length() */
enum 
{
    timeunit_seconds = 0,
    timeunit_minutes,
    timeunit_hours,
    timeunit_days,
    timeunit_weeks,
};

// seconds are in each time unit
#define SECONDS_IN_MINUTE 60
#define SECONDS_IN_HOUR   3600
#define SECONDS_IN_DAY    86400
#define SECONDS_IN_WEEK   604800


char g_szTimeCommands[][] = {
	"!my_time",
	"/my_time",
	"my_time",
	"!mytime",
	"/mytime",
	"mytime",
	"!time",
	"/time",
	"time"
};

enum
{
	ADMCMD_GET_TIME,
	ADMCMD_SET_TIME
};

char g_szAdminCmd[][] = {
	"sm_get_time",
	"sm_set_time"
};

enum
{
	TIME_TABLE_NAME,
	TIME_NAME_COLUMN,
	TIME_TIME_COLUMN,
	TIME_STEAMID_COLUMN,
	TIME_LASTJOIN_TIMESTAMP,
	TIME_STATUS
};

char g_szTimeTable[][] = {
	"played_time",
	"name",
	"played_time",
	"steamid",
	"lastjoin",
	"player_status"
};

enum TimeTable
{
	TIME_SET,
	TIME_GET
};

int g_iPlayedTime[MAXPLAYERS] = { 0, ... };
bool g_bGotTime[MAXPLAYERS] = { false, ... };
Database g_hSQL = null;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szErr, int iErrMax)
{
	CreateNative("PT_GetClientPlayedTime", Native_GetTime);
	CreateNative("PT_SetClientPlayedTime", Native_SetTime);
	//CreateNative("JBShop_SetCredits", Native_SetCredits);
	
	//CreateGlobalForward("PT_OnPlayerConnect_GetTime",  , ET_Single, ET_Single)
	//CreateGlobalForward("PT_OnPlayerDisconnect_SetTime",  , ET_Single, ET_Single)
	
	g_bLate = bLate;
	
	return APLRes_Success;
}

public int Native_GetTime(Handle hPlugin, int argc)
{
	int client;
	return g_iPlayedTime[ ( client = GetNativeCell(1) ) ] + ( GetNativeCell(2) ? 0 : RoundFloat( GetClientTime(client) ) );
}

public int Native_SetTime(Handle hPlugin, int argc)
{
	
}

public void OnPluginStart()
{
	AddCommandListener(OnClientSay, "say");
	AddCommandListener(OnClientSay, "say_team");
	
	RegConsoleCmd(g_szAdminCmd[ADMCMD_GET_TIME], AdminGetTime, "< name - #userid - @(something) > - Gets specific player(s) time");
	RegAdminCmd(g_szAdminCmd[ADMCMD_SET_TIME], AdminSetTime, ADMFLAG_ROOT, "- Gets specific player(s) played time");
	
	CreateSQLTable();
	
	//HookEvent("player_connect", OnPlayerConnect);
	HookEvent("player_disconnect", OnPlayerDisconnect);	// Use events because map change doesnt reset time in server.
}

public void OnPluginEnd()
{
	CloseHandle(g_hSQL);
}

public Action AdminGetTime(int client, int iArgC)
{
	char szTargetArg[MAX_NAME_LENGTH];
	char szTargetName[MAX_NAME_LENGTH]; 
	int iTargetArray[MAXPLAYERS], iTargetsCount;
	bool bDump;
	
	if(iArgC < 2)
	{
		/*for(new i = 1, j = 1, String:szClientName[MAX_NAME_LENGTH]; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				GetClientName(i, szClientName, sizeof szClientName);
				ReplyToCommand(client, "%2d. %-32s %d minutes", j++, szClientName, g_iPlayedTime[i]);
			}
		}*/
		
		szTargetName = "everyone";
		for (int i = 1, j; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				iTargetArray[j++] = i;
				iTargetsCount++;
			}
		}
	}
	
	else iTargetsCount = ProcessTargetString(szTargetArg, client, iTargetArray, 
	sizeof iTargetArray, COMMAND_FILTER_NO_BOTS, szTargetName, sizeof szTargetName, bDump);
	
	if(iTargetsCount < 1)
	{
		switch(iTargetsCount)
		{
			case COMMAND_TARGET_NONE:			ReplyToCommand(client, "- Fail: No targets found.");
			case COMMAND_TARGET_NOT_IN_GAME:	ReplyToCommand(client, "- Fail: Client is not fully connected yet.");
			case COMMAND_TARGET_AMBIGUOUS:		ReplyToCommand(client, "- Fail: Partial name had too many targets");
			case COMMAND_TARGET_NOT_HUMAN:		ReplyToCommand(client, "- Fail: Target is a bot.");
			case COMMAND_TARGET_IMMUNE:			ReplyToCommand(client, "- Fail: taget is immune to this command.");
		}
		
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "* Listing played time for %s", szTargetName);
	
	for (int i, iTarget; i < iTargetsCount; i++)
	{
		iTarget = iTargetArray[i];
		GetClientName(iTarget, szTargetName, sizeof szTargetName);
		ReplyToCommand(client, "%2d. %s %33d minutes", i + 1, szTargetName, g_iPlayedTime[iTarget]);
	}
		
	return Plugin_Handled;
}

enum TimeActions
{
	TA_SET,
	TA_ADD,
	TA_TAKE
}

public Action AdminSetTime(int client, int iArgC)
{
	if(iArgC < 2)
	{
		ReplyToCommand(client, "- Gets specific player(s) played time\n\
		- Usage: (name | #userid | @<something)> <action arg or (time if set)> <time>\n\
		action arg can be one of the following: (+, add, give), (-, take, subtract), (set) or (direcly type the time to set)");
		return Plugin_Handled;
	}
	
	char szActionArg[12], szTimeArg[32], szTargetArg[MAX_NAME_LENGTH];
	TimeActions iAction;
	char szPreposition[6], szActionName[16];
	GetCmdArg(2, szActionArg, sizeof szActionArg);
	
	if(IsStringNumber(szActionArg, sizeof szActionArg))
	{
		iAction = TA_SET;
		strcopy(szTimeArg, sizeof szTimeArg, szActionArg);
		szPreposition = "for";
		szActionName = "set";
	}
	
	else
	{
		if( StrEqual(szActionArg, "+") || StrEqual(szActionArg, "add", false) || StrEqual(szActionArg, "give", false) )
		{
			szPreposition = "to";
			szActionName = "add";
			iAction = TA_ADD;
		}
	
		else if(StrEqual(szActionArg, "-") || StrEqual(szActionArg, "take", false) || StrEqual(szActionArg, "subtract", false) )
		{
			szPreposition = "from";
			szActionName = "take";
			iAction = TA_TAKE;
		}
		
		else if (StrEqual(szActionArg, "set"))
		{
			szPreposition = "for";
			szActionName = "set";
			iAction = TA_SET;
		}
		
		else
		{
			ReplyToCommand(client, "* Invalid Action Arg. Use (+, add, give), (-, take, subtract) or set as action args");
			return Plugin_Handled;
		}
		
		
		GetCmdArg(3, szTimeArg, sizeof szTimeArg);
	}
	
	GetCmdArg(1, szTargetArg, sizeof szTargetArg);
	char szTargetName[MAX_NAME_LENGTH];
	int iTargetArray[MAXPLAYERS];
	bool bDump;
	int iTargetsCount = ProcessTargetString(szTargetArg, client, iTargetArray, sizeof iTargetArray, COMMAND_FILTER_NO_BOTS, szTargetName, sizeof szTargetName, bDump);
	if(iTargetsCount < 1)
	{
		switch(iTargetsCount)
		{
			case COMMAND_TARGET_NONE:			ReplyToCommand(client, "- Fail: No targets found.");
			case COMMAND_TARGET_NOT_IN_GAME:	ReplyToCommand(client, "- Fail: Client is not fully connected yet.");
			case COMMAND_TARGET_AMBIGUOUS:		ReplyToCommand(client, "- Fail: Partial name had too many targets");
			case COMMAND_TARGET_NOT_HUMAN:		ReplyToCommand(client, "- Fail: Target is a bot.");
			case COMMAND_TARGET_IMMUNE:			ReplyToCommand(client, "- Fail: taget is immune to this command.");
		}
		
		return Plugin_Handled;
	}
	
	int iTime = StringToInt(szTimeArg);
	
	if(iTime < 0)
	{
		ReplyToCommand(client, "- Cannot use negative amount.");
		return Plugin_Handled;
	}
	
	for (int i, iTargetId, iTimeChange = iTime * 60/*, szTargetName[MAX_NAME_LENGTH]*/; i < iTargetsCount; i++)
	{
		iTargetId = iTargetArray[i];
		switch(iAction)
		{
			case TA_TAKE:
			{
				if(g_iPlayedTime[iTargetId] < iTime)	g_iPlayedTime[iTargetId] = 0;
				else 									g_iPlayedTime[iTargetId] -= iTimeChange;
			}
			
			case TA_ADD:								g_iPlayedTime[iTargetId] += iTimeChange;
			case TA_SET:								g_iPlayedTime[iTargetId] = iTimeChange;
		}
	}
	
	//new String:szTag[35];
	char szAdminName[MAX_NAME_LENGTH];
	//FormatEx(szTag, sizeof szTag, " \x04%s", g_szPrefix);
	GetClientName(client, szAdminName, sizeof szAdminName);
	
	if(iAction == TA_SET)
	{
		PrintToChat(client, " %s \x01ADMIN \x03%s\x01: set %s \x07%s\x01%s  played time to \x05%d \x01minutes", g_szPrefix, szAdminName, iTargetsCount > 1 ? "'" : "'s", szTargetName, iTargetsCount > 1 ? "team" : "player", iTime );
	}
	else	PrintToChat(client, " %s \x01ADMIN \x03%s\x01: %s \x05%d \x01minutes %s %s \x07%s\x01%s played time.", g_szPrefix, szAdminName, szActionName, iTime, szPreposition, iTargetsCount > 1 ? "team" : "player", szTargetName, iTargetsCount > 1 ? "'" : "'s");
	
	return Plugin_Handled;
}

public Action OnClientSay(int client, char[] szCmd, int iArgC)
{
	char szSaid[20];
	GetCmdArg(1, szSaid, sizeof szSaid);
	
	for (int i; i < sizeof g_szTimeCommands; i++)
	{
		if (StrEqual(g_szTimeCommands[i], szSaid, false))
		{
			ShowPlayerTime(client);
		}
	}

	if( StrEqual(szSaid[1], "toptime" ) )
	{
		#if !defined TOP_WEB
		/*
		ReplaceString(szSaid, sizeof szSaid, "/top", "", false); ReplaceString(szSaid, sizeof(szSaid), "_time", "", false);
		
		if(!IsStringNumber(szSaid, sizeof szSaid))		// If it has more other words than /top*_time
		{
			return;
		}*/
		
		PrintToChat(client, "* Showing Top15");
		SendTopQuery(GetClientUserId(client));
		#else
		ShowTopMotd(client);
		#endif
	}
}

stock void ShowTopMotd(int client)
{
	char szTopMotd[1024];
	FormatEx(szTopMotd, sizeof szTopMotd, "%s?web=%s&fullsize=1", REDIR_WEBSITE, WEBSITE);
	ShowMOTDPanel(client, "Top Time", szTopMotd, MOTDPANEL_TYPE_URL);
}

#if !defined TOP_WEB
stock void SendTopQuery(int data)
{
	char szQuery[256];
	FormatEx(szQuery, sizeof szQuery, "SELECT `%s`,`%s` FROM `%s` ORDER BY `%s` DESC LIMIT 15", g_szTimeTable[TIME_NAME_COLUMN], g_szTimeTable[TIME_TIME_COLUMN],
																								g_szTimeTable[TIME_TABLE_NAME], g_szTimeTable[TIME_TIME_COLUMN]);
	SQL_TQuery(g_hSQL, SQLQuery_FormatMotd, szQuery, data);
}
#endif

void ShowPlayerTime(int client)
{
	//FormatPlayerTime(client, szMsg, sizeof szMsg);
	int iSecs = RoundFloat(GetClientTime(client));
	int iTotal = iSecs + g_iPlayedTime[client];
	PrintToChat(client, " %s \x01You have been playing for \x05%d \x01minute(s) and \x05%d \x01second(s).", g_szPrefix, iSecs / 60, iSecs % 60 );
	PrintToChat(client, " %s \x01Your total played time is \x05%d \x01minute(s) and \x05%d \x01second(s).", g_szPrefix, iTotal / 60, iTotal % 60 );
}

public void OnPlayerDisconnect(Event hEvent, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!client)
	{
		return;
	}
	
	if(IsFakeClient(client))
	{
		return;
	}
	
	TimeFromSQL( client, TIME_SET, g_iPlayedTime[client] + RoundFloat( GetClientTime(client) ) );
	g_iPlayedTime[client] = 0;
	g_bGotTime[client] = false;
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	TimeFromSQL(client, TIME_GET);
}

/*

public OnPlayerConnect(Event:hEvent, String:szEventName[], bool:dontBroadcast)
{
	if(GetEventInt(hEvent, "bot"))
	{
		PrintToServer("Bot");
		return;
	}
	
	new iUserId = GetEventInt(hEvent, "userid");
	PrintToServer("UserId: %d", iUserId);
	
	new client = GetClientOfUserId(iUserId);
	
	new String:szAuthId[35], String:szClientName[MAX_NAME_LENGTH];
	GetEventString(hEvent, "networkid", szAuthId, sizeof szAuthId);
	GetEventString(hEvent, "name", szClientName, sizeof szClientName);
	
	PrintToServer("NetworkId : %s << >> Name : %s", szAuthId, szClientName);
	
	TimeFromSQL(client, TIME_GET, 0, szAuthId, szClientName);
}*/

/* -------------------------------------------------------------------------------------------------------------------
   -------------------------------------------------------------------------------------------------------------------
   ------------------------------------------------------------------------------------------------------------------- */

public void SQLCallback_ConnectToDB(Handle owner, Handle database, char[] szError, any data)
{
	
	g_hSQL = view_as<Database>(database);
	
	if(g_hSQL == null)
	{
		SetFailState("[Played Time] SQL database failed: %s", szError);
		return;
	}
	
	char szQuery[256];
	FormatEx(szQuery, sizeof szQuery, "CREATE TABLE IF NOT EXISTS `%s` (%s VARCHAR(%d) NOT NULL, %s VARCHAR(35) NOT NULL, %s INT(32), %s INT(32), %s INT(32))", 
		g_szTimeTable[TIME_TABLE_NAME], 
		g_szTimeTable[TIME_NAME_COLUMN], 
		MAX_NAME_LENGTH,
		g_szTimeTable[TIME_STEAMID_COLUMN], 
		g_szTimeTable[TIME_TIME_COLUMN],
		g_szTimeTable[TIME_LASTJOIN_TIMESTAMP], g_szTimeTable[TIME_STATUS]);
		
	SQL_TQuery(g_hSQL, SQLCallback_CreateTable, szQuery);
}

public void SQLCallback_CreateTable(Handle owner, Handle handle, char[] szError, any data)
{
	if(szError[0])
	{
		LogError("Could not create table");
		return;
	}
	
	if(g_bLate)
	{
		g_bLate = false;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				continue;
			}
			
			OnClientPostAdminCheck(i);
		}
	}
}

void CreateSQLTable()
{
	if(!SQL_CheckConfig("played_time"))
	{
		SetFailState("Please add database configuration to Database.cfg");
		return;
	}
	
	SQL_TConnect(SQLCallback_ConnectToDB, "played_time");
}

void TimeFromSQL(int client, TimeTable iGetOrSet, int iSetValue = 0, char szAuthId[35] = "", char szClientName[MAX_NAME_LENGTH] = "")
{
	char szQuery[256];
	//new String:szClientName[MAX_NAME_LENGTH];
	
	if(!szAuthId[0])
	{
		GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	}
	
	ReplaceString(szAuthId, sizeof szAuthId, "STEAM_0", "STEAM_1");
	
	if(!szClientName[0])
	{
		GetClientName(client, szClientName, sizeof szClientName);
	}
	//GetClientName(client, szClientName, sizeof szClientName);
			
	switch(iGetOrSet)
	{
		case TIME_SET:
		{
			if(!g_bGotTime[client])
			{
				return;
			}
			
			char szEscapedName[MAX_NAME_LENGTH * 3];
			SQL_EscapeString(g_hSQL, szClientName, szEscapedName, sizeof szEscapedName);
		
			FormatEx(szQuery, sizeof szQuery, "UPDATE `%s` SET `%s` = '%d', `%s` = '%s', `%s` = '%d' WHERE `%s` = '%s'",
				g_szTimeTable[TIME_TABLE_NAME],
				g_szTimeTable[TIME_TIME_COLUMN],
				iSetValue,
				g_szTimeTable[TIME_NAME_COLUMN],
				szEscapedName,
				g_szTimeTable[TIME_STATUS],
				GetUserStatus(client),
				g_szTimeTable[TIME_STEAMID_COLUMN],
				szAuthId);
			
			//PrintToServer(szQuery);
			SQL_TQuery(g_hSQL, DumpSQLCallBack, szQuery, 3);
		}
		
		case TIME_GET:
		{
			FormatEx(szQuery, sizeof szQuery, "SELECT `%s` FROM `%s` WHERE `%s` = '%s'",
				g_szTimeTable[TIME_TIME_COLUMN], g_szTimeTable[TIME_TABLE_NAME], 
				g_szTimeTable[TIME_STEAMID_COLUMN], szAuthId);
			
			//PrintToServer(szQuery);
			Handle hData = CreateDataPack();
			
			WritePackCell(hData, GetClientUserId(client));
			WritePackString(hData, szAuthId);
			WritePackString(hData, szClientName);
			
			ResetPack(hData);
			
			SQL_TQuery(g_hSQL, SQLQuery_GetTime, szQuery, hData);
		}
	}																	
}

public void SQLQuery_GetTime(Handle owner, Handle hHandle , char[] szError, Handle hData)
{
	ResetPack(hData);
	
	int client; 
	char szClientName[MAX_NAME_LENGTH], szAuthId[35];
	
	client = GetClientOfUserId(ReadPackCell(hData))
	
	if(!client)
	{
		return;
	}
	
	if(szError[0])
	{
		LogError("[Played Time] Error getting time for client (%d): %s", client, szError);
		CloseHandle(hData);
		
		return;
	}
	
	ReadPackString(hData, szAuthId, sizeof szAuthId);
	ReadPackString(hData, szClientName, sizeof szClientName);

	CloseHandle(hData);
		
	//GetClientName(client, szClientName, sizeof szClientName);
	//GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	
	if(SQL_FetchRow(hHandle))
	{
		g_iPlayedTime[client] = SQL_FetchInt(hHandle, 0);
		UpdateTimeStamp(szAuthId);
		g_bGotTime[client] = true;
	}
	
	else
	{
		char szQuery[1024];
	
		char szEscapedName[MAX_NAME_LENGTH * 3];
		SQL_EscapeString(g_hSQL, szClientName, szEscapedName, sizeof szEscapedName);
	
		FormatEx(szQuery, sizeof szQuery, "INSERT INTO `%s` ( %s, %s, %s, %s, %s ) VALUES ( '%s', '%s', %d, %d, %d )",
			g_szTimeTable[TIME_TABLE_NAME],
			
			g_szTimeTable[TIME_NAME_COLUMN], 
			g_szTimeTable[TIME_STEAMID_COLUMN], 
			g_szTimeTable[TIME_TIME_COLUMN],
			g_szTimeTable[TIME_LASTJOIN_TIMESTAMP], 
			g_szTimeTable[TIME_STATUS],
			
			szEscapedName, szAuthId, 0, GetTime(), GetUserStatus(client));
			
		//PrintToServer(szQuery);
		g_bGotTime[client] = false;
		g_iPlayedTime[client] = 0;
		SQL_TQuery(g_hSQL, SQLCallback_OnInsertTime, szQuery, GetClientUserId(client));
	}
	
	//PrintToServer("[Played Time] Got %d for %s", g_iPlayedTime[client], szClientName);
}

public void SQLCallback_OnInsertTime(Handle hOwner, Handle hHandle, char[] szError, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
	{
		return;
	}
	
	if(szError[0])
	{
		LogError("[Played Time] Error getting time for client (%d): %s", client, szError);
		return;
	}
	
	g_iPlayedTime[client] = 0;
	g_bGotTime[client] = true;
}

int GetUserStatus(int client)
{
	int iFlags = GetUserFlagBits(client);
	
	if(iFlags & ADMFLAG_ROOT)
	{
		// Owner
		return 1;
	}
	
	if(iFlags & ADMFLAG_BAN)
	{
		// Admin
		return 2;
	}
	
	return 0;
}

void UpdateTimeStamp(char[] szAuthId)
{
	char szQuery[256];
	FormatEx(szQuery, sizeof szQuery, "UPDATE `%s` SET `%s` = '%d' WHERE `%s` = '%s'", g_szTimeTable[TIME_TABLE_NAME], g_szTimeTable[TIME_LASTJOIN_TIMESTAMP], GetTime(), g_szTimeTable[TIME_STEAMID_COLUMN], szAuthId);
	//PrintToServer(szQuery);
	SQL_TQuery(g_hSQL, DumpSQLCallBack, szQuery, 2);
}

stock int IsStringNumber(char[] szString, int iLen)
{
	TrimString(szString);
	int i;
	if(szString[i] != '-')
	{
		if(!IsCharNumeric(szString[i]))
		{
			return 0;
		}
	}
	
	else i = 1;
	
	for(; i < iLen; i++)
	{
		if(szString[i] == 0)
		{
			break;
		}
		
		if(!IsCharNumeric(szString[i]))
		{
			return 0;
		}
	}
	
	return 1;
}

#if !defined TOP_WEB
public void SQLQuery_FormatMotd(Handle hOwner, Handle hHandle, char[] szError, int data)
{
	if(szError[0])
	{
		LogError("SQL Error in top formating: %s", szError);
		return;
	}
	
	int client = GetClientOfUserId(data);
	
	if(!client)
	{
		return;
	}
	
	#if TOP_TIME_METHOD == METHOD_MOTD
	char szMotd[1024];
	int iLen;
	
	iLen = FormatEx(szMotd, sizeof(szMotd), "<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}\
	table{border-style:solid;border-width:1px;border-color:#FFFFFF;font-size:13px}\
	</STYLE>\
	<body><table align=center width=100%% cellpadding=2 cellspacing=0");
	iLen += FormatEx(szMotd[iLen], sizeof(szMotd) - iLen, "<tr align=center bgcolor=#52697B><th width=4%% > # <th width=24%%> Name <th  width=24%%> Minutes Played ");	
	
	int j;
	char szClientName[MAX_NAME_LENGTH]
	int iTime;
	while(SQL_FetchRow(hHandle))
	{
		SQL_FetchString(hHandle, 0, szClientName, sizeof szClientName);
		iTime = SQL_FetchInt(hHandle, 1);
		
		iLen += FormatEx(szMotd[iLen], sizeof(szMotd) - iLen, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %d ", ++j, szClientName, iTime);
		//PrintToServer("#%d", j);
	}
	
	iLen += FormatEx(szMotd[iLen], sizeof(szMotd) - iLen, "</body></font></pre>");
	
	Handle f = OpenFile("played_time_top.txt", "w");
	WriteFileString(f, szMotd, true);
	CloseHandle(f);
	
	ShowMOTDPanel(client, "Top15 Time", "played_time_top.txt", MOTDPANEL_TYPE_TEXT);
	#endif
	
	#if TOP_TIME_METHOD == METHOD_MENU
	char szPlayerName[MAX_NAME_LENGTH];
	int iPlayedTime;
	char szFormattedItem[60];
	
	Menu hTopMenu = new Menu(MenuHandler_TopMenu, MENU_ACTIONS_DEFAULT);
	hTopMenu.SetTitle("Top Time");
	char szTimeString[33];
	
	int iNumber;
	
	while(SQL_FetchRow(hHandle))
	{
		
		SQL_FetchString(hHandle, 0, szPlayerName, sizeof szPlayerName);
		iPlayedTime = SQL_FetchInt(hHandle, 1);
		GetTimeLength(iPlayedTime, timeunit_seconds, szTimeString, sizeof szTimeString);
		
		FormatEx(szFormattedItem, sizeof szFormattedItem, "#%d - %s [%s]", ++iNumber, szPlayerName, szTimeString);
		
		hTopMenu.AddItem("", szFormattedItem);
	}
	
	hTopMenu.Display(client, MENU_TIME_FOREVER);
	#endif
}
#endif

public int MenuHandler_TopMenu(Menu hMenu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
}

public void DumpSQLCallBack(Handle owner, Handle hHandle, char[] szError, int queryId)
{
	if (owner == null)
	{
		LogError("Failed to connect to database (%d): %s", queryId, szError);
		return;
	}
	
	if (hHandle == null)
	{
		LogError("Result Set Error (%d): %s", queryId, szError);
		return;
	}
	
	if(szError[0])
	{
		LogError("Query Error: %s", szError);
		return;
	}
}

/* Stock by Brad */
stock void GetTimeLength(int unitCnt, int type, char[] output, int outputLen)
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
            case timeunit_seconds: secondCnt = unitCnt;
            case timeunit_minutes: secondCnt = unitCnt * SECONDS_IN_MINUTE;
            case timeunit_hours:   secondCnt = unitCnt * SECONDS_IN_HOUR;
            case timeunit_days:    secondCnt = unitCnt * SECONDS_IN_DAY;
            case timeunit_weeks:   secondCnt = unitCnt * SECONDS_IN_WEEK;
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
        char timeElement[5][33];

        if (weekCnt > 0)
            Format(timeElement[++maxElementIdx], sizeof timeElement[], "%d %s", weekCnt, (weekCnt == 1) ? "W" : "W");
        if (dayCnt > 0)
            Format(timeElement[++maxElementIdx], sizeof timeElement[], "%d %s", dayCnt, (dayCnt == 1) ? "D" : "D");
        if (hourCnt > 0)
            Format(timeElement[++maxElementIdx], sizeof timeElement[], "%d %s", hourCnt, (hourCnt == 1) ? "H" : "H");
        if (minuteCnt > 0)
            Format(timeElement[++maxElementIdx], sizeof timeElement[], "%d %s", minuteCnt, (minuteCnt == 1) ? "M" : "M");
        if (secondCnt > 0)
            Format(timeElement[++maxElementIdx], sizeof timeElement[], "%d %s", secondCnt, (secondCnt == 1) ? "S" : "S");

        switch(maxElementIdx)
        {
            case 0: Format(output, outputLen, "%s", timeElement[0]);
            case 1: Format(output, outputLen, "%s %s %s", timeElement[0], "and", timeElement[1]);
            case 2: Format(output, outputLen, "%s, %s %s %s", timeElement[0], timeElement[1], "and", timeElement[2]);
            case 3: Format(output, outputLen, "%s, %s, %s %s %s", timeElement[0], timeElement[1], timeElement[2], "and", timeElement[3]);
            case 4: Format(output, outputLen, "%s, %s, %s, %s %s %s", timeElement[0], timeElement[1], timeElement[2], timeElement[3], "and", timeElement[4]);
        }
    }
}