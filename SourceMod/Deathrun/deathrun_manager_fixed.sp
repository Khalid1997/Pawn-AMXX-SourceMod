#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#define MESS  "[DeathRun] %t"
#define TEAM_T 2
#define TEAM_CT 3
#define PLUGIN_VERSION	 "1.1"

new Handle:deathrun_manager_version = INVALID_HANDLE;
new Handle:deathrun_enabled = INVALID_HANDLE;
new Handle:deathrun_swapteam  = INVALID_HANDLE;
new Handle:deathrun_block_radio = INVALID_HANDLE;
new Handle:deathrun_block_suicide = INVALID_HANDLE;
new Handle:deathrun_fall_damage = INVALID_HANDLE;
new Handle:deathrun_limit_terror  = INVALID_HANDLE;
new Handle:deathrun_block_sprays  = INVALID_HANDLE;
new Handle:deathrun_give_usp = INVALID_HANDLE;
new Handle:deathrun_min_players = INVALID_HANDLE;

ConVar ConVar_RestartGame;

new g_bRunning = false;
new g_iPlayersCount;

new g_iOldTerrId;

new Handle:g_hTimer;

public Plugin:myinfo =
{
	name = "Deathrun Manager",
	author = "Rogue",
	description = "Manages terrorists/counter-terrorists on DR servers",
	version = PLUGIN_VERSION,
	url = "http://www.surf-infamous.com/"
};

public OnPluginStart()
{
	LoadTranslations("deathrun.phrases");
	
	AddCommandListener(BlockRadio, "coverme");
	AddCommandListener(BlockRadio, "takepoint");
	AddCommandListener(BlockRadio, "holdpos");
	AddCommandListener(BlockRadio, "regroup");
	AddCommandListener(BlockRadio, "followme");
	AddCommandListener(BlockRadio, "takingfire");
	AddCommandListener(BlockRadio, "go");
	AddCommandListener(BlockRadio, "fallback");
	AddCommandListener(BlockRadio, "sticktog");
	AddCommandListener(BlockRadio, "getinpos");
	AddCommandListener(BlockRadio, "stormfront");
	AddCommandListener(BlockRadio, "report");
	AddCommandListener(BlockRadio, "roger");
	AddCommandListener(BlockRadio, "enemyspot");
	AddCommandListener(BlockRadio, "needbackup");
	AddCommandListener(BlockRadio, "sectorclear");
	AddCommandListener(BlockRadio, "inposition");
	AddCommandListener(BlockRadio, "reportingin");
	AddCommandListener(BlockRadio, "getout");
	AddCommandListener(BlockRadio, "negative");
	AddCommandListener(BlockRadio, "enemydown");
	AddCommandListener(BlockKill, "kill");
	
	AddCommandListener(Cmd_JoinTeam, "jointeam");
	
	AddTempEntHook("Player Decal", PlayerSpray);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	HookEvent("player_team", Event_PlayerEnterTeam);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	deathrun_manager_version = CreateConVar("deathrun_manager_version", PLUGIN_VERSION, "Deathrun Manager version; not changeable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	deathrun_enabled = CreateConVar("deathrun_enabled", "1", "Enable or disable Deathrun Manager; 0 - disabled, 1 - enabled");
	deathrun_swapteam = CreateConVar("deathrun_swapteam", "1", "Enable or disable automatic swapping of CTs and Ts; 1 - enabled, 0 - disabled");
	deathrun_block_radio = CreateConVar("deathrun_block_radio", "1", "Allow or disallow radio commands; 1 - radio commands are blocked, 0 - radio commands can be used");
	deathrun_block_suicide = CreateConVar("deathrun_block_suicide", "1", "Block or allow the 'kill' command; 1 - command is blocked, 0 - command is allowed");
	deathrun_fall_damage = CreateConVar("deathrun_fall_damage", "1", "Blocks fall damage given to terrorists; 1 - enabled, 0 - disabled");
	deathrun_limit_terror = CreateConVar("deathrun_limit_terror", "0", "Limits terrorist team to chosen value; 0 - disabled");
	deathrun_block_sprays = CreateConVar("deathrun_block_sprays", "0", "Blocks player sprays; 1 - enabled, 0 - disabled");
	
	deathrun_give_usp = CreateConVar("deathrun_give_usp", "1", "Give USP 1 - enabled, 0 - disabled");
	deathrun_min_players = CreateConVar("deathrun_min_players", "2");
	
	ConVar_RestartGame = FindConVar("mp_restartgame");
	
	SetConVarString(deathrun_manager_version, PLUGIN_VERSION);
	AutoExecConfig(true, "deathrun_manager");
}

public OnConfigsExecuted()
{
  decl String:mapname[128];
  GetCurrentMap(mapname, sizeof(mapname));
  
  if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "dtka_", 5, false) == 0))
  {
    LogMessage("Deathrun map detected. Enabling Deathrun Manager.");
    SetConVarInt(deathrun_enabled, 1);
  }
  else
  {
    LogMessage("Current map is not a deathrun map. Disabling Deathrun Manager.");
    //SetConVarInt(deathrun_enabled, 0);
  }
}

