#pragma semicolon 1
#include <sourcemod>
#include <getplayers>
#include <jail_shop>

//#pragma newdecls required

public Plugin MyInfo = 
{
	name = "JBShop: Guess the Number", 
	description = "Gain credits for guessing a random number", 
	version = "1.0", 
	author = "Khalid", 
	url = "none"
};

char g_szPrefix[60] = "[Guess The Number]";

// --- Convars ---
ConVar 	ConVar_NormalNumberRange, 
		ConVar_NormalNumberMax, 
		ConVar_NormalNumberMin, 
		ConVar_NormalWinCreditsMax, 
		ConVar_NormalWinCreditsMin, 

		ConVar_RareNumberRange, 
		ConVar_RareNumberMax, 
		ConVar_RareNumberMin, 
		ConVar_RareWinCreditsMax, 
		ConVar_RareWinCreditsMin, 
		ConVar_RarePossibility, 

		ConVar_GuessingTime, 
		ConVar_DelayForFullCredits, 

		ConVar_CreditsFastPercentage, 

		ConVar_DelayBetween, 
		ConVar_MinPlayers,
		
		ConVar_Debug_ShowNum;

// --- Cvar Variables ---
int 	g_iNormalNumberRange, 
		g_iNormalNumberMax, 
		g_iNormalNumberMin, 
		g_iNormalWinCreditsMax, 
		g_iNormalWinCreditsMin, 

		g_iRareNumberRange, 
		g_iRareNumberMax, 
		g_iRareNumberMin, 
		g_iRareWinCreditsMax, 
		g_iRareWinCreditsMin;
float 	g_flRarePossibility, 

		g_flGuessingTime, 
		g_flDelayForFullCredits;

int 	g_iCreditsFastPercentage;

float 	g_flDelayBetween;
int 	g_iMinPlayers;

// --- Others ---
bool g_bRunning;

bool g_bFastPercentage;

int g_iNumber, 
g_iWinCredits, g_iWinner;

float g_flStartTime;

void GetConVarValues()
{
	g_iNormalNumberRange = ConVar_NormalNumberRange.IntValue;
	g_iNormalNumberMax = ConVar_NormalNumberMax.IntValue;
	g_iNormalNumberMin = ConVar_NormalNumberMin.IntValue;
	g_iNormalWinCreditsMax = ConVar_NormalWinCreditsMax.IntValue;
	g_iNormalWinCreditsMin = ConVar_NormalWinCreditsMin.IntValue;
	
	g_iRareNumberRange = ConVar_RareNumberRange.IntValue;
	g_iRareWinCreditsMax = ConVar_RareWinCreditsMax.IntValue;
	g_iRareWinCreditsMin = ConVar_RareWinCreditsMin.IntValue;
	g_iRareNumberMax = ConVar_RareNumberMax.IntValue;
	g_iRareNumberMin = ConVar_RareNumberMin.IntValue;
	g_flRarePossibility = ConVar_RarePossibility.FloatValue;
	
	g_flGuessingTime = ConVar_GuessingTime.FloatValue;
	g_flDelayForFullCredits = ConVar_DelayForFullCredits.FloatValue;
	g_iCreditsFastPercentage = ConVar_CreditsFastPercentage.IntValue;
	g_flDelayBetween = ConVar_DelayBetween.FloatValue;
	g_iMinPlayers = ConVar_MinPlayers.IntValue;
	
	//g_iTeams = ConVar_Teams.IntValue;
}

