#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <the_khalid_inc>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

#define CS_TEAM_NC			CS_TEAM_T
#define CS_TEAM_SURVIVOR	CS_TEAM_CT
#define CHAR_DASH '-'
#define CHAR_BAR '|'

new const String:PLUGIN_LOG_FILE[] = "addons/sourcemod/logs/nightcrawler.log";
new const String:PLUGIN_CHAT_PREFIX[] = "\x04[NightCrawlers]";
new const String:g_szManaName[] = "Mana";
new const String:g_szNightcrawlerTeamName[] = "NightCrawlers";
new const String:g_szNightcrawlerName[] = "Nightcrawler";
new const String:g_szSurvivorTeamName[] = "Survivors";
new const String:g_szSurvivorName[] = "Survivor";

new const String:MODEL_BEAM[] = "materials/sprites/laserbeam.vmt";

// -- Game State --
bool g_bRunning = false;
bool g_bRoundEnd = false;

float g_flMineLaser_SoundPlayCooldown = 1.05;

#define MODE_RANDOM 0
#define MODE_KILL	1
#define MODE_QUEUE	2

#define WEAPONTYPE_SECONDARY 2
#define WEAPONTYPE_PRIMARY 1

#define HINTMSG_UPDATE_TIME 0.5

// -- Settings #1: Default --
int g_iDefault_MinPlayers = 2;
int g_iDefault_ChooseNCPlayersMode = MODE_RANDOM;

float g_flDefault_NCSpeedMultiplier = 1.05;
float g_flDefault_NCGravityMultiplier = 0.7;

float g_flDefault_NCRatio = 3.0;
float g_flDefault_LaserRatio = 3.0;
int g_iDefault_PointsPerKill_NC = 3;
int g_iDefault_PointsHSBonus = 1;
int g_iDefault_PointsPerKill_Survivor = 1;

float g_flDefault_MaxMana = 200.0;
float g_flDefault_ManaRegenTime = 1.5;
float g_flDefault_ManaRegenAmount = 3.5;
float g_flDefault_ManaTeleportCost = 75.0;

float g_flDefault_ChooseWeaponTime = 25.0;

char g_szDefault_LightStyle[3] = "b";

float g_flDefault_NCVisibleTime = 2.3;
bool g_bDefault_BlockFallDamage_NC = true;

bool g_bDefault_RemoveShadows = true;
bool g_bDefault_MakeFog = true;

float g_flDefault_MinePlacement_MaxDistanceFromWall = 20.0;
int g_iDefault_MineMaxPlayers = 3;
int g_iDefault_MineGiveCount = 2;
float g_flDefault_MinePlacement_PlacementTime = 3.0;
//new const String:g_szDefault_MineLaserColor[12] = "0 0 200";
int g_iDefault_MineLaserColor_Normal[4] =  { 0, 0, 200, 255 };
int g_iDefault_MineLaserColor_Aim[4] =  { 0, 0, 200, 255 };
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
float g_flDefault_Detector_Radius = 525.0;
char g_szDefault_DetectorNormalColor[10] = "#FFFFFF";
char g_szDefault_DetectorCloseColor[10] = "#FF0000";
char g_szDefault_DetectorDefaultMessage[35] = "NC Detector:\n\t";

int g_iDefault_HegrenadeGiveAmount = 2;
int g_iDefault_HegrenadeRegenAmount = 1;
int g_iDefault_HegrenadeMax = 3;
float g_flDefault_HegrenadeRegenTime = 60.0;

// -- Settings #2 Actual s--
int g_iMinPlayers;
int g_iChooseNCPlayersMode;

float g_flNCSpeedMultiplier;
float g_flNCGravityMultiplier;

float g_flNCRatio;
float g_flLaserRatio;
int g_iPointsPerKill_NC;
int g_iPointsHSBonus;
int g_iPointsPerKill_Survivor;

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

new const String:g_szMineTargetName[] = "rxgmine";
new const String:g_szMineLaserTargetName[] = "rxgmine_laser";
new const String:g_szPlayerLaserTargetName[] = "player_laser_detector";

// -------------------------------
// -- Player Data --
// -------------------------------
bool g_bDontShowPlayer[MAXPLAYERS];
bool g_bKilledNC[MAXPLAYERS];
bool g_bLaser[MAXPLAYERS];
int g_iLaserEnt[MAXPLAYERS];
int g_iLaserCount;

// Items
bool g_bHasChosenItemThisRound[MAXPLAYERS];
int g_iPlayerMinesCount[MAXPLAYERS];
float g_vPlaceMineOrigin[MAXPLAYERS][3];
Handle g_hPlaceMineTimer[MAXPLAYERS];
float g_flMineLaser_PlayerTouch_SoundPlayCooldown[MAXPLAYERS];

bool g_bHasSuicideBomb[MAXPLAYERS];
bool g_bSuicideBombActivated[MAXPLAYERS];
float g_vDeathPosition[MAXPLAYERS][3];

bool g_bHasAdrenaline[MAXPLAYERS];
bool g_bAdrenalineActivated[MAXPLAYERS];
float g_flNextModifyTime[MAXPLAYERS];

Handle g_hDetectorTimer[MAXPLAYERS];

// WeaponMenu;
bool g_bHasChosenWeaponsThisRound[MAXPLAYERS];
int g_iWeaponMenuStep[MAXPLAYERS];
int g_iLastWeapons[MAXPLAYERS][2];
bool g_bSaveLastWeapons[MAXPLAYERS];

// ManaStuff;
float g_flNextManaGain[MAXPLAYERS];
int g_iPlayerPoints[MAXPLAYERS];
float g_flPlayerMana[MAXPLAYERS];

bool g_bHasHeGrenade[MAXPLAYERS];
float g_flPlayerNextGrenade[MAXPLAYERS];

#define MAX_BUTTONS 25
int g_LastButtons[MAXPLAYERS];

// -- Misc --
Handle g_hTimer, g_hHintMessageTimer;
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

float g_flWeaponMenuExpireTime;
int g_iWeapons_Clip1Offset;

bool g_bFirstRun = true;

// --- Shop Items ---
enum
{
	ITEM_LASER, 
	ITEM_LASERMINE, 
	ITEM_ADRENALINE, 
	ITEM_SUICIDEBOMB, 
	ITEM_DETECTOR, 
	ITEM_HEGRENADE, 
	
	MAX_PLAYER_ITEMS
};

enum PlayerItems
{
	PlayerItem_Enabled, String:PlayerItem_Name[20]
};

int g_iItemsData[][PlayerItems] =  {
	{ 0, "Laser Detector" }, 
	{ 1, "Laser Mines [2]" }, 
	{ 1, "Adrenaline" }, 
	{ 1, "Suicide Bomb" }, 
	{ 1, "Detector Bar" }, 
	{ 1, "He grenades [2] with Regen" }
};

char g_szNightcrawlerPlayerModel[][PLATFORM_MAX_PATH] =  {
	""
};
char g_szSurvivorPlayerModel[][PLATFORM_MAX_PATH] =  {
	"models/player/custom_player/marvel/deadpool/deadpool_red_v2.mdl"
};

new const String:g_szMineModel[] = "models/tripmine/tripmine.mdl";
new const String:g_szMinePlacementSound[] = "nightcrawler/mine_deploy.wav";
new const String:g_szMineArmedSound[] = "nightcrawler/mine_activate.wav";
new const String:g_szMineArmingSound[] = "nightcrawler/mine_charge.wav";
new const String:g_szMineLaserTouchSound[] = "nightcrawler/sonic_sound.wav";

