#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <xs>
#include <engine>
#include <colorchat>

new const VERSION[] = "1.0"
new const PREFIX[] = "[NightCrawler]"

// CVARS
//#define GAMMA_ADD	1.5
#define GAMMA_ADD	( random_num(1, 3) )
#define GAMMA_DELAY	2

#define EXPLOSION_RADIUS	300.0
#define EXPLOSION_DAMAGE	450.0

// MINES
#define MINE_CLASSNAME		"lasermine"

#define MINE_PLANT_TIME		3
#define MINE_POWERUP_TIME 	2.5

#define MINE_VEC_ENDPOS		pev_vuser2
#define MINE_POWERUP_PEV	pev_iuser2

#define MINE_POWERUP_SOUND	"sound/weapons/mine_charge.wav"
#define MINE_POWERUP_SOUND	"sound/weapons/mine_charge.wav"

#define MINE_MODEL		"models/v_tripmine.mdl"

#define MINE_COUNT		2
#define MINE_HEALTH		500


#define SUICIDE_TIME	4

#define CT_RATIO	3
#define NC_TEAM		CS_TEAM_T
#define HUMAN_TEAM	CS_TEAM_CT

// TASKS
#define TASK_HUD	28917
#define TASK_INVIS	18736
#define TASK_SUICIDE	92712

// TELEPORT
#define MAX_DISTANCE	8092.0
#define START_DISTANCE  32   // --| The first search distance for finding a free location in the map.
#define MAX_ATTEMPTS    128  // --| How many times to search in an area for a free

// OFFSETS
#define MAPZONE_BUY (1<<0)
#define OFFSET_MAPZONES 235

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

new const CT_MODELS[][] = {
	"gign",
	"sas",
	"gsg9",
	"urban"
}

// CVARS
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

// SHOP
enum _:ITEMDATAS {
	ITEMNAME[32],
	COST
}

enum
{
	EXPLOSION,	// Done
	FROST,		// Done.
	//FIRE,
	UNLIMITED,	// Done
	LASERMINE,
	LASERSIGHT
}

new const _:ITEMS[][ITEMDATAS] = {
	{ "Explosion", 8 },
	{ "Frost grenade", 5 },
	//{ "Fire grenade", 3 },
	{ "UnlimitedClip", 10 },
	{ "LaserMine",	0 },
	{ "Laser Sight", 0 }
}

// GAMMA STUFF
enum
{
	GAMMA_AMOUNT,
	GAMMA_LASTGAIN
}

new g_iUserGamma[33][2]

// MODELS
new NC_MODEL[] = "nightcrawler"
new NC_KNIFE[] = "models/nightcrawler/v_nightcrawler.mdl"
new const g_szSuicideBombSound[ ] = "weapons/c4_beep4.wav"

new g_iUserPoints[33], g_iVisible[33] = 1, g_iSuicideTime[33], 
g_iLaser
new g_iMines[33], g_iIsInPlant[33]

// wall origin
new Float:g_flWallOrigin[33][3]

// CVARS
new g_pGravity

// Sprite
new gExplosionSprite

// MessageId
new g_msgAmmoPickup, gMsgIdBarTime

// OTHERS
#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

// Macros
new g_iMaxPlayers
#define		IsPlayer(%1)		( 1 <= %1 <= g_iMaxPlayers )

// BITS
new gUnlimited, gExplosion

// MACROS
#define IsInBit(%1,%2)		( %2 &  (1<<%1)  )
#define InsertToBit(%1,%2)	( %2 |= (1<<%1)  )
#define RemoveFromBit(%1,%2)	( %2 &= ~(1<<%1) )

new const TELEPORT_SOUND[] = "nightcrawlers/teleport.wav"

