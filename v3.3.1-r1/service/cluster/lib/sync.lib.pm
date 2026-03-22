#
# ETHER|AAPEN|CLUSTER - LIB|SYNC
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
# received delta sync [NULL]
#
sub cluster_rx_sync_delta($message){
	my $fid = "[cluster_rx_sync_delta]";
	my $ffid = "RX|SYNC|DELTA";

	# check for reflection
	if(get_cluster_uid() ne $message->{'cluster'}{'src'}{'uid'}){
		# not reflection, process request
		my @delta_index = index_split($message->{'data'}{'index'});
		
		log_debug($ffid, "self uid [" . get_cluster_uid() . "] src uid [" . $message->{'cluster'}{'src'}{'uid'} . "] node [" . $message->{'cluster'}{'src'}{'name'} . "] deltas [" . scalar(@delta_index) . "]");

		foreach my $delta (@delta_index){
			log_debug($ffid, "delta id [$delta] request [$message->{'data'}{$delta}{'cluster'}{'req'}]");
			
			# process delta
			cluster_rx_sync_delta_proto($message->{'cluster'}, $message->{'data'}{$delta});
			
			# push delta to buffer
			if(get_zmq_server()){ zmq_server_delta_buffer_set($message->{'data'}{$delta}); };
			if(get_zmq_sync()){ zmq_sync_delta_buffer_set($message->{'data'}{$delta}); };
		}
	}
	else{
		# mcast reflection. ignore.
		log_debug($ffid, "packet reflection. origin is self. discarding packets!");
	}
}

#
# process object deltas [NULL]
# 
sub cluster_rx_sync_delta_proto($owner, $delta){
	my $fid = "[cluster_rx_sync_delta_proto]";
	my $ffid = "RX|SYNC|DELTA|PROTO";
	
	my $db_meta = db_meta_get();
	
	log_debug($ffid, "[RX] req [$delta->{'cluster'}{'req'}] obj [$delta->{'cluster'}{'obj'}] key [$delta->{'cluster'}{'key'}] id [$delta->{'cluster'}{'id'}] src [$owner->{'src'}{'name'}]");

	# check if local object
	if(($owner->{'src'}{'name'} ne config_node_name_get()) || (get_cluster_type() eq "server")){
		log_debug($ffid, "[RX] req [$delta->{'cluster'}{'req'}] obj [$delta->{'cluster'}{'obj'}] key [$delta->{'cluster'}{'key'}] id [$delta->{'cluster'}{'id'}] src [$owner->{'src'}{'name'}]: origin [REMOTE]");

		# meta set
		if($delta->{'cluster'}{'req'} eq "obj_meta_set"){
			cluster_rx_sync_meta($delta, $db_meta);
		}
		
		# object set
		if($delta->{'cluster'}{'req'} eq "obj_set"){
			
			# object or service
			if($delta->{'cluster'}{'obj'} eq "service"){
				# service
				cluster_rx_sync_delta_service($owner, $db_meta, $delta);
			}
			else{
				# object type
				cluster_rx_sync_delta_object($owner, $db_meta, $delta);
			}
		}
		
		# delete object request
		if($delta->{'cluster'}{'req'} eq "obj_del"){
			cluster_obj_del($delta, 0, "remote");
		}
	}
	else{
		log_debug($ffid, "[RX] req [$delta->{'cluster'}{'req'}] obj [$delta->{'cluster'}{'obj'}] key [$delta->{'cluster'}{'key'}] id [$delta->{'cluster'}{'id'}] src [$owner->{'src'}{'name'}]: context [LOCAL] - NOT SERVER - discarding delta");

	}
}

