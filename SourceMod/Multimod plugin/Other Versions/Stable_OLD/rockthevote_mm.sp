/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Rock The Vote Plugin
 * Creates a map vote when the required number of players have requested one.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
//#include <mapchooser>
//#include <nextmap>
#include <multimod>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Rock The Vote",
	author = "AlliedModders LLC",
	description = "Provides RTV Map Voting",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

ConVar g_Cvar_Needed;
ConVar g_Cvar_MinPlayers;
ConVar g_Cvar_InitialDelay;
//ConVar g_Cvar_Interval;
ConVar g_Cvar_ChangeTime;
//ConVar g_Cvar_RTVPostVoteAction;

new bool:g_bModVotingStarted = false;

//new bool:g_CanRTV = false;		// True if RTV loaded maps and is active.
new bool:g_RTVAllowed = false;	// True if RTV is available to players. Used to delay rtv votes.
new g_Voters = 0;				// Total voters connected. Doesn't include fake clients.
new g_Votes = 0;				// Total number of "say rtv" votes
new g_VotesNeeded = 0;			// Necessary votes before map vote begins. (voters * percent_needed)
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};

new Float:g_flStartTime;

//new bool:g_InChange = false;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("rockthevote.phrases");
	
	g_Cvar_Needed = CreateConVar("sm_rtv_needed", "0.60", "Percentage of players needed to rockthevote (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtv_minplayers", "0", "Number of players required before RTV will be enabled.", 0, true, 0.0, true, float(MAXPLAYERS));
	g_Cvar_InitialDelay = CreateConVar("sm_rtv_initialdelay", "30.0", "Time (in seconds) before first RTV can be held", 0, true, 0.00);
//	g_Cvar_Interval = CreateConVar("sm_rtv_interval", "240.0", "Time (in seconds) after a failed RTV before another can be held", 0, true, 0.00);
	g_Cvar_ChangeTime = CreateConVar("sm_rtv_changetime", "0", "When to change the map after a succesful RTV: 0 - Instant, 1 - RoundEnd, 2 - MapEnd", _, true, 0.0, true, 2.0);
	//g_Cvar_RTVPostVoteAction = CreateConVar("sm_rtv_postvoteaction", "1", "What to do with RTV's after a mapvote has completed. 0 - Allow, success = instant change, 1 - Deny", _, true, 0.0, true, 1.0);
	
	//RegConsoleCmd("sm_rtv", Command_RTV);
	
	AutoExecConfig(true, "rtv");
}

