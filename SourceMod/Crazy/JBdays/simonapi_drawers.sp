#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <daysapi>
#include <simonapi>
#tryinclude <warden>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "SimonAPI: Drawers",
	version = "1.0",
	author = "Khalid",
	description = "!paint !draw !mark !laser commands",
	url = ""
}

// Boolean

#define PAINTER_DEFAULT_UPDATE_INTERVAL		2
#define MARKER_UPDATE_INTERVAL				0.25
#define MARKER_REMOVE_MAX_DISTANCE			256
#define MARKER_MINIMUM_RADIUS				16
#define MARKER_SECOND_STEP_PAUSE_TIME		0.5
#define MARKER_MAX_COUNT					6

int g_iCurrentUpdateIntervalIndex = PAINTER_DEFAULT_UPDATE_INTERVAL;
float g_flIntervals[] =  {
	0.150, 
	0.100, 
	0.050, 
	0.010
};

#define MAX_DRAWERS 3

enum Drawer ( <<= 1)
{
	Drawer_None = 0, 
	Drawer_Laser = 1, 
	Drawer_Painter, 
	Drawer_Marker
};
#define All_Drawers ( Drawer_Laser | Drawer_Painter | Drawer_Marker )

Drawer g_iDrawerType[MAX_DRAWERS] =  {
	Drawer_Laser, 
	Drawer_Painter, 
	Drawer_Marker
};

char g_szDrawerTypeInfo[MAX_DRAWERS][] =  {
	"laser", 
	"painter", 
	"marker"
};

char g_szDrawerTypeName[MAX_DRAWERS][] =  {
	"Laser", 
	"Painter", 
	"Marker"
};

Drawer g_iPlayerDrawerType[MAXPLAYERS];
int g_iPlayerDrawerColor[MAXPLAYERS];

// Give access menu stuff
int g_iPlayerAccessMenuDrawerColor[MAXPLAYERS];
int g_iPlayerAccessMenuDrawerType[MAXPLAYERS];	// Holds Index of g_iDrawerType

bool g_bAlive[MAXPLAYERS];

// Painter Vars
int g_iLastButtons[MAXPLAYERS];
float g_flLastSaveTime[MAXPLAYERS];
float g_vLastEyePos[MAXPLAYERS][3];

// Marker Vars
float g_vMarkerCenter[MAXPLAYERS][3];
float g_vMarkerRadius[MAXPLAYERS][3];
ArrayList g_hMarkerData;
Handle g_hMarkerTimer;
int g_iMarkerCount;
float g_flMarkerLastGameTime[MAXPLAYERS];

enum MarkerStep
{
	MarkerStep_None,
	MarkerStep_Center,
	MarkerStep_Radius
};

MarkerStep g_iMakingMarkerStep[MAXPLAYERS] = MarkerStep_None;

int g_iBeamSprite;
int g_iHaloSprite;

#define MAX_PAINTER_COLORS 8
int g_iColors[MAX_PAINTER_COLORS][4] = 
{
	{ 255, 255, 255, 255 },  // white
	{ 255, 0, 0, 255 },  // red
	{ 20, 255, 20, 255 },  // green
	{ 0, 65, 255, 255 },  // blue
	{ 255, 255, 0, 255 },  // yellow
	{ 0, 255, 255, 255 },  // cyan
	{ 255, 0, 255, 255 },  // magenta
	{ 255, 80, 0, 255 } // orange
};

char g_szColorNames[MAX_PAINTER_COLORS][] =  {
	"White", 
	"Red", 
	"Green", 
	"Blue", 
	"Yellow", 
	"Cyan", 
	"Magenta", 
	"Orange"
};

enum ( <<= 1)
{
	Access_None = 0, 
	Access_Admin = 1, 
	Access_Simon, 
	Access_Player
};

// Access that allows to use the menu.
#define Access_Menu	(Access_Admin | Access_Simon)
int g_iAccess[MAXPLAYERS];

bool g_bSimonAPI = false;
bool g_bLate = false;

public APLRes AskPluginLoad2(Handle plugin, bool bLate, char[] error, int max)
{
	g_bLate = bLate;
	
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] libName)
{
	if(StrEqual(libName, "simonapi"))
	{
		g_bSimonAPI = true;
	}
}

public void OnLibraryRemoved(const char[] libName)
{
	if(StrEqual(libName, "simonapi"))
	{
		g_bSimonAPI = false;
	}
}

