
/*==========================================================================================*/
/*																							*/
/*	Plugin  : Flower_Main																	*/
/*	Version : 2.6																			*/
/*	Author  : Micapat																		*/
/*																							*/
/*	Thanks to ConnorMcLeod for the explosion												*/
/*	--> http://forums.alliedmods.net/showthread.php?t=97012									*/
/*																							*/
/*	Thanks to Hlstriker for the Shoop da whoop												*/
/*	--> http://forums.alliedmods.net/showthread.php?p=907087								*/
/*																							*/
/*==========================================================================================*/

#include < amxmodx >
#include < cstrike >
#include < fun >
#include < fakemeta >
#include < hamsandwich >
#include < engine >

#define GIB_ALWAYS							2
#define message_begin_f(%1,%2,%3,%4)		engfunc( EngFunc_MessageBegin, %1, %2, %3, %4 )
#define write_coord_f(%1)					engfunc( EngFunc_WriteCoord, %1 )

#define TASK_EXPLODE						1000
#define TASK_SCREENFADE						2000
#define TASK_CTS_MSG						3000
#define TASK_TS_MSG							4000
#define TASK_SHOOP							5000

enum _: FlowersCvars
{
	CVAR_FW_TIMECANTATTACK = 0,
	CVAR_FW_DAMAGEEXPLOSION,
	CVAR_FW_RADIUSEXPLOSION,
	CVAR_FW_SPEEDEXPLOSION,
	CVAR_FW_GRAVITYEXPLOSION,
	CVAR_FW_MONEYEXPLOSION,
	CVAR_FW_FRAGSEXPLOSION,
	CVAR_FW_CANBUYSHOOP,
	CVAR_FW_PRICESHOOP,
	CVAR_FW_SPEEDSHOOP,
	CVAR_FW_GRAVITYSHOOP,
	CVAR_GD_TIMESCREENFADE,
	CVAR_GD_COLORSCREENFADE,
	CVAR_GD_CANBUYKNIFE,
	CVAR_GD_PRICEKNIFE,
	CVAR_GD_CANBUYAMMOS,
	CVAR_GD_PRICEAMMOS,
	CVAR_MAX
}

new const FLOWERS_TAG[ ]					= "[ Flowers ]";

new const FLOWER_MOTD[ ]					= "flower_help.txt";
new const GARDENER_MOTD[ ]					= "gardener_help.txt";

new const SOUND_EXPL[ ] 	 				= "flower/yalala.wav";
new const SOUND_PROV[ ]  	 				= "flower/provocation.wav";
new const SOUND_SHOOP_BEGIN[ ]				= "flower/iamfiringmahlaser.wav";
new const SOUND_SHOOP_LAZER[ ]				= "flower/blahhhhh.wav";
new const FLOWER_MODEL[ ]					= "models/player/lag_plat_/lag_plat_.mdl";

new CsTeams:g_PlayerTeam[ 33 ];
new bool:g_bGibbed[ 33 ];
new bool:g_bAlive[ 33 ];
new bool:g_bIsANewPlayer[ 33 ];
new bool:g_bGoToExplode[ 33 ];
new bool:g_bHasShoopDaWhoop[ 33 ];
new bool:g_bActivatedShoopDaWhoop[ 33 ];

new g_pCvars[ CVAR_MAX ];

new g_MaxPlayers;
new g_ExploSprite;
new g_LastTime[ 33 ];
new g_Beam;
new g_RoundTime;

new g_DeathMsg, g_ScreenfadeMsg;

/*==========================================================================================*/

