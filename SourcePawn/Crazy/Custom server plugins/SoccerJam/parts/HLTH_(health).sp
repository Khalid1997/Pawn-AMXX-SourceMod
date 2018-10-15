int HealthUpgradeId

public HLTH_Init()
{
	HealthUpgradeId = CreateUpgrade("health", 70.0, 200.0, 5, 1, "hp", UpdatePlayerHealth)
}

public void HLTH_Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int team = GetClientTeam(client)
	if (team != CS_TEAM_NONE)
	{
		UpdateClientHealth(client)
	}
}

public void UpdatePlayerHealth(int client, float health)
{
	if (client > 0 && IsClientInGame(client))
	{
		UpdateClientHealth(client)
	}
}

static void UpdateClientHealth(int client)
{
	int health = GetPlayerMaxHealth(client);
	SetEntProp(client, Prop_Data, "m_iHealth", health)
}

static void GetPlayerMaxHealth(int client)
{
	float ugradeMaxHealthValue = GetPlayerUpgradeValue(client, HealthUpgradeId)
	return RoundFloat(ugradeMaxHealthValue)
}