public void OnPluginStart()
{
	// Register Commands
	RegConsoleCmd("sm_painter", Command_PaintersMenu);
	RegConsoleCmd("sm_laser", Command_PaintersMenu);
	RegConsoleCmd("sm_marker", Command_PaintersMenu);
	RegConsoleCmd("sm_paint", Command_PaintersMenu);
	RegConsoleCmd("sm_drawer", Command_PaintersMenu);
	
	RegConsoleCmd("+lookatweapon", Command_RemoveMarker);

	g_hMarkerData = CreateArray(5);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
}

public void SimonAPI_OnSimonChanged(int news, int olds, SimonChangedReason iReason)
{
	if (olds != No_Simon)
	{
		DeleteFlag(g_iAccess[olds], Access_Simon);
		AssignFlag(g_iPlayerDrawerType[olds], Drawer_None);
	}
	
	if (news != No_Simon)
	{
		GiveFlag(g_iAccess[news], Access_Simon);
	}
}

public void warden_OnWardenCreated(int client)
{
	GiveFlag(g_iAccess[client], Access_Simon);
}

public void warden_OnWardenRemoved(int client)
{
	//PrintToChatAll("RMOVEDFGASKGFJKAG");
	DeleteFlag(g_iAccess[client], Access_Simon);
	AssignFlag(g_iPlayerDrawerType[client], Drawer_None);
}

public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	
	g_hMarkerTimer = CreateTimer(MARKER_UPDATE_INTERVAL, Timer_DrawMarkers, _, TIMER_REPEAT);
	ClearMarkers();
	
	if (g_bLate)
	{
		g_bLate = false;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			OnClientPostAdminCheck(i);
			g_bAlive[i] = IsPlayerAlive(i);
		}
	}
}

public void OnMapEnd()
{
	delete g_hMarkerTimer;
	ClearMarkers();
}

public Action Command_RemoveMarker(int client, int args)
{
	if( IsFlagIn(g_iAccess[client], Access_Admin) || IsFlagIn(g_iAccess[client], Access_Simon) || ( g_bAlive[client] && GetClientTeam(client) == CS_TEAM_CT ) ) 
	{
		RemoveMarker(client);
	}
	
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	SetArrayValue(g_iMakingMarkerStep, sizeof g_iMakingMarkerStep, MarkerStep_None);
	ClearMarkers();
}

public void Event_PlayerDeath(Event event, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_bAlive[client] = false;
	g_iMakingMarkerStep[client] = MarkerStep_None;
}

public void Event_PlayerSpawn(Event event, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bAlive[client] = true;
}

public void OnClientPutInServer(int client)
{
	// I chose to put this here in case the server is using SQL admins
	// and it might take too long to cal OnClientPostAdminCheck
	g_bAlive[client] = false;
}

public void OnClientPostAdminCheck(int client)
{
	ResetClientVars(client);
}

void ResetClientVars(int client)
{
	if (g_bSimonAPI && SimonAPI_HasAccess(client, false))
	{
		//PrintToChatAll("Gave %N admin access to painters 1 ", client);
		AssignFlag(g_iAccess[client], Access_Admin);
	}
	
	else if(GetUserFlagBits(client) & (ADMFLAG_ROOT))
	{
		//PrintToChatAll("Gave %N admin access to painters 2", client);
		// Give Interval access
		AssignFlag(g_iAccess[client], Access_Admin);
	}
	
	else if(GetUserFlagBits(client) & (ADMFLAG_RESERVATION))
	{
		//PrintToChatAll("Gave %N admin access to painters 2", client);
		// Dont give interval access
		AssignFlag(g_iAccess[client], Access_Simon);
	}
	
	else
	{
		//PrintToChatAll("Gave %N no access to painters 2", client);
		AssignFlag(g_iAccess[client], Access_None);
	}
	
	g_iPlayerDrawerType[client] = Drawer_None;
	g_iPlayerDrawerColor[client] = 0;
	
	g_iPlayerAccessMenuDrawerType[client] = 0;
	g_iPlayerAccessMenuDrawerColor[client] = 0;
	
	g_iMakingMarkerStep[client] = MarkerStep_None;
}

public Action Command_PaintersMenu(int client, int args)
{
	// Not needed cause disabled in menu
	/*
	if (!HasAccess(client, Access_Menu)
	{
		CReplyToCommand(client, "\x05* You do not have the required access to use this command.");
		return Plugin_Handled;
	}*/
	
	CPrintToChat(client, "* \x04Press the \x03USE Key (default: E) \x04to activate!!");
	ShowDrawersMenu(client);
	return Plugin_Handled;
}

void ShowDrawersMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DrawerMenu, MENU_ACTIONS_ALL);
	{
		menu.SetTitle("Select");
		
		menu.AddItem(g_szDrawerTypeInfo[0], "");
		menu.AddItem(g_szDrawerTypeInfo[1], "");
		menu.AddItem(g_szDrawerTypeInfo[2], "");
		menu.AddItem("color", "Change Color");
		menu.AddItem("playeraccess", "Give Access to Player");
		
		if (IsFlagIn(g_iAccess[client], Access_Admin))
		{
			menu.AddItem("interval", "Update Interval");
		}
	}
	
	menu.Display(client, 20);
}

public int MenuHandler_DrawerMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	if (action == MenuAction_Cancel)
	{
		return 0;
	}
	
	if (action == MenuAction_DrawItem)
	{
		// Disable menu items for all those who
		// do not have the required access.
		//PrintToServer("%d %d %d", g_iAccess[param1], Access_Menu, IsFlagIn(g_iAccess[param1], Access_Menu));
		if (!IsFlagIn(g_iAccess[param1], Access_Menu))
		{
			return ITEMDRAW_DISABLED;
		}
		
		return ITEMDRAW_DEFAULT;
	}
	
	if (action == MenuAction_DisplayItem)
	{
		char szInfo[15];
		menu.GetItem(param2, szInfo, sizeof szInfo);
		char szFmt[50];
		
		for (int i; i < MAX_DRAWERS; i++)
		{
			if (StrEqual(szInfo, g_szDrawerTypeInfo[i]))
			{
				if (IsFlagIn(g_iPlayerDrawerType[param1], g_iDrawerType[i]))
				{
					FormatEx(szFmt, sizeof szFmt, "[%s: On]", g_szDrawerTypeName[i]);
					return RedrawMenuItem(szFmt);
				}
				
				FormatEx(szFmt, sizeof szFmt, "[%s]", g_szDrawerTypeName[i]);
				return RedrawMenuItem(szFmt);
			}
		}
		
		if (StrEqual(szInfo, "interval"))
		{
			FormatEx(szFmt, sizeof szFmt, "Update Interval [Current: %0.2f]", g_flIntervals[g_iCurrentUpdateIntervalIndex]);
			return RedrawMenuItem(szFmt);
		}
		
		return 0;
	}
	
	if (action == MenuAction_Select)
	{
		char szInfo[15];
		menu.GetItem(param2, szInfo, sizeof szInfo);
		bool bRedisplay = true;
		
		for (int i; i < MAX_DRAWERS; i++)
		{
			if (StrEqual(szInfo, g_szDrawerTypeInfo[i]))
			{
				if (g_iDrawerType[i] == Drawer_Marker)
				{
					if(g_iMarkerCount + 1 > MARKER_MAX_COUNT)
					{
						CPrintToChat(param1, "* \x07MARKER - \x01Too many markers. Remove some by pressing \x04G (drop) \x01near the center.");
					}
					
					else
					{
						SetupMarkerFirstStep(param1);
					}
				}
				
				else if (IsFlagIn(g_iPlayerDrawerType[param1], g_iDrawerType[i]))
				{
					DeleteFlag(g_iPlayerDrawerType[param1], g_iDrawerType[i]);
				}
				
				else
				{
					if (IsFlagIn(g_iAccess[param1], Access_Admin))
					{
						// Unconditional use of the painters
						// meaning can use them all at once.
						GiveFlag(g_iPlayerDrawerType[param1], g_iDrawerType[i]);
					}
					
					// Can only use one at a time
					else
					{
						DeleteFlag(g_iPlayerDrawerType[param1], All_Drawers);
						GiveFlag(g_iPlayerDrawerType[param1], g_iDrawerType[i]);
					}
				}
				break;
			}
		}
		
		if (StrEqual(szInfo, "color"))
		{
			ShowColorsMenu(param1, false);
			bRedisplay = false;
		}
		
		else if (StrEqual(szInfo, "playeraccess"))
		{
			ShowPlayerAccessMenu(param1);
			bRedisplay = false;
		}
		
		else if (StrEqual(szInfo, "interval"))
		{
			ShowIntervalMenu(param1);
			bRedisplay = false;
		}
		
		if (bRedisplay)
		{
			ShowDrawersMenu(param1);
		}
	}
	
	return 0;
}

