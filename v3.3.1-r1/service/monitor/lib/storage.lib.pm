#
# ETHER|AAPEN|MONITOR - LIB|STORAGE
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
# monitor storage []
#
sub monitor_storage($metadata, $nodes){
	my $fid = "[monitor_node]";
	
	my $health = {};
	$health->{'index'}{'healthy'} = "";
	$health->{'index'}{'unknown'} = "";
	$health->{'index'}{'error'} = "";
	$health->{'index'}{'warning'} = "";
	
	#
	# hypervisor
	#
	my @storage_index = index_split($metadata->{'index'});
	
	my @node_index = index_split($nodes->{'index'});
	my $length = @storage_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "storage", RESET, "] [$length] ----------------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	#
	# process remote index
	#
	foreach my $storage (@storage_index){

		my $stordata = $metadata->{'db'}{$storage};
		
		# COMPAT FOR MASTER BUG
		my $healthy = 1;
		
		# ignore iso
		if($stordata->{'object'}{'model'} ne "iso"){
			if(env_verbose()){ print "  [", BOLD BLUE, $storage, RESET, "] id [", BOLD, $stordata->{'id'}{'id'} , RESET,"] "; };
			if(env_verbose()){ print "ver [" . $metadata->{'meta'}{$storage}{'ver'} . "] "; };
			$health->{'meta'}{$storage}{'ver'} = $metadata->{'meta'}{$storage}{'ver'};
		}
		
		if($stordata->{'object'}{'model'} eq "device"){
			
			if(env_verbose()){ print "type [", BOLD, "device", RESET, "] "; };
			
			my $owner = $stordata->{'node'}{'name'};
			
			$health->{'meta'}{$storage}{'model'} = "device";
			$health->{'meta'}{$storage}{'owner'} = $owner;
			
			# COMPAT FOR POLLY/MASTER CLUSTER ERROR
			$stordata->{'meta'}{'stats'}{$owner} = $metadata->{'stats'}{$storage}{$owner};
			

			if(defined ($stordata->{'meta'}{'date'})){
				#
				# mdraid
				#
				if($stordata->{'object'}{'class'} eq "mdraid"){
					if(env_verbose()){ print "[", BOLD BLACK, $stordata->{'object'}{'class'}, RESET, "] "; };
					
					my $mddev = $stordata->{'mdraid'}{'node'};
	
					# check if sate active
					if($stordata->{'meta'}{'mdraid'}{$mddev}{'state'} eq "active"){
						if(env_verbose()){ print "mdraid [", BOLD, $stordata->{'meta'}{'mdraid'}{$mddev}{'state'}, RESET, "] "; };
						$health->{'meta'}{$storage}{'mdraid'}{'state'} = $stordata->{'meta'}{'mdraid'}{$mddev}{'state'};
						$health->{'meta'}{$storage}{'mdraid'}{'state'} = $stordata->{'meta'}{'mdraid'}{$mddev}{'state'};
					}
					else{
						if(env_verbose()){ print "mdraid [", BOLD RED, $stordata->{'meta'}{'mdraid'}{$mddev}{'state'}, RESET, "] "; };
						$health->{'meta'}{$storage}{'mdraid'}{'state'} = $stordata->{'meta'}{'mdraid'}{$mddev}{'state'};
						$health->{'meta'}{$storage}{'warning'}{'mdraid'}{'disk_state'} = $stordata->{'meta'}{'mdraid'}{$mddev}{'disk_state'};
						$healthy = 0;
						alarm_set("storage", $owner, "MDRAID ARRAY", "MDRAID array status [" . $health->{'meta'}{$storage}{'warning'}{'mdraid'}{'disk_state'} . "]");
					}
					
					if(defined $stordata->{'meta'}{'mdraid'}{$mddev}{'disk_status'}){
					
						# check if disk status 
						if($stordata->{'meta'}{'mdraid'}{$mddev}{'disk_status'} !~ "_"){
							if(env_verbose()){ print "status $stordata->{'meta'}{'mdraid'}{$mddev}{'disk_status'} "; };
						}
						else{
							if(env_verbose()){ print "status ", BOLD RED, $stordata->{'meta'}{'mdraid'}{$mddev}{'disk_status'}, RESET, " "; };
							$health->{'meta'}{$storage}{'warning'}{'mdraid'}{'disk_status'} = $stordata->{'meta'}{'mdraid'}{$mddev}{'disk_status'};
							$healthy = 0;
							alarm_set("storage", $owner, "MDRAID DEVICE", "MDRAID disk status [" . $health->{'meta'}{$storage}{'warning'}{'mdraid'}{'disk_status'} . "]");
						}
					}
					
					# temperature
					my @dev_index = index_split($stordata->{'mdraid'}{'devices'});
					
					$health->{'meta'}{$storage}{'smart'}{'temperature'} = "NORMAL";
					$health->{'meta'}{$storage}{'smart'}{'self_test'} = "NORMAL";
					$health->{'meta'}{$storage}{'smart'}{'smart_test'} = "HEALTHY";
					
					foreach my $dev (@dev_index){

						if(defined $stordata->{'meta'}{'smart'}{$dev}{'temperature'}){
							
							# check temperature
							if($stordata->{'meta'}{'smart'}{$dev}{'temperature'} < 45){
								#print "temp [NORMAL] ";
							}
							else{
								if(env_verbose()){ print "temp [HIGH] ($stordata->{'meta'}{'smart'}{$dev}{'temperature'})"; };
								$health->{'meta'}{$storage}{'smart'}{'temperature'} = "HIGH [$stordata->{'meta'}{'smart'}{$dev}{'temperature'}]";
								$health->{'meta'}{$storage}{'warning'}{'smart'}{$dev}{'temperature'} = $stordata->{'meta'}{'smart'}{$dev}{'temperature'};
								$health->{'meta'}{$storage}{'smart'}{'temperature'} = "WARNING";
								$healthy = 0;
							}
						}
						
						# self test
						if($stordata->{'meta'}{'smart'}{$dev}{'self_test_passed'} eq "true"){
							#print "self test [NORMAL] ";
						}
						else{
							if(env_verbose()){ print "self test [ERROR] "; };
							$health->{'meta'}{$storage}{'smart'}{'self_test'} = "ERROR";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{$dev}{'self_test'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{$dev}{'self_test_passed'};
							$healthy = 0;
						}
						
						# smart check
						if($stordata->{'meta'}{'smart'}{$dev}{'smart_passed'} eq "true"){
							#print "smart test [NORMAL] ";
						}
						else{
							if(env_verbose()){ print "smart test [ERROR] "; };
							$health->{'meta'}{$storage}{'smart'}{'smart_test'} = "ERROR";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{$dev}{'smart_test'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{$dev}{'smart_passed'};
							$healthy = 0;
						}
					}
				}
				
				#
				# device
				#
				if($stordata->{'object'}{'class'} eq "disk"){
					if(env_verbose()){ print "[", BOLD BLACK, $stordata->{'object'}{'class'}, RESET, "] "; };
				
					# need better check!
					if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'firmware'}){
						$health->{'meta'}{$storage}{'smart'}{'supported'} = 1;
				
						# check temperature
						if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'} < 45){
							#print "temp [NORMAL] ";
							$health->{'meta'}{$storage}{'smart'}{'temperature'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'};
						}
						else{
							if(env_verbose()){ print "temp [HIGH] ($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'})"; };
							$health->{'meta'}{$storage}{'smart'}{'temperature'} = "HIGH [$stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'}]";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{'temperature'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'};
							$healthy = 0;
						}
						
						# self test
						if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'self_test_passed'} eq "true"){
							#print "self test [NORMAL] ";
						}
						else{
							if(env_verbose()){ print "self test [ERROR] "; };
							$health->{'meta'}{$storage}{'smart'}{'self_test'} = "ERROR";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{'self_test'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{'self_test_passed'};
							$healthy = 0;
						}
						
						# smart status
						if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'smart_passed'} eq "true"){
							#print "smart test [NORMAL] ";
						}
						else{
							if(env_verbose()){ print "smart test [ERROR]"; };
							$health->{'meta'}{$storage}{'smart'}{'smart_test'} = "ERROR";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{'smart_test'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{'smart_passed'};
							$healthy = 0;
						}
					
					}
					else{
						$health->{'meta'}{$storage}{'smart'}{'supported'} = 0;
					}
				}

				#
				# nvme
				#
				if($stordata->{'object'}{'class'} eq "nvme"){
					if(env_verbose()){ print "[", BOLD BLACK, $stordata->{'object'}{'class'}, RESET, "] "; };
				
					# need better check!
					if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'firmware'}){
						$health->{'meta'}{$storage}{'smart'}{'supported'} = 1;
				
						# check temperature
						if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'} < 40){
							#print "temp [NORMAL] ";
						}
						else{
							if(env_verbose()){ print "temp [HIGH] ($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'})"; };
							$health->{'meta'}{$storage}{'smart'}{'temperature'} = "high";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{'temperature'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{'temperature'};
							$healthy = 0;
						}
						
						#  self test
						if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'self_test_passed'} eq "true"){
							#print "self test [NORMAL] ";
						}
						else{
							if(env_verbose()){ print "self test [ERROR] "; };
							$health->{'meta'}{$storage}{'smart'}{'self_test'} = "error";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{'self_test'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{'self_test_passed'};
							$healthy = 0;
						}
						
						# smart passed
						if($stordata->{'meta'}{'stats'}{$owner}{'smart'}{'smart_passed'} eq "true"){
							#print "smart test [NORMAL] ";
						}
						else{
							if(env_verbose()){ print "smart test [ERROR]"; };
							$health->{'meta'}{$storage}{'smart'}{'smart_test'} = "error";
							$health->{'meta'}{$storage}{'warning'}{'smart'}{'smart_test'} = $stordata->{'meta'}{'stats'}{$owner}{'smart'}{'smart_passed'};
							$healthy = 0;
						}
					}
					else{
						$health->{'meta'}{$storage}{'smart'}{'supported'} = 0;
					}
				}				

				my $diff = date_str_diff_now($stordata->{'meta'}{'date'});
				if(env_verbose()){ print "delta [", BOLD BLACK, $diff, RESET, "] "; };
				
				# overall health
				if(defined ($stordata->{'meta'}{'status'})){
					if(env_verbose()){ print "status [$stordata->{'meta'}{'status'}] "; };
				}
				else{
					if(env_verbose()){ print "status [$stordata->{'meta'}{'status'}] "; };
					$health->{'meta'}{$storage}{'warning'}{'status'} = $stordata->{'meta'}{'status'};
					$healthy = 0;
				}
				
				if($diff < 360){
					$health->{'meta'}{$storage}{'state'} = "ONLINE";
					$health->{'meta'}{$storage}{'status'} = "HEALTHY";
					$health->{'meta'}{$storage}{'delta'} = $diff;
				}
				else{
					$health->{'meta'}{$storage}{'status'} = "WARNING";
					$health->{'meta'}{$storage}{'state'} = "WARNING";
					$health->{'meta'}{$storage}{'warning'}{'delta_check'} = $diff;
					$health->{'meta'}{$storage}{'delta'} = $diff;
					$healthy = 0;
				}
			}
			else{
				
				$health->{'meta'}{$storage}{'state'} = "OFFLINE";
				$health->{'meta'}{$storage}{'status'} = "OFFLINE";
			}	
		}
		
		#
		# POOL
		#
		if($stordata->{'object'}{'model'} eq "pool"){
			if(env_verbose()){ print "type [", BOLD, "pool", RESET, "] "; };
			
			if(defined $metadata->{'stats'}{$storage}){
				$stordata->{'meta'}{'stats'} = $metadata->{'stats'}{$storage}
			}
			
			# pool object
			$health->{'meta'}{$storage}{'model'} = "pool";
			$health->{'meta'}{$storage}{'nodes'}{'active'} = 0;
			$health->{'meta'}{$storage}{'nodes'}{'healthy'} = 0;
			$health->{'meta'}{$storage}{'nodes'}{'error'} = 0;
			$health->{'meta'}{$storage}{'delta'} = 0;
			
			my $owner = $stordata->{'owner'}{'name'};
			
			if(defined ($stordata->{'meta'}{'stats'}{$owner})){
			
				if(defined ($stordata->{'meta'}{'stats'}{$owner}{'date'})){
					
					my $diff = date_str_diff_now($stordata->{'meta'}{'stats'}{$owner}{'date'});
						if(env_verbose()){  print "delta [", BOLD BLACK, $diff, RESET, "] "; };
						if($diff < 360){
							if(env_verbose()){ print "owner [", BOLD, "healthy", RESET, "] - "; };
							$health->{'meta'}{$storage}{'owner'}{'state'} = "HEALTHY";
							$health->{'meta'}{$storage}{'owner'}{'status'} = "ONLINE";
							$health->{'meta'}{$storage}{'owner'}{'delta'} = $diff;
							
							$health->{'meta'}{$storage}{'state'} = "HEALTHY";
							$health->{'meta'}{$storage}{'status'} = "ONLINE";
						}
						else{
							$health->{'meta'}{$storage}{'owner'}{'state'} = "ERROR";
							$health->{'meta'}{$storage}{'owner'}{'status'} = "WARNING";
							$health->{'meta'}{$storage}{'owner'}{'delta'} = $diff;
							$health->{'meta'}{$storage}{'warning'}{'owner'}{'delta'} = $diff;
							if(env_verbose()){ print "owner [", BOLD GREEN, "WARNING", RESET, "] - "; };
							
							$health->{'meta'}{$storage}{'state'} = "WARNING";
							$health->{'meta'}{$storage}{'status'} = "OWNER OFFLINE";
						}

					$health->{'meta'}{$storage}{'delta'} = $diff;
				}
			
			}
			else{
				$health->{'meta'}{$storage}{'owner'}{'state'} = "OFFLINE";
				$health->{'meta'}{$storage}{'state'} = "OFFLINE";
				$health->{'meta'}{$storage}{'status'} = "OFFLINE";
				if(env_verbose()){ print "owner [", BOLD, "OFFLINE", RESET, "] - "; };
			}

			#
			# node storage
			#
			foreach my $node (@node_index){
				
				if(defined ($stordata->{'meta'}{'stats'}{$node})){

					if(defined ($stordata->{'meta'}{'stats'}{$node}{'date'})){
						
						my $diff = date_str_diff_now($stordata->{'meta'}{'stats'}{$node}{'date'});
						if($diff < 360){
							$health->{'index'}{'healthy'} = index_add($health->{'index'}{'healthy'}, $storage);
							$health->{'meta'}{$storage}{'node'}{$node}{'name'} = $node;
							$health->{'meta'}{$storage}{'node'}{$node}{'delta'} = $diff;
							$health->{'meta'}{$storage}{'node'}{$node}{'status'} = "HEALTHY";
							$health->{'meta'}{$storage}{'node'}{$node}{'state'} = "ONLINE";
							$health->{'meta'}{$storage}{'nodes'}{'healthy'}++;
							
						}
						else{
							if(env_verbose()){ print "[", BOLD RED, "WARNING", RESET, "] "; };
							$health->{'index'}{'warning'} = index_add($health->{'index'}{'warning'}, $storage);
							$health->{'meta'}{$storage}{'node'}{$node}{'name'} = $node;
							$health->{'meta'}{$storage}{'node'}{$node}{'delta'} = $diff;
							$health->{'meta'}{$storage}{'node'}{$node}{'status'} = "WARNING";
							$health->{'meta'}{$storage}{'node'}{$node}{'state'} = "OFFLINE";
							$health->{'meta'}{$storage}{'nodes'}{'error'}++;
						}
						
					}
				}
				
				$health->{'meta'}{$storage}{'index'} = index_add($health->{'meta'}{$storage}{'index'}, $node);
				$health->{'meta'}{$storage}{'nodes'}{'active'}++;
			}
			
			if(env_verbose()){ print "subscribers [$health->{'meta'}{$storage}{'nodes'}{'active'}] healthy [$health->{'meta'}{$storage}{'nodes'}{'healthy'}] error [$health->{'meta'}{$storage}{'nodes'}{'error'}] "; };
		}
		
		# ignore iso
		if($stordata->{'object'}{'model'} ne "iso"){
		
			if($healthy){
				if(env_verbose()){ print "- [", BOLD GREEN, "HEALTHY", RESET, "]"; };
				$health->{'meta'}{$storage}{'status'} = "HEALTHY";
				$health->{'meta'}{$storage}{'state'} = "ONLINE";
				$health->{'meta'}{$storage}{'updated'} = date_get();
				$health->{'index'}{'healthy'} = index_add($health->{'index'}{'healthy'}, $storage);
			}
			else{
				if(env_verbose()){ print "- [", BOLD RED, "WARNING", RESET, "]"; };
				$health->{'meta'}{$storage}{'status'} = "WARNING";
				$health->{'meta'}{$storage}{'state'} = "WARNING";
				$health->{'meta'}{$storage}{'updated'} = date_get();
				$health->{'index'}{'warning'} = index_add($health->{'index'}{'warning'}, $storage);
			}

			if(env_verbose()){ print "\n"; };
		
		}
	}	
	
	return $health;
}

