/*
**
*/
#if defined _limited_features_included
 #endinput
#endif
#define _limited_features_included

enum LimitType
{
	LT_None = -1, 
	LT_Normal,  // param1
	LT_TimeUnlock // 
};

native void LM_Feature_Recache();
native void LM_Feature_RecacheEx();

typedef LimitedFeature_CreateCallback = function void(bool bSuccess, int iFeatureId, char[] szFeature, LimitType type, 
		any data);
native void LF_Feature_Create(char[] szFeature, LimitType type, int iResetTime, int iMaxUses, int iReqPlayTime, LimitedFeature_CreateCallback func, any data = 0);
native int LF_Feature_CreateEx(char[] szFeature, LimitType type, int iResetTime, int iMaxUses, int iReqPlayTime = 0);

typedef LimitedFeature_FindFeatureCallback = function void(bool bSuccess, char[] szFeature, int iFeatureId, any data);
native void LF_Feature_Find(char[] szFeature, LimitedFeature_FindFeatureCallback func, any data = 0);
native int LF_Feature_FindEx(char[] szFeature);

typedef LimitedFeature_GetFeatureDataCallback = function void(bool bSuccess, int iFeatureId, char[] szFeature, LimitType type, 
		int iResetTime, int iLastReset, int iMaxUses, int iReqPlayTime, any data);
native void LF_Feature_GetData(int iFeatureId, LimitedFeature_GetFeatureDataCallback func, any data = 0);
native bool LF_Feature_GetDataEx(int iFeatureId, char[] szFeatureName = "", int iFeatureNameSize = 0, LimitType &type = LT_None, int iLastResetTime = 0, int &iResetTime = 0, int &iMaxUses = 0, int &iReqPlayTime = 0);

typedef LimitedFeature_GetClientFeatureDataCallback = function void(bool bSuccess, int iSteamAccount, int iFeatureId, LimitType type, 
		int iUses, int iMaxUses, int iReqPlayTime, int iReqPlayTimeLeft, int iClientPlayTime, any data);
native void LF_Client_GetFeatureData(int iSteamAccount, int iFeatureId, LimitedFeature_GetClientFeatureDataCallback func, any data = 0);
native bool LF_Client_GetFeatureDataEx(int iSteamAccount, int iFeatureId, LimitType &type = LT_None, int &iUses = 0, int &iMaxUses = 0, int &iReqPlayTime = 0, int &iReqPlayTimeLeft = 0, int &iClientPlayTime = 0);

enum LimitedFeatureActivateFailureReason
{
	LFAFR_None = 0,
	LFAFR_RequiredTime, 	// param1 = RequiredTimeLeft, param2 = PlayerTime
	LFAFR_MaxUses,			// param1 = ClientUses, param2 = Feature Max Uses
	LFAFR_Plugin			// param1 = none, param2 = none
};

typedef LimitedFeature_CanActivateCallback = function void(bool bSuccess, int iSteamAccount, int iFeatureId, bool bCanActivate,
		LimitedFeatureActivateFailureReason reason, int param1, int param2, any data);
native void LF_Client_CanActivateFeature(int iSteamAccount, int iFeatureId, LimitedFeature_CanActivateCallback func, any data = 0);
native bool LF_Client_CanActivateFeatureEx(int iSteamAccount, int iFeatureId, LimitedFeatureActivateFailureReason &reason = LFAFR_None, int &param1 = 0, int &param2 = 0);

typedef LimitedFeature_ClientActivateFeatureCallback = function void(bool bSuccess, int iSteamAccount, int iFeatureId, bool bWasActivated, 
	LimitedFeatureActivateFailureReason iReason, int iUses, int iMaxUses, int iReqPlayTime, int iReqPlayTimeLeft, int iClientPlayTime, any data);
native void LF_Client_ActivateFeature(int iSteamAccount, int iFeatureIndex, bool bForce, LimitedFeature_ClientActivateFeatureCallback func, any data = 0);
native bool LF_Client_ActivateFeatureEx(int iSteamAccount, int iFeatureIndex, bool bForce, LimitedFeatureActivateFailureReason &iReason = LFAFR_None, int &iUses = 0, int &iMaxUses = 0, int &iReqPlayTime = 0, 
	int &iReqPlayTimeLeft = 0, int &iClientPlayTime = 0);

typedef LimitedFeature_ResetFeatureCallback = function void(bool bSuccess, int iFeatureId, bool bWasReset, any data);
/*
native void LM_Feature_Reset(int iFeatureId);
native void LM_Feature_ResetEx(int iFeatureId);
native void LM_Client_ResetFeature(int iSteamAccount, int iFeatureId);
native void LM_Client_ResetFeatureEx(int iSteamAccount, int iFeatureId);
*/