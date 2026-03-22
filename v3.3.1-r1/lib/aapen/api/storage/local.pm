#
# ETHER|AAPEN|LIBS - API|STORAGE|LOCAL
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1ersion: 3.3.1
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
# ping network service [JSON-OBJ]
#
sub api_storage_local_ping($socket){
	my $fid = "[api_storage_local_ping]";
	my $packet = api_proto_packet_build("storage", "ping");
	return api_socket_send($socket, $packet, $fid);
}

#
# add vm network device [JSON-OBJ]
#
sub api_storage_local_pool_get($socket, $pool){
	my $fid = "[api_storage_local_pool_get]";
	my $packet = api_proto_packet_build("storage", "pool_get");	
	$packet->{'storage'}{'pool'} = $pool;
	return api_socket_send($socket, $packet, $fid);
}

1;
