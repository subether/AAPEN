#
# ETHER|AAPEN|API - LIB|REST
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
# ping api [JSON-OBJ]
#
sub api_rest_ping($request){
	my $fid = "[api_ping]";
	log_info($fid, "received ping");
	return packet_build_noencode("1", "success: pong", $fid);
}

#
# get api metadata [JSON-OBJ]
#
sub api_rest_db_meta($request){
	my $fid = "[api_db_meta]";
	my $ffid = "DB|META";
	
	my $meta = api_cluster_local_meta_get(env_serv_sock_get('cluster'));
	
	if($meta->{'proto'}{'result'} eq "1"){
		my $result = packet_build_noencode("1", "success: returning cluster metadata", $fid);
		$result->{'request'} = $request;
		$result->{'response'}{'meta'} = $meta->{'meta'};
		return $result;
	}
	else{
		log_warn($fid, "error: failed to fetch metadata from cluster");
		return packet_build_noencode("0", "error: failed to fetch metadata from cluster", $fid);
	}
}

#
# get api database [JSON-OBJ]
#
sub api_rest_db_get($request){
	my $fid = "[api_db_get]";
	my $ffid = "DB|GET";
	
	my $db = api_cluster_local_db_get(env_serv_sock_get('cluster'));
	
	if($db->{'proto'}{'result'} eq "1"){
		log_info($ffid, "success: returning db");
		
		my $result = packet_build_noencode("1", "success: returning db", $fid);
		$result->{'request'} = $request;
		$result->{'response'}{'db'} = $db->{'db'};
		return $result;
	}
	else{
		log_warn($ffid, "error: failed to fetch db from cluster");
		return packet_build_noencode("0", "error: failed to fetch db from cluster", $fid);
	}
}

#
# get object from api [JSON-OBJ]
#
sub api_rest_obj_get($object, $request){
	my $fid = "[api_obj_get]";
	my $ffid = "OBJ|GET";
	
	# check for valid name
	if(defined $request->{'proto'}{'name'} && string_validate($request->{'proto'}{'name'})){
		log_debug($fid, "success: name defined and valid");
		my $obj = api_cluster_local_obj_get(env_serv_sock_get("cluster"), $object, $request->{'proto'}{'name'});
		
		if($obj->{'proto'}{'result'} eq "1"){
			log_info($ffid, "success: returning object [$request->{'proto'}{'name'}]");
			
			my $result = packet_build_noencode("1", "success: returning object", $fid);
			$result->{'request'} = $request;
			$result->{'response'} = $obj;
			return $result;
		}
		else{
			log_warn($ffid, "error: failed to fetch object from cluster");
			return packet_build_noencode("0", "error: failed to fetch object from cluster", $fid);
		}		
	}
	else{
		log_warn($ffid, "error: object name must be defined");
		return packet_build_noencode("0", "error: object name must be defined", $fid);
	}
}

#
# get object metadata from api [JSON-OBJ]
#
sub api_rest_obj_meta_get($object, $request){
	my $fid = "[api_obj_meta]";
	my $ffid = "OBJ|META";
	
	my $meta = api_cluster_local_meta_get(env_serv_sock_get('cluster'));
	
	if($meta->{'proto'}{'result'} eq "1"){
		log_info($ffid, "success: returning cluster metadata");
		my $result = packet_build_noencode("1", "success: returning cluster metadata", $fid);
		$result->{'request'} = $request;
		$result->{'response'}{'meta'}{$object} = $meta->{'meta'}{$object};
		return $result;
	}
	else{
		log_warn($ffid, "error: failed to fetch metadata from cluster");
		return packet_build_noencode("0", "error: failed to fetch metadata from cluster", $fid);
	}
}

#
# get object database from api [JSON-OBJ]
#
sub api_rest_obj_db_get($object, $request){
	my $fid = "[api_obj_db_get]";
	my $ffid = "OBJ|DB|GET";
	
	my $db = api_cluster_local_db_get(env_serv_sock_get('cluster'));
	
	if($db->{'proto'}{'result'} eq "1"){
		my $result = packet_build_noencode("1", "success: returning object db", $fid);
		$result->{'request'} = $request;
		$result->{'response'}{'db'}{$object} = $db->{'db'}{$object};
		return $result;
	}
	else{
		log_warn($fid, "error: failed to fetch db from cluster");
		return packet_build_noencode("0", "error: failed to fetch db from cluster", $fid);
	}
}

#
# get service metadata from api [JSON-OBJ]
#
sub api_rest_srv_meta_get($object, $request){
	my $fid = "[api_obj_meta]";
	my $ffid = "OBJ|META";
	
	my $meta = api_cluster_local_meta_get(env_serv_sock_get('cluster'));
	
	if($meta->{'proto'}{'result'} eq "1"){
		my $result = packet_build_noencode("1", "success: returning cluster metadata", $fid);
		$result->{'request'} = $request;
		
		if($object eq "all"){
			$result->{'response'}{'meta'}{'service'} = $meta->{'meta'}{'service'};
		}
		else{
			$result->{'response'}{'meta'}{'service'}{$object} = $meta->{'meta'}{'service'}{$object};
		}
		
		return $result;
	}
	else{
		log_warn($fid, "error: failed to fetch metadata from cluster");
		return packet_build_noencode("0", "error: failed to fetch metadata from cluster", $fid);
	}
}

