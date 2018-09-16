/* 		
*  		 					   |================|
*				        		   |/\/\/\/\/\/\/\/\|
*  		      					   < DeathRace v1.4 >
*                     					   |\/\/\/\/\/\/\/\/|
*		      		        		   |================|
*
*  				          [Credits]
*						 -GrimVh2: Helping with some code stuff
*						 -Pukata: Mapping, Idea's, Support.
*						 -Huibert: Mapping, Idea's, Support.
*						 -D4zo: Texture
*
* 					  [v1.0]
*   					         -Release
*					
*					  [v1.1]
*						 -Fixed Teamkill message (By: schmurgel1983)
*						 -Removed buy zones (By: GrimVh2)
*						 -Fixed UZI bug
*						 -Fixed Win Bug
*						 -Fixed He-Grenade bug
*
*					  [v1.2]
*						 -Fixed some HP & CASH bug. (In random crate)
*						 -Fixed a UZI bug
*						 -Limits (With cvars)
*
*					  [v1.3]
*						 -Fixed: Speed bug
*						 -Added: Cvars (Uzi Bullets, Freeze Speed, Gravity, Win Frags)
*						 -Added: ML	
*
*					  [v1.4]
*						 -Fixed: Freeze Bug (by Empowers)
*						 -Added: API (By Wrecked, thanks man!)
*/
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <nvault>

#define PLUGIN "DeathRace"
#define VERSION "1.4"
#define AUTHOR "Xalus"

#define MAX_PLAYERS 32

// Save Stats? (Or U wanne let it reset by change map set then: //#define SaveStats )
#define SaveStats

#if defined SaveStats
new g_drVault;
#endif
new dr_status, dr_speed, dr_glow, dr_stats, dr_lives, dr_gamename, dr_maxhp, dr_maxarmor, dr_godmode, dr_he, dr_speedlimit, dr_gravity, dr_uzi, dr_uzibullets, dr_winfrags, dr_freezespeed, dr_gravityjump;
new g_Crates[33], g_Wins[33], g_Respawns[33];
new g_Speed[33], g_Godmode[33], g_Gravity[33], g_Uzi[33];
new bool:b_HasSpeed[33], bool:ButtonUsed, b_SpeedStyle[33];
new g_iMsgSayText;
new iForward, g_hWinForward

#define WITH_PLACES

#if defined WITH_PLACES
	#define TASKID_PLACESHUD 17515
	#define TOP_NUM 3
	new g_iEndButton
#endif

