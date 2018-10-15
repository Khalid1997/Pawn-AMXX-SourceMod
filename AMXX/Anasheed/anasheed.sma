#include <amxmodx>

new const szSounds[][]={	// Max 5
	"7ob_w_7yah.mp3",
	"2owahen_2ahen_2owaho.mp3",
	"2ela_9alaty.mp3",
	"Dawi_Qalbi.mp3",
	"iny_t2amalto.mp3"
}

new const szSounds2[][] = {	// Max 5
	"5awa6er_8.mp3",
	"lasawfa_a3ood_ya2omy.mp3",
	"farshy_altorab.mp3",
	"5awa6er_7.mp3",
	"l8d_3lmtny_al7ayah.mp3"
}

#define NUMBER 5	// Max 8
#define NUMBER2 5

new const szArabicTitle[][] = {
	"ﺓﺎﻴﺣ ﻭ ﺐﺣ",
	"ﻮﻫﺍﻭﺃ ﻩﺍ ﻦﻫﺍﻭﺃ",
	"ﻲﺗﻼﺻ ﻻﺇ",
	"ﻲﺒﻠﻗ ﻱﻭﺍﺩ",
	"ﺖﻠﻣﺄﺗ ﻲﻧﺇ"
}

new const szArabicTitle2[][] = {
	"۸ ﺮﻃﺍﻮﺧ",
	"ﻲﻣﺃ ﺎﻳ ﺪﻮﻋﺃ ﻒﻮﺴﻟ",
	"ﺏﺍﺮﺘﻟﺍ ﻲﺷﺮﻓ",
	"۷ ﺮﻃﺍﻮﺧ",
	"ﺓﺎﻴﺤﻟﺍ ﻲﻨﺘﻤﻠﻋ ﺪﻘﻠ"
}
	
#define VERSION "1.5"

#define PATH "sound/anasheed"

new gKeys

new Page[33]

new const Key[]={
	MENU_KEY_0,
	MENU_KEY_1,
	MENU_KEY_2,
	MENU_KEY_3,
	MENU_KEY_4,
	MENU_KEY_5,
	MENU_KEY_6,
	MENU_KEY_7,
	MENU_KEY_8,
	MENU_KEY_9
}

public plugin_precache()
{
	new fmt[100]
	for(new i; i < sizeof(szSounds); i++)
	{
		formatex(fmt, 99, "%s/%s", PATH, szSounds[i])
		precache_generic(fmt)
	}
	
	for(new i; i < sizeof(szSounds2); i++)
	{
		formatex(fmt, 99, "%s/%s", PATH, szSounds2[i])
		precache_generic(fmt)
	}
}

public plugin_init() {
	register_plugin("In game sounds", VERSION, "Khalid :)")
	register_clcmd("say /sounds", "cmd_anasheed")
	register_clcmd("say /anasheed", "cmd_anasheed")
	
	/*new size = sizeof(szSounds) + 2
	for(new i; i <= size; i++)
	{
		gKeys |= Key[i]
		//if(i == size)
			//gKeys = gKeys|Key[8]|Key[7]
	}*/
	
	for(new i; i < sizeof(Key); i++)
	{
		gKeys |= Key[i]
	}
	
	register_menucmd(register_menuid("Choose what you want:"), gKeys, "menu_handler")
}

public client_connect(id)
	Page[id] = 0
	

public cmd_anasheed(id)
{
	Page[id] = 1
	new anasheed[180], len, b

	for(new i; i < NUMBER; i++)
	{
		len = len + formatex(anasheed[len], charsmax(anasheed) - len, "%s\y%d. \w%s", len ? "^n" : "", ++b, szArabicTitle[i])
	}
	
	new menu[300]
	formatex(menu, charsmax(menu), "Choose what you want:^n%s^n^n\r8. \wNext Page^n\r9. \wStop sound^n\r0. \wExit^n^n\rBy: \wKhalid :)", anasheed)
	
	//replace_all(menu, charsmax(menu), ".mp3", "")
	//replace_all(menu, charsmax(menu), ".wav", "")
	//replace_all(menu, charsmax(menu), "_", " ")
	
	show_menu(id, gKeys, menu)	
	return PLUGIN_CONTINUE
}

public menu_handler(id, key)
{
	if(key < NUMBER || key < NUMBER2)
	{
		if( Page[id] == 1 )
			client_cmd(id, ";mp3 play ^"%s/%s^"", PATH, szSounds[key])
		if(Page[id] == 2)
			client_cmd(id, ";mp3 play ^"%s/%s^"", PATH, szSounds2[key])
	}
	
	if(key == 7)
	{
		NextPage(id)
	}
	
	if(key == 8)
	{
		client_cmd(id, ";mp3 stop")
	}
}

NextPage(id)
{
	if(Page[id] == 1)
	{
		Page[id] = 2
		page_two(id)
		return PLUGIN_CONTINUE
	}
	
	if(Page[id] == 2)
	{
		Page[id] = 1
		cmd_anasheed(id)
	}
	
	return PLUGIN_HANDLED
}
		

stock page_two(id)
{
	new canasheed[180], clen, cb

	for(new i; i < NUMBER2; i++)
	{
		clen = clen + formatex(canasheed[clen], charsmax(canasheed) - clen, "%s\y%d. \w%s", clen ? "^n" : "", ++cb, szArabicTitle2[i])
	}
	
	new cmenu[300]
	formatex(cmenu, charsmax(cmenu), "\rBy \wKhalid :)^nChoose what you want:^n%s^n^n\r8. \wNext Page^n\r9. \wStop sound^n\r0. \wExit^n^n\rBy: \wKhalid :)", canasheed)
	
	show_menu(id, gKeys, cmenu)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
