#
# ETHER|AAPEN|API - LIB|REST|NETWORK
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
# network rest config load [JSON-OBJ]
#
sub network_rest_config_load($request){
	my $fid = "[network_config_load]";
	my $ffid = "NETWORK|CONFIG|LOAD";
	my $netcfg = base_network_cfg_get();
	
	log_info($fid, "loading network configuration");
	if(env_debug()){ json_encode_pretty($request); }
	
	my $result = api_rest_obj_config_load($netcfg->{'dir'}, $netcfg->{'type'}, 'network', $request);
	
	log_info($fid, "network config load result");
	if(env_debug()){ json_encode_pretty($result); }
		
	return packet_build_noencode("1", "success: reached network config load", $fid);
}

#
# network rest config save [JSON-OBJ]
#
sub network_rest_config_save($request){
	my $fid = "[network_config_save]";
	my $ffid = "NETWORK|CONFIG|SAVE";
	
	log_info($fid, "saving network configuration");
	if(env_debug()){ json_encode_pretty($request); }
	
	return packet_build_noencode("1", "success: reached network config save", $fid);
}

1;
