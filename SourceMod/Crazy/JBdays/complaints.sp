#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.20"

#include <sourcemod>
#include <simonapi>
#include <daysapi>
#include <cstrike>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "FreeKill Complaints", 
	author = PLUGIN_AUTHOR, 
	description = "!freekill !heal commands", 
	version = PLUGIN_VERSION, 
	url = ""
};

bool g_bAutoShowMenu[MAXPLAYERS] = true;

#define No_Complaint 0

int g_iPlayerComplaintNum[MAXPLAYERS] = No_Complaint;
int g_iCurrentComplaintNum = No_Complaint;

ArrayList g_Array_ComplaintNum;
ArrayList g_Array_ComplaintData;

int g_iPlayerKiller[MAXPLAYERS] = 0;

int g_iPlayerMenuComplaintNum[MAXPLAYERS];

enum/* ComplaintType */
{
	CT_FreeKill, 
	CT_Heal, 
	
	CT_Size
};

char g_szComplaintMenuName[CT_Size][] =  {
	"FreeKill", 
	"Heal"
};

#define DataMaxSize	2

float g_vDeathOrigins[MAXPLAYERS][3];

char Action_Respawn[] = "respawn";
char Action_Slay[] = "slay";
char Action_Heal[] = "heal";
char Action_None[] = "none";

enum/* DataType */
{
	DT_Type = 0, 
	DT_Client, 
	
	DT_Size
};

#define Access_None 0
#define Access_Admin (1<<0)
#define Access_Simon (1<<1)
int g_iAccess[MAXPLAYERS];

bool g_bLate = false;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int ErrorMax)
{
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_Array_ComplaintNum = new ArrayList(1);
	g_Array_ComplaintData = new ArrayList(DT_Size); // Complaint Type, Id of complainer, Id of Complained on
	
	RegConsoleCmd("sm_complaints", Command_Complaints);
	RegConsoleCmd("sm_issues", Command_Complaints);
	RegConsoleCmd("sm_report", Command_Complaints);
	RegConsoleCmd("sm_reports", Command_Complaints);
	RegConsoleCmd("sm_freekill", Command_FreeKill);
	RegConsoleCmd("sm_heal", Command_Heal);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void OnMapStart()
{
	g_Array_ComplaintNum.Clear();
	g_Array_ComplaintData.Clear();
	
	g_iCurrentComplaintNum = No_Complaint;
	
	if(g_bLate)
	{
		g_bLate = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
				OnClientPostAdminCheck(i);
			}
		}
		
		SimonAPI_OnSimonChanged(SimonAPI_GetSimon(), No_Simon, SCR_Generic);
	}
}

public void OnClientPutInServer(int client)
{
	g_iPlayerKiller[client] = 0;
	g_iPlayerComplaintNum[client] = No_Complaint;
	g_bAutoShowMenu[client] = true;
}

public void OnClientPostAdminCheck(int client)
{
	if(SimonAPI_HasAccess(client, false))
	{
		g_iAccess[client] = true;
	}
	
	else
	{
		g_iAccess[client] = Access_None;
	}
}

public void SimonAPI_OnSimonChanged(int newClient, int oldClient)
{
	if (oldClient != No_Simon)
	{
		g_iAccess[oldClient] &= ~Access_Simon;
	}
	
	if (newClient != No_Simon)
	{
		g_iAccess[newClient] |= Access_Simon;
	}
}

public void OnClientDisconnect(int client)
{
	if (g_iPlayerComplaintNum[client] != No_Complaint)
	{
		int iIndex = FindComplaintIdFromNum(g_iPlayerComplaintNum[client]);
		DeleteComplaint(iIndex);
	}
}

public void Event_RoundStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iPlayerComplaintNum[i] = No_Complaint;
	}
	
	g_Array_ComplaintNum.Clear();
	g_Array_ComplaintData.Clear();
}

public Action Event_PlayerDeath(Event event, char[] szEventName, bool bDontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(attacker)
	{
		if(GetClientTeam(attacker) != CS_TEAM_CT)
		{
			g_iPlayerKiller[client] = 0;
		}
		
		else
		{
			g_iPlayerKiller[client] = attacker;
		}
	}
	
	if (g_iPlayerComplaintNum[client] != No_Complaint)
	{
		DeleteComplaint(FindComplaintIdFromNum(g_iPlayerComplaintNum[client]));
		g_iPlayerComplaintNum[client] = No_Complaint;
	}
	
	GetClientAbsOrigin(client, g_vDeathOrigins[client]);
	// For some reason, TeleportEntity Actually teleports the EyePosition and not the origin, so
	// Offset our origin by the difference between the eye origin and the actual origin(feet);
	g_vDeathOrigins[client][2] -= 64.0;
	
	
	return Plugin_Continue;
}

