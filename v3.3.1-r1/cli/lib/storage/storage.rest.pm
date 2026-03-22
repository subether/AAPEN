#
# ETHER|AAPEN|CLI - LIB|STORAGE|REST
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
# storage config load
#
sub storage_rest_config_load($storage_name){
	my $fid = "storage_rest_config_load";
	my $ffid = "STORAGE|CONFIG|LOAD";
	my $result = rest_post_request("/storage/config/load", {name => $storage_name});
	api_rest_response_print($ffid, $result, "storage rest config load");
}

#
# storage config save
#
sub storage_rest_config_save($storage_name){
	my $fid = "storage_rest_config_save";
	my $ffid = "STORAGE|CONFIG|SAVE";
	my $result = rest_post_request("/storage/config/save", {name => $storage_name});
	api_rest_response_print($ffid, $result, "storage rest config save");
}

#
# reset system via REST [NULL]
#
sub storage_rest_info($storage_name){
	my $fid = "storage_info";
	my $ffid = "STORAGE|INFO";
	
	# validate system name
	if(defined $storage_name && string_validate($storage_name)){
		my $result = rest_get_request("/storage/get?name=" . $storage_name);
		api_rest_response_print($ffid, $result, "storage info");
		return $result;
	}	
	else{
		api_print_error($ffid, "node name invalid!");
	}
}

#
#
#
sub storage_rest_get($storage_name){
	return rest_get_request("/storage/get?name=" . $storage_name);
}

#
#
#
sub storage_rest_list($option, $string){
	my $ffid = "STORAGE|LIST";

	# fetch node db
	my $storage_db = rest_get_request("/storage/db");
	
	if($storage_db->{'proto'}{'result'}){
		
		# process index	
		my @storage_index = index_split($storage_db->{'response'}{'db'}{'storage'}{'index'});
		@storage_index = sort @storage_index;
		
		my $length = @storage_index;
		print "\n[", BOLD BLUE, "storage", RESET, "] [$length]\n\n";
		my $count = 0;
		
		# iterate index
		foreach my $storage_name (@storage_index){
			
			my $storage = $storage_db->{'response'}{'db'}{'storage'}{'db'}{$storage_name};
			#json_encode_pretty($storage);

			# list all
			if($option eq "all"){
				storage_rest_print($storage);
				$count++;
			}

			# search cluster
			if($option eq "iso" && $storage->{'object'}{'model'} eq "iso"){
				storage_rest_print($storage);
				$count++;
			}

			# search cluster
			if($option eq "device" && $storage->{'object'}{'model'} eq "device"){
				storage_rest_print($storage);
				$count++;
			}
			
			# search cluster
			if($option eq "pool" && $storage->{'object'}{'model'} eq "pool"){
				storage_rest_print($storage);
				$count++;
			}

			# search cluster
			if($option eq "find"){
				if($storage->{'id'}{'name'} =~ $string){
					storage_rest_print($storage);
					$count++;
				}
			}
			
		}
		
		print "\nListed [$count] storage with filter [$option]\n";
		
	}
	else{
		api_print_error($ffid, "failed to fetch storage db!");
	}
	
}

#
# storage rest print
#
sub storage_rest_print($storage){
	
	if($storage->{'object'}{'model'} eq "device"){
		storage_rest_device_print($storage);
	}
	
	if($storage->{'object'}{'model'} eq "pool"){
		storage_rest_pool_print($storage);
	}

	if($storage->{'object'}{'model'} eq "iso"){
		storage_rest_pool_print($storage);
	}	
}

#
# storage rest device print
#
sub storage_rest_device_print($stor){
	
	if($stor->{'object'}{'class'} eq "disk"){
		print " id [", BOLD BLUE, $stor->{'id'}{'id'}, RESET, "] name [", BOLD, $stor->{'id'}{'name'}, RESET, "] type [", BOLD, "device", RESET, "] node [", BOLD, $stor->{'node'}{'name'}, RESET, "] id [", BOLD, $stor->{'node'}{'id'}, RESET, "] backing [", BOLD, $stor->{'device'}{'type'}, RESET, "] size [", BOLD, $stor->{'device'}{'size'}, RESET, "]";
	}

	if($stor->{'object'}{'class'} eq "nvme"){
		print " id [", BOLD BLUE, $stor->{'id'}{'id'}, RESET, "] name [", BOLD, $stor->{'id'}{'name'}, RESET, "] type [", BOLD, "nvme", RESET, "] node [", BOLD, $stor->{'node'}{'name'}, RESET, "] id [", BOLD, $stor->{'node'}{'id'}, RESET, "] backing [", BOLD, $stor->{'device'}{'type'}, RESET, "] size [", BOLD, $stor->{'device'}{'size'}, RESET, "]";
	}
	
	if($stor->{'object'}{'class'} eq "mdraid"){
		print " id [", BOLD BLUE, $stor->{'id'}{'id'}, RESET, "] name [", BOLD, $stor->{'id'}{'name'}, RESET, "] type [", BOLD, "mdraid", RESET, "] level [", BOLD,  $stor->{'mdraid'}{'raid'}, RESET, "] node [", BOLD, $stor->{'node'}{'name'}, RESET, "] id [", BOLD, $stor->{'node'}{'id'}, RESET, "] backing [", BOLD, $stor->{'mdraid'}{'type'}, RESET, "] size [", BOLD, $stor->{'mdraid'}{'size'}, RESET, "]";	
	}

	cluster_obj_state($stor);
	print "\n";
}

#
# storage rest pool print
#
sub storage_rest_pool_print($stor){
	print " id [", BOLD BLUE, $stor->{'id'}{'id'}, RESET, "] name [", BOLD, $stor->{'id'}{'name'}, RESET, "]";
	cluster_obj_state($stor);
	print "\n";
}

1;
