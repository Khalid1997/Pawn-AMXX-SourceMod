/*  SM Fortnite Emotes Extended
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <vipsys>
#include <tVip>
//#include <thirdperson>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvThirdperson;
ConVar g_cvHidePlayers;

TopMenu hTopMenu;

ConVar g_cvCooldown;
ConVar g_cvSoundVolume;
ConVar g_cvEmotesSounds;
ConVar g_cvHideWeapons;
ConVar g_cvTeleportBack;

int g_iEmoteEnt[MAXPLAYERS+1];
int g_iEmoteSoundEnt[MAXPLAYERS+1];

int g_EmotesTarget[MAXPLAYERS+1];

char g_sEmoteSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];

bool g_bClientDancing[MAXPLAYERS+1];


Handle CooldownTimers[MAXPLAYERS+1];
bool g_bEmoteCooldown[MAXPLAYERS+1];

int g_iWeaponHandEnt[MAXPLAYERS+1];

Handle g_EmoteForward;
Handle g_EmoteForward_Pre;
bool g_bHooked[MAXPLAYERS + 1];

float g_fLastAngles[MAXPLAYERS+1][3];
float g_fLastPosition[MAXPLAYERS+1][3];

char g_szDanceName[][] = {
	"Dance Moves",
	"Orange Justice",
	"Rambunctious",
	"Electro Shuffle",
	"Aerobic",
	"Bendy",
	"Best Mates",
	"Boogie Down",
	"Capoeira",
	"Chicken",
	"Flapper",
	"Boneless",
	"Hype",
	"Shake It Up",
	"Disco Fever",
	"Disco Fever 2",
	"The Worm",
	"Take the L",
	"Breakdance",
	"Pump",
	"Ride the Pony",
	"Dab",
	"Eastern Bloc",
	"Dream Feet",
	"Floss",
	"Flippn",
	"Fresh",
	"Grefg",
	"Guitar",
	"Shuffle",
	"Hip Hop",
	"Hula Hop",
	"Infinite Dab",
	"Intensity",
	"Turkish Dabke",
	"Eagle",
	"True Heart",
	"Living Large",
	"Maracas",
	"Pop Lock",
	"Star Power",
	"Robot",
	"T-Rex",
	"Reanimated",
	"Twist",
	"Ware House",
	"Wiggle",
	"You're Awesome",
};

char g_szDanceAnim1[][] = {
	"DanceMoves",
	"Emote_Mask_Off_Intro",
	"Emote_Zippy_Dance",
	"ElectroShuffle",
	"Emote_AerobicChamp",
	"Emote_Bendy",
	"Emote_BandOfTheFort",
	"Emote_Boogie_Down_Intro",
	"Emote_Capoeira",
	"Emote_Charleston",
	"Emote_Chicken",
	"Emote_Dance_NoBones",
	"Emote_Dance_Shoot",
	"Emote_Dance_SwipeIt",
	"Emote_Dance_Disco_T3",
	"Emote_DG_Disco",
	"Emote_Dance_Worm",
	"Emote_Dance_Loser",
	"Emote_Dance_Breakdance",
	"Emote_Dance_Pump",
	"Emote_Dance_RideThePony",
	"Emote_Dab",
	"Emote_EasternBloc_Start",
	"Emote_FancyFeet",
	"Emote_FlossDance",
	"Emote_FlippnSexy",
	"Emote_Fresh",
	"Emote_GrooveJam",
	"Emote_guitar",
	"Emote_Hillbilly_Shuffle_Intro",
	"Emote_Hiphop_01",
	"Emote_Hula_Start",
	"Emote_InfiniDab_Intro",
	"Emote_Intensity_Start",
	"Emote_IrishJig_Start",
	"Emote_KoreanEagle",
	"Emote_Kpop_02",
	"Emote_LivingLarge",
	"Emote_Maracas",
	"Emote_PopLock",
	"Emote_PopRock",
	"Emote_RobotDance",
	"Emote_T-Rex",
	"Emote_TechnoZombie",
	"Emote_Twist",
	"Emote_WarehouseDance_Start",
	"Emote_Wiggle",
	"Emote_Youre_Awesome"
};

char g_szDanceAnim2[][] = {
	"none",
	"Emote_Mask_Off_Loop",
	"none",
	"none",
	"none",
	"none",
	"none",
	"Emote_Boogie_Down",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"Emote_Dance_Loser_CT",
	"none",
	"none",
	"none",
	"none",
	"Emote_EasternBloc",
	"Emote_FancyFeet_CT",
	"none",
	"none",
	"none",
	"none",
	"none",
	"Emote_Hillbilly_Shuffle",
	"Emote_Hip_Hop",
	"Emote_Hula",
	"Emote_InfiniDab_Loop",
	"Emote_Intensity_Loop",
	"Emote_IrishJig",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"Emote_WarehouseDance_Loop",
	"none",
	"none",
};

char g_szDanceSoundName[][] = {
	"ninja_dance_01",
	"hip_hop_good_vibes_mix_01_loop",
	"emote_zippy_a",
	"athena_emote_electroshuffle_music",
	"emote_aerobics_01",
	"athena_music_emotes_bendy",
	"athena_emote_bandofthefort_music",
	"emote_boogiedown",
	"emote_capoeira",
	"athena_emote_flapper_music",
	"athena_emote_chicken_foley_01",
	"athena_emote_music_boneless",
	"athena_emotes_music_shoot_v7",
	"Athena_Emotes_Music_SwipeIt",
	"athena_emote_disco",
	"athena_emote_disco",					
	"athena_emote_worm_music",
	"athena_music_emotes_takethel",
	"athena_emote_breakdance_music",
	"Emote_Dance_Pump",
	"athena_emote_ridethepony_music_01",
	"",
	"eastern_bloc_musc_setup_d",
	"athena_emotes_lankylegs_loop_02",
	"athena_emote_floss_music",
	"Emote_FlippnSexy",
	"athena_emote_fresh_music",
	"emote_groove_jam_a",
	"br_emote_shred_guitar_mix_03_loop",
	"Emote_Hillbilly_Shuffle",
	"s5_hiphop_breakin_132bmp_loop",
	"emote_hula_01",
	"athena_emote_infinidab",
	"emote_Intensity",
	"emote_irish_jig_foley_music_loop",
	"Athena_Music_Emotes_KoreanEagle",
	"emote_kpop_01",
	"emote_LivingLarge_A",
	"emote_samba_new_B",
	"Athena_Emote_PopLock",
	"Emote_PopRock_01",	
	"athena_emote_robot_music",
	"Emote_Dino_Complete",
	"athena_emote_founders_music",		
	"athena_emotes_music_twist",
	"Emote_Warehouse",
	"Wiggle_Music_Loop",
	"youre_awesome_emote_music"
};

bool g_bDanceRepeating[] = {
	false,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	false,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	false,
	true,
	false,
	true,
	false,
	false,
	true,
	true,
	true,
	false,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	false,
	true,
	true,
	true,
	true,
	false
};

char g_szEmoteName[][] = {
	"Finger Guns",
	"Come to Me",
	"Thumbs Down",
	"Thumbs Up",
	"Celebration",
	"Blow Kiss",
	"Calculated",
	"Confused",
	"Chug",
	"Cry",
	"Band of the Fort",
	"Shake it Up 2",
	"Facepalm",
	"Fishing",
	"Flex",
	"Golf Clap",
	"Hand Signals",
	"Click!",
	"Hot Stuff",
	"Breaking Point",
	"True Love",
	"Kung-Fu Salute",
	"Laugh",
	"Luchador",
	"Make it Rain",
	"No Hoy",
	"Rock Paper Sicssor: Paper",
	"Rock Paper Scissor: Rock",
	"Rock Paper Scissor: Scissor",
	"Salt Bae",
	"Salute",
	"Drive Car",
	"Snap",
	"Stage Bow",
	"Salute 2",
	"Yeet"
};

char g_szEmoteAnim1[][] = {
	"Emote_Fonzie_Pistol",
	"Emote_Bring_It_On",
	"Emote_ThumbsDown",
	"Emote_ThumbsUp",
	"Emote_Celebration_Loop",
	"Emote_BlowKiss",
	"Emote_Calculated",
	"Emote_Confused",	
	"Emote_Chug",
	"Emote_Cry",
	"Emote_DustingOffHands",
	"Emote_DustOffShoulders",	
	"Emote_Facepalm",
	"Emote_Fishing",
	"Emote_Flex",
	"Emote_golfclap",	
	"Emote_HandSignals",
	"Emote_HeelClick",
	"Emote_Hotstuff",
	"Emote_IBreakYou",	
	"Emote_IHeartYou",
	"Emote_Kung-Fu_Salute",
	"Emote_Laugh",
	"Emote_Luchador",	
	"Emote_Make_It_Rain",
	"Emote_NotToday",
	"Emote_RockPaperScissor_Paper",
	"Emote_RockPaperScissor_Rock",	
	"Emote_RockPaperScissor_Scissor",
	"Emote_Salt",
	"Emote_Salute",
	"Emote_SmoothDrive",	
	"Emote_Snap",
	"Emote_StageBow",
	"Emote_Wave2",
	"Emote_Yeet"
};	

char g_szEmoteAnim2[][] = {
	"none",
	"none",
	"none",
	"none",
	"",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"Emote_Laugh_CT",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
};

char g_szEmoteSoundName[][] = {
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"emote_cry",
	"athena_emote_bandofthefort_music",
	"athena_emote_hot_music",
	"athena_emote_facepalm_foley_01",
	"Athena_Emotes_OnTheHook_02",
	"",
	"",
	"",
	"Emote_HeelClick",
	"Emote_Hotstuff",
	"",
	"",
	"",
	"emote_laugh_01.mp3",
	"Emote_Luchador",
	"athena_emote_makeitrain_music",
	"",
	"",
	"",
	"",
	"",
	"athena_emote_salute_foley_01",
	"",
	"Emote_Snap1",
	"emote_stagebow",
	"",
	"Emote_Yeet",
};

bool g_bEmoteRepeating[] = {
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	true,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
};

bool g_bIsVIP[MAXPLAYERS + 1] = false;
bool g_bLate;

public Plugin myinfo =
{
	name = "SM Fortnite Emotes Extended",
	author = "Kodua, Franc1sco franug, TheBO$$",
	description = "This plugin is for demonstration of some animations from Fortnite in CS:GO",
	version = "1.4.2",
	url = "https://github.com/Franc1sco/Fortnite-Emotes-Extended"
};

public void OnPluginStart()
{	
	LoadTranslations("common.phrases");
	LoadTranslations("fnemotes.phrases");
	
	RegConsoleCmd("sm_emotes", Command_MainMenu);
	RegConsoleCmd("sm_emote", Command_MainMenu);
	RegConsoleCmd("sm_dances", Command_MainMenu);	
	RegConsoleCmd("sm_dance", Command_MainMenu);
	RegConsoleCmd("emoteqa", Command_QuickAccessMenu);
	
	RegConsoleCmd("emote", Command_MainMenu, "<EmoteId> - Plays Emote. Get the ID from Emote Menu (in brackets)");
	
	RegAdminCmd("sm_setemotes", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
	RegAdminCmd("sm_setemote", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
	RegAdminCmd("sm_setdances", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
	RegAdminCmd("sm_setdance", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", 	Event_PlayerHurt, 	EventHookMode_Pre);
	HookEvent("round_prestart",  Event_Start);
	
	/**
		Convars
	**/
	
	AutoExecConfig_SetFile("fortnite_emotes_extended");

	g_cvEmotesSounds = AutoExecConfig_CreateConVar("sm_emotes_sounds", "1", "Enable/Disable sounds for emotes.", _, true, 0.0, true, 1.0);
	g_cvCooldown = AutoExecConfig_CreateConVar("sm_emotes_cooldown", "4.0", "Cooldown for emotes in seconds. -1 or 0 = no cooldown.");
	g_cvSoundVolume = AutoExecConfig_CreateConVar("sm_emotes_soundvolume", "0.4", "Sound volume for the emotes.");
	g_cvHideWeapons = AutoExecConfig_CreateConVar("sm_emotes_hide_weapons", "1", "Hide weapons when dancing", _, true, 0.0, true, 1.0);
	g_cvHidePlayers = AutoExecConfig_CreateConVar("sm_emotes_hide_enemies", "0", "Hide enemy players when dancing", _, true, 0.0, true, 1.0);
	g_cvTeleportBack = AutoExecConfig_CreateConVar("sm_emotes_teleportonend", "0", "Teleport back to the exact position when he started to dance. (Some maps need this for teleport triggers)", _, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	/**
		End Convars
	**/

	g_cvThirdperson = FindConVar("sv_allow_thirdperson");
	if (!g_cvThirdperson) SetFailState("sv_allow_thirdperson not found!");

	g_cvThirdperson.AddChangeHook(OnConVarChanged);
	g_cvThirdperson.BoolValue = true;
	
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}	
	
	g_EmoteForward = CreateGlobalForward("fnemotes_OnEmote", ET_Ignore, Param_Cell);
	g_EmoteForward_Pre = CreateGlobalForward("fnemotes_OnEmote_Pre", ET_Event, Param_Cell);
	
	if(g_bLate)
	{
		bool bVIPSys = LibraryExists("vipsys");
		bool bTVIP = LibraryExists("tVip");
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				continue;
			}
			
			if( bVIPSys && VIPSys_Client_IsVIP(i))
			{
				g_bIsVIP[i] = true;
			}
			
			else if(bTVIP && tVip_IsVip(i))
			{
				g_bIsVIP[i] = true;
			}
			
			else	g_bIsVIP[i] = false;
			
			/*if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}*/
		}
	}
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem("emotes");
	
	for (int i = 1; i <= MaxClients; i++)
            if (IsValidClient(i) && g_bClientDancing[i]) {
				StopEmote(i);
			}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("fnemotes");
	CreateNative("fnemotes_IsClientEmoting", Native_IsClientEmoting);
	
	g_bLate = late;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem("emotes", "Emotes", MenuAction_Select, ITEMDRAW_DEFAULT, VIP_OnSelectEmote_OpenMenu, 3);
}

