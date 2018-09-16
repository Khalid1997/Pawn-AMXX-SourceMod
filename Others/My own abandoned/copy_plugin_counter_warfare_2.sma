#include <amxmodx>

new const files[][] = {
	"v_sight_ak47",
	"v_sight_aug",
	"v_sight_colt",
	"v_sight_usp",
	"v_sight_deagle",
	"v_sight_p228",
	"v_sight_p90",
	"v_sight_vector",
	"v_sight_fal",
	"v_sight_rpd",
	"v_sight_m4a1",
	"v_sight_striker",
	"v_sight_uzi",
	"v_sight_tar",
	"v_sight_tmp",
	"v_sight_g18",
	"v_sight_m93"
}

public plugin_init()
{
	register_plugin("Copy file", "1.0", "Khalid :)")
	
	new iFile[60], iOther[60]
	
	for(new i ; i < sizeof(files); i++)
	{
		formatex(iFile, charsmax(iFile), "models/cod/%s.mdl", files[i])
		formatex(iOther, charsmax(iOther), "logs/sight/%s.mdl", files[i])
		
		if(!fcopy(iFile, iOther))
			server_print("Failed to copy file %s", iFile)
	}
}
		
	
	
/*
#include <amxmodx>
#include <fakemeta>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "author"

public plugin_precache()
{
	register_forward(FM_PrecacheModel, "Fwd_Precache")
	register_forward(FM_PrecacheGeneric, "Fwd_PrecacheGeneric")
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public Fwd_PrecacheGeneric(szFile[])
{
	write_file("logs/precache_generic.log", szFile)
}

public Fwd_Precache(szFile[])
{
	static szOtherFile[60]
	if(containi(szFile, "v_") != -1)
	{
		copy(szOtherFile, charsmax(szOtherFile), szFile)
		replace(szOtherFile, charsmax(szOtherFile), "models/", "")
		replace(szOtherFile, charsmax(szOtherFile), "cod/", "")
		
		fcopy(szFile, szOtherFile)
	}
	
	//write_file("logs/precache.log", szFile)
}*/
	
#define BUFFERSIZE    256 
enum FWrite 
{ 
	FW_NONE = 0, 
	FW_DELETESOURCE = (1<<0), 
	FW_CANOVERRIDE = (1<<1) 
} 

stock fcopy(read_path[], dest_path[], FWrite:flags = FW_NONE)  
{  
	// Prepare for read   
	new fp_read = fopen(read_path, "rb")  
	
	// No file to read, errors!  
	if (!fp_read)  
	{  
		fclose(fp_read)  
		return 0  
	}  
	
	// If the native cannot override  
	if (file_exists(dest_path) && !(flags & FW_CANOVERRIDE))  
	{ 
		return 0  
	}  
	
	// Prepare for write   
	new fp_write = fopen(dest_path, "wb")  
	
	// Used for copying  
	static buffer[BUFFERSIZE]  
	static readsize  
	
	// Find the size of the files 
	fseek(fp_read, 0, SEEK_END); 
	new fsize = ftell(fp_read); 
	fseek(fp_read, 0, SEEK_SET); 
	
	// Here we copy the info  
	for (new j = 0; j < fsize; j += BUFFERSIZE)  
	{  
		readsize = fread_blocks(fp_read, buffer, BUFFERSIZE, BLOCK_CHAR);  
		fwrite_blocks(fp_write, buffer, readsize, BLOCK_CHAR);  
	}  
	
	// Close the files  
	fclose(fp_read)  
	fclose(fp_write)  
	
	// Can delete source?  
	if (flags & FW_DELETESOURCE)  
		delete_file(read_path)  
	
	// Success  
	return 1  
}  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang13313\\ f0\\ fs16 \n\\ par }
*/
