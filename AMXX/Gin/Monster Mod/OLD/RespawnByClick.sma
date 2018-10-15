#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#define TASKID_TIMER 178561

#define TIMER 3.0
new Float:g_flCounter[33] = 0.0;
new bool:g_bAllowRespawn = false;

new gAlive;
#define SetDead(%1) ( gAlive &= ~(1<<%1) )
#define IsAlive(%1) ( gAlive & (1<<%1) )
#define SetAlive(%1) ( gAlive |= (1<<%1) )

public plugin_init()
{
	register_plugin "Respawn by click", "1.0", "Khalid";
	
	register_logevent("RoundEnd", 2, "1=Round_End");
	register_logevent("RoundStart", 2, "1=Round_Start");
	
	register_forward(FM_CmdStart, "fw_CmdStart", 1);
	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1);
	RegisterHam(Ham_Killed, "player", "fw_Killed", 1);
}

public RoundEnd()
{
	g_bAllowRespawn = false;
}

public RoundStart()
{
	g_bAllowRespawn = true;
}

public client_disconnect(id)
{
	SetDead(id);
	
	if(task_exists(id + TASKID_TIMER))
	{
		remove_task(id + TASKID_TIMER);
	}
}

public client_putinserver(id)
{
	SetDead(id);
	new Float:flGameTime = get_gametime();
	g_flCounter[id] =  flGameTime * flGameTime; // Do not allow respawn for people who has just connected
}

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	SetAlive(id);
}

public fw_Killed(id, iKiller, iShouldGib)
{
	SetDead(id);
	
	if(!g_bAllowRespawn)
	{
		return;
	}
	
	g_flCounter[id] = TIMER + get_gametime();

	set_task(0.1, "TaskTimer", id + TASKID_TIMER, .flags = "b");
}

public TaskTimer(iTaskId)
{
	if(!g_bAllowRespawn)
	{
		remove_task(iTaskId);
		return;
	}
	
	new id = iTaskId - TASKID_TIMER;
	
	if(IsAlive(id))
	{
		remove_task(iTaskId);
		return;
	}
	
	if(g_flCounter[id] - get_gametime() > 0.0)
	{
		set_hudmessage(255, 180, 30, -1.0, 0.15, 0, 0.0, 0.1, 0.0, 0.0, -1);
		show_hudmessage(id, "You can respawn in %0.2f", g_flCounter[id] - get_gametime());
	} else {
		set_hudmessage(255, 180, 30, -1.0, 0.15, 0, 0.0, 10.0, 0.1, 0.1, -1);
		show_hudmessage(id, "You can now click ATTACK1 button to respawn");
		remove_task(iTaskId);
	}
}	

public fw_CmdStart(id, hUc, iSeed)
{
	if(is_user_bot(id))
	{
		return;
	}
	
	if(!g_bAllowRespawn)
	{
		return;
	}
	
	if(IsAlive(id))
	{
		return;
	}
	
	if(g_flCounter[id] > get_gametime())
	{
		return;
	}
	
	static iButtons;
	iButtons = get_uc(hUc, UC_Buttons);
	
	if(iButtons & IN_ATTACK)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
