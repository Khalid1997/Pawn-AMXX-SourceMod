#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

#pragma semicolon 1

#define PUG_TASK_VOTE 	1337
#define PUG_TASK_AUTO 	1338

#define PUG_MAX_PLAYERS 	33
#define PUG_MOD_MINPLAYERS 	5
#define PUG_CAPTAIN_MINPLAYERS 	6

new PUG_szHead[] = "^4[GESG PUG]^1";

public PUG_iStage;
new bool:PUG_bReady[PUG_MAX_PLAYERS];
new bool:PUG_bVoted[PUG_MAX_PLAYERS];
new bool:PUG_bInRound;

new PUG_iHits[PUG_MAX_PLAYERS][PUG_MAX_PLAYERS];
new PUG_iDamage[PUG_MAX_PLAYERS][PUG_MAX_PLAYERS];

new const PUG_szTeamNames[CsTeams][] =
{
	"Unassigned",
	"Terrorists",
	"Counter-Terrorists",
	"Spectator"
};

new const PUG_szTeams[CsTeams][] =
{
	"UNASGDs",
	"TRs",
	"CTs",
	"SPECs"
};

new PUG_iScores[CsTeams];
new PUG_iRounds[3];

#define PUG_isValidTeam(%0) 	(CS_TEAM_T <= cs_get_user_team(%0) <= CS_TEAM_CT)

enum _:PUG_STAGES_CONST
{
	PUG_STAGE_READY = 0,
	PUG_STAGE_START,
	PUG_STAGE_FIRSTHALF,
	PUG_STAGE_INTERMISSION,
	PUG_STAGE_SECONDHALF,
	PUG_STAGE_OVERTIME,
	PUG_STAGE_END
};

new const PUG_szStage[PUG_STAGES_CONST][] =
{
	"Pregame",
	"Voting",
	"First Half",
	"Intermission",
	"Second Half",
	"Overtime",
	"Finished"
};

new PUG_MinPlayers;
new PUG_MaxPlayers;
new PUG_VoteMap;
new PUG_VoteDelay;
new PUG_SwitchDelay;
new PUG_MaxRounds;
new PUG_OTRounds;
new PUG_AllowSpec;
new PUG_AllowHLTV;
new PUG_Reconnect;
new PUG_TeamMoney;
new PUG_NoSuicide;
new PUG_AllowVoteCmds;
new PUG_HelpFile;

new PUG_ReadyConfig;
new PUG_StartConfig;
new PUG_FirstConfig;
new PUG_IntermissionConfig;
new PUG_SecondConfig;
new PUG_OvertimeConfig;
new PUG_EndConfig;

new PUG_sv_restart;
new PUG_sv_visiblemaxplayers;
new PUG_mp_startmoney;
new PUG_mapcyclefile;

enum
{
	PUG_MENU_NONE = 0,
	PUG_MENU_MAP,
	PUG_MENU_TEAMS,
	PUG_MENU_CAPTAINS,
	PUG_MENU_CFG
};

new PUG_iMenuStage;

new PUG_iMenuMap;
new PUG_iMenuTeams;
new PUG_iMenuCfg;

#define PUG_MAX_MAPS 32

new PUG_iMapVotes[PUG_MAX_MAPS];
new PUG_szMapNames[PUG_MAX_MAPS][32];
new PUG_iMapCount;

new bool:PUG_bTeams;

enum _:PUG_SORT_TYPE
{
	PUG_SORT_AUTO = 0,
	PUG_SORT_NONE,
	PUG_SORT_CAPTAINS
};

new const PUG_szTeamTypes[PUG_SORT_TYPE][] =
{
	"Random",
	"Not Sorted",
	"Captains"
};

new PUG_iTeamVotes[PUG_SORT_TYPE];

new PUG_iCaptain[2];

enum _:PUG_CFG_FILE
{
	PUG_CFG_CAL = 0,
	PUG_CFG_CEVO
};

new const PUG_szConfigTypes[PUG_CFG_FILE][] =
{
	"CAL (15 Rounds, 1:45 min, $800)",
	"CEVO (15 Rounds, 2:00 min, $800)"
};

new PUG_iConfigVotes[PUG_CFG_FILE];

new Trie:PUG_tRetry;

enum
{
	PUG_SLOT_PRIMARY = 1,
	PUG_SLOT_SECONDARY,
	PUG_SLOT_KNIFE,
	PUG_SLOT_GRENADE,
	PUG_SLOT_C4
};

new const PUG_iWeaponSlots[] =
{
	0,
	2,	//CSW_P228
	0,
	1,	//CSW_SCOUT
	4,	//CSW_HEGRENADE
	1,	//CSW_XM1014
	5,	//CSW_C4
	1,	//CSW_MAC10
	1,	//CSW_AUG
	4,	//CSW_SMOKEGRENADE
	2,	//CSW_ELITE
	2,	//CSW_FIVESEVEN
	1,	//CSW_UMP45
	1,	//CSW_SG550
	1,	//CSW_GALIL
	1,	//CSW_FAMAS
	2,	//CSW_USP
	2,	//CSW_GLOCK18
	1,	//CSW_AWP
	1,	//CSW_MP5NAVY
	1,	//CSW_M249
	1,	//CSW_M3
	1,	//CSW_M4A1
	1,	//CSW_TMP
	1,	//CSW_G3SG1
	4,	//CSW_FLASHBANG
	2,	//CSW_DEAGLE
	1,	//CSW_SG552
	1,	//CSW_AK47
	3,	//CSW_KNIFE
	1	//CSW_P90
};

new const PUG_iMaxBPAmmo[] =
{
	0,
	52,	//CSW_P228
	0,
	90,	//CSW_SCOUT
	1,	//CSW_HEGRENADE
	32,	//CSW_XM1014
	1,	//CSW_C4
	100,	//CSW_MAC10
	90,	//CSW_AUG
	1,	//CSW_SMOKEGRENADE
	120,	//CSW_ELITE
	100,	//CSW_FIVESEVEN
	100,	//CSW_UMP45
	90,	//CSW_SG550
	90,	//CSW_GALIL
	90,	//CSW_FAMAS
	100,	//CSW_USP
	120,	//CSW_GLOCK18
	30,	//CSW_AWP
	120,	//CSW_MP5NAVY
	200,	//CSW_M249
	32,	//CSW_M3
	90,	//CSW_M4A1
	120,	//CSW_TMP
	90,	//CSW_G3SG1
	2,	//CSW_FLASHBANG
	35,	//CSW_DEAGLE
	90,	//CSW_SG552
	90,	//CSW_AK47
	0,	//CSW_KNIFE
	100	//CSW_P90
};

new const PUG_szRestrictWeapons[][] =
{
	"shield",
	"flash",
	"hegren",
	"sgren",
	"primammo",
	"secammo",
	"buyammo1",
	"buyammo2"
};

new const PUG_szVoteCommands[][] =
{
	"buy",
	"buyequip",
	"radio1",
	"radio2",
	"radio3",
	"chooseteam"
};

new Trie:g_hTrie;

