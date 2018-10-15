#pragma semicolon 1

#define PLUGIN_AUTHOR "Khalid"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <simonapi>
#include <smartjaildoors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "SimonAPI: Effects", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};
int g_iSimonId;
Handle g_hTimer_CloseJail;

public void OnPluginStart()
{
	RegConsoleCmd("sm_open", Command_OpenJail);
	RegConsoleCmd("sm_close", Command_CloseJail);
}

public void OnMapStart()
{
	g_hTimer_CloseJail = null;
}

public Action Command_OpenJail(int client, int Argc)
{
	if (!SimonAPI_HasAccess(client))
	{
		ReplyToCommand(client, "* You do not have access to this command.");
		return Plugin_Handled;
	}
	
	char szTime[5];
	GetCmdArg(1, szTime, sizeof szTime);
	float flTime;
	
	if (szTime[0])
	{
		flTime = StringToFloat(szTime);
	}
	
	else
	{
		flTime = 0.0;
	}
	
	if (flTime > 0.0)
	{
		if (g_hTimer_CloseJail != null)
		{
			delete g_hTimer_CloseJail;
		}
		
		ReplyToCommand(client, "You have opened the jails. They will close in %0.1f seconds", flTime);
		g_hTimer_CloseJail = CreateTimer(flTime, Timer_CloseJail, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	else
	{
		if (g_hTimer_CloseJail != null)
		{
			delete g_hTimer_CloseJail;
			g_hTimer_CloseJail = null;
		}
		
		ReplyToCommand(client, "You have opened the jails.");
	}
	
	SJD_OpenDoors();
	
	return Plugin_Handled;
}

public Action Timer_CloseJail(Handle hTimer, int client)
{
	g_hTimer_CloseJail = null;
	SJD_CloseDoors();
	
	if (!IsClientInGame(client))
	{
		return;
	}
	
	PrintToChat(client, "The jail doors have closed.");
}

public Action Command_CloseJail(int client, int Argc)
{
	if (!SimonAPI_HasAccess(client))
	{
		ReplyToCommand(client, "* You do not have access to this command.");
		return Plugin_Handled;
	}
	
	SJD_CloseDoors();
	ReplyToCommand(client, "You have closed the jails.");
	return Plugin_Handled;
}

public void SimonAPI_OnSimonChanged(int newClient, int oldClient, SimonChangedReason iReason)
{
	g_iSimonId = newClient;
	
	if (g_iSimonId == No_Simon)
	{
		if (iReason == SCR_Disconnect)
		{
			PrintToChatAll(" \x05The last simon has disconnected. A new simon must be assigned before continuing.");
			PrintHintTextToAll("The last simon has disconnected. \nA new simon must be assigned before continuing.");
			return;
		}
		
		if (iReason == SCR_Dead)
		{
			PrintToChatAll(" \x05The \x03Simon \x05has been killed!!!");
			PrintHintTextToAll("<font size='27' color='#006699'>The Simon</font> has been killed!!!");
			return;
		}
		
		if (iReason == SCR_Retire || iReason == SCR_DayStart)
		{
			PrintToChatAll(" \x05Player \x04%N \x05has retired from being the Simon!", oldClient);
			PrintHintTextToAll("<font size='27' color='#006699'>The Simon</font> has retired!");
			return;
		}
		
		if (iReason == SCR_TeamChange)
		{
			PrintToChatAll(" \x05Player \x04%N \x05has retired from being the Simon!", oldClient);
			PrintHintTextToAll("<font size='27' color='#006699'>The Simon</font> has retired!");
			return;
		}
		
		return;
	}
	
	if (oldClient != No_Simon)
	{
		ResetSimonEffects(oldClient);
	}
	
	ApplySimonEffects(g_iSimonId);
	
	if (iReason == SCR_Admin)
	{
		PrintToChatAll(" \x05Admin assigned \x04%N \x05as the SIMON", g_iSimonId);
	}
	
	PrintHintTextToAll("<font size='27' color='#006699'>%N</font> is the new SIMON. Obey all his orders!", g_iSimonId);
	PrintToChatAll(" \x05%N is the new SIMON!", g_iSimonId);
}

void ApplySimonEffects(int client)
{
	SetEntityRenderColor(client, 0, 128, 255, 192);
}

void ResetSimonEffects(int client)
{
	SetEntityRenderColor(client);
} 