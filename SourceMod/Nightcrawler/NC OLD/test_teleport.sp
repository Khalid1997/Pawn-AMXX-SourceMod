#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <the_khalid_inc>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	AddCommandListener(Command_Teleport, "drop");
}

new const String:MODEL_BEAM[] =	"materials/sprites/purplelaser1.vmt";

public void OnMapStart()
{
	if(PrecacheModel( MODEL_BEAM, true ))
	{
		PrintToServer("Precached");
	}
}

public void OnGameFrame()
{
	static int iPlayers[MAXPLAYERS];
	int iCount = GetPlayers(iPlayers, GetPlayersFlag_Alive, GP_TEAM_FIRST | GP_TEAM_SECOND);
	
	for(int i; i < iCount; i++)
	{
		SDKHookCallback_ThinkPost(iPlayers[i]);
	}
}

public OnClientPutInServer(client)
{
	PrintToServer("Hooked");
	//SDKHook(client, SDKHook_ThinkPost, SDKHookCallback_ThinkPost);
}

public OnClientDisconnect(client)
{
	//SDKUnhook(client, SDKHook_ThinkPost, SDKHookCallback_ThinkPost);
}

public void SDKHookCallback_ThinkPost(int client)
{
	PrintToServer("Thinking");
	if(GetClientButtons(client) & IN_USE)
	{
		PrintToServer("Climbing");
		DoClimb(client);
	}
}

