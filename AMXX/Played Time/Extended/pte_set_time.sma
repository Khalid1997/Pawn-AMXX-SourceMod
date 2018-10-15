#include <amxmodx>
#include <amxmisc>
#include <played_time>

public plugin_init()
{
	register_plugin("Played Time: Set Time", "1.0b", "Khalid :)")
	register_concmd("amx_set_time", "AdminCmdSetTime", ADMIN_RCON, "<name/@team/@all/*> <+/-/ or time to set> <time to add or take> - Sets time")
}
	
public AdminCmdSetTime(id, level, cid)
{
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED
		
	new szArg[32]; read_argv( 1, szArg, charsmax(szArg) )
	new szMark[25]; read_argv( 2, szMark, charsmax(szArg) )
	
	new szOtherName[32];
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
		
		get_user_name(iPlayer, szOtherName, charsmax(szOtherName));
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
				pt_set_user_played_time(iPlayer, iTime * 60)
			}
		}
		
		else	pt_set_user_played_time(iPlayer, iTime * 60)
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
					pt_set_user_played_time(iPlayer, pt_get_user_played_time(iPlayer) + (iTime * 60) )
				}
			}
			
			else pt_set_user_played_time(iPlayer, pt_get_user_played_time(iPlayer) + (iTime * 60))
		}
		
		else if(szMark[0] == '-')
		{
			new iCurrentTime
			if(iTeam)
			{
				for(new i; i < iNum; i++)
				{
					iPlayer = iPlayers[i]
					iCurrentTime = pt_get_user_played_time(iPlayer) - (iTime * 60)

					if(iCurrentTime < 0)
					{
						pt_set_user_played_time(iPlayer, 0)
						continue;
					}
						
				}
			}
			
			else
			{
				iCurrentTime = pt_get_user_played_time(iPlayer) - (iTime * 60)
				
				if(iCurrentTime < 0)
					pt_set_user_played_time(iPlayer, 0)
					
				else	pt_set_user_played_time(iPlayer, iCurrentTime)
			}
		}
		
		else	return console_print(id, "Invalid Mark")
	}
	
	new szName[32]; get_user_name(id, szName, 31)
	client_print(0, print_chat, "ADMIN %s: %s %s%s total time%s %d", szName, ( iArgs == 3 ? "Set" : ( szMark[0] == '+' ? "Add to" : "Take from") ), ( !iTeam ? szOtherName : ( iTeam == 3 ? "Everyone's" : ( iTeam == 2 ? "CT team players" : "TERRORIST team players" ) ) ), iTeam ? "" : "'s", iArgs == 3 ? " to" : "", iTime)
	return PLUGIN_HANDLED
}
