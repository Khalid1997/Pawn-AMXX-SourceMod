#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <sqlx>
#include <basebuilder>
#include <bbshop_const>

new const VERSION[] = "0.1"

#define WITH_MAX_POINTS

new Array:gItemName
new Array:gItemCost
new Array:gItemTeam
new g_iItemCount

new Float:g_flPlayerDamage[33], g_iPlayerPoints[33]

new gItemChoosedForward[2], gRoundEndForward

enum _:CVARS
{
	KILL,
	DAMAGE
}

new g_pDamageH, g_pDamageZ
new g_pKillH, g_pKillZ
#if defined WITH_MAX_POINTS
new g_pMaxPoints
#endif
new bool:g_bAllowShop

new g_iMaxPlayers
#define IsPlayer(%1)	(1 <= %1 <= g_iMaxPlayers)

new Handle:g_hSql
new gszQuery[250]

public plugin_init()
{
	register_plugin("BaseBuilder Shop", VERSION, "Khalid :)")
	
	register_clcmd("say /mypoints", "CmdShowUserPoints")
	register_clcmd("say /bbshop", "CmdShowShop")
	register_clcmd("chooseteam", "CmdShowShop")
	
	register_clcmd("say /toppoints", "CmdShowTopPoints")
	register_concmd("amx_bbpoints", "AdminShowPlayerPoints", ADMIN_BAN, "<name> - Shows user points")
	register_concmd("amx_set_bbpoints", "AdminSetPlayerPoints", ADMIN_RCON, "<name> <amount to set> - Sets user points to <amount>")
	register_concmd("amx_take_bbpoints" ,  "AdminTakePlayersPoints" , ADMIN_RCON, "<name> <points to take> - Take points from a player")
	
	gItemChoosedForward[0] = CreateMultiForward("bb_extra_item_choosed", ET_STOP, FP_CELL, FP_CELL)
	gItemChoosedForward[1] = CreateMultiForward("zp_extra_item_selected", ET_STOP, FP_CELL, FP_CELL)
	gRoundEndForward = CreateMultiForward("bb_round_end", ET_IGNORE)
	
	if(gItemChoosedForward[0] <= 0 || gItemChoosedForward[1] <= 0 )
		set_fail_state("Could not create extra item choosed forward")
	
	RegisterHam(Ham_Killed, "player", "Fwd_Killed", 0)
	RegisterHam(Ham_TakeDamage, "player", "Fwd_TakeDamage", 1)
	RegisterHam(Ham_Player_ImpulseCommands, "player", "Fwd_Impulse", 0)
	
	register_logevent("RoundEnd", 2, "1=Round_End")
	
	gItemName = ArrayCreate(32, 1)
	gItemCost = ArrayCreate(1, 1)
	gItemTeam = ArrayCreate(1, 1)
	
	#if defined WITH_MAX_POINTS
	g_pMaxPoints = register_cvar("bb_pointsmax", "5000")
	#endif
	g_pDamageH	= register_cvar("bb_damage_humans", "150.0")
	g_pDamageZ	= register_cvar("bb_damage_zombies", "50.0")
	g_pKillH	= register_cvar("bb_killpoints_humans", "50")
	g_pKillZ	= register_cvar("bb_killpoints_zombies", "35")
	
	g_iMaxPlayers = get_maxplayers()
	
	g_hSql = SQL_MakeDbTuple("localhost", "root", "", "amxx")
	SQL_ThreadQuery(g_hSql, "QueryHandler", "CREATE TABLE IF NOT EXISTS `bbshop_points` (steamid VARCHAR(35), name VARCHAR(32), points INT)")
}
	
public plugin_natives()
{
	register_library("bbshop")
	
	register_native("bb_get_user_points", "native_get_user_points", 1)
	register_native("bb_set_user_points", "native_set_user_points", 1)
	register_native("bb_register_extra_item", "native_register_extra_item", 1)
	
	register_native("zp_get_user_ammo_packs", "native_get_user_points", 1)
	register_native("zp_set_user_ammo_packs", "native_get_user_points", 1)
	register_native("zp_register_extra_item", "native_register_extra_item", 1)
	//register_native("bb_force_buy_extra_item", "native_force_buy_extra_item", 1)
}

public plugin_end()
{
	DestroyForward(gItemChoosedForward[0])
	DestroyForward(gItemChoosedForward[1])
	DestroyForward(gRoundEndForward)
	
	SQL_FreeHandle(g_hSql)
}

