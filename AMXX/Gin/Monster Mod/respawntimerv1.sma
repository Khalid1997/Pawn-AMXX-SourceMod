#include <amxmodx>
#include <hamsandwich>
#include <cstrike>

#define PLUGIN "New Plugin"
#define VERSION "1.0"
#define AUTHOR "Author"

#define TIMER_TASK        654321
#define RESPAWN_TASK      098765

new g_counter[33]
new g_respawn 
new g_money
new g_SyncRespawnTimer

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1)
	RegisterHam(Ham_Killed, "player", "Killed", 1)
	register_event( "TeamInfo", "JoinTeam", "a")
	
	g_respawn = register_cvar("amx_respawn_time","3.0")
	g_money = register_cvar("amx_respawn_money","5000")
	
	g_SyncRespawnTimer = CreateHudSyncObj()
}

public JoinTeam() 
{
	new Client = read_data(1)
	static user_team[32]
	
	read_data(2, user_team, 31)
	
	if(!is_user_connected(Client))
		return PLUGIN_HANDLED
	
	switch(user_team[0])
	{
		case 'C': set_task(1.0,"TimeCounter",Client + TIMER_TASK,_,_,"a",get_pcvar_num(g_respawn))
			
		case 'T': set_task(1.0,"TimeCounter",Client + TIMER_TASK,_,_,"a",get_pcvar_num(g_respawn))
			
		case 'S': 
		{
			if(task_exists(Client + TIMER_TASK))
			{
				remove_task(Client + TIMER_TASK)
				g_counter[Client] = 0
			} 
		}
	}
	return PLUGIN_HANDLED
}

public Spawn(Client)
{
	if (is_user_alive(Client))
	{
		new iMoney = get_pcvar_num(g_money)
		new iPlayerMoney = cs_get_user_money(Client)
		if(iPlayerMoney + iMoney <= 16000)
			cs_set_user_money(Client, iPlayerMoney + iMoney) 
		else
			cs_set_user_money(Client, 16000) 
		if(task_exists(Client + TIMER_TASK))
		{
			remove_task(Client + TIMER_TASK)
			g_counter[Client] = 0
		} 
	}
}

public Respawn(Client)
{
	Client -= RESPAWN_TASK
	if (!is_user_alive(Client) && is_user_connected(Client))
		if( cs_get_user_team(Client) != CS_TEAM_SPECTATOR )
		ExecuteHamB(Ham_CS_RoundRespawn, Client)
}

public Killed(Client)
{
	if(get_pcvar_num(g_respawn) != 0)
	{
		set_task(1.0,"TimeCounter",Client + TIMER_TASK,_,_,"a",get_pcvar_num(g_respawn))
	}
}

public TimeCounter(Client) 
{
	Client -= TIMER_TASK
	g_counter[Client]++
	
	new Float:iRespawnTime = get_pcvar_float(g_respawn) - g_counter[Client]
	new Float:fSec
	fSec = iRespawnTime 
	
	//set_hudmessage( random_num(0,255), random_num(0,255), random_num(0,255), -1.0, 0.25, _, _, 1.0, _, _, -1)
	//ShowSyncHudMsg( Client, g_SyncRespawnTimer, "You Will Respawn In %d Seconds", floatround( fSec ) )
	client_print(Client, print_center, "You Will Respawn In %d Seconds", floatround( fSec ) )
	
	if(g_counter[Client] == get_pcvar_num(g_respawn))
	{
		set_task(0.1, "Respawn", Client + RESPAWN_TASK)
		g_counter[Client] = 0
	}
}  
