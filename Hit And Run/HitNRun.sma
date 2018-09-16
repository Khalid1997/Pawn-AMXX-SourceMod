#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <nvault>

new const VERSION[] = "2.5"
new const AUTHOR[] = "Khalid :)"

#define ACCESS ADMIN_RCON

new const PREFIX[] = "^3[ ^4Hit And Run ^3]"

// Starting level for each new player
#define START_LEVEL	1

// Each level's Experince points.
#define LEVEL_EXP	100

// Support for CZ Bots ? (May work with P0DBots)
// Not for Real use! Only for testing!
#define BOT_SUPPORT

// Save points and other data by name?
// Else save by STEAMID
#define SAVE_BY_NAME

// Make players auto join terrorist when they connect?
//#define AUTO_JOIN

// ONLY FOR TESTING! DON'T USE!
//#define TEST

// do sv_restart 1 on round restart? Else respawn players normally
//#define RESTART_METHOD

#define BomberGlow(%1) set_user_rendering(%1, kRenderFxGlowShell, random(256), random(256), random(256), kRenderTransAlpha, 16)

#define SSTRING 60

// Offsets
const OFFSET_CSTEAMS = 114

// pdata CBase
const m_pPlayer = 41

// pdata Float
const m_flNextPrimaryAttack = 46
const m_flNextAttack = 83

 /* --- Tasks --- */
enum _:TASKS ( += 32 )
{
	TASKID_REMOVE_IMMUNITY = 1581,
	TASKID_REMOVE_INVISIBILITY,
	TASKID_WIN_SPRITE,
	TASKID_HELP,
	
	TASK_CHECK_PLAYERS,
	TASKID_TIMER
}

enum RunningStage
{
	NO_RUN,
	PREPARE,
	RUNNING,
	WIN
}

new RunningStage:g_iRunningStage = NO_RUN

/* --- Save scores for respawn --- */
enum _:SCORES
{
	FRAGS,
	DEATHS
}

new g_iScore[33][SCORES]

enum _:PlayerData
{
	LEVEL,
	EXP,
	POINTS,
	FREE_ITEMS
}

new g_iPlayerData[33][PlayerData]

new g_szLevelsTitle[50] = "\y[HNR] \wAll Players' \rLevels"

/* ---------- Ammo Menu ------------------------ */
enum _:AMMOS
{
	AMOUNT, PRICE
} 

new const gAmmos[][] = {
	/* Ammo	|	Price */
	{ 10	,	10 },
	{ 15	, 	20 },
	{ 30	, 	30 },
	{ 50	, 	40 },
	{ 60	, 	50 }
}

new const Float:PRICE_RATE_FOR_SCOUTS = 1.5
new g_hAmmoMenu

/* ----------  Scout Things  ------------------- */
enum _:SCOUTS
{
	SCOUT_NAME[40],
	Float:SCOUT_FIRE_SPEED,
	SCOUT_BULLETS,
	SCOUT_UNLOCK_LEVEL,
	SCOUT_MODEL[60]
}

new const g_szScoutMenuTitle[] = "\w[\yScout Levels\w] \yHNR Scout Levels"

new const gScoutInfo[][SCOUTS] = {
	/* "Name"  |  Float:Fire Rate | Bullets | Unlock Level | "Model" */
	{ "Beginner Scout", 1.0, 10, 1 , "models/v_scout.mdl" },
	{ "Advanced Scout", 1.2, 20, 10, "models/hnr/v_scout1.mdl" },
	{ "SuperAdv Scout", 1.4, 30, 20, "models/hnr/v_scout2.mdl" },
	{ "Vatican Scout", 1.6, 40,  30, "models/hnr/v_scout3.mdl" },
	{ "Killer Scout", 1.8, 50, 40, "models/hnr/v_scout4.mdl" },
	{ "Killer Scout", 2.0, 60, 50, "models/hnr/v_scout5.mdl" },
	{ "KingDOOM Scout", 2.2, 70, 60, "models/hnr/v_scout6.mdl" },
	{ "Magic Scout", 2.4, 80, 70, "models/hnr/v_scout7.mdl" },
	{ "Euphoria Scout", 2.6, 90, 80, "models/hnr/v_scout8.mdl" },
	{ "Supervisor Scout", 2.8, 100, 90, "models/hnr/v_scout9.mdl" },
	{ ".:~W00W~:. Scout", 3.0, 110, 100, "models/hnr/v_scout10.mdl" }
}

new g_iPlayerScout[33]

/* ------------------- CVARS THINGS ------------------ */
/* --- Main Cvars --- */
enum _:MAIN_CVARS
{
	CVAR_MIN_PLAYERS,
	
	CVAR_START_TIME,
	CVAR_TIMER_TIME,
	CVAR_CELEBRATION_TIME,
	
	CVAR_BLOOD_EFFECT,
	
	CVAR_WINNER_POINTS_MULTIPILER,
	CVAR_WINNER_EXP_MULTIPILER,
	
//	CVAR_DISCONNECT_EXP,
//	CVAR_DISCONNECT_POINTS,
	
	CVAR_SHAKE_DURATION,
	CVAR_SHAKE_FREQUENCY,
	CVAR_SHAKE_AMPLITUDE,
}

new const g_szCvarInfo[MAIN_CVARS][][] = {
	{ "hnr_min_players", "2", "Minimum Players Required To start the game" },
	
	{ "hnr_start_time", "8.5", "Delay before starting a game in new round" },
	{ "hnr_timer_time", "20.0", "Timer for each bomber picked randomlly" },
	{ "hnr_celebration_time", "18.0", "Celebration time before new round starts\n(Before players are spawned)" },
	
	{ "hnr_blood_effect", "0", "Show blood when hitting someone?" },
	
	{ "hnr_winner_points_multipiler", "1", "Win points multipiler\nPlayers Number * multipiler = Winner Points" },
	{ "hnr_winner_exp_multipiler", "1.5", "Winner Exp multipiler\nPlayers Number * multipiler = Winner EXP" },
	
//	{ "hnr_bomb_exp_decrement_disconnect", "0" },
//	{ "hnr_bomb_points_decrement_disconnect", "0" },
	
	{ "hnr_shake_duration", "4", "When the bomber gets choosed by a way, shake duration is?" },
	{ "hnr_shake_frequency", "255", "Shake frequency" },
	{ "hnr_shake_amplitude", "255", "Shake Amplitude\nPut higher shake is stronger" }
}

new g_pCvars[MAIN_CVARS]

/* ---- WIN EFFECT CVARS AND BITS ---- */
enum ( <<= 1 )
{
	EFFECT_TORUS = 1,
	EFFECT_CYLINDER,
	EFFECT_DISK,
}

enum _:WIN_EFFECTS_CVARS
{
	CVAR_WIN_EFFECT,
	CVAR_DELAY_BETWEEN_WIN_SPRITE,
	CVAR_EFFECTS_SAME_COLOR,
	
	CVAR_TORUS_AMPLITUDE,
	CVAR_TORUS_BRIGHTNESS,
	CVAR_TORUS_WIDTH,
	
	CVAR_CYLINDER_AMPLITUDE,
	CVAR_CYLINDER_BRIGHTNESS,
	CVAR_CYLINDER_WIDTH,
	
	CVAR_DISK_AMPLITUDE,
	CVAR_DISK_BRIGHTNESS,
	CVAR_DISK_WIDTH
}

new const g_szEffectsCvarsInfo[WIN_EFFECTS_CVARS][][] = {
	{ "hnr_win_effects", "abc", "Winner Effects (Things that come of of him)\na - Torus\nb - Cylinder\nc - Disk\nYou can put all in one like this ^"abc^"" },
	{ "hnr_delay_between_win_sprite", "0.35", "Delay between each effects action" },
	{ "hnr_effects_same_color", "1", "All effects (In one time) have the same colors?" },
	
	{ "hnr_torus_amplitude", "255", "Torus Power Max 255" },
	{ "hnr_torus_brightness", "255", "Brightness? Max 255" },
	{ "hnr_torus_width", "15", "Line Width?\nMax 255" },
	
	{ "hnr_cylinder_amplitude", "0", "Cylinder Power\nMax 255" },
	{ "hnr_cylinder_brightness", "255", "Brightness\nMax 255" },
	{ "hnr_cylinder_width", "70", "Cylinder Line Width" },
	
	{ "hnr_disk_amplitude", "0", "Amplitude (Rage/Power)" },
	{ "hnr_disk_brightness", "255", "Brightness" },
	{ "hnr_disk_width", "70", "Width" }
}

new g_pEffectsCvars[WIN_EFFECTS_CVARS]

/* --- SHOP CVARS --- */
enum _:SHOP_ITEMS
{
	ITEM_M4A1,
	ITEM_INVISIBILITY,
	ITEM_SPEED,
	ITEM_IMMUNITY,
	//ITEM_PASS_GLOW,
	ITEM_FREE
}

new g_szShopTitle[] = "\w[\yHNR Shop\w] What would you like to buy?"

new const g_szShopItems[SHOP_ITEMS][] = {
	"\rM4\w-A1 with %d bullets!",
	"\rInvisibility \wfor %d seconds!",
	"\rSpeed \wfor a game!",
	"\rImmunity \wfor %d seconds!",
	//"\rAble to pass glow always \wfor a game!",
	"\r%d free items on shop \wuntil you buy!"
}

new g_szShopBuy[SHOP_ITEMS][] = {
	"You have bought an ^4M4-A1 ^3with ^4%d BULLETS!",
	"You have bought ^4Invisibility ^3and it will last for ^4%d SECONDS!",
	"^3You have bought ^4Speed^3. ^4Run FAST!!!",
	"You have bought ^4Immunity ^3against being the ^4GLOW^3. It will last for ^4%d SECONDS!",
	//"You have passed the "
	"You have bought ^4%d Free Items^3. They will be saved for you until you buy!"
}

enum _:SHOP_CVARS
{
	CVAR_M4A1_PRICE,
	CVAR_M4A1_AMMO,
	
	CVAR_INVISIBILITY_PRICE,
	CVAR_INVISIBILITY_TIME,
	
	CVAR_SPEED_PRICE,
	CVAR_SPEED_AMOUNT,
	
	CVAR_IMMUNITY_PRICE,
	CVAR_IMMUNITY_TIME,
	
	//CVAR_PASS_GLOW_PRICE,
	
	CVAR_FREE_ITEMS_PRICE,
	CVAR_FREE_ITEMS_AMOUNT
}

new g_pShopCvars[SHOP_CVARS]

new const g_iItemsCvars[SHOP_ITEMS][] = {
	/* PRICE CVAR	  |  OTHER CVAR IF EXISTS, IF NOT PUT -1 */
	{ CVAR_M4A1_PRICE, CVAR_M4A1_AMMO }, 
	{ CVAR_INVISIBILITY_PRICE, CVAR_INVISIBILITY_TIME },
	{ CVAR_SPEED_PRICE, CVAR_SPEED_AMOUNT }, 
	{ CVAR_IMMUNITY_PRICE, CVAR_IMMUNITY_TIME },
	//{ CVAR_PASS_GLOW_PRICE, -1 },
	{ CVAR_FREE_ITEMS_PRICE, CVAR_FREE_ITEMS_AMOUNT }
}

new const g_szShopCvarsInfo[SHOP_CVARS][][] = {
	{ "hnr_m4a1_price", "15", "M4A1 Price in points" },
	{ "hnr_m4a1_ammo", "50", "M4A1 Ammo" },
	
	{ "hnr_invisiblity_price", "20", "Invisibility Price" },
	{ "hnr_invisiblity_time", "60.0", "Invisibility stay time" },
	
	{ "hnr_speed_price", "25", "Speed Price" },
	{ "hnr_speed_amount", "2.0", "Speed multipiler\nSpeed = Current Weapon Speed * Multipiler" },
	
	{ "hnr_immunity_price", "30", "Immunity Price" },
	{ "hnr_immunity_time", "100.0", "Immunity Stay Time" },
	
//	{ "hnr_pass_glow_price", "35" },
	
	{ "hnr_free_items_price", "70", "Free Items (item in shop) price" },
	{ "hnr_free_items_amount", "3", "Free items amount that is given to a player once he buys it" }
}
	

/* --- REQUIRED CVARS EXECUTE, POINTERS, ALSO OLD VALUE SAVE --- */
enum _:REQUIRED_CVARS
{
	CVAR_NAME[30],
	CVAR_VALUE_STRING[10],
	POINTER
}

new gRequiredCvars[][REQUIRED_CVARS] = {
	{ "humans_join_team", "T", 0 },
	#if defined BOT_SUPPORT
	{ "bot_join_team", "T", 0 },
	{ "bot_join_after_player", "0", 0 },
	#endif
	{ "mp_limitteams", "0", 0 },
	{ "mp_autoteambalance", "0", 0 },
	{ "mp_friendlyfire", "1", 0 }/*,
	{ "mp_tkpunish", "0", 0 }*/
}

/* --- HUD Messages --- */
enum _:HUD_PARAMETER
{
	Float:X, Float:Y, Float:HOLD_TIME, Float:FADE_IN, Float:FADE_OUT
}

enum _:HUDS
{
	WIN,
	GAME_PREPARE,
	NEW_BOMBER_HIT,
	NEW_BOMBER_RANDOM,
	TIMER,
	
	HELP
}

enum _:HUD_COLORS_FOR_NORMAL_MESSAGES
{
	R = 255,
	G = 0,
	B = 0
}

