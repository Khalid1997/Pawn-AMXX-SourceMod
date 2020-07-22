#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid - Private Plugin"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
//#include <the_khalid_inc>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <getplayers>
#include <emitsoundany>

#undef REQUIRE_PLUGIN
#tryinclude <fdownloader>
#tryinclude <WeaponAttachmentAPI>

public Plugin myinfo = 
{
	name = "Nightcrawler Mod", 
	author = PLUGIN_AUTHOR, 
	description = "Bla Bla", 
	version = PLUGIN_VERSION, 
	url = "steamcommunity.com/id/Khalid123"
};

#define CS_TEAM_NC				CS_TEAM_T
#define CS_TEAM_SURVIVOR		CS_TEAM_CT

#if CS_TEAM_NC == CS_TEAM_T
	#define GP_Team_NC 			GP_Team_First
	#define GP_Team_Survivor 	GP_Team_Second
#else 
	#define GP_Team_NC 			GP_Team_Second
	#define GP_Team_Survivor 	GP_Team_First
#endif

// -- Game State --
bool g_bRunning = false;
bool g_bRoundEnd = false;

float g_flMineLaser_SoundPlayCooldown = 1.05;

#define MODE_RANDOM 					0
#define MODE_KILL						1
#define MODE_QUEUE						2

#define LMODE_RANDOM					0
#define LMODE_MENU						1
#define LMODE_KILL						2

#define WEAPONTYPE_SECONDARY 			2
#define WEAPONTYPE_PRIMARY 				1

#define HINTMSG_UPDATE_TIME 			0.5

char g_szMineTargetName[] = 			"rxgmine";
char g_szMineLaserTargetName[] = 		"rxgmine_laser";
char g_szPlayerLaserTargetName[] = 		"player_laser_detector";

#define CHAR_DASH 						'-'
#define CHAR_BAR 						'|'

#define FROST_GRENADE_TYPE 				Nade_Decoy
#define g_szFrostGrenProjectileName 	"decoy_projectile"

#define FROST_ICECUBE_MODEL				"models/weapons/eminem/ice_cube/ice_cube.mdl"
#define FROST_SPRITE_1					"materials/sprites/laserbeam.vmt"
#define FROST_SPRITE_2					"materials/sprites/lgtning.vmt"
#define FROST_HALO_SPRITE				"materials/sprites/halo01.vmt"
#define FROST_GLOW_SPRITE				"sprites/blueglow2.vmt"
#define FROST_GLASS_IMPACT_SOUND		"physics/glass/glass_impact_bullet4.wav"
#define FROST_FREEZE_SOUND				"/nightcrawler/freeze_cam.mp3"

#define PLUGIN_LOG_FILE 				"addons/sourcemod/logs/nightcrawler.log"

char MODEL_BEAM[] = 					"materials/sprites/physbeam.vmt"; /*"materials/sprites/laserbeam.vmt";*/

char g_szMineModel[] = "models/tripmine/tripmine.mdl";
char g_szMinePlacementSound[] = "nightcrawler/mine_deploy.wav";
char g_szMineArmedSound[] = "nightcrawler/mine_activate.wav";
char g_szMineArmingSound[] = "nightcrawler/mine_charge.wav";
char g_szMineLaserTouchSound[] = "nightcrawler/sonic_sound.wav";

char g_szTeleportSound[] = "nightcrawler/teleport.wav";
char g_szAdrenalineInjectionSound[] = "nightcrawler/adrenaline_shot.wav";
char g_szNightcrawlerDeathSound[][] =  {
	"nightcrawler/nc_death1.wav", 
	"nightcrawler/nc_death2.wav", 
	"nightcrawler/nc_death3.wav"
};

// --- Shop Items ---
enum
{
	ITEM_LASER, 
	ITEM_LASERMINE, 
	ITEM_ADRENALINE, 
	ITEM_SUICIDEBOMB, 
	ITEM_DETECTOR, 
	ITEM_HEGRENADE, 
	ITEM_FROSTGRENADE, 
	
	MAX_PLAYER_ITEMS
};

enum PlayerItems
{
	PlayerItem_Enabled, 
	String:PlayerItem_Name[35]
}

int g_iItemsData[][PlayerItems] =  {
	{ 1, "Laser Detector" }, 
	{ 1, "Laser Mines [2]" }, 
	{ 1, "Adrenaline" }, 
	{ 1, "Suicide Bomb" }, 
	{ 1, "Detector Bar" }, 
	{ 1, "HE grenades [2] with Regen" }, 
	{ 1, "Frost Grenades [3]" }
};

// -- Settings #1: Default --
int g_iDefault_MinPlayers = 						2;
int g_iDefault_ChooseNCPlayersMode = 				MODE_KILL;

char g_szDefault_ChatPrefix[] = 					"\x04[NightCrawlers-Beta] ";

char g_szDefault_SurvivorName[] = 					"Survivor";
char g_szDefault_SurvivorTeamName[] = 				"Survivors";
char g_szDefault_NCName[] = 						"Nightcrawler";
char g_szDefault_NCTeamName[] = 					"NightCrawlers";

bool g_bDefault_KeepSurvivingNC	=					true;
float g_flDefault_NCSpeedMultiplier = 				1.1;
float g_flDefault_NCGravityMultiplier =	 			0.7;
float g_flDefault_NCStartingHealth = 				160.0;

float g_flDefault_NCRatio = 						3.0;
int g_iDefault_LaserMode = 							LMODE_KILL;
int g_iDefault_MaxGivenLaserCount = 				-1;
float g_flDefault_LaserRatio = 						3.0;
int g_iDefault_SurvivorLaserColor_Normal[4] =  		{ 0, 0, 255, 180 };
int g_iDefault_SurvivorLaserColor_Aim[4] =  		{ 255, 0, 0, 255 };
int g_iDefault_PointsPerKill_NC = 					3;
int g_iDefault_PointsHSBonus = 						1;
int g_iDefault_PointsPerKill_Survivor = 			1;

char g_szDefault_ManaName[] = 						"Mana";
float g_flDefault_MaxMana = 						200.0;
float g_flDefault_ManaRegenTime = 					1.5;
float g_flDefault_ManaRegenAmount = 				5.0;
float g_flDefault_ManaTeleportCost = 				75.0;

float g_flDefault_ChooseWeaponTime = 				25.0;

char g_szDefault_LightStyle[3] = 					"b";

float g_flDefault_NCVisibleTime = 					2.3;
bool g_bDefault_BlockFallDamage_NC = 				true;

bool g_bDefault_RemoveShadows = 					true;
bool g_bDefault_MakeFog = 							true;

float g_flDefault_MinePlacement_MaxDistanceFromWall = 32.0;
int g_iDefault_MineMaxPlayers = 					3;
int g_iDefault_MineGiveCount = 						2;
float g_flDefault_MinePlacement_PlacementTime = 	0.4;
int g_iDefault_MineLaserColor_Normal[4] =  			{ 0, 0, 200, 150 };
int g_iDefault_MineLaserColor_Aim[4] =  			{ 200, 0, 0, 150 };
float g_flDefault_MineActivateTime = 				3.0;

float g_flDefault_SuicideBombExplodeTime = 			2.5;
float g_flDefault_SuicideBombDamage = 				320.0;
float g_flDefault_SuicideBombRadius = 				235.0;

float g_flDefault_AdrenalineSpeedMultiplier = 		1.31;
float g_flDefault_AdrenalineAttackSpeedMultiplier = 0.8;
int g_iDefault_AdrenalineExtraHealth = 				70;
float g_flDefault_AdrenalineTime = 					8.7;

float g_flDefault_DetectorUpdateTime = 				0.5;
int g_iDefault_DetectorMaxPlayers = 				2;
float g_flDefault_Detector_UnitsPerChar = 			35.0;
float g_flDefault_Detector_Radius = 				700.0;
char g_szDefault_DetectorNormalColor[10] = 			"#FFFFFF";
char g_szDefault_DetectorCloseColor[10] = 			"#FF0000";
char g_szDefault_DetectorDefaultMessage[35] = 		"NC Detector:";

int g_iDefault_HegrenadeGiveAmount = 				2;
int g_iDefault_HegrenadeRegenAmount = 				1;
int g_iDefault_HegrenadeMax = 						3;
float g_flDefault_HegrenadeRegenTime = 				60.0;

int g_iDefault_FrostGrenadeGiveAmount = 			3;
float g_flDefault_FrostGrenadeRadius = 				64.0;
//float g_flDefault_FrostGrenadeActivationDelay = 	1.3;
float g_flDefault_FrostGrenadeFreezeDuration = 		1.2;
int g_iDefault_FrostGrenadeBeamFollowColor[4] =  	{ 75, 75, 255, 128 };

bool g_bDefault_InfiniteBPAmmo = true;

// -- Settings #2 Actual s--
int g_iMinPlayers;
int g_iChooseNCPlayersMode;

char g_szSurvivorName[MAX_NAME_LENGTH];
char g_szSurvivorTeamName[MAX_NAME_LENGTH];
char g_szNCName[MAX_NAME_LENGTH];
char g_szNCTeamName[MAX_NAME_LENGTH];

bool g_bKeepSurvivingNC;
float g_flNCSpeedMultiplier;
float g_flNCGravityMultiplier;
float g_flNCStartingHealth;

float g_flNCRatio;
int g_iLaserMode;
int g_iMaxGivenLaserCount;
float g_flLaserRatio;
int g_iSurvivorLaserColor_Normal[4];
int g_iSurvivorLaserColor_Aim[4];
int g_iPointsPerKill_NC;
int g_iPointsHSBonus;
int g_iPointsPerKill_Survivor;

char g_szManaName[20];
float g_flMaxMana;
float g_flManaRegenTime;
float g_flManaRegenAmount;
float g_flManaTeleportCost;

float g_flChooseWeaponTime;

char g_szLightStyle[3];

float g_flNCVisibleTime;
bool g_bBlockFallDamage_NC;

bool g_bRemoveShadows;
bool g_bMakeFog;

float g_flMinePlacement_MaxDistanceFromWall;
int g_iMineMaxPlayers;
int g_iMineGiveCount;
float g_flMinePlacement_PlacementTime;
int g_iMineLaserColor_Normal[4];
int g_iMineLaserColor_Aim[4];
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
float g_flDetector_Radius;
char g_szDetectorNormalColor[10];
char g_szDetectorCloseColor[10];
char g_szDetectorDefaultMessage[35];

int g_iHegrenadeGiveAmount;
int g_iHegrenadeRegenAmount;
int g_iHegrenadeMax;
float g_flHegrenadeRegenTime;

int g_iFrostGrenadeGiveAmount;
float g_flFrostGrenadeRadius;
//float g_flFrostGrenadeActivationDelay;
float g_flFrostGrenadeFreezeDuration;
int g_iFrostGrenadeBeamFollowColor[4];

int g_bInfiniteBPAmmo;

// -------------------------------
// -- Player Data --
// -------------------------------
bool g_bDontShowPlayer[MAXPLAYERS + 1];
bool g_bKilledNC[MAXPLAYERS + 1];
bool g_bLaser[MAXPLAYERS + 1];
int g_iLaserEnt[MAXPLAYERS + 1];

int g_iCalculatedMaxLaserCount;
int g_iLaserCarriersCount;

// Items
bool g_bHasChosenItemThisRound[MAXPLAYERS + 1];
int g_iPlayerMinesCount[MAXPLAYERS + 1];
float g_vPlaceMineOrigin[MAXPLAYERS + 1][3];
Handle g_hTimer_PlaceMine[MAXPLAYERS + 1] = null;
float g_flMineLaser_PlayerTouch_SoundPlayCooldown[MAXPLAYERS + 1];

bool g_bHasSuicideBomb[MAXPLAYERS + 1];
bool g_bSuicideBombActivated[MAXPLAYERS + 1];
float g_vDeathPosition[MAXPLAYERS + 1][3];

bool g_bHasAdrenaline[MAXPLAYERS + 1];
bool g_bAdrenalineActivated[MAXPLAYERS + 1];
float g_flNextModifyTime[MAXPLAYERS + 1];

Handle g_hTimer_Detector[MAXPLAYERS + 1] = null;

bool g_bHasHeGrenade[MAXPLAYERS + 1];
float g_flPlayerNextGrenade[MAXPLAYERS + 1];

bool g_bHasFrostGrenade[MAXPLAYERS + 1];

// WeaponMenu;
bool g_bHasChosenWeaponsThisRound[MAXPLAYERS + 1];
int g_iWeaponMenuStep[MAXPLAYERS + 1];
int g_iLastWeapons[MAXPLAYERS + 1][2];
bool g_bSaveLastWeapons[MAXPLAYERS + 1];

// ManaStuff;
float g_flNextManaGain[MAXPLAYERS + 1];
int g_iPlayerPoints[MAXPLAYERS + 1];
float g_flPlayerMana[MAXPLAYERS + 1];

#define MAX_BUTTONS 25
int g_LastButtons[MAXPLAYERS + 1];

// -- Misc --
ConVar sv_footsteps;

Handle g_hTimer_CheckGameState, g_hTimer_HintMessage;
bool g_bLate;
int g_iFogEnt;

int g_iMineCount;
int g_iDetectorCount;

char g_szDefaultDetectorText[25];

Menu g_hShopMenu;
Menu g_hMainMenu;
Menu g_hWeaponMenu_Main, g_hWeaponMenu_Primary, g_hWeaponMenu_Sec;
Menu g_hItemMenu;

StringMap g_Trie_WeaponSuffix;
ArrayList g_Array_WeaponName, 
g_Array_WeaponGiveName, 
g_Array_WeaponSuffix, 
g_Array_WeaponType, g_Array_WeaponReserveAmmo;

StringMap g_Trie_WeaponsBPAmmo;

float g_flWeaponMenuExpireTime;
int g_iWeapons_Clip1Offset;

bool g_bIsInNCQueue[MAXPLAYERS + 1];
ArrayList g_Array_NCQueue = null;
int g_iNCQueueCount = 0;

int g_iFrostGrenadeBeamIndex_Sprite1,
	g_iFrostGrenadeBeamIndex_Sprite2,
	g_iFrostGrenadeHaloSprite,
	g_iFrostGrenadeGlowSprite;

Handle g_hTimer_Freeze[MAXPLAYERS + 1];
bool g_bIsFrozen[MAXPLAYERS + 1];

Handle g_hTimer_ExplodeSuicideBomb[MAXPLAYERS + 1];

ArrayList g_Array_SurvivorModels,
	g_Array_NightcrawlerModels;
	
int g_iSurvivorModelsCount,
	g_iNightcrawlerModelsCount;

int g_iTotalDashCount;

// 6 total grenades
char g_szGrenadeWeaponNames[][] =  {
	"weapon_flashbang", 
	"weapon_molotov", 
	"weapon_smokegrenade", 
	"weapon_hegrenade", 
	"weapon_decoy", 
	"weapon_incgrenade"
};

enum
{
	Nade_Flash = 0, 
	Nade_Molotov, 
	Nade_Smoke, 
	Nade_He, 
	Nade_Decoy, 
	Nade_Inc
}

int g_iGrenadeOffsets[6];

bool g_bFirstRun = true;

#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------
//								Plugin Start
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
//								Essential forwards (Plugin forwards)
// --------------------------------------------------------------------------

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int iErrMax)
{
	g_bLate = bLate;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vVel[3], float vAngles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);
		
		if ((buttons & button))
		{
			if (!(g_LastButtons[client] & button))
			{
				OnButtonPress(client, button);
			}
		}
		else if ((g_LastButtons[client] & button))
		{
			OnButtonRelease(client, button);
		}
	}
	
	g_LastButtons[client] = buttons;
	return Plugin_Continue;
}

bool CanPlaceMineOnWall(int client)
{
	float trace_start[3], trace_angle[3], trace_end[3];
	GetClientEyePosition(client, trace_start);
	GetClientEyeAngles(client, trace_angle);
	
	GetAngleVectors(trace_angle, trace_end, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(trace_end, trace_end); // end = normal
	
	for (int i = 0; i < 3; i++)
	{
		trace_end[i] = trace_start[i] + trace_end[i] * 9999.0;
	}
	
	Handle hTr = TR_TraceRayFilterEx(trace_start, trace_angle, CONTENTS_SOLID | CONTENTS_WINDOW, RayType_Infinite, TraceFilter_Callback, client);
	
	if (TR_DidHit(hTr))
	{
		TR_GetEndPosition(trace_end, hTr);
		
		if (GetVectorDistance(trace_start, trace_end) <= g_flMinePlacement_MaxDistanceFromWall)
		{
			delete hTr;
			return true;
		}
	}
	
	delete hTr;
	return false;
}

void OnButtonPress(int client, int button)
{
	if (button & IN_USE)
	{
		if (GetClientTeam(client) == CS_TEAM_SURVIVOR)
		{
			if (g_iPlayerMinesCount[client] > 0)
			{
				if (CanPlaceMineOnWall(client))
				{
					g_hTimer_PlaceMine[client] = CreateTimer(g_flMinePlacement_PlacementTime, Timer_PlaceMine, client);
					GetClientAbsOrigin(client, g_vPlaceMineOrigin[client]);
				}
				
				else
				{
					CPrintToChat(client, "Please aim somewhere else to place the mine.");
				}
			}
			
			else if (g_bHasSuicideBomb[client])
			{
				g_bHasSuicideBomb[client] = false;
				ActivateSuicideBomb(client);
			}
			
			else if (g_bHasAdrenaline[client])
			{
				g_bHasAdrenaline[client] = false;
				ActivateAdrenaline(client);
			}
		}
	}
}

void OnButtonRelease(int client, int button)
{
	if (button & IN_USE && g_hTimer_PlaceMine[client] != null)
	{
		delete g_hTimer_PlaceMine[client];
		g_hTimer_PlaceMine[client] = null;
	}
}

void ActivateSuicideBomb(int client)
{
	CPrintToChat(client, "You have activated the bomb! You will explode in \x04%0.1f \x01second!", g_flSuicideBombExplodeTime);
	g_hTimer_ExplodeSuicideBomb[client] = CreateTimer(g_flSuicideBombExplodeTime, Timer_ExplodeSuicideBomb, client);
}

public Action Timer_ExplodeSuicideBomb(Handle hTimer, int client)
{
	g_hTimer_ExplodeSuicideBomb[client] = null;
	if (!IsClientInGame(client) || GetClientTeam(client) != CS_TEAM_SURVIVOR)
	{
		
		return;
	}
	
	float vOrigin[3];
	if (!IsPlayerAlive(client))
	{
		vOrigin = g_vDeathPosition[client];
	}
	
	else
	{
		GetClientEyePosition(client, vOrigin);
		ForcePlayerSuicide(client);
	}
	
	//TakeDamage_Radius(vOrigin, g_flSuicideBombRadius, g_flSuicideBombDamage, 
	MakeExplosion(client, vOrigin);
	//ForcePlayerSuicide(client);
}

stock void MakeExplosion(int client, float vOrigin[3] =  { 0.0, 0.0, 0.0 }, bool bApplyForce = true, float flForce = 1500.0 )
{
	/*int explosion = CreateEntityByName("env_explosion");
	
	if (vOrigin[0] == NULL_VECTOR[0] && vOrigin[1] == NULL_VECTOR[1] && vOrigin[2] == NULL_VECTOR[2])
	{
		GetClientEyePosition(client, vOrigin);
	}
	
	if (explosion != -1)
	{
		// Stuff we will need
		int iTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
		
		// We're going to use eye level because the blast can be clipped by almost anything.
		// This way there's no chance that a small street curb will clip the blast.
		DispatchKeyValue(explosion, "classname", "env_explosion");
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(explosion, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(explosion, Prop_Data, "m_spawnflags", 264);
		SetEntProp(explosion, Prop_Data, "m_iMagnitude", g_flSuicideBombDamage);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", g_flSuicideBombRadius);
		
		PrintToChatAll("%0.3f - %0.3f", g_flSuicideBombDamage, g_flSuicideBombRadius);
		DispatchKeyValue(explosion, "rendermode", "5");
		
		DispatchSpawn(explosion);
		ActivateEntity(explosion);
		
		TeleportEntity(explosion, vOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "Kill");
	}
	*/
	
	float flRadius = g_flSuicideBombRadius;
	float flDamage = g_flSuicideBombDamage;
	float flDistance, flClientDamage;
	
	float vOtherOrigin[3];
	//GetClientEyePosition(client, vOrigin);
	
	float flRatio;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		if(i == client)
		{
			continue;
		}
		
		if(!IsPlayerAlive(i))
		{
			continue;
		}
		
		GetClientEyePosition(i, vOtherOrigin);
		
		if( ( flDistance = FloatAbs( GetVectorDistance(vOrigin, vOtherOrigin) ) - 32.0 ) > flRadius )
		{
			continue;
		}
		
		flRatio = (1.0 - (flDistance / flRadius));
		flClientDamage = flRatio * flDamage;
		
		if(bApplyForce)
		{
			SubtractVectors(vOtherOrigin, vOrigin, vOtherOrigin);
			NormalizeVector(vOtherOrigin, vOtherOrigin);
			
			ScaleVector(vOtherOrigin, flForce * flRatio);
			
			if (vOtherOrigin[2] < 355.0)
			{
				vOtherOrigin[2] = 355.0;
			}
			
			//PrintToChatAll("%N Knockback %0.2f %0.2f %0.2f", i, vOtherOrigin[0], vOtherOrigin[1], vOtherOrigin[2]);
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vOtherOrigin);
		}		
		
		if (GetClientTeam(i) == CS_TEAM_NC)
		{
			//continue;
			SDKHooks_TakeDamage(i, 0, client, flClientDamage, DMG_BLAST);
		}
	}
	
	EmitSoundToAll("weapons/hegrenade/explode5.wav", client/*, 1, 90*/);
	EmitSoundToAll("ambient/explosions/explode_8.wav", client/*, 1, 90*/);
}

