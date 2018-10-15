#if defined _multimod_stocks_included_
  #endinput
#endif
#define _multimod_stocks_included_

#include <multimod>

stock MM_PrintToChat(client, String:szMessage[], any:...)
{
	static String:szBuffer[256];
	VFormat(szBuffer, sizeof szBuffer, szMessage, 3);
	Format(szBuffer, sizeof szBuffer, " \x01%s \x01%s", CHAT_PREFIX, szBuffer);

	if(client == 0)	
		PrintToChatAll(szBuffer);
	else
		PrintToChat(client, szBuffer);
}