#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>

#define PLUGIN_VERSION "2.00"

#define SLASH_MAX_LENGTH	 60
#define DISPLAY_MAX_LENGTH 60
#define MAX_SLASH_NAMES	5
#define No_Admin 		-1

public Plugin myinfo = 
{
	name = "Slash admins", 
	author = "Khalid", 
	description = "/admins in chat", 
	version = PLUGIN_VERSION, 
	url = "No"
};

ArrayList g_Array_DisplayName;
ArrayList g_Array_ConnectNotify;
StringMap g_Trie_SlashCommands;
ArrayList g_Array_AccessFlag;

int g_iClientAdminIndex[MAXPLAYERS];
bool g_bLate = false;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrorLen)
{
	g_bLate = bLate;
}

public void OnPluginStart()
{
	g_Array_DisplayName = CreateArray(DISPLAY_MAX_LENGTH + 1);
	g_Trie_SlashCommands = CreateTrie();
	g_Array_AccessFlag = CreateArray(1);
	g_Array_ConnectNotify = CreateArray(1);
	
	AddCommandListener(CMDListener_Say, "say");
	AddCommandListener(CMDListener_Say, "say_team");
	
	RegAdminCmd("sm_slashadmins_reload", ConCmd_Reload, ADMFLAG_ROOT);
	
	if(!g_bLate)
	{
		ReloadConfig();
	}
}

public void OnMapStart()
{
	ReloadConfig();
	
	if (g_bLate)
	{
		g_bLate = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			OnClientPostAdminCheck(i);
		}
	}
}

public Action ConCmd_Reload(int client, int argc)
{
	ReloadConfig();
	ReplyToCommand(client, "* You have reloaded slash admins file.");
	
	return Plugin_Handled;
}

void ReloadConfig()
{
	g_Array_DisplayName.Clear();
	g_Trie_SlashCommands.Clear();
	g_Array_AccessFlag.Clear();
	g_Array_ConnectNotify.Clear();
	
	char szFile[] = "cfg/sourcemod/slash_admins.ini";
	KeyValues Kv = CreateKeyValues("SlashAdmins");
	
	char Key_DispName[] = "display_name";
	char Key_SlashName[] = "slash_name";
	char Key_Flags[] = "flags";
	char Key_ConnectNotify[] = "connect_notify";
	
	char szName[150];
	
	if (!FileExists(szFile))
	{
		Kv.JumpToKey("Example", true);
		Kv.SetString(Key_DispName, "Head Admin");
		Kv.SetNum(Key_ConnectNotify, 1);
		Kv.SetString(Key_SlashName, "headadmins headadmin ha");
		Kv.SetString(Key_Flags, "z");
		
		Kv.GoBack();
		Kv.ExportToFile(szFile);
	}
	
	else
	{
		Kv.ImportFromFile(szFile);
	}
	
	int iEntry = 0;
	
	if (!(Kv.GotoFirstSubKey(true)))
	{
		//PrintToServer(":(");
		return;
	}
		
	do
	{
		//KvGetSectionName(Kv, szName, sizeof szName);
		//PrintToServer("Section %s", szName);
	
		// Display Name
		Kv.GetString(Key_DispName, szName, sizeof szName, "disabled");
		g_Array_DisplayName.PushString(szName);
		
		//PrintToServer("%s %s", Key_DispName, szName);
		
		// Connect Notify
		g_Array_ConnectNotify.Push(Kv.GetNum(Key_ConnectNotify, 1));
		//PrintToServer("%s %d", Key_ConnectNotify, Kv.GetNum(Key_ConnectNotify, 1));
		
		// Slash names
		Kv.GetString(Key_SlashName, szName, sizeof szName);
		
		int iCount = CountStringParts(szName, " ", true);
		char szStrings[MAX_SLASH_NAMES][SLASH_MAX_LENGTH];
		ExplodeString(szName, " ", szStrings, iCount, sizeof szStrings[], true);
		
		for (int i; i < iCount; i++)
		{
			if (StrContains(szStrings[i], "disable", false) != -1)
			{
				break;
			}
			
			g_Trie_SlashCommands.SetValue(szStrings[i], iEntry);
			//PrintToServer("Command %s", szStrings[i]);
		}
		
		// Flags
		Kv.GetString(Key_Flags, szName, sizeof szName);
		//PrintToServer("%s %s", Key_Flags, szName);
		g_Array_AccessFlag.Push(ReadFlagString(szName));
		
		++iEntry;
	}
	while (Kv.GotoNextKey());
	
	delete Kv;
}

