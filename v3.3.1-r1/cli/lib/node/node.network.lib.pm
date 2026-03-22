#
# ETHER|AAPEN|CLI - LIB|NODE|NETWORK
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
# ping network service on node [JSON-OBJ]
#
sub node_rest_network_ping($node_name){
	my $fid = "node_rest_network_ping";
	my $ffid = "NODE|NETWORK|PING";
	my $result = rest_get_request("/service/network/ping?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node network ping");
}

#
# get network service metadata for node [JSON-OBJ]
#
sub node_rest_network_meta($node_name){
	my $fid = "node_rest_network_meta";
	my $ffid = "NODE|NETWORK|META";
	my $result = rest_get_request("/service/network/meta?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node network meta");
}

#
# get network service data from node [JSON-OBJ]
#
sub node_rest_network_service_get($node_name){
	my $fid = "node_rest_network_service_get";
	my $ffid = "NODE|NETWORK|GET";
	
	# need to convert id to name
	my $result = rest_get_request("/service/network/get?name=" . $node_name);
	
	if($result->{'proto'}{'result'}){
		return $result->{'response'}{'service'}{'network'}{$node_name};
	}
	else{
		print "$fid operation failed!\n";
		return 0;
	}
	
}

#
# list networks on node [NULL]
#
sub node_rest_network_list($nodeid){
	my $ffid = "NODE|NETWORK|LIST";
	
	my $net_service_data = node_rest_network_service_get($nodeid);
	
	# process networks
	my @net_index = index_split($net_service_data->{'net'}{'index'}{'name'});
	
	foreach my $net (@net_index){
		print " [NETWORK] id [$net] id [$net_service_data->{'net'}{$net}{'id'}{'id'}] name [$net_service_data->{'net'}{$net}{'id'}{'name'}]\n";
		
		if(defined $net_service_data->{'net'}{$net}{'stats'}){
			print "    '- [STATS] [TX] data [$net_service_data->{'net'}{$net}{'stats'}{'tx'}] - [RX] data [$net_service_data->{'net'}{$net}{'stats'}{'tx'}]\n";
		}
		
		if(defined $net_service_data->{'net'}{$net}{'vm'}){
			my @vm_index = index_split($net_service_data->{'net'}{$net}{'vm'}{'index'});
			
			foreach my $vm (@vm_index){
				print "    '- [VM] name [$vm] nic [$net_service_data->{'net'}{$net}{'vm'}{$vm}]\n";
			}
		}
		
		print "\n";	
	}	
}

#
# list network taps on node [NULL]
#
sub node_rest_network_tap_list($nodeid){
	my $ffid = "NODE|NETWORK|TAP|LIST";
	
	my $net_service_data = node_rest_network_service_get($nodeid);
	
	print "TAP INDEX [$net_service_data->{'tap'}{'index'}]\n\n";

	# process networks
	my @tap_index = index_split($net_service_data->{'tap'}{'index'});
	
	foreach my $tap (@tap_index){
		print " [TAP] tap [$tap] system id [$net_service_data->{'tap'}{$tap}{'vm'}{'id'}] name [$net_service_data->{'tap'}{$tap}{'vm'}{'name'}] dev [$net_service_data->{'tap'}{$tap}{'vm'}{'dev'}] net [$net_service_data->{'tap'}{$tap}{'tap'}{'net'}] bri [$net_service_data->{'tap'}{$tap}{'tap'}{'bri'}]\n";	
		
		if(defined $net_service_data->{'tap'}{$tap}{'stats'}){
			print "    '- [STATS] [TX] bytes [$net_service_data->{'tap'}{$tap}{'stats'}{'tx'}{'bytes'}] error [$net_service_data->{'tap'}{$tap}{'stats'}{'tx'}{'errors'}] dropped [$net_service_data->{'tap'}{$tap}{'stats'}{'tx'}{'dropped'}] multicast [$net_service_data->{'tap'}{$tap}{'stats'}{'tx'}{'multicast'}] data [$net_service_data->{'tap'}{$tap}{'stats'}{'tx'}{'data'}]\n";
			print "    '- [STATS] [RX] bytes [$net_service_data->{'tap'}{$tap}{'stats'}{'rx'}{'bytes'}] error [$net_service_data->{'tap'}{$tap}{'stats'}{'rx'}{'errors'}] dropped [$net_service_data->{'tap'}{$tap}{'stats'}{'rx'}{'dropped'}] multicast [$net_service_data->{'tap'}{$tap}{'stats'}{'rx'}{'multicast'}] data [$net_service_data->{'tap'}{$tap}{'stats'}{'rx'}{'data'}]\n";
		}
		
		print "\n";
	}	

}

