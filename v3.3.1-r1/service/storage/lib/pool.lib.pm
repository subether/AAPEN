#
# ETHER|AAPEN|VMM - LIB|KVM
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#

use warnings;
use strict;
use experimental 'signatures';


#
# init pool config [JSON-OBJ]
#
sub storage_pool_conf_init(){
	my $fid = "STORAGE|POOL|CONF|INIT";
	my $type = "*.pool.json";
	my $result;
	my $i = 0;
	my $pooldb = storage_db_obj_get("pool");
	
	my $host = hostname();
	my $cfgdir = get_root() . "config/storage/$host/";
	
	# gather list of files
	log_info($fid, "config dir [$cfgdir]");
	my @file_list = file_list($cfgdir, $type);
	log_debug($fid, "config file list [@file_list]");
	
	# init config files
	foreach my $pool_config (@file_list){	
		log_info($fid, "importing pool config [$pool_config]");
		my $pool = json_file_load($pool_config);
		storage_pool_load($pool);	
		$i++;
	}
	
	log_info($fid, "imported [$i] pools");
	
	return $result;
}

#
# set storage pool [JSON-OBJ]
#
sub storage_pool_load($pool){
	my $fid = "STORAGE|POOL|LOAD";
	my $pooldb = storage_db_obj_get("pool");
	my $result;
	
	# check if valid object type
	if($pool->{'object'}{'type'} eq "storage" && $pool->{'object'}{'model'} eq "pool"){
		$result = packet_build_noencode("1", "success: object is storage pool", $fid);
		
		log_info($fid, "committing pool data");

		# check if owner of pool
		if($pool->{'owner'}{'name'} eq config_node_id_get()){
			$result->{'owner'} = "1";
			
			if(index_find($pooldb->{'index'}, $pool->{'id'}{'name'})){
				# known
				log_info($fid, "pool [$pool->{'id'}{'name'}] is known. owner [LOCAL]");
				
				# strip extra stats from object
				delete $pool->{'meta'}{'stats'};
				
				$pooldb->{'data'}{$pool->{'id'}{'name'}} = $pool;
				storage_db_obj_set("pool", $pooldb);
				
				$result = packet_build_noencode("1", "success: pool [$pool->{'id'}{'name'}] updated", $fid);
				$result->{'pool_init'} = storage_pool_init($pool->{'id'}{'name'});
			}
			else{
				# unknown
				log_info($fid, "pool [$pool->{'id'}{'name'}] is unknown. owner [LOCAL]");
				
				# strip extra stats from object
				delete $pool->{'meta'}{'stats'};
				
				$pooldb->{'data'}{$pool->{'id'}{'name'}} = $pool;
				$pooldb->{'index'} = index_add($pooldb->{'index'}, $pool->{'id'}{'name'});
				
				# metadata
				$pooldb->{'meta'}{$pool->{'id'}{'name'}}{'state'} = "0";
				$pooldb->{'meta'}{$pool->{'id'}{'name'}}{'init'} = "0";
				
				storage_db_obj_set("pool", $pooldb);
	
				$result = packet_build_noencode("1", "success: pool [$pool->{'id'}{'name'}] committed to db", $fid);	
				$result->{'pool_init'} = storage_pool_init($pool->{'id'}{'name'});	
			}
		}
		else{
			$result->{'owner'} = "0";
			
			if(index_find($pooldb->{'index'}, $pool->{'id'}{'name'})){
				# known
				log_info($fid, "pool [$pool->{'id'}{'name'}] is known. owner [REMOTE]");
				
				# strip extra stats from object
				delete $pool->{'meta'}{'stats'};
				
				$pooldb->{'data'}{$pool->{'id'}{'name'}} = $pool;
				storage_db_obj_set("pool", $pooldb);

				$result = packet_build_noencode("1", "success: pool [$pool->{'id'}{'name'}] updated", $fid);
				$result->{'pool_init'} = storage_pool_init($pool->{'id'}{'name'});
			}
			else{
				# unknown
				log_info($fid, "pool [$pool->{'id'}{'name'}] is unknown. owner [REMOTE]");
				
				# strip extra stats from object
				delete $pool->{'meta'}{'stats'};
				
				$pooldb->{'data'}{$pool->{'id'}{'name'}} = $pool;
				$pooldb->{'index'} = index_add($pooldb->{'index'}, $pool->{'id'}{'name'});
				
				# metadata
				$pooldb->{'meta'}{$pool->{'id'}{'name'}}{'state'} = "0";
				$pooldb->{'meta'}{$pool->{'id'}{'name'}}{'init'} = "0";
				
				storage_db_obj_set("pool", $pooldb);
	
				$result = packet_build_noencode("1", "success: pool [$pool->{'id'}{'name'}] committed to db", $fid);	
				$result->{'pool_init'} = storage_pool_init($pool->{'id'}{'name'});		
			}
		}
	}
	else{
		log_warn($fid, "object type is not storage pool!");
		$result = packet_build_noencode("0", "error: object is not storage pool", $fid);
	}
	
	storage_pool_stats();

	return $result;
}

