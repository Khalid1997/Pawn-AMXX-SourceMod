const MAX_SPECIFICS = 128
int SpecificCount
char SpecificNames[MAX_SPECIFICS][MAX_NAME_LENGTH]
char SpecificStrings[MAX_SPECIFICS][PLATFORM_MAX_PATH]

public void GSM_Init()
{
	CreateConfig("game_specific.cfg", "specific", GSM_ReadConfig)
}

public void GSM_ReadConfig(Handle kv)
{
	for (int specificId = 0; specificId < SpecificCount; specificId++)
	{
		KvGetString(kv, SpecificNames[specificId], SpecificStrings[specificId], PLATFORM_MAX_PATH)
	}
}

int CreateSpecificString(const char[] specificName)
{
	strcopy(SpecificNames[SpecificCount], MAX_NAME_LENGTH, specificName)
	SpecificCount++
	return SpecificCount - 1
}

stock void GetSpecificString(int specificId, char[] dest, int deatLen)
{
	strcopy(dest, deatLen, SpecificStrings[specificId])
}