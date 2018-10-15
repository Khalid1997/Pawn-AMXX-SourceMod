
#if defined HATS_ENABLED
#endinput
#endif

#define HATS_ENABLED

#pragma newdecls optional

//#define SMARTDM_DEBUG
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <cstrike>
#include <multicolors>
#include <sdkhooks>
#include <smartdm>
#include <thirdperson>
#include <vipsys>
//#undef SMARTDM_DEBUG

#pragma newdecls required // let's go new syntax! 

char HAT_TARGETNAME[] = "hats_hatent";

ThirdPersonType g_iClientThirdPersonType[MAXPLAYERS];
bool g_bIsVIP[MAXPLAYERS];

#define MAX_SKIN_KEY_LENGTH	21
#define MAX_SKIN_NAME_LENGTH 35
#define MAX_INFO_LENGTH	15

#define Team_First_Bit		( 1 << (CS_TEAM_T+1) )
#define Team_Second_Bit	( 1 << (CS_TEAM_CT+1) )

#define Team_First	0
#define Team_Second 1

enum Hat_Data
{
	String:HD_szType[MAX_SKIN_KEY_LENGTH], 
	String:HD_szName[MAX_SKIN_NAME_LENGTH], 
	String:HD_szModel[PLATFORM_MAX_PATH], 
	String:HD_szAttachment[64], 
	Float:HD_fPosition[3], 
	Float:HD_fAngles[3], 
	bool:HD_bBonemerge, 
	HD_iTeam
}

/*
enum Hat_Model_Data
{
	String:HMD_szPlayerModel[PLATFORM_MAX_PATH],
	Float:HMD_fPosition[3],
	Float:HD_fAngles[3]
};
*/

KeyValues g_hKv = null;
KeyValues g_hKv_Models = null;

#define No_Hat -1
#define MAX_HATS 30

int g_eHats[MAX_HATS][Hat_Data], 
//	g_eHatsModelsData[MAX_HATS][Hat_Model_Data],
g_iTotalHatsCount = 0;

int g_iPlayerSavedHats[MAXPLAYERS][2];
int g_iPlayerEquippedHat[MAXPLAYERS] =  { No_Hat, ... };
int g_iPlayerHatEntity[MAXPLAYERS] = INVALID_ENT_REFERENCE;

int g_iLastMenuSelection[MAXPLAYERS];

#define EDITMODE_BASE	0
#define EDITMODE_MODEL	1

//int g_iPlayerEditorMenuMode[MAXPLAYERS] = { 0, ... };
int g_iPlayerEditorMode[MAXPLAYERS];
int g_iPlayerEditorMenuOffset[MAXPLAYERS] = 0;
int g_iPlayerEditorMenuOffsetMode[MAXPLAYERS] = 0;
float g_flPlayerEditAngles[MAXPLAYERS][3];
float g_flPlayerEditPosition[MAXPLAYERS][3];

float g_flEditorMenuOffsets[] =  {
	1.0, 
	2.0, 
	2.5, 
	5.0, 
	10.5
};

Handle g_hTimers[MAXPLAYERS];
Handle g_hCookie_Hats_TeamFirst, 
g_hCookie_Hats_TeamSecond;

char MENU_ITEM_INFO[] = "menu_vip_item";

int g_bLate;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrorMax)
{
	g_bLate = bLate;
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCookie_Hats_TeamFirst = RegClientCookie("hats_t", "Hats", CookieAccess_Protected);
	g_hCookie_Hats_TeamSecond = RegClientCookie("hats_ct", "Hats", CookieAccess_Protected);
	
	//RegAdminCmd("sm_editor", AdmCmd_HatsEditor, ADMFLAG_ROOT, "Opens hats editor.");
	RegAdminCmd("sm_reloadhats", AdmCmd_ReloadHats, ADMFLAG_ROOT, "Reload hats configuration.");
	RegConsoleCmd("sm_hats", ConCmd_HatsMenu);
	
	HookEvent("player_spawn", Event_Hats_PlayerSpawn);
	HookEvent("player_death", Event_Hats_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", Event_Hats_PlayerDeath, EventHookMode_Pre);
	
	if(g_bLate)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				continue;
			}
			
			g_bIsVIP[i] = VIPSys_Client_IsVIP(i);
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem(MENU_ITEM_INFO, "Hats Menu", MENU_ACTIONS_DEFAULT, ITEMDRAW_DEFAULT, VIPMenu_HatsItem, 11);
}

public int VIPMenu_HatsItem(Menu menu, char[] szInfo, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		ShowHatsMenu(param1, 0, g_bIsVIP[param1]);
	}
	
	return 0;
}

