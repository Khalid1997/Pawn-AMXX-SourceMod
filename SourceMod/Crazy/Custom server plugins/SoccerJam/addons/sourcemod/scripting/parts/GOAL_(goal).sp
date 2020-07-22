
Handle OnGoalForward
int GoalSoundId
int GoalSirenSoundId

public void GOAL_Init()
{
	OnGoalForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell)
	RegisterCustomForward(OnGoalForward, "OnGoal")

	GoalSoundId = CreateSound("goal")
	GoalSirenSoundId = CreateSound("goal_siren")
}

public void GOAL_Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_Goal = false
}

public void GOAL_OnBallCreated(int ballEntity)
{
	SDKHook(g_Ball, SDKHook_Touch, GOAL_OnBallTouch)
}

public void  GOAL_OnBallTouch(int ball, int entity)
{
	if (g_IsBallFree)
	{
		if (entity == g_Goals[CS_TEAM_CT])
		{
			CheckForGoal(CS_TEAM_T);		
		}
		else if (entity == g_Goals[CS_TEAM_T])
		{
			CheckForGoal(CS_TEAM_CT);
		}
	}
}

void CheckForGoal(int team)
{
	if (!g_Goal)
	{
		if (g_BallOwner 
			&& GetClientTeam(g_BallOwner) == team)
		{			
			ScoreGoal(team, g_BallOwner)
		}
	}
}

void ScoreGoal(int team, int scorer)
{
	g_Goal = true;
	SJ_IncreaseTeamScore(team);
	ShowGoalInfoForSpecs();
	PlaySoundByIdToAll(GoalSirenSoundId)
	PlaySoundByIdToAll(GoalSoundId)	

	Handle event = CreateEvent("cs_win_panel_round") 
	SetEventBool(event, "show_timer_defend", true)
	SetEventBool(event, "show_timer_attack", true)
	SetEventInt(event, "timer_time", 10)
	if (team == CS_TEAM_CT)
	{
		SetEventInt(event, "final_event", view_as<int>(CSRoundEnd_CTWin))
	}
	else if (team == CS_TEAM_T)
	{
		SetEventInt(event, "final_event", view_as<int>(CSRoundEnd_TerroristWin))
	}
	
	FireOnGoal(team, scorer)
}

void FireOnGoal(int team, int scorer)
{
	Call_StartForward(OnGoalForward)
	Call_PushCell(team)
	Call_PushCell(scorer)
	Call_Finish()
}

void ShowGoalInfoForSpecs()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client)
			&& GetClientTeam(client) == CS_TEAM_SPECTATOR)
		{
			char status[MAX_HINTTEXT_LENGTH];
			Format(status, sizeof(status), "%T!\n%T", "GOAL", client, "SCORER", client, g_BallOwnerName);
			PrintHintText(client, status);
		}
	}
}