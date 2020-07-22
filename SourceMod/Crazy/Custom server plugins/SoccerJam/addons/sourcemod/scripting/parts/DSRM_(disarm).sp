Handle DisarmTimers[MAXPLAYERS+1]

int DisarmUpgradeId

int DisarmStatsId
int KnifeKillsStatsId

public void DSRM_Init()
{
	DisarmUpgradeId = CreateUpgrade("disarm", 10.0, 90.0, 5, 1, "%")

	DisarmStatsId = CreateMatchStats("Most disarm")
	KnifeKillsStatsId = CreateMatchStats("Most knife kills")
}

public void DSRM_OnMapStart()
{
	ForEachClient(ResetClientWeapon)
}

public void DSRM_Event_MatchEndRestart(Handle event, const char[] name, bool dontBroadcast)
{	
	ForEachClient(ResetClientWeapon)
}

public void DSRM_Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int team = GetClientTeam(client)	
	if (team != CS_TEAM_NONE)
	{
		ResetClientWeapon(client)
	}
	
}

public void DSRM_Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	ResetClientWeapon(client)
	if (attacker > 0 && client != attacker)
	{
		char weaponName[MAX_NAME_LENGTH]
		GetEventString(event, "weapon", weaponName, sizeof(weaponName))
		if (StrEqual(weaponName, "weapon_knife"))
		{
			AddMatchStatsValue(KnifeKillsStatsId, attacker, 1)
		}
	}
}

public void DSRM_Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	if (client == attacker)
	{
		return
	}	
	int rand = GetRandomInt(1, 100)

	if (GetPlayerUpgradeValue(attacker, DisarmUpgradeId) >= rand)
	{
		if (client == g_BallHolder) 
		{
			SetBallHolder(attacker)
		}
		else
		{
			Client_RemoveAllWeapons(client)
			DisarmTimers[client] = CreateTimer(4.0, Timer_GiveWeapon, client)
		}
		AddMatchStatsValue(DisarmStatsId, attacker, 1)
	}
}

public Action Timer_GiveWeapon(Handle timer, any client)
{
	DisarmTimers[client] = INVALID_HANDLE
	GivePlayerWeapon(client)
	return Plugin_Continue
}

public void ResetClientWeapon(int client)
{
	if (DisarmTimers[client] != INVALID_HANDLE)
	{
		KillTimer(DisarmTimers[client])
		DisarmTimers[client] = INVALID_HANDLE
	}
}