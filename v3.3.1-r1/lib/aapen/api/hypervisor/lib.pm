#
# ETHER|AAPEN|LIBS - API|HYPERVISOR|LIB
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
# ping hypervisor [JSON-OBJ]
#
sub api_hypervisor_ping($node){
	my $fid = "[api_hypervisor_ping]";
	my $packet = api_proto_packet_build("hyper", "ping");
	return api_proto_ssl_send($node, $packet, $fid);
}

#
# push data to hypervisor [JSON-OBJ]
#
sub api_hypervisor_push($node, $json){
	my $fid = "[api_hypervisor_push]";
	my $packet = api_proto_packet_build("hyper", "push");
	$packet->{'hyper'}{'vm'} = $json;
	return api_proto_ssl_send($node, $packet, $fid);
}

#
# request system load [JSON-OBJ]
#
sub api_hypervisor_info($node){
	my $fid = "[api_hypervisor_info]";
	my $packet = api_proto_packet_build("hyper", "info");
	return api_proto_ssl_send($node, $packet, $fid);
}

#
# request system load [JSON-OBJ]
#
sub api_hypervisor_meta($node){
	my $fid = "[api_hypervisor_meta]";
	my $packet = api_proto_packet_build("hyper", "info");
	return api_proto_ssl_send($node, $packet, $fid);
}

1;
