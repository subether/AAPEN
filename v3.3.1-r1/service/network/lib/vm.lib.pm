#
# ETHER|AAPEN|NETWORK - LIB|VM
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
# get vm data [JSON-STR]
#
sub vm_get($req){
	my $fid = "[vm_get]";
	my $ffid = "VM|GET";

	my $result;
	my $vmdb = net_db_obj_get("vm");
	
	my $vmname = $req->{'vm'}{'name'};
	
	if(index_find($vmdb->{'index'}, $vmname)){
		log_info($ffid, "sucess: vm [$vmname] found in db. returning vm data");
		$result = packet_build_noencode("1", "success: returning vm", $fid);
		$result->{'vmdata'} = $vmdb->{$vmname};
	}
	else{
		log_info($ffid, "failed: vm not [$vmname] found in db.");
		$result = packet_build_noencode("0", "failed: vm not found in db", $fid);
	}
	
	return json_encode($result);
}

#
# add netdevs to vm [JSON-OBJ] (convert to string!)
#
sub vm_nic_add($vm){
	my $fid = "[vm_nic_add]";
	my $ffid = "VM|NIC|ADD";
	my $result;

	if(env_debug()){ json_encode_pretty($vm); };

	# gather interfaces
	log_debug($ffid, "interface index [" . $vm->{'net'}{'dev'} . "]");
	my @netifs = index_split($vm->{'net'}{'dev'});
	
	# process interfaces
	foreach my $netif (@netifs){

		if(defined($vm->{'net'}{$netif}{'net'}{'type'})){

			if($vm->{'net'}{$netif}{'net'}{'type'} eq "dpdk-vpp"){

				if(vpp_status()){
					log_info($ffid, "processing network interface [$netif], network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] as DPDK VPP");
					my $tmp = vm_vpp_init($vm, $netif);
					$result = json_encode($tmp);
				}
				else{
					log_warn($ffid, "VPP functionality is disabled. giving up.");
					$result = packet_build_encode("0", "failed: vpp functionality is disabled", $fid);
				}
			}
			
			if($vm->{'net'}{$netif}{'net'}{'type'} eq "bri-tap"){
				log_info($ffid, "processing network interface [$netif], network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] as TUNTAP");
				$result = vm_tap_init($vm, $netif);
			}

		}
		else{
			log_warn($ffid, "failed: network type is unknown!");
			$result = packet_build_encode("0", "failed: network type is unknown!", $fid);
		}
	}
	
	network_stats();
	network_cdb_sync();
	
	if(env_verbose()){ json_encode_pretty($vm); };
	return $result;
}

#
# initialize vpp vm interface [JSON-OBJ]
#
sub vm_vpp_init($vm, $netif){
	my $fid = "[vm_vpp_init]";
	my $ffid = "VM|VPP|INIT";

	my $netdb = net_db_obj_get("net");
	my $vmdb = net_db_obj_get("vm");
	my $vmid = $vm->{'id'}{'id'};
	my $vnicdb = net_db_obj_get("vnic");
	my $result;

	# check if network is known
	if(index_find($netdb->{'index'}, $vm->{'net'}{$netif}{'net'}{'id'})){
		# network is known
		my $netid = $vm->{'net'}{$netif}{'net'}{'id'};

		# socket
		my $ifsock = "/var/run/vpp/" . $vm->{'id'}{'name'} . "-" . $vm->{'id'}{'id'} . "-" . $netif . ".sock";
		my $mtu = $netdb->{$netid}{'vpp'}{'mtu'};
		my $bridge = $netdb->{$netid}{'vpp'}{'bridge'};
		
		log_info($ffid, "network [$netid] is known. vhost [$netif] socket [$ifsock] mtu [$mtu] bridge [$bridge]");
		
		# add vhost
		my $vppresult = vpp_vhost_add($ifsock, $mtu, $bridge);
		
		# basic sanity
		if($vppresult->{'proto'}{'result'} eq "1"){
			$result = packet_build_noencode("1", "successfully built vpp interface", $fid);
			
			my $vnic = $vm->{'id'}{'name'} . "-" . $vm->{'id'}{'id'} . "-" . $netif;
			
			# save data
			$result->{'proto'}{'vpp'}{$netif} = $vppresult->{'vpp'};
			
			# FIX ME HERE
			$netdb->{$netid}{'vpp'}{$vmid}{$netif} = $vppresult->{'vpp'};
			$vm->{'net'}{$netif}{'vpp'} = $vppresult->{'vpp'};
			$vm->{'net'}{$netif}{'vpp'}{'vnic'} = $vnic;
			$result->{'vm'} = $vm;
			
			# update vnic
			$vnicdb->{'index'} = index_add($vnicdb->{'index'}, $vnic);	
			$vnicdb->{$vnic} = $vppresult->{'vpp'};
			$vnicdb->{$vnic}{'system_name'} = $vm->{'id'}{'name'};
			$vnicdb->{$vnic}{'system_id'} = $vm->{'id'}{'id'};
			$vnicdb->{$vnic}{'netid'} = $netid;
			
			# save vm
			$vmdb->{'index'} = index_add($vmdb->{'index'}, $vm->{'id'}{'name'});
			$vmdb->{$vm->{'id'}{'name'}} = $vm;
			
			net_db_obj_set("vnic", $vnicdb);
			net_db_obj_set("vm", $vmdb);
		}
		else{
			# operation failed!
			log_warn($ffid, "VPP operation failed!");
			$result = $vppresult;
		}
		
	}
	else{
		# network unknown
		log_warn($ffid, "failed: network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] unknown!");
		$result = packet_build_noencode("0", "failed: network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] unknown!", $fid);
	}
	
	return $result;
}

