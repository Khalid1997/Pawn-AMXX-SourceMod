#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <store>
#include <multicolors>
#include <sdkhooks>
#include <sdktools>
#include <smartjaildoors>
#include <getplayers>
#include <daysapi>
#include <cstrike>
#include <dbi>

//#define DEBUG

#if defined DEBUG
#define LogDebug LogMessage
#endif

public Plugin myinfo = 
{
	name = "JBShop Items for Store API", 
	author = PLUGIN_AUTHOR, 
	description = "Nope", 
	version = PLUGIN_VERSION, 
	url = "Nope URL"
};

/*
	1-10 sec invisibility
	2-10 sec Immortality
	3-Open Jail
	4-Deagle with 2 Bullets
	5-LightSaber (+15% damage slash, +0% damage stab)
	6-Guard Skin(10 sec)
	7-Respawn as a ghost for 10 sec // VIPS ONLY // Deleted
	8-Suicide Bomber(5sec ticking & ct's will hear the ticking)
	9-press E for speed
	10-Credits x1.25 // VIPS ONLY
	11-AWP (1 Bullet)
*/

/* // Upgrade Menu
	1-12 sec invisibility(LVL 2) - 14 sec invisibility(LVL 3)
	2-12 sec Immortality(LVL 2) - 14 sec Immortality(LVL 3)
	3-Open Jail & Blind Ct's for 2 sec(LVL 2) - Open Jail & Blind ct's for 5 sec(LVL 3)
	4-Deagle with 4 Bullets(LVL 2) - Deagle with 7 Bullets(LVL 3)
	5-LightSaber (+30% damage slash, +10% damage stab)(LVL 2) - LightSaber (+50% damage slash, +15% damage stab)(LVL 3)
	6-Guard Skin(20 sec & empty dgl & m4)(LVL 2) - Guard Skin(Whole round & empty dgl & m4)
	7-Respawn as a ghost for 30 sec(LVL 2) - Respawn as a ghost for 60 sec(LVL 3) // Deleted
	8-Suicide Bomber(10sec ticking & ct's won't hear)(LVL 2) - Suicide Bomber(Explode instantly)
	9-Press E for speed(+More speed)(LVL 2) - Press E for speed(++More speed)(LVL 3)
	10-Credits x1.5(LVL 2) - Credits x1.75(LVL 3)
	11-AWP(2 Bullets)(LVL 2) - AWP(3 Bullets)(LVL 3)
*/
/* *************************************************
				Items list
   ************************************************* */

enum
{
	// Do not use
	Item_Invalid = -1, 
	
	// Use
	Item_Invisibility, 
	Item_Immortal, 
	Item_OpenJail, 
	Item_Deagle, 
	Item_Lightsaber, 
	Item_GuardSkin, 
	Item_Bomb, 
	Item_Speed, 
	Item_Credit, 
	Item_AWP, 
	
	// Do not use
	Item_Count
};

enum
{
	Reason_Dead, 
	Reason_Alive, 
	Reason_HasItem, 
	Reason_NotVIP, 
	Reason_RoundEnd, 
	Reason_NotEnoughCredits_Upgrade, 
	Reason_Item_NotUsable, 
	Reason_LastRequest, 
	Reason_NotATerrorist, 
	Reason_TooManyBoughtThisRound, 
	Reason_MaximumBuyLimit,
	Reason_MaximumClientBuyLimit
};

const int ItemUpgrade_Base = 0;

bool g_bCanBuy = false;
bool g_bLastRequestAvailable = false;

bool g_bHasItem[MAXPLAYERS][Item_Count];
bool g_bIsItemActivated[MAXPLAYERS][Item_Count];
int g_iClientCurrentItemUpgrade[MAXPLAYERS][Item_Count];

// Item buy limit
int g_iItemRoundBuyLimit[Item_Count];
int g_iItemClientRoundBuyLimit[Item_Count];
int g_iItemClientRoundBuyLimit_RoundReset[Item_Count];

int g_iClientItemBuyCountThisRound[MAXPLAYERS][Item_Count];
int g_iClientItemBuyCountThisRound_RoundReset[MAXPLAYERS][Item_Count];
int g_iItemBuyCountThisRound[Item_Count];

