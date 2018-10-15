#include < amxmodx >
#include < amxmisc >
#include < hamsandwich >
#include < fakemeta >
#include < fvault >
#include < colorchat >

#define PASSWORDLENGTH		16
#define COLOR			TEAM_COLOR

#define TASK_KICKPLAYER		300410

new gmsgScreenFade;
new RegTime;
new iMaxPlayers;
new AttemptsPCvar;

new UserFlags[33];
new bool:Passed[33] = true;
new bool:FirstPassed[33] = true;
new bool:FirstSpawn[33] = false;
new bool:Blined[33] = false;
new bool:Freezed[33] = false;
new bool:WasAdmin[33] = false;
new PlayerAttempts[33] = 0;

new BlockedCommands[][] = {
	"say",
	"say_team"
}

new ChangePasswordCommand[] = "/reg_changepass";

new szPrefix[] = "[AMXX]";
new szFileName[] = "RegisterSystem";
new szRegisterCommand[] = "REGISTER_PASS";
new szFirstRegisterCommand[] = "FIRST_REGISTER_PASS";
new szChangePasswordCommand[] = "CHANGE_PASS";

public plugin_init( )
{
	register_plugin( "Register System ( SteamID )", "1.0", "Yousef & Khalid" );
	
	RegTime = register_cvar( "reg_time", "60" );
	AttemptsPCvar = register_cvar( "reg_attempts", "3" );
	
	register_event( "HLTV", "Event_HLTV_New_Round", "a", "1=0", "2=0" );
	register_logevent( "event_RoundStart" , 2, "1=Round_Start" );
	
	RegisterHam( Ham_Spawn, "player", "PlayerSpawn" );
	register_concmd( szRegisterCommand, "Passwording" );
	register_concmd( szFirstRegisterCommand, "Registering" );
	register_concmd( szChangePasswordCommand, "ChangingPassword" );
	
	new Word[50];
	formatex( Word, charsmax( Word ), "say %s", ChangePasswordCommand );
	register_clcmd( Word, "ChangePassword" );
	formatex( Word, charsmax( Word ), "say_team %s", ChangePasswordCommand );
	register_clcmd( Word, "ChangePassword" );
	
	gmsgScreenFade = get_user_msgid( "ScreenFade" );
	iMaxPlayers = get_maxplayers( );
}

public client_putinserver( id )
{
	PlayerAttempts[id] = 0;
	Passed[id] = true;
	FirstPassed[id] = true;
	FirstSpawn[id] = true;
	WasAdmin[id] = false;
	
	if( is_user_admin( id ) )
	{
		new PlayerSteamID[50];
		get_user_authid( id, PlayerSteamID, charsmax( PlayerSteamID ) );
		
		if( GetRegistered( PlayerSteamID ) )
		{
			UserFlags[id] = get_user_flags( id );
			remove_user_flags( id );
			WasAdmin[id] = true;
				
			Passed[id] = false;
				
			BlindHim( id );
		}
		else
		{
			FirstPassed[id] = false;
				
			BlindHim( id );
		}
	}
}

public PlayerSpawn( id )
{
	if( FirstSpawn[id] )
	{
		FirstSpawn[id] = false;
		
		if( is_user_admin( id ) || WasAdmin[id] )
		{
			new PlayerSteamID[50];
			get_user_authid( id, PlayerSteamID, charsmax( PlayerSteamID ) );
			
			if( GetRegistered( PlayerSteamID ) )
			{
				PutThePassword( id );
			}
			else
			{
				YouMustRegister( id );
			}
		}
	}
}

public Event_HLTV_New_Round( )
{
	for( new i = 0; i < iMaxPlayers; i++ )
	{
		if( is_user_connected( i ) )
		{
			if( Blined[i] )
			{
				BlindHim( i );
			}
		}
	}
}

public event_RoundStart( )
{
	for( new i = 0; i < iMaxPlayers; i++ )
	{
		if( is_user_connected( i ) )
		{
			if( Freezed[i] )
			{
				FreezePlayer( i );
			}
		}
	}
}

public client_disconnect( id )
{
	if( task_exists( id + TASK_KICKPLAYER ) )
	{
		remove_task( id + TASK_KICKPLAYER );
	}
}

public ChangePassword( id )
{
	if( is_user_admin( id ) )
	{
		new SteamID[50];
		get_user_authid( id, SteamID, charsmax( SteamID ) );
		
		if( GetRegistered( SteamID ) )
		{
			ColorChat( id, COLOR, "^4%s ^1Type your new password.", szPrefix );
			
			client_cmd( id, "messagemode %s", szChangePasswordCommand );
		}
		else
		{
			ColorChat( id, COLOR, "^4%s ^1You aren't Registered.", szPrefix );
		}
	}
}

public ChangingPassword( id )
{
	if( is_user_admin( id ) )
	{
		new SteamID[50];
		get_user_authid( id, SteamID, charsmax( SteamID ) );
		
		if( GetRegistered( SteamID ) )
		{
			new Argv1[PASSWORDLENGTH + 1];
			read_argv( 1, Argv1, charsmax( Argv1 ) );
			
			SetNewPassword( SteamID, Argv1 );
		}
	}
}