public void OnMapStart()
{
	//	PrintToServer("OnMapStart");
	
	LoadHats();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_hTimers[i] = INVALID_HANDLE;
	}
	
	//PrintToServer("%d", g_iTotalHatsCount);
	for (int i = 0; i < g_iTotalHatsCount; ++i)
	{
		//PrintToServer("PRecache %s %s", g_eHats[i][HD_szModel], g_eHats[i][HD_szName]);
		//PrintToServer("PRecache ****", g_eHats[i][HD_szModel]);
		
		if (!FileExists(g_eHats[i][HD_szModel]))
		{
			LogError("[Hats] Model %s doesnt exist", g_eHats[i][HD_szModel]);
			continue;
		}
		
		PrecacheModel(g_eHats[i][HD_szModel], false);
		Downloader_AddFileToDownloadsTable(g_eHats[i][HD_szModel]);
	}
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem(MENU_ITEM_INFO);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	
}

public void ThirdPerson_OnClientChangeMode(int client, ThirdPersonType type)
{
	g_iClientThirdPersonType[client] = type;
}

public Action SDKCallback_SetTransmit(int entity, int client)
{
	static int owner;
	owner =	GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (owner != client)
	{
		return Plugin_Continue;
	}

	if (g_iClientThirdPersonType[client] != TPT_FirstPerson)
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action Event_Hats_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(client))
	{
		return;
	}
}

public void VIP_SkinMenu_OnSkinChange(int client)
{
	RemoveHat(client);
	
	int iTeam = CGetClientTeam(client);
	if (iTeam == -1)
	{
		return;
	}
	
	CreateHat(client, g_iPlayerSavedHats[client][iTeam]);
}

public Action AdmCmd_ReloadHats(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			RemoveHat(i);
		}
	}
	
	LoadHats();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			CreateHat(client, g_iPlayerSavedHats[i][CGetClientTeam(i)]);
		}
	}
	
	CPrintToChat(client, " {darkred}Hats Config Loaded.");
	return Plugin_Handled;
}

public Action ConCmd_HatsMenu(int client, int args)
{
	ShowHatsMenu(client, 0, g_bIsVIP[client]);
	return Plugin_Handled;
}

