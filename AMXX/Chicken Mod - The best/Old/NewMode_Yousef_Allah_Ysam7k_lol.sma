#include < 	amxmodx 	>
#include <	amxmisc 	>
#include < 	cstrike 	>
#include <	hamsandwich 	>
#include < 	engine 		>
#include <	fun 		>
#include < 	fakemeta 	>
#include <	xs		>
#include <	fvault		>

// Force semicolons ';'
#pragma semicolon 1

//#define DEBUG
//#define HAM_RESET_SPEED

/* ========================================================= */
/* ===================  EDIT STARTS HERE  ================== */
/* ========================================================= */
// ---- Include bot to keep normal gameplay?			(Define or not)
#define INCLUDE_BOT

// ---- Player Models ----
new const g_szJokerModel[] = 		"e_joker";
new const g_szChickenModel[] = 		"chicken";

// ---- Prefix for chat messages and bot name ----
new const g_szPrefix[] =			"^4[CHICKEN MOD]";
#if defined INCLUDE_BOT
	new const g_szBotName[] =	"CHICKEN MOD BOT";
#endif

// ---- Chicken sounds when gun is picked up or when round startes ----
new g_szChickenSounds[][] = {
	"chicken_sound.mp3"
};

new g_szChickenKillSounds[][] = {
	"chicken_die.wav"
};

// ---- Menus ----
// Required Access for admins menu.
new const g_szMainMenuTitle[] = 	"Chicken Mod Menu";

#define ADMIN_MENU_ACCESS			ADMIN_RCON
#define ADMIN_SPAWN_ACCESS			ADMIN_RCON
#define ADMIN_MENU_POINTS			ADMIN_BAN

// ---- Menu item titles ----				(String)
new g_szMainMenuItemsTitle[][] = {						
	"Players Points",
	"Shop Menu",
	"Toggle Mod Sounds",
	"Admin Menu"
};

// ---- Points ----					(Integer)	
#define POINTS_KILL					5
#define POINTS_TAKE_WEAPON				10

// ---- Color Chat message Color (USELESS) ----		(USELESS)
#define COLOR 						RED

// ---- Random gun bullets = Players * This value ----	(Integer)
#define RANDOM_GUN_BULLETS_MULTIPILE			2

// ---- SPEED FOR SHOP ----				(Float)
#define SPEED_SET_SHOP					375.0

// ---- HEALTH ADD IN SHOP ----				(Integer)
#define ADD_HEALTH					200

// ---- Time for 'search for weapon' phase ----		(Integer)
#define SEARCH_FOR_WEAPON_TIME				45		// In seconds.

// ---- Minimum players to start mod. ----			(Integer)
#define MIN_PLAYERS					1

// ---- Random Weapons Spawn Spot Stuff ----		(Float)
#define MAX_ATTEMPTS					500
#define MAX_ORIGIN 					4192.0
#define MAX_HIGHT					300.0

// ---- Extra Z Origin (Height) for weapon off the ground. ----	(Float)
#define WEAPON_EXTRA_UP_ORIGIN		10.0

// ---- Mod Sounds Path (Folder name for mod which is in sound folder) ---- (String)
new const MOD_SOUNDS_PATH[] = "chicken_mod";

// ---- Emit MP3 Files by searching for near players then sending	( Define or not )
// mp3 play command to play sound ----
#define EMIT_MP3


new g_szGrabCmd[] = "+spgrab";
new const g_szGiveCustomPointsCmd[] = "Give_Custom_Points_Amount";

// ---- String length ----				(Integer)	
#define MAX_POINT_STR_LEN				10


#if !defined HAM_RESET_SPEED
new bool:g_bFreezeTime = false;
#endif

#define TEST_SPAWN_ENT_SOLID		SOLID_BBOX

#define TASKID_HUD					145851
#define TASKID_CHECK_PLAYERS		215171

// Gun Ent Stuff.
new g_szGunEntClass[] = 			"gun_entity";
new const Float:g_vGunMins[3] = 	{ -16.0, -16.0, 0.0 };
new const Float:g_vGunMaxs[3] = 	{ 16.0, 16.0, 16.0 };

#define GUIDING_LASER_MAX_DIST		500.0
new const pev_array_index = 		pev_iuser4;
new g_szTestSpawnEnt[] =			"gun_test_entity";

#define m_iMenuCode 				205
#define m_iId						43

const m_iTeam = 114;
#define fm_cs_get_user_team(%1)  	get_pdata_int(%1, m_iTeam )
#define fm_cs_set_user_team(%1,%2) 	set_pdata_int(%1, m_iTeam, %2 )

enum Color
{
	NORMAL = 1, 	// clients scr_concolor cvar color
	GREEN, 		// Green Color
	TEAM_COLOR, 	// Red, grey, blue
	GREY, 		// grey
	RED, 		// Red
	BLUE		// Blue
};

enum _:GUN_INFO
{
	GF_szName[30], 
	GF_szClassName[33], 
	GF_iCSW, 
	GF_szModel[60]
};

new gGunsInfo[][GUN_INFO] =
{
	{ "AK47", "weapon_ak47", 0, "models/w_ak47.mdl" }
	/*{ "AWP", "weapon_awp", 0, "models/w_awp.mdl" },
	{ "Deagle", "weapon_deagle", 0,"models/w_deagle.mdl" },
	{ "M4A1", "weapon_m4a1", 0, "models/w_m4a1.mdl" },
	{ "Glock18", "weapon_glock18", 0, "models/w_glock18.mdl" },
	{ "ShotGun", "weapon_m3", 0, "models/w_m3.mdl" },
	{ "Galil", "weapon_galil", 0, "models/w_galil.mdl" }*/
};

// Mod Specific
enum GamePhases
{
	GAME_STOP,
	GAME_RUN,
	GAME_STANDBY
};

new GamePhases:g_iGameState;
new g_iCounter;
new bool:g_bWeaponFound;
new g_iEnt;

// Menu
enum
{
	MMENU_PLAYER_POINTS,
	MMENU_SHOP_MENU,
	MMENU_TOGGLE_SOUNDS,
	MMENU_ADMIN_MENU
};

enum _:SHOP_ITEM_DATA
{
	SHOP_ITEM_NAME[50],
	SHOP_ITEM_PRICE
};
	
enum _:SHOP_ITEMS
{
	SI_LASER,
	SI_JOKER_MDL,
	SI_CHICKEN_MDL,
	SI_MORE_SPEED,
	SI_MORE_HEALTH
};

new const g_szShopItemsBuyChatMsg[SHOP_ITEMS][] = {
	"You have bought the ^3Guiding Laser! ^1It will guide you to the weapon.",
	"You have bought the ^3Joker Model!",
	"You have bought the ^3Chicken Model!",
	"You have bought ^3More Speed!",
	"You have bought the ^3Chicken Nuggets ( Health )."
	
};

new const g_szShopItems[SHOP_ITEMS][SHOP_ITEM_DATA] = {
	{ "Guiding Laser", 50 },
	{ "Joker Model", 20 },
	{ "Chicken Model", 30 },
	{ "More Speed", 20 },
	{ "Chicken Nuggets", 15 }
};

new const g_iPointsNumberMenuItems[] = {
	5,
	10,
	50,
	100,
	500,
	1000,
	5000
};

enum _:WEAPON_DATA
{
	WEAPON_NAME[10],
	WEAPON_CMD[20]
}

new const g_szWeaponMenuItems[][WEAPON_DATA] = {
	{ "Ak47", "weapon_ak47" },
	{ "M4a1", "weapon_m4a1" },
	{ "Galil", "weapon_galil" },
	{ "Deagle", "weapon_deagle" },
	{ "Glock", "weapon_glock18" },
	{ "Usp", "weapon_usp" },
	{ "M3", "weapon_m3" },
	{ "Awp", "weapon_awp" },
	{ "Mp5", "weapon_mp5navy" }
};

// Menus
new g_iGiveShopItemMenu;

new g_WeaponMenu;
new g_iGivePointsMenu;

new g_iMainMenu;
new g_iAdminMenu;
new g_iShopMenu;
new g_iSpawnPointMenu[2], g_iEditMode, g_iGuidingLaser, g_iWorkingType = 1, g_iRemoveEnt, g_iRemoveMenu;
new g_hPlayerMenu[33];
new g_iPlayerPLMenuStatus[33];

new g_iMoveValueIndex = 0;
new g_iEditNoClip = 0;

new const Float:g_flMoveValues[] = {
	1.0,
	5.0,
	7.5,
	10.0,
	100.0,
	200.0
};

enum
{
	PM_SHOW_PLAYERS_POINTS,
	PM_GIVE_POINTS,
	PM_GIVE_SHOP_ITEM,
	PM_GIVE_WEAPON
};

enum
{
	AM_POINTS_MENU,
	AM_GIVE_WEAPONS,
	AM_GIVE_SHOP_ITEM,
	AM_SPAWN_MENU
};

enum
{
	SM_EDIT_MENU,
	
	SM_REMOVE_ALL,
	SM_SAVE_ALL,
	
	SM_SPAWN_SETTINGS,
	SM_GUIDING_LASER,
	
	SM_NOCLIP
};

enum
{
	SM_ADD,
	SM_REMOVE,
	
	SM_MOVE_VALUE,
	SM_MOVE_UP,
	SM_MOVE_DOWN,
		
	SM_GRAB_START,
	SM_GRAB_END
};

// Points Give
new g_iGiveThingNumber[33] = 0;

// Laser Things
#define IsInBit(%1,%2)			(	%1 & (1<<%2)	)
#define AddToBit(%1,%2)			(	%1 |= (1<<%2)	)
#define RemoveFromBit(%1,%2)		(	%1 &= ~(1<<%2)	)
new gLaserBit, gSpeedBit;
new gAliveBit;
new gSoundsBit;

// Natives Stuff;
new Array:g_hWeaponsArray;
new Array:g_hShopItemsArray;
new g_iWeaponsCount, g_iShopItemsCount;

new g_hWeaponTouchForward;
new g_hShopChoosedForward;

enum _:ArrayWeaponsData
{
	WEAP_MENU_NAME[35],
	WEAP_MODEL[60]
};

// Sql
#if _SAVE_TYPE == 3
new g_szQuery[256];
new Handle:g_hSql;
#endif

// nVault
#if _SAVE_TYPE == 2
new g_hnVault;
#endif

// Remove map objectives
new Trie:g_hObjectives;
new g_hEntSpawnForward;

// Spawn Origins
new Array:g_hArraySpawnOrigins;
new g_iWeapSpawnOrigins;

// User Models
new g_szUserModel[33][35];

// Search origin
new Float:g_flSearchOrigin;

// Checkign for valid player
new g_iMaxPlayers;
#define IsValidPlayer(%1)		( 1 <= %1 <= g_iMaxPlayers )

new g_szSpawnFile[60];

// Points Stuff
new g_iPoints[33];

#define get_user_points(%1)			g_iPoints[%1]
//#define set_user_points(%1,%2)		g_iPoints[%1] = %2

new beampoint;
new Float:g_flLast[33];

// Grab Stuff
new g_iGrabEnt[33];
new Float:g_flGrabDistance[33];

public plugin_precache()
{
	beampoint = precache_model("sprites/laserbeam.spr");
	
	new i;
	g_hObjectives = TrieCreate();
	new const szObjectives[][] =
	{
		"func_bomb_target", "info_bomb_target", "hostage_entity", "monster_scientist",
		"func_hostage_rescue", "info_hostage_rescue", "info_vip_start", "func_vip_safetyzone",
		"func_escapezone", "armoury_entity", "weaponbox", 
		"player_weaponstrip", "game_player_equip"
	};
	
	for(i = 0; i < sizeof(szObjectives); i++)
	{
		TrieSetCell(g_hObjectives, szObjectives[i], 1);
	}
	
	g_hEntSpawnForward = register_forward(FM_Spawn, "fw_EntSpawn", 0);
	
	for(i = 0; i < sizeof(gGunsInfo); i++)
	{	
		precache_model(gGunsInfo[i][GF_szModel]);
	}
	
	new szMdl[60];
	formatex(szMdl, charsmax(szMdl), "models/player/%s/%s.mdl", g_szChickenModel, g_szChickenModel);
	precache_model(szMdl);
	
	formatex(szMdl, charsmax(szMdl), "models/player/%s/%sT.mdl", g_szChickenModel, g_szChickenModel);
	if(file_exists(szMdl))
	{
		precache_model(szMdl);
	}
	
	formatex(szMdl, charsmax(szMdl), "models/player/%s/%s.mdl", g_szJokerModel, g_szJokerModel);
	precache_model(szMdl);
	
	formatex(szMdl, charsmax(szMdl), "models/player/%s/%sT.mdl", g_szJokerModel, g_szJokerModel);
	if(file_exists(szMdl))
	{
		precache_model(szMdl);
	}
	
	for(i = 0; i < sizeof(g_szChickenSounds); i++)
	{
		PrecacheSound(g_szChickenSounds[i]);
	}
	
	for(i = 0; i < sizeof(g_szChickenKillSounds); i++)
	{
		PrecacheSound(g_szChickenKillSounds[i]);
	}
	
	log_amx("1");
}

