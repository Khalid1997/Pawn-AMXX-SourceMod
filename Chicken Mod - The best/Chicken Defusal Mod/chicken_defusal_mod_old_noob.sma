#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <fakemeta>
#include <engine>
#include <cstrike>

#define PLUGIN "Chicken Defusal mod"
#define VERSION "1.0"
#define AUTHOR "Khalid :)"

new const g_szC4Sounds[][] = {
	
	"weapons/c4_beep1.wav",
	"weapons/c4_beep2.wav",
	"weapons/c4_beep3.wav",
	"weapons/c4_beep4.wav",
	"weapons/c4_beep5.wav"
};

#define IsPlayer(%1) (1 <= %1 <= g_iMaxPlayers)

// Cvars
new g_pRoundTime, g_pMinPlayers

// Vars
new g_iTimer = 999, g_iChicken, g_iMaxPlayers, g_iExplodeTime, g_iExplodeSprite
new g_szOldModel[40]

// --------  Offsets  ---------
const m_iMenu = 205

const m_iId = 43
#define CBASE_LINUX_DIFFERENCE 4

new const CHICKEN_MODEL[] = "chicken"

stock set_user_model(id, const model[])
{
	get_user_info(id, "model", g_szOldModel, charsmax(g_szOldModel))
	set_user_info(id, "model", model)
}

stock get_user_model(id, model[], len)
	get_user_info(id, "model", model, len)
	
stock reset_user_model(id)
{
	set_user_info(id, "model", g_szOldModel)
}

