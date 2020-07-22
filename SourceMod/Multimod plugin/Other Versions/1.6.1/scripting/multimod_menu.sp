#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <multimod>

public Plugin myinfo = 
{
	name = "Multimod Plugin: Menu",
	author = "Khalid",
	description = "Adds multimod menu to the multimod plugin.",
	version = MM_VERSION_STR,
	url = ""
};

new AdminFlag:ACCESS_FLAG;

new Handle:g_hMultiModMainMenu;
new Handle:g_hMultiModNextModMenu;
new Handle:g_hMultiModBlockMenu;

new g_iModsCount;

new g_iCurrentModId;

new bool:g_bVotingStarted;
new bool:g_bVotingPlugin = false;

new bool:g_bLateLoad;

new const String:g_szMM_MenuInfo[4][] = {
	"BLOCK",
	"NEXT",
	"CANCEL",
	"START"
};

// keep in order
enum
{
	MM_BLOCK,
	MM_NEXT,
	MM_CANCEL,
	MM_STARTVOTE
};

public APLRes:AskPluginLoad2(Handle:hHandle, bool:bLate, String:szError[], iErrLen)
{
	g_bLateLoad = bLate;

	return APLRes_Success;
}

public OnLibraryRemoved(const String:szLibName[])
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		g_bVotingPlugin = false;
	}
}
 
public OnLibraryAdded(const String:szLibName[])
{
	if (StrEqual(szLibName, MM_LIB_VOTE))
	{
		g_bVotingPlugin = true;
	}
}

public OnPluginStart()
{
	BitToFlag(MM_ACCESS_FLAG_BIT, ACCESS_FLAG);
	
	AddCommandListener(Cmd_Say, "say");
	AddCommandListener(Cmd_Say, "say_team");
	
	if(g_bLateLoad)
	{
		if(MultiMod_IsLoaded())
		{
			//g_iCurrentModId = MultiMod_GetCurrentModId();
			//BuildMultiModMenu();
			MultiMod_Loaded(MultiModLoad_Loaded);
		}
	}
	
	// Check whether the plugin was loaded during map change, it is not considered a late load
	else if(MultiMod_IsLoaded())
	{
		//g_iCurrentModId = MultiMod_GetCurrentModId();
		//BuildMultiModMenu();
		MultiMod_Loaded(MultiModLoad_Loaded);
	}
}

public OnMapStart()
{
	if(MultiMod_IsLoaded())
	{
		g_iCurrentModId = MultiMod_GetCurrentModId();
	}
	
	g_bVotingStarted = false;
}

public MultiMod_Loaded(MultiModLoad:iLoad)
{
	if(iLoad == MultiModLoad_Reload)
	{
		CloseHandle(g_hMultiModMainMenu);
		CloseHandle(g_hMultiModNextModMenu);
		CloseHandle(g_hMultiModBlockMenu);
	}
	
	g_iModsCount = MultiMod_GetModsCount();
	g_iCurrentModId = MultiMod_GetCurrentModId();
	
	BuildMultiModMenu();	
}

public Action:Cmd_Say(client, const String:szCommand[], iArgCount)
{
	static String:szMMCmd[20];
	GetCmdArgString(szMMCmd, sizeof szMMCmd);
	StripQuotes(szMMCmd);
	
	if(StrEqual(szMMCmd[1], "mm_menu", false))
	{
		DisplayMultiModMenu(client);
	}
	
	return Plugin_Continue;
}

CancelNextMod()
{
	MultiMod_SetNextMod(MM_NEXTMOD_CANCEL);
}

public MultiMod_VotingStarted(MultiModVote:iStartingVote, bool:bInstantChange)
{
	g_bVotingStarted = true;
}

DisplayMultiModMenu(client)
{
	//PrintToChat(client, "Success %d", iAccess);
	DisplayMenu(g_hMultiModMainMenu, client, MENU_TIME_FOREVER);
}

