#if defined _iso_date_time_included_
	#endinput
#endif

#define _iso_date_time_included_

#define INCLUDE_VERSION "1.0"

// For references:
// Datime - DateTime		// Made this up to make it easier to find a function that handles both date and time
// Date		

// --- For each part: (3 parts total)
// 1. Ability to get vars from string.
// 2. Ability to get string from vars.
// 3. Ability to get vars from timestamp
// 4. Ability to get string from timestamp

// Total
// 1. Ability to parse total string into timestamp
// 2. Ability to parse total string into vars
// 3. Ability to build total string from timestamp.

// Time Format from ISO 8601:
// https://en.wikipedia.org/wiki/ISO_8601
// https://www.w3.org/TR/NOTE-datetime
//
// YYYY-MM-DDThh:mm:ss[timezone]
// [timezone] is optional and can be omitted (omittion means UTC time)
//
// Possible timezones:
// Z	- UTC time
// +00
// -0000
// +00:00
// The + or - sign is always required.

/**
 * Some useful constants, instead of being calculated or redefined.
 */

#define MAX_ISO_TIME_LENGTH			9			// sizeof("hh:mm:ss") == 8 + terminator
#define MAX_ISO_DATE_LENGTH			11			// sizeof("YYYY-MM-DD") == 10 + terminator
#define MAX_ISO_TIMEZONE_LENGTH		7 			// sizeof("+00:00") == 6 + terminator;

#define MAX_ISO_DATETIME_LENGTH		26			// sizeof("YYYY-MM-DDThh:mm:ss+00:00") == 25 + terminator

#define UNIX_START_YEAR				1970
#define UNIX_START_MONTH			1
#define UNIX_START_DAY				1
#define UNIX_START_HOUR				0
#define UNIX_START_MINUTE			0
#define UNIX_START_SECOND			0

#define UNIX_START_DATETIME_ISO		"1970-01-01T00:00:00Z"

#define DAYS_IN_YEAR				365
#define DAYS_IN_DAY					1
	
#define HOURS_IN_YEAR				8760
#define HOURS_IN_DAY				24
#define HOURS_IN_HOUR				1
	
#define MINUTES_IN_YEAR				525600
#define MINUTES_IN_DAY				1440
#define MINUTES_IN_HOUR				60
#define MINUTES_IN_MINUTE			1
	
#define SECONDS_IN_YEAR				31536000
#define SECONDS_IN_DAY				86400
#define SECONDS_IN_HOUR				3600		
#define SECONDS_IN_MINUTE			60
#define SECONDS_IN_SECOND			1

#define STRING_DATE_SEPERATOR			"-"
#define CHAR_DATE_SEPERATOR				'-'

#define STRING_TIME_SEPERATOR			":"
#define CHAR_DATE_SEPERATOR				':'

#define STRING_TIMEZONE_SEPERATOR		":"
#define CHAR_TIMEZONE_SEPERATOR			':'
 
/**
 * -------------
 *	Date Stocks
 * -------------
 */
 
 /**
 * Builds an ISO date string from date variables (integers)
 *
 * @note Format of string: YYYY-MM-DD
 *
 *
 * @param szString		String that will store the ISO date string
 * @param iMaxLen		Maximum length of the string
 * @param iYear			Year
 * @param iMonth		Month
 * @param iDay			Day
 * @noreturn
 */
stock void Time_Date_BuildStringFromVars(char[] szString, int iMaxLen, int iYear, int iMonth, int iDay)
{
	FormatEx(szString, iMaxLen, "%04d%c%02d%c%02d", iYear, CHAR_DATE_SEPERATOR, iMonth, CHAR_DATE_SEPERATOR, iDay);
}
 
 /**
 * Parses ISO date string into variables of: Current year, current month, current day (of passed timestamp).
 *
 *
 * @param szString	String that contains the ISO date format.
 * @param iYear		Optional variable to store the year.
 * @param iMonth	Optional variable to store the month.
 * @param iDay		Optional variable to store the day.
 * @noreturn
 */