new const Float:HUD_POS[HUDS][HUD_PARAMETER] = {
	// Win
	{ -1.0, -1.0 , 12.0, 0.1, 0.1 },
	// Game prepare
	{ -1.0, 0.65, 0.0 /* FROM A CVAR */, 0.1, 0.1 },
	// New bomber (From HIT)
	{ -1.0, 0.70, 6.5, 0.1, 0.1 },
	// New bomber (Randomly chosen)
	{ -1.0, 0.75, 6.0, 0.1, 0.1 },
	// Timer !!
	{ -1.0, 0.60, 0.1, 0.0, 0.0 },
	
	// HELP MESSAGE
	{ -1.0, 0.25, 1.0, 0.1, 0.1 }
}

// Chats & HUDS
new const g_szHuds[ _:HUDS - 1 ][] = { 
	"And the winner is... %s!!!",			// Win
	"The game is about to BEGIN!^nHit And Run...",	// Game Prepare
	"%s was last hit!",				// New bomber by hit
	"%s was randomally picked!",			// New bomber (randomly picked)
	"Time Left: %0.1f Seconds!"			// Bomb Timer
}

// HUD MESSAGE Handler ..
new g_iCurrentHud
#define SET_HUD_MESSAGE() set_hudmessage(R, G, B, HUD_POS[g_iCurrentHud][X], HUD_POS[g_iCurrentHud][Y], 0, 0.0, HUD_POS[g_iCurrentHud][HOLD_TIME], HUD_POS[g_iCurrentHud][FADE_IN], HUD_POS[g_iCurrentHud][FADE_OUT], -1)

// -- Basic Stuff --
new MAIN_WEAPON[] = "weapon_scout"

// -- Vars --
new g_iWeaponIndex
new g_iMaxPlayers

// Bomber Id
new g_iBombId
new Float:g_flTimer = 0.0

// Can join after game started
new bool:g_bCanJoin = true

#if defined RESTART_METHOD
// Block the round will restart in x seconds message
new bool:g_bRestart = false
#endif

// Game is currently running ? (ENOUGH PLAYERS ARE IN SERVER?)
new bool:g_bGameRunning

// -- MsgIds --
new gMsgIdScreenShake
new gMsgIdTeamInfo, gMsgIdSayText

// -- Handlers --
new Trie:g_hObjectives
new g_hEntSpawnForward

new gHnrAdminMenu
new g_iUsedSpecCmd[33]

// Saving data
new g_hVault

// For HUD Messages
//new g_hHelpHud, g_hTimerHud
new g_hBomberHud
new g_hGlobalAnnounces

// For Win Effects
new g_iWinnerId

// For bomb killed EXP
enum _:REWARDS
{
	REWARD_EXP, REWARD_POINTS
}

new g_iRounds = 0, g_iRewards[REWARDS]

// sv_restart Cvar Pointer
#if defined RESTART_METHOD
new g_pRestart
#endif

#if defined BOT_SUPPORT
new g_iBotsRegistered = 0
#endif

// Bits & Macros
#define IsPlayer(%1) ( 0 < %1 <= g_iMaxPlayers )

#define IsInBit(%0,%1) ( %0 & (1<<%1) )
#define AddToBit(%0,%1) ( %0 |= (1<<%1) )
#define RemoveFromBit(%0,%1) ( %0 &= ~(1<<%1) )
new gHelp, gSpec, gNoSounds
new gImmunity, gInvisible, gSpeed
new gAlive

// /help command HUD Message
new const g_szHelpHud[] = {
	"------------------Hit And Run------------------^n\
	^n\
	This server is running a Hit And Run Plugin\
	^n\
	In HitAndRunyou need to run away from man in GLOW,^n\
	the man in GLOW dies when time ends.^n\
	When you GLOW your screen will shake,then you need^n\
	to hit someone to pass the GLOW.^n\
	The last surviver wins!^n\
	^n\
	Commands: /shop, /points, /free,^n\
	/scout, /xp, /levels, /mute,^n\
	To stop the game sounds type /sound^n\
	^n\
	Type /help again to close this text."
	//	This plugin has been scripted by Khalid :)^n" // NO!
}

// - - - - - - - - - - - - WIN STUFF - - - - - - - - - - - - - - - -
new g_iLaserBeamIndex

new g_szAlarmSound[] = "alarm-clock.mp3"
new g_szChooseBomberSound[] = "alarm-thriller.mp3"
new g_szStartGameSound[] = "start.wav"
new g_szLightingSound[] = "ambience/thunder_clap.wav"

new g_iAlarmSoundIndex, g_iChooseBomberSoundIndex, g_iStartGameSoundIndex
new g_iLightingSoundIndex

// Bit
new gMp3Files

new g_szWinSounds[][] = {
	"win1.mp3",
	"win2.mp3", 
	"win3.mp3",
	"win4.mp3",
	"win5.mp3",
	"win6.mp3",
	"win7.mp3",
	"win8.mp3",
	"win9.mp3",
//	"win10.mp3",
	"win11.mp3",
	"win12.mp3"	
}

// ----------------------- SHOP ----------------------------------------

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
// -------------------------- Code start :) ----------------------------
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

/* ------------ STOCKS ----------------- */

stock PrecacheSound(szFile[], iNum, iCustomDir = 1)
{	
	new szFolderDir[60]
	if( ( equali(szFile[strlen(szFile) - 4], ".mp3") ) )
	{
		if(iCustomDir)
		{
			formatex(szFolderDir, charsmax(szFolderDir), "sound/hnr/%s", szFile)
		}
		
		if(!file_exists(szFolderDir))
		{
			return;
		}
		
		precache_generic(szFolderDir)
		AddToBit(gMp3Files, iNum + 1)
	}
	
	else
	{
		new szCheckDir[80]
		if(iCustomDir)
		{
			formatex(szFolderDir, charsmax(szFolderDir), "hnr/%s", szFile)
		}
		
		else
		{
			formatex(szFolderDir, charsmax(szFolderDir), szFile)
		}
		
		formatex(szCheckDir, charsmax(szCheckDir), "sound/%s", szFolderDir)
		if(!file_exists(szCheckDir))
		{
			return;
		}
		
		precache_sound(szFolderDir)
	}
}

stock PlaySound(szFile[] = "", iIndex, iCustomDir = 1)
{
	static iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "ch")
	
	new szSound[60]
	
	
	
	if(!szFile[0] && iIndex)
	{
		copy(szSound, charsmax(szSound), g_szWinSounds[iIndex])
	}
	
	else if(szFile[0])
	{
		copy(szSound, charsmax(szSound), szFile)
	}
	
	if(IsInBit(gMp3Files, iIndex + 1))
	{
		for(new i; i < iNum; i++)
		{
			if( IsInBit( gNoSounds, ( iPlayer = iPlayers[i] ) ) )
			{
				continue;
			}
			
			switch(iCustomDir)
			{
				case 0:
				{
					client_cmd(iPlayer, "mp3 play ^"%s^"", szSound)
				}
				
				default:
				{
					client_cmd(iPlayer, "mp3 play ^"sound/hnr/%s^"", szSound)
				}
			}
		}
	}
	
	else
	{
		for(new i; i < iNum; i++)
		{
			if( IsInBit( gNoSounds, ( iPlayer = iPlayers[i] ) ) )
			{
				continue;
			}
			
			switch(iCustomDir)
			{
				case 0:
				{
					client_cmd(iPlayer, "spk ^"%s^"", szSound)
				}
				
				default:
				{
					client_cmd(iPlayer, "spk ^"hnr/%s^"", szSound)
				}
			}
		}
	}
}

stock UnSetBomber(id)
{
	set_user_rendering(id)
	if(get_pdata_int(id, OFFSET_CSTEAMS) == 2)
	{
		set_pdata_int(id, OFFSET_CSTEAMS, 2)
	}
}

stock GetPlayerData(id, szSave[])
{
	g_iPlayerScout[id] = 1 /* Default Scout */
	
	static szValue[100]
	static iTimeStamp
	if(!nvault_lookup(g_hVault, szSave, szValue, charsmax(szValue), iTimeStamp))
	{
		formatex(szValue, charsmax(szValue), "^"0^" ^"%d^" ^"0^"", START_LEVEL * LEVEL_EXP)
		nvault_set(g_hVault, szSave, szValue)
		
		g_iPlayerData[id][POINTS] = 0
		g_iPlayerData[id][EXP] = 0
		g_iPlayerData[id][LEVEL] = START_LEVEL
		g_iPlayerData[id][FREE_ITEMS] = 0
		return;
	}
	
	static szPoints[SSTRING], szExp[SSTRING], szFreeItems[SSTRING]
	parse(szValue, szPoints, charsmax(szPoints), szExp, charsmax(szExp), szFreeItems, charsmax(szFreeItems))
	
	static iNum
	iNum = str_to_num(szExp)
	
	g_iPlayerData[id][POINTS] = str_to_num(szPoints)
	g_iPlayerData[id][FREE_ITEMS] = str_to_num(szFreeItems)
	
	g_iPlayerData[id][EXP] = ( iNum % LEVEL_EXP )
	g_iPlayerData[id][LEVEL] = ( iNum / LEVEL_EXP )
	
	if(g_iPlayerData[id][LEVEL] <= 0)
	{
		g_iPlayerData[id][LEVEL] = START_LEVEL
	}
}

stock SavePlayerData(id)
{
	static szCode[50];
	#if defined SAVE_BY_NAME
	formatex(szCode, charsmax(szCode), "^"%s^"", get_player_name(id))
	#else
	get_user_authid(id, szCode, charsmax(szCode))
	#endif
	
	static szDump[2]
	static iTimeStamp
	
	new szValue[ SSTRING * ( PlayerData - 1 ) ]
	formatex(szValue, charsmax(szValue), "^"%d^" ^"%d^" ^"%d^"", g_iPlayerData[id][POINTS], ( g_iPlayerData[id][LEVEL] * LEVEL_EXP ) + g_iPlayerData[id][EXP], g_iPlayerData[id][FREE_ITEMS])
	
	if(nvault_lookup(g_hVault, szCode, szDump, 1, iTimeStamp))
	{
		nvault_remove(g_hVault, szCode)
	}
	
	nvault_set(g_hVault, szCode, szValue)
}

stock TempEntity(iType, iOrigin[3], iZVectorIncrement, iSpriteIndex, r = -1, g = -1, b = -1, iBrightness, iAmplitude, iWidth)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	{
		write_byte(iType)
		write_coord(iOrigin[0])				// position.x
		write_coord(iOrigin[1])				// position.y
		write_coord(iOrigin[2])				// position.z
		write_coord(iOrigin[0])   			// axis.x
		write_coord(iOrigin[1])   			// axis.y
		write_coord(iOrigin[2]  + iZVectorIncrement )			// axis.z
		write_short(iSpriteIndex)			// sprite index
		write_byte(0)      				// starting frame
		write_byte(1)       				// frame rate in 0.1's
		write_byte(7)        				// life in 0.1's
		write_byte(iWidth)	       			// line width in 0.1's
		write_byte(iAmplitude)        			// noise amplitude in 0.01's
		write_byte(r == -1 ? random(256) : r)		// r
		write_byte(g == -1 ? random(256) : g)		// g
		write_byte(b == -1 ? random(256) : b)		// b
		write_byte(iBrightness)				// brightness
		write_byte(15 / 20)					// scroll speed in 0.1's
		//write_byte(0)					// scroll speed in 0.1's
	}	
	message_end()
}

stock DeathEffect(id)
{
	new iOrigin[3]
	get_user_origin(id, iOrigin, 0)
	
	TempEntity(
	TE_BEAMPOINTS,
	iOrigin,
	500,
	g_iLaserBeamIndex,
	0, 0, 255,
	255,
	50,
	25 )
}

stock ReadEffectCvar()
{
	static szValue[5]
	get_pcvar_string(g_pEffectsCvars[CVAR_WIN_EFFECT], szValue, charsmax(szValue))
	
	return read_flags(szValue)
}

stock CountPlayers()
{
	new iCount
	for(new id = 1; id <= g_iMaxPlayers; id++)
	{
		if(is_user_connected(id))
		{
			if(cs_get_user_team(id) == CS_TEAM_T)
			{
				iCount++
			}
		}
	}
	
	return iCount
}

stock bool:CanJoin()
{
	if(!g_bCanJoin)
	{
		return false;
	}
	
	return true;
}

stock GiveItems(id)
{	
	//strip_user_weapons(id)
	RemoveOtherWeapons(id)
	
	if(!user_has_weapon(id, CSW_KNIFE))
	{
		give_item(id, "weapon_knife")
	}
	
	if(user_has_weapon(id, g_iWeaponIndex))
	{
		new iEnt
		new iAmmo = cs_get_weapon_ammo( ( iEnt = find_ent_by_owner(g_iMaxPlayers, MAIN_WEAPON, id) ) )
		
		if(iAmmo < gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_BULLETS])
		{
			cs_set_weapon_ammo(iEnt, gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_BULLETS])
			cs_set_user_bpammo(id, g_iWeaponIndex, 0)
		}
	}
	
	else
	{
		cs_set_weapon_ammo(give_item(id, MAIN_WEAPON), gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_BULLETS])
		cs_set_user_bpammo(id, g_iWeaponIndex, 0)
	}
	
	if(!user_has_weapon(id, CSW_FLASHBANG))
	{
		give_item(id, "weapon_flashbang")
	}
	
	cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
	
	if(!user_has_weapon(id, CSW_HEGRENADE))
	{
		give_item(id, "weapon_hegrenade")
	}
	
	if(!user_has_weapon(id, CSW_SMOKEGRENADE))
	{
		give_item(id, "weapon_smokegrenade")
	}
}

