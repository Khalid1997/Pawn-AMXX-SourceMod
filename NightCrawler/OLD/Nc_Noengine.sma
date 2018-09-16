#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
//#include <engine>
#include <xs>
#include <colorchat>

new const VERSION[] = "1.0"

new const PREFIX[] = "[NightCrawler]"

/* ***************** UNLIMITED CLIP ******************** */
// CS Offsets
#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

// Max Clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, 1, 7, -1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }
			
// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }
			
// Weapon IDs for ammo types
new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }
			
// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }
			
new g_msgAmmoPickup
/* ***************** UNLIMITED CLIP ******************** */

enum	_:NC_
{
	HEALTH,
	SPEED,
	GRAVITY,
	GAMMA,
	TELEPORT_COST
}

new CVARS[NC_] = {
	150,
	250,
	400,
	150,
	50
}

new g_iUserPoints[33], g_iUserGamma[33][2]
new g_iVisible[33] = 1
new Float:g_flWallOrigin[33][3]
new gExplosionSpirit
new g_pGravity, g_pRadius

enum
{
	GAMMA_AMOUNT,
	GAMMA_LASTGAIN
}

new NC_MODEL[] = "nightcrawler"
new NC_KNIFE[] = "models/nightcrawler/v_nightcrawler.mdl"

enum
{
	EXPLOSION,
	FROST,
	FIRE,
	UNLIMITED,
	LASERMINE,
	LASERSIGHT
}

enum _:ITEMDATAS {
	ITEMNAME[32],
	COST
}

new const _:ITEMS[][ITEMDATAS] = {
	{ "Explosion", 8 },
	{ "Frost grenade", 5 },
	{ "Fire grenade", 3 },
	{ "UnlimitedClip", 10 },
	{ "LaserMine",	0 },
	{ "Laser Sight", 0 }
}

// Macros
new g_iMaxPlayers
#define		IsPlayer(%1)		( 1 <= %1 <= g_iMaxPlayers )

// BITS
new gUnlimited, gExplosion
#define IsInBit(%1,%2)		( %2 &  (1<<%1)  )
#define InsertToBit(%1,%2)	( %2 |= (1<<%1)  )
#define RemoveFromBit(%1,%2)	( %2 &= ~(1<<%1) )

#define MAPZONE_BUY (1<<0)
#define OFFSET_MAPZONES 235

//#define GAMMA_ADD	1.5
#define GAMMA_ADD	( random_num(1, 3) )
#define GAMMA_DELAY	2
#define EXPLOSION_RADIUS	300

#define CT_RATIO 3
#define NC_TEAM	CS_TEAM_T

#define TASK_HUD	2891715132243231
#define TASKID_INVIS	18736187213351

public plugin_precache()
{
	precache_sound("nightcrawler/teleport.wav")
	
	new szFile[70]
	formatex(szFile, charsmax(szFile), "models/player/%s/%s.mdl", NC_MODEL, NC_MODEL)
	precache_model(szFile)
	precache_model(NC_KNIFE)
	
	gExplosionSpirit = precache_model("sprites/zerogxplode.spr")
	
	// Round end ... 
	/*new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
	if (pev_valid(ent))
	{
		engfunc(EngFunc_SetOrigin, ent, Float:{ 8192.0,8192.0,8192.0 } )
		dllfunc(DLLFunc_Spawn, ent)
	}*/
}

stock SetBombSites( bool:bActive, bool:bRestart )
{
	new iEnt = -1
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname",  bActive ? "_func_bomb_target" : "func_bomb_target")) > 0 )
	{
		set_pev(iEnt, pev_classname, bActive ? "func_bomb_target" : "_func_bomb_target")
	}
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname",  bActive ? "_info_bomb_target" : "info_bomb_target")) > 0 )
	{
		set_pev(iEnt, pev_classname, bActive ? "info_bomb_target" : "_info_bomb_target")
	}
	
	if( bRestart )
	{
		static pSvRestart
		if( !pSvRestart )
		{
			pSvRestart = get_cvar_pointer("sv_restart")
		}
		
		set_pcvar_num(pSvRestart, 1)
	}
}  
	
