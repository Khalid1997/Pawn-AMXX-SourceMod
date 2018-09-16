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
#define FOG

#define NC_LIGHTS "c"

#define MAX_MINE_HOLDERS 2
#define MAX_LASER_SIGHT_HOLDERS 1

//#define GAMMA_ADD	1.5
#define GAMMA_ADD	( random_num(1, 3) )
#define GAMMA_DELAY	2

#define SUICIDE_TIME		5
#define EXPLOSION_RADIUS	300.0
#define EXPLOSION_DAMAGE	450.0

#define ADRENALINE_TIME		13
#define ADRENALINE_SPEED	280.0

// MINES
#define MINE_CLASSNAME		"lasermine"

#define MINE_PLANT_TIME		2
#define MINE_POWERUP_TIME 	2.5

#define MINE_VEC_ENDPOS		pev_vuser2
#define MINE_POWERUP_PEV	pev_iuser2

#define MINE_POWERUP_SOUND	"weapons/mine_charge.wav"
#define MINE_NC_NOTIFY		"nightcrawlers/sonic_sound.wav"
#define MINE_ACTIVATE_SOUND	"weapons/mine_activate.wav"

#define MINE_MODEL		"models/v_tripmine.mdl"

#define MINE_GIVE_AMOUNT 	2
#define MINE_HEALTH		500

// Teams and ratio
#define HUMAN_TO_NC_RATIO		3
#define NC_TEAM			CS_TEAM_T
#define HUMAN_TEAM		CS_TEAM_CT

#define VISIBLE_TIME		2.7

// TASKS
enum _:TASKS (+= 124)
{
	TASK_HUD = 	912,
	TASK_INVIS,
	TASK_SUICIDE
}

// TELEPORT
#define MAX_DISTANCE	8092.0
#define START_DISTANCE  32   // --| The first search distance for finding a free location in the map.
#define MAX_ATTEMPTS    128  // --| How many times to search in an area for a free

// OFFSETS
#define MAPZONE_BUY		(1<<0)
#define OFFSET_MAPZONES		235
#define OFFSET_PRIMARYWEAPON	116 

#define Ham_ResetPlayerMaxSpeed Ham_Item_PreFrame
#define THINK_ENT "ThinkingEnt"

// MACROS
#define IsInBit(%1,%2)		( %2 &  (1<<%1)  )
#define InsertToBit(%1,%2)	( %2 |= (1<<%1)  )
#define RemoveFromBit(%1,%2)	( %2 &= ~(1<<%1) )

#define	IsPlayer(%1)		( 1 <= %1 <= g_iMaxPlayers )

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
	ARMOR,
	SPEED,
	GRAVITY,
	GAMMA,
	TELEPORT_COST
}

new CVARS[NC_] = {
	150,
	100,
	250,
	400,
	150,
	50
}

// SHOP
enum
{
	LASER,		// DONE
	MINE,		// Done
	EXPLOSION,	// Done
	FROST,		// Done.
	//FIRE,
	ADRENALINE	// Done
}

new const ITEMS[][] = {
	"Laser Sight",
	"LaserMine",
	"Explosion" ,
	"Frost grenade" ,
	//"Fire grenade",
	"Adrenaline \y(\wUnlimited clip + Speed\y)"
}

// GAMMA STUFF
enum
{
	GAMMA_AMOUNT,
	GAMMA_LASTGAIN
}

enum Coord_e 
{ 
	Float:x, 
	Float:y, 
	Float:z
};

new g_iUserGamma[33][2], g_iUserPoints[33]

new g_iVisible[33] = 1
// Items
new g_iSuicideTime[33], g_iLaser[33], g_iLaserCount,
g_iMines[33], g_iMinesCount
new Float:g_flIsInPlant[33]

new Float:g_flWallOrigin[33][3]

enum _:WEAPONS
{
	MAIN,
	PRIM = 1,
	SEC
}

enum
{
	NC_MENU =1,
	ABILITY,
	
	
	ADMIN_MENUS
}
new g_iAdminMenu[ADMIN_MENUS]
new g_iSelectedItem[33], g_iPlayerMenu[33]

// Menus
new g_iItemMenu, g_iWeaponMenu[WEAPONS]
new g_iLastWeapons[33], g_iItemCount
new g_iChooseTeamMenu[33]

new g_iWasNc[33], g_iNcNextRound[33]

// CVARS
new g_pGravity

// Sprite
new gExplosionSprite, beampoint

// MessageId
new g_msgAmmoPickup, gMsgIdBarTime, gMsgIdStatusText

// OTHERS
new Trie:gKnifeSounds, Trie:gDeathSounds
new gSyncHud
new g_iMaxPlayers

#if cellbits == 32
new const OFFSET_CLIPAMMO = 51
#else
new const OFFSET_CLIPAMMO = 65
#endif
new const OFFSET_LINUX_WEAPONS = 4

// BITS
new gAdrenaline, gExplosion, gCanHaveLaser, gHasChoosed, gHasAdrenaline, gHasChoosedWeapons,
gSave, gFirstJoin, gCanJoinTeam, gFakeTeam

new g_iSpec[33]

// MODELS
new NC_MODEL[] = "nightcrawler"
new NC_KNIFE[] = "models/nightcrawler/v_nightcrawler.mdl"

new const TELEPORT_SOUND[] = "nightcrawlers/teleport.wav"
new const ADRENALINE_SOUND[] = "nightcrawlers/adrenaline_shot.wav"

new const PAIN_SOUND[] = "nightcrawlers/pain.wav"

new const g_szSuicideBombSound[][] = {
	"",
	"weapons/c4_beep5.wav",
	"weapons/c4_beep4.wav",
	"weapons/c4_beep3.wav",
	"weapons/c4_beep2.wav",
	"weapons/c4_beep1.wav"
}

new const g_szHumanWinSounds[][] = {
	"nightcrawlers/humans_win3.wav",
	"nightcrawlers/humans_win4.wav"
}


new const g_szKnifeSounds[][] = {
	// Knife slashes player
	"weapons/knife_hit1.wav",
	"weapons/knife_hit2.wav",
	"weapons/knife_hit3.wav",
	"weapons/knife_hit4.wav",
	
	// Knife slashes or stabs wall
	"weapons/knife_hitwall1.wav",
	
	// Knife (1 = slash, 2 = stab) air
	//"weapons/knife_slash1.wav",
	//"weapons/knife_slash2.wav",
	
	// Knife stabs player
	"weapons/knife_stab.wav"
}

new const g_szNewKnifeSounds[sizeof(g_szKnifeSounds)][] = {
	// Knife slashes player
	"nightcrawlers/sword_strike1.wav",
	"nightcrawlers/sword_strike1.wav",
	"nightcrawlers/sword_strike1.wav",
	"nightcrawlers/sword_strike1.wav",
	
	// Knife slashes or stabs wall
	"nightcrawlers/sword_strike2.wav",
	
	// Knife (1 = slash, 2 = stab) air
	//"",
	//"",
	
	"nightcrawlers/sword_strike4.wav"
}

new const g_szDeathSounds[][] =
{
	"player/death6.wav",
	"player/die1.wav",
	"player/die2.wav",
	"player/die3.wav"
};

new const g_szNewDeathSounds[][] =
{
	"nightcrawlers/nc_death1.wav",
	"nightcrawlers/nc_death2.wav",
	"nightcrawlers/nc_death3.wav"
};

new const g_szNewCTWinMessage[] = "Humans have won"
new const g_szNewTWinMessage[] = "NightCrawlers won"

