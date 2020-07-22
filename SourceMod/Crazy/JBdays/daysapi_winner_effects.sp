#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <daysapi>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "DaysAPI: Winners Effects",
	author = PLUGIN_AUTHOR,
	description = "LOL, MOST RETARDED PLUGIN EVER",
	version = PLUGIN_VERSION,
	url = ""
};

// Settings
float radius_start = 90.5;
float radius_end = 500.0;
int start_frame = 0;
int frame_rate = 10;
float life = 1.0;
float width = 16.0;
//float amp = 5.0;
#define amp GetRandomFloat(0.0, 16.0/*64.0 max*/)
int speed = 100;

#define SHUTOFF_TIME	12.0			// Time in seconds to stop doing the effects after start
#define INTERVAL_BETWEEN_EFFECTS 	0.5

int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

float g_flShutoffTime;
Handle g_hTimer = null;

int g_iWinners[MAXPLAYERS], g_iCount;

char g_szSoundsFolder[] = "days";
char g_szSounds[][] = {
//	"win1.mp3",	// not working for some reason
	"win9.mp3",
	"win7.mp3",
	"win15.mp3",
//	"win14.mp3",
	"win16.mp3"
};

// Do not remove the -1
// It is neceserry to avoid run time errors;
int g_iLastSoundPlayed;
int g_iLastSound = -1;

ConVar ConVar_RoundRestartDelay;
float g_flOldRoundRestartDelay;

void DestroyHandle(Handle &hHandle)
{
	if(hHandle != null)
	{
		delete hHandle;
		hHandle = null;
	}
}

public void OnPluginStart()
{
	ConVar_RoundRestartDelay = FindConVar("mp_round_restart_delay");
}

public void OnMapStart()
{
	g_hTimer = null;
	g_iBeamSprite = PrecacheModel("materials/sprites/physbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/light_glow02.vmt");
	
	char szFile[PLATFORM_MAX_PATH];
	
	for (int i; i < sizeof g_szSounds; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", g_szSoundsFolder, g_szSounds[i]);
		PrecacheSoundAny(szFile);
		
		Format(szFile, sizeof szFile, "sound/%s", szFile);
		AddFileToDownloadsTable(szFile);
	}
}

public DayStartReturn DaysAPI_OnDayStart_Pre(char[] szName, bool bWasPlanned, any data)
{
	g_flOldRoundRestartDelay = ConVar_RoundRestartDelay.FloatValue;
	
	if(g_flOldRoundRestartDelay < 8.0)
	{
		ConVar_RoundRestartDelay.FloatValue = 8.0;
	}
}

public void DaysAPI_OnDayEnd(char[] szName)
{
	DestroyHandle(g_hTimer);
	
	ConVar_RoundRestartDelay.FloatValue = g_flOldRoundRestartDelay;
	
	g_iCount = 0;
	DaysAPI_GetDayWinnersGroups(GetDaysWinnersCallback);

	if(g_iCount)
	{
		Start_Winners_Effects();
	}
}

public void GetDaysWinnersCallback(char[] szDay, char[] szWinnerGroup, int[] iWinners, int iCount, any data)
{
	for (int i; i < iCount; i++)
	{
		g_iWinners[g_iCount++] = iWinners[i];
	}
}

void Start_Winners_Effects()
{
	++g_iLastSound;
	if(g_iLastSound == sizeof g_szSounds)
	{
		g_iLastSound = 0;
	}
	
	PlaySound(g_iLastSound);
	
	g_flShutoffTime = GetGameTime() + SHUTOFF_TIME;
	Timer_ApplyEffects(INVALID_HANDLE, 0);
	g_hTimer = CreateTimer(INTERVAL_BETWEEN_EFFECTS, Timer_ApplyEffects, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ApplyEffects(Handle hTimer, int args)
{
	if(GetGameTime() > g_flShutoffTime)
	{
		g_hTimer = null;
		EndSound();
		return Plugin_Stop;
	}
	
	float vPos[3];
	int iColor[4];
	iColor[0] = GetRandomInt(0, 254);
	iColor[1] = GetRandomInt(0, 254);
	iColor[2] = GetRandomInt(0, 254);
	iColor[3] = 200;
	
	for (int i, client; i < g_iCount; i++)
	{
		client = g_iWinners[i];
		if(!IsClientInGame(client))
		{
			continue;
		}
		
		if(!IsPlayerAlive(client))
		{
			continue;
		}
		
		GetClientAbsOrigin(client, vPos);
		vPos[2] += 32.0;
		TE_SetupBeamRingPoint(vPos, radius_start, radius_end, g_iBeamSprite, g_iHaloSprite, start_frame, frame_rate, life, width, amp, iColor, speed, 0);
		TE_SendToAll();
	}
	
	return Plugin_Continue;
}

void EndSound()
{
	char szFile[PLATFORM_MAX_PATH];
	FormatEx(szFile, sizeof szFile, "%s/%s", g_szSoundsFolder, g_szSounds[g_iLastSoundPlayed]);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		StopSoundAny(i, SNDCHAN_AUTO, szFile);
	}
}

void PlaySound(int iIndex)
{
	g_iLastSoundPlayed = iIndex;
	
	char szFile[PLATFORM_MAX_PATH];
	FormatEx(szFile, sizeof szFile, "%s/%s", g_szSoundsFolder, g_szSounds[iIndex]);
	
	// Ends at round end
	//EmitSoundToAllAny(szFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		ClientCommand(i, "play \"*%s\"", szFile);
	}
}