public fw_EntSpawn(iEnt)
{
	if(!pev_valid(iEnt))
	{
		return FMRES_IGNORED;
	}
	
	new szClassName[50]; pev(iEnt, pev_classname, szClassName, 49);
	if(TrieKeyExists(g_hObjectives, szClassName))
	{
		remove_entity(iEnt);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public plugin_natives()
{
	g_hWeaponsArray = ArrayCreate(ArrayWeaponsData);
	g_hShopItemsArray = ArrayCreate(SHOP_ITEM_DATA);
	
	new i;
	
	for(new _Array[ArrayWeaponsData]; i < sizeof(gGunsInfo); i++)
	{
		copy(_Array[WEAP_MENU_NAME], charsmax(_Array[WEAP_MENU_NAME]), gGunsInfo[i][GF_szName]);
		copy(_Array[WEAP_MODEL], charsmax(_Array[WEAP_MODEL]), gGunsInfo[i][GF_szModel]);
		
		ArrayPushArray(g_hWeaponsArray, _Array);
		
		g_iWeaponsCount++;
	}
	
	i = 0;
	for(new _Array[SHOP_ITEM_DATA]; i < sizeof( g_szShopItems ); i++)
	{
		copy(_Array[SHOP_ITEM_NAME], charsmax(_Array[SHOP_ITEM_NAME]), g_szShopItems[i][SHOP_ITEM_NAME]);
		_Array[SHOP_ITEM_PRICE] = g_szShopItems[i][SHOP_ITEM_PRICE];
		
		ArrayPushArray(g_hShopItemsArray, _Array);
		g_iShopItemsCount++;
	}
	
	register_library("chicken_mod");
	
	g_hWeaponTouchForward = CreateMultiForward("CM_WeaponTouch", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_hShopChoosedForward = CreateMultiForward("CM_ShopItemChoosed", ET_IGNORE, FP_CELL, FP_CELL);

	register_native("CM_register_shop_item", "Native_RegisterShopItem", 1);
	register_native("CM_register_weapon", "Native_RegisterWeapon", 1);
	
	register_native("CM_set_user_points", "Native_SetUserPoints", 1);
	register_native("CM_get_user_points", "Native_GetUserPoints", 1);
}

public Native_RegisterWeapon(const szMenuName[], szWeaponModel[])
{
	param_convert(1);
	param_convert(2);
	
	new _Array[ArrayWeaponsData];
	copy(_Array, charsmax(_Array[WEAP_MENU_NAME]), szMenuName);
	copy(_Array, charsmax(_Array[WEAP_MODEL]), szWeaponModel);
	
	ArrayPushArray(g_hWeaponsArray, _Array);
	g_iWeaponsCount++;
	return g_iWeaponsCount;
}

public Native_RegisterShopItem(szItemName[], iItemPrice)
{
	param_convert(1);
	
	new _Array[SHOP_ITEM_DATA];
	
	copy(_Array[SHOP_ITEM_NAME], charsmax(_Array[SHOP_ITEM_NAME]), szItemName);
	
	_Array[SHOP_ITEM_PRICE] = iItemPrice;

	ArrayPushArray(g_hShopItemsArray, _Array);
	++g_iShopItemsCount;
	return g_iShopItemsCount;
}

public Native_SetUserPoints(id, iNewPoints)
{
	if(!IsValidPlayer(id))
	{
		log_error( AMX_ERR_NATIVE, "Player index out of bounds (%d)", id);
		return 0;
	}
	
	if(!is_user_connected(id))
	{
		log_error( AMX_ERR_NATIVE, "Player is not connected (%d)", id);
		return 0;
	}
	
	set_user_points(id, iNewPoints);
	return 1;
}

public Native_GetUserPoints(id, iNewPoints)
{
	if(!IsValidPlayer(id))
	{
		log_error( AMX_ERR_NATIVE, "Player index out of bounds (%d)", id);
		return -1;
	}
	
	if(!is_user_connected(id))
	{
		log_error( AMX_ERR_NATIVE, "Player is not connected (%d)", id);
		return -1;
	}

	return get_user_points(id);
}

public plugin_init( )
{
	log_amx("2");
	
	register_plugin( "Chicken Mod", "1.0", "Khalid & Yousef" );
	
	TrieDestroy(g_hObjectives);
	unregister_forward(FM_Spawn, g_hEntSpawnForward, 0);
	
	for(new i; i < sizeof(gGunsInfo); i++)
	{
		gGunsInfo[i][GF_iCSW] = get_weaponid(gGunsInfo[i][GF_szClassName]);
	}
	
	//register_forward( FM_PlayerPreThink, "fw_PlayerPreThink" );
	register_forward( FM_SetClientKeyValue, "fw_SetClientKeyValue" );
	register_forward( FM_ClientKill, "fw_ClientKill" );
	register_forward( FM_SetModel, "fw_SetModel" );
	
	register_touch(g_szGunEntClass, "player", "fw_PlayerTouchGun");
	register_think(g_szGunEntClass, "fw_GunEntThink");
	register_think(g_szTestSpawnEnt, "fw_TestSpawnEntThink");

	register_event("HLTV", "eNewRound", "a", "1=0", "2=0");
	register_event("TeamInfo", "eTeamInfo", "a", "2=CT");
	#if defined INCLUDE_BOT
	register_event("DeathMsg", "eDeathMsg", "a");
	#endif
	
	register_logevent( "RoundStart", 2, "1=Round_Start" );
	register_logevent( "RoundEnd", 2, "1=Round_End" );
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Pre", 0);
	RegisterHam(Ham_Killed, "player", "fw_Killed_Pre", 0);
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Pre", 0);
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1);
	
	#if defined HAM_RESET_SPEED
		#if !defined Ham_Player_ResetMaxSpeed
		new const Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;
		#endif
		RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_Player_ResetMaxSpeed", 1);
	#else
		register_event("CurWeapon", "eCurWeapon", "b", "1=1");
	#endif
	
	#if defined INCLUDE_BOT
	register_message(get_user_msgid("DeathMsg"), "MessageDeathMsg");
	#endif
	register_message(get_user_msgid("StatusIcon"), "MessageStatusIcon");
	register_message(get_user_msgid("Radar"), "MessageRadar");
	register_message(get_user_msgid("ShowMenu"), "MessageShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "MessageVGUIMenu");
	
	register_concmd("amx_set_points", "SetPointsCmd", ADMIN_KICK, "<name | @all> <points>" );
	register_concmd("amx_spawn_edit_mode", "CmdEditMode", ADMIN_SPAWN_ACCESS);
	
	register_clcmd(g_szGrabCmd, "CmdGrabOn");
	new szCmd[20];
	copy(szCmd, charsmax(szCmd), g_szGrabCmd);
	replace(szCmd, charsmax(szCmd), "+", "-");
	register_clcmd(szCmd, "CmdGrabOff");
	
	register_clcmd( "say /shop", "ShopCmd" );
	register_clcmd( "say shop", "ShopCmd" );
	register_clcmd( "say /points", "PointsCmd" );
	register_clcmd( "say points", "PointsCmd" );
	
	register_clcmd(g_szGiveCustomPointsCmd, "GiveCustomPointsCmd");
	
	register_clcmd( "drop", "Handle_Drop" );
	register_clcmd( "chooseteam", "CmdMenu" );
	register_clcmd( "jointeam", "CmdBlockJoinTeam" );
	register_clcmd( "drawradar", "CmdBlock");
	
	server_cmd("mp_limitteams 32");
	server_cmd("mp_autoteambalance 0");
		
	// --| STUFF..
	new iEnt = find_ent_by_class(iEnt, "info_player_spawn");
	if(iEnt)
	{
		new Float:vOrigin[3];
		pev(iEnt, pev_origin, vOrigin);
		// Try to get low hieght.
		g_flSearchOrigin = vOrigin[2];
	}
	
	#if defined DEBUG
	register_clcmd("say /get_to_weapon", "CmdDebug");
	register_clcmd("say /origin", "Origin");
	#endif
	
	g_iMaxPlayers = get_maxplayers();
	
	#if defined INCLUDE_BOT
	set_task(0.5, "DoBot");
	#endif
	

	
	// Do this here after Natives and stuff
	CreateGameMenus();
	GetSpawnOriginsFromFile();
}

#if defined INCLUDE_BOT
new g_iBot;
public DoBot()
{
	// Code stolen ofc :P
	new id = engfunc( EngFunc_CreateFakeClient, g_szBotName );
	
	if( pev_valid( id ) )
	{
		engfunc( EngFunc_FreeEntPrivateData, id );
		dllfunc( MetaFunc_CallGameEntity, "player", id );
		
		set_user_info( id, "rate", "3500" );
		set_user_info( id, "cl_updaterate", "25" );
		set_user_info( id, "cl_lw", "1" );
		set_user_info( id, "cl_lc", "1" );
		set_user_info( id, "cl_dlmax", "128" );
		set_user_info( id, "cl_righthand", "1" );
		set_user_info( id, "_vgui_menus", "0" );
		set_user_info( id, "_ah", "0" );
		set_user_info( id, "dm", "0" );
		set_user_info( id, "tracker", "0" );
		set_user_info( id, "friends", "0" );
		set_user_info( id, "*bot", "1" );
		
		set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
		set_pev( id, pev_colormap, id );
				
		new szMsg[ 128 ];
		dllfunc( DLLFunc_ClientConnect, id, g_szBotName, "127.0.0.1", szMsg );
		dllfunc( DLLFunc_ClientPutInServer, id );
				
		cs_set_user_team( id, CS_TEAM_T );
		ExecuteHamB( Ham_CS_RoundRespawn, id );
				
		set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
		set_pev( id, pev_solid, SOLID_NOT );
		
		dllfunc( DLLFunc_Think, id );
		
		g_iBot = id;
	}
}
#endif

public plugin_end()
{
	ArrayDestroy(g_hArraySpawnOrigins);
	
	#if _SAVE_TYPE == 3
	SQL_FreeHandle(g_hSql);
	#endif
	
	#if _SAVE_TYPE == 2
	nvault_close(g_hnVault);
	#endif
}

public fw_ClientKill(id)
{
	if(!g_iGameState)
	{
		return FMRES_IGNORED;
	}
	
	console_print(id, "** You can't kill your self.");
	return FMRES_SUPERCEDE;
}

public fw_SetClientKeyValue( id, const infobuffer[], const key[] )
{
	if(equal( key, "model" ))
	{
		static currentmodel[32];
		get_user_info( id, "model", currentmodel, charsmax(currentmodel));
        
		if (!equal(currentmodel, g_szUserModel[id]))
		{
			set_user_model(id);
		}
        
		return FMRES_SUPERCEDE;
	}
    
	return FMRES_IGNORED;
}

public MessageRadar(iMsgID, iDest, iReceiver)
{
	return PLUGIN_HANDLED;
}

public MessageStatusIcon(msgID, dest, receiver)
{
	if(get_msg_arg_int(1))
	{
		static const buyzone[] = "buyzone";
		
		static icon[sizeof(buyzone) + 1];
		get_msg_arg_string(2, icon, charsmax(icon));
		
		if(equal(icon, buyzone))
		{
			static const m_fClientMapZone = 235;
			static const MAPZONE_BUYZONE = (1 << 0);
			static const XO_PLAYERS = 5;
	
			set_pdata_int(receiver, m_fClientMapZone, get_pdata_int(receiver, m_fClientMapZone, XO_PLAYERS) & ~MAPZONE_BUYZONE, XO_PLAYERS);
				
			set_msg_arg_int(1, ARG_BYTE, 0);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public MessageShowMenu(iMsgID, iDest, iReceiver)
{
	new const Team_Select[] = "#Team_Select";
	
	new szMenu[sizeof(Team_Select)];
	get_msg_arg_string(4, szMenu, charsmax(szMenu));
	
	if(!equal(szMenu, Team_Select))
	{
		if(equal(szMenu, "#CT_Select"))
		{
			set_pdata_int(iReceiver, m_iMenuCode, 0);
			return PLUGIN_HANDLED;
		}
		
		return PLUGIN_CONTINUE;
	}
	
	set_task(0.2, "JoinTeam", iReceiver);
	return PLUGIN_HANDLED;
}

public MessageVGUIMenu(iMsgID, iDest, iReceiver)
{
	if(get_msg_arg_int(1) != 2)
	{
		return PLUGIN_CONTINUE;
	}
	
	set_task(0.2, "JoinTeam", iReceiver);
	return PLUGIN_HANDLED;
}

public ShopCmd( id )
{
	if(!g_iGameState)
	{
		ColorPrint(id, "Sorry, game is not running. Try again later.");
		return;
	}
	
	if(!IsInBit(gAliveBit, id ))
	{
		ColorPrint(id, "Sorry, you must be alive to buy items.");
		return;
	}
	
	menu_display(id, g_iShopMenu, 0);
}

public SetPointsCmd( id, level, cid )
{
	if(!cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	new szArg1[32], szArg2[5];
	read_argv( 1, szArg1, charsmax( szArg1 ) );
	read_argv( 2, szArg2, charsmax( szArg2 ) );
	
	new szAdminName[32], szPlayerName[32];
	get_user_name( id, szAdminName, charsmax( szAdminName ) );
	
	new newpoints = str_to_num( szArg2 );
	new Players[32], iPNum;
	
	if( szArg1[0] == '@' )
	{
		//new szTeam[ 20 ];
		if(equal(szArg1[1], "all"))
		{
			//szTeam = "EVERYONE";
			get_players( Players, iPNum, "c" );
		}

		else
		{
			console_print(id, "Sorry, Team is not valid.");
			return PLUGIN_HANDLED;
		}
		
		for( new i = 0 ; i < iPNum ; i++ )
		{
			set_user_points( Players[i], newpoints );
		}
		
		if(iPNum)
		{
			ColorPrint( 0, "ADMIN ^3%s: ^1set ^3Everyone's ^1points to ^3%d^1.", szAdminName, newpoints );
		}
		
		else
		{
			console_print(id, "There are no players in this team");
		}
	}
	else
	{
		new iTarget = cmd_target( id, szArg1, (CMDTARGET_ALLOW_SELF|CMDTARGET_OBEY_IMMUNITY|CMDTARGET_NO_BOTS) );
		
		if(!iTarget)
		{
			return PLUGIN_HANDLED;
		}
		
		set_user_points( iTarget, newpoints );
		get_user_name( iTarget, szPlayerName, charsmax( szPlayerName ) );
		ColorPrint( 0, "ADMIN ^3%s: ^1set ^3%d ^1points to ^3%s^1.", szAdminName, newpoints, szPlayerName );
	}
	
	return PLUGIN_HANDLED;
}

public GiveCustomPointsCmd(id, level, cid)
{
	if(!(get_user_flags(id) & ADMIN_MENU_POINTS))
	{
		ColorPrint(id, "^1You don't have the required access");
		return PLUGIN_HANDLED;
	}
	
	new szPoints[MAX_POINT_STR_LEN];
	read_argv(1, szPoints, charsmax(szPoints));
	
	if(equali(szPoints, "cancel"))
	{
		g_iGiveThingNumber[id] = 0;
		ColorPrint(id, "^1Canceled Give points.");
		return PLUGIN_HANDLED;
	}
	
	if(!is_str_num(szPoints))
	{
		ColorPrint(id, "^1Wrong Amount!");
		return PLUGIN_HANDLED;
	}
	
	if(str_to_num(szPoints) <= 0)
	{
		ColorPrint(id, "^1Wrong Amount!");
		return PLUGIN_HANDLED;
	}
	
	new iPoints = str_to_num(szPoints);
	
	g_iGiveThingNumber[id] = iPoints;
	
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "c");
	
	new menu = CreateMenu(id, "Choose a player", "PlayerMenuHandler");
	g_iPlayerPLMenuStatus[id] = PM_GIVE_POINTS;
	
	menu_additem( menu, "\yEveryone" );
	
	for( new i = 0, szId[5], Player, szItemName[50], PlayerName[32] ; i < iNum ; i++ )
	{
		Player = iPlayers[i];
		
		get_user_name(Player, PlayerName, charsmax( PlayerName ) );
		num_to_str(Player, szId, charsmax(szId));
		
		formatex(szItemName, charsmax(szItemName), "%s \y(\r%d\y)", PlayerName, g_iPoints[Player]);
		menu_additem( menu, szItemName, szId );
	}
	
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public CmdGrabOn(id)
{
	if(	!(get_user_flags(id) & ADMIN_SPAWN_ACCESS ) )
	{
		ColorPrint(id, "^1You don't have the access");
		return PLUGIN_HANDLED;
	}
	
	g_iGrabEnt[id] = 0;
	
	new iHitEnt;
	if(GetHitAimStuff(id, iHitEnt))
	{
		if(is_valid_ent(iHitEnt))
		{
			g_iGrabEnt[id] = iHitEnt;
			g_flGrabDistance[id] = entity_range(id, iHitEnt);
		}
	}
	
	return PLUGIN_HANDLED;
}

public CmdGrabOff(id)
{
	if(!is_valid_ent(g_iGrabEnt[id]))
	{
		g_iGrabEnt[id] = 0;
		return PLUGIN_HANDLED;
	}
	
	if(IsEntStuck(g_iGrabEnt[id]))
	{
		ColorPrint( id, "^1Spawn point removed because it got ^3Stuck^1." );
		RemoveTestSpawnEnt(g_iGrabEnt[id], 1);
	}
	
	g_iGrabEnt[id] = 0;
	return PLUGIN_HANDLED;
}

public PointsCmd( id )
{
	new iPoints = get_user_points( id );
	
	ColorPrint( id, "Your points are ^3%d^1.", iPoints );
}

public JoinTeam(id)
{
	client_cmd(id, "jointeam 2");
	client_cmd(id, "joinclass 5");
}

public CmdMenu( id )
{
	menu_display(id, g_iMainMenu);
	return PLUGIN_HANDLED;
}

public CmdBlock(id)
{
	return PLUGIN_HANDLED;
}

public CmdBlockJoinTeam( id )
{	
	return cs_get_user_team(id) != CS_TEAM_UNASSIGNED ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public CmdEditMode(id)
{
	if( !(id && get_user_flags(id) & ADMIN_SPAWN_ACCESS) )
	{
		console_print(id, "You don't have the required flags to access this command.");
		return PLUGIN_HANDLED;
	}
	
	if(!g_iEditMode)
	{
		g_iEditMode = id;
		
		g_iGameState = GAME_STOP;
		remove_task(TASKID_HUD);
		
		new Float:vOrigin[3];
		for(new i; i < g_iWeapSpawnOrigins; i++)
		{
			ArrayGetArray(g_hArraySpawnOrigins, i, vOrigin);
			CreateTestEntity(i, vOrigin);
		}
		
		console_print(id, "** Edit mode on.");
		
		ColorPrint(0, "Edit mode is ^3ON! ^1Game Paused.");
	}
	
	else
	{
		if(id != g_iEditMode)
		{
			console_print(id, "You are not the editing player to end 'Edit Mode'");
			return PLUGIN_HANDLED;
		}
		
		g_iEditMode = 0;
		
		remove_entity_name(g_szTestSpawnEnt);
		
		eTeamInfo();
		
		console_print(id, "** Edit mode off. Restarting Round");
		ColorPrint(0, "Edit mode ^3off! ^1Continuing.");
	}
	
	return PLUGIN_HANDLED;
}

#if defined HAM_RESET_SPEED
public fw_Player_ResetMaxSpeed(id)
#else
public eCurWeapon(id)
#endif
{
	#if defined HAM_RESET_SPEED
	if( !IsInBit(gAliveBit, id) || !IsInBit(gSpeedBit, id) || is_user_bot(id) )
	#else
	if( !IsInBit(gAliveBit, id) || !IsInBit(gSpeedBit, id) || is_user_bot(id) || g_bFreezeTime )
	#endif
	{
		return;
	}
	
	#if defined HAM_RESET_SPEED
	new Float:flMaxSpeed;
	pev(id, pev_maxspeed, flMaxSpeed);
	
	if(flMaxSpeed != 1.0)
	{
		entity_set_float(id, EV_FL_maxspeed, SPEED_SET_SHOP);
	}
	
	#else
		entity_set_float(id, EV_FL_maxspeed, SPEED_SET_SHOP);
	#endif
}

public fw_TraceAttack_Pre(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(g_iGameState != GAME_RUN)
	{
		return HAM_IGNORED;
	}
	
	if(!IsValidPlayer(attacker))
	{
		return HAM_IGNORED;
	}
	
	if( victim != attacker )
	{
		if( fm_cs_get_user_team(victim) == fm_cs_get_user_team(attacker) )
		{
			fm_cs_set_user_team(victim, 1);
			ExecuteHamB(Ham_TraceAttack, victim, attacker, damage, direction, tracehandle, damagebits);
			fm_cs_set_user_team(victim, 2);
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}

public fw_TakeDamage_Pre(victim, idinflictor, attacker, Float:damage, damagebits)
{
	if(g_iGameState != GAME_RUN)
	{
		return HAM_IGNORED;
	}
	
	if(!IsValidPlayer(attacker))
	{
		return HAM_IGNORED;
	}
	
	if( victim != attacker )
	{
		if(fm_cs_get_user_team(victim) == fm_cs_get_user_team(attacker) )
		{
			fm_cs_set_user_team(victim, 1);
			ExecuteHamB(Ham_TakeDamage, victim, idinflictor, attacker, damage, damagebits);
			fm_cs_set_user_team(victim, 2);
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}

public fw_Killed_Pre(victim, attacker, shouldgib)
{
	if(g_iGameState != GAME_RUN)
	{
		if(g_iEditMode)
		{
			ExecuteHamB(Ham_CS_RoundRespawn, victim);
		}
		
		return HAM_IGNORED;
	}
	
	if(!IsValidPlayer(attacker))
	{
		return HAM_IGNORED;
	}
	
	PlaySound(victim, true, g_szChickenKillSounds[random(sizeof(g_szChickenKillSounds))]);
	RemoveFromBit(gAliveBit, victim);
	
	if( victim != attacker )
	{
		if( fm_cs_get_user_team(victim) == fm_cs_get_user_team(attacker) )
		{
			fm_cs_set_user_team(victim, 1);
			ExecuteHamB(Ham_Killed, victim, attacker, shouldgib);
			fm_cs_set_user_team(victim, 2);
			
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}

public fw_Spawn_Post(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	if(id == g_iBot)
	{
		set_pev(id, pev_origin, Float:{ 8192.0, 8192.0, 8192.0 } );
		set_pev(id, pev_movetype, MOVETYPE_NOCLIP);
		set_pev(id, pev_solid, SOLID_NOT);
		set_pev(id, pev_takedamage, DAMAGE_NO);
		set_pev(id, pev_effects, pev( id, pev_effects ) | EF_NODRAW);
		return;
	}
	
	AddToBit(gAliveBit, id);
	
	g_szUserModel[id] = g_szChickenModel;
	set_user_model(id);
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
}

public eNewRound()
{
	if(!g_bWeaponFound)
	{
		if(is_valid_ent(g_iEnt))
		{
			remove_entity(g_iEnt);
		}
	}
	
	#if !defined HAM_RESET_SPEED
	g_bFreezeTime = true;
	#endif
	
	gLaserBit = 0;
	gSpeedBit = 0;
}

public eDeathMsg()
{
	new iKiller = read_data( 1 );
	new iVictim = read_data( 2 );
	new iTeam = get_user_team( iVictim );
	
	new iPlayers[32], iCount;
	get_players(iPlayers, iCount, "ae", "CT");
	if( iTeam == 2 && is_user_alive( g_iBot ) && iCount == 1)
	{
		set_pev(g_iBot, pev_takedamage, DAMAGE_YES);
		fakedamage( g_iBot, "worldspawn", 100.0, DMG_GENERIC );
	}
	
	if( !is_user_bot( iKiller ) && !is_user_bot( iVictim ) && iKiller != iVictim && IsValidPlayer( iKiller ) )
	{
		set_user_points( iKiller, get_user_points( iKiller ) + POINTS_KILL );
		ColorPrint( iKiller, "You earned ^3%d ^1points for killing.", POINTS_KILL );
	}
}

#if defined INCLUDE_BOT
public MessageDeathMsg(iMsgID, iDest, iReceiver)
{
	if( get_msg_arg_int( 2 ) == g_iBot )
	{
		return PLUGIN_HANDLED;
	}
		
	return PLUGIN_CONTINUE;
}
#endif

public RoundEnd()
{
	remove_task(TASKID_HUD);
	client_cmd(0, "mp3 stop");
}

public RoundStart()
{
	if(!g_iGameState)
	{
		return;
	}
	
	#if !defined HAM_RESET_SPEED
	g_bFreezeTime = false;
	#endif
	
	new iPlayers[32], iCTNum;
	get_players( iPlayers, iCTNum, "e", "CT" );
	
	new szWeaponName[60];
	PlaceRandomGun(szWeaponName, charsmax(szWeaponName));
	
	g_bWeaponFound = false;
	ColorPrint( 0, "The random gun is ^3%s^1 with ^3%d ^1bullets", szWeaponName, iCTNum * RANDOM_GUN_BULLETS_MULTIPILE);
	
	g_iGameState = GAME_STANDBY;
	g_iCounter = SEARCH_FOR_WEAPON_TIME + 1;
	
	TaskHudMessage(TASKID_HUD);
	set_task(1.0, "TaskHudMessage", TASKID_HUD, .flags = "b");
}

public TaskHudMessage(iTaskId)
{
	switch(g_iGameState)
	{
		case GAME_STOP:
		{
			remove_task(iTaskId);
			return;
		}
		
		case GAME_STANDBY:
		{
			--g_iCounter;
			
			if(!g_iCounter)
			{
				g_iGameState = GAME_RUN;
				
				set_hudmessage(127, 127, 127, -1.0, 0.70, 0, 0.0, 1.0, 0.1, 0.1, -1);
				show_hudmessage(0, "Phase: KILL^n^nFRIENDLY FIRE ON!!!!^nFRIENDLY FIRE ON!!!!");
			}
			
			else
			{
				set_hudmessage(255, 255, 255, -1.0, 0.85, 0, 0.0, 1.0, 0.1, 0.1, -1);
				show_hudmessage(0, "Phase: Look for weapon^nTimer: %d seconds left", g_iCounter);
			}
		}
		
		case GAME_RUN:
		{
			if(g_bWeaponFound)
			{
				set_hudmessage(127, 127, 127, -1.0, 0.70, 0, 0.0, 1.0, 0.1, 0.1, -1);
				show_hudmessage(0, "Phase: KILL^nThe weapon was picked up^nFRIENDLY FIRE ON!!!!^nFRIENDLY FIRE ON!!!!");
			}
			
			else
			{
				set_hudmessage(127, 127, 127, -1.0, 0.70, 0, 0.0, 1.0, 0.1, 0.1, -1);
				show_hudmessage(0, "Phase: KILL^n^nFRIENDLY FIRE ON!!!!^nFRIENDLY FIRE ON!!!!");
			}
		}
	}
}

public client_disconnect(id)
{
	if(is_user_bot(id))
	{
		if(id == g_iBot)
		{
			set_task(0.5, "DoBot");
		}
		
		return;
	}

	if(id == g_iEditMode)
	{
		g_iEditMode = 0;
		remove_entity_name(g_szTestSpawnEnt);
			
		eTeamInfo();
	}
		
	SavePoints(id);
	
	// Reset Stuff
	g_iGrabEnt[id] = 0;
	if(IsInBit(gLaserBit, id))
	{
		RemoveFromBit(gLaserBit, id);
	}
	
	if(IsInBit(gAliveBit, id))
	{
		RemoveFromBit(gAliveBit, id);
	}
	
	if(IsInBit(gSpeedBit, id))
	{
		RemoveFromBit(gSpeedBit, id);
	}
}

public client_putinserver(id)
{
	if(is_user_bot(id))
	{
		return;
	}
	
	LoadPoints(id);
	
	AddToBit(gSoundsBit, id);
}

public client_connect(id)
{
	client_cmd(id, "hideradar");
}

public CheckPlayers(iTaskId)
{
	new iCount = CountPlayers();
	
	if(iCount < MIN_PLAYERS)
	{
		if(g_iGameState != GAME_STOP)
		{
			g_iGameState = GAME_STOP;
			
			if(!g_bWeaponFound)
			{
				if(is_valid_ent(g_iEnt))
				{
					remove_entity(g_iEnt);
				}
			}
			else
			{
				g_bWeaponFound = false;
			}
			
			ColorPrint(0, "The game has stopped because not enough players are connected");
		}
	}
}

public eTeamInfo()
{
	if(!g_iGameState && !g_iEditMode)
	{
		new iCount = CountPlayers();
		
		if(iCount >= MIN_PLAYERS)
		{
			if(task_exists(TASKID_CHECK_PLAYERS))
			{
				remove_task(TASKID_CHECK_PLAYERS);
			}
			
			g_iGameState = GAME_STANDBY;
			
			server_cmd("sv_restart 5");
			
			ColorPrint(0, "Enough players have joined. Restarting Round!");
		}
	}
}

stock CountPlayers(iAlive = 0)
{
	new iCount;
	for(new i; i <= g_iMaxPlayers; i++)
	{
		if(is_user_connected(i) && !is_user_bot(i))
		{
			if(iAlive)
			{
				if( IsInBit(gAliveBit, i) )
				{
					if(cs_get_user_team(i) == CS_TEAM_CT)
					{
						iCount++;
					}
				}
			}
			
			else if (cs_get_user_team(i) == CS_TEAM_CT)
			{
				iCount++;
			}
		}	
	}
	
	return iCount;
}

public fw_PlayerTouchGun(iEnt, iPlayer)
{
	if(!g_iGameState)
	{
		return;
	}
	
	if(!g_bWeaponFound && g_iEnt == iEnt)
	{
		g_bWeaponFound = true;
		g_iGameState = GAME_RUN;
		
		new iEntry = pev(iEnt, pev_array_index);
		
		remove_entity(iEnt);
		
		g_szUserModel[iPlayer] = g_szJokerModel;
		set_user_model(iPlayer);
		
		new iBullets = CountPlayers() * RANDOM_GUN_BULLETS_MULTIPILE;
		
		// Custom Weapon (From another plugin).
		if(iEntry >= sizeof(gGunsInfo))
		{
			new iRet;
			ExecuteForward(g_hWeaponTouchForward, iRet, iPlayer, iEntry + 1, iBullets);
		}
		
		else
		{
			new szWeaponName[32]; 
			get_weaponname(gGunsInfo[iEntry][GF_iCSW], szWeaponName, charsmax(szWeaponName));
			cs_set_weapon_ammo( give_item(iPlayer, szWeaponName), iBullets );
			cs_set_user_bpammo(iPlayer, gGunsInfo[iEntry][GF_iCSW], 0);
		}
		
		new szPlayerName[32];
		get_user_name( iPlayer, szPlayerName, charsmax( szPlayerName ) );
		
		set_user_points( iPlayer, ( get_user_points( iPlayer ) + POINTS_TAKE_WEAPON ) );
		
		ColorPrint( iPlayer, "You took ^3%d ^1Points for taking the random weapon.", POINTS_TAKE_WEAPON );
		ColorPrint( 0, "The weapon has been picked up.", szPlayerName );
	
		PlaySound(0, false, g_szChickenSounds[random(sizeof(g_szChickenSounds))]);
	}
}

public fw_GunEntThink(iEnt)
{	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.025);
	
	static Float:vOrigin[3];
	static Float:vUserOrigin[3];
	pev(iEnt, pev_origin, vOrigin);
	
	static iPlayer, iNearestPlayer, Float:flDistance, Float:flSmallestDistance;
	iPlayer = 0, flSmallestDistance = 99999.0, iNearestPlayer = 0; // Reset Some
	
	while( ( iPlayer = find_ent_in_sphere(iPlayer, vOrigin, 250.0) ) )
	{
		if(iPlayer > g_iMaxPlayers)
		{
			break;
		}
		
		pev(iPlayer, pev_origin, vUserOrigin);
		flDistance = get_distance_f(vOrigin, vUserOrigin);
		
		if( flDistance < flSmallestDistance)
		{
			iNearestPlayer = iPlayer;
			flSmallestDistance = flDistance;
		}
	}
	
	if(!iNearestPlayer)
	{
		return;
	}

	pev(iNearestPlayer, pev_origin, vUserOrigin);
	
	vUserOrigin[2] = vOrigin[2];
	
	static Float:vAngles[3];
	compute_look_angles(vOrigin, vUserOrigin, vAngles);
	
	set_pev(iEnt, pev_angles, vAngles);
}

public fw_TestSpawnEntThink(iEnt)
{
	set_pev(iEnt, pev_solid, TEST_SPAWN_ENT_SOLID);
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.01);
}

/* ------------------------------------------------------------------------------
   ----------------------------   Menus   ---------------------------------------
   ------------------------------------------------------------------------------ */

stock CreateGameMenus()
{
	new szItemName[60];
	// ------------------ MAIN MENU ---------------------------------
	g_iMainMenu = menu_create(g_szMainMenuTitle, "MainMenuHandler");
	
	for(new i; i < MMENU_ADMIN_MENU; i++)
	{
		if(i == MMENU_TOGGLE_SOUNDS)
		{
			menu_additem(g_iMainMenu, g_szMainMenuItemsTitle[i], .callback = menu_makecallback("ToggleSoundsCallBack"));
		}
		
		else
		{
			menu_additem(g_iMainMenu, g_szMainMenuItemsTitle[i]);
		}
	}
	
	menu_addblank(g_iMainMenu, 0);
	menu_additem(g_iMainMenu, g_szMainMenuItemsTitle[MMENU_ADMIN_MENU],_, ADMIN_MENU_ACCESS);
	
	// ------------------ SHOP MENU ---------------------------------
	g_iShopMenu = menu_create( "Chicken Mod Shop", "ShopHandler" );
	new callback = menu_makecallback( "ShopCallBack" );
	
	new iLen = strlen(g_szShopItems[SI_MORE_HEALTH][SHOP_ITEM_NAME]);
	formatex( g_szShopItems[SI_MORE_HEALTH][SHOP_ITEM_NAME][iLen], charsmax( g_szShopItems[] ) - iLen, "( +%d Health )", ADD_HEALTH );
	
	//for(new i, ; i < sizeof(g_szShopItems); i++)
	for(new i, _Array[SHOP_ITEM_DATA], szPrice[30]; i < g_iShopItemsCount; i++)
	{
		ArrayGetArray(g_hShopItemsArray, i, _Array);
		
		formatex(szItemName, charsmax(szItemName), "%s \r[\w%d \yPoints\r]", _Array[SHOP_ITEM_NAME], _Array[SHOP_ITEM_PRICE]);
		num_to_str(_Array[SHOP_ITEM_PRICE], szPrice, charsmax(szPrice));
		
		menu_additem(g_iShopMenu, szItemName, szPrice, .callback = callback);
	}
	
	// ------------------ ADMIN MENU ---------------------------------
	g_iAdminMenu = menu_create(g_szMainMenuItemsTitle[MMENU_ADMIN_MENU], "AdminMenuHandler");
	
	menu_additem(g_iAdminMenu, "Set Points Menu", .paccess = ADMIN_MENU_POINTS);
	menu_addblank(g_iAdminMenu, 0);
	
	menu_additem(g_iAdminMenu, "Give Weapon to Player", .paccess = ADMIN_MENU_ACCESS);
	menu_addblank(g_iAdminMenu, 0);
	
	menu_additem(g_iAdminMenu, "Give Shop Item to Player", .paccess = ADMIN_MENU_ACCESS);
	menu_addblank(g_iAdminMenu, 0);
	
	menu_additem(g_iAdminMenu, "Weapon Spawn Points Menu", .paccess = ADMIN_SPAWN_ACCESS);
	
	// ------------------ Give Points Menu ---------------------------------
	g_iGivePointsMenu = menu_create("Give Points Menu", "GivePointsNumMenuHandler");
	
	menu_additem(g_iGivePointsMenu, "\yGive Custom Amount");
	
	for( new i = 0 ; i < sizeof(g_iPointsNumberMenuItems) ; i++ )
	{
		formatex(szItemName, charsmax(szItemName), "%d", g_iPointsNumberMenuItems[i]);
		menu_additem( g_iGivePointsMenu, szItemName );
	}
	
	// ------------------ Give Shop Item Menu ---------------------------------
	g_iGiveShopItemMenu = menu_create("Give Shop Item to Player", "GiveShopMenuHandler");
	
	for( new i = 0 ; i < sizeof(g_szShopItems) ; i++ )
	{
		menu_additem( g_iGiveShopItemMenu, g_szShopItems[i] );
	}
	
	// ------------------ SPAWN POINT MENU ---------------------------------
	
	// --						** Spawn Point 1 **
	g_iSpawnPointMenu[0] = menu_create("Spawn Points Menu", "SpawnPointMenuHandler");
	
	menu_additem(g_iSpawnPointMenu[0], "Edit Menu");
	menu_addblank(g_iSpawnPointMenu[0], 0);
	
	menu_additem(g_iSpawnPointMenu[0], "Remove All");
	menu_additem(g_iSpawnPointMenu[0], "Save All");
	menu_addblank(g_iSpawnPointMenu[0], 0);
	
	formatex(szItemName, charsmax(szItemName), "Weapon Spawn Points BY \r[\y%s\r]", g_iWorkingType ? "FILE" : "RANDOM");
	menu_additem(g_iSpawnPointMenu[0], szItemName);
	formatex(szItemName, charsmax(szItemName), "Guiding Laser (Guides to spawn points) \r[\y%s\r]", g_iGuidingLaser ? "ON" : "OFF");
	menu_additem(g_iSpawnPointMenu[0], szItemName);
	menu_addblank(g_iSpawnPointMenu[0], 0);
	
	formatex(szItemName, charsmax(szItemName), "NoClip \r[\y%s\r]", g_iEditNoClip ? "ON" : "OFF");
	menu_additem(g_iSpawnPointMenu[0], szItemName);
	
	// --					** Spawn Point 2 ** 
	g_iSpawnPointMenu[1] = menu_create("Spawn Points Menu", "EditSPMenuHandler");
	
	menu_additem(g_iSpawnPointMenu[1], "Add Spawn Point");
	menu_additem(g_iSpawnPointMenu[1], "Remove Spawn Point");
	menu_addblank(g_iSpawnPointMenu[1], 0);
	
	formatex(szItemName, charsmax(szItemName), "Move Value \r[\y%0.1f\r]", g_flMoveValues[0]);
	menu_additem(g_iSpawnPointMenu[1], szItemName);
	menu_additem(g_iSpawnPointMenu[1], "Move Spawn Point \yUP (By Move Value)");
	menu_additem(g_iSpawnPointMenu[1], "Move Spawn Point \yDOWN (By Move Value)");
	menu_addblank(g_iSpawnPointMenu[1], 0);
	
	new szCmd[20];
	copy(szCmd, charsmax(szCmd), g_szGrabCmd[1]);
	formatex(szItemName, charsmax(szItemName), "Grab Spawn Point (+%s Bind)", szCmd);
	menu_additem(g_iSpawnPointMenu[1], szItemName);
	
	formatex(szItemName, charsmax(szItemName), "Leave Spawn Point (-%s)", szCmd);
	menu_additem(g_iSpawnPointMenu[1], szItemName);
	
	// ------------------ REMOVE SPAWN POINT MENU ---------------------------------
	
	g_iRemoveMenu = menu_create("Remove Spawn Point Menu", "RemoveMenuHandler");
	menu_additem(g_iRemoveMenu, "Remove Nearest Spawn Point");
	menu_additem(g_iRemoveMenu, "Remove Spawn Point By Aim");
}

public ToggleSoundsCallBack(id, menu, item)
{
	new szItemName[60];
	formatex(szItemName, charsmax(szItemName), "%s \r[\y%s\r]", g_szMainMenuItemsTitle[item], IsInBit(gSoundsBit, id) ? "ON" : "OFF" );
	
	menu_item_setname(menu, item, szItemName);
}

public MainMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	switch(item)
	{
		case MMENU_PLAYER_POINTS:
		{
			new iMenu = CreateMenu(id, g_szMainMenuItemsTitle[MMENU_PLAYER_POINTS], "PlayerMenuHandler");
			g_iPlayerPLMenuStatus[id] = PM_SHOW_PLAYERS_POINTS;
			
			new iPlayers[32], iNum, szName[32], szItem[64];
			get_players(iPlayers, iNum, "c");
			
			for(new i; i < iNum; i++)
			{
				get_user_name(iPlayers[i], szName, charsmax(szName));
				
				formatex(szItem, charsmax(szItem), "\w%s \r[\w%d \yPoints\r]", szName, g_iPoints[iPlayers[i]]);
				menu_additem(iMenu, szItem);
			}
			
			menu_display(id, iMenu);
		}
		
		case MMENU_SHOP_MENU:
		{
			if(!g_iGameState)
			{
				ColorPrint(id, "Sorry, game is not running. Try again later.");
				return;
			}
			
			if(!IsInBit(gAliveBit, id ))
			{
				ColorPrint(id, "You must be alive to open this menu." );
				return;
			}
			
			menu_display(id, g_iShopMenu, 0);
		}
		
		case MMENU_ADMIN_MENU:
		{
			menu_display(id, g_iAdminMenu);
		}
	}
}

public ShopHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	if(!g_iGameState)
	{
		return;
	}
	
	if(!IsInBit(gAliveBit, id ))
	{
		ColorPrint(id, "You must be alive to buy items." );
		return;
	}
	
	new bool:bBought = false, iPrice;
	
	if(item < sizeof(g_szShopItems))
	{
		iPrice = g_szShopItems[item][SHOP_ITEM_PRICE];
		
		switch(item)
		{
			case SI_LASER:
			{
				if(!g_bWeaponFound)
				{
					if( IsInBit(gLaserBit, id) )
					{
						ColorPrint(id, "You already have the ^3Guiding Laser^1.");
					}
					
					else
					{
						AddToBit(gLaserBit, id);
						ColorPrint(id, g_szShopItemsBuyChatMsg[item]);
					
						bBought = true;
					}
				}
			
				else
				{
					ColorPrint(id, "Sorry, The gun was picked up. You can't buy the ^3Guiding Laser^1.");
				}
			}
			
			case SI_JOKER_MDL:
			{
				if(equal(g_szUserModel[id], g_szJokerModel))
				{
					ColorPrint(id, "You already have the ^3Joker Model^1.");
				}
				
				else
				{
					g_szUserModel[id] = g_szJokerModel;
					set_user_model(id);
				
					ColorPrint(id, g_szShopItemsBuyChatMsg[item]);
				
					bBought = true;
				}
			}
			
			case SI_CHICKEN_MDL:
			{
				if(equal(g_szUserModel[id], g_szChickenModel))
				{
					ColorPrint(id, "You already have the ^3Chicken Model^1.");
				}
				
				else
				{
					g_szUserModel[id] = g_szChickenModel;
					set_user_model(id);
					
					ColorPrint(id, g_szShopItemsBuyChatMsg[item]);
					
					bBought = true;
				}
			}
			
			case SI_MORE_SPEED:
			{
				if( IsInBit(gSpeedBit, id) )
				{
					ColorPrint( id, "You already have ^3More Speed." );
				}
				
				else
				{
					AddToBit(gSpeedBit, id);
					set_user_maxspeed( id, SPEED_SET_SHOP );
					
					ColorPrint(id, g_szShopItemsBuyChatMsg[item]);
					
					bBought = true;
				}
			}
			
			case SI_MORE_HEALTH:
			{
				set_user_health( id, get_user_health(id) + ADD_HEALTH );
				
				ColorPrint(id, g_szShopItemsBuyChatMsg[item]);
				bBought = true;
			}
		}
	}
	
	else
	{
		new iRet;
		ExecuteForward(g_hShopChoosedForward, iRet, id, item + 1);
		
		if( iRet == PLUGIN_HANDLED || iRet == PLUGIN_HANDLED_MAIN )
		{
			bBought = true;
			
			new _Array[SHOP_ITEM_DATA];
			ArrayGetArray(g_hShopItemsArray, item, _Array);
			iPrice = _Array[SHOP_ITEM_PRICE];
		}
	}
	
	if(bBought)
	{
		set_user_points(id, get_user_points(id) - iPrice);
	}
	
	menu_display(id, menu);
}

public ShopCallBack(id, menu, item)
{	
	new szPrice[30], iDump;
	menu_item_getinfo(menu, item, iDump, szPrice, charsmax(szPrice), _, _, iDump);
	return ( get_user_points(id) >= str_to_num(szPrice) ) ? ITEM_ENABLED : ITEM_DISABLED;
}

public AdminMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	new iShow = 1;
	switch(item)
	{
		case AM_POINTS_MENU:
		{
			iShow = 0;
			
			menu_display(id, g_iGivePointsMenu, 0);
		}
		
		case AM_GIVE_WEAPONS:
		{
			iShow = 0;
			g_WeaponMenu = menu_create("Give Weapon to Player", "WeaponMenuHandler");
			
			for( new i = 0 ; i < sizeof( g_szWeaponMenuItems ) ; i++ )
			{
				menu_additem( g_WeaponMenu, g_szWeaponMenuItems[i] );
			}
			
			menu_display(id, g_WeaponMenu, 0);
		}
		
		case AM_GIVE_SHOP_ITEM:
		{
			iShow = 0;
			
			menu_display(id, g_iGiveShopItemMenu, 0);
		}
		
		case AM_SPAWN_MENU:
		{
			if(!g_iEditMode)
			{
				ColorPrint(id, "Edit mode needs to be on. Type amx_spawn_edit_mode 1 in console.");
			}
			
			else if(g_iEditMode != id)
			{
				ColorPrint(id, "You are not the player who is currently in edit mode.");
			}
			
			else
			{
				iShow = 0;
				menu_display(id, g_iSpawnPointMenu[0]);
			}
		}
	}
	
	if(iShow)
	{
		menu_display(id, menu);
	}
}

public GiveShopMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	switch(item)
	{
		case SI_LASER:
		{
			if(g_bWeaponFound)
			{
				ColorPrint(id, "^1You can't give laser when the weapon was picked up.");
				menu_display(id, menu);
				
				return;
			}
			
			g_iGiveThingNumber[id] = SI_LASER;
		}
		
		case SI_JOKER_MDL:
		{
			g_iGiveThingNumber[id] = SI_JOKER_MDL;
		}
		
		case SI_CHICKEN_MDL:
		{
			g_iGiveThingNumber[id] = SI_CHICKEN_MDL;
		}
		
		case SI_MORE_SPEED:
		{
			g_iGiveThingNumber[id] = SI_MORE_SPEED;
		}
		
		case SI_MORE_HEALTH:
		{
			g_iGiveThingNumber[id] = SI_MORE_HEALTH;
		}
		
		default:
		{
			g_iGiveThingNumber[id] = item;
		}
	}
	
	new menu = CreateMenu(id, "Give Shop Item to Player", "PlayerMenuHandler");
	g_iPlayerPLMenuStatus[id] = PM_GIVE_SHOP_ITEM;
			
	new Players[32], PlayerName[32], PNum;
	get_players( Players, PNum, "c" );
	
	menu_additem( menu, "\yEveryone" );
	
	new szId[5];
			
	for( new i = 0 ; i < PNum ; i++ )
	{
		get_user_name(Players[i], PlayerName, charsmax( PlayerName ) );
		num_to_str(Players[i], szId, charsmax(szId));
		menu_additem( menu, PlayerName, szId );
	}
	
	menu_display(id, menu, 0);
}

GiveShopItemMenuHandler(id, menu, item)
{	
	if(g_iGiveThingNumber[id] == SI_LASER && g_bWeaponFound)
	{
		ColorPrint(id, "^1You can't give laser when the weapon was picked up.");
		menu_display(id, g_iGiveShopItemMenu);
		return;
	}
	
	new command[5], szPlayerName[32], access, callback;
	menu_item_getinfo(menu, item, access, command, charsmax(command), szPlayerName, charsmax(szPlayerName), callback);
	
	new Players[32], PNum, iPlayer;
	get_players( Players, PNum, "ac" );
	
	new AdminName[32];
	get_user_name( id, AdminName, charsmax( AdminName ) );
	
	new bool:giveall = false;
	switch(item)
	{
		case 0:
		{
			giveall = true;
		}
		
		default:
		{
			giveall = false;
		}
	}
	
	if( giveall )
	{
		for( new i = 0 ; i < PNum ; i++ )
		{
			iPlayer = Players[i];
			
			switch( g_iGiveThingNumber[id] )
			{
				case SI_LASER:
				{
					AddToBit(gLaserBit, iPlayer);
				}
							
				case SI_JOKER_MDL:
				{
					g_szUserModel[iPlayer] = g_szJokerModel;
					set_user_model(iPlayer);
				}
							
				case SI_CHICKEN_MDL:
				{
					g_szUserModel[iPlayer] = g_szChickenModel;
					set_user_model(iPlayer);
				}
							
				case SI_MORE_SPEED:
				{
					AddToBit(gSpeedBit, iPlayer);
					set_user_maxspeed( iPlayer, SPEED_SET_SHOP );
				}
							
				case SI_MORE_HEALTH:
				{
					set_user_health( iPlayer, get_user_health(iPlayer) + ADD_HEALTH );
				}
				
				default:
				{
					new iRet;
					ExecuteForward(g_hShopChoosedForward, iRet, iPlayer, g_iGiveThingNumber[id] + 1);
				}
			}
		}
		
		new _Array[SHOP_ITEM_DATA];
		ArrayGetArray(g_hShopItemsArray, g_iGiveThingNumber[id], _Array);
		
		ColorPrint( 0, "ADMIN ^3%s ^1gave ^3Everyone %s^1.", AdminName, _Array[SHOP_ITEM_NAME] );
	}
	else
	{
		iPlayer = str_to_num(command);
		
		if(!is_user_connected(Players[0]))
		{
			ColorPrint(id, "Player wasn't found.");
			return;
		}
			
		if(!IsInBit(gAliveBit, Players[0]))
		{
			ColorPrint(id, "^1Player %s is not alive!", szPlayerName);
			return;
		}
		
		switch( g_iGiveThingNumber[id] )
		{
			case SI_LASER:
			{
				AddToBit(gLaserBit, iPlayer);
			}
						
			case SI_JOKER_MDL:
			{
				g_szUserModel[iPlayer] = g_szJokerModel;
				set_user_model(iPlayer);
			}
						
			case SI_CHICKEN_MDL:
			{
				g_szUserModel[iPlayer] = g_szChickenModel;
				set_user_model(iPlayer);
			}
						
			case SI_MORE_SPEED:
			{
				AddToBit(gSpeedBit, iPlayer);
				set_user_maxspeed( iPlayer, SPEED_SET_SHOP );
			}
					
			case SI_MORE_HEALTH:
			{
				set_user_health( iPlayer, get_user_health(iPlayer) + ADD_HEALTH );
			}
			
			default:
			{
				new iRet;
				ExecuteForward(g_hShopChoosedForward, iRet, iPlayer, g_iGiveThingNumber[id] + 1);
			}
		}
		
		new _Array[SHOP_ITEM_DATA];
		ArrayGetArray(g_hShopItemsArray, g_iGiveThingNumber[id], _Array);
		
		ColorPrint( 0, "ADMIN ^3%s ^1gave ^3%s %s^1.", AdminName, szPlayerName, _Array[SHOP_ITEM_NAME] );
	}
}

public WeaponMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	g_iGiveThingNumber[id] = item;
	
	new menu = CreateMenu(id, "Give Weapon to Player", "PlayerMenuHandler");
	g_iPlayerPLMenuStatus[id] = PM_GIVE_WEAPON;
			
	new Players[32], PlayerName[32], PNum;
	get_players( Players, PNum, "c" );
	
	menu_additem( menu, "\yEveryone" );
	
	new szId[5];
			
	for( new i = 0 ; i < PNum ; i++ )
	{
		get_user_name(Players[i], PlayerName, charsmax( PlayerName ) );
		num_to_str(Players[i], szId, charsmax(szId));
		menu_additem( menu, PlayerName, szId );
	}
	
	menu_display(id, menu, 0);
}

WeaponNameMenuMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	new command[30], name[64], access, callback;

	menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback);
	
	switch(item)
	{
		case 0:
		{
			new Players[32], PNum;
			get_players( Players, PNum, "ac" );
			
			for( new i = 0 ; i < PNum ; i++ )
			{
				if(IsInBit(gAliveBit, Players[i]))
				{
					give_item( Players[i], g_szWeaponMenuItems[g_iGiveThingNumber[id]][WEAPON_CMD] );
				}
			}
			
			new AdminName[32];
			get_user_name( id, AdminName, charsmax( AdminName ) );
			
			ColorPrint( 0, "ADMIN ^3%s ^1gave ^3Everyone ^1weapon ^3%s^1.", AdminName, g_szWeaponMenuItems[g_iGiveThingNumber[id]][WEAPON_NAME] );
		}
		default:
		{
			new PlayerId = str_to_num(command);
			
			if(!PlayerId)
			{
				ColorPrint(id, "Player wasn't found.");
				return;
			}
			
			if(!IsInBit(gAliveBit, PlayerId))
			{
				ColorPrint(id, "Player is dead.");
				return;
			}
			
			give_item( PlayerId, g_szWeaponMenuItems[g_iGiveThingNumber[id]][WEAPON_CMD] );
			
			new AdminName[32], PlayerName[32];
			get_user_name( PlayerId, PlayerName, charsmax( PlayerName ) );
			get_user_name( id, AdminName, charsmax( AdminName ) );
			
			ColorPrint( 0, "ADMIN ^3%s ^1gave ^3%s ^1weapon ^3%s^1.", AdminName, PlayerName, g_szWeaponMenuItems[g_iGiveThingNumber[id]][WEAPON_NAME] );
		}
	}
}

public GivePointsNumMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	if(!item)
	{
		client_cmd(id, "messagemode %s", g_szGiveCustomPointsCmd);
		return;
	}
	
	g_iGiveThingNumber[id] = g_iPointsNumberMenuItems[item - 1];
			
	if( g_iGiveThingNumber[id] < 0 )
	{
		g_iGiveThingNumber[id] = 0;
		ColorPrint(id, "^1Invalid Number.");
		return;
	}
			
	new menu = CreateMenu(id, "Give Points Menu^nSyntax:^n\r.# \wName \y(\rPoints\y)", "PlayerMenuHandler");
	g_iPlayerPLMenuStatus[id] = PM_GIVE_POINTS;
			
	new Players[32], PlayerName[32], PNum;
	get_players( Players, PNum, "c" );
			
	menu_additem( menu, "\yEveryone" );
			
	for( new i = 0, szId[5], Player, szItemName[50] ; i < PNum ; i++ )
	{
		Player = Players[i];
		
		get_user_name(Player, PlayerName, charsmax( PlayerName ) );
		num_to_str(Player, szId, charsmax(szId));
		
		formatex(szItemName, charsmax(szItemName), "%s \y(\r%d\y)", PlayerName, g_iPoints[Player]);
		menu_additem( menu, szItemName, szId );
	}

	menu_display(id, menu, 0);
}

public PlayerMenuHandler(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		DestroyMenu(id);
		return;
	}
	
	switch(g_iPlayerPLMenuStatus[id])
	{
		/*case PM_SHOW_PLAYERS_POINTS:
		{
			// Do Nothing, Just destroy.
		}*/
		
		case PM_GIVE_POINTS:
		{
			GivePointsMenuHandler(id, menu, item);
		}
		
		case PM_GIVE_SHOP_ITEM:
		{
			GiveShopItemMenuHandler(id, menu, item);
		}
		
		case PM_GIVE_WEAPON:
		{
			WeaponNameMenuMenuHandler(id, menu, item);
		}
	}
	
	DestroyMenu(id);
}
		
GivePointsMenuHandler(id, menu, item)
{
	new command[5], access, callback;

	menu_item_getinfo(menu, item, access, command, charsmax(command), .callback = callback);
	
	new iGivePointsNum = g_iGiveThingNumber[id];
	
	switch(item)
	{
		case 0:
		{
			new Players[32], PNum;
			get_players( Players, PNum, "c" );
				
			for( new i = 0, iPlayer ; i < PNum ; i++ )
			{
				set_user_points( ( iPlayer = Players[i] ) , get_user_points(iPlayer) + iGivePointsNum);
			}
				
			new AdminName[32];
			get_user_name( id, AdminName, charsmax( AdminName ) );
				
			ColorPrint( 0, "ADMIN ^3%s ^1Gave ^3Everyone ^1^3%d^1 Points.", AdminName, iGivePointsNum );
		}
		
		default:
		{
			new PlayerId = str_to_num(command);
				
			if(!is_user_connected(PlayerId))
			{
				ColorPrint(id, "Player wasn't found.");
				return;
			}
			
			new szPlayerName[32];
			get_user_name(PlayerId, szPlayerName, 31);
			
			set_user_points( PlayerId, get_user_points(PlayerId) + iGivePointsNum );
				
			new AdminName[32];
			get_user_name( id, AdminName, charsmax( AdminName ) );
				
			ColorPrint( 0, "ADMIN ^3%s ^1Gave ^3%d ^1points to ^3%s^1.", AdminName, iGivePointsNum, szPlayerName );
		}
	}
}

public SpawnPointMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	if(g_iEditMode != id)
	{
		return;
	}
	
	new iShow = 1;
	switch(item)
	{
		case SM_EDIT_MENU:
		{
			menu_display(id, g_iSpawnPointMenu[1]);
			iShow = 0;
		}
		
		case SM_REMOVE_ALL:
		{
			remove_entity_name(g_szTestSpawnEnt);
			g_iWeapSpawnOrigins = 0;
			ArrayClear(g_hArraySpawnOrigins);
			
			ColorPrint(id, "Removed all spawn origins");
		}
		
		case SM_SAVE_ALL:
		{
			new f = fopen(g_szSpawnFile, "w");
			new Float:vOrigin[3];
			
			if(f)
			{
				for(new i; i < g_iWeapSpawnOrigins; i++)
				{
					ArrayGetArray(g_hArraySpawnOrigins, i, vOrigin);
					fprintf(f, "%0.2f %0.2f %0.2f^n", vOrigin[0], vOrigin[1], vOrigin[2]);
				}
				
				fclose(f);
			}
			
			ColorPrint(id, "^1Saved ^3all");
		}
		
		case SM_GUIDING_LASER:
		{
			g_iGuidingLaser = !g_iGuidingLaser;
			
			new szItemName[60];
			formatex(szItemName, charsmax(szItemName), "Guiding Laser (Guides to spawn points) \r[\y%s\r]", g_iGuidingLaser ? "ON" : "OFF");
			
			menu_item_setname(menu, item, szItemName);
		}
		
		case SM_SPAWN_SETTINGS:
		{
			g_iWorkingType = !g_iWorkingType;
			
			new szItemName[60];
			formatex(szItemName, charsmax(szItemName), "Weapon Spawn Points BY \r[\y%s\r]", g_iWorkingType ? "FILE" : "RANDOM" );
			
			menu_item_setname(menu, item, szItemName);
		}
		
		case SM_NOCLIP:
		{
			if(g_iEditNoClip)
			{
				g_iEditNoClip = 0;
				menu_item_setname(menu, item, "NoClip \r[\yOFF\r]");
				ColorPrint( id, "^3NoClip is ^4OFF" );
			}
			
			else
			{
				g_iEditNoClip = 1;
				menu_item_setname(menu, item, "NoClip \r[\yON\r]");
				ColorPrint( id, "^3NoClip is ^4ON" );
			}
		
			set_user_noclip(id, g_iEditNoClip);
		}
	}
	
	if(iShow)
	{
		menu_display(id, menu);
	}
}

public EditSPMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_display(id, g_iSpawnPointMenu[0]);
		return;
	}
	
	new iShow = 1;
	switch(item)
	{	
		case SM_ADD:
		{
			new iHitEnt, Float:vHitPoint[3];
			if(GetHitAimStuff(id, iHitEnt, vHitPoint))
			{
				ArrayPushArray(g_hArraySpawnOrigins, vHitPoint);
				CreateTestEntity( (++g_iWeapSpawnOrigins) - 1, vHitPoint);
				
				ColorPrint(id, "Spawn Point Created!");
			}
			
			else ColorPrint(id, "Please aim at a solid place ...");
		}
		
		case SM_REMOVE:
		{
			iShow = 0;
			menu_display(id, g_iRemoveMenu);
		}
		
		case SM_MOVE_VALUE:
		{
			new szItemName[60];
			formatex(szItemName, charsmax(szItemName), "Move Value \r[\y%0.1f\r]",
			g_flMoveValues[ ( (++g_iMoveValueIndex) == sizeof(g_flMoveValues) ) ? ( g_iMoveValueIndex = 0 ) : g_iMoveValueIndex ]);
			menu_item_setname(menu, item, szItemName);
		}
		
		case SM_MOVE_UP, SM_MOVE_DOWN:
		{
			new iHitEnt;
			if(GetHitAimStuff(id, iHitEnt) && pev_valid(iHitEnt))
			{
				new szClassName[35];
				pev(iHitEnt, pev_classname, szClassName, charsmax(szClassName));
				
				if(!equal(szClassName, g_szTestSpawnEnt))
				{
					ColorPrint(id, "Please aim at a weapon (Spawn Point) #1");
					return;
				}
				
				new Float:vOrigin[3];
				pev(iHitEnt, pev_origin, vOrigin);
				vOrigin[2] = ( item == SM_MOVE_DOWN ? vOrigin[2] - g_flMoveValues[g_iMoveValueIndex] : vOrigin[2] + g_flMoveValues[g_iMoveValueIndex] );
				entity_set_origin(iHitEnt, vOrigin);
				
				if(IsEntStuck(iHitEnt))
				{
					RemoveTestSpawnEnt(iHitEnt, 1);
					ColorPrint(id, "Deleted entity because it got stuck.");
					return;
				}
				
				new iEntry = pev(iHitEnt, pev_array_index);
				ArrayGetArray(g_hArraySpawnOrigins, iEntry, vOrigin);
				vOrigin[2] = ( item == SM_MOVE_DOWN ? vOrigin[2] - 1.0 : vOrigin[2] + 1.0 );
				ArraySetArray(g_hArraySpawnOrigins, iEntry, vOrigin);
				
				ColorPrint(id, "Moved spawn point ^3%s", item == SM_MOVE_DOWN ? "DOWN" : "UP");
			}
			
			else
			{
				ColorPrint(id, "Please aim at a weapon (Spawn Point)");
			}
		}
		
		case SM_GRAB_START:
		{
			CmdGrabOn(id);
			
			if(g_iGrabEnt[id])
			{
				ColorPrint(id, "^1Start Grab");
			}
			
			else
			{
				ColorPrint(id, "^1Please aim at an entity");
			}
		}
		
		case SM_GRAB_END:
		{
			if(g_iGrabEnt[id])
			{
				CmdGrabOff(id);
				ColorPrint(id, "^1Removed Grab");
			}
			
			else
			{
				ColorPrint(id, "^1You didn't grab any entity");
			}
		}
	}
	
	if(iShow)
	{
		menu_display(id, menu);
	}
}

public RemoveMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_display(id, g_iSpawnPointMenu[1]);
		return;
	}
	
	if(g_iEditMode != id)
	{
		return;
	}
	
	g_iRemoveEnt = 0;
	
	if(item)
	{
		new szClassName[35];
	
		new iEnt, Float:vDump[3];
	
		if(GetHitAimStuff(id, iEnt, vDump) && is_valid_ent(iEnt))
		{
			pev(iEnt, pev_classname, szClassName, charsmax(szClassName));
			if(equal(szClassName, g_szTestSpawnEnt))
			{
				g_iRemoveEnt = iEnt;
			}
			else
			{
				ColorPrint(id, "Wrong Entity.");
				return;
			}
		}
		
		else
		{
			ColorPrint(id, "Please aim at an Weapon (Spawn Entity)");
		}
	}
	
	else
	{
		new Float:vOrigin[3];
		pev(id, pev_origin, vOrigin);
		
		new iFound, iEnt, szClassName[35];
		new Float:flNearestDistance = 9999.0, Float:flDistance, iNearestEnt;
		new Float:vEntOrigin[3];
		
		while( ( iEnt = find_ent_in_sphere(iEnt, vOrigin, 150.0) ) )
		{
			pev(iEnt, pev_classname, szClassName, charsmax(szClassName)); 

			if(!equal(szClassName, g_szTestSpawnEnt))
			{
				continue;
			}
		
			if(!iFound)
			{
				iFound = 1;
			}
		
			pev(iEnt, pev_origin, vEntOrigin);
			flDistance = get_distance_f(vOrigin, vEntOrigin);
			if(flDistance < flNearestDistance)
			{
				flNearestDistance = flDistance;
				iNearestEnt = iEnt;
			}
		}
		
		if(iFound)
		{
			g_iRemoveEnt = iNearestEnt;
		}
		
		else
		{
			ColorPrint(id, "No near spawn point");
		}
	}
	
	if(!g_iRemoveEnt)
	{
		menu_display(id, g_iRemoveMenu);
		return;
	}
	
	new iMenu = CreateMenu(id, "Are you sure you want to^nremove this spawn point?" , "ConfirmMenuHandler");
	menu_additem(iMenu, "Yes");
	menu_additem(iMenu, "No");
		
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
		
	menu_display(id, iMenu);
}

