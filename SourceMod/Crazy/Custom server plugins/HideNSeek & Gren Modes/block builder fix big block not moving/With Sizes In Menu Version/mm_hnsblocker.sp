#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <multimod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "mm_hnsblocker",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

int g_iModIndexHNS = ModIndex_Null;

public void OnPluginStart()
{
	
}

public void MultiMod_OnLoaded(bool bReload)
{
	int iMaxMods = MultiMod_GetModsCount();
	g_iModIndexHNS = ModIndex_Null;
	
	char szInfoKey[30];
	
	for (int i; i < iMaxMods; i++)
	{
		MultiMod_GetModProp(i, MultiModProp_InfoKey, szInfoKey, sizeof szInfoKey);
		
		if(StrEqual(szInfoKey, "hns", false))
		{
			g_iModIndexHNS = i;
			break;
		}
	}
	
	CheckHNSModBlock();
}

public void OnMapStart()
{
	if(!MultiMod_IsLoaded())
	{
		return;
	}
	
	CheckHNSModBlock();
}

void CheckHNSModBlock()
{
	if (g_iModIndexHNS == ModIndex_Null)
	{
		return;
	}
	
	MultiMod_SetModLock(g_iModIndexHNS, MultiModLock_Locked_Save);
}
