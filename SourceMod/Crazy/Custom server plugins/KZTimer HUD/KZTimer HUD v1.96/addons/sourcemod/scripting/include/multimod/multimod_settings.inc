/*
**
*/
#if defined _multimod_settings_included
 #endinput
#endif
#define _multimod_settings_included

// True if success, false if setting already exist.
// When creating a new Setting, do not set the variable in your plugin after this function
// Example:
// Wrong:
// MultiMod_Settings_Create
// Check if the file had a different value, if yes, set it to that (it will force a forward call, regardless of bCallChangeForward
// bCallChangeForward = true then it will immediately execute MultiMod_Settings_ValueChanges forward (only post) with values "" and new value.
// Keep in mind that the value will change with the next reload, unless the (pre)forward blocks it.
//native bool MultiMod_Settings_Create(char[] szSettingName, char[] szDefaultValue, bool bCallChangeForward = false, bool bBackCheckFile = true, bool bReloadFile = false);
native bool MultiMod_Settings_Create(char[] szSettingName, char[] szDefaultValue, bool bCallChangeForward = false, bool bBackCheckFile = true, bool bReloadFile = false);
native bool MultiMod_Settings_Exist(char[] szSettingName);
//native int MultiMod_Settings_Create2(char[] szSettingName, char[] szSettingDefaultValue, bool bCallChangeForward = false, bool bBackCheckFile = true, MultiModSettingsValueChangeForward Callback)

// False if it does not exist.
native void MultiMod_Settings_GetValue(char[] szSettingName, char[] szValueString, int iMaxSize);

// False if a plugin blocked the change (from the forwards)
native bool MultiMod_Settings_SetValue(char[] szSettingName, char[] szValueString);

forward MMReturn MultiMod_Settings_OnValueChange_Pre(char[] szSettingName, char[] szOldValue, char[] szNewValue);
forward void MultiMod_Settings_OnValueChange(char[] szSettingName, char[] szOldValue, char[] szNewValue);

// Reread the file.
native bool MultiMod_Settings_Reload();

/*
public SharedPlugin __pl_multimod_settings =
{
	name = MM_LIB_SETTINGS,
	file = "multimod_settings.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_multimod_settings_SetNTVOptional()
{
	MarkNativeAsOptional("MultiMod_Settings_Create");
	MarkNativeAsOptional("MultiMod_Settings_Exist");
	
	MarkNativeAsOptional("MultiMod_Settings_GetValue");
	MarkNativeAsOptional("MultiMod_Settings_SetValue");
	
	MarkNativeAsOptional("MultiMod_Settings_Reload");
}
#endif
*/