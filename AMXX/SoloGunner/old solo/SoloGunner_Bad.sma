/* same as Dubai Play time Solo gunner mod.
you can find desription about this mod
Here: http://www.dubaiplaytime.com/sgm.php
*/

#include <amxmodx>	// Every thing else
#include <amxmisc>	// checking flag
#include <cstrike>	// Setting user models
#include <fun>		// Item giver && stripper
#include <fakemeta>	// For buy block
#include <hamsandwich>	// Block weapon pickup
#include <sqlx>		// OTHERS
#include <played_time>

//#define host "127.0.0.1"	// These must be exactly as the
//#define user "root"		// Played time plugin
//#define pass ""			// which means (NO DIFFERENCE 
//#define db "amxx"		// AT ALL)

// *** Plugin registering info ***
#define PLUGIN "Solo Gunner Mode"
#define VERSION "2.5"
#define AUTHOR "Khalid :)"

// *** Admin/Silver/Golden Flags ***
#define ADMIN ADMIN_BAN
#define GOLDEN ADMIN_LEVEL_H
#define SILVER ADMIN_LEVEL_G
// Final Flag
#define FLAGS (ADMIN|GOLDEN|SILVER)

// *** Solo gunner ***

//#define WITH_MAKE		// Only use for testing ..

// Solo gunner MDL
//new const SoloMDL[] = "models/player/vip/vip.mdl"	
// Solo bools
new bool:issolo[33]		// Is the solo gunner a solo?
new bool:solorun		// Is it a soloround?
new bool:gsolo_Killed_bdis = false	// Solo gunner got killed before disconnecting
// Solo ID's
new soloid//, g_lastid
// Solo Cvars Pointers
new g_soloammo			// USP ammo
new g_Bkill, g_Bkiller		// Bonusses
new g_Dkilled, g_Ddisconnect	// Decreses
new g_Dsuicide
new g_MinPlayers

// *** Weapon Changing thing ***
new g_curwep			

// *** SQL THINGS ***
new Handle:sql, g_query[512]//, selectquery[50]
//new chost[64], cuser[64], cpass[64], cdb[64]
//new phost[30], puser[30], ppass[30], pdb[10]

// *** Block buy things ***
new bool:gBlockBuyZone;
new gMsgStatusIcon;

// *** Weapon pickup block ***
new g_iMaxPlayers

// *** HUD Messages
//new gSyncHud//, gSyncHud2

#define TSILVER 2	// how many times silver player can activate solo
#define TGOLDEN 3
#define TADMIN 4
#define SILV 1
#define GOLD 2
#define LADMIN 3

new times[33],acc[33],day

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("amx_solo", "admin_solo", FLAGS)
	register_event("DeathMsg", "fw_death", "a")
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")
	register_event("CurWeapon", "eCurWeapon", "be")
	#if defined WITH_MAKE
	register_concmd("amx_makesolo", "admin_make_solo", ADMIN_IMMUNITY, "<name> - Starts Solo mode and make that player as SoloGunner")
	#endif
	g_curwep = get_user_msgid("CurWeapon")
	
	// ************ Cvars *************************************
	// Ammo
	g_soloammo = register_cvar("amx_solo_ammo", "26")
	// Increment
	g_Bkill = register_cvar("amx_solo_bkill", "5")		// Bonus Per kill (for the solo gunner)
	g_Bkiller = register_cvar("amx_solo_bkiller", "100")
	// Decrement
	g_Ddisconnect = register_cvar("amx_solo_ddisconnect", "350")
	g_Dkilled = register_cvar("amx_solo_dkilled", "350")
	g_Dsuicide = register_cvar("amx_solo_dsuicide", "350")
	
	// Minimum Players
	g_MinPlayers = register_cvar("amx_solo_min_players", "1")
	
	// ************ No weapon drop ****************************
	register_clcmd("drop", "hook_drop")
	
	/* ************ Weapon pickup block - By Exolent ********** */
	g_iMaxPlayers = get_maxplayers()
	RegisterHam( Ham_Touch, "armoury_entity", "FwdHamPlayerPickup" );
	RegisterHam( Ham_Touch, "weaponbox", "FwdHamPlayerPickup" );
	
	/* ************ Buy block code - By Exolent *************** */
	// Grab StatusIcon message ID
	gMsgStatusIcon = get_user_msgid("StatusIcon");
	// Hook StatusIcon message
	register_message(gMsgStatusIcon, "MessageStatusIcon");
	
	//gSyncHud = CreateHudSyncObj()
	//gSyncHud2 = CreateHudSyncObj()
	
	server_cmd(";echo *** SoloGunner mode has been loaded successfully!")
	server_cmd(";echo *** Contact me on my steam account incase of any problem ( My account is: pokemonmaster199714)")
}

