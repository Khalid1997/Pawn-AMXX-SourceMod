static bool IsNewPlayer[MAXPLAYERS + 1]

public HLP_Init()
{
	AddCommandListener(HLP_Cmd_Say, "say")
	AddCommandListener(HLP_Cmd_Say, "say_team")
}

public void HLP_Event_PlayerActivate(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	IsNewPlayer[client] = true
}

public void HLP_Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	int team = GetClientTeam(client);
	if (team == CS_TEAM_CT || team == CS_TEAM_T)
	{
		if (IsNewPlayer[client])
		{
			ShowClientHelp(client);
			IsNewPlayer[client] = false
		}
	}
}

void ShowClientHelp(int client)
{
	Handle panel = CreatePanel();
	char line[64]
	Format(line, sizeof(line), "%T", "HELP_KICK_BALL", client, "E")
	DrawPanelText(panel, line)
	Format(line, sizeof(line), "%T", "HELP_UPGRADE_MENU", client, "R")
	DrawPanelText(panel, line);
	Format(line, sizeof(line), "%T", "HELP_TURBO", client, "G")
	DrawPanelText(panel, line)
	Format(line, sizeof(line), "%T", "HELP_CURVE_LEFT", client, "Shift+A")
	DrawPanelText(panel, line);
	Format(line, sizeof(line), "%T", "HELP_CURVE_RIGHT", client, "Shift+D")
	DrawPanelText(panel, line)
	Format(line, sizeof(line), "%T", "HELP_HELP", client, "help")
	DrawPanelText(panel, line)
	SendPanelToClient(panel, client, HelpPanelHandler, 20)
	CloseHandle(panel)
}

public int HelpPanelHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
}

public Action HLP_Cmd_Say(int client, const char[] command, int argc) 
{
	char text[192]
	if(!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue
	}
	StripQuotes(text)
	if (StrEqual(text, "help", false))
	{
		ShowClientHelp(client)
		return Plugin_Handled
	}
	return Plugin_Continue
}