public OnMapStart()
{
	g_iPlayersCount = 0;
}

stock CountPlayersInTeams()
{
	new i, iTeam, iC;
	for (i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if( (iTeam = GetClientTeam(i) == CS_TEAM_T ) || iTeam == CS_TEAM_CT )
			{
				iC++;
				//PrintToServer("In Game %d", i);
			}
			
			//PrintToServer("Team %d", iTeam);
		}
		
		//else
		//{
			//PrintToServer("Not in game %d", i);
		//}
	}
	
	return iC;
}

public Event_PlayerEnterTeam(Handle hEvent, char[] szEventName, bool bDontBroadcast)
{
	//new userid = GetEventInt(hEvent, "userid");
	//new client = GetClientOfUserId(userid);
	new iTeam = GetEventInt(hEvent, "team");
	new iOldTeam = GetEventInt(hEvent, "oldteam");
	
	//PrintToServer("Joining team %d", iTeam);
	//PrintToServer("Old team %d", iOldTeam);
	
	if(iTeam == CS_TEAM_NONE)
	{
		if(iOldTeam != CS_TEAM_SPECTATOR)
		{
			--g_iPlayersCount;
		}
	}
	
	else if(iOldTeam == CS_TEAM_T || iOldTeam == CS_TEAM_CT)
	{
		if(iTeam == CS_TEAM_SPECTATOR)
		{
			++g_iPlayersCount;
		}
	}
	
	else if(iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT)
	{
		if(iOldTeam == CS_TEAM_SPECTATOR || iOldTeam == CS_TEAM_NONE)
		{
			++g_iPlayersCount;
		}
	}
	
	if(!g_bRunning)
	{
		if(g_hTimer)
		{
			CloseHandle(g_hTimer);
			g_hTimer = INVALID_HANDLE;
		}
		
		g_hTimer = CreateTimer(0.1, Timer_IsRunnable);
	}
	
	else
	{
		if(g_iPlayersCount < GetConVarInt(deathrun_min_players) )
		{
			g_bRunning = false;
			//PrintToServer("Stopped deathrun plugin");
			//PrintToServer("CountPlayersInTeam %d", CountPlayersInTeams());
		}
	}
	
	//PrintToServer("Event g_iPlayersCount = %d", g_iPlayersCount);
}

