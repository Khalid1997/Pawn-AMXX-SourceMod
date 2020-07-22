#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

Menu hMenu;
Menu hEffectsMenu;

int g_iTotalPoints;

enum
{
	Menu_ChoosePoint,
	Menu_TraceEyePoint,
	Menu_PointEffects,
	Menu_PermanentEffects,
	Menu_CheckPoints,
	Menu_ShowPoints,
	Menu_PrepareTest
};

ArrayList hPointPositions;
ArrayList hPointEffects;

#define EFFECT_DELAY 0.5

enum	(<<=1)
{
	Effect_Ring,
	Effect_Sparks,
	Effect_Explosion,
	Effect_Energy_Splash,
	Effect_BeamFollow
};

#define Effect_Count 5

bool g_bGotEntity = false;
bool g_bRunning = false;
int g_iLastEnt;
bool g_bShowPoints = false;

bool g_bEffectMenu_All;
int g_iAllEffects;

int g_iCurrentExpectedPoint;
int g_iChosenMenuPoint;

public void OnPluginStart()
{
	//RegConsoleCmd("sm_save", SaveToFile);
	//RegConsoleCmd("sm_load", LoadFromFile);
	//RegConsoleCmd("sm_point", GetClosestPoint);
	
	hPointPositions = CreateArray(3);
	hPointEffects = CreateArray(1);
	
	hMenu = CreateMenu(MenuHandler_Main, MENU_ACTIONS_DEFAULT);
	
	AddMenuItem(hMenu, "0", "Point: 0");
	AddMenuItem(hMenu, "1", "Trace Eye Point");
	AddMenuItem(hMenu, "2", "Effects:");
	AddMenuItem(hMenu, "3", "Permanent Effects");
	AddMenuItem(hMenu, "4", "Check Points");
	AddMenuItem(hMenu, "5", "Show Points: ");
	AddMenuItem(hMenu, "6", "Running test");
	
	hEffectsMenu = CreateMenu(MenuHandler_EffectMenu, MENU_ACTIONS_ALL);
	
	AddMenuItem(hEffectsMenu, "0", "Ring");
	AddMenuItem(hEffectsMenu, "1", "Sparks");
	AddMenuItem(hEffectsMenu, "2", "Explosion");
	AddMenuItem(hEffectsMenu, "3", "Energy Splash");
	AddMenuItem(hEffectsMenu, "4", "Beam Follow");
	
	RegConsoleCmd("sm_menu", ConCmd_DisplayMenu);
}

