#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

#define RANK_LENGTH 60
#define NOTIFY_LENGTH 60
//#define ACCESS_LENGTH	AdminFlags_TOTAL

//#define SQL_ADMINS

#if defined SQL_ADMINS
new Handle:g_hReloadTimer = INVALID_HANDLE;
#endif

public Plugin myinfo = 
{
	name = "Slash admins",
	author = "Khalid",
	description = "/admins in chat",
	version = PLUGIN_VERSION,
	url = "No"
};

ConVar ConVar_ParseString;

enum
{
	ARRAY_NOTIFY_NAME,
	ARRAY_SLASH_NAME,
	ARRAY_ACCESS_FLAG
}

Handle g_hArrays[3];
Handle g_hAdminsCountArray;
Handle g_hSlashAdminStrings;

int g_iClientAccessIndex[MAXPLAYERS + 1] = -1;
bool g_bLate = false;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrorLen)
{
	g_bLate = bLate;
}

public void OnPluginStart()
{
	g_hArrays[ARRAY_NOTIFY_NAME] = CreateArray(NOTIFY_LENGTH + 1);
	g_hArrays[ARRAY_SLASH_NAME] = CreateArray(RANK_LENGTH + 1);
	g_hArrays[ARRAY_ACCESS_FLAG] = CreateArray(1);
	g_hAdminsCountArray = CreateArray(1);
	
	g_hSlashAdminStrings = CreateArray(256);
	
	new const String:szInitValue[] = "HEAD ADMIN:Head Admin:z, ADMIN:ADMIN:g";
	
	ConVar_ParseString = CreateConVar("slashadmins_admins", 
	szInitValue,
	"Name on connect notify(disabled for disable):Name for slash (disabled for disable):access flag");
	
	
	ReadCvarValue( szInitValue );
	
	ConVar_ParseString.AddChangeHook(ConVarChanged_Callback);
	//HookConVarChange(ConVar_ParseString, ConVarChanged_False);
	
	AddCommandListener(CMDListener_Say, "say");
	AddCommandListener(CMDListener_Say, "say_team");
	
	AutoExecConfig(true, "slash_admins");
	
	if(g_bLate)
	{
		RebuildAdminString(-1);
	}
}

public ConVarChanged_Callback(ConVar convar, const String:oldValue[], const String:newValue[])
{
	ClearArray(g_hArrays[ARRAY_NOTIFY_NAME]);
	ClearArray(g_hArrays[ARRAY_SLASH_NAME]);
	ClearArray(g_hArrays[ARRAY_ACCESS_FLAG]);
	ClearArray(g_hSlashAdminStrings);
	ClearArray(g_hAdminsCountArray);
	
	SetArrayValue(g_iClientAccessIndex, sizeof g_iClientAccessIndex, -1);
	
	ReadCvarValue(newValue);
	
	RebuildAdminString(-1);
}

public OnClientPostAdminCheck(client)
{
	if(!IsClientAdmin(client, g_iClientAccessIndex[client]))
	{
		return;
	}
	
	AddToAdminNames(client, g_iClientAccessIndex[client]);
	PrintConnectNotify(client, g_iClientAccessIndex[client]);
}

public OnRebuildAdminCache(AdminCachePart part)
{
	//SetArrayValue(g_iClientAccessIndex, sizeof g_iClientAccessIndex, -1);
#if defined SQL_ADMINS
	if(g_hReloadTimer != INVALID_HANDLE)
	{
		CloseHandle(g_hReloadTimer);
	}

	g_hReloadTimer = CreateTimer(4.0, Timer_Reload, TIMER_FLAG_NO_MAPCHANGE);
#else
	Timer_Reload(INVALID_HANDLE, 0);
#endif
}

public Action Timer_Reload(Handle hTimer, any data)
{
#if defined SQL_ADMINS
	g_hReloadTimer = INVALID_HANDLE;
#endif

	ReCheckPlayers();
	RebuildAdminString(-1);
	
	return Plugin_Stop;
}

ReCheckPlayers()
{
	for (new i = 1, iIndex; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsClientAdmin(i, iIndex))
			{
				g_iClientAccessIndex[i] = iIndex;
			}
		}
		
		g_iClientAccessIndex[i] = -1;
	}
}

public OnClientDisconnect(int client)
{
	if(g_iClientAccessIndex[client] != -1)
	{
		int iVal = g_iClientAccessIndex[client];
		g_iClientAccessIndex[client] = -1;
		RebuildAdminString(iVal);
	}
}

