#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <cstrike>
#include <smlib> 
#include <sdkhooks>
#include <multicolors>

//#include <hosties>
//#include <lastrequest>

#define ST_SQL 0
#define ST_COOKIES 1

#define KATANA_ENABLED
#define SAVE_TYPE 	ST_COOKIES
#define KATANA_SAVE_TYPE ST_COOKIES

#if SAVE_TYPE == ST_COOKIES || KATANA_SAVE_TYPE == ST_COOKIES
#include <clientprefs>
#endif

// Not Done
//#define LOG_CREDITS_ACTIONS

#if SAVE_TYPE == ST_SQL
new String:g_szLastQuery[512];
new Handle:g_hSql;

new const String:TABLE_NAME[] = "jb_shop";

enum
{
	Field_SteamID, 
	Field_Credits, 
	Field_Katana, 
	
	Field_Total
};
new const String:TABLE_FIELD[Field_Total][] =  {
	"steamid", 
	"credits",
	"katana"
};
#endif

new bool:g_Ivisivel[MAXPLAYERS + 1] =  { false, ... };
new bool:g_Godmode[MAXPLAYERS + 1] =  { false, ... };
new bool:poison[MAXPLAYERS + 1] =  { false, ... };
new bool:vampire[MAXPLAYERS + 1] =  { false, ... };
//new bool:super_faca[MAXPLAYERS+1] = {false, ...};
new bool:view[MAXPLAYERS + 1] =  { false, ... };
new bool:fogo[MAXPLAYERS + 1] =  { false, ... };
new bool:AWP[MAXPLAYERS + 1] =  { true, ... };
new bool:EAGLE[MAXPLAYERS + 1] =  { true, ... };
new bool:bhop[MAXPLAYERS + 1] =  { false, ... };
new bool:Spell[MAXPLAYERS + 1] =  { false, ... };
new Laser = -1;

new g_Kedavra = -1;

#define VERSION "Private version"

new g_iCreditos[MAXPLAYERS + 1];

new iEnt;
new String:EntityList[][] =  {
	
	"func_door", 
	"func_rotating", 
	"func_walltoggle", 
	"func_breakable", 
	"func_door_rotating", 
	"func_movelinear", 
	"prop_door", 
	"prop_door_rotating", 
	"func_tracktrain", 
	"func_elevator", 
	"\0"
};

new Handle:cvarCreditosMax = INVALID_HANDLE;
new Handle:cvarCreditosKill_CT = INVALID_HANDLE;
new Handle:cvarCreditosKill_T = INVALID_HANDLE;
new Handle:cvarCreditos_LR = INVALID_HANDLE;
new Handle:cvarCreditosKill_CT_VIP = INVALID_HANDLE;
new Handle:cvarCreditosKill_T_VIP = INVALID_HANDLE;
new Handle:cvarCreditos_LR_VIP = INVALID_HANDLE;
new Handle:cvarCreditos_Kedavra = INVALID_HANDLE;
new Handle:cvarCreditosSave = INVALID_HANDLE;
new Handle:cvarTronly = INVALID_HANDLE;
new Handle:cvarEnableRevive = INVALID_HANDLE;
new Handle:cvarSpawnMsg = INVALID_HANDLE;
new Handle:cvarCreditsOnWarmup = INVALID_HANDLE;
new Handle:cvarMinPlayersToGetCredits = INVALID_HANDLE;

new Handle:cvar_0;
new Handle:cvar_1;
new Handle:cvar_2;
new Handle:cvar_3;
new Handle:cvar_4;
new Handle:cvar_5;
new Handle:cvar_6;
new Handle:cvar_7;
//new Handle:cvar_8;
new Handle:cvar_9;
new Handle:cvar_10;
new Handle:cvar_11;
new Handle:cvar_12;
new Handle:cvar_14;
new Handle:cvar_15;
new Handle:cvar_16;
new Handle:cvar_17;
new Handle:cvar_18;
new Handle:cvar_19;
new Handle:cvar_20;

new Handle:cvar_katana_damage;

//new Handle:cvarRoundCreditos = INVALID_HANDLE;
//new Handle:cvarCrInterval = INVALID_HANDLE;

#if SAVE_TYPE == ST_COOKIES
new Handle:c_GameCreditos = INVALID_HANDLE;
#endif

#if defined KATANA_ENABLED && KATANA_SAVE_TYPE == ST_COOKIES
new Handle:c_Katana = INVALID_HANDLE;
#endif

new g_sprite;
new g_HaloSprite;

new const String:IMPOSTER_MODEL[] = "models/player/kuristaja/big_boss/big_boss.mdl";

#if defined KATANA_ENABLED
new g_iHasKatana[MAXPLAYERS + 1];

new const String:KATANA_FILES[][] = {
	"models/weapons/melee/w_katana.dx90.vtx",
	"models/weapons/melee/w_katana.phy",
	"models/weapons/melee/w_katana.vvd"
};
	
new const String:KATANA_MODEL[] = "models/weapons/melee/w_katana.mdl";
new g_iKatanaModelIndex;
#endif

public Plugin:myinfo = 
{
	name = "Shop Jail", 
	author = "Dk--", 
	description = "Comprar itens no shop jailbreak", 
	version = VERSION, 
};

public int Native_GetCredits(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if (!CheckClient(client))
	{
		return -1;
	}
	
	return g_iCreditos[client];
}

public int Native_SetCredits(Handle hPlugin, int iArgs)
{
	int client = GetNativeCell(1);
	
	if (!CheckClient(client))
	{
		return 0;
	}
	
	int iCredits = GetNativeCell(2);
	
	if (iCredits < 0)
	{
		iCredits = 0;
	}
	
	int iMaxCredits = GetConVarInt(cvarCreditosMax);
	if (iCredits > iMaxCredits)
	{
		iCredits = iMaxCredits;
	}
	
	g_iCreditos[client] = iCredits;
	return 1;
}

