#define FFADE_OUT			0x0002
#define	FFADE_PURGE		0x0010  

void FadeClient(int client, int duration, const int color[4]) 
{
	Handle hFadeClient = StartMessageOne("Fade",client)
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hFadeClient, "duration", duration)
		PbSetInt(hFadeClient, "hold_time", 0)
		PbSetInt(hFadeClient, "flags", (FFADE_PURGE|FFADE_OUT))
		PbSetColor(hFadeClient, "clr", color)
	}
	else
	{		
		BfWriteShort(hFadeClient, duration)
		BfWriteShort(hFadeClient, 0)
		BfWriteShort(hFadeClient, (FFADE_PURGE|FFADE_OUT))
		BfWriteByte(hFadeClient, color[0])
		BfWriteByte(hFadeClient, color[1])
		BfWriteByte(hFadeClient, color[2])
		BfWriteByte(hFadeClient, 128)		
	}
	EndMessage()
}

void ClearTimer(Handle &timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
	}
	timer = INVALID_HANDLE;
}

float GetEntityRadius(int entity)
{
	float vecMax[3];
	Entity_GetMaxSize(entity, vecMax);
	int highestSizeIndex = Array_FindHighestValue(vecMax, sizeof(vecMax));
	return vecMax[highestSizeIndex];
}