#
# ETHER|AAPEN|CLI - LIB|CLUSTER
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
# ping local cluster [NULL]
#
sub cluster_local_ping(){
	my $fid = "[cluster_local_ping]";
	my $ffid = "LOCAL:CLUSTER|PING";
	my $result = api_cluster_local_ping(env_serv_sock_get("cluster"));
	api_rest_response_print($ffid, $result, "cluster ping");
}

#
# get local cluster metadata [NULL]
#
sub cluster_local_meta_get($object){
	my $fid = "[cluster_local_meta_get]";
	my $ffid = "LOCAL:CLUSTER|META|GET";
	my $meta;
	
	my $result = api_cluster_local_meta_get(env_serv_sock_get("cluster"));
	
	if($object ne "all"){
		print "$fid object [$object] metadata\n";
		$meta = $result->{'meta'}{$object};
		api_rest_response_print($ffid, $result->{'meta'}{$object}, "cluster metadata");
	}
	else{
		api_rest_response_print($ffid, $result, "cluster metadata object [$object]");
		$meta = $result;
	}
	
	return $meta;
}

#
# get object from local cluster [NULL]
#
sub cluster_local_obj_get($object, $key){
	my $fid = "[cluster_local_obj_get]";
	my $ffid = "LOCAL:CLUSTER|OBJ|GET";
	
	my $result = api_cluster_local_obj_get(env_serv_sock_get("cluster"), $object, $key);
	api_rest_response_print($ffid, $result, "cluster object [$object] key [$key]");
}

#
# get all objects of type from local cluster [NULL]
#
sub cluster_local_obj_get_all($object){
	my $fid = "[cluster_local_obj_get_all]";
	my $ffid = "LOCAL:CLUSTER|OBJ|GET|ALL";
	
	my $result = api_cluster_local_obj_get_all(env_serv_sock_get("cluster"), $object);
	api_rest_response_print($ffid, $result, "cluster get all");
}

#
# get full db from local cluster [NULL]
#
sub cluster_local_db_get(){
	my $fid = "[cluster_local_db_get]";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	api_rest_response_print($fid, $result, "cluster db get");
}

#
# delete object from local cluster [NULL]
#
sub cluster_local_obj_del($object, $key){
	my $fid = "[cluster_local_obj_del]";
	my $ffid = "LOCAL:CLUSTER|OBJ|DEL";
	
	my $result = api_cluster_local_obj_del(env_serv_sock_get("cluster"), $object, $key);
	api_rest_response_print($ffid, $result, "cluster object [$object] key [$key] del");
}

#
# local cluster system set [NULL]
#
sub cluster_local_system_set($system){
	my $fid = "[cluster_local_system_set]";
	my $ffid = "LOCAL:CLUSTER|SYSTEM|SET";
	
	my $sysdata = system_rest_get($system);
	
	if($sysdata->{'proto'}{'result'} eq "1"){
		my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $sysdata->{'response'}{'system'});
		api_rest_response_print($ffid, $result, "cluster system set [$system]");
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $sysdata, "cluster system set. request failed");
	}
}

#
# local cluster system del [NULL]
#
sub cluster_local_system_del($system){
	my $fid = "[cluster_local_system_del]";
	my $ffid = "LOCAL:CLUSTER|SYSTEM|DEL";
	
	my $sysdata = system_rest_get($system);
	$sysdata->{'response'}{'system'}{'object'}{'delete'} = "1";
	
	if($sysdata->{'proto'}{'result'} eq "1"){
		my $result = api_cluster_local_system_del(env_serv_sock_get("cluster"), $sysdata->{'response'}{'system'});
		api_rest_response_print($ffid, $result, "cluster system del [$system]");
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $sysdata, "cluster system del [$system]. failed");
	}
}

#
# local cluster network set [NULL]
#
sub cluster_local_net_set($net){
	my $fid = "[cluster_local_net_set]";
	my $ffid = "LOCAL:CLUSTER|NET|SET";
	
	my $netdata = network_rest_get($net);
	
	if($netdata->{'proto'}{'result'} eq "1"){
		my $result = api_cluster_local_net_set(env_serv_sock_get("cluster"), $netdata->{'response'}{'network'});
		api_rest_response_print($ffid, $result, "cluster network set [$net]");
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $netdata, "cluster network set [$net]. request failed");
	}
}

#
# local cluster network del [NULL]
#
sub cluster_local_net_del($network){
	my $fid = "[cluster_local_net_del]";
	my $ffid = "LOCAL:CLUSTER|NET|DEL";
	
	my $netdata = network_rest_get($network);
	$netdata->{'response'}{'network'}{'object'}{'delete'} = "1";
	
	if($netdata->{'proto'}{'result'} eq "1"){
		my $result = api_cluster_local_net_set(env_serv_sock_get("cluster"), $netdata->{'response'}{'network'});
		api_rest_response_print($ffid, $result, "cluster network delete [$network]");
		delete $netdata->{'response'}{'netdata'}{'object'}{'delete'};
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $netdata, "cluster network delete [$network]. request failed");
	}
}

