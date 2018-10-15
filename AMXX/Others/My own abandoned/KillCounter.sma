#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Kill Counter"
#define VERSION "1.0"
#define AUTHOR "Khalid"

new g_iTotalKills = 0
new szNum[10]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("DeathMsg", "Event_Death", "a")
	//register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	
	formatex(szNum, charsmax(szNum), "%04d", g_iTotalKills)
	
	set_task(0.2, "Update_Hud", .flags="b")
}

public Event_Death()
{
	new iKiller = read_data(1)
	new iVictim = read_data(2)
	
	static sWeapon[16]; 
	read_data( 4, sWeapon, sizeof( sWeapon ) - 1 );
	
	if(
		( iKiller == iVictim && equal(sWeapon, "world", 5) /* 1 */ ) ||
		!iKiller && 
		(
			equal( sWeapon, "world", 5 ) || 
			equal( sWeapon, "door", 4 ) ||
			equal( sWeapon, "trigger_hurt", 12 )
		)
	)
		return;
	
	if(iKiller != iVictim)
		g_iTotalKills++
	
	formatex(szNum, charsmax(szNum), "%04d", g_iTotalKills)  
}

/*public Event_NewRound()
{
g_iTotalKills = 0
}*/

public Update_Hud()
{    
	set_hudmessage(255, 255, 255, -1.0, 0.1, 0, 0.0, 0.2, 0.2, 0.2, 3)
	show_hudmessage(0, "Total Kills: %s", szNum)
}  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