public ConfirmMenuHandler(id, menu, item)
{
	DestroyMenu(id);
	
	if(g_iEditMode != id)
	{
		g_iRemoveEnt = 0;
		return;
	}
	
	#define CONFIRM_ITEM_YES	0
	#define CONFIRM_ITEM_NO		1
	
	if(item == CONFIRM_ITEM_NO)
	{
		g_iRemoveEnt = 0;
		menu_display(id, g_iRemoveMenu);
	}
	
	else
	{
		RemoveTestSpawnEnt(g_iRemoveEnt, 1);
		ColorPrint(id, "Successfully removed Spawn Point");
		
		menu_display(id, g_iRemoveMenu);
	}
}

public Handle_Drop( id )
{	
	return PLUGIN_HANDLED;
}

/* ------------------------------------------------------------------------------
   ----------------------------   Stocks   --------------------------------------
   ------------------------------------------------------------------------------ */

stock IsEntStuck(iEnt)
{
	if(!is_valid_ent(iEnt))
	{
		return 0;
	}
	
	new Float:vOrigin[3];
	pev(iEnt, pev_origin, vOrigin);
	
	if(point_contents(vOrigin) != CONTENTS_EMPTY)
	{
		return true;
	}
	
	return false;
}

stock RemoveTestSpawnEnt(iEnt, iDecreaseArrayIndex = 0)
{
	if(iDecreaseArrayIndex)
	{
		new iSearchEnt, iEntEntry;
		new iEntry = pev(iEnt, pev_array_index);
		
		ArrayDeleteItem(g_hArraySpawnOrigins, iEntry);
		
		while( ( iSearchEnt = find_ent_by_class(iSearchEnt, g_szTestSpawnEnt) ) )
		{
			iEntEntry = pev(iSearchEnt, pev_array_index);
			if(iEntEntry > iEntry)
			{
				set_pev(iSearchEnt, pev_array_index, iEntEntry - 1);
			}
		}
		
		g_iWeapSpawnOrigins--;
	}
	
	remove_entity(iEnt);
}
	
