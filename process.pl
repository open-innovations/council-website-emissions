#!/usr/bin/perl
# Website CO2 emissions calculator v 1.1.2

use utf8;
use lib "lib/";
use JSON::XS;
use Data::Dumper;
use POSIX qw(strftime);
use OpenInnovations::CarbonAPI;
use open qw( :std :encoding(UTF-8) );

require "lib.pl";

%config;

if(-e ".config"){
	open(FILE,".config");
	@lines = <FILE>;
	close(FILE);
	foreach $line (@lines){
		$line =~ s/[\n\r]//g;
		($k,$v) = split(/\t/,$line);
		$config{$k} = $v;
	}
}else{
	print "No .config file.\n";
	exit;
}

$type = $config{'Type'};
$typeplural = $config{'Type (plural)'};
$odir = $config{'Directory'};

$file = $config{'JSON'}||"data/index.json";
$cfile = $config{'CSV'}||"data/index.csv";
$tfile = $config{'TSV'}||"data/index.tsv";

$carbon = OpenInnovations::CarbonAPI->new(("raw"=>$config{'raw'},"CC_GPSAPI_KEY"=>$ENV{'CC_GPSAPI_KEY'}));



if(!-d $odir){
	`mkdir $odir`;
}
if(!-e $odir."template.html"){
	print "No template file at ".$odi."template.html\n";
	exit;
}

open(FILE,$file);
@lines = <FILE>;
close(FILE);

$data = JSON::XS->new->utf8->decode(join("",@lines));

%org;
$ratings = {'A+'=>0,'A'=>0,'B'=>0,'C'=>0,'D'=>0,'E'=>0,'F'=>0};

$avco2 = 0.5;	# Previously 1.76 in v2
$monthlyvisits = 10000;
$mostrecent = "2000-00-00";

# Make the CSV
$tsv = "$config{'Code'}\t$type name\tWebsite\tStatus\tCO2 emissions (g)\tWebsite carbon link\tDate last checked\n";
for $id (sort{$data->{'orgs'}{$a}{'name'} cmp $data->{'orgs'}{$b}{'name'}}(keys(%{$data->{'orgs'}}))){
	$url = "";
	@urls = keys(%{$data->{'orgs'}{$id}{'urls'}});
	# Find the default URL (if there is only one URL this is it)
	if(@urls == 1){
		$url = $urls[0];
	}elsif(@urls > 1){
		for($i = 0; $i < @urls; $i++){
			if($data->{'orgs'}{$id}{'urls'}{$urls[$i]}{'default'}){
				$url = $urls[$i];
			}
		}
		if(!$def){
			print "No default URL provided for $id so using $urls[0]";
			$url = $urls[0];
		}
	}
	$recent = "";
	$lastco = 0;
	@dates = reverse(sort(keys(%{$data->{'orgs'}{$id}{'urls'}{$url}{'values'}})));
	if(@dates == 1){
		$recent = $dates[0];
		$lastco = $data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$recent}{'CO2'};
	}else{
		for($i = 0; $i < @dates; $i++){
			if(!$recent || $lastco eq ""){
				$recent = $dates[$i];
				$lastco = $data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$i]}{'CO2'};
			}
		}
	}

	if($recent gt $mostrecent){ $mostrecent = $recent; }

	if($data->{'orgs'}{$id}{'active'}){
		$tsv .= "$id\t$data->{'orgs'}{$id}{'name'}\t$url";
		$nm = $data->{'orgs'}{$id}{'name'};
		$co2 = $data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$recent}{'CO2'}||"";
		$lnk = $data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$recent}{'ref'};
		$byt = $data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$recent}{'bytes'};
		if($co2){
			$tsv .= "\t\t".sprintf("%0.2f",$co2)."\t$lnk";
		}else{
			$tsv .= "\tFAIL\t\t"
		}
		$tsv .= "\t$recent\n";
		$org{$id} = {'name'=>$nm,'url'=>$url,'CO2'=>$co2,'link'=>$lnk,'date'=>$recent,'bytes'=>$byt,'blocked'=>($data->{'orgs'}{$id}{'blocked'} ? 1:0)};
	}
}
# Now go through everything again and compare the overall most recent date with data from a year before
if($mostrecent =~ /^([0-9]{4})\-([0-9]{2})/){
	$y = $1-1;
	$m = $2;
	$yearago = "$y-$m";
	$values = {'size'=>{'yearago'=>[],'now'=>[]},'co2'=>{'yearago'=>[],'now'=>[]}};
	for $id (sort{$data->{'orgs'}{$a}{'name'} cmp $data->{'orgs'}{$b}{'name'}}(keys(%{$data->{'orgs'}}))){
		$url = "";
		@urls = keys(%{$data->{'orgs'}{$id}{'urls'}});
		# Find the default URL (if there is only one URL this is it)
		if(@urls == 1){
			$url = $urls[0];
		}elsif(@urls > 1){
			for($i = 0; $i < @urls; $i++){
				if($data->{'orgs'}{$id}{'urls'}{$urls[$i]}{'default'}){
					$url = $urls[$i];
				}
			}
			if(!$def){
				print "No default URL provided for $id so using $urls[0]";
				$url = $urls[0];
			}
		}
		@dates = reverse(sort(keys(%{$data->{'orgs'}{$id}{'urls'}{$url}{'values'}})));
		$yearago = "";
		if($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$mostrecent}){
			for($d = 0; $d < @dates; $d++){
				if($dates[$d] =~ /$y-$m/){ $yearago = $dates[$d]; }
			}
			if($yearago){
				#print "A year ago $mostrecent to $yearago ($id)\n";
				push(@{$values->{'co2'}{'yearago'}},$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$yearago}{'CO2'});
				push(@{$values->{'co2'}{'now'}},$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$mostrecent}{'CO2'});
				push(@{$values->{'size'}{'yearago'}},$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$yearago}{'bytes'});
				push(@{$values->{'size'}{'now'}},$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$mostrecent}{'bytes'});
			}
		}
	}
	$n = @{$values->{'co2'}{'yearago'}};
	msg("Based on <yellow>".$n."<none> entries, since last year\n");
	msg("\t- the median CO2 has changed from <yellow>".median(@{$values->{'co2'}{'yearago'}})."g<none> to <yellow>".median(@{$values->{'co2'}{'now'}})."g<none>\n");
	msg("\t- the median homepage size has changed from <yellow>".sprintf("%0.1f",median(@{$values->{'size'}{'yearago'}})/1e6)."MB<none> to <yellow>".sprintf("%0.1f",median(@{$values->{'size'}{'now'}})/1e6)."MB<none>\n");
}