void ShowHatsMenu(int client, int iPosition = 0, bool bAccess)
{
	Menu menu_hats = new Menu(MenuHandler_HatSelectionMenu, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	SetMenuExitButton(menu_hats, true);
	
	int iItemDraw = bAccess ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	
	SetMenuTitle(menu_hats, "Select a Hat:");
	AddMenuItem(menu_hats, "inspect", "Toggle Inspect Mode");
	AddMenuItem(menu_hats, "none", "None", iItemDraw);
	
	char item[4];
	for (int i = 0; i < g_iTotalHatsCount; ++i)
	{
		FormatEx(item, sizeof item, "%i", i);
		AddMenuItem(menu_hats, item, g_eHats[i][HD_szName], iItemDraw);
	}
	
	menu_hats.DisplayAt(client, iPosition, MENU_TIME_FOREVER);
}

void ShowHatEquipMenu(int client)
{
	Menu menu = new Menu(MenuHandler_HatsEquipMenu, MENU_ACTIONS_DEFAULT);
	
	int iSkinIndex = g_iPlayerEquippedHat[client];
	
	int iTeam;
	if (iSkinIndex == No_Hat)
	{
		iTeam = Team_First_Bit | Team_Second_Bit;
	}
	
	else
	{
		iTeam = g_eHats[iSkinIndex][HD_iTeam];
	}
	
	menu.ExitBackButton = false;
	menu.ExitButton = false;
	
	char szSkinName[MAX_SKIN_NAME_LENGTH];
	if (iSkinIndex == No_Hat)
	{
		FormatEx(szSkinName, sizeof szSkinName, "None");
	}
	
	else
	{
		FormatEx(szSkinName, sizeof szSkinName, g_eHats[iSkinIndex][HD_szName]);
		
		if(GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			menu.AddItem("edit", "Edit Hat");
		}
	}
	
	menu.SetTitle("Select an Option For Skin [%s]", szSkinName);
	menu.AddItem("back", "Go Back", ITEMDRAW_DEFAULT);
	menu.AddItem("both", "Equip on Both Teams", iTeam & (Team_First_Bit | Team_Second_Bit) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("first", "Equip on Terrorist Team", iTeam & Team_First_Bit ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("second", "Equip on CT Team", iTeam & Team_Second_Bit ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_HatSelectionMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	if (action == MenuAction_Cancel)
	{
		ThirdPerson_SetClientCurrentThirdPerson(param1, ThirdPerson_GetClientChosenThirdPerson(param1) );
	}
	
	if (action == MenuAction_DisplayItem)
	{
		char szInfo[MAX_INFO_LENGTH];
		int iIndex;
		
		menu.GetItem(param2, szInfo, sizeof szInfo);
		if (StrEqual(szInfo, "inspect") || StrEqual(szInfo, "none"))
		{
			return 0;
		}
		
		bool bEdit = false;
		iIndex = StringToInt(szInfo);
		
		char szFmt[MAX_SKIN_NAME_LENGTH + 40];
		int iLen;
		iLen = FormatEx(szFmt, sizeof szFmt, "%s", g_eHats[iIndex][HD_szName]);
		
		if (g_iPlayerSavedHats[param1][Team_First] == iIndex)
		{
			iLen += FormatEx(szFmt[iLen], sizeof(szFmt) - iLen, " %s", "[T Hat]");
			bEdit = true;
		}
		
		if (g_iPlayerSavedHats[param1][Team_Second] == iIndex)
		{
			iLen += FormatEx(szFmt[iLen], sizeof(szFmt) - iLen, " %s", "[CT Hat]");
			bEdit = true;
		}
		
		if (g_iPlayerEquippedHat[param1] != No_Hat && g_iPlayerEquippedHat[param1] == iIndex)
		{
			iLen += FormatEx(szFmt[iLen], sizeof(szFmt) - iLen, " %s", "[Current Skin]");
			bEdit = true;
		}
		
		return bEdit ? RedrawMenuItem(szFmt) : 0;
	}
	
	if (action == MenuAction_Select)
	{
		g_iLastMenuSelection[param1] = GetMenuSelectionPosition();
		char szInfo[MAX_INFO_LENGTH];
		int iIndex;
		
		menu.GetItem(param2, szInfo, sizeof(szInfo));
		if (StrEqual(szInfo, "inspect"))
		{
			ThirdPerson_SetClientCurrentThirdPerson(param1, ThirdPerson_GetClientCurrentThirdPerson(param1) == TPT_FirstPerson ? TPT_ThirdPerson_Mirror : TPT_FirstPerson);
			ShowHatsMenu(param1, g_iLastMenuSelection[param1], g_bIsVIP[param1]);
		}
		
		else if (StrEqual(szInfo, "none"))
		{
			g_iPlayerEquippedHat[param1] = No_Hat;
			
			RemoveHat(param1);
			ShowHatEquipMenu(param1);
		}
		
		else
		{
			iIndex = StringToInt(szInfo);
			RemoveHat(param1);
			CreateHat(param1, iIndex);
			
			g_iLastMenuSelection[param1] = GetMenuSelectionPosition();
			ShowHatEquipMenu(param1);
		}
	}
	
	return 0;
}

public int MenuHandler_HatsEquipMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return;
	}
	
	if (action == MenuAction_Cancel)
	{
		int iIndex = g_iPlayerSavedHats[param1][CGetClientTeam(param1)];
		if (g_iPlayerEquippedHat[param1] != iIndex)
		{
			RemoveHat(param1);
			CreateHat(param1, iIndex);
		}
		
		return;
	}
	
	char szInfo[15];
	menu.GetItem(param2, szInfo, sizeof szInfo);
	
	int iSkinIndex = g_iPlayerEquippedHat[param1];
	
	if (StrEqual(szInfo, "edit"))
	{
		//SetClientInspectMode(param1, true);
		
		Menu modemenu = new Menu(MenuHandler_EditMode, MENU_ACTIONS_DEFAULT);
		modemenu.AddItem("base", "Edit base");
		modemenu.AddItem("model", "Edit for (Worn) model");
		
		modemenu.Display(param1, MENU_TIME_FOREVER);
		
		return;
	}
	
	if (StrEqual(szInfo, "back"))
	{
		int iIndex = g_iPlayerSavedHats[param1][CGetClientTeam(param1)];
		if (g_iPlayerEquippedHat[param1] != iIndex)
		{
			RemoveHat(param1);
			CreateHat(param1, iIndex);
		}
		
		ShowHatsMenu(param1, g_iLastMenuSelection[param1], g_bIsVIP[param1]);
		return;
	}
	
	else if (StrEqual(szInfo, "both"))
	{
		int iTeam;
		
		if (iSkinIndex == No_Hat)
		{
			iTeam = Team_First_Bit | Team_Second_Bit;
		}
		
		else
		{
			iTeam = g_eHats[iSkinIndex][HD_iTeam];
		}
		
		if (iTeam & Team_First_Bit)
		{
			g_iPlayerSavedHats[param1][Team_First] = iSkinIndex;
		}
		
		if (iTeam & Team_Second_Bit)
		{
			g_iPlayerSavedHats[param1][Team_Second] = iSkinIndex;
		}
	}
	
	else if (StrEqual(szInfo, "first"))
	{
		g_iPlayerSavedHats[param1][Team_First] = iSkinIndex;
	}
	
	else if (StrEqual(szInfo, "second"))
	{
		g_iPlayerSavedHats[param1][Team_Second] = iSkinIndex;
	}
	
	int iTeam;
	if (g_iPlayerEquippedHat[param1] != g_iPlayerSavedHats[param1][(iTeam = CGetClientTeam(param1))])
	{
		RemoveHat(param1);
		CreateHat(param1, g_iPlayerSavedHats[param1][iTeam]);
	}
	
	ShowHatsMenu(param1, g_iLastMenuSelection[param1], g_bIsVIP[param1]);
}

public int MenuHandler_EditMode(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	
	if(action != MenuAction_Select)
	{
		return;
	}
	
	char szInfo[MAX_INFO_LENGTH];
	menu.GetItem(param2, szInfo, sizeof szInfo);
	
	if(StrEqual(szInfo, "base"))
	{
		StartShowOffSetsMenu(param1, EDITMODE_BASE);
	}
	
	else if(StrEqual(szInfo, "model"))
	{
		StartShowOffSetsMenu(param1, EDITMODE_MODEL);
	}
	
	
}

void LoadHats()
{
	char sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof sConfig, "configs/franug_hats.txt");
	
	g_iTotalHatsCount = 0;
	if (g_hKv != null)
	{
		delete g_hKv;
		g_hKv = null;
		
		delete g_hKv_Models;
		g_hKv_Models = null;
	}
	
	g_hKv = new KeyValues("Hats");
	g_hKv_Models = new KeyValues("Hats");
	
	if (!FileToKeyValues(g_hKv, sConfig))
	{
		delete g_hKv;
		g_hKv = null;
		LogError("[VIP Hats] Could not load hats file: %s", sConfig);
		return;
	}
	
	if (!g_hKv.GotoFirstSubKey(true))
	{
		LogError("[VIP Hats] No hats detected");
		delete g_hKv;
		g_hKv = null;
		
		return;
	}
	
	BuildPath(Path_SM, sConfig, sizeof sConfig, "configs/franug_hats_models.txt");
	FileToKeyValues(g_hKv_Models, sConfig);
	
	float m_fTemp[3];
	char szSkinTeams[10];
	int iIndex;
	int iTeam;
	
	do
	{
		g_eHats[g_iTotalHatsCount][HD_iTeam] = 0;
		
		KvGetSectionName(g_hKv, g_eHats[g_iTotalHatsCount][HD_szType], MAX_SKIN_KEY_LENGTH);
		
		//PrintToServer("Section %s", g_eHats[g_iTotalHatsCount][HD_szType]);
		KvGetString(g_hKv, "displayname", g_eHats[g_iTotalHatsCount][HD_szName], MAX_SKIN_NAME_LENGTH);
		KvGetString(g_hKv, "model", g_eHats[g_iTotalHatsCount][HD_szModel], PLATFORM_MAX_PATH);
		KvGetVector(g_hKv, "position", m_fTemp);
		g_eHats[g_iTotalHatsCount][HD_fPosition] = m_fTemp;
		KvGetVector(g_hKv, "angles", m_fTemp);
		g_eHats[g_iTotalHatsCount][HD_fAngles] = m_fTemp;
		g_eHats[g_iTotalHatsCount][HD_bBonemerge] = (KvGetNum(g_hKv, "bonemerge", 0) ? true : false);
		KvGetString(g_hKv, "attachment", g_eHats[g_iTotalHatsCount][HD_szAttachment], 64, "facemask");
		KvGetString(g_hKv, "team", szSkinTeams, sizeof szSkinTeams, "ct,t");
		
		iTeam = 0;
		ReplaceString(szSkinTeams, sizeof szSkinTeams, " ", "");
		if (StrContains(szSkinTeams, "ct", false) != -1)
		{
			ReplaceString(szSkinTeams, sizeof szSkinTeams, "ct", "");
			iTeam |= Team_Second_Bit;
		}
		
		if ((iIndex = StrContains(szSkinTeams, "t", false)) != -1)
		{
			if (iIndex > 0 && szSkinTeams[iIndex - 1] == 'c')
			{
				//PrintToServer("Yeeeses");
			}
			
			else
			{
				iTeam |= Team_First_Bit;
			}
		}
		
		g_eHats[g_iTotalHatsCount][HD_iTeam] = iTeam;
		++g_iTotalHatsCount;
	}
	while (KvGotoNextKey(g_hKv));
	
	g_hKv.GoBack();
	
	//PrintToServer("Nodes in stack %d", g_hKv.NodesInStack());
}

void CreateHat(int client, int iIndex, bool bTempCoords = false)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	g_iPlayerEquippedHat[client] = iIndex;
	if (iIndex == No_Hat)
	{
		return;
	}
	
	// CreateHats code taken from https://forums.alliedmods.net/showthread.php?t=208125
	
	// Calculate the final position and angles for the hat
	float m_fHatOrigin[3], m_fHatAngles[3], m_fForward[3], m_fRight[3], m_fUp[3], m_fOffset[3];
	float m_fPlayerAngles[3];
	
	GetClientAbsOrigin(client, m_fHatOrigin);
	//GetClientAbsAngles(client, m_fHatAngles);
	GetClientAbsAngles(client, m_fPlayerAngles);
	
	if (bTempCoords)
	{
		m_fHatAngles[0] = g_flPlayerEditAngles[client][0];
		m_fHatAngles[1] = g_flPlayerEditAngles[client][1];
		m_fHatAngles[2] = g_flPlayerEditAngles[client][2];
		
		m_fOffset[0] = g_flPlayerEditPosition[client][0];
		m_fOffset[1] = g_flPlayerEditPosition[client][1];
		m_fOffset[2] = g_flPlayerEditPosition[client][2];
	}
	
	else
	{
		float vPos[3], vAngles[3];
		char szModel[PLATFORM_MAX_PATH];
		GetClientModel(client, szModel, sizeof szModel);
		ReplaceString(szModel, sizeof szModel, "\\", "/");
		ReplaceString(szModel, sizeof szModel, "/", "&");
		
		if(GetModelHatVectors(g_eHats[iIndex][HD_szType], szModel, vPos, vAngles))
		{
			PrintToServer("FOund %s [ %0.2f - %0.2f - %0.2f ] - [ %0.2f - %0.2f - %0.2f ]", szModel, vAngles[0], vAngles[1], vAngles[2], vPos[0], vPos[1], vPos[2]);
			
			m_fHatAngles[0] = vAngles[0];
			m_fHatAngles[1] = vAngles[1];
			m_fHatAngles[2] = vAngles[2];
				
			m_fOffset[0] = vPos[0];
			m_fOffset[1] = vPos[1];
			m_fOffset[2] = vPos[2];
		}
		
		else
		{
			m_fHatAngles[0] = g_eHats[iIndex][HD_fAngles][0];
			m_fHatAngles[1] = g_eHats[iIndex][HD_fAngles][1];
			m_fHatAngles[2] = g_eHats[iIndex][HD_fAngles][2];
			
			m_fOffset[0] = g_eHats[iIndex][HD_fPosition][0];
			m_fOffset[1] = g_eHats[iIndex][HD_fPosition][1];
			m_fOffset[2] = g_eHats[iIndex][HD_fPosition][2];
		}
	}
	
	GetAngleVectors(m_fPlayerAngles, m_fForward, m_fRight, m_fUp);
	
	m_fHatOrigin[0] += m_fRight[0] * m_fOffset[0] + m_fForward[0] * m_fOffset[1] + m_fUp[0] * m_fOffset[2];
	m_fHatOrigin[1] += m_fRight[1] * m_fOffset[0] + m_fForward[1] * m_fOffset[1] + m_fUp[1] * m_fOffset[2];
	m_fHatOrigin[2] += m_fRight[2] * m_fOffset[0] + m_fForward[2] * m_fOffset[1] + m_fUp[2] * m_fOffset[2];
	
	m_fHatAngles[0] += m_fPlayerAngles[0];
	m_fHatAngles[1] += m_fPlayerAngles[1];
	m_fHatAngles[2] += m_fPlayerAngles[2];
	
	// Create the hat entity
	int m_iEnt = CreateEntityByName("prop_dynamic_override");
	//DispatchKeyValue(m_iEnt, "targetname", HAT_TARGETNAME);
	SetEntPropString(m_iEnt, Prop_Data, "m_iName", HAT_TARGETNAME);
	DispatchKeyValue(m_iEnt, "model", g_eHats[iIndex][HD_szModel]);
	DispatchKeyValue(m_iEnt, "spawnflags", "256");
	DispatchKeyValue(m_iEnt, "solid", "0");
	SetEntPropEnt(m_iEnt, Prop_Send, "m_hOwnerEntity", client);
	
	if (g_eHats[iIndex][HD_bBonemerge])
	{
		Bonemerge(m_iEnt);
	}
	
	DispatchSpawn(m_iEnt);
	AcceptEntityInput(m_iEnt, "TurnOn", m_iEnt, m_iEnt, 0);
	
	// Save the entity index
	g_iPlayerHatEntity[client] = EntIndexToEntRef(m_iEnt);
	
	// Teleport the hat to the right position and attach it
	TeleportEntity(m_iEnt, m_fHatOrigin, m_fHatAngles, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(m_iEnt, "SetParent", client, m_iEnt, 0);
	
	SetVariantString(g_eHats[iIndex][HD_szAttachment]);
	AcceptEntityInput(m_iEnt, "SetParentAttachmentMaintainOffset", m_iEnt, m_iEnt, 0);
	
	SDKHook(m_iEnt, SDKHook_SetTransmit, SDKCallback_SetTransmit);
}

public void Bonemerge(int ent)
{
	int m_iEntEffects = GetEntProp(ent, Prop_Send, "m_fEffects");
	m_iEntEffects &= ~32;
	m_iEntEffects |= 1;
	m_iEntEffects |= 128;
	SetEntProp(ent, Prop_Send, "m_fEffects", m_iEntEffects);
}

public Action Event_Hats_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		delete(g_hTimers[client]);
		g_hTimers[client] = INVALID_HANDLE;
	}
	
	ThirdPerson_SetClientCurrentThirdPerson(client, ThirdPerson_GetClientChosenThirdPerson(client));
	
	RemoveHat(client);
}