new const String:g_szTeleportSound[] = "nightcrawler/teleport.wav";
new const String:g_szAdrenalineInjectionSound[] = "nightcrawler/adrenaline_shot.wav";
new const String:g_szNightcrawlerDeathSound[][] =  {
	"nightcrawler/nc_death1.wav", 
	"nightcrawler/nc_death2.wav", 
	"nightcrawler/nc_death3.wav"
};

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
	for (new i = 0; i < MAX_BUTTONS; i++)
	{
		new button = (1 << i);
		
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
	decl Float:trace_start[3], Float:trace_angle[3], Float:trace_end[3];
	GetClientEyePosition(client, trace_start);
	GetClientEyeAngles(client, trace_angle);
	GetAngleVectors(trace_angle, trace_end, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(trace_end, trace_end); // end = normal
	
	for (new i = 0; i < 3; i++)
	trace_end[i] = trace_start[i] + trace_end[i] * g_flMinePlacement_MaxDistanceFromWall;
	
	TR_TraceRayFilter(trace_start, trace_end, CONTENTS_SOLID | CONTENTS_WINDOW, RayType_EndPoint, TraceFilter_Callback, client);
	
	if (TR_DidHit(INVALID_HANDLE)) {
		return true;
	}
	
	return false;
}

void OnButtonPress(client, button)
{
	if (button & IN_USE)
	{
		if (GetClientTeam(client) == CS_TEAM_SURVIVOR)
		{
			if (g_iPlayerMinesCount[client] > 0)
			{
				if (CanPlaceMineOnWall(client))
				{
					g_hPlaceMineTimer[client] = CreateTimer(g_flMinePlacement_PlacementTime, Timer_PlaceMine, client);
					GetClientAbsOrigin(client, g_vPlaceMineOrigin[client]);
				}
				
				else
				{
					PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Please aim somewhere else to place the mine.");
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
	if (button & IN_USE && g_hPlaceMineTimer[client] != INVALID_HANDLE)
	{
		delete g_hPlaceMineTimer[client];
		g_hPlaceMineTimer[client] = INVALID_HANDLE;
	}
}

void ActivateSuicideBomb(int client)
{
	PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have activated the bomb! You will explode in \x04%0.0f \x01second!", g_flSuicideBombExplodeTime);
	CreateTimer(g_flSuicideBombExplodeTime, Timer_ExplodeSuicideBomb, client);
}

public Action Timer_ExplodeSuicideBomb(Handle hTimer, int client)
{
	if (!IsClientInGame(client))
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
	ForcePlayerSuicide(client);
}

stock void MakeExplosion(int client, float vOrigin[3] =  { 0.0, 0.0, 0.0 } )
{
	int explosion = CreateEntityByName("env_explosion");
	
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
		
		SetEntProp(explosion, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(explosion, Prop_Data, "m_spawnflags", 264);
		SetEntProp(explosion, Prop_Data, "m_iMagnitude", g_flSuicideBombDamage);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", g_flSuicideBombRadius);
		DispatchKeyValue(explosion, "rendermode", "5");
		
		DispatchSpawn(explosion);
		ActivateEntity(explosion);
		
		TeleportEntity(explosion, vOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode");
		
		EmitSoundToAll("weapons/hegrenade/explode5.wav", explosion, 1, 90);
		EmitSoundToAll("ambient/explosions/explode_8.wav", explosion, 1, 90);
	}
}

void ActivateAdrenaline(int client)
{
	PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have injected yourself with Adrenaline!");
	PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You will move and shoot faster!");
	PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have gained extra health!");
	
	g_bAdrenalineActivated[client] = true;
	SetClientSpeed(client, g_flAdrenalineSpeedMultiplier);
	SetEntityHealth(client, GetEntProp(client, Prop_Send, "m_iHealth") + g_iAdrenalineExtraHealth);
	
	EmitSoundToClient(client, g_szAdrenalineInjectionSound);
	
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
	
	PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Adrenaline wore off.");
}

void ModifyAttackSpeed(int client)
{
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iWeapon != INVALID_ENT_REFERENCE)
	{
		float flNextPrimaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
		//float flNextAttack = GetEntPropFloat(client, Prop_Send, "m_flNextAttack");
		
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
	g_hPlaceMineTimer[client] = INVALID_HANDLE;
	
	if (g_iPlayerMinesCount[client] <= 0)
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
		
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Laser Mines Left: %d mines", g_iPlayerMinesCount[client]);
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
	trace_end[i] = trace_start[i] + trace_end[i] * g_flMinePlacement_MaxDistanceFromWall;
	
	TR_TraceRayFilter(trace_start, trace_end, CONTENTS_SOLID | CONTENTS_WINDOW, RayType_EndPoint, TraceFilter_Callback, client);
	
	if (TR_DidHit(INVALID_HANDLE)) {
		TR_GetEndPosition(trace_end, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, trace_normal);
		
		return SetupMine(trace_end, trace_normal);
		
	} else {
		//PrintCenterText( client, "Invalid mine position." );
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Invalid Mine position.");
	}
	
	return false;
}

bool SetupMine(float position[3], float vnormal[3])
{
	new Float:angles[3];
	GetVectorAngles(vnormal, angles);
	
	new ent = CreateEntityByName("prop_physics_override");
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
		//SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client); // use this to identify the owner (see below)
		//SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity",client); //Set the owner of the mine (cant, it stops the owner from destroying it)
		SetEntityRenderColor(ent, 255, 255, 255, 255);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2); // set non-collidable
		
		#define MINE_PLACEMENT_OFFSET 1.5
		for (new i = 0; i < 3; i++) {
			position[i] += vnormal[i] * MINE_PLACEMENT_OFFSET;
		}
		
		TeleportEntity(ent, position, angles, NULL_VECTOR); //angles, NULL_VECTOR );
		
		// trace ray for laser (allow passage through windows)
		TR_TraceRayFilter(position, angles, CONTENTS_SOLID, RayType_Infinite, TraceFilter_Callback_PlaceLaser, ent);
		
		new Float:beamend[3];
		TR_GetEndPosition(beamend, INVALID_HANDLE);
		
		// create beam
		new ent_laser = CreateLaser(beamend, position);
		
		// when touched, activate/break the mine
		
		//} else {
		
		// detonate against anything
		//Format(str, sizeof(str), "%s,Break,,0,-1", mine_name);
		//DispatchKeyValue(ent_laser, "OnTouchedByEntity");
		
		new Handle:data;
		data = CreateDataPack();
		WritePackCell(data, ent);
		WritePackCell(data, ent_laser);
		ResetPack(data);
		
		// timer for activating
		CreateTimer(g_flMineActivateTime, ActivateTimer, data, TIMER_DATA_HNDL_CLOSE);
		
		EmitSoundToAll(g_szMinePlacementSound, ent);
		EmitSoundToAll(g_szMineArmingSound, ent);
		
		return true;
	}
	
	return false;
}

public void SDKCallback_ThinkPost_LaserBeam(int iLaserEnt)
{
	float vVecStart[3], vVecEnd[3];
	GetEntPropVector(iLaserEnt, Prop_Data, "m_vecEndPos", vVecEnd);
	GetEntPropVector(iLaserEnt, Prop_Data, "m_vecOrigin", vVecStart);
	
	TR_TraceRayFilter(vVecStart, vVecEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilterCallback_LaserBeam, iLaserEnt);
	
	if (TR_DidHit())
	{
		int iEnt = TR_GetEntityIndex();
		SetEntityRenderColor(iLaserEnt, g_iMineLaserColor_Aim[0], g_iMineLaserColor_Aim[1], g_iMineLaserColor_Aim[2], g_iMineLaserColor_Aim[3]);
		
		// Sound is played in the TraceFilterCallback because I didn't want to limit the sound to just one entity, but all
		// Entities touching the laser.
		// UPDATE: I Guess I have to leave it here because .... RenderColor :/
		float flGameTime;
		
		if (g_flMineLaser_PlayerTouch_SoundPlayCooldown[iEnt] < (flGameTime = GetGameTime()))
		{
			g_flMineLaser_PlayerTouch_SoundPlayCooldown[iEnt] = flGameTime + g_flMineLaser_SoundPlayCooldown;
			EmitSoundToAll(g_szMineLaserTouchSound, iEnt);
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
	
	if(GetClientTeam(iEnt) != CS_TEAM_NC)
	{
		return false;
	}
	
	return false;
}

public Action ActivateTimer(Handle timer, Handle data)
{
	ResetPack(data);
	
	int ent = ReadPackCell(data);
	int ent_laser = ReadPackCell(data);
	
	if (!IsValidEntity(ent)) {  // mine was broken (gunshot/grenade) before it was armed
		return Plugin_Stop;
	}
	
	SetEntityRenderColor(ent_laser, g_iMineLaserColor_Normal[0], g_iMineLaserColor_Normal[1], g_iMineLaserColor_Normal[2], g_iMineLaserColor_Normal[3]);
	//DispatchKeyValue(ent_laser, "TouchType", "4");
	SDKHook(ent_laser, SDKHook_ThinkPost, SDKCallback_ThinkPost_LaserBeam);

	EmitSoundToAll(g_szMineArmedSound, ent);

	return Plugin_Stop;
}

int CreateLaser(Float:start[3], Float:end[3])
{
	new ent = CreateEntityByName("env_beam");
	
	if (ent != -1)
	{
		TeleportEntity(ent, start, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(ent, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
		SetEntPropVector(ent, Prop_Data, "m_vecEndPos", end);
		DispatchKeyValue(ent, "targetname", g_szMineLaserTargetName);
		//DispatchKeyValue(ent, "rendercolor", g_szMineLaserColor);
		DispatchKeyValue(ent, "renderamt", "67");
		DispatchKeyValue(ent, "decalname", "Bigshot");
		DispatchKeyValue(ent, "life", "0");
		DispatchKeyValue(ent, "TouchType", "0");
		DispatchSpawn(ent);
		SetEntPropFloat(ent, Prop_Data, "m_fWidth", 1.0);
		SetEntPropFloat(ent, Prop_Data, "m_fEndWidth", 1.0);
		ActivateEntity(ent);
		
		SetEntityRenderColor(ent, g_iMineLaserColor_Normal[0], g_iMineLaserColor_Normal[1], g_iMineLaserColor_Normal[2], g_iMineLaserColor_Normal[3] / 2);
		AcceptEntityInput(ent, "TurnOn");
	}
	
	return ent;
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

public void OnPluginStart()
{
	AddCommandListener(Command_Teleport, "drop");
	//RegConsoleCmd("jointeam", Command_JoinTeam);
	
	//RegConsoleCmd("sm_shop", Command_DisplayShopMenu);
	
	RegConsoleCmd("sm_guns", Command_DisplayWeaponsMenu);
	RegConsoleCmd("sm_gun", Command_DisplayWeaponsMenu);
	
	RegConsoleCmd("sm_menu", Command_DisplayMainMenu);
	RegConsoleCmd("sm_modmenu", Command_DisplayMainMenu);
	RegConsoleCmd("sm_mm", Command_DisplayMainMenu);
	
	HookEvent("round_prestart", Event_RoundPreStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_fire", Event_WeaponFire);
	
	g_iWeapons_Clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	// In order to play sound on touch mine's laser
	
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
	
	enum ConVars
	{
		String:ConVar_Name[35],
		String:ConVar_Value[12]
	};
	
	new const szConVars[][ConVars] = {
		{ "mp_buytime", "0" },
		//{ "sv_infinite_ammo", "2" },
		{ "mp_autoteambalance", "0" },
		{ "mp_limitteams", "0" },
		{ "mp_friendlyfire", "0" },
		{ "mp_give_player_c4", "0" },
	//	{ "mp_humanteam", "CT" },
		{ "mp_teamname_2", "Nightcrawler" },
		{ "mp_teamname_1", "Survivor" },
		{ "sv_buy_status_override",  "3" }
	};
	
	ConVar Var;
	for(int i; i < sizeof szConVars; i++)
	{
		Var = CreateConVar(szConVars[i][ConVar_Name], "", "");
		SetConVarString(Var, szConVars[i][ConVar_Value], true, false);
		//SetConVarFlags(Var, FCVAR_PROTECTED);
		HookConVarChange(Var, ConVarChangedCallback_ModRequiredConVars);
	}
}

public void ConVarChangedCallback_ModRequiredConVars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UnhookConVarChange(convar, ConVarChangedCallback_ModRequiredConVars);
	SetConVarString(convar, oldValue, true);
	HookConVarChange(convar, ConVarChangedCallback_ModRequiredConVars);
}

public void OnMapStart()
{
	LoadSettingsFromFile();
	PrecacheFiles();
	
	int iLen = 0;
	int iBarCount = RoundFloat(g_flDetector_Radius / g_flDetector_UnitsPerChar);
	
	while (iLen < iBarCount)
	{
		g_szDefaultDetectorText[iLen++] = CHAR_DASH;
	}
	
	g_szDefaultDetectorText[iLen] = 0;
	
	g_hTimer = CreateTimer(10.0, Timer_CheckGameState, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
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
}

public void OnMapEnd()
{
	g_bRunning = false;
	
	delete g_hTimer;
	RemoveEdict(g_iFogEnt);
}

public void OnConfigsExecuted()
{
	//LoadSettingsFromFile();
}

public void OnClientDisconnect(int client)
{
	if (g_bLaser[client])
	{
		if (IsValidEntity(g_iLaserEnt[client]))
		{
			RemoveEdict(g_iLaserEnt[client]);
		}
	}
	
	if (GetClientTeam(client) == CS_TEAM_SURVIVOR && IsPlayerAlive(client))
	{
		CheckLastSurvivor();
	}
	
	MakeHooks(client, false);
}

public OnClientPutInServer(client)
{
	g_iLastWeapons[client][0] = -1;
	g_iLastWeapons[client][1] = -1;
	g_bSaveLastWeapons[client] = false;
	g_bHasChosenWeaponsThisRound[client] = false;
	
	ResetVars(client, true);
	MakeHooks(client, true);
	
	SetVariantString("MyFog");
	AcceptEntityInput(client, "SetFogController");
}

void LoadSettingsFromFile()
{
	// To ensure that all settings were loaded correctly.
	LoadDefaultValues();
	
	char szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/nightcrawler.cfg");
	
	if (!FileExists(szFile))
	{
		LogError("Missing Settings file. Using default values as defined in plugin.");
	}
	
	else
	{
		Handle hKv = CreateKeyValues("NightCrawler");
		FileToKeyValues(hKv, szFile);
		KvGotoFirstSubKey(hKv, true);
		
		LoadKeyValues(hKv);
		
		delete hKv;
	}
	
	LoadOtherFiles();
}

void LoadKeyValues(Handle hKv)
{
	char Keys[][] =  {
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
		"Hegrenade_MaxNades", 
		"Hegrenade_RegenerationTime", 
		"Hegrenade_GiveAmount", 
		"Hegrenade_RegenerationAmount", 
		"Nightcralwer_SpeedMultiplier", 
		"Nightcrawler_GravityMultiplier"
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
		Key_NCSpeedMultiplier, 
		Key_NCGravityMultiplier, 
		
		Key_Total
	};
	g_iMinPlayers = KvGetNum(hKv, Keys[Key_MinimumPlayers], g_iDefault_MinPlayers);
	g_iChooseNCPlayersMode = KvGetNum(hKv, Keys[Key_ChooseNCMode], g_iDefault_ChooseNCPlayersMode);
	g_flNCRatio = KvGetFloat(hKv, Keys[Key_NCRatio], g_flDefault_NCRatio);
	g_flLaserRatio = KvGetFloat(hKv, Keys[Key_LaserRatio], g_flDefault_LaserRatio);
	
	g_iPointsPerKill_NC = KvGetNum(hKv, Keys[Key_NCPointsPerKill], g_iDefault_PointsPerKill_NC);
	g_iPointsPerKill_Survivor = KvGetNum(hKv, Keys[Key_SurvivorPointsPerKill], g_iDefault_PointsPerKill_Survivor);
	g_iPointsHSBonus = KvGetNum(hKv, Keys[Key_SurvivorHSBonus], g_iDefault_PointsHSBonus);
	
	g_flMaxMana = KvGetFloat(hKv, Keys[Key_MaxMana], g_flDefault_MaxMana);
	g_flManaRegenTime = KvGetFloat(hKv, Keys[Key_ManaRegenTime], g_flDefault_ManaRegenTime);
	g_flManaRegenAmount = KvGetFloat(hKv, Keys[Key_ManaRegenAmount], g_flDefault_ManaRegenAmount);
	g_flManaTeleportCost = KvGetFloat(hKv, Keys[Key_ManaTeleportCost], g_flDefault_ManaTeleportCost);
	g_flChooseWeaponTime = KvGetFloat(hKv, Keys[Key_WeaponsChooseTime], g_flDefault_ChooseWeaponTime);
	
	KvGetString(hKv, Keys[Key_LightStyle], g_szLightStyle, sizeof g_szLightStyle, g_szDefault_LightStyle);
	g_bMakeFog = view_as<bool>(KvGetNum(hKv, Keys[Key_MakeFog], view_as<int>(g_bDefault_MakeFog)));
	g_bRemoveShadows = view_as<bool>(KvGetNum(hKv, Keys[Key_RemoveShadows], view_as<int>(g_flDefault_ManaTeleportCost)));
	
	g_flMinePlacement_MaxDistanceFromWall = KvGetFloat(hKv, Keys[Key_MinePlacementMaxDistance], g_flDefault_MinePlacement_MaxDistanceFromWall);
	g_iMineMaxPlayers = KvGetNum(hKv, Keys[Key_MineMaxPlayers], g_iDefault_MineMaxPlayers);
	g_iMineGiveCount = KvGetNum(hKv, Keys[Key_MineGiveAmount], g_iDefault_MineGiveCount);
	g_flMinePlacement_PlacementTime = KvGetFloat(hKv, Keys[Key_MinePlacementTime], g_flDefault_MinePlacement_PlacementTime);
	g_flMineActivateTime = KvGetFloat(hKv, Keys[Key_MineActivateTime], g_flDefault_MineActivateTime);
	
	KvGetColor(hKv, Keys[Key_MineLaserColor_Normal], g_iMineLaserColor_Normal[0], g_iMineLaserColor_Normal[1], 
		g_iMineLaserColor_Normal[2], g_iMineLaserColor_Normal[3]);
	KvGetColor(hKv, Keys[Key_MineLaserColor_Aim], g_iMineLaserColor_Aim[0], g_iMineLaserColor_Aim[1], 
		g_iMineLaserColor_Aim[2], g_iMineLaserColor_Aim[3]);
	
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
	
	g_flNCSpeedMultiplier = KvGetFloat(hKv, Keys[Key_NCSpeedMultiplier], g_flDefault_NCSpeedMultiplier);
	g_flNCGravityMultiplier = KvGetFloat(hKv, Keys[Key_NCGravityMultiplier], g_flDefault_NCGravityMultiplier);
	
	for (int i; i < Key_Total; i++)
	{
		if (!KvJumpToKey(hKv, Keys[i], false))
		{
			LogError("Key '%s' was not found in the config file.", Keys[i]);
		}
	}
}

void LoadDefaultValues()
{
	g_iMinPlayers = g_iDefault_MinPlayers;
	g_iChooseNCPlayersMode = g_iDefault_ChooseNCPlayersMode;
	
	g_flNCSpeedMultiplier = g_flDefault_NCSpeedMultiplier;
	g_flNCGravityMultiplier = g_flDefault_NCGravityMultiplier;
	
	g_flNCRatio = g_flDefault_NCRatio;
	g_flLaserRatio = g_flDefault_LaserRatio;
	g_iPointsPerKill_NC = g_iDefault_PointsPerKill_NC;
	g_iPointsHSBonus = g_iDefault_PointsHSBonus;
	g_iPointsPerKill_Survivor = g_iDefault_PointsPerKill_Survivor;
	
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
	
	g_iItemsData[0][PlayerItem_Enabled] = 0;
	g_iItemsData[1][PlayerItem_Enabled] = 1;
	g_iItemsData[2][PlayerItem_Enabled] = 1;
	g_iItemsData[3][PlayerItem_Enabled] = 1;
	g_iItemsData[4][PlayerItem_Enabled] = 1;
}

void LoadOtherFiles()
{
	if (g_bFirstRun)
	{
		g_bFirstRun = false;
		g_Array_WeaponReserveAmmo = CreateArray(1);
		g_Array_WeaponGiveName = CreateArray(25);
	}
	
	else
	{
		ClearArray(g_Array_WeaponReserveAmmo);
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

void ParseWeaponsMenuFile()
{
	char szFile[PLATFORM_MAX_PATH];
	char szLine[125];
	
	int iStep = 0;
	
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/nightcrawler_weaponmenu.ini");
	
	PluginLog("Path: %s", szFile);
	
	File f = OpenFile(szFile, "r");
	
	if (f == INVALID_HANDLE)
	{
		CreateWeaponsMenuFile(szFile);
		ParseWeaponsMenuFile();
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
		
		new String:szStringParts[5][35];
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
}

void CreateWeaponsMenuFile(char[] szFile)
{
	File f = OpenFile(szFile, "w+");
	
	if (f == INVALID_HANDLE)
	{
		LogError("Wrong path: %s", szFile);
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
	WriteFileLine(f, "1:2:weapon_awp:AWP");
	WriteFileLine(f, "1:4:weapon_p90:P90");
	WriteFileLine(f, "2:5:weapon_glock:Glock-18");
	
	delete f;
}

void CleanStrings(String:szStringParts[][], int iArraySize, int iStringSize)
{
	for (int i; i < iArraySize; i++)
	{
		TrimString(szStringParts[i]);
		ReplaceString(szStringParts[i], iStringSize, "\"", "");
	}
}

public void Event_WeaponFire(Handle event, char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (g_bAdrenalineActivated[client])
	{
		SetEntData(iEnt, g_iWeapons_Clip1Offset, GetEntData(iEnt, g_iWeapons_Clip1Offset) + 1, true);
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
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Choosing weapons time has expired. You won't be able to choose new weapons until you die or next round.");
			}
			
			return false;
		}
		
		if (g_bHasChosenWeaponsThisRound[client])
		{
			if (bPrintChat)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have already chosen weapons for this round.");
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
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Shop is only available to alive players.");
		}
		
		return false;
	}
	
	if (GetClientTeam(client) != CS_TEAM_SURVIVOR)
	{
		if (bPrintChat)
		{
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Shop is only available to survivors.");
		}
		
		return false;
	}
	
	if (g_bHasChosenItemThisRound[client])
	{
		if (bPrintChat)
		{
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have already chosen an item for this round.");
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
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Shop is only available to alive players.");
		}
		
		return false;
	}
	
	if (GetClientTeam(client) != CS_TEAM_SURVIVOR)
	{
		if (bPrintChat)
		{
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Shop is only available to survivors.");
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

public Action Command_Teleport(int client, const char[] szCommand, int iArgCount)
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
			
			else PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Teleport failed. Try to aim somewhere else");
		}
		
		else PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are missing %0.1f %s to teleport", g_flManaTeleportCost - g_flPlayerMana[client], g_szManaName);
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
			
			if (GetClientButtons(client) & IN_USE)
			{
				DoClimb(client);
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
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	
	if (GetClientTeam(client) == CS_TEAM_NC)
	{
		CS_RemoveWeapon(client, -1, false, true);
		
		GivePlayerItem(client, "weapon_knife");
		
		//SetEntityModel(client, g_szNightcrawlerPlayerModel[GetRandomInt(0, sizeof(g_szNightcrawlerPlayerModel) - 1)]);
		SetEntityRenderColor(client, 0, 255, 0, 128);
		
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are a %s", g_szNightcrawlerName);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are invisible; You invisibility will break if you get shot!");
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Your objective is to kill the %ss", g_szSurvivorName);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You can press G to teleport (drop weapon button) or E to climb walls (+use key)");
		
		SetEntityGravity(client, g_flNCGravityMultiplier);
		SetClientSpeed(client, g_flNCSpeedMultiplier);
	}
	
	else
	{
		SetEntityModel(client, g_szSurvivorPlayerModel[GetRandomInt(0, sizeof(g_szSurvivorPlayerModel) - 1)]);
		
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You are a %s", g_szSurvivorName);
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You objective is to kill the %ss", g_szNightcrawlerName);
		//PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You can press G to teleport (drop weapon button) or E to climb walls (+use key)");
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Use your items to assist you to complete your objective.");
		
		SetEntityGravity(client, 1.0);
		SetClientSpeed(client, 1.0);
		
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
	
	int iHumans[MAXPLAYERS];
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
	
	if (!g_bRunning)
	{
		return;
	}
	
	PluginLog("RoundStart #3");
	g_hHintMessageTimer = CreateTimer(HINTMSG_UPDATE_TIME, Timer_HintMessage, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	GiveLasers(iHumans, iCount);
	CheckLastSurvivor();
	PluginLog("RoundStart #4");
}

public void Event_RoundEnd(Event event, char[] szEventName, bool bDontBroadcast)
{
	g_bRoundEnd = true;
	delete g_hHintMessageTimer;
	
	if (!g_bRunning)
	{
		return;
	}
	
	ChooseNCPlayers();
	//ChangePlayersTeams();
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
		
		CheckLastSurvivor();
	}
	
	else
	{
		EmitSoundToAll(g_szNightcrawlerDeathSound[GetRandomInt(0, sizeof(g_szNightcrawlerDeathSound) - 1)]);
	}
	
	if (IsValidPlayer(iKiller) && iKiller != iVictim)
	{
		switch (GetClientTeam(iKiller))
		{
			case CS_TEAM_NC:
			{
				g_iPlayerPoints[iKiller] += g_iPointsPerKill_NC;
				
				PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", g_iPointsPerKill_NC, g_szSurvivorName);
			}
			case CS_TEAM_SURVIVOR:
			{
				g_bKilledNC[iKiller] = true;
				if (GetEventInt(event, "headshot"))
				{
					PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", g_iPointsPerKill_Survivor + g_iPointsHSBonus, g_szNightcrawlerName);
					g_iPlayerPoints[iKiller] += (g_iPointsPerKill_Survivor + g_iPointsHSBonus);
				}
				
				else PrintToChat_Custom(iKiller, PLUGIN_CHAT_PREFIX, "You have gained %d points for killing a %s", g_iPointsPerKill_Survivor, g_szNightcrawlerName);
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
		
		//SDKHook(client, SDKHook_Touch, SDKHookCallback_Touch);
		
		SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKHookCallback_WeaponSwitch);
		SDKHook(client, SDKHook_WeaponCanUse, SDKHookCallback_WeaponSwitch);
		SDKHook(client, SDKHook_WeaponEquip, SDKHookCallback_WeaponSwitch);
		
		//SDKHook(client, SDKHook_ThinkPost, SDKHookCallback_ThinkPost);
		SDKHook(client, SDKHook_PostThinkPost, SDKHookCallback_OnPostThinkPost);
	}
	
	else
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, SDKHookCallback_OnTakeDamage);
		SDKUnhook(client, SDKHook_SetTransmit, SDKHookCallback_SetTransmit);
		
		//SDKUnhook(client, SDKHook_Touch, SDKHookCallback_Touch);
		
		SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDKHookCallback_WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponCanUse, SDKHookCallback_WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponEquip, SDKHookCallback_WeaponSwitch);
		
		//SDKUnhook(client, SDKHook_ThinkPost, SDKHookCallback_ThinkPost);
		SDKHook(client, SDKHook_PostThinkPost, SDKHookCallback_OnPostThinkPost);
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
	
	return Plugin_Continue;
}

public Action SDKHookCallback_SetTransmit(client, entity)
{
	if (client == entity)
	{
		return Plugin_Continue;
	}
	
	if (g_bRoundEnd)
	{
		return Plugin_Continue;
	}
	
	if (GetClientTeam(client) == GetClientTeam(entity))
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
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iItemIndex = StringToInt(szInfo);
			
			if (!g_iItemsData[iItemIndex][PlayerItem_Enabled])
			{
				return ITEMDRAW_DISABLED;
			}
			
			if (iItemIndex == ITEM_LASER)
			{
				/*
				if (g_iChooseLaserPlayersMode != LASERMODE_MENU)
				{
					return ITEMDRAW_DISABLED;
				}
				*/
				
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
			return 0;
		}
		
		case MenuAction_Select:
		{
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			iItemIndex = StringToInt(szInfo);
			
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
			
			GiveLaser(client, true);
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
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "ADMIN %N has given you a free Laser!", iAdminId);
			}
			
			if (!bSuccess)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "This item has maxed out.");
			}
			
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have the laser. If you aim at a %s, it will change the color!", g_szNightcrawlerName);
		}
		
		case ITEM_LASERMINE:
		{
			if (bFree)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "ADMIN %N has given you a free Laser Mine (%d)!", iAdminId, g_iMineGiveCount);
			}
			
			if (!bSuccess)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "This item has maxed out.");
			}
			
			else
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have (%d) laser mines. Place them on the wall by holding +use key (default: E)", g_iMineGiveCount);
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "When a %s touches the laser of the mine, a voice will be heard!", g_szNightcrawlerName);
			}
		}
		
		case ITEM_SUICIDEBOMB:
		{
			if (bFree)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "ADMIN %N has given you a free Suicide Bomb!", iAdminId);
			}
			
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have the suicicde bomb! Press +use key to activate it! (default: E)");
		}
		
		case ITEM_ADRENALINE:
		{
			if (bFree)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "ADMIN %N has given you a free Adrenaline!", iAdminId);
			}
			
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have the adrenaline! It will help you run and shoot faster with infinite clip ammo, and gain health as well!");
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Press +use key to inject yourself with Adrenaline! (default: E)");
		}
		
		case ITEM_DETECTOR:
		{
			if (bFree)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "ADMIN %N has given you a free detector!", iAdminId);
			}
			
			if (!bSuccess)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "This item has maxed out.");
			}
			
			else
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have the detector! It will update every %0.2f seconds.", g_flDetectorUpdateTime);
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "If a %s is close to you, the detector will indicate with bars and a color ( ||||| )", g_szNightcrawlerName);
			}
		}
		
		case ITEM_HEGRENADE:
		{
			if (bFree)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "ADMIN %N has given you a free hegrenade!", iAdminId);
			}
			
			if (!bSuccess)
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "This item has maxed out.");
			}
			
			else
			{
				PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "You have (%d) Hegrenades! You will get %d extra Hegrenades every %0.1f seconds.", g_iHegrenadeGiveAmount, g_iHegrenadeRegenAmount, g_flHegrenadeRegenTime);
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
	Timer_Detector(INVALID_HANDLE, client);
	g_hDetectorTimer[client] = CreateTimer(g_flDetectorUpdateTime, Timer_Detector, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_Detector(Handle hTimer, int client)
{
	if (!IsClientInGame(client) && !IsPlayerAlive(client))
	{
		g_hDetectorTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	float flDistance;
	int iOtherClient = GetNearestPlayer(client, flDistance);
	
	char szDetectorText[25];
	if (iOtherClient && flDistance <= g_flDetector_Radius)
	{
		float flRemainingDistance = flDistance;
		int iExpectedBarCount = RoundFloat(flRemainingDistance / g_flDetector_UnitsPerChar);
		int iLen;
		
		while (iLen < iExpectedBarCount)
		{
			szDetectorText[iLen++] = CHAR_BAR;
		}
		
		szDetectorText[iLen] = 0;
		int iDashsNumber = RoundFloat((g_flDetector_Radius - flDistance) / g_flDetector_UnitsPerChar);
		int iHalfDashsNumber = iDashsNumber / 2;
		
		// Even
		if (!(iHalfDashsNumber % 2))
		{
			char szDashText[25];
			iLen = 0;
			while (iLen < iHalfDashsNumber)
			{
				szDashText[iLen++] = CHAR_DASH;
			}
			
			szDashText[iLen] = 0;
			FormatEx(szDetectorText, sizeof szDetectorText, "%s%s<font color=\"%s\">%s</font>%s", g_szDetectorDefaultMessage, szDashText, g_szDetectorCloseColor, szDetectorText, szDashText);
		}
		
		// Odd
		else
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
			FormatEx(szDetectorText, sizeof szDetectorText, "%s%s<font color=\"%s\">%s</font>%s", g_szDetectorDefaultMessage, szDashTextRight, g_szDetectorCloseColor, szDetectorText, szDashTextLeft);
		}
	}
	
	else
	{
		FormatEx(szDetectorText, sizeof szDetectorText, "%s%s", g_szDetectorDefaultMessage, g_szDefaultDetectorText);
	}
	
	PrintHintText(client, szDetectorText);
	return Plugin_Continue;
}

stock GetNearestPlayer(int client, float &flDistance)
{
	static float vOrigin[3], vOtherOrigin[3];
	static float flNearestDistance;
	static int iNearestPlayer;
	flNearestDistance = 99999.0; iNearestPlayer = 0;
	
	GetClientAbsOrigin(client, vOrigin);
	
	// Nearest player
	static int iPlayers[MAXPLAYERS], iCount;
	iCount = GetPlayers(iPlayers, GetPlayersFlag_Alive, GP_TEAM_FIRST);
	
	for (int i = 0; i < iCount; i++)
	{
		GetClientAbsOrigin(iPlayers[i], vOtherOrigin);
		
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

void GiveHeGrenades(client)
{
	GiveGrenades(client, true, g_iHegrenadeGiveAmount);
	g_bHasHeGrenade[client] = true;
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
	AddMenuItem(g_hMainMenu, "2", "Shop Menu");
	
	if (g_iChooseNCPlayersMode == MODE_QUEUE)
	{
		AddMenuItem(g_hMainMenu, "3", "Enter Nightcrawler Queue");
	}
	
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
		bool bShowAgain = false;
		bool bAlive = IsPlayerAlive(param1);
		if (bAlive && GetGameTime() > g_flWeaponMenuExpireTime)
		{
			PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "The time to choose the weapons has expired. You will need to wait for a new round.");
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
					PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You haven't even choosen a weapon!");
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
					PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You haven't even choosen a weapon!");
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

stock SetReserveAmmo(client, weapon, ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo); //set reserve to 0
	
	new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
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
	if(slot == -1)
	{
		i = CS_SLOT_PRIMARY;
		iEnd = CS_SLOT_C4;
	}
	
	else
	{
		i = slot;
		iEnd = slot;
	}
	
	for(; i <= iEnd; i++)
	{
		int weapon_index = -1;
		while ((weapon_index = GetPlayerWeaponSlot(client, i)) != -1)
		{
			if (IsValidEntity(weapon_index))
			{
				
				if(slot == CS_SLOT_KNIFE && !bStripKnife)
				{
					continue;
				}
				
				if(slot == CS_SLOT_C4 && !bStripBomb)
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
		char szInfo[3];
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
			
			case 3:
			{
				/*
				if (!CanDisplayShopMenu(param1, true))
				{
					bDisplayAgain = true;
				}
				*/
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "The shop is still under developement.");
			}
			
			case 2:
			{
				if (!CanDisplayItemMenu(param1, true))
				{
					bDisplayAgain = true;
				}
				
				else DisplayMenu(g_hItemMenu, param1, MENU_TIME_FOREVER);
			}
			
			case 998:
			{
				PrintHelpMessagesInConsole(param1);
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "Everything you need to know about this mod has been printed in your console.");
				
				bDisplayAgain = true;
			}
			
			case 999:
			{
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "The admin menu is still under developement.");
			}
		}
		
		if (bDisplayAgain)
		{
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

void PrintHelpMessagesInConsole(client)
{
	PrintToConsole(client, "-------------------------------");
	PrintToConsole(client, "------  Nightcrawlers Mod -----");
	PrintToConsole(client, "-------------------------------");
	PrintToConsole(client, "Nightcrawlers are aliens that invaded the earth. Their objective is to hunt down the human surivors and obliterate them.");
	PrintToConsole(client, "--- How to play:");
	PrintToConsole(client, "-- As a %s:", g_szSurvivorName);
	PrintToConsole(client, "You are a %s. You have to survive until the end of the round or kill all the %s.", g_szSurvivorName, g_szNightcrawlerTeamName);
	PrintToConsole(client, "You can choose your guns, your (assisting) items, or buy upgrades from the shop.", g_szSurvivorName, g_szNightcrawlerTeamName);
	PrintToConsole(client, "The %s are invisible. They only turn visible when you hurt them.", g_szNightcrawlerTeamName);
	PrintToConsole(client, "-- As a %s:", g_szNightcrawlerName);
	PrintToConsole(client, "Your objective is to kill the %ss", g_szSurvivorTeamName);
	PrintToConsole(client, "You are invisible, and you are only visible (for a limited amount of time) when you get hurt!");
	PrintToConsole(client, "You can climb walls using your '+use' key.");
	PrintToConsole(client, "You can teleport by clicking on the 'drop' button (the button that drops a gun). Teleporting costs you %0.2f %s", g_flManaTeleportCost, g_szManaName);
}

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
}

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
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You are missing %d points to buy this item.", g_iShopItemCost[iItemIndex] - g_iPlayerPoints[param1]);
				bDisplayAgain = true;
			}
			
			if (g_iShopItemCost[iItemIndex] > g_iPlayerPoints[param1])
			{
				PrintToChat_Custom(param1, PLUGIN_CHAT_PREFIX, "You are missing %d points to buy this item.", g_iShopItemCost[iItemIndex] - g_iPlayerPoints[param1]);
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
}

// --------------------------------------------------------------------------
//								Timers
// --------------------------------------------------------------------------
public Action Timer_HintMessage(Handle hTimer)
{
	//int iPlayers[MAXPLAYERS], iCount;
	//iCount = GetPlayers(iPlayers, GetPlayersFlag_Alive, GP_TEAM_FIRST | GP_TEAM_SECOND);
	
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
				PrintHintText(iPlayer, "Mana: %0.2f|%0.2f\nRegeneration Rate: %0.1f", g_flPlayerMana[iPlayer], g_flMaxMana, g_flManaRegenAmount);
			}
			
			case CS_TEAM_SURVIVOR:
			{
				float flGameTime;
				if (g_bHasHeGrenade[iPlayer])
				{
					if (g_flPlayerNextGrenade[iPlayer] > (flGameTime = GetGameTime()))
					{
						PrintHintText(iPlayer, "Next Grenade reload in: %0.1f seconds", g_flPlayerNextGrenade[iPlayer] - flGameTime);
					}
					
					else
					{
						g_flPlayerNextGrenade[iPlayer] = flGameTime + g_flHegrenadeRegenTime;
						GiveGrenades(iPlayer, false, 1);
					}
				}
			}
		}
	}
}