stock CreateTestEntity(iEntry, Float:vOrigin[3])
{
	new iEnt = create_entity("info_target");
	
	if(!is_valid_ent(iEnt))
	{
		return;
	}
	
	set_pev(iEnt, pev_classname, g_szTestSpawnEnt);
	entity_set_origin(iEnt, vOrigin);
	
	entity_set_model(iEnt, "models/w_weaponbox.mdl");
	entity_set_size(iEnt, Float:{ -16.0, -16.0, 0.0 }, Float:{ 16.0, 16.0, 32.0 } );
	
	set_pev(iEnt, pev_solid, TEST_SPAWN_ENT_SOLID);
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY);
	
	set_pev(iEnt, pev_array_index, iEntry);
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.01);
	
	engfunc(EngFunc_DropToFloor, iEnt);
	
	pev(iEnt, pev_origin, vOrigin);
	vOrigin[2] += WEAPON_EXTRA_UP_ORIGIN;
	entity_set_origin(iEnt, vOrigin);
}

stock GetHitAimStuff(id, &iHitEnt, Float:vEndPoint[3] = { 0.0, 0.0, 0.0 }, iAddPlane = 1)
{
	new iTr = create_tr2();
	
	new Float:vOrigin[3], Float:vAngles[3], Float:vViewOfs[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_v_angle, vAngles);
	pev(id, pev_view_ofs, vViewOfs);
	
	xs_vec_add(vOrigin, vViewOfs, vOrigin);
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vAngles);

	vEndPoint = Float:{ 0.0, 0.0, 0.0 };
	xs_vec_mul_scalar(vAngles, 9999.0, vAngles);
	xs_vec_add(vAngles, vOrigin, vAngles);

	//(const float *v1, const float *v2, int fNoMonsters, edict_t *pentToSkip, TraceResult *ptr);
	engfunc(EngFunc_TraceLine, vOrigin, vAngles, DONT_IGNORE_MONSTERS, id, iTr);
	
	new flFraction;
	get_tr2(iTr, TR_flFraction, flFraction);
	
	if(flFraction == 1.0)
	{
		console_print(0, "No solid place in sight to place spawn origin.");
		return 0;
	}
	
	get_tr2(iTr, TR_vecEndPos, vEndPoint);
	
	if(iAddPlane)
	{
		new Float:vPlane[3];
		get_tr2(iTr, TR_vecPlaneNormal, vPlane);
		xs_vec_add(vEndPoint, vPlane, vEndPoint);
	}
	
	Draw(vOrigin, vEndPoint, 50, 0, 255, 0, 255, 2, 0);
	
	iHitEnt = get_tr2(iTr, TR_pHit);
	
	free_tr2(iTr);
	return 1;
}

