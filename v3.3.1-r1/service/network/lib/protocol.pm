#
# ETHER|AAPEN|NETWORK - LIB|PROTOCOL
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#

use strict;
use warnings;
use experimental 'signatures';


#
# protocol handler [JSON-STR]
#
sub protocol($packet){
	my $fid = "[protocol]";
	my $ffid = "PROTOCOL";
	my $err = "";
	my $result = 0;

	try{
		log_info_json($ffid, "request [$packet->{'net'}{'req'}]", $packet);
		my $request = $packet->{'net'}{'req'};
		
		# return version
		if($request eq "ping"){ $result = packet_build_encode("1", "pong", "[ping]"); };
		
		# environment
		if($request eq "env"){ 
			$result = env_update($packet->{'net'});
		};
		
		# return info
		if($request eq "info"){ $result = info(); };

		# return metadata
		if($request eq "meta"){ $result = meta(); };

		# push network
		if($request eq "push"){ $result = net_push($packet->{'net'}{'obj'}); };

		# pull network
		if($request eq "pull"){ $result = net_pull($packet->{'net'}{'id'}); };

		# vm networking
		if($request eq "vm"){ $result = vm_protocol($packet); };

		# vpp management
		if($request eq "vpp"){ $result = vpp_protocol($packet); };
		
		# tap management
		if($request eq "tap"){ $result = tap_protocol($packet); };
	
		# device management
		if($request eq "dev_info"){ $result = dev_info(); };
		
		
		if(!$result){
			$result = packet_build_encode("0", "error: failed to process command", $fid);
		}
		else{
			#config_state_save("network", $db);
		}
	}	
	catch{
		log_error($ffid, "error: fatal error during processing!");
		$result = packet_build_encode("0", "error: fatal error during processing!", $fid);
	}	 
	
	#json_decode_pretty($result);
	return $result;
}

#
# VM protocol
#
sub vm_protocol($packet){
	my $fid = "[vm_protocol]";
	my $ffid = "PROTOCOL|VM";
	my ($result, $status, $string);

	# vm processing
	log_info($ffid, "request [" . $packet->{'vm'}{'req'} . "]");
	my $request = $packet->{'vm'}{'req'};

	# add network device
	if($request eq "nicadd"){ $result = vm_nic_add($packet->{'vm'}{'data'}); };
	
	# remove network device
	if($request eq "nicdel"){ $result = vm_nic_del($packet->{'vm'}{'data'}); };

	# remove network device
	if($request eq "get"){ $result = vm_get($packet); };
		
	# fallback
	if(!$result){
		log_warn($ffid, "failed to process request");
		$result = packet_build_encode("error", "failed to process request", $fid);	
	}
	
	return $result;
}

#
# tap management protocol
#
sub tap_protocol($packet){
	my $fid = "[tap_protocol]";
	my $ffid = "PROTOCOL|TAP";
	my ($result, $status, $string);

	# process tap header
	log_info($ffid, "request [" . $packet->{'tap'}{'req'} . "]");
	my $request = $packet->{'tap'}{'req'};

	# add tap device
	if($request eq "add"){
		($status, $string) = tap_add($packet);
		$result = packet_build_encode($string, $status, $fid);	
	}
	
	# delete tap device
	if($request eq "del"){ $result = tap_del($packet); };
	
	# tap info
	if($request eq "info"){ $result = tap_info_db(); };

	if(!$result){
		log_warn($ffid, "failed to process request");
		$result = packet_build_encode("error", "failed to process request", $fid);	
	}
	
	return $result;
}

#
# tap management protocol [JSON-STR]
#
sub vpp_protocol($packet){
	my $fid = "[vpp_protocol]";
	my $ffid = "PROTOCOL|VPP";
	my ($result, $status, $string);

	log_info($ffid, "request [" . $packet->{'vpp'}{'req'} . "]");
	my $request = $packet->{'vpp'}{'req'};

	# show version
	if($request eq "version"){ $result = vpp_show_ver(); };

	# show interface
	if($request eq "show_int"){ $result = vpp_show_int(); };

	# delete vnic
	if($request eq "vnic_del"){ $result = vpp_del_vnic($packet); };

	if(!$result){
		log_warn($ffid, "failed to process request");
		$result = packet_build_encode("error", "failed to process request", $fid);	
	}
	
	return $result;
}

1;
