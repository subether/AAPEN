#
# ETHER|AAPEN|CLI - LIB|API|CMD
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
use JSON::MaybeXS;


#
# api commands
#
sub api_cmd(){

	return  {
		"api" => {
			desc => "api commands",
			cmds => {
				"ping" => {
					desc => "ping REST API",
					proc => sub { rest_api_ping() }},									
				"config" => {
					desc => "api config",
					cmds => {
						"base" => {
							desc => "show base config",
							proc => sub {api_config_base_show() }},
						"node" => {
							desc => "show node config",
							proc => sub {api_config_node_show() }},
				}},
		
		}},
	
	};

}

1;
