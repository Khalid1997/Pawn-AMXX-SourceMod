#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEntityOutput("env_beam", "OnTouchedByEntity", MineLaser_OnTouch);
}


public Action:ActivateTimer(Handle:timer, Handle:data)
{
	if (!IsValidEntity(ent)) { 
		PrintToServer("Invalid Ent");
		return Plugin_Stop;
	}

	// enable touch trigger and increase brightness
	DispatchKeyValue(ent_laser, "TouchType", "4");
	DispatchKeyValue(ent_laser, "renderamt", "255");
}

int CreateLaser(Float:start[3], Float:end[3])
{
	new ent = CreateEntityByName("env_beam");

	if (ent != -1)
	{
		TeleportEntity(ent, start, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(ent, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
		SetEntPropVector(ent, Prop_Data, "m_vecEndPos", end);
		DispatchKeyValue(ent, "targetname", g_szMineLaserTargetName);
		DispatchKeyValue(ent, "rendercolor", g_szMineLaserColor);
		DispatchKeyValue(ent, "renderamt", "67");
		DispatchKeyValue(ent, "decalname", "Bigshot");
		DispatchKeyValue(ent, "life", "0");
		DispatchKeyValue(ent, "TouchType", "0");
		DispatchSpawn(ent);
		SetEntPropFloat(ent, Prop_Data, "m_fWidth", 1.0);
		SetEntPropFloat(ent, Prop_Data, "m_fEndWidth", 1.0);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "TurnOn");
	}
	
	return ent;
}

public void MineLaser_OnTouch(const char[] output, int iEnt, int iActivator, float delay)
//public Action SDKCallback_TouchPost_MineLaser(int iEnt, int iActivator)
{
	PrintToServer("Touch");
	SetEntProp(iEnt, Prop_Data, "m_nNextThinkTick", GetGameTickCount());
	
	char szTargetName[32];
	GetEntPropString(iEnt, Prop_Data, "m_iName", szTargetName, sizeof szTargetName);
	
	if(!StrEqual(szTargetName, g_szMineLaserTargetName))
	{
		PrintToServer("Fail #1");
		return;
	}

	if (!IsPlayer(iActivator))
	{
		PrintToServer("Fail #2");
		return;
	}
	
	if (!IsPlayerAlive(iActivator))
	{
		PrintToServer("Fail #3");
		return;
	}
	
	float vOrigin[3];
	GetClientAbsOrigin(iActivator, vOrigin);
	EmitSoundToAll(SOUND, iActivator);
	
	PrintToServer("Touch Sound played");
}
