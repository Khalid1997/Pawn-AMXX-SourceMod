#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >
#include < engine >

#define m_afButtonPressed            246

#define FBit_Get(%1,%2)              ( %1 &   ( 1 << ( %2 - 1 )))
#define FBit_Set(%1,%2)              ( %1 |=  ( 1 << ( %2 - 1 )))
#define FBit_Clear(%1,%2)            ( %1 &= ~( 1 << ( %2 - 1 )))

new g_bHas3DCamera;

public plugin_init( )
{
	RegisterHam( Ham_ObjectCaps, "player", "CPlayer__ObjectCaps" );
}

public client_putinserver( iPlayer )
{
	FBit_Clear( g_bHas3DCamera, iPlayer );
}

public CPlayer__ObjectCaps( iPlayer )
{
	if(( is_user_alive( iPlayer )) && ( get_pdata_int( iPlayer, m_afButtonPressed, 5 ) & IN_USE ))
	{
		if( FBit_Get( g_bHas3DCamera, iPlayer ))
		{
			set_view( iPlayer, CAMERA_NONE );
			FBit_Clear( g_bHas3DCamera, iPlayer );
		}
		else
		{
			set_view( iPlayer, CAMERA_3RDPERSON );
			FBit_Set( g_bHas3DCamera, iPlayer );
		}
	}
}  