RebuildAdminString(int iIndex)
{
	int iSize;
	
	if(iIndex == -1)
	{
		iIndex = 0;
		iSize = GetArraySize(g_hSlashAdminStrings);
		
		for (int i; i < iSize; i++)
		{
			SetArrayString(g_hSlashAdminStrings, i, "");
			SetArrayCell(g_hAdminsCountArray, i, 0);
		}
	}
	
	else
	{
		iSize = iIndex + 1;
		SetArrayString(g_hSlashAdminStrings, iIndex, "");
		SetArrayCell(g_hAdminsCountArray, iIndex, 0);
	}
	
	for (int i = iIndex, client, iArrayIndex; i < iSize; i++)
	{
		for (client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				if( ( (iArrayIndex = g_iClientAccessIndex[client]) != -1 ))
				{
					//g_iClientAccessIndex[client] = iArrayIndex;
					
					if(iArrayIndex != iIndex)
					{
						continue;
					}
					
					//g_iClientAccessIndex[client] = iArrayIndex;
					//iLen += FormatEx(szNames[iLen], sizeof(szNames) - iLen, "%s%N", szNames[0] ? ", " : "", client);
					AddToAdminNames(client, iArrayIndex);
				}
			}
		}
	}
}

PrintConnectNotify(client, iIndex)
{
	static String:szNotifyName[NOTIFY_LENGTH];
	GetArrayString(g_hArrays[ARRAY_NOTIFY_NAME], iIndex, szNotifyName, sizeof szNotifyName);
	
	if(StrEqual(szNotifyName, "disabled", false))
	{
		PrintToServer("Notify Disabled");
		return;
	}
	
	char szString[256];
	FormatEx(szString, sizeof szString, " \x04*** %s LOGIN: \x03%N \x05has connected.", szNotifyName, client);
	PrintToChatAll(szString);
	PrintToServer("Message: %s", szString);
}

AddToAdminNames(int client, int iIndex, bool bAlterAdminCount = true)
{
	static char szRankName[RANK_LENGTH];
	GetArrayString(g_hArrays[ARRAY_SLASH_NAME], iIndex, szRankName, sizeof szRankName);
	
	if(StrEqual(szRankName, "disabled", false))
	{
		PrintToServer("Disabled from Slash admins");
		return;
	}
	
	static String:szOldNames[256], String:szNewNames[256];
	int iLen = GetArrayString(g_hSlashAdminStrings, iIndex, szOldNames, sizeof szOldNames);
	
	FormatEx(szNewNames[iLen], sizeof(szNewNames) - iLen, "%s%N", szOldNames[0] ? ", " : "", client);
	SetArrayString(g_hSlashAdminStrings, iIndex, szNewNames);
	
	if(bAlterAdminCount)
	{
		SetArrayCell(g_hAdminsCountArray, iIndex, GetArrayCell(g_hAdminsCountArray, iIndex) + 1);
	}
	
	PrintToServer("newNames %s", szNewNames);
}

public Action CMDListener_Say(int client, char[] szCmd, int iArgsC)
{
	char szCmdArg[25];
	int iSuccess;
	
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	static const String:szTriggerCmds[][] = {
		"all",
		"admin",
		"showadmin",
		"showadmins",
		"onlineadmins",
		"administrators"
	};
	
	if( szCmdArg[0] == '!' || szCmdArg[0] == '/' )
	{
		for (new i; i < sizeof szTriggerCmds; i++)
		{
			if(StrEqual(szCmdArg[1], szTriggerCmds[i], false))
			{
				ShowOnlineAdmins(client);
				iSuccess = 1;
				break;
			}
		}
		
		return iSuccess ? (szCmdArg[0] == '!' ? Plugin_Continue : Plugin_Handled) : Plugin_Continue;
	}
	
	return Plugin_Continue;
}

ShowOnlineAdmins(int client)
{
	int iTotalAdmins, iSize = GetArraySize(g_hArrays[ARRAY_SLASH_NAME]), i, iAdmins;
	static String:szSlashName[256];
	static String:szPrint[512];

	for(i = 0; i < iSize; i++)
	{
		GetArrayString(g_hArrays[ARRAY_SLASH_NAME], i, szSlashName, sizeof szSlashName);
		iTotalAdmins += ( iAdmins = GetArrayCell(g_hAdminsCountArray, i) );
		
		if(StrEqual(szSlashName, "disabled", false))
		{
			continue;
		}
		
		GetArrayString(g_hSlashAdminStrings, i, szPrint, sizeof szPrint);
		
		Format(szPrint, sizeof szPrint, " Online \x03%s\x01: \x05%s\x01.", szSlashName, iAdmins ?  szPrint : "none");
		PrintToChat(client, szPrint);
	}
	
	PrintToChat(client, " Total online \x03admins\x01: \x05%d\x01.", iTotalAdmins);
}

