#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <engine>
#include <fakemeta>
#include <cstrike>

#define PLUGIN "Hit N Run"
#define VERSION "1.0"
#define AUTHOR "Annonymous"

#define BOT_SUPPORT

new const PREFIX[] = "^3[ ^4Hit And Run ^3]"

// Offsets
const OFFSET_CSTEAMS = 114

/* 
[ Hit And Run ] This server is running Hit And Run Plugin by p1Mp.
[ Hit And Run ] A game is activated right now, do not die!!
[ Hit And Run ] To get some HELP - Type now /help.

[ Hit And Run ] This server is running Hit And Run Plugin by p1Mp.
[ Hit And Run ] A game is activated right now, do not die!!
[ Hit And Run ] To get some HELP - Type now /help.
[ Hit And Run ] You have died since you ran out of TIME!
[ Hit And Run ] You have gained 3 EXP for surviving so far!

/points
[ Hit And Run ] You have 0 points.

--- ITEMS:
weapon_scout
weapon_knife
weapon_hegrenade
weapon_smokenade
weapon_flashnade
weapon_flashnade

Alaram sound runs on 5 seconds left.
Win sound plays on win and stays to new game start

*/

enum _:TASKS ( += 32 )
{
	TASKID_TIMER = 1581,
	TASKID_HELP,
	
	TASKID_WIN_SPRITE
}

enum _:SCORES
{
	FRAGS,
	DEATHS
}

new g_iScore[33][SCORES]

enum _:CVARS
{
	CVAR_MIN_PLAYERS,
	CVAR_START_TIME,
	CVAR_TIMER_TIME,
	
	CVAR_SHAKE_DURATION,
	CVAR_SHAKE_FREQUENCY,
	CVAR_SHAKE_AMPLITUDE,
	
	//CVAR_WIN_EFFECT,
	CVAR_DELAY_BETWEEN_WIN_SPRITE,
}

new const g_pCvarInfo[][][] = {
	{ "hnr_min_players", "2" },
	{ "hnr_start_time", "8.5" },
	{ "hnr_timer_time", "20.0" },
	
	{ "hnr_shake_duration", "16" },
	{ "hnr_shake_frequency", "1" },
	{ "hnr_shake_amplitude", "16" },
	
	//{ "hnr_win_effect", "" },
	{ "hnr_delay_between_win_effects", "0.5" }
}

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
	{ "mp_friendlyfire", "1", 0 }
//	{ "mp_tkpunish", "0", 0 }
}

new g_pCvars[CVARS]

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
	{ -1.0, 0.72, 6.5, 0.1, 0.1 },
	// New bomber (Randomly chosen)
	{ -1.0, 0.78, 6.0, 0.1, 0.1 },
	// Timer !!
	{ -1.0, 0.58, 0.1, 0.0, 0.0 },
	
	// HELP MESSAGE
	{ -1.0, 0.25, 1.0, 0.1, 0.1 }
}

// For easy handle
new g_iCurrentHud
#define SET_HUD_MESSAGE() set_hudmessage(R, G, B, HUD_POS[g_iCurrentHud][X], HUD_POS[g_iCurrentHud][Y], 0, 0.0, HUD_POS[g_iCurrentHud][HOLD_TIME], HUD_POS[g_iCurrentHud][FADE_IN], HUD_POS[g_iCurrentHud][FADE_OUT], -1)

// Basic Stuff
new const WEAPON_AMMO = 10
new MAIN_WEAPON[] = "weapon_scout"

// Vars
new g_iWeaponIndex
new g_iMaxPlayers

new g_iBombId
new Float:g_flTimer = 0.0
new bool:g_bCanJoin = true
new bool:g_bRestart = false
new bool:g_bGameRunning

// MsgIds
new gMsgIdScreenShake

// Handlers
new Trie:g_hObjectives
new g_hEntSpawnForward
new /*g_hHelpHud,*/ g_hTimerHud, g_hBomberHud, g_hGlobalAnnounces
new g_iWinnerId
new g_pRestart

