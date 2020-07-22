public void RWOS_Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	Client_RemoveAllWeapons(client, "weapon_knife")
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1)
}

public Action RWOS_OnWeaponDrop(int client, int weaponIndex)
{
	PrintToChatAll("drop")
	Entity_Kill(weaponIndex)
	return Plugin_Continue
}