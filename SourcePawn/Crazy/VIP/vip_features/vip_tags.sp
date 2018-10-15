#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <chat-processor>
#include <vipsys>
#include <clientprefs>
#include <multicolors>
#include <cstrike>
#include <sdktools>

#pragma newdecls required

#define DEFAULT_TAG "[VIP]"

public Plugin myinfo = 
{
	name = "VIP Feature: Tags",
	author = PLUGIN_AUTHOR,
	description = "Tags",
	version = PLUGIN_VERSION,
	url = ""
};

enum
{
	TagColor_Name,
	TagColor_Byte
};

char cTagColors[][][] = {
	{ "Normal", 				"\x01" },
	{ "Dark Red", 				"\x02" },
	{ "Magenta", 				"\x03" },
	{ "Green",					"\x04" },
	{ "Olive",					"\x05" },
	{ "Light Green", 			"\x06" },
	{ "Light Red", 				"\x07" },
	{ "Grey", 					"\x08" },
	{ "Yellow", 				"\x09" },
	{ "Dark Grey", 				"\x0A" },
	{ "Cyan", 					"\x0B" },
	{ "Blue", 					"\x0C" },
	//{ "The heck is this color #3", "\x0D" },
	{ "Purple", 				"\x0E" },
	{ "Very Light Red", 		"\x0F" },
	{ "Gold", 					"\x10" }
};

#define MAX_TAG_LENGTH		25
char g_szClientTag[MAXPLAYERS][MAX_TAG_LENGTH];
bool g_bIntercept[MAXPLAYERS];
Handle g_hCookie_Tag,
	g_hCookie_TagColor;

int g_iPlayerTagChatColor[MAXPLAYERS];

public void OnPluginStart()
{
	g_hCookie_Tag = RegClientCookie("viptag", "Scoreboard, Chat Tag for VIPs", CookieAccess_Protected);
	g_hCookie_TagColor = RegClientCookie("viptagcolor", "Tag Color", CookieAccess_Protected);
	
	AddCommandListener(CommandListenerCallback_OnSay, "say");
	AddCommandListener(CommandListenerCallback_OnSay, "say_team");
	
	HookEvent("player_spawn", Event_PlayerSetTag);
	HookEvent("player_team", Event_PlayerSetTag);
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem("viptag", "Change (Scoreboard, Chat) Tag", MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenuCallback_ChangeTagName, 10);
	VIPSys_Menu_AddItem("viptag_color", "Change Tag Chat Color", MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenuCallback_ChangeTagColor, 9);
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem("viptag");
	VIPSys_Menu_RemoveItem("viptag_color");
}

public void Event_PlayerSetTag(Event event, char[] szName, bool bDontBroadcast)
{
	SetClientTag(GetClientOfUserId(GetEventInt(event, "userid")));
}

public void OnClientSettingsChanged(int client)
{
	if (AreClientCookiesCached(client))
	{
		SetClientTag(client);
	}
}

public void OnClientConnected(int client)
{
	g_bIntercept[client] = false;
	g_iPlayerTagChatColor[client] = 0;
}

public int VIPMenuCallback_ChangeTagColor(Menu basemenu, char[] szItemInfo, MenuAction action, int param1, int param2)
{
	DisplayTagColorMenu(param1);
}

public int MenuHandler_TagColor(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DisplayItem:
		{
			char szInfo[5]; int iIndex;
			menu.GetItem(param2, szInfo, sizeof szInfo);
			
			iIndex = StringToInt(szInfo);
			
			if(g_iPlayerTagChatColor[param1] == iIndex)
			{
				char szFormat[65];
				FormatEx(szFormat, sizeof szFormat, "%s [Current]",  cTagColors[iIndex][TagColor_Name]);
				return RedrawMenuItem(szFormat);
			}
			
			return 0;
		}
		
		case MenuAction_Select:
		{
			char szInfo[5]; int iIndex;
			menu.GetItem(param2, szInfo, sizeof szInfo);
			
			iIndex = StringToInt(szInfo);
			
			g_iPlayerTagChatColor[param1] = iIndex;
			SetClientCookie(param1, g_hCookie_TagColor, szInfo);
			
			CPrintToChat(param1, "\x04* You have chosen %s%s \x04as your chat color.", cTagColors[iIndex][TagColor_Byte], cTagColors[iIndex][TagColor_Name]);
			
			// Display Menu Again
			DisplayTagColorMenu(param1, GetMenuSelectionPosition());
		}
	}
	
	return 0;
}