bool CheckClient(client)
{
	if (!(1 <= client <= MaxClients))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Index out of bounds (%d) should be < MaxClients (%d)", client, MaxClients);
		return false;
	}
	
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client not in game (%d)", client);
		return false;
	}
	
	return true;
}

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szErr, iErrMax)
{
	CreateNative("JBShop_GetCredits", Native_GetCredits);
	CreateNative("JBShop_SetCredits", Native_SetCredits);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	
	LoadTranslations("common.phrases");
	LoadTranslations("jail_shop.phrases");
	
	#if SAVE_TYPE == ST_COOKIES
	c_GameCreditos = RegClientCookie("Creditos", "Creditos", CookieAccess_Private);
	#endif
	
	#if defined KATANA_ENABLED && KATANA_SAVE_TYPE == ST_COOKIES
	c_Katana = RegClientCookie("JBShop_Katana", "Client bought katana", CookieAccess_Protected);
	#endif
	
	// ======================================================================
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("smokegrenade_detonate", Event_SmokeGrenadeDetonate, EventHookMode_Post);
	HookEvent("smokegrenade_detonate", Event_SmokeGrenadeDetonate2, EventHookMode_Post);
	HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("weapon_fire", Fire);
	// ======================================================================
	
	RegConsoleCmd("sm_shop", SHOPMENU);
	RegConsoleCmd("sm_credits", Creditos);
	RegConsoleCmd("sm_doar", Command_SendCredits);
	RegConsoleCmd("sm_gift", Command_SendCredits);
	RegConsoleCmd("sm_revive", Reviver);
	RegConsoleCmd("sm_reviver", Reviver);
	RegConsoleCmd("sm_showcredits", Command_ShowCredits);
	
	RegAdminCmd("sm_give", SetCreditos, ADMFLAG_ROOT);
	RegAdminCmd("sm_set", SetCreditos2, ADMFLAG_ROOT);
	RegAdminCmd("sm_removeall", RemoveCredits, ADMFLAG_ROOT);
	// ======================================================================
	
	// ======================================================================
	
	cvarCreditosMax = CreateConVar("shop_creditos_maximo", "500000", "Maxim of credits for player");
	cvarCreditosKill_T = CreateConVar("shop_creditos_por_kill_t", "150", "Amount of credits for kill ( prisioner )");
	cvarCreditosKill_CT = CreateConVar("shop_creditos_por_kill_ct", "15", "Amount of credits for kill ( guard )");
	cvarCreditos_LR = CreateConVar("shop_creditos_por_kill_lr", "300", "Amount of credits for the last player");
	cvarCreditosKill_T_VIP = CreateConVar("shop_creditos_por_kill_t_vip", "150", "Amount of credits for kill ( prisioner ) for VIP (flag a)");
	cvarCreditosKill_CT_VIP = CreateConVar("shop_creditos_por_kill_ct_vip", "15", "Amount of credits for kill ( guard ) for VIP (flag a)");
	cvarCreditos_LR_VIP = CreateConVar("shop_creditos_por_kill_lr_vip", "300", "Amount of credits for the last player for VIP (flag a)");
	cvarCreditos_Kedavra = CreateConVar("shop_creditos_por_kedavra certo", "300", "Amount of credits for one right avada kedavra");
	cvarSpawnMsg = CreateConVar("shop_spawnmessages", "1", "Messages on spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCreditosSave = CreateConVar("shop_creditos_save", "1", "Save or not credits on player disconnect", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTronly = CreateConVar("shop_terrorist_only", "1", "Menu for only prisioners", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarEnableRevive = CreateConVar("shop_ativar_revive", "1", "Enable/Disble revive", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCreditsOnWarmup = CreateConVar("shop_warmupcredits", "0", "Should players get credits on warmup?");
	cvarMinPlayersToGetCredits = CreateConVar("shop_minplayers", "4", "Minimum players to get credits");
	
	cvar_0 = CreateConVar("preco_00", "500000", "Price of item (Katana)");
	cvar_1 = CreateConVar("preco_01", "7000", "Price of item (invisible)");
	cvar_2 = CreateConVar("preco_02", "2000", "Price of item (awp)");
	cvar_3 = CreateConVar("preco_03", "7000", "Price of item (imortal)");
	cvar_4 = CreateConVar("preco_04", "800", "Price of item (open jails)");
	cvar_5 = CreateConVar("preco_05", "4000", "Price of item (more fast)");
	cvar_6 = CreateConVar("preco_06", "3500", "Price of item (hp)");
	cvar_7 = CreateConVar("preco_07", "2000", "Price of item (eagle)");
	//	cvar_8 = CreateConVar("preco_08", "1500", "Price of item (super knife)");
	cvar_9 = CreateConVar("preco_09", "50", "Price of item (healing)");
	cvar_10 = CreateConVar("preco_10", "650", "Price of item (molotov)");
	cvar_11 = CreateConVar("preco_11", "7000", "Price of item (skin)");
	cvar_12 = CreateConVar("preco_12", "1000", "Price of item (poison smoke)");
	cvar_14 = CreateConVar("preco_14", "8000", "Price of item (smoke teleport)");
	cvar_15 = CreateConVar("preco_15", "8000", "Price of item (respawn)");
	cvar_16 = CreateConVar("preco_16", "2000", "Price of item (he with fire)");
	cvar_17 = CreateConVar("preco_17", "5000", "Price of item (bhop)");
	cvar_18 = CreateConVar("preco_18", "2500", "Price of item (low gravity)");
	cvar_19 = CreateConVar("preco_19", "1000", "Price of item (taser with 2 bullets)");
	cvar_20 = CreateConVar("preco_20", "10000", "Price of item (Kedavra)");
	
	cvar_katana_damage = CreateConVar("katana_damage", "100.0", "Katana Damage");
	
	AutoExecConfig(true, "sm_shopjail");
	
#if SAVE_TYPE == ST_SQL
	new String:szError[256];
	g_hSql = SQL_Connect("jb_shop", false, szError, sizeof szError);
	
	if (szError[0])
	{
		SetFailState("Could not connect to SQL DB: %s", szError);
		return;
	}
	
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "CREATE TABLE IF NOT EXISTS `%s` ( %s VARCHAR(60), %s INT, %s TINYINT(1) )", TABLE_NAME, 
	TABLE_FIELD[Field_SteamID], TABLE_FIELD[Field_Credits], TABLE_FIELD[Field_Katana]);
	
	SQL_TQuery(g_hSql, SQLCallback_Dump, g_szLastQuery);
#endif
	
	if (GetConVarBool(cvarCreditosSave))
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				#if SAVE_TYPE == ST_SQL
				GetCredits(client);
				#endif
				
				#if SAVE_TYPE == ST_COOKIES
				if (AreClientCookiesCached(client))
				{
					OnClientCookiesCached(client);
				}
				#endif
			}
		}
	}
}


public OnPluginEnd()
{
	if (!GetConVarBool(cvarCreditosSave))
		return;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
	
	#if SAVE_TYPE == ST_SQL
	CloseHandle(g_hSql);
	#endif
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	#if SAVE_TYPE == ST_SQL
	if (!GetConVarBool(cvarCreditosSave))
	{
		g_iCreditos[client] = 0;
		return;
	}
	
	GetCredits(client);
	#endif
	
#if defined KATANA_ENABLED
	SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
#endif
}

#if SAVE_TYPE == ST_COOKIES || ( defined KATANA_ENABLED && KATANA_SAVE_TYPE == ST_COOKIES )
public OnClientCookiesCached(client)
{
	#if SAVE_TYPE == ST_COOKIES
		if (!GetConVarBool(cvarCreditosSave))
		{
			g_iCreditos[client] = 0;
			return;
		}
	#endif
	
	new String:CreditosString[12];
	
	#if SAVE_TYPE == ST_COOKIES
		GetClientCookie(client, c_GameCreditos, CreditosString, sizeof(CreditosString));
		g_iCreditos[client] = StringToInt(CreditosString);
	#endif
	
	#if defined KATANA_ENABLED
		#if	KATANA_SAVE_TYPE == ST_COOKIES
			GetClientCookie(client, c_Katana, CreditosString, sizeof CreditosString);
			g_iHasKatana[client] = StringToInt(CreditosString);
			
			if(g_iHasKatana[client])
			{
				SDKHook(client, SDKHook_WeaponSwitchPost, WeaponHook);
			}
		#endif
		
		g_iHasKatana[client] = 0;
	#endif
}
#endif

