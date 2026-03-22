#
# ETHER|AAPEN|CDB - LIB|DB
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


my $db;
my $obj_index = "system;node;network;container;storage;service;element;group";
my $srv_index = "hypervisor;network;framework;monitor;storage";


#
# initialize database [NULL]
#
sub cdb_init(){
	
	# services
	$db->{'service'}{'index'} = $srv_index;
	my @srv_index = index_split($db->{'service'}{'index'});

	# objects
	$db->{'object'}{'obj_index'} = $obj_index;
	my @obj_index = index_split($db->{'object'}{'obj_index'});
	
	# metadata
	$db->{'cdb'}{'version'} = env_version();
	
	# generate database
	foreach my $object (@obj_index){
		if($object eq "service"){
			# services
			foreach my $service (@srv_index){
				$db->{'service'}{$service}{'index'} = "";
				$db->{'service'}{$service}{'meta'} = {};
				$db->{'service'}{$service}{'db'} = {};
			}
			$db->{'service'}{'meta'} = {};
		}
		else{
			# object
			$db->{$object}{'index'} = "";
			$db->{$object}{'meta'} = {};
			$db->{$object}{'db'} = {};
		}
	}
}

#
# flush current db [JSON-STR]
#
sub cdb_flush(){
	my $fid = "FLUSH";
	my $return = packet_build_noencode("1", "success: flushed cdb", $fid);
	
	$db = {};
	cdb_init();
	
	return json_encode($return);
}

#
# return full db [JSON-STR]
#
sub cdb_get(){
	my $fid = "GET";
	my $return = packet_build_noencode("1", "success: returning cdb", $fid);
	$return->{'db'} = $db;
	return json_encode($return);
}

#
# get database metadata [JSON-STR]
#
sub cdb_meta_get(){
	my $fid = "META|GET";
	
	# build packet
	my $return = packet_build_noencode("1", "success: returning cdb metadata", $fid);
	my $meta = {};

	#
	# objects
	#
	my @obj_index = index_split($obj_index);

	foreach my $object (@obj_index){
		$meta->{$object}{'index'} = $db->{$object}{'index'};
		$meta->{$object}{'meta'} = $db->{$object}{'meta'};	
	}

	#
	# services
	#
	my @srv_index = index_split($srv_index);

	foreach my $service (@srv_index){
		$meta->{'service'}{$service}{'index'} = $db->{'service'}{$service}{'index'};
		$meta->{'service'}{$service}{'meta'} = $db->{'service'}{$service}{'meta'};
	}

	$return->{'meta'} = $meta;
	return json_encode($return);
}

#
# set object data [JSON-STR]
# 
sub cdb_obj_set($request){
	my $fid = "OBJ|SET";
	my $object = $request->{'cdb'}{'obj'};
	my $key = $request->{'cdb'}{'key'};
	my $id = $request->{'cdb'}{'id'};
	
	# header
	log_debug($fid, "object [$object] key [$key] id [$id]");

	my $objchk = cdb_obj_check($object);
	if($objchk->{'proto'}{'result'} eq "1"){
	
		# validate 
		if((defined $object && $object ne "") && (defined $key && $key ne "")){
		
			#
			# service
			#
			if($object eq "service"){
				my $service = $request->{'data'}{'config'}{'service'};
				my $node = $request->{'data'}{'config'}{'name'};
				
				# check index
				if(index_find($db->{$object}{$service}{'index'}, $node)){
					# in index
					
					# data
					$db->{$object}{$service}{'db'}{$node} = $request->{'data'};
					
					# metadata
					$db->{$object}{$service}{'meta'}{$node}{'ver'}++;
					$db->{$object}{$service}{'meta'}{$node}{'date'} = date_get();
					
					log_debug($fid, "service [$service] node [$node] updated");
					return packet_build_encode("1", "service [$service] node [$node] updated", $fid);
				}
				else{
					# not in index
					
					# index
					$db->{$object}{$service}{'index'} = index_add($db->{$object}{$service}{'index'}, $node);

					# data
					$db->{$object}{$service}{'db'}{$node} = $request->{'data'};
					
					# metadata
					$db->{$object}{$service}{'meta'}{$node}{'ver'} = 0;
					$db->{$object}{$service}{'meta'}{$node}{'date'} = date_get();
					
					log_debug($fid, "service [$service] node [$node] added");
					return packet_build_encode("1", "service [$service] node [$node] added", $fid);
				}
			}
			else{
				#
				# object
				#

				if(index_find($db->{$object}{'index'}, $key)){
					# in index
							
					# data					
					$db->{$object}{'db'}{$key} = $request->{'data'};
					
					# metadata
					$db->{$object}{'meta'}{$key}{'ver'}++;
					$db->{$object}{'meta'}{$key}{'date'} = date_get();
					
					log_debug($fid, "object [$object] key [$key] updated");
					return packet_build_encode("1", "object [$object] key [$key] updated", $fid);
				}
				else{
					# not in index
					
					# index
					$db->{$object}{'index'} = index_add($db->{$object}{'index'}, $key);
						
					# data
					$db->{$object}{'db'}{$key} = $request->{'data'};
					
					# metadata
					$db->{$object}{'meta'}{$key}{'ver'} = 0;
					$db->{$object}{'meta'}{$key}{'date'} = date_get();
					
					log_debug($fid, "object [$object] key [$key] added");
					return packet_build_encode("1", "object [$object] key [$key] added", $fid);
				}

			}
		}
		else{
			log_warn($fid, "object params missing!");
			return packet_build_encode("0", "error: object params missing", $fid);
		}
	}
	else{
		log_warn($fid, "invalid object type [$object]");
		return $objchk;
	}
}

