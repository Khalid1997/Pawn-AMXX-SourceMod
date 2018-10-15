#if defined _bbshop_included
  #endinput
#endif
#define _bbshop_included

#include <amxmodx>
#include <basebuilder>
#include <bbshop_const>

/* Returns Player points on success, -1 on failure */
native bb_get_user_points(id)

/* Sets user points to iNum value */
native bb_set_user_points(id, iNum)

/* Returns item id */
native bb_register_extra_item(const szName[], const iCost, iTeam)

forward bb_extra_item_choosed(id, itemid)

forward bb_round_end()
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
