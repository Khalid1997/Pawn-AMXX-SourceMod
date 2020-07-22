/*
**
*/
#if defined _get_players_included_
 #endinput
#endif
#define _get_players_included_

#include <getplayers>

#define GET_PLAYERS_INC_AUTHOR	"Khalid"
#define GET_PLAYERS_INC_VERSION	"1.2"

// -----------------------------------
// Constants | FOR BACKEND ONLY! DO NOT USE. 
// -----------------------------------
#define TEAM_VALUE_FIRST		2
#define TEAM_VALUE_SECOND		3
#define TEAM_VALUE_SPEC			1
#define TEAM_VALUE_UNASSIGNED	0

// -----------------------------------
// Actual Include
// -----------------------------------
#define		GP_Flag_None		0		// No flags defined. (Count all players (in-game only)	
#define		GP_Flag_Alive		(1<<0)			// Only alive players. Dead will be stripped if present
#define		GP_Flag_Dead		(1<<1)		// Only dead.
#define		GP_Flag_OnlyBots	(1<<2)			// Only bots. No bots will be stripped if this is present
#define		GP_Flag_NoBots		(1<<3)				// No bots.
#define		GP_Flag_CheckAdmins	(1<<4)		// Check on the iAdminFlags bit

// + 1 because TEAM_VALUE_UNASSIGNED is 0 so the bit would be 0 as well

enum
{
	GP_Team_Unassigned		= (	1<< ( TEAM_VALUE_UNASSIGNED +	1 	) 	),
	GP_Team_First			= ( 1<< ( TEAM_VALUE_FIRST + 		1 	)	),
	GP_Team_Second			= ( 1<< ( TEAM_VALUE_SECOND +		1	)	),
	GP_Team_Spectator		= ( 1<< ( TEAM_VALUE_SPEC + 		1	) 	),
	GP_Team_Any				= (GP_Team_Unassigned | GP_Team_First | GP_Team_Second | GP_Team_Spectator)
};

#define		GP_FlagAdmin_AdminNone	0	// Do not include admins
#define		GP_FlagAdmin_AdminAny	-1	// Any admin
// ------------------------------------------

typeset GetPlayersFilter
{
		function bool (int client);
		function bool (int client, int iCurrentPlayerCount);
}
		

/*
 Returns number of players.

 @param int				iPlayers[MAXPLAYERS]	- Optional. Stores players indexes.
 @param GetPlayersFlag	iFlags					- Optional. Specifies flags to filter players from GetPlayersFlag enum.
 @param	GetPlayersTeam	iTeam					- Optional. Bitsum of teams using provided GP_Team_* bits (in GetPlayersTeam enum).
 @param	int				iAdminFlagsBit			- Optional. Bitsum of admin flags using ADMFLAG_* flags to filter players or one of the GP_FlagAdmin_* flags.
 @param	bool			bExactAccess			- Optional.	Only admins with exact access as the previous iAdminFlagsBit bitsum will be included in the array iPlayers.
	
 @return int									- Number of players (Could be 0 to MaxClients)
 @error											- No error.
*/
stock int GetPlayers(int iPlayers[MAXPLAYERS] = 0, int iFlags = GP_Flag_None,
	int iTeams = GP_Team_Any, int iAdminFlagsBit = GP_FlagAdmin_AdminAny,
	bool bExactAccess = false)
{
	return FilterPlayers(iPlayers, iFlags, iTeams, iAdminFlagsBit, bExactAccess, DumpFilterCallback);
}

stock int GetPlayersFilter(int iPlayers[MAXPLAYERS] = 0, int iFlags = GP_Flag_None,
	int iTeams = GP_Team_Any, int iAdminFlagsBit = GP_FlagAdmin_AdminAny,
	bool bExactAccess = false, GetPlayersFilter FilterForwardId)
{
	return FilterPlayers(iPlayers, iFlags, iTeams, iAdminFlagsBit, bExactAccess, FilterForwardId);
}

public bool DumpFilterCallback(int client, int iCount)
{
	return true;
}

stock int FilterPlayers(int iPlayers[MAXPLAYERS] = 0, int iFlags = GP_Flag_None,
	int iTeams = GP_Team_Any, int iAdminFlagsBit = GP_FlagAdmin_AdminAny,
	bool bExactAccess = false, Function FilterForwardId)
{
	int iCount;
	int iPlayerTeam;
	
	if(iFlags & GP_Flag_Alive)
	{
		iFlags &= ~GP_Flag_Dead;
	}
	
	if(iFlags & GP_Flag_OnlyBots)
	{
		iFlags &= ~GP_Flag_NoBots;
	}
	
	bool bRet;
	for (int i = 1; i <= MaxClients; i++)
	{	
		bRet = true;
		
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		// Skip all checks, do this at once.
		if(iFlags == GP_Flag_None)
		{
			iPlayers[iCount++] = i;
			continue;
		}
		
		if(iFlags & GP_Flag_OnlyBots)
		{
			if(!IsFakeClient(i))
			{
				continue;
			}
		}
		
		else if(iFlags & GP_Flag_NoBots)
		{
			if(IsFakeClient(i))
			{
				continue;
			}
		}
		
		if(iFlags & GP_Flag_Alive)
		{
			if( !IsPlayerAlive(i) )
			{
				continue;
			}
		}
		
		else if(iFlags & GP_Flag_Dead)
		{
			if( IsPlayerAlive(i) )
			{
				continue;
			}
		}
		
		if(iTeams != GP_Team_Any)
		{
			iPlayerTeam = (1 << (GetClientTeam(i) + 1));
			if( !( iPlayerTeam & iTeams ) )
			{
				continue;
			}
		}
		
		// iFlags tells us to check on the admin flags
		if(iFlags & GP_Flag_CheckAdmins)
		{
			switch(iFlags)
			{
				case GP_FlagAdmin_AdminAny:
				{
					if(!GetUserFlagBits(i))
					{
						continue;
					}
				}
					
				case GP_FlagAdmin_AdminNone:
				{
					if(GetUserFlagBits(i))
					{
						continue;
					}
				}
				
				default:
				{
					switch(bExactAccess)
					{
						case true:
						{
							if(GetUserFlagBits(i) & iAdminFlagsBit != iAdminFlagsBit)
							{
								continue;
							}
						}
						
						case false:
						{
							if( !(GetUserFlagBits(i) & iAdminFlagsBit) )
							{
								continue;
							}
						}
					}
				}
			}
		}
		
		if(FilterForwardId != INVALID_FUNCTION)
		{
			Call_StartFunction(GetMyHandle(), FilterForwardId);
			Call_PushCell(i);
			Call_PushCell(iCount);
			Call_Finish(bRet);
		}
		
		if (bRet)
		{
			iPlayers[iCount++] = i;
		}
	}
	
	return iCount;
}