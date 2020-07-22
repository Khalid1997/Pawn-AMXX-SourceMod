#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <vipsys>
#include <sdktools>

#pragma newdecls required

#define ST_SQL 1
#define ST_FILE 0

#define SAVE_TYPE	ST_SQL

public Plugin myinfo = 
{
	name = "VIPSystem And Menu",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

#define VIP_ACCESS_FLAG	"t"
int g_iVIPAccessFlag;

bool g_bIsVIP[MAXPLAYERS];
Handle g_hForward_Client_OnCheckVIP;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int ErrMax)
{
	RegPluginLibrary("vipsys");
	
	CreateNative("VIPSys_Client_IsVIP", Native_Client_IsVIP);

	g_hForward_Client_OnCheckVIP = CreateGlobalForward("VIPSys_Client_OnCheckVIP", ET_Ignore, Param_Cell, Param_Cell);
	
	return APLRes_Success;
}

public int Native_Client_IsVIP(Handle hPlugin, int argc)
{
	return view_as<int>(g_bIsVIP[GetNativeCell(1)]);
}

public void OnPluginStart()
{
	g_iVIPAccessFlag = ReadFlagString(VIP_ACCESS_FLAG);
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	bool bOld = g_bIsVIP[client];
	g_bIsVIP[client] = false;
	
	if(bOld != false)
	{
		Call_StartForward(g_hForward_Client_OnCheckVIP);
		Call_PushCell(client);
		Call_PushCell(g_bIsVIP[client]);
		Call_Finish();
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	g_bIsVIP[client] = CheckClientVIP(client);
	//g_bIsVIP[client] = true;
	
	Call_StartForward(g_hForward_Client_OnCheckVIP);
	Call_PushCell(client);
	Call_PushCell(g_bIsVIP[client]);
	Call_Finish();
}

bool CheckClientVIP(int client)
{
	if( GetUserFlagBits(client) & (ADMFLAG_ROOT | g_iVIPAccessFlag) )
	{
		return true;
	}
	
	return false;
}
