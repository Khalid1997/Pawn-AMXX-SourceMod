#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

// -- Settings --
int g_iDefault_MinPlayers = 2;
int g_iDefault_ChooseNCPlayersMode = MODE_RANDOM;
float g_flDefault_NCRatio = 3.0;
float g_flDefault_LaserRatio = 3.0;
int g_iDefault_PointsPerKill_NC = 3;
int g_iDefault_PointsHSBonus = 1;
int g_iDefault_PointsPerKill_Survivor = 1;

float g_flDefault_MaxMana = 200.0;
float g_flDefault_ManaRegenTime = 1.5;
float g_flDefault_ManaRegenAmount = 3.5;
float g_flDefault_TeleportManaCost = 75.0;

float g_flDefault_ChooseWeaponTime = 25.0;

char g_szDefault_LightStyle[3] = "b";

float g_flDefault_NCVisibleTime = 2.3;
bool g_bDefault_BlockFallDamge_NC = true;

bool g_bDefault_RemoveShadows = true;
bool g_bDefault_MakeFog = true;

float g_flDefault_MinePlacement_MaxDistanceFromWall = 20.0;
int g_iDefault_MineMaxPlayers = 3;
int g_iDefault_MineGiveCount = 2;
float g_flDefault_MinePlaceTime = 3.0;
new const String:g_szDefault_MineLaserColor[12] = "0 0 200";
float g_flDefault_MineActivateTime = 3.0;

float g_flDefault_SuicideBombExplodeTime = 2.5;
float g_flDefault_SuicideBombDamage = 425.0;
float g_flDefault_SuicideBombRadius = 250.0;

float g_flDefault_AdrenalineSpeedMultiplier = 1.31;
float g_flDefault_AdrenalineAttackSpeedMultiplier = 0.8;
int g_iDefault_AdrenalineExtraHealth = 70;
float g_flDefault_AdrenalineTime = 8.7;

float g_flDefault_DetectorUpdateTime = 1.8;
int g_iDefault_DetectorMaxPlayers = 2;
float g_flDefault_Detector_UnitsPerChar = 75.0;
float g_flDefault_Detector_MaxDistance = 525.0;
char g_szDefault_DetectorNormalColor[10] = "#FFFFFF";
char g_szDefault_DetectorCloseColor[10] = "#FF0000";
char g_szDefault_DetectorMsg[35] = "NC Detector:\n\t";

// -- Settings --
int g_iMinPlayers
int g_iChooseNCPlayersMode
float g_flNCRatio;
float g_flLaserRatio;
int g_iPointsPerKill_NC;
int g_iPointsHSBonus;
int g_iPointsPerKill_Survivor;

float g_flMaxMana;
float g_flManaRegenTime;
float g_flManaRegenAmount;
float g_flTeleportManaCost;

float g_flChooseWeaponTime;

char g_szLightStyle[3];

float g_flNCVisibleTime;
bool g_bBlockFallDamge_NC;

bool g_bRemoveShadows;
bool g_bMakeFog;

float g_flMinePlacement_MaxDistanceFromWall;
int g_iMineMaxPlayers;
int g_iMineGiveCount;
float g_flMinePlaceTime;
char g_szMineLaserColor[12];
float g_flMineActivateTime;

float g_flSuicideBombExplodeTime;
float g_flSuicideBombDamage;
float g_flSuicideBombRadius;

float g_flAdrenalineSpeedMultiplier;
float g_flAdrenalineAttackSpeedMultiplier;
int g_iAdrenalineExtraHealth;
float g_flAdrenalineTime;

float g_flDetectorUpdateTime;
int g_iDetectorMaxPlayers;
float g_flDetector_UnitsPerChar;
float g_flDetector_MaxDistance;
char g_szDetectorNormalColor[10];
char g_szDetectorCloseColor[10];
char g_szDetectorMsg[35];

