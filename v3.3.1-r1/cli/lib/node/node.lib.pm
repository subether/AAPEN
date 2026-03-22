#
# ETHER|AAPEN|CLI - LIB|NODE
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
# list nodes [NULL]
#
sub node_list_new($flag, $string){
	my $fid = "node list";
	my $ffid = "NODE|LIST";
	my $meta = node_rest_meta();
	my $node_index = $meta->{'response'}{'meta'}{'network'}{'index'};

	# build index
	my @nodes = index_split($node_index);

	my $length = @nodes;
	print "\n[", BOLD BLUE, "nodes", RESET, "] [$length]\n\n";
	my $count = 0;
	
	foreach my $nodeid (@nodes){
		my $node = node_rest_get($nodeid);
		$node = $node->{'response'}{'node'};
		
		# list all
		if($flag eq "all"){
			node_list_print($node);
			$count++;
		}

		# search cluster
		if($flag eq "cluster"){
			if($node->{'id'}{'cluster'} =~ $string){
				node_list_print($node);
				$count++;
			}
		}
		
		# search groups
		if($flag eq "group"){
			if($node->{'id'}{'group'} =~ $string){
				node_list_print($node);
				$count++;
			}
		}

		# search name
		if($flag eq "name"){
			if($node->{'id'}{'name'} =~ $string){
				node_list_print($node);
				$count++;
			}
		}		
		
		# offline nodes
		if($flag eq "online"){
			if($node->{'meta'}{'state'} eq "1"){
				node_list_print($node);
				$count++;
			}
		}	
		
		# offline nodes
		if($flag eq "offline"){
			if($node->{'meta'}{'state'} eq "0"){
				node_list_print($node);
				$count++;
			}
		}			
		
	}
	
	print "\nListed [$count] nodes with filter [$flag]\n";
}

#
# node info print [NULL]
#
sub node_list_print($node){
	
	my $nodeid = $node->{'id'}{'id'};
	
	print " id [", BOLD BLUE, $nodeid, RESET, "] name [", BOLD, $node->{'id'}{'name'}, RESET, "]";
	print " cluster [", BOLD, $node->{'id'}{'cluster'}, RESET, "]";
	
	if((defined $node->{'object'}{'meta'}) && (defined $node->{'object'}{'meta'}{'ver'}) && (defined $node->{'object'}{'meta'}{'date'})){
	
		if($node->{'meta'}{'state'} eq "1"){
			print " - state [", BOLD GREEN, "ONLINE", RESET, "] ver [", BOLD BLACK, $node->{'object'}{'meta'}{'ver'} , RESET, "] updated [", BOLD, $node->{'object'}{'meta'}{'date'}, RESET, "] ";
			my $diff = date_str_diff_now($node->{'object'}{'meta'}{'date'});
			print "delta [", BOLD BLACK, $diff, RESET, "]";
			
			if($diff < 180){
				print " - [", BOLD GREEN, "HEALTHY", RESET, "] "; 
			}
			
			elsif($diff < 320){
				print " - [", BOLD MAGENTA, "WARNING", RESET, "] "; 
			}
			
			elsif($diff < 480){
				print " - [", BOLD RED, "ERROR", RESET, "] "; 
			}
			else{
				print " - [", BOLD RED, "FAILURE", RESET, "] "; 
			}
			
			print "\n";
			
		}
		elsif($node->{'meta'}{'state'} eq "2"){
			print " - state [", BOLD MAGENTA, "UNAVAIL", RESET, "] ver [", BOLD BLACK, $node->{'object'}{'meta'}{'ver'} , RESET, "] updated [", BOLD, $node->{'object'}{'meta'}{'date'}, RESET, "] ";
			my $diff = date_str_diff_now($node->{'object'}{'meta'}{'date'});
			print "delta [", BOLD BLACK, $diff, RESET, "]";
			
			if($diff < 180){
				print " - [", BOLD GREEN, "HEALTHY", RESET, "] "; 
			}
			
			elsif($diff < 320){
				print " - [", BOLD MAGENTA, "WARNING", RESET, "] "; 
			}
			
			elsif($diff < 480){
				print " - [", BOLD RED, "ERROR", RESET, "] "; 
			}
			else{
				print " - [", BOLD RED, "FAILURE", RESET, "] "; 
			}
			
			print "\n";
			
		}
		else{
			print " - state [", BOLD, "OFFLINE", RESET, "] ver [", BOLD BLACK, $node->{'object'}{'meta'}{'ver'} , RESET, "] last seen [", BOLD, $node->{'object'}{'meta'}{'date'}, RESET, "]\n";
		}
	}
	else{
		print " - state [", BOLD, "OFFLINE", RESET, "]\n"; 
	}

}

1;
