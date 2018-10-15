#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>

#pragma semicolon 1

#define UPDATE_TIME 1.0
#define MIN_DIS 8092.0

new const g_szThinkEntClassName[] = "ThinkingEnt";
new const PREFIX[] = "[FLOWER]";

// Vars + CVars
new g_pCost, g_pTime;
new gMsgIdHostageK, gMsgIdHostagePos;

new gSpotter;
#define HasSpotter(%1) ( gSpotter & (1<<%1) )
#define GiveSpotter(%1) ( gSpotter |= (1<<%1) )
#define TakeSpotter(%1) ( gSpotter &= ~(1<<%1) )

#define TASKID_REMOVESPOTTER 15161
stock Print(id, szMsg[], any:...) 
{
	new szPrintMsg[191], iLen;
	iLen = formatex(szPrintMsg, charsmax(szPrintMsg), "%s ", PREFIX);
	vformat(szPrintMsg[iLen], charsmax(szPrintMsg) - iLen, szMsg, 3);
	
	client_print(id, print_chat, szPrintMsg);
}

public plugin_init()
{
	register_plugin("Flower Spotter", "1.0", "Khalid :)");
	
	if(is_plugin_loaded("flower_main.amxx", true) == -1)
	{
		set_fail_state("Flower mod not running");
		return;
	}
	
	if(!CreateThinkingEnt())
	{
		set_fail_state("Couldn't create thinking entity");
		return;
	}
	
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0");
	
	register_concmd("amx_give_spotter", "CmdGiveSpotter", ADMIN_RESERVATION, "<player> - Give a player a flower spotter");
	register_clcmd("say /spotter", "CmdSpotter");
	
	g_pCost = register_cvar("fs_cost", "16000");
	g_pTime = register_cvar("fs_time", "10.0");
	
	gMsgIdHostageK = get_user_msgid("HostageK");
	gMsgIdHostagePos = get_user_msgid("HostagePos");
		
	set_task(220.0, "Adver", .flags = "b");
}

public Adver()
{
	Print(0, "Type /spotter in chat to buy the flower spotter");
}

public CmdGiveSpotter(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
	{
		return PLUGIN_HANDLED;
	}
	
	new szPlayer[32], iPlayer;
	read_argv(1, szPlayer, 31);
	
	if(! ( iPlayer = cmd_target(id, szPlayer, CMDTARGET_ALLOW_SELF) ) )
	{
		return PLUGIN_HANDLED;
	}
	
	if(HasSpotter(iPlayer))
	{
		console_print(id, "Player already has flower spotter!");
		return PLUGIN_HANDLED;
	}
	
	GiveToPlayerFlowerSpotter(iPlayer);
	
	get_user_name(iPlayer, szPlayer, 31);
	new szAdminName[32]; get_user_name(id, szAdminName, 31);
	Print(0, "ADMIN %s gave player %s the flower spotter for this round!", szAdminName, szPlayer);
	
	return PLUGIN_HANDLED;
}

public CmdSpotter(id)
{
	if(!CanBuy(id))
	{
		return;
	}
	
	Print(id, "You have bought the flower spotter");
	Print(id, "You can now see near flowers in radar!");
	Print(id, "It will only last for %d seconds!", floatround(get_pcvar_float(g_pTime)));
	
	new szName[32]; get_user_name(id, szName, charsmax(szName));
	
	set_hudmessage(0, 255, 0, -1.0, 0.39, 1, 6.0, 7.5, 0.1, 0.1, -1);
	show_hudmessage(0, "Watch out flowers!^n%s has bought the flower spotter!", szName);
	
	GiveToPlayerFlowerSpotter(id);
}

stock GiveToPlayerFlowerSpotter(id)
{
	GiveSpotter(id);
	set_task(get_pcvar_float(g_pTime), "RemoveSpotter", TASKID_REMOVESPOTTER + id);
}

public RemoveSpotter(id)
{
	id -= TASKID_REMOVESPOTTER;
	
	if(!is_user_alive(id))
	{
		return;
	}
	
	if(!HasSpotter(id))
	{
		return;
	}
	
	TakeSpotter(id);
	Print(id, "You can no longer see the flowers in radar");
}

stock bool:CanBuy(id)
{
	if(!is_user_alive(id))
	{
		Print(id, "You must be alive to buy flower spotter!");
		return false;
	}
	
	if( cs_get_user_team(id) == CS_TEAM_T )
	{
		Print(id, "Only gardeners can buy the flower spotter!");
		return false;
	}
	
	static iMoney, iCost;
	
	if( ( iMoney = cs_get_user_money(id) ) < ( iCost = get_pcvar_num(g_pCost) ) )
	{
		Print(id, "You don't have enought money to buy the flower spotter! (Missing %d$)", iCost - iMoney);
		return false;
	}
	
	if(HasSpotter(id))
	{
		Print(id, "You already have a flower Spotter");
		return false;
	}
	
	cs_set_user_money(id, iMoney - iCost, 1);
	return true;
}	

stock CreateThinkingEnt()
{
	new iEnt = create_entity("info_target");
	
	if(is_valid_ent(iEnt))
	{
		set_pev(iEnt, pev_classname, g_szThinkEntClassName);
		set_pev(iEnt, pev_solid, SOLID_NOT);
		set_pev(iEnt, pev_origin, Float:{ 8092.0, 8092.0, 8092.0 });
		
		set_pev(iEnt, pev_nextthink, get_gametime() + UPDATE_TIME);
		
		register_think(g_szThinkEntClassName, "ThinkEntThink");
		
		return true;
	}
	
	return false;
}

public ThinkEntThink(iEnt)
{
	set_pev(iEnt, pev_nextthink, get_gametime() + UPDATE_TIME);
	
	static iPlayers[32], iNum, iPlayer;
	static iTerrPlayers[32], iTerrNum, iTerrPlayer;
	get_players(iPlayers, iNum, "ahe", "CT");
	get_players(iTerrPlayers, iTerrNum, "ahe", "TERRORIST");
	
	for(new i, b; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		if(!HasSpotter(iPlayer))
		{
			continue;
		}
		
		for(b = 0; b < iTerrNum; b++)
		{
			iTerrPlayer = iTerrPlayers[b];
			if(entity_range(iPlayer, iTerrPlayer) > MIN_DIS)
			{
				continue;
			}

			ShowOnRadar(iPlayer, iTerrPlayer);
		}
	}
}

public eNewRound()
{
	gSpotter = 0;
}

// Credits to other guy
stock ShowOnRadar(id, iShowPlayer) 
{
	static iOrigin[3]; get_user_origin(iShowPlayer, iOrigin);
	
	message_begin(MSG_ONE_UNRELIABLE, gMsgIdHostagePos, .player=id);
	write_byte(id);
	write_byte(iShowPlayer);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE, gMsgIdHostageK, .player=id);
	write_byte(iShowPlayer);
	message_end();
}