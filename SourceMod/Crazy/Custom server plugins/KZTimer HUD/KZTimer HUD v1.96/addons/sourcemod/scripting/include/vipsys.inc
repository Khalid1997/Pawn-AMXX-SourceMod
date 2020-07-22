/*
**
*/
#if defined _vipsys_included
 #endinput
#endif
#define _vipsys_included

forward void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP);

native bool VIPSys_Client_IsVIP(int client);

typedef VIPMenuCallback_OnItemAction = function int(Menu menu, char[] szInfo, MenuAction action, int param1, int param2);
native void VIPSys_Menu_AddItem(char[] szInfo, char[] szDisplayName, MenuAction actions = MENU_ACTIONS_ALL, int iDrawType = ITEMDRAW_DEFAULT,
	VIPMenuCallback_OnItemAction callback, int priority);
native void VIPSys_Menu_RemoveItem(char[] szInfo);

enum VIPMenuProperty
{
	Property_DisplayName,
	Property_Actions,
	Propery_DrawType
}

native void VIPSys_Menu_SetItemProperty(char[] szInfo, VIPMenuProperty prop, any ...);

public SharedPlugin __pl_vipsys =
{
	name = "vipsys",
	file = "vipsys.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_vipsys_SetNTVOptional()
{
	MarkNativeAsOptional("VIPSys_Client_IsVIP");
	MarkNativeAsOptional("VIPSys_Menu_AddItem");
	MarkNativeAsOptional("VIPSys_Menu_RemoveItem");
	MarkNativeAsOptional("VIPSys_Menu_SetItemProperty");
}
#endif
