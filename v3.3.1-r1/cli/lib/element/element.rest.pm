#
# ETHER|AAPEN|CLI - LIB|ELEMENT
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
# element config load [NULL]
#
sub element_rest_config_load($element_name){
	my $fid = "element_rest_config_load";
	my $ffid = "ELEMENT|CONFIG|LOAD";
	my $result = rest_post_request("/element/config/load", {name => $element_name});
	api_rest_response_print($ffid, $result, "element rest config load");
}

#
# get element [JSON-OBJ]
#
sub element_rest_get($element_name){
	return rest_get_request("/element/get?name=" . $element_name);
}

#
# get element metadata [JSON-OBJ]
#
sub element_rest_meta(){
	return rest_get_request("/element/meta");
}

#
# reset system via REST [NULL]
#
sub element_rest_info($element_name){
	my $fid = "element_info";
	
	# validate system name
	if(defined $element_name && string_validate($element_name)){

		my $result = rest_get_request("/element/get?name=" . $element_name);
		api_rest_response_print($fid, $result, "element info");
	}	
	else{
		print "$fid error: element name invalid!\n"
	}
}

#
# list elements [NULL]
#
sub element_rest_list($flag, $string){

	# fetch node db
	my $element_db = rest_get_request("/element/db");
	
	if($element_db->{'proto'}{'result'}){
		print "sucessfully fetched node db!\n";
		
		# process index
		print "index [$element_db->{'response'}{'db'}{'element'}{'index'}]\n";		
		my @element_index = index_split($element_db->{'response'}{'db'}{'element'}{'index'});
		@element_index = sort @element_index;
		
		my $length = @element_index;
		print "\n[", BOLD BLUE, "elements", RESET, "] [$length]\n\n";
		my $count = 0;
		
		# iterate index
		foreach my $element_name (@element_index){
			my $element = $element_db->{'response'}{'db'}{'element'}{'db'}{$element_name};
			
			# list all
			if($flag eq "all"){
				element_list_print($element);
				$count++;
			}

			# search cluster
			if($flag eq "cluster"){
				if($element->{'id'}{'cluster'} =~ $string){
					element_list_print($element);
					$count++;
				}
			}
			
			# search groups
			if($flag eq "group"){
				if($element->{'id'}{'group'} =~ $string){
					element_list_print($element);
					$count++;
				}
			}

			# search name
			if($flag eq "name"){
				if($element->{'id'}{'name'} =~ $string){
					element_list_print($element);
					$count++;
				}
			}		
			
			# offline nodes
			if($flag eq "device"){
				if($element->{'object'}{'model'} eq "device"){
					element_list_print($element);
					$count++;
				}
			}	
			
			# offline nodes
			if($flag eq "service"){
				if($element->{'object'}{'model'} eq "service"){
					element_list_print($element);
					$count++;
				}
			}	

		}
		
		print "\nListed [$count] elements with filter [$flag]\n";
	}
		
}

#
# print element [NNULL]
#
sub element_list_print($element_data){
	print "id [$element_data->{'id'}{'id'}] name [$element_data->{'id'}{'name'}] desc [$element_data->{'id'}{'desc'}] group [$element_data->{'id'}{'group'}] class [$element_data->{'object'}{'class'}] model [$element_data->{'object'}{'model'}]\n";
}


1;
