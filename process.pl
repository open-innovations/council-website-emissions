#!/usr/bin/perl

use lib "lib/";
use JSON::XS;
use Data::Dumper;
use ODILeeds::CarbonAPI;


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

$carbon = ODILeeds::CarbonAPI->new();

open(FILE,$file);
@lines = <FILE>;
close(FILE);

$data = JSON::XS->new->utf8->decode(join("",@lines));

%org;
$avco2 = 1.76;
$monthlyvisits = 10000;

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

	if($data->{'orgs'}{$id}{'active'}){
		$tsv .= "$id\t$data->{'orgs'}{$id}{'name'}\t$url";
		$nm = $data->{'orgs'}{$id}{'name'};
		$co2 = $data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$recent}{'CO2'}||"";
		$lnk = $data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$recent}{'ref'};
		if($co2){
			$tsv .= "\t\t".sprintf("%0.2f",$co2)."\t$lnk";
		}else{
			$tsv .= "\tFAIL\t\t"
		}
		$tsv .= "\t$recent\n";
		$org{$id} = {'name'=>$nm,'url'=>$url,'CO2'=>$co2,'link'=>$lnk,'date'=>$recent};
	}
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




@order = reverse(sort{$org{$a}{'CO2'} <=> $org{$b}{'CO2'} || $org{$a}{'name'} cmp $org{$b}{'name'}}(keys(%org)));

