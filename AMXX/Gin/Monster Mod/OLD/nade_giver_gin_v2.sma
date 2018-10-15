#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#define PLUGIN "Auto nade giver"
#define VERSION "1.0"
#define AUTHOR "Khalid"

new const TASKID_GIVE = 1857157678861576161

#define GIVE_TIME 20.0
#define MAXIMUM_GRENADES 3

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	//register_logevent("LogEvent_RoundStart", 2, "1=Round_Start")
	//register_logevent("LogEvent_RoundEnd", 2, "1=Round_End")
	RegisterHam(Ham_Spawn, "player", "fw_StartGiveNade", 1);
	RegisterHam(Ham_Killed, "player", "fw_StopGiveNade", 1);
}

public fw_StopGiveNade(id)
{
	if(task_exists(TASKID_GIVE + id))
	{
		remove_task(TASKID_GIVE + id);
	}
}

public fw_StartGiveNade(id)
{
	// Lets prevent it from registering the task more than 1 time.
	if(task_exists(TASKID_GIVE + id))
	{
		remove_task(TASKID_GIVE + id);
		return;
	}
	
	set_task(GIVE_TIME, "Function_GiveGrenade", TASKID_GIVE + id, .flags = "b")
}

public Function_GiveGrenade(iTaskId)
{
	static id, iPlayerHeGrenades;
	
	id = iTaskId - TASKID_GIVE

	switch( user_has_weapon( ( id ), CSW_HEGRENADE ) )
	{
		case 1:
		{
			if( ( iPlayerHeGrenades = cs_get_user_bpammo(id, CSW_HEGRENADE ) ) >= MAXIMUM_GRENADES )
			{
				return;
			}
				
			cs_set_user_bpammo(id, CSW_HEGRENADE, iPlayerHeGrenades + 1)
		}
			
		case 0:
		{
			give_item(id, "weapon_hegrenade")
		}
	}
}
