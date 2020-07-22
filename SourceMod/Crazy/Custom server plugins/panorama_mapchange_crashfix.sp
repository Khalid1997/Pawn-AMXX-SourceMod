#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin myinfo =
{
    name = "Panorama Map crash fix test",
    author = "pokemonmaster",
    description = "",
    version = "1.0",
    url = "forums.alliedmods.net"
};

StringMap g_Trie_ReconnectingClients;

public void OnPluginStart()
{
	g_Trie_ReconnectingClients = new StringMap();
	HookEvent("player_disconnect", Event_PlayerDisconnect);	// Use events because map change doesnt reset time in server.
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientAuthorized(i))
		{
			OnClientAuthorized(i, "");
		}
	}
}

public void OnClientAuthorized(int client, const char[] szAuth)
{
	PrintToServer("-- Client Authorized %N (%d)", client, client);
	char szIP[30];
	GetClientIP(client, szIP, sizeof szIP, false);
	SetTrieValue(g_Trie_ReconnectingClients, szIP, true);
}

public void OnClientConnected(int client)
{
	char szIP[25], iValue;
	GetClientIP(client, szIP, sizeof szIP, false);
	
	//LogToFile("aconnections.txt", "Client Connected %N (%d): %s", client, client, szIP);
	
	if(GetTrieValue(g_Trie_ReconnectingClients, szIP, iValue))
	{
		PrintToServer("-- Reconnecting client %N (%d) connected!", client, client);
		ClientCommand(client, "retry");
		return;
	}
	
	PrintToServer("-- Client %N (%d) connected!", client, client);
}

public void Event_PlayerDisconnect(Event hEvent, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!client)
	{
		return;
	}
	
	char szIP[25];
	GetClientIP(client, szIP, sizeof szIP, false);
	PrintToServer("-- Client Disconnect ---- Event - %N (%d)", client, client);
	RemoveFromTrie(g_Trie_ReconnectingClients, szIP);
}