public plugin_precache()
{	
	beampoint = precache_model("sprites/laserbeam.spr")
	
	precache_sound(TELEPORT_SOUND)
	precache_model(MINE_MODEL)
	precache_sound(MINE_POWERUP_SOUND)
	precache_sound(MINE_NC_NOTIFY)
	precache_sound(MINE_ACTIVATE_SOUND)
	
	precache_sound(PAIN_SOUND)
	precache_sound(ADRENALINE_SOUND)
	
	for(new i = 1; i < sizeof(g_szSuicideBombSound); i++)
	{
		precache_sound(g_szSuicideBombSound[i])
	}
	
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
	iEnt = find_ent_by_class(iEnt, "info_map_parameters")
	
	if(iEnt <= 0)
		iEnt = create_entity("info_map_parameters")
	
	DispatchKeyValue(iEnt,"buying","3") // 3 = nobody can buy, 1 = Ts CAN'T buy, 2 = CTs CAN'T buy, 0 = everybody can buy
	DispatchSpawn(iEnt)
	
	gKnifeSounds = TrieCreate()
	gDeathSounds = TrieCreate()
	
	for(new i; i < sizeof(g_szNewKnifeSounds); i++)
	{
		TrieSetCell(gKnifeSounds, g_szKnifeSounds[i], i)
		
		precache_sound(g_szNewKnifeSounds[i])
	}
	
	for(new i; i < sizeof(g_szNewDeathSounds); i++)
	{
		TrieSetCell(gDeathSounds, g_szDeathSounds[i], i)
		
		precache_sound(g_szNewDeathSounds[i])
	}
	
}

stock RemoveMapObjectives()
{
	new const szMapObjectives[][] =
	{
		"func_bomb_target",
		"info_bomb_target",
		//"hostage_entity",
		"monster_scientist",
		"func_hostage_rescue",
		"info_hostage_rescue",
		"info_vip_start",
		"func_vip_safetyzone",
		"func_escapezone",
		"armoury_entity",
		//"info_map_parameters",
		"player_weaponstrip",
		"game_player_equip",
		"func_buyzone"
	}
	
	new iEnt
	for(new i; i < sizeof(szMapObjectives); i++)
	{
		iEnt = -1
		while( ( iEnt = find_ent_by_class(iEnt, szMapObjectives[i]) ) )
		{
			remove_entity(iEnt)
		}
	}
	
	set_cvar_num("sv_restart", 1)
}  

public plugin_init()
{	
	RemoveMapObjectives()
	
	register_plugin("NightCrawler Mod", VERSION, "Khalid :)")
	
	register_clcmd("say /guns", "EnableGuns")
	register_clcmd("say guns", "EnableGuns")
	register_clcmd("say /help", "ShowHelpMotd")
	
	register_clcmd("chooseteam", "ShowMenu")
	register_clcmd("jointeam", "Block")
	register_clcmd("joinclass", "Block")
	
	//register_clcmd("say /points", "GivePoints")
	//register_clcmd("say /gamma",  "GiveGamma")
	//register_clcmd("say /mine", "GiveMine")
	
	register_event("CurWeapon", "eCurWeapon", "b", "1=1", "2=29")
	//register_event("DeathMsg", "eDeathMsg", "a")
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")
	register_event("AmmoX", "eAmmoX", "b")
	
	register_message(get_user_msgid("CurWeapon"), "message_CurWeapon")
	register_message(get_user_msgid("Scenario"), "message_Scenario")
	register_message(get_user_msgid("SendAudio"), "message_SendAudio")
	register_message(get_user_msgid("TextMsg"), "message_TextMsg")
	
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu")
	register_message(get_user_msgid("VGUIMenu"), "message_VGUIMenu")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PostThink, "player", "fw_Think", 1)
	RegisterHam(Ham_Player_ImpulseCommands, "player", "fw_Impulse", 0)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 0)
	RegisterHam(Ham_Killed, "player", "fw_Killed", 1)
	RegisterHam(Ham_ResetPlayerMaxSpeed, "player", "fw_SetMaxSpeed", 1)
	
	// Mine take damage
	//RegisterHam(Ham_TakeDamage, "info_target", "fw_MineTakeDamage", 1)
	
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_forward(FM_ClientKill, "fw_ClientKill", 0)
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	new const WALLS[][] = {
		"func_wall",
		"func_breakable",
		"worldspawn"
	}
	
	for(new i; i < sizeof WALLS; i++)
		register_touch(WALLS[i], "player", "fw_TouchWall")
	
	register_touch("weaponbox", "player", "fw_TouchWeapon")
	register_touch("armoury_entity", "player", "fw_TouchWeapon")
	
	register_think(MINE_CLASSNAME, "fw_MineThink")
	
	g_iMaxPlayers = get_maxplayers()
	
	// --| Cvars
	g_pGravity = get_cvar_pointer("sv_gravity")
	
	// --| CallBacks
	new iCallBack = menu_makecallback("CallBack")
	
	// --| Messages IDs
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	gMsgIdBarTime = get_user_msgid("BarTime")
	gMsgIdStatusText = get_user_msgid("StatusText")
	
	gSyncHud = CreateHudSyncObj()
	
	// --| Item Menu
	new szTitle[50]
	formatex(szTitle, charsmax(szTitle), "\r%s \wChoose an Item:", PREFIX)
	
	// ------------------- ITEM MENU --------------------------
	g_iItemMenu = menu_create(szTitle, "ItemMenuHandler")
	new iMenu = menu_create("Choose an item to give to a player", "ItemAdminMenuHandler")
	
	new iSize = sizeof(ITEMS)
	new szInfo[5]
	
	for(new i; i < iSize; i++)
	{
		formatex(szTitle, charsmax(szTitle), "%s", ITEMS[i])
		num_to_str(i, szInfo, charsmax(szInfo))
		
		menu_additem(g_iItemMenu, szTitle, szInfo, .callback = ( i == LASER || i == MINE ? iCallBack : -1 ) )
		menu_additem(iMenu, szTitle, szInfo)
		
		
		g_iItemCount++
	}
	
	g_iAdminMenu[ABILITY] = iMenu
	
	// ------------------- ADMIN MENU -------------------------
	formatex(szTitle, charsmax(szTitle), "\r%s \wAdmin Menu", PREFIX)
	iMenu = menu_create(szTitle, "MainAdminMenuHandler")
	
	menu_additem(iMenu, "Make a NightCrawler/Human", "1")
	menu_additem(iMenu, "Give an Item to a human", "2")
	
	g_iAdminMenu[MAIN] = iMenu
	
	// ------------------- WEAPON MENU ------------------------
	BuildWeaponMenus()
	
	// ------------------- Player Checker Entity --------------
	new iEnt = create_entity("info_target")
	
	set_pev(iEnt, pev_classname, THINK_ENT)
	
	register_think(THINK_ENT, "fw_PlayerCheck")
	set_pev(iEnt, pev_nextthink, get_gametime() + 5.0)
}

public client_connect(id)
{
	set_lights(NC_LIGHTS)
	
	g_iVisible[id] = 1
}


public client_putinserver(id)
{
#if defined FOG
	set_task(1.0, "MakeFog", id)
#endif
	InsertToBit(id, gFirstJoin)
}

public fw_PlayerCheck(iEnt)
{
	new iPlayers[32], iCTPlayers[32] ,iNum, iCTNum
	
	get_players(iCTPlayers, iCTNum, "che", "CT")
	get_players(iPlayers, iNum, "ch")
	
	if(iCTNum == iNum && iNum > 1)
	{
		ChooseNCPlayers(iPlayers, iNum, 1)
	}
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 5.0)
}

stock ChooseNCPlayers(iPlayers[32], iNum, Slay = 0)
{
	arrayset(g_iNcNextRound, 0, sizeof(g_iNcNextRound))
	static iTNum
	iTNum = floatround(Float:iNum / Float:(HUMAN_TO_NC_RATIO + 1))

	new n, iPlayer, numplayers, iHasChecked
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(Slay)
		{
			if(is_user_alive(iPlayer))
			{
				user_silentkill(iPlayer)
			}
		}
		
		if(cs_get_user_team(iPlayer) == NC_TEAM)
		{
			g_iWasNc[iPlayer] = 1
			cs_set_user_team(iPlayer, HUMAN_TEAM)
		}
	}
	
	while(n != iTNum && numplayers != iNum)
	{
		iPlayer = iPlayers[random(iNum)]
		
		if(IsInBit(iPlayer, iHasChecked))
		{
			continue;
		}
		
		numplayers++
		InsertToBit(iPlayer, iHasChecked)
		
		if(g_iWasNc[iPlayer])
		{
			continue;
		}
		
		g_iNcNextRound[iPlayer] = 1
		n++
	}
	
	if(n != iTNum)
	{
		iHasChecked = 0
		while(n != iTNum)
		{
			iPlayer = iPlayers[random(iNum)]
			
			if(IsInBit(iPlayer, iHasChecked))
			{
				continue;
			}
			
			InsertToBit(iPlayer, iHasChecked)
			
			if(g_iNcNextRound[iPlayer])
			{
				continue;
			}
			
			g_iNcNextRound[iPlayer]++
			n++
		}
	}
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(g_iNcNextRound[iPlayer])
		{
			g_iNcNextRound[iPlayer] = 0
			g_iWasNc[iPlayer] = 1
			cs_set_user_team(iPlayer, NC_TEAM)
		}
	}
}

