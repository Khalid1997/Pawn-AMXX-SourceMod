#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <dbi>
#include <vip_const>

public Plugin myinfo = 
{
	name = "VIP System", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

bool g_bDebug = true;

#define FLAGMODE_CONTAIN	2
#define FLAGMODE_EQUAL	3

enum
{
	VIPData_Flags, 
	VIPData_EndTime, 
	
	VIPData_Total
};

StringMap g_Trie_VIPs;
int g_iClientFlags[MAXPLAYERS];

ArrayList g_Array_FeatureName;
ArrayList g_Array_FeatureFlags;
ArrayList g_Array_FeatureFlagMode;

ArrayList g_Array_AdminFlags;
ArrayList g_Array_AdminFlagMode;
ArrayList g_Array_AdminGivenVIPFlags;

StringMap g_Trie_FeatureIndexes;

/* ---- FileKeys ----- */
#define DEFAULT_DEBUG 1
new const String:KEY_SETTINGS[] = "Settings";
new const String:KEY_DEBUG[] = "Debug";

new const String:KEY_ADMINVIP[] = "AdminVIP";
new const String:KEY_ADMINVIP_FLAGS[] = "admin_flags";
new const String:KEY_ADMINVIP_FLAGSMODE[] = "admin_flags_mode";
new const String:KEY_ADMINVIP_GIVENFLAGS[] = "given_vip_flags";

new const String:KEY_FLAGSOVERRIDE[] = "OverrideFlags";
//new const String:KEY_FLAGSOVERRIDE_FEATURENAME[] = "feature";
new const String:KEY_FLAGSOVERRIDE_FLAGS[] = "flags";
new const String:KEY_FLAGSOVERRIDE_FLAGSMODE[] = "flags_mode";

new const String:KEY_VIPLIST[] = "VIPList";
new const String:KEY_VIPLIST_FLAGS[] = "flags";
new const String:KEY_VIPLIST_ENDTIME[] = "end_time";

/* ---- FileKeys ----- */

#define LOGTYPE_SECTION_NOT_FOUND 1
#define LOGTYPE_SECTION_NO_SUBS 2
#define LOGTYPE_SECTION_NORMAL	3

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrorMax)
{
	CreateNative("VIP_GetClientFlagsBit", Native_GetClientFlagsBit);
	//CreateNative("VIP_GetClientFlagsString", Native_GetClientFlagsString);
	
	CreateNative("VIP_RegisterFeature", Native_RegisterFeature);
	CreateNative("VIP_HasClientFeature", Native_HasClientFeature);
	CreateNative("VIP_GetFeatureFlags", Native_GetFeatureFlags);
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_Trie_VIPs = CreateTrie();
	
	g_Array_FeatureName = CreateArray(MAX_FEATURE_NAME);
	g_Array_FeatureFlags = CreateArray(1);
	g_Array_FeatureFlagMode = CreateArray(1);
	
	g_Array_AdminFlags = CreateArray(1);
	g_Array_AdminFlagMode = CreateArray(1);
	g_Array_AdminGivenVIPFlags = CreateArray(1);
	
	RegAdminCmd("vip_reload_file", AdmCmd_ReloadVIPFile, ADMFLAG_ROOT, "");
	RegAdminCmd("vip_list", AdmCmd_List, ADMFLAG_ROOT, "<feature/viplist> - List registered features and VIPs");
	RegAdminCmd("viplist", AdmCmd_List, ADMFLAG_ROOT, "<feature/viplist> - List registered features and VIPs");
}

public Action AdmCmd_ReloadVIPFile(int client, int iArgs)
{
	ReloadVIPStuff();
	ReplyToCommand(client, "* Successfuly reloaded the VIP File");
	
	return Plugin_Handled;
}

