#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

public plugin_init()
{
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed_Post", 1);
}

public fw_ResetMaxSpeed_Post(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	new Float:flMaxSpeed
	pev(id, pev_maxspeed, flMaxSpeed)
	
	server_print("flMaxSpeed is %0.1f", flMaxSpeed)
	
	if(flMaxSpeed != 1.0)
	{
		set_pev(id, pev_maxspeed, 399.0)
		
		pev(id, pev_maxspeed, flMaxSpeed)
		server_print("flMaxSpeed After Change is %0.1f", flMaxSpeed)
	}
}