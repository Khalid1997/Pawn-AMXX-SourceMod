public Action Store_OnBuyItem(int client, int iStoreItemId)
{
	int iItem = FindItemIndexFromStoreIndex(iStoreItemId);
	if (iItem == Item_Invalid)
	{
		return Plugin_Continue;
	}
	
	if(DaysAPI_IsDayRunning())
	{
		return Plugin_Handled;
	}
	
	if(!g_bReady)
	{
		return Plugin_Handled;
	}
	
	return (!CanBuyItem(client, iItem, true) ? Plugin_Handled : Plugin_Continue);
}

public void Store_OnBuyItem_Post(int client, int iStoreItemId, bool bSuccess)
{
	if(!bSuccess)
	{
		return;
	}
	
	int iItem = FindItemIndexFromStoreIndex(iStoreItemId);
	if(iItem == Item_Invalid)
	{
		return;
	}
	
	// Immediately use our item.
	g_iClientItemBuyCountThisRound[client][iItem]++;
	if(g_iItemClientRoundBuyLimit_RoundReset[iItem] != BUYLIMIT_NO_LIMIT && g_iClientItemBuyCountThisRound_RoundReset[client][iItem] == 0)
	{
		g_iClientItemBuyCountThisRound_RoundReset[client][iItem] = g_iItemClientRoundBuyLimit_RoundReset[iItem] + g_iRounds;
	}
	
	g_iItemBuyCountThisRound[iItem]++;
	
	Store_Custom_UseItem(iStoreItemId, client);
}

public Action Store_Custom_OnDisplayEquipConfirmationMenu(int client, int iStoreItemId)
{
	char szType[STORE_MAX_TYPE_LENGTH];
	Store_GetItemType(iStoreItemId, szType, sizeof szType);
	
	// Disable Confirmation menu for all items that use our plugin
	if(StrEqual(szType, Store_Items_ItemType))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}	

public void Store_Custom_OnGetItemPrice(int client, int iStoreItemId, int &iPrice)
{
	if(!client)
	{
		return;
	}
	
	int iItem = FindItemIndexFromStoreIndex(iStoreItemId);
	if(iItem == Item_Invalid)
	{
		return;
	}
	
	if(!HasItemUpgrades(iItem))
	{
		return;
	}
	
	if(g_iClientCurrentItemUpgrade[client][iItem] == ItemUpgrade_Base)
	{
		return;
	}
	
	int iOverridePrice = g_iItemPriceOverride[iItem][g_iClientCurrentItemUpgrade[client][iItem]];
	if(iOverridePrice == -1)
	{
		return;
	}
	
	iPrice = iOverridePrice;
}

public Action Store_Custom_OnDisplayItemInMenu(int client, int category, int iStoreItemId, char[] szDisplayName, int iMax, bool &bEnabled)
{
	int iItem = FindItemIndexFromStoreIndex(iStoreItemId);
	if(iItem == Item_Invalid)
	{
		return Plugin_Continue;
	}
	
	if(g_bHasItem[client][iItem])
	{
		bEnabled = false;
	}
	
	if(!HasItemUpgrades(iItem))
	{
		return Plugin_Continue;
	}
	
	bool bFoundItemDesc = (StrContains(szDisplayName, Store_ITEM_DESC, true) != -1);

	{
		FormatEx(szDisplayName, iMax, "%s [%s] [%s %s]%s%s",
		Store_ITEM_NAME, g_szItemUpgradeName[ iItem ][ g_iClientCurrentItemUpgrade[client][iItem] ],
		Store_ITEM_PRICE, Store_CURRENCY,
		bFoundItemDesc ? "\n" : "", bFoundItemDesc ? Store_ITEM_DESC : "");
	}
	
	return Plugin_Continue;
}

//public void MenuClickCallback_Upgrade(int client, const char[] value)
public void MenuClickCallback_Upgrade(int client)
{
	//PrintToServer("Upgrade Menu Start");
	
	if( (g_hUpgradeMenu[client] = CreateUpgradeMenu(client) ) == null )
	{
		return;
	}
	
	DisplayMenu( g_hUpgradeMenu[client], client, MENU_TIME_FOREVER );
}

