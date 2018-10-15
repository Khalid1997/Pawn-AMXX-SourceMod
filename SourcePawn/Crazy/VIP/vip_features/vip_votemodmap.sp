#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <multimod>
#include <vipsys>
#include <sdktools>
#include <limited_features>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "VIP Feature: Vote Mod/Map",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

#define MAX_USES_MOD	3
#define MAX_USES_MAP	3
int g_iModChangesId, g_iMapChangesId;

public void OnPluginStart()
{
	
}

public void OnAllPluginsLoaded()
{
	VIPSys_Menu_AddItem("vote_mod", "Vote Mod", MenuAction_DisplayItem | MenuAction_DrawItem | MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenuCallback_Select, 16);
	VIPSys_Menu_AddItem("vote_map", "Vote map", MenuAction_DisplayItem | MenuAction_DrawItem | MenuAction_Select, ITEMDRAW_DEFAULT, VIPMenuCallback_Select, 17);
	
	g_iModChangesId = LF_Feature_CreateEx("vip_mod_changes", LT_Normal, 604800 /* 1 Week */, 3, 0);
	g_iMapChangesId = LF_Feature_CreateEx("vip_map_changes", LT_Normal, 604800 /* 1 Week */, 3, 0);
}

public void OnPluginEnd()
{
	VIPSys_Menu_RemoveItem("vote_mod");
	VIPSys_Menu_RemoveItem("vote_map");
}

public int VIPMenuCallback_Select(Menu menu, char[] szInfo, MenuAction action, int param1, int param2)
{
	if(!VIPSys_Client_IsVIP(param1))
	{
		return 0;
	}
	
	#define VoteType_Mod 0
	#define VoteType_Map	1
	int iVoteType;
	if(StrEqual(szInfo, "vote_mod"))
	{
		iVoteType = VoteType_Mod;
	}
	
	else if(StrEqual(szInfo, "vote_map"))
	{
		iVoteType = VoteType_Map;
	}
	
	int iUses, iMaxUses;
	int iSteam = GetSteamAccountID(param1);
	LF_Client_GetFeatureDataEx(iSteam, iVoteType == VoteType_Mod ? g_iModChangesId : g_iMapChangesId, _, iUses, iMaxUses);
			
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			if(iMaxUses - iUses <= 0)
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
			
		case MenuAction_DisplayItem:
		{
			char szDisplayItem[65];
			
			if(iVoteType == VoteType_Mod)
			{
				FormatEx(szDisplayItem, sizeof szDisplayItem, "Vote Mod (%d uses left)", iMaxUses - iUses);
			}
			
			else
			{
				FormatEx(szDisplayItem, sizeof szDisplayItem, "Vote Map (%d uses left)", iMaxUses - iUses);
			}
			
			return RedrawMenuItem(szDisplayItem);
		}
		
		case MenuAction_Select:
		{
			LimitedFeatureActivateFailureReason iReason;
			
			if( MultiMod_Vote_GetVoteStatus() != MultiModVoteStatus_NoVote )
			{
				CPrintToChat(param1, "\x04* There is a vote already running. You cannot override that vote as a VIP.");
				return 0;
			}
			
			if(!LF_Client_ActivateFeatureEx(iSteam, iVoteType == VoteType_Mod ? g_iModChangesId : g_iMapChangesId, false, iReason) )
			{
				CPrintToChat(param1, "\x04* (CODE %d) You have exceeded the allowed amount to this feature.", iReason);
				return 0;
			}
			
			switch(iVoteType)
			{
				case VoteType_Mod:
				{
					MultiMod_Vote_StartVote(MultiModVote_Mod | MultiModVote_Map, true);
					CPrintToChat(param1, "\x04* VIP player \x03%N \x04has started the \x05Mod \x04vote.", param1);
				}
				
				case VoteType_Map:
				{
					MultiMod_Vote_StartVote(MultiModVote_Map, true);
					CPrintToChat(param1, "\x04* VIP player \x03%N \x04has started the \x05Map \x04vote.", param1);
				}
			}
		}
	}
	
	return 0;
}

public void VIPSys_Client_OnCheckVIP(int client, bool bIsVIP)
{
	if(bIsVIP)
	{
		MultiMod_Vote_SetClientVotingPower(client, 2);
	}
	
	else
	{
		MultiMod_Vote_SetClientVotingPower(client, 1);
	}
}
