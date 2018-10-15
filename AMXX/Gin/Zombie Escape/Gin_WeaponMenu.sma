#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "Gin"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	//register_event("HLTV","NewRound","a","1=0","2=0")
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1);
}

public fw_Spawn(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	
	static menu
	if(!menu)
	{
		menu = menu_create("\rChoose your weapon","gunmenuhandler")
		menu_additem(menu,"M4A1")
		menu_additem(menu,"AK47")
		menu_additem(menu,"AWP")
		menu_additem(menu,"M3")
		menu_additem(menu,"M249")
		menu_additem(menu,"MP5")
	}
	
	menu_display(id,menu,0)
}

public gunmenuhandler(id,menu,item)
{
	if(item == MENU_EXIT)
	{
		// Stop here and don't go down (Exit from here)
		return;
	}
	
	server_print("WHAT?");
	strip_user_weapons(id)
	give_item(id,"weapon_knife")
	give_item(id,"weapon_grenade")
	cs_set_user_armor(id,100,CS_ARMOR_VESTHELM)

	new iWeapon, iAmmo;
	switch(item)
	{
		case 0:
		{
			give_item(id,"weapon_m4a1")
			iWeapon = CSW_M4A1;
			iAmmo = 90;
		}
		case 1:
		{
			give_item(id,"weapon_ak47")
			iWeapon = CSW_AK47;
			iAmmo = 90;
		}
		case 2:
		{
			give_item(id,"weapon_awp")
			iWeapon = CSW_AWP;
			iAmmo = 30;
		}
		case 3:
		{
			give_item(id,"weapon_m3")
			iWeapon = CSW_M3;
			iAmmo = 32;
		}
		case 4:
		{
			give_item(id,"weapon_m249")
			iWeapon = CSW_M249;
			iAmmo = 200;
		}
		case 5:
		{
			
			give_item(id,"weapon_mp5navy")
			iWeapon = CSW_MP5NAVY;
			iAmmo = 120;
		}
	}
	
	cs_set_user_bpammo(id, iWeapon, iAmmo);
	
	pistolmenu(id);
}

pistolmenu(id)
{
	static menu
	if( !menu ) // Create it for the first time
	{
		menu = menu_create("r\Choose your weapon","pistolmenuhandler")
		menu_additem(menu,"Deagle")
		menu_additem(menu,"Usp")
		menu_additem(menu,"Glock")
		menu_additem(menu,"Dual Elite")
	}
	
	menu_display(id,menu,0)
}

public pistolmenuhandler(id,menu,item)
{
	if(item == MENU_EXIT)
	{
		return;
	}
	
	switch(item)
	{
		case 0:
		{
			give_item(id,"weapon_deagle")
			cs_set_user_bpammo(id,CSW_DEAGLE,35)
		}
		case 1:
		{
			give_item(id,"weapon_usp")
			cs_set_user_bpammo(id,CSW_USP,100)
		}
		case 2:
		{
			give_item(id,"weapon_glock18")
			cs_set_user_bpammo(id,CSW_GLOCK18,120)
		}
		case 3:
		{
			give_item(id,"weapon_elite")
			cs_set_user_bpammo(id,CSW_ELITE,120)
		}
		
		/*
		case MENU_EXIT:
		{
			// What? o.o
			if (is_user_connected(id))
			{
				NewRound()
			}
		}*/
	}
}