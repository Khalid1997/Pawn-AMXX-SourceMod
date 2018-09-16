#include <amxmodx>

public plugin_init()
{
	register_plugin("Auto Redirect test", "1.0", "Test");
	
	register_clcmd("say /test", "CmdTest");
}

public CmdTest(id)
{
	client_cmd(id, "wait;^"connect^" %s", "192.168.0.2:27016")
	//client_cmd(id, "wait;alias 11 ^"motdfile file.txt^"");
	//client_cmd(id, "11");
	
	//client_cmd(id, "wait;alias 11 ^"motd_write test^"");
	//client_cmd(id, "11");
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