#if defined BOT_SUPPORT
new g_iBotsRegistered = 0
#endif

// Bits
#define IsPlayer(%1) ( 0 < %1 <= g_iMaxPlayers )

#define IsInBit(%0,%1) ( %0 & (1<<%1) )
#define AddToBit(%0,%1) ( %0 |= (1<<%1) )
#define RemoveFromBit(%0,%1) ( %0 &= ~(1<<%1) )
new gHelp, gSpec, gSounds

// Chats & HUDS
new const g_szHuds[ _:HUDS - 1 ][] = { 
	"And the winner is... %s!!!",
	"The game is about to BEGIN!^nHit And Run...",
	"%s was last hit!",
	"%s was randomally picked!",
	"Time Left: %0.1f Seconds!"
}

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
	//	This plugin has been scripted by Khalid :)^n"
}

// - - - - - - - - - - - - WIN STUFF - - - - - - - - - - - - - - - -
new g_iLaserBeamIndex

new g_szAlarmSound[] = "alarm.wav"
new g_iAlarmSoundIndex

new gMp3Files

new g_szWinSounds[][] = {
	"win1.wav",
	"win2.wav", 
	"win3.wav",
	"win4.wav",
	"win5.wav",
	"win6.wav",
	"win7.wav",
	"win8.wav",
	"win9.wav",
	"win10.wav",
	"win11.wav",
	"win12.wav"
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
// -------------------------- Code start :) ----------------------------
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
public plugin_precache()
{
	g_iLaserBeamIndex = precache_model("sprites/laserbeam.spr")
	
	new szFile[60]
	
	new i
	for(i = 0; i < sizeof(g_szWinSounds); i++)
	{
		formatex(szFile, charsmax(szFile), "sound/hnr/%s", g_szWinSounds[i])
		Precache_Sound(szFile, i)
	}
	
	formatex(szFile, charsmax(szFile), "sound/hnr/%s", g_szAlarmSound)
	Precache_Sound(szFile, i)
	
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
		"func_buyzone"
	}
	
	for(new i; i < sizeof(szObjectives); i++)
	{
		TrieSetCell(g_hObjectives, szObjectives[i], 1)
	}
	
	g_hEntSpawnForward = register_forward(FM_Spawn, "fw_EntSpawn", 0)
}

stock Precache_Sound(szFile[], iNum)
{
	if(!file_exists(szFile))
	{
		return;
	}
	
	if(equali(szFile[strlen(szFile) - 4], ".mp3"))
	{
		precache_generic(szFile)
		
		if(iNum)
		{
			AddToBit(gMp3Files, iNum)
		}
	}
	
	else
	{
		precache_sound(szFile)
	}
}

public fw_EntSpawn(iEnt)
{
	new szClassName[50]; pev(iEnt, pev_classname, szClassName, 49)

	if(TrieKeyExists(g_hObjectives, szClassName) || contain(szClassName, "weapon_") != -1)
	{
		server_print(szClassName)
		remove_entity(iEnt)
	}
}

