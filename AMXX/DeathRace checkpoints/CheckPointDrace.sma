#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <xs>

#define VERSION "2.1a"

//#define DEBUG

#define ACCESS ADMIN_RCON

#define MAX_CHECK_POINTS 5
#define CHECK_NUM EV_INT_iuser4
#define HIGHLIGHT_ID EV_INT_iuser3

#define TASKID_TIMER 1515
#define NULL -1

new const PREFIX[] = "[CheckPoint]"
new const g_szCheckPointClassName[] = "DR_CheckPoint"

new g_iCheckPointEnt[MAX_CHECK_POINTS], g_iChecksNum
new g_iMenu

new g_iCreateStep[33], Float:g_flCreateOrigins[33][2][3], g_iCreateEnt[33]

new g_iCounter[33], g_iPlayerCheckPoint[33]

new bool:g_bHighLight = false, bool:g_bAllowRespawn = false

new g_pRespawnTime, g_pAutoSave

enum
{
	GO = 0,
	ADD,
	REMOVE,
	REMOVE_ALL,
	HIGHLIGHT,
	SAVE,
	LOAD
}

enum
{
	x,
	y,
	z
}

enum
{
	START,
	END
}

new gAlive, gIsHighLightened

#define IsInBit(%1,%2) ( %2 & (1<<%1) )
#define AddToBit(%1,%2) ( %2 |= (1<<%1) )
#define RemoveFromBit(%1,%2) ( %2 &= ~(1<<%1) )


new beampoint

new g_szCheckPointSound[] = "checkpoint.wav"

forward dr_win(iWinnerId)

public plugin_precache()
{
	beampoint = precache_model("sprites/laserbeam.spr")
	precache_sound(g_szCheckPointSound)
}


public plugin_init() {
	register_plugin .author = "Khalid :)", .plugin_name = "[DeathRace] CheckPoints", .version = VERSION
	
	if(!cvar_exists("Deathrace_status"))
	{
		set_fail_state("Can be only used on deathrace mod, sorry")
	}
	
	register_concmd("amx_checkpoints", "AdminCmdCheckPoints", ACCESS)
	register_clcmd("say", "HookSaid", ACCESS)
	
	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")
	register_logevent("RoundEnd", 2, "1=Round_End")
	
	RegisterHam(Ham_Killed, "player", "fw_Killed", 1)
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1)
	RegisterHam(Ham_Player_PreThink, "player", "fw_Think", 1)
	
	register_touch(g_szCheckPointClassName, "player", "fw_TouchCheckPoint")
	
	register_think(g_szCheckPointClassName, "fw_CheckPoint_Think")
	
	// Menu
	g_iMenu = menu_create("Choose an option", "MainMenuHandler")
	
	menu_additem(g_iMenu, "Go to a checkpoint", "0")
	menu_addblank(g_iMenu, 0)
	menu_additem(g_iMenu, "Add a checkpoint", "1")
	menu_additem(g_iMenu, "Remove Nearset checkpoint", "2")
	menu_addblank(g_iMenu, 0)
	menu_additem(g_iMenu, "Remove All checkpoints", "3")
	menu_addblank(g_iMenu, 0)
	menu_additem(g_iMenu, "Highlight CheckPoints", "4")
	menu_addblank(g_iMenu, 0)
	menu_additem(g_iMenu, "Save", "5")
	menu_additem(g_iMenu, "Load checkpoints", "6")
	
	// Setting Cvars
	set_cvar_num("mp_friendlyfire", 1)
	set_cvar_num("mp_tkpunish", 0)
	g_pRespawnTime = register_cvar("cp_respawn_time", "3")
	g_pAutoSave = register_cvar("cp_auto_save_checkpoints", "0")
	
	// Others
	LoadChecks()
}

public client_connect(id)
{
	g_iCreateEnt[id] = 0
	g_iCreateStep[id] = 0
	g_iPlayerCheckPoint[id] = NULL
	
	if(IsInBit(id, gAlive))
	{
		RemoveFromBit(id, gAlive)
	}
}

public client_putinserver(id)
{	
	g_iCounter[id] = get_pcvar_num(g_pRespawnTime) + 1
	
	set_task(4.0, "StartTimer", id)
}

