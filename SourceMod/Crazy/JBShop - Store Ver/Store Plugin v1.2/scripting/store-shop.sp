#pragma semicolon 1

#include <sourcemod>
#include <store>

//New Syntax
#pragma newdecls required

#define PLUGIN_NAME "[Store] Shop Module"
#define PLUGIN_DESCRIPTION "Shop module for the Sourcemod Store."
#define PLUGIN_VERSION_CONVAR "store_shop_version"

//Config Globals
bool g_confirmItemPurchase;
bool g_hideEmptyCategories;
bool g_showCategoryDescriptions = true;
bool g_allowBuyingDuplicates;
int  g_equipAfterPurchase;
char sPriority_Categories[256];
char sPriority_Items[256];

char g_currencyName[64];

Handle g_buyItemForward;
Handle g_buyItemPostForward;

Menu categories_menu[MAXPLAYERS + 1];
int iLeft[MAXPLAYERS + 1];

ConVar ConVar_Enabled;

// Edit
Handle g_hForward_DisplayItem, g_hForward_OnDisplayEquipConfirmationMenu;
ArrayList g_Array_CustomItems;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = STORE_AUTHORS,
	description = PLUGIN_DESCRIPTION,
	version = STORE_VERSION,
	url = STORE_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Array_CustomItems = new ArrayList(MAX_CUSTOM_ITEM_NAME_LENGTH);
	
	CreateNative("Store_OpenShop", Native_OpenShop);
	CreateNative("Store_OpenShopCategory", Native_OpenShopCategory);
	
	g_buyItemForward = CreateGlobalForward("Store_OnBuyItem", ET_Event, Param_Cell, Param_Cell);
	g_buyItemPostForward = CreateGlobalForward("Store_OnBuyItem_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	// Edit
	// (int client, int category_id, int iItemId, char[] szDisplayName, int iDisplayNameSize, bool &bShow);
	g_hForward_DisplayItem = CreateGlobalForward("Store_Custom_OnDisplayItemInMenu", ET_Hook,
	Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_CellByRef);
	
	g_hForward_OnDisplayEquipConfirmationMenu = CreateGlobalForward("Store_Custom_OnDisplayEquipConfirmationMenu", ET_Event, Param_Cell, Param_Cell);

	CreateNative("Store_Custom_Shop_AddMenuItem", Native_Custom_AddMenuItem);
	CreateNative("Store_Custom_Shop_RemoveMenuItem", Native_Custom_RemoveMenuItem);

	RegPluginLibrary("store-shop");
	return APLRes_Success;
}

public int Native_Custom_AddMenuItem(Handle hPlugin, int argc)
{
	int iSize = g_Array_CustomItems.Length;
	
	char szInfo[MAX_CUSTOM_ITEM_NAME_LENGTH];
	char szInfo2[MAX_CUSTOM_ITEM_NAME_LENGTH];
	char szDispName[MAX_CUSTOM_ITEM_NAME_LENGTH];
	DataPack dp;
	
	GetNativeString(1, szInfo, sizeof szInfo);
	GetNativeString(2, szDispName, sizeof szDispName);
	Function func = GetNativeFunction(3);
	
	for(int i; i < iSize; i++)
	{
		dp = g_Array_CustomItems.Get(i);
		dp.Reset();
		
		dp.ReadString(szInfo2, sizeof szInfo2);
		
		if(StrEqual(szInfo, szInfo2))
		{
			delete dp;
			g_Array_CustomItems.Erase(i);
			break;
		}
	}
	
	dp = new DataPack();
	dp.WriteString(szInfo);
	dp.WriteString(szDispName);
	dp.WriteFunction(func);
	dp.WriteCell(hPlugin);
	
	g_Array_CustomItems.Push(dp);
}

