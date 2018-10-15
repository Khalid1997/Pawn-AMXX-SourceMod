#include "soccerjam/tools/cycles.sp"
#include "soccerjam/tools/func_caller.sp"

void GivePlayerWeapon(int client)
{
	Client_RemoveAllWeapons(client);
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
	GivePlayerItem(client, "weapon_knife");
}

void PrintSJMessageAll(char[] text, any ...)
{
	char message[100];
	VFormat(message, sizeof(message), text, 2);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrintSJMessage(i, message);
		}
	}
}

void PrintSJMessage(int client, char[] text, any ...)
{
	char message[100];
	VFormat(message, sizeof(message), text, 3);
	PrintToChat(client, "\x01\x0B\x04[\x03SJ\x04] \x03%s", message);
}

int GetClientOpponentSJTeam(int client)
{
	int team = GetClientTeam(client);
	switch (team)
	{
		case CS_TEAM_CT:
		{
			return CS_TEAM_T;
		}
		case CS_TEAM_T:
		{
			return CS_TEAM_CT;
		}
	}
	return CS_TEAM_NONE;
}

void SJ_IncreaseTeamScore(int team)
{
	TeamScore[team]++;
	SJ_UpdateTeamScores();
}

void SJ_UpdateTeamScores()
{
	CS_SetTeamScore(CS_TEAM_T, TeamScore[CS_TEAM_T]);
	SetTeamScore(CS_TEAM_T, TeamScore[CS_TEAM_T]);
	CS_SetTeamScore(CS_TEAM_CT, TeamScore[CS_TEAM_CT]);
	SetTeamScore(CS_TEAM_CT, TeamScore[CS_TEAM_CT]);
}

void SJ_ResetTeamScores()
{
	TeamScore[CS_TEAM_T] = 0;
	TeamScore[CS_TEAM_CT] = 0;
	SJ_UpdateTeamScores();
}

void MapFunctionPrefix(Function &func, char[] prefix, const char[] funcName)
{
	char realFunctionName[MAX_FUNCTION_NAME_LENGTH]
	Format(realFunctionName, sizeof(realFunctionName), "%s_%s", prefix, funcName)
	func = GetFunctionByName(INVALID_HANDLE, realFunctionName)
}

bool GetChance(float percent)
{
	float random = GetRandomFloat(1.0, 100.0);
	return percent >= random;
}