public plugin_init()
{
	register_plugin("Pug Mod (XT)",AMXX_VERSION_STR,"SmileY");

	register_dictionary("CsPug.txt");
	
	PUG_MinPlayers 		= register_cvar("pug_minplayers","10");
	PUG_MaxPlayers 		= register_cvar("pug_maxplayers","10");
	PUG_VoteMap 		= register_cvar("pug_votemap","1");
	PUG_VoteDelay 		= register_cvar("pug_votedelay","10.0");
	PUG_SwitchDelay 	= register_cvar("pug_switch_delay","5.0");
	PUG_MaxRounds 		= register_cvar("pug_rounds","30");
	PUG_OTRounds 		= register_cvar("pug_ot_rounds","6");
	PUG_AllowSpec 		= register_cvar("pug_allowspec","1");
	PUG_AllowHLTV 		= register_cvar("pug_allowhltv","1");
	PUG_Reconnect		= register_cvar("pug_reconnect","20.0");
	PUG_TeamMoney 		= register_cvar("pug_teammoney","1");
	PUG_NoSuicide		= register_cvar("pug_nosuicide","1");
	PUG_AllowVoteCmds 	= register_cvar("pug_allowvotes","1");
	PUG_HelpFile 		= register_cvar("pug_help","help.htm");
	
	PUG_ReadyConfig 	= register_cvar("pug_pregame_cfg","pregame.rc");
	PUG_StartConfig 	= register_cvar("pug_ready_cfg","ready.rc");
	PUG_FirstConfig 	= register_cvar("pug_firsthalf_cfg","cal.rc");
	PUG_IntermissionConfig 	= register_cvar("pug_intermission_cfg","intermission.rc");
	PUG_SecondConfig 	= register_cvar("pug_secondhalf_cfg","cal.rc");
	PUG_OvertimeConfig 	= register_cvar("pug_overtime_cfg","cal-ot.rc");
	PUG_EndConfig 		= register_cvar("pug_finished_cfg","finished.rc");
	
	PUG_sv_restart 			= get_cvar_pointer("sv_restart");
	PUG_sv_visiblemaxplayers 	= get_cvar_pointer("sv_visiblemaxplayers");
	PUG_mp_startmoney 		= get_cvar_pointer("mp_startmoney");
	PUG_mapcyclefile 		= get_cvar_pointer("mapcyclefile");
	
	register_clcmd("say","PUG_SayFilter");
	register_clcmd("say_team","PUG_SayFilter");
	
	new szCommands[][] = {
		"ready",
		"notready",
		"round",
		"score",
		"status",
		"hp",
		"hpteam",
		"hpall" ,
			
		"dmg" ,
		"rdmg",
		"sum",
		"help"
	};
	
	g_hTrie = TrieCreate();
	for(new i; i < sizeof szCommands; i++)
	{
		TrieSetCell(g_hTrie, szCommands[i], 1);
	}
	
	register_clcmd("ready","PUG_ReadyUp", 		.info="Tells the server the player is ready");
	register_clcmd("notready","PUG_ReadyDown", 	.info="Tells the server the player is not ready");
	
	register_clcmd("round","PUG_Round",		.info="Display the current round");
	register_clcmd("score","PUG_Scores", 		.info="Display the current scores");
	register_clcmd("status","PUG_Status", 		.info="Display the server status");
	
	register_clcmd("hp","PUG_HP", 			.info="Shows the HP of the enemy");
	register_clcmd("hpteam","PUG_HPTeam", 		.info="Shows the HP of your team");
	register_clcmd("hpall","PUG_HPAll", 		.info="Shows the HP of all players");
	
	register_clcmd("dmg","PUG_Damage", 		.info="Shows damage you have done to other players");
	register_clcmd("rdmg","PUG_RDamage", 		.info="Shows damage done to you by other players");
	register_clcmd("sum","PUG_SDamage", 		.info="Shows the summary of the round");
	
	register_clcmd("help","PUG_Help", 		.info="Brings up client help info");

	PUG_tRetry = TrieCreate();

	for(new i;i < sizeof(PUG_szVoteCommands);++i)
	{
		register_clcmd(PUG_szVoteCommands[i],"PUG_Locked");
	}
	
	register_clcmd("vote","PUG_VoteCommand");
	register_clcmd("votemap","PUG_VoteCommand");
	
	register_clcmd("jointeam","PUG_JoinTeam");
	register_clcmd("joinclass","PUG_JoinClass");
	register_clcmd("menuselect","PUG_JoinClass");
	
	PUG_iMenuMap 	= menu_create("Vote Map:","PUG_MenuHandler");
	
	menu_setprop(PUG_iMenuMap,MPROP_EXIT,MEXIT_NEVER);
	
	PUG_iMenuCfg = menu_create("Config:","PUG_MenuHandler");
	
	menu_additem(PUG_iMenuCfg,PUG_szConfigTypes[PUG_CFG_CAL],"0");
	menu_additem(PUG_iMenuCfg,PUG_szConfigTypes[PUG_CFG_CEVO],"1");

	menu_setprop(PUG_iMenuCfg,MPROP_EXIT,MEXIT_NEVER);
	
	PUG_iMenuTeams 	= menu_create("Team Enforcement:","PUG_MenuHandler");
	
	menu_additem(PUG_iMenuTeams,PUG_szTeamTypes[PUG_SORT_AUTO],"0");
	menu_additem(PUG_iMenuTeams,PUG_szTeamTypes[PUG_SORT_NONE],"1");
	menu_additem(PUG_iMenuTeams,PUG_szTeamTypes[PUG_SORT_CAPTAINS],"2");
	
	menu_setprop(PUG_iMenuTeams,MPROP_EXIT,MEXIT_NEVER);
	
	register_menucmd(register_menuid("#Buy",1),511,"PUG_BuyMenu");
	register_menucmd(-28,511,"PUG_BuyMenu");
	
	register_menucmd(register_menuid("BuyItem",1),511,"PUG_ItemMenu");
	register_menucmd(-34,511,"PUG_ItemMenu");
	
	register_menucmd(-2,(1<<0)|(1<<1)|(1<<4)|(1<<5),"PUG_TeamSelect");
	register_menucmd(register_menuid("Team_Select",1),(1<<0)|(1<<1)|(1<<4)|(1<<5),"PUG_TeamSelect");

	register_event("ResetHUD","PUG_HudList","b");
	register_event("CurWeapon","PUG_CurWeapon","be","1=1");
	register_event("StatusIcon","PUG_StatusIcon","be","2=buyzone");
	register_event("SendAudio","PUG_SendAudio","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw");
	
	register_logevent("PUG_RoundStart",2,"1=Round_Start");
	register_logevent("PUG_RoundEnd",2,"1=Round_End");
	
	register_message(get_user_msgid("Money"),"PUG_Money");
	
	register_forward(FM_SetModel,"PUG_fwSetModel",true);
	register_forward(FM_CVarGetFloat,"PUG_fwCVarGetFloat",false);
	register_forward(FM_ClientKill,"PUG_fwClientKill",false);

	RegisterHam(Ham_Killed,"player","PUG_HamKilledPost",1);
	RegisterHam(Ham_Spawn,"player","PUG_SpawnPost",1);
}

public plugin_cfg()
{
	new szPatch[40];
	get_localinfo("amxx_configsdir",szPatch,charsmax(szPatch));

	format(szPatch,charsmax(szPatch),"%s/maps.ini",szPatch);

	if(!PUG_LoadMaps(szPatch))
	{
		get_pcvar_string(PUG_mapcyclefile,szPatch,charsmax(szPatch));
		
		PUG_LoadMaps(szPatch);
	}
	
	PUG_Change(PUG_STAGE_READY);
}

public plugin_end()
{
	if(PUG_STAGE_FIRSTHALF <= PUG_iStage <= PUG_STAGE_OVERTIME)
	{
		PUG_Change(PUG_STAGE_END);
	}
}

PUG_LoadMaps(const szPatch[])
{
	if(!file_exists(szPatch)) return 0;
	
	new iFile = fopen(szPatch,"rb");
	
	new szMap[32],iNum[10];

	new szCurrent[32];
	get_mapname(szCurrent,charsmax(szCurrent));
	
	while(!feof(iFile) && (PUG_iMapCount < PUG_MAX_MAPS))
	{
		fgets(iFile,szMap,charsmax(szMap));
		trim(szMap);
		
		if(szMap[0] != ';' && is_map_valid(szMap) && !equali(szMap,szCurrent))
		{
			copy(PUG_szMapNames[PUG_iMapCount],charsmax(PUG_szMapNames[]),szMap);
				
			num_to_str(PUG_iMapCount,iNum,charsmax(iNum));
			menu_additem(PUG_iMenuMap,PUG_szMapNames[PUG_iMapCount],iNum);
		
			PUG_iMapCount++;
		}
	}
	
	fclose(iFile);
	
	return PUG_iMapCount;
}

