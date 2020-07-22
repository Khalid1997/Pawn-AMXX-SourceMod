/*
	Originally SourceMod's base rockthevote.sp
	Adjusted to be compatible with MultiMod Plugin 
*/

#include <sourcemod>
#include <multimod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "MultiMod Plugin: Rock the Vote",
	author = "Khalid",
	description = "Rock the vote",
	version = MM_VERSION_STR,
	url = ""
};

ConVar g_Cvar_Needed;
ConVar g_Cvar_MinPlayers;
ConVar g_Cvar_InitialDelay;

bool g_CanRTV = false;		// True if RTV loaded maps and is active.
bool g_RTVAllowed = false;	// True if RTV is available to players. Used to delay rtv votes.
int g_Voters = 0;				// Total voters connected. Doesn't include fake clients.
int g_Votes = 0;				// Total number of "say rtv" votes
int g_VotesNeeded = 0;			// Necessary votes before map vote begins. (voters * percent_needed)
bool g_Voted[MAXPLAYERS+1] = {false, ...};
MultiModVote g_VotePreference[MAXPLAYERS];

bool g_InChange = false;

float g_flStartTime;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("rockthevote.phrases");
	
	g_Cvar_Needed = CreateConVar("sm_rtv_needed", "0.60", "Percentage of players needed to rockthevote (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtv_minplayers", "0", "Number of players required before RTV will be enabled.", 0, true, 0.0, true, float(MAXPLAYERS));
	g_Cvar_InitialDelay = CreateConVar("sm_rtv_initialdelay", "30.0", "Time (in seconds) before first RTV can be held", 0, true, 0.00);
	
	AutoExecConfig(true, "rtv");
}

