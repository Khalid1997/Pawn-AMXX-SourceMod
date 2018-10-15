#pragma semicolon 1

#include <sourcemod>
#include <multicolors>
#include <the_khalid_inc>

// ---------------------------------------------------------------------------------
// 								Plugin Info
// ---------------------------------------------------------------------------------
#define PLUGIN_VERSION	"1.0"

public Plugin myinfo = 
{
	name = "Freeday menu",
	author = "Khalid",
	description = "Ability to highlight prisoners for freeday",
	version = PLUGIN_VERSION,
	url = "no url"
}

// ---------------------------------------------------------------------------------
// 								 Important functions
// ---------------------------------------------------------------------------------
#define AddToBit(%1,%2)			%1 |= %2
#define RemoveFromBit(%1,%2)	%1 &= ~%2
stock int IsInBit(any iBit, any iCheck, bool bExactMatch = false)
{
	PrintToServer("%d %d IsInBit", iBit, iCheck);
	int iCheckedBitResult = iBit & iCheck;
	return bExactMatch ? view_as<int>(iCheckedBitResult == iBit) : (iCheckedBitResult);
}

// ---------------------------------------------------------------------------------
// 								Enums
// ---------------------------------------------------------------------------------
enum Change	(<<= 1)
{
	Change_None = 1,
	Change_Change,
	Change_Apply
};

enum FreeDay (<<= 1)
{
	FreeDay_NoChange = 0,
	FreeDay_None = 1,
	FreeDay_Next,
	FreeDay_Active
};

#define FreeDay_All	(FreeDay_Next | FreeDay_Active)

enum 
{
	FDITEM_TIME = 0,	// 0
	FDITEM_MODE,		// 1
	FDITEM_CHOOSE,		// 2
	FDITEM_APPLY,		// 3
	FDITEM_APPLY_NOTE,	// 4
	FDITEM_RESET,		// 5
	FDITEM_CANCEL		// 6
};

enum TIME_MENU
{
	String:TM_STRING[60],
	Float:TM_TIME
};

/*
enum
{
	FreeDayStatus_Active = 0,
	FreeDayStatus_Change,
	
	FreeDayStatus_Total
} */
#define Player_All	0

// ---------------------------------------------------------------------------------
// 								Constants
// ---------------------------------------------------------------------------------
new const gTimeMenuItems[][TIME_MENU] = {
	{ "Full Round", 0.0 },			// 0
	{ "5 Minutes", 300.0 },			// 1
	{ "3 Minutes", 180.0 },			// 2
	{ "2 Minutes",	120.0 },		// 3
	{ "1 Minute",	60.0 },			// 4
	{ "30 Seconds",	30.0 }			// 5
};

const int FREEDAY_TIME_DEFAULT = 0;

new const String:g_szCommands[][] = {
	"sm_fd",
	"sm_freeday",
	"sm_free"
};

#define ADMIN_ACCESS	ADMFLAG_BAN

#define ADMIN_ACCESS_FINAL	(ADMIN_ACCESS | ADMFLAG_ROOT)

// Do not edit.
new const String:FDITEM_ALL[] = "all";

#define RESET_FD_ON_DEATH
#define FOOOOOORCE				// ask me what is this
// ---------------------------------------------------------------------------------
// 								Variables & Important Defines
// ---------------------------------------------------------------------------------
#if defined CS_TEAM_CT
	#define TEAM_GAURDS		CS_TEAM_CT
	#define TEAM_PRISONERS	CS_TEAM_T
#else
	#define TEAM_GAURDS		3
	#define TEAM_PRISONERS	2
#endif

FreeDay g_iPlayerFreeDayStatus[MAXPLAYERS + 1] = FreeDay_None;
float g_flFreeDayTime[MAXPLAYERS + 1];

// ----------------
// Menu Stuff
// ----------------
int g_iFreeDayChoosenTime[MAXPLAYERS + 1];

enum FreeDayChangeStuff
{
	FreeDay:FreeDayChangeStuff_Status,
	Float:FreeDayChangeStuff_Time
};

