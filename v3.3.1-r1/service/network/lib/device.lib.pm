#
# ETHER|AAPEN|NETWORK - LIB|DEVICE
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
# return device info [JSON-STR]
#
sub dev_info(){
	my $devdb = net_db_obj_get("interface");
	my $devdata->{'net'}{'interface'} = $devdb;
	return json_encode($devdata);
}

#
# init device config [NULL]
#
sub dev_conf_init(){
	my $fid = "DEV|CONF|INIT";

	# fetch the node config	
	my $node_config = config_node_get();

	# check for interface
	if(defined $node_config->{'network'}{'interface'}){
		log_info($fid, "interface configuration present");
		json_encode_pretty($node_config->{'network'}{'interface'});
		net_db_obj_set("interface", $node_config->{'network'}{'interface'});
	}
	else{
		log_info($fid, "interface configuration not found!");
	}
}

#
# gather all device stats [NULL]
#
sub dev_stats(){
	my $fid = "[dev_stats]";
	my $ffid = "DEV|STATS";

	log_info($ffid, "------ [ device discovery ] ------");

	# get interfaces
	my $devdb = net_db_obj_get("interface");	
	my @index_ar = index_split($devdb->{'index'});
	
	# process devices
	foreach my $device (@index_ar){	
		
		# check type
		if($devdb->{$device}{'type'} eq "interface"){			
			# gather device data
			$devdb->{$device}{'meta'} = dev_meta_gather_eth($device);
			log_info($ffid, "dev [$device] type [standalone] driver [$devdb->{$device}{'meta'}{'driver'}] port [$devdb->{$device}{'meta'}{'port'}] speed [$devdb->{$device}{'meta'}{'speed'}] link [$devdb->{$device}{'meta'}{'link'}]");
		}
		elsif($devdb->{$device}{'type'} eq "bond"){

			# gather device data
			$devdb->{$device}{'meta'} = dev_meta_gather_eth($device);
			my @members = index_split($devdb->{$device}{'bond'}{'member'});

			# gather member data
			foreach my $dev (@members){
				$devdb->{$device}{'meta'}{$dev} = dev_meta_gather_eth($dev);
			}
			
			log_info($ffid, "dev [$device] type [standalone] driver [$devdb->{$device}{'meta'}{'driver'}] port [$devdb->{$device}{'meta'}{'port'}] speed [$devdb->{$device}{'meta'}{'speed'}] link [$devdb->{$device}{'meta'}{'link'}]");
		}
		elsif($devdb->{$device}{'type'} eq "infiniband"){
			log_info($ffid, "device [$device] is infiniband");
			$devdb->{$device}{'meta'} = ib_dev_stats($devdb->{$device});
		}
		else{
			log_warn($ffid, "error: unknown device type");
		}
		
		net_db_obj_set("interface", $devdb);	
	}
}

#
# gather device info [JSON-OBJ]
#
sub dev_meta_gather_eth($device){
	my $fid = "[dev_meta_gather_eth]";
	my $ffid = "DEV|META|GATHER";
	my $meta;
	
	# validate interface name
	if (!validate_interface_name($device)) {
		log_error($ffid, "error: invalid device name!");
		return $meta->{'error'} = "invalid device name!";
	}
	
	$meta->{'driver'} = dev_get_driver($device);
	$meta->{'speed'} = dev_get_speed($device);
	$meta->{'duplex'} = dev_get_duplex($device);
	$meta->{'port'} = dev_get_port($device);
	
	# get stats from iproute
	$meta->{'link'} = dev_get_link($device);
	$meta->{'stats'} = dev_get_stats_iproute2($device);
	$meta->{'iproute'} = dev_get_info_iproute2($device);
	$meta = dev_get_interface($device, $meta);	
	
	return $meta;
}

#
# check if iproute2 is available [BOOLEAN]
#
sub has_iproute2(){
	my $result = `which ip 2>/dev/null`;
	chomp($result);
	return $result ne '';
}