void LoadSettingsFromFile(bool bForceReplace)
{
	if(!g_bFirstRun && !bForceReplace)
	{
		g_bUpdateSettingsNextRound = true;
		return;
	}
	
	// To ensure that all settings were loaded correctly.
	LoadDefaultValues();
	
	any Keys[] = {
		"MinimumPlayers",
		"ChooseNightcrawlerMode",
		"NightcrawlerRatio",
		"LaserRatio",
		"Nightcrawler_PointsPerKill",
		"Survivor_PointsPerKill",
		"Survivor_HeadshotBonus",
		"Mana_Max",
		"Mana_RegenTime",
		"Mana_RegenAmount",
		"Mana_TeleportCost",
		"Weapons_ChooseWeaponTime",
		"World_LightStyle",
		"World_MakeFog",
		"World_RemoveShadows",
		"Mine_PlacementMaxDistance",
		"Mine_MaxPlayers",
		"Mine_GiveAmount",
		"Mine_PlacementTime",
		"Mine_LaserColor_Normal",
		"Mine_LaserColor_Aim",
		"Mine_ActivateTime",
		"SuicideBomb_ExplodeTime",
		"SuicideBomb_MaxDamage",
		"SuicideBomb_Radius",
		"Adrenaline_RunSpeedMultiplier",
		"Adrenaline_AttackSpeedMultiplier",
		"Adrenaline_ExtraHealth",
		"Adrenaline_Time",
		"Detector_UpdateTime",
		"Detector_MaxPlayers",
		"Detector_NormalColor",
		"Detector_CloseColor",
		"Detector_Radius",
		"Detector_UnitsPerChar",
		"Detector_DefaultMessage",
	};
	
	enum
	{
		Key_MinimumPlayers,
		Key_ChooseNCMode,
		Key_NCRatio,
		Key_LaserRatio,
		Key_NCPointsPerKill,
		Key_SurvivorPointsPerKill,
		Key_SurvivorHSBonus,
		Key_MaxMana,
		Key_ManaRegenTime,
		Key_ManaRegenAmount,
		Key_ManaTeleportCost,
		Key_WeaponsChooseTime,
		Key_LightStyle,
		Key_MakeFog,
		Key_RemoveShadows,
		Key_MinePlacementMaxDistance,
		Key_MineMaxPlayers,
		Key_MineGiveAmount,
		Key_MinePlacementTime,
		Key_MineLaserColor_Normal,
		Key_MineLaserColor_Aim,
		Key_MineActivateTime,
		Key_SuicicdeBombExplodeTime,
		Key_SuicideBomb_MaxDamage,
		Key_SuicideBomb_Radius,
		Key_AdrenalineSpeedMultiplier,
		Key_AdrenalineAttackSpeedMultiplier,
		Key_AdrenalineExtraHealth,
		Key_AdrenalineTime,
		Key_DetectorUpdateTime,
		Key_DetectorMaxPlayers,
		Key_DetectorNormalColor,
		Key_DetectorCloseColor,
		Key_DetectorRadius,
		Key_DetectorUnitsPerChar,
		Key_DetectorDefaultMessage,
		
		Key_Total
	};
	
	char szFile[PLATFORM_MAX_PATH];
	BuildPath(szFile, sizeof szFile, "/configs/nightcrawler.cfg");
	
	if(!FileExists(szFile))
	{
		LogError("Missing Settings file. Using default values as defined in plugin.");
		return;
	}
	
	Handle hKv = CreateKeyValues("NightCrawler");
	FileToKeyValues(hKv, szFile);
	KvGotoFirstSubKey(hKv, true);
	
	LoadKeyValues(hKv);
	
	for(int i; i < Key_Total; i++)
	{
		if(!KvJumpToKey(hKv, Keys[i][KeyData_Name], false)
		{
			LogError("Key '%s' was not found in the config file.", Keys[i][KeyData_Name]);
		}
	}
	
	delete hKv;
	
	LoadOtherFiles();
}

void LoadKeyValues(Handle hKv)
{
	g_iMinimumPlayers = KvGetNum(hKv, Keys[Key_MinimumPlayers], g_iDefault_MinimumPlayers);
	g_iChooseNCMode = KvGetNum(hKv, Keys[Key_MinimumPlayers], g_iDefault_ChooseNCMode);
	g_flNCRatio = KvGetFloat(hKv, Keys[Key_NCRatio], g_flDefault_NCRatio);
	g_flLaserRatio = KvGetFloat(hKv, Keys[Key_LaserRatio], g_flDefault_LaserRatio);
	
	g_iPointsPerKill_NC = KvGetNum(hKv, Keys[Key_NCPointsPerKill], g_iDefault_PointsPerKill_NC);
	g_iPointsPerKill_Survivor = KvGetNum(hKv, Keys[Key_SurvivorPointsPerKill], g_iDefault_PointsPerKill_Survivor);
	g_iPointsHSBonus = KvGetNum(hKv, Keys[Key_SurvivorHSBonus], g_iDefault_PointsHSBonus);
	
	g_flMaxMana = KvGetFloat(hkV, Keys[Key_MaxMana], g_flDefault_MaxMana);
	g_flManaRegenTime = KvGetFloat(hKv, Keys[Key_ManaRegenTime], g_flDefault_ManaRegenTime);
	g_flManaRegenAmount = KvGetFloat(hKv, Keys[Key_ManaRegenAmount], g_flDefault_ManaRegenAmount);
	g_flManaTeleportCost = KvGetFloat(hKv, Keys[Key_ManaTeleportCost], g_flDefault_ManaTeleportCost);
	g_flChooseWeaponTime = KvGetFloat(hKv, Keys[Key_WeaponsChooseTime], g_flDefault_ChooseWeaponTime);
	
	KvGetString(hKv, Keys[Key_LightStyle], g_szLightStyle, sizeof g_szLightStyle, g_szDefault_LightStyle);
	g_bMakeFog = view_as<bool>(KvGetNum(hKv, Keys[Key_MakeFog], view_as<int>(g_bDefault_MakeFog)));
	g_bRemoveShadows = view_as<bool>(KvGetNum(hKv, Keys[Key_RemoveShadows], view_as<int>(g_bDefault_RemoveShadows)));
	
	g_flMinePlacement_MaxDistanceFromWall = KvGetFloat(hKv, Keys[Key_MinePlacementMaxDistance], g_flDefault_MinePlacement_MaxDistanceFromWall);
	g_iMineMaxPlayers = KvGetNum(hKv, Keys[Key_MineMaxPlayers], g_iDefault_MineMaxPlayers);
	g_iMineGiveCount = KvGetNum(hKv, Keys[Key_MineGiveAmount], g_iDefault_MineGiveCount);
	g_flMinePlacement_PlacementTime = KvGetFloat(hKv, Keys[Key_MinePlacementTime], g_flDefault_MinePlacement_PlacementTime);
	
	KvGetColor(hKv, Keys[Key_MineLaserColor_Normal], g_szMineLaserColor_Normal[0], g_szMineLaserColor_Normal[1],
	g_szMineLaserColor_Normal[2], g_szMineLaserColor_Normal[3]);
	KvGetColor(hKv, Keys[Key_MineLaserColor_Aim], g_szMineLaserColor_Aim[0], g_szMineLaserColor_Aim[1],
	g_szMineLaserColor_Aim[2], g_szMineLaserColor_Aim[3]);
	
	g_flSuicideBombExplodeTime = KvGetFloat(hKv, Keys[Key_SuicideBombExplodeTime], g_flDefault_SuicideBombExplodeTime);
	g_flSuicideBombDamage = KvGetFloat(hKv, Keys[Key_SuicideBomb_MaxDamage], g_flDefault_SuicideBombDamage);
	g_flSuicideBombRadius = KvGetFloat(hKv, Keys[Key_SuicideBomb_Radius], g_flDefault_SuicideBombRadius);
	
	g_flAdrenalineSpeedMultiplier = KvGetFloat(hKv, Keys[Key_AdrenalineSpeedMultiplier], g_flDefault_AdrenalineSpeedMultiplier);
	g_flAdrenalineAttackSpeedMultiplier = KvGetFloat(hKv, Keys[Key_AdrenalineAttackSpeedMultiplier], g_flDefault_AdrenalineAttackSpeedMultiplier);
	g_iAdrenalineExtraHealth = KvGetNum(hKv, Keys[Key_AdrenalineExtraHealth], g_iDefault_AdrenalineExtraHealth);
	g_flAdrenalineTime = KvGetFloat(hKv, Keys[Key_AdrenalineTime], g_flDefault_AdrenalineTime);
	
	g_flDetectorUpdateTime = KvGetFloat(hKv, Keys[Key_DetectorUpdateTime], g_flDefault_DetectorUpdateTime);
	g_iDetectorMaxPlayers = KvGetFloat(hKv, Keys[Key_DetectorMaxPlayers], g_iDefault_DetectorMaxPlayers);
	g_flDetector_UnitsPerChat = KvGetFloat(hKv, Keys[Key_DetectorUnitsPerChar], g_flDefault_Detector_UnitsPerChar);
	g_flDetector_Radius = KvGetFloat(hKv, Keys[Key_DetectorRadius] g_flDefault_DetectorRadius);
	KvGetString(hKv, Keys[Key_DetectorNormalColor], g_szDetectorNormalColor, sizeof g_szDetectorNormalColor, g_szDefault_DetectorNormalColor);
	KvGetString(hKv, Keys[Key_DetectorCloseColor], g_szDetectorCloseColor, sizeof g_SzDetectorCloseColor, g_szDefualt_DetectorCloseColor);
	KvGetString(hKv, Keys[Key_DetectorDefaultMessage], g_szDetectorDefaultMessage, sizeof g_szDetectorDefaultMessage, g_szDefault_DetectorDefaultMessage); 
}

void LoadDefaultValues()
{
	g_iMinPlayers = g_iDefault_MinPlayers;
	g_iChooseNCPlayersMode = g_iDefault_ChooseNCPlayersMode;
	g_flNCRatio = g_flDefault_NCRatio;
	g_flLaserRatio = g_flDefault_LaserRatio;
	g_iPointsPerKill_NC = g_iDefault_PointsPerKill_NC;
	g_iPointsHSBonus = g_iDefault_PointsHSBonus;
	g_iPointsPerKill_Survivor = g_iDefault_PointsPerKill_Survivor;

	g_flMaxMana = g_flDefault_MaxMana;
	g_flManaRegenTime = g_flDefault_ManaRegenTime;
	g_flManaRegenAmount = g_flDefault_ManaRegenAmount;
	g_flTeleportManaCost = g_flDefault_TeleportManaCost;

	g_flChooseWeaponTime = g_flDefault_ChooseWeaponTime;

	g_szLightStyle = g_szDefault_LightStyle;

	g_flNCVisibleTime = g_flDefault_NCVisibleTime;
	g_bBlockFallDamage_NC = g_bDefault_BlockFallDamage_NC;

	g_bRemoveShadows = g_bDefault_RemoveShadows;
	g_bMakeFog = g_bDefault_MakeFog

	g_flMinePlacement_MaxDistanceFromWall = g_flDefault_MinePlacement_MaxDistanceFromWall;
	g_iMineMaxPlayesrs = g_iDefault_MineMaxPlayers;
	g_iMineGiveCount = g_iDefault_MineGiveCount;
	g_flMinePlaceTime = g_flDefault_MinePlaceTime;
	g_szMineLaserColor_Normal = g_szDefault_MineLaserColor_Normal;
	g_szMineLaserColor_Touch = g_szDefault_MineLaserColor_Touch
	g_flMineActivateTime = g_flDefault_MineActivateTime;

	g_flSuicideBombExplodeTime = g_flDefault_SuicideBombExplodeTime;
	g_flSuicideBombDamage = g_flDefault_SuicideBombDamage;
	g_flSuicideBombRadius = g_flDefault_SuicideBombRadius;

	g_flAdrenalineSpeedMultiplier = g_flDefault_AdrenalineSpeedMultiplier;
	g_flAdrenalineAttackSpeedMultiplier = g_flDefault_AdrenalineAttackSpeedMultiplier;
	g_iAdrenalineExtraHealth = g_iDefault_AdrenalineExtraHealth;
	g_flAdrenalineTime = g_flDefault_AdrenalineTime;

	g_flDetectorUpdateTime = g_flDefault_DetectorUpdateTime;
	g_iDetectorMaxPlayers = g_iDefault_DetectorMaxPlayers;
	g_flDetector_UnitsPerChar = g_flDefault_Detector_UnitsPerChar;
	g_flDetector_MaxDistance = g_flDefault_Detector_MaxDistance;
	g_szDetectorBarColor = g_szDefault_DetectorBarColor;
	g_szDetectorMsg = g_szDefault_DetectorMsg;
	
	int g_iItemsData[0][PlayerItem_Name] = "Laser Detector";
	int g_iItemsData[0][PlayerItem_Enabled] = 0;
	
	int g_iItemsData[1][PlayerItem_Name] = "Laser Mines [2]";
	int g_iItemsData[1][PlayerItem_Enabled] = 1;
	
	int g_iItemsData[2][PlayerItem_Name] = "Adrenaline";
	int g_iItemsData[2][PlayerItem_Enabled] = 1;
	
	int g_iItemsData[3][PlayerItem_Name] = "Suicide Bomb";
	int g_iItemsData[3][PlayerItem_Enabled] = 1;
	
	int g_iItemsData[4][PlayerItem_Name] = "Detector Bar";
	int g_iItemsData[4][PlayerItem_Enabled] = 1;
}

void LoadOtherFires()
{
	if(g_bFirstRun)
	{
		g_Array_WeaponClipAmmo = CreateArray(1);
		g_Array_WeaponGiveName = CreateArray(25);
	}
	
	else
	{
		ClearArray(g_Array_WeaponClipAmmo);
		ClearArray(g_Array_WeaponGiveName);
	}
	
	g_Array_WeaponSuffix = CreateArray(1);
	g_Array_WeaponType = CreateArray(1);
	g_Array_WeaponName = CreateArray(25);
	g_Trie_WeaponSuffix = CreateTrie();
	
	ParseWeaponsMenuFile();
	BuildMenus();
	
	delete g_Array_WeaponName;
	//delete g_Array_WeaponGiveName;
	delete g_Array_WeaponType;
	delete g_Array_WeaponSuffix;
	delete g_Trie_WeaponSuffix;
}	