public int VIP_OnSelectEmote_OpenMenu(Menu menu, char[] szInfo, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		if (!IsClientVIP(param1))
		{
			return;
		}
		
		Command_MainMenu(param1, 0);
	}
	
	return;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvThirdperson)
	{
		if(newValue[0] != '1') convar.BoolValue = true;
	}
}

int Native_IsClientEmoting(Handle plugin, int numParams)
{
	return g_bClientDancing[GetNativeCell(1)];
}

public Action Command_QuickAccessMenu(int client, int args)
{
	OpenQuickAccessMenu(client);
}

bool IsClientVIP(int client)
{	
	return g_bIsVIP[client];
}

public void tVip_OnClientLoadedPost(int client, bool bIsVIP)
{
	VIPSys_Client_OnCheckVIP(client, bIsVIP);
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	g_bIsVIP[client] = bIsVIP;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2.vvd");
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2.dx90.vtx");

	// edit
	// add the sound file routes here
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/ninja_dance_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/dance_soldier_03.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/hip_hop_good_vibes_mix_01_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_zippy_a.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_electroshuffle_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_aerobics_01.wav"); 
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_bendy.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_bandofthefort_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_boogiedown.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_flapper_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_chicken_foley_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_cry.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_music_boneless.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_shoot_v7.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emotes_Music_SwipeIt.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_disco.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_worm_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_takethel.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Dance_Pump.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3"); 
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emotes_OnTheHook_02.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_floss_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_FlippnSexy.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_fresh_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_groove_jam_a.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_HeelClick.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Hotstuff.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_hula_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_infinidab.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_Intensity.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Music_Emotes_KoreanEagle.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_kpop_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_laugh_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_LivingLarge_A.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Luchador.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Hillbilly_Shuffle.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_samba_new_B.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emote_PopLock.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_PopRock_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_robot_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Snap1.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_stagebow.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Dino_Complete.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_founders_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_twist.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Warehouse.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Wiggle_Music_Loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Yeet.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/youre_awesome_emote_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/eastern_bloc_musc_setup_d.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_bandofthefort_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_hot_music.wav");
    

	// this dont touch
	PrecacheModel("models/player/custom_player/kodua/fortnite_emotes_v2.mdl", true);

	// edit
	// add mp3 files without sound/
	// add wav files with */
	PrecacheSound("kodua/fortnite_emotes/ninja_dance_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/dance_soldier_03.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/hip_hop_good_vibes_mix_01_loop.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_zippy_a.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_electroshuffle_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_aerobics_01.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_music_emotes_bendy.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_bandofthefort_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_boogiedown.wav");
	PrecacheSound("kodua/fortnite_emotes/emote_capoeira.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_flapper_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_chicken_foley_01.wav");
	PrecacheSound("kodua/fortnite_emotes/emote_cry.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_music_boneless.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emotes_music_shoot_v7.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Athena_Emotes_Music_SwipeIt.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_disco.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_worm_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_music_emotes_takethel.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_Dance_Pump.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/Athena_Emotes_OnTheHook_02.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_floss_music.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_FlippnSexy.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_fresh_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_groove_jam_a.wav");
	PrecacheSound("*/kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_HeelClick.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_Hotstuff.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/emote_hula_01.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_infinidab.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_Intensity.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Athena_Music_Emotes_KoreanEagle.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_kpop_01.wav");
	PrecacheSound("kodua/fortnite_emotes/emote_laugh_01.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/emote_LivingLarge_A.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_Luchador.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_Hillbilly_Shuffle.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_samba_new_B.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/Athena_Emote_PopLock.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_PopRock_01.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_robot_music.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/Emote_Snap1.mp3");
	PrecacheSound("kodua/fortnite_emotes/emote_stagebow.mp3");
	PrecacheSound("kodua/fortnite_emotes/Emote_Dino_Complete.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_founders_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emotes_music_twist.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_Warehouse.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Wiggle_Music_Loop.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_Yeet.mp3");
	PrecacheSound("kodua/fortnite_emotes/youre_awesome_emote_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.wav");
	PrecacheSound("*/kodua/fortnite_emotes/eastern_bloc_musc_setup_d.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_bandofthefort_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_hot_music.wav");
}


