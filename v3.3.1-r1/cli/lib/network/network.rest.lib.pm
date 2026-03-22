#
# ETHER|AAPEN|CLI - LIB|NET|REST
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
# load network config [NULL]
#
sub network_rest_config_load($net_name){
	my $fid = "network_rest_config_load";
	my $ffid = "NETWORK|CONFIG|LOAD";
	my $result = rest_post_request("/network/config/load", {name => $net_name});
	api_rest_response_print($ffid, $result, "network rest config load");
}

#
# save network config [NULL]
#
sub network_rest_config_save($net_name){
	my $fid = "network_rest_config_save";
	my $ffid = "NETWORK|CONFIG|SAVE";
	my $result = rest_post_request("/network/config/save", {name => $net_name});
	api_rest_response_print($ffid, $result, "network rest config save");
}

#
# reset system via REST [NULL]
#
sub network_rest_info($network_name){
	my $fid = "network_info";
	my $ffid = "NETWORK|INFO";
	
	# validate system name
	if(defined $network_name && string_validate($network_name)){
		my $result = rest_get_request("/network/get?name=" . $network_name);
		api_rest_response_print($fid, $result, "network info");
	}	
	else{
		print "$fid error: network name invalid!\n"
	}
}

#
# get network [JSON-OBJ]
#
sub network_rest_get($network_name){
	return rest_get_request("/network/get?name=" . $network_name);
}

#
# get network metadata [JSON-OBJ]
#
sub network_rest_meta(){
	return rest_get_request("/network/meta");
}

#
# process metadata index [INDEX]
#
sub network_rest_meta_index(){
	my $network_meta = network_rest_meta();
	
	if($network_meta->{'proto'}{'result'}){
		return $network_meta->{'response'}{'meta'}{'network'}{'index'};
	}
	else{
		return "";
	}
}

#
# list networks [NULL]
#
sub network_rest_list($option, $string){

	# fetch network db
	my $network_db = rest_get_request("/network/db");

	if($network_db->{'proto'}{'result'}){
		
		# process index 
		print "index [$network_db->{'response'}{'db'}{'network'}{'index'}]\n";
		my @net_index = index_split($network_db->{'response'}{'db'}{'network'}{'index'});
		@net_index = sort @net_index;
		
		my $length = @net_index;
		print "\n[", BOLD BLUE, "network", RESET, "] [$length]\n\n";
		my $count = 0;
		
		# iterate index
		foreach my $network_name (@net_index){
			my $net = $network_db->{'response'}{'db'}{'network'}{'db'}{$network_name};
			my $netid = $net->{'id'}{'id'};
			
			# list all
			if($option eq "all"){
				net_print($net, $netid);
				$count++;
			}
			
			# find network
			if($option eq "find"){
				if($net->{'id'}{'name'} =~ $string){
					net_print($net, $netid);
					$count++;
				}
			}
			
			# show vpp networks
			if($option eq "vpp"){
				if($net->{'meta'}{'type'} =~ "vpp"){
					net_print($net, $netid);
					$count++;
				}
			}		

			# show bridges
			if($option eq "bridge"){
				if($net->{'meta'}{'type'} =~ "vlan"){
					net_print($net, $netid);
					$count++;
				}
			}	

			# show trunks
			if($option eq "trunk"){
				if($net->{'meta'}{'type'} =~ "trunk"){
					net_print($net, $netid);
					$count++;
				}
			}	

			# show vlans
			if($option eq "vlan"){
				if(defined $net->{'vlan'}{'tag'} && ($net->{'vlan'}{'tag'} =~ $string)){
					net_print($net, $netid);
					$count++;
				}
			}

			# search for address
			if($option eq "addr"){
				if(defined $net->{'addr'}{'ip'} && $net->{'addr'}{'ip'} =~ $string){
					net_print($net, $netid);
					$count++;
				}
			}
			
		}
		
		print "\nListed [$count] nodes with filter [$option]\n";
		
	}
	else{
		print "failed to fetch node db!\n";
	}
	
}

