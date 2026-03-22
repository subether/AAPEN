#
# ETHER|AAPEN|NETWORK - LIB|NET
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
# check network status [NULL]
#
sub net_check_status(){
	my $fid = "[net_check_status]";
	my $ffid = "NET|STATUS";
	my $netdb = net_db_get();

	if((defined $netdb->{'vnic'}{'index'}) && ($netdb->{'vnic'}{'index'} ne "")){

		my @vnic_index = index_split($netdb->{'vnic'}{'index'});

		foreach my $vnic (@vnic_index){
			print "[" . date_get() . "]$fid vnic [$vnic]\n";
			
			my $vnicstats = vpp_vnic_stats($netdb->{'vnic'}{$vnic});
			
			if($vnicstats->{'valid'} eq "1"){
				# vnic is valid
				print "[" . date_get() . "]$fid vnic is valid!\n";
				log_info($fid, "vnic [$vnic] is valid");
			}
			else{
				# vnic is invalid
				print "[" . date_get() . "]$fid vnic is invalid!\n";
				log_info($fid, "vnic [$vnic] is invalid. cleaning up.");
				
				# clean up vnic
				my @vnic_index = index_del($netdb->{'vnic'}{'index'}, $vnic);
				delete $netdb->{'vnic'}{$vnic};
			}
		}
		
		net_db_set($netdb);
	}
}

#
# network meta [JSON-OBJ]
#
sub net_meta(){
	my $fid = "NET|META";
	my $netdb = net_db_obj_get("net");
	if(env_verbose()){ 
		print "$fid network database\n";
		json_encode_pretty($netdb); 
	};
	
	return $netdb->{'index'};
}

#
# push network to node [JSON-STR]
#
sub net_push($network){
	my $fid = "[net_push]";
	my $ffid = "NET|PUSH";
	my $netdb = net_db_obj_get("net");
	my $result;
	
	# check network state
	if(index_find($netdb->{'index'}, $network->{'id'}{'id'})){
		# network is known
		log_info($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] is known. checking state.");
	
		if($netdb->{$network->{'id'}{'id'}}{'meta'}{'lock'}){
			# network is locked
			log_warn($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] is locked. cannot modify.");
			$result = packet_build_encode("error", "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] is locked. cannot modify.", $fid);	
		}
		else{
			# network is unlocked
			log_info($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] unlocked. initializing..");
			$result = net_init($network);
		}
	}
	else{
		# network is unknown
		log_info($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] is unknown. initializing..");

		# add to database
		$netdb->{$network->{'id'}{'id'}} = $network;
		$netdb->{'index'} = index_add($netdb->{'index'}, $network->{'id'}{'id'});
		$netdb->{'index_name'} = index_add($netdb->{'index_name'}, $network->{'id'}{'name'});
		
		# initialize network
		$result = net_init($network);
		
		# TODO: BETTER LOCKING
		$netdb->{$network->{'id'}{'id'}}{'meta'}{'lock'} = 1;
		
		# save and return
		net_db_obj_set("net", $netdb);
	}
	
	my $action = json_decode($result);
	if($action->{'proto'}{'result'} eq "0"){
		log_warn($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] init failed!");
		delete $netdb->{$network->{'id'}{'id'}};
		$netdb->{'index'} = index_del($netdb->{'index'}, $network->{'id'}{'id'});
		$netdb->{'index_name'} = index_del($netdb->{'index_name'}, $network->{'id'}{'name'});
		net_db_obj_set("net", $netdb);
	}
	
	# check for result	
	if(!$result){
		log_warn($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] operation failed!");
		$result = packet_build_encode("1", "$fid operation failed", $fid);
	}

	return $result;
}