#
# local cluster node set [NULL]
#
sub cluster_local_node_set($node){
	my $fid = "[cluster_local_node_set]";
	my $ffid = "LOCAL:CLUSTER|NODE|SET";
	
	my $nodedata = node_rest_get($node);
	
	if($nodedata->{'proto'}{'result'} eq "1"){
		my $result = api_cluster_local_node_set(env_serv_sock_get("cluster"), $nodedata->{'response'}{'node'});
		api_rest_response_print($ffid, $result, "cluster node set [$node]");
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $nodedata, "cluster node set [$node], request failed");
	}
}

#
# local cluster node del [NULL]
#
sub cluster_local_node_del($node){
	my $fid = "[cluster_local_node_del]";
	my $ffid = "LOCAL:CLUSTER|NODE|DEL";

	my $nodedata = node_rest_get($node);
	$nodedata->{'response'}{'nodedata'}{'object'}{'delete'} = "1";
	
	if($nodedata->{'proto'}{'result'} eq "1"){
		my $result = api_cluster_local_node_set(env_serv_sock_get("cluster"), $nodedata->{'response'}{'node'});
		api_rest_response_print($ffid, $result, "cluster node del [$node]");
		delete $nodedata->{'response'}{'nodedata'}{'object'}{'delete'};
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $nodedata, "cluster node del [$node]. request failed");
	}
}

#
# local cluster storage set [NULL]
#
sub cluster_local_stor_set($type, $stor){
	my $fid = "[cluster_local_stor_set]";
	my $ffid = "LOCAL:CLUSTER|STOR|SET";

	my $stordata = storage_rest_get($stor);
	
	if($stordata->{'proto'}{'result'} eq "1"){
		
		if($type eq "device"){
			my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $stordata->{'response'}{'storage'});
			api_rest_response_print($ffid, $result, "cluster storage set [$stor]");
		}
		elsif($type eq "iso"){
			my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $stordata->{'response'}{'storage'});
			api_rest_response_print($ffid, $result, "cluster storage set [$stor]");
		}
		elsif($type eq "pool"){
			my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $stordata->{'response'}{'storage'});
			api_rest_response_print($ffid, $result, "cluster storage set [$stor]");
		}
		else{
			print "$fid uknown storage type [$type]\n";
		}
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $stordata, "cluster storage set [$stor]. request failed");
	}
}

#
# local cluster storage del [NULL]
#
sub cluster_local_stor_del($type, $stor){
	my $fid = "[cluster_local_stor_del]";
	my $ffid = "LOCAL:CLUSTER|STOR|DEL";
	
	my $stordata = storage_rest_get($stor);
		
	if($stordata->{'proto'}{'result'} eq "1"){
		
		if($type eq "device"){
			$stordata->{'response'}{'stordata'}{'object'}{'delete'} = "1";
			json_encode_pretty($stordata);
			
			my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $stordata->{'response'}{'storage'});
			api_rest_response_print($ffid, $result, "cluster storage del [$stor]");
			delete $stordata->{'response'}{'stordata'}{'object'}{'delete'}
		}
		elsif($type eq "iso"){
			$stordata->{'response'}{'isodata'}{'object'}{'delete'} = "1";
			json_encode_pretty($stordata);
			
			my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $stordata->{'response'}{'storage'});
			api_rest_response_print($ffid, $result, "cluster storage del [$stor]");
			delete $stordata->{'response'}{'isodata'}{'object'}{'delete'}
		}
		elsif($type eq "pool"){
			$stordata->{'response'}{'pooldata'}{'object'}{'delete'} = "1";
			json_encode_pretty($stordata);
			
			my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $stordata->{'response'}{'storage'});
			api_rest_response_print($ffid, $result, "cluster storage del [$stor]");
			delete $stordata->{'response'}{'pooldata'}{'object'}{'delete'}
		}
		else{
			print "$fid uknown storage type [$type]\n";
		}

	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($ffid, $stordata, "cluster storage del [$stor]. request failed");
	}
}

#
# local cluster service get [NULL]
#
sub cluster_local_service_get($service, $node){
	my $fid = "[cluster_local_service_get]";
	my $ffid = "LOCAL:CLUSTER|SERVICE|GET";
	
	print "service [$service] node [$node]\n";	
	my $result = api_cluster_local_service_get(env_serv_sock_get("cluster"), $service, $node);
	api_rest_response_print($ffid, $result, "cluster service [$service] node [$node] get");
}

#
# local cluster service del [NULL]
#
sub cluster_local_service_del($service, $node){
	my $fid = "[cluster_local_service_del]";
	my $ffid = "LOCAL:CLUSTER|SERVICE|DEL";
	
	my $result = api_cluster_local_service_get(env_serv_sock_get("cluster"), $service, $node);
	
	if($result->{'proto'}{'result'} eq "1"){		
		my $service = $result->{'service'}{$service}{$node};
		$service->{'object'}{'delete'} = "1";
		
		my $response = api_cluster_local_service_set(env_serv_sock_get("cluster"), $service);
		api_rest_response_print($ffid, $response, "cluster service del. service [$service] node [$node]");
	}
	else{
		print "$fid request failed\n";
		api_rest_response_print($ffid, $result, "cluster service [$service] node [$node] del: request failed");
	}
}