public plugin_init()
{	
	register_plugin("NightCrawler Mod", VERSION, "Khalid :)")
	
	SetBombSites(false, true)
	
	register_clcmd("say /help", "ShowHelpMotd")
	register_clcmd("say /shop", "ShowShopMenu")
	
	register_clcmd("say /points", "GivePoints")
	register_clcmd("say /gamma",  "GiveGamma")
	
	register_event("CurWeapon", "eCurWeapon", "b", "1=1", "2=29")
	//register_event("DeathMsg", "eDeathMsg", "a")
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")
	register_event("AmmoX", "eAmmoX", "b")
	
	register_message(get_user_msgid("CurWeapon"), "message_CurWeapon")
	register_message(get_user_msgid("Scenario"), "message_Scenario")
	register_message(get_user_msgid("StatusIcon"), "message_StatusIcon");
	
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	
	RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PreThink, "player", "Fwd_Think")
	RegisterHam(Ham_Player_ImpulseCommands, "player", "Fwd_Impulse", 0)
	RegisterHam(Ham_TakeDamage, "player", "Fwd_TakeDamage", 0)
	
	register_forward(FM_AddToFullPack, "Forward_AddToFullPack_Post", 1);
	
	register_forward(FM_Touch, "Fwd_Touch")
	//register_touch("armoury_entity", "player", "Fwd_Touch")
	
	//register_touch("func_wall", "player", "Fwd_WallTouch")
	//register_touch("func_breakable", "player", "Fwd_WallTouch")
	//register_touch("worldspawn", "player", "Fwd_WallTouch")
	
	g_iMaxPlayers = get_maxplayers()
	
	g_pGravity = get_cvar_pointer("sv_gravity")
	g_pRadius = register_cvar("test_radius", "300")
}

public GiveGamma(id)
	g_iUserGamma[id][GAMMA_AMOUNT] = 999999

public GivePoints(id)
	g_iUserPoints[id] = 9999999

public Fwd_WallTouch(touched, toucher)
{
	pev(toucher, pev_origin, g_flWallOrigin[toucher])
}

