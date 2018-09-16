/*
*
*  	Plugin: JailBreak Shop
*  	Autor: MaNuCs
*  
*  	Credits: rubee
*                Gladius
*		 capostrike93
*		 apu
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <nvault>

#define is_valid_player(%1) (1 <= %1 <= 32)

/*============================================================
			Variables
============================================================*/

new 	
	OnOff, 
	OnOff2, 
	precio1, 
	precio2, 
	precio3,
	precio4, 
	precio5, 
	precio6, 
	precio7, 
	precioC1, 
	precioC2, 
	precioC3,
	precioC4,
	CTDefaultDano, 
	TDefaultDano, 
	PaloDano, 
	HachaDano, 
	MacheteDano, 
	MotocierraDano,
	hTDefaultDano, 
	hCTDefaultDano, 
	hPaloDano, 
	hHachaDano, 
	hMacheteDano,
	Vida,
	Armor,
	glock1,
	glock2,
	help,
	g_killjp, 
	g_killhsjp, 
	g_startjp,
	g_maxjp,
	g_iMsgSayText,
	syncObj,
	Ronda[33],
	Speed[33],
	Speed2[33],
	TCuchillo[33],
	CTCuchillo[33],
	Destapador[33],
	Hacha[33],
	Machete[33],
	Motocierra[33],
	g_jbpacks[33],
	quitar[33],
	regalar[33],
	gidPlayer[33]
	

/*============================================================
			Weapon Model's
============================================================*/


new VIEW_MODELT[]    	= "models/[Shop]JailBreak/Punos/Punos.mdl" 
new PLAYER_MODELT[] 	= "models/[Shop]JailBreak/Punos/Punos2.mdl" 

new VIEW_MODELCT[]    	= "models/[Shop]JailBreak/Electro/Electro.mdl" 
new PLAYER_MODELCT[]   	= "models/[Shop]JailBreak/Electro/Electro2.mdl" 

new VIEW_Hacha[]    	= "models/[Shop]JailBreak/Hacha/Hacha.mdl" 
new PLAYER_Hacha[]   	= "models/[Shop]JailBreak/Hacha/Hacha2.mdl" 

new VIEW_Machete[]    	= "models/[Shop]JailBreak/Machete/Machete.mdl" 
new PLAYER_Machete[]    	= "models/[Shop]JailBreak/Machete/Machete2.mdl"

new VIEW_Palo[]    	= "models/[Shop]JailBreak/Palo/Palo.mdl" 
new PLAYER_Palo[]    	= "models/[Shop]JailBreak/Palo/Palo2.mdl" 

new VIEW_Moto[]    	= "models/[Shop]JailBreak/Moto/Moto.mdl" 
new PLAYER_Moto[]    	= "models/[Shop]JailBreak/Moto/Moto2.mdl" 

new WORLD_MODEL[]    	= "models/w_knife.mdl"
new OLDWORLD_MODEL[]    	= "models/w_knife.mdl"

/*============================================================
                     Shop Sounds!
============================================================*/
new const Si[] 		= { "[Shop]JailBreak/Yes.wav" }
new const No[] 		= { "[Shop]JailBreak/No.wav" }

/*============================================================
                     Weapon Sound's
============================================================*/

new const palo_deploy[] 		= { "weapons/knife_deploy1.wav" }
new const palo_slash1[] 		= { "weapons/knife_slash1.wav" }
new const palo_slash2[] 		= { "weapons/knife_slash2.wav" }
new const palo_wall[] 		= { "[Shop]JailBreak/Palo/PHitWall.wav" } 
new const palo_hit1[] 		= { "[Shop]JailBreak/Palo/PHit1.wav" } 
new const palo_hit2[] 		= { "[Shop]JailBreak/Palo/PHit2.wav" } 
new const palo_hit3[] 		= { "[Shop]JailBreak/Palo/PHit3.wav" } 
new const palo_hit4[] 		= { "[Shop]JailBreak/Palo/PHit4.wav" } 
new const palo_stab[] 		= { "[Shop]JailBreak/Palo/PStab.wav" }

new const hacha_deploy[] 	= { "weapons/knife_deploy1.wav" }
new const hacha_slash1[] 	= { "[Shop]JailBreak/Hacha/HSlash1.wav" }
new const hacha_slash2[] 	= { "[Shop]JailBreak/Hacha/HSlash2.wav" }
new const hacha_wall[] 		= { "[Shop]JailBreak/Hacha/HHitWall.wav" }
new const hacha_hit1[] 		= { "[Shop]JailBreak/Hacha/HHit1.wav" }
new const hacha_hit2[] 		= { "[Shop]JailBreak/Hacha/HHit2.wav" }
new const hacha_hit3[] 		= { "[Shop]JailBreak/Hacha/HHit3.wav" }
new const hacha_stab[] 		= { "[Shop]JailBreak/Hacha/HHit4.wav" }

new const machete_deploy[] 	= { "[Shop]JailBreak/Machete/MConvoca.wav" }
new const machete_slash1[] 	= { "[Shop]JailBreak/Machete/MSlash1.wav" }
new const machete_slash2[] 	= { "[Shop]JailBreak/Machete/MSlash2.wav" }
new const machete_wall[] 	= { "[Shop]JailBreak/Machete/MHitWall.wav" }
new const machete_hit1[] 	= { "[Shop]JailBreak/Machete/MHit1.wav" }
new const machete_hit2[] 	= { "[Shop]JailBreak/Machete/MHit2.wav" }
new const machete_hit3[] 	= { "[Shop]JailBreak/Machete/MHit3.wav" }
new const machete_hit4[] 	= { "[Shop]JailBreak/Machete/MHit4.wav" }
new const machete_stab[] 	= { "[Shop]JailBreak/Machete/MStab.wav" }