int g_iRounds;

Database g_hSql;

/* *************************************************
				Basic Stuff for Params for Upgrades
   ************************************************* */
#define MAX_UPGRADE_NAME_LENGTH 35
#define MAX_PARAMS 5
#define MAX_UPGRADES_PLUGIN (5 + 1)

bool g_bReady = false;
// Were the base values loaded
int g_bItemUsable[Item_Count];

// Item + Upgrades stuff
int g_iItemUpgradeCount[Item_Count]; // Includes BASE
char g_szItemUpgradeName[Item_Count][MAX_UPGRADES_PLUGIN][MAX_UPGRADE_NAME_LENGTH];
int g_iItemUpgradePrice[Item_Count][MAX_UPGRADES_PLUGIN];
int g_iItemPriceOverride[Item_Count][MAX_UPGRADES_PLUGIN];

Handle g_hOpenJailTimer = null;

// Cache of StoreItemIndexes
int g_iStoreItemIdCache[Item_Count];

// Stores Upgrade menu to destroy it in case the store was reloaded.
Menu g_hUpgradeMenu[MAXPLAYERS];

/* *************************************************
				KeyValue Reading Stuff
   ************************************************* */
char KEY_BASE[] = "Items";
char KEY_ITEM_ROUND_BUY_LIMIT[] = "buy_round_limit";
char KEY_ITEM_CLIENT_BUY_LIMIT[] = "buy_client_round_limit";
char KEY_ITEM_CLIENT_BUY_LIMIT_ROUNDRESET[] = "buy_client_round_reset";

#define BUYLIMIT_NO_LIMIT 0

char KEY_BASE_UPGRADE[] = "Base";
char KEY_UPGRADE_SECTION[] = "Upgrade";
char KEY_UPGRADE_NAME[] = "upgrade_name";
char KEY_UPGRADE_PRICE[] = "upgrade_price";
char KEY_ITEM_PRICE_OVERRIDE[] = "item_price_override";
char KEY_PARAM_BASE[] = "param";

/* *************************************************
				Editable stuff
   ************************************************* */
char PREFIX[] = "\x04[Store]\x01";
char BASE_ITEM_UPGRADE_NAME[] = "Base Upgrade";
#define VIP_ACCESS "t"

int g_iVIPItems[] =  {
	13
};

// DO NOT CHANGE THE ORDER
// This should match the
// Item Name (NOT Item Display Name)
// in the web page
// Use
char Store_Items_ItemName[Item_Count][] =  {
	"item_invisibility", 
	"item_immortal", 
	"item_open_jail", 
	"item_give_deagle", 
	"item_lightsaber", 
	"item_guard_skin", 
	"item_bomb", 
	"item_speed", 
	"item_credit_multiplier", 
	"item_give_awp"
};

char Store_Items_ItemType[] = "khalid_plugin";

#define IsClientVIP(%1)  IsClientHaveFlag(%1, ReadFlagString(VIP_ACCESS), false)

Handle g_Forward_OnCreditChange = null;

#include "store-jbitems/params.sp"
#include "store-jbitems/upgrade_menu.sp"
#include "store-jbitems/give_items.sp"
#include "store-jbitems/store.sp"

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szErr, iErrMax)
{
	CreateNative("JBShop_GetCredits", Native_GetCredits);
	CreateNative("JBShop_GiveCredits", Native_GiveCredits);
	CreateNative("JBShop_RemoveCredits", Native_RemoveCredits);
	
	g_Forward_OnCreditChange = CreateGlobalForward("JBShop_OnCreditChange", ET_Ignore, Param_Cell, Param_Cell);
	
	CSetPrefix("%s ", PREFIX);
	return APLRes_Success;
}

public void OnPluginEnd()
{
	Store_Custom_RemoveItemType(Store_Items_ItemType);
	Store_Custom_Shop_RemoveMenuItem("jbshop_itemupgrades");
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerSpawn);
	
	// Blinding stuff
	g_hFadeUserMsgId = GetUserMessageId("Fade");
	
	// Param storage.
	gArray_ParamStorage = new ArrayList(64);
	
	AddCommandListener(CommandListenerCallback_Drop, "drop");
	
	if (Store_Custom_IsDatabaseLoaded())
	{
		Store_OnDatabaseInitialized();
		Store_OnReloadItemsPost();
	}
}

