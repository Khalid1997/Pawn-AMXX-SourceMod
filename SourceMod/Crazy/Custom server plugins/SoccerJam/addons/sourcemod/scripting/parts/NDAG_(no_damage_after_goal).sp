public void NDAG_Event_PlayerActivate(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	SDKHook(client, SDKHook_OnTakeDamage, NDAG_OnTakeDamage)
}

public Action NDAG_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (g_Goal)
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}