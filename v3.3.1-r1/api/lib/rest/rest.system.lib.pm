#
# ETHER|AAPEN|API - LIB|REST|SYSTEM
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
# validate and fetch system from cluster [JSON-OBJ]
#
sub system_rest_validate_get($system_name){
	my $fid = "[system_validate_get]";
	my $ffid = "SYSTEM|VALIDATE|GET";
	
	# validate node name
	if(defined $system_name && string_validate($system_name)){
		log_info($ffid, "success: system name defined and valid");
		my $system_data = api_cluster_local_obj_get(env_serv_sock_get("cluster"), 'system', $system_name);
		
		if($system_data->{'proto'}{'result'} eq "1"){
			return $system_data;
		}
		else{
			log_warn($ffid, "error: failed to fetch system [$system_name] from cluster");
			return packet_build_noencode("0", "error: failed to fetch system [$system_name] from cluster", $fid);
		}		
	}
	else{
		log_warn($ffid, "error: object name must be defined");
		return packet_build_noencode("0", "error: object name must be defined", $fid);
	}
}

#
# load system config from disk [JSON-OBJ]
#
sub system_rest_config_load($request){
	my $fid = "[system_config_load]";
	my $ffid = "SYSTEM|CONFIG|LOAD";
	my $syscfg = base_system_cfg_get();

	log_info_json($ffid, "loading system configuration", $request);
	
	my $result = packet_build_noencode("1", "success: loading storage config", $fid);
	$result->{'system'} = api_rest_obj_config_load($syscfg->{'dir'}, $syscfg->{'type'}, 'system', $request);
	log_info_json($ffid, "system config load result", $result);
	
	return $result;	
}

#
# save system config to disk [JSON-OBJ]
#
sub system_rest_config_save($request){
	my $fid = "[system_config_save]";
	my $ffid = "SYSTEM|CONFIG|SAVE";
	my $syscfg = base_system_cfg_get();

	my $system_num = 0;
	my $system_fail = 0;
	
	my $system_meta = api_cluster_local_meta_get(env_serv_sock_get("cluster"));

	if($system_meta->{'proto'}{'result'}){
		my @system_index = index_split($system_meta->{'meta'}{'system'}{'index'});
		
		foreach my $system_name (@system_index){
			my $system_data = system_rest_validate_get($system_name);
			
			if($system_data->{'proto'}{'result'}){
				my $system_clean = system_rest_config_clean($system_data->{'system'});
				my $result = api_rest_obj_config_save($syscfg->{'dir'}, $syscfg->{'type'}, 'system', $system_clean);
				
				if($result->{'proto'}{'result'}){
					log_info($ffid, "successfully saved system [$system_name]");
					$system_num++;
				}
				else{
					log_warn($ffid, "failed to save system [$system_name]");
					$system_fail++;
				}
				
			}
			else{
				log_warn($ffid, "failed to get system [$system_data] from cluster!");
				$system_fail++;
			}	
		}
		
		log_info($ffid, "saved [$system_num] systems. [$system_fail] failures");
		return packet_build_noencode("1", "success: saved [$system_num] systems. [$system_fail] failures", $fid);	
	}
	else{
		log_warn($ffid, "failed to get metadata from cluster");
		return packet_build_noencode("0", "failed: could not get metadata from cluster", $fid);	
	}

}

#
# save system config [JSON-OBJ]
#
sub system_rest_config_set($request){
	my $fid = "[system_config_set]";
	my $ffid = "SYSTEM|CONFIG|SET";
	my $syscfg = base_system_cfg_get();

	log_info_json($ffid, "saving system configuration", $request);
	
	# validate system
	if($request->{'proto'}{'system'}{'id'}{'name'}){
		# clean system
		my $system_clean = system_rest_config_clean($request->{'proto'}{'system'});
		log_debug_json($ffid, "cleaned system configuration", $system_clean);
		
		# commit to cluster
		my $cluster_result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $request->{'proto'}{'system'});
			
		# save config
		my $result = api_rest_obj_config_save($syscfg->{'dir'}, $syscfg->{'type'}, 'system', $system_clean);
		
		return packet_build_noencode("1", "success: system config saved", $fid);
	}
	else{
		# system essentials missing - need better checking
		log_warn($ffid, "failed: system [$request->{'proto'}{'name'}] requirements missing");
		return packet_build_noencode("0", "failed: system [$request->{'proto'}{'name'}] requirements missing", $fid);
	}
}

