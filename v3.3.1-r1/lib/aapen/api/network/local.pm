#
# ETHER|AAPEN|LIBS - API|NETWORK|LOCAL
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
# ping network service [JSON-OBJ]
#
sub api_network_local_ping($socket){
	my $fid = "[api_network_local_ping]";
	my $packet = api_proto_packet_build("net", "ping");
	return api_socket_send($socket, $packet, $fid);
}

#
# network service meta [JSON-OBJ]
#
sub api_network_local_meta($socket){
	my $fid = "[api_network_local_meta]";
	my $packet = api_proto_packet_build("net", "meta");
	return api_socket_send($socket, $packet, $fid);
}

#
# add vm network device [JSON-OBJ]
#
sub api_network_local_vm_get($socket, $vmname){
	my $fid = "[api_network_local_vm_get]";
	my $packet = api_proto_packet_build("net", "vm");	
	$packet->{'vm'}{'req'} = "get";
	$packet->{'vm'}{'name'} = $vmname;
	return api_socket_send($socket, $packet, $fid);
}

#
# add vm network device [JSON-OBJ]
#
sub api_network_local_vm_nic_add($socket, $vm){
	my $fid = "[api_network_local_vm_nic_add]";
	my $packet = api_proto_packet_build("net", "vm");	
	$packet->{'vm'}{'req'} = "nicadd";
	$packet->{'vm'}{'data'} = $vm;
	return api_socket_send($socket, $packet, $fid);
}

#
# delete vm network device [JSON-OBJ]
#
sub api_network_local_vm_nic_del($socket, $vm){
	my $fid = "[api_network_local_vm_nic_del]";
	my $packet = api_proto_packet_build("net", "vm");
	$packet->{'vm'}{'req'} = "nicdel";
	$packet->{'vm'}{'data'} = $vm;
	return api_socket_send($socket, $packet, $fid);
}

1;