#
# remve vpp interface [JSON-STR]
#
sub vm_vpp_remove($vm, $netif){
	my $fid = "[vm_vpp_remove]";
	my $ffid = "VM|VPP|REMOVE";

	my $vnicdb = net_db_obj_get("vnic");
	my $vmdb = net_db_obj_get("vm");
	
	log_info($ffid, "removing VPP interface [ $vm->{'net'}{$netif}{'vpp'}{'interface'}]");
	
	# remove interface
	my $result = vpp_vhost_del($vm->{'net'}{$netif}{'vpp'}{'interface'});
	
	# basic sanity
	if($result->{'proto'}{'result'} eq "1"){
		log_info($ffid, "success: removed interface [ $vm->{'net'}{$netif}{'vpp'}{'interface'}] sucessfully");
		
		my $vnic = $vm->{'net'}{$netif}{'vpp'}{'vnic'};
		$vnicdb->{'index'} = index_del($vnicdb->{'index'}, $vnic);
		delete $vnicdb->{$vnic};
		net_db_obj_set("vnic", $vnicdb);
		
		# delete vpp info
		delete  $vm->{'net'}{$netif}{'vpp'};
		
		# remove vm
		$vmdb->{'index'} = index_del($vmdb->{'index'}, $vm->{'id'}{'name'});
		delete $vmdb->{$vm->{'id'}{'name'}};
		$vmdb->{$vm->{'id'}{'name'}} = $vm;
		net_db_obj_set("vm", $vmdb);
		
		print "[" . date_get() . "] $fid VMDB\n";
		json_encode_pretty($vmdb);
	}
	else{
		# operation failed!
		log_warn($ffid, "failed: interface [ $vm->{'net'}{$netif}{'vpp'}{'interface'}] removal failed");
	}
	
	return $result;
}

#
# initialize tap for vm [JSON-STR]
#
sub vm_tap_init($vm, $netif){
	my $fid = "[vm_tap_init]";
	my $ffid = "VM|TAP|INIT";

	my $netdb = net_db_obj_get("net");
	my $vmdb = net_db_obj_get("vm");
	my $result;

	# check vm tap state
	my $result_tap = vm_tap_check_vm($vm, $netif);
	
	if($result_tap->{'proto'}{'result'} eq "1"){
		$result = packet_build_noencode("0", "error: vm alredy has taps associated!", $fid);
		$result->{'tapresult'} = $result_tap->{'tapdev'};
		$result = json_encode($result);
	}
	else{

		# check if network is known
		if(index_find($netdb->{'index'}, $vm->{'net'}{$netif}{'net'}{'id'})){
			# network is known
			log_info($ffid, "network [$vm->{'net'}{$netif}{'net'}{'id'}] is known");
			
			# add tap device
			my $tap = vm_tap_add_dev($vm, $netif);
	
			# verify tap state
			if($tap->{'tap'}{'state'} eq "1"){
				# added successfully
				log_info($ffid, "success: tap device added!");
				$vm->{'net'}{$netif}{'tap'} = $tap;
				
				# save result
				my $json = packet_build_noencode("1", "success: tap device added", $fid);
				$json->{'vm'} = $vm;
				$result = json_encode($json);
				
				# save vm
				$vmdb->{'index'} = index_add($vmdb->{'index'}, $vm->{'id'}{'name'});
				$vmdb->{$vm->{'id'}{'name'}} = $vm;
				net_db_obj_set("vm", $vmdb);
			}
			else{
				# tap failed
				log_warn($ffid, "error: failed to add tap device!");
				return packet_build_encode("0", "failed: unable to add tap device", $fid);
			}
		}
		else{
			# network is unknown
			log_warn($ffid, "error: network [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] unknown");
			$result = packet_build_encode("0", "failed: network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] unknown!", $fid);
		}
	}

	# return
	if(env_debug()){ json_encode_pretty($vm); };
	return $result;
}

