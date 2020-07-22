int CtModelId
int TModelId

public void TM_Init()
{
	TModelId = CreateModel("team_red")
	CtModelId = CreateModel("team_blue")
}

public void TM_Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int team = GetClientTeam(client)
	if (team == CS_TEAM_CT)
	{
		SetEntityModelById(client, CtModelId)
	}
	else if (team == CS_TEAM_T)
	{
		SetEntityModelById(client, TModelId)
	}
}