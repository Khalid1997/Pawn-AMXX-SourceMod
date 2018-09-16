/*
*
*		Background Sounds
*			
*		H3avY Ra1n (nikhilgupta345)
*
*		Description
*		-----------
*
*			This plugin enables you to play background music on your server
*			during the round. It will start playing at the beginning of the 
*			round, and stop at when the round ends. 

*		Cvars
*		-----
*			ba_ambience <0/1> <default:1> 							- turns plugin on or off
*			ba_sound_change <any number greater than 1> <default:1> - how often a new sound is chosen to be played
*
*		Changelog
*		---------
*		
*			September 05, 2011 	- v1.0 - 	Initial Release
*			September 06, 2011	- v1.0.1 -	Fixed bug with death sounds not playing at the end of the round
*		
*		Credits
*		-------
*		
*			Vaan123			- 	Original Plugin Idea
*			ConnnorMcLeod	- 	Helped me fix a problem I was having with trim()
*
*		
*		Plugin Thread: http://forums.alliedmods.net/showthread.php?p=1548443
*
*/

#include < amxmodx >
#include < amxmisc >
#include < cstrike >

#define TASK_LOOPSOUND 1000

new const g_szPlugin[ ] = "Background Sounds";
new const g_szVersion[ ] = "1.0";
new const g_szAuthor[ ] = "H3avY Ra1n";

new const g_szDefaultSounds[ ][ ] = 
{
	"nightcrawlers/ambiece_4.wav",
    "nightcrawlers/ambience1.mp3",
	"nightcrawlers/ambience1.wav",
	"nightcrawlers/ambience2.mp3",
	"nightcrawlers/ambience2.mp3",
	"nightcrawlers/ambience3.wav",
	"nightcrawlers/ambience3.mp3"
};

new Array:g_aSounds;

new bool:g_bFileExists;

new g_pPluginOn;
new g_pSoundChange;

new g_iRandom;

new g_iRoundNumber;

public plugin_init()
{
	register_plugin( g_szPlugin, g_szVersion, g_szAuthor );

	register_event( "HLTV", "Event_RoundStart", "a", "1=0", "2=0" );

	register_logevent( "LogEvent_RoundEnd", 2, "1=Round_End" );

	g_pPluginOn = register_cvar( "ba_ambience", "1" );
	g_pSoundChange = register_cvar( "ba_sound_changee", "1" );
}

public plugin_precache()
{
	g_aSounds = ArrayCreate( 256 );

	new szDirectory[ 256 ], szMapName[ 32 ];
	get_configsdir( szDirectory, charsmax( szDirectory ) );

	get_mapname( szMapName, charsmax( szMapName ) );

	format( szDirectory, charsmax( szDirectory ), "%s/sounds/%s.ini", szDirectory, szMapName );

	g_bFileExists = bool:file_exists( szDirectory );

	new szPath[ 256 ], bool:bSuccess;

	if( g_bFileExists )
	{
		new iFile = fopen( szDirectory, "rt" );
		
		new szBuffer[ 256 ];
		
		while( !feof( iFile ) )
		{
			fgets( iFile, szBuffer, charsmax( szBuffer ) );

			trim( szBuffer );
			
			remove_quotes( szBuffer );
			
			bSuccess = false;
			
			formatex( szPath, charsmax( szPath ), "sound/%s", szBuffer );
			
			if( !file_exists( szPath ) )
			{
				log_amx( "[Background Sounds] %s does not exist.", szPath );
			}
			
			else
			{
				if( contain( szBuffer, ".mp3" ) )
				{
					precache_generic( szPath );
					bSuccess = true;
				}
				
				else if( contain( szBuffer, ".wav" ) )
				{
					precache_sound( szBuffer );
					bSuccess = true;
				}
				
				else
				{
					log_amx( "[Background Sounds] %s not a valid sound file.", szPath );
				}
			}
			
			if( bSuccess )
				ArrayPushString( g_aSounds, szBuffer );
		}
		
		fclose( iFile );
	}

	else
	{
		for( new i = 0; i < sizeof g_szDefaultSounds; i++ )
		{
			bSuccess = false;
			
			formatex( szPath, charsmax( szPath ), "sound/%s", g_szDefaultSounds[ i ] );
			
			if( !file_exists( szPath ) )
			{
				log_amx( "[Background Sounds] %s does not exist.", szPath );
			}
			
			else
			{
				if( contain( g_szDefaultSounds[ i ], ".mp3" ) )
				{
					precache_generic( szPath );
					bSuccess = true;
				}
				
				else if( contain( g_szDefaultSounds[ i ], ".wav" ) )
				{
					precache_sound( g_szDefaultSounds[ i ] );
					bSuccess = true;
				}
				
				else
				{
					log_amx( "[Background Sounds] %s not a valid sound file.", szPath );
				}
			}
			
			if( bSuccess )
				ArrayPushString( g_aSounds, g_szDefaultSounds[ i ] );
		}
	}
	
	new iSize = ArraySize( g_aSounds );
	
	if( !iSize )
		set_fail_state( "No sound files found." );
	
	else
		g_iRandom = random( iSize );
}