public plugin_natives()
{
	register_library( "drace" );
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("deathrace_mod", VERSION, FCVAR_SERVER);
	
	// ML
	register_dictionary("DeathRace.txt");
	
	// Clcmd's
	register_clcmd("say /stats", "drstats");
	register_clcmd("say /drstats", "drstats");
	
	// Other stuff
	g_iMsgSayText = get_user_msgid("SayText") 
	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	register_event( "CurWeapon", "CurWeapon", "be", "1=1" );
	register_message(get_user_msgid("TextMsg"), "message_textmsg");
	register_message(get_user_msgid("StatusIcon"), "Msg_StatusIcon"); 
	
	// Cvar's
	dr_status	= register_cvar("deathrace_status"		, "1");
	dr_glow 	= register_cvar("deathrace_glow"		, "0");
	dr_stats 	= register_cvar("deathrace_stats"		, "0");
	dr_speed 	= register_cvar("deathrace_speed"		, "400");
	dr_freezespeed 	= register_cvar("deathrace_freezespeed"		, "50");
	dr_lives 	= register_cvar("deathrace_lives"		, "0");
	dr_gravityjump	= register_cvar("deathrace_gravity"		, "0.7");
	dr_gamename	= register_cvar("deathrace_gamename"		, "DeathRace [v1.4]");
		// Limits
	dr_maxhp	= register_cvar("deathrace_hplimit"		, "200");
	dr_maxarmor	= register_cvar("deathrace_armorlimit"		, "200");
	dr_speedlimit	= register_cvar("deathrace_speedlimit"		, "2");
	dr_godmode	= register_cvar("deathrace_godmodlimit"		, "2");
	dr_gravity	= register_cvar("deathrace_gravitylimit"	, "2");
	dr_uzi		= register_cvar("deathrace_uzilimit"		, "2");
	dr_he		= register_cvar("deathrace_hegrenadelimit"	, "2");
		// Counts
	dr_uzibullets	= register_cvar("deathrace_uzibullets"		, "3");
	dr_winfrags	= register_cvar("deathrace_frags"		, "5");
	
	// Ham Stuff
	RegisterHam(Ham_Touch, "func_breakable", "CrateTouch");
	RegisterHam(Ham_Use, "func_button", "ButtonUse");
	RegisterHam(Ham_Killed, "player", "FwdHamPlayerKilled");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "BlockKnife");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "BlockKnife");
	RegisterHam(Ham_Spawn, "player", "FwdHamPlayerSpawn", 1);
	
	#if defined SaveStats
	g_drVault = nvault_open("DeathRace");
	#endif
	
	// Game Name
	register_forward( FM_GetGameDescription, "GameDesc" );
	
	// Forward
	iForward = CreateMultiForward( "dr_crate_hit", ET_STOP, FP_CELL, FP_CELL, FP_STRING ) // :avast:
	g_hWinForward = CreateMultiForward("dr_win", ET_IGNORE, FP_CELL)
	
	#if defined WITH_PLACES
	set_task(1.0, "PlacesHud", TASKID_PLACESHUD, .flags = "b");
	
	g_iEndButton = find_ent_by_tname(get_maxplayers(), "winbut");
	#endif
	
	
}

#if defined WITH_PLACES
public PlacesHud(iTaskId)
{
	if(ButtonUsed)
	{
		return;
	}
	
	enum
	{
		DISTANCE,
		ID
	};
	
	new iPlayersData[33][2];
	static iPlayers[32], iNum, iPlayer, i, szName[32];
	get_players(iPlayers, iNum, "ae", "CT");
	
	for(i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		iPlayersData[ i ] [ID] = iPlayer;
		iPlayersData[ i ] [ DISTANCE ] = get_entity_distance(iPlayer, g_iEndButton);
	}
	
	SortCustom2D(iPlayersData, sizeof iPlayersData, "CompareFunc");
	
	static szHudMsg[350], iLen;
	
	iLen = formatex(szHudMsg, charsmax(szHudMsg), "Nearest Players To WIN TARGET:^n#. Name   (SPEED)^n");
	for(i = 0; i < TOP_NUM; i++)
	{
		iPlayer = iPlayersData[i][1];
		
		if(iPlayer > 0)
		{
			get_user_name(iPlayer, szName, charsmax(szName));
		
			iLen += formatex(szHudMsg[iLen], charsmax(szHudMsg) - iLen, "^n%i. %s   (%0.1f)", i + 1, szName, GetSpeedVector(iPlayer));
		}
	}
	
	set_hudmessage(255, 255, 0, 0.60, 0.15, 0, 0.0, 1.0, 0.1, 0.1, -1);
	show_hudmessage(0, szHudMsg);
}

stock Float:GetSpeedVector(id)
{
	static Float:vVelocity[3];
	pev(id, pev_velocity, vVelocity);
	
	return vector_length(vVelocity);
}

public CompareFunc(iElement1[], iElement2[])
{
	if(iElement1[0] < iElement2[0])
	{
		return 1;
	}
	
	if(iElement1[0] > iElement2[0])
	{
		return -1;
	}
	
	return 0;
}
#endif

public plugin_end(){
	#if defined SaveStats
	nvault_close(g_drVault);
	#endif
}
public CurWeapon(id)
	if(get_pcvar_num(dr_status))
		if(b_HasSpeed[id])
			if(b_SpeedStyle[id] == 1)
				set_user_maxspeed(id, get_pcvar_float(dr_speed))
			else if(b_SpeedStyle[id] == 0)
				set_user_maxspeed(id, get_pcvar_float(dr_freezespeed))

