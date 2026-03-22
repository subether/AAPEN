#
# ETHER|AAPEN|NETWORK - LIB|CLUSTER
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
# sync with cdb [NULL]
#
sub network_cdb_sync(){
	my $fid = "[network_cdb_sync]";
	my $ffid = "CLUSTER|SYNC";
	my $db = net_db_get();
	my $meta = {};
	
	# config
	$meta->{'updated'} = date_get();
	$meta->{'config'} = $db->{'config'}; 
	$meta->{'config'}{'service'} = "network";
	
	log_info($ffid, "------ [ updating network metadata ] ------");
	
	# network index
	$meta = network_cdb_net_meta($meta);
	$meta->{'net'}{'index'}{'id'} = $db->{'net'}{'index'};
	$meta->{'vpp'}{'index'} = $db->{'vpp'}{'index'};	
	$meta->{'net'}{'index'}{'id'} = $db->{'net'}{'index'};
	
	# metadata
	$meta->{'vnic'} = $db->{'vnic'};
	$meta->{'tap'} = $db->{'tap'};
	$meta->{'bri'} = $db->{'bri'};
	$meta->{'vpp'} = $db->{'vpp'};

	# interfaces
	$meta->{'interface'} = $db->{'interface'};

	log_info($ffid, "------ [ updating system metadata ] ------");
	
	$meta = network_cdb_vm_meta($meta);
	
	my $result = api_cluster_local_service_set(env_serv_sock_get("cluster"), $meta);
}

#
# check vm network status [JSON-OBJ]
#
sub network_cdb_net_meta($meta){
	my $fid = "[network_cdb_net_meta]";
	my $ffid = "CLUSTER|NET|META";
	my $status = 0;
	my $db = net_db_get();
	
	my @net_index = index_split($db->{'net'}{'index'});
	
	foreach my $net (@net_index){
		
		$meta->{'net'}{'index'}{'name'} = index_add($meta->{'net'}{'index'}{'name'}, $db->{'net'}{$net}{'id'}{'name'});
		my $netname = $db->{'net'}{$net}{'id'}{'name'};
		
		$meta->{'net'}{$netname}{'id'}{'id'} = $db->{'net'}{$net}{'id'}{'id'};
		$meta->{'net'}{$netname}{'id'}{'name'} = $db->{'net'}{$net}{'id'}{'name'};
		
		#
		# vlan
		#
		if($db->{'net'}{$net}{'meta'}{'type'} eq "vlan"){
			my $brdev = $db->{'net'}{$net}{'bri'}{'brdev'};

			$meta->{'net'}{$netname}{'stats'}{'rx'} = $db->{'bri'}{$brdev}{'stats'}{'rx'}{'data'};
			$meta->{'net'}{$netname}{'stats'}{'tx'} = $db->{'bri'}{$brdev}{'stats'}{'tx'}{'data'};
			$meta->{'net'}{$netname}{'stats'}{'rx'} = $db->{'bri'}{$brdev}{'stats'}{'rx'}{'data'};
			$meta->{'net'}{$netname}{'stats'}{'tx'} = $db->{'bri'}{$brdev}{'stats'}{'tx'}{'data'};
			$meta->{'net'}{$netname}{'class'} = "vlan";
			$meta->{'net'}{$netname}{'model'} = "tap";
			$meta->{'net'}{$netname}{'bridge'} = $brdev;
			
			if(!defined $meta->{'net'}{$netname}{'stats'}{'rx'}){
				$meta->{'net'}{$netname}{'stats'}{'rx'} = 0;
			}

			if(!defined $meta->{'net'}{$netname}{'stats'}{'tx'}){
				$meta->{'net'}{$netname}{'stats'}{'tx'} = 0;
			}
			
			log_info($ffid, "net [$net] - type [vlan] rx [$meta->{'net'}{$netname}{'stats'}{'rx'}] tx [$meta->{'net'}{$netname}{'stats'}{'tx'}]");
		}

		#
		# trunk
		#
		if($db->{'net'}{$net}{'meta'}{'type'} eq "trunk"){		
			my $brdev = $db->{'net'}{$net}{'bri'}{'brdev'};

			$meta->{'net'}{$netname}{'stats'}{'rx'} = $db->{'bri'}{$brdev}{'stats'}{'rx'}{'data'};
			$meta->{'net'}{$netname}{'stats'}{'tx'} = $db->{'bri'}{$brdev}{'stats'}{'tx'}{'data'};
			$meta->{'net'}{$netname}{'stats'}{'rx'} = $db->{'bri'}{$brdev}{'stats'}{'rx'}{'data'};
			$meta->{'net'}{$netname}{'stats'}{'tx'} = $db->{'bri'}{$brdev}{'stats'}{'tx'}{'data'};
			$meta->{'net'}{$netname}{'class'} = "trunk";
			$meta->{'net'}{$netname}{'model'} = "tap";
			$meta->{'net'}{$netname}{'bridge'} = $brdev;
			
			if(!defined $meta->{'net'}{$netname}{'stats'}{'rx'}){
				$meta->{'net'}{$netname}{'stats'}{'rx'} = 0;
			}

			if(!defined $meta->{'net'}{$netname}{'stats'}{'tx'}){
				$meta->{'net'}{$netname}{'stats'}{'tx'} = 0;
			}
			
			log_info($ffid, "net [$net] - type [trunk] rx [$meta->{'net'}{$netname}{'stats'}{'rx'}] tx [$meta->{'net'}{$netname}{'stats'}{'tx'}]");
		}

		#
		# vpp
		#
		if(vpp_status() && $db->{'net'}{$net}{'meta'}{'type'} eq "vpp"){			
			my $rx_bytes = "N/A";
			my $tx_bytes = "N/A";
			
			$meta->{'net'}{$netname}{'stats'}{'rx'} = $db->{'vpp'}{$netname}{'stats'}{'rx'}{'data'};
			$meta->{'net'}{$netname}{'stats'}{'tx'} = $db->{'vpp'}{$netname}{'stats'}{'tx'}{'data'};
			$meta->{'net'}{$netname}{'class'} = "vlan";
			$meta->{'net'}{$netname}{'model'} = "vpp";
			
			log_info($ffid, "net [$net] - type [VPP] rx [$meta->{'net'}{$netname}{'stats'}{'rx'}] tx [$meta->{'net'}{$netname}{'stats'}{'tx'}]");
		}
		else{
			#print " - VPP disabled\n";
		}
	}
	
	return $meta;
}

