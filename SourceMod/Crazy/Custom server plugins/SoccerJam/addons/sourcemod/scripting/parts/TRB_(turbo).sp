Handle TurboTimers[MAXPLAYERS+1]
Handle TurboEnableTimers[MAXPLAYERS+1]

int TurboDurationUpgradeId
int TurboCooldownUpgradeId
bool IsInTurbo[MAXPLAYERS+1];
bool IsTurboEnabled[MAXPLAYERS+1];

public void TRB_Init()
{
	TurboDurationUpgradeId = CreateUpgrade("turbo_duration", 5.0, 10.0, 5, 1, "s")
	TurboCooldownUpgradeId = CreateUpgrade("turbo_cooldown", 10.0, 5.0, 5, 1, "s")
	AddCommandListener(Cmd_Turbo, "drop")
}

public void TRB_OnMapStart()
{
	ForEachClient(ClearClientTurbo)
}

public void TRB_Event_MatchEndRestart(Handle event, const char[] name, bool dontBroadcast)
{	
	ForEachClient(ClearClientTurbo)
}

public void TRB_Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int team = GetClientTeam(client);
	if (team != CS_TEAM_NONE)
	{
		ClearClientTurbo(client)
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0)
	}
}

public void TRB_Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	ClearClientTurbo(client)
}

void Client_UpdateSpeed(int client)
{
	float multiplier = GetPlayerSpeedMultiplier(client)
	float turboSpeedMultiplier = IsInTurbo[client] ? 0.3 : 0.0
	float totalMultiplier = multiplier + turboSpeedMultiplier
	g_PlayerSpeedMultiplier[client] = totalMultiplier
}

public Action Cmd_Turbo(int client, const char[] command, int argc) 
{
	Client_StartTurboMode(client)
	return Plugin_Handled
}

void Client_StartTurboMode(int client)
{
	if (IsTurboEnabled[client] && !IsInTurbo[client])
	{
		IsInTurbo[client] = true
		float turboDuration = GetPlayerUpgradeValue(client, TurboDurationUpgradeId)
		TurboTimers[client] = CreateTimer(turboDuration, Timer_EndTurbo, client)		
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime())
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", RoundFloat(turboDuration))
		Client_UpdateSpeed(client)
	}
}

void Client_EndTurboMode(int client)
{
	TurboTimers[client] = INVALID_HANDLE
	IsInTurbo[client] = false
	IsTurboEnabled[client] = false
	Client_UpdateSpeed(client)
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0)
}

bool Client_IsInTurboMode(int client)
{
	return IsInTurbo[client]
}

public void ClearClientTurbo(int client)
{
	if (TurboTimers[client] != INVALID_HANDLE)
	{
		KillTimer(TurboTimers[client])
		TurboTimers[client] = INVALID_HANDLE
	}
	if (TurboEnableTimers[client] != INVALID_HANDLE)
	{
		KillTimer(TurboEnableTimers[client])
		TurboEnableTimers[client] = INVALID_HANDLE
	}	
	IsInTurbo[client] = false
	IsTurboEnabled[client] = true
	Client_UpdateSpeed(client)
}

public Action Timer_EndTurbo(Handle timer, any client) 
{
	Client_EndTurboMode(client)
	TurboEnableTimers[client] = CreateTimer(GetPlayerUpgradeValue(client, TurboCooldownUpgradeId), Timer_EnableTurbo, client)
	return Plugin_Continue
}

public Action Timer_EnableTurbo(Handle timer, any client)
{
	IsTurboEnabled[client] = true
	if (TurboEnableTimers[client] != INVALID_HANDLE)
	{
		KillTimer(TurboEnableTimers[client])
		TurboEnableTimers[client] = INVALID_HANDLE
	}
	return Plugin_Continue
}