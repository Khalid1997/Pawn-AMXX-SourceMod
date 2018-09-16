#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

new const VERSION[] = "1.0"

new gBit

#define IsInBit(%1)		( (1<<%1) & gBit )
#define AddToBit(%1)		( gBit |= (1<<%1) )
#define RemoveFromBit(%1)	( gBit &= ~(1<<%1) )

public plugin_init() {
	register_plugin("Custom BHOP", VERSION, "")
	RegisterHam(Ham_Player_PreThink, "player", "Fwd_Think")
	register_clcmd("say /bhop", "toggle_bhop")
}

public toggle_bhop(id)
{
	new menu = menu_create("Bhop menu", "menu_handler")
	
	if(!IsInBit(id))
	{
		menu_additem(menu, "Enabled", "0")
		menu_additem(menu, "Disabled", "1", (1<<26))
	}
	
	else
	{
		menu_additem(menu, "Enabled", "0", (1<<26))
		menu_additem(menu, "Disabled", "1")
	}
	
	menu_display(id, menu)
	
	return PLUGIN_HANDLED
}

public menu_handler(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu)
		return;
	}
	
	new szInfo[4], callback, access
	menu_item_getinfo(menu, item, access, szInfo, charsmax(szInfo), .callback=callback)
	
	menu_destroy(menu)
	
	switch(str_to_num(szInfo))
	{
		case 0:
		{
			if(IsInBit(id))
			{
				client_print(id, print_chat, "Bunnyhop is already enabled for you.")
				return;
			}
			
			client_print(id, print_chat, "Bunnyhop is enabled for you now.")
			AddToBit(id)
		}
		
		case 1: 
		{
			if(!IsInBit(id))
			{
				client_print(id, print_chat, "Bunnyhop is already disabled for you.")
				return;
			}
			
			RemoveFromBit(id)
			client_print(id, print_chat, "Bunnyhop is disabled for you now.")
		}
	}
}

public Fwd_Think(id)
{
	if(!IsInBit(id))
		return;
		
	set_pev(id, pev_fuser2, 0.0)
	
	if( pev(id, pev_button) & IN_JUMP )
	{
		new flags = pev(id, pev_flags)

		if(flags & FL_WATERJUMP)
			return;
			
		if(pev(id, pev_waterlevel) >= 2 )
			return;
			
		if ( !(flags & FL_ONGROUND) )
			return;

		new Float:velocity[3]
		pev(id, pev_velocity, velocity)
		velocity[2] += 250.0
		set_pev(id, pev_velocity, velocity)

		set_pev(id, pev_gaitsequence, 6)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang2057{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
