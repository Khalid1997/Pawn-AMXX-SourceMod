#include <amxmodx>
#include <fakemeta>

public plugin_init()
{
	register_clcmd("say /test", "test")
}

public test(id)
{
	new ent = -1
	
	while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_breakable") ) )
	{
		// FIRST WAY
		//entity_get_string(ent, EV_SZ_targetname, szTargetName, charsmax(szTargetName))
		//Health = entity_get_float(ent, EV_FL_health)
		//server_print("Target name %s ... HP: %f", szTargetName, Health)
		//ExecuteHam(Ham_TakeDamage, ent, 0, 0, Health, DMG_BLAST);
		
		// SECOUND WAY
		//dllfunc(DLLFunc_Use, ent, 0)
		
		// OTHER
		//set_pev(ent, pev_solid, SOLID_NOT)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
