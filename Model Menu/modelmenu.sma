#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "Khalid"

#define MODEL_KEY	"model"
#define MAX_MODEL_LENGTH 35

#define SetUserConnected(%1)		g_bConnected |= 1<<(%1 & 31)
#define SetUserNotConnected(%1)		g_bConnected &= ~( 1<<(%1 & 31) )
#define IsUserConnected(%1)		( g_bConnected &  1<<(%1 & 31) )

#define SetUserModeled(%1)		g_bModeled |= 1<<(%1 & 31)
#define SetUserNotModeled(%1)		g_bModeled &= ~( 1<<(%1 & 31) )
#define IsUserModeled(%1)		( g_bModeled &  1<<(%1 & 31) )

new const RESET_KEY[] =	"RESET";
#define RESET_VALUE	-1
#define MAX_MODEL_NAME	64

#define PREFIX "^x04[UaE-Gaming]"

new Array:g_hMenusArray;
new Array:g_hFlagsArray;
new Array:g_hModelsArray;

new g_hMainMenu;

new g_bConnected;
new g_bModeled;

new g_hLastMenu[33];

new g_iPlayerModel[33];

GetIndexFromMenuId(hMenuHandler)
{
	new iSize = ArraySize(g_hMenusArray);
	
	for(new i; i < iSize; i++)
	{
		if(ArrayGetCell(g_hMenusArray, i) == hMenuHandler)
		{
			return i;
		}
	}
	
	return -1;
}

GetMenuIdFromIndex(iIndex)
{
	return ArrayGetCell(g_hMenusArray, iIndex);
}

public plugin_precache()
{
	g_hMenusArray = ArrayCreate(1);
	g_hFlagsArray = ArrayCreate(1);
	g_hModelsArray = ArrayCreate(MAX_MODEL_LENGTH);
	
	ReadFile();
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Spawn, "player", "HamCallback_PlayerSpawn", 1);
	
	register_forward(FM_SetClientKeyValue, "SetClientKeyValue");
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse");
	
	register_clcmd("say /model_menu", "ClCmd_ShowModelMenu");
	register_clcmd("say /models", "ClCmd_ShowModelMenu");
	register_clcmd("say /model", "ClCmd_ShowModelMenu");
}

public plugin_end()
{
	new iSize = ArraySize(g_hMenusArray);
	for(new i; i < iSize; i++)
	{
		menu_destroy(ArrayGetCell(g_hMenusArray, i));
	}
	
	ArrayDestroy(g_hMenusArray);
	ArrayDestroy(g_hFlagsArray);
	ArrayDestroy(g_hModelsArray);
}

public HamCallback_PlayerSpawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	ApplyModel(id);
}

public client_putinserver(id)
{
	SetUserConnected(id);
	g_iPlayerModel[id] = RESET_VALUE;
}

public client_disconnected(id)
{
	SetUserNotModeled(id);
	SetUserNotConnected(id);
}

public ClCmd_ShowModelMenu(id)
{
	menu_display(id, g_hMainMenu);
}

public Message_ClCorpse()
{
	#define ClCorpse_ModelName 1
	#define ClCorpse_PlayerID 12
	new id = get_msg_arg_int(ClCorpse_PlayerID);
	
	if( g_iPlayerModel[id] != RESET_VALUE )
	{
		new szModel[MAX_MODEL_LENGTH];
		ArrayGetString(g_hModelsArray, g_iPlayerModel[id], szModel, charsmax(szModel));
		set_msg_arg_string(ClCorpse_ModelName, szModel);
	}
}