void SetupMarkerFirstStep(int client)
{
	g_iMakingMarkerStep[client] = MarkerStep_Center;
	CPrintToChat(client, "* \x07MARKER -\x01 Making a marker with color \x04%s. \x01You can also press \x04F (+lookatweapon) \x05anytime to remove the marker\x01.", g_szColorNames[g_iPlayerDrawerColor[client]]);
	CPrintToChat(client, "* \x07MARKER -\x01 STEP 1: Press \x04E (use key) \x01 to set the center of the circle/ring");	
}

void SetupMarkerSecondStep(int client)
{
	g_iMakingMarkerStep[client] = MarkerStep_Radius;
	CPrintToChat(client, "* \x07MARKER - \x01STEP 2: Press \x04E (use key) \x01 to the radius.");
}

void AddMarker(int client)
{
	g_iMakingMarkerStep[client] = MarkerStep_None;
	
	if( !g_bAlive[client] || GetClientTeam(client) != CS_TEAM_CT )
	{
		if(!IsFlagIn(g_iAccess[client], Access_Menu))
		{
			return;
		}
	}
	
	if(g_iMarkerCount + 1 > MARKER_MAX_COUNT)
	{
		CPrintToChat(client, "* \x07MARKER - \x01Too many markers. Remove some by pressing \x04G (drop) \x01near the center.");
		return;
	}
	
	float flRadius = GetVectorDistance(g_vMarkerCenter[client], g_vMarkerRadius[client]);
	
	if( flRadius < MARKER_MINIMUM_RADIUS )
	{
		CPrintToChat(client, "* \x07MARKER - \x01Marker size is too small, try again with a bigger radius.");
		return;
	}
	
	DataPack hPack = CreateDataPack();
	hPack.WriteFloat(g_vMarkerCenter[client][0]);
	hPack.WriteFloat(g_vMarkerCenter[client][1]);
	hPack.WriteFloat(g_vMarkerCenter[client][2]);
	
	hPack.WriteFloat(2*flRadius);
	hPack.WriteCell(g_iPlayerDrawerColor[client]);
	hPack.Reset(false);
	
	g_hMarkerData.Push(hPack);
	
	g_iMarkerCount++;
	CPrintToChat(client, "* \x07MARKER - \x01Created Marker. Current Total: \x04%d", g_iMarkerCount);
}

void RemoveMarker(int client)
{
	float vAimPos[3], vMarkerPos[3];
	GetEndEyePos(client, NULL_VECTOR, vAimPos);
	
	DataPack hPack;
	
	int iIndex = -1;
	float flLastSmallestDistance = 9999.0;
	float flDistance;
	
	for (int i; i < g_iMarkerCount; i++)
	{
		hPack = g_hMarkerData.Get(i);
		
		vMarkerPos[0] = hPack.ReadFloat();
		vMarkerPos[1] = hPack.ReadFloat();
		vMarkerPos[2] = hPack.ReadFloat();
		
		hPack.Reset(false);
		
		if( ( (flDistance = GetVectorDistance(vMarkerPos, vAimPos) ) <= MARKER_REMOVE_MAX_DISTANCE ) && flDistance < flLastSmallestDistance)
		{
			iIndex = i;
			flLastSmallestDistance = flDistance;
		}
	}
	
	if(iIndex != -1)
	{
		hPack = g_hMarkerData.Get(iIndex);
		delete hPack;
		--g_iMarkerCount;
		g_hMarkerData.Erase(iIndex);
		
		CPrintToChat(client, "* \x07MARKER - \x01Removed Marker. Current existing total: \x04%d", g_iMarkerCount);
	}
}

void ClearMarkers()
{
	DataPack hPack;
	for (int i; i < g_iMarkerCount; i++)
	{
		hPack = g_hMarkerData.Get(i);
		delete hPack;
	}
	
	g_hMarkerData.Clear();
	g_iMarkerCount = 0;
}

