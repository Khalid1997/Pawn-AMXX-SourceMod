Handle DeathZoneRadiusConVar
Handle DeathZoneDamageMinConVar
Handle DeathZoneDamageMaxConVar
DeathZoneKillSoundId

public void DZ_Init()
{
	DeathZoneRadiusConVar = CreateConVar("sj_death_zone_radius", "650", "Radius of death zone that does damage to enemy", 0, true, 0.0)
	DeathZoneDamageMinConVar = CreateConVar("sj_death_zone_damage_min", "5", "Min damage of death zone", 0, true, 0.0)
	DeathZoneDamageMaxConVar = CreateConVar("sj_death_zone_damage_max", "15", "Max damage of death zone", 0, true, 0.0)
	DeathZoneKillSoundId = CreateSound("death_zone_kill")
	CreateTimer(1.0, Timer_CheckDeathZone, _, TIMER_REPEAT)
}

public Action Timer_CheckDeathZone(Handle timer)
{	
	if (!g_Goal)
	{
		CheckDeathZones()
	}
	return Plugin_Continue
}

void CheckDeathZones()
{
	CheckDeathZone(CS_TEAM_CT)
	CheckDeathZone(CS_TEAM_T)
}

void CheckDeathZone(int team)
{
	int[] playersInZone = new int[MaxClients+1]
	int	playersInZoneCount = 0
	int chosenPlayer = 0
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsPlayerAlive(i)
				&& GetClientOpponentSJTeam(i) == team
				&& IsClientInDeathZone(i, team))
			{	
				playersInZone[playersInZoneCount++] = i
				if (i == g_BallHolder) 
				{
					chosenPlayer = i
					break
				}
			}
		}
	}
	if (playersInZoneCount > 0)
	{
		if (!chosenPlayer) 
		{
			int randomIndex = GetRandomInt(0, (playersInZoneCount-1))
			chosenPlayer = playersInZone[randomIndex]
		}
		int minDamage = GetConVarInt(DeathZoneDamageMinConVar)
		int maxDamage = GetConVarInt(DeathZoneDamageMaxConVar)
		int damage = (chosenPlayer == g_BallHolder) ? GetClientHealth(chosenPlayer) : GetRandomInt(minDamage, maxDamage)
		TerminatePlayer(chosenPlayer, team, damage)
	}
	float radius = GetConVarFloat(DeathZoneRadiusConVar) * 2
	float goalOverrideOrigin[3]
	GetGoalOverrideOrigin(goalOverrideOrigin, team)
	TE_SetupBeamRingPoint(goalOverrideOrigin, radius + 0.1, radius, g_LaserCache, 0, 0, 66, 0.5, 10.0, 1.0, g_TeamColors[team], 0, 0)
	TE_SendToAll()
}

void TerminatePlayer(int client, int team, int dmg) 
{	
	Entity_Hurt(client, dmg, 0, DMG_DROWN, "sj_death_zone")
	if (!IsPlayerAlive(client))
	{
		Effect_DissolvePlayerRagDoll(client)
		PlaySoundByIdToAll(DeathZoneKillSoundId)
	}
	float goalOverrideOrigin[3]
	GetGoalOverrideOrigin(goalOverrideOrigin, team)
	float startOrigin[3]
	startOrigin[0] += goalOverrideOrigin[0]
	startOrigin[1] += goalOverrideOrigin[1]
	startOrigin[2] += goalOverrideOrigin[2] + 256.0
	float clientOrigin[3]
	GetClientAbsOrigin(client, clientOrigin)
	TE_SetupBeamPoints(startOrigin, clientOrigin, g_LaserCache, 0, 0, 66, 0.5, 10.0, 10.0, 0, 1.0, g_TeamColors[team], 0)
	TE_SendToAll()
}

public bool IsClientInOwnDeathZone(int client)
{
	int team = GetClientTeam(client);
	return IsClientInDeathZone(client, team);
}

bool IsClientInDeathZone(int client, int deathZoneTeam)
{
	float goalOverrideOrigin[3]
	GetGoalOverrideOrigin(goalOverrideOrigin, deathZoneTeam)
	float clientOrigin[3]
	GetClientAbsOrigin(client, clientOrigin)
	return GetVectorDistance(goalOverrideOrigin, clientOrigin) < GetConVarFloat(DeathZoneRadiusConVar)
}