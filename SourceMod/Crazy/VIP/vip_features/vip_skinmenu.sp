#if defined SKIN_MENU_ENABLED
#endinput
#endif

#define SKIN_MENU_ENABLED

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <cstrike>
#include <fdownloader>
#include <thirdperson>
#include <multicolors>

#undef REQUIRE_PLUGIN
#tryinclude <multimod>
#undef REQUIRE_PLUGIN
#include <vipsys>
#undef REQUIRE_PLUGIN
#include <tvip>

bool g_bIsVIP[MAXPLAYERS];

#define Team_First_Bit		( 1 << (CS_TEAM_T+1) )
#define Team_Second_Bit	( 1 << (CS_TEAM_CT+1) )

#define Team_First	0
#define Team_Second 1

#define MAX_SKIN_KEY_LENGTH	21
#define MAX_SKIN_NAME_LENGTH 35
#define MAX_INFO_LENGTH	25

#define No_Skin -1

ArrayList g_Array_SkinPaths;
ArrayList g_Array_SkinNames;
ArrayList g_Array_SkinTeams;
ArrayList g_Array_SkinKeys;

#define GetClientTeamBit(%1)		( 1<<(GetClientTeam(%1) + 1) )

int g_iPlayerEquippedSkin[MAXPLAYERS] = { No_Skin, ... };
int g_iPlayerSavedSkin[MAXPLAYERS][2];

Handle g_hCookie_Skin_TeamFirst, 
g_hCookie_Skin_TeamSecond;

int g_iLastSkinMenuSelectionPosition[MAXPLAYERS];

char MENU_ITEM_INFO[] = "vip_menu_skins";
Handle g_hForward;

#if defined _multimod_included
bool g_bMultiMod = false;
int g_iRestrictedTeams;
#endif

bool g_bLate;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrMax)
{
	g_bLate = bLate;
	g_hForward = CreateGlobalForward("VIP_SkinMenu_OnSkinChange", ET_Ignore, Param_Cell);
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] szName)
{
	#if defined _multimod_included
	if(StrEqual(szName, MM_LIB_BASE))
	{
		g_bMultiMod = true;
	}
	#endif
}

public void OnLibraryRemove(const char[] szName)
{
	#if defined _multimod_included
	if(StrEqual(szName, MM_LIB_BASE))
	{
		g_bMultiMod = false;
	}
	#endif
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_skins", Command_Skins);
	
	g_Array_SkinPaths = new ArrayList(PLATFORM_MAX_PATH);
	g_Array_SkinNames = new ArrayList(MAX_SKIN_NAME_LENGTH);
	g_Array_SkinTeams = new ArrayList(1);
	g_Array_SkinKeys = new ArrayList(MAX_SKIN_KEY_LENGTH);
	
	g_hCookie_Skin_TeamFirst = RegClientCookie("skins_team_first", "T Skin", CookieAccess_Protected);
	g_hCookie_Skin_TeamSecond = RegClientCookie("skins_team_second", "CT Skin", CookieAccess_Protected);
	
	HookEvent("player_spawn", Event_SkinMenu_PlayerSpawn);
	
	if(g_bLate)
	{
		bool bVIPSys = LibraryExists("vipsys");
		bool bTVIP = LibraryExists("tVip");
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				continue;
			}
			
			if( bVIPSys && VIPSys_Client_IsVIP(i))
			{
				g_bIsVIP[i] = true;
			}
			
			else if(bTVIP && tVip_IsVip(i))
			{
				g_bIsVIP[i] = true;
			}
			
			else	g_bIsVIP[i] = false;
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem(MENU_ITEM_INFO, "Skin Menu", MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenu_SkinMenuItem, 9);
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem(MENU_ITEM_INFO);
	
	#if defined _multimod_included
	g_bMultiMod = LibraryExists(MM_LIB_BASE);
	#endif
}

public int VIPMenu_SkinMenuItem(Menu menu, char[] szInfo, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		ShowSkinsMenu(param1, 0, g_bIsVIP[param1]);
	}
}

public void Event_SkinMenu_PlayerSpawn(Event event, char[] szEventName, bool bDontBroadcast)
{
	int iUserId = GetEventInt(event, "userid");
	RequestFrame(NextFrame_SetSkin, iUserId);
}