public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{	
		ResetCam(client);
		TerminateEmote(client);
		g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;

		if (CooldownTimers[client] != null)
		{
			KillTimer(CooldownTimers[client]);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		ResetCam(client);
		TerminateEmote(client);

		if (CooldownTimers[client] != null)
		{
			KillTimer(CooldownTimers[client]);
			CooldownTimers[client] = null;
			g_bEmoteCooldown[client] = false;
		}
	}
	g_bHooked[client] = false;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		ResetCam(client);
		StopEmote(client);
	}
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) 
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	char sAttacker[16];
	GetEntityClassname(attacker, sAttacker, sizeof(sAttacker));
	if (StrEqual(sAttacker, "worldspawn"))//If player was killed by bomb
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		StopEmote(client);
	}
}

void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
            if (IsValidClient(i, false) && g_bClientDancing[i]) {
				ResetCam(i);
				//StopEmote(client);
				WeaponUnblock(i);
				
				g_bClientDancing[i] = false;
			}
}

public Action Command_MainMenu(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if(!IsClientVIP(client))
	{
		CPrintToChat(client, "\x04[EMOTES] \x01You are not a VIP.");
		CReplyToCommand(client, "\x04[EMOTES] \x01You are not a VIP.");
		return Plugin_Handled;
	}
	
	if(args == 1)
	{
		char szArg[5];
		GetCmdArg(1, szArg, sizeof szArg);
		
		int iIndex = StringToInt(szArg);
		iIndex -= 1;
	
		if( !( 0 <= iIndex < ( sizeof(g_szEmoteName) + sizeof(g_szDanceName) ) ) )
		{
			CPrintToChat(client, "\x04[EMOTES] \x01INVALID EMOTE ID.");
			CReplyToCommand(client, "\x04[EMOTES] \x01INVALID EMOTE ID.");
			return Plugin_Handled;
		}
	
		CreateEmoteFromIndex(client, iIndex);
		return Plugin_Handled;
	}
	
	OpenMainMenu(client);
	CPrintToChat(client, "\x04* You can bind a key to use a specific emote number (in between brackets). For example, try the following bind c \"emote 73\"");
	
	return Plugin_Handled;
}