public int Native_Custom_RemoveMenuItem(Handle hPlugin, int argc)
{
	int iSize = g_Array_CustomItems.Length;
	
	char szInfo[MAX_CUSTOM_ITEM_NAME_LENGTH];
	char szInfo2[MAX_CUSTOM_ITEM_NAME_LENGTH];
	DataPack dp;
	
	GetNativeString(1, szInfo, sizeof szInfo);
	
	for(int i; i < iSize; i++)
	{
		dp = g_Array_CustomItems.Get(i);
		dp.Reset();
		
		dp.ReadString(szInfo2, sizeof szInfo2);
		
		if(StrEqual(szInfo, szInfo2))
		{
			delete dp;
			g_Array_CustomItems.Erase(i);
			return true;
		}
	}
	
	return false;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");
	
	CreateConVar(PLUGIN_VERSION_CONVAR, STORE_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	ConVar_Enabled = CreateConVar("store_shopmenu_enabled", "1");
	
	LoadConfig();
}

public void Store_OnCoreLoaded()
{
	Store_AddMainMenuItem("Shop", "Shop Description", _, OnMainMenuShopClick, 1);
}

public void OnConfigsExecuted()
{
	Store_GetCurrencyName(g_currencyName, sizeof(g_currencyName));
}

public void Store_OnDatabaseInitialized()
{
	Store_RegisterPluginModule(PLUGIN_NAME, PLUGIN_DESCRIPTION, PLUGIN_VERSION_CONVAR, STORE_VERSION);
	
	FixSorting();
}

void LoadConfig()
{
	Handle kv = CreateKeyValues("root");

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/store/shop.cfg");

	if (!FileToKeyValues(kv, path))
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}

	char menuCommands[255];
	KvGetString(kv, "shop_commands", menuCommands, sizeof(menuCommands), "!shop /shop");
	Store_RegisterChatCommands(menuCommands, ChatCommand_OpenShop);

	g_confirmItemPurchase = view_as<bool>(KvGetNum(kv, "confirm_item_purchase", 0));
	g_hideEmptyCategories = view_as<bool>(KvGetNum(kv, "hide_empty_categories", 0));
	g_showCategoryDescriptions = view_as<bool>(KvGetNum(kv, "show_category_descriptions", 1));
	g_allowBuyingDuplicates = view_as<bool>(KvGetNum(kv, "allow_buying_duplicates", 0));
	
	// Edit default value, was 1
	g_equipAfterPurchase = (KvGetNum(kv, "equip_after_purchase", 2));
	
	if (KvJumpToKey(kv, "Menu Sorting"))
	{
		if (KvJumpToKey(kv, "Categories") && KvGotoFirstSubKey(kv, false))
		{
			CreatePriorityString(kv, sPriority_Categories, sizeof(sPriority_Categories));
			KvGoBack(kv);
		}
		
		if (KvJumpToKey(kv, "Items") && KvGotoFirstSubKey(kv, false))
		{
			CreatePriorityString(kv, sPriority_Items, sizeof(sPriority_Items));
			KvGoBack(kv);
		}
		
		KvGoBack(kv);
	}

	CloseHandle(kv);
	
	Store_AddMainMenuItem("Shop", "Shop Description", _, OnMainMenuShopClick, 1);
	
	// Fix. 
	// There is no sorting method for loading items from cache (as it is done in this shop), to fix it, we reload the items from database using the priority string
	FixSorting();
}

void FixSorting()
{
	if(!Store_Custom_IsDatabaseLoaded())
	{
		return;
	}
	
	Store_GetCategories(INVALID_FUNCTION, false, sPriority_Categories);
	Store_GetItems(INVALID_HANDLE, INVALID_FUNCTION, false, sPriority_Items);
}

void CreatePriorityString(Handle hKV, char[] sPriority, int maxsize)
{
	Format(sPriority, maxsize, "ORDER BY ");
	
	do {
		char sName[256];
		KvGetSectionName(hKV, sName, sizeof(sName));
		
		char sValue[256];
		KvGetString(hKV, NULL_STRING, sValue, sizeof(sValue));
		
		char sSource[256];
		Format(sSource, sizeof(sSource), "%s %s, ", sValue, sName);
		
		StrCat(sPriority, maxsize, sSource);
		
	} while (KvGotoNextKey(hKV, false));
	KvGoBack(hKV);
	
	Format(sPriority, maxsize, "%s;", sPriority);
	ReplaceString(sPriority, maxsize, ", ;", ";");
	
	//PrintToServer("Priority String: %s", sPriority);
}

