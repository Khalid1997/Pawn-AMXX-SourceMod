#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "2.00b"

#include <sourcemod>
#include <limited_features>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Limited Features API", 
	author = PLUGIN_AUTHOR, 
	description = "Adds API to allow automatic limited features", 
	version = PLUGIN_VERSION, 
	url = ""
};

#define MAX_FEATURE_NAME_LENGTH 32
#define MAX_FEATURES		15
#define MAX_QUERY_LENGTH  	512
#define MAX_ERROR_LENGTH  	512

Database g_hSql;

enum Features
{
	Feature_Id, 
	String:Feature_Name[MAX_FEATURE_NAME_LENGTH], 
	Feature_Type, 
	Feature_LastResetTime, 
	Feature_ResetTime, 
	Feature_MaxUses, 
	Feature_RequiredPlayTime
};

int g_iFeatures[MAX_FEATURES][Features];
int g_iFeaturesCount;

int g_iReturn;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int ErrMax)
{
	ConnectToSQLDatabase();
	
	CreateNative("LF_Feature_Create", Native_Feature_Create);
	CreateNative("LF_Feature_CreateEx", Native_Feature_CreateEx);
	
	CreateNative("LF_Feature_Find", Native_Feature_Find);
	CreateNative("LF_Feature_FindEx", Native_Feature_FindEx);
	
	CreateNative("LF_Feature_GetData", Native_Feature_GetData);
	CreateNative("LF_Feature_GetDataEx", Native_Feature_GetDataEx);
	
	CreateNative("LF_Client_GetFeatureData", Native_Client_GetFeatureData);
	CreateNative("LF_Client_GetFeatureDataEx", Native_Client_GetFeatureDataEx);
	
	CreateNative("LF_Client_CanActivateFeature", Native_Client_CanActivateFeature);
	CreateNative("LF_Client_CanActivateFeatureEx", Native_Client_CanActivateFeatureEx);
	
	CreateNative("LF_Client_ActivateFeature", Native_Client_ActivateFeature);
	CreateNative("LF_Client_ActivateFeatureEx", Native_Client_ActivateFeatureEx);
	
	RegPluginLibrary("limited_features");
	return APLRes_Success;
}

public int Native_Feature_Create(Handle hPlugin, int argc)
{
	char szFeature[MAX_FEATURE_NAME_LENGTH];
	GetNativeString(1, szFeature, sizeof szFeature);
	LimitType type = GetNativeCell(2);
	int iResetTime = GetNativeCell(3);
	int iMaxUses = GetNativeCell(4);
	int iReqPlayTime = GetNativeCell(5);
	Function func = GetNativeFunction(6);
	any data = GetNativeCell(7);
	
	Func_CreateLimitedFeature(szFeature, type, iResetTime, iMaxUses, iReqPlayTime, hPlugin, func, data, true);
}

public int Native_Feature_CreateEx(Handle hPlugin, int argc)
{
	char szFeature[MAX_FEATURE_NAME_LENGTH];
	GetNativeString(1, szFeature, sizeof szFeature);
	LimitType type = GetNativeCell(2);
	int iResetTime = GetNativeCell(3);
	int iMaxUses = GetNativeCell(4);
	int iReqPlayTime = GetNativeCell(5);
	
	Func_CreateLimitedFeature(szFeature, type, iResetTime, iMaxUses, iReqPlayTime, INVALID_HANDLE, NativeCallback_CreateLimitFeatureEx, 0, false);
	
	return g_iReturn;
}

public void NativeCallback_CreateLimitFeatureEx(bool bSuccess, int iFeatureId, char[] szFeature, LimitType type, any data)
{
	g_iReturn = iFeatureId;
}

public int Native_Feature_Find(Handle hPlugin, int argc)
{
	char szFeature[MAX_FEATURE_NAME_LENGTH];
	GetNativeString(1, szFeature, sizeof szFeature);
	
	int iIndex = FindFeatureIndexFromName(szFeature);
	
	Call_StartFunction(hPlugin, GetNativeFunction(2));
	{
		Call_PushCell(true);
		
		if(iIndex == -1)
		{
			Call_PushCell(-1);
			Call_PushString("");
		}
		
		else
		{
			Call_PushCell(g_iFeatures[iIndex][Feature_Id]);
			Call_PushString(g_iFeatures[iIndex][Feature_Name]);
		}
		
		Call_PushCell(GetNativeCell(3));
		Call_Finish();
	}
}

public int Native_Feature_FindEx(Handle hPlugin, int argc)
{
	char szFeature[MAX_FEATURE_NAME_LENGTH];
	GetNativeString(1, szFeature, sizeof szFeature);
	
	int iIndex = FindFeatureIndexFromName(szFeature);
	return iIndex == -1 ? -1 : g_iFeatures[iIndex][Feature_Id];
}

public int Native_Feature_GetDataEx(Handle hPlugin, int argc)
{
	int iFeatureId = GetNativeCell(1);
	int iSize = GetNativeCell(3);
	
	bool bTQuery = false;
	DataPack dp = new DataPack();
	dp.WriteCell(iFeatureId);
	dp.WriteCell(INVALID_HANDLE);
	dp.WriteFunction(NativeCallback_GetDataEx);
	dp.WriteCell(iSize);
	dp.WriteCell(bTQuery);
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Feature_GetData, bTQuery, dp);
	return g_iReturn;
}

public int Native_Feature_GetData(Handle hPlugin, int argc)
{
	int iFeatureId = GetNativeCell(1);
	
	DataPack dp = new DataPack();
	bool bTQuery = true;
	dp.WriteCell(iFeatureId);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(GetNativeFunction(2));
	dp.WriteCell(GetNativeCell(3));
	dp.WriteCell(bTQuery);
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Feature_GetData, bTQuery, dp);
	return g_iReturn;
}

public void CFE_Feature_GetData(bool bSuccess, int iFeatureId, bool bWasReset, DataPack dp)
{
	dp.Reset();
	dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	//bool bTQuery = dp.ReadCell();
	delete dp;
	
	Func_GetFeatureData(iFeatureId, hPlugin, func, data);
}

public void NativeCallback_GetDataEx(bool bSuccess, int iFeatureId, char[] szFeature, LimitType type, int iResetTime, int iLastResetTime, int iMaxUses, int iReqPlayTime, any data)
{
	// (int iFeatureId, char[] szFeatureName = "", int iFeatureNameSize = 0, LimitType &type = LT_None, 
	// int iLastResetTime = 0, int &iResetTime = 0, int &iMaxUses = 0, int &iReqPlayTime = 0);
	g_iReturn = view_as<int>(bSuccess);
	
	SetNativeString(2, szFeature, data);
	SetNativeCellRef(4, type);
	SetNativeCellRef(5, iLastResetTime);
	SetNativeCellRef(6, iResetTime);
	SetNativeCellRef(7, iMaxUses);
	SetNativeCellRef(8, iReqPlayTime);
}