public void OnPluginStart()
{
	HookConVarChange((ConVar_NormalNumberRange = CreateConVar("gtn_number_range", "15", "Number range. Ex: if the value is 15, the number can be between 35 and 20")), ConVarHook_Changed);
	HookConVarChange(( ConVar_NormalNumberMax = CreateConVar("gtn_number_max", "100", "Maximum number that can be guess")), ConVarHook_Changed);
	HookConVarChange((ConVar_NormalNumberMin = CreateConVar("gtn_number_min", "0", "Minimum number that can be guess")), ConVarHook_Changed);
	HookConVarChange((ConVar_NormalWinCreditsMax = CreateConVar("gtn_win_credits_max", "1000", "Maximum credits to be won in a guess")), ConVarHook_Changed);
	HookConVarChange((ConVar_NormalWinCreditsMin = CreateConVar("gtn_win_credits_min", "300", "Minimum credits to be won in a guess")), ConVarHook_Changed);
	
	HookConVarChange((ConVar_RareNumberRange = CreateConVar("gtn_rare_number_range", "50", "Number range. Ex: if the value is 15, the number will be between 15 and 0")), ConVarHook_Changed);
	HookConVarChange((ConVar_RareWinCreditsMax = CreateConVar("gtn_rare_win_credits_max", "100000", "Maximum credits to be won in a guess")), ConVarHook_Changed);
	HookConVarChange((ConVar_RareWinCreditsMin = CreateConVar("gtn_rare_win_credits_min", "10000", "Minimum credits to be won in a guess")), ConVarHook_Changed);
	HookConVarChange((ConVar_RareNumberMax = CreateConVar("gtn_rare_number_max", "200", "Maximum number that can be guess")), ConVarHook_Changed);
	HookConVarChange((ConVar_RareNumberMin = CreateConVar("gtn_rare_number_min", "0", "Manimum number that can be guess")), ConVarHook_Changed);
	HookConVarChange((ConVar_RarePossibility = CreateConVar("gtn_rare_possibility", "15.0", "Rare possiblity in percentage value")), ConVarHook_Changed);
	
	HookConVarChange((ConVar_GuessingTime = CreateConVar("gtn_guessing_time", "15", "Guessing Time in seconds")), ConVarHook_Changed);
	HookConVarChange((ConVar_DelayForFullCredits = CreateConVar("gtn_delay_for_full_credits", "5", "In seconds. If the player guess the number within x seconds of the start they will get full credits. \n// This only works if gtn_fast_percentage is 1")), ConVarHook_Changed);
	HookConVarChange((ConVar_CreditsFastPercentage = CreateConVar("gtn_fast_percentage", "0", "[0/1/2/3] [0 - Disabled | 1 - Enabled for all | 2 - Enabled for Normal Only | 3 - Enable for rare only] Credits will be given as a percentage of 0.xx number on how fast the player has answered")), ConVarHook_Changed);
	HookConVarChange((ConVar_DelayBetween = CreateConVar("gtn_delay", "30.0", "Delay between two questions/guesses.")), ConVarHook_Changed);
	HookConVarChange((ConVar_MinPlayers = CreateConVar("gtn_min_players", "1")), ConVarHook_Changed);
	
	ConVar_Debug_ShowNum = CreateConVar("gtn_debug_show_number", "1");
	GetConVarValues();
	
	AddCommandListener(ClientCmd_Say, "say");
}

