#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.0.001"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <matchsystem_stocks>
#include <matchsystem_const>
#include <cstrike>

#pragma newdecls required
#include "matchsystem/const.sp"
#include "matchsystem/stats.sp"
#include "matchsystem/match.sp"

/*
- V 1.0.001: (Do not ask why version number is like this, i just felt it should be that way. LOL)
	New:
		* CMDS:
			- sm_match_force_start
		* Implemented ban system
		* Complete Match End Reasons.
		* Stats Enable/Disable.
		* Overtime support. (Last thing to do)
		* Total Jumps to the stats
		
	To Do:
		* Clan Tag timer.
		* sm_match_restart_round.	-- will do as an external plugin.
		* Ban System
		* Bot Support - Done
		* Team  - Team Choose Menu, if round ended it crashs the server.
		* Team Menu - Choose another player.
		* Team Menu, Timer.
		* Hud (players remaining to ready)

- V 0.1.006:
	New:
		* Natives & Forwards - Done
		* Late Load - Done
		* Damage report added - Done
		* SQL Support - Done
		* Code Cleaned! - Done
		* Code improvement(s) - Done
		* Added a matchstate when the server is waiting to recieve a match. - Done
		* Support for outside clients (can be turned on and off) - Partially done (only admins done)
		* Kick all players on match end. - Done.
		* Added Test version Support - Done.
		* Stats	- Done
		* UPDATE STATS QUERY FIX (Local STATS ARE 0 WHEN UPDATED AT GAME END). - Done
		* Crash Detect	 - Done
		* CMDs: 
			- sm_match_end - Done
		* Custom Query stocks (functions)
		
	To Do: (Priority by order- First is high)
		* Ask murshid about data type for time. - Done
		* Transfer to sockets - Canclled
		
- V 0.1.005: 
	New:
		* First 'stable' version
		* Team score notification.
		* Custom PrintToChat function
		* Added Prefix support
		* A lot of chat messages
		
	To Do:
		* Late load / reload support. - done
		* Natives - done
		* Check Ready and not ready clan tag if working properly
		* Implement Ban system.
		* Add check for match end (prop shutdown server) - done
		* Add check for match players and how many are in a match (incase one of them abandoned) - Done
*/

public Plugin myinfo = 
{
	name = "Match System",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "None"
};

#define CheckMatchState(%1)	( gMatchState == ( %1 ) )
//#define SetMatchId(%1)		strcopy(gMatchId, sizeof g_szMatchId, %1)
#define SetMatchId(%1)		gMatchId = %1
//#define CheckMatchId(%1) 	StrEqual(g_szMatchId, %1)
#define CheckMatchId(%1)	( gMatchId == ( %1 ) )

//#define TEST_VERSION

// -------------------------------------------
// 				Start: SQL Stuff
// -------------------------------------------
Database g_hSql;

// -------------------------------------------
// 				Start: Match Vars
// -------------------------------------------
enum MatchState
{
	Match_Waiting = 0,
	
	#if defined RNR_PHASE_ENABLED
	Match_FirstReadyPhase,
	#endif
	Match_KnifeRound,
	Match_TeamChoose,
	#if defined RNR_PHASE_ENABLED
	Match_SecondReadyPhase,			// This is after the team choose.
	#endif
	Match_Restarts,
	Match_Running
};

MatchState gMatchState = Match_Waiting;
//char g_szMatchId[MATCHID_MAX_LENGTH];
int gMatchId;

#if !defined TEST_VERSION
int g_iMatchPlayersCount;
#else
int g_iMatchPlayersCount = 10;
#endif

#if defined ALLOW_OUTSIDE_CLIENTS
int g_iOutsideClientsCount;
#endif

bool g_bHalfTimeReached = false;

char g_szMatchMap[35];

// -------------------------------------------
// 				Start: Team Info
// -------------------------------------------

// -------------------------------------------
// 				Start: Player Vars
// -------------------------------------------
// Player State
enum PlayerState
{
	PlayerState_Error = -1,
	
	PlayerState_None,
	PlayerState_Checking,		// Still connecting to the database to check the player. // Do later
	PlayerState_Player,			// Player who partipates in match.
	PlayerState_Bot,
	PlayerState_Admin,			// Admin
	PlayerState_Spectator		// Do this later (Spectators defined in database)
};

// -------------------------------------------
// 				Start: ConVars
// -------------------------------------------
ConVar		ConVar_ServerAddress,
			ConVar_ServerPort;
		
char		g_szServerAddress[20];
int			g_iServerPort;

// -------------------------------------------
// 				Start: Other
// -------------------------------------------
DataPack 	g_hRestartsPack = null;
int 		g_iRestarts, g_iNumRestarts,
			g_bRestarting;

bool 		g_bLate;

enum PlayerData
{
	PD_PlayerDBId,
	PD_PlayerId
}

int ePlayerData[MAXPLAYERS][PlayerData];
char ePlayerAuth[MAXPLAYERS][MAX_AUTHID_LENGTH];
int cIndex_PlayerState[MAXPLAYERS];

