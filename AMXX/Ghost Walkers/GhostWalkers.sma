#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <cstrike>
#include <played_time>
#include <sqlx>

#define WITH_LIMIT
#if defined WITH_LIMIT
	#include <nvault>
#endif

#define VERSION		"2.75"

#define ADMIN		ADMIN_BAN
#define SILVER		ADMIN_LEVEL_H
#define GOLDEN		ADMIN_LEVEL_G
#define FINAL		(ADMIN|SILVER|GOLDEN)

enum		(+= 1000)
{
	TASKID_HUD = 1000,
	TASKID_GHOST2,	//2000
	TASKID_WIND,	//3000
	TASKID_UM 	//4000
}
enum
{
	GHOST2 = 0,
	WIND1,
	GHOST_KILL,
	GHOST_ARRIVED
}

#if defined WITH_LIMIT
new const GhostUses[3] = {
	3,	// ADMIN
	2,	// GOLDEN
	1	// SILVER
}
#endif

new const szGhostSounds[][] = {
	"ghosts2",
	"wind1",
	"ghost_kill",
	"ghosts_arrived"
}
new const szGhostModel[] = "ghost1"

// ------------------------------------
// ---------- Bools/Variables ---------
new bool:	g_bRunning = false
new 		g_iMaxPlayers
new CsTeams:	g_iActivatorTeam

// **** Cvars ***	G = Ghost, H = Human
new 		g_pGFragsPerKill, g_pHKnife_Minutes, g_pHFragsPerKill, g_pLighting, 
		g_pHMoney, g_pGUspAmmo

// **** Handlers ****
#if defined WITH_LIMIT
new		g_Vault
#endif

// Block buy zoneo
new 		gMsgStatusIcon;

new bool:gBlockBuyZone = false
public plugin_precache()
{
	new SoundPath[50]
	
	for(new i; i < sizeof szGhostSounds; i++)
	{
		formatex(SoundPath, charsmax(SoundPath), "ghostmode/%s.wav", szGhostSounds[i])
		precache_sound(SoundPath)
	}
	
	formatex(SoundPath, charsmax(SoundPath), "models/player/%s/%s.mdl", szGhostModel, szGhostModel)
	precache_model(SoundPath)
}

public plugin_init() {
	register_plugin("Ghost Walkers", VERSION, "Khalid :)")
	
	register_clcmd("say /ghost", "admin_ghost", FINAL)
	register_concmd("spt_ghost_walker", "admin_ghost", FINAL)
	register_clcmd("drop", "hook_drop")
	
	register_event("HLTV", "NewRound",  "a", "1=0", "2=0")
	register_event("DeathMsg", "Kill_Event", "a")
	
	register_touch("armoury_entity", "player", "Fw_PickUp")
	register_touch("weaponbox", "player", "Fw_PickUp")
	
	register_clcmd("jointeam", "BlockTeamJoin")
	register_clcmd("chooseteam", "BlockTeamJoin")
	
	// Grab StatusIcon message ID
	gMsgStatusIcon = get_user_msgid("StatusIcon")
	// Hook StatusIcon message
	register_message(gMsgStatusIcon, "MessageStatusIcon")
	
	g_iMaxPlayers = get_maxplayers()
	
	// Cvars
	g_pGFragsPerKill	= register_cvar("ghost_frags_per_kill", 	"2"	)
	g_pHKnife_Minutes	= register_cvar("human_knife_ghost_minutes", 	"50"	)
	g_pHFragsPerKill	= register_cvar("human_frags_ghost_kill", 	"3"	)
	g_pLighting		= register_cvar("ghost_lighting",		"g"	)
	g_pHMoney		= register_cvar("human_money",			"10000"	)
	g_pGUspAmmo		= register_cvar("ghost_usp_ammo",		"100"	)
}

public plugin_cfg()
{
	#if defined WITH_LIMIT
	g_Vault = 	nvault_open("ghost_uses")
	
	new vault_day = nvault_get(g_Vault, "day")
	new szDay[5]
	get_time("%j", szDay, charsmax(szDay))
	new iDay = str_to_num(szDay)
	
	if(!vault_day)
		nvault_set(g_Vault, "day", szDay)

	if(iDay != vault_day)
	{
		server_print("--------------------------------------------------------------")
		server_print("[GHOST WALKERS] The day is not the same, clearing Ghost uses!")
		server_print("--------------------------------------------------------------")
		nvault_prune(g_Vault, 0, get_systime())
		nvault_set(g_Vault, "day", szDay)
	}
	#endif
}

