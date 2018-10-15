#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <csx>

public plugin_init()
{
	RegisterHam(Ham_Touch, "grenade", "Fwd_Touch")
	//register_forward(FM_Think, "Fwd_Think", 1)
	//register_forward(FM_Touch, "Fwd_Touch", 0)
}

public grenade_throw(id, iGren, wId)
{
	if(wId != CSW_HEGRENADE)
		return;

	delay_explosion(wId)
}

public Fwd_Touch(toucher, touched)
{
	if( is_grenade(toucher)&& is_solid(touched) )
	{
		set_pev(toucher, pev_dmgtime, 0.0)
		dllfunc(DLLFunc_Think, toucher)
	}
}

delay_explosion(grenade)
{
	static Float:gtime
	global_get(glb_time, gtime)
	set_pev(grenade, pev_dmgtime, gtime + 600.0)
	set_pev(grenade, pev_movetype, MOVETYPE_BOUNCE)
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
	return (equal(classname, "grenade") && !get_pdata_int(ent, 114) ) ? true : false
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
