#define MAX_MESSAGE_LENGTH 64
int TimeLeft
Function CallBack
char Message[MAX_MESSAGE_LENGTH]
bool IsSoundNotifyEnabled
int TimerTickSoundId

public void SJT_Init()
{
	TimerTickSoundId = CreateSound("timer_tick")
	CreateTimer(1.0, Timer_CheckSjTimer, _, TIMER_REPEAT)
}

public Action Timer_CheckSjTimer(Handle timer)
{	
	DecreaseCounter()
	return Plugin_Continue
}

void DecreaseCounter()
{
	TimeLeft--
	if (TimeLeft > 0 )
	{
		if (!StrEqual(Message, ""))
		{
			char message[MAX_MESSAGE_LENGTH]
			Format(message, MAX_MESSAGE_LENGTH, "%s%i%s", Message, TimeLeft, "...");
			PrintCenterTextAll(message)
		}
		if (IsSoundNotifyEnabled)
		{
			PlaySoundByIdToAll(TimerTickSoundId)
		}
	}
	CheckForCallBack()
}

void CreateSjTimer(int timeInSeconds, Function callBackFunc, const char[] message = "", bool isSoundNotifyEnabled = false)
{
	TimeLeft = timeInSeconds
	CallBack = callBackFunc
	IsSoundNotifyEnabled = isSoundNotifyEnabled
	strcopy(Message, MAX_MESSAGE_LENGTH, message)
	CheckForCallBack()
}

void CheckForCallBack()
{
	if (TimeLeft == 0)
	{
		Call_StartFunction(INVALID_HANDLE, CallBack)
		Call_Finish()
	}
}