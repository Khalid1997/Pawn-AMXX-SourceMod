#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>

//#define DEBUG

public Plugin myinfo = 
{
	name = "Changelog menu",
	author = PLUGIN_AUTHOR,
	description = "Makes a menu for change logs to be viewed by the players",
	version = PLUGIN_VERSION,
	url = "none"
};

ArrayList 	ArrayMenus;
Handle		g_Cookie_ChangelogNum;
int			g_bShowMenu[MAXPLAYERS + 1];
Menu		g_Menu_Main;

int			g_iChangelogsParts;
int			g_iChangelogsNumber;

public void OnPluginStart()
{
	RegConsoleCmd("sm_changelog", ConCommand_Changelog, "Haha original");
	RegAdminCmd("sm_changelog_reload", ConCommand_Changelog_Reload, ADMFLAG_ROOT, "Haha");
	
	g_Cookie_ChangelogNum = RegClientCookie("changelog_num", "Stores changelogs that the user has viewed", CookieAccess_Private);
	
	ArrayMenus = CreateArray(1);
}

public OnClientCookiesCached(int client)
{
	char szNum[15];
	int iNum;
	
	GetClientCookie(client, g_Cookie_ChangelogNum, szNum, sizeof szNum);
	iNum = StringToInt(szNum);
	
	if(iNum != g_iChangelogsNumber && g_iChangelogsNumber)
	{
		g_bShowMenu[client] = true;
	}
}

public void OnClientDisconnect(int client)
{
	g_bShowMenu[client] = false;
}

public void OnMapStart()
{
	ReadChangelogFile(true);
}

public Action ConCommand_Changelog(int client, int iArgs)
{
	g_Menu_Main.Display(client, MENU_TIME_FOREVER);
	return;
}

public Action ConCommand_Changelog_Reload(int client, int iArgs)
{
	ReadChangelogFile(true);
	ReplyToCommand(client, "** Successfully read the changelog file. Total: %d sections (dates), %d changelogs", g_iChangelogsParts, g_iChangelogsNumber);
	
	return Plugin_Handled;
}

void ReadChangelogFile(bool bReset = false)
{
	if(bReset)
	{
		int iSize = GetArraySize(ArrayMenus);
		
		for(int i; i < iSize; i++)
		{
			delete (view_as<Menu>ArrayMenus.Get(i));
		}
		
		ArrayMenus.Clear();
		
		delete g_Menu_Main;
	}
	
	char szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFile, sizeof szFile, "configs/changelog.cfg");
	#if defined DEBUG
	PrintToServer(szFile);
	#endif
	
	if(!FileExists(szFile))
	{
		 MakeFile(szFile);
		 return;
	}
	
	g_Menu_Main = CreateMenu(MenuHandler_Main, MENU_ACTIONS_DEFAULT);
	g_Menu_Main.SetTitle("Changelog Menu - By: Khalid");
	
	KeyValues	hKv;
	char		szData[60];
	
	hKv = CreateKeyValues("Changelog");
	hKv.ImportFromFile(szFile);
	
	g_iChangelogsNumber = 0; g_iChangelogsParts = 0;

#if defined DEBUG
	hKv.GetSectionName(szData, sizeof szData);
	PrintToServer(szData);
#endif
		
	if(!hKv.GotoFirstSubKey(true))
	{
		delete hKv;
		return;
	}
	
	Menu hMenu;
	char szInfo[4];
	
	do
	{
		hKv.GetSectionName(szData, sizeof szData);
	#if defined DEBUG
		PrintToServer(szData);
	#endif
		
		FormatEx(szInfo, sizeof szInfo, "%d", (++g_iChangelogsParts) - 1);
		g_Menu_Main.AddItem(szInfo, szData, ITEMDRAW_DEFAULT);
		
		hMenu = CreateMenu(MenuHandler_Dump, MENU_ACTIONS_DEFAULT);
		hMenu.SetTitle(szData);
		
		
		if(hKv.GotoFirstSubKey(false))
		{
			ReadKeyValues(hKv, hMenu);
			hKv.GoBack();
		}
		
		ArrayMenus.Push(hMenu);
	}
	
	while(hKv.GotoNextKey(true));
	
	delete hKv;
}

