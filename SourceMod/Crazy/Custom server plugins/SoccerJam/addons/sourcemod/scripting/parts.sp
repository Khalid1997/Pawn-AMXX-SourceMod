
Handle CustomForwardsArray
Handle CustomForwardNamesArray

PrivateForward InitPartForward
PrivateForward OnMapStartForward
PrivateForward OnEntityCreatedForward
PrivateForward OnWeaponDropForward
PrivateForward OnTerminateRoundForward
PrivateForward OnPlayerRunCmdForward
PrivateForward OnClientDisconnectForward

// SJ
#define PART_NAME_LENGTH 16

Handle PartsNamesArray = INVALID_HANDLE

void InitPartSystem()
{
	PartsNamesArray = CreateArray(PART_NAME_LENGTH)
	CustomForwardsArray = CreateArray()
	CustomForwardNamesArray = CreateArray(MAX_NAME_LENGTH)

	CreateGameForwards()
}

void CreateGameForwards()
{
	InitPartForward = CreateForward(ET_Ignore)
	OnMapStartForward = CreateForward(ET_Ignore)
	OnEntityCreatedForward = CreateForward(ET_Ignore, Param_Cell, Param_String)
	OnWeaponDropForward = CreateForward(ET_Event, Param_Cell, Param_Cell)
	OnTerminateRoundForward = CreateForward(ET_Event, Param_FloatByRef, Param_CellByRef)
	OnPlayerRunCmdForward = CreateForward(ET_Event, Param_Cell, Param_CellByRef)
	OnClientDisconnectForward = CreateForward(ET_Ignore, Param_Cell)
}

void RegisterCustomForward(Handle fwd, const char[] postfix)
{
	PushArrayCell(CustomForwardsArray, fwd)
	PushArrayString(CustomForwardNamesArray, postfix)
}

void RegisterPart(const char partName[PART_NAME_LENGTH])
{
	PushArrayString(PartsNamesArray, partName)
	HookPartForward(InitPartForward, partName, "Init")
	HookPartForward(OnMapStartForward, partName, "OnMapStart")
	HookPartForward(OnEntityCreatedForward, partName, "OnEntityCreated")
	HookPartForward(OnWeaponDropForward, partName, "OnWeaponDrop")
	HookPartForward(OnTerminateRoundForward, partName, "OnTerminateRound")
	HookPartForward(OnPlayerRunCmdForward, partName, "OnPlayerRunCmd")
	HookPartForward(OnClientDisconnectForward, partName, "OnClientDisconnect")

	HookPartEvent("cs_match_end_restart", partName, "MatchEndRestart")
	HookPartEvent("cs_win_panel_round", partName, "WinPanelRound")
	HookPartEvent("player_activate", partName, "PlayerActivate")
	HookPartEvent("player_hurt", partName, "PlayerHurt")
	HookPartEvent("player_spawn", partName, "PlayerSpawn")
	HookPartEvent("player_team", partName, "PlayerTeam")
	HookPartEvent("player_death", partName, "PlayerDeath")
	HookPartEvent("player_disconnect", partName, "PlayerDisconnect")
	HookPartEvent("round_end", partName, "RoundEnd")
	HookPartEvent("round_freeze_end", partName, "RoundFreezeEnd")
	HookPartEvent("round_prestart", partName, "RoundPreStart")
	HookPartEvent("round_start", partName, "RoundStart")	
}

void InitParts()
{
	Call_StartForward(InitPartForward)
	Call_Finish()

	int partsCount = GetArraySize(PartsNamesArray)
	char partName[PART_NAME_LENGTH];
	for (int i = 0; i < partsCount; i++)
	{
		GetArrayString(PartsNamesArray, i, partName, sizeof(partName))
		HookCustomForwards(partName)
	}
}

void HookCustomForwards(const char partName[PART_NAME_LENGTH])
{
	int forwardsCount = GetArraySize(CustomForwardsArray)
	Handle fwd;
	char postfix[MAX_NAME_LENGTH]
	
	for (int i = 0; i < forwardsCount; i++)
	{
		fwd = GetArrayCell(CustomForwardsArray, i)
		GetArrayString(CustomForwardNamesArray, i, postfix, sizeof(postfix))
		HookPartForward(fwd, partName, postfix)
	}
}

void HookPartForward(Handle fwd, const char partName[PART_NAME_LENGTH], const char[] postfix)
{
	char partFunctionName[MAX_NAME_LENGTH]
	Format(partFunctionName, MAX_NAME_LENGTH, "%s_%s", partName, postfix);
	Function func = GetFunctionByName(INVALID_HANDLE, partFunctionName)
	
	if (func != INVALID_FUNCTION)
	{
		AddToForward(fwd, INVALID_HANDLE, func);
	}
}

void HookPartEvent(const char[] hookName, const char partName[PART_NAME_LENGTH], const char[] postfix)
{
	char partFunctionName[MAX_NAME_LENGTH]
	Format(partFunctionName, MAX_NAME_LENGTH, "%s_Event_%s", partName, postfix);
	Function func = GetFunctionByName(INVALID_HANDLE, partFunctionName)
	if (func != INVALID_FUNCTION)
	{
		HookEventEx(hookName, view_as<EventHook>(func))
	}

	char partPreFunctionName[MAX_NAME_LENGTH]
	Format(partPreFunctionName, MAX_NAME_LENGTH, "%s_Event_Pre%s", partName, postfix);
	Function preFunction = GetFunctionByName(INVALID_HANDLE, partPreFunctionName)
	if (preFunction != INVALID_FUNCTION)
	{
		HookEventEx(hookName, view_as<EventHook>(preFunction), EventHookMode_Pre)
	}
}

stock void FireOnMapStart()
{
	Call_StartForward(OnMapStartForward)
	Call_Finish()
}

stock void FireOnEntityCreated(int entity, const char[] classname)
{
	Call_StartForward(OnEntityCreatedForward)
	Call_PushCell(entity)
	Call_PushString(classname)
	Call_Finish()
}

stock Action FireOnWeaponDrop(int client, int weaponIndex)
{
	Call_StartForward(OnWeaponDropForward)
	Call_PushCell(client)
	Call_PushCell(weaponIndex)
	Action result
	Call_Finish(result)
	return result
}

stock Action FireOnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	Call_StartForward(OnTerminateRoundForward)
	Call_PushFloatRef(delay);
	Call_PushCellRef(reason)
	Action result
	Call_Finish(result)
	return result
}

stock Action FireOnPlayerRunCmd(int client, int &buttons)
{
	Call_StartForward(OnPlayerRunCmdForward)
	Call_PushCell(client);
	Call_PushCellRef(buttons)
	Action result
	Call_Finish(result)
	return result
}

stock void FireOnClientDisconnect(int client)
{	
	Call_StartForward(OnClientDisconnectForward)
	Call_PushCell(client)
	Call_Finish()
}