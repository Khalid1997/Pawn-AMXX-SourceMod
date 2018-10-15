#include < 	amxmodx 	>
#include <	amxmisc 	>
#include < 	cstrike 	>
#include <	hamsandwich >
#include < 	engine 		>
#include <	fun 		>
#include < 	fakemeta 	>
#include <	xs			>
#include <	fvault		>

// Force semicolons ';'
#pragma semicolon 1

#define INCLUDE_BOT
//#define DEBUG

#define TEST_SPAWN_ENT_SOLID SOLID_BBOX

/* ========================================================= */
/* ===================  EDIT STARTS HERE  ================== */
/* ========================================================= */
// ---- Player Models ----
new const g_szJokerModel[] = 		"e_joker";
new const g_szChickenModel[] = 		"chicken";

// ---- Prefix for chat messages and bot name ----
new const g_szPrefix[] =			"^4[KFC MOD]";
#if defined INCLUDE_BOT
	new const g_szBotName[] =	"WHERE'S THE GUN BOT";
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
new const g_szMainMenuTitle[] = "WHERE'S THE GUN Menu";

#define ADMIN_MENU_ACCESS		ADMIN_RCON
#define ADMIN_SPAWN_ACCESS		ADMIN_RCON
#define ADMIN_MENU_POINTS		ADMIN_KICK

// ---- Menu item titles ----
new g_szMainMenuItemsTitle[][] = {
	"Players Points",
	"Shop Menu",
	//"Go to Spectators",
	//"???",
	"Admin Menu"
};

// ---- Max Guns ----
#define MAX_GUNS						7

// ---- Color Chat message Color (USELESS) ----
#define COLOR 							RED

// ---- Random gun bullets = Players * This value ----
#define RANDOM_GUN_BULLETS_MULTIPILE 	2

// ---- Time for 'search for weapon' phase ----
#define SEARCH_FOR_WEAPON_TIME			45		// In seconds.

// ---- Minimum players to start mod. ----
#define MIN_PLAYERS						2

// ---- Random Weapons Spawn Spot Stuff ----
#define MAX_ATTEMPTS					500
#define MAX_ORIGIN 						4192.0
#define MAX_HIGHT						300.0

// String length
#define MAX_POINT_STR_LEN				10
/* ========================================================= */
/* ===================  EDIT ENDS HERE  ==================== */
/* ========================================================= */

new const g_szPointsKey[] = "wtg_points";

#define TASKID_HUD					145851
#define TASKID_CHECK_PLAYERS		215171
new g_szGunEntClass[] = 			"gun_entity";

new const pev_array_index = 		pev_iuser4;
new g_szTestSpawnEnt[] =			"gun_test_entity";

#define m_iMenuCode 				205
#define m_iId						43

//#define m_Type 					34
//#define m_Count 					35
//#define XTRA_OFS_ARMOURY  		4

const m_iTeam = 114;
#define fm_cs_get_user_team(%1)  	get_pdata_int(%1, m_iTeam )
#define fm_cs_set_user_team(%1,%2)  set_pdata_int(%1, m_iTeam, %2 )

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

