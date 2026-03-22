#
# ETHER|AAPEN|LIBS - API|CLUSTER|LOCAL
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
sub api_cluster_local_ping($socket){
	my $fid = "[api_cluster_local_ping]";	
	my $packet = api_proto_packet_build("cluster", "ping");	
	return api_socket_send($socket, $packet, $fid);
}

#
# get local cluster db [JSON-OBJ]
#
sub api_cluster_local_db_get($socket){
	my $fid = "[api_cluster_local_db_get]";	
	my $packet = api_proto_packet_build("cluster", "db_get");
	return api_socket_send($socket, $packet, $fid);
}

#
# get local cluster metadata [JSON-OBJ]
#
sub api_cluster_local_meta_get($socket){
	my $fid = "[api_cluster_local_meta_get]";
	my $packet = api_proto_packet_build("cluster", "meta_get");
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster object data [JSON-OBJ]
#
sub api_cluster_local_obj_set($socket, $data){
	my $fid = "[api_cluster_local_obj_set]";
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = $data->{'cluster'}{'obj'};
	$packet->{'cluster'}{'key'} = $data->{'cluster'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# get cluster object data [JSON-OBJ]
#
sub api_cluster_local_obj_get($socket, $object, $key){
	my $fid = "[api_cluster_local_obj_get]";
	my $packet = api_proto_packet_build("cluster", "obj_get");
	$packet->{'cluster'}{'obj'} = $object;
	$packet->{'cluster'}{'key'} = $key;
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster object data [JSON-OBJ]
#
sub api_cluster_local_obj_get_all($socket, $object){
	my $fid = "[api_cluster_local_obj_get_all]";
	my $packet = api_proto_packet_build("cluster", "obj_get_all");
	$packet->{'cluster'}{'obj'} = $object;
	return api_socket_send($socket, $packet, $fid);
}

#
# mark object for delete data [JSON-OBJ]
#
sub api_cluster_local_obj_del($socket, $object, $key){
	my $fid = "[api_cluster_local_obj_del]";
	my $packet = api_proto_packet_build("cluster", "obj_del");
	$packet->{'cluster'}{'obj'} = $object;
	$packet->{'cluster'}{'key'} = $key;
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster system data [JSON-OBJ]
#
sub api_cluster_local_system_set($socket, $data){
	my $fid = "[api_cluster_local_system_set]";
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = "system";
	$packet->{'cluster'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cluster'}{'id'} = $data->{'id'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster system data [JSON-OBJ]
#
sub api_cluster_local_system_del($socket, $data){
	my $fid = "[api_cluster_local_system_del]";
	my $packet = api_proto_packet_build("cluster", "obj_del");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = "system";
	$packet->{'cluster'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cluster'}{'id'} = $data->{'id'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster node data [JSON-OBJ]
#
sub api_cluster_local_node_set($socket, $data){
	my $fid = "[api_cluster_local_node_set]";
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = "node";
	$packet->{'cluster'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cluster'}{'id'} = $data->{'id'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster network data [JSON-OBJ]
#
sub api_cluster_local_net_set($socket, $data){
	my $fid = "[api_cluster_local_net_set]";
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = "network";
	$packet->{'cluster'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cluster'}{'id'} = $data->{'id'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster network data [JSON-OBJ]
#
sub api_cluster_local_stor_set($socket, $data){
	my $fid = "[api_cluster_local_stor_set]";
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = "storage";
	$packet->{'cluster'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cluster'}{'id'} = $data->{'id'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster node data [JSON-OBJ]
#
sub api_cluster_local_element_set($socket, $data){
	my $fid = "[api_cluster_local_element_set]";
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = "element";
	$packet->{'cluster'}{'key'} = $data->{'id'}{'name'};
	$packet->{'cluster'}{'id'} = $data->{'id'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster service data [JSON-OBJ]
#
sub api_cluster_local_service_set($socket, $data){
	my $fid = "[api_cluster_local_service_set]";
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $data;
	$packet->{'cluster'}{'obj'} = "service";
	$packet->{'cluster'}{'key'} = $data->{'config'}{'name'};
	$packet->{'cluster'}{'id'} = $data->{'config'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster service data [JSON-OBJ]
#
sub api_cluster_local_service_get($socket, $service, $node){
	my $fid = "[api_cluster_local_service_get]";
	my $packet = api_proto_packet_build("cluster", "obj_get");
	$packet->{'cluster'}{'obj'} = "service";
	$packet->{'cluster'}{'key'} = $service;
	$packet->{'cluster'}{'id'} = $node;
	return api_socket_send($socket, $packet, $fid);
}

#
# set cluster node data [JSON-OBJ]
#
sub api_cluster_local_obj_meta_set($socket, $data){
	my $fid = "[api_cluster_local_obj_meta_set]";
	my $packet = api_proto_packet_build("cluster", "obj_meta_set");
	$packet->{'data'} = $data->{'data'};
	$packet->{'cluster'}{'obj'} = $data->{'cluster'}{'obj'};
	$packet->{'cluster'}{'key'} = $data->{'cluster'}{'key'};
	$packet->{'cluster'}{'id'} = $data->{'cluster'}{'id'};
	return api_socket_send($socket, $packet, $fid);
}

#
# ping local cluster [JSON-OBJ]
#
sub api_cluster_local_env_set($socket, $envflag){
	my $fid = "[api_cluster_local_env_set]";	
	my $packet = api_proto_packet_build("cluster", "env_update");
	$packet->{'cluster'}{'env'} = $envflag;
	return api_socket_send($socket, $packet, $fid);
}

1;
