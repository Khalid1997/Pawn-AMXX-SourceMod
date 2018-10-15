#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <getplayers>

#undef REQUIRE_PLUGIN
#include <daysapi>
#define REQUIRE_PLUGIN

public Plugin myinfo =  {
	name = "DaysAPI: LaZerZ", 
	author = "Khalid", 
	version = "1.0", 
	url = "", 
	description = ""
}

// Constants
#define TIMER_UPDATE_INTERVAL	0.1

#define WAVE_TIME				15.0	// Wave Duration
#define WAVE_EXTRA_LASERS		4		// Extra lasers each wave
#define WAVE_REST_TIME			7.0		// Time between waves
#define PREPARATION_TIME		15.0		// Preparation Time

#define BEAM_INITIAL_COUNT		( GetPlayers(_, GP_Flag_Alive, GP_Team_First | GP_Team_Second) * 4 )
#define BEAM_DIST_FROM_PLAYER	500.0
#define BEAM_LENGTH				1000.0
#define BEAM_INITIAL_SPEED		350.0		// Units per second
#define BEAM_SPEED_INCREASE		50.0
#define	BEAM_WIDTH				5.0
#define BEAM_DAMAGE				100.0
#define	ReguideTimeDurationFactor	2.0
//#define BEAM_INITIAL_DAMAGE	25.0
//#define WAVE_DAMAGE_INCREASE	20.0

char g_szBeamSprite[] = "materials/sprites/laserbeam.vmt";

char g_szBeamEntity[] = "env_beam";
char g_szPointEntity[] = "hegrenade_projectile";

char g_szBeamTargetName[] = "lbeam";
char g_szPointStartTargetName[] = "lbeam_start";
char g_szPointEndTargetName[] = "lbeam_end";

char g_szIntName[] = "lazerz";

// Variables
bool g_bRunning,
	g_bWaveRunning,
	g_bNextRoundStart;
	
int g_iWaveNumber,
	g_iLaserCount;

float g_flReguideTimeDuration,
	 g_flBeamSpeed,
	 g_flWaveEndTime,
	 g_flWaveStartTime,
	 g_flNextGuideTime;

Handle g_hTimer;

int g_iLastDeaths[3];

#if defined DEBUG
int g_iBeamSprite;
#endif

bool g_bDaysAPI;

public void OnPluginStart()
{
	RegAdminCmd("sm_lazerz", ConCmd_StartLasers, ADMFLAG_ROOT);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd()
{
	DaysAPI_RemoveDay(g_szIntName);
}

public void OnLibraryAdded(const char[] szName)
{
	if (StrEqual(szName, "daysapi"))
	{
		g_bDaysAPI = true;
	}
}

public void OnLibraryRemoved(const char[] szName)
{
	if (StrEqual(szName, "daysapi"))
	{
		g_bDaysAPI = false;
	}
}

public void OnAllPluginsLoaded()
{
	g_bDaysAPI = LibraryExists("daysapi");
	
	if (g_bDaysAPI)
	{
		DaysAPI_AddDay(g_szIntName, LasersDay_Start, LasersDay_End);
		DaysAPI_SetDayInfo(g_szIntName, DayInfo_DisplayName, "LaZerZ");
		DaysAPI_SetDayInfo(g_szIntName, DayInfo_Flags, DayFlag_EndTerminateRound);
	}
}

public void OnMapStart()
{
	#if defined DEBUG
	g_iBeamSprite = PrecacheModel(g_szBeamSprite);
	#else
	PrecacheModel(g_szBeamSprite);
	#endif
	g_hTimer = null;
	
	g_bRunning = false;
	g_bWaveRunning = false;
	g_bNextRoundStart = false;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, SDKCallback_TraceAttack);
}

public void OnClientDisconnect(int client)
{
	if(g_bRunning)
	{
		RemoveEntryFromArray(g_iLastDeaths, sizeof g_iLastDeaths, client);
	}
}

public Action ConCmd_StartLasers(int client, int args)
{
	if (g_bRunning)
	{
		return Plugin_Handled;
	}
	
	if (g_bDaysAPI)
	{
		return Plugin_Handled;
	}
	
	g_bNextRoundStart = true;
	
	ReplyToCommand(client, "* Starting Next Round");
	return Plugin_Handled;
}

