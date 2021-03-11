#!/usr/bin/perl

open(FILE,"data/website-carbon.tsv");
@lines = <FILE>;
close(FILE);

$avco2 = 1.76;


%council;

for($i = 1; $i < @lines; $i++){
	# Remove newlines
	$lines[$i] =~ s/[\n\r]//g;

	# ONS code	Local authority name	Website	Status	CO2 emissions (g)	Website carbon link	Date last checked
	(@cols) = split(/\t/,$lines[$i]);
	$id = $cols[0];
	$nm = $cols[1];
	$url = $cols[2];
	$co2 = $cols[4];
	$lnk = $cols[5];
	$dat = $cols[6];

	if(!$council{$id}){
		$council{$id} = {'name'=>$nm,'url'=>$url,'CO2'=>$co2,'link'=>$lnk,'date'=>$dat};
	}else{
		print "We already have $nm ($id)\n";
	}	
}

@order = reverse(sort{$council{$a}{'CO2'} <=> $council{$b}{'CO2'} || $council{$a}{'name'} cmp $council{$b}{'name'}}(keys(%council)));

$idt = "				";
$table = "\n$idt<table class=\"table-sort\">\n$idt\t<tr><th>Rank</th><th>Council</th><th>ONS Code</th><th>CO2 / grams</th><th>Last checked</th></tr>\n";
$tablebest = "\n$idt<table class=\"table-sort top\">\n$idt\t<tr><th>Council</th><th>CO2 / grams</th></tr>\n";
$tableworst = "\n$idt<table class=\"table-sort top\">\n$idt\t<tr><th>Council</th><th>CO2 / grams</th></tr>\n";
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
	$tr = "$idt\t<tr><td class=\"cen\">$rank</td><td>".($council{$id}{'url'} ? "<a href=\"$council{$id}{'url'}\">":"").$council{$id}{'name'}.($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">$id</td><td class=\"cen\">".($council{$id}{'link'} ? "<a href=\"$council{$id}{'link'}\">":"").($council{$id}{'CO2'}||"?").($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">$council{$id}{'date'}</td></tr>\n";
	$tr2 = "$idt\t<tr><td>".($council{$id}{'url'} ? "<a href=\"$council{$id}{'url'}\">":"").$council{$id}{'name'}.($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">".($council{$id}{'link'} ? "<a href=\"$council{$id}{'link'}\">":"").($council{$id}{'CO2'}||"?").($council{$id}{'link'} ? "</a>":"")."</td></tr>\n";
	$table .= $tr;
	if($council{$id}{'CO2'} > 0){
		$n = @worst;
		if($n < 10){
			push(@worst,$tr2);
		}
		push(@best,$tr2);
		$n = @best;
		if($n >= 10){
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
$results = "The average emissions from a UK council homepage are <strong class=\"bold\">".sprintf("%.2f",$av)."g</strong> (median of <strong class=\"bold\">".sprintf("%.2f",$median)."g</strong>) which is ".($better ? "better than":"worse than")." an average website (".$avco2."g).";
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
