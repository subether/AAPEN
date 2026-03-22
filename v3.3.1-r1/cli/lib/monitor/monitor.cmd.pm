#
# ETHER|AAPEN|CLI - LIB|MONITOR|CMD
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
sub monitor_cmd(){

	return  {
		"monitor" => {
			desc => "cluster health monitor",
			cmds => {
				"service" => {
					desc => "service monitor management",
					cmds => {	
						"hypervisor" => {
							desc => "hypervisor service monitor management",
							cmds => {	
								"list" => {
									desc => "show health (local)",
									proc => sub { cli_loc_monitor_service_hyper_health() }},
								"overview" => {
									desc => "system monitor | <node>",
									proc => sub { cli_loc_monitor_service_hyper_health_overview() }},
						}},
						"storage" => {
							desc => "storage service monitor management",
							cmds => {	
								"list" => {
									desc => "show health (local)",
									proc => sub { cli_loc_monitor_service_storage_health() }},
								"overview" => {
									desc => "system monitor | <node>",
									proc => sub { cli_loc_monitor_service_storage_health_overview() }},
						}},
						"network" => {
							desc => "network service monitor management",
							cmds => {	
								"list" => {
									desc => "show health (local)",
									proc => sub { cli_loc_monitor_service_network_health() }},
								"overview" => {
									desc => "system monitor | <node>",
									proc => sub { cli_loc_monitor_service_network_health_overview() }},
						}},
						"framework" => {
							desc => "network service framework management",
							cmds => {	
								"list" => {
									desc => "show health (local)",
									proc => sub { cli_loc_monitor_service_framework_health() }},
								"overview" => {
									desc => "system monitor | <node>",
									proc => sub { cli_loc_monitor_service_framework_health_overview() }},
						}},
				}},
				"system" => {
					desc => "system monitor management",
					cmds => {	
						"list" => {
							desc => "system health (local)",
							proc => sub { cli_loc_system_health() }},
						"overview" => {
							desc => "system monitor | <node>",
							proc => sub { cli_loc_system_health_overview() }},
				}},
				"node" => {
					desc => "node monitor management",
					cmds => {	
						"list" => {
							desc => "node monitor (local)",
							proc => sub { monitor_node_health() }},
						"overview" => {
							desc => "node monitor | <node>",
							proc => sub { monitor_node_health_overview() }},
				}},
				"storage" => {
					desc => "storage monitor management",
					cmds => {	
						"list" => {
							desc => "system monitor (local)",
							proc => sub { monitor_storage_health() }},
						"overview" => {
							desc => "system monitor | <node>",
							proc => sub { monitor_storage_health_overview() }},
				}},
				"alarm" => {
					desc => "monitor alarm management",
					cmds => {	
						"list" => {
							desc => "show alamrs (local)",
							proc => sub { cli_loc_monitor_alarm_show() }},
						"node" => {
							desc => "show alarms from monitor | <node>",
							proc => sub { cli_loc_monitor_alarm_show_monitor(@_) }},
						"overview" => {
							desc => "show alarms from all monitors",
							proc => sub { quote() }},
						"clear" => {
							desc => "clear alarms on monitor | <node>",
							proc => sub { quote() }},
				}},
				"list" => {
					desc => "list active cluster monitors",
					proc => sub { cli_loc_monitor_list() }},
		}},
	
	};

}

1;
