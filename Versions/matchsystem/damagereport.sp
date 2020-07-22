
void DamageReport_OnTakeDamage(int victim, int attacker, float damage)
{
	if(!IsValidClient(attacker, false, true))
	{
		return;
	}
	
	g_flDamage[attacker][victim] += damage;
	g_iHits[attacker][victim]++;
}

void DamageReport_Print(int client)
{
	// Damage report stuff.
	PrintDamageReport(client);
}

void DamageReport_PrintToAll(bool bAliveOnly)
{
	if(bAliveOnly)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				PrintDamageReport(i);
			}
		}
	}
	
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				PrintDamageReport(i);
			}
		}
	}
}

void PrintDamageReport(client)
{
	static int TeamBit = (1<<( CS_TEAM_CT + 1 )) | (1<<( CS_TEAM_T + 1 ));
	
	PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "-------- Damage Report --------");
	
	char iColorLeft, iColorRight;
	int iClientTeamBit;
	int iOtherTeamBit;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) )
		{
			iClientTeamBit	= (1<< (GetClientTeam(client) + 1) );
			iOtherTeamBit	= (1<< (GetClientTeam(i) + 1) );
			
			if( !(iClientTeamBit & TeamBit && iOtherTeamBit & TeamBit && iClientTeamBit != iOtherTeamBit) )
			{
				continue;
			}
			
		#if defined OLD_DAMAGE_REPORT
		
			if(g_flDamage[client][i] > 0.0)	iColorLeft = '\x04';
			else	iColorLeft = '\x01';
			
			if(g_flDamage[i][client] > 0.0)	iColorRight = '\x07';
			else	iColorRight = '\x01';
			
		#else
			
			if(g_iKiller[i] == client)	iColorLeft = '\x04';
			else	iColorLeft = '\x01';
			
			if(g_iKiller[client] == i)	iColorRight = '\x07';
			else	iColorRight = '\x01';
			
		#endif	
			
			PrintToChat_Custom(client, PLUGIN_CHAT_PREFIX, "%s[\x01%d in %d%s] \
			\x01<-> \
			%s[\x01%d in %d%s] \
			\x01- %d HP %N", 

			iColorLeft,
			RoundFloat(g_flDamage[client][i]),
			g_iHits[client][i],
			iColorLeft,
			
			iColorRight,
			RoundFloat(g_flDamage[i][client]),
			g_iHits[i][client],
			iColorRight,
			
			GetClientHealth(i),
			i
			);
		}
	}
}