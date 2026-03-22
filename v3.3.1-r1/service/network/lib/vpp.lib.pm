#
# ETHER|AAPEN|NETWORK - LIB|VPP
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
# return vpp state [BOOLEAN]
#
sub vpp_status(){
	my $fid = "[vpp_status]";
	my $ffid = "VPP|STATUS";
	
	my $config = net_db_obj_get("config");
	return $config->{'vpp'}{'state'};
}

#
# check if VPP is enabled and present [BOOLEAN]
#
sub vpp_enabled_OLD(){
	my $fid = "[vpp_enabled]";	
	my $ffid = "VPP|ENABLED";	
	my $config = config_node_network_get();
	my $result = 0;

	# check config
	if(defined $config->{'vpp'}){

		# check enabled
		if($config->{'vpp'}{'enabled'}){
			log_info($ffid, "VPP CONFIGURATION ENABLED");
		
			# check for path
			if(-e $config->{'vpp'}{'bin'}){
				log_info($ffid, "VPP BIN FOUND");
				$result = 1;
			}
			else{
				log_info($ffid, "VPP BIN NOT FOUND!");
			}
		}
		else{
			log_info($ffid, "VPP CONFIGURATION DISABLED");
			json_encode_pretty($config);
		}
		
	}
	else{
		log_info($ffid, "VPP CONFIGURATION NOT FOUND");
	}
	
	return $result;
}

#
# check vpp state [JSON-OBJ]
#
sub vpp_check_state(){
	my $fid = "[vpp_check_state]";
	my $ffid = "VPP|CHECK";

	my $config = net_db_obj_get("config");
	my $netconfig = config_node_network_get();
	
	my $result;

	# check config
	if(defined $netconfig->{'vpp'}){

		# check enabled
		if($netconfig->{'vpp'}{'enabled'}){
			$config->{'vpp'}{'enabled'} = 1;
		
			# check for path
			if(-e $netconfig->{'vpp'}{'bin'}){
				
				# run test command
				my $vppcheck = vpp_cmd("show version");
			
				if($vppcheck =~ "built by root on"){
					log_info($ffid, "success: vpp command check succeeded");
					$result = packet_build_noencode("1", "$fid success. vpp command check succeeded", $fid);
					$config->{'vpp'}{'state'} = 1;
					$config->{'vpp'}{'bin'} = $netconfig->{'vpp'}{'bin'};
				}
				else{
					log_info($ffid, "failed: vpp command check failed");
					$result = packet_build_noencode("0", "$fid failed. vpp command check failed", $fid);
					$config->{'vpp'}{'state'} = 0;
				}
			}
			else{
				log_info($ffid, "failed: vpp enabled but vpp path invalid");
				$result = packet_build_noencode("0", "$fid failed. vpp enabled but vpp path invalid", $fid);
				$config->{'vpp'}{'state'} = 0;
			}
		}
		else{
			log_info($ffid, "failed: vpp not enabled");
			$result = packet_build_noencode("0", "$fid failed. vpp not enabled", $fid);
			$config->{'vpp'}{'state'} = 0;
			$config->{'vpp'}{'enabled'} = 0;
		}
	}
	else{
		log_info($ffid, "failed: vpp not configured");
		$result = packet_build_noencode("0", "$fid failed. vpp not configured", $fid);
		$config->{'vpp'}{'state'} = 0;
		$config->{'vpp'}{'enabled'} = 0;
	}
	
	log_info_json($ffid, "VPP CONFIG STATUS", $config->{'vpp'});
	net_db_obj_set("config", $config);
	return $result;
}

#
# show version [JSON-STR]
#
sub vpp_show_ver(){
	my $fid = "[vpp_show_ver]";
	my $json = packet_build_noencode("1", "success: returning vpp version", $fid);
	$json->{'vpp'} = vpp_cmd("show version");
	return json_encode($json);
}