new gGunsInfo[MAX_GUNS][GUN_INFO] =
{
	{ "AK47", "weapon_ak47", 0, "models/w_ak47.mdl" },
	{ "AWP", "weapon_awp", 0, "models/w_awp.mdl" },
	{ "Deagle", "weapon_deagle", 0,"models/w_deagle.mdl" },
	{ "M4A1", "weapon_m4a1", 0, "models/w_m4a1.mdl" },
	{ "Glock18", "weapon_glock18", 0, "models/w_glock18.mdl" },
	{ "ShotGun", "weapon_m3", 0, "models/w_m3.mdl" },
	{ "Galil", "weapon_galil", 0, "models/w_galil.mdl" }
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
new g_iEnt, g_iGunIndex;

// Menu
enum
{
	MMENU_PLAYER_POINTS,
	MMENU_SHOP_MENU,
	//MMENU_SPEC,
	//MMENU_
	MMENU_ADMIN_MENU,
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
	SI_CHICKEN_MDL
};

new const g_szShopItemsBuyChatMsg[SHOP_ITEMS][] = {
	"^1You have bought the ^4Guiding Laser! ^1It will guide you to the weapon.",
	"^1You have bought the ^3Joker Model!",
	"^1You have bought the ^3Chicken Model!"
	
};

new const g_szShopItems[SHOP_ITEMS][SHOP_ITEM_DATA] = {
	{ "Guiding Laser", 100 },
	{ "Joker Model", 30 },
	{ "Chicken Model", 30 }
};

new g_iMainMenu;
new g_iShopMenu;
new g_iAdminMenu;
new g_iSpawnPointMenu, g_iEditMode, g_iGuidingLaser, g_iWorkingType = 1, g_iRemoveEnt, g_iRemoveMenu;
new g_hPlayerMenu[33];

#define IsInBit(%1,%2)			(	%1 & (1<<%2)	)
#define AddToBit(%1,%2)			(	%1 |= (1<<%2)	)
#define RemoveFromBit(%1,%2)	(	%1 &= ~(1<<%2)	)
new gLaserBit;

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
#define set_user_points(%1,%2)		g_iPoints[%1] = %2

new beampoint;
new Float:g_flLast[33];

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
		//"info_map_parameters",
		//"func_buyzone"
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
		formatex(szMdl, charsmax(szMdl), "sound/where_is_the_gun/%s", g_szChickenSounds[i]);
		precache_generic(szMdl);
	}
	
	for(i = 0; i < sizeof(g_szChickenKillSounds); i++)
	{
		formatex(szMdl, charsmax(szMdl), "where_is_the_gun/%s", g_szChickenKillSounds[i]);
		server_print("**** Precache %s", szMdl);
		precache_sound(szMdl);
	}
	
	precache_model("models/w_weaponbox.mdl");
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

public plugin_init( )
{
	register_plugin( "Where's the gun", "1.0", "Yousef & Khalid" );
	
	TrieDestroy(g_hObjectives);
	unregister_forward(FM_Spawn, g_hEntSpawnForward, 0);
	
	for(new i; i < sizeof(gGunsInfo); i++)
	{
		gGunsInfo[i][GF_iCSW] = get_weaponid(gGunsInfo[i][GF_szClassName]);
	}
	
	register_forward( FM_SetClientKeyValue, "fw_SetClientKeyValue" );
	register_forward( FM_ClientKill, "fw_ClientKill" );
	
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
	
	#if defined INCLUDE_BOT
	register_message(get_user_msgid("DeathMsg"), "MessageDeathMsg");
	#endif
	register_message(get_user_msgid("StatusIcon"), "MessageStatusIcon");
	register_message(get_user_msgid("Radar"), "MessageRadar");
	register_message(get_user_msgid("ShowMenu"), "MessageShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "MessageVGUIMenu");
	
	register_concmd( "wtg_setpoints", "SetPointsCmd", ADMIN_KICK, "<name | @all> <points>" );
	register_concmd("amx_spawn_edit_mode", "CmdEditMode", ADMIN_SPAWN_ACCESS);
	
	register_clcmd( "say /shop", "ShopCmd" );
	register_clcmd( "say .shop", "ShopCmd" );
	register_clcmd( "say /points", "PointsCmd" );
	
	register_clcmd( "chooseteam", "CmdMenu" );
	register_clcmd( "jointeam", "CmdBlockJoinTeam" );
	register_clcmd("drawradar", "CmdBlock");
	
	server_cmd("mp_limitteams 32");
	server_cmd("mp_autoteambalance 0");
	
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
	
	GetSpawnOriginsFromFile();
	CreateGameMenus();
	
	#if defined INCLUDE_BOT
	set_task(0.5, "DoBot");
	#endif
}

#if defined INCLUDE_BOT
new g_iBot;
public DoBot()
{
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
		ColorPrint(id, "^1Sorry, game is not running. Try again later.");
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
		new szTeam[ 20 ];
		if(equali(szArg1[1], "all"))
		{
			szTeam = "EVERYONE";
			get_players( Players, iPNum, "c" );
		}
		/*
		else if( szArg1[1] == 'T' || szArg1[1] == 't' )
		{
			szTeam = "TERRORIST";
			get_players( Players, iPNum, "ce", "TERRORIST" );
		}
		
		else if( szArg1[1] == 'c' || szArg1[1] == 'C' )
		{
			szTeam = "CT";
			get_players( Players, iPNum, "ce", "CT" );
		}*/
		
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
			ColorPrint( 0, "^1ADMIN ^3%s: ^1set ^3Everyone's ^1points to ^3%d^1.", szAdminName, newpoints );
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
		ColorPrint( 0, "^1ADMIN ^3%s: ^1set ^3%d ^1points to ^3%s^1.", szAdminName, newpoints, szPlayerName );
	}
	
	return PLUGIN_HANDLED;
}