#
# check vm network status [JSON-OBJ]
#
sub network_cdb_vm_net_meta($netname){
	my $fid = "[network_cdb_vm_net_meta]";
	my $ffid = "CLUSTER|VM|NET|META";
	my $status = 0;
	my $db = net_db_get();
	my $meta;
	
	my @vm_index = index_split($db->{'vm'}{'index'});
	
	foreach my $vm (@vm_index){		
		my @nic_index = index_split($db->{'vm'}{$vm}{'net'}{'dev'});
		
		foreach my $nic (@nic_index){
			
			if($db->{'vm'}{$vm}{'net'}{$nic}{'net'}{'name'} eq $netname){
				$meta->{'name'} = index_add($meta->{'name'}, $db->{'vm'}{$vm}{'id'}{'name'});
				$meta->{'id'} = index_add($meta->{'id'}, $db->{'vm'}{$vm}{'id'}{'id'});
			}
		}
	}
	
	return $meta;
}

#
# check vm network status [JSON-OBJ]
#
sub network_cdb_vm_meta($meta){
	my $fid = "[network_cdb_vm_meta]";
	my $ffid = "CLUSTER|VM|META";
	my $status = 0;
	my $db = net_db_get();
	
	my @vm_index = index_split($db->{'vm'}{'index'});
	
	foreach my $vm (@vm_index){		
		my $netstats = {};
		my @nic_index = index_split($db->{'vm'}{$vm}{'net'}{'dev'});
		
		foreach my $nic (@nic_index){
			my $nicdata = $db->{'vm'}{$vm}{'net'}{$nic};	
			my $netname = $db->{'vm'}{$vm}{'net'}{$nic}{'net'}{'name'};
			
			# dpdk
			if($nicdata->{'net'}{'type'} eq "dpdk-vpp"){
				log_info($ffid, "vm [$vm] nic [$nic] type [$nicdata->{'net'}{'type'}]");
				
				my $vnic = $nicdata->{'vpp'}{'vnic'};
				$meta->{'net'}{$netname}{'vm'}{$vm} = index_add($meta->{'net'}{$netname}{'vm'}{$vm}, $nic);
				$meta->{'net'}{$netname}{'vm'}{'index'} = index_add($meta->{'net'}{$netname}{'vm'}{'index'}, $vm);
			}

			# tuntap
			if($nicdata->{'net'}{'type'} eq "bri-tap"){
				log_info($ffid, "vm [$vm] nic [$nic] type [$nicdata->{'net'}{'type'}]");
				
				my $tap = $nicdata->{'tap'}{'tap'}{'dev'};
				$meta->{'net'}{$netname}{'vm'}{$vm} = index_add($meta->{'net'}{$netname}{'vm'}{$vm}, $nic);
				$meta->{'net'}{$netname}{'vm'}{'index'} = index_add($meta->{'net'}{$netname}{'vm'}{'index'} , $vm);
			}
		}
		
	}

	return $meta;
}

