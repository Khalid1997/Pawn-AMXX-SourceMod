#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <sqlx>
#include <fakemeta_util>

#define PLUGIN "Ghost walkers mode"
#define VERSION "2.31"
#define AUTHOR "Khalid"

#define ADMIN		ADMIN_BAN
#define SILVER		ADMIN_LEVEL_H
#define GOLDEN		ADMIN_LEVEL_G
#define FINAL		(ADMIN|SILVER|GOLDEN)

enum _:TaskIds (+= 1000)
{
	TASKID_HUD = 1000,
	TASKID_GHOST2,	//2000
	TASKID_WIND,	//3000
	TASKID_UM 	//4000
}

enum
{
	ADD,
	TAKE
}

/*enum
{
	UNASSIGNED = 0,		// 0
	TERRORIST,		// 1
	COUNTER_TERRORIST,	// 2
	SPECTATOR		// 3
}*/

// Is the mode running?
new bool:g_bModRunning = false

// **** Hud message ****
//new gSyncHud

// **** GhostStuff ****
// Ghost pointers
new g_pKillBonus, g_pGhostBonusFrags, g_pSurvivorsBonusFrags, g_pLighting
// Others
new CsTeams:g_iActivatorTeam

// **** SQLX ****
new Handle:Sql

// Block buy zone
new bool:gBlockBuyZone;
new gMsgStatusIcon;
// for block pickup
new g_iMaxPlayers


new szGhostModel[] = "ghost1"

enum
{
	GHOST2 = 0,
	WIND1,
	GHOST_KILL,
	GHOST_ARRIVED
}

new const szGhostSounds[][] = {
	"ghosts2.wav",
	"wind1.wav",
	"ghost_kill.wav",
	"ghosts_arrived.wav"
}

public plugin_precache()
{
	new SoundPath[50]
	
	for(new i; i < sizeof szGhostSounds; i++)
	{
		formatex(SoundPath, charsmax(SoundPath), "ghostmode/%s", szGhostSounds[i])
		precache_sound(SoundPath)
	}
	
	formatex(SoundPath, charsmax(SoundPath), "models/player/%s/%s.mdl", szGhostModel, szGhostModel)
	precache_model(SoundPath)
}

public plugin_init()
{
	// -------- Plugin info registration --------
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// ------- Commands --------
	register_concmd("spt_ghost_walkers", "admin_ghost", FINAL)
	register_clcmd("say /ghost", "admin_ghost", FINAL)
	register_clcmd("drop", "hook_drop")
	
	// ------- Cvars --------
	g_pKillBonus =			register_cvar("survivors_bonus_minutes_per_kill", "50")
	g_pGhostBonusFrags =		register_cvar("ghost_bonus_frags", "2")
	g_pSurvivorsBonusFrags =	register_cvar("survivors_bonus_frags", "3")
	g_pLighting =			register_cvar("ghost_lighting", "d")
	
	// ------- Exents --------
	//register_event("HLTV", "NewRound", "a", "1=0", "2=0")
	register_event("DeathMsg", "Kill_Event", "a")
	
	// ------- SQL --------
	Sql = SQL_MakeStdTuple()
	
	// ------- Others -------
	RegisterHam(Ham_Player_PreThink, "player", "Client_PreThink")
	RegisterHam( Ham_Touch, "armoury_entity", "FwdHamPlayerPickup" );
	RegisterHam( Ham_Touch, "weaponbox", "FwdHamPlayerPickup" );
	RegisterHam(Ham_Spawn, "player", "NewRound", 1)
	
	g_iMaxPlayers = get_maxplayers()
	
	// Grab StatusIcon message ID
	gMsgStatusIcon = get_user_msgid("StatusIcon");
	
	// Hook StatusIcon message
	register_message(gMsgStatusIcon, "MessageStatusIcon");
	
	// For Model changes
	//register_forward( FM_SetClientKeyValue, "fw_SetClientKeyValue" )
}

/*public fw_SetClientKeyValue( id, const infobuffer[], const key[] )
	if(g_bModRunning && equal(key,8 "model") && cs_get_user_team(id) == g_iActivatorTeam)
		return FMRES_SUPERCEDE*/

