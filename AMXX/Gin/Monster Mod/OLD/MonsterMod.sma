/* SCXPM Version 17.0 by Silencer
** Edited by Wrd, Version 17.31
** 	Wrd thanks supergreg for his suggestions
** 
** Special Thanks to:
** 
** VEN			For heavily improving my Scripting-Skills.  ;p 
** darkghost9999	For his great Ideas!
** 
** 
** Thanks to:
** 
** ThomasNguyen
** `666
** g3x
** 
*/

// comment the #define USING_CS if you don't use cs
#define USING_CS

#include <amxmodx>
#include <amxmisc>
#include <core>
#include <fakemeta>
#include <fun>
#include <sqlx>
#include <hamsandwich>
#include <geoip>

#if defined USING_CS
#include <cstrike>
#endif

#define VERSION "17.31"
#define LASTUPDATE "21 March 2010"

/*
* The table create code is too long to compile so table have to be created manually

CREATE TABLE IF NOT EXISTS `scxpm_stats` (
  `id` int(11) NOT NULL auto_increment,
  `uniqueid` varchar(50) NOT NULL,
  `authid` varchar(24) NOT NULL,
  `ip` varchar(24) NOT NULL,
  `nick` varchar(50) NOT NULL,
  `xp` bigint(20) NOT NULL default '0',
  `playerlevel` int(11) NOT NULL default '0',
  `skillpoints` int(11) NOT NULL default '0',
  `medals` tinyint(4) NOT NULL default '4',
  `health` int(11) NOT NULL default '0',
  `armor` int(11) NOT NULL default '0',
  `rhealth` int(11) NOT NULL default '0',
  `rarmor` int(11) NOT NULL default '0',
  `rammo` int(11) NOT NULL default '0',
  `gravity` int(11) NOT NULL default '0',
  `speed` int(11) NOT NULL default '0',
  `dist` int(11) NOT NULL default '0',
  `dodge` int(11) NOT NULL default '0',
  `lastUpdated` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `uniqueid` (`uniqueid`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

*/



/*
*	Future Features
*	if you want new features ask it on: http://forums.alliedmods.net/showthread.php?t=44168
*	------------------
*	- pruning database with the `lastUpdated` field
*	- cuicide penalty
*
*/

/*
*	Changelog
*
*	Version: 	17.31
*	Date: 		21 March 2010
*	------------------------
*	- Fixed movement bug
*	- Fixed not receiving xp for kill
*	------------------------
*
*	Version: 	17.30
*	Date: 		08 Februari 2010
*	------------------------
*	- Added Incremental skill upgrade
*	------------------------
*
*	Version: 	17.29
*	Date: 		07 Februari 2010
*	------------------------
*	- Fixed: set loaddata to true when loading from file
*	------------------------
*
*	Version: 	17.28
*	Date: 		02 Februari 2010
*	------------------------
*	- Fixed: don't set the xp back to 0
*	------------------------
*
*	Version: 	17.27
*	Date: 		20 December 2009
*	------------------------
*	- Added: scxpm_maxlevel cvar for capping the max level
*	- Fixed: xp problem when #define USING_CS is commented
*	------------------------
*
*	Version: 	17.26
*	Date: 		15 November 2009
*	------------------------
*	- Fixed: The inefficient way of calculating the xp does not work for sven coop 
*	------------------------
*
*	Version: 	17.25
*	Date: 		9 November 2009
*	------------------------
*	- Changed: amx_scxpm_gamename to scxpm_gamename
*	- Changed: amx_scxpm_save to scxpm_save
*	- Changed: amx_scxpm_savestyle to scxpm_savestyle
*	- Changed: amx_scxpm_debug to scxpm_debug
*	- Changed: scxpm_xpgain to scxpm_xpgain
*	------------------------
*
*	Version: 	17.24
*	Date: 		8 November 2009
*	------------------------
*	- Removed: Inefficient way of calculating the xp
*	- Added: Event triggered way of calculating the xp
*	------------------------
*
*	Version: 	17.23
*	Date: 		7 November 2009
*	------------------------
*	- Added: lastupdate field in the database for later use
*	- Added: cvar scxpm_minplaytime: setting in seconds the minimum playing time before stats are saved
*	- Fixed: empty uniqueid added to database
*	- Fixed: empty ip or nickname added to the database
*	------------------------
*
*	Version: 	17.22
*	Date: 		2 November 2009
*	------------------------
*	- Changed database structure and queries for better query handling
*	- Added an check so that data is not loaded twice because of retreiving the steamid
*	------------------------
*
*	Update Note from version 17.21 to 17.22
*	execute the following query:	
*	- ALTER TABLE `scxpm_stats` ADD `uniqueid` VARCHAR( 50 ) NOT NULL AFTER `id` ;
*	- UPDATE scxpm_stats SET uniqueid = <unique>;
*		replace <unique> with the following possibilities according to your situation
*			- authid
*			- ip
*			- nick
*	-  ALTER TABLE `scxpm_stats` ADD UNIQUE (`uniqueid`) 
*
*	Version: 	17.21
*	Date: 		28 Oktober 2009
*	------------------------
*	- Fixed: xp lower than 0 won't be saved
*	------------------------
*
*	Version: 	17.20
*	Date: 		11 Oktober 2009
*	------------------------
*	- Fixed: Possible entries inserted in the database with no auth id when the savestyle is on authid
*   - Fixed: Players could only gain one level and the rest would not be saved
*	- Fixed: directly go to the correct level when alot of xp is given, instead of going through every level
*   - Added: More debug feedback
*	------------------------
*
*	Version: 	17.19
*	Date: 		 8 Oktober 2009
*	------------------------
*	- Fixed: Added the loaddata check on save, no stats will be saved if no data is loaded
*	------------------------
*
*	Version: 	17.18
*	Date: 		15 September 2009
*	------------------------
*	- Fixed: Threaed SQL (There were incredible horrible bugs)
*	------------------------
*
*	Version: 	17.17
*	Date: 		13 September 2009
*	------------------------
*	- Added: Threaded sql
*	------------------------
*
*	Version: 	17.16
*	Date: 		31 August 2009
*	------------------------
*	- Fixed: Showing the players info and other players info 
*	------------------------
*
*	Version: 	17.15
*	Date: 		28 August 2009
*	------------------------
*	- Added create sql script info
*	- Fixed the savexp_all sql part
*	- Fixed health issue
*	------------------------
*
*
*	Version: 	17.14
*	Date: 		2 August 2009
*	------------------------
*	- Added changes made by supergreg
*	 = Changed the database cvars
*      Now another database can be used instead of the default one
*	 = Fixed: cs weapons offset
*	 = Generally small but useful changes
*	 = Added a define for cs, if you don't use this pluging for cs please comment the define
*   ------------------------
*
*	Version: 	17.13
*	Date: 		30 Juli 2009
*	------------------------
*	- Fixed repeated saving stats; scxpm_save_frequent fixed
*   ------------------------
*
*	Version: 	17.12
*	Date: 		30 Juli 2009
*	-------------------------
*	- Try to fix the health bug when spawning
*	- Added this changelog	
*	-------------------------
*/


/*
** Queries 
*/
#define QUERY_SELECT_SKILLS "SELECT `xp`, `playerlevel`, `skillpoints`, `medals`, `health`, `armor`, `rhealth`, `rarmor`, `rammo`, `gravity`, `speed`, `dist`, `dodge` FROM `%s` WHERE %s"
#define QUERY_UPDATE_SKILLS "INSERT INTO %s (uniqueid) VALUES ('%s') ON DUPLICATE KEY UPDATE authid ='%s',nick='%s',ip='%s',xp='%d',playerlevel='%d',skillpoints='%d',medals='%d',health='%d',armor='%d',rhealth='%d',rarmor='%d',rammo='%d',gravity='%d',speed='%d',dist='%d',dodge='%d'"
										
// added for mysl support
new Handle:dbc;
new g_Cache[1024];
new sql_table[64];
new bool:loaddata[33];		// check so data is only saved when data is loaded
new bool:plugin_ended;

#if defined USING_CS
	// cs specific
	new ammotype[7][15];		// types of ammo you can receive through random ammo (from regeneration)
#endif

new load_error[33];
new xp[33];
new neededxp[33];
new playerlevel[33];
new rank[33][32];
new skillpoints[33];
new medals[35];
new health[33];
new armor[33];
new rhealth[33];
new rarmor[33];
new rammo[33];
new gravity[33];
new speed[33];
new dist[33];
new dodge[33];
new rarmorwait[33];
new rhealthwait[33];
new ammowait[33];
new starthealth;
new startarmor;
new lastfrags[33];
new lastDeadflag[33];
new skillIncrement[33];
#if !defined USING_CS
	new bool:onecount;
#endif
new bool:has_godmode[33];

#if defined USING_CS
new g_iMaxPlayers
new g_pMoney
#endif

new g_szSteamId[33][35]
new Float:g_flNextSee[33]
new g_szCountry[33][50]

new g_iMonsterFrags[33];
new const Float:g_flShowTime = 1.0