public plugin_precache()
{
	precache_sound(TELEPORT_SOUND)
	precache_model(MINE_MODEL)
	
	new szFile[70]
	formatex(szFile, charsmax(szFile), "models/player/%s/%s.mdl", NC_MODEL, NC_MODEL)
	precache_model(szFile)
	precache_model(NC_KNIFE)
	
	gExplosionSprite = precache_model("sprites/zerogxplode.spr")
	
	// Round end ... 
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
	
	if (pev_valid(iEnt))
	{
		engfunc(EngFunc_SetOrigin, iEnt, Float:{ 8192.0,8192.0,8192.0 } )
		set_pev(iEnt, pev_solid, SOLID_NOT)
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha)
		set_pev(iEnt, pev_renderfx, kRenderFxNone)
		set_pev(iEnt, pev_renderamt, 255.0)
	}
	
	iEnt = -1
	find_ent_by_class(iEnt, "info_map_parameters")
	
	if(iEnt <= 0)
		iEnt = create_entity("info_map_parameters")
	
	DispatchKeyValue(iEnt,"buying","3") // 3 = nobody can buy, 1 = Ts CAN'T buy, 2 = CTs CAN'T buy, 0 = everybody can buy
	DispatchSpawn(iEnt)
}

stock RemoveBombSites()
{
	new iEnt = -1
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "func_bomb_target")) > 0 )
	{
		set_pev(iEnt, pev_classname, "_func_bomb_target")
	}
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "info_bomb_target")) > 0 )
	{
		set_pev(iEnt, pev_classname, "_info_bomb_target")
	}
	
	set_cvar_num("sv_restart", 1)
}  
	
public plugin_init()
{	
	register_plugin("NightCrawler Mod", VERSION, "Khalid :)")
	
	RemoveBombSites()
	
	register_clcmd("say /help", "ShowHelpMotd")
	register_clcmd("say /shop", "ShowShopMenu")
	
	register_clcmd("say /points", "GivePoints")
	register_clcmd("say /gamma",  "GiveGamma")
	register_clcmd("say /mine", "GiveMine")
	
	register_event("CurWeapon", "eCurWeapon", "b", "1=1", "2=29")
	//register_event("DeathMsg", "eDeathMsg", "a")
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")
	register_event("AmmoX", "eAmmoX", "b")
	
	register_message(get_user_msgid("CurWeapon"), "message_CurWeapon")
	register_message(get_user_msgid("Scenario"), "message_Scenario")
	
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	gMsgIdBarTime = get_user_msgid("BarTime")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PostThink, "player", "fw_Think")
	RegisterHam(Ham_Player_ImpulseCommands, "player", "fw_Impulse", 0)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 0)
	
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1);
	
	new const WALLS[][] = {
		"func_wall",
		"func_breakable",
		"worldspawn"
	}
	
	for(new i; i < sizeof WALLS; i++)
		register_touch(WALLS[i], "player", "fw_TouchWall")
		
	register_think("lasermine", "fw_MineThink")
	
	g_iMaxPlayers = get_maxplayers()
	
	g_pGravity = get_cvar_pointer("sv_gravity")
}

public GiveMine(id)
{
	if(!g_iMines[id])
	{
		client_print(id, print_chat, "You have been given 2 laser mines")
		g_iMines[id] = 2
	}
}

public GiveGamma(id)
	g_iUserGamma[id][GAMMA_AMOUNT] = 999999

public GivePoints(id)
	g_iUserPoints[id] = 9999999

public fw_TouchWall(world, id)
{
	if(is_user_alive(id))
		pev(id, pev_origin, g_flWallOrigin[id])
}

public eNewRound()
{
	// Reset Shops
	gExplosion = 0
	gUnlimited = 0
}

public client_putinserver(id)
	g_iVisible[id] = 1
	// LOAD POINTS

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
		
		/*case	FIRE:
		{
			ColorChat(id, BLUE, "%s ^4You have bought Frost grenade", PREFIX)
			give_item(id, "weapon_hegrenade")
		}*/
		
		case	UNLIMITED:
		{
			ColorChat(id, BLUE, "%s ^4You have bought unlimited clip.", PREFIX)
			InsertToBit(id, gUnlimited)
		}
		
		case	LASERMINE:
		{
			
		}
	}
}