BuildMultiModMenu()
{
	g_hMultiModMainMenu = CreateMenu(MultiMod_Main_MenuHandler, MENU_ACTIONS_ALL);
	SetMenuTitle(g_hMultiModMainMenu, "MultiMod Menu:    - By Khalid");
	
	// Keep in order
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_BLOCK], "Block a MOD", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_NEXT], "Choose Next Mod", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_CANCEL], "Cancel Next Mod", ITEMDRAW_DEFAULT);
	AddMenuItem(g_hMultiModMainMenu, g_szMM_MenuInfo[MM_STARTVOTE], "Start Mod Vote", ITEMDRAW_DEFAULT);
	
	g_hMultiModBlockMenu = CreateMenu(MultiModMenu_Block_Handler, MENU_ACTIONS_ALL);
	g_hMultiModNextModMenu = CreateMenu(MultiModMenu_NextMod_Handler, MENU_ACTIONS_ALL);
	AddMenusItems();
}

AddMenusItems()
{
	new String:szInfo[5]; //,String:szModName[MAX_MOD_NAME], String:szMenuItemName[MAX_MOD_NAME + 15];
	for (new i; i < g_iModsCount; i++)
	{
		//GetArrayString(gModsArrays[MP_NAME], i, szModName, sizeof szModName);
		IntToString(i, szInfo, sizeof szInfo);
		//FormatEx(szMenuItemName, sizeof szMenuItemName, "%s [Not Blocked]", szModName);
		//AddMenuItem(g_hMultiModBlockMenu, szInfo, szMenuItemName, ITEMDRAW_DEFAULT);
		//AddMenuItem(g_hMultiModNextModMenu, szInfo, szModName, ITEMDRAW_DEFAULT);
		AddMenuItem(g_hMultiModBlockMenu, szInfo, "", ITEMDRAW_DEFAULT);	// Display Name altered later in handler
		AddMenuItem(g_hMultiModNextModMenu, szInfo, "", ITEMDRAW_DEFAULT);
	}
}