public OnClientDisconnect(client)
{
	if (!GetConVarBool(cvarCreditosSave))
	{
		return;
	}
	
#if SAVE_TYPE == ST_COOKIES
	if (AreClientCookiesCached(client))
	{
		new String:CreditosString[12];
		FormatEx(CreditosString, sizeof(CreditosString), "%i", g_iCreditos[client]);
		SetClientCookie(client, c_GameCreditos, CreditosString);
		
	#if defined KATANA_ENABLED && KATANA_SAVE_TYPE == ST_COOKIES
		FormatEx(CreditosString, sizeof CreditosString, "%i", g_iHasKatana[client]);
		SetClientCookie(client, c_Katana, CreditosString);
	#endif
	}
#else
	#if SAVE_TYPE == ST_SQL
	SaveCredits(client);
	#endif
#endif
	
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	
#if defined KATANA_ENABLED
	SDKUnhook(client, SDKHook_WeaponSwitchPost, WeaponHook);
	SDKUnhook(client, SDKHook_TraceAttack, Hook_TraceAttack);
#endif
}

#if SAVE_TYPE == ST_SQL
GetCredits(client)
{
	new String:szClientAuthId[60];
	GetClientAuthId(client, AuthId_Steam2, szClientAuthId, sizeof szClientAuthId);
	
	#if defined KATANA_ENABLED && KATANA_SAVE_TYPE == ST_SQL
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "SELECT `%s`,`%s` FROM `%s` WHERE `%s` = '%s'", TABLE_FIELD[Field_Credits], TABLE_FIELD[Field_Katana], 
		TABLE_NAME, TABLE_FIELD[Field_SteamID], szClientAuthId);
	#else
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "SELECT `%s` FROM `%s` WHERE `%s` = '%s'", TABLE_FIELD[Field_Credits], TABLE_NAME, TABLE_FIELD[Field_SteamID], 
		szClientAuthId);
	#endif
	SQL_TQuery(g_hSql, SQLCallback_GetCredits, g_szLastQuery, client);
}

SaveCredits(client)
{
	new String:szClientAuthId[60];
	GetClientAuthId(client, AuthId_Steam2, szClientAuthId, sizeof szClientAuthId);
	
	#if defined KATANA_ENABLED && KATANA_SAVE_TYPE == ST_SQL
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "UPDATE `%s` SET `%s` = '%d', `%s` = '%d' WHERE %s = '%s'", TABLE_NAME, TABLE_FIELD[Field_Credits], 
		g_iCreditos[client], TABLE_FIELD[Field_Katana], g_iHasKatana[client], TABLE_FIELD[Field_SteamID], szClientAuthId);
	#else
	FormatEx(g_szLastQuery, sizeof g_szLastQuery, "UPDATE `%s` SET `%s` = '%d' WHERE %s = '%s'", TABLE_NAME, TABLE_FIELD[Field_Credits], 
		g_iCreditos[client], TABLE_FIELD[Field_SteamID], szClientAuthId);
	#endif
	
	SQL_TQuery(g_hSql, SQLCallback_Dump, g_szLastQuery, client);
}

bool CheckQuery(Handle hResults, const char[] szError)
{
	if (!hResults)
	{
		LogMessage("Results handle is null, Error: %s", szError);
		return false;
	}
	
	if (szError[0])
	{
		LogMessage("SQL Query Error: %s", szError);
		return false;
	}
	
	return true;
}

public void SQLCallback_GetCredits(Handle hSQL, Handle hResult, const char[] szError, int data)
{
	if (!CheckQuery(hResult, szError))
	{
		return;
	}
	
	if (!SQL_FetchRow(hResult))
	{
		new String:szClientAuthId[60];
		GetClientAuthId(data, AuthId_Steam2, szClientAuthId, sizeof szClientAuthId);
		
		FormatEx(g_szLastQuery, sizeof g_szLastQuery, "INSERT INTO `jb_shop` VALUES ( '%s', 0, 0 )");
		
		SQL_TQuery(g_hSql, SQLCallback_Dump, g_szLastQuery);
		
		g_iCreditos[data] = 0;
		return;
	}
	
	g_iCreditos[data] = SQL_FetchInt(hResult, 0);
	
	#if defined KATANA_ENABLED && KATANA_SAVE_TYPE == ST_SQL
	g_iHasKatana[data] = SQL_FetchInt(hResult, 1);
	
	if(g_iHasKatana[data])
	{
		SDKHook(data, SDKHook_WeaponSwitchPost, WeaponHook);
	}
	#endif
}

public void SQLCallback_Dump(Handle hSQL, Handle hResult, const char[] szError, any data)
{
	CheckQuery(hResult, szError);
}
#endif

public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vmt", true);
	
	//PrecacheModel("models/player/ctm_gign_variantc.mdl"); '
	
	AddFileToDownloadsTable("sound/music/spells/kedavra.mp3");
	PrecacheSound("music/spells/kedavra.mp3", true);
	
	Laser = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	PrecacheModel(IMPOSTER_MODEL);
	AddFileToDownloadsTable(IMPOSTER_MODEL);
	
#if defined KATANA_ENABLED
	g_iKatanaModelIndex = PrecacheModel(KATANA_MODEL);
	AddFileToDownloadsTable(KATANA_MODEL);
	
	for(new i; i < sizeof KATANA_FILES; i++)
	{
		AddFileToDownloadsTable(KATANA_FILES[i]);
	}
#endif
}

public Action:MensajesSpawn(Handle:timer, any:client)
{
	if (GetConVarBool(cvarSpawnMsg) && IsClientInGame(client))
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Kill");
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Type");
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetConVarInt(cvarEnableRevive))
	{
		CreateTimer(2.0, MensajesMuerte, client);
	}
	
	if (!attacker)
		return;
	
	if (attacker == client)
		return;
	
	if (!GetConVarBool(cvarCreditosKill_CT))
		return;
	
	if (!GetConVarBool(cvarCreditosKill_T))
		return;
	
	if (GetAllPlayersCount() >= GetConVarInt(cvarMinPlayersToGetCredits) && (GetConVarInt(cvarCreditsOnWarmup) != 0 || GameRules_GetProp("m_bWarmupPeriod") != 1))
	{
		if (GetClientTeam(attacker) == CS_TEAM_CT)
		{
			if (IsPlayerReservationAdmin(attacker))
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_CT_VIP);
			else
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_CT);
		}
		
		if (GetClientTeam(attacker) == CS_TEAM_T)
		{
			if (IsPlayerReservationAdmin(attacker))
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_T_VIP);
			else
				g_iCreditos[attacker] += GetConVarInt(cvarCreditosKill_T);
		}
	}
	if (GetAllPlayersCount() >= GetConVarInt(cvarMinPlayersToGetCredits) && (GetConVarInt(cvarCreditsOnWarmup) != 0 || GameRules_GetProp("m_bWarmupPeriod") != 1))
	{
		if (g_iCreditos[attacker] < GetConVarInt(cvarCreditosMax))
		{
			if (GetClientTeam(attacker) == CS_TEAM_CT)
			{
				if (IsPlayerReservationAdmin(attacker))
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t", "KillCT", g_iCreditos[attacker], GetConVarInt(cvarCreditosKill_CT_VIP));
				else
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t", "KillCT", g_iCreditos[attacker], GetConVarInt(cvarCreditosKill_CT));
			}
			
			if (GetClientTeam(attacker) == CS_TEAM_T)
			{
				if (IsPlayerReservationAdmin(attacker))
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t", "KillT", g_iCreditos[attacker], GetConVarInt(cvarCreditosKill_T_VIP));
				else
					CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t", "KillT", g_iCreditos[attacker], GetConVarInt(cvarCreditosKill_T));
			}
			
			
		}
		else
		{
			CPrintToChat(attacker, "\x0E[ SHOP ] \x04%t", "Maximo", g_iCreditos[attacker]);
			g_iCreditos[attacker] = GetConVarInt(cvarCreditosMax);
		}
	}
}