public plugin_precache()
{
	g_iExplodeSprite = precache_model("sprites/eexplo.spr");
	
	new szFile[60]
	formatex(szFile, charsmax(szFile), "models/player/%s/%s.mdl", CHICKEN_MODEL, CHICKEN_MODEL)
	
	precache_model("models/rpgrocket.mdl")
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("RoundTime", "eRoundTime", "a")
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")
	
	register_logevent("ChooseChicken", 2, "1=Round_End")
	
	register_clcmd("say /or", "Origin")
	
	g_pRoundTime = get_cvar_pointer("mp_roundtime")
	g_pMinPlayers = register_cvar("chickdefuse_min_players", "2")

		
	RegisterHam(Ham_Spawn, "player", "Fwd_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "Fwd_Killed")
	//RegisterHam(Ham_AddPlayerItem, "player", "Fwd_AddItem", 0)
	
	register_think("c4_bomb", "Fwd_C4Think")
	register_think("c4_sprite", "Fwd_C4SpriteThink")
	
	register_forward(FM_Touch, "Fwd_Touch", 1)
	register_forward(FM_ClientUserInfoChanged, "Fwd_ClientUserInfoChanged")
	
	g_iMaxPlayers = get_maxplayers()
	
	new iEnt = create_entity("info_target")
	
	if(!pev_valid(iEnt))
		set_fail_state("Failed to create think bot")
		
	set_pev(iEnt, pev_classname, "think_bot")
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	
	register_think("think_bot", "Fwd_BotThink")
}

public Fwd_ClientUserInfoChanged(id)
{	
	if (id == g_iChicken)
	{
		// Get current model
		static currentmodel[32]
		get_user_model(id, currentmodel, charsmax(currentmodel))
		
		// If they're different, set model again
		if (!equal(currentmodel, g_szOldModel))
			set_user_model(id, CHICKEN_MODEL)
	}
}

public client_disconnect(id)
{
	if(id == g_iChicken)
	{
		Remove_Entities()
	}
}

public Fwd_Killed(iVictim, iAttacker, shouldgib)
{
	if(iVictim == g_iChicken)
	{
		Remove_Entities()
	}
}

Remove_Entities()
{
	remove_entity(find_ent_by_class(-1, "c4_sprite"))
	remove_entity(find_ent_by_class(-1, "c4_bomb"))

public Fwd_BotThink(iEnt)
{
	new iTerr, iCT
	get_players_count(iTerr, iCT)
	
	if(!iTerr && iCT && iCT >= get_pcvar_num(g_pMinPlayers))
	{
		ChooseChicken()
		server_cmd("sv_restart 1")
	}
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 5.0)
}

public eRoundTime()
{
	server_print("g_iTimer = %d", g_iTimer)
	g_iTimer = read_data(1)
}
	
public eNewRound()
	g_iExplodeTime = get_pcvar_num(g_pRoundTime) * 60
	
public ChooseChicken()
{
	if(is_user_connected(g_iChicken) && g_iChicken)
	{
		set_view(g_iChicken, CAMERA_NONE)
		//set_user_info(g_iChicken, "model", g_szOldModel)
		
		cs_reset_user_model(g_iChicken)
		cs_set_user_team(g_iChicken, CS_TEAM_CT)
		
		remove_entity(find_ent_by_class(-1, "c4_sprite"))
		remove_entity(find_ent_by_class(-1, "c4_bomb"))
	}
	
	new iOldChicken = g_iChicken
	new iPlayers[32], iNum
	
	get_players(iPlayers, iNum, "che", "CT")
	
	g_iChicken = iPlayers[random(iNum)]
	
	while(g_iChicken == iOldChicken)
		g_iChicken = iPlayers[random(iNum)]
		
	cs_set_user_team(g_iChicken, CS_TEAM_T)
}
	
public Fwd_Touch(iToucher, iTouched)
{
	if(!IsPlayer(iToucher) || !IsPlayer(iTouched))
		return;
		
	if(get_user_team(iToucher) == 2 && iTouched == g_iChicken)
		set_pev(iTouched, pev_flags, (pev(iTouched, pev_flags) | FL_FROZEN))
}

public Origin(id)
{
	new Float:vOrigin[3]

	pev(id, pev_origin, vOrigin)
	client_print(id, print_chat, "Seocond : %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2])
}
	
public Fwd_Spawn(id)
{	
	if(!is_user_alive(id))
		return;
		
	if(id != g_iChicken)
	{
		strip_user_weapons(id)
		return;
	}
	
	strip_user_weapons(id)
	
	//get_user_info(id, "model", g_szOldModel, charsmax(g_szOldModel))
	cs_set_user_model(id, CHICKEN_MODEL)
	
	set_view(id, CAMERA_3RDPERSON)
	
	set_user_maxspeed(id, 1.1)
	
	new iEnt = create_entity("info_target")
	server_print("Created c4 bomb entity")
	if(!pev_valid(iEnt))
		set_fail_state("Could not create c4 entity")
	
	// Spawn C4 model on chicken's head :)
	set_pev(iEnt, pev_classname, "c4_bomb")
	set_pev(iEnt, pev_takedamage, DAMAGE_NO)
	set_pev(iEnt, pev_health, 1.0)
	
	set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
	
	set_pev(iEnt, pev_aiment, id);
	set_pev(iEnt, pev_owner, id)
	set_pev(iEnt, pev_solid, SOLID_BBOX);
	engfunc(EngFunc_SetModel, iEnt, "models/w_c4.mdl");
	//dllfunc(DLLFunc_Spawn, iEnt)

	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)

	new iSprite = create_entity("info_target")
	
	if(!pev_valid(iSprite))
		set_fail_state("Could not create c4 sprite")
	
	set_pev(iSprite, pev_classname, "c4_sprite");
	set_pev(iSprite, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(iSprite, pev_aiment, iEnt);
	set_pev(iSprite, pev_owner, iEnt)
	
	set_pev(iSprite, pev_rendermode, 5);
	set_pev(iSprite, pev_renderamt, 200.0);
	set_pev(iSprite, pev_scale, 0.3);
	
	engfunc(EngFunc_SetModel, iSprite, "sprites/ledglow.spr");
	
	set_pev(iSprite, pev_iuser1, 3);
	set_pev(iSprite, pev_nextthink, get_gametime() + 0.1);
}

public Fwd_C4Think(iEnt)
{
	
	if( g_iTimer <= 0 )
	{
		new Float:iOrigin[3]; pev(iEnt, pev_origin, iOrigin, 3)
		engfunc(EngFunc_RemoveEntity, iEnt)
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
		write_byte(TE_EXPLOSION);
		//write_coord(iOrigin[0])
		//write_coord(iOrigin[1])     
		//write_coord(iOrigin[2])
		engfunc(EngFunc_WriteCoord, iOrigin[0])
		engfunc(EngFunc_WriteCoord, iOrigin[1])
		engfunc(EngFunc_WriteCoord, iOrigin[2])
		write_short(g_iExplodeSprite);
		write_byte(80);
		write_byte(15); 
		write_byte(0); 
		message_end();
		
		new iPlayers[32], iNum, iPlayer, Float:flHealth
		get_players(iPlayers, iNum, "bch")
		
		for(new i; i < iNum; i++)
		{
			iPlayer = iPlayers[i];
			pev(iPlayer, pev_health, flHealth)
			ExecuteHam(Ham_TakeDamage, iPlayer, iPlayer, iPlayer, flHealth + 1.0, any:DMG_BLAST);
		}
	}
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
}

public Fwd_C4SpritThink(iEnt)
{	
	switch(pev(iEnt, pev_iuser1))
	{
		case 3: { set_pev(iEnt, pev_renderamt, 100.0); }
		case 2: { set_pev(iEnt, pev_renderamt, 50.0); }
		case 1: { set_pev(iEnt, pev_renderamt, 10.0); }
		case 0:
		{
			engfunc(EngFunc_RemoveEntity, iEnt);
			return;
		}
	}
	
	if(0 <= g_iExplodeTime <= g_iTimer / 5)
		emit_sound(iEnt, CHAN_AUTO, g_szC4Sounds[4], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		
	else if(g_iExplodeTime / 5 < g_iTimer <= g_iExplodeTime / 4)
		emit_sound(iEnt, CHAN_AUTO, g_szC4Sounds[3], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
			
	else if(g_iExplodeTime / 4 < g_iTimer <= g_iExplodeTime / 3)
		emit_sound(iEnt, CHAN_AUTO, g_szC4Sounds[2], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		
	else if(g_iExplodeTime / 3 < g_iTimer <= g_iExplodeTime / 2)
		emit_sound(iEnt, CHAN_AUTO, g_szC4Sounds[1], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
			
	else if(g_iExplodeTime / 2 < g_iTimer <= g_iExplodeTime)
		emit_sound(iEnt, CHAN_AUTO, g_szC4Sounds[0], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		
	set_pev(iEnt, pev_iuser1, pev(iEnt, pev_iuser1) - 1);
	set_pev(iEnt, pev_nextthink, get_gametime() + 1.5);
}

get_players_count(&iTerr, &iCT)
{
	static iDump[32]
	get_players(iDump, iTerr, "che", "TERRORIST")
	get_players(iDump, iCT, "che", "CT")
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
