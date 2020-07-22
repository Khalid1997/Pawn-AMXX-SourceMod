/*
* MultiMod Voting Plugin Include.
*/
#if defined _multimod_vote_included
 #endinput
#endif
#define _multimod_vote_included

enum MultiModVote (<<=1)
{
	MultiModVote_None = 0,
	MultiModVote_Mod = 1,
	MultiModVote_Map
};

#define MultiModVote_TotalVotes 2
#define MultiModVote_Normal ( MultiModVote_Mod | MultiModVote_Map )

enum MultiModVoteType
{
	MultiModVoteType_Normal = 0
	//MultiModVoteType_RunOff // In the future
};

forward void MultiMod_Vote_OnClientVote(MultiModVote iVote, int client, int iVoteItemIndex, int iVoteItemRealIndex);

forward MMReturn MultiMod_Vote_OnAddMenuItem_Pre(MultiModVote iVote, int iVoteItemRealIndex, char[] szDisplayName, int iDisplayNameSize, bool &bEnabled);
forward void  MultiMod_Vote_OnAddMenuItem(MultiModVote iVote, int iVoteItemIndex, int iVoteItemRealIndex, char[] szDisplayName, int iDisplayNameSize, bool bEnabled);

forward MMReturn MultiMod_Vote_OnVoteStart_Pre(MultiModVote iAllVoteBit, MultiModVote iCurrentVote, MultiModVoteType iVoteType, bool &bForceChange);
forward void MultiMod_Vote_OnVoteStart(MultiModVote iAllVoteBit, MultiModVote iCurrentVote, MultiModVoteType iVoteType, bool bForceChange);

// iAllVoteBit == iVoteProgressBit = No more votes.
forward void MultiMod_Vote_OnVoteFinished(MultiModVote iAllVoteBit, MultiModVote iVoteProgressBit, MultiModVote iCurrentVote, MultiModVoteType iVoteType, int iWinnerIndex, int iWinningVotes, int iTotalVotes);

enum MultiModVoteStatus
{
	MultiModVoteStatus_NoVote = 0,
	MultiModVoteStatus_Running,
	MultiModVoteStatus_Done
}

native MultiModVoteStatus MultiMod_Vote_GetVoteStatus();
	
native MultiModVoteType MultiMod_Vote_GetCurrentVoteType();
	
native MultiModVote MultiMod_Vote_GetCurrentVote();
native MultiModVote MultiMod_Vote_GetVoteProgressBit();
native MultiModVote MultiMod_Vote_GetAllVoteBit();
	
native int	MultiMod_Vote_GetVoteItemCount();
native void MultiMod_Vote_GetVoteItemName(int iVoteItem, char[] szItemName, int iMaxSize, bool bUnedited = true);

native int MultiMod_Vote_GetVoteItemVotes(int iVoteItem, bool bWithoutPower = false);
native int MultiMod_Vote_GetTotalVotes(bool bWithoutPower = false);
	
native bool MultiMod_Vote_StartVote(MultiModVote iAllVoteBit, bool bForceChange);
	
native void MultiMod_Vote_SetClientVotingPower(int client, int iVotingPower);
native void MultiMod_Vote_GetClientVotingPower(int client, int iVotingPower);

stock bool MultiMod_Vote_CanStartVote(bool bAllowSecondaryVotes = true)
{
	MultiModVoteStatus status = MultiMod_Vote_GetVoteStatus();
	
	if(status == MultiModVoteStatus_NoVote || ( bAllowSecondaryVotes && status == MultiModVoteStatus_Done ) )
	{
		return true;
	}
	
	return false;
}

public SharedPlugin __pl_multimod_vote = 
{
	name = MM_LIB_VOTE, 
	file = "multimod_vote.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_multimod_vote_SetNTVOptional()
{
	MarkNativeAsOptional("MultiMod_Vote_OnClientVote");
	MarkNativeAsOptional("MultiMod_Vote_OnAddMenuItem_Pre");
	MarkNativeAsOptional("MultiMod_Vote_OnAddMenuItem");
	MarkNativeAsOptional("MultiMod_Vote_OnVoteStart_Pre");
	MarkNativeAsOptional("MultiMod_Vote_OnVoteStart");
	MarkNativeAsOptional("MultiMod_Vote_OnVoteFinished");
	MarkNativeAsOptional("MultiMod_Vote_GetVoteStatus");
	MarkNativeAsOptional("MultiMod_Vote_GetCurrentVoteType");
	MarkNativeAsOptional("MultiMod_Vote_GetCurrentVote");
	MarkNativeAsOptional("MultiMod_Vote_GetVoteProgressBit");
	MarkNativeAsOptional("MultiMod_Vote_GetAllVoteBit");
	MarkNativeAsOptional("MultiMod_Vote_GetVoteItemCount");
	MarkNativeAsOptional("MultiMod_Vote_GetVoteItemName");
	MarkNativeAsOptional("MultiMod_Vote_GetVoteItemVotes");
	MarkNativeAsOptional("MultiMod_Vote_GetTotalVotes");
	MarkNativeAsOptional("MultiMod_Vote_StartVote");
	MarkNativeAsOptional("MultiMod_Vote_SetClientVotingPower");
	MarkNativeAsOptional("MultiMod_Vote_GetClientVotingPower");
}
#endif