public void OnMapStart()
{
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_InChange = false;
	
	g_flStartTime = GetGameTime();
	
	/* Handle late load */
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public void OnMapEnd()
{
	g_CanRTV = false;	
	g_RTVAllowed = false;
}

public void OnConfigsExecuted()
{	
	g_CanRTV = true;
	g_RTVAllowed = false;
	CreateTimer(g_Cvar_InitialDelay.FloatValue, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	return;
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	if (!g_CanRTV)
	{
		return;	
	}
	
	if (g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded && 
		g_RTVAllowed ) 
	{	
		StartRTV();
	}	
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (!g_CanRTV || !client)
	{
		return;
	}
	
	// == 0 not -1
	if (StrContains(sArgs, "rtv", false) == 0 || StrContains(sArgs, "rockthevote", false) == 0)
	{
		//ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		int iPos;
		if( ( iPos = StrContains(sArgs, " ", true) ) == -1 )
		{
			MultiMod_PrintToChat(client, "Write 'rtv [\x05mod/map\x01]' to specifiy what you want to rtv.");
		}
		
		else
		{
			iPos++;

			MultiModVote type = MultiModVote_None;
			
			if(StrEqual(sArgs[iPos], "mod", false))
			{
				type = MultiModVote_Normal;
			}
			
			else if(StrEqual(sArgs[iPos], "map"))
			{
				type = MultiModVote_Map;
			}
			
			if(type != MultiModVote_None)
			{
				AttemptRTV(client, type);
			}
			
			else
			{
				MultiMod_PrintToChat(client, "Wrong argument. Use rtv '\x05[mod/map]\x01' only.");
			}
		}
		
		//SetCmdReplySource(old);
	}
}

void AttemptRTV(int client, MultiModVote type)
{
	if (!g_RTVAllowed)
	{
		float flCurrGameTime = GetGameTime();
		float flAllowRTVTime = g_flStartTime + g_Cvar_InitialDelay.FloatValue;
		if ( flCurrGameTime < flAllowRTVTime )
		{
			int iMinutes, iSecs;
			iSecs = RoundFloat(flAllowRTVTime - flCurrGameTime);
			iMinutes = iSecs / 60;
			iSecs = iSecs % 60;
			
			char szTimeFormat[60];
			int iLen;
			
			if(iMinutes)
			{
				iLen = FormatEx(szTimeFormat, sizeof szTimeFormat, "%d minutes", iMinutes);
			}
			
			if(iSecs)
			{
				iLen += FormatEx(szTimeFormat[iLen], sizeof szTimeFormat - iLen, "%s%d seconds", iMinutes ? " and " : "", iSecs);
			}
			
			MultiMod_PrintToChat(client, "Please wait %s before rocking the vote.", szTimeFormat);
		}
		
		else
		{
			MultiMod_PrintToChat(client, "Rocking the vote is currently disabled. Check again later.");
		}
		
		return;
	}
		
	if ( !MultiMod_Vote_CanStartVote(false) )
	{
		MultiMod_PrintToChat(client, "RTV cannot start a vote as a vote is already running or has already completed.");
		return;
	}
	
	int iMinPlayers = g_Cvar_MinPlayers.IntValue;
	if (GetClientCount(true) < g_Cvar_MinPlayers.IntValue)
	{
		MultiMod_PrintToChat(client, "A minimum of \x04%d \x01players is needed to rock the vote.", iMinPlayers);
		return;
	}
	
	if (g_Voted[client])
	{
		MultiMod_PrintToChat(client, "You have already \x05rocked the vote.");
		return;
	}
	
	g_Votes++;
	g_Voted[client] = true;
	g_VotePreference[client] = type;
	
	MultiMod_PrintToChat(client, "Player \x05%N \x01has rocked the vote (Total: %d - Needed: %d)", client, g_Votes, g_VotesNeeded);
	
	if (g_Votes >= g_VotesNeeded)
	{
		StartRTV();
	}	
}

public Action Timer_DelayRTV(Handle timer)
{
	g_RTVAllowed = true;
}

void StartRTV()
{
	if (g_InChange)
	{
		return;	
	}
	
	MultiModVote iDominantType;
	int iVoteTypeCount[2];	// 0 --  Mod, 1 -- Map
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		if(!g_Voted[i])
		{
			continue;
		}
		
		if(g_VotePreference[i] == MultiModVote_Normal)
		{
			iVoteTypeCount[0]++;
		}
		
		else if(g_VotePreference[i] == MultiModVote_Map)
		{
			iVoteTypeCount[1]++;
		}
	}	
	
	char MOD_VOTE_STR[] = "'Mod Vote'";
	char MAP_VOTE_STR[] = "'Map Vote'";
	
	if(iVoteTypeCount[0] > iVoteTypeCount[1])
	{
		iDominantType = MultiModVote_Normal;
		MultiMod_PrintToChatAll("RTV: Starting \x07%s \x01(Total: \x04%d \x01- Mod Votes: \x04%d \x01- Map Votes: \x04%d\x01).",
		MOD_VOTE_STR, 
		g_Votes, iVoteTypeCount[0], iVoteTypeCount[1]);
	}
	
	else if(iVoteTypeCount[0] < iVoteTypeCount[1])
	{
		iDominantType = MultiModVote_Map;
		
		char szModName[MM_MAX_MOD_PROP_LENGTH];
		MultiMod_GetModProp(MultiMod_GetCurrentModId(), MultiModProp_Name, szModName, sizeof szModName);
		
		MultiMod_PrintToChatAll("RTV: Starting \x07%s \x01for current mod \x07%s \x01(Total: \x04%d \x01- Mod Votes: \x04%d \x01- Map Votes: \x04%d\x01).",
		MAP_VOTE_STR, szModName,
		g_Votes, iVoteTypeCount[0], iVoteTypeCount[1]);
	}
	
	else
	{
		iDominantType = GetRandomInt(0,1) ? MultiModVote_Mod : MultiModVote_Map;
		MultiMod_PrintToChatAll("RTV: Selected \x07%s \x01as the vote from randomizing (Total: \x04%d \x01- Mod Votes: \x04%d \x01- Map Votes: \x04%d\x01).", 
		iDominantType == MultiModVote_Normal ? MOD_VOTE_STR : MAP_VOTE_STR, 
		g_Votes, iVoteTypeCount[0], iVoteTypeCount[1]);
	}
	
	ResetRTV();
	MultiMod_Vote_StartVote(iDominantType, true);
	
}

void ResetRTV()
{
	g_Votes = 0;
			
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}