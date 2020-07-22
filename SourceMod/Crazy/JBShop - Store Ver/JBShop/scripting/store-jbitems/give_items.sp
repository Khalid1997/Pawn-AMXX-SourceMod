/* *************************************************
				Give Items Functions
   ************************************************* */

// /////////////////////////////////////////
// Invisibility
// /////////////////////////////////////////
Handle g_hTimerInvisibility[MAXPLAYERS] = INVALID_HANDLE;

void Give_Invisibility(int client)
{
	g_bHasItem[client][Item_Invisibility] = true;
	g_bIsItemActivated[client][Item_Invisibility]	= true;
	
	//SetEntityRenderMode(client, RENDER_NONE);
	SDKHook(client, SDKHook_SetTransmit, SDKCallback_SetTransmit);
	
	float flDuration = GetParamCell(Item_Invisibility, g_iClientCurrentItemUpgrade[client][Item_Invisibility], 1);
	g_hTimerInvisibility[client] = CreateTimer(flDuration, Timer_Deactivate_Invisibility, client, TIMER_FLAG_NO_MAPCHANGE);
	
	CPrintToChat(client, "You are now invisible for\x03 %0.2f\x01 seconds", flDuration);
}

void Deactivate_Invisibility(int client, bool bNotInGame = false)
{
	if(g_bHasItem[client][Item_Invisibility])
	{
		SDKUnhook(client, SDKHook_SetTransmit, SDKCallback_SetTransmit);
	}
	
	g_bHasItem[client][Item_Invisibility] = false;
	g_bIsItemActivated[client][Item_Invisibility] = false;
	
	
	if (!bNotInGame)
	{
		//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		//SetEntityRenderColor(client);
		CPrintToChat(client, "You are now\x04 visible!");
	}
	
	if (g_hTimerInvisibility[client] != INVALID_HANDLE)
	{
		delete g_hTimerInvisibility[client];
		g_hTimerInvisibility[client] = INVALID_HANDLE;
	}
}