public MultiMod_Main_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	static String:szInfo[10];
	switch(action)
	{
		case MenuAction_DisplayItem:
		{
			// param1 = client, param2 =  item number for use with GetMenuItem 
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			if (StrEqual(szInfo, g_szMM_MenuInfo[MM_NEXT], true))
			{
				static iNextModId;
				static String:szItemTitle[MAX_MOD_NAME + 30];
				
				iNextModId = MultiMod_GetNextModId();
				
				if(iNextModId == -1)
				{
					FormatEx(szItemTitle, sizeof szItemTitle, "Choose Next Mod (Current: Not chosen yet)");
				}
				
				else
				{
					static String:szNextModName[MAX_MOD_NAME];
					MultiMod_GetModProp(iNextModId, MultiModProp_Name, szNextModName, sizeof szNextModName);
					FormatEx(szItemTitle, sizeof szItemTitle, "Choose Next Mod (Current: %s)", szNextModName);
				}
				 
				return RedrawMenuItem(szItemTitle);
			}
			
			if(StrEqual(szInfo, g_szMM_MenuInfo[MM_STARTVOTE], true))
			{
				if(!g_bVotingPlugin)
				{
					new String:szItem[50];
					FormatEx(szItem, sizeof szItem, "Start Mod Vote (Disabled: Voting is not loaded)");
					return RedrawMenuItem(szItem);
				}
			}
		}
		
		case MenuAction_DrawItem:
		{
			// param1: client index
			// param2: item number for use with GetMenuItem
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			if(StrEqual(szInfo, g_szMM_MenuInfo[MM_CANCEL]))
			{
				if(MultiMod_GetNextModId() == -1)
				{
					return ITEMDRAW_DISABLED;
				}
				
				else
				{
					static AdminId:iAdminId;
					iAdminId = GetUserAdmin(param1);
		
					if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
					{
						return ITEMDRAW_DISABLED;
					}
					
					return ITEMDRAW_DEFAULT;
				}
					
			}
			
			if (StrEqual(szInfo, g_szMM_MenuInfo[MM_STARTVOTE]))
			{
				if(!g_bVotingPlugin)
				{
					return ITEMDRAW_DISABLED;
				}
				
				static AdminId:iAdminId;
				iAdminId = GetUserAdmin(param1);
		
				if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
				{
					return ITEMDRAW_DISABLED;
				}
				
				return ITEMDRAW_DEFAULT;
			}
		}
		
		case MenuAction_End: {  }
		case MenuAction_Select:
		{
			switch(param2)
			{
				case MM_BLOCK:
				{
					DisplayMenu(g_hMultiModBlockMenu, param1, MENU_TIME_FOREVER);
				}
				
				case MM_NEXT:
				{
					DisplayMenu(g_hMultiModNextModMenu, param1, MENU_TIME_FOREVER);
				}
				
				case MM_CANCEL: 
				{
					CancelNextMod();
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
					
					static String:szAdminName[MAX_NAME_LENGTH];
					GetClientName(param1, szAdminName, sizeof szAdminName);
			
					MM_PrintToChat(0, "ADMIN \x04%s \x01canceled the next chosen MOD.", szAdminName);
				}
				case MM_STARTVOTE:
				{
					if(g_bVotingStarted)
					{
						MM_PrintToChat(param1, "The vote has already started!");
					}
					
					else
					{
						// Keep like this at the moment
						new bool:bStarted = MultiMod_StartVote();
						
						if(bStarted)
						{
							g_bVotingStarted = true;
							
							new String:szAdminName[MAX_NAME_LENGTH];
							GetClientName(param1, szAdminName, sizeof szAdminName);
							MM_PrintToChat(0, "ADMIN \x04%s\x01: Start the MOD vote.", szAdminName);
						}
						
						else
						{
							MM_PrintToChat(param1, "The vote has already started!");
						}
					}
				}
			}
		}
	}
	
	return 0;
}

