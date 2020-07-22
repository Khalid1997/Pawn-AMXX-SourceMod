/*
**
*/
#if defined _simonapi_included
 #endinput
#endif
#define _simonapi_included

enum SimonChangedReason
{
	SCR_Generic,
	SCR_Dead,
	SCR_Disconnect,
	SCR_RoundRestart,
	SCR_Admin,
	SCR_Retire,
	SCR_TeamChange,
	SCR_DayStart
};

#define No_Simon 	0

native bool SimonAPI_SetSimon(int client, SimonChangedReason iReason);
native int SimonAPI_GetSimon();
forward void SimonAPI_OnSimonChanged(int newClient, int oldClient, SimonChangedReason iReason);

enum AccessType
{
	AT_NoAccess = 0,
	AT_Admin,
	AT_Simon
};

native AccessType SimonAPI_HasAccess(int client, bool bAllowSimon = true);

public SharedPlugin __pl_simonapi =
{
	name = "simonapi",
	file = "simonapi.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
}

#if !defined REQUIRE_PLUGIN
public __pl_simonapi_SetNTVOptional()
{
	MarkNativeAsOptional("SimonAPI_SetSimon");
	MarkNativeAsOptional("SimonAPI_GetSimon");
	
	MarkNativeAsOptional("SimonAPI_HasAccess");
}
#endif