public void OnMainMenuShopClick(int client, const char[] value)
{
	OpenShop(client);
}

public void ChatCommand_OpenShop(int client)
{	
	OpenShop(client);
}

void OpenShop(int client)
{
	if(!ConVar_Enabled.IntValue)
	{
		PrintToChat(client, "* Store Shop is not enabled.");
		return;
	}
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || categories_menu[client] != INVALID_HANDLE)
	{
		return;
	}
	
	if (Store_ClientIsDeveloper(client))
	{
		CPrintToChat(client, "%t%t", "Store Tag Colored", "Cannot access while developer");
		Store_OpenMainMenu(client);
		return;
	}
	
	Store_GetCategories(GetCategoriesCallback, true, sPriority_Categories, GetClientUserId(client));
}

public void GetCategoriesCallback(int[] ids, int count, any data)
{
	int client = GetClientOfUserId(data);
	
	if (!client)
	{
		return;
	}
	
	if (count < 1)
	{
		CPrintToChat(client, "%t%t", "Store Tag Colored", "No categories available");
		return;
	}
	
	categories_menu[client] = CreateMenu(ShopMenuSelectHandle);
	SetMenuTitle(categories_menu[client], "%T\n \n", "Shop", client);
	
	/* Edit */
	int iSize = g_Array_CustomItems.Length;
	DataPack dp;
	
	char szInfo[MAX_CUSTOM_ITEM_NAME_LENGTH], szDisplayName[MAX_CUSTOM_ITEM_NAME_LENGTH];
	
	bool bNoCategories = true;
	
	if(iSize > 0)
	{
		bNoCategories = false;
	}
	
	// szInfo
	// DispName
	// Function
	// Plugin
	for(int i; i < iSize; i++)
	{
		dp = g_Array_CustomItems.Get(i);
		dp.Reset();
		
		dp.ReadString(szInfo, sizeof szInfo);
		dp.ReadString(szDisplayName, sizeof szDisplayName);

		Format(szInfo, sizeof(szInfo), "callback_%s", szInfo);
		categories_menu[client].AddItem(szInfo, szDisplayName);
	}
	
	/* Edit finish */
	
	for (int category = 0; category < count; category++)
	{
		char requiredPlugin[STORE_MAX_REQUIREPLUGIN_LENGTH];
		Store_GetCategoryPluginRequired(ids[category], requiredPlugin, sizeof(requiredPlugin));
		
		if ( ( strlen(requiredPlugin) != 0 && !Store_IsItemTypeRegistered(requiredPlugin) ) )
		{
			iLeft[client] = count - category - 1;
			CheckLeft(client);
			continue;
		}
		
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, GetClientUserId(client));
		WritePackCell(hPack, ids[category]);
		iLeft[client] = count - category - 1;

		Handle filter = CreateTrie();
		SetTrieValue(filter, "is_buyable", 1);
		SetTrieValue(filter, "category_id", ids[category]);
		SetTrieValue(filter, "flags", GetUserFlagBits(client));

		Store_GetItems(filter, GetItemsForCategoryCallback, true, sPriority_Items, hPack);
		bNoCategories = false;
	}
	
	if (bNoCategories)
	{
		CPrintToChat(client, "%t%t", "Store Tag Colored", "No categories available");
	}
}

