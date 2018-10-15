/*
**
*/
#if defined _jbshop_included
 #endinput
#endif
#define _jbshop_included

native int JBShop_GetCredits(int client);
native int JBShop_SetCredits(int client, int iCreditsToSet, bool bWithoutMultiplier = false);

/*
// --------------------------------------------------------------------------------

// ADD TEAMS??
#define TEAM_1	2
#define TEAM_2	3
int const JBShop_Team1 = (1<<TEAM_1);
int const JBShop_Team2 = (1<<TEAM_2);

#define JBSHOP_ITEM_PRICE_FREE				0
#define JBSHOP_ITEM_PRICE_DONT_CHANGE		-1
#define JBSHOP_ITEM_PRICE_CUSTOM			-2

#define JBSHOP_ITEM_NAME_DONT_CHANGE		""

enum JBShop_CallbackReturn
{
	JBShopReturn_Ignored,
	JBShopReturn_ShowMenuBack//,
	
	//JBShopReturn_DontChangeCallback	- Probably Later.
};

// --------------------------------------------------------------------------------

// ADD TEAMS ????
typedef JBShop_ItemSelectCallback = JBShop_CallbackReturn (client);

native bool JBShop_Item_Add(char[] szItemIdentifier, JBShop_ItemSelectCallback Select_Callback, char[] szItemName, int iItemPrice);
native bool JBShop_Item_ChangeProperties(char[] szItemIdentifier, char[] szItemName = JBITEM_NAME_DONT_CHANGE, int iItemPrice = JBITEM_PRICE_DONT_CHANGE);

native bool JBShop_Item_Exists(char[] szItemIdentifier);
native bool JBShop_Item_Remove(char[] szItemIdentifier);

*/