#
# delete system config
#
sub system_rest_config_del($request){
	my $fid = "[system_config_del]";
	my $ffid = "SYSTEM|CONFIG|DELETE";
	my $syscfg = base_system_cfg_get();
	
	log_info_json($ffid, "deleting system configuration", $request);

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
		
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check if system is online
		if(defined $system_data->{'system'}{'meta'}{'state'} && $system_data->{'system'}{'meta'}{'state'} == "0"){
			# system is offline
			
			my $trashdir = $syscfg->{'dir'} . "REMOVED/";
			
			# check for dir
			if(dir_check($trashdir)){
				log_info($ffid, "trash directory exists!");
			}
			else{
				log_info($ffid, "trash directory does not exist!");
			}
			
			my $cfg_file = $syscfg->{'dir'} . $system_data->{'system'}{'id'}{'name'} . $syscfg->{'type'};
			
			log_info($ffid, "cfg file [$cfg_file]");
			
			if(file_check($cfg_file)){
				log_info($ffid, "file exists!");
			}
			else{
				log_info($ffid, "file does not exist!");
			}
			
			#my $cfgsrc = $sysdir . $sysdb->{$sysid}{'id'}{'cfg'};
			#my $cfgdst = $trashdir . $sysdb->{$sysid}{'id'}{'cfg'};
			
			# move config to trash
			#move($cfgsrc, $cfgdst) or do {
			#	log_error($ffid, "ERROR: FAILED TO COPY THE CONFIG TO TRASH DIR!");
			#	$remove_success = 0;
			#};
									
			# check if config removal is successful
			#if($remove_success){
			#	$result->{'response'}{'api'}{'cfg_remove'} = "success: moved config to trash";
			#}
			#else{
			#	$result->{'response'}{'api'}{'cfg_remove'} = "error: failed to trash config!";
			#}
			
			return packet_build_noencode("1", "success: system is offline. can delete..", $fid);
		}
		else{
			# system is online
			return packet_build_noencode("0", "failed: system is online. cannot delete.", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}
}

#
# reset system [JSON-OBJ]
#
sub system_rest_reset($request){
	my $fid = "[system_reset]";
	my $ffid = "SYSTEM|RESET";

	log_info_json($ffid, "resetting system", $request);

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if($system_data->{'system'}{'meta'}{'state'}){
			log_info($ffid, "success: system [$request->{'proto'}{'name'}] is marked online. attempting reset");
			
			# fetch node
			my $node_data = node_rest_validate_get($system_data->{'system'}{'meta'}{'node_name'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				
				# packet
				my $packet = api_proto_packet_build("hyper", "reset");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				
				# send
				my $result = packet_build_noencode("1", "success: resetting system [$request->{'proto'}{'name'}]", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				return $result;
			}
			else{
				# failed to fetch node
				return $node_data;
			}
		}
		else{
			# system is not marked online. cannot reset
			log_warn($ffid, "error: system [$request->{'proto'}{'name'}] is not marked online");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is not marked online", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}
}

#
# shutdown system [JSON-OBJ]
#
sub system_rest_shutdown($request){
	my $fid = "[system_shutdown]";
	my $ffid = "SYSTEM|SHUTDOWN";

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if($system_data->{'system'}{'meta'}{'state'}){
			log_info($ffid, "success: system [$request->{'proto'}{'name'}] is marked online. attempting shutdown");
			
			# fetch node
			my $node_data = node_rest_validate_get($system_data->{'system'}{'meta'}{'node_name'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				
				# packet
				my $packet = api_proto_packet_build("hyper", "sys_shutdown_async");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				
				# send
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] shutdown initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				return $result;
			}
			else{
				# failed to fetch node
				return $node_data;
			}
		}
		else{
			# system not marked online. cannot shutdown
			log_warn($ffid, "error: system is not marked online");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is not marked online", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}

}

#
# unload system [JSON-OBJ]
#
sub system_rest_unload($request){
	my $fid = "[system_unload]";
	my $ffid = "SYSTEM|UNLOAD";

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if($system_data->{'system'}{'meta'}{'state'}){
			log_info($ffid, "success: system [$request->{'proto'}{'name'}] is marked online. attempting unload");
			
			# fetch node
			my $node_data = node_rest_validate_get($system_data->{'system'}{'meta'}{'node_name'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				
				# packet
				my $packet = api_proto_packet_build("hyper", "sys_unload_async");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				
				# send
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] unload initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				return $result;
			}
			else{
				# failed to fetch node
				return $node_data;
			}
		}
		else{
			# system not marked online. cannot unload
			log_warn($ffid, "error: system [$request->{'proto'}{'name'}] is not marked online");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is not marked online", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}

}

#
# load system [JSON-OBJ]
#
sub system_rest_load($request){
	my $fid = "[system_load]";
	my $ffid = "SYSTEM|LOAD";

	log_info_json($ffid, "loading system", $request);

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if(!$system_data->{'system'}{'meta'}{'state'}){
			log_info($ffid, "success: system [$request->{'proto'}{'name'}] is not marked online. attempting load");
			
			# fetch node
			my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				
				# packet
				my $packet = api_proto_packet_build("hyper", "sys_load_async");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				$packet->{'hyper'}{'vm'} = $system_data->{'system'};
				
				# send
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] node [$request->{'proto'}{'node'}] load initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				return $result;
			}
			else{
				# failed to fetch node
				return $node_data;
			}
		}
		else{
			log_warn($ffid, "error: system [$request->{'proto'}{'name'}] is already marked online");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is already marked online", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}
}

#
# validate system and resources on node [JSON-OBJ]
#
sub system_rest_validate($request){
	my $fid = "[system_validate]";
	my $ffid = "SYSTEM|VALIDATE";

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	#json_encode_pretty($system_data);
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		#print "$fid SYSTEM STATE [$system_data->{'system'}{'meta'}{'state'}]\n";
		
		# check system state
		if(!$system_data->{'system'}{'meta'}{'state'}){
			log_info($fid, "success: system [$request->{'proto'}{'name'}] is not marked online. requesting validation");
			
			# fetch node
			my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				
				# packet
				my $packet = api_proto_packet_build("hyper", "validate");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				$packet->{'hyper'}{'vm'} = $system_data->{'system'};
				
				# send
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] validation initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				log_info_json($fid, "validation result", $result);
				
				# check for successful validation request
				if($result->{'response'}{'proto'}{'result'} eq "1"){
					
					# check if system init flag is set..
					if($system_data->{'system'}{'object'}{'init'}){
						log_info($fid, "system [$request->{'proto'}{'name'}] is marked as initialized");
						
						# check if system is actually initialized
						if($result->{'response'}{'vm'}{'init'}{'storage'}){
							# marked as initialized, and initialized
							log_info($fid, "system [$request->{'proto'}{'name'}] storage exists and is marked as initialized");
						}
						else{
							# marked as initialized, but does not exist on disk
							log_warn($fid, "system [$request->{'proto'}{'name'}] storage is not initialized! updating config..");
							$system_data->{'system'}{'object'}{'init'} = 0;
							
							# push to cluster
							my $cluster_result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system_data->{'system'});
							log_info_json($fid, "cluster update result", $cluster_result);
						}
					}
					else{
						log_info($fid, "system [$request->{'proto'}{'name'}] not marked as initialized");
						
						# check if system is initialized
						if($result->{'response'}{'vm'}{'init'}{'storage'}){
							# system exists but not marked as initialized
							log_warn($fid, "system [$request->{'proto'}{'name'}] storage is initialized. updating config.");
							$system_data->{'system'}{'object'}{'init'} = 1;
							
							# push to cluster
							my $cluster_result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system_data->{'system'});	
							log_info_json($fid, "cluster update result", $cluster_result);
						}
						else{
							# not marked as initialized and not present on disk
							log_info($fid, "system [$request->{'proto'}{'name'}] storage is not initialized");
						}
					}
					
				}
				else{
					log_warn_json($fid, "system validation failed to complete!", $result);
				}
				
				return $result;
			}
			else{
				# failed to fetch node
				return $node_data;
			}
		
		}
		else{
			return packet_build_noencode("0", "system [$request->{'proto'}{'name'}] is marked online. cannot validate.", $fid);	
		}
		
	}
	else{
		# failed to fetch system
		return $system_data;
	}

}

