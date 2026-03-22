#
# ETHER|AAPEN|CLI - LIB|CDB|CMD
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
sub cdb_cmd(){

	return  {
		"cdb" => {
			desc => "cluster database management",
			cmds => {
				"ping" => {
					desc => "ping cdb",
					proc => sub { cdb_local_ping() }},
				"db" => {
					desc => "database actions",
					cmds => {
						"meta" => {
							desc => "get cdb metadata",
							proc => sub { cdb_local_meta_get("all") }},
						"get" => {
							desc => "get full cdb",
							proc => sub { cdb_local_db_get() }},
						"flush" => {
							desc => "flush cdb",
							proc => sub { cdb_local_db_flush() }},

				}},
				"object" => {
					desc => "object data management",
					cmds => {	
						"system" => {
							desc => "system data",
							cmds => {	
								"get" => {
									desc => "get system | <system>",
									proc => sub { cdb_local_obj_get( "system", @_) }},
								"set" => {
									desc => "set system | <system>",
									proc => sub { cdb_local_system_set(@_) }},
								"del" => {
									desc => "remove system | <system>",
									proc => sub { cdb_local_system_del(@_) }},
								"meta" => {
									desc => "get system metadata",
									proc => sub { cdb_local_meta_get("system") }},
								"list" => {
									desc => "list system metadata",
									proc => sub { cdb_local_meta_list("system") }},
						}},
						"node" => {
							desc => "node data",
							cmds => {	
								"get" => {
									desc => "get node | <node>",
									proc => sub { cdb_local_obj_get( "node", @_) }},
								"set" => {
									desc => "set node | <node>",
									proc => sub { cdb_local_node_set(@_) }},
								"del" => {
									desc => "remove node | <node>",
									proc => sub { cdb_local_node_del(@_) }},
								"meta" => {
									desc => "get node metadata",
									proc => sub { cdb_local_meta_get("node") }},
								"list" => {
									desc => "list node metadata",
									proc => sub { cdb_local_meta_list("node") }},
						}},
						"network" => {
							desc => "network data",
							cmds => {	
								"get" => {
									desc => "get network <network>",
									proc => sub { cdb_local_obj_get( "network", @_) }},
								"set" => {
									desc => "set network <network>",
									proc => sub { cdb_local_net_set(@_) }},
								"del" => {
									desc => "remove network <network>",
									proc => sub { cdb_local_net_del(@_) }},
								"meta" => {
									desc => "get network metadata",
									proc => sub { cdb_local_meta_get("network") }},
								"list" => {
									desc => "list network metadata",
									proc => sub { cdb_local_meta_list("network") }},
						}},
						"storage" => {
							desc => "storage data",
							cmds => {	
								"get" => {
									desc => "get storage <storage>",
									proc => sub { cdb_local_obj_get( "storage", @_) }},
								"set" => {
									desc => "set storage <type> <storage>",
									proc => sub { quote() }},
								"del" => {
									desc => "remove storage <storage>",
									proc => sub { quote() }},
								"meta" => {
									desc => "get storage metadata",
									proc => sub { cdb_local_meta_get("storage") }},
								"list" => {
									desc => "list storage metadata",
									proc => sub { cdb_local_meta_list("storage") }},
						}},
						"element" => {
							desc => "element data",
							cmds => {	
								"get" => {
									desc => "get element <element>",
									proc => sub { cdb_local_obj_get( "element", @_) }},
								"set" => {
									desc => "set element <type> <element>",
									proc => sub { quote() }},
								"del" => {
									desc => "remove element <element>",
									proc => sub { quote() }},
								"meta" => {
									desc => "get element metadata",
									proc => sub { cdb_local_meta_get("element") }},
								"list" => {
									desc => "list element metadata",
									proc => sub { cdb_local_meta_list("element") }},
						}},
						"group" => {
							desc => "group data",
							cmds => {	
								"get" => {
									desc => "get group <group>",
									proc => sub { cdb_local_obj_get( "group", @_) }},
								"set" => {
									desc => "set group <type> <group>",
									proc => sub { quote() }},
								"del" => {
									desc => "remove group <group>",
									proc => sub { quote() }},
								"meta" => {
									desc => "get group metadata",
									proc => sub { cdb_local_meta_get("group") }},
								"list" => {
									desc => "list group metadata",
									proc => sub { cdb_local_meta_list("group") }},
						}},
					
				}},
				"service" => {
					desc => "service data management",
					cmds => {	
						"framework" => {
							desc => "framework data",
							cmds => {	
								"get" => {
									desc => "get framework service data for node | <node>",
									proc => sub { cdb_local_service_get("framework", @_) }},
								"del" => {
									desc => "remove framework service data for node | <node>",
									proc => sub { cdb_local_service_del("framework", @_) }},
								"meta" => {
									desc => "get framework metadata",
									proc => sub { cdb_local_service_meta("framework") }},
								"list" => {
									desc => "list framework metadata",
									proc => sub { cdb_local_service_meta_list("framework") }},
						}},
						"network" => {
							desc => "network data",
							cmds => {	
								"get" => {
									desc => "get network service data for node | <node>",
									proc => sub { cdb_local_service_get("network", @_) }},
								"del" => {
									desc => "remove network service data for node | <node>",
									proc => sub { cdb_local_service_del("network", @_) }},
								"meta" => {
									desc => "get network metadata",
									proc => sub { cdb_local_service_meta("network") }},
								"list" => {
									desc => "list network metadata",
									proc => sub { cdb_local_service_meta_list("network") }},
						}},
						"hypervisor" => {
							desc => "hypervisor data",
							cmds => {	
								"get" => {
									desc => "get hypervisor service data for node | <node>",
									proc => sub { cdb_local_service_get("hypervisor", @_) }},
								"del" => {
									desc => "remove hypervisor service data for node | <node>",
									proc => sub { cdb_local_service_del("hypervisor", @_) }},
								"meta" => {
									desc => "get hypervisor metadata",
									proc => sub { cdb_local_service_meta("hypervisor") }},
								"list" => {
									desc => "list hypervisor metadata",
									proc => sub { cdb_local_service_meta_list("hypervisor") }},
						}},
						"monitor" => {
							desc => "monitor data",
							cmds => {	
								"get" => {
									desc => "get monitor service data for node | <node>",
									proc => sub { cdb_local_service_get("monitor", @_) }},
								"del" => {
									desc => "remove monitor service data for node | <node>",
									proc => sub { cdb_local_service_del("monitor", @_) }},
								"meta" => {
									desc => "get storage metadata",
									proc => sub { cdb_local_service_meta("monitor") }},
								"list" => {
									desc => "list storage metadata",
									proc => sub { cdb_local_service_meta_list("monitor") }},
						}},
						"storage" => {
							desc => "monitor data",
							cmds => {	
								"get" => {
									desc => "get storage service data for node | <node>",
									proc => sub { cdb_local_service_get("storage", @_) }},
								"del" => {
									desc => "remove storage service data for node | <node>",
									proc => sub { cdb_local_service_del("storage", @_) }},
								"meta" => {
									desc => "get storage metadata",
									proc => sub { cdb_local_service_meta("storage") }},
								"list" => {
									desc => "get storage metadata",
									proc => sub { cdb_local_service_meta_list("storage") }},
						}},
						"list" => {
							desc => "list all service metadata",
							proc => sub { cdb_local_service_meta_list("all") }},
					
				}},
				"env" => {
					desc => "cdb environment",
					cmds => {
						"info" => {
							desc => "enable infomrational output",
							proc => sub { cdb_local_env_set("info") }},
						"debug" => {
							desc => "enable debug output",
							proc => sub { cdb_local_env_set("debug") }},
						"verbose" => {
							desc => "enable verbose output",
							proc => sub { cdb_local_env_set("verbose") }},
						"silent" => {
							desc => "enable silent output",
							proc => sub { cdb_local_env_set("silent") }},
				}},	
				

		}},
	
	};

}

1;
