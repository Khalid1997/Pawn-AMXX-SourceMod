#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

public Plugin myinfo = 
{
	name = "Name of plugin here!",
	author = "Your name here!",
	description = "Brief description of plugin functionality here!",
	version = PLUGIN_VERSION,
	url = "Your website URL/AlliedModders profile URL"
};

bool g_bEnabled;

public void OnPluginStart()
{
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	CreateConVar("sm_pluginnamehere_version", PLUGIN_VERSION, "Standard plugin version ConVar. Please don't change me!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("weapon_fire", Event_WeaponFire);
	RegAdminCmd("sm_dis", ConCmd_Distance, ADMFLAG_ROOT);
}

public Action ConCmd_Distance(int client, int args)
{
	g_bEnabled = !g_bEnabled;
	
	ReplyToCommand(client, "Distance Output: %s", g_bEnabled ? "Enabled" : "Disabled");
	
	return Plugin_Handled;
}

public void Event_WeaponFire(Event event, const char[] szName, bool bDont)
{
	if(!g_bEnabled)
	{
		return;
	}
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	/**
	 * @note Precache your models, sounds, etc. here!
	 * Not in OnConfigsExecuted! Doing so leads to issues.
	 */
	 
	float trace_start[3], trace_angle[3], trace_end[3];
	GetClientEyePosition(client, trace_start);
	GetClientEyeAngles(client, trace_angle);
	GetAngleVectors(trace_angle, trace_end, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(trace_end, trace_end); // end = normal
	
	for (int i = 0; i < 3; i++)
	{
		trace_end[i] = trace_start[i] + trace_end[i] * 9999.0;
	}
	
	TR_TraceRayFilter(trace_start, trace_end, CONTENTS_SOLID | CONTENTS_WINDOW, RayType_EndPoint, TraceFilter_Callback, client);
	
	if (!TR_DidHit(INVALID_HANDLE)) {
		PrintToChatAll("??");
		return;
	}	
	
	TR_GetEndPosition(trace_end, INVALID_HANDLE);
	
	trace_end[2] = trace_start[2];
	
	PrintToChatAll("Distance = %0.2f", FloatAbs(GetVectorDistance(trace_start, trace_end) - 16.0));
}
	
	public bool TraceFilter_Callback(int iEnt, int iContentMask, int client)
{
	if (iEnt == client)
	{
		return false;
	}
	
	return true;
}
