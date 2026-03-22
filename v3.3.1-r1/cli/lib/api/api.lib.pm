#
# ETHER|AAPEN|CLI - LIB|API
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
# ping API [NULL]
#
sub api_ping() {
	my $fid = "[api_ping]";
	my $ffid = "API|PING";
	
	my $packet = api_packet_build("ping", "", "", "");
	my $result = api_send($packet);
	api_rest_response_print($ffid, $result, "API ping");
}

#
# build api packet [JSON-OBJ]
#
sub api_packet_build($req, $obj, $id, $node) {
	my $fid = "[api_packet_build]";
	my $ffid = "API|PACKET|BUILD";

	my $packet = packet_head_build("cli");
	$packet->{'proto'}{'req'} = $req;
	$packet->{'proto'}{'obj'} = $obj;
	$packet->{'proto'}{'id'} = $id;
	$packet->{'proto'}{'key'} = $id;
	$packet->{'proto'}{'node'} = $node;
		
	return $packet;
}

#
# send api packet [JSON-OBJ]
#
sub api_send($packet) {
	my $fid = "[api_send]";
	my $ffid = "API|SEND";
	my $data = json_encode($packet);
	my $response;
	
	# configure socket
	my $socket = new IO::Socket::INET (
		PeerAddr => config_base_api_address(),
		PeerPort => config_base_api_port(),
		Proto => 'tcp',
		Timeout => '1',
		Reuse => 1
	) or die "$ffid ERROR in INET Socket Creation: $!\n";

	# print to socket
	print $socket "$data\n";
	chomp($response = <$socket>);
	
	return json_decode($response);
}

#
# show api base config [NULL]
#
sub api_config_base_show(){
	my $ffid = "API|CONFIG|BASE";
	my $base_config = config_base_get();
	api_print_success_json($ffid, "api base config", $base_config);
}

#
# show api node config [NULL]
#
sub api_config_node_show(){
	my $ffid = "API|CONFIG|NODE";
	my $node_config = config_node_get();
	api_print_success_json($ffid, "api node config", $node_config);
}

1;
