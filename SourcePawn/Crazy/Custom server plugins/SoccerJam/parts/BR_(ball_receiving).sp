Handle OnBallReceivedForward;

int BallKickSoundId;
int BallPickUpSoundId;
int BallInterceptionSoundId;

int BallStealsStatsId;

public void BR_Init()
{
	OnBallReceivedForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell);
	RegisterCustomForward(OnBallReceivedForward, "OnBallReceived");
	
	BallKickSoundId = CreateSound("ball_kill");
	BallPickUpSoundId = CreateSound("ball_pickup");
	BallInterceptionSoundId = CreateSound("ball_steal");

	BallStealsStatsId = CreateMatchStats("Most steals");

	AddCommandListener(CMD_JoinTeam, "jointeam");
}

public void BR_OnBallCreated(int ballEntity)
{
	SDKHook(ballEntity, SDKHook_Touch, BR_OnBallTouch);
}

public void BR_OnBallTouch(int ball, int entity)
{
	if (g_IsBallFree 
		&& entity >= 1 
		&& entity <= MaxClients)
	{
		CheckPlayerTouchBall(entity);
	}
}

public void BR_Event_PrePlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))	
	if (client == g_BallHolder)
	{
		RemoveBallHolder();
	}
}

public void BR_OnBallKicked(int client)
{
	RemoveBallHolder();
}

void CheckPlayerTouchBall(int client)
{
	if (IsPlayerAlive(client))
	{
		if (g_BallOwner == 0 || GetClientTeam(client) != GetClientTeam(g_BallOwner))
		{		
			CheckPlayerInterception(client);
		}
		else
		{
			SetBallHolder(client);
		}
	}
}

void CheckPlayerInterception(int client)
{
	float ballSpeed = GetBallSpeed();
	if (IsClientSmacked(client, ballSpeed))
	{
		SmackPlayerOnBallSpeed(client, ballSpeed);
		SetBallSmackEffect();
	}
	else
	{
		SetBallHolder(client);
	}
}

void SmackPlayerOnBallSpeed(int client, float ballSpeed)
{
	float playerDexterity = GetPlayerCatchingPercent(client);
	float damage = ballSpeed / 16.0 - playerDexterity;
	if (damage < 10.0)
	{
		damage = 10.0;
	}
	float ballVelovity[3];
	Entity_GetLocalVelocity(g_Ball, ballVelovity);
	Entity_Hurt(client, RoundFloat(damage), 0, DMG_SHOCK, "sj_ball")
	if(!IsPlayerAlive(client))
	{
		PlaySoundByIdToAll(BallKickSoundId);
	}
	else
	{
		float pushVel[3];
		pushVel[0] = ballVelovity[0];
		pushVel[1] = ballVelovity[1];
		pushVel[2] = ballVelovity[2] + ((ballVelovity[2] < 0) ? GetRandomFloat(-200.0,-50.0) : GetRandomFloat(50.0,200.0))
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, pushVel);
	}
	for (int i = 0; i < 3; i++)
	{
		ballVelovity[i] = ballVelovity[i] * GetRandomFloat(0.1,0.9)
	}
	TeleportEntity(g_Ball, NULL_VECTOR, NULL_VECTOR, ballVelovity)
}

bool IsClientSmacked(int client, float ballSpeed)
{
	if (ballSpeed < BALL_SPEED_FAST)
	{
		return false;
	}
	int buttons = GetClientButtons(client);
	
	float catchChancePercent = ((buttons & IN_USE) ? 10.0 : 0.0) + GetPlayerCatchingPercent(client);
	if (Client_IsInTurboMode(client))
	{
		catchChancePercent += 5.0;
	}	
	if (GetChance(catchChancePercent))
	{
		return false;
	}
	return true;
}

void SetBallHolder(int client)
{
	if (client != g_BallHolder)
	{
		int oldBallOwner = g_BallOwner;
		OnClientReceivedBall(client);
		
		int team = GetClientTeam(client);
		if (team != g_BallTeam)
		{
			if (g_BallTeam != CS_TEAM_NONE)
			{
				OnClientInterceptedBall();
				AddMatchStatsValue(BallStealsStatsId, client, 1);
			}
			SetBallTeam(team);
		}
		g_BallHolder = client;
		
		SetBallOwner(client);
		GetClientName(client, g_BallOwnerName, sizeof(g_BallOwnerName));
		SetBallNotFree();
		FireOnBallReceived(client, oldBallOwner);
	}
}

void OnClientInterceptedBall()
{
	if (GetBallSpeed() > BALL_SPEED_FAST) 
	{
		SetBallCatchEffect();
	}
	
	PlaySoundByIdToAll(BallInterceptionSoundId);
}

void OnClientReceivedBall(int client)
{
	int team = GetClientTeam(client);
	FadeClient(client, 50, g_TeamColors[team]);
	PlaySoundByIdFromEntity(BallPickUpSoundId, client);
}

bool IsBallHolder(int client)
{
	return (g_BallOwner == client) && !g_IsBallFree;
}

void FireOnBallReceived(int ballHolder, int oldBallOwner)
{
	Call_StartForward(OnBallReceivedForward);
	Call_PushCell(ballHolder);
	Call_PushCell(oldBallOwner);
	Call_Finish();
}

public Action CMD_JoinTeam(int client, const char[] command, int argc) 
{	
	if (argc)
	{
		char team[3];
		GetCmdArgString(team, sizeof(team));
		if (GetClientTeam(client) == StringToInt(team))
		{
			return Plugin_Handled;
		}
	}
	if (client == g_BallOwner)
	{
		RespawnBallWithNotify();
	}
	return Plugin_Continue;
}