public Action:MensajesMuerte(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Reviver4", GetConVarInt(cvar_15));
	}
}

public Action:Creditos(client, args)
{
	if (client == 0)
	{
		PrintToServer("%t", "Command is in-game only");
		return;
	}
	CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Creditos", g_iCreditos[client]);
}

public Action:SHOPMENU(client, args)
{
	if (GetConVarBool(cvarTronly))
	{
		if (GetClientTeam(client) != 2)
		{
			CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Prisioneiros");
			return;
		}
		else
		{
			DID(client);
		}
	}
	else
	{
		DID(client);
	}
}

public Action:Reviver(client, args)
{
	if (client == 0)
	{
		PrintToServer("%t", "Command is in-game only");
		return;
	}
	
	if (!GetConVarBool(cvarEnableRevive))
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Ativado");
		return;
	}
	
	if (GetConVarBool(cvarTronly))
	{
		if (GetClientTeam(client) != 2)
		{
			CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Prisioneiros2");
			return;
		}
		else
		{
			if (IsClientInGame(client) && !IsPlayerAlive(client))
			{
				if (g_iCreditos[client] >= GetConVarInt(cvar_15))
				{
					
					CS_RespawnPlayer(client);
					
					g_iCreditos[client] -= GetConVarInt(cvar_15);
					
					decl String:nome[32];
					GetClientName(client, nome, sizeof(nome));
					
					CPrintToChatAll("\x0E[ SHOP ] \x04The player\x03 %s \x04has respawned by shop!", nome);
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item reviver", g_iCreditos[client], GetConVarInt(cvar_15));
				}
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Morto");
			}
		}
	}
	else
	{
		if (!IsPlayerAlive(client))
		{
			if (g_iCreditos[client] >= GetConVarInt(cvar_15))
			{
				
				CS_RespawnPlayer(client);
				
				g_iCreditos[client] -= GetConVarInt(cvar_15);
				
				decl String:nome[32];
				GetClientName(client, nome, sizeof(nome));
				
				
				CPrintToChatAll("\x0E[ SHOP ] \x04The player\x03 %s \x04has respawned by shop!", nome);
				
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item reviver", g_iCreditos[client], GetConVarInt(cvar_15));
			}
		}
		else
		{
			CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Morto");
		}
	}
}


public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker == 0 || !fogo[attacker])
		return;
	
	if (victim != attacker && attacker != 0 && attacker < MAXPLAYERS) {
		new String:sWeaponUsed[50];
		GetEventString(event, "weapon", sWeaponUsed, sizeof(sWeaponUsed));
		if (StrEqual(sWeaponUsed, "hegrenade"))
		{
			IgniteEntity(victim, 15.0);
		}
		
	}
}

public Action:Event_SmokeGrenadeDetonate2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (view[client] == true)
	{
		view[client] = false;
		if (IsClientInGame(client))
			SetClientViewEntity(client, client);
		new Float:origin[3];
		
		// Dest. location
		origin[0] = float(GetEventInt(event, "x"));
		origin[1] = float(GetEventInt(event, "y"));
		origin[2] = float(GetEventInt(event, "z"));
		
		//TELEPORT TO PLACE WHERE THE GRENADE WILL EXPLODE!
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:Event_SmokeGrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x");
	DetonateOrigin[1] = GetEventFloat(event, "y");
	DetonateOrigin[2] = GetEventFloat(event, "z");
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!poison[client])
		return;
	
	new iEntity = CreateEntityByName("light_dynamic");
	
	if (iEntity == -1)
	{
		return;
	}
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "5");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 96.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "6");
	DispatchKeyValue(iEntity, "_light", "0 255 0");
	DispatchKeyValueFloat(iEntity, "distance", 256.0);
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
	CreateTimer(20.0, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
	
	TE_SetupBeamRingPoint(DetonateOrigin, 99.0, 100.0, g_sprite, g_HaloSprite, 0, 15, 20.0, 10.0, 220.0, { 50, 255, 50, 255 }, 10, 0);
	TE_SendToAll();
	
	TE_SetupBeamRingPoint(DetonateOrigin, 99.0, 100.0, g_sprite, g_HaloSprite, 0, 15, 20.0, 10.0, 220.0, { 50, 50, 255, 255 }, 10, 0);
	TE_SendToAll();
	
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, DetonateOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
	
	CreateTimer(1.0, Timer_CheckDamage, iEntity, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	poison[client] = false;
}

public OnEntityCreated(iEntity, const String:classname[])
{
	if (StrEqual(classname, "smokegrenade_projectile"))
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
}

public OnEntitySpawned(iGrenade)
{
	new client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	if (view[client] && IsClientInGame(client))
	{
		SetClientViewEntity(client, iGrenade);
	}
}

public Action:Fire(Handle:event, const String:name[], bool:dB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (Spell[client])
	{
		decl String:weapon[64];
		
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		if (StrContains(weapon, "knife") != -1)
		{
			new target = GetClientAimTarget(client);
			
			if (0 < target < MaxClients && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(client))
			{
				CreateTimer(0.5, Timer_Slap, any:target);
				CreateTimer(1.2, Timer_Kill, any:target);
				Ray(client);
				g_Kedavra = client;
				new Float:pos[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				
				for (new i = 1; i <= GetMaxClients(); i++)
				{
					if (IsClientInGame(i))
					{
						EmitSoundToAll("music/spells/kedavra.mp3", i);
					}
				}
				
				//EmitAmbientSound("music/spells/kedavra.mp3", pos, client, SNDLEVEL_NORMAL);
				
				
				g_iCreditos[client] += GetConVarInt(cvarCreditos_Kedavra);
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Ganhou", GetConVarInt(cvarCreditos_Kedavra));
				Spell[client] = false;
			}
			else
			{
				CPrintToChat(client, "\x0E[ SHOP ] \x07%t", "Errou");
				Spell[client] = false;
				
			}
		}
		else
		{
			CPrintToChat(client, "\x0E[ SHOP ] \x07 Use a faca para lançar o poder");
		}
	}
}

public Action:Timer_Slap(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		Slap(client, 5);
	}
}

public Action:Timer_Kill(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		DealDamage(client, 100000, g_Kedavra, DMG_BULLET, "weapon_knife");
		SetEntProp(g_Kedavra, Prop_Data, "m_iFrags", GetClientFrags(g_Kedavra) + 2);
	}
}
public Action:Delete(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action:Delete2(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action:Timer_CheckDamage(Handle:timer, any:iEntity)
{
	
	if (!IsValidEdict(iEntity))
		return Plugin_Stop;
	
	new client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	
	new Float:fSmokeOrigin[3], Float:fOrigin[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fSmokeOrigin);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client))
		{
			GetClientAbsOrigin(i, fOrigin);
			if (GetVectorDistance(fSmokeOrigin, fOrigin) <= 220)
				//SDKHooks_TakeDamage(i, iGrenade, client, GetConVarFloat(g_hCVDamage), DMG_POISON, -1, NULL_VECTOR, fSmokeOrigin);
			DealDamage(i, 75, client, DMG_POISON, "weapon_smokegrenade");
		}
	}
	return Plugin_Continue;
}