public Action AdmCmd_List(int client, int iArgs)
{
	if (iArgs < 1)
	{
		ReplyToCommand(client, "<featurelist/viplist/adminflag> - Lists registered features and VIPs");
		return Plugin_Handled;
	}
	
	char szArg[15];
	GetCmdArg(1, szArg, sizeof szArg);
	
	int iSize;
	char szFlags[15];
	
	if (StrEqual(szArg, "adminflag", false) || StrEqual(szArg, "admin"))
	{
		ReplyToCommand(client, "-- Listing Start: Admin List");
		ReplyToCommand(client, "%-2s %-21s %-13s %s", "##", "\"Admin Flags\"", "\"Flags Mode\"", "\"Given VIP Flags\"");
		
		iSize = GetArraySize(g_Array_AdminFlags);
		int iAdminFlagsBit, iFlagMode, iGivenVIPFlags;
		bool bAdminFlagArray[AdminFlags_TOTAL];
		
		int iLen, iChar;
		char szAdminFlagsString[22];
		
		for (int i; i < iSize; i++)
		{
			iFlagMode = GetArrayCell(g_Array_AdminFlagMode, i);
			iAdminFlagsBit = GetArrayCell(g_Array_AdminFlags, i);
			iGivenVIPFlags = GetArrayCell(g_Array_AdminGivenVIPFlags, i);
			
			FlagsBitToString(iGivenVIPFlags, szFlags, sizeof szFlags);
			FlagBitsToBitArray(iAdminFlagsBit, bAdminFlagArray, sizeof bAdminFlagArray);
			
			iLen = 0;
			for (int j = view_as<int>(Admin_Reservation); j < AdminFlags_TOTAL; j++)
			{
				if (bAdminFlagArray[j] == true)
				{
					FindFlagChar(view_as<AdminFlag>(j), iChar);
					szAdminFlagsString[iLen++] = iChar;
				}
			}
			
			szAdminFlagsString[iLen] = 0;
			ReplyToCommand(client, "%-2s %-21s %-13s %s", i + 1, szAdminFlagsString, iFlagMode == FLAGMODE_CONTAIN ? "contain" : "equal", szFlags);
		}
		
		ReplyToCommand(client, "-- Listing End");
	}
	
	if (StrEqual(szArg, "features", false) || StrEqual(szArg, "featurelist", false))
	{
		ReplyToCommand(client, "-- Listing Start: Feature List");
		ReplyToCommand(client, "%-2s %-15s %-15s %s", "##", "\"Feature Name\"", "\"Flags\"", "\"Flags Mode\"");
		
		char szFeatureName[MAX_FEATURE_NAME];
		int iFlagsMode;
		iSize = GetArraySize(g_Array_FeatureName);
		
		for (int i; i < iSize; i++)
		{
			GetArrayString(g_Array_FeatureName, i, szFeatureName, sizeof szFeatureName);
			FlagsBitToString(GetArrayCell(g_Array_FeatureFlags, i), szFlags, sizeof szFlags);
			iFlagsMode = GetArrayCell(g_Array_FeatureFlagMode, i);
			
			ReplyToCommand(client, "%-2d %-15s %-15s %s", i + 1, szFeatureName, szFlags, iFlagsMode == FLAGMODE_EQUAL ? "Equal" : "Contain");
		}
		
		ReplyToCommand(client, "-- Listing End");
	}
	
	else if (StrEqual(szArg, "viplist", false) || StrEqual(szArg, "vip", false))
	{
		ReplyToCommand(client, "-- Listing Start: VIPList");
		ReplyToCommand(client, "%-2s %-35s %-15s %-26s %-3s", "##", "\"SteamID\"", "\"Flags\"", "\"End Time\"", "\"Active\"");
		
		Handle hSnapShot = CreateTrieSnapshot(g_Trie_VIPs);
		
		char szAuthId[35];
		int Data[VIPData_Total];
		char szTimeFmt[35];
		int iSysTime = GetTime();
		
		iSize = TrieSnapshotLength(hSnapShot);
		for (int i; i < iSize; i++)
		{
			GetTrieSnapshotKey(hSnapShot, i, szAuthId, sizeof szAuthId);
			GetTrieArray(g_Trie_VIPs, szAuthId, Data, sizeof Data);
			
			FlagsBitToString(Data[VIPData_Flags], szFlags, sizeof szFlags);
			
			if (!Data[VIPData_EndTime])
			{
				ReplyToCommand(client, "%-2d %-35s %-15s %-26s %-3s", i + 1, szAuthId, szFlags, "Infinite", "yes");
			}
			
			else
			{
				FormatTime(szTimeFmt, sizeof szTimeFmt, "%c", Data[VIPData_EndTime]);
				ReplyToCommand(client, "%-2d %-35s %-15s %-26s %-3s", i + 1, szAuthId, szFlags, szTimeFmt, Data[VIPData_EndTime] > iSysTime ? "yes" : "no");
			}
		}
		
		ReplyToCommand(client, "-- Listing End");
		delete hSnapShot;
	}
	
	return Plugin_Handled;
}