bool IsClientAdmin(int client, int &iIndex = -1)
{
	static AdminId iAdminId; 
	iAdminId = GetUserAdmin(client);
	
	if(iAdminId == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	int iSize = GetArraySize(g_hArrays[ARRAY_ACCESS_FLAG]);
	int iBit, iCount, i;
	AdminFlag iAdminFlags[AdminFlags_TOTAL];
	
	for (iIndex = 0; iIndex < iSize; iIndex++)
	{
		iBit = GetArrayCell(g_hArrays[ARRAY_ACCESS_FLAG], iIndex);
		iCount = GetFlagsFromBit(iAdminFlags, iBit);
		
		for (i = 0; i < iCount; i++)
		{
			if( !( GetAdminFlag(iAdminId, iAdminFlags[i]) ) )
			{
				PrintToServer("Here 1 %d", iAdminFlags[i]);
				break;
			}
			
			if(i + 1 == iCount)
			{
				return true;
			}
		}
	}
	
	iIndex = -1;
	return false;
}

int GetFlagsFromBit(AdminFlag:iFlagArray[AdminFlags_TOTAL], int iFlagBit)
{
	if(iFlagBit & ADMFLAG_ROOT)
	{
		iFlagArray[0] = Admin_Root;
		return 1;
	}
	
	else
	{
		int iCount;
		
		for (new i = 0; i < view_as<int>(AdminFlag); i++)
		{
			if( iFlagBit & (1<<i) )
			{
				iFlagArray[iCount++] = AdminFlag:i;
			}
		}
		
		return iCount;
	}
}

ReadCvarValue(const String:newValue[])
{
	#define MINI_PART_COUNT 	(3)
	#define MAX_MAIN_PART_NAME 	(RANK_LENGTH + NOTIFY_LENGTH + AdminFlags_TOTAL + MINI_PART_COUNT + 1)
	#define MAX_MINI_PART_NAME (MAX_MAIN_PART_NAME / MINI_PART_COUNT)
	
	enum
	{
		PART_NOTIFY,
		PART_SLASH,
		PART_ACCESS
	};
	
	int iMainPartCount = CountStringParts(newValue, ",", true);
	new String:szSplittedString[iMainPartCount][MAX_MAIN_PART_NAME];
	
	ExplodeString(newValue, ",", szSplittedString, iMainPartCount, MAX_MAIN_PART_NAME, true);
	
	for (new i; i < iMainPartCount; i++)
	{
		PrintToServer(szSplittedString[i]);
	}
	
	int iMiniPartCount;
	new String:szMiniSplittedString[MINI_PART_COUNT][MAX_MINI_PART_NAME];
	for (new i, j, iFlagBit; i < iMainPartCount; i++)
	{
		TrimString(szSplittedString[i]);
		iMiniPartCount = CountStringParts(szSplittedString[i], ":", true);
		
		if(iMiniPartCount == MINI_PART_COUNT)
		{
			ExplodeString(szSplittedString[i], ":", szMiniSplittedString, MINI_PART_COUNT, sizeof szMiniSplittedString[], true);
			
			for (j = 0; j < MINI_PART_COUNT; j++)
				TrimString(szMiniSplittedString[j]);
				
			PushArrayString(g_hArrays[ARRAY_NOTIFY_NAME], szMiniSplittedString[PART_NOTIFY]);
			PushArrayString(g_hArrays[ARRAY_SLASH_NAME], szMiniSplittedString[PART_SLASH]);
			
			iFlagBit = ReadFlagString(szMiniSplittedString[PART_ACCESS]);
			PushArrayCell(g_hArrays[ARRAY_ACCESS_FLAG], iFlagBit);
			
			PushArrayString(g_hSlashAdminStrings, "");
			PushArrayCell(g_hAdminsCountArray, 0);
			
			PrintToServer("ADD %s %s %s", szMiniSplittedString[0], szMiniSplittedString[1], szMiniSplittedString[2]);
			continue;
		}
		
		// Something wrong happened
		if(iMiniPartCount > MINI_PART_COUNT)
		{
			LogError("Error in ConVar part '%s': part contains extra arguments (max arguments %d)", szSplittedString[i], MINI_PART_COUNT);
		}
		
		else if(iMiniPartCount < MINI_PART_COUNT)
		{
			new String:szError[256]; 
			int iLen, iAdd;
			
			iLen = FormatEx(szError, sizeof szError, "Error in ConVar part '%s': ", szSplittedString[i]);
			
			new const String:szMissingError[MINI_PART_COUNT][] = {
				"missing notify name part",
				"missing slash name part",
				"missing access flags part"
			};
			
			for (j = MINI_PART_COUNT; j > iMiniPartCount; j--)
			{
				iLen += FormatEx(szError[iLen], sizeof(szError) - iLen, "%s%s", iAdd ? ", " : "", szMissingError[j - 1]);
				iAdd = 1;
			}
			
			LogError("%s.", szError);
		}
		
	}
}

int CountStringParts(const String:szString[], String:szSplitTocken[], bool bCountRemainder = false)
{
	int iC, iPos, iLen;
	
	while( (iPos = StrContains(szString[iLen], szSplitTocken, false) ) != -1)
	{
		iLen += iPos + 1;	// Move to the next index (char) after the match.
		iC++;
	}
	
	return bCountRemainder ? iC + 1 : iC;
}

SetArrayValue(int[] iArray, int iSize, int iValue)
{
	for (int i = 0; i < iSize; i++)
	{
		iArray[i] = iValue;
	}
}