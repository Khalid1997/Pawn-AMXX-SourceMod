#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <bbshop>

#define VERSION	"1.0"

new g_iJumperZombieId
new g_iItemIndex
new g_iHasGravity[33]

public plugin_init()
{
	register_plugin("[BBSHOP EXTRA] Gravity", VERSION, "Khalid :)")
	
	g_iItemIndex = bb_register_extra_item("Gravity", 1, BB_TEAM_ANY)
	g_iJumperZombieId = get_xvar_id("g_zclass_jumper")
	
	RegisterHam(Ham_Spawn, "player", "Fwd_Spawn", 1)
}

public client_putinserver(id)
	g_iHasGravity[id] = 0

public bb_extra_item_choosed(id, itemid)
{
	if(itemid != g_iItemIndex)
		return;
	
	if(g_iHasGravity[id])
	{
		ColorChat(id, "You already have gravity")
		return;
	}
	
	if(bb_get_user_zombie_class(id) == g_iJumperZombieId)
	{
		ColorChat(id, "You can't buy this when you have jumper zombie class")
		return;
	}
	
	g_iHasGravity[id] = 1
	set_user_gravity(id, 0.5)
}

public Fwd_Spawn(id)
{
	if(is_user_alive(id))
	{
		if(g_iHasGravity[id])
		{
			g_iHasGravity[id] = 0
			set_user_gravity(id, 1.0)
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
