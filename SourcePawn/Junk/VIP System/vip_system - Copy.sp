#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "VIP System",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

#define ADMIN_FLAG_ROOT_VIP ADMFLAG_ROOT | ADMFLAG_RCON

enum VIPFlag
{
	VIPFLAG_ROOT = 1
}

new const String:g_szRootFlagName[] = "root";
new const String:g_szFlagSeperator[] = " ";

bool g_bAdminVIP = false;
int g_iAdminFlag = ADMFLAG_ROOT;

int g_iFlagsCount;
#define MAX_FLAGS 32

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrorMax)
{
	CreateNative("VIP_IsClientVIP", Native_IsClientVIP);
	CreateNative("VIP_GetClientFlags", Native_IsClientVIP);
	CreateNative("VIP_GetClientFlagsNames", Native_GetClientFlagsNames);
	
	CreateNative("VIP_GetRootFlagValue", Native_GetRootValue);
	CreateNative("VIP_CreateFlag", Native_CreateFlag);
	CreateNative("VIP_FindFlag", Native_FindFlag);
	CreateNative("VIP_CreateFlagAlias", Native_CreateFlagAlias);
	CreateNative("VIP_FindFlagAlias", Native_FindFlagAlias);
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("vip_reload_file", AdmCmd_ReloadVIPFile, ADMFLAG_ROOT, "");
	RegAdminCmd("vip_get_flag_value", AdmCmd_GetFlagValue, ADMFLAG_ROOT, "<flag name> - Prints the flag numerical value");
}

public void OnClientPutInServer(client)
{
	
}

public Action AdmCmd_ReloadVIPFile(int client, int iArgs)
{
	return Plugin_Handled;
}

public void OnMapStart()
{
	ReadVIPFile();
}

void ReadVIPFile()
{
	char szFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, szFile, sizeof szFile, "/vips.ini");
	
	File f;
	delete (f = OpenFile(szFile, "r"));
	
	if(f == INVALID_HANDLE)
	{
		WriteNewVIPFile(szFile);
		return;
	}
	
	KeyValues hKv = CreateKeyValues("VIP_Plugin");
	FileToKeyValues(hKv, szFile);
	
	char szSectionName[35];
	char szValue[256];
	
	if(!KvJumpToKey(hKv, "Settings"))
	{
		LogError("Failed to find key \"Settings\"");
	}
	
	else
	{
		KvGotoFirstSubKey(hKv, true);
		KvGetSectionName(hKv, szSectionName, sizeof szSectionName);
		PrintToServer("Key: %s");
		do
		{
			KvGetSectionName(hKv, szSectionName, sizeof szSectionName);
			PrintToServer("Key: %s");
			
			if(StrEqual(szSectionName, "AdminVIP", false))
			{
				g_bAdminVIP = view_as<bool>(KvGetNum(hKv, szSectionName));
			}
			
			else if(StrEqual(szSectionName, "AdminFlags", false))
			{
				KvGetString(hKv, szValue, sizeof szValue);
				
				if(!szValue[0])
				{
					g_iAdminFlags = ADMFLAG_ANY;
				}
				
				else g_iAdminFlags = ReadFlagString(szValue, strlen(szValue)));
			}
		}
		
		while(KvGotoNextKey(hKv, true));
		KvGoBack(hKv);
	}
	
	if(KvJumpToKey("Flags"))
	{
		KvGotoFirstSubKey(hKv, false);
		PrintToServer("Key: %s");
		
		do
		{
			KvGetSectionName(hKv, szSectionName, sizeof szSectionName);
			PrintToServer("Key: %s");
			
			if(StrEqual(szSectionName, "root", false))
			{
				continue;
			}
			
			KvGetString(hKv, NULL_STRING, szValue, sizeof szValue);
			
			if(szValue)
			{
				
			}
		}
		while(KvGotoNextKey(hKv, false));
		KvGoBack(hKv);
	}
	
	if(KvJumpToKey("FlagAliases"))
	{
		KvGotoFirstSubKey(hKv, false);
		
		do
		{
			
		}
		while(KvGotoNextKey(hKv, false));
		
		CheckFlagAliases();
		KvGoBack(hKv);
	}
	
	if(KvJumpToKey("VIPs"))
	{
		KvGotoFirstSubKey(hKv, false);
		
		do
		{
			
		}
		while(KvGotoNextKey(hKv, false));
		KvGoBack(hKv);
	}
	
	delete hKv;
	
	CheckPlayers();
}

