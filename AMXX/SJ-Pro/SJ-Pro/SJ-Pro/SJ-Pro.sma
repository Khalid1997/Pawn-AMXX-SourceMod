#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <amxmisc>
#include <csx>
#include <nvault>
#include <maths>
//#include <Sj-Pro>
#include <hamsandwich>
#include <xs>

//#pragma semicolon 1;



#define VAULTNAMEEXP 	"Sj-Pro_Exp"
#define VAULTNAMERANK 	"Sj-Pro_Rank"
#define VAULTNAMETOP 	"Sj-Pro_Top"



/*

#define ADMIN_LEVEL			ADMIN_MENU	//admin access level to use this plugin. ADMIN_MENU = flag 'u'
#define MAIN_MENU_KEYS		(1<<0)|(1<<1)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<9)

enum { N1, N2, N3, N4, N5, N6, N7, N8, N9, N0 };
new const X = 0;
new const Y = 1;
new const Z = 2;			//for some reason I got tag mismatch on Z when using an enum

new gszMainMenuText[256];

new const spr_teams[] = "sprites/PersonClock.spr";
new const spr_digits[] = "sprites/clock_digits.spr";
new const spr_tiempo[] = "sprites/Tiempo.spr";

new const gszPrefix[] = "[CM] ";

// Clases de carteles

new const class_infotarget[] = "info_target";
new const class_team[] = "cartel_team";
new const class_digito[] = "cartel_digito";
new const class_tiempo[] = "cartel_tiempo";

new const Float:gfDigitOffsetMultipliers[2] = {0.3, 0.75};
new const Float:gfClockSize[2] = {40.0, 32.0};
new const Float:gfTitleSize = 16.0;

new FileCartel[128];

const gteamTypesMax = 2;

//clock types
enum
{
	SJ_CT,
	SJ_TERROR,
	SJ_TIME
};

new gClockSaveIds[gteamTypesMax] =
{
	'C', 'T'
};

*/

static const AUTHOR[] = "L//"
static const VERSION[] = "6.0b"

//#define NAME_SERVER		"Sj-Pro 6.0a"

///////////////////////////////////////////////////////////////////////////////////  
//////////////////////////////////  PERFECT SELECT	///////////////////////////////
/////////////////////////////////////////////////////////////////////////////////// 

#define MENSAGE_SERVER	"- Estas jugando Sj-Pro -^n^n"

#pragma dynamic 131072 //I used to much memory =(

/* ------------------------------------------------------------------------- */
/* /----------------------- START OF CUSTOMIZATION  -----------------------/ */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/* /------------  CUSTOM DEFINES  ------------ CUSTOM DEFINES  ------------/ */
/* ------------------------------------------------------------------------- */

//When player reaches MAX level, they receive this many levels.

#define MAX_LVL_BONUS 1
#define MAX_LVL_POWERPLAY 10
#define DISARM_MULTIPLIER 	2

#define TEAMS 4 //Don't edit this.

static const TeamNames[TEAMS][32] 

/* ------------------------------------------------------------------------- */
/* /----------------  MODELS  ---------------- MODELS  ----------------/ */
/* ------------------------------------------------------------------------- */

new ball[256]

static const TeamMascots[2][] = {
	"models/controller.mdl",//"models/kingpin.mdl",	//TERRORIST MASCOT
	"models/agrunt.mdl"//"models/garg.mdl"	//CT MASCOT
}


/* ------------------------------------------------------------------------- */
/* /----------------  SOUNDS  ---------------- SOUNDS  ----------------/ */
/* ------------------------------------------------------------------------- */


/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/* /------------------------ END OF CUSTOMIZATION  ------------------------/ */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */

/* ------------ DO NOT EDIT BELOW ---------------------------------------------------------- */
/* -------------------------- DO NOT EDIT BELOW -------------------------------------------- */
/* --------------------------------------- DO NOT EDIT BELOW ------------------------------- */
/* ---------------------------------------------------- DO NOT EDIT BELOW ------------------ */

#define MAX_TEXT_BUFFER		2047
#define MAX_PLAYER			32
#define MAX_ASSISTERS		3
#define MAX_BALL_SPAWNS		5
#define POS_X 				-1.0
#define POS_Y 				0.85
#define HUD_CHANNEL			 4
#define MESSAGE_DELAY 		4.0

#define MAX_LINE_MODELS 200
#define BOCHA_COLORS 12
#define PLAYER_COLORS 31
#define NUM_MODELS 7
#define NUM_SPRITES 8
#define NUM_SOUNDS 27

#define NOMBRETEAMCT		"NOMBRE_TEAM_CT"
#define NOMBRETEAMTT		"NOMBRE_TEAM_TT"
#define NOMBRETEAMSPEC		"NOMBRE_TEAM_SPEC"

#define BOCHAGLOW 			"BOCHA_GLOW"
#define BOCHACOLORBEAMCT 	"BOCHA_COLOR_BEAM_CT"
#define BOCHACOLORBEAMTT 	"BOCHA_COLOR_BEAM_TT"
#define BEAMGROSOR 			"BEAM_GROSOR"
#define BEAMLIFE 			"BEAM_LIFE"
#define BOCHABRILLO 		"BOCHA_BRILLO"

#define PLAYERCOLORGLOWCT 	"PLAYER_COLOR_GLOW_CT"
#define PLAYERCOLORGLOWTT 	"PLAYER_COLOR_GLOW_TT"
#define ARQUEROCOLORGLOWCT 	"ARQUERO_COLOR_GLOW_CT"
#define ARQUEROCOLORGLOWTT 	"ARQUERO_COLOR_GLOW_TT"
#define PLAYERGROSORGLOW 	"PLAYER_GROSOR_GLOW"
#define ARQUEROGROSORGLOW 	"ARQUERO_GROSOR_GLOW"

#define COLORGLOWOFFSIDE	"COLOR_GLOW_OFFSIDE"
#define GROSORGLOWOFFSIDE	"GROSOR_GLOW_OFFSIDE"
#define COLORGLOWFOUL		"COLOR_GLOW_FOUL"
#define GROSORGLOWFOUL		"GROSOR_GLOW_FOUL"

#define COLORTURBOCT		"COLOR_TURBO_CT"
#define COLORTURBOTT		"COLOR_TURBO_TT"
#define COLORCARTELSCORE	"COLOR_CARTEL_SCORE"

#define MODELBOCHA			"MODEL_BOCHA"
#define MODELARQUEROCT		"MODEL_ARQUERO_CT"
#define MODELARQUEROTT		"MODEL_ARQUERO_TT"
#define VMODELFAKAARQUERO	"V_MODEL_FAKA_ARQUERO"
#define PMODELFAKAARQUERO	"P_MODEL_FAKA_ARQUERO"
#define VMODELFAKAPLAYER	"V_MODEL_FAKA_PLAYER"
#define PMODELFAKAPLAYER	"P_MODEL_FAKA_PLAYER"

#define EXPLOSIONGOL 		"EXPLOSION_GOL"
#define EFECTOHUMO 			"EFECTO_HUMO"
#define POWERPLAY 			"POWER_PLAY"
#define RAYOMASCOTA 		"RAYO_MASCOTA"
#define FESTEJOGOL 			"FESTEJO_GOL"
#define FESTEJOGOLENCONTRA 	"FESTEJO_GOL_EN_CONTRA"
#define BOCHABEAM 			"BOCHA_BEAM"
#define LINEAOFFSIDE 		"LINEA_OFFSIDE"

#define GOL1 				"GOL_1"
#define GOL2 				"GOL_2"
#define GOL3 				"GOL_3"
#define GOL4				"GOL_4"
#define GOL5 				"GOL_5"
#define GOL6 				"GOL_6"
#define GOLENCONTRA1 		"GOL_EN_CONTRA_1"
#define GOLENCONTRA2 		"GOL_EN_CONTRA_2"
#define GOLENCONTRA3 		"GOL_EN_CONTRA_3"
#define GOLENCONTRA4		"GOL_EN_CONTRA_4"
#define GOLENCONTRA5 		"GOL_EN_CONTRA_5"
#define PUSSY				"PUSSY"
#define INICIORONDA 		"INICIO_RONDA"
#define BOCHAPIQUE 			"BOCHA_PIQUE"
#define BOCHARECIBIDA 		"BOCHA_RECIBIDA"
#define BOCHARESPAWN 		"BOCHA_RESPAWN"
#define GOLMARCADO 			"GOL_MARCADO"
#define BOCHAPASE 			"BOCHA_PASE"
#define FULLSKILL 			"FULL_SKILL"
#define VICTORIA 			"VICTORIA"
#define TELEPORTCABINA 		"TELEPORT_CABINA"
#define KILLCONBOCHA 		"KILL_CON_BOCHA"
#define TEDESARMAN 			"TE_DESARMAN"
#define DESARMAS 			"DESARMAS"
#define SERARQUERO 			"SER_ARQUERO"
#define NOSERARQUERO 		"NO_SER_ARQUERO"
#define SILBATO 			"SILBATO"


#define	MAXLVLSTAMINA 		"MAX_LVL_VIDA"
#define	MAXLVLSTRENGTH		"MAX_LVL_FUERZA"
#define	MAXLVLAGILITY		"MAX_LVL_AGILIDAD"
#define MAXLVLDEXTERITY		"MAX_LVL_DESTREZA"
#define	MAXLVLDISARM		"MAX_LVL_DISARM"

#define	EXPPRICESTAMINA		"EXP_PRECIO_VIDA"
#define	EXPPRICESTRENGTH	"EXP_PRECIO_FUERZA"
#define	EXPPRICEAGILITY		"EXP_PRECIO_AGILIDAD"
#define	EXPPRICEDEXTERITY	"EXP_PRECIO_DESTREZA"
#define	EXPPRICEDISARM		"EXP_PRECIO_DISARM"

#define EXPGOLEQUIPO		"EXP_GOL_EQUIPO"
#define EXPROBO				"EXP_ROBO"
#define EXPBALLKILL			"EXP_BALLKILL"
#define EXPASISTENCIA		"EXP_ASISTENCIA"
#define EXPGOL				"EXP_GOL"

#define BASEHP				"VIDA_INICIAL"
//#define BASESPEED			"SPEED_INICIAL"
#define BASEDISARM			"DISARM_INICIAL"

#define CUENTAREGRESIVA		"CUENTA_REGRESIVA"
#define TIEMPOEXPCAMPEAR	"TIEMPO_EXP_CAMPEAR"

#define CURVEANGLE			"COMBA_ANGULO"
#define CURVECOUNT			"COMBA_VECES_CURVA"
//#define CURVETIME			"COMBA_TIEMPO"
#define DIRECTIONS			"COMBA_CUANTAS"
#define ANGLEDIVIDE			"COMBA_DIVISION"

#define AMOUNTLATEJOINEXP	"EXP_TARDE"
#define AMOUNTPOWERPLAY		"PP_AUMENTO_SKILL"
#define AMOUNTGOALY 		"EXP_CAMPEAR"

#define AMOUNTSTA			"CANT_VIDA_POR_LVL"
#define AMOUNTSTR			"CANT_FUERZA_POR_LVL"
#define AMOUNTAGI			"CANT_AGILIDAD_POR_LVL"
#define AMOUNTDEX			"CANT_DESTREZA_POR_LVL"
#define AMOUNTDISARM		"CANT_DISARM_POR_LVL"

#define RANKGOL				"RANK_GOL"
#define RANKGOLENCONTRA		"RANK_GOL_EN_CONTRA"
#define RANKROBO			"RANK_ROBO"
#define RANKREGALO			"RANK_REGALO"
#define RANKASISTENCIA		"RANK_ASISTENCIA"
#define RANKBALLKILL		"RANK_BALLKILL"
#define RANKRVBALLKILL		"RANK_RV_BALLKILL"
#define RANKDISARM			"RANK_DISARM"
#define RANKRVDISARM		"RANK_RV_DISARM"

#define VISORHP				"VISOR_HP"

#define MAXRANK				"MAX_RANK"

new ConfigPro[32]

#define MAX_FILE_NAME	50
#define MAX_PLAYERS	33
#define FILES_PER_PAGE	8
#define MAX_MENU_CHARS	500
#define MAX_FILE_SIZE	300
#define ALL_MENU_KEYS	(1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7 | 1<<8 | 1<<9)

enum {
	UNASSIGNED = 0,
	T,
	CT,
	SPECTATOR
}

#define RECORDS 8
enum {
	GOAL = 1,
	ASSIST,
	STEAL,
	KILL,
	DISTANCE,
	DISARMS,
	ENCONTRA,
	GOALY
}

#define UPGRADES 5
enum {
	STA = 1,	//stamina
	STR,		//strength
	AGI,		//agility
	DEX,		//dexterity
	DISARM,		//disarm
}

static const UpgradeTitles[UPGRADES+1][] = 
{
	"NULL",
	"Hp",
	"Fuerza",
	"Agilidad",
	"Destreza",
	"Desarmar"
}

new UpgradeMax[UPGRADES+1]
new UpgradePrice[UPGRADES+1]

new PlayerUpgrades[MAX_PLAYER + 1][UPGRADES+1]
new GoalEnt[TEAMS]
new PressedAction[MAX_PLAYER + 1]
new seconds[MAX_PLAYER + 1]
new g_sprint[MAX_PLAYER + 1]
new SideJump[MAX_PLAYER + 1]
new Float:SideJumpDelay[MAX_PLAYER + 1]
new PlayerDeaths[MAX_PLAYER + 1]
new PlayerKills[MAX_PLAYER + 1]
new curvecount
new direction
new maxplayers
new Float:BallSpinDirection[3]
new ballspawncount
new Float:TeamBallOrigins[TEAMS][3]
new Float:TEMP_TeamBallOrigins[3]
new Mascots[TEAMS]
new Float:MascotsOrigins[3]
new Float:MascotsAngles[3]
new menu_upgrade[MAX_PLAYER + 1]
new Float:fire_delay
new winner
new Float:GoalyCheckDelay[MAX_PLAYER + 1]
new GoalyCheck[MAX_PLAYER + 1]
new GoalyPoints[MAX_PLAYER + 1]
new Float:BallSpawnOrigin[MAX_BALL_SPAWNS][3]
new TopPlayer[2][RECORDS+1]
new MadeRecord[MAX_PLAYER + 1][RECORDS+1]
new TopPlayerName[RECORDS+1][MAX_PLAYER + 1]
new g_Experience[MAX_PLAYER + 1]
new timer
new Float:testorigin[3]
new Float:velocity[3]
new score[TEAMS]
new scoreboard[1025]
new temp1[64], temp2[64]
new distorig[2][3] //distance recorder
new gmsgShake
new gmsgDeathMsg
new gmsgSayText
new gmsgTextMsg
new goaldied[MAX_PLAYER + 1]
new bool:is_dead[MAX_PLAYER + 1]
new terr[MAX_PLAYER + 1], ct[MAX_PLAYER + 1], cntCT, cntT
new PowerPlay, powerplay_list[MAX_LVL_POWERPLAY+1]
new assist[16]
new iassist[TEAMS]
new gamePlayerEquip

new CVAR_SCORE
new CVAR_RESET
new CVAR_GOALSAFETY
new CVAR_KICK
new Float:CVAR_RESPAWN
new CVAR_RANDOM
new CVAR_KILLNEARBALL
new CVAR_KILLNEARHOLDER
new CVAR_KILLNEARAREA
new CVAR_FRAG
new CVAR_POSS
new	CVAR_LIMITES
new	CVAR_ARQUEROS
new	CVAR_ENCONTRA
new	CVAR_FOUL
new CVAR_OFFSIDE
new CVAR_SPEC
new CVAR_SPEC_CABINAS
new CVAR_RANK
new CVAR_RESEXP

new BCol[BOCHA_COLORS][4]
new BallColors[BOCHA_COLORS]
new PCol[PLAYER_COLORS][4]
new PlayerColors[PLAYER_COLORS]
new SModel[NUM_MODELS][128]
new SSprite[NUM_SPRITES][128]
new SoundDirect[NUM_SOUNDS][256]

new SpriteGol
new SpriteGolContra

new fire
new smoke
new beamspr
new g_fxBeamSprite
new Burn_Sprite
new offbeam

new ballholder
new ballowner
new aball
new is_kickball
new bool:has_knife[MAX_PLAYER + 1]

// System Foul

new bool:is_user_foul[MAX_PLAYER + 1]
new user_foul_count[MAX_PLAYER + 1]
new g_msgScreenFade

// System Keeper

new bool:T_keeper[MAX_PLAYER + 1] 
new bool:CT_keeper[MAX_PLAYER + 1] 
new bool:user_is_keeper[MAX_PLAYER + 1] 

new a_Classname[] = "aco_t"
new b_Classname[] = "aco_t2"

new p_Classname[] = "arco_t"
new g_Classname[] = "arco_ct"
new y_Classname[] = "limite_t"
new z_Classname[] = "limite_ct"
new arqueroct
new arquerot   
new bobo[MAX_PLAYER + 1]

new espectadores
new bool:soy_spec[MAX_PLAYER + 1]

// System Offside

new bool:is_offside[MAX_PLAYER + 1]
new off_1

// Festejos

new T_sprite
new CT_sprite

// Security CFG's

new bool:Seguridad_rr
new bool:Seguridad_cfg

// nVault

new nameVault
new rankVault
new topVault
//new fileVault			// version 5.06
//new ResguardVault		// version 5.06
//new ResguardVault2		// version 5.06

// Spawns Maps Sj

new SpawnSjPro[256]

// Global Rank

new no_ball
new Coord_Off_Z_active
new Coord_Off_Z
new Coord_Off_Y

new Pro_Rank[MAX_PLAYER + 1]
new Pro_Point[MAX_PLAYER + 1]
//new Pro_Partidos[MAX_PLAYER + 1]	// version 5.06
//new Pro_Active[MAX_PLAYER + 1]		// version 5.06

new bool:UserPassword[MAX_PLAYER + 1] = true;

new TotalRank
new sj_systemrank
new ActiveJoinTeam

// Segurity Rank

new TeamSelect[MAX_PLAYER + 1]

// Suman Rank

new Pro_Goal[MAX_PLAYER + 1]
new Pro_Steal[MAX_PLAYER + 1]
new Pro_Asis[MAX_PLAYER + 1]
new Pro_Disarm[MAX_PLAYER + 1]
new Pro_Kill[MAX_PLAYER + 1]

// Restan Rank

new Pro_Contra[MAX_PLAYER + 1]
new Pro_teSteal[MAX_PLAYER + 1]
new Pro_teKill[MAX_PLAYER + 1]
new Pro_teDisarm[MAX_PLAYER + 1]


// pcvars

new sj_password_field;


new UserHealth[MAX_PLAYER + 1]
new MonitorHudSync

new MsgHideWeapon
#define HIDE_HUD_HEALTH (1<<3)

//////////////////CHAT COLORS/////////////////////

enum Color
{
	YELLOW = 1, // Amarillo
	GREEN, // Gris
	TEAM_COLOR, // Rojo, verde, Azul
	GREY, // gris
	RED, // Rojo
	BLUE, // Azul
}

new TeamInfo;
new SayText;
new MaxSlots;

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

new bool:IsConnected[MAX_PLAYER + 1];

new FileMdl[256], FileCol[256], FileSpr[256], FileSounds[256], FileCfg[256]

//new mod_name[MAX_PLAYER + 1] = NAME_SERVER

new OFFSET_INTERNALMODEL;

/*====================================================================================================
 [Precache]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
PrecacheSounds() 
{
	new configDir[128]
	get_configsdir(configDir,127)
	formatex(FileSounds,255,"%s/Sj-Pro/pro-sounds.ini",configDir)
	
	new SoundNames[128]
	new prefijo[4], sufijo[26], Data[128], len
	for(new x = 0; x < MAX_LINE_MODELS; x++)
	{
		read_file(FileSounds, x, Data, 127, len)
		parse(Data, prefijo, 3, sufijo, 25)
		if(equali(prefijo,"##"))
		{
			for(new y = x + 1; y < x + 10; y++)
			{
				read_file(FileSounds, y, Data, 127, len)
				if(equali(Data,""))				
					continue
					
				x = y - 1
				break;
			}				
			
			parse(Data, SoundNames, 127)
			
			if(equali(sufijo,GOL1))
				formatex(SoundDirect[0], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOL2))
				formatex(SoundDirect[1], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOL3))
				formatex(SoundDirect[2], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOL4))
				formatex(SoundDirect[3], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOL5))
				formatex(SoundDirect[4], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOL6))
				formatex(SoundDirect[5], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOLENCONTRA1))
				formatex(SoundDirect[6], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOLENCONTRA2))
				formatex(SoundDirect[7], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOLENCONTRA3))
				formatex(SoundDirect[8], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOLENCONTRA4))
				formatex(SoundDirect[9], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOLENCONTRA5))
				formatex(SoundDirect[10], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,PUSSY))
				formatex(SoundDirect[11], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,INICIORONDA))
				formatex(SoundDirect[12], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,BOCHAPIQUE))
				formatex(SoundDirect[13], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,BOCHARECIBIDA))
				formatex(SoundDirect[14], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,BOCHARESPAWN))
				formatex(SoundDirect[15], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,GOLMARCADO))
				formatex(SoundDirect[16], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,BOCHAPASE))
				formatex(SoundDirect[17], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,FULLSKILL))
				formatex(SoundDirect[18], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,KILLCONBOCHA))
				formatex(SoundDirect[19], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,VICTORIA))
				formatex(SoundDirect[20], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,TELEPORTCABINA))
				formatex(SoundDirect[21], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,DESARMAS))
				formatex(SoundDirect[22], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,TEDESARMAN))
				formatex(SoundDirect[23], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,SERARQUERO))
				formatex(SoundDirect[24], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,NOSERARQUERO))
				formatex(SoundDirect[25], 255, "Sj-Pro/%s.wav", SoundNames)	
			else if(equali(sufijo,SILBATO))
				formatex(SoundDirect[26], 255, "Sj-Pro/%s.wav", SoundNames)					
				
		}
	}	
	for(new x = 0; x < NUM_SOUNDS; x++)
		engfunc( EngFunc_PrecacheSound,	SoundDirect[x])
}

PrecacheBall() 
{
	new prefijo[4], sufijo[26], Data[128], len
	for(new x = 0; x < MAX_LINE_MODELS; x++)
	{
		read_file(FileCol, x, Data, 127, len)
		parse(Data, prefijo, 3, sufijo, 25)
		if(equali(prefijo,"##"))
		{
			for(new y = x + 1; y < x + 10; y++)
			{
				read_file(FileCol, y, Data, 127, len)
				if(equali(Data,""))				
					continue

				x = y - 1
				break;
			}				
				
			if(equali(sufijo,BOCHAGLOW))
				parse(Data, BCol[0], 3, BCol[1], 3, BCol[2], 3)
				
			else if(equali(sufijo,BOCHACOLORBEAMCT))
				parse(Data, BCol[3], 3, BCol[4], 3, BCol[5], 3)
				
			else if(equali(sufijo,BOCHACOLORBEAMTT))
				parse(Data, BCol[6], 3, BCol[7], 3, BCol[8], 3)
			
			else if(equali(sufijo,BEAMGROSOR))
				parse(Data, BCol[9], 3)
				
			else if(equali(sufijo,BEAMLIFE))
				parse(Data, BCol[10], 3)
				
			else if(equali(sufijo,BOCHABRILLO))
				parse(Data, BCol[11], 3)					
	
			else if(equali(sufijo,PLAYERCOLORGLOWCT))
				parse(Data, PCol[0], 3, PCol[1], 3, PCol[2], 3)
				
			else if(equali(sufijo,PLAYERCOLORGLOWTT))
				parse(Data, PCol[3], 3, PCol[4], 3, PCol[5], 3)	

			else if(equali(sufijo,ARQUEROCOLORGLOWCT))
				parse(Data, PCol[6], 3, PCol[7], 3, PCol[8], 3)	

			else if(equali(sufijo,ARQUEROCOLORGLOWTT))
				parse(Data, PCol[9], 3, PCol[10], 3, PCol[11], 3)

			else if(equali(sufijo,PLAYERGROSORGLOW))
				parse(Data, PCol[12], 3)				

			else if(equali(sufijo,ARQUEROGROSORGLOW))
				parse(Data, PCol[13], 3)	

			else if(equali(sufijo,COLORGLOWOFFSIDE))
				parse(Data, PCol[14], 3, PCol[15], 3, PCol[16], 3)
				
			else if(equali(sufijo,GROSORGLOWOFFSIDE))
				parse(Data, PCol[17], 3)		
				
			else if(equali(sufijo,COLORGLOWFOUL))
				parse(Data, PCol[18], 3, PCol[19], 3, PCol[20], 3)
				
			else if(equali(sufijo,GROSORGLOWFOUL))
				parse(Data, PCol[21], 3)

			else if(equali(sufijo,COLORTURBOCT))
				parse(Data, PCol[22], 3, PCol[23], 3, PCol[24], 3)
				
			else if(equali(sufijo,COLORTURBOTT))
				parse(Data, PCol[25], 3, PCol[26], 3, PCol[27], 3)	

			else if(equali(sufijo,COLORCARTELSCORE))
				parse(Data, PCol[28], 3, PCol[29], 3, PCol[30], 3)
		
		}
	}
	for(new x = 0; x < BOCHA_COLORS; x++)
		BallColors[x] = str_to_num(BCol[x])
		
	for(new x = 0; x < PLAYER_COLORS; x++)
		PlayerColors[x] = str_to_num(PCol[x])


	new configDir[128]
	get_configsdir(configDir,127)
	formatex(FileCfg,255,"%s/Sj-Pro/pro-cfg.ini",configDir)
		
	ConfigPro[31] = 8;
		
	new cantidad[32]
	for(new x = 0; x < MAX_LINE_MODELS; x++)
	{
		read_file(FileCfg, x, Data, 127, len)
		parse(Data, prefijo, 3, sufijo, 25, cantidad, 31)
		if(equali(prefijo,"##"))
		{							
			if(equali(sufijo,MAXLVLSTAMINA))
				UpgradeMax[1] = str_to_num(cantidad)			
			else if(equali(sufijo,MAXLVLSTRENGTH))
				UpgradeMax[2] = str_to_num(cantidad)
			else if(equali(sufijo,MAXLVLAGILITY))
				UpgradeMax[3] = str_to_num(cantidad)			
			else if(equali(sufijo,MAXLVLDEXTERITY))
				UpgradeMax[4] = str_to_num(cantidad)				
			else if(equali(sufijo,MAXLVLDISARM))
				UpgradeMax[5] = str_to_num(cantidad)
			else if(equali(sufijo,EXPPRICESTAMINA))
				UpgradePrice[1] = str_to_num(cantidad)
			else if(equali(sufijo,EXPPRICESTRENGTH))
				UpgradePrice[2] = str_to_num(cantidad)				
			else if(equali(sufijo,EXPPRICEAGILITY))
				UpgradePrice[3] = str_to_num(cantidad)				
			else if(equali(sufijo,EXPPRICEDEXTERITY))
				UpgradePrice[4] = str_to_num(cantidad)				
			else if(equali(sufijo,EXPPRICEDISARM))
				UpgradePrice[5] = str_to_num(cantidad)					
			else if(equali(sufijo,EXPGOLEQUIPO))
				ConfigPro[0] = str_to_num(cantidad)	
			else if(equali(sufijo,EXPROBO))	
				ConfigPro[1] = str_to_num(cantidad)			
			else if(equali(sufijo,EXPBALLKILL))
				ConfigPro[2] = str_to_num(cantidad)				
			else if(equali(sufijo,EXPASISTENCIA))
				ConfigPro[3] = str_to_num(cantidad)					
			else if(equali(sufijo,EXPGOL))
				ConfigPro[4] = str_to_num(cantidad)				
			else if(equali(sufijo,BASEHP))
				ConfigPro[5] = str_to_num(cantidad)
			else if(equali(sufijo,BASEDISARM))
				ConfigPro[6] = str_to_num(cantidad)
			else if(equali(sufijo,CUENTAREGRESIVA))
				ConfigPro[7] = str_to_num(cantidad)
			else if(equali(sufijo,TIEMPOEXPCAMPEAR))
				ConfigPro[8] = str_to_num(cantidad)
			else if(equali(sufijo,CURVEANGLE))
				ConfigPro[9] = str_to_num(cantidad)
			else if(equali(sufijo,CURVECOUNT))
				ConfigPro[10] = str_to_num(cantidad)
			else if(equali(sufijo,DIRECTIONS))
				ConfigPro[11] = str_to_num(cantidad)
			else if(equali(sufijo,ANGLEDIVIDE))
				ConfigPro[12] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTLATEJOINEXP))
				ConfigPro[13] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTPOWERPLAY))
				ConfigPro[14] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTGOALY))
				ConfigPro[15] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTSTA))
				ConfigPro[16] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTSTR))
				ConfigPro[17] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTAGI))
				ConfigPro[18] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTDEX))
				ConfigPro[19] = str_to_num(cantidad)
			else if(equali(sufijo,AMOUNTDISARM))
				ConfigPro[20] = str_to_num(cantidad)

			else if(equali(sufijo,RANKGOL))
				ConfigPro[21] = str_to_num(cantidad)
			else if(equali(sufijo,RANKGOLENCONTRA))
				ConfigPro[22] = str_to_num(cantidad)
			else if(equali(sufijo,RANKROBO))
				ConfigPro[23] = str_to_num(cantidad)
			else if(equali(sufijo,RANKREGALO))
				ConfigPro[24] = str_to_num(cantidad)
			else if(equali(sufijo,RANKASISTENCIA))
				ConfigPro[25] = str_to_num(cantidad)				
			else if(equali(sufijo,RANKBALLKILL))
				ConfigPro[26] = str_to_num(cantidad)	
			else if(equali(sufijo,RANKRVBALLKILL))
				ConfigPro[27] = str_to_num(cantidad)	
			else if(equali(sufijo,RANKDISARM))
				ConfigPro[28] = str_to_num(cantidad)		
			else if(equali(sufijo,RANKRVDISARM))
				ConfigPro[29] = str_to_num(cantidad)				

			else if(equali(sufijo,VISORHP))
				ConfigPro[30] = str_to_num(cantidad)	

			else if(equali(sufijo,MAXRANK))
				ConfigPro[31] = str_to_num(cantidad)
				
			else if(equali(sufijo,NOMBRETEAMCT))
			{
				new formatoname[64]
				format(formatoname, 63,"^"%s^"", cantidad)
				TeamNames[2] = cantidad
			}
			else if(equali(sufijo,NOMBRETEAMTT))
			{
				new formatoname[64]
				format(formatoname, 63,"^"%s^"", cantidad)
				TeamNames[1] = cantidad
			}
			else if(equali(sufijo,NOMBRETEAMSPEC))
			{
				new formatoname[64]
				format(formatoname, 63,"^"%s^"", cantidad)
				TeamNames[0] = cantidad
				TeamNames[3] = cantidad
			}
		}
	}
}

PrecacheMonsters(team) {
	engfunc( EngFunc_PrecacheModel, TeamMascots[team-1])
}

PrecacheSprites() 
{
	new configDir[128]
	new DirectSprite[128]
	get_configsdir(configDir,127)
	formatex(FileSpr,255,"%s/Sj-Pro/pro-sprites.ini",configDir)
	new prefijo[4], sufijo[26], Data[128], len
	for(new x = 0; x < MAX_LINE_MODELS; x++)
	{
		read_file(FileSpr, x, Data, 127, len)
		parse(Data, prefijo, 3, sufijo, 25)
		if(equali(prefijo,"##"))
		{
			for(new y = x + 1; y < x + 10; y++)
			{
				read_file(FileSpr, y, Data, 127, len)
				if(equali(Data,""))										
					continue
					
				x = y - 1
				break;
			}				
			
			if(equali(sufijo,EXPLOSIONGOL))
			{
				parse(Data, SSprite[0], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[0])
				fire = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}
			else if(equali(sufijo,EFECTOHUMO))
			{
				parse(Data, SSprite[1], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[1])
				smoke = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}
			else if(equali(sufijo,POWERPLAY))
			{
				parse(Data, SSprite[2], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[2])
				Burn_Sprite = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}
			else if(equali(sufijo,RAYOMASCOTA))
			{
				parse(Data, SSprite[3], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[3])
				g_fxBeamSprite = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}
			else if(equali(sufijo,FESTEJOGOL))
			{
				parse(Data, SSprite[4], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[4])
				SpriteGol = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}
			else if(equali(sufijo,FESTEJOGOLENCONTRA))
			{
				parse(Data, SSprite[5], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[5])
				SpriteGolContra = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}
			else if(equali(sufijo,BOCHABEAM))
			{
				parse(Data, SSprite[6], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[6])
				beamspr = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}
			else if(equali(sufijo,LINEAOFFSIDE))
			{
				parse(Data, SSprite[7], 127)
				formatex(DirectSprite, 127, "sprites/Sj-Pro/%s.spr", SSprite[7])
				offbeam = engfunc( EngFunc_PrecacheModel, DirectSprite)
			}				
		}
	}
}


public plugin_precache() 
{ 
	new mapname[64]
	get_mapname(mapname,63)

	new configDir[128]
	get_configsdir(configDir,127)
	
	formatex(FileMdl,255,"%s/Sj-Pro/pro-models.ini",configDir)
	formatex(FileCol,255,"%s/Sj-Pro/pro-colors.ini",configDir)
	
	/*
	precache_model(spr_teams);
	precache_model(spr_digits);
	*/

	if(equali(mapname,"soccerjam") || (containi(mapname, "sj_") != -1))
	{		
		new spawndir[256]
		format(spawndir,255,"%s/Sj-Pro/Sj-Pro_spawns",configDir)
		if (!dir_exists(spawndir))
		{
			if (mkdir(spawndir)==0)
			{ 
				log_amx("Directorio [%s] creado",spawndir)
		    }
			else
			{
				log_error(AMX_ERR_NOTFOUND,"No se puede crear el directorio[%s], los spawns no han sido adaptados.",spawndir)
				pause("ad")
			}
		}
		
		format(SpawnSjPro, 255, "%s/%s_Sj-Pro.cfg",spawndir, mapname)

		set_task(6.0,"PossSpawnSjPro")	
		

		new timestamp;

		new RankMax[MAX_PLAYER + 1]


		
		topVault = nvault_open(VAULTNAMETOP);
		
		new rankkey[64], rankdata[64];
		format(rankkey, 63, "RankKey");
		if(nvault_lookup(topVault, rankkey, rankdata, 1500, timestamp))
		{
			parse(rankdata,RankMax, MAX_PLAYER);
			TotalRank = str_to_num(RankMax);
		}
		else
		{
			format(rankdata, 63, "0")
			nvault_set(topVault, rankkey, rankdata);
			TotalRank = 0
		}
		nvault_close(topVault);
	
		new SDirect[256]
		new prefijo[4], sufijo[26], Data[128], len
		for(new x = 0; x < MAX_LINE_MODELS; x++)
		{
			read_file(FileMdl, x, Data, 127, len)
			parse(Data, prefijo, 3, sufijo, 25)
			if(equali(prefijo,"##"))
			{
				for(new y = x + 1; y < x + 10; y++)
				{
					read_file(FileMdl, y, Data, 127, len)
					if(equali(Data,""))				
						continue
						
					x = y - 1
					break;
				}				
				
				if(equali(sufijo,MODELBOCHA))
				{
					parse(Data, SModel[0], 127)
					formatex(SDirect, sizeof SDirect - 1, "models/Sj-Pro/Bocha/%s.mdl", SModel[0])	
					copy(ball, sizeof ball - 1, SDirect)
				}
					
				else if(equali(sufijo,MODELARQUEROCT))
				{
					parse(Data, SModel[1], 127)
					formatex(SDirect, sizeof SDirect - 1, "models/player/%s/%s.mdl", SModel[1], SModel[1])	
				}
					
				else if(equali(sufijo,MODELARQUEROTT))
				{
					parse(Data, SModel[2], 127)
					formatex(SDirect, sizeof SDirect - 1, "models/player/%s/%s.mdl", SModel[2], SModel[2])	
				}
				
				else if(equali(sufijo,VMODELFAKAARQUERO))
				{
					parse(Data, SModel[3], 127)
					formatex(SDirect, sizeof SDirect - 1, "models/Sj-Pro/Fakas/%s.mdl", SModel[3])	
				}
				else if(equali(sufijo,PMODELFAKAARQUERO))
				{
					parse(Data, SModel[4], 127)
					formatex(SDirect, sizeof SDirect - 1, "models/Sj-Pro/Fakas/%s.mdl", SModel[4])	
				}
				else if(equali(sufijo,VMODELFAKAPLAYER))
				{
					parse(Data, SModel[5], 127)
					formatex(SDirect, sizeof SDirect - 1, "models/%s.mdl", SModel[5])	
				}	
				else if(equali(sufijo,PMODELFAKAPLAYER))
				{
					parse(Data, SModel[6], 127)
					formatex(SDirect, sizeof SDirect - 1, "models/%s.mdl", SModel[6])	
				}
				
				precache_model(SDirect)				
			}
		}
		precache_model("models/rpgrocket.mdl")		// Camara 3D
	}
}	

PrecacheOther() 
{
	engfunc( EngFunc_PrecacheModel, 		"models/chick.mdl")
}