public fw_Think(id)
{
	if(!pev_valid(id) || !is_user_alive(id))
		return;
	
	static  CsTeams:iTeam, iButton, Float:vOrigin[3], Float:flGameTime
	if( ( iTeam = cs_get_user_team(id) ) == NC_TEAM)
	{
		if(( g_iUserGamma[id][GAMMA_AMOUNT] < CVARS[GAMMA] ) && ( (iButton = floatround( get_gametime() ) ) >= g_iUserGamma[id][GAMMA_LASTGAIN] ) )
			AddGamma(id, iButton)
		
		iButton = pev(id, pev_button)
	
		if( iButton & IN_USE )
		{
			pev( id, pev_origin, vOrigin );
		
			if( get_distance_f( vOrigin, g_flWallOrigin[ id ] ) > 10.0 )
				return;
		
			if( pev( id, pev_flags ) & FL_ONGROUND )
			{
				//ExecuteHam(Ham_Player_Jump, id)
				return;
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
	
	else if(iTeam == HUMAN_TEAM && g_iMines[id])
	{
		static iPlantTime; iPlantTime = g_iIsInPlant[id]
		// Start Planting
		iButton = pev(id, pev_button)
		
		if( !iPlantTime )
		{
			if( (iButton & IN_USE) && (pev(id, pev_oldbuttons) & IN_USE))
			{
				pev( id, pev_origin, vOrigin );
				if( get_distance_f( vOrigin, g_flWallOrigin[ id ] ) > 10.0 )
					return;
				
				server_print("started planting")
				start_plant_bar(id)
				g_iIsInPlant[id] = MINE_PLANT_TIME + floatround(get_gametime())
				return;
			}
		}
		
		else
		{
			pev( id, pev_origin, vOrigin );
			if(iPlantTime && get_distance_f( vOrigin, g_flWallOrigin[ id ] ) > 10.0 )
			{
				remove_plant_bar(id)
				g_iIsInPlant[id] = 0
				return;
			}
				
			// Stopped planting
			if( !(iButton & IN_USE) )
			{
				server_print("Stopped planting")
				remove_plant_bar(id)
				g_iIsInPlant[id] = 0
				return;
			}
			
			else if( floatround( ( flGameTime = get_gametime() ) ) >= iPlantTime )
			{
				server_print("Planted 1 mine")
				g_iIsInPlant[id] = 0
			
				static Float:vAimOrigin[3], Float:vAimAngles[3], Float:vNormal[3], Float:vTraceEnd[3]
				
				pev( id, pev_v_angle, vAimOrigin )
				
				xs_vec_mul_scalar(vAimOrigin, 9999.0, vAimOrigin)
				xs_vec_add(vAimOrigin, vOrigin, vAimOrigin)
		
				new iTr = create_tr2()
				engfunc( EngFunc_TraceLine, vOrigin, vAimOrigin, IGNORE_MONSTERS, id, iTr )
				
				get_tr2(iTr, TR_vecEndPos, vTraceEnd)
				server_print("[vTraceEnd] x: %f ** y: %f ** z: %f", vTraceEnd[0], vTraceEnd[1], vTraceEnd[2])
				
				get_tr2(iTr, TR_vecPlaneNormal, vNormal)
				server_print("[vNormal] x: %f ** y: %f ** z: %f", vNormal[0], vNormal[1], vNormal[2])
				
				free_tr2(iTr)
				
				vector_to_angle(vNormal, vAimAngles)
				
				//xs_vec_mul_scalar( vNormal, 8.0, vNormal)
				
				server_print("x: %f ** y: %f ** z: %f", vOrigin[0], vOrigin[1], vOrigin[2])
				
				new iEnt = create_entity("info_target")
				
				if(pev_valid(iEnt))
				{
					
					set_pev(iEnt, pev_classname, MINE_CLASSNAME)
					set_pev(iEnt, pev_owner, id)
					set_pev(iEnt, pev_health, MINE_HEALTH)
					set_pev(iEnt, pev_angles, vAimAngles)
					set_pev(iEnt, pev_origin, vOrigin)
					set_pev(iEnt, pev_takedamage, DAMAGE_YES)
					set_pev(iEnt, pev_sequence, 7)
					set_pev(iEnt, pev_body, 3);
					set_pev(iEnt, pev_framerate, 0);
					set_pev(iEnt, pev_frame, 0)
					set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
					set_pev(iEnt, pev_solid, SOLID_BBOX);
					
					engfunc(EngFunc_SetOrigin, iEnt, vOrigin)
					engfunc(EngFunc_SetSize, iEnt, Float:{ -4.0, -4.0, -4.0 }, Float:{ 4.0, 4.0, 4.0 } );
					engfunc(EngFunc_SetModel, iEnt, MINE_MODEL)
				
					set_pev(iEnt, pev_nextthink, flGameTime + MINE_POWERUP_TIME)
					PlaySound(iEnt, MINE_POWERUP_SOUND)
					
					g_iMines[id]--
				}
			}
			
			 // First think
		}
	}
}

public fw_MineThink(iEnt)
{
	set_pev(iEnt, pev_solid, SOLID_BBOX);
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
}

start_plant_bar(id)
{
	message_begin(MSG_ONE, gMsgIdBarTime,_, id)
	write_short(MINE_PLANT_TIME)
	message_end()
	
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "bch")
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		if(pev(iPlayer, pev_iuser2) == id && pev(iPlayer, pev_iuser1) == 4)
		{
			message_begin(MSG_ONE, gMsgIdBarTime,_, iPlayers[i])
			write_short(MINE_PLANT_TIME)
			message_end()
		}
	}
}

remove_plant_bar(id)
{
	message_begin(MSG_ONE, gMsgIdBarTime,_, id)
	write_short(0)
	message_end()
	
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "bch")
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		if(pev(iPlayer, pev_iuser2) == id /* && pev(iPlayer, pev_iuser1) == 4*/)
		{
			message_begin(MSG_ONE, gMsgIdBarTime,_, iPlayers[i])
			write_short(0)
			message_end()
		}
	}
}

