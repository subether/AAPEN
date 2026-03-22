#
# ETHER|AAPEN|NETWORK - LIB|DB
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
use JSON::MaybeXS;


#
# initialize database
#
sub net_db_init(){
	my $db;
	
	# config
	$db->{'config'}{'id'} = config_node_id_get();
	$db->{'config'}{'name'} = config_node_name_get();
	$db->{'config'}{'addr'} = config_node_addr_get();

	$db->{'config'}{'vpp'}{'enabled'} = 0;
	$db->{'config'}{'vpp'}{'state'} = 0;
	$db->{'config'}{'vpp'}{'bin'} = "";

	$db->{'version'} = env_version();
	$db->{'self'}{'init'} = "1";
	
	$db->{'net'}{'index'} = "";
	$db->{'net'}{'lock'} = "";
	$db->{'net'}{'index_name'} = "";

	$db->{'tap'}{'index'} = "";
	
	$db->{'bri'}{'index'} = "";
	
	$db->{'vpp'}{'index'} = "";
	
	$db->{'vnic'}{'index'} = "";
	
	$db->{'vm'}{'index'} = "";
	
	net_db_set($db);
}

#
#
#
sub net_config_init(){
	my $fid = "[net_config_init()]";
	my $ffid = "NET|CONFIG|INIT";
	
	my $netcfgbase = base_network_cfg_get();
	
	print "$fid NETWORK CFG BASE\n";
	json_encode_pretty($netcfgbase);
	
	my $net_init = 0;
	my $net_total = 0;
	
	my $net_dir_base = $netcfgbase->{'dir'};
	my $net_cfg_type = "*" . $netcfgbase->{'type'};
	
	# iterate the objects in the 
	my @file_list = file_list($net_dir_base, $net_cfg_type);
	
	print "$fid DIR BASE [$net_dir_base]\n";
	print "$fid CFG TYPE [$net_cfg_type]\n";
	print "$fid FILE LIST [@file_list]\n";
	
	foreach my $net_config_file (@file_list){	
		log_info("CONFIG|NET|LOAD", "loading network config [$net_config_file]");
		
		my $net_config = json_file_load($net_config_file);

		# fetch the index
		if(index_find($net_config->{'node'}{'index'}, config_node_id_get())){
			# node is defined in index
			log_info($ffid, "net id [$net_config->{'id'}{'id'}] name [$net_config->{'id'}{'name'}] - NODE IS DEFINED");
			
			# push network here
			net_push($net_config);
			$net_init++;
		}
		else{
			# node is not defined in index
			log_info($ffid, "net id [$net_config->{'id'}{'id'}] name [$net_config->{'id'}{'name'}] - NODE IS NOT DEFINED");
		}
		
		$net_total++;
	}	
	
	log_info($ffid, "loaded [$net_init] of [$net_total] configurations");
}

#
# get database
#
sub net_db_get(){
	my $fid = "[net_db_get]";
	my %vmshare = dbshare_get();
	my $db = $vmshare{'db'};
	return json_decode($db);
}

#
# set database
#
sub net_db_set($db){
	my $fid = "[net_db_set]";
	my $ffid = "DB|SET";
	my %vmshare = dbshare_get();
	
	# encode
	my $data = json_encode($db);
	
	# validate
	if(json_decode_validate($data)){
		$vmshare{'db'} = json_encode($db);
		$vmshare{'db_state'} = 1;
		dbshare_set(%vmshare);
		
		# save state
		config_state_save("network", $db);	
	}
	else{
		print "$fid warning: failed to validate json!\n";
		print "$db";
	}

}


#
# get object [JSON-OBJ]
# 
sub net_db_obj_get($obj){
	my $fid = "[net_db_obj_get]";
	my $ffid = "DB|OBJ|GET";
	my $db = net_db_get();
	return $db->{$obj};
}

#
# set object [NULL]
# 
sub net_db_obj_set($obj, $data){
	my $fid = "[net_db_obj_set]";
	my $ffid = "DB|OBJ|SET";
	my $db = net_db_get();
	$db->{$obj} = $data;
	net_db_set($db);
}

#
# print database
#
sub net_db_print(){
	print "[net_db_print]\n";
	my $db = net_db_get();
	json_encode_pretty($db);
}

1;