int FlagsBitToString(int iFlags, char[] szString, int iSize)
{
	if (iFlags & VIPFLAG_ROOT)
	{
		return FormatEx(szString, iSize, "root");
	}
	
	int iWrittenCells;
	for (int i = VIP_A; i < VIP_Total; i++)
	{
		if (iFlags & (1 << i))
		{
			if (iWrittenCells < iSize)
			{
				szString[iWrittenCells++] = g_szVIPFlagLetters[i];
			}
		}
	}
	
	szString[iWrittenCells++] = 0;
	return iWrittenCells;
}

public void OnMapStart()
{
	ReloadVIPStuff();
}

public void OnClientAuthorized(int client, const char[] szAuthId)
{
	g_iClientFlags[client] = GetClientFlags(client, szAuthId);
}

int GetClientFlags(int client, const char[] szAuthId)
{
	any Data[VIPData_Total];
	if (!GetTrieArray(g_Trie_VIPs, szAuthId, Data, sizeof Data))
	{
		int iFlags = CheckClientAdminFlags(client);
		if (iFlags != VIPFLAG_NONE)
		{
			return iFlags;
		}
		return VIPFLAG_NONE;
	}
	
	return Data[VIPData_Flags];
}

int CheckClientAdminFlags(int client)
{
	int iFlags = GetUserFlagBits(client);
	if (!iFlags)
	{
		return VIPFLAG_NONE;
	}
	
	for (int i, iSize = GetArraySize(g_Array_AdminFlags), iCheckFlag, iFlagMode; i < iSize; i++)
	{
		iCheckFlag = GetArrayCell(g_Array_AdminFlags, i);
		iFlagMode = GetArrayCell(g_Array_AdminFlagMode, i);
		
		switch (iFlagMode)
		{
			case FLAGMODE_CONTAIN:
			{
				if (iFlagMode & iCheckFlag)
				{
					return GetArrayCell(g_Array_AdminGivenVIPFlags, i);
				}
			}
			
			case FLAGMODE_EQUAL:
			{
				if ((iFlagMode & iCheckFlag) == iCheckFlag)
				{
					return GetArrayCell(g_Array_AdminGivenVIPFlags, i);
				}
			}
		}
	}
	
	return VIPFLAG_NONE;
}

void ReloadVIPStuff()
{
	ClearTrie(g_Trie_VIPs);
	
	ClearArray(g_Array_AdminFlags);
	ClearArray(g_Array_AdminFlagMode);
	ClearArray(g_Array_AdminGivenVIPFlags);
	
	ReadVIPFile();
}

void ReadVIPFile()
{
	char szFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/vips.cfg");
	
	File f;
	delete(f = OpenFile(szFile, "r"));
	
	if (f == INVALID_HANDLE)
	{
		WriteNewVIPFile(szFile);
		return;
	}
	
	KeyValues hKv = CreateKeyValues("VIP", "");
	
	if (FileToKeyValues(hKv, szFile))
	{
		PrintToServer("True");
	}
	
	Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, "");
	
	if (KvJumpToKey(hKv, KEY_SETTINGS, false))
	{
		GetSettings(hKv);
		KvGoBack(hKv);
	}
	else LogError("Could not find '%s' Section", KEY_SETTINGS);
	
	if (KvJumpToKey(hKv, KEY_FLAGSOVERRIDE, false))
	{
		GetOverridenFlags(hKv);
		KvGoBack(hKv);
	}
	else LogError("Could not find '%s' Section", KEY_FLAGSOVERRIDE);
	
	if (KvJumpToKey(hKv, KEY_VIPLIST, false))
	{
		GetVIPList(hKv);
		KvGoBack(hKv);
	}
	else LogError("Could not find '%s' Section", KEY_VIPLIST);
	
	delete hKv;
}

