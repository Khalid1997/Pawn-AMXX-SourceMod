Handle OnBallKickedForward;
int KickStrengthUpgradeId;
int KickSoundId;

Handle KickDistanceConVar;

public void BK_Init()
{
	OnBallKickedForward = CreateForward(ET_Ignore, Param_Cell);
	RegisterCustomForward(OnBallKickedForward, "OnBallKicked");
	
	KickStrengthUpgradeId = CreateUpgrade("strength", 650.0, 1000.0, 5, 1);
	KickSoundId = CreateSound("ball_kick");
	
	KickDistanceConVar = CreateConVar("sj_kick_distance", "55", "Distance between the player and the ball in kick", 0, true, 1.0);
}

public void BK_OnPlayerRunCmd(int client, int &buttons)
{
	if (client == g_BallHolder)
	{
		if (buttons & IN_USE)
		{
			KickBall(client);
		}
		else
		{
			SetBallInFront(client);
		}
	}
}

void KickBall(int client)
{
	float kickDistance = GetConVarFloat(KickDistanceConVar);
	if (IsInterferenceForKick(client, kickDistance))
	{
		return;
	}
	float clientEyeAngles[3];
	GetClientEyeAngles(client, clientEyeAngles);
	
	float angleVectors[3];
	GetAngleVectors(clientEyeAngles, angleVectors, NULL_VECTOR, NULL_VECTOR);
	
	float kickStrength = GetPlayerUpgradeValue(client, KickStrengthUpgradeId)
	float ballVelocity[3];
	for (int i = 0; i < 3; i++)
	{
		ballVelocity[i] = angleVectors[i] * kickStrength;
	}
	
	
	float frontOrigin[3];
	GetClientFrontBallOrigin(client, kickDistance, BALL_HOLD_HEIGHT + BALL_KICK_HEIGHT_ADDITION, frontOrigin);
	float kickOrigin[3];
	kickOrigin[0] = frontOrigin[0];
	kickOrigin[1] = frontOrigin[1];
	kickOrigin[2] = frontOrigin[2] + BALL_KICK_HEIGHT_ADDITION;
	
	RecreateBall();
	
	TeleportEntity(g_Ball, kickOrigin, NULL_VECTOR, ballVelocity);
	for (int i = 0; i < 3; i++)
	{
		g_BallDistOrigin[0][i] = frontOrigin[i];
	}
	PlaySoundByIdFromEntity(KickSoundId, client);
	FireOnBallKicked(client);
}

bool IsInterferenceForKick(int client, float kickDistance)
{
	float clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);
	float clientEyeAngles[3];
	GetClientEyeAngles(client, clientEyeAngles);
	
	float cos = Cosine(DegToRad(clientEyeAngles[1]));
	float sin = Sine(DegToRad(clientEyeAngles[1]));
	
	float leftBottomOrigin[3];
	leftBottomOrigin[0] = clientOrigin[0] - sin * g_BallRadius;
	leftBottomOrigin[1] = clientOrigin[1] - cos * g_BallRadius;
	leftBottomOrigin[2] = clientOrigin[2] + BALL_HOLD_HEIGHT + BALL_KICK_HEIGHT_ADDITION - g_BallRadius;
	
	float startOriginAddtitions[3];
	startOriginAddtitions[0] = sin * g_BallRadius;
	startOriginAddtitions[1] = cos * g_BallRadius;
	startOriginAddtitions[2] = g_BallRadius
	
	float testOriginAdditions[3];
	testOriginAdditions[0] = cos * (kickDistance + g_BallRadius);
	testOriginAdditions[1] = sin * (kickDistance + g_BallRadius);
	testOriginAdditions[2] = 0.0;
	
	float startOrigin[3];
	float testOrigin[3];
	for (int x = 0, y, z, j; x < 3; x++)
	{
		for (y = 0; y < 3; y++)
		{
			for (z = 0; z < 3; z++)
			{
				startOrigin[0] = leftBottomOrigin[0] + x * startOriginAddtitions[0];
				startOrigin[1] = leftBottomOrigin[1] + y * startOriginAddtitions[1];
				startOrigin[2] = leftBottomOrigin[2] + z * startOriginAddtitions[2];
				for (j = 0; j < 3; j++)
				{
					testOrigin[j] = startOrigin[j] + testOriginAdditions[j];
				}
				TR_TraceRayFilter(startOrigin, testOrigin, MASK_SOLID, RayType_EndPoint, BallTraceFilter, client);
				if (TR_DidHit())
				{
					return true;
				}
			}
		}
	}
	return false;
}

void SetBallInFront(int client)
{
	float origin[3];
	GetClientFrontBallOrigin(client, DISTANCE_BETWEEN_PLAYER_AND_BALL, BALL_HOLD_HEIGHT, origin);
	TeleportEntity(g_Ball, origin, NULL_VECTOR, g_StartBallVelocity);
}

void GetClientFrontBallOrigin(int client, float distance, int height, float destOrigin[3])
{
	float clientOrigin[3]
	GetClientAbsOrigin(client, clientOrigin)
	float clientEyeAngles[3]
	GetClientEyeAngles(client, clientEyeAngles)
	
	float cos = Cosine(DegToRad(clientEyeAngles[1]))
	float sin = Sine(DegToRad(clientEyeAngles[1]))
	
	destOrigin[0] = clientOrigin[0] + cos * distance
	destOrigin[1] = clientOrigin[1] + sin * distance
	destOrigin[2] = clientOrigin[2] + height
}

void FireOnBallKicked(int client)
{
	Call_StartForward(OnBallKickedForward)
	Call_PushCell(client)
	Call_Finish()
} 