public void Event_RoundStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	if (g_bRunning)
	{
		return;
	}
	
	if (g_bNextRoundStart)
	{
		g_bNextRoundStart = false;
		
		if (g_bDaysAPI)
		{
			return;
		}
		
		LasersDay_Start(true, 0);
	}
}

public void Event_RoundEnd(Event event, char[] szEventName, bool bDontBroadcast)
{
	if (g_bRunning && !g_bDaysAPI)
	{
		LasersDay_End(0);
		return;
	}
}

public void Event_PlayerDeath(Event event, char[] szEventName, bool bDontBroadcast)
{
	int iPlayers[MAXPLAYERS];
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	PushEntryToArray(g_iLastDeaths, sizeof g_iLastDeaths, client);
	
	int iCount = GetPlayers(iPlayers, GP_Flag_Alive, GP_Team_First | GP_Team_Second);
	
	if(iCount == 1)
	{
		PushEntryToArray(g_iLastDeaths, sizeof g_iLastDeaths, iPlayers[0]);
		DaysAPI_EndDay(g_szIntName);
	}
}

void RemoveEntryFromArray(int[ ] array, int size, int entry)
{
	int i, j = -1;
	for(; i < size; i++)
	{
		if(j == -1)
		{
			if(array[i] == entry)
			{
				j = i;
			}
			
			continue;
		}
		
		array[j++] = array[i];
	}
	
	if(j != -1)
	{
		array[j] = 0;
	}
}

stock void PushEntryToArray(int[] array, int size, int entry)
{
	for(int i = size - 1; i >= 1; i--)
	{
		array[i] = array[i - 1];
	}
	
	array[0] = entry;
}

