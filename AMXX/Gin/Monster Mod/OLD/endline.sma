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

new const PREFIX[] = "[AMXX]"
new const g_szCheckPointClassName[] = "EndGameLimit"

new g_iEndGameEnt
new g_iMenu

new g_iCreateStep[33], Float:g_flCreateOrigins[33][2][3], g_iCreateEnt[33]
new g_iCheckPointEnt
new bool:g_bHighLight = false, bool:g_bAllowRespawn = false

new g_pRespawnTime, g_pAutoSave

enum
{
	ADD,
	REMOVE,
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

public plugin_precache()
{
	beampoint = precache_model("sprites/laserbeam.spr")
}

public plugin_init() {
	register_plugin .author = "Khalid :)", .plugin_name = "Limit End", .version = VERSION

	register_concmd("amx_endgameline", "AdminCmdCheckPoints", ACCESS)
	register_clcmd("say", "HookSaid", ACCESS)
	
	RegisterHam(Ham_Player_PreThink, "player", "fw_Think", 1)
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_Killed", 1)
	
	register_touch(g_szCheckPointClassName, "player", "fw_TouchCheckPoint")
	
	register_think(g_szCheckPointClassName, "fw_CheckPoint_Think")
	
	// Menu
	g_iMenu = menu_create("Choose an option", "MainMenuHandler")
	
	menu_additem(g_iMenu, "Add an EndLine", "1")
	menu_additem(g_iMenu, "Remove EndLine", "2")
	menu_addblank(g_iMenu, 0)
	menu_additem(g_iMenu, "Highlight End Line", "3")
	menu_addblank(g_iMenu, 0)
	menu_additem(g_iMenu, "Save", "4")
	menu_additem(g_iMenu, "Load", "5")
	
	// Others
	LoadChecks()
}

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	AddToBit(id, gAlive);
}

public fw_Killed(id)
{
	RemoveFromBit(id, gAlive);
}

public client_connect(id)
{
	g_iCreateEnt[id] = 0
	g_iCreateStep[id] = 0
	
	if(IsInBit(id, gAlive))
	{
		RemoveFromBit(id, gAlive)
	}
}

new g_iTouch = 0
public fw_TouchCheckPoint(iTouched, id)
{
	if(g_iTouch)
	{
		server_print("sss");
		return;
	}
	
	server_print("Here");
	
	g_iTouch = 1
	
	new f = fopen("addons/amxmodx/configs/maps.ini", "r");
	
	if(!f)
	{
		g_iTouch = 0
		return;
	}
	
	new iLook
	new szLine[50], szMapName[50]
	get_mapname(szMapName, charsmax(szMapName))
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine));
		trim(szLine);
		
		if(!iLook && equal(szLine, szMapName))
		{
			fgets(f, szLine, charsmax(szLine));
			trim(szLine);
			
			if(is_map_valid(szLine))
			{
				remove_entity(iTouched);
				
				set_task(0.1, "Change",_, szLine, charsmax(szLine))
				//server_exec();
				return;
			}
			
			fgets(f, szLine, charsmax(szLine));
			trim(szLine);
		}
		
		if(is_map_valid(szLine))
		{
			remove_entity(iTouched);
				
			set_task(0.1, "Change",_, szLine, charsmax(szLine))
			//server_exec();
			return;
		}
		
		if(feof(f))
		{
			iLook = 1
			fseek(f, SEEK_SET, 0);
		}
	}	
}

public Change(szParam[])
{
	server_cmd("changelevel %s", szParam);
}

public fw_CheckPoint_Think(iEnt)
{	
	static iColor[3]
	static Float:vOrigin[3], Float:vMaxs[3], Float:vMins[3]
	
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
					client_print(id, print_chat, "%s Aim somewhere good for a endline", PREFIX)
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
					
					g_iCheckPointEnt = CreateCheckPoint(vOrigin, flMaxs, flMins)
					client_print(0, print_chat, "%s Created EndLine!", PREFIX)
					
					menu_display(id, g_iMenu);
					return;
				}
			}
		}		
	}
}

