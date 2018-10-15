#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <vipsys>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "VIPSystem And Menu",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

#define VIP_ACCESS_FLAG	"t"
int g_iVIPAccessFlag;

#define MAX_INFO_SIZE	25
#define MAX_ITEM_SIZE	65

ArrayList g_Array_MenuItems_DataPack;
ArrayList g_Array_MenuItems_Info;
ArrayList g_Array_MenuItems_Name;
ArrayList g_Array_MenuItems_Actions;
ArrayList g_Array_MenuItems_DrawType;
ArrayList g_Array_MenuItems_Order;

char g_szMenuCommands[][] = {
	"vip",
	"vipmenu",
	"vm"
};

bool g_bIsVIP[MAXPLAYERS];
Handle g_hForward_Client_OnCheckVIP;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int ErrMax)
{
	RegPluginLibrary("vipsys");
	
	g_Array_MenuItems_DataPack = new ArrayList(1);
	g_Array_MenuItems_Info = new ArrayList(MAX_INFO_SIZE);
	g_Array_MenuItems_Name = new ArrayList(MAX_ITEM_SIZE);
	g_Array_MenuItems_Actions = new ArrayList(1);
	g_Array_MenuItems_DrawType = new ArrayList(1);
	g_Array_MenuItems_Order = new ArrayList(1);
	
	CreateNative("VIPSys_Client_IsVIP", Native_Client_IsVIP);
	CreateNative("VIPSys_Menu_AddItem", Native_Menu_AddItem);
	CreateNative("VIPSys_Menu_RemoveItem", Native_Menu_RemoveItem);
	CreateNative("VIPSys_Menu_SetItemProperty", Native_Menu_SetProperty);
	
	g_hForward_Client_OnCheckVIP = CreateGlobalForward("VIPSys_Client_OnCheckVIP", ET_Ignore, Param_Cell, Param_Cell);
	
	return APLRes_Success;
}

public int Native_Client_IsVIP(Handle hPlugin, int argc)
{
	return view_as<int>(g_bIsVIP[GetNativeCell(1)]);
}

public int Native_Menu_AddItem(Handle hPlugin, int argc)
{
	char szInfo[MAX_INFO_SIZE];
	GetNativeString(1, szInfo, sizeof szInfo);
	
	int iIndex = FindItemIndex(szInfo);
	
	char szDisplayName[MAX_ITEM_SIZE];
	GetNativeString(2, szDisplayName, sizeof szDisplayName);
	
	MenuAction iMenuActions = GetNativeCell(3) | MenuAction_Select;
	int iDrawType = GetNativeCell(4);
	
	Function func = GetNativeFunction(5);
	
	DataPack dp = new DataPack();
	dp.WriteCell(hPlugin);
	dp.WriteFunction(func);
	
	PrintToServer("------ Add %s .. %s %d %d", szInfo, szDisplayName, iMenuActions, iDrawType);
	
	if(iIndex == -1)
	{
		g_Array_MenuItems_DataPack.Push(dp);
		g_Array_MenuItems_Info.PushString(szInfo);
		g_Array_MenuItems_Name.PushString(szDisplayName);
		g_Array_MenuItems_Actions.Push(iMenuActions);
		g_Array_MenuItems_DrawType.Push(iDrawType);
		g_Array_MenuItems_Order.Push(GetNativeCell(6));
	}
	
	else
	{
		delete view_as<DataPack>(g_Array_MenuItems_DataPack.Get(iIndex));
		g_Array_MenuItems_DataPack.Set(iIndex, dp);
		g_Array_MenuItems_Info.SetString(iIndex, szInfo);
		g_Array_MenuItems_Name.SetString(iIndex, szDisplayName);
		g_Array_MenuItems_Actions.Set(iIndex, iMenuActions);
		g_Array_MenuItems_DrawType.Set(iIndex, iDrawType);
		g_Array_MenuItems_Order.Set(iIndex, GetNativeCell(6));
	}
	
	SortMenuItems();
}

stock void SortMenuItems()
{
	int iSize = g_Array_MenuItems_Order.Length;
	
	if(iSize < 2)
	{
		return;
	}
	
	for(int i = 1, j; i < iSize; i++)
	{
		for(j = i - 1; j >= 0; j--)
		{
			if(g_Array_MenuItems_Order.Get(i) < g_Array_MenuItems_Order.Get(j))
			{
				g_Array_MenuItems_DataPack.SwapAt(i, j);
				g_Array_MenuItems_Info.SwapAt(i, j);
				g_Array_MenuItems_Name.SwapAt(i, j);
				g_Array_MenuItems_Actions.SwapAt(i, j);
				g_Array_MenuItems_DrawType.SwapAt(i, j);
				g_Array_MenuItems_Order.SwapAt(i, j);
				
				i = j;
				j = i;	// i - 1 from loop
			}
		}
	}
}

public int Native_Menu_RemoveItem(Handle hPlugin, int argc)
{
	char szInfo[MAX_INFO_SIZE];
	GetNativeString(1, szInfo, sizeof szInfo);
	
	int iIndex = FindItemIndex(szInfo);
	
	delete view_as<DataPack>(g_Array_MenuItems_DataPack.Get(iIndex));
	g_Array_MenuItems_DataPack.Erase(iIndex);
	g_Array_MenuItems_Info.Erase(iIndex);
	g_Array_MenuItems_Name.Erase(iIndex);
	g_Array_MenuItems_Actions.Erase(iIndex);
	g_Array_MenuItems_DrawType.Erase(iIndex);
	g_Array_MenuItems_Order.Erase(iIndex);
}