public Block(id)
{
	// jointeam
	if(IsInBit(id, gCanJoinTeam))
	{
		RemoveFromBit(id, gCanJoinTeam)
		return PLUGIN_CONTINUE
	}
	
	// joinclass
	if(gCanJoinTeam & (2<<id))
	{
		gCanJoinTeam &= ~(2<<id)
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public message_VGUIMenu(msgid, dest, id)
{
	static const VGUI_CHOOSE_TEAM_MENU = 2
	if(get_msg_arg_int(id) == VGUI_CHOOSE_TEAM_MENU)
	{
		if(IsInBit(id, gFirstJoin))
		{
			RemoveFromBit(id, gFirstJoin)
			
			set_task(0.1, "JoinTeam", id)
		}
			
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public message_ShowMenu(msgid, dest, id)
{
	static const FIRST_JOIN_MSG[] =		"#Team_Select";
	static const FIRST_JOIN_MSG_SPEC[] =	"#Team_Select_Spect";
	static const INGAME_JOIN_MSG[] =		"#IG_Team_Select";
	static const INGAME_JOIN_MSG_SPEC[] =	"#IG_Team_Select_Spect";
	
	static szMenuCode[23];
	get_msg_arg_string(4, szMenuCode, charsmax(szMenuCode));
	
	if(equal(szMenuCode, "#CT_Select"))
	{
		set_pdata_int(id, 205, 0)
		return PLUGIN_HANDLED
	}
	
	if(equal(szMenuCode, "#Terrorist_Select"))
	{
		InsertToBit(id, gFakeTeam)
		gCanJoinTeam |= (2<<id)
		
		engclient_cmd(id, "joinclass", "1")
		
		return PLUGIN_HANDLED
	}
	
	if(equal(szMenuCode, FIRST_JOIN_MSG) || equal(szMenuCode, FIRST_JOIN_MSG_SPEC))
	{
		set_pdata_int(id, 205, 0)
		if(IsInBit(id, gFirstJoin))
		{
			RemoveFromBit(id, gFirstJoin)
		}
		
		set_task(0.1, "JoinTeam", id)
		
		return PLUGIN_HANDLED
	}
	
	// Just in case
	if(equal(szMenuCode, INGAME_JOIN_MSG) || equal(szMenuCode, INGAME_JOIN_MSG_SPEC))
	{
		set_pdata_int(id, 205, 0)
		set_task(0.1, "ShowMenu", id)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public JoinTeam(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	new szClass[3]
	formatex(szClass, charsmax(szClass), "%d", random_num(1, 4))
	
	InsertToBit(id, gCanJoinTeam)
	gCanJoinTeam |= (2<<id)
	
	#if HUMAN_TEAM == CS_TEAM_CT)
	engclient_cmd(id, "jointeam", "2")
	#else
	engclient_cmd(id, "jointeam", "1")
	#endif
	engclient_cmd(id, "joinclass", szClass)
}

public ShowMenu(id)
{
	if(g_iChooseTeamMenu[id])
	{
		menu_destroy(g_iChooseTeamMenu[id])
	}
	
	new iMenu = menu_create("\wNightCrawlers \yMod by^n\rKhalid :)", "ChooseTeamHandler")
	
	menu_additem(iMenu, IsInBit(id, gSave) ? "Re-Enable Guns Menu" :  "Choose Weapons", IsInBit(id, gSave) ? "1" : "2", (  (!IsInBit(id, gSave) && IsInBit(id, gHasChoosedWeapons)) || cs_get_user_team(id) == NC_TEAM ? (1<<26) : 0) )
	
	menu_additem(iMenu, "Shop Menu", "3")
	menu_additem(iMenu, ( g_iSpec[id] ? "Go to CTs" : "Go to Spectators" ), "4")
	menu_additem(iMenu, "Help^n", "5")

	menu_additem(iMenu, "Admin Menu", "6", ADMIN_RCON)
	
	//menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER)
	
	//menu_additem(iMenu, "Exit", "7")
	
	menu_display(id, iMenu)
	g_iChooseTeamMenu[id] = iMenu
	
	return PLUGIN_HANDLED
}

public ChooseTeamHandler(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu)
		g_iChooseTeamMenu[id] = 0
		
		return;
	}
	
	new szInfo[5], iDump
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo), .callback = iDump)
	
	menu_destroy(menu)
	g_iChooseTeamMenu[id] = 0
	
	switch(str_to_num(szInfo))
	{
		case 1:
		{
			EnableGuns(id)
		}
		
		case 2:
		{
			menu_display(id, g_iWeaponMenu[MAIN])
		}
		
		case 3:
		{
			ColorChat(id, BLUE, "%s ^4Under development", PREFIX)
		}
		
		case 4:
		{
			new iRounds = g_iSpec[id]
			if(iRounds)
			{
				if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
				{
					g_iSpec[id] = 0
					return;
				}
				
				if(g_iWasNc[id])
				{
					g_iWasNc[id] = 0
				}
				
				if(iRounds > 1)
				{
					g_iSpec[id] = 0
					cs_set_user_team(id, HUMAN_TEAM)
				
					ColorChat(id, BLUE, "%s ^4You have been transfered to Humans team", PREFIX)
				}
				
				else
				{
					ColorChat(id, BLUE, "%s ^4You must atleast wait 1 round until you can switch back", PREFIX)
				}
			}
			
			else
			{
				g_iSpec[id] = 1
				
				if(is_user_alive(id))
				{
					user_kill(id, 1)
				}
				
				cs_set_user_team(id, CS_TEAM_SPECTATOR)
				
				ColorChat(id, BLUE, "%s ^4You have been transfered to Spectator team", PREFIX)
			}
		}
		
		case 5:
		{
			ShowHelpMotd(id)
		}
		
		case 6:
		{
			menu_display(id, g_iAdminMenu[MAIN])
		}
	}
}

public MainAdminMenuHandler(id, menu, item)
{
	if(item < 0)
	{
		return;
	}
	
	static szInfo[5], iNum
	
	menu_item_getinfo(menu, item, iNum, szInfo, charsmax(szInfo), .callback = iNum)
	
	switch(str_to_num(szInfo))
	{
		case NC_MENU:
		{
			new iMenu = menu_create("Choose a Player", "NcHumanAdminMenuHandler")
			
			new iPlayers[32], iNum, iPlayer, szName[32], szItem[70], szInfo[5]
			get_players(iPlayers, iNum, "ch")
			
			for(new i; i < iNum; i++)
			{
				iPlayer = iPlayers[i]
				
				get_user_name(iPlayer, szName, charsmax(szName))
				
				switch(is_user_alive(iPlayer))
				{
					case 0:
					{
						formatex(szItem, charsmax(szItem), "%s \w(\yDEAD\w) \r[\y%s\r]", szName, cs_get_user_team(id) == NC_TEAM ? "NightCrawler" : "Human")
					}
					
					case 1:
					{
						formatex(szItem, charsmax(szItem), "%s              \r[\y%s\r]", szName, cs_get_user_team(id) == NC_TEAM ? "NightCrawler" : "Human")
					}
				}
				
				formatex(szInfo, charsmax(szInfo), "%d", iPlayer)
				
				menu_additem(iMenu, szItem, szInfo)
			}
			
			if(g_iPlayerMenu[id])
			{
				menu_destroy(g_iPlayerMenu[id])
			}
			
			menu_display(id, iMenu)
			g_iPlayerMenu[id] = iMenu
		}
		
		case ABILITY:
		{
			menu_display(id, g_iAdminMenu[ABILITY])
		}
	}
}

public NcHumanAdminMenuHandler(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu)
		g_iPlayerMenu[id] = 0
		return
	}
	
	static szInfo[50], CsTeams:iNum
	menu_item_getinfo(menu, item, _:iNum, szInfo, charsmax(szInfo), .callback = _:iNum)
	
	new iPlayer = str_to_num(szInfo)
	
	if(!is_user_connected(iPlayer))
	{
		ColorChat(id, BLUE, "%s ^4User no longer connected", PREFIX)
		return;
	}
	
	switch( ( iNum = cs_get_user_team(iPlayer) ) )
	{
		case NC_TEAM:
		{
			cs_set_user_team(iPlayer, HUMAN_TEAM)
		}
		
		case HUMAN_TEAM:
		{
			cs_set_user_team(iPlayer, NC_TEAM)
			g_iWasNc[iPlayer] = 1
		}
	}
	
	ExecuteHamB(Ham_Spawn, iPlayer)
	
	get_user_name(iPlayer, szInfo, charsmax(szInfo))
	
	ColorChat(id, BLUE, "%s ^4You have turned %s to a %s", PREFIX, szInfo, iNum == NC_TEAM ? "Human" : "NightCrawler")
	format(szInfo, charsmax(szInfo), "%s              \r[\y%s\r]", szInfo, iNum == NC_TEAM ? "Human" : "NightCrawler")
	
	menu_item_setname(menu, item, szInfo)
	
	menu_display(id, menu)
}			