#
# check network status [NULL]
#
sub network_cdb_check(){
	my $fid = "[network_cdb_check]";
	my $ffid = "CLUSTER|CHECK";
	my $status = 0;
	my $db = net_db_get();
	my $nodeid = config_node_id_get();
	
	log_info($ffid, "------ [ cluster sync ] ------");
		
	my $netmeta = api_cluster_local_meta_get(env_serv_sock_get("cluster"));
	my @net_index = index_split($netmeta->{'meta'}{'network'}{'index'});

	foreach my $net (@net_index){
		
		if(net_check_name($net)){
			my $netid = net_get_id_from_name($net);
			
			if($db->{'net'}{$netid}{'meta'}{'type'} eq "vpp"){
				my $name = $db->{'net'}{$netid}{'id'}{'name'};
				
				if(vpp_status()){
					log_info($ffid, "net [$net] id [$netid] state [KNOWN] model [VPP] - [ENABLED]");

					if(defined $db->{'vpp'}{$name}{'stats'}){
						log_info($ffid, "net [$net] id [$netid] name [$name] state [KNOWN] model [VPP] - [ENABLED] - [STATS]");						
						$db->{'vpp'}{$net}{'stats'}{'vm'} = network_cdb_vm_net_meta($net);
						my $stats_result = network_cdb_meta_set($name, $db->{'vpp'}{$net}{'stats'});
					}
					else{
						log_info($ffid, "net [$net] id [$netid] name [$name] state [KNOWN] model [VPP] - [ENABLED]");
					}
				}
				else{
					log_info($ffid, "net [$net] id [$netid] name [$name] type [VLAN] state [KNOWN] model [VPP] - [DISABLED]");
				}
			}
			#else{
			#	print " type [VPP] - disabled\n";
			#}
			
			if($db->{'net'}{$netid}{'meta'}{'type'} eq "vlan"){				
				my $brdev = $db->{'net'}{$netid}{'bri'}{'brdev'};
				my $name = $db->{'net'}{$netid}{'id'}{'name'};
			
				if(defined $db->{'bri'}{$brdev}{'stats'}){
					log_info($ffid, "net [$net] id [$netid] name [$name]  type [VLAN] bridge [$brdev] state [KNOWN] model [BRI] - [ENABLED] - [STATS]");
					
					$db->{'bri'}{$brdev}{'stats'}{'netdev'} = $db->{'net'}{$netid}{'node'}{$nodeid};
					$db->{'bri'}{$brdev}{'stats'}{'vm'} = network_cdb_vm_net_meta($net);
					my $stats_result = network_cdb_meta_set($name, $db->{'bri'}{$brdev}{'stats'});
				}
				else{
					log_info($ffid, "net [$net] id [$netid] name [$name]  type [VLAN] bridge [$brdev] state [KNOWN] model [BRI] - [ENABLED]");
				}
			}
			
			if($db->{'net'}{$netid}{'meta'}{'type'} eq "trunk"){
				my $brdev = $db->{'net'}{$netid}{'bri'}{'brdev'};
				my $name = $db->{'net'}{$netid}{'id'}{'name'};
			
				if(defined $db->{'bri'}{$brdev}{'stats'}){
					log_info($ffid, "net [$net] id [$netid] name [$name] type [TRUNK] bridge [$brdev] state [KNOWN] model [BRI] - [ENABLED] - [STATS]");
					
					$db->{'bri'}{$brdev}{'stats'}{'netdev'} = $db->{'net'}{$netid}{'node'}{$nodeid};
					$db->{'bri'}{$brdev}{'stats'}{'vm'} = network_cdb_vm_net_meta($net);
					my $stats_result = network_cdb_meta_set($name, $db->{'bri'}{$brdev}{'stats'});
				}
				else{
					log_info($ffid, "net [$net] id [$netid] name [$name] type [TRUNK] bridge [$brdev] state [KNOWN] model [BRI] - [ENABLED] - [STATS]");
				}
			}
		}
		else{
			my $netdata = api_cluster_local_obj_get(env_serv_sock_get("cluster"), "network", $net);
			my $id = config_node_id_get();
			
			# check if this node is defined for the network
			if(index_find($netdata->{'network'}{'node'}{'index'}, $id)){
				log_info($ffid, "net [$net] name [$netdata->{'network'}{'id'}{'name'}] - state [UNKNOWN] - node id [DEFINED] - [INITIALIZING]");
				net_push($netdata->{'network'});
				$status = 1;
			}
			else{
				# network not defined for this node
				log_info($ffid, "net [$net] - name [$netdata->{'network'}{'id'}{'name'}] - state [UNKNOWN] - node id [UNDEFINED] - [DEFERRING]");
			}
		}
	}
	
	# check for changes
	if($status){
		sleep 2;
		network_stats();
		sleep 2;		
		network_cdb_sync();
	}

}