stock Ray(client)
{
	decl Float:clientpos[3];
	decl Float:position[3];
	GetPlayerEye(client, position);
	GetClientEyePosition(client, clientpos);
	TE_SetupBeamPoints(clientpos, position, Laser, 0, 0, 0, 0.3, 3.0, 3.0, 10, 0.0, { 21, 178, 57, 255 }, 30);
	TE_SendToAll(0.0);
}

stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return (true);
	}
	
	CloseHandle(trace);
	return (false);
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}
/* ~~~~~~~~~~~~~~~~~ */

/* ~ Stocks > Slap ~ */
stock Slap(client, slaps)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		for (new i = 1; i <= slaps; i++)
		{
			SlapPlayer(client, 0);
		}
	}
}

stock DealDamage(nClientVictim, nDamage, nClientAttacker = 0, nDamageType = DMG_GENERIC, String:sWeapon[] = "")
// ----------------------------------------------------------------------------
{
	// taken from: http://forums.alliedmods.net/showthread.php?t=111684
	// thanks to the authors!
	if (nClientVictim > 0 && 
		IsValidEdict(nClientVictim) && 
		IsClientInGame(nClientVictim) && 
		IsPlayerAlive(nClientVictim) && 
		nDamage > 0)
	{
		new EntityPointHurt = CreateEntityByName("point_hurt");
		if (EntityPointHurt != 0)
		{
			new String:sDamage[16];
			IntToString(nDamage, sDamage, sizeof(sDamage));
			
			new String:sDamageType[32];
			IntToString(nDamageType, sDamageType, sizeof(sDamageType));
			
			DispatchKeyValue(nClientVictim, "targetname", "war3_hurtme");
			DispatchKeyValue(EntityPointHurt, "DamageTarget", "war3_hurtme");
			DispatchKeyValue(EntityPointHurt, "Damage", sDamage);
			DispatchKeyValue(EntityPointHurt, "DamageType", sDamageType);
			if (!StrEqual(sWeapon, ""))
				DispatchKeyValue(EntityPointHurt, "classname", sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt, "Hurt", (nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt, "classname", "point_hurt");
			DispatchKeyValue(nClientVictim, "targetname", "war3_donthurtme");
			
			RemoveEdict(EntityPointHurt);
		}
	}
}


public Action:DID(clientId)
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "%t", "Shop", g_iCreditos[clientId]);
	decl String:opcionmenu[124];
	
#if defined KATANA_ENABLED
	FormatEx(opcionmenu, sizeof opcionmenu, "Katana - %d Credits", GetConVarInt(cvar_0));
	AddMenuItem(menu, "option0", opcionmenu);