PUG_Change(PUG_STAGE)
{
	PUG_iStage = PUG_STAGE;
	
	switch(PUG_iStage)
	{
		case PUG_STAGE_READY:
		{
			new szConfig[32];
			get_pcvar_string(PUG_ReadyConfig,szConfig,charsmax(szConfig));

			PUG_ExecConfig(szConfig,1);

			PUG_BombRemove(true);
						
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_START",
				PUG_szStage[PUG_iStage]
			);
		}
		case PUG_STAGE_START:
		{
			new szConfig[32];
			get_pcvar_string(PUG_StartConfig,szConfig,charsmax(szConfig));
			
			PUG_ExecConfig(szConfig,1);
			
			arrayset(PUG_bVoted,false,sizeof(PUG_bVoted));
			
			new iVoteMap = get_pcvar_num(PUG_VoteMap);
			
			if(iVoteMap)
			{
				PUG_iMenuStage = PUG_MENU_MAP;
				
				arrayset(PUG_iMapVotes,0,sizeof(PUG_iMapVotes));
				
				new iPlayers[32],iNum,iPlayer;
				get_players(iPlayers,iNum,"ch");
				
				for(new i;i < iNum;i++)
				{
					iPlayer = iPlayers[i];
					
					if(is_user_connected(iPlayer) && PUG_isValidTeam(iPlayer))
					{
						menu_display(iPlayer,PUG_iMenuMap);
					}
				}
				
				set_task(get_pcvar_float(PUG_VoteDelay),"PUG_VoteEnd",PUG_TASK_VOTE);
				
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_MAP"
				);
			}
			else if(!iVoteMap && !PUG_bTeams)
			{
				PUG_iMenuStage = PUG_MENU_TEAMS;

				PUG_bTeams = true;
				arrayset(PUG_iTeamVotes,0,sizeof(PUG_iTeamVotes));
				
				new iPlayers[32],iNum,iPlayer;
				get_players(iPlayers,iNum,"ch");
				
				for(new i;i < iNum;i++)
				{
					iPlayer = iPlayers[i];
					
					if(is_user_connected(iPlayer) && PUG_isValidTeam(iPlayer))
					{
						menu_display(iPlayer,PUG_iMenuTeams);
					}
				}
				
				set_task(get_pcvar_float(PUG_VoteDelay),"PUG_VoteEnd",PUG_TASK_VOTE);
				
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_TEAM"
				);
			}
			else if(!iVoteMap && PUG_bTeams)
			{
				PUG_iMenuStage = PUG_MENU_CFG;
				
				arrayset(PUG_iConfigVotes,0,sizeof(PUG_iConfigVotes));
				
				new iPlayers[32],iNum,iPlayer;
				get_players(iPlayers,iNum,"ch");
				
				for(new i;i < iNum;i++)
				{
					iPlayer = iPlayers[i];
					
					if(is_user_connected(iPlayer) && PUG_isValidTeam(iPlayer))
					{
						menu_display(iPlayer,PUG_iMenuCfg);
					}
				}
				
				set_task(get_pcvar_float(PUG_VoteDelay),"PUG_VoteEnd",PUG_TASK_VOTE);
				
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_CFG"
				);
			}
		}
		case PUG_STAGE_FIRSTHALF:
		{
			new iFwd = CreateMultiForward("PUG_match_start", ET_IGNORE), iRet;
			ExecuteForward(iFwd, iRet);
			DestroyForward(iFwd);
			
			new szConfig[32];
			get_pcvar_string(PUG_FirstConfig,szConfig,charsmax(szConfig));

			PUG_ExecConfig(szConfig,0);

			PUG_iMenuStage = PUG_MENU_NONE;

			arrayset(PUG_iRounds,0,sizeof(PUG_iRounds));

			PUG_LO3();
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_LO3"
			);
		}
		case PUG_STAGE_INTERMISSION:
		{
			new szConfig[32];
			get_pcvar_string(PUG_IntermissionConfig,szConfig,charsmax(szConfig));
			
			PUG_ExecConfig(szConfig,0);
			
			arrayset(PUG_bReady,0,sizeof(PUG_bReady));
			
			PUG_HudList();
			
			new iTemp = PUG_iScores[CS_TEAM_T];
	
			PUG_iScores[CS_TEAM_T] 	= PUG_iScores[CS_TEAM_CT];
			PUG_iScores[CS_TEAM_CT] = iTemp;
			
			set_task(get_pcvar_float(PUG_SwitchDelay),"PUG_SwapTeams");

			PUG_BombRemove(true);

			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_INTERMISSION",
				PUG_szStage[PUG_iStage]
			);
		}
		case PUG_STAGE_SECONDHALF:
		{
			new szConfig[32];
			get_pcvar_string(PUG_SecondConfig,szConfig,charsmax(szConfig));
			
			PUG_ExecConfig(szConfig,0);
			
			PUG_LO3();
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %s: %s - %d, %s - %d",
				PUG_szHead,
				PUG_szStage[PUG_iStage],
				PUG_szTeams[CS_TEAM_T],
				PUG_iScores[CS_TEAM_T],
				PUG_szTeams[CS_TEAM_CT],
				PUG_iScores[CS_TEAM_CT]
			);
		}
		case PUG_STAGE_OVERTIME:
		{
			new szConfig[32];
			get_pcvar_string(PUG_OvertimeConfig,szConfig,charsmax(szConfig));
			
			PUG_ExecConfig(szConfig,0);
			
			PUG_LO3();
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %s: %s - %d, %s - %d",
				PUG_szHead,
				PUG_szStage[PUG_iStage],
				PUG_szTeams[CS_TEAM_T],
				PUG_iScores[CS_TEAM_T],
				PUG_szTeams[CS_TEAM_CT],
				PUG_iScores[CS_TEAM_CT]
			);
		}
		case PUG_STAGE_END:
		{
			new szConfig[32];
			get_pcvar_string(PUG_EndConfig,szConfig,charsmax(szConfig));
			
			PUG_ExecConfig(szConfig,0);
			
			arrayset(PUG_bReady,0,sizeof(PUG_bReady));
			
			if(!get_pcvar_num(PUG_VoteMap)) set_pcvar_num(PUG_VoteMap,1);

			PUG_BombRemove(true);
			
			if(PUG_iScores[CS_TEAM_T] != PUG_iScores[CS_TEAM_CT])
			{
				new CsTeams:iWinner = (PUG_iScores[CS_TEAM_T] > PUG_iScores[CS_TEAM_CT]) ? CS_TEAM_T : CS_TEAM_CT;
				new CsTeams:iLosers = (iWinner == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;

				new szMessage[86];
				format
				(
					szMessage,
					charsmax(szMessage),
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_END_WIN",
					PUG_szTeamNames[iWinner],
					PUG_iScores[iWinner],
					PUG_iScores[iLosers]
				);
				
				console_print(0,szMessage);
				client_print_color(0,print_team_grey,szMessage);
			}
			else
			{
				new szMessage[64];
				format
				(
					szMessage,
					charsmax(szMessage),
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_END_TIE",
					PUG_iScores[CS_TEAM_T],
					PUG_iScores[CS_TEAM_CT]
				);
				
				console_print(0,szMessage);
				client_print_color(0,print_team_grey,szMessage);
			}
			
			new iFwd = CreateMultiForward("PUG_match_end", ET_IGNORE), iRet;
			ExecuteForward(iFwd, iRet);
			DestroyForward(iFwd);
		}
	}
}


public PUG_SayFilter(id)
{
	new szArgs[192];
	read_args(szArgs,charsmax(szArgs));
	remove_quotes(szArgs);
	
	if(TrieKeyExists(g_hTrie, szArgs))
	{
		client_cmd(id,szArgs);
		
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public PUG_Locked(id)
{
	if(PUG_iStage == PUG_STAGE_START)
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public client_authorized(id)
{
	new iReconnectTime = get_pcvar_num(PUG_Reconnect);
	
	if(iReconnectTime)
	{
		new szSteam[35]; 
		get_user_authid(id,szSteam,charsmax(szSteam));       
		 
		new iTime;
	
		if(TrieGetCell(PUG_tRetry,szSteam,iTime))
		{
			if(get_systime() - iTime < iReconnectTime)
			{
				new szReason[32];
				
				format
				(
					szReason,
					charsmax(szReason),
					"%L",
					LANG_SERVER,
					"PUG_RETRY_MSG",
					(iReconnectTime + iTime - get_systime())
				);
	
				PUG_Disconnect(id,szReason);
			}
		}
		
		return PLUGIN_HANDLED;
	}
	
	PUG_bReady[id] = false;
	
	arrayset(PUG_iHits[id],0,sizeof(PUG_iHits[]));
	arrayset(PUG_iDamage[id],0,sizeof(PUG_iDamage[]));
	
	PUG_HudList();
	
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	PUG_HudList();

	set_task(10.0,"PUG_IntroMessage",id);
}

public client_infochanged(id) set_task(0.1,"PUG_HudList");

public client_disconnect(id)
{
	PUG_HudList();
	
	for(new i;i < PUG_MAX_PLAYERS;++i)
	{
		PUG_iHits[i][id] = 0;
		PUG_iDamage[i][id] = 0;
	}
	
	if(get_pcvar_num(PUG_Reconnect))
	{
		new szSteam[35];
		get_user_authid(id,szSteam,charsmax(szSteam));
		
		TrieSetCell(PUG_tRetry,szSteam,get_systime());
	}

	if(PUG_STAGE_FIRSTHALF <= PUG_iStage <= PUG_STAGE_OVERTIME)
	{
		if(get_playersnum() <= PUG_MOD_MINPLAYERS)
		{
			PUG_Change(PUG_STAGE_END);
		}
	}
}

public PUG_IntroMessage(id)
{
	if(is_user_connected(id))
	{
		if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_INTRO"
			);
		}

		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_HELP"
		);
	}
}

public PUG_HudList()
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_START || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		PUG_HudDisplay(9999.0);
	}
}

public PUG_CheckPlayer(id)
{
	new iMaxPlayers = get_pcvar_num(PUG_MaxPlayers);
		
	if(PUG_GetPlayers() >= iMaxPlayers)
	{
		new szMsg[32];
		formatex(szMsg,charsmax(szMsg),"%L",LANG_PLAYER,"PUG_FULL");
	
		if(is_user_hltv(id) && !get_pcvar_num(PUG_AllowHLTV))
		{
			PUG_Disconnect(id,szMsg);
		}
		else if(!get_pcvar_num(PUG_AllowSpec))
		{
			PUG_Disconnect(id,szMsg);
		}
	}
	
	if(get_playersnum(1) > iMaxPlayers)
	{
		new szMsg[32];
		formatex(szMsg,charsmax(szMsg),"%L",LANG_PLAYER,"PUG_FULL");

		if(!is_user_hltv(id) || !get_pcvar_num(PUG_AllowSpec))
		{
			PUG_Disconnect(id,szMsg);
		}
	}
}

