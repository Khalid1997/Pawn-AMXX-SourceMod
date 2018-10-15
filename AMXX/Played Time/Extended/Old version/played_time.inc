#pragma reqlib "played_time"

/* Sets a defined player time
 * @param id		Player index
 * @param iNum		Time in seconds
 *
 *
 * @return		1 on success, 0 on failure
 */
native set_user_played_time(const index, iNum)

/* Returns player time on success (in secounds), -1 on failure. */
native get_user_played_time(const index)