/*float GetDistance(int client1, int client2)
{
	float vOrigin1[3], vOrigin2[3];
	GetClientAbsOrigin(client1, vOrigin1);
	GetClientAbsOrigin(client2, vOrigin2);
	
	float flDistance = GetVectorDistance(vOrigin1, vOrigin2, false);
	return flDistance > 0.0 ? flDistance : flDistance * -1.0;
}*/

void ActivateAdrenaline(int client)
{
	CPrintToChat(client, "You have injected yourself with Adrenaline!");
	CPrintToChat(client, "You will move and shoot faster!");
	CPrintToChat(client, "You have gained extra health!");
	
	g_bAdrenalineActivated[client] = true;
	SetClientSpeed(client, g_flAdrenalineSpeedMultiplier);
	SetEntityHealth(client, GetEntProp(client, Prop_Send, "m_iHealth") + g_iAdrenalineExtraHealth);
	
	EmitSoundToClientAny(client, g_szAdrenalineInjectionSound);
	
	CreateTimer(g_flAdrenalineTime, Timer_TurnOffAdrenaline, client);
}

void SetClientSpeed(int client, float flSpeed)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", flSpeed);
}

public Action Timer_TurnOffAdrenaline(Handle hTimer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	g_bAdrenalineActivated[client] = false;
	//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	SetClientSpeed(client, 1.0);
	
	CPrintToChat(client, "Adrenaline wore off.");
}

void ModifyAttackSpeed(int client)
{
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iWeapon != INVALID_ENT_REFERENCE)
	{
		float flNextPrimaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");

		if (GetGameTime() < g_flNextModifyTime[client])
		{
			return;
		}
		
		flNextPrimaryAttack -= GetGameTime();
		flNextPrimaryAttack *= g_flAdrenalineAttackSpeedMultiplier;
		flNextPrimaryAttack += GetGameTime();
		
		g_flNextModifyTime[client] = flNextPrimaryAttack;
		
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", flNextPrimaryAttack);
	}
}

public Action Timer_PlaceMine(Handle hTimer, int client)
{
	g_hTimer_PlaceMine[client] = null;
	
	if (g_iPlayerMinesCount[client] < 1)
	{
		return;
	}
	
	float vCurrentOrigin[3];
	GetClientAbsOrigin(client, vCurrentOrigin);
	
	if (GetVectorDistance(vCurrentOrigin, g_vPlaceMineOrigin[client]) > 10.0)
	{
		return;
	}
	
	if (PlaceMine(client))
	{
		--g_iPlayerMinesCount[client];
		
		CPrintToChat(client, "Laser Mines Left: %d mines", g_iPlayerMinesCount[client]);
	}
}

//	PlaceMine(
bool PlaceMine(int client)
{
	float trace_start[3], trace_angle[3], trace_end[3], trace_normal[3];
	GetClientEyePosition(client, trace_start);
	GetClientEyeAngles(client, trace_angle);
	GetAngleVectors(trace_angle, trace_end, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(trace_end, trace_end); // end = normal
	
	for (int i = 0; i < 3; i++)
	{
		trace_end[i] = trace_start[i] + trace_end[i] * g_flMinePlacement_MaxDistanceFromWall;
	}
	
	TR_TraceRayFilter(trace_start, trace_end, CONTENTS_SOLID | CONTENTS_WINDOW, RayType_EndPoint, TraceFilter_Callback, client);
	
	if (TR_DidHit(INVALID_HANDLE)) {
		TR_GetEndPosition(trace_end, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, trace_normal);
		
		NormalizeVector(trace_normal, trace_normal);
		
		return SetupMine(trace_end, trace_normal);
		
	} else {
		//PrintCenterText( client, "Invalid mine position." );
		CPrintToChat(client, "Invalid Mine position.");
	}
	
	return false;
}

bool SetupMine(float position[3], float vnormal[3])
{
	float angles[3];
	GetVectorAngles(vnormal, angles);
	//GetAngleVectors(
	
	int ent = CreateEntityByName("prop_physics_override");
	if (ent > -1)
	{
		DispatchKeyValue(ent, "model", g_szMineModel);
		DispatchKeyValue(ent, "physdamagescale", "0.0"); // enable this to destroy via physics?
		DispatchKeyValue(ent, "health", "1"); // use the set entity health function instead ?
		DispatchKeyValue(ent, "targetname", g_szMineTargetName);
		DispatchKeyValue(ent, "spawnflags", "256"); // set "usable" flag
		DispatchSpawn(ent);
		
		SetEntityMoveType(ent, MOVETYPE_NONE);
		
		#define DAMAGE_NO 0
		SetEntProp(ent, Prop_Data, "m_takedamage", DAMAGE_NO);
		
		SetEntityRenderColor(ent, 255, 255, 255, 255);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2); // set non-collidable
		
		#define MINE_PLACEMENT_OFFSET 1.5
		for (int i = 0; i < 3; i++)
		{
			position[i] += vnormal[i] * MINE_PLACEMENT_OFFSET;
		}
		
		TeleportEntity(ent, position, angles, NULL_VECTOR); //angles, NULL_VECTOR );
		
		// trace ray for laser (allow passage through windows)
		TR_TraceRayFilter(position, angles, CONTENTS_SOLID, RayType_Infinite, TraceFilter_Callback_PlaceLaser, ent);
		
		float beamend[3];
		TR_GetEndPosition(beamend, INVALID_HANDLE);
		
		//PrintToChatAll("%0.3f %0.3f %0.3f", beamend[0], beamend[1], beamend[2]);
		
		int ent_laser = CreateLaser(position, beamend);
		
		// when touched, activate/break the mine
		
		DataPack data = CreateDataPack();
		WritePackCell(data, ent);
		WritePackCell(data, ent_laser);
		ResetPack(data);
		
		// timer for activating
		CreateTimer(g_flMineActivateTime, ActivateTimer, data, TIMER_DATA_HNDL_CLOSE);
		
		EmitSoundToAllAny(g_szMinePlacementSound, ent);
		EmitSoundToAllAny(g_szMineArmingSound, ent);
		
		return true;
	}
	
	return false;
}

public void SDKCallback_ThinkPost_LaserBeam(int iLaserEnt)
{
	float vVecStart[3], vVecEnd[3];
	GetEntPropVector(iLaserEnt, Prop_Data, "m_vecEndPos", vVecEnd);
	GetEntPropVector(iLaserEnt, Prop_Data, "m_vecOrigin", vVecStart);
	
	TR_TraceRayFilter(vVecStart, vVecEnd, CONTENTS_SOLID, RayType_EndPoint, TraceFilterCallback_LaserBeam, iLaserEnt);
	int iEnt;
	
	if (TR_DidHit() && IsValidPlayer((iEnt = TR_GetEntityIndex())))
	{
		SetEntityRenderColor(iLaserEnt, g_iMineLaserColor_Aim[0], g_iMineLaserColor_Aim[1], g_iMineLaserColor_Aim[2], g_iMineLaserColor_Aim[3]);
		
		// Sound is played in the TraceFilterCallback because I didn't want to limit the sound to just one entity, but all
		// Entities touching the laser.
		// UPDATE: I Guess I have to leave it here because .... RenderColor :/
		float flGameTime;
		
		if (g_flMineLaser_PlayerTouch_SoundPlayCooldown[iEnt] < (flGameTime = GetGameTime()))
		{
			g_flMineLaser_PlayerTouch_SoundPlayCooldown[iEnt] = flGameTime + g_flMineLaser_SoundPlayCooldown;
			EmitSoundToAllAny(g_szMineLaserTouchSound, iEnt);
		}
	}
	
	else
	{
		SetEntityRenderColor(iLaserEnt, g_iMineLaserColor_Normal[0], g_iMineLaserColor_Normal[1], g_iMineLaserColor_Normal[2], g_iMineLaserColor_Normal[3]);
	}
}

public bool TraceFilterCallback_LaserBeam(int iEnt, int iContents, int iLaserEnt)
{
	if (iEnt == iLaserEnt)
	{
		return false;
	}
	
	if (!IsValidPlayer(iEnt))
	{
		return false;
	}
	
	if (!IsPlayerAlive(iEnt))
	{
		return false;
	}
	
	if (GetClientTeam(iEnt) != CS_TEAM_NC)
	{
		return false;
	}
	
	//PrintToChatAll("Hit player %N", iEnt);
	return true;
}

public Action ActivateTimer(Handle timer, Handle data)
{
	ResetPack(data);
	
	int ent = ReadPackCell(data);
	int ent_laser = ReadPackCell(data);
	
	if (!IsValidEntity(ent))
	{ 
		// mine was broken (gunshot/grenade) before it was armed
		return Plugin_Stop;
	}
	
	float vOrigin[3];
	GetEntPropVector(ent_laser, Prop_Send, "m_vecOrigin", vOrigin);
	//PrintToChatAll("Current Origin: %0.3f %0.3f %0.3f", vOrigin[0], vOrigin[1], vOrigin[2]);
	
	AcceptEntityInput(ent_laser, "TurnOn");
	
	SetEntityRenderColor(ent_laser, g_iMineLaserColor_Normal[0], g_iMineLaserColor_Normal[1], g_iMineLaserColor_Normal[2], g_iMineLaserColor_Normal[3]);
	//DispatchKeyValue(ent_laser, "TouchType", "4");
	
	SDKHook(ent_laser, SDKHook_ThinkPost, SDKCallback_ThinkPost_LaserBeam);
	
	EmitSoundToAllAny(g_szMineArmedSound, ent);
	
	return Plugin_Stop;
}