#
# show version [JSON-STR]
#
sub vpp_show_int(){
	my $fid = "[vpp_show_int]";
	my $json = packet_build_noencode("1", "success: returning vpp interfaces", $fid);
	$json->{'vpp'} = vpp_cmd("show interface");
	return json_encode($json);
}

#
# show version [JSON-STR]
#
sub vpp_del_vnic($request){
	my $fid = "[vpp_del_vnic]";
	my $ffid = "VPP|VNIC|DEL";
	my $vnicdb = net_db_obj_get("vnic");
	my $found = 0;
	my $json;

	my @vnic_index = index_split($vnicdb->{'index'});
	
	foreach my $vnic (@vnic_index){

		if($vnic eq $request->{'vpp'}{'vnic'}){
			$found = 1;
			
			# remove interface
			my $result = vpp_vhost_del($vnicdb->{$vnic}{'interface'});
			
			# basic sanity
			if($result->{'proto'}{'result'} eq "1"){
				log_info($ffid, "success: vnic [$vnic] operation completed");
				$vnicdb->{'index'} = index_del($vnicdb->{'index'}, $vnic);
				delete $vnicdb->{$vnic};
				net_db_obj_set("vnic", $vnicdb);
				
				$json = packet_build_noencode("1", "success: vnic [" . $request->{'vpp'}{'vnic'} . "] removed", $fid);
				$json->{'vppresult'} = $result;
			}
			else{
				# operation failed!
				log_warn($ffid, "error: vnic [$vnic] operation failed");
				$json = packet_build_noencode("0", "error: failed to remove vnic [" . $request->{'vpp'}{'vnic'} . "]", $fid);
				$json->{'vppresult'} = $result;
			}			
		}
	}
		
	if(!$found){
		$json = packet_build_noencode("0", "error: vnic [" . $request->{'vpp'}{'vnic'} . "] not found in index", $fid);
	}

	return json_encode($json);
}


#
# execute vpp commands [STRING]
#
sub vpp_cmd($cmd){
	my $fid = "[vpp_cmd]";
	my $ffid = "VPP|CMD";
	my $config = net_db_obj_get("config");
	my $vppbin = $config->{'vpp'}{'bin'};

	# execute command
	my $exec = $vppbin . " " . $cmd;
	my $result = execute($exec);
	return $result;
}

#
# intialize vpp bridge [JSON-STR]
#
sub vpp_net_init($network){
	my $fid = "[vpp_net_init]";
	my $ffid = "VPP|NET|INIT";

	my $netdb = net_db_obj_get("net");
	my $id = config_node_id_get();
	my $vppdb = net_db_obj_get("vpp");
	my $result;
	my $exec;
	
	log_info($ffid, "interface [$network->{'node'}{$id}] bridge type [$network->{'vpp'}{'bridge-type'}] id [$network->{'vpp'}{'bridge'}] tag [$network->{'vpp'}{'tag'}] type [$network->{'vpp'}{'tag-type'}]");
	
	if(vpp_bridge_check($network)){
		log_warn($ffid, "error: bridge [$network->{'vpp'}{'bridge'}] already exists. skipping init.");
		
		if(index_find($vppdb->{'index'}, $network->{'id'}{'name'})){
			log_warn($ffid, "error: bridge [$network->{'vpp'}{'bridge'}] already exists. skipping init.");
			$network = vpp_bridge_int_stats($network);
			
			$vppdb->{'index'} = index_add($vppdb->{'index'}, $network->{'id'}{'name'});
			$vppdb->{$network->{'id'}{'name'}} = $network;
			net_db_obj_set("vpp", $vppdb);
		}
		else{
			log_warn($ffid, "bridge [$network->{'vpp'}{'bridge'}] is unkonwn");
			$network = vpp_bridge_int_stats($network);
			
			$vppdb->{'index'} = index_add($vppdb->{'index'}, $network->{'id'}{'name'});
			$vppdb->{$network->{'id'}{'name'}} = $network;
			net_db_obj_set("vpp", $vppdb);
		}
	}
	else{
		log_info($ffid, "bridge [$network->{'vpp'}{'bridge'}] does not exist. initializing...");
		vpp_bridge_l2_init($network);
		$network = vpp_bridge_int_stats($network);
		$vppdb->{'index'} = index_add($vppdb->{'index'}, $network->{'id'}{'name'});
		$vppdb->{$network->{'id'}{'name'}} = $network;
		net_db_obj_set("vpp", $vppdb);
	}

	return packet_build_encode("1", "$fid vpp network init completed", $fid);
}

