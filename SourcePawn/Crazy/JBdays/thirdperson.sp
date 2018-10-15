#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <thirdperson>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Client View", 
	author = PLUGIN_AUTHOR, 
	description = "!tp, !thirdperson commands", 
	version = PLUGIN_VERSION, 
	url = ""
};

#define HIDE_CROSSHAIR_CSGO 1<<8
#define HIDE_RADAR_CSGO 1<<12

ConVar ConVar_AllowTP, ConVar_ForceCamera;

ThirdPersonType g_iPlayerCurrentThirdPerson[MAXPLAYERS];
ThirdPersonType g_iPlayerChosenThirdPerson[MAXPLAYERS];
ThirdPersonType g_iPlayerLockedThirdPerson[MAXPLAYERS];

ThirdPersonType g_iGlobalLockMode = TPT_None;
Handle g_hForward_Toggle;

public int Native_SetGlobalLockMode(Handle hPlugin, int argc)
{
	g_iGlobalLockMode = GetNativeCell(1);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		SetPlayerThirdPersonChecks(i, g_iPlayerChosenThirdPerson[i]);
	}
}

public int Native_GetGlobalLockMode(Handle hPlugin, int argc)
{
	return view_as<int>(g_iGlobalLockMode);
}

public int Native_SetClientCurrentThirdPerson(Handle hPlugin, int argc)
{
	int client = GetNativeCell(1);
	return view_as<int>(SetPlayerThirdPersonChecks(client, GetNativeCell(2)));
}

public int Native_GetClientCurrentThirdPerson(Handle hPlugin, int argc)
{
	int client = GetNativeCell(1);
	return view_as<int>(g_iPlayerCurrentThirdPerson[client]);
}

public int Native_GetClientMode(Handle hPlugin, int argc)
{
	int client = GetNativeCell(1);
	return view_as<int>(g_iPlayerChosenThirdPerson[client]);
}

public int Native_SetClientMode(Handle hPlugin, int argc)
{
	int client = GetNativeCell(1);
	
	g_iPlayerChosenThirdPerson[client] = GetNativeCell(2);
	
	if(g_iPlayerChosenThirdPerson[client] == TPT_None)
	{
		g_iPlayerChosenThirdPerson[client] = TPT_FirstPerson;
	}
	
	SetPlayerThirdPersonChecks(client, g_iPlayerChosenThirdPerson[client]);
}

public int Native_GetClientLockMode(Handle hPlugin, int argc)
{
	return view_as<int>(g_iPlayerLockedThirdPerson[GetNativeCell(1)]);
}

public int Native_SetClientLockMode(Handle hPlugin, int argc)
{
	int client = GetNativeCell(1);
	g_iPlayerLockedThirdPerson[client] = GetNativeCell(2);
	SetPlayerThirdPersonChecks(client, g_iPlayerChosenThirdPerson[client]);
}

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int ErrMax)
{
	CreateNative("ThirdPerson_SetGlobalLockMode", Native_SetGlobalLockMode);
	CreateNative("ThirdPerson_GetGlobalLockMode", Native_GetGlobalLockMode);
	
	CreateNative("ThirdPerson_SetClientCurrentThirdPerson", Native_SetClientCurrentThirdPerson);
	CreateNative("ThirdPerson_GetClientCurrentThirdPerson", Native_GetClientCurrentThirdPerson);
	
	CreateNative("ThirdPerson_SetClientChosenThirdPerson", Native_SetClientMode);
	CreateNative("ThirdPerson_GetClientChosenThirdPerson", Native_GetClientMode);
	
	CreateNative("ThirdPerson_SetClientThirdPersonLockMode", Native_SetClientLockMode);
	CreateNative("ThirdPerson_GetClientThirdPersonLockMode", Native_GetClientLockMode);
	
	g_hForward_Toggle = CreateGlobalForward("ThirdPerson_OnClientChangeMode", ET_Ignore, Param_Cell, Param_Cell);
	
	RegPluginLibrary("thirdperson");
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar_AllowTP = FindConVar("sv_allow_thirdperson");
	ConVar_AllowTP.AddChangeHook(ConVarOnChange);
	ConVar_AllowTP.BoolValue = true;
	RegConsoleCmd("sm_tp", Command_Toggle);
	RegConsoleCmd("sm_thirdperson", Command_Toggle);
	
	ConVar_ForceCamera = FindConVar("mp_forcecamera");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientConnected(int client)
{
	//SetThirdPersonMode(client, TPT_FirstPerson);
	
	g_iPlayerChosenThirdPerson[client] = TPT_FirstPerson;
	g_iPlayerCurrentThirdPerson[client] = TPT_FirstPerson;
	g_iPlayerLockedThirdPerson[client] = TPT_None;
}

public void OnClientPutInServer(int client)
{
	SetThirdPersonMode(client, g_iPlayerChosenThirdPerson[client]);
}

public void ConVarOnChange(ConVar convar, char[] szOldValue, char[] szNewValue)
{
	if (ConVar_AllowTP.BoolValue == false)
	{
		ConVar_AllowTP.BoolValue = true;
	}
}

public void Event_PlayerSpawn(Event event, char[] szName, bool bDOntBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client)
	{
		SetPlayerThirdPersonChecks(client, g_iPlayerChosenThirdPerson[client]);
	}
}

