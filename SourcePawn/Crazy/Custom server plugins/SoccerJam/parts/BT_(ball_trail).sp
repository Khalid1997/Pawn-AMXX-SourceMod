Function CreateBallTrailProc;
int g_BallSpriteTrail;

public void BT_Init()
{
	InitGame();
	MapFunction(CreateBallTrailProc, "CreateBallTrail");
}

public void BT_OnBallSpawned(int ballEntity, int team)
{
	SetEntityRenderColor(g_BallSpriteTrail, g_TeamColors[team][0], g_TeamColors[team][1], g_TeamColors[team][2], g_TeamColors[team][3]);
}

public void BT_OnBallReceived(int ballHolder, int oldBallOwner)
{
	int team = GetClientTeam(ballHolder);
	SetEntityRenderColor(g_BallSpriteTrail, g_TeamColors[team][0], g_TeamColors[team][1], g_TeamColors[team][2], g_TeamColors[team][3]);
}

void InitGame()
{
	GetGameFolderName(GameFolderName, sizeof(GameFolderName));
	Function initGameFunc;
	MapFunction(initGameFunc, "Init");
	I_Call_void_void(initGameFunc);
}

public void BT_OnBallCreated(int ballEntity)
{
	I_Call_void_void(CreateBallTrailProc);
}

void MapFunction(Function func, const char[] functionName)
{
	MapFunctionPrefix(func, GameFolderName, functionName);
}

public void csgo_Init()
{
	CreateTimer(BALL_TRAIL_TIME, Timer_ShowBallTrail, INVALID_HANDLE, TIMER_REPEAT);
}

public void csgo_CreateBallTrail()
{
	ShowBallTrail();
}

public Action Timer_ShowBallTrail(Handle timer)
{
	if (IsValidEntity(g_Ball))
	{
		ShowBallTrail();
	}
}

void ShowBallTrail()
{
	TE_SetupBeamFollow(g_Ball, g_LaserCache, g_LaserCache, BALL_TRAIL_TIME, 13.0, 13.0, 1, g_TeamColors[g_BallTeam]);
	TE_SendToAll();
}

public void cstrike_CreateBallTrail()
{
	g_BallSpriteTrail = CreateEntityByName("env_spritetrail");
	DispatchKeyValue(g_BallSpriteTrail, "spritename", LASER_SPRITE);
	DispatchKeyValue(g_BallSpriteTrail, "startwidth", "25.0");
	DispatchKeyValue(g_BallSpriteTrail, "endwidth", "25.0");
	DispatchKeyValueFloat(g_BallSpriteTrail, "lifetime", BALL_TRAIL_TIME);
	DispatchKeyValue(g_BallSpriteTrail, "renderamt", "255");
	DispatchKeyValue(g_BallSpriteTrail, "rendermode", "5");
	DispatchSpawn(g_BallSpriteTrail);
	
	SetVariantString(SJ_BALL_ENTITY_NAME);
	AcceptEntityInput(g_BallSpriteTrail, "SetParent");
}