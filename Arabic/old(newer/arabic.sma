#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Arabic Chat"
#define VERSION "1.0"
#define AUTHOR "Khalid :)"

#define DEBUG

new gBit
#define IsInBit(%1) (gBit & (1<<%1))
#define AddToBit(%1) (gBit |= (1<<%1))
#define RemoveFromBit(%1) ( gBit &= ~(1<<%1) )

new channels[][] =
{
    "#Cstrike_Chat_CT",
    "#Cstrike_Chat_T",
    "#Cstrike_Chat_CT_Dead",
    "#Cstrike_Chat_T_Dead",
    "#Cstrike_Chat_Spec",
    "#Cstrike_Chat_All",
    "#Cstrike_Chat_AllDead",
    "#Cstrike_Chat_AllSpec"
}

new Trie:gChats

new gMsgId

enum 
{
	Trie:ALONE = 0,
	Trie:INITIAL,
	Trie:MID,
	Trie:FINAL
}

new Trie:gLetters[4]

new const gszEnglishLetters[][] = {
	// Ã È Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö Ø Ù Ú Û Ý Þ ß á ã ä åÜ æ í
	"h", "f", "j", "e", "[", "p", "o", "]", "`", "v", ".", "s", "a", "w", "q", "'", "/", "u", "y", "t", "r", ";", "g", "l", "k", "i", ",", "d"
}

new const Arabic[][][] = {
	{ "Ç", "Ç", "Ç", "Ç" },
	{ "È", "È", "È", "È" },
	{ "Ê", "Ê", "Ê", "Ê" },
	{ "Ë", "Ë", "Ë", "Ë" },
	{ "Ì", "Ì", "Ì", "Ì" },
	{ "Í", "Í", "Í", "Í" },
	{ "Î", "Î", "Î", "Î" },
	{ "Ï", "Ï", "Ï", "Ï" },
	{ "Ð", "Ð", "Ð", "Ð" },
	{ "Ñ", "Ñ", "Ñ", "Ñ" },
	{ "Ò", "Ò", "Ò", "Ò" },
	{ "Ó", "Ó", "Ó", "Ó" },
	{ "Ô", "Ô", "Ô", "Ô" },
	{ "Õ", "Õ", "Õ", "Õ" },
	{ "Ö", "Ö", "Ö", "Ö" },
	{ "Ø", "Ø", "Ø", "Ø" },
	{ "Ù", "Ù", "Ù", "Ù" },
	{ "Ú", "Ú", "Ú", "Ú" },
	{ "Û", "Û", "Û", "Û" },
	{ "Ý", "Ý", "Ý", "Ý" },
	{ "Þ", "Þ", "Þ", "Þ" },
	{ "ß", "ß", "ß", "ß" },
	{ "á", "á", "á", "á" },
	{ "ã", "ã", "ã", "ã" },
	{ "ä", "ä", "ä", "ä" },
	{ "å", "å", "å", "å" },
	{ "æ", "æ", "æ", "æ" },
	{ "í", "í", "í", "í" }
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	//register_message( ( gMsgId = get_user_msgid("SayText") ), "message_SayText")
	
	register_clcmd("say", "HookSaid")
	
	//register_clcmd("say /arabic", "Switch")
	gMsgId = get_user_msgid("SayText")
	
	gChats = TrieCreate()
	
	for(new i; i < sizeof(gLetters); i++)
		gLetters[i] = TrieCreate()
	
	for(new i; i < sizeof(channels); i++)
		TrieSetCell(gChats, channels[i], 1)
		
	for(new i; i < sizeof(Arabic); i++)
	{
		TrieSetString(gLetters[ALONE], gszEnglishLetters[i], Arabic[i][ALONE])
		TrieSetString(gLetters[INITIAL], gszEnglishLetters[i], Arabic[i][INITIAL])
		TrieSetString(gLetters[MID], gszEnglishLetters[i], Arabic[i][MID])
		TrieSetString(gLetters[FINAL], gszEnglishLetters[i], Arabic[i][FINAL])
	}
}

public client_putinserver(id)
	if(IsInBit(id))	RemoveFromBit(id)
/*
public message_SayText(msg_id, msg_dest, id)
{
	static iSender
	//if(!IsInBit( ( iSender = get_msg_arg_int(1) ) ) )
		//return PLUGIN_CONTINUE
		
	
	static szSaid[256]
	//get_msg_arg_string(2, szSaid, charsmax(szSaid))
	
	#if defined DEBUG
	//server_print("[DEBUG] Channel is: %s", szSaid)
	#endif
	
	if(!TrieKeyExists(gChats, szSaid))
		return PLUGIN_CONTINUE
	
	get_msg_arg_string(4, szSaid, charsmax(szSaid))
	
	replace(szSaid, charsmax(szSaid), "^n", "")
	
	#if defined DEBUG
	server_print("[DEBUG] Said 4 String is: ^"%s^"", szSaid)
	#endif*/
public HookSaid(id)
{
	static szSaid[256]
	read_argv(1, szSaid, charsmax(szSaid))
	
	if(equali(szSaid, "/arabic"))
	{
		Switch(id)
		return PLUGIN_HANDLED
	}
	
	if( !IsInBit(id) )
	{
		//server_print("Not in bit")
		return PLUGIN_CONTINUE
	}
	
	if(!szSaid[0])
		return PLUGIN_CONTINUE

	// CHECKING LETTERS ....
	static szReversed[256]
	
	ReverseString(szSaid, szReversed)
	
	server_print("Reversed string: %s", szReversed)
	
	new i = 0, szLetter[2]
	while(szReversed[i])
	{
		// First letter (Nothing before it
		if(i - 1 < 0)
		{
			szLetter[0] = szReversed[i]
			
			// If there is not any letter after it
			if(szReversed[i + 1] == ' ' || !szReversed[i + 1])
			{
				if( TrieKeyExists(gLetters[ALONE], szLetter[0]))
				{
					#if defined DEBUG
					server_print("[DEBUG] Found letter! (Block 1a)")
					#endif
					TrieGetString(gLetters[ALONE], szLetter[0], szLetter[0], charsmax(szLetter))
				}
			}
			
			// iF there is a letter after it
			else if(gLetters[i + 1])
			{
				if( TrieKeyExists(gLetters[INITIAL], szLetter[0]))
				{
					#if defined DEBUG
					server_print("[DEBUG] Found letter! (Block 1b)")
					#endif
					TrieGetString(gLetters[INITIAL], szLetter[0], szLetter[0], charsmax(szLetter))
				}
			}
			
			
			szReversed[i] = szLetter[i]
			++i
			continue; // Skip rest of code
		}
		
		// Not the first letter
		// ÇáÏ æáíÏ
		
		if(szReversed[i])
		{
			szLetter[0] = szReversed[i]
			
			if(szReversed[i - 1] == ' ') // Before it is a space
			{
				// After it is a space, nothing or number (Make it ALONE)
				if( szReversed[i + 1] == ' ' || szReversed[i + 1] == EOS || isdigit(szReversed[i + 1])) // After it is a space
				{
					if(TrieKeyExists(gLetters[ALONE], szLetter[0]))
						TrieGetString(gLetters[ALONE], szLetter[0], szLetter[0], charsmax(szLetter))
				}
				
				else if(szReversed[i + 1] )  // A letter is after it ..
					if( TrieKeyExists(gLetters[INITIAL], szLetter[0]) )
						TrieGetString(gLetters[INITIAL], szLetter[0], szLetter[0], charsmax(szLetter))
			}
			
			else
			{
				// Before it is a number
				if(isdigit(szReversed[i - 1]) || isdigit(szReversed[i + 1]) )
				{
					if(TrieKeyExists(gLetters[ALONE], szLetter[0]))
						TrieGetString(gLetters[ALONE], szLetter[0], szLetter[0], charsmax(szLetter))
				}
				
				// Before it is a letter
				else
				{
					if(szReversed[i + 1] == ' ')
					{
						if(TrieKeyExists(gLetters[FINAL], szLetter[0]))
							TrieGetString(gLetters[FINAL], szLetter[0], szLetter[0], charsmax(szLetter))
					}
					
					else 
					{
						if(TrieKeyExists(gLetters[MID], szLetter[0]))
							TrieGetString(gLetters[MID], szLetter[0], szLetter[0], charsmax(szLetter))
					}
				}
			}
			
			szReversed[i] = szLetter[0]
			++i
		}
	}
	
	//server_print("szSaid %s", szSaid)
	static szFinal[256]
	ReverseString(szReversed, szFinal)
	write_file("addons/amxmodx/logs/arabic.txt", szFinal)
	
	//set_msg_arg_string(4, szFinal)
	
	// We can't do emessage_begin or it will end in a loop as it will keep detecting the message we sent for sending chat ...
	new iPlayers[32], iNum
	get_players(iPlayers, iNum)
	
	for(new i; i < iNum; i++)
	{
		message_begin(MSG_ALL, gMsgId ,_, iPlayers[i])
		write_byte(id)
		write_string(szFinal)
		message_end()
	}
	
	server_print("He said: %s^n reversed: %s - Arabic.amxx", szSaid, szReversed)
	
	return PLUGIN_HANDLED
}

public Switch(id)
{
	if(IsInBit(id))
	{
		RemoveFromBit(id)
		client_print(id, print_chat, "[AMXX] Now you will talk in english")
		return;
	}
		
	AddToBit(id)
	client_print(id, print_chat, "[AMXX] Now you will talk in arabic.")
}

stock ReverseString(input[], output[]) 
{ 
	new i, j
	
	for( i = strlen( input ) - 1, j = 0 ; i >= 0 ; i--, j++ ) 
	{ 
		output[ j ] = input[ i ]; 
	} 
	
	output[ j ] = '^0'; 
}  
/*
stock ReverseString(input[], output[], size) 
{ 
	new i, j
	static szTemp[256]
	
	copy(szTemp, charsmax(szTemp), input)
	
	for( i = strlen( input ) - 1, j = 0 ; i >= 0 ; i--, j++ ) 
	{ 
		szTemp[ j ] = input[ i ]; 
	} 
	
	szTemp[ j ] = '^0'; 
	
	copy(output, size, szTemp)
}  */