stock RemoveOtherWeapons(id)
{
	new const iInvalidWeaponsBit = ( (1<<g_iWeaponIndex) | (1<<CSW_HEGRENADE) |\
	(1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_KNIFE) | (1<<CSW_C4) )\
	| (1<<CSW_M4A1) | (1<<2) /* No weapon with number 2 */
	
	new iWeapons = pev(id, pev_weapons)
	//new szClassName[32]
	
	for(new i = CSW_P228; i < CSW_VEST; i++)
	{	
		if((1<<i) & iInvalidWeaponsBit)
		{
			continue;
		}
		
		if(iWeapons & (1<<i))
		{
			
			/*iWeapons |= ~(1<<i)
			set_pev(id, pev_weapons ,iWeapons)
			get_weaponname(i, szClassName, charsmax(szClassName))
			
			ExecuteHam(Ham_RemovePlayerItem, id, find_ent_by_class(g_iMaxPlayers, szClassName))*/
			ham_strip_user_weapon(id, i)
		}
	}
}

stock ham_strip_user_weapon(id, iCswId, iSlot = 0, bool:bSwitchIfActive = true)
{
	new iWeapon;
	if( !iSlot )
	{
		static const iWeaponsSlots[CSW_P90 + 1] = {
			-1, 2, -1, 1, 4, 1, 5, 1, 1, 4, 
			2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 
			1, 1, 1, 1, 4, 2, 1, 1, 3, 1 
		}
	
		iSlot = iWeaponsSlots[iCswId];
	}
	
	static const XO_CBASEPLAYERITEM = 4;
	static const m_rgpPlayerItems_CBasePlayer[6] = { 367 , 368 , ... }
	static const m_pNext = 42;
	static const m_iId = 43;
	static const m_pActiveItem = 373

	iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_CBasePlayer[iSlot]);

	while( iWeapon > 0 )
	{
		if( get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM) == iCswId )
		{
			break;
		}
		
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
	}

	if( iWeapon > 0 )
	{
		if( bSwitchIfActive && get_pdata_cbase(id, m_pActiveItem) == iWeapon )
		{
			ExecuteHamB(Ham_Weapon_RetireWeapon, iWeapon);
		}

		if( ExecuteHamB(Ham_RemovePlayerItem, id, iWeapon) )
		{
			user_has_weapon(id, iCswId, 0);
			ExecuteHamB(Ham_Item_Kill, iWeapon);
			return 1;
		}
	}

	return 0;
}  

enum Sounds
{
	SOUND_NO,
	SOUND_NEW_GAME_START,
	SOUND_NEW_BOMBER_CHOOSED
}

stock SetBomber(id = 0, iReset = 1, Sounds:iPlaySound = SOUND_NO)
{
	if(!id)
	{
		new iPlayers[32], iNum
		get_players(iPlayers, iNum, "ah")

		id = iPlayers[random_num(0, iNum - 1)]
		g_iCurrentHud = NEW_BOMBER_RANDOM
		
		#if defined BOT_SUPPORT
		if(is_user_bot(g_iBombId))
		{
			set_pdata_int(g_iBombId, OFFSET_CSTEAMS, 1)
		}
		
		if(is_user_bot(id))
		{			
			set_pdata_int(id, OFFSET_CSTEAMS, 2)
		}
		#endif
	}
	
	else
	{
		UnSetBomber(g_iBombId)
		g_iCurrentHud = NEW_BOMBER_HIT
	}
	
	BomberEffects(id)
	g_iBombId = id
	
	SET_HUD_MESSAGE()

	ShowSyncHudMsg(0, g_hBomberHud, g_szHuds[g_iCurrentHud], get_player_name(id))
	
	if(iReset)
	{
		g_flTimer = get_pcvar_float(g_pCvars[CVAR_TIMER_TIME]) + 0.1
	}
	
	switch(iPlaySound)
	{
		case SOUND_NEW_GAME_START:
		{
			PlaySound(g_szStartGameSound, g_iStartGameSoundIndex)
		}
		
		case SOUND_NEW_BOMBER_CHOOSED:
		{
			PlaySound(g_szChooseBomberSound, g_iChooseBomberSoundIndex)
		}
	}
}

stock BomberEffects(id)
{
	BomberGlow(id)
	UTIL_ScreenShake(id)
}

stock Winner(id)
{
	remove_task(TASKID_TIMER)
	remove_task(TASKID_WIN_SPRITE)
	
	ClearSyncHud(0, g_hGlobalAnnounces)
	
	g_bCanJoin = false
	g_iWinnerId = id
	g_iBombId = 0
	
	set_task(get_pcvar_float(g_pCvars[CVAR_CELEBRATION_TIME]), "Restart")
	
	g_iCurrentHud = WIN
	SET_HUD_MESSAGE()
	ShowSyncHudMsg(0, g_hGlobalAnnounces, g_szHuds[g_iCurrentHud], get_player_name(id))

	WinSpriteEffect(TASKID_WIN_SPRITE)
	set_task(get_pcvar_float(g_pEffectsCvars[CVAR_DELAY_BETWEEN_WIN_SPRITE]), "WinSpriteEffect", TASKID_WIN_SPRITE, .flags = "b")
	
	new iRan = random_num(0, sizeof(g_szWinSounds) - 1)
	PlaySound(g_szWinSounds[iRan], iRan)
	
	Color(id, "^4Congratulations! ^3You have won ^4%d Points ^3and ^4%d EXP ^3for winning the game!", g_iRewards[REWARD_POINTS], g_iRewards[REWARD_EXP])
	Color(0, "^3The winner ^4%s ^3has won ^4%d Points ^3for the win, ^4Congratulations^3!", get_player_name(id), g_iRewards[REWARD_POINTS])
	
	GiveExp(id, g_iRewards[REWARD_EXP])
	g_iPlayerData[id][POINTS] += g_iRewards[REWARD_POINTS]
	
	g_iRunningStage = RunningStage:WIN
}

stock GiveExp(id, iAmount)
{
	while( (g_iPlayerData[id][EXP] += iAmount ) > LEVEL_EXP)
	{
		g_iPlayerData[id][EXP] -= 100
		g_iPlayerData[id][LEVEL]++

		Color(0, "^4Congratulations for player ^3%s ^4He just got a level!", get_player_name(id))
	}
}

stock UTIL_ScreenShake(id)
{
	static iShakeDuration, iShakeAmplitude, iShakeFrequency
	
	new Float:flShakeDuration = get_pcvar_float(g_pCvars[CVAR_SHAKE_DURATION])
	new Float:flShakeAmplitude = get_pcvar_float(g_pCvars[CVAR_SHAKE_AMPLITUDE])
	new Float:flShakeFrequency = get_pcvar_float(g_pCvars[CVAR_SHAKE_FREQUENCY])
	
	iShakeDuration = __FixedUnsigned16(flShakeDuration, 1<<12)
	iShakeAmplitude = __FixedUnsigned16(flShakeAmplitude, 1<<12)
	iShakeFrequency = __FixedUnsigned16(flShakeFrequency, 1<<8)
	
	message_begin(MSG_ONE, gMsgIdScreenShake, .player = id)
	write_short(iShakeAmplitude)
	write_short(iShakeDuration)
	write_short(iShakeFrequency)
	message_end()
}

stock __FixedUnsigned16(Float:flValue, iScale) 
{ 
	new iOutput; 

	iOutput = floatround(flValue * iScale) 

	if ( iOutput < 0 ) 
		iOutput = 0 

	if ( iOutput > 0xFFFF ) 
		iOutput = 0xFFFF 

	return iOutput 
}

stock CanBuy(id, item)
{
	if(!IsInBit(gAlive, id))
	{
		Color(id, "You need to be alive to buy an item")
		return 0
	}
	
	if(g_iPlayerData[id][FREE_ITEMS])
	{
		g_iPlayerData[id][FREE_ITEMS]--
		return 1
	}
	
	static iItemCost
	if(g_iPlayerData[id][POINTS] < ( iItemCost = get_pcvar_num( g_pShopCvars[ g_iItemsCvars[ item ][ 0 ] ] ) ) )
	{
		Color(id, "You don't have enough points to buy that item!")
		return 0
	}
	
	if(item == ITEM_M4A1 && user_has_weapon(id, CSW_M4A1))
	{
		Color(id, "You already have that item!")
		return 0
	}
	
	static iAllow; iAllow = 1
	switch(item)
	{
		case ITEM_IMMUNITY:
		{
			if( IsInBit(gImmunity, id) )
			{
				iAllow = 0
			}
		}
		
		case ITEM_SPEED:
		{
			if( IsInBit(gSpeed, id) )
			{
				iAllow = 0
			}
		}
		
		case ITEM_INVISIBILITY:
		{
			if( IsInBit(gInvisible, id) )
			{
				iAllow = 0
			}
		}
	}
	
	if(!iAllow)
	{
		Color(id, "You already have that item!")
	}
	
	else
	{
		g_iPlayerData[id][POINTS] -= iItemCost
	}
	
	return iAllow
}

stock GiveShopItem(id, item, Float:flNum)
{
	switch(item)
	{
		case ITEM_INVISIBILITY:
		{
			AddToBit(gInvisible, id)
			set_user_rendering(id, kRenderFxNone, _, _, _, kRenderTransAlpha, 0)
			
			set_task(flNum, "RemoveInvisibility", id + TASKID_REMOVE_INVISIBILITY)
		}
		
		case ITEM_SPEED:
		{
			AddToBit(gSpeed, id)
		}
		
		case ITEM_IMMUNITY:
		{
			AddToBit(gImmunity, id)
			set_task(flNum, "RemoveImmunity", id + TASKID_REMOVE_IMMUNITY)
		}
	}
}

stock ShowScoutHud(id, item)
{
	static szHud[150], len, iColors[3], iUnlocked
	
	if(gScoutInfo[item][SCOUT_UNLOCK_LEVEL] <= g_iPlayerData[id][LEVEL])
	{
		iUnlocked = 1
		iColors = { 0, 255, 0 }
	}
	
	else
	{
		iUnlocked = 0
		iColors = { 255, 0, 0 }
	}
	
	set_hudmessage(iColors[0], iColors[1], iColors[2], 0.05, 0.20, 0, 0.0, 12.0, 0.1, 0.1, -1)
	
	len = 0
	len += formatex(szHud[len], charsmax(szHud) - len, "Scout: %s^n", gScoutInfo[item][SCOUT_NAME])
	len += formatex(szHud[len], charsmax(szHud) - len, "Attack Speed: %0.1f faster^n", gScoutInfo[item][SCOUT_FIRE_SPEED])
	len += formatex(szHud[len], charsmax(szHud) - len, "Bullets: %d^n", gScoutInfo[item][SCOUT_BULLETS])
	len += formatex(szHud[len], charsmax(szHud) - len, "UNLOCK at Level: %d^n", gScoutInfo[item][SCOUT_UNLOCK_LEVEL])
	
	len+= formatex(szHud[len], charsmax(szHud) - len, "[THIS SCOUT IS %s]", iUnlocked ? "UNLOCKED" : "LOCKED" )
	
	show_hudmessage(id, szHud)
}

new g_hPlayerMenu[33]
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

stock get_player_name(id)
{
	static szName[32]; get_user_name(id, szName, 31)
	return szName
}

stock ReadCfg()
{
	new CFG_FILE[70]
	get_configsdir(CFG_FILE, charsmax(CFG_FILE))
	add(CFG_FILE, charsmax(CFG_FILE), "/hitandrun.cfg")
	
	new f = fopen(CFG_FILE, "r")
	
	if(f)
	{
		fclose(f)
		server_cmd("exec ^"%s^"", CFG_FILE)
		server_exec()
		return;
	}
	
	f = fopen(CFG_FILE, "w+")
	
	// If file not exists, write new one.
	
	new szLine[250], i = -1, iSize
	
	fputs(f, "// --------------- Main Cvars ----------------^n")
	
	iSize = sizeof(g_szCvarInfo)
	while(++i < iSize)
	{
		szLine = "// "
		copy(szLine[3], charsmax(szLine) - 3, g_szCvarInfo[i][2])
		
		if(contain(szLine, "\n") != -1)
		{
			replace_all(szLine, charsmax(szLine), "\n", "^n// ")
		}
		
		fprintf(f, "%s^n", szLine)
		fprintf(f, "%s ^"%s^"^n^n", g_szCvarInfo[i][0], g_szCvarInfo[i][1])
	}
	
	fputs(f, "// --------------- Shop Cvars ----------------^n")
	iSize = sizeof(g_szShopCvarsInfo)
	i = -1
	szLine[0] = EOS
	
	while(++i < iSize)
	{
		szLine = "// "
		copy(szLine[3], charsmax(szLine) - 3, g_szShopCvarsInfo[i][2])
		
		if(contain(szLine, "\n") != -1)
		{
			replace_all(szLine, charsmax(szLine), "\n", "^n// ")
		}
		
		fprintf(f, "%s^n", szLine)
		fprintf(f, "%s ^"%s^"^n^n", g_szShopCvarsInfo[i][0], g_szShopCvarsInfo[i][1])
	}
	
	fputs(f, "// --------------- Winner Effect Cvars ----------------^n")
	iSize = sizeof(g_szEffectsCvarsInfo)
	i = -1
	szLine[0] = EOS
	
	while(++i < iSize)
	{
		szLine = "// "
		copy(szLine[3], charsmax(szLine) - 3, g_szEffectsCvarsInfo[i][2])
		
		if(contain(szLine, "\n") != -1)
		{
			replace_all(szLine, charsmax(szLine), "\n", "^n// ")
		}
		
		fprintf(f, "%s^n", szLine)
		fprintf(f, "%s ^"%s^"^n^n", g_szEffectsCvarsInfo[i][0], g_szEffectsCvarsInfo[i][1])
	}
	
	fputs(f, "echo [HIT AND RUN] Successfully executed Hit'n'Run Config File^n")
	fprintf(f, "echo [HIT AND RUN] File location is: %s", CFG_FILE)
	
	fclose(f); fclose(f)
	server_print("[HIT AND RUN] Successfully written a new CFG FILE")
}