PUG_RestoreOrder()
{
	while(PUG_GetPlayers() > get_pcvar_num(PUG_MaxPlayers))
	{
		new iTest = 3600,iWho,iTime;

		new iPlayers[32],iNum,iPlayer;
		get_players(iPlayers,iNum,"ch");

		for(new i;i < iNum;i++)
		{
			iPlayer = iPlayers[i];

			if(!is_user_hltv(iPlayer) && is_user_connected(iPlayer)) 
			{
				iTime = get_user_time(iPlayer,1);

     				if(iTest >= iTime)
				{
					iTest = iTime;

					iWho = iPlayer;
				}
			}
		}
		
		new szMsg[64];
		formatex(szMsg,charsmax(szMsg),"%L",LANG_PLAYER,"PUG_FULL_TIME");

		PUG_Disconnect(iWho,szMsg);
	}
}

public PUG_ReadyUp(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;

	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		if(PUG_bReady[id])
		{
			client_print_color(id,print_team_grey,"%s %L",PUG_szHead,LANG_PLAYER,"PUG_READY_ALREADY");
		}
		else
		{
			PUG_bReady[id] = true;
			
			new szName[32];
			get_user_name(id,szName,charsmax(szName));
			
			client_print_color(0,print_team_grey,"%s %L",PUG_szHead,LANG_PLAYER,"PUG_READY",szName);
			
			PUG_CheckReady();
		}
	}
	else
	{
		client_print_color(id,print_team_grey,"%s %L",PUG_szHead,LANG_PLAYER,"PUG_CMD_IMPOSSIBLE");
	}
	
	return PLUGIN_HANDLED;
}

public PUG_ReadyDown(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;

	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		if(!PUG_bReady[id])
		{
			client_print_color(id,print_team_grey,"%s %L",PUG_szHead,LANG_PLAYER,"PUG_READY_NOTREADY");
		}
		else
		{
			PUG_bReady[id] = false;
			
			new szName[32];
			get_user_name(id,szName,charsmax(szName));
			
			client_print_color(0,print_team_grey,"%s %L",PUG_szHead,LANG_PLAYER,"PUG_READY_UNREADY",szName);

			PUG_HudList();
		}
	}
	else
	{
		client_print_color(id,print_team_grey,"%s %L",PUG_szHead,LANG_PLAYER,"PUG_CMD_IMPOSSIBLE");
	}
	
	return PLUGIN_HANDLED;
}

PUG_CheckReady()
{
	PUG_HudList();
	
	new iReady;

	for(new i;i < sizeof(PUG_bReady);i++)
	{
		if(PUG_bReady[i]) iReady++;
	}
	
	if(iReady >= get_pcvar_num(PUG_MinPlayers))
	{
		switch(PUG_iStage)
		{
			case PUG_STAGE_READY:
			{
				PUG_Change(PUG_STAGE_START);
			}
			case PUG_STAGE_INTERMISSION:
			{
				PUG_Change(PUG_STAGE_SECONDHALF);
			}
			case PUG_STAGE_END:
			{
				PUG_Change(PUG_STAGE_START);
			}
		}
	}
}

PUG_HudDisplay(Float:fTime)
{
	switch(PUG_iStage)
	{
		case PUG_STAGE_READY,PUG_STAGE_INTERMISSION,PUG_STAGE_END:
		{
			new szReady[1056],szNotReady[1056],szName[32];
			
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"ch");
			
			new iReadys;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				if(PUG_isValidTeam(iPlayer))
				{
					get_user_name(iPlayer,szName,charsmax(szName));
					
					if(PUG_bReady[iPlayer])
					{
						iReadys++;
						
						format(szReady,charsmax(szReady),"%s%s^n",szReady,szName);
					}
					else format(szNotReady,charsmax(szNotReady),"%s%s^n",szNotReady,szName);
				}
			}
			
			new iMinPlayers = get_pcvar_num(PUG_MinPlayers);
		
			set_hudmessage(0,255,0,0.23,0.02,0,0.0,fTime,0.0,0.0,3);
			show_hudmessage(0,"%L",LANG_PLAYER,"PUG_HUD_UNREADY",PUG_GetPlayers() - iReadys,iMinPlayers);
		
			set_hudmessage(0,255,0,0.58,0.02,0,0.0,fTime,0.0,0.0,2);
			show_hudmessage(0,"%L",LANG_PLAYER,"PUG_HUD_READY",iReadys,iMinPlayers);
		
			set_hudmessage(255,255,225,0.58,0.05,0,0.0,fTime,0.0,0.0,1);
			show_hudmessage(0,szReady);
		
			set_hudmessage(255,255,225,0.23,0.05,0,0.0,fTime,0.0,0.0,4);
			show_hudmessage(0,szNotReady);
		}
		case PUG_STAGE_START:
		{
			switch(PUG_iMenuStage)
			{
				case PUG_MENU_CAPTAINS:
				{
					new szTRs[1056],szCTs[1056],szName[38];
					
					new iPlayers[32],iNum,iPlayer;
					get_players(iPlayers,iNum,"h");
					
					for(new i;i < iNum;i++)
					{
						iPlayer = iPlayers[i];
						
						get_user_name(iPlayer,szName,charsmax(szName));
						
						if(PUG_iCaptain[0] == iPlayer || PUG_iCaptain[1] == iPlayer)
						{
							format(szName,charsmax(szName),"%s (C)",szName);
						}
						
						switch(cs_get_user_team(iPlayer))
						{
							case CS_TEAM_T:
							{
								format(szTRs,charsmax(szTRs),"%s%s^n",szTRs,szName);
							}
							case CS_TEAM_CT:
							{
								format(szCTs,charsmax(szCTs),"%s%s^n",szCTs,szName);
							}
						}
					}
					
					set_hudmessage(255,0,0,0.23,0.02,0,0.0,fTime,0.0,0.0,1);
					show_hudmessage(0,PUG_szTeamNames[CS_TEAM_T]);
				
					set_hudmessage(255,255,255,0.23,0.05,0,0.0,fTime,0.0,0.0,2);
					show_hudmessage(0,szTRs);
				
					set_hudmessage(0,0,255,0.58,0.02,0,0.0,fTime,0.0,0.0,3);
					show_hudmessage(0,PUG_szTeamNames[CS_TEAM_CT]);

					set_hudmessage(255,255,255,0.58,0.05,0,0.0,fTime,0.0,0.0,4);
					show_hudmessage(0,szCTs);
				}
				case PUG_MENU_MAP:
				{
					set_hudmessage(0,255,0,0.23,0.02,0,0.0,fTime,0.0,0.0,1);
					show_hudmessage(0,"%L",LANG_PLAYER,"PUG_HUD_MAP");
					
					new szMaps[256],iVotes;
					
					for(new x;x < PUG_iMapCount;++x)
					{
						if(PUG_iMapVotes[x])
						{
							iVotes++;
							
							format
							(
								szMaps,
								charsmax(szMaps),
								"%s%s - %d %s^n",
								szMaps,
								PUG_szMapNames[x],
								PUG_iMapVotes[x],
								(PUG_iMapVotes[x] > 1) ? "votes" : "vote"
							);
						}
					}
					
					new szNone[32];
					formatex(szNone,charsmax(szNone),"%L",LANG_PLAYER,"PUG_HUD_NONE");
					
					set_hudmessage(255,255,255,0.23,0.05,0,0.0,fTime,0.0,0.0,2);
					show_hudmessage(0,iVotes ? szMaps : szNone);
				}
				case PUG_MENU_TEAMS:
				{
					set_hudmessage(0,255,0,0.23,0.02,0,0.0,fTime,0.0,0.0,1);
					show_hudmessage(0,"%L",LANG_PLAYER,"PUG_HUD_TEAM");
					
					new szTeams[128],iVotes;
					
					for(new x;x < PUG_SORT_TYPE;++x)
					{
						if(PUG_iTeamVotes[x])
						{
							iVotes++;
							
							format
							(
								szTeams,
								charsmax(szTeams),
								"%s%s - %d %s^n",
								szTeams,
								PUG_szTeamTypes[x],
								PUG_iTeamVotes[x],
								(PUG_iTeamVotes[x] > 1) ? "votes" : "vote"
							);
						}
					}
					
					new szNone[32];
					formatex(szNone,charsmax(szNone),"%L",LANG_PLAYER,"PUG_HUD_NONE");
					
					set_hudmessage(255,255,255,0.23,0.05,0,0.0,fTime,0.0,0.0,2);
					show_hudmessage(0,iVotes ? szTeams : szNone);
				}
				case PUG_MENU_CFG:
				{
					set_hudmessage(0,255,0,0.23,0.02,0,0.0,fTime,0.0,0.0,1);
					show_hudmessage(0,"%L",LANG_PLAYER,"PUG_HUD_CFG");
					
					new szConfigs[256],iVotes;
					
					for(new x;x < PUG_CFG_FILE;++x)
					{
						if(PUG_iConfigVotes[x])
						{
							iVotes++;
							
							format
							(
								szConfigs,
								charsmax(szConfigs),
								"%s%s - %d %s^n",
								szConfigs,
								PUG_szConfigTypes[x],
								PUG_iConfigVotes[x],
								(PUG_iConfigVotes[x] > 1) ? "votes" : "vote"
							);
						}
					}
					
					new szNone[32];
					formatex(szNone,charsmax(szNone),"%L",LANG_PLAYER,"PUG_HUD_NONE");
					
					set_hudmessage(255,255,255,0.23,0.05,0,0.0,fTime,0.0,0.0,2);
					show_hudmessage(0,iVotes ? szConfigs : szNone);
				}
			}
		}
	}
}