#
# initialize l2 bridge [NULL]
#
sub vpp_bridge_l2_init($network){
	my $fid = "[vpp_bridge_l2_init]";
	my $ffid = "VPP|BRIDGE|L2INIT";

	my $vppdb = net_db_obj_get("vpp");
	my $id = config_node_id_get();
	my $success = 1;
	my $exec;	
	
	# mtu
	my $mtucmd = "set interface mtu " . $network->{'vpp'}{'mtu'} . " " . $network->{'node'}{$id};
	log_debug($ffid, "mtu exec [$mtucmd]");
	my $mtustat = vpp_cmd($mtucmd);
	$mtustat = string_strip($mtustat);
	log_debug($ffid, "mtu exec result [$mtustat]");
	if($mtustat){ $success = 0 };
	
	# state
	my $statecmd = "set interface state " . $network->{'node'}{$id} . " up";
	log_debug($ffid, "state exec result [$statecmd]");
	my $statestat = vpp_cmd($statecmd);
	$statestat = string_strip($statestat);
	log_debug($ffid, "state exec result [$statestat]");
	if($statestat){ $success = 0 };
	
	# sub interface
	my $subcmd = "create sub " . $network->{'node'}{$id} . " " . $network->{'vpp'}{'bridge'};
	my $subint = $network->{'node'}{$id} . "." . $network->{'vpp'}{'bridge'};
	log_debug($ffid, "sub interface init exec [$subcmd]");
	my $substat = vpp_cmd($subcmd);
	$substat = string_strip($substat);
	log_debug($ffid, "sub interface init result [$substat]");
	if($substat){ $success = 0 };
	
	# bring up subint
	my $substatcmd = "set interface state " . $subint . " up";
	log_debug($ffid, "sub interface state result [$substatcmd]");
	my $substatestat = vpp_cmd($substatcmd);
	$substatestat = string_strip($substatestat);
	log_debug($ffid, "sub interface state result [$substatestat]");
	if($substatestat){ $success = 0 };
	
	# add subint to bridge
	my $bricmd = "set interface l2 bridge " . $subint . " " . $network->{'vpp'}{'bridge'};
	log_debug($ffid, "sub interface bridge exec [$bricmd]");
	my $bristat = vpp_cmd($bricmd);
	$bristat = string_strip($bristat);
	log_debug($ffid, "sub interface bridge result [$bristat]");
	if($bristat){ $success = 0 };
	
	
	if($success){
		log_info($ffid, "success: created l2 bridge  [$subint] on [$network->{'vpp'}{'bridge'}] successfully");
	}
	else{
		log_info($ffid, "failed: creating l2 bridge  [$subint] on [$network->{'vpp'}{'bridge'}] failed");
	}
	
}						

#
# check for bridge [BOOLEAN]
#
sub vpp_bridge_check($network){
	my $fid = "[vpp_bridge_check]";
	my $ffid = "VPP|BRIDGE|CHECK";

	my $result = 0;
	
	# check bridge status
	my $cmd = "show bridge " . $network->{'vpp'}{'bridge'};
	my $britmp = vpp_cmd($cmd);
	my $bricheck = "show bridge-domain: No such bridge domain " . $network->{'vpp'}{'bridge'};
	my $bristate = string_strip($britmp);

	if($bristate eq $bricheck){
		log_info($ffid, "bridge [$network->{'vpp'}{'bridge'}] does not exist. result [$bristate]");
		$result = 0;
	}
	else{
		log_info($ffid, "bridge [$network->{'vpp'}{'bridge'}] already exist! result [$bristate]");
		vpp_bridge_int_check($network);
		$result = 1;
	}
	
	return $result;
}

