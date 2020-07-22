[] Table Name
* Notes
- Description

- Table creation query.
* `headshots` are kills that are headshots
* `playerid` is the player's SteamID as we agreed
* This insertion is done AFTER the match end.
* If you decide to change a field name, just tell me. I can easily edit it.
* Everything is an integer value, except for the `matchid` and `playerid`
* I think you can improve the query, of course :)
[`match_stats`]
CREATE TABLE `match_stats` (
	`matchid` INT, `playerid` VARCHAR(35) , `kills` INT DEFAULT 0, `deaths` INT DEFAULT 0, `assists` INT DEFAULT 0, `headshots` INT DEFAULT 0,
	`bomb_plants` INT DEFAULT 0, `bomb_defuses` INT DEFAULT 0,
	`2k` INT DEFAULT 0, `3k` INT DEFAULT 0, `4k` INT DEFAULT 0, `ace` INT DEFAULT 0,
	`total_shots` INT DEFAULT 0, `total_hits` INT DEFAULT 0, `total_damage` INT DEFAULT 0,
	`total_mvps` INT DEFAULT 0, `rounds_played` INT DEFAULT 0 );

- Table layout for the servers
* The table name should be changed I think xD
* `match_end_code` (updated by me) is on of these:
[`match_matches`]
* `match_end_reason` is the string reason of `match_end_code` (inserted/updated by me)
* Use whatever datatype that you think is best, and tell me which one you used. (Or talk to me to discuss it)
* I was thinking about making the datatype for the time as TIMESTAMP. What do you think?
enum MatchEndReason
{
	MatchEndReason_None = 0;
	MatchEndReason_Cancelled = 1,		// The match was cancelled by a superior admin.
	MatchEndReason_End = 2,				// Match Ended normally.
	MatchEndReason_Surrender = 3,		// Match Ended by a team surrenderring.
	MatchEndReason_ConnectFailure = 4,	// Players failed to connect within the given time.
	MatchEndReason_Forefit = 5			// A team failed to connect.
};

CREATE TABLE `match_matches` ( `matchid` INT NOT NULL AUTO_INCREMENT, `accept_time` TIMESTAMP_TYPE, `start_time` TIMESTAMP_TYPE, `end_time` TIMESTAMP_TYPE, `winner_team` INT, `match_end_code` INT);

[`match_players`]
- List of players in a match.
- `team` is either 1 or 2 - Doesn't matter which one is CT or T as I only will be using this number to put each player in his corresponding team/lobby.
CREATE TABLE `match_player` ( `matchid` INT NOT NULL, `playerid` VARCHAR(35) NOT NULL, `team` VARCHAR(35) );

[`match_servers`]
* Server IP contains the IP and the port in the following format IP:Port
* If you need a 
CREATE TABLE `match_servers ( `server_ip` VARCHAR(35) NOT NULL, `current_match_id` INT DEFAULT NULL );

// -------------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------------

CREATE TABLE `match_servers` ( `server_ip` VARCHAR(25), `current_match_id` VARCHAR(20) );

CREATE TABLE `match` ( `match_id` VARCHAR(20), `match_map` VARCHAR(35), `record_stats` INT,
	`match_accept_time` TIMESTAMP, `match_start_time` TIMESTAMP, `match_end_time` TIMESTAMP,
	`winner_team` INT, `match_end_code` INT, `match_end_reason` VARCHAR(128) );
	
CREATE TABLE `match_players` ( `match_id` INT NOT NULL, `steam` VARCHAR(35) NOT NULL, `team` INT);

CREATE TABLE `match_stats` ( `match_id` INT NOT NULL, `steam` VARCHAR(35) NOT NULL, `kills` INT, `headshots` INT, `deaths` INT, `assists` INT,
	`bomb_plants` INT, `bomb_defuses` INT,
	`2kills` INT, `3kills` INT, `4kills` INT, `aces` INT,
	`total_shots` INT, `total_hits` INT, `total_damage` INT, `total_mvps` INT,
	`rounds_played` INT);