//any g_iPlayerFreeDayStatus_Change[MAXPLAYERS + 1][MAXPLAYERS + 1][FreeDayChangeStuff];
FreeDay g_iPlayerFreeDayStatus_Change[MAXPLAYERS + 1][MAXPLAYERS + 1];
//bool g_bPlayerFreeDayStatus_WasChanged[MAXPLAYERS + 1][MAXPLAYERS + 1];

Menu g_hFreeDayMenu_ModeMenu;
Menu g_hFreeDayMenu_TimeMenu;
Menu g_hFreeDayMenu_MainMenu;

FreeDay g_iFreeDayMenu_ForceMode[MAXPLAYERS + 1] = FreeDay_None;

char g_szPlayerMenuName[MAXPLAYERS + 1][MAXPLAYERS + 1][MAX_NAME_LENGTH + 1];

// Other
Handle g_hTimer[MAXPLAYERS + 1];

// ---------------------------------------------------------------------------------
// 								Code Start
// ---------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrorMax)
{
	/* Do this (late load && natives) */
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CSGO");
		return;
	}
	
	for (int i; i < sizeof g_szCommands; i++)
	{
		RegConsoleCmd(g_szCommands[i], Command_FreeDay);
	}
	
	HookEvent("round_prestart", Event_RoundPreStart, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
#if defined RESET_FD_ON_DEATH
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
#endif
	
	PrintToServer("Values: %d", FreeDay_NoChange);
	PrintToServer("Values: %d", FreeDay_None);
	PrintToServer("Values: %d", FreeDay_Next);
	PrintToServer("Values: %d", FreeDay_Active);
	PrintToServer("Values: %d", FreeDay_All);
	
	MakeMenus();
}

#if defined RESET_FD_ON_DEATH
public void Event_PlayerDeath(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	PrintToServer("** Death");
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsInBit_C(g_iPlayerFreeDayStatus[client], FreeDay_Active, false))
	{
		RemoveFromBit_C(g_iPlayerFreeDayStatus[client], FreeDay_Active);
		
		DestroyHandle(g_hTimer[client]);
	}
}
#endif

public void Event_RoundPreStart(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	DestroyHandle(g_hTimer[Player_All]);
	PrintToServer("** Round PreStart");
	if(IsInBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_Next, false))
	{
		g_iPlayerFreeDayStatus[Player_All] = FreeDay_Active;
		
		for (int i = 1; i < sizeof g_iPlayerFreeDayStatus; i++)
		{
			g_iPlayerFreeDayStatus[i] = FreeDay_None;
		}
	}
	
	else
	{
		if(IsInBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_Active, false))
		{
			RemoveFromBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_Active);
		}
		
		PrintToServer("** RoundPreStart #2");
		for (int i = 1; i < sizeof g_iPlayerFreeDayStatus; i++)
		{
			g_iPlayerFreeDayStatus[i] = (IsInBit_C(g_iPlayerFreeDayStatus[i], FreeDay_Next, false) ? FreeDay_Active : FreeDay_None);
		}
	}
}

public void Event_RoundStart(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	PrintToServer("** RoundStart #2");
	if(IsInBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_Active, false))
	{
		//DestroyHandle(g_hTimer[Player_All]);
		
		if(g_flFreeDayTime[Player_All] != 0.0)
		{
			g_hTimer[Player_All] = CreateTimer(g_flFreeDayTime[Player_All], Timer_EndFreeDay, Player_All, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_RoundEnd(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	PrintToServer("** RoundEnd");
	if( IsInBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_Active, false) )
	{
		RemoveFromBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_Active);

		DestroyHandle(g_hTimer[Player_All]);
	}
}

public Action Timer_EndFreeDay(Handle hTimer, int client)
{
	if(client != 0 && !IsClientValid(client, true))
	{
		g_hTimer[client] = INVALID_HANDLE;
		RemoveFromBit_C(g_iPlayerFreeDayStatus[client], FreeDay_Active);
		return Plugin_Stop;
	}
	
	PrintToServer("** Timer End");
	if(IsInBit_C(g_iPlayerFreeDayStatus[client], FreeDay_Active, false) )
	{
		RemoveFromBit_C(g_iPlayerFreeDayStatus[client], FreeDay_Active);
		SetFreeDay(client, false);
	}
	
	g_hTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public void Event_PlayerSpawn(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	PrintToServer("** Spawn");
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsInBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_Active, false))
	{
		// Do not set time here because we will a timer will be created on round start
		SetFreeDay(client, true, 0.0);
	}
	
	else if(IsInBit_C(g_iPlayerFreeDayStatus[client], FreeDay_Active, false))
	{
		SetFreeDay(client, true, g_flFreeDayTime[client]);
	}
}