$idt = "				";
$table = "\n$idt<table class=\"table-sort\">\n$idt\t<tr><th>Rank</th><th>$type</th><th>$config{'Code'}</th><th>CO2 / grams</th><th>Last checked</th></tr>\n";
$tablebest = "\n$idt<table class=\"top top-best\">\n$idt\t<tr><th>$type</th><th>CO2 / grams</th></tr>\n";
$tableworst = "\n$idt<table class=\"top top-worst\">\n$idt\t<tr><th>$type</th><th>CO2 / grams</th></tr>\n";
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
	if(!$org{$id}{'CO2'}){
		$missing++;
	}
	$tr = "$idt\t<tr><td class=\"cen\">$rank</td><td><a href=\"$odir$id.html\">".$org{$id}{'name'}.($org{$id}{'url'} ? "</a>":"")."</td><td class=\"cen\">$id</td><td class=\"cen\">".($org{$id}{'link'} ? "<a href=\"$org{$id}{'link'}\">":"").($org{$id}{'CO2'} ? sprintf("%0.2f",$org{$id}{'CO2'}) : "?").($org{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">$org{$id}{'date'}</td></tr>\n";
	$tr2 = "$idt\t<tr><td><a href=\"$odir$id.html\">".$org{$id}{'name'}.($org{$id}{'url'} ? "</a>":"")."</td><td class=\"cen\">".($org{$id}{'CO2'} ? sprintf("%0.2f",$org{$id}{'CO2'}) : "?")."</td></tr>\n";
	$table .= $tr;
	if($org{$id}{'CO2'} > 0){
		$n = @worst;
		if($n < 10){
			push(@worst,$tr2);
		}
		push(@best,$tr2);
		$n = @best;
		if($n > 10){
			shift(@best);
		}
	}
	$lastco2 = $org{$id}{'CO2'};
}
@best = reverse(@best);
for($i = 0; $i < @best; $i++){
	$tablebest .= $best[$i];
}
for($i = 0; $i < @worst; $i++){
	$tableworst .= $worst[$i];
}
$table .= "$idt</table>\n";
$tablebest .= "$idt</table>\n";
$tableworst .= "$idt</table>\n";

$av /= $nn;

$better = ($av < $avco2);
$howwell = "much better";
if($av > 0.5*$avco2){ $howwell = "well"; }
if($av > 0.75*$avco2){ $howwell = "better"; }
if($av > 1*$avco2){ $howwell = "OK"; }
if($av > 1.25*$avco2){ $howwell = "badly"; }
$results = "The average emissions from a $type homepage are <strong class=\"bold\">".sprintf("%.2f",$av)."g</strong> (median of <strong class=\"bold\">".sprintf("%.2f",$median)."g</strong>) which is ".($better ? "better than":"worse than")." an average website (".$avco2."g). So, overall, ".$typeplural." are doing <strong class=\"bold\">$howwell</strong>.";
if($missing > 0){
	$results .= " We were unable to calculate emissions for <strong class=\"bold\">$missing out of $tot</strong> ".$typeplural." possibly due to their sites blocking automated requests.";
}
$results .= " The top and bottom 10 websites are given here with the <a href=\"#full-list\">full list below</a>.";

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

# Make a page for each org
for $id (sort{$data->{'orgs'}{$a}{'name'} cmp $data->{'orgs'}{$b}{'name'}}(keys(%{$data->{'orgs'}}))){
	$txt = $html;
	$body = "<h1>$data->{'orgs'}{$id}{'name'} - <code>$id</code>".($data->{'orgs'}{$id}{'active'} ? "<span class=\"c5-bg code\">ACTIVE</span>":"<span class=\"c12-bg code\">INACTIVE</span>")."</h1>\n";
	if($data->{'orgs'}{$id}{'replacedBy'}){
		$rid = $data->{'orgs'}{$id}{'replacedBy'}{'id'};
		$body .= "$indent<p>Replaced by <a href=\"$rid\.html\">$data->{'orgs'}{$rid}{'name'}</a> on $data->{'orgs'}{$id}{'replacedBy'}{'date'}.</p>";
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
		$body .= "$indent\t\t<table>\n$indent\t\t\t<tr><th>Date checked</th><th class=\"cen\">CO2 / grams</th><th class=\"cen\">Page size</th><th class=\"cen\"><a href=\"https://www.thegreenwebfoundation.org/directory/\">Energy</a></th></tr>\n";
		@dates = reverse(sort(keys(%{$data->{'orgs'}{$id}{'urls'}{$url}{'values'}})));
		for($d = 0; $d < @dates; $d++){
			$body .= "$indent\t\t\t<tr><td>$dates[$d]</td><td class=\"cen\"><a href=\"$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'ref'}\">".sprintf("%0.2f",$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'CO2'})."</a></td><td class=\"cen\" data=\"$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'bytes'}\">".niceSize($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'bytes'})."</td><td class=\"cen ".($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'green'} ? "c5-bg":"")."\">".($data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'green'} ? "GREEN":"GRID?")."</td></tr>\n";
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
				if($u =~ /\.(png|jpg|jpeg|webp)$/ || $u =~ /\.(png|jpg|jpeg|webp)\?/ || $u =~ /format=(png|jpg|jpeg|webp)\&/){
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
				for $j (reverse(sort{ $doneimages{$a}{'bytes'} <=> $doneimages{$b}{'bytes'} || $a cmp $b }keys((%doneimages)))){
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
			for($j = 0; $j < @{$details->{'weight'}{'details'}{'items'}}; $j++){
				$file = "File";
				if($details->{'weight'}{'details'}{'items'}[$j]{'url'} =~ /([^\/]*)$/){
					$file = $1;
					if($file =~ /jquery/){ $jquery++; }
				}
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

		$body .= "$indent\t</div>\n";
		$body .= "$indent\t<div>\n";
		if($details->{'screenshot'}){
			$body .= "$indent<a href=\"$url\"><img src=\"$details->{'screenshot'}\" alt=\"Screenshot\" class=\"screenshot\" /></a>";
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

	open(FILE,">","$odir$id.html");
	print FILE $txt;
	close(FILE);
}

print "Biggest files:\n";
@big = reverse(sort{ $biggestfiles{$a}{'bytes'} <=> $biggestfiles{$b}{'bytes'} }(keys(%biggestfiles)));
for($i = 0; $i < @big; $i++){
	if($biggestfiles{$big[$i]}{'bytes'} > 5e6){
		print "  ".($i+1).". ".niceSize($biggestfiles{$big[$i]}{'bytes'})." - $biggestfiles{$big[$i]}{'id'} - $big[$i]\n";
	}
}
print "Yearly image savings of ".niceSize($fullsavings*$monthlyvisits*12)." (".sprintf("%0.1f",($co2savings*$monthlyvisits*12)/1e3)."kg CO2) if $monthlyvisits visitors per month\n";
print "jQuery usage: $jqueryorg/$tot orgs.\n";

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
		$json = JSON::XS->new->utf8->decode($str);
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
	}
	return $rtn;	
}