#
# create system [JSON-OBJ]
#
sub system_rest_create($request){
	my $fid = "[system_create]";
	my $ffid = "SYSTEM|CREATE";

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if(!$system_data->{'system'}{'meta'}{'state'}){
			log_info($fid, "success: system [$request->{'proto'}{'name'}] is not marked online. requesting create");
			
			# fetch node
			my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				log_info($fid, "success: system [$request->{'proto'}{'name'}] is offline. starting create");
				
				# packet
				my $packet = api_proto_packet_build("hyper", "sys_create");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				$packet->{'hyper'}{'vm'} = $system_data->{'system'};
				
				# send
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] create initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				return $result;
			}
			else{
				# failed to fetch node
				return $node_data;
			}
	
		}
		else{
			return packet_build_noencode("0", "system [$request->{'proto'}{'name'}] is marked online. cannot create", $fid);	
		}

	}
	else{
		# failed to fetch system
		return $system_data;
	}

}

#
# clone system config [JSON-OBJ]
#
sub system_rest_config_clone($request){
	my $fid = "[system_config_clone]";
	my $ffid = "SYSTEM|CONFIG|CLONE";
	my $syscfg = base_system_cfg_get();

	log_info_json($fid, "cloning system configuration", $request);

	# fetch system
	my $src_system_data = system_rest_validate_get($request->{'proto'}{'srcname'});

	# validate system
	if($src_system_data->{'proto'}{'result'} eq "1"){
		
		# fetch db from cluster
		my $db = api_cluster_local_db_get(env_serv_sock_get('cluster'));
		
		# check if dest name is unique
		if(!api_rest_check_obj_name($db->{'db'}{'system'}, $request->{'proto'}{'dstname'})){
			log_info($fid, "name is unique!");
		}
		else{
			log_warn($fid, "error: dest system name [$request->{'proto'}{'dstname'}] already exists");
			return packet_build_noencode("0", "error: dest system name [$request->{'proto'}{'dstname'}] already exists", $fid);
		}
		
		# check if dst id is unique
		if(!api_rest_check_obj_id($db->{'db'}{'system'}, $request->{'proto'}{'dstid'})){
			log_info($fid, "id is unique!");
		}
		else{
			log_warn($fid, "error: dest system id [$request->{'proto'}{'dstid'}] already exists");
			return packet_build_noencode("0", "error: dest system id [$request->{'proto'}{'dstid'}] already exists", $fid);
		}

		# check if storage pool exists
		if(storage_rest_pool_check($db->{'db'}{'storage'}, $request->{'proto'}{'dstpool'})){
			log_info($fid, "storage pool exists");
		}
		else{
			log_warn($fid, "error: storage pool [$request->{'proto'}{'dstpool'}] does not exist");
			return packet_build_noencode("0", "error: storage pool [$request->{'proto'}{'dstpool'}] does not exist", $fid);
		}		

		# check if group is valid
		if(!defined $request->{'proto'}{'dstgroup'} || !string_validate($request->{'proto'}{'dstgroup'})){
			log_warn($fid, "error: group name [$request->{'proto'}{'dstpool'}] is invalid");
			return packet_build_noencode("0", "error: group name [$request->{'proto'}{'dstpool'}] is invalid", $fid);
		}


		# get pool
		my $storage_pool = storage_rest_pool_get($db->{'db'}{'storage'}, $request->{'proto'}{'dstpool'});

		# create config clone
		my $system_clone = system_rest_config_clone_create($src_system_data->{'system'}, $request->{'proto'}{'dstname'}, $request->{'proto'}{'dstid'}, $request->{'proto'}{'dstgroup'}, $request->{'proto'}{'dstpool'}, $storage_pool);
		
		# print the resulting config
		log_info_json($fid, "cloned system configuration", $system_clone);

		if($system_clone->{'proto'}{'result'} eq "1"){
			#my $result = packet_build_noencode("1", "success: system config cloned successfully", $fid);

			# save to cluster
			#my $cluster_result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system_clone->{'clone'});
			#log_info_json($fid, "cluster update result", $cluster_result);
			#$result->{'cluster_result'} = $cluster_result;

			# save to disk
			my $system_clean = system_rest_config_clean($system_clone->{'clone'});
			my $result = api_rest_obj_config_save($syscfg->{'dir'}, $syscfg->{'type'}, 'system', $system_clean);
			#$result->{'cluster_result'} = $cluster_result;

			# save to cluster
			my $cluster_result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system_clean);
			log_info_json($fid, "cluster update result", $cluster_result);

			return packet_build_noencode("1", "success: system config cloned successfully", $fid);
		}
		else{
			return packet_build_noencode("0", "error: system config cloning failed", $fid);
		}
	}
	else{
		# failed to fetch src system
		return $src_system_data;
	}
}