// Block Knife
public BlockKnife(){
	if(get_pcvar_num(dr_status))
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED;
}

// DeathRace Stats
public drstats(id)
{
	if(get_pcvar_num(dr_stats))
	{
		new Tempstats[150];
		formatex(Tempstats, 149, "%L", id, "STATS", g_Wins[id], g_Respawns[id], g_Crates[id]); 
		ChatColor( id, Tempstats );
	}

	return PLUGIN_HANDLED;
}
// Block some text messages
public message_textmsg()
{
	static textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	    
	// Block Teammate attack and kill Message
	if (equal(textmsg, "#Game_teammate_attack") || equal(textmsg, "#Killed_Teammate"))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}
// Block Buy command
public Msg_StatusIcon(msgid, msgdest, id) 
{
	if(!get_pcvar_num(dr_status))
		return PLUGIN_CONTINUE;
    
	static szMsg[8];
	get_msg_arg_string(2, szMsg, 7);
    
	if(equal(szMsg, "buyzone") && get_msg_arg_int(1)) 
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1 << 0));
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
// New round starts
public new_round()
	ButtonUsed = false

// Button Use
public ButtonUse(ent, id)
{
	if(is_user_connected(id) && get_pcvar_num(dr_status))
	{		
		new target[32]
		pev(ent, pev_targetname, target, 31)
		
		if(equal(target, "winbut")) { // End-Button
			
			new iRet
			ExecuteForward(g_hWinForward, iRet, id)
			
			new szName[32]
			get_user_name(id, szName, 31)
			ChatColor(0, "^3[DeathRace] ^4The winner is ^3%s", szName)
			
			set_hudmessage(255, 255, 255, -1.0, 0.37, 1, 6.0, 5.0, 1.0, 0.0, -1)
			show_hudmessage(0, "%L", LANG_PLAYER, "WON", szName)
			
			cs_set_user_deaths(id, get_user_deaths(id) - 1);
			ButtonUsed = true
			
			if(get_pcvar_num(dr_lives))
				g_Respawns[id]++;
			if(get_pcvar_num(dr_stats))
				g_Wins[id]++;
				
			new Players[32] 
			new playerCount, i, playerdr
			get_players(Players, playerCount, "a") 
			
			new frags = get_pcvar_num(dr_winfrags)
			set_user_frags(id, get_user_frags(id) + frags)
			
			for (i=0; i<playerCount; i++) 
			{
				playerdr = Players[i]
				user_silentkill(playerdr)
			}
		}
	}
	return PLUGIN_HANDLED
}
// Crate Touch
public CrateTouch(ent, id)
{		
	if(get_pcvar_num(dr_status) && is_user_connected(id)) 
	{	
		new target[32]
		pev(ent, pev_targetname, target, 31)
		
		// -- Wrecked is HOT --
		new iReturn
		ExecuteForward( iForward, iReturn, id, ent, target )
		
		if( iReturn == 1 )
		{
			ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC )
			
			if(get_pcvar_num(dr_stats) != 0)
				g_Crates[id]++;
				
			return PLUGIN_HANDLED;
		}
		// --

		else if(equal(target, "speedcrate")) { // Speed-Crate
			if(g_Speed[id] == get_pcvar_num(dr_speedlimit))
			{
				ChatColor(id, "%L", LANG_PLAYER, "TURBOLIMIT", get_pcvar_num(dr_speedlimit))
				// Break it, for stop bug!
				ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC );
				return PLUGIN_HANDLED
			}
			ChatColor(id, "%L", LANG_PLAYER, "TURBO")
			
			g_Speed[id]++;
			b_HasSpeed[id] = false 
			b_SpeedStyle[id] = 1
			set_user_maxspeed(id, get_pcvar_float(dr_speed))
			
			if(get_pcvar_num(dr_glow))
				set_user_rendering(id, kRenderFxGlowShell, 128, 128, 0, kRenderNormal, 20);
				
			set_task(2.0, "SpeedStop", id);			
		}
		else if(equal(target, "hecrate")) { // He-Crate
			ChatColor(id, "%L", LANG_PLAYER, "GRENADE")
	
			if(user_has_weapon(id, CSW_HEGRENADE))
			{
				cs_set_user_bpammo( id, CSW_HEGRENADE, min( ( cs_get_user_bpammo( id, CSW_HEGRENADE ) + 1 ), get_pcvar_num(dr_he) ) );
				// Break it, for stop bug!
				ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC );
				return PLUGIN_HANDLED;
			}
			
			give_item(id, "weapon_hegrenade");
			cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
			
			if(get_pcvar_num(dr_glow) > 0) 
				set_user_rendering(id, kRenderFxGlowShell, 0, 250, 0, kRenderNormal, 20);
		}	
		else if(equal(target, "uzicrate")) { // Uzi crate			
			if(user_has_weapon(id, CSW_TMP))
			{
				ChatColor(id, "%L", LANG_PLAYER, "GOTUZI")
				// Break it, for stop bug!
				ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC );
				return PLUGIN_HANDLED
			}
			
			if(g_Uzi[id] == get_pcvar_num(dr_uzi))
			{
				ChatColor(id, "%L", LANG_PLAYER, "UZILIMIT", get_pcvar_num(dr_uzi))
				// Break it, for stop bug!
				ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC );
				return PLUGIN_HANDLED
			}
			ChatColor(id, "%L", LANG_PLAYER, "UZI", get_pcvar_num(dr_uzibullets))
			g_Uzi[id]++;
				
			new tmpboy = give_item(id, "weapon_tmp");
			cs_set_weapon_ammo(tmpboy, get_pcvar_num(dr_uzibullets))
			
			give_item(id, "weapon_tmp")
			
			cs_set_user_bpammo(id, CSW_TMP, 0)
			
			if(get_pcvar_num(dr_glow))
				set_user_rendering(id, kRenderFxGlowShell, 0, 250, 0, kRenderNormal, 20);
		}	
		else if(equal(target, "sheildcrate") || equal(target, "shieldcrate"))  { // Shield Crate
			ChatColor(id, "%L", LANG_PLAYER, "SHIELD")
			give_item(id, "weapon_shield");
			
			if(get_pcvar_num(dr_glow) > 0)
				set_user_rendering(id, kRenderFxGlowShell, 128, 128, 0, kRenderNormal, 20);
		}
		else if(equal(target, "godmodecrate"))  { // Godmode Crate
			if(g_Godmode[id] == get_pcvar_num(dr_godmode))
			{
				ChatColor(id, "%L", LANG_PLAYER, "GODMODELIMIT", get_pcvar_num(dr_godmode))
				// Break it, for stop bug!
				ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC );
				return PLUGIN_HANDLED
			}
			
			ChatColor(id, "%L", LANG_PLAYER, "GODMODE")
			g_Godmode[id]++;
			set_user_godmode(id, 1)
		
			if(get_pcvar_num(dr_glow) > 0)
				set_user_rendering(id, kRenderFxGlowShell, 128, 128, 0, kRenderNormal, 20);
			
			set_task(10.0, "GodmodeStop", id);
		}
		else if(equal(target, "gravitycrate")) { // Gravity-Crate
			if(g_Gravity[id] == get_pcvar_num(dr_gravity))
			{
				ChatColor(id, "%L", LANG_PLAYER, "GRAVITYLIMIT", get_pcvar_num(dr_gravity))
				// Break it, for stop bug!
				ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC );
				return PLUGIN_HANDLED
			}
			ChatColor(id, "%L", LANG_PLAYER, "GRAVITY")
			g_Gravity[id]++;
			set_user_gravity(id, get_pcvar_float(dr_gravityjump))
			
			if(get_pcvar_num(dr_glow) > 0)
				set_user_rendering(id, kRenderFxGlowShell, 128, 128, 0, kRenderNormal, 20);
			
			set_task(10.0, "GravityStop", id);
		}	
		else if(equal(target, "hpcrate"))  { // Health Crate
			ChatColor(id, "%L", LANG_PLAYER, "HEALTH")
			set_user_health( id, min( ( get_user_health( id ) + 50 ), get_pcvar_num(dr_maxhp) ) );

			if(get_pcvar_num(dr_glow) > 0)
				set_user_rendering(id, kRenderFxGlowShell, 0, 128, 0, kRenderNormal, 20);
		}			
		else if(equal(target, "armorcrate"))  { // Armor Crate
			ChatColor(id, "%L", LANG_PLAYER, "ARMOR")
			set_user_armor( id, min( ( get_user_armor( id ) + 50 ), get_pcvar_num(dr_maxarmor) ) );

			if(get_pcvar_num(dr_glow) > 0)
				set_user_rendering(id, kRenderFxGlowShell, 128, 0, 0, kRenderNormal, 20);
		}		
		else if(equal(target, "frostcrate")) { // Frost-Crate
			ChatColor(id, "%L", LANG_PLAYER, "FLASH")
			// WARNING: It gives a FLASH Bang!
			give_item(id, "weapon_flashbang");
			cs_set_user_bpammo(id,CSW_FLASHBANG,1)
	
			if(get_pcvar_num(dr_glow) > 0) 
				set_user_rendering(id, kRenderFxGlowShell, 0, 250, 0, kRenderNormal, 20);
		}
		else if(equal(target, "smokecrate")) { // Smoke-Crate
			ChatColor(id, "%L", LANG_PLAYER, "SMOKE")
			// WARNING: It gives a FLASH Bang!
			give_item(id, "weapon_smokegrenade");
			cs_set_user_bpammo(id,CSW_SMOKEGRENADE,1)
	
			if(get_pcvar_num(dr_glow) > 0) 
				set_user_rendering(id, kRenderFxGlowShell, 0, 250, 0, kRenderNormal, 20);
		}
		else if(equal(target, "deathcrate")) { // Death-Crate
			if (!get_user_godmode(id))
			{
				ChatColor(id, "%L", LANG_PLAYER, "DEATH")
				user_kill(id, 0)
				if(get_pcvar_num(dr_glow) > 0) 
					set_user_rendering(id, kRenderFxGlowShell, 0, 250, 0, kRenderNormal, 20);
			}
		}
		else if(equal(target, "drugcrate")) { // Random-Crate
			ChatColor(id, "%L", LANG_PLAYER, "DRUGS")
			
			message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
			write_byte(170)
			message_end()
			
			set_task(10.0, "DrugStop", id);
		}
		else if(equal(target, "shakecrate")) { // Random-Crate
			ChatColor(id, "%L", LANG_PLAYER, "SHAKE")
			
			new g_msgScreenShake=get_user_msgid("ScreenShake");
			message_begin(MSG_ONE,g_msgScreenShake, {0,0,0},id);
			write_short(255<<14);
			write_short(10<<14);
			write_short(255<<14);
			message_end();
		}
		else if(equal(target, "freezecrate")) { // Random-Crate
			ChatColor(id, "%L", LANG_PLAYER, "FREEZE")
			
			set_user_maxspeed(id, get_pcvar_float(dr_freezespeed))
			b_HasSpeed[id] = true
			b_SpeedStyle[id] = 0
			set_task(2.0, "SpeedStop", id);
		}
		else if(equal(target, "randomcrate")) { // Random-Crate
			new rnum = random_num( 1, 6 )
 
			switch( rnum )
			{
				case 1:
				{
					ChatColor(id, "%L", LANG_PLAYER, "HEALTH")
					set_user_health( id, min( ( get_user_health( id ) + 50 ), get_pcvar_num(dr_maxhp) ) );
				}
				case 2:
				{
					ChatColor(id, "%L", LANG_PLAYER, "CASH")
					new money =  cs_get_user_money(id)
					cs_set_user_money(id, money + 3000);
					cs_set_user_money( id, min( ( cs_get_user_money( id ) + 3000 ), 16000 ) );
				}
				case 3:
				{
					ChatColor(id, "%L", LANG_PLAYER, "SHAKE")
					
					new g_msgScreenShake=get_user_msgid("ScreenShake");
					message_begin(MSG_ONE,g_msgScreenShake, {0,0,0},id);
					write_short(255<<14);
					write_short(10<<14);
					write_short(255<<14);
					message_end();
				}	
				case 4:
				{
					ChatColor(id, "%L", LANG_PLAYER, "DRUGS")
			
					message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
					write_byte(170)
					message_end()
					
					set_task(10.0, "DrugStop", id);
				}
				default:
					ChatColor(id, "%L", LANG_PLAYER, "NOTHING")
			}
			if(get_pcvar_num(dr_glow) > 0) 
				set_user_rendering(id, kRenderFxGlowShell, 0, 250, 0, kRenderNormal, 20);
		}
		else
			ChatColor(id, "%L", LANG_PLAYER, "UNKNOWN")
		
		ExecuteHamB( Ham_TakeDamage, ent, 0, 0, 9999.0, DMG_GENERIC );
		
		if(get_pcvar_num(dr_stats) != 0)
			g_Crates[id]++;
		
		#if defined SaveStats
		DeathRace_Save(id);
		#endif	
	}
	return PLUGIN_CONTINUE
}
// Stop the stuff
public DrugStop(id){
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(90)
	message_end()
}
public SpeedStop(id){
	set_user_maxspeed(id, 320.0) 
	b_HasSpeed[id] = false
}
public GodmodeStop(id)
	set_user_godmode(id, 0)
	
