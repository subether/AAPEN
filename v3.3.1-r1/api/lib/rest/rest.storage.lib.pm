#
# ETHER|AAPEN|API - LIB|REST|STORAGE
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
# load storage config [JSON-OBJ]
#
sub storage_rest_config_load($request){
	my $fid = "[storage_config_load]";
	my $ffid = "STORAGE|CONFIG|LOAD";
	
	my $storcfg = base_storage_cfg_get();
	
	log_info($fid, "loading storage configuration");
	if(env_debug()){ json_encode_pretty($request); }

	my $result = packet_build_noencode("1", "success: loading storage config", $fid);

	$result->{'device'} = api_rest_obj_config_load($storcfg->{'device'}{'dir'}, $storcfg->{'device'}{'type'}, 'storage', $request);
	
	$result->{'pool'} = api_rest_obj_config_load($storcfg->{'pool'}{'dir'}, $storcfg->{'pool'}{'type'}, 'storage', $request);
	
	$result->{'iso'} = api_rest_obj_config_load($storcfg->{'iso'}{'dir'}, $storcfg->{'iso'}{'type'}, 'storage', $request);
	
	log_info_json($ffid, "storage config load result", $result);
	
	return $result;
}

#
# save storage config
#
sub storage_rest_config_save($request){
	my $fid = "[storage_config_save]";
	my $ffid = "STORAGE|CONFIG|SAVE";
	
	log_info($fid, "saving storage configuration");
	if(env_debug()){ json_encode_pretty($request); }
	
	return packet_build_noencode("1", "success: reached storage config save", $fid);
}

#
# check if storage pool exists [BOOL]
#
sub storage_rest_pool_check($storage_db, $storage_pool_name){
	my @storage_index = index_split($storage_db->{'index'});
	
	foreach my $storage_name (@storage_index){
		if($storage_db->{'db'}{$storage_name}{'object'}{'model'} eq "pool"){
			if($storage_name eq $storage_pool_name){
				return 1;
			}
		}
	}
	
	return 0;
}

#
# get storage pool [JSON-OBJ]
#
sub storage_rest_pool_get($storage_db, $storage_pool_name){
	return $storage_db->{'db'}{$storage_pool_name};
}

1;
