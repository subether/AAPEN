#
# ETHER|AAPEN|CLI - LIB|NET|CMD
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
# network commands
#
sub net_cmd(){

	return  {
		"network" => {
			desc => "network management",
			cmds => {
				"info" => {
					desc => "show network json | <network>",
					proc => sub { network_rest_info( @_ ) }},
				"list" => {
					desc => "list systems",
					cmds => {
						"all" => {
							desc => "list all networks",
							proc => sub { network_rest_list("all", "") }},
						"vpp" => {
							desc => "list vpp networks",
							proc => sub { network_rest_list("vpp", "") }},
						"bridge" => {
							desc => "list bridge networks",
							proc => sub { network_rest_list("bridge", "") }},
						"trunk" => {
							desc => "list trunk networks",
							proc => sub { network_rest_list("trunk", "") }},
						"find" => {
							desc => "list network name containing | <string>",
							proc => sub { network_rest_list("find", @_) }},
						"address" => {
							desc => "list networks with address | <string>",
							proc => sub { network_rest_list("addr", @_) }},
				}},
				"config" => {
					desc => "network configuration",
					cmds => {
						"load" => {
							desc => "load network config | <sync/network-name>",
							proc => sub { network_rest_config_load(@_) }},
						"save" => {
							desc => "save network config | <sync/network-name>",
							proc => sub { network_rest_config_save(@_) }},
						"sync" => {
							desc => "sync networks to cluster",
							proc => sub { network_rest_cluster_sync() }},
						"force" => {
							desc => "force sync all networks to cluster",
							proc => sub { network_rest_cluster_sync_force() }},
						"remove_all" => {
							desc => "delete all networks from cluster",
							proc => sub { network_rest_cluster_remove_all() }},	
				}},
				
		}},
	
	};

}

1;