#
# get service database from api [JSON-OBJ]
#
sub api_rest_srv_get($service, $request){
	my $fid = "[api_srv_get]";
	my $ffid = "SRV|GET";
	
	# check for valid name
	if(defined $request->{'proto'}{'name'} && string_validate($request->{'proto'}{'name'})){
		log_info($fid, "success: name defined and valid");
		my $srv = api_cluster_local_service_get(env_serv_sock_get("cluster"), $service, $request->{'proto'}{'name'});
		
		if($srv->{'proto'}{'result'} eq "1"){
			my $result = packet_build_noencode("1", "success: returning service", $fid);
			$result->{'request'} = $request;
			$result->{'response'} = $srv;
			return $result;
		}
		else{
			log_warn($fid, "error: failed to fetch object from cluster");
			return packet_build_noencode("0", "error: failed to fetch object from cluster", $fid);
		}		
	}
	else{
		log_warn($fid, "error: object name must be defined");
		return packet_build_noencode("0", "error: object name must be defined", $fid);
	}
}

#
# load object config from api to cluster [JSON-OBJ]
#
sub api_rest_obj_config_load($cfgdir, $cfgtype, $object, $request){
	my $fid = "[api_obj_config_load]";
	my $ffid = "OBJ|CONFIG|LOAD";
	
	$cfgtype = "*" . $cfgtype;
	my $cfg_count = 0;
	my $cfg_known = 0;
	my $cfg_unknown = 0;
		
	# fetch db from cluster
	my $db = api_cluster_local_db_get(env_serv_sock_get('cluster'));
	
	if($db->{'proto'}{'result'} eq "1"){
		log_info($fid, "fetched cluster db successfully");
	}
	else{
		log_warn($fid, "failed to fetch db from cluster!");
	}
	
	# build list of config files
	my @file_list = file_list($cfgdir, $cfgtype);
	
	# process config files
	foreach my $obj_config (@file_list){	
		# load object config from file
		my $objdata = json_file_load($obj_config);
		
		# check object name
		if(defined $objdata->{'id'}{'name'}){
			# check if object present in cluster
			if(index_find($db->{'db'}{$object}{'index'}, $objdata->{'id'}{'name'})){
				log_info($ffid, "config [$obj_config] name [$objdata->{'id'}{'name'}] - [KNOWN]");
				# should check for overrides here
				$cfg_known++;
			}
			else{
				# push config to cluster
				log_info($ffid, "config [$obj_config] name [$objdata->{'id'}{'name'}] - [UNKNOWN]");				
				api_rest_obj_cluster_set($objdata);
				$cfg_unknown++;
			}
			$cfg_count++;
		}
		else{
			log_warn($ffid, "config [$obj_config] name not defined!");
			return packet_build_noencode("0", "error: config [$obj_config] name not defined", $fid);
		}
	}	

	return packet_build_noencode("1", "success: object [$object] known cfg [$cfg_known] unknown [$cfg_unknown]. loaded [$cfg_count] configs", $fid);
}

#
# save object config from api [JSON-OBJ]
#
sub api_rest_obj_config_save($cfgdir, $cfgtype, $object, $config){
	my $fid = "[api_obj_config_save]";
	my $ffid = "OBJ|CONFIG|SAVE";
	
	log_info($ffid, "saving object [$object] dir [$cfgdir] type [$cfgtype] name [$config->{'id'}{'name'}]");
	#log_debug_json($fid, "saving object config: dir [$cfgdir] type [$cfgtype] object [$object]", $config);
	
	my $cfg_file = $cfgdir . $config->{'id'}{'name'} . $cfgtype;
	log_info($ffid, "config file [$cfg_file]");
	json_file_save($cfg_file, $config);
	
	return packet_build_noencode("1", "success: saved config [$cfg_file] to disk", $fid);
}

#
# push object to cluster [JSON-OBJ]
#
sub api_rest_obj_cluster_set($object){
	my $fid = "[api_obj_cluster_set]";
	my $ffid = "OBJ|SET";
	
	log_info($fid, "pushing object to cluster: type [$object->{'object'}{'type'}] name [$object->{'id'}{'name'}]");
	log_debug_json($fid, "pushing object to cluster: type [$object->{'object'}{'type'}] name [$object->{'id'}{'name'}]", $object);
	
	my $packet = api_proto_packet_build("cluster", "obj_set");
	$packet->{'data'} = $object;
	$packet->{'cluster'}{'obj'} = $object->{'object'}{'type'};
	$packet->{'cluster'}{'key'} = $object->{'id'}{'name'};
	
	my $result = api_socket_send(env_serv_sock_get("cluster"), $packet, $fid);
	return $result;
}

#
# check object name helper [JSON-OBJ]
#
sub api_rest_check_obj_name($obj_db, $obj_name){
	if(index_find($obj_db->{'index'}, $obj_name)){
		return 1;
	}
	else{
		return 0;
	}
}

#
# check object id helper [JSON-OBJ]
#
sub api_rest_check_obj_id($obj_db, $obj_id_match){
	my @obj_index = index_split($obj_db->{'index'});
	
	foreach my $obj_id (@obj_index){
		if($obj_id_match eq $obj_db->{'db'}{$obj_id}{'id'}{'id'}){
			return 1;
		}
	}
	
	return 0;
}

#
# get file from api [JSON-OBJ]
#
sub api_rest_file_get($packet){
	my $fid = "[api_file_get]";
	my $ffid = "FILE|GET";
	
	log_info($fid, "processing file get request");
	if(env_debug()){ json_encode_pretty($packet); }
	
	$packet = packet_build_noencode("1", "success: reached file get", $fid);
	
	my $file = '/eth/node/lithium/md0/cfs/silver/log/storage.log';
	
	if(file_check($file)){
		log_info($fid, "file exists: [$file]");
	}
	else{
		log_info($fid, "file does not exist: [$file]");
	}
	
	my $file_path = path($file);
	my $stats = $file_path->stat->size;
	log_info($fid, "file size: [$stats] bytes");
	
	my $file_data = $file_path->slurp;
	
	return ($packet, $file_data);
}

1;
