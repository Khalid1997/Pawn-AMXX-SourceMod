#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <csx>
#include <bbshop>
#include <fakemeta_util>

#define TASKID	149871621

new const g_iCost = 50

new gBit, gItemId
#define IsInBit(%1)		(gBit & (1<<%1))
#define AddToBit(%1)		(gBit |= (1<<%1))
#define RemoveFromBit(%1)	(gBit &= ~(1<<%1))

new g_iMaxPlayers
#define IsPlayer(%1)	(1 <= %1 <= g_iMaxPlayers)

new g_iCounters[33]
new g_iMenus[33]
new g_pDonate

public plugin_init()
{
	register_touch("grenade", "worldspawn", "Fwd_Touch")
	register_touch("grenade", "func_wall", "Fwd_Touch")
	//register_forward(FM_Think, "Fwd_Think", 1)
	//register_forward(FM_Touch, "Fwd_Touch", 0)
	//gItemId = bb_register_extra_item("Command Nade", g_iCost, BB_TEAM_ZOMBIES)
	register_clcmd("say /buy", "BuyGrenade")
	
	g_pDonate = register_cvar("bb_command_points_to_donate", "50")
	
	g_iMaxPlayers = get_maxplayers()
}

public BuyGrenade(id)
{
	if(!user_has_weapon(id, CSW_HEGRENADE))
		give_item(id, "weapon_hegrenade")
	
	AddToBit(id)
}

public bb_extra_item_choosed(id, itemid)
{
	if(itemid != gItemId)
		return;

	if(!user_has_weapon(id, CSW_HEGRENADE))
		give_item(id, "weapon_hegrenade")
		
	AddToBit(id)
}

public grenade_throw(id, iGren, wId)
{
	if(wId == CSW_HEGRENADE && IsInBit(id))
	{
		delay_explosion(iGren, id)
	}
}

public Fwd_Touch(toucher, touched)
{
	static iEnt, owner, iTeam
	owner = pev(toucher, pev_iuser4)
	
	new Float:flOrigin[3]
	
	if( is_grenade(toucher) && IsInBit(owner) )
	{
		RemoveFromBit(owner)
		iEnt = -1
		iTeam = get_user_team(owner)
		pev(toucher, pev_origin, flOrigin)
		
		while( ( iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, flOrigin, 8000.0) ) && ( 1 <= iEnt <= g_iMaxPlayers ) )//&& iTeam != get_user_team(iEnt)/*!bb_is_user_zombie(iEnt)) */ && owner != iEnt)
		{
			server_print("%d", iEnt)
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_FROZEN)  
			set_user_godmode(iEnt, 1)
			ShowMenu(iEnt, owner)
		}
		
		remove_entity(toucher)

		server_print("Removed")
	}
}

ShowMenu(id, id2)
{
	static szItem[25], iNum, szInfo[4]
	
	/*if(bb_get_user_points(id) < ( iNum = get_pcvar_num(g_pDonate) ) )
	{
		set_user_godmode(id, 0)
		user_kill(id)
		return;
	}*/
		
	new menu = menu_create("Choose:", "command_handler")

	formatex(szItem, charsmax(szItem), "Donate %d", iNum)
	num_to_str(id2, szInfo, charsmax(szInfo))
	menu_additem(menu, szItem, szInfo)
	menu_additem(menu, "Slay your self :)", "0")
	
	menu_display(id, menu)
	g_iMenus[id] = menu
	
	g_iCounters[id] = 16
	Counter(id + TASKID)
	set_task(1.0, "Counter", id + TASKID, .flags="b")
}

public Counter(taskid)
{
	static id
	id = taskid - TASKID
	g_iCounters[id]--
	if(!g_iCounters[id])
	{
		menu_destroy(g_iMenus[id])
		user_kill(id)
		remove_task(taskid)
		return;
	}
	
	client_print(id, print_center, "%d seconds left to choose", g_iCounters[id])
}

public command_handler(id, menu, item)
{
	if(item < 0)
		return;
		
	new szInfo[3], access, callback
	menu_item_getinfo(menu, item, access, szInfo, charsmax(szInfo), .callback=callback)
	menu_destroy(menu)
	
	remove_task(id + TASKID)
	
	set_user_godmode(id, 0)
	set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
	if(! (callback = str_to_num(szInfo) ) )
	{
		user_kill(id)
		return;
	}
	
	if(!is_user_connected(callback))
	{
		client_print(id, print_chat, "The user who commanded you is no longer connected")
		
		return;
	}
	
	//bb_set_user_points(id, bb_get_user_points(id) - (access = get_pcvar_num(g_pDonate)))
	//bb_set_user_points(callback, bb_get_user_points(callback) + access)
}

delay_explosion(grenade, id)
{
	static Float:gtime
	global_get(glb_time, gtime)
	set_pev(grenade, pev_dmgtime, gtime + 600.0)
	set_pev(grenade, pev_movetype, MOVETYPE_BOUNCE)
	
	server_print("pev %d", pev(grenade, pev_iuser4))
	set_pev(grenade, pev_iuser4, id)
}

stock bool:is_solid(ent)
{
	// Here we account for ent = 0, where 0 means it's part of the map (and therefore is solid)
	return ( ent ? ( (pev(ent, pev_solid) > SOLID_TRIGGER) ? true : false ) : true )
}

stock bool:is_grenade(ent)
{
	if (!pev_valid(ent)) return false
	static classname[32]
	pev(ent, pev_classname, classname, 31)
	
	return (equal(classname, "grenade") && get_pdata_int(ent, 114) & (1<<0)) ? true : false
}

/*
cs_get_grenade_type( iEnt ) // VEN
{
    new iBits = get_pdata_int(iEnt, 114)
    if (iBits & (1<<0))
    {
        return CSW_HEGRENADE
    }
    else if (iBits & (1<<1))
    {
        return CSW_SMOKEGRENADE
    }
    else if (!iBits)
    {
        return CSW_FLASHBANG        
    }
    return 0
}*/