public void GetItemsForCategoryCallback(int[] ids, int count, any hPack)
{
	ResetPack(hPack);

	int client = GetClientOfUserId(ReadPackCell(hPack));
	int categoryId = ReadPackCell(hPack);

	CloseHandle(hPack);
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}

	if (!g_hideEmptyCategories || count > 0)
	{
		char sDisplayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetCategoryDisplayName(categoryId, sDisplayName, sizeof(sDisplayName));
		
		char sDescription[STORE_MAX_DESCRIPTION_LENGTH];
		Store_GetCategoryDescription(categoryId, sDescription, sizeof(sDescription));
		
		char sDisplay[sizeof(sDisplayName) + 1 + sizeof(sDescription)];
		Format(sDisplay, sizeof(sDisplay), "%s", sDisplayName);

		if (g_showCategoryDescriptions)
		{
			Format(sDisplay, sizeof(sDisplay), "%s\n%s", sDisplay, sDescription);
		}

		char sItem[12];
		IntToString(categoryId, sItem, sizeof(sItem));
		
		bool bShow = true;
		if (Store_GetCategoryServerRestriction(categoryId) && !Store_ProcessCategory(Store_GetServerID(), categoryId))
		{
			bShow = false;
		}
		
		AddMenuItem(categories_menu[client], sItem, sDisplay, bShow ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	CheckLeft(client);
}

void CheckLeft(int client)
{
	if (iLeft[client] <= 0)
	{
		SetMenuExitBackButton(categories_menu[client], true);
		DisplayMenu(categories_menu[client], client, 0);
		categories_menu[client] = null;
	}
}

public int ShopMenuSelectHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sMenuItem[64];
				GetMenuItem(menu, slot, sMenuItem, sizeof(sMenuItem));
				
				PrintToServer("sMenuItem : %s", sMenuItem);
				if(StrContains(sMenuItem, "callback_") != -1)
				{
					ReplaceStringEx(sMenuItem, sizeof sMenuItem, "callback_", "");
					
					int iSize = g_Array_CustomItems.Length;
					DataPack dp;
					char szCheckString[MAX_CUSTOM_ITEM_NAME_LENGTH];
					for(int i; i < iSize; i++)
					{
						dp = g_Array_CustomItems.Get(i);
						dp.Reset();
						
						dp.ReadString(szCheckString, sizeof szCheckString);
						
						PrintToServer("Check: %s - %s", sMenuItem, szCheckString);
						if(StrEqual(szCheckString, sMenuItem))
						{
							dp.ReadString(szCheckString, sizeof szCheckString);
							Function func = dp.ReadFunction();
							Handle hPlugin = dp.ReadCell();
							
							Call_StartFunction(hPlugin, func);
							Call_PushCell(client);
							Call_Finish();
							
							return;
						}
					}
				}
				
				OpenShopCategory(client, StringToInt(sMenuItem));
			}
		case MenuAction_Cancel:
			{
				if (slot == MenuCancel_ExitBack)
				{
					Store_OpenMainMenu(client);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

void OpenShopCategory(int client, int categoryId)
{
	if(!ConVar_Enabled.IntValue)
	{
		PrintToChat(client, "* Store Shop is not enabled.");
		return;
	}
	
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, GetClientUserId(client));
	WritePackCell(hPack, categoryId);

	Handle filter = CreateTrie();
	SetTrieValue(filter, "is_buyable", 1);
	SetTrieValue(filter, "category_id", categoryId);
	SetTrieValue(filter, "flags", GetUserFlagBits(client));

	Store_GetItems(filter, GetItemsCallback, true, sPriority_Items, hPack);
}

public void GetItemsCallback(int[] ids, int count, any hPack)
{
	ResetPack(hPack);

	int client = GetClientOfUserId(ReadPackCell(hPack));
	int categoryId = ReadPackCell(hPack);

	CloseHandle(hPack);
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	if (count == 0)
	{
		CPrintToChat(client, "%t%t", "Store Tag Colored", "No items in this category");
		OpenShop(client);

		return;
	}

	char categoryDisplayName[64];
	Store_GetCategoryDisplayName(categoryId, categoryDisplayName, sizeof(categoryDisplayName));
	
	Handle menu = CreateMenu(ShopCategoryMenuSelectHandle);
	SetMenuTitle(menu, "%T - %s\n \n", "Shop", client, categoryDisplayName);
	
	// Edit
	char ITEM_NAME[] = "%ITEM_NAME%",
		ITEM_DESC[] = "%ITEM_DESC%",
		ITEM_PRICE[] = "%ITEM_PRICE%",
		CURRENCY[] = "%CURRENCY%";
		
	char sPrice[20];
	Action iRet = Plugin_Continue;

	for (int item = 0; item < count; item++)
	{
		char sDisplayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(ids[item], sDisplayName, sizeof(sDisplayName));

		char sDescription[STORE_MAX_DESCRIPTION_LENGTH];
		Store_GetItemDescription(ids[item], sDescription, sizeof(sDescription));
		
		char sDisplay[sizeof(sDisplayName) + sizeof(sDescription) + 5];
		//Format(sDisplay, sizeof(sDisplay), "%s [%d %s]", sDisplayName, Store_GetItemPrice(ids[item]), g_currencyName);
		FormatEx(sDisplay, sizeof(sDisplay), "%s [%s %s]", ITEM_NAME, ITEM_PRICE, CURRENCY);
	
		if (g_showCategoryDescriptions)
		{
			//Format(sDisplay, sizeof(sDisplay), "%s\n%s", sDisplay, sDescription);
			Format(sDisplay, sizeof(sDisplay), "%s\n%s", sDisplay, ITEM_DESC);
		}

		char sItem[12];
		IntToString(ids[item], sItem, sizeof(sItem));
		
		bool bShow = true;
		if (Store_GetItemServerRestriction(ids[item]) && !Store_ProcessItem(Store_GetServerID(), ids[item]))
		{
			bShow = false;
		}
		
		// Edit
		iRet = Plugin_Continue;
		Call_StartForward(g_hForward_DisplayItem);
		Call_PushCell(client);
		Call_PushCell(categoryId);
		Call_PushCell(ids[item]);
		Call_PushStringEx(sDisplay, sizeof sDisplay, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(sizeof(sDisplay));
		Call_PushCellRef(bShow);
		Call_Finish(iRet);
		
		if(iRet == Plugin_Handled || iRet == Plugin_Stop)
		{
			continue;
		}
		
		FormatEx(sPrice, sizeof sPrice, "%d", Store_Custom_GetItemPrice(client, ids[item]));
		ReplaceString(sDisplay, sizeof sDisplay, ITEM_PRICE, sPrice, true);
		ReplaceString(sDisplay, sizeof sDisplay, ITEM_NAME, sDisplayName, true);
		ReplaceString(sDisplay, sizeof sDisplay, ITEM_DESC, sDescription, true);
		ReplaceString(sDisplay, sizeof sDisplay, CURRENCY, g_currencyName, true);
		
		// End Edit
		AddMenuItem(menu, sItem, sDisplay, bShow ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int ShopCategoryMenuSelectHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sMenuItem[64];
				GetMenuItem(menu, slot, sMenuItem, sizeof(sMenuItem));
				DoBuyItem(client, StringToInt(sMenuItem));
			}
		case MenuAction_Cancel:
			{
				if (slot == MenuCancel_ExitBack)
				{
					OpenShop(client);
				}
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

void DoBuyItem(int client, int itemId, bool confirmed = false, bool checkeddupes = false)
{
	if (g_confirmItemPurchase && !confirmed)
	{
		DisplayConfirmationMenu(client, itemId);
	}
	else if (!g_allowBuyingDuplicates && !checkeddupes)
	{
		char itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(itemId, itemName, sizeof(itemName));

		Handle hPack = CreateDataPack();
		WritePackCell(hPack, GetClientUserId(client));
		WritePackCell(hPack, itemId);

		Store_GetUserItemsCount(GetSteamAccountID(client), itemName, DoBuyItem_ItemCountCallBack, hPack);
	}
	else
	{
		Action result = Plugin_Continue;

		Call_StartForward(g_buyItemForward);
		Call_PushCell(client);
		Call_PushCell(itemId);
		Call_Finish(result);

		if (result == Plugin_Handled || result == Plugin_Stop)
		{
			return;
		}
		
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, GetClientUserId(client));
		WritePackCell(hPack, itemId);

		Store_BuyItem(GetSteamAccountID(client), itemId, OnBuyItemComplete, hPack);
	}
}

public void DoBuyItem_ItemCountCallBack(int count, any hPack)
{
	ResetPack(hPack);

	int client = GetClientOfUserId(ReadPackCell(hPack));
	int itemId = ReadPackCell(hPack);

	CloseHandle(hPack);
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}

	if (count <= 0)
	{
		DoBuyItem(client, itemId, true, true);
	}
	else
	{
		char displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		CPrintToChat(client, "%t%t", "Store Tag Colored", "Already purchased item", displayName);
	}
}

void DisplayConfirmationMenu(int client, int itemId)
{
	char displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
	Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));

	Handle menu = CreateMenu(ConfirmationMenuSelectHandle);
	SetMenuTitle(menu, "%T", "Item Purchase Confirmation", client,  displayName);

	char value[8];
	IntToString(itemId, value, sizeof(value));

	AddMenuItem(menu, value, "Yes");
	AddMenuItem(menu, "no", "No");

	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int ConfirmationMenuSelectHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sMenuItem[64];
				GetMenuItem(menu, slot, sMenuItem, sizeof(sMenuItem));
				
				if (StrEqual(sMenuItem, "no"))
				{
					OpenShop(client);
				}
				else
				{
					DoBuyItem(client, StringToInt(sMenuItem), true);
				}
			}
		case MenuAction_DisplayItem:
			{
				char sDisplay[64];
				GetMenuItem(menu, slot, "", 0, _, sDisplay, sizeof(sDisplay));

				char buffer[255];
				Format(buffer, sizeof(buffer), "%T", sDisplay, client);

				return RedrawMenuItem(buffer);
			}
		case MenuAction_Cancel: OpenShop(client);
		case MenuAction_End: CloseHandle(menu);
	}

	return false;
}

