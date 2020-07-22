enum MatchState
{
	MatchState_Preparing,
	MatchState_FirstHalf,
	MatchState_HalfTime,
	MatchState_SecondHalf,
	MatchState_OverTime,
	MatchState_Public,
}

PrivateForward OnStartOverTimeForward
PrivateForward OnStartPublicForward
PrivateForward OnStartMatchForward
PrivateForward OnEndPublicForward
PrivateForward OnEndFirstHalfForward
PrivateForward OnEndMatchForward

MatchState CurrentState
ConVar CvarGoalsToWin

int MatchTimeIsUpSoundId

// API //

public bool IsMatchPublic()
{
	return CurrentState == MatchState_Public
}

public int GetWinLimit()
{
	return GetConVarInt(CvarGoalsToWin)
}

/////////

public void MTCH_Init()
{
	RegAdminCmd("sj_match_start", MTCH_Cmd_StartMatch, ADMFLAG_CHANGEMAP)
	RegAdminCmd("sj_public_start", MTCH_Cmd_StartPublic, ADMFLAG_CHANGEMAP)
	
	OnStartOverTimeForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnStartOverTimeForward, "OnStartOverTime")

	OnStartPublicForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnStartPublicForward, "OnStartPublic")

	OnStartMatchForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnStartMatchForward, "OnStartMatch")

	OnEndPublicForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnEndPublicForward, "OnEndPublic")

	OnEndFirstHalfForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnEndFirstHalfForward, "OnEndFirstHalf")

	OnEndMatchForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnEndMatchForward, "OnEndMatch")
	
	CvarGoalsToWin = CreateConVar("sj_goals_to_win", "15", "How many goals need to win in public mode", 0, true, 1.0)
	MatchTimeIsUpSoundId = CreateSound("match_timeisup")
	AddCommandListener(MTCH_Cmd_Say, "say")
	AddCommandListener(CMD_JoinClass, "joinclass")
}

public void MTCH_OnMapStart()
{
	Match_StartPublic()
}

public void MTCH_Event_MatchEndRestart(Handle event, char[] name, bool dontBroadcast)
{
	Match_StartPublic()
}

public void Match_StartPublic()
{
	CurrentState = MatchState_Public
	ClearAllClients()
	g_BallSpawnTeam = CS_TEAM_NONE
	//CS_TerminateRound(0.0, CSRoundEnd_GameStart)
	
	SJ_ResetTeamScores();
	
	CS_TerminateRound(0.0, CSRoundEnd_Draw, true)

	FireOnStartPublic()
}

void Match_StartPreparing()
{
	CurrentState = MatchState_Preparing
	ForEachPlayer(Client_KillForPreparing)
	FireOnStartMatch()
}

public void Match_StartFirstHalf()
{
	CurrentState = MatchState_FirstHalf
	SJ_ResetTeamScores()
	g_BallSpawnTeam = CS_TEAM_NONE	
	Half_Start()
}

public void Match_StartHalfTime()
{
	CurrentState = MatchState_HalfTime
	ForEachPlayer(Client_KillForPreparing)
	PrintCenterTextAll("HALF TIME")
}

public void Match_StartSecondHalf()
{
	CurrentState = MatchState_SecondHalf
	g_BallSpawnTeam = CS_TEAM_NONE
	Half_Start()
}

public void Match_StartOverTime()
{
	PrintCenterTextAll("OVERTIME")
	CurrentState = MatchState_OverTime
	g_BallSpawnTeam = CS_TEAM_NONE	
	FireOnStartOverTime()
}

void Match_End()
{
	FireOnEndMatch()
	CreateSjTimer(10, Match_StartPublic, "public mode start in ")
}

public void MTCH_OnHalfEnd()
{
	switch (CurrentState)
	{
		case MatchState_FirstHalf:
		{
			Match_StartHalfTime()
			PlaySoundByIdToAll(MatchTimeIsUpSoundId)
			FireOnEndFirstHalf()
		}
		case MatchState_SecondHalf:
		{
			if (!Match_CheckForWin())
			{
				CreateSjTimer(5, Match_StartOverTime, "OverTime start in ")
			}
			PlaySoundByIdToAll(MatchTimeIsUpSoundId)
		}
	}
}

