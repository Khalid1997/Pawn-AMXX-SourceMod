#if defined _zcore_lootspawner_included
  #endinput
#endif
#define _zcore_lootspawner_included

#define TYPE_NONE -1

#define MAX_LOOTSPAWNS 1024

#define LS_FLAG_TOUCH				(1 << 0)
#define LS_FLAG_USE					(1 << 1)
#define LS_FLAG_NOSHADOWS			(1 << 2)
#define LS_FLAG_NORECEIVESHADOWS	(1 << 3)
#define LS_FLAG_USESPAWNCENTER		(1 << 4)
#define LS_FLAG_BREAK_STARTTOUCH	(1 << 5)
#define LS_FLAG_BREAK_ENDTTOUCH		(1 << 6)
#define LS_FLAG_BREAK_USE			(1 << 7)

#define LS_ACTION_NOSPAWN		-1
#define LS_ACTION_NONE			0
#define LS_ACTION_REMOVE		1
#define LS_ACTION_SPAWN			2
#define LS_ACTION_BREAK			3
#define LS_ACTION_REPLACE		4
#define LS_ACTION_USE			5
#define LS_ACTION_STARTTOUCH	6
#define LS_ACTION_ENDTOUCH		7
#define LS_ACTION_PICKUP		8
#define LS_ACTION_DROP			9
#define LS_ACTION_DESTROY		10
#define LS_ACTION_WIPE			11
#define LS_ACTION_TTL			12

/* Forwards */

forward void ZCore_LootSpawner_OnPluginStart();
forward Action ZCore_LootSpawner_OnLootSpawnThink(int type, int &failStreak);
forward Action ZCore_LootSpawner_OnLootSpawnPre(int type, float pos[3], int &failStreak);
forward Action ZCore_LootSpawner_OnLootSpawned(int entity, int type, int action);
forward Action ZCore_LootSpawner_OnLootAction(int client, int entity, int type, int action);
forward Action ZCore_LootSpawner_OnLootRemoved(int client, int entity, int type, int action);

/* Natives */

native int ZCore_LootSpawner_RegisterLootType(char name[32], char model[256], int health, int ttl, int weight, int roundStartWeight, int maxSpawned, int flags, int minDistance, int maxDistance);
native int ZCore_LootSpawner_DeregisterLootType(char name[32]);

native int ZCore_LootSpawner_GetType(int entity);
native int ZCore_LootSpawner_RemoveLoot(int entity, int client, int action);

native int ZCore_LootSpawner_WipeEntitysAll();
native int ZCore_LootSpawner_WipeEntitysByType(int type);

native int ZCore_LootSpawner_ForceSpawn(int type, float pos[3], int client, int action);
native int ZCore_LootSpawner_ForceSpawnNear(int type, float pos[3], int client, int action, float range_min, float range_max, bool free, bool remove);

public void __pl_zcore_lootspawner_SetNTVOptional() 
{
	MarkNativeAsOptional("ZCore_LootSpawner_RegisterLootType");
	MarkNativeAsOptional("ZCore_LootSpawner_DeregisterLootType");
	MarkNativeAsOptional("ZCore_LootSpawner_GetType");
	MarkNativeAsOptional("ZCore_LootSpawner_RemoveLoot");
	MarkNativeAsOptional("ZCore_LootSpawner_WipeEntitysAll");
	MarkNativeAsOptional("ZCore_LootSpawner_WipeEntitysByType");
	MarkNativeAsOptional("ZCore_LootSpawner_ForceSpawn");
	MarkNativeAsOptional("ZCore_LootSpawner_ForceSpawnNear");
}