public Action Timer_DrawMarkers(Handle timer)
{
	float vMarkerCenter[3];
	float flMarkerRadius;
	int iMarkerColorIndex;
	
	DataPack hPack;
	
	for (int i; i < g_iMarkerCount; i++)
	{
		hPack = g_hMarkerData.Get(i);
		
		vMarkerCenter[0] = hPack.ReadFloat();
		vMarkerCenter[1] = hPack.ReadFloat();
		vMarkerCenter[2] = hPack.ReadFloat();
		flMarkerRadius = hPack.ReadFloat();
		iMarkerColorIndex = hPack.ReadCell();
		
		hPack.Reset(false);
		
		TE_SetupBeamRingPoint(vMarkerCenter, flMarkerRadius, flMarkerRadius+5.0, g_iBeamSprite, g_iHaloSprite, 0, 10, MARKER_UPDATE_INTERVAL+0.05, 2.0, 0.0, g_iColors[iMarkerColorIndex], 10, 0);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(vMarkerCenter, 10.0, 10.0+5.0, g_iBeamSprite, g_iHaloSprite, 0, 10, MARKER_UPDATE_INTERVAL+0.05, 2.0, 0.0, { 128, 128, 128, 255 }, 10, 0);
		TE_SendToAll();
	}
	
	float vMarkerEndOrigin[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_bAlive[i] && g_iMakingMarkerStep[i] == MarkerStep_Radius)
		{
			GetEndEyePos(i, NULL_VECTOR, vMarkerEndOrigin);
			vMarkerEndOrigin[2] = g_vMarkerCenter[i][2];
			flMarkerRadius = 2*GetVectorDistance(vMarkerEndOrigin, g_vMarkerCenter[i]);
			TE_SetupBeamRingPoint(g_vMarkerCenter[i], flMarkerRadius, flMarkerRadius+5.0, g_iBeamSprite, g_iHaloSprite, 0, 10, MARKER_UPDATE_INTERVAL+0.05, 2.0, 0.0, g_iColors[g_iPlayerDrawerColor[i]], 10, 0);
			TE_SendToAll();
		}
	}
}

public void DaysAPI_OnDayStart(char[] szName, bool bWasPlanned, any data)
{
	ClearMarkers();
}

void ShowColorsMenu(int client, bool bPlayerAccessMenu)
{
	Menu menu = new Menu(bPlayerAccessMenu ? MenuHandler_ColorSelect_PlayerAccess : MenuHandler_ColorSelect_Main, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	
	//char szInfo[5];
	for (int i; i < MAX_PAINTER_COLORS; i++)
	{
		//FormatEx(StringFromInt(, sizeof szInfo, "%d", i);
		menu.AddItem(StringFromInt(i), "");
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ColorSelect_PlayerAccess(Menu menu, MenuAction action, int param1, int param2)
{
	return MenuHandler_ColorSelect(menu, action, param1, param2, true);
}

public int MenuHandler_ColorSelect_Main(Menu menu, MenuAction action, int param1, int param2)
{
	return MenuHandler_ColorSelect(menu, action, param1, param2, false);
}

int MenuHandler_ColorSelect(Menu menu, MenuAction action, int param1, int param2, bool bPlayerAccess)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Exit)
		{
			if (bPlayerAccess)
			{
				ShowPlayerAccessMenu(param1);
			}
			else
			{
				ShowDrawersMenu(param1);
			}
		}
		
		return 0;
	}
	
	if (action == MenuAction_DisplayItem)
	{
		char szFmt[50];
		menu.GetItem(param2, szFmt, sizeof szFmt);
		int iIndex = StringToInt(szFmt);
		
		if (bPlayerAccess)
		{
			if (g_iPlayerAccessMenuDrawerColor[param1] == iIndex)
			{
				FormatEx(szFmt, sizeof szFmt, "[%s <---]", g_szColorNames[iIndex]);
				return RedrawMenuItem(szFmt);
			}
			
			FormatEx(szFmt, sizeof szFmt, "[%s]", g_szColorNames[iIndex]);
			return RedrawMenuItem(szFmt);
		}
		
		else
		{
			if (g_iPlayerDrawerColor[param1] == iIndex)
			{
				FormatEx(szFmt, sizeof szFmt, "[%s <---]", g_szColorNames[iIndex]);
				return RedrawMenuItem(szFmt);
			}
			
			FormatEx(szFmt, sizeof szFmt, "[%s]", g_szColorNames[iIndex]);
			return RedrawMenuItem(szFmt);
		}
	}
	
	if (action == MenuAction_Select)
	{
		char szFmt[5];
		menu.GetItem(param2, szFmt, sizeof szFmt);
		int iIndex = StringToInt(szFmt);
		
		if (bPlayerAccess)
		{
			g_iPlayerAccessMenuDrawerColor[param1] = iIndex;
		}
		
		else
		{
			g_iPlayerDrawerColor[param1] = iIndex;
		}
		
		ShowColorsMenu(param1, bPlayerAccess);
	}
	
	return 0;
}