#
# get stats using iproute2 [JSON-OBJ]
#
sub dev_get_stats_iproute2($dev){
	my $fid = "[dev_get_stats_iproute2]";
	my $ffid = "DEV|STATS";
	my $stats = {};
	my $exec = "ip -s -j link show $dev 2>/dev/null";
	
	log_debug($ffid, "exec [$exec]");
	
	my $result = `$exec`;
	if ($? != 0) {
		log_warn($ffid, "command failed for dev [$dev] with status [$?]");
	}
	unless ($result) {
		log_warn($ffid, "empty command output for dev [$dev]");
		return;
	}
	
	my $data = decode_json($result)->[0];
	unless ($data && $data->{'stats64'}) {
		log_warn($ffid, "invalid JSON structure");
		return;
	}
	
	# original byte counts
	my $rx_bytes = $data->{'stats64'}{'rx'}{'bytes'} || 0;
	my $tx_bytes = $data->{'stats64'}{'tx'}{'bytes'} || 0;
	
	$stats->{'rx'} = {
		'bytes' => $rx_bytes,
		'packets' => $data->{'stats64'}{'rx'}{'packets'} || 0,
		'errors' => $data->{'stats64'}{'rx'}{'errors'} || 0,
		'dropped' => $data->{'stats64'}{'rx'}{'dropped'} || 0,
		'multicast' => $data->{'stats64'}{'rx'}{'multicast'} || 0,
		'data' => format_bytes($rx_bytes)
	};
	$stats->{'tx'} = {
		'bytes' => $tx_bytes,
		'packets' => $data->{'stats64'}{'tx'}{'packets'} || 0,
		'errors' => $data->{'stats64'}{'tx'}{'errors'} || 0,
		'dropped' => $data->{'stats64'}{'tx'}{'dropped'} || 0,
		'multicast' => $data->{'stats64'}{'tx'}{'multicast'} || 0,
		'data' => format_bytes($tx_bytes)
	};
	
	return $stats;
}

#
# get interface info using iproute2 [JSON-OBJ]
#
sub dev_get_info_iproute2($dev){
	my $fid = "[dev_get_info_iproute2]";
	my $ffid = "DEV|INFO";
	my $info = {};
	my $exec = "ip -j addr show $dev 2>/dev/null";
	
	my $result = `$exec`;
	if ($? != 0) {
		log_warn($ffid, "command failed with status [$?]");
	}
	unless ($result) {
		log_warn($ffid, "empty command output");
	}
	
	my $data = decode_json($result)->[0];
	unless ($data) {
		log_warn($ffid, "invalid JSON structure");
	}
	
	# extract basic interface info
	$info->{'mtu'} = $data->{'mtu'} // "";
	$info->{'state'} = $data->{'operstate'} // "";
	$info->{'hwaddr'} = $data->{'address'} // "";
	
	# extract address info if available
	if ($data->{'addr_info'} && @{$data->{'addr_info'}}) {
		my $addr = $data->{'addr_info'}[0];
		$info->{'addr'} = $addr->{'local'} // "";
		$info->{'netmask'} = $addr->{'prefixlen'} // "";
		$info->{'broadcast'} = $addr->{'broadcast'} // "";
	}
	
	return $info;
}

#
# get interface driver [STRING]
#
sub dev_get_driver($dev){
    my $fid = "[dev_get_driver]";
    my $driver_path = "/sys/class/net/$dev/device/driver";
    
    if (-l $driver_path) {
        my $driver = readlink($driver_path);
        $driver =~ s{.*/}{};  # extract just driver name
        return $driver;
    }
    return "unknown";
}