void GiveGrenades(int client, bool bSet, iCount)
{
	#define HEGrenadeOffset 13
	int iGrenadeCount = GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
	
	if (!iGrenadeCount)
	{
		GivePlayerItem(client, "weapon_hegrenade");
	}
	
	if (iGrenadeCount >= g_iHegrenadeMax)
	{
		return;
	}
	
	switch (bSet)
	{
		case true:
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", iCount, _, HEGrenadeOffset);
		}
		
		case false:
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", iCount + iGrenadeCount, _, HEGrenadeOffset);
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
		int iPlayersCT[MAXPLAYERS];
		int iPlayersT[MAXPLAYERS];
		
		int iCountCT = GetPlayers(iPlayersCT, GetPlayersFlag_None, GP_TEAM_SECOND);
		int iCountT = GetPlayers(iPlayersT, GetPlayersFlag_None, GP_TEAM_FIRST);
		
		if (iCountT + iCountCT < g_iMinPlayers)
		{
			g_bRunning = false;
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Stopped the game: not enough players players", g_szNightcrawlerTeamName);
			return Plugin_Continue;
		}
		
		if (iCountT <= 0 || iCountCT <= 0)
		{
			PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Restarting the round as there are no players in the %s team.", g_szNightcrawlerTeamName);
			CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
		}
		
		return Plugin_Continue;
	}
	
	int iCount = GetPlayers(_, GetPlayersFlag_None, GP_TEAM_FIRST | GP_TEAM_SECOND);
	
	if (iCount >= g_iMinPlayers)
	{
		//ChooseNCPlayers();
		PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "--- Starting ---", g_szNightcrawlerTeamName);
		CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
		g_bRunning = true;
	}
	
	else PrintToChat_Custom(0, PLUGIN_CHAT_PREFIX, "Waiting for at least %d players to join to start the game.", g_iMinPlayers);
	
	return Plugin_Continue;
}

