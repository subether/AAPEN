#
# ETHER|AAPEN|MONITOR - LIB|DB
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
sub monitor_db_init(){
	my $db;
	$db->{'version'} = env_version_get();
	my $node_config = config_node_get();

	$db->{'config'}{'name'} = $node_config->{'id'}{'name'};
	$db->{'config'}{'id'} = $node_config->{'id'}{'id'};
	$db->{'config'}{'prio'} = $node_config->{'monitor'}{'prio'};
		
	# alarm
	$db->{'alarm'} = {};
	$db->{'alarm'}{'index'} = "";
	
	monitor_db_set($db);
}

#
# get database
#
sub monitor_db_get(){
	my %vmshare = dbshare_get();
	my $db = $vmshare{'db'};
	return json_decode($db);
}

#
# set database
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
# get object [JSON-OBJ]
# 
sub monitor_db_obj_get($obj){
	my $db = monitor_db_get();
	return $db->{$obj};
}

#
# set object [NULL]
# 
sub monitor_db_obj_set($obj, $data){
	my $db = monitor_db_get();
	$db->{$obj} = $data;
	monitor_db_set($db);
}

1;
