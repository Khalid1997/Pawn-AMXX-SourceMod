const float UNIT_TO_METERS_NIULTIPLIER = 0.01905
float LastShotOrigin[3]
int LongestGoalStatsId

public void GD_Init()
{
	LongestGoalStatsId = CreateMatchStats("Longest goal (m)")
}

public void GD_OnBallKicked(int client)
{
	GetClientAbsOrigin(client, LastShotOrigin)
}

public void GD_OnGoal(int team, int scorer)
{
	float ballOrigin[3]
	GetBallOrigin(ballOrigin)
	float distance = GetVectorDistance(LastShotOrigin, ballOrigin)
	float distanceInMeters = distance * UNIT_TO_METERS_NIULTIPLIER
	SetMatchStatsValue(LongestGoalStatsId, scorer, RoundFloat(distanceInMeters))
}