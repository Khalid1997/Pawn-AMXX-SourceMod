#if defined _bbshop_const_included
  #endinput
#endif
#define _bbshop_const_included

const BB_TEAM_ZOMBIES 	= (1<<1)
const BB_TEAM_HUMANS 	= (1<<0)
const BB_TEAM_ANY	= (1<<2)

new const PREFIX[] = "[BB SHOP]"

stock ColorChat(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1, fullmsg[220]
	vformat(msg,190,input,3);
	
	formatex(fullmsg, charsmax(fullmsg), "^3%s ^4%s", PREFIX, msg)

	if (id) players[0] = id
	
	else get_players(players,count,"ch");
	
	for (new i=0;i<count;i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
