#
# ETHER|AAPEN|CLUSTER - LIB|CLUSTER
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
# cluster object sync [NULL]
#
sub cluster_obj_sync($sync, $context, $syncobj){
	if(get_mc_enabled() && ($context eq "local")){ mc_delta_buffer_set($syncobj); };
	if(get_mc_enabled() && ($context eq "remote" && get_zmq_sync())){ mc_delta_buffer_set($syncobj); };

	if(get_zmq_client() && $sync){ zmq_client_delta_buffer_set($syncobj); };
	if(get_zmq_server()){ zmq_server_delta_buffer_set($syncobj); };
	if(get_zmq_sync() && $sync){ zmq_sync_delta_buffer_set($syncobj); };
}

#
# set object data [JSON-STR]
# 
sub cluster_obj_set($request, $sync, $context){
	my $fid = "[cluster_obj_set]";
	my $db_meta = db_meta_get();
	my $result;
	
	my $object = $request->{'cluster'}{'obj'};
	my $key = $request->{'cluster'}{'key'};
	my $id = $request->{'cluster'}{'id'};
	
	log_debug($fid, "object [$object] key [$key] id [$id] context [$context] sync [$sync]");
	
	if(defined($key) && ($key ne "")){
		log_debug($fid, "object [$object] key [$key] id [$id] context [$context] sync [$sync]");
		
		if(cluster_obj_check_bool($object)){
			my $syncobj = {};
			$syncobj->{'cluster'} = $request->{'cluster'};
			
			#
			# service
			#
			if($object eq "service"){
				my $service = $request->{'data'}{'config'}{'service'};
				my $node = $request->{'data'}{'config'}{'name'};
				
				# check index
				if(index_find($db_meta->{$object}{$service}{'index'}, $node)){
					# in index

					# check if it exists in the current context - should never happen on objects
					if(!index_find($db_meta->{$object}{$service}{$context}, $node)){
						
						# change context
						if($context eq "remote"){
							$db_meta->{$object}{$service}{'local'} = index_del($db_meta->{$object}{$service}{'local'}, $node);
						}
						else{
							$db_meta->{$object}{$service}{'remote'} = index_del($db_meta->{$object}{$service}{'remote'}, $node);
						}
						
						# commit metadata
						$db_meta->{$object}{$service}{$context} = index_add($db_meta->{$object}{$service}{$context}, $node);
						db_meta_set($db_meta);
					}

					$result = packet_build_noencode("1", "success: service [$service] node [$node] ctx [$context] updated", $fid);

					my $cdbtmp = api_cdb_local_service_get(env_serv_sock_get("cdb"), $service, $node);
										
					if($cdbtmp->{'proto'}{'result'} eq "1"){
						# got object successfully
					
						if(defined $cdbtmp->{'service'}{$service}{$node}{'object'}{'meta'}{'ver'}){

							# check context
							if($context eq "local"){
								my $cdbsrv = $request->{'data'};
								
								# get version tag from cdb if present
								if(defined $cdbtmp->{'service'}{$service}{$node}{'object'}{'cdb'}{'ver'}){
									$cdbsrv->{'object'}{'meta'}{'ver'} = $cdbtmp->{'service'}{$service}{$node}{'object'}{'cdb'}{'ver'};
								}
								else{
									$cdbsrv->{'object'}{'meta'}{'ver'}++;
								}
								
								$cdbsrv->{'object'}{'meta'}{'owner_id'} = config_node_id_get();
								$cdbsrv->{'object'}{'meta'}{'owner_name'} = config_node_name_get();
								$cdbsrv->{'object'}{'meta'}{'owner'}{'id'} = config_node_id_get();
								$cdbsrv->{'object'}{'meta'}{'owner'}{'name'} = config_node_name_get();
								$cdbsrv->{'object'}{'meta'}{'date'} = date_get();
								$cdbsrv->{'object'}{'meta'}{'context'} = $context;

								# commit object to CDB
								api_cdb_local_service_set(env_serv_sock_get("cdb"), $cdbsrv);
								
								$syncobj->{'data'} = $cdbsrv;
								cluster_obj_sync($sync, $context, $syncobj);
							}
							else{
								log_debug($fid, "service [$service] node [$node] ctx [$context]: remote context");
								api_cdb_local_service_set(env_serv_sock_get("cdb"), $request->{'data'});
								
								$syncobj->{'data'} = $request->{'data'};
								cluster_obj_sync($sync, $context, $syncobj);
							}
							
						}
						else{
							log_warn($fid, "service [$service] node [$node] ctx [$context] has no metadata");
							
							# check context
							if($context eq "local"){
								my $cdbsrv = $request->{'data'};
								$cdbsrv->{'object'}{'meta'}{'owner_id'} = config_node_id_get();
								$cdbsrv->{'object'}{'meta'}{'owner_name'} = config_node_name_get();
								$cdbsrv->{'object'}{'meta'}{'owner'}{'id'} = config_node_id_get();
								$cdbsrv->{'object'}{'meta'}{'owner'}{'name'} = config_node_name_get();
								$cdbsrv->{'object'}{'meta'}{'date'} = date_get();
								$cdbsrv->{'object'}{'meta'}{'ver'} = 0;
								$cdbsrv->{'object'}{'meta'}{'context'} = $context;
								
								# commit object to CDB
								api_cdb_local_service_set(env_serv_sock_get("cdb"), $cdbsrv);
								
								$syncobj->{'data'} = $cdbsrv;
								cluster_obj_sync($sync, $context, $syncobj);
							}
							else{
								api_cdb_local_service_set(env_serv_sock_get("cdb"), $request->{'data'});
								
								$syncobj->{'data'} = $request->{'data'};
								cluster_obj_sync($sync, $context, $syncobj);
							}
						}

					}
					else{
						# failed getting object
						log_warn($fid, "service [$service] node [$node]: failed to fetch object");
					}
					
				}
				else{
					# not in index
					log_debug($fid, "service [$service] node [$node] ctx [$context] not in index. adding.");

					# add to index
					$db_meta->{$object}{$service}{'index'} = index_add($db_meta->{$object}{$service}{'index'}, $key);
					$db_meta->{$object}{$service}{$context} = index_add($db_meta->{$object}{$service}{$context}, $key);
					db_meta_set($db_meta);
					
					# new object : TODO
					my $cdbobj = $request->{'data'};
					
					# check context
					if($context eq "local"){
						$cdbobj->{'object'}{'meta'}{'ver'} = 0;
						$cdbobj->{'object'}{'meta'}{'owner_id'} = config_node_id_get();
						$cdbobj->{'object'}{'meta'}{'owner_name'} = config_node_name_get();
						$cdbobj->{'object'}{'meta'}{'owner'}{'id'} = config_node_id_get();
						$cdbobj->{'object'}{'meta'}{'owner'}{'name'} = config_node_name_get();
						$cdbobj->{'object'}{'meta'}{'date'} = date_get();
						$cdbobj->{'object'}{'meta'}{'context'} = $context;
						
						# commit object to CDB
						$syncobj->{'data'} = $cdbobj;
						cluster_obj_sync($sync, $context, $syncobj);
					}
					else{
						# remote context
						$syncobj->{'data'} = $request->{'data'};
						cluster_obj_sync($sync, $context, $syncobj);
					}
					
					# commit service to CDB
					api_cdb_local_service_set(env_serv_sock_get("cdb"), $cdbobj);
					
					$result = packet_build_noencode("1", "success: object [$object] service [$service] key [$key] committed to db", $fid);
				}
				
			}
			else{
				#
				# object
				#
	
				if(index_find($db_meta->{$object}{'index'}, $key)){
					# in index
					log_debug($fid, "object [$object] key [$key] ctx [$context] in index. updating.");
					
					# check if it exists in the current context
					if(!index_find($db_meta->{$object}{$context}, $key)){
						# change context
						if($context eq "remote"){
							$db_meta->{$object}{'local'} = index_del($db_meta->{$object}{'local'}, $key);
						}
						else{
							$db_meta->{$object}{'remote'} = index_del($db_meta->{$object}{'remote'}, $key);
						}
						
						$db_meta->{$object}{$context} = index_del($db_meta->{$object}{$context}, $key);
						db_meta_set($db_meta);
					}
	
					my $cdbtmp = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);		
					my $cdbobj = $request->{'data'};
					
					# check context
					if($context eq "local"){
						
						# get version tag from cdb if present
						if(defined $cdbtmp->{$object}{'object'}{'cdb'}{'ver'}){
							$cdbobj->{'object'}{'meta'}{'ver'} = $cdbtmp->{$object}{'object'}{'cdb'}{'ver'};
						}
						else{
							$cdbobj->{'object'}{'meta'}{'ver'}++;
						}
						
						$cdbobj->{'object'}{'meta'}{'owner_id'} = config_node_id_get();
						$cdbobj->{'object'}{'meta'}{'owner_name'} = config_node_name_get();
						$cdbobj->{'object'}{'meta'}{'owner'}{'id'} = config_node_id_get();
						$cdbobj->{'object'}{'meta'}{'owner'}{'name'} = config_node_name_get();
						$cdbobj->{'object'}{'meta'}{'date'} = date_get();
						$cdbobj->{'object'}{'meta'}{'context'} = $context;
						
						$cdbobj->{'meta'}{'date'} = date_get();
						$cdbobj->{'meta'}{'ver'}++;
						
						if($object eq "system" || $object eq "network" || $object eq "storage" || $object eq "element"){
							
							if(defined $cdbtmp->{$object}{'meta'}{'stats'}){
								log_debug($fid, "object [$object] key [$key] has stats");
								$cdbobj->{'meta'}{'stats'} = $cdbtmp->{$object}{'meta'}{'stats'};
							}
							else{
								log_debug($fid, "object [$object] key [$key] does not have stats");
							}
						}
						
						$syncobj->{'data'} = $cdbobj;
						
						# commit object to CDB and sync to cluster
						api_cdb_obj_set(env_serv_sock_get("cdb"), $object, $cdbobj);
						cluster_obj_sync($sync, $context, $syncobj);
					}
					else{
						# remote context
						$syncobj->{'data'} = $request->{'data'};
						cluster_obj_sync($sync, $context, $syncobj);
						api_cdb_obj_set(env_serv_sock_get("cdb"), $object, $request->{'data'});
					}

					$result = packet_build_noencode("1", "success: object [$object] key [$key] updated", $fid);
				}
				else{
					# object not in index
					log_debug($fid, "object [$object] key [$key] ctxt [$context] not in index. adding.");

					# not in index
					$db_meta->{$object}{'index'} = index_add($db_meta->{$object}{'index'}, $key);
					$db_meta->{$object}{$context} = index_add($db_meta->{$object}{$context}, $key);
					db_meta_set($db_meta);

					my $cdbobj = $request->{'data'};
					
					# check context
					if($context eq "local"){
						$cdbobj->{'object'}{'meta'}{'ver'} = 0;
						$cdbobj->{'object'}{'meta'}{'owner_id'} = config_node_id_get();
						$cdbobj->{'object'}{'meta'}{'owner_name'} = config_node_name_get();
						$cdbobj->{'object'}{'meta'}{'owner'}{'id'} = config_node_id_get();
						$cdbobj->{'object'}{'meta'}{'owner'}{'name'} = config_node_name_get();
						$cdbobj->{'object'}{'meta'}{'date'} = date_get();
						$cdbobj->{'object'}{'meta'}{'context'} = $context;
						
						$syncobj->{'data'} = $cdbobj;

						# commit object to CDB and publish to cluster
						api_cdb_obj_set(env_serv_sock_get("cdb"), $object, $cdbobj);
						cluster_obj_sync($sync, $context, $syncobj);						
					}
					else{
						# remote context
						$syncobj->{'data'} = $request->{'data'};
						api_cdb_obj_set(env_serv_sock_get("cdb"), $object, $request->{'data'});
						cluster_obj_sync($sync, $context, $syncobj);
					}
					
					$result = packet_build_noencode("1", "success: object [$object] key [$key] committed to db", $fid);
				}
				
			}
		}
		else{
			log_warn($fid, "invalid object type [$object]");
			$result = cluster_obj_check($object);
		}	
	}
	else{
		log_warn($fid, "object key [$key] invalid");
		$result = packet_build_noencode("0", "error: object key [$key] invalid", $fid);
		json_encode_pretty($request);
	}

	return json_encode($result);
}

