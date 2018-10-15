#pragma semicolon 1

#include <sourcemod>
#include <multimod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "MultiMod Plugin: Settings", 
	author = MM_PLUGIN_AUTHOR, 
	description = "Settings API", 
	version = MM_VERSION_STR, 
	url = "No URL."
};

char g_szMultiModSettingsFileName[] = "multimod_settings.cfg";
KeyValues g_hKeyValues;
KeyValues g_hFileKeyValues = null;

bool g_bLoaded;

char PARENT_SECTION_NAME[] = "MultiModSettings";

Handle g_hForward_SettingValueChange_Pre;
Handle g_hForward_SettingValueChange_Post;

public APLRes AskPluginLoad2(Handle plugin, bool bLate, char[] szError, int iErrorMax)
{
	// This must stay here because other plugins might create 
	// settings after their OnPluginStart when ours was not called.
	g_hKeyValues = CreateKeyValues(PARENT_SECTION_NAME);
	g_hFileKeyValues = CreateKeyValues(PARENT_SECTION_NAME);
	
	KvGotoFirstSubKey(g_hKeyValues, false);
	KvGotoFirstSubKey(g_hFileKeyValues, false);
	
	CreateNative("MultiMod_Settings_Create", Native_CreateSetting);
	CreateNative("MultiMod_Settings_Exist", Native_SettingExist);
	CreateNative("MultiMod_Settings_GetValue", Native_GetSettingValue);
	CreateNative("MultiMod_Settings_SetValue", Native_SetSettingValue);
	
	g_hForward_SettingValueChange_Pre = CreateGlobalForward("MultiMod_Settings_OnValueChange_Pre", ET_Event, Param_String, Param_String, Param_String);
	g_hForward_SettingValueChange_Post = CreateGlobalForward("MultiMod_Settings_OnValueChange", ET_Ignore, Param_String, Param_String, Param_String);
	
	RegPluginLibrary(MM_LIB_SETTINGS);
	
	return APLRes_Success;
}

public int Native_CreateSetting(Handle hPlugin, int iArgs)
{	
	char szSettingName[MM_SETTING_NAME_LENGTH];
	char szSettingValue[MM_SETTING_VALUE_LENGTH];
	
	GetNativeString(1, szSettingName, sizeof szSettingName);
	GetNativeString(2, szSettingValue, sizeof szSettingValue);
	
	bool bCallForward = GetNativeCell(3);
	bool bBackCheck = GetNativeCell(4);
	bool bReloadFile = GetNativeCell(5);

	//LogMessage("Create Called for %s .... %d %d %d", szSettingName, bCallForward, bBackCheck, bReloadFile);
	// Check if it exists in our keyvalues
	
	//LogMessage("Pass");
	//KvJumpToKey(g_hKeyValues, szSettingName, true);
	
	if (bBackCheck)
	{
		//LogMessage("Pass2");
		
		if(bReloadFile)
		{
			//LogMessage("Pass3");
			ReadSettingsFile();
		}
		
		if (KeyExistInKeyValuesStack(g_hFileKeyValues, szSettingName))
		{
			//LogMessage("Pass4");
			//MultiMod_PrintDebug("Exists In file");
			KvGetString(g_hFileKeyValues, szSettingName, szSettingValue, sizeof szSettingValue);
		}
	}
	
	//LogMessage("Created Setting %s with value %s", szSettingName, szSettingValue);
	//MultiMod_PrintDebug("Created Setting %s with value %s", szSettingName, szSettingValue);
	KvSetString(g_hKeyValues, szSettingName, szSettingValue);
	
	if (bCallForward)
	{
		//LogMessage("Pass5");
		//LogMessage("Called Change for Setting %s with value %s", szSettingName, szSettingValue);
		CallValueChangeForward(false, szSettingName, "", szSettingValue);
	}
	
	return 1;
}

public void OnAllPluginsLoaded()
{
	if(!g_bLoaded)
	{
		g_bLoaded = true;
		ReadSettingsFile();
	}
}
	
public void OnPluginStart()
{
	RegAdminCmd("sm_mm_reloadsettings", AdminCmdReloadSettings, MM_ACCESS_FLAG_ROOT_BIT, "Reloads multimod settings from the file", "MultiMod");
	RegAdminCmd("sm_mm_dumpkeyvalues", AdminCmdDumpKeysValues, MM_ACCESS_FLAG_ROOT_BIT);
}

public void MultiMod_OnLoaded(bool bReload)
{
	// Do not reset any of the existing values, just change the values to what is in the file (if it exists, otherwise, keep it as it is).
	
	if (bReload)
	{
		ReadSettingsFile();
	}
}