/*====================================================================================================
 [Initialize]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/

public plugin_init() 
{
	new mapname[64]
	get_mapname(mapname,63)

	register_cvar("Sj-Pro", "0", FCVAR_SERVER|FCVAR_SPONLY)
	register_cvar("Sj-Pro_Version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	set_cvar_string("Sj-Pro_Version", VERSION)
	

 
	/*
	
	//menus
	register_menucmd(register_menuid("clockMainMenu"), MAIN_MENU_KEYS, "handleMainMenu");
	
	//commands
	register_clcmd("say /cm", "showClockMenu", ADMIN_LEVEL);
	
	*/
	
	if(is_kickball > 0)
	{
		PrecacheSprites()
		
		register_plugin("Sj-Pro(ON)", VERSION, AUTHOR)
		set_cvar_num("Sj-Pro", 1)
		
		timer = ConfigPro[7]
		
		// Message IDs
		
		gmsgTextMsg = get_user_msgid("TextMsg")
		gmsgDeathMsg = get_user_msgid("DeathMsg")
		gmsgShake = get_user_msgid("ScreenShake")
		gmsgSayText = get_user_msgid("SayText")
		g_msgScreenFade = get_user_msgid("ScreenFade")


		maxplayers = get_maxplayers()
		
		if(equali(mapname,"soccerjam")) 
		{	
			PrecacheOther()
			CreateGoalNets()
			create_wall()
			set_cvar_num("sj_score", 20) 
			register_clcmd("say /aco","spec_cabina")
		}
		
		if(equali(mapname,"sj_indoorx_small")) 
		{			
			register_clcmd("say /aco","spec_cabina")
			set_cvar_num("sj_score", 30)
		}
			
		if(equali(mapname,"sj_pro") || equali(mapname,"sj_pro_small")) 
		{			
			register_clcmd("say /aco","spec_cabina")
			set_cvar_num("sj_score", 30)
		}
			
		sj_password_field = register_cvar("sj_password_field", "_sj")
		
		register_event("CurWeapon","CurWeapon","be","1=1") 

		register_clcmd("say","handle_say")
		
		register_clcmd("say pipe","sumar_score1")
	
		register_clcmd("Password_rank", "NewUserRank");
			
		register_event("ResetHUD", "Event_ResetHud", "be")
		register_event("HLTV","Event_StartRound","a","1=0","2=0")
		register_event("Damage", "Event_Damage", "b", "2!0", "3=0", "4!0" )

		register_event("Health", "health_change", "b")		
			
		register_clcmd("say /atajo","cmdKeeper") 
		register_clcmd("say_team /atajo","cmdKeeper") 
		register_clcmd("say /noatajo","cmdUnKeeper")  
		register_clcmd("say_team /noatajo","cmdUnKeeper") 
		register_clcmd("say /menu","sjmenuclient")  
		register_clcmd("say_team /menu","sjmenuclient") 
			
			
		register_menucmd(register_menuid("Menu de camaras"), 1023, "setview") 
		register_clcmd("say /camara", "chooseview")
		register_clcmd("say_team /camara", "chooseview")
		register_clcmd("say /cam", "chooseview")
		register_clcmd("say_team /cam", "chooseview") 	


		if(ConfigPro[30])
		{	
			MsgHideWeapon = get_user_msgid("HideWeapon")
			register_message(MsgHideWeapon, "msg_hideweapon")

			MonitorHudSync = CreateHudSyncObj() 

			new monitor = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
			if ( monitor )
			{
				set_pev(monitor, pev_classname, "monitorloop")
				set_pev(monitor, pev_nextthink, get_gametime() + 0.1)
				register_forward(FM_Think, "monitor_think")
			}
		}

		register_concmd("amx_start","restartpartido",ADMIN_KICK,"Comienza el parrido en 10 segundos") 	

		register_concmd("help","sjmenuhelp")
		register_concmd("help_pro","comandos_adm", ADMIN_KICK,"Los admins pueden visualizar todos los comandos disponibles")
			
		register_concmd("amx_exp","experiencia", ADMIN_KICK,"Fulea a todos los jugadores") 
		register_concmd("amx_full","fullall", ADMIN_KICK,"Fulea a todos los jugadores") 			
		register_concmd("amx_spec","todosspec", ADMIN_KICK,"Manda a todos los jugadores spec, menos adms con inmu") 
		register_concmd("amx_sjmenu","menu_pro", ADMIN_KICK,"Menu para adms") 
		register_concmd("amx_unkeeper","QuitarKeeper")
		register_concmd("amx_asd","MenuQuitarKeeper")
		register_concmd("menu","sj_editor_menu")
		
			
		register_concmd("sj_cerrado","SvCerrado")
		register_concmd("sj_publico","SvPublico")
		register_concmd("sj_vale","SvVale")
		register_concmd("sj_fragarqueros","SvFrag")
		
		register_event("TeamInfo", "join_team", "a")	
			
		register_clcmd("chooseteam","clcmd_changeteam")
		
//		register_concmd("amx_mifull","miexperiencia")

		register_concmd("records","records")

		register_concmd("allrecords","allrecords")
		
			
		register_clcmd("say /sjrank", "sjrank")
		register_clcmd("say_team /sjrank", "sjrank")
		register_clcmd("say /sjstats", "RankEstadisticas")
		register_clcmd("say_team /sjstats", "RankEstadisticas")
		register_clcmd("say /sjtop10", "SjTop10")
		register_clcmd("say_team /sjtop10", "SjTop10")
		
		
	//	register_forward(FM_GetGameDescription,"GameDesc")
		register_forward(FM_PlayerPreThink, "glow_del_player")
		
		register_forward(FM_Touch , "fTouch")
	
		CVAR_SCORE = register_cvar("sj_score","20")
		CVAR_RESET = register_cvar("sj_reset","30.0")
		CVAR_GOALSAFETY = register_cvar("sj_goalsafety","650")
		CVAR_KICK = register_cvar("sj_kick","650")
		CVAR_RESPAWN = 2.0 //register_cvar("kickball_respawn","2.0")
		CVAR_RANDOM = register_cvar("sj_random","1")
		CVAR_KILLNEARBALL = register_cvar("sj_kill_distance_ball", "500.0")
		CVAR_KILLNEARHOLDER = register_cvar("sj_kill_distance_holder", "96.0")

		CVAR_KILLNEARAREA = register_cvar("sj_areas", "700.0")
			
		sj_systemrank = 0
		
		CVAR_FRAG = register_cvar("sj_frag","0")
		CVAR_POSS = register_cvar("sj_poss_areas","0")
		CVAR_LIMITES = register_cvar("sj_limites","0")
		CVAR_ARQUEROS = register_cvar("sj_arqueros","0")
		CVAR_ENCONTRA = register_cvar("sj_golesencontra","0")
		CVAR_FOUL = register_cvar("sj_foul","0")
		CVAR_OFFSIDE = register_cvar("sj_offside","0")
		CVAR_SPEC = register_cvar("sj_spec","1")
		CVAR_SPEC_CABINAS = register_cvar("sj_spec_cabinas","1")
		CVAR_RANK = register_cvar("sj_rank","1")
		CVAR_RESEXP = register_cvar("sj_systemexp","1")
		
		register_cvar("SCORE_CT","0")
		register_cvar("SCORE_T","0")

		register_touch(a_Classname,"player",			"teleport_aco")
		register_touch(b_Classname,"player",			"teleport_2")
		
		register_touch(p_Classname,"player",			"tocoarcot")
	   	register_touch(g_Classname,"player",			"tocoarcoct")

		register_touch(y_Classname,"player",			"limitet")
	   	register_touch(z_Classname,"player",			"limitect")
		
		register_touch("PwnBall", "player", 			"touchPlayer")
		register_touch("PwnBall", "soccerjam_goalnet",	"touchNet")

		register_touch("PwnBall", "worldspawn",			"touchWorld")
		register_touch("PwnBall", "func_wall",			"touchWorld")
		register_touch("PwnBall", "func_door",			"touchWorld")
		register_touch("PwnBall", "func_door_rotating", "touchWorld")
		register_touch("PwnBall", "func_wall_toggle",	"touchWorld")
		register_touch("PwnBall", "func_breakable",		"touchWorld")
		register_touch("PwnBall", "Blocker",			"touchBlocker")

		set_task(0.4,"meter",0,_,_,"b")
		set_task(0.5,"statusDisplay",7654321,"",0,"b")
		
		set_task(1.0, "AutoRestart")
		
		register_think("PwnBall","ball_think")
		register_think("Mascot", "mascot_think")
		
		register_clcmd("radio1", 		"LeftDirection",  0)
		register_clcmd("radio2",		"RightDirection", 0)
		register_clcmd("drop",			"Turbo")
	   	register_clcmd("lastinv",		"BuyUpgrade")
	   	register_clcmd("fullupdate",	"fullupdate")
		
		register_message(gmsgTextMsg, 	"editTextMsg")
			
		TeamInfo = get_user_msgid("TeamInfo");
		SayText = get_user_msgid("SayText");
		MaxSlots = get_maxplayers();
			
		//Setup config file paths
		lConfig()			
		
	   	OFFSET_INTERNALMODEL = is_amd64_server() ? 152 : 126;
	}
	else 
	{
		register_plugin("Sj-Pro(OFF)", VERSION, AUTHOR)
		set_cvar_num("Sj-Pro",0)
	}
	return PLUGIN_HANDLED
}

public sumar_score1()
{
	server_cmd("sumar_score %d %d", score[1], score[2])
}

/*====================================================================================================
 [Initialize Entities]

 Purpose:	Handles our custom entities, created with Valve Hammer, and fixes for soccerjam.bsp.

 Comment:	$$

====================================================================================================*/
public pfn_keyvalue(entid) {

	new classname[MAX_PLAYER + 1], key[MAX_PLAYER + 1], value[MAX_PLAYER + 1]
	copy_keyvalue(classname, MAX_PLAYER, key, MAX_PLAYER, value, MAX_PLAYER)

	new temp_origins[3][10], x, team
	new temp_angles[3][10]

	if(equal(key, "classname") && equal(value, "soccerjam_goalnet"))
		DispatchKeyValue("classname", "func_wall")

	if(equal(classname, "game_player_equip")){
		if(!is_kickball || !gamePlayerEquip)
			gamePlayerEquip = entid
		else {
			remove_entity(entid)
		}
	}
	else if(equal(classname, "func_wall"))
	{
		if(equal(key, "team"))
		{
			team = str_to_num(value)
			if(team == 1 || team == 2) {
				GoalEnt[team] = entid
				set_task(1.0, "FinalizeGoalNet", team)
			}
		}
	}
	else if(equal(classname, "soccerjam_mascot"))
	{

		if(equal(key, "team"))
		{
			team = str_to_num(value)
			create_mascot(team)
		}
		else if(equal(key, "origin"))
		{
			parse(value, temp_origins[0], 9, temp_origins[1], 9, temp_origins[2], 9)
			for(x=0; x<3; x++)
				MascotsOrigins[x] = floatstr(temp_origins[x])
		}
		else if(equal(key, "angles"))
		{
			parse(value, temp_angles[0], 9, temp_angles[1], 9, temp_angles[2], 9)
			for(x=0; x<3; x++)
				MascotsAngles[x] = floatstr(temp_angles[x])
		}
	}
	else if(equal(classname, "soccerjam_teamball"))
	{
		if(equal(key, "team"))
		{
			team = str_to_num(value)
			for(x=0; x<3; x++)
				TeamBallOrigins[team][x] = TEMP_TeamBallOrigins[x]
		}
		else if(equal(key, "origin"))
		{
			parse(value, temp_origins[0], 9, temp_origins[1], 9, temp_origins[2], 9)
			for(x=0; x<3; x++)
				TEMP_TeamBallOrigins[x] = floatstr(temp_origins[x])
		}
	}
	else if(equal(classname, "soccerjam_ballspawn"))
	{
		if(equal(key, "origin")) {
			is_kickball = 1

			create_Game_Player_Equip()

			PrecacheBall()
			PrecacheSounds()

			if(ballspawncount < MAX_BALL_SPAWNS) {
				parse(value, temp_origins[0], 9, temp_origins[1], 9, temp_origins[2], 9)

				BallSpawnOrigin[ballspawncount][0] = floatstr(temp_origins[0])
				BallSpawnOrigin[ballspawncount][1] = floatstr(temp_origins[1])
				BallSpawnOrigin[ballspawncount][2] = floatstr(temp_origins[2]) + 10.0

				ballspawncount++
			}
		}
	}
}

createball() {

	new entity = create_entity("info_target")
	if (entity) {

		entity_set_string(entity,EV_SZ_classname,"PwnBall")
		entity_set_model(entity, ball)

		entity_set_int(entity, EV_INT_solid, SOLID_BBOX)
		entity_set_int(entity, EV_INT_movetype, MOVETYPE_BOUNCE)

		new Float:MinBox[3]
		new Float:MaxBox[3]
		MinBox[0] = -15.0
		MinBox[1] = -15.0
		MinBox[2] = 0.0
		MaxBox[0] = 15.0
		MaxBox[1] = 15.0
		MaxBox[2] = 12.0

		entity_set_vector(entity, EV_VEC_mins, MinBox)
		entity_set_vector(entity, EV_VEC_maxs, MaxBox)

		glow(entity,BallColors[0],BallColors[1],BallColors[2],10)


		entity_set_float(entity,EV_FL_framerate,0.0)
		entity_set_int(entity,EV_INT_sequence,0)
	}
	//save our entity ID to aball variable
	aball = entity
	entity_set_float(entity,EV_FL_nextthink,halflife_time() + 0.05)
	return PLUGIN_HANDLED
}

public cambiarmove(param)
{
	entity_set_int(aball,EV_INT_sequence,param)
}

public cambiarframe(Float:param)
{
	entity_set_float(aball,EV_FL_framerate,param)
}


CreateGoalNets() {

	new endzone, x
	new Float:orig[3]
	new Float:MinBox[3], Float:MaxBox[3]

	for(x=1;x<3;x++) {
		endzone = create_entity("info_target")
		if (endzone) {

			entity_set_string(endzone,EV_SZ_classname,"soccerjam_goalnet")
			entity_set_model(endzone, "models/chick.mdl")
			entity_set_int(endzone, EV_INT_solid, SOLID_BBOX)
			entity_set_int(endzone, EV_INT_movetype, MOVETYPE_NONE)

			MinBox[0] = -25.0;	MinBox[1] = -145.0;	MinBox[2] = -36.0
			MaxBox[0] =  25.0;	MaxBox[1] =  145.0;	MaxBox[2] =  70.0

			entity_set_vector(endzone, EV_VEC_mins, MinBox)
			entity_set_vector(endzone, EV_VEC_maxs, MaxBox)

			switch(x) {
				case 1: {
					orig[0] = 2110.0
					orig[1] = 0.0
					orig[2] = 1604.0
				}
				case 2: {
					orig[0] = -2550.0
					orig[1] = 0.0
					orig[2] = 1604.0
				}
			}

			entity_set_origin(endzone,orig)

			entity_set_int(endzone, EV_INT_team, x)
			set_entity_visibility(endzone, 0)
			GoalEnt[x] = endzone
		}
	}

}

create_wall() {
	new wall = create_entity("func_wall")
	if(wall)
	{
		new Float:orig[3]
		new Float:MinBox[3], Float:MaxBox[3]
		entity_set_string(wall,EV_SZ_classname,"Blocker")
		entity_set_model(wall, "models/chick.mdl")

		entity_set_int(wall, EV_INT_solid, SOLID_BBOX)
		entity_set_int(wall, EV_INT_movetype, MOVETYPE_NONE)

		MinBox[0] = -72.0;	MinBox[1] = -100.0;	MinBox[2] = -72.0
		MaxBox[0] =  72.0;	MaxBox[1] =  100.0;	MaxBox[2] =  72.0

		entity_set_vector(wall, EV_VEC_mins, MinBox)
		entity_set_vector(wall, EV_VEC_maxs, MaxBox)

		orig[0] = 2355.0
		orig[1] = 1696.0
		orig[2] = 1604.0
		entity_set_origin(wall,orig)
		set_entity_visibility(wall, 0)
	}
}

create_mascot(team)
{
	new Float:MinBox[3], Float:MaxBox[3]
	new mascot = create_entity("info_target")
	if(mascot)
	{
		PrecacheMonsters(team)
		entity_set_string(mascot,EV_SZ_classname,"Mascot")
		entity_set_model(mascot, TeamMascots[team-1])
		Mascots[team] = mascot

		entity_set_int(mascot, EV_INT_solid, SOLID_NOT)
		entity_set_int(mascot, EV_INT_movetype, MOVETYPE_NONE)
		entity_set_int(mascot, EV_INT_team, team)
		MinBox[0] = -16.0;	MinBox[1] = -16.0;	MinBox[2] = -72.0
		MaxBox[0] =  16.0;	MaxBox[1] =  16.0;	MaxBox[2] =  72.0
		entity_set_vector(mascot, EV_VEC_mins, MinBox)
		entity_set_vector(mascot, EV_VEC_maxs, MaxBox)
		//orig[2] += 200.0

		entity_set_origin(mascot,MascotsOrigins)
		entity_set_float(mascot,EV_FL_animtime,2.0)
		entity_set_float(mascot,EV_FL_framerate,1.0)
		entity_set_int(mascot,EV_INT_sequence,0)

		if(team == 2)
			entity_set_byte(mascot, EV_BYTE_controller1, 115)

		entity_set_vector(mascot,EV_VEC_angles,MascotsAngles)
		entity_set_float(mascot,EV_FL_nextthink,halflife_time() + 1.0)
	}
}

create_Game_Player_Equip() {
	gamePlayerEquip = create_entity("game_player_equip")
	if(gamePlayerEquip) {
		//DispatchKeyValue(gamePlayerEquip, "weapon_knife", "1")
		//DispatchKeyValue(entity, "weapon_scout", "1")
		DispatchKeyValue(gamePlayerEquip, "targetname", "roundstart")
		DispatchSpawn(gamePlayerEquip)
	}

}

public FinalizeGoalNet(team)
{
	new golnet = GoalEnt[team]
	entity_set_string(golnet,EV_SZ_classname,"soccerjam_goalnet")
	entity_set_int(golnet, EV_INT_team, team)
	set_entity_visibility(golnet, 0)
}

public RightDirection(id) {

	if(id == ballholder) {

		direction--
		if(direction < -(ConfigPro[11]))
			direction = -(ConfigPro[11])
		new temp = direction * ConfigPro[9]
		SendCenterText( id, temp );
		
	}
	else
		ColorChat(id, YELLOW, "Debes ^x03TENER^x01 la bocha para poder darle comba.");
	return PLUGIN_HANDLED
}

public LeftDirection(id) {
	if(id == ballholder) {
		direction++
		if(direction > ConfigPro[11])
			direction = ConfigPro[11]
		new temp = direction * ConfigPro[9]
		SendCenterText( id, temp );
		
	}
	else {
		ColorChat(id, YELLOW, "Debes ^x03TENER^x01 la bocha para poder darle comba.");
	}
	return PLUGIN_HANDLED
}


SendCenterText( id, dir )
{
	if(dir < 0)
		client_print(id, print_center, "%i grados a la derecha.", (dir<0?-(dir):dir));
	else if(dir == 0)
		client_print(id, print_center, "0 grados");
	else if(dir > 0)
		client_print(id, print_center, "%i grados a la izquierda.", (dir<0?-(dir):dir));
}





public plugin_cfg() 
{
	if(is_kickball) 
	{
		lConfig()

		/*
		
		//create the main menu
		new size = sizeof(gszMainMenuText);
		add(gszMainMenuText, size, "\yClock Maker Menu^n^n");
		add(gszMainMenuText, size, "\r1. \wCreate server time clock^n");
		add(gszMainMenuText, size, "\r2. \wCreate map timeleft clock^n^n");
		add(gszMainMenuText, size, "\r4. \wDelete clock^n^n");
		add(gszMainMenuText, size, "\r5. \wMake larger^n");
		add(gszMainMenuText, size, "\r6. \wMake smaller^n^n");
		add(gszMainMenuText, size, "\r7. \wSave clocks^n");
		add(gszMainMenuText, size, "\r8. \wLoad clocks^n^n");
		add(gszMainMenuText, size, "\r0. \wClose^n");
		
		
		//make save folder in basedir
		new szDir[64];
		new szMap[32];
		
		get_basedir(szDir, 64);
		add(szDir, 64, "/clockmaker");
		
		//create the folder is it doesn't exist
		if (!dir_exists(szDir))
		{
			mkdir(szDir);
		}
		
		get_mapname(szMap, 32);
		formatex(FileCartel, 96, "%s/%s.cm", szDir, szMap);
		
		//load the clocks
		loadScore(0);
		
		//set a task to update the clocks (every second is frequent enough)
		//set_task(1.0, "UpdateScore", 0, "", 0, "b");
		
		*/
	}
	else 
	{
		new failed[64];
		format(failed,63,"Plugin de Sj-Pro deshabilitado.");
		set_fail_state(failed);
	}
}


/*====================================================================================================
 [Ball Brain]

 Purpose:	These functions help control the ball and its activities.

 Comment:	$$

====================================================================================================*/
public ball_think() {

	new maxscore = get_pcvar_num(CVAR_SCORE)
	if(score[1] >= maxscore || score[2] >= maxscore) {
		entity_set_float(aball,EV_FL_nextthink,halflife_time() + 0.05)
		return PLUGIN_HANDLED
	}

	if(is_valid_ent(aball))
	{
		new Float:gametime = get_gametime()
		if(PowerPlay >= MAX_LVL_POWERPLAY && gametime - fire_delay >= 0.3)
			on_fire()

		if(ballholder > 0)
		{

			new team = get_user_team(ballholder)
			entity_get_vector(ballholder, EV_VEC_origin,testorigin)
			if(!is_user_alive(ballholder)) {

				new tname[MAX_PLAYER + 1]
				get_user_name(ballholder,tname, MAX_PLAYER)

				remove_task(55555)
				set_task(get_pcvar_float(CVAR_RESET),"clearBall",55555)

				if(!g_sprint[ballholder])
					set_speedchange(ballholder)

				format(temp1,63,"%s [%s] Fue desarmado!", TeamNames[team], tname)

				//remove glow of owner and set ball velocity really really low
				glow(ballholder,0,0,0,0)

				ballowner = ballholder
				ballholder = 0

				testorigin[2] += 5
				entity_set_origin(aball, testorigin)

				new Float:vel[3], x
				for(x=0;x<3;x++)
					vel[x] = 1.0

				entity_set_vector(aball,EV_VEC_velocity,vel)
				entity_set_float(aball,EV_FL_nextthink,halflife_time() + 0.05)
				return PLUGIN_HANDLED
			}
			if(entity_get_int(aball,EV_INT_solid) != SOLID_NOT)
				entity_set_int(aball, EV_INT_solid, SOLID_NOT)

			//Put ball in front of player
			ball_infront(ballholder, 55.0)
			new i
			for(i=0;i<3;i++)
				velocity[i] = 0.0
			//Add lift to z axis
			new flags = entity_get_int(ballholder, EV_INT_flags)
			if(flags & FL_DUCKING)
				testorigin[2] -= 10
			else
				testorigin[2] -= 30

			entity_set_vector(aball,EV_VEC_velocity,velocity)
	  		entity_set_origin(aball,testorigin)
		}
		else {
			if(entity_get_int(aball,EV_INT_solid) != SOLID_BBOX)
				entity_set_int(aball, EV_INT_solid, SOLID_BBOX)
		}
	}
	entity_set_float(aball,EV_FL_nextthink,halflife_time() + 0.05)
	return PLUGIN_HANDLED
}

moveBall(where, team=0) {

	if(is_valid_ent(aball)) {
		if(team) {
			new Float:bv[3]
			bv[2] = 50.0
			entity_set_origin(aball, TeamBallOrigins[team])
			entity_set_vector(aball,EV_VEC_velocity,bv)
		}
		else {
			switch(where) {
				case 0: { //outside map
		
					new Float:orig[3], x
					for(x=0;x<3;x++)
						orig[x] = -9999.9
					entity_set_origin(aball,orig)
					ballholder = -1
				}
				case 1: { //at middle

					new Float:v[3], rand
					v[2] = 400.0
					if(ballspawncount > 1)
						rand = random_num(0, ballspawncount-1)
					else
						rand = 0

					entity_set_origin(aball, BallSpawnOrigin[rand])
					entity_set_vector(aball, EV_VEC_velocity, v)

					PowerPlay = 0
					ballholder = 0
					ballowner = 0
				}
			}
		}
	}
}

public ball_infront(id, Float:dist) {

	new Float:nOrigin[3]
	new Float:vAngles[3] // plug in the view angles of the entity
	new Float:vReturn[3] // to get out an origin fDistance away

	entity_get_vector(aball,EV_VEC_origin,testorigin)
	entity_get_vector(id,EV_VEC_origin,nOrigin)
	entity_get_vector(id,EV_VEC_v_angle,vAngles)

//	set_change_ball(0, 0.0)

	vReturn[0] = floatcos( vAngles[1], degrees ) * dist
	vReturn[1] = floatsin( vAngles[1], degrees ) * dist

	vReturn[0] += nOrigin[0]
	vReturn[1] += nOrigin[1]

	testorigin[0] = vReturn[0]
	testorigin[1] = vReturn[1]
	testorigin[2] = nOrigin[2]

	/*
	//Sets the angle to face the same as the player.
	new Float:ang[3]
	entity_get_vector(id,EV_VEC_angles,ang)
	ang[0] = 0.0
	ang[1] -= 90.0
	ang[2] = 0.0
	entity_set_vector(aball,EV_VEC_angles,ang)
	*/
	
}


public CurveBall(id) {
	if(direction && get_speed(aball) > 5 && curvecount > 0) {

		new Float:dAmt = float((direction * ConfigPro[9]) / ConfigPro[12]);
		new Float:v[3], Float:v_forward[3];
		
		entity_get_vector(aball, EV_VEC_velocity, v);
		vector_to_angle(v, BallSpinDirection);

		BallSpinDirection[1] = normalize( BallSpinDirection[1] + dAmt );
		BallSpinDirection[2] = 0.0;
		
		angle_vector(BallSpinDirection, 1, v_forward);
		
		new Float:speed = vector_length(v)// * 0.95;
		v[0] = v_forward[0] * speed
		v[1] = v_forward[1] * speed
		
		entity_set_vector(aball, EV_VEC_velocity, v);

		curvecount--;
		set_task(0.14, "CurveBall", id);
	}
}

public clearBall() 
{
//	play_wav(0, BALL_RESPAWN);
	play_wav(0, SoundDirect[15]);
	format(temp1,63,"La bocha RESPAWNEO en el centro de la cancha!")
	moveBall(1)
}

/*====================================================================================================
 [Mascot Think]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
public mascot_think(mascot)
{
	new team = entity_get_int(mascot, EV_INT_team)
	new indist[MAX_PLAYER + 1], inNum, chosen

	new id, playerteam, dist
	for(id=1 ; id<=maxplayers ; id++)
	{
		if(is_user_alive(id) && !is_user_bot(id))
		{
			playerteam = get_user_team(id)
			if(playerteam != team)
			{
				if(!chosen) {
					dist = get_entity_distance(id, mascot)
					if(dist < get_pcvar_num(CVAR_GOALSAFETY))
						if(id == ballholder) {
							chosen = id
							break
						}
						else
							indist[inNum++] = id
				}
			}
		}
	}
	if(!chosen) {
		new rnd = random_num(0, (inNum-1))
		chosen = indist[rnd]
	}
	if(chosen)
		TerminatePlayer(chosen, mascot, team, ( ballholder == chosen ? 500.0 : random_float(5.0, 15.0) ) )
	entity_set_float(mascot,EV_FL_nextthink,halflife_time() + 1.0)
}

goaly_checker(id, Float:gametime, team) {
	if(!is_user_alive(id) || (gametime - GoalyCheckDelay[id] < ConfigPro[8]) )
		return PLUGIN_HANDLED

	new dist, gcheck
	new Float:pOrig[3]
	entity_get_vector(id, EV_VEC_origin, pOrig)
	dist = floatround(get_distance_f(pOrig, TeamBallOrigins[team]))

	//--/* Goaly Exp System */--//
	if(dist < 600 ) {

		gcheck = GoalyCheck[id]

		if(id == ballholder && gcheck >= 2)
				kickBall(id, 1)

		GoalyPoints[id]++

		if(gcheck < 2)
			g_Experience[id] += gcheck * ConfigPro[15]
		else
			g_Experience[id] += gcheck * (ConfigPro[15] / 2)

		if(gcheck < 5)
			GoalyCheck[id]++

		GoalyCheckDelay[id] = gametime
	}
	else
		GoalyCheck[id] = 0
	return PLUGIN_HANDLED
}

/*====================================================================================================
 [Status Display]

 Purpose:	Displays the Scoreboard information.

 Comment:	$$

====================================================================================================*/


public statusDisplay()
{
	new id, team, bteam = get_user_team(ballholder>0?ballholder:ballowner)
	new score_t = score[T], score_ct = score[CT]

	set_hudmessage(PlayerColors[28], PlayerColors[29], PlayerColors[30], 0.95, 0.20, 0, 1.0, 1.5, 0.1, 0.1, HUD_CHANNEL)
	new Float:gametime = get_gametime()

	for(id=1; id<=maxplayers; id++) {
		if(is_user_connected(id) && !is_user_bot(id))
		{
			team = get_user_team(id)
			goaly_checker(id, gametime, team)
			if(!is_user_alive(id) && !is_dead[id] && (team == 1 || team == 2) && GetPlayerModel(id) != 0xFF)
			{
				//new Float:ballorig[3], x
				//entity_get_vector(id,EV_VEC_origin,ballorig)
				//for(x=0;x<3;x++)
				//	distorig[0][x] = floatround(ballorig[x])
				remove_task(id+1000)
				has_knife[id] = false;
				is_dead[id] = true
				new Float:respawntime = CVAR_RESPAWN
				set_task(respawntime,"AutoRespawn",id)
				set_task((respawntime+0.2), "AutoRespawn2",id)
			}
			if(!winner) 
			{
				if(get_pcvar_num(CVAR_RANK))
					format(scoreboard,1024,"%s- Rank: %s -^n^n%i Goles gana!^n%s - %i  |  %s - %i ^nExperiencia: %i ^n^n%s^n^n^n%s",MENSAGE_SERVER, sj_systemrank==0?"Desactivado":"Activado",get_pcvar_num(CVAR_SCORE),TeamNames[1],score_t,TeamNames[2],score_ct,g_Experience[id],temp1,team==bteam?temp2:"")
				else
					format(scoreboard,1024,"%s- %i Goles gana!^n%s - %i  |  %s - %i ^nExperiencia: %i ^n^n%s^n^n^n%s",MENSAGE_SERVER,get_pcvar_num(CVAR_SCORE),TeamNames[1],score_t,TeamNames[2],score_ct,g_Experience[id],temp1,team==bteam?temp2:"")
				show_hudmessage(id,"%s",scoreboard)
			}
		}
	}
}