public PUG_MenuHandler(id,iMenu,iKey)
{
	new szData[6],szOption[64],iAccess,iCallBack;
	menu_item_getinfo(iMenu,iKey,iAccess,szData,charsmax(szData),szOption,charsmax(szOption),iCallBack);
	
	switch(PUG_iMenuStage)
	{
		case PUG_MENU_MAP:
		{
			if(iKey == MENU_EXIT) return PLUGIN_HANDLED;
			
			PUG_iMapVotes[str_to_num(szData)]++;
			
			PUG_bVoted[id] = true;
			
			PUG_HudList();
			
			new szName[32];
			get_user_name(id,szName,charsmax(szName));
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_VOTE_CHOOSED",
				szName,
				szOption
			);
			
			if(PUG_StopVote()) PUG_VoteEnd();
		}
		case PUG_MENU_TEAMS:
		{
			if(iKey == MENU_EXIT) return PLUGIN_HANDLED;
			
			PUG_iTeamVotes[str_to_num(szData)]++;
			
			PUG_bVoted[id] = true;
			
			PUG_HudList();

			new szName[32];
			get_user_name(id,szName,charsmax(szName));
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_VOTE_CHOOSED",
				szName,
				szOption
			);
			
			if(PUG_StopVote()) PUG_VoteEnd();
		}
		case PUG_MENU_CAPTAINS:
		{
			if(iKey == MENU_EXIT)
			{
				menu_display(id,iMenu,0);
				
				return PLUGIN_HANDLED;
			}
			
			new iPlayer = str_to_num(szData);
			
			cs_set_user_team(iPlayer,cs_get_user_team(id));
		
			new szTemp[2][32];
			get_user_name(id,szTemp[0],charsmax(szTemp[]));
			get_user_name(iPlayer,szTemp[1],charsmax(szTemp[]));
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CAPT_CHOOSED",
				szTemp[0],
				szTemp[1]
			);
			
			if(is_user_connected(PUG_iCaptain[0]) && is_user_connected(PUG_iCaptain[1]))
			{
				set_task(1.5,"PUG_CaptainMenu",(id == PUG_iCaptain[0]) ? PUG_iCaptain[1] : PUG_iCaptain[0]);
			}
			else
			{
				set_task(3.0,"PUG_CaptainJoin",(id == PUG_iCaptain[0]) ? PUG_iCaptain[1] : PUG_iCaptain[0]);
				
				client_print_color(0,print_team_grey,"%s %L",PUG_szHead,LANG_PLAYER,"PUG_CAPT_WAIT");
			}
			
			menu_destroy(iMenu);
			remove_task(id + PUG_TASK_AUTO);
		}
		case PUG_MENU_CFG:
		{
			if(iKey == MENU_EXIT) return PLUGIN_HANDLED;
			
			PUG_iConfigVotes[str_to_num(szData)]++;
			
			PUG_bVoted[id] = true;
			
			PUG_HudList();
			
			new szName[32];
			get_user_name(id,szName,charsmax(szName));
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_VOTE_CHOOSED",
				szName,
				szOption
			);
			
			if(PUG_StopVote()) PUG_VoteEnd();
		}
	}
	
	return PLUGIN_HANDLED;
}

public PUG_VoteEnd()
{
	show_menu(0,0,"^n",1);
	remove_task(PUG_TASK_VOTE);
	
	switch(PUG_iMenuStage)
	{
		case PUG_MENU_MAP:
		{
			new iWinner,iWinnerVotes,iVotes;

			for(new i;i < PUG_iMapCount;i++)
			{
				iVotes = PUG_iMapVotes[i];
			
				if(iVotes >= iWinnerVotes)
				{
					iWinner = i;
					iWinnerVotes = iVotes;
				}
				else if(iVotes == iWinnerVotes)
				{
					if(random_num(0,1))
					{
						iWinner = i;
						iWinnerVotes = iVotes;
					}
				}
			}
			
			if(PUG_iMapVotes[iWinner])
			{
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_WON",
					PUG_szMapNames[iWinner]
				);
			}
			else
			{
				iWinner = random_num(1,PUG_iMapCount);
				
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_AUTO",
					PUG_szMapNames[iWinner]
				);
			}
			
			set_task
			(
				get_pcvar_float(PUG_SwitchDelay),
				"PUG_ChangeMap",
				_,
				PUG_szMapNames[iWinner],
				sizeof(PUG_szMapNames)
			);
			
			return PLUGIN_HANDLED;
		}
		case PUG_MENU_TEAMS:
		{
			new iWinner,iWinnerVotes,iVotes;

			for(new i;i < sizeof(PUG_szTeamTypes);++i)
			{
				iVotes = PUG_iTeamVotes[i];
			
				if(iVotes > iWinnerVotes)
				{
					iWinner = i;
					iWinnerVotes = iVotes;
				}
				else if(iVotes == iWinnerVotes)
				{
					if(random_num(0,1))
					{
						iWinner = i;
						iWinnerVotes = iVotes;
					}
				}
			}
			
			if(PUG_iTeamVotes[iWinner])
			{
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_WON",
					PUG_szTeamTypes[iWinner]
				);
			}
			else
			{
				iWinner = random(sizeof(PUG_szTeamTypes));
				
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_AUTO",
					PUG_szTeamTypes[iWinner]
				);
			}
			
			PUG_ChangeTeams(iWinner);
			
			return PLUGIN_HANDLED;
		}
		case PUG_MENU_CFG:
		{
			new iWinner,iWinnerVotes,iVotes;
			
			for(new i;i < sizeof(PUG_szConfigTypes);++i)
			{
				iVotes = PUG_iConfigVotes[i];
			
				if(iVotes > iWinnerVotes)
				{
					iWinner = i;
					iWinnerVotes = iVotes;
				}
				else if(iVotes == iWinnerVotes)
				{
					if(random_num(0,1))
					{
						iWinner = i;
						iWinnerVotes = iVotes;
					}
				}
			}
	
			if(PUG_iConfigVotes[iWinner])
			{
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_WON",
					PUG_szConfigTypes[iWinner]
				);
			}
			else
			{
				iWinner = random(sizeof(PUG_szConfigTypes));
				
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_VOTE_AUTO",
					PUG_szConfigTypes[iWinner]
				);
			}
			
			PUG_SetConfigs(iWinner);
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PUG_ChangeMap(const szMap[])
{
	set_pcvar_num(PUG_VoteMap,0);
	server_cmd("changelevel %s",szMap);
}

PUG_ChangeTeams(iType)
{
	switch(iType)
	{
		case PUG_SORT_AUTO:
		{
			new iPlayers[32],iNum;
			get_players(iPlayers,iNum);
			
			for(new i;i < iNum;i++)
			{
				if(!PUG_isValidTeam(iPlayers[i])) iPlayers[i--] = iPlayers[--iNum];
			}
			
			new iPlayer,CsTeams:iTeam = random(2) ? CS_TEAM_T : CS_TEAM_CT;
			
			new iRandom;
			
			while(iNum)
			{
				iRandom = random(iNum);
				
				iPlayer = iPlayers[iRandom];
				
				cs_set_user_team(iPlayer,iTeam);
				
				iPlayers[iRandom] = iPlayers[--iNum];
				
				iTeam = CsTeams:((_:iTeam) % 2 + 1);
			}
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_SORT_AUTO"
			);
			
			PUG_Change(PUG_STAGE_START);
		}
		case PUG_SORT_NONE:
		{
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_SORT_NONE"
			);
			
			PUG_Change(PUG_STAGE_START);
		}
		case PUG_SORT_CAPTAINS:
		{
			PUG_iMenuStage = PUG_MENU_CAPTAINS;
			
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			if(iNum < PUG_CAPTAIN_MINPLAYERS)
			{
				client_print_color
				(
					0,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_CAPT_MINPLAYERS",
					PUG_CAPTAIN_MINPLAYERS
				);
				
				PUG_Change(PUG_STAGE_START);
				
				return;
			}
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				if(!PUG_iCaptain[0])
				{
					PUG_iCaptain[0] = iPlayer;
					
					cs_set_user_team(iPlayer,CS_TEAM_T);
					
					continue;
				}
				
				if(!PUG_iCaptain[1])
				{
					PUG_iCaptain[1] = iPlayer;
					
					cs_set_user_team(iPlayer,CS_TEAM_CT);
					
					continue;
				}
				
				user_silentkill(iPlayer);
				cs_set_user_team(iPlayer,CS_TEAM_SPECTATOR);
			}
			
			set_pcvar_num(PUG_sv_restart,1);
			
			new szName[2][32];
			get_user_name(PUG_iCaptain[0],szName[0],charsmax(szName[]));
			get_user_name(PUG_iCaptain[1],szName[1],charsmax(szName[]));
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CAPT_ARE",
				szName[0],
				szName[1]
			);
			
			set_task(2.0,"PUG_CaptainMenu",PUG_iCaptain[random(1)]);
		}
		default:
		{
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_SORT_OFF"
			);
			
			PUG_Change(PUG_STAGE_START);
		}
	}
}

