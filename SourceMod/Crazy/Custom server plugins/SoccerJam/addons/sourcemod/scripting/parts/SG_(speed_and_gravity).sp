ConVar BHSpeedMultiplierConVar
int SpeedUpgradeId
float BallHolderSpeedMultiplier

public void SG_Init()
{
	SpeedUpgradeId = CreateUpgrade("speed", 100.0, 150.0, 5, 1, "%", UpdatePlayerSpeed)
	CreateUpgrade("gravity", 100.0, 50.0, 5, 1, "%", UpdatePlayerGravity)

	BHSpeedMultiplierConVar = CreateConVar("sj_ball_holder_speed_multiplier", "0.9", "Ball holder speed multiplier", 0, true, 0.0, true, 1.0)
	HookConVarChange(BHSpeedMultiplierConVar, OnCVBHSpeedMultiplierChanged)
	BallHolderSpeedMultiplier = GetConVarFloat(BHSpeedMultiplierConVar)
}

public void SG_Event_PlayerActivate(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	SDKHook(client, SDKHook_PreThink, SG_OnClientThink)
}

public void SG_OnClientThink(int client)
{
	Client_FixSpeed(client)
}

void Client_FixSpeed(int client)
{
	if (IsClientInGame(client))
	{
		float speedMultiplier = g_PlayerSpeedMultiplier[client] * (IsBallHolder(client) ? BallHolderSpeedMultiplier : 1.0)
		float gravityMultiplier = (1.0 / speedMultiplier) * g_PlayerGravityMultiplier[client]
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speedMultiplier)
		SetEntPropFloat(client, Prop_Data, "m_flGravity", gravityMultiplier)		
	}
}

float GetPlayerSpeedMultiplier(int client)
{
	return GetPlayerUpgradeValue(client, SpeedUpgradeId) * 0.01
}

public void UpdatePlayerSpeed(int client, float speedPct)
{
	g_PlayerSpeedMultiplier[client] = speedPct * 0.01
}

public void UpdatePlayerGravity(int client, float gravityPct)
{
	g_PlayerGravityMultiplier[client] = gravityPct * 0.01
}

public void OnCVBHSpeedMultiplierChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	BallHolderSpeedMultiplier = GetConVarFloat(cvar);
}