void ShowPlayerAccessMenu(int client)
{
	PrintToServer("Player Access Menu");
	
	Menu menu = new Menu(MenuHandler_PlayerAccess, MENU_ACTIONS_ALL);
	{
		menu.AddItem("removeall", "Remove Access From All");
		menu.AddItem("drawertype", "");
		menu.AddItem("color", "");
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			if (!IsPlayerAlive(i))
			{
				continue;
			}
			
			if (i == client/* || g_bIsAdmin[i]*/)
			{
				continue;
			}
			
			menu.AddItem(StringFromInt(i), "");
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerAccess(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}
	
	char szInfo[15];
	int iClientIndex;
	if (action == MenuAction_DrawItem)
	{
		menu.GetItem(param2, szInfo, sizeof szInfo);
		iClientIndex = StringToInt(szInfo);
		
		if (IsFlagIn(g_iAccess[iClientIndex], Access_Admin))
		{
			return ITEMDRAW_DISABLED;
		}
		
		return ITEMDRAW_DEFAULT;
	}
	
	if (action == MenuAction_DisplayItem)
	{
		menu.GetItem(param2, szInfo, sizeof szInfo);
		
		if (StrEqual(szInfo, "removeall"))
		{
			return 0;
		}
		
		char szFmt[65];
		if (StrEqual(szInfo, "drawertype"))
		{
			FormatEx(szFmt, sizeof szFmt, "Drawer Type: %s", g_szDrawerTypeName[g_iPlayerAccessMenuDrawerType[param1]]);
			return RedrawMenuItem(szFmt);
		}
		
		if (StrEqual(szInfo, "color"))
		{
			FormatEx(szFmt, sizeof szFmt, "Drawer Color: %s", g_szColorNames[g_iPlayerAccessMenuDrawerColor[param1]]);
			return RedrawMenuItem(szFmt);
		}
		
		iClientIndex = StringToInt(szInfo);
		if (IsFlagIn(g_iAccess[iClientIndex], Access_Player))
		{
			FormatEx(szFmt, sizeof szFmt, "%N [%s - %s]", iClientIndex, g_szDrawerTypeName[FindPlayerDrawer(iClientIndex)], g_szColorNames[g_iPlayerDrawerColor[iClientIndex]]);
		}
		
		else
		{
			FormatEx(szFmt, sizeof szFmt, "%N", iClientIndex);
		}
		
		return RedrawMenuItem(szFmt);
	}
	
	else if (action == MenuAction_Select)
	{
		menu.GetItem(param2, szInfo, sizeof szInfo);
		iClientIndex = StringToInt(szInfo);
		bool bRedisplay;
		
		if (StrEqual(szInfo, "removeall"))
		{
			RemoveAccessFromAll();
			bRedisplay = true;
		}
		
		else if (StrEqual(szInfo, "color"))
		{
			ShowColorsMenu(param1, true);
			bRedisplay = false;
		}
		
		else if (StrEqual(szInfo, "drawertype"))
		{
			bRedisplay = true;
			++g_iPlayerAccessMenuDrawerType[param1];
			if(g_iDrawerType[g_iPlayerAccessMenuDrawerType[param1]] == Drawer_Marker)
			{
				++g_iPlayerAccessMenuDrawerType[param1];
			}
			
			if (g_iPlayerAccessMenuDrawerType[param1] == sizeof g_iDrawerType)
			{
				g_iPlayerAccessMenuDrawerType[param1] = 0;
			}
		}
		
		else
		{
			iClientIndex = StringToInt(szInfo);
			if (!IsClientInGame(iClientIndex) || !IsPlayerAlive(iClientIndex))
			{
				CPrintToChat(param1, "* \x04Player no longer valid.");
				
			}
			
			else
			{
				if (IsFlagIn(g_iAccess[iClientIndex], Access_Player))
				{
					DeleteFlag(g_iAccess[iClientIndex], Access_Player);
					AssignFlag(g_iPlayerDrawerType[iClientIndex], Drawer_None);
					
					g_iPlayerDrawerColor[iClientIndex] = g_iPlayerAccessMenuDrawerColor[iClientIndex];
				}
				
				else
				{
					GiveFlag(g_iAccess[iClientIndex], Access_Player);
					AssignFlag(g_iPlayerDrawerType[iClientIndex], g_iDrawerType[g_iPlayerAccessMenuDrawerType[param1]]);
				}
				
				bRedisplay = true;
			}
		}
		
		if (bRedisplay)
		{
			ShowPlayerAccessMenu(param1);
		}
		
		return 0;
	}
	
	return 0;
}

void RemoveAccessFromAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (!IsFlagIn(g_iAccess[i], Access_Player))
		{
			continue;
		}
		
		DeleteFlag(g_iAccess[i], Access_Player);
		AssignFlag(g_iPlayerDrawerType[i], Drawer_None);
	}
}