public int Native_Client_GetFeatureDataEx(Handle hPlugin, int argc)
{
	int iSteamAccount = GetNativeCell(1);
	int iFeatureId = GetNativeCell(2);
	
	DataPack dp = new DataPack();
	bool bTQuery = false;
	dp.WriteCell(iFeatureId);
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(INVALID_HANDLE);
	dp.WriteFunction(NativeCallback_GetClientFeatureDataEx);
	dp.WriteCell(0);		// data
	dp.WriteCell(bTQuery);	// bTQuery
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Client_GetFeatureData, bTQuery, dp);
	
	return g_iReturn;
}

public int Native_Client_GetFeatureData(Handle hPlugin, int argc)
{
	int iSteamAccount = GetNativeCell(1);
	int iFeatureId = GetNativeCell(2);
	
	DataPack dp = new DataPack();
	bool bTQuery = true;
	dp.WriteCell(iFeatureId);
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(GetNativeCell(3));
	dp.WriteCell(GetNativeCell(4));		// data
	dp.WriteCell(bTQuery);	// bTQuery
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Client_GetFeatureData, bTQuery, dp);
}

public void CFE_Client_GetFeatureData(bool bSuccess, int iFeatureId, bool bWasReset, DataPack dp)
{
	dp.Reset();
	dp.ReadCell();
	int iSteamAccount = dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	bool bTQuery = dp.ReadCell();
	delete dp;
	
	Func_GetClientFeatureData(iSteamAccount, iFeatureId, hPlugin, func, data, bTQuery);
}

public void NativeCallback_GetClientFeatureDataEx(bool bSuccess, int iSteamAccount, int iFeatureId, LimitType type, int iUses, int iMaxUses, int iReqPlayTime, 
	int iReqPlayTimeLeft, int iClientPlayTime, any data)
{
	g_iReturn = view_as<int>(bSuccess);
	
	// (int iSteamAccount, int iFeatureId, LimitType type, int &iUses, int &iMaxUses, int &iReqPlayTime, int &iReqPlayTimeLeft, int &iClientPlayTime);
	SetNativeCellRef(3, type);
	SetNativeCellRef(4, iUses);
	SetNativeCellRef(5, iMaxUses);
	SetNativeCellRef(6, iReqPlayTime);
	SetNativeCellRef(7, iReqPlayTimeLeft);
	SetNativeCellRef(8, iClientPlayTime);
}

public int Native_Client_CanActivateFeature(Handle hPlugin, int argc)
{
	// (int iSteamAccount, int iFeatureId, LimitedFeatureActivateFailureReason reason = &LFAFR_None, int &param1 = 0, int &param2 = 0);
	int iSteamAccount = GetNativeCell(1);
	int iFeatureId = GetNativeCell(2);
	
	DataPack dp = new DataPack();
	bool bTQuery = true;
	dp.WriteCell(iFeatureId);
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(GetNativeFunction(3));
	dp.WriteCell(GetNativeCell(4));		// Data
	dp.WriteCell(bTQuery);
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Client_CanActivateFeature, bTQuery, dp);
}

public int Native_Client_CanActivateFeatureEx(Handle hPlugin, int argc)
{
	// (int iSteamAccount, int iFeatureId, LimitedFeatureActivateFailureReason reason = &LFAFR_None, int &param1 = 0, int &param2 = 0);
	int iSteamAccount = GetNativeCell(1);
	int iFeatureId = GetNativeCell(2);
	
	DataPack dp = new DataPack();
	bool bTQuery = false;
	dp.WriteCell(iFeatureId);
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(INVALID_HANDLE);
	dp.WriteFunction(NativeCallback_CanActivateFeatureEx);
	dp.WriteCell(0);		// Data
	dp.WriteCell(bTQuery);
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Client_CanActivateFeature, bTQuery, dp);
	
	return g_iReturn;
}

public void CFE_Client_CanActivateFeature(bool bSuccess, int iFeatureId, bool bWasReset, DataPack dp)
{
	dp.Reset();
	dp.ReadCell();
	int iSteamAccount = dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	bool bTQuery = dp.ReadCell();
	delete dp;
	
	Func_CanActivateFeature(iSteamAccount, iFeatureId, hPlugin, func, data, bTQuery);
}

public void NativeCallback_CanActivateFeatureEx(bool bSuccess, int iSteamAccount, int iFeatureId, bool bCanActivate, LimitedFeatureActivateFailureReason reason, int param1, int param2, any data)
{
	g_iReturn = view_as<int>(bCanActivate);
	
	SetNativeCellRef(3, reason);
	SetNativeCellRef(4, param1);
	SetNativeCellRef(5, param2);
}

public int Native_Client_ActivateFeature(Handle hPlugin, int argc)
{
	int iSteamAccount = GetNativeCell(1);
	int iFeatureId = GetNativeCell(2);
	bool bForce = GetNativeCell(3);
	
	DataPack dp = new DataPack();
	bool bTQuery = true;
	
	dp.WriteCell(iFeatureId);
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(GetNativeFunction(4));
	dp.WriteCell(bForce);
	dp.WriteCell(GetNativeCell(5));		// Data
	dp.WriteCell(bTQuery);
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Client_ActivateFeature, bTQuery, dp);
	// (int iSteamAccount, int iFeatureId, bool bForce, Handle hPlugin, LimitedFeature_ClientActivateFeatureCallback func, any data, bTQuery)
}

public int Native_Client_ActivateFeatureEx(Handle hPlugin, int argc)
{
	int iSteamAccount = GetNativeCell(1);
	int iFeatureId = GetNativeCell(2);
	bool bForce = GetNativeCell(3);
	
	DataPack dp = new DataPack();
	bool bTQuery = false;
	
	dp.WriteCell(iFeatureId);
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(INVALID_HANDLE);
	dp.WriteFunction(NativeCallback_ActivateFeature);
	dp.WriteCell(bForce);
	dp.WriteCell(0);		// Data
	dp.WriteCell(bTQuery);
	
	Func_CheckIfFeatureExpired(iFeatureId, true, INVALID_HANDLE, CFE_Client_ActivateFeature, bTQuery, dp);
	// (int iSteamAccount, int iFeatureId, bool bForce, Handle hPlugin, LimitedFeature_ClientActivateFeatureCallback func, any data, bTQuery)
	return g_iReturn;
}

public void CFE_Client_ActivateFeature(bool bSuccess, int iFeatureId, bool bWasReset, DataPack dp)
{
	dp.Reset();
	dp.ReadCell();
	int iSteamAccount = dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	bool bForce = dp.ReadCell();
	any data = dp.ReadCell();
	bool bTQuery = dp.ReadCell();
	delete dp;
	
	Func_ActivateFeature(iSteamAccount, iFeatureId, bForce, hPlugin, func, data, bTQuery);
}

