#
# ETHER|AAPEN|CLI - LIB|MONITOR
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
# LOCAL: list monitors [NULL]
#
sub cli_loc_monitor_list(){
	my $fid = "[cli_loc_cluster_ping]";

	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my $length = @mon_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "monitor", RESET, "] [$length] ----------------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	# print
	foreach my $mon (@mon_index){
		monitor_print($result, $mon);
	}

}

#
# print monitor info [NULL]
#
sub monitor_print($result, $mon){

	if(index_find($result->{'db'}{'node'}{'index'}, $mon)){
		print "  [", BOLD BLUE, $mon, RESET, "] id [", BOLD, $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'id'} , RESET,"] ";
		
		my $diff = date_str_diff_now($result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'date'});
		print " ver [", BOLD,  $result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'ver'} , RESET, "]";
		print " delta [", BOLD BLACK, $diff, RESET, "]";
		print " updated [", BOLD,  $result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'date'} , RESET, "]";
		print " prio [", BOLD,  $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'prio'} , RESET, "] - ";

		# check delta
		if($diff < 15){
			print "[", BOLD GREEN, "HEALTHY", RESET, "]";
		}
		elsif($diff < 30){
			print "[", BOLD GREEN, "WARNING", RESET, "]";
			
		}
		else{
			print "[", BOLD RED, "ERROR", RESET, "]";
		}	

		if($result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'master'}){
			print " [", BOLD MAGENTA, "MASTER", RESET, "]";
		}

		if(defined $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'maintenance'} && $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'maintenance'}){
			print " [", BOLD RED, "MAINTENANCE", RESET, "]";
		}

		print "\n";	
	}
	else{
		print "  [", BOLD BLUE, $mon, RESET, "] id [", BOLD, $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'id'} , RESET,"] ";
		print "- [", BOLD, "OFFLINE", RESET, "]\n";
	}	
	
}

#
# get monitor master [STRING]
#
sub monitor_get_master($result){
	my $fid = "[cli_loc_cluster_ping]";

	my $master;	
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});

	# process monitors
	foreach my $mon (@mon_index){
		
		# only process active nodes
		if(index_find($result->{'db'}{'node'}{'index'}, $mon)){
		
			if($result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'master'}){
				$master = $mon;
			}
		}
	}	
	
	return $master;
}

#
# ping agent
#
sub cli_loc_system_health(){
	my $fid = "[cli_loc_systen_health]";

	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));	
	my $metadata = $result->{'db'}{'system'};
	my $health = {};
	my @sys_index = index_split($metadata->{'index'});
	my $length = @sys_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "systems", RESET, "] [$length] ---------------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	#
	# process remote index
	#
	foreach my $system (@sys_index){
		my $sysdata = $metadata->{'db'}{$system};
		$health->{'meta'}{$system} = monitor_system_health($sysdata, $metadata->{'meta'}{$system});
	}	
	
}

#
# ping agent
#
sub cli_loc_system_health_overview(){
	my $fid = "[cli_loc_systen_health]";

	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my $metadata = $result->{'db'}{'system'};
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my @sys_index = index_split($metadata->{'index'});
	my $length = @sys_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "systems", RESET, "] [$length] ---------------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	#
	# process remote index
	#
	foreach my $system (@sys_index){
		my $sysdata = $metadata->{'db'}{$system};
		
		monitor_system_health($sysdata, $metadata->{'meta'}{$system});

		foreach my $mon (@mon_index){
			
			my $sysmeta = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'data'}{'systems'}{'meta'}{$system};
			monitor_overview_system_print($sysmeta, $mon);
		}

		print "\n";
	}	
}