public Action SDKCallback_SetTransmit(int client, int ent)
{
	// In case it was thirdperson or something
	if(ent == client)
	{
		return Plugin_Continue;
	}
	
	if(g_bHasItem[client][Item_Invisibility])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Timer_Deactivate_Invisibility(Handle hTimer, any client)
{
	// L 07/05/2016 - 11:12:15: [SM] Plugin "store-jbitems.smx" encountered error 23: Native detected error
	// L 07/05/2016 - 11:12:15: [SM] Invalid timer handle 48c0114 (error 3) during timer end, displayed function is timer callback, not the stack trace
	// L 07/05/2016 - 11:12:15: [SM] Unable to call function "Timer_Deactivate_Invisibility" due to above error(s).
	g_hTimerInvisibility[client] = INVALID_HANDLE;
	Deactivate_Invisibility(client, false);
}

// /////////////////////////////////////////
// Immortality
// /////////////////////////////////////////
Handle g_hTimer_Immortal[MAXPLAYERS];
void Give_Immortal(int client)
{
	g_bHasItem[client][Item_Immortal] = true;
	g_bIsItemActivated[client][Item_Immortal] = true;
	
	float flDuration = GetParamCell(Item_Immortal, g_iClientCurrentItemUpgrade[client][Item_Immortal], 1);
	
	g_hTimer_Immortal[client] = CreateTimer(flDuration, Timer_Deactivate_Immortal, client, TIMER_FLAG_NO_MAPCHANGE);
	
	CPrintToChat(client, "You are now\x04 Immortal\x01 for\x05 %0.2f seconds.", flDuration);
}

void Deactivate_Immortal(int client, bool bNotInGame)
{
	g_bHasItem[client][Item_Immortal] = false;
	g_bIsItemActivated[client][Item_Immortal] = false;
	
	if(g_hTimer_Immortal[client] != INVALID_HANDLE)
	{
		delete g_hTimer_Immortal[client];
		g_hTimer_Immortal[client] = INVALID_HANDLE;
	}
	
	if (!bNotInGame)
	{
		CPrintToChat(client, "You are now\x04 mortal (you can take damage).");
	}
}

public Action Timer_Deactivate_Immortal(Handle hTimer, int client)
{
	g_hTimer_Immortal[client] = INVALID_HANDLE;
	Deactivate_Immortal(client, false);
}

// /////////////////////////////////////////
// Open jail doors
// /////////////////////////////////////////
UserMsg g_hFadeUserMsgId;

void Give_OpenJail(int client)
{
	float flOpenJailDuration = GetParamCell(Item_OpenJail, g_iClientCurrentItemUpgrade[client][Item_OpenJail], 1);
	int iBlindDuration = RoundFloat(GetParamCell(Item_OpenJail, g_iClientCurrentItemUpgrade[client][Item_OpenJail], 2));
	
	CPrintToChatAll("Player %N has opened the Jail Doors for %0.2f Seconds!", client, flOpenJailDuration);
	
	SJD_OpenDoors();
	if(flOpenJailDuration > 0.0)
	{
		if(g_hOpenJailTimer != null)
		{
			delete g_hOpenJailTimer;
		}
		
		g_hOpenJailTimer = CreateTimer(flOpenJailDuration, Timer_CloseJail, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}

	if (iBlindDuration > 0)
	{
		CPrintToChatAll("The Guards have been blinded for %d seconds", iBlindDuration);
		BlindCTPlayers(iBlindDuration);
	}
}

public Action Timer_CloseJail(Handle hTimer)
{
	g_hOpenJailTimer = null;
	SJD_CloseDoors();
}

void BlindCTPlayers(int iDuration)
{
	int iCount;
	int iPlayers[MAXPLAYERS];
	
	iCount = GetPlayers(iPlayers, GP_Flag_Alive, GP_Team_Second);
	//iCount = GetPlayers(iPlayers, GP_Flag_Alive);
	
	PerformBlind(iPlayers, iCount, iDuration, 255);
}

void Deactivate_OpenJail(int client, bool bNotInGame)
{
	// Can't deactivate it as it is not a player item.
	if(client || bNotInGame)
	{
		
	}
}

void PerformBlind(int[] targets, int count, int duration, int amount)
{
	int holdtime = duration - 2 > 0 ? (duration - 2) : duration;
	
	duration *= 500;
	holdtime *= 500;
	
	///PrintToServer("Fade: %d %d", duration, holdtime);
	int flags;
	
	#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
	#define FFADE_OUT			0x0002		// Fade out (not in)
	#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
	#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
	#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one
	
	flags = (FFADE_IN | FFADE_PURGE);
	int color[4] =  { 0, 0, 0, 0 };
	color[3] = amount;
	
	Handle message = StartMessageEx(g_hFadeUserMsgId, targets, count);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(duration);
		bf.WriteShort(holdtime);
		bf.WriteShort(flags);
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}
	
	EndMessage();
}

// /////////////////////////////////////////
// Deagle
// /////////////////////////////////////////
void Give_Deagle(int client)
{
	int iTotalDeagleAmmo = GetParamCell(Item_Deagle, g_iClientCurrentItemUpgrade[client][Item_Deagle], 1);
	int iReserve, iClip;
	
	#define DEAGLE_DEFAULT_MAX_CLIP 7
	if (iTotalDeagleAmmo - DEAGLE_DEFAULT_MAX_CLIP > 0)
	{
		iClip = DEAGLE_DEFAULT_MAX_CLIP;
		iReserve = iTotalDeagleAmmo - DEAGLE_DEFAULT_MAX_CLIP;
	}
	
	else
	{
		iClip = iTotalDeagleAmmo;
		iReserve = 0;
	}
	
	StripClientWeapons(client, true);
	GivePlayerWeapon(client, "weapon_deagle", iClip, iReserve);
	
	g_bHasItem[client][Item_Deagle] = true;
	g_bIsItemActivated[client][Item_Deagle] = true;
	
	// Immediately deactivate here
	Deactivate_Deagle(client, false);
}

void Deactivate_Deagle(int client, bool bNotInGame)
{
	if(bNotInGame)
	{
		
	}
	
	g_bHasItem[client][Item_Deagle] = false;
	g_bIsItemActivated[client][Item_Deagle] = false;
}

void StripClientWeapons(int client, bool bDontRemoveKnife)
{
	#define CSGO_MAX_WEAPON_SLOTS 6
	for(int i = 0; i < CSGO_MAX_WEAPON_SLOTS; i++)
	{
		if(bDontRemoveKnife && i == CS_SLOT_KNIFE)
		{
			continue;
		}
		
		StripClientSingleWeapon(client, i);
	}
}

void StripClientSingleWeapon(int client, int iSlot)
{
	int iWeaponEnt = GetPlayerWeaponSlot(client, iSlot);
		
	if(iWeaponEnt != -1)
	{
		RemovePlayerItem(client, iWeaponEnt);
	}
}

void GivePlayerWeapon(client, char[] szWeapon, int iClip, int iReserve)
{
	int iWeapon = GivePlayerItem(client, szWeapon);
	SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iReserve);
	SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClip);
}