public Action AdminCmdReloadSettings(int client, int iArgsCount)
{
	if (iArgsCount < 1)
	{
		ReplyToCommand(client, "This will reload the MM Settings file.\
								\nIf you want to procceed, write sm_mm_reloadsettings \"confirm\" to continue.");
		return Plugin_Handled;
	}
	
	char szArg[10];
	GetCmdArg(1, szArg, sizeof szArg);
	
	if (!StrEqual(szArg, "confirm", false))
	{
		ReplyToCommand(client, "Fail: Arg is not \"confirm\". Write sm_mm_reload for more info.");
		return Plugin_Handled;
	}
	
	ReadSettingsFile();
	ReplyToCommand(client, "Successfully reloaded MultiMod settings.");
	return Plugin_Handled;
}

public Action AdminCmdDumpKeysValues(int client, int iArgs)
{
	KvRewind(g_hKeyValues);
	KvRewind(g_hFileKeyValues);
	
	KeyValuesToFile(g_hKeyValues, "cfg/multimod/dump1.txt");
	KeyValuesToFile(g_hFileKeyValues, "cfg/multimod/dump2.txt");
	
	KvGotoFirstSubKey(g_hKeyValues, false);
	KvGotoFirstSubKey(g_hFileKeyValues, false);
}

void ReadSettingsFile()
{
	char szMultiModPath[256];
	MultiMod_BuildPath(MultiModPath_Base, ModIndex_Null, szMultiModPath, sizeof szMultiModPath, "/%s", g_szMultiModSettingsFileName);
	
	if (g_hFileKeyValues != null)
	{
		delete g_hFileKeyValues;
	}
	
	g_hFileKeyValues = CreateKeyValues(PARENT_SECTION_NAME);
	KeyValues hNewKeyValues = CreateKeyValues(PARENT_SECTION_NAME);
	
	if (!FileExists(szMultiModPath))
	{
		delete hNewKeyValues;
		KeyValuesToFile(g_hKeyValues, szMultiModPath);
		//MultiMod_PrintDebug("Stop %s", szMultiModPath);
		return;
	}
	
	FileToKeyValues(hNewKeyValues, szMultiModPath);
	KvRewind(g_hKeyValues);
	
	/*
	if(!KvGotoFirstSubKey(hNewKeyValues, false))
	{
		MultiMod_PrintDebug(true, "[Setting Plugin] Something went wrong with the key values #2");
		delete hNewKeyValues;
		return;
	}*/
	
	RemoveExtraKeysAndKeepValues(hNewKeyValues, g_hFileKeyValues);
	delete hNewKeyValues;
	
	KvRewind(g_hFileKeyValues);
	KvRewind(g_hKeyValues);
	CheckChangesAndExistenceOfKeys(g_hKeyValues, g_hFileKeyValues);
}

void CheckChangesAndExistenceOfKeys(KeyValues hKv, KeyValues hFileKv)
{
	char szKeyName[MM_SETTING_NAME_LENGTH];
	char szOldValue[MM_SETTING_VALUE_LENGTH]; // Value in hKv
	char szNewValue[MM_SETTING_VALUE_LENGTH]; // Value in file (new value);
	
	MMReturn iRet;
	
	do
	{
		KvGetSectionName(hKv, szKeyName, sizeof szKeyName);
		//MultiMod_PrintDebug("** KeyName %s", szKeyName);
		
		if (KvGotoFirstSubKey(hKv, false))
		{
			//MultiMod_PrintDebug("** In");
			CheckChangesAndExistenceOfKeys(hKv, hFileKv);
			KvGoBack(hKv);
			continue;
		}
		
		KvGetString(hKv, NULL_STRING, szOldValue, sizeof szOldValue);
		//MultiMod_PrintDebug("** KeyName %s %s", szKeyName, szOldValue);
		
		if (!KeyExistInKeyValuesStack(hFileKv, szKeyName))
		{
			//MultiMod_PrintDebug("Key \"%s\" does not exist in the [Multimod Settings File]", szKeyName);
			continue;
		}
		
		KvGetString(hFileKv, szKeyName, szNewValue, sizeof szNewValue);
		
		if (!StrEqual(szNewValue, szOldValue))
		{
			//MultiMod_PrintDebug("Value Changed for setting %s from %s to %s", szKeyName, szOldValue, szNewValue);
			iRet = CallValueChangeForward(true, szKeyName, szOldValue, szNewValue);
			
			if (iRet == MMReturn_Stop)
			{
				continue;
			}
			
			KvSetString(hKv, NULL_STRING, szNewValue);
			CallValueChangeForward(false, szKeyName, szOldValue, szNewValue);
		}
	}
	while (KvGotoNextKey(hKv, false));
}