void OpenQuickAccessMenu(int client)
{
	CPrintToChat(client, "\x04* This feature is still under development. Sorry! From \x01Khalid!");
}

Action CreateEmote(int client, const char[] anim1, const char[] anim2, const char[] soundName, bool isLooped)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	if(g_EmoteForward_Pre != null)
	{
		Action res = Plugin_Continue;
		Call_StartForward(g_EmoteForward_Pre);
		Call_PushCell(client);
		Call_Finish(res);

		if (res != Plugin_Continue)
		{
			return Plugin_Handled;
		}
	}
	
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "%t", "MUST_BE_ALIVE");
		return Plugin_Handled;
	}

	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		CReplyToCommand(client, "%t", "STAY_ON_GROUND");
		return Plugin_Handled;
	}
	
	if (GetEntProp(client, Prop_Send, "m_bIsScoped"))
	{
		CReplyToCommand(client, "%t", "SCOPE_DETECTED");
		return Plugin_Handled;
	}

	if (CooldownTimers[client])
	{
		CReplyToCommand(client, "%t", "COOLDOWN_EMOTES");
		return Plugin_Handled;
	}

	if (StrEqual(anim1, ""))
	{
		CReplyToCommand(client, "%t", "AMIN_1_INVALID");
		return Plugin_Handled;
	}

	if (g_iEmoteEnt[client])
		StopEmote(client);

	if (GetEntityMoveType(client) == MOVETYPE_NONE)
	{
		CReplyToCommand(client, "%t", "CANNOT_USE_NOW");
		return Plugin_Handled;
	}

	int EmoteEnt = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(EmoteEnt))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		WeaponBlock(client);

		float vec[3], ang[3];
		GetClientAbsOrigin(client, vec);
		GetClientAbsAngles(client, ang);
		
		g_fLastPosition[client] = vec;
		g_fLastAngles[client] = ang;

		char emoteEntName[16];
		FormatEx(emoteEntName, sizeof(emoteEntName), "emoteEnt%i", GetRandomInt(1000000, 9999999));
		
		DispatchKeyValue(EmoteEnt, "targetname", emoteEntName);
		DispatchKeyValue(EmoteEnt, "model", "models/player/custom_player/kodua/fortnite_emotes_v2.mdl");
		DispatchKeyValue(EmoteEnt, "solid", "0");
		DispatchKeyValue(EmoteEnt, "rendermode", "10");

		ActivateEntity(EmoteEnt);
		DispatchSpawn(EmoteEnt);

		TeleportEntity(EmoteEnt, vec, ang, NULL_VECTOR);
		
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "SetParent", client, client, 0);

		g_iEmoteEnt[client] = EntIndexToEntRef(EmoteEnt);

		int enteffects = GetEntProp(client, Prop_Send, "m_fEffects");
		enteffects |= 1; /* This is EF_BONEMERGE */
		enteffects |= 16; /* This is EF_NOSHADOW */
		enteffects |= 64; /* This is EF_NORECEIVESHADOW */
		enteffects |= 128; /* This is EF_BONEMERGE_FASTCULL */
		enteffects |= 512; /* This is EF_PARENT_ANIMATES */
		SetEntProp(client, Prop_Send, "m_fEffects", enteffects);

		//Sound

		if (g_cvEmotesSounds.BoolValue && !StrEqual(soundName, ""))
		{
			int EmoteSoundEnt = CreateEntityByName("info_target");
			if (IsValidEntity(EmoteSoundEnt))
			{
				char soundEntName[16];
				FormatEx(soundEntName, sizeof(soundEntName), "soundEnt%i", GetRandomInt(1000000, 9999999));

				DispatchKeyValue(EmoteSoundEnt, "targetname", soundEntName);

				DispatchSpawn(EmoteSoundEnt);

				vec[2] += 72.0;
				TeleportEntity(EmoteSoundEnt, vec, NULL_VECTOR, NULL_VECTOR);

				SetVariantString(emoteEntName);
				AcceptEntityInput(EmoteSoundEnt, "SetParent");

				g_iEmoteSoundEnt[client] = EntIndexToEntRef(EmoteSoundEnt);

				//Formatting sound path

				char soundNameBuffer[64];

				if (StrEqual(soundName, "ninja_dance_01") || StrEqual(soundName, "dance_soldier_03"))
				{
					int randomSound = GetRandomInt(0, 1);
					if(randomSound)
					{
						soundNameBuffer = "ninja_dance_01";
					} else
					{
						soundNameBuffer = "dance_soldier_03";
					}
				} else
				{
					FormatEx(soundNameBuffer, sizeof(soundNameBuffer), "%s", soundName);
				}

				if (isLooped)
				{
					FormatEx(g_sEmoteSound[client], PLATFORM_MAX_PATH, "*/kodua/fortnite_emotes/%s.wav", soundNameBuffer);
				} else
				{
					FormatEx(g_sEmoteSound[client], PLATFORM_MAX_PATH, "kodua/fortnite_emotes/%s.mp3", soundNameBuffer);
				}

				EmitSoundToAll(g_sEmoteSound[client], EmoteSoundEnt, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, g_cvSoundVolume.FloatValue, _, _, vec, _, _, _);
			}
		} else
		{
			g_sEmoteSound[client] = "";
		}
		
		if (StrEqual(anim2, "none", false))
		{
			
			HookSingleEntityOutput(EmoteEnt, "OnAnimationDone", EndAnimation, true);
		} else
		{
			SetVariantString(anim2);
			AcceptEntityInput(EmoteEnt, "SetDefaultAnimation", -1, -1, 0);
		}

		SetVariantString(anim1);
		AcceptEntityInput(EmoteEnt, "SetAnimation", -1, -1, 0);

		SetCam(client);

		g_bClientDancing[client] = true;
		
		if(g_cvHidePlayers.BoolValue)
		{
			for(int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client) && !g_bHooked[i])
				{
					SDKHook(i, SDKHook_SetTransmit, SetTransmit);
					g_bHooked[i] = true;
				}
		}

		if (g_cvCooldown.FloatValue > 0.0)
		{
			CooldownTimers[client] = CreateTimer(g_cvCooldown.FloatValue, ResetCooldown, client);
		}
		
		if(g_EmoteForward != null)
		{
			Call_StartForward(g_EmoteForward);
			Call_PushCell(client);
			Call_Finish();
		}
	}
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (g_bClientDancing[client] && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		StopEmote(client);
	}

	static int iAllowedButtons = IN_BACK | IN_FORWARD | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK | IN_SPEED | IN_SCORE;

	if (iButtons == 0)
		return Plugin_Continue;

	if (g_iEmoteEnt[client] == 0)
		return Plugin_Continue;

	if ((iButtons & iAllowedButtons) && !(iButtons &~ iAllowedButtons)) 
		return Plugin_Continue;

	StopEmote(client);

	return Plugin_Continue;
}

