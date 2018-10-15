#include <amxmodx>
#include <cstrike>
#include <fun>

#define PLUGIN "Auto nade giver"
#define VERSION "1.0"
#define AUTHOR "Khalid"

const TASKID_GIVE = 185715767886157616161515718951786151851661

#define GIVE_TIME 20.0
#define MAXIMUM_GRENADES 3

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start")
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End")
}

public LogEvent_RoundEnd()
{
	if(task_exists(TASKID_GIVE))
	{
		remove_task(TASKID_GIVE)
	}
}

public LogEvent_RoundStart()
{
	// Lets prevent it from registering the task more than 1 time.
	if(task_exists(TASKID_GIVE))
	{
		return;
	}
	
	set_task(GIVE_TIME, "Function_GiveGrenade", TASKID_GIVE, .flags = "b")
}

public Function_GiveGrenade(iTaskId)
{
	static iPlayers[32], iNum, id, iPlayerHeGrenades
	get_players(iPlayers, iNum, "ace", "CT")
	
	for(new i; i < iNum; i++)
	{
		switch( user_has_weapon( ( id = iPlayers[i] ), CSW_HEGRENADE ) )
		{
			case 1:
			{
				if( ( iPlayerHeGrenades = cs_get_user_bpammo(id, CSW_HEGRENADE ) ) >= MAXIMUM_GRENADES )
				{
					continue;
				}
				
				cs_set_user_bpammo(id, CSW_HEGRENADE, iPlayerHeGrenades + 1)
			}
			
			case 0:
			{
				give_item(id, "weapon_hegrenade")
			}
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