public admin_ghost(id, level, cid)
{
	if( !cmd_access(id, level, cid, 1) ) 
		return PLUGIN_HANDLED
	
	if( g_bModRunning )
	{
		console_print(id, "*** Ghost Walkers mode is already running")
		return PLUGIN_HANDLED
	}
	
	if( !is_user_alive(id) )
	{
		console_print(id, "*** You need to be alive to activate Ghost Walkers mode.")
		return PLUGIN_HANDLED
	}
	
	new iFlags = get_user_flags(id)
	
	new szLeveL[15]
	
	if( iFlags & ADMIN )
		szLeveL = "Administrator"
	
	else if( iFlags & SILVER )
		szLeveL = "Silver Player"
	
	else if( iFlags & GOLDEN )
		szLeveL = "Golden Player"
	
	new CsTeams:iTeam
	g_iActivatorTeam = cs_get_user_team(id); iTeam = g_iActivatorTeam //check_team(id)
	
	new players[32], count, player
	
	/*if( iTeam == UNASSIGNED || iTeam == SPECTATOR )*/
	if( iTeam == CS_TEAM_SPECTATOR || iTeam == CS_TEAM_UNASSIGNED )
	{
		console_print(id, "*** You must join a team to activate Ghost Walker mode!")
		return PLUGIN_HANDLED
	}
	
	get_players(players, count, "ae", (iTeam == CS_TEAM_T/*TERRORIST*/ ? "TERRORIST" : "CT"))

	for(new i; i < count; i++)
	{
		player = players[i]
		
		strip_user_weapons(player)
		give_item(player, "weapon_knife")
		give_item(player, "weapon_usp")
		cs_set_user_bpammo(player, CSW_USP, 100)
		
		set_user_noclip(player, 1)
		cs_set_user_model(player,/* model*/ szGhostModel)
	}
	
	get_players(players, count, "ae", (iTeam == CS_TEAM_T/*TERRORIST*/ ? "CT" : "TERRORIST"))	// Get the other team
	
	for(new i; i < count; i++)
	{
		player = players[i]
		cs_set_user_money(player, 10000, 1)
	}
	
	
	
	new szHud[200], szActivatorName[32]
	get_user_name(id, szActivatorName, 31)
	formatex(szHud, charsmax(szHud), "Ghost Walkers mode activated by %s %s!^nAll the %s team are ghosts", szLeveL, szActivatorName, ( iTeam == CS_TEAM_T/*TERRORIST*/ ? "Terrorist" : "Counter Terrorist"))
	formatex(szHud, charsmax(szHud), "Ghost Walkers mode activated by %s %s!^nAll the %s team are ghosts", szLeveL, szActivatorName, ( iTeam == CS_TEAM_T/*TERRORIST*/ ? "Terrorist" : "Counter Terrorist"))
	
	set_task(0.1, "show_hud", TASKID_HUD, szHud, charsmax(szHud), "b")
	
	g_bModRunning = true

	/* *************************** Chat Messages ************************* */
	client_print(0, print_chat, "*** %s %s has activated Ghost Walkers mode. Everything will return to normal next round.", szLeveL, szActivatorName)
	client_print(0, print_chat, "*** All players of %s's team (%s) are now ghosts. They only have the USP gun now.", szActivatorName, (iTeam == CS_TEAM_T/*TERRORIST*/ ? "Terrorist" : "Counter-Terrorist"))
	client_print(0, print_chat, "*** If a ghost gets killed, the killer will have %d extra frags (kills) to his score.", get_pcvar_num(g_pSurvivorsBonusFrags))
	client_print(0, print_chat, "*** If a ghost kills someone, he will get %d extra frags (kills) to his score.", get_pcvar_num(g_pGhostBonusFrags))
	client_print(0, print_chat, "*** Don't forget to buy nightvision goggle.")
	
	new light[2]
	get_pcvar_string(g_pLighting, light, charsmax(light))
	set_lights(light[0])
	
	//g_iActivatorTeam = iTeam
	
	BlockBuyZones()
	
	/* ------------ Play Sounds ------------- */
	ArrivedSound()
	GhostSound()
	new SoundFile[60]
	formatex(SoundFile, charsmax(SoundFile), "sound/ghostmode/%s", szGhostSounds[WIND1])
	set_task(GetWavDuration(SoundFile), "WindSound", TASKID_WIND, .flags="b")
	//WindSound()
	/* -------------------------------------- */
	
	console_print(id, "*** You have activated Ghost Walkers Mode")
	return PLUGIN_CONTINUE
}

public NewRound()
{
	if(g_bModRunning)
	{
		for(new i = 1; i <=  g_iMaxPlayers; i++)
		{
			if(is_user_connected(i))
				if(cs_get_user_team(i) == g_iActivatorTeam)
				{
					set_user_noclip(i, 0)
					cs_reset_user_model(i)
				}
		}
		
		new something = 1000
		for(new i; i <= 4; i++)
		{
			if(task_exists(something))
				remove_task(something)
			
			something += 1000
		}

		UnblockBuyZones()
		set_lights("#OFF")

		client_cmd(0, "stopsound")
		
		g_bModRunning = false
	}
}
			
