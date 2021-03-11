#!/usr/bin/perl

open(FILE,"data/website-carbon.tsv");
@lines = <FILE>;
close(FILE);

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

$idt = "			";
$table = "\n$idt<table class=\"table-sort\">\n$idt\t<tr><th>Rank</th><th>Council</th><th>ONS Code</th><th>CO2 emissions (grams)</th><th>Last checked</th></tr>\n";
$j = 0;
$lastco2 = 1e100;
for($i = 0; $i < @order; $i++){
	$id = $order[$i];
	if($council{$id}{'CO2'} < $lastco2){
		$j = $i;
	}
	print "$i - $j - $council{$id}{'CO2'}\n";
	$table .= "$idt\t<tr><td class=\"cen\">".($j+1)."</td><td>".($council{$id}{'url'} ? "<a href=\"$council{$id}{'url'}\">":"").$council{$id}{'name'}.($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">$id</td><td class=\"cen\">".($council{$id}{'link'} ? "<a href=\"$council{$id}{'link'}\">":"").($council{$id}{'CO2'}||"?").($council{$id}{'link'} ? "</a>":"")."</td><td class=\"cen\">$council{$id}{'date'}</td></tr>\n";
	$lastco2 = $council{$id}{'CO2'};
}
$table .= "$idt</table>\n";

open(FILE,"index.html");
@lines = <FILE>;
close(FILE);
$str = join("",@lines);
$str =~ s/\n/=NEWLINE=/g;
$str =~ s/(<\!-- Start table -->).*(<\!-- End table -->)/$1$table$2/;
$str =~ s/=NEWLINE=/\n/g;

open(FILE,">","index.html");
print FILE $str;
close(FILE);
