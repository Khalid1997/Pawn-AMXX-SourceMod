#if defined PARACHUTE_ENABLED
	#endinput
#endif

#define PARACHUTE_ENABLED

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <fdownloader>

#undef REQUIRE_PLUGIN
#include <vipsys>
#include <tvip>

// Taken from 
// https://github.com/ESK0/Advanced-Parachute/blob/master/addons/sourcemod/scripting/files/globals.sp

#define MAX_BUTTONS 25
#define TAG "[AdvancedParachute]"

char sFilePath[PLATFORM_MAX_PATH];
char sDownloadFilePath[PLATFORM_MAX_PATH];
int g_LastButtons[MAXPLAYERS+1];

ArrayList arParachuteList;
StringMap smParachutes;

int g_iParachuteEnt[MAXPLAYERS+1];
int g_iDefaultPar = -1;
int g_iVelocity = -1;
Handle g_hParachute;
//Handle g_hOnParachute;

/*
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hOnParachute = CreateGlobalForward("OnParachuteOpen", ET_Event, Param_Cell);
	RegPluginLibrary("AdvancedParachute");
	return APLRes_Success;
}*/

bool g_bIsVIP[MAXPLAYERS];

#define Team_First_Bit		( 1 << (CS_TEAM_T+1) )
#define Team_Second_Bit	( 1 << (CS_TEAM_CT+1) )

#define Team_First	0
#define Team_Second 1

#define MAX_SKIN_KEY_LENGTH	21
#define MAX_SKIN_NAME_LENGTH 35
#define MAX_INFO_LENGTH	15

char MENU_ITEM_INFO[] = "menu_item_parachute";

bool g_bLate;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szError, int max)
{
	g_bLate = bLate;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_parachute", Command_Parachute);
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "configs/AdvancedParachute.cfg");
	BuildPath(Path_SM, sDownloadFilePath, sizeof(sDownloadFilePath), "configs/AdvancedParachuteDownload.txt");
	arParachuteList = new ArrayList(256);
	smParachutes = new StringMap();
	
	HookEvent("player_death", Parachute_Event_OnPlayerDeath);
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	if (g_iVelocity == -1)
	{
		SetFailState("%s Can not find m_vecVelocity[0] offset", TAG);
	}
	
	g_hParachute = RegClientCookie("advanced_parachute_test", "Parachute clientprefs", CookieAccess_Private);
	
	if(g_bLate)
	{
		bool bVIPSys = LibraryExists("vipsys");
		bool bTVIP = LibraryExists("tVip");
		
		if(bVIPSys && bTVIP)
		{
			bTVIP = false;
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if( bVIPSys && VIPSys_Client_IsVIP(i))
				{
					g_bIsVIP[i] = true;
				}
				
				else if(bTVIP && tVip_IsVip(i))
				{
					g_bIsVIP[i] = true;
				}
			
				else	g_bIsVIP[i] = false;
			}
		}
	}
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem(MENU_ITEM_INFO);
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem(MENU_ITEM_INFO, "Parachute Menu", MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenu_ItemParachute, 13);
}

public int VIPMenu_ItemParachute(Menu menu, char[] szInfo, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		ShowParachuteMenu(param1, g_bIsVIP[param1]);
	}
}

public void OnClientPutInServer(int client)
{
	g_bIsVIP[client] = false;
}

public void tVip_OnClientLoadedPost(int client, bool bIsVIP)
{
	g_bIsVIP[client] = bIsVIP;
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	g_bIsVIP[client] = bIsVIP;
}

public void OnMapStart()
{
	g_iDefaultPar = -1;
	arParachuteList.Clear();
	smParachutes.Clear();
	
	AdvP_AddFilesToDownload();
	KeyValues kvFile = new KeyValues("AdvancedParachute");
	
	if (FileExists(sFilePath) == false)
	{
		SetFailState("%s Unable to find AdvancedParachute.cfg in %s", TAG, sFilePath);
		return;
	}
	
	kvFile.ImportFromFile(sFilePath);
	kvFile.GotoFirstSubKey();
	AdvP_AddParachute(kvFile);
	
	while (kvFile.GotoNextKey())
	{
		AdvP_AddParachute(kvFile);
	}
	
	if (g_iDefaultPar == -1)
	{
		SetFailState("%s Default parachute not found", TAG);
	}
	
	char sBuffer[64];
	arParachuteList.GetString(g_iDefaultPar, sBuffer, sizeof(sBuffer));
	//PrintToServer(sBuffer);
	
	delete kvFile;
}

