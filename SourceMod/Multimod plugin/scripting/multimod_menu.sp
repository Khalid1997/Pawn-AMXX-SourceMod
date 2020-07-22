#pragma semicolon 1

#include <sourcemod>
#include <multimod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Multimod Plugin: Menu", 
	author = "Khalid", 
	description = "Adds multimod menu to the multimod plugin.", 
	version = MM_VERSION_STR, 
	url = ""
};

bool g_bLate;

Menu g_hMultiModMenu_Main;
Menu g_hMultiModMenu_NextMod;
Menu g_hMultiModMenu_Block;
Menu g_hMultiModMenu_StartVote;

int g_iModsCount;

bool g_bVotingPlugin = false;

bool g_bForceChange = true;

#define MAX_MENU_ITEM_NAME_LENGTH	50
#define MAX_MENU_ITEM_INFO_LENGTH	25

// keep in order
enum
{
	MainMenuItem_BlockMenu, 
	MainMenuItem_NextModMenu, 
	MainMenuItem_StartVoteMenu,
	MainMenuItem_CancelNextMod,
	MainMenuItem_CancelVote,
	MainMenuItem_Count
};

char g_szMainMenuItemsInfo[MainMenuItem_Count][] =  {
	"BLOCK", 
	"NEXT", 
	"START",
	"CANCELNEXTMOD",
	"CANCELVOTE"
};

enum 
{
	VoteMenuItem_Force,
	VoteMenuItem_NormalVote,
	VoteMenuItem_ModVote,
	VoteMenuItem_MapVote,
	VoteMenuItem_Count
};

char g_szVoteMenuItemsInfo[VoteMenuItem_Count][] = {
	"FORCE",
	"NORMALVOTE",
	"MODVOTE",
	"MAPVOTE"
};

char MAINMENUITEM_CHOOSENEXTMOD[] = "Next Mod";
char MAINMENUITEM_STARTVOTEMENU[] = "Start Vote";
char MAINMENUITEM_CANCELVOTE[] = "Cancel On-going Vote";

public APLRes AskPluginLoad2(Handle hHandle, bool bLate, char[] szError, int iErrLen)
{
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnLibraryRemoved(const char[] szLibName)
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		g_bVotingPlugin = false;
	}
}

public void OnLibraryAdded(const char[] szLibName)
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		g_bVotingPlugin = true;
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_mm_menu", CmdDisplayMultiModMenu);
	RegConsoleCmd("sm_mm", CmdDisplayMultiModMenu);
	
	if (g_bLate && MultiMod_IsLoaded())
	{
		MultiMod_OnLoaded(false);
	}
}

public void MultiMod_OnLoaded(bool bReload)
{
	if (bReload)
	{
		delete g_hMultiModMenu_Main;
		delete g_hMultiModMenu_NextMod;
		delete g_hMultiModMenu_Block;
		delete g_hMultiModMenu_StartVote;
	}
	
	g_iModsCount = MultiMod_GetModsCount();
	
	BuildMultiModMenu();
}

public Action CmdDisplayMultiModMenu(int client, int iArgs)
{
	DisplayMultiModMenu(client);
	return Plugin_Continue; // Or Handled?
}

void CancelNextMod()
{
	MultiMod_SetNextMod(ModIndex_Null);
}

void DisplayMultiModMenu(int client)
{
	//PrintToChat(client, "Success %d", iAccess);
	DisplayMenu(g_hMultiModMenu_Main, client, MENU_TIME_FOREVER);
}