public void OnClientPostAdminCheck(int client)
{
	FindAdminAccess(client);
	//PrintToServer("Clinet Admin Access: %d", g_iClientAdminIndex[client]);
	PrintConnectNotify(client);
}

void FindAdminAccess(int client)
{
	int iSize = g_Array_AccessFlag.Length;
	int iFlags = GetUserFlagBits(client);
	for (int i; i < iSize; i++)
	{
		//PrintToServer("Check %d %d", g_Array_AccessFlag.Get(i), iFlags);
		if (iFlags & (g_Array_AccessFlag.Get(i)))
		{
			g_iClientAdminIndex[client] = i;
			return;
		}
	}
	
	g_iClientAdminIndex[client] = No_Admin;
}

void PrintConnectNotify(int client)
{
	int iIndex = g_iClientAdminIndex[client];
	if (g_iClientAdminIndex[client] == No_Admin)
	{
		return;
	}
	
	if (!(g_Array_ConnectNotify.Get(iIndex)))
	{
		return;
	}
	
	char szNotifyName[DISPLAY_MAX_LENGTH];
	g_Array_DisplayName.GetString(iIndex, szNotifyName, sizeof szNotifyName);
	
	char szString[256];
	FormatEx(szString, sizeof szString, "\x05*** %s LOGIN: \x03%N \x05has connected.", szNotifyName, client);
	CPrintToChatAll(szString);
}

public OnRebuildAdminCache(AdminCachePart part)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		FindAdminAccess(i);
	}
}

int BuildAdminString(int iIndex, char[] szString, int iSize)
{
	int iLen;
	int iCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (g_iClientAdminIndex[i] != iIndex)
		{
			continue;
		}
		
		++iCount;
		iLen += FormatEx(szString[iLen], iSize - iLen, "%s%N", iLen > 0 ? ", " : "", i);
	}
	
	if (!iCount)
	{
		FormatEx(szString, iSize, "None");
	}
	
	return iCount;
}

public Action CMDListener_Say(int client, char[] szCmd, int iArgsC)
{
	char szCmdArg[25];
	int iSuccess;
	
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	char szTriggerCmds[][] =  {
		"all"
	};
	
	if (szCmdArg[0] != '!' && szCmdArg[0] != '/')
	{
		return;
	}
	
	for (new i; i < sizeof szTriggerCmds; i++)
	{
		if (StrEqual(szCmdArg[1], szTriggerCmds[i], false))
		{
			ShowAllAdmins(client);
			iSuccess = 1;
			break;
		}
	}
	
	if (!iSuccess)
	{
		int iValue;
		//PrintToServer("%s", szCmdArg[1]);
		if (g_Trie_SlashCommands.GetValue(szCmdArg[1], iValue) == false)
		{
			return;
		}
		
		ShowAdmins(client, iValue, true);
	}
}

void ShowAllAdmins(int client)
{
	int iCount = 0;
	int iSize = g_Array_DisplayName.Length;
	for (int i; i < iSize; i++)
	{
		iCount += ShowAdmins(client, i, false);
	}
	
	char szString[192];
	FormatEx(szString, sizeof szString, "\x05Total Count: \x03%d", iCount);
	CPrintToChat(client, szString);
}

int ShowAdmins(int client, int iIndex, bool bAddCount = true)
{
	char szString[192];
	int iCount;
	
	char szDisplayName[DISPLAY_MAX_LENGTH];
	g_Array_DisplayName.GetString(iIndex, szDisplayName, sizeof szDisplayName);
	
	int iLen = FormatEx(szString, sizeof szString, "\x05Online \x03%s\x05: \x07", szDisplayName);
	iCount = BuildAdminString(iIndex, szString[iLen], sizeof(szString) - iLen);
	
	CPrintToChat(client, szString);
	
	if(bAddCount)
	{
		FormatEx(szString, sizeof szString, "\x05Total Count: \x03%d", iCount);
		CPrintToChat(client, szString);
	}
	
	return iCount;
}

int CountStringParts(const char[] szString, char[] szSplitTocken, bool bCountRemainder = false)
{
	int iC, iPos, iLen;
	
	while ((iPos = StrContains(szString[iLen], szSplitTocken, false)) != -1)
	{
		iLen += iPos + 1; // Move to the next index (char) after the match.
		iC++;
	}
	
	return bCountRemainder ? iC + 1 : iC;
}