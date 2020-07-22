#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

#define RANK_LENGTH 60
#define NOTIFY_LENGTH 60
//#define ACCESS_LENGTH	AdminFlags_TOTAL

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
Handle g_hTempFlagsArray;
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
	
	AddCommandListener(CMDListener_Say, "say");
	AddCommandListener(CMDListener_Say, "say_team");
	
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

PrintConnectNotify(client, iIndex)
{
	static String:szNotifyName[NOTIFY_LENGTH];
	GetArrayString(g_hArrays[ARRAY_NOTIFY_NAME], iIndex, szNotifyName, sizeof szNotifyName);
	
	if(!StrEqual(szNotifyName, "disabled", false))
	{
		PrintToServer("Notify Disabled");
		return;
	}
	
	PrintToChatAll(" \x01*** %s %N has connected.", szNotifyName, client);
}

SetArrayValue(int[] iArray, int iSize, int iValue)
{
	for (int i = 1; i < iSize; i++)
	{
		iArray[i] = iValue;
	}
}

AddToAdminNames(int client, int iIndex)
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
}

public OnRebuildAdminCache(AdminCachePart part)
{
	RebuildAdminString(-1);
}

public OnClientDisconnect(int client)
{
	if(IsClientAdmin(client))
	{
		RebuildAdminString(g_iClientAccessIndex[client]);
	}
}

RebuildAdminString(int iIndex)
{
	new String:szNames[256];
	int iSize, iLen;
	
	if(iIndex == -1)
	{
		iIndex = 0;
		iSize = GetArraySize(g_hSlashAdminStrings);
	}
	
	else
	{
		iSize = iIndex + 1;
	}
	
	for (int i = iIndex, client, iArrayIndex; i < iSize; i++)
	{
		for (client = 1, iLen = 0; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				if(IsClientAdmin(client, iArrayIndex))
				{
					if(iArrayIndex != iIndex)
					{
						continue;
					}
					
					iLen += FormatEx(szNames[iLen], sizeof(szNames) - iLen, "%s%N", szNames[0] ? ", " : "", client);
				}
			}
		}
		
		SetArrayString(g_hSlashAdminStrings, iIndex, szNames);
	}
}

public Action CMDListener_Say(int client, char[] szCmd, int iArgsC)
{
	char szCmdArg[25];
	int iSuccess;
	
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	static const String:szTriggerCmds[][] = {
		"admins",
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
	
	PrintToChat(client, " Total online \x03admins\x01: \x05%d\x01", iTotalAdmins);
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
	
	for (iIndex = 0; iIndex < iSize; i++)
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
		
		for (new i = 0; i < view_as<int> AdminFlag; i++)
		{
			if( iFlagBit & (1<<i) )
			{
				iFlagArray[iCount++] = AdminFlag:i;
			}
		}
		
		return iCount;
	}
}

ReadCvarValue(const String:newValue[] )
{
	g_hTempFlagsArray = CreateArray(3);
	
	#define MAX_PART_NAME 120
	
	new String:szPartMain[MAX_PART_NAME], String:szPartMini[120];
	int iIndexMain, iIndexMain2, iIndexMini, iIndexMini2, iPart;
	
	enum
	{
		PART_NONE = -1,
		PART_NOTIFY,
		PART_SLASH,
		PART_FLAG,
		
		PART_COUNT,
		PART_ERROR_EXTRA_ARGS
	};
	
	new iPartCount = CountParts(newValue[], ",");
	while( (iIndexMain = SplitString(newValue[iIndexMain2], ",", szPartMain, sizeof szPartMain) ) != -1 )
	{
		iIndexMain2 += iIndexMain;
		LogError("Main %s", szPartMain);
		
		iIndexMini = 0; iIndexMini2 = 0; iPart = PART_NOTIFY;
		
		while( ( iIndexMini = SplitString(szPartMain[iIndexMini2], ":", szPartMini, sizeof szPartMini) ) != -1 )
		{
			iIndexMini2 += iIndexMini;
			LogError("Mini %s", szPartMini);
			LogError("iIndexMini %d", iIndexMini);
			switch(iPart)
			{
				case PART_NOTIFY:
				{
					iPart = PART_SLASH;
					TrimString(szPartMini);
					PushArrayString(g_hArrays[ARRAY_NOTIFY_NAME], szPartMini);
				}
				
				case PART_SLASH:
				{
					iPart = PART_FLAG;
					TrimString(szPartMini);
					PushArrayString(g_hArrays[ARRAY_SLASH_NAME], szPartMini);
				}
				
				case PART_FLAG:
				{
					// PART_ERROR_EXTRA_ARGS
					iPart = PART_ERROR_EXTRA_ARGS;
					LogError("Error in ConVar: Extra argument: %s", szPartMini);
					break;
				}
			}
		}
		
		static const String:szMissing[PART_COUNT][] = {
			"Missing Notify Name",
			"Missing Slash Name",
			"Missing Access Flag"
		};
		
		// If it's not complete or contains extra arguments, we delete it from array
		if( iPart == PART_ERROR_EXTRA_ARGS || iPart != PART_FLAG )
		{
			switch(iPart)
			{
				case PART_ERROR_EXTRA_ARGS:
				{
					LogError("Extra arguments in ConVar part %s", szPartMain);
					
					int i = PART_NONE;
					while(++i < PART_COUNT)
					{
						RemoveFromArray(g_hArrays[i], GetArraySize(g_hArrays[i]) - 1);
					}
				}
			
				default:
				{
					LogError("Skipping ConVar Part: %s (Containing errors)", szPartMain);
					
					new String:szError[256];
					int iLen, iAdd = 0, i = PART_NONE;
				
					iLen = FormatEx(szError, sizeof szError, "Missing arguments in ConVar part (");
					
					while(++i < PART_COUNT)
					{
						if( i < iPart )
						{
							RemoveFromArray(g_hArrays[i], GetArraySize(g_hArrays[i]) - 1);
							PrintToServer("Erasing %d from array", i);
						}
					
						else	// i >= iPart
						{
							iLen += FormatEx(szError[iLen], sizeof(szError) - iLen, "%s%s", iAdd ? ", " : "", szMissing[i]);
							iAdd = 1;
						}
					}
					
					LogError("%s)", szError);
				}
			}
		}
		
		else
		{
			iPart = PART_NONE;
			
			new String:szFlag[25];
			strcopy(szFlag, sizeof szFlag, szPartMini[iIndexMini2]);
			TrimString(szFlag);
			PushArrayString(g_hTempFlagsArray, szFlag);
			
			PushArrayString(g_hSlashAdminStrings, "");
			PushArrayCell(g_hAdminsCountArray, 0);
		}
	}
	
	FilterFlagArray();
}

int CountParts(String:szString[], String:szSplitTocken[])
{
	int iC, iPos, iLen;
	
	while( (iPos = StrContains(szString[iLen], szSplitTocken, false) ) != -1)
	{
		iLen += iPos;
		iC++
	}
	
	return iC + 1;
}

FilterFlagArray()
{
	int iSize = GetArraySize(g_hTempFlagsArray);
	int iFlagBit;
	new String:szFlags[25];
	
	for(int i; i < iSize; i++)
	{
		GetArrayString(g_hTempFlagsArray, i, szFlags, sizeof szFlags);
		iFlagBit = ReadFlagString(szFlags);
		
		PushArrayCell(g_hArrays[ARRAY_ACCESS_FLAG], iFlagBit);
	}
	
	delete (g_hTempFlagsArray);
}