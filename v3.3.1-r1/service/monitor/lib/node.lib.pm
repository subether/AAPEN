#
# ETHER|AAPEN|MONITOR - LIB|NODE
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
# monitor nodes [JSON-OBJ]
#
sub monitor_node($data){
	my $fid = "[monitor_node]";
	
	my $health = {};
	$health->{'index'}{'healthy'} = "";
	$health->{'index'}{'unknown'} = "";
	$health->{'index'}{'error'} = "";
	$health->{'index'}{'warning'} = "";
	
	my $metadata = $data->{'db'}{'node'};
	
	#
	# hypervisor
	#
	my @node_index = index_split($metadata->{'index'});
	my $length = @node_index;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "node", RESET, "] [$length] -------------------------------------------------------------------------------------------------------------------------------\n\n"; };

	#
	# process remote index
	#
	foreach my $node (@node_index){
		my $nodedata = $metadata->{'db'}{$node};

		if(env_verbose()){ print "  [", BOLD BLUE, $node, RESET, "] id [", BOLD, $nodedata->{'id'}{'id'} , RESET,"] "; };
		if(env_verbose()){ print "ver [" . $metadata->{'meta'}{$node}{'ver'} . "] "; };

		$health->{'meta'}{$node}{'ver'} = $metadata->{'meta'}{$node}{'ver'};
		my $diff = date_str_diff_now($metadata->{'meta'}{$node}{'date'});
		
		if($nodedata->{'meta'}{'state'} ne 0){
			if(env_verbose()){ print "delta [", BOLD BLACK, $diff, RESET, "] "; };
			$health->{'meta'}{$node}{'delta'} = $diff;
		}
		
		if(env_verbose()){ print "updated [", BOLD,  $metadata->{'meta'}{$node}{'date'} , RESET, "] - "; };
		$health->{'meta'}{$node}{'updated'} = $metadata->{'meta'}{$node}{'date'};
		
		# check delta
		if(($diff < 180) && ($nodedata->{'meta'}{'state'} eq 1)){
			if(env_verbose()){ print "[", BOLD GREEN, "HEALTHY", RESET, "]"; };
			$health->{'meta'}{$node}{'status'} = "HEALTHY";
			$health->{'meta'}{$node}{'state'} = "ONLINE";
			$health->{'index'}{'healthy'} = index_add($health->{'index'}{'healthy'}, $node);
		}
		else{
			if($nodedata->{'meta'}{'state'} eq 0){
				# offline
				if(env_verbose()){ print "[", BOLD, "OFFLINE", RESET, "]"; };
			}
			elsif($diff > 360 && (($nodedata->{'meta'}{'state'} ne 2) && ($nodedata->{'meta'}{'state'} ne 0))){
				# mark as unavailable
				if(env_verbose()){ print "[", BOLD RED, "UNAVAIL", RESET, "]"; };
				$health->{'meta'}{$node}{'status'} = "ERROR";
				$health->{'meta'}{$node}{'state'} = "UNAVAIL";
				$health->{'index'}{'warning'} = index_add($health->{'index'}{'warning'}, $node);
				node_mark_unavail($nodedata, $metadata);
			}
			else{
				# mark as warning
				if(env_verbose()){ print "[", BOLD MAGENTA, "WARNING", RESET, "]"; };
				$health->{'meta'}{$node}{'status'} = "WARNING";
				$health->{'meta'}{$node}{'state'} = "ONLINE";
				$health->{'index'}{'warning'} = index_add($health->{'index'}{'warning'}, $node);
			}
		}		

		if($nodedata->{'meta'}{'state'} eq 2){
			if(env_verbose()){ print " [", BOLD RED, "UNAVAILABLE", RESET, "]"; };
			$health->{'meta'}{$node}{'status'} = "ERROR";
			$health->{'meta'}{$node}{'state'} = "UNAVAIL";

			# mark node resources unavailable
			node_resource_unavail($node, $data);
		}

		if(env_verbose()){ print "\n"; };
	}	
	
	return $health;
}

#
# mark node as unavail [NULL]
#
sub node_mark_unavail($nodedata, $metadata){
	my $fid = "[node_mark_unavail]";

	#if($nodedata->{'meta'}{'state'} ne 0){

		$nodedata->{'meta'}{'state'} = 2;
		$nodedata->{'meta'}{'status'} = "UNAVAIL";
		
		my $result = api_cluster_local_node_set(env_serv_sock_get("cluster"), $nodedata);
		
		# find other resource
		node_resource_unavail($nodedata->{'id'}{'name'}, $metadata);
	#}
}

#
# identify node resources and mark unavail [NULL]
#
sub node_resource_unavail($node, $metadata){
	my $fid = "[node_resource_unavail]";
	
	print "\n";
	
	#
	# storage
	#
	my @storage_index = index_split($metadata->{'db'}{'storage'}{'index'});
	
	#
	# process remote index
	#
	foreach my $storage (@storage_index){
		my $stordata = $metadata->{'db'}{'storage'}{'db'}{$storage};
		
		if($metadata->{'db'}{'storage'}{'db'}{$storage}{'object'}{'model'} eq "device"){
			if($node eq $stordata->{'node'}{'name'}){
				print "$fid storage [$storage] type [$metadata->{'db'}{'storage'}{'db'}{$storage}{'object'}{'model'}] owner [$stordata->{'node'}{'name'}]: DOWN!\n";
				
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'state'} = "2";
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'status'} = "UNAVAIL";
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'warning'} = "NODE DOWN";
				
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'health'}{'warning'} = "NODE DOWN";
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'health'}{'status'} = "UNAVAIL";
				
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'health'}{'smart'} = "UNAVAIL";
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'health'}{'device'} = "UNAVAIL";
				$metadata->{'db'}{'storage'}{'db'}{$storage}{'meta'}{'health'}{'temperature'} = "UNAVAIL";

				api_cluster_local_stor_set(env_serv_sock_get("cluster"), $metadata->{'db'}{'storage'}{'db'}{$storage});
			}
		}

		if($metadata->{'db'}{'storage'}{'db'}{$storage}{'object'}{'model'} eq "pool"){	
			if($node eq $stordata->{'owner'}{'name'}){
				print "$fid storage [$storage] type [$metadata->{'db'}{'storage'}{'db'}{$storage}{'object'}{'model'}] owner [$stordata->{'owner'}{'name'}]: DOWN!\n";
			}
		}
	}	
}

1;
