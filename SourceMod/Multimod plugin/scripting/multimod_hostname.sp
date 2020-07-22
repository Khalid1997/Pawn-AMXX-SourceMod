#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION MM_VERSION_STR

#include <sourcemod>
#include <multimod>

public Plugin myinfo = 
{
	name = "MultiMod Plugin: HostName",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "No URL"
};

ConVar	ConVar_MultiMod_HostName, 
		ConVar_Engine_HostName;
bool g_bAllowEngineConVarChange, g_bAllowFirst = true;

Handle g_hTimerHandle;

char KEY_TIME_LEFT[] = "{timeleft}";
char KEY_CURRENT_MOD[] =  "{currentmod}";
char KEY_NEXT_MOD[] =  "{nextmod}";

public void OnPluginStart()
{
	ConVar_MultiMod_HostName = CreateConVar("mm_hostname", "", "Sets hostname with additional keys:\n\
	{currentmod} - Current mod\n\
	{nextmod} - Nextmod name\n\
	{timeleft} - Timeleft");
	ConVar_Engine_HostName = FindConVar("hostname"); //CreateConVar("hostname", "");
	
	HookConVarChange(ConVar_MultiMod_HostName, ConVar_ChangeCallback);
	HookConVarChange(ConVar_Engine_HostName, ConVar_ChangeCallback);
	
	AutoExecConfig(true, "multimod_hostname");
}

public void OnMapStart()
{
	//ServerCommand("exec sourcemod/multimod_hostname.cfg");
	char szHostName[256];
	GetConVarString(ConVar_MultiMod_HostName, szHostName, sizeof szHostName);
	
	if(g_hTimerHandle != null)
	{
		delete g_hTimerHandle;
		g_hTimerHandle = null;
	}
		
	if(StrContains(szHostName, KEY_TIME_LEFT, true) != -1)
	{
		g_hTimerHandle = CreateTimer(1.0, Timer_ChangeHostName, INVALID_HANDLE, TIMER_REPEAT);
	}
		
	SetHostName(szHostName);
}

public void ConVar_ChangeCallback(ConVar Var, const char[] szOldValue, const char[] szNewValue)
{
	if(Var == ConVar_MultiMod_HostName)
	{
		if(g_hTimerHandle != null)
		{
			delete g_hTimerHandle;
			g_hTimerHandle = null;
		}
		
		if(StrContains(szNewValue, KEY_TIME_LEFT, true) != -1)
		{
			g_hTimerHandle = CreateTimer(1.0, Timer_ChangeHostName, INVALID_HANDLE, TIMER_REPEAT);
		}
		
		SetHostName(szNewValue);
		//g_bAllowEngineConVarChange = true
	}
		
	else if(Var == ConVar_Engine_HostName)
	{
		if(g_bAllowFirst)
		{
			g_bAllowFirst = false;
			return;
		}
		
		if(!StrEqual(szOldValue, szNewValue, true))
		{
			if(g_bAllowEngineConVarChange)
			{
				g_bAllowEngineConVarChange = false;
				return;
			}
		}
		
		g_bAllowEngineConVarChange = true;
		SetConVarString(ConVar_Engine_HostName, szOldValue);
	}
}

public Action Timer_ChangeHostName(Handle hTimer)
{
	char szHostName[256];
	GetConVarString(ConVar_MultiMod_HostName, szHostName, sizeof szHostName);
	
	SetHostName(szHostName);
}

void SetHostName(const char[] szHostName)
{
	char szFormatHostName[256];
	
	FormatEx(szFormatHostName, sizeof szFormatHostName, szHostName);
	
	int iTimeLeft;
	if(GetMapTimeLeft(iTimeLeft) && iTimeLeft >= 0)
	{
		char szTimeLeftString[256];
		Format(szTimeLeftString, sizeof szTimeLeftString, "Timeleft: %02d:%02d", (iTimeLeft / 60), (iTimeLeft % 60));
		ReplaceString(szFormatHostName, sizeof szFormatHostName, KEY_TIME_LEFT, szTimeLeftString, true);
	}
	
	else
	{
		ReplaceString(szFormatHostName, sizeof szFormatHostName, KEY_TIME_LEFT, "", true);
	}
	
	int iModId;
	char szModName[MM_MAX_MOD_PROP_LENGTH];
	if( ( iModId = MultiMod_GetCurrentModId() ) != ModIndex_Null )
	{
		MultiMod_GetModProp(iModId, MultiModProp_Name, szModName, sizeof szModName);
		ReplaceString(szFormatHostName, sizeof szFormatHostName, KEY_CURRENT_MOD, szModName);
	}
	
	else
	{
		ReplaceString(szFormatHostName, sizeof szFormatHostName, KEY_CURRENT_MOD, "");
	}
	
	if( ( iModId = MultiMod_GetNextModId() ) != ModIndex_Null )
	{
		MultiMod_GetModProp(iModId, MultiModProp_Name, szModName, sizeof szModName);
		ReplaceString(szFormatHostName, sizeof szFormatHostName, KEY_NEXT_MOD, szModName);
	}
	
	else
	{
		ReplaceString(szFormatHostName, sizeof szFormatHostName, KEY_NEXT_MOD, "Not Chosen");
	}
	
	// Keep before changing convar;
	g_bAllowEngineConVarChange = true;
	SetConVarString(ConVar_Engine_HostName, szFormatHostName);
}