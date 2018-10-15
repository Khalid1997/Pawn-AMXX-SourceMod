#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <engine>

#define PLUGIN "Simple zombie mod"
#define VERSION "1.0"
#define AUTHOR "Khalid"

#define MINIMUM_PLAYERS 2

// Save our players zombie status
// 0 = Not zombie
// 1 = Zombie but still not spawned as zombie (First spawn)
// 2 = Zombie and spawned as zombie.
new g_iZombie[33]

// save the value of get_maxplayers here instead of
// calling get_maxplayers each time in loop
// Read loop stuff in wiki to understand
new g_iMaxPlayers

public plugin_precache()
{
	// Precache it
	// It means add it to list of downloads and let counter strike use it.
	precache_model("models/player/zombie/zombie.mdl");
	
	precache_model("models/rpgrocket.mdl");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Register players spawn
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1);
	
	// Register attacks (0 means pre which means before it happens)
	// Don't ask me what is Ham_TraceAttack 3ashan magdr afhmk eyaha xd
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack", 0);
	
	//RegisterHam(Ham_Killed, "player", "fw_Killed", 1);
	
	// Register ((NEW))Round (Not roundstart)
	// This is called even before Spawns (Ham_Spawn)
	register_event("HLTV", "eHLTV", "a", "1=0", "2=0");
	
	g_iMaxPlayers = get_maxplayers()
	
	register_clcmd("say /cam", "cam");
}

public cam(id)
{
	static iView[33]
	set_view(id, iView[id] ? CAMERA_NONE : CAMERA_3RDPERSON);
}

new g_iBot

public client_putinserver(id)
{
	// Reset everything.
	g_iZombie[id] = 0
	
	if(is_user_bot(id) && !g_iBot)
	{
		g_iBot = 1
		set_task(1.0, "RegBots", id);
	}
}

public RegBots(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack", 0);
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn", 1);
	//RegisterHamFromEntity(Ham_Killed, id, "fw_Killed", 1);
}

public eHLTV()
{	
	new iPlayers[32], iNum, iZombieId;
	get_players(iPlayers, iNum);
	
	for(new i; i < g_iMaxPlayers; i++)
	{
		if(is_user_connected(i))
		{
			if(g_iZombie[i] == 2)
			{
				cs_reset_user_model(i);
			}
		}
	}
	
	// Let's get all connected players
	arrayset(g_iZombie, 33, 0);
	
	// There is no connected players
	if(!iNum)
	{
		return;
	}
	
	/*
	// Check if players num is not enough to do everything.
	if(iNum < MINIMUM_PLAYERS)
	{
		return;
	}*/
	
	for(new i; i < iNum; i++)
	{
		// Transfer all to CT's
		cs_set_user_team(iPlayers[i], CS_TEAM_CT);
	}
	
	// Get our random zombie
	iZombieId = iPlayers[random(iNum)];
	
	// Put it to step 1 (Just choose zombie)
	// The task will be made in spawn
	// Note that HLTV comes before SPAWNS
	g_iZombie[iZombieId] = 1
}

public fw_Killed(id)
{
	if(g_iZombie[id] == 2)
	{
		server_print("Zombie");
		cs_reset_user_model(id);
	}
}

public fw_Spawn(id)
{
	// Check if player is alive and connected
	// This is because when a player connects to the server
	// Ham_Spawn is called and if we don't put this, errors will come
	// because the player is not even alive.
	if(!is_user_alive(id))
	{
		return;
	}
	
	// Player is not a zombie
	if(!g_iZombie[id])
	{
		// if he is not a zombie, exit the code and do nothing
		return;
	}
	
	switch(g_iZombie[id])
	{
		// g_iZombie[id] == 1
		case 1:
		{
			// Change it to 2 to let the plugin know that the next spawn
			// Of this player will make him a zombie and do stuff in case 2:
			g_iZombie[id] = 2
			set_task(5.0, "SpawnZombieAgain", id);
		}
		
		// g_iZombie[id] == 2
		case 2:
		{
			// Do on him zombie stuff
			DoZombieStuff(id);
		}
	}
}

DoZombieStuff(id)
{
	// Take all his weapons
	strip_user_weapons(id);
		
	// Clearly understandable
	give_item(id, "weapon_knife");
	cs_set_user_model(id, "zombie");
	
	client_print(id, print_chat, "[ZOMBIE] You are now a zombie.");
}

public SpawnZombieAgain(id)
{
	// He is not connected? 
	// (prevent crash or errors)
	if(!is_user_connected(id))
	{
		return;
	}
	
	// Transfer to terrorists
	cs_set_user_team(id, CS_TEAM_T);
	
	// Spawn The zombie again.
	ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public fw_TraceAttack(iVictimId, iAttackerId, Float:flDamage, Float:vDirection[3], iTrHandle, iDamageBits )
{
	// Attacker and victim are not on the same team
	if(cs_get_user_team(iAttackerId) != cs_get_user_team(iVictimId))
	{
		// Check if the attacker is a zombie
		if(g_iZombie[iAttackerId] == 2)
		{
			// Check if victim is not zombie
			if(!g_iZombie[iVictimId])
			{
				// Get alive CTS count
				// then check if only 1 is alive
				if(CountTeams(CS_TEAM_CT) == 1)
				{
					// Kill him to end the round.
					// Let's kill him by making him take the damage
					// as his own health
					// I mean damage = all of his hp
					
					// get a float health
					// we did not use get_user_health because it gives an integer.
					new Float:flHealth
					pev(iVictimId, pev_health, flHealth)
					
					// Trteeb al flDamage fl public fw_traceattack(iVictim (1), iAttacker (2), flDamage (3), ...);
					SetHamParamFloat(3, flHealth);
					return HAM_IGNORED;
				}
				
				// Just in case (I really don't know why xd)
				g_iZombie[iVictimId] = 2;
				
				cs_set_user_team(iVictimId, CS_TEAM_T);
				// Do zombie stuff on him (change model, team, bla)
				DoZombieStuff(iVictimId);
				
				// Prevent attack
				set_tr2(iTrHandle, TR_flFraction, 1.0);
				return HAM_SUPERCEDE;
			}
		
		}
	}
	
	// if they are in the same team
	// or they are NOT in the same team but the attacker is not zombie
	// or they they are NOT in the same team but the VICTIM is ZOMBIE
	// Don't do anything and let cs do the rest. (block attack, allow attack, bla)
	return HAM_IGNORED
}

stock CountTeams(CsTeams:iTeam = CS_TEAM_CT)
{
	static iCount, i;
	
	// Reset stuff and do loop
	for(i = 0, iCount = 0; i < g_iMaxPlayers; i++)
	{
		// Is the player connected and alive
		// If not, continue to the next player?
		// Else, continue to the code after this ( if() )
		if(!is_user_alive(i))
		{
			continue;
		}
		
		// The player is in the team that we want to count
		// how many players is in?
		if(cs_get_user_team(i) == iTeam)
		{
			// if yes, increase iCount by 1
			iCount++;
		}
	}
	
	// Return the count to cache it in a variable or directly check it.
	return iCount;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