stock BuildAmmoMenu()
{
	g_hAmmoMenu = menu_create("Choose the ammo that fits your needs", "AmmoMenuHandler")
	
	for(new i, szItem[50]; i < sizeof(gAmmos); i++)
	{
		formatex(szItem, charsmax(szItem), "%d Bullets \y(\w%d \wPoints\y)", gAmmos[i][AMOUNT], gAmmos[i][PRICE])
		menu_additem(g_hAmmoMenu, szItem)
	}
	
	menu_additem(g_hAmmoMenu, "\yFill My Ammo", "Fill")
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
public plugin_precache()
{
	//g_iLaserBeamIndex = precache_model("sprites/laserbeam.spr")
	//g_iLaserBeamIndex = precache_model("sprites/zbeam2.spr")
	g_iLaserBeamIndex = precache_model("sprites/lgtning.spr")
	
	new i
	for(i = 0; i < sizeof(g_szWinSounds); i++)
	{
		//formatex(szFile, charsmax(szFile), "sound/hnr/%s", g_szWinSounds[i])
		//Precache_Sound(szFile, i)
		PrecacheSound(g_szWinSounds[i], i)
	}
	
	//formatex(szFile, charsmax(szFile), "sound/hnr/%s", g_szAlarmSound)
	//Precache_Sound(szFile, i)
	PrecacheSound(g_szAlarmSound, i)
	g_iAlarmSoundIndex = i
	
	//formatex(szFile, charsmax(szFile), "sound/hnr/%s", g_szChooseBomberSound)
	//Precache_Sound(szFile, ++i)
	PrecacheSound(g_szChooseBomberSound, ++i)
	g_iChooseBomberSoundIndex = i
	
	//formatex(szFile, charsmax(szFile), "sound/hnr/%s", g_szStartGameSound)
	//Precache_Sound(szFile, ++i)
	PrecacheSound(g_szStartGameSound, ++i)
	g_iStartGameSoundIndex = i
	
	PrecacheSound(g_szLightingSound, ++i, 0)
	g_iLightingSoundIndex = i
	
	for(i = 0; i < sizeof(gScoutInfo); i++)
	{
		if(!file_exists(gScoutInfo[i][SCOUT_MODEL]))
		{
			new szFailState[100]
			formatex(szFailState, charsmax(szFailState), "PREVENTING CRASH! Model Not found! %s", gScoutInfo[i][SCOUT_MODEL])
			set_fail_state(szFailState)
			
			return;
		}

		precache_model(gScoutInfo[i][SCOUT_MODEL])
	}
	
	// ------------------------------------------------------
	// -------------------- others --------------------------
	// ------------------------------------------------------
	new iEnt = find_ent_by_class(-1, "info_map_parameters")
	
	if(!iEnt)
	{
		iEnt = create_entity("info_map_parameters")
	}
	
	if(is_valid_ent(iEnt))
	{
		DispatchKeyValue(iEnt, "buying", "3")
	}
	
	// Remove map objectives code...
	g_hObjectives = TrieCreate()
	new const szObjectives[][] =
	{
		"func_bomb_target",
		"info_bomb_target",
		"hostage_entity",
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
		"func_buyzone",
		"weaponbox"
	}
	
	for(new i; i < sizeof(szObjectives); i++)
	{
		TrieSetCell(g_hObjectives, szObjectives[i], 1)
	}
	
	g_hEntSpawnForward = register_forward(FM_Spawn, "fw_EntSpawn", 0)
	
	
	// Execute NEEDED CVARS
	new szCvarValue[10]
	for(new i; i < sizeof(gRequiredCvars); i++)
	{
		if(!cvar_exists(gRequiredCvars[i][CVAR_NAME]))
		{
			continue;
		}
		
		gRequiredCvars[i][POINTER] = get_cvar_pointer(gRequiredCvars[i][CVAR_NAME])

		get_pcvar_string(gRequiredCvars[i][POINTER], szCvarValue, 9)
		set_pcvar_string(gRequiredCvars[i][POINTER], gRequiredCvars[i][CVAR_VALUE_STRING])
		gRequiredCvars[i][CVAR_VALUE_STRING] = szCvarValue
	}
}

public fw_EntSpawn(iEnt)
{
	if(!pev_valid(iEnt))
	{
		return;
	}
	
	new szClassName[50]; pev(iEnt, pev_classname, szClassName, 49)

	if(TrieKeyExists(g_hObjectives, szClassName))
	{
		remove_entity(iEnt)
	}
}

/* ------------- COLOR CHAT ------------------- */
enum Colors
{
	NORMAL = 1, 		// clients scr_concolor cvar color
	GREEN, 			// Green Color
	TEAM_COLOR, 		// Red, grey, blue
	GREY, 			// grey
	RED,			// Red
	BLUE, 			// Blue
}
/* ------------- COLOR CHAT ------------------- */

public plugin_init()
{
	register_plugin("Hit 'N' Run", VERSION, AUTHOR)
	
	// --- Check Weapon Stuff ---
	if( !(g_iWeaponIndex = get_weaponid(MAIN_WEAPON)) )
	{
		log_amx("Non existance Main Weapon .. Defaulting to Scout!")
		g_iWeaponIndex = CSW_SCOUT
		MAIN_WEAPON = "weapon_scout"
	}
	
	// --- Remove Ent spawn stuff ---
	unregister_forward(FM_Spawn, g_hEntSpawnForward, 0)
	TrieDestroy(g_hObjectives)
	g_hEntSpawnForward = 0; g_hObjectives = Trie:0
	
	// --- RegisterHam Stuff ---
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 0)
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Pre", 0)
	
	new const Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed", 1)
	
	RegisterHam(Ham_Item_Deploy, MAIN_WEAPON, "fw_ItemDeploy", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, MAIN_WEAPON, "fw_PrimAttack", 1)
	
	// FakeMeta forwards - Not really needed.
	//register_forward(FM_AddToFullPack, "fw_AddToFullPack", 0)
	
	// --- Events ---
	register_event("HLTV",  "eNewRound", "a", "1=0", "2=0")
	
	#if defined AUTO_JOIN
	register_event("TeamInfo", "eTeamInfo", "a")
	#endif
	
	// --- Messages ---
	#if defined AUTO_JOIN
	register_message(get_user_msgid("VGUIMenu"), "message_VGUIMenu")
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu")
	#endif
	register_message(get_user_msgid("TextMsg"), "message_TextMsg")
	
	// --- Admin Console/Client Commands ---
	register_concmd("hnr_set_data", "AdminCmdSetData", ACCESS, "<player> < level - xp - points - freeitems > < + or - or new amount > < amount if previous is - or + > - Set Data to a player")
	
	register_concmd("hnr_menu", "AdminCmdHnrMenu", ACCESS)
	register_clcmd("say /hnr_menu", "AdminCmdHnrMenu", ACCESS)
	
	// --- Client Commands ----
	register_clcmd("chooseteam", "CmdChooseTeam")
	
	#if !defined AUTO_JOIN
	register_clcmd("menuselect", "ClCmd_MenuSelect_JoinClass"); // old style menu
	register_clcmd("joinclass", "ClCmd_MenuSelect_JoinClass"); // VGUI menu
	#endif
	
	register_clcmd("say /help", "CmdHelp")
	register_clcmd("say /sound", "CmdSound")
	
	register_clcmd("say /shop", "CmdShop")
	register_clcmd("say /ammo", "CmdAmmo")
	
	register_clcmd("say /xp", "CmdXpLevel")
	register_clcmd("say /level", "CmdXpLevel")
	register_clcmd("say /points", "CmdPoints")
	register_clcmd("say /free", "CmdFree")
	
	register_clcmd("say /scout", "CmdScout")
	register_clcmd("say /levels", "CmdAllLevels")
	
	#if defined TEST
	register_clcmd("say /model", "CmdMdl")
	register_clcmd("say", "CmdGive")
	#endif
	
	// --- Huds ----
	//g_hHelpHud = CreateHudSyncObj()
	//g_hTimerHud = CreateHudSyncObj(1)
	g_hBomberHud = CreateHudSyncObj()
	g_hGlobalAnnounces = CreateHudSyncObj(1)
	
	// --- CVARS ---
	for(new i; i < sizeof(g_pCvars); i++)
	{
		g_pCvars[i] = register_cvar(g_szCvarInfo[i][0], g_szCvarInfo[i][1])
	}
	
	for(new i; i < sizeof(g_pEffectsCvars); i++)
	{
		g_pEffectsCvars[i] = register_cvar(g_szEffectsCvarsInfo[i][0], g_szEffectsCvarsInfo[i][1])
	}
	
	for(new i; i < sizeof(g_pShopCvars); i++)
	{
		g_pShopCvars[i] = register_cvar(g_szShopCvarsInfo[i][0], g_szShopCvarsInfo[i][1])
	}
	
	#if defined RESTART_METHOD
	g_pRestart = get_cvar_pointer("sv_restart")
	#endif
	
	// --- Message Ids ---
	gMsgIdScreenShake = get_user_msgid("ScreenShake")
	gMsgIdSayText = get_user_msgid("SayText")
	gMsgIdTeamInfo = get_user_msgid("TeamInfo")
	
	// --- Others ---
	g_iMaxPlayers = get_maxplayers()
	
	#if defined SAVE_BY_NAME
	g_hVault = nvault_open("HNR_POINTS_NAME")
	#else
	g_hVault = nvault_open("HNR_POINTS_STEAMID")
	#endif
	
	BuildAdminMenu()
	BuildAmmoMenu()
}

enum _:Choices
{
	CHOICE_WINNER,
	CHOICE_BOMBER,
	CHOICE_SCOUT,
	CHOICE_SHOP
}

new g_iMenuChoice[33][2]
new gHnrAdminScoutMenu
//new gHnrAdminDataHandler

stock BuildAdminMenu()
{
	gHnrAdminMenu = menu_create("\r[Hit And Run] \wAdmin Menu", "AdminMenuHandler")
	{
		menu_additem(gHnrAdminMenu, "Make a player a winner")
		menu_additem(gHnrAdminMenu, "Make a player a bomber(glow) \y(Previous one will be normal player)")
		menu_additem(gHnrAdminMenu, "Give Scout to a Player")
		menu_additem(gHnrAdminMenu, "Give a Shop Item to a player")
		//menu_additem(gHnrAdminMenu, "Give user an \y(\rEXP\y|\rLEVEL\y|\rPOINTS\y|\rFREE ITEMS\y)")
		menu_addtext(gHnrAdminMenu, "\rBy \wKhalid \y:)", 0)
	}
	
	gHnrAdminScoutMenu = menu_create("Choose a scout:", "AdminScoutMenuHandler")
	{
		new szItem[70]
		
		for(new i; i < sizeof(gScoutInfo); i++)
		{
			formatex(szItem, charsmax(szItem), "%s \y(\rSpeed \w%0.1f \y| \rBullets \w%d \y)", gScoutInfo[i][SCOUT_NAME], gScoutInfo[i][SCOUT_FIRE_SPEED], gScoutInfo[i][SCOUT_BULLETS])
			menu_additem(gHnrAdminScoutMenu, szItem)
		}
	}
}

public AdminScoutMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	g_iMenuChoice[id][0] = CHOICE_SCOUT
	
	g_iMenuChoice[id][1] = item
	
	ShowPlayerMenu(id)
}

stock ShowPlayerMenu(id)
{
	new iMenu = CreateMenu(id, "Choose a player", "PlayerMenuHandler")
	{
		new szName[32], iPlayers[32], iNum, szInfo[5]
		get_players(iPlayers, iNum, "he", "TERRORIST")
				
		for(new i; i < iNum; i++)
		{
			num_to_str(iPlayers[i], szInfo, 4)
			get_user_name(iPlayers[i], szName, charsmax(szName))
			menu_additem(iMenu, szName, szInfo)
		}
				
		menu_display(id, iMenu)
	}
}

public AdminMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	g_iMenuChoice[id][0] = -1
	switch(item)
	{
		case 0..1:
		{
			if(g_iRunningStage != RUNNING)
			{
				Color(id, "Please wait until a game starts")
				return;
			}
			
			g_iMenuChoice[id][0] = item
		}
			
		case 2:
		{
			menu_display(id, gHnrAdminScoutMenu)
		}
		
		case 3:
		{
			new iMenu = CreateMenu(id, "Choose an item", "AdminShopMenuHandler")
			for(new i, szItem[60]; i < SHOP_ITEMS; i++)
			{
				if(i == ITEM_FREE)
				{
					continue;
				}
				
				if(g_iItemsCvars[i][1] != -1)
				{
					format(szItem, charsmax(szItem), g_szShopItems[i], get_pcvar_num(g_pShopCvars[g_iItemsCvars[i][1]]))
				}
			
				else
				{
					formatex(szItem, charsmax(szItem), g_szShopItems[i])
				}
			
				menu_additem(iMenu, szItem)
			}
			
			menu_display(id, iMenu)
		}
	}
	
	if(g_iMenuChoice[id][0] > -1)
	{
		ShowPlayerMenu(id)
	}
}

public AdminShopMenuHandler(id, menu, item)
{
	DestroyMenu(id)
	if(item == MENU_EXIT)
	{
		return;
	}
	
	g_iMenuChoice[id][0] = CHOICE_SHOP
	g_iMenuChoice[id][1] = item
	
	ShowPlayerMenu(id)
}

public PlayerMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		DestroyMenu(id)
		return;
	}
	
	new szId[5], iPlayer
	menu_item_getinfo(menu, item, iPlayer, szId, 4, .callback = iPlayer)
	
	DestroyMenu(id)
	
	iPlayer = str_to_num(szId)
	
	new iAlive = 1
	if(!IsInBit(gAlive, iPlayer))
	{
		iAlive = 0
	}
	
	switch(g_iMenuChoice[id][0])
	{
		case CHOICE_BOMBER:
		{
			if(g_iRunningStage != RUNNING)
			{
				return;
			}
			
			if(!iAlive)
			{
				Color(id, "Player must be alive")
				return;
			}
			
			if(iPlayer == g_iBombId)
			{
				Color(id, "Player is already bomber")
				return;
			}
			
			SetBomber(iPlayer, 0)
			Color(0, "Admin %s Made player %s the ^4GLOW (BOMBER)", get_player_name(id), get_player_name(iPlayer))
		}
		
		case CHOICE_WINNER:
		{
			if(!iAlive)
			{
				Color(id, "Player must be alive")
				return;
			}
			
			if(g_iRunningStage != RUNNING)
			{
				return;
			}
			
			new iPlayers[32], iNum
			get_players(iPlayers, iNum, "ah")
			
			#if defined BOT_SUPPORT
			if(is_user_bot(g_iBombId))
			{
				set_pdata_int(g_iBombId, OFFSET_CSTEAMS, 1)
			}
			#endif
			
			for(new i; i < iNum; i++)
			{
				if(iPlayers[i] == iPlayer)
				{
					continue;
				}
				
				user_silentkill(iPlayers[i])
				cs_set_user_team(iPlayers[i], CS_TEAM_SPECTATOR)
			}
			
			Winner(iPlayer)
			Color(0, "Admin %s made player %s ^4WIN THE GAME", get_player_name(id), get_player_name(iPlayer))
		}
		
		case CHOICE_SCOUT:
		{
			if(!is_user_connected(id))
			{
				Color(id, "Player must be connected")
				return;
			}
			
			g_iPlayerScout[iPlayer] = g_iMenuChoice[id][1] + 1
			ChangeModel(id)
			
			new szName[32]; copy(szName, 31, get_player_name(iPlayer))
			Color(id, "You have given player ^4%s ^3scout ^4'%s'^3.", szName, gScoutInfo[g_iMenuChoice[id][1]][SCOUT_NAME])
			Color(id, "Admin %s gave you scout ^4%s", get_player_name(id), gScoutInfo[g_iMenuChoice[id][1]][SCOUT_NAME])
		}
		
		case CHOICE_SHOP:
		{
			if(!is_user_connected(iPlayer))
			{
				Color(id, "Player must be connected")
				return;
			}
			
			if(g_iMenuChoice[id][1] != ITEM_FREE && !iAlive)
			{
				Color(id, "Player must be alive ...")
				return;
			}
			
			switch(g_iMenuChoice[id][1])
			{
				case ITEM_IMMUNITY:
				{	
					new iTime = get_pcvar_num(g_pShopCvars[CVAR_IMMUNITY_TIME])
					GiveShopItem(iPlayer, item, float(iTime))
					
					Color(0, "Admin %s gave %s item ^4IMMUNITY that lasts for %d seconds", get_player_name(id), get_player_name(iPlayer), iTime)
				}
				
				case ITEM_M4A1:
				{	
					if(user_has_weapon(iPlayer, CSW_M4A1))
					{
						return;
					}
					
					new iAmmo = get_pcvar_num(g_pShopCvars[CVAR_M4A1_AMMO])
					cs_set_weapon_ammo(give_item(iPlayer, "weapon_m4a1"), iAmmo)
					
					Color(0, "Admin %s gave %s item ^4M4A1 with %d bullets", get_player_name(id), get_player_name(iPlayer), iAmmo)
				}
				
				case ITEM_INVISIBILITY:
				{
					new iTime = get_pcvar_num(g_pShopCvars[CVAR_INVISIBILITY_TIME])
					GiveShopItem(iPlayer, item, float(iTime))
					
					Color(0, "Admin %s gave %s item ^4INVISIBILITY that lasts for %d seconds", get_player_name(id), get_player_name(iPlayer), iTime)
				}
				
				case ITEM_SPEED:
				{
					new Float:flSpeed = get_pcvar_float(g_pShopCvars[CVAR_SPEED_AMOUNT])
					GiveShopItem(id, item, flSpeed)
					
					Color(0, "Admin %s gave %s item ^4SPEED that lasts for one game", get_player_name(id), get_player_name(iPlayer))
				}
				
				/*case ITEM_FREE:
				{
					new iNum = get_pcvar_num(g_pShopCvars[CVAR_FREE_ITEMS_AMOUNT])
					g_iPlayerData[id][FREE_ITEMS] += iNum
					
					Color(0, "Admin %s gave %s %d free items", 
				}*/
				
				/*case ITEM_PASS_GLOW:
				{
					Color(id, g_szShopBuy[item])
					//ShopItemHudMessage(id, item)
				}*/
			}
		}
	}	
}

public plugin_cfg()
{
	ReadCfg()
}

public plugin_end()
{
	for(new i; i < sizeof(gRequiredCvars); i++)
	{
		if(gRequiredCvars[i][POINTER])
		{
			set_pcvar_string(gRequiredCvars[i][POINTER], gRequiredCvars[i][CVAR_VALUE_STRING])
		}
	}
}

enum _:ARGS
{
	ARG_CMD,
	ARG_PLAYER,
	ARG_DATA,
	ARG_OPERATOR,
	ARG_AMOUNT
}

stock GetDataType(szData[])
{
	static const szTypes[PlayerData][][] = {
		{ "level", "playerlevel", "" },
		{ "exp", "xp", "experience" },
		{ "points", "shoppoints", "playerpoints" },
		{ "freeitems", "free_items", "free items" }
	}
		
	for(new i; i < PlayerData; i++)
	{
		for(new b; b < sizeof(szTypes[]); b++)
		{
			if(szTypes[i][b][0] && equali(szData, szTypes[i][b]))
			{
				return i;
			}
		}
	}
	
	return -1
}

public AdminCmdSetData(id, level, cid)
{
	if(!cmd_access(id, level, cid, 4))
	{
		return PLUGIN_HANDLED
	}
	
	static const szData[][] = {
		"Level",
		"XP",
		"Points",
		"Free Items"
	}
	
	new szArgs[ARGS][50]
	new iCount = read_argc()
	for(new iArgs = 1; iArgs < iCount; iArgs++)
	{
		read_argv(iArgs, szArgs[iArgs], charsmax(szArgs[]))
	}
	
	new iData = GetDataType(szArgs[ARG_DATA])
	
	if(iData == -1)
	{
		console_print(id, "Choose an appropriate data type from level, xp, points, freeitems")
		return PLUGIN_HANDLED
	}
	
	new iTeam  = 0, szTeam[20], iPlayers[32], iNum
	new iPlayer = cmd_target(id, szArgs[ARG_PLAYER], CMDTARGET_ALLOW_SELF)
	
	if(!iPlayer)
	{
		if(szArgs[ARG_PLAYER][0] == '@')
		{
			switch(szArgs[ARG_PLAYER][1])
			{
				case 'A':
				{
					iTeam = 3
					get_players(iPlayers, iNum, "h")
					szTeam = "ALL"
				}
				
				case 'T':
				{
					iTeam = 1
					get_players(iPlayers, iNum, "he", "TERRORIST")
					szTeam = "TERRORIST"
				}
				
				case 'C':
				{
					iTeam = 2
					get_players(iPlayers, iNum, "he", "CT")
					
					szTeam = "CT"
				}
				
				default:
				{
					iTeam = 0
					console_print(id, "Team is invalid!")
				}
			}
		}
		
		if(!iTeam)
		{
			console_print(id, "Player could not be targetted")
			return PLUGIN_HANDLED
		}
	}
	
	switch(iCount)
	{
		case 4:
		{
			if(!is_str_num(szArgs[ARG_OPERATOR]))
			{
				console_print(id, "Error in Amount argument! IT MUST BE A NUMBER")
				return PLUGIN_HANDLED
			}
			
			new b = str_to_num(szArgs[ARG_OPERATOR])
			if(b < 1 || !b)
			{
				console_print(id, "Put a right Number! -.-")
				return PLUGIN_HANDLED
			}
			
			if(!iPlayer && iTeam)
			{
				for(new i; i < iNum; i++)
				{
					g_iPlayerData[iPlayers[i]][iData] = b
				}
				
				Color(id, "ADMIN ^4%s: ^3Set ^%s ^3players ^4%s ^3to ^4%d^3.", get_player_name(id), szTeam, szData[iData], b)
				return PLUGIN_HANDLED
			}
			
			g_iPlayerData[iPlayer][iData] = b
			
			Color(id, "ADMIN ^4%s: ^3Set player ^4%s's %s%s ^3to ^4%d %s", get_player_name(id), get_player_name(iPlayer), szData[iData], b == 1 ? "" : "s", b, szData[iData])
			return PLUGIN_HANDLED
		}
		
		case 5:
		{
			if(szArgs[ARG_OPERATOR][0] != '-' && szArgs[ARG_OPERATOR][0] != '+' )
			{
				console_print(id, "Choose and appropriate operator")
				return PLUGIN_HANDLED
			}
			
			new b = str_to_num(szArgs[ARG_AMOUNT])
			if(b < 1 || !b)
			{
				console_print(id, "Put a right number! -.-")
				return PLUGIN_HANDLED
			}
			
			switch(szArgs[ARG_OPERATOR][0])
			{
				case '-':
				{
					if(!iPlayer && iTeam)
					{						
						for(new i; i < iNum; i++)
						{
							if(g_iPlayerData[ ( iPlayer = iPlayers[i] ) ][iData] - b < 0)
							{
								g_iPlayerData[iPlayer][iData] = 0
							}
							
							else
							{
								g_iPlayerData[iPlayers[i]][iData] -= b
							}
						}
				
						Color(id, "ADMIN ^4%s: ^3Take from ^%s ^3players ^4%s ^4%d ^3amount.", get_player_name(id), szTeam, szData[iData], b)
						return PLUGIN_HANDLED
					}
					
					if(g_iPlayerData[iPlayer][iData] - b < 0)
					{
						b = g_iPlayerData[id][iData]
						g_iPlayerData[iPlayer][iData] = 0
					}
					
					else
					{
						g_iPlayerData[iPlayer][iData] -= b
					}
					
					Color(id, "ADMIN ^4%s: ^3Take from player ^4%s^3's ^4%s%s %d %s", get_player_name(id), get_player_name(iPlayer), szData[iData], b == 1 ? "" : "s", b, szData[iData])
				}
				
				case '+':
				{
					if(!iPlayer && iTeam)
					{
						for(new i; i < iNum; i++)
						{
							g_iPlayerData[iPlayers[i]][iData] += b
						}
						
						Color(id, "ADMIN ^4%s: ^3Add to ^%s ^3players ^4%s ^4%d ^3amount.", get_player_name(id), szTeam, szData[iData], b)
						
						return PLUGIN_HANDLED
					}
					
					g_iPlayerData[iPlayer][iData] += b
					Color(id, "ADMIN ^4%s: ^3Add player ^4%s^3's ^4%s%s %d %s", get_player_name(id), get_player_name(iPlayer), szData[iData], b == 1 ? "" : "s", b, szData[iData])
					
					return PLUGIN_HANDLED
				}
			}
		}
	}
		
	if(iData == EXP)
	{
		if(!iTeam && iPlayer)
		{
			while(g_iPlayerData[iPlayer][EXP] > LEVEL_EXP)
			{
				g_iPlayerData[iPlayer][EXP] -= LEVEL_EXP
				g_iPlayerData[iPlayer][LEVEL]++
			}
		}
			
		else
		{
			for(new i; i < iNum; i++)
			{
				while(g_iPlayerData[ ( iPlayer = iPlayers[i] ) ][EXP] > LEVEL_EXP)
				{
					g_iPlayerData[iPlayer][EXP] -= LEVEL_EXP
					g_iPlayerData[iPlayer][LEVEL]++
				}
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public AmmoMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id))
	{
		return;
	}
	
	new szInfo[10], iDump
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo),_,_, iDump)
	
	new iEnt = find_ent_by_owner(g_iMaxPlayers, MAIN_WEAPON, id)
	if(!iEnt)
	{
		Color(id, "You don't have the main weapon to buy ammo")
		return;
	}
	
	if(equali(szInfo, "Fill"))
	{
		new iPrice, iAmmo = cs_get_weapon_ammo(iEnt)
		
		if(iAmmo == gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_BULLETS])
		{
			Color(id, "Your scout is already filled!")
			return;
		}
		
		iPrice = floatround(float( ( gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_BULLETS]) - iAmmo ) * PRICE_RATE_FOR_SCOUTS)
		
		new szTitle[100]
		formatex(szTitle, charsmax(szTitle), "Do you want to fill your scout bullets^nfor %d points?", iPrice)
		new menu = CreateMenu(id, szTitle, "ConfirmMenu")
		
		new szPrice[10]
		num_to_str(iPrice, szPrice, charsmax(szPrice))
		menu_additem(menu, "Yes", szPrice)
		menu_additem(menu, "No")
		
		menu_setprop(menu, MPROP_EXIT, 0)
		
		menu_display(id, menu)
		return;
	}
	
	new iPrice = gAmmos[item][PRICE]
	
	if(g_iPlayerData[id][POINTS] < iPrice)
	{
		Color(id, "Your are missing %d points", iPrice - g_iPlayerData[id][POINTS])
		return;
	}
	
	cs_set_weapon_ammo(iEnt, cs_get_weapon_ammo(iEnt) +  gAmmos[item][AMOUNT])
	
	g_iPlayerData[id][POINTS] -= iPrice
	Color(id, "You have bought ^3%d bullets ^3for ^4%d points", gAmmos[item][AMOUNT], gAmmos[item][PRICE])
}