#
# set storage pool [JSON-STR]
#
sub storage_pool_set($request){
	my $fid = "[storage_pool_set]";
	my $ffid = "STORAGE|POOL|SET";
	my $pooldb = storage_db_obj_get("pool");
	my $result;
	
	# check if valid object type
	if($request->{'pooldata'}{'object'}{'type'} eq "storage" && $request->{'pooldata'}{'object'}{'model'} eq "pool"){
		$result = packet_build_noencode("1", "success: object is storage pool", $fid);
		
		log_info($ffid, "committing pool data");
		my $pool = $request->{'pooldata'};
		
		$result = storage_pool_load($pool);
	}
	else{
		log_warn($ffid, "object type is not storage pool!");
		$result = packet_build_noencode("0", "error: object is not storage pool", $fid);
	}
	
	return json_encode($result);
}

#
# return storage pool [JSON-STR]
#
sub storage_pool_get($request){
	my $fid = "STORAGE|POOL|GET";
	my $pooldb = storage_db_obj_get("pool");
	my $result;
	
	if(index_find($pooldb->{'index'}, $request->{'storage'}{'pool'})){
		$result = packet_build_noencode("1", "success: returning pool [$request->{'storage'}{'pool'}] data", $fid);
		$result->{'pooldata'} = $pooldb->{'data'}{$request->{'storage'}{'pool'}};
		$result->{'poolmeta'} = $pooldb->{'meta'}{$request->{'storage'}{'pool'}};
	}
	else{
		$result = packet_build_noencode("0", "failed: unknown pool [$request->{'storage'}{'pool'}]", $fid);
	}
	
	return json_encode($result);
}

#
# check storage pool [NULL]
#
sub storage_pool_check($pool){
	my $fid = "STORAGE|POOL|CHECK";
	my $pooldb = storage_db_obj_get("pool");
	
	if(index_find($pooldb->{'index'}, $pool)){
		# known
		if(mount_check($pool->{'nfs'}{'client'}{'mount'})){
			log_info($fid, "pool is known and already mounted");
		}
		else{
			if(env_verbose()){ print "[" . date_get() . "] $fid pool is known but not mounted!\n"; };
			log_info($fid, "pool is known, but not mounted");
		}		
	}
	else{
		# unknown
		if(mount_check($pool->{'nfs'}{'client'}{'mount'})){
			log_info($fid, "pool is unknown, but already mounted");
		}
		else{
			log_info($fid, "pool is unknown, and not mounted");
		}		
	}
}

