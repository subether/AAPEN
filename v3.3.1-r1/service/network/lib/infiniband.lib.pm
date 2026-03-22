#
# ETHER|AAPEN|NETWORK - LIB|INFINIBAND
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


#
# get infiniband device stats [JSON-OBJ]
#
sub ib_dev_stats($device){
	my $fid = "[ib_dev_stats]";
	my $ffid = "DEV|IB|STATS";

	# Validate input device structure
	unless (ref($device) eq 'HASH' && exists $device->{'dev'}) {
		warn "$fid Invalid device structure";
		return {};
	}

	# Sanitize device name
	my $dev = $device->{'dev'};
	$dev =~ s/[^a-zA-Z0-9_-]//g;
	unless ($dev) {
		warn "$fid Invalid device name";
		return {};
	}

	my $meta = {};
	eval {
		$meta->{'hca_desc'} = ib_dev_hca_desc($dev);
		$meta->{'hca_model'} = ib_dev_hca_model($dev);
		$meta->{'hca_fw'} = ib_dev_hca_fw($dev);
		$meta->{'hca_guid'} = ib_dev_hca_guid($dev);
		
		# ports
		my @ports = index_split($device->{'ports'});
		
		foreach my $port (@ports) {
			# sanitize port number
			$port =~ s/[^0-9]//g;
			next unless $port;

			$meta->{'port'}{$port}{'state'} = ib_dev_port_state($dev, $port);
			$meta->{'port'}{$port}{'speed'} = ib_dev_port_rate($dev, $port);
			$meta->{'port'}{$port}{'link'} = ib_dev_port_link($dev, $port);
			$meta->{'port'}{$port}{'phys'} = ib_dev_port_phys($dev, $port);
						
			log_info($ffid, "dev [$dev] port [$port] state [$meta->{'port'}{$port}{'state'}] speed [$meta->{'port'}{$port}{'speed'}] link [$meta->{'port'}{$port}{'link'}] phys [$meta->{'port'}{$port}{'phys'}]");
		}
	};

	if ($@) {
		warn "$fid Error processing stats: $@";
	}

	return $meta;
}

#
# get port state (#4: ACTIVE) [STRING]
#
sub ib_dev_port_state($dev, $port){
	my $fid = "[ib_dev_port_state]";
	
	my $state = execute("cat /sys/class/infiniband/$dev/ports/$port/state 2>/dev/null");
	unless (defined $state) {
		return "Failed to read port state";
	}
	chomp($state);
	return $state;
}

#
# return rate (40 Gb/sec (4X QDR)) [STRING]
#
sub ib_dev_port_rate($dev, $port){
	my $fid = "[ib_dev_port_rate]";
	
	my $rate = execute("cat /sys/class/infiniband/$dev/ports/$port/rate 2>/dev/null");
	unless (defined $rate) {
		return "Failed to read port rate";
	}
	chomp($rate);
	return $rate;
}

#
# return link type (#InfiniBand) [STRING]
#
sub ib_dev_port_link($dev, $port){
	my $fid = "[ib_dev_port_link]";
	
	my $link = execute("cat /sys/class/infiniband/$dev/ports/$port/link_layer 2>/dev/null");
	unless (defined $link) {
		return "Failed to read link layer";
	}
	chomp($link);
	return $link;
}

#
# return link type (5: LinkUp) [STRING]
#
sub ib_dev_port_phys($dev, $port){
	my $fid = "[ib_dev_port_phys]";
	
	my $state = execute("cat /sys/class/infiniband/$dev/ports/$port/phys_state 2>/dev/null");
	unless (defined $state) {
		return "Failed to read physical state";
	}
	chomp($state);
	return $state;
}

#
# return hca model [STRING]
#
sub ib_dev_hca_model($dev){
	my $fid = "[ib_dev_hca_type]";
	
	my $state = execute("cat /sys/class/infiniband/$dev/hca_type 2>/dev/null");
	unless (defined $state) {
		return "Failed to read HCA model";
	}
	chomp($state);
	return $state;
}

#
# return hca firmware [STRING]
#
sub ib_dev_hca_fw($dev){
	my $fid = "[ib_dev_hca_fw]";
	
	my $state = execute("cat /sys/class/infiniband/$dev/fw_ver 2>/dev/null");
	unless (defined $state) {
		return "Failed to read HCA firmware";
	}
	chomp($state);
	return $state;
}

#
# return hca desc [STRING]
#
sub ib_dev_hca_desc($dev){
	my $fid = "[ib_dev_hca_desc]";
	
	my $state = execute("cat /sys/class/infiniband/$dev/node_desc 2>/dev/null");
	unless (defined $state) {
		return "Failed to read HCA description";
	}
	chomp($state);
	return $state;
}

#
# return hca guid [SRING]
#
sub ib_dev_hca_guid($dev){
	my $fid = "[ib_dev_hca_guid]";
	
	my $state = execute("cat /sys/class/infiniband/$dev/node_guid 2>/dev/null");
	unless (defined $state) {
		return "Failed to read HCA GUID";
	}
	chomp($state);
	return $state;
}

#
# return port phy address [STRING]
#
sub ib_dev_port_addr($dev, $ib){
	my $fid = "[ib_dev_port_addr]";
	

	my $state = execute("cat /sys/class/infiniband/$dev/device/net/$ib/address 2>/dev/null");
	unless (defined $state) {
		return "00:00:00:00:00:00";
	}
	chomp($state);
	return $state;

}

#
# return ipoib devs on ibdev [ARRAY]
#
sub ib_dev_netdev($dev){
	my $fid = "[ib_dev_netdev]";
	
	my @net_devs = read_dir("/sys/class/infiniband/$dev/device/net/");
	unless (@net_devs) {
		warn "$fid No network devices found for $dev";
	}
	@net_devs = sort(@net_devs);
	return @net_devs;
}

1;