/*====================================================================================================
 [Touched]

 Purpose:	All touching stuff takes place here.

 Comment:	$$

====================================================================================================*/
public touchWorld(ball, world) {

	if(get_speed(ball) > 10)
	{
		new Float:v[3]
		
		new Float:r
	
		entity_get_vector(ball, EV_VEC_velocity, v)
		r = entity_get_float(ball, EV_FL_framerate)
		
		v[0] = (v[0] * 0.85)
		v[1] = (v[1] * 0.85)
		v[2] = (v[2] * 0.85)
		
		r = (r * 0.50)
		
		entity_set_float(ball,EV_FL_framerate,r)
		entity_set_int(ball,EV_INT_sequence,2)		

	//	set_change_ball(2, r) 
		
		entity_set_vector(ball, EV_VEC_velocity, v)
		emit_sound(ball, CHAN_ITEM, SoundDirect[13], 1.0, ATTN_NORM, 0, PITCH_NORM)
//		emit_sound(ball, CHAN_ITEM, BALL_BOUNCE_GROUND, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else
	{
		entity_set_float(ball,EV_FL_framerate,0.0)
		entity_set_int(ball,EV_INT_sequence,0)
	}

	return PLUGIN_HANDLED
}

public set_change_ball(secuencia, Float:frame)
{
	entity_set_float(aball,EV_FL_framerate,frame)
	entity_set_int(aball,EV_INT_sequence,secuencia)
}

public touchPlayer(ball, player) {

	if(is_user_bot(player))
		return PLUGIN_HANDLED
		
	if(is_offside[player] || is_user_foul[player])
		return PLUGIN_HANDLED
	
	new playerteam = get_user_team(player)
	if((playerteam != 1 && playerteam != 2))
		return PLUGIN_HANDLED

	remove_task(55555)

	new aname[64], stolen, x
	get_user_name(player,aname,63)
	new ballteam = get_user_team(ballowner)
	if(ballowner > 0 && playerteam != ballteam )
	{
		new speed = get_speed(aball)
		if(speed > 500)
		{
			//configure catching algorithm
			new rnd = random_num(0,100)
			new bstr = (PlayerUpgrades[ballowner][STR] * ConfigPro[17]) / 10
			new dex = (PlayerUpgrades[player][DEX] * ConfigPro[19])
			new pct = ( PressedAction[player] ? 40:20 ) + dex

			pct += ( g_sprint[player] ? 5 : 0 )		//player turboing? give 5%
			pct -= ( g_sprint[ballowner] ? 5 : 0 ) 	//ballowner turboing? lose 5%
			pct -= bstr						//ballowner has strength? remove bstr

			//will player avoid damage?
			if( rnd > pct ) {
				new Float:dodmg = (float(speed) / 13.0) + bstr

				ColorChat(0,YELLOW,"^x04%s^x01 fue daniado por ^x04%i^x01 .",aname,floatround(dodmg))

				set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
				fakedamage(player,"AssWhoopin",dodmg,1)
				set_msg_block(gmsgDeathMsg,BLOCK_NOT)

				if(!is_user_alive(player)) 
				{
					message_begin(MSG_ALL, gmsgDeathMsg)
					write_byte(ballowner)
					write_byte(player)
					write_string("AssWhoopin")
					message_end()
					
					new frags = get_user_frags(ballowner)
					entity_set_float(ballowner, EV_FL_frags, float(frags + 1))
					setScoreInfo(ballowner)
					//set_user_frags(ballowner, get_user_frags(ballowner)+1)
					Event_Record(ballowner, KILL, -1, ConfigPro[2])
					
					///////////////////////////////////////////////
					
					if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
					{
						if(UserPassword[ballowner])
							Pro_Kill[ballowner] += 1
						if(UserPassword[player])
							Pro_teKill[player] += 1	
						if(VerificarPossUP(ballowner))
							log_amx("1 Rank ok")		
						if(VerificarPossUP(player))						
							log_amx("2 Rank ok")
					}
					
					///////////////////////////////////////////////	
					
			//		play_wav(0, HEAD_BOCHA)
					play_wav(0, SoundDirect[19])
					
					ColorChat(player,GREY,"Fuiste eliminado por la pelota que iba demasiado rapida!")
					ColorChat(ballowner,YELLOW,"Ganaste ^x04%i^x01 de experiencia por matar con la bocha!",100)
				}
				else 
				{
					new Float:pushVel[3]
					pushVel[0] = velocity[0]
					pushVel[1] = velocity[1]
					pushVel[2] = velocity[2] + ((velocity[2] < 0)?random_float(-200.0,-50.0):random_float(50.0,200.0))
					entity_set_vector(player,EV_VEC_velocity,pushVel)
				}
				for(x=0;x<3;x++)
					velocity[x] = (velocity[x] * random_float(0.1,0.9))
				entity_set_vector(aball,EV_VEC_velocity,velocity)
				direction = 0
				return PLUGIN_HANDLED
			}
		}
		
		if(speed > 950)
		//	play_wav(0, STOLE_BALL_FAST)
			play_wav(0, SoundDirect[11])
			
		new Float:pOrig[3]
		entity_get_vector(player, EV_VEC_origin, pOrig)
		new dist = floatround(get_distance_f(pOrig, TeamBallOrigins[playerteam]))
		new gainedxp
		
		if(dist < 550) {
			gainedxp = ConfigPro[1] + ConfigPro[0] + (speed / 8)
			Event_Record(player, STEAL, -1, ConfigPro[1] + ConfigPro[0] + (speed / 8))
			GoalyPoints[player] += ConfigPro[0]/2
			
			///////////////////////////////////////////////
			
			if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
			{	
				if(UserPassword[player])
					Pro_Steal[player] += 1
				if(UserPassword[ballowner])
					Pro_teSteal[ballowner] += 1	
				if(VerificarPossUP(player))
					log_amx("3 Rank ok")
				if(VerificarPossUP(ballowner))
					log_amx("4 Rank ok")
			}
					
			///////////////////////////////////////////////			
		}
		else {
			gainedxp = ConfigPro[1]
			Event_Record(player, STEAL, -1, ConfigPro[1])
			
			///////////////////////////////////////////////
					
			if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
			{
				if(UserPassword[player])
					Pro_Steal[player] += 1
				if(UserPassword[ballowner])
					Pro_teSteal[ballowner] += 1
				if(VerificarPossUP(player))
					log_amx("5 Rank ok")
				if(VerificarPossUP(ballowner))
					log_amx("6 Rank ok")
			}
							
			///////////////////////////////////////////////			
		}

		format(temp1,63,"%s [%s] Robo la bocha!",TeamNames[playerteam],aname)
		//client_print(0,print_console,"%s",temp1)

		stolen = 1

		message_begin(MSG_ONE, gmsgShake, {0,0,0}, player)
		write_short(255 << 12) //ammount
		write_short(1 << 11) //lasts this long
		write_short(255 << 10) //frequency
		message_end()

		ColorChat(player,YELLOW,"Ganaste ^x04%i^x01 de exp por robar la bocha!",gainedxp)

	}
	
	if(ballholder == 0) 
	{
//		emit_sound(aball, CHAN_ITEM, BALL_PICKED_UP, 1.0, ATTN_NORM, 0, PITCH_NORM)
		emit_sound(aball, CHAN_ITEM, SoundDirect[14], 1.0, ATTN_NORM, 0, PITCH_NORM)
		new msg[64], check
		
		if(get_pcvar_num(CVAR_OFFSIDE))	
			niOffSide()
		
		if(!has_knife[player] && !soy_spec[player])
			give_knife(player)

		if(stolen)
			PowerPlay = 0
		else
			format(temp1,63,"%s [%s] Agarro la bocha!",TeamNames[playerteam],aname)

		if(((PowerPlay > 1 && powerplay_list[PowerPlay-2] == player) || (PowerPlay > 0 && powerplay_list[PowerPlay-1] == player)) && PowerPlay != MAX_LVL_POWERPLAY)
			check = true

		if(PowerPlay <= MAX_LVL_POWERPLAY && !check) {
			g_Experience[player] += (PowerPlay==2?10:25)
			powerplay_list[PowerPlay] = player
			PowerPlay++
		}
		curvecount = 0
		direction = 0
		GoalyCheck[player] = 0

		format(temp2, 63, "POWER PLAY! -- Nivel: %d", PowerPlay>0?PowerPlay-1:0)

		ballholder = player
		ballowner = 0

		if(!g_sprint[player])
			set_speedchange(player)


		set_hudmessage(255, 225, 128, POS_X, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2)
		format(msg,63,"TENES LA BOCHA!!!")
		show_hudmessage(player,"%s",msg)

		beam()
	}
		
	return PLUGIN_HANDLED
}

public touchNet(ball, goalpost)
{
	remove_task(55555)

	new team = get_user_team(ballowner)
	new golent = GoalEnt[team]
	if (goalpost != golent && ballowner > 0) 
	{
		new aname[64]
		new Float:netOrig[3]
		new netOrig2[3]

		entity_get_vector(ball, EV_VEC_origin,netOrig)

		new l
		for(l=0;l<3;l++)
		netOrig2[l] = floatround(netOrig[l])
		flameWave(netOrig2)
		get_user_name(ballowner,aname,63)
		new frags = get_user_frags(ballowner)
		entity_set_float(ballowner, EV_FL_frags, float(frags + 10))

	//	play_wav(0, SCORED_GOAL)
		play_wav(0, SoundDirect[16])

		/////////////////////ASSIST CODE HERE///////////

		new assisters[4] = { 0, 0, 0, 0 }
		new iassisters = 0
		new ilastplayer = iassist[ team ]

		// We just need the last player to kick the ball
		// 0 means it has passed 15 at least once
		if ( ilastplayer == 0 )
			ilastplayer = 15
		else
			ilastplayer--

		if ( assist[ ilastplayer ] != 0 ) {
			new i, x, bool:canadd, playerid
			for(i=0; i<16; i++) {
				// Stop if we've already found 4 assisters
				if ( iassisters == MAX_ASSISTERS )
					break
				playerid = assist[ i ]
				// Skip if player is invalid
				if ( playerid == 0 )
					continue
				// Skip if kicker is counted as an assister
				if ( playerid == assist[ ilastplayer ] )
					continue

				canadd = true
				// Loop through each assister value
				for(x=0; x<3; x++)
					// make sure we can add them
					if ( playerid == assisters[ x ] ) {
						canadd = false
						break
					}

				// Skip if they've already been added
				if ( canadd == false )
					continue
				// They didn't kick the ball last, and they haven't been added, add them
				assisters[ iassisters++ ] = playerid
			}
			// This gives each person an assist, xp, and prints that out to them
			new c, pass
			for(c=0; c<iassisters; c++) {
				pass = assisters[ c ]
				Event_Record(pass, ASSIST, -1, ConfigPro[3])
				ColorChat( pass, YELLOW, "Ganaste ^x04%i^x01 de exp por la asistencia hecha!",ConfigPro[3])
				
				///////////////////////////////////////////////
					
				if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
				{
					if(UserPassword[pass])
						Pro_Asis[pass] += 1	
					if(VerificarPossUP(pass))
						log_amx("7 Rank ok")
				}
					
				///////////////////////////////////////////////				
							
			}
		}
		iassist[ 0 ] = 0
		/////////////////////ASSIST CODE HERE///////////

		for(l=0; l<3; l++)
			distorig[1][l] = floatround(netOrig[l])
		new distshot = (get_distance(distorig[0],distorig[1])/12)
		new gainedxp = distshot + ConfigPro[4]

		format(temp1,63,"%s [%s] Metio la bocha desde los %i pies!!",TeamNames[team],aname,distshot)
		//client_print(0,print_console,"%s",temp1)

		if(distshot > MadeRecord[ballowner][DISTANCE])
			Event_Record(ballowner, DISTANCE, distshot, 0)// record distance, and make that distance exp

		Event_Record(ballowner, GOAL, -1, gainedxp)	//zero xp for goal cause distance is what gives it.
		
		///////////////////////////////////////////////
		if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))		
		{
			if(UserPassword[ballowner])
				Pro_Goal[ballowner] += 1
			if(VerificarPossUP(ballowner))
				log_amx("8 Rank ok")
		}
		///////////////////////////////////////////////		

		//Increase Score, and update cvar score
		score[team]++
		switch(team) {
			case 1: set_cvar_num("score_ct",score[team])
			case 2: set_cvar_num("score_t",score[team])
		}

		// PONER
		
		server_cmd("setear_score %d %d", score[1], score[2])
		
		ColorChat(ballowner,YELLOW,"Ganaste ^x04%i^x01 de exp por hacer un gol desde los ^x04%i^x01 pies!",gainedxp,distshot)
		Gol_Sprite(ballowner)

		new oteam = (team == 1 ? 2 : 1)
		increaseTeamXP(team, 75)
		increaseTeamXP(oteam, 50)
		moveBall(0)

		new x
		for(x=1; x<=maxplayers; x++) {
			if(is_user_connected(x))
			{
				Event_Record(x, GOALY, GoalyPoints[x], 0)
				new kills = get_user_frags(x)
				new deaths = cs_get_user_deaths(x)
				setScoreInfo(x)
				if( deaths > 0)
					PlayerDeaths[x] = deaths
				if( kills > 0)
					PlayerKills[x] = kills
			}
		}


		if(score[team] < get_pcvar_num(CVAR_SCORE)) {
			new r = random_num(0,5)
			play_wav(0, SoundDirect[r]);		
		
/*		
			new r = random_num(0,MAX_SOUNDS-1)
			play_wav(0, SCORED_SOUNDS[r]);
*/
		}
		else 
		{
			winner = team
			format(scoreboard,1024,"-+- TEAM %s -+-^nGANARON!!!",TeamNames[team])
			set_task(1.0,"showhud_winner",0,"",0,"a",3)
	//		play_wav(0, VICTORY)
			play_wav(0, SoundDirect[20])
		
			ActiveJoinTeam = 0
		
	//		set_cvar_num("sj_systemexp", 0)
			sj_systemrank = 0
			BorrarSistemExp()
		/*	set_task(2.0,"gungame")
			set_task(7.0,"RefreshRank")	
			set_task(10.0,"LoadAllPlayerRank")	*/	//version 5.06
			
		}
		/*
		if(get_cvar_num("sj_systemexp")==1)
			set_task(2.0,"GuardarExp")
		*/
		server_cmd("sv_restart 4")
		

	}

/********************************************************************** GOLES EN CONTRA ***************************************************************/

	else if(goalpost == golent && get_pcvar_num(CVAR_ENCONTRA)) 
	{
		new aname[64]
		new Float:netOrig[3]
		new netOrig2[3]

		entity_get_vector(ball, EV_VEC_origin,netOrig)
		new l
		for(l=0;l<3;l++)
		netOrig2[l] = floatround(netOrig[l])
		flameWave(netOrig2)
		get_user_name(ballowner,aname,63)
		new frags = get_user_frags(ballowner)
		entity_set_float(ballowner, EV_FL_frags, float(frags - 10))

		for(l=0; l<3; l++)
			distorig[1][l] = floatround(netOrig[l])
		new distshot = (get_distance(distorig[0],distorig[1])/12)

		format(temp1,63,"%s [%s] Metio un gol en contra desde los %i pies!!",TeamNames[team],aname,distshot)
		//client_print(0,print_console,"%s",temp1)

		Event_Record(ballowner, ENCONTRA, -1, 0)
		
		///////////////////////////////////////////////

		if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
		{
			if(UserPassword[ballowner])
				Pro_Contra[ballowner] += 1
			if(VerificarPossUP(ballowner))
				log_amx("9 Rank ok")
		}
					
		///////////////////////////////////////////////			

		//Increase Score, and update cvar score

		if(team == 1)
		{
			set_cvar_num("score_t",score[2]++)
		}

		else if(team == 2)
		{
			set_cvar_num("score_ct",score[1]++)
		}
		
		// PONER
		
		server_cmd("setear_score %d %d", score[1], score[2])

		ColorChat(ballowner,YELLOW,"Perdiste ^x04%i^x01 de exp por hacer un gol en contra desde los ^x04%i^x01 pies!",200,distshot)
		Encontra_Sprite(ballowner)

		new oteam = (team == 1 ? 2 : 1)
		increaseTeamXP(team, -200)
		increaseTeamXP(oteam, 200)
		moveBall(0)

		new x
		for(x=1; x<=maxplayers; x++) {
			if(is_user_connected(x))
			{
				new kills = get_user_frags(x)
				new deaths = cs_get_user_deaths(x)
				setScoreInfo(x)
				if( deaths > 0)
					PlayerDeaths[x] = deaths
				if( kills > 0)
					PlayerKills[x] = kills
			}
		}

		if(score[oteam] < get_pcvar_num(CVAR_SCORE)) {
		
			new p = random_num(6,10)
			play_wav(0, SoundDirect[p]);	
			
	/*	
			new p = random_num(0,SOUNDS_CONTRA-1)
			play_wav(0, SCORED_CONTRA[p]);
			
	*/

		}
		else 
		{
			winner = oteam
			format(scoreboard,1024,"-+- TEAM %s -+-^nWiners!!!",TeamNames[oteam])
			set_task(1.0,"showhud_winner",0,"",0,"a",3)
			play_wav(0, SoundDirect[20])	
	
			ActiveJoinTeam = 0
	//		set_cvar_num("sj_systemexp", 0)
			sj_systemrank = 0
			BorrarSistemExp()
		/*	set_task(2.0,"gungame")
			set_task(7.0,"RefreshRank")	
			set_task(10.0,"LoadAllPlayerRank")		*/	//version 5.06
			
		}
		/*
		if(get_cvar_num("sj_systemexp")==1)
			set_task(2.0,"GuardarExp")
		*/

		server_cmd("sv_restart 4")
	}
	
	else if(goalpost == golent && !get_pcvar_num(CVAR_ENCONTRA)) 
	{
		moveBall(0, team)
		ColorChat(ballowner,GREY,"No podes meterte un gol en contra!!")
	}

	return PLUGIN_HANDLED
}

//This is for soccerjam.bsp to fix locker room.
public touchBlocker(pwnball, blocker) {
	new Float:orig[3] = { 2234.0, 1614.0, 1604.0 }
	entity_set_origin(pwnball, orig)
}

/*====================================================================================================
 [Events]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
//public Event_DeathMsg() {
//	new id = read_data(2)
//	strip_user_weapons(id);
//}

public Event_Damage()
{
	new victim = read_data(0)
	new attacker = get_user_attacker(victim)
	if(is_user_alive(attacker)) 
	{
		if(get_pcvar_num(CVAR_FOUL))
			IsFoul(attacker)
			
		if(is_user_alive(victim)) 
		{		
			if(victim == ballholder) 
			{
				new upgrade = PlayerUpgrades[attacker][DISARM]
				if(upgrade) {
					new disarm = upgrade * ConfigPro[20]
					new disarmpct = ConfigPro[6] + (victim==ballholder?(disarm*2):0)
					new rand = random_num(1,100)

					if(disarmpct >= rand)
					{
						new vname[MAX_PLAYER + 1], aname[MAX_PLAYER + 1]
						get_user_name(victim,vname, MAX_PLAYER)
						get_user_name(attacker,aname, MAX_PLAYER)

						if(victim == ballholder) 
						{
							kickBall(victim, 1)
							Event_Record(attacker, DISARMS, -1, 0)
							
							////////////////////////////////////////////
							
							if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
							{
								if(UserPassword[victim])
									Pro_teDisarm[victim] += 1
								if(UserPassword[attacker])
									Pro_Disarm[attacker] += 1
								if(VerificarPossUP(victim))
									log_amx("10 Rank ok")
								if(VerificarPossUP(attacker))
									log_amx("11 Rank ok")
							}
							
							////////////////////////////////////////////
							
							ColorChat(attacker,YELLOW,"Hiciste que ^x04%s^x01 perdiera la bocha!",vname)
							ColorChat(victim,YELLOW,"Has sido desarmado por ^x04%s^x01 !!",aname)
				//			play_wav(victim, DISARMSOUND);
							play_wav(victim, SoundDirect[23]);
							play_wav(attacker, SoundDirect[22]);
						}
					}
				}
			}
		}
		else
			g_Experience[attacker] += (ConfigPro[2]/2)
	}
}

public AvisoFoul(id)
{
	new msg[64]
	set_hudmessage(255, 225, 128, POS_X, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2)
	
	if((user_foul_count[id] > 0) && is_user_foul[id])
		user_foul_count[id]--
	else
	{
		format(msg,63," ")
		show_hudmessage(id,"%s",msg)
		is_user_foul[id] = false;
		remove_foul(id)
		return PLUGIN_HANDLED;
	}

	format(msg,63,"Cometiste foul!, por %d seg no podras moverte", user_foul_count[id])
	show_hudmessage(id,"%s",msg)
		
	set_task(1.0,"AvisoFoul",id)
	
	return PLUGIN_HANDLED;
}

public AvisoOffside(id)
{
	new msg[64]
	set_hudmessage(255, 225, 128, POS_X, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2)

	if(!is_offside[id])
	{
		new msg[64]
		set_hudmessage(255, 225, 128, POS_X, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2)
		format(msg,63," ")
		show_hudmessage(id,"%s",msg)
		return PLUGIN_CONTINUE;
	}
			
	format(msg,63,"Offside!.^n Cuando alguno toque la bocha podras moverte")
	show_hudmessage(id,"%s",msg)
	set_task(1.0,"AvisoOffside", id)
	
	return PLUGIN_CONTINUE
}


Paralize(id)
{
	if(is_user_foul[id])
	{
		set_user_godmode(id, 1) 
	//	set_pev(id, pev_solid, SOLID_NOT);
		set_user_rendering(id,kRenderFxGlowShell,PlayerColors[18],PlayerColors[19],PlayerColors[20],kRenderNormal, PlayerColors[21])
	
	//	play_wav(id, FOULOFFSIDE);
		play_wav(id, SoundDirect[26]);
	
		// add a blue tint to their screen
		message_begin(MSG_ONE, g_msgScreenFade, _, id);
		write_short(~0);	// duration
		write_short(~0);	// hold time
		write_short(0x0004);	// flags: FFADE_STAYOUT
		write_byte(0);		// red
		write_byte(200);		// green
		write_byte(50);	// blue
		write_byte(100);	// alpha
		message_end();
		
		// prevent from jumping
		if (pev(id, pev_flags) & FL_ONGROUND)
			set_pev(id, pev_gravity, 999999.9) // set really high
		else
			set_pev(id, pev_gravity, 0.000001) // no gravity	
	}
	else if(is_offside[id])
	{
		set_user_godmode(id, 1) 
	//	set_pev(id, pev_solid, SOLID_NOT);
		set_user_rendering(id,kRenderFxGlowShell,PlayerColors[14],PlayerColors[15],PlayerColors[16], kRenderNormal, PlayerColors[17])
	
		play_wav(id, SoundDirect[26]);
	
		// add a blue tint to their screen
		message_begin(MSG_ONE, g_msgScreenFade, _, id);
		write_short(~0);								// duration
		write_short(~0);								// hold time
		write_short(0x0004);							// flags: FFADE_STAYOUT
		write_byte(0);									// red
		write_byte(200);								// green
		write_byte(50);									// blue
		write_byte(100);								// alpha
		message_end();
		
		// prevent from jumping
		if (pev(id, pev_flags) & FL_ONGROUND)
			set_pev(id, pev_gravity, 999999.9) // set really high
		else
			set_pev(id, pev_gravity, 0.000001) // no gravity
	}
}



public Event_StartRound()
{
	if(!winner)
	{
		iassist[ 0 ] = 0

		if(!is_valid_ent(aball))
			createball()

		moveBall(1)

		new id
		for(id=1; id<=maxplayers; id++) 
		{
			if(is_user_connected(id) && !is_user_bot(id)) 
			{
				is_dead[id] = false
				seconds[id] = 0
				g_sprint[id] = 0
				PressedAction[id] = 0
				glow(id,0,0,0,0)
			}
		}
		play_wav(0, SoundDirect[12])
//		play_wav(0, ROUND_START)

		set_task(1.0, "PostSetupRound", 0)
		set_task(2.0, "PostPostSetupRound", 0)
	}	
	else
	{	
		set_task(2.0,"displayWinnerAwards",0)
		set_task(20.0,"PostGame",0)
	}
}

public PostSetupRound() {
	new id
	for(id=1; id<=maxplayers; id++)
	{
		if(is_user_alive(id) && !is_user_bot(id) && !soy_spec[id])
			give_knife(id)	
	}
}

public PostPostSetupRound() {
	new id, kills, deaths
	for(id=1; id<=maxplayers; id++) {
		if(is_user_connected(id) && !is_user_bot(id)) {
			kills = PlayerKills[id]
			deaths = PlayerDeaths[id]
			if(kills)
				entity_set_float(id, EV_FL_frags, float(kills))
			if(deaths)
				cs_set_user_deaths(id,deaths)

			setScoreInfo(id)
		}
	}
}

public Event_ResetHud(id) 
{
	if(ConfigPro[30])
	{
		if (is_user_alive(id) || !is_user_bot(id) )
		{
			UserHealth[id] = get_user_health(id)
			// Remove HP and AP from screen, however radar is removed aswell
			message_begin(MSG_ONE_UNRELIABLE, MsgHideWeapon, _, id)
			write_byte(HIDE_HUD_HEALTH)
			message_end()
		}
	}
	
	goaldied[id] = 0;
	is_user_foul[id] = false;
	is_offside[id] = false;
	user_foul_count[id] = 0;
	set_task(1.0,"PostResetHud",id);
}

public PostResetHud(id) {
	if(is_user_alive(id) && !is_user_bot(id))
	{
		new stam = PlayerUpgrades[id][STA]

		if(!has_knife[id] && !soy_spec[id]) {
			give_knife(id)
		}

		//compensate for our turbo
		if(!g_sprint[id])
			set_speedchange(id)

		if(stam > 0)
			entity_set_float(id, EV_FL_health, float(ConfigPro[5] + (stam * ConfigPro[16])))
			
		ProcesTeam()
	}
}

/*====================================================================================================
 [Client Commands]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
public Turbo(id)
{
	if(is_user_alive(id))
		g_sprint[id] = 1
	return PLUGIN_HANDLED
}

public Adelantado(id)
{
	if(ballowner > 0)
	{	
		new Float:angles[3]
		new pateoteam = get_user_team(ballowner)
		entity_get_vector(ballowner, EV_VEC_angles, angles)
		if(angles[0] > float(-25) && angles[0] < float(25))
		{
			if(pateoteam == 1)
			{	
				if(angles[1] > float(0))
				{
					if(angles[1] > float(130))
					{
						if(Offside(id))
							log_amx("Offside!")
					}
				}
				else
				{
					if(angles[1] < float(-130))
					{
						if(Offside(id))
							log_amx("Offside!")
					}
				}
			}
			else if(pateoteam == 2)
			{
				if(angles[1] > float(0))
				{		
					if(angles[1] < float(50))
					{
						if(Offside(id))
							log_amx("Offside!")
					}
				}
				else
				{
					if(angles[1] > float(-50))
					{
						if(Offside(id))
							log_amx("Offside!")
					}	
				}
			}
		}
	}
	return true
}

public client_PreThink(id)
{
	if( is_kickball && is_valid_ent(aball) && is_user_connected(id))
	{
		new button = entity_get_int(id, EV_INT_button)
		new relode = (button & IN_RELOAD)
		new usekey = (button & IN_USE)
		new up = (button & IN_FORWARD)
		new down = (button & IN_BACK)
		new moveright = (button & IN_MOVERIGHT)
		new moveleft = (button & IN_MOVELEFT)
		new jump = (button & IN_JUMP)
		new flags = entity_get_int(id, EV_INT_flags)
		new onground = flags & FL_ONGROUND
		if( (moveright || moveleft) && !up && !down && jump && onground && !g_sprint[id] && id != ballholder)
			SideJump[id] = 1
		
		if(!Coord_Off_Z_active)
		{
			if(onground)
			{
				new User_Origin[3]
				get_user_origin(id, User_Origin)
				Coord_Off_Z_active = 1
				Coord_Off_Z = User_Origin[2] - 35
				Coord_Off_Y = User_Origin[1]
			}
		}

		if(ballholder > 0)
		{
			no_ball = 1
			entity_set_float(aball,EV_FL_framerate,0.0)
			entity_set_int(aball,EV_INT_sequence,0)
		}
		else
		{
			if(no_ball)
			{
				no_ball = 0
				entity_set_int(aball, EV_INT_sequence, 2);
				entity_set_float(aball, EV_FL_framerate, 22.0);
			}
		}

		
		
		if(relode)
		{
			
		entity_set_float(id, EV_FL_framerate, 0.0);    //FLY CHARGE
		entity_set_int(id, EV_INT_sequence, 54);
		entity_set_float(id, EV_FL_animtime, 1.0)
		}



		if(g_sprint[id])
			entity_set_float(id, EV_FL_fuser2, 0.0)

		if( id != ballholder )
			PressedAction[id] = usekey
		else 
		{
			if( usekey && !PressedAction[id]) 
			{
				kickBall(ballholder, 0)
						
				if(get_pcvar_num(CVAR_OFFSIDE))
					Adelantado(id)					
			}
			else if( !usekey && PressedAction[id])
				PressedAction[id] = 0
		}	
		
		if(soy_spec[id] || is_user_foul[id] || is_offside[id])
		{
			if((button & IN_ATTACK || button & IN_ATTACK2)) 
				entity_set_int(id, EV_INT_button, (button & ~IN_ATTACK) & ~IN_ATTACK2)
		}

/****************************************************************** FRAG O NO FRAG ************************************************************************/
		new auxiliar = get_pcvar_num(CVAR_FRAG)
		if(!auxiliar)
		{
			if( id != ballholder && (button & IN_ATTACK || button & IN_ATTACK2) ) 
			{

/****************************************************************** FRAG EN AREA ************************************************************************/
			
				static Float:maxdistance
				static Float:maxdistancem
				static ferencere
				static distancemax

				new fteam = get_user_team(id)
			
				distancemax = Mascots[fteam]
				maxdistancem = get_pcvar_float(CVAR_KILLNEARAREA)
				
				if(ballholder > 0) 
				{
					ferencere = ballholder
					maxdistance = get_pcvar_float(CVAR_KILLNEARHOLDER)
				}			
				else {
					ferencere = aball
					maxdistance = get_pcvar_float(CVAR_KILLNEARBALL)
				}
				
				if(!maxdistance)
					return
					
				if(entity_range(id, ferencere) > maxdistance && entity_range(id, distancemax) > maxdistancem)
					entity_set_int(id, EV_INT_button, (button & ~IN_ATTACK) & ~IN_ATTACK2)
			}
		}
	}
}

public client_PostThink(id) 
{
	if(is_kickball && is_user_connected(id)) {
		new Float:gametime = get_gametime()
		new button = entity_get_int(id, EV_INT_button)

		new up = (button & IN_FORWARD)
		new down = (button & IN_BACK)
		new moveright = (button & IN_MOVERIGHT)
		new moveleft = (button & IN_MOVELEFT)
		new jump = (button & IN_JUMP)
		new Float:vel[3]

		entity_get_vector(id,EV_VEC_velocity,vel)

		if( (gametime - SideJumpDelay[id] > 5.0) && SideJump[id] && jump && (moveright || moveleft) && !up && !down) {

			vel[0] *= 2.0
			vel[1] *= 2.0
			vel[2] = 300.0

			entity_set_vector(id,EV_VEC_velocity,vel)
			SideJump[id] = 0
			SideJumpDelay[id] = gametime
		}
		else
			SideJump[id] = 0
	}
}

public kickBall(id, velType)
{
	remove_task(55555)
	set_task(get_pcvar_float(CVAR_RESET),"clearBall",55555)

	new team = get_user_team(id)
	new a,x

	//Give it some lift
	ball_infront(id, 55.0)

	testorigin[2] += 10

	new Float:tempO[3], Float:returned[3]
	new Float:dist2

	entity_get_vector(id, EV_VEC_origin, tempO)
	new tempEnt = trace_line( id, tempO, testorigin, returned )

	dist2 = get_distance_f(testorigin, returned)

	//ball_infront(id, 55.0)

	if( point_contents(testorigin) != CONTENTS_EMPTY || (!is_user_connected(tempEnt) && dist2 ) )//|| tempDist < 65)
		return PLUGIN_HANDLED
	else
	{
		//Check Make sure our ball isnt inside a wall before kicking
		new Float:ballF[3], Float:ballR[3], Float:ballL[3]
		new Float:ballB[3], Float:ballTR[3], Float:ballTL[3]
		new Float:ballBL[3], Float:ballBR[3]

		for(x=0; x<3; x++) {
				ballF[x] = testorigin[x];	ballR[x] = testorigin[x];
				ballL[x] = testorigin[x];	ballB[x] = testorigin[x];
				ballTR[x] = testorigin[x];	ballTL[x] = testorigin[x];
				ballBL[x] = testorigin[x];	ballBR[x] = testorigin[x];
			}

		for(a=1; a<=6; a++) {

			ballF[1] += 3.0;	ballB[1] -= 3.0;
			ballR[0] += 3.0;	ballL[0] -= 3.0;

			ballTL[0] -= 3.0;	ballTL[1] += 3.0;
			ballTR[0] += 3.0;	ballTR[1] += 3.0;
			ballBL[0] -= 3.0;	ballBL[1] -= 3.0;
			ballBR[0] += 3.0;	ballBR[1] -= 3.0;

			if(point_contents(ballF) != CONTENTS_EMPTY || point_contents(ballR) != CONTENTS_EMPTY ||
			point_contents(ballL) != CONTENTS_EMPTY || point_contents(ballB) != CONTENTS_EMPTY ||
			point_contents(ballTR) != CONTENTS_EMPTY || point_contents(ballTL) != CONTENTS_EMPTY ||
			point_contents(ballBL) != CONTENTS_EMPTY || point_contents(ballBR) != CONTENTS_EMPTY)
					return PLUGIN_HANDLED
		}

		new ent = -1
		testorigin[2] += 35.0

		while((ent = find_ent_in_sphere(ent, testorigin, 35.0)) != 0) {
			if(ent > maxplayers)
			{
				new classname[MAX_PLAYER + 1]
				entity_get_string(ent, EV_SZ_classname, classname, MAX_PLAYER)

				if((contain(classname, "goalnet") != -1 || contain(classname, "func_") != -1) &&
					!equal(classname, "func_water") && !equal(classname, "func_illusionary"))
					return PLUGIN_HANDLED
			}
		}
		testorigin[2] -= 35.0

	}

	new kickVel
	if(!velType)
	{
		new str = (PlayerUpgrades[id][STR] * ConfigPro[17]) + (ConfigPro[14]*(PowerPlay*5))
		kickVel = get_pcvar_num(CVAR_KICK) + str
		kickVel += g_sprint[id] * 100

		if(direction) {
			entity_get_vector(id, EV_VEC_angles, BallSpinDirection)
			curvecount = ConfigPro[10]
		}
	}
	else {
		curvecount = 0
		direction = 0
		kickVel = random_num(100, 600)
	}

	new Float:ballorig[3]
	entity_get_vector(id,EV_VEC_origin,ballorig)
	for(x=0; x<3; x++)
		distorig[0][x] = floatround(ballorig[x])

	velocity_by_aim(id, kickVel, velocity)

	for(x=0; x<3; x++)
		distorig[0][x] = floatround(ballorig[x])

	/////////////////////WRITE ASSIST CODE HERE IF NEEDED///////////
	if ( iassist[ 0 ] == team ) {
		if ( iassist[ team ] == 15 )
			iassist[ team ] = 0
	}
	else {
		// clear the assist list
		new ind
		for(ind = 0; ind < 16; ind++ )
			assist[ ind ] = 0
		// clear the assist index
		iassist[ team ] = 0
		// set which team to track
		iassist[ 0 ] = team
	}
	assist[ iassist[ team ]++ ] = id
	/////////////////////WRITE ASSIST CODE HERE IF NEEDED///////////

	ballowner = id
	ballholder = 0
	entity_set_origin(aball,testorigin)
	entity_set_vector(aball,EV_VEC_velocity,velocity)

	set_task(0.14 *2, "CurveBall", id)

	emit_sound(aball, CHAN_ITEM, SoundDirect[17], 1.0, ATTN_NORM, 0, PITCH_NORM)
//	emit_sound(aball, CHAN_ITEM, BALL_KICKED, 1.0, ATTN_NORM, 0, PITCH_NORM)

	glow(id,0,0,0,0)

	beam()

	new aname[64]
	get_user_name(id,aname,63)

	if(!g_sprint[id])
		set_speedchange(id)

	format(temp1,63,"%s [%s] Pateo la bocha!",TeamNames[team],aname)
	//client_print(0,print_console,"%s",temp1)
	
	return PLUGIN_HANDLED
}

/*====================================================================================================
 [Command Blocks]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
public client_kill(id) {
	if(is_kickball)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public client_command(id) {
	if(!is_kickball) return PLUGIN_CONTINUE
	
	new arg[13]
	read_argv( 0, arg , 12 )

	if ( equal("buy",arg) || equal("autobuy",arg) )
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

//fix for an exploit.
public menuclass(id) {
	
	// They changed teams
	SetPlayerModel(id, 0xFF);
	clcmd_changeteam(id)
}

GetPlayerModel(id)
{
	if(!is_user_connected(id))
		return 0;

	return get_pdata_int(id, OFFSET_INTERNALMODEL, 5);
}

SetPlayerModel(id, int)
{
	if(!is_user_connected(id))
		return;

	set_pdata_int(id, OFFSET_INTERNALMODEL, int, 5);
}

/*
public team_select(id, key) {
	if(is_kickball) 
	{
		
		cmdUnKeeper(id)
		soy_spec[id] = false
		new team = get_user_team(id)
			
		if( (team == 1 || team == 2) && (key == team-1) )
		{
			new message[64]
			format(message, 63, "No puedes volver a entrar al mismo equipo!")
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0, 0, 0}, id)
			write_byte(0)
			write_string(message)
			message_end()
			cmdUnKeeper(id)
			soy_spec[id] = false
			engclient_cmd(id,"chooseteam")
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
*/

public fullupdate(id)
	return PLUGIN_HANDLED

/*====================================================================================================
 [Upgrades]

 Purpose:	This handles the upgrade menu.

 Comment:	$$

====================================================================================================*/
public BuyUpgrade(id) {

	new level[65], num[11], mTitle[101]//, max_count
	format(mTitle,100,"Levels - Skills:")

	menu_upgrade[id] = menu_create(mTitle, "Upgrade_Handler")
	new x
	for(x=1; x<=UPGRADES; x++)
	{
		new price = ((PlayerUpgrades[id][x] * UpgradePrice[x]) / 2) + UpgradePrice[x]
		if((PlayerUpgrades[id][x] + 1) > UpgradeMax[x]) {
			//max_count++
			format(level,64,"\r%s (AL MAXIMO Lvl: %i)",UpgradeTitles[x], UpgradeMax[x])
		}
		else {
			format(level,64,"%s \r(Próximo Lvl: %i) \y-- \w%i XP",UpgradeTitles[x], PlayerUpgrades[id][x]+1, price)
		}
		format(num, 10,"%i",x)
		menu_additem(menu_upgrade[id], level, num, 0)
	}

	menu_addblank(menu_upgrade[id], (UPGRADES+1))
	menu_setprop(menu_upgrade[id], MPROP_EXIT, MEXIT_NORMAL)

	menu_display(id, menu_upgrade[id], 0)
	return PLUGIN_HANDLED
}

public Upgrade_Handler(id, menu, item) {

	if(item == MENU_EXIT)
		return PLUGIN_HANDLED

	new cmd[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)

	new upgrade = str_to_num(cmd)

	new playerupgrade = PlayerUpgrades[id][upgrade]
	new price = ((playerupgrade * UpgradePrice[upgrade]) / 2) + UpgradePrice[upgrade]
	new maxupgrade = UpgradeMax[upgrade]

	if(playerupgrade != maxupgrade && playerupgrade != maxupgrade+MAX_LVL_BONUS)
	{
		new needed = g_Experience[id] - price

		if( (needed >= 0) )
		{
			if(playerupgrade < maxupgrade-1)
				playerupgrade += 1
			else
				playerupgrade += MAX_LVL_BONUS+1

			g_Experience[id] -= price

			if(playerupgrade < maxupgrade)
				ColorChat(id,YELLOW,"Subiste a Lvl ^x03%i^x01 de ^x04%s^x01 usando ^x03%i^x01 de experiencia.",playerupgrade,UpgradeTitles[upgrade],price)
			else {
				ColorChat(id,YELLOW,"Subiste a Lvl ^x03%i^x01 de ^x04%s^x01 usando ^x03%i^x01 de experiencia.",maxupgrade,UpgradeTitles[upgrade],price)
				#if(MAX_LVL_BONUS > 1)
					ColorChat(id,YELLOW,"Has alcanzado el maximo nivel ^x04(%i)^x01! Recibiste ^x03%i^x01 de extra level bonus!",maxupgrade,MAX_LVL_BONUS)
				#else
					ColorChat(id,YELLOW,"Ya has alcanzado el nivel maximo ^x04(%i)^x01!",maxupgrade)
				#endif

		//		play_wav(id, UPGRADED_MAX_LEVEL)
				play_wav(id, SoundDirect[18])
			}
			switch(upgrade) {
				case STA: {
					new stam = playerupgrade * ConfigPro[16]
					entity_set_float(id, EV_FL_health, float(ConfigPro[5] + stam))
				}
				case AGI: {
					if(!g_sprint[id])
						set_speedchange(id)
				}
			}
			PlayerUpgrades[id][upgrade] = playerupgrade
		}
		else
			ColorChat(id,YELLOW,"Faltan ^x04%i^x01 de experiencia para Lvl ^x03%i^x01 de ^x04%s^x01!",(needed * -1),(playerupgrade+1),UpgradeTitles[upgrade])
	}
	else {
		ColorChat(id,YELLOW,"^x04%s^x01 ha sido maximizado a LvL ^x03%i^x01!",UpgradeTitles[upgrade],maxupgrade)
	}
	return PLUGIN_HANDLED
}

