Menu CreateUpgradeMenu(int client)
{
	Menu hUpgradeMenu = CreateMenu(MenuHandler_UpgradeMenu, MENU_ACTIONS_DEFAULT | MenuAction_DrawItem);
	{
		// Settings
		SetMenuTitle(hUpgradeMenu, "Item Upgrades Menu:");
		SetMenuExitBackButton(hUpgradeMenu, true);
		SetMenuPagination(hUpgradeMenu, 7);
	}
	
	int iStoreItemId;
	char szCurrency[35];
	char szPriceString[sizeof(szCurrency) + 5];
	char szVIPOnlyString[12];
	
	char szItemDisplayName[STORE_MAX_DISPLAY_NAME_LENGTH];
	char szFormattedDisplayName[256];
	int iCurrentUpgrade, iNextUpgrade;
	char szInfo[5];
	
	Store_GetCurrencyName(szCurrency, sizeof szCurrency);
	
	int iAdded;
	for (int iItem; iItem < Item_Count; iItem++)
	{
		if (!HasItemUpgrades(iItem))
		{
			continue;
		}
		
		// Was it disabled by the store ?
		iStoreItemId = FindStoreIndexFromItemIndex(iItem);
		if (iStoreItemId == -1)
		{
			continue;
		}
		
		FormatEx(szInfo, sizeof szInfo, "%d", iItem);
		
		Store_GetItemDisplayName(iStoreItemId, szItemDisplayName, sizeof szItemDisplayName);
		
		iCurrentUpgrade = g_iClientCurrentItemUpgrade[client][iItem];
		iNextUpgrade = iCurrentUpgrade + 1;
		
		if (iNextUpgrade < g_iItemUpgradeCount[iItem])
		{
			FormatEx(szPriceString, sizeof szPriceString, "[%d %s]", g_iItemUpgradePrice[iItem][iNextUpgrade], szCurrency);
		}
		
		else
		{
			szPriceString = "";
		}
		
		if (IsVIPOnlyItem(iItem) && !IsClientVIP(client))
		{
			FormatEx(szVIPOnlyString, sizeof szVIPOnlyString, "[VIP ONLY]");
		}
		
		else
		{
			szVIPOnlyString = "";
		}
		
		FormatEx(szFormattedDisplayName, sizeof szFormattedDisplayName, "%s [Upgrade: %s -> %s] %s %s", 
			szItemDisplayName, 
			//iCurrentUpgrade == ItemUpgrade_Base ? BASE_UPGRADE_NAME : g_szItemUpgradeName[iItem][iCurrentUpgrade],
			g_szItemUpgradeName[iItem][iCurrentUpgrade], 
			iNextUpgrade < g_iItemUpgradeCount[iItem] ? g_szItemUpgradeName[iItem][iNextUpgrade] : "None", 
			szPriceString, szVIPOnlyString);
		
		AddMenuItem(hUpgradeMenu, szInfo, szFormattedDisplayName);
		iAdded++;
	}
	
	if(!iAdded)
	{
		delete hUpgradeMenu;
		CPrintToChat(client, "There are no items to upgrade.");
		return null;
	}
	
	return hUpgradeMenu;
}

public int MenuHandler_UpgradeMenu(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			g_hUpgradeMenu[param1] = null;
		}
		
		case MenuAction_DrawItem:
		{
			char szInfo[5];
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			int iItem = StringToInt(szInfo);
			
			if (IsVIPOnlyItem(iItem) && !IsClientVIP(param1))
			{
				return ITEMDRAW_DISABLED;
			}
			
			if (iItem == Item_Lightsaber || iItem == Item_Credit)
			{
				if (!g_bHasItem[param1][iItem])
				{
					return ITEMDRAW_DISABLED;
				}
			}
			
			int iNextUpgrade = g_iClientCurrentItemUpgrade[param1][iItem] + 1;
			if (iNextUpgrade >= g_iItemUpgradeCount[iItem])
			{
				return ITEMDRAW_DEFAULT;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			char szInfo[5];
			GetMenuItem(menu, param2, szInfo, sizeof szInfo);
			
			int iItem = StringToInt(szInfo);
			
			if (iItem == Item_Lightsaber || iItem == Item_Credit)
			{
				if (!g_bHasItem[param1][iItem])
				{
					return 0;
				}
			}
			
			int iNextUpgrade = g_iClientCurrentItemUpgrade[param1][iItem] + 1;
			
			if (iNextUpgrade >= g_iItemUpgradeCount[iItem])
			{
				return 0;
			}
			
			int iPrice = g_iItemUpgradePrice[iItem][iNextUpgrade];
			
			DataPack hPack = CreateDataPack();
			WritePackCell(hPack, param1);
			WritePackCell(hPack, iItem);
			WritePackCell(hPack, iNextUpgrade);
			WritePackCell(hPack, iPrice);
			Store_GetCredits(GetSteamAccountID(param1), StoreCallback_OnGetCreditsForBuyUpgrade, hPack);
		}
	}
	
	return 0;
}

public void StoreCallback_OnGetCreditsForBuyUpgrade(int iCredits, DataPack hPack)
{
	ResetPack(hPack);
	int client = ReadPackCell(hPack);
	int iItem = ReadPackCell(hPack);
	int iNextUpgrade = ReadPackCell(hPack);
	int iPrice = ReadPackCell(hPack);
	
	char szItemName[STORE_MAX_NAME_LENGTH];
	if (iCredits < iPrice)
	{
		delete hPack;
		
		Store_GetItemDisplayName(FindStoreIndexFromItemIndex(iItem), szItemName, sizeof szItemName);
		
		PrintReason(client, true, Reason_NotEnoughCredits_Upgrade, iPrice - iCredits, g_szItemUpgradeName[iItem][iNextUpgrade], szItemName);
		return;
	}
	
	char szLogReason[MAX_LOG_REASON_LENGTH];
	Store_GetItemName(FindStoreIndexFromItemIndex(iItem), szItemName, sizeof szItemName);
	
	FormatEx(szLogReason, sizeof szLogReason, "Upgrade Buy: %s - %d", szItemName, iNextUpgrade);
	
	Store_RemoveCredits(GetSteamAccountID(client), iPrice, StoreCallback_OnRemoveCreditsForBuyUpgrade, hPack, szLogReason);
}

public void StoreCallback_OnRemoveCreditsForBuyUpgrade(int accountId, int credits, bool bIsNegative, DataPack hPack)
{
	ResetPack(hPack);
	int client = ReadPackCell(hPack);
	int iItem = ReadPackCell(hPack);
	int iNextUpgrade = ReadPackCell(hPack);
	int iPrice = ReadPackCell(hPack);
	
	delete hPack;
	
	g_iClientCurrentItemUpgrade[client][iItem] = iNextUpgrade;
	
	char szDisplayName[STORE_MAX_DISPLAY_NAME_LENGTH];
	Store_GetItemDisplayName(FindStoreIndexFromItemIndex(iItem), szDisplayName, sizeof szDisplayName);
	
	char szCurrency[20];
	Store_GetCurrencyName(szCurrency, sizeof szCurrency);
	//PrintReason(client, true, Reason_BoughtItem, g_szUpgradeName[iItem], szItemName, iPrice, iCredits);
	CPrintToChat(client, "You have bought upgrade \x04 %s \x01 for item \x03 %s \x01 for \x05 %d %s", 
		g_szItemUpgradeName[iItem][iNextUpgrade], szDisplayName, iPrice, szCurrency);
	
	DoBuyClientUpgrade(client, iItem, iNextUpgrade);
} 