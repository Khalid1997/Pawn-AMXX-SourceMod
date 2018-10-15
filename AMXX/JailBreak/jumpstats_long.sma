#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <jumpstats_const>
#include <jumpstats_stocks>
#include <fun>
#include <engine>
#include <xs>

enum
{
	TYPE_LONG,
	TYPE_HIGH,
	
	TYPE_TOTAL
};

#define TypeToJump(%1) (%1 + JUMP_LONG)

new bool:g_reset[33];

new bool:g_connected[33];
new bool:g_alive[33];
new bool:g_jumped[33];
new bool:g_on_ground[33];
new bool:g_first_frame[33];
new bool:g_post_think[33];

new g_script_flags[33];

new Float:g_jump_maxspeed[33];
new g_jump_weapon[33];

new Float:g_jumped_at[33][3];
new Float:g_jump_start[33];

new g_direction[33];

new Float:g_prestrafe[33];

new Float:g_maxspeed[33];

new Float:g_old_speed[33];
new Float:g_good_sync[33];
new Float:g_sync_frames[33];

new g_strafes[33];

new bool:g_turning_right[33];
new bool:g_turning_left[33];
new bool:g_strafing_aw[33];
new bool:g_strafing_sd[33];

new Float:g_strafe_good_sync[33][MAX_STRAFES];
new Float:g_strafe_frames[33][MAX_STRAFES];
new Float:g_strafe_max_speed[33][MAX_STRAFES];
new Float:g_strafe_gained[33][MAX_STRAFES];
new Float:g_strafe_lost[33][MAX_STRAFES];

new Float:g_start_origin[33][3];
new Float:g_start_velocity[33][3];

new Float:g_land_origin[33][3];
new Float:g_land_velocity[33][3];

new g_ground_frames[33];

new g_godlike[33];

new bool:g_failstats[33];
new bool:g_failed_ducking[33];
new Float:g_failstats_origin[33][3];
new Float:g_failstats_velocity[33][3];

new bool:g_highjump[33];

new bool:g_bJumpedOffEntity[ 33 ];
new Float:g_vJumpEntityOrigin[ 33 ][ 3 ];
new Float:g_vJumpEntityMins[ 33 ][ 3 ];
new Float:g_vJumpEntityMaxs[ 33 ][ 3 ];
new Float:g_vJumpEntityAngles[ 33 ][ 3 ];

new bool:g_bCheckSurf[ 33 ];

new cvar_dist_min[TYPE_TOTAL];
new cvar_dist_max[TYPE_TOTAL];
new cvar_dist_leet[TYPE_TOTAL];
new cvar_dist_pro[TYPE_TOTAL];
new cvar_dist_good[TYPE_TOTAL];

new Float:g_dist_min[TYPE_TOTAL];
new Float:g_dist_max[TYPE_TOTAL];
new Float:g_dist_leet[TYPE_TOTAL];
new Float:g_dist_pro[TYPE_TOTAL];
new Float:g_dist_good[TYPE_TOTAL];

new sv_airaccelerate;
new sv_gravity;

new g_max_clients;

#if !defined USE_TEST_BEAM
//new g_beam_sprite;
#endif

new HamHook:g_iHamThinkPre
new HamHook:g_iHamThinkPost
new g_iTouchForward

new g_iJumpForward