/*====================================================================================================
 [Meters]

 Purpose:	This controls the turbo meter and curve angle meter.

 Comment:	$$

====================================================================================================*/
public meter()
{
	new id
	new turboTitle[MAX_PLAYER + 1]
	new sprintText[128], sec
	new r, g, b, team
	new len, x
	new ndir = -(ConfigPro[11])
	format(turboTitle, MAX_PLAYER,"[-TURBO-]");
	for(id=1; id<=maxplayers; id++)
	{
		if(!is_user_connected(id) || !is_user_alive(id) || is_user_bot(id))
			continue

		sec = seconds[id]
		team = get_user_team(id)
		if(team == 1)
		{
			r = PlayerColors[25]
			g = PlayerColors[26]
			b = PlayerColors[27]
		}
		else if(team == 2)
		{
			r = PlayerColors[22]
			g = PlayerColors[23]
			b = PlayerColors[24]
		}
		else
		{
			r = 0
			g = 0
			b = 0
		}

		if(id == ballholder) 
		{

			set_hudmessage(r, g, b, POS_X, 0.75, 0, 0.0, 0.6, 0.0, 0.0, 1)

			len = format(sprintText, 127, "[-COMBA-]^n[")

			for(x=ConfigPro[11]; x>=ndir; x--)
				if(x==0)
					len += format(sprintText[len], 127-len, "%s%s",direction==x?"0":"+", x==ndir?"]":"  ")
				else
					len += format(sprintText[len], 127-len, "%s%s",direction==x?"0":"=", x==ndir?"]":"  ")

			show_hudmessage(id, "%s", sprintText)
		}

		set_hudmessage(r, g, b, POS_X, POS_Y, 0, 0.0, 0.6, 0.0, 0.0, 3)
		
		if(Pro_Rank[id])
		{
			if(sec > 30) 
			{
				sec -= 2
				if(get_pcvar_num(CVAR_RANK))
					format(sprintText, 127, "  %s ^n[==============]^nRANK: %i",turboTitle, Pro_Rank[id])
				else
					format(sprintText, 127, "  %s ^n[==============]",turboTitle)
					
				set_speedchange(id)
				g_sprint[id] = 0
			}
			else if(sec >= 0 && sec < 30 && g_sprint[id]) 
			{
				sec += 2
				set_speedchange(id, 100.0)
			}
		}
		else
		{
			if(sec > 30) 
			{
				sec -= 2
				if(get_pcvar_num(CVAR_RANK))
					format(sprintText, 127, "  %s ^n[==============]^nTipea /menu y registrate",turboTitle)
				else
					format(sprintText, 127, "  %s ^n[==============]",turboTitle)
					
				set_speedchange(id)
				g_sprint[id] = 0
			}
			else if(sec >= 0 && sec < 30 && g_sprint[id]) 
			{
				sec += 2
				set_speedchange(id, 100.0)
			}
		}		

		if(get_pcvar_num(CVAR_RANK))
		{		
			if(Pro_Rank[id])
			{
				switch(sec)	
				{
					case 0:		format(sprintText, 127, "  %s ^n[||||||||||||||]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 2:		format(sprintText, 127, "  %s ^n[|||||||||||||=]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 4:		format(sprintText, 127, "  %s ^n[||||||||||||==]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 6:		format(sprintText, 127, "  %s ^n[|||||||||||===]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 8:		format(sprintText, 127, "  %s ^n[||||||||||====]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 10:	format(sprintText, 127, "  %s ^n[|||||||||=====]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 12:	format(sprintText, 127, "  %s ^n[||||||||======]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 14:	format(sprintText, 127, "  %s ^n[|||||||=======]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 16:	format(sprintText, 127, "  %s ^n[||||||========]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 18:	format(sprintText, 127, "  %s ^n[|||||=========]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 20:	format(sprintText, 127, "  %s ^n[||||==========]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 22:	format(sprintText, 127, "  %s ^n[|||===========]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 24:	format(sprintText, 127, "  %s ^n[||============]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 26:	format(sprintText, 127, "  %s ^n[|=============]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 28:	format(sprintText, 127, "  %s ^n[==============]^nRANK: %i",turboTitle, Pro_Rank[id])
					case 30: 
					{
						format(sprintText, 128, "  %s ^n[==============]^nRANK: %i",turboTitle, Pro_Rank[id])
						sec = 92
					}
					case 32: sec = 0
				}
			}
			
			else
			{
				switch(sec)	
				{
					case 0:		format(sprintText, 127, "  %s ^n[||||||||||||||]^nTipea /menu y registrate",turboTitle)
					case 2:		format(sprintText, 127, "  %s ^n[|||||||||||||=]^nTipea /menu y registrate",turboTitle)
					case 4:		format(sprintText, 127, "  %s ^n[||||||||||||==]^nTipea /menu y registrate",turboTitle)
					case 6:		format(sprintText, 127, "  %s ^n[|||||||||||===]^nTipea /menu y registrate",turboTitle)
					case 8:		format(sprintText, 127, "  %s ^n[||||||||||====]^nTipea /menu y registrate",turboTitle)
					case 10:	format(sprintText, 127, "  %s ^n[|||||||||=====]^nTipea /menu y registrate",turboTitle)
					case 12:	format(sprintText, 127, "  %s ^n[||||||||======]^nTipea /menu y registrate",turboTitle)
					case 14:	format(sprintText, 127, "  %s ^n[|||||||=======]^nTipea /menu y registrate",turboTitle)
					case 16:	format(sprintText, 127, "  %s ^n[||||||========]^nTipea /menu y registrate",turboTitle)
					case 18:	format(sprintText, 127, "  %s ^n[|||||=========]^nTipea /menu y registrate",turboTitle)
					case 20:	format(sprintText, 127, "  %s ^n[||||==========]^nTipea /menu y registrate",turboTitle)
					case 22:	format(sprintText, 127, "  %s ^n[|||===========]^nTipea /menu y registrate",turboTitle)
					case 24:	format(sprintText, 127, "  %s ^n[||============]^nTipea /menu y registrate",turboTitle)
					case 26:	format(sprintText, 127, "  %s ^n[|=============]^nTipea /menu y registrate",turboTitle)
					case 28:	format(sprintText, 127, "  %s ^n[==============]^nTipea /menu y registrate",turboTitle)
					case 30: 
					{
						format(sprintText, 128, "  %s ^n[==============]^nTipea /menu y registrarte",turboTitle)
						sec = 92
					}
					case 32: sec = 0
				}			
			}
		}
		else
		{
			switch(sec)	
			{
				case 0:		format(sprintText, 127, "  %s ^n[||||||||||||||]",turboTitle)
				case 2:		format(sprintText, 127, "  %s ^n[|||||||||||||=]",turboTitle)
				case 4:		format(sprintText, 127, "  %s ^n[||||||||||||==]",turboTitle)
				case 6:		format(sprintText, 127, "  %s ^n[|||||||||||===]",turboTitle)
				case 8:		format(sprintText, 127, "  %s ^n[||||||||||====]",turboTitle)
				case 10:	format(sprintText, 127, "  %s ^n[|||||||||=====]",turboTitle)
				case 12:	format(sprintText, 127, "  %s ^n[||||||||======]",turboTitle)
				case 14:	format(sprintText, 127, "  %s ^n[|||||||=======]",turboTitle)
				case 16:	format(sprintText, 127, "  %s ^n[||||||========]",turboTitle)
				case 18:	format(sprintText, 127, "  %s ^n[|||||=========]",turboTitle)
				case 20:	format(sprintText, 127, "  %s ^n[||||==========]",turboTitle)
				case 22:	format(sprintText, 127, "  %s ^n[|||===========]",turboTitle)
				case 24:	format(sprintText, 127, "  %s ^n[||============]",turboTitle)
				case 26:	format(sprintText, 127, "  %s ^n[|=============]",turboTitle)
				case 28:	format(sprintText, 127, "  %s ^n[==============]",turboTitle)
				case 30: 
				{	
					format(sprintText, 128, "  %s ^n[==============]",turboTitle)
					sec = 92
				}
				case 32: sec = 0
			}	
		}
		seconds[id] = sec
		show_hudmessage(id,"%s",sprintText)
	}
}


/*====================================================================================================
 [Misc.]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
set_speedchange(id, Float:speed=0.0)
{
	new Float:agi = float( (PlayerUpgrades[id][AGI] * ConfigPro[18]) + (id==ballholder?(ConfigPro[14] * (PowerPlay*2)):0) )
	agi += (250.0 + speed)
	entity_set_float(id,EV_FL_maxspeed, agi)
}

public give_knife(id) {
	if(id > 1000)
		id -= 1000

	remove_task(id+1000)


	give_item(id, "weapon_knife")
	has_knife[id] = true;
}

Event_Record(id, recordtype, amt, exp) {
	if(amt == -1)
		MadeRecord[id][recordtype]++
	else
		MadeRecord[id][recordtype] = amt

	new playerRecord = MadeRecord[id][recordtype]
	if(playerRecord > TopPlayer[1][recordtype])
	{
		TopPlayer[0][recordtype] = id
		TopPlayer[1][recordtype] = playerRecord
		new name[MAX_PLAYER+1]
		get_user_name(id,name,MAX_PLAYER)
		format(TopPlayerName[recordtype],MAX_PLAYER,"%s",name)
	}
	g_Experience[id] += exp
}

Float:normalize(Float:nVel)
{
	if(nVel > 360.0) {
		nVel -= 360.0
	}
	else if(nVel < 0.0) {
		nVel += 360.0
	}

	return nVel
}

print_message(id, msg[]) {
	message_begin(MSG_ONE_UNRELIABLE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

public editTextMsg()
{
	new string[64], radio[64]
	get_msg_arg_string(2, string, 63)

	if( get_msg_args() > 2 )
		get_msg_arg_string(3, radio, 63)

	if(containi(string, "#Game_will_restart") != -1 || containi(radio, "#Game_radio") != -1)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public client_connect(id)
{
	if(is_kickball)
	{	
		//Pro_Active[id] = 0		// version 5.06
		soy_spec[id] = false
		set_user_info(id,"_vgui_menus","1")
	}	
}


public AutoRespawn(id)
	if(is_dead[id] && is_user_connected(id)) {
		new team = get_user_team(id)
		if(team == 1 || team == 2) {
			spawn(id)

		}
		else
			is_dead[id] = false
	}

public AutoRespawn2(id)
	if(is_dead[id] && is_user_connected(id)) {
		new team = get_user_team(id)
		if(team == 1 || team == 2) {
			spawn(id)
			if(!has_knife[id] && soy_spec[id] == false)
				give_knife(id)
		}
		//strip_user_weapons(id)
		is_dead[id] = false
	}

play_wav(id, wav[])
	client_cmd(id,"spk %s",wav)


cmdSpectate(id) 
{		
	if(get_pcvar_num(CVAR_SPEC))
	{
		if(is_user_alive(id))
		{
			cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
			user_kill(id)
		}	
	}
	else		
		ColorChat(id, GREY, "[Sj-Pro]^x04 Opcion no habilitada")
}


cmdSpectatemenu(id) 
{
	if(get_pcvar_num(CVAR_SPEC))
	{
		cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
		user_kill(id)	
	}
	else		
		ColorChat(id, GREY, "[Sj-Pro]^x04 Opcion no habilitada")	
}


increaseTeamXP(team, amt) {
	new id
	for(id=1; id<=maxplayers; id++)
		if(get_user_team(id) == team && is_user_connected(id))
			g_Experience[id] += amt
}

setScoreInfo(id) {
	message_begin(MSG_BROADCAST,get_user_msgid("ScoreInfo"));
	write_byte(id);
	write_short(get_user_frags(id));
	write_short(cs_get_user_deaths(id));
	write_short(0);
	write_short(get_user_team(id));
	message_end();
}

// Erase our current temps (used for ball events)
public eraser(num) {
	if(num == 3333)
		format(temp1,63,"")
	if(num == 4444)
		format(temp2,63,"")
	return PLUGIN_HANDLED
}
/*====================================================================================================
 [Cleanup]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
public client_disconnect(id) 
{
	if(is_kickball) 
	{
		UserPassword[id] = false;
		soy_spec[id] = false;
		IsConnected[id] = false;		
		
		if(ActiveJoinTeam == 1 && sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
		{
			new clase_tt = 0, clase_ct = 0, suma_player = 0;
			for(new x = 1; x <= MAX_PLAYER; x++)
			{	
				if(is_user_connected(x))
				{
					switch(TeamSelect[x])
					{
						case 1: clase_tt++
						case 2: clase_ct++
					}
				}
			}
				
			suma_player = clase_tt + clase_ct			
			if(suma_player < ConfigPro[31])
			{
				sj_systemrank = 0
				ColorChat(0,GREY,"[Sj-Pro]^x04 Sistema de Rank deshabilitado por haber menos de 8 players activos")
			}
		}
			
		// Offside Clear
			
		if(is_offside[id])
			is_offside[id] = false;
		
		// Foul clear
		
		is_user_foul[id] = false;
		
		if(get_pcvar_num(CVAR_RESEXP))
			SavePlayerExp(id)
			
		new x
		for(x = 1; x<=RECORDS; x++)
			MadeRecord[id][x] = 0
				
		remove_task(id)
		if(ballholder == id ) 
		{
			ballholder = 0
			clearBall()
		}
		if(ballowner == id) 
		{
			ballowner = 0
		}

		GoalyPoints[id] = 0
		PlayerKills[id] = 0
		PlayerDeaths[id] = 0
		is_dead[id] = false
		seconds[id] = 0
		g_sprint[id] = 0
		PressedAction[id] = 0
		has_knife[id] = false;
		g_Experience[id] = 0
		
		for(x=1; x<=UPGRADES; x++)
			PlayerUpgrades[id][x] = 0
			
		Pro_Point[id] = 0
		Pro_Goal[id] = 0
		Pro_Steal[id] = 0
		Pro_Asis[id] = 0   
		Pro_Contra[id] = 0
		Pro_Disarm[id] = 0
		Pro_Kill[id] = 0
		Pro_teKill[id] = 0
		Pro_teSteal[id] = 0		
		Pro_teDisarm[id] = 0
	//	Pro_Partidos[id] = 0	// version 5.06
	//	Pro_Active[id] = 0		// version 5.06	
		
		cmdUnKeeper(id)
	}
}

cleanup() {
	new x, id, m
	for(x=1;x<=RECORDS;x++) {
		TopPlayer[0][x] = 0
		TopPlayer[1][x] = 0
		TopPlayerName[x][0] = 0
	}

	for(id=1;id<=maxplayers;id++) {
		PlayerDeaths[id] = 0
		PlayerKills[id] = 0

		//UsedExp[id] = 0
		g_Experience[id] = 0

		for(x=1;x<=UPGRADES;x++)
			PlayerUpgrades[id][x] = 0

		for(m = 1; m<=RECORDS; m++)
			MadeRecord[id][m] = 0
	}

	PowerPlay = 0
	winner = 0
	score[T] = 0
	score[CT] = 0
	set_cvar_num("score_ct",0)
	set_cvar_num("score_t",0)

	for(x = 0;x<=cntCT;x++)
		ct[x] = 0

	for(x = 0; x<= cntT; x++)
		terr[x] = 0

	cntCT = 0
	cntT = 0
}

/*====================================================================================================
 [Help]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
public client_putinserver(id) {

	if(is_kickball) 
	{
	//	Pro_Active[id] = 0		// version 5.06
		
		VerificarUser(id)
	
		soy_spec[id] = false
		IsConnected[id] = true;
			
		new MapName[64]
		set_task(20.0,"soccerjamHelp",id)
		
		if(get_pcvar_num(CVAR_RESEXP))
			set_task(10.0,"VerificarExist",id)
		else
			set_task(10.0,"LateJoinExp",id)
		
	
		get_mapname(MapName,63)
		if(equali(MapName,"sj_indoorx_small")) 			
			set_task(2.0,"areas_indoorx",id)
			
		if(equali(MapName,"sj_pro")) 			
			set_task(2.0,"areas_pro",id)
			
		if(equali(MapName,"sj_pro_small")) 			
			set_task(2.0,"areas_pro_small",id)
			
		if(equali(MapName,"soccerjam")) 
			set_task(2.0,"areas_soccerjam",id)
			
		new flags = get_user_flags(id) 		
		if(flags&ADMIN_KICK)
			client_cmd(id, "bind / amx_sjmenu")
			
	}
}

VerificarAccess(id, name[], password[])
{
	new playername[MAX_PLAYER + 1];

	if(name[0])
	{
		copy(playername, 31, name)
	}
	else
	{
		get_user_name(id, playername, 31)
	}

	new result = 0
	
	rankVault = nvault_open(VAULTNAMERANK);
	topVault = nvault_open(VAULTNAMETOP);
	
	new vaultkey[64], vaultdata[64], timestamp;

	new rank_pw[MAX_PLAYER + 1],rank_points[MAX_PLAYER + 1], rank_goles[MAX_PLAYER + 1], rank_robos[MAX_PLAYER + 1], rank_asis[MAX_PLAYER + 1], rank_encontra[MAX_PLAYER + 1], rank_disarm[MAX_PLAYER + 1], rank_kill[MAX_PLAYER + 1], rank_tekill[MAX_PLAYER + 1], rank_terobos[MAX_PLAYER + 1], rank_tedisarm[MAX_PLAYER + 1], rank_rank[MAX_PLAYER + 1];
	format(vaultkey, 63, "^"%s^"", playername);
	if(nvault_lookup(rankVault, vaultkey, vaultdata, 1500, timestamp))
	{
		parse(vaultdata, rank_pw, MAX_PLAYER, rank_points, MAX_PLAYER, rank_goles, MAX_PLAYER, rank_robos, MAX_PLAYER, rank_asis, MAX_PLAYER, rank_encontra, MAX_PLAYER, rank_disarm, MAX_PLAYER, rank_kill, MAX_PLAYER, rank_tekill, MAX_PLAYER, rank_terobos, MAX_PLAYER, rank_tedisarm, MAX_PLAYER, rank_rank, MAX_PLAYER);
		if(equali(rank_pw, password))
		{	
			Pro_Point[id] = str_to_num(rank_points);
			Pro_Goal[id] = str_to_num(rank_goles);
			Pro_Steal[id] = str_to_num(rank_robos);
			Pro_Asis[id] = str_to_num(rank_asis);    
			Pro_Contra[id] = str_to_num(rank_encontra);
			Pro_Disarm[id] = str_to_num(rank_disarm);
			Pro_Kill[id] = str_to_num(rank_kill);
			Pro_teKill[id] = str_to_num(rank_tekill);
			Pro_teSteal[id] = str_to_num(rank_terobos);
			Pro_teDisarm[id] = str_to_num(rank_tedisarm);	
			Pro_Rank[id] = str_to_num(rank_rank);
			
			result = 1
		}
		else
			result = 2
	}
	else
		result = 3

	
	nvault_close(rankVault);
	nvault_close(topVault);
	
	return result
}
	

VerificarUser(id, name[] = "")
{
	new password[32], passfield[32], username[32]
	
	if (name[0])
	{
		copy(username, 31, name)
	}
	else
	{
		get_user_name(id, username, 31)
	}
	
	get_pcvar_string(sj_password_field, passfield, 31)
	get_user_info(id, passfield, password, 31)
	new result = VerificarAccess(id, username, password)
	
	if (result == 1)
	{
		UserPassword[id] = true;
		client_cmd(id, "echo ^"[Sj-Pro] Has sido logueado correctamente^"")
	}
	
	if (result == 2)
	{
		UserPassword[id] = true;
		ClearTask(id)
		client_cmd(id, "echo ^"[Sj-Pro] Contrasenia incorrecta^"")
	}
	
	if (result == 3)
	{
		UserPassword[id] = false;
		ClearTask(id)
		client_cmd(id, "echo ^"[Sj-Pro] Debes crearte una cuenta para estar en el rank, tipea help para mas info^"")
	}
	
	return PLUGIN_CONTINUE	
}

public client_infochanged(id)
{
	if(!is_user_connected(id))
	{
		return PLUGIN_CONTINUE
	}

	new newname[32], oldname[32]
	
	get_user_name(id, oldname, 31)
	get_user_info(id, "name", newname, 31)	
	
	if (!equali(newname, oldname))
	{
		VerificarUser(id, newname)
	}

	return PLUGIN_CONTINUE	
} 

public soccerjamHelp(id)
{
	if(!is_user_connected(id))
		return
		
	client_cmd(id, "cl_forwardspeed 1000")
	client_cmd(id, "cl_backspeed 1000")
	client_cmd(id, "cl_sidespeed 1000")
	client_cmd(id, "bind p records")
	client_cmd(id, "bind l allrecords")
	client_cmd(id, "bind F1 help")

	new name[MAX_PLAYER + 1]
	get_user_name(id,name, MAX_PLAYER)
	ColorChat(id,YELLOW," ")
	ColorChat(id,YELLOW,"-------======----------======= ^x04- Sj-Pro^x03 6.0a ^x01- by^x03 L// ^x01=======-----------======------")
	ColorChat(id,YELLOW,"Bienvenido ^x03%s^x01, has entrado al partido!                      ",name)
	ColorChat(id,YELLOW,"Tipea en say ^x03/menu^x01 para ver todo lo disponible en ^x04Sj-Pro!^x01")
	ColorChat(id,YELLOW,"=======--------------======------------======-----------======--------------=======")
}

public LateJoinExp(id)
{
	if(!is_user_connected(id))
		return
		
	new total = (score[T] + score[CT]) * ConfigPro[13]
	if(total) 
	{
		g_Experience[id] = total
		ColorChat(id, YELLOW, "Recibes ^x04%i^x01 exp por entrar tarde!",total)
	}
}

public handle_say(id)
{
	new name[MAX_PLAYER + 1]
	get_user_name(id,name, MAX_PLAYER)
	new said[192], help[7]
	read_args(said,192)
	remove_quotes(said)
	strcat(help,said,6)
	if((containi(help, "help") != -1))
		sjmenuhelp(id)
	if((contain(help, "spec") != -1)) 
	{
		if(get_pcvar_num(CVAR_SPEC))
		{
			cmdUnKeeper(id) 
			cmdSpectate(id)
			ColorChat(0,TEAM_COLOR,"%s^x01:  ^x04spec",name) 
			return PLUGIN_HANDLED
		}
		else		
			ColorChat(id, GREY, "[Sj-Pro]^x04 Opcion no habilitada")
	}
	
	if((contain(help, "/spec") != -1) ) {
		return PLUGIN_HANDLED
	}
	if(soy_spec[id] == true)
	{
		new sayspec[192]
		read_args(sayspec,192)
		if (equal(sayspec, ""))
			return PLUGIN_HANDLED		

		ColorChat(id, GREY, "[Sj-Pro]^x04 Only say_team o say adm")
		client_cmd(id,"say_team %s",sayspec)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

/*====================================================================================================
 [Post Game]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
public showhud_winner() {
	set_hudmessage(255, 0, 20, -1.0, 0.35, 1, 1.0, 1.5, 0.1, 0.1, HUD_CHANNEL)
	show_hudmessage(0,"%s",scoreboard)


}
public displayWinnerAwards()
{
	//If NO steal/assist was made, set name to Nobody
	new x
	for(x=1;x<=RECORDS;x++)
		if(!TopPlayer[0][x])
			format(TopPlayerName[x],MAX_PLAYER,"Nobody")

	//Display our Winning Team, with Awards, and kill Comm Chair of opponent
	new awards[513]
	new len = 0
	len += format(awards[len], 512-len, "%s GANARON!!!^n", (winner == 1 ? "Terrorist" : "CT"))
	len += format(awards[len], 512-len, "%s - %i  |  %s - %i^n^n", TeamNames[T],score[T],TeamNames[CT],score[CT])
	len += format(awards[len], 512-len, "      -- Premios --^n")
	len += format(awards[len], 512-len, "%i Goles -- %s^n", TopPlayer[1][GOAL], TopPlayerName[GOAL])
	len += format(awards[len], 512-len, "%i Robos -- %s^n", TopPlayer[1][STEAL], TopPlayerName[STEAL])
	len += format(awards[len], 512-len, "%i Asistencias -- %s^n", TopPlayer[1][ASSIST], TopPlayerName[ASSIST])
	len += format(awards[len], 512-len, "%i Ball Kills -- %s^n", TopPlayer[1][KILL], TopPlayerName[KILL])
	len += format(awards[len], 512-len, "%i Pies (Gol más lejano) -- %s^n", TopPlayer[1][DISTANCE], TopPlayerName[DISTANCE])
	len += format(awards[len], 512-len, "%i Disarms -- %s^n", TopPlayer[1][DISARMS], TopPlayerName[DISARMS])
	len += format(awards[len], 512-len, "%i Goles en contra -- %s^n", TopPlayer[1][ENCONTRA], TopPlayerName[ENCONTRA])

	set_hudmessage(250, 130, 20, 0.4, 0.35, 0, 1.0, 10.0, 0.1, 0.1, 2)
	show_hudmessage(0, "%s", awards)
}

public PostGame() {
	new randomize = get_pcvar_num(CVAR_RANDOM)
	if(randomize)
	{
		set_hudmessage(20, 250, 20, -1.0, 0.55, 1, 1.0, 3.0, 1.0, 0.5, 2)
		show_hudmessage(0, "...MEZCLANDO EQUIPOS...")
		set_task(3.0,"randomize_teams",0)
	}
	else
		BeginCountdown()
}

public BeginCountdown() {
	if(!timer) {
		timer = ConfigPro[7]
		cleanup()
	}
	else {
		new output[MAX_PLAYER + 1]
		num_to_word(timer,output, MAX_PLAYER)
		client_cmd(0,"spk vox/%s.wav",output)

		if(timer > (ConfigPro[7] / 2))
			set_hudmessage(0, 255, 255, -1.0, 0.55, 1, 1.0, 1.0, 1.0, 0.5, 2)
		else
			set_hudmessage(255, 255, 0, -1.0, 0.55, 1, 1.0, 1.0, 1.0, 0.5, 2)

		if(timer > (ConfigPro[7] - 2))
			show_hudmessage(0, "EL JUEGO COMIENZA EN...^n%i",timer)
		else
			show_hudmessage(0, "%i",timer)

		if(timer < ConfigPro[7])
			server_cmd("reset_score")
			
		if(timer == 1)
		{
			server_cmd("sv_restart 1")
			server_cmd("start_score")
		}
		timer--
		set_task(0.9,"BeginCountdown",0)
	}
}


/*====================================================================================================
 [Team Randomizer]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
public randomize_teams()
{
	new terr, ct, id, team, cnt, temp, x, pl_temp
	new teams[3][MAX_PLAYER + 1], player_list[MAX_PLAYER + 1]
	new shuff_t, shuff_ct
	new shuffle = random_num(10,30)

	//Put all players in one big list
	for(id=1; id<=maxplayers; id++)
		if(is_user_connected(id) && !is_user_bot(id)) {
			team = get_user_team(id)
			if(team == 1 || team == 2)
				player_list[cnt++] = id
		}

	cnt--

	//Make a list of Terr and CT players
	while(cnt >= 0)
	{
		if(cnt % 2 == 0)
			teams[1][terr++] = player_list[cnt--]
		else
			teams[2][ct++] = player_list[cnt--]
	}

	//Shuffle the players
	for(x=0;x<=shuffle;x++) {
		shuff_t = random_num(0,terr-1);
		shuff_ct = random_num(0,ct-1);
		temp = teams[1][shuff_t];
		teams[1][shuff_t] = teams[2][shuff_ct];
		teams[2][shuff_ct] = temp;
	}

	//Put Players in their team.
	for(x=1; x<3; x++)
		for(id=0; id<((terr>ct?terr:ct)); id++) {
			pl_temp = teams[x][id]
			if(is_user_connected(pl_temp)) {
				select_model(pl_temp, x, random_num(1,4))
				set_task(1.0, "DelayedTeamSwitch", pl_temp+(x*1000))
			}
		}
	set_task(3.0,"BeginCountdown",0)
}

public DelayedTeamSwitch(id) {
	new team, msg[124]
	if(id >= 2000)
		team = 2
	else
		team = 1

	id -= team*1000

	format(msg, 123, "^x03 HAS SIDO TRANSFERIDO AL EQUIPO %s", team==1?"Terrorist":"Counter-Terrorist")
	print_message(id, msg)
}

//random model selecting for teamstack
select_model(id, team, model) 
{
	cmdUnKeeper(id)
	switch(team) {
		case 1: 
		{
			switch(model) 
			{
				case 1: cs_set_user_team(id, CS_TEAM_T, CS_T_TERROR)
				case 2: cs_set_user_team(id, CS_TEAM_T, CS_T_LEET)
				case 3:	cs_set_user_team(id, CS_TEAM_T, CS_T_ARCTIC)
				case 4: cs_set_user_team(id, CS_TEAM_T, CS_T_GUERILLA)
			}
		}
		case 2: 
		{
			switch(model) {
				case 1: cs_set_user_team(id, CS_TEAM_CT, CS_CT_URBAN)
				case 2: cs_set_user_team(id, CS_TEAM_CT, CS_CT_GSG9)
				case 3: cs_set_user_team(id, CS_TEAM_CT, CS_CT_SAS)
				case 4: cs_set_user_team(id, CS_TEAM_CT, CS_CT_GIGN)
				case 5: cs_set_user_team(id, CS_TEAM_CT, CS_CT_VIP) //my lil secret
			}
		}
		case 3: {
			cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
			if(is_user_alive(id)){
				cmdUnKeeper(id)
				user_kill(id)

			}
		}
	}
}


/*====================================================================================================
 [Special FX]

 Purpose:	$$

 Comment:	$$

====================================================================================================*/
TerminatePlayer(id, mascot, team, Float:dmg) {
	new orig[3], Float:morig[3], iMOrig[3]

	get_user_origin(id, orig)
	entity_get_vector(mascot,EV_VEC_origin,morig)
	new x
	for(x=0;x<3;x++)
		iMOrig[x] = floatround(morig[x])
		
		
	/*	
	message_begin(MSG_ONE,iconstatus,{0,0,0},id);
	write_byte(1); // status (0=hide, 1=show, 2=flash)
	write_string("dmg_shock"); // sprite name
	write_byte(255); // red
	write_byte(255); // green
	write_byte(0); // blue
	message_end();
	
	set_task(2.0,"ClearIcon",id)
	*/

	fakedamage(id,"Terminator",dmg,1)

	new hp = get_user_health(id)
	if(hp < 0)
		increaseTeamXP(team, 25)

	new loc = (team == 1 ? 100 : 140)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(0)
	write_coord(iMOrig[0])			//(start positionx)
	write_coord(iMOrig[1])			//(start positiony)
	write_coord(iMOrig[2] + loc)			//(start positionz)
	write_coord(orig[0])			//(end positionx)
	write_coord(orig[1])		//(end positiony)
	write_coord(orig[2])		//(end positionz)
	write_short(g_fxBeamSprite) 			//(sprite index)
	write_byte(0) 			//(starting frame)
	write_byte(0) 			//(frame rate in 0.1's)
	write_byte(7) 			//(life in 0.1's)
	write_byte(120) 			//(line width in 0.1's)
	write_byte(25) 			//(noise amplitude in 0.01's)
	write_byte(255)			//r
	write_byte(255)			//g
	write_byte(255)			//b
	write_byte(400)			//brightness
	write_byte(1) 			//(scroll speed in 0.1's)
	message_end()
}


/*
public ClearIcon(id)
{
	message_begin(MSG_ONE,iconstatus,{0,0,0},id);
	write_byte(1); // status (0=hide, 1=show, 2=flash)
	write_string("dmg_shock"); // sprite name
	write_byte(0); // red
	write_byte(0); // green
	write_byte(0); // blue
	message_end();
}
*/

glow(id, r, g, b, on) {
	if(on == 1) {
		set_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, 16)
		entity_set_float(id, EV_FL_renderamt, 1.0)
	}
	else if(!on) {
		set_rendering(id, kRenderFxNone, r, g, b,  kRenderNormal, 16)
		entity_set_float(id, EV_FL_renderamt, 1.0)
	}
	else if(on == 10) {
		set_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, 16)
		entity_set_float(id, EV_FL_renderamt, 1.0)
	}
}

on_fire()
{
	new rx, ry, rz, Float:forig[3], forigin[3], x
	fire_delay = get_gametime()

	rx = random_num(-5, 5)
	ry = random_num(-5, 5)
	rz = random_num(-5, 5)
	entity_get_vector(aball, EV_VEC_origin, forig)
	for(x=0;x<3;x++)
		forigin[x] = floatround(forig[x])

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(17)
	write_coord(forigin[0] + rx)
	write_coord(forigin[1] + ry)
	write_coord(forigin[2] + 10 + rz)
	write_short(Burn_Sprite)
	write_byte(7)
	write_byte(235)
	message_end()
}

beam() 
{
	if(get_user_team(ballholder) == 1 || get_user_team(ballowner) == 1)
	{
		if(T_sprite == 0)
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_KILLBEAM)
			write_short(aball)
			message_end()
			T_sprite = 1
			CT_sprite = 0
		}
		beam_T()
	}	
	else if(get_user_team(ballholder) == 2 || get_user_team(ballowner) == 2)
	{
		if(CT_sprite == 0)
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_KILLBEAM)
			write_short(aball)
			message_end()
			CT_sprite = 1
			T_sprite = 0
		}
		beam_CT()
	}
}


beam_CT()
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(22) 		// TE_BEAMFOLLOW
	write_short(aball) 	// ball
	write_short(beamspr)// laserbeam
	
	write_byte(BallColors[10])	// life
	write_byte(BallColors[9])	// width
	
	write_byte(BallColors[3])	// R
	write_byte(BallColors[4])	// G
	write_byte(BallColors[5])	// B
	write_byte(BallColors[11])	// brightness	
	
	
/*	
	write_byte(BallProp[3])	// life
	write_byte(BallProp[4])	// width
	
	write_byte(BallProp[5])	// R
	write_byte(BallProp[6])	// G
	write_byte(BallProp[7])	// B
	write_byte(BallProp[11])	// brightness
*/	
	
	message_end()
}

beam_T()
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(22) 		// TE_BEAMFOLLOW
	write_short(aball) 	// ball
	write_short(beamspr)// laserbeam

	write_byte(BallColors[10])	// life
	write_byte(BallColors[9])	// width
	
	write_byte(BallColors[6])	// R
	write_byte(BallColors[7])	// G	Perfect Select
	write_byte(BallColors[8])	// B
	write_byte(BallColors[11])	// brightness
	
/*	
	write_byte(BallProp[3])	// life
	write_byte(BallProp[4])	// width
	
	write_byte(BallProp[8])	// R
	write_byte(BallProp[9])	// G	Perfect Select
	write_byte(BallProp[10])	// B
	
	write_byte(BallProp[11])	// brightness
	
*/	
	message_end()
}

flameWave(myorig[3]) {
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, myorig)
    write_byte( 21 )
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2] + 16)
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2] + 500)
    write_short( fire )
    write_byte( 0 ) // startframe
    write_byte( 0 ) // framerate
    write_byte( 15 ) // life 2
    write_byte( 50 ) // width 16
    write_byte( 10 ) // noise
    write_byte( 209 ) // r 255
    write_byte( 164 ) // g 0
    write_byte( 255 ) // b 0
    write_byte( 255 ) //brightness
    write_byte( 1 / 10 ) // speed
    message_end()

    message_begin(MSG_BROADCAST,SVC_TEMPENTITY,myorig)
    write_byte( 21 )
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2] + 16)
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2] + 500)
    write_short( fire )
    write_byte( 0 ) // startframe
    write_byte( 0 ) // framerate
    write_byte( 10 ) // life 2
    write_byte( 70 ) // width 16
    write_byte( 10 ) // noise
    write_byte( 0 ) // r 0
    write_byte( 0 ) // g 0
    write_byte( 255 ) // b 0
    write_byte( 200 ) //brightness
    write_byte( 1 / 8 ) // speed
    message_end()

    message_begin(MSG_BROADCAST,SVC_TEMPENTITY,myorig)
    write_byte( 21 )
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2] + 16)
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2] + 500)
    write_short( fire )
    write_byte( 0 ) // startframe
    write_byte( 0 ) // framerate
    write_byte( 10 ) // life 2
    write_byte( 90 ) // width 16
    write_byte( 10 ) // noise
    write_byte( 0 ) // r 255
    write_byte( 255 ) // g 100
    write_byte( 255 ) // b 0
    write_byte( 200 ) //brightness
    write_byte( 1 / 5 ) // speed
    message_end()

    //Explosion2
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte( 12 )
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2])
    write_byte( 80 ) // byte (scale in 0.1's) 188
    write_byte( 10 ) // byte (framerate)
    message_end()

    //TE_Explosion
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
    write_byte( 3 )
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2])
    write_short( fire )
    write_byte( 65 ) // byte (scale in 0.1's) 188
    write_byte( 10 ) // byte (framerate)
    write_byte( 0 ) // byte flags
    message_end()
	
    //Smoke
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY,myorig)
    write_byte( 5 ) // 5
    write_coord(myorig[0])
    write_coord(myorig[1])
    write_coord(myorig[2])
    write_short( smoke )
    write_byte( 50 )  // 2 50
    write_byte( 10 )  // 10
    message_end()

    return PLUGIN_HANDLED
}


/***************************************************************************************************************************************************
****************************************************************************************************************************************************
****************************************************************************************************************************************************
*************************************************************** TODOS MIS AGREGADOS by L// *********************************************************
****************************************************************************************************************************************************
****************************************************************************************************************************************************
***************************************************************************************************************************************************/





/******************************* REINICIAR PARTIDO  *********************************/


public restartpartido(id){

	new nameadm[MAX_PLAYER + 1]
	new flags = get_user_flags(id)
	get_user_name(id, nameadm, MAX_PLAYER)	
	
	if(flags&ADMIN_KICK)
	{	
		if(!Seguridad_rr)
		{
			BeginCountdown()
			ColorChat(0,YELLOW,"ADMIN ^x04%s^x01 reinicio el partido",nameadm)		
			ColorChat(0,YELLOW," ")
			ColorChat(0,GREY,"En 10 segundos se reinicia el partido")
			Seguridad_rr = true
			set_task(15.0,"Seg_rr")
		}
		else
			ColorChat(id, BLUE, "Debes esperar un determinado tiempo para utilizar este comando nuevamente")
		return PLUGIN_HANDLED	
	}
	else
		NoAdmin(id)
	
	return PLUGIN_HANDLED
	
}

public Seg_rr()
{
	Seguridad_rr = false
	return PLUGIN_HANDLED
}


/******************************** TODOS SPEC ****************************************/

public todosspec(id)
{
	if(get_pcvar_num(CVAR_SPEC))
	{
		new nameadm[MAX_PLAYER + 1]
		new flags = get_user_flags(id)
		get_user_name(id, nameadm, MAX_PLAYER)	
		if(flags&ADMIN_KICK)
		{			
			for(new i = 1; i <= MAX_PLAYER; i++)
			{
				if((i != id) && (soy_spec[i] == false))
					cmdSpectate(i)
			}  
			ColorChat(0,YELLOW,"ADMIN ^x04%s^x01 transfirio a todos de spec",nameadm)		
			ColorChat(0,YELLOW," ")		
			set_task(1.0,"despec1")
		}
		else
			NoAdmin(id)
	}
	else		
		ColorChat(id, GREY, "[Sj-Pro]^x04 Spec deshabilitados")

	return PLUGIN_HANDLED	
}

public despec1()
{
	ColorChat(0,GREY,"Todos fueron transferidos de ^x04spec")
}

/*************************************** EXPERIENCIA *************************************/