public void OnBuyItemComplete(bool success, any hPack)
{
	ResetPack(hPack);

	int client = GetClientOfUserId(ReadPackCell(hPack));
	int itemId = ReadPackCell(hPack);

	CloseHandle(hPack);
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}

	if (!success)
	{
		CPrintToChat(client, "%t%t", "Store Tag Colored", "Not enough credits to buy", g_currencyName);
		return;
	}
		
	char displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
	Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
	CPrintToChat(client, "%t%t", "Store Tag Colored", "Item Purchase Successful", displayName);
	
	if (g_equipAfterPurchase)
	{
		Action iRet = Plugin_Continue;
		Call_StartForward(g_hForward_OnDisplayEquipConfirmationMenu);
		{
			Call_PushCell(client);
			Call_PushCell(itemId);
		}
		Call_Finish(iRet);
		
		if(iRet == Plugin_Continue)
		{
			Handle hMenu = CreateMenu(EquipAfterPurchaseMenuHandle);
			SetMenuTitle(hMenu, "%t", "Item Purchase Menu Title", displayName);
			
			char sItemID[64];
			IntToString(itemId, sItemID, sizeof(sItemID));
			
			AddMenuItem(hMenu, sItemID, "Yes");
			AddMenuItem(hMenu, "", "No");
			
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
	}

	else
	{	
		OpenShop(client);
	}

	//int loadout = Store_GetClientCurrentLoadout(client);
	//Store_SetItemEquippedState(GetSteamAccountID(client), itemId, loadout, true, EquipItemCallback);

	Call_StartForward(g_buyItemPostForward);
	Call_PushCell(client);
	Call_PushCell(itemId);
	Call_PushCell(success);
	Call_Finish();
}

public int EquipAfterPurchaseMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				char sMenuItem[64]; char sDisplay[64];
				GetMenuItem(menu, slot, sMenuItem, sizeof(sMenuItem), _, sDisplay, sizeof(sDisplay));
				
				if (StrEqual(sDisplay, "Yes"))
				{
					int loadout = Store_GetClientCurrentLoadout(client);
					int itemId = StringToInt(sMenuItem);
					Store_SetItemEquippedState(GetSteamAccountID(client), itemId, loadout, true, EquipItemCallback);
					
					char displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
					Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
					
					CPrintToChat(client, "%t%t", "Store Tag Colored", "Item Purchase Equipped", displayName, loadout);
				}
				
				OpenShop(client);
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

public void EquipItemCallback(int accountId, int itemId, int loadoutId, any data)
{
	
}

public int Native_OpenShop(Handle plugin, int params)
{
	OpenShop(GetNativeCell(1));
}

public int Native_OpenShopCategory(Handle plugin, int params)
{
	OpenShopCategory(GetNativeCell(1), GetNativeCell(2));
}
