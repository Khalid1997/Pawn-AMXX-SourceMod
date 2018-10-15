#include <sourcemod>
#include <multicolors>
#include <clientprefs>
#include <jail_shop>

#pragma semicolon 1
//#pragma newdecls required

#define QUIZ_PLUGIN_NAME "[Store] Chat Quizzes"
#define QUIZ_PLUGIN_AUTHOR "cam"
#define QUIZ_PLUGIN_DESCRIPTION "Interactive quizzes in chat for [Store] rewards."
#define QUIZ_PLUGIN_VERSION "dev0.1"


#define QUIZ_NULL_ANSWER -20010000
#define QUIZ_NULL_REWARD 0

public Plugin ChatQuiz = {
    name        = QUIZ_PLUGIN_NAME,
    author      = QUIZ_PLUGIN_AUTHOR,
    description = QUIZ_PLUGIN_DESCRIPTION,
    version     = QUIZ_PLUGIN_VERSION,
    url         = "http://strafeodyssey.com"
}

int g_iLastWinner;
int g_iCurrentAnswer = QUIZ_NULL_ANSWER;
int g_iCurrentReward = QUIZ_NULL_REWARD;

char g_sCurrencyName[64] = "Credits";

float g_Settings_fQuestionInterval;
float g_Settings_fQuestionExpire;
float g_Settings_fQuestionWarning;

int g_Settings_iMathNumber_Low;
int g_Settings_iMathNumber_High;

int g_Settings_iGenerateCredits_Low;
int g_Settings_iGenerateCredits_High;

int g_Settings_iGenerateCredits_Rare;
int g_Settings_iGenerateCredits_Rare_Low;
int g_Settings_iGenerateCredits_Rare_High;

int g_Settings_iRequiredPlayers;

bool g_Settings_bStats_Enabled;

//int g_iHistoryQuestionCount;

int g_Stats_CurrentStreak[MAXPLAYERS+1] = {0, ...};

int g_Stats_BestStreak[MAXPLAYERS+1] = {0, ...};
int g_Stats_TotalAnswered[MAXPLAYERS+1] = {0, ...};

Handle g_hCookie_TotalAnswered; 
Handle g_hCookie_BestStreak;

enum {
	QUIZ_TYPE_ADDITION,
	QUIZ_TYPE_SUBTRACTION
}