// Player MatchIndex
#define pmIndex(%1)  	( cIndex_Player_pIndex[%1] )
int cIndex_Player_pIndex[MAXPLAYERS];
	

// -------------------------------------------
// 		Plugin Initialization
// -------------------------------------------
// Do compatibility for late load (final thing)
public APLRes AskPluginLoad2(Handle plugin, bool bLate, char[] szError, int iErrMax)
{
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{	
	// Match Players Commands
	AddCommandListener(ClCmd_JoinTeam, "jointeam");
	AddCommandListener(ClCmd_Say, "say");
	AddCommandListener(ClCmd_Say, "say_team");
	
	// AdminCommands
	RegAdminCmd("match", AdmCmd_EndMatch, ADMFLAG_RCON, "[confirm] <winner team> - End the current match");
	
	// ConVars
	ConVar_ServerAddress = FindConVar("hostip");
	ConVar_ServerPort = FindConVar("hostport");

	int pieces[4];
	int longip = GetConVarInt(ConVar_ServerAddress);

	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	
	// Do
	FormatEx(g_szServerAddress, sizeof(g_szServerAddress), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	//FormatEx(g_szServerAddress, sizeof(g_szServerAddress), "75.118.154.5");
	g_iServerPort = GetConVarInt(ConVar_ServerPort);
	
	// Needed for main system
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end",	Event_RoundEnd, EventHookMode_Post);
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	// Needed for stats
	Stats_OnPluginStart();

	// SQL
	Database_ConnectToSQL();
	ResetMatchStuff(false);
	
	// Do later
	if(g_bLate)
	{
		CheckClients();
	}
}

public Action AdmCmd_EndMatch(int client, int iArgs)
{
	char szConfirmArg[10];
	GetCmdArg(1, szConfirmArg, sizeof szConfirmArg);
	
	if(!StrEqual(szConfirmArg, "confirm", false))
	{
		ReplyToCommand(client, "This command will end the match. Please confirm the command by writing \"confirm\" as the first arg");
		return Plugin_Handled;
	}
	
	//g_iMatchEndCode = MatchEndCode_Cancelled_Admin;
	//g_iWinnerTeam = TEAM_NONE;
	
	int iOldScore = GetTeamScore(CS_TEAM_CT);
	SetTeamScore(CS_TEAM_CT, 1);
	SetConVarInt( FindConVar("mp_maxrounds"), 1 );
	SetTeamScore(CS_TEAM_CT, iOldScore);
	
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "An admin has ended the match.");
	
	MatchEndStuff(true, RecordStats_All, MatchEndCode_Cancelled_Admin, TeamIndex_None);
	
	return Plugin_Handled;
}

stock void CheckIfServerHasCrashed()
{
	SQL_LockDatabase(g_hSql);
	Handle result = SQL_ExecuteQuery(g_hSql, g_szError, sizeof g_szError, "Check Crash Query #1",
	g_szCheckCrashQuery1, g_szServerAddress, g_iServerPort);
	SQL_UnlockDatabase(g_hSql);
	
	if(result == null)
	{
		return;
	}
	
	SQL_FetchRow(result);
	
	int iMatchId = SQL_FetchInt(result, 0);
	if(SQL_IsFieldNull(result, 0) || iMatchId == MATCHID_NO_MATCH)
	{
		delete result;
		
		PrintDebug("NO +++++++++++++++++" );		
		return;
	}
	
	delete hResult;
	
	result = SQL_ExecuteQuery(g_hSql, g_szError, sizeof g_szError, "Check Crash Query #2", g_szCheckCrashQuery2)
	if(result == null)
	{
		delete result;
		return;
	}
	
	SQL_FetchRow(hResult);
	if(SQL_FetchInt(result, 0) == 0)
	{
		delete result;
		return;
	}
	
	delete result;
	
	result = SQL_ExecuteQuery(g_hSql, g_szError, sizeof g_szError, "Check Crash Query #3",
	g_szQuery_CheckCrash_CancelMatchCrash
	TEAM_ID_NONE,
	MatchEndCode_Cancelled_Crash,
	iMatchId);
	
	delete result;
	
	result = SQL_ExecuteQuery(g_hSql, g_szError, sizeof g_szError, "Check Crash query #4", g_szCheckCrashQuery2,
	g_szServerAddress, g_iServerPort);
	
	if(result != null)
	{
		delete result;
	}
	
	LoopClients()
	{
		if(IsClientAuthorized(i))
		{
			CheckIfClientIsAllowed(i);
		}
	}
}

void MatchEndStuff(bool bDoQuerys = true, RecordStats iStatsBit = RecordStats_None, int iCode = MatchEndCode_None, TeamsIndexes iWinnerTeamIndex)
{
	if(bDoQuerys)
	{
		SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0,_, "MatchEnd Time Update Query", "UPDATE `%s` SET `%s` = UNIX_TIMESTAMP(), `%s` = %d, `%s` = %d WHERE `%s` = %d",
		g_szMatchTableName,
		g_szMatchTableFields[MatchField_EndTime], // UNIX_TIMESTAMP()
		g_szMatchTableFields[MatchField_Winner], iWinnerTeamIndex == TeamIndex_None ? TEAM_ID_NONE : gTeams[iWinnerTeamIndex][TeamInfo_TeamId],
		g_szMatchTableFields[MatchField_MatchEndCode], iCode,
//		g_szMatchTableFields[MatchField_MatchEndReason], g_szMatchEndReasonString[iCode],
		g_szMatchTableFields[MatchField_MatchId], gMatchId);
		
		SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0,_, "MatchEnd ID Update Query", "UPDATE `%s` SET `%s` = NULL WHERE `%s` = %d", 
		g_szServersTableName, 
		g_szServersTableFields[ServersField_MatchId], 
		g_szServersTableFields[ServersField_MatchId], gMatchId);
	}
	
	if(iStatsBit != RecordStats_DoNotRecord)
	{
		PrintDebug("Uploading Stats");
		UploadAllPlayersStats(iStatsBit);
	}
	
	ResetMatchStuff(false);
	
	g_iKickTime = MATCH_END_KICK_TIME;
	CreateTimer(1.0, Timer_KickAll,_, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void ResetMatchStuff(bool bNewMatch)
{
	if(!bNewMatch)
	{
		SetMatchState(Match_Waiting);
		SetMatchId(MatchId_NoMatch);
	}
	
	g_iReadyCount = 0;
	g_iRestarts = 0;
	g_bRestarting = false;
	g_iNumRestarts = 0;
	g_bHalfTimeReached = false;
}

// ----------------------------------------
// 		Events
// ----------------------------------------
public void Event_RoundStart(Event event, const char[] szEventName, bool bDontBroadcast)
{
	PrintDebug("Round Start");
	
	PrintDebug("Restarting %d, iRestart : %d %d", g_bRestarting, g_iRestarts + 1, g_iNumRestarts);
	PrintDebug("gMatchState = %d", gMatchState);
	
	int i, j;
	LoopClients(i)
	{
		g_iKiller[i] = 0;
		
		LoopClients(j)
		{
			g_flDamage[i][j] = 0.0;
			g_iHits[i][j] = 0;
		}
	}
	
	if(g_bRestarting)
	{
		PrintDebug("Restarting, iRestart : %d %d", g_iRestarts + 1, g_iNumRestarts);
		if(++g_iRestarts < g_iNumRestarts)
		{	
			//SetConVarInt(ConVar_RestartGame, 1);
		
			int iDelay = ReadPackCell(g_hRestartsPack);
			ServerCommand("mp_restartgame %d", iDelay);
		}
		
		else if(g_iRestarts >= g_iNumRestarts)
		{
			RestartsDone();
		}
		
		return;
	}
	
	if(CheckMatchState(Match_Running))
	{
		int iCTScore = GetTeamScore(CS_TEAM_CT), iTScore = GetTeamScore(CS_TEAM_T);
		if(iCTScore == iTScore)
		{
			//PrintToChatAll(" %d", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Score is tied: %d-%d", iCTScore, iTScore);
		}
		
		else if(iCTScore > iTScore)
		{
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "The Counter-Terrorists team is winning: %d-%d", iCTScore, iTScore);
		}
		
		else
		{
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "The Terrorists team is winning: %d-%d", iTScore, iCTScore);
		}
		
		for(int i = 1; i <= MaxClients; i++)
		{
			// Do is valid player;
			if(IsClientInGame(i))
			{
				g_iRoundsPlayed[i]++;
			}
		}
	}
	
	else if(CheckMatchState(Match_TeamChoose))
	{
		int client;
		
		PrintDebug("Done1");
		// Do show menu to other player if no player is in game.
		while( (client = GetRandomClient(g_iChoosingTeamIndex) ) > 0)
		{
			break;
		}
		
		PrintDebug("Done2 %d", client);
		
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Player %N will be choosing the starting team for team %s", client, g_szTeamNames[g_iTeamIndex[client]]);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Choose the starting team");
		
		PrintDebug("Done3");
	
		Menu hMenu = CreateMenu(MenuHandler_TeamChoose, MENU_ACTIONS_DEFAULT);
		char szInfo[3];
		
		PrintDebug("Done4");
		
		IntToString(CS_TEAM_T, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Terrorists");
		
		IntToString(CS_TEAM_CT, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Counter-Terrorists");
		
		IntToString(CS_TEAM_SPECTATOR, szInfo, sizeof szInfo);
		hMenu.AddItem(szInfo, "Random");
		
		hMenu.ExitBackButton = false;
		
		PrintDebug("Done5");
		
		hMenu.Display(client, MENU_TIME_FOREVER);
		
		PrintDebug("---- MENU DISPLAYED");
	}
}

