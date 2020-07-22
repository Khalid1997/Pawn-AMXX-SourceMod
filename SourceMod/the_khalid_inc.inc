/*
**
*/
#if defined _the_khalid_inc_include_
 #endinput
#endif
#define _the_khalid_inc_include_

#define INC_VERSION	"1.5"

void GetFileExtName(char[] szFile, char[] szExt, int iSize)
{
	int iLen = 0, iTotal = 0;
	while( ( iLen = StrContains(szFile[iTotal], ".") ) != -1 )
	{
		iTotal += iLen + 1; // Move it after the .
		continue;
	}
	
	strcopy(szExt, iSize, szFile[iTotal]);
}


// Undone - Might actually never be.
stock int CountStringArgs(const char[] szBuffer, bool bConsiderInnerQuotes = false)
{
	int iC, iPos, iLen;
	
	switch(bConsiderInnerQuotes)
	{
		case true:
		{
			while( (iPos = StrContains(szString[iLen], "\"", false) ) != -1)
			{
		
			}
		}
		
		case false:
		{
			while( (iPos = StrContains(szString[iLen], "\"", false) ) != -1)
			{
		
			}
		}
	}
	
	return iC;
}

stock int CountStringParts(const char[] szString, char [] szSplitTocken = " ", bool bCountRemainder = false)
{
	int iC, iPos, iLen;
	
	while( (iPos = StrContains(szString[iLen], szSplitTocken, false) ) != -1)
	{
		iLen = iPos + 1;	// Move to the next index (char) after the match.
		iC++;
	}
	
	return bCountRemainder ? iC + 1 : iC;
}

stock bool IsStringNumber(char[] szString)
{
	TrimString(szString);
	
	int i;

	if(szString[0] == '-')
	{
		i = 1;
	}
	
	int iLen = strlen(szString);
	for(bool bFoundDecimal = false; i < iLen; i++)
	{
		if(!bFoundDecimal && szString[i] == '.')
		{
			bFoundDecimal = true;
			continue;
		}
		
		if(!IsCharNumeric(szString[i]))
		{
			return false;
		}
	}
	
	return true;
}

stock void SetArrayValue(any[] Array, int iSize, any Value, int iStartingIndex = 0)
{
	for (int i = iStartingIndex; i < iSize; i++)
	{
		Array[i] = Value;
	}
}