public void OnPluginStart()
{
	LoadTranslations("store.quizzes.phrases");

	CreateConVar("store_chat_quizzes_version", QUIZ_PLUGIN_VERSION, "Current version of chat quizzes ([Store] module).", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	g_hCookie_TotalAnswered = RegClientCookie("QUIZ_TOTAL_ANSWERED", "Total Answered quizes", CookieAccess_Protected);
	g_hCookie_BestStreak = RegClientCookie("QUIZ_BEST_STREAK", "Client's best answered steak", CookieAccess_Protected);
	
	LoadConfig();
}

void LoadConfig()
{
	Handle kv = CreateKeyValues("root");
	
	char Config_Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/store/quizzes.cfg");
	
	if(!FileToKeyValues(kv, Config_Path)){
		CloseHandle(kv);
		SetFailState("Can't read from configuration file: %s", Config_Path);
	}
	
	g_Settings_fQuestionInterval 			= KvGetFloat(kv, "question_interval", 90.0);
	g_Settings_fQuestionWarning				= KvGetFloat(kv, "question_warning", 10.0);
	
	g_Settings_fQuestionExpire				= KvGetFloat(kv, "question_expire_delay", 30.0);
	
	g_Settings_iGenerateCredits_Low			= KvGetNum(kv, "reward_generate_low", 5);
	g_Settings_iGenerateCredits_High 		= KvGetNum(kv, "reward_generate_high", 20);
	
	g_Settings_iGenerateCredits_Rare 		= KvGetNum(kv, "reward_generate_rare", 5);
	g_Settings_iGenerateCredits_Rare_Low	= KvGetNum(kv, "reward_generate_rare_low", 25);
	g_Settings_iGenerateCredits_Rare_High	= KvGetNum(kv, "reward_generate_rare_high", 150);
	
	g_Settings_iRequiredPlayers				= KvGetNum(kv, "minimum_players", 10);

	if(KvJumpToKey(kv, "category_math")){
		g_Settings_iMathNumber_Low 		= KvGetNum(kv, "question_variable_low", -100);
		g_Settings_iMathNumber_High 	= KvGetNum(kv, "question_variable_high", 150);
		
		KvGoBack(kv);
	}
	
	//if(KvJumpToKey(kv, "category_history")){
	//	while (KvGotoNextKey(kv)){
	//		
	//	
	//	}
	//	
	//	KvGoBack(kv);
	//}
	
	
	if(KvJumpToKey(kv, "stats")){
		char chatcommands[64];
	
		g_Settings_bStats_Enabled		= view_as<bool>(KvGetNum(kv, "stats_enabled", 1));
		
		KvGetString(kv, "stats_chatcommand_me", chatcommands, sizeof(chatcommands), "!quizstats /quizstats");
		RegisterChatCommands(chatcommands, Command_QuizStats);
		
		//KvGetString(kv, "stats_chatcommand_top", chatcommands, sizeof(chatcommands), "!quiztop /quiztop");
		//RegisterChatCommands(chatcommands, Command_QuizTop);
	}
	
	CloseHandle(kv);
}

void RegisterChatCommands(char[] chatcommands, ConCmd:iCallBack)
{
	int iChatCommandCount = CountStringParts(chatcommands, " ", true);
	
	new String:szActualCommands[iChatCommandCount][32];
	ExplodeString(chatcommands, " ", szActualCommands, iChatCommandCount, 32, true);
	
	for (new i, String:szConsoleCmd[32]; i < iChatCommandCount; i++)
	{
		ReplaceString(szActualCommands[i], 32, "!", "");
		ReplaceString(szActualCommands[i], 32, "/", "");
		FormatEx(szConsoleCmd, sizeof szConsoleCmd, "sm_%s", szActualCommands[i]);
		
		RegConsoleCmd(szConsoleCmd, iCallBack, "Hi");
	}
}

stock int CountStringParts(const String:szString[], String:szSplitTocken[], bool bCountRemainder = false)
{
	int iC, iPos, iLen;
	
	while( (iPos = StrContains(szString[iLen], szSplitTocken, false) ) != -1)
	{
		iLen += iPos + 1;	// Move to the next index (char) after the match.
		iC++;
	}
	
	return bCountRemainder ? iC + 1 : iC;
}

/*
public int Store_OnDatabaseInitialized(){
	Store_RegisterPluginModule(QUIZ_PLUGIN_NAME, QUIZ_PLUGIN_DESCRIPTION, "store_chat_quizzes_version", STORE_VERSION);
}*/

public void OnMapStart()
{
	g_iCurrentAnswer = QUIZ_NULL_ANSWER;

	CreateTimer(g_Settings_fQuestionInterval, Timer_AskQuestions, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	//Store_GetCurrencyName(g_sCurrencyName, sizeof(g_sCurrencyName));
}
/*
public void OnClientAuthorized(int client, const char[] sAuth)
{
	if(g_Settings_bStats_Enabled == true){
		if(!IsFakeClient(client))
			RetrievePlayerData(client);
	}
}
*/

public OnClientCookiesCached(client)
{
	if(g_Settings_bStats_Enabled == true)
	{
		if(!IsFakeClient(client))
			RetrievePlayerData(client);
	}
}

public Action Timer_AskQuestions(Handle timer)
{
	if(ShouldDoQuizzes())
	{
		int RandomNumber_1 = GetRandomInt(g_Settings_iMathNumber_Low, g_Settings_iMathNumber_High);
		int RandomNumber_2 = GetRandomInt(g_Settings_iMathNumber_Low, g_Settings_iMathNumber_High);
		
		g_iCurrentReward = GenerateCreditsReward();
		
		switch(GetRandomInt(QUIZ_TYPE_ADDITION, QUIZ_TYPE_SUBTRACTION))
		{
			case QUIZ_TYPE_ADDITION:
			{
				// Addition
				g_iCurrentAnswer = (RandomNumber_1) + (RandomNumber_2);
				
				CPrintToChatAll("%t%t", "Quiz Tag Colored", "Math 2 Variable Question", RandomNumber_1, "+", RandomNumber_2);
			}
			case QUIZ_TYPE_SUBTRACTION:
			{
				// Subtraction
				g_iCurrentAnswer = (RandomNumber_1) - (RandomNumber_2);
				
				CPrintToChatAll("%t%t", "Quiz Tag Colored", "Math 2 Variable Question", RandomNumber_1, "-", RandomNumber_2);
			}
		}
		
		if(g_Settings_fQuestionExpire > 0.0){
			CreateTimer(g_Settings_fQuestionExpire, Timer_AskQuestions_Expire);
		}
		
		CreateTimer(g_Settings_fQuestionInterval - g_Settings_fQuestionWarning, Timer_AskQuestions_Warning);
	}
	else
	{
		g_iCurrentAnswer = QUIZ_NULL_ANSWER;
		CPrintToChatAll("%t%t", "Quiz Tag Colored", "Players Not Met", GetPlayerCount(), g_Settings_iRequiredPlayers);
	}
}

public Action Timer_AskQuestions_Expire(Handle timer)
{
	if(g_iCurrentAnswer != QUIZ_NULL_ANSWER)
	{
		CPrintToChatAll("%t%t", "Quiz Tag Colored", "Answer Expired Int", g_iCurrentAnswer);
		g_iCurrentAnswer = QUIZ_NULL_ANSWER;
	}
}

public Action Timer_AskQuestions_Warning(Handle timer)
{
	if(ShouldDoQuizzes())
	{
		if(g_iLastWinner != 0 && IsClientInGame(g_iLastWinner)){
			char g_iLastWinnerName[32];
			GetClientName(g_iLastWinner, g_iLastWinnerName, sizeof(g_iLastWinnerName));
			
			CPrintToChatAll("%t%t", "Quiz Tag Colored", "Question Warning Winner", RoundToFloor(g_Settings_fQuestionWarning), g_iLastWinnerName);
		}
		else
		{
			CPrintToChatAll("%t%t", "Quiz Tag Colored", "Question Warning No Winner", RoundToFloor(g_Settings_fQuestionWarning));
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) 
{
	if(ShouldDoQuizzes() && (g_iCurrentAnswer != QUIZ_NULL_ANSWER) && (g_iCurrentReward != QUIZ_NULL_REWARD))
	{
		int AttemptedAnswer = StringToInt(args[0]);
		
		if(g_iCurrentAnswer == AttemptedAnswer)
		{	
			char clientname[32];
			GetClientName(client, clientname, sizeof(clientname));
			
			CPrintToChatAll("%t%t", "Quiz Tag Colored", "Question Answered All", clientname, g_iCurrentAnswer, g_iCurrentReward, g_sCurrencyName);
			
			// start stats block
			if(g_Settings_bStats_Enabled == true)
			{
				g_Stats_TotalAnswered[client]++;
				
				for(int i = 1; i <= MaxClients; i++){
					if(i != client){
						if(IsClientConnected(i) && IsClientInGame(i)){
							g_Stats_CurrentStreak[i] = 0;
						}
					}
				}
				
				g_Stats_CurrentStreak[client]++;
				
				if(g_Stats_CurrentStreak[client] > g_Stats_BestStreak[client]){
					g_Stats_BestStreak[client] = g_Stats_CurrentStreak[client];
					
					CPrintToChat(client, "%t%t", "Quiz Tag Colored", "Stats New Streak", g_Stats_BestStreak[client]);
				}
				CPrintToChat(client, "%t%t", "Quiz Tag Colored", "Question Answered Reward", g_iCurrentReward, g_sCurrencyName, g_Stats_CurrentStreak[client]);
				
				UpdatePlayerData(client);
			}
			// end stats block
			
			g_iCurrentAnswer = QUIZ_NULL_ANSWER;
			g_iLastWinner = client;
			
			JBShop_SetCredits(client, JBShop_GetCredits(client) + g_iCurrentReward);
		}
	}
}

stock int GenerateCreditsReward()
{
	int GenerateCreditsLow 	= g_Settings_iGenerateCredits_Low;
	int GenerateCreditsHigh = g_Settings_iGenerateCredits_High;
	
	if(GetRandomInt(0, 100) <= g_Settings_iGenerateCredits_Rare)
	{
		CPrintToChatAll("%t", "Rare Reward Notification");
		GenerateCreditsLow 	= g_Settings_iGenerateCredits_Rare_Low;
		GenerateCreditsHigh = g_Settings_iGenerateCredits_Rare_High;
	}
	
	return GetRandomInt(GenerateCreditsLow, GenerateCreditsHigh);
}

stock bool ShouldDoQuizzes()
{
	if(GetPlayerCount() >= g_Settings_iRequiredPlayers)
		return true;
	else
		return false;
}

stock int GetPlayerCount(int Team = QUIZ_NULL_ANSWER)
{
	int PlayersNum = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsFakeClient(i)){
			if(Team == QUIZ_NULL_ANSWER)
			{
				if(GetClientTeam(i) != 0) // CS_TEAM_NONE
					PlayersNum++;
			}
			else
			{
				if(GetClientTeam(i) == Team)
					PlayersNum++;
			}
		}
	}
	
	return (PlayersNum != 0) ? PlayersNum : -1;
}

void RetrievePlayerData(int client)
{	
	new String:szCookie[12];
	
	GetClientCookie(client, g_hCookie_TotalAnswered, szCookie, sizeof szCookie);
	g_Stats_TotalAnswered[client] = StringToInt(szCookie);
	
	GetClientCookie(client, g_hCookie_BestStreak, szCookie, sizeof szCookie);
	g_Stats_BestStreak[client] = StringToInt(szCookie);
	
	g_Stats_CurrentStreak[client] = 0;
	
	/*
	int accountId = GetSteamAccountID(client);
	
	char query[255];
	Format(query, sizeof(query), "SELECT total_answered, best_streak FROM store_quizstats WHERE auth = '%i';", accountId);

	Store_SQLTQuery(RetrievePlayerData_Callback, query, client, DBPrio_High);
	*/
}

void UpdatePlayerData(int client)
{
	new String:szCookie[12];
	
	FormatEx(szCookie, sizeof szCookie, "%d", g_Stats_TotalAnswered[client]);
	SetClientCookie(client, g_hCookie_TotalAnswered, szCookie);
	
	FormatEx(szCookie, sizeof szCookie, "%d", g_Stats_BestStreak[client]);
	SetClientCookie(client, g_hCookie_BestStreak, szCookie);
}
/*

public void RetrievePlayerData_Callback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		Store_LogError("SQL Error on Quiz-Stats Retrieval: %s", error);
	}
	
	if (SQL_FetchRow(hndl))
	{
		g_Stats_TotalAnswered[client] = SQL_FetchInt(hndl, 0);
		g_Stats_BestStreak[client] = SQL_FetchInt(hndl, 1);
		g_Stats_CurrentStreak[client] = 0;
	}
	else
	{
		//PrintToServer("Creating data for client's first connection");
		CreatePlayerData(client);
	}
} 

void CreatePlayerData(int client)
{
	int accountId = GetSteamAccountID(client);

	char query[255];
	Format(query, sizeof(query), "INSERT INTO store_quizstats (auth, name, total_answered, best_streak) VALUES ('%i', 'none', '0', '0');", accountId);
	
	//PrintToServer(query);
	
	Store_SQLTQuery(CreatePlayerData_Callback, query, client, DBPrio_High);
}

public void CreatePlayerData_Callback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		Store_LogError("SQL Error on Quiz-Stats Registration: %s", error);
	}

	g_Stats_TotalAnswered[client] = 0;
	g_Stats_BestStreak[client] = 0;
	g_Stats_CurrentStreak[client] = 0;
}

void UpdatePlayerData(int client)
{
	int accountId = GetSteamAccountID(client);
	
	char query[255];
	Format(query, sizeof(query), "UPDATE store_quizstats SET total_answered = '%i', best_streak = '%i' WHERE auth = '%i';", 
		g_Stats_TotalAnswered[client], g_Stats_BestStreak[client], accountId);
	
	Store_SQLTQuery(UpdatePlayerData_Callback, query, client, DBPrio_High);
}

public void UpdatePlayerData_Callback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		Store_LogError("SQL Error on Quiz-Stats Update: %s", error);
	}
} */

public Action Command_QuizStats(int client, int iArgs){
	if(g_Stats_TotalAnswered[client] > 0){
		CPrintToChat(client, "%t (%N)", "Stats Title", client);
		CPrintToChat(client, "-- %t: %i", "Stats Total", g_Stats_TotalAnswered[client]);
		CPrintToChat(client, "-- %t: %i", "Stats Best Streak", g_Stats_BestStreak[client]);
		CPrintToChat(client, "-- %t: %i", "Stats Current Streak", g_Stats_CurrentStreak[client]);
	}
	else
	{
		CPrintToChat(client, "%t%t", "Quiz Tag Colored", "Stats Unranked");
	}
}

/*
public Action Command_QuizTop(int client, iArgs){
	Store_SQLTQuery(Command_QuizTop_Callback, "SELECT store_quizstats.auth, store_users.name, store_quizstats.total_answered, store_quizstats.best_streak FROM store_quizstats, store_users WHERE store_users.auth = store_quizstats.auth ORDER BY total_answered DESC LIMIT 0, 25;", client, DBPrio_High);
}

public void Command_QuizTop_Callback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		Store_LogError("SQL Error on Quiz-Stats Top Selection: %s", error);
	}
	
	Menu QuizTop_Menu = CreateMenu(Command_QuizTop_MenuHandler);
	
	QuizTop_Menu.SetTitle("%t", "Stats Top Menu Title");
	
	int rank = 1;
	
	while(SQL_FetchRow(hndl) && !SQL_IsFieldNull(hndl, 0)){
		char name[32];
		
		SQL_FetchString(hndl, 1, name, sizeof(name));
		
		int total_answered	= SQL_FetchInt(hndl, 2);
		int best_streak		= SQL_FetchInt(hndl, 3);
		
		if(total_answered > 0){
			char menuLine[64];
			Format(menuLine, sizeof(menuLine), "(T: %i; S: %i) %s", total_answered, best_streak, name);
			
			QuizTop_Menu.AddItem(menuLine, menuLine, ITEMDRAW_DISABLED);
			rank++;
		}
	}
	
	if(rank > 1){
		QuizTop_Menu.Display(client, MENU_TIME_FOREVER);
	}else{
		CPrintToChat(client, "%t%t", "Quiz Tag Colored", "Stats No Data");
		CloseHandle(QuizTop_Menu);
	}
}

public int Command_QuizTop_MenuHandler(Handle hndl, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(hndl);
}*/