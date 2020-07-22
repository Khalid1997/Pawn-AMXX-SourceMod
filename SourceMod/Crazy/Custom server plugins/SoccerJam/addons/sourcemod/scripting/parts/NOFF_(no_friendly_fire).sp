public void NOFF_Event_PlayerActivate(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	SDKHook(client, SDKHook_OnTakeDamage, NOFF_OnTakeDamage)
}

public Action NOFF_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (victim == attacker || attacker == 0)
	{
		return Plugin_Continue
	}
	if (GetClientTeam(victim) == GetClientTeam(attacker))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue
}