new const motocierra_deploy[] 	= { "[Shop]JailBreak/Moto/MTConvoca.wav", }
new const motocierra_slash[] 	= { "[Shop]JailBreak/Moto/MTSlash.wav", }
new const motocierra_wall[] 	= { "[Shop]JailBreak/Moto/MTHitWall.wav" }
new const motocierra_hit1[] 	= { "[Shop]JailBreak/Moto/MTHit1.wav",  }
new const motocierra_hit2[] 	= { "[Shop]JailBreak/Moto/MTHit2.wav",  }
new const motocierra_stab[] 	= { "[Shop]JailBreak/Moto/MTStab.wav"  }

new const t_deploy[] 		= { "[Shop]JailBreak/T/TConvoca.wav", }
new const t_slash1[] 		= { "[Shop]JailBreak/T/Slash1.wav", }
new const t_slash2[] 		= { "[Shop]JailBreak/T/Slash2.wav", }
new const t_wall[] 		= { "[Shop]JailBreak/T/THitWall.wav" }
new const t_hit1[] 		= { "[Shop]JailBreak/T/THit1.wav",  }
new const t_hit2[] 		= { "[Shop]JailBreak/T/THit2.wav",  }
new const t_hit3[] 		= { "[Shop]JailBreak/T/THit3.wav",  }
new const t_hit4[] 		= { "[Shop]JailBreak/T/THit4.wav",  }
new const t_stab[] 		= { "[Shop]JailBreak/T/TStab.wav"  }

new const ct_deploy[] 		= { "[Shop]JailBreak/CT/CTConvoca.wav", }
new const ct_slash1[] 		= { "[Shop]JailBreak/CT/Slash1.wav", }
new const ct_slash2[] 		= { "[Shop]JailBreak/CT/Slash2.wav", }
new const ct_wall[] 		= { "[Shop]JailBreak/CT/CTHitWall.wav" }
new const ct_hit1[] 		= { "[Shop]JailBreak/CT/CTHit1.wav",  }
new const ct_hit2[] 		= { "[Shop]JailBreak/CT/CTHit2.wav",  }
new const ct_hit3[] 		= { "[Shop]JailBreak/CT/CTHit3.wav",  }
new const ct_hit4[] 		= { "[Shop]JailBreak/CT/CTHit4.wav",  }
new const ct_stab[] 		= { "[Shop]JailBreak/CT/CTStab.wav"  }


new vault

/*============================================================
			Config
============================================================*/

public plugin_init() 
{
	
	register_plugin("[JB] Shop", "2.9", "[M]aNuC[s]_")
	
	register_clcmd("say /shop", "Tienda")
	register_clcmd("say !shop", "Tienda")
	register_clcmd("say_team /shop", "Tienda")
	register_clcmd("say_team !shop", "Tienda")
	
	register_clcmd("say /mg", 	"duel_menu", ADMIN_ALL)
	register_clcmd("say !mg", 	"duel_menu", ADMIN_ALL)
	register_clcmd("say_team /mg", 	"duel_menu", ADMIN_ALL)
	register_clcmd("say_team !mg", 	"duel_menu", ADMIN_ALL)
	register_clcmd("JbPacks", 	"player")
	
	RegisterHam(Ham_Spawn, 		"player", "Fwd_PlayerSpawn_Post",	1)
	RegisterHam(Ham_TakeDamage, 	"player", "FwdTakeDamage", 		0)
	RegisterHam(Ham_Killed,		"player", "fw_player_killed")
	
	register_event("CurWeapon", 	"Event_Change_Weapon", "be", "1=1")
	
	register_forward(FM_SetModel, 	"fw_SetModel")
	register_forward(FM_EmitSound,	"Fwd_EmitSound")
	
	/*============================================================
				Cvar's 
	============================================================*/
	g_killjp 	= register_cvar("jb_killJP", 		"3"); 
	g_killhsjp 	= register_cvar("jb_bonushsJP", 	"2");
	g_startjp 	= register_cvar("jb_startJP",		"7"); 
	g_maxjp 	= register_cvar("jb_maxgiveJP",		"10000"); 
		
	OnOff 		= register_cvar("jb_Shop", 		"1")//1(ON) 0(OFF) 
	OnOff2 		= register_cvar("jb_ShopKnifes",	"1")//1(ON) 0(OFF) 
	help 		= register_cvar("jb_help", 		"1")//1(ON) 0(OFF)
	
	precio1 	= register_cvar("jb_pFlash", 		"8")
	precio2		= register_cvar("jb_pHe", 		"11")
	precio3		= register_cvar("jb_pHEFL", 		"22")
	precio4		= register_cvar("jb_pWalk", 		"25")
	precio5		= register_cvar("jb_pFast", 		"28")
	precio6		= register_cvar("jb_pDrugs", 		"30")
	precio7		= register_cvar("jb_pGlock", 		"36")
	
	precioC1	= register_cvar("jb_pKnife1", 		"5")
	precioC2 	= register_cvar("jb_pKnife2", 		"20")
	precioC3 	= register_cvar("jb_pKnife3", 		"25")
	precioC4 	= register_cvar("jb_pKnife4", 		"36")
	
	TDefaultDano 	= register_cvar("jb_dKnifeT", 		"20")
	CTDefaultDano 	= register_cvar("jb_dKnifeCT", 		"50")
	PaloDano 	= register_cvar("jb_dKnife1", 		"30")
	HachaDano 	= register_cvar("jb_dKnife2", 		"60")
	MacheteDano 	= register_cvar("jb_dKnife3", 		"80")
	MotocierraDano 	= register_cvar("jb_dKnife4", 		"200")
	
	hTDefaultDano 	= register_cvar("jb_dHsKnifeT", 	"30")
	hCTDefaultDano 	= register_cvar("jb_dHsKnifeCT",	"80")
	hPaloDano 	= register_cvar("jb_dhsKnife1", 	"45")
	hHachaDano 	= register_cvar("jb_dhsKnife2", 	"75")
	hMacheteDano 	= register_cvar("jb_dhsKnife3", 	"95")
	
	Vida 		= register_cvar("jb_drLife", 		"200")
	Armor 		= register_cvar("jb_drArmor", 		"200")
	
	glock1 		= register_cvar("jb_gClip", 		"20")
	glock2 		= register_cvar("jb_gAmmo", 		"0")

	g_iMsgSayText 	= get_user_msgid("SayText") 
	syncObj 	= CreateHudSyncObj()
	
	
	/*============================================================
				Multi Lengual!
	============================================================*/
	register_dictionary("JBShop.txt")
}

