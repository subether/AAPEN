#
# ETHER|AAPEN|CLI - LIB|NODE|REST
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
# load node config [NULL]
#
sub node_rest_config_load($node_name){
	my $fid = "node_rest_config_load";
	my $ffid = "NODE|CONFIG|LOAD";
	my $result = rest_post_request("/node/config/load", {name => $node_name});
	api_rest_response_print($ffid, $result, "node rest config load");
}

#
# save node config [NULL]
#
sub node_rest_config_save($net_name){
	my $fid = "node_rest_config_save";
	my $ffid = "NODE|CONFIG|SAVE";
	my $result = rest_post_request("/node/config/save", {name => $net_name});
	api_rest_response_print($ffid, $result, "node rest config save");
}

#
# get node info [NULL]
#
sub node_rest_info($node_name){
	my $fid = "node_info";
	my $ffid = "NODE|INFO";
	
	# validate system name
	if(defined $node_name && string_validate($node_name)){

		my $result = rest_get_request("/node/get?name=" . $node_name);
		api_rest_response_print($ffid, $result, "node [$node_name] info");
		return $result;
	}	
	else{
		api_print_error($ffid, "node name invalid!");
	}
}

#
# get node info [JSON-OBJ]
#
sub node_rest_get($node_name){
	return rest_get_request("/node/get?name=" . $node_name);
}

#
# get node metadata [JSON-OBJ]
#
sub node_rest_meta(){
	return rest_get_request("/node/meta");
}

#
# ping node agent service [JSON-OBJ]
#
sub node_rest_ping($node_name){
	my $fid = "node_rest_ping";
	my $ffid = "NODE|PING";
	my $result = rest_get_request("/node/ping?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node [$node_name] ping");
}

#
# storage config save [NULL]
#
sub node_rest_service_env($service, $env, $node_name){
	my $fid = "api_rest_node_service_env";
	my $result = rest_post_request("/service/$service/env", {name => $node_name, env => $env});
	api_rest_response_print($fid, $result, "node [$node_name] service [$service] env [$env]");
}


#
# list nodes [NULL]
#
sub node_rest_list($option, $string){
	my $fid = "node_rest_list";
	my $ffid = "NODE|LIST";

	# fetch node db
	my $node_db = rest_get_request("/node/db");
	
	if($node_db->{'proto'}{'result'}){
		
		# process index	
		my @node_index = index_split($node_db->{'response'}{'db'}{'node'}{'index'});
		@node_index = sort @node_index;
		
		my $length = @node_index;
		print "\n[", BOLD BLUE, "node", RESET, "] [$length]\n\n";
		my $count = 0;
		
		# iterate index
		foreach my $node_name (@node_index){
			my $node = $node_db->{'response'}{'db'}{'node'}{'db'}{$node_name};
			
			# list all
			if($option eq "all"){
				node_list_print($node);
				$count++;
			}

			# search cluster
			if($option eq "cluster"){
				if($node->{'id'}{'cluster'} =~ $string){
					node_list_print($node);
					$count++;
				}
			}
			
			# search groups
			if($option eq "group"){
				if($node->{'id'}{'group'} =~ $string){
					node_list_print($node);
					$count++;
				}
			}

			# search name
			if($option eq "name"){
				if($node->{'id'}{'name'} =~ $string){
					node_list_print($node);
					$count++;
				}
			}		
			
			# offline nodes
			if($option eq "online"){
				if($node->{'meta'}{'state'} eq "1"){
					node_list_print($node);
					$count++;
				}
			}	
			
			# offline nodes
			if($option eq "offline"){
				if($node->{'meta'}{'state'} eq "0"){
					node_list_print($node);
					$count++;
				}
			}	
			
		}
		
		print "\nListed [$count] nodes with filter [$option]\n";
		
	}
	else{
		api_print_error($ffid, "failed to fetch node db!");
	}
	
}

1;
