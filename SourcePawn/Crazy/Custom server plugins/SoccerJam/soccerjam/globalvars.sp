//GAME
char GameFolderName[MAX_FILENAME_LENGTH]
int TeamScore[TEAMS_COUNT]

int g_Goals[TEAMS_COUNT]
int g_TeamColors[TEAMS_COUNT][] = 
{
	{128, 0, 128, 255},	// None
	{128, 0, 128, 255},	// None
	{255, 10, 10, 255},	// T
	{10, 10, 255, 255}	// CT	
}

bool g_Goal;
char g_TeamSpawnEntityNames[TEAMS_COUNT][MAX_NAME_LENGTH] =
{
	"",	// None
	"",	// None
	"info_player_terrorist",	// T
	"info_player_counterterrorist"	// CT	
}

// BALL
int g_Ball
int g_BallSpawnTeam
bool g_IsBallFree
int g_BallOwner
int g_BallHolder
char g_BallOwnerName[MAX_NAME_LENGTH]
float g_BallRadius
int g_BallTeam;

int g_LaserCache
int g_MiniExplosionSprite

float g_StartBallVelocity[3] = {0.0, 0.0, 100.0}
//float g_DeathZoneOrigins[TEAMS_COUNT][3]
float g_BallSpawnOrigin[3]
float g_BallDistOrigin[2][3]

// PLAYERS

float g_PlayerSpeedMultiplier[MAXPLAYERS+1]
float g_PlayerGravityMultiplier[MAXPLAYERS+1]