#
# clone system [JSON-OBJ]
#
sub system_rest_clone($request){
	my $fid = "[system_clone]";
	my $ffid = "SYSTEM|CLONE";
	my $syscfg = base_system_cfg_get();

	log_info_json($fid, "cloning system", $request);

	# fetch system
	my $src_system_data = system_rest_validate_get($request->{'proto'}{'srcname'});
	
	log_info_json($fid, "source system data", $src_system_data);
	
	# validate system
	if($src_system_data->{'proto'}{'result'} eq "1"){
		
		# fetch db from cluster
		my $db = api_cluster_local_db_get(env_serv_sock_get('cluster'));
		
		# check if dest name is unique
		if(!api_rest_check_obj_name($db->{'db'}{'system'}, $request->{'proto'}{'dstname'})){
			log_info($fid, "name is unique!");
		}
		else{
			log_warn($fid, "error: dest system name [$request->{'proto'}{'dstname'}] already exists");
			return packet_build_noencode("0", "error: dest system name [$request->{'proto'}{'dstname'}] already exists", $fid);
		}
		
		# check if dst id is unique
		if(!api_rest_check_obj_id($db->{'db'}{'system'}, $request->{'proto'}{'dstid'})){
			log_info($fid, "id is unique!");
		}
		else{
			log_warn($fid, "error: dest system id [$request->{'proto'}{'dstid'}] already exists");
			return packet_build_noencode("0", "error: dest system id [$request->{'proto'}{'dstid'}] already exists", $fid);
		}

		# check if storage pool exists
		if(storage_rest_pool_check($db->{'db'}{'storage'}, $request->{'proto'}{'dstpool'})){
			log_info($fid, "storage pool exists");
		}
		else{
			log_warn($fid, "error: storage pool [$request->{'proto'}{'dstpool'}] does not exist");
			return packet_build_noencode("0", "error: storage pool [$request->{'proto'}{'dstpool'}] does not exist", $fid);
		}		

		# check if group is valid
		if(!defined $request->{'proto'}{'dstgroup'} || !string_validate($request->{'proto'}{'dstgroup'})){
			log_warn($fid, "error: group name [$request->{'proto'}{'dstpool'}] is invalid");
			return packet_build_noencode("0", "error: group name [$request->{'proto'}{'dstpool'}] is invalid", $fid);
		}

		# check if node is valid
		if(!defined $request->{'proto'}{'node'} || !string_validate($request->{'proto'}{'node'})){
			log_warn($fid, "error: node name [$request->{'proto'}{'node'}] is invalid");
			return packet_build_noencode("0", "error: node name [$request->{'proto'}{'dstpool'}] is invalid", $fid);
		}

		# fetch node
		my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
		
		# validate node
		if($node_data->{'proto'}{'result'} eq "1"){
			log_info($fid, "success: node name [$request->{'proto'}{'node'}] fetched successfully");
			
		}
		else{
			log_warn($fid, "error: node name [$request->{'proto'}{'node'}] does not exist");
			return packet_build_noencode("0", "error: node name [$request->{'proto'}{'dstpool'}] does not exist", $fid);
		}

		# get pool
		my $storage_pool = storage_rest_pool_get($db->{'db'}{'storage'}, $request->{'proto'}{'dstpool'});

		# NEED TO VALIDATE THE POOL AS WELL HERE
		# make a rest validate get function for pools as well

		#log_info_json($fid, "pre-marker system state", $src_system_data->{'system'});

		# create config clone
		my $system_clone = system_rest_config_clone_create($src_system_data->{'system'}, $request->{'proto'}{'dstname'}, $request->{'proto'}{'dstid'}, $request->{'proto'}{'dstgroup'}, $request->{'proto'}{'dstpool'}, $storage_pool);

		# print the resulting config
		log_info_json($fid, "cloned system configuration", $system_clone);

		if($system_clone->{'proto'}{'result'} eq "1"){
			
			# build clone request packet
			my $packet = api_proto_packet_build("hyper", "sys_clone_async");
			$packet->{'hyper'}{'src'} = $src_system_data->{'system'};
			$packet->{'hyper'}{'dst'} = $system_clone->{'clone'};
			
			log_info_json($fid, "clone async packet", $packet);
			
			# send clone request to node
			my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'srcname'}] create initialized", $fid);
			$result->{'request'} = $request;
			$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));

			log_info_json($fid, "clone async result", $result);
			
			# save to cluster
			my $cluster_result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system_clone->{'clone'});
			log_info_json($fid, "cluster update result", $cluster_result);
			
			# save to disk
			my $system_clean = system_rest_config_clean($system_clone->{'clone'});
			api_rest_obj_config_save($syscfg->{'dir'}, $syscfg->{'type'}, 'system', $system_clean);

			return packet_build_noencode("1", "success: system config cloned successfully", $fid);
		}
		else{
			log_warn($fid, "error: system [$request->{'proto'}{'name'}] config clone failed!");
			return packet_build_noencode("0", "error: system config cloning failed", $fid);
		}

	}
	else{
		# failed to fetch src system
		return $src_system_data;
	}
}

#
# clean system config [JSON-OBJ]
#
sub system_rest_config_clean($system){
	my $fid = "[system_config_clean]";
	my $ffid = "SYSTEM|CONFIG|CLEAN";
	
	log_debug_json($ffid, "received system for cleaning", $system);	
	log_info($ffid, "dest system name [" . $system->{'id'}{'name'} . "] id [".  $system->{'id'}{'id'} . "]");
	
	# cleanup config
	delete $system->{'meta'};
	delete $system->{'state'};
	delete $system->{'object'}{'meta'};
	delete $system->{'object'}{'cdb'};
	
	$system->{'meta'}{'state'} = "0";
	$system->{'meta'}{'status'} = "offline";
	$system->{'state'}{'vm_status'} = "offline";
	
	# process storage devices
	my @net_index = index_split($system->{'net'}{'dev'});
	
	foreach my $nic (@net_index){
		#log_info($fid, "processing nic [$nic]");
				
		if($system->{'net'}{$nic}{'net'}{'type'} eq "bri-tap"){
			delete $system->{'net'}{$nic}{'tap'};
			delete $system->{'net'}{$nic}{'bri'};
		}
		elsif($system->{'net'}{$nic}{'net'}{'type'} eq "dpdk-vpp"){
			delete $system->{'net'}{$nic}{'vpp'};
		}
		else{
			log_warn($fid, "error: network type [" . $system->{'net'}{$nic}{'net'}{'type'} . "] is unknown");
			return packet_build_noencode("0", "error: network type [" . $system->{'net'}{$nic}{'net'}{'type'} . "] is unknown", $fid);
		}
	}	
	
	# completed
	log_debug_json($fid, "cleaned system configuration", $system);
	return $system;
}