stock CreateMenu(id, const szTitle[], const szHandler[])
{
	if(g_hPlayerMenu[id])
	{
		DestroyMenu(id);
	}
	
	g_hPlayerMenu[id] = menu_create(szTitle, szHandler);
	return g_hPlayerMenu[id];
}

stock DestroyMenu(id)
{
	if(g_hPlayerMenu[id])
	{
		menu_destroy(g_hPlayerMenu[id]);
		g_hPlayerMenu[id] = 0;
	}
}

stock set_user_points(id, points)
{
	if( points < 0 )
		points = 0;
	
	g_iPoints[id] = points;
}

#if _SAVE_TYPE != 3
stock LoadPoints(id)
{
	new iPoints;
	new szSteam[35];
	new szPoints[MAX_POINT_STR_LEN];
	
	get_user_authid( id, szSteam, charsmax( szSteam ) );
	
	#if _SAVE_TYPE == 1
		fvault_get_data( g_szSqlTblFileName, szSteam, szPoints, charsmax( szPoints ) );
	#endif
	
	#if _SAVE_TYPE == 2
		new iTimeStamp;
		nvault_lookup( g_hnVault, szSteam, szPoints, charsmax( szPoints ), iTimeStamp );
		iPoints = str_to_num(szPoints);
	#endif
	
	iPoints = str_to_num(szPoints);
	
	if(iPoints < 0)
		iPoints = 0;
	
	set_user_points( id, iPoints );
}

