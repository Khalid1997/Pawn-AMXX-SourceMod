#include <amxmodx>
#include <amxmisc>

#pragma semicolon 1

#define PLUGIN "Write in Arabic!"
#define VERSION "1.0"
#define AUTHOR "Khalid"

enum _:LETTERS
{
	MATCHING_LETTER, INITIAL, MIDDLE, FINAL, ISOLATED
};

new g_iSpecialCharsBit = (1<<7) | (1<<8) | (1<<9) | (1<<10) | (1<<25);

new g_szArabicChars[28][LETTERS][] = {
	{ "h", "ﺃ", "ﺄ", "ﺄ", "ﺃ" },
	{ "f", "ﺑ", "ﺒ", "ﺐ", "ﺏ" },
	{ "j", "ﺗ", " ﺘ", "ﺖ", "ﺕ" },
	{ "e", "ﺛ", "ﺜ", "ﺚ", "ﺙ" },
	{ "[", "ﺟ", "ﺠ", "ﺞ", "ﺝ" },
	{ "p", "ﺣ", "ﺤ", "ﺢ", "ﺡ" },
	{ "o", "ﺧ", "ﺨ", "ﺦ", "ﺥ" },
	{ "]", "ﺩ", "ﺪ", "ﺪ", "ﺩ" }, // Special
	{ "`", "ﺫ", "ﺬ", "ﺬ", "ﺫ" }, // Special
	{ "v", "ﺭ", "ﺮ", "ﺮ", "ﺭ" }, // Special
	{ ".", "ﺯ", "ﺰ", "ﺰ", "ﺯ" }, // Special
	{ "s", "ﺳ", "ﺴ", "ﺲ", "ﺱ" },
	{ "a", "ﺷ", "ﺸ", "ﺶ", "ﺵ" },
	{ "w", "ﺻ", "ﺼ", "ﺺ", "ﺹ" },
	{ "q", "ﺿ", "ﻀ", "ﺾ", "ﺽ" },
	{ "'", "ﻃ", "ﻄ", "ﻂ", "ﻁ" },
	{ "/", "ﻇ", "ﻈ", "ﻆ", "ﻅ" },
	{ "u", "ﻋ", "ﻌ", "ﻊ", "ﻉ" },
	{ "y", "ﻏ", "ﻐ", "ﻎ", "ﻍ" },
	{ "t", "ﻓ", "ﻔ", "ﻒ", "ﻑ" },
	{ "r", "ﻗ", "ﻘ", "ﻖ", "ﻕ" },
	{ ";", "ﻛ", "ﻜ", "ﻚ", "ﻙ" },
	{ "g", "ﻟ", "ﻠ", "ﻞ", "ﻝ" },
	{ "l", "ﻣ", "ﻤ", "ﻢ", "ﻡ" },
	{ "k", "ﻧ", "ﻨ", "ﻦ", "ﻥ" },
	{ ",", "ﻭ", "ﻮ", "ﻮ", "ﻭ" }, // Special
	{ "i", "ﻫ", "ﻬ", "ﻪ", "ﻩ" },
	{ "d", "ﻳ", "ﻴ", "ﻲ", "ﻱ" }
};
	
new g_iSayAllCmd;
new g_iArabic[33];

public plugin_init()
{
	g_iSayAllCmd = register_clcmd("say", "CmdSay");
	register_clcmd("say_team", "CmdSay");
	
	register_clcmd("say /arabic", "CmdToggleArabic");
}

public CmdToggleArabic(id)
{
	g_iArabic[id] = !g_iArabic[id];
}

public CmdSay(id, level, cid)
{
	if(!g_iArabic[id])
	{
		return PLUGIN_CONTINUE;
	}
	
	new szChat[192]; read_argv(1, szChat, 191);
	ReverseString(szChat, szChat);
	
	new iLen = strlen(szChat);
	
	new szAdjustedString[191], a
	for(a = 0, iChar; a < iLen; a++)
	{
		for(new i; i < 29 /* LETTERS NUM */; i++)
		{
			iChar = szChat[a]
			if(szChat[a] == g_szArabicChars[i][MATCHING_LETTER] || 
			( szChat[a] + 32 == g_szArabicChars[i][MATCHING_LETTER] /* Case insensitive */
			&& IsValidChar(szChat[a]) ) )
			{
				// Starting of checking for position
				// In arabic, the position of the letter changes the form of it.
				// Initial letter differs from middle, final and isolated (In most cases)
				if(i > 0)
				{
					if(szChat[a - 1] == ' ')
					{
						switch(szChat[a + 1])
						{
							case ' ':
							{
								iChar = g_szArabicChars[i][ISOLATED];
							}
							
							default:
							{
								switch( IsValidChar(szChat[a + 1]) )
								{
									case 1:
									{
										iChar = g_szArabicChars[i][INITIAL];
									}
									
									case 0:
									{
										iChar = g_szArabicChars[i][ISOLATED];
									}
								}
							}
						}
					}
		
					else if( IsValidChar(szChat[a - 1]) && szChat[a - 1] != ' ')
					{
						iChar = g_szArabicChars[i][MIDDLE];
					}
					
					else
					{
						iChar = g_szArabicChars[i][FINAL];
					}
				}
					
				else if(szChat[a + 1] == ' ') 
				{
					iChar = g_szArabicChars[i][ISOLATED];
				}
				
				else if(IsValidChar(szChat[a + 1]))
				{
					iChar = g_szArabicChars[i][INITIAL]
				}
			}
			
			szAdjustedString[a] = iChar
		}
	}
	
	new szCmd[15]
	if(g_iSayAllCmd == cid)
	{
		szCmd = "say"
	} else {
		szCmd = "say_team"
	}
	
	//engclient_cmd(id, szCmd, szAdjustedString)
	client_print(id, print_chat, "English: %s", szChat)
	client_print(id, print_chat, "Arabic: %s", szAdjustedString)
	return PLUGIN_HANDLED
}

stock ReverseString( input[ ], output[ ] ) 
{ 
	new i, j
	for( i = strlen( input ) - 1, j = 0 ; i 90 ; i--, j++ ) 
	{ 
		output[ j ] = input[ i ]; 
	} 
	
	output[ j ] = '^0'; 
}

stock IsValidChar(charLetter)
{
	// Chars between Capital and small letters in ACII table.
	static iWrong = (1<<91) | (1<<92) | (1<<93) | (1<<94) | (1<<95) | (1<<96);
	
	for(new i; i < 29; i++)
	{
		if(charLetter == g_szArabicChars[i][MATCHING_LETTER] ||
		( ( 64 < charLetter < 123 ) && !( (1<<charLetter) & iWrong ) && charLetter + 32 == g_szArabicChars[i][MATCHING_LETTER] ) )
		{
			return 1;
		}
	}
	
	return 0;
}