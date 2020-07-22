#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "DaysAPI: Farmer Day", 
	author = "Khalid", 
	description = "", 
	version = "1.0", 
	url = ""
};

char MODEL_CHICKEN[] = "models/chicken/chicken.mdl";
char MODEL_CHICKEN_ZOMBIE[] = "models/chicken/chicken_zombie.mdl";
char SOUND_SPAWN[] = "player/pl_respawn.wav";

ArrayList g_hArrayOrigins = null;
int g_hHighlightedSpawnBox[MAXPLAYERS] = -1;

float g_vPotentialSpawnPoint[MAXPLAYERS][2][3]; // 3 points

stock void ClearMapSpawnBoxes()
{
	g_hArrayOrigins.Clear();
}

stock int GetSpawnBoxCount()
{
	return (g_hArrayOrigins.Length);
}

stock void EraseSpawnBox(int iBoxIndex)
{
	g_hArrayOrigins.Erase(iBoxIndex);
}

stock void GetSpawnBoxOrigins(int iBoxIndex, float vBoxOrigin[3], float vMins[3], float vMaxs[3])
{
	float flArray[9];
	g_hArrayOrigins.GetArray(iBoxIndex, flArray, 9);
	
	for (int i; i < 3; i++)
	{
		vBoxOrigin[i] = flArray[(i * 3) + 0];
		vBoxOrigin[i] = flArray[(i * 3) + 1];
		vBoxOrigin[i] = flArray[(i * 3) + 2];
	}
	
	for (int i = 3; i < 6; i++)
	{
		vMins[i] = flArray[(i * 3) + 0];
		vMins[i] = flArray[(i * 3) + 1];
		vMins[i] = flArray[(i * 3) + 2];
	}
	
	for (int i = 6; i < 9; i++)
	{
		vMaxs[i] = flArray[(i * 3) + 0];
		vMaxs[i] = flArray[(i * 3) + 1];
		vMaxs[i] = flArray[(i * 3) + 2];
	}
}

stock int AddSpawnBoxOrigins(float vBoxOrigin[3], float vMins[3], float vMaxs[3])
{
	float flArray[9];
	for (int i; i < 3; i++)
	{
		flArray[(i * 3) + 0] = vBoxOrigin[i];
		flArray[(i * 3) + 1] = vBoxOrigin[i];
		flArray[(i * 3) + 2] = vBoxOrigin[i];
	}
	
	for (int i = 3; i < 6; i++)
	{
		flArray[(i * 3) + 0] = vMins[i];
		flArray[(i * 3) + 1] = vMins[i];
		flArray[(i * 3) + 2] = vMins[i];
	}
	
	for (int i = 6; i < 9; i++)
	{
		flArray[(i * 3) + 0] = vMaxs[i];
		flArray[(i * 3) + 1] = vMaxs[i];
		flArray[(i * 3) + 2] = vMaxs[i];
	}
	
	g_hArrayOrigins.PushArray(flArray);
	return g_hArrayOrigins.Length;
}

public void OnPluginStart()
{
	g_hArrayOrigins = new ArrayList(6);
	// chickn spawn box - csb
	RegAdminCmd("sm_csb", ConCmd_ChickenDay, ADMFLAG_ROOT);
	RegConsoleCmd("point", ConCmd_Point);
}

public void OnMapStart()
{
	g_hHighlightTimer = null;
	ClearMapSpawnBoxes()
	
	ReadSpawnBoxFile();
}

public Action ConCmd_ChickenDay(int client, int argc)
{
	ShowSpawnBoxMenu(client);
}

