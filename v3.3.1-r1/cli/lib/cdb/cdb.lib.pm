#
# ETHER|AAPEN|CLI - LIB|CDB
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
# ping agent [NULL]
#
sub cdb_local_ping(){
	my $fid = "[cdb_local_ping]";
	my $result = api_cdb_local_ping(env_serv_sock_get("cdb"));
	api_rest_response_print($fid, $result, "cdb ping");
}

#
# get metadata [JSON-OBJ]
#
sub cdb_local_meta_get($object){
	my $fid = "[cdb_local_meta_get]";
	my $meta;
	
	my $result = api_cdb_local_meta_get(env_serv_sock_get("cdb"));
	
	if($object ne "all"){
		$meta = $result->{'meta'}{$object};
		api_rest_response_print($fid, $result->{'meta'}{$object}, "object [$object] metadata");		
	}
	else{
		api_rest_response_print($fid, $result, "object [$object] metadata");
		$meta = $result;
	}
	
	return $meta;
}

#
# get metadata [NULL]
#
sub cdb_local_db_flush(){
	my $fid = "[cdb_local_db_flush]";
	my $result = api_cdb_local_db_flush(env_serv_sock_get("cdb"));
	api_rest_response_print($fid, $result, "cdb flush");
}

#
# get metadata [JSON-OBJ]
#
sub cdb_local_meta_list($object){
	my $fid = "[local_cdb_meta_list]";
	my $meta;
	
	my $result = api_cdb_local_meta_get(env_serv_sock_get("cdb"));
	
	if($object ne "all"){
		print "$fid object [$object] metadata\n";
		$meta = $result->{'meta'}{$object};
		
		my @index = index_split($result->{'meta'}{$object}{'index'});
		
		foreach my $obj (@index){
			my $diff = date_str_diff_now($result->{'meta'}{$object}{'meta'}{$obj}{'date'});
			print " object [", BOLD, $object, RESET, "] name [", BOLD BLUE, $obj, RESET, "] updated [", BOLD BLACK, $result->{'meta'}{$object}{'meta'}{$obj}{'date'}, RESET, "] ver [", BOLD, $result->{'meta'}{$object}{'meta'}{$obj}{'ver'}, RESET, "] delta [", BOLD BLACK, $diff, RESET, "]\n";
		}
	}
	else{
		api_rest_response_print($fid, $result, "object [$object] metadata");
		$meta = $result;
	}
	
	return $meta;
}

#
# get full cdb [NULL]
#
sub cdb_local_db_get(){
	my $fid = "[cdb_local_db_get]";
	my $result = api_cdb_local_db_get(env_serv_sock_get("cdb"));
	api_rest_response_print($fid, $result, "cdb db get");
}

#
# get object from cdb [NULL]
#
sub cdb_local_obj_get($object, $key){
	my $fid = "[cdb_local_obj_get]";	
	my $result = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);
	api_rest_response_print($fid, $result, "object [$object] key [$key]");
}


#
# set system to cdb [NULL]
#
sub cdb_local_system_set($system){
	my $fid = "[local_cdb_system_set]";
	my $sysdata = system_rest_get($system);

	if($sysdata->{'proto'}{'result'} eq "1"){
		my $result = api_cdb_obj_set(env_serv_sock_get("cdb"), "system", $sysdata->{'response'}{'system'});
		api_rest_response_print($fid, $sysdata, "cdb system [$system] set");
	}
	else{
		api_rest_response_print($fid, $sysdata, "cdb system [$system] set failed");
	}
}

#
# remove system from cdb [NULL]
#
sub cdb_local_system_del($system){
	my $fid = "[cdb_local_system_del]";
	my $sysdata = system_rest_get($system);
	
	if($sysdata->{'proto'}{'result'} eq "1"){
		my $result = api_cdb_local_obj_del(env_serv_sock_get("cdb"), "system", $sysdata->{'response'}{'system'});
		api_rest_response_print($fid, $result, "cdb system [$system] del");
	}
	else{
		api_rest_response_print($fid, $sysdata, "cdb system [$system] del failed");
	}
}

#
# set node to cdb [NULL]
#
sub cdb_local_node_set($node){
	my $fid = "[cdb_local_node_set]";
	my $nodedata = node_rest_get($node);

	if($nodedata->{'proto'}{'result'} eq "1"){
		my $result = api_cdb_obj_set(env_serv_sock_get("cdb"), "node", $nodedata->{'response'}{'node'});
		api_rest_response_print($fid, $result, "cdb node [$node] set failed");
	}
	else{
		api_rest_response_print($fid, $nodedata, "cdb node [$node] set failed");
	}
}

