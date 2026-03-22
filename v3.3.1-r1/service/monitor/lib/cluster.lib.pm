#
# ETHER|AAPEN|MONITOR - LIB|CLUSTER
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#

use warnings;
use strict;
use experimental 'signatures';
use JSON::MaybeXS;
use TryCatch;


#
# get cluster metadata
#
sub mon_cluster_get_meta(){
	my $fid = "[mon_cluster_get_meta]";
	
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	
	my $health = {};
	my $date = date_get();

	if(env_verbose()){ print "\n\n\n[", BOLD MAGENTA, "cluster", RESET, "] updating at [", BOLD, $date, RESET, "] -----------------------------------------------------------------------------------------------"; };
	$health->{'meta'}{'updated'} = $date;
	
	if($result->{'proto'}{'result'}){
		#
		# SERVICE
		#
	
		# service framework
		$health->{'service'}{'framework'} = monitor_frame_serv($result->{'db'}{'service'}{'framework'});
	
		# service network
		$health->{'service'}{'network'} = monitor_net_serv($result->{'db'}{'service'}{'network'});
		
		# service hypervisor
		$health->{'service'}{'hypervisor'} = monitor_hyper_serv($result);

		# service storage
		#$health->{'service'}{'storage'} = monitor_stor_serv($result);
	
		#
		# OBJECTS
		#
	
		# network
		$health->{'networks'} = monitor_network($result->{'db'}{'network'}, $result->{'db'}{'service'}{'network'}{'index'});
	
		# systems
		$health->{'systems'} = monitor_system($result->{'db'}{'system'});
		
		# nodes
		$health->{'nodes'} = monitor_node($result);
		
		# storage
		$health->{'storage'} = monitor_storage($result->{'db'}{'storage'}, $result->{'db'}{'node'});
		
		# node priority
		monitor_prio($result);
	}
	
	if(env_verbose()){ print "\n[", BOLD MAGENTA, "cluster", RESET, "] update complete -----------------------------------------------------------------------------------------------------------------\n"; };
		
	monitor_cdb_sync($health);
}

#
# sync with cdb [NULL]
#
sub monitor_cdb_sync($health){
	my $fid = "[network_cdb_sync]";
	my $config = monitor_db_obj_get("config");
	my $alarm = monitor_db_obj_get("alarm");
	my $meta = {};
	
	# config
	$meta->{'updated'} = date_get();

	$meta->{'config'}{'service'} = "monitor";
	$meta->{'config'}{'name'} = $config->{'name'};
	$meta->{'config'}{'id'} = $config->{'id'};
	$meta->{'config'}{'prio'} = $config->{'prio'};
	$meta->{'config'}{'master'} = monitor_is_master();
	$meta->{'config'}{'maintenance'} = env_maintenance();
	
	$meta->{'data'} = $health;
	$meta->{'data'}{'alarm'} = $alarm;
	
	#json_encode_pretty($meta->{'config'});
	
	my $result = api_cluster_local_service_set(env_serv_sock_get("cluster"), $meta);
}

#
# calcualte node priority [NULL]
#
sub monitor_prio($result){
	my $config = monitor_db_obj_get("config");

	my $master = {};
	$master->{'prio'} = 100;
	$master->{'value'} = 0;
	$master->{'id'} = "";
	$master->{'name'} = "";
	
	my @mon_index = index_split($result->{'db'}{'service'}{'monitor'}{'index'});
	my $length = @mon_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "service|monitor", RESET, "] [$length] ---------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	# find master
	foreach my $mon (@mon_index){
		
		# only process active nodes
		if(index_find($result->{'db'}{'node'}{'index'}, $mon)){
		
		my $diff = date_str_diff_now($result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'date'});
		
			if($diff < 30){
			
				# lowest priority becomes master
				if($result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'prio'} <= $master->{'prio'}){
					
					# if same priority, oldest becomes master
					if($result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'prio'} == $master->{'prio'}){
						
						if($result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'ver'} > $result->{'db'}{'service'}{'monitor'}{'meta'}{$master->{'name'}}{'ver'}){
							$master->{'id'} = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'id'};
							$master->{'name'} = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'name'};
							$master->{'prio'} = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'prio'};		
						}
					}
					else{
						$master->{'id'} = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'id'};
						$master->{'name'} = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'name'};
						$master->{'prio'} = $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'prio'};				
						
					}
				}
			}
		}
	}
	
	#print "[MARK]";
	
	# print monitors
	foreach my $mon (@mon_index){
		
		# only process active nodes
		if(index_find($result->{'db'}{'node'}{'index'}, $mon)){
		
			if(env_verbose()){ print "  [", BOLD BLUE, $mon, RESET, "] id [", BOLD, $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'id'} , RESET,"]"; };
			
			my $diff = date_str_diff_now($result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'date'});
			if(env_verbose()){ 
				print " ver [", BOLD,  $result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'ver'} , RESET, "]";
				print " delta [", BOLD BLACK, $diff, RESET, "]";
				print " updated [", BOLD,  $result->{'db'}{'service'}{'monitor'}{'meta'}{$mon}{'date'} , RESET, "]";
				print " prio [", BOLD,  $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'prio'} , RESET, "] - ";
			}

			# check delta
			if($diff < 30){
				if(env_verbose()){ print "[", BOLD GREEN, "HEALTHY", RESET, "]"; };
				alarm_unset("monitor", $mon);
			}
			elsif($diff < 120){
				if(env_verbose()){ print "[", BOLD YELLOW, "WARNING", RESET, "]"; };
				
			}
			else{
				if(env_verbose()){ print "[", BOLD RED, "ERROR", RESET, "]"; };
				alarm_set("monitor", $mon, "ERROR", "UNAVAIL");
			}	
			
			# flag master
			if($master->{'id'} eq $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'id'}){
				if(env_verbose()){ print " [", BOLD MAGENTA, "MASTER", RESET, "]"; };
			}

			## self flag
			if(config_node_id_get() eq $result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'id'}){
				if(env_verbose()){ print " [", BOLD MAGENTA, "SELF", RESET, "]"; };
			}

			# maintenance flag
			if($result->{'db'}{'service'}{'monitor'}{'db'}{$mon}{'config'}{'maintenance'}){
				if(env_verbose()){ print " [", BOLD RED, "MAINTENANCE", RESET, "]"; };
			}
			
			if(env_verbose()){ print "\n"; };
		}
	}
	
	$config->{'master'} = $master;
	monitor_db_obj_set("config", $config);
}

#
# check if monitor is master [BOOL]
#
sub monitor_is_master(){
	my $fid = "[monitor_is_master]";
	my $config = monitor_db_obj_get("config");
	my $master = $config->{'master'};
	
	if(defined $config->{'master'}){
		if(env_debug()){ print "MASTER ELECTION HAS COMPLETED\n"; };
		if(config_node_id_get() eq $master->{'id'}){ return 1; }
		else{ return 0; }
	}
	else{
		print "$fid WAITING FOR MASTER ELECTION...\n";
		return 0;
	}

}

1;
