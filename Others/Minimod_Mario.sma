#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <engine>
#include <xs>

#define PLUGIN "[Minimod] Mario"
#define VERSION "1.0"
#define AUTHOR "Xalus"

#define MAX_Animals 30

#define Model_Mario "mario_b3"
#define Model_Mario_Big "mario_v5"

#define Model_Coin  "models/mario/mario_coin.mdl"
#define Model_Mushroom "models/mario/mushroom_test.mdl"

#define Name_Coin 		"wall_coint"
#define Name_MultipleCoin 	"wall_coin"
#define Name_LevelTeleport 	"level"
#define Name_Finish		"finish"

const OFFSET_MODELINDEX = 491

// Player
enum _:enumPlayer
{
	plCoins,
	plLifes,
	
	plTime,
	
	Float:plHeight,
	Float:plX,
	
	plCamera,
	
	plBoost,
	
	plType,
		// 0 = Small Mario
		// 1 = Big Mario
	
	plEntity,
	plAnimal,
	plBuilding,
	
	Float:plDelay
}
new Player[33][enumPlayer]

// Animals
enum _:enumAnimals
{
	Mushroom,
	animalGoomba,
	animalTurtle
}
new const animalNames[enumAnimals][32] =
{
	"None",
	"Goomba",
	"Turtle"
}
new const animalModels[enumAnimals][50] =
{
	"",
	"models/crashball/ball_b1.mdl",
	"models/crashball/fireball_b1.mdl"
}
new const Float:animalSize[enumAnimals][2][3] =
{
	{{-15.0, -15.0, 0.0}, {15.0, 15.0, 15.0}},
	{{-15.0, -15.0, 0.0}, {15.0, 15.0, 15.0}},
	{{-15.0, -15.0, 0.0}, {15.0, 15.0, 15.0}}
}
enum _:enumSave
{
	saveType,
	saveEntity,
	
	Float:saveStartorig[3],
	Float:saveEndorig[3],
	Float:saveSpeed
}
new Animal[MAX_Animals][enumSave]

// Sounds
enum _:enumSounds
{
	soundRespawn,
	soundLife,
	
	soundCoin,
	soundJump,
	soundPipe,
	soundLevel,
	soundCrushanimal,
	soundTurtleShell,
	soundMushroom,
	
	soundDie,
	soundGameover
	
}
new const Sounds[enumSounds][] =
{
	"mario/respawned.wav",
	"mario/lifegained.wav",
	
	"mario/smb_coin.wav",
	"mario/smb_jumpsmall.wav",
	"mario/smb_pipe.wav",
	"mario/smb_stage_clear.wav",
	"mario/smb_stomp.wav",
	"mario/smb_kick.wav",
	"mario/smb_vine.wav",
	
	"mario/smb_mariodie.wav",
	"mario/smb_gameover.wav"
}

// Others
new cvarJumpHeight, cvarCamDistance, cvarCamHeight, cvarTurtleSpeed, cvarMultipleCoin

new intMariosmall, intBreakable

public plugin_precache()
{
	new szTemp[100]
	formatex(szTemp, 99, "models/player/%s/%s.mdl", Model_Mario, Model_Mario)
	intMariosmall = precache_model(szTemp)
	
	formatex(szTemp, 99, "models/player/%s/%s.mdl", Model_Mario_Big, Model_Mario_Big)
	precache_model(szTemp)
	
	for(new i = 1; i < enumAnimals; i++)
		precache_model(animalModels[i])
		
	for(new j = 0; j < enumSounds; j++)
		precache_sound(Sounds[j])
		
	precache_model(Model_Coin)
	precache_model(Model_Mushroom)
	
	intBreakable = precache_model("models/woodgibs.mdl")
}
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Register: Cvars
	cvarJumpHeight 	= register_cvar("mario_jump_height", "500")
	cvarCamDistance	= register_cvar("mario_camera_distance", "800")
	cvarCamHeight	= register_cvar("mario_camera_height", "10")
	cvarTurtleSpeed	= register_cvar("mario_turtle_speed", "300")
	cvarMultipleCoin= register_cvar("mario_multiplecoin", "4")
	
	// Register: Clclmd
	register_clcmd("say /animals", "Menu_Main")
	register_clcmd("say respawn", "Cmd_Respawn")
	register_clcmd("say origin", "Cmd_Origin")
	
	// Register: Ham
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn", 1)
	RegisterHam(Ham_Touch, "trigger_teleport", "Ham_TouchTeleport")
	RegisterHam(Ham_Touch, "info_target", "Ham_TouchAnimal")
	RegisterHam(Ham_Touch, "func_wall", "Ham_TouchCoin")
	RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage");
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled")
	
	RegisterHam(Ham_Touch, "func_door", "Ham_Semiclip_Touched", 1)
	RegisterHam(Ham_Touch, "trigger_hurt", "Ham_Semiclip_Touched", 1)
	
	// Register: Forward
	register_forward(FM_Think, "Think_PlayerCamera")
	register_forward(FM_PlayerPreThink, "Forward_PreThink")
	register_forward(FM_PlayerPostThink, "Forward_PostThink")
	
	// Register: Message
	register_message(get_user_msgid("RoundTime"), "Message_RoundTime")
	
	// Register: Logevent
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	
	// Load
	set_task(1.0, "File_Load")
}
/* Semiclip:
	- Stocks
*/
public client_connect(id)
{
	new intCamera = Player[id][plCamera]
	arrayset(Player[id], 0, enumPlayer)
	Player[id][plCamera] = intCamera
}

