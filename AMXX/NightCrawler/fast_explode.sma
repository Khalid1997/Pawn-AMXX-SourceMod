#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <csx>

#if AMXX_VERSION_NUM < 183

#define SHORT_BYTES    2 
#define INT_BYTES        4 
#define BYTE_BITS        8 

stock bool:get_pdata_bool(ent, charbased_offset, intbase_linuxdiff = 5) 
{ 
	return !!( get_pdata_int(ent, charbased_offset / INT_BYTES, intbase_linuxdiff) & (0xFF<<((charbased_offset % INT_BYTES) * BYTE_BITS)) ) 
} 
stock get_pdata_short(ent, shortbased_offset, intbase_linuxdiff = 5) 
{ 
	return ( get_pdata_int(ent, shortbased_offset / SHORT_BYTES, intbase_linuxdiff)>>>((shortbased_offset % SHORT_BYTES) * BYTE_BITS) ) & 0xFFFF 
} 
#endif

#define INDEX pev_iuser2

new g_iMode[33]

public plugin_init()
{
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_flashbang", "fw_FlashBangSecAttack", 0);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_hegrenade", "fw_FlashBangSecAttack", 0);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_smokegrenade", "fw_FlashBangSecAttack", 0);
	RegisterHam(Ham_Touch, "grenade", "Fwd_Touch")
}

public client_putinserver(id)
{
	g_iMode[id] = 0
}

public fw_FlashBangSecAttack(iEnt)
{
	static id; id = pev(iEnt, pev_owner)
	
	if( ( pev(id, pev_button) & IN_ATTACK2 ) )
	{
		server_print("In");
		return;
	}
	
	server_print("Out");
	g_iMode[id] = !g_iMode[id];
	client_print(id, print_center, "Mode: %s", g_iMode[id] ? "Impact" : "Normal");
}

public grenade_throw(id, iGren, wId)
{
	if(wId != CSW_HEGRENADE)
		return;
	
	if(g_iMode[id])
	{
		delay_explosion(iGren)
		g_iMode[id] = 0
	}
}

public Fwd_Touch(toucher, touched)
{
	if( !pev_valid(toucher) || !pev_valid(touched) )
	{
		return;
	}
	
	if(pev(toucher, INDEX) && IsHeGrenade(toucher) && is_solid(touched) )
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
	set_pev(grenade, INDEX, 1);
}


stock bool:is_solid(ent)
{
	return ( ent ? ( (pev(ent, pev_solid) > SOLID_TRIGGER) ? true : false ) : true )
}

stock IsHeGrenade( ent) 
{ 
	new const m_bIsC4 = 385
	new const m_usEvent_Grenade = 228
	
	if( get_pdata_bool(ent, m_bIsC4) ) 
	{ 
		return 0
	} 
	
	new usEvent = get_pdata_short(ent, m_usEvent_Grenade) 

	static m_usHgrenExplo
	if( !m_usHgrenExplo ) 
	{ 
		m_usHgrenExplo = engfunc(EngFunc_PrecacheEvent, 1, "events/createexplo.sc") 
	} 
	
	return usEvent == m_usHgrenExplo ? 1 : 0
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