public void OnAllPluginsLoaded()
{
	// Store Stuff
	Store_RegisterItemType(Store_Items_ItemType, OnShopItem_Use);
	//Store_AddMainMenuItemEx("Item Upgrades", "Upgrades for items", "", MenuClickCallback_Upgrade, 2, false);
	Store_Custom_Shop_AddMenuItem("jbshop_itemupgrades", "Item Upgrades", MenuClickCallback_Upgrade);
}

public void Store_OnDatabaseInitialized()
{
	PrintToServer("************* JB Shop items plugin Loaded");
	PrintToServer("************* JB Shop items plugin Loaded");
	LogDebug("REAEEEEADDDYYYYY");
	g_bReady = true;
	g_hSql = Store_Custom_GetSQLHandle();
	
	DoThreadedQuery(SQLCallback_CreateTable, 0, 
		"CREATE TABLE IF NOT EXISTS `_table_name_upgrade_` ( `_user_id_` INT, `_item_id_` INT, `_upgrade_number_` INT)");

	// Get items indexes
	//OnMapStart();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		OnClientPutInServer(i);
	}
}

public void SQLCallback_CreateTable(Handle hDatabase, Handle hResult, char[] szError, any data)
{
	if (szError[0])
	{
		SetFailState("Could not create table! %s", szError);
		return;
	}
}

public void OnMapStart()
{
	g_iRounds = 0;
	g_hOpenJailTimer = null;
	
	PrecacheSound(g_szBombTickSound);
	PrecacheSound(g_szBombExplodeSound);
	PrecacheModel(IMPOSTER_MODEL_DEFAULT);
}