public Cmd_Respawn(id)
{
	for(new i = 0; i <= 12; i++)
		if(!is_user_alive(i)
		&& is_user_connected(i))
			ExecuteHamB(Ham_CS_RoundRespawn, i)
}
public Cmd_Origin(id)
{
	new Float:flOrigin[3]
	pev(id, pev_origin, flOrigin)
	
	client_print(id, print_chat, "Origin: %.2f %.2f %.2f", flOrigin[0], flOrigin[1], flOrigin[2])
}
/* Mario:
	- Messages
*/
public Message_RoundTime( const MsgId, const MsgDest, const MsgEnt )
{
	set_msg_arg_int( 1, ARG_SHORT, ((floatround(get_gametime()) - Player[MsgEnt][plTime]) + 1))
}
/* Mario:
	- Ham
*/
public Ham_Semiclip_Touched(entity, id)
{
	if(pev_valid(entity) && is_user_alive(id))
	{
		new Float:flGametime = get_gametime()
		if(Float:Player[id][plDelay] > flGametime)
			return
			
		Player[id][plDelay] = _:(flGametime + 0.5)
		
		new Float:flOrigin[3]
		pev(id, pev_origin, flOrigin)
		
		if(!is_hull_vacant(flOrigin, pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id))
		{
			ExecuteHamB(Ham_TakeDamage, id, entity, entity, 100.0, DMG_CRUSH)
		}
	}
}
public Ham_PlayerKilled(id, killer)
{
	if(is_user_connected(id))
	{
		if(Player[id][plLifes])
		{
			Player[id][plLifes]--
			client_cmd(id, "spk %s", Sounds[soundDie])
			
			set_task(3.0, "Task_RespawnPlayer", id)
		}
		else
		{
			client_cmd(id, "spk %s", Sounds[soundGameover])
		}
	}
}
		
