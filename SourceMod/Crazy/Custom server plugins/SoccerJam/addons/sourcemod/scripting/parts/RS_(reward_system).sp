ConVar CreditCostConVar
ConVar RewardsEnabledConVar
ConVar InterceptionRewardConVar
ConVar GoalRewardConVar
ConVar GoalTeamRewardConVar
ConVar AssistingRewardConVar
ConVar LevelCostMultConVar
ConVar LevelCostAddConVar
ConVar CreditsPerLevelConVar

StringMap LevelCostCacheTrie

int PlayerCash[MAXPLAYERS+1]
int PlayerTotalCash[MAXPLAYERS+1]
int PlayerLevel[MAXPLAYERS+1]

int LevelUpSoundId


public void RS_Init()
{
	RewardsEnabledConVar = CreateConVar("sj_rewards_enabled", "0", "Enable rewards", 0, true, 0.0, true, 1.0)

	CreditsPerLevelConVar = CreateConVar("sj_credits_per_level_addition", "1", "Credits for level", 0, true, 0.0)

	CreditCostConVar = CreateConVar("sj_first_level_cost", "500", "Level 1 cost", 0, true, 1.0)
	LevelCostMultConVar = CreateConVar("sj_level_cost_multiplier", "1.2", "Level cost multiplier", 0, true, 1.0)
	LevelCostAddConVar = CreateConVar("sj_level_cost_addition", "0", "Level cost addition", 0, true, 0.0)
	
	InterceptionRewardConVar = CreateConVar("sj_interception_reward", "50", "Reward for ball interception", 0, true, 0.0)
	GoalTeamRewardConVar = CreateConVar("sj_goal_team_reward", "100", "Reward ALL players in team for goal scoring", 0, true, 0.0)
	GoalRewardConVar = CreateConVar("sj_goal_reward", "300", "Reward goal scoring", 0, true, 0.0)
	AssistingRewardConVar = CreateConVar("sj_assisting_reward", "200", "Reward assisting", 0, true, 0.0)

	LevelCostCacheTrie = CreateTrie()

	LevelUpSoundId = CreateSound("level_up")
}

public void RS_OnStartPublic()
{
	if (!GetConVarBool(RewardsEnabledConVar))
	{
		return;
	}
	ForEachClient(ResetPlayerCash)
}

public void RS_OnGetUpgradeInfo(int client, char info[512])
{
	if (!GetConVarBool(RewardsEnabledConVar))
	{
		return;
	}
	Format(info, sizeof(info), "%s\nLevel: %i\nNext level: $%i\n\n", info, PlayerLevel[client], GetNextLevelCost(client))
}

public void RS_OnBallReceived(int ballHolder, int oldBallOwner)
{
	if (!GetConVarBool(RewardsEnabledConVar))
	{
		return
	}
	int team = GetClientTeam(ballHolder)
	if (oldBallOwner > 0
		&& team != GetClientTeam(oldBallOwner))
	{
		int credits =  GetConVarInt(InterceptionRewardConVar)
		PrintSJMessage(ballHolder, "You have gained %i for %s", credits, "Interception")
		AddPlayerCash(ballHolder, credits)
	}
}

public void RS_OnGoal(int team, int scorer)
{
	if (!GetConVarBool(RewardsEnabledConVar))
	{
		return;
	}
	int credits
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			credits =  GetConVarInt(GoalTeamRewardConVar)
			PrintSJMessage(client, "You have gained %i for %s", credits, "Team Goal")
			AddPlayerCash(scorer, credits)
		}
	}
	credits = GetConVarInt(GoalRewardConVar)
	PrintSJMessage(scorer, "You have gained %i for %s", credits, "Goal scoring")
	AddPlayerCash(scorer, credits)
}

public void RS_OnClientAssisted(int client)
{
	if (!GetConVarBool(RewardsEnabledConVar))
	{
		return
	}
	int credits =  GetConVarInt(AssistingRewardConVar)
	PrintSJMessage(client, "You have gained %i for %s", credits, "Goal Assisting")
	AddPlayerCash(client, credits)
}

public void RS_OnClientResetUpgrades(int client)
{
	if (!GetConVarBool(RewardsEnabledConVar))
	{
		return
	}
	AddPlayerCredits(client, GetConVarInt(CreditsPerLevelConVar) * PlayerLevel[client])
}

void AddPlayerCash(int client, int value)
{	
	if (!GetConVarBool(RewardsEnabledConVar))
	{
		return
	}
	int creditCost = GetNextLevelCost(client)

	PlayerTotalCash[client] += value
	
	PlayerCash[client] += value
	if (PlayerCash[client] >= creditCost)
	{
		PlayerCash[client] -= creditCost
		AddPlayerCredits(client, GetConVarInt(CreditsPerLevelConVar))
		PlayerLevel[client]++
		PlaySoundByIdToClient(client, LevelUpSoundId)
		PrintSJMessage(client, "You have reached level %i and got %i credits. Next level cost: $%i", PlayerLevel[client], GetConVarInt(CreditsPerLevelConVar), GetNextLevelCost(client))
		AddPlayerCash(client, 0)
	}
	UpdateClientVisibleCash(client)
}

int GetNextLevelCost(int client)
{
	int playerLevel = PlayerLevel[client]
	return GetLevelCost(playerLevel + 1)
}

int GetLevelCost(int level)
{
	char levelNumberString[8]
	IntToString(level, levelNumberString, sizeof(levelNumberString))
	
	int cost
	if (GetTrieValue(LevelCostCacheTrie, levelNumberString, cost))
	{
		return cost
	}

	cost = CalculateLevelCost(level)
	SetTrieValue(LevelCostCacheTrie, levelNumberString, cost)

	return cost
}

int CalculateLevelCost(int level)
{
	int initialCost = GetConVarInt(CreditCostConVar)
	float creditCost = float(initialCost)
	
	if (level == 0)
	{
		return RoundFloat(creditCost)
	}
	
	int costAddition = GetConVarInt(LevelCostAddConVar)
	float costMultiplier = GetConVarFloat(LevelCostMultConVar)
	
	
	for (int i = 0; i < level - 1; i++)
	{
		creditCost = (creditCost * costMultiplier) + costAddition
	}

	return RoundFloat(creditCost)
}

public void ResetPlayerCash(int client)
{
	ClearClientUpgrades(client)
	PlayerTotalCash[client] = 0
	PlayerCash[client] = 0
	PlayerLevel[client] = 0

	UpdateClientVisibleCash(client)
}

void UpdateClientVisibleCash(int client)
{
	if (IsClientInGame(client))
	{
		int accountOffset = FindSendPropInfo("CCSPlayer", "m_iAccount")
		SetEntData(client, accountOffset, PlayerCash[client])
	}
}