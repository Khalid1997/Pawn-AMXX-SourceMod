public void RBAH_OnMapStart()
{
	Entity_KillAllByClassName("func_bomb_target")
}

public void RBAH_Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{	
	Entity_KillAllByClassName("hostage_entity")
}