public plugin_init( )
{
	register_plugin( "flower main", "2.6", "Micapat" );
	register_dictionary( "flower_main.txt" );
	
	register_touch( "weaponbox", "player", "Weapons_Block" );
	register_touch( "armoury_entity", "player", "Weapons_Block" );
	
	RegisterHam( Ham_Spawn, "player", "Player_Spawn", 1 );
	RegisterHam( Ham_Killed, "player", "Player_Killed" );
	RegisterHam( Ham_TakeHealth, "player", "fw_TakeHealth")
	
	register_clcmd( "say /cut", "Cut_Command" );
	register_clcmd( "say_team /cut", "Cut_Command" );
	register_clcmd( "say /ammo", "Ammo_Command" );
	register_clcmd( "say_team /ammo", "Ammo_Command" );
	register_clcmd( "say /shoop", "Shoop_Command" );
	register_clcmd( "say_team /shoop", "Shoop_Command" );
	register_clcmd( "say /help", "Help_Command" );
	
	register_forward( FM_PlayerPreThink, "Player_PreThink" );
	register_forward( FM_EmitSound, "fw_EmitSound" )
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	register_event( "HLTV", "Event_HLTV_New_Round", "a", "1=0", "2=0" );
	//register_message("Health", "message_Health")
	register_message( get_user_msgid("ClCorpse"), "Message_ClCorpse" );
	
	g_pCvars[ CVAR_FW_TIMECANTATTACK ] = 	register_cvar( "Fw_TimeCantAttack", "15" );
	g_pCvars[ CVAR_FW_DAMAGEEXPLOSION ] = 	register_cvar( "Fw_DamageExplosion", "60000.0" );
	g_pCvars[ CVAR_FW_RADIUSEXPLOSION ] = 	register_cvar( "Fw_RadiusExplosion", "250" );
	g_pCvars[ CVAR_FW_SPEEDEXPLOSION ] = 	register_cvar( "Fw_SpeedExplosion", "480.0" );
	g_pCvars[ CVAR_FW_GRAVITYEXPLOSION ] =	register_cvar( "Fw_GravityExplosion", "0.75" );
	g_pCvars[ CVAR_FW_MONEYEXPLOSION ] = 	register_cvar( "Fw_MoneyExplosion", "1000" );
	g_pCvars[ CVAR_FW_FRAGSEXPLOSION ] = 	register_cvar( "Fw_FragsExplosion", "2" );
	g_pCvars[ CVAR_FW_CANBUYSHOOP ] = 		register_cvar( "Fw_CanBuyShoop", "1" );
	g_pCvars[ CVAR_FW_PRICESHOOP ] = 		register_cvar( "Fw_PriceShoop", "16000" );
	g_pCvars[ CVAR_FW_SPEEDSHOOP ] = 		register_cvar( "Fw_SpeedShoop", "120.0" );
	g_pCvars[ CVAR_FW_GRAVITYSHOOP ] = 		register_cvar( "Fw_GravityShoop", "2.5" );
	g_pCvars[ CVAR_GD_TIMESCREENFADE ] = 	register_cvar( "Gd_TimeScreenFade", "7" );
	g_pCvars[ CVAR_GD_COLORSCREENFADE ] = 	register_cvar( "Gd_ColorScreenFade", "000000000" );
	g_pCvars[ CVAR_GD_CANBUYKNIFE ] = 		register_cvar( "Gd_CanBuyKnife", "1" );
	g_pCvars[ CVAR_GD_PRICEKNIFE ] = 		register_cvar( "Gd_PriceKnife", "10000" );
	g_pCvars[ CVAR_GD_CANBUYAMMOS ] = 		register_cvar( "Gd_CanBuyAmmos", "1" );
	g_pCvars[ CVAR_GD_PRICEAMMOS ] = 		register_cvar( "Gd_PriceAmmos", "12000" );
	
	g_MaxPlayers = get_maxplayers( );
	g_DeathMsg = get_user_msgid( "DeathMsg" );
	g_ScreenfadeMsg = get_user_msgid( "ScreenFade" );
	
	set_task( 1.0, "Spawn_RealFlower", 123456789 );
	
	set_cvar_string( "mp_freezetime", "0" );
	set_cvar_string( "mp_playerid", "2" );
	set_cvar_string( "sv_maxspeed", "999" );
	
	set_task(0.5, "MinModels", .flags = "b")
}

public MinModels()
{
	client_cmd(0, "cl_minmodels 0")
}

