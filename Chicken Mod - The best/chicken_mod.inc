#if !defined _CM_INC_INCLUDED_
	#define _CM_INC_INCLUDED_
#else
	#endinput
#endif

/*	CM_register_weapon:
	returns WeaponIndex. Weaponmodel must be precached.
*/
native CM_register_weapon( szMenuName[],  szWeaponModel[]);

/*	CM_register_shop_item:
	returns ShopItemIndex. If itemindex matches, return PLUGIN_HANDLED in the forward to automatically decrease
	the points amount.
*/
native CM_register_shop_item(szItemName[], iItemPrice);

native CM_set_user_points(id, iNewPoints);
native CM_get_user_points(id);

// Register index is the value returned from CM_register_* natives.
forward CM_WeaponTouch(iPlayer, iWeaponRegisterIndex, iBullets);
forward CM_ShopItemChoosed(id, iShopItemRegisterIndex);

