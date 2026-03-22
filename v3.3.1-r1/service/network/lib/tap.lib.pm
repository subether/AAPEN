#
# ETHER|AAPEN|NETWORK - LIB|TAP
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
# add tap device using iproute2 [STRING],[BOOLEAN]
#
sub tap_add($json) {
	my $fid = "[tap_add_iproute2]";
	my $ffid = "TAP|ADD";
	my ($exec, $return, $status, $result);
	my $tapdb = net_db_obj_get("tap");

	my $node_net_cfg = config_node_network_get();
	
	# check for tap username
	if(!defined($node_net_cfg->{'tap'}{'user'} || $node_net_cfg->{'tap'}{'user'} eq "")){
		log_error($ffid, "tap user is not defined");
		return ("error: tap user is not defined", 0);
	}

	if(env_debug()){ json_encode_pretty($json); };

	# validate interface names
	if (!validate_interface_name($json->{'tap'}{'dev'})) {
		log_error($ffid, "invalid tap name - only alphanumeric, ., - and _ allowed (max 15 chars)");
		return ("error: invalid tap name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
	}
	if (!validate_interface_name($json->{'tap'}{'bri'})) {
		log_error($ffid, "invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)");
		return ("error: invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
	}

	# check if tap exists in database
	if( index_find($tapdb->{'index'}, $json->{'tap'}{'dev'}) ) {
		log_error($fid, "tap [" . $json->{'tap'}{'dev'} . "] already marked online!");
		return ("error: tap [" . $json->{'tap'}{'dev'} . "] already marked online", 0);
	}

	# check if bridge exists
	$exec = "ip link show " . $json->{'tap'}{'bri'} . " 2>/dev/null";
	$result = execute($exec);
	if($? != 0) {
		log_error($ffid, "bridge [" . $json->{'tap'}{'bri'} . "] not found!");
		return ("error: bridge [" . $json->{'tap'}{'bri'} . "] not found", 0);
	}

	# check if tap device physically exists
	$exec = "ip link show tap" . $json->{'tap'}{'dev'} . " 2>/dev/null";
	$result = execute($exec);
	if($? == 0) {
		log_error($ffid, "tap device [tap" . $json->{'tap'}{'dev'} . "] already exists!");
		return ("error: tap device [tap" . $json->{'tap'}{'dev'} . "] already exists", 0);
	}

	# create tap device with owner uid using iproute2
	$exec = "ip tuntap add mode tap user " . $node_net_cfg->{'tap'}{'user'} . " name tap" . $json->{'tap'}{'dev'};
	
	log_debug($fid, "exec [$exec]");
	$result = execute($exec);
	if($? != 0) {
		log_error($ffid, "failed to create tap device!");
		return ("error: failed to create tap device", 0);
	}
		
	# add tap to the bridge interface
	$exec = "ip link set tap" . $json->{'tap'}{'dev'} . " master " . $json->{'tap'}{'bri'};
	log_debug($fid, "exec [$exec]");
	$result = execute($exec);
	if($? != 0) {
		# Clean up tap device if bridge add failed
		execute("ip tuntap del mode tap name tap" . $json->{'tap'}{'dev'});
		log_error($fid, "failed to add tap to bridge!");
		return ("error: failed to add tap to bridge", 0);
	}
	
	# bring up the tap interface
	$exec = "ip link set tap" . $json->{'tap'}{'dev'} . " up";
	log_debug($fid, "exec [$exec]");
	$result = execute($exec);
	if($? != 0) {
		log_warn($fid, "failed to bring tap up (continuing anyway)");
	}
	
	# add tap to db
	$tapdb->{'index'} = index_add($tapdb->{'index'}, $json->{'tap'}{'dev'});
	
	# strip protocol header
	delete $json->{'proto'};
	delete $json->{'bri'}{'req'}; 
	
	# save to database
	$tapdb->{$json->{'tap'}{'dev'}} = $json;
	
	# tap created
	$return = "tap created (iproute2)";
	$status = 1;

	net_db_obj_set("tap", $tapdb);
	return ($return, $status);
}

#
# delete tap device using iproute2 [JSON-STR]
#
sub tap_del($json) {
	my $fid = "[tap_del_iproute2]";
	my $ffid = "TAP|DEL";
	my ($exec, $result, $skip_interface_ops);
	my $tapdb = net_db_obj_get("tap");
	
	if(env_verbose()){ json_encode_pretty($json); };


	# validate interface names
	if (!validate_interface_name($json->{'tap'}{'dev'})) {
		log_error($fid, "error: invalid tap name - only alphanumeric, ., - and _ allowed (max 15 chars)");
		return ("error: invalid tap name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
	}
	if (!validate_interface_name($json->{'tap'}{'bri'})) {
		log_error($fid, "error: invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)");
		return ("error: invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
	}

	# check if tap exists in database
	if( !index_find($tapdb->{'index'}, $json->{'tap'}{'dev'}) ) {
		log_warn($ffid, "tap [$json->{'tap'}{'dev'}] offline or unknown! cannot remove it");
		return packet_build_encode("0", "error: tap [" . $json->{'tap'}{'dev'} . "] offline or unknown! cannot remove it.", $fid);
	}

	# check if tap device physically exists
	$exec = "ip link show tap" . $json->{'tap'}{'dev'} . " 2>/dev/null";
	$result = execute($exec);
	$skip_interface_ops = ($? != 0);
	if($skip_interface_ops) {
		log_warn($ffid, "warning: tap device [tap" . $json->{'tap'}{'dev'} . "] not found (continuing with cleanup)");
	}

	# Only attempt interface operations if it exists
	if(!$skip_interface_ops) {
		# bring down tap device
		$exec = "ip link set tap" . $json->{'tap'}{'dev'} . " down";
		log_debug($fid, "exec [$exec]");
		$result = execute($exec);
		if($? != 0) {
			print "[" . date_get() . "] $fid warning: failed to bring tap down (continuing anyway)\n";
		}
		
		# remove tap from bridge interface
		$exec = "ip link set tap" . $json->{'tap'}{'dev'} . " nomaster";
		log_debug($fid, "exec [$exec]");
		$result = execute($exec);
		if($? != 0) {
			print "[" . date_get() . "] $fid warning: failed to remove tap from bridge (continuing anyway)\n";
		}

		# remove tap device
		$exec = "ip tuntap del mode tap name tap" . $json->{'tap'}{'dev'};
		log_debug($fid, "exec [$exec]");
		$result = execute($exec);
		if($? != 0) {
			print "[" . date_get() . "] $fid error: failed to delete tap device!\n";
			return packet_build_encode("0", "error: failed to delete tap device", $fid);
		}
	}

	# remove tap from db
	$tapdb->{'index'} = index_del($tapdb->{'index'}, $json->{'tap'}{'dev'});
	log_debug($fid, "index [$tapdb->{'index'}]");

	# delete tap data
	delete $tapdb->{$json->{'tap'}{'dev'}};		
	log_info($ffid, "tap [$json->{'tap'}{'dev'}] destroyed");
	$result = packet_build_encode("1", "success: tap [" . $json->{'tap'}{'dev'} . "] removed", $fid);

	net_db_obj_set("tap", $tapdb);
	return $result;
}

#
# return tap data [JSON-OBJ]
#
sub tap_info(){
	my $fid = "[tap_info]";
	my $tapdb = db_obj_get("tap");
	return $tapdb;
}

#
# return tap data [JSON-OBJ]
#
sub tap_meta(){
	my $fid = "[tap_meta]";
	my $tapdb = net_db_obj_get("tap");
	
	if(env_verbose()){
		print "$fid tap database\n";
		json_encode_pretty($tapdb);
	}
	return $tapdb->{'index'};
}

#
# return tap data [JSON-STR]
#
sub tap_info_db(){
	my $fid = "[tap_info]";
	my $tapdb = net_db_obj_get("tap");

	if(env_verbose()){
		print "[" . date_get() . "] $fid returning tap data\n";
		json_encode_pretty($tapdb);
	}
	
	my $result = packet_build_noencode("1", "$fid returning tap database", $fid);
	$result->{'tapdb'} = $tapdb;
	return json_encode($result);
}

1;