PlaySound(iEnt, const szSound[])
{
	emit_sound(iEnt, CHAN_ITEM, szSound, VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
}

AddGamma(id, iGameTime)
{
	g_iUserGamma[id][GAMMA_LASTGAIN] = iGameTime + GAMMA_DELAY
	
	new iGammaAmount = CVARS[GAMMA]
	if(g_iUserGamma[id][GAMMA_AMOUNT] + GAMMA_ADD > iGammaAmount)
		g_iUserGamma[id][GAMMA_AMOUNT] = iGammaAmount
	
	else	g_iUserGamma[id][GAMMA_AMOUNT] += GAMMA_ADD
}

public fw_TakeDamage(id, idinflictor, iAttacker)
{
	if( /*IsPlayer(id) &&*/ cs_get_user_team(id) == NC_TEAM)
	{
		if( !IsPlayer(iAttacker) )	// Falled ..
			return HAM_SUPERCEDE
	
		if(IsPlayer(iAttacker) )
		{
			g_iVisible[id] = 1
			
			new iNum = TASK_INVIS + id
			if(task_exists(iNum))
				remove_task(iNum)
				
			set_task(3.0, "set_back", iNum)
		}
	}
	return HAM_IGNORED
}

public fw_AddToFullPack_Post( es, e, iEntity, iHost, iHostFlags, iPlayer, pSet )
{
	if( is_user_alive( iEntity ) && is_user_alive( iHost ) && cs_get_user_team( iEntity ) == NC_TEAM && cs_get_user_team( iHost ) == HUMAN_TEAM )
	{
		set_es( es, ES_RenderMode, kRenderTransAdd );
			
		if( g_iVisible[ iEntity ] )
			set_es(es, ES_RenderAmt, 255);
			
		else set_es(es, ES_RenderAmt, 0);
	}
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
	get_msg_arg_string(2, szHud, charsmax(szHud))
	server_print(szHud)
	return ( ( equal(szHud, "hostage1") && get_msg_arg_int(1) == 1 ) ?  PLUGIN_HANDLED : PLUGIN_CONTINUE )
}

/* ********************************************************************************************** */
/* ####################################### UNLIMITED CLIP AMMO ################################## */
/* ********************************************************************************************** */
public message_CurWeapon(msg_id, msg_dest, id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return;
		
	if( cs_get_user_team(id) != HUMAN_TEAM )
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

public fw_PlayerSpawn(id)
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

public fw_Impulse(id)
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
			{
				g_iUserGamma[id][GAMMA_AMOUNT] -= CVARS[TELEPORT_COST]
			}
			
			else
			{
				ColorChat(id, BLUE, "%s You were slayed as you were stuck because of the teleport", PREFIX)
				user_kill(id)
			}
			
			return HAM_SUPERCEDE
		}
		
		if( iTeam == HUMAN_TEAM && IsInBit(id, gExplosion) )		// EXPLOSION
		{
			RemoveFromBit(id, gExplosion)
			
			g_iSuicideTime[id] = SUICIDE_TIME
			id += TASK_SUICIDE
			Suicide(id)
			
			set_task(float(SUICIDE_TIME), "Suicide", id, .flags = "b")
		
			return HAM_SUPERCEDE
		}
		
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

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
		//new iEntityHit; 
		//get_tr2( pTr, TR_pHit, iEntityHit ); 
		
		//if( iEntityHit == 0 ) 
		//{ 
		new Float: vEndPos[ 3 ]; 
		get_tr2( pTr, TR_vecEndPos, vEndPos ); 
			
		//if( point_contents( vEndPos ) == CONTENTS_SKY ) 
			//return 0
	
		new Float: vPlane[ 3 ]; 
		get_tr2( pTr, TR_vecPlaneNormal, vPlane ); 
			
		vEndPos[ 0 ] = vEndPos[ 0 ] + vPlane[ 0 ] * 40.0; 
		vEndPos[ 1 ] = vEndPos[ 1 ] + vPlane[ 1 ] * 40.0; 
		vEndPos[ 2 ] = vEndPos[ 2 ] + vPlane[ 2 ] * 40.0; 
			
		entity_set_vector(iPlayer, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } )
		
		PlaySound(iPlayer, TELEPORT_SOUND)
		
		engfunc(EngFunc_SetOrigin, iPlayer, vEndPos ); 
		
		return UTIL_UnstickPlayer(iPlayer, START_DISTANCE, MAX_ATTEMPTS)
		//{
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