public fw_TakeHealth(this, Float:health, damagebits)
{
	if(g_PlayerTeam[this] != CS_TEAM_T)
	{
		return HAM_IGNORED
	}
	
	if(!pev(this, pev_waterlevel))
	{
		return HAM_IGNORED
	}
	
	if(damagebits == DMG_GENERIC)
	{
		SetHamParamFloat(2, 0.0)
		return HAM_SUPERCEDE
	}
	
	return HAM_SUPERCEDE
}

public fw_TakeDamage(id, iInflictor, iAttacker, Float:flDamage, iBits)
{
	if(g_PlayerTeam[id] != CS_TEAM_T)
	{
		return FMRES_IGNORED
	}
	
	if(iBits & DMG_DROWN)
	{
		SetHamParamFloat(4, 0.0)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public fw_EmitSound(iEnt, iChannel, szSound[ ], Float:fVolume, Float:fAttn, iFlags, iPitch)
{
	if( !(1<= iEnt <= g_MaxPlayers) || !is_user_alive(iEnt) || g_PlayerTeam[iEnt] != CS_TEAM_T)
	{
		return FMRES_IGNORED
	}

	if(contain(szSound, "pl_swim") != -1 || contain(szSound, "pl_wade") != -1)
	{
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public plugin_precache( )
{
	precache_model( "models/rpgrocket.mdl" ); // Necessary for 3D View
	precache_model( FLOWER_MODEL );
	
	g_Beam = 		precache_model( "sprites/xbeam3.spr" );
	g_ExploSprite = 	precache_model( "sprites/zerogxplode.spr" );
	
	precache_sound( SOUND_EXPL );
	precache_sound( SOUND_PROV );
	precache_sound( SOUND_SHOOP_BEGIN );
	precache_sound( SOUND_SHOOP_LAZER );
}

public Spawn_RealFlower( )
{
	new entity = -1, Float: temp[ 3 ];
	
	while(( entity = find_ent_by_class( entity, "info_target" )) > 0 )
	{
		entity_set_model( entity, FLOWER_MODEL );
		
		// Origin
		entity_get_vector( entity, EV_VEC_origin, temp );
		temp[ 2 ] += 28.0;
		entity_set_origin( entity, temp );
		
		// Angles
		temp[ 0 ] = temp[ 2 ] = 0.0;
		temp[ 1 ] = random_float( 0.0, 360.0 );
		entity_set_vector( entity, EV_VEC_angles, temp );
	}
}

/*==========================================================================================*/

public client_connect( id )
{
	g_bIsANewPlayer[ id ] = true;
	g_bGoToExplode[ id ] = false;
	g_bHasShoopDaWhoop[ id ] = false;
	g_bActivatedShoopDaWhoop[ id ] = false;
	g_bAlive[ id ] = false;
}

public client_disconnect( id )
{
	remove_task( id + TASK_EXPLODE );
	remove_task( id + TASK_SCREENFADE );
	remove_task( id + TASK_CTS_MSG );
	remove_task( id + TASK_TS_MSG );
	remove_task( id + TASK_SHOOP );
	
	g_bIsANewPlayer[ id ] = true;
	g_bGoToExplode[ id ] = false;
	g_bHasShoopDaWhoop[ id ] = false;
	g_bActivatedShoopDaWhoop[ id ] = false;
	g_bAlive[ id ] = false;
}

public Player_PreThink( id )
{
	if( g_bAlive[ id ] && g_PlayerTeam[ id ] == CS_TEAM_T )
	{
		if( !g_bGoToExplode[ id ] )
		{
			new button = entity_get_int( id, EV_INT_button );
			new oldButton = entity_get_int( id, EV_INT_oldbuttons );
			
			if( button & IN_ATTACK2 && !( oldButton & IN_ATTACK2 ))
			{
				if ( g_RoundTime - get_timeleft( ) > get_pcvar_num( g_pCvars[ CVAR_FW_TIMECANTATTACK ] ))
				{
					g_bGoToExplode[ id ] = true;
					
					if( !g_bHasShoopDaWhoop[ id ] ) /* Explode */
					{
						set_user_maxspeed( id, get_pcvar_float( g_pCvars[ CVAR_FW_SPEEDEXPLOSION ] ) );
						set_user_gravity( id, get_pcvar_float( g_pCvars[ CVAR_FW_GRAVITYEXPLOSION ] ) );
						
						emit_sound( id, CHAN_STATIC, SOUND_EXPL, 0.5, ATTN_NORM, 0, PITCH_NORM );
						
						client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "LAUNCH_EXPLODE" );
						client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "LAUNCH_EXPLODE_2" );
						
						set_task ( 3.0, "Explode", id + TASK_EXPLODE );
					}
					else /* Shoop Da Whoop  0_0 */
					{
						emit_sound( id, CHAN_STATIC, SOUND_SHOOP_BEGIN, 1.0, ATTN_NORM, 0, PITCH_NORM );
						
						client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "LAUNCH_SHOOP" );
						
						set_hudmessage ( 12, 109, 190, -1.0, 0.45, 0, 0.1, 2.0, 0.1, 1.0, -1 );
						show_hudmessage ( 0 , "WTFFFFFFFFFFFFFFFFFF ???" );
						
						set_task ( 2.5,  "ShoopdaWhoop", id + TASK_SHOOP );
						set_task ( 12.5, "Explode", id + TASK_EXPLODE );
					}
				}
				else
				{
					client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "CANT_LAUNCH" );
				}
			}
			else if( button & IN_ATTACK && !( oldButton & IN_ATTACK ) && ( g_LastTime[ id ] - get_timeleft( ) > 2 ))
			{
				g_LastTime[ id ] = get_timeleft( );
				emit_sound( id, CHAN_STATIC, SOUND_PROV, 0.5, ATTN_NORM, 0, PITCH_NORM );
			}
		}
		else if( g_bActivatedShoopDaWhoop[ id ] )
		{
			new origin[ 3 ], aim[ 3 ], target, body;
			
			get_user_origin( id, origin);
			get_user_origin( id, aim, 3 );
			
			// Lazeeeeeeeeeeeeeeeer
			message_begin( MSG_PVS, SVC_TEMPENTITY, origin );
			write_byte( TE_BEAMPOINTS )
			write_coord( origin[ 0 ] );
			write_coord( origin[ 1 ] );
			write_coord( origin[ 2 ] );
			write_coord( aim[ 0 ] );
			write_coord( aim[ 1 ] );
			write_coord( aim[ 2 ] );
			write_short( g_Beam );
			write_byte( 1 );
			write_byte( 1 );
			write_byte( 1 );
			write_byte( 210 );
			write_byte( 1 );
			write_byte( 12 );
			write_byte( 109 );
			write_byte( 190 );
			write_byte( 255 );
			write_byte( 50 );
			message_end( );
			
			get_user_aiming( id, target, body );
			
			if( 1 <= target <= g_MaxPlayers && g_PlayerTeam[ target ] == CS_TEAM_CT && g_bAlive[ target ] )
			{
				ExecuteHamB( Ham_TakeDamage, target, id, id, 200.0, DMG_BLAST | DMG_ALWAYSGIB );
				
				if( !g_bAlive[ target ] ) 
				{
					cs_set_user_deaths( target, get_user_deaths( target ) + 1 );
					set_user_frags( id, get_user_frags( id ) + 2 );
					
					message_begin( MSG_ALL, g_DeathMsg );
					write_byte( id );
					write_byte( target );
					write_byte( 0 );
					write_string( "" );
					message_end( );
				}
			}
		}
	}
}

