#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <daysapi>
#include <getplayers>

#undef REQUIRE_PLUGIN
#include <simonapi>
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
	name = "DaysAPI: Menu", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

Menu g_mVoteMenu, 
g_mMainMenu;

int g_iPlayerVoteChoice[MAXPLAYERS];

ArrayList g_Array_Names, 
g_Array_DisplayNames, 
g_Array_Votes;

float g_flVoteTime = 15.0, 
g_flVoteStartTime, 
g_flVoteEndTime, 
g_flMenuUpdateFreq = 0.5;

int g_iTotalVotes;

bool g_bVoteInProgress, 
g_bHasPlayerExitedMenu[MAXPLAYERS];

Handle g_hTimer_UpdateMenu;

#define MENU_MAX_ITEM_NAME	(MAX_DISPLAY_NAME_LENGTH + 6)
#define MAX_INFO_SIZE		5

#define MMItem_Mode				0
#define MMItem_SelectDay		1
#define MMItem_VoteDay			2
#define MMItem_EndDay			3
#define MMItem_CancelLast		4

#define MODE_PLAN				0
#define MODE_START				1

int g_iVoteMode = MODE_PLAN;

ConVar ConVar_MinPlayers;

bool g_bSimonAPI;
public void OnLibraryAdded(const char[] szName)
{
	if(StrEqual(szName, "simonapi"))
	{
		g_bSimonAPI = true;
	}
}

public void OnLibraryRemoved(const char[] szName)
{
	if(StrEqual(szName, "simonapi"))
	{
		g_bSimonAPI = false;
	}
}

public void OnAllPluginsLoaded()
{
	g_bSimonAPI = LibraryExists("simonapi");
}

public void OnPluginStart()
{
	//ConVar_VotingTime = CreateConVar("mjb_votetime", "20.0", "Voting time");
	//ConVar_VotingTime.AddChangeHook(ConVarChange_CallBack);
	
	//g_flVotingTime = ConVar_VotingTime.FloatValue;
	
	RegConsoleCmd("sm_voteday", ConCmd_VotingMenu, "Allows warden & admin to opens event day voting");
	RegConsoleCmd("sm_days", ConCmd_VotingMenu, "Allows warden & admin to opens event day voting");
	RegConsoleCmd("sm_day", ConCmd_VotingMenu, "Allows warden & admin to opens event day voting");
	
	ConVar_MinPlayers = CreateConVar("daysapi_menu_minplayers", "4");
	BuildMenus();
}

public void OnMapStart()
{
	AutoExecConfig(true, "daysapi_menu");
	
	if (g_bVoteInProgress)
	{
		ResetVoteValues();
	}
}

void ResetVoteValues()
{
	g_bVoteInProgress = false;
	
	g_flVoteStartTime = 0.0;
	g_flVoteEndTime = 0.0;
	
	g_iVoteMode = MODE_PLAN;
	
	// Vote-Storing array.
	if (g_Array_Names != null)
	{
		delete g_Array_Names;
		g_Array_Names = null;
	}
	
	if (g_Array_DisplayNames != null)
	{
		delete g_Array_DisplayNames;
		g_Array_DisplayNames = null;
	}
	
	if (g_Array_Votes != null)
	{
		delete g_Array_Votes;
		g_Array_Votes = null;
	}
	
	if (g_mVoteMenu != null)
	{
		delete g_mVoteMenu;
		g_mVoteMenu = null;
	}
	
	if (g_hTimer_UpdateMenu != null)
	{
		delete g_hTimer_UpdateMenu;
		g_hTimer_UpdateMenu = null;
	}
	
	g_iTotalVotes = 0;
	
	SetArrayValue(g_iPlayerVoteChoice, sizeof g_iPlayerVoteChoice, -1);
	SetArrayValue(g_bHasPlayerExitedMenu, sizeof g_bHasPlayerExitedMenu, false);
}

