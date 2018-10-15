#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#include <mystocks>
#include <cstrike>

public Plugin myinfo =  {
	name = "MybJailreak: (Heavy) Edit - Core", 
	author = "shanapu. Edit by Khalid", 
	description = "MyJailbreak - core plugin", 
	version = "1.0", 
	url = "Shitty code"
};

ConVar gc_bLogging;
ConVar gc_bShootButton;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrMax)
{
	CreateNative("MyJailbreak_ActiveLogging", Native_GetActiveLogging);
	
	CreateNative("MyJailbreak_FogOn", Native_FogOn);
	CreateNative("MyJailbreak_FogOff", Native_FogOff);
	
	CreateNative("MyJailbreak_BeaconOn", Native_BeaconOn);
	CreateNative("MyJailbreak_BeaconOff", Native_BeaconOff);
	
	RegPluginLibrary("myjailbreak_e");
}

public void OnPluginStart()
{
	// AutoExecConfig
	DirExistsEx("cfg/MyJailbreak/EventDays");
	
	AutoExecConfig_SetFile("MyJailbreak", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);
	
	gc_bLogging = AutoExecConfig_CreateConVar("sm_myjb_log", "1", "Allow MyJailbreak to log events, freekills & eventdays in logs/MyJailbreak", _, true, 0.0, true, 1.0);
	gc_bShootButton = AutoExecConfig_CreateConVar("sm_myjb_shoot_buttons", "1", "0 - disabled, 1 - allow player to trigger a map button by shooting it", _, true, 0.0, true, 1.0);
	
	Beacon_OnPluginStart();
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	char sBuffer[256];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "logs/MyJailbreak");
	DirExistsEx(sBuffer);
	
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	Fog_OnMapStart();
	Beacon_OnMapStart();
}

public void OnMapEnd()
{
	Beacon_OnMapEnd();
}

public void Event_RoundStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	if (gc_bShootButton.BoolValue)
	{
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, "func_button")) != -1)
		{
			SetEntProp(ent, Prop_Data, "m_spawnflags", GetEntProp(ent, Prop_Data, "m_spawnflags") | 512);
		}
	}
}

// Check if logging is active
public int Native_GetActiveLogging(Handle plugin, int argc)
{
	if (gc_bLogging.BoolValue)return true;
	else return false;
}


/******************************************************************************
                   STARTUP
******************************************************************************/

// Integers
int FogIndex = -1;

// Floats
float mapFogStart = 0.0;
float mapFogEnd = 150.0;
float mapFogDensity = 0.99;

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

