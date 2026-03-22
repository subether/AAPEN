#
# ETHER|AAPEN|MONITOR - LIB|NETWORK
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
# monitor networks [NULL]
#
sub monitor_network($metadata, $nodes){
	my $fid = "[monitor_network]";	
	my $result;
	my @node_index = index_split($nodes);
	my $node_length = @node_index;
	my @net_index = index_split($metadata->{'index'});
	my $net_length = @net_index;
	my $err_idx = "errors;frame;overruns;dropped";
	my @err_index = index_split($err_idx);
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "networks", RESET, "] [$net_length] ---------------------------------------------------------------------------------------------------------------------------\n"; };
	
	$result->{'updated'} = date_get();
	my $root_errors = 0;
	
	#
	# process remote index
	#
	foreach my $network (@net_index){
		$result->{'index'} = index_add($result->{'index'}, $network);
		
		if(env_verbose()){ print "\n  [", BOLD BLUE, $network, RESET, "] id [", BOLD, $metadata->{'db'}{$network}{'id'}{'id'} , RESET,"] model [", $metadata->{'db'}{$network}{'object'}{'model'} , "] type [", $metadata->{'db'}{$network}{'object'}{'class'}  ,"]"; };
		
		my $errors = 0;
		my $node_errors = 0;
		
		$result->{$network}{'node'}{'index'} = "";
		$result->{$network}{'node'}{'num'} = 0;
		$result->{$network}{'vm'}{'index'} = "";
		$result->{$network}{'vm'}{'num'} = 0;
		
		foreach my $node (@node_index){
			#print "$fid NODE [$node]";
			my $errors = 0;
			
			if(defined($metadata->{'db'}{$network}{'meta'}{'stats'})){
				$result->{$network}{'node'}{'index'} = index_add($result->{$network}{'node'}{'index'}, $node);
				$result->{$network}{'node'}{'num'}++;
			
				my $stats = $metadata->{'db'}{$network}{'meta'}{'stats'}{$node};
				
				$result->{$network}{'node'}{$node}{'updated'} = $stats->{'updated'};
				
				my $diff = date_str_diff_now($stats->{'updated'});
				$result->{$network}{'node'}{$node}{'delta'} = $diff;
				
				# check delta
				if($diff < 180){
					$result->{$network}{'node'}{$node}{'status'} = "HEALTHY";
				}
				else{
					$result->{$network}{'node'}{$node}{'status'} = "WARNING";
					$node_errors++;
				}
				
				# rx errors
				foreach my $err (@err_index){
					#if(defined $stats->{'rx'}{'errors'}{$err}){
					#	$errors += $stats->{'rx'}{'errors'}{$err};
					#	$result->{$network}{'node'}{$node}{'errors'} += $stats->{'rx'}{'errors'}{$err};
					#}
				}
				
				# tx errors
				foreach my $err (@err_index){
					#if(defined $stats->{'tx'}{'errors'}{$err}){
					#	$errors += $stats->{'tx'}{'errors'}{$err};
					#	$result->{$network}{'node'}{$node}{'errors'} += $stats->{'tx'}{'errors'}{$err};
					#}
				}				
				
				# systems
				if($stats->{'vm'}{'name'}){	
					my @sys_index = index_split($stats->{'vm'}{'name'});

					foreach my $sys (@sys_index){
						$result->{$network}{'vm'}{'index'} = index_add($result->{$network}{'vm'}{'index'}, $sys);
						$result->{$network}{'vm'}{'num'}++;
					}
				}
			}
		}
		
		if(env_verbose()){ print " nodes [", BOLD, $result->{$network}{'node'}{'num'}, RESET, "] vm [", BOLD, $result->{$network}{'vm'}{'num'}, RESET,"] errors [", $errors, "] - "; };

		$result->{$network}{'errors'} = $errors;
				
		# check for nodes
		if($result->{$network}{'node'}{'num'} > 0){
			# nodes present
			
			# check for VMs
			if($result->{$network}{'vm'}{'num'} > 0){
				if(env_verbose()){ print "state [", BOLD GREEN, "ACTIVE", RESET, "] "; };
				$result->{$network}{'state'} = "ACTIVE";
			}
			else{
				if(env_verbose()){ print "state [", GREEN, "ONLINE", RESET, "] "; };
				$result->{$network}{'state'} = "ONLINE";
			}
		}
		else{
			# no nodes present, check for VMs
			if($result->{$network}{'vm'}{'num'} > 0){
				if(env_verbose()){ print "state [", BOLD RED, "WARNING", RESET, "] "; };
				$result->{$network}{'state'} = "WARNING";
			}
			else{
				if(env_verbose()){ print "state [INACTIVE] "; };
				$result->{$network}{'state'} = "INACTIVE";
			}
		}
	
		if(($errors > 0) && $node_errors > 0){
			if(env_verbose()){ print "- [", BOLD RED, "WARNING", RESET, "] "; };
			$result->{$network}{'status'} = "WARNING";
			$root_errors++;
		}
		else{
			if(env_verbose()){ print "- [", BOLD GREEN, "HEALTHY", RESET, "] "; };
			$result->{$network}{'status'} = "HEALTHY";
		}
	}	

	if($root_errors > 0){
		$result->{'status'} = "WARNING";
	}
	else{
		$result->{'status'} = "HEALTHY";
	}

	return $result;
}