public experiencia(id)
{

	new nameadm[MAX_PLAYER + 1]
	new flags = get_user_flags(id)
	get_user_name(id, nameadm, MAX_PLAYER)
	 		
	if(flags&ADMIN_KICK)
	{	
		ColorChat(0,GREY, "Ahora estan todos con FULL EXP")

		for(new z=1;z<=MAX_PLAYER;z++)	
		{
			if(!is_user_bot(z) &&  !is_user_hltv(z) && is_user_connected(z))
				g_Experience[z] += 50000
		}
		ColorChat(0,YELLOW,"ADMIN ^x04%s^x01 dio exp a todos",nameadm)		
		ColorChat(0,YELLOW," ")		
		return PLUGIN_HANDLED
	}
	else
	{
		bobo[id] += 1
		console_print(id, "Comprate un adm primero")
		
		if(bobo[id] == 2)
		{
			new ipa[MAX_PLAYER + 1]
			new name[MAX_PLAYER + 1]
			get_user_ip(id, ipa, MAX_PLAYER, 1)
			get_user_name(id, name, MAX_PLAYER)
			server_cmd("addip 5 %s;writeip", ipa)
			ColorChat(0,GREY,"%s fue baneado por 5 min por querer fulear a todos sin ser adm",name)
		}
	}
	
	return PLUGIN_HANDLED
}

public fullall(id)
{
	new nameadm[MAX_PLAYER + 1]
	new flags = get_user_flags(id)
	get_user_name(id, nameadm, MAX_PLAYER)
	 		
	if(flags&ADMIN_KICK)
	{	
		ColorChat(0,GREY, "Ahora estan todos FULL habilidades")

		for(new z=1;z<=MAX_PLAYER;z++)	
		{
			if(!is_user_bot(z) &&  !is_user_hltv(z) && is_user_connected(z))
			{
				PlayerUpgrades[z][1] = UpgradeMax[1]
				PlayerUpgrades[z][2] = UpgradeMax[2]
				PlayerUpgrades[z][3] = UpgradeMax[3]
				PlayerUpgrades[z][4] = UpgradeMax[4]
				PlayerUpgrades[z][5] = UpgradeMax[5]
			}
		}
		ColorChat(0,YELLOW,"ADMIN ^x04%s^x01 fuleo a todos",nameadm)		
		ColorChat(0,YELLOW," ")		
		return PLUGIN_HANDLED
	}
	else
	{
		bobo[id] += 1
		console_print(id, "Comprate un adm primero")
		
		if(bobo[id] == 2)
		{
			new ipa[MAX_PLAYER + 1]
			new name[MAX_PLAYER + 1]
			get_user_ip(id, ipa, MAX_PLAYER, 1)
			get_user_name(id, name, MAX_PLAYER)
			server_cmd("addip 5 %s;writeip", ipa)
			ColorChat(0,GREY,"%s fue baneado por 5 min por querer fulear a todos sin ser adm",name)
		}
	}
	
	return PLUGIN_HANDLED
}

public miexperiencia(id)
{
	g_Experience[id] += 50000
	ColorChat(id,GREEN,"FULL")
	return PLUGIN_HANDLED
}

/******************************** PLUGINS DEL AREA **********************************/


public areas_soccerjam(id)
{
    if(!is_user_connected(id))
        return

    new Ent_t = create_entity("info_target")
    new Ent_c = create_entity("info_target")
    new Ent_tt = create_entity("info_target")
    new Ent_ct = create_entity("info_target")

    new Float:t_Origin[3] = {1912.0,0.0,1636.0}
    new Float:c_Origin[3] = {-2360.0,0.0,1636.0}
    new Float:tt_Origin[3] = {-295.0,-300.0,1970.0}
    new Float:ct_Origin[3] = {-159.0,-300.0,1970.0}

    entity_set_string(Ent_t,EV_SZ_classname,p_Classname)
    entity_set_string(Ent_c,EV_SZ_classname,g_Classname)
    entity_set_string(Ent_tt,EV_SZ_classname,y_Classname)
    entity_set_string(Ent_ct,EV_SZ_classname,z_Classname)

    entity_set_int(Ent_t,EV_INT_solid,SOLID_TRIGGER)
    entity_set_int(Ent_c,EV_INT_solid,SOLID_TRIGGER)
    entity_set_int(Ent_tt,EV_INT_solid,SOLID_TRIGGER)
    entity_set_int(Ent_ct,EV_INT_solid,SOLID_TRIGGER)

    entity_set_origin(Ent_t,t_Origin)
    entity_set_origin(Ent_c,c_Origin)
    entity_set_origin(Ent_tt,tt_Origin)
    entity_set_origin(Ent_ct,ct_Origin)

    entity_set_size(Ent_t,Float:{-156.5,-280.0,-68.0},Float:{156.5,280.0,68.0})
    entity_set_size(Ent_c,Float:{-156.5,-280.0,-68.0},Float:{156.5,280.0,68.0})
    entity_set_size(Ent_tt,Float:{-5.0,-6790.0,-402.0},Float:{5.0,6790.0,402.0})
    entity_set_size(Ent_ct,Float:{-5.0,-6790.0,-402.0},Float:{5.0,6790.0,402.0})

    entity_set_edict(Ent_t,EV_ENT_owner,id)
    entity_set_edict(Ent_c,EV_ENT_owner,id)
    entity_set_edict(Ent_tt,EV_ENT_owner,id)
    entity_set_edict(Ent_ct,EV_ENT_owner,id)

}

	
public areas_indoorx(id)
{
	if(!is_user_connected(id))
		return

	new Ent_t = create_entity("info_target")
	new Ent_c = create_entity("info_target")
	new Ent_tt = create_entity("info_target")
	new Ent_ct = create_entity("info_target")

	new Float:t_Origin[3] = {1789.0,-363.0,-215.0}
	new Float:c_Origin[3] = {-1557.0,-358.0,-215.0}
	new Float:tt_Origin[3] = {42.0,-360.0,-244.0}
	new Float:ct_Origin[3] = {180.0,-360.0,-244.0}

	entity_set_string(Ent_t,EV_SZ_classname,p_Classname)
	entity_set_string(Ent_c,EV_SZ_classname,g_Classname)
	entity_set_string(Ent_tt,EV_SZ_classname,y_Classname)
	entity_set_string(Ent_ct,EV_SZ_classname,z_Classname)

	entity_set_int(Ent_t,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_c,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_tt,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_ct,EV_INT_solid,SOLID_TRIGGER)

	entity_set_origin(Ent_t,t_Origin)
	entity_set_origin(Ent_c,c_Origin)
	entity_set_origin(Ent_tt,tt_Origin)
	entity_set_origin(Ent_ct,ct_Origin)
	
	entity_set_size(Ent_t,Float:{-90.0,-270.5,-117.5},Float:{90.0,270.5,117.5})
	entity_set_size(Ent_c,Float:{-90.0,-270.5,-117.5},Float:{90.0,270.5,117.5})
	entity_set_size(Ent_tt,Float:{-5.0,-995.0,-93.0},Float:{5.0,995.0,93.0})
	entity_set_size(Ent_ct,Float:{-5.0,-995.0,-93.0},Float:{5.0,995.0,93.0})

	entity_set_edict(Ent_t,EV_ENT_owner,id)
	entity_set_edict(Ent_c,EV_ENT_owner,id)
	entity_set_edict(Ent_tt,EV_ENT_owner,id)
	entity_set_edict(Ent_ct,EV_ENT_owner,id)
	
	
	
	new ent_aco = create_entity("info_target")
	new Float:aco_origin[3] = {1040.0, 800.0, -140.0}
	entity_set_string(ent_aco,EV_SZ_classname,a_Classname)
	entity_set_int(ent_aco,EV_INT_solid,SOLID_TRIGGER)
	entity_set_origin(ent_aco,aco_origin)
	entity_set_size(ent_aco,Float:{-10.0,-10.0,-40.0},Float:{10.0,10.0,40.0})
	entity_set_edict(ent_aco,EV_ENT_owner,id)	
	
	new ent_aco2 = create_entity("info_target")
	new Float:aco_origin2[3] = {97.0, 710.0, -298.0}
	entity_set_string(ent_aco2,EV_SZ_classname,b_Classname)
	entity_set_int(ent_aco2,EV_INT_solid,SOLID_TRIGGER)
	entity_set_origin(ent_aco2,aco_origin2)
	entity_set_size(ent_aco2,Float:{-10.0,-10.0,-40.0},Float:{10.0,10.0,40.0})
	entity_set_edict(ent_aco2,EV_ENT_owner,id)	

	/*
	new cartel_ind = create_entity("info_target")
	new Float:cartel_org[3] = {125.0, -1338.5, -130.0}
	entity_set_int(cartel_ind,EV_INT_solid,SOLID_TRIGGER)
	entity_set_origin(cartel_ind,cartel_org)
	entity_set_size(cartel_ind,Float:{-1.0,-1.0,-1.0},Float:{1.0,1.0,1.0})	
	entity_set_model(cartel_ind, "models/Sj-Pro/Otros/Sj-Pro.mdl")
	
	new estrella = create_entity("info_target")
	new Float:estrella_org[3] = {125.0, -1338.5, -130.0}
	entity_set_int(estrella,EV_INT_solid,SOLID_TRIGGER)
	entity_set_origin(estrella,estrella_org)
	entity_set_size(estrella,Float:{-1.0,-1.0,-1.0},Float:{1.0,1.0,1.0})	
	entity_set_model(estrella, "sprites/esf_spirit_bomb.spr")
	*/
	
}

public areas_pro(id)
{
	if(!is_user_connected(id))
		return

	new Ent_t = create_entity("info_target")
	new Ent_c = create_entity("info_target")
	new Ent_tt = create_entity("info_target")
	new Ent_ct = create_entity("info_target")

	new Float:t_Origin[3] = {1892.0,215.0,-500.0}
	new Float:c_Origin[3] = {-1469.0,215.0,-500.0}
	new Float:tt_Origin[3] = {56.0,215.0,-430.0}
	new Float:ct_Origin[3] = {364.0,215.0,-430.0}

	entity_set_string(Ent_t,EV_SZ_classname,p_Classname)
	entity_set_string(Ent_c,EV_SZ_classname,g_Classname)
	entity_set_string(Ent_tt,EV_SZ_classname,y_Classname)
	entity_set_string(Ent_ct,EV_SZ_classname,z_Classname)

	entity_set_int(Ent_t,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_c,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_tt,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_ct,EV_INT_solid,SOLID_TRIGGER)

	entity_set_origin(Ent_t,t_Origin)
	entity_set_origin(Ent_c,c_Origin)
	entity_set_origin(Ent_tt,tt_Origin)
	entity_set_origin(Ent_ct,ct_Origin)
	
	entity_set_size(Ent_t,Float:{-90.0,-280.5,-117.5},Float:{90.0,270.5,117.5})
	entity_set_size(Ent_c,Float:{-90.0,-275.5,-117.5},Float:{90.0,270.5,117.5})
	entity_set_size(Ent_tt,Float:{-5.0,-995.0,-93.0},Float:{5.0,995.0,93.0})
	entity_set_size(Ent_ct,Float:{-5.0,-995.0,-93.0},Float:{5.0,995.0,93.0})

	entity_set_edict(Ent_t,EV_ENT_owner,id)
	entity_set_edict(Ent_c,EV_ENT_owner,id)
	entity_set_edict(Ent_tt,EV_ENT_owner,id)
	entity_set_edict(Ent_ct,EV_ENT_owner,id)
}

public areas_pro_small(id)
{
	if(!is_user_connected(id))
		return

	new Ent_t = create_entity("info_target")
	new Ent_c = create_entity("info_target")
	new Ent_tt = create_entity("info_target")
	new Ent_ct = create_entity("info_target")

	new Float:t_Origin[3] = {1700.0,215.0,-500.0}
	new Float:c_Origin[3] = {-1278.0,215.0,-500.0}
	new Float:tt_Origin[3] = {56.0,215.0,-430.0}
	new Float:ct_Origin[3] = {364.0,215.0,-430.0}

	entity_set_string(Ent_t,EV_SZ_classname,p_Classname)
	entity_set_string(Ent_c,EV_SZ_classname,g_Classname)
	entity_set_string(Ent_tt,EV_SZ_classname,y_Classname)
	entity_set_string(Ent_ct,EV_SZ_classname,z_Classname)

	entity_set_int(Ent_t,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_c,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_tt,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(Ent_ct,EV_INT_solid,SOLID_TRIGGER)

	entity_set_origin(Ent_t,t_Origin)
	entity_set_origin(Ent_c,c_Origin)
	entity_set_origin(Ent_tt,tt_Origin)
	entity_set_origin(Ent_ct,ct_Origin)
	
	entity_set_size(Ent_t,Float:{-90.0,-280.5,-117.5},Float:{90.0,270.5,117.5})
	entity_set_size(Ent_c,Float:{-90.0,-275.5,-117.5},Float:{90.0,270.5,117.5})
	entity_set_size(Ent_tt,Float:{-5.0,-995.0,-93.0},Float:{5.0,995.0,93.0})
	entity_set_size(Ent_ct,Float:{-5.0,-995.0,-93.0},Float:{5.0,995.0,93.0})

	entity_set_edict(Ent_t,EV_ENT_owner,id)
	entity_set_edict(Ent_c,EV_ENT_owner,id)
	entity_set_edict(Ent_tt,EV_ENT_owner,id)
	entity_set_edict(Ent_ct,EV_ENT_owner,id)
}

public tocoarcot(Ptd,id)
{
	new owner = entity_get_edict(Ptd,EV_ENT_owner)
	static Float:DistanceBall
	DistanceBall = 600.0
	if(owner == id)
	{
		if(is_user_alive(id) && is_user_connected(id) &&  !is_user_hltv(id))
		{
			if(get_pcvar_num(CVAR_POSS))
			{
				if(entity_range(id, aball) < DistanceBall)
				{			
					if(!T_keeper[id])  
					{
						user_silentkill(id); 
						ColorChat(id, GREY, "[Sj-Pro]^x04 La bocha esta cerca del area")
						//ColorChat(id,RED,"No podes entrar al area chica de los Terrors cuando la bocha esta cerca del area")
					}
				}
			}
		}
	}
}

			

public tocoarcoct(Ptd,id)
{
	new owner = entity_get_edict(Ptd,EV_ENT_owner)
	static Float:DistanceBall
	DistanceBall = 600.0
	if(owner == id)
	{
		if(is_user_alive(id) && is_user_connected(id) &&  !is_user_hltv(id))
		{
			if(entity_range(id, aball) < DistanceBall)
			{
				if(get_pcvar_num(CVAR_POSS))
				{
					if(!CT_keeper[id]) 
					{
						user_silentkill(id)
						ColorChat(id, GREY, "[Sj-Pro]^x04 La bocha esta cerca del area")
					}	
				}
			}
		}
	}
}

public limitet(Ptd,id)
{
	new owner = entity_get_edict(Ptd,EV_ENT_owner)
	if(owner == id)
	{
		if(is_user_alive(id) && is_user_connected(id) &&  !is_user_hltv(id))
		{
			if(get_pcvar_num(CVAR_LIMITES))
			{
				if(user_is_keeper[id] && T_keeper[id])  
				{
					user_silentkill(id)
					ColorChat(id, GREY, "[Sj-Pro]^x04 No podes sobrepasar la mitad de la cancha siendo arquero!")
				}
			}
		}
	}
}	

		
public limitect(Ptd,id)
{
	new owner = entity_get_edict(Ptd,EV_ENT_owner)
	if(owner == id)
	{
		if(is_user_alive(id) && is_user_connected(id) &&  !is_user_hltv(id))
		{
			if(get_pcvar_num(CVAR_LIMITES))
			{	
				if(user_is_keeper[id] && CT_keeper[id]) 
				{
					user_silentkill(id)
					ColorChat(id, GREY, "[Sj-Pro]^x04 No podes sobrepasar la mitad de la cancha siendo arquero!")
				}
			}
		}
	}
}	


/************************************ PLUGINS DE ARQUERO **************************************/


public cmdKeeper(id) 
{ 
	if(get_pcvar_num(CVAR_ARQUEROS))
	{
		if(is_user_alive(id) && soy_spec[id] == false)
		{
			new userteam = get_user_team(id) 
			if(!user_is_keeper[id]) 
			{
				new name[MAX_PLAYER + 1]
				get_user_name(id, name, MAX_PLAYER) 
				if(userteam == 2) 
				{ 
					if(arqueroct == 0)
					{				
						new KeeperMdl[128]
						copy(KeeperMdl, sizeof KeeperMdl - 1, SModel[1])
						CT_keeper[id] = true 
						user_is_keeper[id] = true 
						arqueroct = 1
						set_hudmessage (0, 255, 255, -1.0, 0.2, 2, 0.1, 10.0, 0.05, 1.0, 1) 
						show_hudmessage(0, "%s es el nuevo arquero CT!", name) 
						ColorChat(0, GREY, "[Sj-Pro]^x04 %s es el nuevo arquero CT!", name)
						cs_set_user_model(id, KeeperMdl) 
						set_user_rendering(id,kRenderFxGlowShell,0,255,0,kRenderNormal,255) 
						CurWeapon(id)
				//		play_wav(id, KEEPER);
						play_wav(id, SoundDirect[24])
					}
					else
					{
						new NameKeeper[MAX_PLAYER + 1]
						for(new x = 1; x <= MAX_PLAYER; x++)
						{
							new TeamX = get_user_team(x)		
							if(TeamX == 2 && user_is_keeper[x] && is_user_connected(x))
								get_user_name(x, NameKeeper, MAX_PLAYER)
						}
						
						if(equali(NameKeeper,""))
						{
							arqueroct = 0
							cmdKeeper(id)
							return PLUGIN_HANDLED
						}
						
						ColorChat(id, GREY, "[Sj-Pro]^x04 No podes ser arquero porque ^x03%s^x04 ya lo es", NameKeeper)
					}
				} 
				else if(userteam == 1) 
				{ 
					if(arquerot == 0)
					{	 
						new KeeperMdl[128]
						copy(KeeperMdl, sizeof KeeperMdl - 1, SModel[2])
					
						T_keeper[id] = true 
						user_is_keeper[id] = true 
						arquerot = 1
						set_hudmessage (255, 255, 0, -1.0, 0.25, 2, 0.1, 10.0, 0.05, 1.0, 1)  
						show_hudmessage(0, "%s es el nuevo arquero de los TT", name) 
						ColorChat(0, GREY, "[Sj-Pro]^x04 %s es el nuevo arquero TT!", name)
						cs_set_user_model(id, KeeperMdl)		
						set_user_rendering(id,kRenderFxGlowShell,255,255,0,kRenderNormal,255) 
						CurWeapon(id)				
					//	play_wav(id, KEEPER);
						play_wav(id, SoundDirect[24])
					} 
					else
					{
						new NameKeeper[MAX_PLAYER + 1]
						for(new x = 1; x <= MAX_PLAYER; x++)
						{
							new TeamX = get_user_team(x)		
							if(TeamX == 1 && user_is_keeper[x] && is_user_connected(x))
								get_user_name(x, NameKeeper, MAX_PLAYER)
						}
						
						if(equali(NameKeeper,""))
						{
							arquerot = 0
							cmdKeeper(id)
							return PLUGIN_HANDLED
						}						
						
						ColorChat(id, GREY, "[Sj-Pro]^x04 No podes ser arquero porque ^x03%s^x04 ya lo es", NameKeeper)
					}
				}	
				else
				{
					ColorChat(id, GREY, "[Sj-Pro]^x04 Los SPEC no pueden ser arqueros")
				}
			}
			else
			{
				ColorChat(id, GREY, "[Sj-Pro]^x04 Ya sos arquero!")
			}
		}
	}
	else
		ColorChat(id, GREY, "[Sj-Pro]^x04 Esta opcion no esta habilitada")
	
	return PLUGIN_HANDLED
}

public cmdUnKeeper(id) 
{ 	
	if(user_is_keeper[id]) 
	{
		new CsTeams:userteam = cs_get_user_team(id) 
		new name[MAX_PLAYER + 1] 
		get_user_name(id, name, MAX_PLAYER)
		
		if(userteam == CS_TEAM_CT) 
		{ 
			CT_keeper[id] = false 
			user_is_keeper[id] = false 	
			arqueroct = 0
			
			set_hudmessage (0, 255, 255, -1.0, 0.3, 2, 0.1, 10.0, 0.05, 1.0, 1) 
			show_hudmessage(0, "%s no es mas el arquero de los CT's", name)
			ColorChat(0, GREY, "[Sj-Pro]^x04 %s no es mas el arquero de los CT's", name)	
			cs_reset_user_model(id)
			
			set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,255) 
			resetCurWeapon(id)
		//	play_wav(id, UNKEEPER);
			play_wav(id, SoundDirect[25]);
		} 
		else if(userteam == CS_TEAM_T) 
		{ 
			T_keeper[id] = false 
			user_is_keeper[id] = false 
			arquerot = 0
			
			set_hudmessage (255, 255, 0, -1.0, 0.35, 2, 0.1, 10.0, 0.05, 1.0, 1)  
			show_hudmessage(0, "%s no es mas el arquero de los TT's", name) 
			ColorChat(0, GREY, "[Sj-Pro]^x04 %s no es mas el arquero de los TT's", name)
			
			cs_reset_user_model(id)
			set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,255) 
			resetCurWeapon(id)
		//	play_wav(id, UNKEEPER);
			play_wav(id, SoundDirect[25]);
		} 
	} 
	return PLUGIN_HANDLED
}

/**************************************** RECORDS ****************************************/

public records(id)

{
	new award[513]
	new len = 0

	len += format(award[len], 512-len, "Records ^n^nGoles: %i^n",MadeRecord[id][GOAL],0)
	len += format(award[len], 512-len, "Robos: %i^n",MadeRecord[id][STEAL],0)
	len += format(award[len], 512-len, "Asistencias: %i^n",MadeRecord[id][ASSIST],0)
	len += format(award[len], 512-len, "Ball kill: %i^n", MadeRecord[id][KILL],0)
	len += format(award[len], 512-len, "Gol lejano: %i Pies^n", MadeRecord[id][DISTANCE],0)
	len += format(award[len], 512-len, "Disarms: %i^n", MadeRecord[id][DISARMS],0)
	len += format(award[len], 512-len, "Goles en contra: %i^n", MadeRecord[id][ENCONTRA],0)
	set_hudmessage(255, 128, 0,  0.15, 0.15, 0, 0.2, 5.0, 0.2, 0.1, 2)
	show_hudmessage(id, "%s", award)
	
	return PLUGIN_HANDLED
}



/**************************************  GLOWS  ********************************************/

public glow_del_player(id)
{
	if(!user_is_keeper[id] && id == ballholder && !is_user_foul[id] && !is_offside[id])
	{
		if(cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_rendering(id, kRenderFxGlowShell, PlayerColors[0], PlayerColors[1], PlayerColors[2], kRenderNormal, PlayerColors[12])
			entity_set_float(id, EV_FL_renderamt, 1.0)
			
		}

		else if(cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_rendering(id, kRenderFxGlowShell, PlayerColors[3], PlayerColors[4], PlayerColors[5], kRenderNormal, PlayerColors[12])
			entity_set_float(id, EV_FL_renderamt, 1.0)
		}
	}
	else if(id == ballholder)
	{
		if(cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_rendering(id, kRenderFxGlowShell, PlayerColors[6], PlayerColors[7], PlayerColors[8], kRenderNormal, PlayerColors[13])
			entity_set_float(id, EV_FL_renderamt, 1.0)
		}

		else if(cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_rendering(id, kRenderFxGlowShell, PlayerColors[9], PlayerColors[10], PlayerColors[11], kRenderNormal, PlayerColors[13])
			entity_set_float(id, EV_FL_renderamt, 1.0)
		}
	}
	
	// Set Player MaxSpeed
	if (is_user_foul[id] || is_offside[id])
	{
		set_pev(id, pev_velocity, Float:{0.0,0.0,0.0}) // stop motion
		set_pev(id, pev_maxspeed, 1.0) // prevent from moving
	}
	else
	{
		if(!g_sprint[id])
			set_speedchange(id)
	}	
}

		
/************************************** MOD NAME *****************************************/

/*
public GameDesc() 
{ 
	forward_return(FMV_STRING, mod_name)
	return FMRES_SUPERCEDE
}
*/
/*********************************** MENUS PARA ADM *************************************/


public menu_pro(id){

	new flags = get_user_flags(id)
	
	if(flags&ADMIN_KICK)
	{	
		new soccermenu = menu_create("Menu Sj-Pro", "handSoccerMenu")
	
		menu_additem(soccermenu, "CFG's", "1",0)
		menu_additem(soccermenu, "Mapas","2",0)
		menu_additem(soccermenu, "Comandos","3",0)
		menu_additem(soccermenu, "Cvars","4",0)
		menu_additem(soccermenu, "Help para Admins","5",0)
		menu_addblank(soccermenu,1)
		menu_display(id, soccermenu, 0)	
	}	
	
	return PLUGIN_HANDLED
	
}


public handSoccerMenu(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED
	}

	if( item == 0)	
	{
		displaysoccercfg(id);
	}
	
	if( item == 1)	
	{
		displaysoccercambiar(id);
	}
	
	if( item == 2)	
	{
		comandos_utiles(id)
	}

	if( item == 3)	
	{
		cvars_utiles(id, 0)
	}

	if( item == 4)	
	{
		client_cmd(id,"help_pro")
	}

	return PLUGIN_HANDLED;
}

/*====================================================================================================
 [CVARS MENU]

 Purpose:	Advance Cvars

 Comment:	$$

====================================================================================================*/


public cvars_utiles(id, select)
{	
	new menucvars = menu_create("Cvars ...", "menudecvars")
	new auxiliar = get_pcvar_num(CVAR_POSS)
	
	if (auxiliar)
		menu_additem(menucvars, "Poss areas: Activo", "1", 0)
	else
		menu_additem(menucvars, "Poss areas: Inactivo", "1", 0)	
		
	auxiliar = get_pcvar_num(CVAR_LIMITES)
	
	if (auxiliar)
		menu_additem(menucvars, "Limites de arquero: Activo", "2", 0)
	else 
		menu_additem(menucvars, "Limites de arquero: Inactivo", "2", 0)	
		
	auxiliar = get_pcvar_num(CVAR_ARQUEROS)
	
	if (auxiliar)
		menu_additem(menucvars, "Sistema de arqueros: Activo", "3", 0)
	else
		menu_additem(menucvars, "Sistema de arqueros: Inactivo", "3", 0)
		
	auxiliar = get_pcvar_num(CVAR_FRAG)
	
	if (auxiliar)
		menu_additem(menucvars, "Anti-Frag: Inactivo", "4", 0)
	else
		menu_additem(menucvars, "Anti-Frag: Activo", "4", 0)
		
	auxiliar = get_pcvar_num(CVAR_ENCONTRA)
	
	if (auxiliar)
		menu_additem(menucvars, "Goles en contra: Activo", "5", 0)
	else 
		menu_additem(menucvars, "Goles en contra: Inactivo", "5", 0)
		
	auxiliar = get_pcvar_num(CVAR_OFFSIDE)
	
	if (auxiliar)
		menu_additem(menucvars, "Offside: Activo", "5", 0)
	else 
		menu_additem(menucvars, "Offside: Inactivo", "5", 0)	

	auxiliar = get_pcvar_num(CVAR_FOUL)
	
	if (auxiliar)
		menu_additem(menucvars, "Foul: Activo", "5", 0)
	else 
		menu_additem(menucvars, "Foul: Inactivo", "5", 0)	

	auxiliar = get_pcvar_num(CVAR_SPEC)
	
	if (auxiliar)
		menu_additem(menucvars, "Spec: Activo", "5", 0)
	else 
		menu_additem(menucvars, "Spec: Inactivo", "5", 0)		
		
	auxiliar = get_pcvar_num(CVAR_SPEC_CABINAS)
	
	if (auxiliar)
		menu_additem(menucvars, "Cabinas: Activo", "5", 0)
	else 
		menu_additem(menucvars, "Cabinas: Inactivo", "5", 0)
	
	
	menu_setprop(menucvars , MPROP_BACKNAME , "Atras...");
	menu_setprop(menucvars , MPROP_NEXTNAME , "Mas...");
	menu_setprop(menucvars , MPROP_EXITNAME , "Exit");
	menu_setprop(menucvars , MPROP_PERPAGE , 6);
	menu_setprop(menucvars , MPROP_EXIT , MEXIT_ALL);
	
	menu_addblank(menucvars,1)
	menu_display(id,menucvars,select)

	return PLUGIN_HANDLED

}


public menudecvars(id, menu, item){
	
	
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED

	switch(item)
	{
		case 0: if (get_pcvar_num(CVAR_POSS))
					set_cvar_num("sj_poss_areas",0)
				else 
					set_cvar_num("sj_poss_areas",1)
					
		case 1: if (get_pcvar_num(CVAR_LIMITES))
					set_cvar_num("sj_limites",0)
				else 
					set_cvar_num("sj_limites",1)
					
		case 2: if (get_pcvar_num(CVAR_ARQUEROS))
					set_cvar_num("sj_arqueros",0)
				else 
					set_cvar_num("sj_arqueros",1)
					
		case 3: if (get_pcvar_num(CVAR_FRAG))
					set_cvar_num("sj_frag",0)
				else
					set_cvar_num("sj_frag",1)

		case 4: if (get_pcvar_num(CVAR_ENCONTRA))
					set_cvar_num("sj_golesencontra",0)
				else 
					set_cvar_num("sj_golesencontra",1)
					
		case 5: if (get_pcvar_num(CVAR_OFFSIDE))
					set_cvar_num("sj_offside",0)
				else 
					set_cvar_num("sj_offside",1)

		case 6: if (get_pcvar_num(CVAR_FOUL))
					set_cvar_num("sj_foul",0)
				else 
					set_cvar_num("sj_foul",1)	

		case 7: if (get_pcvar_num(CVAR_SPEC))
					set_cvar_num("sj_spec",0)
				else 
					set_cvar_num("sj_spec",1)	

		case 8: if (get_pcvar_num(CVAR_SPEC_CABINAS))
					set_cvar_num("sj_spec_cabinas",0)
				else 
					set_cvar_num("sj_spec_cabinas",1)						
	}
	
	if(item < 6)	
		cvars_utiles(id, 0)
	else
		cvars_utiles(id, 1)
		
	return PLUGIN_HANDLED
}


/*====================================================================================================
 [CFG MENU]

 Purpose:	Un sencillo menu de cfgs

 Comment:	$$

====================================================================================================*/


public displaysoccercfg(id)
{	
	new menusoccercfg = menu_create("Ejecutar CFG ...", "handsoccercfg")
	
	menu_additem(menusoccercfg, "Publico", "1", 0)
	menu_additem(menusoccercfg, "Cerrado", "2", 0)
	menu_additem(menusoccercfg, "Vale!", "3", 0)
	menu_additem(menusoccercfg, "Frag Arqueros", "4", 0)

	menu_addblank(menusoccercfg,1)
	menu_display(id,menusoccercfg,0)

	return PLUGIN_HANDLED

}


public handsoccercfg(id, menu, item){
	
	
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0: client_cmd(id,"sj_publico")
		case 1: client_cmd(id,"sj_cerrado")
		case 2: client_cmd(id,"sj_vale")
		case 3: client_cmd(id,"sj_fragarqueros")
	}
	displaysoccercfg(id);
	return PLUGIN_HANDLED
}


/*====================================================================================================
 [CAMBIAR MAPA MENU]

 Purpose:	Un sencillo menu para cambiar mapas pre definidos

 Comment:	$$

====================================================================================================*/


public displaysoccercambiar(id){
	

	new menusoccercambiar = menu_create("Cambiar al mapa...","handsoccercambiar")


	menu_additem(menusoccercambiar, "Soccerjam", "1", 0)
	menu_additem(menusoccercambiar, "Indoorx", "2", 0)
		
	menu_addblank(menusoccercambiar,1)
	menu_display(id,menusoccercambiar,0)

	return PLUGIN_HANDLED

}


public handsoccercambiar(id, menu, item){
	
	
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED
    }

	switch(item)
	{
		case 0: client_cmd(id,"amx_map soccerjam")
		case 1: client_cmd(id,"amx_map sj_indoorx_small")
	}
	return PLUGIN_HANDLED
}


/*====================================================================================================
 [COMANDOS UTILES]

 Purpose:	Un sencillo menu para visualizar los comandos

 Comment:	$$

====================================================================================================*/


public comandos_utiles(id){
	

	new menucomandos = menu_create("Comandos...","menudecomandos")

	menu_additem(menucomandos, "Todos spec!", "1", 0)
	menu_additem(menucomandos, "Full exp", "2", 0)
	menu_additem(menucomandos, "Full habilidades", "3", 0)
	menu_additem(menucomandos, "Reiniciar partido", "4", 0)
	menu_additem(menucomandos, "Desbuguear arqueros", "5", 0)
	
	menu_addblank(menucomandos,1)
	menu_display(id,menucomandos,0)

}

public menudecomandos(id, menu, item){
	
	
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED
    }

	switch(item)
	{
		case 0: client_cmd(id,"amx_spec")
		case 1: client_cmd(id,"amx_exp")
		case 2: client_cmd(id,"amx_full")
		case 3: client_cmd(id,"amx_start")
	}
	
	if(item == 4)	
	{
		desbuguear_arqueros(id)
	}
	comandos_utiles(id);
	return PLUGIN_HANDLED
}

public desbuguear_arqueros(id)
{
	if(arqueroct == 1)
		arqueroct = 0
	if(arquerot == 1)
		arquerot = 0
	
	ColorChat(id,GREEN,"Arqueros desbugueados!")
	return PLUGIN_HANDLED
}

public ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	static message[256];

	switch(type)
	{
		case YELLOW: // Yellow
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	new team, ColorChange, index, MSG_Type;
	
	if(!id)
	{
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	
	} else {
		MSG_Type = MSG_ONE;
		index = id;
	}
	
	team = get_user_team(index);	
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, SayText, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	message_begin(type, TeamInfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	new i = -1;

	while(i <= MaxSlots)
	{
		if(IsConnected[++i])
		{
			return i;
		}
	}

	return -1;
}


public spec_cabina(id)
{
	new nombredelmap[64]
	get_mapname(nombredelmap,63)
	new origin[3]
	new z = 100
	
	if(equali(nombredelmap,"sj_indoorx_small") || equali(nombredelmap,"sj_pro") || equali(nombredelmap,"sj_pro_small")) 
	{
		if(get_pcvar_num(CVAR_SPEC_CABINAS))
		{
			if(is_user_alive(id) && !is_user_bot(id) && is_user_connected(id) &&  !is_user_hltv(id) && id != ballholder && !user_is_keeper[id])
			{
				cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE) 
				
				if(equali(nombredelmap,"sj_indoorx_small"))
				{
					origin[0] = -820
					origin[1] = 680
					origin[2] = -75
				}
				
				else if(equali(nombredelmap,"sj_pro"))
				{
					origin[0] = -700
					origin[1] = 1310
					origin[2] = -290
				}
				
				else if(equali(nombredelmap,"sj_pro_small"))
				{
					origin[0] = -690
					origin[1] = 1260
					origin[2] = -290
				}	
				
				switch(espectadores)
				{
					case 0:	origin[0] = origin[0] + z*0
					case 1: origin[0] = origin[0] + z*1
					case 2: origin[0] = origin[0] + z*2
					case 3: origin[0] = origin[0] + z*3	
					case 4: origin[0] = origin[0] + z*4	
					case 5: origin[0] = origin[0] + z*5	
					case 6: origin[0] = origin[0] + z*6	
					case 7: origin[0] = origin[0] + z*7	
					case 8: origin[0] = origin[0] + z*8	
					case 9: origin[0] = origin[0] + z*9	
					case 10: origin[0] = origin[0] + z*10	
					case 11: origin[0] = origin[0] + z*11	
					case 12: origin[0] = origin[0] + z*12	
					case 13: origin[0] = origin[0] + z*13	
					case 14: origin[0] = origin[0] + z*14	
					case 15: origin[0] = origin[0] + z*15	
					case 16: origin[0] = origin[0] + z*16	
					case 17: origin[0] = origin[0] + z*17	
					case 18: origin[0] = origin[0] + z*18
				}
				if(espectadores < 18)
					espectadores++
				else
					espectadores = 0
					
			//	strip_user_weapons (id)
					
				set_user_origin(id, origin)
				
				ColorChat(id,GREY,"[Sj-Pro]^x04 Te teletransportaste a la cabina de los spec")
				
				soy_spec[id] = true
			}
			else
				ColorChat(id,GREY,"[Sj-Pro]^x04 Debes estar vivo y no tener la bocha para transferirte a la cabina de los spec")
		}
		else
			ColorChat(id,GREY,"[Sj-Pro]^x04 Opcion no habilitada")
		
	}
	
	else if(equali(nombredelmap,"soccerjam")) 
	{
		if(get_pcvar_num(CVAR_SPEC_CABINAS))
		{
			if(is_user_alive(id) && !is_user_bot(id) && is_user_connected(id) &&  !is_user_hltv(id) && id != ballholder && !user_is_keeper[id])
			{
				cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
				
				origin[0] = -1600
				origin[1] = 3250
				origin[2] = 1975
				
				switch(espectadores)
				{
					case 0:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*0
					}
					case 1:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*1
					}
					case 2:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*2
					}
					case 3:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*3
					}
					case 4:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*0
					}
					case 5:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*1
					}
					case 6:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*2
					}
					case 7:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*3
					}
					case 8:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*0
					}
					case 9:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*1
					}
					case 10:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*2
					}
					case 11:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*3
					}
					case 12:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*0
					}
					case 13:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*1
					}
					case 14:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*2
					}
					case 15:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*3
					}
					case 16:
					{	
						origin[0] = -2290
						origin[1] = 3160
					}
					case 17:
					{	
						origin[0] = -2290
						origin[1] = 3260
					}		
				}
				if(espectadores < 17)
					espectadores++
				else
					espectadores = 0
					
			//	strip_user_weapons (id)
					
				set_user_origin(id, origin)
				
				ColorChat(id,GREY,"[Sj-Pro]^x04 Te teletransportaste a la cabina de los spec")
				
				soy_spec[id] = true
			}
			else
				ColorChat(id,GREY,"[Sj-Pro]^x04 Debes estar vivo y no tener la bocha para transferirte a la cabina de los spec")
		}
		else
			ColorChat(id,GREY,"[Sj-Pro]^x04 Opcion no habilitada")
		
	}
	else
		ColorChat(id,GREY,"[Sj-Pro]^x04 Solo en indoorx, soccerjam, sj_pro y sj_pro_small")
	
	return PLUGIN_HANDLED
}