public ItemAdminMenuHandler(id, menu, item)
{
	if(item < 0)
	{
		return;
	}
	
	static szInfo[5], iNum, iPlayers[32], iPlayer, szName[32]
	
	menu_item_getinfo(menu, item, iNum, szInfo, charsmax(szInfo), .callback = iNum)
	
	g_iSelectedItem[id] = str_to_num(szInfo)
	
	if(g_iPlayerMenu[id])
	{
		menu_destroy(g_iPlayerMenu[id])
	}
	
	new iMenu = menu_create("Choose a player", "GiveItemAdminMenuHandler")
	
	g_iPlayerMenu[id] = iMenu
#if NC_TEAM == CS_TEAM_CT
	get_players(iPlayers, iNum, "che", "CT")
#else
	get_players(iPlayers, iNum, "che", "TERRORIST")
#endif
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
				
		get_user_name(iPlayer, szName, charsmax(szName))
				
		formatex(szInfo, charsmax(szInfo), "%d", iPlayer)
				
		menu_additem(iMenu, szName, szInfo, cs_get_user_team(iPlayer) == NC_TEAM ? (1<<26) : 0)
	}
	
	menu_display(id, iMenu)
}

public GiveItemAdminMenuHandler(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu)
		g_iPlayerMenu[id] = 0
		return;
	}
	
	static szInfo[5], iPlayer, szName[32]
	menu_item_getinfo(menu, item, iPlayer, szInfo, charsmax(szInfo), szName, charsmax(szName), iPlayer)
	
	menu_destroy(menu)
	g_iPlayerMenu[id] = 0
	
	iPlayer = str_to_num(szInfo)
	switch(g_iSelectedItem[id])
	{
		case LASER:
		{
			if(g_iLaser[iPlayer])
			{
				g_iLaser[iPlayer] = 0
				
				ColorChat(id, BLUE, "%s ^4You have taken %s laser sight", szName)
				return;
			}
			
			g_iLaser[iPlayer] = 1
			ColorChat(id, BLUE, "%s ^4You have given %s laser sight", szName)
		}
		
		case MINE:
		{
			g_iMines[iPlayer] = MINE_GIVE_AMOUNT
			ColorChat(id, BLUE, "%s ^4You have given %s %d Laser Mines", szName, MINE_GIVE_AMOUNT)
		}
		
		case ADRENALINE:
		{
			InsertToBit(iPlayer, gHasAdrenaline)
			ColorChat(id, BLUE, "%s ^4You have given %s Adrenaline", szName)
		}
		
		case FROST:
		{
			give_item(iPlayer, "weapon_flashbang")
			ColorChat(id, BLUE, "%s ^4You have given %s a frostnade", szName, MINE_GIVE_AMOUNT)
		}
		
		case EXPLOSION:
		{
			InsertToBit(iPlayer, gExplosion)
			ColorChat(id, BLUE, "%s ^4You have given %s Explosion Suicide", szName, MINE_GIVE_AMOUNT)
		}
	}
}
			

public client_disconnect(id)
{
	RemoveFromBit(id, gSave);
	RemoveFromBit(id, gCanHaveLaser);
	RemoveFromBit(id, gExplosion);
	RemoveFromBit(id, gAdrenaline);
	RemoveFromBit(id, gHasChoosed);
	RemoveFromBit(id, gHasAdrenaline);
	/*
	gHasChoosedWeapons
	gFirstJoin
	gCanJoinTeam
	gFakeTeam*/
	
	new id2
	if(get_alive_ct(id2) == 1)
	{
		g_iLaser[id2] = 1
		g_iLaserCount = 1
				
		if(IsInBit(id2, gCanHaveLaser))
		{
			RemoveFromBit(id2, gCanHaveLaser)
		}
	}
}

#if defined FOG
public MakeFog(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	CreateFog(id, 190, 190, 190)
}
#endif

