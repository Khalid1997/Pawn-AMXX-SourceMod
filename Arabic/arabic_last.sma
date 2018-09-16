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

new g_iSpecialCharsBit = (1<<0) | (1<<7) | (1<<8) | (1<<9) | (1<<10) | (1<<25) \
| (1<<28) | (1<<29) | (1<<30); /*| (1<<31); | (1<<32);*/

new g_szArabicChars[][LETTERS][] = {
	{ "h", "ﺃ", "ﺄ", "ﺄ", "ﺃ" }, // Special
	{ "f", "ﺑ", "ﺒ", "ﺐ", "ﺏ" },
	{ "j", "ﺗ", "ﺘ", "ﺖ", "ﺕ" },
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
	{ "", "ﻛ", "ﻜ", "ﻚ", "ﻙ" },
	{ "g", "ﻟ", "ﻠ", "ﻞ", "ﻝ" },
	{ "l", "ﻣ", "ﻤ", "ﻢ", "ﻡ" },
	{ "k", "ﻧ", "ﻨ", "ﻦ", "ﻥ" },
	{ ",", "ﻭ", "ﻮ", "ﻮ", "ﻭ" }, // Special
	{ "i", "ﻫ", "ﻬ", "ﻪ", "ﻩ" },
	{ "d", "ﻳ", "ﻴ", "ﻲ", "ﻱ" },
	
	{ "m", "ﺓ", "ﺔ", "ﺔ", "ة" }, // Special
	{ "n", "ﻯ", "ﻰ", "ﻰ", "ﻯ" }, // SPecial
	{ "b", "ﻻ", "ﻼ", "ﻼ", "ﻻ" }, // Special
	{ "c", "ﺅ", "ﺆ", "ﺆ", "ﺅ" }, // Special
	//{ "x", "ء", "ء", "ء", "ء" }, // Special
	{ "z", "ﺋ", "ﺌ", "ﺊ", "ﺉ" }
};

new g_iSayAllCmd;
new g_iArabic[33];

public plugin_init()
{
	register_clcmd("say /arabic", "CmdToggleArabic");
	
	g_iSayAllCmd = register_clcmd("say", "CmdSay");
	register_clcmd("say_team", "CmdSay");
}

public client_putinserver(id)
{
	g_iArabic[id] = 1;
}

public CmdToggleArabic(id)
{
	g_iArabic[id] = !g_iArabic[id];
	client_print(id, print_chat, "** Arabic chat %sabled", g_iArabic[id] ? "en" : "dis");
}

