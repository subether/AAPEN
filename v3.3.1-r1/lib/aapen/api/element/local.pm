#
# ETHER|AAPEN|LIBS - API|ELEMENT|LOCAL
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

use aapen::api::protocol;


#
# ping local element service [JSON-OBJ]
#
sub api_element_local_ping($socket){
	my $fid = "[api_element_local_ping]";	
	my $packet = api_proto_packet_build("element", "ping");
	my $pong = api_socket_send($socket, $packet, $fid);
	return $pong;
}


1;