#
# print object health
#
sub monitor_overview_system_print($meta, $mon){
	my $status = $meta->{'status'};
	

	if(exists $meta->{'state'} && ($meta->{'state'} eq "running")){

		if($meta->{'status'} eq "HEALTHY"){
			$status = "", BOLD GREEN, $meta->{'status'}, RESET, "";
		}
		
		my $diff = date_str_diff_now($meta->{'updated'});		
		print "    monitor [", BOLD, $mon, RESET, "] ver [", BOLD BLACK, $meta->{'ver'}, RESET, "] delta [", BOLD MAGENTA, $meta->{'delta'}, RESET, "] updated [$meta->{'updated'}] update delta ";
		
		if($diff < 60){
			print "[", BOLD GREEN, $diff, RESET, "]";
		}
		else{
			print "[", BOLD RED, $diff, RESET, "]";
		}
			
		print " state [$meta->{'state'}] status ";
		
		if($meta->{'status'} eq "HEALTHY"){
			print "[", BOLD GREEN, $meta->{'status'}, RESET, "]\n";
		}
		else{
			print "[", BOLD RED, $meta->{'status'}, RESET, "]\n";
		}
	}

}

#
# print object health
#
sub monitor_overview_node_print($meta, $mon){
	my $status = $meta->{'status'};
	

	print "MATCH!\n";
	#if(exists $meta->{'state'} && ($meta->{'state'} eq "running")){

		if($meta->{'status'} eq "HEALTHY"){
			$status = "", BOLD GREEN, $meta->{'status'}, RESET, "";
		}
		
		my $diff = date_str_diff_now($meta->{'updated'});		
		print "    monitor [", BOLD, $mon, RESET, "] ver [", BOLD BLACK, $meta->{'ver'}, RESET, "] delta [", BOLD MAGENTA, $meta->{'delta'}, RESET, "] updated [$meta->{'updated'}] update delta ";
		
		if($diff < 60){
			print "[", BOLD GREEN, $diff, RESET, "]";
		}
		else{
			print "[", BOLD RED, $diff, RESET, "]";
		}
			
		print " state [$meta->{'state'}] status ";
		
		if($meta->{'status'} eq "HEALTHY"){
			print "[", BOLD GREEN, $meta->{'status'}, RESET, "]\n";
		}
		else{
			print "[", BOLD RED, $meta->{'status'}, RESET, "]\n";
		}
	#}

}

#
# monitor hypervisor
#
sub monitor_node_health(){
	my $fid = "[monitor_node_health]";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	monitor_node($result);
}

#
# monitor hypervisor
#
sub monitor_node_health_overview(){
	my $fid = "[monitor_node_health_overview]";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my $metadata = $result->{'db'}{'node'};
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my @node_index = index_split($metadata->{'index'});
	my $length = @node_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "node", RESET, "] [$length]\n\n"; };

	# process remote index
	foreach my $node (@node_index){

		my $nodedata = $metadata->{'db'}{$node};
		monitor_node_header_print($metadata, $node);
		
		foreach my $mon (@mon_index){
			my $nodemeta = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'data'}{'nodes'}{'meta'}{$node};
			monitor_overview_node_print($nodemeta, $mon);
		}
		print "\n";
	}
}

#
# monitor hypervisor
#
sub monitor_storage_health(){
	my $fid = "[monitor_storage_health]";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	monitor_storage($result->{'db'}{'storage'}, $result->{'db'}{'node'});
}

#
# ping agent
#
sub monitor_storage_health_overview(){
	my $fid = "[monitor_storage_health_overview]";

	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my $metadata = $result->{'db'}{'storage'};
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my @stor_index = index_split($metadata->{'index'});
	my $length = @stor_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "storage", RESET, "] [$length] ---------------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	# process remote index
	foreach my $storage (@stor_index){
		monitor_storage_dev($result->{'db'}{'storage'}, $result->{'db'}{'node'}, $storage);
		
		foreach my $mon (@mon_index){
			my $stormeta = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'data'}{'storage'}{'meta'}{$storage};
			monitor_overview_print($stormeta, $mon);
		}

		print "\n";
	}	
}