#
# check for interface on bridge [BOOLEAN]
#
sub vpp_bridge_int_check($network){
	my $fid = "[vpp_bridge_int_check]";
	my $ffid = "VPP|BRIDGE|INT|CHECK";

	my $id = config_node_id_get();
	my $result = 0;
	
	# check bridge status
	my $cmd = "show bridge " . $network->{'vpp'}{'bridge'} . " int";
	my $bristate = vpp_cmd($cmd);
	
	my $subint = $network->{'node'}{$id} . "." . $network->{'vpp'}{'bridge'};
	
	if($bristate =~ $subint){
		log_info($ffid, "interface [$subint] found on bridge [$network->{'vpp'}{'bridge'}]");
		$result = 0;
	}
	else{
		log_info($ffid, "interface [$subint] not found on bridge [$network->{'vpp'}{'bridge'}]");
		$result = 1;
	}
	
	return $result;
}

#
# check for interface on bridge [BOOLEAN]
#
sub vpp_bridge_int_stats($network){
	my $fid = "[vpp_bridge_int_stats]";
	my $ffid = "VPP|BRIDGE|INT|STATS";

	my $id = config_node_id_get();
	my $result = 0;
	
	# state
	my $statecmd = "show interface " . $network->{'node'}{$id} . "." . $network->{'vpp'}{'tag'};
	my $statestat = vpp_cmd($statecmd);	
	
	my @line = split /\n/, $statestat;
	my $i = 0;
	
	# init defaults
	$network->{'stats'}{'interface'} = "N/A";
	$network->{'stats'}{'if_idx'} = "N/A";
	$network->{'stats'}{'if_state'} = "N/A";
	$network->{'stats'}{'if_mtu'} = "N/A";
	
	$network->{'stats'}{'rx'}{'packets'} = "N/A";
	$network->{'stats'}{'rx'}{'bytes'} = "N/A";
	$network->{'stats'}{'rx'}{'data'} = "N/A";
	
	$network->{'stats'}{'tx'}{'packets'} = "N/A";
	$network->{'stats'}{'tx'}{'bytes'} = "N/A";
	$network->{'stats'}{'tx'}{'data'} = "N/A";
	
	$network->{'stats'}{'drops'} = "N/A";
			
	foreach my $ln (@line){
		my $j = 0;
		
		my @str = split /\s+/, $ln;
		
		if(defined ($str[4]) && ($str[4] eq "rx") && ($str[5] eq "packets")){
			$network->{'stats'}{'interface'} = $str[0];
			$network->{'stats'}{'if_idx'} = $str[1];
			$network->{'stats'}{'if_state'} = $str[2];
			$network->{'stats'}{'if_mtu'} = $str[3];
			$network->{'stats'}{'rx'}{'packets'} = $str[6];
		}

		if(($str[1] eq "rx") && ($str[2] eq "bytes")){
			$network->{'stats'}{'rx'}{'bytes'} = $str[3];
			$network->{'stats'}{'rx'}{'data'} = format_bytes($network->{'stats'}{'rx'}{'bytes'});
		}

		if(($str[1] eq "tx") && ($str[2] eq "packets")){
			$network->{'stats'}{'tx'}{'packets'} = $str[3];
		}

		if(($str[1] eq "tx") && ($str[2] eq "bytes")){
			$network->{'stats'}{'tx'}{'bytes'} = $str[3];
			$network->{'stats'}{'tx'}{'data'} = format_bytes($network->{'stats'}{'tx'}{'bytes'});
		}

		if(($str[1] eq "drops")){
			$network->{'stats'}{'drops'} = $str[2];
		}
	
		$i++;
			
	}
	
	return $network;
}