public Ham_PlayerTakeDamage(id, inflictor, iAttacker, Float:damage, damagebits) 
{
	return (damagebits & DMG_FALL) ? HAM_SUPERCEDE : HAM_IGNORED
}
public Ham_PlayerSpawn(id)
{
	if(is_user_alive(id))
	{
		// Solid
		set_pev(id, pev_solid, SOLID_NOT)
		
		client_print(id, print_chat, "Spawned")
		
		// Timer
		Player[id][plTime] = floatround(get_gametime())
		
		// Model
		Player[id][plType] = 0
		cs_set_user_model(id, Model_Mario)
		set_pdata_int(id, OFFSET_MODELINDEX, intMariosmall) 
		
		// Player height
		new Float:vecOrigin[3]
		pev(id, pev_origin, vecOrigin)
		vecOrigin[2] += get_pcvar_float(cvarCamHeight)
		
		Player[id][plHeight] = _:vecOrigin[2]
		
		// Camera
		if(!Player[id][plBuilding])
			Create_PlayerCamera(id)
			
		// Sound
		client_cmd(id, "spk %s", Sounds[soundRespawn])
		//emit_sound(id, CHAN_ITEM, Sounds[soundRespawn], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}
public Ham_TouchTeleport(entity, id)
{
	//client_print(0, print_chat, "Teleport")
	
	if(is_user_alive(id)
	&& !task_exists(id + 357))
	{
		static strTargetname[32]
		pev(entity, pev_targetname, strTargetname, 31)
		
		if(containi(strTargetname, Name_LevelTeleport) >= 0)
		{
			replace(strTargetname, 31, Name_LevelTeleport, "")
			client_print(id, print_chat, "[Mario] Level %i", str_to_num(strTargetname))
			
			client_cmd(id, "spk %s", Sounds[soundLevel])
		}
		else if(!(pev(id, pev_button) & IN_BACK))
		{
			return HAM_SUPERCEDE
		}
		else
		{
			client_cmd(id, "spk %s", Sounds[soundPipe])
		}
		
		set_task(0.2, "Task_Teleport", id + 357)
		
		
	}
	return HAM_IGNORED
}
public Ham_TouchAnimal(entity, id)
{
	if(pev_valid(entity) && is_user_alive(id) && !Player[id][plBoost])
	{
		static strClassname[32]
		pev(entity, pev_classname, strClassname, 31)
		
		if(equal(strClassname, "Classname_Animal"))
		{
			if(pev(id, pev_groundentity) != entity)
			{
				if(Player[id][plType])
				{
					animal_kill(entity)
					Player[id][plType] = 0
					cs_set_user_model(id, Model_Mario)
				}
				else
				{
					ExecuteHamB(Ham_Killed, id, entity, 0)
				}
				animal_kill(entity)
				
				client_print(0, print_chat, "KILL! Player")
			}
			else
			{	
				Player[id][plBoost] = 1
				
				switch(pev(entity, pev_euser4))
				{
					case animalGoomba:
					{
						animal_kill(entity)
						
						client_print(0, print_chat, "KILL! Goomba")
						
						client_cmd(id, "spk %s", Sounds[soundCrushanimal])
					}
					case animalTurtle:
					{
						if(pev(entity, pev_euser1))
						{
							animal_kill(entity)
							client_print(0, print_chat, "KILL! Turtle")
							
							client_cmd(id, "spk %s", Sounds[soundCrushanimal])
						}
						else	
						{
							set_pev(entity, pev_euser1, 1)
							client_print(0, print_chat, "Shield!")
							
							client_cmd(id, "spk %s", Sounds[soundTurtleShell])
						}
					}
				}
			}
		}
		else if(equal(strClassname, "Classname_Mushroom"))
		{
			remove_entity(entity)
			Player[id][plType]++
			cs_set_user_model(id, Model_Mario_Big)
			
			client_print(0, print_chat, "You got now a BIG.... dick")
			
			client_cmd(id, "spk %s", Sounds[soundMushroom])
		}
	}
}
public Ham_TouchCoin(entity, id)
{
	if(pev_valid(entity) && is_user_alive(id))
	{
		if(pev(id, pev_groundentity) != entity
		&& !(pev(id, pev_flags) & FL_ONGROUND))
		{
			static strTargetname[32]
			pev(entity, pev_targetname, strTargetname, 31)
			
			static isMultiple
			if( (equal(strTargetname, Name_Coin) && !pev(entity, pev_euser1)) 
			|| (isMultiple = equal(strTargetname, Name_MultipleCoin)))
			{
				new intUsed
				if(isMultiple)
				{
					intUsed = pev(entity, pev_euser1)
					if(intUsed >= get_pcvar_num(cvarMultipleCoin))
						return
						
					set_pev(entity, pev_euser1, (intUsed + 1))
				}
				else
					set_pev(entity, pev_euser1, 1)
				
				// Show to everyone block has been used
				if(!isMultiple || (isMultiple && intUsed == get_pcvar_num(cvarMultipleCoin)-1))
					set_rendering(entity, kRenderFxGlowShell, 255, 255, 0, kRenderTransColor, 255)
				
				// Sound
				client_cmd(id, "spk %s", Sounds[soundCoin])
				//emit_sound(id, CHAN_ITEM, Sounds[soundCoin], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				
				// Popout coin
				new coinEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
				if( !coinEnt )
					return;
				/*
				if(isMultiple || (!isMultiple && random(5) != 3))
				{
					set_pev(coinEnt, pev_classname, "Classname_Coin")
					engfunc(EngFunc_SetModel, coinEnt, Model_Coin)
				}
				else // Mushroom!
				{
					*/
				set_pev(coinEnt, pev_classname, "Classname_Mushroom")
				engfunc(EngFunc_SetModel, coinEnt, Model_Mushroom)
				
				engfunc(EngFunc_SetSize, coinEnt, animalSize[Mushroom][0], animalSize[Mushroom][1])
					
				// Make it mushroom!
				set_pev(coinEnt, pev_euser1, 1)
			
			//}
				set_pev(coinEnt, pev_solid, SOLID_NOT)
				set_pev(coinEnt, pev_movetype, MOVETYPE_NOCLIP)
				
				new Float:flOrigin[2][3]
				pev(id, pev_origin, flOrigin[0])
				flOrigin[0][2] += 35.0
				
				flOrigin[1][0] = flOrigin[0][0]
				flOrigin[1][1] = flOrigin[0][1]
				flOrigin[1][2] = (flOrigin[0][2] + 20.0)
				
				engfunc(EngFunc_SetOrigin, coinEnt, flOrigin[0])
				
				new Float:flVec[3]
				get_speed_vector(flOrigin[0], flOrigin[1], 150.0, flVec)
				
				set_pev(coinEnt, pev_velocity, flVec)
				
				set_task(0.3, "Task_RemoveCoin", coinEnt)
			}
			else if(Player[id][plType])
			{
				client_print(id, print_chat, "Target: %s", strTargetname)
				
				set_pev(entity, pev_solid, SOLID_NOT)
				set_rendering(entity, kRenderFxGlowShell, 255, 255, 0, kRenderTransColor, 0)
				Breakable_effect(id)
			}	
		}
	}
}
public Ham_MushroomThink(entity)
{
	if(pev_valid(entity))
	{
		static strClassname[32]
		pev(entity, pev_classname, strClassname, 31)
		
		if(equal(strClassname, "Classname_Mushroom"))
		{
			drop_to_floor(entity)
			set_pev(entity, pev_nextthink, get_gametime())
		}
	}
}
/* Mario:
	- Foward
*/
public Forward_PreThink(id)
{
	if(!is_user_alive(id))
	{
		if(is_user_connected(id)
		&& pev(id, pev_iuser1))
		{
			static intSpectating
			intSpectating = pev(id, pev_iuser2)
			
			if(pev_valid(Player[intSpectating][plCamera]))
				engfunc(EngFunc_SetView, id, Player[intSpectating][plCamera])
			
			return
		}
	}
	set_pev(id, pev_solid, SOLID_SLIDEBOX)
	
	if(!Player[id][plBuilding])
	{
		// Small mario
		/*if(!Player[id][plType])
		{
			set_pev(id, pev_button, pev(id, pev_button) | IN_DUCK)
		}*/
		
		// Angle System
		set_pev(id, pev_angles, Float:{0.0, 180.0, 0.0})
		set_pev(id, pev_v_angle, Float:{0.0, 180.0, 0.0})
		set_pev(id, pev_fixangle, 1)

		// Boost | Jump system
		static intButton//, intOldbutton
		intButton = pev(id, pev_button)
		//intOldbutton = pev(id, pev_oldbuttons)
		
		if(Player[id][plBoost]
		&& pev(id, pev_flags) & FL_ONGROUND)
		{
			new Float:vecBoost[3]
			pev(id, pev_velocity, vecBoost)
			vecBoost[2] = 350.0
			set_pev(id, pev_velocity, vecBoost)
			
			Player[id][plBoost] = 0
			
			client_cmd(id, "spk %s", Sounds[soundJump])
		}
		else if( (intButton & IN_JUMP || intButton & IN_FORWARD) // && !(intOldbutton & IN_JUMP) && !(intOldbutton & IN_FORWARD)
		&& pev(id, pev_flags) & FL_ONGROUND)
		{
			static Float:flHeight 
			flHeight = get_pcvar_float(cvarJumpHeight)
			
			new Float:vecJump[3]
			pev(id, pev_velocity, vecJump)
			vecJump[2] = flHeight
			set_pev(id, pev_velocity, vecJump)
			
			client_cmd(id, "spk %s", Sounds[soundJump])
		}
	}
}
public Forward_PostThink(id)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_solid, SOLID_NOT)
}
/* Mario:
	- Logevent
*/
public Event_RoundStart()
{
	for(new i = 0; i < MAX_Animals; i++)
	{
		if(pev_valid(Animal[i][saveEntity])
		&& Animal[i][saveType])
		{
			animal_repair(Animal[i][saveEntity])
		}
	}
	new ent
	while( (ent = find_ent_by_class(ent, "func_wall")) )
	{
		set_rendering(ent)
		set_pev(ent, pev_solid, SOLID_BBOX)
		set_pev(ent, pev_euser1, 0)
	}
	remove_entity_name("Classname_Mushroom")
}
/* Mario:
	- Menus
*/
public Menu_Main(id)
{
	new strTemp[100]
	formatex(strTemp, 99, "\dMario:\w Animal Menu^n     \yBy Xalus v%s", VERSION)
	new menu = menu_create(strTemp, "Handler_Main")
	
	menu_additem(menu, Player[id][plBuilding] ? "Building:\y Enabled": "Building", "0")
	
	menu_additem(menu, "Create", "1")
	menu_additem(menu, "Remove^n", "2")
	
	menu_additem(menu, "Save", "3")
	
	menu_display(id, menu)
}
public Handler_Main(id, menu, item)
{
	if(item == MENU_EXIT
	|| !is_user_admin(id))
		menu_destroy(menu)
	else
	{
		switch(MenuKey(menu, item))
		{
			case 0: // Building mode
			{
				Player[id][plBuilding] = !Player[id][plBuilding]
				
				if(!Player[id][plBuilding])
				{
					Create_PlayerCamera(id)
					set_user_gravity(id)
				}
				else
				{
					engfunc(EngFunc_SetView, id, id)
					set_user_gravity(id, 0.4)
				}
				Menu_Main(id)
			}
			case 1: // Create
			{
				Menu_CreateAnimal(id)
			}
			case 2: // Remove
			{
				new intEntity, intBody
				get_user_aiming(id, intEntity, intBody)
				
				if(pev_valid(intEntity))
				{
					static strClassname[32]
					pev(intEntity, pev_classname, strClassname, 31)
					
					if(equal(strClassname, "Classname_Animal"))
					{
						new intID = pev(intEntity, pev_euser3)
						Animal[intID][saveType] = 0
						
						engfunc(EngFunc_RemoveEntity, intEntity)
					}
				}
				Menu_Main(id)
			}
			case 3: // Save
			{
				File_Save(id)
				
				Menu_Main(id)
			}
		}
	}
}
public Menu_CreateAnimal(id)
{
	new strTemp[100]
	formatex(strTemp, 99, "\dMario:\w Create Animal^n     \yBy Xalus v%s", VERSION)
	new menu = menu_create(strTemp, "Handler_CreateAnimal")
	
	menu_additem(menu, pev_valid(Player[id][plEntity]) ? "Destroy^n" : "Create^n", "1")
	
	if(pev_valid(Player[id][plEntity]))
	{
		formatex(strTemp, 99, "\wType:\y %s^n", animalNames[Player[id][plAnimal]])
		menu_additem(menu, strTemp, "2")
		
		new intID = pev(Player[id][plEntity], pev_euser3)
		
		formatex(strTemp, 99, "\wStart:\y %.2f %.2f %.2f", Float:Animal[intID][saveStartorig], Float:Animal[intID][saveStartorig+1], Float:Animal[intID][saveStartorig+2])
		menu_additem(menu, strTemp, "3")
		
		formatex(strTemp, 99, "\wEnd:\y %.2f %.2f %.2f", Float:Animal[intID][saveEndorig], Float:Animal[intID][saveEndorig+1], Float:Animal[intID][saveEndorig+2])
		menu_additem(menu, strTemp, "4")
		
		if(!Animal[intID][saveSpeed])
			Animal[intID][saveSpeed] = 50
		
		formatex(strTemp, 99, "\wSpeed:\y %.1f^n^n", Float:Animal[intID][saveSpeed])
		menu_additem(menu, strTemp, "5")
		
		menu_additem(menu, "\yActivate!", "6")
	}
	menu_display(id, menu)
}
public Handler_CreateAnimal(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		
		if(pev_valid(Player[id][plEntity]))
		{
			destroy_entity(id)
		}
		Menu_Main(id)
	}
	else
	{
		new intKey
		switch( (intKey = MenuKey(menu, item)) )
		{
			case 1: // Create | Destroy
			{
				if(pev_valid(Player[id][plEntity]))
				{
					destroy_entity(id)
				}
				else
				{
					Player[id][plEntity] = Create_Animal(id)
				}
				Menu_CreateAnimal(id)
			}
			case 2: // Animal type
			{
				Menu_Animal(id)
			}
			case 3, 4: // Start- / End origin
			{
				pev(id, pev_origin, Float:Animal[pev(Player[id][plEntity], pev_euser3)][ (intKey == 3) ? saveStartorig : saveEndorig ])
				Menu_CreateAnimal(id)
			}
			case 5: // Speed
			{
				new intID = pev(Player[id][plEntity], pev_euser3)
				Animal[intID][saveSpeed] += 25
				
				if(Animal[intID][saveSpeed] > 150)
					Animal[intID][saveSpeed] = 50
					
				Menu_CreateAnimal(id)
			}
			case 6: // Activate
			{
				new intID = pev(Player[id][plEntity], pev_euser3)
				
				if(!Player[id][plAnimal] || Float:Animal[intID][saveStartorig] == 0.0 || Float:Animal[intID][saveEndorig] == 0.0)
				{
					client_print(id, print_center, "Your settings are wrong, recheck!")
					Menu_CreateAnimal(id)
				}
				else // Activate!
				{
					animal_activate(Player[id][plEntity], Player[id][plAnimal])
					
					Player[id][plEntity] = 0
					
					Menu_CreateAnimal(id)
				}
			}
		}
	}
}
public Menu_Animal(id)
{
	new strTemp[100]
	formatex(strTemp, 99, "\dMario:\w Animals^n     \yBy Xalus v%s", VERSION)
	new menu = menu_create(strTemp, "Handler_Animal")
	
	new strKey[6]
	for(new i = 1; i < enumAnimals; i++)
	{
		num_to_str(i, strKey, 5)
		menu_additem(menu, animalNames[i], strKey)
	}
	menu_display(id, menu)
}
public Handler_Animal(id, menu, item)
{
	if(item == MENU_EXIT)
		menu_destroy(menu)
	else
		Player[id][plAnimal] = MenuKey(menu, item)
		
	Menu_CreateAnimal(id)
}
/* Mario:
	- Animal Moving
*/
public Move_Animal(entity)
{
	remove_task(entity)
	
	if(pev_valid(entity))
	{
		if(pev(entity, pev_solid) == SOLID_NOT)
			return
		
		static intID
		intID = pev(entity, pev_euser3)
		
		new Float:flStartorig[3]
		flStartorig[0] = Float:Animal[intID][saveStartorig]
		flStartorig[1] = Float:Animal[intID][saveStartorig+1]
		flStartorig[2] = Float:Animal[intID][saveStartorig+2]
		
		new Float:flEndorig[3]
		flEndorig[0] = Float:Animal[intID][saveEndorig]
		flEndorig[1] = Float:Animal[intID][saveEndorig+1]
		flEndorig[2] = Float:Animal[intID][saveEndorig+2]
		
		new Float:flSpeed 
		flSpeed = (pev(entity, pev_euser1) && Animal[intID][saveType] == animalTurtle) ? get_pcvar_float(cvarTurtleSpeed) : Float:Animal[intID][saveSpeed] 
		
		new Float:flVec[3], intMove
		if( (intMove = pev(entity, pev_euser2)) )
		{
			engfunc(EngFunc_SetOrigin, entity, flEndorig)
			get_speed_vector(flEndorig, flStartorig, flSpeed, flVec)
		}
		else
		{
			engfunc(EngFunc_SetOrigin, entity, flStartorig)
			get_speed_vector(flStartorig, flEndorig, flSpeed, flVec)
		}
		
		set_pev(entity, pev_euser2, !intMove)
		set_pev(entity, pev_velocity, flVec)
	
		set_task( (vector_distance(flStartorig, flEndorig) / flSpeed), "Move_Animal", entity)
	}
}
/* Mario:
	- Tasks
*/
public Task_Teleport(id)
{
	id -= 357
	
	new Float:vecOrigin[3]
	pev(id, pev_origin, vecOrigin)
		
	Player[id][plHeight] = _:vecOrigin[2]
}
public Task_DisappearAnimal(entity)
	if(pev_valid(entity))
		animal_disappear(entity)
		