// --------------------------------------------------------------------------
//								Other Funcs
// --------------------------------------------------------------------------
void ChooseNCPlayers()
{
	int iPlayers[MAXPLAYERS];
	int iCount = GetPlayers(iPlayers, _, GP_TEAM_FIRST | GP_TEAM_SECOND);
	
	int iNCCount = RoundFloat(float(iCount) / g_flNCRatio);
	
	int iChosenPlayersCount;
	int bChosenPlayers[MAXPLAYERS];
	
	int iPlayer;
	
	bool bFillRandom = false;
	
	if (g_iChooseNCPlayersMode == MODE_KILL)
	{
		for (int i; i < iCount; i++)
		{
			iPlayer = iPlayers[GetRandomInt(1, iCount - 1)];
			
			// Survivor Killed NC or NC survived
			if (g_bKilledNC[iPlayer] || (IsPlayerAlive(iPlayer) && GetClientTeam(iPlayer) == CS_TEAM_NC))
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
	if (g_iChooseNCPlayersMode == MODE_RANDOM || bFillRandom)
	{
		int iMaxTries = 1000;
		int iTries;
		while (iChosenPlayersCount < iNCCount)
		{
			iTries++;
			
			iPlayer = iPlayers[GetRandomInt(1, iCount - 1)];
			
			if (!bChosenPlayers[iPlayer])
			{
				bChosenPlayers[iPlayer] = true;
				iChosenPlayersCount++;
			}
			
			if (iTries >= iMaxTries)
			{
				break;
			}
		}
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
			//	g_bDontShowPlayer[client] = true;
		}
		
		else if (!bChosenPlayers[iPlayer] && GetClientTeam(iPlayer) != CS_TEAM_SURVIVOR)
		{
			CS_SwitchTeam(iPlayer, CS_TEAM_SURVIVOR);
			//	g_bShowPlayer[client] = true;
		}
		
		else PluginLog("LOL? Client : %d", iPlayer);
	}
	
	PluginLog("Players Count: %d - NC Expected Count %d - Chosen NC Count %d", iCount, iNCCount, iChosenPlayersCount);
}

void ReadPrecacheFile()
{
	char szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFile, sizeof szFile, "/configs/nightcrawer_downloadfiles.ini");
	
	Handle f = OpenFile(szFile, "r");
	
	if (f == INVALID_HANDLE)
	{
		f = OpenFile(szFile, "w+");
		
		WriteFileLine(f, "# Use directory path to precache all files in a folder");
		WriteFileLine(f, "# Example:");
		WriteFileLine(f, "# models/players - Will precache all files in that folder and sub folders");
		WriteFileLine(f, "");
		
		delete f;
		return;
	}
	
	char szLine[PLATFORM_MAX_PATH];
	bool bDontOpenSubFolders;
	
	while (ReadFileLine(f, szLine, sizeof szLine))
	{
		TrimString(szLine);
		if (!szLine[0] || szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		bDontOpenSubFolders = false;
		
		if (szLine[0] == '*')
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
		
		AddFileToDownloadsTable(szLine);
	}
}

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
				FormatEx(szFilePath, sizeof szFilePath, "%s/%s", szDir, szFile);
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
}

