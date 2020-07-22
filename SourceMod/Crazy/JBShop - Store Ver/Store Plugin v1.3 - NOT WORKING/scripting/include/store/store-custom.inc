#if defined _store_custom_included
#endinput
#endif
#define _store_custom_included


native void Store_Custom_UseItem(int iItemId, int client);

stock char Store_ITEM_NAME[] = "%ITEM_NAME%",
			Store_ITEM_DESC[] = "%ITEM_DESC%",
			Store_ITEM_PRICE[] = "%ITEM_PRICE%",
			Store_CURRENCY[] = "%CURRENCY%";
// Returning Plugin_Handled will not show the item
// bEnabled is to wether make the item usable or not 
// (ITEMDRAW_DISABLED)
// %ITEM_NAME%
// %PRICE% to display the price of the item there
// %ITEM_DESCRIPTION%
// %CURRENCY%
/*
	FormatEx(sDisplay, sizeof(sDisplay), "%s [%s %s]", ITEM_NAME, ITEM_PRICE, CURRENCY);
 	if (g_showCategoryDescriptions)
	{
		Format(sDisplay, sizeof(sDisplay), "%s\n%s", sDisplay, ITEM_DESC);
	}
	
*/
// Itemids are all the ids in the database

#define MAX_LOG_REASON_LENGTH		128
forward Action Store_Custom_OnDisplayItemInMenu(int client, int category_id, int iItemId, char[] szDisplayName, int iDisplayNameSize, bool &bEnabled);

// Client = 0, no client, default price
forward void Store_Custom_OnGetItemPrice(int client, int iItemId, int &iPrice);

native int Store_Custom_GetItemPrice(int client, int iItemId);

forward Action Store_Custom_OnDisplayEquipConfirmationMenu(int client, int iItemId);

native bool Store_Custom_IsDatabaseLoaded();

native Database Store_Custom_GetSQLHandle();

native void Store_Custom_RemoveItemType(char[] szType);

#define MAX_CUSTOM_ITEM_NAME_LENGTH 64
typedef ShopMenuClickCallback = function void(int client);
native void Store_Custom_Shop_AddMenuItem(char[] szInfo, char[] szDisplayName, ShopMenuClickCallback func); 
native bool Store_Custom_Shop_RemoveMenuItem(char[] szInfo); 