public int Native_Menu_SetProperty(Handle hPlugin, int argc)
{
	char szInfo[MAX_INFO_SIZE];
	GetNativeString(1, szInfo, sizeof szInfo);

	int iIndex = FindItemIndex(szInfo);
	VIPMenuProperty prop = GetNativeCell(2);
	
	switch(prop)
	{
		case Property_DisplayName:
		{
			char szName[MAX_ITEM_SIZE];
			GetNativeString(3, szName, sizeof szName);
			g_Array_MenuItems_Name.SetString(iIndex, szName);
		}
		
		case Property_Actions:
		{
			g_Array_MenuItems_Actions.Set(iIndex, GetNativeCell(3) | MenuAction_Select);
		}
		
		case Propery_DrawType:
		{
			g_Array_MenuItems_DrawType.Set(iIndex, GetNativeCell(3));
		}
	}
}

public void OnPluginStart()
{
	g_iVIPAccessFlag = ReadFlagString(VIP_ACCESS_FLAG);
	
	AddCommandListener(CommandListenerCallback_OnSay, "say");
	AddCommandListener(CommandListenerCallback_OnSay, "say_team");
}

public Action CommandListenerCallback_OnSay(int client, const char[] command, int argc)
{
	if(!argc)
	{
		return Plugin_Continue;
	}
	
	char szCheckCmd[30];
	GetCmdArg(1, szCheckCmd, sizeof szCheckCmd);
	
	if(szCheckCmd[0] != '!' && szCheckCmd[0] != '/')
	{
		return Plugin_Continue;
	}
	
	for(int i; i < sizeof g_szMenuCommands; i++)
	{
		if(StrEqual(szCheckCmd[1], g_szMenuCommands[i], false))
		{
			ShowMainMenu(client);
			return szCheckCmd[0] == '!' ? Plugin_Continue : Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void ShowMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu, MENU_ACTIONS_ALL);
	
	int iSize = g_Array_MenuItems_Info.Length;
	char szInfo[MAX_INFO_SIZE];
	char szName[MAX_ITEM_SIZE];
	
	bool bHasAccess = IsClientVIP(client);
	for(int i; i < iSize; i++)
	{
		g_Array_MenuItems_Info.GetString(i, szInfo, sizeof szInfo);
		g_Array_MenuItems_Name.GetString(i, szName, sizeof szName);
		
		menu.AddItem(szInfo, szName, bHasAccess ? g_Array_MenuItems_DrawType.Get(i) : ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete menu;
		return 0;
	}

	char szInfo[MAX_INFO_SIZE];
	int iStyle;
	menu.GetItem(param2, szInfo, sizeof szInfo, iStyle);
	
	int iIndex = FindItemIndex(szInfo);
	
	if(action == MenuAction_DrawItem || action == MenuAction_Select || action == MenuAction_DisplayItem)
	{
		if( !(g_Array_MenuItems_Actions.Get(iIndex) & action ) )
		{
			if(action == MenuAction_DrawItem)
			{
				return iStyle;
			}
			
			if(action == MenuAction_DisplayItem)
			{
				return 0;
			}
			
			return 0;
		}
	
		DataPack dp = g_Array_MenuItems_DataPack.Get(iIndex);
		dp.Reset();
		Handle hPlugin = dp.ReadCell();
		Function func = dp.ReadFunction();
		int iRet;
		
		Call_StartFunction(hPlugin, func);
		Call_PushCell(menu);
		Call_PushString(szInfo);
		Call_PushCell(action);
		Call_PushCell(param1);
		Call_PushCell(param2);
		Call_Finish(iRet);
		return iRet;
	}
	
	return 0;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	bool bOld = g_bIsVIP[client];
	g_bIsVIP[client] = false;
	
	if(bOld != false)
	{
		Call_StartForward(g_hForward_Client_OnCheckVIP);
		Call_PushCell(client);
		Call_PushCell(g_bIsVIP[client]);
		Call_Finish();
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	g_bIsVIP[client] = CheckClientVIP(client);
	//g_bIsVIP[client] = true;
	
	Call_StartForward(g_hForward_Client_OnCheckVIP);
	Call_PushCell(client);
	Call_PushCell(g_bIsVIP[client]);
	Call_Finish();
}

int FindItemIndex(char[] szInfo)
{
	char szCheckInfo[MAX_INFO_SIZE];
	int iSize = g_Array_MenuItems_Info.Length;
	
	for(int i; i < iSize; i++)
	{
		g_Array_MenuItems_Info.GetString(i, szCheckInfo, sizeof szCheckInfo);
		if(StrEqual(szCheckInfo, szInfo))
		{
			PrintToServer("%s %s", szCheckInfo, szInfo);
			return i;
		}
	}
	
	return -1;
}

bool IsClientVIP(int client)
{
	return g_bIsVIP[client];
}

bool CheckClientVIP(int client)
{
	if( GetUserFlagBits(client) & (ADMFLAG_ROOT | g_iVIPAccessFlag) )
	{
		return true;
	}
	
	return false;
}