PUG_SetConfigs(iType)
{
	switch(iType)
	{
		case PUG_CFG_CAL:
		{
			set_pcvar_string(PUG_FirstConfig,	"cal.rc");
			set_pcvar_string(PUG_SecondConfig,	"cal.rc");
			set_pcvar_string(PUG_OvertimeConfig,	"cal-ot.rc");
		}
		case PUG_CFG_CEVO:
		{
			set_pcvar_string(PUG_FirstConfig,	"cevo.rc");
			set_pcvar_string(PUG_SecondConfig,	"cevo.rc");
			set_pcvar_string(PUG_OvertimeConfig,	"cevo-ot.rc");
		}
		default:
		{
			set_pcvar_string(PUG_FirstConfig,	"cal.rc");
			set_pcvar_string(PUG_SecondConfig,	"cal.rc");
			set_pcvar_string(PUG_OvertimeConfig,	"cal-ot.rc");
		}
	}
	
	PUG_Change(PUG_STAGE_FIRSTHALF);
}

public PUG_CaptainMenu(id)
{
	PUG_HudList();
	
	if(is_user_bot(id))
	{
		PUG_CaptainTask(id + PUG_TASK_AUTO); 
		
		return;
	}
	
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"h");
	
	new szName[32],szTemp[3],iSpec;
	new iMenu = menu_create("Escolha um Player:","PUG_MenuHandler");
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		if(cs_get_user_team(iPlayer) == CS_TEAM_SPECTATOR)
		{
			iSpec++;
			
			get_user_name(iPlayer,szName,charsmax(szName));
					
			num_to_str(iPlayer,szTemp,charsmax(szTemp));
			menu_additem(iMenu,szName,szTemp);
		}
	}
	
	if(!iSpec)
	{
		PUG_Change(PUG_STAGE_START);
		
		arrayset(PUG_iCaptain,0,sizeof(PUG_iCaptain));
		
		return;
	}
	
	menu_setprop(iMenu,MPROP_EXIT,MEXIT_NEVER);
	
	menu_display(id,iMenu);
	
	set_task(11.5,"PUG_CaptainTask",id + PUG_TASK_AUTO);
}

public PUG_CaptainTask(id)
{
	id -= PUG_TASK_AUTO;
	
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"h");
	
	new bool:bSpec;
	
	for(new i; i < iNum;i++)
	{
		if(cs_get_user_team(iPlayers[i]) == CS_TEAM_SPECTATOR)
		{
			bSpec = true;
		}
	}
	
	if(!bSpec)
	{
		PUG_Change(PUG_STAGE_START);
		
		arrayset(PUG_iCaptain,0,sizeof(PUG_iCaptain));
		
		return;
	}
	
	new iRandom = random(iNum);
	
	while(cs_get_user_team(iPlayers[iRandom]) != CS_TEAM_SPECTATOR)
	{
		iRandom = random(iNum);
	}
	
	if(is_user_connected(id))
	{
		if(is_user_connected(iPlayers[iRandom]))
		{
			cs_set_user_team(iPlayers[iRandom],cs_get_user_team(id));
			
			new szName[2][32];
			get_user_name(id,szName[0],charsmax(szName[]));
			get_user_name(iPlayers[iRandom],szName[1],charsmax(szName[]));
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CAPT_CHOOSED",
				szName[0],
				szName[1]
			);
		}
		
		set_task(1.5,"PUG_CaptainMenu",(id == PUG_iCaptain[0]) ? PUG_iCaptain[1] : PUG_iCaptain[0]);
	}
	else
	{
		set_task(3.0,"PUG_CaptainJoin",(id == PUG_iCaptain[0] ? PUG_iCaptain[1] : PUG_iCaptain[0]));

		client_print_color
		(
			0,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_CAPT_WAIT"
		);
	}
	
	show_menu(id,0,"^n",1);
}

public PUG_CaptainJoin(iNext)
{
	if(is_user_connected(PUG_iCaptain[0]) && is_user_connected(PUG_iCaptain[1]))
	{
		set_task(1.5,"PUG_CaptainMenu",iNext);
	}
	else
	{
		set_task(3.0,"PUG_CaptainJoin",iNext);
		
		client_print_color
		(
			0,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_CAPT_WAIT"
		);
	}
}

PUG_LO3()
{
	PUG_BombRemove(false);

	set_task(0.2,"PUG_RestartRound",_,"1",1);
	set_task(2.2,"PUG_RestartRound",_,"2",1);
	set_task(5.8,"PUG_RestartRound",_,"3",1);
	
	set_task(10.0,"PUG_LiveMessage");
}

public PUG_LiveMessage()
{
	set_hudmessage(0,255,0,-1.0,0.3,0,6.0,6.0);
	show_hudmessage(0,"--- MATCH IS LIVE ---");
}

public PUG_RestartRound(const szSeconds[]) set_pcvar_num(PUG_sv_restart,str_to_num(szSeconds));

public PUG_SendAudio()
{
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		PUG_bInRound = false;
		
		new szTeam[22];
		read_data(2,szTeam,charsmax(szTeam));
		
		if(containi(szTeam,"terwin") != -1)
		{
			PUG_iRounds[0]++;
			PUG_iScores[CS_TEAM_T]++;
			
			if(PUG_iStage == PUG_STAGE_OVERTIME) PUG_iRounds[2]++;
			
			console_print
			(
				0,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_ROUND_WON",
				PUG_iRounds[0],
				PUG_szTeamNames[CS_TEAM_T]
			);
		}
		else if(containi(szTeam,"ctwin") != -1)
		{
			PUG_iRounds[0]++;
			PUG_iScores[CS_TEAM_CT]++;
			
			if(PUG_iStage == PUG_STAGE_OVERTIME) PUG_iRounds[2]++;
				
			console_print
			(
				0,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_ROUND_WON",
				PUG_iRounds[0],
				PUG_szTeamNames[CS_TEAM_CT]
			);
		}
		else
		{
			PUG_iRounds[1]++;
			
			console_print
			(
				0,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_ROUND_NONE"
			);
		}
	}
}

public PUG_RoundEnd()
{
	switch(PUG_iStage)
	{
		case PUG_STAGE_FIRSTHALF:
		{
			if(PUG_iRounds[0] == (get_pcvar_num(PUG_MaxRounds) / 2))
			{
				PUG_Change(PUG_STAGE_INTERMISSION);
			}
		}
		case PUG_STAGE_SECONDHALF:
		{
			new iMaxRounds = get_pcvar_num(PUG_MaxRounds);
			
			if(PUG_iScores[CS_TEAM_T] > (iMaxRounds / 2))
			{
				PUG_Change(PUG_STAGE_END);
			}
			else if(PUG_iScores[CS_TEAM_CT] > (iMaxRounds / 2))
			{
				PUG_Change(PUG_STAGE_END);
			}
			else if(PUG_iRounds[0] == iMaxRounds)
			{
				PUG_Change(PUG_STAGE_INTERMISSION);
			}
		}
		case PUG_STAGE_OVERTIME:
		{
			new iOT = get_pcvar_num(PUG_OTRounds);
			
			new iRoundsOT = (iOT / 2);
			
			if(PUG_iRounds[0] == iRoundsOT)
			{
				PUG_Change(PUG_STAGE_INTERMISSION);
			}
			else if((PUG_iScores[CS_TEAM_T] - PUG_iScores[CS_TEAM_CT]) >= (iRoundsOT + 1))
			{
				PUG_Change(PUG_STAGE_END);
			}
			else if((PUG_iScores[CS_TEAM_CT] - PUG_iScores[CS_TEAM_T]) >= (iRoundsOT + 1))
			{
				PUG_Change(PUG_STAGE_END);
			}
		}
	}
}

public PUG_RoundStart()
{
	PUG_bInRound = true;
	
	for(new i;i < PUG_MAX_PLAYERS;++i)
	{
		arrayset(PUG_iHits[i],0,sizeof(PUG_iHits));
		arrayset(PUG_iDamage[i],0,sizeof(PUG_iDamage));	
	}
	
	switch(PUG_iStage)
	{
		case PUG_STAGE_FIRSTHALF:
		{
			if(PUG_iRounds[0]) PUG_Scores(0);
		}
		case PUG_STAGE_SECONDHALF:
		{
			if(PUG_iRounds[0] != (get_pcvar_num(PUG_MaxRounds) / 2)) PUG_Scores(0);
		}
		case PUG_STAGE_OVERTIME:
		{
			if(PUG_iRounds[0] != get_pcvar_num(PUG_MaxRounds)) PUG_Scores(0);
		}
	}
}

