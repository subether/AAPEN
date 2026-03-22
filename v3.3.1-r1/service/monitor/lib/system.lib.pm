#
# ETHER|AAPEN|MONITOR - LIB|SYSTEM
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
use Number::Bytes::Human qw(format_bytes);

#
# monitor systems [JSON-OBJ]
#
sub monitor_system($metadata){
	my $fid = "[monitor_system]";
	my $health = {};
	my @sys_index = index_split($metadata->{'index'});
	my $length = @sys_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "systems", RESET, "] [$length] ---------------------------------------------------------------------------------------------------------------------------\n\n"; };
	
	$health->{'index'}{'healthy'} = "";
	$health->{'index'}{'unknown'} = "";
	$health->{'index'}{'error'} = "";
	$health->{'index'}{'warning'} = "";
	
	#
	# process remote index
	#
	foreach my $system (@sys_index){
		my $sysdata = $metadata->{'db'}{$system};

		$health->{'meta'}{$system} = monitor_system_health($sysdata, $metadata->{'meta'}{$system});
		
		if($sysdata->{'meta'}{'state'} eq "1"){
		
			if($health->{'meta'}{$system}{'status'} eq "HEALTHY"){
				$health->{'index'}{'healthy'} = index_add($health->{'index'}{'healthy'}, $system);
			}
			else{
				$health->{'index'}{'warning'} = index_add($health->{'index'}{'warning'}, $system);
			}
		}
	}	
	
	return $health;
}

#
# monitor systems [JSON-OBJ]
#
sub monitor_system_health($system, $meta){
	my $fid = "[monitor_system_print]";
	my $healthy = 1;
	my $unloaded = 0;
	my $health = {};
	
	if(env_verbose()){ print "  [", BOLD BLUE, $system->{'id'}{'name'}, RESET, "] id [", BOLD, $system->{'id'}{'id'}, RESET, "] "; };
	
	if(defined($system->{'meta'}{'state'})){
	
		if($system->{'meta'}{'state'} eq "1"){
			# online
			if(env_verbose()){ print "- state [", BOLD GREEN, "ONLINE", RESET, "] node [", BOLD, $system->{'meta'}{'node'}, RESET, "] "; };
		}
		elsif($system->{'meta'}{'state'}){
			# offline
			if(defined($system->{'state'}{'vm_status'})){
				if($system->{'state'}{'vm_status'} eq "ended"){
					if(env_verbose()){ print "state [", BOLD RED, "VM STOPPED", RESET, "] "; };
					$healthy = 0;
				}
				else{
					if(env_verbose()){ print "state [", BOLD RED, "OFFLINE", RESET, "] "; };
				}
				
				if($system->{'state'}{'vm_status'} eq "unloaded"){ 
					$unloaded = 1; 
				};
					
				if($system->{'state'}{'vm_status'} eq "unloaded_force"){ 
					$unloaded = 1;
				};

				if($system->{'state'}{'vm_status'} eq "shutdown"){ 
					$unloaded = 1; 
				};
				
			}
			else{
				if(env_verbose()){ print "state [", BOLD RED, "OFFLINE", RESET, "] "; };
				$health->{'state'} = "OFFLINE";
			}
		}
		else{
			# check if offline system is marked shutdown
			if(defined $system->{'state'}{'vm_status'} && ($system->{'state'}{'vm_status'} eq "shutdown" ||  $system->{'state'}{'vm_status'} eq "poweroff")){ 
				$unloaded = 1; 
				if(env_verbose()){ print "state [", BOLD BLACK, "OFFLINE", RESET, "] "; };
				$health->{'state'} = "OFFLINE";
			}
			else{
				if(env_verbose()){ print "state [", BOLD BLACK, "UNKNOWN", RESET, "] "; };
				$health->{'state'} = "UNKNOWN";
				$unloaded = 1; 
			}
			
		}
		
		if(defined($system->{'state'}{'vm_status'})){
			if(env_verbose()){ print "status [", BOLD,  $system->{'state'}{'vm_status'} , RESET, "] "; };
			$health->{'state'} = $system->{'state'}{'vm_status'};
		}
		
		if(defined($meta->{'ver'})){
			if(env_verbose()){ print "ver [", BOLD BLACK, $meta->{'ver'} , RESET, "] "; };
			$health->{'ver'} = $meta->{'ver'};
		}		
		
		# check if unloaded
		if(!$unloaded){
			if(defined($system->{'meta'}{'date'})){
				my $diff = date_str_diff_now($system->{'meta'}{'date'});
				if(env_verbose()){ print "delta [", BOLD BLACK, $diff, RESET, "] "; };
				$health->{'delta'} = $diff;
				
				if(env_verbose()){ print "updated [", BOLD,  $system->{'meta'}{'date'} , RESET, "] - "; };
				$health->{'updated'} = $system->{'meta'}{'date'} ;
				
				# check delta
				if($diff < 180){
					if(env_verbose()){ print "[", BOLD GREEN, "HEALTHY", RESET, "]"; };
					$health->{'status'} = "HEALTHY";
				}
				elsif($diff < 480){
					if(env_verbose()){ print "[", BOLD MAGENTA, "WARNING", RESET, "]"; };
					$health->{'status'} = "WARNING";
				}
				else{
					if(env_verbose()){ print "[", BOLD RED, "ERROR", RESET, "]"; };
					$health->{'status'} = "ERROR";
				}
			}
			else{
				if(env_debug()){ print "$fid warning: date is missing for system!"; };
			}
		}
		else{
			if(env_verbose()){ print "- [", BOLD BLACK,  "UNLOADED" , RESET, "]"; };
			$health->{'status'} = "UNLOADED";
		}
	}
	else{
		if(defined($meta->{'ver'})){
			if(env_verbose()){ print "ver [", BOLD BLACK, $meta->{'ver'} , RESET, "] "; };
		}		
		
		if(env_verbose()){ print "- state [", BOLD BLACK,  "NOT LOADED" , RESET, "]"; };
		$health->{'status'} = "NOT LOADED";
	}
	
	if(env_verbose()){ print "\n"; };
	return $health;
}

1;
