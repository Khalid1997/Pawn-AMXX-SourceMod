#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <emitsoundany>
#include <sdktools>
#include <multicolors>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <daysapi>
#include <simonapi>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "MEMEMEMEME",
	author = PLUGIN_AUTHOR,
	description = "MEMEMEMME",
	version = PLUGIN_VERSION,
	url = ""
};

#define MAX_REFUSALS_PER_ROUND	2
#define MAX_REPEATS_PER_ROUND	2

char g_szSoundsPath[] = "music/MyJailbreak";

char g_szRefusalWords[][] = {
	"no",
	"refuse",
	"bla",
	"tflsf",
	"meme"
};

char g_szRepeatWords[][] = {
	"repeat",
	"say what",
	"saywhat",
	"again",
	"what"
};

char g_szRefusalSounds[][] = {
	"refuse.mp3",
	"Gibberish.mp3"
};

char g_szRepeatSounds[][] = {
	"repeat.mp3"
};

int g_iRefusesThisRound[MAXPLAYERS];
int g_iRepeatsThisRound[MAXPLAYERS];

bool g_bSoundsAllowed;
bool g_bSimonAssignedForTheRound;
bool g_bSimonAPI;

bool g_bLate;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErroMax)
{
	g_bLate = bLate;
}

public void OnPluginStart()
{
	CSetPrefix("\x03[\x04Jailbreak\x03]\x01");
	
	AddCommandListener(Command_OnSay, "say");
	HookEvent("round_start", Event_RoundStart);
	
	g_bSoundsAllowed = true;
	
	if(g_bLate)
	{
		OnMapStart();
	}
}

public void OnAllPluginsLoaded()
{
	g_bSimonAPI = LibraryExists("simonapi");
}

public void DaysAPI_OnDayStart()
{
	g_bSoundsAllowed = false;
}

public void DaysAPI_OnDayEnd()
{
	g_bSoundsAllowed = true;
}

public void SimonAPI_OnSimonChanged(int iNew, int iOld, SimonChangedReason iReason)
{
	if( ( 1 <= iNew <= MaxClients ) )
	{
		g_bSimonAssignedForTheRound = true;
	}
}

public void OnClientPutInServer(int client)
{
	g_iRefusesThisRound[client] = 0;
	g_iRepeatsThisRound[client] = 0;
}

public void OnMapStart()
{
	char szFile[PLATFORM_MAX_PATH];
	
	for (int i; i < sizeof g_szRefusalSounds; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", g_szSoundsPath, g_szRefusalSounds[i]);
		PrecacheSoundAny(szFile, false);
		
		FormatEx(szFile, sizeof szFile, "sound/%s/%s", g_szSoundsPath, g_szRefusalSounds[i]);
		AddFileToDownloadsTable(szFile);
	}
	
	for (int i; i < sizeof g_szRepeatSounds; i++)
	{
		FormatEx(szFile, sizeof szFile, "%s/%s", g_szSoundsPath, g_szRepeatSounds[i]);
		PrecacheSoundAny(szFile, false);
		
		FormatEx(szFile, sizeof szFile, "sound/%s/%s", g_szSoundsPath, g_szRepeatSounds[i]);
		AddFileToDownloadsTable(szFile);
	}
	
	g_bSoundsAllowed = true;
}

public void Event_RoundStart(Event event, const char[] szEventName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iRefusesThisRound[i] = 0;
		g_iRepeatsThisRound[i] = 0;
	}
	
	g_bSimonAssignedForTheRound = false;
}

public Action Command_OnSay(int client, const char[] command, int argc)
{
	if(!g_bSoundsAllowed || !IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_T)
	{
		return;
	}
	
	char szChatString[PLATFORM_MAX_PATH];
	int iLen = GetCmdArgString(szChatString, sizeof(szChatString));
	
	if(iLen < 2)
	{
		return;
	}
	
	int startidx = 0;
			
	if(szChatString[strlen(szChatString)-1] == '"')
	{
		szChatString[strlen(szChatString)-1] = '\0';
		startidx = 1;
	}
	
	AttemptPlaySound(client, szChatString[startidx]);
}

void AttemptPlaySound(int client, char[] szString)
{
	for (int i; i < sizeof g_szRefusalWords; i++)
	{
		if(StrContains(szString, g_szRefusalWords[i], false) > -1)
		{
			if(g_bSimonAPI && !g_bSimonAssignedForTheRound)
			{
				CPrintToChat(client, "A warden needs to be assigned before you can request a repeat or refuse a command!");
				return;
			}
			
			if (g_iRefusesThisRound[client] >= MAX_REFUSALS_PER_ROUND)
			{
				return;
			}
			
			g_iRefusesThisRound[client]++;
			
			CPrintToChatAll("Prisoner %N refuses!", client);
			CPrintToChat(client, "You have used %d/%d refusals for this round.", g_iRefusesThisRound[client], MAX_REFUSALS_PER_ROUND);
			
			PlayRefusalSound();
			
			
			return;
		}
	}
	
	for (int i; i < sizeof g_szRepeatWords; i++)
	{
		if(StrContains(szString, g_szRepeatWords[i], false) > -1)
		{
			if(g_bSimonAPI && !g_bSimonAssignedForTheRound)
			{
				CPrintToChat(client, "A warden needs to be assigned before you can request a repeat or refuse a command!");
				return;
			}
			
			if (g_iRepeatsThisRound[client] >= MAX_REPEATS_PER_ROUND)
			{
				return;
			}
			
			g_iRepeatsThisRound[client]++;
			
			CPrintToChatAll("Prisoner %N requests a repeat!", client);
			CPrintToChat(client, "You have used %d/%d repeats for this round.", g_iRepeatsThisRound[client], MAX_REPEATS_PER_ROUND);
			
			PlayRepeatSound();
			return;
		}
	}
}

void PlayRefusalSound()
{
	char szFile[PLATFORM_MAX_PATH];
	FormatEx(szFile, sizeof szFile, "%s/%s", g_szSoundsPath, g_szRefusalSounds[GetRandomInt(0, sizeof(g_szRefusalSounds) - 1)]);
	//PrintToChatAll(szFile);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			EmitSoundToClientAny(i, szFile);
		}
	}
}

void PlayRepeatSound()
{
	char szFile[PLATFORM_MAX_PATH];
	FormatEx(szFile, sizeof szFile, "%s/%s", g_szSoundsPath, g_szRepeatSounds[GetRandomInt(0, sizeof(g_szRepeatSounds) - 1)]);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			EmitSoundToClientAny(i, szFile);
		}
	}
}
