#
# ETHER|AAPEN|VMM - LIB|DB
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

my $lock = 0;


#
# get database [JSON-OBJ]
#
sub monitor_db_get(){
	my %vmshare = dbshare_get();
	my $db = $vmshare{'db'};
	return json_decode($db);
}

#
# set database [NULL]
#
sub monitor_db_set($db){
	my $fid = "[monitor_db_set]";
	my %vmshare = dbshare_get();
	my $data = json_encode($db);
	
	# validate
	if(json_decode_validate($data)){
		$vmshare{'db'} = $data;
		dbshare_set(%vmshare);	
	}
	else{
		print "$fid warning: failed to validate json!\n";
		print "$db";
	}

}

#
# get database [JSON-OBJ]
#
sub vmm_db_get_new(){
	my %vmshare = vmshare_get();
	my $tmp = $vmshare{'db'};
	my $db = json_decode($tmp);
	return $db;
}

#
# set database [NULL]
#
sub vmm_db_set_new($db){
	my %vmshare = vmshare_get();
	$vmshare{'db'} = json_encode($db);
	$vmshare{'db_state'} = 1;
	vmshare_set(%vmshare);
}

#
# set database [NULL]
#
sub vmm_db_vm_set($vm){
	my $db = vmm_db_get_new();
	$db->{'vm'} = $vm;
	vmm_db_set_new($db);
}

#
# db get [JSON-OBJ]
#
sub vmm_db_vm_get(){
	my $db = vmm_db_get_new();
	return $db->{'vm'};
}

#
# initialize database [NULL]
#
sub vmm_db_init(){
	my $db;
	$db->{'init'} = "1";
	$db->{'version'} = env_version();
	$db->{'meta'}{'lock'} = "0";
	vmm_db_set_new($db);
}

#
# get vmm info [JSON-OBJ]
#
sub vmm_info_new(){
	my $fid = "[vmmdb_cluster_update]";
	my $ffid = "CLUSTER|UPDATE";
	my %vmshare = vmshare_get();
	my $vm = vmm_db_vm_get();

	my $data = {};
	$data = $vm;
	
	$data->{'meta'}{'state'} = $vmshare{'vm_running'};
	$data->{'meta'}{'state'} = $vmshare{'vm_running'};
	$data->{'meta'}{'version'} = env_version();
	
	$data->{'state'}{'vm_id'} = $vmshare{'vm_id'};
	$data->{'state'}{'vm_name'} = $vmshare{'vm_name'};
	
	$data->{'state'}{'node_id'} = $vmshare{'node_id'};
	$data->{'state'}{'node_name'} = $vmshare{'node_name'};
	
	$data->{'state'}{'vm_running'} = $vmshare{'vm_running'};	
	$data->{'state'}{'vm_state'} = $vmshare{'vm_state'};
	$data->{'state'}{'vm_status'} = $vmshare{'vm_status'};
	$data->{'state'}{'vm_lock'} = $vmshare{'vm_lock'};
	
	$data->{'state'}{'vmm_error'} = $vmshare{'vmmerr'};
	$data->{'state'}{'vmm_state'} = $vmshare{'vmmstat'};
	$data->{'state'}{'vmm_status'} = $vmshare{'vmmstatus'};
	$data->{'state'}{'vmm_proc'} = $vmshare{'vmmproc'};
	$data->{'state'}{'vmm_pid'} = $vmshare{'vmmpid'};
	$data->{'state'}{'vmm_out'} = $vmshare{'vmmout'};
	
	$data->{'state'}{'vmm_version'} = env_version();
	
	# NEW
	$data->{'meta'}{'date'} = date_get();

	if(env_debug()){ json_encode_pretty($data); };
	return $data;
}

#
# prepare disk lock files [STRING]
#
sub vmm_cfg_file($vm){
	my $fid = "[vmm_cfg_file]";
	my $ffid = "VMM|CONFIG";
	my $disk_id = 0;
		
	# network metadata
	my @disks = index_split($vm->{'stor'}{'disk'});
	my $disk = $disks[0];
	my $confdir = $vm->{'stor'}{$disk}{'dev'};
	
	# filename
	my $cfgfile = $confdir . $vm->{'id'}{'name'} . "." . $vm->{'id'}{'id'} . ".cfg";
	
	print "$fid cfgfile [$cfgfile]\n";
	return $cfgfile;
}

#
# cluster update [NULL]
#
sub vmmdb_cluster_update(){
	my $fid = "[vmmdb_cluster_update]";
	my $ffid = "VMM|CLUSTER|UPDATE";
	my $env = env_get();
	my %vmshare = vmshare_get();
	my $vm = vmm_db_vm_get();

	if(defined ($vmshare{'vm_name'})){
		my $data = vmm_info_new();
		log_info($ffid, "publishing data to cluster");
		my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $data);
	}
	else{
		log_info($ffid, "vm not initialized");
	}
	
}

#
# locking
#
sub lock_state(){
	return $lock;
}
sub lock_set(){
	$lock = 1;
}
sub lock_clear(){
	$lock = 0;
}

1;