#
# check vm network status [NULL]
#
sub network_cdb_vm_check(){
	my $fid = "[network_cdb_vm_check]";
	my $ffid = "CLUSTER|VM|CHECK";
	my $status = 0;
	my $db = net_db_get();
	
	my @vm_index = index_split($db->{'vm'}{'index'});
	
	foreach my $vm (@vm_index){
		my $netstats = {};
		my @nic_index = index_split($db->{'vm'}{$vm}{'net'}{'dev'});
		
		foreach my $nic (@nic_index){
			my $nicdata = $db->{'vm'}{$vm}{'net'}{$nic};
			
			# dpdk-vpp
			if($nicdata->{'net'}{'type'} eq "dpdk-vpp"){
				my $vnic = $nicdata->{'vpp'}{'vnic'};
				$netstats->{$nic} = vpp_vnic_stats($db->{'vnic'}{$vnic});
			}

			# tuntap
			if($nicdata->{'net'}{'type'} eq "bri-tap"){
				my $tap = $nicdata->{'tap'}{'tap'}{'dev'};
				$netstats->{$nic} = dev_get_stats_iproute2("tap" . $tap);
			}
		}

		log_info($ffid, "publising metadata to cluster");
		network_vm_cdb_meta_set($vm, $netstats);
	}
}

#
# commit vm metadata [NULL]
#
sub network_vm_cdb_meta_set($system, $meta){
	my $fid = "CLUSTER|VM|META|SET";
	
	my $packet;
	$packet->{'cluster'}{'obj'} = "system";
	$packet->{'cluster'}{'key'} = $system;
	$packet->{'cluster'}{'id'} = "network";
	
	$meta->{'updated'} = date_get();
	$packet->{'data'} = $meta;
	
	my $result = api_cluster_local_obj_meta_set(env_serv_sock_get("cluster"), $packet);
}