public plugin_init()
{
	log_amx( "[Monster Mod] Loading Monster Mod version %s", VERSION );
	register_plugin("MM",VERSION,"GinANDKhalid");
	register_menucmd(register_menuid("Select Skill"),(1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9),"SCXPMSkillChoice");
	register_menucmd(register_menuid("Select Increment"),(1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5),"SCXPMIncrementChoice");
	register_forward(FM_GetGameDescription,"scxpm_gn");
	register_forward(FM_PlayerPreThink,"scxpm_prethink");
	register_concmd("setlvl","scxpm_setlvl",ADMIN_IMMUNITY,"Playername Value - Will set Players Level");
	register_concmd("addmedal","scxpm_addmedal",ADMIN_IMMUNITY,"Playername - Will award Player with a Medal");
	register_concmd("removemedal","scxpm_removemedal",ADMIN_IMMUNITY,"Playername - Will remove a Medal of a Player");
	register_concmd("addxp","scxpm_addxp",ADMIN_IMMUNITY,"Playername Value - Will add xp to Players xp");
	register_concmd("removexp","scxpm_removexp",ADMIN_IMMUNITY,"Playername Value - Will remove xp from Players xp");
	
	// for debug reasons
	// register_concmd("say savedata","scxpm_savexp_all_mysql",ADMIN_IMMUNITY,"- Will save your SCXPM data");
	
	register_concmd("godmode","scxpm_godmode",ADMIN_IMMUNITY,"Playername - Toggle Players God Mode On or Off.");
	register_concmd("noclipmode","scxpm_noclipmode",ADMIN_IMMUNITY,"Playername - Toggle Players noclip Mode On or Off.");
	
	// it's removed so why register it
	//register_concmd("say saveall","scxpm_removed",-1,"- REMOVED")
	
	register_concmd("say selectskills","SCXPMSkill",-1,"- Opens the Skill Choice Menu, if you have Skillpoints available");
	register_concmd("say resetskills","scxpm_reset",-1,"- Will reset your Skills so you can rechoose them");
	register_concmd("say playerskills","scxpm_others",-1,"- Will print Other Players Stats");
	register_concmd("say skillsinfo","scxpm_info",-1,"- Will print Information about all Skills");
	
	
	// it's removed so why register it
	//register_concmd("say /saveall","scxpm_removed",-1,"- REMOVED")
	
	register_concmd("say /selectskills","SCXPMSkill",-1,"- Opens the Skill Choice Menu, if you have Skillpoints available");
	register_concmd("say /resetskills","scxpm_reset",-1,"- Will reset your Skills so you can rechoose them");
	register_concmd("say /playerskills","scxpm_others",-1,"- Will print Other Players Stats");
	register_concmd("say /skillsinfo","scxpm_info",-1,"- Will print Information about all Skills");
	
	
	// it's removed so why register it
	//register_concmd("saveall","scxpm_removed",-1,"- REMOVED")
	
	register_concmd("selectskills","SCXPMSkill",0,"- Opens the Skill Choice Menu, if you have Skillpoints available");
	register_concmd("resetskills","scxpm_reset",0,"- Will reset your Skills so you can rechoose them");
	register_concmd("playerskills","scxpm_others",0,"- Will print Other Players Stats");
	register_concmd("skillsinfo","scxpm_info",0,"- Will print Information about all Skills");
	
	
	// there is no need to change the name
	//register_cvar("scxpm_gamename","1")
	register_cvar("scxpm_gamename","0");
	
	// set a load protecting flag
	for( new i = 0; i<33 ;i++ )
	{
		loaddata[i] = false;
	}
	plugin_ended = false;
	
	/* 
	** set the save style
	** 0 = not saved
	** 1 = save in a file
	** 2 = save in mysql  
	*/
	register_cvar("scxpm_save","0");
	
	
	// for debug information in the logfile set this to 1
	register_cvar("scxpm_debug","0");
	
	/*
	** what to save on
	** 0 = id
	** 1 = ip address
	** 2 = nickname
	*/
	//register_cvar("scxpm_savestyle", "0")
	
	// if sv_lan irr ls on save stuff on the nickname
	if (get_cvar_num("sv_lan") == 1)
	{
		register_cvar("scxpm_savestyle", "2");
	}
	else
	{
		register_cvar("scxpm_savestyle", "0");
	}
	
	// minimum play time before saving data in seconds, 0 = always save
	register_cvar("scxpm_minplaytime", "0");
	
	/*
	** mysql
	*/
	register_cvar("scxpm_sql_host", "127.0.0.1");
	register_cvar("scxpm_sql_user", "NOTSET");
	register_cvar("scxpm_sql_pass", "NOTSET");
	register_cvar("scxpm_sql_db", "NOTSET");
	register_cvar("scxpm_sql_table", "scxpm_stats");
	
	new configsDir[64];
	get_configsdir(configsDir, 63);
	server_cmd("exec %s/sql.cfg", configsDir);

#if defined USING_CS
	ammotype[0] = "ammo_9mm";	// glock18, elite, mp5navy, tmp
	ammotype[1] = "ammo_50ae";	// deagle
	ammotype[2] = "ammo_buckshot";	// m3, xm1014
	ammotype[3] = "ammo_57mm";	// p90, fiveseven
	ammotype[4] = "ammo_45acp";	// usp, mac10, ump45
	ammotype[5] = "ammo_556nato";	// famas, sg552, m4a1, aug, sg550
	ammotype[6] = "ammo_9mm";	// glock18, elite, mp5navy, tmp	
#endif
	
	// hud message fix if it conflicts with other plugins
	register_cvar("scxpm_hud_channel", "4");
	
	// to enable frequent savestyle
	// if set to 1 players data will be saved as soon it gains xp
	register_cvar("scxpm_save_frequent", "0");
	
	register_cvar( "scxpm_xpgain", "1.0" );
	
	// possibility to cap the max level
	register_cvar( "scxpm_maxlevel", "1800" );
	
	set_task( 0.5, "scxpm_sdac", 0, "", 0, "b" );
	register_logevent("roundstart", 2, "0=World triggered", "1=Round_Start");
	#if defined USING_CS sma
	register_event("DeathMsg","death","a");
	#endif
	set_task( 0.1, "sql_init" );
	register_message(get_user_msgid("Health"), "message_Health");
	
	#if defined USING_CS
	RegisterHam(Ham_Killed, "func_wall", "fw_MonsterKill", 1)
	//RegisterHam(Ham_Killed, "func_wall", "monster_killed", 1)
	
	#endif
	RegisterHam(Ham_Player_PostThink, "player", "fw_Think");
	
	g_pMoney = register_cvar("scxpm_monsterkill_money", "500")
	
	g_iMaxPlayers = get_maxplayers()
	
}

public fw_Think(id)
{
	static iEntId, iDump, iAdd, szHudMsg[250], iColors[3]
	get_user_aiming(id, iEntId, iDump, 500);
	iAdd = 0
	
	//server_print("Think");
	static Float:flGameTime
	if(g_flNextSee[id] > (flGameTime = get_gametime() ) )
	{
		return;
	}
	
	if( !(1 <= iEntId <= g_iMaxPlayers) )
	{
		if(pev(iEntId, pev_flags) & FL_MONSTER)
		{
			static Float:Health;
			pev(iEntId, pev_health, Health)
			formatex(szHudMsg, charsmax(szHudMsg), 
			"Name: %s\
			^nHealth: %0.1f",
			GetMonsterName(iEntId), Health);
			
			iColors = { 255, 0, 0 }
			iAdd = 1
		}
		
		else	
		{
			return;
		}
	}
	
	else
	{
		static szName[32]; get_user_name(iEntId, szName, 31);
		
		formatex(szHudMsg, charsmax(szHudMsg),
		"Name: %s \
		^nHealth: %d \
		^nArmor: %d \
		^nLevel: %d \
		^nRank: %s \
		^nMedals: %d \
		^nSteamID: %s \
		^n%s",
		szName,
		get_user_health(iEntId),
		get_user_armor(iEntId),
		playerlevel[id],
		rank[iEntId],
		medals[iEntId],
		g_szSteamId[iEntId],
		g_szCountry[iEntId]);
		
		iColors = { 0, 255, 255 }
		iAdd = 1
	}
	
	if(iAdd)
	{
		g_flNextSee[id] = flGameTime + g_flShowTime
		
		set_hudmessage(iColors[0], iColors[1], iColors[2], -1.0, 0.50, 0, 0.0, g_flShowTime, 0.1, 0.1, -1);
		show_hudmessage(id, szHudMsg);
	}
}

stock GetMonsterName(iEnt)
{
	static szModel[60]
	pev(iEnt, pev_model, szModel, charsmax(szModel))
	
	replace(szModel, charsmax(szModel), "models/", "")
	replace(szModel, charsmax(szModel), ".mdl", "")
	
	if(equal(szModel, "w_squeak"))		szModel = "Squeak"
	else if(equal(szModel, "big_mom"))	szModel = "Big Momma"
	else if(equal(szModel, "bullsquid"))	szModel = "Bull Squid"
	else if(equal(szModel, "headcrab"))	szModel = "Head Crab"
	else if(equal(szModel, "hornet"))	szModel = "Hornet"
	else if(equal(szModel, "hassassin"))	szModel = "Spy"
	else if(equal(szModel, "islave"))	szModel = "Islave"
	else if(equal(szModel, "leech"))	szModel = "Leech"
	else if(equal(szModel, "zombie"))	szModel = "Zombie"
	else if(equal(szModel, "zombie01"))	szModel = "Zombie"
	else if(equal(szModel, "zombie02"))	szModel = "Zombie"
	else if(equal(szModel, "zombie03"))	szModel = "Zombie"
	else if(equal(szModel, "garg"))		szModel = "Garg"
	else if(equal(szModel, "controller"))	szModel = "Controller"
	else if(equal(szModel, "barney"))	szModel = "Barney"
	else if(equal(szModel, "hgrunt"))	szModel = "Hgrunt"
		
	return szModel
}

public fw_MonsterKill(iEntId, iPlayer, iShouldGib)
{
	if(! ( 1 <= iPlayer <= g_iMaxPlayers ) )
	{
		return;
	}
	
	//client_print(0, print_chat, "Monster Kill!")
	
	new addxp = 1 // Default Value
	
	new szModel[50]
	pev(iEntId, pev_model, szModel, 49)
	
	replace(szModel, charsmax(szModel), "models/", "")
	replace(szModel, charsmax(szModel), ".mdl", "")
	
	if(equal(szModel, "w_squeak"))		addxp = 105
	else if(equal(szModel, "big_mom"))	addxp = 300
	else if(equal(szModel, "bullsquid"))	addxp = 150
	else if(equal(szModel, "headcrab"))	addxp = 50
	else if(equal(szModel, "hornet"))	addxp = 100
	else if(equal(szModel, "hassassin"))	addxp = 150
	else if(equal(szModel, "islave"))	addxp = 120
	else if(equal(szModel, "leech"))	addxp = 120
	else if(equal(szModel, "zombie"))	addxp = 110
	else if(equal(szModel, "zombie02"))	addxp = 110
	else if(equal(szModel, "zombie01"))	addxp = 110
	else if(equal(szModel, "zombie03"))	addxp = 110
	else if(equal(szModel, "garg"))		addxp = 500
	else if(equal(szModel, "controller"))	addxp = 70
	else if(equal(szModel, "barney"))	addxp = 100
	else if(equal(szModel, "hgrunt"))	addxp = 150

	if ( addxp + xp[iPlayer] > scxpm_calc_xp ( get_cvar_num( "scxpm_maxlevel" ) ) )
	{
		addxp = scxpm_calc_xp ( get_cvar_num( "scxpm_maxlevel" ) ) - xp[iPlayer];
	}
	
	// should be impossible but why not
	if ( addxp + xp[iPlayer] < 0 )
	{
		xp[iPlayer] = 0;
	}
	
	// now add the xp to the current xp
	xp[iPlayer] += addxp;
	
	scxpm_calcneedxp(iPlayer);
	if( neededxp[iPlayer] > 0 )
	{
		if( xp[iPlayer] >= neededxp[iPlayer] )
		{
			new playerlevelOld = playerlevel[iPlayer];
			playerlevel[iPlayer] = scxpm_calc_lvl( xp[iPlayer] );
			skillpoints[iPlayer] += playerlevel[iPlayer] - playerlevelOld;
			
			scxpm_calcneedxp(iPlayer );
			
			new name[32];
			get_user_name( iPlayer, name, 63 );
			
			if ( playerlevel[iPlayer] == 1800 )
			{
				client_print(0,print_chat,"[Monster Mod] Everyone say ^"Congratulations!!!^" to %s, who has reached Level 1800!",name)
				log_amx("[Monster Mod] Player %s reached level 1800!", name );
			}
			else
			{
				client_print(iPlayer,print_chat,"[Monster Mod] Congratulations, %s, you are now Level %i - Next Level: %i XP - Needed: %i XP",name,playerlevel[iPlayer],neededxp[iPlayer], neededxp[iPlayer], xp[iPlayer])
				log_amx("[Monster Mod] Player %s reached level %i!", name, playerlevel[iPlayer] );
			}
			
			scxpm_getrank( iPlayer );
			
			SCXPMSkill( iPlayer );
			// just in case save the data
			SavePlayerData(iPlayer);
		}
	}
	
	cs_set_user_money(iPlayer, cs_get_user_money(iPlayer) + get_pcvar_num(g_pMoney), 1)
	g_iMonsterFrags[iPlayer]++
	
	client_print(iPlayer, print_chat, "** You have gained %d XP for killing a monster.", addxp)
	client_print(iPlayer, print_chat, "** Type /selectskills to select your skills.", playerlevel)
} 

public plugin_end() {
	if (get_cvar_num( "scxpm_debug") == 1 )
	{
		log_amx( "[SCXPM DEBUG] plugin_end" );
	}
	
	if ( dbc ) {
		SQL_FreeHandle( dbc );
	}
	
	new iPlayers[32], iNum, iFrags, iId;
	get_players(iPlayers, iNum);
	for(new i; i < iNum; i++)
	{
		if(g_iMonsterFrags[iPlayers[i]] > iFrags)
		{
			iFrags = g_iMonsterFrags[iPlayers[i]];
			iId = iPlayers[i];
		}
	}
	
	playerlevel[iId] += iFrags
	
	plugin_ended = true;
	
	return PLUGIN_HANDLED;
}

// init the sql, check if the sql table exist
public sql_init() {
	if ( get_cvar_num( "scxpm_save" ) >= 2 && !dbc)
	{
		if (get_cvar_num( "scxpm_debug") == 1 )
		{
			log_amx( "[SCXPM DEBUG] Begin Init the sql" );
		}
		
		new host[64], username[64], password[64], dbname[64];
		
		//no pcvar, only called once at plugin start
		get_cvar_string( "scxpm_sql_host", host, 64 );
		get_cvar_string( "scxpm_sql_user", username, 64 );
		get_cvar_string( "scxpm_sql_pass", password, 64 );
		get_cvar_string( "scxpm_sql_db", dbname, 64 );
		
		get_cvar_string( "scxpm_sql_table", sql_table, 64 );
		
		SQL_SetAffinity( "mysql" );
		dbc = SQL_MakeDbTuple( host, username, password, dbname );
		
		// check if the table exist
		formatex( g_Cache, 1023, "show tables like '%s'", sql_table );
		SQL_ThreadQuery( dbc, "ShowTableHandle", g_Cache);	
		
		if (get_cvar_num( "scxpm_debug") == 1 )
		{
			log_amx( "[SCXPM DEBUG] End Init the sql" );
		}
	}
}