#
# get object [JSON-STR]
# 
sub cluster_obj_get($request){
	my $fid = "[cluster_obj_get]";
	my $db_meta = db_meta_get();
	my $result;

	if(!defined $request->{'cluster'}{'id'}){ $request->{'cluster'}{'id'} = "" };

	my $object = $request->{'cluster'}{'obj'};
	my $key = $request->{'cluster'}{'key'};
	my $id = $request->{'cluster'}{'id'};
	
	if(cluster_obj_check_bool($object)){
		
		# check if object or service
		if($object eq "service"){
			# service
			my $node = $request->{'cluster'}{'id'};
			my $service = $request->{'cluster'}{'key'};
			
			if(index_find($db_meta->{$object}{$service}{'index'}, $node)){
				$result = api_cdb_local_service_get(env_serv_sock_get("cdb"), $service, $node);
				
			}
			else{
				log_warn($fid, "object [$object] key [$key] id [$id] not in index");
				$result = packet_build_noencode("0", "fail: object [$object] key [$key] id [$id] not in index", $fid);
			}
			
		}
		else{
			# object
			if(index_find($db_meta->{$object}{'index'}, $key)){
				$result = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);
			}
			else{
				# return result
				log_warn($fid, "object [$object] with key [$key] not in index");
				$result = packet_build_noencode("0", "fail: object [$object] with key [$key] not in index", $fid);
				
			}
		}
	}
	else{
		log_warn($fid, "invalid object type [$object]");
		$result = cluster_obj_check($object);
	}
	
	return json_encode($result);
}

