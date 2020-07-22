public void MVP_OnGoal(int team, int scorer)
{
	IncreaseMvpCount(scorer);
}

void IncreaseMvpCount(int client)
{
	int oldMvpCount = CS_GetMVPCount(client);
	CS_SetMVPCount(client, oldMvpCount + 1);
}