void PrecacheFiles()
{
	ReadPrecacheFile();
	char szFile[PLATFORM_MAX_PATH];
	
	PrecacheModel(MODEL_BEAM);
	//FormatEx(szFile, sizeof szFile, "models/%s", g_szMineModel);
	PrecacheModel(g_szMineModel);
	AddFileToDownloadsTable(g_szMineModel);
	
	PrecacheSound(g_szMinePlacementSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMinePlacementSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSound(g_szMineArmedSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMineArmedSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSound(g_szMineArmingSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMineArmingSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSound(g_szMineLaserTouchSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szMineLaserTouchSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSound(g_szTeleportSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szTeleportSound);
	AddFileToDownloadsTable(szFile);
	PrecacheSound(g_szAdrenalineInjectionSound);
	FormatEx(szFile, sizeof szFile, "sound/%s", g_szAdrenalineInjectionSound);
	AddFileToDownloadsTable(szFile);
	
	/*PrecacheSound(xxx);
	FormatEx(szFile, sizeof szFile, "sound/%s", yyy);
	PrecacheSound(xxx);
	FormatEx(szFile, sizeof szFile, "sound/%s", yyy);
	*/
	
	for (int i; i < sizeof g_szNightcrawlerDeathSound; i++)
	{
		PrecacheSound(g_szNightcrawlerDeathSound[i]);
		FormatEx(szFile, sizeof szFile, "sound/%s", g_szNightcrawlerDeathSound[i]);
		AddFileToDownloadsTable(szFile);
	}
	
	/*
	for (int i; i < sizeof g_szNightcrawlerPlayerModel; i++)
	{
		if (g_szNightcrawlerPlayerModel[i][0])
		{
			if (!FileExists(g_szSurvivorPlayerModel[i]))
			{
				PluginLog("File not exits %s", g_szNightcrawlerPlayerModel[i]);
			}
			
			PrecacheModel(g_szNightcrawlerPlayerModel[i]);
		}
	}
	*/
	
	for (int i; i < sizeof g_szSurvivorPlayerModel; i++)
	{
		if (g_szSurvivorPlayerModel[i][0])
		{
			if (!FileExists(g_szSurvivorPlayerModel[i]))
			{
				PluginLog("File not exits %s", g_szSurvivorPlayerModel[i]);
			}
			
			PrecacheModel(g_szSurvivorPlayerModel[i]);
		}
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
		
		RemoveEdict(iEnt);
		PluginLog("Removed Fog ent %d", iEnt);
		//iEnt;
	}
	
	iEnt = CreateEntityByName("env_fog_controller");
	if (iEnt > -1)
	{
		/*
		DispatchKeyValue(iEnt, "fogenable", "true");
		DispatchKeyValue(iEnt, "fogstart", "150.0");
		DispatchKeyValue(iEnt, "fogend", "1000.0");
		DispatchKeyValue(iEnt, "fogmaxdensity", "0.5");
		DispatchKeyValue(iEnt, "farz", "1150.0");
		DispatchKeyValue(iEnt, "fogcolor", "204 204 255");
		DispatchKeyValue(iEnt, "fogblend", "false");
		//DispatchKeyValue(iEnt, "fogstart", "150.0");
		DispatchSpawn(iEnt);
		*/
		
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

bool TeleportClient(client)
{
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
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Please aim somewhere else to teleport");
		delete hTr;
		return false;
	}
	
	TR_GetEndPosition(vOtherPosition, hTr);
	if (TR_PointOutsideWorld(vOtherPosition))
	{
		PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "Please aim somewhere INSIDE THE MAP to teleport");
		delete hTr;
		return false;
	}
	
	delete hTr;
	ScaleVector(vVector1, 32.0);
	
	// Move the player model back based on mins/maxes;
	// Subtract because in the opposite direction;
	SubtractVectors(vOtherPosition, vVector1, vOtherPosition);
	//CreateLaser(vEyePosition, vOtherPosition);
	
	TeleportEntity(client, vOtherPosition, NULL_VECTOR, Float: { 0.0, 0.0, 0.0 } );
	EmitSoundToAll(g_szTeleportSound, client);
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

void GiveLasers(int iHumans[MAXPLAYERS], int iCount)
{
	DeleteLaserEntities();
	SetArrayValue(g_bLaser, sizeof g_bLaser, false, 0);
	
	g_iLaserCount = RoundFloat(float(iCount) / g_flLaserRatio);
	
	int iChosenCount;
	if (!g_iLaserCount && iCount)
	{
		g_iLaserCount = 1;
	}
	
	int client;
	while (iChosenCount < g_iLaserCount)
	{
		client = iHumans[GetRandomInt(0, iCount - 1)];
		
		if (g_bLaser[client])
		{
			continue;
		}
		
		GiveLaser(client, true);
		iChosenCount++;
	}
	
	PluginLog("iLaserCount: %d - iChosenCount: %d", g_iLaserCount, iChosenCount);
}

void DeleteLaserEntities()
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (g_iLaserEnt[client] && IsValidEntity(g_iLaserEnt[client]))
		{
			RemoveEdict(g_iLaserEnt[client]);
			g_iLaserEnt[client] = 0;
			g_bLaser[client] = false;
		}
	}
}

void DoClimb(int client)
{
	static float vOrigin[3]; GetClientAbsOrigin(client, vOrigin);
	static float vEyeAngles[3]; static float vEyePosition[3];
	
	//TeleportEntity(iLaserEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	
	static float vEndPosition[3];
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
	
	if (GetVectorDistance(vEyePosition, vEndPosition) >= 45.0)
	{
		return;
	}
	
	static float vVelocity[3];
	GetAngleVectors(vEyeAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(vVelocity, vVelocity);
	ScaleVector(vVelocity, 250.0);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

void MoveLaserEnt(int client)
{
	//Handle hPf = CreateProfiler();
	//StartProfiling(hPf);
	
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
	
	static float vOrigin[3]; GetClientAbsOrigin(client, vOrigin);
	static float vEyeAngles[3]; GetClientEyeAngles(client, vEyeAngles);
	static float vEyePosition[3]; GetClientEyePosition(client, vEyePosition);
	
	TeleportEntity(iLaserEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
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
	
	if (IsValidPlayer(iHit, true) && GetClientTeam(iHit) == CS_TEAM_NC)
	{
		SetEntityRenderColor(iLaserEnt, 255, 0, 0, 255);
	}
	
	else SetEntityRenderColor(iLaserEnt, 0, 255, 0, 255);
	
	SetEntPropVector(iLaserEnt, Prop_Data, "m_vecEndPos", vEndPosition);
	
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
			g_bLaser[client] = true;
			g_iLaserEnt[client] = MakeLaserEntity();
		}
		
		case false:
		{
			g_bLaser[client] = false;
			
			if (IsValidEntity(g_iLaserEnt[client]))
			{
				RemoveEdict(g_iLaserEnt[client]);
			}
			
			g_iLaserEnt[client] = 0;
		}
	}
}

int MakeLaserEntity()
{
	int iEnt;
	
	#define LASER_COLOR_CT	"255 255 255"
	iEnt = CreateEntityByName("env_beam");
	if (IsValidEntity(iEnt))
	{
		new String:color[16] = LASER_COLOR_CT;
		
		//TeleportEntity(iEnt, start, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(iEnt, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
		//SetEntPropVector(iEnt, Prop_Data, "m_vecEndPos", end);
		
		DispatchKeyValue(iEnt, "targetname", g_szPlayerLaserTargetName);
		DispatchKeyValue(iEnt, "rendercolor", color);
		DispatchKeyValue(iEnt, "renderamt", "255");
		DispatchKeyValue(iEnt, "decalname", "Bigshot");
		DispatchKeyValue(iEnt, "life", "0");
		DispatchKeyValue(iEnt, "TouchType", "0");
		DispatchSpawn(iEnt);
		SetEntPropFloat(iEnt, Prop_Data, "m_fWidth", 1.0);
		SetEntPropFloat(iEnt, Prop_Data, "m_fEndWidth", 1.0);
		ActivateEntity(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		
		PrintToChatAll("Made laser");
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
	
	if (g_iLaserEnt[client])
	{
		if (IsValidEdict(g_iLaserEnt[client]))
		{
			RemoveEdict(g_iLaserEnt[client]);
		}
		
		g_iLaserEnt[client] = 0;
	}
	
	g_bHasChosenItemThisRound[client] = false;
	g_iPlayerMinesCount[client] = 0;
	
	if (g_hPlaceMineTimer[client] != INVALID_HANDLE)
	{
		delete g_hPlaceMineTimer[client];
		g_hPlaceMineTimer[client] = INVALID_HANDLE;
	}
	
	g_flMineLaser_PlayerTouch_SoundPlayCooldown[client] = 0.0;
	
	g_bHasSuicideBomb[client] = false;
	g_bSuicideBombActivated[client] = false;
	
	g_bHasAdrenaline[client] = false;
	g_bAdrenalineActivated[client] = false;
	g_flNextModifyTime[client] = 0.0;
	
	if (g_hDetectorTimer[client] != INVALID_HANDLE)
	{
		delete g_hDetectorTimer[client];
		g_hDetectorTimer[client] = INVALID_HANDLE;
	}
	
	g_bHasChosenWeaponsThisRound[client] = false;
	
	g_flNextManaGain[client] = 0.0;
	g_iPlayerPoints[client] = 0;
	g_flPlayerMana[client] = 0.0;
	g_bHasHeGrenade[client] = false;
	
	g_flPlayerNextGrenade[client] = 0.0;
	
	if (bConnect)
	{
		g_LastButtons[client] = 0;
		g_iWeaponMenuStep[client] = WEAPONTYPE_PRIMARY;
		g_iLastWeapons[client] =  { 0, 0 };
		g_bSaveLastWeapons[client] = false;
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

stock void PrintToChat_Custom(int client, const char[] szPrefix = "", char[] szMsg, any...)
{
	char szBuffer[192];
	VFormat(szBuffer, sizeof(szBuffer), szMsg, 4);
	
	if (client > 0)
	{
		CPrintToChat(client, "%s \x01%s", szPrefix, szBuffer);
	}
	
	else CPrintToChatAll("%s \x01%s", szPrefix, szBuffer);
} 