#
# ETHER|AAPEN|CLI - LIB|NODE|HYPERVISOR
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
use JSON::MaybeXS;

#
# ping hypervisor on node [JSON-OBJ]
#
sub node_rest_hypervisor_ping($node_name){
	my $fid = "node_rest_hypervisor_ping";
	my $ffid = "NODE|HYPERVISOR|PING";
	my $result = rest_get_request("/service/hypervisor/ping?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node hypervisor ping");
}

#
# get hypervisor meta from node [JSON-OBJ]
#
sub node_rest_hypervisor_meta($node_name){
	my $fid = "node_rest_hypervisor_meta";
	my $ffid = "NODE|HYPERVISOR|META";
	my $result = rest_get_request("/service/hypervisor/meta?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node hypervisor meta");
}

#
# reset system via REST [NULL]
#
sub node_rest_hypervisor_system_destroy($node_name, $system_name){
	my $fid = "hypervisor_system_destroy";
	my $ffid = "NODE|HYPERVISOR|SYSTEM|DESTROY";
	
	print "$ffid system name [$system_name] node name [$node_name]\n";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $system_name && string_validate($system_name)){
			# send REST post request
			my $result = rest_post_request("/service/hypervisor/system/destroy", {system => $system_name, node => $node_name});
			api_rest_response_print($ffid, $result, "system destroy");
		}
		else{
			print "$ffid error: node name invalid!\n"
		}
	}	
	else{
		print "$ffid error: system name invalid!\n"
	}
}


1;