#
# check for interface on bridge [BOOLEAN]
#
sub vpp_vnic_stats($vnic){
	my $fid = "[vpp_vnic_stats]";
	my $ffid = "VPP|VNIC|STATS";

	my $id = config_node_id_get();
	my $result = 0;

	# check bridge status
	my $cmd = "show interface " . $vnic->{'interface'};
	my $vnicstat = vpp_cmd($cmd);
	
	if($vnicstat =~ "show interface: unknown input"){
		# invalid
		log_warn($ffid, "error: unknown interface [" . $vnic->{'interface'} . "]");
		$vnic->{'valid'} = "0";
	}
	else{
		# valid
		my @line = split /\n/, $vnicstat;
		
		# init
		$vnic->{'valid'} = "1";
		$vnic->{'idx'} = "N/A";
		$vnic->{'state'} = "N/A";
		$vnic->{'mtu'} = "N/A";
		$vnic->{'rx'}{'packets'} = "N/A";
		$vnic->{'rx'}{'bytes'} = "N/A";
		$vnic->{'rx'}{'data'} = "N/A";
		
		$vnic->{'tx'}{'packets'} = "N/A";
		$vnic->{'tx'}{'bytes'} = "N/A";
		$vnic->{'tx'}{'data'} = "N/A";
		$vnic->{'tx'}{'errors'} = "N/A";
		$vnic->{'drops'} = "N/A";
		
		# parse vnic data
		my $i = 0;
		
		foreach my $ln (@line){
			my $j = 0;
			
			my @str = split /\s+/, $ln;
			
			if($i == 1 && ($str[5] eq "packets")){
				$vnic->{'idx'} = $str[1];
				$vnic->{'state'} = $str[2];
				$vnic->{'mtu'} = $str[3];
				$vnic->{'rx'}{'packets'} = $str[6];
			}

			if($i == 2 && ($str[2] eq "bytes")){
				$vnic->{'rx'}{'bytes'} = $str[3];
				$vnic->{'rx'}{'data'} = format_bytes($vnic->{'rx'}{'bytes'});
			}

			if($i == 3 && ($str[2] eq "packets")){
				$vnic->{'tx'}{'packets'} = $str[3];
			}

			if($i == 4 && ($str[2] eq "bytes")){
				$vnic->{'tx'}{'bytes'} = $str[3];
				$vnic->{'tx'}{'data'} = format_bytes($vnic->{'tx'}{'bytes'});
			}

			if($i == 5 && ($str[1] eq "drops")){
				$vnic->{'drops'} = $str[2];
			}

			if($i == 6 && ($str[1] eq "tx-error")){
				$vnic->{'tx'}{'errors'} = $str[2];
			}		#	
				
			$i++;
				
		}
	}
	
	return $vnic;
}