void BuildMultiModMenu()
{
	g_hMultiModMenu_Main = CreateMenu(MultiMod_Main_MenuHandler, MENU_ACTIONS_ALL);
	SetMenuTitle(g_hMultiModMenu_Main, "MultiMod Menu: [By: Khalid]");
	
	// Keep in order
	AddMenuItem(g_hMultiModMenu_Main, g_szMainMenuItemsInfo[MainMenuItem_BlockMenu], "Block Mod Menu", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMenu_Main, g_szMainMenuItemsInfo[MainMenuItem_NextModMenu], "Choose Next Mod Menu", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMenu_Main, g_szMainMenuItemsInfo[MainMenuItem_StartVoteMenu], "Start Vote Menu", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMenu_Main, g_szMainMenuItemsInfo[MainMenuItem_CancelNextMod], "Cancel Next Mod", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMenu_Main, g_szMainMenuItemsInfo[MainMenuItem_CancelVote], "Cancel On-going Vote Results", ITEMDRAW_DEFAULT);
	
	g_hMultiModMenu_Block = CreateMenu( MultiModMenu_Block_Handler, MENU_ACTIONS_ALL);
	SetMenuTitle(g_hMultiModMenu_Block, "MultiMod Block Menu");
	
	g_hMultiModMenu_NextMod = CreateMenu(MultiModMenu_NextMod_Handler, MENU_ACTIONS_ALL);
	SetMenuTitle(g_hMultiModMenu_NextMod, "MultiMod NextMod Menu");
	
	g_hMultiModMenu_StartVote = CreateMenu(MultiModMenu_Vote_MenuHandler, MENU_ACTIONS_ALL);
	SetMenuTitle(g_hMultiModMenu_StartVote, "MultiMod Vote Menu");
	AddMenuItem(g_hMultiModMenu_StartVote, g_szVoteMenuItemsInfo[VoteMenuItem_Force], "", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMenu_StartVote, g_szVoteMenuItemsInfo[VoteMenuItem_NormalVote], "Start Normal Vote (Respects NextMod)", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMenu_StartVote, g_szVoteMenuItemsInfo[VoteMenuItem_ModVote], "Start Mod Vote", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMenu_StartVote, g_szVoteMenuItemsInfo[VoteMenuItem_MapVote], "Start Map Only Vote (Respects NextMod)", ITEMDRAW_DEFAULT);
	
	AddMenusItems();
}

void AddMenusItems()
{
	char szInfo[MAX_MENU_ITEM_INFO_LENGTH];
	for (int iModIndex; iModIndex < g_iModsCount; iModIndex++)
	{
		IntToString(iModIndex, szInfo, sizeof szInfo);
		
		AddMenuItem(g_hMultiModMenu_Block, szInfo, "", ITEMDRAW_DEFAULT); // Display Name altered later in handler
		AddMenuItem(g_hMultiModMenu_NextMod, szInfo, "", ITEMDRAW_DEFAULT);
	}
}

