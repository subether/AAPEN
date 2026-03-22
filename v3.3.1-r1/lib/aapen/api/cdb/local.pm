#
# ETHER|AAPEN|LIBS - API|CDB|LOCAL
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
# ping local cluster [JSON-OBJ]
#
sub api_cdb_local_ping($socket){
	my $fid = "[api_cdb_local_ping]";	
	my $packet = api_proto_packet_build("cdb", "ping");	
	return api_socket_send($socket, $packet, $fid);
}

#
# get local cluster db [JSON-OBJ]
#
sub api_cdb_local_db_get($socket){
	my $fid = "[api_cdb_local_db_get]";	
	my $packet = api_proto_packet_build("cdb", "db_get");
	return api_socket_send($socket, $packet, $fid);
}

#
# get local cluster db [JSON-OBJ]
#
sub api_cdb_local_db_flush($socket){
	my $fid = "[api_cdb_local_db_flush]";	
	my $packet = api_proto_packet_build("cdb", "db_flush");
	return api_socket_send($socket, $packet, $fid);
}

#
# get local cluster metadata [JSON-OBJ]
#
sub api_cdb_local_meta_get($socket){
	my $fid = "[api_cdb_local_meta_get]";
	my $packet = api_proto_packet_build("cdb", "meta_get");
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster system data [JSON-OBJ]
#
sub api_cdb_obj_set($socket, $object, $data){
	my $fid = "[api_cdb_obj_set]";
	my $packet = api_proto_packet_build("cdb", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cdb'}{'obj'} = $object;
	$packet->{'cdb'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cdb'}{'id'} = $data->{'id'}{'id'};
	
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster system data [JSON-OBJ]
#
sub api_cdb_local_obj_del($socket, $object, $data){
	my $fid = "[api_cdb_local_obj_del]";
	my $packet = api_proto_packet_build("cdb", "obj_del");
	$packet->{'cdb'}{'obj'} = $object;
	$packet->{'cdb'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cdb'}{'id'} = $data->{'id'}{'id'};
	
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster system data [JSON-OBJ]
#
sub api_cdb_local_obj_del_new($socket, $object, $key){
	my $fid = "[api_cdb_local_obj_del]";
	my $packet = api_proto_packet_build("cdb", "obj_del");
	$packet->{'cdb'}{'obj'} = $object;
	$packet->{'cdb'}{'key'} = $key;

	return api_socket_send($socket, $packet, $fid);
}

#
# get cluster object data [JSON-OBJ]
#
sub api_cdb_local_obj_get($socket, $object, $key){
	my $fid = "[api_cdb_local_obj_get]";	
	my $packet = api_proto_packet_build("cdb", "obj_get");
	$packet->{'cdb'}{'obj'} = $object;
	$packet->{'cdb'}{'key'} = $key;
	return api_socket_send($socket, $packet, $fid);
}

#
# ping local cluster [JSON-OBJ]
#
sub api_cdb_local_env_set($socket, $envflag){
	my $fid = "[api_cdb_local_env_set]";
	my $packet = api_proto_packet_build("cdb", "env_update");
	$packet->{'cdb'}{'env'} = $envflag;
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster service data [JSON-OBJ]
#
sub api_cdb_local_service_set($socket, $data){
	my $fid = "[api_cdb_local_service_set]";
	my $packet = api_proto_packet_build("cdb", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cdb'}{'obj'} = "service";
	$packet->{'cdb'}{'key'} = $data->{'config'}{'name'};
	$packet->{'cdb'}{'id'} = $data->{'config'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster service data [JSON-OBJ]
#
sub api_cdb_local_service_get($socket, $service, $node){
	my $fid = "[api_cdb_local_service_get]";
	my $packet = api_proto_packet_build("cdb", "obj_get");
	$packet->{'cdb'}{'obj'} = "service";
	$packet->{'cdb'}{'key'} = $service;
	$packet->{'cdb'}{'id'} = $node;
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster system data [JSON-OBJ]
#
sub api_cdb_local_service_del($socket, $service, $node){
	my $fid = "[api_cdb_local_service_del]";
	my $packet = api_proto_packet_build("cdb", "obj_del");
	$packet->{'cdb'}{'obj'} = "service";
	$packet->{'cdb'}{'key'} = $service;
	$packet->{'cdb'}{'id'} = $node;
	return api_socket_send($socket, $packet, $fid);
}

1;
