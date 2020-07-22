#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <limited_features>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

int g_iFeatureId = -1, g_iFeatureId2 = -1;

public void OnPluginStart()
{	
	RegConsoleCmd("sm_test", ConCmd_Test);
}

public void OnAllPluginsLoaded()
{
	g_iFeatureId = LF_Feature_CreateEx("test_feature", LT_Normal, 60, 1);
	g_iFeatureId2 = LF_Feature_CreateEx("test_feature2", LT_TimeUnlock, 300, 3, 60);
}

public Action ConCmd_Test(int client, int argc)
{
	// int &iUses = 0, int &iMaxUses = 0, int &iReqPlayTime = 0, 
	//int &iReqPlayTimeLeft = 0, int &iClientPlayTime = 0);
	
	char szCmd[5];
	GetCmdArg(1, szCmd, sizeof szCmd);
	
	int iFeature = StringToInt(szCmd);
	
	//PrintToServer("iFeatureId %d %d", g_iFeatureId, g_iFeatureId2);
	
	//int iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientTime;
	
	PrintToServer("Feature: %d", iFeature ? g_iFeatureId2 : g_iFeatureId);
	
	LF_Client_ActivateFeature(GetSteamAccountID(client), iFeature ? g_iFeatureId2 : g_iFeatureId, false, OnActivateFeature, 0);
	/*if(LF_Client_ActivateFeatureEx(GetSteamAccountID(client), iFeature ? g_iFeatureId2 : g_iFeatureId, false, _, iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientTime))
	{
		PrintToServer("Success: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientTime);
		PrintToChatAll("Success: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientTime);
	}
	
	else
	{
		PrintToServer("Fail: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientTime);
		PrintToChatAll("Fail: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientTime);
	}*/
	
	return Plugin_Handled;
}

public void OnActivateFeature(bool bSuccess, int iSteamAccount, int iFeatureId, bool bWasActivated, 
	LimitedFeatureActivateFailureReason iReason, int iUses, int iMaxUses, int iReqPlayTime, int iReqPlayTimeLeft, int iClientPlayTime, any data)
{
	if(bWasActivated)
	{
		PrintToServer("Success: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientPlayTime);
		PrintToChatAll("Success: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientPlayTime);
	}
	
	else
	{
		PrintToServer("Fail: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientPlayTime);
		PrintToChatAll("Fail: Uses: %d - MaxUses: %d - ReqPlayTime: %d - ReqPlayTimeLeft %d ClientTime: %d", iUses, iMaxUses, iReqPlayTime, iReqPlayTimeLeft, iClientPlayTime);
	}
}