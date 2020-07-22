#include <sourcemod>
#include <cstrike>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <ctban>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =  {
	name = "Team Join Managment", 
	author = "Khalid", 
	description = "", 
	version = "2.0", 
	url = ""
}

ConVar ConVar_JoinTeamMode, 
ConVar_BlockChangeTeam, 
ConVar_BlockChangeTeamAllowForRatio, 
ConVar_ApplyTeamChangeFix, 
ConVar_MP_LimitTeams, 
ConVar_AutoJoin, 
ConVar_Ratio;

int g_iJoinTeamMode, 
g_iLimitTeams, 
g_iBlockChangeMode, 
g_iRatioT, 
g_iRatioCT;

bool g_bApplyTeamChangeFix, 
g_bAutoJoin, 
g_bRatioModeEnabled, 
g_bBlockChangeTeamAllowForRatio;

#define TEAM_DEFAULT CS_TEAM_CT

#define JoinMode_Balance		0
#define JoinMode_Terrorist		1
#define JoinMode_CT				2
#define JoinMode_Spec			3

#define BlockMode_None		0
#define BlockMode_NoSpec	1
#define BlockMode_All		2

#define RoundFloatCT	RoundToCeil
#define RoundFloatT		RoundToFloor

#define BypassFlag_Block	(1<<0)
#define BypassFlag_Ratio	(1<<1)
#define BypassFlag_All		(BypassFlag_Block | BypassFlag_Ratio)

KeyValues g_hKv = null;
char g_szKeyValuesFile[] = "addons/sourcemod/configs/tjm_bypass.ini";
int g_iBypassFlags[MAXPLAYERS];
int g_iBypass_AdminFlags, g_iBypass_AdminBypassFlags;

#define Key_Admin			"admin"
#define Key_AdminFlags		"admin_flags"
#define Key_BypassFlags 	"bypass_flags"
#define Key_Name			"reference_name"

bool g_bCTBanPlugin = false;
bool g_bLate = false;

/*
"TJM_Bypass"
{
	"admin"
	{
		"adminflags"	""
		"bypassflags"	""
	}
	
	"SteamID"
	{
		"reference_name"	"Name"
		"bypassflags"		""
	}
}
*/

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int errmax)
{
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookConVarChange((ConVar_MP_LimitTeams = FindConVar("mp_limitteams")), ConVarChange_Plugin);
	HookConVarChange((ConVar_JoinTeamMode = CreateConVar("tjm_mode", "0", ", 0 = Balance, 1 = Join T, 2 = Join CT, 3 = Spectators")), ConVarChange_Plugin);
	HookConVarChange((ConVar_AutoJoin = CreateConVar("tjm_autojointeam_onconnect", "1", "0 = Disabled, 1 = Enabled")), ConVarChange_Plugin);
	HookConVarChange((ConVar_BlockChangeTeam = CreateConVar("tjm_blockteamchange", "0", "0 = Don't block, 1 = Block except from spec, 2 = Block all")), ConVarChange_Plugin);
	HookConVarChange((ConVar_BlockChangeTeamAllowForRatio = CreateConVar("tjm_blockteamchange_allowratiobalance", "0", 
				"Allow players to swtich in order to balance teams based on ratio\n\
		regardless of block type.\n0 = Disable, 1 = Enable")), ConVarChange_Plugin);
	HookConVarChange((ConVar_ApplyTeamChangeFix = CreateConVar("tjm_apply_teamchange_fix", "1", "0 = Don't Apply, 1 = Apply")), ConVarChange_Plugin);
	HookConVarChange((ConVar_Ratio = CreateConVar("tjm_ratio", "0", "T:CT ratio or 0 to disable Ex. (3:1)")), ConVarChange_Plugin);
	
	g_iJoinTeamMode = ConVar_JoinTeamMode.IntValue;
	g_iBlockChangeMode = ConVar_BlockChangeTeam.IntValue;
	g_bApplyTeamChangeFix = view_as<bool>(!!(ConVar_ApplyTeamChangeFix.IntValue));
	g_iLimitTeams = ConVar_MP_LimitTeams.IntValue;
	g_bAutoJoin = ConVar_AutoJoin.BoolValue;
	char szValue[10];
	GetConVarString(ConVar_Ratio, szValue, sizeof szValue);
	ConVarChange_Plugin(ConVar_Ratio, "0", szValue); // Initial Value of this shit
	g_bBlockChangeTeamAllowForRatio = ConVar_BlockChangeTeamAllowForRatio.BoolValue;
	
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	HookEvent("player_connect_full", Event_OnFullConnect, EventHookMode_Post);
	
	HookEvent("round_prestart", Event_RoundEnd, EventHookMode_Post);
	
	RegAdminCmd("sm_tjm_bypass", AdmCmd_AddBypasser, ADMFLAG_ROOT, "<name/steamid> <(new)bypassflags/remove> - Bypassflags: 1: Block, 2: Ratio");
	RegAdminCmd("sm_tjm_bypassreload", AdmCmd_BypassReload, ADMFLAG_ROOT);
	
	AutoExecConfig(true, "teamjoinmanagement");
	
	ReadKeyValues();
}