void EndAnimation(const char[] output, int caller, int activator, float delay) 
{
	if (caller > 0)
	{
		activator = GetEmoteActivator(EntIndexToEntRef(caller));
		StopEmote(activator);
	}
}

int GetEmoteActivator(int iEntRefDancer)
{
	if (iEntRefDancer == INVALID_ENT_REFERENCE)
		return 0;
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (g_iEmoteEnt[i] == iEntRefDancer) 
		{
			return i;
		}
	}
	return 0;
}

void StopEmote(int client)
{
	if (!g_iEmoteEnt[client])
		return;

	int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
	if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
	{
		char emoteEntName[50];
		GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
		DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(iEmoteEnt, "FireUser1");
		
		if(g_cvTeleportBack.BoolValue)
			TeleportEntity(client, g_fLastPosition[client], g_fLastAngles[client], NULL_VECTOR);
		
		ResetCam(client);
		WeaponUnblock(client);
		SetEntityMoveType(client, MOVETYPE_WALK);

		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	} else
	{
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	}

	if (g_iEmoteSoundEnt[client])
	{
		int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);

		if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
		{
			StopSound(iEmoteSoundEnt, SNDCHAN_AUTO, g_sEmoteSound[client]);
			AcceptEntityInput(iEmoteSoundEnt, "Kill");
			g_iEmoteSoundEnt[client] = 0;
		} else
		{
			g_iEmoteSoundEnt[client] = 0;
		}
	}
}

void TerminateEmote(int client)
{
	if (!g_iEmoteEnt[client])
		return;

	int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
	if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
	{
		char emoteEntName[50];
		GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
		DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(iEmoteEnt, "FireUser1");

		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	} else
	{
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	}

	if (g_iEmoteSoundEnt[client])
	{
		int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);

		if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
		{
			StopSound(iEmoteSoundEnt, SNDCHAN_AUTO, g_sEmoteSound[client]);
			AcceptEntityInput(iEmoteSoundEnt, "Kill");
			g_iEmoteSoundEnt[client] = 0;
		} else
		{
			g_iEmoteSoundEnt[client] = 0;
		}
	}
}

