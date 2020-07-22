const int MAX_SOUNDS = 128
const int MAX_SOUND_GROUPS = 128
const int MAX_SOUNDS_IN_GROUPS = 32

int SoundGroupsCount
int SoundCount[MAX_SOUND_GROUPS]
char SoundGroupNames[MAX_SOUNDS][MAX_NAME_LENGTH]
char SoundPaths[MAX_SOUND_GROUPS][MAX_SOUNDS][PLATFORM_MAX_PATH]


public void SM_Init()
{
	CreateConfig("sounds.cfg", "sounds", SM_ReadConfig)
}

int CreateSound(const char[] soundGrouopName)
{
	strcopy(SoundGroupNames[SoundGroupsCount], MAX_NAME_LENGTH, soundGrouopName)
	SoundGroupsCount++
	return SoundGroupsCount - 1
}

public void SM_ReadConfig(Handle kv)
{
	for (int soundGroupId = 0; soundGroupId < SoundGroupsCount; soundGroupId++)
	{
		SoundCount[soundGroupId] = 0
		if (KvJumpToKey(kv, SoundGroupNames[soundGroupId]))
		{
			if (KvGotoFirstSubKey(kv, false))
			{
				do
				{
					int soundCountInThisGroup = SoundCount[soundGroupId]
					KvGetSectionName(kv, SoundPaths[soundGroupId][soundCountInThisGroup], PLATFORM_MAX_PATH)
					SoundCount[soundGroupId]++
				}
				while (KvGotoNextKey(kv, false))
				KvGoBack(kv)
			}
			KvGoBack(kv)
		}
	}
}

public void SM_OnSjConfigLoaded()
{
	int soundId
	for (int soundGroupId = 0; soundGroupId < SoundGroupsCount; soundGroupId++)
	{
		for (soundId = 0; soundId < SoundCount[soundGroupId]; soundId++)
		{
			PrecacheSound(SoundPaths[soundGroupId][soundId])

			char fullSoundPath[PLATFORM_MAX_PATH]
			Format(fullSoundPath, sizeof(fullSoundPath), "sound/%s", SoundPaths[soundGroupId][soundId])
			AddFileToDownloadsTable(fullSoundPath)
		}
	}
}

void GetSoundPathById(int soundGroupId, char dest[PLATFORM_MAX_PATH])
{
	if (SoundCount[soundGroupId] == 0)
	{
		return
	}
	int randomSoundId = GetRandomInt(0, SoundCount[soundGroupId] - 1)
	strcopy(dest, PLATFORM_MAX_PATH, SoundPaths[soundGroupId][randomSoundId])
}

void PlaySoundByIdToAll(int soundGroupId)
{
	if (SoundCount[soundGroupId] == 0)
	{
		return
	}
	int randomSoundId = GetRandomInt(0, SoundCount[soundGroupId] - 1)
	if (!StrEqual(SoundPaths[soundGroupId][randomSoundId], "", false))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				EmitSoundToClient(i, SoundPaths[soundGroupId][randomSoundId]);
			}
		}
	}
}

void PlaySoundByIdToClient(int client, int soundGroupId)
{
	if (SoundCount[soundGroupId] == 0)
	{
		return
	}
	int randomSoundId = GetRandomInt(0, SoundCount[soundGroupId] - 1)
	if (!StrEqual(SoundPaths[soundGroupId][randomSoundId], "", false))
	{
		EmitSoundToClient(client, SoundPaths[soundGroupId][randomSoundId]);
	}
}

void PlaySoundByIdFromEntity(int soundGroupId, int entity)
{
	if (SoundCount[soundGroupId] == 0)
	{
		return
	}
	int randomSoundId = GetRandomInt(0, SoundCount[soundGroupId] - 1)
	if (!StrEqual(SoundPaths[soundGroupId][randomSoundId], "", false))
	{
		EmitSoundToAll(SoundPaths[soundGroupId][randomSoundId], entity);
	}
}