public GravityStop(id)
	set_user_gravity(id, 1.0)

// Ham stuff
public FwdHamPlayerKilled(id)
{
	if(get_pcvar_num(dr_status))
	{
		if(ButtonUsed)
			return PLUGIN_HANDLED
		
		new playerCount, g_iMaxPlayers, tempid, Players[32];
		get_players(Players, g_iMaxPlayers, "a") 
		
		for(new i;i<g_iMaxPlayers;i++)
		{
			if (!is_user_alive(Players[i]))
				return PLUGIN_CONTINUE
			
			switch (cs_get_user_team(Players[i]))
			{
				case CS_TEAM_CT:
				{
					playerCount++;
					tempid = Players[i]
				}
			}
		}
		if(playerCount == 1)
		{
			new szName[32]
			get_user_name(tempid, szName, 31)
			ChatColor(id, "%L", LANG_PLAYER, "WON", szName)
			
			cs_set_user_deaths(tempid, get_user_deaths(tempid) - 1)
			new frags = get_pcvar_num(dr_winfrags)
			set_user_frags(tempid, get_user_frags(tempid) + frags)
			
			user_silentkill(tempid)
		}
		if(get_pcvar_num(dr_lives) && g_Respawns[id])
		{
			new Title[64]
			formatex(Title, 63, "%L", id, "GOTLIVE"); 
			
			new RespawnMenu = menu_create(Title, "RespawnMenuHandler")
			formatex(Title, 63, "%L", id, "YES"); 
			menu_additem(RespawnMenu, Title, "1", 0)
			formatex(Title, 63, "%L", id, "NO");
			menu_additem(RespawnMenu, Title, "2", 0)
			
			menu_display(id, RespawnMenu)
		}
	}
	return PLUGIN_HANDLED
}	
public RespawnMenuHandler(id, menu, key) {
	if( key < 0 )
		return PLUGIN_CONTINUE

	if( key == MENU_EXIT ) {
		return PLUGIN_HANDLED
	}

	switch(key) {
		case 0:
		{
			ExecuteHamB( Ham_CS_RoundRespawn, id );
			g_Respawns[ id ]--;
			
			#if defined SaveStats
			DeathRace_Save(id);
			#endif
		}
		case 1:
		{
			// nothing
		}
	}

	return PLUGIN_HANDLED
}	
public FwdHamPlayerSpawn(id)
{
	if(is_user_alive(id) && get_pcvar_num(dr_status))
	{
		//remove glow
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
		// remove player's weapons
		strip_user_weapons(id)
		// Give knife
		give_item(id, "weapon_knife")
		// set users back normal
		set_user_godmode(id, 0)
		set_user_gravity(id, 1.0)
		
		//if maxspeed is 1.0 then we are frozen 
		if(get_user_maxspeed(id)<=1.0) 
		{     
			new Float:freeze = get_cvar_float("mp_freezetime") 
			set_task(freeze,"SpeedStop",id)     
		} 
		       // respawned not in round start 
		else 
			set_user_maxspeed(id, 320.0) 
		
		// Set crate stuff back 0
		g_Speed[id] = 0
		g_Godmode[id] = 0
		g_Gravity[id] = 0
		g_Uzi[id] = 0
	}
}
// Save & Load
public DeathRace_Load(id){
	new szAuthId[64], data[129];
	get_user_authid(id, szAuthId, 63);
	
	#if defined SaveStats
	new key[72], stats[34], stat[3][12];
	formatex(key, 71, "%s-stats", szAuthId);
	
	nvault_get(g_drVault, key, stats, 33);
	
	parse(stats, stat[0], 11, stat[1], 11, stat[2], 11);
	
	g_Wins[id] = str_to_num(stat[0]);
	g_Respawns[id] = str_to_num(stat[1]);
	g_Crates[id] = str_to_num(stat[2]);
	
	nvault_get(g_drVault, szAuthId, data, 128);
	#endif
}
public client_connect(id)
{
	#if defined SaveStats
	DeathRace_Load(id);
	#endif
}

