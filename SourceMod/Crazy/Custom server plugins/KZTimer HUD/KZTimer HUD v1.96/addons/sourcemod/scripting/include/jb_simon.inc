/*
**
*/
#if defined _JB_Simon_included
 #endinput
#endif
#define _JB_Simon_included

enum SimonChangedReason
{
	SCR_Generic,
	SCR_Dead,
	SCR_Disconnect,
	SCR_RoundRestart,
	SCR_Admin,
	SCR_Retire
};

#define No_Simon 	0

// Client == 0 then no simon
native bool JB_SetSimon(int client, SimonChangedReason iReason);
native int JB_GetSimon();

forward void JB_OnSimonChanged(int newClient, int oldClient, SimonChangedReason iReason);

