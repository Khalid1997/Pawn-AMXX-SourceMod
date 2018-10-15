#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	
}

// MultiMod Test script that is not completed.
void GetModArrayLists(int iSize, int[] iMods, int[] iListType, int[] iHandleType, int[] hHandles, int[] iOptionalCount)
{
	bool bDone[iSize];
	for(int i; i < iSize; i++)
	{
		switch(iListType[i])
		{
			case ModList_Plugins:
			{
				CreatePluginsList(iMods[i], iHandleType[i], hHandle[i], iOptionalCount[i]);
				bDone[i] = true;
			}
		}
	}
	
	/*
	int iOriginalIndex[iSize];
	int iNew_Mods[iSize];
	int iNew_HandleType[iSize];
	any hNew_Handle[iSize];
	int iNew_ListType[iSize];
	int iNew_OptionalCount[iSize]
	int iNewSize
	
	// This is only here because I didn't feel like opening a file more than needed to parse it.
	// This is only used for map file.
	// This groups whats left by Mods, and then groups those already grouped.
	// Group by mods
	for(int i; i < iSize; i++)
	{
		if(bDone[i])
		{
			continue;
		}
		
		iNewSize = 0;
		
		// Group;
		for(int j; j < iSize; i++)
		{
			if(!bDone[j])
			{
				continue;
			}
			
			if(iMods[j] != iMods[i])
			{
				continue;
			}
			
			iOriginalIndex[iNewSize] = j;
		
			iNewListType[iNewSize] = iListType[j];
		
			iNew_HandleType[iNewSize] = iHandleType[i];
			hNew_Handle[iNewSize] = hHandle[i];
			
			iNewSize++;
		
			//iNewOptionalCount[iNewSize] = iOptionalCount[i];
		}
		
		if(!iNewSize)
		{
			continue;
		}
		
		CreateMapListForMod(iMods[i], iNewSize, iNewListType, iHandleType, iNewHandlesArray, iNewOptionalCount);
		
		// Copy back to their origianl indexes;
	}
}

*/

/*
bool IsServerProperlyLoaded()
{
	if(g_iLoadStatus == LS_Loaded)
	{
		// Check if it should be unloaded as there are no mods.
		if(g_iModsCount)
		{
			return true;
		}
		
		else
		{
			g_iLoadStatus = LS_Waiting;
			g_iCurrentModId = 0;
			SetNextMod(ModIndex_Null);
		}
	}
	
	else if(g_iLoadStatus == LS_Waiting)
	{
		if(!g_iModsCount)
		{
			return false;
		}
		
		else
		{
			#if defined RANDOMIZE_FIRST_MOD
			SetNextMod(GetRandomInt(0, g_iModsCount -1));
			#else
			SetNextMod(0);
			#endif
			
			g_iLoadStatus = LS_Loaded_NextMapChange;
			
			g_iCurrentModId = ModIndex_Null;
			SetNextMod(ModIndex_Null);
			
			#if defined RANDOMIZE_FIRST_MAP
			
		}
	}
	
	else if g_iLoadStatus == LS_Loaded_Next)
	{
		g_iLoadStatus = LS_Loaded;
		CallLoadForward(false);
	}
}*/