/*==========================================================================================*/

public Player_Spawn( id )
{
	if( is_user_alive( id ))
	{
		if( g_bIsANewPlayer[ id ] )
		{
			g_bIsANewPlayer[ id ] = false;
			
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "HELP_COMMAND" );
			
			//query_client_cvar( id, "cl_minmodels", "Cvar_Result" );
		}
		else
		{
			emit_sound( id, CHAN_STATIC, SOUND_EXPL, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM );
			emit_sound( id, CHAN_STATIC, SOUND_SHOOP_BEGIN, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM );
			emit_sound( id, CHAN_STATIC, SOUND_SHOOP_LAZER, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM );
			
			remove_task( id + TASK_EXPLODE );
			remove_task( id + TASK_SCREENFADE );
			remove_task( id + TASK_CTS_MSG );
			remove_task( id + TASK_TS_MSG );
			remove_task( id + TASK_SHOOP );
			
			g_bGoToExplode[ id ] = false;
			g_bHasShoopDaWhoop[ id ] = false;
			g_bActivatedShoopDaWhoop[ id ] = false;
		}
		
		strip_user_weapons( id );
		g_PlayerTeam[ id ] = cs_get_user_team( id );
		g_bAlive[ id ] = true;
		
		switch( g_PlayerTeam[ id ] )
		{
			case CS_TEAM_T:
			{
				set_view( id, CAMERA_3RDPERSON );
				set_user_footsteps( id, 1 );
				set_user_health( id, 1 );
			}
			case CS_TEAM_CT:
			{
				set_view( id, CAMERA_NONE );
				set_user_footsteps( id, 0 );
				
				set_task( 0.3, "ScreenFade", id + TASK_SCREENFADE );
			}
		}
		
		set_task( float( get_pcvar_num( g_pCvars[ CVAR_GD_TIMESCREENFADE ] )), "Cts_Beginning", id + TASK_CTS_MSG );
		set_task( float( get_pcvar_num( g_pCvars[ CVAR_FW_TIMECANTATTACK ] )), "Ts_Beginning", id + TASK_TS_MSG );
		
		g_LastTime[ id ] = get_timeleft( );
	}
	
	return PLUGIN_CONTINUE;
}