public void OnConfigsExecuted()
{
	//PrintToChatAll("Executed");
}

public void OnAllPluginsLoaded()
{
	g_bCTBanPlugin = LibraryExists("ctban");
}

public void OnLibraryAdded(const char[] szLib)
{
	if(StrEqual(szLib, "ctban"))
	{
		g_bCTBanPlugin = true;
	}	
}

public void OnLibraryRemoved(const char[] szLib)
{
	if(StrEqual(szLib, "ctban"))
	{
		g_bCTBanPlugin = false;
	}	
}

public Action AdmCmd_BypassReload(int client, int iArgs)
{
	ReadKeyValues();
	
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
	
	ReplyToCommand(client, "[TJM] Reloaded file.");
}

public Action AdmCmd_AddBypasser(int client, int iArgs)
{
	char szPattern[35], szFlags[10];
	GetCmdArg(1, szPattern, sizeof szPattern);
	GetCmdArg(2, szFlags, sizeof szFlags);
	
	int iFlags = StringToInt(szFlags);
	if(iFlags > BypassFlag_All)
	{
		iFlags = BypassFlag_All;
	}
	
	int iCount, iTargets[MAXPLAYERS];
	char szTargetName[MAX_NAME_LENGTH];
	bool bIsML;
	
	iCount = ProcessTargetString(szPattern, 0, iTargets, sizeof iTargets, COMMAND_FILTER_NO_BOTS, szTargetName, sizeof szTargetName, bIsML);
	int iTarget = -1;
	
	char szAuthId[35];
	
	if (iCount == 1)
	{
		iTarget = iTargets[0];
		GetClientAuthId(iTarget, AuthId_Steam2, szAuthId, sizeof szAuthId);
		ReplyToCommand(client, "[TJM] Found player %s with SteamID '%s'", szTargetName, szAuthId);
	}
	
	else
	{
		if (StrContains(szPattern, "STEAM_") == -1)
		{
			ReplyToCommand(client, "[TJM] Couldn't find client with pattern '%s'", szPattern);
			return Plugin_Handled;
		}
		
		strcopy(szAuthId, sizeof szAuthId, szPattern);
	}
	
	if (StrContains(szFlags, "remove", false) != -1)
	{
		if (KvJumpToKey(g_hKv, szAuthId, false))
		{
			do
			{
				KvDeleteThis(g_hKv);
			}
			while (KvGotoNextKey(g_hKv, true));
				
			KvGoBack(g_hKv);
			ReplyToCommand(client, "[TJM] Player %s Bypass privilage. Removing", szAuthId);
			//PrintToServer("%d %d", KvNodesInStack(g_hKv));
			//KvSetString(g_hKv, szAuthId, "");
			
			KeyValuesToFile(g_hKv, g_szKeyValuesFile);
			
			if (iTarget)
			{
				g_iBypassFlags[iTarget] = 0;
			}
			return Plugin_Handled;
		}
		
		else
		{
			ReplyToCommand(client, "[TJM] Couldn't find entry for '%s' to remove", szAuthId);
			return Plugin_Handled;
		}
	}
	
	if (!KvJumpToKey(g_hKv, szAuthId, false))
	{
		ReplyToCommand(client, "[TJM] Couldn't find entry for '%s' to adjust. Creating a new one.", szAuthId);
		KvJumpToKey(g_hKv, szAuthId, true);
	}
	
	else
	{
		if(!szFlags[0])
		{
			//KvGotoFirstSubKey(g_hKv, true);
			ReplyToCommand(client, "[TJM] Player '%s' has flags %d", szAuthId, KvGetNum(g_hKv, Key_BypassFlags));
			KvGoBack(g_hKv);
			
			return Plugin_Handled;
		}
	}
	
	ReplyToCommand(client, "[TJM] Replaced flags for '%s' with '%d'", szAuthId, iFlags);
	KvSetNum(g_hKv, Key_BypassFlags, iFlags);
	KvSetString(g_hKv, Key_Name, szTargetName);
	KvGoBack(g_hKv);
	
	KeyValuesToFile(g_hKv, g_szKeyValuesFile);
	
	if (iTarget > 0)
	{
		g_iBypassFlags[iTarget] = iFlags;
	}
	
	else
	{
		iTarget = FindTarget(0, szAuthId, false, false);
		if(iTarget != -1)
		{
			g_iBypassFlags[iTarget] = iFlags;
		}
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	KeyValuesToFile(g_hKv, g_szKeyValuesFile);
	//PrintToServer("OnMapStart Called");
	//ReadKeyValues();
	
	if(g_bLate)
	{
		g_bLate = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				
				OnClientPostAdminCheck(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	if (g_hKv != null)
	{
		KeyValuesToFile(g_hKv, g_szKeyValuesFile);
	}
	
	delete g_hKv;
}

public void OnClientPostAdminCheck(int client)
{
	//PrintToServer("Doing Client %d", client);
	
	g_iBypassFlags[client] = 0;
	
	char szAuthId[35];
	GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof szAuthId);
	int iFlagsBit = GetUserFlagBits(client);
	
	//PrintToServer("#1");
	if (KvJumpToKey(g_hKv, szAuthId, false))
	{
		//PrintToServer("#1.1");
		g_iBypassFlags[client] = KvGetNum(g_hKv, Key_BypassFlags);
		KvGoBack(g_hKv);
	}
	
	else if (iFlagsBit & ADMFLAG_ROOT)
	{
		//PrintToServer("#1.2 Done");
		// Give roots full access
		g_iBypassFlags[client] = BypassFlag_All;
	}
	
	else if (iFlagsBit & g_iBypass_AdminFlags)
	{
		//PrintToServer("#1.3");
		g_iBypassFlags[client] = g_iBypass_AdminBypassFlags;
	}
	
	//PrintToServer("Client %N (%d) flags %d", client, client, g_iBypassFlags[client]);
}

public void Event_RoundEnd(Event event, char[] szEventName, bool bDontBroadcast)
{
	if (!g_bRatioModeEnabled)
	{
		PrintToChatAll("Ratio Mode Disabled");
		return;
	}
	
	//PrintToServer("RoundPrestart ok");
	Event_RoundEnd_NextFrame(0);
	//PrintToServer("RoundPrestart end");
	//RequestFrame(Event_RoundEnd_NextFrame, 0);
}

public void Event_RoundEnd_NextFrame(any data)
{	
	if (!g_bRatioModeEnabled)
	{
		//PrintToChatAll("Ratio Mode Disabled");
		return;
	}
	
	int numCT, numT;
	int indexCT[MAXPLAYERS], indexT[MAXPLAYERS];
	GetTeamsPlayersCount(numCT, numT, indexCT, indexT);
	int numTotal = numCT + numT;
	
	int arraylistSize;
	ArrayList aPlayers;
	arraylistSize = numT;
	
	int maxNum = RoundFloatCT(float(numTotal) * floatRatio(g_iRatioCT, g_iRatioCT + g_iRatioT));
	//PrintToChatAll("maxNum : %d", maxNum);

	//PrintToServer("%0.2f .. %0.2f", floatRatio(g_iRatioCT, g_iRatioCT + g_iRatioT), float(numTotal) * floatRatio(g_iRatioCT, g_iRatioCT + g_iRatioT));
	//PrintToServer("MaxNum %d numCT %d", maxNum, numCT);
	
	// -------
	// Guarantee that there is one in the other team
	if(maxNum == numTotal)
	{
		maxNum -= 1;
	}
	
	else if(!maxNum)
	{
		maxNum = 1;
	}
	// -------
	
	int client;
	int iPos;
	
	if (numCT < maxNum)
	{
		aPlayers = ArrayToArrayList(indexT, numT);
		arraylistSize = numT;
		while (numCT < maxNum && arraylistSize > 0)
		{
			client = aPlayers.Get((iPos = GetRandomInt(0, arraylistSize - 1)));
			aPlayers.Erase(iPos);
			--arraylistSize;
			
			if (g_iBypassFlags[client] & BypassFlag_Ratio)
			{
				//PrintToChatAll("Bypass Ratio1.. %N", client);
				continue;
			}
			
			if(g_bCTBanPlugin && CTBan_IsClientBanned(client))
			{
				PrintToChat(client, "[TJM] * You were selected to be Transfered to CT but you are banned from CT. Reverting.");
				continue;
			}
			
			indexCT[++numCT] = client;
			
			// Change the Team
			ChangeClientTeam(client, CS_TEAM_CT);
			PrintToChat(client, "[TJM] * You have been moved to Counter-Terrorists team.");
		}
		delete aPlayers;
	}
	
	else if(numCT > maxNum)
	{
		aPlayers = ArrayToArrayList(indexCT, numCT);
		arraylistSize = numCT;
		while (numCT > maxNum && arraylistSize > 0)
		{
			client = aPlayers.Get((iPos = GetRandomInt(0, arraylistSize - 1)));
			aPlayers.Erase(iPos);
			--arraylistSize;
			
			if (g_iBypassFlags[client] & BypassFlag_Ratio)
			{
				//PrintToServer("Bypass Ratio2.. %N", client);
				continue;
			}
			
			--numCT;
			// Change the Team
			ChangeClientTeam(client, CS_TEAM_T);
			PrintToChat(client, "[TJM] * You have been moved to Terrorists team.");
		}
		
		delete aPlayers;
	}
}

stock ArrayList ArrayToArrayList(int[] iArray, int size)
{
	ArrayList list = new ArrayList(1);
	for (int i; i < size; i++)
	{
		list.Push(iArray[i]);
	}
	return list;
}

public void ConVarChange_Plugin(ConVar convar, char[] szOldValue, char[] szNewValue)
{
	//PrintToChatAll("CONVAR CHANGE %s %s", szOldValue, szNewValue);
	char ConVarName[32];
	convar.GetName(ConVarName, sizeof ConVarName);
	//PrintToServer("***** ConVar %s: '%s' '%s'", ConVarName, szNewValue, szOldValue);
	
	if (convar == ConVar_JoinTeamMode)
	{
		g_iJoinTeamMode = StringToInt(szNewValue);
	}
	
	else if (convar == ConVar_BlockChangeTeam)
	{
		g_iBlockChangeMode = StringToInt(szNewValue);
	}
	
	else if (convar == ConVar_ApplyTeamChangeFix)
	{
		g_bApplyTeamChangeFix = view_as<bool>(!!StringToInt(szNewValue));
	}
	
	else if (convar == ConVar_MP_LimitTeams)
	{
		g_iLimitTeams = StringToInt(szNewValue);
		
		char szString[10];
		ConVar_Ratio.GetString(szString, sizeof szString);
		ConVarChange_Plugin(ConVar_Ratio, "", szString);
	}
	
	else if (convar == ConVar_AutoJoin)
	{
		g_bAutoJoin = view_as<bool>(!!StringToInt(szNewValue));
	}
	
	else if (convar == ConVar_BlockChangeTeamAllowForRatio)
	{
		g_bBlockChangeTeamAllowForRatio = view_as<bool>(!!StringToInt(szNewValue));
	}
	
	else if (convar == ConVar_Ratio)
	{
		int iPos = StrContains(szNewValue, ":");
		if (iPos == -1)
		{
			g_bRatioModeEnabled = false;
			g_iRatioT = 0;
			g_iRatioCT = 0;
			
			//PrintToChatAll("Not???");
			return;
		}
		
		char szPart1[3], szPart2[3];
		FormatEx(szPart1, iPos + 1, szNewValue);
		FormatEx(szPart2, sizeof szPart2, szNewValue[iPos + 1]);
		
		//PrintToChatAll("%s %s", szPart1, szPart2);
		
		if (Custom_IsStringNumber(szPart1))
		{
			g_iRatioT = StringToInt(szPart1);
			if (g_iLimitTeams && g_iRatioT > g_iLimitTeams)
			{
				g_iRatioT = g_iLimitTeams;
			}
		}
		
		if (Custom_IsStringNumber(szPart2))
		{
			g_iRatioCT = StringToInt(szPart2);
			if (g_iLimitTeams && g_iRatioCT > g_iLimitTeams)
			{
				g_iRatioCT = g_iLimitTeams;
			}
		}
		
		if(!g_iRatioCT || !g_iRatioT)
		{
			g_bRatioModeEnabled = false;
		}
		
		else
		{
			g_bRatioModeEnabled = true;
		}
		
		//PrintToServer("%s .-%d-. %s", szPart1, iPos, szPart2);
	}

}

public void Event_OnFullConnect(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bAutoJoin)
	{
		return;
	}
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(0.0, Timer_AssignTeam, client); // Next frame
	}
}