public void OnClientPutInServer(client)
{
	g_iPlayerFreeDayStatus[client] = FreeDay_None;
	g_iFreeDayMenu_ForceMode[client] = FreeDay_None;
	
	g_flFreeDayTime[client] = 0.0;
	g_iFreeDayChoosenTime[client] = FREEDAY_TIME_DEFAULT;

	SetArrayValue(g_iPlayerFreeDayStatus_Change[client], sizeof(g_iPlayerFreeDayStatus_Change[]), FreeDay_NoChange, 0);
}

public void OnClientDisconnect(client)
{
	DestroyHandle(g_hTimer[client]);
}

public void OnMapStart()
{
	// Assume we destroyed all timers
	SetArrayValue(g_hTimer, sizeof g_hTimer, INVALID_HANDLE, 0);
	
	g_iPlayerFreeDayStatus[Player_All] = FreeDay_None;
}

public Action Command_FreeDay(int client, int args)
{
	if(!HasMenuAccess(client))
	{
		PrintToChat(client, "* Only Admins and CTs can use this command.");
		return Plugin_Handled;
	}
	
	/*
	// He is a CT
	// Admins always have access to this.
	else if(!IsPlayerAlive(client) && !AdminHasAccess(client, ADMIN_ACCESS))
	{
		PrintToChat(client, "* You must be alive to use the menu.");
		return Plugin_Handled;
	}
	*/
	
	g_hFreeDayMenu_MainMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

void MakeMenus()
{
	g_hFreeDayMenu_MainMenu = MakeFreeDayMenu();
	g_hFreeDayMenu_TimeMenu = MakeTimeMenu();
	g_hFreeDayMenu_ModeMenu = MakeModeMenu();
}

Menu MakeFreeDayMenu()
{
	Menu hMenu;
	hMenu = CreateMenu(Menu_FreeDay_Main_Handler, MENU_ACTIONS_ALL);
	hMenu.SetTitle("Choose an option");
	
	// ----------------------------------------------------------------------
	// Do not change info number unless you know what you are doing.....
	// ----------------------------------------------------------------------
	//char szFormat[120];
	//FormatEx( szFormat, sizeof szFormat, "Freeday Time: %s", g_szTimeMenuItems[ g_iFreeDayChoosenTime[client] ] );
	hMenu.AddItem("0", "");		// Format later ( Time )
	hMenu.AddItem("1", "");		// format later ( Mode )
	
	hMenu.AddItem("2", "Choose a Player(s).");
	hMenu.AddItem("3", "Apply Freedays.");
	hMenu.AddItem("4", "NOTE: Above option will only apply changes!");
	
	hMenu.AddItem("5", "Reset all changes (Use before applying only)");
	
	hMenu.AddItem("6", "Cancel All Freedays");
	
	hMenu.ExitButton = true;
	return hMenu;
}

Menu MakeTimeMenu()
{
	Menu hMenu;
	hMenu = CreateMenu(Menu_TimeMenu_Handler, MENU_ACTIONS_ALL);
	hMenu.SetTitle("Choose the Freeday time");
	
	char szInfo[5];
	for (int i; i < sizeof(gTimeMenuItems); i++)
	{
		IntToString(i, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "");
	}
	
	//hMenu.Display(client, MENU_TIME_FOREVER);
	return hMenu;
}

Menu MakeModeMenu()
{
	return view_as<Menu>INVALID_HANDLE;
}

public int Menu_FreeDay_Main_Handler(Menu hMenu, MenuAction iAction, int param1, int param2)
{
	int iShowMenuAgain = 0;
	switch(iAction)
	{
		/*
		case MenuAction_End:
		{
			return 0;
		}*/
		
		case MenuAction_DisplayItem:
		{
			switch(param2)
			{
				case FDITEM_TIME:
				{
					char szFormat[40];
					FormatEx(szFormat, sizeof szFormat, "Freeday time: %s", gTimeMenuItems[g_iFreeDayChoosenTime[param1]][TM_STRING]);
					
					RedrawMenuItem(szFormat);
				}
				
				case FDITEM_MODE:
				{
					char szFreeDayModeFmt[20];
					char szFormat[60];
					
					GetFreeDayString(g_iFreeDayMenu_ForceMode[param1], szFreeDayModeFmt, sizeof szFreeDayModeFmt);
					FormatEx(szFormat, sizeof szFormat, "Freeday force mode: %s", szFreeDayModeFmt);
					
					RedrawMenuItem(szFormat);
				}
			}
				
			return 0;
		}
		
		case MenuAction_DrawItem:
		{
			if(param2 == FDITEM_APPLY_NOTE)
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			if(!HasMenuAccess(param1))
			{
				//CancelMenu(hMenu);
				return 0;
			}
			
			switch(param2)
			{
				case FDITEM_TIME:
				{
					//ShowTimeMenu(param1);
					g_hFreeDayMenu_TimeMenu.Display(param1, MENU_TIME_FOREVER);
				}
				
				case FDITEM_MODE:
				{
					//ShowModeMenu(param1);
					/* Do this */
					PrintToChat(param1, "* This is not done yet..");
					hMenu.Display(param1, MENU_TIME_FOREVER);
				}
				
				case FDITEM_CHOOSE:
				{
					DisplayPlayerMenu(param1);
				}
				
				case FDITEM_APPLY:
				{
					ApplyChanges(Change_Apply);
					iShowMenuAgain = 1;
				}
				
				case FDITEM_APPLY_NOTE:
				{
					CPrintToChat(param1, "* How did you even choose this? LOL");
					iShowMenuAgain = 1;
				}
				
				case FDITEM_RESET:
				{
					ResetChangeFreeDayVars(param1);
					PrintToChat(param1, "* Successfully reset to default/current values.");

					iShowMenuAgain = 1;
				}
				
				case FDITEM_CANCEL:
				{
					CancelAllFreeDays();
					ResetChangeFreeDayVars(param1);
					PrintToChat(param1, "* Successfully cancelled ALL freedays");

					iShowMenuAgain = 1;
				}
			}
		}
	}
	
	if(iShowMenuAgain)
	{
		hMenu.Display(param1, MENU_TIME_FOREVER);
	}
			
	PrintToServer("Menu Select %d", hMenu);
	return 0;
}

void ResetChangeFreeDayVars(int client)
{
	g_iPlayerFreeDayStatus_Change[client][Player_All] = g_iPlayerFreeDayStatus[Player_All];
	
	for (int i; i < sizeof g_iPlayerFreeDayStatus_Change[]; i++)
	{
		g_iPlayerFreeDayStatus_Change[client][i] = g_iPlayerFreeDayStatus[i];
	}
}

void CancelAllFreeDays()
{
	g_iPlayerFreeDayStatus[Player_All] = FreeDay_None;
	DestroyHandle(g_hTimer[Player_All]);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iPlayerFreeDayStatus[i] = FreeDay_None;
		DestroyHandle(g_hTimer[Player_All]);
		
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_PRISONERS && IsPlayerAlive(i))
		{
			SetFreeDay(i, false, 0.0);
		}
	}
}

