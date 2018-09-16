#include <amxmodx>
#include <amxmisc>
#include <sqlx>

new Handle:g_hSqlHandle
new g_szQuery[128]

enum _:SQL_DATA
{
	HOST,
	USER,
	PASS,
	DB_NAME,
	TABLE_NAME,
	STEAM_ID_ENTRY_IN_TABLE
};

new const g_szSqlAccessInfo[SQL_DATA][] = {
	"192.168.0.2",
	"Khalid",
	"811811",
	"steamid",
	"steamid",
	"steamid"
};

public plugin_init() {
	register_plugin("SteamId Checker", "1.0", "Khalid");
	
	g_hSqlHandle = SQL_MakeDbTuple(g_szSqlAccessInfo[HOST], g_szSqlAccessInfo[USER], g_szSqlAccessInfo[PASS], g_szSqlAccessInfo[DB_NAME]);
	
	if(g_hSqlHandle == Empty_Handle)
	{
		set_fail_state("Could not connect to SQL database.");
	}
}

public plugin_end()
{
	SQL_FreeHandle(g_hSqlHandle);
}

public client_authorized(id)
{
	new szAuthId[35]; get_user_authid(id, szAuthId, charsmax(szAuthId));
	
	formatex(g_szQuery, charsmax(g_szQuery), "SELECT %s FROM %s WHERE %s = '%s'", g_szSqlAccessInfo[STEAM_ID_ENTRY_IN_TABLE], g_szSqlAccessInfo[TABLE_NAME], g_szSqlAccessInfo[STEAM_ID_ENTRY_IN_TABLE], szAuthId);
	
	new iData[1]; iData[0] = id
	SQL_ThreadQuery(g_hSqlHandle, "CheckSteamIdQuery", g_szQuery, iData, 1);
}

public CheckSteamIdQuery(iFailState, Handle:hQuery, szError[], iErrNum, iData[], iDataSize)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("SQL ERROR #%d: %s", iErrNum, szError);
			set_fail_state("Failed to connect to SQL server while executing query");
			
			return;
		}
		
		case TQUERY_QUERY_FAILED:
		{
			log_amx("Query Failed");
			log_amx("SQL ERROR #%d: %s", iErrNum, szError);
			return;
		}
	}
	
	if(iErrNum)
	{
		log_amx("SQL ERROR(2) Error #%d: %s", iErrNum, szError);
		return;
	}
	
	if(!SQL_NumResults(hQuery))
	{
		server_cmd("kick #%d ^"You didn't register at the website^"", get_user_userid(iData[0]));
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang1033{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