stock void Time_Date_GetVarsFromString(char[] szString, int &iYear = 0, int &iMonth = 0, int &iDay = 0)
{
	int iLen = strlen(szString);
	
	// We won't edit our original string.
	char[] szCopyDateString = new char[iLen + 1];
	strcopy(szCopyDateString, sizeof szCopyDateString, szString);
	
	ReplaceString(szCopyDateString, sizeof szCopyDateString, CHAR_DATE_SEPERATOR, "");
	
	float flDate = StringToFloat(szCopyDateString);
	// YYYYMMDD
	iYear = RoundToFloor( flDate / 10000.0 );
	iMonth = RoundToFloor( flDate / 100.0 ) - ( iYear * 100.0) );
	iDay = RoundToFloor( flDate - ( iYear * 10000 ) - ( iMonth * 100 ) );
}

/**
 * Builds an ISO date string from a unix timestamp
 *
 *
 * @param szDateString		String that will store the ISO date string
 * @param iMaxLen			Maximum length of the string
 * @param iUnixTimestamp	32 bit integer that stores the unixtimestamp
 * @param flTimeZone		Optional timezone.

 * @noreturn
 */
stock void Time_Date_BuildStringFromUnixTimestamp(char[] szDateString, int iMaxLen, int iUnixTimestamp, float flTimeZone = 0.0)
{
	int iYear, iMonth, iDay;
	Time_UnixTimestamp_GetDateTimeVars(iUnixTimestamp, flTimeZone, iYear, iMonth, iDay);
	
	Time_Date_BuildStringFromVars(szDateString, iMaxLen, iYear, iMonth, iDay);
}

/**
 * -------------
 *	Time Stocks
 * -------------
 */

/**
 * Builds an ISO time string from time variables (integers)
 *
 * @note Format of string: hh:mm:ss
 *
 *
 * @param szString		String that will store the ISO time string
 * @param iMaxLen		Maximum length of the string
 * @param iHour			Hour
 * @param iMinute		Minute
 * @param iSecond		Second
 * @noreturn
 */
stock void Time_Time_BuildStringFromVars(char[] szString, int iMaxLen, int iHour, int iMinute, int iSecond)
{
	FormatEx(szString, iMaxLen, "%02d%c%02d%c%02d", iHour, CHAR_TIME_SEPERATOR, iMinute, CHAR_TIME_SEPERATOR, iSecond);
}

 /**
 * Parses ISO date string into variables of: Current year, current month, current day (of passed timestamp).
 *
 *
 * @param szString		String that contains the ISO time format.
 * @param iHour			Optional variable to store the hour.
 * @param iMinute		Optional variable to store the minute.
 * @param iSecond		Optional variable to store the second.
 * @noreturn
 */
stock void Time_Time_GetVarsFromString(char[] szString, int &iHour = 0, int &iMinute = 0, int &iSecond = 0)
{
	int iLen = strlen(szString);
	
	// We won't edit our original string.
	char[] szCopyTimeString = new char[iLen + 1];
	strcopy(szCopyTimeString, sizeof szCopyTimeString, szString);
	
	ReplaceString(szCopyDateTimeString, sizeof szCopyDateTimeString, STRING_TIME_SEPERATOR, "");
	
	float flTime = StringToFloat(szCopyDateTimeString);
	// hhmmss
	iHour = RoundToFloor( flTime / 10000.0 );
	iMinute = RoundToFloor( flTime / 100.0 ) - ( iHour * 100.0) );
	iDay = RoundToFloor( flTime - ( iHour * 10000.0 ) - ( iMinute * 100.0 ) );
}

/**
 * Builds an ISO time string from a unix timestamp
 *
 *
 * @param szTimeString		String that will store the ISO time string
 * @param iMaxLen			Maximum length of the string
 * @param iUnixTimestamp	32 bit integer that stores the unixtimestamp
 * @param flTimeZone		Optional timezone.
 * @noreturn
 */
stock void Time_Time_BuildStringFromUnixTimestamp(char[] szTimeString, int iMaxLen, int iUnixTimestamp, float flTimeZone = 0.0)
{
	int iHour, iMinute, iSecond;
	Time_UnixTimestamp_GetDateTimeVars(iUnixTimestamp, flTimeZone, _, _, _, iHour, iMinute, iSecond);
	
	Time_Time_BuildStringFromVars(szDateString, iMaxLen, iHour, iMinute, iSecond);
}

/**
 * -------------
 *	Time Zone Stocks
 * -------------
 */