#
# list network taps on node [NULL]
#
sub node_rest_network_tap_meta($nodeid){
	my $ffid = "NODE|NETWORK|TAP|META";
	my $result = node_rest_network_service_get($nodeid);
	api_rest_response_print($ffid, $result, "node network tap");
}

#
# show node network device meta [NULL]
#
sub node_rest_network_dev_meta($nodeid){
	my $ffid = "NODE|NETWORK|INTERFACE|META";
	my $result = node_rest_network_service_get($nodeid);
	api_rest_response_print($ffid, $result, "node network interface");
}

#
# list node network devices [NULL]
#
sub node_network_dev_list($nodeid){
	my $net_service_data = node_rest_network_service_get($nodeid);
	my @dev_index = index_split($net_service_data->{'interface'}{'index'});
	
	print "\n";
	
	foreach my $dev (@dev_index){

		# ETHERNET INTERFACE
		if($net_service_data->{'interface'}{$dev}{'type'} eq "interface"){
			print " [DEVICE] dev [$dev] id [$net_service_data->{'interface'}{$dev}{'id'}{'id'}] name [$net_service_data->{'interface'}{$dev}{'id'}{'name'}] desc [$net_service_data->{'interface'}{$dev}{'id'}{'desc'}] type [$net_service_data->{'interface'}{$dev}{'type'}]\n";
			print "    '- [LINK] link [$net_service_data->{'interface'}{$dev}{'meta'}{'link'}] duplex [$net_service_data->{'interface'}{$dev}{'meta'}{'mtu'}] duplex [$net_service_data->{'interface'}{$dev}{'meta'}{'duplex'}] speed [$net_service_data->{'interface'}{$dev}{'meta'}{'speed'}]\n";
			print "    '- [ADDR] hwaddr [$net_service_data->{'interface'}{$dev}{'meta'}{'hwaddr'}] addr [$net_service_data->{'interface'}{$dev}{'meta'}{'addr'}] mask [$net_service_data->{'interface'}{$dev}{'meta'}{'netmask'}]\n";
			print "    '- [STATS] [TX] bytes [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'bytes'}] error [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'errors'}] dropped [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'dropped'}] multicast [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'multicast'}] data [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'data'}]\n";
			print "    '- [STATS] [RX] bytes [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'bytes'}] error [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'errors'}] dropped [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'dropped'}] multicast [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'multicast'}] data [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'data'}]\n";
		}
		
		# ETHERNET BOND INTERFACE
		if($net_service_data->{'interface'}{$dev}{'type'} eq "bond"){
			print " [BOND] dev [$dev] id [$net_service_data->{'interface'}{$dev}{'id'}{'id'}] name [$net_service_data->{'interface'}{$dev}{'id'}{'name'}] desc [$net_service_data->{'interface'}{$dev}{'id'}{'desc'}] type [$net_service_data->{'interface'}{$dev}{'type'}] members [$net_service_data->{'interface'}{$dev}{'bond'}{'member'}] type [$net_service_data->{'interface'}{$dev}{'bond'}{'type'}] hash [$net_service_data->{'interface'}{$dev}{'bond'}{'hash'}]\n";
			
			# check for metadata
			if(defined $net_service_data->{'interface'}{$dev}{'meta'}){
				print "    '- [LINK] link [$net_service_data->{'interface'}{$dev}{'meta'}{'link'}] duplex [$net_service_data->{'interface'}{$dev}{'meta'}{'mtu'}] duplex [$net_service_data->{'interface'}{$dev}{'meta'}{'duplex'}] speed [$net_service_data->{'interface'}{$dev}{'meta'}{'speed'}]\n";
				print "    '- [ADDR] hwaddr [$net_service_data->{'interface'}{$dev}{'meta'}{'hwaddr'}] addr [$net_service_data->{'interface'}{$dev}{'meta'}{'addr'}] mask [$net_service_data->{'interface'}{$dev}{'meta'}{'netmask'}]\n";
				print "    '- [STATS] [TX] bytes [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'bytes'}] error [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'errors'}] dropped [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'dropped'}] multicast [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'multicast'}] data [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'data'}]\n";
				print "    '- [STATS] [RX] bytes [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'bytes'}] error [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'errors'}] dropped [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'dropped'}] multicast [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'tx'}{'multicast'}] data [$net_service_data->{'interface'}{$dev}{'meta'}{'stats'}{'rx'}{'data'}]\n";
			}
			
			my @member_index = index_split($net_service_data->{'interface'}{$dev}{'bond'}{'member'});
			
			foreach my $member (@member_index){
				print "     '- [MEMBER] [$member] id [$net_service_data->{'interface'}{$dev}{'bond'}{$member}{'id'}] name [$net_service_data->{'interface'}{$dev}{'bond'}{$member}{'name'}] desc [$net_service_data->{'interface'}{$dev}{'bond'}{$member}{'desc'}]\n";
				print "          '- [LINK] link [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'link'}] driver [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'driver'}] port [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'port'}] duplex [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'duplex'}] speed [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'speed'}]\n";
				print "          '- [STATS] [TX] bytes [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'tx'}{'bytes'}] error [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'tx'}{'errors'}] dropped [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'tx'}{'dropped'}] multicast [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'tx'}{'multicast'}] data [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'tx'}{'data'}]\n";
				print "          '- [STATS] [TX] bytes [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'rx'}{'bytes'}] error [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'rx'}{'errors'}] dropped [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'rx'}{'dropped'}] multicast [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'rx'}{'multicast'}] data [$net_service_data->{'interface'}{$dev}{'meta'}{$member}{'stats'}{'rx'}{'data'}]\n";
			}
			
		}
		
		# INFINIBAND INTERFACE
		if($net_service_data->{'interface'}{$dev}{'type'} eq "infiniband"){
			print " [INFINIBAND] dev [$dev] id [$net_service_data->{'interface'}{$dev}{'id'}{'id'}] name [$net_service_data->{'interface'}{$dev}{'id'}{'name'}] desc [$net_service_data->{'interface'}{$dev}{'id'}{'desc'}] device [$net_service_data->{'interface'}{$dev}{'dev'}] ports [$net_service_data->{'interface'}{$dev}{'ports'}]\n";
			
			if(defined $net_service_data->{'interface'}{$dev}{'meta'}{'hca_model'}){
				print "    '- [STATS] model [$net_service_data->{'interface'}{$dev}{'meta'}{'hca_model'}] guid [$net_service_data->{'interface'}{$dev}{'meta'}{'hca_guid'}] fw [$net_service_data->{'interface'}{$dev}{'meta'}{'hca_fw'}]\n";
			}

			my @ib_ports = index_split($net_service_data->{'interface'}{$dev}{'ports'});
			
			foreach my $ib_port (@ib_ports){
				  print "     '- [PORT] id [$ib_port] link [$net_service_data->{'interface'}{$dev}{'meta'}{'port'}{$ib_port}{'link'}] state [$net_service_data->{'interface'}{$dev}{'meta'}{'port'}{$ib_port}{'state'}] phys [$net_service_data->{'interface'}{$dev}{'meta'}{'port'}{$ib_port}{'phys'}] speed [$net_service_data->{'interface'}{$dev}{'meta'}{'port'}{$ib_port}{'speed'}]\n"
			}
						
		}
	
		print "\n";
	}	
	
}

1;
