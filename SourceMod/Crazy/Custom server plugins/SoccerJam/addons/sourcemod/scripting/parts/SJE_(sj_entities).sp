public void SJE_OnEntityCreated(int entity, const char[] classname)
{
	if (IsValidEdict(entity))
	{
		SDKHook(entity, SDKHook_Spawn, SJE_OnEntitySpawned)
	}
}

public void SJE_OnEntitySpawned(int entity)
{	
	char name[MAX_NAME_LENGTH];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	
	if (StrEqual(name, "sj_ballspawn", false))
	{
		float ballSpawnPoint[3];
		Entity_GetAbsOrigin(entity, ballSpawnPoint);
		SetBallSpawnPoint(ballSpawnPoint);
	} 
	/*else if (StrEqual(name, "sj_teamball_t", false) || StrEqual(name, "sj_death_zone_red", false))
	{
		Entity_GetAbsOrigin(entity, g_DeathZoneOrigins[CS_TEAM_T]);
	}
	else if (StrEqual(name, "sj_teamball_ct", false) || StrEqual(name, "sj_death_zone_blue", false))
	{
		Entity_GetAbsOrigin(entity, g_DeathZoneOrigins[CS_TEAM_CT]);
	}*/
	else if (StrEqual(name, "sj_goal_t", false) || StrEqual(name, "sj_goal_red", false))
	{
		if (GetSwapsCount() % 2 == 0)
		{
			SetGoalEntity(CS_TEAM_T, entity)
		}
		else
		{
			SetGoalEntity(CS_TEAM_CT, entity)
		}
		
	}
	else if (StrEqual(name, "sj_goal_ct", false) || StrEqual(name, "sj_goal_blue", false))
	{
		if (GetSwapsCount() % 2 == 0)
		{
			SetGoalEntity(CS_TEAM_CT, entity)
		}
		else
		{
			SetGoalEntity(CS_TEAM_T, entity)
		}
	}
}