@vals = split(/\t/,$tsv);
$csv = "";
for($i = 0; $i < @vals; $i++){
	$csv .= ($vals[$i] =~ /\,/ ? "\"$vals[$i]\"" : $vals[$i]);
	$csv .= ",";
}

open(FILE,">",$tfile);
print FILE $tsv;
close(FILE);

open(FILE,">",$cfile);
print FILE $csv;
close(FILE);

open(FILE,"index.html");
@lines = <FILE>;
close(FILE);
$str = join("",@lines);
if($str =~ /<time datetime="([^\"]*)">([^\<]*)<\/time>/){
	$lastupdate = $1;
	if($mostrecent gt $lastupdate){
		print "Updating timestamp from $lastupdate to $mostrecent\n";
		$mostrecentnice = ISO2String("%d %B %Y",$mostrecent);
		$str =~ s/<time datetime="([^\"]*)">([^\<]*)<\/time>/<time datetime="$mostrecent">$mostrecentnice<\/time>/;
		open(FILE,">","index.html");
		print FILE $str;
		close(FILE);
	}
}

@order = reverse(sort{$org{$a}{'CO2'} <=> $org{$b}{'CO2'} || $org{$a}{'name'} cmp $org{$b}{'name'}}(keys(%org)));

$idt = "				";
$table = "\n$idt<table class=\"table-sort\">\n$idt\t<thead><tr><th>Rank</th><th>$type</th><th>$config{'Code'}</th><th>CO2 (g)</th><th>Rating</th><th>MB</th><th>Updated</th><th>Note</th></tr></thead>\n";
#$tablebest = "\n$idt<table class=\"top top-best\">\n$idt\t<thead><tr><th>$type</th><th>CO2 (g)</th><th><a href=\"https://www.websitecarbon.com/introducing-the-website-carbon-rating-system/\">Rating</a></th></tr></thead>\n";
$tablebest = "\n$idt<h2>Best $config{'Top'} homepages for emissions</h2>\n$idt<ul class=\"grid top top-best\">\n";
$tableworst = "\n$idt<h2>Worst $config{'Top'} homepages for emissions</h2>\n$idt<ul class=\"grid top top-worst\">\n";
$rank = 1;
$av = 0;
$tot = @order;
$lastco2 = 1e100;
$median = 0;
$missing = 0;
@best = ();
@worst = ();
$nn = 0;
for($i = 0; $i < $tot; $i++){
	if($org{$order[$i]}{'CO2'}){ $nn++; }
}
$half = int($nn/2);

if($nn == 0){
	print "No values!\n";
	exit;	
}

