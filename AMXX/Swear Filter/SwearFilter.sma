#include <amxmodx>
#include <amxmisc>

#define MAX_WORD_CHARACTER_NUMBER 30

new Array:g_hSwearWords
new g_iSwearWordsCount

public plugin_init( ) 
{
	register_plugin( "Swearing Filter", "1.0", "Yousef And Khalid" );
	
	register_clcmd( "say", "Say_Handle" );
	register_clcmd( "say_team", "Say_Handle" );
	
	ReadFile()
}

stock ReadFile()
{
	new const FILE_NAME[] = "swear_words.ini"
	
	g_hSwearWords = ArrayCreate(30, 1)
	
	if(g_hSwearWords == Invalid_Array)
	{
		set_fail_state("Failed creating swear words dynamic array")
		return;
	}
	
	new szFile[60]
	get_configsdir(szFile, charsmax(szFile))
	
	format(szFile, charsmax(szFile), "%s/%s", szFile, FILE_NAME)
	
	new f = fopen(szFile, "r")
	
	if(!f)
	{
		f = fopen(szFile, "a+")
		
		if(!f)
		{
			fclose(f)
			return;
		}
		
		fputs(f, "; Put a swear word in each line^n")
		fputs(f, "; By Pro-Yousef & Khalid :)")
		
		fclose(f)
		fclose(f)
		
		return;
	}
	
	new szLine[MAX_WORD_CHARACTER_NUMBER + 1]
	while(!feof(f))
	{
		fgets(f, szLine, charsmax(szLine))
		trim(szLine)
		
		if(!szLine[0] || szLine[0] == ';' || ( szLine[0] == '/' && szLine[1] == '/' ) || szLine[0] == '#')
		{
			continue;
		}
	
		ArrayPushString(g_hSwearWords, szLine)
		g_iSwearWordsCount++
	}
	
	fclose(f)
	fclose(f)
}

public Say_Handle( id )
{
	new said[256];
	new szCmd[12];
	
	read_argv(0, szCmd, charsmax(szCmd))
	read_argv(1,  said, charsmax( said ));
	//remove_quotes( said );
	
	for( new i = 0, iPos = 0, szWord[MAX_WORD_CHARACTER_NUMBER + 1], iStrLen; i < g_iSwearWordsCount; i++, iPos = 0 )
	{
		ArrayGetString(g_hSwearWords, i, szWord, charsmax(szWord))
		
		iStrLen =  strlen(szWord)

		while( ( iPos = containi( said[iPos], szWord ) ) != -1)
		{
			FilterBadWord(said[iPos], iStrLen)
		}
	}
	
	engclient_cmd(id, szCmd, said)
	return PLUGIN_HANDLED
}

stock FilterBadWord(szOutput[], iWordCharacterNumber)
{
	new i
	for(i = 0; i < iWordCharacterNumber; i++)
	{
		/*if(szOutput[i] == EOS)
		{
			return;
		}*/
		
		if(szOutput[i] == ' ')
		{
			continue;
		}
		
		szOutput[i] = '*'
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
