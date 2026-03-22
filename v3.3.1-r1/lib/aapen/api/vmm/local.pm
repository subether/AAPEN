#
# ETHER|AAPEN|LIBS - API|SYSTEM|LOCAL
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
# get socket path [STRING]
#
sub api_vmm_local_socket_path($vm){
	my $fid = "[api_vmm_local_socket_path]";
	my $socket = $vm->{'meta'}{'vmm'}{'vmmsock'};
	if(env_verbose()){ print "$fid socket [$socket]\n"; };
	return $socket;
}

#
# vmm info [JSON-OBJ]
#
sub api_vmm_local_info($socket){
	my $fid = "[api_vmm_local_info]";
	my $packet = api_proto_packet_build("vmm", "info");
	return api_socket_send($socket, $packet, $fid);
}

#
# vmm info [JSON-OBJ]
#
sub api_vmm_local_info_new($socket){
	my $fid = "[api_vmm_local_info_new]";
	my $packet = api_proto_packet_build("vmm", "info_new");
	return api_socket_send($socket, $packet, $fid);
}

#
# ping vmm [JSON-OBJ]
#
sub api_vmm_local_ping($socket){
	my $fid = "[api_vmm_local_ping]";
	my $packet = api_proto_packet_build("vmm", "ping");
	return api_socket_send($socket, $packet, $fid);
}

#
# push vmm config [JSON-OBJ]
#
sub api_vmm_local_push($vm){
	my $fid = "[api_vmm_local_push]";
	my $socket = api_vmm_local_socket_path($vm);
	my $packet = api_proto_packet_build("vmm", "push");
	$packet->{'vm'} = $vm;
	return api_socket_send($socket, $packet, $fid);
}

#
# pull vmm config [JSON-OBJ]
#
sub api_vmm_local_pull($socket){
	my $fid = "[api_vmm_local_pull]";
	my $packet = api_proto_packet_build("vmm", "pull");
	return api_socket_send($socket, $packet, $fid);
}

#
# vmm load [JSON-OBJ]
#
sub api_vmm_local_load($vm){
	my $fid = "[api_vmm_local_load]";
	my $socket = api_vmm_local_socket_path($vm);
	my $packet = api_proto_packet_build("vmm", "load");
	return api_socket_send($socket, $packet, $fid);
}

#
# vmm unload [JSON-OBJ]
#
sub api_vmm_local_unload($vm){
	my $fid = "[api_vmm_local_unload]";
	my $socket = api_vmm_local_socket_path($vm);
	my $packet = api_proto_packet_build("vmm", "unload");
	return api_socket_send($socket, $packet, $fid);
}

#
# vmm reset [JSON-OBJ]
#
sub api_vmm_local_reset($vm){
	my $fid = "[api_vmm_local_reset]";
	my $socket = api_vmm_local_socket_path($vm);
	my $packet = api_proto_packet_build("vmm", "reset");
	return api_socket_send($socket, $packet, $fid);
}

#
# vmm shutdown [JSON-OBJ]
#
sub api_vmm_local_shutdown($vm){
	my $fid = "[api_vmm_local_shutdown]";
	my $socket = api_vmm_local_socket_path($vm);
	my $packet = api_proto_packet_build("vmm", "shutdown");
	return api_socket_send($socket, $packet, $fid);
}

#
# vmm migrate [JSON-OBJ]
#
sub api_vmm_local_migrate($vm, $request){
	my $fid = "[api_vmm_local_vmm_migrate]";
	my $socket = api_vmm_local_socket_path($vm);	
	my $packet = api_proto_packet_build("vmm", "migrate");
	
	$packet->{'dest'}{'port'} = $request->{'port'};
	$packet->{'dest'}{'addr'} = $request->{'host'};
	$packet->{'dest'}{'proto'} = $request->{'proto'};
	
	print "$fid migration request\n";
	json_encode_pretty($packet);
	
	return api_socket_send($socket, $packet, $fid);
}

1;