void GetVIPList(KeyValues hKv)
{
	char szAuthId[35];
	char szFlags[15];
	
	int iSysTime = GetTime();
	int iEndTime = 0;
	char szSectionName[35];
	
	KvGotoFirstSubKey(hKv, false);
	
	do
	{
		Debug_Message("Enter #0");
		
		Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, KEY_VIPLIST);
		
		iEndTime = 0;
		szFlags[0] = 0;
		
		KvGetSectionName(hKv, szAuthId, sizeof szAuthId);
		
		if (KvGotoFirstSubKey(hKv, false))
		{
			Debug_Message("Enter #1");
			
			do
			{
				Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, KEY_VIPLIST);
				
				KvGetSectionName(hKv, szSectionName, sizeof szSectionName);
				if (StrEqual(szSectionName, KEY_VIPLIST_FLAGS))
				{
					KvGetString(hKv, NULL_STRING, szFlags, sizeof szFlags);
				}
				
				else if (StrEqual(szSectionName, KEY_VIPLIST_ENDTIME))
				{
					Debug_Message("EndTime: %d", iEndTime);
					iEndTime = KvGetNum(hKv, NULL_STRING);
				}
				
				else
				{
					LogError("Unknown Section '%s'", szSectionName);
				}
			}
			while (KvGotoNextKey(hKv, false));
			
			KvGoBack(hKv);
		}
		
		else
		{
			Debug_Message("Enter #2");
			Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, KEY_VIPLIST);
			
			KvGetString(hKv, NULL_STRING, szFlags, sizeof szFlags);
		}
		
		AddAuthIdToVIP(szAuthId, szFlags, iEndTime, iSysTime);
	}
	while (KvGotoNextKey(hKv, true));
}

void AddAuthIdToVIP(char[] szAuthId, char[] szFlags, int iEndTime, int iSysTime)
{
	if (iEndTime && iSysTime > iEndTime)
	{
		char szTimeFmt[25];
		FormatTime(szTimeFmt, sizeof szTimeFmt, "%c", iEndTime);
		LogMessage("AuthID: '%s' has expired @ %s", szAuthId, szTimeFmt);
	}
	
	char szInvalidFlags[12];
	if (!CheckFlags(szFlags, szInvalidFlags, sizeof szInvalidFlags))
	{
		LogError("VIPFlags Error: Flags '%s' are invalid on SteamID: '%s'", szInvalidFlags, szAuthId);
		return;
	}
	
	Debug_Message("Add Client: %s %s %d", szAuthId, szFlags, iEndTime);
	
	any Data[VIPData_Total];
	Data[VIPData_Flags] = FlagsToBit(szFlags);
	Data[VIPData_EndTime] = iEndTime;
	
	SetTrieArray(g_Trie_VIPs, szAuthId, Data, sizeof Data, true);
}

void GetOverridenFlags(KeyValues hKv)
{
	char szFlags[MAX_FLAGS_STRING];
	char szFlagsMode[10]; int iFlagMode;
	char szFeatureName[MAX_FEATURE_NAME];
	char szSectionName[35];
	
	if (!KvGotoFirstSubKey(hKv, true))
	{
		Debug_LogSection(LOGTYPE_SECTION_NO_SUBS, hKv, KEY_FLAGSOVERRIDE);
		return;
	}
	
	do
	{
		Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, KEY_FLAGSOVERRIDE);
		KvGetSectionName(hKv, szFeatureName, sizeof szFeatureName);
		
		if (KvGotoFirstSubKey(hKv, true))
		{
			do
			{
				Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, KEY_FLAGSOVERRIDE);
				KvGetSectionName(hKv, szSectionName, sizeof szSectionName);
				
				if (StrEqual(szSectionName, KEY_FLAGSOVERRIDE_FLAGS))
				{
					KvGetString(hKv, NULL_STRING, szFlags, sizeof szFlags, "");
				}
				
				if (StrEqual(szSectionName, KEY_FLAGSOVERRIDE_FLAGSMODE))
				{
					KvGetString(hKv, NULL_STRING, szFlagsMode, sizeof szFlagsMode, "contian");
					if (StrEqual(szFlagsMode, "contain", false))
					{
						iFlagMode = FLAGMODE_CONTAIN;
					}
					
					if (StrEqual(szFlagsMode, "equal", false))
					{
						iFlagMode = FLAGMODE_EQUAL;
					}
					
					else
					{
						iFlagMode = FLAGMODE_DEFAULT;
						LogMessage("Flags mode '%s' is unknown. Defaulting to contain", szFlagsMode);
					}
				}
			}
			while (KvGotoNextKey(hKv, true));
			
			KvGoBack(hKv);
		}
		
		else
		{
			KvGetString(hKv, NULL_STRING, szFlags, sizeof szFlags);
		}
		
		OverrideFeatureFlag(szFeatureName, szFlags, iFlagMode);
	}
	while (KvGotoNextKey(hKv, true));
}