public Action Timer_AssignTeam(Handle timer, int client)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	PutPlayerInTeam(client, FindJoinableTeam());
}

public Action CommandListener_JoinTeam(int client, const char[] command, int args)
{
	if (CheckFloodProtection(client))
	{
		//PrintToConsole(client, "* Flooding");
		return Plugin_Handled;
	}
	
	char szTeam[2];
	GetCmdArg(1, szTeam, sizeof(szTeam));
	int iNewTeam = StringToInt(szTeam);
	
	if (g_iBypassFlags[client] & BypassFlag_Block)
	{
		PrintToChat(client, "[TJM] You have been granted a bypass to freely change the team.");
			
		if (!g_bApplyTeamChangeFix)
		{
			//PrintToServer("Stop No Apply Fix");
			return Plugin_Continue;
		}
		
		// The fix is actually here
		ForcePlayerSuicide(client);
		PutPlayerInTeam(client, iNewTeam);
	
		return Plugin_Handled;
	}
	
	if (!Custom_IsStringNumber(szTeam))
	{
		return Plugin_Continue;
	}
	
	int iCurrentTeam = GetClientTeam(client);
	
	//PrintToServer("Called %s %s", command, szTeam);
	
	if (iNewTeam == iCurrentTeam)
	{
		return Plugin_Continue;
	}
	
	if (!CanChangePlayerTeam(iNewTeam))
	{
		if (g_bRatioModeEnabled && g_bBlockChangeTeamAllowForRatio)
		{
			int numCT, numT;
			GetTeamsPlayersCount(numCT, numT);
			int iTotal = numCT + numT;
			int iRatioNum, iTeamNum;
			int iMax;
			
			// Here we have round to ceil and round to floor to add the extra players to only one team;
			switch (iNewTeam)
			{
				case CS_TEAM_CT:
				{
					iRatioNum = g_iRatioCT;
					iTeamNum = numCT;
					iMax = RoundFloatCT(float(iTotal) * floatRatio(iRatioNum, g_iRatioCT + g_iRatioT));
				}
				
				case CS_TEAM_T:
				{
					iRatioNum = g_iRatioT;
					iTeamNum = numT;
					iMax = RoundFloatT(float(iTotal) * floatRatio(iRatioNum, g_iRatioCT + g_iRatioT));
				}
			}
			
			if (iTeamNum >= iMax)
			{
				//PrintToServer("Stop MAX IS there");
				return Plugin_Handled;
			}
			
			//PrintToServer("ALlow from ratio");
			// Continue;
		}
		
		else
		{
			return Plugin_Handled;
		}
	}
	
	if (!g_bApplyTeamChangeFix)
	{
		//PrintToServer("Stop No Apply Fix");
		return Plugin_Continue;
	}
	
	// The fix is actually here
	ForcePlayerSuicide(client);
	PutPlayerInTeam(client, iNewTeam);
	
	return Plugin_Handled;
}

