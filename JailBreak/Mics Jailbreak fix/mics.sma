#include <amxmodx>
#include <fakemeta>

public plugin_init()
{
	register_plugin("T's can't talk", "1.0", "Khalid :)")
	register_forward(FM_Voice_SetClientListening, "fwd_FM_Voice_SetClientListening");
}

public fwd_FM_Voice_SetClientListening(receiver, sender, bool:bListen)
{
	if(!is_user_connected(receiver) || !is_user_connected(sender))
	{
		return FMRES_IGNORED;
	}
	
	static iSpeakValue, iTeam
	
	if( (iTeam = get_user_team(sender)) == 1) // IF T
	{
		if(is_user_alive(sender))	// IF alive
		{
			if(get_user_team(receiver) == 2) // If receiver is CT
				if(is_user_alive(receiver)) // if he is alive
					iSpeakValue = 0 // don't hear t talking
				else	iSpeakValue = 1 // if he is not alive, hear them.
				
			else	iSpeakValue = 1 // not ct
		}
		
		else if(!is_user_alive(receiver)) // if not alive (Voice recevier) and not alive (Talker)
			iSpeakValue = 1		// Hear them talking
			
		else	iSpeakValue = 0		// Is live(receiver) ? Don't hear.
	}
	
	else if( iTeam == 2 )
	{
		if(is_user_alive(sender))// if the one who is talking is CT
			iSpeakValue = 1 // make everyone listen
			
		else	iSpeakValue = 1
	}
		
	engfunc(EngFunc_SetClientListening, receiver, sender, iSpeakValue);
	return FMRES_SUPERCEDE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