public PointsCmd( id )
{
	new iPoints = get_user_points( id );
	
	ColorPrint( id, "^1Your points are ^3%d^1.", iPoints );
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
		
		ColorPrint(0, "^1Edit mode is ^3ON! Game Paused.");
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
		//server_cmd("sv_restart 3");
		
		console_print(id, "** Edit mode off. Restarting Round");
		ColorPrint(0, "^1Edit mode ^3off! ^1Continuing.");
	}
	
	return PLUGIN_HANDLED;
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
		return HAM_IGNORED;
	}
	
	if(!IsValidPlayer(attacker))
	{
		return HAM_IGNORED;
	}
	
	new szSound[60];
	formatex(szSound, charsmax(szSound), "where_is_the_gun/%s", g_szChickenKillSounds[random(sizeof(g_szChickenKillSounds))]);
	replace(szSound, charsmax(szSound), ".wav", "");
	
	emit_sound(victim, CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
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
		return;
	}
	
	g_szUserModel[id] = g_szChickenModel;
	set_user_model(id);
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
}

public eNewRound()
{
	g_bWeaponFound = false;
	
	if(!g_bWeaponFound)
	{
		if(is_valid_ent(g_iEnt))
		{
			remove_entity(g_iEnt);
		}
	}
	
	gLaserBit = 0;
}

#if defined INCLUDE_BOT
public eDeathMsg()
{
	new iVictim = read_data( 2 );
	new iTeam = get_user_team( iVictim );
	
	new iPlayers[32], iCount;
	get_players(iPlayers, iCount, "ae", "CT");
	if( iTeam == 2 && is_user_alive( g_iBot ) && iCount == 1)
	{
		set_pev(g_iBot, pev_takedamage, DAMAGE_YES);
		fakedamage( g_iBot, "worldspawn", 100.0, DMG_GENERIC );
	}
}

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
	
	new iPlayers[32], iCTNum;
	get_players( iPlayers, iCTNum, "e", "CT" );
	
	g_iGunIndex = PlaceRandomGun();
	
	if(g_iGunIndex == -1)
	{
		return;
	}
	
	g_bWeaponFound = false;
	ColorPrint( 0, "^1The random gun is ^3%s^1 with ^3%d ^1bullets", gGunsInfo[g_iGunIndex][GF_szName], iCTNum * RANDOM_GUN_BULLETS_MULTIPILE);
	
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
	if(id == g_iBot)
	{
		set_task(0.5, "DoBot");
	}
	
	else
	{
		if(id == g_iEditMode)
		{
			g_iEditMode = 0;
			remove_entity_name(g_szTestSpawnEnt);
			
			eTeamInfo();
		}
		
		SavePoints(id);
	}
}

public client_putinserver(id)
{
	LoadPoints(id);
	
	if(IsInBit(gLaserBit, id))
	{
		RemoveFromBit(gLaserBit, id);
	}
}

public client_connect(id)
{
	client_cmd(id, "hiderardar");
}