#
# init storage pool [JSON-OBJ]
#
sub storage_pool_init($name){
	my $fid = "[storage_pool_init]";
	my $ffid = "STORAGE|POOL|INIT";
	my $pooldb = storage_db_obj_get("pool");
	my $result;
	
	# verify if pool exists
	if(index_find($pooldb->{'index'}, $name)){
		# pool is known
		
		log_info($ffid, "success: pool [$name] is known");
		
		$result = packet_build_noencode("1", "success: pool is known", $fid);
		
		if(mount_check($pooldb->{'data'}{$name}{'nfs'}{'client'}{'mount'})){
			$result->{'pool_mount'} = "is mounted";
			
			if($pooldb->{'data'}{$name}{'object'}{'class'} eq "nfs"){
				$result->{'pool_size'} = mount_size_info($pooldb->{'data'}{$name}{'nfs'}{'client'}{'mount'});
			}
			
			if($pooldb->{'data'}{$name}{'object'}{'class'} eq "local"){
				$result->{'pool_size'} = mount_size_info($pooldb->{'data'}{$name}{'local'}{'mount'});
			}
		}
		else{
			$result->{'pool_mount'} = "is not mounted!";
		}
	}
	else{
		# pool is unknown
		log_warn($ffid, "pool [$name] is unknown");
		$result = packet_build_noencode("0", "error: pool is unknown", $fid);
	}
	
	return $result;
}

#
# gather stats for all known pools [NULL]
#
sub storage_pool_stats(){
	my $fid = "STORAGE|POOL|STATS";
	my $pooldb = storage_db_obj_get("pool");
	my $pools = 0;
	
	if($pooldb->{'index'} ne ""){
		my @pool_index = index_split($pooldb->{'index'});
		
		foreach my $pool (@pool_index){
			log_info($fid, "processing pool [$pool]");
			
			if($pooldb->{'data'}{$pool}{'object'}{'class'} eq "nfs"){
				if(mount_check($pooldb->{'data'}{$pool}{'nfs'}{'client'}{'mount'})){
					$pooldb->{'meta'}{$pool}{'mounted'} = "1";
					$pooldb->{'meta'}{$pool}{'state'} = "1";
					$pooldb->{'meta'}{$pool}{'date'} = date_get();
					$pooldb->{'meta'}{$pool}{'size'} = mount_size_info($pooldb->{'data'}{$pool}{'nfs'}{'client'}{'mount'});
				}
				else{
					$pooldb->{'meta'}{$pool}{'mounted'} = "0";
					$pooldb->{'meta'}{$pool}{'state'} = "0";
					$pooldb->{'meta'}{$pool}{'date'} = date_get();
				}
			}
			
			if($pooldb->{'data'}{$pool}{'object'}{'class'} eq "local"){
				$pooldb->{'meta'}{$pool}{'mounted'} = "1";
				$pooldb->{'meta'}{$pool}{'state'} = "1";
				$pooldb->{'meta'}{$pool}{'date'} = date_get();
				$pooldb->{'meta'}{$pool}{'size'} = mount_size_info($pooldb->{'data'}{$pool}{'local'}{'mount'});
			}
			
			# check for owner
			if($pooldb->{'data'}{$pool}{'owner'}{'name'} eq config_node_name_get() && $pooldb->{'data'}{$pool}{'owner'}{'id'} eq config_node_id_get()){
				log_info($fid, "node is owner of pool [$pool]... publishing pool to cluster");
				api_cluster_local_stor_set(env_serv_sock_get("cluster"), $pooldb->{'data'}{$pool});
			}
			
			$pools++;
			
			storage_pool_health($pooldb->{'data'}{$pool});
		}
		
		log_info($fid, "completed. processed [$pools] pools");
		storage_db_obj_set("pool", $pooldb);
	}
	else{
		log_info($fid, "completed. no pools");
	}
}

#
# check pool health (TODO)
#
sub storage_pool_health($pool){
	my $fid = "STORAGE|POOL|HEALTH";
	my $pool_check = $pool->{'pool'}{'check'};
	my $check_file = $pool->{'check'}{'file'};
	log_info($fid, "check [$pool_check] file [$check_file]");
}

1;