public plugin_init()
{
	register_plugin("LongJump Stats", PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_cvar(PLUGIN_NAME, PLUGIN_VERSION, (FCVAR_SERVER|FCVAR_SPONLY));
	
	if( !cstrike_running() ) return;
	
	cvar_dist_min[TYPE_LONG] = register_cvar("js_dist_min_lj", "215");
	cvar_dist_max[TYPE_LONG] = register_cvar("js_dist_max_lj", "270");
	cvar_dist_leet[TYPE_LONG] = register_cvar("js_dist_leet_lj", "250");
	cvar_dist_pro[TYPE_LONG] = register_cvar("js_dist_pro_lj", "245");
	cvar_dist_good[TYPE_LONG] = register_cvar("js_dist_good_lj", "240");
	
	js_update_cvars()
	
	sv_airaccelerate = get_cvar_pointer("sv_airaccelerate");
	sv_gravity = get_cvar_pointer("sv_gravity");
	
	g_max_clients = get_maxplayers();
	
	// from main plugin
	register_touch("func_train", "player", "FwdResetJump");
	register_touch("func_door", "player", "FwdResetJump");
	register_touch("func_door_rotating", "player", "FwdResetJump");
	register_touch("func_conveyor", "player", "FwdResetJump");
	register_touch("func_rotating", "player", "FwdResetJump");
	register_touch("trigger_push", "player", "FwdResetJump");
	register_touch("trigger_teleport", "player", "FwdResetJump");
	/////////////////////////////////////////////////////////
	
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawn", 1);
	RegisterHam(Ham_Killed, "player", "FwdPlayerDeath", 1);
	
	g_iTouchForward = register_forward( FM_Touch, "FwdTouch" );
	
	g_iHamThinkPre = RegisterHam(Ham_Player_PreThink, "player", "fw_ClientPreThink", 0)
	g_iHamThinkPost = RegisterHam(Ham_Player_PostThink, "player", "fw_ClientPostThink", 0)
	
	g_iJumpForward = CreateMultiForward("JS_LongJump", ET_IGNORE, FP_CELL, FP_FLOAT)
	
	Off_JS_Forwards()
}

public FwdResetJump(ent, client)
{
	js_reset_jump(client, false);
}

public On_JS_Forwards()
{
	if(g_iTouchForward == -1)
	{
		g_iTouchForward = register_forward(FM_Touch, "FwdTouch")
	}
	
	EnableHamForward(g_iHamThinkPre)
	EnableHamForward(g_iHamThinkPost)
}

public Off_JS_Forwards()
{
	DisableHamForward(g_iHamThinkPre)
	DisableHamForward(g_iHamThinkPost)
	
	if(g_iTouchForward != -1)
	{
		unregister_forward(FM_Touch, g_iTouchForward)
		g_iTouchForward = -1
	}
}

public js_update_cvars()
{
	for( new i = 0; i < TYPE_TOTAL - 1 /* Addition */; i++ )
	{
		g_dist_min[i] = get_pcvar_float(cvar_dist_min[i]);
		g_dist_max[i] = get_pcvar_float(cvar_dist_max[i]);
		g_dist_leet[i] = get_pcvar_float(cvar_dist_leet[i]);
		g_dist_pro[i] = get_pcvar_float(cvar_dist_pro[i]);
		g_dist_good[i] = get_pcvar_float(cvar_dist_good[i]);
	}
}

public client_putinserver(client)
{
	g_connected[client] = true;
	g_alive[client] = false;
	
	g_godlike[client] = 0;
}

public client_disconnect(client)
{
	g_connected[client] = false;
	g_alive[client] = false;
}

public FwdPlayerSpawn(client)
{
	if( is_user_alive(client) )
	{
		g_alive[client] = true;
		
		g_on_ground[client] = false;
		
		g_reset[client] = true;
	}
}

public FwdPlayerDeath(client, killer, shouldgib)
{
	g_alive[client] = bool:is_user_alive(client);
}

public js_reset_jump(client, bool:func_door)
{
	g_reset[client] = true;
}

public FwdTouch( iEntity1, iEntity2 )
{
	// player touched something while in the air, so reset the jump
	// this prevents surfing
	// 
	// the only problem with this is player could touch a wall during a jump
	// but not lose any speed and this would reset the jump
	// 
	// oh well. this prevents surfing, and i'm happy
	
	if( ( 1 <= iEntity1 <= g_max_clients ) && !IsUserOnGround( iEntity1 ) )
	{
		g_bCheckSurf[ iEntity1 ] = true;
	}
	
	if( ( 1 <= iEntity2 <= g_max_clients ) && !IsUserOnGround( iEntity2 ) )
	{
		g_bCheckSurf[ iEntity2 ] = true;
	}
}

public fw_ClientPreThink(client)
{
	if( !g_alive[client] ) return;
	
	new bool:on_ground = IsUserOnGround(client);
	
	if( g_bCheckSurf[ client ] )
	{
		g_bCheckSurf[ client ] = false;
		
		if( !on_ground && !g_on_ground[ client ] )
		{
			//client_print( client, print_chat, "Reset for surf." );
			
			g_reset[ client ] = true;
			goto finish_prethink;
		}
	}
	
	static Float:old_origin[33][3];
	static bool:started_falling_down[33];
	static Float:old_maxspeed[33];
	static Float:last_maxspeed_change[33];
	
	static Float:origin[3], Float:velocity[3];
	pev(client, pev_origin, origin);
	pev(client, pev_velocity, velocity);
	
	static Float:maxspeed, Float:gravity;
	pev(client, pev_maxspeed, maxspeed);
	pev(client, pev_gravity, gravity);
	
	new bool:ducking = IsUserDucking(client);
	new weapon = get_user_weapon(client);
	
	new airaccelerate = get_pcvar_num(sv_airaccelerate);
	
	if( g_reset[client] != false
	//|| !IsTeamAllowed(client, g_allowteam)
	|| pev(client, pev_movetype) != MOVETYPE_WALK
	|| maxspeed != old_maxspeed[client]
	|| maxspeed != GetClientWeaponMaxspeed(client)
	|| gravity != 1.0
	|| pev(client, pev_waterlevel) > 0
	|| get_distance_f(old_origin[client], origin) > 20.0
	|| get_pcvar_float(sv_gravity) != GRAVITY )
	//|| airaccelerate != 10 && airaccelerate != 100 )
	{
		g_jumped[client] = false;
		g_first_frame[client] = false;
		g_script_flags[client] = 0;
		g_failstats[client] = false;
		g_ground_frames[client] = 0;
		g_reset[client] = false;
		last_maxspeed_change[client] = get_gametime();
		
		goto finish_prethink;
	}
	
	if( !on_ground && g_jumped[client] )
	{
		g_failstats[client] = ((origin[2] + 18) < g_jumped_at[client][2]);
		
		if( !g_failstats[client] )
		{
			if( (ducking ? (origin[2]+18) : origin[2]) >= g_jumped_at[client][2] )
			{
				g_failstats_origin[client] = origin;
				g_failstats_velocity[client] = velocity;
				
				g_failed_ducking[client] = ducking;
			}
			
			/*
			if( g_beam_count[client] < MAX_BEAM_POINTS )
			{
				static Float:origin1[3], Float:origin2[3];
				origin1 = g_beam_origins[client][g_beam_count[client] - 1];
				origin2 = origin;
				new Float:distance = floatsqroot(floatpower(origin1[0]-origin2[0], 2.0) + floatpower(origin1[1]-origin2[1], 2.0));
				
				if( distance >= BEAM_DISTANCE )
				{
					g_beam_origins[client][g_beam_count[client]] = origin;
					
					g_beam_types[client][g_beam_count[client]] = ducking ? BEAM_DUCK : BEAM_STAND;
					
					g_beam_count[client]++;
				}
			}*/
		}
		
		if( !g_first_frame[client] )
		{
			g_first_frame[client] = true;
			g_start_origin[client] = origin;
			g_start_velocity[client] = velocity;
			started_falling_down[client] = false;
		}
		else
		{
			g_land_origin[client] = origin;
			g_land_velocity[client] = velocity;
			
			if( origin[2] < old_origin[client][2] )
			{
				started_falling_down[client] = true;
			}
			else if( started_falling_down[client]
			|| (origin[2] - old_origin[client][2]) > 280.0 )
			{
				g_reset[client] = true;
				
				goto finish_prethink;
			}
		}
	}
	
	new button = pev(client, pev_button);
	new oldbuttons = pev(client, pev_oldbuttons);
	
	if( on_ground && (button & IN_JUMP) && !(oldbuttons & IN_JUMP) )
	{
		if( g_ground_frames[client] >= GROUND_FRAMES )
		{
			new Float:gametime = get_gametime();
			if( last_maxspeed_change[client] > (gametime + 0.7) )
			{
				g_reset[client] = true;
				goto finish_prethink;
			}
			
			g_jump_maxspeed[client] = maxspeed;
			g_jump_weapon[client] = weapon;
			
			g_jumped_at[client] = origin;
			g_jump_start[client] = gametime;
			
			//g_beam_origins[client][0] = origin;
			//g_beam_types[client][0] = ducking ? BEAM_DUCK : BEAM_STAND;
			//g_beam_count[client] = 1;
			
			new Float:speed = floatsqroot(floatpower(velocity[0], 2.0) + floatpower(velocity[1], 2.0));
			
			g_old_speed[client] = g_maxspeed[client] = g_prestrafe[client] = speed;
			
			g_strafing_aw[client] = false;
			g_strafing_sd[client] = false;
			
			g_turning_left[client] = false;
			g_turning_right[client] = false;
			
			g_jumped[client] = true;
			
			g_good_sync[client] = 0.0;
			g_sync_frames[client] = 0.0;
			
			g_strafes[client] = 0;
			
			for( new i = 0; i < MAX_STRAFES; i++ )
			{
				g_strafe_good_sync[client][i] = 0.0;
				g_strafe_frames[client][i] = 0.0;
				g_strafe_max_speed[client][i] = 0.0;
				g_strafe_gained[client][i] = 0.0;
				g_strafe_lost[client][i] = 0.0;
			}
			
			g_direction[client] = GetDirection(client);
			
			g_bJumpedOffEntity[ client ] = false;
			
			new iEntity = entity_get_edict( client, EV_ENT_groundentity );
			if( is_valid_ent( iEntity ) )
			{
				static Float:vOrigin[ 3 ];
				entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
				
				if( vOrigin[ 0 ] != 0.0
				|| vOrigin[ 1 ] != 0.0
				|| vOrigin[ 2 ] != 0.0 )
				{
					g_bJumpedOffEntity[ client ] = true;
					
					xs_vec_copy( vOrigin, g_vJumpEntityOrigin[ client ] );
					entity_get_vector( iEntity, EV_VEC_mins, g_vJumpEntityMins[ client ] );
					entity_get_vector( iEntity, EV_VEC_maxs, g_vJumpEntityMaxs[ client ] );
					entity_get_vector( iEntity, EV_VEC_angles, g_vJumpEntityAngles[ client ] );
				}
			}
			
			set_task(0.8, "TaskResetJump", client);
		}
	}
	else if( (on_ground && !g_on_ground[client] || g_failstats[client]) && g_jumped[client] )
	{
		g_jumped[client] = false;
		g_first_frame[client] = false;
		
		static Float:origin2[3];
		
		if( !g_failstats[client] )
		{
			origin2 = origin;
			if( ducking )
			{
				origin2[2] += 18.0;
			}
			
			if( origin2[2] < g_jumped_at[client][2] )
			{
				g_failstats[client] = true;
			}
		}
		
		if( g_failstats[client] )
		{
			origin2 = g_failstats_origin[client];
		}
		
		new Float:airtime = get_gametime() - g_jump_start[client];
		
		if( g_failstats[client] && (0.710 < airtime < 0.790)
		|| !g_failstats[client] && origin2[2] == g_jumped_at[client][2] && (ducking && (0.718 < airtime < 0.790) || !ducking && (0.650 < airtime < 0.689)) )
		{
			g_highjump[ client ] = false;
			
			static Float:vMiddle[ 3 ];
			xs_vec_add( g_jumped_at[ client ], origin, vMiddle );
			xs_vec_div_scalar( vMiddle, 2.0, vMiddle );
			vMiddle[ 2 ] = g_jumped_at[ client ][ 2 ] - 37.0;
			
			if( engfunc( EngFunc_PointContents, vMiddle ) == CONTENTS_EMPTY )
			{
				static Float:vStart[ 3 ], Float:fLength;
				xs_vec_sub( g_jumped_at[ client ], vMiddle, vStart );
				vStart[ 2 ] = 0.0;
				fLength = vector_length( vStart );
				xs_vec_normalize( vStart, vStart );
				xs_vec_mul_scalar( vStart, fLength + EXTRA_DISTANCE, vStart );
				xs_vec_add( vStart, vMiddle, vStart );
				
				engfunc( EngFunc_TraceLine, vMiddle, vStart, 0, client, 0 );
				
				static Float:fFraction;
				get_tr2( 0, TR_flFraction, fFraction );
				
				if( fFraction != 1.0 )
				{
					static Float:vPlaneNormal[ 3 ];
					get_tr2( 0, TR_vecPlaneNormal, vPlaneNormal );
					
					if( vPlaneNormal[ 2 ] == 0.0 && (
						vPlaneNormal[ 0 ] == 0.0 && floatabs( vPlaneNormal[ 1 ] ) == 1.0
					      || vPlaneNormal[ 1 ] == 0.0 && floatabs( vPlaneNormal[ 0 ] ) == 1.0
					      )
					)
					{
						static Float:vEndPos[ 3 ];
						get_tr2( 0, TR_vecEndPos, vEndPos );
						
						xs_vec_add( vEndPos, vPlaneNormal, vStart );
						vStart[ 2 ] = vMiddle[ 2 ] + 1.0;
						
						xs_vec_copy( vStart, vEndPos );
						vEndPos[ 2 ] -= 70.0;
						
						engfunc( EngFunc_TraceLine, vStart, vEndPos, 0, client, 0 );
						
						get_tr2( 0, TR_flFraction, fFraction );
						
						g_highjump[ client ] = ( fFraction == 1.0 );
					}
				}
			}
			
			static Float:distance, Float:land_origin[3];
			if( g_failstats[client] )
			{
				distance = GetFailedDistance(g_failed_ducking[client], GRAVITY, g_jumped_at[client], velocity, g_failstats_origin[client], g_failstats_velocity[client]);
				
				land_origin = origin;
			}
			else
			{
				static Float:frame_origin[2][3], Float:frame_velocity[2][3];
				
				xs_vec_copy(g_start_origin[client], frame_origin[0]);
				xs_vec_copy(g_land_origin[client], frame_origin[1]);
				
				xs_vec_copy(g_start_velocity[client], frame_velocity[0]);
				xs_vec_copy(g_land_velocity[client], frame_velocity[1]);
				
				CalculateLandOrigin(ducking, GRAVITY, origin, frame_origin, frame_velocity, land_origin);
				
				static Float:dist1, Float:dist2;
				dist1 = get_distance_f(g_jumped_at[client], origin);
				dist2 = get_distance_f(g_jumped_at[client], land_origin);
				
				if( dist1 < dist2 )
				{
					distance = dist1;
					land_origin = origin;
				}
				else
				{
					distance = dist2;
				}
				
				distance += EXTRA_DISTANCE;
				
				if( g_highjump[ client ] )
				{
					// This is for skywalk detection
					
					g_highjump[ client ] = false;
					
					static Float:vFixedStart[ 3 ];
					xs_vec_copy( land_origin, vFixedStart );
					vFixedStart[ 2 ] -= 36.0;
					
					static Float:vDirections[ 4 ][ 3 ], bool:bExecutedOnce;
					if( !bExecutedOnce )
					{
						for( new i = 0; i < 4; i++ )
						{
							vDirections[ i ][ 0 ] = vDirections[ i ][ 1 ] = ( EXTRA_DISTANCE / 2.0 );
							if( ( i % 2 ) == 0 )
							{
								vDirections[ i ][ 0 ] *= -1;
							}
							if( ( i / 2 ) == 0 )
							{
								vDirections[ i ][ 1 ] *= -1;
							}
						}
						
						bExecutedOnce = true;
					}
					
					// check if any of the 4 corners of the player is above ground
					// if so, then player is on ground and not skywalking
					static Float:vStart[ 3 ], Float:vStop[ 3 ], Float:fFraction;
					for( new i = 0; i < 4; i++ )
					{
						xs_vec_add( vFixedStart, vDirections[ i ], vStart );
						xs_vec_copy( vStart, vStop );
						vStop[ 2 ] -= 70.0;
						
						engfunc( EngFunc_TraceLine, vStart, vStop, 0, client, 0 );
						
						get_tr2( 0, TR_flFraction, fFraction );
						
						if( fFraction != 1.0 )
						{
							g_highjump[ client ] = true;
							break;
						}
					}
					
					if( g_highjump[ client ] )
					{
						// This is for detection of jumping along the edge ( such as a building )
						
						vMiddle[ 2 ] = land_origin[ 2 ];
						
						static Float:vDirection[ 3 ];
						xs_vec_sub( land_origin, g_jumped_at[ client ], vDirection );
						vDirection[ 2 ] = 0.0;
						
						static Float:vWallOrigin[ 2 ][ 3 ];
						for( new i = 0; i < 2; i++ )
						{
							vWallOrigin[ 0 ][ 0 ] = vDirection[ 1 ];
							vWallOrigin[ 0 ][ 1 ] = vDirection[ 0 ];
							vWallOrigin[ 0 ][ i ] *= -1;
							vWallOrigin[ 0 ][ 2 ] = 0.0;
							
							xs_vec_add( vMiddle, vWallOrigin[ 0 ], vWallOrigin[ 0 ] );
							xs_vec_copy( vWallOrigin[ 0 ], vWallOrigin[ 1 ] );
							vWallOrigin[ 1 ][ 2 ] -= 40.0;
							
							engfunc( EngFunc_TraceLine, vWallOrigin[ 0 ], vWallOrigin[ 1 ], 0, client, 0 );
							
							get_tr2( 0, TR_flFraction, fFraction );
							
							if( fFraction != 1.0 )
							{
								g_highjump[ client ] = false;
								break;
							}
						}
					}
				}
			}
			
			new type = g_highjump[client] ? TYPE_HIGH : TYPE_LONG;
			new jump_type = TypeToJump(type);
			
			////////////////////////////////////////////////////
			/*if(type == TYPE_HIGH)
			{
				return;
			} */ 
			////////////////////////////////////////////////////
			
			/*if( !IsTechAllowed(jump_type, g_techs_allowed) )
			{
				g_reset[client] = true;
				goto finish_prethink;
			}*/
			
			static Float:jump_edge, Float:land_edge, block, block_jump;
			
			block_jump = GetEdgeDistances( jump_type, ducking, g_failstats[ client ], g_jumped_at[ client ], land_origin, g_bJumpedOffEntity[ client ],\
				g_vJumpEntityOrigin[ client ], g_vJumpEntityAngles[ client ], g_vJumpEntityMins[ client ], g_vJumpEntityMaxs[ client ],\
				jump_edge, land_edge, block
				);
			
			if( g_dist_min[type] <= distance <= g_dist_max[type] )
			{
				//new sync = floatround(g_good_sync[client] / g_sync_frames[client] * 100.0);
				
				if(!g_failstats[client] /*&& !g_script_flags[client]*/)
				{
					new iRet
					ExecuteForward(g_iJumpForward, iRet, client, distance)
					//client_print(0, print_chat, "Long Jump %0.2f", distance)
				}
				
				//else client_print(0, print_chat, "long jump failed")
				
				/*if( g_jump_maxspeed[client] == 250.0 && !g_failstats[client] && !g_script_flags[client]
				&& js_check_user_best(client, jump_type, g_direction[client], distance, g_prestrafe[client], g_maxspeed[client], g_strafes[client], sync) )
				{
					switch( g_show_best )
					{
						case 1:
						{
							if( js_user_has_colorchat(client) )
							{
								ColorChat(client, BLUE, "[JUMPSTATS] You beat your personal best for %s with a %.3f jump!", g_jump_names[jump_type], distance);
							}
						}
						case 2:
						{
							static name[32];
							get_user_name(client, name, sizeof(name) - 1);
							
							for( new i = 1; i <= g_max_clients; i++ )
							{
								if( i == client )
								{
									if( js_user_has_colorchat(client) )
									{
										ColorChat(client, BLUE, "[JUMPSTATS] You beat your personal best for %s with a %.3f jump!", g_jump_names[jump_type], distance);
									}
								}
								else if( g_connected[i] )
								{
									if( js_user_has_colorchat(i) )
									{
										ColorChat(i, BLUE, "[JUMPSTATS] %s beat their personal best for %s with a %.3f jump!", name, g_jump_names[jump_type], distance);
									}
								}
							}
						}
					}
				}
				
				if( g_beam_count[client] == MAX_BEAM_POINTS )
				{
					g_beam_count[client]--;
				}
				
				g_beam_origins[client][g_beam_count[client]][0] = land_origin[0];
				g_beam_origins[client][g_beam_count[client]][1] = land_origin[1];
				g_beam_origins[client][g_beam_count[client]][2] = land_origin[2];
				
				g_beam_types[client][g_beam_count[client]] = ducking ? BEAM_DUCK : BEAM_STAND;
				
				g_beam_count[client]++;
				
				static r, g, b;
				if( g_script_flags[client] || g_failstats[client] )
				{
					r = g_fail_color[R];
					g = g_fail_color[G];
					b = g_fail_color[B];
				}
				else
				{
					r = g_hud_color[R];
					g = g_hud_color[G];
					b = g_hud_color[B];
				}
				*/
				
				new r = 255, g = 255, b = 255
				
				new Float:leet = g_dist_leet[type];
				new Float:pro = g_dist_pro[type];
				new Float:good = g_dist_good[type];
				
				/*new fail[15];
				if( g_failstats[client] )
				{
					copy(fail, sizeof(fail) - 1, " (Failed)");
				}*/
				
				/*new direction[32];
				if( g_direction_forwards ||  g_direction[client] != DIR_FORWARDS )
				{
					formatex(direction, sizeof(direction) - 1, " %s", g_direction_names[g_direction[client]]);
				}
				
				new direction_hud[64];
				if( direction[0] )
				{
					formatex(direction_hud, sizeof(direction_hud) - 1, "Direction: %s^n", direction);
				}
				
				static message1[192], message2[192];
				
				formatex(message1, sizeof(message1) - 1, "Type: %s^n\
				%%sDistance: %f^n\
				MaxSpeed: %f (%.3f)",\
					g_jump_names[jump_type],\
					distance,\
					g_maxspeed[client],\
					g_maxspeed[client] - g_prestrafe[client]
					);
				
				formatex(message2, sizeof(message2) - 1, "PreStrafe: %f^nStrafes: %i",\
					g_prestrafe[client],\
					g_strafes[client]);
				
				static message1_dir[192];
				for( new i = 1; i <= g_max_clients; i++ )
				{
					if( i == client )
					//|| g_connected[i]
					//&& IsUserSpectatingPlayer(i, client)
					//&& js_user_has_jumpstats(i)
					//&& js_user_has_specstats(i) )
					{
						//formatex(message1_dir, sizeof(message1_dir) - 1, message1, js_user_has_dirhud(i) ? direction_hud : "");
						
						set_hudmessage(r, g, b, HUD_POS_STATS_X, HUD_POS_STATS_Y, 0, 0.0, HUD_TIME_STATS, HUD_FADE_IN, HUD_FADE_OUT, 1);
						show_hudmessage(i, "%s^n%s", message1, message2);
					}
				}
				
				
				if( !g_script_flags[client] && g_jump_maxspeed[client] == 250.0 )
				{
					console_print(client, "----------------------------------------");
					console_print(client, message1, direction_hud);
					console_print(client, "%s%%", message2);
					
					new szBlockInfo[ 64 ], iLen;
					if( block_jump )
					{
						iLen = formatex( szBlockInfo, 63, "Block: %i^n", block );
					}
					if( jump_edge >= 0.0 )
					{
						iLen += formatex( szBlockInfo[ iLen ], 63 - iLen, "Jump Edge: %f^n", jump_edge );
					}
					if( !g_failstats[ client ] && land_edge >= 0.0 )
					{
						iLen += formatex( szBlockInfo[ iLen ], 63 - iLen, "Land Edge: %f^n", land_edge );
					}
					
					console_print( client, "^n%s", szBlockInfo );
				}
				
				if( g_strafes[client] > 1 )
				{
					if( !g_script_flags[client] && g_jump_maxspeed[client] == 250.0 )
					{				// |---------|---------|---------|
						console_print(client, " #. Sync      Gained    Lost      MaxSpeed");
					}
					
					static strafes_info[512];
					new len = copy(strafes_info, sizeof(strafes_info) - 1, " #. Sync      Gained    Lost      MaxSpeed");
					for( new i = 0; i < g_strafes[client]; i++ )
					{
						len += formatex(strafes_info[len], sizeof(strafes_info) - len - 1, "^n%2i. %3i%s     %3.3f      %3.3f      %3.3f",\
							i + 1,\
							floatround(g_strafe_good_sync[client][i] / g_strafe_frames[client][i] * 100.0),\
							"%",\
							g_strafe_gained[client][i],\
							g_strafe_lost[client][i],\
							g_strafe_max_speed[client][i]
							);
						
						if( !g_script_flags[client] && g_jump_maxspeed[client] == 250.0 )
						{
							console_print(client, "%2i. %3i%s        %3.3f      %3.3f      %3.3f",\
								i + 1,\
								floatround(g_strafe_good_sync[client][i] / g_strafe_frames[client][i] * 100.0),\
								"%%",\
								g_strafe_gained[client][i],\
								g_strafe_lost[client][i],\
								g_strafe_max_speed[client][i]
								);
						}
					}
					
					for( new i = 1; i <= g_max_clients; i++ )
					{
						if( (i == client
							|| g_connected[i]
							&& IsUserSpectatingPlayer(i, client)
							&& js_user_has_jumpstats(i)
							&& js_user_has_specstats(i))
						&& js_user_has_strafestats(i) )
						{
							set_hudmessage(r, g, b, HUD_POS_STRAFE_X, HUD_POS_STRAFE_Y, 0, 0.0, HUD_TIME_STRAFE, HUD_FADE_IN, HUD_FADE_OUT, 2);
							show_hudmessage(i, "%s", strafes_info);
						}
					}
				}
				
				static szBlock[ 16 ];
				if( block_jump )
				{
					formatex( szBlock, 15, "Block: %i^n", block );
				}
				else
				{
					szBlock[ 0 ] = '^n';
					szBlock[ 1 ] = '^0';
				}
				
				static szJumpDist[ 32 ];
				if( jump_edge >= 0.0 )
				{
					formatex( szJumpDist, 31, "Jump Edge: %f^n", jump_edge );
				}
				else
				{
					szJumpDist[ 0 ] = '^n';
					szJumpDist[ 1 ] = '^0';
				}
				
				static szLandDist[ 32 ];
				if( !g_failstats[ client ] && land_edge >= 0.0 )
				{
					formatex( szLandDist, 31, "Land Edge: %f", land_edge );
				}
				else
				{
					szLandDist[ 0 ] = '^0';
				}
				
				for( new i = 1; i <= g_max_clients; i++ )
				{
					if( (i == client
						|| g_connected[i]
						&& IsUserSpectatingPlayer(i, client)
						&& js_user_has_jumpstats(i)
						&& js_user_has_specstats(i))
					)
					{
						if( js_user_has_edgedist( i ) )
						{
							set_hudmessage(r, g, b, HUD_POS_EDGE_X, HUD_POS_EDGE_Y, 0, 0.0, HUD_TIME_EDGE, HUD_FADE_IN, HUD_FADE_OUT, 3);
							show_hudmessage(i, "%s%s%s", js_user_has_blockdist( i ) ? szBlock : "^n", szJumpDist, szLandDist);
						}
						else if( js_user_has_blockdist( i ) )
						{
							set_hudmessage(r, g, b, HUD_POS_EDGE_X, HUD_POS_EDGE_Y, 0, 0.0, HUD_TIME_EDGE, HUD_FADE_IN, HUD_FADE_OUT, 3);
							show_hudmessage(i, "%s", szBlock);
						}
					}
				}
				
				if( !g_script_flags[client] && g_jump_maxspeed[client] == 250.0 )
				{
					console_print(client, "----------------------------------------");
				}
				*/
				switch( g_script_flags[client] )
				{
					case (SCRIPT_AIRSTRAFE | SCRIPT_PRESTRAFE):
					{
						//client_print(client, print_center, "%s Script!", g_jump_names[jump_type]);
						
						g_godlike[client] = 0;
					}
					case SCRIPT_PRESTRAFE:
					{
					//	client_print(client, print_center, "PreStrafe Script!");
						
						g_godlike[client] = 0;
					}
					case SCRIPT_AIRSTRAFE:
					{
					//	client_print(client, print_center, "AirStrafe Script!");
						
						g_godlike[client] = 0;
					}
					/*case 0:
					{
						if( !g_failstats[client] && ( g_weapons_chat & ( 1 << g_jump_weapon[client] ) ) )
						{
							static name[32];
							get_user_name(client, name, sizeof(name) - 1);
							
							new bool:bSound = ( g_weapons_sound & ( 1 << g_jump_weapon[client] ) ) ? true : false;
							
							new pos = 0;
							if( g_jump_maxspeed[client] == 250.0 )
							{
								pos = js_check_user_top(client, jump_type, g_direction[client], distance, g_prestrafe[client], g_maxspeed[client], g_strafes[client], sync);
								
								if( pos )
								{
									for( new i = 1; i <= g_max_clients; i++ )
									{
										if( g_connected[i] && js_user_has_colorchat(i) )
										{
											client_print(i, print_chat, "[JUMPSTATS] %s is now #%i in the %s Top with a %.3f jump!", name, pos, g_jump_names[jump_type], distance);
										}
									}
								}
							}
							
							new speed[64];
							if( g_show_default_speed || g_jump_maxspeed[client] != 250.0 )
							{
								new Float:advantage = g_jump_maxspeed[client] - 250.0;
								if( advantage == 0.0 )
								{
									formatex(speed, sizeof(speed) - 1, " with a %s (legal speed)", g_weapon_names[g_jump_weapon[client]]);
								}
								else
								{
									formatex(speed, sizeof(speed) - 1, " with a %s (%s%i speed)", g_weapon_names[g_jump_weapon[client]], advantage >= 0.0 ? "+" : "-", floatround(floatabs(advantage)));
								}
							}
							
							if( leet <= distance )
							{
								if( g_jump_maxspeed[client] == 250.0 )
								{
									++g_godlike[client];
								}
								else
								{
									g_godlike[client] = 0;
								}
								
								for( new i = 1; i <= g_max_clients; i++ )
								{
									if( !g_connected[i] ) continue;
									
									if( bSound && g_sound_leet > 0 && (g_sound_leet == 2 || (i == client || IsUserSpectatingPlayer(i, client) && js_user_has_specstats(i)) && g_sound_leet == 1) && js_user_has_sounds(i) )
									{
										if( 1 <= pos <= 10 )
										{
											// DOMINATING!!!!
											client_cmd(i, "speak %s", g_sound_files[SOUND_DOMINATING_GODLIKE]);
										}
										else if( (leet + g_holyshit) <= distance )
										{
											// HOLY SHIT
											client_cmd(i, "speak %s", g_sound_files[SOUND_HOLYSHIT]);
										}
										else if( g_godlike[client] >= g_rampage )
										{
											// rampage
											client_cmd(i, "speak %s", g_sound_files[SOUND_RAMPAGE]);
										}
										else
										{
											// godlike
											client_cmd(i, "speak %s", g_sound_files[SOUND_GODLIKE]);
										}
									}
									
									if( js_user_has_colorchat(i) )
									{
										ColorChat(i, g_color_leet, "[JUMPSTATS] %s %s'd %.3f units%s%s!", name, g_jump_names[jump_type], distance, direction, speed);
									}
								}
							}
							else
							{
								g_godlike[client] = 0;
								
								if( good <= distance < pro )
								{
									// impressive
									for( new i = 1; i <= g_max_clients; i++ )
									{
										if( !g_connected[i] ) continue;
										
										if( bSound && g_sound_good > 0 && (g_sound_good == 2 || (i == client || IsUserSpectatingPlayer(i, client) && js_user_has_specstats(i)) && g_sound_good == 1) )
										{
											if( js_user_has_sounds(i) )
											{
												client_cmd(i, "speak %s", g_sound_files[SOUND_IMPRESSIVE]);
											}
										}
										
										if( js_user_has_colorchat(i) )
										{
											ColorChat(i, g_color_good, "[JUMPSTATS] %s %s'd %.3f units%s%s!", name, g_jump_names[jump_type], distance, direction, speed);
										}
									}
								}
								else if( pro <= distance < leet )
								{
									for( new i = 1; i <= g_max_clients; i++ )
									{
										if( !g_connected[i] ) continue;
										
										if( bSound && g_sound_pro > 0 && (g_sound_pro == 2 || (i == client || IsUserSpectatingPlayer(i, client) && js_user_has_specstats(i)) && g_sound_pro == 1) && js_user_has_sounds(i) )
										{
											if( 1 <= pos <= 10 )
											{
												// dominating
												client_cmd(i, "speak %s", g_sound_files[SOUND_DOMINATING]);
											}
											else
											{
												// perfect
												client_cmd(i, "speak %s", g_sound_files[SOUND_PERFECT]);
											}
										}
										
										if( js_user_has_colorchat(i) )
										{
											ColorChat(i, g_color_pro, "[JUMPSTATS] %s %s'd %.3f units%s%s!", name, g_jump_names[jump_type], distance, direction, speed);
										}
									}
								}
							}
						}
						else if( g_failstats[client] )
						{
							g_godlike[client] = 0;
						}
					}*/
				}
				
				/*if( g_beam_type )
				{
					new Float:height = g_jumped_at[client][2] + 2.0;
					
					switch( g_beam_type )
					{
						case 1:
						{
							if( g_beam_color )
							{
								new color = random(sizeof(g_default_beam_colors));
								r = g_default_beam_colors[color][R];
								g = g_default_beam_colors[color][G];
								b = g_default_beam_colors[color][B];
							}
							else
							{
								r = random(256);
								g = random(256);
								b = random(256);
							}
							
							for( new c = 1; c <= g_max_clients; c++ )
							{
								if( c != client )
								{
									if( !g_connected[c]
									|| !IsUserSpectatingPlayer(c, client)
									|| !js_user_has_specstats(c) ) continue;
								}
								
								if( !js_user_has_beam(c) ) continue;
								
								message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, c);
								write_byte(TE_BEAMPOINTS);
								engfunc(EngFunc_WriteCoord, g_jumped_at[client][0]);
								engfunc(EngFunc_WriteCoord, g_jumped_at[client][1]);
								engfunc(EngFunc_WriteCoord, height);
								engfunc(EngFunc_WriteCoord, g_beam_origins[client][g_beam_count[client] - 1][0]);
								engfunc(EngFunc_WriteCoord, g_beam_origins[client][g_beam_count[client] - 1][1]);
								engfunc(EngFunc_WriteCoord, height);
								write_short(g_beam_sprite);
								write_byte(1);
								write_byte(5);
								write_byte(floatround((BEAM_TIME + DECAY_BEAM_TIME) * 10.0));
								write_byte(20);
								write_byte(0);
								write_byte(r);
								write_byte(g);
								write_byte(b);
								write_byte(200);
								write_byte(200);
								message_end();
							}
						}
						case 2:
						{
							for( new c = 1; c <= g_max_clients; c++ )
							{
								if( c != client )
								{
									if( !g_connected[c]
									|| !IsUserSpectatingPlayer(c, client)
									|| !js_user_has_specstats(c) ) continue;
								}
								
								if( !js_user_has_beam(c) ) continue;
								
								for( new i = 1; i < g_beam_count[client]; i++ )
								{
									message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, c);
									write_byte(TE_BEAMPOINTS);
									engfunc(EngFunc_WriteCoord, g_beam_origins[client][i - 1][0]);
									engfunc(EngFunc_WriteCoord, g_beam_origins[client][i - 1][1]);
									engfunc(EngFunc_WriteCoord, height);
									engfunc(EngFunc_WriteCoord, g_beam_origins[client][i][0]);
									engfunc(EngFunc_WriteCoord, g_beam_origins[client][i][1]);
									engfunc(EngFunc_WriteCoord, height);
									write_short(g_beam_sprite);
									write_byte(1);
									write_byte(5);
									write_byte(max(1, floatround(float(i) / float(g_beam_count[client] - 1) * DECAY_BEAM_TIME * 10.0 + BEAM_TIME * 10.0)));
									write_byte(20);
									write_byte(0);
									switch( g_beam_types[client][i - 1] )
									{
										case BEAM_PREDUCK:
										{
											write_byte(0);
											write_byte(255);
											write_byte(0);
										}
										case BEAM_STAND:
										{
											write_byte(255);
											write_byte(255);
											write_byte(0);
										}
										case BEAM_DUCK:
										{
											write_byte(255);
											write_byte(0);
											write_byte(0);
										}
									}
									write_byte(200);
									write_byte(200);
									message_end();
								}
							}
						}
					}
				}*/
			}
		}
		
		g_highjump[client] = false;
		g_failstats[client] = false;
		g_prestrafe[client] = 0.0;
		g_maxspeed[client] = 0.0;
		g_old_speed[client] = 0.0;
		g_good_sync[client] = 0.0;
		g_sync_frames[client] = 0.0;
		g_strafes[client] = 0;
		g_script_flags[client] = 0;
		
		for( new i = 0; i < MAX_STRAFES; i++ )
		{
			g_strafe_good_sync[client][i] = 0.0;
			g_strafe_frames[client][i] = 0.0;
			g_strafe_max_speed[client][i] = 0.0;
			g_strafe_gained[client][i] = 0.0;
			g_strafe_lost[client][i] = 0.0;
		}
		
		//g_beam_count[client] = 0;
	}
	
	finish_prethink:
	
	old_origin[client] = origin;
	old_maxspeed[client] = maxspeed;
	
	if( !g_post_think[client] )
	{
		if( on_ground )	g_ground_frames[client]++;
		else		g_ground_frames[client] = 0;
	}
	else	g_post_think[client] = false;
	
	g_on_ground[client] = on_ground;
}

public TaskResetJump(client)
{
	g_reset[client] = true;
}

public fw_ClientPostThink(client)
{
	if( !g_alive[client] /*|| !IsTeamAllowed(client, g_allowteam)*/ || g_failstats[client] ) return;
	
	new bool:on_ground = IsUserOnGround(client);
	
	if( on_ground && g_jumped[client] && !g_on_ground[client] )
	{
		g_post_think[client] = true;
		fw_ClientPreThink(client);
	}
	
	static Float:old_angle[33];
	
	static Float:angles[3];
	pev(client, pev_angles, angles);
	
	g_turning_right[client] = false;
	g_turning_left[client] = false;
	
	if( angles[1] < old_angle[client] )
	{
		g_turning_right[client] = true;
	}
	else if( angles[1] > old_angle[client] )
	{
		g_turning_left[client] = true;
	}
	
	old_angle[client] = angles[1];
	
	new button = pev(client, pev_button);
	
	if( !on_ground )
	{
		static Float:velocity[3];
		pev(client, pev_velocity, velocity);
		new Float:speed = floatsqroot(floatpower(velocity[0], 2.0) + floatpower(velocity[1], 2.0));
		
		if( g_turning_left[client] || g_turning_right[client] )
		{
			if( !g_strafing_aw[client] && ((button & IN_FORWARD) || (button & IN_MOVELEFT)) && !(button & IN_MOVERIGHT) && !(button & IN_BACK) )
			{
				g_strafing_aw[client] = true;
				g_strafing_sd[client] = false;
				
				if( 0 < ++g_strafes[client] <= MAX_STRAFES )
				{
					g_strafe_max_speed[client][g_strafes[client] - 1] = speed;
				}
			}
			else if( !g_strafing_sd[client] && ((button & IN_BACK) || (button & IN_MOVERIGHT)) && !(button & IN_MOVELEFT) && !(button & IN_FORWARD) )
			{
				g_strafing_aw[client] = false;
				g_strafing_sd[client] = true;
				
				if( 0 < ++g_strafes[client] <= MAX_STRAFES )
				{
					g_strafe_max_speed[client][g_strafes[client] - 1] = speed;
				}
			}
		}
		
		if( g_maxspeed[client] < speed )
		{
			g_maxspeed[client] = speed
		}
		
		if( g_old_speed[client] < speed )
		{
			g_good_sync[client]++;
			
			if( 0 < g_strafes[client] <= MAX_STRAFES )
			{
				g_strafe_good_sync[client][g_strafes[client] - 1]++;
				g_strafe_gained[client][g_strafes[client] - 1] += (speed - g_old_speed[client]);
			}
		}
		else if( g_old_speed[client] > speed )
		{
			if( 0 < g_strafes[client] <= MAX_STRAFES )
			{
				g_strafe_lost[client][g_strafes[client] - 1] += (g_old_speed[client] - speed);
			}
		}
		
		g_sync_frames[client]++;
		
		if( 0 < g_strafes[client] <= MAX_STRAFES )
		{
			g_strafe_frames[client][g_strafes[client] - 1]++;
			
			if( g_strafe_max_speed[client][g_strafes[client] - 1] < speed )
			{
				g_strafe_max_speed[client][g_strafes[client] - 1] = speed;
			}
		}
		
		g_old_speed[client] = speed;
	}
	
	if( (button & IN_LEFT) || (button & IN_RIGHT) )
	{
		if( on_ground )
		{
			if( g_script_flags[client] & SCRIPT_AIRSTRAFE )
			{
				g_script_flags[client] &= ~SCRIPT_AIRSTRAFE;
			}
			
			remove_task(client);
			
			if( !(g_script_flags[client] & SCRIPT_PRESTRAFE) )
			{
				g_script_flags[client] |= SCRIPT_PRESTRAFE;
			}
		}
		else if( g_jumped[client] && !(g_script_flags[client] & SCRIPT_AIRSTRAFE) )
		{
			g_script_flags[client] |= SCRIPT_AIRSTRAFE;
		}
	}
	else if( on_ground )
	{
		if( g_script_flags[client] & SCRIPT_AIRSTRAFE )
		{
			g_script_flags[client] &= ~SCRIPT_AIRSTRAFE;
		}
		
		if( !task_exists(client) && (g_script_flags[client] & SCRIPT_PRESTRAFE) )
		{
			set_task(1.5, "TaskRemovePreStrafeScript", client);
		}
	}
}

public TaskRemovePreStrafeScript(client)
{
	if( g_script_flags[client] & SCRIPT_PRESTRAFE )
	{
		g_script_flags[client] &= ~SCRIPT_PRESTRAFE;
	}
}