public void NativeCallback_ActivateFeature(bool bSuccess, int iSteamAccount, int iFeatureId, bool bWasActivated, 
	LimitedFeatureActivateFailureReason iReason,
	int iUses, int iMaxUses, int iReqPlayTime, int iReqPlayTimeLeft, int iClientPlayTime)
{
	g_iReturn = view_as<int>(bWasActivated);
	// (int iSteamAccount, int iFeatureIndex, bool bForce, int &iUses = 0, int &iMaxUses = 0, int &iReqPlayTime = 0, 
	// int &iReqPlayTimeLeft = 0, int &iClientPlayTime = 0);
	
	SetNativeCellRef(4, iReason);
	SetNativeCellRef(5, iUses);
	SetNativeCellRef(6, iMaxUses);
	SetNativeCellRef(7, iReqPlayTime);
	SetNativeCellRef(8, iReqPlayTimeLeft);
	SetNativeCellRef(9, iClientPlayTime);
}

public void OnPluginStart()
{
	HookEvent("player_connect", Event_PlayerConnect);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public void Event_PlayerConnect(Event event, char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
	{
		return;
	}
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	char szQuery[MAX_QUERY_LENGTH];
	FormatQuery(szQuery, sizeof szQuery, "Update client time 1", "UPDATE {table_clients} SET {playtime_offset} = 0 WHERE {auth} = %d", 
		GetSteamAccountID(client));
	
	g_hSql.Query(SQLCallback_Dump, szQuery);
}

public void SQLCallback_Dump(Database owner, DBResultSet result, char[] szError, any data)
{
	if (szError[0])
	{
		LogError("Dump: %s", szError);
	}
}

public void Event_PlayerDisconnect(Event event, char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
	{
		return;
	}
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	Transaction txn = new Transaction();
	
	int iTime = RoundFloat(GetClientTime(client));
	char szQuery[MAX_QUERY_LENGTH];
	FormatQuery(szQuery, sizeof szQuery, "Update client time 1", "UPDATE {table_clients} SET {required_playtime_left} = \
		IF( ( {required_playtime_left} - (%d - {playtime_offset}) ) < 0, 0, ( {required_playtime_left} - (%d - {playtime_offset}) ) ) WHERE {auth} = %d", 
		iTime, iTime, GetSteamAccountID(client));
	txn.AddQuery(szQuery);
	FormatQuery(szQuery, sizeof szQuery, "Update client time 1", "UPDATE {table_clients} SET {playtime_offset} = 0 WHERE {auth} = %d", 
		GetSteamAccountID(client));
	txn.AddQuery(szQuery);
	
	g_hSql.Execute(txn, SQLTxnCallback_OnClientUpdate_OnSuccess, SQLTxnCallback_OnClientUpdate_OnFail);
}

public void SQLTxnCallback_OnClientUpdate_OnFail(Database db, DataPack dp, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("Update Client Error (%d): %s", failIndex, error);
}

public void SQLTxnCallback_OnClientUpdate_OnSuccess(Database db, DataPack dp, int numQueries, DBResultSet[] allresults, any[] queryData)
{
	
}

void ConnectToSQLDatabase()
{
	char szError[MAX_ERROR_LENGTH];
	g_hSql = SQL_Connect("limitedfeatures", true, szError, sizeof szError);
	
	if (g_hSql == null)
	{
		SetFailState("Connect to DB error: %s", szError);
		return;
	}
	
	char szQuery[MAX_QUERY_LENGTH];
	FormatQuery(szQuery, sizeof szQuery, "Make Feature Table", 
		"CREATE TABLE IF NOT EXISTS {table_features} ( {id} INTEGER PRIMARY KEY AUTO_INCREMENT, {feature_name} VARCHAR(32) NOT NULL UNIQUE, {feature_type} INTEGER NOT NULL, \
	{reset_time_last} INTEGER NOT NULL, {reset_time} INTEGER NOT NULL, {uses_max} INTEGER NOT NULL, {required_playtime} INTEGER );");
	DBResultSet result = SQL_Query(g_hSql, szQuery);
	
	if (result == null)
	{
		SQL_GetError(g_hSql, szError, sizeof szError);
		SetFailState("Couldnt create table: %s", szError);
	}
	
	delete result;
	RetrieveFeatures();
	
	FormatQuery(szQuery, sizeof szQuery, "Make Client Table", 
		"CREATE TABLE IF NOT EXISTS {table_clients} ( {id} INTEGER PRIMARY KEY AUTO_INCREMENT, {auth} INTEGER NOT NULL, {feature_id} INTEGER NOT NULL, \
	{uses} INTEGER DEFAULT 0, {required_playtime_left} INTEGER, {playtime_offset} INTEGER DEFAULT 0 );");
	result = SQL_Query(g_hSql, szQuery);
	
	if (result == null)
	{
		SQL_GetError(g_hSql, szError, sizeof szError);
		SetFailState("Couldnt create table2: %s", szError);
	}
	
	delete result;
}

public void SQLCallback_MakeFeaturesTable(Handle owner, Handle result, char[] szError, any data)
{
	if (result == null)
	{
		LogMessage("Error (MFT): %s", szError);
		return;
	}
}

bool RetrieveFeatures()
{
	g_iFeaturesCount = 0;
	char szQuery[MAX_QUERY_LENGTH];
	
	FormatQuery(szQuery, sizeof szQuery, "Retrive Features", 
		"SELECT {id}, {feature_name}, {feature_type}, {reset_time_last}, {reset_time}, {uses_max}, {required_playtime} FROM {table_features};");
	
	SQL_LockDatabase(g_hSql);
	DBResultSet result = SQL_Query(g_hSql, szQuery);
	SQL_UnlockDatabase(g_hSql);
	
	if (result == null)
	{
		SQL_GetError(g_hSql, szQuery, sizeof szQuery);
		LogError("Retrieve Features Ex Error: %s", szQuery);
		
		return false;
	}
	
	Fetch_RetrieveFeaturesResult(result);
	delete result;
	
	return true;
}

void Fetch_RetrieveFeaturesResult(DBResultSet result)
{
	while (SQL_FetchRow(result))
	{
		g_iFeatures[g_iFeaturesCount][Feature_Id] = SQL_FetchInt(result, 0);
		SQL_FetchString(result, 1, g_iFeatures[g_iFeaturesCount][Feature_Name], MAX_FEATURE_NAME_LENGTH);
		g_iFeatures[g_iFeaturesCount][Feature_Type] = SQL_FetchInt(result, 2);
		g_iFeatures[g_iFeaturesCount][Feature_LastResetTime] = SQL_FetchInt(result, 3);
		g_iFeatures[g_iFeaturesCount][Feature_ResetTime] = SQL_FetchInt(result, 4);
		g_iFeatures[g_iFeaturesCount][Feature_MaxUses] = SQL_FetchInt(result, 5);
		g_iFeatures[g_iFeaturesCount][Feature_RequiredPlayTime] = SQL_FetchInt(result, 6);
		
		g_iFeaturesCount++;
	}
	
	for (int i; i < g_iFeaturesCount; i++)
	{
		Func_CheckIfFeatureExpired(g_iFeatures[i][Feature_Id], true, INVALID_HANDLE, INVALID_FUNCTION, false, 0);
	}
}

bool Func_CheckIfFeatureExpired(int iFeatureId, bool bReset, Handle hPlugin, Function func, bool bTQuery, any data)
{
	int iIndexInArray = FindFeatureIndexFromId(iFeatureId); 
	PrintToServer("Check Expire: %d - %d = %d",  GetTime(), g_iFeatures[iIndexInArray][Feature_LastResetTime] + g_iFeatures[iIndexInArray][Feature_ResetTime], GetTime() - (g_iFeatures[iIndexInArray][Feature_LastResetTime] + g_iFeatures[iIndexInArray][Feature_ResetTime]));
	
	if (GetTime() >= g_iFeatures[iIndexInArray][Feature_LastResetTime] + g_iFeatures[iIndexInArray][Feature_ResetTime])
	{
		if (bReset)
		{
			Func_ResetFeature(iFeatureId, hPlugin, func, bTQuery, data);
			return true;
		}
	}
	
	if(func == INVALID_FUNCTION)
	{
		return false;
	}
	
	Call_StartFunction(hPlugin, func);
	{
		Call_PushCell(true);
		Call_PushCell(iFeatureId);
		Call_PushCell(false);
		Call_PushCell(data);
		Call_Finish();
	}
	
	return false;
}

void Func_ResetFeature(int iFeatureId, Handle hPlugin, Function func, bool bTQuery, any data)
{
	int iNewLastResetTime;
	int iIndexInArray = FindFeatureIndexFromId(iFeatureId);
	
	int iDifference = GetTime() - (g_iFeatures[iIndexInArray][Feature_LastResetTime]);
	float flMultiplier = float(iDifference) / float(g_iFeatures[iIndexInArray][Feature_ResetTime]);
	
	PrintToServer("%d -- %d -- iMultipLier %0.2f", 
		iDifference, g_iFeatures[iIndexInArray][Feature_ResetTime], flMultiplier);

	iNewLastResetTime = ( RoundToFloor(flMultiplier) * g_iFeatures[iIndexInArray][Feature_ResetTime] ) + g_iFeatures[iIndexInArray][Feature_LastResetTime];
	
	DataPack dp = new DataPack();
	dp.WriteCell(iFeatureId);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(func);
	dp.WriteCell(data);
	
	char szQuery[MAX_QUERY_LENGTH];
	FormatQuery(szQuery, sizeof szQuery, "Reset Feature", 
		"UPDATE {table_features} SET {reset_time_last} = %d WHERE {id} = %d;", iNewLastResetTime, iFeatureId);
	
	Transaction txn;
	DBResultSet result;
	
	if(bTQuery)
	{
		txn = new Transaction();
		txn.AddQuery(szQuery, iNewLastResetTime);
	}
	
	else
	{
		result = SQL_Query(g_hSql, szQuery);
		
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("ResetFeature Error: %s", szQuery);
			
			Fetch_ResetFeature(false, dp);
			return;
		}
		
		g_iFeatures[iIndexInArray][Feature_LastResetTime] = iNewLastResetTime;
		delete result;
	}
		
	FormatQuery(szQuery, sizeof szQuery, "Reset Feature", 
		"UPDATE {table_clients} SET {uses} = 0, {required_playtime_left} = %d WHERE {feature_id} = %d;", g_iFeatures[iIndexInArray][Feature_RequiredPlayTime], iFeatureId);
		
	if(bTQuery)
	{
		txn.AddQuery(szQuery);
		g_hSql.Execute(txn, SQLTxnCallback_OnResetFeature_OnSuccess, SQLTxnCallback_OnResetFeature_OnFail, dp);
	}
	
	else
	{
		result = SQL_Query(g_hSql, szQuery);
		
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("ResetFeature Error: %s", szQuery);
			Fetch_ResetFeature(false, dp);
			
			return;
		}
		
		delete result;
		
		Fetch_ResetFeature(true, dp);
	}
}

