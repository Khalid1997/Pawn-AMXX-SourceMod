#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <multimod>
#include <fdownloader>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "FDownloader: Mod Specific config",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

bool g_bLoaded;

public void OnPluginStart()
{
	if(MultiMod_IsLoaded())
	{
		MultiMod_OnLoaded(false);
	}
}

public void MultiMod_OnLoaded(bool bReload)
{
	g_bLoaded = true;
	int iCount = MultiMod_GetModsCount();
	
	char szKey[MM_MAX_MOD_PROP_LENGTH];
	char szPath[PLATFORM_MAX_PATH];
	
	for(int i; i < iCount; i++)
	{
		MultiMod_GetModProp(i, MultiModProp_Plugins, szKey, sizeof szKey);
		MultiMod_BuildPath(MultiModPath_Mods, szPath, sizeof szPath, "%s-downloads.ini", szKey);
		
		if(!FileExists(szPath))
		{
			CreateFile(szPath);
		}
	}
}

public void OnMapStart()
{
	if(!g_bLoaded)
	{
		return;
	}
	
	int iModIndex = MultiMod_GetCurrentModId();
	
	char szKey[MM_MAX_MOD_PROP_LENGTH];
	MultiMod_GetModProp(iModIndex, MultiModProp_Plugins, szKey, sizeof szKey);
	
	char szPath[PLATFORM_MAX_PATH];
	MultiMod_BuildPath(MultiModPath_Mods, szPath, sizeof szPath, "%s-downloads.ini", szKey);
	
	if(!FileExists(szPath))
	{
		CreateFile(szPath);
		return;
	}
	
	File f = OpenFile(szPath, "r");
	while(ReadFileLine(f, szPath, sizeof szPath))
	{
		if (!szPath[0] || szPath[0] == '#' || szPath[0] == ';' || (szPath[0] == '/' && szPath[1] == '/'))
		{
			continue;
		}
		
		FDownloader_AddSinglePath(szPath);
	}
	
	delete f;
}

void CreateFile(char[] szPath)
{
	File f = OpenFile(szPath, "w+");
	
	if(f == null)
	{
		return;
	}
	
	f.WriteLine("; This file is Mod-Specific. It will only be executed during the mod it is specified to.");
	f.WriteLine("; Any line starting with ';', '#', or '//' is a comment.");
	f.WriteLine("; You can specifiy to download all files in an entire folder by adding '*' at the end.");
	f.WriteLine("; Example on entire folder:");
	f.WriteLine("; models/multimod/public/*");
	
	delete f;
}
	
	
