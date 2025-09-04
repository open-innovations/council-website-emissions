#!/usr/bin/perl


my $bytes = $ARGV[0];
print "Bytes = $bytes\n";
print "CO2 = ".getStatistics($bytes,0)."\n";

# Calculate total CO2 here and correct for green energy
sub getStatistics {
	my ($bytes, $green) = @_;
	
	my $DataTransferredGB = $bytes/1e9;


	# Estimated emissions (gCO2e/GB) = Operational emissions + Embodied emissions
	# or
	# Average Emissions per Page View (gCO2e) = 
	#	([(OPDC × (1 - Green Hosting Factor) + EMDC) + (OPN + EMN) + (OPUD + EMUD)] × New Visitor Ratio)
	#	+
	#	([(OPDC × (1 - Green Hosting Factor) + EMDC) + (OPN + EMN) + (OPUD + EMUD)] × Return Visitor Ratio × (1 - Data Cache Ratio))

	my $GridCarbonIntensity = 494; # grams CO2e/kWh - global average grid intensity of 494 grams CO2e/kWh which is pulled from the CO2 intensity dataset for "World" of Ember’s Data Explorer

	# The final values we obtain for operational energy intensity are:
	my $EnergyIntensity = {
		'DataCentres'=> 0.055, # kWh/GB
		'Network'=> 0.059, # kWh/GB
		'UserDevices'=> 0.080 # kWh/GB
	};
	
	# The final values we obtain for embodied emissions are:
	my $EmbodiedEmissions = {
		'DataCentres'=> 0.012, # kWh/GB
    	'Network'=> 0.013, # kWh/GB
		'UserDevices'=> 0.081 # kWh/GB
	};

	# Operational emissions for segment  (gCO2e/GB) = Data transfer (GB) × Energy intensity (kWh/GB) × Grid carbon intensity (gCO2e/kWh)
	my $GreenHostingFactor = ($green ? 1 : 0);	# The portion of hosting services powered by renewable or zero-carbon energy, between 0 and 1
	
	my $OPDC = $DataTransferredGB * $EnergyIntensity->{'DataCentres'} * $GridCarbonIntensity;	# Operational Emissions Data Centers
	my $OPN = $DataTransferredGB * $EnergyIntensity->{'Network'} * $GridCarbonIntensity;	# Operational Emissions Networks
	my $OPUD = $DataTransferredGB * $EnergyIntensity->{'UserDevices'} * $GridCarbonIntensity; # Operational Emissions User Devices
	my $EMDC = $DataTransferredGB * $EmbodiedEmissions->{'DataCentres'} * $GridCarbonIntensity;	# Embodied Emissions Data Centers
	my $EMN = $DataTransferredGB * $EmbodiedEmissions->{'Network'} * $GridCarbonIntensity; # Embodied Emissions Networks
	my $EMUD = $DataTransferredGB * $EmbodiedEmissions->{'UserDevices'} * $GridCarbonIntensity; # Embodied Emissions User Devices
	my $NewVisitorRatio = 0.9; # The portion of first time visitors to a web page, between 0 and 1 (v2 figure was 0.25 but examples at https://developers.thegreenwebfoundation.org/co2js/methods/ use 0.9)
	my $ReturnVisitorRatio = 1-$NewVisitorRatio; # The portion of returning visitors to a web page, between 0 and 1
	my $DataCacheRatio = 0.25; # The portion of data that is loaded from cache for returning visitors, between 0 and 1. Guesstimate based on WebsiteCarbon giving 0.33g for Leeds City Council's 2258038 bytes

	my $co2 = (($OPDC * (1-$GreenHostingFactor) + $EMDC) + ($OPN + $EMN) + ($OPUD + $EMUD));

	return ($co2 * $NewVisitorRatio) + ($co2 * $ReturnVisitorRatio * (1-$DataCacheRatio));
}
