#!/usr/bin/perl

use utf8;
use JSON::XS;
use Data::Dumper;

my $dir = "areas/";
my ($dh,$filename,$palettes,$code,$las,@colours,$geojson,@features,$f,$name,$json,$c,$fh,@urls,@files,$jfile);

$las = LoadJSON("data/index.json")->{'orgs'};

@features = @{LoadJSON("data/Local_Authority_Districts_(May_2025)_Boundaries_UK_BUC.geojson")->{'features'}};
for($f = 0; $f < @features; $f++){
	$geojson->{$features[$f]->{'properties'}{'LAD25CD'}} = {'name'=>$features[$f]->{'properties'}{'LAD25NM'},'lat'=>$features[$f]->{'properties'}{'LAT'},'lon'=>$features[$f]->{'properties'}{'LONG'}};
}

# Read the directory for JSON files
foreach $code (sort(keys(%{$las}))){
	if($las->{$code}{'active'} && !$las->{$code}{'blocked'}){
		print $code."\n";
		$jfile = $dir."palettes/$code.json";
		if(!-e $jfile){
			`pylette $dir$filename --n 8 --export-json --output $jfile`;
		}
		@{$palettes->{$code}} = @{LoadJSON($jfile)->{'palettes'}[0]{'colors'}};
	}
}



# Process each 
$str = "<style>table {width:100%;border:0;border-collapse:collapse;} td, th {padding:0;margin:0;} .palette {min-width:300px;display:flex;align-items:center;} .block {height:16px; display:inline-block;}</style>\n";
$str .= "<table>\n";
foreach $code (sort{ $geojson->{$b}{'lat'} <=> $geojson->{$a}{'lat'} }(keys(%{$palettes}))){
	$name = $las->{$code}{'name'};
	if($geojson->{$code}{'lat'}){
		$str .= "\t<tr>\n";
		@urls = keys(%{$las->{$code}{'urls'}});
		$str .= "\t\t<td title=\"$name ($code)\"><a href=\"../$dir/$code.webp\" class=\"palette\">";
		@colours = @{$palettes->{$code}};
		for($c = 0; $c < @colours; $c++){
			$str .= "<div class=\"block\" style=\"background:$colours[$c]->{'hex'};width:".sprintf("%0.2f",(100*$colours[$c]->{'frequency'}))."%\"></div>";
		}
		$str .= "</a></td>\n";
		$str .= "\t</tr>\n";
	}else{
		warning("Not found <green>$name<none> ($code) in GeoJSON\n");
	}
}
$str .= "</table>\n";
open($fh,">","data/palettes.html");
print $fh $str;
close($fh);







#####################################

sub msg {
	my $str = $_[0];
	my $dest = $_[1]||"STDOUT";
	
	my %colours = (
		'black'=>"\033[0;30m",
		'red'=>"\033[0;31m",
		'green'=>"\033[0;32m",
		'yellow'=>"\033[0;33m",
		'blue'=>"\033[0;34m",
		'magenta'=>"\033[0;35m",
		'cyan'=>"\033[0;36m",
		'white'=>"\033[0;37m",
		'none'=>"\033[0m"
	);
	foreach my $c (keys(%colours)){ $str =~ s/\< ?$c ?\>/$colours{$c}/g; }
	if($dest eq "STDERR"){
		print STDERR $str;
	}else{
		print STDOUT $str;
	}
}

sub error {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<red>ERROR:<none> /;
	msg($str,"STDERR");
}

sub warning {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<yellow>WARNING:<none> /;
	msg($str,"STDERR");
}
sub ParseJSON {
	my $str = shift;
	my $json = {};
	if(!$str){ $str = "{}"; }
	eval {
		$json = JSON::XS->new->decode($str);
	};
	if($@){ error("\tInvalid output.\n"); }
	return $json;
}

sub LoadJSON {
	my (@files,$str,@lines,$json);
	my $file = $_[0];
	open(FILE,"<:utf8",$file);
	@lines = <FILE>;
	close(FILE);
	$str = (join("",@lines));
	# Error check for JS variable e.g. South Tyneside https://maps.southtyneside.gov.uk/warm_spaces/assets/data/wsst_council_spaces.geojson.js
	$str =~ s/[^\{]*var [^\{]+ = //g;
	return ParseJSON($str);
}

# Version 1.1.1
sub SaveJSON {
	my $json = shift;
	my $file = shift;
	my $depth = shift;
	my $oneline = shift;
	if(!defined($depth)){ $depth = 0; }
	my $d = $depth+1;
	my ($txt,$fh);
	

	$txt = JSON::XS->new->canonical(1)->pretty->space_before(0)->encode($json);
	$txt =~ s/   /\t/g;
	$txt =~ s/\n\t{$d,}//g;
	$txt =~ s/\n\t{$depth}([\}\]])(\,|\n)/$1$2/g;
	$txt =~ s/": /":/g;

	if($oneline){
		$txt =~ s/\n[\t\s]*//g;
	}

	msg("Save JSON to <cyan>$file<none>\n");
	open($fh,">:utf8",$file);
	print $fh $txt;
	close($fh);

	return $txt;
}