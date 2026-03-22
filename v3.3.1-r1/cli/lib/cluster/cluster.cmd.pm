#
# ETHER|AAPEN|CLI - LIB|CLUSTER|CMD
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
sub cluster_cmd(){

	return  {
		"cluster" => {
			desc => "cluster management",
			cmds => {
				"panic" => {
					desc => "panic the cluster",
					cmds => {	
						"destroy" => {
							desc => "bring down all of quitthe clusters",
							proc => sub { cluster_local_panic_down() }},
						"graceful" => {
							desc => "gracefully bring down the cluster | <cluster>",
							proc => sub { cluster_local_panic_graceful(@_) }},
				}},
				"local" => {
					desc => "cluster management (local | socket)",
					cmds => {	
						"ping" => {
							desc => "ping cluster service",
							proc => sub { cluster_local_ping() }},
						"meta" => {
							desc => "cluster metadata",
							proc => sub { cluster_local_meta_get("all") }},
						"db_get" => {
							desc => "get cluster database",
							proc => sub { cluster_local_db_get() }},
						"object" => {
							desc => "system management",
							cmds => {	
								"get" => {
									desc => "object get |  <object> <key>",
									proc => sub { cluster_local_obj_get(@_) }},
								"get_all" => {
									desc => "object get <object>",
									proc => sub { cluster_local_obj_get_all(@_) }},
						}},
						"system" => {
							desc => "system management",
							cmds => {	
								"get" => {
									desc => "get system | <system>",
									proc => sub { cluster_local_obj_get( "system", @_) }},
								"set" => {
									desc => "set system | <system>",
									proc => sub { cluster_local_system_set(@_) }},
								"del" => {
									desc => "remove system | <system>",
									proc => sub { cluster_local_obj_del("system", @_) }},
								"meta" => {
									desc => "get system metadata",
									proc => sub { cluster_local_meta_get("system") }},
								"clean" => {
									desc => "clean offline systems from cluster",
									proc => sub { sys_cluster_clean() }},
						}},
						"node" => {
							desc => "node management",
							cmds => {	
								"get" => {
									desc => "get node | <node>",
									proc => sub { cluster_local_obj_get("node", @_) }},
								"set" => {
									desc => "set node | <node>",
									proc => sub { cluster_local_node_set(@_) }},
								"del" => {
									desc => "remove node | <node>",
									proc => sub { cluster_local_obj_del("node", @_) }},
								"meta" => {
									desc => "get node metadata",
									proc => sub { cluster_local_meta_get("node") }},
						}},
						"network" => {
							desc => "network management",
							cmds => {	
								"get" => {
									desc => "get network <network>",
									proc => sub { cluster_local_obj_get("network", @_) }},
								"set" => {
									desc => "set network <network>",
									proc => sub { cluster_local_net_set(@_) }},
								"del" => {
									desc => "remove network <network>",
									proc => sub { cluster_local_obj_del("network", @_) }},
								"meta" => {
									desc => "get network metadata",
									proc => sub { cluster_local_meta_get("network") }},
						}},
						"storage" => {
							desc => "storage management",
							cmds => {	
								"get" => {
									desc => "get storage <storage>",
									proc => sub { cluster_local_obj_get("storage", @_) }},
								"set" => {
									desc => "set storage <type> <storage>",
									proc => sub { cluster_local_stor_set(@_) }},
								"del" => {
									desc => "remove storage <network>",
									proc => sub { cluster_local_obj_del("storage", @_) }},
								"meta" => {
									desc => "get storage metadata",
									proc => sub { cluster_local_meta_get("storage") }},
						}},
						"service" => {
							desc => "service management",
							cmds => {	
								"get" => {
									desc => "get service <service>",
									proc => sub { cluster_local_service_get(@_) }},
								"node" => {
									desc => "get service <service> <node>",
									proc => sub { cluster_local_service_node_get(@_) }},
								"del" => {
									desc => "remove service object <service> <node>",
									proc => sub { cluster_local_service_del(@_) }},
								"meta" => {
									desc => "get service metadata",
									proc => sub { cluster_local_meta_get("service") }},
						}},
						"element" => {
							desc => "element management",
							cmds => {	
								"get" => {
									desc => "get element | <type> <name>",
									proc => sub { cluster_local_obj_get("element", @_) }},
								"set" => {
									desc => "set node | <name>",
									proc => sub { cluster_local_element_set(@_) }},
								"del" => {
									desc => "remove element | <name>",
									proc => sub { cluster_local_obj_del("element", @_) }},
								"meta" => {
									desc => "get element metadata",
									proc => sub { cluster_local_meta_get("element") }},
						}},	
						"env" => {
							desc => "cluster environment",
							cmds => {
								"info" => {
									desc => "enable infomrational output",
									proc => sub { cluster_local_env_set("info") }},
								"debug" => {
									desc => "enable debug output",
									proc => sub { cluster_local_env_set("debug") }},
								"verbose" => {
									desc => "enable verbose output",
									proc => sub { cluster_local_env_set("verbose") }},
								"silent" => {
									desc => "enable silent output",
									proc => sub { cluster_local_env_set("silent") }},
						}},						
				}},
				"node" => {
					desc => "cluster management (node | ip)",
					cmds => {	
						"ping" => {
							desc => "ping cluster <cluster-node>",
							proc => sub { node_rest_cluster_ping(@_) }},
							#proc => sub { cli_node_cluster_ping(@_) }},
						"meta" => {
							desc => "cluster metadata <cluster-node>",
							proc => sub { node_rest_cluster_meta(@_) }},
							#proc => sub { cli_node_cluster_meta(@_) }},
						"env" => {
							desc => "environment commands",
							cmds => {
								"info" => {
									desc => "enable infomrational output | <node>",
									proc => sub { node_rest_service_env('cluster', 'info', @_) }},
								"debug" => {
									desc => "enable debug output | <node>",
									proc => sub { node_rest_service_env('cluster', 'debug', @_) }},
								"verbose" => {
									desc => "enable verbose output | <node>",
									proc => sub { node_rest_service_env('cluster', 'verbose', @_) }},
								"silent" => {
									desc => "enable silent output | <node>",
									proc => sub { node_rest_service_env('cluster', 'silent', @_) }},
								"current" => {
									desc => "current env | <node>",
									proc => sub { node_rest_service_env('cluster', 'current', @_) }},
						}},	
						"system" => {
							desc => "system management",
							cmds => {
								"meta" => {
									desc => "get system metadata <cluster-node>",
									proc => sub { cluster_node_obj_meta("system", @_) }},
								"get" => {
									desc => "get system | <cluster-node> <system>",
									proc => sub { cluster_node_obj_get("system", @_) }},
						}},
						"node" => {
							desc => "node management",
							cmds => {
								"meta" => {
									desc => "get system metadata | <cluster-node>",
									proc => sub { cluster_node_obj_meta("node", @_) }},
								"get" => {
									desc => "get node | <cluster-node> <node>",
									proc => sub { cluster_node_obj_get("node", @_) }},
						}},
						"network" => {
							desc => "network management",
							cmds => {
								"meta" => {
									desc => "get network metadata <cluster-node>",
									proc => sub { cluster_node_obj_meta("network", @_) }},
								"get" => {
									desc => "get network | <cluster-node> <network>",
									proc => sub { cluster_node_obj_get("network", @_) }},
						}},
						"storage" => {
							desc => "storage management",
							cmds => {
								"meta" => {
									desc => "get storage metadata <cluster-node>",
									proc => sub { cluster_node_obj_meta("storage", @_) }},
								"get" => {
									desc => "get storage | <cluster-node> <storage>",
									proc => sub { cluster_node_obj_get("storage", @_) }},
						}},
						"element" => {
							desc => "element management",
							cmds => {
								"meta" => {
									desc => "get element metadata <cluster-node>",
									proc => sub { cluster_node_obj_meta("element", @_) }},
								"get" => {
									desc => "get element | <cluster-node> <element>",
									proc => sub { cluster_node_obj_get("element", @_) }},
						}},
						"db_get" => {
							desc => "get cluster database",
							proc => sub { node_rest_cluster_db(@_) }},
						#}},	
						"service" => {
							desc => "service management",
							cmds => {
								"framework" => {
									desc => "framework service",
									cmds => {
										"meta" => {
											desc => "get framework cluster metadata <cluster-node>",
											proc => sub { cluster_node_service_meta("framework", @_) }},
										"get" => {
											desc => "get framework cluster metadata <node>",
											proc => sub { cluster_node_service_get("framework", @_) }},
								}},
								"hypervisor" => {
									desc => "framework service",
									cmds => {
										"meta" => {
											desc => "get framework cluster metadata <cluster-node>",
											proc => sub { cluster_node_service_meta("framework", @_) }},
										"get" => {
											desc => "get framework cluster metadata <cluster-node>",
											proc => sub { cluster_node_service_get("framework", @_) }},
								}},	
								"storage" => {
									desc => "storage service",
									cmds => {
										"meta" => {
											desc => "get storage cluster metadata <node>",
											proc => sub { cluster_node_service_meta("storage", @_) }},
										"get" => {
											desc => "get storage cluster metadata <node>",
											proc => sub { cluster_node_service_get( "storage", @_) }},
								}},	
								"monitor" => {
									desc => "storage service",
									cmds => {
										"meta" => {
											desc => "get storage cluster metadata <cluster-node>",
											proc => sub { cluster_node_service_meta("monitor", @_) }},
										"get" => {
											desc => "get storage cluster metadata <cluster-node>",
											proc => sub { cluster_node_service_get("monitor", @_) }},
											
								}},	
									
						}},	
				}},
				"api" => {
					desc => "api cluster operations",
					cmds => {	
						"sync" => {
							desc => "sync with api",
							proc => sub { cli_cluster_api_sync() }},
						"enable" => {
							desc => "enable api cluster integration",
							proc => sub { cli_cluster_api_enable() }},
						"disable" => {
							desc => "disable api cluster integration",
							proc => sub { cli_cluster_api_disable() }},
				}},

		}},
	
	};

}

1;