public void SQLTxnCallback_OnResetFeature_OnSuccess(Database db, DataPack dp, int numQueries, DBResultSet[] allresults, any[] queryData)
{
	dp.Reset();
	int iFeatureId = dp.ReadCell();
	
	g_iFeatures[FindFeatureIndexFromId(iFeatureId)][Feature_LastResetTime] = queryData[0];
	Fetch_ResetFeature(true, dp);
}

public void SQLTxnCallback_OnResetFeature_OnFail(Database db, DataPack dp, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	Fetch_ResetFeature(false, dp);
}

void Fetch_ResetFeature(bool bSuccess, DataPack dp)
{
	dp.Reset();
	int iFeatureId = dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	delete dp;
	
	if(func == INVALID_FUNCTION)
	{
		return;
	}
	
	Call_StartFunction(hPlugin, func);
	{
		Call_PushCell(bSuccess);
		Call_PushCell(iFeatureId);
		Call_PushCell(bSuccess);
		Call_PushCell(data);
		Call_Finish();
	}
}

bool Func_CreateLimitedFeature(char[] szFeature, LimitType type, int iResetTime, int iMaxUses, int iReqPlayTime, Handle hPlugin, Function func, any data = 0, bool bTQuery)
{
	int iIndex = FindFeatureIndexFromName(szFeature);
	if (iIndex != -1)
	{
		Func_UpdateLimitedFeature(g_iFeatures[iIndex][Feature_Id], type, iResetTime, iMaxUses, iReqPlayTime, hPlugin, func, data, bTQuery);
		return true;
	}
	
	char szQuery[MAX_QUERY_LENGTH];
	
	DataPack dp = new DataPack();
	dp.WriteString(szFeature);
	dp.WriteCell(type);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(func);
	dp.WriteCell(data);
	dp.WriteCell(false);
	
	if (bTQuery)
	{
		Transaction txn = new Transaction();
		FormatQuery(szQuery, sizeof szQuery, "INSERT feature", "INSERT INTO {table_features} \
		( {feature_name}, {feature_type}, {reset_time_last}, {reset_time}, {uses_max}, {required_playtime} ) VALUES \
		( '%s', %d, %d, %d, %d, %d )", szFeature, type, GetTime(), iResetTime, iMaxUses, iReqPlayTime);
		txn.AddQuery(szQuery);
		
		FormatQuery(szQuery, sizeof szQuery, "SELECT INSERT Feature", 
			"SELECT {id}, {feature_name}, {feature_type}, {reset_time_last}, {reset_time}, {uses_max}, {required_playtime} \
		FROM {table_features} WHERE {feature_name} = '%s'", 
			szFeature);
		txn.AddQuery(szQuery);
		
		g_hSql.Execute(txn, SQLTxnCallback_CreateNewFeature_OnSuccess, SQLTxnCallback_CreateNewFeature_OnFail, dp);
	}
	
	else
	{
		DBResultSet result;
		
		FormatQuery(szQuery, sizeof szQuery, "INSERT feature", "INSERT INTO {table_features} \
		( {feature_name}, {feature_type}, {reset_time_last}, {reset_time}, {uses_max}, {required_playtime} ) VALUES \
		( '%s', %d, %d, %d, %d, %d )", szFeature, type, GetTime(), iResetTime, iMaxUses, iReqPlayTime);
		
		result = SQL_Query(g_hSql, szQuery);
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("Insert Feature Error: %s", szQuery);
			Fetch_CreateFeatureRow(false, dp);
			
			return false;
		}
		
		delete result;
		
		FormatQuery(szQuery, sizeof szQuery, "SELECT INSERT Feature", 
			"SELECT {id}, {feature_name}, {feature_type}, {reset_time_last}, {reset_time}, {uses_max}, {required_playtime} \
			FROM {table_features} WHERE {feature_name} = '%s'", 
			szFeature);
		
		result = SQL_Query(g_hSql, szQuery);
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("Insert Feature #2 Error: %s", szQuery);
			Fetch_CreateFeatureRow(false, dp);
			
			return false;
		}
		
		Fetch_CreateFeatureRow(true, dp, result);
	}
	
	return true;
}

