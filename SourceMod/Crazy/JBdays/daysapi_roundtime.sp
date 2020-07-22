#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <daysapi>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "DaysAPI: Day Round Time Changer",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

KeyValues kv;
char g_szPath[] = "cfg/sourcemod/daysapi/daysapi_roundtime.ini";

char Key_Parent[] = "DaysAPI_RoundTime";
char Key_RoundTime[] = "round_time";

float g_flRoundStartTime;

char g_szIntName[MAX_INTERNAL_NAME_LENGTH];

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public void Event_RoundStart(Event event, const char[] szEvent, bool bDontbroadcast)
{
	g_flRoundStartTime = GetGameTime();
}

public void DaysAPI_OnDayAdded(char[] szIntName)
{
	FindRoundTime(szIntName);
}

public void DaysAPI_OnDayStart(char[] szIntName)
{
	strcopy(g_szIntName, sizeof g_szIntName, szIntName);
	RequestFrame(Frame_AdjustRoundTime);
}

public void Frame_AdjustRoundTime(any data)
{
	int iRequiredRoundTime = RoundFloat(FindRoundTime(g_szIntName) * 60.0) ;
	
	if(iRequiredRoundTime < 0)
	{
		return;
	}
	
	//int iCurrentRoundTime = GameRules_GetProp("m_iRoundTime");
	int iRoundStartTime = RoundFloat(g_flRoundStartTime);
	//int iRoundEndTime = iRoundStartTime + iCurrentRoundTime;
	int iCurrentGameTime = RoundFloat(GetGameTime());
	
	//int iLeft = iRoundEndTime - iCurrentGameTime;
	int iPassed = iCurrentGameTime - iRoundStartTime;
	
	int iRoundTime;
	iRoundTime = iPassed + iRequiredRoundTime;
	
	//PrintToChatAll("%d %d %d %d", iCurrentRoundTime, (iRoundEndTime - iCurrentGameTime), (iCurrentGameTime - iRoundStartTime), iRoundTime);
	GameRules_SetProp("m_iRoundTime", iRoundTime, 4, 0, true);
}

float FindRoundTime(char[] szIntName)
{
	kv = new KeyValues(Key_Parent);
	if(!FileExists(g_szPath))
	{
		KeyValuesToFile(kv, g_szPath);
		delete kv;
		return -1.0;
	}
	
	FileToKeyValues(kv, g_szPath);
	
	if(!kv.JumpToKey(szIntName, false))
	{
		kv.JumpToKey(szIntName, true);
		kv.SetFloat(Key_RoundTime, -1.0);
		kv.GoBack();
		
		KeyValuesToFile(kv, g_szPath);
		delete kv;
		return -1.0;
	}
	
	float flRoundTime = kv.GetFloat(Key_RoundTime, -1.0);
	delete kv;
	
	return flRoundTime;
}