#
# create system config clone [JSON-OBJ]
#
sub system_rest_config_clone_create($src_system, $dst_system_name, $dst_system_id, $dst_system_group, $pool_name, $storage_pool){
	my $fid = "[system_config_clone_create]";
	my $ffid = "SYSTEM|CONFIG|CLONE|CREATE";
	
	log_info_json($fid, "received system", $src_system);	
	log_info($fid, "dest system name [$dst_system_name] id [$dst_system_id] group [$dst_system_group] pool [$pool_name]");
	
	# clone config (dereference object)
	my $dst_system = decode_json(encode_json($src_system));
	
	# cleanup config
	delete $dst_system->{'meta'};
	delete $dst_system->{'state'};
	delete $dst_system->{'object'}{'meta'};
	delete $dst_system->{'object'}{'cdb'};
	
	# identity
	$dst_system->{'id'}{'name'} = $dst_system_name;
	$dst_system->{'id'}{'id'} = $dst_system_id;
	$dst_system->{'id'}{'group'} = $dst_system_group;
	$dst_system->{'id'}{'cfg'} = $dst_system_name . ".sys.json";

	$dst_system->{'meta'}{'state'} = "0";
	$dst_system->{'meta'}{'status'} = "offline";
	$dst_system->{'state'}{'vm_status'} = "offline";
	$dst_system->{'object'}{'init'} = "0";
	
	# process storage
	my @stor_index = index_split($dst_system->{'stor'}{'disk'});
	
	foreach my $stor_dev (@stor_index){	
		log_info($fid, "processing storage [$stor_dev]");
		
		if($src_system->{'stor'}{$stor_dev}{'backing'} ne "pool"){
			log_warn($fid, "error: storage for device [$stor_dev] is not pool");
			return packet_build_noencode("0", "error: storage for device [$stor_dev] is not pool", $fid);
		}
		else{
			# configure pool settings
			$dst_system->{'stor'}{$stor_dev}{'pool'}{'name'} = $storage_pool->{'id'}{'name'};
			$dst_system->{'stor'}{$stor_dev}{'pool'}{'id'} = $storage_pool->{'id'}{'id'};
			$dst_system->{'stor'}{$stor_dev}{'pool'}{'type'} = $storage_pool->{'object'}{'class'};
			
			$dst_system->{'stor'}{$stor_dev}{'image'} = $dst_system_name . "." . $stor_dev . "." . $src_system->{'stor'}{$stor_dev}{'type'};
			$dst_system->{'stor'}{$stor_dev}{'dev'} = $storage_pool->{'pool'}{'path'} . $dst_system->{'id'}{'group'} . "/" . $dst_system->{'id'}{'name'} . "/";
		}
	}
	
	# process network devices
	my @net_index = index_split($dst_system->{'net'}{'dev'});
	
	foreach my $nic (@net_index){		
		log_info($fid, "processing nic [$nic]");
		$dst_system->{'net'}{$nic}{'mac'} = net_mac_generate();
		$dst_system->{'net'}{$nic}{'ip'} = "unknown";
		
		if($dst_system->{'net'}{$nic}{'net'}{'type'} eq "bri-tap"){
			delete $dst_system->{'net'}{$nic}{'tap'};
			delete $dst_system->{'net'}{$nic}{'bri'};
		}
		elsif($dst_system->{'net'}{$nic}{'net'}{'type'} eq "dpdk-vpp"){
			delete $dst_system->{'net'}{$nic}{'vpp'};
		}
		else{
			log_warn($fid, "error: network type [$dst_system->{'net'}{$nic}{'net'}{'type'}] is unknown");
			return packet_build_noencode("0", "error: network type [$dst_system->{'net'}{$nic}{'net'}{'type'}] is unknown", $fid);
		}
	}	
	
	# return cloned system
	my $return = packet_build_noencode("1", "success: system cloned successfully", $fid);
	$return->{'clone'} = $dst_system;
	return $return;
}

#
# migrate system [JSON-OBJ]
#
sub system_rest_migrate($request){
	my $fid = "[system_migrate]";
	my $ffid = "SYSTEM|MIGRATE";
	
	log_info_json($fid, "migrating system", $request);

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if($system_data->{'system'}{'meta'}{'state'}){
			log_info($fid, "success: system [$request->{'proto'}{'name'}] is marked online. requesting migration");
			
			# fetch and validate src node data
			my $src_node_data = node_rest_validate_get($system_data->{'system'}{'meta'}{'node_name'});
			
			if($src_node_data->{'proto'}{'result'} eq "1"){
				
				# fetch and validate dest node data
				my $dst_node_data = node_rest_validate_get($request->{'proto'}{'dstnode'});
				
				if($dst_node_data->{'proto'}{'result'} eq "1"){
					
					if($src_node_data->{'node'}{'id'}{'name'} ne $dst_node_data->{'node'}{'id'}{'name'}){
						my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] migration initialized", $fid);
					
						# get source node
						log_info($fid, "SYSTEM [$system_data->{'system'}{'id'}{'name'}] SRC NODE [$src_node_data->{'node'}{'id'}{'name'}] DST NODE [$dst_node_data->{'node'}{'id'}{'name'}]");
						
						return $result;
					}
					else{
						log_warn($fid, "error: source and destination node is the same. cannot migrate.");
						return packet_build_noencode("0", "error: source and destination node is the same. cannot migrate.", $fid);
					}	
				}
				else{
					log_warn($fid, "error: destination node failed validation");
					return $dst_node_data;
				}
			}
			else{
				log_warn($fid, "error: source node failed validation");
				return $src_node_data;
			}
		}
		else{
			log_warn($fid, "error: system [$request->{'proto'}{'name'}] is not marked online. cannot migrate.");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is not marked online. cannot migrate", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}
}