#
# gather network stats [NULL]
#
sub network_stats(){
	my $fid = "[network_stats]";
	my $ffid = "CLUSTER|NET|STATS";
	my $stats = {};
	my $db = net_db_get();
	
	log_info($ffid, "------ [ updating network stats ] ------");
		
	#
	# bridge
	#
	if($db->{'bri'}{'index'}){
		my @bridge_index = index_split($db->{'bri'}{'index'});
		
		# process bridges
		foreach my $bri (@bridge_index){
			my $nodeid = config_node_id_get();
			my $netdev = "";
			
			# process vlan tagged bridges
			if($db->{'bri'}{$bri}{'bri'}{'type'} eq "vlan"){
				$netdev = $db->{'bri'}{$bri}{'bri'}{'ethdev'} . "." .  $db->{'bri'}{$bri}{'bri'}{'vlan'};
				$db->{'bri'}{$bri}{'stats'} = dev_get_stats_iproute2($netdev);
				$db->{'bri'}{$bri}{'stats'}{'brdev'} = $bri;
			
				log_info($ffid, "net [$db->{'net'}{$db->{'bri'}{$bri}{'bri'}{'netid'}}{'id'}{'name'}] bri [$bri] device [$db->{'bri'}{$bri}{'bri'}{'ethdev'}] vlan [$db->{'bri'}{$bri}{'bri'}{'vlan'}] type [VLAN]");
			}
			
			# process trunked bridges
			if($db->{'bri'}{$bri}{'bri'}{'type'} eq "trunk"){
				$netdev = $db->{'bri'}{$bri}{'bri'}{'ethdev'};
				
				if($netdev eq "NULL" || $netdev eq "null"){
					# use bridge for NULL interfaces
					log_info($ffid, "net [$db->{'net'}{$db->{'bri'}{$bri}{'bri'}{'netid'}}{'id'}{'name'}] bri [$bri] device [$db->{'bri'}{$bri}{'bri'}{'ethdev'}] type [TRUNK] - [NULL INTERFACE]");
					$db->{'bri'}{$bri}{'stats'} = dev_get_stats_iproute2($bri);
					$db->{'bri'}{$bri}{'stats'}{'brdev'} = $bri;
				}
				else{
					# fetch interface stats
					$db->{'bri'}{$bri}{'stats'} = dev_get_stats_iproute2($netdev);
					$db->{'bri'}{$bri}{'stats'}{'brdev'} = $bri;
					log_info($ffid, "net [$db->{'net'}{$db->{'bri'}{$bri}{'bri'}{'netid'}}{'id'}{'name'}] bri [$bri] device [$db->{'bri'}{$bri}{'bri'}{'ethdev'}] type [TRUNK]");
				}

			}
		}
	}

	#
	# tap
	#
	if($db->{'tap'}{'index'}){
		my @tap_index = index_split($db->{'tap'}{'index'});
		
		foreach my $tap (@tap_index){
			$db->{'tap'}{$tap}{'stats'} = dev_get_stats_iproute2("tap" . $tap);
		}

		#
		# vpp
		#
		my @vpp_index = index_split($db->{'vpp'}{'index'});
		
		foreach my $vpp (@vpp_index){
			
			if(vpp_status()){
				#log_info($ffid, "VPP is enabled");
				$db->{'vpp'}{$vpp} = vpp_bridge_int_stats($db->{'vpp'}{$vpp});
			}
			else{
				#log_info($ffid, "VPP is disabled");
			}
		}
	}
	
	#
	# vnic
	#
	if($db->{'vnic'}{'index'}){
		my @vnic_index = index_split($db->{'vnic'}{'index'});
		
		foreach my $vnic (@vnic_index){
			$db->{'vnic'}{$vnic} = vpp_vnic_stats($db->{'vnic'}{$vnic});
		}
	}
	
	net_db_set($db);
}


#
# set network metadata [NULL]
#
sub network_cdb_meta_set($network, $meta){
	my $fid = "[network_cdb_meta_set]";
	my $ffid = "CLUSTER|META|SET";
	
	my $packet;
	$packet->{'cluster'}{'obj'} = "network";
	$packet->{'cluster'}{'key'} = $network;
	$packet->{'cluster'}{'id'} = config_node_name_get();
	
	$meta->{'updated'} = date_get();
	$packet->{'data'} = $meta;
	
	my $result = api_cluster_local_obj_meta_set(env_serv_sock_get("cluster"), $packet);
}

1;