public Action CommandListenerCallback_Drop(int client, const char[] command, int argc)
{
	if (g_bHasItem[client][Item_Bomb])
	{
		if (!g_bIsItemActivated[client][Item_Bomb])
		{
			Activate_Bomb(client);
			return Plugin_Handled;
		}
	}
	
	if (g_bHasItem[client][Item_Speed])
	{
		if (!g_bIsItemActivated[client][Item_Speed])
		{
			Activate_Speed(client);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if (!g_bReady)
	{
		return;
	}
	
	if (g_hSql == null)
	{
		return;
	}
	
	SDKHook(client, SDKHook_OnTakeDamageAlive, SDKCallback_OnTakeDamageAlive);
	
	StringMap hTrie = CreateTrie();
	SetTrieString(hTrie, "type", Store_Items_ItemType);
	
	Store_GetUserItems(hTrie, GetSteamAccountID(client), Store_GetClientLoadout(client), StoreCallback_GetUserItems, client);
}

public void StoreCallback_GetUserItems(int[] useritems, bool[] equipped, int[] useritemCount, int count, int loadoutId, any client)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	char szItemName[STORE_MAX_NAME_LENGTH];
	for (int iItem; iItem < count; iItem++)
	{
		// If he had our items from before, then give them to him.
		Store_GetItemName(useritems[iItem], szItemName, sizeof szItemName);
		
		//PrintToServer("Got client item: %s", szItemName);
		if (StrEqual(szItemName, Store_Items_ItemName[Item_Lightsaber]))
		{
			Give_Lightsaber(client);
			continue;
		}
		
		if (StrEqual(szItemName, Store_Items_ItemName[Item_Credit]))
		{
			Give_CreditMultiplier(client);
			continue;
		}
	}
	
	LogDebug("* Got items for %N", client);
	GetClientUpgrades(client);
}

void GetClientUpgrades(int client)
{
	//PrintToServer("do this");
	Store_GetClientUserID(client, Callback_GetUserId);
}

public void Callback_GetUserId(int client, int iUserId, any data)
{
	DoThreadedQuery(SQLCallback_GetClientUpgrades, 
		client, "SELECT `_item_id_`, `_upgrade_number_` FROM `_table_name_upgrade_` WHERE `_user_id_` = '%d'", iUserId);
}

void DoBuyClientUpgrade(int client, int iItem, int iUpgrade)
{
	int iStoreItemIndex = FindStoreIndexFromItemIndex(iItem);
	
	if (iStoreItemIndex == -1)
	{
		LogError("Failed to buy upgrade because iStoreItemIndex == -1");
		return;
	}
	
	DataPack hPack = CreateDataPack();
	
	WritePackCell(hPack, client);
	WritePackCell(hPack, iItem);
	WritePackCell(hPack, iStoreItemIndex);
	WritePackCell(hPack, iUpgrade);
	
	Store_GetClientUserID(client, Callback_BuyItemUpgrade, hPack);
}

public void Callback_BuyItemUpgrade(int client, int iUserId, DataPack hPack)
{
	hPack.Reset();
	hPack.ReadCell();
	hPack.ReadCell();
	int iStoreItemIndex = hPack.ReadCell();
	int iUpgrade = hPack.ReadCell();
	
	DoThreadedQuery(SQLCallback_BuyItemUpgrade, hPack, 
		"UPDATE `_table_name_upgrade_` SET `_upgrade_number_` = '%d' WHERE `_user_id_` = '%d' AND `_item_id_` = '%d'", iUpgrade, iUserId, iStoreItemIndex);
}

public void SQLCallback_BuyItemUpgrade(Handle hPlugin, Handle hResult, char[] szError, DataPack hPack)
{
	ResetPack(hPack);
	
	int client = ReadPackCell(hPack);
	int iItem = ReadPackCell(hPack);
	int iStoreItemIndex = ReadPackCell(hPack);
	int iUpgrade = ReadPackCell(hPack);
	
	if (szError[0])
	{
		LogError("Failed to upgrade upgrade query for client %d %N %d %d %d", client, client, iItem, iStoreItemIndex, iUpgrade);
		LogError("%s", szError);
		delete hPack;
		return;
	}
	
	if (SQL_GetAffectedRows(hResult) <= 0)
	{
		Store_GetClientUserID(client, Callback_OnConfigItemBuyUpgrade, hPack);
		
	}
	
	else
	{
		SQLCallback_OnConfirmItemUpgradeBuy(INVALID_HANDLE, INVALID_HANDLE, "", hPack);
	}
}

public void Callback_OnConfigItemBuyUpgrade(int client, int iUserId, DataPack hPack)
{
	hPack.Reset();
	hPack.ReadCell();
	hPack.ReadCell();
	int iStoreItemIndex = hPack.ReadCell();
	int iUpgrade = hPack.ReadCell();
	
	DoThreadedQuery(SQLCallback_OnConfirmItemUpgradeBuy, hPack, 
		"INSERT INTO `_table_name_upgrade_` ( `_user_id_`, `_item_id_`, `_upgrade_number_` ) VALUES ( '%d', '%d', '%d' )", iUserId
		, iStoreItemIndex, iUpgrade);
}

public void SQLCallback_OnConfirmItemUpgradeBuy(Handle hDatabase, Handle hResult, char[] szError, DataPack hPack)
{
	ResetPack(hPack);
	
	int client = ReadPackCell(hPack);
	int iItem = ReadPackCell(hPack);
	int iStoreItemIndex = ReadPackCell(hPack);
	int iUpgrade = ReadPackCell(hPack);
	
	delete hPack;
	
	if (szError[0])
	{
		LogError("Could not buy upgrade %d for item %s %d player %d %N", iUpgrade, Store_Items_ItemName[iItem], iStoreItemIndex, client, client);
		return;
	}
}

void DoThreadedQuery(SQLTCallback SqlCallback, any data = 0, char[] szQuery, any...)
{
	char szFormattedQuery[MAX_QUERY_SIZES];
	VFormat(szFormattedQuery, sizeof szFormattedQuery, szQuery, 4);
	
	ReplaceString(szFormattedQuery, sizeof szFormattedQuery, "_table_name_upgrade_", "store_user_upgrades");
	ReplaceString(szFormattedQuery, sizeof szFormattedQuery, "_upgrade_number_", "upgrade_number");
	ReplaceString(szFormattedQuery, sizeof szFormattedQuery, "_user_id_", "userid");
	ReplaceString(szFormattedQuery, sizeof szFormattedQuery, "_item_id_", "itemid");
	
	//PrintToServer("szFormatted: %s", szFormattedQuery);
	LogDebug("%s", szFormattedQuery);
	SQL_TQuery(g_hSql, SqlCallback, szFormattedQuery, data);
}

public void SQLCallback_GetClientUpgrades(Handle hDatabase, Handle hResult, char[] szError, any client)
{
	if (szError[0])
	{
		LogError("Could not load client %d '%N' upgrades: %s", client, client, szError);
		return;
	}
	
	//PrintToServer("Good till now");
	
	int iStoreItemId;
	int iItem;
	int iUpgradeNumber;
	
	LogDebug("GetUpgrades: Start Client: %N", client);
	LogDebug("CountRows: %d", SQL_GetRowCount(hResult));
	
	while (SQL_FetchRow(hResult))
	{
		LogDebug("GetUpgradesItem: Start");
		iStoreItemId = SQL_FetchInt(hResult, 0);
		iItem = FindItemIndexFromStoreIndex(iStoreItemId);
		
		if (iItem == Item_Invalid)
		{
			LogDebug("Continue: %d", iStoreItemId);
			LogDebug("Item Invalid");
			continue;
		}
		
		iUpgradeNumber = SQL_FetchInt(hResult, 1);
		if (iUpgradeNumber != ItemUpgrade_Base && iUpgradeNumber >= g_iItemUpgradeCount[iItem])
		{
			iUpgradeNumber = g_iItemUpgradeCount[iItem] - 1;
		}
		
		g_iClientCurrentItemUpgrade[client][iItem] = iUpgradeNumber;
		LogDebug("GetUpgradesItem: End");
	}
	
	LogDebug("GetUpgrades: End");
}

public void OnClientDisconnect(client)
{
	if (!g_bReady)
	{
		return;
	}
	
	// Do nothing? We are resetting at putinserver
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, SDKCallback_OnTakeDamageAlive);
	
	SetArrayValue(g_iClientItemBuyCountThisRound[client], sizeof g_iClientItemBuyCountThisRound[], 0, 0);
	SetArrayValue(g_iClientItemBuyCountThisRound_RoundReset[client], sizeof g_iClientItemBuyCountThisRound_RoundReset[], 0, 0);
	
	// Reset stuff;
	for (int iItem; iItem < Item_Count; iItem++)
	{
		g_iClientCurrentItemUpgrade[client][iItem] = ItemUpgrade_Base;
		
		DeactivateItem(client, iItem, true);
		
		// g_bHasItem Is used as a check if the player has the item or has bought it this round if it is a one-time in round.
		g_bHasItem[client][iItem] = false;
		g_bIsItemActivated[client][iItem] = false;
	}
}

