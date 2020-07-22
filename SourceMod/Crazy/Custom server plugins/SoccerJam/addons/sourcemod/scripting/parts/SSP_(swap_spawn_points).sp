int TSpawnPoints[32]
float TSpawnPointOrigins[32][3]
float TSpawnPointAngles[32][3]
int TSpawnsCount
int CtSpawnPoints[32]
float CtSpawnPointOrigins[32][3]
float CtSpawnPointAngles[32][3]
int CtSpawnsCount
int SwapsCount

public void SSP_OnMapStart()
{
	SwapsCount = 0
	TSpawnsCount = 0
	CtSpawnsCount = 0
	int entity = INVALID_ENT_REFERENCE
	while ((entity = FindEntityByClassname(entity, "info_player_terrorist")) != INVALID_ENT_REFERENCE) 
	{
    	TSpawnPoints[TSpawnsCount] = entity
    	Entity_GetAbsOrigin(entity, TSpawnPointOrigins[TSpawnsCount])
    	Entity_GetAbsAngles(entity, TSpawnPointAngles[TSpawnsCount])
    	TSpawnsCount++
	}

	while ((entity = FindEntityByClassname(entity, "info_player_counterterrorist")) != INVALID_ENT_REFERENCE) 
	{
    	CtSpawnPoints[CtSpawnsCount] = entity
    	Entity_GetAbsOrigin(entity, CtSpawnPointOrigins[CtSpawnsCount]);
    	Entity_GetAbsAngles(entity, CtSpawnPointAngles[CtSpawnsCount]);
    	CtSpawnsCount++
	}
}

public void SSP_OnGoal(int team, int scorer)
{
	if (IsMatchPublic())
	{
		SpawnPlaces()
	}
}

public void SSP_OnEndFirstHalf()
{
	SpawnPlaces()
}

int GetSwapsCount()
{
	return SwapsCount
}

void SpawnPlaces()
{
	SpawnSpawnPoints()
	SwapGoals()
	SwapsCount++
}

void SpawnSpawnPoints()
{
	float tSpawnPointOrigin[3]
	float ctSpawnPointOrigin[3]
	float tSpawnPointAngles[3]
	float ctSpawnPointAngles[3]
	
	int tSpawnPoint, ctSpawnPoint;
	for (int i = 0; i < TSpawnsCount; i++)
	{
		tSpawnPoint = TSpawnPoints[i]
		Entity_GetAbsOrigin(tSpawnPoint, tSpawnPointOrigin)
		Entity_GetAbsAngles(tSpawnPoint, tSpawnPointAngles)
		ctSpawnPoint = CtSpawnPoints[i]
		Entity_GetAbsOrigin(ctSpawnPoint, ctSpawnPointOrigin)
		Entity_GetAbsAngles(ctSpawnPoint, ctSpawnPointAngles)
		TeleportEntity(tSpawnPoint , ctSpawnPointOrigin, ctSpawnPointAngles, NULL_VECTOR)
		TeleportEntity(ctSpawnPoint , tSpawnPointOrigin, tSpawnPointAngles, NULL_VECTOR)
	}
}

void SwapGoals()
{
	int tGoal = g_Goals[CS_TEAM_T]
	int ctGoal = g_Goals[CS_TEAM_CT]
	g_Goals[CS_TEAM_T] = ctGoal
	g_Goals[CS_TEAM_CT] = tGoal
}