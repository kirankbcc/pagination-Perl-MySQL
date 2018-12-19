package pagination;

use pm::myConnection;
my $dbh = new myConnection;

sub new 
{

	my ($class) = shift;
	my $self = {};

	bless($self,$class);

}

sub renderReportsBody
{

 	my ($self,$STDsite,$STDgeo,$STDimt,$STDaccount,$STDautoID,$STDcreator,$STDrelease,$ReportLayerType,$ReportStatusType,$USERDBROLE,$startdate,$enddate,$pageno,$pagesize,$USERDBIOT) = @_;

	#automation,release,Layer,status,client,IMT,creator
	my @builder = ();
	my $type = "\"".join("\",\"",split(/,/,$ReportLayerType))."\"";
	my $status = "\"".join("\",\"",split(/,/,$ReportStatusType))."\"";		
	
	if($STDgeo =~ /.+/){     	push @builder,"iot=\"$STDgeo\""; 	}
	if($STDimt =~ /.+/){     	push @builder,"imt=\"$STDimt\""; 	}
	if($STDaccount =~ /.+/){ 	push @builder,"account=\"$STDaccount\""; }
	if($STDcreator =~ /.+/){ 	push @builder,"username=\"$STDcreator\""; }
	if($STDautoID =~ /.+/){ 	push @builder,"itemnumber IN ($STDautoID)"; }
	if($STDrelease =~ /.+/){ 	push @builder,"releasenum IN ($STDrelease)"; }
	if($ReportLayerType =~ /.+/){ 		push @builder,"type IN ($type)"; }
	if($ReportStatusType =~ /.+/){ 	push @builder,"status IN ($status)"; }
	if($startdate =~ /.+/){ 	push @builder,"(date(timestamp) BETWEEN '$startdate' AND '$enddate')"; }
	if($USERDBROLE !~ /superadmin/){     	push @builder,"iot=\"$USERDBIOT\""; 	}

	my $buildlen = scalar @builder;
	my $qExtention = "WHERE ".join " AND ",@builder if($buildlen > 0);

	#$qExtention =~ s/\\\'/\'/ig;

	 my $query = "SELECT itemnumber,releasenum,type,status,account,iot,imt,username,completename,domain,errornumber,errortext,timestamp FROM reviews $qExtention";
	 my $html_data1;


	 my $reqpage = '1';
	 $reqpage = $pageno if($pageno != '');	

	 my $soth= $dbh->{dbh}->prepare("$query;");
	 $soth->execute();
	 my $num_rows=$soth->rows;
	 my $num_results = 20;
	 $num_results = $pagesize if($pagesize != '');

	 # calculate the number of pages to show
	 my $pagecount = int($num_rows / $num_results);
	 if (($pagecount * $num_results) != $num_rows)
	 {
	  	$pagecount++;
	 }

	 # calculate which results to show in the page
	 my $firstresult = (($reqpage - 1) * $num_results) + 1;
	 my $lastresult = $firstresult + $num_results - 1;
	 if ($lastresult > $num_rows)
	 {
	  	$lastresult = $num_rows;
	 }
	 
	 # sql limit starts at 0
	 my $start_point = $firstresult - 1;
	
	 my $tot = $dbh->{dbh}->prepare("$query LIMIT $start_point,$num_results;"); 
	 $tot->execute();
	 my @results =(); 
	 while(my $row=$tot->fetchrow_hashref)
	 {
	  	push @results,$row;
	 }
	 $tot->finish();

	 # page links
	 my ($prev_link, $next_link, $pagelinks,$lastlink,$firstlink);
	 my $prev_page = $reqpage - 1;
	 my $next_page = $reqpage + 1;
	 
	 if ($reqpage == 1)
	 {
	  	$prev_link = "";

	 }else{

	  	$prev_link = " <a href=\"/index.pl?tab=Reports&page=$prev_page&STDimt=$STDimt&STDaccount=$STDaccount&STDautoID=$STDautoID&STDcreator=$STDcreator&STDrelease=$STDrelease&layer[]=$ReportLayerType&status[]=$ReportStatusType&startdate=$startdate&enddate=$enddate&pagesize=$pagesize\">". "<< pre" . "</a>";
	  	$firstlink = " <a href=\"/index.pl?tab=Reports&STDimt=$STDimt&STDaccount=$STDaccount&STDautoID=$STDautoID&STDcreator=$STDcreator&STDrelease=$STDrelease&layer[]=$ReportLayerType&status[]=$ReportStatusType&startdate=$startdate&enddate=$enddate&pagesize=$pagesize\">first</a>";

	#&STDimt=$STDimt&STDaccount=$STDaccount&STDautoID=$STDautoID&STDcreator=$STDcreator&STDrelease=$STDrelease&layer[]=$ReportLayerType&status[]=$ReportStatusType&startdate=$startdate&enddate=$enddate&pagesize=$pagesize

	 }

	 if ($reqpage == $pagecount)
	 {
	  	$next_link = "";

	 }else{

	  	$next_link = " <a href=\"/index.pl?tab=Reports&page=$next_page&STDimt=$STDimt&STDaccount=$STDaccount&STDautoID=$STDautoID&STDcreator=$STDcreator&STDrelease=$STDrelease&layer[]=$ReportLayerType&status[]=$ReportStatusType&startdate=$startdate&enddate=$enddate&pagesize=$pagesize\">". "next >>" . "</a>";

	 } 

	 if ($pagecount > 1)
	 {
	  	  $pagelinks = $prev_link;
	  	  $pageno = 0 if($pageno == '');

		  while ($pageno < $pagecount)
		  {
			   $pageno++;

			   if ($pageno == $reqpage)
			   {
			    	$lastlink = " <strong>$pageno</strong> ";

			   }else{

			    	$lastlink = " <a href=\"/index.pl?tab=Reports&page=$pageno&STDimt=$STDimt&STDaccount=$STDaccount&STDautoID=$STDautoID&STDcreator=$STDcreator&STDrelease=$STDrelease&layer[]=$ReportLayerType&status[]=$ReportStatusType&startdate=$startdate&enddate=$enddate&pagesize=$pagesize\">last</a>";

			   }

		   	   $pagelinks = $pagelinks . $lastlink;
		  }

		  $pagelinks = $pagelinks . "   " . $next_link;
	 }else{

	  	$pagelinks = "";
	 }




		$html_data1 .= "<br /><br />";
		$html_data1 .= "<table width=\"100%\" height=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"5\" class=\"CriteriaForm\">\n";
		$html_data1 .= "<tr BGcolor=\"#5d6d7e\" height=\"20px\"><td colspan=\"7\" align=\"left\" style=\"color:#ffffff;font-weight:normal;\">Search Results</td>";
		$html_data1 .= "<td colspan=\"4\" style=\"text-align:right;color:#fff;\"><div class=\"paginate\"><span>$firstresult - $lastresult of $num_rows</span>&nbsp;";
		$html_data1 .= "<span>$firstlink</span>&nbsp;<span>$prev_link</span>&nbsp;<span>$reqpage</span>&nbsp;<span>$next_link</span>&nbsp;<span>$lastlink</span>&nbsp;</div></td></tr>";

		$html_data1 .= "<tr><td width=\"5%\" style=\"text-align:left;font-weight:bold;\">Automation</td>\n";
		$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:bold;\">Release</td>\n";
		$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:bold;\">Layer</td>\n";
		$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:bold;\">Status</td>\n";
		$html_data1 .= "<td width=\"15%\" style=\"text-align:left;font-weight:bold;\">Client</td>\n";
		$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:bold;\">IOT</td>\n";
		$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:bold;\">IMT</td>\n";
		$html_data1 .= "<td width=\"20%\" style=\"text-align:left;font-weight:bold;\">Creator</td>\n";
		$html_data1 .= "<td width=\"10%\" style=\"text-align:left;font-weight:bold;\">Errors</td>\n";
		$html_data1 .= "<td width=\"10%\" style=\"text-align:left;font-weight:bold;\">Error Details</td>\n";
		$html_data1 .= "<td width=\"15%\" style=\"text-align:left;font-weight:bold;\">Date/Time</td>\n";
		$html_data1 .= "</tr>\n";

	my $searchrows = scalar @results;

	if($searchrows > 0){

		my $r = 0;
		my $color;

		#while(my @rows = $sth->fetchrow_array()){
		foreach my $rows (@results){

			my $owner = $rows->{'completename'}." (".$rows->{'username'}.") (".$rows->{'domain'}.")";
			if($r%2 == 0){  $color = "#ffffff";  }else{  $color = "#e5e8e8"; }
			my $errordetails;
			my $errors;

			if($USERDBROLE =~ /admin|superadmin/){

				my $btn = "myBtn$r";
				my $modal = "myModal$r";
				my $close = "close$r";

				$errors = $rows->{'errornumber'};

				if($errors > 0){  

					$errordetails .= "<a href=\"#\" id=\"$btn\" title=\"Clicl to View\" onClick=\"OpenModalBox('$modal','$btn','$close')\"><img style=\"opacity: 1;\" height=\"15px\" width=\"20px\" src=\"/img/error.png\" alt=\"Icon\"></a>";
					$errordetails .= "<div id=\"$modal\" class=\"modal\">";
					$errordetails .= "<div class=\"modal-content\"><div class=\"modal-header\"><span class=\"close\" id=\"$close\">&times;</span><h4>Error Details</h4></div>";
					$errordetails .= "<div class=\"modal-body\"><br />";

					my @log = split(/;:;/,$rows->{'errortext'});
					my $i = 1;

					foreach my $val (@log){

						$errordetails .= "$i. $val<br /><br />";
						$i++;
					}

					$errordetails .= "<br /></div>";
					$errordetails .= "<div class=\"modal-footer\"></div>";
					$errordetails .= "</div></div>";

				}else{ $errordetails .= "-"; }

			}else{
				
				$errordetails = "-";

				$errors = "-";

			}

				$html_data1 .= "<tr BGcolor=\"$color\">";
				$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:normal;\">$rows->{'itemnumber'}</td>\n";
				$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:normal;\">$rows->{'releasenum'}</td>\n";
				$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:normal;\">$rows->{'type'}</td>\n";
				$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:normal;\">$rows->{'status'}</td>\n";
				$html_data1 .= "<td width=\"15%\" style=\"text-align:left;font-weight:normal;\">$rows->{'account'}</td>\n";
				$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:normal;\">$rows->{'iot'}</td>\n";
				$html_data1 .= "<td width=\"5%\" style=\"text-align:left;font-weight:normal;\">$rows->{'imt'}</td>\n";
				$html_data1 .= "<td width=\"20%\" style=\"text-align:left;font-weight:normal;\">$owner</td>\n";
				$html_data1 .= "<td width=\"10%\" style=\"text-align:left;font-weight:normal;\">$errors</td>\n";
				$html_data1 .= "<td width=\"10%\" style=\"text-align:left;font-weight:normal;\">$errordetails</td>\n";
				$html_data1 .= "<td width=\"15%\" style=\"text-align:left;font-weight:normal;\">$rows->{'timestamp'}</td>\n";
				$html_data1 .= "</tr>";

			$r++;
		}

	}else{

			$html_data1 .= "<tr BGcolor=\"#ffffff\">";
			$html_data1 .= "<td colspan=\"12\" align=\"center\" style=\"font-weight:normal;padding:30px;\"><i>No Results Found for this Criteria.</i></td>\n";
			$html_data1 .= "</tr>";
	}
	
		$html_data1 .= "</table><br><br><br></div>\n";

	return $html_data1;


}

1;