public OnMapStart()
{
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	//g_InChange = false;
	
	g_flStartTime = GetGameTime();
	
	/* Handle late load */
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public OnMapEnd()
{
	//g_CanRTV = false;	
	g_RTVAllowed = false;
	g_bModVotingStarted = false;
}

public Voting_VoteStarted()
{
	g_bModVotingStarted = true;
}
/*
public OnConfigsExecuted()
{	
	//g_CanRTV = true;
	//g_RTVAllowed = false;
	CreateTimer(g_Cvar_InitialDelay.FloatValue, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
}*/

public OnClientConnected(client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	return;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	/*if (!g_CanRTV)
	{
		return;	
	}*/
	
	if (g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded && 
		g_RTVAllowed ) 
	{
		if (/*g_Cvar_RTVPostVoteAction.IntValue == 1 ||*/ g_bModVotingStarted)
		{
			return;
		}
		
		StartRTV();
	}	
}

public OnClientSayCommand_Post(client, const String:command[], const String:sArgs[])
{
	if (/*!g_CanRTV ||*/ !client)
	{
		return;
	}
	
	if (strcmp(sArgs, "rtv", false) == 0 || strcmp(sArgs, "rockthevote", false) == 0 || strcmp(sArgs, "rtmv", false) == 0 || strcmp(sArgs, "rockthemodvote", false) == 0)
	{
		//new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		AttemptRTV(client);
		
		//SetCmdReplySource(old);
	}
}

public Action:Command_RTV(client, args)
{
	if (/*!g_CanRTV ||*/ !client)
	{
		return Plugin_Handled;
	}
	
	AttemptRTV(client);
	
	return Plugin_Handled;
}

AttemptRTV(client)
{
	if(g_bModVotingStarted)
	{
		MM_PrintToChat(client, "The vote has already started!");
		return;
	}
	
	new Float:flCurrGameTime = GetGameTime();
	new Float:flAllowRTVTime = g_flStartTime + g_Cvar_InitialDelay.FloatValue;
	if (GetGameTime() < flAllowRTVTime)
	{
		new iMinutes, iSecs;
		iSecs = RoundFloat(flAllowRTVTime - flCurrGameTime);
		iMinutes = iSecs / 60;
		iSecs = iSecs % 60;
		
		new String:szTimeFormat[60], iLen;
		
		if(iMinutes)
		{
			iLen = FormatEx(szTimeFormat, sizeof szTimeFormat, "%d minutes", iMinutes);
		}
		
		if(iSecs)
		{
			iLen += FormatEx(szTimeFormat[iLen], sizeof szTimeFormat - iLen, "%s%d seconds", iMinutes ? " and " : "", iSecs);
		}
		
		MM_PrintToChat(client, "Please wait %s before rocking the vote.", szTimeFormat);
		
		return;
	}
	
	if (!g_RTVAllowed) //|| (g_Cvar_RTVPostVoteAction.IntValue == 1))
	{
		//ReplyToCommand(client, "[SM] %t", "RTV Not Allowed");
		
		return;
	}
		
	/*if (!CanMapChooserStartVote())
	{
		//ReplyToCommand(client, "[SM] %t", "RTV Started");
		MM_PrintToChat(client, "RTV started!");
		return;
	}*/
	
	if (GetClientCount(true) < g_Cvar_MinPlayers.IntValue)
	{
		//ReplyToCommand(client, "[SM] %t", "Minimal Players Not Met");
		MM_PrintToChat(client, "Minimal players not met.");
		return;			
	}
	
	if (g_Voted[client])
	{
		//ReplyToCommand(client, "[SM] %t", "Already Voted", g_Votes, g_VotesNeeded);
		MM_PrintToChat(client, "You have already voted.");
		return;
	}	
	
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	g_Votes++;
	g_Voted[client] = true;
	
	//PrintToChatAll("[SM] %t", "RTV Requested", name, g_Votes, g_VotesNeeded);
	MM_PrintToChat(0, "\x05 % s\x01has Rocked The Vote!(Total Votes: % d - Needed: % d)", name, g_Votes, g_VotesNeeded);
	
	if (g_Votes >= g_VotesNeeded)
	{
		StartRTV();
	}	
}

/*
public Action:Timer_DelayRTV(Handle:timer)
{
	g_RTVAllowed = true;
}*/

StartRTV()
{
	if(g_bModVotingStarted)
	{
		return;
	}
	
	/*
	if (g_InChange)
	{
		return;	
	}
	
	
	if (EndOfMapVoteEnabled() && HasEndOfMapVoteFinished())
	{
		new String:map[65];
		if (GetNextMap(map, sizeof(map)))
		{
			PrintToChatAll("[SM] %t", "Changing Maps", map);
			CreateTimer(5.0, Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
			g_InChange = true;
			
			ResetRTV();
			
			g_RTVAllowed = false;
		}
		return;	
	}*/
	
	//if (CanMapChooserStartVote())
	{
		//new MapChange:when = MapChange:g_Cvar_ChangeTime.FloatValue;
		//InitiateMapChooserVote(when);
		CreateTimer(g_Cvar_ChangeTime.FloatValue, StartVote, .flags = TIMER_FLAG_NO_MAPCHANGE);
		
		ResetRTV();
		
		g_RTVAllowed = false;
		//CreateTimer(g_Cvar_Interval.FloatValue, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:StartVote(Handle:hTimer)
{
	new Handle:hForward = CreateGlobalForward("Vote_StartVote", ET_Single, Param_Cell);
	Call_StartForward(hForward);
	//Call_PushCell(param1);
					
	//new iResult
	Call_Finish(/*iResult*/);
	CloseHandle(hForward);
	
	return Plugin_Stop;
}

ResetRTV()
{
	g_Votes = 0;
			
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}

/*
public Action:Timer_ChangeMap(Handle:hTimer)
{
	g_InChange = false;
	
	LogMessage("RTV changing map manually");
	
	new String:map[65];
	if (GetNextMap(map, sizeof(map)))
	{	
		ForceChangeLevel(map, "RTV after mapvote");
	}
	
	return Plugin_Stop;
}
*/