public CmdSay(id, level, cid)
{
	if(!g_iArabic[id])
	{
		return PLUGIN_CONTINUE;
	}
	
	new szOriginal[192], szChat[192]; read_argv(1, szChat, 191);
	//ReverseString(szOriginal, szChat);
	
	new iLen = strlen(szChat);
	
	new szAdjustedString[512], a, iDone;
	new iLen2;
	
	for( a = 0, iDone = 0; a < iLen; a++, iDone = 0)
	{
		for(new i; i < sizeof(g_szArabicChars) /* LETTERS NUM */; i++)
		{
			// Starting of checking for position
			// In arabic, the position of the letter changes the form of it.
			// Initial letter differs from middle, final and isolated (In most cases)
			
			// Not the first char
			
			if(szChat[a] != g_szArabicChars[i][MATCHING_LETTER][0]) //&&
			//	( !( 64 < szChat[a] < 123) && szChat[a] + 32 != g_szArabicChars[i][MATCHING_LETTER][0]) )
			{
				server_print("Continue; %c(%d) %c(%d)", szChat[a], szChat[a], g_szArabicChars[i][MATCHING_LETTER][0], g_szArabicChars[i][MATCHING_LETTER][0]);
				continue;
			}
		
			if(a > 0)
			{
				if(szChat[a - 1] == ' ')
				{
					if( IsValidChar(szChat[a + 1]) )
					{
						server_print("#1: a = %d <> i = %d", a, i);
						iLen2 += formatex(szAdjustedString[iLen2], charsmax(szAdjustedString) - iLen2, g_szArabicChars[i][INITIAL]);
						iDone = 1;
						break;
					}
					
					else
					{
						server_print("#2: a = %d <> i = %d", a, i);
						iLen2 += formatex(szAdjustedString[iLen2], charsmax(szAdjustedString) - iLen2, g_szArabicChars[i][ISOLATED]);
						iDone = 1;
						break;
					}
				}
				
				else
				{
					if( IsValidChar(szChat[a - 1]) )
					{
						switch(szChat[a + 1] == ' ')
						{
							case 0:
							{
								new iLetter = INITIAL;
								if(IsValidChar(szChat[a + 1]))
								{
									if( (1<< ( a - 1) ) & g_iSpecialCharsBit )
									{
										iLetter = INITIAL;
									}
									
									else
									{
										iLetter = MIDDLE;
									}
								}
								
								else
								{
									iLetter = ISOLATED;
								}
							
								server_print("#4: a = %d <> i = %d", a, i);
								iLen2 += formatex(szAdjustedString[iLen2], charsmax(szAdjustedString) - iLen2, g_szArabicChars[i][iLetter]);
								iDone = 1;
								break;
								
							}
							
							case 1:
							{
								server_print("#3: a = %d <> i = %d", a, i);
								iLen2 += formatex(szAdjustedString[iLen2], charsmax(szAdjustedString) - iLen2, g_szArabicChars[i][FINAL] );
								iDone = 1;
								break;
							}		
						}
					}
				}			
			
			}
		
			else
			{
				if( IsValidChar(szChat[a + 1]) )
				{
					server_print("#5: a = %d <> i = %d", a, i);
					iLen2 += formatex(szAdjustedString[iLen2], charsmax(szAdjustedString) - iLen2, g_szArabicChars[i][INITIAL]);
					iDone = 1;
					break;
				}
			
				else
				{
					server_print("#6: a = %d <> i = %d", a, i);
					iLen2 += formatex(szAdjustedString[iLen2], charsmax(szAdjustedString) - iLen2, g_szArabicChars[i][ISOLATED]);
					iDone = 1;
					break;
				}
			}
		}
		
		if(!iDone)
		{
			//iLen2 += formatex(szAdjustedString[iLen2], charsmax(szAdjustedString) - iLen, szChat[a])
			szAdjustedString[iLen2++] = szChat[a];
		}
	}

	ReverseString(szAdjustedString, szOriginal);

	new szCmd[15];
	if(g_iSayAllCmd == cid)
	{
		szCmd = "say";
		} else {
		szCmd = "say_team";
	}

	//engclient_cmd(id, szCmd, szAdjustedString)
	client_print(id, print_chat, "English: %s", szChat);
	client_print(id, print_chat, "Arabic: %s", szAdjustedString );
	client_print(id, print_chat, "szOriginal: %s", szOriginal);

	/*log_amx("..: %s", szOriginal);

	for(new i; i < strlen(szOriginal); i++)
	{
		server_print("%s <> %d <> %c", szOriginal[i], szOriginal[i], szOriginal[i]);
	}*/

	return PLUGIN_HANDLED;
}

/*
stock ReverseString( string[], output[], maxlen )
{
	new len = strlen(string);
	if( len > maxlen )
	{
		return 0;
	}

	maxlen = len;
	new i;
	for(--len; len>=0; len--)
	{
		output[i] = string[len];
	}

	new c;
	for(i=0; i<maxlen; i++)
	{
		c = output[i];
		if( c & 0xC0 == 0xC0 )
		{
			server_print("Yes 1 %d", i);
			if( c & 0xF0 == 0xF0 )
			{
				server_print("Yes 2 %d", i);
				output[i] = output[i-3];
				output[i-3] = c;
				c = output[i-2];
				output[i-2] = output[i-1];
				output[i-1] = c;
			}
			else if( c & 0xE0 == 0xE0 )
			{
				server_print("Yes 3 %d", i);
				output[i] = output[i-2];
				output[i-2] = c;
			}
			else
			{
				server_print("Yes 4 %d", i);
				output[i] = output[i-1];
				output[i-1] = c;
			}
		}
	}
	
	return 1;
}  */

stock ReverseString( input[ ], output[ ] ) 
{ 
	//new i, j;
	//for( i = strlen( input ) - 1, j = 0 ; i >= 0 ; i--, j++ ) 
	//{ 
	//output[ j ] = input[ i ]; 
	//} 

	//output[ j ] = '^0'; 

	new szUnicodeChar[] = "�";

	new iLen = strlen(input);
	new j = iLen - 1;
	new i;

	output[iLen] = '^0';

	while( i < iLen )
	{
		if(input[i] == szUnicodeChar[0])
		{
			output[j] = input[i + 2];
			output[j - 1] = input[i + 1];
			output[j - 2] = input[i];
			
			j -= 3; i += 3;
			continue;
		}
		
		output[j] = input[i];
		j--; i++;
	}

	output[j] = EOS;
}
stock IsValidChar(charLetter)
{
	// Chars between Capital and small letters in ACII table.
	//static iWrong = (1<<91) | (1<<92) | (1<<93) | (1<<94) | (1<<95) | (1<<96);

	if(!charLetter)
	{
		return 0;
	}

	static iBit;

	if(!iBit)
	{
		for(new i; i < sizeof(g_szArabicChars); i++)
		{
			iBit |= (1<<g_szArabicChars[i][MATCHING_LETTER][0]);
		}
	}

	if( (1<<charLetter) & iBit )
	{
		return 1;
	}

	return 0;
}

