public void Client_Respawn(int client)
{
	CS_RespawnPlayer(client);
}

public void Client_KillForPreparing(int client)
{
	Client_Kill(client)
	PrintSJMessage(client, "Print 'ready' when you're ready")
}

public void Client_Kill(int client)
{
	ForcePlayerSuicide(client)
}

void ClearAllClients()
{
	ForEachClient(ClearClient);
}

public void ClearClient(int client)
{
	ClearClientUpgrades(client)	
	if (IsClientInGame(client))
	{
		Client_SetScore(client, 0)
		Client_SetDeaths(client, 0)
	}
}