// /////////////////////////////////////////
// Lightsaber
// /////////////////////////////////////////
void Give_Lightsaber(int client)
{
	g_bHasItem[client][Item_Lightsaber] = true;
	g_bIsItemActivated[client][Item_Lightsaber] = true;
	
	if(g_bFPVM_Interface && g_bFDownloader)
	{
		FPVMI_AddViewModelToClient(client, "weapon_knife", g_iLightSaberViewModel);
		FPVMI_AddWorldModelToClient(client, "weapon_knife", g_iLightSaberWorldModel);
	}
}

void Deactivate_Lightsaber(int client, bool bNotInGame)
{
	// only if on disconnected
	if (bNotInGame)
	{
		g_bHasItem[client][Item_Lightsaber] = false;
		g_bIsItemActivated[client][Item_Lightsaber] = false;
	}
}

// /////////////////////////////////////////
// Guard Skin
// /////////////////////////////////////////
char IMPOSTER_MODEL_DEFAULT[] = "models/player/ctm_fbi_varianta.mdl";
char g_szOldModel[MAXPLAYERS][PLATFORM_MAX_PATH];
Handle g_hTimer_GuardSkin[MAXPLAYERS] = INVALID_HANDLE;
void Give_GuardSkin(int client)
{
	int iPlayers[MAXPLAYERS];
	int iCount = GetPlayers(iPlayers, GP_Flag_Alive, GP_Team_Second);
	
	if (!iCount)
	{
		CPrintToChat(client, "You were given the default guard skin.");
		SetEntityModel(client, IMPOSTER_MODEL_DEFAULT);
	}
	 
	else
	{
		GetEntityModel(client, g_szOldModel[client], sizeof g_szOldModel[]);
		
		int iRandomCTPlayer = iPlayers[GetRandomInt(0, iCount - 1)];
		char szModel[PLATFORM_MAX_PATH];
		GetEntityModel(iRandomCTPlayer, szModel, sizeof szModel);
		
		SetEntityModel(client, szModel);
		CPrintToChat(client, "You now wear the same skin as guard \x04%N", iRandomCTPlayer);
		
		float flDuration = GetParamCell(Item_GuardSkin, g_iClientCurrentItemUpgrade[client][Item_GuardSkin], 1);
		bool bGiveWeapons = view_as<bool>(GetParamCell(Item_GuardSkin, g_iClientCurrentItemUpgrade[client][Item_GuardSkin], 2));
		
		if (flDuration > 0.0)
		{
			g_hTimer_GuardSkin[client] = CreateTimer(flDuration, Timer_Deactivate_GuardSkin, client);
		}
		
		if (bGiveWeapons)
		{
			StripClientWeapons(client, true);
			GivePlayerWeapon(client, "weapon_deagle", 0, 0);
			GivePlayerWeapon(client, "weapon_m4a1", 0, 0);
		}
		
		g_bHasItem[client][Item_GuardSkin] = true;
	}
}

void GetEntityModel(int client, char[] szModel, int iSize)
{
	GetEntPropString(client, Prop_Data, "m_ModelName", szModel, iSize);
}

public Action Timer_Deactivate_GuardSkin(Handle hTimer, int client)
{
	g_hTimer_GuardSkin[client] = null;
	Deactivate_GuardSkin(client, false);
}

void Deactivate_GuardSkin(int client, bool bNotInGame)
{
	if (g_hTimer_GuardSkin[client] != null)
	{
		delete g_hTimer_GuardSkin[client];
		g_hTimer_GuardSkin[client] = null;
	}
	
	if (!bNotInGame)
	{
		SetEntityModel(client, g_szOldModel[client]);
	}
	
	g_bHasItem[client][Item_GuardSkin] = false;
	g_bIsItemActivated[client][Item_GuardSkin] = false;
}