public int MultiMod_Main_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	char szInfo[25];
	switch(action)
	{
		case MenuAction_DisplayItem:
		{
			// param1 = client, param2 =  item number for use with GetMenuItem 
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			if (StrEqual(szInfo, g_szMainMenuItemsInfo[MainMenuItem_NextModMenu]))
			{
				int iNextModId;
				char szItemTitle[MAX_MENU_ITEM_NAME_LENGTH];
				
				iNextModId = MultiMod_GetNextModId();
				
				if (iNextModId == ModIndex_Null)
				{
					FormatEx(szItemTitle, sizeof szItemTitle, "%s (Chosen: None)", MAINMENUITEM_CHOOSENEXTMOD);
				}
				
				else
				{
					char szNextModName[MM_MAX_MOD_PROP_LENGTH];
					MultiMod_GetModProp(iNextModId, MultiModProp_Name, szNextModName, sizeof szNextModName);
					FormatEx(szItemTitle, sizeof szItemTitle, "%s (Chosen: %s)", MAINMENUITEM_CHOOSENEXTMOD, szNextModName);
				}
				
				return RedrawMenuItem(szItemTitle);
			}
			
			if (StrEqual(szInfo, g_szMainMenuItemsInfo[MainMenuItem_StartVoteMenu], true))
			{
				char szItem[MAX_MENU_ITEM_NAME_LENGTH];
				if (!g_bVotingPlugin)
				{
					FormatEx(szItem, sizeof szItem, "%s [Disabled: Voting is not loaded]", MAINMENUITEM_STARTVOTEMENU);
					return RedrawMenuItem(szItem);
				}
				
				else
				{
					FormatEx(szItem, sizeof szItem, "%s", MAINMENUITEM_STARTVOTEMENU);
					return RedrawMenuItem(szItem);
				}
			}
			
			else if (StrEqual(szInfo, g_szMainMenuItemsInfo[MainMenuItem_CancelVote], true))
			{
				char szItem[MAX_MENU_ITEM_NAME_LENGTH];
				MultiModVoteStatus iStatus = MultiMod_Vote_GetVoteStatus();
				
				if (iStatus == MultiModVoteStatus_Running)
				{
					FormatEx(szItem, sizeof szItem, "%s [Vote Status: Running]", MAINMENUITEM_CANCELVOTE);
					return RedrawMenuItem(szItem);
				}
				
				else if (iStatus == MultiModVoteStatus_Done)
				{
					FormatEx(szItem, sizeof szItem, "%s [Vote Status: Finished Voting]", MAINMENUITEM_CANCELVOTE);
					return RedrawMenuItem(szItem);
				}
				
				else if (iStatus == MultiModVoteStatus_NoVote)
				{
					FormatEx(szItem, sizeof szItem, "%s [No Vote Running]", MAINMENUITEM_CANCELVOTE);
					return RedrawMenuItem(szItem);
				}
			}
			
			return 0;
		}
		
		case MenuAction_DrawItem:
		{
			// param1: client index
			// param2: item number for use with GetMenuItem
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			//bool bAdmin = ClientHasFlag(param1, MM_MENU_ACCESS_FLAG_BIT);
			
			if (StrEqual(szInfo, g_szMainMenuItemsInfo[MainMenuItem_StartVoteMenu]))
			{
				if (!g_bVotingPlugin || MultiMod_Vote_GetVoteStatus() == MultiModVoteStatus_Running)
				{
					return ITEMDRAW_DISABLED;
				}
			}
			
			else if (StrEqual(szInfo, g_szMainMenuItemsInfo[MainMenuItem_CancelNextMod]))
			{
				if (!ClientHasFlag(param1, MM_ACCESS_FLAG_NEXTMOD_BIT))
				{
					return ITEMDRAW_DISABLED;
				}
				
				if (MultiMod_GetNextModId() == ModIndex_Null)
				{
					return ITEMDRAW_DISABLED;
				}
			}
			
			else if (StrEqual(szInfo, g_szMainMenuItemsInfo[MainMenuItem_CancelVote]))
			{
				if (!ClientHasFlag(param1, MM_ACCESS_FLAG_NEXTMOD_BIT))
				{
					return ITEMDRAW_DISABLED;
				}
				
				MultiModVoteStatus iStatus = MultiMod_Vote_GetVoteStatus();
				
				if (iStatus == MultiModVoteStatus_Running || iStatus == MultiModVoteStatus_Done)
				{
					return ITEMDRAW_DEFAULT;
				}
				
				else if (iStatus == MultiModVoteStatus_NoVote)
				{
					return ITEMDRAW_DISABLED;
				}
			}
			
			// Enable other items even for other people.
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_End: {  }
		case MenuAction_Select:
		{
			int iIndex = GetMainMenuItemIndexFromParam(menu, param2);
			switch (iIndex)
			{
				case MainMenuItem_BlockMenu:
				{
					DisplayMenu(g_hMultiModMenu_Block, param1, MENU_TIME_FOREVER);
				}
				
				case MainMenuItem_NextModMenu:
				{
					DisplayMenu(g_hMultiModMenu_NextMod, param1, MENU_TIME_FOREVER);
				}

				case MainMenuItem_StartVoteMenu:
				{
					if (MultiMod_Vote_GetVoteStatus() != MultiModVoteStatus_NoVote)
					{
						MultiMod_PrintToChat(param1, "The vote has already started!");
					}
					
					else
					{
						DisplayMenu(g_hMultiModMenu_StartVote, param1, MENU_TIME_FOREVER);
					}
				}
				
				case MainMenuItem_CancelNextMod:
				{
					if(MultiMod_GetNextModId() == ModIndex_Null)
					{
						return 0;
					}
					
					MultiMod_SetNextMod(ModIndex_Null);
					
					menu.Display(param1, MENU_TIME_FOREVER);
				}
				
				case MainMenuItem_CancelVote:
				{
					if(MultiMod_Vote_CancelOngoingVote())
					{
						MultiMod_PrintToChatAll("ADMIN \x03%N \x01Canceled the on-going vote!", param1);
					}
					
					menu.Display(param1, MENU_TIME_FOREVER);
				}
			}
		}
	}
	
	return 0;
}