#
# clone system [JSON-OBJ]
#
sub system_rest_move($request){
	my $fid = "[system_move]";
	my $ffid = "SYSTEM|MOVE";
	my $syscfg = base_system_cfg_get();

	log_info_json($fid, "cloning system", $request);

	# fetch system
	my $src_system_data = system_rest_validate_get($request->{'proto'}{'srcname'});
	log_info_json($fid, "source system data", $src_system_data);
	
	# validate system
	if($src_system_data->{'proto'}{'result'} eq "1"){
		
		# fetch db from cluster
		my $db = api_cluster_local_db_get(env_serv_sock_get('cluster'));
		
		# check if dest name is unique
		if(!api_rest_check_obj_name($db->{'db'}{'system'}, $request->{'proto'}{'dstname'})){
			log_info($fid, "name is unique!");
		}
		else{
			
			# need to check if name matches original...
			log_warn($fid, "error: dest system name [$request->{'proto'}{'dstname'}] already exists");
			return packet_build_noencode("0", "error: dest system name [$request->{'proto'}{'dstname'}] already exists", $fid);
		}
		
		# check if dst id is unique
		if(!api_rest_check_obj_id($db->{'db'}{'system'}, $request->{'proto'}{'dstid'})){
			log_info($fid, "id is unique!");
		}
		else{
			
			# need to check if name matches original...
			log_warn($fid, "error: dest system id [$request->{'proto'}{'dstid'}] already exists");
			return packet_build_noencode("0", "error: dest system id [$request->{'proto'}{'dstid'}] already exists", $fid);
		}

		# check if storage pool exists
		if(storage_rest_pool_check($db->{'db'}{'storage'}, $request->{'proto'}{'dstpool'})){
			log_info($fid, "storage pool exists");
		}
		else{
			log_warn($fid, "error: storage pool [$request->{'proto'}{'dstpool'}] does not exist");
			return packet_build_noencode("0", "error: storage pool [$request->{'proto'}{'dstpool'}] does not exist", $fid);
		}		

		# check if group is valid
		if(!defined $request->{'proto'}{'dstgroup'} || !string_validate($request->{'proto'}{'dstgroup'})){
			log_warn($fid, "error: group name [$request->{'proto'}{'dstpool'}] is invalid");
			return packet_build_noencode("0", "error: group name [$request->{'proto'}{'dstpool'}] is invalid", $fid);
		}

		# check if group is valid
		if(!defined $request->{'proto'}{'node'} || !string_validate($request->{'proto'}{'node'})){
			log_warn($fid, "error: node name [$request->{'proto'}{'node'}] is invalid");
			return packet_build_noencode("0", "error: node name [$request->{'proto'}{'dstpool'}] is invalid", $fid);
		}

		# fetch node
		my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
		
		# validate node
		if($node_data->{'proto'}{'result'} eq "1"){
			log_info($fid, "success: node name [$request->{'proto'}{'node'}] fetched successfully");
			
		}
		else{
			log_warn($fid, "error: node name [$request->{'proto'}{'node'}] does not exist");
			return packet_build_noencode("0", "error: node name [$request->{'proto'}{'dstpool'}] does not exist", $fid);
		}

		# get pool
		my $storage_pool = storage_rest_pool_get($db->{'db'}{'storage'}, $request->{'proto'}{'dstpool'});

		# NEED TO VALIDATE THE STORAGE POOL

		# create config clone
		my $system_clone = system_rest_config_clone_create($src_system_data->{'system'}, $request->{'proto'}{'dstname'}, $request->{'proto'}{'dstid'}, $request->{'proto'}{'dstgroup'}, $request->{'proto'}{'dstpool'}, $storage_pool);

		# print the resulting config
		log_info_json($fid, "cloned system configuration", $system_clone);

		if($system_clone->{'proto'}{'result'} eq "1"){
			
			# save to cluster
			#my $cluster_result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system_clone->{'clone'});
			#json_encode_pretty($cluster_result);

			# save to disk
			# THIS ONE IS MISSING...
			

			# start ASYNC - this must be REST
			my $packet = api_proto_packet_build("hyper", "sys_clone_async");
			$packet->{'hyper'}{'src'} = $src_system_data->{'system'};
			$packet->{'hyper'}{'dst'} = $system_clone->{'clone'};
			
			log_info_json($fid, "clone async packet", $packet);
			
			#my $src_system = $req->{'hyper'}{'src'};
			#my $dst_system = $req->{'hyper'}{'dst'};
			
			# send
			my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'srcname'}] create initialized", $fid);
			$result->{'request'} = $request;
			$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));

			log_info_json($fid, "clone async result", $result);
			
			# save to disk
			my $system_clean = system_rest_config_clean($system_clone->{'clone'});
			api_rest_obj_config_save($syscfg->{'dir'}, $syscfg->{'type'}, 'system', $system_clean);

			return packet_build_noencode("1", "success: system config cloned successfully", $fid);
		
		}
		else{
			log_warn($fid, "error: system [$request->{'proto'}{'name'}] config clone failed!");
			return packet_build_noencode("0", "error: system config cloning failed", $fid);
		}

	}
	else{
		# failed to fetch src system
		return $src_system_data;
	}
}