public Fwd_Touch(touched, toucher)
{
	if(IsPlayer(toucher) && cs_get_user_team(toucher) == NC_TEAM)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public eNewRound()
{
	// Reset Shops
	gExplosion = 0
	gUnlimited = 0
}

public client_putinserver(id)
	g_iVisible[id] = 1
	
	//g_iUserPoints[id] = load_points(id)

public ShowHelpMotd(id)
{
	ColorChat(id, BLUE, "Under development.....")
	return PLUGIN_HANDLED
}

public ShowShopMenu(id)
{
	if(!is_user_alive(id))
	{
		ColorChat(id, GREEN, "You must be alive to use this :)")
		return PLUGIN_HANDLED
	}
	
	if(cs_get_user_team(id) == NC_TEAM)
	{
		ColorChat(id, BLUE, "You must be a survivor to use shop..")
		return PLUGIN_HANDLED
	}
	
	new szTitle[50]
	formatex(szTitle, charsmax(szTitle), "\r%s \wShop:	\r(\yYour total points: \w%d\r)", PREFIX, g_iUserPoints[id])
	new iMenu = menu_create(szTitle, "ShopHandler")
	
	new iSize = sizeof(ITEMS)
	new szInfo[5]
	
	for(new i; i < iSize; i++)
	{
		if(ITEMS[i][COST])
		{
			formatex(szTitle, charsmax(szTitle), "\w%s \r%d \yPoints", ITEMS[i][ITEMNAME], ITEMS[i][COST])
			num_to_str(i, szInfo, charsmax(szInfo))
			menu_additem(iMenu, szTitle, szInfo)
		}
	}
	
	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public ShopHandler(id, menu, item)
{
	if(item < 0)
		return;
		
	new szInfo[2], iNum, access, callback
	menu_item_getinfo(menu, item, access, szInfo, charsmax(szInfo), .callback=callback)
	menu_destroy(menu)
	
	iNum = str_to_num(szInfo)
	
	if(g_iUserPoints[id] < ITEMS[iNum][COST])
	{
		ColorChat(id, BLUE, "%s ^4You don't have enough points to buy this item.", PREFIX)
		return;
	}
	
	g_iUserPoints[id] -= ITEMS[iNum][0]
	
	switch(iNum)
	{
		case	EXPLOSION:
		{
			InsertToBit(id, gExplosion)
			ColorChat(id, BLUE, "%s ^4Press your F key to activate it.", PREFIX)
		}
		
		case	FROST:
		{
			ColorChat(id, BLUE, "%s ^4You have bought Frost grenade", PREFIX)
			give_item(id, "weapon_flashbang")
		}
		
		case	FIRE:
		{
			ColorChat(id, BLUE, "%s ^4You have bought Frost grenade", PREFIX)
			give_item(id, "weapon_hegrenade")
		}
		
		case	UNLIMITED:
		{
			ColorChat(id, BLUE, "%s ^4You have bought unlimited clip.", PREFIX)
			InsertToBit(id, gUnlimited)
		}
	}
}

public Fwd_Think(id)
{
	if(!pev_valid(id))
		return;
	
	static iGameTime
	if(cs_get_user_team(id) == NC_TEAM)
	{
		if(is_user_alive(id) && ( g_iUserGamma[id][GAMMA_AMOUNT] < CVARS[GAMMA] ) && ( (iGameTime = floatround(get_gametime()) ) >= g_iUserGamma[id][GAMMA_LASTGAIN] ) )
			AddGamma(id, iGameTime)
		
		static iButton;
		iButton = pev(id, pev_button)
	
		if( iButton & IN_USE )
		{
			static Float:fOrigin[ 3 ];
			pev( id, pev_origin, fOrigin );
		
			if( get_distance_f( fOrigin, g_flWallOrigin[ id ] ) > 10.0 )
				return;
		
			if( pev( id, pev_flags ) & FL_ONGROUND )
			{
				ExecuteHam(Ham_Player_Jump, id)
				//return;
			}
		
			if( iButton & IN_FORWARD )
			{
				static Float:fVelocity[ 3 ];
				velocity_by_aim( id, 240, fVelocity );
			
				set_pev( id, pev_velocity, fVelocity );
			}
		
			else if( iButton & IN_BACK )
			{
				static Float:fVelocity[ 3 ];
				velocity_by_aim( id, -240, fVelocity );
			
				set_pev( id, pev_velocity, fVelocity );
			}
		}
	}
}

AddGamma(id, iGameTime)
{
	g_iUserGamma[id][GAMMA_LASTGAIN] = iGameTime + GAMMA_DELAY
	
	new iGammaAmount = CVARS[GAMMA]
	new iNum = GAMMA_ADD
	if(g_iUserGamma[id][GAMMA_AMOUNT] + iNum > iGammaAmount)
		g_iUserGamma[id][GAMMA_AMOUNT] = iGammaAmount
	
	else	g_iUserGamma[id][GAMMA_AMOUNT] += iNum
}

public Fwd_TakeDamage(id, idinflictor, iAttacker)
{
	if( /*IsPlayer(id) &&*/ cs_get_user_team(id) == NC_TEAM)
	{
		if( !IsPlayer(iAttacker) )	// Falled ..
			return HAM_SUPERCEDE
	
		if(IsPlayer(iAttacker) )
		{
			g_iVisible[id] = 1
			
			new iNum = TASKID_INVIS + id
			if(task_exists(iNum))
				remove_task(iNum)
				
			set_task(3.0, "set_back", iNum)
		}
	}
	return HAM_IGNORED
}

public Forward_AddToFullPack_Post( es, e, iEntity, iHost, iHostFlags, iPlayer, pSet )
{
	if( is_user_alive( iEntity ) && is_user_alive( iHost ) && cs_get_user_team( iEntity ) == NC_TEAM && cs_get_user_team( iHost ) == CS_TEAM_CT )
	{
		set_es( es, ES_RenderMode, kRenderTransAdd );
			
		if( g_iVisible[ iEntity ] )
			set_es(es, ES_RenderAmt, 255);
			
		else set_es(es, ES_RenderAmt, 0);
	}
}

public set_back(taskid)
{
	new id = taskid - TASKID_INVIS
	g_iVisible[id] = 0
}

public message_StatusIcon(msg_id, msg_dest, msg_entity)
{
	new icon[9]
	get_msg_arg_string(2, icon, charsmax(icon));

	if(equal(icon, "buyzone"))
	{
		set_pdata_int(msg_entity, OFFSET_MAPZONES, (get_pdata_int(msg_entity, OFFSET_MAPZONES) & ~MAPZONE_BUY) );
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public refill_bpammo(const args[], id)
{
	// Player died or turned into a zombie
	if (!is_user_alive(id))
		return;
	
	set_msg_block(g_msgAmmoPickup, BLOCK_ONCE)
	
	static iWeaponId
	iWeaponId = args[0]
	
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[iWeaponId], AMMOTYPE[iWeaponId], MAXBPAMMO[iWeaponId])
}

// BP Ammo update
public eAmmoX(id)
{
	// Get ammo type
	static type
	type = read_data(1)
	
	// Unknown ammo type
	if (type >= sizeof AMMOWEAPON)
		return;
	
	// Get weapon's id
	static weapon
	weapon = AMMOWEAPON[type]
	
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// Get ammo amount
	static amount
	amount = read_data(2)

	if (amount < MAXBPAMMO[weapon])
	{
		static args[1]
		args[0] = weapon
		set_task(0.1, "refill_bpammo", id, args, sizeof args)

	}
}

public eCurWeapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return;

	if(cs_get_user_team(id) == NC_TEAM /*&& read_data(2) == CSW_KNIFE*/)
		set_pev(id, pev_viewmodel2, NC_KNIFE)
}

public message_Scenario(msgid, dest, id)
{
	static szHud[50]
	get_msg_arg_string(1, szHud, charsmax(szHud))
	server_print(szHud)
	return ( equal(szHud, "hostage1") && get_msg_arg_int(1) == 1) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

/* ********************************************************************************************** */
/* ####################################### UNLIMITED CLIP AMMO ################################## */
/* ********************************************************************************************** */
public message_CurWeapon(msg_id, msg_dest, id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return;
		
	if( cs_get_user_team(id) != CS_TEAM_CT )
		return;
		
	// Player doesn't have the unlimited clip upgrade
	if ( !IsInBit(id, gUnlimited) )
		return;
	
	// Player not alive or not an active weapon
	if (!is_user_alive(id) || get_msg_arg_int(1) != 1)
		return;
	
	static weapon, clip
	weapon = get_msg_arg_int(2) // get weapon ID
	clip = get_msg_arg_int(3) // get weapon clip
	
	// Unlimited Clip Ammo
	if (MAXCLIP[weapon] > 2) // skip grenades
	{
		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon]) // HUD should show full clip all the time
		
		if (clip < 2) // refill when clip is nearly empty
		{
			// Get the weapon entity
			static wname[32], weapon_ent
			get_weaponname(weapon, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, id)
			
			// Set max clip on weapon
			fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		}
	}
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	
	return entity;
}

// Set Weapon Clip Ammo
stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}
/* ********************************************************************************************** */
/* ####################################### UNLIMITED CLIP AMMO ################################## */
/* ********************************************************************************************** */