public void OnAvailableLR(Announced)
{
	g_bLastRequestAvailable = true;
}

public void Event_RoundStart(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	g_bCanBuy = true;
	g_bLastRequestAvailable = false;
	
	SetArrayValue(g_iItemBuyCountThisRound, sizeof g_iItemBuyCountThisRound, 0, 0);
	
	g_iRounds++;
	
	// Decided to put this here because RoundEnd is not called on mp_restartgame or warmup_end
	for (int i = 1, j = 0; i <= MaxClients; i++)
	{
		//SetArrayValue(g_iClientItemBuyCountThisRound[i], sizeof g_iClientItemBuyCountThisRound[], 0, 0);
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		for (j = 0; j < Item_Count; j++)
		{
			if(g_iRounds == g_iClientItemBuyCountThisRound_RoundReset[i][j])
			{
				//PrintToChatAll("Reset item (%d, %d) %d for %d", g_iClientItemBuyCountThisRound_RoundReset[i][j], g_iRounds, j, i);
				g_iClientItemBuyCountThisRound[i][j] = 0;
				g_iClientItemBuyCountThisRound_RoundReset[i][j] = 0;
			}
			
			if (g_bHasItem[i][j])
			{
				DeactivateItem(i, j);
			}
		}
	}
}

public void Event_RoundEnd(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	g_bCanBuy = false;
}

public void Event_PlayerSpawn(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	//int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
}