public Action:Timer_IsRunnable(Handle hTimer, any:data)
{
	if(g_bRunning)
	{
		g_hTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	//new iPlayers = CountPlayersInTeams();
	
	PrintToChatAll("TESTSTSG iPlayers = %d", g_iPlayersCount);
	if ( g_iPlayersCount >= GetConVarInt(deathrun_min_players) )
	{
		g_bRunning = true;
		ConVar_RestartGame.IntValue = 3;
		
		movect(0);
		PrintToChatAll("[DEATHRUN] Starting Game");
	}
	
	g_hTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Event_PlayerSpawn(Handle hEvent, char[] szEventName, bool bDontBroadcast)
{
	new client_id = GetEventInt(hEvent, "userid");
	new client = GetClientOfUserId(client_id);
    
	//GivePlayerItem(client, "weapon_hegrenade");
	//GivePlayerItem(client, "weapon_elite");
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		if(GetConVarInt(deathrun_give_usp) == 1)
		{
			GivePlayerItem(client, "weapon_usp_silencer");
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_iOldTerrId == client)
	{
		movect(0);
	}
	
	//PrintToServer("Dis g_iPlayersCount = %d", g_iPlayersCount);
}

public OnClientPutInServer(client)
{
	ChangeClientTeam(client, CS_TEAM_CT);
	//CreateTimer(0.1, Timer_Slot, client);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToServer("Round End");
	
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_swapteam) == 1))
	{
		for (new i=1;i<MaxClients;i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				CS_SwitchTeam(i, TEAM_CT);
			}
		}
		
		if(g_bRunning)
		{
			movect(GetRandomPlayer(TEAM_CT));
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_swapteam) == 1) && (GetClientTeam(client) == TEAM_T))
	{
		moveter(client);
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_fall_damage) == 1))
	{
		new ev_attacker = GetEventInt(event, "attacker");
		new ev_client = GetEventInt(event, "userid");
		new client = GetClientOfUserId(ev_client);
		
		if ((ev_attacker == 0) && (IsPlayerAlive(client)) && (GetClientTeam(client) == TEAM_T))
		{
			SetEntData(client, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
		}
	}
}

void movect(client)
{
  CreateTimer(1.5, movectt, client);
}

void moveter(client)
{
  CreateTimer(1.0, movet, client);
}

public Action:movectt(Handle:timer, any:client)
{
	new counter = GetRandomPlayer(TEAM_CT);
	if ((counter != -1) && (GetTeamClientCount(TEAM_T) == 0))
	{
		if(counter == g_iOldTerrId)
		{
			counter = GetRandomPlayer(TEAM_CT);
		
		}
  	
		g_iOldTerrId = counter;
		CS_SwitchTeam(counter, TEAM_T);
		PrintToChatAll(MESS, "random moved");
	}
}

public Action:movet(Handle:timer, any:client)
{
	CS_SwitchTeam(client, TEAM_CT);
	PrintToChat(client, MESS, "moved from t");
}

public Action:BlockRadio(client, const String:command[], args)
{
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_block_radio) == 1))
	{
		PrintToChat(client, MESS, "radio blocked");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:BlockKill(client, const String:command[], args)
{
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_block_suicide) == 1))
	{
		PrintToChat(client, MESS, "kill blocked");
		PrintToChat(client, MESS, "join spec");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/*  For some reason hooking this command means that you can not use the 'jointeam' command via console.
    Not that it really matters anyway, because the command is hidden. Changing team VIA the GUI
    (pressing M) still works fine though. I know of a way to 'fix' it if it's a major problem for anybody. */ 
public Action:Cmd_JoinTeam(client, const String:command[], args)
{
	int iJoiningTeam, iOldTeam; char szJoiningTeam[3];
	GetCmdArg(1, szJoiningTeam, sizeof szJoiningTeam);
	
	iOldTeam = GetClientTeam(client);
	iJoiningTeam = StringToInt(szJoiningTeam);

	if(iJoiningTeam == iOldTeam)
	{
		return Plugin_Continue;
	}
	
	if(iJoiningTeam == CS_TEAM_CT || iJoiningTeam == CS_TEAM_SPECTATOR)
	{
		if(iOldTeam == CS_TEAM_T)
		{
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
  /*if (args == 0)
	{
		return Plugin_Continue;
	}
  
  new argg;
  new String:arg[32];  
  GetCmdArg(1, arg, sizeof(arg));
  argg = StringToInt(arg);
  
  if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_limit_terror) > 0) && (argg == 2))
  {
    new teamcount = GetTeamClientCount(TEAM_T);
    
    if (teamcount >= GetConVarInt(deathrun_limit_terror))
    {
      PrintToChat(client, MESS, "enough ts");
      return Plugin_Handled;
    }
  }
  return Plugin_Continue;*/
}

public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay)
{
  new client = TE_ReadNum("m_nPlayer");
  
  if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_block_sprays) == 1))
  {
    PrintToChat(client, MESS, "sprays blocked");
    return Plugin_Handled;
  }
  return Plugin_Continue;
}

GetRandomPlayer(team)
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (GetClientTeam(i) == team))
		clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}