#
# ETHER|AAPEN|CLI - LIB|CMD
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
sub stor_cmd(){

	return  {
		"storage" => {
			desc => "storage management",
			cmds => {
				"info" => {
					desc => "show storage json | <storage>",
					proc => sub { storage_rest_info(@_) }},
				"meta" => {
					desc => "list storage json metadata",
					proc => sub { quote(@_) }},
				"list" => {
					desc => "list storage",
					cmds => {
						"all" => {
							desc => "list all networks",
							proc => sub { storage_rest_list("all", "") }},
						"iso" => {
							desc => "list ISO images",
							proc => sub { storage_rest_list("iso", "") }},
						"device" => {
							desc => "list storage devices",
							proc => sub { storage_rest_list("device", "") }},
						"pool" => {
							desc => "list storage pools",
							proc => sub { storage_rest_list("pool", "") }},
						"find" => {
							desc => "list storage name containing | <string>",
							proc => sub { storage_rest_list("find", @_) }},
				}},
				"config" => {
					desc => "storage configuration",
					cmds => {
						"load" => {
							desc => "load storage config | <sync/storage-name>",
							proc => sub { storage_rest_config_load(@_ // "") }},
						"save" => {
							desc => "save storage config | <sync/storage-name>",
							proc => sub { storage_rest_config_save(@_ // "") }},
				}},

		}},
	
	};

}

1;
