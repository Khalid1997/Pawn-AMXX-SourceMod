/*
**
*/
#include <sourcemod>

#if defined fdownloader_included
 #endinput
#endif
#define fdownloader_included

/*
*	Add files to the Download list using AddFileToDownloadList function
*	@param Paths		ArrayList that contains paths of file relative to the mod
*						Folder.
*	@error				No Error.
*	@note				Folders ending with * denotes all files in that folder.
*
**/	
native void FDownloader_AddSinglePath(char[] szPath);

/*
*	Add files to the Download list using AddFileToDownloadList function
*	@param Paths		ArrayList that contains paths of file relative to the mod
*						Folder.
*	@error				No Error.
*	@note				Folders ending with * denotes all files in that folder.
*
**/			
native void FDownloader_AddPaths(ArrayList Paths);

/*
*	Same as FDownloader_AddPaths, but uses string arrays as arguments
*	@param StringArray	Array that contains strings
*	@param iNumStrings	How many strings in the string array.
*	
*	@error 				No Error.
**/			
stock void FDownloader_AddPathsEx(char[][] StringArray, int iNumStrings)
{
	ArrayList hArray = CreateArray(PLATFORM_MAX_PATH);
	for (int i; i < iNumStrings; i++)
	{
		hArray.PushString(StringArray[i]);
	}
	
	FDownloader_AddPaths(hArray);
	delete hArray;
}