// /////////////////////////////////////////
// Explosion Bomb
// /////////////////////////////////////////
char g_szBombTickSound[] = "buttons/button17.wav";
char g_szBombExplodeSound[] = "weapons/c4/c4_explode1.wav";

// BombData
enum
{
	BD_DurationTotal, 
	BD_DetonateTime,
	BD_Radius, 
	BD_MaxDamage, 
	BD_LastPlayed, 
	
	BD_Count
};

float g_flBombData[MAXPLAYERS][BD_Count];

#define PERCENTAGE_FAST 0.5 // when 50% of the duration is left to detonate
#define PERCENTAGE_LIGHTSPEED 0.3 // when 30% of the duration is left to detonate

void Give_Bomb(int client)
{
	g_bHasItem[client][Item_Bomb] = true;
	g_bIsItemActivated[client][Item_Bomb] = false;
	
	g_flBombData[client][BD_DurationTotal] = GetParamCell(Item_Bomb, g_iClientCurrentItemUpgrade[client][Item_Bomb], 1);
	g_flBombData[client][BD_Radius] = GetParamCell(Item_Bomb, g_iClientCurrentItemUpgrade[client][Item_Bomb], 2);
	g_flBombData[client][BD_MaxDamage] = GetParamCell(Item_Bomb, g_iClientCurrentItemUpgrade[client][Item_Bomb], 3);
	
	CPrintToChat(client, "You were given the suicide bomb. Press G to activate it!");
}

void Deactivate_Bomb(int client, bool bNotInGame)
{
	if(bNotInGame)
	{
		
	}
	
	if (g_bIsItemActivated[client][Item_Bomb])
	{
		SDKUnhook(client, SDKHook_PostThinkPost, SDKCallback_PostThinkPost);
	}
	
	g_bHasItem[client][Item_Bomb] = false;
	g_bIsItemActivated[client][Item_Bomb] = false;
}

void Activate_Bomb(int client)
{
	g_bIsItemActivated[client][Item_Bomb] = true;
	g_flBombData[client][BD_DetonateTime] = GetGameTime() + g_flBombData[client][BD_DurationTotal];
	
	CPrintToChat(client, "You have activated the bomb.");
	SDKHook(client, SDKHook_PostThinkPost, SDKCallback_PostThinkPost);
}

public void SDKCallback_PostThinkPost(int client)
{
	if (!g_bIsItemActivated[client][Item_Bomb])
	{
		Deactivate_Bomb(client, false);
		return;
	}
	
	float flGameTime = GetGameTime();
	bool bPlaySound = false;
	float flPercentageLeft = (g_flBombData[client][BD_DetonateTime] - flGameTime) / g_flBombData[client][BD_DurationTotal];
	
	if (flPercentageLeft > 0.0)
	{
		#define PERCENTAGE_LIGHTSPEED_INCREMENT 0.3
		if (flPercentageLeft <= PERCENTAGE_LIGHTSPEED)
		{
			if (g_flBombData[client][BD_LastPlayed] + PERCENTAGE_LIGHTSPEED_INCREMENT < flGameTime)
			{
				g_flBombData[client][BD_LastPlayed] = flGameTime;
				bPlaySound = true;
			}
		}
		
		#define PERCENTAGE_FAST_INCREMENT 0.6
		if (flPercentageLeft <= PERCENTAGE_FAST)
		{
			if (g_flBombData[client][BD_LastPlayed] + PERCENTAGE_FAST_INCREMENT < flGameTime)
			{
				g_flBombData[client][BD_LastPlayed] = flGameTime;
				bPlaySound = true;
			}
		}
		
		else
		{
			#define PERCENTAGE_NORMAL_INCREMENT 0.8
			if (g_flBombData[client][BD_LastPlayed] + PERCENTAGE_NORMAL_INCREMENT < flGameTime)
			{
				g_flBombData[client][BD_LastPlayed] = flGameTime;
				bPlaySound = true;
			}
		}
		
		if (bPlaySound)
		{
			EmitSoundToAll(g_szBombTickSound, client);
		}
	}
	
	else
	{
		Detonate_Bomb(client);
	}
}