public ScreenFade( id )
{
	id -= TASK_SCREENFADE;
	
	if( g_bAlive[ id ] )
	{
		new timeScreenfade = get_pcvar_num( g_pCvars[ CVAR_GD_TIMESCREENFADE ] ) * 4096;
		new colorScreenfade = get_pcvar_num( g_pCvars[ CVAR_GD_COLORSCREENFADE ] );
		
		if( timeScreenfade < 0 )
			timeScreenfade = 0;
		else if( timeScreenfade > 0xFFFF )
			timeScreenfade = 0xFFFF;
		
		message_begin( MSG_ONE_UNRELIABLE, g_ScreenfadeMsg, { 0, 0, 0 }, id );
		write_short( timeScreenfade );
		write_short( timeScreenfade );
		write_short( 4096 );
		write_byte(( colorScreenfade / 1000000 ));
		write_byte(( colorScreenfade / 1000 ) % 1000 );
		write_byte( colorScreenfade % 1000 );
		write_byte( 255 );
		message_end( );
	}
}

public Cts_Beginning( id )
{
	id -= TASK_CTS_MSG;

	if( g_bAlive[ id ] )
	{
		switch( g_PlayerTeam[ id ] )
		{
			case CS_TEAM_T:
			{
				set_hudmessage ( 255, 0, 0, -1.0, 0.35, 0, 0.1, 2.5, 0.1, 1.0, -1 );
				show_hudmessage ( id , "%L", id, "HUD_SPOTTED" );
			}
			case CS_TEAM_CT:
			{
				set_hudmessage ( 0, 255, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.1, 1.0, -1 );
				show_hudmessage ( id , "%L", id, "HUD_GARDEN" );
				give_item( id, "weapon_usp" );
			}
		}
	}
}

public Ts_Beginning( id )
{
	id -= TASK_TS_MSG;

	if( g_bAlive[ id ] )
	{
		switch( g_PlayerTeam[ id ] )
		{
			case CS_TEAM_T:
			{
				set_hudmessage ( 0, 255, 0, -1.0, 0.35, 0, 0.1, 2.5, 0.1, 1.0, -1 );
				show_hudmessage ( id , "%L", id, "HUD_ANGRY" );
			}
			case CS_TEAM_CT:
			{
				set_hudmessage ( 255, 0, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.1, 1.0, -1 );
				show_hudmessage ( id , "%L", id, "HUD_AGRESSIVE" );
			}
		}
	}
}

