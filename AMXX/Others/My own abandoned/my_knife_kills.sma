#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Knife Kills"
#define VERSION "1.0"
#define AUTHOR "Khalid :)"

new const SAVE_FILE[] = "addons/amxmodx/data/knife_kills.ini"

new g_iKnifeKills[33]
new Trie:g_hKnifeKills, Array:g_hNameArray

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
		
	g_hKnifeKills = TrieCreate()
	if(g_hKnifeKills == Invalid_Trie)
	{
		set_fail_state("Failed to create knife kills trie")
	}
	
	g_hNameArray = ArrayCreate(32, 1)
	
	if(g_hNameArray == Invalid_Array)
	{
		TrieDestroy(g_hKnifeKills)
		set_fail_state("Failed to create name array")
	}
	
	register_clcmd("say /my_knife_kills", "CmdKnifeKills")
	
	new szCondition[10]; formatex(szCondition, charsmax(szCondition), "1<%d", get_maxplayers() + 1)
	register_event("DeathMsg", "eKnifeKill", "a", szCondition, "4=knife")
	
	LoadFile()
}

public plugin_end()
{
	SaveFile()
}

public eKnifeKill()
{
	new iKiller = read_data(1)	
	g_iKnifeKills[iKiller]++
}

public client_putinserver(id)
{
	if(is_user_bot(id))
	{
		return;
	}
	
	g_iKnifeKills[id] = GetKnifeKills(id)
}

public client_disconnect(id)
{
	if(is_user_bot(id))
	{
		return;
	}
	
	SaveKnifeKills(id)
	g_iKnifeKills[id] = 0
}

public client_infochanged(id)
{
	static szOldName[32], szNewName[32]
	
	get_user_info(id, "name", szNewName, 31)
	get_user_name(id, szOldName, 31)
	
	if(!equal(szOldName, szNewName))
	{
		SaveKnifeKills(id)
		g_iKnifeKills[id] = GetKnifeKills(id)
	}
}

public CmdKnifeKills(id)
{
	client_print(id, print_chat, "[AMXX] Your total knife kills is %d", g_iKnifeKills[id])
}

stock GetKnifeKills(id)
{
	static szName[32]; get_user_name(id, szName, 31)
	if(TrieKeyExists(g_hKnifeKills, szName))
	{
		static iValue
		TrieGetCell(g_hKnifeKills, szName, iValue)
		
		return iValue
	}
	
	TrieSetCell(g_hKnifeKills, szName, 0)
	ArrayPushString(g_hNameArray, szName)
	return 0
}

stock SaveKnifeKills(id)
{
	static szName[32]; get_user_name(id, szName, 31)
	TrieSetCell(g_hKnifeKills, szName, g_iKnifeKills[id])
}

stock SaveFile()
{
	new f = fopen(SAVE_FILE, "w+")
	
	if(!f)
	{
		return;
	}
	
	new i = 0, iSize = ArraySize(g_hNameArray), szName[32], iKills, szLine[100]
	
	while(i < iSize)
	{
		ArrayGetString(g_hNameArray, i, szName, 31)
		TrieGetCell(g_hKnifeKills, szName, iKills)
		
		formatex(szLine, 99, "^"%s^" %d", szName, iKills)
		fputs(f, szLine)
		i++
		
		break;
	}
	
	fclose(f)
}

stock LoadFile()
{
	new f = fopen(SAVE_FILE, "r")
	
	if(!f)
	{
		return;
	}
	
	new szName[32], szLine[100]
	
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		trim(szLine)
		
		if(!szLine[0] || szLine[0] == ';')
		{
			continue;
		}
		
		parse(szLine, szName, charsmax(szName), szLine, charsmax(szLine))
		
		TrieSetCell(g_hKnifeKills, szName, str_to_num(szLine))
		ArrayPushString(g_hNameArray, szName)
	}
	
	fclose(f)
}