void Detonate_Bomb(client)
{
	Deactivate_Bomb(client, false);
	
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
	
	static bool bPrecached;
	char szExplodeSound[] = "sounds/weapons/c4/c4_explode1.wav";
	if(!bPrecached)
	{
		bPrecached = true;
		PrecacheSound(szExplodeSound);
	}
	
	float flRadius = g_flBombData[client][BD_Radius];
	float flDamage = g_flBombData[client][BD_MaxDamage];
	float flDistance;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			//PrintToServer("2");
			continue;
		}
		
		if(i == client)
		{
			//PrintToServer("2 %N", i);
			continue;
		}
		
		if(!IsPlayerAlive(i))
		{
			//PrintToServer("3 %N", i);
			continue;
		}
		
		if (GetClientTeam(i) != CS_TEAM_CT)
		{
			//PrintToServer("4 %N", i);
			continue;
		}
		
		if( (flDistance = GetDistance(i, client) ) > flRadius)
		{
			//PrintToServer("1 %0.2f %0.2f", flDistance, flRadius);
			continue;
		}
		
		//PrintToServer("Pass");
		SDKHooks_TakeDamage(i, client, client, (flDistance - 32.0) / flRadius * flDamage, DMG_BURN);
	}
	
	EmitSoundToAll(szExplodeSound, client);
		
	/*
	int iExplosionIndex = CreateEntityByName("env_explosion");
	if (iExplosionIndex != -1)
	{
		int radius = RoundFloat(g_flBombData[client][BD_Radius]);
		int damage = RoundFloat(g_flBombData[client][BD_MaxDamage]);
		
		PrintToServer("Damage %d, Radius %d", damage, radius);
		SetEntProp(iExplosionIndex, Prop_Data, "m_spawnflags", 8192 + 2048 + 4096); //16384);
		SetEntProp(iExplosionIndex, Prop_Data, "m_iMagnitude", damage);
		SetEntProp(iExplosionIndex, Prop_Data, "m_iRadiusOverride", radius);
		
		DispatchSpawn(iExplosionIndex);
		ActivateEntity(iExplosionIndex);
		
		float flExplosionOrigin[3];
		GetClientAbsOrigin(client, flExplosionOrigin);
		
		int clientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
		
		TeleportEntity(iExplosionIndex, flExplosionOrigin, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(iExplosionIndex, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(iExplosionIndex, Prop_Send, "m_iTeamNum", clientTeam);
		
		EmitAmbientSound(g_szBombExplodeSound, NULL_VECTOR, client);
		
		AcceptEntityInput(iExplosionIndex, "Explode");
		AcceptEntityInput(iExplosionIndex, "Kill");
	}*/
}

float GetDistance(int client1, int client2)
{
	float vOrigin1[3], vOrigin2[3];
	GetClientAbsOrigin(client1, vOrigin1);
	GetClientAbsOrigin(client2, vOrigin2);
	
	float flDistance = GetVectorDistance(vOrigin1, vOrigin2, false);
	return flDistance > 0.0 ? flDistance : flDistance * -1.0;
}

// /////////////////////////////////////////
// Speed
// /////////////////////////////////////////
Handle g_hTimer_Speed[MAXPLAYERS];
float g_flSpeedMultiplier[MAXPLAYERS];

void Give_Speed(int client)
{
	g_bHasItem[client][Item_Speed] = true;
	g_bIsItemActivated[client][Item_Speed] = false;
	
	float flDuration = GetParamCell(Item_Speed, g_iClientCurrentItemUpgrade[client][Item_Speed], 1);
	CPrintToChat(client, "Press G to activate your\x04Extra Speed.\x01 It will last for\x06 %0.2f seconds.", flDuration);
}

void Activate_Speed(int client)
{
	g_bIsItemActivated[client][Item_Speed] = true;
	
	float flDuration = GetParamCell(Item_Speed, g_iClientCurrentItemUpgrade[client][Item_Speed], 1);
	g_hTimer_Speed[client] = CreateTimer(flDuration, Timer_Deactivate_Speed, client);
	g_flSpeedMultiplier[client] = GetParamCell(Item_Speed, g_iClientCurrentItemUpgrade[client][Item_Speed], 2);
	
	CPrintToChat(client, "You have activated Extra Speed for\x04 %0.2f seconds.", flDuration);
	
	SetClientMaxSpeed(client, g_flSpeedMultiplier[client]);
	SDKHook(client, SDKHook_WeaponSwitchPost, SDKCallback_WeaponSwitchPost);
}