#
# set object data [JSON-STR]
# 
sub cluster_obj_meta_set($request, $sync, $context){
	my $fid = "[cluster_obj_meta_set]";
	my $db_meta = db_meta_get();
	my $result;

	my $object = $request->{'cluster'}{'obj'};
	my $key = $request->{'cluster'}{'key'};
	my $id = $request->{'cluster'}{'id'};

	if((defined($key) && ($key ne "")) && (defined($id) && ($id ne ""))){
		
		# check for local object
		if(index_find($db_meta->{$object}{'index'}, $key)){

			my $cdbdata = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);

			# check if metadatatable object
			if($object eq "system" || $object eq "network" || $object eq "storage" || $object eq "element"){
				if(env_verbose()){ log_debug($fid, "[METADATA] obj [$object] src [$id] key [$key]"); };
				log_debug($fid, "object [$object] src [$id] key [$key]");
				
				my $cdbtmp = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);
									
				my $cdbobj = $cdbtmp->{$object};
				$cdbobj->{'object'}{'meta'}{'ver'}++;
				$cdbobj->{'object'}{'meta'}{'date'} = date_get();
				
				if($object eq "system" || $object eq "network" || $object eq "storage"){
					$cdbobj->{'meta'}{'stats'}{$id} = $request->{'data'};
				}
				else{
					$cdbobj->{'meta'}{'stats'} = $request->{'data'};
				}
				
				# commit to CDB and publish to cluster
				api_cdb_obj_set(env_serv_sock_get("cdb"), $object, $cdbobj);
				cluster_obj_sync($sync, $context, $request);

				$result = packet_build_noencode("1", "success: metadata for [$object] key [$key] id [$id] updated", $fid);		
			}
			else{
				# object does not support metadata append
				log_warn($fid, "metadata for object type [$object] not supported");
				$result = packet_build_noencode("0", "error: metadata for object type [$object] not supported", $fid);
			}
		}
		else{
			# object unknown
			log_warn($fid, "object [$object] with key [$key] not fund");
			$result = packet_build_noencode("0", "error: object [$object] with key [$key] not fund", $fid);
		}
	}
	else{
		# invalid key
		$result = packet_build_noencode("0", "error: key [$key] or [$id] invalid", $fid);	
		log_warn($fid, "key [$key] or [$id] invalid");	
	}

	return json_encode($result);
}