#else
public LoadPoints(id)
{
	new iData[2], szSteam[35];
	get_user_authid( id, szSteam, charsmax( szSteam ) );
	
	iData[0] = id;
	
	formatex(g_szQuery, charsmax(g_szQuery), "SELECT Points FROM `%s` WHERE SteamId = '%s'", g_szSqlTblFileName, szSteam);
	SQL_ThreadQuery(g_hSql, "QueryHandler", g_szQuery, iData, 2);
}

public QueryHandler(iFailState, Handle:hQuery, szError[], iErrNum, iData[], size)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("Connection for Query#%d FAILED! Error: %s", hQuery, szError);
		}
		
		case TQUERY_QUERY_FAILED:
		{
			log_amx("Query#%d FAILED: Error #%d : %s", hQuery, iErrNum, szError);
		}
	}
	
	if(iErrNum)
	{
		log_amx("Query#%d Error#%d: %s", hQuery, iErrNum, szError);
		return;
	}
	
	if(size > 1)
	{
		if(!is_user_connected(iData[0]))
		{
			return;
		}
		
		_LoadPoints(hQuery, iData[0]);
	}
}

stock _LoadPoints(Handle:hQuery, id)
{
	if(SQL_MoreResults(hQuery))
	{
		set_user_points(id, SQL_ReadResult( hQuery, 1 ));
	}
	
	else
	{
		new szSteam[35]; get_user_authid(id, szSteam, charsmax(szSteam));
		formatex(g_szQuery, charsmax(g_szQuery), "INSERT INTO `%s` VALUES ( '%s', 0 )", g_szSqlTblFileName, szSteam);
		
		SQL_ThreadQuery(g_hSql, "QueryHandler", g_szQuery);
		
		set_user_points(id, 0);
	}
}
#endif

stock SavePoints(id)
{
	if(!is_user_bot(id))
	{
		new szSteam[35];
		get_user_authid( id, szSteam, charsmax( szSteam ) );
		
		if( g_iPoints[id] < 0 )
		{
			g_iPoints[id] = 0;
		}
		
		new szData[MAX_POINT_STR_LEN];
		num_to_str(g_iPoints[id], szData, charsmax( szData ));
		
		#if _SAVE_TYPE == 1
			fvault_set_data( g_szSqlTblFileName, szSteam, szData );
		#endif
		
		#if _SAVE_TYPE == 2
			nvault_remove( g_hnVault, szSteam );
			nvault_set( g_hnVault, szSteam, szData );
		#endif
		
		#if _SAVE_TYPE == 3
			formatex( g_szQuery, charsmax( g_szQuery ), "UPDATE `%s` SET Points = '%d' WHERE SteamId = '%s'", g_szSqlTblFileName, g_iPoints[id], szSteam );
			SQL_ThreadQuery( g_hSql, "QueryHandler", g_szQuery );
		#endif
	}
}