public void OnGameFrame()
{
	for (int client = 0; client <= MaxClients; client++)
	{
		if (IsValidClient(client, true))
		{
			if (g_iParachuteEnt[client] != 0)
			{
				float fVelocity[3];
				float fFallspeed = 100 * (-1.0);
				GetEntDataVector(client, g_iVelocity, fVelocity);
				
				if (fVelocity[2] < 0.0)
				{
					if (fVelocity[2] >= fFallspeed)
					{
						fVelocity[2] = fFallspeed;
					}
					else
					{
						fVelocity[2] = fVelocity[2] + 50.0;
					}
					
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
					SetEntDataVector(client, g_iVelocity, fVelocity);
				}
			}
		}
	}
}

public void Parachute_Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (g_iParachuteEnt[client] != 0)
	{
		RemoveParachute(client);
	}
}

public void OnClientCookiesCached(int client)
{
	if (IsValidClient(client))
	{
		g_iParachuteEnt[client] = 0;
		
		char sDefaultParachute[64];
		arParachuteList.GetString(g_iDefaultPar, sDefaultParachute, sizeof(sDefaultParachute));
		
		char sBuffer[64];
		GetClientCookie(client, g_hParachute, sBuffer, sizeof(sBuffer));

		if (StrEqual(sBuffer, "", false))
		{
			SetClientCookie(client, g_hParachute, sDefaultParachute);
		}
		
		else if (arParachuteList.FindString(sBuffer) == -1)
		{
			SetClientCookie(client, g_hParachute, sDefaultParachute);
		}
	}
}

public void OnClientDisconnect(int client)
{
	g_bIsVIP[client] = false;
	g_LastButtons[client] = 0;
	RemoveParachute(client);
}

void OnButtonPress(int client, int button)
{
	//PrintToChatAll("Pressed");
	if (IsValidClient(client, true))
	{
		int cFlags = GetEntityFlags(client);
		if (button == IN_USE && g_iParachuteEnt[client] == 0 && IsInAir(client, cFlags))
		{
			//PrintToChatAll("Continue1");
			AttachParachute(client);
		}
	}
}

void OnButtonRelease(int client, int button)
{
	//PrintToServer("Released");
	if (IsValidClient(client))
	{
		if (button == IN_USE && g_iParachuteEnt[client] != 0)
		{
			//PrintToChatAll("Continue2");
			RemoveParachute(client);
		}
	}
}
public Action Command_Parachute(int client, int args)
{
	bool bAccess = false;
	if(g_bIsVIP[client])
	{
		bAccess = true;
	}
	
	ShowParachuteMenu(client, bAccess);
}

