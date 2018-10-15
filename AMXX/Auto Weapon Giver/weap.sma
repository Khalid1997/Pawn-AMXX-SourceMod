#include <amxmodx>
#include <amxmisc>
#include <fakemeta> 
#include <hamsandwich>
#include <fun>

new const g_iPrimWeps = ( (1<<CSW_AK47) | (1<<CSW_AUG) | (1<<CSW_AWP) | (1<<CSW_FAMAS) | (1<<CSW_GALIL) | (1<<CSW_G3SG1) | (1<<CSW_M249) | (1<<CSW_M3) | (1<<CSW_M4A1) | (1<<CSW_MAC10) | (1<<CSW_MP5NAVY) | (1<<CSW_P90) | (1<<CSW_SCOUT) | (1<<CSW_SG550) | (1<<CSW_SG552) | (1<<CSW_TMP) | (1<<CSW_XM1014) );
    
new const VERSION[] = "1.0"

new gWant[33][2][35], Trie:gNames
new const FILE_NAME[] = "weapnames.ini"

public plugin_init()
{
	register_plugin("Auto Gun Giver", VERSION, "Khalid :)")
	
	RegisterHam(Ham_Spawn, "player", "Fwd_Spawn", 1)
	
	gNames = TrieCreate()
	ReadFile()
	
	register_concmd("amx_reload_wepfile", "AdminReloadFile", ADMIN_RCON)
}

public AdminReloadFile(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	TrieClear(gNames)
	ReadFile()
	
	console_print(id, "Successfully reloaded file")
	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	get_user_authid(id, gWant[id][1], sizeof(gWant[][]) - 1)
	new szSteamId[33]; get_user_authid(id, szSteamId, charsmax(szSteamId))
	
	if(TrieKeyExists(gNames, gWant[id][1]))
		gWant[id][0][0] = 1
}
	
public client_disconnect(id)
{
	gWant[id][0][0] = 0
	gWant[id][1][0] = EOS
}

public Fwd_Spawn(id)
{
	if(is_user_alive(id))
	{
		if( !gWant[id][0][0] )
			return;
	
		if( HasPrimWeapon(id) )
			return;
		
		static szWeapon[32]
		TrieGetString(gNames, gWant[id][1], szWeapon, charsmax(szWeapon))
		server_print(szWeapon)
		
		Give(szWeapon, id)
		//set_task(1.5, "Give", id, szWeapon, charsmax(szWeapon))
	}
}

public Give(some[], id)
	give_item(id, some)

ReadFile()
{
	static szFile[100]
	
	if(!szFile[0])
	{
		get_configsdir(szFile, charsmax(szFile))
		format(szFile, charsmax(szFile), "%s/%s", szFile, FILE_NAME)
	}
	
	if(!file_exists(szFile))
		write_file(szFile, "")

	new f = fopen(szFile, "r")
	
	new szLine[70]
	new iLen = charsmax(szLine)
	new szSteamId[35], szWeapon[33]
	
	while(!feof(f))
	{
		fgets(f, szLine, iLen)
		
		replace(szLine, charsmax(szLine), "^n", "")
		
		if(!szLine[0] || szLine[0] == ';' || szLine[0] != '"')
			continue;
		
		strbreak(szLine, szSteamId, charsmax(szSteamId), szWeapon, charsmax(szWeapon))
		
		remove_quotes(szSteamId)
		remove_quotes(szWeapon)
		
		TrieSetString(gNames, szSteamId, szWeapon)
	}
	
	fclose(f)
}

HasPrimWeapon(id)
{
	new iWeapons[32], iNum
	
	get_user_weapons(id, iWeapons, iNum)
	
	for(new i;i < sizeof(iWeapons); i++)
		if( ( (1<<iWeapons[i]) & g_iPrimWeps) )
			return 1
			
	return 0
}
