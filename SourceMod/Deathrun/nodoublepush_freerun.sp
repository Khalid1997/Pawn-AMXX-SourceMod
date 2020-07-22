#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
//#include <weapons>

#pragma semicolon 1
#define PLUGIN_VERSION "2.4.5"

stock bool:Entity_LockStatus(entity, bool bLockStatus) {
	
	return bool:GetEntProp(entity, Prop_Data, "m_bLocked", 1) == bLockStatus;
}

stock Entity_Lock(entity, bool bLock) {
	SetEntProp(entity, Prop_Data, "m_bLocked", _:bLock, 1);
}

new const String:g_szButtonEnts[][] = {
	"func_button",
	"func_rot_button"
};
/*****************************************************************


 G L O B A L   V A R I A B L E S


*****************************************************************/
new Handle:g_cvar_Version = INVALID_HANDLE;
new Handle:g_cvar_Enable = INVALID_HANDLE;
new Handle:g_cvar_Time = INVALID_HANDLE;
new Handle:g_cvar_Deathrun = INVALID_HANDLE;
//new Handle:g_cvar_TriggerTime = INVALID_HANDLE;
ConVar g_cvar_freerun_allowtime;

new Handle:g_hLockedButtons = INVALID_HANDLE;
Handle g_hLockedButtonsTimerHandle = INVALID_HANDLE;

bool g_bAllowFree = false;
bool g_bFreeRun = false;
char g_szPrefix[] = "[DeahtRun]";

float g_flRoundStartTime;

/*****************************************************************


 P L U G I N   I N F O


*****************************************************************/
public Plugin:myinfo = 
{
	name = "No Double Push & Free Run.",
	author = "Chanz",
	description = "Locks func_button and func_rot_button entities for a certain amount of time, to prevent double pushing on deathrun or other maps & free run for deathrun",
	version = PLUGIN_VERSION,
	url = "Edited plugin, no URL"
};

/*****************************************************************


 F O R W A R D S


*****************************************************************/
public OnPluginStart(){
	
	g_cvar_Version = CreateConVar("sm_nodoublepush_version", PLUGIN_VERSION, "No Double Push Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(g_cvar_Version,PLUGIN_VERSION);
	g_cvar_Enable = CreateConVar("sm_nodoublepush_enable", "1","Enable or disable No Double Push",FCVAR_PLUGIN);
	g_cvar_Time = CreateConVar("sm_nodoublepush_time", "-1","The time in seconds, when the button should be unlocked again. -1 will never unlock the buttons again.",FCVAR_PLUGIN);
	g_cvar_Deathrun = CreateConVar("sm_nodoublepush_deathrun", "1","How to handle deathrun maps: 0 this plugin is always on, 1 this plugin is only on deathrun maps on, 2 this plugin is only on deathrun maps off",FCVAR_PLUGIN);
	//g_cvar_TriggerTime = CreateConVar("sm_nodoublepush_triggertime", "5.0","Only change the time of buttons if the original time (in seconds) is greater than this value (in seconds).",FCVAR_PLUGIN);
	g_cvar_freerun_allowtime = CreateConVar("sm_freerun_allow_time", "20.0", "Time to allow freerun begining from round start", FCVAR_PLUGIN);
	
	AutoExecConfig(true,"plugin.nodoublepush");
	
	g_hLockedButtons = CreateArray();
	g_hLockedButtonsTimerHandle = CreateArray();
	
	AddCommandListener(CMDListener_Say, "say");
	AddCommandListener(CMDListener_Say, "say_team");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	for (new i; i < sizeof g_szButtonEnts; i++)
	{
		HookEntityOutput(g_szButtonEnts[i], "OnIn", EntityOutput:FuncButtonOutput);
	}
}

public OnPluginEnd(){
	
	UnlockAllButtons();
}

public OnMapStart()
{
	
	ClearArray(g_hLockedButtons);
	
	if(GetConVarBool(g_cvar_Enable)){
		
		decl String:mapname[128];
		GetCurrentMap(mapname, sizeof(mapname));
		
		switch(GetConVarInt(g_cvar_Deathrun)){
			
			case 1:{
				
				if (strncmp(mapname, "dr_", 3, false) != 0 && (strncmp(mapname, "deathrun_", 9, false) != 0) && (strncmp(mapname, "dtka_", 5, false) != 0)){
					//LogMessage("sm_nodoublepush_deathrun is 1 and this is the map: %s, so this plugin is disabled.",mapname);
					SetConVarBool(g_cvar_Enable,false);
					return;
				}
			}
			case 2:{
				
				if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "dtka_", 5, false) == 0)){
					//LogMessage("sm_nodoublepush_deathrun is 2 and this is the map: %s, so this plugin is disabled.",mapname);
					SetConVarBool(g_cvar_Enable,false);
					return;
				}
			}
		}
	}
}

public void Event_RoundStart(Handle hEvent, char[] szEvName, bool bDontBroadcast)
{
	if(bDontBroadcast)
	{
		return;
	}
	
	if(g_bFreeRun)
	{
		SetFreeRunStatus(false);
	}
	
	g_flRoundStartTime = GetGameTime();

	g_bAllowFree = true;
}

public void Event_RoundEnd(Handle hEvent, char[] szEvName, bool bDontBroadcast)
{
	if(bDontBroadcast)
	{
		return;
	}
	
	g_bAllowFree = false;
	
	if(g_bFreeRun)
	{
		SetFreeRunStatus(false);
	}
	
	UnlockAllButtons();
}