#
# sync api network configs with cluster [NULL]
#
sub network_rest_cluster_sync(){
	my $fid = "[network_cluster_sync]";
	my $meta = network_rest_meta();
	my $net_index = $meta->{'response'}{'meta'}{'network'}{'index'};
	if(env_debug()){ print "$fid net index [$net_index]\n"; };

	# build index
	my @nets = index_split($net_index);

 	# process nets
	print "\n";
	foreach my $netid (@nets){
		my $net = network_rest_get($netid);
		$net = $net->{'response'}{'network'};
		print " id [", BOLD BLUE, $netid, RESET, "] name [", BOLD, $net->{'id'}{'name'}, RESET, "] - type [", BOLD BLACK, $net->{'meta'}{'type'}, RESET, "]";
		
		if(defined $net->{'object'}{'meta'}{'ver'}){
			print " version [", BOLD BLACK,  $net->{'object'}{'meta'}{'ver'}, RESET, "] - CLUSTER";
		}
		else{
			print " - pushing to cluster..";
			cluster_local_net_set($net->{'id'}{'name'});
		}
		
		print "\n"
	}
}

#
# sync api network configs with cluster (forcefully) [NULL]
#
sub network_rest_cluster_sync_force(){
	my $fid = "network_cluster_sync";
	my $meta = network_rest_meta();
	my $net_index = $meta->{'response'}{'meta'}{'network'}{'index'};
	if(env_debug()){ print "$fid net index [$net_index]\n"; };

	# build index
	my @nets = index_split($net_index);

 	# process nets
	print "\n";
	foreach my $netid (@nets){
		
		#my $net = net_conf_get($netid);
		my $net = network_rest_get($netid);
		$net = $net->{'response'}{'network'};
		print " id [", BOLD BLUE, $netid, RESET, "] name [", BOLD, $net->{'id'}{'name'}, RESET, "] - type [", BOLD BLACK, $net->{'meta'}{'type'}, RESET, "]";
		
		if(defined $net->{'object'}{'meta'}{'ver'}){
			print " version [", BOLD BLACK,  $net->{'object'}{'meta'}{'ver'}, RESET, "] - CLUSTER";
			cluster_local_net_set($net->{'id'}{'name'});
		}
		else{
			print " - pushing to cluster..";
			cluster_local_net_set($net->{'id'}{'name'});
			
		}
		
		print "\n"
	}
}

#
# remove all networks from cluster [NULL]
#
sub network_rest_cluster_remove_all(){
	my $fid = "net_cluster_remove_all";
	my $meta = network_rest_meta();
	my $net_index = $meta->{'response'}{'meta'}{'network'}{'index'};
	if(env_debug()){ print "$fid net index [$net_index]\n"; };

	# build index
	my @nets = index_split($net_index);

 	# process nets
	print "\n";
	foreach my $netid (@nets){
		
		#my $net = net_conf_get($netid);
		my $net = network_rest_get($netid);
		$net = $net->{'response'}{'network'};
		print " id [", BOLD BLUE, $netid, RESET, "] name [", BOLD, $net->{'id'}{'name'}, RESET, "] - type [", BOLD BLACK, $net->{'meta'}{'type'}, RESET, "]";
		
		if(defined $net->{'object'}{'meta'}{'ver'}){
			print " version [", BOLD BLACK,  $net->{'object'}{'meta'}{'ver'}, RESET, "] - CLUSTER";
			cluster_local_net_del($net->{'id'}{'name'});
		}
		
		print "\n"
	}
	
}

#
# print network [NULL]
#
sub net_print($net, $netid){
	my $ip = "";
	if(defined $net->{'addr'}{'ip'}){ $ip = $net->{'addr'}{'ip'} };
	
	print " id [", BOLD BLUE, $netid, RESET, "] name [", BOLD, $net->{'id'}{'name'}, RESET, "] - type [", BOLD BLUE, $net->{'meta'}{'type'}, RESET, "] addr [", BOLD, $ip,  RESET, "]";
	cluster_obj_state($net);
	print "\n";
}


1;