public Action Command_FreeKill(int client, int args)
{
	if(DaysAPI_IsDayRunning())
	{
		return Plugin_Handled;
	}
	
	if (g_iPlayerComplaintNum[client] != No_Complaint)
	{
		ReplyToCommand(client, "* You already have a pending complaint (C#%d).", g_iPlayerComplaintNum[client]);
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client))
	{
		ReplyToCommand(client, "* You can't submit if you're alive.");
		return Plugin_Handled;
	}
	
	if (!g_iPlayerKiller[client] || g_iPlayerKiller[client] == client)
	{
		ReplyToCommand(client, "* You can't complain for killing yourself??");
		return Plugin_Handled;
	}
	
	AddComplaint(client, CT_FreeKill);
	ReplyToCommand(client, "* Complaint submitted for freekill (C#%d).", g_iCurrentComplaintNum);
	return Plugin_Handled;
}

public Action Command_Heal(int client, int args)
{
	if(DaysAPI_IsDayRunning())
	{
		return Plugin_Handled;
	}
	
	if (g_iPlayerComplaintNum[client] != No_Complaint)
	{
		ReplyToCommand(client, "* You already have a pending complaint (C#%d).", g_iPlayerComplaintNum[client]);
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "* You can't submit if you're dead.");
		return Plugin_Handled;
	}
	
	if (GetClientHealth(client) >= 100)
	{
		ReplyToCommand(client, "* Really? You are already at full health.");
		return Plugin_Handled;
	}
	
	AddComplaint(client, CT_Heal);
	ReplyToCommand(client, "* Complaint submitted for heal (C#%d).", g_iCurrentComplaintNum);
	return Plugin_Handled;
}

