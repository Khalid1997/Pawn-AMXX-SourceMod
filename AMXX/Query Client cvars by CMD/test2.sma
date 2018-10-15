#include <amxmodx>
#include <amxmisc>

new g_iQueryPlayer[33]

new g_szVars[][] = {
	"fps_max",
	"cl_updaterate",
	"cl_cmdrate",
	"rate",
	"ex_interp",
	"cl_dynamiccrosshair",
	"cl_lw",
	"cl_crosshairsize"
}

public plugin_init()
{
	register_plugin "Query vars", "1.0", "Khalid :)"
	
	register_concmd("amx_getcmds", "CmdGetVars", ADMIN_RCON, "<player> - Gets player net cvars")
	register_concmd("amx_query", "CmdGetVars", ADMIN_RCON, "<player> - Gets player net cvars")
}

/*
public client_connect(id)
{
	for(new i; i < sizeof g_szVars; i++)
	{
		query_client_cvar(id, g_szVars[i], "QueryResultFunc")//, 1, iParam)
	}
}*/

public CmdGetVars(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
	{
		return PLUGIN_HANDLED
	}
	
	new szPlayerArg[32]; read_argv(1, szPlayerArg, 31)
	
	new iPlayer
	if( !( iPlayer = cmd_target(id, szPlayerArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF) ) )
	{
		return PLUGIN_HANDLED
	}
	
	if(g_iQueryPlayer[iPlayer])
	{
		console_print(id, "This player is already getting queried! Please try again later")
		return PLUGIN_HANDLED
	}
	
	new iParam[1]; iParam[0] = id
	g_iQueryPlayer[iPlayer] = 0
	for(new i; i < sizeof g_szVars; i++)
	{
		query_client_cvar(iPlayer, g_szVars[i], "QueryResultFunc", 1, iParam)
	}
	
	get_user_name(iPlayer, szPlayerArg, 31)
	console_print(id, "** Started Query on '%s':", szPlayerArg)
	
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{
	g_iQueryPlayer[id] = 0
}

public QueryResultFunc(iPlayer, const cvar[], const value[], const param[])
{
	new id = param[0]
	
	server_print("called")
	console_print(id, "%i. ^"%s^" is ^"%s^"", ( g_iQueryPlayer[iPlayer] = g_iQueryPlayer[iPlayer] + 1 ) , cvar, value)
	//console_print(0, "#%d %-0.22s = ^"%s^"", ++g_iQueryPlayer[iPlayer], cvar, value)
	
	if( g_iQueryPlayer[iPlayer] >= sizeof g_szVars)
	{
		g_iQueryPlayer[iPlayer] = 0
		
		new szName[32]; get_user_name(id, szName, 31)
		console_print(id, "** End Query on %s.", szName)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