public void Event_PlayerDeath(Event event, char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client)
	{
		SetThirdPersonMode(client, TPT_FirstPerson);
	}
}

public Action Command_Toggle(int client, int args)
{
	if (g_iGlobalLockMode != TPT_None || g_iPlayerLockedThirdPerson[client] != TPT_None)
	{
		CPrintToChat(client, "\x05* You can't change at this time.");
		return Plugin_Handled;
	}
	
	ThirdPersonType iNewType = TPT_ThirdPerson;
	if(g_iPlayerChosenThirdPerson[client] != TPT_FirstPerson)
	{
		iNewType = TPT_FirstPerson;
	}
	
	if( SetPlayerThirdPersonChecks(client, iNewType) )
	{
		g_iPlayerChosenThirdPerson[client] = iNewType;
		CPrintToChat(client, "\x05* You are now in '\x04%s\x05'", g_iPlayerChosenThirdPerson[client] == TPT_ThirdPerson ? "Third Person" : "First Person");
	}
	
	else
	{
		CPrintToChat(client, "\x05* Changing view mode is currently locked.");
	}

	return Plugin_Handled;
}

stock bool SetPlayerThirdPersonChecks(int client, ThirdPersonType type)
{
	if (g_iGlobalLockMode != TPT_None)
	{
		if (g_iPlayerCurrentThirdPerson[client] != g_iGlobalLockMode)
		{
			SetThirdPersonMode(client, g_iGlobalLockMode);
		}
		
		return false;
	}
	
	if (g_iPlayerLockedThirdPerson[client] != TPT_None)
	{
		if (g_iPlayerCurrentThirdPerson[client] != g_iPlayerLockedThirdPerson[client])
		{
			SetThirdPersonMode(client, g_iPlayerLockedThirdPerson[client]);
		}
		
		return false;
	}
	
	if ( g_iPlayerCurrentThirdPerson[client] != type)
	{
		SetThirdPersonMode(client, type);
	}
	
	return true;
}

void SetThirdPersonMode(int client, ThirdPersonType type)
{
	if(g_iPlayerCurrentThirdPerson[client] == TPT_ThirdPerson_Mirror && type != TPT_ThirdPerson_Mirror)
	{
		SetThirdPersonView(client, false);
	}
	
	switch (type)
	{		
		case TPT_None:
		{
			ClientCommand(client, "firstperson");
			g_iPlayerCurrentThirdPerson[client] = TPT_FirstPerson;
		}
		
		case TPT_FirstPerson:
		{
			ClientCommand(client, "firstperson");
			g_iPlayerCurrentThirdPerson[client] = TPT_FirstPerson;
		}
		
		case TPT_ThirdPerson:
		{
			ClientCommand(client, "thirdperson");
			g_iPlayerCurrentThirdPerson[client] = TPT_ThirdPerson;
		}
			
		case TPT_ThirdPerson_Mirror:
		{
			SetThirdPersonView(client, true);
			g_iPlayerCurrentThirdPerson[client] = TPT_ThirdPerson_Mirror;
		}
	}
	
	Call_StartForward(g_hForward_Toggle);
	{
		Call_PushCell(client);
		Call_PushCell(type);
		Call_Finish();
	}
}

stock void SetThirdPersonView(int client, bool third)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if (third)
	{
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SendConVarValue(client, ConVar_ForceCamera, "1");
		//SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
		
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_CROSSHAIR_CSGO);
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		
		char szValue[6];
		GetConVarString(ConVar_ForceCamera, szValue, sizeof szValue);
		SendConVarValue(client, ConVar_ForceCamera, szValue);
		//SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_CROSSHAIR_CSGO);
	}
}