void MakeFile(char[] szFile)
{
	Handle f = OpenFile(szFile, "w");
	
	if(f == INVALID_HANDLE)
	{
		SetFailState("Failed to make file");
		return;
	}
	
	WriteFileLine(f, 
	"\"Changelog\"\n\
	{\n\n\
	}");
		
	delete f;
	return;
}

void ReadKeyValues(KeyValues hKv, Menu hMenu)
{
	char szData[60];
	char szDump[5];
	
	do
	{
		if(hKv.GotoFirstSubKey(false))
		{
			ReadKeyValues(hKv, hMenu);
			hKv.GoBack();
		}
		else
		{
			hKv.GetString(NULL_STRING, szData, sizeof szData);
			
			//g_iChangelogsNumber++;
			IntToString(++g_iChangelogsNumber, szDump, sizeof szDump);
			
			hMenu.AddItem(szDump, szData, ITEMDRAW_DISABLED);
			//PrintToServer("Added %s to menu %d", szData, hMenu);	
		}
	}
	while(hKv.GotoNextKey(false));
}

public int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			return 0;
		}
		
		case MenuAction_Select:
		{
			Menu hMenu = view_as<Menu>(ArrayMenus.Get(param2));
			hMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
		
	return 0;
}

public int MenuHandler_Dump(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			return 0;
		}
		
		case MenuAction_Cancel:
		{
			g_Menu_Main.Display(param1, MENU_TIME_FOREVER);
		}
		
		case MenuAction_DrawItem:
		{
			return ITEMDRAW_DISABLED;
		}
		
		case MenuAction_DisplayItem:
		{
			return param2;
		}
		
		case MenuAction_Select:
		{
			menu.Display(param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}
/* 
// i was planning on making sub menus, but i immediately got a headache xd

stock void ReadKeyValues_Old(KeyValues hKv)
{
	char szSectionName[60];
	
	do
	{
		hKv.GetSectionName(szSectionName, sizeof szSectionName);
	#if defined DEBUG
		PrintToServer("Sec: %s", szSectionName);
	#endif
	
		if(hKv.GotoFirstSubKey(false))
		{
			ReadKeyValues(hKv, hSubMenu);
			hKv.GoBack();
		}
		
		else
		{
			
		}
	}
	
	while(hKv.GotoNextKey(false));
}
*/


// Old code and wont be used.

	/*
	#if defined DEBUG
	PrintToServer("Enter 1");
	#endif
	do
	{
		// Section Name = Date each time
		hKv.GetSectionName(szData, sizeof szData);
		IntToString(iSectionsCount++, szDump, sizeof szDump);
		g_Menu_Main.AddItem(szDump, szData, ITEMDRAW_DISABLED);		
		
		#if defined DEBUG
		PrintToServer(szData);
		#endif
				
		if(!hKv.GotoFirstSubKey(false))
		{
			// Add under this change log
			#if defined DEBUG
			PrintToServer("Does not contain sub values");
			#endif
			
			g_Array_Menu_Data.Push(0);
			continue;
		}
		
		SubMenu.Menu(SpecificDateMenu, MENU_ACTIONS_ALL);
		SubMenu.SetTitle(szData);
		g_Array_Menu_Data.Push(SpecificDateMenu);
	
		do
		{
			#if defined DEBUG
			hKv.GetSectionName(szData, sizeof szData);
			PrintToServer(szData);
			#endif
			
			hKv.GetString(szData, sizeof szData);
			SpecificDateMenu.AddItem("", szData)
			
			if(hKv.GotoFirstSubKey(false))
			{
				// Create Sub menu here.
				// Items in sub menu.
				do
				{
					#if defined DEBUG
					hKv.GetSectionName(szData, sizeof szData);
					PrintToServer(szData);
					#endif
				}
							
				while(hKv.GotoNextKey(false));
				hKv.GoBack();							
			}
			
			else
			{
				g_Array_Menu_Date_Sub.
			}
		}
					
		while(hKv.GotoNextKey(false));
		
		hKv.GoBack();
	}

	while(hKv.GotoNextKey(false));
	
	delete hKv;
}*/