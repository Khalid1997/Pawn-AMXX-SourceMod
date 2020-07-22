#include <cstrike>
#include <multicolors>
#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <vipsys>

#undef REQUIRE_PLUGIN
#include <updater>

//ConVar g_hCvar_Trail_Enable, 
//g_hCvar_Trail_AdminOnly, 
ConVar g_hCvar_Trail_Duration, 
g_hCvar_Trail_Fade_Duration, 
g_hCvar_Trail_Width, 
g_hCvar_Trail_End_Width, 
g_hCvar_Trail_Per_Round;

Handle g_Cookie_Trail = null, 
g_TrailTimer[MAXPLAYERS + 1], 
g_SpawnTimer[MAXPLAYERS + 1];

float g_fCvar_Trail_Duration, 
g_fCvar_Trail_Width, 
g_fCvar_Trail_End_Width, 
g_fPosition[MAXPLAYERS + 1][3];

//bool g_bCvar_Trail_Enable, 
//g_bCvar_Trail_AdminOnly, 
bool g_bTrail[MAXPLAYERS + 1] =  { false, ... }, 
g_bSpamCheck[MAXPLAYERS + 1] =  { false, ... }, 
g_bTimerCheck[MAXPLAYERS + 1] =  { false, ... };

int g_iSpamCmd[MAXPLAYERS];

int g_iTrailIndex, 
g_iTrailcolor[MAXPLAYERS + 1][4], 
g_iCvar_Trail_Fade_Duration, 
g_iCvar_Trail_Per_Round, 
g_iMatches[MAXPLAYERS + 1], 
g_iButtons[MAXPLAYERS + 1], 
g_iCookieTrail[MAXPLAYERS + 1];

char TTag[][] =  { "red", "orange", "yellow", "green", "blue", "purple", "pink", "cyan", "white", "none" };
char TTagCode[][] =  { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" };

#define PLUGIN_VERSION          "1.1.0"
#define PLUGIN_NAME             "[CS:GO] Player Trails"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Gives clients a colored trail when moving."
#define PLUGIN_URL              "http://maxximou5.com/"
#define UPDATE_URL              "http://www.maxximou5.com/sourcemod/playertrails/update.txt"
#define MODEL_TRAIL             "materials/sprites/laserbeam.vmt"
#define CHAT_BANNER             "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01]"
#define MAX_TCOLORS             10

public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_playertrails_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	//g_hCvar_Trail_Enable = CreateConVar("sm_trail_enable", "1", "Enable or Disable all features of the plugin.", _, true, 0.0, true, 1.0);
	//g_hCvar_Trail_AdminOnly = CreateConVar("sm_trail_adminonly", "0", "Enable trails only for Admins (VOTE Flag).", _, true, 0.0, true, 1.0);
	g_hCvar_Trail_Duration = CreateConVar("sm_trail_duration", "1.0", "Duration of the trail.", _, true, 1.0, true, 100.0);
	g_hCvar_Trail_Fade_Duration = CreateConVar("sm_trail_fade_duration", "1", "Duration of the trail.", _, true, 1.0, true, 100.0);
	g_hCvar_Trail_Width = CreateConVar("sm_trail_width", "5.0", "Width of the trail.", _, true, 1.0, true, 100.0);
	g_hCvar_Trail_End_Width = CreateConVar("sm_trail_end_width", "1.0", "Width of the trail.", _, true, 1.0, true, 100.0);
	g_hCvar_Trail_Per_Round = CreateConVar("sm_trail_per_round", "5", "How many times per round a client can use the command.", _, true, 1.0, true, 100.0);
	g_Cookie_Trail = RegClientCookie("TrailColor", "TrailColor", CookieAccess_Protected);
	
	//HookConVarChange(g_hCvar_Trail_Enable, OnSettingsChange);
	//HookConVarChange(g_hCvar_Trail_AdminOnly, OnSettingsChange);
	HookConVarChange(g_hCvar_Trail_Duration, OnSettingsChange);
	HookConVarChange(g_hCvar_Trail_Fade_Duration, OnSettingsChange);
	HookConVarChange(g_hCvar_Trail_Width, OnSettingsChange);
	HookConVarChange(g_hCvar_Trail_End_Width, OnSettingsChange);
	HookConVarChange(g_hCvar_Trail_Per_Round, OnSettingsChange);
	
	AutoExecConfig(true, "playertrails");
	
	RegConsoleCmd("sm_trail", Command_Trail, "Opens a menu for players to choose their trail colors.");
	RegConsoleCmd("sm_trails", Command_Trail, "Opens a menu for players to choose their trail colors.");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsValidClient(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
	
	UpdateConVars();
	
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("ERROR: This plugin is designed only for CS:GO.");
	}
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem("surf_trails", "Trails", MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenuCallback_ItemSelect, 9);
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem("surf_trails");
}

