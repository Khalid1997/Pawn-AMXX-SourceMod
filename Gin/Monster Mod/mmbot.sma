// Never do you have to deal with round ending again!
#include <amxmodx>
#include <fakemeta>
#include <cstrike>

new g_szBotName[32] = "MonsterMod BOT"
new bot_id

public plugin_init() 
{
	register_plugin("Fake TeamBot", "1.0", "OneEyed")
	register_event("HLTV","StartRound","a","1=0","2=0")
	createBots()
}

public StartRound()
{
	if(bot_id)
	{
		set_pev(bot_id, pev_effects, (pev(bot_id, pev_effects) | 128) ) //set invisible
		set_pev(bot_id, pev_solid, 0) 		//Not Solid
	}
}

public createBots()
{
	bot_id = engfunc(EngFunc_CreateFakeClient, g_szBotName)
	
	new ptr[128]
	dllfunc(DLLFunc_ClientConnect, bot_id, g_szBotName, "127.0.0.1", ptr )
	dllfunc(DLLFunc_ClientPutInServer, bot_id);
	cs_set_user_team(bot_id, CS_TEAM_CT, CS_CT_URBAN)
}
