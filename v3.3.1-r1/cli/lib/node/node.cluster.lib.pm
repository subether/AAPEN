#
# ETHER|AAPEN|CLI - LIB|NODE|FRAMEWORK
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
use JSON::MaybeXS;

#
# ping cluster service on node [JSON-OBJ]
#
sub node_rest_cluster_ping($node_name){
	my $fid = "node_rest_cluster_ping";
	my $ffid = "NODE|CLUSTER|PING";
	my $result = rest_get_request("/service/cluster/ping?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node cluster ping");
}

#
# get cluster metadata from node [JSON-OBJ]
#
sub node_rest_cluster_meta($node_name){
	my $fid = "node_rest_cluster_meta";
	my $ffid = "NODE|CLUSTER|META";
	my $result = rest_get_request("/service/cluster/meta?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node cluster meta");
}

#
# get cluster db from node [JSON-OBJ]
#
sub node_rest_cluster_db($node_name){
	my $fid = "node_rest_cluster_db";
	my $ffid = "NODE|CLUSTER|DB";
	my $result = rest_get_request("/service/cluster/db?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node cluster db");
}

#
# get object from cluster on node [JSON-OBJ]
#
sub node_rest_cluster_object_get($node_name, $object_type, $object_name){
	my $fid = "node_rest_cluster_obj_get";
	my $ffid = "NODE|CLUSTER|OBJ|GET";
	my $result = rest_get_request("/service/cluster/object/get?name=" . $node_name . "&obj_type=" . $object_type . "&obj_name=" . $object_name);
	api_rest_response_print($ffid, $result, "node cluster db");
}

#
# get service from cluster on node [JSON-OBJ]
#
sub node_rest_cluster_service_get($node_name, $service_name, $service_node){
	my $fid = "node_rest_cluster_srv_get";
	my $ffid = "NODE|CLUSTER|SERVICE|GET";
	my $result = rest_get_request("/service/cluster/service/get?name=" . $node_name . "&obj_type=service"  . "&srv_name=" . $service_name . "&srv_node=" . $service_node);
	api_rest_response_print($ffid, $result, "node cluster db");
}

1;
