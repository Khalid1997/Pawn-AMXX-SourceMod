ConVar InitialCreditsConVar
ConVar ResetUpgradesEnabledConVar
ConVar WarmupUpgradesEnabledConVar

PrivateForward OnClientResetUpgradesForward
PrivateForward OnGetClientUpgradeInfoForward

const int MAX_UPGRADES = 128
const int UPGRADE_NAME_LENGTH = 32
const int UPGRADE_MEAS_NAME_LENGTH = 8
const int INVALID_UPGRADE = -1

int CatchingUpgradeId
int UpgradeMaxLevelSoundId

enum SJUpgradeData
{
	String:SJUpgradeData_Name[UPGRADE_NAME_LENGTH],
	Float:SJUpgradeData_MinValue,
	Float:SJUpgradeData_MaxValue,
	SJUpgradeData_LevelsCount,
	SJUpgradeData_Cost,
	UpgradeFunc:SJUpgradeData_Func,
	String:SJUpgradeData_MeasName[UPGRADE_MEAS_NAME_LENGTH],
}

int UpgradesCount
int PlayerUpgrades[MAXPLAYERS+1][MAX_UPGRADES]
int EnabledUpgrades[MAX_UPGRADES]
int EnabledUpgradesCount
float PlayerUpgradeValue[MAXPLAYERS+1][MAX_UPGRADES]
any UpgradeInfo[MAX_UPGRADES][SJUpgradeData]
int PlayerCredits[MAXPLAYERS+1]

/// API ////

#if defined START_WITH_MAX_UPGRADES
public void OnClientPutInServer(int client)
{
	for (int i; i < UpgradesCount; i++)
	{
		SetPlayerUpgradeLevel(client, i, GetUpgradeMaxLevel(i))
	}
}
#endif

void AddPlayerCredits(int client, int creditsCount)
{
	int oldCredits = GetPlayerCredits(client)
	SetPlayerCredits(client, oldCredits + creditsCount)
}

int GetPlayerCredits(int client/*, int creditsCount*/)
{
	return PlayerCredits[client]
}

void SetPlayerCredits(int client, int creditsCount)
{
	PlayerCredits[client] = creditsCount
}

int CreateUpgrade(char[] name, float minValue, float maxValue, int levelsCount, int cost, 
		const char[] measureName = "", UpgradeFunc funcion = INVALID_FUNCTION)
{
	strcopy(UpgradeInfo[UpgradesCount][SJUpgradeData_Name], UPGRADE_NAME_LENGTH, name)
	UpgradeInfo[UpgradesCount][SJUpgradeData_MinValue] = minValue
	UpgradeInfo[UpgradesCount][SJUpgradeData_MaxValue] = maxValue
	UpgradeInfo[UpgradesCount][SJUpgradeData_LevelsCount] = levelsCount
	UpgradeInfo[UpgradesCount][SJUpgradeData_Cost] = cost
	UpgradeInfo[UpgradesCount][SJUpgradeData_Func] = funcion
	strcopy(UpgradeInfo[UpgradesCount][SJUpgradeData_MeasName], UPGRADE_MEAS_NAME_LENGTH, measureName)
	return UpgradesCount++
}

public void ClearClientUpgrades(int client)
{
	#if !defined START_WITH_MAX_UPGRADES
	for (int upgrade = 0; upgrade < UpgradesCount; upgrade++)
	{
		SetPlayerUpgradeLevel(client, upgrade, 0)
	}
	#else
	for (int i; i < UpgradesCount; i++)
	{
		SetPlayerUpgradeLevel(client, i, GetUpgradeMaxLevel(i))
	}
	#endif
	
	PlayerCredits[client] = GetConVarInt(InitialCreditsConVar)
	FireOnClientResetUpgrades(client)
}

////////////

