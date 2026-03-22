#
# ETHER|AAPEN|MONITOR - LIB|HYPERVISOR
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
# monitor hypervisor [JSON-OBJ]
#
sub monitor_hyper_serv($metadata){
	my $fid = "[monitor_node]";
	my @hyper_index = index_split($metadata->{'db'}{'service'}{'hypervisor'}{'index'});
	my $length = @hyper_index;
	my $result;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "service|hypervisor", RESET, "] [$length] --------------------------------------------------------------------------------------------------------------------------\n"; };

	#
	# process remote index
	#
	foreach my $hyper (@hyper_index){

		my $nodedata = $metadata->{'db'}{'service'}{'hypervisor'}{'db'}{$hyper};
		my $diff = date_str_diff_now($metadata->{'db'}{'service'}{'hypervisor'}{'meta'}{$hyper}{'date'});
		
		if(env_verbose()){ 
			print "\n [", BOLD BLUE, $hyper, RESET, "] id [", BOLD, $nodedata->{'config'}{'id'} , RESET,"]";
			print " uptime [", BOLD, $nodedata->{'hw'}{'stats'}{'uptime'} , RESET, "]";
			print " ver [", BOLD BLACK, $metadata->{'db'}{'service'}{'hypervisor'}{'meta'}{$hyper}{'ver'} , RESET, "] ";
			print "delta [", BOLD BLACK, $diff, RESET, "] ";
			print "updated [", BOLD,  $metadata->{'db'}{'service'}{'hypervisor'}{'meta'}{$hyper}{'date'} , RESET, "] - ";
		};
		
		# check delta
		if($diff < 180){
			if(env_verbose()){ print "[", BOLD GREEN, "HEALTHY", RESET, "]\n"; };
			$result->{$hyper}{'status'} = "HEALTHY";
			$result->{$hyper}{'state'} = "ACTIVE";
			$result->{$hyper}{'delta'} = $diff;
			$result->{$hyper}{'updated'} = date_get();
		}
		else{
			if(env_verbose()){ print "[", BOLD RED, "ERROR", RESET, "]\n"; };
			$result->{$hyper}{'status'} = "ERROR";
			$result->{$hyper}{'state'} = "UNKNOWN";
			$result->{$hyper}{'delta'} = $diff;
			$result->{$hyper}{'updated'} = date_get();
		}
		
		if(env_verbose()){ 
			print "   [", BOLD, "cpu", RESET, "] type [", BOLD,  $nodedata->{'hw'}{'cpu'}{'type'} , RESET, "]"; 

			print " socket [", BOLD, $nodedata->{'hw'}{'cpu'}{'sock'} , RESET, "]";
			print " cores [", BOLD, $nodedata->{'hw'}{'cpu'}{'core'} , RESET, "] -";
			print " load [", BOLD,  sprintf("%.2f", $nodedata->{'hw'}{'stats'}{'load'}{'1'}) , RESET, "]";
			print " [", BOLD, sprintf("%.2f",$nodedata->{'hw'}{'stats'}{'load'}{'5'}) , RESET, "]";
			print " [", BOLD, sprintf("%.2f",$nodedata->{'hw'}{'stats'}{'load'}{'15'}) , RESET, "]";
			print " idle [", BOLD, $nodedata->{'hw'}{'stats'}{'cpu'}{'idle'} , RESET, "]";
			print " wait [", BOLD, $nodedata->{'hw'}{'stats'}{'cpu'}{'wait'} , RESET, "]\n";
		
			print "   [", BOLD, "memory", RESET, "] total [", BOLD, $nodedata->{'hw'}{'mem'}{'mb'} , RESET, " MB]"; 
			print " used [", BOLD, $nodedata->{'hw'}{'stats'}{'mem'}{'used'} , RESET, " MB]";
			print " free [", BOLD, $nodedata->{'hw'}{'stats'}{'mem'}{'free'} , RESET, " MB]";
			print " cache [", BOLD, $nodedata->{'hw'}{'stats'}{'mem'}{'cache'} , RESET, " MB] -";
			
			if(defined $nodedata->{'hw'}{'stats'}{'swap'}{'total'}){ 
				print " swap [", BOLD, $nodedata->{'hw'}{'stats'}{'swap'}{'total'} , RESET, " MB]"; 
			}
			else{
				print " swap [", BOLD, "0" , RESET, " MB]"; 
			}
			
			if(defined $nodedata->{'hw'}{'stats'}{'swap'}{'used'}){
				print " used [", BOLD, $nodedata->{'hw'}{'stats'}{'swap'}{'used'} , RESET, " MB]\n";
			}
			else{
				print " used [", BOLD, "0" , RESET, " MB]\n";
			}
			
		};

		if(defined ($nodedata->{'hw'}{'sensors'}{'coretemp'})){
			if(env_verbose()){ print "   [", BOLD, "sensors", RESET, "] "; };
			
			my @socket_index = index_split($nodedata->{'hw'}{'sensors'}{'coretemp'}{'index'});
			
			if(env_verbose()){ print "sockets [$nodedata->{'hw'}{'sensors'}{'coretemp'}{'index'}] "; };
			
			foreach my $socket (@socket_index){
				if(env_verbose()){ print "- socket [$socket] temp max [$nodedata->{'hw'}{'sensors'}{'coretemp'}{$socket}{'max'}] min [$nodedata->{'hw'}{'sensors'}{'coretemp'}{$socket}{'min'}]"; };
				
				if($nodedata->{'hw'}{'sensors'}{'coretemp'}{$socket}{'max'} > 60){
					if(env_verbose()){ print " [", BOLD MAGENTA, "WARNING", RESET, "] "; };
				}
				elsif($nodedata->{'hw'}{'sensors'}{'coretemp'}{$socket}{'max'} > 75){
					if(env_verbose()){ print " [", BOLD RED, "ALERT", RESET, "] "; };
					$result->{$hyper}{'temperature'} = "ALERT";
				}
				else{
					if(env_verbose()){ print " [", BOLD GREEN, "NORMAL", RESET, "] "; };
					$result->{$hyper}{'temperature'} = "NORMAL";
				}
			}
			
			if(env_verbose()){ print "\n"; };
		}

		if(defined ($nodedata->{'hyper'}{'systems'}) && $nodedata->{'hyper'}{'systems'} ne ""){
			
			if(env_verbose()){ 
				print "   [", BOLD, "hyper", RESET, "] systems [", BOLD, $nodedata->{'hyper'}{'systems'} , RESET, "]";
				print " memory alloc [", BOLD, $nodedata->{'hyper'}{'memalloc'} , RESET, " MB]";
				print " cpu alloc [", BOLD, $nodedata->{'hyper'}{'cpualloc'} , RESET, "]";
				print " locked [", BOLD, $nodedata->{'hyper'}{'lock'} , RESET, "]\n";
			};
			
			my @sys_index = index_split($nodedata->{'hyper'}{'lock'});
			
			foreach my $sys (@sys_index){
				if(env_verbose()){ 
					print "     '- vm [", BOLD, $sys, RESET, "] name [", BOLD BLUE, $nodedata->{'stats'}{$sys}{'id'}{'name'} , RESET, "]";
					print " pid [", BOLD BLACK, $nodedata->{'stats'}{$sys}{'pid'} , RESET, "]";
					print " boot [", BOLD BLACK, $nodedata->{'stats'}{$sys}{'boot'} , RESET, "]";
					print " cpu [", BOLD, $nodedata->{'stats'}{$sys}{'cpu'} , RESET, "%]";
					print " mem [", BOLD, $nodedata->{'stats'}{$sys}{'mem'} , RESET, "%]\n";
				};
			}
		}
		else{
			if(env_verbose()){ print "   [", BOLD, "hyper", RESET, "] status [", BOLD , "inactive, ready, no systems", RESET, "]\n"; };
		}
	}
	
	return $result;
}

1;