#
# device health check [BOOL, JSON-OBJ]
#
sub device_health_smart($devdata, $dev){
	my $health = {};
	my $healthy = 1;

	# check temperature
	if($devdata->{'temperature'} < 40){
		if(env_verbose()){ print "temp [NORMAL]"; };
	}
	else{
		if(env_verbose()){ print "temp [HIGH]"; };
		$health->{'temperature'} = "high";
		$health->{$dev}{'temperature'} = $devdata->{'temperature'};
		$healthy = 0;
	}
	
	# check temperature
	if($devdata->{'self_test_passed'} eq "true"){
		if(env_verbose()){ print "self test [NORMAL]"; };
	}
	else{
		if(env_verbose()){ print "self test [ERROR]"; };
		$health->{'self_test'} = "error";
		$health->{'meta'}{$dev}{'self_test'} = $devdata->{'self_test_passed'};
		$healthy = 0;
	}
	
	# check temperature
	if($devdata->{'smart_passed'} eq "true"){
		if(env_verbose()){ print "smart test [NORMAL]"; };
	}
	else{
		if(env_verbose()){ print "smart test [ERROR]"; };
		$health->{'smart_test'} = "error";
		$health->{$dev}{'smart_test'} = $devdata->{'smart_passed'};
		$healthy = 0;
	}

	return ($healthy, $health);
}