public client_putinserver(id)
{
	if(g_bRunning)
	{
		static light[2]
		get_pcvar_string(g_pLighting, light, 1)
		set_lights(light[0])
	}
}
	
public admin_ghost(id, level, cid)
{
	new iFlags = get_user_flags(id)
	if(!(iFlags & FINAL))
	{
		console_print(id, "You don't have access to this command.")
		return PLUGIN_HANDLED
	}
	
	#if defined WITH_LIMIT

	if(!Allow_Activate(id, iFlags))
	{
		console_print(id,"*** You have reached limit of activating Ghost Walkers mode.")
		return PLUGIN_HANDLED
	}
	#endif
	
	if(g_bRunning)
	{
		console_print(id, "*** The mode is already activated!")
		return PLUGIN_HANDLED
	}

	if(!is_user_alive(id))
	{
		console_print(id, "*** You need to be alive to activate ghost walkers mode.")
		return PLUGIN_HANDLED
	}
	
	new szLeveL[16]
	if( iFlags & ADMIN )
		szLeveL = "Administrator"

	else if( iFlags & SILVER )
		szLeveL = "Silver Player"

	else if( iFlags & GOLDEN )
		szLeveL = "Golden Player"

	new CsTeams:iTeam = cs_get_user_team(id)
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(is_user_alive(i))
		{
			if(cs_get_user_team(i) == iTeam)
			{
				//cs_get_user_model(i, szPlayerModels[i], sizeof szPlayerModels - 1)
				cs_set_user_model(i, szGhostModel)
				strip_user_weapons(id)
				give_item(id, "weapon_knife")
				give_item(id, "weapon_usp")
				cs_set_user_bpammo(id, CSW_USP, get_pcvar_num(g_pGUspAmmo))
				set_user_noclip(i, 1)
			}
			
			cs_set_user_money(i, get_pcvar_num(g_pHMoney), 1)
		}
	}

	g_iActivatorTeam = iTeam
	new cvar[2]
	get_pcvar_string(g_pLighting, cvar, 1)
	set_lights(cvar[0])

	/* ------------ Play Sounds ------------- */
	ArrivedSound()
	GhostTwoSound()
	WindSound()
	/* -------------------------------------- */
	#if defined WITH_LIMIT
	Used_Once(id)		// Add a one-time use
	#endif
	
	g_bRunning = true

	new szHud[200], szActivatorName[32]
	get_user_name(id, szActivatorName, 31)
	formatex(szHud, charsmax(szHud), "Ghost Walkers mode activated by %s %s^nAll the %s team are ghosts", szLeveL, szActivatorName, ( iTeam == CS_TEAM_T/*TERRORIST*/ ? "Terrorist" : "Counter Terrorist"))
	set_task(1.0, "show_hud", TASKID_HUD, szHud, charsmax(szHud), "b")
	
	BlockBuyZones()
	
	return PLUGIN_CONTINUE
}

#if defined WITH_LIMIT
Allow_Activate(id, iFlags)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	new Uses = nvault_get(g_Vault, szName) 
	
	if(Uses)
	{
		if(iFlags & ADMIN && Uses < GhostUses[0])
			return 1
			
		else if( iFlags & SILVER && Uses < GhostUses[2])
			return 1
		
		else if(iFlags & GOLDEN && Uses < GhostUses[1])
			return 1
		
		else return 0
	}
	
	nvault_set(g_Vault, szName, "0")
	return 1
}

Used_Once(id)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	new CurrentUses[4]
	CurrentUses[0] = nvault_get(g_Vault, szName)
	nvault_remove(g_Vault, szName)
	num_to_str(CurrentUses[0] + 1, CurrentUses, charsmax(CurrentUses))
	nvault_set(g_Vault, szName, CurrentUses)
}
#endif

public NewRound()
{
	if(g_bRunning)
	{
		for(new i = 1; i <= g_iMaxPlayers; i++)
		{
			if(is_user_connected(i))
			{
				if(cs_get_user_team(i) == g_iActivatorTeam)
				{
					cs_reset_user_model(i)
					set_user_noclip(i, 0)
				}
			}
		}

		set_lights("#OFF")
		g_bRunning = false

		for(new i; i < 5000; i +=1000)
			if(task_exists(i))
				remove_task(i)

		client_cmd(0, "stopsound")
		
		UnblockBuyZones()
	}
}

