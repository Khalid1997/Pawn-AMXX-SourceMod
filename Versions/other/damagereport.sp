#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

public Plugin myinfo = 
{
	name = "Damage report test",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

//#define OLD_DAMAGE_REPORT

new const String:g_szPrefix[] = "[TEST] ";

// 					 Attacker 	||	 Victim
float	g_flDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int 	g_iHits[MAXPLAYERS + 1][MAXPLAYERS + 1];
int		g_iKiller[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("round_start", EventHook_RoundStart, EventHookMode_Post);
	HookEvent("player_death", EventHook_PlayerDeath, EventHookMode_Post);
	
	AddCommandListener(ClCmd_Say, "say");
	AddCommandListener(ClCmd_Say, "say_team");
}

public Action ClCmd_Say(int client, const char[] szCommand, int iArgCount)
{
	if(IsPlayerAlive(client))
	{
		return;
	}
	
	char szCmd[10];
	GetCmdArg(1, szCmd, sizeof szCmd);
	
	if(StrEqual(szCmd, ".dmg", false))
	{
		PrintDamageReport(client);
	}
}

public void EventHook_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1, j; i <= MaxClients; i++)
	{
		for(j = 1; j <= MaxClients; j++)
		{
			g_flDamage[i][j] = 0.0;
			g_iHits[i][j] = 0;
			g_iKiller[i] = 0;
		}
	}
}

public void EventHook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = ( GetClientOfUserId( GetEventInt(event, "userid") ) );
	int iKiller = ( GetClientOfUserId( GetEventInt(event, "attacker") ) );
	g_iKiller[client] = iKiller;
	
	if(!client)
	{
		return;
	}
	
	PrintDamageReport(client);
}

PrintDamageReport(client)
{
	static int TeamBit = (1<<( CS_TEAM_CT + 1 )) | (1<<( CS_TEAM_T + 1 ));
	
	PrintToChat(client, " %s-------- Damage Report --------", g_szPrefix);
	
	char iColorLeft, iColorRight;
	int iClientTeamBit;
	int iOtherTeamBit;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) )
		{
			iClientTeamBit	= (1<< (GetClientTeam(client) + 1) );
			iOtherTeamBit	= (1<< (GetClientTeam(i) + 1) );
			
			if( !(iClientTeamBit & TeamBit && iOtherTeamBit & TeamBit && iClientTeamBit != iOtherTeamBit) )
			{
				continue;
			}
			
		#if defined OLD_DAMAGE_REPORT
		
			if(g_flDamage[client][i] > 0.0)	iColorLeft = '\x04';
			else	iColorLeft = '\x01';
			
			if(g_flDamage[i][client] > 0.0)	iColorRight = '\x07';
			else	iColorRight = '\x01';
			
		#else
			
			if(g_iKiller[i] == client)	iColorLeft = '\x04';
			else	iColorLeft = '\x01';
			
			if(g_iKiller[client] == i)	iColorRight = '\x07';
			else	iColorRight = '\x01';
			
		#endif	
			
			PrintToChat(client, " %s\
			%s[\x01%d in %d%s] \
			\x01<-> \
			%s[\x01%d in %d%s] \
			\x01- %d HP %N", 
			g_szPrefix,
			
			iColorLeft,
			RoundFloat(g_flDamage[client][i]),
			g_iHits[client][i],
			iColorLeft,
			
			iColorRight,
			RoundFloat(g_flDamage[i][client]),
			g_iHits[i][client],
			iColorRight,
			
			GetClientHealth(i),
			i
			);
		}
	}
}

public void OnClientPutInServer(client)
{
	
}

public void OnClientDisconnect(client)
{
	
}

public Action SDKCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	g_flDamage[attacker][victim] += damage;
	g_iHits[attacker][victim]++;
}