#
# add vm tap device [JSON-OBJ]
#
sub vm_tap_add_dev($vm, $netif){
	my $fid = "[vm_tap_add_dev]";
	my $ffid = "VM|TAP|DEV|ADD";

	my $tapdb = net_db_obj_get("tap");
	my $netdb = net_db_obj_get("net");
	
	# find free tapdev
	my $tapdev = index_free($tapdb->{'index'}, 0);
	
	# build tap	
	my $tap;
	$tap->{'tap'}{'dev'} = $tapdev;
	$tap->{'tap'}{'state'} = "1";
	
	my $netid = $vm->{'net'}{$netif}{'net'}{'id'};
	
	$tap->{'tap'}{'bri'} = $netdb->{$netid}{'bri'}{'brdev'};
	$tap->{'tap'}{'net'} = $vm->{'net'}{$netif}{'net'}{'id'};
	
	$tap->{'vm'}{'id'} = $vm->{'id'}{'id'};
	$tap->{'vm'}{'name'} = $vm->{'id'}{'name'};
	$tap->{'vm'}{'dev'} = $netif;
	
	# packet
	log_info($ffid, "tap [" .  $tap->{'tap'}{'dev'} . "] net id [" . $tap->{'tap'}{'net'} . "]");
	
	# commit tap
	my ($return, $status) = tap_add($tap);
	if(env_debug()){ json_encode_pretty($return); };
	
	# check result
	if($status){
		# success
		$tap->{'tap'}{'state'} = "1";
		$tapdb->{$tapdev} = $tap;
		$tapdb->{'index'} = index_add($tapdb->{'index'}, $tapdev);	
		net_db_obj_set("tap", $tapdb);
	}
	else{
		# failed
		$tap->{'tap'}{'state'} = "0";
		$tap->{'tap'}{'result'} = $return;
	}
	
	return $tap;
}

#
# remove netdev from vm [JSON-OBJ]
#
sub vm_nic_del($vm){
	my $fid = "[vm_nic_del]";
	my $ffid = "VM|NIC|DEL";

	my $result;

	log_info($ffid, "network interfaces [" . $vm->{'net'}{'dev'} . "]");
	my @netifs = index_split($vm->{'net'}{'dev'});
	
	# process interfaces
	foreach my $netif (@netifs){
		
		if(defined $vm->{'net'}{$netif}{'net'}{'type'}){
		
			if($vm->{'net'}{$netif}{'net'}{'type'} eq "dpdk-vpp"){
				# DPDK-VPP
				log_info($ffid, "network interface [$netif] network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] processing as DPDK-VPP");
				$result = vm_vpp_remove($vm, $netif);
				$result->{'vm'} = $vm;
			}
			elsif($vm->{'net'}{$netif}{'net'}{'type'} eq "bri-tap"){
				# TUNTAP
				log_info($ffid, "network interface [$netif] network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] processing as TUNTAP");
				$result = vm_tap_remove($vm, $netif);
				
			}
			else{
				# DEFAULT TUNTAP
				log_info($ffid, "network interface [$netif] network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] processing as TUNTAP (default)");
				$result = vm_tap_remove($vm, $netif);
			}
		}
		else{
			# need to check if network type matches actual network type
			log_info($ffid, "network interface [$netif] network id [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] processing as TUNTAP (legacy)");
			$result = vm_tap_remove($vm, $netif);
		}
		
	}
	
	network_stats();
	network_cdb_sync();
	
	return json_encode($result);
}