void ShowSpawnBoxMenu(client)
{
	Menu menu = new Menu(MenuHandler_SpawnBox, MENU_ACTIONS_DEFAULT);
	menu.AddItem("1", "Toggle Highlight Spawn Boxes");
	menu.AddItem("2", "Add New Spawn Box");
	menu.AddItem("3", "Remove Nearest Spawn Box");
	
	#define Item_Highlight	1
	#define Item_Add		2
	#define Item_Remove		3
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_SpawnBox(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return;
	}
	
	if (action == MenuAction_Select)
	{
		char szInfo[5];
		menu.GetItem(param2, szInfo, sizeof szInfo);
		
		switch (StringToInt(szInfo))
		{
			case Item_Highligt:
			{
				g_bHighlight = !g_bHighlight;
				
				if (g_bHighlight)
				{
					g_hHighlightTimer = CreateTimer(1.0, Timer_CreateHighlightingLasers, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
				
				else
				{
					DestroyHandle(g_hHighlightTimer);
				}
				
				ShowSpawnBoxMenu(param1);
			}
			
			case Item_Add:
			{
				StartAddSpawnBoxProcedures(client);
			}
			
			case Item_Remove:
			{
				
			}
		}
	}
}

void ResetAddSpawnBoxVars(int client)
{
	g_iSpawnBoxPointNum[client] = 0;
}

void StartAddSpawnBoxProcedures(int client)
{
	PrintToChat(client, "* You will need to select 3 points to make the spawn box.");
	PrintToChat(client, "* Select the first point");
	ResetAddSpawnBoxVars(client);
	
	ShowPlayerPointSelectMenu(client);
}

bool PlayerAddSpawnBoxPoint(int client, bool bEyePostion)
{
	switch (bEyePosition)
	{
		case true:
		{
			if (!GetEndEyePos(client, g_vPotentialSpawnPoint[client][g_iSpawnBoxPointNum[client]]))
			{
				PrintToChat(client, "* Invalid Position.");
				return false;
			}
		}
		
		// Origin of player
		case false:
		{
			GetClientAbsOrigin(client, g_vPotentialSpawnPoint[client][g_iSpawnBoxPointNum[client]]);
		}
	}
	
	g_iSpawnBoxPointNum[client]++;
	
	if (g_iSpawnBoxPointNum[client] == 2)
	{
		FinalizePlayerAddSpawnBox(client);
		return true;
	}
	
	else
	{
		PrintToChat(client, "* Select another point.");
		ShowPlayerPointSelectMenu(client);
		return false;
	}
	
	return false;
}

void CancelPlayerPointSelect(int client)
{
	g_iSpawnBoxPointNum[client] = 0;
	PrintToChat(client, "* Cancelled");
	ShowSpawnBoxMenu(client);
}

void ShowPlayerPointSelectMenu(client)
{
	Menu menu = new Menu(MenuHandler_PlayerSelectPoint, MENU_ACTIONS_DEFAULT)
	menu.AddItem("endeyepos", "Aim Point");
	menu.AddItem("origin", "Current Point");
	menu.AddItem("cancel", "Cancel");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerSelectPoint(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return;
	}
	
	if (action == MenuAction_Cancel)
	{
		CancelPlayerPointSelect(param1);
		return;
	}
	
	if (action == MenuAction_Select)
	{
		char szInfo[11];
		menu.GetItem(param2, szInfo, sizeof szInfo);
		
		if (StrEqual(szInfo, "endeyepos"))
		{
			PlayerAddSpawnBoxPoint(param1, true);
		}
		
		else if (StrEqual(szInfo, "origin"))
		{
			PlayerAddSpawnBoxPoint(param1, false);
		}
		
		else if (StrEqual(szInfo, "cancel"))
		{
			CancelPlayerPointSelect(param1);
		}
	}
}

void FinalizePlayerAddSpawnBox(int client)
{
	//g_vPotentialSpawnPoint[client][0/2]
	float vOrigin[3], vMins[3], vMaxs[3];
	for (new i; i < 3; i++)
	{
		vOrigin[i] = (g_vPotentialSpawnPoint[client][1][i] + g_vPotentialSpawnPoint[client][2][i]) / 2.0
		
		flDiff = (g_vPotentialSpawnPoint[client][0][i] , g_vPotentialSpawnPoint[client][1][i]) / 2.0
		flDiff = flDiff > 0.0 ? flDiff : -flDiff;
		flMins[i] = flDiff;
		flMaxs[i] = flDiff;
	}
	
	AddSpawnBoxOrigins(vOrigin, vMins, vMaxs);
	
}


public void OnAllPluginsLoaded()
{
	DaysAPI_AddDay(g_szIntName, DayStart_Farmer, DayEnd_Farmer);
	DaysAPI_SetDayInfo(g_szIntName, DayInfo_DisplayName, "Farmer Day");
}

public OnMapStart()
{
	//LoadMapKeyValues();
	
	PrecacheModel(MODEL_CHICKEN, true);
	PrecacheModel(MODEL_CHICKEN_ZOMBIE, true);
	
	PrecacheSound(SOUND_SPAWN, true);
}


public DayStartReturn DayStart_Farmer(any data)
{
	g_bRunning = true;
	CreateChickens();
}

public void DayEnd_Farmer(int[] iWinners, int iCount, any data)
{
	g_bRunning = false;
	RemoveChickens();
	
	//GetDayWinners()
}

bool GetEndEyePos(int client, float vector[3])
{
	float vEyePos[3];
	GetClientEyePosition(client, vEyePos);
	GetClientEyeAngles(client, vector);
	
	TR_TraceRayFilter(vEyePos, vector, MASK_PLAYERSOLID, RayType_Infinite, TraceRayFiler, client);
	
	if (TR_DidHit())
	{
		TR_GetEndPosition(vector);
		return true;
	}
	
	return false;
}

public Action Timer_CreateHighlightingLasers(Handle hTimer, any data)
{
	float vOrigins[3][3];
	int iSize = GetSpawnBoxCount();
	
	float vDrawOrigins[9][3];
	for (int i; i < iSize; i++)
	{
		vOrigins[0][0]
		GetSpawnBoxOrigins(i, vOrigins);
		TE_SetupBeamPoints(vOrigin[0]
		}
	}
	
	/*
//-----COMMANDS-----//
public Action:CMD_SpawnChicken(client, args)
{
	new String:arg[16];
	GetCmdArg(1, arg, sizeof(arg));
	
	if ((args == 0) || (StringToInt(arg) == 0))
	{
		SpawnChicken(client, 0);
	}
	else
	{
		SpawnChicken(client, 1);
	}
	return Plugin_Handled;
}

//-----STOCKS-----//
void SpawnChickens(int iSkin)
{
	const int MAX_CHICKENS = 200;
	float vPos[3];
	float vEndPos[3];
	
	int iCount;
	while(iCount < MAX_CHICKENS)
	{
		vPos[0] = GetRandomFloat(-10000.0, 10000.0);
		vPos[1] = GetRandomFloat(-10000.0, 10000.0);
		vPos[2] = GetRandomFloat(-10000.0, 10000.0);
		
		if(IsValidSpawnOrigin(vPos))
		{
			
		}
	}
	
	GetClientEyePosition(client, eye_pos);
	GetClientEyeAngles(client, eye_ang);
	
	if (TR_DidHit(trace))
	{
		if (TR_GetEntityIndex(trace) == 0)
		{
			new chicken = CreateEntityByName("chicken"); //The Chicken
			if (IsValidEntity(chicken))
			{
				new Float:end_pos[3];
				TR_GetEndPosition(end_pos, trace);
				end_pos[2] = (end_pos[2] + 10.0);
				
				new String:skin[16];
				Format(skin, sizeof(skin), "%i", GetRandomInt(0, 1));
				
				DispatchKeyValue(chicken, "glowenabled", "0"); //Glowing (0-off, 1-on)
				DispatchKeyValue(chicken, "glowcolor", "255 255 255"); //Glowing color (R, G, B)
				DispatchKeyValue(chicken, "rendercolor", "255 255 255"); //Chickens model color (R, G, B)
				DispatchKeyValue(chicken, "modelscale", "1.0"); //Chickens model scale (0.5 smaller, 1.5 bigger chicken, min: 0.1, max: -)
				DispatchKeyValue(chicken, "skin", skin); //Chickens model skin(default white 0, brown is 1)
				DispatchSpawn(chicken);
				
				TeleportEntity(chicken, end_pos, NULL_VECTOR, NULL_VECTOR);
				
				if (type == 0)
				{
					CreateParticle(chicken, 0);
				}
				else
				{
					CreateParticle(chicken, 1);
					SetEntityModel(chicken, MODEL_CHICKEN_ZOMBIE);
					HookSingleEntityOutput(chicken, "OnBreak", OnBreak);
				}
				
				EmitSoundToAll(SOUND_SPAWN, chicken);
				ReplyToCommand(client, "%t", "ChickenSpawned");
			}
		}
		else
		{
			ReplyToCommand(client, "%t", "CantSpawnHere");
		}
	}
}

CreateParticle(entity, type)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		if (type == 0)
		{
			DispatchKeyValue(particle, "effect_name", "chicken_gone_feathers");
		}
		else
		{
			DispatchKeyValue(particle, "effect_name", "chicken_gone_feathers_zombie");
		}
		
		DispatchKeyValue(particle, "angles", "-90 0 0");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		CreateTimer(5.0, Timer_KillEntity, EntIndexToEntRef(particle));
	}
}

bool:IsClientValid(client)
{
	return ((client > 0) && (client <= MaxClients));
}

//-----SINGLEOUTPUTS-----//
public OnBreak(const String:output[], caller, activator, Float:delay)
{
	CreateParticle(caller, 1);
}

//-----TIMERS-----//
public Action:Timer_KillEntity(Handle:timer, any:reference)
{
	new entity = EntRefToEntIndex(reference);
	if (entity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

//-----FILTERS-----//
public bool:Filter_DontHitPlayers(entity, contentsMask, any:data)
{
	return !((entity > 0) && (entity <= MaxClients));
} 

*/
	
	/*
void FinalizePlayerAddSpawnBox(int client)
{
	
	float vOrigin[3], vMins[3], vMaxs[3];
	
	// Center is the mid point.
	vOrigin[0] = (g_vPotentialSpawnPoint[client][0][0] + g_vPotentialSpawnPoint[client][1][0]) / 2.0;
	vOrigin[1] = (g_vPotentialSpawnPoint[client][0][1] + g_vPotentialSpawnPoint[client][1][1]) / 2.0;
	vOrigin[2] = (g_vPotentialSpawnPoint[client][0][2] + g_vPotentialSpawnPoint[client][1][2]) / 2.0;
	
	// Instead of doing a new coordinate system .. this is much much much much easier
	// Get the shortest distance between the first two points and the third point.
	
	// Set the height equal to one of the others;
	// (Doing this we will get the shortest distance between the third point and (one) of the other
	// two points (This is really a hack)
	g_vPotentialSpawnPoint[client][2][2] = g_vPotentialSpawnPoint[client][0][2];
	
	float flDistance1, flDistance2, flDistance;
	flDistance1 =  GetVectorDistance(g_vPotentialSpawnPoint[client][0], g_vPotentialSpawnPoint[client][2]);
	flDistance2 = GetVectorDistance(g_vPotentialSpawnPoint[client][1], g_vPotentialSpawnPoint[client][2]);
	
	int iPoint;
	if(flDistance1 > flDistance2)
	{
		flDistance = flDistance2 / 2.0;
		iPoint = 0;
	}
	
	else
	{
		flDistance = flDistance1 / 2.0;
		iPoint = 1;
	}
	
	// Make a vector between the third point, and whichever that has the shortest distance (if condition above)
	// in the direction of the third point
	float vVector[3];
	for (int i; i < 3; i++)
	{
		vVector[i] = g_vPotentialSpawnPoint[client][2][i] - g_vPoitentialSpawnPoint[client][iPoint][i];
	}
	
	// Normalize and scale so that the magnitude is the distance to the origin.
	NormalizeVector(vVector, vVector);
	ScaleVector(vVector, flDistance);
	
	// Move the origin
	// And now we have it;
	AddVectors(vOrigin, vVector, vOrigin);
	
	vMins[0] = GetVectorDistance(g_vPotentialSpawnPoint[client][0], g_vPotentialSpawnPoint[client][1]);
	vMins[1] = GetVectorDistance(g_vPotentialSpawnPoint[client][1], g_vPotentialSpawnPoint[client][1]);
}*/