public spec_cabina_menu(id)
{
	new nombredelmap[64]
	get_mapname(nombredelmap,63)
	new origin[3]
	new z = 100
	
	if(equali(nombredelmap,"sj_indoorx_small") || equali(nombredelmap,"sj_pro") || equali(nombredelmap,"sj_pro_small")) 
	{
		if(get_pcvar_num(CVAR_SPEC_CABINAS))
		{
			if(!is_user_bot(id) && is_user_connected(id) &&  !is_user_hltv(id) && id != ballholder && !user_is_keeper[id])
			{
				if(!is_user_alive(id))
					spawn(id)
				
				cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE) 
				
				if(equali(nombredelmap,"sj_indoorx_small"))
				{
					origin[0] = -820
					origin[1] = 680
					origin[2] = -75
				}
				
				else if(equali(nombredelmap,"sj_pro"))
				{
					origin[0] = -700
					origin[1] = 1310
					origin[2] = -290
				}
				
				else if(equali(nombredelmap,"sj_pro_small"))
				{
					origin[0] = -690
					origin[1] = 1260
					origin[2] = -290
				}	
				
				switch(espectadores)
				{
					case 0:	origin[0] = origin[0] + z*0
					case 1: origin[0] = origin[0] + z*1
					case 2: origin[0] = origin[0] + z*2
					case 3: origin[0] = origin[0] + z*3	
					case 4: origin[0] = origin[0] + z*4	
					case 5: origin[0] = origin[0] + z*5	
					case 6: origin[0] = origin[0] + z*6	
					case 7: origin[0] = origin[0] + z*7	
					case 8: origin[0] = origin[0] + z*8	
					case 9: origin[0] = origin[0] + z*9	
					case 10: origin[0] = origin[0] + z*10	
					case 11: origin[0] = origin[0] + z*11	
					case 12: origin[0] = origin[0] + z*12	
					case 13: origin[0] = origin[0] + z*13	
					case 14: origin[0] = origin[0] + z*14	
					case 15: origin[0] = origin[0] + z*15	
					case 16: origin[0] = origin[0] + z*16	
					case 17: origin[0] = origin[0] + z*17	
					case 18: origin[0] = origin[0] + z*18
				}
				
				if(espectadores < 18)
					espectadores++
				else
					espectadores = 0
					
			//	strip_user_weapons (id)
					
				set_user_origin(id, origin)
				
				ColorChat(id,GREY,"[Sj-Pro]^x04 Te teletransportaste a la cabina de los spec")
				
				soy_spec[id] = true
			}
			else
				ColorChat(id,GREY,"[Sj-Pro]^x04 Debes estar vivo y no tener la bocha para transferirte a la cabina de los spec")
		}
		else
			ColorChat(id,GREY,"[Sj-Pro]^x04 Opcion no habilitada")
		
	}
	
	else if(equali(nombredelmap,"soccerjam")) 
	{
		if(get_pcvar_num(CVAR_SPEC_CABINAS))
		{
			if(!is_user_bot(id) && is_user_connected(id) &&  !is_user_hltv(id) && id != ballholder && !user_is_keeper[id])
			{		
				if(!is_user_alive(id))
					spawn(id)
					
				cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
				
				origin[0] = -1600
				origin[1] = 3250
				origin[2] = 1975
				
				switch(espectadores)
				{
					case 0:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*0
					}
					case 1:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*1
					}
					case 2:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*2
					}
					case 3:
					{	
						origin[0] = origin[0] - z*0
						origin[1] = origin[1] - z*3
					}
					case 4:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*0
					}
					case 5:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*1
					}
					case 6:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*2
					}
					case 7:
					{	
						origin[0] = origin[0] - z*1
						origin[1] = origin[1] - z*3
					}
					case 8:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*0
					}
					case 9:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*1
					}
					case 10:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*2
					}
					case 11:
					{	
						origin[0] = origin[0] - z*2
						origin[1] = origin[1] - z*3
					}
					case 12:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*0
					}
					case 13:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*1
					}
					case 14:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*2
					}
					case 15:
					{	
						origin[0] = origin[0] - z*3
						origin[1] = origin[1] - z*3
					}
					case 16:
					{	
						origin[0] = -2290
						origin[1] = 3160
					}
					case 17:
					{	
						origin[0] = -2290
						origin[1] = 3260
					}		
				}
				if(espectadores < 17)
					espectadores++
				else
					espectadores = 0
					
			//	strip_user_weapons (id)
					
				set_user_origin(id, origin)
				
				ColorChat(id,GREY,"[Sj-Pro]^x04 Te teletransportaste a la cabina de los spec")
				
				soy_spec[id] = true
			}
			else
				ColorChat(id,GREY,"[Sj-Pro]^x04 Debes estar vivo y no tener la bocha para transferirte a la cabina de los spec")
		}
		else
			ColorChat(id,GREY,"[Sj-Pro]^x04 Opcion no habilitada")
		
	}
	else
		ColorChat(id,GREY,"[Sj-Pro]^x04 Solo en indoorx, soccerjam, sj_pro y sj_pro_small")
	
	return PLUGIN_HANDLED
}

public teleport_aco(Ptd,id)
{	
	new owner = entity_get_edict(Ptd,EV_ENT_owner)
	if(owner == id)
	{
		new origin_aco[3]
		origin_aco[0] = 222
		origin_aco[1] = 770
		origin_aco[2] = -290
		set_user_origin(id,origin_aco)
//		play_wav(id, TELEPORT)
		play_wav(id, SoundDirect[21])
	}
}

public teleport_2(Ptd,id)
{	
	new owner = entity_get_edict(Ptd,EV_ENT_owner)
	if(owner == id)
	{
		new origin[3]
		new z = 100
		origin[0] = -820
		origin[1] = 680
		origin[2] = -75
		switch(espectadores)
		{
			case 0:	origin[0] = origin[0] + z*0
			case 1: origin[0] = origin[0] + z*1
			case 2: origin[0] = origin[0] + z*2
			case 3: origin[0] = origin[0] + z*3	
			case 4: origin[0] = origin[0] + z*4	
			case 5: origin[0] = origin[0] + z*5	
			case 6: origin[0] = origin[0] + z*6	
			case 7: origin[0] = origin[0] + z*7	
			case 8: origin[0] = origin[0] + z*8	
			case 9: origin[0] = origin[0] + z*9	
			case 10: origin[0] = origin[0] + z*10	
			case 11: origin[0] = origin[0] + z*11	
			case 12: origin[0] = origin[0] + z*12	
			case 13: origin[0] = origin[0] + z*13	
			case 14: origin[0] = origin[0] + z*14	
			case 15: origin[0] = origin[0] + z*15	
			case 16: origin[0] = origin[0] + z*16	
			case 17: origin[0] = origin[0] + z*17	
			case 18: origin[0] = origin[0] + z*18
		}
		if(espectadores < 18)
			espectadores++
		else
			espectadores = 0
			
		set_user_origin(id, origin)
	//	play_wav(id, TELEPORT)
		play_wav(id, SoundDirect[21])
	}
}

public resetCurWeapon(id)
{
	new Clip, Ammo, Weapon = get_user_weapon(id, Clip, Ammo) 
	if ( Weapon != CSW_KNIFE )
		return PLUGIN_HANDLED

	new vModel[56],pModel[56]
	
	format(vModel,55,"models/%s.mdl", SModel[5])
	format(pModel,55,"models/%s.mdl", SModel[6])

	entity_set_string(id, EV_SZ_viewmodel, vModel)
	entity_set_string(id, EV_SZ_weaponmodel, pModel)
	
	return PLUGIN_HANDLED	
}

public CurWeapon(id)
{
	new Clip, Ammo, Weapon = get_user_weapon(id, Clip, Ammo) 
	if ( Weapon != CSW_KNIFE )
		return PLUGIN_HANDLED

	new vModel[56],pModel[56]

	if(user_is_keeper[id])
	{	
		format(vModel,55,"models/Sj-Pro/Fakas/%s.mdl", SModel[3])			
		format(pModel,55,"models/Sj-Pro/Fakas/%s.mdl", SModel[4])
	}
	else
	{	
		format(vModel,55,"models/%s.mdl", SModel[5])		
		format(pModel,55,"models/%s.mdl", SModel[6])
	}
	entity_set_string(id, EV_SZ_viewmodel, vModel)
	entity_set_string(id, EV_SZ_weaponmodel, pModel)
	
	return PLUGIN_HANDLED	
}

public Gol_Sprite(id)
{	
	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(124)
	write_byte(id)
	write_coord(65)
	write_short(SpriteGol)
	write_short(40)
	message_end()
}

public Encontra_Sprite(id)
{	
	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(124)
	write_byte(id)
	write_coord(65)
	write_short(SpriteGolContra)
	write_short(40)
	message_end()
}

public AutoRestart()
{
	server_cmd("sv_restartround 1")
}

public SvCerrado(id)
{
	new mapname[64]
	new flags = get_user_flags(id)
	
	get_mapname(mapname,63)
	
	if(flags&ADMIN_KICK)
	{	
		if(!Seguridad_cfg)
		{
			Seguridad_cfg = true
			set_task(5.0,"Seg_cfg")
			new nameadm[MAX_PLAYER + 1]
			new configfile[32]
			
			format(configfile, 31, "sjcerrado.cfg")
			
			if(!file_exists(configfile))
			{
				ColorChat(id, GREY, "[Sj-Pro]^x04 No se encuentra la cfg ^x03%s^x04", configfile)
				return PLUGIN_HANDLED;
			}
			
			server_cmd("exec %s", configfile)			
			
			get_user_name(id, nameadm, MAX_PLAYER)	
			
			set_cvar_num("sv_allowupload", 1)
			set_cvar_num("sv_allowdownload", 1)			
			
			ActiveJoinTeam = 0;
			
			set_hudmessage(0, 0, 255, 0.42, 0.40, 2, 6.0, 4.0, 0.1, 0.2, -1)
			show_hudmessage(0, "-- SERVER EN CFG CERRADO --")
			ColorChat(0,BLUE,"-- SERVER EN CFG CERRADO --")
			ColorChat(0,BLUE,"-- SERVER EN CFG CERRADO --")
			ColorChat(0,BLUE,"-- SERVER EN CFG CERRADO --")
			ColorChat(0,BLUE,"-- SERVER EN CFG CERRADO --")
			ColorChat(0,BLUE,"-- SERVER EN CFG CERRADO --")

			if(equali(mapname,"soccerjam")) 
				set_cvar_num("sj_score", 20) 

			if(equali(mapname,"sj_indoorx_small")) 
				set_cvar_num("sj_score", 30)			

			new i
			for(i = 1; i <= MAX_PLAYER; i++)
			{
				if(user_is_keeper[i])
					cmdUnKeeper(i)
			}
			arqueroct = 0
			arquerot = 0 
			
			ColorChat(0, YELLOW, "ADMIN ^x04%s^x01 ejecuto la cfg de cerrado",nameadm)
			set_task(5.0,"ayuda_atajar")	
		}
		else 
			ColorChat(id,RED,"Debes esperar 5 seg para ejecutar una cfg")
	}
	else
		NoAdmin(id)
		
	return PLUGIN_HANDLED	
}

public SvPublico(id)
{
	new mapname[64]
	new flags = get_user_flags(id)
	
	get_mapname(mapname,63)
	
	if(flags&ADMIN_KICK)
	{	
		if(!Seguridad_cfg)
		{
			Seguridad_cfg = true
			set_task(5.0,"Seg_cfg")	
			new nameadm[MAX_PLAYER + 1]
			
			new configfile[32]
			
			format(configfile, 31, "sjpublico.cfg")
			
			if(!file_exists(configfile))
			{
				ColorChat(id, GREY, "[Sj-Pro]^x04 No se encuentra la cfg ^x03%s^x04", configfile)
				return PLUGIN_HANDLED;
			}
			
			server_cmd("exec %s", configfile)	
			
			get_user_name(id, nameadm, MAX_PLAYER)	
			set_cvar_num("sv_allowupload", 1)
			set_cvar_num("sv_allowdownload", 1)
	
			set_hudmessage(255, 0, 0, 0.42, 0.53, 2, 6.0, 4.0, 0.1, 0.2, -1)
			show_hudmessage(0, "-- SERVER EN CFG PUBLICO --")
			ColorChat(0,GREY,"-- SERVER EN CFG PUBLICO --")
			ColorChat(0,GREY,"-- SERVER EN CFG PUBLICO --")
			ColorChat(0,GREY,"-- SERVER EN CFG PUBLICO --")
			ColorChat(0,GREY,"-- SERVER EN CFG PUBLICO --")
			ColorChat(0,GREY,"-- SERVER EN CFG PUBLICO --")
			
			ActiveJoinTeam = 0;

			if(equali(mapname,"soccerjam")) 
				set_cvar_num("sj_score", 20) 

			if(equali(mapname,"sj_indoorx_small")) 
				set_cvar_num("sj_score", 30)		
				
			new i
			for(i = 1; i <= MAX_PLAYER; i++)
			{
				if(user_is_keeper[i])
				{
					if(CT_keeper[i])
						CT_keeper[i] = false 
					if(T_keeper[i])
						T_keeper[i] = false 
						
					user_is_keeper[i] = false 	
					cs_reset_user_model(i) 
				}	
			//	if(is_user_connected(i))
			//		Pro_Active[i] = 0;		// version 5.06
			}
			arqueroct = 0
			arquerot = 0 
			
	//		set_cvar_num("sj_systemexp", 0)
			sj_systemrank = 0
			BorrarSistemExp()
				
			ColorChat(0, YELLOW, "ADMIN ^x04%s^x01 ejecuto la cfg de publico", nameadm)
		}
		else 
			ColorChat(id,RED,"Debes esperar 5 seg para ejecutar una cfg")
	}
	else
		NoAdmin(id)
		
	return PLUGIN_HANDLED	
}

public SvVale(id)
{
	new flags = get_user_flags(id)
	if(flags&ADMIN_KICK)
	{	
		if(!Seguridad_cfg)
		{
			Seguridad_cfg = true
			set_task(10.0,"Seg_cfg")	
			BeginCountdown()
	
			new configfile[32]
			
			format(configfile, 31, "sjvale.cfg")
			
			if(!file_exists(configfile))
			{
				ColorChat(id, GREY, "[Sj-Pro]^x04 No se encuentra la cfg ^x03%s^x04", configfile)
				return PLUGIN_HANDLED;
			}
			
			server_cmd("exec %s", configfile)	
			
			new nameadm[MAX_PLAYER + 1]
			get_user_name(id, nameadm, MAX_PLAYER)	
			set_cvar_num("sv_allowupload", 1)
			set_cvar_num("sv_allowdownload", 1)

			
			/*
			set_cvar_num("sj_limites", 1)
			set_cvar_num("sv_alltalk", 0)
			set_cvar_num("sj_kick", 650)
			set_cvar_num("sj_goalsafety", 650)
			set_cvar_num("sj_frag", 1)
			set_cvar_num("sj_areas", 700)
			set_cvar_num("sj_golesencontra", 1)
			set_cvar_num("sj_foul", 0)
			set_cvar_num("sj_offside", 1)	
			*/
			
			set_task(12.0,"vale1",0)
			
			ColorChat(0,GREEN,"En 10 segundos comienza el cerrado/rjt")
			ColorChat(0,GREEN,"En 10 segundos comienza el cerrado/rjt")
			ColorChat(0,GREEN,"En 10 segundos comienza el cerrado/rjt")
			ColorChat(0,GREEN,"En 10 segundos comienza el cerrado/rjt")
			ColorChat(0,GREEN,"En 10 segundos comienza el cerrado/rjt")	
			
			ColorChat(0, YELLOW, "ADMIN ^x04%s^x01 ejecuto la cfg de vale", nameadm)
		
			ActiveJoinTeam = 0;
			
			moveBall(0)
			
			return PLUGIN_HANDLED	
		}
		else 
			ColorChat(id,RED,"Debes esperar 10 seg para ejecutar una cfg")		
	}
	else
		NoAdmin(id)
		
	return PLUGIN_HANDLED	
}

public vale1()
{
	new clase_tt = 0, clase_ct = 0, suma_player = 0;
	for(new x = 1; x <= MAX_PLAYER; x++)
	{	
		if(is_user_connected(x))
		{
			switch(TeamSelect[x])
			{
				case 1: clase_tt++
				case 2: clase_ct++
			}
		}
	}

	suma_player = clase_tt + clase_ct	
	
	set_hudmessage(0, 225, 255, 0.42, 0.40, 2, 6.0, 4.0, 0.1, 0.2, -1)
	show_hudmessage(0, "VALE!          VALE!           VALE!")
	
	BorrarSistemExp()

//	set_cvar_num("sj_systemexp", 1)

	if(suma_player >= ConfigPro[31])
		sj_systemrank = 1
	else
		sj_systemrank = 0

	ActiveJoinTeam = 1;	
	
	ColorChat(0,GREEN,"-- VALE! --")
	ColorChat(0,GREEN,"-- VALE! --")
	ColorChat(0,GREEN,"-- VALE! --")
	ColorChat(0,GREEN,"-- VALE! --")
	ColorChat(0,GREEN,"-- VALE! --")	
	
	set_task(5.0,"vale2")
}

public vale2()
{
	if(get_pcvar_num(CVAR_RESEXP))
		ColorChat(0,GREY,"Sistema save game ^x04habilitado")
	else
		ColorChat(0,TEAM_COLOR,"Sistema save game deshabilitado")
		
	if(sj_systemrank == 1 && get_pcvar_num(CVAR_RANK))
		ColorChat(0,GREY,"Sistema de rank ^x04habilitado")
	else
		ColorChat(0,TEAM_COLOR,"Sistema de rank deshabilitado")
}

public SvFrag(id)
{
	new flags = get_user_flags(id)
	if(flags&ADMIN_KICK)
	{	
		if(!Seguridad_cfg)
		{
			Seguridad_cfg = true
			set_task(10.0,"Seg_cfg")		
			new nameadm[MAX_PLAYER + 1]
			get_user_name(id, nameadm, MAX_PLAYER)	
			BeginCountdown()
			
			new configfile[32]
			
			format(configfile, 31, "sjfragarqueros.cfg")
			
			if(!file_exists(configfile))
			{
				ColorChat(id, GREY, "[Sj-Pro]^x04 No se encuentra la cfg ^x03%s^x04", configfile)
				return PLUGIN_HANDLED;
			}
			
			server_cmd("exec %s", configfile)			
			/*
			set_cvar_num("sj_limites", 0)
			set_cvar_num("sj_frag", 1)		
			*/
			set_task(12.0,"frag1",0)
			ColorChat(0, YELLOW, "ADMIN ^x04%s^x01 ejecuto la cfg de frag-arqueros", nameadm)
			ColorChat(0,GREY,"[Sj-Pro]^x04 En 10 seg los arqueros deberan fraguearse")
			ActiveJoinTeam = 0;
			
			return PLUGIN_HANDLED	
		}
		else 
			ColorChat(id,GREY,"[Sj-Pro]^x04 Debes esperar 10 seg para ejecutar una cfg")
	}
	else
		NoAdmin(id)
		
	return PLUGIN_HANDLED	
}

public Seg_cfg()
{
	Seguridad_cfg = false
	return PLUGIN_HANDLED
}

public frag1()
{
	set_hudmessage(255, 180, 60, 0.42, 0.53, 2, 6.0, 4.0, 0.1, 0.2, -1)
	show_hudmessage(0, "FRAG ARQUEROS!")
	ColorChat(0,RED,"-- FRAG ARQUEROS! --")
	ColorChat(0,RED,"-- FRAG ARQUEROS! --")
	ColorChat(0,RED,"-- FRAG ARQUEROS! --")
	ColorChat(0,RED,"-- FRAG ARQUEROS! --")
	ColorChat(0,RED,"-- FRAG ARQUEROS! --")
}
	
public ayuda_atajar()
{
	ColorChat(0,YELLOW,"Escribe en say ^x04/atajo^x01 para ser el nuevo arquero del equipo")
	ColorChat(0,YELLOW,"Escribe en say ^x04/noatajo^x01 para dejar de ser el arquero del equipo")
}

public NoAdmin(id)
{
	bobo[id] += 1
	console_print(id, "Comprate un admin primero")
	
	if(bobo[id] == 2)
	{
		new ipa[MAX_PLAYER + 1]
		new name[MAX_PLAYER + 1]
		get_user_ip(id, ipa, MAX_PLAYER, 1)
		get_user_name(id, name, MAX_PLAYER)
		server_cmd("addip 5 %s;writeip", ipa)
		ColorChat(0,GREY,"[Sj-Pro]^x04 %s fue baneado por 5 min por intentar ejecutar comandos sin ser adm",name)
	}
}



/*
public apuntado(id)
{
	new name[MAX_PLAYER + 1]
	new aimed, body, team1, team2, hp;
	get_user_aiming(id, aimed, body);
	team1 = get_user_team(id);
	team2 = get_user_team(aimed);
	get_user_name(aimed,name, MAX_PLAYER)

	if(team1 == team2)
	{
		hp = get_user_health(aimed)
		if(team1 == 1)
			set_hudmessage(255, 255, 0, -1.0, 0.2, 1, 6.0, 12.0, 0.0, 0.0, 1) 
		else if(team1 == 2)
			set_hudmessage(0, 255, 255, -1.0, 0.2, 1, 6.0, 12.0, 0.0, 0.0, 1) 
			
		show_hudmessage(id, "%s - HP: %i", name, hp) 
	}
	else 
	{
		if(team2 == 1)
			set_hudmessage(255, 255, 0, -1.0, 0.2, 1, 6.0, 12.0, 0.0, 0.0, 1) 
		else if(team2 == 2)
			set_hudmessage(0, 255, 255, -1.0, 0.2, 1, 6.0, 12.0, 0.0, 0.0, 1) 
		
		show_hudmessage(id, "%s", name)
	}
}
*/

/*
public porro(id)
{
	new ent_porro = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetModel, ent_porro, "models/Sj-Pro/Accesorios/Sj-Pro_1.mdl");
	set_pev(ent_porro, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(ent_porro, pev_aiment, id);  
	return PLUGIN_HANDLED
}

public noporro(id)
{
	remove_entity(ent_porro)
	return PLUGIN_HANDLED
}


public diablo(id)
{
	ent_diablo = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetModel, ent_diablo, "models/Sj-Pro_Models/diablo.mdl");
	set_pev(ent_diablo, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(ent_diablo, pev_aiment, id); 
	return PLUGIN_HANDLED	
}

public angel(id)
{
	ent_angel = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetModel, ent_angel, "models/Sj-Pro_Models/angel.mdl");
	set_pev(ent_angel, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(ent_angel, pev_aiment, id);  
	return PLUGIN_HANDLED
}

public gorra(id)
{
	ent_gorra = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetModel, ent_gorra, "models/Sj-Pro_Models/gorra.mdl");
	set_pev(ent_gorra, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(ent_gorra, pev_aiment, id);  
	return PLUGIN_HANDLED
}



public capucha(id)
{
	ent_capucha = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetModel, ent_capucha, "models/Sj-Pro_Models/capucha.mdl");
	set_pev(ent_capucha, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(ent_capucha, pev_aiment, id);  
	return PLUGIN_HANDLED
}

public nogorra(id)
{
	remove_entity(ent_gorra)
	return PLUGIN_HANDLED
}

public nodiablo(id)
{
	remove_entity(ent_diablo)
	return PLUGIN_HANDLED
}

public noangel(id)
{
	remove_entity(ent_angel)
	return PLUGIN_HANDLED
}



public nocapucha(id)
{
	remove_entity(ent_capucha)
	return PLUGIN_HANDLED
}

*/


Offside(id)
{
	new RestUser = 0, alive = 0, teamoff
	new origin_x[3], PossCancha[MAX_PLAYER + 1][3]

	for(new x = 1; x <= MAX_PLAYER; x++)
	{		
		if(is_user_alive(x) && !is_user_bot(x) && !is_user_hltv(x) && is_user_connected(x) && !user_is_keeper[x] && !soy_spec[x])
		{	
			alive++
			get_user_origin(x, origin_x)
			teamoff = get_user_team(x)
			PossCancha[x - RestUser][0] = x
			PossCancha[x - RestUser][1] = origin_x[0]
			PossCancha[x - RestUser][2] = teamoff
		}
		else 
			RestUser++
	}
	
	if(alive >= 3)
	{
		new pateoteam = get_user_team(ballowner)
		new auxiliar0, auxiliar1, auxiliar2, finish
		if(pateoteam == 1)
		{
			do
			{
				finish = 0
				for(new x = 1; x <= alive; x++)
				{
					if(PossCancha[x][1] > PossCancha[x + 1][1])
					{
						auxiliar0 = PossCancha[x][0]
						PossCancha[x][0] = PossCancha[x + 1][0]
						PossCancha[x + 1][0] = auxiliar0						
					
						auxiliar1 = PossCancha[x][1]
						PossCancha[x][1] = PossCancha[x + 1][1]
						PossCancha[x + 1][1] = auxiliar1
						
						auxiliar2 = PossCancha[x][2]
						PossCancha[x][2] = PossCancha[x + 1][2]
						PossCancha[x + 1][2] = auxiliar2						
					
						finish = 1
					}
				}
			}
			while(finish)
		}
		else if(pateoteam == 2)
		{
			do
			{
				finish = 0
				for(new x = 1; x <= alive; x++)
				{
					if(PossCancha[x][1] < PossCancha[x + 1][1])
					{
						auxiliar0 = PossCancha[x][0]
						PossCancha[x][0] = PossCancha[x + 1][0]
						PossCancha[x + 1][0] = auxiliar0						
					
						auxiliar1 = PossCancha[x][1]
						PossCancha[x][1] = PossCancha[x + 1][1]
						PossCancha[x + 1][1] = auxiliar1
						
						auxiliar2 = PossCancha[x][2]
						PossCancha[x][2] = PossCancha[x + 1][2]
						PossCancha[x + 1][2] = auxiliar2						
					
						finish = 1
					}
				}
			}
			while(finish)
		}
		
		if(pateoteam != PossCancha[1][2])
			return false;	
			
		if(id == PossCancha[1][0])
			return false;
			
		if((pateoteam == PossCancha[1][2]) && (pateoteam != PossCancha[2][2]))
		{
			SentenceOffside(PossCancha[1][0], PossCancha[2][0], PossCancha[1][1], PossCancha[2][1])		
		}
		else if((pateoteam == PossCancha[1][2]) && (pateoteam == PossCancha[2][2]) && (pateoteam != PossCancha[3][2]))
		{
			SentenceOffside(PossCancha[1][0], PossCancha[3][0], PossCancha[1][1], PossCancha[3][1])			
		}
		else if((pateoteam == PossCancha[1][2]) && (pateoteam == PossCancha[2][2]) && (pateoteam == PossCancha[3][2]) && (pateoteam != PossCancha[4][2]))
		{
			SentenceOffside(PossCancha[1][0], PossCancha[4][0], PossCancha[1][1], PossCancha[4][1])			
		}
		else		
			return false;
	}
	else 
		return false;
		
	return true;
}

public SentenceOffside(idoff, idhabil, originoff, originhabil)
{
	off_1 = idoff
	is_offside[idoff] = true
	Paralize(idoff)
	create_line_off_red(originoff)	
	create_line_off_green(originhabil)	
	PrintOffside(idoff, idhabil)	
	AvisoOffside(idoff)	
}

public PrintOffside(idoff, idhabil)
{	
	new name_off1[MAX_PLAYER + 1],name_off2[MAX_PLAYER + 1]
	get_user_name(idoff,name_off1, MAX_PLAYER)
	get_user_name(idhabil,name_off2, MAX_PLAYER)

	if(idhabil)
		ColorChat(0,YELLOW,"^x04%s^x01 esta adelantado por ^x04%s^x01",name_off1,name_off2)
	else
		ColorChat(0,YELLOW,"^x04%s^x01 esta adelantado",name_off1)
}

public niOffSide()
{
	if(off_1 > 0)
	{
		if(is_offside[off_1])
		{
			is_offside[off_1] = false	
			remove_foul(off_1)		
		}
	}	
}


			
remove_foul(id)
{
//	set_pev(id, pev_solid, SOLID_BBOX);
	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,25) 
	set_user_godmode(id, 0) 
	
	// restore normal gravity

	set_pev(id, pev_gravity, 1.0)
	
	// clear screen fade
	message_begin(MSG_ONE, g_msgScreenFade, _, id);
	write_short(0);	// duration
	write_short(0);	// hold time
	write_short(0);	// flags
	write_byte(0);	// red
	write_byte(0);	// green
	write_byte(0);	// blue
	write_byte(0);	// alpha
	message_end();
	
	return PLUGIN_CONTINUE;
}



/**************************************************************

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR) 
    set_task(1.0, "getAimed", 0, "", 0, "b");
}

public getAimed(id) {
    if(!is_user_alive(id)) {
        return PLUGIN_HANDLED;
    }
    
    new ent, body;
    get_user_aiming(id, ent, body);
    
    if(is_valid_ent(ent)) {
        new classname[50];
        entity_get_string(ent,EV_SZ_classname,classname,49);
        
        if(equal(classname,"player")) {
            if(!is_user_alive(ent)) {
                return PLUGIN_HANDLED;
            }
        
            showPlayerHud(id, ent);
        }
    }
    
    return PLUGIN_CONTINUE;
}

public showPlayerHud(id, ent) {
    new name[50];
    
    get_user_name(ent, name, 49);
    set_hudmessage(0, 100, 200, -1.0, 0.35, 0, 4.0, 0.9, 0.1, 0.2, 2);
    show_hudmessage(id, "You are looking at %s", name);
}

*///////////////////////////////////////////////////////////////


public BorrarSistemExp()
{
	new datadir[128]
	new jivault[256]
	get_datadir(datadir, 127 )
	format(jivault, 255, "%s/vault/Sj-Pro_Exp.vault",datadir)
	if(file_exists(jivault))
		delete_file(jivault);
	
	return PLUGIN_HANDLED
}

public SavePlayerExp(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	nameVault = nvault_open(VAULTNAMEEXP);		

	new playername[MAX_PLAYER + 1];
	get_user_name(id, playername, MAX_PLAYER);

	new vaultkey[64], vaultdata[64];	
	new exp_goles, exp_robos, exp_asis, exp_encontra, exp_disarm, exp_bk, upgrade1, upgrade2, upgrade3, upgrade4, upgrade5, TotalExp;
	
	exp_goles = MadeRecord[id][GOAL];
	exp_robos = MadeRecord[id][STEAL];
	exp_asis = MadeRecord[id][ASSIST];
	exp_encontra = MadeRecord[id][ENCONTRA]
	exp_disarm = MadeRecord[id][DISARMS]
	exp_bk = MadeRecord[id][KILL]
	
	upgrade1 = PlayerUpgrades[id][1]
	upgrade2 = PlayerUpgrades[id][2]
	upgrade3 = PlayerUpgrades[id][3] 
	upgrade4 = PlayerUpgrades[id][4]
	upgrade5 = PlayerUpgrades[id][5]

	TotalExp = g_Experience[id]

	format(vaultkey, 63, "^"%s^"", playername);
	format(vaultdata, 63, "%i %i %i %i %i %i %i %i %i %i %i %i", exp_goles, exp_robos, exp_asis, exp_encontra, exp_disarm, exp_bk, upgrade1, upgrade2, upgrade3, upgrade4, upgrade5, TotalExp)
	nvault_set(nameVault, vaultkey, vaultdata);
	
	nvault_close(nameVault);

	return PLUGIN_CONTINUE;
}

public LoadPlayerExp(id)
{
	nameVault = nvault_open(VAULTNAMEEXP);
		
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	new playername[MAX_PLAYER + 1];
	get_user_name(id, playername, MAX_PLAYER);

	new vaultkey[64], vaultdata[64], timestamp;

	new ex_goles[MAX_PLAYER + 1], ex_robos[MAX_PLAYER + 1], ex_asis[MAX_PLAYER + 1], ex_encontra[MAX_PLAYER + 1], ex_disarm[MAX_PLAYER + 1], ex_bk[MAX_PLAYER + 1], upgrad1[MAX_PLAYER + 1], upgrad2[MAX_PLAYER + 1], upgrad3[MAX_PLAYER + 1], upgrad4[MAX_PLAYER + 1], upgrad5[MAX_PLAYER + 1], TotalEx[MAX_PLAYER + 1];
	new exp_goles, exp_robos, exp_asis, exp_encontra, exp_disarm, exp_bk, upgrade1, upgrade2, upgrade3, upgrade4, upgrade5, TotalExp;

	format(vaultkey, 63, "^"%s^"", playername);
	nvault_lookup(nameVault, vaultkey, vaultdata, 1500, timestamp)
	
	parse(vaultdata,ex_goles, MAX_PLAYER, ex_robos, MAX_PLAYER, ex_asis, MAX_PLAYER, ex_encontra, MAX_PLAYER, ex_disarm, MAX_PLAYER, ex_bk, MAX_PLAYER, upgrad1, MAX_PLAYER, upgrad2, MAX_PLAYER, upgrad3, MAX_PLAYER, upgrad4, MAX_PLAYER, upgrad5, MAX_PLAYER, TotalEx, MAX_PLAYER);
	exp_goles = str_to_num(ex_goles);
	exp_robos = str_to_num(ex_robos);
	exp_asis = str_to_num(ex_asis);    
	exp_encontra = str_to_num(ex_encontra);
	exp_disarm = str_to_num(ex_disarm);
	exp_bk = str_to_num(ex_bk);
	upgrade1 = str_to_num(upgrad1);
	upgrade2 = str_to_num(upgrad2);
	upgrade3 = str_to_num(upgrad3);
	upgrade4 = str_to_num(upgrad4);
	upgrade5 = str_to_num(upgrad5);
	TotalExp = str_to_num(TotalEx);		
	
	MadeRecord[id][GOAL] = exp_goles
	MadeRecord[id][STEAL] = exp_robos 
	MadeRecord[id][ASSIST] = exp_asis 
	MadeRecord[id][ENCONTRA] = exp_encontra 
	MadeRecord[id][DISARMS] = exp_disarm 
	MadeRecord[id][KILL] = exp_bk 
	
	PlayerUpgrades[id][1] = upgrade1 
	PlayerUpgrades[id][2] = upgrade2 
	PlayerUpgrades[id][3] = upgrade3 
	PlayerUpgrades[id][4] = upgrade4 
	PlayerUpgrades[id][5] = upgrade5 
	
	g_Experience[id] = TotalExp 
		
	ColorChat(id, GREY, "[Sj-Pro]^x04 Recuperaste todos tus logros")
		
	nvault_close(nameVault);	
	return PLUGIN_CONTINUE;
}

/*
public GuardarExp()
{
	nameVault = nvault_open(VAULTNAMEEXP);
	new playername[MAX_PLAYER + 1];
	new vaultkey[64], vaultdata[64];	
	new exp_goles, exp_robos, exp_asis, exp_encontra, exp_disarm, exp_bk, upgrade1, upgrade2, upgrade3, upgrade4, upgrade5, TotalExp;
	
	for(new x = 1; x <= MAX_PLAYER ; x++)
	{
		if(!is_user_connected(x))
		{	
			get_user_name(x, playername, MAX_PLAYER);
			
			exp_goles = MadeRecord[x][GOAL];
			exp_robos = MadeRecord[x][STEAL];
			exp_asis = MadeRecord[x][ASSIST];
			exp_encontra = MadeRecord[x][ENCONTRA]
			exp_disarm = MadeRecord[x][DISARMS]
			exp_bk = MadeRecord[x][KILL]
			
			upgrade1 = PlayerUpgrades[x][1]
			upgrade2 = PlayerUpgrades[x][2]
			upgrade3 = PlayerUpgrades[x][3]
			upgrade4 = PlayerUpgrades[x][4]
			upgrade5 = PlayerUpgrades[x][5]
			
			TotalExp = g_Experience[x]
			
			format(vaultkey, 63, "%s", playername);
			format(vaultdata, 63, "%i %i %i %i %i %i %i %i %i %i %i %i", exp_goles, exp_robos, exp_asis, exp_encontra, exp_disarm, exp_bk, upgrade1, upgrade2, upgrade3, upgrade4, upgrade5, TotalExp)
			nvault_set(nameVault, vaultkey,vaultdata);
		}
	}
	nvault_close(nameVault);
	
	return PLUGIN_HANDLED;
}
*/