#
# get object [JSON-STR]
# 
sub cluster_obj_del($request, $sync, $context){
	my $fid = "[cluster_obj_del]";
	my $db_meta = db_meta_get();
	my $result;

	if(!defined $request->{'cluster'}{'id'}){ $request->{'cluster'}{'id'} = "" };

	my $object = $request->{'cluster'}{'obj'};
	my $key = $request->{'cluster'}{'key'};
	my $id = $request->{'cluster'}{'id'};
	
	if(cluster_obj_check_bool($object)){
		
		# check if object or service
		if($object eq "service"){
			# service
			
			if(index_find($db_meta->{$object}{$key}{'index'}, $id)){
				$result = api_cdb_local_service_get(env_serv_sock_get("cdb"), $key, $id);
			}
			else{
				log_warn($fid, "object [$object] key [$key] id [$id] not in index");
				$result = packet_build_noencode("0", "fail: object [$object] key [$key] id [$id] not in index", $fid);
			}
			
			$result->{'cdb'} = api_cdb_local_service_del(env_serv_sock_get("cdb"), $key, $id);
			
			# update index
			$db_meta->{$object}{$key}{'index'} = index_del($db_meta->{$object}{$key}{'index'}, $id);
			db_meta_set($db_meta);
		}
		else{
			# object
			
			if(index_find($db_meta->{$object}{'index'}, $key)){
				$result = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);
			}
			else{
				log_warn($fid, "object [$object] with key [$key] not in index");
				$result = packet_build_noencode("0", "fail: object [$object] with key [$key] not in index", $fid);
			}

			$result->{'cdb'} = api_cdb_local_obj_del_new(env_serv_sock_get("cdb"), $object, $key);
			
			# update index
			$db_meta->{$object}{'index'} = index_del($db_meta->{$object}{'index'}, $key);
			db_meta_set($db_meta);
		}
		
		# push request to cluster
		cluster_obj_sync($sync, $context, $request);
	}
	else{
		log_warn($fid, "invalid object type [$object]");
		$result = cluster_obj_check($object);
	}
	
	return json_encode($result);
}

#
# cluster default env [NULL]
#
sub cluster_env_default(){
	my $fid = "[cluster_env_default]";
	env_debug_off();
	env_verbose_off();
	env_info_off();
}

#
# verify CDB state [NULL]
#
sub cluster_cdb_check(){
	my $fid = "[cluster_cdb_check]";
	my $ffid = "CDB|CHECK";
	
	my $pong = api_cdb_local_ping(env_serv_sock_get("cdb"));
	
	if($pong->{'proto'}{'result'} eq "1"){
		log_info($ffid, "CDB version [$pong->{'proto'}{'version'}] responded");
	}
	else{
		log_fatal($ffid, "CDB did not respond. start CDB before starting CLUSTER...");
		log_fatal($ffid, "CDB did not respond!");
		log_fatal($ffid, "*** FAILED: Please start CDB before starting CLUSTER.. ***");
		die;
	}
	
}

1;