public Task_RemoveCoin(entity)
{
	if(pev_valid(entity))
	{
		if(pev(entity, pev_euser1) == 1) // Mushroom!
		{
			set_pev(entity, pev_velocity, Float:{0.0, 0.0, 0.0})
			
			new Float:flOrigin[3][3]
			pev(entity, pev_origin, flOrigin[0])
			flOrigin[0][2] += 10.0
			set_pev(entity, pev_origin, flOrigin[0])
			
			drop_to_floor(entity)
			
			pev(entity, pev_origin, flOrigin[0])
			
			set_pev(entity, pev_solid, SOLID_BBOX)
			set_pev(entity, pev_movetype, MOVETYPE_BOUNCE)
			
			origin_behind(Float:{0.0, -90.0, 0.0}, flOrigin[0], 1000.0, flOrigin[1])
			
			get_speed_vector(flOrigin[0], flOrigin[1], 100.0, flOrigin[2])
			set_pev(entity, pev_velocity, flOrigin[2])
			
			RegisterHamFromEntity(Ham_Think, entity, "Ham_MushroomThink")
			set_pev(entity, pev_nextthink, get_gametime())
		}
		else
		{
			engfunc(EngFunc_RemoveEntity, entity)
		}
	}
}	
public Task_RespawnPlayer(id)
{
	if(is_user_connected(id)
	&& !is_user_alive(id))
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
}
/* Mario:
	- View System
*/
Create_PlayerCamera( id )
{
	if(pev_valid(Player[id][plCamera]))
	{
		set_pev(Player[id][plCamera], pev_nextthink, get_gametime())
		engfunc(EngFunc_SetView, id, Player[id][plCamera])
		return;
	}
	Player[id][plCamera] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if( !Player[id][plCamera] )
		return;
	
	set_pev(Player[id][plCamera], pev_classname, "PlayerCamera")
	engfunc(EngFunc_SetModel, Player[id][plCamera], "models/w_usp.mdl")
	
	set_pev(Player[id][plCamera], pev_solid, SOLID_TRIGGER)
	set_pev(Player[id][plCamera], pev_movetype, MOVETYPE_FLYMISSILE)
	set_pev(Player[id][plCamera], pev_owner, id)
	
	set_pev(Player[id][plCamera], pev_rendermode, kRenderTransTexture)
	set_pev(Player[id][plCamera], pev_renderamt, 0.0)
	
	set_pev(Player[id][plCamera], pev_angles, Float:{0.0, 180.0, 0.0})
	set_pev(Player[id][plCamera], pev_v_angle, Float:{0.0, 180.0, 0.0})
	set_pev(Player[id][plCamera], pev_punchangle, 1.0)
	
	engfunc(EngFunc_SetView, id, Player[id][plCamera])
	set_pev(Player[id][plCamera], pev_nextthink, get_gametime())
}
public Think_PlayerCamera( iEnt )
{
	static sClassname[32];
	pev( iEnt, pev_classname, sClassname, sizeof sClassname - 1 );
	
	if( !equal( sClassname, "PlayerCamera" ) )
		return FMRES_IGNORED;
	
	static iOwner;
	iOwner = pev( iEnt, pev_owner );
	
	if( !is_user_alive( iOwner ) )
		return FMRES_IGNORED;
	
	static Float:fOrigin[3], Float:flDistance;
	pev(iOwner, pev_origin, fOrigin);
	flDistance = get_pcvar_float(cvarCamDistance)
	
	fOrigin[0] = flDistance
	fOrigin[2] = Float:Player[iOwner][plHeight]
	
	engfunc( EngFunc_SetOrigin, iEnt, fOrigin );
	
	set_pev( iEnt, pev_nextthink, get_gametime() );
	
	return FMRES_HANDLED;
}
/* Mario:
	- File Save/Load
*/
public File_Save(id) 
{
	new szFile[64], szMapName[32];
	get_datadir(szFile, sizeof szFile - 1);
	get_mapname(szMapName, sizeof szMapName - 1);
		
	format(szFile, sizeof szFile - 1, "%s/Mario/%s.ini", szFile, szMapName);
	
	new iFile = fopen(szFile, "wt+");
	
	new intResults
	for(new i = 0; i < MAX_Animals; i++)
	{
		if(Animal[i][saveType])
		{
			fprintf(iFile, "^"0^" ^"%i^" ^"%f^" ^"%.1f;%.1f;%.1f^" ^"%.1f;%.1f;%.1f^"^n", Animal[i][saveType], Float:Animal[i][saveSpeed], Float:Animal[i][saveStartorig], Float:Animal[i][saveStartorig+1], Float:Animal[i][saveStartorig+2], Float:Animal[i][saveEndorig], Float:Animal[i][saveEndorig+1], Float:Animal[i][saveEndorig+2]);
			intResults++
		}
	}
	fclose(iFile);
	
	client_print(id, print_center, "Saved %i animals in %s", intResults, szMapName)
}
public File_Load() 
{
	new szFile[64], szMapName[32];
	get_datadir(szFile, sizeof szFile - 1);
	get_mapname(szMapName, sizeof szMapName - 1);
	
	add(szFile, sizeof szFile - 1, "/Mario");
	
	if(!dir_exists(szFile))
		mkdir(szFile);
	
	format(szFile, sizeof szFile - 1, "%s/%s.ini", szFile, szMapName);
	
	new iFile = fopen(szFile, "at+");
	
	new szBuffer[256];
	new szType[6], szId[6], szSpeed[6], szOriginStart[64], szOriginEnd[64]
	new szTemp[3][32]
	
	new intID
	while(!feof(iFile)) 
	{
		fgets(iFile, szBuffer, sizeof szBuffer - 1);
		
		if(!szBuffer[0])
			continue;
		
		parse(szBuffer, szType, sizeof szType - 1, szId, sizeof szId - 1, szSpeed, sizeof szSpeed - 1, szOriginStart, sizeof szOriginStart - 1, szOriginEnd, sizeof szOriginEnd - 1);
		
		Animal[intID][saveType] = str_to_num(szType)
		Animal[intID][saveSpeed] = _:str_to_float(szSpeed)
		
		str_piece(szOriginStart, szTemp, sizeof szTemp, sizeof szTemp[] - 1, ';');
		Animal[intID][saveStartorig] = _:str_to_float(szTemp[0])
		Animal[intID][saveStartorig+1] = _:str_to_float(szTemp[1])
		Animal[intID][saveStartorig+2] = _:str_to_float(szTemp[2])
		
		str_piece(szOriginEnd, szTemp, sizeof szTemp, sizeof szTemp[] - 1, ';');
		Animal[intID][saveEndorig] = _:str_to_float(szTemp[0])
		Animal[intID][saveEndorig+1] = _:str_to_float(szTemp[1])
		Animal[intID][saveEndorig+2] = _:str_to_float(szTemp[2])
		
		if(Create_Animal(0, intID))
			animal_activate(Animal[intID][saveEntity], Animal[intID][saveType])
		
		intID++
	}
	fclose(iFile);
	return 1;
}
/* Mario:
	- Stocks
*/
stock MenuKey(menu, item) 
{
	new szData[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, szData, charsmax(szData), szName, charsmax(szName), callback);
	
	menu_destroy(menu)
	
	return str_to_num(szData);
}
stock destroy_entity(id)
{
	if(pev_valid(Player[id][plEntity]))
	{
		Animal[pev(Player[id][plEntity], pev_euser3)][saveType] = 0
		engfunc(EngFunc_RemoveEntity, Player[id][plEntity])
			
		Player[id][plEntity] = 0
	}
}
stock get_free_slot()
{
	for(new i = 0; i < MAX_Animals; i++)
		if(!Animal[i][saveType])
			return i
	return -1
}
stock Create_Animal(id, intSlot=-1)
{
	if(intSlot == -1)
	{
		intSlot = get_free_slot()
		if(intSlot == -1)
		{
			client_print(id, print_center, "Maximum of animals has been reached")
			return 0
		}
	}
	
	new iEnt
	iEnt = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) )
	
	if( !iEnt )
		return 0
		
	set_pev( iEnt, pev_classname, "Classname_Animal");
	engfunc( EngFunc_SetModel, iEnt, "models/w_usp.mdl")
	
	set_pev(iEnt, pev_solid, SOLID_BBOX)
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	
	set_pev(iEnt, pev_euser3, intSlot)
	Animal[intSlot][saveType] = 1
	Animal[intSlot][saveEntity] = iEnt
	
	set_pev(iEnt, pev_angles, Float:{0.0, 90.0, 0.0})
	set_pev(iEnt, pev_v_angle, Float:{0.0, 90.0, 0.0})
	set_pev(iEnt, pev_punchangle, 1.0)

	return iEnt
}
stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3]) 
{
	new_velocity[0] = origin2[0] - origin1[0];
	new_velocity[1] = origin2[1] - origin1[1];
	new_velocity[2] = origin2[2] - origin1[2];
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]));
	new_velocity[0] *= num;
	new_velocity[1] *= num;
	new_velocity[2] *= num;

	return 1;
}
stock origin_behind(const Float:vAngles[3], const Float:vecOrigin[ 3 ], Float:flDistance, Float:vecOutput[ 3 ])
{
	static Float:vecAngles[3]
	xs_vec_copy(vAngles, vecAngles)
	
	engfunc( EngFunc_MakeVectors, vecAngles );
	global_get( glb_v_forward, vecAngles );
	
	xs_vec_mul_scalar( vecAngles, -flDistance, vecAngles );
	
	xs_vec_add( vecOrigin, vecAngles, vecOutput );
}
stock str_piece(const input[], output[][], outputsize, piecelen, token = '|') {
	new i = -1, pieces, len = -1 ;
	
	while ( input[++i] != 0 ) {
		if ( input[i] != token ) {
			if ( ++len < piecelen )
				output[pieces][len] = input[i];
		}
		else {
			output[pieces++][++len] = 0 ;
			len = -1 ;
			
			if ( pieces == outputsize )
				return pieces ;
		}
	}
	return pieces + 1;
}
stock animal_kill(entity)
{
	set_pev(entity, pev_solid, SOLID_NOT)
	set_pev(entity, pev_movetype, MOVETYPE_NOCLIP)
	set_pev(entity, pev_velocity, Float:{0.0, 0.0, 0.0})
	
	// Get twice the origin
	new Float:flOrigin[2][3]
	pev(entity, pev_origin, flOrigin[0])
	
	flOrigin[1][0] = flOrigin[0][0]
	flOrigin[1][1] = flOrigin[0][1]
	flOrigin[1][2] = (flOrigin[0][2] - 30.0)
	
	// Move down
	new Float:flVec[3]
	get_speed_vector(flOrigin[0], flOrigin[1], 100.0, flVec)
	set_pev(entity, pev_velocity, flVec)
	
	// Disappear
	set_task(0.7, "Task_DisappearAnimal", entity)
}		
stock animal_disappear(entity)
{
	set_pev(entity, pev_rendermode, kRenderTransTexture)
	set_pev(entity, pev_renderamt, 0.0)
}
stock animal_repair(entity)
{
	set_pev(entity, pev_velocity, Float:{0.0, 0.0, 0.0})
	
	engfunc(EngFunc_SetOrigin, entity, Float:Animal[pev(entity, pev_euser3)][saveStartorig])
	
	set_pev(entity, pev_solid, SOLID_BBOX)
	set_pev(entity, pev_movetype, MOVETYPE_FLY)
	set_pev(entity, pev_rendermode, kRenderTransTexture)
	set_pev(entity, pev_renderamt, 255.0)
	
	set_pev(entity, pev_euser2, 0)
	
	Move_Animal(entity)
}
stock animal_activate(entity, animal)
{
	engfunc(EngFunc_SetModel, entity, animalModels[animal])
	engfunc(EngFunc_SetSize, entity, animalSize[animal][0], animalSize[animal][1])
	set_pev(entity, pev_euser4, animal)
	
	new intID = pev(entity, pev_euser3)
	Animal[intID][saveType] = animal
		
	set_pev(entity, pev_origin, Float:Animal[intID][saveStartorig])
	drop_to_floor(entity)
					
	new Float:flOrigin[3]
	pev(entity, pev_origin, flOrigin)
	Animal[intID][saveStartorig+2] = _:flOrigin[2]
	Animal[intID][saveEndorig+2] = _:flOrigin[2]
				
	Move_Animal(entity)
}
stock bool:is_hull_vacant(const Float:origin[3], hull,id) {
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
		return true
	
	return false
}
stock Breakable_effect(entity) 
{
	static arrayOrigin[3]
	get_user_origin(entity, arrayOrigin)
	arrayOrigin[2] += 20
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, arrayOrigin)
	
	write_byte(108)
	write_coord(arrayOrigin[0])
	write_coord(arrayOrigin[1])
	write_coord(arrayOrigin[2])
	write_coord(0)
	write_coord(0)
	write_coord(0)
	write_coord(5)
	write_coord(5)
	write_coord(5)
	write_byte(15)
	write_short(intBreakable)
	write_byte(50)
	write_byte(50)
	write_byte(0)
	
	message_end()
}