int ParticleSystemSpecificId;
int BallExplosionSoundId;

public void BE_Init()
{
	ParticleSystemSpecificId = CreateSpecificString("explosion_particle_system");
	BallExplosionSoundId = CreateSound("ball_explosion");
}

public void BE_OnGoal()
{
	int BallExplosionEntity = CreateEntityByName("info_particle_system");

	char explosionParticlesSystem[MAX_NAME_LENGTH]
	GetSpecificString(ParticleSystemSpecificId, explosionParticlesSystem, sizeof(explosionParticlesSystem));

	DispatchKeyValue(BallExplosionEntity, "effect_name", explosionParticlesSystem);
	DispatchKeyValue(BallExplosionEntity, "start_active", "0");
	DispatchKeyValue(BallExplosionEntity, "flag_as_weather", "0");
	DispatchKeyValue(BallExplosionEntity, "angles", "0 0 0");
	DispatchSpawn(BallExplosionEntity);
	ActivateEntity(BallExplosionEntity);
	
	float ballOrigin[3];
	Entity_GetAbsOrigin(g_Ball, ballOrigin);
	
	TeleportEntity(BallExplosionEntity, ballOrigin, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(BallExplosionEntity, "Start");
	PlaySoundByIdToAll(BallExplosionSoundId);
}