#
# monitor hypervisor
#
sub cli_loc_monitor_alarm_show(){
	my $fid = "[cli_loc_monitor_storage_health]";

	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my $master = monitor_get_master($result);
	print "MONITOR MASTER [$master]\n\n";

	if(defined $result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}){

		my @obj_index = index_split($result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{'index'});
		
		foreach my $obj (@obj_index){
			#print " OBJECT [$obj]\n";
			
			my @obj_name_index = index_split($result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{'index'});
			
			foreach my $obj_name (@obj_name_index){
				#print "  NAME [$obj_name]\n";
			
				my @alarm_index = index_split($result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{'index'});
			
				foreach my $alarm_num (@alarm_index){
					
					if($result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'alarm'}){
						#print "ACTIVE ALARMS:\n";
						print "ALARM: object [$obj] name [$obj_name] id [$alarm_num] -";
						print " active [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'alarm'}]";
						print " state [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'state'}]";
						print " status [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'status'}] - ACTIVE";
						#print "  -- date [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'date'}]\n";
						#print " triggered [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'triggered'}]";
						#print " cleared [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'cleared'}]";
						#print " events [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'events'}]";
						#print " timer [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'timer'}]";
						json_encode_pretty($result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num});
					}
					else{
						#print "HISTORIC ALARMS:\n";
						print "ALARM: object [$obj] name [$obj_name] id [$alarm_num] -";
						#print "ALARM: [$obj]:[$obj_name]:[$alarm_num] -";
						print " active [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'alarm'}]";
						print " state [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'state'}]";
						print " status [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'status'}] - CLEARED\n";
						#print " date [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'date'}]";
						#print "   -- triggered [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'triggered'}]";
						#print " cleared [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'cleared'}]";
						#print " events [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'events'}]";
						#print " timer [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'timer'}]";
						json_encode_pretty($result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num});
					}
					
					print "\n";
					#print " active [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'active'}]";
					#print "  [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'active'}]";
					#print " active [$result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num}{'active'}]";
					#json_encode_pretty($result->{'db'}{'service'}{'monitor'}{'db'}{$master}{'data'}{'alarm'}{$obj}{$obj_name}{$alarm_num});
				
				}
			
			}
			
		}
		
	}
	else{
		
		print "no alarms registered\n";
	}

}

#
# monitor hypervisor
#
sub cli_loc_monitor_alarm_show_monitor($monitor){
	my $fid = "[cli_loc_monitor_storage_health]";

	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));

	if(index_find($result->{'db'}{'service'}{'monitor'}{'index'}, $monitor)){
		my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
		
		if(defined $result->{'db'}{'service'}{'monitor'}{'db'}{$monitor}{'data'}{'alarm'}){
			json_encode_pretty($result->{'db'}{'service'}{'monitor'}{'db'}{$monitor}{'data'}{'alarm'});
		}
		else{
			print "no alarms registered on monitor [$monitor]\n";
		}		
		
	}
	else{
		print "error: unknown monitor node [$monitor]. check monitor list for available monitors\n";
	}
}

#
# monitor hypervisor
#
sub cli_loc_monitor_service_hyper_health(){
	my $fid = "[cli_loc_monitor_hyper_health]";

	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	monitor_hyper($result);
}

#
# monitor hypervisor
#
sub cli_loc_monitor_service_hyper_health_overview(){
	my $fid = "[cli_loc_monitor_hyper_health]";
	my $result;
	
	my $metadata = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($metadata->{'db'}{'service'}{'monitor'}{'index'});

	my @hyper_index = index_split($metadata->{'db'}{'service'}{'hypervisor'}{'index'});
	my $length = @hyper_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "hypervisor", RESET, "] [$length] --------------------------------------------------------------------------------------------------------------------------\n"; };
	
	# process remote index
	foreach my $hyper (@hyper_index){

		if(index_find($metadata->{'db'}{'node'}{'index'}, $hyper)){

			my $nodedata = $metadata->{'db'}{'service'}{'hypervisor'}{'db'}{$hyper};
			my $diff = date_str_diff_now($metadata->{'db'}{'service'}{'hypervisor'}{'meta'}{$hyper}{'date'});
	
			monitor_hyper_header($result, $metadata->{'db'}{'service'}{'hypervisor'}{'meta'}{$hyper}, $nodedata, $hyper);
			
			foreach my $mon (@mon_index){
				my $hypermeta = $metadata->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'data'}{'service'}{'hypervisor'}{$hyper};
				
				# services does not have versions - todo
				$hypermeta->{'ver'} = "n/a";
				monitor_overview_print($hypermeta, $mon);
			}
		
		}
	}

}

#
# monitor hypervisor
#