for($i = 0; $i < $tot; $i++){
	$id = $order[$i];
	$org{$id}{'rank'} = $i+1;
	if($org{$id}{'CO2'} < $lastco2){
		$rank = $i+1;
	}
	$av += $org{$id}{'CO2'};
	if($i==$half){
		$median = $org{$id}{'CO2'};
	}
	$rating = "?";
	if(!defined($org{$id}{'CO2'})){
		$missing++;
	}else{
		($rating,$rcls) = getRating($org{$id}{'CO2'});
	}
	$ratings->{$rating}++;
	$url = $org{$id}{'url'};
	$url =~ s/^https?:\/\///g;
	$url =~ s/^www\.//g;
	$url =~ s/\/$//g;
	$tr = "$idt\t<tr".($org{$id}{'blocked'} ? " class=\"blocked\"":"")."><td class=\"cen\">$rank</td><td><a href=\"$odir$id.html\">".$org{$id}{'name'}.($org{$id}{'url'} ? "</a>":"")."</td><td class=\"cen\">$id</td><td class=\"cen\">".($org{$id}{'link'} ? "<a href=\"$org{$id}{'link'}\">":"").($org{$id}{'CO2'} ? sprintf("%0.2f",$org{$id}{'CO2'}) : "?").($org{$id}{'link'} ? "</a>":"")."</td><td class=\"cen rating $rcls\">$rating</td><td class=\"cen\">".sprintf("%0.1f",$org{$id}{'bytes'}/1e6)."</td><td class=\"cen\">$org{$id}{'date'}</td><td>".($org{$id}{'blocked'} ? "BLOCKED":"")."</td></tr>\n";
	$table .= $tr;
	if(!$org{$id}{'blocked'}){
		$tr2 = "$idt\t<li><a href=\"$odir$id.html\"><img src=\"$odir$id.webp\" /><div class=\"about\"><div class=\"title\">".$org{$id}{'name'}."</div><div class=\"rating $rcls\">$rating</div></div></a></li>\n";
		if($org{$id}{'CO2'} > 0){
			$n = @worst;
			if($n < $config{'Top'}){
				push(@worst,$tr2);
			}
			push(@best,$tr2);
			$n = @best;
			if($n > $config{'Top'}){
				shift(@best);
			}
		}
		$lastco2 = $org{$id}{'CO2'};
	}
}
@best = reverse(@best);
for($i = 0; $i < @best; $i++){
	$tablebest .= $best[$i];
}
for($i = 0; $i < @worst; $i++){
	$tableworst .= $worst[$i];
}
$table .= "$idt</table>\n";
$tablebest .= "$idt</ul>\n";
$tableworst .= "$idt</ul>\n";


$ratingnmax = 0;
foreach $rating (keys(%{$ratings})){
	if($ratings->{$rating} > $ratingnmax){ $ratingnmax = $ratings->{$rating}; }
}
$tablerate = "<ul class=\"ratings\">";
$tablerate .= "<li><div style=\"width:".sprintf("%0.1f",90*$ratings->{'A+'}/$ratingnmax)."%\" class=\"rate-aplus\">A+</div> $ratings->{'A+'}</li>";
$tablerate .= "<li><div style=\"width:".sprintf("%0.1f",90*$ratings->{'A'}/$ratingnmax)."%\" class=\"rate-a\">A</div> $ratings->{'A'}</li>";
$tablerate .= "<li><div style=\"width:".sprintf("%0.1f",90*$ratings->{'B'}/$ratingnmax)."%\" class=\"rate-b\">B</div> $ratings->{'B'}</li>";
$tablerate .= "<li><div style=\"width:".sprintf("%0.1f",90*$ratings->{'C'}/$ratingnmax)."%\" class=\"rate-c\">C</div> $ratings->{'C'}</li>";
$tablerate .= "<li><div style=\"width:".sprintf("%0.1f",90*$ratings->{'D'}/$ratingnmax)."%\" class=\"rate-d\">D</div> $ratings->{'D'}</li>";
$tablerate .= "<li><div style=\"width:".sprintf("%0.1f",90*$ratings->{'E'}/$ratingnmax)."%\" class=\"rate-e\">E</div> $ratings->{'E'}</li>";
$tablerate .= "<li><div style=\"width:".sprintf("%0.1f",90*$ratings->{'F'}/$ratingnmax)."%\" class=\"rate-f\">F</div> $ratings->{'F'}</li>";
$tablerate .= "</ul>";
print "$ratingnmax\n";
print "nn = $nn\n";
$av /= $nn;

$better = ($av < $avco2);
$howwell = "much better";
if($av > 0.5*$avco2){ $howwell = "well"; }
if($av > 0.75*$avco2){ $howwell = "better"; }
if($av > 1*$avco2){ $howwell = "OK"; }
if($av > 1.25*$avco2){ $howwell = "badly"; }
$results = "The average emissions from a $type homepage are <strong class=\"bold\">".sprintf("%.2f",$av)."g</strong> (median of <strong class=\"bold\">".sprintf("%.2f",$median)."g</strong>) which is ".($better ? "better than":"worse than")." an average website (".$avco2."g). Overall, ".$typeplural." are doing <strong class=\"bold\">$howwell</strong>.";
if($missing > 0){
	$results .= " We were unable to calculate emissions for <strong class=\"bold\">$missing out of $tot</strong> ".$typeplural." possibly due to their sites blocking automated requests.";
}
$results .= " See the <a href=\"#full-list\">full list below</a>.";

$results = "\n$idt<p>$results</p>\n";

# Read in the index.html page
open(FILE,"index.html");
@lines = <FILE>;
close(FILE);
$str = join("",@lines);
# Replace newlines
$str =~ s/\n/=NEWLINE=/g;
# Update parts of the page
$str =~ s/(<\!-- Start best -->).*(<\!-- End best -->)/$1$tablebest$2/;
$str =~ s/(<\!-- Start worst -->).*(<\!-- End worst -->)/$1$tableworst$2/;
$str =~ s/(<\!-- Start table -->).*(<\!-- End table -->)/$1$table$2/;
$str =~ s/(<\!-- Start results -->).*(<\!-- End results -->)/$1$results$2/;
$str =~ s/(<\!-- Start ratings -->).*(<\!-- End ratings -->)/$1$tablerate$2/;
# Replace our temporary newlines
$str =~ s/=NEWLINE=/\n/g;