public void Event_RoundEnd(Event event, const char[] szEventName, bool bDontBroadcast)
{
	// Do compatibility for hostage maps
	if(CheckMatchState(Match_KnifeRound))
	{
		PrintDebug("MatchState Knife Roun #1d");
		
		PrintDamageReportAll(true);
		
		CSRoundEndReason iEndReason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
		int iWinningTeam = GetEventInt(event, "winner");
		
		PrintDebug("RoundEnd End Reason = %d", iEndReason);
	
		// Do this efficiently
		if(iEndReason == CSRoundEnd_TerroristWin || iEndReason == CSRoundEnd_CTWin || iEndReason == CSRoundEnd_Draw)
		{
			PrintDebug("End Reason Valid");
			int iOtherTeam = (iWinningTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T);
			
			bool bEliminated = true;
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i))
				{
					continue;
				}
				
				if(GetClientTeam(i) == iOtherTeam)
				{
					if(IsPlayerAlive(i))
					{
						PrintDebug("%N not eliminated", i);
						bEliminated = false;
						break;
					}
				}
			}
			
			if(bEliminated)
			{
				g_iChoosingTeamIndex = iWinningTeam == gTeams[TeamIndex_First][TeamInfo_CurrentTeam] ? TeamIndex_First : TeamIndex_Second;
				SetMatchState(Match_TeamChoose);
				
				PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "The %s team won the knife round. They will be choosing the starting team.", iWinningTeam == CS_TEAM_CT ? "Counter-Terrorists" : "Terrorist");
			}
		}
		
		return;
	}
	
	if (CheckMatchState(Match_Running))
	{
		PrintDamageReportAll(true);
		
		for(int i = 1, iKills; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || gPlayerState[i] != PlayerState_Player)
			{
				continue;
			}
			
			iKills = g_iKillsThisRound[i];
			g_iKillsThisRound[i] = 0;
			switch(iKills)
			{
				case 1: continue;
				case 2: g_i2Kills[i]++;
				case 3: g_i3Kills[i]++;
				case 4: g_i4Kills[i]++;
				case 5: g_iAces[i]++;
			}		
		}
		
		CheckMatchEnd();
	}
}

