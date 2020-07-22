#include <sourcemod>
#include <sdktools>

//This will make the map as dark as possible (using SetLightStyle) in CS:GO.
public void OnMapStart()
{
	char szMapName[128];
	GetCurrentMap(szMapName, sizeof szMapName);
	
	if(StrEqual(szMapName, "awp_map_csgo", false))
	{
		SetLightStyle(0, "zzzzzz");
	}
} 