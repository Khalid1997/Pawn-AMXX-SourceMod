#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <vipsys>
#include <tvip>

#pragma semicolon 1

#define PLUGIN_VERSION	 "2.4"

new blockCommand;
new g_Collision;
new Handle:cvar_adverts = INVALID_HANDLE;
new Handle:cvar_bhop = INVALID_HANDLE;
new Handle:cvar_dm = INVALID_HANDLE;
new bool:g_IsGhost[MAXPLAYERS + 1];
new bool:g_dm_redie[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "VIP Feature: CS:GO Redie", 
	author = "Pyro, originally by MeoW", 
	description = "Return as a ghost after you died.", 
	version = PLUGIN_VERSION, 
	url = "http://steamcommunity.com/profiles/76561198051084603"
};

bool g_bIsVIP[MAXPLAYERS];

public OnPluginStart()
{
	HookEvent("round_end", Event_Round_End, EventHookMode_Pre);
	HookEvent("round_start", Event_Round_Start, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_death", Event_Player_Death);
	RegConsoleCmd("sm_redie", Command_Redie);
	
	cvar_bhop = CreateConVar("sm_redie_bhop", "0", "If enabled, ghosts will be able to autobhop by holding space.");
	cvar_dm = CreateConVar("sm_redie_dm", "0", "If enabled, using redie while alive will make you a ghost next time you die.");
	g_Collision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");
	AddNormalSoundHook(OnNormalSoundPlayed);
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem("redie", "Redie (Allow you to walk when dead)", MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenuCallback_Redie, 1);
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem("redie");
}

public void OnClientPutInServer(int client)
{
	g_bIsVIP[client] = false;
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void tVip_OnClientLoadedPost(int client, bool bIsVIP)
{
	VIPSys_Client_OnCheckVIP(client, bIsVIP);
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	g_bIsVIP[client] = bIsVIP;
}

public int VIPMenuCallback_Redie(Menu menu, char[] szInfo, MenuAction action, int param1, int param2)
{
	if (!g_bIsVIP[param1])
	{
		PrintToChat(param1, "* You are not a VIP to use this command.");
	}
	
	else
	{
		DoRedieStuff(param1);
	}
}

public OnClientPostAdminCheck(client)
{
	g_IsGhost[client] = false;
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	blockCommand = false;
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	blockCommand = true;
	new ent = MaxClients + 1;
	while ((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, brushentCollide);
		SDKHookEx(ent, SDKHook_StartTouch, brushentCollide);
		SDKHookEx(ent, SDKHook_Touch, brushentCollide);
	}
	while ((ent = FindEntityByClassname(ent, "func_door")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, brushentCollide);
		SDKHookEx(ent, SDKHook_StartTouch, brushentCollide);
		SDKHookEx(ent, SDKHook_Touch, brushentCollide);
	}
	while ((ent = FindEntityByClassname(ent, "func_button")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, brushentCollide);
		SDKHookEx(ent, SDKHook_StartTouch, brushentCollide);
		SDKHookEx(ent, SDKHook_Touch, brushentCollide);
	}
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
}

public Action:brushentCollide(entity, other)
{
	if 
		(
		(0 < other && other <= MaxClients) && 
		(g_IsGhost[other]) && 
		(IsClientInGame(other))
		)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (IsValidEntity(victim))
	{
		if (g_IsGhost[victim])
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	if (g_IsGhost[client])
	{
		g_IsGhost[client] = false;
	}
}

public Action:Hook_SetTransmit(entity, client)
{
	if (g_IsGhost[entity] && entity != client)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_dm_redie[client])
	{
		g_dm_redie[client] = false;
		CreateTimer(0.1, bringback, client);
	}
	else
	{
		if (GetClientTeam(client) == 3)
		{
			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "item_defuser")) != -1)
			{
				if (IsValidEntity(ent))
				{
					AcceptEntityInput(ent, "kill");
				}
			}
		}
	}
}

public Action:bringback(Handle:timer, any:client)
{
	if (GetClientTeam(client) > 1)
	{
		g_IsGhost[client] = false;
		CS_RespawnPlayer(client);
		g_IsGhost[client] = true;
		new weaponIndex;
		for (new i = 0; i <= 3; i++)
		{
			if ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, weaponIndex);
				RemoveEdict(weaponIndex);
			}
		}
		SetEntProp(client, Prop_Send, "m_lifeState", 1);
		SetEntData(client, g_Collision, 2, 4, true);
		SetEntProp(client, Prop_Data, "m_ArmorValue", 0);
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
		PrintToChat(client, "\x01[\x03Redie\x01] \x04You are now a ghost.");
	}
	else
	{
		PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be on a team.");
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (g_IsGhost[client])
	{
		buttons &= ~IN_USE;
		if (GetConVarInt(cvar_bhop))
		{
			if (buttons & IN_JUMP)
			{
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1 && !(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND))
				{
					SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
					buttons &= ~IN_JUMP;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_Redie(client, args)
{
	if (!g_bIsVIP[client])
	{
		return Plugin_Handled;
	}
	
	DoRedieStuff(client);
	return Plugin_Handled;
}

void DoRedieStuff(int client)
{ 
	if (!IsPlayerAlive(client))
	{
		if (blockCommand)
		{
			if (GetClientTeam(client) > 1)
			{
				g_IsGhost[client] = false; //Allows them to pick up knife and gun to then have it removed from them
				CS_RespawnPlayer(client);
				g_IsGhost[client] = true;
				new weaponIndex;
				for (new i = 0; i <= 3; i++)
				{
					if ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
					{
						RemovePlayerItem(client, weaponIndex);
						RemoveEdict(weaponIndex);
					}
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 1);
				SetEntData(client, g_Collision, 2, 4, true);
				SetEntProp(client, Prop_Data, "m_ArmorValue", 0);
				SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You are now a ghost.");
			}
			else
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be on a team.");
			}
		}
		else
		{
			PrintToChat(client, "\x01[\x03Redie\x01] \x04Please wait for the new round to begin.");
		}
	}
	else
	{
		if (GetConVarInt(cvar_dm))
		{
			if (g_dm_redie[client])
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You will no longer be brought back as a ghost next time you die.");
			}
			else
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You will be brought back as a ghost next time you die.");
			}
			g_dm_redie[client] = !g_dm_redie[client];
		}
		else
		{
			PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be dead to use redie.");
		}
	}
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (g_IsGhost[client])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:advert(Handle:timer)
{
	if (GetConVarInt(cvar_adverts))
	{
		PrintToChatAll("\x01[\x03Redie\x01] \x04This server is running !redie.");
	}
	return Plugin_Continue;
}

public Action:OnSay(client, const String:command[], args)
{
	decl String:messageText[200];
	GetCmdArgString(messageText, sizeof(messageText));
	
	if (strcmp(messageText, "\"!redie\"", false) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnNormalSoundPlayed(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (entity && entity <= MaxClients && g_IsGhost[entity])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
} 