public PUG_Round(id)
{
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_STAGE_OVERTIME)
	{
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_ROUND",
			(PUG_iRounds[0] + 1)
		);
	}
	else
	{
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_CMD_IMPOSSIBLE"
		);
	}

	return PLUGIN_HANDLED;
}

public PUG_Scores(id)
{
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		if(PUG_iScores[CS_TEAM_T] != PUG_iScores[CS_TEAM_CT])
		{
			new CsTeams:iWinner = (PUG_iScores[CS_TEAM_T] > PUG_iScores[CS_TEAM_CT]) ? CS_TEAM_T : CS_TEAM_CT;
			
			client_print_color
			(
				0,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_SCORE_WINNER",
				PUG_szTeamNames[iWinner],
				PUG_iScores[iWinner],
				(iWinner == CS_TEAM_T) ? PUG_iScores[CS_TEAM_CT] : PUG_iScores[CS_TEAM_T]
			);
		}
		else
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_SCORE_TIED",
				PUG_iScores[CS_TEAM_T],
				PUG_iScores[CS_TEAM_CT]
			);
		}
	}
	else
	{
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_CMD_IMPOSSIBLE"
		);
	}
	
	return PLUGIN_HANDLED;	
}

public PUG_Status(id)
{
	client_print_color
	(
		id,
		print_team_grey,
		"%s %L",
		PUG_szHead,
		LANG_PLAYER,
		"PUG_STATUS",
		PUG_GetPlayers(),
		get_pcvar_num(PUG_MinPlayers),
		get_pcvar_num(PUG_MaxPlayers),
		PUG_szStage[PUG_iStage]
	);
	
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_STATUS_ROUND",
			PUG_iRounds[0],
			PUG_iRounds[1],
			PUG_szTeams[CS_TEAM_T],
			PUG_iScores[CS_TEAM_T],
			PUG_szTeams[CS_TEAM_CT],
			PUG_iScores[CS_TEAM_CT]
		);
	}

	return PLUGIN_HANDLED;
}

public PUG_SwapTeams()
{
	new iPlayers[32],iNum,Players;
	get_players(iPlayers,iNum,"h");
	
	for(new i;i < iNum;i++)
	{
		Players = iPlayers[i];
	
		switch(cs_get_user_team(Players))
		{
			case CS_TEAM_T:
			{
				cs_set_user_team(Players,CS_TEAM_CT);
			}
			case CS_TEAM_CT:
			{
				cs_set_user_team(Players,CS_TEAM_T);
			}
		}
	}
	
	set_pcvar_num(PUG_sv_restart,1);
}

public PUG_Money(iMsg,iDest,id)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		if(is_user_connected(id))
		{
			cs_set_user_money(id,get_pcvar_num(PUG_mp_startmoney),0);
		}

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public PUG_CurWeapon(id)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		new iWeapon = get_user_weapon(id);
		
		if(PUG_iWeaponSlots[iWeapon] == PUG_SLOT_PRIMARY || PUG_iWeaponSlots[iWeapon] == PUG_SLOT_SECONDARY)
		{
			new iAmmo = cs_get_user_bpammo(id,iWeapon);
			
			if(iAmmo < PUG_iMaxBPAmmo[iWeapon])
			{
				cs_set_user_bpammo(id,iWeapon,PUG_iMaxBPAmmo[iWeapon]);
			}
		}
	}
}

public client_damage(iAttacker,iVictim,iDamage,iWP,iPlace,TA)
{
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		PUG_iHits[iAttacker][iVictim]++;

		PUG_iDamage[iAttacker][iVictim] += iDamage;
	}
}

public PUG_HamKilledPost(id)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		set_task(0.75,"PUG_Respawn",id);
	}
}

public PUG_Respawn(id)
{
	if(is_user_connected(id) && !is_user_alive(id) && PUG_isValidTeam(id))
	{
		ExecuteHam(Ham_CS_RoundRespawn,id);
	}
}

public PUG_SpawnPost(id)
{
	if(get_pcvar_num(PUG_TeamMoney))
	{
		if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
		{
			if(is_user_connected(id) && PUG_isValidTeam(id) && cs_get_user_money(id) != get_pcvar_num(PUG_mp_startmoney))
			{
				set_task(0.1,"PUG_MoneyTeam",id);
			}
		}
	}
}

public PUG_MoneyTeam(id)
{
	new szTeam[13];
	get_user_team(id,szTeam,charsmax(szTeam));

	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"aeh",szTeam);

	new szName[32],szHud[512],iMoney;

	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];

		iMoney = cs_get_user_money(iPlayer);
		get_user_name(iPlayer,szName,charsmax(szName));

		format
		(
			szHud,
			charsmax(szHud),
			"%s%s $ %d^n",
			szHud,
			szName,
			iMoney
		);
	}

	set_hudmessage(0,255,0,0.58,0.02,0,0.0,6.0,0.0,0.0,1);
	show_hudmessage(id,(szTeam[0] == 'C') ? "Counter-Terrorists:" : "Terrorists:");
	
	set_hudmessage(255,255,225,0.58,0.05,0,0.0,6.0,0.0,0.0,2);
	show_hudmessage(id,szHud);
}

public PUG_StatusIcon(id)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		set_pev(id,pev_takedamage,read_data(1) ? DAMAGE_NO : DAMAGE_AIM);
	}
}

public PUG_fwSetModel(iEntity)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		if(!pev_valid(iEntity)) return;
		
		new szClassname[10];
		pev(iEntity,pev_classname,szClassname,charsmax(szClassname));
		
		if(equal(szClassname,"weaponbox"))
		{
			set_pev(iEntity,pev_nextthink,get_gametime() + 0.1);
		}
	}
}