public Passwording( id )
{
	if( WasAdmin[id] )
	{
		new SteamID[50], TypedPassword[PASSWORDLENGTH + 1], RealPassword[PASSWORDLENGTH + 1];
		read_argv( 1, TypedPassword, charsmax( TypedPassword ) );
		get_user_authid( id, SteamID, charsmax( SteamID ) );
		fvault_get_data( szFileName, SteamID, RealPassword, charsmax( RealPassword ) );
		
		if( equal( TypedPassword, RealPassword ) )
		{
			remove_task( id + TASK_KICKPLAYER );
			UnBlindHim( id );
			set_user_flags( id, UserFlags[id] );
			Passed[id] = true;
			UnFreezePlayer( id );
			WasAdmin[id] = false;
			
			ColorChat( id, COLOR, "^4%s ^1Login Successful.", szPrefix );
		}
		else
		{
			PlayerAttempts[id] += 1;
			
			if( PlayerAttempts[id] >= get_pcvar_num( AttemptsPCvar ) )
			{
				server_cmd( "kick #%d ^"Attempts Ended.^"", get_user_userid( id ) );
			}
			else
			{
				ColorChat( id, COLOR, "^4%s ^1You have ^3%d^1/^3%d ^1attempts.", szPrefix, PlayerAttempts[id], get_pcvar_num( AttemptsPCvar ) );
				
				client_cmd( id, "messagemode %s", szRegisterCommand );
			}
		}
	}
}

public client_command( id )
{
	new Argv0[50];
	read_argv( 0, Argv0, charsmax( Argv0 ) );
	
	for( new i = 0; i < sizeof( BlockedCommands ); i++ )
	{
		if( equal( Argv0, BlockedCommands[i] ) )
		{
			if( is_user_connected( id ) && !Passed[id] )
			{
				ColorChat( id, COLOR, "^4%s ^1Before you do any command you must put your password.", szPrefix );
				
				client_cmd( id, "messagemode %s", szRegisterCommand );
				
				return PLUGIN_HANDLED;
			}
			
			if( is_user_connected( id ) && !FirstPassed[id] )
			{
				ColorChat( id, COLOR, "^4%s ^1Before you do any command you must put your password.", szPrefix );
				
				client_cmd( id, "messagemode %s", szFirstRegisterCommand );
				
				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

PutThePassword( id )
{
	set_task( get_pcvar_float( RegTime ), "KickPlayer", id + TASK_KICKPLAYER );
	
	BlindHim( id );
	
	FreezePlayer( id );
	
	ColorChat( id, COLOR, "^4%s ^1Please put your password or you will be kicked after %d seconds.", szPrefix, get_pcvar_num( RegTime ) );
	
	client_cmd( id, "messagemode %s", szRegisterCommand );
}

public Registering( id )
{
	if( is_user_admin( id ) )
	{
		new SteamID[50];
		get_user_authid( id, SteamID, charsmax( SteamID ) );
		
		if( GetRegistered( SteamID ) )
		{
			console_print( id, "You are already registered." );
		}
		else
		{
			new Argv1[PASSWORDLENGTH + 1];
			read_argv( 1, Argv1, charsmax( Argv1 ) );
			
			FirstPassed[id] = true;
			UnFreezePlayer( id );
			
			SetNewPassword( SteamID, Argv1 );
			
			UnBlindHim( id );
			
			ColorChat( id, COLOR, "^4%s ^1Registered Successful.", szPrefix );
		}
	}
}

SetNewPassword( SteamID[], Password[] )
{
	fvault_set_data( szFileName, SteamID, Password );
}

public KickPlayer( Number )
{
	new id = Number - TASK_KICKPLAYER;
	
	if( is_user_connected( id ) )
	{
		server_cmd( "amx_kick #%d ^"Please put the password faster.^"", get_user_userid( id ) );
	}
}

YouMustRegister( id )
{
	BlindHim( id );
	
	FreezePlayer( id );
	
	ColorChat( id, COLOR, "^4%s ^1You must register first.", szPrefix );
	ColorChat( id, COLOR, "^4%s ^1NOTE: The password you will put must be written every login.", szPrefix );
	ColorChat( id, COLOR, "^4%s ^1NOTE: Password length must be %d or less than.", szPrefix, PASSWORDLENGTH );
	
	client_cmd( id, "messagemode %s", szFirstRegisterCommand );
}

FreezePlayer( id ) 
{
	Freezed[id] = true;
	
	if( is_user_alive(id) )
	{
		new iFlags = pev( id, pev_flags );
		
		if( ~iFlags & FL_FROZEN )
		{	
			set_pev( id, pev_flags, iFlags | FL_FROZEN );
		}
	}
}

UnFreezePlayer( id ) 
{
	Freezed[id] = false;
	
	if( is_user_alive(id) )
	{
		new iFlags = pev(id, pev_flags);
		
		if( iFlags & FL_FROZEN )
		{
			set_pev( id, pev_flags, iFlags & ~FL_FROZEN );
		}
	}
}

BlindHim( id )
{
	message_begin( MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id );
	write_short( ( 1 << 3 ) | ( 1 << 8 ) | ( 1 << 10 ) );
	write_short( ( 1 << 3 ) | ( 1 << 8 ) | ( 1 << 10 ) );
	write_short( ( 1 << 0 ) | ( 1 << 2 ) );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	message_end( );
	
	Blined[id] = true;
}

UnBlindHim( id )
{
	message_begin( MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id );
	write_short( 1 << 2 );
	write_short( 0 );
	write_short( 0 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 0 );
	message_end( );
	
	Blined[id] = false;
}

bool:GetRegistered( SteamID[] )
{
	new DataDir[50], Place[100];
	get_datadir( DataDir, charsmax( DataDir ) );
	formatex( Place, charsmax( Place ), "%s/file_vault/%s.txt", DataDir, szFileName );
	
	if( file_exists( Place ) )
	{
		new PassID[PASSWORDLENGTH + 1];
		fvault_get_data( szFileName, SteamID, PassID, charsmax( PassID ) );
		
		if( PassID[0] )
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	
	return false;
}

