/*
**
*/
#if defined _thirdperson_included
 #endinput
#endif
#define _thirdperson_included

enum ThirdPersonType
{
	TPT_None = 0,	// Only for locking
	TPT_FirstPerson,
	TPT_ThirdPerson,
	TPT_ThirdPerson_Mirror
};

native void ThirdPerson_SetGlobalLockMode(ThirdPersonType iLockMode);
native ThirdPersonType ThirdPerson_GetGlobalLockMode();
	
native ThirdPersonType ThirdPerson_GetClientCurrentThirdPerson(int client);
native bool ThirdPerson_SetClientCurrentThirdPerson(int client, ThirdPersonType type = TPT_None);

native ThirdPersonType ThirdPerson_GetClientChosenThirdPerson(int client);
native void ThirdPerson_SetClientChosenThirdPerson(int client, ThirdPersonType type = TPT_None);

native ThirdPersonType ThirdPerson_GetClientThirdPersonLockMode(int client);
native void ThirdPerson_SetClientThirdPersonLockMode(int client, ThirdPersonType iLockType);

forward void ThirdPerson_OnClientChangeMode(int client, ThirdPersonType type);
forward void ThirdPerson_OnGlobalLockChanged(ThirdPersonType iNewLockMode, ThirdPersonType iOldLockMode);

public SharedPlugin __pl_thirdperson =
{
	name = "thirdperson",
	file = "thirdperson.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
}

#if !defined REQUIRE_PLUGIN
public void __pl_thirdperson_SetNTVOptional()
{
	MarkNativeAsOptional("ThirdPerson_SetGlobalLockMode");
	MarkNativeAsOptional("ThirdPerson_GetGlobalLockMode");
	
	MarkNativeAsOptional("ThirdPerson_GetClientThirdPerson");
	MarkNativeAsOptional("ThirdPerson_SetClientThirdPerson");
	
	MarkNativeAsOptional("ThirdPerson_GetClientThirdPersonLockMode");
	MarkNativeAsOptional("ThirdPerson_SetClientThirdPersonLockMode");
}
#endif