#
# add vpp vhost adapter [JSON-OBJ]
#
sub vpp_vhost_add($vsock, $mtu, $bridge){
	my $fid = "[vpp_vhost_init]";
	my $ffid = "VPP|VHOST|ADD";	

	my $id = config_node_id_get();
	my $result = 0;
	
	# cretate interface
	my $exec = "create vhost-user socket " . $vsock . " server";
	my $vhoststate = vpp_cmd($exec);
	$vhoststate = string_strip($vhoststate);
	
	if($vhoststate =~ "VirtualEthernet"){
		# success
		my $vhostint = $vhoststate;
		log_info($ffid, "success. bringing up [$vhostint]");
		
		# set mtu - not relevant in new VPP version
		#my $mtucmd = "set interface mtu " . $mtu . " " . $vhostint;
		#my $mtustate = vpp_cmd($mtucmd);
		#$mtustate = string_strip($mtustate);
		my $mtustate = "";
		
		# check mtu
		if($mtustate eq ""){
			
			# set state
			my $upcmd = "set interface state " . $vhostint . " up";
			my $upstate = vpp_cmd($upcmd);
			$upstate = string_strip($upstate);
			
			if($upstate eq ""){
			
				# add to bridge
				my $bricmd = "set interface l2 bridge " . $vhostint . " " . $bridge;
				my $bristate = vpp_cmd($bricmd);
				$bristate = string_strip($bristate);
				
				if($bristate eq ""){
	
					# add tagging
					my $tagcmd = "set interface l2 tag-rewrite " . $vhostint . " push dot1q " . $bridge;
					my $tagstate = vpp_cmd($tagcmd);
					$tagstate = string_strip($tagstate);
					
					if($tagstate eq ""){
						# success!
						log_info($ffid, "interface [$vhostint] brought up successfully");
						$result = packet_build_noencode("1", "sucess. socket [$vsock] interface [$vhostint] bridge [$bridge]", $fid);
						$result->{'vpp'}{'socket'} = $vsock;
						$result->{'vpp'}{'interface'} = $vhostint;
						$result->{'vpp'}{'bridge'} = $bridge;
						$result->{'vpp'}{'mtu'} = $mtu;
						
						# save interface to db
						#net_db_obj_set("vnic", $vnicdb);
					}
					else{
						# failed to define tagging
						log_warn($ffid, "interface [$vhostint] 8021q tagging failed! error: [$tagstate]");
						$result = packet_build_noencode("0", "8021q tagging failed! error: [$tagstate]", $fid);
					}
				}
				else{
					# failed to add to bridge
					log_warn($ffid, "interface [$vhostint] failed bind int to bridge! error: [$bristate]");
					$result = packet_build_noencode("0", "failed bind int to bridge. error: [$bristate]", $fid);							
				}
			}
			else{
				# failed to bring int up
				log_warn($ffid, "interface [$vhostint] failed to bring int up! error: [$upstate]");
				$result = packet_build_noencode("0", "failed to bring int up. error: [$upstate]", $fid);	
			}
		}
		else{
			# mtu set failed!
			log_warn($ffid, "interface [$vhostint] failed to set mtu! error: [$mtustate]");
			$result = packet_build_noencode("0", "failed to set mtu! error: [$mtustate]", $fid);	
		}
		
	}
	else{
		# failed to create interface
		log_warn($ffid, "error: failed to create interface! error: [$vhoststate]");
		$result = packet_build_noencode("0", "failed to create interface. error: [$vhoststate]", $fid);	
	}
	
	return $result;
}

#
# check for interface on bridge [JSON-OBJ]
#
sub vpp_vhost_del($vint){
	my $fid = "[vpp_vhost_del]";
	my $ffid = "VPP|VHOST|DEL";	

	my $id = config_node_id_get();
	my $result = 0;
	
	my $exec = "delete vhost-user " . $vint;
	my $vhoststate = vpp_cmd($exec);
	chomp($vhoststate);
	
	if($vhoststate =~ "delete vhost-user: unknown input"){
		# fail
		log_warn($ffid, "failed to remove interface! error: [$vhoststate]");
		$result = packet_build_noencode("0", "failed to remove interface. error: [$vhoststate]", $fid);
	}
	else{
		# success
		log_info($ffid, "successfully removed interface [$vint]");
		$result = packet_build_noencode("1", "successfully removed interface [$vint]", $fid);
	}
	
	return $result;
}

#
# return bridge data [JSON-OBJ]
#
sub vpp_info(){
	my $vppdb = net_db_obj_get("vpp");
	return $vppdb;
}

#
# return bridge data [JSON-OBJ]
#
sub vnet_info(){
	my $vnetdb = net_db_obj_get("vnic");
	return $vnetdb;
}

#
# return bridge metadata [JSON-STR]
#
sub vpp_meta(){
	my $vppdb = net_db_obj_get("vpp");
	return $vppdb->{'index'};
}

#
# return bridge metadata [JSON-STR]
#
sub vnet_meta(){
	my $vnetdb = net_db_obj_get("vnic");
	return $vnetdb->{'index'};
}

#
# return bridge metadata [JSON-STR]
#
sub vm_meta(){
	my $vmdb = net_db_obj_get("vm");
	return $vmdb->{'index'};
}

1;