public Event_RoundStart()
{
	if( !get_pcvar_num( g_pPluginOn ) )
		return;

	if( ++g_iRoundNumber % get_pcvar_num( g_pSoundChange ) == 0 && ArraySize( g_aSounds ) > 1 )
	{
		new iOldSound = g_iRandom;
		
		while( g_iRandom == iOldSound )
			g_iRandom = random( ArraySize( g_aSounds ) );
	}

	new szBuffer[ 256 ];
	ArrayGetString( g_aSounds, g_iRandom, szBuffer, charsmax( szBuffer ) );
	
	if( contain( szBuffer, ".mp3" ) != -1 )
	{
		client_cmd( 0, "mp3 loop ^"sound/%s^"", szBuffer );
	}

	else if( contain( szBuffer, ".wav" ) != -1 )
	{
		client_cmd( 0, "stopsound" );
		
		new szPath[ 256 ];
		formatex( szPath, charsmax( szPath ), "sound/%s", szBuffer );
		
		client_cmd( 0, "spk ^"%s^"", szBuffer );
		
		set_task( GetWavDuration( szPath ), "Task_LoopSound", TASK_LOOPSOUND, szBuffer, charsmax( szBuffer ), .flags="b" );
	}
}

public LogEvent_RoundEnd()
{	
	set_task( 2.0, "Task_EndSound" );

	remove_task( TASK_LOOPSOUND );
}

public Task_EndSound()
{
	client_cmd( 0, "stopsound" );
	client_cmd( 0, "mp3 stop" );	
}
	
public Task_LoopSound( szSound[ ], iTaskID )
{
	client_cmd( 0, "stopsound" );
	client_cmd( 0, "spk ^"%s^"", szSound );
}

// Provided by Arkshine
Float:GetWavDuration( const WavFile[] )
{
	new Frequence [ 4 ];
	new Bitrate   [ 2 ];
	new DataLength[ 4 ];
	new File;
	
	// --| Open the file.
	File = fopen( WavFile, "rb" );
	
	// --| Get the frequence from offset 24. ( Read 4 bytes )
	fseek( File, 24, SEEK_SET );
	fread_blocks( File, Frequence, 4, BLOCK_INT );
	
	// --| Get the bitrate from offset 34. ( read 2 bytes )
	fseek( File, 34, SEEK_SET ); 
	fread_blocks( File, Bitrate, 2, BLOCK_BYTE );
	
	// --| Search 'data'. If the 'd' not on the offset 40, we search it.
	if ( fgetc( File ) != 'd' ) while( fgetc( File ) != 'd' && !feof( File ) ) {}
	
	// --| Get the data length from offset 44. ( after 'data', read 4 bytes )
	fseek( File, 3, SEEK_CUR ); 
	fread_blocks( File, DataLength, 4, BLOCK_INT );

	// --| Close file.
	fclose( File );
	
	// --| Calculate the time. ( Data length / ( frequence * bitrate ) / 8 ).
	return float( DataLength[ 0 ] ) / ( float( Frequence[ 0 ] * Bitrate[ 0 ] ) / 8.0 );
}