public void OnConfigsExecuted()
{
	UpdateConVars();
}

public void OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
}

public void Event_RoundStart(Event event, char[] szName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iSpamCmd[i] = 0;
	}
}

public void OnMapStart()
{
	g_iTrailIndex = PrecacheModel(MODEL_TRAIL, true);
}

public void OnClientCookiesCached(int client)
{
	char CookieTrail[64];
	GetClientCookie(client, g_Cookie_Trail, CookieTrail, sizeof(CookieTrail));
	if (StringToInt(CookieTrail) <= -1)
	{
		g_iCookieTrail[client] = 0;
	}
	else
	{
		g_iCookieTrail[client] = StringToInt(CookieTrail);
	}
	
	if (VIPSys_Client_IsVIP(client))
	{
		VIPSys_Client_OnCheckVIP(client, true);
	}
}

public void OnClientPutInServer(int client)
{
	g_fPosition[client] = view_as<float>( { 0.0, 0.0, 0.0 } );
	g_iButtons[client] = 0;
	g_iMatches[client] = 0;
	
	g_iSpamCmd[client] = 0;
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	g_bTrail[client] = false;
	
	if (!AreClientCookiesCached(client) || !bIsVIP)
	{
		return;
	}
	
	if (g_iCookieTrail[client] > 0)
	{
		g_bTrail[client] = true;
	}
	else
	{
		g_bTrail[client] = false;
	}
}

/*
/// ??????
public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
}
*/

public void OnClientDisconnect(int client)
{
	if (AreClientCookiesCached(client))
	{
		char CookieTrail[64];
		Format(CookieTrail, sizeof(CookieTrail), "%i", g_iCookieTrail[client]);
		SetClientCookie(client, g_Cookie_Trail, CookieTrail);
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && g_bTrail[client] && (GetClientTeam(client) != CS_TEAM_SPECTATOR))
	{
		if (IsValidClient(client))
		{
			GetClientAbsOrigin(client, g_fPosition[client]);
			g_iButtons[client] = GetClientButtons(client);
			g_iMatches[client] = 0;
			g_bTimerCheck[client] = false;
			g_SpawnTimer[client] = CreateTimer(1.0, Timer_TrailsCheck, GetClientSerial(client), TIMER_REPEAT);
		}
		if (g_TrailTimer[client] == null)
		{
			CreateTimer(1.5, Timer_SpawnTrail, GetClientSerial(client));
		}
	}
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && g_bTrail[client])
	{
		if (IsValidClient(client))
		{
			if (g_SpawnTimer[client] != null)
			{
				ResetTimer(g_SpawnTimer[client]);
				ResetTimer(g_TrailTimer[client]);
			}
		}
	}
	return Plugin_Handled;
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			TrailSelection(param1, StringToInt(info), false);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return;
}

public int VIPMenuCallback_ItemSelect(Menu menu, char[] szInfo, MenuAction action, int client, int param2)
{
	if (!VIPSys_Client_IsVIP(client))
	{
		CPrintToChat(client, "\x04* You are not a VIP.");
		return;
	}
	
	g_iSpamCmd[client] += 1;
	if (g_iSpamCmd[client] >= g_iCvar_Trail_Per_Round)
	{
		CPrintToChat(client, "%s {red}ERROR{default}: You must wait until next round!", CHAT_BANNER);
		return;
	}
	
	ShowTrailsMenu(client);
}

