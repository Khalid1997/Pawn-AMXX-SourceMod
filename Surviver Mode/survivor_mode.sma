#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <fakemeta>
#include <engine>

#include <played_time>

new const VERSION[] = "2.5"

enum _:LEVELS
{
	ADMIN,
	GOLDEN,
	SILVER
}

new const g_szLevels[LEVELS][15] = {
	"Administrator",
	"Golden Player",
	"Silver Player"
}

#define LIMITS

#if defined LIMITS
	#include <sqlx>
	#define host "127.0.0.1"
	#define user "root"
	#define pass ""
	#define database "amxx"
	
	new const TABLE_NAME[] = "survivor_uses"
	new g_szQuery[256]
	new g_iUses[33], g_iCurrentDay
	
	#define ADMIN_ACTIVATES 3
	#define GOLDEN_ACTIVATES 2
	#define SILVER_ACTIVATES 1
	
	new g_iActivateLimit[LEVELS] = {
		ADMIN_ACTIVATES,
		GOLDEN_ACTIVATES,
		SILVER_ACTIVATES
	}
#endif

#define FREEZE_TIME 20

#define ADMIN_FLAG ADMIN_BAN
#define SILVER_FLAG ADMIN_LEVEL_G
#define GOLDEN_FLAG ADMIN_LEVEL_H

#define FINAL	(ADMIN_FLAG | SILVER_FLAG | GOLDEN_FLAG)

#define USP_BULLETS 0
#define SURVIVOR_DISCONNECT_TIME 350
#define KILL_TIME 100


#define UPDATE_TIME_HUD 2.5
#define TASKID_HUD 178194

enum SurvivorActions
{
	// Not running
	OFF = 0,
	// Showing menu next round
	READY_UP,
	// Currently selecting players
	SELECTING,
	// Starting the mode next round
	START,
	// Mode is currently running
	RUNNING,
	// Finalizing everything and putting everything to normal
	//FINALIZE // No need
}

enum
{
	ACTIVATOR,
	OTHER
}

new g_iSurvivors[2], g_szSurvivorsNames[2][32], CsTeams:g_iActivatorTeam, g_iCanChoose
new g_iSurvivorsBit

new SurvivorActions:g_iRunning = OFF, g_iOldFreezeTime, CsTeams:g_iTeams[33]
new g_pFreezeTime, g_pMinPlayers

new bool:gBlockBuyZone
new gMsgStatusIcon

new g_iPlayersMenu
new g_iMaxPlayers

new gSyncHud, g_szActivatorLevel[15], g_iCanNotAttack

#if defined LIMITS
new Handle:g_hSql
#endif

#define IsPlayer(%1) (1 <= %1 <= g_iMaxPlayers)

public plugin_init()
{
	register_plugin .plugin_name = "Survivor Mode", .version = VERSION, .author = "Khalid :)";
	
	register_concmd("amx_survivor", "AdminSurvivor", FINAL)
	
	register_clcmd("chooseteam", "ClcmdChooseTeam")
	
	register_message(get_user_msgid("VGUIMenu"), "message_ShowMenu")
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu")
	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Pre", 0)
	
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")
	register_event("DeathMsg", "eDeathMsg", "a")
	register_logevent("RoundStart", 2, "1=Round_Start")
	register_logevent("RoundEnd", 2, "1=Round_End")
	
	register_message( ( gMsgStatusIcon = get_user_msgid("StatusIcon") ), "message_StatusIcon")
	
	register_touch("armoury_entity", "player", "fw_Block")
	register_touch("weaponbox", "player", "fw_Block")
	
	g_pFreezeTime = get_cvar_pointer("mp_freezetime")
	g_pMinPlayers = register_cvar("survivor_min_players", "10")
	
	gSyncHud = CreateHudSyncObj()
	
	g_iMaxPlayers = get_maxplayers()
	
	#if defined LIMITS
	g_hSql = SQL_MakeDbTuple(host, user, pass, database)
	
	if(g_hSql == Empty_Handle)
	{
		set_fail_state("Failed to connect to SQL database.")
		return;
	}
	
	new szDay[5]
	get_time("%j", szDay, charsmax(szDay))
	g_iCurrentDay = str_to_num(szDay)
	
	formatex(g_szQuery, charsmax(g_szQuery), "CREATE TABLE IF NOT EXISTS `%s` ( name VARCHAR(32), uses INT, day INT )", TABLE_NAME)
	SQL_ThreadQuery(g_hSql, "query_handler", g_szQuery)
	
	formatex(g_szQuery, charsmax(g_szQuery), "DELETE FROM %s WHERE day != %d", TABLE_NAME, g_iCurrentDay)
	SQL_ThreadQuery(g_hSql, "query_handler", g_szQuery)
	
	#endif
}

