#include <amxmodx>
#include <hamsandwich>

public plugin_init() {
	register_plugin("Spawn fix No weapon", "0000.0", "zomeone")
	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1);
}

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
