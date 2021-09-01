package ODILeeds::CarbonAPI;

# Port of https://gitlab.com/wholegrain/carbon-api-2-0/-/blob/master/includes/carbonapi.php
# Version 1.0

use strict;
use warnings;
use Data::Dumper;
use URI::Split qw/ uri_split /;
use JSON::XS;
use POSIX qw(strftime);

my $KWG_PER_GB = 1.805;
my $RETURNING_VISITOR_PERCENTAGE = 0.75;
my $FIRST_TIME_VIEWING_PERCENTAGE = 0.25;
my $PERCENTAGE_OF_DATA_LOADED_ON_SUBSEQUENT_LOAD = 0.02;
my $CARBON_PER_KWG_GRID = 475;
my $CARBON_PER_KWG_RENEWABLE = 33.4;
my $PERCENTAGE_OF_ENERGY_IN_DATACENTER = 0.1008;
my $PERCENTAGE_OF_ENERGY_IN_TRANSMISSION_AND_END_USER = 0.8992;
my $CO2_GRAMS_TO_LITRES = 0.5562;



sub new {
	my ($class, %args) = @_;
 	my ($entry,$self,$date,$recent,$file,$filename);

	$self = \%args;
 
	bless $self, $class;

	# Find most recent version of the green energy database
	opendir(DIR,"data/raw/");
	$date = "";
	$recent = "";
	$file = "";
	while( ($filename = readdir(DIR))) {
		if($filename =~ /([0-9]{4}-[0-9]{2}-[0-9]{2})\.db/){
			$date = $1;
			if($date gt $recent){
				$file = $filename;
				$recent = $date;
			}
		}
	}
	closedir(DIR);
	if($file){
		$self->{'db'} = "data/raw/$file";
	}else{
		print "Error: Please download and gunzip a green energy SQLite file from https://admin.thegreenwebfoundation.org/admin/green-urls and save it in data/raw/\n";
		exit;
	}

	return $self;
}

# Get SQLite database from: https://admin.thegreenwebfoundation.org/admin/green-urls
sub getGreen {
	my ($self, $url) = @_;
	my (@parts,$host,$rtn);
	if($url){
		@parts = uri_split($url);
		$host = $parts[1];
		$rtn = `sqlite3 $self->{'db'} "select url,modified from greendomain where url = '$host'"`;
	}
	return ($rtn ? 1 : 0);
}

sub getSafeURL {
	my ($self,$url) = @_;
	$url =~ s/https?:\/\///g;
	$url =~ s/\./\_/g;
	$url =~ s/\//\_/g;
	$url =~ s/\?//g;
	$url =~ s/\=//g;
	$url =~ s/\_+/\_/g;
	$url =~ s/\_$//g;
	return lc($url);
}

sub makeEntry {
	my ($self, $url) = @_;
	my ($pageSpeedParameters,%results,$bytesTransfered,$statistics,$co2,%entry,$str,$json,@lines,@items,$n,%images,$safeurl,$jfile,$download,$today);

	if(!$url){ return {}; }
	# Setup the default parameters required for google
	# Add the google page speed api key if it exists
	$results{'pagespeedapi'} = { 'url' => 'https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url='.$url.($ENV{'CC_GPSAPI_KEY'} ? '&key='.$ENV{'CC_GPSAPI_KEY'} :'') };
	$results{'greenweb'} = { 'green'=>$self->getGreen($url) };
	
	$safeurl = $self->getSafeURL($url);
	$jfile = "data/raw/$safeurl.json";
	$download = 0;
	$today = strftime('%Y-%m-%d',gmtime());

	if(-e $jfile){
		open(FILE,$jfile);
		@lines = <FILE>;
		close(FILE);
		$str = join("",@lines);
		if($str eq ""){
			print "ERROR: No input for $jfile\n";
			return {};
		}
		$json = JSON::XS->new->utf8->decode($str);
		if(!$json->{'analysisUTCTimestamp'}){
			$download = 1;
		}
		if($json->{'analysisUTCTimestamp'} && substr($json->{'analysisUTCTimestamp'},0,10) ne $today){
			$download = 1;
		}
	}else{
		$download = 1;
	}

	if($download){
		print "Downloading $results{'pagespeedapi'}{'url'} ...\n";
		$str = `curl -s "$results{'pagespeedapi'}{'url'}"`;
		# Save the contents
		open(FILE,">",$jfile);
		print FILE $str;
		close(FILE);
		if($str eq ""){
			print "ERROR: No input for $jfile\n";
			return {};
		}
		$json = JSON::XS->new->utf8->decode($str);
	}
	$n = 0;
	if($json->{'lighthouseResult'}{'audits'}{'network-requests'}{'details'}{'items'}){
		@items = @{$json->{'lighthouseResult'}{'audits'}{'network-requests'}{'details'}{'items'}};
		$n = @items;
	}

	# If google page speed api didnt work
	if($n == 0){ return {'downloaded'=>$download,'url'=>$url}; }

	$results{'pagespeedapi'} = $json;

	# Calc the transfer size
	$bytesTransfered = calculateTransferedBytes(@items);

	# Calculate the statistics as we need the co2 emissions
	$statistics = $self->getStatistics($bytesTransfered);

	# pull the co2 relative to the energy
	$co2 = ($results{'greenweb'}{'green'} ? $statistics->{'co2'}{'renewable'}{'grams'} : $statistics->{'co2'}{'grid'}{'grams'});

	%images = %{$self->getImages(@items)};
	return {
		'downloaded'=> $download,
		'url'       => $url,
		'bytes'     => $bytesTransfered,
		'images'    => \%images,
		'green'     => $results{'greenweb'}{'green'},
		'co2'       => $co2
	};
}
	
	

# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
# Helper functions for calculating emissions
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
sub calculateTransferedBytes {
	my ($self, @items) = @_;
	my ($carry,$i);
	$carry = 0;
	for($i = 0; $i < @items; $i++){
		if($items[$i]{'transferSize'}){
			$carry += $items[$i]{'transferSize'};
		}
	}
	return $carry;
}

sub getImages {
	my ($self, @items) = @_;
	my ($i,$b,@im);
	$b = 0;
	for($i = 0; $i < @items; $i++){
		if($items[$i]{'resourceType'} && $items[$i]{'resourceType'} eq "Image" && $items[$i]{'transferSize'}){
			$b += $items[$i]{'transferSize'};
			push(@im,{'url'=>$items[$i]{'url'},'bytes'=>$items[$i]{'transferSize'}+0,'time'=>int($items[$i]{'endTime'}-$items[$i]{'startTime'})});
		}
	}
	return {'i'=>\@im,'bytes'=>$b};
}

sub getStatistics {
	my ($self, $bytes) = @_;

	my $bytesAdjusted = $self->adjustDataTransfer($bytes);
	my $energy = $self->energyConsumption($bytesAdjusted);
	my $co2Grid = $self->getCo2Grid($energy);
	my $co2Renewable = $self->getCo2Renewable($energy);

	return {
		'adjustedBytes' => $bytesAdjusted,
		'energy' => $energy,
		'co2' => {
			'grid' => {
				'grams' => $co2Grid,
				'litres'=> $self->co2ToLitres($co2Grid)
			},
			'renewable' => {
				'grams' => $co2Renewable,
				'litres' => $self->co2ToLitres($co2Renewable)
			}
		}
	};
}

sub adjustDataTransfer {
	my ($self, $val) = @_;
	return ($val * $RETURNING_VISITOR_PERCENTAGE) + ($PERCENTAGE_OF_DATA_LOADED_ON_SUBSEQUENT_LOAD * $val * $FIRST_TIME_VIEWING_PERCENTAGE);
}

sub energyConsumption {
	my ($self, $bytes) = @_;
	return $bytes * ($KWG_PER_GB / 1073741824);
}

sub getCo2Grid {
	my ($self, $energy) = @_;
	return $energy * $CARBON_PER_KWG_GRID;
}

sub getCo2Renewable {
	my ($self, $energy) = @_;
	return (($energy * $PERCENTAGE_OF_ENERGY_IN_DATACENTER) * $CARBON_PER_KWG_RENEWABLE) + (($energy * $PERCENTAGE_OF_ENERGY_IN_TRANSMISSION_AND_END_USER) * $CARBON_PER_KWG_GRID);
}

sub co2ToLitres {
	my ($self, $co2) = @_;
	return $co2 * $CO2_GRAMS_TO_LITRES;
}




1;