public SetClientKeyValue(id, const szInfoBuffer[], const szKey[], const szValue[])
{
	if( equal(szKey, MODEL_KEY) && IsUserConnected(id) )
	{
		if( IsUserModeled(id) )
		{
			SetUserNotModeled(id);
			return FMRES_IGNORED;
		}
		
		if(g_iPlayerModel[id] == RESET_VALUE)
		{
			return FMRES_IGNORED;
		}
		
		new szSupposedModel[MAX_MODEL_LENGTH];
		ArrayGetString(g_hModelsArray, g_iPlayerModel[id], szSupposedModel, charsmax(szSupposedModel))
		
		if(!equali(szValue, szSupposedModel))
		{
			SetUserModeled(id);
			set_user_info(id, MODEL_KEY, szSupposedModel);

			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public MenuHandler_Main(id, menu, item)
{
	if(item < 0)
	{
		return;
	}
	
	new szInfo[11], iDump;
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo), .callback = iDump);

	if(equal(szInfo, RESET_KEY))
	{
		PrintMsg(id, "Your model has been reset");
		
		g_iPlayerModel[id] = RESET_VALUE;
		menu_display(id, menu);
		return;
	}
	new hChosenMenu = GetMenuIdFromIndex(str_to_num(szInfo));
	g_hLastMenu[id] = hChosenMenu;
	menu_display(id, hChosenMenu);
}

public MenuHandler_SubMenu(id, menu, item)
{
	if(item < 0)
	{
		if(item == MENU_EXIT)
		{
			menu_display(id, g_hMainMenu);
		}
		
		return;
	}
	
	if(!HasAccess(id, menu))
	{
		PrintMsg(id, "You do not have access to this menu");
		
		menu_display(id, g_hMainMenu);
		return;
	}
	
	new szInfo[4], iModelIndex, szModelName[MAX_MODEL_NAME];
	menu_item_getinfo(menu, item, iModelIndex, szInfo, charsmax(szInfo), szModelName, charsmax(szModelName), iModelIndex);

	iModelIndex = str_to_num(szInfo);
	
	g_iPlayerModel[id] = iModelIndex;
	ApplyModel(id);
	
	PrintMsg(id, "Your model has been changed to: ^x03%s", szModelName);
	
	//menu_display(id, menu);
}

ApplyModel(id)
{
	if(g_iPlayerModel[id] == RESET_VALUE)
	{
		cs_reset_user_model(id);
		return;
	}
	
	new szModel[35];
	ArrayGetString(g_hModelsArray, g_iPlayerModel[id], szModel, charsmax(szModel));
	set_user_info(id, MODEL_KEY, szModel);
}

public MenuCallback_Main(id, menu, item)
{
	new szInfo[15], iDump;
	menu_item_getinfo(menu, item, iDump, szInfo, charsmax(szInfo), .callback = iDump);
	
	if(!HasAccess(id, str_to_num(szInfo)))
	{
		return ITEM_DISABLED;
	}
	
	return ITEM_ENABLED;
}

ReadFile()
{
	g_hMainMenu = menu_create("Models Menu:^n\rBy: Khalid", "MenuHandler_Main");
	new iCallback = menu_makecallback("MenuCallback_Main");
	//menu_item_setcall
	
	menu_additem(g_hMainMenu, "Reset Model", RESET_KEY);
	ArrayPushCell(g_hMenusArray, g_hMainMenu);
	ArrayPushCell(g_hFlagsArray, -1);
	
	new FILE_PATH[] = "addons/amxmodx/configs/model_menu.ini";
	new f = fopen(FILE_PATH, "r");
	
	if(!f)
	{
		fclose(f);
		fclose(f);
		CreateFile(FILE_PATH);
		
		return;
	}
	
	new szLine[256];
	new szLastMenuName[40], hLastMenuHandler;
	new szModelName[40], szModelFolderName[MAX_MODEL_LENGTH];
	new szInfo[5];
	new szSubMenuTitle[60];
	
	new iCount = 0;
	new iModelCount = -1;
	new bool:bExpectingFlags;
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine));
		trim(szLine);
		
		if(!szLine[0] || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/') || szLine[0] == '#')
		{
			continue;
		}
		
		if(bExpectingFlags)
		{
			bExpectingFlags = false;
			
			if(!IsFlagsLine(szLine, charsmax(szLine)))
			{
				//menu_destroy(hLastMenuHandler); hLastMenuHandler = 0;
				
				log_amx("[ModelMenu] Could not find flags line for menu: ^"%s^"", szLastMenuName);
				if(IsMenuNameLine(szLine, charsmax(szLine)))
				{
					bExpectingFlags = true;
					copy(szLastMenuName, charsmax(szLastMenuName), szLine);
				}
			}
			
			else
			{
				formatex(szSubMenuTitle, charsmax(szSubMenuTitle), "%s Model List:", szLastMenuName);
				hLastMenuHandler = menu_create(szSubMenuTitle, "MenuHandler_SubMenu");
				
				formatex(szInfo, charsmax(szInfo), "%d", ++iCount);
				menu_additem(g_hMainMenu, szLastMenuName, szInfo,_, iCallback);
				
				ArrayPushCell(g_hMenusArray, hLastMenuHandler);
				
				remove_quotes(szLine);
				ArrayPushCell(g_hFlagsArray, read_flags_custom(szLine));
			}
			
			continue;
		}
		
		if(IsMenuNameLine(szLine, charsmax(szLine)))
		{
			bExpectingFlags = true;
			copy(szLastMenuName, charsmax(szLastMenuName), szLine);
			
			continue;
		}
		
		if(hLastMenuHandler)
		{
			server_print("SZLINE: %s", szLine);
			parse(szLine, szModelName, charsmax(szModelName), szModelFolderName, charsmax(szModelFolderName));
			
			remove_quotes(szModelName);
			remove_quotes(szModelFolderName);
			
			if(!precache_model_custom(szModelFolderName))
			{
				continue;
			}
			
			server_print("Added model %s", szModelFolderName);
			ArrayPushString(g_hModelsArray, szModelFolderName);
			formatex(szInfo, charsmax(szInfo), "%d", ++iModelCount);
			menu_additem(hLastMenuHandler, szModelName, szInfo);
		}
	}
}