public StartTimer(id)
{
	if(!g_bAllowRespawn || task_exists(id + TASKID_TIMER) || get_user_team(id) == 3 || IsInBit(id, gAlive))
	{
		return;
	}
	
	new iTaskId = id + TASKID_TIMER
	ShowTimer(iTaskId)
	set_task(1.0, "ShowTimer", iTaskId,_,_, "a", g_iCounter[id])
}

public plugin_end()
{
	if(get_pcvar_num(g_pAutoSave))
	{
		SaveAll()
	}
}

public dr_win(iWinner)
{
	g_bAllowRespawn = false
}

public eNewRound()
{
	g_bAllowRespawn = true
	arrayset(g_iPlayerCheckPoint, NULL, sizeof(g_iPlayerCheckPoint))
}

public RoundEnd()
{
	g_bAllowRespawn = false
}

public fw_TouchCheckPoint(iTouched, id)
{
	static iNum; iNum = entity_get_int(iTouched, CHECK_NUM)
	if(g_iPlayerCheckPoint[id] < iNum)
	{
		g_iPlayerCheckPoint[id] = iNum
		
		set_hudmessage(255, 255, 255, -1.0, 0.35, 2, 6.0, 6.0, 0.1, 0.1)
		show_hudmessage(id, "CheckPoint!")
		emit_sound(id, CHAN_AUTO, g_szCheckPointSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}

public fw_CheckPoint_Think(iEnt)
{	
	static iColor[3], id
	static Float:vOrigin[3], Float:vMaxs[3], Float:vMins[3]
	
	if(IsInBit(iEnt, gIsHighLightened))
	{
		iColor = { 0, 0, 255 }
		id = entity_get_int(iEnt, HIGHLIGHT_ID)
		
		entity_get_vector(iEnt, EV_VEC_origin, vOrigin)
		entity_get_vector(iEnt, EV_VEC_maxs, vMaxs)
		entity_get_vector(iEnt, EV_VEC_mins, vMins)
		
		xs_vec_add(vMaxs, vOrigin, vMaxs)
		xs_vec_add(vMins, vOrigin, vMins)
		
		fm_draw_line(vMaxs[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor, id)
		fm_draw_line(vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMins[1], vMaxs[2], iColor, id)
		fm_draw_line(vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMaxs[1], vMins[2], iColor, id)
		fm_draw_line(vMins[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor, id)
		fm_draw_line(vMins[0], vMins[1], vMins[2], vMins[0], vMaxs[1], vMins[2], iColor, id)
		fm_draw_line(vMins[0], vMins[1], vMins[2], vMins[0], vMins[1], vMaxs[2], iColor, id)
		fm_draw_line(vMins[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMins[2], iColor, id)
		fm_draw_line(vMins[0], vMaxs[1], vMins[2], vMaxs[0], vMaxs[1], vMins[2], iColor, id)
		fm_draw_line(vMaxs[0], vMaxs[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor, id)
		fm_draw_line(vMaxs[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMaxs[2], iColor, id)
		fm_draw_line(vMaxs[0], vMins[1], vMaxs[2], vMins[0], vMins[1], vMaxs[2], iColor, id)
		fm_draw_line(vMins[0], vMins[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor, id)
		
		entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 2.0)
		
		return;
	}
	
	if(g_bHighLight)
	{
		iColor = { 255, 0, 0 }
		
		entity_get_vector(iEnt, EV_VEC_origin, vOrigin)
		entity_get_vector(iEnt, EV_VEC_maxs, vMaxs)
		entity_get_vector(iEnt, EV_VEC_mins, vMins)
		
		xs_vec_add(vMaxs, vOrigin, vMaxs)
		xs_vec_add(vMins, vOrigin, vMins)
		
		fm_draw_line(vMaxs[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor)
		fm_draw_line(vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(vMins[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor)
		fm_draw_line(vMins[0], vMins[1], vMins[2], vMins[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(vMins[0], vMins[1], vMins[2], vMins[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(vMins[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(vMins[0], vMaxs[1], vMins[2], vMaxs[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(vMaxs[0], vMaxs[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor)
		fm_draw_line(vMaxs[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(vMaxs[0], vMins[1], vMaxs[2], vMins[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(vMins[0], vMins[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor)
		
		entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 2.0)
		
		return;
	}
	
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.1)
}

stock fm_draw_line(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, const iColor[3], id = 0)
{
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, .player = id ? id : 0)
	
	write_byte(TE_BEAMPOINTS)
	
	engfunc(EngFunc_WriteCoord, x1)
	engfunc(EngFunc_WriteCoord, y1)
	engfunc(EngFunc_WriteCoord, z1)
	
	engfunc(EngFunc_WriteCoord, x2)
	engfunc(EngFunc_WriteCoord, y2)
	engfunc(EngFunc_WriteCoord, z2)
	
	write_short(beampoint)
	write_byte(1)
	write_byte(1)
	write_byte(20)
	write_byte(5)
	write_byte(0)
	
	write_byte(iColor[0])
	write_byte(iColor[1])
	write_byte(iColor[2])
	
	write_byte(200)
	write_byte(0)
	
	message_end()
}

public fw_Killed(id, iAttacker, iShouldGib)
{
	if(!g_bAllowRespawn)
	{
		return;
	}
	
	RemoveFromBit(id, gAlive)
	
	g_iCounter[id] = get_pcvar_num(g_pRespawnTime) + 1
	
	new iTaskId = id + TASKID_TIMER
	ShowTimer(iTaskId)
	set_task(1.0, "ShowTimer", iTaskId,_,_, "a", g_iCounter[id])
}

public ShowTimer(id)
{
	id -= TASKID_TIMER
	
	if(!is_user_connected(id) || IsInBit(id, gAlive) || !g_bAllowRespawn)
	{
		remove_task(id + TASKID_TIMER)
		return;
	}
	
	if(--g_iCounter[id] == 0)
	{
		Respawn(id)
		return;
	}
	
	set_hudmessage(255, 255, 255, -1.0, 0.35, 0, 0.0, 1.0, 0.0, 0.0)
	
	if(g_iPlayerCheckPoint[id] > -1)
	{
		show_hudmessage(id, "Respawning to checkpoint #%d IN^n%d seconds", g_iPlayerCheckPoint[id] + 1, g_iCounter[id])
	}
	
	else
	{
		show_hudmessage(id, "Respawning IN^n%d seconds", g_iCounter[id])
	}
}

public Respawn(id)
{
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	AddToBit(id, gAlive)
	
	static iNum
	if( ( iNum = g_iPlayerCheckPoint[id] ) < 0 || !g_iCheckPointEnt[iNum])
	{
		return;
	}
	
	SpawnToCheckPoint(id, iNum)
}

stock SpawnToCheckPoint(id, iNum)
{
	static Float:vCPOrigin[3], Float:vCPMins[3], Float:vCPMaxs[3], iEnt, Float:vSpawnOrigin[3], Float:vPlayerSize[2][3], Float:flNum
	entity_get_vector((iEnt = g_iCheckPointEnt[iNum]), EV_VEC_origin, vCPOrigin)
	entity_get_vector(iEnt, EV_VEC_mins, vCPMins)
	entity_get_vector(iEnt, EV_VEC_maxs, vCPMaxs)
	
	entity_get_vector(id, EV_VEC_mins, vPlayerSize[1])
	entity_get_vector(id, EV_VEC_maxs, vPlayerSize[0])
	
	for(new i; i < 2; i++)
	{
		vSpawnOrigin[i] = (flNum = GetRandomSpawn(vCPOrigin[i] + vCPMaxs[i], vCPOrigin[i] + vCPMins[i], vPlayerSize[0][i], vPlayerSize[1][i] * -1.0) ) == -1 ? vCPOrigin[i] : flNum
	}
	
	vSpawnOrigin[2] = vCPOrigin[2]

	static Float:vTraceEnd[3]
	xs_vec_copy(vSpawnOrigin, vTraceEnd)
	
	vTraceEnd[2] = -9999.0
	
	new iTr = create_tr2()
	
	engfunc(EngFunc_TraceLine, vSpawnOrigin, vTraceEnd, IGNORE_MONSTERS, id, iTr)

	static Float:flFraction
	get_tr2(iTr, TR_flFraction, flFraction)

	if(flFraction == 1.0)
	{
		client_print(id, print_chat, "[DEBUG] No good origin to go to")
		free_tr2(iTr)
		
		return;
	}

	get_tr2(iTr, TR_vecEndPos, vSpawnOrigin)
	free_tr2(iTr)
	
	// No need to add MAXS
	//xs_vec_add(vSpawnOrigin, vPlayerSize[0], vSpawnOrigin)
	xs_vec_mul_scalar(vPlayerSize[1], -1.0, vPlayerSize[1])
	
	vSpawnOrigin[2] += vPlayerSize[1][2]
	
	entity_set_origin(id, vSpawnOrigin)
	UTIL_UnstickPlayer(id, 32, 128)
}

stock Float:GetRandomSpawn( Float:flMaxDis, Float:flMinDis, Float:flPlayerMins, Float:flPlayerMaxs)
{
	static Float:flOrigin, iGot
	iGot = 10, flOrigin = 0.0
	
	while(iGot)
	{
		flOrigin = random_float(flMaxDis, flMinDis)
		
		if(flMinDis <= flOrigin <= flMaxDis && flMaxDis - flOrigin >= flPlayerMaxs && flOrigin - flMinDis > flPlayerMins)
		{
			break;
		}
		
		iGot--
	}
	
	return iGot ? flOrigin : -1.0
}

public fw_Think(id)
{
	if(!IsInBit(id, gAlive))
	{
		return;
	}
	
	static iNum
	if( !( iNum = g_iCreateStep[id] ) )
	{
		return;
	}
	
	// Clicked +use key
	if( pev(id, pev_button) & IN_USE && !(pev(id, pev_oldbuttons) & IN_USE))
	{
		switch(iNum)
		{
			case 1:
			{
				if(GetHitOrigin(id, g_flCreateOrigins[id][iNum - 1]))
				{
					client_print(id, print_chat, "%s Now aim at the other side and hit +use key", PREFIX)
					g_iCreateStep[id] = 2
					
					return;
				}
				
				else
				{
					client_print(id, print_chat, "%s Aim somewhere good for a checkpoint", PREFIX)
				}
			}
				
			case 2:
			{
				if(GetHitOrigin(id, g_flCreateOrigins[id][iNum - 1]))
				{
					new Float:flMins[3], Float:flMaxs[3], Float:vOrigin[3], Float:flDiff
					
					for(new i; i < 3; i++)
					{
						vOrigin[i] = (g_flCreateOrigins[id][START][i] + g_flCreateOrigins[id][END][i]) / 2.0
						
						flDiff = get_difference(g_flCreateOrigins[id][START][i], g_flCreateOrigins[id][END][i])
						flMins[i] =  flDiff / -2.0
						flMaxs[i] = flDiff / 2.0
					}
					
					g_iCreateStep[id] = 0
					
					g_iCheckPointEnt[g_iCreateEnt[id]] = CreateCheckPoint(vOrigin, flMaxs, flMins, g_iCreateEnt[id])
					g_iChecksNum++
					client_print(0, print_chat, "%s Created CheckPoint!", PREFIX)
					
					return;
				}
			}
		}		
	}
}

public HookSaid(id, level, cid)
{
	static szSaid[30]
	static const szSayCommand[] = "/checkpoints"
	read_argv(1, szSaid, charsmax(szSaid))
	
	if(!equali(szSaid, szSayCommand))
	{
		return PLUGIN_CONTINUE
	}
	
	if(!cmd_access(id, level, cid, 2))
	{
		static szFlag[5]
		if(!szFlag[0])
		{
			get_flags(level, szFlag, charsmax(szFlag))
		}
		
		client_print(id, print_chat, "** Only admins with flag ^"%s^" can use this command.", szFlag)
		return PLUGIN_CONTINUE
	}
	
	menu_display(id, g_iMenu)
	return PLUGIN_HANDLED
}

public AdminCmdCheckPoints(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}
	
	console_print(id, "Close console to view the menu.")
	menu_display(id, g_iMenu)
	
	return PLUGIN_HANDLED
}

public MainMenuHandler(id, menu, item)
{
	if(item < 0)
	{
		return;
	}
	
	new szInfo[5], iDump
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo), .callback = iDump)
	
	switch(str_to_num(szInfo))
	{
		case GO:
		{
			new menu = menu_create("Choose a CheckPoint", "GotoCheckHandler")
			
			static const iSize = sizeof(g_iCheckPointEnt)
			new szInfo[5], szItem[20]
			for(new i; i < iSize; i++)
			{
				formatex(szInfo, charsmax(szInfo), "%d", i + 1)
				formatex(szItem, charsmax(szItem), "CheckPoint #%s", szInfo)
				
				menu_additem(menu, szItem, szInfo, g_iCheckPointEnt[i] ? 0 : (1<<28) )
			}
			
			menu_display(id, menu)
		}
		
		case ADD:
		{
			new menu = menu_create("Choose a CheckPoint number", "CheckNumberHandler")
			
			static const iSize = sizeof(g_iCheckPointEnt)
			new szInfo[5], szItem[20]
			for(new i; i < iSize; i ++)
			{
				formatex(szInfo, charsmax(szInfo), "%d", i + 1)
				formatex(szItem, charsmax(szItem), "CheckPoint #%s", szInfo)
				
				menu_additem(menu, szItem, szInfo, g_iCheckPointEnt[i] ? (1<<28) : 0)
			}
			
			menu_display(id, menu)
		}
		
		case REMOVE:
		{
			new Float:vOrigin[3], menu, iEnt = -1, szTitle[55], iNum
			entity_get_vector(id, EV_VEC_origin, vOrigin)
			
			while( ( iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, 300.0 ) ) != 0)
			{
				if(!IsCheckPoint(iEnt))
				{
					continue;
				}
	
				iNum = entity_get_int(iEnt, CHECK_NUM)
				entity_set_int(iEnt, HIGHLIGHT_ID, id)
				AddToBit(iEnt, gIsHighLightened)
				
				formatex(szTitle, charsmax(szTitle), "Are you sure you want to remove^nthis CheckPoint #%d?", iNum + 1)
				menu = menu_create(szTitle, "SureHandler")
				
				formatex(szTitle, charsmax(szTitle), "%d", iNum)
				menu_additem(menu, "Yes", szTitle)
				menu_additem(menu, "No", szTitle)
				
				menu_display(id, menu)
				
				iNum = 1
				
				break;
			}
			
			if(!iNum)
			{
				client_print(id, print_chat, "%s Couldn't find any near checkpoints", PREFIX)
			}
			
			//g_iCheckPointEnt[iHitBox] = 0
		}
		
		case REMOVE_ALL:
		{
			RemoveAll()
			client_print(0, print_chat, "%s Removed all CheckPoints!", PREFIX)
		}
		
		case HIGHLIGHT:
		{
			g_bHighLight = !g_bHighLight
			
			switch(g_bHighLight)
			{
				case true:
				{
					client_print(0, print_chat, "%s CheckPoints are now highlightened and can be seen", PREFIX)
				}
				
				case false:
				{
					client_print(0, print_chat, "%s CheckPoints are unhighlightened and can't be seen", PREFIX)
				}
			}
		}
			
		case SAVE:
		{
			SaveAll()
			client_print(0, print_chat, "%s Successfully saved all CheckPoints", PREFIX)
		}
		
		case LOAD:
		{
			RemoveAll()
			LoadChecks()
			
			client_print(0, print_chat, "%s Loaded %d CheckPoints", PREFIX, g_iChecksNum)
		}
	}
}

public SureHandler(id, menu, item)
{
	new szInfo[5], iDump
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo), .callback = iDump)
	menu_destroy(menu)
	
	iDump = str_to_num(szInfo)
	
	if(item < 0)
	{
		RemoveFromBit(g_iCheckPointEnt[iDump], gIsHighLightened)
		return;
	}

	switch(item)
	{
		case 1:
		{
			// Do nothing
		}
		
		default:
		{
			remove_entity(g_iCheckPointEnt[iDump])
			g_iCheckPointEnt[iDump] = 0
			g_iChecksNum--
			
			client_print(0, print_chat, "%s Removed CheckPoint #%d", PREFIX, iDump + 1)
		}
	}
	
	RemoveFromBit(g_iCheckPointEnt[iDump], gIsHighLightened)
}
	

public GotoCheckHandler(id, menu, item)
{
	if(item < 0)
	{
		menu_destroy(menu)
		return;
	}
	
	new szInfo[5], iDump, iEnt
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo), .callback = iDump)
	
	menu_destroy(menu)
	
	iDump = str_to_num(szInfo) - 1
	iEnt = g_iCheckPointEnt[iDump]
	
	if(!is_valid_ent(iEnt))
	{
		return;
	}
	
	SpawnToCheckPoint(id, iDump)
	
	client_print(id, print_chat, "%s Go to CheckPoint #%d", PREFIX, iDump + 1)
}

public CheckNumberHandler(id, menu, item)
{
	if(item  < 0)
	{
		menu_destroy(menu)
		return;
	}
	
	new szInfo[5], iEnt
	menu_item_getinfo(menu, item, iEnt, szInfo, charsmax(szInfo), .callback = iEnt)
	
	menu_destroy(menu)
	
	iEnt = g_iCheckPointEnt[( g_iCreateEnt[id] = str_to_num(szInfo) - 1)]
	
	if(iEnt && is_valid_ent(iEnt))
	{
		return;
	}

	g_iCreateStep[id] = 1
	client_print(id, print_chat, "%s Aim at a corner and press +use key", PREFIX)
}

stock GetHitOrigin(id, Float:vOrigin[3])
{
	if(!is_user_connected(id))
	{
		return 0
	}
	
	new iTr = create_tr2()
				
	new Float:vTraceEnd[3], Float:vViewOfs[3]
	
	entity_get_vector(id, EV_VEC_origin, vOrigin)
	entity_get_vector(id, EV_VEC_view_ofs, vViewOfs)
	entity_get_vector(id, EV_VEC_v_angle, vTraceEnd)
	
	// Get player camera Z vector
	xs_vec_add(vOrigin, vViewOfs, vOrigin)
	
	angle_vector(vTraceEnd, ANGLEVECTOR_FORWARD, vTraceEnd)
	
	velocity_by_aim(id, 9999, vTraceEnd)
	
	xs_vec_add(vOrigin, vTraceEnd, vTraceEnd)
			
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, iTr);
				
	new Float:flFraction
	get_tr2(iTr, TR_flFraction, flFraction)
				
	if(flFraction == -1)
	{
		free_tr2(iTr)
		return 0
	}
				
	get_tr2(iTr, TR_vecEndPos, vTraceEnd)
	draw_laser(vOrigin, vTraceEnd)
	xs_vec_copy(vTraceEnd, vOrigin)

	free_tr2(iTr)
	
	return 1
}

stock draw_laser(Float:origin[3], Float:endpoint[3])
{                    
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	engfunc(EngFunc_WriteCoord, endpoint[0])
	engfunc(EngFunc_WriteCoord, endpoint[1])
	engfunc(EngFunc_WriteCoord, endpoint[2])
	write_short(beampoint)
	write_byte(0)
	write_byte(0)
	write_byte(100) // In tenths of a second.
	write_byte(10)
	write_byte(1)
	write_byte(255) // Red
	write_byte(0) // Green
	write_byte(0) // Blue
	write_byte(127)
	write_byte(1)
	message_end()
}  


stock bool:is_user_stuck(Id, &hull)
{
	static Float:Origin[3]
	pev(Id, pev_origin, Origin)
	engfunc(EngFunc_TraceHull, Origin, Origin, IGNORE_MONSTERS, pev(Id, pev_flags) & FL_DUCKING ? (hull = HULL_HEAD) : (hull = HULL_HUMAN), 0, 0)
	
	if (get_tr2(0, TR_StartSolid))
	{
		return true
	}
	
	return false
}

stock UTIL_UnstickPlayer (const id, const i_StartDistance, const i_MaxAttempts)
{
	// --| Not alive, ignore.
	if ( !IsInBit(id, gAlive ) )
	{  
		return -1
	}
	
	new hull
	if(!is_user_stuck(id, hull))
		return -1
	
	static Float:vf_OriginalOrigin[3], Float:vf_NewOrigin[3];
	static i_Attempts, i_Distance;
	
	// --| Get the current player's origin.
	pev ( id, pev_origin, vf_OriginalOrigin );
	
	i_Distance = i_StartDistance;
	
	while ( i_Distance < 1000 )
	{
		i_Attempts = i_MaxAttempts;
		
		while ( i_Attempts-- )
		{
			vf_NewOrigin[ 0 ] = random_float ( vf_OriginalOrigin[ 0 ] - i_Distance, vf_OriginalOrigin[ 0 ] + i_Distance );
			vf_NewOrigin[ 1 ] = random_float ( vf_OriginalOrigin[ 1 ] - i_Distance, vf_OriginalOrigin[ 1 ] + i_Distance );
			vf_NewOrigin[ 2 ] = random_float ( vf_OriginalOrigin[ 2 ] - i_Distance, vf_OriginalOrigin[ 2 ] + i_Distance );
			
			engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, hull, id, 0 );
			
			// --| Free space found.
			if ( get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) )
			{
				// --| Set the new origin .
				engfunc ( EngFunc_SetOrigin, id, vf_NewOrigin );
				return 1;
			}
		}
		
		i_Distance += i_StartDistance;
	}
	
	// --| Could not be found.
	return 0;
}    

stock RemoveAll()
{
	
	new iEnt = -1
	while( (iEnt = find_ent_by_class(iEnt, g_szCheckPointClassName) ) > 0)
	{
		g_iCheckPointEnt[entity_get_int(iEnt, CHECK_NUM)] = 0
		remove_entity(iEnt)
	}
}

stock SaveAll()
{
	new szFile[120]
	GetFileName(szFile, charsmax(szFile))

	new f = fopen(szFile, "w" /* Write new file if not exists or if exists */)
	
	if(!f)
	{
		fclose(f)
		return;
	}
	
	static const iSize = sizeof(g_iCheckPointEnt)
	
	new Float:flOrigin[3], Float:flMaxs[3], iEnt, szLine[256]
	
	for(new i; i < iSize; i++)
	{
		if(! ( iEnt = g_iCheckPointEnt[i] ) )
		{
			continue;
		}
		
		entity_get_vector(iEnt, EV_VEC_origin, flOrigin)
		entity_get_vector(iEnt, EV_VEC_maxs, flMaxs)
		
		#if defined DEBUG
		server_print("[%d]^n\
		%f %f %f \
		%f %f %f^n\
		^n", i + 1, \
		flOrigin[x], flOrigin[y], flOrigin[z], \
		flMaxs[x], flMaxs[y], flMaxs[z])
		server_print("Printed")
		#endif
		
		formatex(szLine, charsmax(szLine),"[%d]^n\
		%f %f %f \
		%f %f %f^n\
		^n", i + 1, \
		flOrigin[x], flOrigin[y], flOrigin[z], \
		flMaxs[x], flMaxs[y], flMaxs[z])
		
		fputs(f, szLine)
		
	}
	
	fclose(f)
}

stock LoadChecks()
{	
	new szFile[120]
	GetFileName(szFile, charsmax(szFile))
	
	new f = fopen(szFile, "r")
	
	if(!f)
	{
		server_print("[CheckPoints] No check points loaded for this map")
		fclose(f)
		return;
	}
	
	new szLine[70], Float:flCheckPointOrigin[3], szCheckPointOrigin[3][10], szCheckPointSize[2][3][10], Float:flCheckPointSize[2][3]
	new iNum = -1, iEntNum
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		
		replace_all(szLine, charsmax(szLine), "^n", "")
		
		if(!szLine[0] || szLine[0] == ';' || szLine[0] != '[')
		{
			continue;
		}
		
		replace(szLine, charsmax(szLine), "[", "")
		replace(szLine, charsmax(szLine), "]", "")
		
		iEntNum = str_to_num(szLine) - 1
		
		#if defined DEBUG
		server_print(szLine)
		#endif
		
		fgets(f, szLine, charsmax(szLine))
		replace_all(szLine, charsmax(szLine), "^n", "")
		
		#if defined DEBUG
		server_print(szLine)
		#endif
		
		parse(szLine, szCheckPointOrigin[x], 9, szCheckPointOrigin[y], 9, szCheckPointOrigin[z], 9, szCheckPointSize[0][x], 9, szCheckPointSize[0][y], 9, szCheckPointSize[0][z], 9)
		
		// Origin
		flCheckPointOrigin[x] = str_to_float(szCheckPointOrigin[x])
		flCheckPointOrigin[y] = str_to_float(szCheckPointOrigin[y])
		flCheckPointOrigin[z] = str_to_float(szCheckPointOrigin[z])
		// Maxs
		flCheckPointSize[0][x] = str_to_float(szCheckPointSize[0][x])
		flCheckPointSize[0][y] = str_to_float(szCheckPointSize[0][y])
		flCheckPointSize[0][z] = str_to_float(szCheckPointSize[0][z])
		// Mins
		//flCheckPointSize[1][z] = str_to_float(szCheckPointSize[1][z])
		//flCheckPointSize[1][z] = str_to_float(szCheckPointSize[1][z])
		//flCheckPointSize[1][z] = str_to_float(szCheckPointSize[1][z])
		
		xs_vec_mul_scalar(flCheckPointSize[0], -1.0, flCheckPointSize[1]) 
		
		
		g_iCheckPointEnt[iEntNum] = CreateCheckPoint(flCheckPointOrigin, flCheckPointSize[0], flCheckPointSize[1], iEntNum)
		
		// Search again?
		if(++iNum + 1 >= MAX_CHECK_POINTS)
		{
			break;
		}
	}
	
	g_iChecksNum = iNum + 1
	fclose(f)
}

stock GetFileName(szFile[], iLen)
{
	new szMapName[50], szDir[60]
	get_mapname(szMapName, charsmax(szMapName))
	
	get_datadir(szDir, charsmax(szDir))
	add(szDir, charsmax(szDir), "/checkpoints")
	
	if(!dir_exists(szDir))
	{
		mkdir(szDir)
		return;
	}
	
	formatex(szFile, iLen, "%s/%s.ini", szDir, szMapName)
	
	#if defined DEBUG
	server_print("[DEBUG] szMapName: %s^n[DEBUG] File: %s", szMapName, szFile)
	#endif
}

stock Float:get_difference(Float:flNum, Float:flNum2)
{
	new Float:flRet = flNum - flNum2
	return (flRet >= 0 ? flRet : flRet * -1.0)
}

stock IsCheckPoint(iEnt)
{
	static const iSize = sizeof(g_iCheckPointEnt)
	for(new i; i < iSize; i++)
	{
		if(g_iCheckPointEnt[i] == iEnt)
		{
			return 1
		}
	}
	
	return 0
}

stock CreateCheckPoint( Float:flOrigin[3], Float:flMaxs[3], Float:flMins[3], iNum)
{
	new iEnt = create_entity("info_target")
	
	if(!is_valid_ent(iEnt))
	{
		server_print("[DEBUG] Failed to create CheckPoint entity.")
		return 0
	}
	
	entity_set_string(iEnt, EV_SZ_classname, g_szCheckPointClassName)

	dllfunc(DLLFunc_Spawn, iEnt)
	
	entity_set_origin(iEnt, flOrigin)
	
	#if defined DEBUG
	server_print("flMins %f %f %f^nflMaxs %f %f %f^nflOrigin %f %f %f", flMins[0], flMins[1], flMins[2], flMaxs[0], flMaxs[1], flMaxs[2], flOrigin[0], flOrigin[1], flOrigin[2])
	#endif

	entity_set_size(iEnt, flMins, flMaxs)
	
	entity_set_int(iEnt, EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY)
	entity_set_float(iEnt, EV_FL_framerate, 15.0)
	set_pev(iEnt,pev_gaitsequence,0)
	set_pev(iEnt,pev_sequence,0)
	entity_set_int(iEnt, CHECK_NUM, iNum)
	
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.1)
	
	#if defined DEBUG
	server_print("[DEBUG] Created Entity %d", iEnt)
	#endif
	
	if(IsInBit(iEnt, gIsHighLightened))
	{
		RemoveFromBit(iEnt, gIsHighLightened)
	}
	
	return iEnt
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