public eDeathMsg()
{
	if(!g_iRunning)
	{
		return;
	}
	
	new iKiller = read_data(1)
	new iVictim = read_data(2)
	
	if(IsPlayer(iKiller) && cs_get_user_team(iVictim) == g_iActivatorTeam && cs_get_user_team(iKiller) != g_iActivatorTeam)
	{
		set_user_playedtime(iKiller, get_user_playedtime(iKiller) + KILL_TIME)
		
		static szName[32]; get_user_name(iKiller, szName, charsmax(szName))
		client_print(0, print_chat, "** %s has killed survivor and is awarded with 100 minutes.", szName)
	}
}

public ClcmdChooseTeam(id)
{
	if(g_iCanChoose)
	{
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	static const iActions = (1<<_:START) | (1<<_:READY_UP) | (1<<_:SELECTING)
	if(_:g_iRunning & iActions)
	{
		if((1<<id)  & g_iSurvivorsBit && is_user_alive(id))
		{
			ResetStuff()
			UnblockBuyZones()
			
			client_print(0, print_chat, "Survivor mode was canceled as one of the survivors disconnected")
		}
	}
	
	else if(g_iRunning == RUNNING && (1<<id) & g_iSurvivorsBit && is_user_alive(id))
	{
		set_user_playedtime(id, get_user_playedtime(id) - SURVIVOR_DISCONNECT_TIME)
		static szName[32]; get_user_name(id, szName, 31)
		
		client_print(id, print_chat, "%d minutes were taken from Survivor %s for disconnecting while the mod was running", SURVIVOR_DISCONNECT_TIME, szName)
	}
	
	if(is_user_admin(id))
	{
		SaveUses(id)
	}
}

public fw_TraceAttack_Pre(iVictim, iAttacker, Float:flDamage, Float:vDirection[3], iResult, damagebits)
{
	if(g_iCanNotAttack)
	{
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

public client_putinserver(id)
{
	// Auto join other team when mode is running
	if(g_iRunning == RUNNING)
	{
		set_task(1.0, "TaskJoinTeam", id)
	}
	
	g_iUses[id] = -1
	
	if(is_user_admin(id))
	{
		g_iUses[id] = GetUses(id)
	}
}

#if defined LIMITS

public client_infochanged(id)
{
	static szNewName[32], szOldName[32]
	get_user_info(id, "name", szNewName, 31)
	get_user_name(id, szOldName, 31)
	
	if(!equal(szNewName, szOldName))
	{
		g_iUses[id] = GetUses(id, szNewName)
	}
}

stock ClearSqlString(szName[], len)
{
	replace_all(szName, len, "'", "")
	replace_all(szName, len, "^"", "")
}

GetUses(id, szName[32] = "", len = 0)
{
	if(!len)
	{
		get_user_name(id, szName, 31)
	}
	
	ClearSqlString(szName, len)
	
	static Handle:hConnect, Handle:hQuery, szError[256], iErrorCode
	
	hConnect = SQL_Connect(g_hSql, iErrorCode, szError, charsmax(szError))
	
	if(iErrorCode)
	{
		log_amx("Error on SQL: %s", szError)
		return -1
	}
	
	hQuery = SQL_PrepareQuery(hConnect, "SELECT uses FROM %s WHERE name = '%s'", TABLE_NAME, szName)
	
	SQL_Execute(hQuery)
	
	if(!SQL_MoreResults(hQuery))
	{
		SQL_FreeHandle(hQuery)
		SQL_FreeHandle(hConnect)
		
		formatex(g_szQuery, charsmax(g_szQuery), "INSERT INTO %s VALUES ( '%s', 0, %d )", TABLE_NAME, szName, g_iCurrentDay)
		SQL_ThreadQuery(g_hSql, "query_handler", g_szQuery)
		
		return 0
	}
	
	iErrorCode =  SQL_ReadResult(hQuery, 0)
	
	SQL_FreeHandle(hQuery)
	SQL_FreeHandle(hConnect)
	
	return iErrorCode
}

SaveUses(id, szName[32] = "", len = 0)
{
	if(!len)
	{
		get_user_name(id, szName, 31)
	}
	
	ClearSqlString(szName, charsmax(szName))
	
	formatex(g_szQuery, charsmax(g_szQuery), "UPDATE %s SET uses = %d WHERE name = '%s'", TABLE_NAME, g_iUses[id], szName)
	SQL_ThreadQuery(g_hSql, "query_handler", g_szQuery)
}
#endif

public TaskJoinTeam(id)
{
	if(g_iRunning == OFF)
	{
		client_print(id, print_chat, "Press M to join a team")
		client_cmd(id, "chooseteam")
		return;
	}
	
	new CsTeams:iTeam = g_iActivatorTeam == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT
	
	engclient_cmd(id, "jointeam", iTeam == CS_TEAM_CT? "1" : "2")
	engclient_cmd(id, "joinclass", "5")
	
	g_iTeams[id] = iTeam
}

public message_ShowMenu(msgid, dest, id)
{
	if(g_iRunning == RUNNING )
	//if(id == g_iSurvivors[ACTIVATOR] && g_iCanChoose)
	{
		/*static szMenu[5]
		get_msg_arg_string(4, szMenu, charsmax(szMenu))
		
		// One of the defauls cstrike menus
		if(contain(szMenu, "#") != -1)
		{
			return PLUGIN_HANDLED
		}*/
		
		if( g_iCanChoose && (1<<id) & g_iSurvivorsBit)
		{
			return PLUGIN_HANDLED
		}
		
		if(cs_get_user_team(id) != g_iActivatorTeam && is_user_alive(id))
		{
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public fw_Block(itouched, itoucher)
{
	if(!g_iRunning || !is_user_admin(itoucher))
	{
		return PLUGIN_CONTINUE
	}
	
	if(cs_get_user_team(itoucher) ==  g_iActivatorTeam)
	{
		return PLUGIN_CONTINUE
	}
		
	else
	{
		static const wId = 43
		if(get_pdata_int(itouched, wId) == CSW_USP)
		{
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public fw_Spawn(id)
{
	if(!is_user_alive(id) || g_iRunning != RUNNING)
	{
		return;
	}
	
	strip_weapons(id)
	give_item(id, "weapon_knife")
	
	if(cs_get_user_team(id) == g_iActivatorTeam)
	{
		cs_set_user_money(id, 16000)
		return;
	}
	
	// If not in survivor team
	give_item(id, "weapon_usp")
	cs_set_user_bpammo(id, CSW_USP, USP_BULLETS)
}

public RoundStart()
{
	if(!g_iRunning || g_iRunning != SELECTING)
	{
		return;
	}
	
	if(g_iCanChoose)
	{
		g_iCanChoose = 0
	}
		
	remove_task(TASKID_HUD)
	ClearSyncHud(0, gSyncHud)
		
	// didn't choose anyplayer
	if(!g_iSurvivors[OTHER])
	{
		set_hudmessage(255, 255, 0, -1.0, 0.20, 0, 0.0, 6.0, 0.0, 0.1)
		ShowSyncHudMsg(0, gSyncHud, "Survivor mode activation was canceled as the %s didn't choose another survivor", g_szActivatorLevel)
		ResetStuff()
	}
}

ResetStuff()
{
	g_iRunning = OFF
	
	arrayset(g_iSurvivors, 0, 2)
	arrayset(_:g_iTeams, -1, 33)
	
	g_iCanChoose = 0
	g_iCanNotAttack = 0
		
	//UnblockBuyZones()
		
	set_pcvar_num(g_pFreezeTime, g_iOldFreezeTime)
}

public RoundEnd()
{
	switch(g_iRunning)
	{
		case OFF:
		{
			return;
		}
		
		case READY_UP:
		{
			remove_task(TASKID_HUD)
			ClearSyncHud(0, gSyncHud)
		}
	
		case START:
		{
			// Starting mode next round
			set_pcvar_num(g_pFreezeTime, 0)
			TransferTeams(cs_get_user_team(g_iSurvivors[ACTIVATOR]))
		}

		case RUNNING:
		{
			g_iRunning = OFF
			UnblockBuyZones()
			SetTeamsBack()
			ResetStuff()
			
			g_iCanNotAttack = 1
		}
	}
}

public show_hud(iTaskId)
{
	if(!g_iRunning)
	{
		remove_task(iTaskId)
		return;
	}
	
	set_hudmessage(255, 255, 0, -1.0, 0.20, 0, 0.0, UPDATE_TIME_HUD - 0.1, 0.0, 0.1)
	switch(g_iRunning)
	{
		case RUNNING: 
		{
			set_hudmessage(255, 255, 0, -1.0, 0.20, 0, 0.0, 7.5, 0.0, 0.1)
			ShowSyncHudMsg(0, gSyncHud, "The person who kills any of the survivors will be awarded with 100 minutes.")
		}
		
		case READY_UP:
		{
			ShowSyncHudMsg(0, gSyncHud, "Survivor mode has been activated by %s %s. The selection of survivor will be done next round.", g_szActivatorLevel, g_szSurvivorsNames[ACTIVATOR])
		}
		
		case SELECTING:
		{
			ShowSyncHudMsg(0, gSyncHud, "Survivor mode has been activated by %s. The selection of survivor is running now!^nCurrent Survivors: %s", g_szActivatorLevel, g_szSurvivorsNames[ACTIVATOR])
		}
		
		case START:
		{
			ShowSyncHudMsg(0, gSyncHud, "The %s has selected the player.^nThe players are %s and %s", g_szActivatorLevel, g_szSurvivorsNames[ACTIVATOR], g_szSurvivorsNames[OTHER])
		}
	}
}

public eNewRound()
{
	switch(g_iRunning)
	{
		case OFF:
		{
			if(g_iCanNotAttack)
			{
				g_iCanNotAttack = 0
			}
		}
	
		case READY_UP:
		{
			g_iRunning = SELECTING;
			
			set_task(UPDATE_TIME_HUD, "show_hud", TASKID_HUD, .flags = "b");
			set_task(1.0, "ShowPlayersMenu", g_iSurvivors[ACTIVATOR]);
		}
	
		case START:
		{
			g_iRunning = RUNNING
			
			remove_task(TASKID_HUD)
			ClearSyncHud(0, gSyncHud)
			show_hud(TASKID_HUD)
			
			BlockBuyZones()
		}
	}
}

public ShowPlayersMenu(id)
{	
	new iPlayers[32], iNum, iPlayer, szName[32], szId[4]
	get_players(iPlayers, iNum/*, "ch"*/)
	
	if(g_iPlayersMenu)
	{
		menu_destroy(g_iPlayersMenu)
	}
	
	g_iPlayersMenu = menu_create("Choose your partner", "menu_handler")
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(iPlayer == id)
			continue;
		
		formatex(szId, charsmax(szId), "%d", iPlayer)
		get_user_name(iPlayer, szName, charsmax(szName))
		
		menu_additem(g_iPlayersMenu, szName, szId)
	}
	
	g_iCanChoose = 1
	menu_display(id, g_iPlayersMenu)
}

public menu_handler(id, menu, item)
{
	if(item < 0 || !g_iCanChoose)
	{
		menu_destroy(menu)
		g_iPlayersMenu = 0
		g_iCanChoose = 0
		
		ResetStuff()
		return;
	}
	
	new szInfo[4], iPId, iCallBack, szName[32]
	menu_item_getinfo(menu, item, iPId, szInfo, charsmax(szInfo), szName, charsmax(szName), iCallBack)
	
	iPId = str_to_num(szInfo)
	
	if(!is_user_connected(iPId))
	{
		client_print(id, print_chat, "Player %s is no longer connected. Choose another player", szName)
		
		// Redisplay menu to choose another player
		menu_display(id, menu)
		//g_iRunning = OFF
		
		return;
	}
	
	get_user_name(iPId, g_szSurvivorsNames[OTHER], 31)
	
	g_iPlayersMenu = 0
	g_iCanChoose = 0
	
	menu_destroy(menu)
	
	client_print(id, print_chat, "You have choosed player %s to be a Survivor with you!", szName)
	
	g_iSurvivors[OTHER] = iPId
	g_iRunning = START
	
	//remove_task(TASKID_HUD)
	ClearSyncHud(0, gSyncHud)
	
	show_hud(TASKID_HUD)
	
	g_iSurvivorsBit = (1<<iPId)
}

#if defined LIMITS
stock CanActivate(id, level)
{
	if(g_iUses[id] < g_iActivateLimit[level])
	{
		g_iUses[id] ++
		return 1
	}
	
	console_print(id, "You have exceeded the limit of activating Survivor mode for this day.")
	return 0
}

stock get_level(id)
{
	switch(get_user_flags(id) & FINAL)
	{
		case ADMIN_FLAG:
		{
			return ADMIN
		}
		
		case SILVER_FLAG:
		{
			return SILVER
		}
		
		case GOLDEN_FLAG:
		{
			return GOLDEN
		}
	}
	
	return -1
}
#endif

public AdminSurvivor(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	#if defined LIMITS
	new level = get_level(id)
	
	if(!CanActivate(id, level))
	{
		return PLUGIN_HANDLED
	}
	#endif
	
	if(g_iRunning)
	{
		console_print(id, "Mode is already running")
		return PLUGIN_HANDLED
	}
	
	static const InvalidTeams = (1<<_:CS_TEAM_SPECTATOR) | (1<<_:CS_TEAM_UNASSIGNED)
	if(1<<_:cs_get_user_team(id) & InvalidTeams)
	{
		console_print(id, "You can't activate the mode when your are a spectator!")
		return PLUGIN_HANDLED
	}
	
	if(get_playersnum() < get_pcvar_num(g_pMinPlayers))
	{
		console_print(id, "Not enough players to activate mode")
		return PLUGIN_HANDLED
	}
	
	g_iOldFreezeTime = get_pcvar_num(g_pFreezeTime)
	set_pcvar_num(g_pFreezeTime, FREEZE_TIME)
	
	g_iActivatorTeam = cs_get_user_team(id)
	g_iRunning = READY_UP
	
	arrayset(g_iSurvivors, sizeof(g_iSurvivors), 0)
	
	g_iSurvivors[ACTIVATOR] = id
	g_iTeams[id] = g_iActivatorTeam
	
	g_iSurvivorsBit |= (1<<id)
	
	get_user_name(id, g_szSurvivorsNames[ACTIVATOR], 31)
	
	copy(g_szActivatorLevel, charsmax(g_szActivatorLevel), g_szLevels[level])
	
	console_print(id, "Players' menu will appear next round to choose the survivor.")
	
	set_task(UPDATE_TIME_HUD, "show_hud", TASKID_HUD, .flags = "b")
	
	return PLUGIN_HANDLED
}	

TransferTeams(CsTeams:iTeam)
{
	if( ( g_iTeams[g_iSurvivors[OTHER]] = cs_get_user_team(g_iSurvivors[OTHER] ) ) != iTeam )
	{
		cs_set_user_team(g_iSurvivors[OTHER], iTeam)
	}
	
	// Setting new team for other players
	iTeam = (iTeam == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT)
	
	new iBit = ( (1<<g_iSurvivors[ACTIVATOR]) | (1<<g_iSurvivors[OTHER]) )
	
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum/*, "ch"*/)
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if( ( 1<< iPlayer ) & iBit )
			continue;
		
		g_iTeams[iPlayer] = cs_get_user_team(iPlayer)
		
		cs_set_user_team(iPlayer, iTeam)
	}
	
	return 1
}

SetTeamsBack()
{
	new iPlayers[32], iNum, iPlayer
	get_players(iPlayers, iNum)
	
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(cs_get_user_team(iPlayer) != g_iTeams[iPlayer] )
		{
			cs_set_user_team(iPlayer, g_iTeams[iPlayer])
		}
	}
}

strip_weapons(id)
{
	#define OFFSET_PRIMARYWEAPON        116 
	
	strip_user_weapons(id) 
	set_pdata_int(id, OFFSET_PRIMARYWEAPON, 0) 
}

public message_StatusIcon(msgID, dest, receiver)
{
	// Check if status is to be shown
	if(gBlockBuyZone && cs_get_user_team(receiver) != g_iActivatorTeam && get_msg_arg_int(1)) {
		
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

stock BlockBuyZones()
{
	// Hide buyzone icon from all players
	message_begin(MSG_BROADCAST, gMsgStatusIcon);
	write_byte(0);
	write_string("buyzone");
	message_end();
	
	// Get all alive players
	new players[32], pnum;
	get_players(players, pnum, "ae", g_iActivatorTeam == CS_TEAM_CT ? "TERRORIST" : "CT");
	
	// Remove all alive players from buyzone
	while(pnum-- > 0)
	{
		RemoveFromBuyzone(players[pnum]);
	}
	// Set that buyzones should be blocked
	gBlockBuyZone = true;
}

stock RemoveFromBuyzone(id)
{
	// Define offsets to be used
	const m_fClientMapZone = 235;
	const MAPZONE_BUYZONE = (1 << 0);
	const XO_PLAYERS = 5;
	
	// Remove player's buyzone bit for the map zones
	set_pdata_int(id, m_fClientMapZone, get_pdata_int(id, m_fClientMapZone, XO_PLAYERS) & ~MAPZONE_BUYZONE, XO_PLAYERS);
}

stock UnblockBuyZones()
{
	// Set that buyzone should not be blocked
	gBlockBuyZone = false;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
