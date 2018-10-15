#include <amxmodx>
#include <cstrike>
new g_iAlive[33], g_iNcNextRound[33]

#define NC_TEAM CS_TEAM_T
#define HUMAN_TEAM CS_TEAM_CT

public plugin_init()
{
	new iPlayers[32], iNum
	ChooseNCPlayers(iPlayers, iNum);
}

stock ChooseNCPlayers(iPlayers[32], iNum, Slay = 0)
{
	static iTNum;
	iTNum = floatround(Float:iNum / Float:(3 + 1))

	new iPlayer, i;
	for(i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(Slay)
		{
			if(g_iAlive[iPlayer])
			{
				user_silentkill(iPlayer)
			}
		}
		
		if(g_iNcNextRound[iPlayer])
		{
			new szName[32];
			get_user_name(iPlayer, szName, 31);
			server_print("Will be NC %s", szName);
			cs_set_user_team(iPlayer, NC_TEAM)
			
			if(is_user_connected(g_iNcNextRound[iPlayer]))
			{
				cs_set_user_team(g_iNcNextRound[iPlayer], HUMAN_TEAM)
				g_iNcNextRound[iPlayer] = 0
			}
		}
	}
	
	server_print("iCurrentTNum = %d , iTNum = %d", iCurrentTNum, iTNum);
	
	if(iCurrentTNum < iTNum)
	{
		new iHumanPlayers[32]

#if NC_TEAM == CS_TEAM_T
		
		#if !defined BOT_SUPPORT
		get_players(iHumanPlayers, iNum, "che", "CT")
		#else
		get_players(iHumanPlayers, iNum, "e", "CT")
		#endif
#else
		#if defined BOT_SUPPORT
		get_players(iHumanPlayers, iNum, "che", "TERRORIST")
		#else
		get_players(iHumanPlayers, iNum, "e", "TERRORIST")
		#endif
#endif

		while(iCurrentTNum < iTNum)
		{
			iPlayer = iHumanPlayers[random(iNum)]
			
			// Make sure he is an human
			//if(cs_get_user_team(iPlayer) == NC_TEAM)
			//{
			//	continue;
			//}
		
			cs_set_user_team(iPlayer, NC_TEAM)
			iCurrentTNum++
		}
	}
	
	else if(iCurrentTNum > iTNum)
	{
		new iNcPlayers[32]
#if NC_TEAM == CS_TEAM_T
		
		#if !defined BOT_SUPPORT
		get_players(iNcPlayers, iNum, "che", "TERRORIST")
		#else
		get_players(iNcPlayers, iNum, "e", "TERRORIST")
		#endif
#else
		#if !defined BOT_SUPPORT
		get_players(iNcPlayers, iNum, "che", "CT")
		#else
		get_players(iNcPlayers, iNum, "e", "CT")
		#endif
#endif
		
		while(iCurrentTNum > iTNum)
		{
			iPlayer = iNcPlayers[random(iNum)]
			
			if(cs_get_user_team(iPlayer) == HUMAN_TEAM)
			{
				continue;
			}
			
			cs_set_user_team(iPlayer, HUMAN_TEAM)
			iCurrentTNum--
		}
	}
}