void DoClimb(int client)
{
	static float vOrigin[3]; GetClientAbsOrigin(client, vOrigin);
	static float vEyeAngles[3]; static float vEyePosition[3];
	
	//TeleportEntity(iLaserEnt, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	
	static float vEndPosition[3];
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilterFunction, client);
	
	if(TR_GetFraction(hTr) == 1.0)
	{
		delete hTr;
		PrintToServer("Fraction == 1.0");
		return;
	}
	
	TR_GetEndPosition(vEndPosition, hTr);
	delete hTr;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		PrintToServer("OnGround");
		return;
	}
	
	//CreateLaser(vEyePosition, vEndPosition);
	if(GetVectorDistance(vEyePosition, vEndPosition) >= 45.0)
	{
		PrintToServer("TooFar %0.2f", GetVectorDistance(vEyePosition, vEndPosition));
		return;
	}
	
	static float vVelocity[3];
	GetAngleVectors(vEyeAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(vVelocity, vVelocity);
	ScaleVector(vVelocity, 250.0);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

public Action Command_Teleport(int client, const char[] szCommand, int iArgCount)
{
	if(TeleportClient(client))
	{
			
	}
			
	else PrintToChat(client, "Teleport failed.");
}

/*
bool TeleportClient(client)
{
	//float vClientOrigin[3];
	float vEyePosition[3];
	float vEyeAngles[3];
	
	//GetEntPropVector(client, Prop_Send, "m_vecOrigin", vClientOrigin);
	//PrintToChat(client, "Origin: %0.2f %0.2f %0.2f", vClientOrigin[0], vClientOrigin[1], vClientOrigin[2]);
	
	//
	//NormalizeVector(
	// Member: m_angEyeAngles[0] (offset 8452) (type float) (bits 10) (RoundDown|ChangesOften)
	//Member: m_angEyeAngles[1] (offset 8456) (type float) (bits 10) (RoundDown|ChangesOften)
	
	//float vEyeAngle[3];
	//vEyeAngle[0] = GetEntPropFloat(client, Prop_Send, "m_angEyeAngles[0]");
	//vEyeAngle[1] = GetEntPropFloat(client, Prop_Send, "m_angEyeAngles[1]");
	
	GetClientEyePosition(client, vEyePosition);
	PrintToChatAll("EyePos: %0.2f %0.2f %0.2f", vEyePosition[0], vEyePosition[1], vEyePosition[2]);
	
	GetClientEyeAngles(client, vEyeAngles);
	PrintToChatAll("EyeAng: %0.2f %0.2f %0.2f", vEyeAngles[0], vEyeAngles[1], vEyeAngles[2]);
	
	float vVector1[3], vVector2[3], vVector3[3];
	//GetAngleVectors(vEyeAngles, vVector1, NULL_VECTOR, NULL_VECTOR);
	//PrintToChatAll("vVector1_1: %0.2f %0.2f %0.2f", vVector1[0], vVector1[1], vVector1[2]);
	GetAngleVectors(vEyeAngles, vVector1, NULL_VECTOR, NULL_VECTOR);
	//PrintToChatAll("vVector1_1: %0.2f %0.2f %0.2f", vVector1[0], vVector1[1], vVector1[2]);
	//PrintToChatAll("vVector2: %0.2f %0.2f %0.2f", vVector2[0], vVector2[1], vVector2[2]);
	//PrintToChatAll("vVector3: %0.2f %0.2f %0.2f", vVector3[0], vVector3[1], vVector3[2]);
	
	float vOtherPosition[3];
	//AddVectors(vEyePosition, vVector1, vOtherPosition);
	NormalizeVector(vVector1, vVector2);
	vVector3 = vVector1;
	ScaleVector(vVector2, 8192.0);
	AddVectors(vEyePosition, vVector2, vOtherPosition);

	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, FilterFunction, client);
	if(!TR_DidHit(hTr))
	{
		delete hTr;
		PrintToChatAll("Nothing found.");
		return false;
	}
	
	TR_GetEndPosition(vOtherPosition, hTr);
	if(TR_PointOutsideWorld(vOtherPosition))
	{
		PrintToChatAll("Outside");
		delete hTr;
		return false;
	}
	
	delete hTr;
	
	//NegateVector(vVector3);
	ScaleVector(vVector3, 32.0);
	SubtractVectors(vOtherPosition, vVector3, vOtherPosition);
	CreateLaser(vEyePosition, vOtherPosition);
	
	//vOtherPosition[2] -= 64.0;
	TeleportEntity(client, vOtherPosition, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
	UnStuckEntity(client);
	//CreateLaser(vStart, vEnd, "bla", 0);
	
	return true;
}

public bool FilterFunction(int entity, int Contents, int client)
{
	if(entity == client)
	{
		return false;
	}
	
	return true;
}
*/

bool TeleportClient(client)
{
	float vEyePosition[3];
	float vEyeAngles[3];
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	
	float vVector1[3];//, vVector2[3], vVector3[3];
	GetAngleVectors(vEyeAngles, vVector1, NULL_VECTOR, NULL_VECTOR);
	
	float vOtherPosition[3];
	NormalizeVector(vVector1, vVector1);
	//vVector3 = vVector2;
	//ScaleVector(vVector2, 8192.0);
	//AddVectors(vEyePosition, vVector2, vOtherPosition);

	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilterFunction, client);
	if(!TR_DidHit(hTr))
	{
		delete hTr;
		PrintToChatAll("Nothing found.");
		return false;
	}
	
	TR_GetEndPosition(vOtherPosition, hTr);
	if(TR_PointOutsideWorld(vOtherPosition))
	{
		PrintToChatAll("Outside");
		delete hTr;
		return false;
	}
	
	delete hTr;
	
	ScaleVector(vVector1, 32.0);
	
	// Move the player model back based on mins/maxes;
	// Subtract because in the opposite direction;
	SubtractVectors(vOtherPosition, vVector1, vOtherPosition);
	
	CreateLaser(vEyePosition, vOtherPosition);
	
	TeleportEntity(client, vOtherPosition, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
	UnStuckEntity(client);
	
	return true;
}

#define START_DISTANCE  32   // --| The first search distance for finding a free location in the map.
#define MAX_ATTEMPTS    128  // --| How many times to search in an area for a free

bool UnStuckEntity(int client, int i_StartDistance = START_DISTANCE, int i_MaxAttempts = MAX_ATTEMPTS)
{
	int iMaxTries = 30;
	int iTries;

	enum 
	{
		x = 0, y, z, Coord_e
	};
		
	static float vf_OriginalOrigin[ Coord_e ];
	static float vf_NewOrigin[ Coord_e ];
	static int i_Attempts, i_Distance;
	static float vEndPosition[3];
	static float vMins[Coord_e];
	static float vMaxs[Coord_e];
	
	GetClientAbsOrigin(client, vf_OriginalOrigin);
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
		
	while(CheckIfClientIsStuck(client))
	{
		if(iTries++ >= iMaxTries)
		{
			break;
		}
		
		i_Distance = i_StartDistance;
		
		while ( i_Distance < 1000 )
		{
			i_Attempts = i_MaxAttempts;
			
			while ( i_Attempts-- )
			{
				vf_NewOrigin[ x ] = GetRandomFloat ( vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance );
				vf_NewOrigin[ y ] = GetRandomFloat ( vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance );
				vf_NewOrigin[ z ] = GetRandomFloat ( vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance );
				
				//engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, hull, id, 0 );
				TR_TraceHullFilter(vf_NewOrigin, vf_NewOrigin, vMins, vMaxs, MASK_ALL, TraceFilterFunction, client);
				
				// --| Free space found.
				TR_GetEndPosition(vEndPosition);
				if ( !TR_PointOutsideWorld(vEndPosition) && TR_GetFraction() == 1.0 )
				{
					// --| Set the new origin .
					TeleportEntity(client, vEndPosition, NULL_VECTOR, NULL_VECTOR);
					return true;
				}
			}
			
			i_Distance += i_StartDistance;
		}
	}
	
	// --| Could not be found.
	return false;
}

public bool TraceFilterFunction(int entity, int contentsMask, any client)
{
	if(client == entity)
	{
		return false;
	}
	
	return true;
}

bool CheckIfClientIsStuck(int client)
{
	static float fOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
	
	static float fMins[3];
	static float fMaxs[3];
	
	GetClientMins(client, fMins);
	GetClientMaxs(client, fMaxs);
	
	TR_TraceHullFilter(fOrigin, fOrigin, fMins, fMaxs, MASK_ALL, TraceFilterFunction, client);
	
	//engfunc(EngFunc_TraceHull, Origin, Origin, IGNORE_MONSTERS,  : (hull = HULL_HUMAN), 0, 0)
	
	if (TR_DidHit())
	{
		return true;
	}
	
	PrintToChatAll("Not stuck");
	return false;
}

public CreateLaser(Float:start[3], Float:end[3])
{
	#define LASER_COLOR_CT	"255 255 255"
	new ent = CreateEntityByName("env_beam");
	if (ent != -1)
	{
		new String:color[16] = LASER_COLOR_CT;

		TeleportEntity(ent, start, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(ent, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
		SetEntPropVector(ent, Prop_Data, "m_vecEndPos", end);
		DispatchKeyValue(ent, "targetname", "bla" );
		DispatchKeyValue(ent, "rendercolor", color );
		DispatchKeyValue(ent, "renderamt", "255");
		DispatchKeyValue(ent, "decalname", "Bigshot"); 
		DispatchKeyValue(ent, "life", "0"); 
		DispatchKeyValue(ent, "TouchType", "0");
		DispatchSpawn(ent);
		SetEntPropFloat(ent, Prop_Data, "m_fWidth", 1.0); 
		SetEntPropFloat(ent, Prop_Data, "m_fEndWidth", 1.0); 
		ActivateEntity(ent);
		AcceptEntityInput(ent, "TurnOn");
		
		PrintToChatAll("Made laser");
		CreateTimer(3.0, Timer_DeleteLaser, ent, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_DeleteLaser(Handle hTimer, int entity)
{
	RemoveEdict(entity);
	PrintToChatAll("Remove Laser");
}