int CreateLaser(float start[3], float end[3])
{
	int beament = CreateEntityByName("env_beam");
	
	if (beament != -1)
	{
		DispatchKeyValue(beament, "targetname", g_szMineLaserTargetName);
		
		DispatchKeyValue(beament, "BoltWidth", "4.0");
		DispatchKeyValue(beament, "ClipStyle", "0");
		DispatchKeyValue(beament, "TouchType", "0"); // 0 = none, 1 = player only, 2 = NPC only, 3 = player or NPC, 4 = player, NPC or physprop
		DispatchKeyValue(beament, "damage", "0");
		DispatchKeyValue(beament, "spawnflags", "48"); // 0 disable, 1 = start on, etc etc. look from hammer editor
		DispatchKeyValue(beament, "decalname", "Bigshot");
		
		DispatchKeyValue(beament, "framerate", "0");
		DispatchKeyValue(beament, "framestart", "0");
		
		DispatchKeyValue(beament, "HDRColorScale", "1.0");
		DispatchKeyValue(beament, "life", "0"); // 0 = infinite, beam life time in seconds
		DispatchKeyValue(beament, "NoiseAmplitude", "0"); // straight beam = 0, other make noise beam
		DispatchKeyValue(beament, "Radius", "256");
		
		DispatchKeyValue(beament, "renderfx", "0");
		DispatchKeyValue(beament, "renderamt", "100");
		DispatchKeyValue(beament, "rendercolor", "0 0 0");
		
		DispatchKeyValue(beament, "StrikeTime", "1"); // If beam life time not infinite, this repeat it back
		DispatchKeyValue(beament, "TextureScroll", "30");
		
		SetEntityModel(beament, MODEL_BEAM);
		DispatchKeyValue(beament, "texture", MODEL_BEAM);
		
		//DispatchKeyValueVector(beament, "targetpoint", end); // Doesnt work!
		SetEntPropVector(beament, Prop_Data, "m_vecEndPos", end);
		
		SetEntProp(beament, Prop_Data, "m_nBeamType", 0);
		
		DispatchKeyValue(beament, "TouchType", "0");
		
		DispatchSpawn(beament);
		TeleportEntity(beament, start, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(beament);
		
		//AcceptEntityInput(beament, "TurnOff");
		
		SetEntityRenderColor(beament, g_iMineLaserColor_Normal[0], g_iMineLaserColor_Normal[1], g_iMineLaserColor_Normal[2], g_iMineLaserColor_Normal[3] / 2);
	}
	
	return beament;
}

public bool TraceFilter_Callback_PlaceLaser(int iEnt, int iContents, int iLaserEnt)
{
	if (iEnt == iLaserEnt)
	{
		return false;
	}
	
	if (0 < iEnt <= MaxClients)
	{
		return false;
	}
	
	return true;
}

void DeletePlacedMines()
{
	int ent = -1;
	char name[32];
	while ((ent = FindEntityByClassname(ent, "prop_physics_override")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", name, 32);
		if (StrEqual(name, g_szMineTargetName))
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
	
	while ((ent = FindEntityByClassname(ent, "env_beam")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", name, 32);
		if (StrEqual(name, g_szMineLaserTargetName))
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}

public Action FootstepCheck(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	// Player
	if (IsValidPlayer(entity))
	{
		if (StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1 || StrContains(sample, "land") != -1)
		{
			// Player not ninja, play footsteps
			if (GetClientTeam(entity) == CS_TEAM_SURVIVOR)
			{
				return Plugin_Continue;
			}
			
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public void OnPluginStart()
{
	CSetPrefix(g_szDefault_ChatPrefix);
	
	RegConsoleCmd("drop", Command_Teleport);
	RegConsoleCmd("+lookatweapon", Command_Teleport);
	//RegConsoleCmd("jointeam", Command_JoinTeam);
	
	//RegConsoleCmd("sm_shop", Command_DisplayShopMenu);
	
	RegConsoleCmd("sm_guns", Command_DisplayWeaponsMenu);
	RegConsoleCmd("sm_gun", Command_DisplayWeaponsMenu);
	
	RegConsoleCmd("sm_menu", Command_DisplayMainMenu);
	RegConsoleCmd("sm_modmenu", Command_DisplayMainMenu);
	RegConsoleCmd("sm_nc", Command_DisplayMainMenu);
	
	RegAdminCmd("sm_nc_reload", Command_ReloadSettings, ADMFLAG_ROOT);
	
	HookEvent("round_prestart", Event_RoundPreStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent(/*"decoy_detonate"*/"decoy_started", Event_DecoyDetonate, EventHookMode_Pre);
	
	//HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	
	AddCommandListener(Command_Join, "jointeam");
	
	g_iWeapons_Clip1Offset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	
	sv_footsteps = FindConVar("sv_footsteps");
	AddNormalSoundHook(FootstepCheck);
	
	char szConVars[][][] =  {
		{ "mp_buytime", "0" }, 
		//{ "sv_infinite_ammo", "2" },
		{ "mp_autoteambalance", "0" }, 
		{ "mp_limitteams", "0" }, 
		{ "mp_friendlyfire", "0" }, 
		//{ "mp_humanteam", "CT" }, 
		{ "sv_disable_immunity_alpha", "1" }, 
		{ "mp_give_player_c4", "0" }, 
		//{ "mp_teamname_2", "Nightcrawler" }, 
		//{ "mp_teamname_1", "Survivor" }, 
		{ "sv_buy_status_override", "3" }, 
		{ "ammo_grenade_limit_total", "999" }, 
		{ "ammo_grenade_limit_default ", "999" },
		{ "mp_weapons_allow_map_placed", "0" }
	};
	
	ConVar Var;
	for (int i; i < sizeof szConVars; i++)
	{
		Var = CreateConVar(szConVars[i][0], "", "");
		SetConVarString(Var, szConVars[i][1], true, false);
		//SetConVarFlags(Var, FCVAR_PROTECTED);
		HookConVarChange(Var, ConVarChangedCallback_ModRequiredConVars);
	}
	
	// InfiniteAmmo
	g_Trie_WeaponsBPAmmo = new StringMap();
}

public Action Event_PlayerTeam(Event event, const char[] szName, bool bDontBroadcast)
{
	// Block 'Player is joining the Terrorist force' chat message
	return Plugin_Handled;
}

public Action Command_Join(int client, const char[] command, int argc)
{
	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int NewTeam = StringToInt(arg);
	int OldTeam = GetClientTeam(client);
	
	if ((OldTeam == CS_TEAM_T || OldTeam == CS_TEAM_CT) && NewTeam != CS_TEAM_SPECTATOR)
	{
		CPrintToChat(client, "You cannot change teams.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_ReloadSettings(int client, int args)
{
	LoadSettingsFromFile();
	
	CReplyToCommand(client, "* Reloaded NightCrawlers settings file!");
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!strcmp(classname, "decoy_projectile"))
	{
		//SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
		
		BeamFollowCreate(entity, g_iFrostGrenadeBeamFollowColor);
		
		//int entref = EntIndexToEntRef(entity);
		//CreateTimer(g_flFrostGrenadeActivationDelay, CreateEvent_DecoyDetonate, entref, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void BeamFollowCreate(int entity, int color[4])
{
	TE_SetupBeamFollow(entity, g_iFrostGrenadeBeamIndex_Sprite1, 0, 1.0, 10.0, 10.0, 5, color);
	TE_SendToAll();
}

/*
public Action CreateEvent_DecoyDetonate(Handle timer, any entref)
{
	int entity = EntRefToEntIndex(entref);
	
	if (!IsValidEdict(entity))
	{
		return;
	}
	
	char classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));
	if (!strcmp(classname, "decoy_projectile", false))
	{
		float origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		int userid = GetClientUserId(GetEntPropEnt(entity, Prop_Send, "m_hThrower"));
		
		Handle event = CreateEvent("decoy_detonate");
		
		SetEventInt(event, "userid", userid);
		SetEventFloat(event, "x", origin[0]);
		SetEventFloat(event, "y", origin[1]);
		SetEventFloat(event, "z", origin[2]);
		FireEvent(event);
	}
	
	return;
}*/

public Action Event_DecoyDetonate(Event event, const char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(event.GetInt("userid"));
	
	float origin[3];
	origin[0] = event.GetFloat("x");
	origin[1] = event.GetFloat("y");
	origin[2] = event.GetFloat("z");
	
	int index = MaxClients + 1;
	
	float xyz[3];
	
	while ((index = FindEntityByClassname(index, "decoy_projectile")) != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", xyz);
		if (xyz[0] == origin[0] && xyz[1] == origin[1] && xyz[2] == origin[2])
		{
			AcceptEntityInput(index, "kill");
		}
	}
	
	origin[2] += 10.0;
	float targetOrigin[3];
	
	Handle trace = null;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		if (GetClientTeam(i) != CS_TEAM_NC)
		{
			continue;
		}
		
		GetClientAbsOrigin(i, targetOrigin);
		targetOrigin[2] += 2.0;
		if (GetVectorDistance(origin, targetOrigin) <= g_flFrostGrenadeRadius)
		{
			trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, TraceHandle_FrostFilterTarget, i);
			
			if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
			{
				FreezeClient(i, g_flFrostGrenadeFreezeDuration);
				delete trace;
			}
			
			else
			{
				delete trace;
				
				GetClientEyePosition(i, targetOrigin);
				targetOrigin[2] -= 2.0;
				
				trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, TraceHandle_FrostFilterTarget, i);
				
				if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= g_flFrostGrenadeRadius - 100.0))
				{
					FreezeClient(i, g_flFrostGrenadeFreezeDuration);
				}
				
				delete trace;
			}
		}
	}
	
	TE_SetupBeamRingPoint(origin, 10.0, 200.0, g_iFrostGrenadeBeamIndex_Sprite2, g_iFrostGrenadeHaloSprite, 1, 1, 0.2, 100.0, 1.0, g_iFrostGrenadeBeamFollowColor, 0, 0);
	TE_SendToAll();
	
	LightCreate(origin);
}

public void LightCreate(float pos[3])
{
	int iEntity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	DispatchKeyValue(iEntity, "_light", "75 75 255 255");
	DispatchKeyValueFloat(iEntity, "distance", 200.0);
	
	EmitSoundToAllAny(FROST_FREEZE_SOUND, iEntity, SNDCHAN_WEAPON);
	
	CreateTimer(0.2, Timer_DeleteFrostGrenadeLightEnt, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
	DispatchSpawn(iEntity);
	
	TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(iEntity, "TurnOn");
}

public Action Timer_DeleteFrostGrenadeLightEnt(Handle hTimer, int entref)
{
	int entity = EntRefToEntIndex(entref);
	if (IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "kill");
	}
}

void FreezeClient(int client, float time)
{
	if (g_hTimer_Freeze[client] != null)
	{
		KillTimer(g_hTimer_Freeze[client]);
		g_hTimer_Freeze[client] = null;
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	
	float vec[3];
	GetClientEyePosition(client, vec);
	vec[2] -= 50.0;
	EmitAmbientSoundAny(FROST_GLASS_IMPACT_SOUND, vec, client, SNDLEVEL_RAIDSIREN);
	TE_SetupGlowSprite(vec, g_iFrostGrenadeGlowSprite, time, 2.0, 50);
	TE_SendToAll();
	
	vec[2] -= 10.0;
	int ent;
	if ((ent = CreateEntityByName("prop_dynamic")) != -1)
	{
		DispatchKeyValue(ent, "model", FROST_ICECUBE_MODEL);
		DispatchKeyValue(ent, "solid", "0");
		DispatchKeyValueVector(ent, "origin", vec);
		DispatchSpawn(ent);
		
		ent = EntIndexToEntRef(ent);
	}
	
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(ent);
	pack.WriteCell(g_bDontShowPlayer[client]);
	
	g_bIsFrozen[client] = true;
	g_bDontShowPlayer[client] = false;
	
	g_hTimer_Freeze[client] = CreateTimer(time, Timer_UnfreezeClient, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

public Action Timer_UnfreezeClient(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int ent = pack.ReadCell();
	bool bDontShow = pack.ReadCell();
	
	// Auto delete from flags
	//delete pack;
	
	if (g_hTimer_Freeze[client] == timer)
	{
		g_hTimer_Freeze[client] = null;
	}
	
	ent = EntRefToEntIndex(ent);
	UnFreezeClient(client, ent);
	
	g_bDontShowPlayer[client] = bDontShow;
}

void UnFreezeClient(int client, int ent)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	g_bIsFrozen[client] = false;
		
	if (IsValidEdict(ent))
	{
		AcceptEntityInput(ent, "Kill");
	}
}

public bool TraceHandle_FrostFilterTarget(int entity, int contentsMask, any data)
{
	return (data == entity);
}

public void ConVarChangedCallback_ModRequiredConVars(ConVar convar, char[] oldValue, char[] newValue)
{
	UnhookConVarChange(convar, ConVarChangedCallback_ModRequiredConVars);
	SetConVarString(convar, oldValue, true);
	HookConVarChange(convar, ConVarChangedCallback_ModRequiredConVars);
}

public void OnMapStart()
{
	g_hTimer_HintMessage = null; // Handle deleted from flags
	
	if (!g_iGrenadeOffsets[0])
	{
		int end = sizeof(g_szGrenadeWeaponNames);
		for (int i = 0; i < end; i++)
		{
			int entindex = CreateEntityByName(g_szGrenadeWeaponNames[i]);
			DispatchSpawn(entindex);
			g_iGrenadeOffsets[i] = GetEntProp(entindex, Prop_Send, "m_iPrimaryAmmoType");
			AcceptEntityInput(entindex, "Kill");
		}
	}
	
	LoadSettingsFromFile();
	PrecacheFiles();
	
	int iLen = 0;
	g_iTotalDashCount = RoundFloat(g_flDetector_Radius / g_flDetector_UnitsPerChar);
	
	while (iLen < g_iTotalDashCount)
	{
		g_szDefaultDetectorText[iLen++] = CHAR_DASH;
	}
	
	g_szDefaultDetectorText[iLen] = 0;
	
	g_bRunning = false;
	
	// Light?
	SetLightStyle(0, g_szLightStyle);
	
	if (g_bMakeFog)
	{
		// Make Fog
		g_iFogEnt = CreateFog();
	}
	
	if (g_bRemoveShadows)
	{
		// Remove Shadows
		CreateEntityByName("shadow_control");
		int iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "shadow_control")) != -1)
		{
			// I hope I'm doing it right 
			// Also may not work because "This feature is only available in the Half Life 2 engine" 
			SetVariantInt(1);
			AcceptEntityInput(iEnt, "SetShadowsDisabled");
		}
	}
	
	g_hTimer_CheckGameState = CreateTimer(10.0, Timer_CheckGameState, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	Timer_CheckGameState(g_hTimer_CheckGameState);
	
	if (g_bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				//esht'3l allah yr'90a 3lek
				OnClientPutInServer(i);
			}
		}
	}
	
}

public void OnMapEnd()
{
	g_bRunning = false;
	
	delete g_hTimer_CheckGameState;
	
	if(IsValidEdict(g_iFogEnt))
	{
		//RemoveEdict(g_iFogEnt);
		AcceptEntityInput(g_iFogEnt, "Kill");
	}	
}

public void OnConfigsExecuted()
{
	//LoadSettingsFromFile();
}

public void OnClientDisconnect(int client)
{
	GiveLaser(client, false);
	CheckLastSurvivor();
	
	MakeHooks(client, false);
	
	//if(g_bIsInNCQueue[param1]) // allow more than once?
	{
		for (int i; i < g_iNCQueueCount; i++)
		{
			if (g_Array_NCQueue.Get(i) == client)
			{
				g_Array_NCQueue.Erase(i);
				g_iNCQueueCount--;
			}
		}
	}
	
	g_bIsInNCQueue[client] = false;
	
	if(g_hTimer_Freeze[client] != null)
	{
		KillTimer(g_hTimer_Freeze[client], true);
		g_hTimer_Freeze[client] = null;
	}
}

public void OnClientPutInServer(int client)
{
	g_iLastWeapons[client][0] = -1;
	g_iLastWeapons[client][1] = -1;
	g_bSaveLastWeapons[client] = false;
	g_bHasChosenWeaponsThisRound[client] = false;
	
	if (!IsFakeClient(client))
	{
		SendConVarValue(client, sv_footsteps, "0");
	}
	
	ResetVars(client, true);
	MakeHooks(client, true);
	
	SetVariantString("MyFog");
	AcceptEntityInput(client, "SetFogController");
}

public void Event_WeaponFire(Handle event, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (g_bAdrenalineActivated[client])
	{
		SetEntData(iEnt, g_iWeapons_Clip1Offset, GetEntData(iEnt, g_iWeapons_Clip1Offset) + 1, true);
	}
	
	if(g_bInfiniteBPAmmo)
	{
		GiveInfiniteBPAmmo(client);
	}
}

void GiveInfiniteBPAmmo(int client)
{
	if(IsPlayerAlive(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if(weapon > 0 && (weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)))
		{
			int iMaxBPAmmo;
			char szClassName[4];
			Format(szClassName, sizeof szClassName, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			
			if(GetTrieValue(g_Trie_WeaponsBPAmmo, szClassName, iMaxBPAmmo))
			{
				if(GetReserveAmmo(weapon) != iMaxBPAmmo) 
				{
					SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iMaxBPAmmo);
				}
			}
		}
	}
}

stock int GetReserveAmmo(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}

void CacheWeaponBPAmmo(int client, int weapon)
{
	if(weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY))
	{
		int iMaxBPAmmo;
		char szClassName[4];
		//GetEdictClassname(weapon, classname, sizeof(classname));
		Format(szClassName, sizeof szClassName, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
	
		if(!GetTrieValue(g_Trie_WeaponsBPAmmo, szClassName, iMaxBPAmmo))
		{
			iMaxBPAmmo = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		
			SetTrieValue(g_Trie_WeaponsBPAmmo, szClassName, iMaxBPAmmo);
		}
	}
}

// --------------------------------------------------------------------------
//						Registered Commands callbacks
// --------------------------------------------------------------------------
public Action Command_DisplayMainMenu(int client, int iArgCount)
{
	DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
}

public Action Command_DisplayWeaponsMenu(int client, int iArgCount)
{
	if (!CanDisplayWeaponMenu(client, true))
	{
		return;
	}
	
	DisplayMenu(g_hWeaponMenu_Main, client, MENU_TIME_FOREVER);
}

bool CanDisplayWeaponMenu(int client, bool bPrintChat = false)
{
	if (IsPlayerAlive(client))
	{
		if (GetGameTime() > g_flWeaponMenuExpireTime)
		{
			if (bPrintChat)
			{
				CPrintToChat(client, "Choosing weapons time has expired. You won't be able to choose new weapons until you die or next round.");
			}
			
			return false;
		}
		
		if (g_bHasChosenWeaponsThisRound[client])
		{
			if (bPrintChat)
			{
				CPrintToChat(client, "You have already chosen weapons for this round.");
			}
			
			return false;
		}
	}
	
	return true;
}

bool CanDisplayItemMenu(int client, bool bPrintChat = false)
{
	if (!IsPlayerAlive(client))
	{
		if (bPrintChat)
		{
			CPrintToChat(client, "Shop is only available to alive players.");
		}
		
		return false;
	}
	
	if (GetClientTeam(client) != CS_TEAM_SURVIVOR)
	{
		if (bPrintChat)
		{
			CPrintToChat(client, "Shop is only available to survivors.");
		}
		
		return false;
	}
	
	if (g_bHasChosenItemThisRound[client])
	{
		if (bPrintChat)
		{
			CPrintToChat(client, "You have already chosen an item for this round.");
		}
		
		return false;
	}
	
	return true;
}

bool CanDisplayShopMenu(int client, bool bPrintChat = false)
{
	if (!IsPlayerAlive(client))
	{
		if (bPrintChat)
		{
			CPrintToChat(client, "Shop is only available to alive players.");
		}
		
		return false;
	}
	
	if (GetClientTeam(client) != CS_TEAM_SURVIVOR)
	{
		if (bPrintChat)
		{
			CPrintToChat(client, "Shop is only available to survivors.");
		}
		
		return false;
	}
	
	return true;
}

public Action Command_DisplayShopMenu(int client, int iArgCount)
{
	if (!CanDisplayShopMenu(client, true))
	{
		return;
	}
	
	DisplayMenu(g_hShopMenu, client, MENU_TIME_FOREVER);
}

public Action Command_JoinTeam(int client, int iArgs)
{
	char szArg[3];
	GetCmdArg(1, szArg, sizeof szArg);
	
	int iJoinTeam = StringToInt(szArg);
	int iTeam = GetClientTeam(client);
	
	if (iJoinTeam == iTeam)
	{
		return Plugin_Continue;
	}
	
	if (iTeam == CS_TEAM_NONE || iTeam == CS_TEAM_SPECTATOR)
	{
		if (iJoinTeam == CS_TEAM_SPECTATOR || iJoinTeam == CS_TEAM_SURVIVOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	if (iTeam == CS_TEAM_NC)
	{
		if (iJoinTeam == CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
	if (GetClientTeam(client) == CS_TEAM_NC && IsPlayerAlive(client))
	{
		if (g_flPlayerMana[client] > g_flManaTeleportCost || g_bRoundEnd)
		{
			if (TeleportClient(client))
			{
				if (!g_bRoundEnd)
				{
					g_flPlayerMana[client] -= g_flManaTeleportCost;
				}
			}
			
			else CPrintToChat(client, "Teleport failed. Try to aim somewhere else");
		}
		
		else CPrintToChat(client, "You are missing %0.1f %s to teleport", g_flManaTeleportCost - g_flPlayerMana[client], g_szManaName);
	}
}

public void SDKHookCallback_OnPostThinkPost(int client)
{
	static float flGameTime;
	flGameTime = GetGameTime();
	switch (GetClientTeam(client))
	{
		case CS_TEAM_NC:
		{
			if (g_flNextManaGain[client] < flGameTime)
			{
				g_flNextManaGain[client] = flGameTime + g_flManaRegenTime;
				
				if (g_flPlayerMana[client] < g_flMaxMana)
				{
					if (g_flPlayerMana[client] + g_flManaRegenAmount > g_flMaxMana)
					{
						g_flPlayerMana[client] = g_flMaxMana;
					}
					
					else g_flPlayerMana[client] += g_flManaRegenAmount;
				}
			}
			
			static int buttons;
			if ( (buttons = GetClientButtons(client) ) & IN_USE)
			{
				DoClimb(client);
				/*bool IsNearWall = false;
				bool IsNearCeiling = false;
				
				Handle traceRay;
				float testVector[3];
				float testPosition[3];
				float testEndPosition[3];
				GetClientAbsOrigin(client, testPosition);
				testPosition[2] += 20.0;
				for (int i = 0; i < 360; i += 30)
				{
					testVector[1] = float(i);
					traceRay = TR_TraceRayFilterEx(testPosition, testVector, MASK_SOLID, RayType_Infinite, TraceFilter_Callback, client);
					if (TR_DidHit(traceRay))
					{
						TR_GetEndPosition(testEndPosition, traceRay);
						
						if (GetVectorDistance(testEndPosition, testPosition) <= 25.0)
						{
							IsNearWall = true;
							SetEntityGravity(client, 0.5 * GetEntityGravity(client));
							CloseHandle(traceRay);
							break;
						}
					}
					CloseHandle(traceRay);
					
				}
				if (!IsNearWall)
				{
					GetClientEyePosition(client, testPosition);
					testVector = testPosition;
					testVector[2] += 25.0;
					traceRay = TR_TraceRayFilterEx(testPosition, testVector, MASK_SOLID, RayType_EndPoint, TraceFilter_Callback, client);
					if (TR_DidHit(traceRay))
					{
						IsNearCeiling = true;
					}
					CloseHandle(traceRay);
				}
				
				if (!IsNearWall && !IsNearCeiling)
				{
					return;
				}
				if (IsNearWall || IsNearCeiling)
				{
					float velocity[3];
					float eyeAngles[3];
					SetEntityMoveType(client, MOVETYPE_WALK);
					GetClientEyeAngles(client, eyeAngles);
					bool noTranslationMade = true;
					if (buttons & IN_FORWARD)
					{
						velocity[0] += (300.0 * Cosine(DegToRad(eyeAngles[1])));
						velocity[1] += (300.0 * Sine(DegToRad(eyeAngles[1])));
						velocity[2] += -(300.0 * Sine(DegToRad(eyeAngles[0])));
						noTranslationMade = false;
					}
					else if (buttons & IN_BACK)
					{
						velocity[0] += -(200.0 * Cosine(DegToRad(eyeAngles[1])));
						velocity[1] += -(200.0 * Sine(DegToRad(eyeAngles[1])));
						velocity[2] += (200.0 * Sine(DegToRad(eyeAngles[0])));
						noTranslationMade = false;
					}
					if (buttons & IN_MOVERIGHT)
					{
						velocity[0] += (200.0 * Cosine(DegToRad(eyeAngles[1] - 90.0)));
						velocity[1] += (200.0 * Sine(DegToRad(eyeAngles[1] - 90.0)));
						noTranslationMade = false;
					}
					else if (buttons & IN_MOVELEFT)
					{
						velocity[0] += (200.0 * Cosine(DegToRad(eyeAngles[1] + 90)));
						velocity[1] += (200.0 * Sine(DegToRad(eyeAngles[1] + 90)));
						noTranslationMade = false;
					}
					if (noTranslationMade)
					{
						SetEntityMoveType(client, MOVETYPE_NONE);
						velocity[0] = velocity[1] = velocity[2] = 0.0;
					}
					SetEntityGravity(client, 1.5e-45);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
				}
				else
				{
					SetEntityMoveType(client, MOVETYPE_WALK);
					SetEntityGravity(client, g_flNCGravityMultiplier);
				}*/
			}
		}
		
		case CS_TEAM_SURVIVOR:
		{
			MoveLaserEnt(client);
			
			if (g_bAdrenalineActivated[client])
			{
				ModifyAttackSpeed(client);
			}
		}
	}
}

public bool TraceFilter_Callback(int iEnt, int iContentMask, int client)
{
	if (iEnt == client)
	{
		return false;
	}
	
	return true;
}

// --------------------------------------------------------------------------
//								Events
// --------------------------------------------------------------------------
public void Event_PlayerSpawn(Event event, char[] szEventName, bool bDontBroadcast)
{
	RequestFrame(Frame_DoSpawnStuff, GetEventInt(event, "userid"));
}

public void Frame_DoSpawnStuff(int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if (GetClientTeam(client) == CS_TEAM_NC)
	{
		CS_RemoveWeapon(client, -1, false, true);
		
		GivePlayerItem(client, "weapon_knife");
		
		if(g_iNightcrawlerModelsCount)
		{
			int iIndex = GetRandomInt(0, g_iNightcrawlerModelsCount - 1);
			char szModel[PLATFORM_MAX_PATH];
			
			g_Array_NightcrawlerModels.GetString(iIndex, szModel, sizeof szModel);
			
			if (szModel[0])
			{
				SetEntityModel(client, szModel);
			}
		}
		
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 200, 0, 200);
		g_bDontShowPlayer[client] = true;
		
		CPrintToChat(client, "You are a %s", g_szNCName);
		CPrintToChat(client, "You are invisible; You invisibility will break if you get shot!");
		CPrintToChat(client, "Your objective is to kill the %ss", g_szSurvivorName);
		CPrintToChat(client, "You can press G or F to teleport (drop weapon or inspect) or E to climb walls (+use key)");
		
		SetEntityGravity(client, g_flNCGravityMultiplier);
		SetClientSpeed(client, g_flNCSpeedMultiplier);
		SetEntityHealth(client, RoundFloat(g_flNCStartingHealth));
	}
	
	else
	{
		if(g_iSurvivorModelsCount)
		{
			int iIndex = GetRandomInt(0, g_iSurvivorModelsCount - 1);
			char szModel[PLATFORM_MAX_PATH];
			
			g_Array_SurvivorModels.GetString(iIndex, szModel, sizeof szModel);
			
			if (szModel[0])
			{
				SetEntityModel(client, szModel);
			}
		}
		
		CPrintToChat(client, "You are a %s", g_szSurvivorName);
		CPrintToChat(client, "You objective is to kill the %ss", g_szNCName);
		//CPrintToChat(client, "You can press G to teleport (drop weapon button) or E to climb walls (+use key)");
		CPrintToChat(client, "Use your items to assist you to complete your objective.");
		
		SetEntityGravity(client, 1.0);
		SetClientSpeed(client, 1.0);
		
		// Reset Colors
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client);
		
		g_bDontShowPlayer[client] = false;
		
		if (g_bSaveLastWeapons[client])
		{
			GiveLastWeapons(client);
			DisplayMenu(g_hItemMenu, client, MENU_TIME_FOREVER);
		}
		
		else
		{
			if (CanDisplayWeaponMenu(client, true))
			{
				g_iWeaponMenuStep[client] = WEAPONTYPE_PRIMARY;
				DisplayMenu(g_hWeaponMenu_Main, client, MENU_TIME_FOREVER);
			}
		}
	}
}

public void Event_RoundPreStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_flWeaponMenuExpireTime = GetGameTime() + g_flChooseWeaponTime;
	SetArrayValue(g_bHasChosenWeaponsThisRound, sizeof g_bHasChosenWeaponsThisRound, false);
}

public void Event_RoundStart(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_bRoundEnd = false;
	PluginLog("RoundStart #1");
	
	DeletePlacedMines();
	
	int iHumans[MAXPLAYERS + 1];
	int iCount;
	
	PluginLog("RoundStart #2");
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!(IsClientInGame(client) && IsPlayerAlive(client)))
		{
			continue;
		}
		
		ResetVars(client, false);
		
		switch (GetClientTeam(client))
		{
			case CS_TEAM_NC:
			{
				g_flPlayerMana[client] = g_flMaxMana;
				g_bDontShowPlayer[client] = true;
			}
			
			case CS_TEAM_SURVIVOR:
			{
				iHumans[iCount++] = client;
			}
		}
	}
	
	/*if (!g_bRunning)
	{
		return;
	}*/
	
	PluginLog("RoundStart #3");
	Timer_HintMessage(g_hTimer_HintMessage);
	g_hTimer_HintMessage = CreateTimer(HINTMSG_UPDATE_TIME, Timer_HintMessage, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	
	CreateTimer(0.5, Timer_RoundStart_GiveLasers, _, TIMER_FLAG_NO_MAPCHANGE);
	
	PluginLog("RoundStart #4");
}

public Action Timer_RoundStart_GiveLasers(Handle hTimer)
{
	GiveLasersOnRoundStart();
	CheckLastSurvivor();
}

public void Event_RoundEnd(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_bRoundEnd = true;
	
	if(g_hTimer_HintMessage != null)
	{
		delete g_hTimer_HintMessage;
		g_hTimer_HintMessage = null;
	}
	
	if (!g_bRunning)
	{
		return;
	}
	
	ChooseNCPlayers();
}

public void Event_PlayerDeath(Event event, char[] szEventName, bool bDontBroadcast)
{
	int iKiller = GetClientOfUserId(GetEventInt(event, "attacker"));
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(iVictim) == CS_TEAM_SURVIVOR)
	{
		if (g_bSuicideBombActivated[iVictim])
		{
			GetClientEyePosition(iVictim, g_vDeathPosition[iVictim]);
		}
		
		if (g_bLaser[iVictim])
		{
			GiveLaser(iVictim, false);
		}
		
		CheckLastSurvivor();
	}
	
	else
	{
		EmitSoundToAllAny(g_szNightcrawlerDeathSound[GetRandomInt(0, sizeof(g_szNightcrawlerDeathSound) - 1)], iVictim);
	}
	
	if (IsValidPlayer(iKiller) && iKiller != iVictim)
	{
		switch (GetClientTeam(iKiller))
		{
			case CS_TEAM_NC:
			{
				g_iPlayerPoints[iKiller] += g_iPointsPerKill_NC;
				
				//PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", g_iPointsPerKill_NC, g_szSurvivorName);
				
				SetEntProp(iKiller, Prop_Data, "m_iFrags", GetEntProp(iKiller, Prop_Data, "m_iFrags") - 1); // Do not count kills while playing NC
			}
			
			case CS_TEAM_SURVIVOR:
			{
				g_bKilledNC[iKiller] = true;
				int iPointsAdded = g_iPointsPerKill_Survivor;
				
				if (GetEventInt(event, "headshot"))
				{
					iPointsAdded += g_iPointsHSBonus;
				}
				
				g_iPlayerPoints[iKiller] += g_iPointsHSBonus;
				//PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", iPointsAdded, g_szNightcrawlerName);
			}
		}
	}
}
// --------------------------------------------------------------------------
//								SDK Hooks
// --------------------------------------------------------------------------

void MakeHooks(int client, bool bStatus)
{
	if (bStatus)
	{
		SDKHook(client, SDKHook_OnTakeDamage, SDKHookCallback_OnTakeDamage);
		SDKHook(client, SDKHook_SetTransmit, SDKHookCallback_SetTransmit);
		
		SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKHookCallback_WeaponSwitch);
		SDKHook(client, SDKHook_WeaponCanUse, SDKHookCallback_WeaponSwitch);
		SDKHook(client, SDKHook_WeaponEquip, SDKHookCallback_WeaponSwitch);
		SDKHook(client, SDKHook_WeaponEquipPost , SDKHookCallback_WeaponEquipPost);
		
		SDKHook(client, SDKHook_PostThinkPost, SDKHookCallback_OnPostThinkPost);
	}
	
	else
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, SDKHookCallback_OnTakeDamage);
		SDKUnhook(client, SDKHook_SetTransmit, SDKHookCallback_SetTransmit);
		
		SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDKHookCallback_WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponCanUse, SDKHookCallback_WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponEquip, SDKHookCallback_WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponEquipPost , SDKHookCallback_WeaponEquipPost);
		
		SDKUnhook(client, SDKHook_PostThinkPost, SDKHookCallback_OnPostThinkPost);
	}
}

public Action SDKHookCallback_WeaponSwitch(int client, int iWeapon)
{
	if (GetClientTeam(client) == CS_TEAM_NC)
	{
		char szWeaponName[35];
		GetEntityClassname(iWeapon, szWeaponName, sizeof szWeaponName);
		
		if (!StrEqual(szWeaponName, "weapon_knife"))
		{
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public void SDKHookCallback_WeaponEquipPost(int client, int iWeapon)
{
	if(g_bInfiniteBPAmmo)
	{
		CacheWeaponBPAmmo(client, iWeapon);
	}
}

public Action SDKHookCallback_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (GetClientTeam(victim) == CS_TEAM_NC)
	{
		if (damagetype & DMG_FALL)
		{
			if (g_bBlockFallDamage_NC)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
		else
		{
			g_bDontShowPlayer[victim] = false;
			CreateTimer(g_flNCVisibleTime, Timer_MakeNCInvisibleAgain, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		return Plugin_Continue;
	}
	
	else
	{
		// Do something about blocking back stab damage
	}
	
	return Plugin_Continue;
}

public Action SDKHookCallback_SetTransmit(int client, int viewer)
{
	if (client == viewer)
	{
		return Plugin_Continue;
	}
	
	if (g_bRoundEnd)
	{
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(viewer))
	{
		return Plugin_Continue;
	}
	
	/*if (GetClientTeam(client) == GetClientTeam(viewer))
	{
		return Plugin_Continue;
	}*/
	
	if (g_bDontShowPlayer[client] && g_bDontShowPlayer[viewer])
	{
		return Plugin_Continue;
	}
	
	if (g_bDontShowPlayer[client])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// --------------------------------------------------------------------------
//								Menu Stuff
// --------------------------------------------------------------------------
void BuildMenus()
{
	BuildMainMenu();
	BuildWeaponsMenu();
	BuildItemMenu();
	//BuildShopMenu();
}


void BuildItemMenu()
{
	g_hItemMenu = CreateMenu(MenuHandler_ItemMenu, MENU_ACTIONS_ALL);
	
	SetMenuTitle(g_hItemMenu, "Choose an item:");
	
	char szInfo[3];
	for (int i; i < MAX_PLAYER_ITEMS; i++)
	{
		IntToString(i, szInfo, sizeof szInfo);
		
		AddMenuItem(g_hItemMenu, szInfo, g_iItemsData[i][PlayerItem_Name]);
	}
}

/*
enum
{
	ITEM_LASER,
	ITEM_MINES,
	ITEM_ADRENALINE,
	ITEM_SUICIDEBOMB,
	ITEM_DETECTOR,
	ITEM_FROSTNADE
};
*/
public int MenuHandler_ItemMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End || action == MenuAction_Cancel)
	{
		return 0;
	}
	
	char szInfo[3];
	int iItemIndex;
	
	GetMenuItem(menu, param2, szInfo, sizeof szInfo);
	iItemIndex = StringToInt(szInfo);
	
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			if (!g_iItemsData[iItemIndex][PlayerItem_Enabled])
			{
				return ITEMDRAW_DISABLED;
			}
			
			if (iItemIndex == ITEM_LASER)
			{
				if(g_iLaserMode == LMODE_MENU)
				{
					if(g_iLaserCarriersCount < g_iCalculatedMaxLaserCount)
					{
						return ITEMDRAW_DEFAULT;
					}
				}
				
				return ITEMDRAW_DISABLED;
			}
			
			if (iItemIndex == ITEM_LASERMINE && g_iMineCount >= g_iMineMaxPlayers)
			{
				return ITEMDRAW_DISABLED;
			}
			
			if (iItemIndex == ITEM_DETECTOR && g_iDetectorCount >= g_iDetectorMaxPlayers)
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_DisplayItem:
		{
			if(iItemIndex == ITEM_LASER)
			{
				char szDispName[60];
				if(g_iLaserMode == LMODE_KILL)
				{
					FormatEx(szDispName, sizeof szDispName, "%s [Highest Kills Only]", g_iItemsData[iItemIndex][PlayerItem_Name]);
					return RedrawMenuItem(szDispName);
				}
				
				if(g_iLaserMode == LMODE_RANDOM)
				{
					FormatEx(szDispName, sizeof szDispName, "%s [Given Randomly]", g_iItemsData[iItemIndex][PlayerItem_Name]);
					return RedrawMenuItem(szDispName);
				}
				
				return RedrawMenuItem(g_iItemsData[iItemIndex][PlayerItem_Name]);
			}
			
			return 0;
		}
		
		case MenuAction_Select:
		{
			if (GetClientTeam(param1) != CS_TEAM_SURVIVOR || !IsPlayerAlive(param1))
			{
				return 0;
			}
			
			if (!GiveClientItem(param1, iItemIndex, true, false, 0))
			{
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
		}
	}
	
	return 0;
}

bool GiveClientItem(int client, int iItemIndex, bool bPrintChatMessages, bool bFree, int iAdminId)
{
	bool bSuccess = true;
	switch (iItemIndex)
	{
		case ITEM_LASER:
		{
			/*
			if (g_iChooseLaserPlayersMode != LASERMODE_MENU)
			{
				if (!bFree)
				{
					bSuccess = false;
				}
			}
			*/
			if (g_iLaserCarriersCount >= g_iCalculatedMaxLaserCount)
			{
				PrintToServer("Curr %d - Max %d", g_iLaserCarriersCount, g_iCalculatedMaxLaserCount);
				bSuccess = false;
			}
			
			else
			{
				g_iLaserCarriersCount++;
				GiveLaser(client, true);
			}
		}
		
		case ITEM_LASERMINE:
		{
			if (g_iMineCount >= g_iMineMaxPlayers)
			{
				bSuccess = false;
			}
			
			else GiveMines(client);
		}
		
		case ITEM_ADRENALINE:
		{
			GiveAdrenaline(client);
		}
		
		case ITEM_SUICIDEBOMB:
		{
			GiveSuicideBomb(client);
		}
		
		case ITEM_DETECTOR:
		{
			GiveDetector(client);
		}
		
		case ITEM_HEGRENADE:
		{
			GiveHeGrenades(client);
		}
		
		case ITEM_FROSTGRENADE:
		{
			GiveFrostGrenades(client);
		}
	}
	
	if (bPrintChatMessages)
	{
		PrintItemGiveChatMessages(client, iItemIndex, bSuccess, bFree, iAdminId);
	}
	
	if (!bFree)
	{
		g_bHasChosenItemThisRound[client] = true;
	}
	
	return bSuccess;
}

void PrintItemGiveChatMessages(int client, int iItem, bool bSuccess, int bFree, int iAdminId)
{
	switch (iItem)
	{
		case ITEM_LASER:
		{
			if (bFree)
			{
				CPrintToChat(client, "ADMIN %N has given you a free Laser!", iAdminId);
			}
			
			if (!bSuccess)
			{
				CPrintToChat(client, "This item has maxed out.");
			}
			
			else
			{
				CPrintToChat(client, "You have the laser. If you aim at a %s, it will change the color!", g_szNCName);
			}
		}
		
		case ITEM_LASERMINE:
		{
			if (bFree)
			{
				CPrintToChat(client, "ADMIN %N has given you a free Laser Mine (%d)!", iAdminId, g_iMineGiveCount);
			}
			
			if (!bSuccess)
			{
				CPrintToChat(client, "This item has maxed out.");
			}
			
			else
			{
				CPrintToChat(client, "You have (%d) laser mines. Place them on the wall by holding +use key (default: E)", g_iMineGiveCount);
				CPrintToChat(client, "When a %s touches the laser of the mine, a voice will be heard!", g_szNCName);
			}
		}
		
		case ITEM_SUICIDEBOMB:
		{
			if (bFree)
			{
				CPrintToChat(client, "ADMIN %N has given you a free Suicide Bomb!", iAdminId);
			}
			
			CPrintToChat(client, "You have the suicide bomb! Press +use key to activate it! (default: E)");
		}
		
		case ITEM_ADRENALINE:
		{
			if (bFree)
			{
				CPrintToChat(client, "ADMIN %N has given you a free Adrenaline!", iAdminId);
			}
			
			CPrintToChat(client, "You have the adrenaline! It will help you run and shoot faster with infinite clip ammo, and gain health as well!");
			CPrintToChat(client, "Press +use key to inject yourself with Adrenaline! (default: E)");
		}
		
		case ITEM_DETECTOR:
		{
			if (bFree)
			{
				CPrintToChat(client, "ADMIN %N has given you a free detector!", iAdminId);
			}
			
			if (!bSuccess)
			{
				CPrintToChat(client, "This item has maxed out.");
			}
			
			else
			{
				CPrintToChat(client, "You have the detector! It will update every %0.2f seconds.", g_flDetectorUpdateTime);
				CPrintToChat(client, "If a %s is close to you, the detector will indicate with bars and a color ( ||||| )", g_szNCName);
			}
		}
		
		case ITEM_HEGRENADE:
		{
			if (bFree)
			{
				CPrintToChat(client, "ADMIN %N has given you a free hegrenade!", iAdminId);
			}
			
			if (!bSuccess)
			{
				CPrintToChat(client, "This item has maxed out.");
			}
			
			else
			{
				CPrintToChat(client, "You have (%d) Hegrenades! You will get %d extra Hegrenades every %0.1f seconds.", g_iHegrenadeGiveAmount, g_iHegrenadeRegenAmount, g_flHegrenadeRegenTime);
			}
		}
	}
}

void GiveMines(int client)
{
	g_iPlayerMinesCount[client] = g_iMineGiveCount;
}

void GiveSuicideBomb(int client)
{
	g_bHasSuicideBomb[client] = true;
}

void GiveDetector(int client)
{
	//g_bHasDetector[client] = true;
	Timer_Detector(null, client);
	g_hTimer_Detector[client] = CreateTimer(g_flDetectorUpdateTime, Timer_Detector, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_Detector(Handle hTimer, int client)
{
	if (!IsClientInGame(client) && !IsPlayerAlive(client))
	{
		g_hTimer_Detector[client] = null;
		return Plugin_Stop;
	}
	
	float flDistance;
	int iOtherClient = GetNearestPlayer(client, flDistance);
	
	char szDetectorText[256];
	if (iOtherClient && flDistance <= g_flDetector_Radius)
	{
		int iExpectedBarCount = RoundToCeil((g_flDetector_Radius - flDistance) / g_flDetector_UnitsPerChar);
		int iLen;
		
		if(flDistance < 64.0)
		{
			iExpectedBarCount = g_iTotalDashCount;
		}
		
		while (iLen < iExpectedBarCount)
		{
			szDetectorText[iLen++] = CHAR_BAR;
		}
		
		szDetectorText[iLen] = 0;
		
		int iDashsNumber = g_iTotalDashCount - iExpectedBarCount;
		int iHalfDashsNumber = RoundToCeil(float(iDashsNumber) / float(2));
		
		// Even
		//if (!(iHalfDashsNumber % 2))
		{
			char szDashText[25];
			iLen = 0;
			while (iLen < iHalfDashsNumber)
			{
				szDashText[iLen++] = CHAR_DASH;
			}
			
			szDashText[iLen] = 0;
			
			//PrintToChatAll("Tot: %d - Dashes: %d - Half %d - Bars: %d - Sum: %d", RoundFloat(g_flDetector_Radius / g_flDetector_UnitsPerChar), iDashsNumber, iHalfDashsNumber, iExpectedBarCount, iDashsNumber + iExpectedBarCount);
			
			//FormatEx(szDetectorText, sizeof szDetectorText, "%s%s<font color=\"%s\">%s</font>%s", g_szDetectorDefaultMessage, szDashText, g_szDetectorCloseColor, szDetectorText, szDashText);
			Format(szDetectorText, sizeof szDetectorText, "%s\n%s<font color=\"%s\">%s</font>%s%c", g_szDetectorDefaultMessage, szDashText, g_szDetectorCloseColor, szDetectorText, szDashText, (iHalfDashsNumber % 2) ? CHAR_DASH : 0);
		}
		
		// Odd
		/*else
		{
			char szDashTextRight[25], szDashTextLeft[25];
			// Odd One
			iLen = 0;
			while (iLen < (iHalfDashsNumber - 1))
			{
				szDashTextRight[iLen++] = CHAR_DASH;
			}
			
			szDashTextRight[iLen] = 0;
			
			// Even one
			iLen = 0;
			while (iLen < iHalfDashsNumber)
			{
				szDashTextLeft[iLen++] = CHAR_DASH;
			}
			
			szDashTextRight[iLen] = 0;
			//FormatEx(szDetectorText, sizeof szDetectorText, "%s%s<font color=\"%s\">%s</font>%s", g_szDetectorDefaultMessage, szDashTextRight, g_szDetectorCloseColor, szDetectorText, szDashTextLeft);
			Format(szDetectorText, sizeof szDetectorText, "%s%s%s%s", g_szDetectorDefaultMessage, szDashTextRight, szDetectorText, szDashTextLeft);
		}*/
	}
	
	else
	{
		Format(szDetectorText, sizeof szDetectorText, "%s\n%s", g_szDetectorDefaultMessage, g_szDefaultDetectorText);
		//PrintToChatAll("szDefault: %s", szDetectorText);
	}
	
	PrintHintText(client, szDetectorText);
	return Plugin_Continue;
}

stock int GetNearestPlayer(int client, float &flDistance)
{
	float vOrigin[3], vOtherOrigin[3];
	float flNearestDistance;
	int iNearestPlayer;
	flNearestDistance = 99999.0;
	
	GetClientAbsOrigin(client, vOrigin);
	vOrigin[2] += 32.0;
	
	// Nearest player
	int iPlayers[MAXPLAYERS + 1], iCount;
	iCount = GetPlayers(iPlayers, GP_Flag_Alive, GP_Team_NC);
	
	for (int i = 0; i < iCount; i++)
	{
		GetClientAbsOrigin(iPlayers[i], vOtherOrigin);
		vOtherOrigin[2] += 32.0;
		
		if ((flDistance = GetVectorDistance(vOrigin, vOtherOrigin)) < flNearestDistance)
		{
			flNearestDistance = flDistance;
			iNearestPlayer = iPlayers[i];
		}
	}
	
	if (iNearestPlayer)
	{
		flDistance = flNearestDistance;
	}
	
	return iNearestPlayer;
}

void GiveHeGrenades(int client)
{
	GiveGrenades(client, Nade_He, true, g_iHegrenadeGiveAmount, g_iHegrenadeMax);
	g_bHasHeGrenade[client] = true;
}

void GiveFrostGrenades(int client)
{
	GiveGrenades(client, FROST_GRENADE_TYPE, true, g_iFrostGrenadeGiveAmount, g_iFrostGrenadeGiveAmount);
	g_bHasFrostGrenade[client] = true;
}

void GiveAdrenaline(int client)
{
	g_bHasAdrenaline[client] = true;
}

void BuildMainMenu()
{
	g_hMainMenu = CreateMenu(MenuHandler_MainMenu, MENU_ACTIONS_DEFAULT);
	
	//SetMenuExitButton(g_hMainMenu, true);
	SetMenuTitle(g_hMainMenu, "Nightcrawler Menu - [By: Khalid]");
	
	AddMenuItem(g_hMainMenu, "0", "Choose Weapons");
	AddMenuItem(g_hMainMenu, "1", "Items Menu");
	//AddMenuItem(g_hMainMenu, "2", "Shop Menu");
	
	AddMenuItem(g_hMainMenu, "3", "Enter Nightcrawler Queue");
	
	AddMenuItem(g_hMainMenu, "998", "Help");
	AddMenuItem(g_hMainMenu, "999", "Admin Menu");
}

enum
{
	WPNMenu_NewWeapons, 
	WPNMenu_LastWeapons, 
	WPNMenu_LastWeaponsAndSave
};

void BuildWeaponsMenu()
{
	g_hWeaponMenu_Main = CreateMenu(MenuHandler_WeaponMenu_Main, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(g_hWeaponMenu_Main, "Select Weapons:");
	AddMenuItem(g_hWeaponMenu_Main, "0", "Select New Weapons");
	AddMenuItem(g_hWeaponMenu_Main, "1", "Select Last Weapons");
	AddMenuItem(g_hWeaponMenu_Main, "2", "Select Last Weapons and Save (Auto Give)");
	
	char szDisplayName[35], szWeaponName[25];
	int iWeaponSuffix;
	
	char szInfo[3];
	char szWeaponSuffix[18];
	
	g_hWeaponMenu_Primary = CreateMenu(MenuHandler_WeaponMenu_ChooseWeapon, MENU_ACTIONS_DEFAULT | MenuAction_Display);
	//SetMenuTitle(g_hWeaponsMenu_Primary, "Select Primary Weapon:");
	
	g_hWeaponMenu_Sec = CreateMenu(MenuHandler_WeaponMenu_ChooseWeapon, MENU_ACTIONS_DEFAULT | MenuAction_Display);
	//SetMenuTitle(g_hWeaponsMenu_Primary, "Select Seconadry Weapon:");
	
	int iSize = GetArraySize(g_Array_WeaponName);
	for (int i; i < iSize; i++)
	{
		GetArrayString(g_Array_WeaponName, i, szWeaponName, sizeof szWeaponName);
		
		iWeaponSuffix = GetArrayCell(g_Array_WeaponSuffix, i);
		if (iWeaponSuffix != 0)
		{
			IntToString(iWeaponSuffix, szInfo, sizeof szInfo);
			if (!GetTrieString(g_Trie_WeaponSuffix, szInfo, szWeaponSuffix, sizeof szWeaponSuffix))
			{
				FormatEx(szDisplayName, sizeof szDisplayName, "%s", szWeaponName);
			}
			
			else FormatEx(szDisplayName, sizeof szDisplayName, "%-12s [%s]", szWeaponName, szWeaponSuffix);
		}
		
		else FormatEx(szDisplayName, sizeof szDisplayName, "%s", szWeaponName);
		
		IntToString(i, szInfo, sizeof szInfo);
		switch (GetArrayCell(g_Array_WeaponType, i))
		{
			case WEAPONTYPE_PRIMARY:
			{
				AddMenuItem(g_hWeaponMenu_Primary, szInfo, szDisplayName);
			}
			
			case WEAPONTYPE_SECONDARY:
			{
				AddMenuItem(g_hWeaponMenu_Sec, szInfo, szDisplayName);
			}
		}
	}
}

public int MenuHandler_WeaponMenu_Main(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (GetClientTeam(param1) != CS_TEAM_SURVIVOR)
		{
			return;
		}
		
		bool bShowAgain = false;
		bool bAlive = IsPlayerAlive(param1);
		
		if(!bAlive)
		{
			return;
		}
		
		if (bAlive && GetGameTime() > g_flWeaponMenuExpireTime)
		{
			CPrintToChat(param1, "The time to choose the weapons has expired. You will need to wait for a new round.");
			return;
		}
		
		char szInfo[3];
		int iItemInfo;
		
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		iItemInfo = StringToInt(szInfo);
		
		switch (iItemInfo)
		{
			case WPNMenu_NewWeapons:
			{
				g_iWeaponMenuStep[param1] = WEAPONTYPE_PRIMARY;
				DisplayMenu(g_hWeaponMenu_Primary, param1, MENU_TIME_FOREVER);
			}
			
			case WPNMenu_LastWeapons:
			{
				if (g_iLastWeapons[param1][0] == -1 || g_iLastWeapons[param1][1] == -1)
				{
					CPrintToChat(param1, "You haven't even choosen a weapon!");
					bShowAgain = true;
				}
				
				else
				{
					if (bAlive)
					{
						g_bHasChosenWeaponsThisRound[param1] = true;
						GiveLastWeapons(param1);
						
						if (CanDisplayItemMenu(param1))
						{
							DisplayMenu(g_hItemMenu, param1, MENU_TIME_FOREVER);
						}
					}
				}
			}
			
			case WPNMenu_LastWeaponsAndSave:
			{
				if (g_iLastWeapons[param1][0] == -1 || g_iLastWeapons[param1][1] == -1)
				{
					CPrintToChat(param1, "You haven't even choosen a weapon!");
					bShowAgain = true;
				}
				
				else
				{
					g_bSaveLastWeapons[param1] = true;
					
					if (bAlive)
					{
						g_bHasChosenWeaponsThisRound[param1] = true;
						GiveLastWeapons(param1);
						
						if (CanDisplayItemMenu(param1))
						{
							DisplayMenu(g_hItemMenu, param1, MENU_TIME_FOREVER);
						}
					}
				}
			}
		}
		
		if (bShowAgain)
		{
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

public int MenuHandler_WeaponMenu_ChooseWeapon(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Display)
	{
		g_bHasChosenWeaponsThisRound[param1] = true;
		
		switch (g_iWeaponMenuStep[param1])
		{
			case WEAPONTYPE_PRIMARY:
			{
				SetMenuTitle(menu, "Choose Primary:");
			}
			case WEAPONTYPE_SECONDARY:
			{
				SetMenuTitle(menu, "Choose Secondary:");
			}
		}
	}
	
	else if (action == MenuAction_Select)
	{
		if(!IsPlayerAlive(param1) || GetClientTeam(param1) != CS_TEAM_SURVIVOR)
		{
			return;
		}
		
		int iItemInfo;
		char szInfo[3];
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		
		iItemInfo = StringToInt(szInfo);
		
		switch (g_iWeaponMenuStep[param1])
		{
			case WEAPONTYPE_PRIMARY:
			{
				CS_RemoveWeapon(param1, CS_SLOT_PRIMARY);
				
				g_iLastWeapons[param1][0] = iItemInfo;
				g_iWeaponMenuStep[param1] = WEAPONTYPE_SECONDARY;
				
				DisplayMenu(g_hWeaponMenu_Sec, param1, MENU_TIME_FOREVER);
			}
			case WEAPONTYPE_SECONDARY:
			{
				CS_RemoveWeapon(param1, CS_SLOT_SECONDARY);
				
				g_iLastWeapons[param1][1] = iItemInfo;
				g_iWeaponMenuStep[param1] = WEAPONTYPE_PRIMARY;
				
				if (CanDisplayItemMenu(param1))
				{
					DisplayMenu(g_hItemMenu, param1, MENU_TIME_FOREVER);
				}
			}
		}
		
		char szWeaponGiveName[35];
		GetArrayString(g_Array_WeaponGiveName, iItemInfo, szWeaponGiveName, sizeof szWeaponGiveName);
		int iEnt = GivePlayerItem(param1, szWeaponGiveName);
		
		int iBPAmmo = GetArrayCell(g_Array_WeaponReserveAmmo, iItemInfo);
		if (iBPAmmo != -1)
		{
			//int iEnt = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
			SetReserveAmmo(param1, iEnt, iBPAmmo);
		}
	}
}

stock void SetReserveAmmo(int client, int weapon, int ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo); //set reserve to 0
	
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype == -1)return;
	
	SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}

bool GiveLastWeapons(int client)
{
	CS_RemoveWeapon(client, CS_SLOT_PRIMARY, false, false);
	CS_RemoveWeapon(client, CS_SLOT_SECONDARY, false, false);
	
	char szWeaponGiveName[35];
	GetArrayString(g_Array_WeaponGiveName, g_iLastWeapons[client][0], szWeaponGiveName, sizeof szWeaponGiveName);
	GivePlayerItem(client, szWeaponGiveName);
	
	GetArrayString(g_Array_WeaponGiveName, g_iLastWeapons[client][1], szWeaponGiveName, sizeof szWeaponGiveName);
	GivePlayerItem(client, szWeaponGiveName);
}

void CS_RemoveWeapon(int client, int slot, bool bStripKnife = false, bool bStripBomb = false)
{
	int i, iEnd;
	if (slot == -1)
	{
		i = CS_SLOT_PRIMARY;
		iEnd = CS_SLOT_C4;
	}
	
	else
	{
		i = slot;
		iEnd = slot;
	}
	
	for (; i <= iEnd; i++)
	{
		int weapon_index = -1;
		while ((weapon_index = GetPlayerWeaponSlot(client, i)) != -1)
		{
			if (IsValidEntity(weapon_index))
			{
				if (slot == CS_SLOT_KNIFE && !bStripKnife)
				{
					continue;
				}
				
				if (slot == CS_SLOT_C4 && !bStripBomb)
				{
					break;
				}
				
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char szInfo[5];
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		
		bool bDisplayAgain;
		
		switch (StringToInt(szInfo))
		{
			case 0:
			{
				if (!CanDisplayWeaponMenu(param1, true))
				{
					bDisplayAgain = true;
				}
			}
			
			case 1:
			{
				if (!CanDisplayItemMenu(param1, true))
				{
					bDisplayAgain = true;
				}
				
				else DisplayMenu(g_hItemMenu, param1, MENU_TIME_FOREVER);
			}
			
			case 2:
			{
				if (!CanDisplayShopMenu(param1, true))
				{
					bDisplayAgain = true;
				}
				
				else DisplayMenu(g_hItemMenu, param1, MENU_TIME_FOREVER);
			}
			
			case 3:
			{
				if(g_iChooseNCPlayersMode != MODE_QUEUE)
				{
					CPrintToChat(param1, "This Option is currently disabled!");
				}
				
				else if(GetClientTeam(param1) == CS_TEAM_NC)
				{
					CPrintToChat(param1, "You cannot join the queue while playing as a %s!", g_szNCName);
				}
				
				else if (!g_bIsInNCQueue[param1])
				{
					g_Array_NCQueue.Push(param1);
					g_iNCQueueCount++;
					g_bIsInNCQueue[param1] = true;
					
					CPrintToChat(param1, "You have been added to the queue! Current position: %d", g_iNCQueueCount);
				}
				
				else
				{
					CPrintToChat(param1, "You are already in the queue!", g_iNCQueueCount);
				}
				
				bDisplayAgain = true;
			}
			
			case 998:
			{
				PrintHelpMessagesInConsole(param1);
				//CPrintToChat(param1, "Everything you need to know about this mod has been printed in your console.");
				
				bDisplayAgain = true;
			}
			
			case 999:
			{
				CPrintToChat(param1, "No access bruh.");
			}
		}
		
		if (bDisplayAgain)
		{
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
	
	else if(action == MenuAction_DrawItem)
	{
		char szInfo[5];
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
	
		if(StringToInt(szInfo) == 3)
		{
			if(g_iChooseNCPlayersMode != MODE_QUEUE)
			{
				return ITEMDRAW_DISABLED;
			}
		}
		
		return ITEMDRAW_DEFAULT;
	}
	
	return 0;
}

void PrintHelpMessagesInConsole(int client)
{
	#define PrintMethod CPrintToChat
	PrintMethod(client, "-------------------------------");
	PrintMethod(client, "------  Nightcrawlers Mod -----");
	PrintMethod(client, "-------------------------------");
	PrintMethod(client, "Nightcrawlers are aliens that invaded the earth. Their objective is to hunt down the human surivors and obliterate them.");
	PrintMethod(client, "--- How to play:");
	PrintMethod(client, "-- As a %s:", g_szSurvivorName);
	PrintMethod(client, "You have to survive until the end of the round or kill all the %s.", g_szSurvivorName, g_szNCTeamName);
	PrintMethod(client, "You can choose your guns, your (assisting) items, or buy upgrades from the shop.");
	PrintMethod(client, "The %s are invisible. They only turn visible when you hurt them.", g_szNCTeamName);
	PrintMethod(client, "-- As a %s:", g_szNCName);
	PrintMethod(client, "Your objective is to kill the %ss", g_szSurvivorTeamName);
	PrintMethod(client, "You are invisible, and you are only visible (for a limited amount of time) when you get hurt!");
	PrintMethod(client, "You can climb walls using your '+use' key.");
	PrintMethod(client, "You can teleport by clicking on the 'drop' button (the button that drops a gun). Teleporting costs you %0.2f %s", g_flManaTeleportCost, g_szManaName);
}
/*
void BuildShopMenu()
{
	g_hShopMenu = CreateMenu(MenuHandler_Shop, MENU_ACTIONS_ALL);
	char szDisplayName[35];
	char szInfo[3];
	
	for (int i; i < MAX_SHOP_ITEMS; i++)
	{
		if (!g_bShopItemEnabled[i])
		{
			continue;
		}
		
		FormatEx(szDisplayName, sizeof szDisplayName, "%s [%d Points]", g_szShopItemName[i], g_iShopItemCost[i]);
		FormatEx(szInfo, sizeof szInfo, "%d", i);
		
		AddMenuItem(g_hShopMenu, szInfo, szDisplayName);
	}
}*/
/*
public int MenuHandler_Shop(Menu menu, MenuAction action, int param1, int param2)
{
	char szInfo[3];
	int iItemIndex;
	
	bool bDisplayAgain = false;
	bool g_bShopItemEnabled[3];
	int g_iShopItemCost[3];
	
	switch (action)
	{
		case MenuAction_End:
		{
			
		}
		
		case MenuAction_Cancel:
		{
			
		}
		
		case MenuAction_DisplayItem:
		{
			return 0;
		}
		
		case MenuAction_DrawItem:
		{
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iItemIndex = StringToInt(szInfo);
			
			if (!g_bShopItemEnabled[iItemIndex])
			{
				//RemoveMenuItem(menu, iItemIndex);
				return ITEMDRAW_DEFAULT;
			}
			
			if (g_iShopItemCost[iItemIndex] > 0 && g_iShopItemCost[iItemIndex] > g_iPlayerPoints[param1])
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Display:
		{
			SetMenuTitle(menu, "Nightcrawler Shop: [%d Points]", g_iPlayerPoints[param1]);
			return 0;
		}
		
		case MenuAction_Select:
		{
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iItemIndex = StringToInt(szInfo);
			
			if (!g_bShopItemEnabled[iItemIndex])
			{
				CPrintToChat(param1, "You are missing %d points to buy this item.", g_iShopItemCost[iItemIndex] - g_iPlayerPoints[param1]);
				bDisplayAgain = true;
			}
			
			if (g_iShopItemCost[iItemIndex] > g_iPlayerPoints[param1])
			{
				CPrintToChat(param1, "You are missing %d points to buy this item.", g_iShopItemCost[iItemIndex] - g_iPlayerPoints[param1]);
				bDisplayAgain = true;
			}
			
			else
			{
				g_iPlayerPoints[param1] -= g_iShopItemCost[iItemIndex];
				//GivePlayerShopItem(param1, iItemIndex, false, 0);
			}
		}
	}
	
	if (bDisplayAgain)
	{
		DisplayMenu(menu, param1, MENU_TIME_FOREVER);
	}
	
	return 0;
}*/

// --------------------------------------------------------------------------
//								Timers
// --------------------------------------------------------------------------
public Action Timer_HintMessage(Handle hTimer)
{
	SetHudTextParams(0.05, 0.5, HINTMSG_UPDATE_TIME + 0.15, 255, 255, 255, 130);
	
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (!IsClientInGame(iPlayer) || !IsPlayerAlive(iPlayer))
		{
			continue;
		}
		
		switch (GetClientTeam(iPlayer))
		{
			case CS_TEAM_NC:
			{
				//PrintHintText(iPlayer, "Mana: %0.2f|%0.2f\nRegeneration Rate: %0.1f", g_flPlayerMana[iPlayer], g_flMaxMana, g_flManaRegenAmount);
				ShowHudText(iPlayer, 4, "Mana: %0.2f|%0.2f\nRegeneration Rate: %0.1f\nTeleport Cost: %0.1f", g_flPlayerMana[iPlayer], g_flMaxMana, g_flManaRegenAmount, g_flManaTeleportCost);
			}
			
			case CS_TEAM_SURVIVOR:
			{
				float flGameTime;
				if (g_bHasHeGrenade[iPlayer])
				{
					if (g_flPlayerNextGrenade[iPlayer] > (flGameTime = GetGameTime()))
					{
						//PrintHintText(iPlayer, "Next Grenade reload in: %0.1f seconds", g_flPlayerNextGrenade[iPlayer] - flGameTime);
						ShowHudText(iPlayer, 4, "Next Grenade reload in: %0.1f seconds", g_flPlayerNextGrenade[iPlayer] - flGameTime);
					}
					
					else
					{
						g_flPlayerNextGrenade[iPlayer] = flGameTime + g_flHegrenadeRegenTime;
						GiveGrenades(iPlayer, Nade_He, false, 1, g_iHegrenadeMax);
					}
				}
			}
		}
	}
}

void GiveGrenades(int client, int iType, bool bSet, int iCount, int iMax)
{
	int iGrenadeCount = GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iGrenadeOffsets[iType]);
	
	if (!iGrenadeCount)
	{
		GivePlayerItem(client, g_szGrenadeWeaponNames[iType]);
	}
	
	if (iGrenadeCount >= iMax)
	{
		return;
	}
	
	switch (bSet)
	{
		case true:
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", iCount, _, g_iGrenadeOffsets[iType]);
		}
		
		case false:
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", iCount + iGrenadeCount, _, g_iGrenadeOffsets[iType]);
		}
	}
}

public Action Timer_MakeNCInvisibleAgain(Handle hTimer, int client)
{
	if (IsClientInGame(client))
	{
		g_bDontShowPlayer[client] = true;
	}
}

public Action Timer_CheckGameState(Handle hTimer)
{
	if (g_bRunning)
	{
		int iPlayersCT[MAXPLAYERS + 1];
		int iPlayersT[MAXPLAYERS + 1];
		
		int iCountCT = GetPlayers(iPlayersCT, GP_Flag_None, GP_Team_Survivor);
		int iCountT = GetPlayers(iPlayersT, GP_Flag_None, GP_Team_NC);
		
		if (iCountT + iCountCT < g_iMinPlayers)
		{
			g_bRunning = false;
			CPrintToChatAll("Stopped the game: not enough players (Minimum: %d)", g_iMinPlayers);
			return Plugin_Continue;
		}
		
		if (iCountT <= 0 || iCountCT <= 0)
		{
			CPrintToChatAll("Restarting the round as there are no players in the %s team.", g_szNCTeamName);
			CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
		}
		
		return Plugin_Continue;
	}
	
	int iCount = GetPlayers(_, GP_Flag_None, GP_Team_NC | GP_Team_Survivor);
	
	if (iCount >= g_iMinPlayers)
	{
		//ChooseNCPlayers();
		CPrintToChatAll("--- Starting ---");
		
		g_bRunning = true;
		CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
	}
	
	else CPrintToChatAll("Waiting for at least %d players to join to start the game.", g_iMinPlayers);
	
	return Plugin_Continue;
}

// --------------------------------------------------------------------------
//								Other Funcs
// --------------------------------------------------------------------------
void ChooseNCPlayers()
{
	int iPlayers[MAXPLAYERS + 1];
	int iCount = GetPlayers(iPlayers, _, GP_Team_NC | GP_Team_Survivor);
	
	int iNCCount = RoundToFloor(float(iCount) / g_flNCRatio);
	
	if(!iNCCount)
	{
		iNCCount = 1;
	}
	
	//PrintToChatAll("Ratio %0.2f - Calculated Count %d - %d", g_flNCRatio, iNCCount, g_iChooseNCPlayersMode);
	
	int iChosenPlayersCount;
	int bChosenPlayers[MAXPLAYERS + 1];
	
	int iPlayer, iIndex;
	
	bool bFillRandom = g_iChooseNCPlayersMode == MODE_RANDOM ? true : false;
	
	if (g_iChooseNCPlayersMode == MODE_QUEUE)
	{
		while (iChosenPlayersCount < iNCCount && g_iNCQueueCount > 0)
		{
			iPlayer = g_Array_NCQueue.Get(iIndex);
			
			if (bChosenPlayers[iPlayer])
			{
				if (iIndex + 1 < g_iNCQueueCount)
				{
					++iIndex;
					continue;
				}
				
				break;
			}
			
			g_bIsInNCQueue[iPlayer] = false;
			g_iNCQueueCount--;
			g_Array_NCQueue.Erase(iIndex);
			iIndex = 0;
			
			bChosenPlayers[iPlayer] = true;
			iChosenPlayersCount++;
		}
		
		if (iChosenPlayersCount < iNCCount)
		{
			bFillRandom = true;
		}
	}
	
	else if (g_iChooseNCPlayersMode == MODE_KILL)
	{
		for (int i; i < iCount; i++)
		{
			iPlayer = iPlayers[i];
			
			// Survivor Killed NC or NC survived
			if (g_bKilledNC[iPlayer] || ( g_bKeepSurvivingNC && (IsPlayerAlive(iPlayer) && GetClientTeam(iPlayer) == CS_TEAM_NC) ) )
			{
				if (iChosenPlayersCount < iNCCount)
				{
					bChosenPlayers[iPlayer] = true;
					iChosenPlayersCount++;
				}
				
				else break;
			}
		}
		
		if (iChosenPlayersCount < iNCCount)
		{
			bFillRandom = true;
		}
	}
	
	// Random
	if (bFillRandom)
	{
		ArrayList hArray = new ArrayList(1);
		for (int i; i < iCount; i++)
		{
			iPlayer = iPlayers[i];
			if (bChosenPlayers[iPlayer])
			{
				continue;
			}
			
			hArray.Push(iPlayers[i]);
		}
		
		int iLength = hArray.Length;
		iIndex = 0;
		
		while (iChosenPlayersCount < iNCCount && (iLength > 0))
		{
			iIndex = GetRandomInt(0, iLength - 1);
			iPlayer = hArray.Get(iIndex);
			
			if (!bChosenPlayers[iPlayer])
			{
				bChosenPlayers[iPlayer] = true;
				
				hArray.Erase(iIndex);
				iLength--;
				iChosenPlayersCount++;
			}
		}
		
		delete hArray;
	}
	
	else
	{
		LogToFile(PLUGIN_LOG_FILE, "g_iChooseNCPlayersMode value fail %d", g_iChooseNCPlayersMode);
	}
	
	for (int i; i < iCount; i++)
	{
		iPlayer = iPlayers[i];
		
		if (bChosenPlayers[iPlayer] && GetClientTeam(iPlayer) != CS_TEAM_NC)
		{
			CS_SwitchTeam(iPlayer, CS_TEAM_NC);
			//SetEntProp(iPlayer, Prop_Send, "m_iTeamNum", CS_TEAM_NC);
			g_bDontShowPlayer[iPlayer] = true;
		}
		
		else if (!bChosenPlayers[iPlayer] && GetClientTeam(iPlayer) != CS_TEAM_SURVIVOR)
		{
			CS_SwitchTeam(iPlayer, CS_TEAM_SURVIVOR);
			//SetEntProp(iPlayer, Prop_Send, "m_iTeamNum", CS_TEAM_SURVIVOR);
			g_bDontShowPlayer[iPlayer] = false;
		}
		
		else PluginLog("LOL? Client : %d", iPlayer);
	}
	
	PluginLog("Players Count: %d - NC Expected Count %d - Chosen NC Count %d", iCount, iNCCount, iChosenPlayersCount);
}

void ReadPrecacheFile()
{
	char szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/nightcrawer_downloadfiles.ini");
	
	File f = null;
	
	if (!FileExists(szFile))
	{
		f = OpenFile(szFile, "w+");
		
		WriteFileLine(f, "# Use directory path to precache all files in a folder");
		
		WriteFileLine(f, "models/tripmine/tripmine.dx90.vtx");
		WriteFileLine(f, "models/tripmine/tripmine.mdl");
		WriteFileLine(f, "models/tripmine/tripmine.phy");
		WriteFileLine(f, "models/tripmine/tripmine.vvd");
		
		WriteFileLine(f, "models/weapons/eminem/ice_cube/ice_cube.dx90.vtx");
		WriteFileLine(f, "models/weapons/eminem/ice_cube/ice_cube.mdl");
		WriteFileLine(f, "models/weapons/eminem/ice_cube/ice_cube.phy");
		WriteFileLine(f, "models/weapons/eminem/ice_cube/ice_cube.vvd");

		WriteFileLine(f, "materials/models/tripmine/minetexture.vmt");
		WriteFileLine(f, "materials/models/tripmine/minetexture.vtf");
		
		WriteFileLine(f, "materials/sprites/blueglow2.vmt");
		WriteFileLine(f, "materials/sprites/blueglow2.vtf");
		WriteFileLine(f, "materials/sprites/halo01.vmt");
		WriteFileLine(f, "materials/sprites/halo01.vtf");
		WriteFileLine(f, "materials/sprites/lgtning.vmt");
		WriteFileLine(f, "materials/sprites/lgtning.vtf");

		
		delete f;
	}
	
	f = OpenFile(szFile, "r");
	
	char szLine[PLATFORM_MAX_PATH];
	//bool bDontOpenSubFolders;
	
	bool bFDownloader = LibraryExists("fdownloader");
	
	while (ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		if (!szLine[0] || szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		if(bFDownloader)
		{
			FDownloader_AddSinglePath(szLine);
		}
		
		else
		{
			AddFileToDownloadsTable(szLine);
		}
		//bDontOpenSubFolders = false;
		
		/*if (szLine[0] == '*')
		{
			Format(szLine, sizeof szLine, "%s", szLine[1]);
			bDontOpenSubFolders = true;
		}
		
		ReplaceString(szLine, sizeof szLine, "\\", " / ");
		
		if (!FileExists(szLine))
		{
			PrecacheFilesInDirectory(szLine, bDontOpenSubFolders);
			
			continue;
		}
		
		AddFileToDownloadsTable(szLine);*/
	}
	
	delete f;
}
/*
void PrecacheFilesInDirectory(char[] szDir, bool bDontOpenSubFolders)
{
	DirectoryListing hDir = OpenDirectory(szDir);
	
	if (hDir == INVALID_HANDLE)
	{
		PluginLog("Failed To open path: %s", szDir);
		return;
	}
	
	PluginLog("szDir %s", szDir);
	
	char szPath[PLATFORM_MAX_PATH];
	char szFilePath[PLATFORM_MAX_PATH];
	char szFile[PLATFORM_MAX_PATH];
	
	FileType iType;
	while (ReadDirEntry(hDir, szFile, sizeof szFile, iType))
	{
		switch (iType)
		{
			case FileType_File:
			{
				FormatEx(szFilePath, sizeof szFilePath, " %s/%s", szDir, szFile);
				PluginLog("#2 Precache %s", szFilePath);
			
				if (!FileExists(szFilePath))
				{
					PluginLog("File %s doesn't exist.", szFilePath);
				}
				
				AddFileToDownloadsTable(szFilePath);
			}
		
			case FileType_Directory:
			{
				if (bDontOpenSubFolders)
				{
					continue;
				}
				
				FormatEx(szPath, sizeof szPath, "%s/%s", szDir, szFile);
				PluginLog("#3 Precache: %s", szPath);
				
				if (StrContains(szPath, ".") != -1)
				{
					PluginLog("Skipped");
					continue;
				}
				
				PrecacheFilesInDirectory(szPath, bDontOpenSubFolders);
			}
		}
	}
}*/

void PrecacheFiles()
{
	ReadPrecacheFile();
	char szFile[PLATFORM_MAX_PATH];
	
	PrecacheModel(FROST_ICECUBE_MODEL);
	
	PrecacheSoundAny(FROST_FREEZE_SOUND);
	FormatEx(szFile, sizeof szFile, "sound/%s", FROST_FREEZE_SOUND);
		
	AddFileToDownloadsTable(szFile);
	
	PrecacheSoundAny(FROST_GLASS_IMPACT_SOUND);
	FormatEx(szFile, sizeof szFile, "sound/%s", FROST_GLASS_IMPACT_SOUND);
	AddFileToDownloadsTable(szFile);
	
	PrecacheModel(MODEL_BEAM);
	//FormatEx(szFile, sizeof szFile, "models/%s", g_szMineModel);
	PrecacheModel(g_szMineModel);
	//AddFileToDownloadsTable(g_szMineModel);
	
	PrecacheSound("weapons/hegrenade/explode5.wav");
	PrecacheSound("ambient/explosions/explode_8.wav");
	
	g_iFrostGrenadeBeamIndex_Sprite1 = PrecacheModel(FROST_SPRITE_1);
	g_iFrostGrenadeBeamIndex_Sprite2 = PrecacheModel(FROST_SPRITE_2);
	g_iFrostGrenadeHaloSprite = PrecacheModel(FROST_HALO_SPRITE);
	g_iFrostGrenadeGlowSprite = PrecacheModel(FROST_GLOW_SPRITE);
	
	AddFileToDownloadsTable(FROST_SPRITE_1);
	AddFileToDownloadsTable(FROST_SPRITE_2);
	AddFileToDownloadsTable(FROST_HALO_SPRITE);
	//AddFileToDownloadsTable(FROST_GLOW_SPRITE);
	
	PrecacheSoundAny(g_szMinePlacementSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMinePlacementSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSoundAny(g_szMineArmedSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMineArmedSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSoundAny(g_szMineArmingSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMineArmingSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSoundAny(g_szMineLaserTouchSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMineLaserTouchSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSoundAny(g_szTeleportSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szTeleportSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSoundAny(g_szAdrenalineInjectionSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szAdrenalineInjectionSound);
	AddFileToDownloadsTable(szFile);
	
	for (int i; i < sizeof g_szNightcrawlerDeathSound; i++)
	{
		PrecacheSoundAny(g_szNightcrawlerDeathSound[i]);
		FormatEx(szFile, sizeof szFile, "sound/%s", g_szNightcrawlerDeathSound[i]);
		AddFileToDownloadsTable(szFile);
	}
}

int CreateFog()
{
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(-1, "env_fog_controller")) > -1)
	{
		/*
		if(!IsValidEdict(iEnt))
		{
			continue;
		}*/
		
		//AcceptEntityInput(iEnt, "Kill"); 
		RemoveEdict(iEnt);
		
		PluginLog("Removed Fog ent %d", iEnt);
	}
	
	iEnt = CreateEntityByName("env_fog_controller");
	if (iEnt > -1)
	{
		DispatchKeyValue(iEnt, "targetname", "MyFog");
		DispatchKeyValue(iEnt, "fogenable", "1");
		DispatchKeyValue(iEnt, "spawnflags", "1");
		DispatchKeyValue(iEnt, "fogblend", "0");
		DispatchKeyValue(iEnt, "fogcolor", "150 150 255");
		DispatchKeyValue(iEnt, "fogcolor2", "255 0 0");
		DispatchKeyValueFloat(iEnt, "fogstart", 175.0);
		DispatchKeyValueFloat(iEnt, "fogend", 1250.0);
		//		DispatchKeyValueFloat(iEnt, "farz", 400.0);
		DispatchKeyValueFloat(iEnt, "fogmaxdensity", 1.0);
		DispatchSpawn(iEnt);
		
		AcceptEntityInput(iEnt, "TurnOn");
	}
	
	return iEnt;
}

bool TeleportClient(int client)
{
	if(g_bIsFrozen[client])
	{
		return false;
	}
	
	float vEyePosition[3];
	float vEyeAngles[3];
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	
	float vVector1[3]; //, vVector2[3], vVector3[3];
	GetAngleVectors(vEyeAngles, vVector1, NULL_VECTOR, NULL_VECTOR);
	
	float vOtherPosition[3];
	NormalizeVector(vVector1, vVector1);
	
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilter_Callback, client);
	if (!TR_DidHit(hTr))
	{
		CPrintToChat(client, "Please aim somewhere else to teleport");
		delete hTr;
		return false;
	}
	
	TR_GetEndPosition(vOtherPosition, hTr);
	if (TR_PointOutsideWorld(vOtherPosition))
	{
		CPrintToChat(client, "Please aim somewhere INSIDE THE MAP to teleport");
		delete hTr;
		return false;
	}
	
	delete hTr;
	ScaleVector(vVector1, 32.0);
	
	// Move the player model back based on mins/maxes;
	// Subtract because in the opposite direction;
	SubtractVectors(vOtherPosition, vVector1, vOtherPosition);
	//CreateLaser(vEyePosition, vOtherPosition);
	
	float zerovec[3] =  { 0.0, 0.0, 0.0 };
	
	TeleportEntity(client, vOtherPosition, NULL_VECTOR, zerovec);
	EmitSoundToAllAny(g_szTeleportSound, client);
	UnStuckEntity(client);
	
	return true;
}

#define START_DISTANCE  32   // --| The first search distance for finding a free location in the map.
#define MAX_ATTEMPTS    128  // --| How many times to search in an area for a free

enum
{
	x = 0, y, z, Coord_e
};

bool UnStuckEntity(int client, int i_StartDistance = START_DISTANCE, int i_MaxAttempts = MAX_ATTEMPTS)
{
	int iMaxTries = 30;
	int iTries;
	
	static float vf_OriginalOrigin[Coord_e];
	static float vf_NewOrigin[Coord_e];
	static int i_Attempts, i_Distance;
	static float vEndPosition[3];
	static float vMins[Coord_e];
	static float vMaxs[Coord_e];
	
	GetClientAbsOrigin(client, vf_OriginalOrigin);
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	
	while (CheckIfClientIsStuck(client))
	{
		if (iTries++ >= iMaxTries)
		{
			break;
		}
		
		i_Distance = i_StartDistance;
		
		while (i_Distance < 1000)
		{
			i_Attempts = i_MaxAttempts;
			
			while (i_Attempts--)
			{
				vf_NewOrigin[x] = GetRandomFloat(vf_OriginalOrigin[x] - i_Distance, vf_OriginalOrigin[x] + i_Distance);
				vf_NewOrigin[y] = GetRandomFloat(vf_OriginalOrigin[y] - i_Distance, vf_OriginalOrigin[y] + i_Distance);
				vf_NewOrigin[z] = GetRandomFloat(vf_OriginalOrigin[z] - i_Distance, vf_OriginalOrigin[z] + i_Distance);
				
				//engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, hull, id, 0 );
				TR_TraceHullFilter(vf_NewOrigin, vf_NewOrigin, vMins, vMaxs, MASK_ALL, TraceFilter_Callback, client);
				
				// --| Free space found.
				TR_GetEndPosition(vEndPosition);
				if (!TR_PointOutsideWorld(vEndPosition) && TR_GetFraction() == 1.0)
				{
					// --| Set the new origin .
					TeleportEntity(client, vEndPosition, NULL_VECTOR, NULL_VECTOR);
					return true;
				}
			}
			
			i_Distance += i_StartDistance;
		}
	}
	
	// --| Could not be found.
	return false;
}

bool CheckIfClientIsStuck(int client)
{
	static float fOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
	
	static float fMins[3];
	static float fMaxs[3];
	
	GetClientMins(client, fMins);
	GetClientMaxs(client, fMaxs);
	
	TR_TraceHullFilter(fOrigin, fOrigin, fMins, fMaxs, MASK_ALL, TraceFilter_Callback, client);
	
	//engfunc(EngFunc_TraceHull, Origin, Origin, IGNORE_MONSTERS,  : (hull = HULL_HUMAN), 0, 0)
	
	if (TR_DidHit())
	{
		return true;
	}
	
	return false;
}

void CheckLastSurvivor()
{
	int iCount;
	int iLastId;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_SURVIVOR)
		{
			iCount++;
			iLastId = client;
		}
	}
	
	PluginLog("Last Survivor Count: %d", iCount);
	if (iCount == 1)
	{
		GiveLaser(iLastId, true);
	}
}

void GiveLasersOnRoundStart()
{
	DeleteLaserEntities();
	
	int iCount = GetPlayers(_, GP_Flag_Alive, GP_Team_Survivor);
	g_iCalculatedMaxLaserCount = RoundFloat(float(iCount) / g_flLaserRatio);
	
	if(!g_iCalculatedMaxLaserCount && iCount > 0 )
	{
		g_iCalculatedMaxLaserCount = 1;
	}
	
	if(g_iMaxGivenLaserCount > 0 && g_iCalculatedMaxLaserCount > g_iMaxGivenLaserCount)
	{
		g_iCalculatedMaxLaserCount = g_iMaxGivenLaserCount;
	}
	
	SetArrayValue(g_bLaser, sizeof g_bLaser, false, 0);
	g_iLaserCarriersCount = 0;
	
	switch(g_iLaserMode)
	{
		case LMODE_RANDOM:
		{
			GiveLaserToRandomPlayers();
		}
		
		case LMODE_KILL:
		{
			GiveLaserToHighestKillsPlayers();
		}
		
		case LMODE_MENU:
		{
			// Do nothing
		}
	}
}

void GiveLaserToHighestKillsPlayers()
{
	ArrayList iPlayersArray = new ArrayList(2);
	
	GetPlayersFilter(_, GP_Flag_Alive, GP_Team_Survivor, _, _, GiveLaserPlayersFilter, iPlayersArray);
	SortADTArrayCustom(iPlayersArray, GiveLaserArraySort);
	
	int iArray[2];
	
	for(g_iLaserCarriersCount = 0; g_iLaserCarriersCount < g_iCalculatedMaxLaserCount; g_iLaserCarriersCount++)
	{
		iPlayersArray.GetArray(g_iLaserCarriersCount, iArray, 2);
		GiveLaser(iArray[0], true);
		
		CPrintToChat(iArray[0], "You were given a laser due to having a high kill count!");
	}
	
	delete iPlayersArray;
	
	if(g_iLaserCarriersCount > 0)
	{
		g_iLaserCarriersCount++;
	}
}

public int GiveLaserArraySort(int index1, int index2, Handle hHandle, Handle hndl)
{
	int iArray1[2], iArray2[2];
	
	ArrayList hAdtArray = view_as<ArrayList>(hHandle);
	hAdtArray.GetArray(index1, iArray1, 2);
	hAdtArray.GetArray(index2, iArray2, 2);
	
	if(iArray1[1] == iArray2[1])
	{
		return 0;
	}
	
	if(iArray1[1] > iArray2[1])
	{
		return -1;
	}
	
	return 1;
}

public bool GiveLaserPlayersFilter(int client, int iCurrCount, ArrayList hAdtArray)
{
	int iPlayerArray[2];
	iPlayerArray[0] = client;
	iPlayerArray[1] = GetEntProp(client, Prop_Data, "m_iFrags");
	
	hAdtArray.PushArray(iPlayerArray);
	return true;
}

void GiveLaserToRandomPlayers()
{
	int iHumans[MAXPLAYERS + 1], iCount;
	
	iCount = GetPlayers(iHumans, GP_Flag_Alive, GP_Team_Survivor);
	
	int client;
	while (g_iLaserCarriersCount < g_iCalculatedMaxLaserCount)
	{
		client = iHumans[GetRandomInt(0, iCount - 1)];
		
		if (g_bLaser[client])
		{
			continue;
		}
		
		GiveLaser(client, true);
		g_iLaserCarriersCount++;
	}
	
	PluginLog("iLaserCount: %d - iChosenCount: %d", g_iCalculatedMaxLaserCount, g_iLaserCarriersCount);
}

void DeleteLaserEntities()
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (g_iLaserEnt[client] && IsValidEntity(g_iLaserEnt[client]))
		{
			//RemoveEdict(g_iLaserEnt[client]);
			AcceptEntityInput(g_iLaserEnt[client], "Kill");
			g_iLaserEnt[client] = 0;
		}
		
		g_bLaser[client] = false;
	}
}

void DoClimb(int client)
{
	float vOrigin[3]; GetClientAbsOrigin(client, vOrigin);
	float vEyeAngles[3]; static float vEyePosition[3];
	
	//TeleportEntity(iLaserEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	
	float vEndPosition[3];
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilter_Callback, client);
	
	if (TR_GetFraction(hTr) == 1.0)
	{
		delete hTr;
		return;
	}
	
	TR_GetEndPosition(vEndPosition, hTr);
	delete hTr;
	
	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		return;
	}
	
	if (GetVectorDistance(vEyePosition, vEndPosition) > 140.0)
	{
		return;
	}
	
	float vVelocity[3];
	GetAngleVectors(vEyeAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(vVelocity, vVelocity);
	ScaleVector(vVelocity, 400.0);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

void MoveLaserEnt(int client)
{
	static int iLaserEnt;
	iLaserEnt = g_iLaserEnt[client];
	
	if (!iLaserEnt)
	{
		return;
	}
	
	if (!IsValidEntity(iLaserEnt))
	{
		g_iLaserEnt[client] = 0;
		return;
	}
	
	//	static float vOrigin[3];
	static float vEyeAngles[3]; GetClientEyeAngles(client, vEyeAngles);
	static float vEyePosition[3]; GetClientEyePosition(client, vEyePosition);
	
	//WA_GetAttachmentPos(client, "muzzle_flash", vOrigin);
	
	//TeleportEntity(iLaserEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	static float vEndPosition[3];
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilter_Callback, client);
	
	if (!TR_DidHit(hTr))
	{
		delete hTr;
		return;
	}
	
	static int iHit;
	iHit = TR_GetEntityIndex(hTr);
	TR_GetEndPosition(vEndPosition, hTr);
	
	delete hTr;
	
	TeleportEntity(iLaserEnt, vEndPosition, NULL_VECTOR, NULL_VECTOR);
	
	int iColor[4]; 
	iColor = g_iSurvivorLaserColor_Normal;
	
	if (IsValidPlayer(iHit, true) && GetClientTeam(iHit) == CS_TEAM_NC)
	{
		iColor = g_iSurvivorLaserColor_Aim;
	}
	
	SetEntityRenderColor(iLaserEnt, iColor[0], iColor[1], iColor[2], iColor[3]);
	
	/*TE_SetupBeamPoints(vOrigin, vEndPosition, g_iBeamModelIndex, 0, 0, 0, 0.1, 1.0, 1.0, 0, 0.0, iColor, 1);
	TE_SendToAllButClient(client);
	
	GetClientEyePosition(client, vOrigin);
	TE_SetupBeamPoints(vOrigin, vEndPosition, g_iBeamModelIndex, 0, 0, 0, 0.1, 1.0, 1.0, 0, 0.0, iColor, 1);
	TE_SendToClient(client);*/
	
	//SetEntPropVector(iLaserEnt, Prop_Data, "m_vecEndPos", vEndPosition);
	//AcceptEntityInput(iEnt, "TurnOn");
	
	//StopProfiling(hPf);
	//PluginLog("Took %f seconds", GetProfilerTime(hPf)); 
	
	//delete hPf;
}

void GiveLaser(int client, bool bStatus)
{
	switch (bStatus)
	{
		case true:
		{
			if (g_bLaser[client])
			{
				return;
			}
			
			g_bLaser[client] = true;
			g_iLaserEnt[client] = MakeLaserEntity(client);
		}
		
		case false:
		{
			g_bLaser[client] = false;
			
			if (g_iLaserEnt[client] > 0 && IsValidEntity(g_iLaserEnt[client]))
			{
				AcceptEntityInput(g_iLaserEnt[client], "Kill");
			}
			
			g_iLaserEnt[client] = 0;
		}
	}
}

int MakeLaserEntity(int client)
{
	int iEnt;
	
	#define LASER_COLOR_CT	"255 255 255"
	iEnt = CreateEntityByName("env_beam");
	if (IsValidEntity(iEnt))
	{
		char color[16] = LASER_COLOR_CT;
		
		SetEntityModel(iEnt, MODEL_BEAM);
		
		DispatchKeyValue(iEnt, "targetname", g_szPlayerLaserTargetName);
		DispatchKeyValue(iEnt, "rendercolor", color);
		DispatchKeyValue(iEnt, "renderamt", "255");
		DispatchKeyValue(iEnt, "damage", "0");
		DispatchKeyValue(iEnt, "decalname", "Bigshot");
		DispatchKeyValue(iEnt, "life", "0");
		DispatchKeyValue(iEnt, "TouchType", "0");
		
		DispatchKeyValue(iEnt, "ClipStyle", "0");
		
		DispatchSpawn(iEnt);
		
		SetEntPropFloat(iEnt, Prop_Data, "m_fWidth", 1.0);
		SetEntPropFloat(iEnt, Prop_Data, "m_fEndWidth", 1.0);
		
		float vOrigin[3]; GetClientEyePosition(client, vOrigin);
		
		//TeleportEntity(iEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
		
		SetEntProp(iEnt, Prop_Send, "m_nNumBeamEnts", 2);
		//SetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(client), 0);
		SetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(client), 1);
		SetEntProp(iEnt, Prop_Send, "m_nBeamType", 1);
		
		AcceptEntityInput(iEnt, "TurnOn");
		ActivateEntity(iEnt);
		
		//SetVariantString("!activator");
		//AcceptEntityInput(iEnt, "SetParent", client);
		//AcceptEntityInput(iEnt, "SetParent", client, iEnt, 0);
		//AcceptEntityInput(iEnt, "SetParentAttachmentMaintainOffset", iEnt, iEnt);
		
		//SetEntPropVector(iEnt, Prop_Data, "m_vecEndPos", end);
		
		//DispatchSpawn(iEnt);
		//ActivateEntity(iEnt);
		//AcceptEntityInput(iEnt, "TurnOn");
		
		//PrintToChatAll("Made laser");
		//CreateTimer(3.0, Timer_DeleteLaser, ent, TIMER_FLAG_NO_MAPCHANGE);
		
		return iEnt;
	}
	
	return 0;
}

void ResetVars(int client, bool bConnect)
{
	g_bDontShowPlayer[client] = false;
	g_bKilledNC[client] = false;
	g_bLaser[client] = false;
	
	GiveLaser(client, false);
	
	g_bHasChosenItemThisRound[client] = false;
	g_iPlayerMinesCount[client] = 0;
	
	if (g_hTimer_PlaceMine[client] != null)
	{
		delete g_hTimer_PlaceMine[client];
		g_hTimer_PlaceMine[client] = null;
	}
	
	g_flMineLaser_PlayerTouch_SoundPlayCooldown[client] = 0.0;
	
	g_bHasSuicideBomb[client] = false;
	g_bSuicideBombActivated[client] = false;
	
	g_bHasAdrenaline[client] = false;
	g_bAdrenalineActivated[client] = false;
	g_flNextModifyTime[client] = 0.0;
	
	if (g_hTimer_Detector[client] != null)
	{
		delete g_hTimer_Detector[client];
		g_hTimer_Detector[client] = null;
	}
	
	g_bHasChosenWeaponsThisRound[client] = false;
	
	g_flNextManaGain[client] = 0.0;
	g_iPlayerPoints[client] = 0;
	g_flPlayerMana[client] = 0.0;
	g_bHasHeGrenade[client] = false;
	
	g_flPlayerNextGrenade[client] = 0.0;
	
	g_bIsFrozen[client] = false;
	g_bHasFrostGrenade[client] = false;
	
	if(g_hTimer_Freeze[client] != null)
	{
		KillTimer(g_hTimer_Freeze[client], true);
		g_hTimer_Freeze[client] = null;
	}
	
	if(g_hTimer_ExplodeSuicideBomb[client] != null)
	{
		KillTimer(g_hTimer_ExplodeSuicideBomb[client]);
		g_hTimer_ExplodeSuicideBomb[client] = null;
	}
	
	if (bConnect)
	{
		g_LastButtons[client] = 0;
		g_iWeaponMenuStep[client] = WEAPONTYPE_PRIMARY;
		g_iLastWeapons[client] =  { 0, 0 };
		g_bSaveLastWeapons[client] = false;
	}
}

void LoadSettingsFromFile()
{
	// To ensure that all settings were loaded correctly.
	ResetDataSettingsArrays();
	LoadDefaultValues();
	
	char szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/nightcrawler.cfg");
	
	KeyValues hKv = CreateKeyValues("NightCrawler");
	
	if (FileExists(szFile))
	{
		FileToKeyValues(hKv, szFile);
		//KvGotoFirstSubKey(hKv, false);
		LoadKeyValues(hKv, false);
	}
	
	else
	{
		LogError("Missing Settings file. Using default values as defined in plugin.");
		
		KvGotoFirstSubKey(hKv, false);
		LoadKeyValues(hKv, true);
		
		KvRewind(hKv);
		KeyValuesToFile(hKv, szFile);
	}
	
	#if CS_TEAM_NC == CS_TEAM_T
	SetConVarString(FindConVar("mp_teamname_2"), g_szNCTeamName, true);
	SetConVarString(FindConVar("mp_teamname_1"), g_szSurvivorTeamName, true);
	#else
	SetConVarString(FindConVar("mp_teamname_2"), g_szSurvivorTeamName, true);
	SetConVarString(FindConVar("mp_teamname_1"), g_szNCTeamName, true);
	#endif
	
	delete hKv;
}

void LoadKeyValues(KeyValues hKv, bool bInsertIntoHandle = false)
{
	enum
	{
		Key_MinimumPlayers = 0, 
		Key_ChooseNCMode, 
		
		Key_SurvivorName,
		Key_SurvivorTeamName,
		Key_NCName,
		Key_NCTeamName,
		
		Key_NCKeepSurvivorsForNextRound,
		Key_NCRatio, 
		Key_NCPointsPerKill, 
		Key_NCSpeedMultiplier, 
		Key_NCGravityMultiplier,
		Key_NCStartingHealth,
		
		Key_SurvivorPointsPerKill, 
		Key_SurvivorHSBonus, 
		Key_InfiniteBPAmmo,
		Key_LaserMode,
		Key_MaxGivenLasers,
		Key_LaserRatio,
		Key_LaserColor_Normal,
		Key_LaserColor_Aim,
		
		Key_ManaName,
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
		
		Key_SuicideBombExplodeTime, 
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
		
		Key_HegrenadeMax, 
		Key_HegrenadeRegenTime, 
		Key_HegrenadeGiveAmount, 
		Key_HegrenadeRegenAmount, 
		
		Key_FrostGrenadeGiveAmount,
		Key_FrostGrenadeRadius,
		//Key_FrostGrenadeActivationDelay,
		Key_FrostGrenadeFreezeDuration,
		Key_FrostGrenadeBeamFollowColor,
		
		Key_SurvivorModels,
		Key_NightcrawlerModels,
		
		Key_Total
	}
	
	char Keys[Key_Total][] =  {
		"MinimumPlayers", 
		"ChooseNightcrawlerMode", 
		
		"Survivor_Name",
		"Survivor_TeamName",
		"Nightcrawler_Name",
		"Nightcrawler_TeamName",
		
		"Nightcrawler_KeepLastRoundSurvivors",
		"Nightcrawler_Ratio", 
		"Nightcrawler_PointsPerKill", 
		"Nightcralwer_SpeedMultiplier", 
		"Nightcrawler_GravityMultiplier",
		"Nightcrawler_StartingHealth",
		
		"Survivor_PointsPerKill", 
		"Survivor_HeadshotBonus", 
		"Survivor_InfiniteBackpackAmmo",
		"Survivor_LaserMode",
		"Survivor_MaxGivenLasers",
		"Survivor_LaserRatio", 
		"Survivor_LaserColor_Normal",
		"Survivor_LaserColor_Aim",
		
		"Mana_Name",
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
		
		"Hegrenade_MaxNades", 
		"Hegrenade_RegenerationTime", 
		"Hegrenade_GiveAmount", 
		"Hegrenade_RegenerationAmount", 
		
		"FrostGrenade_GiveAmount",
		"FrostGrenade_Radius",
		//"FrostGrenade_ActivationDelay",
		"FrostGrenade_FreezeDuration",
		"FrostGrenade_BeamFollowColor",
		
		"Survivor_Models",
		"Nightcrawler_Models"
	};
	
	
	if(bInsertIntoHandle)
	{
		char szFormat[128];
		KvSetNum(hKv, Keys[Key_MinimumPlayers], g_iDefault_MinPlayers);
		KvSetNum(hKv, Keys[Key_ChooseNCMode], g_iDefault_ChooseNCPlayersMode);
		
		KvSetString(hKv, Keys[Key_SurvivorName], g_szDefault_SurvivorName);
		KvSetString(hKv, Keys[Key_SurvivorTeamName], g_szDefault_SurvivorTeamName);
		
		KvSetString(hKv, Keys[Key_NCName], g_szDefault_NCName);
		KvSetString(hKv, Keys[Key_NCTeamName], g_szDefault_NCTeamName);
		
		KvSetNum(hKv, Keys[Key_NCKeepSurvivorsForNextRound], view_as<int>(g_bDefault_KeepSurvivingNC));
		KvSetFloat(hKv, Keys[Key_NCRatio], g_flDefault_NCRatio);
		KvSetNum(hKv, Keys[Key_NCPointsPerKill], g_iDefault_PointsPerKill_NC);
		KvSetFloat(hKv, Keys[Key_NCSpeedMultiplier], g_flDefault_NCSpeedMultiplier);
		KvSetFloat(hKv, Keys[Key_NCGravityMultiplier], g_flDefault_NCGravityMultiplier);
		KvSetFloat(hKv, Keys[Key_NCStartingHealth], g_flDefault_NCStartingHealth);
		
		KvSetNum(hKv, Keys[Key_SurvivorPointsPerKill], g_iDefault_PointsPerKill_Survivor);
		KvSetNum(hKv, Keys[Key_SurvivorHSBonus], g_iDefault_PointsHSBonus);
		KvSetNum(hKv, Keys[Key_InfiniteBPAmmo], view_as<int>(g_bDefault_InfiniteBPAmmo));
		KvSetFloat(hKv, Keys[Key_LaserRatio], g_flDefault_LaserRatio);
		KvSetNum(hKv, Keys[Key_LaserMode], g_iDefault_LaserMode);
		KvSetNum(hKv, Keys[Key_MaxGivenLasers], g_iDefault_MaxGivenLaserCount);
		
		FormatEx(szFormat, sizeof szFormat, "%d %d %d %d", g_iDefault_SurvivorLaserColor_Normal[0], g_iDefault_SurvivorLaserColor_Normal[1], g_iDefault_SurvivorLaserColor_Normal[2], g_iDefault_SurvivorLaserColor_Normal[3]);
		KvSetString(hKv, Keys[Key_LaserColor_Normal], szFormat);
		
		FormatEx(szFormat, sizeof szFormat, "%d %d %d %d", g_iDefault_SurvivorLaserColor_Aim[0], g_iDefault_SurvivorLaserColor_Aim[1], g_iDefault_SurvivorLaserColor_Aim[2], g_iDefault_SurvivorLaserColor_Aim[3]);
		KvSetString(hKv, Keys[Key_LaserColor_Aim], szFormat);
		
		KvSetString(hKv, Keys[Key_ManaName], g_szDefault_ManaName);
		KvSetFloat(hKv, Keys[Key_MaxMana], g_flDefault_MaxMana);
		KvSetFloat(hKv, Keys[Key_ManaRegenTime], g_flDefault_ManaRegenTime);
		KvSetFloat(hKv, Keys[Key_ManaRegenAmount], g_flDefault_ManaRegenAmount);
		KvSetFloat(hKv, Keys[Key_ManaTeleportCost], g_flDefault_ManaTeleportCost);
		KvSetFloat(hKv, Keys[Key_WeaponsChooseTime], g_flDefault_ChooseWeaponTime);
		
		KvSetString(hKv, Keys[Key_LightStyle],g_szDefault_LightStyle);
		KvSetNum(hKv, Keys[Key_MakeFog], view_as<int>(g_bDefault_MakeFog));
		KvSetNum(hKv, Keys[Key_RemoveShadows], view_as<int>(g_bDefault_RemoveShadows));
		
		KvSetFloat(hKv, Keys[Key_MinePlacementMaxDistance], g_flDefault_MinePlacement_MaxDistanceFromWall);
		KvSetNum(hKv, Keys[Key_MineMaxPlayers], g_iDefault_MineMaxPlayers);
		KvSetNum(hKv, Keys[Key_MineGiveAmount], g_iDefault_MineGiveCount);
		KvSetFloat(hKv, Keys[Key_MinePlacementTime], g_flDefault_MinePlacement_PlacementTime);
		KvSetFloat(hKv, Keys[Key_MineActivateTime], g_flDefault_MineActivateTime);
		
		FormatEx(szFormat, sizeof szFormat, "%d %d %d %d", g_iDefault_MineLaserColor_Normal[0], g_iDefault_MineLaserColor_Normal[1], g_iDefault_MineLaserColor_Normal[2], g_iDefault_MineLaserColor_Normal[3]);
		KvSetString(hKv, Keys[Key_MineLaserColor_Normal], szFormat);
		
		FormatEx(szFormat, sizeof szFormat, "%d %d %d %d", g_iDefault_MineLaserColor_Aim[0], g_iDefault_MineLaserColor_Aim[1], g_iDefault_MineLaserColor_Aim[2], g_iDefault_MineLaserColor_Aim[3]);
		KvSetString(hKv, Keys[Key_MineLaserColor_Aim], szFormat);
		
		KvSetFloat(hKv, Keys[Key_SuicideBombExplodeTime], g_flDefault_SuicideBombExplodeTime);
		KvSetFloat(hKv, Keys[Key_SuicideBomb_MaxDamage], g_flDefault_SuicideBombDamage);
		KvSetFloat(hKv, Keys[Key_SuicideBomb_Radius], g_flDefault_SuicideBombRadius);
		
		KvSetFloat(hKv, Keys[Key_AdrenalineSpeedMultiplier], g_flDefault_AdrenalineSpeedMultiplier);
		KvSetFloat(hKv, Keys[Key_AdrenalineAttackSpeedMultiplier], g_flDefault_AdrenalineAttackSpeedMultiplier);
		KvSetNum(hKv, Keys[Key_AdrenalineExtraHealth], g_iDefault_AdrenalineExtraHealth);
		KvSetFloat(hKv, Keys[Key_AdrenalineTime], g_flDefault_AdrenalineTime);
		
		KvSetFloat(hKv, Keys[Key_DetectorUpdateTime], g_flDefault_DetectorUpdateTime);
		KvSetNum(hKv, Keys[Key_DetectorMaxPlayers], g_iDefault_DetectorMaxPlayers);
		KvSetFloat(hKv, Keys[Key_DetectorUnitsPerChar], g_flDefault_Detector_UnitsPerChar);
		KvSetFloat(hKv, Keys[Key_DetectorRadius], g_flDefault_Detector_Radius);
		KvSetString(hKv, Keys[Key_DetectorNormalColor], g_szDefault_DetectorNormalColor);
		KvSetString(hKv, Keys[Key_DetectorCloseColor], g_szDefault_DetectorCloseColor);
		KvSetString(hKv, Keys[Key_DetectorDefaultMessage], g_szDefault_DetectorDefaultMessage);
		
		KvSetFloat(hKv, Keys[Key_HegrenadeRegenTime], g_flDefault_HegrenadeRegenTime);
		KvSetNum(hKv, Keys[Key_HegrenadeMax], g_iDefault_HegrenadeMax);
		KvSetNum(hKv, Keys[Key_HegrenadeGiveAmount], g_iDefault_HegrenadeGiveAmount);
		KvSetNum(hKv, Keys[Key_HegrenadeRegenAmount], g_iDefault_HegrenadeRegenAmount);
		
		KvSetNum(hKv, Keys[Key_FrostGrenadeGiveAmount], g_iDefault_FrostGrenadeGiveAmount);
		KvSetFloat(hKv, Keys[Key_FrostGrenadeRadius], g_flDefault_FrostGrenadeRadius);
		//KvSetFloat(hKv, Keys[Key_FrostGrenadeActivationDelay], g_flDefault_FrostGrenadeActivationDelay);
		KvSetFloat(hKv, Keys[Key_FrostGrenadeFreezeDuration], g_flDefault_FrostGrenadeFreezeDuration);
		
		FormatEx(szFormat, sizeof szFormat, "%d %d %d %d", g_iDefault_FrostGrenadeBeamFollowColor[0], g_iDefault_FrostGrenadeBeamFollowColor[1], g_iDefault_FrostGrenadeBeamFollowColor[2], g_iDefault_FrostGrenadeBeamFollowColor[3]);
		KvSetString(hKv, Keys[Key_FrostGrenadeBeamFollowColor], szFormat);
		
		KvJumpToKey(hKv, Keys[Key_SurvivorModels], true);
		hKv.GotoFirstSubKey(false);
		KvSetString(hKv, "1", " ");
		hKv.Rewind();
		
		KvJumpToKey(hKv, Keys[Key_NightcrawlerModels], true);
		hKv.GotoFirstSubKey(false);
		KvSetString(hKv, "1", " ");
		hKv.Rewind();
	}
	
	g_iMinPlayers = KvGetNum(hKv, Keys[Key_MinimumPlayers], g_iDefault_MinPlayers);
	g_iChooseNCPlayersMode = KvGetNum(hKv, Keys[Key_ChooseNCMode], g_iDefault_ChooseNCPlayersMode);
	
	KvGetString(hKv, Keys[Key_SurvivorName], g_szSurvivorName, sizeof g_szSurvivorName, g_szDefault_SurvivorName);
	KvGetString(hKv, Keys[Key_SurvivorTeamName], g_szSurvivorTeamName, sizeof g_szSurvivorTeamName, g_szDefault_SurvivorTeamName);
		
	KvGetString(hKv, Keys[Key_NCName], g_szNCName, sizeof g_szNCName, g_szDefault_NCName);
	KvGetString(hKv, Keys[Key_NCTeamName], g_szNCTeamName, sizeof g_szNCTeamName, g_szDefault_NCTeamName);
	
	g_bKeepSurvivingNC = view_as<bool>(KvGetNum(hKv, Keys[Key_NCKeepSurvivorsForNextRound], view_as<int>(g_bDefault_KeepSurvivingNC)));
	g_flNCRatio = KvGetFloat(hKv, Keys[Key_NCRatio], g_flDefault_NCRatio);
	g_iPointsPerKill_NC = KvGetNum(hKv, Keys[Key_NCPointsPerKill], g_iDefault_PointsPerKill_NC);
	g_flNCSpeedMultiplier = KvGetFloat(hKv, Keys[Key_NCSpeedMultiplier], g_flDefault_NCSpeedMultiplier);
	g_flNCGravityMultiplier = KvGetFloat(hKv, Keys[Key_NCGravityMultiplier], g_flDefault_NCGravityMultiplier);
	g_flNCStartingHealth = KvGetFloat(hKv, Keys[Key_NCStartingHealth], g_flDefault_NCStartingHealth);
	
	g_iPointsPerKill_Survivor = KvGetNum(hKv, Keys[Key_SurvivorPointsPerKill], g_iDefault_PointsPerKill_Survivor);
	g_iPointsHSBonus = KvGetNum(hKv, Keys[Key_SurvivorHSBonus], g_iDefault_PointsHSBonus);
	g_bInfiniteBPAmmo = view_as<bool>(KvGetNum(hKv, Keys[Key_InfiniteBPAmmo], view_as<int>(g_bDefault_InfiniteBPAmmo)));
	g_flLaserRatio = KvGetFloat(hKv, Keys[Key_LaserRatio], g_flDefault_LaserRatio);
	g_iLaserMode = KvGetNum(hKv, Keys[Key_LaserMode], g_iDefault_LaserMode);
	g_iMaxGivenLaserCount = KvGetNum(hKv, Keys[Key_MaxGivenLasers], g_iDefault_MaxGivenLaserCount);
	
	if (KvJumpToKey(hKv, Keys[Key_LaserColor_Normal], false))
	{
		KvGoBack(hKv);
		KvGetColor(hKv, Keys[Key_LaserColor_Normal], g_iSurvivorLaserColor_Normal[0], g_iSurvivorLaserColor_Normal[1], 
			g_iSurvivorLaserColor_Normal[2], g_iSurvivorLaserColor_Normal[3]);
	}
	
	if (KvJumpToKey(hKv, Keys[Key_LaserColor_Aim], false))
	{
		KvGoBack(hKv);
		KvGetColor(hKv, Keys[Key_LaserColor_Aim], g_iSurvivorLaserColor_Aim[0], g_iSurvivorLaserColor_Aim[1], 
			g_iSurvivorLaserColor_Aim[2], g_iSurvivorLaserColor_Aim[3]);
	}
	
	KvGetString(hKv, Keys[Key_ManaName], g_szManaName, sizeof g_szManaName, g_szDefault_ManaName);
	g_flMaxMana = KvGetFloat(hKv, Keys[Key_MaxMana], g_flDefault_MaxMana);
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
	g_flMineActivateTime = KvGetFloat(hKv, Keys[Key_MineActivateTime], g_flDefault_MineActivateTime);
	
	if (KvJumpToKey(hKv, Keys[Key_MineLaserColor_Normal], false))
	{
		KvGoBack(hKv);
		KvGetColor(hKv, Keys[Key_MineLaserColor_Normal], g_iMineLaserColor_Normal[0], g_iMineLaserColor_Normal[1], 
			g_iMineLaserColor_Normal[2], g_iMineLaserColor_Normal[3]);
	}
	
	if (KvJumpToKey(hKv, Keys[Key_MineLaserColor_Aim], false))
	{
		KvGoBack(hKv);
		KvGetColor(hKv, Keys[Key_MineLaserColor_Aim], g_iMineLaserColor_Aim[0], g_iMineLaserColor_Aim[1], 
			g_iMineLaserColor_Aim[2], g_iMineLaserColor_Aim[3]);
	}
	
	g_flSuicideBombExplodeTime = KvGetFloat(hKv, Keys[Key_SuicideBombExplodeTime], g_flDefault_SuicideBombExplodeTime);
	g_flSuicideBombDamage = KvGetFloat(hKv, Keys[Key_SuicideBomb_MaxDamage], g_flDefault_SuicideBombDamage);
	g_flSuicideBombRadius = KvGetFloat(hKv, Keys[Key_SuicideBomb_Radius], g_flDefault_SuicideBombRadius);
	
	g_flAdrenalineSpeedMultiplier = KvGetFloat(hKv, Keys[Key_AdrenalineSpeedMultiplier], g_flDefault_AdrenalineSpeedMultiplier);
	g_flAdrenalineAttackSpeedMultiplier = KvGetFloat(hKv, Keys[Key_AdrenalineAttackSpeedMultiplier], g_flDefault_AdrenalineAttackSpeedMultiplier);
	g_iAdrenalineExtraHealth = KvGetNum(hKv, Keys[Key_AdrenalineExtraHealth], g_iDefault_AdrenalineExtraHealth);
	g_flAdrenalineTime = KvGetFloat(hKv, Keys[Key_AdrenalineTime], g_flDefault_AdrenalineTime);
	
	g_flDetectorUpdateTime = KvGetFloat(hKv, Keys[Key_DetectorUpdateTime], g_flDefault_DetectorUpdateTime);
	g_iDetectorMaxPlayers = KvGetNum(hKv, Keys[Key_DetectorMaxPlayers], g_iDefault_DetectorMaxPlayers);
	g_flDetector_UnitsPerChar = KvGetFloat(hKv, Keys[Key_DetectorUnitsPerChar], g_flDefault_Detector_UnitsPerChar);
	g_flDetector_Radius = KvGetFloat(hKv, Keys[Key_DetectorRadius], g_flDefault_Detector_Radius);
	KvGetString(hKv, Keys[Key_DetectorNormalColor], g_szDetectorNormalColor, sizeof g_szDetectorNormalColor, g_szDefault_DetectorNormalColor);
	KvGetString(hKv, Keys[Key_DetectorCloseColor], g_szDetectorCloseColor, sizeof g_szDetectorCloseColor, g_szDefault_DetectorCloseColor);
	KvGetString(hKv, Keys[Key_DetectorDefaultMessage], g_szDetectorDefaultMessage, sizeof g_szDetectorDefaultMessage, g_szDefault_DetectorDefaultMessage);
	
	g_flHegrenadeRegenTime = KvGetFloat(hKv, Keys[Key_HegrenadeRegenTime], g_flDefault_HegrenadeRegenTime);
	g_iHegrenadeMax = KvGetNum(hKv, Keys[Key_HegrenadeMax], g_iDefault_HegrenadeMax);
	g_iHegrenadeGiveAmount = KvGetNum(hKv, Keys[Key_HegrenadeGiveAmount], g_iDefault_HegrenadeGiveAmount);
	g_iHegrenadeRegenAmount = KvGetNum(hKv, Keys[Key_HegrenadeRegenAmount], g_iDefault_HegrenadeRegenAmount);
	
	g_iFrostGrenadeGiveAmount = KvGetNum(hKv, Keys[Key_FrostGrenadeGiveAmount], g_iDefault_FrostGrenadeGiveAmount);
	g_flFrostGrenadeRadius = KvGetFloat(hKv, Keys[Key_FrostGrenadeRadius], g_flDefault_FrostGrenadeRadius);
	//g_flFrostGrenadeActivationDelay = KvGetFloat(hKv, Keys[Key_FrostGrenadeActivationDelay], g_flDefault_FrostGrenadeActivationDelay);
	g_flFrostGrenadeFreezeDuration = KvGetFloat(hKv, Keys[Key_FrostGrenadeFreezeDuration], g_flDefault_FrostGrenadeFreezeDuration);
	
	if (KvJumpToKey(hKv, Keys[Key_FrostGrenadeBeamFollowColor], false))
	{
		KvGoBack(hKv);
		KvGetColor(hKv, Keys[Key_FrostGrenadeBeamFollowColor], g_iFrostGrenadeBeamFollowColor[0], g_iFrostGrenadeBeamFollowColor[1], 
			g_iFrostGrenadeBeamFollowColor[2], g_iFrostGrenadeBeamFollowColor[3]);
	}
	
	char szMdl[PLATFORM_MAX_PATH];
	if (KvJumpToKey(hKv, Keys[Key_SurvivorModels], false))
	{
		if(hKv.GotoFirstSubKey(false))
		{
			do
			{
				hKv.GetString(NULL_STRING, szMdl, sizeof szMdl, "");
				TrimString(szMdl);
				
				if(szMdl[0])
				{
					g_Array_SurvivorModels.PushString(szMdl);
					g_iSurvivorModelsCount++;
					PrecacheModel(szMdl);
				}
			}
			while (hKv.GotoNextKey(false));
			
			hKv.GoBack();
		}
		
		hKv.GoBack();
	}
	
	if (KvJumpToKey(hKv, Keys[Key_NightcrawlerModels], false))
	{
		if(hKv.GotoFirstSubKey(false))
		{
			do
			{
				hKv.GetString(NULL_STRING, szMdl, sizeof szMdl, "");
				TrimString(szMdl);
				
				if(szMdl[0])
				{
					g_Array_NightcrawlerModels.PushString(szMdl);
					g_iNightcrawlerModelsCount++;
					PrecacheModel(szMdl);
				}
			}
			while (hKv.GotoNextKey(false));
			
			hKv.GoBack();
		}
		
		hKv.GoBack();
	}
		
	for (int i; i < Key_Total; i++)
	{
		if (!KvJumpToKey(hKv, Keys[i], false))
		{
			LogMessage("Key '%s' was not found in the config file. (%d)", Keys[i], hKv.NodesInStack());
			continue;
		}
		
		KvGoBack(hKv);
	}
}

void LoadDefaultValues()
{
	g_iMinPlayers = g_iDefault_MinPlayers;
	g_iChooseNCPlayersMode = g_iDefault_ChooseNCPlayersMode;
	
	g_flNCSpeedMultiplier = g_flDefault_NCSpeedMultiplier;
	g_flNCGravityMultiplier = g_flDefault_NCGravityMultiplier;
	
	strcopy(g_szSurvivorName, sizeof g_szSurvivorName, g_szDefault_SurvivorName);
	strcopy(g_szSurvivorTeamName, sizeof g_szSurvivorTeamName, g_szDefault_SurvivorTeamName);
		
	strcopy(g_szNCName, sizeof g_szNCName, g_szDefault_NCName);
	strcopy(g_szNCTeamName, sizeof g_szNCTeamName, g_szDefault_NCTeamName);
	
	g_flNCStartingHealth = g_flDefault_NCStartingHealth;
	
	g_bKeepSurvivingNC = g_bDefault_KeepSurvivingNC;
	g_flNCRatio = g_flDefault_NCRatio;
	g_iLaserMode = g_iDefault_LaserMode;
	g_iMaxGivenLaserCount = g_iDefault_MaxGivenLaserCount;
	g_flLaserRatio = g_flDefault_LaserRatio;
	g_iPointsPerKill_NC = g_iDefault_PointsPerKill_NC;
	g_iPointsHSBonus = g_iDefault_PointsHSBonus;
	g_iPointsPerKill_Survivor = g_iDefault_PointsPerKill_Survivor;
	
	strcopy(g_szManaName, sizeof g_szManaName, g_szDefault_ManaName);
	g_flMaxMana = g_flDefault_MaxMana;
	g_flManaRegenTime = g_flDefault_ManaRegenTime;
	g_flManaRegenAmount = g_flDefault_ManaRegenAmount;
	g_flManaTeleportCost = g_flDefault_ManaTeleportCost;
	
	g_flChooseWeaponTime = g_flDefault_ChooseWeaponTime;
	
	g_szLightStyle = g_szDefault_LightStyle;
	
	g_flNCVisibleTime = g_flDefault_NCVisibleTime;
	g_bBlockFallDamage_NC = g_bDefault_BlockFallDamage_NC;
	
	g_bRemoveShadows = g_bDefault_RemoveShadows;
	g_bMakeFog = g_bDefault_MakeFog;
	
	g_flMinePlacement_MaxDistanceFromWall = g_flDefault_MinePlacement_MaxDistanceFromWall;
	g_iMineMaxPlayers = g_iDefault_MineMaxPlayers;
	g_iMineGiveCount = g_iDefault_MineGiveCount;
	g_flMinePlacement_PlacementTime = g_flDefault_MinePlacement_PlacementTime;
	g_iMineLaserColor_Normal = g_iDefault_MineLaserColor_Normal;
	g_iMineLaserColor_Aim = g_iDefault_MineLaserColor_Aim;
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
	g_flDetector_Radius = g_flDefault_Detector_Radius;
	g_szDetectorCloseColor = g_szDefault_DetectorCloseColor;
	g_szDetectorNormalColor = g_szDefault_DetectorNormalColor;
	g_szDetectorDefaultMessage = g_szDefault_DetectorDefaultMessage;
	
	g_flHegrenadeRegenTime = g_flDefault_HegrenadeRegenTime;
	g_iHegrenadeMax = g_iDefault_HegrenadeMax;
	g_iHegrenadeGiveAmount = g_iDefault_HegrenadeGiveAmount;
	g_iHegrenadeRegenAmount = g_iDefault_HegrenadeRegenAmount;
	
	g_iFrostGrenadeGiveAmount = g_iDefault_FrostGrenadeGiveAmount;
	g_flFrostGrenadeRadius = g_flDefault_FrostGrenadeRadius;
	//g_flFrostGrenadeActivationDelay = g_flDefault_FrostGrenadeActivationDelay;
	g_flFrostGrenadeFreezeDuration = g_flDefault_FrostGrenadeFreezeDuration;
	g_iFrostGrenadeBeamFollowColor = g_iDefault_FrostGrenadeBeamFollowColor;
	
	g_bInfiniteBPAmmo = g_bDefault_InfiniteBPAmmo;
}

void ResetDataSettingsArrays()
{
	if (g_bFirstRun)
	{
		g_bFirstRun = false;
		
		g_Array_WeaponReserveAmmo = CreateArray(1);
		g_Array_WeaponGiveName = CreateArray(25);
		g_Array_NCQueue = new ArrayList(1);
		
		g_Array_NightcrawlerModels = new ArrayList(PLATFORM_MAX_PATH);
		g_Array_SurvivorModels = new ArrayList(PLATFORM_MAX_PATH);
	}
	
	else
	{
		ClearArray(g_Array_WeaponReserveAmmo);
		ClearArray(g_Array_WeaponGiveName);
		ClearArray(g_Array_NCQueue); g_iNCQueueCount = 0;
		
		
		ClearArray(g_Array_SurvivorModels); g_iSurvivorModelsCount = 0;
		ClearArray(g_Array_NightcrawlerModels); g_iNightcrawlerModelsCount = 0;
		
		delete g_hItemMenu;
		delete g_hMainMenu;
		delete g_hWeaponMenu_Main;
		delete g_hWeaponMenu_Sec;
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

void ParseWeaponsMenuFile()
{
	char szFile[PLATFORM_MAX_PATH];
	char szLine[125];
	
	int iStep = 0;
	
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/nightcrawler_weaponmenu.ini");
	
	PluginLog("Path: %s", szFile);
	
	if (!FileExists(szFile))
	{
		CreateWeaponsMenuFile(szFile);
	}
	
	File f = OpenFile(szFile, "r");
	
	if (f == null)
	{
		SetFailState("Failed to open weapons file: %s", szFile);
		return;
	}
	
	// Format:
	// Order Matters
	// Type:Suffix:"give_name":"Menu Name"
	while (ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		PluginLog("Read Line: %s", szLine);
		
		if (szLine[0] == ';' || szLine[0] == '#' || (szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		if (StrEqual(szLine, "[Weapon Suffixes]", false))
		{
			iStep = 1;
			continue;
		}
		
		else if (StrEqual(szLine, "[Weapons]", false))
		{
			iStep = 2;
			continue;
		}
		
		// This is in the function loop because I need the string to reset each
		// single loop
		
		char szStringParts[5][35];
		switch (iStep)
		{
			case 0:
			{
				continue;
			}
			case 1:
			{
				ExplodeString(szLine, ":", szStringParts, 2, sizeof szStringParts[], true);
				CleanStrings(szStringParts, 2, sizeof szStringParts[]);
				
				SetTrieString(g_Trie_WeaponSuffix, szStringParts[0], szStringParts[1]);
			}
			case 2:
			{
				PluginLog("Add Line to gun menu %s", szLine);
				
				ExplodeString(szLine, ":", szStringParts, sizeof szStringParts, sizeof szStringParts[], true);
				
				CleanStrings(szStringParts, sizeof szStringParts, sizeof szStringParts[]);
				
				PushArrayCell(g_Array_WeaponType, StringToInt(szStringParts[0]));
				PushArrayCell(g_Array_WeaponSuffix, StringToInt(szStringParts[1]));
				PushArrayString(g_Array_WeaponGiveName, szStringParts[2]);
				PushArrayString(g_Array_WeaponName, szStringParts[3]);
				
				if (!szStringParts[4][0] || StringToInt(szStringParts[4]) < 0)
				{
					szStringParts[4][0] = '-';
					szStringParts[4][1] = '1';
					szStringParts[4][2] = 0;
				}
				
				PushArrayCell(g_Array_WeaponReserveAmmo, StringToInt(szStringParts[4]));
			}
		}
	}
	
	delete f;
}

void CreateWeaponsMenuFile(char[] szFile)
{
	File f = OpenFile(szFile, "w+");
	
	if (f == null)
	{
		LogError("Weapon File wrong path: %s", szFile);
		return;
	}
	
	WriteFileLine(f, "# Auto-Generated File");
	WriteFileLine(f, "# The Weapons menu will be generated based on this file.");
	WriteFileLine(f, "[Weapon Suffixes]");
	WriteFileLine(f, "# In this part, you will assign a number and a suffix using the following format (A value of 0 means no suffix):");
	WriteFileLine(f, "1:Rifle");
	WriteFileLine(f, "2:Sniper Rifle");
	WriteFileLine(f, "3:Shotgun");
	WriteFileLine(f, "4:SMG");
	WriteFileLine(f, "5:Pistol");
	WriteFileLine(f, "");
	WriteFileLine(f, "[Weapons]");
	WriteFileLine(f, "# Order matters! First weapons appear first in menu");
	WriteFileLine(f, "# Skipping BackpackAmmo or putting it to -1 won't will use the default");
	WriteFileLine(f, "# Format:");
	WriteFileLine(f, "# WeaponType(1 for primary, 2 for secondary):WeaponSuffixNumber:WeaponGiveName:WeaponName:BackpackAmmo");
	WriteFileLine(f, "# Examples:");
	WriteFileLine(f, "1:1:weapon_m4a1:M4A4");
	WriteFileLine(f, "1:1:weapon_ak47:AK-47");
	WriteFileLine(f, "1:1:weapon_sg556:SG-556");
	WriteFileLine(f, "1:4:weapon_bizon:PP-Bizon");
	WriteFileLine(f, "1:3:weapon_sawedoff:Sawed-Off");
	WriteFileLine(f, "1:3:weapon_xm1014:XM1014");
	
	WriteFileLine(f, "2:5:weapon_tec9:TEC-9");
	WriteFileLine(f, "2:5:weapon_fiveseven:Five-Seven");
	WriteFileLine(f, "2:5:weapon_hkp2000:P2000");
	WriteFileLine(f, "2:5:weapon_usp_silencer:USP");
	WriteFileLine(f, "2:5:weapon_glock:Glock-18");
	
	
	delete f;
}

void CleanStrings(char[][] szStringParts, int iArraySize, int iStringSize)
{
	for (int i; i < iArraySize; i++)
	{
		TrimString(szStringParts[i]);
		ReplaceString(szStringParts[i], iStringSize, "\"", "");
	}
}

bool IsValidPlayer(int client, bool bAlive = false)
{
	if (!(0 < client <= MaxClients))
	{
		return false;
	}
	
	if (!IsClientInGame(client))
	{
		return false;
	}
	
	if (bAlive)
	{
		if (!IsPlayerAlive(client))
		{
			return false;
		}
	}
	
	return true;
}

// --------------------------------------------------------------------------
//								Custom Funcs
// --------------------------------------------------------------------------
void PluginLog(char[] szMessage, any...)
{
	#if defined LOG_ENABLED
	char szBuffer[1024];
	VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
	
	LogToFileEx(PLUGIN_LOG_FILE, szBuffer);
	#else
	szMessage[0] = 0;
	#endif
}

void SetArrayValue(any[] array, int size, any value, int start = 0)
{
	for (int i = start; i < size; i++)
	{
		array[i] = value;
	}
}