# Save the result
open(FILE,">","index.html");
print FILE $str;
close(FILE);



# Read the template
open(FILE,$odir."template.html");
@lines = <FILE>;
close(FILE);
$html = join("",@lines);

$indent = "\t\t\t\t";
%biggestfiles;
$fullsavings = 0;
$co2savings = 0;
$jqueryorg = 0;
%cookie = ('civiccomputing.com'=>{'total'=>0,'n'=>0},'freeprivacypolicy.com'=>{'total'=>0,'n'=>0},'cookiepro.com'=>{'total'=>0,'n'=>0},'cookiebot.com'=>{'total'=>0,'n'=>0},'cookielaw.org'=>{'total'=>0,'n'=>0},'cookiereports.com'=>{'total'=>0,'n'=>0},'privacypolicies.com'=>{'total'=>0,'n'=>0});


# Create a "replaces" structure for each org using the "replacedBy" structures
for $id (keys(%{$data->{'orgs'}})){
	if($data->{'orgs'}{$id}{'replacedBy'}){
		if(ref($data->{'orgs'}{$id}{'replacedBy'}{'id'}) eq "ARRAY"){
			for($r = 0; $r < @{$data->{'orgs'}{$id}{'replacedBy'}{'id'}}; $r++){
				$rid = $data->{'orgs'}{$id}{'replacedBy'}{'id'}[$r];
				if(!$data->{'orgs'}{$rid}{'replaces'}){ $data->{'orgs'}{$rid}{'replaces'} = {}; }
				$data->{'orgs'}{$rid}{'replaces'}{$id} = 1;
			}
		}else{
			$rid = $data->{'orgs'}{$id}{'replacedBy'}{'id'};
			if(!$data->{'orgs'}{$rid}{'replaces'}){ $data->{'orgs'}{$rid}{'replaces'} = {}; }
			$data->{'orgs'}{$rid}{'replaces'}{$id} = 1;
		}
	}
}