stock GetSpawnOriginsFromFile()
{
	g_hArraySpawnOrigins = ArrayCreate(3);
	
	get_datadir(g_szSpawnFile, charsmax(g_szSpawnFile));
	
	format(g_szSpawnFile, charsmax(g_szSpawnFile), "%s/chicken_mod", g_szSpawnFile);
	
	if(!dir_exists(g_szSpawnFile))
	{
		mkdir(g_szSpawnFile);
		return;
	}
	
	#define MAX_MAP_NAME	50
	new szMapName[MAX_MAP_NAME];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);
	
	format(g_szSpawnFile, charsmax(g_szSpawnFile), "%s/%s.ini", g_szSpawnFile, szMapName);
	
	new f = fopen(g_szSpawnFile, "r");
	
	if(!f)
	{
		//f = fopen(g_szSpawnFile, "a+");
		fclose(f);
		return;
	}
	
	new szLine[60];
	new Float:vOrigin[3];
	new szOrigin[3][20];
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine));
		trim(szLine);
		
		if(!szLine[0] || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/') )
		{
			continue;
		}
			
		parse(szLine, szOrigin[0], charsmax(szOrigin[]), szOrigin[1], charsmax(szOrigin[]),szOrigin[2], charsmax(szOrigin[]));

		for(new i; i < 3; i++)
		{
			trim(szOrigin[i]);
			vOrigin[i] = str_to_float(szOrigin[i]);
		}
		
		g_iWeapSpawnOrigins++;
		ArrayPushArray(g_hArraySpawnOrigins, vOrigin);
	}
	
	fclose(f);
	
	log_amx("Got %d spawn origins for weapons for map %s!", g_iWeapSpawnOrigins, szMapName);
}

stock compute_look_angles(const Float:inSource[3], const Float:inDest[3], Float:outAngles[3])
{
	// Note that we use outAngles as a temporary variable which stores the computed vector

	// First, set outVec to inSource - inDest
	outAngles[0] = inSource[0] - inDest[0];
	outAngles[1] = inSource[1] - inDest[1];
	outAngles[2] = inSource[2] - inDest[2];

	// Now, normalise the vector
	new Float:invLength = 1.0 / floatsqroot(outAngles[0]*outAngles[0] + outAngles[1]*outAngles[1] + outAngles[2]*outAngles[2]);

	outAngles[0] *= invLength;
	outAngles[1] *= invLength;
	outAngles[2] *= invLength;

	vector_to_angle(outAngles, outAngles);
	
	outAngles[0] = -90.0;
}

stock PlaceRandomGun(szWeaponName[], iLen)
{
	g_bWeaponFound = false;
	
	new bool:bFound = false, i = -1;
	
	new Float:vOrigin[3];
	
	if(g_iWorkingType && g_iWeapSpawnOrigins)
	{
		bFound = true;
		ArrayGetArray(g_hArraySpawnOrigins, random(g_iWeapSpawnOrigins), vOrigin);
	}
	
	else
	{
		while( ++i < MAX_ATTEMPTS )
		{
			for(new i; i < 2; i++)
			{
				vOrigin[i] = random_float(-MAX_ORIGIN, MAX_ORIGIN);
			}
			
			vOrigin[2] = random_float(g_flSearchOrigin - MAX_HIGHT, g_flSearchOrigin + MAX_HIGHT);
			
			if (point_contents(vOrigin) == CONTENTS_EMPTY)
			{
				bFound = true;
				break;
			}
		}
	}
	
	if(!bFound)
	{
		return;
	}
	
	g_iEnt = create_entity("info_target");
	
	if(!g_iEnt)
	{
		return;
	}
	
	set_pev(g_iEnt, pev_classname, g_szGunEntClass);
	entity_set_origin(g_iEnt, vOrigin);
	
	set_pev(g_iEnt, pev_solid, SOLID_TRIGGER);
	
	new iArrayIndex = random(g_iWeaponsCount);
	
	new _Array[ArrayWeaponsData];
	ArrayGetArray(g_hWeaponsArray, iArrayIndex, _Array);
	
	entity_set_model(g_iEnt, _Array[WEAP_MODEL]);
	
	entity_set_size(g_iEnt, g_vGunMins, g_vGunMaxs);
	
	set_pev(g_iEnt, pev_array_index, iArrayIndex);
	
	set_pev(g_iEnt, pev_nextthink, get_gametime() + 0.01);
	
	engfunc(EngFunc_DropToFloor, g_iEnt);
	
	pev(g_iEnt, pev_origin, vOrigin);
	vOrigin[2] += WEAPON_EXTRA_UP_ORIGIN;
	entity_set_origin(g_iEnt, vOrigin);
	
	copy(szWeaponName, iLen, _Array[WEAP_MENU_NAME]);
}

stock set_user_model(id)
{
	set_user_info(id, "model", g_szUserModel[id]);
}

stock PlaySound(id, bool:bEmit, szSound[])
{
	//#define FILE_UNKNOWN	0
	#define FILE_MP3		1
	#define FILE_WAV		2
	
	new iFileType;
	
	if(equali(szSound[strlen(szSound) - 3], "mp3"))
	{
		iFileType = FILE_MP3;
	}
	
	else if(equali(szSound[strlen(szSound) - 3], "wav"))
	{
		iFileType = FILE_WAV;
	}
	
	else { /*iFileType = FILE_UNKNOWN;*/ return; }
	
	if(iFileType == FILE_MP3 && bEmit)
	{
		return;
	}
	
	new szFile[60], szCmd[10];
	switch(iFileType)
	{
		case FILE_MP3:
		{
			#if defined EMIT_MP3
			formatex(szFile, charsmax(szFile), "sound/%s/%s", MOD_SOUNDS_PATH, szSound);
			
			if(bEmit)
			{
				if(!IsValidPlayer(id))
				{
					return;
				}
				
				client_cmd(id, "%s ^"%s^"", szCmd, szFile);
				
				new iEnt, Float:vOrigin[3]; pev(id, pev_origin, vOrigin);
				while( ( iEnt = find_ent_in_sphere(iEnt, vOrigin, 150.0) ) )
				{
					if(iEnt > g_iMaxPlayers)
					{
						return;
					}
					
					if(IsInBit(gAliveBit, iEnt))
					{
						client_cmd(iEnt, "%s ^"%s^"", szCmd, szFile);
					}
				}
				
				return;
			}

			#else
			if(bEmit)
			{
				return;
			}
			
			formatex(szFile, charsmax(szFile), "sound/%s/%s", MOD_SOUNDS_PATH, szSound);
			#endif
			szCmd = "mp3 play";
		}
		
		case FILE_WAV:
		{
			if(bEmit)
			{
				if(id)
				{
					formatex(szFile, charsmax(szFile), "%s/%s", MOD_SOUNDS_PATH, szSound);
					emit_sound(id, CHAN_AUTO, szFile, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}
				
				return;
			}
			
			szCmd = "spk";
			formatex(szFile, charsmax(szFile), "%s/%s", MOD_SOUNDS_PATH, szSound);
		}
	}
	
	if(!id)
	{
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "c");
		
		for(new i; i < iNum; i++)
		{
			id = iPlayers[i];
			
			if(IsInBit(gSoundsBit, id))
			{
				client_cmd(id, "%s ^"%s^"", szCmd, szFile);
			}
		}
	}
	
	else
	{
		client_cmd(id, "%s ^"%s^"", szCmd, szFile);
	}
}

stock PrecacheSound(szSound[])
{
	new szFile[60];
	if(equali(szSound[strlen(szSound) - 3], "mp3"))
	{
		formatex(szFile, charsmax(szFile), "sound/%s/%s", MOD_SOUNDS_PATH, szSound);
		precache_generic(szFile);
	}
	
	else if(equali(szSound[strlen(szSound) - 3], "wav"))
	{
		formatex(szFile, charsmax(szFile), "%s/%s", MOD_SOUNDS_PATH, szSound);
		precache_sound(szFile);
	}
}

/* ------------------------------------------------------------------------------
   --------------------------- Debug Stuff --------------------------------------
   ------------------------------------------------------------------------------ */

public client_PreThink(id)
{
	if(!IsInBit(gAliveBit, id))
	{
		return;
	}
	
	// Before delay to keep in real-time movement.
	if(g_iGrabEnt[id])
	{
		static Float:vOrigin[3], Float:vAngles[3];
		entity_get_vector(id, EV_VEC_origin, vOrigin);
		
		velocity_by_aim(id, floatround(g_flGrabDistance[id]), vAngles);
		xs_vec_add(vAngles, vOrigin, vAngles);
		
		entity_set_origin(g_iGrabEnt[id], vAngles);
	}
	
	// Delay Lasers (Prevent lag and overflow)
	static Float:flGameTime;
	if(g_flLast[id] + 0.1 > ( flGameTime = get_gametime() ) )
	{
		return;
	}
	
	g_flLast[id] = flGameTime;
	
	static Float:vOrigin[3], Float:vEntOrigin[3];
	if(id == g_iEditMode && g_iGuidingLaser)
	{	
		pev(id, pev_origin, vOrigin);
		static iEnt;
		iEnt = g_iMaxPlayers;

		while( ( iEnt = find_ent_by_class(iEnt, g_szTestSpawnEnt) ) )
		{
			if(get_entity_distance(iEnt, id) < GUIDING_LASER_MAX_DIST)
			{
				pev(iEnt, pev_origin, vEntOrigin);
				Draw(vOrigin, vEntOrigin, 1, 0, 127, 0, 255, .id = id);
			}
		}
		
		return;
	}
	
	if(IsInBit(gLaserBit, id))
	{
		if(is_valid_ent(g_iEnt) && !g_bWeaponFound && !g_iEditMode)
		{
			pev(id, pev_origin, vOrigin);
			pev(g_iEnt, pev_origin, vEntOrigin);
			Draw(vOrigin, vEntOrigin, 1, 255 ,0, 0, 200, .id = id);
		}
	}
	
	#if defined DEBUG
	else if(is_valid_ent(g_iEnt) && !g_bWeaponFound && !g_iEditMode)
	{
		pev(id, pev_origin, vOrigin);
		pev(g_iEnt, pev_origin, vEntOrigin);
		Draw(vOrigin, vEntOrigin, 1, 255 ,0, 0, 200);
	}
	#endif
}

stock Draw(Float:origin[3] = { 0.0, 0.0, 0.0 }, Float:endpoint[], duration = 1, red = 0, green = 255, blue = 0, brightness = 127, scroll = 2, id = 0)
{                    
	if(id)
	{
		message_begin(MSG_ONE, SVC_TEMPENTITY, .player = id);
	}
	
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	}
	
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, endpoint[0]);
	engfunc(EngFunc_WriteCoord, endpoint[1]);
	engfunc(EngFunc_WriteCoord, endpoint[2]);
	
	write_short(beampoint);
	write_byte(0);
	write_byte(0);
	write_byte(duration); // In tenths of a second.
	write_byte(10);
	write_byte(0);
	write_byte(red); // Red
	write_byte(green); // Green
	write_byte(blue); // Blue
	write_byte(brightness);
	write_byte(scroll);
	message_end();
}  

#if defined DEBUG
public CmdDebug(id)
{
	new Float:vOrigin[3];
	pev(g_iEnt, pev_origin, vOrigin);
	entity_set_origin(id, vOrigin);
	ColorPrint( id, "^4Here you go." );
}

public Origin(id)
{
	new Float:vOrigin1[3];
	pev(id, pev_origin, vOrigin1);
	
	client_print(id, print_chat, "** Your current origin:");
	client_print(id, print_chat, "* X = %0.2f", vOrigin1[0]);
	client_print(id, print_chat, "* Y = %0.2f", vOrigin1[1]);
	client_print(id, print_chat, "* Z = %0.2f", vOrigin1[2]);
	
	console_print(id, "Your current origin: %0.2f %0.2f %0.2f", vOrigin1[0], vOrigin1[1], vOrigin1[2]);
}
#endif

/* ------------------------------------------------------------------------------
   ----------------------------- Color Chat Stuff -------------------------------
   ------------------------------------------------------------------------------ */
stock ColorPrint(id, szMsg[], any:...)
{
	new szFmt[192];
	new len = formatex(szFmt, charsmax(szFmt), "%s ^1", g_szPrefix);
	
	vformat(szFmt[len], charsmax(szFmt) - len, szMsg, 3);
	ColorChat(id, COLOR, szFmt);
} 
   
new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	if( !get_playersnum() ) return;
    
	new message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	new team, ColorChange, index, MSG_Type;
    
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
    
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	static bool:saytext_used;
	static get_user_msgid_saytext;
	if(!saytext_used)
	{
		get_user_msgid_saytext = get_user_msgid("SayText");
		saytext_used = true;
	}
	message_begin(type, get_user_msgid_saytext, _, id);
	write_byte(id);
	write_string(message);
	message_end();    
}

Team_Info(id, type, team[])
{
	static bool:teaminfo_used;
	static get_user_msgid_teaminfo;
	
	if(!teaminfo_used)
	{
		get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
		teaminfo_used = true;
	}
	
	message_begin(type, get_user_msgid_teaminfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();
	
	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}
	return 0;
}

FindPlayer()
{
	new i = -1;

	while(i <= get_maxplayers())
	{
		if(is_user_connected(++i))
			return i;
	}

	return -1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