public Kill_Event()
{
	if(g_bRunning)
	{
		new iKiller = read_data(1)
		new iVictim = read_data(2)
		static szWeapon[15]
		read_data(4, szWeapon, charsmax(szWeapon))
		
		if(
			( iKiller == iVictim && equal(szWeapon, "world", 5) ) ||
			!iKiller && 
			(
				equal( szWeapon, "world", 5 ) || 
				equal( szWeapon, "door", 4 ) ||
				equal( szWeapon, "trigger_hurt", 12 )
			)
		)
			return;
			
		new szName[32], iNum
		get_user_name(iKiller, szName, charsmax(szName))

		if(cs_get_user_team(iKiller) != g_iActivatorTeam)	// Not a ghost
		{
			
			if(szWeapon[0] == 'k')
			{
				iNum = get_pcvar_num(g_pHKnife_Minutes)
				client_print(0, print_chat, "*** %d minutes have been added to player %s for knifing a ghost.", iNum, szName)
				addtime(iKiller, iNum)
				
			}
			
			else
			{
				iNum = get_pcvar_num(g_pHFragsPerKill)
				client_print(0, print_chat, "*** %d frags have been added to player %s for killing a ghost.", iNum, szName)
				set_user_frags(iKiller, (get_user_frags(iKiller) + iNum) - 1)
			}
			
			//PlayGhostKillSound()
			return;
		}
		
		iNum = get_pcvar_num(g_pGFragsPerKill)
		client_print(0, print_chat, "*** %d frags have been added to ghost %s for killing a human", iNum, szName)
		set_user_frags(iKiller, (get_user_frags(iKiller) + iNum))
		PlayGhostKillSound()
	}
}

public hook_drop(id)
{
	if(g_bRunning && cs_get_user_team(id) == g_iActivatorTeam)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}
	
		
public Fw_PickUp(ent, id)
	return ( ( 1 <= id <= g_iMaxPlayers ) && g_bRunning && is_user_alive(id) && cs_get_user_team(id) == g_iActivatorTeam ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE

public show_hud(Msg[], taskid)
{
	set_hudmessage(255, 255, 0, -1.0, 0.20, 0, 0.0, 0.9, 0.1, 0.1 , 4)
	show_hudmessage(0, Msg)
}

public BlockTeamJoin(id)
{
	if(g_bRunning && cs_get_user_team(id) == g_iActivatorTeam)
	{
		client_print(id, print_center, "*** You can't change team during Ghost Walkers mode!")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}


public plugin_end()
{
	#if defined WITH_LIMIT
	nvault_close(g_Vault)
	#endif
}	
/* ------------------------------------------------------------- */
/* -------------------        STOCKS         ------------------- */
/* ------------------------------------------------------------- */

stock addtime(index, itime)
{
	set_user_playedtime(index, get_user_playedtime(index) + itime)
}

enum
{
	GHOST2 = 0,
	WIND1,
	GHOST_KILL,
	GHOST_ARRIVED
}


public WindSound()
{
	client_cmd(0, "spk ^"ghostmode/%s^"", szGhostSounds[WIND1])
}

public GhostTwoSound()
{
	if(task_exists(TASKID_GHOST2))
	{
		client_cmd(0, "spk ^"ghostmode/%s^"", szGhostSounds[GHOST2])
		return;
	}
	
	client_cmd(0, "spk ^"ghostmode/%s^"", szGhostSounds[GHOST2])
	static SoundFile[60]
	formatex(SoundFile, charsmax(SoundFile), "sound/ghostmode/%s.wav", szGhostSounds[GHOST2])
	
	static Float:flDuration
	if(!flDuration)
		flDuration = GetWavDuration(SoundFile)
		
	set_task(flDuration, "GhostTwoSound", TASKID_GHOST2,_,_, "b")
}

ArrivedSound()
{
	client_cmd(0, "spk ^"ghostmode/%s^"", szGhostSounds[GHOST_ARRIVED])
}

PlayGhostKillSound()
{
	client_cmd(0, "spk ^"ghostmode/%s^"", szGhostSounds[GHOST_KILL])
}

public MessageStatusIcon(msgID, dest, receiver) {
	// Check if status is to be shown
	if(gBlockBuyZone && get_msg_arg_int(1)) {
		
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
	// Hide buyzone icon from all players
	message_begin(MSG_BROADCAST, gMsgStatusIcon);
	write_byte(0);
	write_string("buyzone");
	message_end();
	
	// Get all alive players
	new players[32], pnum;
	get_players(players, pnum, "a");
	
	// Remove all alive players from buyzone
	while(pnum-- > 0)
	{
		RemoveFromBuyzone(players[pnum]);
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