public Kill_Event()
{
	if(g_bModRunning)
	{
		new iKiller = read_data(1)
		new iVictim = read_data(2)
		
		new szWeap[10]
		read_data(4, szWeap, 9)
		
		new CsTeams:iTeam
		iTeam = cs_get_user_team(iVictim)//check_team(iVictim)
		
		if(iVictim == iKiller && iTeam == g_iActivatorTeam)
			return PLUGIN_CONTINUE
		
		new iMinutes, szKillerName[32], iFrags
		
		if(iTeam == g_iActivatorTeam)	// Ghost gets killed
		{
			
			if(equali(szWeap, "knife"))
			{
				
				iMinutes = get_pcvar_num(g_pKillBonus)
				get_user_name(iKiller, szKillerName, charsmax(szKillerName))
				
				client_print(0, print_chat, "*** %d minutes have been added to %s for killing a Ghost", iMinutes, szKillerName)
				
				managetime(iKiller, ADD, iMinutes)
			}
			
			else
			{
				iFrags = get_pcvar_num(g_pSurvivorsBonusFrags)
				get_user_name(iKiller, szKillerName, charsmax(szKillerName))
				client_print(0, print_chat, "*** %d frags have been added to %s for killing a Ghost", iFrags, szKillerName)
			
				set_user_frags(iKiller, (iFrags + get_user_frags(iKiller)) - 1)
			}
		}
		
		else				// Ghost kills someone
		{
			iFrags = get_pcvar_num(g_pGhostBonusFrags)
			get_user_name(iKiller, szKillerName, charsmax(szKillerName))
			client_print(0, print_chat, "*** %d frags have been added to %s for killing a human", iFrags, szKillerName)
			
			set_user_frags(iKiller, iFrags + get_user_frags(iKiller))
			
			PlayGhostKillSound()
		}
	}
	
	return PLUGIN_CONTINUE
}

public show_hud(Text[], A_NUM)
{
	set_hudmessage(255, 255, 0, -1.0, 0.20, 0, 0.1, 0.1, 0.1, 0.0, 4)
	show_hudmessage(0, "%s", Text)
}

public query(FailState, Handle:Query, Error[], Errcode)
{
	if( Errcode )
	{
		server_print("ERROR IN GHOSTWALKERS MODE SQL:")
		server_print("%s", Error)
		
	}
}

stock managetime(index, num, itime)
{
	new szName[32]
	get_user_name(index, szName, 31)
	
	static szQuery[512]
	
	switch(num)
	{
		case ADD:
			formatex(szQuery, charsmax(szQuery), "UPDATE played_time SET playedtime = playedtime + %d WHERE name = '%s'", itime, szName)
		case TAKE:
			formatex(szQuery, charsmax(szQuery), "UPDATE played_time SET playedtime = playedtime - %d WHERE name = '%s'", itime, szName)
	}
	
	SQL_ThreadQuery(Sql, "query", szQuery)
}

public Client_PreThink(id)
{
	new iUserFlags = pev(id, pev_flags)
	set_pev(id, pev_flags, (iUserFlags | FL_ONGROUND ) )
}

public client_putinserver(id)
{
	if( g_bModRunning )
	{
		new light[2]
		get_pcvar_string(g_pLighting, light, charsmax(light))
		set_lights(light[0])
	}
}

public WindSound()
{
	//static i
	client_cmd(0, "spk ^"ghostmode/wind1^"")
	
	/*if(task_exists(TASKID_WIND))
	{
		client_cmd(0, "spk ^"ghostmode/wind1^"")
		server_print("%d", i)
		
		return;
	}
	
	new SoundFile[60]
	formatex(SoundFile, charsmax(SoundFile), "sound/ghostmode/%s", szGhostSounds[WIND1])
	set_task(GetWavDuration(SoundFile), "WindSound", TASKID_WIND, .flags="b")*/

	server_print("Running Wind Sound")
}

public GhostSound()
{
	if(task_exists(TASKID_GHOST2))
	{
		client_cmd(0, "pk ^"ghostmode/ghosts2^"")
		return PLUGIN_HANDLED
	}
	
	client_cmd(0, "spk ^"ghostmode/ghosts2^"")
	
	static SoundFile[60]
	formatex(SoundFile, charsmax(SoundFile), "sound/ghostmode/%s", szGhostSounds[GHOST2])
	set_task(GetWavDuration(SoundFile), "GhostSound", TASKID_GHOST2, .flags="b")
	
	return PLUGIN_CONTINUE
}

ArrivedSound()
{
	client_cmd(0, "spk ^"ghostmode/ghost_arrived^"")
}

PlayGhostKillSound()
{
	client_cmd(0, "spk ^"ghostmode/ghost_kill^"")
}