#
# monitor framework service [NULL]
#
sub monitor_stor_serv($metadata){
	my $fid = "[monitor_stor_serv]";
	my $result;
	my @frame_index = index_split($metadata->{'index'});
	my $length = @frame_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "service|storage", RESET, "] [$length] ---------------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	#
	# process remote index
	#
	foreach my $frame (@frame_index){

		my $framedata = $metadata->{'db'}{$frame};
		my $framemeta = $metadata->{'meta'}{$frame};
		
		if(env_verbose()){
			print "  [", BOLD BLUE, $frame, RESET, "] id [", BOLD, $framedata->{'config'}{'id'} , RESET,"] ";
			print "vmm index [", BOLD, $framedata->{'vmm'}{'index'} , RESET,"]";
			print " ver [", BOLD BLACK, $framemeta->{'ver'} , RESET, "]";
		}

		my $diff = date_str_diff_now($framemeta->{'date'});
		if(env_verbose()){ 
			print " delta [", BOLD BLACK, $diff, RESET, "]";
			print " updated [", BOLD,  $framemeta->{'date'} , RESET, "] - ";
		}
		
		# check delta
		if($diff < 180){
			if(env_verbose()){ print "[", BOLD GREEN, "HEALTHY", RESET, "]\n"; };
			$result->{$frame}{'status'} = "HEALTHY";
			$result->{$frame}{'state'} = "ACTIVE";
			$result->{$frame}{'delta'} = $diff;
			$result->{$frame}{'updated'} = date_get();
		}
		else{
			if(env_verbose()){ print "[", BOLD RED, "ERROR", RESET, "]\n"; };
			$result->{$frame}{'status'} = "ERROR";
			$result->{$frame}{'state'} = "UNKNOWN";
			$result->{$frame}{'delta'} = $diff;
			$result->{$frame}{'updated'} = date_get();
		}		

		#
		# SERVICE
		#
		my @srv_index = index_split($framedata->{'service'}{'index'});
		
		foreach my $service (@srv_index){

			if(env_verbose()){
				print "    '- service [", BOLD, $service, RESET, "]";
				print " pid [", BOLD BLACK, $framedata->{'service'}{$service}{'pid'} , RESET, "]";
				print " state [", BOLD BLACK, $framedata->{'service'}{$service}{'state'} , RESET, "]";
				print " status [", BOLD BLACK, $framedata->{'service'}{$service}{'status'} , RESET, "]";
				print "\n"
			}
		}
		
		#
		# VMMs
		#
		my @vmm_index = index_split($framedata->{'vmm'}{'index'});
		
		foreach my $vmm (@vmm_index){
			my $up = date_str_uptime_short($framedata->{'vmm'}{$vmm}{'date'});
			
			if(env_verbose()){
				print "    '- vmm [", BOLD, $vmm, RESET, "]";
				print " system [", BOLD BLUE, $framedata->{'vmm'}{$vmm}{'system_name'} , RESET, "]";
				print " id [", BOLD BLACK, $framedata->{'vmm'}{$vmm}{'system_id'} , RESET, "]";
				print " socket [", BOLD BLACK, $framedata->{'vmm'}{$vmm}{'socket'} , RESET, "]";
				print " pid [", BOLD BLACK, $framedata->{'vmm'}{$vmm}{'pid'} , RESET, "]";
				print " up [", BOLD BLACK, $up, RESET, "]\n";				
			}
		}

		if(env_verbose()){ print "\n"; };
	}
	
	return $result;
}

1;