public void UM_Init()
{
	CreateConfig("upgrades.cfg", "upgrades", UM_ReadConfig)
	CatchingUpgradeId = CreateUpgrade("dexterity", 20.0, 90.0, 5, 1, "%")
	UpgradeMaxLevelSoundId = CreateSound("upgrade_maxlevel")

	InitialCreditsConVar = CreateConVar("sj_initial_credits", "12", "Start credits for upgrades", 0, true, 0.0)
	ResetUpgradesEnabledConVar = CreateConVar("sj_reset_upgrades_enabled", "0", "Enable reset upgrades", 0, true, 0.0, true, 1.0)
	WarmupUpgradesEnabledConVar = CreateConVar("sj_warmup_upgrades_enabled", "0", "Enable upgrades during Warmup", 0, true, 0.0, true, 1.0)

	OnClientResetUpgradesForward = CreateForward(ET_Ignore, Param_Cell)
	RegisterCustomForward(OnClientResetUpgradesForward, "OnClientResetUpgrades")

	OnGetClientUpgradeInfoForward = CreateForward(ET_Ignore, Param_Cell, Param_String)
	RegisterCustomForward(OnGetClientUpgradeInfoForward, "OnGetUpgradeInfo")
}

public void UM_OnPlayerRunCmd(int client, int &buttons)
{
	bool reloading[MAXPLAYERS+1]
	
	if (buttons & IN_RELOAD)
	{
		if (!reloading[client])
		{
			ShowUpgradeMenu(client)
			reloading[client] = true
		}
	}
	else
	{
	   reloading[client] = false;
	}
}

public void UM_OnStartPublic()
{
	ForEachClient(ClearClientUpgrades)
}

public void UM_OnStartMatch()
{
	ForEachClient(ClearClientUpgrades)
}

void GetUpgradeName(int upgradeIndex, char destination[UPGRADE_NAME_LENGTH])
{
	strcopy(destination, UPGRADE_NAME_LENGTH, UpgradeInfo[upgradeIndex][SJUpgradeData_Name])
}

void IncreasePlayerUpgradeLevel(int client, int upgrade)
{
	int newLevel = PlayerUpgrades[client][upgrade] + 1
	SetPlayerUpgradeLevel(client, upgrade, newLevel)
}

void SetPlayerUpgradeLevel(int client, int upgrade, int level)
{
	PlayerUpgrades[client][upgrade] = level
	float maxValue = UpgradeInfo[upgrade][SJUpgradeData_MaxValue]
	float minValue = UpgradeInfo[upgrade][SJUpgradeData_MinValue]
	int levelsCount = UpgradeInfo[upgrade][SJUpgradeData_LevelsCount]
	float step = (maxValue - minValue) / levelsCount
	float value = minValue + step * level
	PlayerUpgradeValue[client][upgrade] = value
	Function func = UpgradeInfo[upgrade][SJUpgradeData_Func]
	
	if (func != INVALID_FUNCTION)
	{
		Call_StartFunction(INVALID_HANDLE, func)
		Call_PushCell(client)
		Call_PushFloat(value)
		Call_Finish()
	}
}

int GetUpgradeMaxLevel(int upgradeIndex)
{
	return UpgradeInfo[upgradeIndex][SJUpgradeData_LevelsCount]
}

public void UM_ReadConfig(KeyValues kv)
{
	EnabledUpgradesCount = 0
	if (KvGotoFirstSubKey(kv))
	{
		int upgrade
		int isEnabled
		char upgradeName[UPGRADE_NAME_LENGTH]
		do
		{
			KvGetSectionName(kv, upgradeName, sizeof(upgradeName))
			upgrade = FindUpgradeByName(upgradeName)
			if (upgrade != INVALID_UPGRADE)
			{					
				UpgradeInfo[upgrade][SJUpgradeData_MinValue] = KvGetFloat(kv, "min_value", UpgradeInfo[upgrade][SJUpgradeData_MinValue])
				UpgradeInfo[upgrade][SJUpgradeData_MaxValue] = KvGetFloat(kv, "max_value", UpgradeInfo[upgrade][SJUpgradeData_MaxValue])
				UpgradeInfo[upgrade][SJUpgradeData_LevelsCount] = KvGetNum(kv, "levels_count", UpgradeInfo[upgrade][SJUpgradeData_LevelsCount])
				UpgradeInfo[upgrade][SJUpgradeData_Cost] = KvGetNum(kv, "cost", UpgradeInfo[upgrade][SJUpgradeData_Cost])
				isEnabled = KvGetNum(kv, "enabled", 1)
				if (isEnabled)
				{
					EnabledUpgrades[EnabledUpgradesCount] = upgrade
					EnabledUpgradesCount++
				}
			}
		}
		while (KvGotoNextKey(kv))
	}
}

int FindUpgradeByName(const char[] name)
{
	for (int upgrade = 0; upgrade < UpgradesCount; upgrade++)
	{
		if (StrEqual(name, UpgradeInfo[upgrade][SJUpgradeData_Name], false))
		{
			return upgrade
		}
	}
	return INVALID_UPGRADE;
}