void DisplayPlayerMenu(int client)
{
	Menu hMenu;
	hMenu = CreateMenu(Menu_PlayerMenu_Handler, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	hMenu.SetTitle("Syntax: Name <Alive or Dead> (Current Freeday Status) [Change freeday Status]");
	
	hMenu.AddItem(FDITEM_ALL, "All Players");
	
	char szInfo[4];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientValid(i, false))
		{
			continue;
		}
		
		if( GetClientTeam(client) != TEAM_PRISONERS )
		{
			continue;
		}
		
		GetClientName(i, g_szPlayerMenuName[client][i], sizeof(g_szPlayerMenuName[][]));
		IntToString(i, szInfo, sizeof szInfo);
		
		hMenu.AddItem(szInfo, "");
	}
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}

void FormatPlayerMenuName(int iOriginClient, int iOtherClient, char szPlayerNameString[128], iSize)
{
	static char szCurrentFreeDayString[16];
	static char szChangeFreeDayString[16];
	
	if(!iOtherClient)
	{
		GetFreeDayString(g_iPlayerFreeDayStatus[Player_All], szCurrentFreeDayString, sizeof szCurrentFreeDayString);
		GetFreeDayString(g_iPlayerFreeDayStatus_Change[iOriginClient][Player_All], szChangeFreeDayString, sizeof szChangeFreeDayString);
		
		FormatEx(szPlayerNameString, iSize, "Everyone: <> (%s) [%s]", szCurrentFreeDayString, szChangeFreeDayString);
	}
	
	else
	{
		GetFreeDayString(g_iPlayerFreeDayStatus[iOtherClient], szCurrentFreeDayString, sizeof szCurrentFreeDayString);
		GetFreeDayString(g_iPlayerFreeDayStatus_Change[iOriginClient][iOtherClient], szChangeFreeDayString, sizeof szChangeFreeDayString);
		
		FormatEx(szPlayerNameString, iSize, "%s <%s> (%s) [%s]", g_szPlayerMenuName[iOriginClient][iOtherClient], IsPlayerAlive(iOtherClient) ? "Alive" : "Dead", szCurrentFreeDayString, szChangeFreeDayString);
	}
}

