const int MAX_ASSISTANTS = 2

Handle OnClientAssistedForward

Handle AssistantsArray

int AssistCountStatsId

public void GA_Init()
{
	AssistantsArray = CreateArray()

	AssistCountStatsId = CreateMatchStats("Most assists")

	OnClientAssistedForward  = CreateForward(ET_Ignore, Param_Cell)
	RegisterCustomForward(OnClientAssistedForward, "OnClientAssisted")
}

public void GA_OnBallReceived(int ballHolder, int oldBallOwner)
{
	if (oldBallOwner > 0
		&& oldBallOwner != ballHolder
		&& GetClientTeam(ballHolder) == GetClientTeam(oldBallOwner))
	{
		RemoveClientFromArray(ballHolder)
		RemoveClientFromArray(oldBallOwner)
		PushArrayCell(AssistantsArray, oldBallOwner)
	}
	else
	{
		ClearArray(AssistantsArray)
	}
}

public void GA_Event_PrePlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	RemoveClientFromArray(client)
}

public void GA_OnGoal(int team, int scorer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			ShowAssistants(client)
		}
	}	
}

void RemoveClientFromArray(int client)
{
	int arraySize = GetArraySize(AssistantsArray);
	int currentClient;
	for (new i = arraySize - 1; i >= 0; i--)
	{
		currentClient = GetArrayCell(AssistantsArray, i)
		if (currentClient == client)
		{
			RemoveFromArray(AssistantsArray, i)
		}
	}
}

void ShowAssistants(int client)
{
	int arraySize = GetArraySize(AssistantsArray)
	if (arraySize > 0)
	{
		Handle panel = CreatePanel()
		DrawPanelItem(panel, "", ITEMDRAW_SPACER)
		int currentClient
		int count = 0
		char clientName[MAX_NAME_LENGTH];
		for (int i = arraySize - 1; i >= 0; i--)
		{
			currentClient = GetArrayCell(AssistantsArray, i)
			GetClientName(currentClient, clientName, sizeof(clientName))
			DrawPanelText(panel, clientName)

			AddMatchStatsValue(AssistCountStatsId, currentClient, 1)
			count++
			FireOnClientAssisted(currentClient)
			if (count >= MAX_ASSISTANTS)
			{
				break
			}
		}
		SetPanelTitle(panel, "Assistants:")
		SendPanelToClient(panel, client, StatsPanelHandler, 20)
		CloseHandle(panel)
	}
}

public void ShowAssistantsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	
}

void FireOnClientAssisted(int client)
{
	Call_StartForward(OnClientAssistedForward)
	Call_PushCell(client)
	Call_Finish()
}