public void OnClientCookiesCached(int client)
{
	if(!VIPSys_Client_IsVIP(client))
	{
		g_iPlayerSavedHats[client][Team_First] = No_Hat;
		g_iPlayerSavedHats[client][Team_Second] = No_Hat;
		
		return;
	}
	
	char SprayString[12];
	GetClientCookie(client, g_hCookie_Hats_TeamFirst, SprayString, sizeof(SprayString));
	g_iPlayerSavedHats[client][Team_First] = FindHatInArray(SprayString);
	
	GetClientCookie(client, g_hCookie_Hats_TeamSecond, SprayString, sizeof(SprayString));
	g_iPlayerSavedHats[client][Team_Second] = FindHatInArray(SprayString);
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	g_bIsVIP[client] = bIsVIP;
	
	if(AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}

int FindHatInArray(char[] szType)
{
	for (int i; i < g_iTotalHatsCount; i++)
	{
		if (StrEqual(szType, g_eHats[i][HD_szType]))
		{
			return i;
		}
	}
	
	return -1;
}

public void OnClientDisconnect(int client)
{
	g_iPlayerEquippedHat[client] = No_Hat;
	
	if (g_iPlayerHatEntity[client] != INVALID_ENT_REFERENCE)
	{
		RemoveHat(client);
	}
	
	g_iPlayerEditorMenuOffset[client] = 0;
	g_iPlayerEditorMenuOffsetMode[client] = 0;
	
	if (AreClientCookiesCached(client))
	{
		if (g_iPlayerSavedHats[client][Team_First] == No_Hat)
		{
			SetClientCookie(client, g_hCookie_Hats_TeamFirst, "none");
		}
		
		else
		{
			SetClientCookie(client, g_hCookie_Hats_TeamFirst, g_eHats[g_iPlayerSavedHats[client][Team_First]][HD_szType]);
		}
		
		if (g_iPlayerSavedHats[client][Team_Second] == No_Hat)
		{
			SetClientCookie(client, g_hCookie_Hats_TeamSecond, "none");
		}
		
		else
		{
			SetClientCookie(client, g_hCookie_Hats_TeamSecond, g_eHats[g_iPlayerSavedHats[client][Team_Second]][HD_szType]);
		}
	}
	
	g_iPlayerSavedHats[client][Team_First] = No_Hat;
	g_iPlayerSavedHats[client][Team_Second] = No_Hat;
	
	if (g_hTimers[client] != INVALID_HANDLE)
	{
		delete g_hTimers[client];
		g_hTimers[client] = INVALID_HANDLE;
	}
}

void RemoveHat(int client)
{
	int entity = EntRefToEntIndex(g_iPlayerHatEntity[client]);
	if (entity != INVALID_ENT_REFERENCE && IsValidEdict(entity) && entity != 0)
	{
		SDKUnhook(entity, SDKHook_SetTransmit, SDKCallback_SetTransmit);
		AcceptEntityInput(entity, "Kill");
		g_iPlayerHatEntity[client] = INVALID_ENT_REFERENCE;
	}
}

void StartShowOffSetsMenu(int client, int iEditMode)
{
	g_iPlayerEditorMode[client] = iEditMode;
	
	if(iEditMode == EDITMODE_MODEL)
	{
		float vPos[3], vAngles[3];
		char szModel[PLATFORM_MAX_PATH];
		GetClientModel(client, szModel, sizeof szModel);
		ReplaceString(szModel, sizeof szModel, "\\", "/");
		ReplaceString(szModel, sizeof szModel, "/", "&");
		
		if(GetModelHatVectors(g_eHats[g_iPlayerEquippedHat[client]][HD_szType], szModel, vPos, vAngles))
		{
			g_flPlayerEditPosition[client][0] = vPos[0];
			g_flPlayerEditPosition[client][1] = vPos[1];
			g_flPlayerEditPosition[client][2] = vPos[2];
			
			g_flPlayerEditAngles[client][0] = vAngles[0];
			g_flPlayerEditAngles[client][1] = vAngles[1];
			g_flPlayerEditAngles[client][2] = vAngles[2];
		}
	}
	
	else
	{
		g_flPlayerEditPosition[client][0] = g_eHats[g_iPlayerEquippedHat[client]][HD_fPosition][0];
		g_flPlayerEditPosition[client][1] = g_eHats[g_iPlayerEquippedHat[client]][HD_fPosition][1];
		g_flPlayerEditPosition[client][2] = g_eHats[g_iPlayerEquippedHat[client]][HD_fPosition][2];
			
		g_flPlayerEditAngles[client][0] = g_eHats[g_iPlayerEquippedHat[client]][HD_fAngles][0];
		g_flPlayerEditAngles[client][1] = g_eHats[g_iPlayerEquippedHat[client]][HD_fAngles][1];
		g_flPlayerEditAngles[client][2] = g_eHats[g_iPlayerEquippedHat[client]][HD_fAngles][2];
	}
	
	int iOld = g_iPlayerEquippedHat[client];
	RemoveHat(client);
	CreateHat(client, iOld, true)

	ShowOffsetsMenu(client);
}

bool GetModelHatVectors(char[] szType, char[] szModel, float vPos[3], float vAngles[3])
{
	vPos[0] = 0.0;
	vPos[1] = 0.0;
	vPos[2] = 0.0;
	
	vAngles[0] = 0.0;
	vAngles[1] = 0.0;
	vAngles[2] = 0.0;
	
	bool bFound = false;
	if(g_hKv_Models.JumpToKey(szType, false))
	{
		if(g_hKv_Models.JumpToKey(szModel, false))
		{
			g_hKv_Models.GetVector("position", vPos);
			g_hKv_Models.GetVector("angles", vAngles);
			g_hKv_Models.GoBack();
			
			bFound = true;
		}
		
		g_hKv_Models.GoBack();
	}
	
	return bFound;
}

void ShowOffsetsMenu(int client, int item = 0)
{
	Menu menu_editor = new Menu(MenuHandler_Editor_OffsetsMenu, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	SetMenuTitle(menu_editor, "Hats Editor:\n\
	X:%0.1f Y:%0.1f Z:%0.1f\n\
	Xd:%0.1f Yd:%0.1f Zd:%0.1f", g_flPlayerEditPosition[client][0], g_flPlayerEditPosition[client][1], g_flPlayerEditPosition[client][2], 
		g_flPlayerEditAngles[client][0], g_flPlayerEditAngles[client][1], g_flPlayerEditAngles[client][2]);
	
	#define POS_OFFSET_Xp	0
	#define POS_OFFSET_Xm	1
	#define POS_OFFSET_Yp	2
	#define POS_OFFSET_Ym	3
	#define POS_OFFSET_Zp	4
	#define POS_OFFSET_Zm	5
	
	AddMenuItem(menu_editor, "back", "Go Back");
	AddMenuItem(menu_editor, "offset", "");
	AddMenuItem(menu_editor, "mode", "");
	AddMenuItem(menu_editor, "0", "X+");
	AddMenuItem(menu_editor, "1", "X-");
	AddMenuItem(menu_editor, "2", "Y+");
	AddMenuItem(menu_editor, "3", "Y-");
	AddMenuItem(menu_editor, "4", "Z+");
	AddMenuItem(menu_editor, "5", "Z-");
	
	AddMenuItem(menu_editor, "save", "Save");
	
	SetMenuExitBackButton(menu_editor, true);
	menu_editor.ExitButton = false;
	menu_editor.ExitBackButton = false;
	DisplayMenuAtItem(menu_editor, client, item, MENU_TIME_FOREVER);
}

public int MenuHandler_Editor_OffsetsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	if (action == MenuAction_DisplayItem)
	{
		char szInfo[32];
		GetMenuItem(menu, param2, szInfo, sizeof(szInfo));
		
		if (StrEqual(szInfo, "offset"))
		{
			FormatEx(szInfo, sizeof szInfo, "Offset: %0.3f", g_flEditorMenuOffsets[g_iPlayerEditorMenuOffset[param1]]);
			return RedrawMenuItem(szInfo);
		}
		
		if (StrEqual(szInfo, "mode"))
		{
			FormatEx(szInfo, sizeof szInfo, "Mode: %s", g_iPlayerEditorMenuOffsetMode[param1] ? "Angles" : "Position");
			return RedrawMenuItem(szInfo);
		}
		
		return 0;
	}
	
	if (action == MenuAction_Select)
	{
		char szInfo[32];
		GetMenuItem(menu, param2, szInfo, sizeof(szInfo));
		
		if (StrEqual(szInfo, "back"))
		{
			RemoveHat(param1);
			CreateHat(param1, g_iPlayerEquippedHat[param1], false);
			
			ShowHatsMenu(param1, g_iLastMenuSelection[param1], g_bIsVIP[param1]);
			return 0;
		}
		
		
		if (StrEqual(szInfo, "mode"))
		{
			g_iPlayerEditorMenuOffsetMode[param1]++;
			if (g_iPlayerEditorMenuOffsetMode[param1] == 2)
			{
				g_iPlayerEditorMenuOffsetMode[param1] = 0;
			}
		}
		
		else if (StrEqual(szInfo, "offset"))
		{
			g_iPlayerEditorMenuOffset[param1]++;
			if (g_iPlayerEditorMenuOffset[param1] == sizeof g_flEditorMenuOffsets)
			{
				g_iPlayerEditorMenuOffset[param1] = 0;
			}
		}
		
		else if (StrEqual(szInfo, "save"))
		{
			char sConfig[PLATFORM_MAX_PATH];
			if(g_iPlayerEditorMode[param1] == EDITMODE_MODEL)
			{
				char szModel[PLATFORM_MAX_PATH];
				GetClientModel(param1, szModel, sizeof szModel);
				ReplaceString(szModel, sizeof szModel, "\\", "/");
				ReplaceString(szModel, sizeof szModel, "/", "&");
				
				g_hKv_Models.Rewind();
				g_hKv_Models.JumpToKey(g_eHats[ g_iPlayerEquippedHat[param1] ][HD_szType], true);
				g_hKv_Models.JumpToKey(szModel, true);
				
				float vNewPos[3], vNewAngles[3];
				
				for(int i; i < 3; i++)
				{
					vNewPos[i] = g_flPlayerEditPosition[param1][i];/* - g_eHats[ g_iPlayerEquippedHat[param1] ][HD_fPosition][i];*/
					vNewAngles[i] = g_flPlayerEditAngles[param1][i];/* - g_eHats[ g_iPlayerEquippedHat[param1] ][HD_fAngles][i];*/
				}
				
				g_hKv_Models.SetVector("position", vNewPos);
				g_hKv_Models.SetVector("angles", vNewAngles);
				g_hKv_Models.Rewind();
				
				BuildPath(Path_SM, sConfig, sizeof sConfig, "configs/franug_hats_models.txt");
				KeyValuesToFile(g_hKv_Models, sConfig);
				CPrintToChat(param1, "* {darkred}Saved to MODELS config file.");
			}
			
			else
			{
				KvJumpToKey(g_hKv, g_eHats[ g_iPlayerEquippedHat[param1] ][HD_szType]);
				KvSetVector(g_hKv, "position", g_flPlayerEditPosition[param1]);
				KvSetVector(g_hKv, "angles", g_flPlayerEditAngles[param1]);
				KvRewind(g_hKv);
				
				g_eHats[ g_iPlayerEquippedHat[param1]][HD_fAngles][0] = g_flPlayerEditAngles[param1][0];
				g_eHats[ g_iPlayerEquippedHat[param1]][HD_fAngles][1] = g_flPlayerEditAngles[param1][1];
				g_eHats[ g_iPlayerEquippedHat[param1]][HD_fAngles][2] = g_flPlayerEditAngles[param1][2];
				
				g_eHats[ g_iPlayerEquippedHat[param1]][HD_fPosition][0] = g_flPlayerEditPosition[param1][0];
				g_eHats[ g_iPlayerEquippedHat[param1]][HD_fPosition][1] = g_flPlayerEditPosition[param1][1];
				g_eHats[ g_iPlayerEquippedHat[param1]][HD_fPosition][2] = g_flPlayerEditPosition[param1][2];
				
				BuildPath(Path_SM, sConfig, sizeof sConfig, "configs/franug_hats.txt");
				KeyValuesToFile(g_hKv, sConfig);
				CPrintToChat(param1, "* {darkred}Saved to base config file.");
			}
	
			
		}
		
		else
		{
			float flOffset;
			int iIndex;
			switch (StringToInt(szInfo))
			{
				case POS_OFFSET_Xp:
				{
					flOffset = g_flEditorMenuOffsets[g_iPlayerEditorMenuOffset[param1]];
					iIndex = 0;
				}
				
				case POS_OFFSET_Xm:
				{
					flOffset = -g_flEditorMenuOffsets[g_iPlayerEditorMenuOffset[param1]];
					iIndex = 0;
				}
				
				case POS_OFFSET_Yp:
				{
					flOffset = g_flEditorMenuOffsets[g_iPlayerEditorMenuOffset[param1]];
					iIndex = 1;
				}
				
				case POS_OFFSET_Ym:
				{
					flOffset = -g_flEditorMenuOffsets[g_iPlayerEditorMenuOffset[param1]];
					iIndex = 1;
				}
				
				case POS_OFFSET_Zp:
				{
					flOffset = g_flEditorMenuOffsets[g_iPlayerEditorMenuOffset[param1]];
					iIndex = 2;
				}
				
				case POS_OFFSET_Zm:
				{
					flOffset = -g_flEditorMenuOffsets[g_iPlayerEditorMenuOffset[param1]];
					iIndex = 2;
				}
			}
			
			// 0 = Position --- 1 = angles
			if (g_iPlayerEditorMenuOffsetMode[param1])
			{
				g_flPlayerEditAngles[param1][iIndex] += flOffset;
			}
			else
			{
				g_flPlayerEditPosition[param1][iIndex] += flOffset;
			}
		}
		
		RemoveHat(param1);
		CreateHat(param1, g_iPlayerEquippedHat[param1], true);
		
		ShowOffsetsMenu(param1, GetMenuSelectionPosition());
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (IsClientInGame(param1))
		{
			RemoveHat(param1);
			CreateHat(param1, g_iPlayerEquippedHat[param1], false);
		}
	}
	
	return 0;
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