public Action SDKCallback_TraceAttack(int client)
{
	if (g_bRunning)
	{
		//PrintToServer("Blocked");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void CleanUpEntities()
{
	int iEnt = -1;
	int iOtherEnt;
	char szTargetName[32];
	
	do
	{
		//PrintToServer("iEnt; %d", iEnt);
		if (iEnt == -1)
		{
			continue;
		}
		
		GetEntPropString(iEnt, Prop_Data, "m_iName", szTargetName, sizeof szTargetName);
		
		if(StrContains(szTargetName, g_szBeamTargetName) == -1)
		{
			continue;
		}
		
		iOtherEnt = EntRefToEntIndex(GetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity"));
		if(iOtherEnt != -1)
		{
			//PrintToServer("Kill");
			AcceptEntityInput(iOtherEnt, "Kill");
		}
		
		iOtherEnt = EntRefToEntIndex(GetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", 1));
		if(iOtherEnt != -1)
		{
			//PrintToServer("Kill");
			AcceptEntityInput(iOtherEnt, "Kill");
		}
		
		//PrintToServer("Kill");
		AcceptEntityInput(iEnt, "Kill");
	}
	while ( ( iEnt = FindEntityByClassname(iEnt, g_szBeamEntity) ) != -1 );
	
	iEnt = -1;
	while( ( iEnt = FindEntityByClassname(iEnt, g_szPointEntity ) ) != -1 )
	{
		GetEntPropString(iEnt, Prop_Data, "m_iName", szTargetName, sizeof szTargetName);
		//PrintToServer("iEnt2: %d - %s - %s", iEnt, szTargetName, g_szPointEntity);
		if(StrContains(szTargetName, g_szPointStartTargetName) == -1 && StrContains(szTargetName, g_szPointEndTargetName) == -1)
		{
			continue;
		}
		
		//PrintToServer("Kill");
		AcceptEntityInput(iEnt, "Kill");
	}
}

void DestroyHandle(Handle &handle)
{
	if (handle != null)
	{
		delete handle;
		handle = null;
	}
}

public DayStartReturn LasersDay_Start(bool bWasPlanned, any data)
{
	for(int i; i < sizeof g_iLastDeaths; i++)
	{
		g_iLastDeaths[i] = 0;
	}
	
	g_bRunning = true;
	g_bWaveRunning = false;
	
	g_iWaveNumber = 1;
	g_iLaserCount = 0;
	g_flBeamSpeed = BEAM_INITIAL_SPEED;
	
	g_flWaveStartTime = GetGameTime() + PREPARATION_TIME;
	
	CreateLasers(BEAM_INITIAL_COUNT);
	g_hTimer = CreateTimer(TIMER_UPDATE_INTERVAL, Timer_StartWave, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return DSR_Success;
}

public void LasersDay_End(any data)
{
	g_bRunning = false;
	g_bWaveRunning = false;
	
	DestroyHandle(g_hTimer);
	CleanUpEntities();
	
	DaysAPI_ResetDayWinners();
	
	int iWinnersCount = 0;
	char szWinnersGroup[][] = {
		"firstplace",
		"secondplace",
		"thirdplace"
	};
	
	int iCount = GetPlayers(_, GP_Flag_Alive);
	if(iCount > 1)
	{
		return;
	}
	
	for(int i, client, iWinners[1]; i < sizeof g_iLastDeaths; i++)
	{
		client = g_iLastDeaths[i];
		if(!client || !IsClientInGame(client))
		{
			continue;
		}
		
		iWinners[0] = client;
		PrintToServer("Winner %d %N", iWinnersCount + 1, client);
		DaysAPI_SetDayWinners(szWinnersGroup[iWinnersCount++], iWinners, 1);
	}
}

public Action Timer_StartWave(Handle hTimer)
{
	if (!g_bRunning)
	{
		g_hTimer = null;
		return Plugin_Stop;
	}
	
	float flGameTime = GetGameTime();
	if (!g_bWaveRunning && flGameTime < g_flWaveStartTime)
	{
		Custom_PrintHintText(0, "Wave starts in <font color=\"#FF0000\">%0.1f</font> seconds!", g_flWaveStartTime - flGameTime);
		return Plugin_Continue;
	}
	
	g_hTimer = null;
	StartWave();
	
	return Plugin_Stop;
}

void StartWave()
{
	g_bWaveRunning = true;
	
	float flGameTime = GetGameTime();
	g_flReguideTimeDuration = (BEAM_DIST_FROM_PLAYER * ReguideTimeDurationFactor) / g_flBeamSpeed;
	g_flWaveEndTime = GetGameTime() + WAVE_TIME;
	g_flNextGuideTime = flGameTime + g_flReguideTimeDuration;
	
	CreateLasers(WAVE_EXTRA_LASERS);	
	GuideLasers();
	TurnOnLasers();

	Timer_EndWave(INVALID_HANDLE);
	g_hTimer = CreateTimer(TIMER_UPDATE_INTERVAL, Timer_EndWave, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_EndWave(Handle hTimer)
{
	if (!g_bRunning)
	{
		g_hTimer = null;
		return Plugin_Stop;
	}
	
	float flGameTime = GetGameTime();
	
	if (g_bWaveRunning && flGameTime < g_flWaveEndTime)
	{
		Custom_PrintHintText(0, "Wave: <font color=\"#0000FF\">%d</font>\n\
		Wave Ends in %0.2f seconds!", g_iWaveNumber, g_flWaveEndTime - flGameTime);
		
		if (g_flNextGuideTime < flGameTime)
		{
			g_flNextGuideTime = flGameTime + g_flReguideTimeDuration;
			GuideLasers();
		}
		
		return Plugin_Continue;
	}
	
	g_hTimer = null;
	EndWave();
	
	return Plugin_Stop;
}

void EndWave()
{
	g_bWaveRunning = false;
	g_iWaveNumber++;
	
	TurnOffLasers();
	
	g_flBeamSpeed += BEAM_SPEED_INCREASE;
	g_flWaveStartTime = GetGameTime() + WAVE_REST_TIME;
	
	Timer_StartWave(INVALID_HANDLE);
	g_hTimer = CreateTimer( TIMER_UPDATE_INTERVAL, Timer_StartWave, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

void TurnOffLasers()
{
	int iEnt = -1;
	char szTargetName[32];
	
	while ( ( iEnt = FindEntityByClassname(iEnt, g_szBeamEntity) ) != -1 )
	{
		GetEntPropString(iEnt, Prop_Data, "m_iName", szTargetName, sizeof szTargetName);
		if(StrContains(szTargetName, g_szBeamTargetName) == -1)
		{
			continue;
		}
		
		AcceptEntityInput(iEnt, "TurnOff");
	}
}

void TurnOnLasers()
{
	int iEnt = -1;
	char szTargetName[32];
	
	while ( ( iEnt = FindEntityByClassname(iEnt, g_szBeamEntity) ) != -1 )
	{
		GetEntPropString(iEnt, Prop_Data, "m_iName", szTargetName, sizeof szTargetName);
		if(StrContains(szTargetName, g_szBeamTargetName) == -1)
		{
			continue;
		}
		
		AcceptEntityInput(iEnt, "TurnOn");
	}
}

void GuideLasers()
{
	int iEnt;
	//int iStartEnt, iEndEnt;
	int iTargetedClient;
	
	char szTargetName[32];
	
	int iPlayers[MAXPLAYERS], iCount;
	iCount = GetPlayers(iPlayers, GP_Flag_Alive, GP_Team_First | GP_Team_Second);
	
	iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, g_szBeamEntity)) != -1)
	{
		GetEntPropString(iEnt, Prop_Data, "m_iName", szTargetName, sizeof szTargetName);
		
		if (StrContains(szTargetName, g_szBeamTargetName) == -1)
		{
			continue;
		}
		
		iTargetedClient = iPlayers[GetRandomInt(0, iCount - 1)];
		GuideLaserToClient(iEnt, iTargetedClient);
	}
}

void GuideLaserToClient(int iEnt, int client)
{
	float vAngles[3];
	float vForward[3];
	float vRight[3]; // The vector for the start point of the beam
	float vLeft[3]; // The vector for the end point of the beam
	float vVelocity[3];
	
	float vPosRight[3];
	float vPosLeft[3];
	float vPos[3];
	
	#if defined DEBUG
	float vOPos[3];
	#endif
	
	// How it is done:
	// What I am doing here is basicly getting a random angle from a player and move the center of the beam
	// based on that angle and then get the left and right positions and using our first vector assign a negative velocity);
	
	// Get a random direction and assume that this direction
	// Is pointed from the client origin.
	vAngles[0] = GetRandomFloat(-180.0, 180.0); // Pitch
	vAngles[1] = GetRandomFloat(-180.0, 180.0); // Yaw
	vAngles[2] = GetRandomFloat(-180.0, 180.0); // Roll
	
	// Get the vector assiciated with this angle
	GetAngleVectors(vAngles, vForward, vRight, NULL_VECTOR);
	CopyVector(vRight, vLeft);
	NegateVector(vLeft);
	
	NormalizeVector(vForward, vForward);
	CopyVector(vForward, vVelocity);
	NegateVector(vVelocity); // We want our beam to move in the opposite direction, coming
	// Towards the targeted player
	ScaleVector(vVelocity, g_flBeamSpeed);
	
	NormalizeVector(vRight, vRight);
	NormalizeVector(vLeft, vLeft);
	
	GetClientAbsOrigin(client, vPos);
	#if defined DEBUG
	GetClientAbsOrigin(client, vOPos);
	#endif
	vPos[2] += 32.0; // Have it to the middle of the body.
	
	// Move our position vector
	ScaleVector(vForward, BEAM_DIST_FROM_PLAYER);
	AddVectors(vPos, vForward, vPos);
	
	// Then we need another position to the right and left of that position
	ScaleVector(vRight, BEAM_LENGTH / 2.0);
	ScaleVector(vLeft, BEAM_LENGTH / 2.0);
	
	// Nice, now make our points.
	AddVectors(vPos, vRight, vPosRight);
	AddVectors(vPos, vLeft, vPosLeft);
	
	#if defined DEBUG
	int Color[4];
	Color[0] = GetRandomInt(0, 255);
	Color[1] = GetRandomInt(0, 255);
	Color[2] = GetRandomInt(0, 255);
	Color[3] = 255;
	
	TE_SetupBeamPoints(vOPos, vPosRight, g_iBeamSprite, 0, 0, 1, g_flReguideTimeDuration, 2.0, 2.0, 0, 0.0, Color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(vOPos, vPosLeft, g_iBeamSprite, 0, 0, 1, g_flReguideTimeDuration, 2.0, 2.0, 0, 0.0, Color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(vOPos, vPos, g_iBeamSprite, 0, 0, 1, g_flReguideTimeDuration, 2.0, 2.0, 0, 0.0, Color, 5);
	TE_SendToAll();
	#endif
	
	// Now we have everything.
	// Just assign them to our beam points
	TeleportEntity(EntRefToEntIndex(GetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity")), vPosRight, NULL_VECTOR, vVelocity);
	TeleportEntity(EntRefToEntIndex(GetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", 1)), vPosLeft, NULL_VECTOR, vVelocity);
	// We are done
}

void CopyVector(float vVector[3], float vResult[3])
{
	for (int i; i < 3; i++)
	{
		vResult[i] = vVector[i];
	}
}

void CreateLasers(int iCount)
{
	int iEnt, iStartEnt, iEndEnt;
	char szTargetName[32];
	
	for (int i; i < iCount; i++)
	{
		iEnt = CreateEntityByName(g_szBeamEntity);
		
		if (iEnt == -1)
		{
			continue;
		}
		
		++g_iLaserCount;
		
		SetEntityModel(iEnt, g_szBeamSprite);
		DispatchKeyValue(iEnt, "renderamt", "100");
		DispatchKeyValue(iEnt, "rendermode", "0");
		
		FormatEx(szTargetName, sizeof szTargetName, "%d %d %d", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
		DispatchKeyValue(iEnt, "rendercolor", szTargetName);
		
		DispatchKeyValue(iEnt, "life", "0");
		DispatchKeyValue(iEnt, "ScrollSpeed", "10");
		DispatchKeyValueFloat(iEnt, "NoiseAmplitude", 64.0);
		DispatchKeyValue(iEnt, "framestart", "0");
		//DispatchKeyValue(iEnt, "TouchType", "0");	// None
		
		DispatchKeyValueFloat(iEnt, "damage", BEAM_DAMAGE);
		
		SetEntProp(iEnt, Prop_Send, "m_nNumBeamEnts", 2);
		SetEntProp(iEnt, Prop_Send, "m_nBeamType", 2);
		
		SetEntPropFloat(iEnt, Prop_Data, "m_fWidth", BEAM_WIDTH);
		SetEntPropFloat(iEnt, Prop_Data, "m_fEndWidth", BEAM_WIDTH);
		DispatchKeyValue(iEnt, "spawnflags", "1");
		
		DispatchSpawn(iEnt);
		
		FormatEx(szTargetName, sizeof szTargetName, g_szBeamTargetName/*, g_iLaserCount - 1*/);
		SetEntPropString(iEnt, Prop_Data, "m_iName", szTargetName);
		
		iStartEnt = CreateEntityByName(g_szPointEntity);
		iEndEnt = CreateEntityByName(g_szPointEntity);
		
		DispatchSpawn(iStartEnt);
		DispatchSpawn(iEndEnt);
		
		FormatEx(szTargetName, sizeof szTargetName, g_szPointStartTargetName);
		SetEntPropString(iStartEnt, Prop_Data, "m_iName", szTargetName);
		FormatEx(szTargetName, sizeof szTargetName, g_szPointEndTargetName);
		SetEntPropString(iEndEnt, Prop_Data, "m_iName", szTargetName);
		
		SetEntityModel(iStartEnt, "");
		SetEntProp(iStartEnt, Prop_Send, "m_CollisionGroup", 0);
		SetEntProp(iStartEnt, Prop_Data, "m_usSolidFlags", 0x0004, 2);
		SetEntProp(iStartEnt, Prop_Data, "m_MoveType", MOVETYPE_NOCLIP);
		
		SetEntityModel(iEndEnt, "");
		SetEntProp(iEndEnt, Prop_Send, "m_CollisionGroup", 0);
		SetEntProp(iEndEnt, Prop_Data, "m_usSolidFlags", 0x0004, 2);
		SetEntProp(iEndEnt, Prop_Data, "m_MoveType", MOVETYPE_NOCLIP);
		
		SetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iStartEnt) );
		SetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEndEnt), 1);
	}
}

void Custom_PrintHintText(int client, char[] szBuffer, any...)
{
	char szMessage[512];
	int iLen = FormatEx(szMessage, sizeof szMessage, "<font color=\"#FFFF00\">L</font>\
		<font color=\"#00FF00\">A</font>\
		<font color=\"#0000FF\">Z</font>\
		<font color=\"#00FFFF\">E</font>\
		<font color=\"#FF00FF\">R</font>\
		<font color=\"#FFFFFF\">Z</font><br>");
		
	iLen += VFormat(szMessage[iLen], sizeof(szMessage) - iLen, szBuffer, 3);
	
	if (client == 0)
	{
		PrintHintTextToAll(szMessage);
	}
	
	else
	{
		PrintHintText(client, szMessage);
	}
} 