// Auto join team;
void PutPlayerInTeam(int client, int iTeam)
{
	ChangeClientTeam(client, iTeam);
}

// Change Player Team
// True if player was put in team
// False if not
bool CanChangePlayerTeam(int iNewTeam)
{
	if (g_iBlockChangeMode == BlockMode_All)
	{
		// Cant change no matter what
		return false;
	}
	
	if (g_iBlockChangeMode == BlockMode_None)
	{
		return true;
	}
	
	if (g_iBlockChangeMode == BlockMode_NoSpec)
	{
		if (iNewTeam == CS_TEAM_SPECTATOR)
		{
			return true;
		}
	}
	
	int iForcedTeam;
	switch (g_iJoinTeamMode)
	{
		case JoinMode_Spec:
		{
			iForcedTeam = CS_TEAM_SPECTATOR;
		}
		
		case JoinMode_CT:
		{
			iForcedTeam = CS_TEAM_CT;
		}
		
		case JoinMode_Terrorist:
		{
			iForcedTeam = CS_TEAM_T;
		}
		
		case JoinMode_Balance:
		{
			int numCT, numT;
			GetTeamsPlayersCount(numCT, numT);
			
			if(g_bRatioModeEnabled)
			{
				
			}
			
			int iFirstTeamNum, iSecondTeamNum;
			if (numCT > numT)
			{
				iFirstTeamNum = numCT;
				iSecondTeamNum = numT;
			}
			
			else
			{
				iFirstTeamNum = numT;
				iSecondTeamNum = numCT;
			}
			
			if (g_iLimitTeams && iFirstTeamNum - iSecondTeamNum >= g_iLimitTeams)
			{
				// Do not allow if it is more than the limit
				//PrintToServer("Limits %d", g_iLimitTeams);
				return false;
			}
			
			iForcedTeam = iNewTeam; // Set forced team to the desired team to allow change
		}
	}
	
	if (iForcedTeam != iNewTeam)
	{
		return false;
	}
	
	return true;
}

