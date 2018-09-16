/*
Arabic in-game writer.
By Khalid

This plugin allows you to type in arabic in the game.
By typing /arabic, you can switch from english typing to arabic and vice versa.

It's not completed yet, it's still the begging of it.
*/

#include <amxmodx>

#define PLUGIN "Arabic talk"
#define VERSION "1.0"
#define AUTHOR "Khalid"

new ArabicWanted[33]
new gMsgId

new const ArabicLetters[][] = {
	"ا",
	"ب",
	"ت",
	"ث",
	"ج",
	"ح",
	"خ",
	"د",
	"ذ",
	"ر",
	"ز",
	"س",
	"ش",
	"ص",
	"ض",
	"ط",
	"ظ",
	"ع",
	"غ",
	"ف",
	"ق",
	"ك",
	"ل",
	"م",
	"ن",
	"ﻫ",
	"و",
	"ي"
}

new const InitialLetters[][] = {
	"ا",
	"ب",
	"ت",
	"ث",
	"ج",
	"ح",
	"خ",
	"د",
	"ذ",
	"ر",
	"ز",
	"س",
	"ش",
	"ص",
	"ض",
	"ط",
	"ظ",
	"ع",
	"غ",
	"ف",
	"ق",
	"ك",
	"ل",
	"م",
	"ن",
	"ه",
	"و",
	"ي"
}

new const MedialLetters[][] = {
	"ا",
	"ب",
	"ت",
	"ث",
	"ج",
	"ح",
	"خ",
	"د",
	"ذ",
	"ر",
	"ز",
	"س",
	"ش",
	"ص",
	"ض",
	"ط",
	"ظ",
	"ع",
	"غ",
	"ف",
	"ق",
	"ك",
	"ل",
	"م",
	"ن",
	"ه",
	"و",
	"ي"
}

new const FinalLetters[][] = {
	"ا",
	"ب",
	"ت",
	"ث",
	"ج",
	"ح",
	"خ",
	"د",
	"ذ",
	"ر",
	"ز",
	"س",
	"ش",
	"ص",
	"ض",
	"ط",
	"ظ",
	"ع",
	"غ",
	"ف",
	"ق",
	"ك",
	"ل",
	"م",
	"ن",
	"ه",
	"و",
	"ي"
}

new const MatchingLetters[][] = {
	"h",
	"f",
	"j",
	"e",
	"[",
	"p",
	"o",
	"]",
	"`",
	"v",
	".",
	"s",
	"a",
	"w",
	"q",
	"'",
	"/",
	"u",
	"y",
	"t",
	"r",
	"\",
	"g",
	"l",
	"k",
	"i",
	",",
	"d"
}


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say", "handle_say")
	register_concmd("amx_arabic", "client_talk")
	gMsgId = get_user_msgid("SayText")
	
}

public handle_say(id)
{	
	if( ArabicWanted[id] )
	{
		new said[256], Reversed[256]
		read_argv(1, said, 255)
		
		
		
		if(said[0] == EOS)
			return PLUGIN_HANDLED
			
		/*for(new i; i < sizeof(MatchingLetters); i++)
		{
			while( replace(said, charsmax(said), MatchingLetters[i], ArabicLetters[i]) )	{	}
		}*/
		
		ReverseString(said, Reversed)
		new i
		for(i = 0; i < 28; i++)
		{			
			/*if( contain(Reversed[i], MatchingLetters[i]) )
				replace_all(Reversed, 255, MatchingLetters[i], ArabicLetters[i])*/
			while( replace( Reversed, charsmax(Reversed), MatchingLetters[i], ArabicLetters[i]) ) { }
		}
		
		//new something[256], anything[256]
		//new j, i
		
		
		
		/*for(i = 27, j = 0; i >= 0; i--, j++)
		{
			formatex(something, charsmax(something), " %s ", MatchingLetters[i])
			server_print("Yea 1")
			if(contain(something, Reversed))
			{
				//server_print("Yea 2")
				//replace_all(Reversed, charsmax(Reversed), something, ArabicLetters[i]) 
				while(replace(Reversed, charsmax(Reversed), something, ArabicLetters[i])) { }
			}
			
			formatex(something, charsmax(something), " %s%s", MatchingLetters[i], MatchingLetters[j])
			server_print("Yea 3")
			if(contain(something, Reversed))
			{
				formatex(anything, charsmax(anything), "%s%s", InitialLetters[i], MedialLetters[i])
				//replace_all(Reversed, charsmax(Reversed), something, InitialLetters[i])
				replace(Reversed, charsmax(Reversed), something, InitialLetters[i])
				server_print("Yea 4")
			}
			
			formatex(something, charsmax(something), "%s%s ", MatchingLetters[i], MatchingLetters[j])
			server_print("Yea 5")
			if(contain(something, Reversed))
			{
				formatex(anything, charsmax(anything), "%s%s", MedialLetters[i], FinalLetters[i])
				//replace_all(Reversed, charsmax(Reversed), something, FinalLetters[i])
				replace(Reversed, charsmax(Reversed), something, FinalLetters[i])
				server_print("Yea 6")
			}
			
			formatex(something, charsmax(something), "%s%s", MatchingLetters[i], MatchingLetters[j])
			server_print("Yea 7")
			if(contain(something, Reversed))
			{
				formatex(anything, 255, "%s%s", MedialLetters[i], MedialLetters[i])
				//replace_all(Reversed, charsmax(Reversed), something, anything)
				replace(Reversed, charsmax(Reversed), something, anything)
				server_print("Yea 8")
			}
		}*/
			
		
		
		server_print("He said: %s, reversed: %s - Arabic.amxx", said, Reversed)
		
		new name[32], output[300]

		get_user_name(id, name, 31)
		
		formatex(output, 299, "^3%s%s ^x01:  %s", (is_user_alive(id) ? "" : ( get_user_team(id) == 3 ? "*SPEC*" : "" ) ), name, Reversed)
		/*if( !is_user_alive(id) )
			formatex(output, 299, "^x01*DEAD* ^x03%s ^x01:  %s", name, Reversed)
		if( get_user_team(id) == 3 )
			formatex(output, 299, "^x01*SPEC* ^x03%s ^x01:  %s", name, Reversed)*/
		
		message_begin(MSG_ALL, gMsgId,_, id)
		write_byte(id)
		write_string(output)
		message_end()
		//client_cmd(id, "say ^"%s^"", Reversed)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
	
}

public client_talk(id)
{
	if(ArabicWanted[id] == 1)
	{
		ArabicWanted[id] = 0
		console_print(id, "[AMXX] Now you can talk in English")
		return PLUGIN_HANDLED
	}
	
	else 
	{
		ArabicWanted[id] = 1
		console_print(id, "[AMXX] Now you can talk in Arabic")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}


public client_disconnect(id)
{
	ArabicWanted[id] = 0
}

public client_connect(id)
{
	ArabicWanted[id] = 0
}

stock ReverseString( input[ ], output[ ] ) 
{ 
	new i, j
	for( i = strlen( input ) - 1, j = 0 ; i >= 0 ; i--, j++ ) 
	{ 
		output[ j ] = input[ i ]; 
	} 
	
	output[ j ] = '^0'; 
}  

/*stock ReverseString( toggle[ ] ) 
{ 
	for( new i = strlen( toggle ) - 1, j = 0, temp ; i > j ; i--, j++ ) 
	{ 
		temp = toggle[ i ]; 
		toggle[ i ] = toggle[ j ]; 
		toggle[ j ] = temp; 
	}
}*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