public message_Health(msgid, dest, id) {
	if(!is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}
	
	static hp;
	hp = get_msg_arg_int(1);
	
	if(hp > 255 && (hp % 256) == 0) {
		set_msg_arg_int(1, ARG_BYTE, ++hp);
	}
	
	return PLUGIN_CONTINUE;
}

// give xp to player
public scxpm_addxp( id, level, cid ) {
	if ( !cmd_access( id, ADMIN_IMMUNITY, cid, 3 ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new targetarg[32];
	read_argv(1, targetarg, 31);
	new target = cmd_target( id, targetarg, 11 );
	if ( !target )
	{
		return PLUGIN_HANDLED;
	}
	new xparg[32];
	read_argv( 2, xparg, 31 );
	new addxp = str_to_num( xparg );
	new name[32];
	get_user_name( target, name, 31 );
	
	
	
	if ( addxp + xp[target] > scxpm_calc_xp ( get_cvar_num( "scxpm_maxlevel" ) ) )
	{
		addxp = scxpm_calc_xp ( get_cvar_num( "scxpm_maxlevel" ) ) - xp[target];
	}
	
	// should be impossible but why not
	if ( addxp + xp[target] < 0 )
	{
		xp[target] = 0;
	}
	
	// now add the xp to the current xp
	xp[target] += addxp;
	
	// now save the stats
	SavePlayerData( target );
	
	// for logging purposes
	new adminname[32];
	new adminid[32];
	get_user_name( id, adminname, 31 );
	get_user_authid(id, adminid, 31 );
	log_amx("[Monster Mod] %s %s gave %s %i xp ", adminname, adminid, name, addxp );
	
	console_print( id, "%s gained %i xp. New xp: %i", name, addxp, xp[target] );
	
	return PLUGIN_HANDLED;
}

// remove xp from player
public scxpm_removexp( id, level, cid ) {
	if ( !cmd_access( id, ADMIN_IMMUNITY, cid, 3 ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new targetarg[32];
	read_argv(1, targetarg, 31);
	new target = cmd_target( id, targetarg, 11 );
	if( !target )
	{
		return PLUGIN_HANDLED;
	}
	new xparg[32];
	read_argv( 2, xparg, 31 );
	new removexp = str_to_num( xparg );
	new name[32];
	get_user_name( target, name, 31 );
	
	// if players xp minus remove xp is higher than the max xp
	if ( xp[target] - removexp > 11500000 )
	{
		removexp = xp[target] - 11500000;
	}
	
	// now remove the xp from the current xp
	xp[target] -= removexp;
	
	if ( xp[target] < 0 )
	{
		xp[target] = 0;
	}
	
	// level needs to be recalculated
	playerlevel[target] = scxpm_calc_lvl ( xp[target] );
	
	//if there are too many skills some should be removed
	while ( playerlevel[target] < health[target] + armor[target] + rhealth[target] + rarmor[target] + rammo[target] + gravity[target] + speed[target] + dist[target] + dodge[target] + skillpoints[target] )
	{
		if ( health[target] > 0  )
		{
			health[target]--;
		}
		else if ( armor[target] > 0 )
		{
			armor[target]--;
		}
		else if ( rhealth[target] > 0 )
		{
			rhealth[target]--;
		}
		else if ( rarmor[target] > 0 )
		{
			rarmor[target]--;
		}
		else if ( rammo[target] > 0 )
		{
			rammo[target]--;
		}
		else if ( gravity[target] > 0 )
		{
			gravity[target]--;
		}
		else if ( speed[target] > 0 )
		{
			speed[target]--;
		}
		else if ( dist[target] > 0 )
		{
			dist[target]--;
		}
		else if ( dodge[target] > 0 )
		{
			dodge[target]--;
		}
	}
	
	// recalculate needed xp
	scxpm_calcneedxp ( target );
	
	// now save the stats
	SavePlayerData( target );
	
	// for logging purposes
	new adminname[32];
	new adminid[32];
	get_user_name( id, adminname, 31 );
	get_user_authid(id, adminid, 31 );
	log_amx("[Monster Mod] %s %s removed %s %i xp ", adminname, adminid, name, removexp );
	
	console_print( id, "%s lost %i xp. New xp: %i", name, removexp, xp[target] );
	return PLUGIN_HANDLED
}

// set gamename
public scxpm_gn() { 
	if( get_cvar_num("scxpm_gamename") >= 1 )
	{
		new g[32];
		format( g, 31, "SCXPM %s", VERSION );
		forward_return( FMV_STRING, g);
		return FMRES_SUPERCEDE;
	}
	return PLUGIN_HANDLED;
}

// set players level
public scxpm_setlvl( id, level, cid ) {
	if ( !cmd_access( id, ADMIN_IMMUNITY, cid, 3 ) )
	{
		return PLUGIN_HANDLED;
	}
	new targetarg[32];
	read_argv(1, targetarg, 31);
	new target = cmd_target( id, targetarg, 11 );
	if( !target )
	{
		return PLUGIN_HANDLED;
	}
	new lvlarg[32];
	read_argv( 2, lvlarg, 31 );
	new nowlvl = str_to_num( lvlarg );
	new name[32];
	get_user_name( target, name, 31 );
	if( nowlvl >= get_cvar_num( "scxpm_maxlevel" ) )
	{
		nowlvl = get_cvar_num( "scxpm_maxlevel" );
	}
	if ( nowlvl < 0 )
	{
		nowlvl = 0;
	}
	if ( nowlvl == playerlevel[target] )
	{
		if ( target == id )
		{
			console_print( id, "[Monster Mod] Your Level is already %i.", nowlvl );
		}
		else
		{
			console_print(id, "[Monster Mod] %s's Level is already %i.", name, nowlvl );
		}
		return PLUGIN_HANDLED
	}
	else
	{
		if ( nowlvl >= 1800 )
		{
			nowlvl = 1800;
			xp[target] = 11500000;
		}
		else
		{
			if ( nowlvl <= 0 )
			{
				nowlvl = 0;
				xp[target] = 0;
			}
			else
			{
				new helpvar = nowlvl - 1;
				new Float:m70b = float( helpvar ) * 70.0;
				new Float:mselfm3dot2b = float( helpvar ) * float(helpvar) * 3.5;
				xp[target] = floatround( m70b + mselfm3dot2b + 30.0);
			}
		}
	}
	if ( playerlevel[target] > nowlvl )
	{
		playerlevel[target] = nowlvl;
		if (target == id )
		{
			console_print( id, "[Monster Mod] You lowered your Level to %i. Calling Skill Reset!", playerlevel[target] );
		}
		else
		{
			console_print( id, "[Monster Mod] You lowered %s's Level to %i.", name, playerlevel[target] );
		}
		if (  nowlvl > 0 )
		{
			if ( target != id )
			{
				client_print( target, print_chat, "[Monster Mod] An Admin has lowered your Level to %i! Calling Skill Reset!", playerlevel[target] );
			}
			scxpm_reset( target );
		}
		else
		{
			if ( target != id )
			{
				client_print( target, print_chat, "[Monster Mod] An Admin has lowered your Level to 0! You lost all Skills!" );
			}
			health[target] = 0;
			armor[target] = 0;
			rhealth[target] = 0;
			rarmor[target] = 0;
			rammo[target] = 0;
			gravity[target] = 0;
			speed[target] = 0;
			dist[target] = 0;
			dodge[target] = 0;
			skillpoints[target] = 0;
			if ( get_user_health( target ) > starthealth )
			{
				set_user_health( target, starthealth );
			}
			if (get_user_armor( target ) > startarmor )
			{
				set_user_armor( target, startarmor );
			}
			set_user_gravity( target, 1.0 );
		}
	}
	else
	{
		if ( nowlvl < 1800 )
		{
			skillpoints[target] = skillpoints[target] + nowlvl - playerlevel[target];
			playerlevel[target] = nowlvl;
			if ( target == id )
			{
				console_print( id, "[Monster Mod] You raised your Level to %i.", playerlevel[target] );
			}
			else
			{
				console_print( id, "[Monster Mod] You raised %s's Level to %i.", name, playerlevel[target] );
				client_print( target, print_chat, "[Monster Mod] An Admin has raised your Level to %i! Calling Skill Menu!", playerlevel[target] );
			}
			SCXPMSkill( target );
		}
		else
		{
			set_user_health( target, get_user_health( target ) + 450 - health[target] );
			set_user_armor( target, get_user_armor( target ) + 450 - armor[target] );
			health[target] = 450;
			armor[target] = 450;
			rhealth[target] = 300;
			rarmor[target] = 300;
			rammo[target] = 30;
			gravity[target] = 40;
			speed[target] = 80;
			dist[target] = 60;
			dodge[target] = 90;
			skillpoints[target] = 0;
			playerlevel[target] = 1800;
			if ( target == id )
			{
				console_print( id, "[Monster Mod] You raised your Level to 1800." );
			}
			else
			{
				console_print( id, "[Monster Mod] You raised %s's Level to 1800.", name );
				client_print( target, print_chat, "[Monster Mod] An Admin has raised your Level to 1800! You got all Skills!" );
			}
		}
	}
	scxpm_calcneedxp( target );
	SavePlayerData( target );
	
	// for logging purposes
	new adminname[32];
	new adminid[32];
	get_user_name( id, adminname, 31 );
	get_user_authid(id, adminid, 31 );
	log_amx( "[Monster Mod] %s %s setlvl %s to level %i  ", adminname, adminid, name, playerlevel[target] );
	
	return PLUGIN_HANDLED;
}

// give player a medal
public scxpm_addmedal( id, level, cid) {
	if ( !cmd_access( id, ADMIN_IMMUNITY, cid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}
	new targetarg[32];
	read_argv(1, targetarg, 31);
	new target = cmd_target( id, targetarg, 11 );
	if ( !target )
	{
		return PLUGIN_HANDLED;
	}
	new name[32];
	get_user_name( target, name, 31 );
	if ( medals[target] < 16 )
	{
		medals[target]+=1;
		console_print( id, "You awarded %s with a Medal.", name );
		client_print( 0, print_chat, "[Monster Mod] %s was awarded with a Medal! (He now has %i Medals)", name, medals[target] - 1 );
	}
	else
	{
		console_print( id, "%s already has 15 Medals.", name );
	}
	
	// for logging purposes
	new adminname[32];
	new adminid[32];
	get_user_name( id, adminname, 31 );
	get_user_authid(id, adminid, 31 );
	log_amx( "[Monster Mod] %s %s addmedal to %s", adminname, adminid, name );
	
	return PLUGIN_HANDLED;
}

// remove players medal
public scxpm_removemedal( id, level, cid ) {
	if ( !cmd_access( id, ADMIN_IMMUNITY, cid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}
	new targetarg[32];
	read_argv( 1, targetarg, 31);
	new target = cmd_target( id, targetarg, 11 );
	if( !target )
	{
		return PLUGIN_HANDLED;
	}
	new name[32];
	get_user_name( target, name, 31 );
	if ( medals[target] > 1 )
	{
		medals[target]-=1;
		console_print( id, "You took a Medal of %s.", name );
		client_print( 0, print_chat, "[Monster Mod] %s lost a Medal! (He now has %i Medals)", name,medals[target] - 1 );
	}
	else
	{
		console_print( id, "%s already has no Medals.", name );
	}
	
	// for logging purposes
	new adminname[32];
	new adminid[32];
	get_user_name( id, adminname, 31 );
	get_user_authid(id, adminid, 31 );
	log_amx( "[Monster Mod] %s %s removemedal from %s", adminname, adminid, name );
	
	return PLUGIN_HANDLED;
}

// toggle godmode
public scxpm_godmode(id,level,cid) {
	if ( !cmd_access( id, ADMIN_IMMUNITY, cid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}
	new godmode_arg[32];
	read_argv( 1, godmode_arg, 31 );
	new godmode_target = cmd_target( id, godmode_arg, 0 );
	if ( godmode_target )
	{
		new godmode_name[32];
		get_user_name( godmode_target, godmode_name, 31);
		if ( !is_user_alive( godmode_target ) )
		{
			console_print( id, "[Monster Mod] The User %s is currently dead!", godmode_name );
			return PLUGIN_HANDLED;
		}
		if ( has_godmode[godmode_target] )
		{
			set_user_godmode( godmode_target );
			has_godmode[godmode_target] = false;
			if ( godmode_target == id )
			{
				console_print(id,"[Monster Mod] You disabled God Mode on yourself!");
			}
			else
			{
				console_print( id, "[Monster Mod] The User %s lost his God Mode!", godmode_name );
				client_print( godmode_target, print_chat, "[Monster Mod] An Admin has disabled God Mode on you!" );
			}
		}
		else
		{
			has_godmode[godmode_target] = true;
			set_user_godmode( godmode_target, 1 );
			if ( godmode_target == id )
			{
				console_print( id, "[Monster Mod] You enabled God Mode on yourself!" );
			}
			else
			{
				console_print( id, "[Monster Mod] The User %s now has God Mode!", godmode_name );
				client_print( godmode_target, print_chat, "[Monster Mod] An Admin has enabled God Mode on you!" );
			}
		}
	}
	return PLUGIN_HANDLED;
}

// toggle noclip
public scxpm_noclipmode( id, level, cid ) {
	if ( !cmd_access( id, ADMIN_IMMUNITY, cid, 2 ) )
	{
		return PLUGIN_HANDLED;
	}
	new noclipmode_arg[32];
	read_argv( 1, noclipmode_arg, 31 );
	new noclipmode_target = cmd_target( id, noclipmode_arg, 0 );
	if ( noclipmode_target )
	{
		new noclipmode_name[32];
		get_user_name( noclipmode_target, noclipmode_name, 31 );
		if ( !is_user_alive( noclipmode_target ) )
		{
			console_print( id, "[Monster Mod] The User %s is currently dead!", noclipmode_name );
			return PLUGIN_HANDLED;
		}
		if ( get_user_noclip( noclipmode_target ) )
		{
			set_user_noclip( noclipmode_target );
			if ( noclipmode_target == id )
			{
				console_print( id, "[Monster Mod] You disabled Noclip Mode on yourself" );
			}
			else
			{
				console_print( id, "[Monster Mod] The User %s lost his Noclip Mode!", noclipmode_name );
				client_print( noclipmode_target, print_chat, "[Monster Mod] An Admin has disabled Noclip Mode on you!" );
			}
		}
		else
		{
			set_user_noclip( noclipmode_target, 1 );
			if ( noclipmode_target == id )
			{
				console_print( id, "[Monster Mod] You enabled Noclip Mode on yourself!" );
			}
			else
			{

				console_print( id, "[Monster Mod] The User %s now has Noclip Mode!", noclipmode_name );
				client_print( noclipmode_target, print_chat, "[Monster Mod] An Admin has enabled Noclip Mode on you!" );
			}
		}
	}
	return PLUGIN_HANDLED;
}

// reset players skills
public scxpm_reset(id) {
	health[id] = 0;
	armor[id] = 0;
	rhealth[id] = 0;
	rarmor[id] = 0;
	rammo[id] = 0;
	gravity[id] = 0;
	speed[id] = 0;
	dist[id] = 0;
	dodge[id] = 0;
	//xp[id] = 0;
	skillpoints[id] = playerlevel[id];
	if ( get_user_health( id ) > starthealth + medals[id] )
	{
		set_user_health( id, starthealth + medals[id] )
	}
	if ( get_user_armor(id) > startarmor + medals[id] )
	{
		set_user_armor( id, startarmor + medals[id] )
	}
	set_user_gravity( id, 1.0 )
	if ( skillpoints[id] > 0 )
	{
		client_print( id, print_chat, "[Monster Mod] All your Skills have been set back. Please choose..." );
		SCXPMSkill( id );
	}
	else
	{
		client_print( id, print_chat, "[Monster Mod] You have no Skills to reset." );
	}
}

// show plugin info
public scxpm_version( id ) {
	new allinfo[1023];
	format( allinfo, 1022, "Plugin Name: SCXPM (Sven Cooperative Experience Mod)^nPlugin Type: Running under AMXModX (www.amxmodx.org)^nAuthor: Silencer^nVersion: %s^nLast Update: %s^nExperience Multiplier (Server Side): %f^nInformation: http://forums.alliedmods.net/showthread.php?t=44168", VERSION, LASTUPDATE, get_cvar_float( "scxpm_xpgain" ) );
	show_motd( id, allinfo, "SCXPM Information" );
}

// show players skill data
public scxpm_info( id ) {
	#if defined USING_CS
	new allskills[1023] = "1. Strength:<br />   Starthealth + 1 * Strengthlevel.<br />";
	format(allskills,1022,"%s<br />2. Superior Armor:<br />   Startarmor + 1 * Armorlevel.<br />",allskills);
	format(allskills,1022,"%s<br />3. Regeneration:<br />   One HP every (150.5-(Regenerationlevel/2)) Seconds<br />   + Bonus Chance every 0.5 Seconds.<br />",allskills);
	format(allskills,1022,"%s<br />4. Nano Armor:<br />   One AP every (150.5-(Nanoarmorlevel/2)) Seconds<br />   + Bonus Chance every 0.5 Seconds.<br />",allskills);
	format(allskills,1022,"%s<br />5. Ammunition Reincarnation:<br />   Ammunition for current Weapon every (90-(Ammolevel*2.5)) Seconds.<br />",allskills);
	format(allskills,1022,"%s<br />6. Anti Gravity Device:<br />   Lowers your Gravity by (1.5)%% per Level. Hold Jump-Key!<br />",allskills);
	format(allskills,1022,"%s<br />7. Awareness:<br />   Generic Skill which is enhancing many other Skills a bit.<br />",allskills);
	format(allskills,1022,"%s<br />8. Team Power:<br />   Supports nearby Teammates with HP and AP<br />   and also yourself on higher Level.<br />",allskills);
	format(allskills,1022,"%s<br />9. Block Attack:<br />   Chance on fully blocking any Attack of (Blocklevel/3)%%.<br />",allskills);
	format(allskills,1022,"%s<br />Special - Medals:<br />   Given by an Admin, Shows your Importance.<br />   (Minimal Ability Support)",allskills);
	#else
	new allskills[1023] = "1. Strength:^n   Starthealth + 1 * Strengthlevel.^n";
	format(allskills,1022,"%s^n2. Superior Armor:^n   Startarmor + 1 * Armorlevel.^n",allskills);
	format(allskills,1022,"%s^n3. Regeneration:^n   One HP every (150.5-(Regenerationlevel/2)) Seconds^n   + Bonus Chance every 0.5 Seconds.^n",allskills);
	format(allskills,1022,"%s^n4. Nano Armor:^n   One AP every (150.5-(Nanoarmorlevel/2)) Seconds^n   + Bonus Chance every 0.5 Seconds.^n",allskills);
	format(allskills,1022,"%s^n5. Ammunition Reincarnation:^n   Ammunition for current Weapon every (90-(Ammolevel*2.5)) Seconds.^n",allskills);
	format(allskills,1022,"%s^n6. Anti Gravity Device:^n   Lowers your Gravity by (1.5)%% per Level. Hold Jump-Key!^n",allskills);
	format(allskills,1022,"%s^n7. Awareness:^n   Generic Skill which is enhancing many other Skills a bit.^n",allskills);
	format(allskills,1022,"%s^n8. Team Power:^n   Supports nearby Teammates with HP and AP^n   and also yourself on higher Level.^n",allskills);
	format(allskills,1022,"%s^n9. Block Attack:^n   Chance on fully blocking any Attack of (Blocklevel/3)%%.^n",allskills);
	format(allskills,1022,"%s^nSpecial - Medals:^n   Given by an Admin, Shows your Importance.^n   (Minimal Ability Support)",allskills);
	#endif
	show_motd(id,allskills,"Skills Information")
}

// show all connected players skills
public scxpm_others( id ) {
	new alldata[2048];
	#if defined USING_CS
		alldata="<html><head><title>Players levels</title></head><body><table border='1'><tr><th width='200' align='left' cellpadding='5'>Playername</th><th width='40'>Level</th><th width='40'>Medals</th></tr>"
		new iPlayers[32],iNum
		get_players(iPlayers,iNum)
		for(new g=0;g<iNum;g++)
		{
			new i=iPlayers[g]
			if(is_user_connected(i))
			{
				new name[20]
				get_user_name(i,name,19)
				format(alldata,2047,"%s<tr><td>%s</td><td align='center'>%i</td><td align='center'>%i</td>",alldata,name,playerlevel[i],medals[i]-1)
			}
		}
		format(alldata,2047,"%s</table></body></html>",alldata)
	#else
		alldata="Playername            Level  Medals^n"
		new iPlayers[32],iNum
		get_players(iPlayers,iNum)
		for(new g=0;g<iNum;g++)
		{
			new i=iPlayers[g]
			if(is_user_connected(i))
			{
				new name[20]
				get_user_name(i,name,19)
				new toadd=20-strlen(name)
				new spaces[20]=""
				add(spaces,19,"                   ",toadd)
				format(alldata,2047,"%s^n%s %s %i     %i",alldata,name,spaces,playerlevel[i],medals[i]-1)
			}
		}
	#endif
	show_motd( id, alldata, "Players Data" );
}

// get the different ranks
public scxpm_getrank( id ) {
	switch( playerlevel[id] )
	{
		case 1800:
		{
			rank[id] = "Highest Force Leader";
		}
		case 1700..1799:
		{
			rank[id] = "Highest Force Member";
		}
		case 1600..1699:
		{
			rank[id] = "Top 15 of most famous Leaders";
		}
		case 1500..1599:
		{
			rank[id] = "Top 30 of most famous Leaders";
		}
		case 1400..1499:
		{
			rank[id] = "General";
		}
		case 1300..1399:
		{
			rank[id] = "Hidden Operations Leader";
		}
		case 1200..1299:
		{
			rank[id] = "Hidden Operations Scheduler";
		}
		case 1100..1199:
		{
			rank[id] = "Hidden Operations Member";
		}
		case 1000..1099:
		{
			rank[id] = "United Forces Leader";
		}
		case 900..999:
		{
			rank[id] = "United Forces Member";
		}
		case 800..899:
		{
			rank[id] = "Special Force Leader";
		}
		case 700..799:
		{
			rank[id] = "Special Force Member";
		}
		case 600..699:
		{
			rank[id] = "Professional Force Leader";
		}
		case 500..599:
		{
			rank[id] = "Professional Force Member";
		}
		case 400..499:
		{
			rank[id] = "Professional Free Agent";
		}
		case 300..399:
		{
			rank[id] = "Free Agent";
		}
		case 200..299:
		{
			rank[id] = "Private First Class";
		}
		case 100..199:
		{
			rank[id] = "Private Second Class";
		}
		case 50..99:
		{
			rank[id] = "Private Third Class";
		}
		case 20..49:
		{
			rank[id] = "Fighter";
		}
		case 5..19:
		{
			rank[id] = "Civilian";
		}
		case 0..4:
		{
			rank[id] = "Frightened Civilian";
		}
	}
}

// give extra info for beginners
public scxpm_newbiehelp( id ) {
	if ( is_user_connected( id ) )
	{
		new name[32];
		get_user_name( id, name, 31);
		client_print( id, print_chat, "[Monster Mod] Hello, %s! Monster Mod (SCXPM) %s by Gin And Khalid is enabled!", name,VERSION );
		client_print( id, print_chat, "[Monster Mod] Commands: ^"'say skillsinfo', 'say selectskills', 'say resetskills', 'say playerskills'^"" );
	}
}

// if player got the steam id load again
public client_authorized( id ) {
	LoadPlayerData( id );
	
	g_iMonsterFrags[id] = 0
	g_flNextSee[id] = 0.0
	get_user_authid(id, g_szSteamId[id], charsmax(g_szSteamId[]))
	
	new szIp[20]; get_user_ip(id, szIp, charsmax(szIp), 0);
	geoip_country(szIp, g_szCountry[id], charsmax(g_szCountry[]));
}

// load empty skills for new player or faulty load
public LoadEmptySkills( id ) {
	xp[id] = 0;
	playerlevel[id] = 0;
	scxpm_calcneedxp( id );
	scxpm_getrank( id );
	skillpoints[id] = 0;
	medals[id] = 4;
	health[id] = 0;
	armor[id] = 0;
	rhealth[id] = 0;
	rarmor[id] = 0;
	rammo[id] = 0;
	gravity[id] = 0;
	speed[id] = 0;
	dist[id] = 0;
	dodge[id] = 0;
	lastDeadflag[id] = 1;
	lastfrags[id] = 0;
	set_task( 35.0, "scxpm_newbiehelp", id, "", 0, "a", 3 );
}

// prepare data on client connect
public client_connect( id ) {
	if (get_cvar_num( "scxpm_debug") == 1 )
	{
		log_amx( "[SCXPM DEBUG] Begin client_connect" );
		new name[64];
		get_user_name( id, name, 63);
		log_amx( "[SCXPM DEBUG] %s connected", name );
	}
	lastfrags[ id ] = 0;
	load_error[ id ] = false;
	loaddata[ id ] = false;
	// if savemode is on steamid don't load till the id is retreived
	if ( get_cvar_num( "scxpm_save" ) < 2 )
	{
		LoadPlayerData( id );
	}
	if (get_cvar_num( "scxpm_debug") == 1 )
	{
		log_amx( "[SCXPM DEBUG] End client_connect" );
	}
}

// clear data on client disconnect
public client_disconnect( id ) {
	if (get_cvar_num( "scxpm_debug") == 1 )
	{
		log_amx( "[SCXPM DEBUG] Begin client_disconnect" );
		new name[64];
		get_user_name( id, name, 63);
		log_amx( "[SCXPM DEBUG] %s disconnected", name );
	}
	
	if ( get_cvar_num( "scxpm_minplaytime" ) == 0 || get_cvar_num( "scxpm_minplaytime" ) <= get_user_time( id ) ) {
		SavePlayerData( id );
	}
	else {
		if (get_cvar_num( "scxpm_debug") == 1 ) {
			log_amx( "[SCXPM DEBUG] Player is too short in the server, don't save stats" );
		}
	}
	
	xp[id] = 0;
	neededxp[id] = 0;
	playerlevel[id] = 0;
	skillpoints[id] = 0;
	medals[id] = 0;
	health[id] = 0;
	armor[id] = 0;
	rhealth[id] = 0;
	rarmor[id] = 0;
	rammo[id] = 0;
	gravity[id] = 0;
	speed[id] = 0;
	dist[id] = 0;
	dodge[id] = 0;
	rarmorwait[id] = 0;
	rhealthwait[id] = 0;
	ammowait[id] = 0;
	rank[id] = "Loading...";
	load_error[ id ] = false;
	loaddata[ id ] = false;
	if (get_cvar_num( "scxpm_debug") == 1 )
	{
		log_amx( "[SCXPM DEBUG] End client_disconnect" );
	}
}

// check respawn and gravity
public scxpm_prethink( id ) {
	new deadflag = pev( id, pev_deadflag );
	if ( !deadflag && lastDeadflag[id] )
	{
		scxpm_client_spawn( id );
	}
	
	lastDeadflag[id] = deadflag;
	if ( pev( id, pev_button ) &IN_JUMP )
	{
		gravityon( id );
	}
	else
	{
		if ( pev( id, pev_oldbuttons ) &IN_JUMP )
		{
			gravityoff( id );
		}
	}
}

// set players health and armor on spawn
public scxpm_client_spawn( id ) {
	starthealth = get_user_health( id );
	startarmor = get_user_armor( id );
	set_user_health( id, health[id] + starthealth + medals[id] );
	set_user_armor( id, armor[id] + startarmor + medals[id] );
}

// set players health and armor on spawn
public client_spawn ( id ) {
	starthealth = get_user_health( id );
	startarmor = get_user_armor( id );
	set_user_health( id, health[id] + starthealth + medals[id] );
	set_user_armor( id, armor[id] + startarmor + medals[id] );
} 

// set players health and armor on round start
public roundstart ( ) {
	if ( get_cvar_num( "scxpm_debug" ) == 1 )
	{
		log_amx( "[SCXPM DEBUG] round_start" );
	}
	
	for ( new i = 0; i < 33; i++ )
	{
		lastDeadflag[i] = 1;
	}
	
	// loop through the players and set their stats
	new iPlayers[32], iNum;
	get_players( iPlayers, iNum );
	
	for( new g = 0; g<iNum ;g++ )
	{
		new id = iPlayers[g];
		
		new name[32];
		get_user_name( id, name, 31 );
	
		starthealth = get_user_health( id );
		startarmor = get_user_armor( id );
		
		if ( get_cvar_num( "scxpm_debug" ) == 1 )
		{
			log_amx( "[SCXPM DEBUG] %s starthealth: %i", name, starthealth);
			log_amx( "[SCXPM DEBUG] setting %s health to: %i", name, health[id] + starthealth + medals[id]);
		}
		set_user_health( id, health[id] + starthealth + medals[id] );
		set_user_armor( id, armor[id] + startarmor + medals[id] );
	}
}

// set gravity on for player
public gravityon( id ) {
	if ( is_user_connected( id ) )
	{
		if ( is_user_alive( id ) )
		{
			set_user_gravity( id, 1.0 - ( 0.015 * gravity[id] ) - ( 0.001 * medals[id] ) );
		}
	}
}

// set gravity off for player
public gravityoff( id ) {
	if ( is_user_connected( id ) )
	{
		if ( is_user_alive( id ) )
		{
			set_user_gravity( id, 1.0 );
		}
	}
}

// calculate needed xp for next level
public scxpm_calcneedxp ( id ) {
	new Float:m70 = float( playerlevel[id] ) * 70.0;
	new Float:mselfm3dot2 = float( playerlevel[id] ) * float( playerlevel[id] ) * 3.5;
	neededxp[id] = floatround( m70 + mselfm3dot2 + 30.0 );
}

// calculate level from xp
public scxpm_calc_lvl ( xp ) {
	return floatround( -10 + floatsqroot( 100 - ( 60 / 7 - ( ( xp - 1 ) / 3.5 ) ) ), floatround_ceil );
}

public scxpm_calc_xp ( level) {
	level--;
	return floatround( (float( level ) * 70.0) + (float( level ) * float(level) * 3.5) + 30);
}

// give ammo
public scxpm_randomammo( i ) {
	new number = random_num(0,6)
#if defined USING_CS
	give_item(i, ammotype[number]);
#else
	new clip,ammo
	if(number==0)
	{
		get_user_ammo(i,2,clip,ammo)
		if(ammo<250)
		{
			give_item(i,"ammo_9mmclip")

		}
		else
		{
			number=1
		}
	}
	if(number==1)
	{
		get_user_ammo(i,3,clip,ammo)
		if(ammo<36)
		{
			give_item(i,"ammo_357")
		}
		else
		{
			number=2
		}
	}
	if(number==2)
	{

		get_user_ammo(i,7,clip,ammo)
		if(ammo<125)
		{
			give_item(i,"ammo_buckshot")
		}
		else
		{
			number=3
		}
	}
	if(number==3)
	{
		get_user_ammo(i,9,clip,ammo)
		if(ammo<100)
		{
			give_item(i,"ammo_gaussclip")
		}
		else
		{
			number=4
		}
	}
	if(number==4)
	{
		get_user_ammo(i,6,clip,ammo)
		if(ammo<50)
		{
			give_item(i,"ammo_crossbow")
		}
		else
		{
			number=5
		}
	}
	if(number==5)
	{
		get_user_ammo(i,8,clip,ammo)
		if(ammo<5)
		{
			give_item(i,"ammo_rpgclip")
		}
		else
		{
			number=6
		}
	}
	if(number==6)
	{
		get_user_ammo(i,23,clip,ammo)
		if(ammo<15)
		{
			give_item(i,"ammo_762")
		}
		else
		{
			give_item(i,"ammo_556")
		}
	}
#endif
}

// give stuff
public scxpm_regen() {
	new iPlayers[32],iNum
	get_players(iPlayers,iNum)
	for(new g=0;g<iNum;g++)
	{
		new i=iPlayers[g]
		if(is_user_connected(i))
		{
			if(is_user_alive(i))
			{
				new halfspeed=floatround(float(speed[i])/2.0)
				if(rhealth[i]>0)
				{
					if(rhealthwait[i]==0)
					{
						if(get_user_health(i)<health[i]+starthealth+medals[i]+halfspeed)
						{
							set_user_health(i,get_user_health(i)+1)
							rhealthwait[i]=300-rhealth[i]
						}
					}
					else
					{
						rhealthwait[i]-=1
						if(get_user_health(i)<health[i]+starthealth+medals[i]+halfspeed&&random_num(0,200+rhealth[i]+medals[i]+halfspeed)>200)
						{
							set_user_health(i,get_user_health(i)+1)
						}
					}
				}
				if(rarmor[i]>0)
				{
					if(rarmorwait[i]==0)
					{
						if(get_user_armor(i)<armor[i]+startarmor+medals[i]+halfspeed)
						{
							set_user_armor(i,get_user_armor(i)+1)
							rarmorwait[i]=300-rarmor[i]
						}
					}
					else
					{
						rarmorwait[i]-=1
						if(get_user_armor(i)<armor[i]+startarmor+medals[i]+halfspeed&&random_num(0,200+rarmor[i]+medals[i]+halfspeed)>200)
						{
							set_user_armor(i,get_user_armor(i)+1)
						}
					}
				}
				if(rammo[i]>0)
				{
					if(ammowait[i]==0)
					{
#if defined USING_CS
						scxpm_randomammo(i)
#else
						new clip,ammo
						switch(get_user_weapon(i,clip,ammo))
						{
							case 1: /* Crowbar */
							{
								scxpm_randomammo(i)
							}
							case 2: /* 9mm Handgun */
							{
								get_user_ammo(i,2,clip,ammo)
								if(ammo<250)
								{
									give_item(i,"ammo_9mmclip")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 3: /* 357 (Revolver) */
							{
								get_user_ammo(i,3,clip,ammo)
								if(ammo<36)
								{
									give_item(i,"ammo_357")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 4: /* 9mm AR = MP5 */
							{
								get_user_ammo(i,4,clip,ammo)
								if(ammo<250)
								{
									give_item(i,"ammo_9mmAR")
								}
								else
								{
									scxpm_randomammo(i)
								}
								give_item(i,"ammo_ARgrenades")
							}
							case 6: /* Crossbow */
							{
								get_user_ammo(i,6,clip,ammo)
								if(ammo<50)
								{
									give_item(i,"ammo_crossbow")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 7: /* Shotgun */
							{
								get_user_ammo(i,7,clip,ammo)
								if(ammo<125)
								{
									give_item(i,"ammo_buckshot")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 8: /* RPG Launcher */
							{
								get_user_ammo(i,8,clip,ammo)
								if(ammo<5)
								{
									give_item(i,"ammo_rpgclip")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 9: /* Gauss Cannon */
							{
								get_user_ammo(i,9,clip,ammo)
								if(ammo<100)
								{
									give_item(i,"ammo_gaussclip")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 10: /* Egon */
							{
								get_user_ammo(i,10,clip,ammo)
								if(ammo<100)
								{
									give_item(i,"ammo_gaussclip")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 11: /* Hornetgun */
							{
								scxpm_randomammo(i)
							}
							case 12: /* Handgrenade */
							{
								scxpm_randomammo(i)
							}
							case 13: /* Tripmine */
							{
								scxpm_randomammo(i)
							}
							case 14: /* Satchels */
							{
								scxpm_randomammo(i)
							}
							case 15: /* Snarks */
							{
								scxpm_randomammo(i)
							}
							case 16: /* Uzi Akimbo */
							{
								get_user_ammo(i,16,clip,ammo)
								if(ammo<250)
								{
									give_item(i,"ammo_9mmAR")
									give_item(i,"ammo_9mmclip")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 17: /* Uzi */
							{
								get_user_ammo(i,17,clip,ammo)
								if(ammo<100)
								{
									give_item(i,"ammo_9mmAR")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 18: /* Medkit */
							{
								scxpm_randomammo(i)
								if(get_user_health(i)<health[i]+starthealth+medals[i]+halfspeed)
								{
									set_user_health(i,get_user_health(i)+1)
									rhealthwait[i]=300-rhealth[i]
								}
							}
							case 20: /* Pipewrench */
							{
								scxpm_randomammo(i)
							}
							case 21: /* Minigun */
							{
								get_user_ammo(i,21,clip,ammo)
								if(ammo<999)
								{
									give_item(i,"ammo_556")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
							case 22: /* Grapple */
							{
								scxpm_randomammo(i)
							}
							case 23: /* Sniper Rifle */
							{
								get_user_ammo(i,23,clip,ammo)
								if(ammo<15)
								{
									give_item(i,"ammo_762")
								}
								else
								{
									scxpm_randomammo(i)
								}
							}
						}
#endif
						new speed_dt=floatround(float(speed[i])/18.0)
						ammowait[i]=179-(5*rammo[i])-speed_dt
					}
					else
					{
						ammowait[i]-=1
					}
				}
#if !defined USING_CS
				new clip,ammo
				switch(get_user_weapon(i,clip,ammo))
				{
					case 18: /* Medkit */
					{
						if(get_user_health(i)<100)
						{
							if(random_num(rhealth[i],800-get_user_health(i)>299))
							{
								set_user_health(i,get_user_health(i)+1)
							}
						}
						else
						{
							if(get_user_health(i)<health[i]+starthealth+medals[i]+halfspeed&&random_num(0,1300+rhealth[i])>1200)
							{
								set_user_health(i,get_user_health(i)+1)
							}
						}
					}
				}
#endif
				if(dist[i]>0)
				{
					for(new h=0;h<iNum;h++)
					{
						new id=iPlayers[h]
						for(new j=0;j<iNum;j++)
						{
							new i=iPlayers[j]
							if(id==i)
							{
								// Do nothing
							}
							else
							{
								if(is_user_alive(i)&&is_user_alive(id))
								{
									new Float:origin_i[3]
									pev(i,pev_origin,origin_i)
									new Float:origin_id[3]
									pev(id,pev_origin,origin_id)
									if(get_distance_f(origin_i,origin_id)<=650.0)
									{
										new halfspeed=floatround(float(speed[i])/2.0)
										new iPlayers[32],iNum
										get_players(iPlayers,iNum)
										iNum=iNum*50
										new luck=random_num(1651-iNum,4200+dist[id]+dist[i]+halfspeed)
										if(luck>4200)
										{
											set_user_health(i,get_user_health(i)+1)
											if(get_user_health(i)>health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
											{
												set_user_health(i,health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
											}
										}
										luck=random_num(1651-iNum,4200+dist[id]+dist[i]+halfspeed)
										if(luck>4200)
										{
											set_user_armor(i,get_user_armor(i)+1)
											if(get_user_armor(i)>health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
											{
												set_user_armor(i,health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
											}
										}
										if(dist[id]>=40)
										{
											luck=random_num(0,1000+dist[id])
											if(luck>1038)
											{
												set_user_health(i,get_user_health(i)+1)
												if(get_user_health(i)>health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
												{
													set_user_health(i,health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
												}
												set_user_armor(i,get_user_armor(i)+1)
												if(get_user_armor(i)>health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
												{
													set_user_armor(i,health[i]+starthealth+60+dist[id]+medals[i]+halfspeed)
												}
											}
										}
									}
								}
							}
						}
					}
				}
				if(!has_godmode[i])
				{
					if(dodge[i]>0)
					{
						new piecespeed=floatround(float(speed[i])/7.0)
						new luck=random_num(0,185+dodge[i]+medals[i]+piecespeed)
						if(luck>185)
						{
							set_user_godmode(i,1)
						}
						else
						{
							set_user_godmode(i)
						}
					}
					else
					{
						set_user_godmode(i)
					}
				}
			}
		}
	}
}

// periodic calculations
public scxpm_sdac() {
	#if defined USING_CS
		scxpm_showdata();
		scxpm_regen();
	#else
		switch(onecount)
		{
			case false:
			{
				onecount = true;
			}
			case true:
			{
				scxpm_reexp();
				scxpm_showdata();
				onecount = false;
			}
		}
		scxpm_regen();
	#endif
	
	// added health fix
	/*
	new iPlayers[32], iNum, hp;
	get_players( iPlayers, iNum );
	for ( new i = 0; i < iNum; i++ ) {
		if(is_user_alive(i)) {
			hp = get_user_health(i);
			if (hp > 255 && (hp % 256) == 0) {
				set_user_health(i, hp++);
			}
		}
	}
	*/
}

#if !defined USING_CS
	public scxpm_reexp() {
		new iPlayers[32], iNum;
		get_players( iPlayers, iNum );
		for( new g = 0; g < iNum; g++ )
		{
			new i=iPlayers[g];
			if ( is_user_connected(i) )
			{
				if ( playerlevel[i] >= 1800 ) {
					xp[i] = 11500000;
				}
				else if ( playerlevel[i] >= get_cvar_num( "scxpm_maxlevel" ) ) {
					xp[i] = scxpm_calc_xp( playerlevel[i] );
				}
				else {
					new Float:helpvar = float(xp[i])/5.0/get_cvar_float("scxpm_xpgain")+float(get_user_frags(i))-float(lastfrags[i]);
					xp[i]=floatround(helpvar*5.0*get_cvar_float("scxpm_xpgain"));
					
					if ( get_cvar_num( "scxpm_save_frequent" ) == 1 ) {
						SavePlayerData( i );
					}
					
					lastfrags[i] = get_user_frags(i);
					if( neededxp[i] > 0 ) {
						if(xp[i] >= neededxp[i]) {
							new playerlevelOld = playerlevel[i];
							playerlevel[i] = scxpm_calc_lvl(xp[i]);
							skillpoints[i] += playerlevel[i] - playerlevelOld;
							scxpm_calcneedxp(i);
							
							new name[32];
							get_user_name( i, name, 31 );
							if ( playerlevel[i] == 1800 )
							{
								client_print(0,print_chat,"[Monster Mod] Everyone say ^"Congratulations!!!^" to %s, who has reached Level 1800!",name)
								log_amx("[Monster Mod] Player %s reached level 1800!", name );
							}
							else
							{
								client_print(i,print_chat,"[Monster Mod] Congratulations, %s, you are now Level %i - Next Level: %i XP - Needed: %i XP",name,playerlevel[i],neededxp[i],neededxp[i]-xp[i])
								log_amx("[Monster Mod] Player %s reached level %i!", name, playerlevel[i] );
							}
							scxpm_getrank(i)
							SCXPMSkill(i)
							// just in case save the data
							SavePlayerData( i );
						}
					}
				}
			}
		}
	}
#else

public death() {
    new killerId, victimId;
    killerId = read_data(1);
    victimId = read_data(2);
    /*
    if ( get_cvar_num( "scxpm_debug" ) == 1 )
    {
        new nickname[35];
        server_print( "[SCXPM DEBUG] death is triggered." );
        server_print( "[SCXPM DEBUG] killerId: %d",killerId );
        
        get_user_name( killerId, nickname, 34 );
        server_print( "[SCXPM DEBUG] killer name: %s", nickname );
        
        server_print( "[SCXPM DEBUG] victimId: %d",victimId );
        get_user_name( victimId, nickname, 34 );
        server_print( "[SCXPM DEBUG] victim name: %s", nickname );
    }
    */

    if (killerId < 1 || victimId < 1 || !is_user_connected(killerId) || killerId == victimId) {
        if ( get_cvar_num( "scxpm_debug" ) == 1 )
        {
            log_amx("[SCXPM DEBUG] Suicide or invalid killer/victim, dont award xp for kill");
        }
        return PLUGIN_HANDLED;
    }
    
    if ( playerlevel[killerId] < get_cvar_num( "scxpm_maxlevel" ) ) {
        scxpm_kill( killerId );
    }

    return PLUGIN_HANDLED;
}  

public scxpm_kill( id ) {
	xp[id] +=  floatround( 5.0 * get_cvar_float( "scxpm_xpgain" ) );
	if ( get_cvar_num( "scxpm_save_frequent" ) == 1 )
	{
		SavePlayerData( id );
	}
	
	scxpm_calcneedxp(id);
	if( neededxp[id] > 0 )
	{
		if( xp[id] >= neededxp[id] )
		{
			new playerlevelOld = playerlevel[id];
			playerlevel[id] = scxpm_calc_lvl( xp[id] );
			skillpoints[id] += playerlevel[id] - playerlevelOld;
			scxpm_calcneedxp( id );
			
			new name[64];
			get_user_name( id, name, 63 );
			if ( playerlevel[id] == 1800 )
			{
				client_print(0,print_chat,"[Monster Mod] Everyone say ^"Congratulations!!!^" to %s, who has reached Level 1800!",name)
				log_amx("[Monster Mod] Player %s reached level 1800!", name );
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] Congratulations, %s, you are now Level %i - Next Level: %i XP - Needed: %i XP",name,playerlevel[id],neededxp[id],neededxp[id]-xp[id])
				log_amx("[Monster Mod] Player %s reached level %i!", name, playerlevel[id] );
			}
			
			scxpm_getrank( id );
			
			SCXPMSkill( id );
			// just in case save the data
			SavePlayerData( id );
		}
	}
}
#endif
// show players data
public scxpm_showdata() {
	new iPlayers[32],iNum
	get_players(iPlayers,iNum)
	for(new g=0;g<iNum;g++)
	{
		new i=iPlayers[g]
		if(is_user_connected(i))
		{
			set_hudmessage(50,135,180,0.5,0.04,0,1.0,255.0,0.0,0.0,get_cvar_num("scxpm_hud_channel"))
			//set_hudmessage(50,135,180,-1.0,0.04,0,1.0,255.0,0.0,0.0,get_cvar_num("scxpm_hud_channel"))
			switch(playerlevel[i])
			{
				case 1800:
				{
					show_hudmessage(i,"Level:   1800 / 1800^nRank:   Highest Force Leader^nMedals:   %i / 15^nHealth:   %i^nArmor:   %i", medals[i]-1, get_user_health( i ), get_user_armor( i ) )
				}
				default:
				{
					if ( get_user_health( i ) > 250 || get_user_armor( i ) > 250)
					{
						show_hudmessage(i,"Exp.:   %i / %i  (+%i)^nLevel:   %i / 1800^nRank:   %s^nMedals:   %i / 15^nHealth:   %i^nArmor:   %i", xp[i],neededxp[i],neededxp[i]-xp[i],playerlevel[i],rank[i],medals[i]-1, get_user_health( i ), get_user_armor( i ) )
					}
					else
					{
						show_hudmessage(i,"Exp.:   %i / %i  (+%i)^nLevel:   %i / 1800^nRank:   %s^nMedals:   %i / 15", xp[i],neededxp[i],neededxp[i]-xp[i],playerlevel[i],rank[i],medals[i]-1 )
					}
				}
			}
			
			if (playerlevel[i] >= 1800) {
				show_hudmessage(i,"Level:   1800 / 1800^nRank:   Highest Force Leader^nMedals:   %i / 15^nHealth:   %i^nArmor:   %i", medals[i]-1, get_user_health( i ), get_user_armor( i ) )
			}
			else if ( playerlevel[i] >= get_cvar_num( "scxpm_maxlevel" ) ) {
				if ( get_user_health( i ) > 250 || get_user_armor( i ) > 250)
				{
					show_hudmessage(i,"Exp.:   %i^nLevel:   %i / %i^nRank:   %s^nMedals:   %i / 15^nHealth:   %i^nArmor:   %i", xp[i],playerlevel[i],get_cvar_num( "scxpm_maxlevel" ),rank[i],medals[i]-1, get_user_health( i ), get_user_armor( i ) )
				}
				else
				{
					show_hudmessage(i,"Exp.:   %i^nLevel:   %i / %i^nRank:   %s^nMedals:   %i / 15", xp[i],playerlevel[i],get_cvar_num( "scxpm_maxlevel" ),rank[i],medals[i]-1 )
				}
			}
			else {
				if ( get_user_health( i ) > 250 || get_user_armor( i ) > 250)
				{
					show_hudmessage(i,"Exp.:   %i / %i  (+%i)^nLevel:   %i / %i^nRank:   %s^nMedals:   %i / 15^nHealth:   %i^nArmor:   %i", xp[i],neededxp[i],neededxp[i]-xp[i],playerlevel[i],get_cvar_num( "scxpm_maxlevel" ),rank[i],medals[i]-1, get_user_health( i ), get_user_armor( i ) )
				}
				else
				{
					show_hudmessage(i,"Exp.:   %i / %i  (+%i)^nLevel:   %i / %i^nRank:   %s^nMedals:   %i / 15", xp[i],neededxp[i],neededxp[i]-xp[i],playerlevel[i],get_cvar_num( "scxpm_maxlevel" ),rank[i],medals[i]-1 )
				}
			}
		}
	}
}

// show skill calculation
public SCXPMSkill( id ) {
	// the default value for the increment is 1
	skillIncrement[id] = 1;
	
	if (skillpoints[id] > 20) {
		SCXPMIncrementMenu( id );
	}
	else {
		SCXPMSkillMenu( id );
	}
}

// show the skills menu
public SCXPMSkillMenu( id ) {
	new menuBody[1024];
	format(menuBody,1023,"Select Skills - Skillpoints available: %i^n^n1.   Strength  [ %i / 450 ]^n2.   Superior Armor  [ %i / 450 ]^n3.   Health Regeneration  [ %i / 300 ]^n4.   Nano Armor  [ %i / 300 ]^n5.   Ammo Reincarnation  [ %i / 30 ]^n6.   Anti Gravity Device  [ %i / 40 ]^n7.   Awareness  [ %i / 80 ]^n8.   Team Power  [ %i / 60 ]^n9.   Block Attack  [ %i / 90 ]^n0.   Done"
	,skillpoints[id],health[id],armor[id],rhealth[id],rarmor[id],rammo[id],gravity[id],speed[id],dist[id],dodge[id]);
	show_menu(id,(1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9),menuBody,13,"Select Skill");
}

// show the increment menu
public SCXPMIncrementMenu( id ) {
	new menuBody[1024];
	if (skillpoints[id] >= 20 && skillpoints[id] < 50) {
		format(menuBody,1023,"Increment your skill with^n^n1.    1  point^n2.    5  points^n3.    10 points^n4.    25 points");
	}
	else if (skillpoints[id] >= 50 && skillpoints[id] < 100) {
		format(menuBody,1023,"Increment your skill with^n^n1.    1  point^n2.    5  points^n3.    10 points^n4.    25 points^n5.    50 points");
	}
	else if (skillpoints[id] >= 100) {
		format(menuBody,1023,"Increment your skill with^n^n1.    1  point^n2.    5  points^n3.    10 points^n4.    25 points^n5.    50 points^n6.    100 points");
	}
	show_menu(id,(1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5),menuBody,13,"Select Increment");
}

public SCXPMIncrementChoice( id, key ) {
	switch(key){
		case 0: {
			skillIncrement[id] = 1;
		}
		case 1: {
			skillIncrement[id] = 5;
		}
		case 2: {
			skillIncrement[id] = 10;
		}
		case 3: {
			skillIncrement[id] = 25;
		}
		case 4: {
			skillIncrement[id] = 50;
		}
		case 5: {
			skillIncrement[id] = 100;
		}
	}
	SCXPMSkillMenu( id );
}
// choose a skill
public SCXPMSkillChoice( id, key ) {
	switch(key)
	{
		case 0:
		{
			if(skillpoints[id]>0)
			{
				if(health[id]<450)
				{
					if (skillIncrement[id] + health[id] >= 450) {
						skillIncrement[id] = 450 - health[id];
					}
					skillpoints[id] -= skillIncrement[id];
					health[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoints to enhance your Strength to Level %i!",skillIncrement[id],health[id]);
					if(is_user_alive(id))
					{
						set_user_health(id, get_user_health(id) + skillIncrement[id]);
					}
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Strength already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id);
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Strength.")
			}
		}
		case 1:
		{
			if(skillpoints[id]>0)
			{
				if(armor[id]<450)
				{
					if (skillIncrement[id] + armor[id] >= 450) {
						skillIncrement[id] = 450 - armor[id];
					}
					
					skillpoints[id]-= skillIncrement[id];
					armor[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoints to enhance your Armor to Level %i!",skillIncrement[id],armor[id]);
					if(is_user_alive(id))
					{
						set_user_armor(id,get_user_armor(id)+skillIncrement[id]);
					}
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Armor already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Armor.")
			}
		}
		case 2:
		{
			if(skillpoints[id]>0)
			{
				if(rhealth[id]<300)
				{
					if (skillIncrement[id] + rhealth[id] >= 300) {
						skillIncrement[id] = 300 - rhealth[id];
					}
					
					skillpoints[id] -= skillIncrement[id];
					rhealth[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoints to enhance your Regeneration to Level %i!",skillIncrement[id],rhealth[id])
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Regeneration already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Regeneration.")
			}
		}
		case 3:
		{
			if(skillpoints[id]>0)
			{
				if(rarmor[id]<300)
				{
					if (skillIncrement[id] + rarmor[id] >= 300) {
						skillIncrement[id] = 300 - rarmor[id];
					}
					
					skillpoints[id] -= skillIncrement[id];
					rarmor[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoint to enhance your Nano Armor to Level %i!",skillIncrement[id],rarmor[id]);
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Nano Armor already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Nano Armor.")
			}
		}
		case 4:
		{
			if(skillpoints[id]>0)
			{
				if(rammo[id]<30)
				{
					if (skillIncrement[id] + rammo[id] >= 30) {
						skillIncrement[id] = 30 - rammo[id];
					}
					
					skillpoints[id] -= skillIncrement[id];
					rammo[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoints to enhance your Ammo Reincarnation to Level %i!",skillIncrement[id],rammo[id]);
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Ammo Reincarnation already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Ammo Reincarnation.")
			}
		}
		case 5:
		{
			if(skillpoints[id]>0)
			{
				if(gravity[id]<40)
				{
					if (skillIncrement[id] + gravity[id] >= 40) {
						skillIncrement[id] = 40 - gravity[id];
					}
					
					skillpoints[id] -= skillIncrement[id];
					gravity[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoints to enhance your Anti Gravity Device to Level %i!",skillIncrement[id],gravity[id]);
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Anti Gravity Device already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Anti Gravity Device.")
			}
		}
		case 6:
		{
			if(skillpoints[id]>0)
			{
				if(speed[id]<80)
				{
					if (skillIncrement[id] + speed[id] >= 80) {
						skillIncrement[id] = 80 - speed[id];
					}
					
					skillpoints[id] -= skillIncrement[id];
					speed[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoints to enhance your Awareness to Level %i!",skillIncrement[id],speed[id])
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Awareness already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Awareness.")
			}
		}
		case 7:
		{
			if(skillpoints[id]>0)
			{
				if(dist[id]<60)
				{
					if (skillIncrement[id] + dist[id] >= 60) {
						skillIncrement[id] = 60 - dist[id];
					}
					
					skillpoints[id] -= skillIncrement[id];
					dist[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoints to enhance your Team Power to Level %i!",skillIncrement[id],dist[id])
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Team Power already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Team Power.")
			}
		}
		case 8:
		{
			if(skillpoints[id]>0)
			{
				if(dodge[id]<90)
				{
					if (skillIncrement[id] + dodge[id] >= 90) {
						skillIncrement[id] = 90 - dodge[id];
					}
					
					skillpoints[id] -= skillIncrement[id];
					dodge[id] += skillIncrement[id];
					client_print(id,print_chat,"[Monster Mod] You spent %i Skillpoint to enhance your Dodging and Blocking Skills to Level %i!",skillIncrement[id],dodge[id]);
				}
				else
				{
					client_print(id,print_chat,"[Monster Mod] You have mastered your Dodging and Blocking Skills already.")
				}
				if(skillpoints[id]>0)
				{
					SCXPMSkill(id)
				}
			}
			else
			{
				client_print(id,print_chat,"[Monster Mod] You need one Skillpoint for enhancing your Dodgin and Blocking Skills.")
			}
		}
		case 9:
		{
			
		}
	}
	return PLUGIN_HANDLED;
}

//
// save and load
//

// load player data
public LoadPlayerData( id ) {
	if (plugin_ended == false) {
		if ( get_cvar_num( "scxpm_debug" ) == 1 )
		{
			new nickname[35];
			get_user_name( id, nickname, 34 );
			log_amx( "[SCXPM DEBUG] Loading data for: %s", nickname );
		}
		// 0 = no saved data
		if ( get_cvar_num( "scxpm_save" ) <= 0 )
		{
			LoadEmptySkills( id );
		}
		else {
			// 1 = load from file
			if ( get_cvar_num( "scxpm_save" ) == 1 )
			{
				scxpm_loadxp_file( id );
			}
			else {
				// 2 = load from mysql
				if ( get_cvar_num( "scxpm_save" ) >= 2 )
				{
					if ( !dbc ) {
						sql_init();
					}
					scxpm_loadxp_mysql( id );
				}
				else {
					if ( get_cvar_num( "scxpm_debug" ) == 1 )
					{
						new nickname[35];
						get_user_name( id, nickname, 34 );
						log_amx( "[SCXPM DEBUG] Data already loaded, don't load data for: %s", nickname );
					}
				}
			}
		}
	}
	else {
		if ( get_cvar_num( "scxpm_debug" ) == 1 )
		{
			log_amx( "[SCXPM DEBUG] Plugin already ended, don't load data" );
		}
	}
}

// save player data
public SavePlayerData( id ) {
	if ( get_cvar_num( "scxpm_save" ) == 0 ) {
		// No need to save data
		return PLUGIN_CONTINUE;
	}
	
	if (plugin_ended == false) {
		if (loaddata[id] == true) {
			if (xp[id] >= 0) {
				//loaddata[id] = false;
				if ( get_cvar_num("scxpm_debug") == 1 )
				{
					new nickname[35];
					get_user_name( id, nickname, 34 );
					log_amx( "[SCXPM DEBUG] Saving data for: %s", nickname ); 
				}
				// 0 = will not be saved
				
				// 1 = save to file
				if ( get_cvar_num( "scxpm_save" ) == 1 )
				{
					scxpm_savexp_file( id );
				}
				
				// 2 = save to mysql
				if ( get_cvar_num( "scxpm_save" ) >= 2 )
				{
					if ( !dbc ) {
						sql_init();
					}
					scxpm_savexp_mysql( id );
				}
			}
			else {
				if ( get_cvar_num( "scxpm_debug" ) == 1 )
				{
					new nickname[35];
					get_user_name( id, nickname, 34 );
					log_amx( "[SCXPM DEBUG] xp lower than 0, don't save data for: %s", nickname );
				}
			}
		}
		else {
			if ( get_cvar_num( "scxpm_debug" ) == 1 )
			{
				new nickname[35];
				get_user_name( id, nickname, 34 );
				log_amx( "[SCXPM DEBUG] Data not loaded, don't save data for: %s", nickname );
			}
		}
	}
	else {
		if ( get_cvar_num( "scxpm_debug" ) == 1 )
		{
			log_amx( "[SCXPM DEBUG] Plugin already ended, don't save data" );
		}
	}
	return PLUGIN_CONTINUE;
}

// load player data from file
public scxpm_loadxp_file( id ) {
	new authid[35]
	if (get_cvar_num("scxpm_savestyle") == 0)
	{
		get_user_authid(id, authid, 34)
		if ( containi(authid,"STEAM_ID_PENDING") !=-1 )
		{
			LoadEmptySkills( id )
			return PLUGIN_CONTINUE;
		}
	}
	if (get_cvar_num("scxpm_savestyle") == 1)
	{
		get_user_ip(id, authid, 34, 1)
	}
	if (get_cvar_num("scxpm_savestyle") == 2)
	{
		get_user_name(id, authid, 34)
	}
	
	new vaultkey[64], vaultdata[96];
	format(vaultkey,63,"%s-scxpm",authid);
	if ( vaultdata_exists(vaultkey) )
	{
		get_vaultdata(vaultkey,vaultdata,95);
		replace_all(vaultdata,95,"#"," ");
		new pre_xp[16],pre_playerlevel[8],pre_skillpoints[8],pre_medals[8],pre_health[8],pre_armor[8],pre_rhealth[8],pre_rarmor[8],pre_rammo[8],pre_gravity[8],pre_speed[8],pre_dist[8],pre_dodge[8];
		parse(vaultdata,pre_xp,15,pre_playerlevel,7,pre_skillpoints,7,pre_medals,7,pre_health,7,pre_armor,7,pre_rhealth,7,pre_rarmor,7,pre_rammo,7,pre_gravity,7,pre_speed,7,pre_dist,7,pre_dodge,7);
		xp[id] = str_to_num(pre_xp);
		playerlevel[id] = str_to_num(pre_playerlevel);
		scxpm_calcneedxp(id);
		scxpm_getrank(id);
		skillpoints[id] = str_to_num(pre_skillpoints);
		medals[id] = str_to_num(pre_medals);
		health[id] = str_to_num(pre_health);
		armor[id] = str_to_num(pre_armor);
		rhealth[id] = str_to_num(pre_rhealth);
		rarmor[id] = str_to_num(pre_rarmor);
		rammo[id] = str_to_num(pre_rammo);
		gravity[id] = str_to_num(pre_gravity);
		speed[id] = str_to_num(pre_speed);
		dist[id] = str_to_num(pre_dist);
		dodge[id] = str_to_num(pre_dodge);
	}
	else
	{
		log_amx("[Monster Mod] Start from level 0");
		LoadEmptySkills( id );
	}
	loaddata[id] = true;
	return PLUGIN_CONTINUE;
}

// save player data to file
public scxpm_savexp_file( id ) {
	new authid[35]
	if ( get_cvar_num("scxpm_savestyle") == 0 )
	{
		get_user_authid( id, authid, 34 );
		if ( containi(authid,"STEAM_ID_PENDING") !=-1 )
		{
			return PLUGIN_CONTINUE;
		}
	}
	if ( get_cvar_num("scxpm_savestyle") == 1 )
	{
		get_user_ip( id, authid, 34, 1 );
	}
	if ( get_cvar_num("scxpm_savestyle") == 2 )
	{
		get_user_name( id, authid, 34 );
	}
	new vaultkey[64],vaultdata[96];
	format( vaultkey, 63, "%s-scxpm", authid );
	format( vaultdata, 95, "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i",xp[id],playerlevel[id],skillpoints[id],medals[id],health[id],armor[id],rhealth[id],rarmor[id],rammo[id],gravity[id],speed[id],dist[id],dodge[id]);
	set_vaultdata( vaultkey, vaultdata );
	return PLUGIN_CONTINUE;
}

// save player data to a database
public scxpm_savexp_mysql( id ) {
	if ( load_error[ id ] )
	{
		new nickname[35];
		get_user_name(id, nickname, 34 );
		log_amx("[Monster Mod] There was an error on loading so stats won't be saved for: %s", nickname )
		return PLUGIN_CONTINUE;
	}
	
	new authid[35];
	new ip[35];
	new nickname[128];
	new where_statement[1024];
	
	get_user_authid(id, authid, 34);
	get_user_ip(id, ip, 199, 1);
	get_user_name(id, nickname, 63);
	
	if ( equali(ip, "") || equali(nickname, "") ) {
		if ( get_cvar_num( "scxpm_debug" ) == 1 )
		{
			log_amx( "[SCXPM DEBUG] Empty ip or nickname, don't save data." );
		}
		return PLUGIN_CONTINUE;
	}
	
	replace_all(nickname,127,"'","\'"); //avoiding sql errors with ' in name
	
	if ( get_cvar_num("scxpm_savestyle") == 0 )
	{
		if ( containi(authid,"STEAM_ID_PENDING") !=-1 || equali(authid, "") )
		{
			if ( get_cvar_num( "scxpm_debug" ) == 1 )
			{
				log_amx( "[SCXPM DEBUG] Empty or invalid steamid, don't save data." );
			}
			return PLUGIN_CONTINUE;
		}
		formatex( g_Cache, 1023, QUERY_UPDATE_SKILLS, sql_table, authid, authid, nickname, ip, xp[id], playerlevel[id], skillpoints[id], medals[id], health[id], armor[id], rhealth[id], rarmor[id], rammo[id], gravity[id], speed[id], dist[id], dodge[id], where_statement );
	}
	if ( get_cvar_num( "scxpm_savestyle" ) == 1 )
	{
		formatex( g_Cache, 1023, QUERY_UPDATE_SKILLS, sql_table, ip, authid, nickname, ip, xp[id], playerlevel[id], skillpoints[id], medals[id], health[id], armor[id], rhealth[id], rarmor[id], rammo[id], gravity[id], speed[id], dist[id], dodge[id], where_statement );
	}
	if ( get_cvar_num("scxpm_savestyle") == 2 )
	{
		formatex( g_Cache, 1023, QUERY_UPDATE_SKILLS, sql_table, nickname, authid, nickname, ip, xp[id], playerlevel[id], skillpoints[id], medals[id], health[id], armor[id], rhealth[id], rarmor[id], rammo[id], gravity[id], speed[id], dist[id], dodge[id], where_statement );
	}
	
	SQL_ThreadQuery( dbc, "QueryHandle", g_Cache );
	return PLUGIN_CONTINUE;
}

// load player data from a database
public scxpm_loadxp_mysql( id ) {
	if (get_cvar_num("scxpm_debug") == 1)
	{
		log_amx( "[SCXPM DEBUG] Entered public scxpm_loadxp_mysql( id )" );
	}
	
	if ( load_error[ id ] )
	{
		new nickname[35]
		get_user_name(id, nickname, 34 )
		log_amx("[Monster Mod] There was an error on loading so stats won't be loaded anymore for: %s", nickname )
		return 0;
	}
	
	
	new where_statement[1024];
	new authid[35];
	new ip[35];
	new nickname[128];
	
	get_user_authid( id, authid, 34 );
	get_user_ip( id, ip, 199, 1 );
	get_user_name( id, nickname, 63 );
	
	replace_all(nickname,127,"'","\'"); //avoiding sql errors with ' in name
		
	if ( get_cvar_num("scxpm_savestyle") == 0 )
	{
		if ( containi(authid,"STEAM_ID_PENDING") !=-1 || equali(authid, "") )
		{
			LoadEmptySkills( id );
			return PLUGIN_CONTINUE;
		}
		format(where_statement, 199, "`uniqueid` = '%s'", authid);
	}
	else if ( get_cvar_num("scxpm_savestyle") == 1 )
	{
		format(where_statement, 49, "`uniqueid` = '%s'", ip);
	}
	else if ( get_cvar_num("scxpm_savestyle") == 2 )
	{
		format(where_statement, 199, "`uniqueid` = '%s'", nickname);
	}
	
	formatex( g_Cache, 1023, QUERY_SELECT_SKILLS, sql_table, where_statement);
	
	new send_id[1];
	send_id[0] = id;
	
	SQL_ThreadQuery( dbc, "LoadDataHandle", g_Cache, send_id, 1 );
	return PLUGIN_CONTINUE;
}

//
// sql handles
//

// handle default queries
public QueryHandle( FailState, Handle:Query, Error[], Errcode, Data[], DataSize ) {
	if (get_cvar_num( "scxpm_debug") == 1 )	{
		log_amx( "[SCXPM DEBUG] Begin QueryHandle" );
		new sql[1024];
		SQL_GetQueryString ( Query, sql, 1024 );
		log_amx( "[SCXPM DEBUG] executed query: %s", sql );
	}
	
	// lots of error checking
	if ( FailState == TQUERY_CONNECT_FAILED ) {
		log_amx( "[SCXPM SQL] Could not connect to SQL database." );
		return set_fail_state("[SCXPM SQL] Could not connect to SQL database.");
	}
	else if ( FailState == TQUERY_QUERY_FAILED ) {
		new sql[1024];
		SQL_GetQueryString ( Query, sql, 1024 );
		log_amx( "[SCXPM SQL] SQL Query failed: %s", sql );
		return set_fail_state("[SCXPM SQL] SQL Query failed.");
	}
	
	if ( Errcode ) {
		return log_amx( "[SCXPM SQL] SQL Error on query: %s", Error );
	}
	
	if (get_cvar_num( "scxpm_debug") == 1 )	{
		log_amx( "[SCXPM DEBUG] End QueryHandle" );
	}
	return PLUGIN_CONTINUE;
}

// check if table exist
public ShowTableHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) {
	if (get_cvar_num("scxpm_debug")==1) {
		log_amx("[SCXPM DEBUG] Begin ShowTableHandle");
		new sql[1024];
		SQL_GetQueryString ( Query, sql, 1024 );
		log_amx( "[SCXPM DEBUG] executed query: %s", sql );
	}
	
	if(FailState==TQUERY_CONNECT_FAILED){
		log_amx( "[SCXPM SQL] Could not connect to SQL database." );
		log_amx( "[SCXPM SQL] Switching to: scxpm_save 0" );
		log_amx( "[SCXPM SQL] Stats won't be saved" );
		set_cvar_num ( "scxpm_save", 0 );
		return PLUGIN_CONTINUE;
	}
	else if (FailState == TQUERY_QUERY_FAILED) {
		log_amx( "[SCXPM SQL] Query failed." );
		log_amx( "[SCXPM SQL] Switching to: scxpm_save 0" );
		log_amx( "[SCXPM SQL] Stats won't be saved" );
		set_cvar_num ( "scxpm_save", 0 );
		return PLUGIN_CONTINUE;
	}
   
	if (Errcode) {
		log_amx( "[SCXPM SQL] Error on query: %s", Error );
		log_amx( "[SCXPM SQL] Switching to: scxpm_save 0" );
		log_amx( "[SCXPM SQL] Stats won't be saved" );
		set_cvar_num ( "scxpm_save", 0 );
		return PLUGIN_CONTINUE;
	}
   
	if (SQL_NumResults(Query) > 0) {
		if (get_cvar_num( "scxpm_debug") == 1 )
		{
			log_amx( "[SCXPM DEBUG] Database table found: %s", sql_table );
		}
	}
	else {
		log_amx( "[SCXPM SQL] Could not find the table: %s", sql_table );
		log_amx( "[SCXPM SQL] Switching to: scxpm_save 0" );
		log_amx( "[SCXPM SQL] Stats won't be saved" );
		set_cvar_num ( "scxpm_save", 0 );
	}
	
	if (get_cvar_num( "scxpm_debug") == 1 )
	{
		log_amx( "[SCXPM DEBUG] End ShowTableHandle" );
	}
	return PLUGIN_CONTINUE;
}

// load player data
public LoadDataHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) {
	if (get_cvar_num( "scxpm_debug") == 1 )
	{
		log_amx( "[SCXPM DEBUG] Begin LoadDataHandle" );
		new sql[1024];
		SQL_GetQueryString ( Query, sql, 1024 );
		log_amx( "[SCXPM DEBUG] executed query: %s", sql );
	}
	if (FailState == TQUERY_CONNECT_FAILED) 
	{
        return set_fail_state("Could not connect to SQL database.")
	}
	else if (FailState == TQUERY_QUERY_FAILED) {
        return set_fail_state("Query failed.")
	}
   
	if (Errcode) {
        return log_amx("Error on query: %s",Error)
	}
	
	loaddata[Data[0]] = true;
   
	if (SQL_NumResults(Query) >= 1) 
	{
		if (SQL_NumResults(Query) > 1) {
			if (get_cvar_num( "scxpm_debug") == 1 ) {
				log_amx( "[SCXPM DEBUG] more than one entry found. just take the first one" );
			}
		}
		xp[Data[0]] = SQL_ReadResult(Query, 0) ;
		playerlevel[Data[0]] = SQL_ReadResult(Query, 1);
		scxpm_calcneedxp( Data[0] );
		scxpm_getrank( Data[0] );
		skillpoints[Data[0]] = SQL_ReadResult( Query, 2 );
		medals[Data[0]] = SQL_ReadResult(Query, 3);
		health[Data[0]] = SQL_ReadResult(Query, 4);
		armor[Data[0]] = SQL_ReadResult(Query, 5);
		rhealth[Data[0]] = SQL_ReadResult(Query, 6); 
		rarmor[Data[0]] = SQL_ReadResult(Query, 7);
		rammo[Data[0]] = SQL_ReadResult(Query, 8);
		gravity[Data[0]] = SQL_ReadResult(Query, 9); 
		speed[Data[0]] = SQL_ReadResult(Query, 10);
		dist[Data[0]] = SQL_ReadResult(Query, 11);
		dodge[Data[0]] = SQL_ReadResult(Query, 12);
	}
	else if (SQL_NumResults(Query) < 1) {
		// load empty skills, the skills will be saved later on
		LoadEmptySkills( Data[0] );
	}
	
	if (get_cvar_num("scxpm_debug")== 1)
	{
		log_amx( "[SCXPM DEBUG] End LoadDataHandle" );
	}
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
