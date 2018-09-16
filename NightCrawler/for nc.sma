#include <amxmodx>
#include <fakemeta>

#define TASKID_COUNT_DOWN 1175051

new g_pCounter;
new g_iCountDown;
new g_iWork

public plugin_init()
{
	register_clcmd("say /test", "test")
	
	g_pCounter = register_cvar("nc_countdown_time", "15");
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0");
	
	if( engfunc(EngFunc_FindEntityByString, -1, "classname", "func_breakable") )
	{
		g_iWork = 1;
	}
}

public eNewRound()
{
	if(!g_iWork)
	{
		return;
	}
	
	if(task_exists(TASKID_COUNT_DOWN))
	{
		remove_task(TASKID_COUNT_DOWN);
	}
	
	set_task(1.0, "CountDown", TASKID_COUNT_DOWN,_,_, "a", ( g_iCountDown = get_pcvar_num(g_pCounter) + 1) - 1);
}

public CountDown(iTaskId)
{
	if(--g_iCountDown)
	{
		set_hudmessage(255, 0, 255, -1.0, 0.25, 0, 0.0, 1.0, 0.1, 0.0, -1);
		show_hudmessage(0, "Nightcrawlers will be release in^n%d", g_iCountDown);
		return;
	}
	
	new iEnt
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "func_breakable") ) )
	{
		// FIRST WAY
		//entity_get_string(ent, EV_SZ_targetname, szTargetName, charsmax(szTargetName))
		//Health = entity_get_float(ent, EV_FL_health)
		//server_print("Target name %s ... HP: %f", szTargetName, Health)
		//ExecuteHam(Ham_TakeDamage, ent, 0, 0, Health, DMG_BLAST);
		
		// SECOUND WAY
		dllfunc(DLLFunc_Use, iEnt)
		
		// OTHER
		//set_pev(ent, pev_solid, SOLID_NOT)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