/**
 * Builds an ISO Time Zone string variable from time zone floating point.
 *
 * @note The output is always in the following format: (+/-)hh:mm
 *
 *
 * @param szTimeZoneString	String in which the output (time zone string) is saved.
 * @param iMaxLen			Maximum lenght of the string.
 * @param flTimeZone		the time zone variable.
 * @noreturn
 */
stock void Time_TimeZone_BuildStringFromVar(char[] szTimeZoneString, int iMaxLen, float flTimeZone)
{
	int iHours, int iMinutes;
	iHours = RoundToFloor(flTimeZoneVar);
	iMinutes = RoundFloat( (flTimeZoneVar - iHours) * MINUTES_IN_HOUR)
	
	FormatEx(szTimeZoneString, iMaxLen, "%s%02d%c%02d", flTimeZoneVar >= 0.0 ? "+" : "-", iHours, CHAR_TIMEZONE_SEPERATOR, iMinutes);
}

/**
 * Converts an ISO Time Zone to a floating point variable
 * Example: 3.5, -4.0
 *
 * @note: All output vars are in hours.
 *
 *
 * @param szTimeZoneString		The string that contains the ISO time zone string.
 * @noreturn					time zone float number.
 */
stock void Time_TimeZone_GetVarFromString(char[] szTimeZoneString, float &flTimeZone)
{
	char szCopyTimeZoneString[MAX_TIMEZONE_LENGTH];
	strcopy(szCopyTimeZoneString, sizeof szCopyTimeZoneString, szTimeZoneString);
	
	Time_TimeZone_FixTimeZoneString(szCopyTimeZoneString);
	
	float flTimeZone = StringToFloat(szCopyTimeZoneString);
	float flHours = float(RoundToFloor(flTimeZone / 100.0));
	float flMinutes = ( flTimeZone  - ( flHours * 100.0 ) ) / float(MINUTES_IN_HOUR);
	
	PrintToServer("flReturn = %0.5f  || %0.3f || %0.3f || %0.3f", flHours + flMinutes, flTimeZone, flHours, flMinutes);
	return (flHours + flMinutes);
}

/**
 * Fixes the timezone string by removing unnecessary characters such as: ':'
 * This function also pads the necessary zeros
 *
 * @note: This should only be used when trying to convert the string into an integer
 *			so that 1 hour is 100, and 1 minute is equal to 1.
 *
 *
 * @param szISOTimeZone		The string that contains the ISO time zone.
 * @return					time zone float number.
 */
stock void Time_PrepareConvertTimeZoneString(char szTimeZoneString[], int iMaxLen)
{
	// Possible timezones:
	// Z - UTC
	// +00
	// +100	( 1 hour = 100, 1 minute = 1 ) 
	// -0000
	// +00:00
	
	ReplaceString(szTimeZoneString, iMaxLen, ":", "");
	
	// if the format is +07, for example
	if(strlen(szTimeZoneString) < 4)
	{
		if(StrEqual(szTimeZoneString, "Z", true))
		{
			FormatEx(szTimeZoneString, iMaxLen, "+0000");
		}
		
		else
		{
			// Make hours dividable by 100
			Format(szTimeZoneString, iMaxLen, "%s0", szTimeZoneString);
		}
	}
}

/**
 * Returns a 32-bit unix timestamp from date-time variables with an optional timezone
 *
 * @param iYear			Year (example 1987)
 * @param iMonth		Month	(1-12)
 * @param iDay			Day		(1-31)
 * @param iHour			Hour	(0-23)
 * @param iMinute		Minute	(0-59)
 * @param iSecond		Second	(0-59)
 * @param flTimeZone	Timezone of the vars as a float relative to hours. (+3.5 hours, -4.0 hours)
 * @return				32-bit unix timestamp
 */