public void MTCH_OnGoal(int team, int scorer)
{	
	CSRoundEndReason reason = (team == CS_TEAM_T) ? CSRoundEnd_TerroristWin : CSRoundEnd_CTWin
	switch (CurrentState)
	{
		case MatchState_FirstHalf:
		{
			CS_TerminateRound(6.0, reason, true)
			FireMvpEvent(scorer)
		}
		case MatchState_SecondHalf:
		{
			CS_TerminateRound(6.0, reason, true)
			FireMvpEvent(scorer)
		}
		case MatchState_OverTime:
		{
			if (Match_CheckForWin())
			{
				CurrentState = MatchState_Public
				CS_TerminateRound(6.0, reason, true)
				FireMvpEvent(scorer)
			}
		}
		case MatchState_Public:
		{
			if (!CheckForGameEnd())
			{
				CS_TerminateRound(6.0, reason, true)
				FireMvpEvent(scorer)
			}
		}
	}
}

void FireMvpEvent(int client)
{
	Handle event = CreateEvent("round_mvp") 
	SetEventInt(event, "userid", GetClientUserId(client))
	const MVP_REASON = 0
	SetEventInt(event, "reason", MVP_REASON)
	FireEvent(event)
}

public void MTCH_Event_PlayerSpawn(Handle event, const char [] name, bool dontBroadcast)
{	
	CheckForStartMatch()
}

public void MTCH_Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{	
	CheckForStartMatch()
}

void CheckForStartMatch()
{
	switch (CurrentState)
	{
		case MatchState_Preparing:
		{
			if (IsTeamsReady())
			{
				CreateSjTimer(10, Match_StartFirstHalf, "Match start in ", true)
			}
		}
		case MatchState_HalfTime:
		{
			if (IsTeamsReady())
			{
				CreateSjTimer(10, Match_StartSecondHalf, "2nd Half start in ", true)
			}
		}
	}
}

bool IsTeamsReady()
{
	return Team_GetClientCount(CS_TEAM_T, CLIENTFILTER_DEAD) == 0
		&& Team_GetClientCount(CS_TEAM_CT, CLIENTFILTER_DEAD) == 0
}

void Match_OnClientReady(int client)
{
	if (Match_IsWaitingPlayers())
	{
		Client_Respawn(client)
	}
}

bool Match_CheckForWin()
{
	int ctScore = GetTeamScore(CS_TEAM_CT)
	int tScore = GetTeamScore(CS_TEAM_T)
	if (ctScore > tScore)
	{
		Match_End()
		return true
	}
	else if (tScore > ctScore)
	{
		
		Match_End()
		return true
	}
	return false
}

bool Match_IsWaitingPlayers()
{
	return CurrentState == MatchState_Preparing
		|| CurrentState == MatchState_HalfTime
}

bool CheckForGameEnd()
{
	int goalsToWin = GetConVarInt(CvarGoalsToWin)
	int ctScore = GetTeamScore(CS_TEAM_CT)
	int tScore = GetTeamScore(CS_TEAM_T)
	if (ctScore >= goalsToWin
			|| tScore >= goalsToWin)
	{
		FireOnEndPublic()
		
		#if defined SPAWN_GAME_END_ENTITY
		Game_End()
		#else
		CreateSjTimer(10, Match_StartPublic, "Restarting Match in ")
		#endif
		
		return true
	}
	
	return false
}

public Action MTCH_Cmd_StartMatch(int client, int argc) 
{
	Match_StartPreparing()
	return Plugin_Handled
}

public Action MTCH_Cmd_StartPublic(int client, int argc) 
{
	Match_StartPublic()
	return Plugin_Handled
}

public Action MTCH_Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{	
	CheckForStartMatch()
	return Plugin_Continue
}

public Action MTCH_Cmd_Say(int client, const char[] command, int argc) 
{
	char text[192]
	if(!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue
	}
	StripQuotes(text)
	if (StrEqual(text, "ready", false))
	{
		Match_OnClientReady(client)
	}
	return Plugin_Continue
}

public Action CMD_JoinClass(int client, const char[] command, int argc) 
{
	if (Match_IsWaitingPlayers())
	{
		FakeClientCommandEx(client, "spec_mode")		
	}
	else
	{
		CreateTimer(1.0, Timer_PlayerRespawn, GetClientUserId(client))
	}
	return Plugin_Handled
}

void FireOnStartOverTime()
{
	Call_StartForward(OnStartOverTimeForward)
	Call_Finish()
}

void FireOnStartPublic()
{
	Call_StartForward(OnStartPublicForward)
	Call_Finish()
}

void FireOnStartMatch()
{
	Call_StartForward(OnStartMatchForward)
	Call_Finish()
}

void FireOnEndPublic()
{
	Call_StartForward(OnEndPublicForward)
	Call_Finish()
}

void FireOnEndFirstHalf()
{
	Call_StartForward(OnEndFirstHalfForward)
	Call_Finish()
}

void FireOnEndMatch()
{
	Call_StartForward(OnEndMatchForward)
	Call_Finish()
}