// Magic
void DoFog()
{
	if (FogIndex != -1)
	{
		DispatchKeyValue(FogIndex, "fogblend", "0");
		DispatchKeyValue(FogIndex, "fogcolor", "0 0 0");
		DispatchKeyValue(FogIndex, "fogcolor2", "0 0 0");
		DispatchKeyValueFloat(FogIndex, "fogstart", mapFogStart);
		DispatchKeyValueFloat(FogIndex, "fogend", mapFogEnd);
		DispatchKeyValueFloat(FogIndex, "fogmaxdensity", mapFogDensity);
	}
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Start
public void Fog_OnMapStart()
{
	int ent = FindEntityByClassname(-1, "env_fog_controller");
	
	if (ent != -1)
	{
		FogIndex = ent;
	}
	else
	{
		FogIndex = CreateEntityByName("env_fog_controller");
		DispatchSpawn(FogIndex);
	}
	
	DoFog();
	
	AcceptEntityInput(FogIndex, "TurnOff");
}

/******************************************************************************
                   NATIVES
******************************************************************************/

// Set Map fog in module
public int Native_FogOn(Handle plugin, int argc)
{
	AcceptEntityInput(FogIndex, "TurnOn");
}

// Remove Map fog OFF in module
public int Native_FogOff(Handle plugin, int argc)
{
	AcceptEntityInput(FogIndex, "TurnOff");
}


/******************************************************************************
                   STARTUP
******************************************************************************/

// Console Variables
ConVar gc_fBeaconRadius;
ConVar gc_fBeaconWidth;
ConVar gc_iCTColorRed;
ConVar gc_iTColorRed;
ConVar gc_iCTColorGreen;
ConVar gc_iTColorGreen;
ConVar gc_iCTColorBlue;
ConVar gc_iTColorBlue;

// Integers
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

// Booleans
bool g_bBeaconOn[MAXPLAYERS + 1] = false;

// Floats
public void Beacon_OnPluginStart()
{
	gc_fBeaconRadius = AutoExecConfig_CreateConVar("sm_myjb_beacon_radius", "850", "Sets the radius for the beacons rings.", _, true, 50.0, true, 1500.0);
	gc_fBeaconWidth = AutoExecConfig_CreateConVar("sm_myjb_beacon_width", "25", "Sets the thickness for the beacons rings.", _, true, 10.0, true, 30.0);
	gc_iCTColorRed = AutoExecConfig_CreateConVar("sm_myjb_beacon_CT_color_red", "0", "What color to turn the CT beacons into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iCTColorGreen = AutoExecConfig_CreateConVar("sm_myjb_beacon_CT_color_green", "0", "What color to turn the CT beacons into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iCTColorBlue = AutoExecConfig_CreateConVar("sm_myjb_beacon_CT_color_blue", "255", "What color to turn the CT beacons into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_iTColorRed = AutoExecConfig_CreateConVar("sm_myjb_beacon_T_color_red", "255", "What color to turn the T beacons  into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iTColorGreen = AutoExecConfig_CreateConVar("sm_myjb_beacon_T_color_green", "0", "What color to turn the T beacons into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iTColorBlue = AutoExecConfig_CreateConVar("sm_myjb_beacon_T_color_blue", "0", "What color to turn the T beacons into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	
	// Hooks
	HookEvent("round_end", Beacon_Event_RoundEnd);
	HookEvent("player_death", Beacon_Event_PlayerTeamDeath);
	HookEvent("player_team", Beacon_Event_PlayerTeamDeath);
}

public void Beacon_Event_PlayerTeamDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")); // Get the dead clients id
	
	g_bBeaconOn[client] = false;
}

public void Beacon_Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))g_bBeaconOn[i] = false;
}

/******************************************************************************
                   FUNCTIONS
******************************************************************************/

public Action Timer_BeaconOn(Handle timer, any client)
{
	if (IsValidClient(client, true, false))
	{
		if (!g_bBeaconOn[client])
			return Plugin_Stop;
		
		float a_fOrigin[3];
		
		GetClientAbsOrigin(client, a_fOrigin);
		a_fOrigin[2] += 10;
		
		int color[4] =  { 255, 255, 255, 255 };
		
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			color[0] = gc_iCTColorRed.IntValue;
			color[1] = gc_iCTColorGreen.IntValue;
			color[2] = gc_iCTColorBlue.IntValue;
			EmitAmbientSound("buttons/blip1.wav", a_fOrigin, client, SNDLEVEL_RAIDSIREN);
		}
		
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			color[0] = gc_iTColorRed.IntValue;
			color[1] = gc_iTColorGreen.IntValue;
			color[2] = gc_iTColorBlue.IntValue;
			EmitAmbientSound("buttons/button1.wav", a_fOrigin, client, SNDLEVEL_RAIDSIREN);
		}
		
		TE_SetupBeamRingPoint(a_fOrigin, 10.0, gc_fBeaconRadius.FloatValue, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, gc_fBeaconWidth.FloatValue, 0.5, color, 5, 0);
		TE_SendToAll();
		//	GetClientEyePosition(client, a_fOrigin);
	}
	
	return Plugin_Continue;
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Start
public void Beacon_OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/light_glow02.vmt");
}

// Start
public void Beacon_OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))g_bBeaconOn[i] = false;
}

public void OnAvailableLR(int Announced)
{
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))g_bBeaconOn[i] = false;
}

/******************************************************************************
                   NATIVES
******************************************************************************/

// Activate Beacon on client & set interval
public int Native_BeaconOn(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	float interval = GetNativeCell(2);
	
	if (!g_bBeaconOn[client])
	{
		g_bBeaconOn[client] = true;
		CreateTimer(interval, Timer_BeaconOn, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

// Remove beacon from client
public int Native_BeaconOff(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	
	g_bBeaconOn[client] = false;
}

/* ---------------------------------------------------------------------------------- */