#include < 	amxmodx 	>
#include <	amxmisc 	>
#include < 	cstrike 	>
#include <	hamsandwich 	>
#include < 	engine 		>
#include <	fun 		>
#include < 	fakemeta 	>
#include <	xs		>

// Force semicolons ';'
#pragma semicolon 1

#define INCLUDE_BOT
#define DEBUG
/* ========================================================= */
/* ===================  EDIT STARTS HERE  ================== */
/* ========================================================= */
// Player Models
new const g_szJokerModel[] = 		"e_joker";
new const g_szChickenModel[] = 		"chicken";

// Prefix for chat messages and bot name
new const g_szPrefix[] =			"^4[AMXX]";
#if defined INCLUDE_BOT
	new const g_szBotName[] =	"WHERE'S THE GUN BOT";
#endif

// Chicken sounds when gun is picked up or when round startes
new g_szChickenSounds[][] = {
	"chicken_sound.mp3"
};

// Required Access for admins menu.
#define ADMIN_MENU_ACCESS		ADMIN_RCON
#define ADMIN_SETTINGS_ACCESS		ADMIN_KICK

// Max Guns
#define MAX_GUNS			5

// Color Chat message Color (USELESS)
#define COLOR 				RED

// Random gun bullets = Players * This value
#define RANDOM_GUN_BULLETS_MULTIPILE 	2

// Time for 'search for weapon' phase
#define SEARCH_FOR_WEAPON_TIME		45		// In seconds.

// Minimum players to start mod.
#define MIN_PLAYERS			2

// Max Spawns Per Map
#define MAX_MAP_WEAPON_SPAWNS		26

// Random Weapons Spawn Spot Stuff
#define MAX_ATTEMPTS			500
#define MAX_ORIGIN 			4192.0
#define MAX_HIGHT			300.0
/* ========================================================= */
/* ===================  EDIT ENDS HERE  ==================== */
/* ========================================================= */

#define TASKID_HUD		145851
#define TASKID_CHECK_PLAYERS	215171
new g_szGunEntClass[] = 		"gun_entity";

#define m_iMenuCode 		205
#define m_iId			43

//#define m_Type 		34
//#define m_Count 		35
//#define XTRA_OFS_ARMOURY  	4

const m_iTeam = 114;
#define fm_cs_get_user_team(%1)  ( get_pdata_int(%1, m_iTeam ) )
#define fm_cs_set_user_team(%1,%2)  ( set_pdata_int(%1, m_iTeam, %2 ) )

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
	{ "Glock18", "weapon_glock18", 0, "models/w_glock18.mdl" }
};

enum GamePhases
{
	GAME_STOP,
	GAME_RUN,
	GAME_STANDBY
};

// Mod Specific
new GamePhases:g_iGameState;
new g_iCounter;
new bool:g_bWeaponFound;
new g_iEnt, g_iGunIndex;

enum
{
	MENU_PLAYER_POINTS,
	MENU_SHOP_MENU,
	MENU_SPEC,
	MENU_
	MENU_ADMIN_MENU,
	
};

new g_szMainMenuItemsTitle[][] = {
	"Players Points",
	"Shop Menu",
	"Go to Spectators",
	"???",
	"Admin Menu"
};

// Menu
new g_iMainMenu;

new g_iAdminMenu;
//new g_i;
new g_iSettingsMenu;
new g_hPlayerMenu[33]

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

// Only debug stuff (Testing)
#if defined DEBUG
new beampoint;
new Float:g_flLast[33];
#endif