public client_putinserver(id)
	g_iPlayerPoints[id] = GetUserPoints(id)
	
public client_disconnect(id)
{
	static szName[32]; get_user_name(id, szName, 31)
	
	ColorChat(0, "Player ^3%s ^4disconnected with a total of ^3%d ^4Points", szName, g_iPlayerPoints[id])
}

public CmdShowUserPoints(id)
{
	ColorChat(id, "You have ^3%d ^4points.", g_iPlayerPoints[id])
	return PLUGIN_HANDLED
}

public CmdShowTopPoints(id)
{
	new data[1]; data[0] = id
	formatex(gszQuery, charsmax(gszQuery), "SELECT name,points FROM `bbshop_points` ORDER BY points DESC LIMIT 15")
	SQL_ThreadQuery(g_hSql, "FormatTop", gszQuery, data, 1)
}

public CmdShowShop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
		
	if(!g_bAllowShop)
	{
		ColorChat(id, "You must wait until round starts")
		return PLUGIN_HANDLED
	}
		
	ShowMenu(id)
	return PLUGIN_HANDLED
}

public AdminTakePlayerPoints(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new szName[32], iPlayer, szPoints[32]
	
	read_argv(1, szName, charsmax(szName))
	
	iPlayer = cmd_target(id, szName, CMDTARGET_ALLOW_SELF)
	
	if(!iPlayer)
	{
		console_print(id, "Player could not be found")
		return PLUGIN_HANDLED
	}
	
	new iPoints
	read_argv(2, szPoints, charsmax(szPoints))
	
	if( !is_str_num(szPoints) || (iPoints = str_to_num(szPoints)) < 0 )
	{
		console_print(id, "You can't take that")
		return PLUGIN_HANDLED
	}
	
	if(g_iPlayerPoints[id] - iPoints < 0)
	{
		iPoints = g_iPlayerPoints[iPlayer]
		g_iPlayerPoints[iPlayer] = 0
	}
		
	else g_iPlayerPoints[iPlayer] -= iPoints
	
	new szAdminName[32]; get_user_name(id, szAdminName)

public AdminShowPlayerPoints(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
		
	new szName[32], iPlayer
	read_argv(1, szName, 31)
	
	iPlayer = cmd_target(id, szName, CMDTARGET_ALLOW_SELF)
	if(!iPlayer)
	{
		console_print(id, "Player could not be found or not connected.")
		return PLUGIN_HANDLED
	}
	
	get_user_name(id, szName, 31)
	console_print(id, "Player %s has %d points", szName, g_iPlayerPoints[id])
	
	return PLUGIN_HANDLED
}

public AdminSetPlayerPoints(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
		
	new szName[32], iPlayer
	read_argv(1, szName, 31)
	
	iPlayer = cmd_target(id, szName, CMDTARGET_ALLOW_SELF)
	if(!iPlayer)
	{
		console_print(id, "Player could not be found or not connected.")
		return PLUGIN_HANDLED
	}
	
	get_user_name(iPlayer, szName, 31)
	
	new szAmount[30], iAmount
	read_argv(2, szAmount, charsmax(szAmount))
	
	if( ( iAmount = str_to_num(szAmount) ) < 0 || !is_str_num(szAmount) )
		return console_print(id, "You can't set that")
		
	g_iPlayerPoints[id] = iAmount
	
	new szAdminName[32]; get_user_name(id, szAdminName, 31)
	ColorChat(0, "ADMIN ^3%s: ^1Set player ^3%s ^1points to ^3%d", szAdminName, szName, iAmount)
	
	console_print(id, "Successfully setted player %s points to %d", szName, iAmount)
	
	return PLUGIN_HANDLED
}
	
public bb_round_started()
	g_bAllowShop = true

public RoundEnd()
{
	static iReturn
	ExecuteForward(gRoundEndForward, iReturn)
	g_bAllowShop = false
}

public Fwd_Impulse(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	if(pev(id, pev_impulse) == 100)
	{
		if(g_bAllowShop)
			ShowMenu(id)
		else	ColorChat(id, "You can't use the bb shop until Round start.")
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

public Fwd_Killed(iVictim, iAttacker)
{
	if(IsPlayer(iAttacker))
	{
		static iNum
		switch(bb_is_user_zombie(iAttacker))
		{
			case 1:		// IS ZOMBIE
			{
				if( !( iNum = get_pcvar_num(g_pKillZ) ) )
					return;
					
			}
			
			case 0: 	// HUMAN
			{
				if( !( iNum = get_pcvar_num(g_pKillH) ) )
					return;
			}
		}
		
		g_iPlayerPoints[iAttacker] += iNum
		
		#if defined WITH_MAX_POINTS
		CheckPoints(iAttacker)
		#endif
	}
}

public Fwd_TakeDamage(id, idinflictor, iAttacker, Float:flDamage, damagebits)
{
	static Float:flNum
	if(IsPlayer(iAttacker))
	{
		switch(bb_is_user_zombie(iAttacker))
		{
			case 1:		// IS ZOMBIE
			{
				if( !( flNum = get_pcvar_float(g_pDamageZ) ) )
					return;
					
			}
			
			case 0: 	// HUMAN
			{
				if( !( flNum = get_pcvar_float(g_pDamageH) ) )
					return;
			}
		}
				
		g_flPlayerDamage[iAttacker] += flDamage
		
		while( g_flPlayerDamage[iAttacker] >= flNum )
		{
			g_flPlayerDamage[iAttacker] -= flNum
			g_iPlayerPoints[iAttacker]++
		}
		
		#if defined WITH_MAX_POINTS
			CheckPoints(iAttacker)
		#endif
	}
}

/*
	----------------------------------------------------- 
	----------------- OTHER THINGS ----------------------
	-----------------------------------------------------
*/
GetUserPoints(id)
{
	new errorcode, error[100], szAuthId[35], szName[32], iPoints 
	get_user_authid(id, szAuthId, 34)
	get_user_name(id, szName, charsmax(szName))
	
	replace_all(szName, 31, "^"", "")
	replace_all(szName, 31, "'", "")
	
	new Handle:hConnection = SQL_Connect(g_hSql, errorcode, error, charsmax(error))
	
	if(errorcode)
		return set_fail_state(error)
		
	new Handle:hQuery = SQL_PrepareQuery(hConnection, "SELECT * FROM `bbshop_points` WHERE steamid = '%s'", szAuthId)
	
	if(!SQL_Execute(hQuery))
		return log_amx("Query failed")
	
	if(!SQL_MoreResults(hQuery))
	{
		formatex(gszQuery, charsmax(gszQuery), "INSERT INTO `bbshop_points` VALUES ('%s', '%s', 0)", szAuthId, szName)
		SQL_ThreadQuery(g_hSql, "QueryHandler", gszQuery)
		
		SQL_FreeHandle(hConnection); SQL_FreeHandle(hQuery)
		return iPoints
	}
	
	iPoints = SQL_ReadResult(hQuery, 2)
	
	new szSavedName[32]
	SQL_ReadResult(hQuery, 1, szSavedName, charsmax(szSavedName))
	
	replace_all(szSavedName, 31, "^"", "")
	replace_all(szSavedName, 31, "'", "")
	
	if(!equal(szSavedNalolme, szName))
	{
		formatex(gszQuery, charsmax(gszQuery), "UPDATE `bbshop_points` SET name = '%s' WHERE steamid = '%s'", szName, szAuthId)
		SQL_ThreadQuery(g_hSql, "QueryHandler", gszQuery)
	}
	
	SQL_FreeHandle(hConnection); SQL_FreeHandle(hQuery)
	
	return iPoints
}

public client_infochanged(id)
{
	static szNewName[32], szName[32]
	
	get_user_name(id, szName, charsmax(szName))
	get_user_info(id, "name", szNewName, 31)
	
	if(!equal(szName, szNewName))
	{
		static szAuthId[35]; get_user_authid(id, szAuthId, charsmax(szAuthId))
		
		formatex(gszQuery, charsmax(gszQuery), "UPDATE `bbshop_points` SET name = '%s' WHERE steamid = '%s'", szNewName, szAuthId)
		SQL_ThreadQuery(g_hSql, "QueryHandler", gszQuery)
	}
}

ShowMenu(id)
{
	if(g_iItemCount <= 0)
	{
		ColorChat(id, "No items registered.")
		return;
	}
	
	if(!is_user_alive(id))
		return;

	new iTeam = (1<<bb_is_user_zombie(id))

	new menu = menu_create(iTeam & BB_TEAM_ZOMBIES ? "Zombies Shop Menu" : "Humans Shop Menu", "shop_handler")

	new szName[50], iCost, szItemId[10], szFmt[70]
	for(new i; i < g_iItemCount; i++)
	{
		if( !(iTeam & ArrayGetCell(gItemTeam, i) ))
			continue;
		
		ArrayGetString(gItemName, i, szName, charsmax(szName))
		iCost = ArrayGetCell(gItemCost, i)
		
		formatex(szFmt, charsmax(szFmt), "\w%s - \y%d \rPoints", szName, iCost)
		
		formatex(szItemId, charsmax(szItemId), "%d", i)
		
		menu_additem(menu, szFmt, szItemId)
	}
	
	menu_display(id, menu)
}

public shop_handler(id, menu, item)
{
	if(!is_user_alive(id))
		return;
	
	new szItemId[10], iItemId, access, callback
	
	if(item < 0)
	{
		menu_destroy(menu)
		return;
	}
	
	menu_item_getinfo(menu, item, access, szItemId, charsmax(szItemId), .callback = callback)
	iItemId = str_to_num(szItemId)
	menu_destroy(menu)
	
	new iCost = ArrayGetCell(gItemCost, iItemId)
	if(g_iPlayerPoints[id] < iCost)
	{
		ColorChat(id, "You don't have enough points")
		return;
	}
	
	new iReturn
	ExecuteForward(gItemChoosedForward[0], iReturn, id, iItemId)
	ExecuteForward(gItemChoosedForward[1], iReturn, id, iItemId)
	
	if(iReturn == PLUGIN_HANDLED)
		return;
	
	g_iPlayerPoints[id] -= iCost
}

#if defined WITH_MAX_POINTS
CheckPoints(id)
{
	static iMaxPoints

	if(g_iPlayerPoints[id] > ( iMaxPoints = get_pcvar_num(g_pMaxPoints) ))
		g_iPlayerPoints[id] = iMaxPoints
}
#endif

public FormatTop(failstate, Handle:query, error[], errnum, data[])
{
	if(failstate == TQUERY_CONNECT_FAILED)
		return set_fail_state("Connect to sql database failed")
		
	if(failstate == TQUERY_QUERY_FAILED)
		return log_amx("Query failed")
		
	if(errnum)
		return log_amx(error)
	
	new szMotd[1024], len, szName[32]
	len = formatex(szMotd, charsmax(szMotd), "<body bgcolor=#000000><font color=#FFB00><pre>")
	len += format(szMotd[len], charsmax(szMotd) - len,"%s %-22.22s %3s^n", "#", "Name", "Time in minutes")
	
	new i
	while(SQL_MoreResults(g_hSql))
	{
		SQL_ReadResult(g_hSql, 1, szName, charsmax(szName))
		replace_all(szName, charsmax(szName), "<", "&lt;")
		replace_all(szName, charsmax(szName), ">", "&gt;")
		
		len += formatex(szMotd[len], charsmax(szMotd) - len, "%s %-22.22s %3d^n", ++i, szName, SQL_ReadResult(g_hSql, 2) )
	}
	
	len += formatex(szMotd[len], charsmax(szMotd) - len, "</pre></font></body>")
	
	show_motd(data[0], szMotd, "Top15 Points")
	return 1
}

public QueryHandler(failstate, Handle:query, error[], errnum)
{
	if(failstate == TQUERY_CONNECT_FAILED)
		return set_fail_state("Connect to sql database failed")
		
	if(failstate == TQUERY_QUERY_FAILED)
		return log_amx("Query failed")
		
	if(errnum)
		return log_amx(error)
		
	return 1
}

public native_get_user_points(id)
{
	if(!is_user_connected(id))
		return -1
	
	return g_iPlayerPoints[id]
}

public native_set_user_points(id, iNum)
{
	if(!is_user_connected(id))
		return -1k
	
	g_iPlayerPoints[id] = iNum
	return 1
}

public native_register_extra_item(const szName[], const iCost, iTeam)
{
	param_convert(1)
	
	ArrayPushString(gItemName, szName)
	ArrayPushCell(gItemCost, iCost)

	if(iTeam == BB_TEAM_ANY)
		iTeam = BB_TEAM_ZOMBIES|BB_TEAM_HUMANS
		
	ArrayPushCell(gItemTeam, iTeam)
	
	g_iItemCount++
	return (g_iItemCount - 1)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
