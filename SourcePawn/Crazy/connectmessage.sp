#include <sourcemod>
#include <geoip>

ConVar h_connectmsg,
	h_disconnectmsg;

int g_iConnectMessageEnabled,
	g_iDisconnectMessageEnabled;

public Plugin myinfo = 
{
	name = "Connect MSG",
	author = "Crazy",
	description = "Provides Info of the player when he joins",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{	
	HookConVarChange((h_connectmsg = CreateConVar("sm_connectmsg", "1", "Shows a connect message in the chat once a player joins.", FCVAR_NOTIFY | FCVAR_DONTRECORD)), ConVar_OnChanged);
	HookConVarChange((h_disconnectmsg = CreateConVar("sm_disconnectmsg", "1", "Shows a disconnect message in the chat once a player leaves.", FCVAR_NOTIFY | FCVAR_DONTRECORD)), ConVar_OnChanged);
	
	g_iConnectMessageEnabled = 1;
	g_iDisconnectMessageEnabled = 1;
}

public void OnMapStart()
{
	AutoExecConfig(true, "connect_message");
}

public void OnClientPutInServer(int client)
{
	if(!g_iConnectMessageEnabled)
	{
		return;
	}
	
	char name[MAX_NAME_LENGTH], authid[35], IP[14], Country[99];
	GetClientName(client, name, sizeof(name));		
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));	
	GetClientIP(client, IP, sizeof(IP), true);
			
	if(!GeoipCountry(IP, Country, sizeof Country))
	{
		Country = "Unknown Country";
	}
		
	PrintToChatAll(" \x04[CONNECT]\x03 %s (%s) has joined the server from [%s]", name, authid, Country);

}

public void OnClientDisconnect(int client)
{
	if(!g_iDisconnectMessageEnabled)
	{
		return;
	}
	
	char name[MAX_NAME_LENGTH], authid[35], IP[14], Country[99];
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
	GetClientIP(client, IP, sizeof(IP), true);
		
	if(!GeoipCountry(IP, Country, sizeof Country))
	{
		Country = "Unknown Country";
	}
    
	PrintToChatAll(" \x04[DISCONNECT]\x03 %s (%s) has left the server from [%s]", name, authid, Country);
}

public void ConVar_OnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PrintToServer("************* New Value: %s %d", newValue, !!StringToInt(newValue));
	if(convar == h_connectmsg)
	{
		g_iConnectMessageEnabled = !!StringToInt(newValue);
	}
	
	else if(convar == h_disconnectmsg)
	{
		g_iDisconnectMessageEnabled = !!StringToInt(newValue);
	}
}