public Store_ItemUseAction OnShopItem_Use(int client, int itemId, bool equipped)
{
	Store_ItemUseAction iReturn = Store_DeleteItem;
	switch(FindItemIndexFromStoreIndex(itemId))
	{
		case Item_Invisibility:
		{
			Give_Invisibility(client);
		}
		
		case Item_Immortal:
		{
			Give_Immortal(client);
		}
		
		case Item_OpenJail:
		{
			Give_OpenJail(client);
		}
		
		case Item_Deagle:
		{
			Give_Deagle(client);
		}
		
		case Item_Lightsaber:
		{
			// This item is permanent, do not delete.
			iReturn = Store_DoNothing;
			Give_Lightsaber(client);
		}
		
		case Item_GuardSkin:
		{
			Give_GuardSkin(client);
		}
		
		case Item_Bomb:
		{
			Give_Bomb(client);
		}
		
		case Item_Speed:
		{
			Give_Speed(client);
		}
		
		case Item_Credit:
		{
			Give_CreditMultiplier(client);
			iReturn = Store_DoNothing;
		}
		
		case Item_AWP:
		{
			Give_AWP(client);
		}
	}
	
	//PrintToChatAll("Deleted Item that you bought %N", client);
	return iReturn;
}

public void Store_OnReloadItemsPost()
{
	PrintToServer("************");
	PrintToServer("** Reset ***");
	PrintToServer("************");
	
	SetArrayValue(g_iItemUpgradeCount, sizeof(g_iItemUpgradeCount), 0, 0);
	SetArrayValue(g_iStoreItemIdCache, sizeof(g_iStoreItemIdCache), -1, 0);
	SetArrayValue(g_bItemUsable, sizeof g_bItemUsable, false);
	
	SetArrayValue(g_iItemRoundBuyLimit, sizeof g_iItemRoundBuyLimit, BUYLIMIT_NO_LIMIT, 0);
	SetArrayValue(g_iItemClientRoundBuyLimit, sizeof g_iItemClientRoundBuyLimit, BUYLIMIT_NO_LIMIT, 0);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_hUpgradeMenu[i] != null)
		{
			delete g_hUpgradeMenu[i];
			g_hUpgradeMenu[i] = null;
		}
	}
	
	ResetParamArray();	
	
	StringMap hFilter = new StringMap();
	SetTrieValue(hFilter, "is_buyable", 1);
	SetTrieString(hFilter, "type", Store_Items_ItemType);
	
	Store_GetItems(hFilter, StoreCallback_OnGetItems, true, "ASC", 0);
	
	ReadUpgradesFile();
}

public void StoreCallback_OnGetItems(int[] iStoreItemIds, int iCount, any data)
{
	//PrintToServer("OnGetItems: Got %d items", iCount);
	
	for(int i; i < iCount; i++)
	{
		int iItemId = FindItemIndexFromStoreIndex(iStoreItemIds[i]);
		
		if(iItemId != Item_Invalid)
		{
			// Cache store item indexes
			g_iStoreItemIdCache[iItemId] = iStoreItemIds[i];
		}
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		OnClientPutInServer(i);
	}
}