public ConfirmMenu(id, menu, item)
{	
	if(!is_user_alive(id))
	{
		return;
	}
	
	switch(item)
	{
		case 0:
		{
			new iPrice, szPrice[10]
			menu_item_getinfo(menu, item, iPrice, szPrice, charsmax(szPrice), _, _, iPrice)
			
			iPrice = str_to_num(szPrice)
			
			if(g_iPlayerData[id][POINTS] < iPrice)
			{
				Color(id, "You are missing %d points", iPrice - g_iPlayerData[id][POINTS])
				client_print(id, print_center, "You are missing %d points", iPrice - g_iPlayerData[id][POINTS])
				return;
			}
			
			if(!user_has_weapon(id, g_iWeaponIndex))
			{
				Color(id, "You don't have the weapon to be filled!")
				return;
			}
			
			new iEnt = find_ent_by_owner(g_iMaxPlayers, MAIN_WEAPON, id) 
			
			if(iEnt > g_iMaxPlayers)
			{
				if(cs_get_weapon_ammo(iEnt) == gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_BULLETS])
				{
					Color(id, "Your scout is already filled!")
					return;
				}
				
				cs_set_weapon_ammo(iEnt, gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_BULLETS])
				g_iPlayerData[id][POINTS] -= iPrice
				Color(id, "You have filled your ammo for %d points", iPrice)
			}
		}
		
		case 1:
		{
			return;
		}
	}
	
	DestroyMenu(id)
}		

public AdminCmdHnrMenu(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
	{
		Color(id, "Sorry, but you have no access to this menu!")
		return PLUGIN_HANDLED
	}
	
	menu_display(id, gHnrAdminMenu)
	return PLUGIN_HANDLED
}

#if !defined AUTO_JOIN
public ClCmd_MenuSelect_JoinClass(id)
{
	static const m_iJoiningState = 121;
	static const m_iMenu = 205;
	static const MENU_CHOOSEAPPEARANCE = 3;
	static const JOIN_CHOOSEAPPEARANCE = 4;
	
	if( get_pdata_int(id, m_iMenu) == MENU_CHOOSEAPPEARANCE && get_pdata_int(id, m_iJoiningState) == JOIN_CHOOSEAPPEARANCE )
	{
		new command[11], arg1[32];
		read_argv(0, command, charsmax(command));
		read_argv(1, arg1, charsmax(arg1));
		engclient_cmd(id, command, arg1);
		ExecuteHam(Ham_Player_PreThink, id);
		
		if( is_user_alive(id) )
		{
			if(!CanJoin())
			{
				user_silentkill(id)
				return PLUGIN_HANDLED
			}
			
			ExecuteHamB(Ham_Spawn, id);
		}
		
		else
		{
			if(CanJoin())
			{
				ExecuteHamB(Ham_Spawn, id);
				return PLUGIN_HANDLED
			}
		}
		
		StartGameCheck()
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}  
#endif

public client_putinserver(id)
{
	#if defined BOT_SUPPORT
	if(!g_iBotsRegistered && is_user_bot(id))
	{
		set_task(1.0, "RegisterBots", id)
	}
	#endif
	
	static szCode[50]
	#if defined SAVE_BY_NAME
	formatex(szCode, charsmax(szCode), "^"%s^"", get_player_name(id)) 
	#else
	get_user_authid(id, szCode, charsmax(szCode))
	#endif
	
	GetPlayerData(id, szCode)
}

public client_disconnect(id)
{
	SavePlayerData(id)
	
	if(IsInBit(gSpec, id))
	{
		RemoveFromBit(gSpec, id)
	}
	
	if(IsInBit(gHelp, id))
	{
		RemoveFromBit(gHelp, id)
	}
	
	if(IsInBit(gNoSounds, id))
	{
		RemoveFromBit(gNoSounds, id)
	}
	
	if(IsInBit(gImmunity, id))
	{
		RemoveFromBit(gImmunity, id)
	}
	
	if(IsInBit(gSpeed, id))
	{
		RemoveFromBit(gSpeed, id)
	}
	
	if(IsInBit(gInvisible, id))
	{
		RemoveFromBit(gInvisible, id)
	}
	
	if(task_exists(id))
	{
		remove_task(id)
	}
	
	for(new i = TASKID_REMOVE_IMMUNITY; i < TASKID_TIMER; i += 32)
	{
		if(task_exists(id + i))
		{
			remove_task(id + i)
		}
	}
	
	if(id == g_iWinnerId)
	{
		remove_task(TASKID_WIN_SPRITE)
	}

	g_iScore[id][DEATHS] = 0
	g_iScore[id][FRAGS] = 0
	
	set_task(0.5, "CheckPlayers", TASK_CHECK_PLAYERS)
	
	if(id == g_iBombId)
	{
		static iPlayers[32], iNum
		get_players(iPlayers, iNum, "ah")
			
		if(iNum == 1)
		{
			Winner(iPlayers[0])
		}
			
		else
		{
			SetBomber(0, 0)
		}
	}
}

public CheckPlayers(taskid)
{
	if(get_playersnum() < get_pcvar_num(g_pCvars[CVAR_MIN_PLAYERS]))
	{
		g_bGameRunning = false
		g_bCanJoin = true;
		g_iBombId = 0
		g_iWinnerId = 0
		
		g_iRunningStage = NO_RUN
		
		remove_task(TASKID_TIMER)
		
		Color(0, "The game has stopped as there are not enough players (^3Required Players: %d^4)", get_pcvar_num( g_pCvars[ CVAR_MIN_PLAYERS ] ) )
	}
}

#if defined BOT_SUPPORT
public RegisterBots(id)
{
	if(!is_user_connected(id) || g_iBotsRegistered)
		return;
		
	g_iBotsRegistered = 1
	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Pre", 0)
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Killed")
}
#endif

public fw_ResetMaxSpeed(id)
{
	if(!IsInBit(gAlive, id) || pev(id, pev_maxspeed) == 1.0)
	{
		return;
	}
	
	if(IsInBit(gSpeed, id))
	{
		static Float:flNum
		flNum = get_pcvar_float(g_pShopCvars[CVAR_SPEED_AMOUNT])
		set_pev(id, pev_maxspeed, flNum)
	}
}	

public fw_Killed(id)
{
	if(cs_get_user_team(id) != CS_TEAM_T)
	{
		cs_set_user_team(id, CS_TEAM_T)
	}
	
	if(IsInBit(gAlive, id))
	{
		RemoveFromBit(gAlive, id)
	}
}

public message_TextMsg(msgid, dest, id)
{
	static szArg[30]
	get_msg_arg_string(2, szArg, charsmax(szArg))
	
	#if defined RESTART_METHOD
	if(equal(szArg, "#Game_will_restart_in"))
	{
		g_bRestart = true
		
		new iPlayers[32], iNum, iPlayer
		get_players(iPlayers, iNum, "h")
		
		for(new i; i < iNum; i++)
		{
			g_iScore[ ( iPlayer = iPlayers[i] ) ][FRAGS] = get_user_frags(iPlayer)
			g_iScore[ ( iPlayer = iPlayers[i] ) ][DEATHS] = cs_get_user_deaths(iPlayer)
		}
		
		return PLUGIN_HANDLED
	}
	#endif
	
	if(equal(szArg, "#Game_teammate_attack"))
	{
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

#if defined AUTO_JOIN
public message_VGUIMenu(msgid, dest, id)
{
	static const VGUI_CHOOSE_TEAM_MENU = 2

	new iArg = get_msg_arg_int(1)
	if(iArg == VGUI_CHOOSE_TEAM_MENU)
	{
		if(cs_get_user_team(id) != CS_TEAM_UNASSIGNED)
		{
			client_print(id, print_chat, "This command is blocked!")
			return PLUGIN_HANDLED
		}
	}
	
	else if(iArg == 26)
	{
		client_cmd(id, "joinclass 5")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public message_ShowMenu(msgid, dest, id)
{
	static szMenuCode[30]
	get_msg_arg_string(4, szMenuCode, charsmax(szMenuCode))
	
	if(equal(szMenuCode, "#Terrorist_Select"))
	{
		set_task(0.5, "JoinClass", id)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public JoinClass(id)
{
	client_cmd(id, "joinclass 5; slot5")
}
#endif

#if defined AUTO_JOIN
public eTeamInfo()
{
	static szTeam[3]; read_data(2, szTeam, charsmax(szTeam))
	new id = read_data(1)
	
	if(szTeam[0] == 'U')
	{
		return;
	}

	StartGameCheck()
	
	if(szTeam[0] == 'T')
	{
		set_task(0.7, "CheckAliveTeamInfo", id)
		
		return;
	}
}
#endif

stock StartGameCheck()
{
	new iNum
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(!is_user_connected(i))
		{
			continue;
		}
		
		iNum ++
	}
	
	if(iNum >= get_pcvar_num(g_pCvars[CVAR_MIN_PLAYERS]) && !g_bGameRunning)
	{
		g_bGameRunning = true;
		g_iRunningStage = PREPARE

		Color(0, "Enough players have joined! ^3Starting game^4!")
		remove_task(TASK_CHECK_PLAYERS)
		
		#if defined RESTART_METHOD
		set_pcvar_num(g_pRestart, 5)
		#else
		Restart()
		#endif
	}
}

public CheckAliveTeamInfo(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	if(!CanJoin())
	{	
		if( is_user_alive(id) )
		{
			user_silentkill(id)
		}
		
		cs_set_user_team(id, CS_TEAM_SPECTATOR);
		Color(id, "The game was ^3started^4, please wait until ^3next game^4.")
	}
		
	else
	{
		set_task(0.2, "SpawnPlayer", id)
	}
}

public SpawnPlayer(id)
{
	if(!is_user_connected(id) || IsInBit(gAlive, id))
	{
		return;
	}
	
	//ExecuteHamB(Ham_CS_RoundRespawn, id)
	cs_user_spawn(id)
}

public CmdChooseTeam(id)
{
	new CsTeams:iTeam = cs_get_user_team(id)
	if(iTeam != CS_TEAM_UNASSIGNED)
	{
		new iMenu = CreateMenu(id, "\r[Hit And Run] \wMenu:", "HnrMainMenuHandler")
		
		menu_additem(iMenu, "Scouts Menu")
		menu_additem(iMenu, "Shop Menu")
		menu_additem(iMenu, "Ammo Menu")
		menu_additem(iMenu, ( ( iTeam == CS_TEAM_SPECTATOR && IsInBit(gSpec, id) ) ? "UnSpec (If game is running and didn't start you will be respawned)" : "Go to spectators (And don't play)" ) )
		menu_additem(iMenu, "Help")
		menu_addblank(iMenu, 0)
		menu_additem(iMenu, "Admin Menu", "", get_user_flags(id) & ACCESS ? 0 : (1<<26))
		
		menu_display(id, iMenu)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public HnrMainMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		DestroyMenu(id)
		return;
	}
	
	DestroyMenu(id)
	
	switch(item)
	{
		case 0:
		{
			CmdScout(id)
		}
		
		case 1:
		{
			CmdShop(id)
		}
		
		case 2:
		{
			CmdAmmo(id)
		}
		
		case 3:
		{
			if(g_iUsedSpecCmd[id])
			{
				Color(id, "You can't use the spec command until next round.")
				return;
			}
			
			g_iUsedSpecCmd[id] = 1
			
			if(IsInBit(gSpec, id))
			{
				RemoveFromBit(gSpec, id)
				
				if(CanJoin())
				{
					cs_set_user_team(id, CS_TEAM_T)
					ExecuteHamB(Ham_CS_RoundRespawn, id)
					Color(id, "You have been transported out of spectators")
					return;
				}
				
				/*else*/
				{
					if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
					{
						cs_set_user_team(id, CS_TEAM_SPECTATOR)
					}
					
					if(IsInBit(gAlive, id))
					{
						user_silentkill(id)
						RemoveFromBit(gAlive, id)
					}
				}
				
				Color(id, "You will now not play and stay in spectators even if a new game starts")
				
				return;
			}
			
			AddToBit(gSpec, id)
			if(IsInBit(gAlive, id))
			{
				RemoveFromBit(gAlive, id)
				user_silentkill(id)
			}
			
			if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
			{
				cs_set_user_team(id, CS_TEAM_SPECTATOR)
			}
			
			Color(id, "You have been transfered to spectators")
		}
		
		case 4:
		{
			CmdHelp(id)
		}
		
		case 5:
		{
			menu_display(id, gHnrAdminMenu)
		}
	}
}

public CmdAllLevels(id)
{
	new iMenu = CreateMenu(id, g_szLevelsTitle, "LevelsMenuHandler")
	
	new szItem[SSTRING + 32 /* Player Name Size */]
	
	new iPlayers[32], iNum, iPlayer
	get_players( iPlayers, iNum, "h" )
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		formatex(szItem, charsmax(szItem), "\r%s \y- %d \w(%d\w/\y%d\w)", get_player_name(iPlayer), g_iPlayerData[id][LEVEL], g_iPlayerData[id][EXP], LEVEL_EXP)
		
		menu_additem(iMenu, szItem, .paccess = (1<<26))
	}
	
	menu_display(id, iMenu)
}

public LevelsMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		DestroyMenu(id)
		return;
	}
}

public CmdScout(id)
{
	new iMenu = CreateMenu(id, g_szScoutMenuTitle, "ScoutHandler");
	new szItem[SSTRING]
	
	new iAccess = is_user_alive(id) ? 0 : (1<<26)
	
	for(new i; i < sizeof gScoutInfo; i++)
	{
		formatex(szItem, charsmax(szItem), "%s %s", gScoutInfo[i][SCOUT_NAME], gScoutInfo[i][SCOUT_UNLOCK_LEVEL] <= g_iPlayerData[id][LEVEL] ? "\y[UNLOCKED]" : "\r[LOCKED]")
		menu_additem(iMenu, szItem, "", iAccess)
	}
	
	menu_display(id, iMenu, 0)
}

public ScoutHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		DestroyMenu(id)
		return;
	}
	
	static iDump, iPage
	player_menu_info(id, iDump, iDump, iPage)
	
	if( ( g_iPlayerScout[id] - 1 ) == item || g_iPlayerData[id][LEVEL] < gScoutInfo[item][SCOUT_UNLOCK_LEVEL])
	{
		ShowScoutHud(id, item)
		menu_display(id, menu, iPage)
		return;
	}
	
	DestroyMenu(id)
	g_iPlayerScout[id] = item + 1
	ChangeModel(id)
	Color(id, "^4You have choosed scout ^3'^4%s^3'", gScoutInfo[item][SCOUT_NAME])
}

public CmdSound(id)
{
	if(IsInBit(gNoSounds, id))
	{
		RemoveFromBit(gNoSounds, id)
		Color(id, "Sounds now are ^3ENABLED ^4for you.")
	}
	
	else
	{
		AddToBit(gNoSounds, id)
		Color(id, "Sounds are now ^3DISABLED ^4for you.")
	}
}

public CmdXpLevel(id)
{
	Color(id, "^3Your Level: ^4%d^3, Your XP: ^4%d^3/^4%d", g_iPlayerData[id][LEVEL], g_iPlayerData[id][EXP], LEVEL_EXP)
	
	set_hudmessage(0, 0, 128, -1.0, 0.65, 2, 4.0, 7.5, 0.1, 0.1, -1)
	show_hudmessage(id, "Your Level: %d, Your XP: %d/%d", g_iPlayerData[id][LEVEL], g_iPlayerData[id][EXP], LEVEL_EXP)
}

public CmdPoints(id)
{
	Color(id, "^3You have ^4%d points^3.", g_iPlayerData[id][POINTS])
}

public CmdFree(id)
{
	Color(id, "^3You have ^4%d Free items!", g_iPlayerData[id][FREE_ITEMS])
}

public CmdAmmo(id)
{
	if(!is_user_alive(id))
	{
		Color(id, "You must be alive!")
		return;
	}
	
	menu_display(id, g_hAmmoMenu)
}

public CmdShop(id)
{
	if(!IsInBit(gAlive, id))
	{
		Color(id, "You need to be alive to buy an ^3ITEM^4.")
		return;
	}
	
	static szShopTitle[100], szItem[SSTRING], len;
	formatex(szShopTitle, charsmax(szShopTitle), "%s ^nYour points: \y%d", g_szShopTitle, g_iPlayerData[id][POINTS])
	
	new iMenu = CreateMenu(id, szShopTitle, "ShopHandler")
	
	for(new i; i < SHOP_ITEMS; i++)
	{		
		len = 0
		if(g_iItemsCvars[i][1] != -1)
		{
			len += format(szItem[len], charsmax(szItem) - len, g_szShopItems[i], get_pcvar_num(g_pShopCvars[g_iItemsCvars[i][1]]))
			len += format(szItem[len], charsmax(szItem) - len, " \r[\w%d Points\r]", get_pcvar_num(g_pShopCvars[g_iItemsCvars[i][0]]))
		}
		
		else
		{
			formatex(szItem, charsmax(szItem) - len, "%s \r[\w%d Points\r]", g_szShopItems[i], get_pcvar_num(g_pShopCvars[g_iItemsCvars[i][0]]))
		}
		
		menu_additem(iMenu, szItem)
	}
	
	menu_display(id, iMenu)
}

public ShopHandler(id, menu, item)
{
	DestroyMenu(id)
	
	if(item == MENU_EXIT)
	{
		return;
	}
	
	if(!CanBuy(id, item))
	{
		return;
	}

	switch(item)
	{
		case ITEM_IMMUNITY:
		{	
			new iTime = get_pcvar_num(g_pShopCvars[CVAR_IMMUNITY_TIME])
			Color(id, g_szShopBuy[item], iTime)
			
			GiveShopItem(id, item, float(iTime))
			//ShopItemHudMessage(id, item)
		}
		
		case ITEM_M4A1:
		{	
			new iAmmo = get_pcvar_num(g_pShopCvars[CVAR_M4A1_AMMO])
			cs_set_weapon_ammo(give_item(id, "weapon_m4a1"), iAmmo)
			
			Color(id, g_szShopBuy[item], iAmmo)
			//ShopItemHudMessage(id, item)
		}
		
		case ITEM_INVISIBILITY:
		{
			new iTime = get_pcvar_num(g_pShopCvars[CVAR_INVISIBILITY_TIME])
			GiveShopItem(id, item, float(iTime))
			
			Color(id, g_szShopBuy[item], iTime)
			//ShopItemHudMessage(id, item)
		}
		
		case ITEM_SPEED:
		{
			new Float:flSpeed = get_pcvar_float(g_pShopCvars[CVAR_SPEED_AMOUNT])
			GiveShopItem(id, item, flSpeed)
			
			Color(id, g_szShopBuy[item])
			//ShopItemHudMessage(id, item)
		}
		
		case ITEM_FREE:
		{
			new iNum = get_pcvar_num(g_pShopCvars[CVAR_FREE_ITEMS_AMOUNT])
			Color(id, g_szShopBuy[item], iNum)
			g_iPlayerData[id][FREE_ITEMS] += iNum
			//ShopItemHudMessage(id, item)
		}
		
		/*case ITEM_PASS_GLOW:
		{
			Color(id, g_szShopBuy[item])
			//ShopItemHudMessage(id, item)
		}*/
	}
}

/*
stock ShopItemHudMessage(id, item)
{
	static const Float:flHudPos[][] = {
		,,,
	}
	
	static iLastHud = -1
	
	new iTarget
	for(new b; b < sizeof(g_szShopHudMessages[]); b += HUD_MESSAGE)
	{
		if(g_szShopHudMessages[item][b] == TARGET_NONE)
		{
			continue;
		}
		
		switch(g_szShopHudMessages[item][b])
		{
			case TARGET_PLAYER:
			{
				iTarget = id
			}
			
			case TARGET_ALL:
			{
				iTarget = 0
			}
			
			if(++iLastHud > sizeof(flHudPos) - 1)
			{
				iLastHud = 0
			}
			
			set_hudmessage(255, 0, 0, flHudPos[iLastHud][0], flHudPos[iLastHud][1], 1, 5.0, 5.0, 0.1, 0.1, -1)
			show_hudmessage(iTarget, g_szShopHudMessages[item]
*/

public RemoveInvisibility(id)
{
	id = id - TASKID_REMOVE_INVISIBILITY;
	RemoveFromBit(gInvisible, id)
	
	if(!IsInBit(gAlive, id))
	{
		return;
	}
	
	Color(id, "^3Invisibility ^4effect wore off. Now you can ^3BE SEEN^4!")
	
	if(id == g_iBombId)
	{
		BomberGlow(id)
	}
	
	else 
	{
		UnSetBomber(id)
	}
}

public RemoveImmunity(id)
{
	id -= TASKID_REMOVE_IMMUNITY;
	RemoveFromBit(gImmunity, id);
	
	if(IsInBit(gAlive, id))
	{
		Color(id, "^3Immunity ^4effect wore off. Now you can ^3GET HITTEN^4!")
	}
}

public CmdHelp(id)
{	
	if(IsInBit(gHelp, id))
	{
		RemoveFromBit(gHelp, id)
		remove_task(id + TASKID_HELP)
		
		return;
	}
	
	AddToBit(gHelp, id)
	
	//set_hudmessage(255, 255, 224, 0.25, 0.25, 1, 1.0, 1.0, 0.1, 0.1, -1)
	//ShowSyncHudMsg(id, g_hHelpHud, g_szHelpHud)
	ShowHelpHud(id + TASKID_HELP)
	set_task(1.0, "ShowHelpHud", id + TASKID_HELP, .flags = "b")
}

public ShowHelpHud(taskid)
{
	new id = taskid - TASKID_HELP
	
	if(!is_user_connected(id))
	{
		remove_task(taskid)
		return;
	}
	
	if(!IsInBit(gHelp, id))
	{
		remove_task(taskid)
		return;
	}
	
	set_hudmessage(255, 255, 224, 0.25, 0.25, 1, 1.0, 1.0, 0.1, 0.1, -1)
	//ShowSyncHudMsg(id, g_hHelpHud, g_szHelpHud)
	show_hudmessage(id, g_szHelpHud)
}

public eNewRound()
{
	if(!g_bGameRunning)
	{
		return;
	}
	
	
	
	#if defined RESTART_METHOD
	new iPlayers[32], iNum, iPlayer
	if(g_bRestart)
	{
		g_bRestart = false
		
		get_players(iPlayers, iNum)
		
		for(new i; i < iNum; i++)
		{
			set_user_frags( ( iPlayer = iPlayers[i] ), g_iScore[iPlayer][FRAGS])
			cs_set_user_deaths(iPlayer, g_iScore[iPlayer][DEATHS])
		}
	}
	#endif
	
	g_bCanJoin = true
	g_iRunningStage = PREPARE
	
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(!is_user_connected(i))
		{
			continue;
		}
		
		if(task_exists(i + TASKID_REMOVE_IMMUNITY))
		{
			remove_task(i + TASKID_REMOVE_IMMUNITY)
		}
		
		if(task_exists(i + TASKID_REMOVE_INVISIBILITY))
		{
			remove_task(i + TASKID_REMOVE_INVISIBILITY)
		}
		
		if(IsInBit(gSpec, i))
		{
			continue;
		}
		
		if(cs_get_user_team(i) == CS_TEAM_SPECTATOR)
		{
			cs_set_user_team(i, CS_TEAM_T)
		}
	}
	
	gSpeed = 0
	gInvisible = 0
	gImmunity = 0
	g_iRounds = 0
	
	arrayset(g_iRewards, 0, REWARDS)
	arrayset(g_iUsedSpecCmd, 0, sizeof(g_iUsedSpecCmd))
	
	/* IF can't run, stop here! */
	if(g_iRunningStage == NO_RUN)
	{
		return;
	}
	
	if(task_exists(TASKID_TIMER))
	{
		remove_task(TASKID_TIMER)
	}
	
	new Float:flNum = get_pcvar_float(g_pCvars[CVAR_START_TIME])
	
	g_iCurrentHud = GAME_PREPARE
	set_hudmessage(R, G, B, HUD_POS[g_iCurrentHud][X], HUD_POS[g_iCurrentHud][Y], 0, 0.0, flNum, HUD_POS[g_iCurrentHud][FADE_IN], HUD_POS[g_iCurrentHud][FADE_OUT], -1)
	ShowSyncHudMsg(0, g_hGlobalAnnounces, g_szHuds[g_iCurrentHud])
	
	set_task(flNum, "StartForward")
}