#
# remove tap from vm [JSON-STR]
#
sub vm_tap_remove($vm, $netif){
	my $fid = "[vm_tap_remove]";
	my $ffid = "VM|TAP|REMOVE";

	my $netdb = net_db_obj_get("net");
	my $vmdb = net_db_obj_get("vm");
	my $result;

	# check tap status
	my $result_tap = vm_tap_check_vm($vm, $netif);	
	if($result_tap->{'proto'}{'result'} eq "1"){
	
		# check if network is known
		if(index_find($netdb->{'index'}, $vm->{'net'}{$netif}{'net'}{'id'})){
			# network is known
			log_info($ffid, "network [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] known");
			my $netid = $vm->{'net'}{$netif}{'net'}{'id'};
			
			# check if tap belongs to vm
			if(vm_tap_check($vm, $netdb->{$netid}{'bri'}{'brdev'}, $netif)){
				log_info($ffid, "checks sucessful. removing device [$netif] bridge [$netdb->{$netid}{'bri'}{'brdev'}]");
				
				# delete tap device
				if(vm_tap_del_device($vm, $netdb->{$netid}{'bri'}{'brdev'} , $netif)){
					# delete succeeded
					delete $vm->{'net'}{$netif}{'tap'};
					log_info($ffid, "success: tap device removed");
					if(env_debug()){ json_encode_pretty($vm); };
					
					# delete tap data
					delete $vm->{'net'}{$netif}{'tap'};
					
					$result = packet_build_noencode("1", "success: tap device removed", $fid);
					$result->{'vm'} = $vm;
					
					# remove vm
					$vmdb->{'index'} = index_del($vmdb->{'index'}, $vm->{'id'}{'name'});
					delete $vmdb->{$vm->{'id'}{'name'}};
					net_db_obj_set("vm", $vmdb);
				}
				else{
					# delete failed
					log_error($ffid, "failed to remove tap device");
					return packet_build_noencode("0", "error: failed to remove tap devices", $fid);
				}
			}
			else{
				# sanity checks failed
				log_warn($ffid, "checks failed. bailing out");
				return packet_build_noencode("0", "failed: vm and tap devices mismatch", $fid);
			}
		}
		else{
			# network is unknown
			log_warn($ffid, "network [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] unknown");
			$result = packet_build_noencode("0", "failed: network [" . $vm->{'net'}{$netif}{'net'}{'id'} . "] unknown", $fid);
		}
	
	}
	else{
		$result = packet_build_noencode("0", "failed: no taps associated with vm", $fid);
	}

	return $result;
}

#
# delete tap device [BOOLEAN]
#
sub vm_tap_del_device($vm, $brdev, $netif){
	my $fid = "[vm_tap_del_dev]";
	my $ffid = "VM|TAP|DEV|DEL";

	my $tapdb = net_db_obj_get("tap");
	my $result = 0;
	
	# get tap dev
	my $tapdev = vm_tap_get($vm, $brdev, $netif);
	log_info($ffid, "tap device [$tapdev], bridge [$brdev], netdev [$netif]");
	
	# tap
	my $tap;
	$tap->{'tap'}{'dev'} = $tapdev;
	$tap->{'tap'}{'bri'} = $brdev;

	# delete tap
	my $tapdelstatus = tap_del($tap);
	$tapdelstatus = json_decode($tapdelstatus);
	if(env_debug()){ json_encode_pretty($tapdelstatus); };

	# check result
	if($tapdelstatus->{'proto'}{'result'} eq "1"){ $result = 1; }
	else{ $result = 0 };
	
	return $result;
}

