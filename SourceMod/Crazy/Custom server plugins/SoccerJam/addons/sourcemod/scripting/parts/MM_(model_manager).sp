const int MAX_MODELS = 128
int ModelsCount
char ModelNames[MAX_MODELS][MAX_NAME_LENGTH]
char ModePaths[MAX_MODELS][PLATFORM_MAX_PATH]
int ModelCaches[MAX_MODELS]

public void MM_Init()
{
	CreateConfig("models.cfg", "models", MM_ReadConfig)
}

public void MM_OnSjConfigLoaded()
{
	for (int modelId = 0; modelId < ModelsCount; modelId++)
	{
		ModelCaches[modelId] = PrecacheModel(ModePaths[modelId])
	}
	g_LaserCache = PrecacheModel(LASER_SPRITE)
	PrecacheModel("materials/sprites/animglow02.vmt")
	g_MiniExplosionSprite = PrecacheModel("materials/sprites/blueglow2.vmt")
}

int CreateModel(const char[] modelName)
{
	strcopy(ModelNames[ModelsCount], MAX_NAME_LENGTH, modelName)
	ModelsCount++
	return ModelsCount - 1
}

public void MM_ReadConfig(Handle kv)
{
	for (int modelId = 0; modelId < ModelsCount; modelId++)
	{
		KvGetString(kv, ModelNames[modelId], ModePaths[modelId], PLATFORM_MAX_PATH);
	}
}

stock void GetModelPath(int modelId, char dest[PLATFORM_MAX_PATH])
{
	strcopy(dest, PLATFORM_MAX_PATH, ModePaths[modelId])
}

stock int GetModelCache(int modelId)
{
	return ModelCaches[modelId]
}

stock void SetEntityModelById(int entity, int modelId)
{
	SetEntityModel(entity, ModePaths[modelId])
}