/* ------------- COLOR CHAT ------------------- */
enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}
/* ------------- COLOR CHAT ------------------- */

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// --- Remove Ent spawn stuff ---
	unregister_forward(FM_Spawn, g_hEntSpawnForward, 0)
	TrieDestroy(g_hObjectives)
	g_hEntSpawnForward = 0; g_hObjectives = Trie:0
	
	// --- RegisterHam Stuff ---
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 0)
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1)
	
	// --- Events ---
	register_event("HLTV",  "eNewRound", "a", "1=0", "2=0")
	register_event("TeamInfo", "eTeamInfo", "a")
	
	// --- Messages ---
	register_message(get_user_msgid("VGUIMenu"), "message_VGUIMenu")
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu")
	
	register_message(get_user_msgid("TextMsg"), "message_TextMsg")
	
	// --- Commands ----
	register_clcmd("chooseteam", "CmdChooseTeam")
	
	register_clcmd("say /help", "CmdHelp")
	register_clcmd("say /sound", "CmdSound")
	
	// --- Huds ----
	//g_hHelpHud = CreateHudSyncObj()
	g_hBomberHud = CreateHudSyncObj()
	g_hTimerHud = CreateHudSyncObj(1)
	g_hGlobalAnnounces = CreateHudSyncObj(2)
	
	// --- CVARS ---
	for(new i; i < sizeof(g_pCvarInfo); i++)
	{
		server_print("%s %s", g_pCvarInfo[i][0], g_pCvarInfo[i][1])
		g_pCvars[i] = register_cvar(g_pCvarInfo[i][0], g_pCvarInfo[i][1])
	}
	
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
	
	g_pRestart = get_cvar_pointer("sv_restart")
	
	gMsgIdScreenShake = get_user_msgid("ScreenShake")
	
	// Others
	if( !(g_iWeaponIndex = get_weaponid(MAIN_WEAPON)) )
	{
		log_amx("Non existance Main Weapon .. Defaulting to Scout!")
		g_iWeaponIndex = CSW_SCOUT
		MAIN_WEAPON = "weapon_scout"
	}
	
	g_iMaxPlayers = get_maxplayers()
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

public client_putinserver(id)
{
	//set_task(0.5, "JoinTeam", id)
	#if defined BOT_SUPPORT
	
	if(is_user_bot(id) && !g_iBotsRegistered)
	{
		set_task(1.0, "RegisterBots", id)
	}
	#endif
}

public RegisterBots(id)
{
	if(!is_user_connected(id) || g_iBotsRegistered)
		return;
		
	g_iBotsRegistered = 1
	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Killed")
}

public fw_Killed(id)
{
	if(cs_get_user_team(id) != CS_TEAM_T)
	{
		cs_set_user_team(id, CS_TEAM_T)
	}
}

public client_disconnect(id)
{
	if(IsInBit(gSpec, id))
	{
		RemoveFromBit(gSpec, id)
	}
	
	if(IsInBit(gHelp, id))
	{
		RemoveFromBit(gHelp, id)
	}
	
	if(IsInBit(gSounds, id))
	{
		RemoveFromBit(gSounds, id)
	}
	
	if(task_exists(id))
	{
		remove_task(id)
	}
	
	for(new i = TASKID_TIMER; i <= TASKID_HELP; i += 32)
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
	
	if(get_playersnum() < get_pcvar_num(g_pCvars[CVAR_MIN_PLAYERS]))
	{
		g_bGameRunning = false
		g_bCanJoin = true;
	}
}

