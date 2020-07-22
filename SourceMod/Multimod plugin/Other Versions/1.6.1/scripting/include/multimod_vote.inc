#if defined _multimod_vote_included
 #endinput
#endif
#define _multimod_vote_included

#include <multimod_const>

enum MultiModVote
{
	MultiModVote_Mod,			/* The vote is a MOD vote */
	MultiModVote_Map,			/* The vote is a map vote */
	MultiModVote_Normal			/* Normal voting was initiated. It could be a map vote or a mod vote depending on whether the next MOD was chosen or not */
}

/**
 * Starts the voting functionality.
 *
 * @param iVote 		vote type to start the vote with. (check MultiModVote enum)
 * @param bInstaChange	If true, voting plugin will immidiatly change to the chosen MOD and map after the vote is done.
 *
 * @note				If a next MOD was chosen and the starting vote a multimod vote, the next MOD that was already chosen will be canceled.
 * @note				If the next mod was chosen, and the starting vote is a map vote, the map vote will be on next MOD's maps.
 * @note				if the next mod is not chosen, and the starting vote is a map vote, the map vote will be on the CURRENT MOD's maps.
 * @return				true on success, false on failure.
 */
native bool:MultiMod_StartVote(MultiModVote:iVote = MultiModVote_Normal, bool:bInstantChange = true);

/**
 * Called whenever a vote has started (by the voting plugin or an external plugin)
 *
 * @param iVote 		vote type the vote started with (check MultiModVote enum, also read the notes from the native above)
 * @param bInstantChange	If true, voting plugin will immidiatly change to the chosen MOD and map after the vote is done.
 * @param iNextModId	the index of the next chosen MOD (if the vote started with a map vote). This will be -1 if no next MOD is chosen
 						The voting plugin will then start a map vote for the current mod MAPS.
 * @noreturn
 */
forward MultiMod_VotingStarted(MultiModVote:iVote, bool:bInstantChange, iNextModId);