void ShowParachuteMenu(int client, bool bAccess = true)
{
	Menu menu = new Menu(h_parachutemenu);
	menu.SetTitle("Advanced Parachute");
	
	for (int i = 0; i < arParachuteList.Length; i++)
	{
		char sSectionName[64];
		char sBuffer[512];
		arParachuteList.GetString(i, sSectionName, sizeof(sSectionName));
		smParachutes.GetString(sSectionName, sBuffer, sizeof(sBuffer));
	
		menu.AddItem(sSectionName, sSectionName, bAccess ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int h_parachutemenu(Menu menu, MenuAction action, int client, int Position)
{
	if (IsValidClient(client))
	{
		if (action == MenuAction_Select)
		{
			char Item[64];
			menu.GetItem(Position, Item, sizeof(Item));
			
			SetClientCookie(client, g_hParachute, Item);
		}
		else if (action == MenuAction_End)
		{
			delete menu;
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!g_bIsVIP[client])
	{
		if(g_iParachuteEnt[client] != 0)
		{
			RemoveParachute(client);
		}
		
		return;
	}
	
	if (IsValidClient(client, true))
	{
		int cFlags = GetEntityFlags(client);
		if ((IsInAir(client, cFlags) == false) && g_iParachuteEnt[client] != 0)
		{
			RemoveParachute(client);
		}
	}
	
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);
		if ((buttons & button))
		{
			if (!(g_LastButtons[client] & button))
			{
				OnButtonPress(client, button);
			}
		}
		else if ((g_LastButtons[client] & button))
		{
			OnButtonRelease(client, button);
		}
	}
	g_LastButtons[client] = buttons;
}

stock bool IsValidClient(int client, bool alive = false)
{
	if (0 < client && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) == false && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
}

void AdvP_AddParachute(KeyValues kv)
{
	char sSectionName[64];
	char sBuffer[512];
	char sModelPath[PLATFORM_MAX_PATH];

	kv.GetSectionName(sSectionName, sizeof(sSectionName));
	arParachuteList.PushString(sSectionName);
	
	kv.GetString("model", sModelPath, sizeof(sModelPath));
	
	if (FileExists(sModelPath) == false)
	{
		SetFailState("%s File: %s does not exists", TAG, sModelPath);
		return;
	}
	
	if (g_iDefaultPar == -1)
	{
		if (kv.GetNum("default", 0) != 1)
		{
			
		}
		else
		{
			g_iDefaultPar = arParachuteList.Length - 1;
		}
	}
	
	Format(sBuffer, sizeof(sBuffer), "%s", sModelPath);
	smParachutes.SetString(sSectionName, sBuffer);
}

void AdvP_AddFilesToDownload()
{
	if (FileExists(sDownloadFilePath) == false)
	{
		SetFailState("%s Unable to find AdvancedParachuteDownload.txt in %s", TAG, sDownloadFilePath);
		return;
	}
	
	File hDownloadFile = OpenFile(sDownloadFilePath, "r");
	char sDownloadFile[PLATFORM_MAX_PATH];
	int iLen;
	
	while (hDownloadFile.ReadLine(sDownloadFile, sizeof(sDownloadFile)))
	{
		iLen = strlen(sDownloadFile);
		if (sDownloadFile[iLen - 1] == '\n')
		{
			sDownloadFile[--iLen] = '\0';
		}
		
		TrimString(sDownloadFile);
		if (FileExists(sDownloadFile) == true)
		{
			int iNamelen = strlen(sDownloadFile) - 4;
			if (StrContains(sDownloadFile, ".mdl", false) == iNamelen)
			{
				PrecacheModel(sDownloadFile, true);
			}
			
			//PrintToServer("Added Download File: %s", sDownloadFile);
			FDownloader_AddSinglePath(sDownloadFile);
		}
		
		if (hDownloadFile.EndOfFile())
		{
			break;
		}
	}
	
	delete hDownloadFile;
}
void AttachParachute(int client)
{
	g_iParachuteEnt[client] = CreateEntityByName("prop_dynamic_override");
	
	if (IsValidEntity(g_iParachuteEnt[client]))
	{
		char sClientPrefs[64];
		char sBuffer[512];
		
		GetClientCookie(client, g_hParachute, sClientPrefs, sizeof(sClientPrefs));
		smParachutes.GetString(sClientPrefs, sBuffer, sizeof(sBuffer));
		
		DispatchKeyValue(g_iParachuteEnt[client], "model", sBuffer);
		SetEntProp(g_iParachuteEnt[client], Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(g_iParachuteEnt[client], Prop_Data, "m_nSolidType", 6);
		SetEntProp(g_iParachuteEnt[client], Prop_Send, "m_CollisionGroup", 1);
		DispatchSpawn(g_iParachuteEnt[client]);
		
		float fOrigin[3];
		float fAngles[3];
		float fAdvP_Angles[3];
		GetClientAbsOrigin(client, fOrigin);
		GetClientAbsAngles(client, fAngles);
		
		fAdvP_Angles[1] = fAngles[1];
		TeleportEntity(g_iParachuteEnt[client], fOrigin, fAdvP_Angles, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(g_iParachuteEnt[client], "SetParent", client);
		SetVariantString("idle");
		AcceptEntityInput(g_iParachuteEnt[client], "SetAnimation", -1, -1, 0);
	}
	
	else
	{
		g_iParachuteEnt[client] = 0;
	}
}

void RemoveParachute(int client)
{
	if (g_iParachuteEnt[client] && IsValidEntity(g_iParachuteEnt[client]))
	{
		AcceptEntityInput(g_iParachuteEnt[client], "KillHierarchy");
	}
	
	g_iParachuteEnt[client] = 0;
}

stock bool IsInAir(int client, int flags)
{
	return !(flags & FL_ONGROUND);
} 