public void OnClientPutInServer(int client)
{
	g_bIsVIP[client] = false;
}

public void NextFrame_SetSkin(int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	
	if (!client)
	{
		return;
	}
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if(IsFakeClient(client))
	{
		return;
	}
	
	EquipPlayerSkin(client, g_iPlayerSavedSkin[client][CGetClientTeam(client)]);
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	//SetClientInspectMode(client, false);
	
	char szKey[MAX_SKIN_KEY_LENGTH];
	if (g_iPlayerSavedSkin[client][Team_First] != No_Skin)
	{
		g_Array_SkinKeys.GetString(g_iPlayerSavedSkin[client][Team_First], szKey, sizeof szKey);
		SetClientCookie(client, g_hCookie_Skin_TeamFirst, szKey);
	}
	else
	{
		SetClientCookie(client, g_hCookie_Skin_TeamFirst, "");
	}
	
	if (g_iPlayerSavedSkin[client][Team_Second] != No_Skin)
	{
		g_Array_SkinKeys.GetString(g_iPlayerSavedSkin[client][Team_Second], szKey, sizeof szKey);
		SetClientCookie(client, g_hCookie_Skin_TeamSecond, szKey);
	}
	else
	{
		SetClientCookie(client, g_hCookie_Skin_TeamSecond, "");
	}
	
	g_iPlayerSavedSkin[client][Team_First] = No_Skin;
	g_iPlayerSavedSkin[client][Team_Second] = No_Skin;
	g_iPlayerEquippedSkin[client] = No_Skin;
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	if(!g_bIsVIP[client])
	{
		g_iPlayerSavedSkin[client][Team_First] = No_Skin;
		g_iPlayerSavedSkin[client][Team_Second] = No_Skin;
		
		return;
	}
	
	char szSkinKey[MAX_SKIN_KEY_LENGTH];
	GetClientCookie(client, g_hCookie_Skin_TeamFirst, szSkinKey, sizeof szSkinKey);
	g_iPlayerSavedSkin[client][Team_First] = FindStringInArray(g_Array_SkinKeys, szSkinKey);
	
	GetClientCookie(client, g_hCookie_Skin_TeamSecond, szSkinKey, sizeof szSkinKey);
	g_iPlayerSavedSkin[client][Team_Second] = FindStringInArray(g_Array_SkinKeys, szSkinKey);
}