void WeaponBlock(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
	SDKHook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
	
	if(g_cvHideWeapons.BoolValue)
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		
	int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(iEnt != -1)
	{
		g_iWeaponHandEnt[client] = EntIndexToEntRef(iEnt);
		
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
	}
}

void WeaponUnblock(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
	SDKUnhook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
	
	//Even if are not activated, there will be no errors
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	
	if(GetEmotePeople() == 0)
	{
		for(int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && g_bHooked[i])
			{
				SDKUnhook(i, SDKHook_SetTransmit, SetTransmit);
				g_bHooked[i] = false;
			}
	}
	
	if(IsPlayerAlive(client) && g_iWeaponHandEnt[client] != INVALID_ENT_REFERENCE)
	{
		int iEnt = EntRefToEntIndex(g_iWeaponHandEnt[client]);
		if(iEnt != INVALID_ENT_REFERENCE)
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iEnt);
		}
	}
	
	g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;
}

Action WeaponCanUseSwitch(int client, int weapon)
{
	return Plugin_Stop;
}

void OnPostThinkPost(int client)
{
	SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

public Action SetTransmit(int entity, int client) 
{ 
	if(g_bClientDancing[client] && IsPlayerAlive(client) && GetClientTeam(client) != GetClientTeam(entity)) return Plugin_Handled;
	
	return Plugin_Continue; 
} 

void SetCam(int client)
{
	ClientCommand(client, "cam_collision 0");
	ClientCommand(client, "cam_idealdist 100");
	ClientCommand(client, "cam_idealpitch 0");
	ClientCommand(client, "cam_idealyaw 0");
	ClientCommand(client, "thirdperson");
}

void ResetCam(int client)
{
	ClientCommand(client, "firstperson");
	ClientCommand(client, "cam_collision 1");
	ClientCommand(client, "cam_idealdist 150");
}

Action ResetCooldown(Handle timer, any client)
{
	CooldownTimers[client] = null;
}

void OpenMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu);

	char title[65];
	Format(title, sizeof(title), "Emotes & Dances Main Menu:");
	menu.SetTitle(title);	

	AddMenuItem(menu, "random_emote", 	"Play Random Emote");
	AddMenuItem(menu, "random_dance", 	"Play Random Dance");
	AddMenuItem(menu, "emote_list", 	"Emotes List");
	AddMenuItem(menu, "dance_list", 	"Dances List");
	AddMenuItem(menu, "qa_menu", 		"Edit Quick Access Menu");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
 
	return;
}

int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int client = param1;
			
			switch (param2)
			{
				case 0: 
				{
					RandomEmote(client);
					OpenMainMenu(client);
				}		
				
				case 1: 
				{
					RandomDance(client);
					OpenMainMenu(client);
				}	
				
				case 2: OpenEmotesMenu(client);
				case 3: DancesMenu(client);
				case 4: OpenQuickAccessMenu(client);
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void OpenEmotesMenu(int client)
{
	Menu menu = new Menu(MenuHandlerEmotes);
	
	char szDisplayName[65];
	menu.SetTitle("Emotes Menu");
	char szInfo[10];
	
	for(int i; i < sizeof g_szEmoteName; i++)
	{
		FormatEx(szDisplayName, sizeof szDisplayName, "%s (%d)", g_szEmoteName[i], i + 1);
		FormatEx(szInfo, sizeof szInfo, "%d", i);
		menu.AddItem(szInfo, szDisplayName);
	}
	
	/*
	AddTranslatedMenuItem(menu, "1", "Emote_Fonzie_Pistol", client);
	AddTranslatedMenuItem(menu, "2", "Emote_Bring_It_On", client);
	AddTranslatedMenuItem(menu, "3", "Emote_ThumbsDown", client);
	AddTranslatedMenuItem(menu, "4", "Emote_ThumbsUp", client);
	AddTranslatedMenuItem(menu, "5", "Emote_Celebration_Loop", client);
	AddTranslatedMenuItem(menu, "6", "Emote_BlowKiss", client);
	AddTranslatedMenuItem(menu, "7", "Emote_Calculated", client);
	AddTranslatedMenuItem(menu, "8", "Emote_Confused", client);	
	AddTranslatedMenuItem(menu, "9", "Emote_Chug", client);
	AddTranslatedMenuItem(menu, "10", "Emote_Cry", client);
	AddTranslatedMenuItem(menu, "11", "Emote_DustingOffHands", client);
	AddTranslatedMenuItem(menu, "12", "Emote_DustOffShoulders", client);	
	AddTranslatedMenuItem(menu, "13", "Emote_Facepalm", client);
	AddTranslatedMenuItem(menu, "14", "Emote_Fishing", client);
	AddTranslatedMenuItem(menu, "15", "Emote_Flex", client);
	AddTranslatedMenuItem(menu, "16", "Emote_golfclap", client);	
	AddTranslatedMenuItem(menu, "17", "Emote_HandSignals", client);
	AddTranslatedMenuItem(menu, "18", "Emote_HeelClick", client);
	AddTranslatedMenuItem(menu, "19", "Emote_Hotstuff", client);
	AddTranslatedMenuItem(menu, "20", "Emote_IBreakYou", client);	
	AddTranslatedMenuItem(menu, "21", "Emote_IHeartYou", client);
	AddTranslatedMenuItem(menu, "22", "Emote_Kung-Fu_Salute", client);
	AddTranslatedMenuItem(menu, "23", "Emote_Laugh", client);
	AddTranslatedMenuItem(menu, "24", "Emote_Luchador", client);	
	AddTranslatedMenuItem(menu, "25", "Emote_Make_It_Rain", client);
	AddTranslatedMenuItem(menu, "26", "Emote_NotToday", client);
	AddTranslatedMenuItem(menu, "27", "Emote_RockPaperScissor_Paper", client);
	AddTranslatedMenuItem(menu, "28", "Emote_RockPaperScissor_Rock", client);	
	AddTranslatedMenuItem(menu, "29", "Emote_RockPaperScissor_Scissor", client);
	AddTranslatedMenuItem(menu, "30", "Emote_Salt", client);
	AddTranslatedMenuItem(menu, "31", "Emote_Salute", client);
	AddTranslatedMenuItem(menu, "32", "Emote_SmoothDrive", client);	
	AddTranslatedMenuItem(menu, "33", "Emote_Snap", client);
	AddTranslatedMenuItem(menu, "34", "Emote_StageBow", client);
	AddTranslatedMenuItem(menu, "35", "Emote_Wave2", client);
	AddTranslatedMenuItem(menu, "36", "Emote_Yeet", client);
	*/

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandlerEmotes(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				int iParam2 = StringToInt(info);
				
				CreateEmoteFromIndex(client, iParam2);
			}
			menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				OpenMainMenu(client);
			}
		}
	}
}

