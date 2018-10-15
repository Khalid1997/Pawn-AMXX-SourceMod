#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <cstrike>

#define PLUGIN "Rounds Menu"
#define VERSION "1.0"
#define AUTHOR "Khalid"

#define FLAG ADMIN_MENU

new gCurMsgId

new bool:HasChoosed, bool:RoundRunning, bool:InRoundEnd
new RoundNum		// For arrays/strings

new gKeys = (MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8)

// **** Weapon\ Round constants *****
// *** Editable strings
// *Round start messeges
new sRoundMessages[][] = {
	"[Sharjah-Gaming] Knife Round has been Started! Run for your lifes!",	// Knife round message
	"[Sharjah-Gaming] USP Round has been Started! Run for your lifes!",	// USP round message
	"[Sharjah-Gaming] Deagle Round has been Started! Run for your lifes!",	// Deagle round message
	"[Sharjah-Gaming] Mp5 Round has been Started! Run for your lifes!",	// Mp5 round message
	"[Sharjah-Gaming] Scout Round has been Started! Run for your lifes!",	// Scout round message
	"[Sharjah-Gaming] M4A1 Round has been Started! Run for your lifes!",	// M4 round message
	"[Sharjah-Gaming] AK47 Round has been Started! Run for your lifes!",	// AK47 round message
	"[Sharjah-Gaming] AWP Round has been Started! Run for your lifes!"	// AWP round message
}

// * Look at line 136 for this, %s will be replace by the strings here...
new const sWeaponStrings[][] = {
	"Knife",
	"USP",
	"Deagle",
	"Mp5",
	"Scout",
	"M4A1",
	"AK47",
	"AWP"
}

// **** No editing here please.
new const CSWeapons[] = {
	CSW_KNIFE,
	CSW_USP,
	CSW_DEAGLE,
	CSW_MP5NAVY,
	CSW_SCOUT,
	CSW_M4A1,
	CSW_AK47,
	CSW_AWP
}

new const sWeapons[][] = {
	"weapon_knife",		// 0
	"weapon_usp",		// 1
	"weapon_deagle",	// 2
	"weapon_mp5navy",	// 3
	"weapon_scout",		// 4
	"weapon_m4a1",		// 5
	"weapon_ak47",		// 6
	"weapon_awp"		// 7
}

new const WeaponBpClips[] = {
	0,		// Knife
	100,		// USP
	35,		// Deagle
	120,		// Mp5
	90,		// Scout
	90,		// M4
	90,		// AK47
	30		// AWP
}

// *** Block buy things ***
new bool:gBlockBuyZone;
new gMsgStatusIcon;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say /rounds", "admin_show_menu", FLAG)
	
	register_clcmd("drop", "hook_drop")
	
	// *** Menu registring ***
	register_menucmd(register_menuid("Choose the next round type:"), gKeys, "player_menu_what")
	
	// *** Events and messages
	register_event("HLTV", "NewRound", "a", "1=0", "2=0")
	register_event("CurWeapon", "eCurWeapon", "be")
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_start", 2, "1=Round_Start")
	gCurMsgId = get_user_msgid("CurWeapon")
	
	/* ************ Buy block code - By Exolent *************** */
	// Grab StatusIcon message ID
	gMsgStatusIcon = get_user_msgid("StatusIcon");
	// Hook StatusIcon message
	register_message(gMsgStatusIcon, "MessageStatusIcon");

}

public admin_show_menu(id, level, cid)
{
	if( !( get_user_flags(id) & level ) )
	{
		client_print(id, print_chat, "You don't have access to this command!")
		console_print(id, "You don't have access to this command!")
		return PLUGIN_HANDLED
	}
	
	if( HasChoosed == true )
	{
		client_print(id, print_chat, "Someone has already choosed a round or a round is already activated")
		return PLUGIN_HANDLED
	}
	
	if( InRoundEnd == true )
	{
		client_print(id, print_chat, "You can't choose a round on round end or on-freezetime!")
		return PLUGIN_HANDLED
	}
	
	//gMenuOpen[id] = 1
	
	static menu[150]
	format(menu, charsmax(menu), "\rChoose the next round type:^n\y1. \wKnife^n\y2. \wUSP^n\y3. \wDeagle^n\y4. \wMp5^n\y5. \wScout^n\y6. \wM4A1^n\y7. \wAK47^n\y8. \wAWP")
	show_menu(id, gKeys, menu)
	
	return PLUGIN_HANDLED
}

