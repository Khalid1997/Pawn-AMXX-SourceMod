#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};


enum  (<<= 1)
{
	RecordStats_DoNotRecord = -1,
	RecordStats_None = 0,
	RecordStats_Kills = 1,		// 1
	RecordStats_Headshots,		// 2
	RecordStats_Deaths,			// 4
	RecordStats_Assists,		// 8
	RecordStats_BombPlants,		// 16
	RecordStats_BombDefuses,	// 32
	RecordStats_2Kills,			// 64
	RecordStats_3Kills,			// 128
	RecordStats_4Kills,			// 256
	RecordStats_Aces,			// 512
	RecordStats_TotalShots,		// 1024
	RecordStats_TotalHits,		// 2048
	RecordStats_TotalDamage,	// 4096
	RecordStats_MVP,			// 8192
	RecordStats_RoundsPlayed	// 16384
};

const int RecordStats_All = (RecordStats_Kills | RecordStats_Headshots | RecordStats_Deaths | RecordStats_Assists
							| RecordStats_BombPlants | RecordStats_BombDefuses | RecordStats_2Kills | RecordStats_3Kills
							| RecordStats_4Kills| RecordStats_Aces | RecordStats_TotalShots | RecordStats_TotalHits
							| RecordStats_TotalDamage | RecordStats_MVP | RecordStats_RoundsPlayed );							


public void OnPluginStart()
{
	int something = 32767;
	
	PrintToServer("****** %d", RecordStats_All);
	PrintToServer("****** %d", RecordStats_All & ~(RecordStats_2Kills, RecordStats_3Kills, RecordStats_4Kills, RecordStats_Aces));
	PrintToServer("****** %s", something & RecordStats_Assists ? "Yes" : "No");
	
	int iTest2 = GetShifts(RecordStats_RoundsPlayed);//(1>>RecordStats_RoundsPlayed);
	int iTest = 1;
	for(int i = 2; i <= ( 15 ); i++)
	{
		iTest |= (1<<i);
		PrintToServer("****** Add %d %d - %d", i, 1<<i, iTest );
		
	}
	
	iTest |= 1;
	int one = 1;
	PrintToServer("****** iTest = %d", iTest);
	PrintToServer("****** iTest2 = %d", iTest2);
	PrintToServer("****** %s", one & 1 ? "Yes" : "No");
}

int GetShifts(const int iDecimal)
{
	int iNum;
	int iTest = iDecimal;
	while(iTest)
	{
		iTest = (iTest>>1);
		iNum++;
		PrintToServer("iDecimal %d", iTest);
	}
	return iNum;
}

int GetBinary(int iDecimal)
{
	static char szString[16];
	FormatEx(szString, sizeof szString, "%d", iDecimal);
	
	return StringToInt(szString, 2);
}
	