bool Func_UpdateLimitedFeature(int iFeatureId, LimitType type, int iResetTime, int iMaxUses, int iReqPlayTime, 
	Handle hPlugin = INVALID_HANDLE, Function func = INVALID_FUNCTION, any data = 0, bool bTQuery)
{
	char szQuery[MAX_QUERY_LENGTH];
	
	Transaction txn = null;
	DBResultSet result = null;
	
	DataPack dp = new DataPack();
	dp.WriteString(g_iFeatures[FindFeatureIndexFromId(iFeatureId)][Feature_Name]);
	dp.WriteCell(type);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(func);
	dp.WriteCell(data);
	dp.WriteCell(true);
	
	FormatQuery(szQuery, sizeof szQuery, "Update Existing Feature #1", 
		"UPDATE {table_features} SET {feature_type} = %d, {reset_time} = %d, {uses_max} = %d, {required_playtime} = %d \
		WHERE {id} = %d;", type, iResetTime, iMaxUses, iReqPlayTime, iFeatureId);
	
	if (bTQuery)
	{
		txn = new Transaction();
		txn.AddQuery(szQuery);
	}
	
	else
	{
		SQL_LockDatabase(g_hSql);
		result = SQL_Query(g_hSql, szQuery);
		SQL_UnlockDatabase(g_hSql);
		
		if (result == null)
		{
			
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("Update Feature #1 Error: %s", szQuery);
			
			Fetch_CreateFeatureRow(false, dp);
			
			return false;
		}
		
		delete result;
	}
	
	FormatQuery(szQuery, sizeof szQuery, "Update Existing Feature #2", 
		"SELECT {id}, {feature_name}, {feature_type}, {reset_time_last}, {reset_time}, {uses_max}, {required_playtime} \
			FROM {table_features} WHERE {id} = %d;", iFeatureId);
	
	if (bTQuery)
	{
		txn.AddQuery(szQuery);
		
		g_hSql.Execute(txn, SQLTxnCallback_CreateNewFeature_OnSuccess, SQLTxnCallback_CreateNewFeature_OnFail, dp);
	}
	
	else
	{
		SQL_LockDatabase(g_hSql);
		result = SQL_Query(g_hSql, szQuery);
		SQL_UnlockDatabase(g_hSql);
		
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("Update Feature #2 Error: %s", szQuery);
			
			Fetch_CreateFeatureRow(false, dp);
			
			return false;
		}
		
		Fetch_CreateFeatureRow(true, dp, result);
		delete result;
	}
	
	return true;
}

public void SQLTxnCallback_CreateNewFeature_OnFail(Database db, DataPack dp, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	Fetch_CreateFeatureRow(false, dp);
}

void Fetch_CreateFeatureRow(bool bSuccess, DataPack dp, DBResultSet result = null)
{
	dp.Reset();
	char szFeature[MAX_FEATURE_NAME_LENGTH];
	dp.ReadString(szFeature, sizeof szFeature);
	LimitType type = dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	bool bUpdateClients = dp.ReadCell();
	
	delete dp;
	
	int iIndex;
	
	if (bSuccess)
	{
		result.FetchRow();
		
		int iFeatureId = result.FetchInt(0);
		
		iIndex = FindFeatureIndexFromId(iFeatureId);
		
		if (iIndex == -1)
		{
			iIndex = g_iFeaturesCount;
		}
		
		int /*iOldResetTime,*/ iOldReqPlayTime;
		if (bUpdateClients)
		{
			//iOldResetTime = g_iFeatures[iIndex][Feature_ResetTime];
			iOldReqPlayTime = g_iFeatures[iIndex][Feature_RequiredPlayTime];
		}
		
		
		g_iFeatures[iIndex][Feature_Id] = iFeatureId;
		result.FetchString(1, g_iFeatures[iIndex][Feature_Name], MAX_FEATURE_NAME_LENGTH);
		g_iFeatures[iIndex][Feature_Type] = result.FetchInt(2);
		g_iFeatures[iIndex][Feature_LastResetTime] = result.FetchInt(3);
		g_iFeatures[iIndex][Feature_ResetTime] = result.FetchInt(4);
		g_iFeatures[iIndex][Feature_MaxUses] = result.FetchInt(5);
		g_iFeatures[iIndex][Feature_RequiredPlayTime] = result.FetchInt(6);
		
		g_iFeaturesCount++;
		
		/*
		if (iOldResetTime + g_iFeatures[iIndex][Feature_ResetTime] > GetTime())
		{
			Func_ResetFeature(iFeatureId, );
			PrintToServer("Reset");
		}*/
		
		if (bUpdateClients)
		{
			int iDifference = g_iFeatures[iIndex][Feature_RequiredPlayTime] - iOldReqPlayTime;
			
			if (iDifference)
			{
				UpdateClientFeatures(iFeatureId, iDifference);
			}
		}
	}
	
	Call_StartFunction(hPlugin, func);
	{
		Call_PushCell(bSuccess);
		
		if (bSuccess)
		{
			Call_PushCell(g_iFeatures[iIndex][Feature_Id]);
		}
		
		else
		{
			Call_PushCell(-1);
		}
		
		Call_PushString(szFeature);
		Call_PushCell(type);
		Call_PushCell(data);
		Call_Finish();
	}
}

