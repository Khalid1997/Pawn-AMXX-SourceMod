int  HeBounceSoundSpecificId;
int  BallBounceSoundId;
char BallBounceSoundPath[PLATFORM_MAX_PATH];

public void BBS_Init()
{
	AddNormalSoundHook(BBS_Event_SoundPlayed);
	HeBounceSoundSpecificId = CreateSpecificString("he_bounce_sound");
	BallBounceSoundId = CreateSound("ball_bounce");
}

public void BBS_OnSjConfigLoaded()
{
	GetSoundPathById(BallBounceSoundId, BallBounceSoundPath);
}

public Action BBS_Event_SoundPlayed(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level,int &pitch,int &flags) 
{
	char heBounceSound[PLATFORM_MAX_PATH];
	GetSpecificString(HeBounceSoundSpecificId, heBounceSound, sizeof(heBounceSound));
	if (StrEqual(sample, heBounceSound))
	{
		EmitSound(clients, numClients, BallBounceSoundPath, entity, channel, level, flags, volume, pitch, entity);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}