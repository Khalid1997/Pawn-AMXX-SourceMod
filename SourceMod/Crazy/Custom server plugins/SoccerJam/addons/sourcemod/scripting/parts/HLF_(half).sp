Handle TimeUpTimer
Handle RoundTimeConVar
Handle HalfDurationConVar
Handle OnHalfEndForward
Handle OnHalfStartForward

public void HLF_Init()
{
	RoundTimeConVar = FindConVar("mp_roundtime")
	HookConVarChange(RoundTimeConVar, OnCVRoundTimeChanged)
	HalfDurationConVar = CreateConVar("sj_half_duration", "15", "Half duration in minutes", 0, true, 1.0, true, 60.0)	
	HookConVarChange(HalfDurationConVar, OnCVHalfDurationChanged)

	OnHalfStartForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnHalfStartForward, "OnHalfStart")

	OnHalfEndForward = CreateForward(ET_Ignore)
	RegisterCustomForward(OnHalfEndForward, "OnHalfEnd")
}

public void HLF_OnMapStart()
{
	TimeUpTimer = INVALID_HANDLE
}

public void Half_Start()
{
	Half_StartAfterDelay(0.0)
}

public void Half_StartAfterDelay(float delayInSeconds)
{
	CS_TerminateRound(delayInSeconds, CSRoundEnd_BombDefused, true)
}

public void HLF_Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ClearTimer(TimeUpTimer)
	FireOnHalfStart()
}

public void HLF_Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	TimeUpTimer = CreateTimer(GetConVarFloat(HalfDurationConVar) * 60, Timer_TimeUp, _, TIMER_FLAG_NO_MAPCHANGE)
}

public Action Timer_TimeUp(Handle timer)
{
	ClearTimer(TimeUpTimer)
	FireOnHalfEnd()
	return Plugin_Continue
}

public void OnCVRoundTimeChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateHalfDuration()
}

public void OnCVHalfDurationChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateHalfDuration()
}

void UpdateHalfDuration()
{
	float halfDuration = GetConVarFloat(HalfDurationConVar)
	float roundTime = GetConVarFloat(RoundTimeConVar)
	if (roundTime != halfDuration)
	{
		SetConVarFloat(RoundTimeConVar, halfDuration)
	}
}

void FireOnHalfStart()
{
	Call_StartForward(OnHalfStartForward)
	Call_Finish()
}

void FireOnHalfEnd()
{
	Call_StartForward(OnHalfEndForward)
	Call_Finish()
}