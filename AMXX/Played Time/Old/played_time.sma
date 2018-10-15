/*Played Time with "Current(Total) played Time" on server.*
*			       (nVault support)					      *
*Author:Alka											  *
*Version: 1.3											  *
*---------------------------------------------------------*
*														  *
***********************************************************/
#include <amxmodx>
#include <amxmisc>
#include <nvault>

#define PLUGIN "Played Time"
#define VERSION "1.3"
#define AUTHOR "Alka"

/*Comment this if you don't want to use nvault*/
#define NVAULT
/*Comment this line if you don't want to prune vlutdata*/
//#define PRUNE
/*Prune time:ater x time of beeing inactive,remove valutdata*/
#define PRUNE_TIME 2592000 /*30 days*/ /*Time in seconds*/

new showpt;

new g_Vault

new TotalPlayedTime[33];
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR );
	
	register_clcmd("say /my_time", "handle_say");
	register_clcmd("say /mytime", "handle_say");
	register_clcmd("say mytime", "handle_say");
	register_clcmd("say my_time", "handle_say");
	register_concmd("amx_playedtime", "admin_showptime", ADMIN_CFG," <#Player Name> - Details about playedtime.");
	register_clcmd("say /top15_time", "show_top15");
	
	showpt = register_cvar("amx_pt_mod","1");
	
	g_Vault = nvault_open("Time_played")
	
	if(g_Vault == INVALID_HANDLE)
		set_fail_state("Nvault returned invalid handle")
	
}

public plugin_natives()
{
	register_library("played_time")
	register_native("set_user_ptime", "_set_user_ptime", 1)
	register_native("get_user_ptime", "_get_user_ptime", 1)
}

public handle_say(id) 
{
	/*static said[9]
	read_argv(1, said, 8);
	
	if(equali(said, "!ptime"))
	{*/
	static ctime[64], timep;
		
	timep = get_user_time(id, 1) / 60;
	get_time("%H:%M:%S", ctime, 63);
		
	switch(get_pcvar_num(showpt))
	{
		case 0: return PLUGIN_HANDLED;
				
		case 1 :
		{
			client_print(id, print_chat, "[PT] You have been playing on the server for: %d minute%s.", timep, timep == 1 ? "" : "s");
			#if defined NVAULT 
			client_print(id, print_chat, "[PT] Your total played time on the server: %d minute%s.", timep+TotalPlayedTime[id], timep+TotalPlayedTime[id] == 1 ? "" : "s");
			#endif
			client_print(id, print_chat, "[PT] Current time: %s", ctime);
		}
		case 2 :
		{
			set_hudmessage(255, 50, 50, 0.34, 0.50, 0, 6.0, 4.0, 0.1, 0.2, -1);
			show_hudmessage(id, "[PT] You have been playing on the server for: %d minute%s.^n[PT]Current time: %s", timep, timep == 1 ? "" : "s", ctime);
		}
	}
	return PLUGIN_HANDLED;
	/*}
	return PLUGIN_CONTINUE;*/
}

public admin_showptime(id,level,cid) 
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	static arg[32];
	read_argv(1, arg, 31);
	
	new player = cmd_target(id, arg, 2);
	
	if(!player)
		return PLUGIN_HANDLED;
	
	static name[32];
	get_user_name(player, name, 31);
	
	static timep, ctime[64];
	
	timep = get_user_time(player, 1) / 60;
	get_time("%H:%M:%S", ctime, 63);
	
	console_print(id, "-----------------------(#PlayedTime#)-----------------------");
	console_print(id, "[PT]%s have been playing on the server for %d minute%s.",name, timep, timep == 1 ? "" : "s");
	#if defined NVAULT
	console_print(id, "[PT]%s's total played time on the server %d minute%s.",name, timep+TotalPlayedTime[player], timep == 1 ? "" : "s"); // new
	#endif
	console_print(id, "[PT]Current time: %s", ctime);
	console_print(id, "-----------------------------------------------------------------");
	
	return PLUGIN_HANDLED;
}

#if defined NVAULT
public client_disconnect(id)
{
	TotalPlayedTime[id] = TotalPlayedTime[id] + (get_user_time(id)/60);
	SaveTime(id, TotalPlayedTime[id]);
}
#endif

#if defined NVAULT
public client_putinserver(id)
{
	TotalPlayedTime[id] = LoadTime(id);
}
#endif

#if defined NVAULT
public LoadTime( id ) 
{
	//new valut = nvault_open("Time_played")
	
	new authid[33];
	new vaultkey[64], vaultdata[64];
	
	get_user_name(id, authid, 32);
	
	format(vaultkey, 63, "TIMEPLAYED%s", authid);
	
	nvault_get(g_Vault, vaultkey, vaultdata, 63);
	
	return str_to_num(vaultdata);
}
#endif

#if defined NVAULT
public SaveTime(id,PlayedTime)
{
	new authid[33];
	new vaultkey[64], vaultdata[64];
	
	get_user_name(id, authid, 32);
	
	format(vaultkey, 63, "TIMEPLAYED%s", authid); 
	format(vaultdata, 63, "%d", PlayedTime); 
	
	nvault_set(g_Vault, vaultkey, vaultdata);
}
#endif

#if defined PRUNE
public prune()
{	
	if(g_Vault == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle");
	
	nvault_prune(g_Vault, 0, get_systime() - PRUNE_TIME);
}
#endif


public plugin_end()
{
	#if defined PRUNE
	prune()
	#endif
	nvault_close(g_Vault)
}


#if defined NVAULT
public show_top15(id)
{
	new i, count;
	static sort[33][2], maxPlayers;
	
	if(!maxPlayers) maxPlayers = get_maxplayers();
	
	for(i=1;i<=maxPlayers;i++)
	{
		sort[count][0] = i;
		sort[count][1] = TotalPlayedTime[i] + (get_user_time(i, 1) / 60);
		count++;
	}
	
	SortCustom2D(sort,count,"stats_custom_compare");
	
	new motd[1024], len	
	
	len = format(motd, 1023,"<body bgcolor=#000000><font color=#FFB000><pre>")
	len += format(motd[len], 1023-len,"%s %-22.22s %3s^n", "#", "Name", "Time")
	
	new players[32], num
	get_players(players, num)
	
	new b = clamp(count,0,15)
	
	new name[32], player
	
	for(new a = 0; a < b; a++)
	{
		player = sort[a][0]
		
		get_user_name(player, name, 31)		
		len += format(motd[len], 1023-len,"%d %-22.22s %d^n", a+1, name, sort[a][1])
	}
	
	
	
	len += format(motd[len], 1023-len,"</body></font></pre>")
	show_motd(id, motd, "Played-Time Top 15")
	
	return PLUGIN_CONTINUE
}
#endif

public stats_custom_compare(elem1[],elem2[])
{
	if(elem1[1] > elem2[1]) return -1;
	else if(elem1[1] < elem2[1]) return 1;
		
	return 0;
}

public _set_user_ptime(id, iNum)
{
	if(!id || !is_user_connected(id))
		return -1
	
	
	TotalPlayedTime[id] = iNum
	return 1
}

public _get_user_ptime(id)
{
	if(!id || !is_user_connected(id))
		return -1
	
	return TotalPlayedTime[id]
}
