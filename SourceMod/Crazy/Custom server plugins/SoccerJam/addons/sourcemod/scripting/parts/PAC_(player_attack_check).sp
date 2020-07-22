ConVar FightRadiusConVar

public void PAC_Init()
{
	FightRadiusConVar = CreateConVar("sj_fight_radius", "0", "The possibility of attack players.\n-1 = Everyone can attack all\n0 = Possible only attack ball holder, ball holder can attack all\n> 0 = Radius around the ball, where everyone can attack each", 0, true, -1.0);
}

public void PAC_Event_PlayerActivate(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	SDKHook(client, SDKHook_OnTakeDamage, PAC_OnTakeDamage)
}

public Action PAC_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (victim == attacker || attacker == 0)
	{
		return Plugin_Continue;
	}
	int fightRadius = GetConVarInt(FightRadiusConVar)
	if (fightRadius < 0)
	{
		return Plugin_Continue;
	}
	if (fightRadius == 0
		&& (victim == g_BallHolder || attacker == g_BallHolder))
	{
		return Plugin_Continue;
	}
	float playerOrig[3];
	float ballOrigin[3];
	if (IsValidEntity(g_Ball))
	{
		Entity_GetAbsOrigin(g_Ball, ballOrigin);
		Entity_GetAbsOrigin(victim, playerOrig);
		if (GetVectorDistance(ballOrigin, playerOrig) <= fightRadius)
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Handled
}