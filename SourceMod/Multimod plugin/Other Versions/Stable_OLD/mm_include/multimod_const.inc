#if defined _multimod_const_included_
  #endinput
#endif
#define _multimod_const_included_


#define	CHAT_PREFIX			"\x04[MultiMod]"

#define ACCESS_FLAG_BIT 		ADMFLAG_ROOT

#define MAX_MOD_NAME 			30
#define MAX_MODS 				8

#define VOTING_TIME 			17
#define MAX_VOTE_MAPS 			5

//#define BLOCK_CURRENT_MOD_IN_VOTE

stock MM_PrintToChat(client, String:szMessage[], any:...)
{
	static String:szBuffer[256]
	VFormat(szBuffer, sizeof szBuffer, szMessage, 3);
	Format(szBuffer, sizeof szBuffer, " \x01%s \x01%s", CHAT_PREFIX, szBuffer);

	if(client == 0)	
		PrintToChatAll(szBuffer);
	else
		PrintToChat(client, szBuffer);
}