void ShowUpgradeMenu(int client)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1 && !GetConVarBool(WarmupUpgradesEnabledConVar)) 
    {
    	return
    }

	Menu menu = CreateMenu(Upgrade_Handler)
	char line[512]
	int currentCredits = PlayerCredits[client]
	FormatEx(line, sizeof(line), "%T\nCredits: %i", "MENU_TITLE", client, currentCredits)
	FireOnGetClientUpgradeInfo(client, line)
	SetMenuTitle(menu, line)
	int style, level, price, maxLevel, value, upgrade
	char upgradeName[UPGRADE_NAME_LENGTH]
	for (int i = 0; i < EnabledUpgradesCount; i++)
	{
		upgrade = EnabledUpgrades[i]
		value = RoundFloat(PlayerUpgradeValue[client][upgrade])
		GetUpgradeName(upgrade, upgradeName)
		style = ITEMDRAW_DEFAULT
		level = PlayerUpgrades[client][upgrade]
		maxLevel = GetUpgradeMaxLevel(upgrade)
		if (level < maxLevel
			&& IsPlayerCanBuyUpgrade(client, upgrade))
		{
			price = UpgradeInfo[upgrade][SJUpgradeData_Cost]
			Format(line, sizeof(line), "%T: %i %s (lvl %i/%i) cost: %i", upgradeName, client, value, UpgradeInfo[upgrade][SJUpgradeData_MeasName], level, maxLevel, price)
		}
		else
		{
			style |= ITEMDRAW_DISABLED
			Format(line, sizeof(line), "%T: %i %s (lvl %i/%i)", upgradeName, client, value, UpgradeInfo[upgrade][SJUpgradeData_MeasName], level, maxLevel)
		}
		style = (currentCredits > 0) ? style : ITEMDRAW_DISABLED
		AddMenuItem(menu, upgradeName, line, style)
	}
	if (GetConVarBool(ResetUpgradesEnabledConVar))
	{
		Format(line, sizeof(line), "%T", "RESET_ALL", client)
		AddMenuItem(menu, "reset", line)
	}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
}

public int Upgrade_Handler(Menu menu, MenuAction action, int client, int choice) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if (choice < EnabledUpgradesCount)
		{
			int upgrade = EnabledUpgrades[choice]
			char upgradeName[UPGRADE_NAME_LENGTH]
			GetUpgradeName(upgrade, upgradeName)
			char upgradeTitle[64];
			Format(upgradeTitle, sizeof(upgradeTitle), "%T", upgradeName, client);
			int currentLevel = PlayerUpgrades[client][upgrade];		
			int price = UpgradeInfo[upgrade][SJUpgradeData_Cost]			
			PlayerCredits[client] -= price;
			IncreasePlayerUpgradeLevel(client, upgrade)
			int maxLevel = GetUpgradeMaxLevel(upgrade)
			if (currentLevel >= maxLevel - 1)
			{
				PlaySoundByIdToClient(client, UpgradeMaxLevelSoundId)
			}				
			if (PlayerCredits[client] > 0)
			{
				ShowUpgradeMenu(client);
			}
		}
		else
		{
			char info[32]
			GetMenuItem(menu, choice, info, sizeof(info))
			if (StrEqual(info, "reset"))
			{
				ClearClientUpgrades(client)				
				ShowUpgradeMenu(client)		
			}
		}
	}
}

bool IsPlayerCanBuyUpgrade(int client, int upgrade)
{
	return PlayerCredits[client] >= UpgradeInfo[upgrade][SJUpgradeData_Cost]
}

float GetPlayerCatchingPercent(int client)
{
	return GetPlayerUpgradeValue(client, CatchingUpgradeId)
}

float GetPlayerUpgradeValue(int client, int upgrade)
{
	return PlayerUpgradeValue[client][upgrade];
}

void FireOnClientResetUpgrades(int client)
{
	Call_StartForward(OnClientResetUpgradesForward)
	Call_PushCell(client)
	Call_Finish()
}
void FireOnGetClientUpgradeInfo(int client, char info[512])
{
	Call_StartForward(OnGetClientUpgradeInfoForward)
	Call_PushCell(client)
	Call_PushStringEx(info, sizeof(info), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK)
	Call_Finish()
}