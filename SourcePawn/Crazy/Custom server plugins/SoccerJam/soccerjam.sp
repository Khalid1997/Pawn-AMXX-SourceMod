#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <smlib>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define SOCCERJAMSOURCE_VERSION	 "2.1.3"
#define SOCCERJAMSOURCE_URL "http://steamcommunity.com/groups/sj-source"

typedef UpgradeFunc = function void(int client, float upgradeValue);

#include "soccerjam/constants.sp"
#include "soccerjam/globalvars.sp"
#include "soccerjam/enginetools.sp"
#include "soccerjam/sjtools.sp"
#include "soccerjam/clients.sp"

#include "parts/parts.sp"
#include "parts/BALL_(ball).sp"
#include "parts/BAR_(ball_autorespawn).sp"
#include "parts/BBM_(ball_bounce_multiplier).sp"
#include "parts/BBS_(ball_bounce_sound).sp"
#include "parts/BE_(ball_explosion).sp"
#include "parts/BK_(ball_kick).sp"
#include "parts/BR_(ball_receiving).sp"
#include "parts/BT_(ball_trail).sp"
#include "parts/CB_(curve_ball).sp"
#include "parts/CM_(config_manager).sp"
#include "parts/DSRM_(disarm).sp"
#include "parts/DZ_(death_zone).sp"
#include "parts/FFI_(frags_for_interception).sp"
#include "parts/GA_(goal_assist).sp"
#include "parts/GD_(goal_distance).sp"
#include "parts/GOAL_(goal).sp"
#include "parts/GSM_(game_specific_manager).sp"
#include "parts/HLF_(half).sp"
#include "parts/HLP_(help).sp"
#include "parts/HLTH_(health).sp"
#include "parts/KAS_(ka_soccer_maps_support).sp"
#include "parts/LJ_(long_jump).sp"
#include "parts/MM_(model_manager).sp"
#include "parts/MSM_(match_stats_manager).sp"
#include "parts/MTCH_(match).sp"
#include "parts/MVP_(mvp_stars).sp"
#include "parts/NDAG_(no_damage_after_goal).sp"
#include "parts/NFFK_(no_frags_for_kill).sp"
#include "parts/NOFF_(no_friendly_fire).sp"
#include "parts/NRD_(no_round_draw).sp"
#include "parts/NREM_(no_round_end_message).sp"
#include "parts/PAC_(player_attack_check).sp"
#include "parts/PR_(player_respawn).sp"
#include "parts/RBAH_(remove_bomb_and_hostages).sp"
#include "parts/RS_(reward_system).sp"
#include "parts/RTE_(round_time_extend).sp"
#include "parts/RWOS_(remove_weapons_on_spawn).sp"
#include "parts/SG_(speed_and_gravity).sp"
#include "parts/SJB_(sj_builder).sp"
#include "parts/SJE_(sj_entities).sp"
#include "parts/SJT_(sj_timer).sp"
#include "parts/SM_(sound_manager).sp"
#include "parts/SSP_(swap_spawn_points).sp"
#include "parts/TBHD_(teleport_ball_on_holder_death).sp"
#include "parts/TEST_(test).sp"
#include "parts/TM_(team_models).sp"
#include "parts/TRB_(turbo).sp"
#include "parts/TU_(team_upgrade).sp"
#include "parts/UM_(upgrade_manager).sp"
#include "parts/WM_(welcome_message).sp"

public Plugin myinfo = 
{
	name = "SoccerJam: Source",
	author = "AlexSang",
	description = "SoccerJam mod for CS:GO",
	version = SOCCERJAMSOURCE_VERSION,
	url = SOCCERJAMSOURCE_URL
}'

public void OnPluginStart()
{
	CreateConVar("soccerjamsource_version", SOCCERJAMSOURCE_VERSION, "SoccerJam: Source Version", 
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	InitPartSystem();

	RegisterPart("BALL"); // Ball
	RegisterPart("BAR"); // Ball AutoRespawn
	RegisterPart("BBM"); // Ball Bounce Multiplier
	RegisterPart("BBS"); // Ball Bounce Sound
	RegisterPart("BE"); // Ball Explosion
	RegisterPart("BK"); // Ball Kick
	RegisterPart("BR"); // Ball Receiving
	RegisterPart("BT"); // Ball Trail
	RegisterPart("CB"); // Curve Ball
	RegisterPart("CM"); // Config Manager
	RegisterPart("DSRM"); // Disarm
	RegisterPart("DZ"); // Death Zone
	RegisterPart("FFI"); // Frags For Interception
	RegisterPart("GA"); // Goal Assist
	RegisterPart("GD"); // Goal Distance
	RegisterPart("GOAL"); // Goal
	RegisterPart("GSM"); // Game Specific Manager
	RegisterPart("HLF"); // Half
	RegisterPart("HLP"); // Help
	RegisterPart("HLTH"); // Health
	RegisterPart("KAS"); // KA_Soccer maps support
	RegisterPart("LJ"); // Long Jump
	RegisterPart("MM"); // Model Manager
	RegisterPart("MSM"); // Match Stats Manager
	RegisterPart("MTCH"); // Match
	RegisterPart("MVP"); // MVP Stars
	RegisterPart("NDAG"); // No Damage After Goal
	RegisterPart("NFFK"); // No Frags For Kill
	RegisterPart("NOFF"); // No Friendly Fire
	RegisterPart("NRD"); // No Round Draw
	RegisterPart("NREM"); // No Round End Message
	RegisterPart("PAC"); // Player Attack Check
	RegisterPart("PR"); // Player Respawn
	RegisterPart("RBAH"); // Remove Bomb And Hostages
	RegisterPart("RS"); // Reward System
	RegisterPart("RTE"); // Round Time Extend
	RegisterPart("RWOS"); // Remove Weapons On Spawn
	RegisterPart("SG"); // Speed and Gravity
	RegisterPart("SJB"); // SJ Builder
	RegisterPart("SJE"); // SJ Entities
	RegisterPart("SJT"); // SJ Timer	
	RegisterPart("SM"); // Sound Manager
	RegisterPart("SSP"); // Swap Spawn Points
	RegisterPart("TBHD"); // Teleport Ball on Holder Death
	RegisterPart("TEST"); // Sound Manager
	RegisterPart("TM"); // Team Models
	RegisterPart("TRB"); // Turbo
	RegisterPart("TU"); // Team Upgrade
	RegisterPart("UM"); // Upgrades
	RegisterPart("WM"); // Welcome Message

	InitParts();
	
	LoadTranslations("soccerjam.phrases");
}

public OnMapStart()
{
	FireOnMapStart();
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if (reason == CSRoundEnd_GameStart)
	{
		SJ_ResetTeamScores();
		return Plugin_Continue;
	}
	return FireOnTerminateRound(delay, reason);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	FireOnEntityCreated(entity, classname);
}

public void OnClientDisconnect(int client)
{
	FireOnClientDisconnect(client);
	if (IsClientInGame(client))
	{
		ClearClient(client);
		if (client == g_BallHolder)
		{
			TeleportBallToClient(client);
		}
		if (client == g_BallOwner
			&& !g_Goal)
		{
			ClearBall();
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	return FireOnPlayerRunCmd(client, buttons);
}