public Action Command_Complaints(int client, int args)
{
	if (!(g_iAccess[client] & (Access_Admin | Access_Simon)))
	{
		return Plugin_Continue;
	}
	
	Menu menu = CreateComplaintMainMenu();
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Menu CreateComplaintMainMenu()
{
	Menu menu = new Menu(MenuHandler_MainMenu, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	menu.SetTitle("Select a Complaint:");
	
	int iArray[DT_Size];
	int iComplaintNum;
	
	menu.AddItem("autoshow", "");
	
	char szFormat[128];
	int iSize = g_Array_ComplaintNum.Length;
	for (int i, issuer; i < iSize; i++)
	{
		iComplaintNum = g_Array_ComplaintNum.Get(i);
		g_Array_ComplaintData.GetArray(i, iArray, DT_Size);
		issuer = iArray[DT_Client];
		
		FormatEx(szFormat, sizeof szFormat, "%N (%-9s) [C#%d]", issuer, g_szComplaintMenuName[iArray[DT_Type]], iComplaintNum);
		menu.AddItem(GetStringOfInt(iComplaintNum), szFormat, ITEMDRAW_DEFAULT);
	}
	
	return menu;
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	if (action == MenuAction_DisplayItem)
	{
		char szInfo[16];
		menu.GetItem(param2, szInfo, sizeof szInfo);
		
		if (!StrEqual(szInfo, "autoshow"))
		{
			return 0;
		}
		
		return RedrawMenuItem(g_bAutoShowMenu[param1] ? "Auto Show: Enabled" : "Auto Show: Disabled");
	}
	
	if (action != MenuAction_Select)
	{
		return 0;
	}
	
	char szInfo[16];
	menu.GetItem(param2, szInfo, sizeof szInfo);
	
	if (StrEqual(szInfo, "autoshow"))
	{
		g_bAutoShowMenu[param1] = !g_bAutoShowMenu[param1];
		
		Menu newmenu = CreateComplaintMainMenu();
		newmenu.Display(param1, MENU_TIME_FOREVER);
		return 0;
	}
	
	int iComplaintNum = StringToInt(szInfo);
	int iIndex = FindComplaintIdFromNum(iComplaintNum);
	
	if (iIndex == -1)
	{
		menu.RemoveItem(param2);
		
		PrintToChat(param1, "* This complaint has already been resolved or deleted.");
		//menu.Display(param1, MENU_TIME_FOREVER);
		
		Menu newmenu = CreateComplaintMainMenu();
		newmenu.Display(param1, MENU_TIME_FOREVER);
		return 0;
	}
	
	ShowComplaintMenu(param1, iIndex, iComplaintNum);
	return 0;
}

void ShowComplaintMenu(int client, int iIndex, int iComplaintNum)
{
	int data[DT_Size];
	
	g_Array_ComplaintData.GetArray(iIndex, data, DT_Size);
	Menu menu = new Menu(MenuHandler_ComplaintAction, MENU_ACTIONS_DEFAULT);
	
	char szFormat[100];
	switch (data[DT_Type])
	{
		case CT_FreeKill:
		{
			if(!IsClientInGame(g_iPlayerKiller[data[DT_Client]]))
			{
				PrintToChat(client, "* Killer no longer in game. Removing complaint.");
				DeleteComplaint(iIndex);
				delete menu;
				return;
			}
			
			FormatEx(szFormat, sizeof szFormat, 
			"Select an Action:\n\
			Complaint: FreeKill (C#%d)\n\
			Issuer: %N\n\
			Killer: %N", iComplaintNum, data[DT_Client], g_iPlayerKiller[data[DT_Client]]);
			menu.SetTitle(szFormat);
			
			FormatEx(szFormat, sizeof szFormat, "Respawn %N", data[DT_Client]);
			menu.AddItem(Action_Respawn, szFormat);
			
			FormatEx(szFormat, sizeof szFormat, "Slay %N", g_iPlayerKiller[data[DT_Client]]);
			menu.AddItem(Action_Slay, szFormat);
			
			menu.AddItem(Action_None, "Do Nothing");
		}
		
		case CT_Heal:
		{
			FormatEx(szFormat, sizeof szFormat, 
			"Select an Action:\n\
			Complaint: FreeKill (C#%d)\n\
			Issuer: %N", iComplaintNum, data[DT_Client]);
			menu.SetTitle(szFormat);
			
			FormatEx(szFormat, sizeof szFormat, "Heal %N to Full", data[DT_Client]);
			menu.AddItem(Action_Heal, szFormat);
			
			menu.AddItem(Action_None, "Do Nothing");
		}
	}
	
	g_iPlayerMenuComplaintNum[client] = iComplaintNum;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ComplaintAction(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	if (action != MenuAction_Select)
	{
		return 0;
	}
	
	int iIndex = FindComplaintIdFromNum(g_iPlayerMenuComplaintNum[param1]);
	if (iIndex == -1)
	{
		PrintToChat(param1, "* This complaint is no longer valid.");
		return 0;
	}
	
	char szAction[15];
	menu.GetItem(param2, szAction, sizeof szAction);
	
	int dataArray[DT_Size];
	g_Array_ComplaintData.GetArray(iIndex, dataArray, DT_Size);
	
	int issuer = dataArray[DT_Client];
	
	if (StrEqual(szAction, Action_Heal))
	{
		if(!IsClientInGame(issuer))
		{
			PrintToChat(param1, "* Player is no longer alive or in game.");
		}
		
		else
		{
			SetEntityHealth(issuer, 100);
			PrintToChat(issuer, "* You were issued a 'Heal' from your complaint by '%N'", param1);
		}
	}
	
	else if (StrEqual(szAction, Action_Slay))
	{
		int iKiller = g_iPlayerKiller[issuer];
		
		if (IsClientInGame(iKiller) && IsPlayerAlive(iKiller))
		{
			ForcePlayerSuicide(iKiller);
			PrintToChat(issuer, "* Player '%N' was slayed due to your complaint by '%N'.", iKiller, param1);
			PrintToChatAll("* Player '%N' was slayed due to a free kill complaint by '%N'.", iKiller, param1);
		}
		
		else
		{
			PrintToChat(param1, "* Player is no longer alive or in game.");
		}
	}
	
	else if (StrEqual(szAction, Action_Respawn))
	{
		if(!IsClientInGame(issuer))
		{
			PrintToChat(param1, "* Player is no longer in game.");
		}
		
		else
		{
			if(IsPlayerAlive(issuer))
			{
				PrintToChat(param1, "* Player is already alive.");
			}
			
			else
			{
				
				float vVel[3];
				vVel[0] = 0.0;
				vVel[1] = 0.0;
				vVel[2] = 0.0;
				
				CS_RespawnPlayer(issuer);
				TeleportEntity(issuer, g_vDeathOrigins[issuer], NULL_VECTOR, vVel);
				PrintToChat(issuer, "* You were respawned by '%N' due to your complaint.", param1);
			}
		}
	}
	
	else if (StrEqual(szAction, Action_None))
	{
		PrintToChat(issuer, "* '%N' decided not to take action regarding your complaint.", param1);
	}
	
	g_iPlayerComplaintNum[issuer] = No_Complaint;
	g_iPlayerKiller[issuer] = 0;
	DeleteComplaint(iIndex);
	return 0;
}

void AddComplaint(int client, int ComplaintType)
{
	++g_iCurrentComplaintNum;
	
	int iComplaintData[DT_Size];
	iComplaintData[DT_Type] = ComplaintType;
	iComplaintData[DT_Client] = client;
	
	g_Array_ComplaintNum.Push(g_iCurrentComplaintNum);
	g_Array_ComplaintData.PushArray(iComplaintData);
	
	g_iPlayerComplaintNum[client] = g_iCurrentComplaintNum;
	ShowMenuToEligibleClients();
}

void ShowMenuToEligibleClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (!(g_iAccess[i] & (Access_Admin | Access_Simon)))
		{
			continue;
		}
		
		if (!g_bAutoShowMenu[i])
		{
			continue;
		}
		
		Menu menu = CreateComplaintMainMenu();
		menu.Display(i, MENU_TIME_FOREVER);
	}
}

int FindComplaintIdFromNum(int iComplaintNum)
{
	int iSize = g_Array_ComplaintNum.Length;
	for (int i; i < iSize; i++)
	{
		if (g_Array_ComplaintNum.Get(i) == iComplaintNum)
		{
			return i;
		}
	}
	
	return -1;
}

void DeleteComplaint(int iIndex)
{
	if (iIndex == -1)
	{
		return;
	}
	
	g_Array_ComplaintNum.Erase(iIndex);
	g_Array_ComplaintData.Erase(iIndex);
}

char[] GetStringOfInt(int iInteger)
{
	char szInt[5];
	FormatEx(szInt, sizeof szInt, "%d", iInteger);
	return szInt;
}