#endif
	
	FormatEx(opcionmenu, 124, "%T", "Invisivel", clientId, GetConVarInt(cvar_1));
	AddMenuItem(menu, "option5", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "AWP", clientId, GetConVarInt(cvar_2));
	AddMenuItem(menu, "option6", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Imortal", clientId, GetConVarInt(cvar_3));
	AddMenuItem(menu, "option8", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Jail", clientId, GetConVarInt(cvar_4));
	AddMenuItem(menu, "option9", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Rapido", clientId, GetConVarInt(cvar_5));
	AddMenuItem(menu, "option10", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "HP", clientId, GetConVarInt(cvar_6));
	AddMenuItem(menu, "option12", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Eagle", clientId, GetConVarInt(cvar_7));
	AddMenuItem(menu, "option13", opcionmenu);
	
	//FormatEx(opcionmenu, 124, "%T","Super", clientId,GetConVarInt(cvar_8));
	//AddMenuItem(menu, "option14", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Cura", clientId, GetConVarInt(cvar_9));
	AddMenuItem(menu, "option15", opcionmenu);
	
	decl String:sGame[64];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "cstrike"))
	{
		FormatEx(opcionmenu, 124, "%T", "2flash", clientId, GetConVarInt(cvar_10));
		AddMenuItem(menu, "option16", opcionmenu);
	}
	else if (StrEqual(sGame, "csgo"))
	{
		FormatEx(opcionmenu, 124, "%T", "Molotov", clientId, GetConVarInt(cvar_10));
		AddMenuItem(menu, "option16", opcionmenu);
	}
	
	FormatEx(opcionmenu, 124, "%T", "Skin", clientId, GetConVarInt(cvar_11));
	AddMenuItem(menu, "option17", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Smoke", clientId, GetConVarInt(cvar_12));
	AddMenuItem(menu, "option18", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Teletransportadora3", clientId, GetConVarInt(cvar_14));
	AddMenuItem(menu, "option20", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "HE", clientId, GetConVarInt(cvar_16));
	AddMenuItem(menu, "option21", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Bhop", clientId, GetConVarInt(cvar_17));
	AddMenuItem(menu, "option22", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Gravity", clientId, GetConVarInt(cvar_18));
	AddMenuItem(menu, "option23", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Taser", clientId, GetConVarInt(cvar_19));
	AddMenuItem(menu, "option24", opcionmenu);
	
	FormatEx(opcionmenu, 124, "%T", "Kedavra", clientId, GetConVarInt(cvar_20));
	AddMenuItem(menu, "option25", opcionmenu);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:Hook_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	PrintToChat(attacker, "inflictor %d - DamageType %d - AmmoType %d", inflictor, damagetype, ammotype);
	
	new String:szClassName[60];
	
	new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(WeaponIndex))
	{
		GetEntityClassname(WeaponIndex, szClassName, sizeof szClassName);
		PrintToChat(attacker, "Classname %s", szClassName);
	}
	
	PrintToChatAll("g_iHasKatana[attacker] = %d ---- Strequal %d", g_iHasKatana[attacker],  StrEqual(szClassName, "weapon_knife"));
	if(g_iHasKatana[attacker] && StrEqual(szClassName, "weapon_knife"))
	{
		PrintToChat(attacker, "changed Damage");
		
		damage = GetConVarFloat(cvar_katana_damage);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:WeaponHook(client, weapon)
{
	new String:szClassName[60];
	if( weapon < 0 || !IsValidEntity(weapon) )
	{
		return Plugin_Continue;
	}
	
	GetEntityClassname(weapon, szClassName, sizeof szClassName);
	
	if(StrEqual(szClassName, "weapon_knife"))
	{
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", g_iKatanaModelIndex);
	}
	
	return Plugin_Continue;
	//DataPack data = CreateDataPack()
	
	//CreateTimer(0.1, Timer_ChangeModel, 
}

public Action:Timer_GiveKatana(Handle:hTimer, client)
{
	if(!IsClientInGame(client))
	{
		return;
	}
	
	if(!IsPlayerAlive(client))
	{
		return;
	}
	
	GiveKnife(client, true, true);
}

stock GiveKnife(client, bool:bStrip = false, bool:bEquip = true)
{
	new wepIdx;
	if(bStrip)
	{
		if ((wepIdx = GetPlayerWeaponSlot(client, 2)) != -1)
		{
			RemovePlayerItem(client, wepIdx);
			AcceptEntityInput(wepIdx, "Kill");
		}
	}
	
	wepIdx = GivePlayerItem(client, "weapon_knife");
	
	if(bEquip)	EquipPlayerWeapon(client, wepIdx);
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	else if (action == MenuAction_Select)
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
#if defined KATANA_ENABLED
		if( StrEqual(info, "option0"))
		{
			DID(client);
			if(g_iHasKatana[client])
			{
				CPrintToChat(client, "* You have already bought the item: Katana");
				return;
			}
				
			int iItemPrice = GetConVarInt(cvar_0);
			if(g_iCreditos[client] < iItemPrice)
			{
				CPrintToChat(client, "* You do not have enough credits (Missing %d credits).", iItemPrice - g_iCreditos[client]);
				return;
			}
			
			g_iHasKatana[client] = 1;
			g_iCreditos[client] -= iItemPrice;
			
			if(IsPlayerAlive(client))
			{
				GiveKnife(client, true);
			}
			
			//SDKHook(client, SDKHook_WeaponSwitch, WeaponHook);
			//SDKHook(client, SDKHook_WeaponEquip, WeaponHook);
			SDKHook(client, SDKHook_WeaponSwitchPost, WeaponHook);
			
			CPrintToChat(client, "* You have bought the Katana for %d credits.", iItemPrice);
			return;
		}
#endif
		
		if (strcmp(info, "option1") == 0)
		{
			{
				DID(client);
				CPrintToChat(client, "\x0E[ SHOP ] \x04make by dk.");
			}
		}
		
		else if (strcmp(info, "option5") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_1))
				{
					if (IsPlayerAlive(client))
					{
						decl String:sGame[255];
						GetGameFolderName(sGame, sizeof(sGame));
						
						if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
						{
							SetEntityRenderMode(client, RENDER_TRANSCOLOR);
							SetEntityRenderColor(client, 255, 255, 255, 0);
							g_Ivisivel[client] = true;
							CreateTimer(10.0, Invisible2, client);
						}
						
						else if (StrEqual(sGame, "csgo"))
						{
							SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
							g_Ivisivel[client] = true;
							CreateTimer(10.0, Invisible, client);
						}
						
						new wepIdx;
						
						// strip all weapons
						for (new s = 0; s < 4; s++)
						{
							if ((wepIdx = GetPlayerWeaponSlot(client, s)) != -1)
							{
								RemovePlayerItem(client, wepIdx);
								RemoveEdict(wepIdx);
							}
						}
						
						GivePlayerItem(client, "weapon_knife");
						SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
						g_iCreditos[client] -= GetConVarInt(cvar_1);
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Invisivel2", g_iCreditos[client], GetConVarInt(cvar_2));
					}
					
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
				}
				
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item invisivel", g_iCreditos[client], GetConVarInt(cvar_1));
				}
			}
			
		}
		
		else if (strcmp(info, "option6") == 0)
		{
			{
				DID(client);
				if (g_iCreditos[client] >= GetConVarInt(cvar_2))
				{
					if (!AWP[client])
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "MaximoAWP");
					}
					
					else if (AWP[client] && IsPlayerAlive(client))
					{
						new Weapon_Awp;
						Weapon_Awp = GivePlayerItem(client, "weapon_awp");
						SetEntProp(Weapon_Awp, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
						Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 0, _, 1);
						AWP[client] = false;
						
						g_iCreditos[client] -= GetConVarInt(cvar_2);
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "AWP2", g_iCreditos[client], GetConVarInt(cvar_2));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item awp", g_iCreditos[client], GetConVarInt(cvar_2));
				}
			}
		}
		
		else if (strcmp(info, "option8") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_3))
				{
					if (IsPlayerAlive(client))
					{
						
						g_Godmode[client] = true;
						CreateTimer(20.0, OpcionNumero16b, client);
						
						g_iCreditos[client] -= GetConVarInt(cvar_3);
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Imortal2", g_iCreditos[client], GetConVarInt(cvar_3));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item imortal", g_iCreditos[client], GetConVarInt(cvar_3));
				}
			}
		}
		
		else if (strcmp(info, "option9") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_4))
				{
					if (IsPlayerAlive(client))
					{
						
						abrir();
						
						g_iCreditos[client] -= GetConVarInt(cvar_4);
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Jails2", g_iCreditos[client], GetConVarInt(cvar_4));
						decl String:nome[32];
						GetClientName(client, nome, sizeof(nome));
						
						CPrintToChatAll("\x0E[ SHOP ] \x04Player \x03 %s \x04abriu as jails pelo shop!", nome);
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item jails", g_iCreditos[client], GetConVarInt(cvar_4));
				}
			}
		}
		
		else if (strcmp(info, "option10") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_5))
				{
					if (IsPlayerAlive(client))
					{
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
						
						g_iCreditos[client] -= GetConVarInt(cvar_5);
						vampire[client] = true;
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Rapido2", g_iCreditos[client], GetConVarInt(cvar_5));
					}
					
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
				}
				
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item rapido", g_iCreditos[client], GetConVarInt(cvar_5));
				}
			}
		}
		
		
		else if (strcmp(info, "option12") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_6))
				{
					if (IsPlayerAlive(client))
					{
						
						g_iCreditos[client] -= GetConVarInt(cvar_6);
						
						new vida = (GetClientHealth(client) + 150);
						
						SetEntityHealth(client, vida);
						GivePlayerItem(client, "item_assaultsuit"); // Give Kevlar Suit and a Helmet
						SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1); // Set kevlar armour
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "HP2", g_iCreditos[client], GetConVarInt(cvar_6));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
				}
				
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da vida", g_iCreditos[client], GetConVarInt(cvar_6));
				}
			}
		}
		else if (strcmp(info, "option13") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_7))
				{
					if (!EAGLE[client])
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "MaximoEAGLE");
					}
					
					else if (EAGLE[client] && IsPlayerAlive(client))
					{
						new Pistol_Eagle;
						Pistol_Eagle = GivePlayerItem(client, "weapon_deagle");
						SetEntProp(Pistol_Eagle, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
						Client_GiveWeaponAndAmmo(client, "weapon_deagle", _, 0, _, 7);
						EAGLE[client] = false;
						
						
						g_iCreditos[client] -= GetConVarInt(cvar_7);
						
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Eagle2", g_iCreditos[client], GetConVarInt(cvar_7));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da eagle", g_iCreditos[client], GetConVarInt(cvar_7));
				}
			}
		}
		/*
		else if (strcmp(info, "option14") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_8))
				{
					if (IsPlayerAlive(client))
					{
						decl String:sGame[255];
						GetGameFolderName(sGame, sizeof(sGame));
						if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
						{
							new currentknife = GetPlayerWeaponSlot(client, 2);
							if (IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
							{
								RemovePlayerItem(client, currentknife);
								RemoveEdict(currentknife);
							}
							
							new knife = GivePlayerItem(client, "weapon_knife");
							EquipPlayerWeapon(client, knife);
							
							super_faca[client] = true;
						}
						
						else if (StrEqual(sGame, "csgo"))
						{
							new currentknife = GetPlayerWeaponSlot(client, 2);
							if (IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
							{
								RemovePlayerItem(client, currentknife);
								RemoveEdict(currentknife);
							}
							
							new knife = GivePlayerItem(client, "weapon_knifegg");
							EquipPlayerWeapon(client, knife);
							
							super_faca[client] = true;
						}
						
						
						g_iCreditos[client] -= GetConVarInt(cvar_8);
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Super2", g_iCreditos[client], GetConVarInt(cvar_8));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da super faca", g_iCreditos[client], GetConVarInt(cvar_8));
				}
			}
			
		}*/
		
		else if (strcmp(info, "option15") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_9))
				{
					if (IsPlayerAlive(client))
					{
						new health = GetEntProp(client, Prop_Send, "m_iHealth");
						
						if (health >= 100)
						{
							CPrintToChat(client, "\x0E[ SHOP ] \x04 Your life already is full '-'");
						}
						else
						{
							SetEntityHealth(client, 100);
							g_iCreditos[client] -= GetConVarInt(cvar_9);
							
							EmitSoundToAll("medicsound/medic.wav");
							CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Curar2", g_iCreditos[client], GetConVarInt(cvar_9));
						}
						
						
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item de curar", g_iCreditos[client], GetConVarInt(cvar_9));
				}
			}
			
		}
		
		else if (strcmp(info, "option16") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_10))
				{
					if (IsPlayerAlive(client))
					{
						
						GivePlayerItem(client, "weapon_molotov");
						GivePlayerItem(client, "weapon_flashbang");
						GivePlayerItem(client, "weapon_flashbang");
						
						g_iCreditos[client] -= GetConVarInt(cvar_10);
						
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Molotov2", g_iCreditos[client], GetConVarInt(cvar_10));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da molotov", g_iCreditos[client], GetConVarInt(cvar_10));
				}
			}
		}
		
		
		
		else if (strcmp(info, "option17") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_11))
				{
					if (IsPlayerAlive(client))
					{
						g_iCreditos[client] -= GetConVarInt(cvar_11);
						SetEntityModel(client, IMPOSTER_MODEL);
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Skin2", g_iCreditos[client], GetConVarInt(cvar_11));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da skin", g_iCreditos[client], GetConVarInt(cvar_11));
				}
			}
			
		}
		
		else if (strcmp(info, "option18") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_12))
				{
					if (IsPlayerAlive(client))
					{
						
						GivePlayerItem(client, "weapon_smokegrenade");
						
						g_iCreditos[client] -= GetConVarInt(cvar_12);
						
						poison[client] = true;
						
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Smoke2", g_iCreditos[client], GetConVarInt(cvar_12));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da smoke", g_iCreditos[client], GetConVarInt(cvar_12));
				}
			}
			
		}
		
		
		
		else if (strcmp(info, "option20") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_14))
				{
					if (IsPlayerAlive(client))
					{
						
						GivePlayerItem(client, "weapon_smokegrenade");
						
						
						g_iCreditos[client] -= GetConVarInt(cvar_14);
						
						
						view[client] = true;
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Teletransportadora", g_iCreditos[client], GetConVarInt(cvar_14));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da teletransportadora", g_iCreditos[client], GetConVarInt(cvar_14));
				}
			}
			
		}
		
		else if (strcmp(info, "option21") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_16))
				{
					if (IsPlayerAlive(client))
					{
						
						GivePlayerItem(client, "weapon_hegrenade");
						
						
						g_iCreditos[client] -= GetConVarInt(cvar_16);
						
						
						fogo[client] = true;
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "HE2", g_iCreditos[client], GetConVarInt(cvar_16));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da he2", g_iCreditos[client], GetConVarInt(cvar_16));
				}
			}
			
		}
		
		else if (strcmp(info, "option22") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_17))
				{
					if (IsPlayerAlive(client))
					{
						
						g_iCreditos[client] -= GetConVarInt(cvar_17);
						
						
						bhop[client] = true;
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Bhop2", g_iCreditos[client], GetConVarInt(cvar_17));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item do bhop", g_iCreditos[client], GetConVarInt(cvar_17));
				}
			}
			
		}
		
		else if (strcmp(info, "option23") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_18))
				{
					if (IsPlayerAlive(client))
					{
						
						g_iCreditos[client] -= GetConVarInt(cvar_18);
						
						
						SetEntityGravity(client, 0.6);
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Gravity2", g_iCreditos[client], GetConVarInt(cvar_18));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da gravidade", g_iCreditos[client], GetConVarInt(cvar_18));
				}
			}
			
		}
		
		else if (strcmp(info, "option24") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_19))
				{
					if (IsPlayerAlive(client))
					{
						new Taser;
						Taser = GivePlayerItem(client, "weapon_taser");
						SetEntProp(Taser, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
						Client_GiveWeaponAndAmmo(client, "weapon_taser", _, 0, _, 3);
						g_iCreditos[client] -= GetConVarInt(cvar_19);
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Taser2", g_iCreditos[client], GetConVarInt(cvar_19));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item da taser", g_iCreditos[client], GetConVarInt(cvar_19));
				}
			}
			
		}
		
		else if (strcmp(info, "option25") == 0)
		{
			{
				DID(client);
				
				if (g_iCreditos[client] >= GetConVarInt(cvar_20))
				{
					if (IsPlayerAlive(client))
					{
						Spell[client] = true;
						g_iCreditos[client] -= GetConVarInt(cvar_20);
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Kedavra2", g_iCreditos[client], GetConVarInt(cvar_20));
					}
					else
					{
						CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Vivo");
					}
					
				}
				else
				{
					CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Item do poder", g_iCreditos[client], GetConVarInt(cvar_20));
				}
			}
		}
	}
}


