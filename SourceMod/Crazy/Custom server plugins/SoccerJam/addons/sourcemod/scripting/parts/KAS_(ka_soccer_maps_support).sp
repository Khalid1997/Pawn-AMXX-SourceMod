public void KAS_Init()
{
	
}

public void KAS_Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	FindPoints();
}

void FindPoints()
{
	char mapName[MAX_NAME_LENGTH];
	GetCurrentMap(mapName, MAX_NAME_LENGTH);
	if (StrContains(mapName, "ka_", false) >= 0)
	{
		FindKaBallSpawn();
		FindKaGoals();
	}
}

void FindKaBallSpawn()
{
	int kaBallEntity = FindEntityByClassname(-1, "func_physbox");
	if (kaBallEntity > 0)
	{
		float ballSpawnPoint[3];
		Entity_GetAbsOrigin(kaBallEntity, ballSpawnPoint);
		SetBallSpawnPoint(ballSpawnPoint);
		
		Entity_Kill(kaBallEntity);
	}
}

void FindKaGoals()
{
	if (FindKaGoalsByClass("trigger_multiple"))
	{
		return;
	}
	FindKaGoalsByClass("trigger_once");
}

bool FindKaGoalsByClass(const char[] className)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, className)) != INVALID_ENT_REFERENCE) 
	{
		if (IsGoalEntity(entity))
		{
			int team = GetEntityTeam(entity);
			SetGoalEntity(team, entity)
		}
	}
	return g_Goals[CS_TEAM_CT] > 0
		&& g_Goals[CS_TEAM_T] > 0;
}

bool IsGoalEntity(int entity)
{
	float entityOrigin[3];
	Entity_GetAbsOrigin(entity, entityOrigin);
	float ballSpawnOrigin[3];
	GetBallSpawnOrigin(ballSpawnOrigin);
	
	float heightDifference = entityOrigin[2] - ballSpawnOrigin[2];
	return GetEntityRadius(entity) < 300.0
		&& FloatAbs(heightDifference) < 100.0;
}

int GetEntityTeam(int entity)
{
	int someBlueSpawn = FindEntityByClassname(-1, "info_player_counterterrorist");
	int someRedSpawn = FindEntityByClassname(-1, "info_player_terrorist");
	float blueDistance = Entity_GetDistance(entity, someBlueSpawn);
	float redDistance = Entity_GetDistance(entity, someRedSpawn);
	if (blueDistance < redDistance)
	{
		return CS_TEAM_CT;
	}
	return CS_TEAM_T;
}