public void SDKCallback_WeaponSwitchPost(int client, int weapon)
{
	if(g_bIsItemActivated[client][Item_Speed])
	{
		SetClientMaxSpeed(client, g_flSpeedMultiplier[client]);
	}
}

void Deactivate_Speed(int client, bool bNotInGame)
{
	if(g_bIsItemActivated[client][Item_Speed])
	{
		SDKUnhook(client, SDKHook_WeaponSwitchPost, SDKCallback_WeaponSwitchPost);
	}
	
	g_bHasItem[client][Item_Speed] = false;
	g_bIsItemActivated[client][Item_Speed] = false;
	
	if(g_hTimer_Speed[client] != INVALID_HANDLE)
	{
		delete g_hTimer_Speed[client];
		g_hTimer_Speed[client] = INVALID_HANDLE;
	}
	
	if(!bNotInGame)
	{
		CPrintToChat(client, "Your extra speed has been\x05 deactivated.");
		SetClientMaxSpeed(client, 1.0);
	}
}

public Action Timer_Deactivate_Speed(Handle hTimer, int client)
{
	g_hTimer_Speed[client] = INVALID_HANDLE;
	Deactivate_Speed(client, false);
}

void SetClientMaxSpeed(int client, float flMaxSpeedMultiplier)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", flMaxSpeedMultiplier);
}

// /////////////////////////////////////////
// 				AWP
// /////////////////////////////////////////
void Give_AWP(int client)
{
	int iTotalAWPAmmo = GetParamCell(Item_AWP, g_iClientCurrentItemUpgrade[client][Item_AWP], 1);
	int iReserve, iClip;
	
	#define AWP_DEFAULT_MAX_CLIP 10
	if (iTotalAWPAmmo - AWP_DEFAULT_MAX_CLIP > 0)
	{
		iClip = DEAGLE_DEFAULT_MAX_CLIP;
		iReserve = iTotalAWPAmmo - AWP_DEFAULT_MAX_CLIP;
	}
	
	else
	{
		iClip = iTotalAWPAmmo;
		iReserve = 0;
	}
	
	StripClientWeapons(client, true);
	GivePlayerWeapon(client, "weapon_awp", iClip, iReserve);
	
	g_bHasItem[client][Item_AWP] = true;
	g_bIsItemActivated[client][Item_AWP] = true;
	
	// Immediately deactivate here
	Deactivate_Deagle(client, false);
}

void Deactivate_AWP(int client, bool bNotInGame)
{
	if(bNotInGame)
	{
		
	}
	
	g_bHasItem[client][Item_AWP] = false;
	g_bIsItemActivated[client][Item_AWP] = false;
}

// /////////////////////////////////////////
// Credit
// /////////////////////////////////////////
void Give_CreditMultiplier(int client)
{
	g_bHasItem[client][Item_Credit] = true;
	g_bIsItemActivated[client][Item_Credit] = true;
}

void Deactivate_Credit(int client, bool bNotInGame)
{
	if(bNotInGame)
	{
		g_bHasItem[client][Item_Credit] = false;
		g_bIsItemActivated[client][Item_Credit] = false;
	}
}

void DeactivateItem(int client, int iItem, bool bNotInGame = false)
{
	switch (iItem)
	{
		case Item_Invisibility:
		{
			Deactivate_Invisibility(client, bNotInGame);
		}
		
		case Item_Immortal:
		{
			Deactivate_Immortal(client, bNotInGame);
		}
		
		case Item_Deagle:
		{
			Deactivate_Deagle(client, bNotInGame);
		}
		
		case Item_OpenJail:
		{
			Deactivate_OpenJail(client, bNotInGame);
		}
		
		case Item_Lightsaber:
		{
			Deactivate_Lightsaber(client, bNotInGame);
		}
		
		case Item_GuardSkin:
		{
			Deactivate_GuardSkin(client, bNotInGame);
		}
		
		case Item_Bomb:
		{
			Deactivate_Bomb(client, bNotInGame);
		}
		
		case Item_Speed:
		{
			Deactivate_Speed(client, bNotInGame);
		}
		
		case Item_AWP:
		{
			Deactivate_AWP(client, bNotInGame);
		}
		
		case Item_Credit:
		{
			Deactivate_Credit(client, bNotInGame);
		}
	}
}