public Action:SetCreditos2(client, args)
{
	if (client == 0)
	{
		PrintToServer("%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Use: sm_set <#userid|name> [amount]");
		return Plugin_Handled;
	}
	
	decl String:arg2[10];
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new amount = StringToInt(arg2);
	
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl TargetList[MAXPLAYERS], TargetCount;
	decl bool:TargetTranslate;
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
				strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	
	for (new i = 0; i < TargetCount; i++)
	{
		new iClient = TargetList[i];
		if (IsClientInGame(iClient))
		{
			g_iCreditos[iClient] = amount;
			CPrintToChat(iClient, "[ SHOP ] Set \x03%i \x01credits in the player: %N", amount, iClient);
		}
	}
	
	return Plugin_Continue;
}

public Action:RemoveCredits(client, args)
{
	if (client == 0)
	{
		PrintToServer("%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i))
		{
			g_iCreditos[i] = 0;
			CPrintToChat(i, "[ SHOP ] \x04 REMOVED ALL PLAYERS CREDITS");
		}
	}
	
	return Plugin_Continue;
}

public Action:SetCreditos(client, args)
{
	if (client == 0)
	{
		PrintToServer("%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Use: sm_give <#userid|name> [amount]");
		return Plugin_Handled;
	}
	
	decl String:arg2[10];
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new amount = StringToInt(arg2);
	
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl TargetList[MAXPLAYERS], TargetCount;
	decl bool:TargetTranslate;
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
				strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	
	for (new i = 0; i < TargetCount; i++)
	{
		new iClient = TargetList[i];
		if (IsClientInGame(iClient))
		{
			g_iCreditos[iClient] += amount;
			
			CPrintToChat(iClient, "[ SHOP ] Give \x03%i \x01credits in the player: %N", amount, iClient);
			
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_SendCredits(client, args)
{
	if (client == 0)
	{
		PrintToServer("%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Use: sm_gift <#userid|name> [amount]");
		return Plugin_Handled;
	}
	
	decl String:arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new amount = StringToInt(arg2);
	
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl TargetList[MAXPLAYERS], TargetCount;
	decl bool:TargetTranslate;
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
				strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < TargetCount; i++)
	{
		new iClient = TargetList[i];
		if (IsClientInGame(iClient) && amount > 0)
		{
			if (g_iCreditos[client] < amount)
				CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "NoCredits");
			else
			{
				g_iCreditos[client] -= amount;
				g_iCreditos[iClient] += amount;
				
				CPrintToChat(client, "[ SHOP ] You give \x03%i \x01credits for player: %N", amount, iClient);
				CPrintToChat(iClient, "[ SHOP ] You get \x03%i \x01credits from player: %N", amount, client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (g_Godmode[victim] == true)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	else if (IsValidClient(attacker))
	{
		if ((vampire[attacker] && GetClientTeam(attacker) != GetClientTeam(victim))) //&& super_faca[attacker] == false))
		{
			new recibir = RoundToFloor(damage * 0.5);
			recibir += GetClientHealth(attacker);
			SetEntityHealth(attacker, recibir);
		}
		
		/*
		if(super_faca[attacker])
		{
			decl String:weaponName[255];
			GetClientWeapon(attacker, weaponName, sizeof(weaponName));
			decl String:sGame[255];
			GetGameFolderName(sGame, sizeof(sGame));
			if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
			{
				if(StrEqual(weaponName, "weapon_knife"))
				{
					DealDamage(victim,100,attacker,DMG_BULLET,weaponName);
				}
			}
			else if (StrEqual(sGame, "csgo"))
			{
				if(StrEqual(weaponName, "weapon_knifegg"))
				{
					DealDamage(victim,100,attacker,DMG_BULLET,weaponName);
				}
			}
			
		}*/
		
	}
	
	return Plugin_Continue;
}


stock bool:IsValidClient(client, bool:bAlive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	if (IsPlayerAlive(client))
	{
		if (buttons & IN_JUMP)
		{
			if (water <= 1)
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
					SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
					if (!(GetEntityFlags(client) & FL_ONGROUND))
					{
						if (bhop[client] == true)
						{
							buttons &= ~IN_JUMP;
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}



public Action:OnWeaponCanUse(client, weapon)
{
	if (g_Ivisivel[client])
	{
		decl String:sClassname[32];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		if (!StrEqual(sClassname, "weapon_knife"))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	g_Godmode[client] = false;
	g_Ivisivel[client] = false;
	fogo[client] = false;
	//super_faca[client] = false;
	poison[client] = false;
	Spell[client] = false;
	vampire[client] = false;
	AWP[client] = true;
	EAGLE[client] = true;
	view[client] = false;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		poison[i] = false;
		vampire[i] = false;
		view[i] = false;
		Spell[i] = false;
		fogo[i] = false;
		//super_faca[i] = false;
		bhop[i] = false;
		AWP[i] = true;
		EAGLE[i] = true;
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
		return;
	}
	Normalizar(client);
	CreateTimer(1.0, MensajesSpawn, client);
	
	#if defined KATANA_ENABLED
	if(g_iHasKatana[client])
	{
		CreateTimer(0.1, Timer_GiveKatana, client);
	}
	#endif
}

Normalizar(client)
{
	if (g_Godmode[client])
	{
		g_Godmode[client] = false;
	}
	if (g_Ivisivel[client])
	{
		g_Ivisivel[client] = false;
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	
	poison[client] = false;
	vampire[client] = false;
	view[client] = false;
	fogo[client] = false;
	Spell[client] = false;
	//super_faca[client] = false;
	bhop[client] = false;
	AWP[client] = true;
	EAGLE[client] = true;
}

public OnAvailableLR(Announced)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			
			if (GetAllPlayersCount() >= GetConVarInt(cvarMinPlayersToGetCredits) && (GetConVarInt(cvarCreditsOnWarmup) != 0 || GameRules_GetProp("m_bWarmupPeriod") != 1))
			{
				if (IsPlayerReservationAdmin(i))
				{
					g_iCreditos[i] += GetConVarInt(cvarCreditos_LR_VIP);
				}
			}
			else
			{
				g_iCreditos[i] += GetConVarInt(cvarCreditos_LR);
			}
			
			SetEntityGravity(i, 1.0);
			Normalizar(i);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
}


public Action:OpcionNumero16b(Handle:timer, any:client)
{
	if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Mortal3");
		g_Godmode[client] = false;
	}
	
}

public Action:Invisible(Handle:timer, any:client)
{
	if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
	{
		g_Ivisivel[client] = false;
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Visivel novamente");
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

public Action:Invisible2(Handle:timer, any:client)
{
	if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
	{
		CPrintToChat(client, "\x0E[ SHOP ] \x04%t", "Visivel novamente");
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		g_Ivisivel[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

public Action:abrir()
{
	for (new i = 0; i < sizeof(EntityList); i++)
	while ((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
		AcceptEntityInput(iEnt, "Open");
	return Plugin_Handled;
}


public Action:Hook_SetTransmit(entity, client)
{
	if (entity != client)
		return Plugin_Handled;
	
	return Plugin_Continue;
}


public Action:Command_ShowCredits(client, args)
{
	decl String:sName[MAX_NAME_LENGTH], String:sUserId[10];
	
	new Handle:menu = CreateMenu(MenuHandlerShowCredits);
	SetMenuTitle(menu, "%t", "Players Credits");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, sName, sizeof(sName));
			IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%s: %d", sName, g_iCreditos[i]);
			AddMenuItem(menu, sUserId, buffer, ITEMDRAW_DISABLED); //sUserID to id_usera, a sName to nick ktory sie wyswietla w Menu
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandlerShowCredits(Handle:menu, MenuAction:action, param1, param2)
{
	
}

GetAllPlayersCount()
{
	decl iCount, i; iCount = 0;
	
	for (i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i))
		iCount++;
	return iCount;
}

bool:IsPlayerReservationAdmin(client)
{
	if (CheckCommandAccess(client, "Admin_Reservation", ADMFLAG_RESERVATION, false))
	{
		return true;
	}
	return false;
}