void CheckMatchEnd()
{
	ConVar ConVar_MaxRounds = CreateConVar("mp_maxrounds", "");
	
	int iMaxRounds = GetConVarInt(ConVar_MaxRounds);
	int iHalfMaxRounds = iMaxRounds / 2;
	
	int iCTScore = GetTeamScore(CS_TEAM_CT), iTScore = GetTeamScore(CS_TEAM_T);
	
	PrintDebug("Scores CT : %d T %d", iCTScore, iTScore);
	
	if(!g_bHalfTimeReached && (iCTScore + iTScore) == iHalfMaxRounds)
	{
		g_bHalfTimeReached = true;
		
		gTeams[TeamIndex_First][TeamInfo_CurrentTeam] = gTeams[TeamIndex_First][TeamInfo_CurrentTeam] == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
		gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] = gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
		
		FixTeamNames();
		
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "--- Half Time ---");
	}
	
	if(	iCTScore > iHalfMaxRounds || iTScore > iHalfMaxRounds || (iCTScore == iHalfMaxRounds && iTScore == iHalfMaxRounds) )
	{
		//if(!bOverTime_Enabled)
		//{
			PrintDebug("The Match Has Ended!");
			
			int iWinner = iCTScore > iTScore ? CS_TEAM_CT : ( ( iTScore > iCTScore ) ? CS_TEAM_T : CS_TEAM_NONE);
			
			TeamsIndexes iWinnerTeamIndex = TeamIndex_None;
			if(iWinner != CS_TEAM_NONE)
			{
				iWinnerTeamIndex = gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == iWinner ? TeamIndex_Second : TeamIndex_Second;
			}
			
			MatchEndStuff(true, g_iStatsRecorded, MatchEndCode_End, iWinnerTeamIndex);
		//}
		
		//else
		//{
			
		//}
	}
}

public Action Timer_KickAll(Handle hTimer, any szReason)
{
	if(g_iKickTime <= 0)
	{
		KickAllClients(KICK_MESSAGE_MATCH_ENDED);
		return;
	}
	
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Kicking everyone in \x05%d \x01seconds", g_iKickTime--);
}

void KickAllClients(const char[] szReason)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		KickClient_Custom(i, szReason);
	}
}

public void Event_PlayerDeath(Event event, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId( GetEventInt(event, "userid") );
	int iKiller = GetClientOfUserId( GetEventInt(event, "attacker") );
	g_iKiller[client] = iKiller;
	
	if(!(0 < client <= MaxClients))
	{
		return;
	}
	
	DamageReport_PrintDamageReport(client);
	Stats_OnPlayerDeath(client, iKiller);
}

public void Event_PlayerSpawn(Event event, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(CheckMatchState(Match_KnifeRound))
	{
		CS_RemoveWeapons(client, false, g_bKnifeRound_DisarmC4);
	}
	
	#if defined RNR_PHASE_ENABLED
	else if(CheckMatchState(Match_FirstReadyPhase) || CheckMatchState(Match_SecondReadyPhase))
	{
		ChangeToReadyClanTag(client);
	}
	#endif
}

// ----------------------------------------
// 		Forwards
// ----------------------------------------
public void OnClientAuthorized(int client, const char[] szAuth)
{	
	g_iTeamIndex[client] = TeamIndex_None;
	g_bReady[client] = false;
	gPlayerState[client] = PlayerState_None;
	
	CheckIfClientIsAllowed(client);
}

public void OnClientPutInServer(client)
{
	Hooks(client, true);
	
	if(IsFakeClient(client))
	{
		return;
	}
}

