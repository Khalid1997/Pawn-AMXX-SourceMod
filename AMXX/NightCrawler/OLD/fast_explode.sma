#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <csx>

new g_iGrenEvent
new g_iEventForward

public plugin_precache()
{
	
}

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
	
	server_print("%d %d", iGren, wId)
	
	delay_explosion(iGren)
}

public Fwd_Touch(toucher, touched)
{
	if( IsHeGrenade(toucher) && is_solid(touched) )
	{
		set_pev(toucher, pev_dmgtime, 0.0)
		dllfunc(DLLFunc_Think, toucher)
	}
}

stock delay_explosion(grenade)
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

/*
stock bool:is_grenade(ent)
{
	if (!pev_valid(ent)) return false
	//static classname[32]
	//pev(ent, pev_classname, classname, 31)
	return ( equal(classname, "grenade") && get_pdata_int(ent, 114) ) ? true : false
}*/

stock IsHeGrenade( ent) 
{ 
	new const m_bIsC4 = 385
	new const m_usEvent_Grenade = 228
	
	if( get_pdata_bool(ent, m_bIsC4) ) 
	{ 
		return 0
	} 
	
	new usEvent = get_pdata_short(ent, m_usEvent_Grenade) 
	if( !usEvent ) 
	{ 
		return 0
	} 
	
	static m_usHgrenExplo
	if( !m_usHgrenExplo ) 
	{ 
		m_usHgrenExplo = engfunc(EngFunc_PrecacheEvent, 1, "events/createexplo.sc") 
	} 
	
	return usEvent == m_usHgrenExplo ? 1 : 0
} 

#if AMXX_VERSION_NUM < 183
stock bool:get_pdata_bool(ent, charbased_offset, intbase_linuxdiff = 5) 
{ 
	return !!( get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff) & (0xFF<<((charbased_offset % INT_BYTES) * BYTE_BITS)) ) 
} 
stock get_pdata_short(ent, shortbased_offset, intbase_linuxdiff = 5) 
{ 
	return ( get_pdata_int(ent, shortbased_offset / SHORT_BYTES, intbase_linuxdiff)>>>((shortbased_offset % SHORT_BYTES) * BYTE_BITS) ) & 0xFFFF 
} 
#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