public void OnMapStart()
{
	g_bRunning = false;
	//GetConVarValues();
	AutoExecConfig(true, "guess_the_number", "sourcemod");
	CreateTimer(g_flDelayBetween, Timer_StartTheGuessGame, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	//PrintToServer("%0.2f", g_flDelayBetween);
}

public Action Timer_StartTheGuessGame(Handle hTimer)
{
	if (g_bRunning)
	{
		return Plugin_Stop;
	}
	
	int iCount, iPlayers[MAXPLAYERS];
	iCount = GetPlayers(iPlayers, GP_Flag_NoBots, GP_Team_First | GP_Team_Second);
	
	if (iCount < g_iMinPlayers)
	{
		//CreateTimer(g_flDelayBetween, Timer_StartTheGuessGame, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	
	StartGame();
	return Plugin_Stop;
}

void StartGame()
{
	int iNumberMin, iNumberMax, iNumberRange;
	int iNumberStart;
	
	g_iWinner = 0;
	
	bool bIsRare = false;
	
	float flPercentRandom = GetRandomFloat(0.0, 100.0);
	
	g_bFastPercentage = false;
	
	if (0.0 < flPercentRandom <= g_flRarePossibility)
	{
		bIsRare = true;
		
		g_iWinCredits = GetRandomInt(g_iRareWinCreditsMin, g_iRareWinCreditsMax);
		
		//PrintToServer("%d %d %d", g_iRareWinCreditsMin, g_iRareWinCreditsMax, g_iWinCredits);
		
		iNumberMin = g_iRareNumberMin; iNumberMax = g_iRareNumberMax;
		iNumberRange = g_iRareNumberRange;
		
		if (g_iCreditsFastPercentage == 3 || g_iCreditsFastPercentage == 1)
		{
			g_bFastPercentage = true;
		}
	}
	
	else
	{
		g_iWinCredits = GetRandomInt(g_iNormalWinCreditsMin, g_iNormalWinCreditsMax);
		
		//PrintToServer("%d %d %d", g_iNormalWinCreditsMin, g_iNormalWinCreditsMax, g_iWinCredits);
		
		iNumberMin = g_iNormalNumberMin; iNumberMax = g_iNormalNumberMax;
		iNumberRange = g_iNormalNumberRange;
		
		if (g_iCreditsFastPercentage == 2 || g_iCreditsFastPercentage == 1)
		{
			g_bFastPercentage = true;
		}
	}
	
	iNumberStart = GetRandomInt(iNumberMin, iNumberMax);
	
	//PrintToServer("iNumber start %d, iNumberMin %d, iNumberMax %d iNumberRange %d", iNumberStart, iNumberMin, iNumberMax, iNumberRange);
	bool bGot = false;
	for (int i; i < 99; i++)
	{
		if (iNumberStart + iNumberRange < iNumberMax)
		{
			g_iNumber = GetRandomInt((iNumberMin = iNumberStart), (iNumberMax = iNumberStart + iNumberRange));
			
			//PrintToServer("1: iNumberMin: %d iNumberMax = %d; iNumber  %d, iAvg = %d", iNumberMin, iNumberMax, g_iNumber, (iNumberMin + iNumberMax) / 2);
			bGot = true;
			break;
		}
		else if (iNumberStart - iNumberRange > iNumberMin)
		{
			g_iNumber = GetRandomInt((iNumberMin = iNumberStart - iNumberRange), (iNumberMax = iNumberStart));
			
			//PrintToServer("2: iNumberMin: %d iNumberMax = %d; iNumber  %d, iAvg = %d", iNumberMin, iNumberMax, g_iNumber, (iNumberMin + iNumberMax) / 2);
			bGot = true;
			break;
		}
	}
	
	if (!bGot)
	{
		LogError("Could not start Guess The Number because the number range does not fit in number min or max");
		return;
	}
	
	if (bIsRare)
	{
		PrintToChat_Custom(0, "\x06RARE POSSIBILITY!!!");
		PrintHintTextToAll("RARE POSSIBLITY!!");
	}
	
	PrintToChat_Custom(0, "The Game has started! You have %0.1f seconds to answer!", g_flGuessingTime);
	PrintToChat_Custom(0, "The number is between [%d and %d]. %sPrize: %d Credits", iNumberMin, iNumberMax, g_bFastPercentage ? "Maximum " : "", g_iWinCredits);
	
	if(ConVar_Debug_ShowNum.IntValue == 1)
	{
		PrintToChatAll("Number is %d", g_iNumber);
	}
	
	g_flStartTime = GetGameTime();
	g_bRunning = true;
	
	CreateTimer(g_flGuessingTime, Timer_EndTheGuessGame, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_EndTheGuessGame(Handle hTimer)
{
	g_bRunning = false;
	if(!g_iWinner)
	{
		PrintToChat_Custom(0, "\x05The game has ended! The number was \x01%d. \x07%d \x01credits have flown away.", g_iNumber, g_iWinCredits);
	}
	
	CreateTimer(g_flDelayBetween, Timer_StartTheGuessGame, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	return Plugin_Stop;
}

public Action ClientCmd_Say(int client, char[] szCommand, int iArgCount)
{
	if (!g_bRunning)
	{
		return;
	}
	
	if(g_iWinner)
	{
		return;
	}
	
	int iNumber;
	char szNumber[10];
	
	GetCmdArgString(szNumber, sizeof szNumber);
	StripQuotes(szNumber);
	
	if (!IsStringNumber(szNumber, sizeof szNumber))
	{
		return;
	}
	
	iNumber = StringToInt(szNumber);
	
	if (iNumber == g_iNumber && !g_iWinner)
	{
		DeclareWinner(client);
	}
}

DeclareWinner(client)
{
	//delete g_hTimer_End;
	//g_bRunning = false;
	
	g_iWinner = client;
	
	float flEndTime = GetGameTime();
	float flWinCreditsFactor;
	
	PrintToChat_Custom(0, "\x01Player \x05%N \x01answered in \x05%0.3f \x01seconds! The number was \x03%d\x01.", client, flEndTime - g_flStartTime, g_iNumber);
	
	if (g_bFastPercentage)
	{
		if(g_flDelayForFullCredits > 0.0 && (flEndTime - g_flStartTime) <= g_flDelayForFullCredits)
		{
			flWinCreditsFactor = 1.0;
			//PrintToChatAll("Full credits: %0.2f %0.2f %0.2f", flEndTime, g_flStartTime, g_flDelayForFullCredits);
		}
		
		else
		{
			flWinCreditsFactor = ( 1.0 - ( ( flEndTime - g_flStartTime ) / g_flGuessingTime ) );
		}
		
		//PrintToChatAll("flWinCreditsFactor = %0.2f", flWinCreditsFactor);
		g_iWinCredits = RoundFloat( float(g_iWinCredits) * flWinCreditsFactor );
		
		//PrintToServer("flTestFactor  =  %0.5f", flTestFactor);
	}
	
	PrintToChat_Custom(0, "\x01He won \x06%d \x01credits for answering in \x05%0.3f \x01seconds.", g_iWinCredits, flEndTime - g_flStartTime);
	
	JBShop_SetCredits(client, JBShop_GetCredits(client) + g_iWinCredits);
}

stock void PrintToChat_Custom(int client, char[] szMsg, any:...)
{
	#define MAX_MESSAGE_LENGTH 256
	char szBuffer[MAX_MESSAGE_LENGTH];
	VFormat(szBuffer, sizeof szBuffer, szMsg, 3);
	
	if (client)
	{
		PrintToChat(client, " \x04%s \x01%s", g_szPrefix, szBuffer);
	} else {
		PrintToChatAll(" \x04%s \x01%s", g_szPrefix, szBuffer);
	}
}

public void ConVarHook_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	//PrintToServer("Called");
	if (convar == ConVar_NormalNumberRange)
	{
		g_iNormalNumberRange = StringToInt(newValue);
	}
	
	else if (convar == ConVar_NormalNumberMax)
	{
		g_iNormalNumberMax = StringToInt(newValue);
	}
	
	else if (convar == ConVar_NormalNumberMin)
	{
		g_iNormalNumberMin = StringToInt(newValue);
	}
	
	else if (convar == ConVar_NormalWinCreditsMax)
	{
		g_iNormalWinCreditsMax = StringToInt(newValue);
	}
	
	else if (convar == ConVar_NormalWinCreditsMin)
	{
		g_iNormalWinCreditsMin = StringToInt(newValue);
	}
	
	else if (convar == ConVar_RareNumberRange)
	{
		g_iRareNumberRange = StringToInt(newValue);
	}
	
	else if (convar == ConVar_RareWinCreditsMax)
	{
		g_iRareWinCreditsMax = StringToInt(newValue);
	}
	
	else if (convar == ConVar_RareWinCreditsMin)
	{
		g_iRareWinCreditsMin = StringToInt(newValue);
	}
	
	else if (convar == ConVar_RareNumberMax)
	{
		g_iRareNumberMax = StringToInt(newValue);
	}
	
	else if (convar == ConVar_RareNumberMin)
	{
		g_iRareNumberMin = StringToInt(newValue);
	}
	
	else if (convar == ConVar_RarePossibility)
	{
		g_flRarePossibility = StringToFloat(newValue);
	}
	
	else if (convar == ConVar_GuessingTime)
	{
		g_flGuessingTime = StringToFloat(newValue);
	}
	
	else if (convar == ConVar_DelayForFullCredits)
	{
		g_flDelayForFullCredits = StringToFloat(newValue);
	}
	
	else if (convar == ConVar_CreditsFastPercentage)
	{
		g_iCreditsFastPercentage = StringToInt(newValue);
	}
	
	else if (convar == ConVar_DelayBetween)
	{
		g_flDelayBetween = StringToFloat(newValue);
	}
	
	else if (convar == ConVar_MinPlayers)
	{
		g_iMinPlayers = StringToInt(newValue);
		CheckPlayers();
	}
	
	//PrintToServer("%s %s", newValue, oldValue);
}

bool CheckPlayers()
{
	int iPlayers[MAXPLAYERS], iCount;
	iCount = GetPlayers(iPlayers, GP_Flag_NoBots, GP_Team_First | GP_Team_Second);
	
	if (iCount >= g_iMinPlayers)
	{
		return true;
	}
	
	return false;
}


stock IsStringNumber(String:szString[], iLen)
{
	TrimString(szString);
	new i;
	if(szString[i] != '-')
	{
		if(!IsCharNumeric(szString[i]))
		{
			return 0;
		}
	}
	
	else i = 1;
	
	for(; i < iLen; i++)
	{
		if(szString[i] == 0)
		{
			break;
		}
		
		if(!IsCharNumeric(szString[i]))
		{
			return 0;
		}
	}
	
	return 1;
}