public PUG_fwCVarGetFloat(const szCvar[])
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		if(equal(szCvar,"mp_buytime"))
		{
			forward_return(FMV_FLOAT,99999.0);
		
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public PUG_fwClientKill(id)
{
	if(is_user_alive(id) && get_pcvar_num(PUG_NoSuicide))
	{
		console_print(id,"Comando nao permitido.");

		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public client_command(id)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		PUG_HudList();

		new szCommand[32];
		read_argv(0,szCommand,charsmax(szCommand));
		
		for(new x;x < sizeof(PUG_szRestrictWeapons);x++)
		{
			if(equal(PUG_szRestrictWeapons[x],szCommand)) return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public CS_InternalCommand(id,const szCommand[])
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		for(new x;x < sizeof(PUG_szRestrictWeapons);x++)
		{
			if(equal(PUG_szRestrictWeapons[x],szCommand)) return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PUG_BuyMenu(id,iKey)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		if(iKey == 5 || iKey == 6) return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PUG_ItemMenu(id,iKey) 
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		switch(iKey)
		{
			case 2,3,4,6,7: return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PUG_VoteCommand(id)
{
	if(!get_pcvar_num(PUG_AllowVoteCmds))
	{
		console_print
		(
			id,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_VOTE_DISABLED"
		);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PUG_JoinTeam(id) 
{
	new szArg[3];
	read_argv(1,szArg,charsmax(szArg));

	return PUG_CheckTeam(id,str_to_num(szArg));
}

public PUG_TeamSelect(id,iKey) return PUG_CheckTeam(id,iKey + 1);

public PUG_CheckTeam(id,iNewTeam) 
{
	new iOldTeam = _:cs_get_user_team(id);
	new iMinPlayers = get_pcvar_num(PUG_MinPlayers);
	
	if(PUG_STAGE_START <= PUG_iStage <= PUG_STAGE_OVERTIME)
	{
		if((iOldTeam == 1) || (iOldTeam == 2))
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_TEAM_LOCKED"
			);

			return PLUGIN_HANDLED;
		}
	}

	if(iNewTeam == 6 && !get_pcvar_num(PUG_AllowSpec)) 
	{
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_TEAM_SPEC"
		);
		
		engclient_cmd(id,"chooseteam");

		return PLUGIN_HANDLED;
	}
	
	if(iNewTeam == iOldTeam)
	{
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_TEAM_SAMETEAM"
		);
		
		return PLUGIN_HANDLED;
	}

	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"h");

	new iTeam[2];
	
	for(new i;i < iNum;i++)
	{
		switch(cs_get_user_team(iPlayers[i]))
		{
			case CS_TEAM_T: ++iTeam[0];
			
			case CS_TEAM_CT: ++iTeam[1];
		}
	}
	
	if(iNewTeam == 5)
	{
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_TEAM_AUTO"
		);
		
		return PLUGIN_HANDLED;
	}
	else if((iNewTeam == 1) && (iTeam[0] == (iMinPlayers / 2)))
	{ 
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_TEAM_FULL"
		);
		
		return PLUGIN_HANDLED;
	}
	else if((iNewTeam == 2) && (iTeam[1] == (iMinPlayers / 2)))
	{ 
		client_print_color
		(
			id,
			print_team_grey,
			"%s %L",
			PUG_szHead,
			LANG_PLAYER,
			"PUG_TEAM_FULL"
		);
		
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public PUG_JoinClass(id)
{
	if(PUG_iStage == PUG_STAGE_READY || PUG_iStage == PUG_STAGE_INTERMISSION || PUG_iStage == PUG_STAGE_END)
	{
		if(get_pdata_int(id,205 /* m_iMenu */) == 3 /* MENU_CHOOSEAPPEARANCE */)
		{
			new szCommand[11],szArg[32];
			read_argv(0,szCommand,charsmax(szCommand));
			read_argv(1,szArg,charsmax(szArg));
		
			engclient_cmd(id,szCommand,szArg);
			ExecuteHam(Ham_Player_PreThink,id);

			PUG_Respawn(id);

			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PUG_HP(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;
	
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		if(is_user_alive(id) && PUG_bInRound)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CMD_IMPOSSIBLE"
			);
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"aeh",(cs_get_user_team(id) == CS_TEAM_T) ? "CT" : "TERRORIST");
			
			if(!iNum)
			{
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_HP_ALIVE"
				);
				
				return PLUGIN_HANDLED;
			}
			
			new szName[32];
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
			
				get_user_name(iPlayer,szName,charsmax(szName));
			    
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_HP",
					szName,
					get_user_health(iPlayer),
					get_user_armor(iPlayer)
				);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public PUG_HPTeam(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;
	
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		if(is_user_alive(id) && PUG_bInRound)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CMD_IMPOSSIBLE"
			);
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"aeh",(cs_get_user_team(id) == CS_TEAM_T) ? "TERRORIST" : "CT");
			
			if(!iNum)
			{
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_HP_ALIVE"
				);
				
				return PLUGIN_HANDLED;
			}
			
			new szName[32];
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
			
				get_user_name(iPlayer,szName,charsmax(szName));
			    
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_HP",
					szName,
					get_user_health(iPlayer),
					get_user_armor(iPlayer)
				);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public PUG_HPAll(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;
	
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		if(is_user_alive(id) && PUG_bInRound)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CMD_IMPOSSIBLE"
			);
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"ah");
			
			if(!iNum)
			{
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_HP_ALIVE"
				);
				
				return PLUGIN_HANDLED;
			}
			
			new szName[32];
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
			    
				if(iPlayer != id)
				{
					get_user_name(iPlayer,szName,charsmax(szName));
			    
					client_print_color
					(
						id,
						print_team_grey,
						"%s %L",
						PUG_szHead,
						LANG_PLAYER,
						"PUG_HP",
						szName,
						get_user_health(iPlayer),
						get_user_armor(iPlayer)
					);
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public PUG_Damage(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;
	
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		if(is_user_alive(id) && PUG_bInRound)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CMD_IMPOSSIBLE"
			);
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new szName[32];
			new iDmg,iHit,iCheck;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				iHit = PUG_iHits[id][iPlayer];
				
				if(iHit)
				{
					++iCheck;
				
					iDmg = PUG_iDamage[id][iPlayer];
					
					if(iPlayer == id)
					{
						client_print_color
						(
							id,
							print_team_grey,
							"%s %L",
							PUG_szHead,
							LANG_PLAYER,
							"PUG_DMG_SELF",
							iHit,
							(iHit > 1) ? "times" : "time",
							iDmg
						);
					}
					else
					{
						get_user_name(iPlayer,szName,charsmax(szName));
						
						client_print_color
						(
							id,
							print_team_grey,
							"%s %L",
							PUG_szHead,
							LANG_PLAYER,
							"PUG_DMG",
							szName,
							iHit,
							(iHit > 1) ? "times" : "time",
							iDmg
						);
					}
				}
			}
			
			if(!iCheck)
			{	
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_DMG_NONE"
				);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public PUG_RDamage(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;
	
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		if(is_user_alive(id) && PUG_bInRound)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CMD_IMPOSSIBLE"
			);
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new szName[32];
			new iDmg,iHit,iCheck;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				iHit = PUG_iHits[iPlayer][id];
				
				if(iHit)
				{
					++iCheck;
				
					iDmg = PUG_iDamage[iPlayer][id];
					
					if(iPlayer == id)
					{
						client_print_color
						(
							id,
							print_team_grey,
							"%s %L",
							PUG_szHead,
							LANG_PLAYER,
							"PUG_DMG_SELF",
							iHit,
							(iHit > 1) ? "times" : "time",
							iDmg
						);
					}
					else
					{
						get_user_name(iPlayer,szName,charsmax(szName));

						client_print_color
						(
							id,
							print_team_grey,
							"%s %L",
							PUG_szHead,
							LANG_PLAYER,
							"PUG_RDMG",
							szName,
							iHit,
							(iHit > 1) ? "times" : "time",
							iDmg
						);
					}
				}
			}
			
			if(!iCheck)
			{
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_RDMG_NONE"
				);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public PUG_SDamage(id)
{
	if(!PUG_isValidTeam(id)) return PLUGIN_CONTINUE;
	
	if(PUG_iStage == PUG_STAGE_FIRSTHALF || PUG_iStage == PUG_STAGE_SECONDHALF || PUG_iStage == PUG_STAGE_OVERTIME)
	{
		if(is_user_alive(id) && PUG_bInRound)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"%s %L",
				PUG_szHead,
				LANG_PLAYER,
				"PUG_CMD_IMPOSSIBLE"
			);
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new szName[32];
			
			new iDmg[2],iHit[2],iCheck;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				iHit[0] = PUG_iHits[id][iPlayer]; // Hits Done
				iHit[1] = PUG_iHits[iPlayer][id]; // Hits Recived
				
				if(iHit[0] || iHit[1])
				{
					++iCheck;
				
					iDmg[0] = PUG_iDamage[id][iPlayer]; // Damage Done
					iDmg[1] = PUG_iDamage[iPlayer][id]; // Damag Recived
					
					if(iPlayer == id)
					{
						client_print_color
						(
							id,
							print_team_grey,
							"%s %L",
							PUG_szHead,
							LANG_PLAYER,
							"PUG_DMG_SELF",
							iHit[0],
							(iHit[0] > 1) ? "times" : "time",
							iDmg[0]
						);
					}
					else
					{
						get_user_name(iPlayer,szName,charsmax(szName));
						
						client_print_color
						(
							id,
							print_team_grey,
							"%s %L",
							PUG_szHead,
							LANG_PLAYER,
							"PUG_SUM",
							iDmg[0],iHit[0],
							iDmg[1],iHit[1],
							szName,
							(is_user_alive(iPlayer) ? get_user_health(iPlayer) : 0)
						);
					}
				}
			}
			
			if(!iCheck)
			{
				client_print_color
				(
					id,
					print_team_grey,
					"%s %L",
					PUG_szHead,
					LANG_PLAYER,
					"PUG_SUM_NONE"
				);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public PUG_Help(id)
{
	new szFile[16];
	get_pcvar_string(PUG_HelpFile,szFile,charsmax(szFile));
	
	new szDir[40];
	get_localinfo("amxx_configsdir",szDir,charsmax(szDir));
	
	formatex(szDir,charsmax(szDir),"%s/pug/%s",szDir,szFile);
	
	new szTitle[32];
	formatex(szTitle,charsmax(szTitle),"%L",LANG_PLAYER,"PUG_HELP_CMD");
	
	show_motd(id,szDir,szTitle);
	
	return PLUGIN_HANDLED;
}

PUG_GetPlayers()
{
	new iPlayers[32],iNum,Players;
	get_players(iPlayers,iNum,"ch");
	
	new iNumber;
	
	for(new i;i < iNum;i++)
	{
		Players = iPlayers[i];
		
		switch(cs_get_user_team(Players))
		{
			case CS_TEAM_T: iNumber++;
			
			case CS_TEAM_CT: iNumber++;
		}
	}
	
	return iNumber;
}

PUG_StopVote()
{
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++)
	{
		if(!PUG_bVoted[iPlayers[i]]) return 0;
	}
	
	return 1;
}

PUG_ExecConfig(const szConfig[],iRestart)
{
	new szDir[32];
	get_localinfo("amxx_configsdir",szDir,charsmax(szDir));
	
	server_cmd("exec %s/pug/%s",szDir,szConfig);
	
	if(iRestart) set_pcvar_num(PUG_sv_restart,iRestart);
	
	PUG_RestoreOrder();
	
	set_pcvar_num(PUG_sv_visiblemaxplayers,get_pcvar_num(PUG_MaxPlayers));
}

PUG_Disconnect(const id,const szReason[] = "")
{
	message_begin(MSG_ONE,SVC_DISCONNECT,_,id);
	write_string(szReason);
	message_end();
}

PUG_BombRemove(bool:bRemove)
{
	new iEnt = -1;

	while((iEnt = engfunc(EngFunc_FindEntityByString,iEnt,"classname",bRemove ? "func_bomb_target" : "_func_bomb_target")) > 0)
	{
		set_pev(iEnt,pev_classname,bRemove ? "_func_bomb_target" : "func_bomb_target");
	}

	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", bRemove ? "info_bomb_target" : "_info_bomb_target")) > 0)
	{
		set_pev(iEnt,pev_classname,bRemove ? "_info_bomb_target" : "info_bomb_target");
	}
}