# Make a page for each org
for $id (sort{$data->{'orgs'}{$a}{'name'} cmp $data->{'orgs'}{$b}{'name'}}(keys(%{$data->{'orgs'}}))){

	$txt = $html;
	$body = "<h1>$data->{'orgs'}{$id}{'name'} - <code>$id</code>".($data->{'orgs'}{$id}{'active'} ? "<span class=\"c5-bg code\">ACTIVE</span>":"<span class=\"c12-bg code\">INACTIVE</span>")."</h1>\n";

	# Create any "replaced by" links
	if($data->{'orgs'}{$id}{'replacedBy'}){
		$replaces = "";
		if(ref($data->{'orgs'}{$id}{'replacedBy'}{'id'}) eq "ARRAY"){
			for($r = 0; $r < @{$data->{'orgs'}{$id}{'replacedBy'}{'id'}}; $r++){
				$rid = $data->{'orgs'}{$id}{'replacedBy'}{'id'}[$r];
				$replaces .= ($r > 0 ? ", " : "")."<a href=\"$rid\.html\">$data->{'orgs'}{$rid}{'name'}</a>";
			}
			$replaces .= " on $data->{'orgs'}{$id}{'replacedBy'}{'date'}";
		}else{
			$rid = $data->{'orgs'}{$id}{'replacedBy'}{'id'};
			$replaces = "<a href=\"$rid\.html\">$data->{'orgs'}{$rid}{'name'}</a> on $data->{'orgs'}{$id}{'replacedBy'}{'date'}";
		}

		$body .= "$indent<p>Replaced by $replaces.</p>";
	}

	# Create any "replaces" links
	if($data->{'orgs'}{$id}{'replaces'}){
		@rids = sort(keys(%{$data->{'orgs'}{$id}{'replaces'}}));
		$replaces = "";
		for($r = 0; $r < @rids; $r++){
			$rid = $rids[$r];
			msg("<yellow>$id<none> ($data->{'orgs'}{$id}{'name'}) => <yellow>$rid<none> - $data->{'orgs'}{$rid}{'name'}\n");
			$replaces .= ($replaces ? ", " : "")."<a href=\"$rid\.html\">$data->{'orgs'}{$rid}{'name'}</a>";
		}
		$body .= "$indent<p>Replaced $replaces.</p>";
	}



	@urls = keys(%{$data->{'orgs'}{$id}{'urls'}});
	if($org{$id}{'rank'}/$nn < 0.5){
		#$body .= "$indent<p>Worse than ".sprintf("%d",(100*(1 - $org{$id}{'rank'}/$nn)))."% of orgs tested.</p>\n";
	}else{
		#$body .= "$indent<p>Better than ".sprintf("%d",(100*($org{$id}{'rank'}/$nn)))."% of orgs tested.</p>\n";
	}
	$body .= "$indent<h2>Emissions</h2>\n";
	$body .= "$indent<ul class=\"emissions\">\n";

	for($i = 0; $i < @urls; $i++){
		$url = $urls[$i];

		# Get the lighthouse details
		$details = getDetails($urls[$i]);
		if($details->{'file'}){
			#print "Using details for $id\n";
		}

		$body .= "$indent\t<li>\n";
		$body .= "$indent\t<div>\n";
		$body .= "$indent\t\t<p><strong>URL:</strong> <a href=\"$url\">$url</a></p>\n";
		if($details->{'first-contentful-paint'}){
			$body .= "$indent\t\t<p><strong>Time to load:</strong> ".sprintf("%0.1f",($details->{'first-contentful-paint'}{'numericValue'}/1000))." seconds</p>\n";
		}
		if(defined($data->{'orgs'}{$id}{'blocked'})){
			$body .= "<p class=\"warning padded\">Note that as of $data->{'orgs'}{$id}{'blocked'} this council is blocking our tool from measuring their page.</p>";
		}
		$body .= "$indent\t\t<table>\n$indent\t\t\t<thead><tr><th>Date checked</th><th class=\"cen\">CO2 / grams</th><th class=\"cen\">Rating</th><th class=\"cen\">Page size</th><th class=\"cen\"><a href=\"https://www.thegreenwebfoundation.org/directory/\">Energy</a></th></tr></thead>\n";
		@dates = reverse(sort(keys(%{$data->{'orgs'}{$id}{'urls'}{$url}{'values'}})));
		for($d = 0; $d < @dates; $d++){
			if(defined($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'CO2'})){
				($rating,$rcls) = getRating($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'CO2'});
			}else{
				$rating = "";
				$rcls = "";
			}
			$body .= "$indent\t\t\t<tr><td>$dates[$d]</td><td class=\"cen\">".(defined($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'CO2'}) ? sprintf("%0.2f",$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'CO2'}) : "BLOCKED")."</td><td class=\"cen rating $rcls\">$rating</td><td class=\"cen\" data=\"$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'bytes'}\">".niceSize($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'bytes'})."</td><td class=\"cen ".($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'green'} ? "c5-bg":"")."\">".($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'green'} ? "GREEN":"GRID?")."</td></tr>\n";
		}
		$body .= "$indent\t\t</table>\n";

		%doneimages = "";
		%duplicates = "";
		$large = 30000;
		if($details->{'images'}){
			$nimages = 0;
			$imsaving = 0;
			$doneimages{$details->{'images'}{'items'}[$j]{'url'}} = 1;
			for($j = 0; $j < @{$details->{'images'}{'items'}}; $j++){
				if($details->{'images'}{'items'}[$j]{'url'}){
					$doneimages{$details->{'images'}{'items'}[$j]{'url'}} = {'bytes'=>$details->{'images'}{'items'}[$j]{'totalBytes'},'saving'=>$details->{'images'}{'items'}[$j]{'wastedBytes'}};
					$imsaving += $details->{'images'}{'items'}[$j]{'wastedBytes'};
					$nimages++;
				}
			}
			for($j = 0; $j < @{$details->{'weight'}{'details'}{'items'}}; $j++){
				$u = $details->{'weight'}{'details'}{'items'}[$j]{'url'};
				$biggestfiles{$u} = {'bytes'=>$details->{'weight'}{'details'}{'items'}[$j]{'totalBytes'},'id'=>$id};
				if($u =~ /\.(png|jpg|jpeg|webp)($|[\?\.\:])/i || $u =~ /format=(png|jpg|jpeg|webp)\&/i){
					if($details->{'weight'}{'details'}{'items'}[$j]{'totalBytes'} >= $large){
						if(!$doneimages{$u}){
							$doneimages{$u} = {};
							$nimages++;
						}
						$doneimages{$u}{'bytes'} = $details->{'weight'}{'details'}{'items'}[$j]{'totalBytes'};
					}
				}
			}
			if($nimages > 0){
				$body .= "$indent\t\t<div class=\"tip\">\n";
				$body .= "$indent\t\t\t<h4>Tip: Optimise images</h4>\n";
				if($imsaving > 0){
					$body .= "$indent\t\t\t<p>We estimate potential to save at least ".niceSize($imsaving)."* by optimising images:</p>\n";
				}
				$body .= "$indent\t\t\t<ol>\n";
				for $j (reverse(sort{ $doneimages{$a}{'bytes'} <=> $doneimages{$b}{'bytes'} || $b cmp $a }keys((%doneimages)))){
					# Estimate savings for large images that Google hasn't estimated
					if(!$doneimages{$j}{'saving'}){
						if($doneimages{$j}{'bytes'} >= 1e6){
							# Say images over 1MB can be reduced to 400kB
							$doneimages{$j}{'savedBytes'} = $doneimages{$j}{'bytes'}-400000;
						}
						if($doneimages{$j}{'bytes'} < 1e6 && $doneimages{$j}{'bytes'} > 5e5){
							# Between 500kB and 1MB we'll estimate they can be reduced to 300kB
							$doneimages{$j}{'savedBytes'} = $doneimages{$j}{'bytes'}-300000;
						}
					}else{
						$doneimages{$j}{'savedBytes'} = $doneimages{$j}{'saving'};
					}
					
					
					$fullsavings += $doneimages{$j}{'savedBytes'};
					if($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[0]}{'bytes'} > 0){
						$co2savings += ($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[0]}{'CO2'} * $doneimages{$j}{'savedBytes'}/$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[0]}{'bytes'});
					}
					$file = "File";
					if($j =~ /([^\/]*)$/){
						$file = $1;
					}
					if($file){
						$body .= "$indent\t\t\t\t<li><a href=\"$j\">".(length($file) > 22 ? substr($file,0,20)."...":$file)."</a> is ".niceSize($doneimages{$j}{'bytes'}).($doneimages{$j}{'saving'} > 0 ? " and could be ".niceSize($doneimages{$j}{'saving'})." smaller":"")."</li>\n";
					}
				}
				$body .= "$indent\t\t\t</ol>\n";
				$body .= "$indent\t\t\t<p>First, check that images are appropriately sized - you most likely don't need a 6000x4000 pixel image straight from a digital camera. In Windows, the Photos software will let you quickly shrink huge images and will give you an improvement.</p>\n";
				$body .= "$indent\t\t\t<p>Next you could try using <a href=\"https://tinyjpg.com/\">tinyjpg.com</a> (JPG image) or <a href=\"https://tinypng.com/\">tinypng.com</a> (PNG image) to further optimise your image. This will strip out metadata that may be taking up lots of space.</p>\n";
				$body .= "$indent\t\t\t<p class=\"small\">*This is an estimate from Google PageSpeed and you may get much better results than this in practice.</p>";
				$body .= "$indent\t\t</div>\n";
			}
		}
		if($details->{'weight'}){
			$weight = 0;
			$list = "";
			$fontweight = 0;
			$fonts = 0;
			$ttf = 0;
			$jquery = 0;
			$civiccomputing = 0;
			$privacypolicy = 0;
			for $src (keys(%cookie)){
				$cookie{$src}{'n'} = 0;
			}
			for($j = 0; $j < @{$details->{'weight'}{'details'}{'items'}}; $j++){
				$file = "File";
				for $src (keys(%cookie)){
					if($details->{'weight'}{'details'}{'items'}[$j]{'url'} =~ $src){
						$cookie{$src}{'n'}++;
					}
				}
				#if($details->{'weight'}{'details'}{'items'}[$j]{'url'} =~ /cookie/ || $details->{'weight'}{'details'}{'items'}[$j]{'url'} =~ /consent/){
				#	print "$details->{'weight'}{'details'}{'items'}[$j]{'url'}\n";
				#}
				if($details->{'weight'}{'details'}{'items'}[$j]{'url'} =~ /([^\/]*)$/){
					$file = $1;
					if($file =~ /jquery/){ $jquery++; }
				}
				if(!$file){ $file = "Page"; }
				$u = $details->{'weight'}{'details'}{'items'}[$j]{'url'};
				if(!$doneimages{$u} && $details->{'weight'}{'details'}{'items'}[$j]{'totalBytes'} > $large){
					if(!$duplicates{$u}){
						$duplicates{$u} = {'bytes'=>$details->{'weight'}{'details'}{'items'}[$j]{'totalBytes'},'n'=>0};
					}
					$duplicates{$u}{'n'}++;
					$duplicates{$u}{'file'} = $file;
					if($file =~ /\.(ttf|woff|woff2|otf)$/ || $file =~ /\.(ttf|woff|woff2|otf)\?/){
						$fontweight += $details->{'weight'}{'details'}{'items'}[$j]{'totalBytes'};
						$fonts++;
					}
					if($file =~ /\.(ttf|otf)$/){
						$ttf++;
					}
				}
			}
			if($jquery > 0){ $jqueryorg++; }
			for $src (keys(%cookie)){
				if($cookie{$src}{'n'} > 0){ $cookie{$src}{'total'}++; }
			}
			$dup = 0;
			for $u (reverse(sort{ $duplicates{$a}{'bytes'} <=> $duplicates{$b}{'bytes'} }keys((%duplicates)))){
				if($u){
					$list .= "$indent\t\t\t\t<li><a href=\"$u\">".(length($duplicates{$u}{'file'}) > 32 ? substr($duplicates{$u}{'file'},0,30)."...":$duplicates{$u}{'file'})."</a> is ".niceSize($duplicates{$u}{'bytes'}).($duplicates{$u}{'n'} > 1 ? " &times;$duplicates{$u}{'n'}" : "")."</li>\n";
					$dup += ($duplicates{$u}{'n'}-1);
					$weight += $duplicates{$u}{'bytes'};
				}
			}
			if($weight > 100000){
				$body .= "$indent\t\t<div class=\"tip\">\n";
				$body .= "$indent\t\t\t<h4>Tip: Large files</h4>\n";
				$body .= "$indent\t\t\t<p>Aside from images, here are the biggest resources:</p>\n";
				$body .= "$indent\t\t\t<ol>\n";
				$body .= $list;
				$body .= "$indent\t\t\t</ol>\n";
				if($dup > 0){
					$body .= "$indent\t\t\t<p>There ".($dup==1 ? "is":"are")." $dup duplicate resource".($dup==1 ? "":"s")." included on the page.</p>\n";
				}
				if($fontweight > 100000){
					$body .= "$indent\t\t\t<p>The page uses $fonts font".($fonts==1 ? "":"s")." which require".($fonts==1 ? "s":"")." ".niceSize($fontweight).". Could system fonts be used instead?".($ttf > 0 ? " There are $ttf TTF/OTF fonts on the page - WOFF2 versions of these fonts may be smaller.":"")."</p>\n";
				}
				$body .= "$indent\t\t</div>\n";
			}
		}
		
		if($details->{'third-party'}){
			$thirdparties = 0;
			$list = "";
			$note = "";
			for($j = 0; $j < @{$details->{'third-party'}{'details'}{'items'}}; $j++){
				$weight = $details->{'third-party'}{'details'}{'items'}[$j]{'transferSize'};
				if($weight > $large){
					$thirdname = "";
					if(ref($details->{'third-party'}{'details'}{'items'}[$j]{'entity'}) eq "HASH"){
						$thirdname = $details->{'third-party'}{'details'}{'items'}[$j]{'entity'}{'text'};
					}else{
						$thirdname = $details->{'third-party'}{'details'}{'items'}[$j]{'entity'};
					}
					if($thirdname){
						$list .= "$indent\t\t\t\t<li>".$details->{'third-party'}{'details'}{'items'}[$j]{'entity'}." uses ".niceSize($details->{'third-party'}{'details'}{'items'}[$j]{'transferSize'})."</li>";
						$thirdparties++;
						if($details->{'third-party'}{'details'}{'items'}[$j]{'entity'} =~ /Twitter/i){
							$note .= " If you use the Twitter widget to load a timeline it may be loading as many as 100 of your recent tweets which may contain lots of images. Try setting '<a href=\"https://developer.twitter.com/en/docs/twitter-for-websites/timelines/overview\">data-tweet-limit</a>' to the most recent 3.";
						}
					}else{
						error("Unexpected value for third party entity.\n");
						print Dumper $details->{'third-party'}{'details'}{'items'}[$j]{'entity'};
						exit;
					}
				}
			}
			if($list){
				$body .= "$indent\t\t<div class=\"tip\">\n";
				$body .= "$indent\t\t\t<h4>Tip: Limit third-party code</h4>\n";
				$body .= "$indent\t\t\t<p>Here are the largest sources of third-party code:</p>\n";
				$body .= "$indent\t\t\t<ol>\n";
				$body .= $list;
				$body .= "$indent\t\t\t</ol>\n";
				$body .= "$indent\t\t\t<p>Third-party code can significantly impact load performance. Limit the number of redundant third-party providers and try to load third-party code after your page has primarily finished loading.</p>\n";
				if($note){ $body .= "$indent\t\t\t<p>$note</p>\n"; }
				$body .= "$indent\t\t</div>\n";
			}
		}

		$body .= "$indent\t</div>\n";
		$body .= "$indent\t<div>\n";
		if($details->{'screenshot'}){
			$body .= "$indent\t\t<a href=\"$url\"><img src=\"$id.webp\" alt=\"Screenshot\" class=\"screenshot\" /></a>\n";
		}
		$body .= "$indent\t</div>\n";
		$body .= "$indent\t</li>\n";
	}
	$body .= "$indent</ul>\n";

	$txt =~ s/\{\{ ID \}\}/$id/g;
	$txt =~ s/\{\{ CO2 \}\}/$org{$id}{'CO2'}/g;
	$txt =~ s/\{\{ DATE \}\}/$org{$id}{'date'}/g;
	$txt =~ s/\{\{ TITLE \}\}/$data->{'orgs'}{$id}{'name'} website emissions/g;
	$txt =~ s/\{\{ NAME \}\}/$data->{'orgs'}{$id}{'name'}/g;
	$txt =~ s/\{\{ BODY \}\}/$body/g;

	open(FILE,">",$odir.$id.".html");
	print FILE $txt;
	close(FILE);
}