#
# monitor network service [NULL]
#
sub monitor_net_serv($metadata){
	my $fid = "[monitor_net]";
	my @node_index = index_split($metadata->{'index'});
	my $length = @node_index;
	my $result;

	if(env_verbose()){ print "\n\n[", BOLD BLUE, "service|network", RESET, "] [$length] ----------------------------------------------------------------------------------------------------------------------------\n\n"; };

	#
	# process remote index
	#
	foreach my $node (@node_index){
		my $nodedata = $metadata->{'db'}{$node};		
		my $diff = date_str_diff_now($metadata->{'meta'}{$node}{'date'});

		if(env_verbose()){ 
			print "  [", BOLD BLUE, $node, RESET, "] id [", BOLD, $nodedata->{'config'}{'id'} , RESET,"]";
			print " ver [", BOLD BLACK, $metadata->{'meta'}{$node}{'ver'} , RESET, "] ";
			print "delta [", BOLD BLACK, $diff, RESET, "] ";
			print "updated [", BOLD,  $metadata->{'meta'}{$node}{'date'} , RESET, "] ";
		};
		
		# bridges
		my @bri_index = index_split($nodedata->{'bri'}{'index'});
		my $bri_length = @bri_index;
		
		# vpp
		my @vpp_index = index_split($nodedata->{'vpp'}{'index'});
		my $vpp_length = @vpp_index;
		
		# networks
		my @net_index = index_split($nodedata->{'net'}{'index'}{'name'});
		my $net_length = @net_index;
		
		if(env_verbose()){ print "networks [", BOLD,  $net_length , RESET, "] - bridge [$bri_length] vpp [$vpp_length]"; };
		my $vm_num = 0;
		
		# process network vm
		foreach my $net (@net_index){

			if(defined ($nodedata->{'net'}{$net}{'vm'}{'index'}) && $nodedata->{'net'}{$net}{'vm'}{'index'} ne ""){
				my @vm_index = index_split($nodedata->{'net'}{$net}{'vm'}{'index'});
				$vm_num += @vm_index;
			}
		}
		
		if(env_verbose()){ print " - online vm [", BOLD, $vm_num, RESET, "] - "; };
		
		# check delta
		if($diff < 180){
			if(env_verbose()){ print "[", BOLD GREEN, "HEALTHY", RESET, "]\n"; };
			$result->{$node}{'status'} = "HEALTHY";
			$result->{$node}{'state'} = "ACTIVE";
			$result->{$node}{'delta'} = $diff;
			$result->{$node}{'updated'} = date_get();
		}
		else{
			if(env_verbose()){ print "[", BOLD RED, "ERROR", RESET, "]\n"; };
			$result->{$node}{'status'} = "ERROR";
			$result->{$node}{'state'} = "ACTIVE";
			$result->{$node}{'delta'} = $diff;
			$result->{$node}{'updated'} = date_get();
		}
	}
	
	return $result;
}

1;