bool KeyExistInKeyValuesStack(KeyValues KeyValuesHandle, char[] szKeyName)
{
	if (!KvJumpToKey(KeyValuesHandle, szKeyName, false))
	{
		return false;
	}
	
	KvGoBack(KeyValuesHandle);
	return true;
}

void RemoveExtraKeysAndKeepValues(KeyValues hKv, KeyValues hNewKeyValues)
{
	char szSettingName[MM_SETTING_NAME_LENGTH];
	char szValue[MM_SETTING_VALUE_LENGTH];
	
	do
	{
		KvGetSectionName(hKv, szSettingName, sizeof szSettingName);
		//MultiMod_PrintDebug("* Section %s", szSettingName);
		
		if (KvGotoFirstSubKey(hKv, false))
		{
			//MultiMod_PrintDebug("* In");
			RemoveExtraKeysAndKeepValues(hKv, hNewKeyValues);
			KvGoBack(hKv);
		}
		
		else
		{
			KvGetSectionName(hKv, szSettingName, sizeof szSettingName);
			KvGetString(hKv, NULL_STRING, szValue, sizeof szValue);
			//MultiMod_PrintDebug("* Write Section %s %s", szSettingName, szValue);
			
			// Create a new key in the file key value.
			//KvJumpToKey(g_hFileKeyValues, szSettingName, true);
			
			KvSetString(g_hFileKeyValues, szSettingName, szValue);
			//KvGoBack(g_hFileKeyValues);
		}
	}
	
	while (KvGotoNextKey(hKv, false));
}

MMReturn CallValueChangeForward(bool PreForward = false, char[] szSettingName, char[] szSettingOldValue, char[] szSettingNewValue)
{
	switch (PreForward)
	{
		case true:
		{
			Call_StartForward(g_hForward_SettingValueChange_Pre);
		}
		
		case false:
		{
			Call_StartForward(g_hForward_SettingValueChange_Post);
		}
	}
	
	Call_PushString(szSettingName);
	Call_PushString(szSettingOldValue);
	Call_PushString(szSettingNewValue);
	
	MMReturn iResult;
	Call_Finish(iResult);
	
	return iResult;
}

public int Native_SettingExist(Handle hPlugin, int iArgs)
{
	char szSettingName[MM_SETTING_NAME_LENGTH];
	GetNativeString(1, szSettingName, sizeof szSettingName);
	
	// Check if it exists in our keyvalues
	if (KeyExistInKeyValuesStack(g_hKeyValues, szSettingName))
	{
		return 1;
	}
	
	return 0;
}

public int Native_GetSettingValue(Handle hPlugin, int iArgs)
{
	char szSettingName[MM_SETTING_NAME_LENGTH];
	char szSettingValue[MM_SETTING_VALUE_LENGTH];
	int iMaxSize;
	
	GetNativeString(1, szSettingName, sizeof szSettingName);
	//GetNativeString(2, szSettingValue, sizeof szSettingValue);
	iMaxSize = GetNativeCell(3);
	
	// Check if it exists in our keyvalues
	if (KeyExistInKeyValuesStack(g_hKeyValues, szSettingName))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Key %s does not exist in stack", szSettingName);
		return;
	}
	
	KvGetString(g_hKeyValues, szSettingName, szSettingValue, sizeof szSettingValue);
	SetNativeString(2, szSettingValue, iMaxSize);
}

public int Native_SetSettingValue(Handle hPlugin, int iArgs)
{
	char szSettingName[MM_SETTING_NAME_LENGTH];
	char szSettingNewValue[MM_SETTING_VALUE_LENGTH];
	char szSettingOldValue[MM_SETTING_VALUE_LENGTH];
	
	GetNativeString(1, szSettingName, sizeof szSettingName);
	GetNativeString(2, szSettingNewValue, sizeof szSettingNewValue);
	
	// Check if it exists in our keyvalues
	if (KeyExistInKeyValuesStack(g_hKeyValues, szSettingName))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Key %s does not exist in stack", szSettingName);
		return 0;
	}
	
	KvGetString(g_hKeyValues, szSettingName, szSettingOldValue, sizeof szSettingOldValue);
	
	MMReturn iRet;
	iRet = CallValueChangeForward(true, szSettingName, szSettingOldValue, szSettingNewValue);
	
	if (iRet == MMReturn_Stop)
	{
		return 0;
	}
	
	KvSetString(g_hKeyValues, szSettingName, szSettingNewValue);
	CallValueChangeForward(false, szSettingName, szSettingOldValue, szSettingNewValue);
	
	return 1;
}