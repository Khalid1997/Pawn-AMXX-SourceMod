#pragma semicolon 1

#include <sourcemod>
#include <multimod>

public Plugin myinfo = 
{
	name = "MultiMod: Logging and Chat",
	author = MM_PLUGIN_AUTHOR,
	description = "Contains natives for logging and printing to chat.",
	version = MM_VERSION_STR,
	url = "No"
};

char g_szSetting_ChatPrefix[MM_MAX_PREFIX_LENGTH];
bool g_bSetting_Debug;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrMax)
{
	CreateNative("MultiMod_LogMessage", Native_LogMessage);
	CreateNative("MultiMod_PrintDebug", Native_PrintDebug);
	
	CreateNative("MultiMod_PrintToChat", Native_PrintToChat);
	CreateNative("MultiMod_PrintToChatAll", Native_PrintToChatAll);
	
	RegPluginLibrary(MM_LIB_LOGGING);
	
	return APLRes_Success;
}

public void OnPluginStart()
{									
	
}

public void OnAllPluginsLoaded()
{
	char szDefault[3];
	FormatEx(szDefault, sizeof szDefault, "%d", g_bSetting_Debug);
	MultiMod_Settings_Create(MM_SETTING_CHAT_PREFIX, 		"[MultiMod]", true, true);
	MultiMod_Settings_Create(MM_SETTING_DEBUG, 				szDefault, true, true, true);
}

public void MultiMod_Settings_OnValueChange(char[] szSettingName, char[] szOldValue, char[] szNewValue)
{
	//LogMessage("SettingName: %s", szSettingName);
	
	if(StrEqual(szSettingName, MM_SETTING_CHAT_PREFIX))
	{
		strcopy(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, szNewValue);
		
		ReplaceString(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, "!1", "\x01");
		ReplaceString(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, "!2", "\x02");
		ReplaceString(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, "!3", "\x03");
		ReplaceString(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, "!4", "\x04");
		ReplaceString(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, "!5", "\x05");
		ReplaceString(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, "!6", "\x06");
		ReplaceString(g_szSetting_ChatPrefix, sizeof g_szSetting_ChatPrefix, "!7", "\x07");
	}
	
	else if(StrEqual(szSettingName, MM_SETTING_DEBUG))
	{
		g_bSetting_Debug = view_as<bool>(!!StringToInt(szNewValue));
		//LogMessage("Value changed debug %s %s %d", szOldValue, szNewValue, g_bSetting_Debug);
	}
}

public int Native_LogMessage(Handle hPlugin, int iArgs)
{
	bool bForce = GetNativeCell(1);
	if(!bForce && !g_bSetting_Debug)
	{
		return;
	}
	
	char szBuffer[256];
	FormatNativeString(0, 1, 2, sizeof(szBuffer),_, szBuffer);
	
	LogToFile(MM_LOG_FILE, szBuffer);
	LogMessage(szBuffer);
}

public int Native_PrintDebug(Handle hPlugin, int iArgs)
{
	if(!g_bSetting_Debug)
	{
		return;
	}
	
	char szBuffer[256];
	int iLen = FormatEx(szBuffer, sizeof szBuffer, "[MM Debug] ");
	
	FormatNativeString(0, 1, 2, sizeof(szBuffer) - iLen,_, szBuffer[iLen]);
	
	LogToFile(MM_LOG_FILE, szBuffer);
	LogMessage(szBuffer);
}

public int Native_PrintToChatAll(Handle hPlugin, int iArgs)
{
	char szBuffer[256];
	int iLen = FormatEx(szBuffer, sizeof szBuffer, " \x01%s \x01", g_szSetting_ChatPrefix);
	
	FormatNativeString(0, 1, 2, sizeof(szBuffer) - iLen, _, szBuffer[iLen]);
	
	PrintToChatAll(szBuffer);
}

public int Native_PrintToChat(Handle hPlugin, int iArgs)
{
	char szBuffer[256];
	int iLen = FormatEx(szBuffer, sizeof szBuffer, " \x01%s \x01", g_szSetting_ChatPrefix);
	
	FormatNativeString(0, 2, 3, sizeof(szBuffer) - iLen, _, szBuffer[iLen]);

	int client = GetNativeCell(1);
	
	PrintToChat(client, szBuffer);
}

