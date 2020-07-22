const int MAX_MATCH_STATS = 16
const int STATS_NAME_LENGTH = 64

int StatsCount
int PlayerStats[MAXPLAYERS+1][MAX_MATCH_STATS]

char StatsNames[MAX_MATCH_STATS][STATS_NAME_LENGTH]

public void MSM_OnStartPublic()
{
	ResetAllClientsMatchStats()
}

public void MSM_OnStartMatch()
{
	ResetAllClientsMatchStats()
}

public void MSM_OnClientDisconnect(int client)
{
	ResetClientMatchStats(client)
}

public void MSM_OnEndPublic()
{
	ShowMatchStatsToAll()
}

public void MSM_OnEndMatch()
{
	ShowMatchStatsToAll()
}

int CreateMatchStats(const char[] name)
{
	strcopy(StatsNames[StatsCount], STATS_NAME_LENGTH, name)
	return StatsCount++
}

void AddMatchStatsValue(int statsId, int client, int value)
{
	PlayerStats[client][statsId] += value
}

void SetMatchStatsValue(int statsId, int client, int value)
{
	if (value > PlayerStats[client][statsId])
	{
		PlayerStats[client][statsId] = value
	}
}

void ResetAllClientsMatchStats()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		ResetClientMatchStats(client)
	}
}

void ResetClientMatchStats(int client)
{
	for (int statsId = 0; statsId < StatsCount; statsId++)
	{
		PlayerStats[client][statsId] = 0
	}
}

void ShowMatchStatsToAll()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			ShowMatchStats(client)
		}
	}
}

void ShowMatchStats(int client)
{
	Handle panel = CreatePanel()
	
	int count = 0
	char line[STATS_NAME_LENGTH]
	int statsClient
	int value;
	char clientName[MAX_NAME_LENGTH]
	for (int statsId = 0; statsId < StatsCount; statsId++)
	{
		statsClient = GetClientWithBiggerValue(statsId, value)
		if (statsClient > 0)
		{
			GetClientName(statsClient, clientName, sizeof(clientName))
			Format(line, sizeof(line), "%s: %s (%i)", StatsNames[statsId], clientName, value)
			DrawPanelText(panel, line)
			count++
		}
	}
	if (count > 0)
	{
		SetPanelTitle(panel, "Match Stats:")
		SendPanelToClient(panel, client, StatsPanelHandler, 20)
	}
	CloseHandle(panel)
}

int GetClientWithBiggerValue(int statsId, int &value)
{
	int client = 0
	int maxValue = 0
	for (int i = 1; i < MaxClients; i++)
	{
		if (PlayerStats[i][statsId] > maxValue)
		{
			maxValue = PlayerStats[i][statsId]
			client = i
		}
	}
	value = maxValue
	return client;
}

public int StatsPanelHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
}