int FindPlayerDrawer(int client)
{
	for (int i; i < MAX_DRAWERS; i++)
	{
		// Return the first
		if (IsFlagIn(g_iPlayerDrawerType[client], g_iDrawerType[i]))
		{
			return i;
		}
	}
	
	return -1;
}

void ShowIntervalMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Interval, MENU_ACTIONS_DEFAULT);
	{
		char szInfo[7];
		for (int i; i < sizeof g_flIntervals; i++)
		{
			FormatEx(szInfo, sizeof szInfo, "%0.2f", g_flIntervals[i]);
			menu.AddItem(StringFromInt(i), szInfo);
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

char[] StringFromInt(int iInt)
{
	char szString[5];
	IntToString(iInt, szString, sizeof szString);
	return szString;
}

public int MenuHandler_Interval(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Select)
	{
		char szInfo[5];
		menu.GetItem(param2, szInfo, sizeof szInfo);
		g_iCurrentUpdateIntervalIndex = StringToInt(szInfo);
		
		CPrintToChat(param1, "* \x04You have selected \x01%0.2f \x04as the new interval.", g_flIntervals[g_iCurrentUpdateIntervalIndex]);
		ShowDrawersMenu(param1);
	}
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	int iLastButtons = g_iLastButtons[client];
	g_iLastButtons[client] = buttons;
	
	if(!g_bAlive[client])
	{
		return;
	}
	
	if (!(buttons & IN_USE))
	{
		return;
	}
	
	bool bSave = false;
	float flGameTime = GetGameTime();
	if (g_iPlayerDrawerType[client] & Drawer_Laser)
	{
		if (flGameTime - g_flLastSaveTime[client] > g_flIntervals[g_iCurrentUpdateIntervalIndex])
		{
			//PrintToServer("Print L");
			bSave = true;
		
			float vOrigin[3], vImpact[3];
			GetEndEyePos(client, vOrigin, vImpact);
			
			TE_SetupBeamPoints(vOrigin, vImpact, g_iBeamSprite, 0, 0, 0, 0.1, 0.12, 0.0, 1, 0.0, g_iColors[g_iPlayerDrawerColor[client]], 0);
			TE_SendToAll();
			TE_SetupGlowSprite(vImpact, g_iHaloSprite, 0.1, 0.25, 255);
			TE_SendToAll();
		}
	}
	
	if (g_iPlayerDrawerType[client] & Drawer_Painter)
	{
		//PrintToServer("Check Ok");
		if (!(iLastButtons & IN_USE))
		{
			GetEndEyePos(client, NULL_VECTOR, g_vLastEyePos[client]);
			bSave = true;
		}
		
		else if (flGameTime - g_flLastSaveTime[client] > g_flIntervals[g_iCurrentUpdateIntervalIndex])
		{
			//PrintToServer("Print P");
			float vVectorEnd[3];
			
			bSave = true;
			
			GetEndEyePos(client, NULL_VECTOR, vVectorEnd);
			ConnectLine(g_vLastEyePos[client], vVectorEnd, g_iColors[g_iPlayerDrawerColor[client]]);
			
			g_vLastEyePos[client][0] = vVectorEnd[0];
			g_vLastEyePos[client][1] = vVectorEnd[1];
			g_vLastEyePos[client][2] = vVectorEnd[2];
		}
	}
	
	if(g_iMakingMarkerStep[client] == MarkerStep_Center)
	{
		GetEndEyePos(client, NULL_VECTOR, g_vMarkerCenter[client]);
		g_vMarkerCenter[client][2] += 7.5;
		
		SetupMarkerSecondStep(client);
		
		g_flMarkerLastGameTime[client] = GetGameTime();
	}
		
	if(g_iMakingMarkerStep[client] == MarkerStep_Radius && g_flMarkerLastGameTime[client] + MARKER_SECOND_STEP_PAUSE_TIME < GetGameTime())
	{
		GetEndEyePos(client, NULL_VECTOR, g_vMarkerRadius[client]);
		g_vMarkerRadius[client][2] == g_vMarkerCenter[client][2];
		AddMarker(client);
	}
	
	if(bSave)
	{
		g_flLastSaveTime[client] = flGameTime;
	}
	
	return;
}

void ConnectLine(float start[3], float end[3], int color[4])
{
	TE_SetupBeamPoints(start, end, g_iBeamSprite, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, color, 0);
	TE_SendToAll();
}

/*
int GetNextColor()
{
	if (++g_iAccessLastColor < MAXCOLORS)
	{
		return g_iAccessLastColor;
	}
	
	return (g_iAccessLastColor = 0);
}*/

bool GetEndEyePos(int client, float vEyePos[3] = NULL_VECTOR, float vector[3])
{
	GetClientEyePosition(client, vEyePos);
	GetClientEyeAngles(client, vector);
	
	TR_TraceRayFilter(vEyePos, vector, MASK_PLAYERSOLID, RayType_Infinite, TraceRayFiler, client);
	
	if (TR_DidHit())
	{
		TR_GetEndPosition(vector);
		return true;
	}
	
	return false;
}

public bool TraceRayFiler(int entity, int contentsMask, int client)
{
	if (entity == client)
	{
		return false;
	}
	
	return true;
}

//bool HasFlag(any iFlagVar, any Access)
bool IsFlagIn(any iFlagVar, any Access)
{
	return (iFlagVar & Access) == 0 ? false : true;
}

void GiveFlag(any &iFlagVar, any Access)
{
	iFlagVar |= Access;
}

void AssignFlag(any &iFlagVar, any Access)
{
	iFlagVar = Access;
	//PrintToServer("- %d .. %d", iFlagVar, Access);
}

void DeleteFlag(any &iFlagVar, any Access)
{
	iFlagVar &= ~Access;
}

stock void SetArrayValue(any[] Array, int iSize, any Value, int iStartingIndex = 0)
{
	for (int i = iStartingIndex; i < iSize; i++)
	{
		Array[i] = Value;
	}
}


/*
methodmap Client
{
	public Client(int iPlayerIndex) {
		return view_as<Client>(iPlayerIndex);
	}
	property bool Laser {
		public get() {
			return HasFlag(g_iPlayerDrawer[this], Drawer_Laser);
		}
		public set(bool value) {
			switch(value)
			{
				case true:	return GiveFlag(g_iPlayerDrawer[this], Drawer_Laser);
				case false:	return RemoveFlag(g_iPlayerDrawer[this], Drawer_Laser);
			}
		}
	}
	
	property bool Painter {
		public get() {
			return HasFlag(g_iPlayerDrawer[this], Drawer_Painter);
		}
		
		public set(bool value) {
			switch(value)
			{
				case true:	return GiveFlag(g_iPlayerDrawer[this], Drawer_Painter);
				case false:	return RemoveFlag(g_iPlayerDrawer[this], Drawer_Painter);
			}
		}
	}
	
	property bool Marker {
		public get()
		{
			return HasFlag(g_iPlayerDrawer[this], Drawer_Marker);
		}
		public set(bool value) {
			switch(value)
			{
				case true:	return GiveFlag(g_iPlayerDrawer[this], Drawer_Marker);
				case false:	return RemoveFlag(g_iPlayerDrawer[this], Drawer_Marker);
			}
		}
	}
	
	property int Color {
		public int get() {
			return g_iPlayerDrawerColor[this];
		}
		
		public int set(int color) {
			return (g_iPlayerDrawerColor = color);
		}
	}
	
	public void GiveDrawer(Drawer drawer)
	{
		GiveFlag(g_iPlayerDrawer[this], drawer);
	}
	
	public bool HasDrawer(Drawer drawer)
	{
		return HasFlag(g_iPlayerDrawer[this], drawer);
	}
	
	public void Reset() {
		g_iPlayerDrawerFlags[this] = Drawer_None;
	}
	
	public bool HasAccess(int iAccess) {
		return HasFlag(g_iAccess[this], iAccess);
	}
	
	public void RemoveAccess(int iAccess) {
		DeleteFlag(g_iAccess[this], iAccess);
	}
	
	property int Access {
		public get() {
			return g_iAccess[this];
		}
		
		public set(int iAccess) {
			return g_iAccess[this] = iAccess;
		}
	}
}
*/