public plugin_cfg()
{
	new sday[6]
	get_time("%d",sday,5)
	day = str_to_num(sday)
	
	//get_cvar_string("amx_sql_host", chost, 63)
	//get_cvar_string("amx_sql_user", cuser, 63)
	//get_cvar_string("amx_sql_pass", cpass, 63)
	//get_cvar_string("amx_sql_db", cdb, 63)
	
	//sql = SQL_MakeDbTuple(chost,cuser,cpass,cdb)
	sql = SQL_MakeStdTuple()
	formatex(g_query,511,"CREATE TABLE IF NOT EXISTS `played_time` (name VARCHAR(32), playedtime INT, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)")
	SQL_ThreadQuery(sql, "query", g_query)
	
	formatex(g_query, 511, "CREATE TABLE IF NOT EXISTS `solo_times` (name VARCHAR(32), times INT, day INT)")
	SQL_ThreadQuery(sql, "query", g_query)
	
	formatex(g_query,511,"DELETE FROM `solo_times` WHERE day!='%d'",day)
	SQL_ThreadQuery(sql,"query",g_query)
}

public client_putinserver(id){
	new name[32],Data[1]
	Data[0]=id
	get_user_name(id,name,31)
	
	if(get_user_flags(id) & ADMIN_LEVEL_G)
	{
		
		acc[id]=SILV
		
		formatex(g_query,511,"SELECT times FROM `solo_times` WHERE name='%s'",name)
		SQL_ThreadQuery(sql,"loadtimes",g_query,Data,1)
	}
	else if(get_user_flags(id) & ADMIN_LEVEL_H)
	{
		formatex(g_query,511,"SELECT times FROM `solo_times` WHERE name='%s'",name)
		SQL_ThreadQuery(sql,"loadtimes",g_query,Data,1)
		acc[id]=GOLD
	}
	
	else if(get_user_flags(id) & ADMIN)
	{
		formatex(g_query,511,"SELECT times FROM `solo_times` WHERE name='%s'",name)
		SQL_ThreadQuery(sql,"loadtimes",g_query,Data,1)
		acc[id]=LADMIN
	}
}

/*public plugin_precache()
{
precache_model(SoloMDL)
}*/

