// author = "sneaK, shavit", thanks!!!
Handle g_hGetPlayerMaxSpeed = null;		// Used to uncap speed regardless of player weapon.

public void WeapSpeedOnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "dhooks"))
	{
		WeapSpeedDhook();
	}
}

void WeapSpeedDhook()
{
	// Optionally setup a hook on CCSPlayer::GetPlayerMaxSpeed to allow full run speed with all weapons.
	if(g_hGetPlayerMaxSpeed == null) {
		Handle hGameData = LoadGameConfigFile("kztimer.games");

		if (hGameData != null) {
			int iOffset = GameConfGetOffset(hGameData, "GetPlayerMaxSpeed");
			CloseHandle(hGameData);

			if (iOffset != -1) {
				g_hGetPlayerMaxSpeed = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHook_GetMaxPlayerSpeed);
			}
		}
	}
}

public void WeapSpeedOnPluginStart()
{
	if (LibraryExists("dhooks"))
	{
		WeapSpeedDhook();
	}
}
	
public void WeapSpeedOnClientPutInServer(int client)
{
	if (LibraryExists("dhooks"))
	{
		DHookEntity(g_hGetPlayerMaxSpeed, true, client);
	}
}


public MRESReturn DHook_GetMaxPlayerSpeed(int client, Handle hReturn)
{
	if (!IsValidClient(client) && !IsPlayerAlive(client))
	{
		return MRES_Ignored;
	}
	
	DHookSetReturn(hReturn, 250.0);
	
	return MRES_Override;
}