public plugin_precache()
{
	#if defined DEBUG
	beampoint = precache_model("sprites/laserbeam.spr");
	#endif
	
	// Removed buyzone. No need.
	/*new iEnt = create_entity("info_map_parameters");
	
	if(iEnt)
	{
		DispatchKeyValue(iEnt, "buying", "3");
	}*/
	
	g_hObjectives = TrieCreate();
	new const szObjectives[][] =
	{
		"func_bomb_target", "info_bomb_target", "hostage_entity", "monster_scientist",
		"func_hostage_rescue", "info_hostage_rescue", "info_vip_start", "func_vip_safetyzone",
		"func_escapezone", "armoury_entity", "weaponbox", 
		"player_weaponstrip", "game_player_equip",
		//"info_map_parameters",
		"func_buyzone"
	};
	
	for(new i; i < sizeof(szObjectives); i++)
	{
		TrieSetCell(g_hObjectives, szObjectives[i], 1);
	}
	
	g_hEntSpawnForward = register_forward(FM_Spawn, "fw_EntSpawn", 0);
	
	for(new i; i < sizeof(gGunsInfo); i++)
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
	
	for(new i; i < sizeof(g_szChickenSounds); i++)
	{
		formatex(szMdl, charsmax(szMdl), "sound/where_is_the_gun/%s", g_szChickenSounds[i]);
		precache_generic(szMdl);
	}
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
	CreateMainMenu()
	
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
			set_user_model(id);
        
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

public JoinTeam(id)
{
	client_cmd(id, "jointeam 2");
	client_cmd(id, "joinclass 5");
}

public CmdMenu( id )
{
	//menu_display(id, g_iMenu);
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
	
	/*if( iCTNum < 2 )
	{
		ColorPrint( 0, "^3Where's the gun ^1mode can't be played until CT team has 2 players or more" );
		set_task(15.0, "RoundStart");
		return;
	}*/
	
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
	//ColorPrint( 0, "^1The random gun is ^3%s", g_name[g_iGunIndex][NAME]);
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
	
	set_task(0.2, "CheckPlayers", TASKID_CHECK_PLAYERS);
}

public client_putinserver(id)
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
	if(!g_iGameState)
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
		
		//client_cmd(0, "mp3 play ^"sound/where_is_the_gun/%s^"", g_szChickenSound);
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

/* ------------------------------------------------------------------------------
   ----------------------------   Stocks   --------------------------------------
   ------------------------------------------------------------------------------ */
public MainMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	switch(item)
	{
		case 
	}
}

stock CreateMainMenu()
{
	g_iMainMenu = menu_create(g_szMainMenuTitle, "MainMenuHandler")
	
	for(new i; i < MENU_ADMIN_MENU; i++)
	{
		menu_additem(g_iMainMenu, g_szMainMenuItemsTitle[i])
	}
	
	menu_addblank(g_iMenu, 0)
	menu_additem(g_iMainMenu, g_szMainMenuItemsTitle[ADMIN_MENU],_, ADMIN_MENU_ACCESS)
}
   
stock CreateMenu(id, const szTitle[], const szHandler[])
{
	if(g_hPlayerMenu[id])
	{
		DestroyMenu(id)
	}
	
	g_hPlayerMenu[id] = menu_create(szTitle, szHandler)
	return g_hPlayerMenu[id]
}

stock DestroyMenu(id)
{
	if(g_hPlayerMenu[id])
	{
		menu_destroy(g_hPlayerMenu[id])
		g_hPlayerMenu[id] = 0
	}
}	
   