#
# cluster rx delta service sync [NULL]
#
sub cluster_rx_sync_delta_service($owner, $db_meta, $delta){
	my $fid = "[cluster_rx_sync_delta_service]";
	my $ffid = "RX|SYNC|DELTA|SRV";
	
	my $object = $delta->{'cluster'}{'obj'};
	my $key = $delta->{'cluster'}{'key'};
	my $id = $delta->{'cluster'}{'id'};
	my $srv_name = $delta->{'data'}{'config'}{'service'};
	my $srv_node = $delta->{'data'}{'config'}{'name'};
	
	# check for reflections
	if((defined $delta->{'data'}{'object'}{'meta'}{'owner'}{'name'}) && ($delta->{'data'}{'object'}{'meta'}{'owner'}{'name'} ne config_node_name_get())){	
	
		if(index_find($db_meta->{'service'}{$srv_name}{'index'}, $srv_node)){
			
			# get service
			my $cdbsrv = api_cdb_local_service_get(env_serv_sock_get("cdb"), $srv_name, $srv_node);
		
			if($cdbsrv->{'proto'}{'result'} eq "1"){
				# object found
				
				# check version number
				if($cdbsrv->{$object}{$srv_name}{$srv_node}{'object'}{'meta'}{'ver'} < $delta->{'data'}{'object'}{'meta'}{'ver'}){
					log_debug($ffid, "$ffid [VERSION CHECK] [NEWER] - curr [$cdbsrv->{$object}{$srv_name}{$srv_node}{'object'}{'meta'}{'ver'}] recv [$delta->{'data'}{'object'}{'meta'}{'ver'}] src [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] srv [$srv_name]");
					cluster_rx_sync_serv($delta, $db_meta, $owner);
				}
				elsif($cdbsrv->{$object}{$srv_name}{$srv_node}{'object'}{'meta'}{'ver'} eq $delta->{'data'}{'object'}{'meta'}{'ver'}){
					log_debug($ffid, "$ffid [VERSION CHECK] [NEWER] - curr [$cdbsrv->{$object}{$srv_name}{$srv_node}{'object'}{'meta'}{'ver'}] recv [$delta->{'data'}{'object'}{'meta'}{'ver'}] src [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] srv [$srv_name]");
					cluster_rx_sync_serv($delta, $db_meta, $owner);
				}
				else{
					log_warn($ffid, "[VERSION CHECK] [OLDER] - curr [$cdbsrv->{$object}{$srv_name}{$srv_node}{'object'}{'meta'}{'ver'}] recv [$delta->{'data'}{'object'}{'meta'}{'ver'}] src [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] srv [$srv_name]");
					cluster_rx_sync_serv($delta, $db_meta, $owner);
				}
			}
			else{
				# object not found
				log_error($ffid, "[CDB CHECK] error: failed to fetch object from CDB!");
				cluster_rx_sync_serv($delta, $db_meta, $owner);
			}
		}
		else{
			log_info($ffid, "[INDEX CHECK] service [$srv_name] node [$srv_node] not in index. adding.");
			cluster_rx_sync_serv($delta, $db_meta, $owner);
		}
	}
	else{
		if($delta->{'data'}{'object'}{'meta'}{'owner_name'} eq config_node_name_get()){
			log_debug($ffid, "[OWNER CHECK] [REFLECTION] owner [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] self [" . config_node_name_get() . "]");
		}
		else{
			log_error($ffid, "[OWNER CHECK] error: no owner defined!");
			json_encode_pretty($delta->{'data'});
		}
	}

}

#
# cluster rx delta object sync [NULL]
#
sub cluster_rx_sync_delta_object($owner, $db_meta, $delta){
	my $fid = "[cluster_rx_sync_delta_object]";
	my $ffid = "RX|SYNC|DELTA|OBJ";
	
	my $object = $delta->{'cluster'}{'obj'};
	my $key = $delta->{'cluster'}{'key'};
	my $id = $delta->{'cluster'}{'id'};
	
	# check for reflections
	if((defined $delta->{'data'}{'object'}{'meta'}{'owner'}{'name'}) && ($delta->{'data'}{'object'}{'meta'}{'owner'}{'name'} ne config_node_name_get())){	
		
		if(index_find($db_meta->{$object}{'index'}, $key)){
			
			# fetch from CDB
			my $cdbobj = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);
			
			if($cdbobj->{'proto'}{'result'} eq "1"){
				
				# cdb version check
				if(defined $cdbobj->{$object}{'object'}{'meta'}{'ver'}){
					
					# check for delta version
					if(defined $delta->{'data'}{'object'}{'meta'}{'ver'}){
						
						# check for version number
						if($cdbobj->{$object}{'object'}{'meta'}{'ver'} < $delta->{'data'}{'object'}{'meta'}{'ver'}){
							log_debug($ffid, "[VERSION CHECK] [NEWER] curr [$cdbobj->{$object}{'object'}{'meta'}{'ver'}] recv [$delta->{'data'}{'object'}{'meta'}{'ver'}] src [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] obj [$object] name [$delta->{'data'}{'id'}{'name'}]");
							cluster_rx_sync_obj($delta, $db_meta, $owner);
						}
						elsif($cdbobj->{$object}{'object'}{'meta'}{'ver'} eq $delta->{'data'}{'object'}{'meta'}{'ver'}){
							log_debug($ffid, "[VERSION CHECK] [CURRENT] curr [$cdbobj->{$object}{'object'}{'meta'}{'ver'}] recv [$delta->{'data'}{'object'}{'meta'}{'ver'}] src [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] obj [$object] name [$delta->{'data'}{'id'}{'name'}]");
							cluster_rx_sync_obj($delta, $db_meta, $owner);
						}
						else{
							# should probably do something more here
							log_warn($ffid, "[VERSION CHECK] [OLDER] curr [$cdbobj->{$object}{'object'}{'meta'}{'ver'}] recv [$delta->{'data'}{'object'}{'meta'}{'ver'}] src [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] obj [$object] name [$delta->{'data'}{'id'}{'name'}]");
							cluster_rx_sync_obj($delta, $db_meta, $owner);
						}
					}
					else{
						# delta missing version tag (should never happen)
						log_warn($ffid, "[CLUSTER VERSION CHECK] warning: received object does not have version tag!");
						json_encode_pretty($delta);
					}
				}
				else{
					# cdb object missing version tag (expected on CDB/CLUSTER and CLI pushed objects)
					log_warn($ffid, "[CDB VERSION CHECK] warning: local object does not have version tag!");
					cluster_rx_sync_obj($delta, $db_meta, $owner);
				}
			}
			else{
				# failed to fetch object from CDB
				log_warn($ffid, "[CDB CHECK] error: failed to fetch object from CDB!");
				cluster_rx_sync_obj($delta, $db_meta, $owner);
			}
		}
		else{
			# object does not exist, add it
			log_info($ffid, "[INDEX CHECK] NEW: object [$object] key [$key] not in index. adding...");
			cluster_rx_sync_obj($delta, $db_meta, $owner);
		}
	}
	else{
		if($delta->{'data'}{'object'}{'meta'}{'owner_name'} eq config_node_name_get()){
			log_debug($ffid, "[OWNER CHECK] [REFLECTION] owner [$delta->{'data'}{'object'}{'meta'}{'owner_name'}] self [" . config_node_name_get() . "]");
		}
		else{
			log_warn($ffid, "[OWNER CHECK] error: no owner defined!");
			#json_encode_pretty($delta->{'data'});
		}
	}
	
}

