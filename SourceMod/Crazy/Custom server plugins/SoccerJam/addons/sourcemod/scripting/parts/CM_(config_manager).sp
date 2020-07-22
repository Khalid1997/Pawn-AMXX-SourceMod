Handle OnSjConfigLoadedForward

#define SJ_CONFIG_DIRECTORY "cfg/sourcemod/soccerjam"

typedef ConfigProcessingFunc = function void(KeyValues kv);

const int MAX_CONFIGS = 32
int ConfigsCount
char FileNames[MAX_CONFIGS][MAX_NAME_LENGTH]
char RootNames[MAX_CONFIGS][MAX_NAME_LENGTH]
ConfigProcessingFunc processingFunctions[MAX_CONFIGS]

public void CM_Init()
{
	OnSjConfigLoadedForward = CreateForward(ET_Ignore);
	RegisterCustomForward(OnSjConfigLoadedForward, "OnSjConfigLoaded");
}

int CreateConfig(const char[] fileName, const char[] rootSectionName, ConfigProcessingFunc processingFunc)
{
	strcopy(FileNames[ConfigsCount], MAX_NAME_LENGTH, fileName);
	strcopy(RootNames[ConfigsCount], MAX_NAME_LENGTH, rootSectionName);
	processingFunctions[ConfigsCount] = processingFunc;
	ConfigsCount++;
	return ConfigsCount - 1;
}

public void CM_OnMapStart()
{
	LoadMainConfig()
	LoadDownloadList("downloads.txt")
	for (int configId = 0; configId < ConfigsCount; configId++)
	{
		LoadSJConfig(configId)
	}
	FireOnSjConfigLoaded()
}

void LoadSJConfig(int configId)
{
	char filePath[PLATFORM_MAX_PATH]
	SjBuildPath(filePath, PLATFORM_MAX_PATH, FileNames[configId])
	if (FileExists(filePath))
	{
		Handle kv = CreateKeyValues(RootNames[configId])
		if (FileToKeyValues(kv, filePath))
		{
			Call_StartFunction(INVALID_HANDLE, processingFunctions[configId])
			Call_PushCell(kv)
			Call_Finish()
		}
		CloseHandle(kv)
	}
}

void LoadMainConfig()
{
	AutoExecConfig(true, "soccerjam")
}

void LoadDownloadList(const char[] fileName)
{
	char filePath[PLATFORM_MAX_PATH]
	SjBuildPath(filePath, PLATFORM_MAX_PATH, fileName)
	if (FileExists(filePath))
	{
		Handle file = OpenFile(filePath, "r");
		char line[128];
		while (!IsEndOfFile(file))
		{
			ReadFileLine(file, line, sizeof(line));
			TrimString(line);
			if((line[0] != '/') && (line[1] != '/') && (line[0] != '\0'))
			{
				if (FileExists(line))
				{
					AddFileToDownloadsTable(line);
				}
			}
		}
		CloseHandle(file)
	}	
}

void SjBuildPath(char[] buffer, int maxlength, const char[] additionPath, any ...)
{
	char path[PLATFORM_MAX_PATH];
	VFormat(path, sizeof(path), additionPath, 4);
	char configDirectory[PLATFORM_MAX_PATH];
	strcopy(configDirectory, sizeof(configDirectory), SJ_CONFIG_DIRECTORY);
	Format(configDirectory, sizeof(configDirectory), "%s/%s", configDirectory, GameFolderName);
	Format(buffer, maxlength, "%s/%s", configDirectory, path);
}

void FireOnSjConfigLoaded()
{
	Call_StartForward(OnSjConfigLoadedForward)
	Call_Finish()
}