void DisplayTagColorMenu(int client, int iPos = 0)
{
	Menu menu = new Menu(MenuHandler_TagColor, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	
	char szInfo[5];
	for(int i; i < sizeof cTagColors; i++)
	{
		IntToString(i, szInfo, sizeof szInfo);
		menu.AddItem(szInfo, cTagColors[i][TagColor_Name]);
	}

	menu.DisplayAt(client, iPos, MENU_TIME_FOREVER);
}

public int VIPMenuCallback_ChangeTagName(Menu menu, char[] szInfo, MenuAction action, int param1, int param2)
{
	if(action != MenuAction_Select)
	{
		return;
	}
	
	if(!VIPSys_Client_IsVIP(param1))
	{
		CPrintToChat(param1, "\x04* You are not a VIP.");
		return;
	}
	
	g_bIntercept[param1] = true;
	CPrintToChat(param1, "\x04* Type (in chat) the tag you would like to use.");
	CPrintToChat(param1, "\x04* You can type 0 or disabled to disable the tag.");
	CPrintToChat(param1, "\x04* You can cancel to cancel.");
}

public Action CommandListenerCallback_OnSay(int client, const char[] command, int argc)
{
	if(!g_bIntercept[client])
	{
		return Plugin_Continue;
	}
	
	g_bIntercept[client] = false;
	
	char szNewTag[MAX_TAG_LENGTH];
	GetCmdArg(1, szNewTag, sizeof szNewTag);
	
	if(StrEqual(szNewTag, "cancel", false))
	{
		CPrintToChat(client, "\x04* You have canceled. Your current tag is: \x07%s", g_szClientTag[client]);
		return Plugin_Handled;
	}
	
	if(StrEqual(szNewTag, "disabled", false) || StrEqual(szNewTag, "0", false) )
	{
		g_szClientTag[client] = "";
		SetClientCookie(client, g_hCookie_Tag, "disabled");
		CPrintToChat(client, "\x04* You have disabled tags.");
		return Plugin_Handled;
	}
	
	strcopy(g_szClientTag[client], sizeof g_szClientTag[], szNewTag);
	SetClientCookie(client, g_hCookie_Tag, g_szClientTag[client]);
	
	SetClientTag(client);
	CPrintToChat(client, "\x04* You have applied \x07%s \x04as your new tag.", g_szClientTag[client]);
	
	return Plugin_Handled;
}

public void OnClientCookiesCached(int client)
{
	if(!VIPSys_Client_IsVIP(client))
	{
		if(!g_szClientTag[client][0])
		{
			return;
		}
		
		g_szClientTag[client][0] = 0;
	}
	
	char szTagColor[4];
	GetClientCookie(client, g_hCookie_Tag, g_szClientTag[client], sizeof g_szClientTag[]);
	GetClientCookie(client, g_hCookie_TagColor, szTagColor, sizeof szTagColor);
	
	if(szTagColor[0])
	{
		g_iPlayerTagChatColor[client] = StringToInt(szTagColor);
		
		if(g_iPlayerTagChatColor[client] >= sizeof(cTagColors))
		{
			g_iPlayerTagChatColor[client] = 0;
		}
	}
	
	else
	{
		g_iPlayerTagChatColor[client] = 0;
	}
	
	// First Time VIP
	if(!g_szClientTag[0])
	{	
		FormatEx(g_szClientTag[client], sizeof g_szClientTag[], DEFAULT_TAG);
		SetClientCookie(client, g_hCookie_Tag, DEFAULT_TAG);
		
		if(IsClientInGame(client))
		{
			SetClientTag(client);
		}
	}
	
	else
	{
		if(StrEqual(g_szClientTag[client], "disabled"))
		{
			g_szClientTag[client][0] = 0;
			return;
		}
		
		if(IsClientInGame(client))
		{
			SetClientTag(client);
		}
	}
}

void SetClientTag(int client)
{
	if( !g_szClientTag[client][0] || StrEqual(g_szClientTag[client], "disabled", true) )
	{
		CS_SetClientClanTag(client, "");
		return;
	}

	CS_SetClientClanTag(client, g_szClientTag[client]);
}
	
public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{	
	if(!VIPSys_Client_IsVIP(author))
	{
		return Plugin_Continue;
	}
	
	if(!g_szClientTag[0])
	{
		return Plugin_Continue;
	}
	
	Format(name, MAXLENGTH_NAME, "%s%s \x03%s", cTagColors[g_iPlayerTagChatColor[author]][TagColor_Byte], g_szClientTag[author], name);
	return Plugin_Changed;
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	if(AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}