bool:IsFlagsLine(szLine[], iSize)
{
	new szFirstArg[35], szSecArg[35], szThirdArg[35];
	parse(szLine, szFirstArg, charsmax(szFirstArg), szSecArg, charsmax(szSecArg), szThirdArg, charsmax(szThirdArg));
	
	remove_quotes(szFirstArg);
	remove_quotes(szSecArg);
	remove_quotes(szThirdArg);
	
	if(equal(szFirstArg, "FLAGS") && szSecArg[0] == '=')
	{
		copy(szLine, iSize, szThirdArg);
		
		server_print("szFlagsLine = %s", szLine);
		return true;
	}
	
	return false;
}

bool:IsMenuNameLine(szLine[], iSize)
{
	if(szLine[0] == '[' && szLine[strlen(szLine) - 1] == ']')
	{
		replace(szLine, iSize, "]", "");
		replace(szLine, iSize, "[", "");
		
		return true;
	}
	
	return false;
}

bool:HasAccess(id, hMenu)
{
	new iIndex = GetIndexFromMenuId(hMenu);
	new iAccess = ArrayGetCell(g_hFlagsArray, iIndex);
	
	if(iAccess == -1 || get_user_flags(id) & iAccess)
	{
		return true;
	}
	
	return false;
}

bool:precache_model_custom(szModelFolderName[])
{
	
	new szModelPath[128];
	formatex(szModelPath, charsmax(szModelPath), "models/player/%s/%s.mdl", szModelFolderName, szModelFolderName);
	
	if(!file_exists(szModelPath))
	{
		log_amx("Skipping model (not found) %s - %s", szModelFolderName, szModelPath);
		return false;
	}
	
	precache_model(szModelPath);
	formatex(szModelPath, charsmax(szModelPath), "models/player/%s/%sT.mdl", szModelFolderName, szModelFolderName);
	
	if(file_exists(szModelPath))
	{
		log_amx("Found modelT for %s, precaching", szModelFolderName);
		precache_model(szModelPath);
	}
	
	return true;
}

CreateFile(szFile[])
{
	new f = fopen(szFile, "w+");
	
	fprintf(f, "; Model Menu. By Khalid^n");
	fprintf(f, "; Any line starting with ; or # or // is a comment line and the plugin won't proccess that line^n");
	fprintf(f, "; To setup the menu, follow the instuctions:^n");
	fprintf(f, "; [Menu Name]^n");
	fprintf(f, "; FLAGS = abd^n");
	fprintf(f, "; ^"Model 1^" ^"model folder name 1^"^n");
	fprintf(f, "; ^"Model 2^" ^"model folder name 1^"^n");
	fprintf(f, ";^n");
	fprintf(f, "; Notes:^n");
	fprintf(f, "; * Make sure that the FLAGS = line exists.^n");
	fprintf(f, "; * If you want to make a menu accessible to any one, put the flags as ANY. Example:^n");
	fprintf(f, "; FLAGS = ANY^n");
	fprintf(f, ";^n");
	fprintf(f, "; Start editing here:^n");
	
	fclose(f); fclose(f);
}

stock read_flags_custom(szFlags[])
{
	if(containi(szFlags, "ANY") != -1)
	{
		return -1;
	}
	
	return read_flags(szFlags);
}

PrintMsg(id, szMessage[], any:...)
{
	new szBuffer[192];
	new iLen = formatex(szBuffer, charsmax(szBuffer), "%s ^x01", PREFIX);
	
	vformat(szBuffer[iLen], charsmax(szBuffer) - iLen, szMessage, 3);
	client_print_color(id, print_team_default, szBuffer);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