#
# move system [JSON-OBJ]
#
sub system_rest_move_ORIG($request){
	my $fid = "[system_move]";
	my $ffid = "SYSTEM|MOVE";

	log_info_json($fid, "moving system", $request);

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if(!$system_data->{'system'}{'meta'}{'state'}){
			
			# get node
			my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
			
			if($node_data->{'proto'}{'result'} eq "1"){
				log_info($fid, "success: system [$request->{'proto'}{'name'}] is offline. starting move");
				
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] move reached", $fid);
			
				
			
				# clone the system ... however... the function wont work here because it validates... this will fail..
				# need to replicate this code here then
				
				# clone the system to the new path
				
				# cannot delete the system before async completes... API wont know when the ASYNC COMPLETES....!
				# this means the hypervisor must do the delete...
				# however... this means the API config wont pick up this action...
				# this is fairly dumb...
			
				# start ASYNC - this must be REST
				#my $packet = api_proto_packet_build("hyper", "sys_clone_async");
				#$packet->{'hyper'}{'src'} = $src_system_data->{'system'};
				#$packet->{'hyper'}{'dst'} = $system_clone->{'clone'};
				
				#log_info_json($fid, "clone async packet", $packet);
				
				#my $src_system = $req->{'hyper'}{'src'};
				#my $dst_system = $req->{'hyper'}{'dst'};
				
				# send
				#my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'srcname'}] create initialized", $fid);
				#$result->{'request'} = $request;
				#$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));

				#log_info_json($fid, "clone async result", $result);
				
				# save to disk
				#my $system_clean = system_rest_config_clean($system_clone->{'clone'});
				#api_rest_obj_config_save($syscfg->{'dir'}, $syscfg->{'type'}, 'system', $system_clean);

				#return packet_build_noencode("1", "success: system config cloned successfully", $fid);
			
			
			
				# need to do the actual things here...
				
				# the system config might not be saved to cluster here!
				
				#my $clone_request = api_hyper_sys_move_async($nodeid, $sysdb->{$sysid}, $clone_result->{'clone'});
							
				# check here if the request is actually processsed by the node!
#					if($clone_request->{'proto'}{'result'} eq "1"){
#					print "$fid cloning succesful\n";
					
#					sysdb_sys_set($result->{'clone'}{'id'}{'id'}, $result->{'clone'});
			
#					print "$fid saving config\n";
#					sysdb_sys_save($result->{'clone'});
					
#					$result = packet_build_noencode("1", "success: cloning request successful", $fid);
#					$result->{'response'} = $clone_request;
#				}
#							else{
#								print "$fid cloning failed!\n";
#								json_encode_pretty($result);
					
#								$result = packet_build_noencode("0", "error: cloning request failed", $fid);
#								$result->{'response'} = $clone_request;
					
					# remove the clone
					# use validate and delete functions here - TODO
#							}			
			
			
				return $result;
			}
			else{
				log_warn($fid, "error: node failed validation");
				return $node_data;
			}
		}
		else{
			log_warn($fid, "error: system [$request->{'proto'}{'name'}] is marked online. cannot move.");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is marked online. cannot clone", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}
}

#
# delete system [JSON-OBJ]
#
sub system_rest_delete($request){
	my $fid = "[system_delete]";
	my $ffid = "SYSTEM|DELETE";

	log_info_json($fid, "deleting system", $request);

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if(!$system_data->{'system'}{'meta'}{'state'}){
			log_info($fid, "success: system [$request->{'proto'}{'name'}] is offline. starting delete.");
			
			# fetch node
			my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				
				my $packet = api_proto_packet_build("hyper", "delete");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				$packet->{'hyper'}{'vm'} = $system_data->{'system'};
				
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] delete initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));

				# check delete succeeded
				if($result->{'response'}{'vm'}{'delete'}{'result'}){
	
					# system has been deleted
					log_info($fid, "success: hypervisor deleted system successfully");
	
					# check if system is present in cluster
					if(defined $system_data->{'system'}{'object'} && defined $system_data->{'system'}{'object'}{'meta'}{'ver'}){
						log_info($fid, "system exists in cluster");
						
						$system_data->{'system'}{'object'}{'delete'} = 1;
						
						my $cluster_update = api_cluster_local_system_del(env_serv_sock_get("cluster"), $system_data->{'system'});
						log_info_json($fid, "cluster delete result", $cluster_update);
						
						if($cluster_update->{'proto'}{'result'} eq "1"){
							log_info($fid, "success: removed system from cluster");
							$result->{'response'}{'api'}{'cluster'} = "success: system removed from cluster";
						}
						else{
							log_warn($fid, "error: failed to remove system from cluster");
							$result->{'response'}{'api'}{'cluster'} = "error: failed to remove from cluster";
						}
					}
					else{
						log_info($fid, "system does not exist in cluster...");
					}
					
					#
					# move config to trash
					#
					my $syscfg = base_system_cfg_get();
					my $sysdir = $syscfg->{'dir'};
					my $trashdir = $syscfg->{'dir'} . "_removed/";
					
					# TODO: Should check if REMOVED exists...
					log_info($fid, "SYSTEM CONFIG [$system_data->{'system'}{'id'}{'cfg'}]");
					log_info($fid, "CONFDIR [$sysdir]");
					log_info($fid, "TRASHDIR [$trashdir]");
					
					my $cfgsrc = $sysdir . $system_data->{'system'}{'id'}{'cfg'};
					my $cfgdst = $trashdir . $system_data->{'system'}{'id'}{'cfg'};
					
					if(file_check($cfgsrc)){
						log_info($fid, "config file exists..");
						$result->{'response'}{'api'}{'cfg'} = "success: config file exists";
					}
					else{
						log_warn($fid, "error: config file not found!");
						$result->{'response'}{'api'}{'cfg'} = "error: config file does not exist!";
					}
					
					my $remove_success = 1;
					
					# move config to trash
					move($cfgsrc, $cfgdst) or do {
						log_error($fid, "ERROR: FAILED TO COPY THE CONFIG TO TRASH DIR!");
						$remove_success = 0;
					};
					
					#copy($cfgsrc, $cfgdst) or do {
					#	log_error($fid, "ERROR: FAILED TO COPY THE CONFIG TO TRASH DIR!");
					#	$remove_success = 0;
					#};
					
					# check if config removal is successful
					if($remove_success){
						$result->{'response'}{'api'}{'cfg_remove'} = "success: moved config to trash";
					}
					else{
						$result->{'response'}{'api'}{'cfg_remove'} = "error: failed to trash config!";
					}
					
					return $result;
				}
				else{
					# system delete failed
					log_warn($fid, "WARNING: SYSTEM DELETE FAILED!");
					$result = packet_build_noencode("0", "error: system delete failed!", $fid);
				}
			}
			else{
				# failed to fetch node
				return $node_data;
			}
		}
		else{
			# system is online
			log_warn($fid, "error: system [$request->{'proto'}{'name'}] is marked online!");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is marked online", $fid);
		}
	}
	else{
		# failed to fetch system
		return $system_data;
	}
}