public void Event_PlayerDeath(Handle hEvent, const char[] szEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (g_bHasItem[client][Item_Invisibility])
	{
		DeactivateItem(client, Item_Invisibility);
	}
}

public Action SDKCallback_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (g_bIsItemActivated[victim][Item_Immortal])
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	if ((0 < attacker <= MaxClients) && attacker != victim && IsClientInGame(attacker) && g_bIsItemActivated[attacker][Item_Lightsaber])
	{
		int iWeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (iWeaponIndex > 0 && IsValidEntity(iWeaponIndex))
		{
			char szClassName[35];
			GetEntityClassname(iWeaponIndex, szClassName, sizeof szClassName);
			
			if (StrEqual(szClassName, "weapon_knife"))
			{
				int iButtons = GetClientButtons(attacker);
				
				float flModifier;
				if (iButtons & IN_ATTACK)
				{
					flModifier = GetParamCell(Item_Lightsaber, g_iClientCurrentItemUpgrade[attacker][Item_Lightsaber], 1);
				}
				
				else if (iButtons & IN_ATTACK2)
				{
					flModifier = GetParamCell(Item_Lightsaber, g_iClientCurrentItemUpgrade[attacker][Item_Lightsaber], 2);
				}
				
				damage = damage + damage * flModifier;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

/* *************************************************
				Checks functions
   ************************************************* */

void PrintReason(int client, bool bPrintReason, int iReason, any ...)
{
	if (!bPrintReason)
	{
		return;
	}
	
	switch (iReason)
	{
		case Reason_Alive:
		{
			//VFormat(szPrint, sizeof szPrint, sz
			CPrintToChat(client, "You must be dead to buy this item.");
		}
		
		case Reason_Dead:
		{
			CPrintToChat(client, "You must be alive to buy this item.");
		}
		
		case Reason_HasItem:
		{
			CPrintToChat(client, "You already have that item.");
		}
		
		case Reason_NotVIP:
		{
			CPrintToChat(client, "This item is only available for VIPs.");
		}
		/*
		case Reason_NotEnoughCredits_Upgrade:
		{
			char szPrint[256];
			VFormat(szPrint, sizeof szPrint, "You need\x03 %d \x01credits to buy upgrade\x04 (%s)\x01 for item \x05%s.", 4);
			
			CPrintToChat(client, szPrint);
		}*/
		
		case Reason_Item_NotUsable:
		{
			CPrintToChat(client, "Item is not usable");
		}
		
		case Reason_LastRequest:
		{
			CPrintToChat(client, "You cannot buy items when a last request is available.");
		}
		
		case Reason_NotATerrorist:
		{
			CPrintToChat(client, "This shop is only available for prisoners.");
		}
		
		case Reason_TooManyBoughtThisRound:
		{
			CPrintToChat(client, "This item has reached the maximum buy limit for this round.");
		}
		
		case Reason_MaximumBuyLimit:
		{
			CPrintToChat(client, "You have bought this item too much this round.");
		}
		
		case Reason_MaximumClientBuyLimit:
		{
			char szPrint[256];
			VFormat(szPrint, sizeof szPrint, "You can only buy this item %d times in %d rounds (reset in %d rounds)", 4);
			CPrintToChat(client, szPrint);
		}
	}
}

bool CanBuyItem(int client, int iItem, bool bPrintReason = false)
{
	if (!g_bCanBuy)
	{
		PrintReason(client, bPrintReason, Reason_RoundEnd);
		return false;
	}
	
	if(g_iItemClientRoundBuyLimit[iItem] != BUYLIMIT_NO_LIMIT && g_iClientItemBuyCountThisRound[client][iItem] >= g_iItemClientRoundBuyLimit[iItem] )
	{
		PrintReason(client, bPrintReason, Reason_MaximumClientBuyLimit, g_iItemClientRoundBuyLimit[iItem], g_iItemClientRoundBuyLimit_RoundReset[iItem], g_iClientItemBuyCountThisRound_RoundReset[client][iItem] - g_iRounds);
		return false;
	}
	
	if (g_bLastRequestAvailable)
	{
		PrintReason(client, bPrintReason, Reason_LastRequest);
		return false;
	}
	
	if (!g_bItemUsable[iItem])
	{
		PrintReason(client, bPrintReason, Reason_Item_NotUsable);
		return false;
	}
	
	if (g_bHasItem[client][iItem])
	{
		PrintReason(client, bPrintReason, Reason_HasItem);
		return false;
	}
	
	if (g_iItemRoundBuyLimit[iItem] != BUYLIMIT_NO_LIMIT && g_iItemBuyCountThisRound[iItem] >= g_iItemRoundBuyLimit[iItem])
	{
		PrintReason(client, bPrintReason, Reason_TooManyBoughtThisRound);
		return false;
	}
	
	if (g_iItemClientRoundBuyLimit[iItem] != BUYLIMIT_NO_LIMIT && g_iClientItemBuyCountThisRound[client][iItem] >= g_iItemClientRoundBuyLimit[iItem])
	{
		PrintReason(client, bPrintReason, Reason_MaximumBuyLimit);
		return false;
	}
	
	if (GetClientTeam(client) != CS_TEAM_T)
	{
		PrintReason(client, bPrintReason, Reason_NotATerrorist);
		return false;
	}
	
	if (IsVIPOnlyItem(iItem) && !IsClientVIP(client))
	{
		PrintReason(client, bPrintReason, Reason_NotVIP);
		
		return false;
	}
	
	switch (iItem)
	{
		case Item_Invisibility:
		{
			if (!IsPlayerAlive(client))
			{
				PrintReason(client, bPrintReason, Reason_Dead);
				return false;
			}
		}
		
		case Item_Immortal:
		{
			if (!IsPlayerAlive(client))
			{
				PrintReason(client, bPrintReason, Reason_Dead);
				return false;
			}
		}
		
		case Item_Deagle:
		{
			if (!IsPlayerAlive(client))
			{
				PrintReason(client, bPrintReason, Reason_Dead);
				return false;
			}
		}
		
		case Item_Lightsaber:
		{
			// No checks needed.
		}
		
		case Item_GuardSkin:
		{
			if (!IsPlayerAlive(client))
			{
				PrintReason(client, bPrintReason, Reason_Dead);
				return false;
			}
		}
		
		case Item_Bomb:
		{
			if (!IsPlayerAlive(client))
			{
				PrintReason(client, bPrintReason, Reason_Dead);
				return false;
			}
		}
		
		case Item_Speed:
		{
			if (!IsPlayerAlive(client))
			{
				PrintReason(client, bPrintReason, Reason_Dead);
				return false;
			}
		}
		
		case Item_Credit:
		{
			// No checks needed.
		}
		
		case Item_AWP:
		{
			if (!IsPlayerAlive(client))
			{
				PrintReason(client, bPrintReason, Reason_Dead);
				return false;
			}
		}
	}
	
	return true;
}

/* *************************************************
				Useful stocks, functions
   ************************************************* */
int FindStoreIndexFromItemIndex(int iItemIndex)
{
	return g_iStoreItemIdCache[iItemIndex];
}

int FindItemIndexFromStoreIndex(int iShopIndex)
{
	char szString[STORE_MAX_TYPE_LENGTH + STORE_MAX_NAME_LENGTH];
	Store_GetItemType(iShopIndex, szString, sizeof szString);
	
	if (!StrEqual(szString, Store_Items_ItemType, true))
	{
		Store_GetItemName(iShopIndex, szString, sizeof szString);
		//PrintToServer("type does not match on item %d %s", iShopIndex, szString);
		//PrintToServer("Stop %s");
		return Item_Invalid;
	}
	
	Store_GetItemName(iShopIndex, szString, sizeof szString);
	int iRet = FindItemIndexFromStoreItemName(szString);
	
	//PrintToServer("%s %d", szString, iRet);
	return iRet;
}

int FindItemIndexFromStoreItemName(const char[] szName)
{
	for (int i; i < Item_Count; i++)
	{
		if (StrEqual(Store_Items_ItemName[i], szName))
		{
			return i;
		}
	}
	
	return Item_Invalid;
}

bool IsVIPOnlyItem(int iItem)
{
	for (int i; i < sizeof(g_iVIPItems); i++)
	{
		if (iItem == g_iVIPItems[i])
		{
			return true;
		}
	}
	
	return false;
}

bool IsClientHaveFlag(int client, int iFlagsBit, bool bExact = false)
{
	int iFlags = GetUserFlagBits(client);
	if (iFlags == ADMFLAG_ROOT)
	{
		return true;
	}
	
	switch (bExact)
	{
		case true:
		{
			if (iFlags & iFlagsBit != iFlagsBit)
			{
				return false;
			}
		}
		
		case false:
		{
			if (!(iFlags & iFlagsBit))
			{
				return false;
			}
		}
	}
	
	return true;
}

bool HasItemUpgrades(int iItem)
{
	return g_iItemUpgradeCount[iItem] > 1 ? true : false;
}

/*
stock void PrintToChat_Custom(int client, const char[] szPrefix = "", char[] szMsg, any...)
{
	int iLen;
	char szBuffer[256];
	iLen = FormatEx(szBuffer, sizeof szBuffer, "%s \x01", szPrefix);
	
	VFormat(szBuffer[iLen], sizeof(szBuffer) - iLen, szMsg, 4);
	
	if (client > 0)
	{
		CPrintToChat(client, szBuffer);
	}
	
	else CPrintToChatAll(szBuffer);
}*/

void SetArrayValue(any[] array, int iSize, any value, int iStart = 0)
{
	for (int i = iStart; i < iSize; i++)
	{
		array[i] = value;
	}
}

public int Native_GetCredits(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if (!CheckClient(client))
	{
		return -1;
	}
	
	return Store_GetCreditsEx(GetSteamAccountID(client));
}

public int Native_GiveCredits(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if (!CheckClient(client))
	{
		return;
	}
	
	int iSteamAccount = GetSteamAccountID(client);
	int iCredits = GetNativeCell(2);
	int iExtraCredits;
	
	if (!GetNativeCell(3) && g_bHasItem[client][Item_Credit])
	{
		float flMultiplier = GetParamCell(Item_Credit, g_iClientCurrentItemUpgrade[client][Item_Credit], 1);
		
		iExtraCredits = RoundFloat(float(iCredits) * flMultiplier);
		//PrintToChatAll("Multiplier: %0.2f .. iCredit**-*-*-*-*-*-**-*-*-s: %d .... iExtraCredits: %d", flMultiplier, iCredits, iExtraCredits);
		
		CPrintToChat(client, "You were given an extra %d credits for buying the credits upgrade! (%0.2f Percent Extra)", iExtraCredits, (flMultiplier) * 100);
	}
	
	Call_StartForward(g_Forward_OnCreditChange);
	Call_PushCell(client);
	Call_PushCell(iCredits + iExtraCredits);
	Call_Finish();
	
	char szLogReason[MAX_LOG_REASON_LENGTH];
	int iLen;
	GetNativeString(4, szLogReason, sizeof szLogReason, iLen);
	
	FormatEx(szLogReason[iLen], sizeof(szLogReason) - iLen, "(%d Extra)", iExtraCredits);
	
	Store_GiveCredits(iSteamAccount, iCredits + iExtraCredits, INVALID_FUNCTION, 0, szLogReason);
}

public int Native_RemoveCredits(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if (!CheckClient(client))
	{
		return;
	}
	
	int iCredits = GetNativeCell(2);
	Call_StartForward(g_Forward_OnCreditChange);
	Call_PushCell(client);
	Call_PushCell(-iCredits);
	Call_Finish();
	
	char szLogReason[MAX_LOG_REASON_LENGTH];
	GetNativeString(4, szLogReason, sizeof szLogReason);
	
	Store_RemoveCredits(GetSteamAccountID(client), iCredits, INVALID_FUNCTION, 0, szLogReason);
}

bool CheckClient(client)
{
	if (!(1 <= client <= MaxClients))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Index out of bounds (%d) should be < %d", client, MaxClients);
		return false;
	}
	
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client not in game (%d)", client);
		return false;
	}
	
	return true;
}

#if !defined DEBUG
stock void LogDebug(char[] szMsg, any...)
{
	
}
#endif