public void OnClientDisconnect(client)
{
	Hooks(client, false);
	
	if(CheckMatchState(Match_Waiting))
	{
		gPlayerState[client] = PlayerState_None;
		g_bReady[client] = false;
		g_iTeamIndex[client] = TeamIndex_None;
		
		return;
	}
	
	#if defined ALLOW_OUTSIDE_CLIENTS
		#if defined ALLOW_ADMINS
		if(gPlayerState[client] == PlayerState_Admin)
		{
			g_iOutsideClients--;
			gPlayerState[client] = PlayerState_None;
			return;
		}
		#endif
		
		#if defined ALLOW_SPECS
		if(gPlayerState[client] == PlayerState_Spec)
		{
			g_iOutsideClients--;
			gPlayerState[client] = PlayerState_None;
			return;
		}
		#endif
	#endif
	
	if(gPlayerState[client] == PlayerState_Player)
	{
		UpdateClientLocalStats(client);
		
		Call_StartForward(g_hForward_MatchPlayer_Disconnect);
		Call_PushCell(client);
		Call_Finish();
	}
	
	gPlayerState[client] = PlayerState_None;
	g_iTeamIndex[client] = TeamIndex_None;
	
	if(g_bReady[client])
	{
		g_iReadyCount--;
		g_bReady[client] = false;
	}
}

// ----------------------------------------
// 		Callbacks
// ----------------------------------------
public Action ClCmd_Say(int client, const char[] szCommand, int iArgCount)
{	
	if(!gPlayerState[client])
	{
		return;
	}
	
	char szCmdArg[12];
	GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	
	if(StrEqual(szCmdArg, ".ready", false))
	{
		if(gMatchState != Match_FirstReadyPhase && gMatchState != Match_SecondReadyPhase)
		{
			return;
		}
	
		if(g_bReady[client])
		{
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have already declared yourself as ready");
			return;
		}
		
		g_bReady[client] = true;
		g_iReadyCount++;
		
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "%N is now ready", client);
		
		PrintDebug("g_iReadyCount %d .. g_iMatchPlayersCount %d", g_iReadyCount, g_iMatchPlayersCount);
		
		CheckStart();
		//PrintToChat(client, "* You are now ready");
	}
}

public Action ClCmd_JoinTeam(int client, const char[] szCommand, int iArgCount)
{
	if(gPlayerState[client] == PlayerState_Bot)
	{
		return Plugin_Continue;
	}
	
	char szCmdArg[6]; GetCmdArg(1, szCmdArg, sizeof szCmdArg);
	int iJoinTeam = StringToInt(szCmdArg);
	int iTeam = GetClientTeam(client);
	
	PrintDebug("iJoinTeam = %d - iTeam %d", iJoinTeam, iTeam);
	
	if(gPlayerState[client] != PlayerState_Player)
	{
		if(iJoinTeam == CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You do not have premission to join a team except Spectators.");
		return Plugin_Handled;
	}
	
	// Is a match player ->>
	if(CheckMatchState(Match_FirstReadyPhase) || CheckMatchState(Match_SecondReadyPhase))
	{
		if(iJoinTeam != CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	// Any other match state
	if( iJoinTeam == iTeam )
	{
		return Plugin_Continue;
	}
	
	if(iTeam == 0 && iJoinTeam == gTeams[g_iTeamIndex[client]][TeamInfo_CurrentTeam])
	{
		return Plugin_Continue;
	}
	
	// Disable Changing teams.
	return Plugin_Handled;
}

// ----------------------------------------
// 		SQL Callbacks
// ----------------------------------------
public void SQLCallback_CheckClient(Handle hSQL, Handle hResultSet, char[] szError, int client)
{
	if(!IsClientConnected(client))
	{
		return;
	}
	
	if(CheckError(szError))
	{
		LogError("SQL Callback Error (CheckClient): %s", szError);
		return;
	}
	
	if(!SQL_GetRowCount(hResultSet))
	{
		#if defined ALLOW_OUTSIDE_CLIENTS
			#if defined ALLOW_ADMINS
			if(GetUserAdmin(client))
			{
				if(g_iOutsideClients < MAX_OUTSIDE_CLIENTS)
				{
					g_iOutsideClients++;
					gPlayerState[client] = PlayerState_Admin;
					
					PrintDebug("Player %N is an admin", client);
					return;
				}
				
				KickClient_Custom(client, KICK_MESSAGE_OUTSIDE_CLIENTS_EXCEEDED);
				return;
			}
			#endif
			
			#if defined ALLOW_SPECS
			// Do support for specs later
			if(IsSpec(client))
			{
				gPlayerState[client] = PlayerState_Spectator;
				return;
			}
			#endif
			
		#endif
		
		PrintToServer("Lol2");
		KickClient_Custom(client, KICK_MESSAGE_NOT_ALLOWED);		// OnClientdisconnet Stuff will happen later
		return;
	}
	
	gPlayerState[client] = PlayerState_Player;
	
	SQL_FetchRow(hResultSet);
	//g_iTeam[client] = SQL_FetchInt(hResultSet, 0);
	g_iTeamIndex[client] = GetTeamIndexFromTeamId(SQL_FetchInt(hResultSet, 0));
	
	GetClientLocalStats(client);
	
	Call_StartForward(g_hForward_MatchPlayer_Joined);
	Call_PushCell(client);
	Call_Finish();
}

TeamsIndexes GetTeamIndexFromTeamId(int iTeamId)
{
	if(iTeamId == gTeams[TeamIndex_First][TeamInfo_TeamId])
	{
		return TeamIndex_First;
	}
	
	return TeamIndex_Second;
}



void UpdateAllLocalStats()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && gPlayerState[i] == PlayerState_Player)
		{
			UpdateClientLocalStats(i);
		}
	}
}