public Action ConCmd_VotingMenu(int client, int iArgs)
{
	int iCount = GetPlayers(_, _, GP_Team_First | GP_Team_Second);
	if( iCount < ConVar_MinPlayers.IntValue )
	{
		CReplyToCommand(client, "\x04* You cannot start a day as there are not enough players in game.");
		return Plugin_Handled;
	}
	
	g_mMainMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int g_iMode[MAXPLAYERS] = MODE_PLAN;
void BuildMenus()
{
	/*	
		Choose Days to Vote
		StartVote
		CancelVote
	*/
	
	g_mMainMenu = new Menu(MenuHandler_MainMenu, MENU_ACTIONS_DEFAULT | MenuAction_DrawItem | MenuAction_DisplayItem | MenuAction_Display);
	// Keep in this Order
	char szTitle[60];
	FormatEx(szTitle, sizeof szTitle, "Select an Item:");
	
	g_mMainMenu.SetTitle(szTitle);
	
	// Start Now/NextRound
	g_mMainMenu.AddItem("0", "Toggle Mode");
	g_mMainMenu.AddItem("1", "Select Day");
	g_mMainMenu.AddItem("2", "Vote Day");
	g_mMainMenu.AddItem("3", "End Current Day");
	g_mMainMenu.AddItem("4", "Cancel Planned Day");
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			return 0;
		}
		
		case MenuAction_DisplayItem:
		{
			char szInfo[MAX_INFO_SIZE];
			menu.GetItem(param2, szInfo, sizeof szInfo);
			int iItem = StringToInt(szInfo);
			
			if(iItem == MMItem_Mode)
			{
				switch(g_iMode[param1])
				{
					case MODE_PLAN:
					{
						RedrawMenuItem("Toggle Mode [Plan (Start Next Round)]");
					}
					
					case MODE_START:
					{
						RedrawMenuItem("Toggle Mode [Start Now]");
					}
				}
			}
			
			else if(iItem == MMItem_EndDay)
			{
				if (!DaysAPI_IsDayRunning())
				{
					return RedrawMenuItem("End Current Day");
				}
				
				char szFmt[35];
				char szDispName[MAX_DISPLAY_NAME_LENGTH];
				ArrayList array = new ArrayList(MAX_DISPLAY_NAME_LENGTH);
				DaysAPI_GetRunningDays(GetDaysCallback, array);
				array.GetString(0, szDispName, sizeof szDispName);
				delete array;
				
				FormatEx(szFmt, sizeof szFmt, "End Current Day [%s]", szDispName);
				return RedrawMenuItem(szFmt);
			}
			
			else if(iItem == MMItem_CancelLast)
			{
				if (!DaysAPI_IsDayPlanned())
				{
					return RedrawMenuItem("Cancel Planned Day");
				}
				
				char szFmt[35];
				char szDispName[MAX_DISPLAY_NAME_LENGTH];
				ArrayList array = new ArrayList(MAX_DISPLAY_NAME_LENGTH);
				DaysAPI_GetPlannedDays(GetDaysCallback, array);
				array.GetString(0, szDispName, sizeof szDispName);
				delete array;
				
				FormatEx(szFmt, sizeof szFmt, "Cancel Planned Day [%s]", szDispName);
				return RedrawMenuItem(szFmt);
			}
		}
		
		case MenuAction_DrawItem:
		{
			if(!HasAccess(param1, true))
			{
				return ITEMDRAW_DISABLED;
			}
			
			char szInfo[MAX_INFO_SIZE];
			menu.GetItem(param2, szInfo, sizeof szInfo);
			int iItem = StringToInt(szInfo);
			
			if (iItem == MMItem_Mode)
			{
				return ITEMDRAW_DEFAULT;
			}
			
			if (iItem == MMItem_SelectDay || iItem == MMItem_VoteDay)
			{
				if (g_iMode[param1] == MODE_PLAN && DaysAPI_IsDayPlanned())
				{
					return ITEMDRAW_DISABLED;
				}
				
				else if (g_iMode[param1] == MODE_START && DaysAPI_IsDayRunning())
				{
					return ITEMDRAW_DISABLED;
				}
				
				return ITEMDRAW_DEFAULT;
			}
			
			if (iItem == MMItem_CancelLast)
			{
				if (DaysAPI_IsDayPlanned())
				{
					return ITEMDRAW_DEFAULT;
				}
				
				return ITEMDRAW_DISABLED;
			}
			
			if (iItem == MMItem_EndDay)
			{
				if (DaysAPI_IsDayRunning())
				{
					return ITEMDRAW_DEFAULT;
				}
				
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			char szInfo[MAX_INFO_SIZE];
			menu.GetItem(param2, szInfo, sizeof szInfo);
			int iItem = StringToInt(szInfo);
			bool bRedisplay = true;
			
			/*
			#define MMItem_Mode				0
			#define MMItem_SelectDay		1
			#defien MMItem_VoteDay			2
			#define MMItem_EndDay			3
			#define MMItem_CancelLast		4
			*/
			
			switch (iItem)
			{
				case MMItem_Mode:
				{
					g_iMode[param1] = !g_iMode[param1];
				}
				
				case MMItem_SelectDay:
				{
					if (g_iMode[param1] == MODE_START && DaysAPI_IsDayRunning())
					{
						CPrintToChat(param1, "\x04* A day is already running.");
					}
					
					else if (g_iMode[param1] == MODE_PLAN && DaysAPI_IsDayPlanned())
					{
						CPrintToChat(param1, "\x04* A day is already planned.");
					}
					
					else
					{
						SelectDayMenu(param1);
						bRedisplay = false;
					}
				}
				
				case MMItem_VoteDay:
				{
					if(g_bVoteInProgress)
					{
						CPrintToChat(param1, "\x04* A vote is already in progress.");
					}
					
					if (g_iMode[param1] == MODE_START && DaysAPI_IsDayRunning())
					{
						CPrintToChat(param1, "\x04* A day is already running.");
					}
					
					else if (g_iMode[param1] == MODE_PLAN && DaysAPI_IsDayPlanned())
					{
						CPrintToChat(param1, "\x04* A day is already planned.");
					}
					
					else
					{
						bRedisplay = false;
						StartVote(g_iMode[param1]);
					}
				}
				
				case MMItem_CancelLast:
				{
					DaysAPI_CancelAllPlannedDays();
				}
				
				case MMItem_EndDay:
				{
					DaysAPI_EndAllDays();
				}
			}
			
			if (bRedisplay)
			{
				menu.Display(param1, MENU_TIME_FOREVER);
			}
			
			return 0;
		}
		
		case MenuAction_Cancel:
		{
			return 0;
		}
	}
	
	return 0;
}

void SelectDayMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SelectDay, MENU_ACTIONS_DEFAULT);
	{
		ArrayList Array_Names, Array_DisplayNames;
		Array_Names = CreateArray(MAX_INTERNAL_NAME_LENGTH);
		Array_DisplayNames = CreateArray(MAX_DISPLAY_NAME_LENGTH);
		
		DataPack dp = new DataPack();
		dp.WriteCell(Array_Names);
		dp.WriteCell(Array_DisplayNames);
		
		int iSize = DaysAPI_GetDays(GetDaysCallbackWithDisplayNames, true, dp);
		
		char szInternalName[MAX_INTERNAL_NAME_LENGTH];
		char szDisplayName[MAX_DISPLAY_NAME_LENGTH];
		
		for (int i; i < iSize; i++)
		{
			Array_Names.GetString(i, szInternalName, sizeof szInternalName);
			Array_DisplayNames.GetString(i, szDisplayName, sizeof szDisplayName);
			menu.AddItem(szInternalName, szDisplayName);
		}
		
		delete Array_Names;
		delete Array_DisplayNames;
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public bool GetDaysCallback(char[] szIntName, char[] szDispName, DayFlag iFlags, ArrayList array)
{
	array.PushString(szDispName);
	return true;
}

public bool GetDaysCallbackWithDisplayNames(char[] szIntName, char[] szDispName, DayFlag iFlags, DataPack dp)
{
	dp.Reset();
	PushArrayString(dp.ReadCell(), szIntName);
	PushArrayString(dp.ReadCell(), szDispName);
	return true;
}

public int MenuHandler_SelectDay(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			g_mMainMenu.Display(param1, MENU_TIME_FOREVER);
		}
		
		case MenuAction_Select:
		{	
			int iMode = g_iMode[param1];
			bool bRedisplay = true;
			if (iMode == MODE_START && DaysAPI_IsDayRunning())
			{
				CPrintToChat(param1, "\x04* A day is already running");
			}
			
			else if (iMode == MODE_PLAN && DaysAPI_IsDayPlanned())
			{
				CPrintToChat(param1, "\x04* A day is already planned");
			}
			
			else
			{
				char szDisplayName[MAX_DISPLAY_NAME_LENGTH];
				char szInternalName[MAX_INTERNAL_NAME_LENGTH];
				menu.GetItem(param2, szInternalName, sizeof szInternalName);
				
				switch(iMode)
				{
					case MODE_START:
					{
						if(g_bVoteInProgress && g_iVoteMode == MODE_START)
						{
							CPrintToChat(param1, "\x04* Cannot start day as there is a vote currently running.");
						}
						
						else
						{
							DaysAPI_GetDayInfo(szInternalName, DayInfo_DisplayName, szDisplayName, sizeof szDisplayName);
							if(DaysAPI_StartDay(szInternalName) == DSS_Success)
							{
								bRedisplay = false;
								CPrintToChat(param1, "\x04* You have started day: \x03%s", szDisplayName);
							}
							
							else
							{
								CPrintToChat(param1, "\x04* Could not start day: \x03%s", szDisplayName);
							}
						}
					}
					
					case MODE_PLAN:
					{
						if(g_bVoteInProgress && g_iVoteMode == MODE_PLAN)
						{
							CPrintToChat(param1, "\x04* Cannot plan day as there is a vote currently running.");
						}
						
						else
						{
							DaysAPI_AddPlannedDay(szInternalName);
							DaysAPI_GetDayInfo(szInternalName, DayInfo_DisplayName, szDisplayName, sizeof szDisplayName);
							CPrintToChat(param1, "\x04* You have planned day \x03'%s' \x04for next round.", szDisplayName);
						}
					}
				}
			}
			
			if(bRedisplay)
			{
				g_mMainMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
	}
}

void StartVote(int iMode)
{
	ResetVoteValues();
	
	g_mVoteMenu = new Menu(MenuHandler_VoteMenu, MENU_ACTIONS_ALL);
	{
		g_mVoteMenu.SetTitle("Select a Day:");
		
		g_flVoteStartTime = GetGameTime();
		g_flVoteEndTime = g_flVoteStartTime + g_flVoteTime;
		
		// Vote-Storing array.
		g_Array_Votes = new ArrayList(1);
		g_iTotalVotes = 0;
		
		g_iVoteMode = iMode;
		
		g_Array_Names = new ArrayList(MAX_INTERNAL_NAME_LENGTH);
		g_Array_DisplayNames = new ArrayList(MAX_DISPLAY_NAME_LENGTH);
		
		DataPack dp = new DataPack();
		dp.WriteCell(g_Array_Names);
		dp.WriteCell(g_Array_DisplayNames);
		int iSize = DaysAPI_GetDays(GetDaysCallbackWithDisplayNames, false, dp);
		
		char szDayDisplayName[MENU_MAX_ITEM_NAME];
		char szInfo[MAX_INFO_SIZE];
		
		for (int i; i < iSize; i++)
		{
			IntToString(i, szInfo, sizeof szInfo);
			g_Array_DisplayNames.GetString(i, szDayDisplayName, sizeof szDayDisplayName);
			g_Array_Votes.Push(0);
			
			g_mVoteMenu.AddItem(szInfo, szDayDisplayName);
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		g_mVoteMenu.Display(i, RoundFloat(g_flVoteTime));
	}
	
	CPrintToChatAll("\x03Voting for the next Event Day has started!");
	CreateTimer(g_flVoteTime, Timer_EndVote, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	g_hTimer_UpdateMenu = CreateTimer(g_flMenuUpdateFreq, Timer_UpdateMenu, INVALID_HANDLE, TIMER_REPEAT);
	
	g_bVoteInProgress = true;
}

public Action Timer_EndVote(Handle hTimer)
{
	int iSize = g_Array_Votes.Length;
	
	int iHighestVotes = 0;
	int[] iTies = new int[iSize];
	int iTiesCount = 0;
	int iVotes;
	for (int i; i < iSize; i++)
	{
		if ((iVotes = g_Array_Votes.Get(i)) > iHighestVotes)
		{
			iHighestVotes = iVotes;
			iTiesCount = 1;
			iTies[0] = i;
		}
		
		else if (iVotes && iVotes == iHighestVotes)
		{
			iTies[++iTiesCount] = i;
		}
	}
	
	if (!iTiesCount)
	{
		CPrintToChatAll("\x03Voting suspended as no one voted!");
	}
	
	else
	{
		int iWinningDay = iTies[GetRandomInt(0, iTiesCount - 1)];
		
		char szWinnerName[MENU_MAX_ITEM_NAME];
		g_Array_DisplayNames.GetString(iWinningDay, szWinnerName, sizeof szWinnerName);
		CPrintToChatAll("\x03Voting for the next Event Day has ended! The winner is: \x07%s \x04(%d/%d votes)", szWinnerName, iHighestVotes, g_iTotalVotes);
		
		g_Array_Names.GetString(iWinningDay, szWinnerName, sizeof szWinnerName);
		
		switch(g_iVoteMode)
		{
			case MODE_PLAN:
			{
				if(!DaysAPI_IsDayPlanned())
				{
					DaysAPI_AddPlannedDay(szWinnerName);
				}
			}
			
			case MODE_START:
			{
				if(!DaysAPI_IsDayRunning())
				{
					DaysAPI_StartDay(szWinnerName);
				}
			}
		}
	}
	
	ResetVoteValues();
}

public Action Timer_UpdateMenu(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (g_bHasPlayerExitedMenu[i])
		{
			continue;
		}
		
		g_mVoteMenu.Display(i, RoundFloat(g_flVoteEndTime - GetGameTime()));
	}
}

void SetArrayValue(any[] array, int size, any value, int start = 0)
{
	for (int i = start; i < size; i++)
	{
		array[i] = value;
	}
}

public int MenuHandler_VoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		return 0;
	}
	
	if (action == MenuAction_Cancel)
	{
		g_bHasPlayerExitedMenu[param1] = true;
		if (param2 == MenuCancel_Disconnected || param2 == MenuCancel_Timeout || param2 == MenuCancel_NoDisplay || param2 == MenuCancel_Exit)
		{
			g_bHasPlayerExitedMenu[param1] = true;
			return 0;
		}
		
		if (g_iPlayerVoteChoice[param1] == -1)
		{
			menu.Display(param1, RoundFloat(g_flVoteEndTime - GetGameTime()));
		}
		
		return 0;
	}
	
	if (action == MenuAction_DisplayItem)
	{
		char szFmt[MENU_MAX_ITEM_NAME];
		char szInfo[MAX_INFO_SIZE];
		
		menu.GetItem(param2, szInfo, sizeof szInfo);
		int iIndex = StringToInt(szInfo);
		g_Array_DisplayNames.GetString(iIndex, szFmt, sizeof szFmt);
		if (g_iPlayerVoteChoice[param1] == -1)
		{
			return RedrawMenuItem(szFmt);
		}
		
		else
		{
			Format(szFmt, sizeof szFmt, "%s (%0.1f%%)", szFmt, 100.0 * (float(g_Array_Votes.Get(iIndex)) / float(g_iTotalVotes)));
			return RedrawMenuItem(szFmt);
		}
	}
	
	if (action == MenuAction_DrawItem)
	{
		if (g_iPlayerVoteChoice[param1] == -1)
		{
			return ITEMDRAW_DEFAULT;
		}
		
		return ITEMDRAW_DISABLED;
	}
	
	if (action == MenuAction_Select)
	{
		char szFmt[MENU_MAX_ITEM_NAME];
		char szInfo[MAX_INFO_SIZE];
		menu.GetItem(param2, szInfo, sizeof szInfo, _, szFmt, sizeof szFmt);
		
		int iIndex = StringToInt(szInfo);
		
		g_iPlayerVoteChoice[param1] = iIndex;
		g_Array_Votes.Set(iIndex, g_Array_Votes.Get(iIndex) + 1);
		++g_iTotalVotes;
		
		CPrintToChatAll("\x05%N \x01chose\x03 %s", param1, szFmt);
		
		menu.Display(param1, RoundFloat(g_flVoteEndTime - GetGameTime()));
		return 0;
	}
	
	return 0;
} 

bool HasAccess(int client, bool bAllowSimon)
{
	if(g_bSimonAPI)
	{
		if(SimonAPI_HasAccess(client, bAllowSimon))
		{
			return true;
		}
		
		return false;
	}
	
	if(GetUserFlagBits(client) & (ADMFLAG_ROOT | ADMFLAG_BAN))
	{
		return true;
	}
	
	return false;
}