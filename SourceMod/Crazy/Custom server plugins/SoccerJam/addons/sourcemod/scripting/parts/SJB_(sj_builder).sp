int GoalOverrideModelId

public void SJB_Init()
{
	GoalOverrideModelId = CreateModel("goal_override")
}

public void SJB_OnMapStart()
{
	SetGoalEntity(CS_TEAM_T, INVALID_ENT_REFERENCE)
	SetGoalEntity(CS_TEAM_CT, INVALID_ENT_REFERENCE)
}

public void SJB_Event_RoundPreStart(Handle event,const char[] name, bool dontBroadcast)
{
	SetGoalEntity(CS_TEAM_T, INVALID_ENT_REFERENCE)
	SetGoalEntity(CS_TEAM_CT, INVALID_ENT_REFERENCE)
}

public void SJB_Event_RoundStart(Handle event,const char[] name, bool dontBroadcast)
{
	if (g_Goals[CS_TEAM_CT] == INVALID_ENT_REFERENCE)
	{
		BuildGoalEntity(CS_TEAM_CT)
	}
	if (g_Goals[CS_TEAM_T] == INVALID_ENT_REFERENCE)
	{
		BuildGoalEntity(CS_TEAM_T)
	}
}

void BuildGoalEntity(int team)
{
	float goalOrigin[3]
	GetRandomTeamSpawnOrigin(team, goalOrigin)
	int goalEntity = SpawnGoalEntity()
	TeleportEntity(goalEntity , goalOrigin, NULL_VECTOR, NULL_VECTOR)
	SetGoalEntity(team, goalEntity)
}

/*

void GetRandomTeamSpawnOrigin(int team, float destOrigin[3])
{
	int spawnPoints[MAXPLAYERS]
	int spawnPointCount = 0;
	int index = -1;
	while ((index = FindEntityByClassname(index, g_TeamSpawnEntityNames[team])) != -1)
	{
		spawnPoints[spawnPointCount++] = index;
	}
	if (spawnPointCount > 0)
	{
		int randomIndex = GetRandomInt(0, spawnPointCount - 1);
		Entity_GetAbsOrigin(spawnPoints[randomIndex], destOrigin);
	}
}

*/

void SetGoalEntity(int team, int entity)
{
	g_Goals[team] = entity
	if (entity != INVALID_ENT_REFERENCE)
	{
		SetEntityRenderColor(entity, 255, 255, 255, 255)
	}
}

void GetGoalOverrideOrigin(float dest[3], int team)
{
	if (g_Goals[team] != INVALID_ENT_REFERENCE)
	{
		Entity_GetAbsOrigin(g_Goals[team], dest)
	}
}

int SpawnGoalEntity()
{
	char modelPath[PLATFORM_MAX_PATH]
	GetModelPath(GoalOverrideModelId, modelPath)
	int goalEntity = CreateEntityByName("prop_dynamic")
	DispatchKeyValue(goalEntity, "solid", "6")
	DispatchKeyValue(goalEntity, "StartDisabled", "0")
	DispatchKeyValue(goalEntity, "model", modelPath)
	DispatchSpawn(goalEntity)
	SetEntityRenderMode(goalEntity, RENDER_TRANSCOLOR)
	return goalEntity
}