enum Coord_e 
{ 
	Float:x, 
	Float:y, 
	Float:z
};

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

public Suicide( iTaskID )
{
	static id; id = iTaskID - TASK_SUICIDE;

	if( --g_iSuicideTime[ id ] == 0 )
	{
		remove_task(iTaskID)
		
		new Float:flOrigin[ 3 ];
		pev( id, pev_origin, flOrigin );
		
		user_kill( id );
		
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_EXPLOSION );
		write_coord( floatround( flOrigin[ 0 ] ) );
		write_coord( floatround( flOrigin[ 1 ] ) );
		write_coord( floatround( flOrigin[ 2 ] ) );
		write_short( gExplosionSprite );
		write_byte( 30 );
		write_byte( 30 );
		write_byte( 0 );
		message_end();
			
		HamRadiusDamage(id, flOrigin, EXPLOSION_RADIUS, EXPLOSION_DAMAGE)
		
	}
		else emit_sound( id, CHAN_ITEM, g_szSuicideBombSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}

stock HamRadiusDamage(ent, Float:origin[3], Float:radius, Float:damage)  
{   
	static Float:o[3], target
	while(( target = find_ent_in_sphere(target, origin, radius) ))  
	{
		pev(target, pev_origin, o)  
          
		xs_vec_sub(origin, o, o)  
          
		// Recheck if the entity is in radius  
		if (xs_vec_len(o) > radius)  
			continue  
          
		ExecuteHam(Ham_TakeDamage, target, 0, ent, damage * (xs_vec_len(o) / radius), DMG_GENERIC)  
	}  
}  

// TASKS
public ShowHud(TaskId)
{
	new id = TaskId - TASK_HUD
	
	if(!is_user_alive(id) || cs_get_user_team(id) != NC_TEAM)
		return remove_task(TaskId)
		
	set_hudmessage(0, 100, 200, -1.0, 0.75, 0, 0.0, 0.5)
	show_hudmessage(id, "Gamma: %d/%d", g_iUserGamma[id][GAMMA_AMOUNT], CVARS[GAMMA])
	
	return 1
}

public set_back(taskid)
{
	new id = taskid - TASK_INVIS
	g_iVisible[id] = 0
}


// FORWARDS
public frostnades_player_chilled( victim, attacker )
{
	if(cs_get_user_team(victim) == NC_TEAM)
	{
		g_iVisible[victim] = 1
		set_task(3.5, "set_back", victim)
	}
}

/*get_highest_killer()
{
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "bch", "CT")
	
	new iFrags, id, iTemp, iPlayer
	
	new iDraw

	for(new i;  i < iNum;i ++)
	{
		iPlayer = iPlayers[i]
		if( ( iTemp = get_user_frags(iPlayer) ) > iFrags)
		{
			iFrags = iTemp;
			id = iPlayer;
		}
	}
	
	return id
}*/
		
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