public Action CMDListener_Say(client, const String:command[], args)
{

	static char szSaid[10];
	GetCmdArg(1, szSaid, sizeof szSaid);
	
	if( StrEqual(szSaid[1], "free") || StrEqual(szSaid[1], "freerun") || StrEqual(szSaid[1], "freeround") )
	{
		if(GetClientTeam(client) != CS_TEAM_T)
		{
			PrintToChat(client, " \x04%s \x01This command is only available for \x03terrorists\x01.", g_szPrefix);
			return;
		}
	
		if(!g_bAllowFree)
		{
			PrintToChat(client, " \x04%s \x01Please wait for round start before activating free run.", g_szPrefix);
			return;
		}
		
		if(g_bFreeRun)
		{
			PrintToChat(client, " \x04%s \x01It is already a free run round.", g_szPrefix);
			return;
		}
		
		float flValue = g_cvar_freerun_allowtime.FloatValue;
		if(GetGameTime() > g_flRoundStartTime + flValue )
		{
			PrintToChat(client, " \x04%s \x01Free run can only be activated whithin the first \x03%0.1f \x01seconds of the round.", g_szPrefix, flValue);
			return;
		}
		
		PrintToChatAll(" \x04%s \x01The terrorist has decided! This round will be a \x03Free Round\x01.", g_szPrefix);
		PrintToChatAll(" \x04%s \x01There will be no guns allowed!.", g_szPrefix);
		
		SetFreeRunStatus(true);
	}
}

UnlockAllButtons()
{
	new size = GetArraySize(g_hLockedButtons), index, iEnt;
	
	for(index = 0;index<size;index++){
		SetEntityRenderColor( ( iEnt = GetArrayCell(g_hLockedButtons, index) ),255,255,255,255);
		Timer_UnLockEntity(INVALID_HANDLE,iEnt);
	}
	
	for(index = 0, size = GetArraySize(g_hLockedButtonsTimerHandle) ;index<size;index++){
		CloseHandle( Handle:GetArrayCell(g_hLockedButtonsTimerHandle, index) );
	}
}

SetFreeRunStatus(bool bFreeRun)
{
	g_bFreeRun = bFreeRun;

	if(bFreeRun == true)
	{
		for (int i, iEnt; i < sizeof g_szButtonEnts; i++)
		{
			iEnt = -1;
			while( ( iEnt = FindEntityByClassname(iEnt, g_szButtonEnts[i]) ) > 0 )
			{
				// If is free run
				if(Entity_LockStatus(iEnt, true))
				{
					continue;
				}
		
				SetEntityRenderColor(iEnt, 255, 0, 0, 255);
				Entity_Lock(iEnt, true);
				
				PushArrayCell(g_hLockedButtons, iEnt);
			}
		}
		
		int iSize = GetArraySize(g_hLockedButtonsTimerHandle);
		if(iSize > 0)
		{
			for (int i = 0; i < sizeof iSize; i++)
			{
				//PushArrayCell(g_hLockedButtons, i);
				CloseHandle( Handle:GetArrayCell(g_hLockedButtonsTimerHandle, i) );
			}
		}
		
		for (new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SDKHook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			}
		}
		
		RemoveWeaponsFromAll();
	}
	
	else
	{
		
		for (new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SDKUnhook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bFreeRun)
	{
		SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

public OnClientDisconnect(client)
{
	if(g_bFreeRun)
	{
		SDKUnhook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
		SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

public Action OnWeaponCanUse(client, weapon)
{
	new String:szClassName[35]; GetEntityClassname(weapon, szClassName, sizeof szClassName);
	if (StrEqual(szClassName, "weapon_knife"))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
	//return  ? Plugin_Handled : Plugin_Continue;
}

RemoveWeaponsFromAll()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			//Client_RemoveWeaponKnife(client, "weapon_knife", true);
			
			CS_RemoveAllWeapons(client);
			CreateTimer(0.1, Timer_GiveKnife, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_GiveKnife(Handle hTimer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && g_bFreeRun)
	{
		new iEnt = GivePlayerItem(client, "weapon_knife");
		//new iEnt = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		if(iEnt > -1)
		{
			EquipPlayerWeapon(client, iEnt);
		}
	}
}

CS_RemoveAllWeapons(client, bool StripBomb = false)
{
	new weapon_index = -1;
	#define MAX_WEAPON_SLOTS 5
	
	for (new slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			if (IsValidEntity(weapon_index))
			{
				if ( ( slot == CS_SLOT_C4  && !StripBomb) )
				{
					return;
				}
				
				/*
				if(slot == CS_SLOT_KNIFE )
				{
					break;
				}*/
					
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

public EntityOutput:FuncButtonOutput(const String:output[], entity, client, Float:delay){
	
	if(!GetConVarBool(g_cvar_Enable)){
		return;
	}
	
	if(g_bFreeRun)
	{
		return;
	}
	
	//if(GetEntPropFloat(entity,Prop_Data,"m_flWait") > GetConVarFloat(g_cvar_TriggerTime)){
	{
		new Float:time = GetConVarFloat(g_cvar_Time);
		
		if(time == -1.0)
		{
			PushArrayCell(g_hLockedButtons,entity);
			SetEntityRenderColor(entity,255,0,0,255);
			Entity_Lock(entity, true);
		}
		
		else {
			
			Handle hTimer = CreateTimer(time, Timer_UnLockEntity, entity, TIMER_FLAG_NO_MAPCHANGE);
			
			PushArrayCell(g_hLockedButtons, entity);
			PushArrayCell(g_hLockedButtonsTimerHandle, hTimer);
			
			SetEntityRenderColor(entity,255,0,0,255);
			Entity_Lock(entity, true);
		}
	}
}

public Action:Timer_UnLockEntity(Handle:timer, any:entity) {
	
	if(IsValidEdict(entity))
	{
		SetEntityRenderColor(entity,255,255,255,255);
		Entity_Lock(entity, false);
	}
}