public StartForward()
{
	if( g_bGameRunning )
	{
		client_cmd(0, "stopsound; mp3 stop");
		
		g_iBombId = 0;
		g_iWinnerId = 0;
		
		if(task_exists(TASKID_WIN_SPRITE))
		{
			remove_task(TASKID_WIN_SPRITE);
		}
		
		g_bCanJoin = false;
		
		SetBomber(0, 1, SOUND_NEW_GAME_START);
		
		new Float:flPlayersNum = float(get_playersnum())
		
		g_iRewards[REWARD_EXP] = floatround( get_pcvar_float(g_pCvars[CVAR_WINNER_EXP_MULTIPILER] ) * flPlayersNum )
		g_iRewards[REWARD_POINTS] = floatround( get_pcvar_float(g_pCvars[CVAR_WINNER_POINTS_MULTIPILER]) * flPlayersNum )
		
		Color(0, "^3The game has now offically ^4STARTED! ^3The points prize stands on: ^4%d Points!!!", g_iRewards[REWARD_POINTS])
		//Color(0, "This server is running ^4Hit And Run ^3Plugin by ^4%s^3.", AUTHOR)
		
		g_iRunningStage = RUNNING
		
		set_task(0.1, "TimerHudTask", TASKID_TIMER, .flags = "b");
	}
}

public TimerHudTask(taskid)
{
	g_flTimer -= 0.1
	
	static bool:bPlayedAlarmSound
	
	if(g_flTimer <= 0.0)
	{
		bPlayedAlarmSound = false
		client_cmd(0, "mp3 stop; stopsound")
		
		#if defined BOT_SUPPORT
		if(is_user_bot(g_iBombId))
		{
			set_pdata_int(g_iBombId, OFFSET_CSTEAMS, 1)
		}
		#endif
		
		DeathEffect(g_iBombId)
		
		Color(g_iBombId, "You have died since you ran out of TIME!")
		
		if(g_iRounds)
		{
			GiveExp(g_iBombId, g_iRounds)
			Color(g_iBombId, "You have gained %d ^4EXP ^3for surviving so far!", g_iRounds)
		}
		
		g_iRounds++
		
		PlaySound(g_szLightingSound, g_iLightingSoundIndex, 0)

		user_kill(g_iBombId, 1)
		RemoveFromBit(gAlive, g_iBombId)
		cs_set_user_team(g_iBombId, CS_TEAM_SPECTATOR)
		
		static iPlayers[32], iNum
		get_players(iPlayers, iNum, "a")
		
		if(iNum == 1)
		{
			Winner(iPlayers[0])
			return;
		}

		SetBomber(0, 1, SOUND_NEW_BOMBER_CHOOSED)
		
		return;
	}
	
	if(g_flTimer <= 7.0 && !bPlayedAlarmSound)
	{
		bPlayedAlarmSound = true
		PlaySound(g_szAlarmSound, g_iAlarmSoundIndex)
	}
		
	set_dhudmessage(R, G, B, HUD_POS[TIMER][X], HUD_POS[TIMER][Y], 0, 0.0, HUD_POS[TIMER][HOLD_TIME], HUD_POS[TIMER][FADE_IN], HUD_POS[TIMER][FADE_OUT])
	//ShowSyncHudMsg(0, g_hTimerHud, g_szHuds[TIMER], g_flTimer)
	show_dhudmessage(0, g_szHuds[TIMER], g_flTimer)
}

