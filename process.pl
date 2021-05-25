#!/usr/bin/perl

use JSON::XS;
use Data::Dumper;

$file = "data/councils.json";
$cfile = "data/website-carbon.csv";
$tfile = "data/website-carbon.tsv";

open(FILE,$file);
@lines = <FILE>;
close(FILE);

$data = JSON::XS->new->utf8->decode(join("",@lines));

%council;
$avco2 = 1.76;

# Make the CSV
$tsv = "ONS code\tLocal authority name\tWebsite\tStatus\tCO2 emissions (g)\tWebsite carbon link\tDate last checked\n";
for $id (sort{$data->{'councils'}{$a}{'name'} cmp $data->{'councils'}{$b}{'name'}}(keys(%{$data->{'councils'}}))){
	$url = "";
	@urls = keys(%{$data->{'councils'}{$id}{'urls'}});
	# Find the default URL (if there is only one URL this is it)
	if(@urls == 1){
		$url = $urls[0];
	}elsif(@urls > 1){
		for($i = 0; $i < @urls; $i++){
			if($data->{'councils'}{$id}{'urls'}{$urls[$i]}{'default'}){
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
	@dates = reverse(sort(keys(%{$data->{'councils'}{$id}{'urls'}{$url}{'values'}})));
	if(@dates == 1){
		$recent = $dates[0];
		$lastco = $data->{'councils'}{$id}{'urls'}{$url}{'values'}{$recent}{'CO2'};
	}else{
		for($i = 0; $i < @dates; $i++){
			if(!$recent || $lastco eq ""){
				$recent = $dates[$i];
				$lastco = $data->{'councils'}{$id}{'urls'}{$url}{'values'}{$dates[$i]}{'CO2'};
			}
		}
	}

	if($data->{'councils'}{$id}{'active'}){
		$tsv .= "$id\t$data->{'councils'}{$id}{'name'}\t$url";
		$nm = $data->{'councils'}{$id}{'name'};
		$co2 = $data->{'councils'}{$id}{'urls'}{$url}{'values'}{$recent}{'CO2'}||"";
		$lnk = $data->{'councils'}{$id}{'urls'}{$url}{'values'}{$recent}{'ref'};
		if($co2){
			$tsv .= "\t\t".sprintf("%0.2f",$co2)."\t$lnk";
		}else{
			$tsv .= "\tFAIL\t\t"
		}
		$tsv .= "\t$recent\n";
		$council{$id} = {'name'=>$nm,'url'=>$url,'CO2'=>$co2,'link'=>$lnk,'date'=>$recent};
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




@order = reverse(sort{$council{$a}{'CO2'} <=> $council{$b}{'CO2'} || $council{$a}{'name'} cmp $council{$b}{'name'}}(keys(%council)));

$idt = "				";
$table = "\n$idt<table class=\"table-sort\">\n$idt\t<tr><th>Rank</th><th>Council</th><th>ONS Code</th><th>CO2 / grams</th><th>Last checked</th></tr>\n";
$tablebest = "\n$idt<table class=\"top top-best\">\n$idt\t<tr><th>Council</th><th>CO2 / grams</th></tr>\n";
$tableworst = "\n$idt<table class=\"top top-worst\">\n$idt\t<tr><th>Council</th><th>CO2 / grams</th></tr>\n";
$rank = 1;
$av = 0;
$tot = @order;
$lastco2 = 1e100;
$half = int($tot/2);
$median = 0;
$missing = 0;
@best = ();
@worst = ();
for($i = 0; $i < @order; $i++){
	$id = $order[$i];
	if($council{$id}{'CO2'} < $lastco2){
		$rank = $i+1;
	}
	$av += $council{$id}{'CO2'};
	if($i==$half){
		$median = $council{$id}{'CO2'};
	}
	if(!$council{$id}{'CO2'}){
		$missing++;
	}
	$tr = "$idt\t<tr><td class=\"cen\">$rank</td><td>".($council{$id}{'url'} ? "<a href=\"areas/$id.html\">":"").$council{$id}{'name'}.($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\"><a href=\"areas/$id.html\">$id</a></td><td class=\"cen\">".($council{$id}{'link'} ? "<a href=\"$council{$id}{'link'}\">":"").($council{$id}{'CO2'} ? sprintf("%0.2f",$council{$id}{'CO2'}) : "?").($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">$council{$id}{'date'}</td></tr>\n";
	$tr2 = "$idt\t<tr><td>".($council{$id}{'url'} ? "<a href=\"$council{$id}{'url'}\">":"").$council{$id}{'name'}.($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">".($council{$id}{'CO2'} ? sprintf("%0.2f",$council{$id}{'CO2'}) : "?")."</td></tr>\n";
	$table .= $tr;
	if($council{$id}{'CO2'} > 0){
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
	$lastco2 = $council{$id}{'CO2'};
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

$av /= $tot;

$better = ($av < $avco2);
$howwell = "much better";
if($av > 0.5*$avco2){ $howwell = "well"; }
if($av > 0.75*$avco2){ $howwell = "better"; }
if($av > 1*$avco2){ $howwell = "OK"; }
if($av > 1.25*$avco2){ $howwell = "badly"; }
$results = "The average emissions from a UK council homepage are <strong class=\"bold\">".sprintf("%.2f",$av)."g</strong> (median of <strong class=\"bold\">".sprintf("%.2f",$median)."g</strong>) which is ".($better ? "better than":"worse than")." an average website (".$avco2."g). So, overall, councils are doing <strong class=\"bold\">$howwell</strong>.";
if($missing > 0){
	$results .= " We were unable to calculate emissions for <strong class=\"bold\">$missing out of $tot</strong> councils possibly due to their sites blocking automated requests.";
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
open(FILE,"areas/template.html");
@lines = <FILE>;
close(FILE);
$html = join("",@lines);

$indent = "\t\t\t\t";

# Make a page for each council
for $id (sort{$data->{'councils'}{$a}{'name'} cmp $data->{'councils'}{$b}{'name'}}(keys(%{$data->{'councils'}}))){
	$txt = $html;
	$body = "<h1>$data->{'councils'}{$id}{'name'} - <code>$id</code>".($data->{'councils'}{$id}{'active'} ? "<span class=\"c5-bg code\">ACTIVE</span>":"<span class=\"c12-bg code\">INACTIVE</span>")."</h1>\n";
	if($data->{'councils'}{$id}{'replacedBy'}){
		$rid = $data->{'councils'}{$id}{'replacedBy'}{'id'};
		$body .= "$indent<p>Replaced by <a href=\"$rid\.html\">$data->{'councils'}{$rid}{'name'}</a> on $data->{'councils'}{$id}{'replacedBy'}{'date'}.</p>";
	}
	$body .= "$indent<h2>Emissions</h2>\n";
	$body .= "$indent<ul class=\"emissions\">\n";
	@urls = keys(%{$data->{'councils'}{$id}{'urls'}});
	for($i = 0; $i < @urls; $i++){
		$url = $urls[$i];
		$body .= "$indent\t<li>\n";
		$body .= "$indent\t\t<p><strong>URL:</strong> <a href=\"$url\">$url</a></p>\n$indent\t\t<table>\n$indent\t\t\t<tr><th>Date checked</th><th>CO2 / grams</th></tr>\n";
		@dates = reverse(sort(keys(%{$data->{'councils'}{$id}{'urls'}{$url}{'values'}})));
		for($d = 0; $d < @dates; $d++){
			$body .= "$indent\t\t\t<tr><td>$dates[$d]</td><td><a href=\"$data->{'councils'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'ref'}\">".sprintf("%0.2f",$data->{'councils'}{$id}{'urls'}{$url}{'values'}{$dates[$d]}{'CO2'})."</a></td></tr>\n";
		}
		$body .= "$indent\t\t</table>\n";
		$body .= "$indent\t</li>\n";
	}
	$body .= "$indent</ul>\n";

	$body .= "$indent<h2>External links</h2>\n$indent<ul class=\"external\">\n";
	$body .= "$indent\t<li><a href=\"https://findthatpostcode.uk/areas/$id.html\">Find that Postcode</a></li>\n";
	$body .= "$indent\t<li><a href=\"http://statistics.data.gov.uk/doc/statistical-geography/$id\">ONS Linked Data</a></li>\n";
	$body .= "$indent\t<li><a href=\"https://findthatpostcode.uk/areas/$id.geojson\">Boundary (GeoJSON)</a></li>\n";
	$body .= "$indent</ul>\n";

	$txt =~ s/\{\{ ID \}\}/$id/g;
	$txt =~ s/\{\{ TITLE \}\}/$data->{'councils'}{$id}{'name'} website emissions/g;
	$txt =~ s/\{\{ NAME \}\}/$data->{'councils'}{$id}{'name'}/g;
	$txt =~ s/\{\{ BODY \}\}/$body/g;

	open(FILE,">","areas/$id.html");
	print FILE $txt;
	close(FILE);
}