#
# create system [JSON-OBJ]
#
sub system_rest_storage_add($request){
	my $fid = "[system_storage_add]";
	my $ffid = "SYSTEM|STORAGE|ADD";

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if($system_data->{'system'}{'meta'}{'state'}){
			log_info($fid, "success: system [$request->{'proto'}{'name'}] is not marked online. requesting storage add");
			
			# fetch node
			my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				log_info($fid, "success: system [$request->{'proto'}{'name'}] is offline. starting storage add");
				
				# packet
				my $packet = api_proto_packet_build("hyper", "sys_stor_add");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				$packet->{'hyper'}{'vm'} = $system_data->{'system'};
				$packet->{'hyper'}{'dev'} = $request->{'proto'}{'storage'};
				
				# send
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] storage add initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				return $result;
			}
			else{
				# failed to fetch node
				log_warn($fid, "error: failed to fetch node!");
				return $node_data;
			}

		}
		else{
			# system is marked online
			log_warn($fid, "error: system [$request->{'proto'}{'name'}] is marked online. cannot add storage");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is marked online. cannot add storage", $fid);
		}

	}
	else{
		# failed to fetch system
		return $system_data;
	}

}

#
# create system [JSON-OBJ]
#
sub system_rest_storage_expand($request){
	my $fid = "[system_storage_expand]";
	my $ffid = "SYSTEM|STORAGE|EXPAND";

	# fetch system
	my $system_data = system_rest_validate_get($request->{'proto'}{'name'});
	
	# validate system
	if($system_data->{'proto'}{'result'} eq "1"){
		
		# check system state
		if($system_data->{'system'}{'meta'}{'state'}){
			log_info($fid, "success: system [$request->{'proto'}{'name'}] is not marked online. requesting storage add");
			
			# fetch node
			my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
			
			# validate node
			if($node_data->{'proto'}{'result'} eq "1"){
				# node and system is valid, system is online... continue
				log_info($fid, "success: system [$request->{'proto'}{'name'}] is offline. starting storage add");
				
				# packet
				my $packet = api_proto_packet_build("hyper", "sys_stor_expand");
				$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
				$packet->{'hyper'}{'vm'} = $system_data->{'system'};
				$packet->{'hyper'}{'dev'} = $request->{'proto'}{'storage'};
				
				# send
				my $result = packet_build_noencode("1", "success: system [$request->{'proto'}{'name'}] storage add initialized", $fid);
				$result->{'request'} = $request;
				$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
				
				return $result;
			}
			else{
				# failed to fetch node
				log_warn($fid, "error: failed to fetch node!");
				return $node_data;
			}
		}
		else{
			# system is marked online
			log_warn($fid, "error: system [$request->{'proto'}{'name'}] is marked online. cannot add storage");
			return packet_build_noencode("0", "error: system [$request->{'proto'}{'name'}] is marked online. cannot add storage", $fid);
		}

	}
	else{
		# failed to fetch system
		return $system_data;
	}

}


#
# add system storage [JSON-OBJ]
#
#sub system_rest_storage_add_ORIG($request){
#	my $fid = "[system_storage_add]";
#	my $ffid = "SYSTEM|STORAGE|ADD";
	
#	log_info_json($fid, "adding system storage", $request);
	
	
	
	#my $packet = api_proto_packet_build("hyper", "sys_stor_add");
	#$packet->{'hyper'}{'id'} = $sysid;
	#$packet->{'hyper'}{'vm'} = $sysdata;
	#$packet->{'hyper'}{'dev'} = $dev;
	#$response = api_proto_ssl_send($node, $packet, $fid);	
	
#	return packet_build_noencode("1", "reached system storage add!", $fid);
#}

#
# expand system storage [JSON-OBJ]
#
#sub system_rest_storage_expand_ORIG($request){
#	my $fid = "[system_storage_expand]";
#	my $ffid = "SYSTEM|STORAGE|EXPAND";
#
#	log_info_json($fid, "expanding system storage", $request);
	
	#my $packet = api_proto_packet_build("hyper", "sys_stor_expand");
	#$packet->{'hyper'}{'id'} = $sysid;
	#$packet->{'hyper'}{'vm'} = $sysdata;
	#$packet->{'hyper'}{'dev'} = $dev;
	#$response = api_proto_ssl_send($node, $packet, $fid);
	
#	return packet_build_noencode("1", "reached system storage expand!", $fid);
#}


#
#
#
#sub api_rest_system_update($packet){
#	my $fid = "rest-system-update-test";
#	
#	print "### RECEIVED POST PACKET ###\n";
#	json_encode_pretty($packet);
#	
#	return packet_build_noencode("1", "reached the POST FUNCTION!", $fid);
#}

# getting nodes 
#sub api_rest_system_update_NEW($request) {
#	my $fid = "[api_rest_system_update]";
#	
#	# Validate input
#	unless ($request->{proto}{name}) {
#		return packet_build_noencode(0, "System name required", $fid);
#	}
#
#	# Process update through cluster
#	my $result = local_cluster_obj_update(
#		env_serv_sock_get('cluster'),
#		'system',
#		$request->{proto}{name},
#		$request->{proto}{config}
#	);
#
#	if ($result->{proto}{result} eq "1") {
#		return packet_build_noencode(1, "System updated successfully", $fid);
#	} else {
#		return packet_build_noencode(0, "Failed to update system", $fid);
#	}
#}

1;