// ----------------------------------------
// 		SDK Hooks
// ----------------------------------------
public Action SDKCallback_WeaponSwitch(int client, int iWeapon)
{
	if(CheckMatchState(Match_KnifeRound))
	{
		char szWeaponName[35];
		GetEntityClassname(iWeapon, szWeaponName, sizeof szWeaponName); 
		
		if(!StrEqual(szWeaponName, "weapon_knife"))
		{
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action SDKCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(IsValidPlayer(attacker))
	{
		return;
	}
	// Damage Report
	DamageReport_OnTakeDamage(victim, attacker, damage);
	
	// Stats
	Stats_OnTakeDamage(attacker);
}

// ----------------------------------------
// 		Menu Handlers
// ----------------------------------------
public int MenuHandler_TeamChoose(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			if(param1 == MenuEnd_Selected)
			{
				delete menu;
			}
		}
		
		case MenuAction_Select:
		{
			int iTeamSelection;
			char szDump[3];
			
			menu.GetItem(param2, szDump, sizeof szDump);
			iTeamSelection = StringToInt(szDump);
			
			if(iTeamSelection == CS_TEAM_SPECTATOR)
			{
				iTeamSelection = GetRandomInt(0, 1) ? CS_TEAM_CT : CS_TEAM_T;
			}
			
			int iOtherTeam = iTeamSelection == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
			TeamsIndexes iOtherIndex = g_iChoosingTeamIndex == TeamIndex_First ? TeamIndex_Second : TeamIndex_First;
			
			gTeams[g_iChoosingTeamIndex][TeamInfo_CurrentTeam] = iTeamSelection;
			gTeams[iOtherIndex][TeamInfo_CurrentTeam] = iOtherTeam;
			
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Team %s chose %s",
			g_szTeamNames[g_iChoosingTeamIndex], iTeamSelection == CS_TEAM_T ? "Terrorist" : "Counter-Terrorists");
			
			FixTeamNames();
			SetMatchState(Match_SecondReadyPhase);
		}
		
		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_Disconnected:
				{
					// Do if no other play is connected.
					int client = GetRandomClient(g_iChoosingTeamIndex);
					while( ( client = GetRandomClient(g_iChoosingTeamIndex) ) )
					{
						break;
					}
					
					menu.Display(client, MENU_TIME_FOREVER);
				}
				
				default:
				{
					menu.Display(param1, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

void FixTeamNames()
{
	if( !g_szTeamNames[TeamIndex_First][0] || 
	StrEqual(g_szTeamNames[TeamIndex_First], TEAM_NAME_CT) ||
	StrEqual(g_szTeamNames[TeamIndex_First], TEAM_NAME_T) )
	{
		strcopy(g_szTeamNames[TeamIndex_First], sizeof(g_szTeamNames[]),
		gTeams[TeamIndex_First][TeamInfo_CurrentTeam] == CS_TEAM_CT ? TEAM_NAME_CT : TEAM_NAME_T);
	}
	
	if( !g_szTeamNames[TeamIndex_Second][0] || 
	StrEqual(g_szTeamNames[TeamIndex_Second], TEAM_NAME_CT) ||
	StrEqual(g_szTeamNames[TeamIndex_Second], TEAM_NAME_T) )
	{
		strcopy(g_szTeamNames[TeamIndex_Second], sizeof(g_szTeamNames[]),
		gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == CS_TEAM_CT ? TEAM_NAME_CT : TEAM_NAME_T);
	}
	
	ServerCommand("mp_teamname_%d \"%s\"", gTeams[TeamIndex_First][TeamInfo_CurrentTeam] == CS_TEAM_CT ? 1 : 2, g_szTeamNames[TeamIndex_First]);
	ServerCommand("mp_teamname_%d \"%s\"", gTeams[TeamIndex_Second][TeamInfo_CurrentTeam] == CS_TEAM_CT ? 1 : 2, g_szTeamNames[TeamIndex_Second]);
}

// ----------------------------------------
// 		Stocks, Custom functions, etc
// ----------------------------------------
void Hooks(int client, bool bOn)
{
	switch(bOn)
	{
		case true:
		{
			SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_WeaponCanUse, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_WeaponEquip, SDKCallback_WeaponSwitch);
			SDKHook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
		}

		case false:
		{
			SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponCanUse, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_WeaponEquip, SDKCallback_WeaponSwitch);
			SDKUnhook(client, SDKHook_OnTakeDamage, SDKCallback_OnTakeDamage);
		}	
	}
}

#if defined RNR_PHASE_ENABLED
void ChangeToReadyClanTag(int client = 0)
{
	switch(client)
	{
		case 0:
		{
			for(client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client) || gPlayerState[client] != PlayerState_Player)
				{
					continue;
				}
				
				CS_SetClientClanTag(client, g_bReady[client] ? "[READY]" : "[NOT READY]");
			}
		}
		
		default:
		{
			CS_SetClientClanTag(client, g_bReady[client] ? "[READY]" : "[NOT READY]");
		}
	}
}

