#include <amxmodx>
#include <fakemeta>

new const VERSION[] = "1.0"

public plugin_precache()
{
	new szMapName[50]; get_mapname(szMapName, charsmax(szMapName))
	
	if(containi(szMapName, "surf") == -1)
	{
		set_fail_state("Not a surf map")
	}
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
	if(pev_valid(ent))
	{
		set_pev(ent, pev_solid, SOLID_NOT)
		engfunc(EngFunc_SetOrigin, ent, Float:{ 8192.0,8192.0,8192.0 } )
		dllfunc(DLLFunc_Spawn, ent)
	}
}

public plugin_init()
{
	register_plugin("Round Ender", VERSION, "author")
	
	register_message(get_user_msgid("SendAudio"), "message_SendAudio")
	register_message(get_user_msgid("Scenario"), "message_Scenario")
	register_message(get_user_msgid("TextMsg"), "message_SayText")
}

public message_SendAudio(msg_id, msg_dest, id)
{
	static szSoundCode[35]
	get_msg_arg_string(2, szSoundCode, charsmax(szSoundCode))
	
	if(equal(szSoundCode, "%!MRAD_terwin") && AllowDraw())
		set_msg_arg_string(2, "%!MRAD_rounddraw")
}

AllowDraw()
{
	static iPlayers[32], iNum, iCTNum
	get_players(iPlayers, iNum, "ae", "TERRORIST")
	
	get_players(iPlayers, iCTNum, "ae", "CT")
	
	if(iNum && iCTNum)// || iCTNum && !iNum || !iCTNum && iNum)
		return 1
		
	return 0
}

public message_SayText(msg_id,msg_dest, id)
{
	if( !id && get_msg_arg_int(1) == print_center ) 
	{
		static szCode[50]
		get_msg_arg_string(2, szCode, charsmax(szCode))
		
		if(equal(szCode, "#Hostages_Not_Rescued"))
			set_msg_arg_string(2, "#Round_Draw")
	}
}

public message_Scenario()
{
	static szHud[50]
	get_msg_arg_string(2, szHud, charsmax(szHud))
	return ( ( equal(szHud, "hostage1") && get_msg_arg_int(1) == 1 ) ?  PLUGIN_HANDLED : PLUGIN_CONTINUE )
}