#
# get interface speed [STRING]
#
sub dev_get_speed($dev) {
    my $fid = "[dev_get_speed]";
    my $speed_path = "/sys/class/net/$dev/speed";
    
    if (-e $speed_path) {
        open(my $fh, '<', $speed_path) or return "unknown";
        my $speed = <$fh>;
        close($fh);
        chomp($speed);
        
        if ($speed == -1) {
            return "unknown";
        }

        return "${speed}Mbps";
    }
    return "unknown";
}

#
# get interface duplex [STRING]
#
sub dev_get_duplex($dev) {
    my $fid = "[dev_get_duplex]";
    my $duplex_path = "/sys/class/net/$dev/duplex";
    
    # get duplex from sysfs
    if (-e $duplex_path) {
        open(my $fh, '<', $duplex_path) or return "unknown";
        my $duplex = <$fh>;
        close($fh);
        chomp($duplex);
        
        if ($duplex =~ /^(full|half)$/) {
            return $duplex;
        }
    }
    
    # fallback to ethtool
    my $result = `/usr/sbin/ethtool $dev 2>/dev/null`;
    if ($? == 0 && $result =~ /Duplex:\s*(\S+)/) {
        my $duplex = lc($1);
        return $duplex;
    }
    
    return "unknown";
}

#
# get interface port [STRING]
#
sub dev_get_port($dev){
	my $fid = "[dev_get_port]";
	my $exec = "/usr/sbin/ethtool $dev 2>/dev/null";
	
	my $result = `$exec`;
	if ($? != 0) {
		log_warn($fid, "ethtool failed with status [$?]");
	}
	unless ($result) {
		log_warn($fid, "empty ethtool output!");
	}
	
	my ($port) = $result =~ /Port:\s*(\S+)/;
	unless ($port) {
		log_warn($fid, "could not parse port");
	}

	return $port;
}

#
# get interface link state [STRING]
#
sub dev_get_link($dev) {
    my $fid = "[dev_get_link]";
    my $carrier_path = "/sys/class/net/$dev/carrier";
    
    # try sysfs
    if (-e $carrier_path) {
        open(my $fh, '<', $carrier_path) or return "unknown";
        my $state = <$fh>;
        close($fh);
        chomp($state);
        
        my $link = ($state == 1) ? "yes" : "no";
        return $link;
    }
    
    # fallback to ethtool
    my $result = `/usr/sbin/ethtool $dev 2>/dev/null`;
    if ($? == 0 && $result =~ /Link detected:\s*(\S+)/) {
        my $link = lc($1);
        return $link;
    }
    
    return "unknown";
}

#
# get interface metrics [JSON-OBJ]
#
sub dev_get_interface($dev, $meta){
	my $fid = "";
	use IO::Interface::Simple;
 
	my $if1 = IO::Interface::Simple->new($dev);
	
	# only set fields if values are defined
	$meta->{'addr'} = $if1->address // "";
	$meta->{'broadcast'} = $if1->broadcast // "";
	$meta->{'netmask'} = $if1->netmask // "";
	$meta->{'dstaddr'} = $if1->dstaddr // "";
	$meta->{'hwaddr'} = $if1->hwaddr // "";
	$meta->{'mtu'} = $if1->mtu // "";
	$meta->{'metric'} = $if1->metric // "";

	# flags are already properly guarded with if statements
	$meta->{'flags'}{'running'} = "1" if $if1->is_running;
	$meta->{'flags'}{'broadcast'} = "1" if $if1->is_broadcast;
	$meta->{'flags'}{'p-to-p'} = "1" if $if1->is_pt2pt;
	$meta->{'flags'}{'loopback'} = "1" if $if1->is_loopback;
	$meta->{'flags'}{'promiscuous'} = "1" if $if1->is_promiscuous;
	$meta->{'flags'}{'multicast'} = "1" if $if1->is_multicast;
	$meta->{'flags'}{'notrailers'} = "1" if $if1->is_notrailers;
	$meta->{'flags'}{'noarp'} = "1" if $if1->is_noarp;	
	
	return $meta;
}

1;
