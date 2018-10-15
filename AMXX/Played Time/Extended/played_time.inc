#pragma reqlib "played_time"

/* Sets client played time 
 * @note 		This does not include the current time played in the server
 * 			but the time that is saved.
 * @param id		Player index
 * @param iNum		Time in seconds
 *
 *
 * @return		1 on success, 0 on failure
 */
native pt_set_user_played_time(id, iTime);


/* Returns the saved time in seconds.
 * @param id		Player index
 *
 *
 * @return		 A value that is > 0 on success (time in seconds),
 *			-1 on failure
 */
native pt_get_user_played_time(id);


/* Returns save type.
 * @return		1 for MySQL, 0 for SQLite
 *
 */
native pt_get_save_type();

/* Called when the plugin saves the played time for a client.
 * @note		You can edit the played time that is gotten
 *			by using the natives above.s
 * 
 * @param id		Client index.
 * @param bIsDisconnect	true if called at connect (client_putinserver), false otherwise
 *
 */
forward pt_client_get_time(id, bool:bIsConnect)

/* Called when the plugin saves the played time for a client.
 * @note		You can edit the played time that is saved 
 *			by using the natives above.
 * 
 * @param id		Client index.
 * @param bIsConnect	true if called at disconnect (client_disconnect), false otherwise
 *
 */
forward pt_client_save_time(id, bool:bIsDisconnect)

// Other stuff
// Compatibility with other (older) plugins
native set_user_played_time(id, iTime);	
native set_user_playedtime(id, iTime);

native get_user_played_time(id);		
native get_user_playedtime(id);		// Compatibility with other plugins
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