void CreateEmoteFromIndex(int client, int i)
{
	if(i < sizeof(g_szEmoteName))
	{
		// Emotes
		CreateEmote(client, g_szEmoteAnim1[i], g_szEmoteAnim2[i], g_szEmoteSoundName[i], g_bEmoteRepeating[i]);
	}
	
	else
	{
		// Dances
		int j = i - sizeof(g_szEmoteName);
		CreateEmote(client, g_szDanceAnim1[j], g_szDanceAnim2[j], g_szDanceSoundName[j], g_bDanceRepeating[j]);
	}
}

Action DancesMenu(int client)
{
	Menu menu = new Menu(MenuHandlerDances);
	
	char szDisplayName[65];
	menu.SetTitle("Dances Menu");
	char szInfo[10];
	
	for(int i; i < sizeof g_szDanceName; i++)
	{
		FormatEx(szDisplayName, sizeof szDisplayName, "%s (%d)", g_szDanceName[i], sizeof(g_szEmoteName) + i + 1);
		FormatEx(szInfo, sizeof szInfo, "%d", sizeof(g_szEmoteName) + i);
		menu.AddItem(szInfo, szDisplayName);
	}
	
	/*AddTranslatedMenuItem(menu, "1", "DanceMoves", client);
	AddTranslatedMenuItem(menu, "2", "Emote_Mask_Off_Intro", client);
	AddTranslatedMenuItem(menu, "3", "Emote_Zippy_Dance", client);
	AddTranslatedMenuItem(menu, "4", "ElectroShuffle", client);
	AddTranslatedMenuItem(menu, "5", "Emote_AerobicChamp", client);
	AddTranslatedMenuItem(menu, "6", "Emote_Bendy", client);
	AddTranslatedMenuItem(menu, "7", "Emote_BandOfTheFort", client);
	AddTranslatedMenuItem(menu, "8", "Emote_Boogie_Down_Intro", client);	
	AddTranslatedMenuItem(menu, "9", "Emote_Capoeira", client);
	AddTranslatedMenuItem(menu, "10", "Emote_Charleston", client);
	AddTranslatedMenuItem(menu, "11", "Emote_Chicken", client);
	AddTranslatedMenuItem(menu, "12", "Emote_Dance_NoBones", client);	
	AddTranslatedMenuItem(menu, "13", "Emote_Dance_Shoot", client);
	AddTranslatedMenuItem(menu, "14", "Emote_Dance_SwipeIt", client);
	AddTranslatedMenuItem(menu, "15", "Emote_Dance_Disco_T3", client);
	AddTranslatedMenuItem(menu, "16", "Emote_DG_Disco", client);	
	AddTranslatedMenuItem(menu, "17", "Emote_Dance_Worm", client);
	AddTranslatedMenuItem(menu, "18", "Emote_Dance_Loser", client);
	AddTranslatedMenuItem(menu, "19", "Emote_Dance_Breakdance", client);
	AddTranslatedMenuItem(menu, "20", "Emote_Dance_Pump", client);	
	AddTranslatedMenuItem(menu, "21", "Emote_Dance_RideThePony", client);
	AddTranslatedMenuItem(menu, "22", "Emote_Dab", client);
	AddTranslatedMenuItem(menu, "23", "Emote_EasternBloc_Start", client);
	AddTranslatedMenuItem(menu, "24", "Emote_FancyFeet", client);	
	AddTranslatedMenuItem(menu, "25", "Emote_FlossDance", client);
	AddTranslatedMenuItem(menu, "26", "Emote_FlippnSexy", client);
	AddTranslatedMenuItem(menu, "27", "Emote_Fresh", client);
	AddTranslatedMenuItem(menu, "28", "Emote_GrooveJam", client);	
	AddTranslatedMenuItem(menu, "29", "Emote_guitar", client);
	AddTranslatedMenuItem(menu, "30", "Emote_Hillbilly_Shuffle_Intro", client);
	AddTranslatedMenuItem(menu, "31", "Emote_Hiphop_01", client);
	AddTranslatedMenuItem(menu, "32", "Emote_Hula_Start", client);	
	AddTranslatedMenuItem(menu, "33", "Emote_InfiniDab_Intro", client);
	AddTranslatedMenuItem(menu, "34", "Emote_Intensity_Start", client);
	AddTranslatedMenuItem(menu, "35", "Emote_IrishJig_Start", client);
	AddTranslatedMenuItem(menu, "36", "Emote_KoreanEagle", client);	
	AddTranslatedMenuItem(menu, "37", "Emote_Kpop_02", client);
	AddTranslatedMenuItem(menu, "38", "Emote_LivingLarge", client);
	AddTranslatedMenuItem(menu, "39", "Emote_Maracas", client);
	AddTranslatedMenuItem(menu, "40", "Emote_PopLock", client);
	AddTranslatedMenuItem(menu, "41", "Emote_PopRock", client);
	AddTranslatedMenuItem(menu, "42", "Emote_RobotDance", client);
	AddTranslatedMenuItem(menu, "43", "Emote_T-Rex", client);	
	AddTranslatedMenuItem(menu, "44", "Emote_TechnoZombie", client);
	AddTranslatedMenuItem(menu, "45", "Emote_Twist", client);
	AddTranslatedMenuItem(menu, "46", "Emote_WarehouseDance_Start", client);
	AddTranslatedMenuItem(menu, "47", "Emote_Wiggle", client);
	AddTranslatedMenuItem(menu, "48", "Emote_Youre_Awesome", client);
	*/	

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

int MenuHandlerDances(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				int iParam2 = StringToInt(info);
				CreateEmoteFromIndex(client, iParam2);
			}
			
			menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				OpenMainMenu(client);
			}
		}
	}
}