/*============================================================
			Precaches 
============================================================*/
public plugin_precache() 
{
	precache_sound(Si)
	precache_sound(No)

	precache_sound(t_deploy)
	precache_sound(t_slash1)
	precache_sound(t_slash2)
	precache_sound(t_stab)
	precache_sound(t_wall)
	precache_sound(t_hit1)
	precache_sound(t_hit2)
	precache_sound(t_hit3)
	precache_sound(t_hit4)
	
	precache_sound(ct_deploy)
	precache_sound(ct_slash1)
	precache_sound(ct_slash2)
	precache_sound(ct_stab)
	precache_sound(ct_wall)
	precache_sound(ct_hit1)
	precache_sound(ct_hit2)
	precache_sound(ct_hit3)
	precache_sound(ct_hit4)
	
	precache_sound(palo_deploy)
	precache_sound(palo_slash1)
	precache_sound(palo_slash2)
	precache_sound(palo_stab)
	precache_sound(palo_wall)
	precache_sound(palo_hit1)
	precache_sound(palo_hit2)
	precache_sound(palo_hit3)
	precache_sound(palo_hit4)
	
	precache_sound(machete_deploy)
	precache_sound(machete_slash1)
	precache_sound(machete_slash2)
	precache_sound(machete_stab)
	precache_sound(machete_wall)
	precache_sound(machete_hit1)
	precache_sound(machete_hit2)
	precache_sound(machete_hit3)
	precache_sound(machete_hit4)
	
	precache_sound(hacha_deploy)
	precache_sound(hacha_slash1)
	precache_sound(hacha_slash2)
	precache_sound(hacha_stab)
	precache_sound(hacha_wall)
	precache_sound(hacha_hit1)
	precache_sound(hacha_hit2)
	precache_sound(hacha_hit3)
	
	precache_sound(motocierra_deploy)
	precache_sound(motocierra_slash)
	precache_sound(motocierra_stab)
	precache_sound(motocierra_wall)
	precache_sound(motocierra_hit1)
	precache_sound(motocierra_hit2)

	
	precache_model(VIEW_MODELT)     
	precache_model(PLAYER_MODELT)
	precache_model(VIEW_MODELCT)     
	precache_model(PLAYER_MODELCT)
	precache_model(VIEW_Palo)     
	precache_model(PLAYER_Palo) 
	precache_model(VIEW_Hacha)     
	precache_model(PLAYER_Hacha)	
	precache_model(VIEW_Machete)     
	precache_model(PLAYER_Machete)	
	precache_model(VIEW_Moto)     
	precache_model(PLAYER_Moto)		
	precache_model(WORLD_MODEL)

	return PLUGIN_CONTINUE
}

public plugin_cfg()
{
	vault = nvault_open("jb_packs")


	//Make the plugin error if vault did not successfully open
	if ( vault == INVALID_HANDLE )
		set_fail_state( "Error opening nVault" );
}

public plugin_end()
	nvault_close(vault)

/*============================================================
                     KNIFE SHOP
============================================================*/
public Tienda1(id)
{
	if(get_pcvar_num(OnOff2))
	{
		if (get_user_team(id) == 1 )
		{
			static Item[64]
						
			formatex(Item, charsmax(Item),"\y%L", LANG_PLAYER, "SHOP") 
			new Menu = menu_create(Item, "CuchilleroHandler")
						
			formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "KNIFE1", get_pcvar_num(precioC1))
			menu_additem(Menu, Item, "1")
							
			formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "KNIFE2", get_pcvar_num(precioC2))
			menu_additem(Menu, Item, "2")
			
			formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "KNIFE3", get_pcvar_num(precioC3))
			menu_additem(Menu, Item, "3")
			
			formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "KNIFE4", get_pcvar_num(precioC4))
			menu_additem(Menu, Item, "4")

			menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
			menu_display(id, Menu)
		}
	}
	return PLUGIN_HANDLED
}

public CuchilleroHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	
	new vivo 	= is_user_alive(id)
	new Obtener1 	= get_pcvar_num(precioC1)
	new Obtener2 	= get_pcvar_num(precioC2)
	new Obtener3 	= get_pcvar_num(precioC3)
	new Obtener4 	= get_pcvar_num(precioC4)	
	
	new key = str_to_num(data);
	
	switch(key)
	{
		case 1:
		{
			if (g_jbpacks[id]>= Obtener1 && vivo)
			{
				g_jbpacks[id] -= Obtener1
				CTCuchillo[id] 	= 0
				TCuchillo[id] 	= 0
				Destapador[id] 	= 1
				Hacha[id] 	= 0
				Machete[id] 	= 0
				Motocierra[id] 	= 0
				
				
				ham_strip_weapon(id, "weapon_knife")
				give_item(id, "weapon_knife")

				ChatColor(id, "%L", LANG_PLAYER, "BUY_KNIFE1")
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		
		case 2:
		{
			if (g_jbpacks[id] >= Obtener2 && vivo)
			{
				
				g_jbpacks[id] -= Obtener2
				CTCuchillo[id] 	= 0
				TCuchillo[id] 	= 0
				Destapador[id] 	= 0
				Hacha[id] 	= 1
				Machete[id] 	= 0
				Motocierra[id] 	= 0
				
				ham_strip_weapon(id, "weapon_knife")
				give_item(id, "weapon_knife")
				
				ChatColor(id, "%L", LANG_PLAYER, "BUY_KNIFE2")
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
			
		case 3:
		{
			if (g_jbpacks[id] >= Obtener3 && vivo)
			{
				
				g_jbpacks[id] -= Obtener3
				CTCuchillo[id] 	= 0
				TCuchillo[id] 	= 0
				Destapador[id] 	= 0
				Hacha[id] 	= 0
				Machete[id] 	= 1
				Motocierra[id] 	= 0
				
				ham_strip_weapon(id, "weapon_knife")
				give_item(id, "weapon_knife")
				
				ChatColor(id, "%L", LANG_PLAYER, "BUY_KNIFE3")
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		
		case 4:
		{
			if (g_jbpacks[id] >= Obtener4 && vivo)
			{
				
				g_jbpacks[id] -= Obtener4
				CTCuchillo[id] 	= 0
				TCuchillo[id] 	= 0
				Destapador[id]	= 0
				Hacha[id] 	= 0
				Machete[id] 	= 0
				Motocierra[id] 	= 1
				
				
				ham_strip_weapon(id, "weapon_knife")
				give_item(id, "weapon_knife")
				
				ChatColor(id, "%L", LANG_PLAYER, "BUY_KNIFE4")
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

/*============================================================
                     ITEM'S MENU
============================================================*/
public Tienda(id)
{
	if(get_pcvar_num(OnOff))
	{
		if(get_pcvar_num(OnOff) && Ronda[id])
		{
			if(is_user_alive(id))
			{
				if (cs_get_user_team(id) == CS_TEAM_T )
				{
					new contador=0;
					new players[32], num, tempid;
					
					get_players(players, num)
					
					for (new i=0; i<num; i++)
					{
						tempid = players[i]
						
						if (get_user_team(tempid)==1 && is_user_alive(tempid))
						{
							contador++;
						}
					}
					if ( contador == 1 )
					{
						ChatColor(id, "%L", LANG_PLAYER, "LAST")
					}
					else if ( contador >= 2 )
					{
						static Item[64]
						
						formatex(Item, charsmax(Item),"\y%L", LANG_PLAYER, "SHOP")
						new Menu = menu_create(Item, "TiendaHandler")
						
						formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "FLASH", get_pcvar_num(precio1))
						menu_additem(Menu, Item, "1")
						
						formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "HE", get_pcvar_num(precio2))
						menu_additem(Menu, Item, "2")
						
						formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "HEFLASH", get_pcvar_num(precio3))
						menu_additem(Menu, Item, "3")
						
						formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "FOOTSTEPS", get_pcvar_num(precio4))
						menu_additem(Menu, Item, "4")
						
						formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "SPEED", get_pcvar_num(precio5))
						menu_additem(Menu, Item, "5")
						
						formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "DRUGS", get_pcvar_num(precio6))
						menu_additem(Menu, Item, "6")
						
						formatex(Item, charsmax(Item),"\w%L \r%d$",LANG_PLAYER, "GLOCK", get_pcvar_num(precio7))
						menu_additem(Menu, Item, "7")
						
						menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
						menu_display(id, Menu)
					}
				}
				else
				{
					ChatColor(id, "%L", LANG_PLAYER, "ONLY")
				}
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "DEAD")
			}
		}
		else
		{
			ChatColor(id, "%L", LANG_PLAYER, "ONE_TIME")
		}
	}
	else
	{
		ChatColor(id, "%L",  LANG_PLAYER, "SHOP_OFF")
	}
	return PLUGIN_HANDLED
}


public TiendaHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new vivo 		= is_user_alive(id)
	new gmsg_SetFOV 	= get_user_msgid("SetFOV") 
	new Obtener1 		= get_pcvar_num(precio1)
	new Obtener2 		= get_pcvar_num(precio2)
	new Obtener3 		= get_pcvar_num(precio3)
	new Obtener4 		= get_pcvar_num(precio4)
	new Obtener5 		= get_pcvar_num(precio5)
	new Obtener6 		= get_pcvar_num(precio6)
	new Obtener7		= get_pcvar_num(precio7)
	new vida1		= get_user_health(id)
	new vida2 		= get_pcvar_num(Vida)
	new armor1		= get_user_armor(id)
	new armor2 		= get_pcvar_num(Armor)
	
	new key = str_to_num(data);
	switch(key)
	{
		case 1:
		{
			if (g_jbpacks[id] >= Obtener1 && vivo)
			{
				g_jbpacks[id] -= Obtener1
				ChatColor(id, "%L", LANG_PLAYER, "BUY_FLASH")
				give_item(id, "weapon_flashbang")
				give_item(id, "weapon_flashbang")
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
				Ronda[id] = 0
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		case 2:
		{
			
			if (g_jbpacks[id] >= Obtener2 && vivo)
			{
				g_jbpacks[id] -= Obtener2
				ChatColor(id, "%L", LANG_PLAYER, "BUY_HE")
				give_item(id, "weapon_hegrenade")
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
				Ronda[id] = 0
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		case 3:
		{
			
			if (g_jbpacks[id] >= Obtener3 && vivo)
			{
				g_jbpacks[id] -= Obtener3
				ChatColor(id, "%L", LANG_PLAYER, "BUY_HEFLASH")
				give_item(id, "weapon_hegrenade")
				give_item(id, "weapon_flashbang")
				give_item(id, "weapon_flashbang")
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
				Ronda[id] = 0
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		case 4:
		{
			
			if (g_jbpacks[id] >= Obtener4 && vivo)
			{
				g_jbpacks[id] -= Obtener4
				ChatColor(id, "%L", LANG_PLAYER, "BUY_FOOTSTEPS")
				set_user_footsteps(id, 1)
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
				Ronda[id] = 0
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		case 5:
		{		
			if (g_jbpacks[id] >= Obtener5 && vivo)
			{
				g_jbpacks[id] -= Obtener5
				ChatColor(id, "%L", LANG_PLAYER, "BUY_SPEED")
				set_user_maxspeed(id, 500.0)
				Speed[id] = 1
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
				Ronda[id] = 0
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")  
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		case 6:
		{	
			if (g_jbpacks[id] >= Obtener6 && vivo)
			{
				g_jbpacks[id] -= Obtener6
				ChatColor(id, "%L", LANG_PLAYER, "BUY_DRUGS")
				set_user_armor(id, armor1 + armor2)
				set_user_health(id, vida1 + vida2)
				set_user_maxspeed(id, 380.0)
				Speed2[id] = 1
				message_begin( MSG_ONE, gmsg_SetFOV, { 0, 0, 0 }, id )
				write_byte( 180 )
				message_end( )  
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
				Ronda[id] = 0
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
		case 7:
		{
			if (g_jbpacks[id] >= Obtener7 && vivo)
			{
				g_jbpacks[id] -= Obtener7	
				ChatColor(id, "%L", LANG_PLAYER, "BUY_GLOCK")
				cs_set_weapon_ammo( give_item( id, "weapon_glock18" ), get_pcvar_num(glock1))
				cs_set_user_bpammo(id, CSW_GLOCK18, get_pcvar_num(glock2))
				emit_sound(id, CHAN_AUTO, Si, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
				Ronda[id] = 0
			}
			else
			{
				ChatColor(id, "%L", LANG_PLAYER, "MONEY")
				emit_sound(id, CHAN_AUTO, No, VOL_NORM, ATTN_NORM , 0, PITCH_NORM) 
			}
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public client_connect(id) 
{
	//g_jbpacks[id] = get_pcvar_num(g_startjp) 
	g_jbpacks[id] = load_packs(id)
	set_task(1.0, "JailbreakPacks", id, _, _, "b")
}

public client_disconnect(id)
{
	save_packs(id, g_jbpacks[id])
}

load_packs(id)
{
	//vault = nvault_open("jb_packs")

	new authid[33]
	get_user_authid(id, authid, 32)
	
	new something[33]
	
	formatex(something, 32, "%s", authid)
	new packs = nvault_get(vault, something)
	if( packs )
		nvault_remove( vault, something);
	
	else
		packs = get_pcvar_num(g_startjp)
	
	//new packs = str_to_num(something)
	
	//nvault_get(vault, "%s", authid)
	server_print("Successfully loaded! <%s>", authid)
	return packs
}


save_packs(id, amount)
{
	//new vault = nvault_open("jb_packs")
	
	new authid[33]
	get_user_authid(id, authid, 32)
	
	new something[33]
	formatex(something, 32, "%d", amount)
	nvault_set(vault, authid, something)
	
	server_print("Successfully saved! <%s>", authid)
}

public JailbreakPacks(id)
{
	set_hudmessage(142, 239, 39, 0.50, 0.90, 0, 6.0, 2.5)
	ShowSyncHudMsg(id, syncObj,"JBPacks: %i", g_jbpacks[id])
}

public duel_menu(id)
{	
	if (!is_user_admin(id))
	{
		ChatColor(id, "%L", LANG_PLAYER, "CANT")
		return PLUGIN_HANDLED
	}
	
	static opcion[64]
	
	formatex(opcion, charsmax(opcion),"\y%L", LANG_PLAYER, "JBPACKS")
	new iMenu = menu_create(opcion, "menu")
	
	formatex(opcion, charsmax(opcion),"\w%L", LANG_PLAYER, "GIVE_JBPACKS")
	menu_additem(iMenu, opcion, "1")	
	
	formatex(opcion, charsmax(opcion),"\w%L", LANG_PLAYER, "TAKE_JBPACKS")
	menu_additem(iMenu, opcion, "2")	
	
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, iMenu, 0)
						
	return PLUGIN_HANDLED
}

public menu(id, menu, item)
{
	
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback
	
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	switch (Key)
	{
		case 1:
		{	
			regalar[id] = 1
			quitar[id] = 0	
			escojer(id)
		}
		case 2: 
		{	
			quitar[id] = 1
			regalar[id] = 0
			escojer(id)
		}
	}
	
	menu_destroy(menu)	
	return PLUGIN_HANDLED
}


public escojer(id)
{
	static opcion[64]
	
	formatex(opcion, charsmax(opcion),"\y%L", LANG_PLAYER, "CHOOSE")
	new iMenu = menu_create(opcion, "choose")
	
	new players[32], pnum, tempid
	new szName[32], szTempid[10]
	
	get_players(players, pnum, "a")
	
	for( new i; i<pnum; i++ )
	{
		tempid = players[i]
				
		get_user_name(tempid, szName, 31)
		num_to_str(tempid, szTempid, 9)
		
		formatex(opcion, charsmax(opcion), "\w%s \rJbPacks[%d]", szName, g_jbpacks[tempid])
		menu_additem(iMenu, opcion, szTempid, 0)
	}
	
	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public choose(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, Callback)
	
	new tempid = str_to_num(Data)
 
	gidPlayer[id] = tempid
	client_cmd(id, "messagemode JbPacks")
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public player(id)
{
    new say[300]
    read_args(say, charsmax(say))
        
    remove_quotes(say)
        
    if(!is_str_num(say) || equal(say, ""))
        return PLUGIN_HANDLED
        
    jbpacks(id, say)    
    
    return PLUGIN_CONTINUE
}

jbpacks(id, say[]) {
	new amount = str_to_num(say)
	new victim = gidPlayer[id]
    
	new vname[32]
        
	if(victim > 0)
	{
		get_user_name(victim, vname, 31)
		
		if(regalar[id])
		{
			if(amount > get_pcvar_num(g_maxjp))
			{
				g_jbpacks[victim] = get_pcvar_num(g_maxjp)
			}
			else
			{
				g_jbpacks[victim] = g_jbpacks[victim] + amount
			}
			ChatColor(0, "%L", LANG_PLAYER, "GIVE_MSG", amount, vname)
		}
		if(quitar[id])
		{
			if(amount > g_jbpacks[victim])
			{
				g_jbpacks[victim] = 0
				ChatColor(0, "%L", LANG_PLAYER, "TAKE_ALL", vname)
			}
			else 
			{
				g_jbpacks[victim] = g_jbpacks[victim] - amount
				ChatColor(0, "%L", LANG_PLAYER, "TAKE_MSG", amount, vname)
			}
			
		}		
	}

	return PLUGIN_HANDLED
}  

public Fwd_PlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		if(get_user_team(id) == 1) strip_user_weapons(id); give_item(id, "weapon_knife")	
		
		set_user_footsteps(id, 0)
		Speed[id] 	= 0
		Speed2[id] 	= 0
		Ronda[id] 	= 1
		CTCuchillo[id] 	= 1
		TCuchillo[id] 	= 1
		Destapador[id] 	= 0
		Hacha[id] 	= 0
		Machete[id] 	= 0
		Motocierra[id] 	= 0
		Tienda1(id)
		if(get_pcvar_num(help))	ChatColor(id, "%L", LANG_PLAYER, "HELP")
	}
}

public FwdTakeDamage(victim, inflictor, attacker, Float:damage, damage_bits)
{
	   
	if (is_valid_player(attacker) && get_user_weapon(attacker) == CSW_KNIFE)	
	{
		switch(get_user_team(attacker))
		{
			case 1:
			{
				if(TCuchillo[attacker])
				{    
					
					SetHamParamFloat(4, get_pcvar_float(TDefaultDano))
						
					if(get_pdata_int(victim, 75) == HIT_HEAD)
					{
						SetHamParamFloat(4, get_pcvar_float(hTDefaultDano))
					}
				}
						
				if(Destapador[attacker])
				{ 
					SetHamParamFloat(4, get_pcvar_float(PaloDano))
					
					if(get_pdata_int(victim, 75) == HIT_HEAD)
					{
						SetHamParamFloat(4, get_pcvar_float(hPaloDano))
					}
				}
			    
				if(Hacha[attacker])
				{    	
					SetHamParamFloat(4, get_pcvar_float(HachaDano))
					
					if(get_pdata_int(victim, 75) == HIT_HEAD)
					{
						SetHamParamFloat(4, get_pcvar_float(hHachaDano))
					}
				}
			    
				if(Machete[attacker])
				{    	
					SetHamParamFloat(4, get_pcvar_float(MacheteDano))
					
					if(get_pdata_int(victim, 75) == HIT_HEAD)
					{
						SetHamParamFloat(4, get_pcvar_float(hMacheteDano))
					}
				}
				
				if(Motocierra[attacker])
				{    
					SetHamParamFloat(4, get_pcvar_float(MotocierraDano))
				}
			}
			case 2:
			{
				if(CTCuchillo[attacker])
				{    
					SetHamParamFloat(4, get_pcvar_float(CTDefaultDano))
							
					if(get_pdata_int(victim, 75) == HIT_HEAD)
					{
						SetHamParamFloat(4, get_pcvar_float(hCTDefaultDano))
					}
				}
			}
		}
	}
	return HAM_HANDLED
}  

public fw_player_killed(victim, attacker, shouldgib)
{
	if(get_user_team(attacker) == 1)
	{
		g_jbpacks[attacker] += get_pcvar_num(g_killjp) 
		
		if(get_pdata_int(victim, 75) == HIT_HEAD)
		{
			g_jbpacks[attacker] += get_pcvar_num(g_killhsjp)
		}
	}
}


public Event_Change_Weapon(id)
{
		new weaponID = read_data(2) 
		
		switch (get_user_team(id))
		{
			case 1:
			{
				if(Speed[id])
				{
					set_user_maxspeed(id, 500.0)
				}
					
				if(Speed2[id])
				{
					set_user_maxspeed(id, 380.0)
				}
					
				if(weaponID == CSW_KNIFE && get_pcvar_num(OnOff2))
				{
					if(TCuchillo[id])
					{
						set_pev(id, pev_viewmodel2, VIEW_MODELT)
						set_pev(id, pev_weaponmodel2, PLAYER_MODELT)
					}
					
					if(Destapador[id])
					{
						set_pev(id, pev_viewmodel2, VIEW_Palo)
						set_pev(id, pev_weaponmodel2, PLAYER_Palo)
					}
					
					if(Hacha[id])
					{
						set_pev(id, pev_viewmodel2, VIEW_Hacha)
						set_pev(id, pev_weaponmodel2, PLAYER_Hacha)
					}
					
					if(Machete[id])
					{
						set_pev(id, pev_viewmodel2, VIEW_Machete)
						set_pev(id, pev_weaponmodel2, PLAYER_Machete)
					}
					
					if(Motocierra[id])
					{
						set_pev(id, pev_viewmodel2, VIEW_Moto)
						set_pev(id, pev_weaponmodel2, PLAYER_Moto)
					}
					
					
				}
			}
			case 2:
			{
				if(CTCuchillo[id] && weaponID == CSW_KNIFE)
				{
					set_pev(id, pev_viewmodel2, VIEW_MODELCT)
					set_pev(id, pev_weaponmodel2, PLAYER_MODELCT)
				}
			}
		}
		return PLUGIN_CONTINUE 
}

public fw_SetModel(entity, model[])
{
    if(!pev_valid(entity))
        return FMRES_IGNORED

    if(!equali(model, OLDWORLD_MODEL)) 
        return FMRES_IGNORED

    new className[33]
    pev(entity, pev_classname, className, 32)
    
    if(equal(className, "weaponbox") || equal(className, "armoury_entity") || equal(className, "grenade"))
    {
        engfunc(EngFunc_SetModel, entity, WORLD_MODEL)
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

public Fwd_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{

	if (!is_user_connected(id))
		return FMRES_IGNORED;
		
	if(CTCuchillo[id])
	{
		if(get_user_team(id) == 2)
		{
			if (equal(sample[8], "kni", 3))
			{
				if (equal(sample[14], "sla", 3)) 
				{
					switch (random_num(1, 2))
					{
						case 1: engfunc(EngFunc_EmitSound, id, channel, ct_slash1, volume, attn, flags, pitch)
						case 2: engfunc(EngFunc_EmitSound, id, channel, ct_slash2, volume, attn, flags, pitch)
					}
					
					return FMRES_SUPERCEDE;
				}
				if(equal(sample,"weapons/knife_deploy1.wav"))
				{
					engfunc(EngFunc_EmitSound, id, channel, ct_deploy, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				if (equal(sample[14], "hit", 3))
				{
					if (sample[17] == 'w')
					{
						engfunc(EngFunc_EmitSound, id, channel, ct_wall, volume, attn, flags, pitch)
						return FMRES_SUPERCEDE;
					}
					else 
					{
						switch (random_num(1, 4))
						{
							case 1: engfunc(EngFunc_EmitSound, id, channel, ct_hit1, volume, attn, flags, pitch)
							case 2: engfunc(EngFunc_EmitSound, id, channel, ct_hit2, volume, attn, flags, pitch)
							case 3: engfunc(EngFunc_EmitSound, id, channel, ct_hit3, volume, attn, flags, pitch)
							case 4: engfunc(EngFunc_EmitSound, id, channel, ct_hit4, volume, attn, flags, pitch)
						}
						
						return FMRES_SUPERCEDE;
					}
				}
				if (equal(sample[14], "sta", 3)) 
				{
					engfunc(EngFunc_EmitSound, id, channel, ct_stab, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
			}
		}	
	}
		
	if(TCuchillo[id])
	{
		if(get_user_team(id) == 1)
		{
			if (equal(sample[8], "kni", 3))
			{
				if (equal(sample[14], "sla", 3)) 
				{
					switch (random_num(1, 2))
					{
						case 1: engfunc(EngFunc_EmitSound, id, channel, t_slash1, volume, attn, flags, pitch)
						case 2: engfunc(EngFunc_EmitSound, id, channel, t_slash2, volume, attn, flags, pitch)
					}
					
					return FMRES_SUPERCEDE;
				}
				if(equal(sample,"weapons/knife_deploy1.wav"))
				{
					engfunc(EngFunc_EmitSound, id, channel, t_deploy, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				if (equal(sample[14], "hit", 3))
				{
					if (sample[17] == 'w') 
					{
						engfunc(EngFunc_EmitSound, id, channel, t_wall, volume, attn, flags, pitch)
						return FMRES_SUPERCEDE;
					}
					else 
					{
						switch (random_num(1, 4))
						{
							case 1: engfunc(EngFunc_EmitSound, id, channel, t_hit1, volume, attn, flags, pitch)
							case 2: engfunc(EngFunc_EmitSound, id, channel, t_hit2, volume, attn, flags, pitch)
							case 3: engfunc(EngFunc_EmitSound, id, channel, t_hit3, volume, attn, flags, pitch)
							case 4: engfunc(EngFunc_EmitSound, id, channel, t_hit4, volume, attn, flags, pitch)
						}
						
						return FMRES_SUPERCEDE;
					}
				}
				if (equal(sample[14], "sta", 3))
				{
					engfunc(EngFunc_EmitSound, id, channel, t_stab, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
			}
		}
	}
	
	if(Destapador[id])
	{
		if (equal(sample[8], "kni", 3))
		{
			if (equal(sample[14], "sla", 3)) 
			{
				switch (random_num(1, 2))
				{
					case 1: engfunc(EngFunc_EmitSound, id, channel, palo_slash1, volume, attn, flags, pitch)
					case 2: engfunc(EngFunc_EmitSound, id, channel, palo_slash2, volume, attn, flags, pitch)
					
				}
				
				return FMRES_SUPERCEDE;
			}
			if(equal(sample,"weapons/knife_deploy1.wav"))
			{
				engfunc(EngFunc_EmitSound, id, channel, palo_deploy, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if (equal(sample[14], "hit", 3))
			{
				if (sample[17] == 'w') 
				{
					engfunc(EngFunc_EmitSound, id, channel, palo_wall, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else 
				{
					switch (random_num(1, 4))
					{
						case 1:engfunc(EngFunc_EmitSound, id, channel, palo_hit1, volume, attn, flags, pitch)
						case 2:engfunc(EngFunc_EmitSound, id, channel, palo_hit2, volume, attn, flags, pitch)
						case 3:engfunc(EngFunc_EmitSound, id, channel, palo_hit3, volume, attn, flags, pitch)
						case 4:engfunc(EngFunc_EmitSound, id, channel, palo_hit4, volume, attn, flags, pitch)
					}
					
					return FMRES_SUPERCEDE;
				}
			}
			if (equal(sample[14], "sta", 3))
			{
				engfunc(EngFunc_EmitSound, id, channel, palo_stab, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	if(Hacha[id])
	{

		if (equal(sample[8], "kni", 3))
		{
			if (equal(sample[14], "sla", 3))
			{
				switch (random_num(1, 2))
				{
					case 1: engfunc(EngFunc_EmitSound, id, channel, hacha_slash1, volume, attn, flags, pitch)
					case 2: engfunc(EngFunc_EmitSound, id, channel, hacha_slash2, volume, attn, flags, pitch)
				}
				
				return FMRES_SUPERCEDE;
			}
			if(equal(sample,"weapons/knife_deploy1.wav"))
			{
				engfunc(EngFunc_EmitSound, id, channel, hacha_deploy, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if (equal(sample[14], "hit", 3))
			{
				if (sample[17] == 'w')
				{
					engfunc(EngFunc_EmitSound, id, channel, hacha_wall, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else 
				{
					switch (random_num(1, 3))
					{
						case 1: engfunc(EngFunc_EmitSound, id, channel, hacha_hit1, volume, attn, flags, pitch)
						case 2: engfunc(EngFunc_EmitSound, id, channel, hacha_hit2, volume, attn, flags, pitch)
						case 3: engfunc(EngFunc_EmitSound, id, channel, hacha_hit3, volume, attn, flags, pitch)
					}
					
					return FMRES_SUPERCEDE;
				}
			}
			if (equal(sample[14], "sta", 3)) 
			{
				engfunc(EngFunc_EmitSound, id, channel, hacha_stab, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	if(Machete[id])
	{
		if (equal(sample[8], "kni", 3))
		{
			if (equal(sample[14], "sla", 3)) 
			{
				switch (random_num(1, 2))
				{
					case 1: engfunc(EngFunc_EmitSound, id, channel, machete_slash1, volume, attn, flags, pitch)
					case 2: engfunc(EngFunc_EmitSound, id, channel, machete_slash2, volume, attn, flags, pitch)
				}
				return FMRES_SUPERCEDE;
			}
			if(equal(sample,"weapons/knife_deploy1.wav"))
			{
				engfunc(EngFunc_EmitSound, id, channel, machete_deploy, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if (equal(sample[14], "hit", 3))
			{
				if (sample[17] == 'w') 
				{
					engfunc(EngFunc_EmitSound, id, channel, machete_wall, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else // hit
				{
					switch (random_num(1, 4))
					{
						case 1: engfunc(EngFunc_EmitSound, id, channel, machete_hit1, volume, attn, flags, pitch)
						case 2: engfunc(EngFunc_EmitSound, id, channel, machete_hit2, volume, attn, flags, pitch)
						case 3: engfunc(EngFunc_EmitSound, id, channel, machete_hit3, volume, attn, flags, pitch)
						case 4: engfunc(EngFunc_EmitSound, id, channel, machete_hit4, volume, attn, flags, pitch)
					}
					return FMRES_SUPERCEDE;
				}
			}
			if (equal(sample[14], "sta", 3)) 
			{
				engfunc(EngFunc_EmitSound, id, channel, machete_stab, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	if(Motocierra[id])
	{
		
		if (equal(sample[8], "kni", 3))
		{
			if (equal(sample[14], "sla", 3))
			{
				engfunc(EngFunc_EmitSound, id, channel, motocierra_slash, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if(equal(sample,"weapons/knife_deploy1.wav"))
			{
				engfunc(EngFunc_EmitSound, id, channel, motocierra_deploy, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if (equal(sample[14], "hit", 3))
			{
				if (sample[17] == 'w') 
				{
					engfunc(EngFunc_EmitSound, id, channel, motocierra_wall, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else 
				{
					switch (random_num(1, 2))
					{
						case 1: engfunc(EngFunc_EmitSound, id, channel, motocierra_hit1, volume, attn, flags, pitch)
						case 2: engfunc(EngFunc_EmitSound, id, channel, motocierra_hit2, volume, attn, flags, pitch)
						
					}
					return FMRES_SUPERCEDE;
				}
			}
			if (equal(sample[14], "sta", 3)) 
			{
				engfunc(EngFunc_EmitSound, id, channel, motocierra_stab, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
	}	
	return FMRES_IGNORED;
}

/*============================================================
                     Stocks!
============================================================*/
stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!team", "^3") // Team Color

	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
			message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayText, _, players[i])  
			write_byte(players[i]);
			write_string(msg);
			message_end();
			}
		}
	}
}  

stock ham_strip_weapon(id,weapon[])
{
    if(!equal(weapon,"weapon_",7)) return 0;

    new wId = get_weaponid(weapon);
    if(!wId) return 0;

    new wEnt;
    while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
    if(!wEnt) return 0;

    if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);

    if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0;
    ExecuteHamB(Ham_Item_Kill,wEnt);

    set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId));

    return 1;
}