void OverrideFeatureFlag(char[] szFeatureName, char[] szFlags, int iFlagsMode)
{
	char szInvalidFlags[MAX_FLAGS_STRING];
	
	if (!CheckFlags(szFlags, szInvalidFlags, sizeof szInvalidFlags))
	{
		LogMessage("Flags '%s' are invalid for feature '%s'", szInvalidFlags, szFeatureName);
		return;
	}
	
	int iIndex;
	if (!GetFeatureIndex(szFeatureName, iIndex))
	{
		LogMessage("Feature '%s' is not valid to override.");
		return;
	}
	
	Debug_Message("FeatureName: '%s' - Flags: %s - FlagsMode: %d", szFeatureName, szFlags, iFlagsMode);
	
	int iFlagsBit = FlagsToBit(szFlags);
	SetArrayCell(g_Array_FeatureFlags, iIndex, iFlagsBit);
	SetArrayCell(g_Array_FeatureFlagMode, iIndex, iFlagsMode);
}

// -1 if not found;
bool GetFeatureIndex(char[] szFeatureName, int &iIndex)
{
	if (!GetTrieValue(g_Trie_FeatureIndexes, szFeatureName, iIndex))
	{
		iIndex = FEATURE_INDEX_INVALID;
		return false;
	}
	
	return true;
}

bool CheckFlags(char[] szFlags, char[] szInvalidFlags = "", iSize = 0)
{
	if (StrEqual(szFlags, "root"))
	{
		return true;
	}
	
	int iFlagsCount = strlen(szFlags);
	int iLen;
	
	for (int i, iFound; i < iFlagsCount; i++)
	{
		iFound = 0;
		for (int j; j < sizeof g_szVIPFlagLetters; j++)
		{
			if (szFlags[i] == g_szVIPFlagLetters[j])
			{
				iFound = 1;
				break;
			}
		}
		
		if (!iFound)
		{
			if (iLen < iSize)
			{
				szInvalidFlags[iLen++] = szFlags[i];
				Debug_Message("Invalid flag %c", szFlags[i]);
			}
		}
		
		else iFound = 0;
	}
	
	if (iLen < iSize)
	{
		szInvalidFlags[iLen] = '\0';
	}
	
	if (iLen > 0)
	{
		Debug_Message("Return false: iLen = %d", iLen);
		return false;
	}
	
	return true;
}

int FlagsToBit(char[] szFlags)
{
	if (StrEqual(szFlags, "root"))
	{
		return VIPFLAG_ROOT;
	}
	
	if (StrContains(szFlags, g_szVIPFlagString[VIP_Root], true) != -1)
	{
		return VIPFLAG_ROOT;
	}
	
	int iSize = strlen(szFlags);
	int iFlags;
	for (int iPos = 0; iPos < iSize; iPos++)
	{
		for (int i = VIP_A; i < VIP_Total; i++)
		{
			if (szFlags[iPos] == g_szVIPFlagLetters[i])
			{
				iFlags |= (1 << i);
				Debug_Message("Add Flag to bit: %c", szFlags[iPos]);
			}
		}
	}
	
	return iFlags;
}

