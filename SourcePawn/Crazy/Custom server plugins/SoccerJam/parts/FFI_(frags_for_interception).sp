public void FFI_OnBallReceive(int ballHolder, int oldBallOwner)
{
	if (oldBallOwner > 0
		&& GetClientTeam(ballHolder) != GetClientTeam(oldBallOwner))
	{
		Client_SetScore(ballHolder, Client_GetScore(ballHolder) + 1)
		Client_SetDeaths(oldBallOwner, Client_GetDeaths(oldBallOwner) + 1)
	}
}