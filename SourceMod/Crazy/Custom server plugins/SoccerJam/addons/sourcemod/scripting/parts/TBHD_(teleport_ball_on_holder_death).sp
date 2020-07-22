PrivateForward OnBallHolderDeathForward

public void TBHD_Init()
{
	OnBallHolderDeathForward = CreateForward(ET_Ignore, Param_Cell)
	RegisterCustomForward(OnBallHolderDeathForward, "OnBallHolderDeath")
}

public void TBHD_Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))

	if (client == g_BallOwner)
	{
		RecreateBall()
		TeleportBallToClient(client)
		FireOnBallHolderDeath(client)
	}
}

void FireOnBallHolderDeath(int client)
{
	Call_StartForward(OnBallHolderDeathForward)
	Call_PushCell(client)
	Call_Finish()
}