#
# process sobject sync deltas [NULL]
#
sub cluster_rx_sync_obj($delta, $db_meta, $owner){
	my $fid = "[cluster_rx_sync_obj]";

	my $object = $delta->{'cluster'}{'obj'};
	my $key = $delta->{'cluster'}{'key'};
	my $id = $delta->{'cluster'}{'id'};	
	
	# index
	$db_meta->{$object}{'local'} = index_del($db_meta->{$object}{'local'}, $key);
	$db_meta->{$object}{'remote'} = index_add($db_meta->{$object}{'remote'}, $key);
	$db_meta->{$object}{'index'} = index_add($db_meta->{$object}{'index'}, $key);
	db_meta_set($db_meta);
	
	my $cdbobj = $delta->{'data'};
	$cdbobj->{'object'}{'meta'}{'cluster'} = $delta->{'cluster'}{'meta'};
	$cdbobj->{'object'}{'meta'}{'src'} = $owner->{'src'};
	
	api_cdb_obj_set(env_serv_sock_get("cdb"), $object, $cdbobj);
}

#
# process service sync deltas [NULL]
#
sub cluster_rx_sync_serv($delta, $db_meta, $owner){
	my $fid = "[cluster_rx_sync_serv]";

	my $object = $delta->{'cluster'}{'obj'};
	my $key = $delta->{'cluster'}{'key'};
	my $id = $delta->{'cluster'}{'id'};
	my $srv_name = $delta->{'data'}{'config'}{'service'};
	my $srv_node = $delta->{'data'}{'config'}{'name'};
	
	# index
	$db_meta->{'service'}{$srv_name}{'index'} = index_add($db_meta->{'service'}{$srv_name}{'index'}, $key);
	$db_meta->{'service'}{$srv_name}{'remote'} = index_add($db_meta->{'service'}{$srv_name}{'remote'}, $key);
	db_meta_set($db_meta);

	my $cdbobj = $delta->{'data'};
	$cdbobj->{'object'}{'meta'}{'meta'} = $delta->{'cluster'}{'meta'};
	$cdbobj->{'object'}{'meta'}{'src'} = $owner->{'src'};

	api_cdb_local_service_set(env_serv_sock_get("cdb"), $cdbobj);
}

#
# process metadata sync deltas [NULL]
#
sub cluster_rx_sync_meta($delta, $db_meta){
	my $fid = "[cluster_rx_sync_meta]";
	my $ffid = "RX|SYNC|META";

	my $object = $delta->{'cluster'}{'obj'};
	my $key = $delta->{'cluster'}{'key'};
	my $id = $delta->{'cluster'}{'id'};

	# only process metadata for valid objects
	if($object eq "system" || $object eq "storage" || $object eq "network"){
		
		# check if known
		if(index_find($db_meta->{$object}{'index'}, $key)){

			# fetch object from cdb
			my $cdbtmp = api_cdb_local_obj_get(env_serv_sock_get("cdb"), $object, $key);
			
			if($cdbtmp->{'proto'}{'result'} eq "1"){
			
				my $cdbobj = $cdbtmp->{$object};
				$cdbobj->{'meta'}{'stats'}{$id} = $delta->{'data'};
				
				api_cdb_obj_set(env_serv_sock_get("cdb"), $object, $cdbobj);
			}
		}
		else{
			log_warn($ffid, "object [$object] key [$key] is unknown. cannot add metadata");
		}
	}
	else{
		log_warn($ffid, "object [$object] does not support metadata");
	}
}

#
# received full sync [NULL] - DEPRECATED
#
sub cluster_rx_sync_full($message){
	my $fid = "[cluster_rx_sync_full]";
	my $ffid = "CLUSTER|RX|SYNC|FULL";

	log_info($ffid, "self uid [" . get_cluster_uid() . "] src uid [$message->{'cluster'}{'src'}{'uid'}] node [$message->{'cluster'}{'src'}{'name'}]");
	
	# check for reflection
	if(get_cluster_uid() ne $message->{'cluster'}{'src'}{'uid'}){
		# not reflection
	}
	else{
		# reflection
		log_debug($ffid, "packet reflection. origin is self. dicarding.");
	}
}

1;
