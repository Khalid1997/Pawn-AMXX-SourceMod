public void NFFK_Event_PrePlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!attacker || client == attacker)
	{
		Client_SetScore(client, Client_GetScore(client) + 1)
	}
	else
	{
		Client_SetScore(attacker, Client_GetScore(attacker) - 1)
	}
	Client_SetDeaths(client, Client_GetDeaths(client) - 1)
}