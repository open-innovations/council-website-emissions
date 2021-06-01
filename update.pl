#!/usr/bin/perl

use lib "lib/";
use ODILeeds::CarbonAPI;
use JSON::XS;
use Data::Dumper;
use POSIX qw(strftime);

$delay = 100;
if($ENV{'CC_GPSAPI_KEY'}){ $delay = 10; }


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



# Read in the existing data
$file = $config{'JSON'}||"data/index.json";
open(FILE,$file);
@lines = <FILE>;
close(FILE);
$str = join("",@lines);
$data = JSON::XS->new->utf8->decode($str);

# Create an object for calculating the carbon usage
$carbon = ODILeeds::CarbonAPI->new();

# Find the ISO8601 date format for today
$today = strftime('%Y-%m-%d',gmtime());

# Check if we've explicitly specified an org(s) by ID (semi-colon separated)
$id = $ARGV[0];

if($id && !$data->{'orgs'}{$id}){
	print "Error: $id does not appear to exist in the dataset.\n";
	exit;
}
# Process the org(s)
processOrgs($id);



#####################
# SUBROUTINES

sub processOrgs {
	my $str = $_[0];
	my (@ids,$ago,$n,$i);
	print "Processing orgs...\n";

	if($str){
		@ids = split(/;/,$str);
		$ago = 0.5;
	}else{
		@ids = (sort{$data->{'orgs'}{$a}{'name'} cmp $data->{'orgs'}{$b}{'name'}}(keys(%{$data->{'orgs'}})));
		$ago = 14;
	}

	$n = @ids;
	if($n==1){
		print "$ids[0]\n";
		$dl = processOrg($ids[0],$ago);
	}else{
		for($i = 0; $i < @ids; $i++){
			if($data->{'orgs'}{$ids[$i]}{'active'}){
				print "$ids[$i]\n";
				$dl = processOrg($ids[$i],$ago);
				if($dl){
					print "\tsleeping for $delay seconds...\n";
					sleep $delay;
				}
			}
		}
	}
	return;
}

sub processOrg {
	my $id = $_[0];
	my $ago = $_[1];
	my (@urls,$u,$url,$recent,@dates,$lastco,$i,$days,$entry,$dl);

	@urls = keys(%{$data->{'orgs'}{$id}{'urls'}});
	$dl = 0;
	for($u = 0; $u < @urls; $u++){
		$url = $urls[$u];
		$recent = "";
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
		$days = daysBetween($recent,$today);
		if($days > ($ago||14)){
			$entry = $carbon->makeEntry($url);
			if($entry->{'co2'}){
				$data->{'orgs'}{$id}{'urls'}{$url}{'values'}{$today} = {'CO2'=>($entry->{'co2'} ? sprintf("%0.2f",$entry->{'co2'})+0 : $entry->{'co2'}),'bytes'=>($entry->{'bytes'}),'imagebytes'=>($entry->{'images'}{'bytes'}),'green'=>($entry->{'green'})};
				print "$id:\n";
				print "\t$url\n";
				print "\t$recent - ".$days." days ago\n";
				print "\tco2 = ".sprintf("%0.2f",$entry->{'co2'})."\n";
				print "\tbytes = $entry->{'bytes'}\n";
				print "\tbytes (images) = $entry->{'images'}->{'bytes'}\n";
				saveIndex($data);
				print `perl process.pl`;
			}else{
				print "$id:\n";
				print "\tNo CO2 data\n";
			}
			if($entry->{'downloaded'}){
				$dl = 1;
			}
		}
	}
	return $dl;
}



##################################################
# SUBROUTINES
sub saveIndex {
	my ($data) = @_;
	my ($str,$date,$contents,$newcontent);

	$str = JSON::XS->new->utf8->pretty(1)->canonical(1)->encode($data);
	$str =~ s/   /\t/g;
	$str =~ s/ \: /: /g;
	$str =~ s/\n\t+"date"\: "([^\"]*)"\,\n\t+"id"\: "([^\"]*)"\n\t+/ "date": "$1", "id": "$2" /g;
	while($str =~ /"([0-9]{4}-[0-9]{2}-[0-9]{2})": \{\n([^\}]*?)\}/){
		$date = $1;
		$contents = $2;
		$newcontent = "\n".$contents;
		$newcontent =~ s/\n\t+/ /g;
		# Replace
		$str =~ s/"$date": \{\n$contents\}/"$date": \{$newcontent\}/;
	}
	$str =~ s/\n\t+"CO2"\: ([^\,]*)\,\n\t+"ref"\: "([^\"]*)"\n\t+/"CO2": $1, "ref": "$2"/g;

	open(FILE,">",$config{'JSON'}||"data/index.json");
	print FILE $str;
	close(FILE);

	return;
}
sub daysBetween {
	my $a = daysSinceEpoch($_[0]);
	my $b = daysSinceEpoch($_[1]);
	return ($b-$a);
}
sub daysSinceEpoch {
	my ($y,$m,$d) = split(/\-/,$_[0]);
	my ($days,$ly,@m1,@m2,$yy,$mm);
	$days = 0;
	@m1 = (31,28,31,30,31,30,31,31,30,31,30,31);
	@m2 = (31,29,31,30,31,30,31,31,30,31,30,31);
	$m = int($m);
	$d = int($d);

	for($yy = 1970; $yy < $y; $yy++){
		# Add up years
		$days += (isLeapYear($yy) ? 366:365);
	}
	$ly = isLeapYear($y);
	# Add previous months
	for($mm = 1; $mm < $m; $mm++){
		$days += ($ly ? $m2[$mm-1] : $m1[$mm-1]);
	}
	# Add days of month
	$days += $d;
	
	return $days;
}
sub isLeapYear {
	my $yy = $_[0];
	my $ly = 0;
	if($yy%4==0){ $ly = 1; }
	if($yy%100==0){ $ly = 0; }
	if($yy%400==0){ $ly = 1; }
	return $ly;
}