int GetMainMenuItemIndexFromParam(Menu menu, int itemparam)
{
	char szInfo[MAX_MENU_ITEM_INFO_LENGTH];
	GetMenuItem(menu, itemparam, szInfo, sizeof szInfo);
	
	int iIndex = 0;
	for (iIndex = 0; iIndex < MainMenuItem_Count; iIndex++)
	{
		if(StrEqual(g_szMainMenuItemsInfo[iIndex], szInfo))
		{
			return iIndex;
		}
	}
	
	return -1;
}

public int MultiModMenu_Block_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			bool bAdmin = ClientHasFlag(param1, MM_MENU_ACCESS_FLAG_BIT);
			
			if (!bAdmin)
			{
				return ITEMDRAW_DISABLED;
			}
			
			if (!MultiMod_CanLockMod())
			{
				if (MultiMod_GetModLock(param2) == MultiModLock_NotLocked) // not blocked
				{
					return ITEMDRAW_DISABLED; // Do not allow blocking of last mod.
				}
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_DisplayItem:
		{
			int iModIndex;
			char szInfo[MAX_MENU_ITEM_INFO_LENGTH];
			char szItemDisplayName[MAX_MENU_ITEM_NAME_LENGTH + 30], 
				szModName[MM_MAX_MOD_PROP_LENGTH], 
				szBlockStatus[25];
			MultiModLock iBlockStatus;
			
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iModIndex = StringToInt(szInfo);
			MultiMod_GetModProp(iModIndex, MultiModProp_Name, szModName, sizeof szModName);
			iBlockStatus = MultiMod_GetModLock(iModIndex);
			
			int iCurrentModIndex = MultiMod_GetCurrentModId();
			
			switch (iBlockStatus)
			{	
				case MultiModLock_Locked:		szBlockStatus = "[Blocked]";
				case MultiModLock_Locked_Save:	szBlockStatus = "[Blocked & Saved]";
				case MultiModLock_NotLocked:	szBlockStatus = "[Not Blocked]";
			}
			
			// ModName [BlockStatus] [CurrentMod]
			FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s %s %s", 
			szModName, szBlockStatus, iModIndex == iCurrentModIndex ? "(Current Mod)" : "");
			return RedrawMenuItem(szItemDisplayName);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_Exit)
			{
				DisplayMenu(g_hMultiModMenu_Main, param1, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_End:
		{
			// param1: MenuEnd reason
			// param2: If param1 is MenuEnd_Cancelled, the MenuCancel reason 
			//if( MenuEnd_Cancelled
		}
		
		case MenuAction_Select:
		{	
			MultiModLock iBlockStatus;
			int iModIndex;
			char szInfo[MAX_MENU_ITEM_INFO_LENGTH],
				szBlockStatus[25];
			
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iModIndex = StringToInt(szInfo);
			
			if(MultiMod_GetNextModId() == iModIndex)
			{
				MultiMod_PrintToChat(param1, "You cannot change the Block status of the NextMod");
			}
			
			else
			{
				iBlockStatus = MultiMod_GetModLock(param2);
				
				switch (iBlockStatus)
				{
					case MultiModLock_NotLocked:
					{
						iBlockStatus = MultiModLock_Locked;
						szBlockStatus = "BLOCKED";
					}
					
					case MultiModLock_Locked:
					{
						iBlockStatus = MultiModLock_Locked_Save;
						szBlockStatus = "BLOCKED (with save)";
					}
					
					case MultiModLock_Locked_Save:
					{
						iBlockStatus = MultiModLock_NotLocked;
						szBlockStatus = "UNBLOCKED";
					}
				}
				
				MultiMod_SetModLock(iModIndex, iBlockStatus);
				
				char szModName[MM_MAX_MOD_PROP_LENGTH];
				MultiMod_GetModProp(iModIndex, MultiModProp_Name, szModName, sizeof szModName);
				
				MultiMod_PrintToChatAll("ADMIN \x04%N \x06%s \x01the MOD \x04%s.", param1, szBlockStatus, szModName);
			}
			
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

bool HasVoteStarted()
{
	return (MultiMod_Vote_GetVoteStatus() != MultiModVoteStatus_NoVote);
}

public int MultiModMenu_NextMod_Handler(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			if (HasVoteStarted())
			{
				return ITEMDRAW_DISABLED;
			}
			
			bool bAdmin = ClientHasFlag(param1, MM_MENU_ACCESS_FLAG_BIT);
			
			if (!bAdmin)
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_DisplayItem:
		{
			int iModIndex;
			char szInfo[MAX_MENU_ITEM_INFO_LENGTH];
			
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iModIndex = StringToInt(szInfo);
			
			char szItemDisplayName[MAX_MENU_ITEM_NAME_LENGTH + 50], szModName[MM_MAX_MOD_PROP_LENGTH];
			MultiMod_GetModProp(iModIndex, MultiModProp_Name, szModName, sizeof szModName);
			
			char szNextModString[15];
			char szCurrentModString[15];
			char szBlockStatus[25];
			
			if (MultiMod_GetNextModId() == iModIndex)
			{
				//GetMenuItem(menu, param2, szInfo, sizeof szInfo
				//FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s (Chosen as next mod)", szModName);
				szNextModString = "[NextMod]";
			}
			
			else
			{
				szNextModString = "";
			}
			
			if(iModIndex == MultiMod_GetCurrentModId())
			{
				szCurrentModString = "[CurrentMod]";
			}
			
			else
			{
				szCurrentModString = "";
			}
			
			switch (MultiMod_GetModLock(iModIndex))
			{	
				case MultiModLock_Locked:		szBlockStatus = "[Blocked]";
				case MultiModLock_Locked_Save:	szBlockStatus = "[Blocked & Saved]";
				case MultiModLock_NotLocked:	szBlockStatus = "[Not Blocked]";
			}
			
			FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s %s %s %s", szModName, szNextModString, szCurrentModString, szBlockStatus);
			return RedrawMenuItem(szItemDisplayName);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_Exit)
			{
				DisplayMenu(g_hMultiModMenu_Main, param1, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_End: {  }
		case MenuAction_Select:
		{
			if (HasVoteStarted())
			{
				MultiMod_PrintToChat(param1, "You cannot select the next MOD as the vote has started.");
				DisplayMenu(g_hMultiModMenu_Main, param1, MENU_TIME_FOREVER);
				return 0;
			}
			
			else
			{
				int iModIndex;
				char szInfo[MAX_MENU_ITEM_INFO_LENGTH];
				
				GetMenuItem(menu, param2, szInfo, sizeof szInfo);
				iModIndex = StringToInt(szInfo);
	
				if(MultiMod_GetModLock(iModIndex) != MultiModLock_NotLocked)
				{
					MultiMod_PrintToChat(param1, "You cannot choose a Blocked Mod as a NextMod");
				}
				
				char szModName[MM_MAX_MOD_PROP_LENGTH];
				MultiMod_GetModProp(iModIndex, MultiModProp_Name, szModName, sizeof szModName);
					
				if(MultiMod_GetNextModId() == iModIndex)
				{
					CancelNextMod();
					MultiMod_PrintToChatAll("ADMIN \x04%N canceled the chosen NextMod [Was: %s].", param1, szModName);
				}
				
				else
				{
					MultiMod_SetNextMod(iModIndex);
					MultiMod_PrintToChatAll("ADMIN \x04%N \x01chose MOD \x04%s as the next MOD.", param1, szModName);
				}
			}
				
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
} 

public int MultiModMenu_Vote_MenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_Exit)
			{
				DisplayMenu(g_hMultiModMenu_Main, param1, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_DrawItem:
		{
			if (!ClientHasFlag(param1, MM_ACCESS_FLAG_NEXTMOD_BIT))
			{
				return ITEMDRAW_DISABLED;
			}
			
			if(HasVoteStarted())
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_DisplayItem:
		{
			int iItemIndex = GetVoteMenuItemIndexFromParam(menu, param2);
			
			switch(iItemIndex)
			{
				case VoteMenuItem_Force:
				{
					char szItemName[MAX_MENU_ITEM_NAME_LENGTH];
					FormatEx(szItemName, sizeof szItemName, "Force Change After Vote: %s", g_bForceChange == true ? "Enabled" : "Disabled");
					return RedrawMenuItem(szItemName);
				}
				
				case VoteMenuItem_NormalVote:
				{
					char szItemName[MAX_MENU_ITEM_NAME_LENGTH];
					int iNextModId = MultiMod_GetNextModId();
					
					if(iNextModId == ModIndex_Null)
					{
						FormatEx(szItemName, sizeof szItemName, "Start Normal Vote: [Mod Vote]");
					}
					
					else
					{
						char szModName[MM_MAX_MOD_PROP_LENGTH];
						MultiMod_GetModProp(iNextModId, MultiModProp_Name, szModName, sizeof szModName);
						
						FormatEx(szItemName, sizeof szItemName, "Start Normal Vote: [Map Vote for: %s]", szModName);
					}
					
					return RedrawMenuItem(szItemName);
				}
				
				case VoteMenuItem_ModVote:
				{
					return 0;
				}
				
				case VoteMenuItem_MapVote:
				{
					char szItemName[MAX_MENU_ITEM_NAME_LENGTH];
					int iNextModId = MultiMod_GetNextModId();
					
					if(iNextModId == ModIndex_Null)
					{
						iNextModId = MultiMod_GetCurrentModId();
						if(iNextModId == ModIndex_Null)
						{
							FormatEx(szItemName, sizeof szItemName, "Map Vote");
							return RedrawMenuItem(szItemName);
						}
						
						char szModName[MM_MAX_MOD_PROP_LENGTH];
						MultiMod_GetModProp(iNextModId, MultiModProp_Name, szModName, sizeof szModName);
						FormatEx(szItemName, sizeof szItemName, "Map Vote: [Current Mod Maps: %s]", szModName);
						
					}
					
					else
					{
						char szModName[MM_MAX_MOD_PROP_LENGTH];
						MultiMod_GetModProp(iNextModId, MultiModProp_Name, szModName, sizeof szModName);
						
						FormatEx(szItemName, sizeof szItemName, "Start Normal Vote: [Next Mod Maps: %s]", szModName);
					}
					
					return RedrawMenuItem(szItemName);
				}
			}
			
			return 0;
		}
		
		case MenuAction_Select:
		{
			if (HasVoteStarted())
			{
				MultiMod_PrintToChat(param1, "You cannot do that as the vote already started.");
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				return 0;
			}
			
			int iItemIndex = GetVoteMenuItemIndexFromParam(menu, param2);
			
			switch(iItemIndex)
			{
				case VoteMenuItem_Force:
				{
					g_bForceChange = !g_bForceChange;
					MultiMod_PrintToChatAll("You have %s \"Force Change After Vote\"", g_bForceChange == true ? "Enabled" : "Disabled");
					
					// Redisplay
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
					return 0;
				}
				
				case VoteMenuItem_NormalVote:
				{
					MultiModVote iType = (MultiMod_GetNextModId() != ModIndex_Null ? MultiModVote_Map : MultiModVote_Normal);
					MultiMod_Vote_StartVote(iType, g_bForceChange);
					MultiMod_PrintToChatAll("ADMIN \x04%N started the \x04Vote\x01.", param1);
				}
				
				case VoteMenuItem_ModVote:
				{
					MultiMod_Vote_StartVote(MultiModVote_Normal, g_bForceChange);
					MultiMod_PrintToChatAll("ADMIN \x04%N started the \x04Mod Vote\x01.", param1);
				}
				
				case VoteMenuItem_MapVote:
				{
					MultiMod_Vote_StartVote(MultiModVote_Map, g_bForceChange);
					MultiMod_PrintToChatAll("ADMIN \x04%N started the \x04map Vote\x01.", param1);
				}
			}
			
			// Do not redisplay
		}
	}
	
	return 1;
}

int GetVoteMenuItemIndexFromParam(Handle menu, int itemparam)
{
	char szInfo[MAX_MENU_ITEM_INFO_LENGTH];
	GetMenuItem(menu, itemparam, szInfo, sizeof szInfo);
	
	int iIndex = 0;
	for (iIndex = 0; iIndex < VoteMenuItem_Count; iIndex++)
	{
		if(StrEqual(g_szVoteMenuItemsInfo[iIndex], szInfo))
		{
			return iIndex;
		}
	}
	
	return -1;
}

bool ClientHasFlag(int client, int iFlagBit)
{
	if( GetUserFlagBits(client) & ( iFlagBit | ADMFLAG_ROOT ) )
	{
		return true;
	}
	
	return false;
}