stock int Time_GetUnixTimestampFromVars(int iYear, int iMonth, int iDay, int iHour, int iMinute, int iSecond, float flTimeZone = 0.0)
{
	// The day we are at has not finished yet.
	iDay -= 1;
	
	int iDaysElapsed;
	iDaysElapsed = ( ( iYear - UNIX_YEAR_START ) * DAYS_IN_YEAR ) +	// Get days elapsed from past years
	( view_as<int>( Time_HasLeapDayFinishedFromDate(iYear, iMonth, iDay) ) ) +	// Is this year a leap year? if yes, did the leap day finish? if yes, add it.
	( Time_LeapYearsBetween(iYear, UNIX_YEAR_START) );		// Add the leap days of the past years
	
	// Get total days elapsed in this current year
	iDaysElapsed += iDay;
	while(--iMonth > 0)
	{
		iDaysElapsed += Time_GetDaysInMonth(iMonth);
	}
	
	// Finally get the timestamp;
	int iTimestamp = ( iDaysElapsed * SECONDS_IN_DAY ) + ( ( iHour * SECONDS_IN_HOUR ) + ( iMinute * SECONDS_IN_MINUTE ) + iSecond ) + 
	// -- TimeZone stuff --
	RoundFloat( -1.0 * flTimeZone * float(SECONDS_IN_HOUR) );
	
	return iTimestamp;
}

stock int Time_GetUnixTimestampFromDatimeString(char[] szDateTimeString)
{	
	int iYear, iMonth, iDay;
	int iHour, iMinute, iSecond;
	float flTimeZone;
	
	char szTimeString[MAX_ISO_TIME_LENGTH];
	char szDateString[MAX_ISO_DATE_LENGTH];
	char szTimeZoneString[MAX_ISO_TIMEZONE_LENGTH];
	
	Time_ParseISODateString(szDateString, iYear, iMonth, iDay);
	Time_ParseISOTimeString(szTimeString, iHour, iMinute, iSecond);
	flTimeZone = Time_GetTimeZoneVarFromISOTimeZone(szTimeZoneString);
	
	return Time_ConvertVarsToUnixTimestamp(iYear, iMonth, iDay, iHour, iMinute, iSecond, flTimeZone);
}

// ----------------------------------
stock void Time_BuildDatimeString(char[] szDateTimeString, int iMaxLen, char[] szDateString, char[] szTimeString, char[] szTimeZoneString)
{
	FormatEx(szDateTimeString, iMaxLen, "%sT%s%s", szDateString, szTimeString, szTimeZoneString);
}

/**
 * Converts the unix timestamp to ISO 8601 date time format.
 *
 * @note: Format of the date-time will be YYYY-MM-DDThh:mm:ss+00:00
 *
 *
 * @param szDatimeString		String that will store the output of the ISO datetime.
 * @param iMaxLen				Maximum length of the string.
 * @param iUnixTimestamp		32-bit unix timestamp of the given date.
 * @param flTimeZone			Optional time zone that will be included in the string. A value of 0.0 is the UTC time
 * @return						true on success, false on failure.
 */
stock void BuildDatimeStringFromUnixTimestamp(char[] szDatimeString, int iMaxLen, int iUnixTimestamp = -1, float flTimeZone = 0.0)
{
	// Reverse changes due to timestamp
	iUnixTimestamp += (-1.0 * flTimeZone * SECONDS_IN_HOUR);
	
	char szTimeZoneString[MAX_TIMEZONE_LENGTH];
	TimeZoneToTimeZoneString(flTimeZone, 
	
	FormatTime(szDate, sizeof szDate, "%Y-%m-%dT%H:%M:%S", iTimestamp);
	Foramt(szDate, sizeof szDate, "%s%s", szDate, szTimeZoneString);
	
	/* --- */
}

stock bool Time_ParseDatimeString(char[] szDateTimeString,
										char[] szDateString = "", int iDateMaxLen = 0,
										char[] szTimeString = "", int iTimeMaxLen = 0,
										char[] szTimeZoneString = "", int iMaxTimeZoneString = 0);
{
	int iLen = strlen(szDateTimeString)
	
	// We won't edit our original string.
	char[] szCopyDateTimeString = new char[iLen + 1];
	strcopy(szCopyDateTimeString, sizeof szCopyDateTimeString, szDateTimeString);estamp.
		return false;
	}
	
	if(iLen > 19)
	{
		// Time zone is included in the string
		strcopy(szTimeZoneString, iMaxTimeZoneString, szCopyDateTimeString[19]);
		szCopyDateTimeString[19] = 0;
	}
	
	else
	{
		flTimestamp = 0.0;
	}
	
	strcopy(szTimeString, iTimeMaxLen, szCopyDateTimeString[12])
	szCopyDateTimeString[11] = 0;		// Remove the T character too.
	
	strcopy(szDateString, iDateMaxLen, szCopyDateTimeString);
}


