int MatchStats1Id
int MatchStats2Id
int MatchStats3Id
int MatchStats4Id
int MatchStats5Id


public void TEST_Init()
{
	MatchStats1Id = CreateMatchStats("stats1")
	MatchStats2Id = CreateMatchStats("stats2")
	MatchStats3Id = CreateMatchStats("stats3")
	MatchStats4Id = CreateMatchStats("stats4")
	MatchStats5Id = CreateMatchStats("stats5")
	RegAdminCmd("sm_t", TEST_Cmd_Test, ADMFLAG_ROOT)
	RegAdminCmd("sm_t2", TEST_Cmd_Test2, ADMFLAG_ROOT)

	HookEvent("grenade_bounce", Bounced)
}

public Action Bounced(Handle event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("bounce")
	return Plugin_Continue
}

public Action TEST_Cmd_Test(int client, int args)
{
	ReplyToCommand(client, "test1")
	//ShowMatchStats(client)
	//ShowAssistants(client)
	TeleportEntity(g_Ball, NULL_VECTOR, NULL_VECTOR, g_StartBallVelocity)
	return Plugin_Handled
}

public Action TEST_Cmd_Test2(int client, int args)
{
	ReplyToCommand(client, "test2")
	AddMatchStatsValue(MatchStats1Id, client, 100)
	AddMatchStatsValue(MatchStats2Id, client, 200)
	AddMatchStatsValue(MatchStats3Id, client, 300)
	AddMatchStatsValue(MatchStats4Id, client, 400)
	AddMatchStatsValue(MatchStats5Id, client, 500)
	return Plugin_Handled
}