void ChangeToOriginalClanTag(int client = 0)
{
	switch(client)
	{
		case 0:
		{
			for(client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client) || gPlayerState[client] != PlayerState_Player)
				{
					continue;
				}
				
				CS_SetClientClanTag(client, g_szOriginalClanTag[client]);
			}
		}
		
		default:
		{
			CS_SetClientClanTag(client, g_szOriginalClanTag[client]);
		}
	}
}
#endif

void StartMatch()
{
	PutPlayersInTeams();
	
	if(CheckMatchState(Match_FirstReadyPhase) && g_bKnifeRound_Enabled)
	{
		SetMatchState(Match_KnifeRound);
			
		//SetConVarInt(ConVar_RestartGame, 3);
		Func_RestartGame( true, 1, { DELAY_RESTART_KNIFE_ROUND } );
		
		return;
	}
	
	// if knife round i
	SetMatchState(Match_Restarts);
	Func_RestartGame( true, 3, { 3, 3, 5 } );
		
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Live on THREE restarts");

}

void CheckStart()
{
	//PrintToChatAll("g_iReadyCount = %d ... MATCH_TEAM_PLAYERS = %d", g_iReadyCount, MATCH_PLAYERS_COUNT);
	if(g_iReadyCount >= g_iMatchPlayersCount)
	{	
		//PrintToChatAll("Starting");
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "-- Starting --");
		
		ChangeToOriginalClanTag();
		StartMatch();
	}
}

void Func_RestartGame( bool bReset, int iNumRestarts, int[] iDelay )
{
	if(bReset)
	{
		g_iRestarts = 0;
		g_hRestartsPack.Reset(true);
	}
	
	//g_iNumRestarts = iNumRestarts;
	
	g_iNumRestarts = iNumRestarts;
	g_bRestarting = true;
	
	if(iNumRestarts > 1)
	{
		for(int i; i < iNumRestarts; i++)
		{
			g_hRestartsPack.WriteCell(iDelay[i]);
		}
		
		g_hRestartsPack.Reset();
	}
	
	ServerCommand("mp_restartgame %d", iDelay[0]);
	PrintDebug("iDelay %d", iDelay);
}

void SetMatchState(MatchState State)
{
	MatchState iOldMatchState = gMatchState;
	gMatchState = State;
	
	switch(State)
	{
		case Match_Waiting:
		{
			ExecuteConfig(g_szWarmUpConfig);
			//strcopy(g_szMatchId, sizeof g_szMatchId, MATCHID_NO_MATCH);
			SetMatchId(MATCHID_NO_MATCH);
		}
		
		case Match_Restarts:
		{
			ExecuteConfig(g_szMatchConfig);
		}
		
		case Match_FirstReadyPhase:
		{
			SetArrayValue(g_bReady, sizeof g_bReady, false, 1);
			g_iReadyCount = 0;
			
			ChangeToReadyClanTag();
			
			ExecuteConfig(g_szWarmUpConfig);
		}
		
		case Match_SecondReadyPhase:
		{
			SetArrayValue(g_bReady, sizeof g_bReady, false, 1);
			g_iReadyCount = 0;
			
			ChangeToReadyClanTag();
			
			ExecuteConfig(g_szWarmUpConfig);
		}
		
		case Match_KnifeRound:
		{
			ExecuteConfig(g_szKnifeRoundConfig);
		}
		
		case Match_TeamChoose:
		{
			ExecuteConfig(g_szWarmUpConfig);
		}
		
		case Match_Running:
		{
			ExecuteConfig(g_szMatchConfig);
		}
	}
	
	Call_StartForward(g_hForward_MatchStateChanged);
	Call_PushCell(iOldMatchState);
	Call_PushCell(State);
	Call_Finish();
}

void PutPlayersInTeams()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || gPlayerState[client] != PlayerState_Player)
		{
			continue;
		}
		
		CS_SwitchTeam(client, gTeams[g_iTeamIndex[client]][TeamInfo_CurrentTeam]);
	}
}

void ExecuteConfig(const char[] szConfig)
{
	ServerCommand("exec \"%s/%s\"", g_szConfigFolder, szConfig);
}

