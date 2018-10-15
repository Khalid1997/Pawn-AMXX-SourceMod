#if defined _bbshop_included
  #endinput
#endif
#define _bbshop_included

#include <amxmodx>
#include <basebuilder>
#include <bbshop_const>

/* Returns Player points on success, -1 on failure */
native bb_get_user_points(id)
native zp_get_user_ammo_packs(id, iNum)

/* Sets user points to iNum value */
native bb_set_user_points(id, iNum)
native zp_set_user_ammo_packs(id, iNum)

/* Returns item id */
native bb_register_extra_item(const szName[], const iCost, iTeam)
native zp_register_extra_item(const szName[], const iCost, iTeam)

forward bb_extra_item_choosed(id, itemid)
forward zp_extra_item_selected(id, itemid)

forward bb_round_end()
