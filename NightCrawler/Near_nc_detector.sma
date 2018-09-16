#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

// --------------------------------------------------------------------
#define MAX_RADIUS    600.0        // OR distance, doesn't matter
#define DECREMENT_AT_TIME 67

#define TASK_HUD    81732512371
#define NC_TEAM    2        // 1 for Terrorist, 2 for CTs
#define UPDATE_TIME 0.5
// --------------------------------------------------------------------

#define IsAlive(%1) (gAlive & (1<<%1))
#define SetAlive(%1) (gAlive |= (1<<%1))
#define SetNotAlive(%1) (gAlive &= ~(1<<%1))

new iMaxRadius
new g_szPlayerMessage[33][50]
new g_iMaxPlayers
new gAlive
new g_szDefaultMessage[30]

public plugin_init()
{
	register_plugin("Near NC detector", "1.0", "Khalid :)")
	
	RegisterHam(Ham_Spawn, "player", "Fwd_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "Fwd_Killed", 0)
	
	g_iMaxPlayers = get_maxplayers()
	
	iMaxRadius = floatround(MAX_RADIUS)
	new iNum = iMaxRadius / DECREMENT_AT_TIME
	
	add(g_szDefaultMessage, charsmax(g_szDefaultMessage), "[")
	while(iNum)
	{
		--iNum
		add(g_szDefaultMessage, charsmax(g_szDefaultMessage), "-")
	}
	add(g_szDefaultMessage, charsmax(g_szDefaultMessage), "]")
}

public client_disconnect(id)
{
	id += TASK_HUD
	
	if(task_exists(id))
	{
		remove_task(id)
	}
}

public Fwd_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	if(get_user_team(id) == NC_TEAM)
	{
		return;
	}
	
	SetAlive(id)
	set_task(UPDATE_TIME, "ShowHud", TASK_HUD + id, .flags = "b")
}

public Fwd_Killed(id)
{
	SetNotAlive(id)
	if(task_exists(id + TASK_HUD))
		remove_task(id + TASK_HUD)
}

public ShowHud(taskid)
{
	new id = taskid - TASK_HUD
	
	if(!IsAlive(id))
	{
		remove_task(taskid)
		return;
	}
	
	static Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	
	static iEnt
	
	static iColor[3]; iColor = { 0, 0, 0 }
	
	iEnt = get_nearest_player(id);

	distance_rate(id, iEnt, iColor)
	
	set_hudmessage(iColor[0], iColor[1], iColor[2], -1.0, 0.60, 0, 0.0, UPDATE_TIME - 0.1, 0.0, 0.1)
	show_hudmessage(id, iEnt ? g_szPlayerMessage[id] : g_szDefaultMessage)
}

stock get_nearest_player(id)
{
	static Float:vOrigin[3], iEnt;
	pev(id, pev_origin, vOrigin);
	static Float:flDistance, Float:flNearestDistance = 99999.0, iNearestPlayer;
	
	flNearestDistance = 99999.0; iEnt = 0, iNearestPlayer = 0
	// Nearest player
	while( (iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, MAX_RADIUS ) ) )
	{
		if(iEnt > g_iMaxPlayers || iEnt == id)
		{
			continue;
		}
		
		if(!IsAlive(id))
		{
			continue;
		}
		
		if(get_user_team(iEnt) != NC_TEAM)
		{
			continue;
		}
		
		if( ( flDistance = entity_range( id, iEnt ) ) < flNearestDistance )
		{
			flNearestDistance = flDistance
			iNearestPlayer = iEnt
		}
	}

	return iNearestPlayer;
}

stock distance_rate(id, iEnt, iColor[3])
{
	static Float:Origin1[3], Float:Origin2[3]; 
	
	pev(iEnt, pev_origin, Origin1);
	pev(iEnt, pev_origin, Origin2)
	
	new Float:flDistance = get_distance_f(Origin1, Origin2)
	
	if(flDistance > MAX_RADIUS)
		return;
	
	new Float:flNewDistance = MAX_RADIUS - DECREMENT_AT_TIME, Float:flOldDistance  = MAX_RADIUS
	
	new k = 1
	while( flNewDistance >= 0 )
	{
		if( flNewDistance <= flDistance <= flOldDistance )
			break;
		
		flOldDistance = flNewDistance; flNewDistance -= DECREMENT_AT_TIME
		++k
	}
	
	set_player_msg_string(id, k, iColor)
}

public set_player_msg_string(id, iNum, iColor[3])
{
	setc(g_szPlayerMessage[id], charsmax(g_szPlayerMessage), 0)
	
	static iLeft, iAdd
	new szAdd[30], szMark[30]
	if(iNum < ( iAdd = (iMaxRadius / DECREMENT_AT_TIME) ) )
	{
		iLeft = iAdd - iNum
		iAdd = iLeft / 2
		
		while(iAdd > -1)
		{
			szAdd[iAdd] = '-'
			
			--iAdd
		}
	}
	
	while(iNum > -1)
	{
		szMark[iNum] = '!'
		--iNum
	}
	
	if(iLeft == 1 || !iLeft)
	{
		iColor = { 255, 0, 0 }
	}
	
	else if( 1 < iLeft <= ( (iMaxRadius / DECREMENT_AT_TIME) / 2 ) )
	{
		iColor = { 255, 255, 0 }
	}
	
	else
	{
		iColor = { 50, 205, 50 }
	}
	
	formatex(g_szPlayerMessage[id], charsmax(g_szPlayerMessage[]), "[%s%s%s]", szAdd, szMark, szAdd)
}  
