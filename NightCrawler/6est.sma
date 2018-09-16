#include <amxmodx>

public GetHighestScore(iIndexes[32], &iEqualTopNum)
{
	new iPlayers[ 32 ] , iNum , id , iUserFrags
	new iFrags[ 32 ][ 2 ]; 
	
	get_players( iPlayers , iNum, "ae", "CT" );
	
	for ( new i = 0 ; i < iNum ; i++ )
	{
		id = iPlayers[ i ];
		iUserFrags = get_user_frags( id );
		
		iFrags[ id ][ 0 ] = id;
		iFrags[ id ][ 1 ] = iUserFrags;      
	}
	
	SortCustom2D(iFrags , 33 , "fn_StatsCompare");
	
	iEqualTopNum = 0
	
	for(new i= 1; i < 32; i++)
	{
		if(iFrags[i][1] == iFrags[0][1])
			++iEqualTopNum
			
		else	break;
	}
	
	for(new i; i < sizeof(iFrags[]); i++)
		iIndexes[i] = iFrags[i][0]
	
}

public fn_StatsCompare( elem1[] , elem2[] )
{
	if( elem1[1] > elem2[1] ) 
		return -1;
		
	if( elem1[1] < elem2[1] )
		return 1;
	
	return 0;
}  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
