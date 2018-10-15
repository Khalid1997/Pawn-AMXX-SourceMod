#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION MM_VERSION_STR

#include <sourcemod>
#include <multimod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Multimod Plugin: Map Display Name",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

char g_szFilePath[] = "cfg/multimod/maps_displayname.ini";

StringMap g_hTrie_DisplayNames;

public void OnPluginStart()
{
	g_hTrie_DisplayNames = new StringMap();
}

public void OnMapStart()
{
	ReadPluginFile();
}

public void MultiMod_OnLoaded(bool bReload)
{
	if(bReload)
	{
		ReadPluginFile();
	}
}

void ReadPluginFile()
{
	g_hTrie_DisplayNames.Clear();
	
	File f = OpenFile(g_szFilePath, "r");
	
	if(f == null)
	{
		f = OpenFile(g_szFilePath, "w+");
		
		if(f == null)
		{
			return;
		}
		
		WriteFileLine(f, "# Any line that starts with #, ; or // is a comment");
		WriteFileLine(f, "; Format:");
		WriteFileLine(f, "; \"map_file_name\" \"Display Name\"");
		
		delete f;
	}
	
	char szStrings[2][MM_MAX_MAP_NAME];
	char szLine[MM_MAX_FILE_LINE_LENGTH];
	while(!f.EndOfFile())
	{
		f.ReadLine(szLine, sizeof szLine);
		TrimString(szLine);
		
		if(szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
		{
			continue;
		}
		
		ExplodeString(szLine, " ", szStrings, 2, sizeof szStrings[], true);
		
		StripQuotes(szStrings[0]);
		StripQuotes(szStrings[1]);
		
		SetTrieString(g_hTrie_DisplayNames, szStrings[0], szStrings[1]);
	}
	
	delete f;
}
	
public MMReturn MultiMod_Vote_OnAddMenuItem_Pre(MultiModVote vote, int iVoteItemRealIndex, char[] szDisplayName, int iSize, bool &bEnabled)
{
	if(vote != MultiModVote_Map)
	{
		return MMReturn_Continue;
	}
	
	CleanDisplayName(szDisplayName, iSize);
	return MMReturn_Continue;
}

void CleanDisplayName(char[] szDisplayName, int iSize)
{
	PrintToServer("Before: %s", szDisplayName);
	ReplaceStringEx(szDisplayName, iSize, ".bsp", "");
	GetMapDisplayName(szDisplayName, szDisplayName, iSize);
	
	char szNewDisplayName[MM_MAX_MAP_NAME];
	if(GetTrieString(g_hTrie_DisplayNames, szDisplayName, szNewDisplayName, sizeof szNewDisplayName))
	{
		strcopy(szDisplayName, iSize, szNewDisplayName);
	}
	
	PrintToServer("After: %s", szDisplayName);
}
