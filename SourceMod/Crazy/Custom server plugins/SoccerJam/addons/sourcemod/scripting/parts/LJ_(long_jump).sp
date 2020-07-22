Handle LongJumpEnableTimers[MAXPLAYERS+1]
bool IsLongJumpEnabled[MAXPLAYERS+1]
int LongJumpCooldownUpgradeId

public void LJ_Init()
{
	LongJumpCooldownUpgradeId = CreateUpgrade("longjump_cooldown", 10.0, 5.0, 5, 1, "s")
}

public void LJ_Event_PlayerActivate(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	SDKHook(client, SDKHook_PreThink, LJ_OnPreThink)
}

public void LJ_OnMapStart()
{
	ForEachClient(ResetClientSideJump)
}

public void LJ_Event_MatchEndRestart(Handle event, const char[] name, bool dontBroadcast)
{	
	ForEachClient(ResetClientSideJump)
}

public void LJ_Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int team = GetClientTeam(client);
	if (team != CS_TEAM_NONE)
	{
		ResetClientSideJump(client)
	}
}

public void LJ_Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	ResetClientSideJump(client)
}

public void LJ_OnPreThink(int client)
{
	if (client != g_BallHolder)
	{
		int buttons = GetClientButtons(client)
		int flags = GetEntityFlags(client)
		if((buttons & IN_MOVERIGHT || buttons & IN_MOVELEFT) 
			&& buttons & IN_JUMP
			&& flags & FL_ONGROUND
			&& !Client_IsInTurboMode(client)
			&& IsLongJumpEnabled[client])
		{
			LongJumpClient(client)
		}
	}
}

void LongJumpClient(int client)
{
	float vel[3];
	Entity_GetLocalVelocity(client, vel);
	
	vel[0] *= 2.0;
	vel[1] *= 2.0;
	vel[2] = 300.0;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	IsLongJumpEnabled[client] = false;
	LongJumpEnableTimers[client] = CreateTimer(GetPlayerUpgradeValue(client, LongJumpCooldownUpgradeId), Timer_LongJumpEnable, client);
}

public Action Timer_LongJumpEnable(Handle timer, any client)
{
	IsLongJumpEnabled[client] = true
	if (LongJumpEnableTimers[client] != INVALID_HANDLE)
	{
		KillTimer(LongJumpEnableTimers[client])
		LongJumpEnableTimers[client] = INVALID_HANDLE
	}
	return Plugin_Continue
}

public void ResetClientSideJump(int client)
{
	if (LongJumpEnableTimers[client] != INVALID_HANDLE)
	{
		KillTimer(LongJumpEnableTimers[client]);
		LongJumpEnableTimers[client] = INVALID_HANDLE;
	}
	IsLongJumpEnabled[client] = true;
}
