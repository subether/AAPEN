#
# ETHER|AAPEN|LIBS - API|PROTOCOL
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
use Exporter::Auto;
use Term::ANSIColor qw(:constants);
use JSON::MaybeXS;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# send network request [JSON-OBJ]
#
sub api_proto_ssl_send($node, $packet, $fid){
	my $node_cfg = nodedb_node_get($node);
	my $result = ssl_send_json($packet, $node_cfg);
	return json_decode($result);	
}	

#
# local network socket send [JSON-OBJ]
#
sub api_socket_send($socket, $packet, $fid){
	my $result = socket_encode_send($socket, $packet);
	my $json = socket_return_check($socket, $result);
	return json_decode($json);
}

#
# build storage packet [JSON-OBJ]
#
sub api_proto_packet_build($service, $req){
	my $packet;
	$packet->{'proto'}{'pass'} = config_base_api_key();
	$packet->{'proto'}{'date'} = date_get();
	$packet->{'proto'}{'packet'} = $service;
	$packet->{$service}{'req'} = $req;
	return $packet;
}

1;
