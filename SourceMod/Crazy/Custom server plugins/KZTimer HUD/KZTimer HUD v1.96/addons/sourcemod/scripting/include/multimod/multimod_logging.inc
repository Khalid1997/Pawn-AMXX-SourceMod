/*
**
*/
#if defined _multimod_logging_included
 #endinput
#endif
#define _multimod_logging_included

native void MultiMod_PrintToChatAll(char[] szMessage, any ...);
native void MultiMod_PrintToChat(int client, char[] szMessage, any ...);

native void MultiMod_LogMessage(char[] szMessage, any ...);

native void MultiMod_PrintDebug(char[] szMessage, any ...);


public SharedPlugin __pl_multimod_logging =
{
	name = MM_LIB_LOGGING,
	file = "multimod_logging.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_multimod_logging_SetNTVOptional()
{
	MarkNativeAsOptional("MultiMod_PrintToChatAll");
	MarkNativeAsOptional("MultiMod_PrintToChat");
	
	MarkNativeAsOptional("MultiMod_LogMessage");
	MarkNativeAsOptional("MultiMod_PrintDebug");
}
#endif