public admin_solo(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	else 
	{
		if(solorun == true)
		{
			console_print(id, "*** The mode is already activated!")
			return PLUGIN_HANDLED
		}
		
		if(!is_user_alive(id))
		{
			console_print(id, "*** You can't activate when you are dead.")
			return PLUGIN_HANDLED
		}
		
		new all = allow_change(id)
		
		if(!all)
		{
			console_print(id,"*** You have reached limit of activating Solo Gunner.")
			return PLUGIN_HANDLED
		}
		
		new num = get_playersnum()
		
		if( num < get_pcvar_num(g_MinPlayers) )
		{
			console_print(id, "You can't activate solo mode when there is %s player%s.", num, (num == 0 ? "s" : "") )
			return PLUGIN_HANDLED
		}
		
		add_time(id)
		
		new players[32], count, player
		get_players(players, count, "a")
		
		soloid = id
		
		/*while(soloid == g_lastid)
		{
			soloid = players[random(count)]
		}*/
	
		for(new i; i<count; i++)
		{
			player = players[i]
			strip_user_weapons(player)
			if(player == soloid)
			{
				give_item(player, "weapon_usp")
				give_item(player, "weapon_knife")
				engclient_cmd(player, "weapon_usp")
				cs_set_user_bpammo(soloid, CSW_USP, get_pcvar_num(g_soloammo))
				cs_set_user_model(soloid, "vip")
			}
			
			else
			{
				give_item(player, "weapon_knife")
				engclient_cmd(player, "weapon_knife")
			}
		}	
	
	
		new name2[32]//, name[32]
		
		//get_user_name(soloid, name, 31)		// Solo Name
		get_user_name(id, name2, 31)		// Admin/Silver/Golden name
		
		console_print(id, "*** You have started SoloGunner Mode!")
		
		client_print(0, print_chat, "*** SoloGunner is activated by %s.", name2)
		
		/*if(get_user_flags(id) & SILVER)
		client_print(0, print_chat, "SILVER PLAYER: %s Has activated the SoloGunner mode! The Sologunner is: %s", name2, name)
		
		else if(get_user_flags(id) & ADMIN)	
			client_print(0, print_chat, "ADMIN: %s Has activated the SoloGunner mode! The Sologunner is: %s", name2, name)
		
		else if(get_user_flags(id) & GOLDEN)
			client_print(0, print_chat, "GOLDEN PLAYER: %s Has activated the SoloGunner mode! The Sologunner is: %s", name2, name)
		*/
		
		client_print(0, print_chat, "*** Everyone will be able to carry knife.")
		client_print(0, print_chat, "*** Next round everything will be back to normal.")
		
		client_print(soloid, print_chat, "*** You have activated SoloGunner!")
		client_print(soloid, print_chat, "*** On each kill you make you will be rewarded with %d minutes.", get_pcvar_num(g_Bkill))
		issolo[soloid] = true
		//g_lastid = soloid
		solorun = true
		gsolo_Killed_bdis = false
		
		BlockBuyZones()
		
		new Flag[15], Flags
		
		Flags = get_user_flags(id)
		
		if( Flags & ADMIN )
			copy(Flag, 14, "Administrator")
		if( Flags & GOLDEN )
			copy(Flag, 14,  "Golden Player")
		if( Flags & SILVER )
			copy(Flag, 14, "Silver Player")
		
		set_task(0.1, "bullets_handle", soloid, Flag, 14, "b")
		
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
	//}
	//return PLUGIN_HANDLED
}

allow_change(id){
	if( acc[id] == SILV && times[id] < TSILVER )
		return 1
	if( acc[id] == GOLD && times[id] < TGOLDEN )
		return 1
	if( get_user_flags(id) & ADMIN && acc[id] == LADMIN && times[id] < TADMIN )
		return 2
	
	return 0
}

public loadtimes(FailState, Handle:Query, Error[], Errcode,Data[],DataSize){
	new id = Data[0]
	
	if(!SQL_MoreResults(Query)){
		new name[32]
		
		get_user_name(id,name,31)
		
		replace_all(name,32,"'","")
		replace_all(name,32,"^"","")
		
		formatex(g_query,511,"INSERT INTO `solo_times`(name, times, day) VALUES('%s',0,'%d')",name,day)
		SQL_ThreadQuery(sql,"query",g_query)
		
		times[id]=0
		
		return PLUGIN_HANDLED
	}
	
	times[id] = SQL_ReadResult(Query,0)
	return PLUGIN_HANDLED
}

public add_time(id)
{
	new name[32]
	get_user_name(id, name, 32)
	formatex(g_query, 511, "UPDATE solo_times SET times=times+1 WHERE name='%s'", name)
	SQL_ThreadQuery(sql, "query", g_query)
	times[id]++
	return PLUGIN_CONTINUE
}


#if defined WITH_MAKE
public admin_make_solo(id, level, cid)
{
	//public make_solo(id, level, cid)
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	if(solorun == true)
	{
		console_print(id, "The mode is already activated")
		return PLUGIN_HANDLED
	}
	
	else
	{
		new Arg[32]
		read_argv(1, Arg, charsmax(Arg))
		soloid = cmd_target(id, Arg, 2)
		
		if(!is_user_alive(soloid))
			return PLUGIN_HANDLED
		
		new players[32], count
		get_players(players, count, "a")
		
		if(soloid == g_lastid)
		{
			console_print(id, "You can't make the same player as a SoloGunner twice in a row!")
			return PLUGIN_HANDLED
		}
		
		new player, name[32]
		for(new i; i<count; i++)
		{	
			player = players[i]
			strip_user_weapons(player)
			if(player == soloid)
			{
				give_item(player, "weapon_usp")
				give_item(player, "weapon_knife")
				engclient_cmd(player, "weapon_usp")
				cs_set_user_model(player, "vip")
			}
			else 
			{
				give_item(player, "weapon_knife")
				engclient_cmd(player, "weapon_knife")
			}
		}
		
		cs_set_user_bpammo(soloid, CSW_USP, get_pcvar_num(g_soloammo))
		
		get_user_name(soloid, name, 31)
		console_print(id, "You have started SoloGunner Mode")
		client_print(0, print_chat, "*** SoloGunner Mode has been started! The Sologunner is: %s", name)
		client_print(soloid, print_chat, "*** You are the SoloGunner!")
		client_print(soloid, print_chat, "*** On each kill you make you will be rewarded with %d minutes.", get_pcvar_num(g_Bkill))
		
		issolo[soloid] = true
		g_lastid = soloid
		solorun = true
		gsolo_Killed_bdis = false
		BlockBuyZones()
		set_task(0.3, "bullets_handle", soloid, Flags, 14)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
}
#endif

public eNewRound()
{
	if(solorun == true)
	{
		UnblockBuyZones()
		
		/*new players[32], count, player
		get_players(players, count)
		new i
		for(i = 1;i < 33; i++)
		{
			player = players[i]
			if(issolo[player] == true)
			{
				cs_reset_user_model(player)
				issolo[player] = false
			}
			//issolo[i] = false
			//cs_reset_user_model()
		}*/
		
		cs_reset_user_model(soloid)
		
		issolo[soloid] = false
		solorun = false
		gsolo_Killed_bdis = false
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}

public eCurWeapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if(solorun == false)
		return PLUGIN_HANDLED
	
	else
	{
		if (issolo[id] == false && !( (1<<read_data(2) ) & (1<<CSW_KNIFE) ) )
		{
			engclient_cmd(id, "weapon_knife")
			emessage_begin(MSG_ONE,g_curwep,_,id)
			ewrite_byte(1)
			ewrite_byte(CSW_KNIFE)
			ewrite_byte(-1)
			emessage_end()
			return PLUGIN_HANDLED
		}
		
		/*else if(issolo[id] == true && !( (1<<read_data(2) ) & (1<<CSW_USP) ) )
	{
		engclient_cmd(id, "weapon_knife")
		emessage_begin(MSG_ONE,g_curwep,_,id)
		ewrite_byte(1)
		ewrite_byte(CSW_USP)
		ewrite_byte(-1)
		emessage_end()
	}*/
	}
	return PLUGIN_HANDLED
}

public fw_death()
{
	if(solorun == true)
	{
		new Victim, Killer
		Killer = read_data(1)
		Victim = read_data(2)
		
		static sWeapon[16]
		read_data(4, sWeapon, 15)
		
		if(Victim == soloid && Victim != Killer)	// Solo Gunner Got killed and he didn't suicide
		{
			//formatex(selectquery, 255, "USE %s", cdb)
			//SQL_ThreadQuery(sql, "query", selectquery)
			new name[32], name2[32]
			get_user_name(Victim, name, 31)		// Solo Gunner name
			replace_all(name,31,"'","")
			replace_all(name,31,"^"","")
			
			get_user_name(Killer, name2, 31)	// Killer name
			replace_all(name2,31,"'","")
			replace_all(name2,31,"^"","")
			
			new killed_solo[88]
			format(killed_solo, 87, "The SoloGunner was killed!!!^nThe SoloGunner was killed!!!^nThe SoloGunner was killed!!!")
			set_hudmessage(255, 0, 0, -1.0, -1.0,_, 3.0)
			show_hudmessage(0, "%s", killed_solo)
			
			// Solo messages
			client_print(0, print_chat, "*** %d minutes has been taken from %s!", get_pcvar_num(g_Dkilled), name)
			client_print(Victim, print_chat, "*** You have lost %d minutes from your total time.", get_pcvar_num(g_Dkilled))
			formatex(g_query, 511, "UPDATE played_time SET playedtime=playedtime-%d WHERE name='%s'", get_pcvar_num(g_Dkilled) ,name)
			SQL_ThreadQuery(sql,"query",g_query)
			
			// Killer Messages
			client_print(0, print_chat, "*** %d minutes were added to %s", get_pcvar_num(g_Bkiller), name2)
			client_print(Killer, print_chat, "*** %d minutes has been added to you.", get_pcvar_num(g_Bkiller))
			get_pcvar_num(g_Dkilled)
			formatex(g_query,511,"UPDATE played_time SET playedtime=playedtime+%d WHERE name='%s'", get_pcvar_num(g_Bkiller) ,name2)
			SQL_ThreadQuery(sql,"query",g_query)
			
			issolo[Victim]=  false
			//solorun = false			// Ending the round
			gsolo_Killed_bdis = true
			return PLUGIN_HANDLED
		}
		
		if(Killer == soloid && Victim != soloid)		// Solo Gunner has killed someone
		{
			//formatex(selectquery, 255, "USE %s", cdb)
			//SQL_ThreadQuery(sql, "query", selectquery)
			new name[32]
			get_user_name(soloid, name, 31)
			replace_all(name, 31,"'", "")
			replace_all(name, 31, "^"", "")
			
			client_print(0, print_chat, "*** %d minutes has been added to %s", get_pcvar_num(g_Bkill), name)
			formatex(g_query,511,"UPDATE played_time SET playedtime=playedtime+%d WHERE name='%s'", get_pcvar_num(g_Bkill), name)
			SQL_ThreadQuery(sql,"query",g_query)
			
			return PLUGIN_HANDLED
		}
		
		if(Victim == Killer && equal(sWeapon, "world", 5) && Victim == soloid)	// Suicide
		{
			//formatex(selectquery, 255, "USE %s", cdb)
			//SQL_ThreadQuery(sql, "query", selectquery)
			new name[32]
			get_user_name(soloid, name, 31)
			replace_all(name, 31,"'", "")
			replace_all(name, 31, "^"", "")
			
			client_print(0, print_chat, "*** %d minutes has been taken from %s", get_pcvar_num(g_Dsuicide), name)
			formatex(g_query,511,"UPDATE played_time SET playedtime=playedtime-%d WHERE name='%s'", get_pcvar_num(g_Dsuicide), name)
			SQL_ThreadQuery(sql,"query",g_query)
			
			issolo[Victim]=  false
			return PLUGIN_HANDLED
		}
		
		if( !Killer && equal( sWeapon, "world", 5 ) && Victim == soloid ) 		// falled    
		{
			//formatex(selectquery, 255, "USE %s", cdb)
			//SQL_ThreadQuery(sql, "query", selectquery)
			new name[32]
			get_user_name(soloid, name, 31)
			replace_all(name, 31,"'", "")
			replace_all(name, 31, "^"", "")
			
			client_print(0, print_chat, "*** %d minutes has been taken from %s", get_pcvar_num(g_Dsuicide), name)
			formatex(g_query,511,"UPDATE played_time SET playedtime=playedtime-%d WHERE name='%s'", get_pcvar_num(g_Dsuicide), name)
			SQL_ThreadQuery(sql,"query",g_query)
			
			issolo[soloid] =  false
			return PLUGIN_HANDLED
		}
		
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{
	if(solorun == true)
	{
		
		if(id == soloid && gsolo_Killed_bdis == false) 
		{	// Just to prevent collusion between this plugin and played time plugin...
			
			new name[50]
			get_user_name(soloid, name, 49)		// Solo Gunner name
			//replace_all(wow, charsmax(name), "'", "")
			//replace_all(name, charsmax(name), "^"", "")
			
			new itime = get_pcvar_num(g_Ddisconnect)
			
			client_print(0, print_chat, "*** %d minutes has been taken from %s for disconnecting!", itime, name)
			
			server_print("%d", itime)
			
			format(g_query, charsmax(g_query), "UPDATE played_time SET playedtime = playedtime - %i WHERE name = '%s'", itime, name)
			server_print(g_query)	
			times[id] = 0
			//PlayedTime[soloid] = 0
			server_print(g_query)
			//set_task(0.7, "Subtract", soloid, g_query, charsmax(g_query))
			Subtract(g_query)
			soloid = 0
			
			return PLUGIN_CONTINUE
		}
	}
	
	return PLUGIN_HANDLED
}

public bullets_handle(Flag[], soloid)
{
	if(solorun == true && is_user_alive(soloid))
	{
		new weapon = get_user_weapon(soloid,_,_)
		new name[32]//, players[32], count, player
		set_hudmessage(255, 255, 0, -1.0, 0.20, 0, 0.0, 0.1, 0.0, 0.1)
		
		//get_players(players, count)
		
		get_user_name(soloid, name, 31)
		
		if(weapon == CSW_USP)
		{
			new clip, bpclip
			get_user_ammo(soloid, CSW_USP, clip, bpclip)
			//ShowSyncHudMsg(0,gSyncHud, "Solo Gunner is activated by %s %s^nBullets remaining: %d", Flag, name, clip+bpclip)
			show_hudmessage(0, "Solo Gunner is activated by %s %s^nBullets remaining: %d", Flag, name, clip+bpclip)
		}
		
		else if(weapon == CSW_KNIFE)
		{
			//ShowSyncHudMsg(0,gSyncHud, "Solo Gunner is activated by %s %s^nBullets remaining: Hidden", Flag, name)
			show_hudmessage(0, "Solo Gunner is activated by %s %s^nBullets remaining: Hidden", Flag, name)
		}
		//set_task(0.1, "bullets_handle", soloid, Flag, 14)
	}

	else
	{
		remove_task(soloid)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

Subtract(something[])
{
	//formatex(selectquery, 29, "USE %s", cdb)
	//SQL_ThreadQuery(sql, "query", selectquery)
	
	/*new name[50]
	get_user_name(soloid, name, 49)		// Solo Gunner name
	//replace_all(wow, charsmax(name), "'", "")
	//replace_all(name, charsmax(name), "^"", "")
	
	new itime = get_pcvar_num(g_Ddisconnect)
	
	client_print(0, print_chat, "*** %d minutes has been taken from %s for disconnecting!", itime, name)
	
	formatex(something, charsmax(something), "UPDATE played_time SET playedtime = playedtime - %d WHERE name = '%s'", itime, name)*/
	server_print("Subtract function started!")
	server_print(something)
	SQL_ThreadQuery(sql, "query", something)
}

public hook_drop(id)
{
	if(solorun == true)
	{
		new weapon = get_user_weapon(id,_,_)
		if(id == soloid && weapon == CSW_USP)
		{
			return PLUGIN_HANDLED
		}
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public query(FailState, Handle:Query, Error[], Errcode)
{
	if(Errcode)
		return server_print("Error on query: %s", Error)
	return PLUGIN_CONTINUE
}

public plugin_end()
{
	SQL_FreeHandle(sql)
}

/* ******************************* Block weapon pickup - By Exolent ******************************** */
public FwdHamPlayerPickup( iEntity, id )
{
	return ( 1 <= id <= g_iMaxPlayers && solorun && is_user_alive(id) ) ? HAM_SUPERCEDE : HAM_IGNORED
}

/* ******************************* Buy block code - By Exolent ************************************* */
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