public message_TextMsg(msgid, dest, id)
{
	static szArg[30]
	get_msg_arg_string(2, szArg, charsmax(szArg))
	
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
	
	if(equal(szArg, "#Game_teammate_attack"))
	{
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public message_VGUIMenu(msgid, dest, id)
{
	static const VGUI_CHOOSE_TEAM_MENU = 2
	
	server_print("%d", get_msg_arg_int(1))
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
		client_cmd(id, "joinclass 5")
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}	

public eTeamInfo()
{
	static szTeam[3]; read_data(2, szTeam, charsmax(szTeam))
	new id = read_data(1)
	
	if(szTeam[0] == 'U')
	{
		return;
	}
	
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
		
		server_print("Starting Game")
		
		set_pcvar_num(g_pRestart, 5)
		//eNewRound()
	}
	
	if(szTeam[0] == 'T')
	{
		set_task(0.5, "CheckAliveTeamInfo", id)
		
		return;
	}
	
	if(szTeam[0] == 'S')
	{
		AddToBit(gSpec, id)
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
		if(is_user_alive(id))
		{
			user_silentkill(id)
			cs_set_user_team(id, CS_TEAM_SPECTATOR)
		}
	}
		
	else
	{
		set_task(0.2, "SpawnPlayer", id)
	}
		
	if(IsInBit(gSpec, id))
	{
		RemoveFromBit(gSpec, id)
	}
}

public SpawnPlayer(id)
{
	if(!is_user_connected(id) || is_user_alive(id))
	{
		return;
	}
	
	server_print("*** SPAWN TASK *** ")
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public CmdChooseTeam(id)
{
	if(cs_get_user_team(id) != CS_TEAM_UNASSIGNED)
	{
		client_print(id, print_center, "This command is blocked")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public CmdJoinTeam(id)
{
	if(cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
	{
		return PLUGIN_CONTINUE
	}
	
	client_print(id, print_center, "This command is blocked")
	return PLUGIN_HANDLED
}

public CmdSound(id)
{
	if(IsInBit(gSounds, id))
	{
		RemoveFromBit(gSounds, id)
		ColorChat(id, NORMAL, "%s ^4Sounds now are ^3ENABLED ^4for you.", PREFIX)
	}
	
	else
	{
		AddToBit(gSounds, id)
		ColorChat(id, NORMAL, "%s ^4Sounds are now ^3DISABLED ^4for you.", PREFIX)
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
	
	if(task_exists(TASKID_TIMER))
	{
		remove_task(TASKID_TIMER)
	}
	
	server_print("New ROund")
	
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
	
	g_bCanJoin = true
	
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(!is_user_connected(i))
		{
			continue;
		}
		
		if(cs_get_user_team(i) == CS_TEAM_SPECTATOR)
		{
			cs_set_user_team(i, CS_TEAM_T)
		}
	}
	
	new Float:flNum = get_pcvar_float(g_pCvars[CVAR_START_TIME])
	
	g_iCurrentHud = GAME_PREPARE
	set_hudmessage(R, G, B, HUD_POS[g_iCurrentHud][X], HUD_POS[g_iCurrentHud][Y], 0, 0.0, flNum, HUD_POS[g_iCurrentHud][FADE_IN], HUD_POS[g_iCurrentHud][FADE_OUT], -1)
	ShowSyncHudMsg(0, g_hGlobalAnnounces, g_szHuds[g_iCurrentHud])
	
	server_print("TASK")
	set_task(flNum, "StartForward")
}

public StartForward()
{
	server_print("Found Task")
	if( CountPlayers() >= get_pcvar_num(g_pCvars[CVAR_MIN_PLAYERS]) )
	{
		client_cmd(0, "stopsound; mp3 stop");
		
		g_iBombId = 0;
		g_iWinnerId = 0;
		
		if(task_exists(TASKID_WIN_SPRITE))
		{
			remove_task(TASKID_WIN_SPRITE);
		}
		
		g_bCanJoin = false;
		
		server_print("Set BombeR")
		SetBomber(0, 1);
		
		set_task(0.1, "TimerHudTask", TASKID_TIMER, .flags = "b");
	}
}

public TimerHudTask(taskid)
{
	g_flTimer -= 0.1
	
	if(g_flTimer <= 0.0)
	{
		#if defined BOT_SUPPORT
		if(is_user_bot(g_iBombId))
		{
			new szName[32]; get_user_name(g_iBombId, szName, 31)
			server_print("Setting team for (KILL BOMB) %s to %d", szName, 1)
			set_pdata_int(g_iBombId, OFFSET_CSTEAMS, 1)
		}
		#endif
		DeathEffect(g_iBombId)
		user_kill(g_iBombId, 1)
		
		cs_set_user_team(g_iBombId, CS_TEAM_SPECTATOR)
		
		static iPlayers[32], iNum
		get_players(iPlayers, iNum, "a")
		
		if(iNum == 1)
		{
			remove_task(taskid)
			Winner(iPlayers[0])
			return;
		}
		
		server_print("Bomber")
		SetBomber(0, 1)
		
		return;
	}
	
	if(g_flTimer == 5.0)
	{
		PlaySound(g_szAlarmSound, g_iAlarmSoundIndex)
	}
		
	set_dhudmessage(R, G, B, HUD_POS[TIMER][X], HUD_POS[TIMER][Y], 0, 0.0, HUD_POS[TIMER][HOLD_TIME], HUD_POS[TIMER][FADE_IN], HUD_POS[TIMER][FADE_OUT])
	//ShowSyncHudMsg(0, g_hTimerHud, g_szHuds[TIMER], g_flTimer)
	show_dhudmessage(0, g_szHuds[TIMER], g_flTimer)
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
	10 )
}

stock PlaySound(szFile[] = "", iIndex)
{
	static iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum, "ch")
	
	new szSound[60]
	
	if(!szFile[0])
	{
		copy(szSound, charsmax(szSound), g_szWinSounds[iIndex])
	}
	
	else
	{
		copy(szSound, charsmax(szSound), szFile)
	}
	
	if(IsInBit(gMp3Files, iIndex))
	{
		for(new i; i < iNum; i++)
		{
			if( IsInBit( gSounds, ( iPlayer = iPlayers[i] ) ) )
			{
				continue;
			}
			
			client_cmd(iPlayer, "mp3 play ^"sound/hnr/%s^"", szFile)
		}
	}
	
	else
	{
		for(new i; i < iNum; i++)
		{
			if( IsInBit( gSounds, ( iPlayer = iPlayers[i] ) ) )
			{
				continue;
			}
			
			client_cmd(iPlayer, "spk ^"hnr/%s^"", szFile)
		}
	}
}

stock Winner(id)
{
	g_bCanJoin = false
	g_iWinnerId = id
	g_iBombId = 0
	
	static szName[32]; get_user_name(id, szName, 31)
	
	g_iCurrentHud = WIN
	SET_HUD_MESSAGE()
	ShowSyncHudMsg(0, g_hGlobalAnnounces, g_szHuds[g_iCurrentHud], szName)

	WinSpriteEffect(TASKID_WIN_SPRITE)
	set_task(get_pcvar_float(g_pCvars[CVAR_DELAY_BETWEEN_WIN_SPRITE]), "WinSpriteEffect", TASKID_WIN_SPRITE, .flags = "b")
	
	set_pcvar_num(g_pRestart, 5)
	
	new iRan = random_num(0, sizeof(g_szWinSounds) - 1)
	PlaySound(g_szWinSounds[iRan], iRan)
}

public WinSpriteEffect(taskid)
{	
	if(!g_iWinnerId)
	{
		remove_task(taskid)
		return;
	}
	
	static iOrigin[3]; get_user_origin(g_iWinnerId, iOrigin, 0)
	
	TempEntity(TE_BEAMTORUS, iOrigin, 350, g_iLaserBeamIndex, random(256), random(256), random(256), 128, 255, 30)
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
		write_coord(iOrigin[2] + iZVectorIncrement)			// axis.z
		write_short(iSpriteIndex)			// sprite index
		write_byte(0)      				// starting frame
		write_byte(0)       				// frame rate in 0.1's
		write_byte(10)        				// life in 0.1's
		write_byte(iWidth)	       			// line width in 0.1's
		write_byte(iAmplitude)        			// noise amplitude in 0.01's
		write_byte(r == -1 ? random(256) : r)		// r
		write_byte(g == -1 ? random(256) : g)		// g
		write_byte(b == -1 ? random(256) : b)		// b
		write_byte(iBrightness)				// brightness
		write_byte(1)					// scroll speed in 0.1's
	}	
	message_end()
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
	
	server_print("iCount is %d", iCount)
	return iCount
}

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	server_print("Called Spawn")
	
	if(cs_get_user_team(id) != CS_TEAM_T)
	{
		cs_set_user_team(id, CS_TEAM_T)
	}
	
	if(!CanJoin())
	{
		server_print("CANT JOIN")
		set_task(0.2, "KillPlayer", id)
		return;
	}
	
	server_print("Giving ITEMS")
	UnSetBomber(id)
	GiveItems(id)
	ColorChat(id, NORMAL, "%s ^4Agent: ^3These are your weapons, try to ^4survive^3!!!", PREFIX)
}

public KillPlayer(id)
{
	if(is_user_connected(id))
	{
		user_kill(id, 1)
		cs_set_user_team(id, CS_TEAM_SPECTATOR)
	}
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
	strip_user_weapons(id)
	
	give_item(id, "weapon_knife")
	
	cs_set_weapon_ammo(give_item(id, MAIN_WEAPON), WEAPON_AMMO)
	cs_set_user_bpammo(id, g_iWeaponIndex, 0)
	
	give_item(id, "weapon_flashbang")
	cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
	
	give_item(id, "weapon_hegrenade")
	give_item(id, "weapon_smokegrenade")
}

public fw_TakeDamage(id, idInflector, iAttacker, Float:flDamage, iDamageBits)
{
	SetHamParamFloat(4, 0.0)
	
	if(IsPlayer(iAttacker) && iAttacker == g_iBombId && IsPlayer(id))
	{
		#if defined BOT_SUPPORT
		if(is_user_bot(id))
		{
			new szName[32]; get_user_name(id, szName, 31)
			server_print("Setting team for Victim %s to %d", szName, 2)
			set_pdata_int(id, OFFSET_CSTEAMS, 2)
		}
		
		if(is_user_bot(iAttacker))
		{
			new szName[32]; get_user_name(iAttacker, szName, 31)
			server_print("Setting team for Attacker %s to %d", szName, 1)
			set_pdata_int(iAttacker, OFFSET_CSTEAMS, 1)
		}
		#endif
		
		SetBomber(id, 0)
	}
}

stock SetBomber(id = 0, iReset = 1)
{
	server_print("Set Bomber id %d iReset %d", id, iReset)
	
	if(!id)
	{
		new iPlayers[32], iNum
		get_players(iPlayers, iNum, "ah")
		server_print("iPlayers Num = %d", iNum)
		
		id = iPlayers[random_num(0, iNum - 1)]
		g_iCurrentHud = NEW_BOMBER_RANDOM
		
		#if defined BOT_SUPPORT
		if(is_user_bot(id))
		{
			new szName[32]; get_user_name(id, szName, 31)
			server_print("Setting team for New bomber (random) %s to %d", szName, 2)
			set_pdata_int(id, OFFSET_CSTEAMS, 2)
		}
		#endif
	}
	
	else
	{
		UnSetBomber(g_iBombId)
		g_iCurrentHud = NEW_BOMBER_HIT
	}
	
	static szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	BomberEffects(id)
	g_iBombId = id
	
	SET_HUD_MESSAGE()

	ShowSyncHudMsg(0, g_hBomberHud, g_szHuds[g_iCurrentHud], szName)
	
	if(iReset)
	{
		g_flTimer = get_pcvar_float(g_pCvars[CVAR_TIMER_TIME]) + 0.1
	}
}

stock UnSetBomber(id)
{
	set_user_rendering(id)
	//, kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 255)
}

stock BomberEffects(id)
{
	set_user_rendering(id, kRenderFxGlowShell, random(256), random(256), random(256), kRenderTransAlpha, 16)
	UTIL_ScreenShake(id)
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
/* ----------------------------- COLOR CHAT -------------------------- */

new const TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

stock ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
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
	static bool:saytext_used;
	static get_user_msgid_saytext;
	if(!saytext_used)
	{
		get_user_msgid_saytext = get_user_msgid("SayText");
		saytext_used = true;
	}
	message_begin(type, get_user_msgid_saytext, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

stock Team_Info(id, type, team[])
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

stock ColorSelection(index, type, Color:Type)
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