public message_TextMsg(msgid, dest, id)
{
	if(get_msg_arg_int(1) != print_center)
	{
		return PLUGIN_CONTINUE
	}
	
	static const CT_WIN1[] = "#CTs_Win"
	static const CT_WIN2[] = "#Hostages_Not_Rescued"
	static const T_WIN[] = "#Terrorists_Win"
	
	static szSound[60]
	get_msg_arg_string(2, szSound, charsmax(szSound))
	
	if(equal(szSound, CT_WIN1) || equal(szSound, CT_WIN2))
	{
		set_hudmessage(0, 0, 255, -1.0, 0.20, 0, 0.0, 6.0, 0.1, 0.1)
		ShowSyncHudMsg(0, gSyncHud, g_szNewCTWinMessage)
		//set_msg_arg_string(2, g_szNewCTWinMessage)
		
		return PLUGIN_HANDLED
	}
	
	else if(equal(szSound, T_WIN))
	{
		set_hudmessage(255, 0, 0, -1.0, 0.20, 0, 0.0, 6.0, 0.1, 0.1)
		ShowSyncHudMsg(0, gSyncHud, g_szNewTWinMessage)
		//set_msg_arg_string(2, g_szNewTWinMessage)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public message_SendAudio(msgid, dest, id)
{
	//static const CT_WIN[] = "%!MRAD_ctwin"
	static const T_WIN[] = "%!MRAD_terwin"
	static const HOSTAGE_NOT_RESCUED[] = "%!MRAD_rounddraw"
	
	static szSound[60]
	get_msg_arg_string(2, szSound, charsmax(szSound))
	
	if(equal(szSound, T_WIN) || equal(szSound, HOSTAGE_NOT_RESCUED))
	{
		new iNum = random(sizeof(g_szHumanWinSounds))
		
		client_cmd(id, "spk ^"%s^"", g_szHumanWinSounds[iNum])
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fw_EmitSound(iEnt, iChannel, szSound[ ], Float:fVolume, Float:fAttn, iFlags, iPitch)
{
	if( !IsPlayer(iEnt) || !is_user_alive(iEnt) || cs_get_user_team(iEnt) != NC_TEAM)
	{
		return FMRES_IGNORED
	}
	
	if(TrieKeyExists(gKnifeSounds, szSound))
	{	
		new iNum
		TrieGetCell(gKnifeSounds, szSound, iNum)
		emit_sound(iEnt, iChannel, g_szNewKnifeSounds[iNum], fVolume, fAttn, iFlags, iPitch)
		
		return FMRES_SUPERCEDE
	}
	
	if(TrieKeyExists(gDeathSounds, szSound))
	{
		emit_sound(iEnt, iChannel, g_szNewDeathSounds[random(sizeof(g_szNewDeathSounds))], fVolume, fAttn, iFlags, iPitch)
		
		return FMRES_SUPERCEDE
	}
	
	if(contain(szSound, "bhit") != -1)
	{
		emit_sound(iEnt, iChannel, PAIN_SOUND, fVolume, fAttn, iFlags, iPitch)
		return FMRES_SUPERCEDE
	}
	
	if(contain(szSound, "nvg") != -1)
	{
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public EnableGuns(id)
{
	if(IsInBit(id, gSave))
	{
		RemoveFromBit(id, gSave)
		
		ColorChat(id, BLUE, "%s ^4The gun menu has been reenabled.", PREFIX)
		
		return PLUGIN_HANDLED
	}
	
	else if(!IsInBit(id, gHasChoosedWeapons))
	{
		menu_display(id, g_iWeaponMenu[MAIN])
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fw_ClientKill(id)
{
	if(cs_get_user_team(id) == NC_TEAM)
	{
		client_print(id, print_center, "You can't kill your self.")
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public GiveMine(id)
{
	if(!g_iMines[id])
	{
		client_print(id, print_chat, "You have been given 2 laser mines")
		g_iMines[id] = MINE_GIVE_AMOUNT
	}
}

public GiveGamma(id)
{
	g_iUserGamma[id][GAMMA_AMOUNT] = 999999
}

public GivePoints(id)
{
	g_iUserPoints[id] = 9999999
}

public fw_SetMaxSpeed(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	if(IsInBit(id, gAdrenaline))
	{
		set_user_maxspeed(id, ADRENALINE_SPEED)
	}
}

public fw_TouchWall(world, id)
{
	if(is_user_alive(id))
		pev(id, pev_origin, g_flWallOrigin[id])
}

public fw_WeaponTouch(iEnt, id)
{
	if(cs_get_user_team(id) == NC_TEAM)
	{
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public eNewRound()
{
	// Reset Shops
	gExplosion = 0
	gAdrenaline = 0
	gHasChoosed = 0
	gHasAdrenaline = 0
	gHasChoosedWeapons = 0
	gCanHaveLaser = 0
	
	arrayset(g_iLaser, 0, sizeof(g_iLaser))
	arrayset(g_iMines, 0, sizeof(g_iMines))
	
	for(new i; i < g_iMaxPlayers; i++)
	{
		if(g_flIsInPlant[i])
		{
			if(is_user_connected(i))
			{
				remove_plant_bar(i)
			}
			
			g_flIsInPlant[i] = 0.0
		}	
	}
	
	g_iLaserCount = 0
	g_iMinesCount = 0
	
	new iEnt = -1
	while((iEnt = find_ent_by_class(iEnt, MINE_CLASSNAME)))
	{
		remove_entity(iEnt)
	}
	
	new iPlayers[32], iNum, iTaskId, iPlayer, CsTeams:iTeam
	get_players(iPlayers, iNum, "ch")
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(g_iSpec[iPlayer])
		{
			g_iSpec[iPlayer]++
		}
		
		if( ( iTeam = cs_get_user_team(iPlayer) ) == NC_TEAM)
		{
			cs_set_user_team(iPlayer, HUMAN_TEAM)
			
			g_iWasNc[iPlayer] = 1
		}
		
		else if(iTeam == HUMAN_TEAM && g_iWasNc[iPlayer])
		{
			g_iWasNc[iPlayer] = 0
		}
		
		if(g_iPlayerMenu[iPlayer])
		{
			menu_destroy(g_iPlayerMenu[iPlayer])
		}
		
		for(new a = TASK_HUD; i < TASKS; i += 124)
		{
			iTaskId = a + iPlayer
			if(task_exists(iTaskId))
			{
				remove_task(iTaskId)
			}
		}
	}
	
	ChooseNCPlayers(iPlayers, iNum)
	get_highest_kills()
	
	#if defined FOG
	CreateFog(0, 190, 190 ,190)
	#endif
}

public ShowHelpMotd(id)
{
	ColorChat(id, BLUE, "Under development.....")
	return PLUGIN_HANDLED
}

public CallBack(id, menu, item)
{
	new szInfo[5], iNum
	menu_item_getinfo(menu, item, iNum, szInfo, charsmax(szInfo), .callback = iNum)
	
	switch(str_to_num(szInfo))
	{
		case LASER:
		{
			if(g_iLaserCount < MAX_LASER_SIGHT_HOLDERS && IsInBit(id, gCanHaveLaser))
			{
				return ITEM_ENABLED
			}
		}
		
		case MINE:
		{
			if(g_iMinesCount < MAX_MINE_HOLDERS)
			{
				return ITEM_ENABLED
			}
		}
	}
	
	return ITEM_DISABLED
}

public ItemMenuHandler(id, menu, item)
{
	if(item < 0 || !is_user_alive(id))
	{
		return;
	}
	
	new szInfo[2], iNum, access, callback
	menu_item_getinfo(menu, item, access, szInfo, charsmax(szInfo), .callback=callback)
	
	iNum = str_to_num(szInfo)
	
	
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
		
		case 	ADRENALINE:
		{
			ColorChat(id, BLUE, "%s ^4Press f to activate it. It will last for %d seconds!", PREFIX, ADRENALINE_TIME)
			InsertToBit(id, gHasAdrenaline)
		}
		
		case	MINE:
		{
			if(g_iMinesCount == MAX_MINE_HOLDERS)
			{
				menu_display(id, menu)
				return;
			}
			
			else
			{
				g_iMines[id] = MINE_GIVE_AMOUNT
				g_iMinesCount++
				ColorChat(id, BLUE, "%s ^4You have choosen two laser mines.", PREFIX)
				
				if(g_iMinesCount == MAX_MINE_HOLDERS)
				{
					UpdateMenus()
				}
			}
		}
		
		case	LASER:
		{
			if(g_iLaserCount == MAX_LASER_SIGHT_HOLDERS)
			{
				menu_display(id, menu)
				return;
			}
			
			else
			{
				g_iLaser[id] = 1
				g_iLaserCount++
				ColorChat(id, BLUE, "%s ^4You now have the laser. It will turn ^3red ^4if aiming at a ^3nightcrawler^4.", PREFIX)
				
				if(g_iLaserCount == MAX_LASER_SIGHT_HOLDERS)
				{
					UpdateMenus()
				}
			}
		}
	}
	
	InsertToBit(id, gHasChoosed)
}

stock UpdateMenus()
{
	new iPlayers[32], iNum, iPlayer, iOldMenu, iNewMenu, iPage
	get_players(iPlayers, iNum, "ache", "CT")
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		player_menu_info(iPlayer, iOldMenu, iNewMenu, iPage)
		
		if(iNewMenu == g_iItemMenu && !IsInBit(gHasChoosed, iPlayer))
		{
			menu_display(iPlayer, g_iItemMenu)
		}
	}
}

public MainWeaponsMenuHandler(id, menu, item)
{
	if(item < 0 || !is_user_alive(id))
	{
		return;
	}
	
	static szInfo[5], iNum
	menu_item_getinfo(menu, item, iNum, szInfo, charsmax(szInfo), .callback = iNum)
	
	switch(str_to_num(szInfo))
	{
		case 1:
		{
			g_iLastWeapons[id] = 0
			menu_display(id, g_iWeaponMenu[PRIM])
		}
		
		case 2:
		{
			GiveOldWeapons(id)
			InsertToBit(id, gHasChoosedWeapons)
			menu_display(id, g_iItemMenu)
		}
		
		case 3:
		{
			GiveOldWeapons(id)
			InsertToBit(id, gSave);
			InsertToBit(id, gHasChoosedWeapons);
			
			menu_display(id, g_iItemMenu)
		}
	}
}

public PrimWeaponsMenuHandler(id, menu, item)
{
	if(item < 0 || !is_user_alive(id))
	{
		return;
	}
	
	static szInfo[5], iNum
	menu_item_getinfo(menu, item, iNum, szInfo, charsmax(szInfo), .callback = iNum)
	
	iNum = str_to_num(szInfo)
	new szWeapon[32]; get_weaponname(iNum, szWeapon, charsmax(szWeapon))
	cs_set_user_bpammo(id, iNum, MAXBPAMMO[iNum])
	give_item(id, szWeapon)
	
	g_iLastWeapons[id] |= (1<<iNum);
	
	InsertToBit(id, gHasChoosedWeapons)
	
	menu_display(id, g_iWeaponMenu[SEC])
}

public SecWeaponsMenuHandler(id, menu, item)
{
	if(item < 0 || !is_user_alive(id))
	{
		return;
	}
	
	static szInfo[5], iNum
	menu_item_getinfo(menu, item, iNum, szInfo, charsmax(szInfo), .callback = iNum)
	
	new szWeapon[32]; get_weaponname( ( iNum = str_to_num(szInfo) ), szWeapon, charsmax(szWeapon))
	
	cs_set_user_bpammo(id, iNum, MAXBPAMMO[iNum])
	give_item(id, szWeapon)
	
	g_iLastWeapons[id] |= (1<<iNum)
	
	menu_display(id, g_iItemMenu)
}

stock GiveOldWeapons(id)
{
	new iWeapons = g_iLastWeapons[id]
	new szWeapon[32]
	
	for(new i = CSW_P228; i < CSW_VEST; i++)
	{
		if(iWeapons & (1<<i))
		{
			get_weaponname(i, szWeapon, charsmax(szWeapon))
			
			give_item(id, szWeapon)
			cs_set_user_bpammo(id, i, MAXBPAMMO[i])
		}
	}
}

public fw_Think(id)
{
	if(!pev_valid(id) || !is_user_alive(id))
	{
		return;
	}
	
	static  CsTeams:iTeam, iButton, Float:vOrigin[3], Float:flGameTime
	if( ( iTeam = cs_get_user_team(id) ) == NC_TEAM)
	{
		if(( g_iUserGamma[id][GAMMA_AMOUNT] < CVARS[GAMMA] ) && ( (iButton = floatround( get_gametime() ) ) >= g_iUserGamma[id][GAMMA_LASTGAIN] ) )
		{
			AddGamma(id, iButton)
		}
		
		iButton = pev(id, pev_button)
		
		if( iButton & IN_USE )
		{
			pev( id, pev_origin, vOrigin );
			
			if( get_distance_f( vOrigin, g_flWallOrigin[ id ] ) > 10.0 )
			{
				return;
			}
			
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
	
	else if(iTeam == HUMAN_TEAM)
	{
		if(g_iLaser[id])
		{
			static iEndOrigin[3], Float:vEndOrigin[3]
			get_user_origin(id, iEndOrigin, 3)
			
			IVecFVec(iEndOrigin, vEndOrigin)
			
			static iAim, iBody, iRed, iGreen, iBlue; get_user_aiming(id, iAim, iBody)
			
			if(IsPlayer(iAim) && cs_get_user_team(iAim) == NC_TEAM)
			{
				iRed = 255
				iGreen = 0
				iBlue = 0
			}
			
			else
			{
				iRed = 0
				iGreen = 255
				iBlue = 0
			}
			
			Draw(_, vEndOrigin, 1, iRed, iGreen, iBlue, 200, 1, id)
		}
		
		if(g_iMines[id])
		{
			static Float:flPlantTime; flPlantTime = g_flIsInPlant[id]
			// Start Planting
			iButton = pev(id, pev_button)
			
			if( !flPlantTime )
			{
				if( (iButton & IN_USE) && (pev(id, pev_oldbuttons) & IN_USE))
				{
					pev( id, pev_origin, vOrigin );
					if( get_distance_f( vOrigin, g_flWallOrigin[ id ] ) > 10.0 )
					{
						return;
					}
					
					start_plant_bar(id)
					g_flIsInPlant[id] = MINE_PLANT_TIME + get_gametime() + 0.2
					return;
				}
			}
			
			else
			{
				pev( id, pev_origin, vOrigin );
				if(flPlantTime && get_distance_f( vOrigin, g_flWallOrigin[ id ] ) > 10.0 )
				{
					remove_plant_bar(id)
					g_flIsInPlant[id] = 0.0
					return;
				}
				
				// Stopped planting
				if( !(iButton & IN_USE) )
				{
					remove_plant_bar(id)
					g_flIsInPlant[id] = 0.0
					return;
				}
				
				else if( ( flGameTime = get_gametime() ) >= flPlantTime )
				{
					g_flIsInPlant[id] = 0.0
					
					new Float:vTraceEnd[3], Float:vOrigin[3]
					
					new iTr = create_tr2()
					
					pev( id, pev_origin, vOrigin );
					velocity_by_aim( id, 128, vTraceEnd );
					
					xs_vec_add(vTraceEnd, vOrigin, vTraceEnd)
					
					engfunc( EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, iTr);
					
					new Float:flFraction
					get_tr2(iTr, TR_flFraction, flFraction)
					
					if(flFraction == 1.0)
					{
						get_tr2(iTr, TR_vecEndPos, vTraceEnd)
						
						client_print(id, print_chat, "[MINE DEBUG] Not good origin")
						free_tr2(iTr)
						return;
					}
					
					get_tr2(iTr, TR_vecEndPos, vTraceEnd)
					
					new Float:vAngles[3], Float:vNormal[3], Float:vEndPos[3]
					
					get_tr2(iTr, TR_vecPlaneNormal, vNormal)
					get_tr2(iTr, TR_vecEndPos, vEndPos)
					
					// To make the Normal vector fit the mine size.
					xs_vec_mul_scalar(vNormal, 8.0, vNormal)
					xs_vec_add(vEndPos, vNormal, vOrigin)
					
					vector_to_angle(vNormal, vAngles)
					
					// --| For mine laser
					xs_vec_copy(vNormal, vTraceEnd)
					
					xs_vec_mul_scalar(vTraceEnd, 8192.0, vTraceEnd)
					xs_vec_add(vOrigin, vTraceEnd, vTraceEnd)
					
					new iEnt = create_entity("info_target")
					
					engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, -1, iTr)
					
					get_tr2(iTr, TR_flFraction, flFraction)
					if(flFraction == 1.0)
					{	
						client_print(id, print_chat, "[MINE DEBUG] Not good end origin")
						
						Draw(vOrigin, vTraceEnd, 100)
						
						remove_entity(iEnt)
						
						free_tr2(iTr)
						return;
					}
					
					get_tr2(iTr, TR_vecEndPos, vTraceEnd)
					free_tr2(iTr)
					
					engfunc(EngFunc_SetSize, iEnt, Float:{ -4.0, -4.0, -4.0 }, Float:{ 4.0, 4.0, 4.0 } );
					
					set_pev(iEnt, pev_classname, MINE_CLASSNAME)
					
					set_pev(iEnt, pev_owner, id)
					set_pev(iEnt, pev_health, MINE_HEALTH)
					
					set_pev(iEnt, pev_angles, vAngles)
					
					set_pev(iEnt, pev_takedamage, DAMAGE_YES)
					
					set_pev(iEnt,pev_sequence, 7)
					set_pev(iEnt,pev_body,3)
					
					set_pev(iEnt, pev_framerate, 72)
					set_pev(iEnt, pev_frame, 1)
					
					set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
					set_pev(iEnt, pev_solid, SOLID_BBOX)
					
					set_pev(iEnt, MINE_VEC_ENDPOS, vTraceEnd)
					engfunc(EngFunc_SetOrigin, iEnt, vOrigin)
					engfunc(EngFunc_SetModel, iEnt, MINE_MODEL)
					
					set_pev(iEnt, pev_nextthink, flGameTime + MINE_POWERUP_TIME)
					
					PlaySound(iEnt, MINE_POWERUP_SOUND)
					
					g_iMines[id]--
					
					if(g_iMines[id])
					{
						StatusMessage(id, "Mines left: %d", g_iMines[id])
					}
					
					else
					{
						StatusMessage(id, "No mines left!")
					}
				}
			}
		}
	}
}

stock Draw(Float:origin[] = { 0.0, 0.0, 0.0 }, Float:endpoint[], duration = 1, red = 0, green = 255, blue = 0, brightness = 127, scroll = 1, id = 0)
{                    
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	
	if(id)
	{
		write_byte(TE_BEAMENTPOINT)
		write_short(id | 0x1000)
		engfunc(EngFunc_WriteCoord, endpoint[0])
		engfunc(EngFunc_WriteCoord, endpoint[1])
		engfunc(EngFunc_WriteCoord, endpoint[2])
	}
	
	else
	{
		write_byte(TE_BEAMPOINTS)
		engfunc(EngFunc_WriteCoord, origin[0])
		engfunc(EngFunc_WriteCoord, origin[1])
		engfunc(EngFunc_WriteCoord, origin[2])
		engfunc(EngFunc_WriteCoord, endpoint[0])
		engfunc(EngFunc_WriteCoord, endpoint[1])
		engfunc(EngFunc_WriteCoord, endpoint[2])
	}

	write_short(beampoint)
	write_byte(0)
	write_byte(0)
	write_byte(duration) // In tenths of a second.
	write_byte(10)
	write_byte(0)
	write_byte(red) // Red
	write_byte(green) // Green
	write_byte(blue) // Blue
	write_byte(brightness)
	write_byte(scroll)
	message_end()
}  

public fw_MineThink(iEnt)
{
	static Float:vOrigin[3], Float:vEndPos[3]
	pev(iEnt, pev_origin, vOrigin)
	pev(iEnt, MINE_VEC_ENDPOS, vEndPos)
	
	Draw(vOrigin, vEndPos, 2)
	
	switch(pev(iEnt, MINE_POWERUP_PEV))
	{
		case 0:
		{
			set_pev(iEnt, MINE_POWERUP_PEV, 1)
			
			set_pev(iEnt, pev_solid, SOLID_BBOX);
			
			PlaySound(iEnt, MINE_ACTIVATE_SOUND)
		}
		
		case 1:
		{
			new iTr = create_tr2()
			
			engfunc(EngFunc_TraceLine, vOrigin, vEndPos, IGNORE_GLASS, 0, iTr)
			
			static Float:flFraction
			get_tr2(iTr, TR_flFraction, flFraction)
			if(flFraction < 1.0)
			{
				new id = get_tr2(iTr, TR_pHit)
				
				if(id <= g_iMaxPlayers && cs_get_user_team(id) == NC_TEAM)
				{
					PlaySound(id, MINE_NC_NOTIFY)
				}
			}
			
			free_tr2(iTr)
		}
	}
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
}

stock start_plant_bar(id)
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

stock remove_plant_bar(id)
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

stock PlaySound(iEnt, const szSound[])
{
	emit_sound(iEnt, CHAN_AUTO, szSound, VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
}

stock AddGamma(id, iGameTime)
{
	g_iUserGamma[id][GAMMA_LASTGAIN] = iGameTime + GAMMA_DELAY
	
	new iGammaAmount = CVARS[GAMMA]
	if(g_iUserGamma[id][GAMMA_AMOUNT] + GAMMA_ADD > iGammaAmount)
		g_iUserGamma[id][GAMMA_AMOUNT] = iGammaAmount
	
	else	
	{
		g_iUserGamma[id][GAMMA_AMOUNT] += GAMMA_ADD
	}
}

public fw_TakeDamage(id, idinflictor, iAttacker, Float:damage, damagebits)
{
	if( /*IsPlayer(id) &&*/ cs_get_user_team(id) == NC_TEAM)
	{
		if(damagebits & DMG_FALL)
		{
			return HAM_SUPERCEDE
		}
		
		if(IsPlayer(iAttacker) && cs_get_user_team(iAttacker) == HUMAN_TEAM)
		{
			g_iVisible[id] = 1
			
			new iNum = TASK_INVIS + id
			
			if(task_exists(iNum))
			{
				remove_task(iNum)
			}
			
			set_task(VISIBLE_TIME, "set_back", iNum)
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
		{
			set_es(es, ES_RenderAmt, 255);
		}
		
		else 
		{
			set_es(es, ES_RenderAmt, 0);
		}
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
	{
		return;
	}
	
	if(cs_get_user_team(id) == NC_TEAM /*&& read_data(2) == CSW_KNIFE*/)
	{
		set_pev(id, pev_viewmodel2, NC_KNIFE)
	}
}

public message_Scenario(msgid, dest, id)
{
	static szHud[50]
	get_msg_arg_string(2, szHud, charsmax(szHud))
	return ( ( contain(szHud, "hostage") && get_msg_arg_int(1) == 1 ) ?  PLUGIN_HANDLED : PLUGIN_CONTINUE )
}

public message_CurWeapon(msg_id, msg_dest, id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return;
	
	if( cs_get_user_team(id) != HUMAN_TEAM )
		return;
	
	// Player doesn't have the unlimited clip upgrade
	if ( !IsInBit(id, gAdrenaline) )
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
			weapon_ent = find_ent_by_owner(-1, wname, id)
			
			// Set max clip on weapon
			fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		}
	}
}

// Set Weapon Clip Ammo
stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}

public fw_Killed(id, iAttacker, iShouldGib)
{
	static iLastPlayer
	if(get_alive_ct(iLastPlayer) == 1)
	{
		g_iLaser[iLastPlayer] = 1
		g_iLaserCount = 1
	}
}

public fw_PlayerSpawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	strip_user_weapons(id)
	set_pdata_int(id, OFFSET_PRIMARYWEAPON, 0)
	give_item(id, "weapon_knife")
	switch(cs_get_user_team(id))
	{
		case NC_TEAM:
		{
			new iNewMenu, iOldMenu, dump
			player_menu_info(id, iOldMenu, iNewMenu, dump)
			
			if(iNewMenu)
			{
				menu_cancel(id)
			}
			
			if(IsInBit(id, gFakeTeam))
			{
				RemoveFromBit(id, gFakeTeam)
				
				cs_set_user_team(id, HUMAN_TEAM)
				ExecuteHam(Ham_Spawn, id)
				
				return;
			}
			
			g_iUserGamma[id][GAMMA_AMOUNT] = 150
			g_iVisible[id] = false
			
			g_iWasNc[id] = 1
			
			set_user_gravity(id, float(CVARS[GRAVITY]) / get_pcvar_float(g_pGravity))
			set_user_health(id, CVARS[HEALTH])
			set_user_footsteps(id, 1)
			set_user_maxspeed(id, float(CVARS[SPEED]))
			
			set_user_armor(id, CVARS[ARMOR])
			
			ColorChat(id, BLUE, "%s ^4You are invisible now.", PREFIX)
			
			cs_set_user_model(id, NC_MODEL)
			cs_set_user_nvg(id, 1)
			
			set_task(0.5, "ShowHud", TASK_HUD + id, .flags ="b")
		}
		
		case HUMAN_TEAM:
		{
			set_user_footsteps(id, 0)

			if(IsInBit(id, gHasChoosedWeapons))
			{
				RemoveFromBit(id, gHasChoosedWeapons)
			}
			
			g_iVisible[id] = true
			cs_set_user_model(id, CT_MODELS[random_num(0, 3)])
			
			if(IsInBit(id, gSave))
			{
				GiveOldWeapons(id)
				InsertToBit(id, gHasChoosedWeapons)
				menu_display(id, g_iItemMenu)
			}
			
			else
			{
				menu_display(id, g_iWeaponMenu[MAIN])
			}
			
			set_task(1.0, "CheckLaser", id)
		}
	}		
}

public CheckLaser(id)
{
	if(get_alive_ct() == 1)
	{
		g_iLaser[id] = 1
		g_iLaserCount = 1
				
		if(IsInBit(id, gCanHaveLaser))
		{
			RemoveFromBit(id, gCanHaveLaser)
		}
	}
}

public fw_Impulse(id)
{
	if(!is_user_alive(id))
	{
		return;
	}

	if(pev(id, pev_impulse) == 100)
	{
		// Block flashlight from working.
		set_pev(id, pev_impulse, 0)
		
		new CsTeams:iTeam = cs_get_user_team(id)
		if( iTeam == NC_TEAM )
		{
			if(g_iUserGamma[id][GAMMA_AMOUNT] > CVARS[TELEPORT_COST])
			{
				if(Teleport(id))
				{
					g_iUserGamma[id][GAMMA_AMOUNT] -= CVARS[TELEPORT_COST]
				}
					
				else
				{
					ColorChat(id, BLUE, "%s You were slayed as you were stuck because of the teleport", PREFIX)
					user_kill(id)
				}
			}
		}
		
		else if( iTeam == HUMAN_TEAM )		// EXPLOSION
		{
			if( IsInBit(id, gExplosion) )
			{
				RemoveFromBit(id, gExplosion);
				
				g_iSuicideTime[id] = SUICIDE_TIME + 1
				
				new iTaskId = id + TASK_SUICIDE
				Suicide(iTaskId)
				set_task(1.0, "Suicide", iTaskId, .flags = "b")
			}
			
			else if( IsInBit(id, gHasAdrenaline) )
			{
				RemoveFromBit(id, gHasAdrenaline);
				InsertToBit(id, gAdrenaline);
				
				set_user_maxspeed(id, ADRENALINE_SPEED)
				ColorChat(id, BLUE, "%s ^4You have activated Adrenaline!", PREFIX)
				
				//client_cmd(id, "spk ^"%s^"", ADRENALINE_SOUND)
				emit_sound(id, CHAN_AUTO, ADRENALINE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				
				set_task(float(ADRENALINE_TIME), "RemoveAdrenaline", id)
			}
		}
	}
}

public RemoveAdrenaline(id)
{
	RemoveFromBit(id, gAdrenaline)
	set_user_maxspeed(id, 250.0)
	ColorChat(id, BLUE, "%s ^4Adrenaline effect wore off", PREFIX)
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
		free_tr2( pTr )
		
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
	{
		return true
	}
	
	return false
}

stock UTIL_UnstickPlayer (const id, const i_StartDistance, const i_MaxAttempts)
{
	// --| Not alive, ignore.
	if ( !is_user_alive ( id ) )
	{  
		return -1
	}
	
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
	
	if(!is_user_alive(id))
	{
		remove_task(iTaskID)
		return;
	}

	if( --g_iSuicideTime[ id ] == 0 )
	{
		remove_task(iTaskID)
		
		new Float:flOrigin[ 3 ], Float:flOrigin2[3]
		pev( id, pev_origin, flOrigin )
		
		user_kill( id, 1 );
		
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_EXPLOSION );
		engfunc(EngFunc_WriteCoord, flOrigin[ 0 ])
		engfunc(EngFunc_WriteCoord, flOrigin[ 1 ])
		engfunc(EngFunc_WriteCoord, flOrigin[ 2 ])
		write_short( gExplosionSprite );
		write_byte( 30 );
		write_byte( 30 );
		write_byte( 0 );
		message_end();
		
		new iEnt = -1, Float:flDamage
		while( ( iEnt = find_ent_in_sphere( iEnt, flOrigin, EXPLOSION_RADIUS) ) && IsPlayer(iEnt) && iEnt != id) 
		{
			pev(iEnt, pev_origin, flOrigin2)
			flDamage = EXPLOSION_DAMAGE  - ( EXPLOSION_DAMAGE * get_distance_f(flOrigin, flOrigin2) ) / EXPLOSION_RADIUS
			
			ExecuteHam(Ham_TakeDamage, iEnt, iEnt, id, flDamage, DMG_GENERIC);
		}
	}

	else emit_sound( id, CHAN_ITEM, g_szSuicideBombSound[g_iSuicideTime[id]], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}

stock StatusMessage(id, szMessage[], any:...)
{
	new szStatus[100]
	vformat(szStatus, charsmax(szStatus), szMessage, 3)
	
	message_begin(MSG_ONE, gMsgIdStatusText, {0,0,0}, id)
	write_byte(0)
	write_string(szStatus)
	message_end()
	
	set_task(3.5, "RemoveText", id)
}

public RemoveText(id)
{
	message_begin(MSG_ONE, gMsgIdStatusText,_, id)
	write_byte(0)
	write_string("")
	message_end()
}

// TASKS
public ShowHud(TaskId)
{
	new id = TaskId - TASK_HUD
	
	if(!is_user_alive(id) || cs_get_user_team(id) != NC_TEAM)
		return remove_task(TaskId)
	
	set_hudmessage(0, 100, 200, -1.0, 0.75, 0, 0.0, 0.6, 0.1, 0.2)
	show_hudmessage(id, "Health: %d          Armor: %d^nGamma: %d/%d", get_user_health(id), get_user_armor(id), g_iUserGamma[id][GAMMA_AMOUNT], CVARS[GAMMA])
	
	return 1
}

public set_back(id)
{
	id -= TASK_INVIS
	g_iVisible[id] = 0
}


// FORWARDS
public frostnades_player_chilled( victim, attacker )
{
	if(cs_get_user_team(victim) == NC_TEAM)
	{
		g_iVisible[victim] = 1
		set_task(VISIBLE_TIME, "set_back", victim)
	}
}

stock BuildWeaponMenus()
{
	g_iWeaponMenu[MAIN] = menu_create("Weapons Menu", "MainWeaponsMenuHandler")
	
	menu_additem(g_iWeaponMenu[MAIN], "Choose new weapons", "1")
	menu_additem(g_iWeaponMenu[MAIN], "Previous weapons", "2")
	menu_additem(g_iWeaponMenu[MAIN], "Don't ask again and save weapons", "3")
	
	g_iWeaponMenu[PRIM] = menu_create("Primary Weapons", "PrimWeaponsMenuHandler")
	g_iWeaponMenu[SEC] = menu_create("Secondary Weapons", "SecWeaponsMenuHandler")
	
	new const iPrimWeps = ( (1<<CSW_AK47) | (1<<CSW_AUG) | (1<<CSW_AWP) | (1<<CSW_FAMAS) | (1<<CSW_GALIL) \
	| (1<<CSW_G3SG1) | (1<<CSW_M249) | (1<<CSW_M3) | (1<<CSW_M4A1) | (1<<CSW_MAC10) | (1<<CSW_MP5NAVY) | \
	 (1<<CSW_P90) | (1<<CSW_SCOUT) | (1<<CSW_SG550) | (1<<CSW_SG552) | (1<<CSW_TMP) | (1<<CSW_XM1014) );
	 
	new const iNullWeapons = (1<<2) | (1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_KNIFE)
	
	new szWeapon[32], szInfo[5]
	
	for(new i = CSW_P228; i < CSW_VEST; i++)
	{
		if(IsInBit(i, iNullWeapons))
		{
			continue;
		}
		
		get_weaponname(i, szWeapon, charsmax(szWeapon))
		replace(szWeapon, charsmax(szWeapon), "weapon_", "")
		strtoupper(szWeapon)
		
		formatex(szInfo, charsmax(szInfo), "%d", i)
		
		menu_additem(g_iWeaponMenu[ IsInBit(i, iPrimWeps) ? PRIM : SEC ], szWeapon, szInfo)	
	}
	
	
	//menu_setprop(g_iWeaponMenu[MAIN], MPROP_EXIT, MEXIT_NEVER)
	menu_setprop(g_iWeaponMenu[PRIM], MPROP_EXIT, MEXIT_NEVER)
	menu_setprop(g_iWeaponMenu[SEC], MPROP_EXIT, MEXIT_NEVER)
}

stock get_alive_ct(&iLastPlayerNum = 0)
{
	static iPlayers[32], iNum
	get_players(iPlayers, iNum, "ache", "CT")
	
	if(iNum == 1)
	{
		iLastPlayerNum = iPlayers[0]
	}
	
	return iNum
}

stock CreateFog (const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false) 
{    
	static msgFog;
	
	if (msgFog || (msgFog = get_user_msgid("Fog")))     
	{         
		new density = _:floatclamp(density_f, 0.0001, 0.25) * _:!clear;                 
		message_begin(index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgFog, .player = index);         
		write_byte(clamp(red, 0, 255));         
		write_byte(clamp(green, 0, 255));         
		write_byte(clamp(blue , 0, 255));         
		write_byte((density & 0xFF));         
		write_byte((density >>  8) & 0xFF);         
		write_byte((density >> 16) & 0xFF);         
		write_byte((density >> 24) & 0xFF);         
		message_end();     
	} 
}

stock get_highest_kills()
{
	new iPlayers[32], iNum, iNum2, iHighestFrag = -2917, iPlayer, iFrags, iAllFrags[33][2]
	get_players(iPlayers, iNum, "che", "CT")
	
	if(!iNum)
	{
		return;
	}
	
	if(iNum == 1)
	{
		g_iLaser[iPlayers[0]] = 1
		return
	}
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if( ( iFrags = ( get_user_frags(iPlayer) - get_user_deaths(iPlayer) ) ) >= iHighestFrag )
		{
			iHighestFrag = iFrags
			iAllFrags[i][0] = iFrags
			iAllFrags[i][1] = iPlayer
			
			iNum2++
		}
	}
	
	server_print("%d", iHighestFrag)
	new szName[32]
	
	for(new i; i < iNum2; i++)
	{
		if(iAllFrags[i][0] == iHighestFrag && IsPlayer( ( iPlayer = iAllFrags[i][1] ) ) )
		{
			get_user_name(iPlayer, szName, charsmax(szName))
			
			server_print("Can have %s", szName)
			
			InsertToBit(iPlayer, gCanHaveLaser)
			
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
