#
# ETHER|AAPEN|LIBS - API|FRAMEWORK|LOCAL
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
# ping local net subsystem [JSON-OBJ]
#
sub api_framework_local_ping($socket){
	my $fid = "[api_framework_local_ping]";
	my $packet = api_proto_packet_build("frame", "ping");
	return api_socket_send($socket, $packet, $fid);
	
}

#
# ping local net subsystem [JSON-OBJ]
#
sub api_framework_local_meta($socket){
	my $fid = "[api_framework_local_meta]";
	my $packet = api_proto_packet_build("frame", "meta");
	return api_socket_send($socket, $packet, $fid);
	
}

#
# framework vmm info [JSON-OBJ]
#
sub api_framework_local_vmm_info($socket, $vm){
	my $fid = "[api_framework_local_vmm_info]";

	my $packet = api_proto_packet_build("frame", "vmm");	
	$packet->{'vmm'}{'req'} = "info";
	$packet->{'vmm'}{'id'} = $vm;

	return api_socket_send($socket, $packet, $fid);
}

#
# framework spawn vmm [JSON-STR]
#
sub api_framework_local_vmm_start($socket, $vm){
	my $fid = "[api_framework_local_vmm_start]";
	
	my $packet = api_proto_packet_build("frame", "vmm");
	$packet->{'vmm'}{'req'} = "start";
	$packet->{'vmm'}{'vm'} = $vm;

	return api_socket_send($socket, $packet, $fid);
}

#
# framework kill vmm [JSON-STR]
#
sub api_framework_local_vmm_stop($socket, $vmmid){
	my $fid = "[api_framework_local_vmm_stop]";

	my $packet = api_proto_packet_build("frame", "vmm");	
	$packet->{'vmm'}{'req'} = "stop";
	$packet->{'vmm'}{'id'} = $vmmid;

	return api_socket_send($socket, $packet, $fid);
}

#
# ping local cluster [JSON-OBJ]
#
sub api_framework_local_env_set($socket, $envflag){
	my $fid = "[api_framework_local_env_set]";	
	
	my $packet = api_proto_packet_build("frame", "env_update");
	$packet->{'frame'}{'env'} = $envflag;
	
	return api_socket_send($socket, $packet, $fid);
}

1;
