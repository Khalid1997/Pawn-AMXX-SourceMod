#include <sourcemod>
#include <colorvariables>

#undef REQUIRE_PLUGIN
#include <multimod>

#pragma newdecls required
#pragma semicolon 1

#define PL_VERSION	"2.2E"

public Plugin myinfo = 
{
	name = "Advertisements: MultiMod Compatibility", 
	author = "Tsunami, Edit by Khalid", 
	description = "Display advertisements", 
	version = PL_VERSION, 
	url = ""
};


/**
 * Globals
 */
KeyValues g_hAdvertisements = null;
ConVar g_hEnabled;
ConVar g_hInterval;
Handle g_hTimer;

bool g_bMultiMod = false;
char g_szCurrentMod[MM_MAX_MOD_PROP_LENGTH];

/**
 * Plugin Forwards
 */
public void OnPluginStart()
{
	CreateConVar("sm_advertisements_version", PL_VERSION, "Display advertisements", FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_advertisements_enabled", "1", "Enable/disable displaying advertisements.");
	g_hInterval = CreateConVar("sm_advertisements_interval", "30", "Amount of seconds between advertisements.");
	
	g_hInterval.AddChangeHook(ConVarChange_Interval);
	
	AddTopColors();
	
	RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");
}

public void OnLibraryAdded(const char[] szLib)
{
	if (StrEqual(szLib, MM_LIB_BASE))
	{
		g_bMultiMod = true;
	}
}

public void OnLibraryRemoved(const char[] szLib)
{
	if (StrEqual(szLib, MM_LIB_BASE))
	{
		g_bMultiMod = false;
	}
}

public void OnAllPluginsLoaded()
{
	g_bMultiMod = LibraryExists(MM_LIB_BASE);
}

public void OnMapStart()
{
	ParseAds();
	g_hTimer = CreateTimer(g_hInterval.IntValue * 1.0, Timer_DisplayAd, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void ConVarChange_Interval(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_hTimer) {
		KillTimer(g_hTimer);
	}
	
	g_hTimer = CreateTimer(g_hInterval.IntValue * 1.0, Timer_DisplayAd, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}


/**
 * Commands
 */
public Action Command_ReloadAds(int args)
{
	ParseAds();
	return Plugin_Handled;
}


/**
 * Menu Handlers
 */
public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {  }


/**
 * Timers
 */
public Action Timer_DisplayAd(Handle timer)
{
	if (!g_hEnabled.BoolValue) {
		return;
	}
	
	char sCenter[1024], sChat[1024], sHint[1024], sMenu[1024], sTop[1024], sFlags[16], sMod[MM_MAX_MOD_PROP_LENGTH];

	g_hAdvertisements.GetString("mod", sMod, sizeof(sMod), "all");
	
	if(g_bMultiMod && ( !StrEqual(sMod, "all") && !StrEqual(sMod, g_szCurrentMod) ) )
	{
		while(g_hAdvertisements.GotoNextKey())
		{
			g_hAdvertisements.GetString("mod", sMod, sizeof(sMod), "all");
			
			if( StrEqual(sMod, "all") || StrEqual(sMod, g_szCurrentMod) )
			{
				Timer_DisplayAd(INVALID_HANDLE);
				return;
			}	
		}
		
		g_hAdvertisements.Rewind();
		g_hAdvertisements.GotoFirstSubKey();
		
		return;
	}
	
	g_hAdvertisements.GetString("center", sCenter, sizeof(sCenter));
	g_hAdvertisements.GetString("chat", sChat, sizeof(sChat));
	g_hAdvertisements.GetString("hint", sHint, sizeof(sHint));
	g_hAdvertisements.GetString("menu", sMenu, sizeof(sMenu));
	g_hAdvertisements.GetString("top", sTop, sizeof(sTop));
	g_hAdvertisements.GetString("flags", sFlags, sizeof(sFlags), "none");
	int iFlags = ReadFlagString(sFlags);
	bool bAdmins = StrEqual(sFlags, ""), 
	bFlags = !StrEqual(sFlags, "none");
	
	if (sCenter[0]) {
		ProcessVariables(sCenter);
		CRemoveColors(sCenter, sizeof(sCenter));
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i) && 
				((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags | ADMFLAG_ROOT)))) || 
					(bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))))) {
				PrintCenterText(i, sCenter);
				
				DataPack hCenterAd;
				CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
				hCenterAd.WriteCell(i);
				hCenterAd.WriteString(sCenter);
			}
		}
	}
	if (sHint[0]) {
		ProcessVariables(sHint);
		CRemoveColors(sHint, sizeof(sHint));
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i) && 
				((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags | ADMFLAG_ROOT)))) || 
					(bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))))) {
				PrintHintText(i, sHint);
			}
		}
	}
	if (sMenu[0]) {
		ProcessVariables(sMenu);
		CRemoveColors(sMenu, sizeof(sMenu));
		
		Panel hPl = new Panel();
		hPl.DrawText(sMenu);
		hPl.CurrentKey = 10;
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i) && 
				((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags | ADMFLAG_ROOT)))) || 
					(bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))))) {
				hPl.Send(i, Handler_DoNothing, 10);
			}
		}
		
		delete hPl;
	}
	if (sChat[0]) {
		bool bTeamColor = StrContains(sChat, "{teamcolor}", false) != -1;
		
		ProcessVariables(sChat);
		CProcessVariables(sChat, sizeof(sChat));
		CAddWhiteSpace(sChat, sizeof(sChat));
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i) && 
				((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags | ADMFLAG_ROOT)))) || 
					(bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))))) {
				if (bTeamColor) {
					CSayText2(i, sChat, i);
				} else {
					PrintToChat(i, sChat);
				}
			}
		}
	}
	if (sTop[0]) {
		int iStart = 0, 
		aColor[4] =  { 255, 255, 255, 255 };
		
		ParseTopColor(sTop, iStart, aColor);
		ProcessVariables(sTop[iStart]);
		
		KeyValues hKv = new KeyValues("Stuff", "title", sTop[iStart]);
		hKv.SetColor4("color", aColor);
		hKv.SetNum("level", 1);
		hKv.SetNum("time", 10);
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i) && 
				((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags | ADMFLAG_ROOT)))) || 
					(bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))))) {
				CreateDialog(i, hKv, DialogType_Msg);
			}
		}
		
		delete hKv;
	}
	
	if (!g_hAdvertisements.GotoNextKey()) {
		g_hAdvertisements.Rewind();
		g_hAdvertisements.GotoFirstSubKey();
	}
}