new const CT_MODELS[][] = {
	"gign",
	"sas",
	"gsg9",
	"urban"
}

public Fwd_PlayerSpawn(id)
{
	if(!is_user_alive(id))
		return;
	
	switch(cs_get_user_team(id))
	{
		case NC_TEAM:
		{
			g_iUserGamma[id][GAMMA_AMOUNT] = 150
			g_iVisible[id] = false
			
			strip_user_weapons(id)
			give_item(id, "weapon_knife")
			
			set_user_gravity(id, float(CVARS[GRAVITY]) / get_pcvar_float(g_pGravity))
			set_user_health(id, CVARS[HEALTH])
			set_user_footsteps(id, 1)
			set_user_maxspeed(id, float(CVARS[SPEED]))
			
			ColorChat(id, BLUE, "%s ^4You are invisible now.", PREFIX)
			
			cs_set_user_model(id, NC_MODEL)
			
			set_task(0.5, "ShowHud", TASK_HUD + id, .flags ="b")
		}
		
		default:
		{
			g_iVisible[id] = true
			cs_set_user_model(id, CT_MODELS[random_num(0, 3)])
		}
	}		
}

public Fwd_Impulse(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	if(pev(id, pev_impulse) == 100)
	{
		new CsTeams:iTeam = cs_get_user_team(id)
		if( iTeam == NC_TEAM )
		{
			if(g_iUserGamma[id][GAMMA_AMOUNT] < CVARS[TELEPORT_COST])		// TELEPORT
				return HAM_SUPERCEDE

			if(Teleport(id))
				g_iUserGamma[id][GAMMA_AMOUNT] -= CVARS[TELEPORT_COST]
			
			return HAM_SUPERCEDE
		}
		
		if( iTeam == CS_TEAM_CT && IsInBit(id, gExplosion) )		// EXPLOSION
		{
			Explode(id)
			RemoveFromBit(id, gExplosion)
			
			return HAM_SUPERCEDE
		}
	}
	return HAM_IGNORED
}