public player_menu_what(id, key)
{
	switch(key)
	{
		case 0..7:
		{
			RoundNum = key
			HasChoosed = true
			client_print(id, print_chat, "You have choosen the %s round. It will be activated next round", sWeaponStrings[key])
		}
	}
		//return PLUGIN_HANDLED
	return PLUGIN_HANDLED
}

public NewRound()
{
	static NextRoundCame
	
	if(NextRoundCame == 1 && HasChoosed == true)		// Restore things to normal
	{
		new players[32], count, player
		get_players(players, count, "a")
		
		for(new i; i < count; i++)
		{
			player = players[i]
			strip_user_weapons(player)
			give_item(player, "weapon_knife")
			
			if(get_user_team(player) == 1)
				give_item(player, "weapon_glock")
			
			if(get_user_team(player) == 2)
				give_item(player, "weapon_usp")
		}

		NextRoundCame = 0
		RoundRunning = false
		HasChoosed = false
		UnblockBuyZones()
		return PLUGIN_HANDLED
	}
	
	if(HasChoosed == true && NextRoundCame == 0)
	{
		BlockBuyZones()
		RoundRunning = true
		//client_print(0, print_chat, sRoundMessages[RoundNum])
		set_hudmessage(255, 255, 0, -1.0, -1.0)
		show_hudmessage(0, sRoundMessages[RoundNum])
		
		
		set_task(0.5, "give_items")

		NextRoundCame++
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public eCurWeapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if(RoundRunning == true)
	{
		if( !( (1 << read_data(2) ) & (1 << CSWeapons[RoundNum]) ) )
		{
			engclient_cmd(id, sWeapons[RoundNum])
		
			emessage_begin(MSG_ONE, gCurMsgId,_, id)
			ewrite_byte(1)
			ewrite_byte(CSWeapons[RoundNum])
			ewrite_byte(-1)
			emessage_end()
		
			return PLUGIN_HANDLED
		}
		return PLUGIN_HANDLED
	}
	
	else
		return PLUGIN_HANDLED
	return PLUGIN_HANDLED
}

public give_items()
{
	new players[32], count, player
	get_players(players, count, "a")
		
	for(new i; i < count; i++)
	{
		player = players[i]
		
		strip_user_weapons(player)

		give_item(player, sWeapons[RoundNum])

		
		if(RoundNum == 0)
			return PLUGIN_HANDLED
		else
			cs_set_user_bpammo(player, CSWeapons[RoundNum], WeaponBpClips[RoundNum])
	}
	return PLUGIN_HANDLED
}

public round_end()
{
	InRoundEnd = true
}

public round_start()
{
	InRoundEnd = false
}

public hook_drop(id)
{
	if( RoundRunning == true )
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}
/* ******************************* Buy block code - By Exolent ************************************* */
public MessageStatusIcon(msgID, dest, receiver) {
	// Check if status is to be shown
	if(gBlockBuyZone && get_msg_arg_int(1)) {
	
		new const buyzone[] = "buyzone";
	
		// Grab what icon is being shown
		new icon[sizeof(buyzone) + 1];
		get_msg_arg_string(2, icon, charsmax(icon));
	
		// Check if buyzone icon
		if(equal(icon, buyzone)) {
		
			// Remove player from buyzone
			RemoveFromBuyzone(receiver);
		
			// Block icon from being shown
			set_msg_arg_int(1, ARG_BYTE, 0);
		}
	}
	return PLUGIN_CONTINUE;
}

BlockBuyZones()
{
	// Hide buyzone icon from all players
	message_begin(MSG_BROADCAST, gMsgStatusIcon);
	write_byte(0);
	write_string("buyzone");
	message_end();
	
	// Get all alive players
	new players[32], pnum;
	get_players(players, pnum, "a");
	
	// Remove all alive players from buyzone
	while(pnum-- > 0)
	{
		RemoveFromBuyzone(players[pnum]);
	}
	// Set that buyzones should be blocked
	gBlockBuyZone = true;
}
	
RemoveFromBuyzone(id)
{
	// Define offsets to be used
	const m_fClientMapZone = 235;
	const MAPZONE_BUYZONE = (1 << 0);
	const XO_PLAYERS = 5;
	
	// Remove player's buyzone bit for the map zones
	set_pdata_int(id, m_fClientMapZone, get_pdata_int(id, m_fClientMapZone, XO_PLAYERS) & ~MAPZONE_BUYZONE, XO_PLAYERS);
}

UnblockBuyZones()
{
	// Set that buyzone should not be blocked
	gBlockBuyZone = false;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