Action RandomEmote(int client)
{
	int i = GetRandomInt(0, sizeof(g_szEmoteName) - 1);
	CreateEmote(client, g_szEmoteAnim1[i], g_szEmoteAnim2[i], g_szEmoteSoundName[i], g_bEmoteRepeating[i]);
}

Action RandomDance(int client)
{
	int i = GetRandomInt(0, sizeof(g_szDanceName) - 1);
	CreateEmote(client, g_szDanceAnim1[i], g_szDanceAnim2[i], g_szDanceSoundName[i], g_bDanceRepeating[i]);
}

Action Command_Admin_Emotes(int client, int args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	int amount=1;
	if (args > 1)
	{
		char arg2[3];
		GetCmdArg(2, arg2, sizeof(arg2));
		StringToIntEx(arg2, amount);
		
		if (amount < 1 || amount >= ( sizeof(g_szEmoteName) + sizeof(g_szDanceName) ) )
		{
			CReplyToCommand(client, "%t", "INVALID_EMOTE_ID");
			return Plugin_Handled;
		}
		
		amount -= 1;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	
	for (int i = 0; i < target_count; i++)
	{
		PerformEmote(target_list[i], amount);
	}	
	
	return Plugin_Handled;
}

void PerformEmote(int target, int iIndex)
{
	CreateEmoteFromIndex(target, iIndex);
}

void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_setemotes", AdminMenu_Emotes, player_commands, "sm_setemotes", ADMFLAG_SLAY);
	}
}

void AdminMenu_Emotes(TopMenu topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "EMOTE_PLAYER", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayEmotePlayersMenu(param);
	}
}

void DisplayEmotePlayersMenu(int client)
{
	Menu menu = new Menu(MenuHandler_EmotePlayers);
	
	char title[65];
	Format(title, sizeof(title), "%T:", "EMOTE_PLAYER", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_EmotePlayers(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			CPrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			CPrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			g_EmotesTarget[param1] = userid;
			DisplayEmotesAmountMenu(param1);
			return;	// Return, because we went to a new menu and don't want the re-draw to occur.
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayEmotePlayersMenu(param1);
		}
	}
	
	return;
}

void DisplayEmotesAmountMenu(int client)
{
	Menu menu = new Menu(MenuHandler_EmotesAmount);
	
	char szDisplayName[65];
	Format(szDisplayName, sizeof(szDisplayName), "%T: %N", "SELECT_EMOTE", client, GetClientOfUserId(g_EmotesTarget[client]));
	menu.SetTitle(szDisplayName);
	menu.ExitBackButton = true;

	char szInfo[10];
	
	for(int i; i < sizeof g_szEmoteName; i++)
	{
		FormatEx(szDisplayName, sizeof szDisplayName, "%s (%d)", g_szEmoteName[i], i + 1);
		FormatEx(szInfo, sizeof szInfo, "%d", i);
		menu.AddItem(szInfo, szDisplayName);
	}
	
	for(int i; i < sizeof g_szDanceName; i++)
	{
		FormatEx(szDisplayName, sizeof szDisplayName, "%s (%d)", g_szDanceName[i], sizeof(g_szEmoteName) + i + 1);
		FormatEx(szInfo, sizeof szInfo, "%d", sizeof(g_szEmoteName) + i);
		menu.AddItem(szInfo, szDisplayName);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_EmotesAmount(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int amount;
		int target;
		
		menu.GetItem(param2, info, sizeof(info));
		amount = StringToInt(info);

		if ((target = GetClientOfUserId(g_EmotesTarget[param1])) == 0)
		{
			CPrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			CPrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			PerformEmote(target, amount);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayEmotePlayersMenu(param1);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(StrEqual(classname, "trigger_multiple"))
    {
        SDKHook(entity, SDKHook_StartTouch, OnTrigger);
        SDKHook(entity, SDKHook_EndTouch, OnTrigger);
        SDKHook(entity, SDKHook_Touch, OnTrigger);
    }
    else if(StrEqual(classname, "trigger_hurt"))
    {
        SDKHook(entity, SDKHook_StartTouch, OnTrigger);
        SDKHook(entity, SDKHook_EndTouch, OnTrigger);
        SDKHook(entity, SDKHook_Touch, OnTrigger);
    }
    else if(StrEqual(classname, "trigger_push"))
    {
        SDKHook(entity, SDKHook_StartTouch, OnTrigger);
        SDKHook(entity, SDKHook_EndTouch, OnTrigger);
        SDKHook(entity, SDKHook_Touch, OnTrigger);
    }
}

public Action OnTrigger(int entity, int other)
{
    if (0 < other <= MaxClients)
    {
        StopEmote(other);
    }
    
    return Plugin_Continue;
} 

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

int GetEmotePeople()
{
	int count;
	for(int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && g_bClientDancing[i])
			count++;
			
	return count;
}