#define MAX_DISTANCE	8092.0
#define START_DISTANCE  32   // --| The first search distance for finding a free location in the map.
#define MAX_ATTEMPTS    128  // --| How many times to search in an area for a free

stock Teleport(iPlayer)
{
	new Float: vOrigin[ 3 ], Float: vViewOfs[ 3 ], Float: vAngles[ 3 ], Float: vVector[ 3 ]; 
	pev( iPlayer, pev_origin, vOrigin ); 
	pev( iPlayer, pev_view_ofs, vViewOfs ); 
	pev( iPlayer, pev_v_angle, vAngles ); 
	
	vOrigin[ 0 ] = vOrigin[ 0 ] + vViewOfs[ 0 ]; 
	vOrigin[ 1 ] = vOrigin[ 1 ] + vViewOfs[ 1 ]; 
	vOrigin[ 2 ] = vOrigin[ 2 ] + vViewOfs[ 2 ]; 
	
	angle_vector( vAngles, ANGLEVECTOR_FORWARD, vVector ); 
	
	vVector[ 0 ] = vVector[ 0 ] * MAX_DISTANCE + vOrigin[ 0 ]; 
	vVector[ 1 ] = vVector[ 1 ] * MAX_DISTANCE + vOrigin[ 1 ]; 
	vVector[ 2 ] = vVector[ 2 ] * MAX_DISTANCE + vOrigin[ 2 ]; 
	
	new pTr = create_tr2( ); 
	engfunc( EngFunc_TraceLine, vOrigin, vVector, IGNORE_MONSTERS, iPlayer, pTr ); 
	
	new Float: flFraction; 
	get_tr2( pTr, TR_flFraction, flFraction ); 
	
	if( flFraction < 1.0 ) 
	{ 
		new iEntityHit; 
		get_tr2( pTr, TR_pHit, iEntityHit ); 
		
		if( iEntityHit == 0 ) 
		{ 
			new Float: vEndPos[ 3 ]; 
			get_tr2( pTr, TR_vecEndPos, vEndPos ); 
			
			//if( point_contents( vEndPos ) == CONTENTS_SKY ) 
			//	return 0
	
			new Float: vPlane[ 3 ]; 
			get_tr2( pTr, TR_vecPlaneNormal, vPlane ); 
			
			vEndPos[ 0 ] = vEndPos[ 0 ] + vPlane[ 0 ] * 40.0; 
			vEndPos[ 1 ] = vEndPos[ 1 ] + vPlane[ 1 ] * 40.0; 
			vEndPos[ 2 ] = vEndPos[ 2 ] + vPlane[ 2 ] * 40.0; 
			
			//entity_set_vector(iPlayer, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } )
			engfunc(EngFunc_SetOrigin, iPlayer, vEndPos ); 
			UTIL_UnstickPlayer(iPlayer, START_DISTANCE, MAX_ATTEMPTS)
			
			//return 1
		} 
	} 
	
	free_tr2( pTr ); 
	return 0
}