public Action Timer_CenterAd(Handle timer, DataPack pack)
{
	char sCenter[1024];
	static int iCount = 0;
	
	pack.Reset();
	int iClient = pack.ReadCell();
	pack.ReadString(sCenter, sizeof(sCenter));
	
	if (!IsClientInGame(iClient) || ++iCount >= 5) {
		iCount = 0;
		return Plugin_Stop;
	}
	
	PrintCenterText(iClient, sCenter);
	return Plugin_Continue;
}


/**
 * Stocks
 */
void ParseAds()
{
	if (g_hAdvertisements != null)
	{
		delete g_hAdvertisements;
	}
	
	g_hAdvertisements = CreateKeyValues("Advertisements");
	
	char sFile[64], sPath[PLATFORM_MAX_PATH];
	
	
	if(g_bMultiMod)
	{
		int iIndex = MultiMod_GetCurrentModId();
		
		if(iIndex != ModIndex_Null)
		{
			MultiMod_GetModProp(iIndex, MultiModProp_InfoKey, g_szCurrentMod, sizeof g_szCurrentMod);
		}
	}
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/advertisements.txt", sFile);

	if (!FileExists(sPath)) {
		SetFailState("File Not Found: %s", sPath);
	}
	
	g_hAdvertisements.ImportFromFile(sPath);
	g_hAdvertisements.GotoFirstSubKey();
}

