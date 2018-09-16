#include <amxmodx>
#include <fun>
#include <bbshop>

new g_iItemId

public plugin_init()
{
	register_plugin("[BBSHOP] FlashBang", "1.0", "Khalid :)")
	g_iItemId = bb_register_extra_item("Flash grenade", 25, BB_TEAM_HUMANS)
}

public bb_extra_item_choosed(id, itemid)
{
	if(itemid == g_iItemId)
	{
		give_item(id, "weapon_flashbang")
		ColorChat(id, "You have bought ^3FlashBang")
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