int FindJoinableTeam()
{
	int iForcedTeam;
	
	switch (g_iJoinTeamMode)
	{
		case JoinMode_Spec:
		{
			iForcedTeam = CS_TEAM_SPECTATOR;
		}
		
		case JoinMode_CT:
		{
			iForcedTeam = CS_TEAM_CT;
		}
		
		case JoinMode_Terrorist:
		{
			iForcedTeam = CS_TEAM_T;
		}
		
		case JoinMode_Balance:
		{
			int numCT, numT;
			GetTeamsPlayersCount(numCT, numT);
			
			int iFirstTeam, iSecondTeam;
			int iFirstTeamNum, iSecondTeamNum;
			
			iFirstTeam = CS_TEAM_CT;
			iSecondTeam = CS_TEAM_T;
			iFirstTeamNum = numCT;
			iSecondTeamNum = numT;
			
			if (iFirstTeamNum > iSecondTeamNum)
			{
				iForcedTeam = iSecondTeam;
			}
			
			// Smaller or equal
			else
			{
				iForcedTeam = iFirstTeam;
			}
		}
	}
	
	return iForcedTeam;
}

void GetTeamsPlayersCount(int &numCT, int &numT, int indexCT[MAXPLAYERS] = 0, int indexT[MAXPLAYERS] = 0)
{
	numCT = 0;
	numT = 0;
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		switch (GetClientTeam(i))
		{
			case CS_TEAM_T:
			{
				indexT[numT++] = i;
			}
			
			case CS_TEAM_CT:
			{
				indexCT[numCT++] = i;
			}
		}
	}
}

