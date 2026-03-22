#
# ETHER - AAPEN - STORAGE - CLUSTER LIB
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


#
# sync with cluster [NULL]
#
sub storage_cdb_sync(){
	my $fid = "[storage_cdb_sync]";
	my $ffid = "CLUSTER|SYNC";
	
	# device
	device_stats();

	# pools
	storage_pool_stats();
	
	# objects
	storage_cdb_service_sync();
	storage_cdb_pool_publish();
	storage_cdb_device_publish();
	
	# metadata
	storage_cdb_meta_sync();
}

#
# gather device stats [NULL]
#
sub storage_cdb_device_publish(){
	my $fid = "[storage_cdb_device_publish]";
	my $ffid = "CLUSTER|DEVICE|PUBLISH";
	my $devdb = storage_db_obj_get("device");
	my @dev_index = index_split($devdb->{'index'});
	
	foreach my $device (@dev_index){
		log_info($ffid, "publishing device [$device]");
		my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $devdb->{'data'}{$device});
	}
}

#
# gather device stats [NULL]
#
sub storage_cdb_pool_publish(){
	my $fid = "[storage_cdb_pool_publish]";
	my $ffid = "CLUSTER|POOL|PUBLISH";
	my $pooldb = storage_db_obj_get("pool");
	my @pool_index = index_split($pooldb->{'index'});
	
	# process pools
	foreach my $pool (@pool_index){
		
		# check if pool is known
		if($pooldb->{'data'}{$pool}{'owner'}{'name'} eq config_node_id_get()){
			log_info($ffid, "publishing pool [$pool]");
			my $result = api_cluster_local_stor_set(env_serv_sock_get("cluster"), $pooldb->{'data'}{$pool});
		}
		else{
			log_debug($ffid, "unknown pool [$pool]. ingnoring.");
		}
	}
}

#
# check network status [NULL]
#
sub storage_cdb_meta_sync(){
	my $fid = "[storage_cdb_meta_sync]";
	my $ffid = "CLUSTER|META|SYNC";
	my $status = 0;
	my $db = storage_db_get();
	my $nodeid = config_node_id_get();
	
	# fetch meta and build index
	my $stormeta = api_cluster_local_meta_get(env_serv_sock_get("cluster"));
	my @stor_index = index_split($stormeta->{'meta'}{'storage'}{'index'});

	log_debug($fid, "cluster storage index [$stormeta->{'meta'}{'storage'}{'index'}]");
	log_debug($fid, "local device index [$db->{'device'}{'index'}]");
	log_debug($fid, "local pool index [$db->{'pool'}{'index'}]");

	# process storage
	foreach my $stor (@stor_index){

		# check for device or pool
		if(index_find($db->{'device'}{'index'}, $stor)){
			# device
			log_debug($ffid, "device [$stor] known. updating meta..");
			storage_cdb_meta_set($stor, $db->{'device'}{'data'}{$stor}{'meta'});
		}
		elsif(index_find($db->{'pool'}{'index'}, $stor)){
			# pool
			log_debug($ffid, "pool [$stor] known. updating meta..");
			storage_cdb_meta_set($stor, $db->{'pool'}{'meta'}{$stor});
		}
		else{
			log_debug($ffid, "storage [$stor] unknown.");
		}
	}
}

#
# sync with cdb [NULL]
#
sub storage_cdb_service_sync(){
	my $fid = "[storage_cdb_meta_sync]";
	my $ffid = "CLUSTER|SERVICE|SYNC";
	my $db = storage_db_get();
	my $meta = {};
	
	# config
	$meta->{'updated'} = date_get();
	$meta->{'config'} = $db->{'config'};
	$meta->{'config'}{'service'} = "storage";
	$meta->{'device'} = $db->{'device'};
	$meta->{'pool'} = $db->{'pool'};
	
	my $result = api_cluster_local_service_set(env_serv_sock_get("cluster"), $meta);
	if(env_debug()){ json_encode_pretty($result); };
}

#
# set network metadata [NULL]
#
sub storage_cdb_meta_set($stordev, $meta){
	my $fid = "[storage_cdb_meta_set]";
	my $ffid = "CLUSTER|META|SET";
	
	my $packet;
	$packet->{'cluster'}{'obj'} = "storage";
	$packet->{'cluster'}{'key'} = $stordev;
	$packet->{'cluster'}{'id'} = config_node_name_get();
	$meta->{'updated'} = date_get();
	$packet->{'data'} = $meta;
	
	my $result = api_cluster_local_obj_meta_set(env_serv_sock_get("cluster"), $packet);
	if(env_debug()){ json_encode_pretty($result); };
}

1;