msg("Biggest files:\n");
@big = reverse(sort{ $biggestfiles{$a}{'bytes'} <=> $biggestfiles{$b}{'bytes'} }(keys(%biggestfiles)));
for($i = 0; $i < @big; $i++){
	if($biggestfiles{$big[$i]}{'bytes'} > 5e6){
		msg("  <green>".($i+1)."<none>. <yellow>".niceSize($biggestfiles{$big[$i]}{'bytes'})."<none> - <yellow>$biggestfiles{$big[$i]}{'id'}<none> - <cyan>$big[$i]<none>\n");
	}
}
msg("Yearly image savings of <yellow>".niceSize($fullsavings*$monthlyvisits*12)."<none> (<green>".sprintf("%0.1f",($co2savings*$monthlyvisits*12)/1e3)."kg<none> CO2) if $monthlyvisits visitors per month\n");
msg("jQuery usage: <yellow>$jqueryorg/$tot<none> orgs.\n");
msg("Cookie settings:\n");
for $src (reverse(sort{$cookie{$a}{'total'} <=> $cookie{$b}{'total'}}(keys(%cookie)))){
	msg("\t<cyan>$src<none>: $cookie{$src}{'total'}\n");
}

sub niceSize {
	my $b = $_[0];
	if(!$b){ return ""; }
	if($b > 1e12){ return sprintf("%0.1fTB",$b/1e12); }
	if($b > 1e9){ return sprintf("%0.1fGB",$b/1e9); }
	if($b > 1e8){ return sprintf("%0.0fMB",$b/1e6); }
	if($b > 1e6){ return sprintf("%0.1fMB",$b/1e6); }
	if($b > 1e5){ return sprintf("%0dkB",$b/1e3); }
	if($b > 1e4){ return sprintf("%0.0fkB",$b/1e3); }
	if($b > 1e3){ return sprintf("%0.1fkB",$b/1e3); }
	return $b." bytes";
}