void CheckIfClientIsAllowed(client)
{
	if( IsFakeClient(client) )
	{
		ePlayerData[client][PD_PlayerState] = PlayerState_Bot;
		ePlayerData[client][PD_TeamId] = TeamIndex_None;
		
		PrintDebug("* Bot %N ignored", client);
		return;
	}
	
	DataBase_CheckIncomingMatch();
	
	if(CheckMatchId(MatchId_NoMatch))
	{
		KickClient_Custom(client, KICK_MESSAGE_NOT_ALLOWED);
		return;
	}
	
	cIndex_PlayerState[client] = PlayerState_Checking;

	char szAuthId[MAX_AUTHID_LENGTH];
	GetClientAuthId(client, AuthId_SteamID64, szAuthId, sizeof szAuthId);
	
	cIndex_Player_pmIndex[client] = FindpmIndex(client);
	if(cIndex_Player_pmIndex[client] == -1)
	{
		KickClient_Custom(client, KICK_MESSAGE_NOT_ALLOWED);
		return;
	}
}

public void OnClientPutInServer(int client)
{
	if( IsFakeClient(client) )
	{
		return;
	}
	
	g_iPlayersConnected++;
}

void CheckPlayersConnectedCount()
{
	if(g_iPlayersConnected == g_iMatchPlayersCount)
	{
		StartMatch();
	}
}

RestartsDone()
{
	g_bRestarting = false;
	
	if(CheckMatchState(Match_Restarts))
	{
		SetMatchState(Match_Running);
		MatchStartStuff();
	}
	
	else if(CheckMatchState(Match_KnifeRound))
	{
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "--- Knife Round ---");
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Win to choose the starting team.");
	}
}

void MatchStartStuff()
{	
	SQL_TQuery_Custom(g_hSql, SQLCallback_Dump, 0,_, "Update Match Start Timestamp",
	"UPDATE `%s` SET `%s` = UNIX_TIMESTAMP() WHERE `%s` = %d",
	g_szMatchTableName, g_szMatchTableFields[MatchField_StartTime], g_szMatchTableFields[MatchField_MatchId], gMatchId);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && gPlayerState[i] == PlayerState_Player)
		{
			g_iRoundsPlayed[i]++;
		}
	}
	
	PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Match is live, Good luck & Have fun.");
	
	Call_StartForward(g_hForward_MatchStart);
	Call_PushCell(gMatchId);
	Call_Finish();
}

int GetRandomClient(TeamsIndexes iTeamIndex = TeamIndex_None, bool bOnlyAlive = false, bool bInATeam = false)
{
	int iPlayers[MAXPLAYERS + 1], iCount;
	for(int client = 1, iPlayerTeam; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))
		{
			continue;
		}
			
		if(iTeamIndex != TeamIndex_None && g_iTeamIndex[client] != iTeamIndex)
		{
			PrintDebug("Skipped %N", client);
			continue;
		}
		
		if(bOnlyAlive && !IsPlayerAlive(client))
		{
			continue;
		}

		if(bInATeam && !( ( iPlayerTeam = GetClientTeam(client) ) == CS_TEAM_CT || iPlayerTeam == CS_TEAM_T ))
		{
			continue;
		}
		
		iPlayers[iCount++] = client;
	}
	
	PrintDebug("Count %d", iCount);
	if(iCount == 1)
	{
		return iPlayers[0];
	}
	
	return iCount ? iPlayers[GetRandomInt(0, iCount - 1)] : 0;
}

// Credits: zeusround.sp by "TnTSCS aka ClarkKent"
void CS_RemoveWeapons(int client, bool bStripKnife, bool bStripBomb)
{
	int weapon_index = -1;
	#define MAX_WEAPON_SLOTS 5
	
	for (int slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		weapon_index = GetPlayerWeaponSlot(client, slot);
		{
			PrintDebug("ent %d", weapon_index);
			if (IsValidEntity(weapon_index))
			{
				if(slot == CS_SLOT_KNIFE && !bStripKnife)
				{
					continue;
				}
				
				if (slot == CS_SLOT_C4 && !bStripBomb)
				{
					return;
				}
				
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

// from the_khalid_inc.inc (my own code)
stock void SetArrayValue(any[] Array, int iSize, any Value, int iStartingIndex = 0)
{
	for (int i = iStartingIndex; i < iSize; i++)
	{
		Array[i] = Value;
	}
}

// Since KickClient is not working properly, this is an alternative.
void KickClient_Custom(int client, const char[] szReason)
{
	ServerCommand("kickid %d \"%s\"", GetClientUserId(client), szReason);
}

bool IsValidPlayer(int client)
{
	if( 0 < client <= MaxClients )
	{
		return true;
	}
	
	return false;
}

public int Native_GetMatchState(Handle hPlugin, int iArgs)
{
	return view_as<int>(gMatchState);
}

public int Native_GetPlayerState(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if( !( 0 < client <= MaxClients ) )
	{
		ThrowError("Index out of bounds. (%d)", client);
		return view_as<int>(PlayerState_Error);
	}
	
	return view_as<int>(gPlayerState[client]);
}

public int Native_GetMatchId(Handle hPlugin, int iArgs)
{
	/*
	//if(StrEqual(g_szMatchId, MATCHID_NO_MATCH))
	if(CheckMatchId(MATCHID_NO_MATCH))
	{
		return 0;
	}
	
	SetNativeString(1, g_szMatchId, GetNativeCell(2), false);
	//return gMatchId;
	return 1;
	*/
	
	return gMatchId;
}
