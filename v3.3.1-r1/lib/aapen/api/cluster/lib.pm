#
# ETHER|AAPEN|LIBS - API|CLUSTER|LIB
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
use JSON::MaybeXS;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# ping cluster service [JSON-OBJ]
#
sub api_cluster_ping($node){
	my $fid = "[api_cluster_ping]";
	my $packet = api_proto_packet_build("cluster", "ping");
	return api_proto_ssl_send($node, $packet, $fid);
}

#
# get cluster metadata [JSON-OBJ]
#
sub api_cluster_meta_get($node){
	my $fid = "[api_cluster_meta]";
	my $packet = api_proto_packet_build("cluster", "meta_get");
	return api_proto_ssl_send($node, $packet, $fid);
}

#
# get cluster database [JSON-OBJ]
#
sub api_cluster_db_get($node){
	my $fid = "[api_stor_ping]";
	my $packet = api_proto_packet_build("cluster", "db_get");
	return api_proto_ssl_send($node, $packet, $fid);	
}

#
# get object from cluster [JSON-OBJ]
#
sub api_cluster_obj_get($node, $req){
	my $fid = "[api_cluster_obj_get]";
	my $packet = api_proto_packet_build("cluster", "obj_get");
	$packet->{'cluster'} = $req;
	$packet->{'cluster'}{'req'} = "obj_get";
	return api_proto_ssl_send($node, $packet, $fid);
}

#
# get all objects from cluster [JSON-OBJ]
#
sub api_cluster_obj_get_all($node, $req){
	my $fid = "[api_cluster_obj_get_all]";
	my $packet = api_proto_packet_build("cluster", "obj_get_all");
	$packet->{'request'} = $req;
	$packet->{'cluster'}{'obj'} = $req->{'obj'};
	return api_proto_ssl_send($node, $packet, $fid);
}

#
# get all objects from cluster [JSON-OBJ]
#
sub api_cluster_service_get($node, $req){
	my $fid = "[api_cluster_service_get]";
	my $packet = api_proto_packet_build("cluster", "obj_get");
	$packet->{'request'} = $req;
	$packet->{'cluster'}{'obj'} = $req->{'obj'};
	$packet->{'cluster'}{'key'} = $req->{'key'};
	$packet->{'cluster'}{'id'} = $req->{'node'};
	return api_proto_ssl_send($node, $packet, $fid);
}

1;