void ReadUpgradesFile()
{
	char szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFile, sizeof szFile, "configs/jbitems.cfg");
	
	if(!FileExists(szFile))
	{
		LogDebug("Plugin file does not exist: %s", szFile);
		return;
	}

	char szUpgradeSectionName[MAX_UPGRADE_NAME_LENGTH];
	KeyValues hKv = CreateKeyValues(KEY_BASE);
	FileToKeyValues(hKv, szFile);
	
	KvGetSectionName(hKv, szUpgradeSectionName, sizeof szUpgradeSectionName);
	//PrintToServer("Parent Section: %s %d", szUpgradeSectionName, KvNodesInStack(hKv));
	
	int iUpgradePrice, ItemPriceOverride;
	char szUpgradeName[MAX_UPGRADE_NAME_LENGTH];
	int iNum;
	
	for(int i, j; i < Item_Count; i++)
	{
		if(!KvJumpToKey(hKv, Store_Items_ItemName[i], false))
		{
			LogDebug("Could not find section %s", Store_Items_ItemName[i]);
			g_bItemUsable[i] = false;
			continue;
		}
		
		LogDebug("Section %s", Store_Items_ItemName[i]);
		
		iNum = KvGetNum(hKv, KEY_ITEM_ROUND_BUY_LIMIT, BUYLIMIT_NO_LIMIT);
		g_iItemRoundBuyLimit[i] = iNum < BUYLIMIT_NO_LIMIT ? BUYLIMIT_NO_LIMIT : iNum;
		
		iNum = KvGetNum(hKv, KEY_ITEM_CLIENT_BUY_LIMIT, BUYLIMIT_NO_LIMIT);
		g_iItemClientRoundBuyLimit[i] = iNum < BUYLIMIT_NO_LIMIT ? BUYLIMIT_NO_LIMIT : iNum;
		
		iNum = KvGetNum(hKv, KEY_ITEM_CLIENT_BUY_LIMIT_ROUNDRESET, 1);
		g_iItemClientRoundBuyLimit_RoundReset[i] = iNum < 1 ? 1 : iNum;

		if(!KvJumpToKey(hKv, KEY_BASE_UPGRADE, false))
		{
			LogDebug("Could not find base section %s to read. Rendering item not usable.", KEY_BASE_UPGRADE);
			g_bItemUsable[i] = false;
			continue;
		}
		
		KvGetSectionName(hKv, szUpgradeSectionName, sizeof szUpgradeSectionName);
		LogDebug("\t-> Sub-Section: %s", szUpgradeSectionName);
		// Get base params
		KvGetString(hKv, KEY_UPGRADE_NAME, szUpgradeName, sizeof szUpgradeName, BASE_ITEM_UPGRADE_NAME);
		strcopy(g_szItemUpgradeName[i][ItemUpgrade_Base], sizeof g_szItemUpgradeName[][], szUpgradeName);
		GetParamsForItem(hKv, i, ItemUpgrade_Base);
		g_bItemUsable[i] = true;
		g_iItemUpgradeCount[i] = 1;
		
		LogDebug("\t-> Done Reading Sub-Section %s", szUpgradeSectionName);
		
		// Go back into item section
		KvGoBack(hKv);
		
		// Loop for upgrades
		for (j = 1; j < MAX_UPGRADES_PLUGIN; j++)
		{
			FormatEx(szUpgradeSectionName, sizeof szUpgradeSectionName, "%s%d", KEY_UPGRADE_SECTION, j);
			
			LogDebug("\t-> Sub-Section: %s", szUpgradeSectionName);
			
			if(!KvJumpToKey(hKv, szUpgradeSectionName, false))
			{
				// Break it as we shouldn't go for whats next if we couldn't get whats first
				LogDebug("\t\t-> Upgrade section %s was not found", szUpgradeSectionName);
				break;
			}
			
			// Actually start getting stuff
			KvGetString(hKv, KEY_UPGRADE_NAME, szUpgradeName, sizeof szUpgradeName, szUpgradeSectionName);
			iUpgradePrice = KvGetNum(hKv, KEY_UPGRADE_PRICE, 0);
			ItemPriceOverride = KvGetNum(hKv, KEY_ITEM_PRICE_OVERRIDE, -1);
			
			if(iUpgradePrice < 0)
			{
				LogDebug("Adjusted price of upgrade %s for item %s to 0", szUpgradeSectionName, Store_Items_ItemName[i]);
				iUpgradePrice = 0;
			}
			
			if(ItemPriceOverride < 0)
			{
				LogDebug("Adjusted price of override price for upgrade %s for item %s to 0", szUpgradeSectionName, Store_Items_ItemName[i]);
				ItemPriceOverride = 0;
			}
			
			strcopy(g_szItemUpgradeName[i][j], sizeof g_szItemUpgradeName[][], szUpgradeName);
			g_iItemUpgradePrice[i][j] = iUpgradePrice;
			g_iItemPriceOverride[i][j] = ItemPriceOverride;
			
			LogDebug("\t\t-> (Found Upgrade) Name: %s - Price: %d - Override Price: %d", g_szItemUpgradeName[i][j], iUpgradePrice, ItemPriceOverride);
			GetParamsForItem(hKv, i, j);
			
			g_iItemUpgradeCount[i]++;
			LogDebug("\t-> Done Reading Sub-Section %s", szUpgradeSectionName);
			
			KvGoBack(hKv);
		}
		
		LogDebug("Done Reading Section %s", Store_Items_ItemName[i]);
		KvGoBack(hKv);
	}
	
	delete hKv;
}