#
# local cluster service get [NULL]
#
sub cluster_local_service_node_get($service, $node){
	my $fid = "[cluster_local_node_get]";
	my $ffid = "LOCAL:CLUSTER|NODE|GET";
	
	my $result = api_cluster_local_service_get(env_serv_sock_get("cluster"), $service, $node);
	api_rest_response_print($ffid, $result, "cluster service get. service [$service] node [$node]");
}

#################
# NODE COMMANDS #
#################

#
# get object metadata from cluster on node [NULL]
#
sub cluster_node_obj_meta($object_type, $node_name){
	my $fid = "[cluster_node_obj_meta]";
	my $ffid = "NODE:CLUSTER|OBJ|META";
	
	my $result = rest_get_request("/service/cluster/meta?name=" . $node_name);
	api_rest_response_print($ffid, $result->{'meta'}{$object_type}, "node cluster object meta [$node_name]");
}

#
# get object from cluster on node [NULL]
#
sub cluster_node_obj_get($object_type, $node_name, $object_name){
	my $fid = "[cluster_node_obj_get]";
	node_rest_cluster_object_get($node_name, $object_type, $object_name);
}

#
#
#
sub cluster_node_service_get($service_name, $node_name, $service_node){
	my $fid = "[cluster_node_service_get]";
	node_rest_cluster_service_get($node_name, $service_name, $service_node);
}

#
# get object metadata from cluster on node [NULL]
#
sub cluster_node_service_meta($service_type, $node_name){
	my $fid = "[cluster_node_service_meta]";
	my $ffid = "NODE:CLUSTER|OBJ|META";
	
	my $result = rest_get_request("/service/cluster/meta?name=" . $node_name);
	api_rest_response_print($ffid, $result->{'meta'}{'service'}{$service_type}, "cluster service metadata");
}

#
# cluster object state helper
#
sub cluster_obj_state($obj){
	
	if(defined $obj->{'object'}{'meta'}{'ver'}){
		print " ver [", BOLD BLACK,  $obj->{'object'}{'meta'}{'ver'}, RESET, "] - [" . BOLD BLUE, "CLUSTER" . RESET . "]";
	}
	else{
		print " - ", BOLD, "LOCAL", RESET;
	}	
	
}

#
# cluster environment sent
#
sub cluster_local_env_set($envflag){
	my $fid = "[cluster_local_env_set]";
	
	my $result = api_cluster_local_env_set(env_serv_sock_get("cluster"), $envflag);
	api_rest_response_print($fid, $result, "cluster env set");
}

#
# local cluster node set [NULL]
#
sub cluster_local_element_set($type, $key){
	my $fid = "[cluster_local_element_set]";
	
	my $element = element_get($type, $key);
	
	if($element->{'proto'}{'result'} eq "1"){
		my $result = api_cluster_local_element_set(env_serv_sock_get("cluster"), $element->{'response'}{'element'});
		api_rest_response_print($fid, $result, "cluster element set");
	}
	else{
		print "$fid request failed!\n";
		api_rest_response_print($fid, $element, "cluster element set failed");
	}
}

#
# local cluster node set [NULL]
#
sub cluster_local_panic_down(){
	my $fid = "[cluster_local_panic_down]";
	my $ffid = "CLUSTER|PANIC|DESTROY";

	log_warn($ffid, "PANIC: ---- WARNING: CLUSTER DESTROY --- FULLL PANIC MODE ---");
	log_error($ffid, "ERROR: ---- PANIC MODE --- THIS WILL DESTROY THE CLUSTER ---");
	
	if(cli_verify("PANIC")){
		print "PANIC MODE: DESTROYING THE CLUSTER\n!";
		
		# fetch the cluster
		
		
	}
	else{
		print "\nPANIC MODE: ABORT!!\n!";
	}

}

#
# local cluster node set [NULL]
#
sub cluster_local_panic_graceful(){
	my $fid = "[cluster_local_panic_graceful]";
	my $ffid = "CLUSSTER|PANIC|DESTROY";

	log_warn($ffid, "PANIC: ---- WARNING: CLUSTER SHUTDOWN --- GRACEFUL PANIC MODE ---");
	log_error($ffid, "ERROR: ---- GRACEFUL PANIC MODE --- THIS WILL GRACEFULLY TERMINATE THE CLUSTER ---");
	
	if(cli_verify("PANIC")){
		print "PANIC MODE: DESTROYING THE CLUSTER\n!";
		
		# fetch the cluster
		
	}
	else{
		print "\nPANIC MODE: ABORT!!\n!";
	}

}

1;
