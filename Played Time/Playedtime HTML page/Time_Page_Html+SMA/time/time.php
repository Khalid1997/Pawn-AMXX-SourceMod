<html>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Played Time</title>
<link href="time.css" rel="stylesheet" type="text/css" />
</head>


<?php
$db = mysql_connect("127.0.0.1","root","");
mysql_select_db("khalid",$db);
?>
<body topmargin="0" leftmargin="-2">
<basefont size="-1" face="MS GOTHIC">
<table width="700" cellpadding="0" cellspacing="0">
	<tr>
		<td colspan="13" class="catHead">
			<span class="genmed">
				<b>
					Played Time TOP 100
				</b>
			</span>
		</td>
	</tr>
<tr>
	<td class="row1" align="center">Rank</td>
	<td class="row1" align="center">Name</td>
	<td class="row1" align="center">Played Time</td>
	<td class="row1" align="center">Player Status</td>
	<td class="row1" align="center">Last Activity</td>
	<td class="row1" align="center">Inactive Days</td>
</tr>

<?php

function GetInActivityDays($year, $month, $day)
{
	$iCurrentDay = date("d");
	$iCurrentYear = date("Y");

	$iCurrentMonth = date("m");
	
	$yearDiff = $iCurrentYear - $year;
	$monthDiff = $iCurrentMonth - $month;
	$dayDiff = $iCurrentDay - $day;
	
	$i_return = 0;
	
	if($yearDiff)
	{
		$i_return += ( 364 * $yearDiff);
	}
	
	if($monthDiff)
	{
		$i_return += ( 30 * $monthDiff);
	}
	
	if($dayDiff)
	{
		$i_return += $dayDiff;
	}
	
	return $i_return;
}

	$i = 1;
	$InActiveDays = 0;
	$result = mysql_query("SELECT * FROM played_time ORDER BY played_time DESC LIMIT 100",$db);
	
	if ($myrow = mysql_fetch_array($result))
	{
		do
		{
			//list($a, $b, $c) = explode('-', $myrow["date"]);
			
			$a = date("Y", $myrow["lastjoin"]);
			$b = date("m", $myrow["lastjoin"]);
			$c = date("d", $myrow["lastjoin"]);
			

			
			/*
			switch($myrow["status"])
			{
				case 0:
					$s_status = "Normal Player";
					break;
				
				case 1:
					$s_status = "Adminstrator";
					break;
				
				case 2:
					$s_status = "Golden Player";
					break;
				
				case 3:
					$s_status = "Silver Player";
					break;


				default:
					$s_status = "Unknown Status";
					break;
			}*/
			
			$s_status = "Normal Player";
			
			$InActiveDays = GetInActivityDays($a, $b, $c);
			
			printf("<tr><td align=right>%s</td><td align=center>%s</td><td align=center>%s</td><td align=center>%s</td><td align=center>%s</td><td align=center>%s</td></tr>\n", $i, $myrow["name"], $myrow["played_time"], $s_status, date("d-m-Y", $myrow["lastjoin"]), $InActiveDays);
			$i++;
		}
		while ($myrow = mysql_fetch_array($result));
	}
	
	error_reporting(E_ERROR | E_PARSE | E_DEPRECATED);
?>
</table>
</body>