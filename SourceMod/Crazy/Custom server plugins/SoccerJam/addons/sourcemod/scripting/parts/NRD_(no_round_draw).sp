public Action NRD_OnTerminateRound(float delay, CSRoundEndReason &reason)
{
	if (reason == CSRoundEnd_Draw)
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}