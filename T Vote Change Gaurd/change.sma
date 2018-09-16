#include <amxmodx>
#include <cstrike>
#include <colorchat>

#define GREEN 0

new g_iHasVoted[33];
new g_iVotes;

new const PREFIX[] = "^4[AMXX]";

new const Float:g_flPlayerPercent = 0.75;

public plugin_init()
{
	register_plugin("", "", "");
	
	register_clcmd("say /changect", "CmdVoteChangeCt");
}

public client_disconnect(id)
{
	if(g_iHasVoted[id])
	{
		--g_iVotes;
		g_iHasVoted[id] = 0
	}
}

public CmdVoteChangeCt(id)
{
	new iCTPlayers[32], iCTNum
	if(!CanVote(id, iCTPlayers, iCTNum))
	{
		return;
	}
	
	g_iHasVoted[id] = 1;
	g_iVotes++;
	
	static iPlayers[32], iNum;
	get_players(iPlayers, iNum, "e", "TERRORIST");
	
	if( g_iVotes <= (iNum = floatround( g_flPlayerPercent * float(iNum) ) ) )
	{
		ColorChat(id, GREEN, "%s ^3%d Players ^1are still needed to change the ^3Gaurds.", PREFIX, iNum - g_iVotes)
		
		return;
	}

	for(new i, iPlayer; i < iCTNum; i++)
	{
		if( cs_get_user_team( (iPlayer = iCTPlayers[i] )) == CS_TEAM_T ) 
		{
			continue;
		}
		
		cs_set_user_team(iPlayer , CS_TEAM_T );
			 
		if(is_user_alive(iPlayer))
		{
			user_kill(iPlayer, 1);
		}
	}
		
	ColorChat(0, GREEN, "%s ^1The ^3VOTE ^1succeded. Changing ^3Gaurds ^1team.", PREFIX);
	
	g_iVotes = 0
	arrayset(g_iHasVoted, 0, sizeof(g_iHasVoted));
}

CanVote(id, iCTPlayers[32] = "", &iNum = 0)
{
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		ColorChat(id, GREEN, "%s ^3Gaurds ^1can't vote.", PREFIX);
		return 0;
	}
	
	get_players(iCTPlayers, iNum, "e", "CT");
	
	if(!iNum)
	{
		ColorChat(id, GREEN, "%s ^1There are no ^3Gaurds ^1on the other team to vote.", PREFIX);
		return 0;
	}
	
	if(g_iHasVoted[id])
	{
		ColorChat(id, GREEN, "%s ^1You have already ^3voted.", PREFIX);
		return 0;
	}
	
	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
