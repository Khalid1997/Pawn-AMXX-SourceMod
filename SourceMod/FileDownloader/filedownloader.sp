#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls requiredsm

public Plugin myinfo = 
{
	name = "Files Downloaded", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

char szFilePath[] = "addons/sourcemod/configs/files_downloader.ini";

int g_bDebug;
ConVar ConVar_Debug;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] error, int err_max)
{
	RegPluginLibrary("fdownloader");
	CreateNative("FDownloader_AddPaths", Native_AddPaths);
	CreateNative("FDownloader_AddSinglePath", Native_AddSinglePath);
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookConVarChange( ( ConVar_Debug = CreateConVar("fdownloader_debug", "0") ), HookConVar_Changed);
	g_bDebug = ConVar_Debug.IntValue;
}

public void HookConVar_Changed(ConVar convar, char[] szNewValue, char[] szOldValue)
{
	g_bDebug = convar.IntValue;
}

public void OnMapStart()
{
	ReadAndCacheFiles();
}

void ReadAndCacheFiles()
{
	char szPath[PLATFORM_MAX_PATH];
	File f = OpenFile(szFilePath, "a+");
	
	if (f == null)
	{
		LogError("[Files Downloader] Couldn't Open base file");
		return;
	}
	
	while (!f.EndOfFile())
	{
		ReadFileLine(f, szPath, sizeof szPath);
		if (!szPath[0] || szPath[0] == '#' || szPath[0] == ';' || (szPath[0] == '/' && szPath[1] == '/'))
		{
			continue;
		}
		
		TrimString(szPath);
		
		ProcessPathString(szPath);
	}
	
	delete f;
}

void GetFileExtName(char[] szFile, char[] szExt, int iSize)
{
	int iLen = 0, iTotal = 0;
	while( ( iLen = StrContains(szFile[iTotal], ".") ) != -1 )
	{
		iTotal += iLen + 1; // Move it after the "."
		continue;
	}
	
	strcopy(szExt, iSize, szFile[iTotal]);
}

void ProcessPathString(char[] szPath)
{
	FileType iFileType;
	char szExt[6];
	char szFileName[PLATFORM_MAX_PATH];
	DirectoryListing hDir;
	
	ReplaceString(szPath, strlen(szPath), "\\", "/");
	
	if(!szPath[0])
	{
		return;
	}
	
	if (szPath[strlen(szPath) - 1] == '*')
	{
		ReplaceString(szPath[strlen(szPath) - 1], 1, "*", "");
		ReplaceStringEx(szPath[strlen(szPath) - 2], 2, "/", "");
			
		hDir = OpenDirectory(szPath);
			
		if (hDir == null)
		{
			LogError("[FileDownloader] Directory %s doesn't exist", szPath);
			return;
		}
			
		while (ReadDirEntry(hDir, szFileName, sizeof szFileName, iFileType))
		{
			if (iFileType != FileType_File)
			{
				continue;
			}
				
			GetFileExtName(szFileName, szExt, sizeof szExt);
			//PrintToServer("Ext: %s", szExt); 
			if (StrEqual(szExt, "ztmp"))
			{
				continue;
			}
				
			Format(szFileName, sizeof szFileName, "%s/%s", szPath, szFileName);
			
			if (g_bDebug)
			{
				LogToFile("addons/sourcemod/filedownloader.txt", "[FileDownloader] Added: %s", szFileName);
			}
			
			AddFileToDownloadsTable(szFileName);
		}
			
		delete hDir;
	}
	
	else if(szPath[strlen(szPath) - 1] == '#')
	{
		ReplaceString(szPath[strlen(szPath) - 1], 1, "#", "");
		//ReplaceStringEx(szPath[strlen(szPath) - 2], 2, "/", "");
		
		int iPos = 0, iLastPos = 0;
		while( ( iPos = StrContains(szPath[iLastPos], "/") ) != -1)
		{
			iLastPos += iPos + 1;
			//PrintToServer("iPos: %d %d %s", iPos, iLastPos, szPath[iLastPos]);
		}
		
		if(iLastPos == -1)
		{
			LogError("[FileDownloader] Incorrect Synatx: %s", szPath);
			return;
		}
		
		// Charachterizing String
		char szChar[128];
		strcopy(szChar, sizeof szChar, szPath[iLastPos + 1]);
		szPath[iLastPos] = '\0';
		
		hDir = OpenDirectory(szPath);
			
		if (hDir == null)
		{
			LogError("[FileDownloader] Directory %s doesn't exist", szPath);
			return;
		}
			
		while (ReadDirEntry(hDir, szFileName, sizeof szFileName, iFileType))
		{
			if (iFileType != FileType_File)
			{
				continue;
			}
				
			GetFileExtName(szFileName, szExt, sizeof szExt);
			//PrintToServer("Ext: %s", szFileName); 
			if (StrEqual(szExt, "ztmp"))
			{
				continue;
			}
			
			if(StrContains(szFileName, szChar, false) != -1)
			{
				Format(szFileName, sizeof szFileName, "%s/%s", szPath, szFileName);
				
				if (g_bDebug)
				{
					LogToFile("addons/sourcemod/filedownloader.txt", "[FileDownloader] Added: %s", szFileName);
				}
				
				AddFileToDownloadsTable(szFileName);
			}
		}
			
		delete hDir;
	}
		
	else
	{
		if (!FileExists(szPath))
		{
			LogError("[FileDownloader] File %s doesn't exist", szPath);
			return;
		}
		
		if (g_bDebug)
		{
			LogToFile("addons/sourcemod/filedownloader.txt", "[FileDownloader] Added: %s", szFileName);
		}
		
		AddFileToDownloadsTable(szPath);
		//PrintToServer("[Downloader] Added: %s", szPath);
	}
}

// native void Downloader_AddPaths(char [][] szPaths, int iNumPaths);
public int Native_AddPaths(Handle hPlugin, int iArgs)
{
	ArrayList hArray = GetNativeCell(1);
	int iSize = GetArraySize(hArray);
	
	char szPath[PLATFORM_MAX_PATH];
	
	for (int i; i < iSize; i++)
	{
		GetArrayString(hArray, i, szPath, sizeof szPath);
		ProcessPathString(szPath);
	}
}

public int Native_AddSinglePath(Handle hPlugin, int iArgs)
{
	char szPath[PLATFORM_MAX_PATH];
	
	GetNativeString(1, szPath, sizeof szPath);
	ProcessPathString(szPath);
}