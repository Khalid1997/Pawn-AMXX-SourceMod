#if defined _playedtime_included_
	#endinput
#endif

#define _playedtime_included_

/* gets played time if player found

* @id		Player index
* @return	-1 if player not found else playedtime of player
*
*/

native get_user_playedtime(id)

/* sets played time if player found

* @id		Player index
* @time		Time you are setting to
* @return	0 on failure, 1 on success
*
*/
native set_user_playedtime(id, time)