stock GetSpawnOriginsFromFile()
{
	new const szFile[] = "addons/amxmodx/data/spawn_origins.ini";
	
	new f = fopen(szFile, "r");
	
	if(!f)
	{
		f = fopen(szFile, "a+");
		fclose(f);
		return;
	}
	
	g_hArraySpawnOrigins = ArrayCreate(3, 3);
	
	#define MAX_MAP_NAME	50	// Keep this here
	new szMapName[MAX_MAP_NAME];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);
	
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
		
		if(szLine[0] != '[')
		{
			continue;
		}
		
		replace(szLine[1], charsmax(szLine) - 1, "]", "");
		trim(szLine);
		
		if(!equal(szLine[1], szMapName))
		{
			continue;
		}
		
		fgets(f, szLine, charsmax(szLine));
		while(!feof(f))
		{
			trim(szLine);
		
			if(szLine[0] == '[')
			{
				break;
			}
			
			if(!szLine[0] || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/') )
			{
				fgets(f, szLine, charsmax(szLine));
				continue;
			}
			
			parse(szLine, szOrigin[0], charsmax(szOrigin[]), szOrigin[1], charsmax(szOrigin[]),
			szOrigin[2], charsmax(szOrigin[]));
			
			for(new i; i < 3; i++)
			{
				trim(szOrigin[i]);
				vOrigin[i] = str_to_float(szOrigin[i]);
				//server_print("** %f", vOrigin[i])
			}
			
			ArrayPushArray(g_hArraySpawnOrigins, vOrigin);
			
			if( ++g_iWeapSpawnOrigins >= MAX_MAP_WEAPON_SPAWNS )
			{
				break;
			}
			
			fgets(f, szLine, charsmax(szLine));
		}
		
		break;
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
	
	new iTr = create_tr2();
	
	new bool:bFound = false, i = -1;
	
	new Float:flFraction;
	new Float:vOrigin2[3];
	new Float:vOrigin[3];
	
	if(g_iWeapSpawnOrigins)
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
			
			vOrigin2 = Float:{ 0.0, 0.0, 0.0 };
			xs_vec_add(vOrigin, Float:{ 16.0, 16.0, 16.0 }, vOrigin2);
			
			engfunc(EngFunc_TraceHull, vOrigin, vOrigin2, 0, HULL_POINT, 0, iTr);
		
			get_tr2(iTr, TR_flFraction, flFraction);
		
			if(flFraction == 1.0)
			{
				server_print("Fail1");
				continue;
			}
			
			if ( get_tr2 (iTr, TR_InOpen) && !get_tr2 (iTr, TR_AllSolid) && !get_tr2 (iTr, TR_StartSolid))
			//point_contents(vOrigin) == CONTENTS_EMPTY)
			{
				bFound = true;
				
				free_tr2(iTr);
				break;
			}
			
			server_print("Fail2 //%d%d %d", get_tr2 (iTr, TR_InOpen), !get_tr2 (iTr, TR_AllSolid), !get_tr2 (iTr, TR_StartSolid));
		}
	}
	
	if(!bFound)
	{
		return -1;
	}
	
	server_print("Found Good origin");
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

#if defined DEBUG
public client_PostThink(id)
{
	if(!is_valid_ent(g_iEnt) || !is_user_alive(id))
	{
		return;
	}
	
	if(g_flLast[id] + 0.1 > get_gametime())
	{
		return;
	}
	
	static Float:vOrigin[3], Float:vOrigin2[3];
	
	pev(id, pev_origin, vOrigin);
	pev(g_iEnt, pev_origin, vOrigin2);
	
	g_flLast[id] = get_gametime();
	Draw(vOrigin, vOrigin2, 1, 255 ,0, 0, 200);
}

stock Draw(Float:origin[3] = { 0.0, 0.0, 0.0 }, Float:endpoint[], duration = 1, red = 0, green = 255, blue = 0, brightness = 127, scroll = 2, id = 0)
{                    
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	
	if(id)
	{
		write_byte(TE_BEAMENTPOINT);
		write_short(id | 0x1000);
		engfunc(EngFunc_WriteCoord, endpoint[0]);
		engfunc(EngFunc_WriteCoord, endpoint[1]);
		engfunc(EngFunc_WriteCoord, endpoint[2]);
	}
	
	else
	{
		write_byte(TE_BEAMPOINTS);
		engfunc(EngFunc_WriteCoord, origin[0]);
		engfunc(EngFunc_WriteCoord, origin[1]);
		engfunc(EngFunc_WriteCoord, origin[2]);
		engfunc(EngFunc_WriteCoord, endpoint[0]);
		engfunc(EngFunc_WriteCoord, endpoint[1]);
		engfunc(EngFunc_WriteCoord, endpoint[2]);
	}

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