public void SQLTxnCallback_CreateNewFeature_OnSuccess(Database db, DataPack dp, int numQueries, DBResultSet[] allresults, any[] queryData)
{
	DBResultSet result = allresults[1];
	Fetch_CreateFeatureRow(true, dp, result);
}

void UpdateClientFeatures(int iFeatureId, int iDifferenceInPlayTime)
{
	char szQuery[MAX_QUERY_LENGTH];
	FormatQuery(szQuery, sizeof szQuery, "Update Client Features", 
		"UPDATE {table_clients} SET {required_playtime_left} = IF({required_playtime_left} + %d < 0, 0, {required_playtime_left} + %d) WHERE {feature_id} = %d", 
		iDifferenceInPlayTime, iDifferenceInPlayTime, iFeatureId);
	g_hSql.Query(SQLCallback_Dump, szQuery);
}

void Func_GetFeatureData(int iFeatureId, Handle hPlugin, Function func, any data)
{
	// function void(int iFeatureId, char[] szFeature, LimitType type, int iResetTime, int iLastReset, int iMaxUses, int iReqPlayTime, any data);
	Call_StartFunction(hPlugin, func);
	{
		int iIndex = FindFeatureIndexFromId(iFeatureId);
		
		if (iIndex == -1)
		{
			Call_PushCell(false);
			Call_PushCell(-1);
			Call_PushString("");
			Call_PushCell(LT_None);
			Call_PushCell(0);
			Call_PushCell(0);
			Call_PushCell(0);
			Call_PushCell(0);
		}
		
		else
		{
			Call_PushCell(true);
			Call_PushCell(iFeatureId);
			Call_PushString(g_iFeatures[iIndex][Feature_Name]);
			Call_PushCell(g_iFeatures[iIndex][Feature_Type]);
			Call_PushCell(g_iFeatures[iIndex][Feature_ResetTime]);
			Call_PushCell(g_iFeatures[iIndex][Feature_LastResetTime]);
			Call_PushCell(g_iFeatures[iIndex][Feature_MaxUses]);
			Call_PushCell(g_iFeatures[iIndex][Feature_RequiredPlayTime]);
			
		}
		
		Call_PushCell(data);
		Call_Finish();
	}
}

// Func_GetClientFeatureData(iSteamAccount, iFeatureId, INVALID_HANDLE, NativeCallback_GetClientFeatureData, 0, false);
void Func_GetClientFeatureData(int iSteamAccount, int iFeatureId, Handle hPlugin, Function func, any data, bool bTQuery)
{
	DataPack dp = new DataPack();
	
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(iFeatureId);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(func);
	dp.WriteCell(data);
	
	char szQuery[MAX_QUERY_LENGTH];
	FormatQuery(szQuery, sizeof szQuery, "Get Client Feature Data", 
		"SELECT {uses}, {required_playtime_left}, {playtime_offset} FROM {table_clients} WHERE {auth} = %d AND {feature_id} = %d;", 
		iSteamAccount, iFeatureId);
	
	if (bTQuery)
	{
		g_hSql.Query(SQLCallback_GetClientFeatureData, szQuery, dp);
	}
	
	else
	{
		SQL_LockDatabase(g_hSql);
		DBResultSet result = SQL_Query(g_hSql, szQuery);
		SQL_UnlockDatabase(g_hSql);
		
		if (result == null)
		{
			char szError[MAX_ERROR_LENGTH];
			SQL_GetError(g_hSql, szError, sizeof szError);
			
			LogError("GetClientFeatureData Error: %s", szError);
			return;
		}
		
		if (!result.RowCount)
		{
			delete result;
			CreateNewClientFeature(dp, false);
			
			return;
		}
		
		Fetch_GetClientFeatureData(true, dp, result);
		delete result;
	}
}

public void SQLCallback_GetClientFeatureData(Database owner, DBResultSet result, char[] szError, DataPack dp)
{
	if (result == null)
	{
		LogError("GetClientFeatureData Error: %s", szError);
		Fetch_GetClientFeatureData(false, dp);
		return;
	}
	
	if (!result.RowCount)
	{
		CreateNewClientFeature(dp, true);
		return;
	}
	
	Fetch_GetClientFeatureData(true, dp, result);
}

void CreateNewClientFeature(DataPack dp, bool bTQuery)
{
	Transaction txn;
	DBResultSet result;
	
	dp.Reset();
	int iSteamAccount = dp.ReadCell();
	int iFeatureId = dp.ReadCell();
	
	int iPlayTimeOffset = 0;
	int client = FindClientFromSteamAccountId(iSteamAccount);
	
	if (client)
	{
		iPlayTimeOffset = RoundFloat(GetClientTime(client));
	}
	
	char szQuery[MAX_QUERY_LENGTH];
	FormatQuery(szQuery, sizeof szQuery, "Add New Client Feature 1", "INSERT INTO {table_clients} \
		( {auth}, {feature_id}, {uses}, {required_playtime_left}, {playtime_offset} ) VALUES \
		( %d, %d, %d, %d, %d);", 
		iSteamAccount, iFeatureId, 0, g_iFeatures[FindFeatureIndexFromId(iFeatureId)][Feature_RequiredPlayTime], iPlayTimeOffset);
	
	if (bTQuery)
	{
		txn = new Transaction();
		txn.AddQuery(szQuery);
	}
	
	else
	{
		SQL_LockDatabase(g_hSql);
		result = SQL_Query(g_hSql, szQuery);
		SQL_UnlockDatabase(g_hSql);
		
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("CreateNewClientFeature Error: %s", szQuery);
			
			Fetch_GetClientFeatureData(false, dp);
			return;
		}
		
		delete result;
	}
	
	FormatQuery(szQuery, sizeof szQuery, "Add new client feature 2", 
		"SELECT {uses}, {required_playtime_left}, {playtime_offset} FROM {table_clients} WHERE {auth} = %d AND {feature_id} = %d;", 
		iSteamAccount, iFeatureId);
	
	if (bTQuery)
	{
		txn.AddQuery(szQuery);
		g_hSql.Execute(txn, SQLTxnCallback_CreateClientFeature_OnSuccess, SQLTxnCallback_CreateClientFeature_OnFail, dp);
	}
	
	else
	{
		SQL_LockDatabase(g_hSql);
		result = SQL_Query(g_hSql, szQuery);
		SQL_UnlockDatabase(g_hSql);
		
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("CreateNewClientFeature Error: %s", szQuery);
			
			Fetch_GetClientFeatureData(false, dp);
			return;
		}
		
		Fetch_GetClientFeatureData(true, dp, result);
		delete result;
	}
}


