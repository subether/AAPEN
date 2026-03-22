#
# ETHER|AAPEN|CLI - LIB|NODE|CMD
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
# node commands
#
sub node_cmd(){

	return  {
		"node" => {
			desc => "node management",
			cmds => {
				"info" => {
					desc => "show node json | <system>",
					proc => sub { node_rest_info( @_ ) }},
				"list" => {
					desc => "list nodes",
					cmds => {
						"all" => {
							desc => "list all nodes",
							proc => sub { node_rest_list("all", "") }},
						"cluster" => {
							desc => "list nodes in cluster | <cluster>",
							proc => sub { node_rest_list("cluster", @_) }},
						"name" => {
							desc => "node name contain | <string>",
							proc => sub { node_rest_list("name", @_) }},
						"offline" => {
							desc => "list offline nodes",
							proc => sub { node_rest_list("offline", "") }},
						"online" => {
							desc => "list online nodes",
							proc => sub { node_rest_list("online", "") }},
						"group" => {
							desc => "list nodes in group | <group>",
							proc => sub { node_rest_list("group", @_) }},
				}},
				"config" => {
					desc => "node configuration",
					cmds => {
						"load" => {
							desc => "load node config | <node>",
							proc => sub { node_rest_config_load(@_ // "") }},
						"save" => {
							desc => "save node config | <node>",
							proc => sub { node_rest_config_save(@_ // "") }},
				}},
				"network" => {
					desc => "node network operations",
					cmds => {
						"ping" => {
							desc => "ping framework service | <node>",
							proc => sub { node_rest_network_ping(@_) }},
						"meta" => {
							desc => "show node framework metadata | <node>",
							proc => sub { node_rest_network_meta(@_) }},
						"list" => {
							desc => "list networks on node | <node>",
							proc => sub { node_rest_network_list(@_) }},
						"meta" => {
							desc => "show node network metadata | <node>",
							proc => sub { node_rest_network_meta(@_) }},
						"tap" => {
							desc => "show node taps (TUNTAP/BRI)",
							cmds => {
								"list" => {
									desc => "list network taps | <node>",
									proc => sub {node_rest_network_tap_list(@_) }},
								"meta" => {
									desc => "show tap metadata | <node> <tap>",
									proc => sub { node_rest_network_tap_meta(@_) }},
								"del" => {
									desc => "remove network tap | <node> <tap>",
									proc => sub { node_rest_network_tap_del(@_) }},				
						}},
						"vnic" => {
							desc => "show node vnics (DPDK/VPP)",
							cmds => {
								"list" => {
									desc => "list network taps | <node>",
									proc => sub {node_network_tap_list(@_) }},
								"meta" => {
									desc => "show tap metadata | <node> <tap>",
									proc => sub { node_network_tap_meta(@_) }},
								"del" => {
									desc => "remove network tap | <node> <tap>",
									proc => sub { node_network_tap_del(@_) }},				
						}},
						"device" => {
							desc => "show node device information",
							cmds => {
								"list" => {
									desc => "list network taps | <node>",
									proc => sub {node_rest_network_dev_list(@_) }},
								"meta" => {
									desc => "show tap metadata | <node> <tap>",
									proc => sub { node_rest_network_dev_meta(@_) }},		
						}},
						"env" => {
							desc => "environment commands",
							cmds => {
								"info" => {
									desc => "enable infomrational output | <node>",
									proc => sub { node_rest_service_env('network', 'info', @_) }},
								"debug" => {
									desc => "enable debug output | <node>",
									proc => sub { node_rest_service_env('network', 'debug', @_) }},
								"verbose" => {
									desc => "enable verbose output | <node>",
									proc => sub { node_rest_service_env('network', 'verbose', @_) }},
								"silent" => {
									desc => "enable silent output | <node>",
									proc => sub { node_rest_service_env('network', 'silent', @_) }},
								"current" => {
									desc => "current env | <node>",
									proc => sub { node_rest_service_env('network', 'current', @_) }},
						}},	
						
				}},
				"monitor" => {
					desc => "node monitor management",
					cmds => {
						"ping" => {
							desc => "ping monitor service | <node>",
							proc => sub {node_rest_monitor_ping(@_) }},
						"meta" => {
							desc => "show node monitor metadata | <node>",
							proc => sub { node_rest_monitor_meta(@_) }},
						"alarm" => {
							desc => "get alarms | <node>",
							proc => sub {node_monitor_alarm_get(@_) }},
						"list" => {
							desc => "list all monitor nodes",
							proc => sub { node_monitor_maint_cluster_status() }},
						"env" => {
							desc => "environment commands",
							cmds => {
								"info" => {
									desc => "enable infomrational output | <node>",
									proc => sub { node_rest_service_env('monitor', 'info', @_) }},
								"debug" => {
									desc => "enable debug output | <node>",
									proc => sub { node_rest_service_env('monitor', 'debug', @_) }},
								"verbose" => {
									desc => "enable verbose output | <node>",
									proc => sub { node_rest_service_env('monitor', 'verbose', @_) }},
								"silent" => {
									desc => "enable silent output | <node>",
									proc => sub { node_rest_service_env('monitor', 'silent', @_) }},
								"current" => {
									desc => "current env | <node>",
									proc => sub { node_rest_service_env('monitor', 'current', @_) }},
						}},
						"maintenance" => {
							desc => "configure maintenance mode",
							cmds => {
								"enable" => {
									desc => "enable maintenance monde  | <node>",
									proc => sub { node_monitor_env_set("maintenance_on", @_) }},
								"disable" => {
									desc => "disable maintenance mode  | <node>",
									proc => sub { node_monitor_env_set("maintenance_off", @_) }},
								"status" => {
									desc => "show maintenance status | <node>",
									proc => sub { node_monitor_env_set("current", @_) }},
								"cluster" => {
									desc => "configure cluster-wide maintenance",
									cmds => {
										"enable" => {
											desc => "enable cluster maintenance mode | <node>",
											proc => sub { node_monitor_maint_cluster_enable() }},
										"disable" => {
											desc => "disable cluster maintenance mode | <node>",
											proc => sub { node_monitor_maint_cluster_disable() }},
										"status" => {
											desc => "show cluster maintenance status | <node>",
											proc => sub { node_monitor_maint_cluster_status() }},
								}},
						}},	
				}},
				"hypervisor" => {
					desc => "node hypervisor",
					cmds => {
						"ping" => {
							desc => "ping node hypervisor | <node>",
							proc => sub { node_rest_hypervisor_ping(@_) }},
						"meta" => {
							desc => "show node hypervisor metadata | <node>",
							proc => sub { node_rest_hypervisor_meta(@_) }},
						"env" => {
							desc => "environment commands",
							cmds => {
								"info" => {
									desc => "enable infomrational output | <node>",
									proc => sub { node_rest_service_env('hypervisor', 'info', @_) }},
								"debug" => {
									desc => "enable debug output | <node>",
									proc => sub { node_rest_service_env('hypervisor', 'debug', @_) }},
								"verbose" => {
									desc => "enable verbose output | <node>",
									proc => sub { node_rest_service_env('hypervisor', 'verbose', @_) }},
								"silent" => {
									desc => "enable silent output | <node>",
									proc => sub { node_rest_service_env('hypervisor', 'silent', @_) }},
								"current" => {
									desc => "current env | <node>",
									proc => sub { node_rest_service_env('hypervisor', 'current', @_) }},
						}},		
						"system" => {
							desc => "system commands",
							cmds => {
								#"info" => {
								#	desc => "get system info | <node> <system>",
								#	proc => sub {node_hyper_vm_info(@_) }},
								"destroy" => {
									desc => "destroy system | <node> <system>",
									proc => sub {node_rest_hypervisor_system_destroy(@_) }},	
						}},
				
				}},		
				"storage" => {
					desc => "node storage management",
					cmds => {
						"ping" => {
							desc => "ping storage service | <node>",
							proc => sub { node_rest_storage_ping(@_) }},
						"meta" => {
							desc => "show node storage metadata | <node>",
							proc => sub { node_rest_storage_meta(@_) }},	
						"info" => {
							desc => "get storage device info | <node> <device>",
							proc => sub { node_storage_info(@_) }},
						"env" => {
							desc => "environment commands",
							cmds => {
								"info" => {
									desc => "enable infomrational output | <node>",
									proc => sub { node_rest_service_env('storage', 'info', @_) }},
								"debug" => {
									desc => "enable debug output | <node>",
									proc => sub { node_rest_service_env('storage', 'debug', @_) }},
								"verbose" => {
									desc => "enable verbose output | <node>",
									proc => sub { node_rest_service_env('storage', 'verbose', @_) }},
								"silent" => {
									desc => "enable silent output | <node>",
									proc => sub { node_rest_service_env('storage', 'silent', @_) }},
								"current" => {
									desc => "current env | <node>",
									proc => sub { node_rest_service_env('storage', 'current', @_) }},
						}},	
						"pool" => {
							desc => "node storage pool management",
							cmds => {
								"set" => {
									desc => "push storage pool to node | <node> <pool>",
									proc => sub { node_rest_storage_pool_set(@_); }},
								"get" => {
									desc => "pull storage pool from node | <node> <pool>",
									proc => sub { node_rest_storage_pool_get(@_); }},
						}},
						"device" => {
							desc => "node storage device management",
							cmds => {
								#"set" => {
								#	desc => "push storage pool to node | <node> <pool>",
								#	proc => sub { node_rest_storage_pool_set(@_); }},
								"get" => {
									desc => "pull storage device from node | <node> <device>",
									proc => sub { node_rest_storage_device_get(@_); }},
						}},	
				}},	
				"framework" => {
					desc => "node framework management",
					cmds => {
						"ping" => {
							desc => "ping framework service | <node>",
							proc => sub { node_rest_framework_ping(@_) }},
						"meta" => {
							desc => "show node framework metadata | <node>",
							proc => sub { node_rest_framework_meta(@_) }},
						"info" => {
							desc => "get node framework info | <node>",
							proc => sub { node_frame_info(@_) }},
						"shutdown" => {
							desc => "environment commands",
							cmds => {
								"graceful" => {
									desc => "shutdown node gracefully | <node>",
									proc => sub { node_rest_framework_shutdown("graceful", @_) }},
								"force" => {
									desc => "shutdown node forcefully | <node>",
									proc => sub { node_rest_framework_shutdown("force", @_) }},
								"reboot" => {
									desc => "reboot node | <node>",
									proc => sub { node_rest_framework_shutdown("reboot", @_) }},
						}},	
						"env" => {
							desc => "environment commands",
							cmds => {
								"info" => {
									desc => "enable infomrational output | <node>",
									proc => sub { node_rest_service_env('framework', 'info', @_) }},
								"debug" => {
									desc => "enable debug output | <node>",
									proc => sub { node_rest_service_env('framework', 'debug', @_) }},
								"verbose" => {
									desc => "enable verbose output | <node>",
									proc => sub { node_rest_service_env('framework', 'verbose', @_) }},
								"silent" => {
									desc => "enable silent output | <node>",
									proc => sub { node_rest_service_env('framework', 'silent', @_) }},
								"current" => {
									desc => "current env | <node>",
									proc => sub { node_rest_service_env('framework', 'current', @_) }},
						}},
						"vmm" => {
							desc => "node vmm management",
							cmds => {
								"info" => {
									desc => "get vmm info | <node> <vmm-id>",
									proc => sub { node_rest_framework_vmm_info(@_) }},
								#"start" => {
								#	desc => "start vmm service | <node> <vmm>",
								#	proc => sub {node_frame_vmm_start(@_)}},
								#"stop" => {
								#	desc => "stop service | <node> <vmm>",
								#	proc => sub { node_frame_vmm_stop(@_) }},
								"list" => {
									desc => "list vmm info | <node>",
									proc => sub { node_rest_framework_vmm_list(@_) }},
						}},
						"service" => {
							desc => "node service management",
							cmds => {
								"info" => {
									desc => "get service info | <node> <service>",
									proc => sub { node_rest_framework_service_info(@_) }},
								"start" => {
									desc => "start service | <node> <service>",
									proc => sub { node_rest_framework_service_start(@_) }},
								"restart" => {
									desc => "restart service | <node> <service>",
									proc => sub { node_rest_framework_service_restart(@_) }},
								#"clean_state" => {
								#	desc => "clean and reset service state | <node> <service>",
								#	proc => sub {node_frame_srv_clear_state(@_)}},
								"stop" => {
									desc => "stop service | <node> <service>",
									proc => sub { node_rest_framework_service_stop(@_) }},
								"logclear" => {
									desc => "clear logs for service | <node> <service>",
									proc => sub { node_rest_framework_service_log_clear(@_) }},
								"list" => {
									desc => "list service info | <node>",
									proc => sub { node_rest_framework_service_list(@_) }},
						}},				
				}},
				"cluster" => {
					desc => "node cluster management",
					cmds => {
						"ping" => {
							desc => "ping cluster service | <node>",
							proc => sub { node_rest_cluster_ping(@_) }},
						"meta" => {
							desc => "get cluster meta from node | <node>",
							proc => sub { node_rest_cluster_meta(@_) }},
						"db" => {
							desc => "get cluster db from node | <node>",
							proc => sub { node_rest_cluster_db(@_) }},
						"object" => {
							desc => "get object node cluster service",
							cmds => {
								"get" => {
									desc => "get object from cluster | <node> <object-type> <object-name>",
									proc => sub { node_rest_cluster_object_get(@_) }},

						}},
						"service" => {
							desc => "get service from node cluster service",
							cmds => {
								"get" => {
									desc => "get service object for node from cluster node | <node> <service-name> <node-name>",
									proc => sub { node_rest_cluster_service_get(@_) }},

						}},	
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
	
				}},	
				"cdb" => {
					desc => "node cdb management",
					cmds => {
						"ping" => {
							desc => "ping storage cdb | <node>",
							proc => sub { node_rest_cdb_ping(@_) }},
						"env" => {
							desc => "cdb commands",
							cmds => {
								"info" => {
									desc => "enable infomrational output | <node>",
									proc => sub { node_rest_service_env('cdb', 'info', @_) }},
								"debug" => {
									desc => "enable debug output | <node>",
									proc => sub { node_rest_service_env('cdb', 'debug', @_) }},
								"verbose" => {
									desc => "enable verbose output | <node>",
									proc => sub { node_rest_service_env('cdb', 'verbose', @_) }},
								"silent" => {
									desc => "enable silent output | <node>",
									proc => sub { node_rest_service_env('cdb', 'silent', @_) }},
								"current" => {
									desc => "current env | <node>",
									proc => sub { node_rest_service_env('cdb', 'current', @_) }},
						}},	
	
				}},	
				"ping" => {
					desc => "ping node | <node>",
					proc => sub {node_rest_ping(@_) }},

		}},
	};

}

1;