void ProcessVariables(char sText[1024])
{
	char sBuffer[64];
	if (StrContains(sText, "\\n") != -1) {
		Format(sBuffer, sizeof(sBuffer), "%c", 13);
		ReplaceString(sText, sizeof(sText), "\\n", sBuffer);
	}
	
	if (StrContains(sText, "{currentmap}", false) != -1) {
		GetCurrentMap(sBuffer, sizeof(sBuffer));
		ReplaceString(sText, sizeof(sText), "{currentmap}", sBuffer, false);
	}
	
	if (StrContains(sText, "{date}", false) != -1) {
		FormatTime(sBuffer, sizeof(sBuffer), "%m/%d/%Y");
		ReplaceString(sText, sizeof(sText), "{date}", sBuffer, false);
	}
	
	if (StrContains(sText, "{time}", false) != -1) {
		FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p");
		ReplaceString(sText, sizeof(sText), "{time}", sBuffer, false);
	}
	
	if (StrContains(sText, "{time24}", false) != -1) {
		FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
		ReplaceString(sText, sizeof(sText), "{time24}", sBuffer, false);
	}
	
	if (StrContains(sText, "{timeleft}", false) != -1) {
		int iMins, iSecs, iTimeLeft;
		if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) {
			iMins = iTimeLeft / 60;
			iSecs = iTimeLeft % 60;
		}
		
		Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
		ReplaceString(sText, sizeof(sText), "{timeleft}", sBuffer, false);
	}
	
	ConVar hConVar;
	char sConVar[64], sSearch[64], sReplace[64];
	int iEnd = -1, iStart = StrContains(sText, "{"), iStart2;
	while (iStart != -1) {
		iEnd = StrContains(sText[iStart + 1], "}");
		if (iEnd == -1) {
			break;
		}
		
		strcopy(sConVar, iEnd + 1, sText[iStart + 1]);
		Format(sSearch, sizeof(sSearch), "{%s}", sConVar);
		
		if ((hConVar = FindConVar(sConVar))) {
			hConVar.GetString(sReplace, sizeof(sReplace));
			ReplaceString(sText, sizeof(sText), sSearch, sReplace, false);
		}
		
		iStart2 = StrContains(sText[iStart + 1], "{");
		if (iStart2 == -1) {
			break;
		}
		
		iStart += iStart2 + 1;
	}
}

StringMap g_hTopColors;

