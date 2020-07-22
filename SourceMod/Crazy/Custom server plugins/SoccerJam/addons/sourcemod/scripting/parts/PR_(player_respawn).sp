public void PR_Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int userId = GetEventInt(event, "userid")
	CreateTimer(2.0, Timer_PlayerRespawn, userId, TIMER_FLAG_NO_MAPCHANGE)
}

public Action Timer_PlayerRespawn(Handle timer, any userId)
{
	int client = GetClientOfUserId(userId)
	if (client)
	{
		if (!IsPlayerAlive(client) 
			&& GetClientTeam(client) != CS_TEAM_NONE
			&& GetClientTeam(client) != CS_TEAM_SPECTATOR
			&& !Match_IsWaitingPlayers())
		{
			CS_RespawnPlayer(client)
		}
	}
	return Plugin_Continue
}

public void PR_Event_PlayerTeam(Handle event, const char[] name, bool bDontBroadcast)
{
	int userId = GetEventInt(event, "userid")
	CreateTimer(2.0, Timer_PlayerRespawn, userId, TIMER_FLAG_NO_MAPCHANGE)
	
}