#
# initialize network [JSON-STR]
#
sub net_init($network){
	my $fid = "[net_init]";
	my $ffid = "NET|INIT";

	my $id = config_node_id_get();
	my $name = config_node_name_get();
	my $result;
	
	# check for network
	if(index_find($network->{'node'}{'index'}, $id)){

		#
		# vlan
		#
		if($network->{'meta'}{'type'} eq "vlan"){
			log_info($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] device [$network->{'node'}{$id}] network is VLAN");
			$result = bri_add($network);
		}
		
		#
		# trunk
		#
		if($network->{'meta'}{'type'} eq "trunk"){
			log_info($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] device [$network->{'node'}{$id}] network is TRUNK");
			$result = bri_add($network);
		}
		
		#
		# vpp
		#
		if($network->{'meta'}{'type'} eq "vpp"){
			log_info($ffid, "network id [$network->{'id'}{'id'}] name [$network->{'id'}{'name'}] device [$network->{'node'}{$id}] network is VPP");
			if(vpp_status()){
				$result = vpp_net_init($network);
			}
			else{
				$result = packet_build_encode("0", "$fid vpp not active", $fid);
			}
		}
	}
	else{
		# self missing
		log_warn($ffid, "error: no network device configured!");
		$result = packet_build_encode("0", "$fid no network device configured!", $fid);
	}
	
	return $result;
}

#
# pull network [JSON-STR] 
# TODO: not very useful post REST 
#
sub net_pull($netid){
	my $fid = "[net_pull]";
	my $ffid = "NET|PULL";
	
	my $id = config_node_id_get();
	my $name = config_node_name_get();
	
	my $netdb = net_db_obj_get("net");
	my $result;
	
	print "[" . date_get() . "] $fid network in index [" . $netdb->{'index'} . "]\n";
	if(env_debug()){ json_encode_pretty($netdb); };
	
	if(index_find($netdb->{'index'}, $netid)){
		log_info($ffid, "network in index [$netdb->{'index'}] - object is known");
		$result = packet_build_noencode("1", "$fid success. returning network", $fid);
		$result->{'net'} = $netdb->{$netid};
	}
	else{
		log_info($ffid, "network in index [$netdb->{'index'}] - object is unknown");
		$result = packet_build_noencode("0", "$fid unknown network id!", $fid);
	}

	return json_encode($result);
}

#
# find net by id [BOOLEAN]
#
sub net_check_id($netid){
	my $fid = "[net_check_id]";
	my $ffid = "NET|CHECK|ID";

	my $netdb = net_db_get();
	my $result;
	
	# check if network in db
	if(index_find($netdb->{'net'}{'index'}, $netid)){
		# the network is known

		# check network lock state
		if($netdb->{'net'}{$netid}->{'meta'}{'lock'}){
			# network marked active
			log_info($ffid, "network id [$netid] is active");
			$result = 1;
		}
		else{
			# network is known, but inactive
			log_info($ffid, "network id [$netid] is inactive");
			$result = 2;
		}
	}
	else{
		# network id is unknown
		log_info($ffid, "network id [$netid] is unknown");
		$result = 0;
	}
	
	return $result;
}

#
# find net by name [BOOLEAN]
#
sub net_check_name($netname){
	my $fid = "[net_check_name]";
	my $ffid = "NET|CHECK|NAME";

	my $netdb = net_db_get();
	my $result = 0;
	
	my @netlist = index_split($netdb->{'net'}{'index'});
	
	foreach my $netid (@netlist){
		if($netdb->{'net'}{$netid}{'id'}{'name'} eq $netname){
			$result = 1;
		}
	}

	return $result;
}

#
# find net by name [BOOLEAN]
#
sub net_get_id_from_name($netname){
	my $fid = "[net_get_id_from_name]";

	my $netdb = net_db_get();
	my $result = 0;
	
	my @netlist = index_split($netdb->{'net'}{'index'});
	
	foreach my $netid (@netlist){
		if($netdb->{'net'}{$netid}{'id'}{'name'} eq $netname){
			$result = $netid;
		}
	}

	return $result;
}

#
# return network data [JSON-STR]
#
sub net_info(){
	my $fid = "[net_info]";
	my $netdb = net_db_obj_get("net");
	return $netdb;
}

1;
