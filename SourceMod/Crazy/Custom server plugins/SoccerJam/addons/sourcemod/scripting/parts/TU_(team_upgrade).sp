ConVar GoalCreditsAdditionGoalConVar

int AdditionCreditsCount

public void TU_Init()
{
	GoalCreditsAdditionGoalConVar = CreateConVar("sj_goal_credits_addition", "0", "Number of credits that get all players at the goal", 0, true, 0.0)
}

public void TU_OnGoal(int team, int scorer)
{
	int  creditsForGoal = GetConVarInt(GoalCreditsAdditionGoalConVar)
	for (int i = 1; i <= MaxClients; i++)
	{
		AddPlayerCredits(i, creditsForGoal)
	}
	AdditionCreditsCount += creditsForGoal
}

public void TU_Event_PrePlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	ClearClientUpgrades(client)
	AddPlayerCredits(client, AdditionCreditsCount)
}

public void TU_OnStartPublic()
{
	AdditionCreditsCount = 0
}

public void TU_OnStartMatch()
{
	AdditionCreditsCount = 0
}

public void TU_OnClientResetUpgrades(int client)
{
	AddPlayerCredits(client, AdditionCreditsCount)
}