#
# get object [JSON-STR]
# 
sub cdb_obj_get($request){
	my $fid = "OBJ|GET";
	my $object = $request->{'cdb'}{'obj'};
	my $key = $request->{'cdb'}{'key'};
	my $result;
	my $id = "";
	
	if(defined $request->{'cdb'}{'id'}){ $id = $request->{'cdb'}{'id'} };
	log_debug($fid, "object [$object] key [$key] id [$id]");
	my $objchk = cdb_obj_check($object);
	
	if($objchk->{'proto'}{'result'} eq "1"){
		
		if(index_find($db->{$object}{'index'}, $key)){
			# index found
			$result = packet_build_noencode("1", "succes: returning object", $fid);
			
			if($object eq "service"){	
				# service			
				if(defined $id){
					if(index_find($db->{$object}{$key}{'index'}, $id)){
						$result->{$object}{$key}{$id} = $db->{$object}{$key}{'db'}{$id};
						$result->{$object}{$key}{$id}{'object'}{'cdb'} = $db->{$object}{$key}{'meta'}{$id};
					}
					else{
						$result = packet_build_noencode("0", "fail: object [$object] key [$key] id [$id] not in index", $fid);
						log_warn($fid, "object [$object] key [$key] id [$id] not in index");
					}
				}
				else{
					# 
					$result->{$object}{$key} = $db->{$object}{$key};
					$result->{$object}{$key}{'object'}{'cdb'} = $db->{$object}{'meta'}{$key};
				}
			}
			else{
				# object
				$result->{$object} = $db->{$object}{'db'}{$key};
				$result->{$object}{'object'}{'cdb'} = $db->{$object}{'meta'}{$key};
			}
		}
		else{
			# not found
			log_warn($fid, "object [$object] key [$key] id [$id] not in index");
			$result = packet_build_noencode("0", "fail: object [$object] with key [$key] not in index", $fid);
		}
	}
	else{
		log_warn($fid, "invalid object type [$object]");
		$result = $objchk;
	}
	
	return json_encode($result);
}

#
# get object [JSON-STR]
# 
sub cdb_obj_del($request){
	my $fid = "OBJ|DEL";
	my $result;
	my $object = $request->{'cdb'}{'obj'};
	my $key = $request->{'cdb'}{'key'};
	my $id = "";
	
	if(defined $request->{'cdb'}{'id'}){ $id = $request->{'cdb'}{'id'} };
	log_debug($fid, "object [$object] key [$key] id [$id]");

	my $objchk = cdb_obj_check($object);
	if($objchk->{'proto'}{'result'} eq "1"){
		
		if(index_find($db->{$object}{'index'}, $key)){
			# index found

			if($object eq "service"){	
				# service			
				if(defined $id){
					if(index_find($db->{$object}{$key}{'index'}, $id)){
						delete $db->{$object}{$key}{'db'}{$id};
						delete $db->{$object}{$key}{'meta'}{$id};
						$db->{$object}{$key}{'index'} = index_del($db->{$object}{$key}{'index'}, $id);
						$result = packet_build_noencode("1", "succes: deleted service [$key] node [$id]", $fid);
					}
					else{
						$result = packet_build_noencode("0", "fail: object [$object] key [$key] id [$id] not in index", $fid);
						log_warn($fid, "object [$object] key [$key] id [$id] not in index");
					}
				}
				else{
					# service id not defined
					$result = packet_build_noencode("0", "fail: service id not defined index", $fid);
					log_warn($fid, "service [$key] not defined index");
				}
			}
			else{
				# delete object, meta and remove from index
				delete $db->{$object}{'db'}{$key};
				delete $db->{$object}{'meta'}{$key};
				$db->{$object}{'index'} = index_del($db->{$object}{'index'}, $key);
				log_info($fid, "deleted object [$object] name [$key]");
				$result = packet_build_noencode("1", "succes: deleted object [$object] name [$key]", $fid);
			}
		}
		else{
			# not found
			log_warn($fid, "object [$object] with key [$key] not in index");
			$result = packet_build_noencode("0", "fail: object [$object] with key [$key] not in index", $fid);
		}
	}
	else{
		log_warn($fid, "invalid object type [$object]");
		$result = $objchk;
	}
	
	return json_encode($result);
}

#
# check for valid object [JSON-OBJ]
#
sub cdb_obj_check($obj){
	my $fid = "[cdb_obj_check]";
		
	if(index_find($db->{'object'}{'obj_index'}, $obj)){
		return packet_build_noencode("1", "success: valid object type", $fid);
	}
	else{
		return packet_build_noencode("0", "error: object [$obj] not a valid object type", $fid);
	}
}

#
# get all objects of type [JSON-STR]
# 
sub cdb_obj_get_all($request){
	my $fid = "[cdb_obj_get_all]";
	my $result;
	
	print "$fid received request\n";
	json_encode_pretty($request);

	my $object = $request->{'cdb'}{'obj'};
	my $objchk = cdb_obj_check($object);
	
	if($objchk->{'proto'}{'result'} eq "1"){		
		$result = packet_build_noencode("1", "succes: returning all [$object] objects", $fid);
		$result->{$object} = $db->{$object};
	}
	else{
		log_warn($fid, "invalid object type [$object]");
		$result = $objchk;
	}
	
	return json_encode($result);
}

1;
