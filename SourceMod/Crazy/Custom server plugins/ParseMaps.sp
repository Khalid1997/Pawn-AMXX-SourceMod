#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PrintToServer LogMessageToFile

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

void LogMessageToFile(char[] szBuffer, any ...)
{
	char szMsg[256];
	VFormat(szMsg, sizeof szMsg, szBuffer, 2);
	
	LogToFile("addons/sourcemod/plugins/ParseMaps.txt", szMsg);
}

bool g_bLate;

public APLRes	AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int Error)
{
	g_bLate = bLate;
}

public void OnPluginStart()
{
	if(g_bLate)
	{
		OnMapStart();
	}
}

public void OnMapStart()
{
	Parse();
}

ArrayList g_hTotalMapsArray;
void Parse()
{	
	g_hTotalMapsArray = new ArrayList(PLATFORM_MAX_PATH);
	LoadMapsFiles();
	
	char szPath[PLATFORM_MAX_PATH];
	char szMM[] = "cfg/multimod/mods/";
	
	DirectoryListing dir = OpenDirectory(szMM);
	
	if(dir == null)
	{
		delete g_hTotalMapsArray;
		return;
	}
	
	FileType filetype;
	
	char szPathMod[PLATFORM_MAX_PATH];
	char szPathNewMapsFile[PLATFORM_MAX_PATH];
	
	while (ReadDirEntry(dir, szPathMod, sizeof szPathMod, filetype))
	{
		if(filetype != FileType_Directory)
		{
			continue;
		}
		
		if(szPathMod[0] == '.')
		{
			continue;
		}
		
		Format(szPathMod, sizeof szPathMod, "%s/%s/", szMM, szPathMod);
		DirectoryListing dirmod = OpenDirectory(szPathMod);
		
		if(dirmod == null)
		{
			continue;
		}
		
		PrintToServer("** Opening MOD %s", szPathMod);
		while (ReadDirEntry(dirmod, szPath, sizeof szPath, filetype))
		{
			if(filetype != FileType_File)
			{
				continue;
			}
			
			if (StrContains(szPath, "maps", false) == -1)
			{
				continue;
			}
			
			Format(szPathNewMapsFile, sizeof szPathNewMapsFile, "%s/new-%s", szPathMod, szPath);
			Format(szPath, sizeof szPath, "%s/%s", szPathMod, szPath);
			
			PrintToServer("File: %s", szPath);
			PrintToServer("NewFile: %s", szPathNewMapsFile);
			
			File newf = OpenFile(szPathNewMapsFile, "w+");
			File f = OpenFile(szPath, "r");
			
			if(f == null)
			{
				delete newf;
				PrintToServer("Couldn't Open ????");
				continue;
			}
			
			char szMap[PLATFORM_MAX_PATH];
			char szLine[PLATFORM_MAX_PATH];
			while(ReadFileLine(f, szLine, sizeof szLine))
			{
				TrimString(szLine);
				PrintToServer("szLine: %s");
				if (!szLine[0] || szLine[0] == ';' || szLine[0] == '#' || (szLine[0] == '/' && szLine[1] == '/'))
				{
					PrintToServer("Failed");
					continue;
				}
				
				PrintToServer("Check line: %s", szLine);
				for (int i; i < g_hTotalMapsArray.Length; i++)
				{
					g_hTotalMapsArray.GetString(i, szMap, sizeof szMap);
					
					if(StrContains(szMap, szLine, false) == -1)
					{
						continue;
					}
					
					PrintToServer("MATCH CASE %d : %s", i, szLine);
					WriteFileLine(newf, szMap);
				}
			}
			
			delete newf;
			delete f;
		}
		
		delete dirmod;
	}
	
	delete dir;
	
	delete g_hTotalMapsArray;
}

void LoadMapsFiles()
{
	char szMapsPath[] = "maps/workshop/";
	
	DirectoryListing dir = OpenDirectory(szMapsPath);
	
	if(dir == null)
	{
		PrintToServer("Failed to open maps dir");
		return;
	}
	
	char szNewPath[PLATFORM_MAX_PATH];
	char szNewNewPath[PLATFORM_MAX_PATH];
	
	FileType filetype;
	while (ReadDirEntry(dir, szNewPath, sizeof szNewPath, filetype))
	{
		if(filetype != FileType_Directory)
		{
			continue;
		}
		
		if(szNewPath[0] == '.')
		{
			continue;
		}
		
		PrintToServer("Loading Workshopmap %s", szNewPath);
		Format(szNewPath, sizeof szNewPath, "%s/%s", szMapsPath, szNewPath);
		DirectoryListing dir2 = OpenDirectory(szNewPath);
		
		if(dir2 == null)
		{
			PrintToServer("Failed to open maps directory %s", szNewPath);
			continue;
		}
		
		while(ReadDirEntry(dir2, szNewNewPath, sizeof szNewNewPath, filetype))
		{
			if(filetype != FileType_File)
			{
				continue;
			}
			
			if(StrContains(szNewNewPath, ".bsp") == -1)
			{
				continue;
			}
			
			PrintToServer("Found Workshop Map %s", szNewNewPath);
			
			Format(szNewNewPath, sizeof szNewNewPath, "%s/%s", szNewPath, szNewNewPath);
			PrintToServer("Format: %s", szNewNewPath);
			
			ReplaceString(szNewNewPath, sizeof szNewNewPath, "//", "/");
			PushArrayString(g_hTotalMapsArray, szNewNewPath);
		}
		
		delete dir2;
	}
	
	delete dir;
}