public MultiModMenu_Block_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			static AdminId:iAdminId;
			iAdminId = GetUserAdmin(param1);
		
			if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
			{
				return ITEMDRAW_DISABLED;
			}
			
			#if defined BLOCK_CURRENT_MOD_IN_VOTE
			if(param2 == g_iCurrentModId)
			{
				return ITEMDRAW_DISABLED;
			}
			#endif
			
			#if defined BLOCK_CURRENT_MOD_IN_VOTE
			if(MultiMod_GetLockedModsCount() + 2 >= g_iModsCount)
			#else
			if(MultiMod_GetLockedModsCount() + 1 >= g_iModsCount)
			#endif
			{
				if( MultiMod_GetModLock(param2) == MultiModLock_NotLocked ) // not blocked
				{
					return ITEMDRAW_DISABLED;		// Do not allow blocking of last mod.
				}
			}
			
			return ITEMDRAW_DEFAULT;
		}
				
		case MenuAction_DisplayItem:
		{
			static String:szItemDisplayName[MAX_MOD_NAME + 35], String:szModName[MAX_MOD_NAME], String:szBlockStatus[35];
			static MultiModLock:iBlockStatus;
			
			MultiMod_GetModProp(param2, MultiModProp_Name, szModName, sizeof szModName);
			iBlockStatus = MultiMod_GetModLock(param2);
			
			szBlockStatus[0] = 0;
#if defined BLOCK_CURRENT_MOD_IN_VOTE
			if(param2 == g_iCurrentModId)
			{
				szBlockStatus = "[Blocked (Current Mod)]";
			}
			
			// keep this before #endif
			if(!szBlockStatus[0])
#endif
			{
				switch(iBlockStatus)
				{
					case MultiModLock_Locked:		szBlockStatus = "[Blocked]";
					case MultiModLock_Locked_Save:	szBlockStatus = "[Blocked & Saved]";
					case MultiModLock_NotLocked:	szBlockStatus = "[Not Blocked]";
				}
			}
			
			FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s %s", szModName, szBlockStatus);

			return RedrawMenuItem(szItemDisplayName);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Exit)
			{
				DisplayMenu(g_hMultiModMainMenu, param1, MENU_TIME_FOREVER);
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
			if(g_bVotingStarted)
			{
				MM_PrintToChat(param1, "You cannot block any MODs as the vote has started.");
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				return 0;
			}
			
			static MultiModLock:iBlockStatus;
			iBlockStatus = MultiMod_GetModLock(param2);
			switch(iBlockStatus)
			{
				case MultiModLock_NotLocked:
				{
					iBlockStatus = MultiModLock_Locked;
				}
				
				case MultiModLock_Locked:
				{
					iBlockStatus = MultiModLock_Locked_Save;
				}
				
				case MultiModLock_Locked_Save:
				{
					iBlockStatus = MultiModLock_NotLocked;
				}
			}
			
			MultiMod_SetModLock(param2, iBlockStatus);
			
			static String:szAdminName[MAX_NAME_LENGTH], String:szModName[MAX_MOD_NAME];
			MultiMod_GetModProp( param2, MultiModProp_Name, szModName, sizeof szModName);
			GetClientName(param1, szAdminName, sizeof szAdminName);
			
			MM_PrintToChat(0, "ADMIN \x04%s \x06%s \x01the MOD \x04%s.", szAdminName, ( iBlockStatus == MultiModLock_Locked || iBlockStatus == MultiModLock_Locked_Save ) ? "BLOCKED" : "UNBLOCKED", szModName);
			
			//g_iBlockedModsCount += (iBlockStatus ? 1 : -1);
			
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			//CancelClientMenu(
		}
	}
	
	return 0;
}

public MultiModMenu_NextMod_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			if(g_bVotingStarted)
			{
				return ITEMDRAW_DISABLED;
			}
			
			static AdminId:iAdminId;
			iAdminId = GetUserAdmin(param1);
		
			if(iAdminId == INVALID_ADMIN_ID || !GetAdminFlag(iAdminId, ACCESS_FLAG))
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_DisplayItem:
		{
			static String:szItemDisplayName[MAX_MOD_NAME + 20], String:szModName[MAX_MOD_NAME];
			//GetArrayString(gModsArrays[MP_NAME], param2, szModName, sizeof szModName);
			MultiMod_GetModProp(param2, MultiModProp_Name, szModName, sizeof szModName);
			
			if(MultiMod_GetNextModId() == param2)
			{
				//GetMenuItem(menu, param2, szInfo, sizeof szInfo
				FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s (Chosen as next mod)", szModName);
			}
			
			else
			{
				FormatEx(szItemDisplayName, sizeof szItemDisplayName, "%s", szModName);
			}
			
			return RedrawMenuItem(szItemDisplayName);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Exit)
			{
				DisplayMenu(g_hMultiModMainMenu, param1, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_End: {   }
		case MenuAction_Select:
		{
			if(g_bVotingStarted)
			{
				MM_PrintToChat(param1, "You cannot select the next MOD as the vote has started.");
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				return 0;
			}
				
			static String:szAdminName[MAX_NAME_LENGTH], String:szModName[MAX_MOD_NAME];
			//GetArrayString(gModsArrays[MP_NAME], param2, szModName, sizeof szModName);
			MultiMod_GetModProp(param2, MultiModProp_Name, szModName, sizeof szModName);
			
			GetClientName(param1, szAdminName, sizeof szAdminName);
			
			MM_PrintToChat(0, "ADMIN \x04%s \x01chose MOD \x04%s as the next MOD.", szAdminName, szModName);
			
			MultiMod_SetNextMod(param2);
			
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}