//functag public ClientFunc(client);

typeset ClientFunc
{
   function void(int client);
   function void(int client, int value);
};

void ForEachClient(Function func, int value = 0)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		Call_StartFunction(INVALID_HANDLE, func)
		Call_PushCell(client)
		Call_PushCell(value)
		Call_Finish()
	}
}

void ForEachPlayer(Function func)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client)
			&& (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT))
		{
			Call_StartFunction(INVALID_HANDLE, func);
			Call_PushCell(client);
			Call_Finish();
		}
	}
}