void GetSettings(KeyValues hKv)
{
	char szSectionName[35];
	char szValue[256];
	
	//KvGotoFirstSubKey(hKv, true);
	
	g_bDebug = view_as<bool>(KvGetNum(hKv, KEY_DEBUG, DEFAULT_DEBUG));
	
	if (!KvJumpToKey(hKv, KEY_ADMINVIP, false))
	{
		Debug_LogSection(LOGTYPE_SECTION_NOT_FOUND, hKv, KEY_SETTINGS, KEY_ADMINVIP);
		LogError("Could not find Section '%s' to parse the Admins who are VIPs", KEY_ADMINVIP);
		
		KvGoBack(hKv);
	}
	
	else
	{
		int iAdminFlags = 0;
		int iAdminGivenVIPFlags = VIPFLAG_NONE;
		int iAdminFlagMode = FLAGMODE_CONTAIN;
		char szInvalidFlags[15];
		
		Debug_Message("Found Section %s", KEY_ADMINVIP);
		
		if (!KvGotoFirstSubKey(hKv, true))
		{
			Debug_LogSection(LOGTYPE_SECTION_NO_SUBS, hKv, KEY_SETTINGS);
		}
		
		else
		{
			do
			{
				Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, KEY_SETTINGS);
				
				if (!KvGotoFirstSubKey(hKv, false))
				{
					Debug_LogSection(LOGTYPE_SECTION_NO_SUBS, hKv, KEY_SETTINGS);
					continue;
				}
				
				iAdminFlags = 0;
				iAdminGivenVIPFlags = VIPFLAG_NONE;
				iAdminFlagMode = FLAGMODE_CONTAIN;
				
				do
				{
					Debug_LogSection(LOGTYPE_SECTION_NORMAL, hKv, KEY_SETTINGS);
					KvGetSectionName(hKv, szSectionName, sizeof szSectionName);
					
					if (StrEqual(szSectionName, KEY_ADMINVIP_FLAGS))
					{
						KvGetString(hKv, NULL_STRING, szValue, sizeof szValue, "");
						iAdminFlags = ReadFlagString(szValue);
					}
					else if (StrEqual(szSectionName, KEY_ADMINVIP_FLAGSMODE))
					{
						KvGetString(hKv, NULL_STRING, szValue, sizeof szValue, "");
						
						if (StrEqual(szValue, "contain"))
						{
							iAdminFlagMode = FLAGMODE_CONTAIN;
						}
						
						else if (StrEqual(szValue, "equal"))
						{
							iAdminFlagMode = FLAGMODE_EQUAL;
						}
						
						else
						{
							iAdminFlagMode = FLAGMODE_DEFAULT;
							LogMessage("Flags mode '%s' is unknown. Defaulting to %s", szValue, iAdminFlagMode == FLAGMODE_EQUAL ? "equal" : "contian");
						}
					}
					else if (StrEqual(szSectionName, KEY_ADMINVIP_GIVENFLAGS))
					{
						KvGetString(hKv, NULL_STRING, szValue, sizeof szValue, "");
						
						Debug_Message("GIVEN FLAGS VALUE: %s", szValue);
						if (!CheckFlags(szValue, szInvalidFlags, sizeof szInvalidFlags))
						{
							LogError("Flags '%s' are invalid.", szValue);
							break;
						}
						
						iAdminGivenVIPFlags = FlagsToBit(szValue);
					}
				}
				while (KvGotoNextKey(hKv, false));
				KvGoBack(hKv);
				
				// handle values here.
				if (iAdminGivenVIPFlags == VIPFLAG_NONE)
				{
					Debug_Message("Flags = %d", iAdminGivenVIPFlags);
					continue;
				}
				
				Debug_Message("AdminFlags: %d .. VIPGivenFlags %d FlagsMode %d", iAdminFlags, iAdminGivenVIPFlags, iAdminFlagMode);
				
				PushArrayCell(g_Array_AdminFlags, iAdminFlags);
				PushArrayCell(g_Array_AdminGivenVIPFlags, iAdminGivenVIPFlags);
				PushArrayCell(g_Array_AdminFlagMode, iAdminFlagMode);
			}
			while (KvGotoNextKey(hKv, true));
			
			KvGoBack(hKv);
		}
		
		KvGoBack(hKv);
	}
}

void WriteNewVIPFile(char[] szFile)
{
	File f = OpenFile(szFile, "w+");
	
	delete f;
}

public int Native_GetClientFlagsBit(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if (!CheckClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client (%d) is not valid. (Not connected)");
		return VIPFLAG_NONE;
	}
	
	char szAuthId[35];
	GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	
	return GetClientFlags(client, szAuthId);
}

bool CheckClient(int client)
{
	if (!(0 < client <= MaxClients))
	{
		return false;
	}
	
	if (!IsClientInGame(client))
	{
		return false;
	}
	
	return true;
}

