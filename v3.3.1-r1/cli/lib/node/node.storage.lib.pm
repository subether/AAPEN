#
# ETHER|AAPEN|CLI - LIB|NODE|STORAGE
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
# ping storage service on node [NULL]
#
sub node_rest_storage_ping($node_name){
	my $fid = "node_rest_storage_ping";
	my $ffid = "NODE|STORAGE|PING";
	my $result = rest_get_request("/service/storage/ping?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node storage ping");
}

#
# get storage meta for node [NULL]
#
sub node_rest_storage_meta($node_name){
	my $fid = "node_rest_storage_meta";
	my $ffid = "NODE|STORAGE|META";
	my $result = rest_get_request("/service/storage/meta?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node storage meta");
}

#
# set storage pool on node [NULL]
#
sub node_rest_storage_pool_set($node_name, $pool_name){
	my $fid = "node_rest_storage_pool_set";
	my $ffid = "NODE|STORAGE|POOL|SET";
	my $result = rest_get_request("/service/storage/pool/set?name=" . $node_name . "&pool=" . $pool_name);
	api_rest_response_print($ffid, $result, "node storage pool set");
}

#
# get storage pool from node [NULL]
#
sub node_rest_storage_pool_get($node_name, $pool_name){
	my $fid = "node_rest_storage_pool_get";
	my $ffid = "NODE|STORAGE|POOL|GET";
	my $result = rest_get_request("/service/storage/pool/get?name=" . $node_name . "&pool=" . $pool_name);
	api_rest_response_print($ffid, $result, "node storage pool get");
}

#
# get storage device from node [NULL]
#
sub node_rest_storage_device_get($node_name, $device_name){
	my $fid = "node_rest_storage_device_get";
	my $ffid = "NODE|STORAGE|DEVICE|GET";
	my $result = rest_get_request("/service/storage/device/get?name=" . $node_name . "&device=" . $device_name);
	api_rest_response_print($ffid, $result, "node storage device get");
}

#
# get node storage info [JSON-OBJ]
#
sub node_storage_info_get($nodeid, $dev){
	my $packet = api_packet_build("node_stor_dev_get", $dev, $dev, $nodeid);
	return api_send($packet)
}

#
# print node storage info [NULL]
#
sub node_storage_info($nodeid, $dev){
	my $fid = "node_storage_info";
	my $ffid = "NODE|STORAGE|INFO";
	my $result = node_storage_info_get($nodeid, $dev);
	api_rest_response_print($ffid, $result, "node storage info");	
}


1;