stock bool:is_user_stuck(Id, &hull)
{
        static Float:Origin[3]
        pev(Id, pev_origin, Origin)
        engfunc(EngFunc_TraceHull, Origin, Origin, IGNORE_MONSTERS, pev(Id, pev_flags) & FL_DUCKING ? (hull = HULL_HEAD) : (hull = HULL_HUMAN), 0, 0)
        if (get_tr2(0, TR_StartSolid))
                return true
        
        return false
}

enum Coord_e { Float:x, Float:y, Float:z };

stock UTIL_UnstickPlayer (const id, const i_StartDistance, const i_MaxAttempts)
{
	// --| Not alive, ignore.
	if ( !is_user_alive ( id ) )  return -1
	
	new hull
	if(!is_user_stuck(id, hull))
		return -1
	
	static Float:vf_OriginalOrigin[ Coord_e ], Float:vf_NewOrigin[ Coord_e ];
	static i_Attempts, i_Distance;
	
	// --| Get the current player's origin.
	pev ( id, pev_origin, vf_OriginalOrigin );
	
	i_Distance = i_StartDistance;
	
	while ( i_Distance < 1000 )
	{
		i_Attempts = i_MaxAttempts;
		
		while ( i_Attempts-- )
		{
			vf_NewOrigin[ x ] = random_float ( vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance );
			vf_NewOrigin[ y ] = random_float ( vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance );
			vf_NewOrigin[ z ] = random_float ( vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance );
			
			engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, hull, id, 0 );
			
			// --| Free space found.
			if ( get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) )
			{
				// --| Set the new origin .
				engfunc ( EngFunc_SetOrigin, id, vf_NewOrigin );
				return 1;
			}
		}
		
		i_Distance += i_StartDistance;
	}
	
	// --| Could not be found.
	return 0;
}    

Explode(id)
{
	if(!is_user_alive(id))
		return;
		
	new iOrigin[3]
	get_user_origin(id, iOrigin)
	user_kill(id, 1)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)	// TE_EXPLOSION
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_short(gExplosionSpirit)	// sprite index
	write_byte(1)	// scale in 0.1's
	write_byte(10)	// framerate
	write_byte(0)
	message_end()
	
	new id2 = -1

	while( ( id2 = engfunc(EngFunc_FindEntityInSphere, id2, iOrigin, get_pcvar_float(g_pRadius)) ) <= g_iMaxPlayers  && is_user_alive(id2) )
	{
		server_print("id2 : %d", id2)
		if( cs_get_user_team(id2) == NC_TEAM )
		{
			Kill(id, id2)
		}
	}
}

Kill(id, id2)
{
	static iDthMsgId
	
	if(!iDthMsgId)
		iDthMsgId= get_user_msgid("DeathMsg")
	
	user_silentkill(id2)
	
	message_begin(MSG_ALL, iDthMsgId,_, id)
	write_byte(id)
	write_byte(id2)
	write_byte(1)
	write_string("worldspawn")
	message_end()
}

public ShowHud(TaskId)
{
	new id = TaskId - TASK_HUD
	
	if(!is_user_alive(id) || cs_get_user_team(id) != NC_TEAM)
		return remove_task(TaskId)
		
	set_hudmessage(0, 100, 200, -1.0, 0.75, 0, 0.0, 0.5)
	show_hudmessage(id, "Gamma: %d/%d", g_iUserGamma[id][GAMMA_AMOUNT], CVARS[GAMMA])
	
	return 1
}

public frostnades_player_chilled( victim, attacker )
{
	if(cs_get_user_team(victim) == NC_TEAM)
	{
		g_iVisible[victim] = 1
		set_task(3.5, "set_back", victim)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