#
# get vm tap device [JSON-OBJ]
#
sub vm_tap_get($vm, $bridev, $ethdev){
	my $fid = "[vm_tap_get]";
	my $ffid = "VM|TAP|GET";

	my $tapdb = net_db_obj_get("tap");
	my $result = "";
	
	log_info($ffid, "active taps [" . $tapdb->{'index'} . "]");
	my @tapdevs = index_split($tapdb->{'index'});	
	
	# process devices
	foreach my $tapdev (@tapdevs){
		log_info($ffid, "tap device [$tapdev]");
		
		if($vm->{'id'}{'id'} eq $tapdb->{$tapdev}{'vm'}{'id'}){
			log_info($ffid, "tap [$tapdev] registered to vm id [$vm->{'id'}{'id'}]");

			if($tapdb->{$tapdev}{'tap'}{'bri'} eq $bridev){
				
				if($tapdb->{$tapdev}{'vm'}{'dev'} eq $ethdev){
					log_info($ffid, "ethdev [$ethdev] bridge [$bridev] matches [$tapdb->{$tapdev}{'tap'}{'bri'}]");
					if(env_debug()){ json_encode_pretty($tapdb->{$tapdev}); };
					$result = $tapdb->{$tapdev}{'tap'}{'dev'};
				}
				else{
					log_warn($ffid, "vm and bridge matches, but not [$ethdev]");
				}
			}
			else{
				log_warn($ffid, "bridge [$bridev] does not match [$tapdb->{$tapdev}{'tap'}{'bri'}]");
			}	
		}
		else{
			log_warn($ffid, "vm id does not match tap vm id!");
		}
		
		if(env_debug()){ json_encode_pretty($tapdb->{$tapdev}); };
	}

	return $result;
}

#
# tap sanity checks [BOOLEAN]
#
sub vm_tap_check($vm, $bridev, $ethdev){
	my $fid = "[vm_tap_check]";
	my $ffid = "VM|TAP|CHECK";

	my $tapdb = net_db_obj_get("tap");
	my $result = 0;
	
	# build index
	log_info($ffid, "active taps [" . $tapdb->{'index'} . "]");
	my @tapdevs = index_split($tapdb->{'index'});	
	
	# iterate devices
	foreach my $tapdev (@tapdevs){
		
		if($vm->{'id'}{'id'} eq $tapdb->{$tapdev}{'vm'}{'id'}){
			log_info($ffid, "tap [$tapdev] registered to vm id [" . $vm->{'id'}{'id'} . "]");

			if($tapdb->{$tapdev}{'tap'}{'bri'} eq $bridev){
				log_info($ffid, "bridge [$bridev] matches [" . $tapdb->{$tapdev}{'tap'}{'bri'} . "]");
				$result = 1;
			}
			else{
				log_warn($ffid, "bridge [$bridev] does not match [" . $tapdb->{$tapdev}{'tap'}{'bri'} . "]");
			}		
		}
		else{
			log_warn($ffid, "vm id does not match tap vm id!");
		}
		
	}

	return $result;
}

#
# check if vm known [JSON-OBJ]
#
sub vm_tap_check_vm($vm, $netif){
	my $fid = "[vm_tap_check_vm]";
	my $ffid = "VM|TAP|VM|CHECK";

	my $tapdb = net_db_obj_get("tap");
	my $status = 0;
	my $result;
	
	log_info($ffid, "active tap interfaces [" . $tapdb->{'index'} . "]");
	
	# check index
	if($tapdb->{'index'} || $tapdb->{'index'} eq 0){
	
		# process tap devices
		my @tapdevs = index_split($tapdb->{'index'});
		
		foreach my $tapdev (@tapdevs){
			log_info($ffid, "tap device [$tapdev]");
			if(env_verbose()){ json_encode_pretty( $tapdb->{$tapdev}); };
			
			if($vm->{'id'}{'id'} eq $tapdb->{$tapdev}{'vm'}{'id'}){
				# belongs to self, check name
				
				if($vm->{'id'}{'name'} eq $tapdb->{$tapdev}{'vm'}{'name'}){
					
					# check if nic if is this if
					if($tapdb->{$tapdev}{'vm'}{'dev'} eq $netif){
						# tap is duplicate/stale
						$status = 2;
					}
				}
				else{
					# name mismatch
					log_warn($ffid, "tap [$tapdev] registered to same vm id under different name");
					$status = 3;
				}
			}
		}
	}
	else{
		log_info($ffid, "tap index is empty.");
		$result = packet_build_noencode("1", "warning: no active taps in index", $fid);
	}

	if(!$status){
		# no reservations
		log_info($ffid, "no taps registered.");
		$result = packet_build_noencode("0", "no previous taps registered to vm nic\n", $fid);
	}
	else{
		# previous reservations found
		log_warn($ffid, "previous taps for this VM found.");
		$result = packet_build_noencode("1", "previous taps for this vm found.\n", $fid);
	}

	return $result;
}

1;