/*stock check_team(id)
{
	new szTeam[5]
	get_user_team(id, szTeam, charsmax(szTeam))
	
	switch(szTeam[0])
	{
		case 'T':
			return TERRORIST
		
		case 'C':
			return COUNTER_TERRORIST
		
		case 'S':
			return SPECTATOR
		
		default:
			return UNASSIGNED
	}
	return -1
}*/

/* ***** Block pickup, drop, buy for g_iActivatorTeam ***** */
public hook_drop(id)
{
	if(g_bModRunning && cs_get_user_team(id) == g_iActivatorTeam)
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public FwdHamPlayerPickup( iEntity, id )
{
	return ( 1 <= id <= g_iMaxPlayers && g_bModRunning && is_user_alive(id) && cs_get_user_team(id) == g_iActivatorTeam ) ? HAM_SUPERCEDE : HAM_IGNORED
}

public MessageStatusIcon(msgID, dest, receiver)
{
	
	// Check if status is to be shown
	if(gBlockBuyZone && get_msg_arg_int(1) && cs_get_user_team(receiver) == g_iActivatorTeam) {
		
		new const buyzone[] = "buyzone";
		
		// Grab what icon is being shown
		new icon[sizeof(buyzone) + 1];
		get_msg_arg_string(2, icon, charsmax(icon));
		
		// Check if buyzone icon
		if(equal(icon, buyzone)) {
			
			// Remove player from buyzone
			RemoveFromBuyzone(receiver);
			
			// Block icon from being shown
			set_msg_arg_int(1, ARG_BYTE, 0);
			
		}
		
	}
	
	return PLUGIN_CONTINUE;
	
}

BlockBuyZones()
{
	
	new szTeam[10]
	new players[32], pnum, player
	switch(g_iActivatorTeam)
	{
		case CS_TEAM_CT/*COUNTER_TERRORIST*/:
		{
			szTeam = "CT"
		}
		
		case CS_TEAM_T/*TERRORIST*/:
		{
			szTeam = "TERRORIST"
		}
	}
	
	// Get all alive players from activator team
	get_players(players, pnum, "ae", szTeam);
	
	for(new i; i < pnum; i++)
	{
		player = players[pnum]
		// Hide buyzone icon from all players
		message_begin(MSG_BROADCAST, gMsgStatusIcon);
		write_byte(player);
		write_string("buyzone");
		message_end();
	}
	
	
	// Remove all alive players from buyzone
	while(pnum-- > 0) {
		player = players[pnum]
		RemoveFromBuyzone(player);
	}
	
	// Set that buyzones should be blocked
	gBlockBuyZone = true;
	
}

RemoveFromBuyzone(id)
{
	
	// Define offsets to be used
	const m_fClientMapZone = 235;
	const MAPZONE_BUYZONE = (1 << 0);
	const XO_PLAYERS = 5;
	
	// Remove player's buyzone bit for the map zones
	set_pdata_int(id, m_fClientMapZone, get_pdata_int(id, m_fClientMapZone, XO_PLAYERS) & ~MAPZONE_BUYZONE, XO_PLAYERS);
	
}

UnblockBuyZones()
{
	
	// Set that buyzone should not be blocked
	gBlockBuyZone = false;
	
}
/* -------------------------------------------------------- */

stock Float:GetWavDuration( const WavFile[] )
{
	new Frequence [ 4 ];
	new Bitrate   [ 2 ];
	new DataLength[ 4 ];
	new File;
	
	// --| Open the file.
	File = fopen( WavFile, "rb" );
	
	// --| Get the frequence from offset 24. ( Read 4 bytes )
	fseek( File, 24, SEEK_SET );
	fread_blocks( File, Frequence, 4, BLOCK_INT );
	
	// --| Get the bitrate from offset 34. ( read 2 bytes )
	fseek( File, 34, SEEK_SET ); 
	fread_blocks( File, Bitrate, 2, BLOCK_BYTE );
	
	// --| Search 'data'. If the 'd' not on the offset 40, we search it.
	if ( fgetc( File ) != 'd' ) while( fgetc( File ) != 'd' && !feof( File ) ) {}
	
	// --| Get the data length from offset 44. ( after 'data', read 4 bytes )
	fseek( File, 3, SEEK_CUR ); 
	fread_blocks( File, DataLength, 4, BLOCK_INT );

	// --| Close file.
	fclose( File );
	
	// --| Calculate the time. ( Data length / ( frequence * bitrate ) / 8 ).
	return float( DataLength[ 0 ] ) / ( float( Frequence[ 0 ] * Bitrate[ 0 ] ) / 8.0 );
}

/*stock fm_set_user_model(id, model[])
{
	set_pev(id, pev_viewmodel2, model[])
	engfunc(EngFunc_SetModel, */
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
