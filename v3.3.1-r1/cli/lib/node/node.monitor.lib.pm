#
# ETHER|AAPEN|CLI - LIB|NODE|MONITOR
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
#
#
sub node_rest_monitor_ping($node_name){
	my $fid = "node_rest_monitor_ping";
	my $result = rest_get_request("/service/monitor/ping?name=" . $node_name);
	api_rest_response_print($fid, $result, "node monitor ping");
}

#
#
#
sub node_rest_monitor_meta($node_name){
	my $fid = "node_rest_storage_ping";
	my $result = rest_get_request("/service/monitor/meta?name=" . $node_name);
	api_rest_response_print($fid, $result, "node monitor meta");
}

#
# node monitor cluster maintenance enable
#
sub node_monitor_maint_cluster_enable(){
	my $fid = "[node_monitor_maint_cluster_enable]";
	print "$fid enable maintenace mode\n";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my $length = @mon_index;
	
	print "\n";
	
	# print
	foreach my $mon (@mon_index){
		node_rest_service_env('monitor', 'maintenance_on', $mon);
	}
	
	sleep 2;
	node_monitor_maint_cluster_status();
	
}

#
# node monitor maintenance disable
#
sub node_monitor_maint_cluster_disable(){
	my $fid = "[node_monitor_maint_cluster_disable]";
	print "$fid disable maintenace mode\n";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my $length = @mon_index;
	
	print "\n";
	
	# print
	foreach my $mon (@mon_index){
		node_rest_service_env('monitor', 'maintenance_off', $mon);
	}
	
	node_monitor_maint_cluster_status();
	
}

#
# node monitor cluster status
#
sub node_monitor_maint_cluster_status(){
	my $fid = "[node_monitor_maint_cluster_status]";
	print "$fid cluster maintenace mode status\n";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my $length = @mon_index;
	
	print "\n";
	
	# print
	foreach my $mon (@mon_index){
		monitor_print($result, $mon);
	}
}

1;