void AddTopColors()
{
    if (!g_hTopColors) {
        g_hTopColors = new StringMap();
    }

    AddTopColor("aliceblue", "F0F8FF");
    AddTopColor("allies", "4D7942");
    AddTopColor("ancient", "EB4B4B");
    AddTopColor("antiquewhite", "FAEBD7");
    AddTopColor("aqua", "00FFFF");
    AddTopColor("aquamarine", "7FFFD4");
    AddTopColor("arcana", "ADE55C");
    AddTopColor("axis", "FF4040");
    AddTopColor("azure", "007FFF");
    AddTopColor("beige", "F5F5DC");
    AddTopColor("bisque", "FFE4C4");
    AddTopColor("black", "000000");
    AddTopColor("blanchedalmond", "FFEBCD");
    AddTopColor("blue", "99CCFF");
    AddTopColor("blueviolet", "8A2BE2");
    AddTopColor("brown", "A52A2A");
    AddTopColor("burlywood", "DEB887");
    AddTopColor("cadetblue", "5F9EA0");
    AddTopColor("chartreuse", "7FFF00");
    AddTopColor("chocolate", "D2691E");
    AddTopColor("collectors", "AA0000");
    AddTopColor("common", "B0C3D9");
    AddTopColor("community", "70B04A");
    AddTopColor("coral", "FF7F50");
    AddTopColor("cornflowerblue", "6495ED");
    AddTopColor("cornsilk", "FFF8DC");
    AddTopColor("corrupted", "A32C2E");
    AddTopColor("crimson", "DC143C");
    AddTopColor("cyan", "00FFFF");
    AddTopColor("darkblue", "00008B");
    AddTopColor("darkcyan", "008B8B");
    AddTopColor("darkgoldenrod", "B8860B");
    AddTopColor("darkgray", "A9A9A9");
    AddTopColor("darkgrey", "A9A9A9");
    AddTopColor("darkgreen", "006400");
    AddTopColor("darkkhaki", "BDB76B");
    AddTopColor("darkmagenta", "8B008B");
    AddTopColor("darkolivegreen", "556B2F");
    AddTopColor("darkorange", "FF8C00");
    AddTopColor("darkorchid", "9932CC");
    AddTopColor("darkred", "8B0000");
    AddTopColor("darksalmon", "E9967A");
    AddTopColor("darkseagreen", "8FBC8F");
    AddTopColor("darkslateblue", "483D8B");
    AddTopColor("darkslategray", "2F4F4F");
    AddTopColor("darkslategrey", "2F4F4F");
    AddTopColor("darkturquoise", "00CED1");
    AddTopColor("darkviolet", "9400D3");
    AddTopColor("deeppink", "FF1493");
    AddTopColor("deepskyblue", "00BFFF");
    AddTopColor("dimgray", "696969");
    AddTopColor("dimgrey", "696969");
    AddTopColor("dodgerblue", "1E90FF");
    AddTopColor("exalted", "CCCCCD");
    AddTopColor("firebrick", "B22222");
    AddTopColor("floralwhite", "FFFAF0");
    AddTopColor("forestgreen", "228B22");
    AddTopColor("frozen", "4983B3");
    AddTopColor("fuchsia", "FF00FF");
    AddTopColor("fullblue", "0000FF");
    AddTopColor("fullred", "FF0000");
    AddTopColor("gainsboro", "DCDCDC");
    AddTopColor("genuine", "4D7455");
    AddTopColor("ghostwhite", "F8F8FF");
    AddTopColor("gold", "FFD700");
    AddTopColor("goldenrod", "DAA520");
    AddTopColor("gray", "CCCCCC");
    AddTopColor("grey", "CCCCCC");
    AddTopColor("green", "3EFF3E");
    AddTopColor("greenyellow", "ADFF2F");
    AddTopColor("haunted", "38F3AB");
    AddTopColor("honeydew", "F0FFF0");
    AddTopColor("hotpink", "FF69B4");
    AddTopColor("immortal", "E4AE33");
    AddTopColor("indianred", "CD5C5C");
    AddTopColor("indigo", "4B0082");
    AddTopColor("ivory", "FFFFF0");
    AddTopColor("khaki", "F0E68C");
    AddTopColor("lavender", "E6E6FA");
    AddTopColor("lavenderblush", "FFF0F5");
    AddTopColor("lawngreen", "7CFC00");
    AddTopColor("legendary", "D32CE6");
    AddTopColor("lemonchiffon", "FFFACD");
    AddTopColor("lightblue", "ADD8E6");
    AddTopColor("lightcoral", "F08080");
    AddTopColor("lightcyan", "E0FFFF");
    AddTopColor("lightgoldenrodyellow", "FAFAD2");
    AddTopColor("lightgray", "D3D3D3");
    AddTopColor("lightgrey", "D3D3D3");
    AddTopColor("lightgreen", "99FF99");
    AddTopColor("lightpink", "FFB6C1");
    AddTopColor("lightsalmon", "FFA07A");
    AddTopColor("lightseagreen", "20B2AA");
    AddTopColor("lightskyblue", "87CEFA");
    AddTopColor("lightslategray", "778899");
    AddTopColor("lightslategrey", "778899");
    AddTopColor("lightsteelblue", "B0C4DE");
    AddTopColor("lightyellow", "FFFFE0");
    AddTopColor("lime", "00FF00");
    AddTopColor("limegreen", "32CD32");
    AddTopColor("linen", "FAF0E6");
    AddTopColor("magenta", "FF00FF");
    AddTopColor("maroon", "800000");
    AddTopColor("mediumaquamarine", "66CDAA");
    AddTopColor("mediumblue", "0000CD");
    AddTopColor("mediumorchid", "BA55D3");
    AddTopColor("mediumpurple", "9370D8");
    AddTopColor("mediumseagreen", "3CB371");
    AddTopColor("mediumslateblue", "7B68EE");
    AddTopColor("mediumspringgreen", "00FA9A");
    AddTopColor("mediumturquoise", "48D1CC");
    AddTopColor("mediumvioletred", "C71585");
    AddTopColor("midnightblue", "191970");
    AddTopColor("mintcream", "F5FFFA");
    AddTopColor("mistyrose", "FFE4E1");
    AddTopColor("moccasin", "FFE4B5");
    AddTopColor("mythical", "8847FF");
    AddTopColor("navajowhite", "FFDEAD");
    AddTopColor("navy", "000080");
    AddTopColor("normal", "B2B2B2");
    AddTopColor("oldlace", "FDF5E6");
    AddTopColor("olive", "9EC34F");
    AddTopColor("olivedrab", "6B8E23");
    AddTopColor("orange", "FFA500");
    AddTopColor("orangered", "FF4500");
    AddTopColor("orchid", "DA70D6");
    AddTopColor("palegoldenrod", "EEE8AA");
    AddTopColor("palegreen", "98FB98");
    AddTopColor("paleturquoise", "AFEEEE");
    AddTopColor("palevioletred", "D87093");
    AddTopColor("papayawhip", "FFEFD5");
    AddTopColor("peachpuff", "FFDAB9");
    AddTopColor("peru", "CD853F");
    AddTopColor("pink", "FFC0CB");
    AddTopColor("plum", "DDA0DD");
    AddTopColor("powderblue", "B0E0E6");
    AddTopColor("purple", "800080");
    AddTopColor("rare", "4B69FF");
    AddTopColor("red", "FF4040");
    AddTopColor("rosybrown", "BC8F8F");
    AddTopColor("royalblue", "4169E1");
    AddTopColor("saddlebrown", "8B4513");
    AddTopColor("salmon", "FA8072");
    AddTopColor("sandybrown", "F4A460");
    AddTopColor("seagreen", "2E8B57");
    AddTopColor("seashell", "FFF5EE");
    AddTopColor("selfmade", "70B04A");
    AddTopColor("sienna", "A0522D");
    AddTopColor("silver", "C0C0C0");
    AddTopColor("skyblue", "87CEEB");
    AddTopColor("slateblue", "6A5ACD");
    AddTopColor("slategray", "708090");
    AddTopColor("slategrey", "708090");
    AddTopColor("snow", "FFFAFA");
    AddTopColor("springgreen", "00FF7F");
    AddTopColor("steelblue", "4682B4");
    AddTopColor("strange", "CF6A32");
    AddTopColor("tan", "D2B48C");
    AddTopColor("teal", "008080");
    AddTopColor("thistle", "D8BFD8");
    AddTopColor("tomato", "FF6347");
    AddTopColor("turquoise", "40E0D0");
    AddTopColor("uncommon", "B0C3D9");
    AddTopColor("unique", "FFD700");
    AddTopColor("unusual", "8650AC");
    AddTopColor("valve", "A50F79");
    AddTopColor("vintage", "476291");
    AddTopColor("violet", "EE82EE");
    AddTopColor("wheat", "F5DEB3");
    AddTopColor("white", "FFFFFF");
    AddTopColor("whitesmoke", "F5F5F5");
    AddTopColor("yellow", "FFFF00");
    AddTopColor("yellowgreen", "9ACD32");
}

void AddTopColor(const char[] sName, const char[] sColor)
{
    int aColor[4];
    ParseColor(sColor, aColor);

    g_hTopColors.SetArray(sName, aColor, sizeof(aColor));
}

void ParseColor(const char[] sColor, int aColor[4])
{
    int iColor = StringToInt(sColor, 16);
    aColor[0]  = iColor >> 16;
    aColor[1]  = iColor >> 8 & 255;
    aColor[2]  = iColor & 255;
    aColor[3]  = 255;
}

void ParseTopColor(const char[] sText, int &iStart, int aColor[4])
{
    int iEnd = StrContains(sText, "}");
    if (sText[0] != '{' || iEnd == -1) {
        return;
    }

    char sColor[32];
    strcopy(sColor, iEnd, sText[1]);
    if (sColor[0] == '#') {
        ParseColor(sColor[1], aColor);
    } else {
        g_hTopColors.GetArray(sColor, aColor, sizeof(aColor));
    }
    iStart = iEnd + 1;
}

