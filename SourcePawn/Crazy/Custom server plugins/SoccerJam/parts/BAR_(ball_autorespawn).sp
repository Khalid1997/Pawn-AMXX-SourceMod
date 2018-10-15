Handle CvarBallAutoRespawn;
Handle TmrBallRespawn;

public void BAR_Init()
{
	CvarBallAutoRespawn = CreateConVar("sj_ball_respawn_time", "30", "Time after which the ball respawn (if no ball holder)", 0, true, 1.0);
}

public void BAR_OnBallKicked(int client)
{
	StartBallRespawnTimer();
}

public void BAR_Event_PrePlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == g_BallHolder)
	{
		StartBallRespawnTimer();
	}
}

public void BAR_OnBallHolderDeath(int client)
{
	StartBallRespawnTimer();
}

public void BAR_OnBallReceived(int client, int oldBallOwner)
{
	StopBallRespawnTimer();
}

public void BAR_OnBallSpawned(int ballEntity, int ballSpawnTeam)
{
	StopBallRespawnTimer();
}

public Action BAR_Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	TmrBallRespawn = INVALID_HANDLE;
	return Plugin_Continue;
}

public void BAR_OnGoal(int team, int scorer)
{
	StopBallRespawnTimer();
}

void StartBallRespawnTimer()
{
	if (TmrBallRespawn == INVALID_HANDLE)
	{
		float respawnTime = GetConVarFloat(CvarBallAutoRespawn);
		TmrBallRespawn = CreateTimer(respawnTime, Timer_RespawnBall, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void BAR_OnMapStart()
{
	TmrBallRespawn = INVALID_HANDLE;
}

public Action Timer_RespawnBall(Handle timer)
{
	StopBallRespawnTimer();
	RespawnBallWithNotify();
	return Plugin_Continue;
}

void StopBallRespawnTimer()
{
	ClearTimer(TmrBallRespawn);
}