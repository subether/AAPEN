#
# ETHER|AAPEN|API - LIB|REST|SYSTEM
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
# load element config
#
sub element_rest_config_load($request){
	my $fid = "element_config_load";
	my $ffid = "ELEMENT|CONFIG|LOAD";
	my $elementcfg = base_element_cfg_get();
	
	log_info($fid, "loading element configuration");
	if(env_debug()){ json_encode_pretty($request); }
	
	# device
	my $result_device = api_rest_obj_config_load($elementcfg->{'device'}{'dir'}, $elementcfg->{'device'}{'type'}, 'element', $request);
	
	log_info($fid, "device config load result");
	if(env_debug()){ json_encode_pretty($result_device); }
	
	# service
	my $result_service = api_rest_obj_config_load($elementcfg->{'service'}{'dir'}, $elementcfg->{'service'}{'type'}, 'element', $request);
	
	log_info($fid, "service config load result");
	if(env_debug()){ json_encode_pretty($result_service); }
	
	return packet_build_noencode("1", "success: reached element config load", $fid);
}

#
# save element config
#
sub element_rest_config_save($request){
	my $fid = "element_config_save";
	my $ffid = "ELEMENT|CONFIG|SAVE";
	
	log_info($fid, "saving element configuration");
	if(env_debug()){ json_encode_pretty($request); }
	
	return packet_build_noencode("1", "success: reached element config save", $fid);
}

1;
