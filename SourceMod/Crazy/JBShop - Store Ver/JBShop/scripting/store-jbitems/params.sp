int g_iParamsIndexes[Item_Count][MAX_UPGRADES_PLUGIN][MAX_PARAMS + 1];
ArrayList gArray_ParamStorage;

char[] GetParamString(int iParamNumber)
{
	char szString[32];
	FormatEx(szString, sizeof szString, "%s%d", KEY_PARAM_BASE, iParamNumber);
	
	return szString;
}

stock void GetParamsForItem(KeyValues hKv, int iItem, int iUpgradeNumber)
{
	switch(iItem)
	{
		case Item_Invisibility:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1)));		// param1: Float - Duration
		}
		
		case Item_Immortal:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1))); 		// param1: Float - Duration
		}
		
		case Item_Deagle:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Int)
			{
				LogDebug("%s is not int. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetNum(hKv, GetParamString(1))); 			// param1: Int - Total Deagle Bullets
		}
		
		case Item_OpenJail:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1)));			// param1: blind CT duration
			
			if(KvGetDataType(hKv, GetParamString(2)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(2));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 2, KvGetFloat(hKv, GetParamString(2)));			// param1: Open jail time
		}
		
		case Item_Lightsaber:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			if(KvGetDataType(hKv, GetParamString(2)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(2));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1))); //	param1: Extra Slash damage ratio to 1; example: 0.15
			PushParamCell(iItem, iUpgradeNumber, 2, KvGetFloat(hKv, GetParamString(2))); //	param2: Extra Stab damage ratio to 1;
		}
		
		case Item_GuardSkin:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			if(KvGetDataType(hKv, GetParamString(2)) != KvData_Int)
			{
				LogDebug("%s is not int. Rendering item not usable.", GetParamString(2));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1))); //	param1: duration of guard skin
			PushParamCell(iItem, iUpgradeNumber, 2, KvGetNum(hKv, GetParamString(2))); //	param2: give weapons to fake it out or not ?
		}
		
		case Item_Bomb:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			if(KvGetDataType(hKv, GetParamString(2)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(2));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			if(KvGetDataType(hKv, GetParamString(3)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(3));
				g_bItemUsable[iItem] = false;
				return;
			}
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1))); //	param1: Detonate Time
			PushParamCell(iItem, iUpgradeNumber, 2, KvGetFloat(hKv, GetParamString(2))); //	param2: Radius
			PushParamCell(iItem, iUpgradeNumber, 3, KvGetFloat(hKv, GetParamString(3))); //	param3: Maximum damage
		}
		
		case Item_Speed:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			if(KvGetDataType(hKv, GetParamString(2)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(2));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1))); //	param1: Duration
			PushParamCell(iItem, iUpgradeNumber, 2, KvGetFloat(hKv, GetParamString(2))); //	param2: Speed
		}
		
		case Item_Credit:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Float)
			{
				LogDebug("%s is not float. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetFloat(hKv, GetParamString(1))); // param1: bonus Ratio to 1.
		}
		
		case Item_AWP:
		{
			if(KvGetDataType(hKv, GetParamString(1)) != KvData_Int)
			{
				LogDebug("%s is not int. Rendering item not usable.", GetParamString(1));
				g_bItemUsable[iItem] = false;
				return;
			}
			
			PushParamCell(iItem, iUpgradeNumber, 1, KvGetNum(hKv, GetParamString(1))); // param1: bullets count;
		}
	}
}

stock int GetParamArray(int iItem, int iUpgradeNumber, int Param_Position, ParamType Type = Param_Array, any[] AnyArray, int iSize)
{
	int iCells;
	switch(Type)
	{
		case Param_Array:
		{
			iCells = GetArrayArray(gArray_ParamsStorage, g_iParamsIndexes[iItem][iUpgradeNumber][Param_Position], AnyArray, iSize)
		}
		
		case Param_String:
		{
			iCells = GetArrayString(gArray_ParamStorage, g_iParamsIndexes[iItem][iUpgradeNumber][Param_Position], AnyArray, iSize)
		}
	}
	
	return iCells;
}

stock any GetParamCell(int iItem, int iUpgradeNumber, int Param_Position)
{
	return GetArrayCell(gArray_ParamStorage, g_iParamsIndexes[iItem][iUpgradeNumber][Param_Position]);
}

stock void PushParamCell(int iItem, int iUpgradeNumber, int Param_Position, any CellValue)
{
	PushArrayCell(gArray_ParamStorage, CellValue);
	g_iParamsIndexes[iItem][iUpgradeNumber][Param_Position] = GetArraySize(gArray_ParamStorage) - 1;
}

stock void PushParamArray(int iItem, int iUpgradeNumber, int Param_Position, ParamType Param_Type = Param_Array, any[] AnyArray)
{
	if(!g_bInitialized)
	{
		ResetParamArray();
	}
	
	switch(Param_Type)
	{
		case Param_Array:
		{
			PushArrayArray(gArray_ParamStorage, AnyArray);
		}
		
		case Param_String:
		{
			PushArrayString(gArray_ParamStorage, AnyArray);
		}
	}
	
	g_iParamsIndexes[iItem][iUpgradeNumber][Param_Position] = GetArraySize(gArray_ParamStorage) - 1;
}

stock void ResetParamArray()
{
	ClearArray(gArray_ParamStorage);
	
	int i, j, y;
	for(i = 0; i < Item_Count; i++)
	{
		for(j = 0; j < MAX_UPGRADES_PLUGIN; j++)
		{
			for(y= 0; y < MAX_PARAMS; y++)
			{
				g_iParamsIndexes[i][j][y] = -1;
			}
		}
	}
}