public void tVip_OnClientLoadedPost(int client, bool bIsVIP)
{
	VIPSys_Client_OnCheckVIP(client, bIsVIP);
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	g_bIsVIP[client] = bIsVIP;
	
	if(AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}

public Action Command_Skins(int client, int args)
{
	ShowSkinsMenu(client, 0, g_bIsVIP[client]);
	return Plugin_Handled;
}

void ShowSkinsMenu(int client, int iItem, bool bWithAccess = true)
{
	int iDrawItem = bWithAccess ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	int iSize = g_Array_SkinNames.Length;
	
	if(!iSize)
	{
		CPrintToChat(client, "There are no skins to choose from.");
		return;
	}
	
	Menu menu = new Menu(MenuHandler_SkinMenu, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	menu.AddItem("inspect", "Toggle Inspect Mode");
	menu.AddItem("none", "None", iDrawItem);
	
	char szName[MAX_SKIN_NAME_LENGTH];
	for (int i; i < iSize; i++)
	{
		g_Array_SkinNames.GetString(i, szName, sizeof szName);
		menu.AddItem(GetNumString(i), szName, iDrawItem);
	}
	
	menu.DisplayAt(client, iItem, MENU_TIME_FOREVER);
}

char[] GetNumString(int iNum)
{
	char szNum[5];
	IntToString(iNum, szNum, sizeof szNum);
	
	return szNum;
}

public int MenuHandler_SkinMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	if (action == MenuAction_Cancel)
	{
		ThirdPerson_SetClientCurrentThirdPerson(param1, ThirdPerson_GetClientChosenThirdPerson(param1));
		EquipPlayerSkin(param1, g_iPlayerSavedSkin[param1][CGetClientTeam(param1)]);
		return 0;
	}
	
	if (action == MenuAction_DisplayItem)
	{
		char szInfo[MAX_INFO_LENGTH], szFmt[MAX_SKIN_NAME_LENGTH + 40];
		int iLen;
		menu.GetItem(param2, szInfo, sizeof szInfo, iLen, szFmt, sizeof szFmt);
		
		if(StrEqual(szInfo, "inspect") || StrEqual(szInfo, "none"))
		{
			return 0;
		}
		
		int iIndex = StringToInt(szInfo);
		iLen = strlen(szFmt);
		
		bool bEdit = false;
		if(g_iPlayerSavedSkin[param1][Team_First] == iIndex)
		{
			iLen += FormatEx(szFmt[iLen], sizeof(szFmt) - iLen, " %s", "[T Skin]");
			bEdit = true;
		}
		
		if(g_iPlayerSavedSkin[param1][Team_Second] == iIndex)
		{
			iLen += FormatEx(szFmt[iLen], sizeof(szFmt) - iLen, " %s", "[CT Skin]");
			bEdit = true;
		}
		
		if (g_iPlayerEquippedSkin[param1] != No_Skin && g_iPlayerEquippedSkin[param1] == iIndex)
		{
			iLen += FormatEx(szFmt[iLen], sizeof(szFmt) - iLen, " %s", "[Current Skin]");	
			bEdit = true;
		}
		
		return bEdit ? RedrawMenuItem(szFmt) : 0;
	}
	
	if (action == MenuAction_Select)
	{
		g_iLastSkinMenuSelectionPosition[param1] = GetMenuSelectionPosition();
		
		if (!CanChooseSkinNow(param1))
		{
			CPrintToChat(param1, "You cannot choose a skin now.");
			return 0;
		}
		
		char szInfo[MAX_INFO_LENGTH];
		menu.GetItem(param2, szInfo, sizeof szInfo);
		
		if (StrEqual(szInfo, "inspect"))
		{
			ThirdPerson_SetClientCurrentThirdPerson(param1, ThirdPerson_GetClientCurrentThirdPerson(param1) == TPT_FirstPerson ? TPT_ThirdPerson_Mirror : TPT_FirstPerson);
			ShowSkinsMenu(param1, g_iLastSkinMenuSelectionPosition[param1], g_bIsVIP[param1]);
			return 0;
		}
		
		if(StrEqual(szInfo, "none"))
		{
			EquipPlayerSkin(param1, No_Skin);
			ShowEquipMenu(param1, No_Skin);
			
			return 0;
		}
		
		int iIndex = StringToInt(szInfo);
		//SetClientInspctSkin(param1, iIndex, true);
		EquipPlayerSkin(param1, iIndex);
		ShowEquipMenu(param1, iIndex);
		
		return 0;
	}
	
	return 0;
}

bool CanChooseSkinNow(int client)
{
	if (client)
	{
		
	}
	
	return true;
}

void EquipPlayerSkin(int client, int iIndex)
{
	char szModel[PLATFORM_MAX_PATH];
	
	g_iPlayerEquippedSkin[client] = iIndex;
	
	#if defined _multimod_included
	if(CGetClientTeam(client) & g_iRestrictedTeams)
	{
		PrintToChat(client, "* Changing to a skin for this team is restricted in this mod. Try again later.");
		return;
	}
	#endif
	
	if (iIndex == No_Skin)
	{
		CS_UpdateClientModel(client);
		
		/*
		if(ConVar_TeamColors.IntValue)
		{
			SetEntityRenderColor(client);
		}
		*/
	}
	
	else
	{	
		g_Array_SkinPaths.GetString(iIndex, szModel, sizeof szModel);
		SetEntityModel(client, szModel);
	}
	
	Call_StartForward(g_hForward);
	Call_PushCell(client);
	Call_Finish();
}

void ShowEquipMenu(int client, int iSkinIndex)
{
	Menu menu = new Menu(MenuHandler_EquipMenu, MENU_ACTIONS_DEFAULT);
	
	int iTeam;
	char szSkinName[MAX_SKIN_NAME_LENGTH];
	if(iSkinIndex == No_Skin)
	{	
		szSkinName = "None";
		iTeam = Team_First_Bit | Team_Second_Bit;
	}
	else
	{
		g_Array_SkinNames.GetString(iSkinIndex, szSkinName, sizeof szSkinName);
		iTeam = g_Array_SkinTeams.Get(iSkinIndex);
	}
	
	menu.ExitBackButton = false;
	menu.ExitButton = false;
	
	menu.SetTitle("Select an Option For Skin [%s]", szSkinName);
	menu.AddItem("back", "Go Back", ITEMDRAW_DEFAULT);
	menu.AddItem("both", "Equip on Both Teams", iTeam & (Team_First_Bit | Team_Second_Bit) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("first", "Equip on Terrorist Team", iTeam & Team_First_Bit ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("second", "Equip on CT Team", iTeam & Team_Second_Bit ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_EquipMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return;
	}
	
	if (action != MenuAction_Select)
	{
		return;
	}
	
	char szInfo[MAX_INFO_LENGTH];
	menu.GetItem(param2, szInfo, sizeof szInfo);
	int iSkinIndex = g_iPlayerEquippedSkin[param1];
	if (StrEqual(szInfo, "back"))
	{
		
	}
	
	else if (StrEqual(szInfo, "both"))
	{
		int iTeam;
		if(iSkinIndex == No_Skin)
		{
			iTeam = Team_First_Bit | Team_Second_Bit;
		}
		
		else
		{
			iTeam = g_Array_SkinTeams.Get(iSkinIndex);
		}
		
		if (iTeam & Team_First_Bit)
		{
			g_iPlayerSavedSkin[param1][Team_First] = iSkinIndex;
		}
		
		if (iTeam & Team_Second_Bit)
		{
			g_iPlayerSavedSkin[param1][Team_Second] = iSkinIndex;
		}
	}
	
	else if (StrEqual(szInfo, "first"))
	{
		g_iPlayerSavedSkin[param1][Team_First] = iSkinIndex;
	}
	
	else if (StrEqual(szInfo, "second"))
	{
		g_iPlayerSavedSkin[param1][Team_Second] = iSkinIndex;
	}
	
	EquipPlayerSkin(param1, g_iPlayerSavedSkin[param1][CGetClientTeam(param1)]);
	ShowSkinsMenu(param1, g_iLastSkinMenuSelectionPosition[param1], g_bIsVIP[param1]);
}

public void MultiMod_OnLoaded(bool bReload)
{

}

public void OnMapStart()
{
	#if defined _multimod_included
	g_iRestrictedTeams = 0;
	
	if(g_bMultiMod)
	{
		ReadRestrictionsFile();
	}
	#endif
	
	g_Array_SkinPaths.Clear();
	g_Array_SkinNames.Clear();
	g_Array_SkinTeams.Clear();
	g_Array_SkinKeys.Clear();
	
	ReadSkinsFile();
}

stock void ReadRestrictionsFile()
{
	char szPath[PLATFORM_MAX_PATH] = "cfg/multimod/vip_skinsmenu_restrictions.ini";
	MultiMod_BuildPath(_, ModIndex_Null, szPath, sizeof szPath, "/vip_skinsmenu_restrictions.ini");
	
	int iModIndex = MultiMod_GetCurrentModId();
	
	if(iModIndex == -1)
	{
		return;
	}
	
	char szCurrentModName[MM_MAX_MOD_PROP_LENGTH];
	MultiMod_GetModProp(iModIndex, MultiModProp_InfoKey, szCurrentModName, sizeof szCurrentModName);
	
	if(!FileExists(szPath))
	{
		File f = OpenFile(szPath, "w+");
		WriteFileLine(f, "\"Restrictions\"\n{\n\t\"jailbreak\"\t\"ct\"\n}");
		delete f;
	}
	
	KeyValues hKv = CreateKeyValues("Restrictions");
	FileToKeyValues(hKv, szPath);
	
	KvGotoFirstSubKey(hKv, false);

	char szRestrictedTeams[10];
	char szModName[MM_MAX_MOD_PROP_LENGTH];
	
	int iTeam;
	int iIndex;
	
	do
	{
		iTeam = 0;
		iIndex = -1;
		
		KvGetSectionName(hKv, szModName, sizeof szModName);
		
		
		if(!StrEqual(szCurrentModName, szModName))
		{
			continue;
		}
		
		KvGetString(hKv, NULL_STRING, szRestrictedTeams, sizeof szRestrictedTeams);
		TrimString(szRestrictedTeams);
		ReplaceString(szRestrictedTeams, sizeof szSkinTeams, " ", "");
		
		if ( StrContains(szRestrictedTeams, "ct", false) != -1)
		{
			ReplaceString(szRestrictedTeams, sizeof szSkinTeams, "ct", "");
			g_iRestrictedTeams |= Team_Second_Bit;
		}
		
		if ( ( iIndex = StrContains(szRestrictedTeams, "t", false) ) != -1)
		{
			if (iIndex > 0 && szRestrictedTeams[iIndex - 1] == 'c')
			{
				
			}
			
			else
			{
				g_iRestrictedTeams |= Team_First_Bit;
			}
		}
		
		break;
	}
	
	while(KvGotoNextKey(hKv, false));
	delete hKv;
}

void ReadSkinsFile()
{
	KeyValues kv = new KeyValues("VIPSkins");
	
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof szPath, "configs/vip_skins.ini");
	
	kv.ImportFromFile(szPath);
	
	char szKey[MAX_SKIN_KEY_LENGTH], szValue[PLATFORM_MAX_PATH];
	char szName[MAX_SKIN_NAME_LENGTH];
	char szSkinPath[PLATFORM_MAX_PATH];
	char szSkinTeams[10];
	int iTeam;
	int iIndex;
	
	if (!kv.GotoFirstSubKey(false))
	{
		delete kv;
		return;
	}

	/*
	"VIPSkins"
	{
		"key"
		{
			"displayname"	"name"
			"path"			"path"
			"team"					"ct,t"
			
			"download"
			{
				"1"	"path1"
				"2"	"path2"
			}
		}
	}
	*/
	
	char Key_DispName[] = "displayname", 
	Key_Path[] = "path", 
	Key_Team[] = "team", 
	Key_Download[] = "download";
	
	char szText[512];
	
	do
	{
		kv.GetSectionName(szKey, sizeof szKey);
		kv.GetString(Key_Path, szSkinPath, sizeof szSkinPath, "");
		
		if (!FileExists(szSkinPath))
		{
			LogError("[Skin Menu] File not exists(%s): %s", szKey, szSkinPath);
			continue;
		}
		
		PrecacheModel(szSkinPath, true);
		AddFileToDownloadsTable(szSkinPath);
		
		kv.GetString(Key_DispName, szName, sizeof szName, "Meh Skin");
		kv.GetString(Key_Team, szSkinTeams, sizeof szSkinTeams, "ct,t");
	
		kv.GetSectionName(szText, sizeof szText);
		if (kv.JumpToKey(Key_Download, false))
		{
			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					szValue[0] = 0;
					
					kv.GetSectionName(szText, sizeof szText);
						
					kv.GetString(NULL_STRING, szValue, sizeof szValue);
					//kv.GoBack();
						
					FDownloader_AddSinglePath(szValue);
				}
				while( kv.GotoNextKey(false) );
				kv.GoBack();
			}
			
			kv.GoBack();
		}
		
		iTeam = 0;
		
		ReplaceString(szSkinTeams, sizeof szSkinTeams, " ", "");
		if ( StrContains(szSkinTeams, "ct", false) != -1)
		{
			ReplaceString(szSkinTeams, sizeof szSkinTeams, "ct", "");
			iTeam |= Team_Second_Bit;
		}
		
		if ( ( iIndex = StrContains(szSkinTeams, "t", false) ) != -1)
		{
			if (iIndex > 0 && szSkinTeams[iIndex - 1] == 'c')
			{
				
			}
			
			else
			{
				iTeam |= Team_First_Bit;
			}
		}
		
		g_Array_SkinNames.PushString(szName);
		g_Array_SkinTeams.Push(iTeam);
		g_Array_SkinKeys.PushString(szKey);
		g_Array_SkinPaths.PushString(szSkinPath);
	}
	while (kv.GotoNextKey());
	
	delete kv;
} 

stock int CGetClientTeam(int client, bool bBit = false)
{
	if (bBit)
	{
		switch (GetClientTeam(client))
		{
			case CS_TEAM_CT:
			{
				return Team_Second_Bit;
			}
			
			case CS_TEAM_T:
			{
				return Team_First_Bit;
			}
		}
	}
	
	else
	{
		switch (GetClientTeam(client))
		{
			case CS_TEAM_CT:
			{
				return Team_Second;
			}
			
			case CS_TEAM_T:
			{
				return Team_First;
			}
		}
	}
	
	return -1;
}
