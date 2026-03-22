#
# ETHER|AAPEN|CLI - LIB|SYSTEM|CMD
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
# system commands
#
sub system_cmd(){

	return  {
		"system" => {
			desc => "system commands",
			cmds => {
				"show" => {
					desc => "show system | <system>",
					proc => sub { quote(@_) }},
				"info" => {
					desc => "show system json | <system>",
					proc => sub { system_rest_info( @_ ) }},
				"reset" => {
					desc => "reset (power-reset) system | <system>",
					proc => sub { system_rest_reset( @_ ) }},
				"shutdown" => {
					desc => "shutdown (graceful) system | <system>",
					proc => sub { system_rest_shutdown( @_ ) }},
				"unload" => {
					desc => "unload (power-off) system | <system>",
					proc => sub { system_rest_unload( @_ ) }},
				"load" => {
					desc => "load (power-on) system | <system> <node>",
					proc => sub { system_rest_load( @_ ) }},
				"validate" => {
					desc => "validate system | <system> <node>",
					proc => sub { system_rest_validate( @_ ) }},
				"migrate" => {
					desc => "live migrate system | <system> <dest-node>",
					proc => sub { system_rest_migrate( @_ ) }},
				"move" => {
					desc => "system storage move | <system> <node>",
					proc => sub { system_rest_move( @_ ) }},
				"clone" => {
					desc => "system clone | <system> <node>",
					proc => sub { system_rest_clone( @_ ) }},
				"create" => {
					desc => "system create | <system> <node>",
					proc => sub { system_rest_create( @_ ) }},
				"delete" => {
					desc => "system delete | <system> <node>",
					proc => sub { system_rest_delete( @_ ) }},
				"console" => {
					desc => "open system console | <system>",
					proc => sub { system_rest_console( @_ ) }},
				"boot" => {
					desc => "change system boot device | <system> <boot-device>",
					proc => sub { system_rest_boot_set( @_ ) }},
				"boot" => {
					desc => "manage system boot options",
					cmds => {
						"set" => {
							desc => "change system boot device | <system> <boot-device>",
							proc => sub { system_rest_boot_set( @_ ) }},
						"list" => {
							desc => "list system boot devices | <system>",
							proc => sub { system_rest_boot_list( @_ ) }},
				}},
				"clone" => {
					desc => "clone system",
					cmds => {
						"config" => {
							desc => "clone system config | <src-system> <dst-system-name> <dst-system-id> <dst-system-group> <storage-pool>",
							proc => sub { system_rest_clone_config(@_) }},
						"full" => {
							desc => "full system clone | <src-system> <dst-system-name> <dst-system-id> <dst-system-group> <storage-pool> <node>",
							proc => sub { system_rest_clone_full( @_ ) }},
				}},
				"storage" => {
					desc => "storage managemet",
					cmds => {
						"pool_config_migrate" => {
							desc => "migrate storage config only | <system> <storage-device> <storage-pool>",
							proc => sub { system_rest_storage_pool_migrate_config(@_) }},
						"add" => {
							desc => "add storage device to system | <system> <device> <node>",
							proc => sub { system_rest_storage_add(@_) }},
						"expand" => {
							desc => "expand storage device to system | <system> <device> <node>",
							proc => sub { system_rest_storage_expand(@_) }},
				}},
				"list" => {
					desc => "list systems",
					cmds => {
						"all" => {
							desc => "list all systems",
							proc => sub { system_rest_list("all", "") }},
						"online" => {
							desc => "list online systems",
							proc => sub { system_rest_list("online", "") }},
						"offline" => {
							desc => "list offline systems",
							proc => sub { system_rest_list("offline", "") }},
						"node" => {
							desc => "list systems on | <node>",
							proc => sub { system_rest_list("node", @_) }},
						"group" => {
							desc => "list systems in | <group>",
							proc => sub { system_rest_list("group", @_) }},
						"find" => {
							desc => "list systems name with | <string>",
							proc => sub { system_rest_list("find", @_) }},
						"network" => {
							desc => "list sysetms on network | <netid> <netname>",
							proc => sub { system_rest_list("network", @_) }},
						"mac" => {
							desc => "list systems with mac | <string>",
							proc => sub { system_rest_list("mac", @_) }},
						"ip" => {
							desc => "list systems with ip | <string>",
							proc => sub { system_rest_list("addr", @_) }},
						"cluster" => {
							desc => "list systems in cluster",
							proc => sub { system_rest_list("cluster", "") }},
						"local" => {
							desc => "list systems known locally",
							proc => sub { system_rest_list("local", "") }},	
						"tag" => {
							desc => "list systems containing tag | <tag>",
							proc => sub { system_rest_list("tag", @_) }},
						"find" => {
							desc => "list systems containing name | <string>",
							proc => sub { system_rest_list("find", @_) }},
						"init" => {
							desc => "list non-initialized sysetms",
							proc => sub { system_rest_list("init", "") }},
				}},
				"config" => {
					desc => "system configuration",
					cmds => {

						"load" => {
							desc => "load system config | <sync/system-name>",
							proc => sub { system_rest_config_load(@_ // "") }},
							#proc => sub { system_rest_config_load() }},
						"save" => {
							desc => "save system config | <sync/system-name>",
							proc => sub { system_rest_config_save(@_ // "") }},
							#proc => sub { system_rest_config_save() }},
						#"add" => {
						#	desc => "add system config | <system-name>",
						#	proc => sub { system_rest_config_add(@_ // "") }},
						"del" => {
							desc => "delete system config | <system-name>",
							proc => sub { system_rest_config_del(@_) }},
						"set" => {
							desc => "set system config | <system-name>",
							proc => sub { system_rest_config_set(@_) }},
				}},
				"legacy" => {
					desc => "system management (legacy)",
					cmds => {
						"cluster" => {
							desc => "system cluster actions",
							cmds => {
								"clean" => {
									desc => "clean offline systems from cluster",
									proc => sub {sys_cluster_clean() }},
						}},
						"hypervisor" => {
									desc => "hypervisor actions",
									cmds => {
										"storage" => {
											desc => "system storage actions",
											cmds => {
											"expand" => {
												desc => "expand storage device | <node> <system> <device>",
												proc => sub {node_hyper_sys_stor_expand(@_) }},
											"add" => {
												desc => "add storage device | <node> <system> <device>",
												proc => sub {node_hyper_sys_stor_add(@_) }},
										}},
						}},

				}},
					
		}},
	};
}

1;