public HookSaid(id, level, cid)
{
	static szSaid[30]
	static const szSayCommand[] = "/endline"
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
	
	
	iDump = 0
	switch(item)
	{
		case ADD:
		{
			g_iCreateStep[id] = 1
			client_print(id, print_chat, "%s Aim at a corner and press +use key", PREFIX)
			
			iDump = 1

		}
		
		case REMOVE:
		{
			RemoveAll()
			client_print(0, print_chat, "%s Removed End Line!", PREFIX)
		}
		
		case HIGHLIGHT:
		{
			g_bHighLight = !g_bHighLight
			
			switch(g_bHighLight)
			{
				case true:
				{
					menu_item_setname(menu, item, "\rUN-\wHighlight End Line")
					client_print(0, print_chat, "%s EndLine is now highlightened and can be seen", PREFIX)
				}
				
				case false:
				{
					
					menu_item_setname(menu, item, "Highlight End Line")
					client_print(0, print_chat, "%s EndLine unhighlightened and can't be seen", PREFIX)
				}
			}
			
		}
			
		case SAVE:
		{
			SaveAll()
			client_print(0, print_chat, "%s Successfully saved endline", PREFIX)
		}
		
		case LOAD:
		{
			RemoveAll()
			LoadChecks()
			
			client_print(0, print_chat, "%s Loaded Endline file", PREFIX)
		}
	}
	if(!iDump)
	{
		menu_display(id, menu);
	}
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

stock Float:get_difference(Float:flNum, Float:flNum2)
{
	new Float:flRet = flNum - flNum2
	return (flRet >= 0 ? flRet : flRet * -1.0)
}

stock RemoveAll()
{
	new iEnt
	while( (iEnt = find_ent_by_class(iEnt,  g_szCheckPointClassName) ) )
	{
		remove_entity(iEnt)
	}
	
	g_iCheckPointEnt = 0
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
	
	new Float:flOrigin[3], Float:flMaxs[3], iEnt, szLine[256]
	
	
	while(( iEnt = find_ent_by_class(iEnt, g_szCheckPointClassName) ))
	{
		entity_get_vector(iEnt, EV_VEC_origin, flOrigin)
		entity_get_vector(iEnt, EV_VEC_maxs, flMaxs)
		
		new szMapName[32]; get_mapname(szMapName, 31)
			
		#if defined DEBUG
		server_print("%f %f %f \
		%f %f %f^n\
		^n",
		flOrigin[x], flOrigin[y], flOrigin[z], \
		flMaxs[x], flMaxs[y], flMaxs[z])
		server_print("Printed")
		#endif
			
		formatex(szLine, charsmax(szLine),"%f %f %f \
		%f %f %f^n\
		^n",
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
		server_print("[EndLine] No EndLine loaded for this map")
		fclose(f)
		return;
	}
	
	new szLine[70], Float:flCheckPointOrigin[3], szCheckPointOrigin[3][10], szCheckPointSize[2][3][10], Float:flCheckPointSize[2][3]
	
	new szMapName[32]; get_mapname(szMapName, 31);
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		
		replace_all(szLine, charsmax(szLine), "^n", "")
		
		if(!szLine[0] || szLine[0] == ';')
		{
			continue;
		}
		
		#if defined DEBUG
		server_print(szLine)
		#endif
		
		//fgets(f, szLine, charsmax(szLine))
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
		
		
		g_iCheckPointEnt = CreateCheckPoint(flCheckPointOrigin, flCheckPointSize[0], flCheckPointSize[1])
	}

	fclose(f)
}

stock GetFileName(szFile[], iLen)
{
	new szMapName[50], szDir[60]
	get_mapname(szMapName, charsmax(szMapName))
	
	get_datadir(szDir, charsmax(szDir))
	add(szDir, charsmax(szDir), "/endline")
	
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

stock CreateCheckPoint( Float:flOrigin[3], Float:flMaxs[3], Float:flMins[3])
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
	
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.1)
	
	#if defined DEBUG
	server_print("[DEBUG] Created Entity %d", iEnt)
	#endif
	
	return iEnt
}
