#
# ETHER|AAPEN|HYPERVISOR - LIB|DB
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
# initialize database NOT IN USE!
#
sub hyper_db_init(){
	my $fid = "[hyper_db_init]";
	my $ffid = "DB|INIT";
	my $db;
	
	# config
	$db->{'config'}{'id'} = config_node_id_get();
	$db->{'config'}{'name'} = config_node_name_get();
	$db->{'config'}{'addr'} = config_node_addr_get();
	
	#$db->{'hyper'}{'aysnc'}{'load'} = "";
	#$db->{'hyper'}{'aysnc'}{'unload'} = "";
	
	$db->{'hyper'}{'db'} = {};
	
	# hyperdb
	$db->{'hyper'}{'vm'}{'index'} = "";
	$db->{'hyper'}{'vm'}{'lock'} = "";
	$db->{'hyper'}{'vm'}{'memalloc'} = 0;
	$db->{'hyper'}{'vm'}{'cpualloc'} = 0;
	$db->{'hyper'}{'vm'}{'systems'} = 0;

	# network
	$db->{'hyper'}{'net'} = {};
	$db->{'hyper'}{'net'}{'index'} = "";
	
	# stats
	$db->{'hyper'}{'stats'} = {};
	
	log_info($ffid, "initial config");
	json_encode_pretty($db);
	
	hyper_db_set($db);
	
	#hardware_stats();
}

#
# get database
#
sub hyper_db_get(){
	my %vmshare = dbshare_get();
	my $db = $vmshare{'db'};
	return json_decode($db);
}

#
# set database
#
sub hyper_db_set($db){
	my $fid = "[hyper_db_set]";
	my %vmshare = dbshare_get();
	
	# encode
	my $data = json_encode($db);
	
	# validate
	if(json_decode_validate($data)){
		$vmshare{'db'} = json_encode($db);
		$vmshare{'db_state'} = 1;
		dbshare_set(%vmshare);
		
		# save state
		config_state_save("hypervisor", $db);
		
		# pubish to cluster - TODO sync for actions, not here.. this is lazy
		hyper_cdb_sync();
	}
	else{
		print "$fid warning: failed to validate json!\n";
		print "$db\n";
	}

}

#
# get object [JSON-OBJ]
# 
sub hyper_db_obj_get($obj){
	my $db = hyper_db_get();
	return $db->{$obj};
}

#
# set object [NULL]
# 
sub hyper_db_obj_set($obj, $data){
	my $db = hyper_db_get();
	$db->{$obj} = $data;
	hyper_db_set($db);
}

#
# print database
#
sub hyper_db_print(){
	print "[hyper_db_print]\n";
	my $db = hyper_db_get();
	json_encode_pretty($db);
}

1;
