<?php
/*
############################################################
#
# merchantdb - Frontend
# version 0.1.3.8
# Copyright (C) 2004 nic0nac
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

	$datum 		= getdate(time());
	$debug 		= 0;	
	$user		= "dataBase_user";
	$pass		= "dataBase_password";
	$database	= "dataBase_name";
	$server		= "localhost";
	$port		= "3306";
	import_request_variables('p', 'p_');
	import_request_variables('g', 'g_');
	$image_path     = "http://roempire.com/database/images/items/small/";
	$ext_info_url	= "http://www.roempire.com/database/?page=items&act=view&iid=";
	if (!isset($p_ROserver)) $p_ROserver = "Loki";
	if ($p_ROserver == "") $p_ROserver = "Loki";

	if (!$link = mysql_connect("$server:$port", $user, $pass))
		echo mysql_errno().": ".mysql_error()."<BR>";
	
	// Auswahl der zu verwendenden Datenbank auf dem Server
	$query = "use $database";
	if (!mysql_query($query, $link))
	{   
		echo("<font face='Verdana, Arial, Helvetica, sans-serif' size='-1'><H1>Database $dbase not found.</H1></font>\n"); 
		include ("../inc/footer.php");
		die();
	}
	
	$query_count = "SELECT count( id ) AS p_count FROM `shopcont` WHERE 1";
	$res_count = mysql_query($query_count, $link);
	$d_count = mysql_fetch_array($res_count);
	echo "Total prices in DB: " . $d_count[p_count] . "<br>";
	
	$query_time = "SELECT max( time ) AS last FROM `shopvisit` WHERE 1";
	$res_time = mysql_query($query_time, $link);
	$d_time = mysql_fetch_array($res_time);
	echo "Last Merc visited: " .  strftime("%c", $d_time[last]) . "<br>";
?>
<html>
<header>
<title>roshop: <? echo $p_ROserver;?></title>
</header>
<body>
<H1>Price-Check</H1>
<?
	 
if ($p_name<>""){
	echo "Search for: " . $p_name . "<br>\n";
	$query_search = "SELECT name, MIN( price ) AS min, MAX( price ) AS max, AVG( price ) AS mid, STD( price ) AS dev, slots, card1, card2, card3, card4, card1ID, card2ID, card3ID, card4ID, itemID, custom, broken, element, star_crumb FROM shopcont WHERE name LIKE '%$p_name%' AND server = '$p_ROserver'";
	if ($p_map<>"-") $query_search .= " AND map = '$p_map'";
	if ($p_cards) $query_search .= " OR card1 LIKE '%$p_name%' OR card2 LIKE '%$p_name%' OR card3 LIKE '%$p_name%' OR card4 LIKE '%$p_name%'";
	$query_search .= " GROUP BY itemID, custom, broken, slots, card1, card2, card3, card4, element, star_crumb";

#	echo $query_search . "<br>";
	$res_search = mysql_query($query_search, $link); 
	$rows_search = mysql_num_rows($res_search);
	if ((!$res_search) or ($rows_search==0))
	{   
		//echo("Abfrage '$query_search' nicht erfolgreich.\n"); 
		echo "The Search for '$p_name' on '$p_ROserver' found nothing.<br>\n";
	} else {
		echo "Hits: '$rows_search'<br>\n";
		echo "Server: '$p_ROserver'<br>\n";
		echo "<table border=1 width='100%'>\n";
		echo "<tr><td></td><td></td><td>Count</td><td>Name</td><td>slots</td><td>custom</td><td>broken</td><td>card</td><td>card</td><td>card</td><td>card</td><td>element</td><td>creator</td><td>min Zenny</td><td>max Zenny</td><td>avg Zenny</td><td>Std. Dev.</td><td>Hot-Deal under</td></tr>\n";
		while($d_search = mysql_fetch_array($res_search))
		{
			$query_count = "SELECT * FROM shopcont WHERE slots = '" . $d_search[slots] . "' AND card1ID = '" . $d_search[card1ID] . "' AND card2ID = '" . $d_search[card2ID] . "' AND card3ID = '" . $d_search[card3ID] . "' AND card4ID = '" . $d_search[card4ID] . "' AND custom = '" . $d_search[custom] . "' AND element = '" . $d_search[element] . "' AND star_crumb = '" . $d_search[star_crumb] . "' AND itemID = '" . $d_search[itemID] . "' AND server = '$p_ROserver'";
			//echo $query_count . "<br>\n";
			$res_count = mysql_query($query_count, $link); 
			$rows_count = mysql_num_rows($res_count);
			
			echo "<tr>\n";
			echo "<td>" . $d_search[itemID] . "</td>\n";
			echo "<td><img src=\"$image_path";
			
			$itembild = strtr(ltrim($d_search[name]), " ", "_");
			if (($d_search[custom]) AND (substr($itembild, 0,1)=="+")) 
				$itembild = substr($itembild, strlen($d_search[custom])+2, strlen($itembild)-(strlen($d_search[custom])+2));
			echo $itembild . ".gif\" border='0' width='50'></td>\n";
			echo "<td>$rows_count</td>\n";
			echo "<td><a href='" . basename(__FILE__) ."?iid=" . $d_search[itemID];
			echo "&custom=" . $d_search[custom];
			echo "&broken=" . $d_search[broken];
			echo "&element=" . $d_search[element];
			echo "&star_crumb=" . $d_search[star_crumb];
			echo "&card1ID=" . $d_search[card1ID];
			echo "&ROserver=$p_ROserver";
			if ($d_search[card1ID]!='255'){
				echo "&slots=" . $d_search[slots];
				echo "&card3ID=" . $d_search[card3ID] . "&card4ID=" . $d_search[card4ID];
			}
			echo "&card2ID=" . $d_search[card2ID];
			echo "'>$d_search[name]</a>&nbsp;[<a href='$ext_info_url" . $d_search[itemID] . "' target='_new'>?</a>]</td>\n";
			if ($d_search[card1ID]=="255"){
				$slots = 0;
			} else {
				$slots = $d_search[slots];
			}
			if ($slots>0){
				echo "<td>" . $slots . "&nbsp;</td>\n";
			} else {
				echo "<td>-</td>\n";
			}
			if ($d_search[custom]>0){
				echo "<td>+" . $d_search[custom] . "&nbsp;</td>\n";
			} else {
				echo "<td>-</td>\n";
			}
			if ($d_search[broken]>0){
				echo "<td>+</td>\n";
			} else {
				echo "<td>-</td>\n";
			}

			echo "<td>" . $d_search[card1] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card2] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card3] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card4] . "&nbsp;</td>\n";
			echo "<td>";
			for ($i=1; $i<= $d_search[star_crumb]; $i++)
				echo "V";
			echo " " . $d_search[element] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[crafted_by] . "&nbsp;</td>\n";
			echo "<td align='right'>" . number_format($d_search[min]) . "&nbsp;</td>\n";
			echo "<td align='right'>" . number_format($d_search[max]) . "&nbsp;</td>\n";
			echo "<td align='right'>" . number_format($d_search[mid]) . "</td>";
			echo "<td align='right'>&plusmn;&nbsp;" . number_format($d_search[dev]) . "&nbsp;</td>\n";
			$hot_deal = $d_search[mid] - $d_search[dev];
			echo "<td align='right'";
			if ($hot_deal > $d_search[min]){
				echo "bgcolor='red'";
			} else {
				echo "";
			}
			echo ">";
			echo number_format( $hot_deal);
			echo "&nbsp;</td>\n";
			echo "</tr>\n";
		}
		echo "</table>\n";
	}
}

if ($g_iid > 0){
	echo "<H2>Item-Details</H2>\n";
	echo "Server: '$g_ROserver'<br>\n";
		
	if ($g_element==""){	
		$query_search = "SELECT * FROM shopcont WHERE itemID='$g_iid' AND slots='$g_slots' AND custom='$g_custom' AND card1ID='$g_card1ID' AND card2ID='$g_card2ID' AND card3ID='$g_card3ID' AND card4ID='$g_card4ID' AND server = '$g_ROserver'";
	} else {
		 $query_search = "SELECT * FROM shopcont WHERE itemID='$g_iid' AND custom='$g_custom' AND card2ID='$g_card2ID' AND element='$g_element' AND star_crumb=$g_star_crumb AND server = '$g_ROserver'";
        } 
	if ($g_sort<>"") $query_search .= " ORDER BY $g_sort";
	$res_search = mysql_query($query_search, $link); 
	$rows_search = mysql_num_rows($res_search);
	if ((!$res_search) or ($rows_search==0))
	{   
		echo("Abfrage '$query_search' nicht erfolgreich.\n"); 
		echo("The Search for '$g_iid' found nothing.<br>\n");
	} else {
		echo "<table border=1>\n";
		echo "<tr>";
		echo "<td></td><td></td>";
		echo "<td>Name</td>";
		echo "<td>slots</td>";
		echo "<td>custom</td>";
		echo "<td>card</td>";
		echo "<td>card</td>";
		echo "<td>card</td>";
		echo "<td>card</td>";
		echo "<td>element</td>";
		echo "<td>crafted by</td>";
		echo "<td>amount</td>";
		echo "<td><a href='" . basename(__FILE__) ."?sort=price&iid=$g_iid";
		echo "&custom=" . $g_custom;
		echo "&element=" . $g_element;
		echo "&star_crumb=" . $g_star_crumb;
		echo "&card1ID=" . $g_card1ID;
		echo "&slots=" . $g_slots;
		echo "&card3ID=" . $g_card3ID . "&card4ID=" . $g_card4ID;
		echo "&card2ID=" . $g_card2ID;
		echo "&ROserver=$g_ROserver";
		echo "'>Zenny</a></td>";
		echo "<td>Map</td>";
		echo "<td>posX</td>";
		echo "<td>posY</td>";
		echo "<td>Shopownername</td>";
		echo "<td>Shopname</td>";
		echo "<td><a href='" . basename(__FILE__) ."?sort=datum&iid=$g_iid";
		echo "&custom=" . $g_custom;
		echo "&element=" . $g_element;
		echo "&star_crumb=" . $g_star_crumb;
		echo "&card1ID=" . $g_card1ID;
		echo "&slots=" . $g_slots;
		echo "&card3ID=" . $g_card3ID . "&card4ID=" . $g_card4ID;
		echo "&card2ID=" . $g_card2ID;
		echo "&ROserver=$g_ROserver";
		echo "'>Date</a></td>";
		echo "</tr>\n";
		while($d_search = mysql_fetch_array($res_search))
		{
			echo "<tr>\n";
			echo "<td>" . $d_search[itemID] . "</td>\n";
			echo "<td><img src=\"$image_path";
			
			for ($i=0; $i < 11; $i++) {
				$such = "+" . $i;
				$itembild = strtr($itembild, $such , "");
			}
			
			$itembild = strtr(ltrim($d_search[name]), " ", "_");
//			$itembild = strtr($itembild, "'", "\'");
                        if (($d_search[custom]) AND (substr($itembild, 0,1)=="+")) $itembild = substr($itembild, strlen($d_search[custom])+2, strlen($itembild)-(strlen($d_search[custom])+2));	
			echo $itembild . ".gif\"></td>\n";
			echo "<td>$d_search[name] [<a href='$ext_info_url" . $d_search[itemID] . "' target='_new'>?</a>]</td>\n";
			if ($d_search[slots]>0){
				echo "<td>" . $d_search[slots] . "&nbsp;</td>\n";
			} else {
				echo "<td>-</td>\n";
			}
			if ($d_search[custom]>0){
				echo "<td>+" . $d_search[custom] . "&nbsp;</td>\n";
			} else {
				echo "<td>-</td>\n";
			}
			echo "<td>" . $d_search[card1] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card2] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card3] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card4] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[element] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[crafted_by] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[amount] . "&nbsp;</td>\n";
			echo "<td align='right'>" . number_format($d_search[price]) . "&nbsp;</td>\n";
			echo "<td>" . $d_search[map] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[posx] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[posy] . "&nbsp;</td>\n";
			echo "<td><a href='" . basename(__FILE__) ."?sid=" . $d_search[shopOwnerID] . "&ROserver=$g_ROserver'>" . $d_search[shopOwner] . "</a></td>\n";
			echo "<td>" . $d_search[shopName] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[datum] . "</td>\n";
			echo "</tr>\n";
		}
		echo "</table>\n";
	}
}

if ($g_sid>0){
	echo "<H2>Shop-Details</H2>\n";
	echo "Server: '$g_ROserver'<br>\n";
	
	$query_search = "SELECT * FROM shopcont WHERE shopOwnerID=$g_sid AND server='$g_ROserver'";
	if ($g_sort<>"") $query_search .= " ORDER BY $g_sort";
//	echo $query_search;
	$res_search = mysql_query($query_search, $link); 
	$rows_search = mysql_num_rows($res_search);
	if ((!$res_search) or ($rows_search==0))
	{   
		//echo("Abfrage '$query_search' nicht erfolgreich.\n"); 
		echo ("The Search for '$g_iid' found nothing.<br>\n");
	} else {
		echo "<table border=1>\n";
		echo "<tr>";
		echo "<td></td><td></td>";
		echo "<td>Name</td>";
		echo "<td>slots</td>";
		echo "<td>custom</td>";
		echo "<td>card</td>";
		echo "<td>card</td>";
		echo "<td>card</td>";
		echo "<td>card</td>";
		echo "<td>amount</td>";
		echo "<td><a href='" . basename(__FILE__) ."?sort=price&sid=$g_sid";
		echo "&custom=" . $g_custom;
		echo "&element=" . $g_element;
		echo "&star_crumb=" . $g_star_crumb;
		echo "&card1ID=" . $g_card1ID;
		echo "&slots=" . $g_slots;
		echo "&card3ID=" . $g_card3ID . "&card4ID=" . $g_card4ID;
		echo "&card2ID=" . $g_card2ID;
		echo "&ROserver=$g_ROserver";
		echo "'>Zenny</a></td>";
		echo "<td>Map</td>";
		echo "<td>posX</td>";
		echo "<td>posY</td>";
		echo "<td>Shopownername</td>";
		echo "<td>Shopname</td>";
		echo "<td><a href='" . basename(__FILE__) ."?sort=datum&sid=$g_sid";
		echo "&custom=" . $g_custom;
		echo "&element=" . $g_element;
		echo "&star_crumb=" . $g_star_crumb;
		echo "&card1ID=" . $g_card1ID;
		echo "&slots=" . $g_slots;
		echo "&card3ID=" . $g_card3ID . "&card4ID=" . $g_card4ID;
		echo "&card2ID=" . $g_card2ID;
		echo "&ROserver=$g_ROserver";
		echo "'>Date</a></td>";
		echo "</tr>\n";
		while($d_search = mysql_fetch_array($res_search))
		{
			echo "<tr>\n";
			echo "<td>" . $d_search[itemID] . "</td>\n";
			echo "<td><img src=\"$image_path";
			
			$itembild = strtr(ltrim($d_search[name]), " ", "_");
			if (($d_search[custom]) AND (substr($itembild, 0,1)=="+")) $itembild = substr($itembild, strlen($d_search[custom])+2, strlen($itembild)-(strlen($d_search[custom])+2));

			echo $itembild . ".gif\"></td>\n";
			echo "<td><a href='" . basename(__FILE__) ."?iid=" . $d_search[itemID] . "&slots=" . $d_search[slots] . "&custom=" . $d_search[custom] . "&card1ID=" . $d_search[card1ID] . "&card2ID=" . $d_search[card2ID] . "&card3ID=" . $d_search[card3ID] . "&card4ID=" . $d_search[card4ID] . "&ROserver=$g_ROserver'>$d_search[name]</a>&nbsp;[<a href='$ext_info_url" . $d_search[itemID] . "' target='_new'>?</a>]</td>\n";
			if ($d_search[slots]>0){
				echo "<td>" . $d_search[slots] . "&nbsp;</td>\n";
			} else {
				echo "<td>-</td>\n";
			}
			if ($d_search[custom]>0){
				echo "<td>+" . $d_search[custom] . "&nbsp;</td>\n";
			} else {
				echo "<td>-</td>\n";
			}
			echo "<td>" . $d_search[card1] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card2] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card3] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[card4] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[amount] . "&nbsp;</td>\n";
      echo "<td align='right'>" . number_format($d_search[price]) . "&nbsp;</td>\n";
			echo "<td>" . $d_search[map] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[posx] . "</td>\n";
			echo "<td>" . $d_search[posy] . "</td>\n";
			echo "<td>" . $d_search[shopOwner] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[shopName] . "&nbsp;</td>\n";
			echo "<td>" . $d_search[datum] . "</td>\n";
			echo "</tr>\n";
		}
		echo "</table>\n";
	}	
}

echo "<br>\n";
echo "<form method='post' ENCTYPE='multipart/form-data' action='" . basename(__FILE__) ."'>\n";
echo "Item-/Cardname:<input type='text' NAME='name' SIZE='40'><br>\n";

// select map
$city_query = "SELECT map FROM shopcont WHERE -1 GROUP BY map ORDER BY map";
$res_city = mysql_query($city_query, $link); 
$rows_city = mysql_num_rows($res_city);
if ((!$res_city) or ($rows_city==0))
{   
	echo("Abfrage '$query_map' nicht erfolgreich.\n"); 
	
	die();
} else {
	echo "Map: <SELECT NAME='map'>\n";
	echo "<OPTION>-</OPTION>\n";
	while($d_city = mysql_fetch_array($res_city))
	{
		echo "<OPTION>$d_city[map]</OPTION>\n";
	}
	echo "</SELECT>\n";
}

// select server
$server_query = "SELECT server FROM shopcont WHERE -1 GROUP BY server ORDER BY server";
$res_server = mysql_query($server_query, $link); 
$rows_server = mysql_num_rows($res_server);
if ((!$res_server) or ($rows_server==0))
{   
	echo("Abfrage '$query_map' nicht erfolgreich.\n"); 
	
	die();
} else {
	echo "Server: <SELECT NAME='ROserver'>\n";
	while($d_server = mysql_fetch_array($res_server))
	{
		echo "<OPTION";
		if (($d_server[server] == $p_ROserver) or ($d_server[server] == $g_ROserver)) echo " SELECTED ";
		echo ">$d_server[server]</OPTION>\n";
	}
	echo "</SELECT>\n";
}

echo "<input type='checkbox' name='cards' value='-1' /> Search in slots<br>\n";
echo "<input type='submit' name='Submit' value='Search'>\n";
echo "</form>\n";	


?>
	</body>
</html>