public Player_Killed( id, iKiller, iGib )
{
	g_bAlive[ id ] = false;
	
	if( iGib == GIB_ALWAYS )
	{
		g_bGibbed[ id ] = true;
	}	
	
	if( g_bHasShoopDaWhoop[ id ] )
	{
		g_bHasShoopDaWhoop[ id ] = false;
		
		set_hudmessage ( 255, 0, 0, -1.0, 0.35, 0, 0.1, 2.5, 0.1, 1.0, -1 );
		show_hudmessage ( id , "%L", id, "HUD_MADNESS" );
		
		remove_task( id + TASK_EXPLODE );
		
		Explode( id + TASK_EXPLODE );
		
		emit_sound( id, CHAN_STATIC, SOUND_SHOOP_BEGIN, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM );
		emit_sound( id, CHAN_STATIC, SOUND_SHOOP_LAZER, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM );
	}
}

/*==========================================================================================*/

public Event_HLTV_New_Round( )
{
	g_RoundTime = get_timeleft( );
	arrayset( g_bGibbed, false, sizeof( g_bGibbed ));
}

public Message_ClCorpse( msgId, msgDest, msgEnt )
{
	return ( g_bGibbed[ get_msg_arg_int( 12 ) ] ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public Weapons_Block( weapon, player )
{
	return ( g_PlayerTeam[ player ] == CS_TEAM_CT ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

/*==========================================================================================*/

public Cvar_Result( id, const cvar[ ], const value[ ] )
{
	if( is_user_connected( id ))
    {
		if( equali( cvar, "cl_minmodels" ))
		{
			if( !Strcheck( value ))
			{
				static name[ 32 ];
				get_user_name( id, name, charsmax( name ) );
				
				server_cmd( "kick #%d ^"%s^"", get_user_userid( id ), "cl_minmodels different of 0 !" );
				client_print( 0, print_chat, "%s %L", FLOWERS_TAG, 0, "KICK_MINMODELS", name );
			}
			
			//query_client_cvar( id, "cl_minmodels", "Cvar_Result" );
		}
	}
}

stock Strcheck( const string[ ] )
{
	static i; i = 0;
	
	while( string[ i ] )
	{
		if( string[ i++ ] != '0' )
		{
			return 0;
		}
	}
	
	return 1;
}

/*==========================================================================================*/

public Explode( id )
{
	id -= TASK_EXPLODE;
	
	if( is_user_connected( id ))
    {
		g_bHasShoopDaWhoop[ id ] = false;
		
		new enemy, Float:origin[ 3 ], Float:origin_enemy[ 3 ], Float:real_damage;
		entity_get_vector( id, EV_VEC_origin, origin );
		
		new Float:damage = get_pcvar_float( g_pCvars[ CVAR_FW_DAMAGEEXPLOSION ] );
		new Float:radius = get_pcvar_float( g_pCvars[ CVAR_FW_RADIUSEXPLOSION ] );
		
		new money_bonus = get_pcvar_num( g_pCvars[ CVAR_FW_MONEYEXPLOSION ] );
		new frags_bonus = get_pcvar_num( g_pCvars[ CVAR_FW_FRAGSEXPLOSION ] );
		
		new money = cs_get_user_money( id );
		new frags = get_user_frags( id );
		
		// Explosion !
		message_begin_f( MSG_BROADCAST, SVC_TEMPENTITY, origin, 0 );
		write_byte( TE_EXPLOSION );
		write_coord_f( origin[ 0 ] );
		write_coord_f( origin[ 1 ] );
		write_coord_f( origin[ 2 ] );
		write_short( g_ExploSprite );
		write_byte( clamp( floatround( damage ), 0, 255 ));
		write_byte( 15 );
		write_byte( 0 );
		message_end( );
		
		// Kill players around
		while( 1 <= ( enemy = find_ent_in_sphere( enemy, origin, radius )) <= g_MaxPlayers )
		{
			if(( g_PlayerTeam[ enemy ] == CS_TEAM_CT ) && ( g_bAlive[ enemy ] ))
			{
				entity_get_vector( enemy, EV_VEC_origin, origin_enemy );
				
				if(( real_damage = damage / get_distance_f( origin, origin_enemy )) > 1.0 )
				{
					ExecuteHamB( Ham_TakeDamage, enemy, id, id, real_damage, DMG_BLAST|DMG_ALWAYSGIB );
					
					if( !g_bAlive[ enemy ] )
					{
						cs_set_user_deaths( enemy, get_user_deaths( enemy ) + 1 );
						money = ( money + money_bonus > 16000 ) ? 16000 : money + money_bonus;
						frags += frags_bonus;
						
						message_begin( MSG_ALL, g_DeathMsg );
						write_byte( id );
						write_byte( enemy );
						write_byte( 0 );
						write_string( "" );
						message_end( );
					}
				}
			}
		}
		
		cs_set_user_money( id, money );
		set_user_frags( id, frags + 1 );
		cs_set_user_deaths( id, get_user_deaths( id ) - 1 );
		
		ExecuteHamB( Ham_Killed, id, id, GIB_ALWAYS );
	}
}

/*==========================================================================================*/

public ShoopdaWhoop( id )
{
	id -= TASK_SHOOP;
	
	if( g_bAlive[ id ] )
	{
		set_user_maxspeed( id, get_pcvar_float( g_pCvars[ CVAR_FW_SPEEDSHOOP ] ) );
		set_user_gravity( id, get_pcvar_float( g_pCvars[ CVAR_FW_GRAVITYSHOOP ] ) );
		g_bActivatedShoopDaWhoop[ id ] = true;
		
		client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "LAUNCH_SHOOP_2" );
		
		emit_sound( id, CHAN_STATIC, SOUND_SHOOP_LAZER, 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
}

/*==========================================================================================*/

public Cut_Command( id )
{
	if( g_PlayerTeam[ id ] == CS_TEAM_CT && g_bAlive[ id ] && get_pcvar_num( g_pCvars[ CVAR_GD_CANBUYKNIFE ] ))
	{
		new money = cs_get_user_money( id );
		new cost = get_pcvar_num( g_pCvars[ CVAR_GD_PRICEKNIFE ] );
		
		if( money >= cost )
		{
			give_item( id, "weapon_knife" );
			cs_set_user_money( id, money - cost );
			
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "BUY_CUT" );
		}
		else
		{
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "CANT_BUY_CUT", cost - money );
		}
	}
}

public Ammo_Command( id )
{
	if( g_PlayerTeam[ id ] == CS_TEAM_CT && g_bAlive[ id ] && get_pcvar_num( g_pCvars[ CVAR_GD_CANBUYAMMOS ] ))
	{
		new money = cs_get_user_money( id );
		new cost = get_pcvar_num( g_pCvars[ CVAR_GD_PRICEAMMOS ] );
		
		if( money >= cost )
		{
			cs_set_user_money( id, money - cost );
			cs_set_user_bpammo( id, CSW_USP, cs_get_user_bpammo( id, CSW_USP ) + 12 );
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "BUY_AMMOS" );
		}
		else
		{
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "CANT_BUY_AMMOS", cost - money );
		}
	}
}

public Shoop_Command( id )
{
	if( g_PlayerTeam[ id ] == CS_TEAM_T && g_bAlive[ id ] && get_pcvar_num( g_pCvars[ CVAR_FW_CANBUYSHOOP ] ))
	{
		new money = cs_get_user_money( id );
		new cost = get_pcvar_num( g_pCvars[ CVAR_FW_PRICESHOOP ] );
		
		if( money >= cost )
		{
			cs_set_user_money( id, money - cost );
			g_bHasShoopDaWhoop[ id ] = true;
			
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "BUY_SHOOP" );
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "BUY_SHOOP_2" );
		}
		else
		{
			client_print( id, print_chat, "%s %L", FLOWERS_TAG, id, "CANT_BUY_SHOOP", cost - money );
		}
	}
}

public Help_Command( id )
{
	switch( g_PlayerTeam[ id ] )
	{
		case CS_TEAM_T:  show_motd( id, FLOWER_MOTD );
		case CS_TEAM_CT: show_motd( id, GARDENER_MOTD );
	}
}