public void SQLTxnCallback_CreateClientFeature_OnFail(Database db, DataPack dp, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	Fetch_GetClientFeatureData(false, dp);
}

public void SQLTxnCallback_CreateClientFeature_OnSuccess(Database db, DataPack dp, int numQueries, DBResultSet[] allresults, any[] queryData)
{
	Fetch_GetClientFeatureData(true, dp, allresults[1]);
}

void Fetch_GetClientFeatureData(bool bSuccess, DataPack dp, DBResultSet result = null)
{
	dp.Reset();
	int iSteamAccount = dp.ReadCell();
	int iFeatureId = dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	
	delete dp;
	
	if (!bSuccess)
	{
		Call_StartFunction(hPlugin, func);
		{
			Call_PushCell(false);
			Call_PushCell(iSteamAccount);
			Call_PushCell(iFeatureId);
			Call_PushCell(LT_None);
			Call_PushCell(0);
			Call_PushCell(0);
			Call_PushCell(0);
			Call_PushCell(0);
			Call_PushCell(0);
			Call_PushCell(data);
			Call_Finish();
		}
		
		return;
	}
	
	result.FetchRow();
	int iUses = result.FetchInt(0);
	int iReqPlayTimeLeft = result.FetchInt(1);
	int iPlayTimeOffset = result.FetchInt(2);
	
	int iClientPlayTime;
	int client;
	if ((client = FindClientFromSteamAccountId(iSteamAccount)))
	{
		iClientPlayTime = RoundFloat(GetClientTime(client));
		iClientPlayTime -= iPlayTimeOffset;
	}
	
	else
	{
		iClientPlayTime = 0;
	}
	
	iReqPlayTimeLeft -= iClientPlayTime;
	if (iReqPlayTimeLeft < 0)
	{
		iReqPlayTimeLeft = 0;
	}
	
	Call_StartFunction(hPlugin, func);
	{
		int iIndex = FindFeatureIndexFromId(iFeatureId);
		
		Call_PushCell(true);
		Call_PushCell(iSteamAccount);
		Call_PushCell(iFeatureId);
		Call_PushCell(g_iFeatures[iIndex][Feature_Type]);
		Call_PushCell(iUses);
		Call_PushCell(g_iFeatures[iIndex][Feature_MaxUses]);
		Call_PushCell(g_iFeatures[iIndex][Feature_RequiredPlayTime]);
		Call_PushCell(iReqPlayTimeLeft);
		Call_PushCell(iClientPlayTime);
		Call_PushCell(data);
		Call_Finish();
	}
}

void Func_CanActivateFeature(int iSteamAccount, int iFeatureId, Handle hPlugin, Function func, any data, bool bTQuery)
{
	DataPack dp = new DataPack();
	dp.WriteCell(hPlugin);
	dp.WriteFunction(func);
	dp.WriteCell(data);
	//void GetClientFeatureData(int iSteamAccount, int iFeatureId, Handle hPlugin, LimitedFeature_GetClientDataCallback func, any data, bool bTQuery)
	
	Func_GetClientFeatureData(iSteamAccount, iFeatureId, INVALID_HANDLE, Callback_GetClientFeatureDataToCanActivateFeature, dp, bTQuery);
}

public void Callback_GetClientFeatureDataToCanActivateFeature(bool bSuccess, int iSteamAccount, int iFeatureId, LimitType type, int iUses, 
	int iMaxUses, int iReqPlayTime, int iReqPlayTimeLeft, int iClientPlayTime, DataPack dp)
{
	dp.Reset();
	
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	
	bool bCanActivate = true;
	LimitedFeatureActivateFailureReason iReason = LFAFR_None;
	int param1 = 0;
	int param2 = 0;
	// (bool bSuccess, int iSteamAccount, int iFeatureId, bool bCanActivate, LimitedFeatureActivateFailureReason reason = LFAFR_None, int param1, int param2);
	
	if (!bSuccess)
	{
		bCanActivate = false;
		iReason = LFAFR_Plugin;
		param1 = 0;
		param2 = 0;
	}
	
	else
	{
		bCanActivate = CheckCanActivateFeature(type, iUses, iMaxUses, iReqPlayTimeLeft, iClientPlayTime, iReason, param1, param2);
	}
	
	Call_StartFunction(hPlugin, func);
	{
		Call_PushCell(bSuccess);
		Call_PushCell(iSteamAccount);
		Call_PushCell(iFeatureId);
		Call_PushCell(bCanActivate);
		Call_PushCell(iReason);
		Call_PushCell(param1);
		Call_PushCell(param2);
		Call_PushCell(data);
		Call_Finish();
	}
}

bool CheckCanActivateFeature(LimitType type, int iUses, int iMaxUses, int iReqPlayTimeLeft, int iClientPlayTime, 
	LimitedFeatureActivateFailureReason &iReason, int &param1 = 0, int &param2 = 0)
{
	if (iUses >= iMaxUses)
	{
		iReason = LFAFR_MaxUses;
		param1 = iUses;
		param2 = iMaxUses;
		return false;
	}
	
	if (type == LT_TimeUnlock && iReqPlayTimeLeft > 0)
	{
		iReason = LFAFR_RequiredTime;
		param1 = iReqPlayTimeLeft;
		param2 = iClientPlayTime;
		return false;
	}
	
	iReason = LFAFR_None;
	param1 = 0;
	param2 = 0;
	return true;
}

void Func_ActivateFeature(int iSteamAccount, int iFeatureId, bool bForce, Handle hPlugin, Function func, any data, bool bTQuery)
{
	DataPack dp = new DataPack();
	dp.WriteCell(bForce);
	dp.WriteCell(bTQuery);
	dp.WriteCell(iSteamAccount);
	dp.WriteCell(iFeatureId);
	dp.WriteCell(hPlugin);
	dp.WriteFunction(func);
	dp.WriteCell(data);
	
	Func_GetClientFeatureData(iSteamAccount, iFeatureId, INVALID_HANDLE, Callback_GetClientFeatureDataToActivateFeature, dp, bTQuery);
	
	//Func_CanActivateFeature(iSteamAccount, iFeatureId, Callback_ClientCanActivateFeatureToActivateFeature, dp, bTQuery);
}