# https://www.websitecarbon.com/introducing-the-website-carbon-rating-system/
# Rating	Grams CO2e per pageview
# A + 	0.040
# A	0.079
# B	0.145
# C	0.209
# D	0.278
# E	0.359
# F 	≥ 0.360
sub getRating {
	my $co = $_[0];
	my ($rating,$rcls);
	if($co <= 0.04){
		$rating = "A+";
		$rcls = "rate-aplus";
	}elsif($co > 0.04 && $co <= 0.079){
		$rating = "A";
		$rcls = "rate-a";
	}elsif($co > 0.079 && $co <= 0.145){
		$rating = "B";
		$rcls = "rate-b";
	}elsif($co > 0.145 && $co <= 0.209){
		$rating = "C";
		$rcls = "rate-c";
	}elsif($co > 0.209 && $co <= 0.278){
		$rating = "D";
		$rcls = "rate-d";
	}elsif($co > 0.278 && $co < 0.36){
		$rating = "E";
		$rcls = "rate-e";
	}elsif($co >= 0.360){
		$rating = "F";
		$rcls = "rate-f";
	}
	return ($rating,$rcls);
}

sub getRatingV3 {
	my $co = $_[0];
	my ($rating,$rcls);
	if($co <= 0.095){
		$rating = "A+";
		$rcls = "rate-aplus";
	}elsif($co > 0.095 && $co <= 0.186){
		$rating = "A";
		$rcls = "rate-a";
	}elsif($co > 0.186 && $co <= 0.341){
		$rating = "B";
		$rcls = "rate-b";
	}elsif($co > 0.341 && $co <= 0.493){
		$rating = "C";
		$rcls = "rate-c";
	}elsif($co > 0.493 && $co <= 0.656){
		$rating = "D";
		$rcls = "rate-d";
	}elsif($co > 0.656 && $co <= 0.846){
		$rating = "E";
		$rcls = "rate-e";
	}elsif($co > 0.846){
		$rating = "F";
		$rcls = "rate-f";
	}
	return ($rating,$rcls);
}