stock bool Custom_IsStringNumber(char[] szString)
{
	// Customied for only positive integers
	TrimString(szString);
	
	int i;
	int iLen = strlen(szString);
	
	for (; i < iLen; i++)
	{
		if (!IsCharNumeric(szString[i]))
		{
			return false;
		}
	}
	
	return true;
}

float floatRatio(int iRatioNum, int iTotal)
{
	return float(iRatioNum) / float(iTotal);
}

stock int abs(int Value)
{
	if (Value < 0)
	{
		Value *= -1;
	}
	return Value;
} 

void ReadKeyValues()
{
	if (g_hKv == null)
	{
		g_hKv = CreateKeyValues("TJM_Bypass");
	}
	
	else
	{
		// ReRead
		//PrintToServer("* ReRead");
		FileToKeyValues(g_hKv, g_szKeyValuesFile);
	}
	
	if (!FileToKeyValues(g_hKv, g_szKeyValuesFile))
	{
		//PrintToServer("*** Writing New. 1");
		
		KvJumpToKey(g_hKv, Key_Admin, true);
		{
			KvSetString(g_hKv, Key_AdminFlags, "z");
			g_iBypass_AdminFlags = 0;
			KvSetString(g_hKv, Key_BypassFlags, "3");
			g_iBypass_AdminBypassFlags = BypassFlag_All;
		}
		KvGoBack(g_hKv);
		
		KeyValuesToFile(g_hKv, g_szKeyValuesFile);
	}
	
	else
	{
		//PrintToServer("*** Writing Not.");
		
		char szAdminFlags[25];
		
		KvJumpToKey(g_hKv, Key_Admin, true);
		{
			//KvJumpToKey(g_hKv, Key_AdminFlags, true);
			KvGetString(g_hKv, Key_AdminFlags, szAdminFlags, sizeof szAdminFlags, "");
			g_iBypass_AdminFlags = ReadFlagString(szAdminFlags) | ADMFLAG_ROOT;
			int iBypassFlags;
			iBypassFlags = KvGetNum(g_hKv, Key_BypassFlags, 3);
			g_iBypass_AdminBypassFlags = iBypassFlags > BypassFlag_All ? BypassFlag_All : iBypassFlags;
		}
		KvGoBack(g_hKv);
	}
}

bool CheckFloodProtection(int client)
{
	#define MAX_COMMANDS_PER_TIME_UNIT	5
	#define	UNIT_TIME					5.0
	
	static float flStartTime[MAXPLAYERS];
	static int iCommandsIssued[MAXPLAYERS];

	float flGameTime = GetGameTime();
	if(flGameTime - flStartTime[client] >= UNIT_TIME)
	{
		flStartTime[client] = flGameTime;
		iCommandsIssued[client] = 0;
		
		return false;
	}
	
	if(++iCommandsIssued[client] >= MAX_COMMANDS_PER_TIME_UNIT)
	{
		return true;
	}
	
	return false;
}