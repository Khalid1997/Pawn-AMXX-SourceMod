#define CURVE_ANGLE 15
#define CURVE_COUNT 6
#define CURVE_TIME 0.2
#define DIRECTIONS 2
#define	ANGLEDIVIDE 6
int g_BallDirection
float g_BallSpinDirection[3]
int g_CurveCount
typedef CurveBallFunc = function void();

float g_flNextCurveTime[MAXPLAYERS + 1];

public void CB_Init()
{
	RegConsoleCmd("sj_curveleft", CMD_CurveLeft)
	RegConsoleCmd("sj_curveright", CMD_CurveRight)
}

public void CB_OnPlayerRunCmd(int client, int &buttons)
{
	bool curveleft[MAXPLAYERS+1]
	bool curveright[MAXPLAYERS+1]

	if (client == g_BallHolder)
	{
		if ((buttons & IN_SPEED) && (buttons & IN_MOVERIGHT))
		{
			if (!curveright[client])
			{
				#if defined CURVE_DELAY
				if(g_flNextCurveTime[client] < GetGameTime())
				#endif
				{
					CurveBallRight(client)
				
					curveright[client] = true
					
					#if defined CURVE_DELAY
					g_flNextCurveTime[client] = GetGameTime() + CURVE_DELAY
					#endif
				}
			}
		}
		else
		{
		   curveright[client] = false;
		}
		if ((buttons & IN_SPEED) && (buttons & IN_MOVELEFT))
		{
			if (!curveleft[client])
			{	
				#if defined CURVE_DELAY
				if(g_flNextCurveTime[client] < GetGameTime())
				#endif
				{
					CurveBallLeft(client)
					curveleft[client] = true
					
					#if defined CURVE_DELAY
					g_flNextCurveTime[client] = GetGameTime() + CURVE_DELAY
					#endif
				}		
			}
		}
		else
		{
		   curveleft[client] = false;
		}
	}

	if (buttons & IN_SPEED)
	{
		buttons &= ~IN_SPEED
	}
}

public void CB_OnBallReceived(int ballHolder, int oldBallOwner)
{
	g_BallDirection = 0
}

public void CB_OnBallKicked(int client)
{
	if (g_BallDirection)
	{
		float clientEyeAngles[3]
		GetAngleVectors(clientEyeAngles, g_BallSpinDirection, NULL_VECTOR, NULL_VECTOR);
		g_CurveCount = CURVE_COUNT;
	}
	CreateTimer(CURVE_TIME * 2, Timer_CurveBall)
}

public Action Timer_CurveBall(Handle timer) 
{
	if(g_BallDirection
		&& g_CurveCount > 0) 
	{
		float dAmt = float((g_BallDirection * CURVE_ANGLE) / ANGLEDIVIDE);
		float v[3];
		float v_forward[3];
		Entity_GetLocalVelocity(g_Ball, v);
		GetVectorAngles(v, g_BallSpinDirection);

		g_BallSpinDirection[1] = g_BallSpinDirection[1] + dAmt;
		g_BallSpinDirection[2] = 0.0;
		
		GetAngleVectors(g_BallSpinDirection, v_forward, NULL_VECTOR, NULL_VECTOR);
		
		float speed = GetVectorLength(v);
		v[0] = v_forward[0] * speed;
		v[1] = v_forward[1] * speed;
		
		TeleportEntity(g_Ball, NULL_VECTOR, NULL_VECTOR, v);

		g_CurveCount--;
		CreateTimer(CURVE_TIME, Timer_CurveBall);		
	}
	return Plugin_Continue;
}

public Action CMD_CurveLeft(int client, int argc)
{
	CurveBallLeft(client)
	return Plugin_Handled
}

public Action CMD_CurveRight(int client, int argc)
{
	CurveBallRight(client)
	return Plugin_Handled
}

void CurveBallLeft(int client)
{
	CurveBall(client, CurveBallLeftFunc);
}

void CurveBallRight(int client)
{
	CurveBall(client, CurveBallRigthFunc);
}

void CurveBall(int client, CurveBallFunc curveFunc)
{
	CallCurveFunc(curveFunc)
	SendCurveString(client)
}

void CallCurveFunc(CurveBallFunc curveFunc)
{
	Call_StartFunction(INVALID_HANDLE, curveFunc);
	Call_Finish();
}

public void CurveBallLeftFunc()
{
	g_BallDirection++;
	if (g_BallDirection > DIRECTIONS)
	{
		g_BallDirection = DIRECTIONS;
	}
}

public void CurveBallRigthFunc()
{
	g_BallDirection--;
	if (g_BallDirection < -(DIRECTIONS))
	{
		g_BallDirection = -(DIRECTIONS);
	}
}

void SendCurveString(int client)
{
	char curveString[8];
	GetBallCurveString(curveString, sizeof(curveString));
	PrintCenterText(client, curveString);
}

int GetBallCurveString(char[] string, int length)
{
	switch (g_BallDirection)
	{
		case -2:
		{
			return strcopy(string, length, "----O\n");
		}
		case -1:
		{
			return strcopy(string, length, "---O-\n");
		}
		case 0:
		{
			return strcopy(string, length, "--O--\n");
		}
		case 1:
		{
			return strcopy(string, length, "-O---\n");
		}
		case 2:
		{
			return strcopy(string, length, "O----\n");
		}
	}
	return 0;
}