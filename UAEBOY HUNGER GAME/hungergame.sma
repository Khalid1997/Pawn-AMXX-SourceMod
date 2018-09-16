#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <hamsandwich>

new const CSTEAMS_OFFSET = 114

new g_iMaxPlayers

#define IsPlayer(%1) (1 <= %1 <= g_iMaxPlayers)

public plugin_init()
{
	register_plugin("Hunger Game", "1.0", "Khalid :)")
	
	RegisterHam(Ham_Killed, "player", "fw_Killed_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Pre", 0)
	
	MakeBots()
	RemoveMapObjectives()
	
	g_iMaxPlayers = get_maxplayers()
}

stock RemoveMapObjectives()
{
	new const szMapObjectives[][] =
	{
		"func_bomb_target",
		"info_bomb_target",
		//"hostage_entity",
		"monster_scientist",
		"func_hostage_rescue",
		"info_hostage_rescue",
		"info_vip_start",
		"func_vip_safetyzone",
		"func_escapezone",
		"armoury_entity",
		//"info_map_parameters",
		"player_weaponstrip",
		"game_player_equip",
		"func_buyzone"
	}
	
	new iEnt
	for(new i; i < sizeof(szMapObjectives); i++)
	{
		iEnt = -1
		while( ( iEnt = find_ent_by_class(iEnt, szMapObjectives[i]) ) )
		{
			remove_entity(iEnt)
		}
	}
}

// Prevent round end
stock MakeBots()
{
	new iBotCT, iBotT
	
	iBotCT = create_entity("info_target")
	
	new szServerIp[25]; get_user_ip(0, szServerIp, charsmax(szServerIp), 1)
	
	if(is_valid_ent(iBotCT))
	{
		set_pev(iBotCT, pev_classname, "player")
		
		set_pev(iBotCT, pev_flags, pev(iBotCT, pev_flags) | FL_FAKECLIENT)
		
		dllfunc(DLLFunc_ClientConnect, iBotCT, szServerIp, "")
		dllfunc(DLLFunc_ClientPutInServer, iBotCT)
		
		cs_set_user_team(iBotCT, CS_TEAM_CT)
		
		ExecuteHam(Ham_Spawn, iBotCT)
		
		entity_set_origin(iBotCT, Float:{ 8092.0, 8092.0, 8092.0 } )
		set_pev(iBotCT, pev_solid, SOLID_NOT)
	}
	
	iBotT = create_entity("info_target")
	if(is_valid_ent(iBotT))
	{
		set_pev(iBotT, pev_classname, "player")
		
		set_pev(iBotT, pev_flags, pev(iBotT, pev_flags) | FL_FAKECLIENT)
		
		dllfunc(DLLFunc_ClientConnect, iBotT, szServerIp, "")
		dllfunc(DLLFunc_ClientPutInServer, iBotT)
		
		cs_set_user_team(iBotT, CS_TEAM_T)
		
		ExecuteHam(Ham_Spawn, iBotT)
		
		entity_set_origin(iBotT, Float:{ 8092.0, 8092.0, 8092.0 } )
		set_pev(iBotT, pev_solid, SOLID_NOT)
	}
}

public fw_TraceAttack_Pre(id, iAttacker, flDamage, vDirection, iTr, iDamageBits)
{
	if(!IsPlayer(id))
	{
		return;
	}
	
	new iNewTeam
	if( (iNewTeam = get_pdata_int(iAttacker, CSTEAMS_OFFSET) ) == get_pdata_int(id, CSTEAMS_OFFSET))
	{
		set_pdata_int(id, iNewTeam == 2 ? (iNewTeam = 1) : (iNewTeam = 2), CSTEAMS_OFFSET)
		ExecuteHamB(Ham_TraceAttack, id, iAttacker, flDamage, vDirection, iTr, iDamageBits)
		set_pdata_int(id, iNewTeam, CSTEAMS_OFFSET)
	}
}

public fw_Killed(id, iAttacker, iShouldGib)
{
	static iPlayers[32], iNum
	arrayset(iPlayers, 0, 32)
	
	get_players(iPlayers, iNum, "ach")
	
	if(iNum == 1)
	{
		static szName[32]
		get_user_name(iPlayers[0], szName, charsmax(szName))
		
		client_print(id, print_chat, "[HUNGER GAME] Player %s WON!", szName)
		
		for(new i; i < iNum ; i++)
		{
			user_silentkill(id)
		}
	}
}
