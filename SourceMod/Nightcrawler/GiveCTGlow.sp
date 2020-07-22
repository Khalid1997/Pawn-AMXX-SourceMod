#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

//#define HEADPROP "models/player/holiday/facemasks/facemask_tf2_spy_model.mdl"
//#define HEADATTACH "facemask"

#define EF_BONEMERGE                (1 << 0)
#define NORMATTACH "primary"

public Plugin myinfo = 
{
	name = "Name of plugin here!", 
	author = "Your name here!", 
	description = "Brief description of plugin functionality here!", 
	version = PLUGIN_VERSION, 
	url = "Your website URL/AlliedModders profile URL"
};

ConVar sv_force_transmit_players = null;
int g_iGlowEntity[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	sv_force_transmit_players = FindConVar("sv_force_transmit_players");
	HookConVarChange(sv_force_transmit_players, ConVarChangedCallback);
}

public void OnMapStart()
{
	sv_force_transmit_players.SetString("1", true, false);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			SetupPlayerSpawn(i);
		}
	}
}

public void ConVarChangedCallback(ConVar convar, char[] szNewValue, char[] szOldValue)
{
	if(sv_force_transmit_players.IntValue != 1)
	{
		sv_force_transmit_players.IntValue = 1;
	}
}

public void Event_PlayerDeath(Event event, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	DestroyGlowEntity(client);
}

public void OnClientDisconnect(int client)
{
	DestroyGlowEntity(client);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			DestroyGlowEntity(i);
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetupPlayerSpawn(client);
}

void SetupPlayerSpawn(int client)
{
	DestroyGlowEntity(client);
	
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		return;
	}
	
	int iEntity = CreateGlowEntity(client);
	
	if (iEntity <= 0)
	{
		return;
	}
	
	if (SDKHookEx(iEntity, SDKHook_SetTransmit, SDKCallback_SetTransmit))
	{
		SetupGlow(iEntity, { 80, 128, 128, 0 } );
	}
	
	g_iGlowEntity[client] = EntIndexToEntRef(iEntity);
}

public Action SDKCallback_SetTransmit(int entity, int client)
{
	if (GetClientTeam(client) == CS_TEAM_T)
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

void SetupGlow(int entity, int color[4])
{
	static int offset;
	// Get sendprop offset for prop_dynamic_override
	if (!offset && (offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1) {
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}
	
	// Enable glow for custom skin
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 10000.0);
	
	// So now setup given glow colors for the skin
	for (int i = 0; i < 3; i++)
	{
		SetEntData(entity, offset + i, color[i], _, true);
	}
}

void DestroyGlowEntity(int client)
{
	int index = EntRefToEntIndex(g_iGlowEntity[client]);
	
	if (index > MaxClients && IsValidEntity(index))
	{
		SetEntProp(index, Prop_Send, "m_bShouldGlow", false);
		AcceptEntityInput(index, "FireUser1");
	}
	
	g_iGlowEntity[client] = INVALID_ENT_REFERENCE;
}

public int CreatePlayerModelProp(int client, char[] sModel, char[] attachment, bool bonemerge, float scale)
{
	int skin = CreateEntityByName("prop_dynamic_glow");
	DispatchKeyValue(skin, "model", sModel);
	DispatchKeyValue(skin, "solid", "0");
	DispatchKeyValue(skin, "fademindist", "1");
	DispatchKeyValue(skin, "fademaxdist", "1");
	DispatchKeyValue(skin, "fadescale", "2.0");
	SetEntProp(skin, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(skin);
	SetEntityRenderMode(skin, RENDER_GLOW);
	SetEntityRenderColor(skin, 0, 0, 0, 0);
	
	if (bonemerge)
	{
		SetEntProp(skin, Prop_Send, "m_fEffects", EF_BONEMERGE);
	}
	
	if (scale != 1.0)
	{
		SetEntPropFloat(skin, Prop_Send, "m_flModelScale", scale);
	}
	
	SetVariantString("!activator");
	AcceptEntityInput(skin, "SetParent", client, skin);
	SetVariantString(attachment);
	AcceptEntityInput(skin, "SetParentAttachment", skin, skin, 0);
	SetVariantString("OnUser1 !self:Kill::0.1:-1");
	AcceptEntityInput(skin, "AddOutput");
	
	return skin;
}

int CreateGlowEntity(int client)
{
	char model[PLATFORM_MAX_PATH];
	char attachment[PLATFORM_MAX_PATH];
	int skin = -1;
	float scale = 1.0;
	
	attachment = NORMATTACH;
	
	GetClientModel(client, model, sizeof(model));
	skin = CreatePlayerModelProp(client, model, attachment, true, scale);
	
	return skin;
}