public Action ConCmd_DisplayMenu(int client, int iArgs)
{
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_EffectMenu(Menu menu, MenuAction action, int param1, int param2)
{
	
}

public int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		return 0;
	}
	
	if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	
	if(action == MenuAction_DisplayItem)
	{
		char szInfo[3];
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		int iIndex = StringToInt(szInfo);
		
		if(iIndex == Menu_ChoosePoint)
		{
			char szFormat[25];
			FormatEx(szFormat, sizeof szFormat, "Point: %d", g_iChosenMenuPoint + 1);
			
			return RedrawMenuItem(szFormat);
		}
		
		if(iIndex == Menu_PointEffects || iIndex == Menu_PermanentEffects)
		{
			char szFormat[25];
			//FormatEffectString(szFormat, sizeof szFormat);
			
			return 0;//RedrawMenuItem(szFormat);
		}
		
		if(iIndex == Menu_ShowPoints)
		{
			char szFormat[25];
			FormatEx(szFormat, sizeof szFormat, "Show Point: %s", g_bShowPoints ? "On" : "Off" );
			
			return RedrawMenuItem(szFormat);
		}
		
		return 0;
	}
	
	if(action == MenuAction_Select)
	{
		char szInfo[3];
		GetMenuItem(menu, param2, szInfo, sizeof szInfo);
		
		int iIndex = StringToInt(szInfo);
		
		bool bDisplayAgain = true;
		
		switch(iIndex)
		{
			case Menu_PrepareTest:
			{
				g_bRunning = true;
				g_iLastEnt = 0;
				g_bGotEntity = false;
				g_iCurrentExpectedPoint = 0;
				
				PrintToChat(param1, "Started");
				//g_bShowPoints = false;
			}
			
			case Menu_ChoosePoint:
			{
				Menu hPointMenu = MakeChoosePointMenu();
				DisplayMenu(hPointMenu, param1, MENU_TIME_FOREVER);
				
				bDisplayAgain = false;
			}
			
			case Menu_TraceEyePoint:
			{
				float vOrigin[3], vAngles[3];
				
				GetClientAbsOrigin(param1, vOrigin);
				GetClientEyeAngles(param1, vAngles);
				
				TR_TraceRayFilter(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceFilterCallback, param1);
				
				if(!TR_DidHit())
				{
					PrintToChat(param1, "Did not hit anything... ?");
				}
				
				else
				{
					TR_GetEndPosition(vOrigin);
					SetArrayArray(hPointPositions, g_iChosenMenuPoint, vOrigin);
					
					PrintToServer("Traced to %0.2f %0.2f %0.2f", vOrigin[0], vOrigin[1], vOrigin[2]);
				}
			}
			
			case Menu_PointEffects:
			{
				//g_iChosenPoint = g_iMenuPoint;
				g_bEffectMenu_All = false;
				DisplayMenu(hEffectsMenu, param1, MENU_TIME_FOREVER);
			}
			
			case Menu_PermanentEffects:
			{
				g_bEffectMenu_All = true;
				DisplayMenu(hEffectsMenu, param1, MENU_TIME_FOREVER);
			}
			
			case Menu_CheckPoints:
			{
				int iSize = GetArraySize(hPointPositions) - 1; // Skip last point
				float vOriginFirst[3];
				float vOriginSecond[3];
				
				int i = 0;
				int iFailedPoints[200];
				int j;
				
				while(i++ < iSize)
				{
					GetArrayArray(hPointPositions, i, vOriginFirst, 3);
					GetArrayArray(hPointPositions, i + 1, vOriginSecond, 3);
					
					TR_TraceRay(vOriginFirst, vOriginSecond, MASK_SOLID, RayType_EndPoint);
					
					if(TR_DidHit())
					{
						iFailedPoints[j++] = i;
					}
				}
				
				if(j > 0)
				{
					for(i = 0; i < j; i++)
					{
						PrintToChat(param1, "Failed point: %d and point %d", iFailedPoints[i], iFailedPoints[i] + 1);
					}
				}
				
				else
				{
					PrintToChat(param1, "All points have empty space lines between them. A nade can move freely without touching anything else.");
				}
			}
		}
		
		if(bDisplayAgain)
		{
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

Menu MakeChoosePointMenu()
{
	Menu menu = CreateMenu(MenuHandler_ChoosePoint, MENU_ACTIONS_DEFAULT | MenuAction_Cancel);
	
	int iSize = GetArraySize(hPointPositions);
	char szInfo[3], szDisplayName[25];
	
	AddMenuItem(menu, "-1", "Add new point");
	
	for(int i; i < iSize; i++)
	{
		FormatEx(szDisplayName, sizeof szDisplayName, "Point: %d", i + 1);
		FormatEx(szInfo, sizeof szInfo, "%d", i);
		
		AddMenuItem(menu, szInfo, szDisplayName);
	}
	
	return menu;
}

public int MenuHandler_ChoosePoint(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		//delete menu;
	}
	
	if(action == MenuAction_Cancel)
	{
		if(param2 != MenuCancel_Disconnected)
		{
			DisplayMenu(hMenu, param1, MENU_TIME_FOREVER);
		}
		
		delete menu;
		return;
	}
	
	if(action != MenuAction_Select)
	{
		return;
	}
	
	char szInfo[3]; int iIndex;
	GetMenuItem(menu, param2, szInfo, sizeof szInfo);
	
	iIndex = StringToInt(szInfo);
	
	if(iIndex == -1)
	{
		PushArrayArray(hPointPositions, NULL_VECTOR, 3);
		PushArrayCell(hPointEffects, 0);
		
		g_iChosenMenuPoint = (++g_iTotalPoints - 1);
	}
	
	else
	{
		g_iChosenMenuPoint = iIndex;
	}
	
	PrintToChat(param1, "Chosen point: %d", g_iChosenMenuPoint + 1);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

public bool TraceFilterCallback(int iEnt, int PointContents, int client)
{
	if(iEnt == client)
	{
		return false;
	}
	
	return true;
}

void Hooks(int iEnt, bool bStatus)
{
	switch(bStatus)
	{
		case true:
		{
			SDKHook(iEnt, SDKHook_ThinkPost, SDKCallback_NadeThinkPost);
			//SDKHook(iEnt, SDKHook_PostThinkPost, SDKCallback_NadeThinkPost);
			SDKHook(iEnt, SDKHook_Think, SDKCallback_NadeThinkPost);
			SDKHook(iEnt, SDKHook_TouchPost, SDKCallback_NadeTouchPost);
		}
		
		case false:
		{
			SDKUnhook(iEnt, SDKHook_ThinkPost, SDKCallback_NadeThinkPost);
			SDKUnhook(iEnt, SDKHook_PostThinkPost, SDKCallback_NadeThinkPost);
			SDKUnhook(iEnt, SDKHook_Think, SDKCallback_NadeThinkPost);
			SDKUnhook(iEnt, SDKHook_TouchPost, SDKCallback_NadeTouchPost);
		}
	}
}

public void SDKCallback_NadeTouchPost(int iEnt, int iOtherEnt)
{
	if(iEnt != g_iLastEnt)
	{
		Hooks(iEnt, false);
		return;
	}
	
	PrintToServer("Touched %d", iOtherEnt);
	g_iCurrentExpectedPoint++;
	
	//MakeEffect(g_iCurrentExpectedPoint);
	
	if(g_iCurrentExpectedPoint == g_iTotalPoints)
	{
		SetEntityGravity(iEnt, 1.0);
		Hooks(iEnt, false);
		g_iCurrentExpectedPoint = 1;
		g_bRunning = false;
		
		return;
	}
	
	if(g_iCurrentExpectedPoint + 1 == g_iTotalPoints)
	{
		float vOrigin[3], vEndPosition[3], vVelocity[3];
		// --- Set direction towards that 'ending' point. :) ---
		GetEntPropVector(iEnt, Prop_Send, "m_vecVelocity", vVelocity);
		
		// Get current speed
		float flScale = GetVectorLength(vVelocity);
		
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vOrigin);
		GetArrayArray(hPointPositions, g_iCurrentExpectedPoint, vEndPosition);
		SubtractVectors(vOrigin, vEndPosition, vVelocity);
		NormalizeVector(vVelocity, vVelocity);
		
		ScaleVector(vVelocity, flScale);
		SetEntPropVector(iEnt, Prop_Send, "m_vecVelocity", vVelocity);
		
		PrintToServer("Set");
	}
	
	else
	{
		SDKCallback_NadeThinkPost(iEnt);
	}
}

// Force max speed.
public void SDKCallback_NadeThinkPost(int iEnt)
{
	PrintToServer("Called Think");
	if(iEnt != g_iLastEnt)
	{
		Hooks(iEnt, false);
		
		PrintToServer("Fail #1");
		return;
	}
	
	if(g_iCurrentExpectedPoint == g_iTotalPoints)
	{
		// Make the last "hit" with 'normal' speed and afterwards.
		PrintToServer("Fail #2");
		return;
	}
	
	// Maintain constant speed.
	float vOrigin[3], vEndPosition[3], vVelocity[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vOrigin);
	GetArrayArray(hPointPositions, g_iCurrentExpectedPoint, vEndPosition);
	
	SubtractVectors(vOrigin, vEndPosition, vVelocity);
	NormalizeVector(vVelocity, vVelocity);
	
	ScaleVector(vVelocity, 250.0);
	SetEntPropVector(iEnt, Prop_Send, "m_vecVelocity", vVelocity);
}

// Stolen code from custom_nades_models plugin :X
public OnEntityCreated(entity, const String:classname[])
{
	if(IsValidEntity(entity)) 
	{
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}

public void OnEntitySpawned(int entity)
{
	if(!g_bRunning)
	{
		return;
	}
	
	if(g_bGotEntity)
	{
		return;
	}
	
	decl String:class_name[32];
	GetEntityClassname(entity, class_name, 32);
	//new ownernade = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");	
	if(StrContains(class_name, "projectile") != -1 && IsValidEntity(entity))
	{
		if(IsValidEntity(g_iLastEnt))
		{
			Hooks(g_iLastEnt, false);
		}
		
		g_bGotEntity = true;
		g_iLastEnt = entity;
		Hooks(g_iLastEnt, true);
		
		SetEntityGravity(entity, 0.0);
		
		PrintToChatAll("Got entity: %d with classname: %s", entity, class_name);
	}
	
	PrintToServer("Classname: %s", class_name);
	SDKUnhook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}
