Handle BallSpawnCenterConVar;
Handle OnBallSpawnedForward;
Handle OnBallCreatedForward;
bool IsSpawnExists;
int BallModelId;
int FastBallPickUpSoundId;
int BallRespawnedSoundId;


public void BALL_Init()
{
	OnBallSpawnedForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell);
	RegisterCustomForward(OnBallSpawnedForward, "OnBallSpawned");
	OnBallCreatedForward = CreateForward(ET_Ignore, Param_Cell);
	RegisterCustomForward(OnBallCreatedForward, "OnBallCreated");
	
	BallModelId = CreateModel("ball");
	FastBallPickUpSoundId = CreateSound("fastball_pickup");
	BallRespawnedSoundId = CreateSound("ball_respawned");
	
	
	BallSpawnCenterConVar = CreateConVar("sj_ball_spawn_always_center", "0", "if 0, ball spawn always near team that conceded goal", 0, true, 0.0, true, 1.0);
	
	RegAdminCmd("sj_respawn_ball", CMD_RespawnBall, ADMFLAG_CHANGEMAP);
}

public void BALL_OnMapStart()
{
	ClearBallSpawnPoint();
}

public void BALL_Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	CreateBall();
	if (g_BallSpawnTeam == CS_TEAM_NONE)
	{
		if (IsSpawnExists)
		{
			Ball_RespawnAtCenter();
		}
		else
		{
			RespawnBallNearRandomTeam();
		}
	}
	else
	{
		RespawnBallNearTeam(g_BallSpawnTeam);
	}
}

public void BALL_OnGoal(int team, int scorer)
{
	g_BallSpawnTeam = GetConVarBool(BallSpawnCenterConVar) ? CS_TEAM_NONE : 
	(team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
	DestroyBall();
}

void RecreateBall()
{
	DestroyBall();
	CreateBall();
	SetBallTeam(g_BallTeam);
}

void CreateBall()
{
	g_Ball = CreateEntityByName("hegrenade_projectile");
	DispatchKeyValue(g_Ball, "targetname", SJ_BALL_ENTITY_NAME);
	DispatchSpawn(g_Ball);
	SetEntityModelById(g_Ball, BallModelId);
	g_BallRadius = GetEntityRadius(g_Ball);
	SetEntityRenderMode(g_Ball, RENDER_TRANSCOLOR);
	
	SetEntProp(g_Ball, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
	
	FireOnBallCreated(g_Ball);
}

void DestroyBall()
{
	AcceptEntityInput(g_Ball, "Kill");
}

void ClearBallSpawnPoint()
{
	IsSpawnExists = false;
}

void SetBallSpawnPoint(const float spawnPoint[3])
{
	g_BallSpawnOrigin = spawnPoint;
	IsSpawnExists = true;
}

void GetBallSpawnOrigin(float buffer[3])
{
	buffer = g_BallSpawnOrigin;
}


void GetBallOrigin(float dest[3])
{
	Entity_GetAbsOrigin(g_Ball, dest);
}

public bool BallTraceFilter(int entity, int mask, int client)
{
	return (entity < 1 || entity > MaxClients)
	 && entity != g_Ball;
}

float GetBallSpeed()
{
	float ballVelocity[3];
	GetEntPropVector(g_Ball, Prop_Data, "m_vecVelocity", ballVelocity);
	float tempValue = 0.0;
	for (int i = 0; i < 3; i++)
	{
		tempValue += Pow(ballVelocity[i], 2.0);
	}
	return SquareRoot(tempValue);
}

void RespawnBallWithNotify()
{
	Ball_RespawnAtCenter();
	PlaySoundByIdToAll(BallRespawnedSoundId);
	PrintSJMessageAll("%t", "BALL_RESPAWNED");
}

void Ball_RespawnAtCenter()
{
	ClearBall();
	SetEntityMoveType(g_Ball, MOVETYPE_FLYGRAVITY);
	TeleportEntity(g_Ball, g_BallSpawnOrigin, NULL_VECTOR, g_StartBallVelocity);
	FireOnBallSpawned(g_Ball, CS_TEAM_NONE);
}

void RespawnBallNearRandomTeam()
{
	int randomTeam = GetRandomInt(CS_TEAM_T, CS_TEAM_CT);
	RespawnBallNearTeam(randomTeam);
}

void RespawnBallNearTeam(int team)
{
	float spawnOrigin[3]
	GetRandomTeamSpawnOrigin(team, spawnOrigin)
	spawnOrigin[2] += 64
	ClearBall()
	SetEntityMoveType(g_Ball, MOVETYPE_FLYGRAVITY)
	TeleportEntity(g_Ball, spawnOrigin, NULL_VECTOR, g_StartBallVelocity)
	FireOnBallSpawned(g_Ball, team)
}

void RemoveBallHolder()
{
	g_BallHolder = 0;
	SetBallFree();
}

void ClearBall()
{
	RecreateBall()
	SetBallTeam(CS_TEAM_NONE)
	RemoveBallHolder()
	SetBallOwner(0)
	SetBallFree()
}

void SetBallTeam(int team)
{
	g_BallTeam = team;
	SetBallTeamColor(team);
}

void SetBallTeamColor(int team)
{
	SetEntityRenderColor(g_Ball, g_TeamColors[team][0], g_TeamColors[team][1], g_TeamColors[team][2], g_TeamColors[team][3]);
}

void SetBallOwner(int client)
{
	g_BallOwner = client;
}

void SetBallFree()
{
	g_IsBallFree = true;
	//	SetEntitySolidForClients(g_Ball);
}

void SetBallNotFree()
{
	g_IsBallFree = false;
	//	SetEntityNotSolidForClients(g_Ball);
}

void SetBallCatchEffect()
{
	float orig[3];
	Entity_GetAbsOrigin(g_Ball, orig);
	float dir[3];
	TE_SetupSparks(orig, dir, 20, 20);
	TE_SendToAll();
	PlaySoundByIdFromEntity(FastBallPickUpSoundId, g_Ball);
}

void SetBallSmackEffect()
{
	float orig[3];
	Entity_GetAbsOrigin(g_Ball, orig);
	float dir[3];
	TE_SetupExplosion(orig, g_MiniExplosionSprite, 5.0, 1, 0, 50, 40, dir);
	TE_SendToAll();
}

void TeleportBallToClient(int client)
{
	float clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);
	TeleportEntity(g_Ball, clientOrigin, NULL_VECTOR, g_StartBallVelocity);
}

void GetRandomTeamSpawnOrigin(int team, float destOrigin[3])
{
	int spawnPoints[64];
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

public Action CMD_RespawnBall(int client, int argc)
{
	RespawnBallWithNotify()
	return Plugin_Handled
}

void FireOnBallSpawned(int ballEntity, int ballTeam)
{
	Call_StartForward(OnBallSpawnedForward)
	Call_PushCell(ballEntity)
	Call_PushCell(ballTeam)
	Call_Finish()
}

void FireOnBallCreated(int ballEntity)
{
	Call_StartForward(OnBallCreatedForward)
	Call_PushCell(ballEntity)
	Call_Finish()
} 