public client_disconnect(id)
{
	if(get_pcvar_num(dr_status))
	{
		#if defined SaveStats
		DeathRace_Save(id);
		#endif
		new playerCount, g_iMaxPlayers, tempid, Players[32];
		get_players(Players, g_iMaxPlayers, "a") 
		
		for(new i;i<g_iMaxPlayers;i++)
		{
			if (!is_user_alive(Players[i]))
				return PLUGIN_CONTINUE
			
			switch (cs_get_user_team(Players[i]))
			{
				case CS_TEAM_CT:
				{
					playerCount++;
					tempid = Players[i]
				}
			}
		}
		if(playerCount == 1)
		{
			new szName[32]
			get_user_name(tempid, szName, 31)
			ChatColor(id, "%L", LANG_PLAYER, "WON", szName)
			
			cs_set_user_deaths(tempid, get_user_deaths(tempid) - 1)
			new frags = get_pcvar_num(dr_winfrags)
			set_user_frags(tempid, get_user_frags(tempid) + frags)
			
			user_silentkill(tempid)
		}
	}
	return PLUGIN_HANDLED;
}
public DeathRace_Save(id){
	new szAuthId[64], data[129];
	get_user_authid(id, szAuthId, 63);
	
	#if defined SaveStats
	new key[72], stats[34];
	formatex(key, 71, "%s-stats", szAuthId);
	formatex(stats, 33, "%i %i %i", g_Wins[id], g_Respawns[id], g_Crates[id]);
	nvault_set(g_drVault, key, stats);
	nvault_set(g_drVault, szAuthId, data);
	#endif
}
// ColorChat - Start
stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!team", "^3") // Team Color

	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
			message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayText, _, players[i])  
			write_byte(players[i]);
			write_string(msg);
			message_end();
			}
		}
	}
} 
// Game Name
public GameDesc( ) { 
	static gamename[32]; 
	get_pcvar_string( dr_gamename, gamename, 31 ); 
	forward_return( FMV_STRING, gamename ); 
	return FMRES_SUPERCEDE; 
} 