public Action Command_Trail(int client, int args)
{
	if (!IsValidClient(client))
	{
		CPrintToChat(client, "%s {red}ERROR{default}: You must be alive and not a spectator!", CHAT_BANNER);
		return Plugin_Handled;
	}
	
	if(!VIPSys_Client_IsVIP(client))
	{
		return Plugin_Handled;
	}
	
	g_iSpamCmd[client] += 1;
	if (g_iSpamCmd[client] >= g_iCvar_Trail_Per_Round)
	{
		CPrintToChat(client, "%s {red}ERROR{default}: You must wait until next round!", CHAT_BANNER);
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ShowTrailsMenu(client);
		return Plugin_Handled;
	}
	
	if (args == 1)
	{
		char text[24];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
		
		for (int i = 0; i < MAX_TCOLORS; i++)
		{
			if (StrContains(text, TTag[i], false) == -1)
				continue;
			
			ReplaceString(text, 24, TTag[i], TTagCode[i], false);
		}
		TrailSelection(client, StringToInt(text), false);
	}
	
	if (args > 2)
	{
		CReplyToCommand(client, "{green}Usage{default}: sm_trail <color> [{red}red, {darkorange}orange, {orange}yellow, {green}green, {blue}blue, {purple}purple, {pink}pink, {lightblue}cyan, {default}white, none]");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

void ShowTrailsMenu(int client)
{
	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	menu.SetTitle("Trail Colors Menu:");
	menu.AddItem("0", "none");
	menu.AddItem("1", "red");
	menu.AddItem("2", "orange");
	menu.AddItem("3", "yellow");
	menu.AddItem("4", "green");
	menu.AddItem("5", "blue");
	menu.AddItem("6", "purple");
	menu.AddItem("7", "pink");
	menu.AddItem("8", "cyan");
	menu.AddItem("9", "white");
	menu.ExitButton = false;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Action Timer_SpawnTrail(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client))
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client))
		return Plugin_Stop;
	
	TrailSelection(client, g_iCookieTrail[client], true);
	
	return Plugin_Handled;
}

public Action Timer_CreateTrail(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client))
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client))
		return Plugin_Stop;
	
	if (!g_bTrail[client])
		return Plugin_Stop;
	
	if (g_bSpamCheck[client])
		return Plugin_Stop;
	
	if (g_TrailTimer[client] != null)
		ResetTimer(g_TrailTimer[client]);
	
	g_bSpamCheck[client] = true;
	int ent = GetPlayerWeaponSlot(client, 0);
	if (!IsValidEntity(ent))
		ent = client;
	
	TE_SetupBeamFollow(client, g_iTrailIndex, 0, g_fCvar_Trail_Duration, g_fCvar_Trail_Width, g_fCvar_Trail_End_Width, g_iCvar_Trail_Fade_Duration, g_iTrailcolor[client]);
	TE_SendToAll();
	
	return Plugin_Handled;
}

public Action Timer_TrailsCheck(Handle Timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client))
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client))
		return Plugin_Stop;
	
	if (g_bTimerCheck[client])
		return Plugin_Stop;
	
	if (g_bTrail[client])
	{
		float fPosition[3];
		GetClientAbsOrigin(client, fPosition);
		int iButtons = GetClientButtons(client);
		
		if (!bVectorsEqual(fPosition, g_fPosition[client]))
		{
			g_iMatches[client] += 1;
		}
		
		if (iButtons == g_iButtons[client])
		{
			g_iMatches[client] += 1;
		}
		
		if (g_iMatches[client] < 2)
		{
			g_iMatches[client] = 0;
		}
		
		if (g_iMatches[client] >= 4)
		{
			g_iMatches[client] = 0;
			g_bSpamCheck[client] = false;
			g_bTimerCheck[client] = true;
			CreateTimer(g_fCvar_Trail_Duration, Timer_TrailCooldown, GetClientSerial(client));
			CreateTrails(client);
		}
	}
	
	g_SpawnTimer[client] = null;
	
	return Plugin_Continue;
}

public Action Timer_TrailCooldown(Handle Timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client))
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client))
		return Plugin_Stop;
	
	g_bTimerCheck[client] = false;
	
	return Plugin_Handled;
}

public OnSettingsChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_Trail_Duration)
		g_fCvar_Trail_Duration = StringToFloat(newValue);
	else if (convar == g_hCvar_Trail_Fade_Duration)
		g_iCvar_Trail_Fade_Duration = StringToInt(newValue);
	else if (convar == g_hCvar_Trail_Width)
		g_fCvar_Trail_Width = StringToFloat(newValue);
	else if (convar == g_hCvar_Trail_End_Width)
		g_fCvar_Trail_End_Width = StringToFloat(newValue);
	else if (convar == g_hCvar_Trail_Per_Round)
		g_iCvar_Trail_Per_Round = StringToInt(newValue);
}

void TrailSelection(int client, int arg, bool spawned)
{
	g_iCookieTrail[client] = arg;
	char buffer[64];
	Format(buffer, sizeof(buffer), "%i", arg);
	SetClientCookie(client, g_Cookie_Trail, buffer);
	g_iTrailcolor[client][3] = 255;
	
	switch (g_iCookieTrail[client])
	{
		case 0:
		{
			g_bTrail[client] = false;
		}
		case 1:
		{
			g_iTrailcolor[client][0] = 255;
			g_iTrailcolor[client][1] = 0;
			g_iTrailcolor[client][2] = 0;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned)
			{
				CPrintToChat(client, "%s Your trail color is {red}red.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 2:
		{
			g_iTrailcolor[client][0] = 255;
			g_iTrailcolor[client][1] = 128;
			g_iTrailcolor[client][2] = 0;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {darkorange}orange.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 3:
		{
			g_iTrailcolor[client][0] = 255;
			g_iTrailcolor[client][1] = 255;
			g_iTrailcolor[client][2] = 0;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {orange}yellow.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 4:
		{
			g_iTrailcolor[client][0] = 0;
			g_iTrailcolor[client][1] = 255;
			g_iTrailcolor[client][2] = 0;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {green}green.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 5:
		{
			g_iTrailcolor[client][0] = 0;
			g_iTrailcolor[client][1] = 0;
			g_iTrailcolor[client][2] = 255;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {blue}blue.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 6:
		{
			g_iTrailcolor[client][0] = 127;
			g_iTrailcolor[client][1] = 0;
			g_iTrailcolor[client][2] = 127;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {purple}purple.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 7:
		{
			g_iTrailcolor[client][0] = 255;
			g_iTrailcolor[client][1] = 0;
			g_iTrailcolor[client][2] = 127;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {pink}pink.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 8:
		{
			g_iTrailcolor[client][0] = 0;
			g_iTrailcolor[client][1] = 255;
			g_iTrailcolor[client][2] = 255;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {lightblue}cyan.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
		case 9:
		{
			g_iTrailcolor[client][0] = 255;
			g_iTrailcolor[client][1] = 255;
			g_iTrailcolor[client][2] = 255;
			g_bTrail[client] = true;
			CreateTrails(client);
			if (!spawned) {
				CPrintToChat(client, "%s Your trail color is {default}white.", CHAT_BANNER);
				CPrintToChat(client, "%s You must stand still to apply the new trail.", CHAT_BANNER);
			}
		}
	}
}

void CreateTrails(int client)
{
	g_TrailTimer[client] = CreateTimer(0.1, Timer_CreateTrail, GetClientSerial(client));
}

void ResetTimer(Handle hTimer)
{
	KillTimer(hTimer);
	hTimer = null;
}

stock bool bVectorsEqual(float[3] v1, float[3] v2)
{
	return (v1[0] == v2[0] && v1[1] == v2[1] && v1[2] == v2[2]);
}

stock bool IsValidClient(int client)
{
	if (!(0 < client <= MaxClients))return false;
	if (!IsClientConnected(client))return false;
	if (!IsClientInGame(client))return false;
	if (IsFakeClient(client))return false;
	return true;
}

UpdateConVars()
{
	g_fCvar_Trail_Duration = GetConVarFloat(g_hCvar_Trail_Duration);
	g_iCvar_Trail_Fade_Duration = GetConVarInt(g_hCvar_Trail_Fade_Duration);
	g_fCvar_Trail_Width = GetConVarFloat(g_hCvar_Trail_Width);
	g_fCvar_Trail_End_Width = GetConVarFloat(g_hCvar_Trail_End_Width);
	g_iCvar_Trail_Per_Round = GetConVarInt(g_hCvar_Trail_Per_Round);
} 