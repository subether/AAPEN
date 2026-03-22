#
# ETHER|AAPEN|API - LIB|REST|NODE
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
#

use strict;
use warnings;
use experimental 'signatures';

#
# get node with validation [JSON-OBJ]
#
sub node_rest_validate_get($node_name){
	my $fid = "[cluster_obj_db_get]";
	my $ffid = "NODE|VALIDATE|GET";
	
	# validate node name
	if(defined $node_name && string_validate($node_name)){
		log_info($ffid, "success: node name defined and valid");
		my $node_data = api_cluster_local_obj_get(env_serv_sock_get("cluster"), 'node', $node_name);
		
		if($node_data->{'proto'}{'result'} eq "1"){
			return $node_data;
		}
		else{
			log_warn($ffid, "error: failed to fetch node from cluster");
			return packet_build_noencode("0", "error: failed to fetch node from cluster", $fid);
		}		
	}
	else{
		log_warn($ffid, "error: node name must be defined");
		return packet_build_noencode("0", "error: node name must be defined", $fid);
	}
}

#
# load node config [JSON-OBJ]
#
sub node_rest_config_load($request){
	my $fid = "[node_config_load]";
	my $ffid = "NODE|CONFIG|LOAD";
	my $nodecfg = base_node_cfg_get();

	log_info($fid, "loading node configuration");
	if(env_debug()){ json_encode_pretty($request); }
	
	my $result = api_rest_obj_config_load($nodecfg->{'dir'}, $nodecfg->{'type'}, 'node', $request);
	log_info_json($ffid, "system config load result", $result);
	
	return $result;	
}

#
# save node config [JSON-OBJ]
#
sub node_rest_config_save($request){
	my $fid = "[node_config_save]";
	my $ffid = "NODE|CONFIG|SAVE";
	
	log_info($fid, "saving node configuration");
	if(env_debug()){ json_encode_pretty($request); }
	
	return packet_build_noencode("1", "success: reached node config save", $fid);
}

#
# save system config to disk [JSON-OBJ]
#
sub node_rest_config_save($request){
	my $fid = "[node_config_save]";
	my $ffid = "NODE|CONFIG|SAVE";
	my $nodecfg = base_node_cfg_get();

	my $node_num = 0;
	my $node_fail = 0;
	
	my $node_meta = api_cluster_local_meta_get(env_serv_sock_get("cluster"));

	if($node_meta->{'proto'}{'result'}){
		my @node_index = index_split($node_meta->{'meta'}{'node'}{'index'});
		
		foreach my $node_name (@node_index){
			my $node_data = node_rest_validate_get($node_name);
			
			if($node_data->{'proto'}{'result'}){
				my $node_clean = node_rest_config_clean($node_data->{'node'});
				my $result = api_rest_obj_config_save($nodecfg->{'dir'}, $nodecfg->{'type'}, 'node', $node_clean);
				
				if($result->{'proto'}{'result'}){
					log_info($ffid, "successfully saved node [$node_name]");
					$node_num++;
				}
				else{
					log_warn($ffid, "failed to save node [$node_name]");
					$node_fail++;
				}
				
			}
			else{
				log_warn($ffid, "failed to get node [$node_data] from cluster!");
				$node_fail++;
			}	
		}
		
		log_info($ffid, "saved [$node_num] node. [$node_fail] failures");
		return packet_build_noencode("1", "success: saved [$node_num] nodes. [$node_fail] failures", $fid);	
	}
	else{
		log_warn($ffid, "failed to get metadata from cluster");
		return packet_build_noencode("0", "failed: could not get metadata from cluster", $fid);	
	}

}

#
# clean system config [JSON-OBJ]
#
sub node_rest_config_clean($node){
	my $fid = "[node_config_clean]";
	my $ffid = "NODE|CONFIG|CLEAN";
	
	log_debug_json($ffid, "received node for cleaning", $node);	
	log_info($ffid, "dest node name [" . $node->{'id'}{'name'} . "] id [".  $node->{'id'}{'id'} . "]");
	
	# cleanup config
	delete $node->{'meta'};
	delete $node->{'hw'};
	delete $node->{'object'}{'meta'};
	delete $node->{'object'}{'cdb'};
	
	$node->{'object'}{'type'} = "node";
	#"type" : "system",
	
	#$system->{'meta'}{'state'} = "0";
	#$system->{'meta'}{'status'} = "offline";
	#$system->{'state'}{'vm_status'} = "offline";
	
	# process storage devices
	#my @net_index = index_split($system->{'net'}{'dev'});
	
	#foreach my $nic (@net_index){
		#log_info($fid, "processing nic [$nic]");
				
	#	if($system->{'net'}{$nic}{'net'}{'type'} eq "bri-tap"){
	#		delete $system->{'net'}{$nic}{'tap'};
	#		delete $system->{'net'}{$nic}{'bri'};
	#	}
	#	elsif($system->{'net'}{$nic}{'net'}{'type'} eq "dpdk-vpp"){
	#		delete $system->{'net'}{$nic}{'vpp'};
	#	}
	#	else{
	#		log_warn($fid, "error: network type [" . $system->{'net'}{$nic}{'net'}{'type'} . "] is unknown");
	#		return packet_build_noencode("0", "error: network type [" . $system->{'net'}{$nic}{'net'}{'type'} . "] is unknown", $fid);
	#	}
	#}	
	
	# completed
	log_debug_json($fid, "cleaned node configuration", $node);
	return $node;
}

1;