public CheckPlayers(iTaskId)
{
	new iCount = CountPlayers();
	
	if(iCount < MIN_PLAYERS)
	{
		if(g_iGameState != GAME_STOP)
		{
			g_iGameState = GAME_STOP;
			g_iGunIndex = 0;
			
			if(!g_bWeaponFound)
			{
				remove_entity(g_iEnt);
			} else {
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
		if(is_user_connected(i)/* && !is_user_bot(i)*/)
		{
			if(iAlive && is_user_alive(i))
			{
				if(cs_get_user_team(i) == CS_TEAM_CT)
				{
					iCount++;
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
	
	if(!g_bWeaponFound && g_iEnt == iEnt) //&& get_pdata_cbase(iEnt, m_iId, 4) != CSW_KNIFE)
	{
		g_bWeaponFound = true;
		g_iGameState = GAME_RUN;
		
		remove_entity(iEnt);
		
		new szWeaponName[32]; 
		get_weaponname(gGunsInfo[g_iGunIndex][GF_iCSW], szWeaponName, charsmax(szWeaponName));
		cs_set_weapon_ammo(give_item(iPlayer, szWeaponName) , CountPlayers() * RANDOM_GUN_BULLETS_MULTIPILE);
		cs_set_user_bpammo(iPlayer, gGunsInfo[g_iGunIndex][GF_iCSW], 0);
		
		new szPlayerName[32];
		get_user_name( iPlayer, szPlayerName, charsmax( szPlayerName ) );
		
		ColorPrint( 0, "^1Player ^3%s ^1got the random weapon.", szPlayerName );
		
		g_szUserModel[iPlayer] = g_szJokerModel;
		set_user_model(iPlayer);
		
		client_cmd(0, "mp3 play ^"sound/where_is_the_gun/%s^"", g_szChickenSounds[random(sizeof(g_szChickenSounds))]);
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
	//set_pev(iEnt, pev_fixangle, 1)
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
	// ------------------ MAIN MENU ---------------------------------
	g_iMainMenu = menu_create(g_szMainMenuTitle, "MainMenuHandler");
	
	for(new i; i < MMENU_ADMIN_MENU; i++)
	{
		menu_additem(g_iMainMenu, g_szMainMenuItemsTitle[i]);
	}
	
	menu_addblank(g_iMainMenu, 0);
	menu_additem(g_iMainMenu, g_szMainMenuItemsTitle[MMENU_ADMIN_MENU],_, ADMIN_MENU_ACCESS);
	
	// ------------------ SHOP MENU ---------------------------------
	g_iShopMenu = menu_create( "Where's the gun Shop", "ShopHandler" );
	new callback = menu_makecallback( "ShopCallBack" );
	
	for(new i, szItemName[70]; i < sizeof(g_szShopItems); i++)
	{
		formatex(szItemName, charsmax(szItemName), "%s \r[\w%d \yPoints\r]", g_szShopItems[i][SHOP_ITEM_NAME], g_szShopItems[i][SHOP_ITEM_PRICE]);
		menu_additem(g_iShopMenu, szItemName, .callback = callback);
	}
	
	// ------------------ ADMIN MENU ---------------------------------
	g_iAdminMenu = menu_create(g_szMainMenuItemsTitle[MMENU_ADMIN_MENU], "AdminMenuHandler");
	
	menu_additem(g_iAdminMenu, "Give Points Menu", .paccess = ADMIN_MENU_POINTS);
	menu_additem(g_iAdminMenu, "Give Weapon to Player", .paccess = ADMIN_MENU_ACCESS);
	menu_addblank(g_iAdminMenu, 0);
	
	menu_additem(g_iAdminMenu, "Give Shop Item to Player", .paccess = ADMIN_MENU_ACCESS);
	
	menu_addblank(g_iAdminMenu, 0);
	menu_additem(g_iAdminMenu, "Weapon Spawn Points Menu", .paccess = ADMIN_SPAWN_ACCESS);
	
	// ------------------ SPAWN POINT MENU ---------------------------------
	
	g_iSpawnPointMenu = menu_create("Spawn Points Menu", "SpawnPointMenuHandler");
	new szItemName[60];
	formatex(szItemName, charsmax(szItemName), "Weapon Spawn Points BY \r[\y%s\r]", g_iWorkingType ? "FILE" : "RANDOM");
	menu_additem(g_iSpawnPointMenu, szItemName);
	formatex(szItemName, charsmax(szItemName), "Guiding Laser (Guides to spawn points) \r[\y%s\r]", g_iGuidingLaser ? "ON" : "OFF");
	menu_additem(g_iSpawnPointMenu, szItemName);
	menu_addblank(g_iSpawnPointMenu, 0);
	
	menu_additem(g_iSpawnPointMenu, "Add Spawn Point");
	menu_additem(g_iSpawnPointMenu, "Remove Spawn Point");
	menu_addblank(g_iSpawnPointMenu, 0);
	
	menu_additem(g_iSpawnPointMenu, "Move Spawn Point \yUP");
	menu_additem(g_iSpawnPointMenu, "Move Spawn Point \yDOWN");
	
	menu_addblank(g_iSpawnPointMenu, 1);
	menu_additem(g_iSpawnPointMenu, "Remove All");
	menu_additem(g_iSpawnPointMenu, "Save All");
	
	// ------------------ REMOVE SPAWN POINT MENU ---------------------------------
	
	g_iRemoveMenu = menu_create("Remove Spawn Point Menu", "RemoveMenuHandler");
	menu_additem(g_iRemoveMenu, "Remove Nearest Spawn Point");
	menu_additem(g_iRemoveMenu, "Remove Spawn Point By Aim");
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
			new iMenu = CreateMenu(id, g_szMainMenuItemsTitle[MMENU_PLAYER_POINTS], "PlayerPointsMenuHandler");
			
			new iPlayers[32], iNum, szName[32], szItem[64];
			get_players(iPlayers, iNum, "ce", "CT");
			
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
				ColorPrint(id, "^1Sorry, game is not running. Try again later.");
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

public PlayerPointsMenuHandler(id, menu, item)
{
	if( item == MENU_EXIT || item != MENU_BACK || item != MENU_MORE )
	{
		DestroyMenu(id);
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
	
	new bool:bBought = false;
	
	switch(item)
	{
		case SI_JOKER_MDL:
		{
			if(!equal(g_szUserModel[id], g_szJokerModel))
			{
				ColorPrint(id, "^1You already have the ^3Joker Model.");
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
			if(!equal(g_szUserModel[id], g_szChickenModel))
			{
				ColorPrint(id, "^1You already have the ^3Chicken Model.");
			}

			else
			{
				g_szUserModel[id] = g_szChickenModel;
				set_user_model(id);
				
				ColorPrint(id, g_szShopItemsBuyChatMsg[item]);
				
				bBought = true;
			}
		}
		
		case SI_LASER:
		{
			if(!g_bWeaponFound)
			{
				AddToBit(gLaserBit, id);
				ColorPrint(id, g_szShopItemsBuyChatMsg[item]);
				
				bBought = true;
			}
			
			else
			{
				ColorPrint(id, "^1Sorry, The gun was picked up. You can't buy the ^4Guiding Laser");
			}
		}
	}
	
	if(bBought)
	{
		set_user_points(id, get_user_points(id) - g_szShopItems[item][SHOP_ITEM_PRICE]);
	}
}

public ShopCallBack(id, menu, item)
{
	if(item < 0)
	{
		return ITEM_ENABLED;
	}
	
	if(get_user_points(id) >= g_szShopItems[item][SHOP_ITEM_PRICE])
	{
		return ITEM_ENABLED;
	}
	
	return ITEM_DISABLED;
}

enum
{
	AM_POINTS_MENU,
	AM_GIVE_WEAPONS,
		
	AM_GIVE_SHOP_ITEM,
		
	AM_SPAWN_MENU,
};

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
			ColorPrint(id, "^1Sorry, this option is undone yet.");
		}
		
		case AM_GIVE_WEAPONS:
		{
			ColorPrint(id, "^1Sorry, this option is undone yet.");
		}
		
		case AM_GIVE_SHOP_ITEM:
		{
			ColorPrint(id, "^1Sorry, this option is undone yet.");
		}
		
		case AM_SPAWN_MENU:
		{
			if(!g_iEditMode)
			{
				ColorPrint(id, "^1Edit mode needs to be on. Type amx_spawn_edit_mode 1 in console.");
			}
			
			else if(g_iEditMode != id)
			{
				ColorPrint(id, "^1You are not the player who is currently in edit mode.");
			}
			
			else
			{
				iShow = 0;
				menu_display(id, g_iSpawnPointMenu);
			}
		}
	}
	
	if(iShow)
	{
		menu_display(id, menu);
	}
}

enum
{
	SM_SPAWN_SETTINGS,
	SM_GUIDING_LASER,
	
	SM_ADD,
	SM_REMOVE,
		
	SM_MOVE_UP,
	SM_MOVE_DOWN,
		
	SM_REMOVE_ALL,
	SM_SAVE_ALL
};

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
		case SM_SPAWN_SETTINGS:
		{
			g_iWorkingType = !g_iWorkingType;
			
			new szItemName[60];
			formatex(szItemName, charsmax(szItemName), "Weapon Spawn Points BY \r[\y%s\r]", g_iWorkingType ? "FILE" : "RANDOM" );
			
			menu_item_setname(menu, item, szItemName);
		}
		
		case SM_GUIDING_LASER:
		{
			g_iGuidingLaser = !g_iGuidingLaser;
			
			new szItemName[60];
			formatex(szItemName, charsmax(szItemName), "Guiding Laser (Guides to spawn points) \r[\y%s\r]", g_iGuidingLaser ? "ON" : "OFF");
			menu_additem(g_iSpawnPointMenu, szItemName);
			
			menu_item_setname(menu, item, szItemName);
		}
		
		case SM_ADD:
		{
			new iHitEnt, Float:vHitPoint[3];
			if(GetHitAimStuff(id, iHitEnt, vHitPoint))
			{
				ArrayPushArray(g_hArraySpawnOrigins, vHitPoint);
				CreateTestEntity(++g_iWeapSpawnOrigins - 1, vHitPoint);
				//g_iWeapSpawnOrigins++;
				
				ColorPrint(id, "^1Spawn Point Created!");
			}
			
			else ColorPrint(id, "^1Please aim at a solid place ...");
		}
		
		case SM_REMOVE:
		{
			iShow = 0;
			menu_display(id, g_iRemoveMenu);
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
					ColorPrint(id, "^1Please aim at a weapon (Spawn Point) #1");
					return;
				}
				new iEntry = pev(iHitEnt, pev_array_index);
				
				new Float:vOrigin[3];
				pev(iHitEnt, pev_origin, vOrigin);
				vOrigin[2] = ( item == SM_MOVE_DOWN ? vOrigin[2] - 1.0 : vOrigin[2] + 1.0 );
				set_pev(iHitEnt, pev_origin, vOrigin);
				
				if(IsEntStuck(iHitEnt))
				{
					new iEntry = pev(iHitEnt, pev_array_index);
					remove_entity(iHitEnt);
					ArrayDeleteItem(g_hArraySpawnOrigins, iEntry);
					g_iWeapSpawnOrigins--;
				
					iHitEnt = 0;
					new iEntEntry;
					while( ( iHitEnt = find_ent_by_class(iHitEnt, g_szTestSpawnEnt) ) )
					{
						iEntEntry = pev(iHitEnt, pev_array_index);
						if(iEntEntry > iEntry)
						{
							set_pev(iHitEnt, pev_array_index, iEntry - 1);
						}
					}
					
					ColorPrint(id, "^1Deleted entity because it got stuck.");
					return;
				}
					
				ArrayGetArray(g_hArraySpawnOrigins, iEntry, vOrigin);
				vOrigin[2] = ( item == SM_MOVE_DOWN ? vOrigin[2] - 1.0 : vOrigin[2] + 1.0 );
				ArraySetArray(g_hArraySpawnOrigins, iEntry, vOrigin);
				
				ColorPrint(id, "^1Moved spawn point ^3%s", item == SM_MOVE_DOWN ? "DOWN" : "UP");
			}
			
			else
			{
				ColorPrint(id, "^1Please aim at a weapon (Spawn Point)");
			}
		}
		
		case SM_REMOVE_ALL:
		{
			remove_entity_name(g_szTestSpawnEnt);
			g_iWeapSpawnOrigins = 0;
			ArrayClear(g_hArraySpawnOrigins);
			
			ColorPrint(id, "^1Removed all spawn origins");
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
				fclose(f);
			}
			ColorPrint(id, "^1Saved all");
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
		menu_display(id, g_iSpawnPointMenu);
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
			if(!equal(szClassName, g_szTestSpawnEnt))
			{
				ColorPrint(id, "WRONG ENTITY NOOB");
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
			ColorPrint(id, "^1No near spawn point");
		}
	}
	
	if(!g_iRemoveEnt)
	{
		menu_display(id, menu);
		//ColorPrint(id, "No near Spawn Point or you are not aiming at one.");
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
	
	if(item)
	{
		g_iRemoveEnt = 0;
		menu_display(id, g_iRemoveMenu);
	}
	
	else
	{
		new iEntry = pev(g_iRemoveEnt, pev_array_index);
		
		static szClassName[60];
		pev(g_iRemoveEnt, pev_classname, szClassName, charsmax(szClassName));
		
		ArrayDeleteItem(g_hArraySpawnOrigins, iEntry);
		
		new iEnt, iEntEntry;
		while( ( iEnt = find_ent_by_class(iEnt, g_szTestSpawnEnt) ) )
		{
			iEntEntry = pev(iEnt, pev_array_index);
			if(iEntEntry > iEntry)
			{
				set_pev(iEnt, pev_array_index, iEntEntry - 1);
			}
		}
		
		g_iWeapSpawnOrigins--;
		
		remove_entity(g_iRemoveEnt);
		ColorPrint(id, "^1Successfully removed Spawn Point");
		
		menu_display(id, g_iRemoveMenu);
	}
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
	
	new Float:vSize[2][3], Float:vOrigin[3];
	pev(iEnt, pev_origin, vOrigin);
	pev(iEnt, pev_mins, vSize[0]);
	pev(iEnt, pev_maxs, vSize[1]);
	
	new Float:flPosition[3];
	new iStuckPoints;
	for(new i, j; i < 2; i++)
	{
		for(j = 0; j < 3; j++)
		{
			flPosition[j] = vOrigin[j] + vSize[i][j];
			
			if(point_contents(flPosition) == CONTENTS_SOLID)
			{
				//return 1;
				iStuckPoints++;
			}
		}
	}
	
	return iStuckPoints == 6 ? 1 : 0;
}
	
stock CreateTestEntity(iEntry, Float:vOrigin[3])
{
	/*new iEnt = create_entity("info_target");
	
	if(!is_valid_ent(iEnt))
	{
		return;
	}
	
	set_pev(iEnt, pev_classname, g_szTestSpawnEnt);
	
	//vOrigin[2] += 10.0;
	set_pev(iEnt, pev_origin, vOrigin);
	
	engfunc(EngFunc_DropToFloor, iEnt);
	pev(iEnt, pev_origin, vOrigin);
	
	vOrigin[2] += 10.0;
	
	set_pev(iEnt, pev_origin, vOrigin);
	
	set_pev(iEnt, pev_model, "models/w_weaponbox.mdl");
	
	set_pev(iEnt, pev_mins, Float:{ -16.0, -16.0, 0.0 } );
	set_pev(iEnt, pev_maxs, Float:{ 16.0, 16.0, 16.0 } );
	
	set_pev(iEnt, pev_solid, SOLID_NOT);
	
	set_pev(iEnt, pev_array_index, iEntry);
	
	//dllfunc(DLLFunc_Spawn, iEnt);*/
	
	new iEnt = create_entity("info_target");
	
	if(!is_valid_ent(iEnt))
	{
		return;
	}
	
	set_pev(iEnt, pev_classname, g_szTestSpawnEnt);
	set_pev(iEnt, pev_origin, vOrigin);
	
	entity_set_model(iEnt, "models/w_weaponbox.mdl");
	entity_set_size(iEnt, Float:{ -16.0, -16.0, 0.0 }, Float:{ 16.0, 16.0, 16.0 } );
	//SetModelCollisionBox(iEnt);
	
	set_pev(iEnt, pev_solid, TEST_SPAWN_ENT_SOLID);
	//set_pev(iEnt, pev_movetype, MOVETYPE_FLY);
	
	set_pev(iEnt, pev_array_index, iEntry);
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.01);
	
	engfunc(EngFunc_DropToFloor, iEnt);
	
	pev(iEnt, pev_origin, vOrigin);
	vOrigin[2] += 10.0;
	set_pev(iEnt, pev_origin, vOrigin);
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

	//vEndPoint = vOrigin;
	vEndPoint = Float:{ 0.0, 0.0, 0.0 };
	xs_vec_mul_scalar(vAngles, 9999.0, vAngles);
	xs_vec_add(vAngles, vOrigin, vAngles);
	//velocity_by_aim(id, 9999, vEndPoint);
	//xs_vec_add(vEndPoint, vOrigin, vEndPoint);
	
	//xs_vec_add(vEndPoint, vViewOfs, vEndPoint);
	//xs_vec_add(vEndPoint, vAngles, vEndPoint);
	//xs_vec_mul_scalar(vEndPoint, 9999.0, vEndPoint);
	
	//(const float *v1, const float *v2, int fNoMonsters, edict_t *pentToSkip, TraceResult *ptr);
	engfunc(EngFunc_TraceLine, vOrigin, vAngles, DONT_IGNORE_MONSTERS, id, iTr);
	
	new flFraction;
	get_tr2(iTr, TR_flFraction, flFraction);
	
	if(flFraction == 1.0)
	{
		console_print(0, "No solid place in sight to place spawn origin. IMPOSSIBLE!!");
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
	
	server_print("iHit Ent = %d", iHitEnt);
	
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

stock LoadPoints(id)
{
	new szSteam[35];
	new szPoints[MAX_POINT_STR_LEN];
		
	get_user_authid( id, szSteam, charsmax( szSteam ) );
	fvault_get_data( g_szPointsKey, szSteam, szPoints, charsmax( szPoints ) );
	
	new iPoints = str_to_num(szPoints);
	if(iPoints < 0)
	{
		iPoints = 0;
	}
	
	set_user_points( id, iPoints );
}

stock SavePoints(id)
{
	new szSteam[35];
	new szData[MAX_POINT_STR_LEN];
	
	get_user_authid( id, szSteam, charsmax( szSteam ) );
	num_to_str(g_iPoints[id], szData, charsmax( szData ));
	fvault_set_data( g_szPointsKey, szSteam, szData );
}

stock GetSpawnOriginsFromFile()
{
	get_datadir(g_szSpawnFile, charsmax(g_szSpawnFile));
	
	format(g_szSpawnFile, charsmax(g_szSpawnFile), "%s/where_is_the_gun", g_szSpawnFile);
	
	if(!dir_exists(g_szSpawnFile))
	{
		mkdir(g_szSpawnFile);
		return;
	}
	
	#define MAX_MAP_NAME	50	// Keep this here
	new szMapName[MAX_MAP_NAME];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);
	
	format(g_szSpawnFile, charsmax(g_szSpawnFile), "%s/%s.ini", g_szSpawnFile, szMapName);
	
	new f = fopen(g_szSpawnFile, "r");
	
	if(!f)
	{
		//f = fopen(g_szSpawnFile, "a+");
		//fclose(f);
		
		return;
	}
	
	g_hArraySpawnOrigins = ArrayCreate(3);
	
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
			
		ArrayPushArray(g_hArraySpawnOrigins, vOrigin);
	}
	
	fclose(f);
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

stock PlaceRandomGun()
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
		return -1;
	}
	
	new iGun = random(MAX_GUNS);
	
	g_iEnt = create_entity("info_target");
	
	if(!g_iEnt)
	{
		return -1;
	}
	
	static const pev_guntype = pev_iuser4;
	
	set_pev(g_iEnt, pev_classname, g_szGunEntClass);
	set_pev(g_iEnt, pev_origin, vOrigin);
	
	set_pev(g_iEnt, pev_solid, SOLID_TRIGGER);
	
	entity_set_model(g_iEnt, gGunsInfo[iGun][GF_szModel]);
	
	set_pev(g_iEnt, pev_mins, Float:{ -16.0, -16.0, 0.0 } );
	set_pev(g_iEnt, pev_maxs, Float:{ 16.0, 16.0, 16.0 } );
	
	set_pev(g_iEnt, pev_guntype, gGunsInfo[iGun][GF_iCSW]);
	
	set_pev(g_iEnt, pev_nextthink, get_gametime() + 0.01);
	
	engfunc(EngFunc_DropToFloor, g_iEnt);
	
	pev(g_iEnt, pev_origin, vOrigin);
	vOrigin[2] += 10.0;
	set_pev(g_iEnt, pev_origin, vOrigin);
	
	return iGun;
}

stock set_user_model(id)
{
	set_user_info(id, "model", g_szUserModel[id]);
}

/* ------------------------------------------------------------------------------
   --------------------------- Debug Stuff --------------------------------------
   ------------------------------------------------------------------------------ */

public client_PostThink(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
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
			if(get_entity_distance(iEnt, id) < 350.0)
			{
				pev(iEnt, pev_origin, vEntOrigin);
				Draw(vOrigin, vEntOrigin, 1, 0, 127, 0, 255, .id = id);
			}
		}
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
		
		/*write_byte(TE_BEAMENTPOINT);
		write_short(id | 0x1000);
		engfunc(EngFunc_WriteCoord, endpoint[0]);
		engfunc(EngFunc_WriteCoord, endpoint[1]);
		engfunc(EngFunc_WriteCoord, endpoint[2]);*/
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
	client_print(id, print_chat, "Go");
}

public Origin(id)
{
	new Float:vOrigin1[3];
	pev(id, pev_origin, vOrigin1);
	
	client_print(id, print_chat, "** Your current origin:");
	client_print(id, print_chat, "* X = %0.2f", vOrigin1[0]);
	client_print(id, print_chat, "* Y = %0.2f", vOrigin1[1]);
	client_print(id, print_chat, "* Z = %0.2f", vOrigin1[2]);
	
	//vOrigin = vOrigin1
	
	console_print(id, "Your current origin: %0.2f %0.2f %0.2f", vOrigin1[0], vOrigin1[1], vOrigin1[2]);
	
	//set_task(2.0, "MakeWeapon");
}

public MakeWeapon()
{
	PlaceRandomGun();
}
#endif

/* ------------------------------------------------------------------------------
   ----------------------------- Color Chat Stuff -------------------------------
   ------------------------------------------------------------------------------ */
stock ColorPrint(id, szMsg[], any:...)
{
	new szFmt[192];
	new len = formatex(szFmt, charsmax(szFmt), "%s ", g_szPrefix);
	
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
