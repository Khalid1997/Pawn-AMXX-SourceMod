#if defined _multimod_included_
  #endinput
#endif
#define _multimod_included_

native MultiMod_GetNextModId();
native MultiMod_GetCurrentModId();
native MultiMod_GetModsCount();
	
native MultiMod_SetNextMod(iModId);

enum MODSPROPS
{
	MP_NAME,
	MP_PLUGIN,
	MP_MAP,
	MP_CFG
};

native Handle:MultiMod_GetNameArray();
native Handle:MultiMod_GetPluginFolderArray();
native Handle:MultiMod_GetMapFileArray();
native Handle:MultiMod_GetConfigFileArray();

native MultiMod_GetModProps(iModId, MODSPROPS:MM_PROP, String:szInfo[], iSize);