void WriteNewVIPFile(char[] szFile)
{
	File f = OpenFile(szFile, "w+");
	
	WriteFileLine(f, "\"VIP_Plugin\"");
	
	WriteFileLine(f, "// ***********\n// USE THIS\n// ***********");
	WriteFileLine(f, "{");
	WriteFileLine(f, "\t\"Settings\"");
	WriteFileLine(f, "\t{");
	WriteFileLine(f, "\t\t\"AdminVIP\"\t\"1\"");
	WriteFileLine(f, "\t\t\"AdminFlag\"\t\"f\"	// Admin Flag required to give him VIP, leave blank to give to all admins");
	WriteFileLine(f, "\t}");
	WriteFileLine(f, "");
	WriteFileLine(f, "\t\"Flags\"");
	WriteFileLine(f, "\t{");
	WriteFileLine(f, "\t\t");
	WriteFileLine(f, "\t}");
	WriteFileLine(f, "");
	WriteFileLine(f, "\t\"FlagAliases\"");
	WriteFileLine(f, "\t{");
	WriteFileLine(f, "\t\t");
	WriteFileLine(f, "\t}");
	WriteFileLine(f, "");
	WriteFileLine(f, "\t\"VIPs\"");
	WriteFileLine(f, "\t{");
	WriteFileLine(f, "\t\t");
	WriteFileLine(f, "\t}");
	WriteFileLine(f, "}");
	
	WriteFileLine(f, "");
	
	WriteFileLine(f, "\"VIP_Example\"");
	WriteFileLine(f, "// THIS IS ONLY FOR EXAMPLES, USE \"VIP\" ABOVE");
	WriteFileLine(f, "{");
	WriteFileLine(f, "\t\"Flags\"	// These can be custom made in plugins too, meaning that you don't have to type them here.");
	WriteFileLine(f, "\t{");
	WriteFileLine(f, "\t\t// Format:\n\t\t// \"flag_name\"\t\"1 or 0\"");
	WriteFileLine(f, "\t\t\"root\"	// Can be removed");
	WriteFileLine(f, "\t\t\"slash_admins\"\t\"1 or 0\"");
	WriteFileLine(f, "\t\t\"command_kick\"\t\"1 or 0\"");
	WriteFileLine(f, "\t\t\"command_multimod\"\t\"1 or 0\"");
	WriteFileLine(f, "\t\t\"command_bla\"\t\"1 or 0\"");
	WriteFileLine(f, "\t}");
	WriteFileLine(f, "");
	WriteFileLine(f, "\t\"FlagAliases\"");
	WriteFileLine(f, "\t{");
	WriteFileLine(f, "\t\t// Format:\n\t\t// \"alias_name\" \"flags\"");
	WriteFileLine(f, "\t\t\"admin\"\t\t\"root\"");
	WriteFileLine(f, "\t\t\"silver\"\t\"slash_admins\"");
	WriteFileLine(f, "\t\t// Can be repeated, and flags will be added together");
	WriteFileLine(f, "\t\t\"golden\"\t\"slash_admins\"");
	WriteFileLine(f, "\t\t\"golden\"\t\"command_multimod\"");
	WriteFileLine(f, "\t\t// Can be expanded");
	WriteFileLine(f, "\t\t\"platinum\"");
	WriteFileLine(f, "\t\t{");
	WriteFileLine(f, "\t\t\t// flags are written directly in this case");
	WriteFileLine(f, "\t\t\t\"command_bla command_kick\"");
	WriteFileLine(f, "\t\t\t\"command_multimod\"");
	WriteFileLine(f, "\t\t}");
	WriteFileLine(f, "\t}");
	WriteFileLine(f, "");
	WriteFileLine(f, "\t\"VIPs\"");
	WriteFileLine(f, "\t{");
	WriteFileLine(f, "\t\t\"STEAM_ID_KHALID_MANAGER\"\t\"root\"");
	WriteFileLine(f, "\t\t\"STEAM_ID_FIRST\"\t\t\"slash_admins command_bla\"");
	WriteFileLine(f, "\t\t// The guy below will have platinum flags which are defined in");
	WriteFileLine(f, "\t\t// FlagAliases");
	WriteFileLine(f, "\t\t\"STEAM_ID_SECOND\"\t\t\"platinum\"");
	WriteFileLine(f, "\t\t// Can Be broken into pieces.");
	WriteFileLine(f, "\t\t\"STEAM_ID_THIRD\"");
	WriteFileLine(f, "\t\t{");
	WriteFileLine(f, "\t\t\t\"flags\"\t\t\"platinum\"");
	WriteFileLine(f, "\t\t\t\"end_time\"\t\"1025448776454\"");
	WriteFileLine(f, "\t\t}");
	WriteFileLine(f, "\t}");
	WriteFileLine(f, "}");
	
	delete f;
}