public PossSpawnSjPro()
{
	if (file_exists(SpawnSjPro))
	{
		new ent_T, ent_CT
		new Data[128], len, line = 0
		new team[8], p_origin[3][8], p_angles[3][8]
		new Float:origin[3], Float:angles[3]
		
		while((line = read_file(SpawnSjPro, line, Data, 127, len)) != 0 ) 
		{
			if (strlen(Data)<2) continue
			parse(Data, team,7, p_origin[0],7, p_origin[1],7, p_origin[2],7, p_angles[0],7, p_angles[1],7, p_angles[2],7)
         
			origin[0] = str_to_float(p_origin[0]); origin[1] = str_to_float(p_origin[1]); origin[2] = str_to_float(p_origin[2]);
			angles[0] = str_to_float(p_angles[0]); angles[1] = str_to_float(p_angles[1]); angles[2] = str_to_float(p_angles[2]);
			if (equali(team,"T"))
			{
				ent_T = find_ent_by_class(ent_T, "info_player_deathmatch")
				if (ent_T>0)
				{
					entity_set_int(ent_T,EV_INT_iuser1,1) 
					entity_set_origin(ent_T,origin)
					entity_set_vector(ent_T, EV_VEC_angles, angles)
				}
			}
			else if (equali(team,"CT"))
			{	
				ent_CT = find_ent_by_class(ent_CT, "info_player_start")
				if (ent_CT>0)
				{
					entity_set_int(ent_CT,EV_INT_iuser1,1)
					entity_set_origin(ent_CT,origin)
					entity_set_vector(ent_CT, EV_VEC_angles, angles)
				}
			}
		}
		return 1
	}
	return 0
}

SavePlayerRank(id)
{
	if(!is_user_connected(id))
		return false;
		
	rankVault = nvault_open(VAULTNAMERANK);
	topVault = nvault_open(VAULTNAMETOP);

	new playername[MAX_PLAYER + 1], temppw[MAX_PLAYER + 1]

	new vaultkey[64], vaultdata[64];	
	new temppoints[MAX_PLAYER + 1], tempgoles[MAX_PLAYER + 1], temprobos[MAX_PLAYER + 1], tempasis[MAX_PLAYER + 1], tempencontra[MAX_PLAYER + 1], tempdisarm[MAX_PLAYER + 1], tempkill[MAX_PLAYER + 1], temptekill[MAX_PLAYER + 1], tempterobos[MAX_PLAYER + 1], temptedisarm[MAX_PLAYER + 1], temprankis[MAX_PLAYER + 1];
	new rank_points, rank_goles, rank_robos, rank_asis, rank_encontra, rank_disarm, rank_kill, rank_tekill, rank_terobo , rank_tedisarm, rank_rank;
	new timestamp
	
	get_user_name(id, playername, MAX_PLAYER);

	format(vaultkey, 63, "^"%s^"", playername);
	if(nvault_lookup(rankVault, vaultkey, vaultdata, 1500, timestamp))
	{
		parse(vaultdata, temppw, MAX_PLAYER, temppoints, MAX_PLAYER, tempgoles, MAX_PLAYER, temprobos, MAX_PLAYER, tempasis, MAX_PLAYER, tempencontra, MAX_PLAYER, tempdisarm, MAX_PLAYER, tempkill, MAX_PLAYER, temptekill, MAX_PLAYER, tempterobos, MAX_PLAYER, temptedisarm, MAX_PLAYER, temprankis, MAX_PLAYER);
	//	ColorChat(id, GREEN, "TEST: temppw del saverank es: %s", temppw)
		rank_rank = str_to_num(temprankis);
		rank_points = Pro_Goal[id] * ConfigPro[21] + Pro_Steal[id] * ConfigPro[23] + Pro_Asis[id] * ConfigPro[25] + Pro_Disarm[id] * ConfigPro[28] + Pro_Kill[id] * ConfigPro[26] + Pro_Contra[id] * ConfigPro[22] + Pro_teSteal[id] * ConfigPro[24] + Pro_teKill[id] * ConfigPro[27] + Pro_teDisarm[id] * ConfigPro[29]
		rank_goles =  Pro_Goal[id];
		rank_robos = Pro_Steal[id];
		rank_asis = Pro_Asis[id];
		rank_encontra = Pro_Contra[id];
		rank_disarm = Pro_Disarm[id];
		rank_kill = Pro_Kill[id];
		rank_tekill = Pro_teKill[id];
		rank_terobo = Pro_teSteal[id];
		rank_tedisarm = Pro_teDisarm[id];		
	}
	else
		return false;
			
	format(vaultdata, 63, "%s %i %i %i %i %i %i %i %i %i %i %i", temppw, rank_points, rank_goles, rank_robos, rank_asis, rank_encontra, rank_disarm, rank_kill, rank_tekill, rank_terobo, rank_tedisarm, rank_rank)
	nvault_set(rankVault, vaultkey, vaultdata);
	
	return true;
}

VerificarPossUP(id)
{
	if(!UserPassword[id])
		return false;
		
	if(!SavePlayerRank(id))
	{
		nvault_close(rankVault);
		nvault_close(topVault);
		return false;
	}

	new P_pw[MAX_PLAYER + 1], P_points[MAX_PLAYER + 1], P_goles[MAX_PLAYER + 1], P_robos[MAX_PLAYER + 1], P_asis[MAX_PLAYER + 1], P_encontra[MAX_PLAYER + 1], P_disarm[MAX_PLAYER + 1], P_kill[MAX_PLAYER + 1], P_tekill[MAX_PLAYER + 1], P_terobos[MAX_PLAYER + 1], P_tedisarm[MAX_PLAYER + 1], P_rank[MAX_PLAYER + 1];
	new C_pw[MAX_PLAYER + 1], C_points[MAX_PLAYER + 1], C_goles[MAX_PLAYER + 1], C_robos[MAX_PLAYER + 1], C_asis[MAX_PLAYER + 1], C_encontra[MAX_PLAYER + 1], C_disarm[MAX_PLAYER + 1], C_kill[MAX_PLAYER + 1], C_tekill[MAX_PLAYER + 1], C_terobos[MAX_PLAYER + 1], C_tedisarm[MAX_PLAYER + 1], C_rank[MAX_PLAYER + 1];
	new Pkey[64], Ckey[64], Pdata[64], Cdata[64], timestamp;
	new Ppoint, Cpoint, Crank, Prank;
	new Pname[MAX_PLAYER + 1], Cname[MAX_PLAYER + 1];
	new tempPrank;
	
	get_user_name(id, Pname, MAX_PLAYER);
	format(Pkey, 63, "^"%s^"", Pname);
	
	for(new x = 1; x <= TotalRank; x++)
	{
		if(nvault_lookup(rankVault, Pkey, Pdata, 1500, timestamp))
		{
			parse(Pdata, P_pw, MAX_PLAYER, P_points, MAX_PLAYER, P_goles, MAX_PLAYER, P_robos, MAX_PLAYER, P_asis, MAX_PLAYER, P_encontra, MAX_PLAYER, P_disarm, MAX_PLAYER, P_kill, MAX_PLAYER, P_tekill, MAX_PLAYER, P_terobos, MAX_PLAYER, P_tedisarm, MAX_PLAYER, P_rank, MAX_PLAYER);
			Ppoint = str_to_num(P_points)
			Prank = str_to_num(P_rank)
			
			if(Prank > 1 && Prank <= TotalRank)
			{
				tempPrank = Prank - 1			
				format(Ckey, 63, "%i", tempPrank);
				if(nvault_lookup(topVault, Ckey, Cdata, 1500, timestamp))
				{
					parse(Cdata, Cname, MAX_PLAYER)
					format(Ckey, 63, "^"%s^"", Cname);
					
					if(nvault_lookup(rankVault, Ckey, Cdata, 1500, timestamp))
					{
						parse(Cdata, C_pw, MAX_PLAYER, C_points, MAX_PLAYER, C_goles, MAX_PLAYER, C_robos, MAX_PLAYER, C_asis, MAX_PLAYER, C_encontra, MAX_PLAYER, C_disarm, MAX_PLAYER, C_kill, MAX_PLAYER, C_tekill, MAX_PLAYER, C_terobos, MAX_PLAYER, C_tedisarm, MAX_PLAYER, C_rank, MAX_PLAYER);
						Cpoint = str_to_num(C_points)
						Crank = str_to_num(C_rank)

						if(Crank >= 1 && Crank <= TotalRank)
						{							
							if(Ppoint > Cpoint)
							{	
						//		ColorChat(id, GREEN, "TEST: rank_pw del Cdata es: %s", C_pw)
						//		ColorChat(id, GREEN, "TEST: rank_pw del Pdata es: %s", P_pw)
								format(Cdata, 63, "%s %i %i %i %i %i %i %i %i %i %i %i", C_pw, Cpoint, str_to_num(C_goles), str_to_num(C_robos), str_to_num(C_asis), str_to_num(C_encontra), str_to_num(C_disarm), str_to_num(C_kill), str_to_num(C_tekill), str_to_num(C_terobos), str_to_num(C_tedisarm), Prank)
								format(Pdata, 63, "%s %i %i %i %i %i %i %i %i %i %i %i", P_pw, Ppoint, str_to_num(P_goles), str_to_num(P_robos), str_to_num(P_asis), str_to_num(P_encontra), str_to_num(P_disarm), str_to_num(P_kill), str_to_num(P_tekill), str_to_num(P_terobos), str_to_num(P_tedisarm), Crank)
								nvault_set(rankVault, Ckey, Cdata);
								nvault_set(rankVault, Pkey, Pdata);
								new keytop[64]
								format(keytop, 63, "%i", Crank);
								nvault_set(topVault, keytop, Pkey);
								format(keytop, 63, "%i", Prank);
								nvault_set(topVault, keytop, Ckey);								
							}
							else
							{
								Pro_Rank[id] = Prank;
								break;				
							}
						}
						else
						{
							Pro_Rank[id] = Prank;
							break;				
						}
					}
					else
					{
						Pro_Rank[id] = Prank;
						break;
					}						
				}
				else
				{
					Pro_Rank[id] = Prank;
					break;
				}	
			}		
			else
			{
				Pro_Rank[id] = Prank;
				break;
			}		
		}
		else
			break;			
	}
	
	for(new x = 1; x <= TotalRank; x++)
	{
		if(nvault_lookup(rankVault, Pkey, Pdata, 1500, timestamp))
		{
			parse(Pdata, P_pw, MAX_PLAYER, P_points, MAX_PLAYER, P_goles, MAX_PLAYER, P_robos, MAX_PLAYER, P_asis, MAX_PLAYER, P_encontra, MAX_PLAYER, P_disarm, MAX_PLAYER, P_kill, MAX_PLAYER, P_tekill, MAX_PLAYER, P_terobos, MAX_PLAYER, P_tedisarm, MAX_PLAYER, P_rank, MAX_PLAYER);
			Ppoint = str_to_num(P_points)
			Prank = str_to_num(P_rank)
			
			if(Prank >= 1 && Prank < TotalRank)
			{
				tempPrank = Prank + 1
				
				format(Ckey, 63, "%i", tempPrank);
				if(nvault_lookup(topVault, Ckey, Cdata, 1500, timestamp))
				{
					parse(Cdata, Cname, MAX_PLAYER)
					format(Ckey, 63, "^"%s^"", Cname);
					
					if(nvault_lookup(rankVault, Ckey, Cdata, 1500, timestamp))
					{
						parse(Cdata, C_pw, MAX_PLAYER, C_points, MAX_PLAYER, C_goles, MAX_PLAYER, C_robos, MAX_PLAYER, C_asis, MAX_PLAYER, C_encontra, MAX_PLAYER, C_disarm, MAX_PLAYER, C_kill, MAX_PLAYER, C_tekill, MAX_PLAYER, C_terobos, MAX_PLAYER, C_tedisarm, MAX_PLAYER, C_rank, MAX_PLAYER);
						Cpoint = str_to_num(C_points)
						Crank = str_to_num(C_rank)
						
						if(Crank >= 1 && Crank <= TotalRank)
						{											
							if(Ppoint < Cpoint)
							{	
						//		ColorChat(id, GREEN, "TEST: rank_pw del Cdata es: %s", C_pw)
						//		ColorChat(id, GREEN, "TEST: rank_pw del Pdata es: %s", P_pw)
								format(Cdata, 63, "%s %i %i %i %i %i %i %i %i %i %i %i", C_pw, Cpoint, str_to_num(C_goles), str_to_num(C_robos), str_to_num(C_asis), str_to_num(C_encontra), str_to_num(C_disarm), str_to_num(C_kill), str_to_num(C_tekill), str_to_num(C_terobos), str_to_num(C_tedisarm), Prank)
								format(Pdata, 63, "%s %i %i %i %i %i %i %i %i %i %i %i", P_pw, Ppoint, str_to_num(P_goles), str_to_num(P_robos), str_to_num(P_asis), str_to_num(P_encontra), str_to_num(P_disarm), str_to_num(P_kill), str_to_num(P_tekill), str_to_num(P_terobos), str_to_num(P_tedisarm), Crank)
								nvault_set(rankVault, Ckey, Cdata);
								nvault_set(rankVault, Pkey, Pdata);
								new keytop[64]
								format(keytop, 63, "%i", Crank)
								nvault_set(topVault, keytop, Pkey);
								format(keytop, 63, "%i", Prank)
								nvault_set(topVault, keytop, Ckey);							
							}	
							else 
							{
								Pro_Rank[id] = Prank;
								break;					
							}							
						}
						else 
						{
							Pro_Rank[id] = Prank;
							break;					
						}
					}
					else 
					{
						Pro_Rank[id] = Prank;
						break;					
					}						
				}
				else 
				{
					Pro_Rank[id] = Prank;
					break;					
				}	
			}
			else 
			{
				Pro_Rank[id] = Prank;
				break;				
			}					
		}
		else
			break;
	}
	
	nvault_close(rankVault);
	nvault_close(topVault);		
	
	return true	
}

/*	
public LoadPlayerRank(id)
{
		
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	rankVault = nvault_open(VAULTNAMERANK);
	topVault = nvault_open(VAULTNAMETOP);

	new playername[MAX_PLAYER + 1];
	
	new vaultkey[64], vaultdata[64], timestamp;

	new rank_points[MAX_PLAYER + 1], rank_goles[MAX_PLAYER + 1], rank_robos[MAX_PLAYER + 1], rank_asis[MAX_PLAYER + 1], rank_encontra[MAX_PLAYER + 1], rank_disarm[MAX_PLAYER + 1], rank_kill[MAX_PLAYER + 1], rank_tekill[MAX_PLAYER + 1], rank_terobos[MAX_PLAYER + 1], rank_tedisarm[MAX_PLAYER + 1], rank_rank[MAX_PLAYER + 1];
	
	get_user_name(id, playername, MAX_PLAYER);

	format(vaultkey, 63, "^"%s^"", playername);
	if(nvault_lookup(rankVault, vaultkey, vaultdata, 1500, timestamp))
	{
		parse(vaultdata, rank_points, MAX_PLAYER, rank_goles, MAX_PLAYER, rank_robos, MAX_PLAYER, rank_asis, MAX_PLAYER, rank_encontra, MAX_PLAYER, rank_disarm, MAX_PLAYER, rank_kill, MAX_PLAYER, rank_tekill, MAX_PLAYER, rank_terobos, MAX_PLAYER, rank_tedisarm, MAX_PLAYER, rank_rank, MAX_PLAYER);
		Pro_Point[id] = str_to_num(rank_points);
		Pro_Goal[id] = str_to_num(rank_goles);
		Pro_Steal[id] = str_to_num(rank_robos);
		Pro_Asis[id] = str_to_num(rank_asis);    
		Pro_Contra[id] = str_to_num(rank_encontra);
		Pro_Disarm[id] = str_to_num(rank_disarm);
		Pro_Kill[id] = str_to_num(rank_kill);
		Pro_teKill[id] = str_to_num(rank_tekill);
		Pro_teSteal[id] = str_to_num(rank_terobos);
		Pro_teDisarm[id] = str_to_num(rank_tedisarm);	
		Pro_Rank[id] = str_to_num(rank_rank);		
	}
	else
	{	
		TotalRank += 1
		new vaultnum[64]
		format(vaultnum, 63, "%i", TotalRank);	
		format(vaultdata, 63, "0 0 0 0 0 0 0 0 0 0 %i", TotalRank)
		nvault_set(rankVault, vaultkey, vaultdata);
		nvault_set(topVault, vaultnum, vaultkey);
		nvault_set(topVault, "RankKey", vaultnum);
		
		set_task(2.0,"BienvenidoRank",id)	
	
		Pro_Point[id] = 0;
		Pro_Goal[id] = 0;
		Pro_Steal[id] = 0;
		Pro_Asis[id] = 0;
		Pro_Contra[id] = 0;
		Pro_Disarm[id] = 0;
		Pro_Kill[id] = 0;
		Pro_teKill[id] = 0;
		Pro_teSteal[id] = 0;
		Pro_teDisarm[id] = 0;
		Pro_Rank[id] = TotalRank;
	}
	nvault_close(rankVault);
	nvault_close(topVault);
	return PLUGIN_CONTINUE;
}
*/

/*
public BienvenidoRank(id)
{
	ColorChat(id,GREY,"[Sj-Pro]^x04 Nick registrado. Tu poss en el SjRank es ^x03%i", TotalRank)
}
*/

public sjrank(id)
{
	if(UserPassword[id])
		ColorChat(id,GREEN,"Tu poss en el SjRank es ^x03%i^x04 de ^x03%i^x04 con ^x03%i^x04 puntos.",Pro_Rank[id], TotalRank, Pro_Point[id])
	else
		ColorChat(id,GREY,"[Sj-Pro]^x04 No estas logueado, ingresa tu pw o create una cuenta")

	return PLUGIN_HANDLED;
}

public SjTop10(id)
{
	rankVault = nvault_open(VAULTNAMERANK);
	topVault = nvault_open(VAULTNAMETOP);
	new Playername[MAX_PLAYER + 1]
	new vaultkey[64], vaultnum[64], vaultdata[64], timestamp;
	new rank_pw[MAX_PLAYER + 1], rank_points[MAX_PLAYER + 1], rank_goles[MAX_PLAYER + 1], rank_robos[MAX_PLAYER + 1], rank_asis[MAX_PLAYER + 1], rank_encontra[MAX_PLAYER + 1], rank_disarm[MAX_PLAYER + 1], rank_kill[MAX_PLAYER + 1], rank_tekill[MAX_PLAYER + 1], rank_terobos[MAX_PLAYER + 1], rank_tedisarm[MAX_PLAYER + 1], rank_rank[MAX_PLAYER + 1];

	new motd[1501],iLen;

	//COLORES  AMARILLO <font color=#fff000> AZUL <font color=#98f5ff> ROJO <font color=#ff0000> VERDE CLARO <font color=#00ff7e>
	
	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>"); 
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Sj-Pro Top 10 ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b><U>%2s %-22.22s %8s %6s %6s %6s %6s %6s %6s %6s %6s %12s</U></b>^n", "#", "Nick", "Puntos", "Goles", "Robos", "Regalos", "Asist", "En contra", "Disarms", "Disarm rv", "Bkills", "Bkills rv");
	
	for(new xtop = 1; xtop <= 10; xtop++)
	{
		format(vaultnum, 63, "%i", xtop);
		if(nvault_lookup(topVault, vaultnum, vaultdata, 1500, timestamp))
		{			
			parse(vaultdata,Playername, MAX_PLAYER)
			format(vaultkey, 63, "^"%s^"", Playername);
			nvault_lookup(rankVault, vaultkey, vaultdata, 1500, timestamp)
			
			if(containi ( Playername, "<" ) != -1 )
				replace( Playername, MAX_PLAYER, "<", "" )
	
			parse(vaultdata, rank_pw, MAX_PLAYER, rank_points, MAX_PLAYER, rank_goles, MAX_PLAYER, rank_robos, MAX_PLAYER, rank_asis, MAX_PLAYER, rank_encontra, MAX_PLAYER, rank_disarm, MAX_PLAYER, rank_kill, MAX_PLAYER, rank_tekill, MAX_PLAYER, rank_terobos, MAX_PLAYER, rank_tedisarm, MAX_PLAYER, rank_rank, MAX_PLAYER);			
			iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%2i %-22.22s %6i %7i %6i %8i %5i %10i %7i %9i %6i %9i^n", xtop, Playername, str_to_num(rank_points), str_to_num(rank_goles), str_to_num(rank_robos), str_to_num(rank_terobos), str_to_num(rank_asis), str_to_num(rank_encontra), str_to_num(rank_disarm), str_to_num(rank_tedisarm), str_to_num(rank_kill), str_to_num(rank_tekill))
		}
		else
		{		
			iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%2i %-22.22s %6i %7i %6i %8i %5i %10i %7i %9i %6i %9i^n", xtop, "-- No existe --", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		}
	}
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</b></center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><b>MSN: leo1-7@hotmail.com</b></center>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><b>- Argentina -</b></center>");
	show_motd(id,motd, "Sj-Pro Top 10");
	nvault_close(rankVault);
	nvault_close(topVault);
	
	return PLUGIN_HANDLED;
}



public allrecords(id)
{	
	new motd[1501],iLen;

	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#fff000><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Todos los records ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %8s %7s %6s %6s %6s %6s %6s^n", "Nick", "Goles", "Robos", "Asist", "En contra", "Disarms", "Bkills", "Lejano");
	for(new x=1; x<=maxplayers; x++) 
	{
		if(is_user_connected(x))
		{
			new elname[MAX_PLAYER + 1] 
			get_user_name(x, elname, MAX_PLAYER) 
			if(containi (elname, "<" ) != -1 )
				replace(elname, MAX_PLAYER, "<", "" )	
				
			iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %5i %8i %7i %10i %7i %6i %6i^n", elname, MadeRecord[x][1], MadeRecord[x][3], MadeRecord[x][2], MadeRecord[x][4], MadeRecord[x][6], MadeRecord[x][7], MadeRecord[x][5]);			
		}
	}
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><b><center>by L//</center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Allrecords by L//");
	
	return PLUGIN_HANDLED
}

public sjmenuhelp(id)
{
	new helpmenu = menu_create("Info Sj-Pro", "InfoMenu")
	
	menu_additem(helpmenu, "General", "1",0)
	menu_additem(helpmenu, "Moves & Levels", "2",0)
	menu_additem(helpmenu, "Rank Sj-Pro", "3",0)
	menu_additem(helpmenu, "Registro Rank", "4",0)
	menu_additem(helpmenu, "Comandos","5",0)
	menu_additem(helpmenu, "Info Areas","6",0)
	menu_addblank(helpmenu,1)
	menu_display(id, helpmenu, 0)	

	return PLUGIN_HANDLED
	
}


public InfoMenu(id, menu, item)
{	
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED

	if( item == 0)	
		displayhelp(id);

	if( item == 1)	
		displaymovements(id);
	
	if( item == 2)	
		displaytop10(id);
	
	if( item == 3)
		displayregistro(id);
	
	if( item == 4)	
		displaycomandos(id);
	
	if( item == 5)	
		displayareas(id)

	return PLUGIN_HANDLED;
}

public displaytop10(id)
{
	new motd[1501],iLen;

	//COLORES  AMARILLO <font color=#fff000> AZUL <font color=#98f5ff> ROJO <font color=#ff0000> VERDE CLARO <font color=#00ff7e>
	
	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Info Rank Sj-Pro ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000>El rank del Sj-Pro se basa en la acumulacion de puntos,^n") 
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"por lo que cada player debera ir acumulandolos a medida que juega cerrados.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Como dije anteriormente, un player podra acumular puntos a partir de que^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"un adm ejecute la cfg de ^"vale^", y a su ves alla 10 players de ct o tt para que el rank se active.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"El metodo para calcular los puntos de cada player es el siguiente:^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#ff0000>%10s %2s %6s^n^n", "Accion","=","Puntos");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Gol","=",5)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Robo","=",2)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Regalo","=",-2)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Asis","=",4)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Disarm","=",3)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Te Disarm","=",-3)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Bkill","=",3)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n", "Te Bkill","=",-3)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%10s</b> %2s %6i^n^n", "En contra","=",-10)
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000>La cantidad de puntos total sera la sumatoria de todas las acciones.^n")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Si el player posee un rank menor o igual a 10, aparecera en el Sj-Pro top 10.^n")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Tu poss en el rank se actualiza automaticamente al hacer algun logro punto.^n^n")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>NOTA</b>: Si un player se desconecta en medio de un cerrado y el total de players^n")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"dentro de la cancha se menor a 9, este se desactivara automaticamente.^n")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Si luego ingresa un player y el total de los mismos es mayor a 9, se activara nuevamente.^n")
	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</b></center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><b>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Info Rank Sj-Pro");
	
	return PLUGIN_HANDLED	
}

public displayregistro(id)
{
	new motd[1501],iLen;

	//COLORES  AMARILLO <font color=#fff000> AZUL <font color=#98f5ff> ROJO <font color=#ff0000> VERDE CLARO <font color=#00ff7e>
	
	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Registro Rank ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000>Para poder rankear en el Sj-Pro, es necesario registrarse.^n") 
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Para ello debemos crear una cuenta de la siguiente manera:^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Tipea <font color=#ff0000>/menu <font color=#fff000>en say, elegir la opcion <font color=#98f5ff>Registrar Rank <font color=#fff000>e introducir la password.^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"En la base de datos se guardara tu nick y contrasenia,^nsimilar a la password de un administrador, ");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"es decir, en tu config.cfg se guardara ^nuna setinfo llamada <font color=#98f5ff>^"setinfo _sj tupassword^"^n")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000>Cuando ingreses nuevamente al server, si no tocaste tu cfg,^ntus logros se cargaran automaticamente.^n^n")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Si cambias de nick, deberas loguearte con el correspondiente nick o crearte una nueva cuenta^n")
	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</b></center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><b>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Registro Rank");
	
	return PLUGIN_HANDLED	
}

public displaycomandos(id)
{
	new motd[1501],iLen;

	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Comandos ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000>Aca una lista de todos los comandos disponibles en el Sj-Pro:^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U><b>Comandos en consola:</U></b>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U>%-22.22s</U> <U>%10s</U>^n^n", "Comando","Accion");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#ff0000>%-22.22s %10s^n", "allrecords","Muestra los records de todos los jugadores en el server")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n^n", "records","Muestra solamente tus records")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000><U><b>Comandos en say:</U></b>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U>%-22.22s</U> <U>%10s</U>^n^n", "Comando","Accion");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#ff0000>%-22.22s %10s^n", "/atajo","Podras ser el arquero del equipo")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "/noatajo","Dejas de ser el arquero del equipo")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "/aco","Te transfieres a la cabina de los spec")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "/sjrank","Visualizas tu rank")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "/sjstats","Visualizas tus estadisticas")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "/sjtop10","Visualizas el Sj-Pro top 10")
	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Info Comandos");
	
	return PLUGIN_HANDLED	
}

public displayareas(id)
{
	new motd[1501],iLen;

	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Areas ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000>El sistema de areas esta diseniado para un mejor juego.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Este evita que los players durante un cerrado no atajen de a varios.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Solamente podra ingresar al area correspondiente ^nel jugador que tipee en say /atajo, es decir, el arquero del equipo^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"A su ves, el arquero no podra sobrepasar la mitad de la cancha.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"Si la bocha esta lejos del area, ^ncualquier player podra ingresar a ella.^n");
	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Info Areas");
}

public displayhelp(id) 
{

	new msg[4094], len
	len = format(msg,4093,"<body bgcolor=#000000><font color=#98f5ff><pre>")
	len += format(msg[len],4093-len,"<center><h2>------Help de Sj-Pro------</h2></center>^n^n<body bgcolor=#000000><font color=#fff000>")
	len += format(msg[len],4093-len,"<U><h2>REGLAMENTO GENERAL:</h2></U>^n")
	len += format(msg[len],4093-len,"<UL><LI>Cualquier tipo de insulto hacia un admin será motivo de BAN.^n")
	len += format(msg[len],4093-len,"<LI>Prohibido abusar del micrófono, en caso de hacerlo le corresponderá GAG.</UL>^n^n")

	len += format(msg[len],4093-len,"<U><h2><b>REGLAMENTO EN PUBLICOS:</b></h2></U>^n")
	len += format(msg[len],4093-len,"<UL><LI>Prohibido FRAGUEAR o MATAR al oponente que no posea la pelota, en caso de hacerlo el admin determinará la acción que corresponda.^n")
	len += format(msg[len],4093-len,"<LI>Estará permitido como máximo 3 bunnys, en caso de sobrepasar el límite el admin determinará la acción que corresponda.</UL>^n^n")

	len += format(msg[len],4093-len,"<U><h2><b>REGLAMENTO EN CERRADOS:</b></h2></U>^n")
	len += format(msg[len],4093-len,"<UL><LI>El FRAG estará permitido mientras pueda estando el antifrag activo, salvo excepciones que serán determinadas por el admin.^n")
	len += format(msg[len],4093-len,"<LI>En el area chica solo podrá ingresar un player que será el arquero del equipo.^n") 
	len += format(msg[len],4093-len,"<LI>El arquero no podrá sobrepasar la mitad de la cancha.^n") 
	len += format(msg[len],4093-len,"<LI>No se podrá cambiar el arquero, salvo excepcion del adm.</UL>^n^n") 
	
	len += format(msg[len],4093-len,"<font color=#00ff7e><center><b>by L//</center>^n") 
	len += format(msg[len],4093-len,"<center>MSN: leo1-7@hotmail.com</b></center>")
	show_motd(id,msg,"Sj-Pro by L//")

}

public displaymovements(id)
{
	new motd[1501],iLen;

	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Movimientos & Levels ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000><U><h2>MOVIMIENTOS:</h2></U>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<UL><LI>Patear - E (^"+Use^").^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Comba hacia la izquierda - Z ( ^"Radio1^").^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Comba hacia la derecha - X (^"Radio2^").^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Turbo -  G (^"Drop^").^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Panel de Habilidades -  Q  (^"Lastinv^").^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Salto mayor - Ir hacia la derecha/izquierda y presionar la tecla con la que saltas.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Atrapar Balón - Solo debes chocarte con el mismo para agarrarlo.</UL>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U><h2>LEVELS:</h2></U>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<UL><LI>Stamina - Aumenta la vida^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Strength - Mayor fuerza al patear la pelota. A su vez, hace mas daño a alguien a quien se le impacte con la pelota.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Agility - Incrementa la velocidad del jugador.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Dexterity - Aumenta la posiblidad de atrapar la pelota.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>Disarm - Incrementa % de sacarle (pegandole con el cuchillo) el cuchillo o la pelota al oponente.</UL>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>Power Play</b>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<UL><LI>El POWER PLAY o juego en equipo incrementa temporalmente la AGILIDAD y la FUERZA.^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<LI>El nivel máximo de PowerPlay es 10.</UL>^n");

	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Info Moves y Levels");
}

public comandos_adm(id) 
{
	new motd[1501],iLen;

	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Help para admines ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000><U><b>CFG's:</U></b>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U>%-22.22s</U> <U>%10s</U>^n^n", "CFG","Comando");	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#00B9F6>%-22.22s %10s^n", "Público:","sj_publico");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "Cerrado:","sj_cerrado")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "Vale","sj_vale")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n^n<font color=#fff000>", "Frag","sj_fragarqueros")	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U><b>CVAR's:</U></b>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U>%-22.22s</U> <U>%10s</U>^n^n", "Accion","Cvar");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#00B9F6>%-22.22s %10s^n", "Anti-frag:","sj_frag ^"1^" ^"0^"")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "Para el poss del area:","sj_poss_areas ^"1^" ^"0^"")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "Para el limite de los arqueros:","sj_limites ^"1^" ^"0^"")	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n^n<font color=#fff000>", "Arqueros:","sj_arqueros ^"1^" ^"0^"")	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U><b>Comandos:</U></b>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U>%-22.22s</U> <U>%10s</U>^n^n", "Accion","Comando");	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#00B9F6>%-22.22s %10s^n", "Restartear partido:","amx_start")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "Full exp:","amx_exp")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n", "Full habilidades:","amx_full")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"%-22.22s %10s^n^n<font color=#fff000>", "Todos spec:","amx_spec")
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<U><b>A tener en cuenta:</U></b>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#00B9F6>Tipea ^"amx_sjmenu^" en consola o presiona la ^"/^" para visualizar el menu de admins^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Info Admins");
	
	return PLUGIN_HANDLED	
}

public clcmd_changeteam(id)
{	
	new soccermenu = menu_create("Elige el team:", "change_menu")
	
	menu_additem(soccermenu, "Terror", "1",0)
	menu_additem(soccermenu, "CT","2",0)
	menu_additem(soccermenu, "Cabina","3",0)
	menu_additem(soccermenu, "Spec","4",0)
	menu_addblank(soccermenu,1)
	menu_display(id, soccermenu, 0)		
	
	return PLUGIN_HANDLED
}


public change_menu(id, menu, item)
{	
	new team = get_user_team(id)
	if((team == 1 || team == 2) && (item == team-1))
	{
		new message[64]
		format(message, 63, "[Sj-Pro] No puedes volver a entrar al mismo equipo!")
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0, 0, 0}, id)
		write_byte(0)
		write_string(message)
		message_end()
		clcmd_changeteam(id)
		return PLUGIN_HANDLED
	}
	
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED
	}

	if( item == 0)	
	{
		show_menu_tt(id);
	}
	
	if( item == 1)	
	{
		show_menu_ct(id);
	}
	
	if( item == 2)	
	{
		spec_cabina_menu(id)
	}

	if( item == 3)	
	{
		cmdSpectatemenu(id)
	}
	
	return PLUGIN_HANDLED;
}

public show_menu_tt(id)
{

	new menucomandos = menu_create("Player...","show_menu_tt1")

	menu_additem(menucomandos, "Terror", "1", 0)
	menu_additem(menucomandos, "Leet", "2", 0)
	menu_additem(menucomandos, "Artic", "3", 0)
	menu_additem(menucomandos, "Guerrilla", "4", 0)	
	
	menu_addblank(menucomandos,1)
	menu_display(id,menucomandos,0)

}

public show_menu_tt1(id, menu, item)
{
	switch(item) 
	{
		case 0: {
					cs_set_user_team(id, CS_TEAM_T, CS_T_TERROR)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false
				}
				
		case 1: {
					cs_set_user_team(id, CS_TEAM_T, CS_T_LEET)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false
				}
				
		case 2: {
					cs_set_user_team(id, CS_TEAM_T, CS_T_ARCTIC)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false
				}
				
		case 3: {
					cs_set_user_team(id, CS_TEAM_T, CS_T_GUERILLA)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false
				}
	}
	
	return PLUGIN_HANDLED;
}

public show_menu_ct(id)
{
	new menucomandos = menu_create("Player...","show_menu_ct1")

	menu_additem(menucomandos, "Urban", "1", 0)
	menu_additem(menucomandos, "GSG9", "2", 0)
	menu_additem(menucomandos, "Sas", "3", 0)
	menu_additem(menucomandos, "Gign", "4", 0)
	
	menu_addblank(menucomandos,1)
	menu_display(id,menucomandos,0)
}

public show_menu_ct1(id, menu, item)
{	
	cmdUnKeeper(id)
	switch(item) 
	{
		case 0: {
					cs_set_user_team(id, CS_TEAM_CT, CS_CT_URBAN)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false					
				}
				
		case 1: {
					cs_set_user_team(id, CS_TEAM_CT, CS_CT_GSG9)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false					
				}
				
		case 2: {
					cs_set_user_team(id, CS_TEAM_CT, CS_CT_SAS)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false					
				}
				
		case 3: {
					cs_set_user_team(id, CS_TEAM_CT, CS_CT_GIGN)
					user_kill(id)
					cmdUnKeeper(id)
					soy_spec[id] = false					
				}
	}
	
	return PLUGIN_HANDLED;
}


public sjmenuclient(id)
{
	new helpmenu = menu_create("Menu - Player", "menuplayer")
	
	menu_additem(helpmenu, "Help", "1",0)
	menu_additem(helpmenu, "Sj-Pro Top 10", "2",0)
	menu_additem(helpmenu, "Tus estadisticas", "3",0)
	menu_additem(helpmenu, "Registrarse Rank", "4", 0)
	menu_additem(helpmenu, "Camaras", "5", 0)
	menu_addblank(helpmenu,1)
	menu_display(id, helpmenu, 0)	

	return PLUGIN_HANDLED
	
}

public menuplayer(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED
	}

	if( item == 0)	
	{
		sjmenuhelp(id);
	}

	if( item == 1)	
	{
		SjTop10(id);
	}
	
	if( item == 2)	
	{
		RankEstadisticas(id);
	}
	
	if( item == 3)
	{
		if(get_pcvar_num(CVAR_RANK))
			sjregisterrank(id);
		else
			ColorChat(id, GREY, "[Sj-Pro]^x04 Rank deshabilitado en el server")
	}
	
	if( item == 4)
	{
		chooseview(id)
	}	
	
	return PLUGIN_HANDLED;
}

public sjregisterrank(id)
{
	if(get_pcvar_num(CVAR_RANK))
	{
		if(UserPassword[id])
		{
			ColorChat(id, GREY, "[Sj-Pro]^x04 Este nick ya posee una cuenta")
			return PLUGIN_HANDLED;
		}
		client_cmd(id, "messagemode Password_rank");
	}
	return PLUGIN_HANDLED
}

public VerificarExist(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	nameVault = nvault_open(VAULTNAMEEXP);
		
	new playername[MAX_PLAYER + 1];
	get_user_name(id, playername, MAX_PLAYER);

	new vaultkey[64], vaultdata[64], timestamp;
	
	

	format(vaultkey, 63, "^"%s^"", playername);
	if(nvault_lookup(nameVault, vaultkey, vaultdata, 1500, timestamp))
	{
		new helpmenu = menu_create("¿Recuperar logros?", "menurecuperar")
		
		menu_additem(helpmenu, "Si", "1",0)
		menu_additem(helpmenu, "No, recibire exp", "2",0)
		menu_addblank(helpmenu,1)
		menu_display(id, helpmenu, 0)	
	}
	else
		LateJoinExp(id)
		
	nvault_close(nameVault)
		
	return PLUGIN_HANDLED;
}
		
