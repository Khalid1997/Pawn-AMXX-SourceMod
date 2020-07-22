#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

public Plugin myinfo = 
{
	name = "Name of plugin here!",
	author = "Your name here!",
	description = "Brief description of plugin functionality here!",
	version = PLUGIN_VERSION,
	url = "Your website URL/AlliedModders profile URL"
};

char MODEL_BEAM[] = "materials/sprites/physbeam.vmt";

public void OnPluginStart()
{
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	CreateConVar("sm_pluginnamehere_version", PLUGIN_VERSION, "Standard plugin version ConVar. Please don't change me!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_beam", ConCmd_Beam);
}

int g_iBeamModelIndex;

public void OnMapStart()
{
	g_iBeamModelIndex = PrecacheModel(MODEL_BEAM);
}

public Action ConCmd_Beam(int client, int args)
{
	float vEyePosition[3]; GetClientEyePosition(client, vEyePosition);
	float vEyeAngles[3];
	GetClientEyeAngles(client, vEyeAngles);
	//WA_GetAttachmentPos(client, "muzzle_flash", vOrigin);
	
	float vEndPosition[3];
	Handle hTr = TR_TraceRayFilterEx(vEyePosition, vEyeAngles, MASK_ALL, RayType_Infinite, TraceFilter_Callback, client);
	
	if (!TR_DidHit(hTr))
	{
		delete hTr;
		return;
	}
	
	TR_GetEndPosition(vEndPosition, hTr);
	
	TE_SetupBeamPoints(vEyePosition, vEndPosition, g_iBeamModelIndex, 0, 0, 0, 3.0, 1.0, 1.0, 0, 0.0, {255, 255, 255, 128}, 1);
	TE_SendToAll();
	
	int iLaser = MakeLaserEntity(client);
	TeleportEntity(iLaser, vEndPosition, NULL_VECTOR, NULL_VECTOR);
	
	delete hTr;
}

int MakeLaserEntity(int client)
{
	PrintToServer("Made Laser ent");
	
	int iEnt;
	
	#define LASER_COLOR_CT	"255 255 255"
	iEnt = CreateEntityByName("env_beam");
	if (IsValidEntity(iEnt))
	{
		char color[16] = LASER_COLOR_CT;
		
		//TeleportEntity(iEnt, start, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(iEnt, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
		//SetEntPropVector(iEnt, Prop_Data, "m_vecEndPos", end);
		
		DispatchKeyValue(iEnt, "targetname", "testtargetname");
		DispatchKeyValue(iEnt, "rendercolor", color);
		DispatchKeyValue(iEnt, "renderamt", "255");
		DispatchKeyValue(iEnt, "damage", "0");
		DispatchKeyValue(iEnt, "decalname", "Bigshot");
		DispatchKeyValue(iEnt, "life", "0");
		DispatchKeyValue(iEnt, "TouchType", "0");
		
		DispatchKeyValue(iEnt, "ClipStyle", "0");
		
		DispatchSpawn(iEnt);
		SetEntPropFloat(iEnt, Prop_Data, "m_fWidth", 1.0);
		SetEntPropFloat(iEnt, Prop_Data, "m_fEndWidth", 1.0);
		
		SetEntProp(iEnt, Prop_Send, "m_nNumBeamEnts", 2);
		//SetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(client), 0);
		SetEntPropEnt(iEnt, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(client), 1);
		SetEntProp(iEnt, Prop_Send, "m_nBeamType", 1);
		
		AcceptEntityInput(iEnt, "TurnOn");
		ActivateEntity(iEnt);
		
		return iEnt;
	}
	
	return 0;
}

public bool TraceFilter_Callback(int iEnt, int iContentMask, int client)
{
	if (iEnt == client)
	{
		return false;
	}
	
	return true;
}