sub cli_loc_monitor_service_network_health(){
	my $fid = "[cli_loc_monitor_hyper_health]";
	
	my $metadata = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	monitor_net_serv($metadata->{'db'}{'service'}{'network'});
}

#
# monitor hypervisor
#
sub cli_loc_monitor_service_network_health_overview(){
	my $fid = "[cli_loc_monitor_hyper_health]";
	
	my $metadata = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($metadata->{'db'}{'service'}{'monitor'}{'index'});
	my @node_index = index_split($metadata->{'db'}{'service'}{'network'}{'index'});
	my $length = @node_index;

	if(env_verbose()){ print "\n\n[", BOLD BLUE, "network", RESET, "] [$length] ----------------------------------------------------------------------------------------------------------------------------\n\n"; };

	# process remote index
	foreach my $node (@node_index){
		
		my $nodedata = $metadata->{'db'}{$node};
		monitor_net_serv_header($metadata->{'db'}{'service'}{'network'}, $node);

		foreach my $mon (@mon_index){
			my $hypermeta = $metadata->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'data'}{'service'}{'network'}{$node};
			
			# service objects does not have versions - todo
			$hypermeta->{'ver'} = "n/a";
			monitor_overview_print($hypermeta, $mon);
		}

		print "\n";
	}

}

#
# monitor hypervisor
#
sub cli_loc_monitor_service_storage_health(){
	my $fid = "[cli_loc_monitor_hyper_health]";

	my $metadata = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	json_encode_pretty($metadata);
	
	monitor_stor_serv($metadata);
	
	#my $metadata = $result;
	
	#monitor_net_serv($result);
	#monitor_serv_framework($metadata->{'db'}{'service'}{'storage'});
	#cli_mon_serv_network_show();
	
	#cli_loc_monitor_hyper_health()

}

#
# monitor hypervisor
#
sub cli_loc_monitor_service_storage_health_overview(){
	my $fid = "[cli_loc_monitor_hyper_health]";

	my $metadata = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($metadata->{'db'}{'service'}{'monitor'}{'index'});
	my @node_index = index_split($metadata->{'db'}{'service'}{'storage'}{'index'});
	my $length = @node_index;

	if(env_verbose()){ print "\n\n[", BOLD BLUE, "storage", RESET, "] [$length] ----------------------------------------------------------------------------------------------------------------------------\n\n"; };

	# process remote index
	foreach my $node (@node_index){
		
		my $nodedata = $metadata->{'db'}{$node};
		print "NODE [$node]\n";

		foreach my $mon (@mon_index){
			my $stormeta = $metadata->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'data'}{'service'};
			
			json_encode_pretty($stormeta);
			
		}

		print "\n";
	}

}

#
# monitor hypervisor
#
sub cli_loc_monitor_service_framework_health(){
	my $fid = "[cli_loc_monitor_hyper_health]";
	
	my $metadata = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	monitor_serv_framework($metadata->{'db'}{'service'}{'framework'});
}

#
# monitor hypervisor
#
sub cli_loc_monitor_service_framework_health_overview(){
	my $fid = "[cli_loc_monitor_hyper_health]";
	
	my $metadata = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my @mon_index = index_split($metadata->{'db'}{'service'}{'monitor'}{'index'});
	my @node_index = index_split($metadata->{'db'}{'service'}{'framework'}{'index'});
	my $length = @node_index;

	if(env_verbose()){ print "\n\n[", BOLD BLUE, "framework", RESET, "] [$length] ----------------------------------------------------------------------------------------------------------------------------\n\n"; };

	# process remote index
	foreach my $node (@node_index){
		
		monitor_serv_framework_header($metadata->{'db'}{'service'}{'framework'}, $node);

		foreach my $mon (@mon_index){
			
			if(index_find($metadata->{'db'}{'node'}{'index'}, $mon)){

				my $stormeta = $metadata->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'data'}{'service'}{'framework'}{$node};
				
				# services does not have versions - todo
				$stormeta->{'ver'} = "n/a";
				#json_encode_pretty($stormeta);
				
				monitor_overview_print($stormeta, $mon);

			}
		}

		print "\n";
	}

}

1;