/**
 * Combines the date, time, and timezone (pre-built) strings into one string in the ISO 8601 format.
 *
 * @note: Format of the date will be YYYY-MM-DDThh:mm:ss+00:00
 *
 *
 * @param szDateTimeString		String where the output will be saved.
 * @param iMaxLen				Maximum length of the Date and Time string (the one above).
 * @param szDateString			String that contains the date.
 * @param szTimeString			String that contains the time.
 * @param szTimeZoneString		String that contains the time zone.
 * @noreturn
 */
stock void Time_BuildDatimeStringFromStrings(char[] szDateTimeString, int iMaxLen, char[] szDateString, char[] szTimeString, char[] szTimeZoneString)
{
	FormatEx(szDateTimeString, iMaxLen, "%sT%s%s", szDateString, szTimeString, szTimeZoneString);
}

stock void Time_ConvertUnixTimestampToVars(int iUnixTimestamp, float &flTimeZone = 0.0,
											int &iYear = 0, int &iMonth = 0, int &iDay = 0, int &iHour = 0, int &iMinute = 0, int &iSecond = 0)
{
	char szDateTimeString[MAX_ISO_DATETIME_LENGTH];
	char szTimeString[MAX_ISO_TIME_LENGTH];
	char szDateString[MAX_ISO_DATE_LENGTH];
	char szTimeZoneString[MAX_ISO_TIMEZONE_LENGTH];
	
	Time_ConvertUnixTimestampToISODateTime(iUnixTimestamp, szDateTimeString, sizeof szDateTimeString, flTimeZone);
	Time_ParseISODateTimeString(szDateTimeString, szDateString, sizeof szDateString, szTimeString, sizeof szTimeString, szTimeZoneString, sizeof szTimeZoneString);
	
	Time_ParseDateString(szDateString, iYear, iMonth, iDay);
	Time_ParseTimeString(szTimeString, iHour, iMinute, iSecond);
	Time_
}

/**
 * Misc stocks. Still useful to some.
 */

/**
 * Returns the number of days in a specified month.
 *
 * @param iMonth		Month number.
 * @return				Number of days.
 */
stock int Time_GetDaysInMonth(int iMonth)
{
	switch(iMonth)
	{
		case 1:		return 31;
		case 2:		return 28;
		case 3:		return 31;
		case 4:		return 30;
		case 5:		return 31;
		case 6:		return 30;
		case 7: 	return 31;
		case 8:		return 31;
		case 9:		return 30;
		case 10:	return 31;
		case 11:	return 30;
		case 12:	return 31;
	}
	
	return 0;
}

stock bool Time_HasLeapDayFinishedFromDate(int iYear, int iMonth, int iDay)
{
	// Did we even pass and finish the leap day in this year ?
	if(!IsLeapYear(iYear))
	{
		return false;
	}
	
	if(iMonth == 2)
	{
		if(iDay < 28)
		{
			return false;
		}
	}
	
	else if(iMonth < 2)
	{
		return false;
	}

	return true;
}

stock bool Time_IsLeapYear(int iYear)
{
	// Check if it is a leap year.
	// A year is called a leap year if:
	// * it can be devided by 4
	// * it can be devided by 4, 100, and 400
	
	// In other words: 
	// If a year is divisible by 4 and by 100, it is not a leap year unless it is also divisible by 400.
	// www.dataip.co.uk/Reference/LeapYear.php
	
	if(iYear % 4)
	{
		return 0;
	}
	
	if(	!(iYear % 100) )
	{
		if( iYear % 400 )
		{
			return 0;
		}
	}
	
	return 1;
}

// Stolen from 
// http://stackoverflow.com/questions/4587513/how-to-calculate-number-of-leap-years-between-two-years-in-c-sharp
stock int Time_LeapYearsBetween(int iStartYear, int iEndYear)
{
	return LeapYearsBefore(iEndYear) - LeapYearsBefore(iStartYear + 1);
}

static int Time_LeapYearsBefore(int iYear)
{
	iYear--;
	return (iYear / 4) - (iYear / 100) + (iYear / 400);
}