public int Native_RegisterFeature(Handle hPlugin, int iArgs)
{
	char szFeatureName[MAX_FEATURE_NAME];
	GetNativeString(1, szFeatureName, sizeof szFeatureName);
	
	int iIndex;
	if (GetFeatureIndex(szFeatureName, iIndex))
	{
		return iIndex;
	}
	
	
	int iFlags = GetNativeCell(2);
	
	// Do later
	/*
	if(!CheckFlags(iFlags))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "FlagsBit contains invalid flags (%d)", iFlags);
		return FEATURE_INDEX_INVALID;
	}
	*/
	
	int iFlagsMode = GetNativeCell(3);
	if (iFlagsMode != FLAGMODE_CONTAIN && iFlagsMode != FLAGMODE_EQUAL)
	{
		ThrowNativeError(SP_ERROR_ABORTED, "FlagsMode is not valid. (%d)", iFlagsMode);
		return FEATURE_INDEX_INVALID;
	}
	
	Debug_Message("FeatureName: '%s' - Flags: %d - FlagsMode %d", szFeatureName, iFlags, iFlagsMode);
	
	PushArrayString(g_Array_FeatureName, szFeatureName);
	PushArrayCell(g_Array_FeatureFlags, iFlags);
	PushArrayCell(g_Array_FeatureFlagMode, iFlagsMode);
	
	SetTrieValue(g_Trie_FeatureIndexes, szFeatureName, (iIndex = GetArraySize(g_Array_FeatureName) - 1));
	return iIndex;
}

public int Native_HasClientFeature(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	int iIndex = GetNativeCell(2);
	
	if (!CheckClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client (%d) is not valid. (Not connected)");
		return VIPFLAG_NONE;
	}
	
	if (!CheckFeatureIndex(iIndex))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Feature Index is invalid. (%d)", iIndex);
		return 0;
	}
	
	return view_as<int>(CheckClientFeature(client, iIndex));
}

bool CheckFeatureIndex(int iIndex)
{
	if (!(-1 < iIndex < GetArraySize(g_Array_FeatureName)))
	{
		return false;
	}
	
	return true;
}

public int Native_GetFeatureFlags(Handle hPlugin, int iArgs)
{
	int iIndex = GetNativeCell(1);
	if (!CheckFeatureIndex(iIndex))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Feature Index is invalid. (%d)", iIndex);
		return 0;
	}
	
	SetNativeCellRef(2, GetArrayCell(g_Array_FeatureFlags, iIndex));
	SetNativeCellRef(3, GetArrayCell(g_Array_FeatureFlagMode, iIndex));
	return 1;
}

bool CheckClientFeature(int client, int iIndex)
{
	if (g_iClientFlags[client] & VIPFLAG_ROOT)
	{
		return true;
	}
	
	int iFeatureFlags = GetArrayCell(g_Array_FeatureFlags, iIndex);
	int iFeatureFlagMode = GetArrayCell(g_Array_FeatureFlagMode, iIndex);
	
	switch (iFeatureFlagMode)
	{
		case FLAGMODE_CONTAIN:
		{
			if (g_iClientFlags[client] & iFeatureFlags)
			{
				return true;
			}
		}
		
		case FLAGMODE_EQUAL:
		{
			if ((g_iClientFlags[client] & iFeatureFlags) == iFeatureFlags)
			{
				return true;
			}
		}
	}
	
	return false;
}

// ----------------------------------------------------------------------
// 						Stocks
// ----------------------------------------------------------------------

void Debug_Message(char[] szMessage, any:...)
{
	if (!g_bDebug)
	{
		return;
	}
	
	char szBuffer[1024];
	VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
	
	LogMessage(szBuffer);
}

void Debug_LogSection(int iLogType, KeyValues hKv, const char[] szParentSection = "", const char[] szNotFoundSectionName = "")
{
	if (!g_bDebug)
	{
		return;
	}
	
	char szSectionName[35];
	char szValue[35];
	KvGetSectionName(hKv, szSectionName, sizeof szSectionName);
	
	switch (iLogType)
	{
		case LOGTYPE_SECTION_NOT_FOUND:
		{
			LogMessage("ParentSection: %-12s -- Tree: %d -- Section: '%-12s' -> Not found section '%s'", szParentSection, KvNodesInStack(hKv), szSectionName, szNotFoundSectionName);
		}
		
		case LOGTYPE_SECTION_NO_SUBS:
		{
			LogMessage("ParentSection: %-12s -- Tree: %d -- Section: '%-12s' -> No Sub-Keys", szParentSection, KvNodesInStack(hKv), szSectionName);
		}
		
		case LOGTYPE_SECTION_NORMAL:
		{
			KvGetString(hKv, NULL_STRING, szValue, sizeof szValue);
			LogMessage("ParentSection: %-12s -- Tree: %d -- Section: '%-12s' -- Value: %s", szParentSection, KvNodesInStack(hKv), szSectionName, szValue);
		}
	}
}