#
# remove node from cdb [NULL]
#
sub cdb_local_node_del($node){
	my $fid = "[cdb_local_node_del]";
	my $nodedata = node_rest_get($node);

	if($nodedata->{'proto'}{'result'} eq "1"){
		my $result = api_cdb_local_obj_del(env_serv_sock_get("cdb"), "node", $nodedata->{'response'}{'node'});
		api_rest_response_print($fid, $result, "cdb node [$node] del");
	}
	else{
		api_rest_response_print($fid, $nodedata, "cdb node [$node] del failed");
	}
}

#
# set network to cdb [NULL]
#
sub cdb_local_net_set($net){
	my $fid = "[cdb_local_net_set]";
	my $netdata = network_rest_get($net);
	
	if($netdata->{'proto'}{'result'} eq "1"){
		my $result = api_cdb_obj_set(env_serv_sock_get("cdb"), "network", $netdata->{'response'}{'network'});
		api_rest_response_print($fid, $result, "cdb network [$net] set failed");
		
	}
	else{
		api_rest_response_print($fid, $netdata, "cdb network [$net] set failed");
	}
}

#
# remove network from cdb [NULL]
#
sub cdb_local_net_del($net){
	my $fid = "[cdb_local_net_del]";
	my $netdata = network_rest_get($net);
	
	if($netdata->{'proto'}{'result'} eq "1"){
		my $result = api_cdb_local_obj_del(env_serv_sock_get("cdb"), "network", $netdata->{'response'}{'network'});
		api_rest_response_print($fid, $result, "cdb network [$net] del failed");
	}
	else{
		api_rest_response_print($fid, $netdata, "cdb network [$net] del failed");
	}
}

#
# get service from cdb [NULL]
#
sub cdb_local_service_get($service, $node){
	my $fid = "[cdb_local_service_get]";
	my $result = api_cdb_local_service_get(env_serv_sock_get("cdb"), $service, $node);
	api_rest_response_print($fid, $result, "service [$service] node [$node]");
}

#
# get service metadata from cdb [NULL]
#
sub cdb_local_service_meta($object){
	my $fid = "[cdb_local_service_meta]";
	my $meta;
	
	my $result = api_cdb_local_meta_get(env_serv_sock_get("cdb"));
	
	if($object ne "all"){
		$meta = $result->{'meta'}{'service'}{$object};
		api_rest_response_print($fid, $meta, "service [$object] metadata");
	}
	else{
		api_rest_response_print($fid, $result, "service [$object] metadata");
		$meta = $result;
	}
	
	return $meta;
}

#
# list service metadata [NULL]
#
sub cdb_local_service_meta_list($object){
	my $fid = "[cdb_local_service_meta_list]";
	my $meta;
	
	my $result = api_cdb_local_meta_get(env_serv_sock_get("cdb"));
	
	if($object ne "all"){
		$meta = $result->{'meta'}{'service'}{$object};
		my @index = index_split($result->{'meta'}{'service'}{$object}{'index'});
		
		foreach my $obj (@index){
			my $diff = date_str_diff_now($result->{'meta'}{'service'}{$object}{'meta'}{$obj}{'date'});
			print " service [", BOLD, $object, RESET, "] node [", BOLD BLUE, $obj, RESET, "] updated [", BOLD BLACK, $result->{'meta'}{'service'}{$object}{'meta'}{$obj}{'date'}, RESET, "] ver [", BOLD, $result->{'meta'}{'service'}{$object}{'meta'}{$obj}{'ver'}, RESET, "] delta [", BOLD BLACK, $diff, RESET, "]\n";
		}
	}
	else{
		api_rest_response_print($fid, $result, "service [$object] metadata");
		$meta = $result;
	}
	
	return $meta;
}

#
# remove service from cdb [NULL]
#
sub cdb_local_service_del($service, $node){
	my $fid = "[cdb_local_service_del]";
	my $result = api_cdb_local_service_del(env_serv_sock_get("cdb"), $service, $node);
	api_rest_response_print($fid, $result, "service [$service] node [$node]");
}

#
# update cluster environment [NULL]
#
sub cdb_local_env_set($envflag){
	my $fid = "[cdb_local_env_set]";
	my $result = api_cdb_local_env_set(env_serv_sock_get("cdb"), $envflag);
	api_rest_response_print($fid, $result, "cdb env set");
}

1;