public Restart()
{
	g_bCanJoin = true; g_iRunningStage = PREPARE;
	
	#if defined RESTART_METHOD
	set_pcvar_num(g_pRestart, 1)
	#else
	// Transfer everyone back, remove tasks
	eNewRound()
	
	remove_entity_name("weaponbox")
	remove_entity_name("armoury_entity")
	
	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "h")
	
	for(new i; i < iNum; i++)
	{
		if(!IsInBit(gSpec, iPlayers[i]))
		{
			// Respawn
			ExecuteHamB(Ham_CS_RoundRespawn, iPlayers[i])
		}
	}
	#endif
}

public WinSpriteEffect(taskid)
{	
	if(!g_iWinnerId)
	{
		remove_task(taskid)
		return;
	}
	
	static iOrigin[3]
	get_user_origin(g_iWinnerId, iOrigin, 0)
	
	static iWinEffects
	iWinEffects = ReadEffectCvar()
	
	static const TE_EFFECTS[] = {
		TE_BEAMTORUS,
		TE_BEAMCYLINDER,
		TE_BEAMDISK
	}
	
	static const iZVectorIncrement[] = {
		400,
		350,
		350
	}
	
	static iSameColor
	iSameColor = get_pcvar_num(g_pEffectsCvars[CVAR_EFFECTS_SAME_COLOR])
	
	static r, g, b
	r = random(256); g = random(256); b = random(256)

	
	for(new i = EFFECT_TORUS, x = 3, y; i <= EFFECT_DISK; i <<= 1, x += 3, y++)
	{
		if( !( iWinEffects & i ) )
		{
			continue;
		}
		
		TempEntity(TE_EFFECTS[y], iOrigin, iZVectorIncrement[y], g_iLaserBeamIndex, r, g, b, get_pcvar_num(g_pEffectsCvars[x + 1]), get_pcvar_num(g_pEffectsCvars[x]), get_pcvar_num(g_pEffectsCvars[x + 2]))

		if(!iSameColor)
		{
			r = random(256); g = random(256); b = random(256)
		}
	}
	
	/*message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	{
		write_byte(TE_BEAMCYLINDER)
		write_coord(iOrigin[0])				// position.x
		write_coord(iOrigin[1])				// position.y
		write_coord(iOrigin[2])				// position.z
		write_coord(iOrigin[0])   			// axis.x
		write_coord(iOrigin[1])   			// axis.y
		write_coord(iOrigin[2] + 350)			// axis.z
		write_short(g_iLaserBeamIndex)			// sprite index
		write_byte(0)      				// starting frame
		write_byte(0)       				// frame rate in 0.1's
		write_byte(10)        				// life in 0.1's
		write_byte(get_pcvar_num(g_pEffectsCvars[CVAR_CYLINDER_WIDTH]))	       	// line width in 0.1's
		write_byte(get_pcvar_num(g_pEffectsCvars[CVAR_CYLINDER_AMPLITUDE]))        			// noise amplitude in 0.01's
		write_byte(r == -1 ? random(256) : r)		// r
		write_byte(g == -1 ? random(256) : g)		// g
		write_byte(b == -1 ? random(256) : b)		// b
		write_byte(get_pcvar_num(g_pEffectsCvars[CVAR_CYLINDER_BRIGHTNESS]))				// brightness
		write_byte(1)					// scroll speed in 0.1's
	}	
	message_end()*/
}

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	if(cs_get_user_team(id) != CS_TEAM_T)
	{
		cs_set_user_team(id, CS_TEAM_T)
	}
	
	if(!CanJoin())
	{
		set_task(0.2, "KillPlayer", id)
		return;
	}
	
	AddToBit(gAlive, id)
	
	GiveItems(id)
	UnSetBomber(id)
	
	if(g_iRunningStage == PREPARE)
	{
		Color(id, "Agent: ^3These are your weapons, try to ^4survive^3!!!")
	}
}

public KillPlayer(id)
{
	if(is_user_connected(id))
	{
		if(IsInBit(gAlive, id))
		{
			RemoveFromBit(gAlive, id)
			user_silentkill(id)
		}
		
		cs_set_user_team(id, CS_TEAM_SPECTATOR)
	}
}

public fw_TakeDamage(id, idInflector, iAttacker, Float:flDamage, iDamageBits)
{
	SetHamParamFloat(4, 0.0)
	
	new const DMG_HEGRENADE = (1<<24)
	if(!(iDamageBits & DMG_HEGRENADE) && !get_pcvar_num(g_pCvars[CVAR_BLOOD_EFFECT]))
	{
		return HAM_SUPERCEDE
	}
	
	if(g_iRunningStage != RUNNING)
	{
		return HAM_SUPERCEDE
	}
	
	HandleHit(id, iAttacker)
	return HAM_IGNORED
}

public fw_TraceAttack_Pre(id, iAttacker, Float:flDamage, Float:vDirection[3], iTr, iDamageBits)
{	
	if(g_iRunningStage != RUNNING)
	{
		set_tr2(iTr, TR_flFraction, 1.0)
		return HAM_SUPERCEDE
	}
	
	if(get_pcvar_num(g_pCvars[CVAR_BLOOD_EFFECT]))
	{
		return HAM_IGNORED
	}

	set_tr2(iTr, TR_flFraction, 1.0)
	HandleHit(id, iAttacker)
	
	return HAM_SUPERCEDE
}

stock HandleHit(id, iAttacker)
{
	if(IsPlayer(iAttacker) && IsInBit(gAlive, iAttacker) && iAttacker == g_iBombId && IsPlayer(id))
	{
		if(IsInBit(gImmunity, id))
		{
			return;
		}
		
		#if defined BOT_SUPPORT
		if(is_user_bot(id))
		{
			set_pdata_int(id, OFFSET_CSTEAMS, 2)
		}
		
		if(is_user_bot(iAttacker))
		{
			set_pdata_int(iAttacker, OFFSET_CSTEAMS, 1)
		}
		#endif
		
		SetBomber(id, 0)
	}
}

public fw_AddToFullPack( es, e, iEntity, iHost, iHostFlags, iPlayer, pSet )
{
	if(g_iRunningStage != RUNNING)
	{
		return;
	}
	
	if( IsPlayer(iEntity) && IsPlayer(iHost) && IsInBit(gAlive, iEntity) && IsInBit(gAlive, iHost) )
	{
		set_es(es, ES_RenderMode, kRenderTransAdd)
		
		if( IsInBit(gInvisible, iEntity) )
		{
			set_es(es, ES_RenderAmt, 0)
		}
		
		else 
		{
			if(iEntity == g_iBombId)
			{
				set_es(es, ES_RenderAmt, 16)
			}
			
			else
			{
				set_es(es, ES_RenderMode, kRenderNormal)
				set_es(es, ES_RenderAmt, 16)
			}
		}
	}
}

public fw_ItemDeploy(iEnt)
{
	static iOwner;

	iOwner = get_pdata_cbase(iEnt, m_pPlayer)
	ChangeModel(iOwner)
}

stock ChangeModel(id)
{
	if(IsInBit(gAlive, id))
	{
		set_pev(id, pev_viewmodel2, gScoutInfo[g_iPlayerScout[id] - 1][SCOUT_MODEL])
	}
}

public fw_PrimAttack(iEnt)
{	
	if(pev_valid(iEnt) != 2)
	{
		return;
	}
	
	if(!ExecuteHam(Ham_Weapon_IsUsable, iEnt))
	{
		return;
	}
	
	static iOwner;
	iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4)
	
	static Float:flNextPrimAttackTime;
	
	flNextPrimAttackTime = get_pdata_float(iEnt, m_flNextPrimaryAttack, 4)

	flNextPrimAttackTime /= gScoutInfo[g_iPlayerScout[iOwner] - 1][SCOUT_FIRE_SPEED]
	
	set_pdata_float(iOwner, m_flNextAttack, flNextPrimAttackTime, 5)
	set_pdata_float(iEnt, m_flNextPrimaryAttack, flNextPrimAttackTime, 4)
}

#if defined TEST
public CmdGive(id)
{
	new szSaid[50], szCmd[50], szNum[50]
	read_argv(1, szSaid, 49)
	
	parse(szSaid, szSaid, charsmax(szSaid), szCmd, charsmax(szCmd), szNum, charsmax(szNum))
	
	
	if(!equali(szSaid, "/give"))
	{
		return PLUGIN_CONTINUE
	}
	
	new iNum = str_to_num(szNum)
	
	switch(szCmd[0])
	{
		case 'e':
		{
			g_iPlayerData[id][EXP] += iNum
			client_print(id, print_chat, "You were given %d Exp", iNum)
		}
			
		case 'l':
		{
			g_iPlayerData[id][LEVEL] += iNum
			client_print(id, print_chat, "You were given %d Levels", iNum)
		}
			
		case 'p':
		{
			g_iPlayerData[id][POINTS] += iNum
			client_print(id, print_chat, "You were given %d points", iNum)
		}
			
		case 'f':
		{
			g_iPlayerData[id][FREE_ITEMS] += iNum
			client_print(id, print_chat, "You were given %d Free items", iNum)
		}
	}
		
	return PLUGIN_HANDLED
}

public CmdMdl(id)
{
	static szModel[60]
	pev(id, pev_viewmodel2, szModel, charsmax(szModel))
	
	client_print(id, print_chat, szModel)
}
#endif

/* ----------------------------- COLOR CHAT -------------------------- */

stock Color(id, const szBuffer[], {Float,Sql,Result,_}:...)
{
	static szMsg[256]
	vformat(szMsg, 255, szBuffer, 3)
	
	ColorChat(id, RED, "%s ^3%s", PREFIX, szMsg)
}

new const TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

stock ColorChat(id, Colors:type, const msg[], {Float,Sql,Result,_}:...)
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

stock ShowColorMessage(id, type, message[])
{
	message_begin(type, gMsgIdSayText, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

stock Team_Info(id, type, team[])
{
	message_begin(type, gMsgIdTeamInfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

stock ColorSelection(index, type, Colors:Type)
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

stock FindPlayer()
{
	new i = -1;

	while(i <= get_maxplayers())
	{
		if(is_user_connected(++i))
			return i;
	}

	return -1;
}

/* ----------------- Director HUD Message Stocks --------------- */

stock __dhud_color;
stock __dhud_x;
stock __dhud_y;
stock __dhud_effect;
stock __dhud_fxtime;
stock __dhud_holdtime;
stock __dhud_fadeintime;
stock __dhud_fadeouttime;
stock __dhud_reliable;

stock set_dhudmessage( red = 0, green = 160, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 6.0, Float:holdtime = 3.0, Float:fadeintime = 0.1, Float:fadeouttime = 1.5, bool:reliable = false )
{
	#define clamp_byte(%1)       ( clamp( %1, 0, 255 ) )
	#define pack_color(%1,%2,%3) ( %3 + ( %2 << 8 ) + ( %1 << 16 ) )
	
	__dhud_color       = pack_color( clamp_byte( red ), clamp_byte( green ), clamp_byte( blue ) );
	__dhud_x           = _:x;
	__dhud_y           = _:y;
	__dhud_effect      = effects;
	__dhud_fxtime      = _:fxtime;
	__dhud_holdtime    = _:holdtime;
	__dhud_fadeintime  = _:fadeintime;
	__dhud_fadeouttime = _:fadeouttime;
	__dhud_reliable    = _:reliable;
	
	return 1;
}

stock show_dhudmessage( index, const message[], any:... )
{
	new buffer[ 128 ];
	new numArguments = numargs();
	
	if( numArguments == 2 )
	{
		send_dhudMessage( index, message );
	}
	else if( index || numArguments == 3 )
	{
		vformat( buffer, charsmax( buffer ), message, 3 );
		send_dhudMessage( index, buffer );
	}
	else
	{
		new playersList[ 32 ], numPlayers;
		get_players( playersList, numPlayers, "ch" );
		
		if( !numPlayers )
		{
			return 0;
		}
		
		new Array:handleArrayML = ArrayCreate();
		
		for( new i = 2, j; i < numArguments; i++ )
		{
			if( getarg( i ) == LANG_PLAYER )
			{
				while( ( buffer[ j ] = getarg( i + 1, j++ ) ) ) {}
				j = 0;
				
				if( GetLangTransKey( buffer ) != TransKey_Bad )
				{
					ArrayPushCell( handleArrayML, i++ );
				}
			}
		}
		
		new size = ArraySize( handleArrayML );
		
		if( !size )
		{
			vformat( buffer, charsmax( buffer ), message, 3 );
			send_dhudMessage( index, buffer );
		}
		else
		{
			for( new i = 0, j; i < numPlayers; i++ )
			{
				index = playersList[ i ];
				
				for( j = 0; j < size; j++ )
				{
					setarg( ArrayGetCell( handleArrayML, j ), 0, index );
				}
				
				vformat( buffer, charsmax( buffer ), message, 3 );
				send_dhudMessage( index, buffer );
			}
		}
		
		ArrayDestroy( handleArrayML );
	}
	
	return 1;
}

stock send_dhudMessage( const index, const message[] )
{
	message_begin( __dhud_reliable ? ( index ? MSG_ONE : MSG_ALL ) : ( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST ), SVC_DIRECTOR, _, index );
	{
		write_byte( strlen( message ) + 31 );
		write_byte( DRC_CMD_MESSAGE );
		write_byte( __dhud_effect );
		write_long( __dhud_color );
		write_long( __dhud_x );
		write_long( __dhud_y );
		write_long( __dhud_fadeintime );
		write_long( __dhud_fadeouttime );
		write_long( __dhud_holdtime );
		write_long( __dhud_fxtime );
		write_string( message );
	}
	message_end();
}

