#include <amxmodx>
#include <amxmisc>
#tryinclude <played_time>

#if !defined _played_time_included_
	native set_user_played_time(id, iNewTime)
	native get_user_played_time(id)
#endif

public plugin_init()
{
	register_plugin("Played Time: Set Time", "1.0", "Khalid :)")
	register_concmd("amx_set_time", "AdminCmdSetTime", ADMIN_RCON, "<name/@team/@all/*> <+/-/ or time to set> <time to add or take> - Sets time")
}
	
public AdminCmdSetTime(id, level, cid)
{
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED
		
	new szArg[32]; read_argv( 1, szArg, charsmax(szArg) )
	new szMark[25]; read_argv( 2, szMark, charsmax(szArg) )
	
	new iTeam, iTime
	new iPlayers[32], iNum, iPlayer, iArgs
	
	if( szArg[0] == '@' )
	{
		if( szArg[1] == 'T' && !szArg[2] )
		{
			get_players(iPlayers, iNum, "e", "TERRORIST")
			if(!iNum)	return console_print(id, "There are no players in that team")
			iTeam = 1
		}
		
		else if( szArg[1] == 'C' && szArg[2] == 'T' && !szArg[3] )
		{
			get_players(iPlayers, iNum, "e", "CT")
			if(!iNum)	return console_print(id, "There are no players in that team")
			iTeam = 2
		}
		
		else if( szArg[1] == 'A' && szArg[2] == 'L' && szArg[3] == 'L' && !szArg[4] )
		{
			get_players(iPlayers, iNum, "h")
			iTeam = 3
		}
		
		else	return console_print(id, "Invalid team")
	}
	
	else if(  szArg[0] == '*'  )
	{
		get_players(iPlayers, iNum, "h")
		
		iTeam = 3
	}
	
	else
	{
		iPlayer = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF)
		if(!iPlayer)	return console_print(id, "Player couldn't be targetted")
	}

	if( ( iArgs = read_argc() ) == 3)
	{
		if(!is_str_num(szMark))
			return console_print(id, "Invalid time input")
			
		iTime = str_to_num(szMark)
		
		if(iTeam)
		{
			for(new i; i < iNum; i++)
			{
				iPlayer = iPlayers[i]
				set_user_played_time(iPlayer, iTime)
			}
		}
		
		else	set_user_played_time(id, iTime)
	}
	
	// Here we don't need to check if the arg is more than 2 because cmd_access already checks it.
	else
	{
		new szTime[25]; read_argv(3, szTime, charsmax(szTime))
		
		if(!is_str_num(szTime))
			return console_print(id, "Invalid time input")
			
		iTime = str_to_num(szTime)
		
		if(szMark[0] == '+')
		{
			if(iTeam)
			{
				for(new i; i < iNum; i++)
				{
					iPlayer = iPlayers[i]
					set_user_played_time(iPlayer, get_user_played_time(iPlayer) + iTime)
				}
			}
			
			else set_user_played_time(iPlayer, get_user_played_time(iPlayer) + iTime)
		}
		
		else if(szMark[0] == '-')
		{
			new iCurrentTime
			if(iTeam)
			{
				for(new i; i < iNum; i++)
				{
					iPlayer = iPlayers[i]
					iCurrentTime = get_user_played_time(iPlayer) - iTime

					if(iCurrentTime < 0)
					{
						set_user_played_time(iPlayer, 0)
						continue;
					}
						
					set_user_played_time(iPlayer, iCurrentTime)
				}
			}
			
			else
			{
				iCurrentTime = get_user_played_time(iPlayer) - iTime
				
				if(iCurrentTime < 0)
					set_user_played_time(iPlayer, 0)
					
				else	set_user_played_time(iPlayer, iCurrentTime)
			}
		}
		
		else	return console_print(id, "Invalid Mark")
	}
	
	new szName[32]; get_user_name(id, szName, 31)
	client_print(0, print_chat, "ADMIN %s: %s %s%s total time%s %d", szName, ( iArgs == 3 ? "Set" : ( szMark[0] == '+' ? "Add to" : "Take from") ), ( !iTeam ? szName : ( iTeam == 3 ? "Everyone's" : ( iTeam == 2 ? "CT team players" : "TERRORIST team players" ) ) ), iTeam ? "" : "'s", iArgs == 3 ? " to" : "", iTime)
	return PLUGIN_HANDLED
}