public menurecuperar(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED
	}

	if( item == 0)	
	{
		LoadPlayerExp(id);
	}

	if( item == 1)	
	{
		LateJoinExp(id)
	}

	return PLUGIN_HANDLED;
}

public RankEstadisticas(id)
{	
	new motd[1501],iLen;
	new name[MAX_PLAYER + 1]
	get_user_name(id,name, MAX_PLAYER)
	
	if(containi (name, "<" ) != -1 )
		replace(name, MAX_PLAYER, "<", "" )	
	
	iLen = format(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><h2>---- Estadisticas ----</h2></center>^n^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center><b>%s</b></center>^n", name);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<font color=#fff000><b>%-22.22s</b>: %10i^n", "Puntos",Pro_Point[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Goles",Pro_Goal[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Goles en contra",Pro_Contra[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Robos",Pro_Steal[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Regalos",Pro_teSteal[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Asistencias",Pro_Asis[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Desarmes",Pro_Disarm[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Te desarmaron",Pro_teDisarm[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Ball kill",Pro_Kill[id]);
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n^n", "Te mataron con bocha",Pro_teKill[id]);
//	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<b>%-22.22s</b>: %10i^n", "Partidos jugados",Pro_Partidos[id]);		// version 5.06

	
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"^n<font color=#00ff7e><center><b>by L//</center>^n");
	iLen += format(motd[iLen], (sizeof motd - 1) - iLen,"<center>MSN: leo1-7@hotmail.com</b></center>");
	show_motd(id,motd, "Estadisticas");
	
	return PLUGIN_HANDLED
}


public join_team()
{
	new id = read_data(1);
	static user_team[MAX_PLAYER + 1];

	read_data(2, user_team, MAX_PLAYER);

	if(!is_user_connected(id))
		return 0;
		
	switch(user_team[0])
    {
		case 'C': 	{
						TeamSelect[id] = 2
						if(soy_spec[id] == true)
							soy_spec[id] = false
					}
						
		case 'T':	{
						TeamSelect[id] = 1
						if(soy_spec[id] == true)
							soy_spec[id] = false		
					}
					
		case 'S': TeamSelect[id] = 0
	}
	
	return 0;
}  

public ProcesTeam()
{
	if(ActiveJoinTeam == 1 && sj_systemrank == 0 && get_pcvar_num(CVAR_RANK))
	{
		new clase_tt = 0, clase_ct = 0, suma_player = 0;
		for(new x = 1; x <= MAX_PLAYER; x++)
		{
			if(is_user_connected(x))
			{
				switch(TeamSelect[x])
				{
					case 1: clase_tt++
					case 2: clase_ct++
				}
			}
		}
		
		suma_player = clase_tt + clase_ct	
		
		if(suma_player >= ConfigPro[31])
		{
			sj_systemrank = 1
			ColorChat(0,GREY,"[Sj-Pro]^x04 Sistema de rank habilitado")
		}
	}	
}

/*
public LoadAllPlayerRank()
{
	for(new x = 1; x <= MAX_PLAYER; x++)
	{
		if(is_user_connected(x))
		{
			LoadPlayerRank(x)
		}
	}	
}
*/

public lConfig()
{
	new gSJConfig[128]
	new configDir[128]
	get_configsdir(configDir,127)
	format(gSJConfig,127,"%s/Sj-Pro/Sj-Pro.cfg",configDir)
	
	if(file_exists(gSJConfig)) 
	{
		server_cmd("exec %s",gSJConfig)

		//Force the server to flush the exec buffer
		server_exec()

		//Exec the config again due to issues with it not loading all the time
		server_cmd("exec %s",gSJConfig)
	}
	return PLUGIN_CONTINUE
}

/*
public createINIFile()
{
	new gSJConfig[128]
	new configDir[128]
	get_configsdir(configDir,127)
	formatex(gSJConfig,127,"%s/Sj-Pro.cfg",configDir)
	new nfila = 0
	
	write_file(gSJConfig,";      ***********                        ",nfila++)
	write_file(gSJConfig,";*******	CFG  By ***************         ",nfila++)
	write_file(gSJConfig,";*  ___.	          ___. ___.   *         ",nfila++)
	write_file(gSJConfig,";* /__/|          /L__|/L__|  *           ",nfila++)
	write_file(gSJConfig,";* |  ||         //  ///  /  *            ",nfila++)
	write_file(gSJConfig,";* |  ||        //  ///  /  *             ",nfila++)
	write_file(gSJConfig,";* |  ||       //  ///  /  *              ",nfila++)
	write_file(gSJConfig,";* |  ||_____ //  ///  /  *               ",nfila++)
	write_file(gSJConfig,";* |  |/____///  ///  /  *                ",nfila++)
	write_file(gSJConfig,";* |________/L__/ L__/  *                 ",nfila++)
	write_file(gSJConfig,";*                     *                  ",nfila++)
	write_file(gSJConfig,";**********************                   ",nfila++)
	write_file(gSJConfig," "
	write_file(gSJConfig,"; Cvars
	
*/


public create_line_off_red(number)
{
	if(is_offside[off_1])
	{		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(0)		//TE_BEAMPOINTS
		write_coord(number)	//centerpoint
		write_coord(Coord_Off_Y + 3000)	//left top corner
		write_coord(Coord_Off_Z)	//horizontal height
		write_coord(number)		//centerpoint
		write_coord(Coord_Off_Y - 3000)	//left right corner
		write_coord(Coord_Off_Z)	//horizontal height
		write_short(offbeam)	//sprite to use
		write_byte(1)		// framestart
		write_byte(1)		// framerate
		write_byte(10)		// life in 0.1's   42
		write_byte(15)		// width
		write_byte(0)		// noise
		write_byte(255)		// red
		write_byte(0)		// green
		write_byte(0)		// blue
		write_byte(210)		// brightness
		write_byte(0)		// speed
		message_end()
		
		set_task(1.0,"create_line_off_red", number)
	}
	
	return PLUGIN_CONTINUE;
}

public create_line_off_green(number)
{
	if(is_offside[off_1])
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(0)		//TE_BEAMPOINTS
		write_coord(number)	//centerpoint
		write_coord(Coord_Off_Y + 3000)	//left top corner
		write_coord(Coord_Off_Z)	//horizontal height
		write_coord(number)		//centerpoint
		write_coord(Coord_Off_Y - 3000)	//left right corner
		write_coord(Coord_Off_Z)	//horizontal height
		write_short(offbeam)	//sprite to use
		write_byte(1)		// framestart
		write_byte(1)		// framerate
		write_byte(10)		// life in 0.1's   42
		write_byte(15)		// width
		write_byte(0)		// noise
		write_byte(0)		// red
		write_byte(255)		// green
		write_byte(0)		// blue
		write_byte(210)		// brightness
		write_byte(0)		// speed
		message_end()
		
		set_task(1.0,"create_line_off_green",number)
	}
}

public IsFoul(attacker)
{
	new button = entity_get_int(attacker, EV_INT_button)
	if( attacker != ballholder && (button & IN_ATTACK || button & IN_ATTACK2)) 
	{					
		static Float:maxdistancia
		static Float:maxdistancia2
		static referencia
		static referencia2
		new team_at = get_user_team(attacker)
	
		referencia2 = Mascots[team_at]
		maxdistancia2 = get_pcvar_float(CVAR_KILLNEARAREA)
					
		if(ballholder > 0) 
		{
			referencia = ballholder
			maxdistancia = 200.0
		}			
		else 
		{
			referencia = aball
			maxdistancia = 400.0
		}
		
		if(entity_range(attacker, referencia2) > maxdistancia2)
		{
			if(entity_range(attacker, referencia) > maxdistancia)
			{
				is_user_foul[attacker] = true;
				user_foul_count[attacker] = 5;
				AvisoFoul(attacker)	
				Paralize(attacker)
			}
		}
	}
	return PLUGIN_CONTINUE;
}
		
public NewUserRank(id)
{
	if(UserPassword[id])
	{
		ColorChat(id, GREY, "[Sj-Pro]^x04 Este nick ya posee una cuenta")
		return PLUGIN_HANDLED;
	}

	new say[300];
	read_args(say, sizeof(say)-1);
	remove_quotes(say), trim(say);

	if (equal(say, ""))
		return PLUGIN_HANDLED
		
	if(contain(say, " ") != -1)
	{
		ColorChat(id, GREY, "[Sj-Pro]^x04 La contrasenia debe ser 1 (una) palabra")
		return PLUGIN_HANDLED;
	}
		
	CreateUserRank(id, say)
	
	return PLUGIN_CONTINUE
}
		
		
CreateUserRank(id, password[] = "")
{		
	new usuariopassword[32]
	
	if (password[0])
	{
		copy(usuariopassword, 31, password)
	}
	
	else
	{
		console_print(id,"[Sj-Pro] La contrasenia debe contener minimo una letra")
		return PLUGIN_HANDLED;
	}

	rankVault = nvault_open(VAULTNAMERANK);
	topVault = nvault_open(VAULTNAMETOP);
	
	new vaultkey[64], vaultdata[64], playername[MAX_PLAYER + 1];
	
	get_user_name(id, playername, MAX_PLAYER);

	format(vaultkey, 63, "^"%s^"", playername);

	TotalRank += 1
	new vaultnum[64]
	format(vaultnum, 63, "%i", TotalRank);	
	format(vaultdata, 63, "%s 0 0 0 0 0 0 0 0 0 0 %i", usuariopassword, TotalRank)
	nvault_set(rankVault, vaultkey, vaultdata);
	nvault_set(topVault, vaultnum, vaultkey);
	nvault_set(topVault, "RankKey", vaultnum);
	
	Pro_Point[id] = 0;
	Pro_Goal[id] = 0;
	Pro_Steal[id] = 0;
	Pro_Asis[id] = 0;
	Pro_Contra[id] = 0;
	Pro_Disarm[id] = 0;
	Pro_Kill[id] = 0;
	Pro_teKill[id] = 0;
	Pro_teSteal[id] = 0;
	Pro_teDisarm[id] = 0;
	Pro_Rank[id] = TotalRank;
	
	client_cmd(id, "setinfo _sj %s", usuariopassword)
	UserPassword[id] = true;

	console_print(id, "[Sj-Pro] Tus datos han sido registrados, en /help encontraras mas info")
	ColorChat(id, GREY, "[Sj-Pro]^x04 Tus datos han sido registrados, en /help encontraras mas info")	
	
	nvault_close(rankVault);
	nvault_close(topVault);
	
	return PLUGIN_CONTINUE;
}	
	
public ClearTask(id)
{	
	Pro_Point[id] = 0
	Pro_Goal[id] = 0
	Pro_Steal[id] = 0
	Pro_Asis[id] = 0   
	Pro_Contra[id] = 0
	Pro_Disarm[id] = 0
	Pro_Kill[id] = 0
	Pro_teKill[id] = 0
	Pro_teSteal[id] = 0		
	Pro_teDisarm[id] = 0
	Pro_Rank[id] = 0
	
	return PLUGIN_CONTINUE;
}

public health_change(id)
{
	if (!is_user_alive(id) || is_user_bot(id))
		return
		
	UserHealth[id] = read_data(1)
}

public monitor_think(ent)
{
	if ( !pev_valid(ent) )
		return FMRES_IGNORED

	static class[32]
	pev(ent, pev_classname, class, 31)

	if ( equal("monitorloop", class, 11) )
	{
		if(is_kickball > 0)
		{
			static players[MAX_PLAYER], count, i, id
			get_players(players, count, "ach")

			for ( i = 0; i < count; i++ )
			{
				id = players[i]

				set_hudmessage(255, 180, 0, 0.02, 0.97, 0, 0.0, 0.3, 0.0, 0.0)
				
				ShowSyncHudMsg(id, MonitorHudSync, "[Sj-Pro]  HP %d", UserHealth[id])
			}
		}

		// Keep monitorloop active even if shmod is not, incase sh is turned back on
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	}

	return FMRES_IGNORED
}

public msg_hideweapon()
{
	if (is_kickball > 0)
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDE_HUD_HEALTH)
}

public chooseview(id)
{
    new menu[192] 
    new keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3 
    format(menu, 191, "\yMenu de camaras^n^n\r1. \wTercera persona^n\r2. \wDesde arriba^n\r3. \wPrimera persona^n^n\r0. \ySalir") 
    show_menu(id, keys, menu)      
    return PLUGIN_CONTINUE
}

public setview(id, key, menu)
{
    if(key == 0) {
         set_view(id, CAMERA_3RDPERSON)
         return PLUGIN_HANDLED
    }

    if(key == 1) {
         set_view(id, CAMERA_TOPDOWN)
         return PLUGIN_HANDLED
    }

    if(key == 2) {
         set_view(id, CAMERA_NONE)
         return PLUGIN_HANDLED
    }

    else {
         return PLUGIN_HANDLED
    }

    return PLUGIN_HANDLED
}

public sj_editor_menu(id)
{

	new menueditor = menu_create("Sj Edit Menu", "menuedit")

	/*
	new asdname[32]
	get_user_name(id, asdname, 31)

	
	new players = get_playersnum(), i;

	new name[33];

	for(i = 1; i <= players; i++) 
	{
		get_user_name(i, name, 32);
		menu_additem( menueditor, name , "i", 0);		
	}
	
	menu_additem(menueditor, asdname, "1", 0)
	
	menu_setprop(menueditor , MPROP_EXITNAME , "Exit");
	menu_setprop(menueditor , MPROP_EXIT , MEXIT_ALL);
	
	menu_addblank(menueditor,1)
	menu_display(id,menueditor,0)

	*/
	
	new TempEdit[128]
	formatex(TempEdit, 127, "%s : %d %d %d",BOCHAGLOW, BallColors[0], BallColors[1], BallColors[2])
	menu_additem(menueditor, TempEdit, "1", 0)
	formatex(TempEdit, 127, "%s : %d %d %d",BOCHACOLORBEAMCT, BallColors[3], BallColors[4], BallColors[5])
	menu_additem(menueditor, TempEdit, "2", 0)	
	formatex(TempEdit, 127, "%s : %d %d %d",BOCHACOLORBEAMTT, BallColors[6], BallColors[7], BallColors[8])
	menu_additem(menueditor, TempEdit, "3", 0)
	formatex(TempEdit, 127, "%s : %d",BEAMGROSOR, BallColors[9])
	menu_additem(menueditor, TempEdit, "4", 0)
	formatex(TempEdit, 127, "%s : %d",BEAMLIFE, BallColors[10])
	menu_additem(menueditor, TempEdit, "5", 0)	
	formatex(TempEdit, 127, "%s : %d",BEAMLIFE, BallColors[11])
	menu_additem(menueditor, TempEdit, "6", 0)	

	/*
	menu_setprop(menueditor , MPROP_BACKNAME , "Atras...");
	menu_setprop(menueditor , MPROP_NEXTNAME , "Mas...");
	menu_setprop(menueditor , MPROP_EXITNAME , "Exit");
	menu_setprop(menueditor , MPROP_PERPAGE , 6);
	menu_setprop(menueditor , MPROP_EXIT , MEXIT_ALL);
	*/
	
	menu_addblank(menueditor,1)
	menu_display(id,menueditor,0)

	return PLUGIN_HANDLED
}



/*
			if(equali(sufijo,BOCHAGLOW))
				parse(Data, BCol[0], 3, BCol[1], 3, BCol[2], 3)
				
			else if(equali(sufijo,BOCHACOLORBEAMCT))
				parse(Data, BCol[3], 3, BCol[4], 3, BCol[5], 3)
				
			else if(equali(sufijo,BOCHACOLORBEAMTT))
				parse(Data, BCol[6], 3, BCol[7], 3, BCol[8], 3)
			
			else if(equali(sufijo,BEAMGROSOR))
				parse(Data, BCol[9], 3)
				
			else if(equali(sufijo,BEAMLIFE))
				parse(Data, BCol[10], 3)
				
			else if(equali(sufijo,BOCHABRILLO))
				parse(Data, BCol[11], 3)					
	
			else if(equali(sufijo,PLAYERCOLORGLOWCT))
				parse(Data, PCol[0], 3, PCol[1], 3, PCol[2], 3)
				
			else if(equali(sufijo,PLAYERCOLORGLOWTT))
				parse(Data, PCol[3], 3, PCol[4], 3, PCol[5], 3)	

			else if(equali(sufijo,ARQUEROCOLORGLOWCT))
				parse(Data, PCol[6], 3, PCol[7], 3, PCol[8], 3)	

			else if(equali(sufijo,ARQUEROCOLORGLOWTT))
				parse(Data, PCol[9], 3, PCol[10], 3, PCol[11], 3)

			else if(equali(sufijo,PLAYERGROSORGLOW))
				parse(Data, PCol[12], 3)				

			else if(equali(sufijo,ARQUEROGROSORGLOW))
				parse(Data, PCol[13], 3)	

			else if(equali(sufijo,COLORGLOWOFFSIDE))
				parse(Data, PCol[14], 3, PCol[15], 3, PCol[16], 3)
				
			else if(equali(sufijo,GROSORGLOWOFFSIDE))
				parse(Data, PCol[17], 3)		
				
			else if(equali(sufijo,COLORGLOWFOUL))
				parse(Data, PCol[18], 3, PCol[19], 3, PCol[20], 3)
				
			else if(equali(sufijo,GROSORGLOWFOUL))
				parse(Data, PCol[21], 3)

			else if(equali(sufijo,COLORTURBOCT))
				parse(Data, PCol[22], 3, PCol[23], 3, PCol[24], 3)
				
			else if(equali(sufijo,COLORTURBOTT))
				parse(Data, PCol[25], 3, PCol[26], 3, PCol[27], 3)	

			else if(equali(sufijo,COLORCARTELSCORE))
				parse(Data, PCol[28], 3, PCol[29], 3, PCol[30], 3)
		
		}
	}
	for(new x = 0; x < BOCHA_COLORS; x++)
		BallColors[x] = str_to_num(BCol[x])
		
	for(new x = 0; x < PLAYER_COLORS; x++)
		PlayerColors[x] = str_to_num(PCol[x])
	
}
	
*/	




public QuitarKeeper(id)
{
	new nameadm[MAX_PLAYER + 1], namekeeper[MAX_PLAYER + 1]
	new flags = get_user_flags(id)
		
	if(flags&ADMIN_KICK)
	{	
		new arg[33];
		read_argv(1 , arg, 32);
		
		new pid = cmd_target(id , arg , 9);
		if(!pid)
			return PLUGIN_HANDLED;
				
		if(!user_is_keeper[pid])
		{
			console_print(id, "[Sj-Pro] El player indicado no es arquero")
			return PLUGIN_HANDLED;
		}
		
		cmdUnKeeper(pid) 
		
		get_user_name(id, nameadm, MAX_PLAYER)
		get_user_name(pid, namekeeper, MAX_PLAYER)
		
		ColorChat(0,YELLOW,"ADMIN ^x04%s^x01 quito el keeper a ^x04%s^x01",nameadm, namekeeper)
	}
	
	return PLUGIN_HANDLED;
}

public MenuQuitarKeeper(id)
{
	new flags = get_user_flags(id)
		
	if(flags&ADMIN_KICK)
	{	
		new menueditor = menu_create("Menu de arqueros", "menuedit")
		new NameKeeper[MAX_PLAYER + 1], veri = 0;
		for(new x = 1; x <= MAX_PLAYER; x++)
		{
			if(user_is_keeper[x])
			{
				get_user_name(x, NameKeeper, MAX_PLAYER);
				menu_additem( menueditor, NameKeeper , "x", 0);		
				veri++;
			}
		}
		
		if(!veri)
		{
			ColorChat(id, GREY, "[Sj-Pro]^x04 No hay keepers para seleccionar")
			return PLUGIN_HANDLED;
		}
			

		menu_setprop(menueditor , MPROP_BACKNAME , "Atras...");
		menu_setprop(menueditor , MPROP_NEXTNAME , "Mas...");
		menu_setprop(menueditor , MPROP_EXITNAME , "Salir");
		menu_setprop(menueditor , MPROP_PERPAGE , 6);
		menu_setprop(menueditor , MPROP_EXIT , MEXIT_ALL);
		
		menu_addblank(menueditor,1)
		menu_display(id,menueditor,0)
	}
	return PLUGIN_HANDLED
	
}

public menuedit(id , menu , item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new cmd[6] , sItem[33];
	new access , callback;

	menu_item_getinfo(menu , item , access , cmd , 5 , sItem , 32 , callback);

	new index = get_user_index(sItem) , userid = get_user_userid(index);

	if(index) client_cmd(id , "amx_unkeeper #%d" , userid);

	return PLUGIN_HANDLED;
}



















































/*






public UpdateScore()
{
	new clock = -1;
	
	new CTSdigitos[2];
	new TTSdigitos[2];
	getScoreDigits(SJ_CT, CTSdigitos);
	getScoreDigits(SJ_TERROR, TTSdigitos);
	
	while((clock = find_ent_by_class(clock, class_team)))
	{
		new teamType = entity_get_int(clock, EV_INT_groupinfo);
		
		if (teamType == SJ_CT)
			set_clock_digits(clock, CTSdigitos);
		else if (teamType == SJ_TERROR)
			set_clock_digits(clock, TTSdigitos);
	}
}

public taskUpdateClocks()
{
	if(!ProgressCount)
		return

	new clock = -1;
	
	new Digitos[4];

	getTimeDigits(SJ_TIME, Digitos);

	while ((clock = find_ent_by_class(clock, class_tiempo)))
	{
		//get the clock type
		new clockType = entity_get_int(clock, EV_INT_groupinfo);
		
		//if the time changed for this clocktype
		if (clockType == SJ_TIME)
			set_clock_digits(clock, Digitos);
	}
}

public showClockMenu(id)
{
	//show the main menu to the player
	show_menu(id, MAIN_MENU_KEYS, gszMainMenuText, -1, "clockMainMenu");
	
	return PLUGIN_HANDLED;
}

public handleMainMenu(id, num)
{
	switch (num)
	{
		case N1: crearCartelScoreAiming(id, SJ_CT);
		case N2: crearCartelScoreAiming(id, SJ_TERROR);
		case N4: deleteScoreAiming(id);
		case N5: scaleScoreAiming(id, 0.1);
		case N6: scaleScoreAiming(id, -0.1);
		case N7: saveScore(id);
		case N8: loadScore(id);
	}
	
	//show menu again
	if (num != N0)
	{
		showClockMenu(id); 
	}
	
	return PLUGIN_HANDLED;
}

crearCartelScoreAiming(id, teamType)
{
	//make sure player has access to this command
	if (get_user_flags(id) & ADMIN_LEVEL)
	{
		new origin[3];
		new Float:vOrigin[3];
		new Float:vAngles[3];
		new Float:vNormal[3];
		
		//get the origin of where the player is aiming
		get_user_origin(id, origin, 3);
		IVecFVec(origin, vOrigin);
		
		new bool:bSuccess = traceClockAngles(id, vAngles, vNormal, 1000.0);
		
		//if the trace was successfull
		if (bSuccess)
		{
			//if the plane the trace hit is vertical
			if (vNormal[2] == 0.0)
			{
				//create the clock
				new bool:bSuccess = crearCartelScore(teamType, vOrigin, vAngles, vNormal);
				
				//if clock created successfully
				if (bSuccess)
				{
					client_print(id, print_chat, "%sCreated clock", gszPrefix);
				}
			}
			else
			{
				client_print(id, print_chat, "%sYou must place the clock on a vertical wall!", gszPrefix);
			}
		}
		else
		{
			client_print(id, print_chat, "%sMove closer to the target to create the clock", gszPrefix);
		}
	}
}

bool:crearCartelScore(teamType, Float:vOrigin[3], Float:vAngles[3], Float:vNormal[3], Float:fScale = 1.0)
{
	new cartel = create_entity(class_infotarget);
	new digito[2];
	
	new bool:bFailed = false;
	
	for (new i = 0; i < 2; ++i)
	{
		digito[i] = create_entity(class_infotarget);
		
		//if failed boolean is false and entity failed to create
		if (!bFailed && !is_valid_ent(digito[i]))
		{
			bFailed = true;
			break;
		}
	}
	
	if (is_valid_ent(cartel) && !bFailed)
	{
		//adjust the origin to lift the clock off the wall (prevent flickering)
		vOrigin[0] += (vNormal[0] * 0.5);
		vOrigin[1] += (vNormal[1] * 0.5);
		vOrigin[2] += (vNormal[2] * 0.5);
		
		// Propiedades del cartel
		
		entity_set_string(cartel, EV_SZ_classname, class_team);
		entity_set_int(cartel, EV_INT_solid, SOLID_NOT);
		entity_set_model(cartel, spr_teams);
		entity_set_vector(cartel, EV_VEC_angles, vAngles);
		entity_set_float(cartel, EV_FL_scale, fScale);
		entity_set_origin(cartel, vOrigin);
		entity_set_int(cartel, EV_INT_groupinfo, teamType);
		
		switch (teamType)
		{
			case SJ_CT: entity_set_float(cartel, EV_FL_frame, 0.0);
			case SJ_TERROR: entity_set_float(cartel, EV_FL_frame, 1.0);
		}
		
		//link the digits entities to the clock
		
		entity_set_int(cartel, EV_INT_iuser1, digito[0]);
		entity_set_int(cartel, EV_INT_iuser2, digito[1]);
		
		new ValorDigito[2];
		
		for (new i = 0; i < 2; ++i)
		{
			//setup digit properties
			entity_set_string(digito[i], EV_SZ_classname, class_digito);
			entity_set_vector(digito[i], EV_VEC_angles, vAngles);
			entity_set_model(digito[i], spr_digits);
			entity_set_float(digito[i], EV_FL_scale, fScale);
			
			//set digit position
			set_digit_origin(i, digito[i], vOrigin, vNormal, fScale);
			
			//get the time digits
			getScoreDigits(teamType, ValorDigito);
			
			//set the in-game clocks digits
			set_clock_digits(cartel, ValorDigito);
		}
		
		return true;
	}
	else
	{
		//delete clock face if it created successfully
		if (is_valid_ent(cartel))
		{
			remove_entity(cartel);
		}
		
		//iterate though the entity array and delete whichever ones created successfully
		for (new i = 0; i < 2; ++i)
		{
			if (is_valid_ent(digito[i]))
			{
				remove_entity(digito[i]);
			}
		}
	}
	
	return false;
}

deleteScoreAiming(id)
{
	new bool:bDeleted;
	new clock = get_score_aiming(id);
	
	if (clock)
	{
		//delete the clock
		bDeleted = deleteClock(clock);
		
		//if the clock was deleted successfully
		if (bDeleted)
		{
			client_print(id, print_chat, "%sDeleted clock", gszPrefix);
		}
	}
}

bool:deleteClock(ent)
{
	//if the entity is a clock
	if (isClock(ent))
	{
		//get entity IDs of digits on the clock
		new digito[2];
		digito[0] = entity_get_int(ent, EV_INT_iuser1);
		digito[1] = entity_get_int(ent, EV_INT_iuser2);
		
		//delete the digits on the clock if they're valid
		if (is_valid_ent(digito[0])) remove_entity(digito[0]);
		if (is_valid_ent(digito[1])) remove_entity(digito[1]);
		
		//delete the clock face
		remove_entity(ent);
		
		//successfully deleted the clock
		return true;
	}
	
	return false;
}

scaleScoreAiming(id, Float:fScaleAmount)
{
	//get the clock the player is aiming at (if any)
	new clock = get_score_aiming(id);
	
	//if player is aiming at a clock
	if (clock)
	{
		//get the clocks digit entities
		new digito[2];
		new bSuccess = get_clock_digits(clock, digito);
		
		//if successfully got clocks digit entities
		if (bSuccess)
		{
			new Float:vOrigin[3];
			new Float:vNormal[3];
			new Float:vAngles[3];
			
			//get the clocks current scale and add on the specified amount
			new Float:fScale = entity_get_float(clock, EV_FL_scale);
			fScale += fScaleAmount;
			
			//make sure the scale isn't negative
			if (fScale > 0.01)
			{
				//set the clocks scale
				entity_set_float(clock, EV_FL_scale, fScale);
				
				//get the clocks origin and angles
				entity_get_vector(clock, EV_VEC_origin, vOrigin);
				entity_get_vector(clock, EV_VEC_angles, vAngles);
				
				//get the clocks normal vector from the angles
				angle_vector(vAngles, ANGLEVECTOR_FORWARD, vNormal);
				
				//set the normal to point in the opposite direction
				vNormal[0] = -vNormal[0];
				vNormal[1] = -vNormal[1];
				vNormal[2] = -vNormal[2];
				
				//enlarge the clocks digits by the specified amount
				for (new i = 0; i < 2; ++i)
				{
					//set the digits scale
					entity_set_float(digito[i], EV_FL_scale, fScale);
					
					//adjust the digits origin because of the new scale
					set_digit_origin(i, digito[i], vOrigin, vNormal, fScale);
				}
			}
		}
	}
}

saveScore(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & ADMIN_LEVEL)
	{
		new ent = -1;
		new Float:vOrigin[3];
		new Float:vAngles[3];
		new Float:fScale;
		new clockCount = 0;
		new szData[128];
		
		//open file for writing
		new file = fopen(FileCartel, "wt");
		new teamType;
		
		while ((ent = find_ent_by_class(ent, class_team)))
		{
			//get clock info
			entity_get_vector(ent, EV_VEC_origin, vOrigin);
			entity_get_vector(ent, EV_VEC_angles, vAngles);
			fScale = entity_get_float(ent, EV_FL_scale);
			teamType = entity_get_int(ent, EV_INT_groupinfo);
			
			//format clock info and save it to file
			formatex(szData, 128, "%c %f %f %f %f %f %f %f^n", gClockSaveIds[teamType], vOrigin[0], vOrigin[1], vOrigin[2], vAngles[0], vAngles[1], vAngles[2], fScale);
			fputs(file, szData);
			
			//increment clock count
			++clockCount;
		}
		
		//get players name
		new szName[32];
		get_user_name(id, szName, 32);
		
		//notify all admins that the player saved clocks to file
		for (new i = 1; i <= 32; ++i)
		{
			//make sure player is connected
			if (is_user_connected(i))
			{
				if (get_user_flags(i) & ADMIN_LEVEL)
				{
					client_print(i, print_chat, "%s'%s' saved %d clock%s to file!", gszPrefix, szName, clockCount, (clockCount == 1 ? "" : "s"));
				}
			}
		}
		
		//close file
		fclose(file);
	}
}

loadScore(id)
{
	//if the clock save file exists
	if (file_exists(FileCartel))
	{
		new szData[128];
		new szType[2];
		new oX[13], oY[13], oZ[13];
		new aX[13], aY[13], aZ[13];
		new szScale[13];
		new Float:vOrigin[3];
		new Float:vAngles[3];
		new Float:vNormal[3];
		new Float:fScale;
		new clockCount = 0;
		
		//open the file for reading
		new file = fopen(FileCartel, "rt");
		
		//iterate through all the lines in the file
		while (!feof(file))
		{
			szType = "";
			fgets(file, szData, 128);
			parse(szData, szType, 2, oX, 12, oY, 12, oZ, 12, aX, 12, aY, 12, aZ, 12, szScale, 12);
			
			vOrigin[0] = str_to_float(oX);
			vOrigin[1] = str_to_float(oY);
			vOrigin[2] = str_to_float(oZ);
			vAngles[0] = str_to_float(aX);
			vAngles[1] = str_to_float(aY);
			vAngles[2] = str_to_float(aZ);
			fScale = str_to_float(szScale);
			
			if (strlen(szType) > 0)
			{
				//get the normal vector from the angles
				angle_vector(vAngles, ANGLEVECTOR_FORWARD, vNormal);
				
				//set the normal to point in the opposite direction
				vNormal[0] = -vNormal[0];
				vNormal[1] = -vNormal[1];
				vNormal[2] = -vNormal[2];
				
				//create the clock depending on the clock type
				switch (szType[0])
				{
					case 'C': crearCartelScore(SJ_CT, vOrigin, vAngles, vNormal, fScale);
					case 'T': crearCartelScore(SJ_TERROR, vOrigin, vAngles, vNormal, fScale);
				}
				
				++clockCount;
			}
		}
		
		//close the file
		fclose(file);
		
		//if a player is loading the clocks
		if (id > 0 && id <= 32)
		{
			//get players name
			new szName[32];
			get_user_name(id, szName, 32);
			
			//notify all admins that the player loaded clocks from file
			for (new i = 1; i <= 32; ++i)
			{
				//make sure player is connected
				if (is_user_connected(i))
				{
					if (get_user_flags(i) & ADMIN_LEVEL)
					{
						client_print(i, print_chat, "%s'%s' loaded %d clock%s from file!", gszPrefix, szName, clockCount, (clockCount == 1 ? "" : "s"));
					}
				}
			}
		}
	}
}

get_score_aiming(id)
{
	//get hit point for where player is aiming
	new origin[3];
	new Float:vOrigin[3];
	get_user_origin(id, origin, 3);
	IVecFVec(origin, vOrigin);
	
	new ent = -1;
	
	//find all entities within a 2 unit sphere
	while ((ent = find_ent_in_sphere(ent, vOrigin, 2.0)))
	{
		//if entity is a clock
		if (isClock(ent))
		{
			return ent;
		}
	}
	
	return 0;
}

bool:traceClockAngles(id, Float:vAngles[3], Float:vNormal[3], Float:fDistance)
{
	//get players origin and add on their view offset
	new Float:vPlayerOrigin[3];
	new Float:vViewOfs[3];
	entity_get_vector(id, EV_VEC_origin, vPlayerOrigin);
	entity_get_vector(id, EV_VEC_view_ofs, vViewOfs);
	vPlayerOrigin[0] += vViewOfs[0];
	vPlayerOrigin[1] += vViewOfs[1];
	vPlayerOrigin[2] += vViewOfs[2];
	
	//calculate the end point for trace using the players view angle
	new Float:vAiming[3];
	entity_get_vector(id, EV_VEC_v_angle, vAngles);
	vAiming[0] = vPlayerOrigin[0] + floatcos(vAngles[1], degrees) * fDistance;
	vAiming[1] = vPlayerOrigin[1] + floatsin(vAngles[1], degrees) * fDistance;
	vAiming[2] = vPlayerOrigin[2] + floatsin(-vAngles[0], degrees) * fDistance;
	
	//trace a line and get the normal for the plane it hits
	new trace = trace_normal(id, vPlayerOrigin, vAiming, vNormal);
	
	//convert the normal into an angle vector
	vector_to_angle(vNormal, vAngles);
	
	//spin the angle vector 180 degrees around the Y axis
	vAngles[1] += 180.0;
	if (vAngles[1] >= 360.0) vAngles[1] -= 360.0;
	
	return bool:trace;
}

set_digit_origin(i, digito, Float:vOrigin[3], Float:vNormal[3], Float:fScale)
{
	//make sure the digit entity is valid
	if (is_valid_ent(digito))
	{
		new Float:vDigitNormal[3];
		new Float:vPos[3];
		new Float:fVal;
		
		//change the normals to get the left and right depending on the digit
		vDigitNormal = vNormal;
		vDigitNormal[X] = -vDigitNormal[X];
		
		//setup digit position
		fVal = (((gfClockSize[X] / 2) * gfDigitOffsetMultipliers[i])) * fScale;
		vPos[X] = vOrigin[X] + (vDigitNormal[Y] * fVal);
		vPos[Y] = vOrigin[Y] + (vDigitNormal[X] * fVal);
		vPos[Z] = vOrigin[Z] + vNormal[Z] - ((gfTitleSize / 2.0 )* fScale);
		
		//bring digit sprites forwards off the clock face to prevent flickering
		vPos[0] += (vNormal[0] * 0.5);
		vPos[1] += (vNormal[1] * 0.5);
		vPos[2] += (vNormal[2] * 0.5);
		
		//set the digits origin
		entity_set_origin(digito, vPos);
	}
}

bool:getScoreDigits(teamType, ValorDigito[2])
{
	new szTime[3];
	new entero

	switch(teamType)
	{
		case SJ_CT:			entero = score[2]
		case SJ_TERROR:		entero = score[1]	
	}
	
	format(szTime, 2, "%s%d", (entero < 10 ? "0" : ""), entero);
	
	ValorDigito[0] = szTime[0] - 48;
	ValorDigito[1] = szTime[1] - 48;

	return true;
}

bool:get_clock_digits(clock, digito[2])
{
	//if the entity is a clock
	if (isClock(clock))
	{
		//get entity IDs of digits on the clock
		digito[0] = entity_get_int(clock, EV_INT_iuser1);
		digito[1] = entity_get_int(clock, EV_INT_iuser2);

		//make sure all the clock digits are valid
		for (new i = 0; i < 2; ++i)
		{
			if (!is_valid_ent(digito[i]))
			{
				log_amx("%sInvalid digit entity in clock", gszPrefix);
				
				return false;
			}
		}
	}
	
	return true;
}

set_clock_digits(clock, ValorDigito[2])
{
	//get the clocks digit entities
	new digito[2];
	new bool:bSuccess = get_clock_digits(clock, digito);
	
	//if successfully got clocks digit entities
	if (bSuccess)
	{
		entity_set_float(digito[0], EV_FL_frame, float(ValorDigito[0]));
		entity_set_float(digito[1], EV_FL_frame, float(ValorDigito[1]));
	}
}



bool:isClock(ent)
{
	//if entity is valid
	if (is_valid_ent(ent))
	{
		//get classname of entity
		new szClassname[32];
		entity_get_string(ent, EV_SZ_classname, szClassname, 32);
		
		//if classname of entity matches global clock classname
		if (equal(szClassname, class_team))
		{
			//entity is a clock
			return true;
		}
	}
	
	return false;
}

*/