void GetFreeDayString(FreeDay iStatus, char[] szFreeDayString, int iSize)
{
	switch(iStatus)
	{
		case FreeDay_None:		FormatEx(szFreeDayString, iSize, "None");
		case FreeDay_Active:	FormatEx(szFreeDayString, iSize, "Current Round");
		case FreeDay_Next:		FormatEx(szFreeDayString, iSize, "Next Round");
		case FreeDay_NoChange:	FormatEx(szFreeDayString, iSize, "No Change");
		default:
		{
			PrintToServer("** FreeDayString #2");
			if( IsInBit_C(iStatus, FreeDay_All, true) )
			{
				FormatEx(szFreeDayString, iSize, "Current & Next");
			}
			
			else FormatEx(szFreeDayString, iSize, "Error");
		}
	}
}

public int Menu_TimeMenu_Handler(Menu hMenu, MenuAction iAction, int param1, int param2)
{
	switch(iAction)
	{
		/*
		case MenuAction_End:
		{
			delete hMenu;
		} */
		
		case MenuAction_Cancel:
		{
			g_hFreeDayMenu_MainMenu.Display(param1, MENU_TIME_FOREVER);
		}
		
		case MenuAction_DisplayItem:
		{
			char szInfo[4], szFormatString[40];
			int iInfoNum;
			
			hMenu.GetItem(param2, szInfo, sizeof szInfo);
			iInfoNum = StringToInt(szInfo);
			
			FormatEx(szFormatString, sizeof szFormatString, "%s%s", gTimeMenuItems[param2][TM_STRING], g_iFreeDayChoosenTime[param1] == iInfoNum ? " [Choosen]" : "");
			
			return RedrawMenuItem(szFormatString);
		}
		
		case MenuAction_DrawItem:
		{
			char szInfo[4]; int iInfoNum;
			hMenu.GetItem(param2, szInfo, sizeof szInfo);
			
			iInfoNum = StringToInt(szInfo);
			
			if(iInfoNum == g_iFreeDayChoosenTime[param1])
			{
				return ITEMDRAW_DISABLED;
			}
		
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			char szInfo[4]; 
			int iInfoNum;
			
			hMenu.GetItem(param2, szInfo, sizeof szInfo);
			
			iInfoNum = StringToInt(szInfo);
			
			g_iFreeDayChoosenTime[param1] = iInfoNum;
			
			hMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

public int Menu_PlayerMenu_Handler(Menu hMenu, MenuAction iAction, int param1, int param2)
{
	switch(iAction)
	{
		/*
		case MenuAction_End:
		{
			
			
		}*/
		
		case MenuAction_Cancel:
		{
			PrintToServer("End %d %d", param1, param2);
			delete hMenu;
			g_hFreeDayMenu_MainMenu.Display(param1, MENU_TIME_FOREVER);
		}
		
		case MenuAction_DisplayItem:
		{
			char szInfo[5];
			char szFormatString[128];
			
			hMenu.GetItem(param2, szInfo, sizeof szInfo);
			int iOtherClient = !StrEqual(szInfo, FDITEM_ALL) ? StringToInt(szInfo) : 0;
			
			FormatPlayerMenuName(param1, iOtherClient, szFormatString, sizeof szFormatString);
			return RedrawMenuItem(szFormatString);
		}
		
		case MenuAction_DrawItem:
		{
			char szInfo[5];
			hMenu.GetItem(param2, szInfo, sizeof szInfo);
			
			if(StrEqual(szInfo, FDITEM_ALL))
			{
				return ITEMDRAW_DEFAULT;
			}
			
			PrintToServer("** DrawItem - PlayerMenu");
			if(IsInBit_C(g_iPlayerFreeDayStatus[Player_All], FreeDay_All, true) || IsInBit_C(g_iPlayerFreeDayStatus_Change[param1][Player_All], FreeDay_All, true))
			{
				return ITEMDRAW_DISABLED;
			}
			
			#if !defined FOOOOOORCE
			int iOtherClient = StringToInt(szInfo);
			
			if( !IsPlayerAlive(client) && IsInBit_C(g_iFreeDayMenu_ForceMode[client], FreeDay_Active, true) )
			{
				return ITEMDRAW_DISABLED;
			}
			#endif
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			char szInfo[5];
			int iTargetClient;
			
			hMenu.GetItem(param2, szInfo, sizeof szInfo);
			
			iTargetClient = StrEqual(szInfo, FDITEM_ALL) ? 0 : StringToInt(szInfo);
			
			if(!ApplyChanges(Change_Change, param1, iTargetClient))
			{
				//CancelClientMenu(param1);
				
				delete hMenu;
				DisplayPlayerMenu(param1);
				
				return 0;
			}
			
			hMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

//bool ApplyChanges(Change iChange, int client = 0, int iTargetClient = 0)
{	
	switch(iChange)
	{
		case Change_Apply:
		{
			return HandleApply(client);
		}
		
		case Change_Change:
		{
			return HandleChange(client, iTargetClient);
		}
	}
	
	return false;
}

bool HandleApply(int client)
{
	int iNumChanges;
	//bool bAllowCurrent = true;
	int iPlayers[MAXPLAYERS], iCount;
	FreeDay iNewStatus = g_iPlayerFreeDayStatus_Change[client][Player_All];
	
	PrintToServer("iNewStatus = %d ... %d - Equality: %d %d", view_as<int>iNewStatus, view_as<int>g_iPlayerFreeDayStatus[Player_All], view_as<int>(view_as<int>iNewStatus == view_as<int>g_iPlayerFreeDayStatus[Player_All]), view_as<int>( iNewStatus == g_iPlayerFreeDayStatus[Player_All] ) );
	if(iNewStatus != FreeDay_NoChange)
	{
		//g_iPlayerFreeDayStatus[Player_All] = iNewStatus;
		
		iCount = GetPlayers(iPlayers, GetPlayersFlag_InGame | GetPlayersFlag_NoBots, GP_TEAM_FIRST, GetPlayersFlag_AdminNone);
	}
	
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				continue;
			}
			
			if(IsFakeClient(i))
			{
				continue;
			}
			
			if(GetClientTeam(i) != TEAM_PRISONERS)
			{
				continue;
			}
			
			if(g_iPlayerFreeDayStatus_Change[client][i] == FreeDay_NoChange)
			{
				continue';
			}
			
			if(IsInBit(g_iPlayerFreeDayStatus_Change[client][i], FreeDay_Active, false))
			{
				if(!IsClientAlive(i))
				{
					continue;
				}
			}
			
			//g_iPlayerFreeDayStatus[i] = g_iPlayerFreeDayStatus_Change[client][i]
			iPlayers[iCount++] = i;
		}
	}
	
	ApplyFreeDaysOnPlayers(client, iPlayers, iCount)
	SetArrayValue(g_iPlayerFreeDayStatus_Change[client], sizeof(g_iPlayerFreeDayStatus_Change[]), FreeDay_NoChange, 0);
	
	return true;
}
/// HEREEEE
void ApplyFreeDaysOnPlayers(int iOriginClient, int iPlayers[MAXPLAYERS], int iPlayersCount)
{
	int i, iFullChangeStatus = 0;		// 0 - No, 1 - either one, 2 - Both (next and current)
	FreeDay iFullFreeDay = FreeDay_NoChange;

	if( (iFullFreeDay = g_iPlayerFreeDayStatus_Change[iOriginClient][Player_All] ) != FreeDay_NoChange )
	{
		if(IsInBit(iFullFreeDay, FreeDay_All, true)
		{
			iFullChangeStatus = 2;
		}
		
		else iFullChangeStatus = 1;
		g_iPlayerFreeDayStatus[Player_All] = g_iPlayerFreeDayStatus_Change[iOriginClient][Player_All];
	}
	
	for (int i; i < iPlayersCount; i++)
	{
		if(g_iPlayerFreeDayStatus_Change[iOriginClient][i] != FreeDay_NoChange)
		{
			g_iPlayerFreeDayStatus[i] = g_iPlayerFreeDayStatus_Change[iOriginClient][i];
		}
		
		switch(iFullChangeStatus)
		{
			case 0:
			{
				
			}
			
			case 1:
			{
				g_iPlayerFreeDayStatus[i] = g_iPlayerFreeDayStatus[Player_All] & 
			}
			
			case 2:
			{
				g_iPlayerFreeDayStatus[i] = FreeDay_None;
			}
		}
	}
}

bool HandleChange(int client, int iTargetClient = 0)
{
	if(iTargetClient && !IsClientValid(iTargetClient, false))
	{
		PrintToChat(iTargetClient, "* Player %s is no longer connected.", g_szPlayerMenuName[client][iTargetClient]);
		return false;
	}
	
	// If it was a normal day with nothing planned, continue
	FreeDay iStatus = DetermineNextFreeDayStatus(g_iPlayerFreeDayStatus_Change[client][iTargetClient], client, iTargetClient);
	
	g_iPlayerFreeDayStatus_Change[client][iTargetClient] = iStatus;
	return true;
}

FreeDay DetermineNextFreeDayStatus(FreeDay iCurrentStatus, int client, int iTarget)
{
	FreeDay iRet;
	
	if(g_iFreeDayMenu_ForceMode[client] != FreeDay_None)
	{
#if defined FOOOOOORCE
		return (g_iFreeDayMenu_ForceMode[client]);
#else
		PrintToServer("** Determine Next #1");
		if(IsInBit_C(g_iFreeDayMenu_ForceMode[client], FreeDay_Active, false) && iTarget)
		{
			if(!IsPlayerAlive(iTarget))
			{
				PrintToServer("** Determine Next #2");
				if(IsInBit_C(g_iFreeDayMenu_ForceMode[client], FreeDay_All, true))
				{
					PrintToServer("** Determine Next #3");
					return view_as<FreeDay>(iRet = (IsInBit_C(iCurrentStatus, g_iFreeDayMenu_ForceMode[client], false) ? FreeDay_None : FreeDay_Next ) );
				}
			}
			
			// Should not happen because we disable dead players from menu
			/*
			else if(IsInBit_C(g_iFreeDayMenu_ForceMode[client], FreeDay_Active, true)
			{
				iRet = FreeDay_None;
			}
			*/
		}
		
		PrintToServer("** Determine Next #4");
		return iRet = IsInBit_C(iCurrentStatus, g_iFreeDayMenu_ForceMode[client], true) ? FreeDay_None : gTimeMenuItems[g_iFreeDayMenu_ForceMode[client]][TM_TIME];
#endif
	}
	
	else
	{
		iRet = GetNextStatus_Normal(iCurrentStatus);
	}
	
	if(iTarget != Player_All)
	{
		int iAlive = IsPlayerAlive(iTarget);
		PrintToServer("** Determine Next #6");
		if(IsInBit_C(iRet, FreeDay_Active, true) && !iAlive)
		{
			iRet = FreeDay_Next;
		}
		
		else if(IsInBit_C(iRet, FreeDay_All, true) && !iAlive)
		{
			iRet = FreeDay_None;
		}
	}
	
	return iRet;
}

// No alive/dead status checks here
FreeDay GetNextStatus_Normal(FreeDay iCurrentStatus)
{
	switch(iCurrentStatus)
	{
		case FreeDay_None:		return FreeDay_Active;
		case FreeDay_Active:	return FreeDay_Next;
		case FreeDay_Next:		return FreeDay_All;
		case FreeDay_All:		return FreeDay_NoChange;
		case FreeDay_NoChange:	return FreeDay_None;
	}
	
	//g_iPlayerFreeDayStatus_Change[client][iTargetClient] = FreeDay_None;
	//PrintToChat(client, "* An Error has occurred while trying to change freeday status for '%s'", g_szPlayerMenuName[client][iTargetClient]);
	LogError("ERRRRRRRRRRRRRRRRRRRRRRROOOOORRR");
	LogMessage("ERRRRRRRRRRRRRRRRRRRRRRROOOOORRR");
	return FreeDay_None;
}

void SetFreeDay(int client, bool bStatus, float flTimerTime = 0.0)
{
	switch(bStatus)
	{
		case false:	SetEntityRenderColor(client);
		case true:
		{
			SetEntityRenderColor(client, 0, 128, 0, 255);
			
			if(flTimerTime != 0.0)
			{
				DestroyHandle(g_hTimer[client]);

				g_hTimer[client] = CreateTimer(flTimerTime, Timer_EndFreeDay, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			PrintToChat(client, "** You were given a freeday");
		}
	}
}

stock bool IsClientValid(int client, bool bCheckAlive = false)
{
	if( !( 0 < client <= MaxClients ) )
	{
		return false;
	}
	
	if(!IsClientInGame(client))
	{
		return false;
	}
	
	if(bCheckAlive && !IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
} 

stock void DestroyHandle(Handle &hHandle)
{
	if(hHandle != INVALID_HANDLE)
	{
		CloseHandle(hHandle);
		hHandle = INVALID_HANDLE;
	}
}

stock int HasMenuAccess(client)
{
	if( GetClientTeam(client) != TEAM_GAURDS )
	{
		if(AdminHasAccess(client, ADMIN_ACCESS_FINAL))
		{
			return 1;
		}
		
		return 0;
	}
	
	return 1;
}

stock bool AdminHasAccess(int client, int iFlag)
{
	AdminId iAdminId = GetUserAdmin(client);
	PrintToServer("** AdminFlags");
	if(!IsInBit_C(GetAdminFlags(iAdminId, Access_Real), iFlag, false))
	{
		return false;
	}
	
	return true;
}