public void Callback_GetClientFeatureDataToActivateFeature(bool bSuccess, int iSteamAccount, int iFeatureId, LimitType type, int iUses, int iMaxUses, 
	int iReqPlayTime, int iReqPlayTimeLeft, int iClientPlayTime, DataPack dp)
{
	DataPack dataDP = new DataPack();
	
	dataDP.WriteCell(dp);
	dataDP.WriteCell(iSteamAccount);
	dataDP.WriteCell(iFeatureId);
	dataDP.WriteCell(type);
	dataDP.WriteCell(iUses);
	dataDP.WriteCell(iMaxUses);
	dataDP.WriteCell(iReqPlayTime);
	dataDP.WriteCell(iReqPlayTimeLeft);
	dataDP.WriteCell(iClientPlayTime);
	
	if (!bSuccess)
	{
		Fetch_ClientActivateFeature(false, false, LFAFR_Plugin, dataDP);
		delete dp;
		return;
	}
	
	dp.Reset();
	bool bForce = dp.ReadCell();
	bool bTQuery = dp.ReadCell();
	
	LimitedFeatureActivateFailureReason iReason = LFAFR_None;
	
	bool bRet = CheckCanActivateFeature(type, iUses, iMaxUses, iReqPlayTimeLeft, iClientPlayTime, iReason);
	PrintToServer("bRet: %d - %d %d", bRet, iReason, type);
	if (!bRet)
	{
		if (iReason != LFAFR_RequiredTime || (iReason == LFAFR_RequiredTime && !bForce) )
		{
			Fetch_ClientActivateFeature(true, false, iReason, dataDP);
			return;
		}
	}
	
	char szQuery[MAX_QUERY_LENGTH];
	int iFeatureIndex = FindFeatureIndexFromId(iFeatureId);
	
	int client;
	int iTimeOffset = (client = FindClientFromSteamAccountId(iSteamAccount)) ? RoundFloat(GetClientTime(client)) : 0;
	
	DBResultSet result;
	
	FormatQuery(szQuery, sizeof szQuery, "Activate Feature", 
		"UPDATE {table_clients} SET {uses} = {uses} + 1, {required_playtime_left} = %d, {playtime_offset} = %d WHERE {auth} = %d AND {feature_id} = %d", 
		g_iFeatures[iFeatureIndex][Feature_RequiredPlayTime], iTimeOffset, iSteamAccount, iFeatureId);
	
	if (bTQuery)
	{
		g_hSql.Query(SQLCallback_ActivateFeature, szQuery, dataDP);
	}
	
	else
	{
		SQL_LockDatabase(g_hSql);
		result = SQL_Query(g_hSql, szQuery);
		SQL_UnlockDatabase(g_hSql);
		
		if (result == null)
		{
			SQL_GetError(g_hSql, szQuery, sizeof szQuery);
			LogError("ActivateFeature Error: %s", szQuery);
			
			Fetch_ClientActivateFeature(false, false, LFAFR_Plugin, dataDP);
			return;
		}
		
		Fetch_ClientActivateFeature(true, true, LFAFR_None, dataDP);
		delete result;
	}
}

public void SQLCallback_ActivateFeature(Database owner, DBResultSet result, char[] szError, DataPack dataDP)
{
	if (result == null)
	{
		LogError("ActivateFeature Error: %s", szError);
		
		Fetch_ClientActivateFeature(false, false, LFAFR_Plugin, dataDP);
		return;
	}
	
	Fetch_ClientActivateFeature(true, true, LFAFR_None, dataDP);
}

void Fetch_ClientActivateFeature(bool bSuccess, bool bWasActivated, LimitedFeatureActivateFailureReason iReason = LFAFR_None, DataPack dataDP)
{
	dataDP.Reset();
	DataPack dp = dataDP.ReadCell();
	int iSteamAccount = dataDP.ReadCell();
	int iFeatureId = dataDP.ReadCell();
	//LimitType type = 
	dataDP.ReadCell();
	int iUses = dataDP.ReadCell();
	int iMaxUses = dataDP.ReadCell();
	int iReqPlayTime = dataDP.ReadCell();
	int iReqPlayTimeLeft = dataDP.ReadCell();
	int iClientPlayTime = dataDP.ReadCell();
	
	delete dataDP;
	
	dp.Reset();
	//bool bForce = 
	dp.ReadCell();
	//bool bTQuery = 
	dp.ReadCell();
	/*int iSteamAccount = */
	dp.ReadCell();
	/*int iFeatureId = */
	dp.ReadCell();
	Handle hPlugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any data = dp.ReadCell();
	
	Call_StartFunction(hPlugin, func);
	{
		Call_PushCell(bSuccess);
		Call_PushCell(iSteamAccount);
		Call_PushCell(iFeatureId);
		Call_PushCell(bWasActivated);
		Call_PushCell(iReason);
		Call_PushCell(iUses);
		Call_PushCell(iMaxUses);
		Call_PushCell(iReqPlayTime);
		Call_PushCell(iReqPlayTimeLeft);
		Call_PushCell(iClientPlayTime);
		Call_PushCell(data);
		Call_Finish();
	}
}

int FindFeatureIndexFromId(int iFeatureId)
{
	for (int i; i < g_iFeaturesCount; i++)
	{
		if (g_iFeatures[i][Feature_Id] == iFeatureId)
		{
			return i;
		}
	}
	
	return -1;
}

int FindFeatureIndexFromName(char[] szFeature)
{
	for (int i; i < g_iFeaturesCount; i++)
	{
		if (StrEqual(g_iFeatures[i][Feature_Name], szFeature))
		{
			return i;
		}
	}
	
	return -1;
}

int FindClientFromSteamAccountId(int iSteamAccountId)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (GetSteamAccountID(i) == iSteamAccountId)
		{
			return i;
		}
	}
	
	return 0;
}

void FormatQuery(char[] szQuery, int iSize, char[] szDesc, char[] szFmt, any...)
{
	VFormat(szQuery, iSize, szFmt, 5);
	FixQuery(szQuery, iSize);
	LogMessage("%s: %s", szDesc, szQuery);
}

void FixQuery(char[] szQuery, int iSize)
{
	ReplaceString(szQuery, iSize, "{table_features}", "limitedfeatures_features");
	ReplaceString(szQuery, iSize, "{table_clients}", "limitedfeatures_clients");
	ReplaceString(szQuery, iSize, "{id}", "id");
	ReplaceString(szQuery, iSize, "{auth}", "auth");
	ReplaceString(szQuery, iSize, "{feature_id}", "feature_id");
	ReplaceString(szQuery, iSize, "{feature_name}", "feature_name");
	ReplaceString(szQuery, iSize, "{feature_type}", "feature_type");
	ReplaceString(szQuery, iSize, "{uses_max}", "uses_max");
	ReplaceString(szQuery, iSize, "{uses}", "uses");
	ReplaceString(szQuery, iSize, "{required_playtime}", "required_playtime");
	ReplaceString(szQuery, iSize, "{required_playtime_left}", "required_playtime_left");
	ReplaceString(szQuery, iSize, "{playtime_offset}", "playtime_offset");
	ReplaceString(szQuery, iSize, "{reset_time}", "reset_time");
	ReplaceString(szQuery, iSize, "{reset_time_last}", "reset_time_last");
} 