sub getDetails {
	my $url = $_[0];
	my $safeurl = $carbon->getSafeURL($url);
	my ($file,@lines,$str,$json,$screenshot,$rtn,$green);
	my $file = "data/raw/$safeurl.json";
	if(-e $file){
		open(FILE,$file);
		@lines = <FILE>;
		close(FILE);
		$str = join("",@lines);
		if(!$str){ $str = "{}"; }
		$json = JSON::XS->new->decode($str);
		$rtn->{'file'} = 1;
		if($json->{'lighthouseResult'}{'audits'}{'first-contentful-paint'}){
			$rtn->{'first-contentful-paint'} = $json->{'lighthouseResult'}{'audits'}{'first-contentful-paint'};
		}
		if($json->{'lighthouseResult'}{'audits'}{'final-screenshot'}{'details'}{'data'}){
			$rtn->{'screenshot'} = $json->{'lighthouseResult'}{'audits'}{'final-screenshot'}{'details'}{'data'};
		}
		if($json->{'lighthouseResult'}{'audits'}{'uses-optimized-images'}{'details'}){
			$rtn->{'images'} = $json->{'lighthouseResult'}{'audits'}{'uses-optimized-images'}{'details'};
		}
		if($json->{'lighthouseResult'}{'audits'}{'total-byte-weight'}{'details'}){
			$rtn->{'weight'} = $json->{'lighthouseResult'}{'audits'}{'total-byte-weight'};
		}
		if($json->{'lighthouseResult'}{'audits'}{'third-party-summary'}{'details'}){
			$rtn->{'third-party'} = $json->{'lighthouseResult'}{'audits'}{'third-party-summary'};
		}
	}
	return $rtn;	
}
sub median {
	my @data = @_;
	@data = sort(@data);
	my $count = @data;
	my $med = 0;
	my $pos = int($count / 2);
	if( $count % 2 == 1){
		return $data[$pos];
	}else{
		my $med2 = $med - 1;
		return ($data[$pos] + $data[$pos-1]) / 2;
	}
	return "";
}
sub ISO2String {
	my $fmt = $_[0];
	my $str = $_[1];
	my $o = $str;
	if($str =~ /(^|\D)([0-9]{4})-([0-9]{2})-([0-9]{2})(\D|$)/){
		$o = strftime($fmt,(0,0,12,$4,$3-1,$2-1900));
	}
	return $o;
}