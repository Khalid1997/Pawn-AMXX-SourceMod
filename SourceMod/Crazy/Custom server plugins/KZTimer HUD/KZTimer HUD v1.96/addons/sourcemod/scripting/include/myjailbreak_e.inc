#if defined _myjailbreak_included_
	#endinput
#endif
#define _myjailbreak_included_

#define MYJB_VERSION "0.000000"
#define MYJB_URL_LINK	"Link ??? XDDDD"


/*********************************************************
 * Check bool is logging active
 *
 *
 * @Return			true on active, false if not
 *********************************************************/
native bool MyJailbreak_ActiveLogging();


/*********************************************************
 * Set map fog
 *
 *
 * @noreturn
 *********************************************************/
native void MyJailbreak_FogOn();


/*********************************************************
 * Remove a map fog
 *
 *
 * @noreturn
 *********************************************************/
native void MyJailbreak_FogOff();


/*********************************************************
 * Set client Beacon
 *
 *
 * @noreturn
 *********************************************************/
native void MyJailbreak_BeaconOn(int client, float interval);


/*********************************************************
 * Remove client Beacon (auto remove on mapend/playerdeath/roundend)
 *
 *
 * @noreturn
 *********************************************************/
native void MyJailbreak_BeaconOff(int client);

public SharedPlugin __pl_myjailbreak_e =
{
	name = "myjailbreak_e",
	file = "myjailbreak_e.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_myjailbreak_e_SetNTVOptional()
{
	MarkNativeAsOptional("MyJailbreak_ActiveLogging");
	MarkNativeAsOptional("MyJailbreak_FogOn");
	MarkNativeAsOptional("MyJailbreak_FogOff");
	MarkNativeAsOptional("MyJailbreak_BeaconOn");
	MarkNativeAsOptional("MyJailbreak_BeaconOff");
}
#endif