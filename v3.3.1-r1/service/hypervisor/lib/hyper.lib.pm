#
# ETHER|AAPEN|HYPERVISOR - LIB|HYPER
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
use Errno qw(ESRCH);


#
# hypervisor info [JSON-STR]
#
sub hyper_info(){
	my $fid = "hypervisor_hyper_info";
	my $ffid = "HYPERVISOR|INFO";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $confdb = hyper_db_obj_get("config");
	my $hwdb = hyper_db_obj_get("hw");
	
	my $packet;
	$packet->{'hyper'} = $hyperdb->{'vm'};
	$packet->{'net'} = $hyperdb->{'net'};
	$packet->{'stats'} = $hyperdb->{'stats'};
	$packet->{'qemu'} = $hyperdb->{'qemu'};
	$packet->{'config'} = $confdb;
	$packet->{'hw'} = $hwdb;
	
	return json_encode($packet);
}

#
# push vm to hypervisor [JSON-STR]
#
sub hyper_push($json){
	my $fid = "hypervisor_hyper_push";
	my $ffid = "HYPERVISOR|PUSH";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $return;
	my $status = 0;

	# conservative validation: check required fields
	unless ($json && $json->{'hyper'} && $json->{'hyper'}{'vm'} && 
	        $json->{'hyper'}{'vm'}{'id'} && $json->{'hyper'}{'vm'}{'id'}{'id'}) {
		log_error($ffid, "invalid vm data structure received");
		return packet_build_encode("0", "error: invalid vm data structure", $ffid);
	}

	my $vm_id = $json->{'hyper'}{'vm'}{'id'}{'id'};
	my $vm_name = $json->{'hyper'}{'vm'}{'id'}{'name'} || 'unknown';
	
	# conservative validation: basic ID validation
	unless ($vm_id =~ /^[a-zA-Z0-9\-_\.]+$/) {
		log_error($ffid, "invalid vm id format: $vm_id");
		return packet_build_encode("0", "error: invalid vm id format", $ffid);
	}

	# enhanced validation: comprehensive VM structure validation
	my $validation = hyper_validate_vm_structure($json->{'hyper'}{'vm'});
	unless ($validation->{valid}) {
		log_error($ffid, "VM structure validation failed: " . 
		         join(", ", @{$validation->{errors}}));
		return packet_build_encode("0", "error: invalid vm structure: " . 
		         join(", ", @{$validation->{errors}}), $ffid);
	}
	
	if (@{$validation->{warnings}}) {
		log_warn($ffid, "VM structure validation warnings: " . 
		        join(", ", @{$validation->{warnings}}));
	}

	log_info($ffid, "received vm id [$vm_id] name [$vm_name] data");
	log_debug_json($ffid, "verbose vm data details", $json);

	# check if vm is known
	if(index_find($hyperdb->{'vm'}{'index'}, $vm_id)){
		
		# check if vm is locked
		if(!index_find($hyperdb->{'vm'}{'lock'}, $vm_id)){
				
			# cache system id
			my $id = $vm_id;
			log_info($ffid, "system id [$id]. updating database");
			$hyperdb->{'db'}{$id} = $json->{'hyper'}{'vm'};
						
			# result
			$return = "$ffid success: vm data updated";
			$status = 1;
		}
		else{
			# vm is locked	
			$return = "error: vm is locked. cannot modify.";
			$status = 0;
		}
	}
	else{
		# vm is unknown, add to database
		my $id = $vm_id;
		log_info($ffid, "vm id [$id] is unknown. saving dataset");
		log_info_json($ffid, "new vm dataset", $json->{'hyper'}{'vm'});

		# save vm data
		$hyperdb->{'db'}{$id} = $json->{'hyper'}{'vm'};
		$hyperdb->{'vm'}{'index'} = index_add($hyperdb->{'vm'}{'index'}, $id);
		
		# result
		$return = "$ffid success: added vm to db";
		$status = 1;
	}
	
	log_info($ffid, "saving database");
	hyper_db_obj_set("hyper", $hyperdb);
	
	return packet_build_encode($status, $return, $ffid);
}

#
# hypervisor system meta migrate [JSON-STR]
#
sub hyper_system_meta_migrate($sysmeta){
	my $fid = "hypervisor_hyper_system_meta_migrate";
	my $ffid = "HYPERVISOR|SYSTEM|META|MIGRATE";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $return;
	my $status = 0;

	# Validate system metadata structure
	unless ($sysmeta && $sysmeta->{'hyper'} && $sysmeta->{'hyper'}{'stats'}) {
		log_error($ffid, "invalid system metadata structure received");
		return packet_build_encode("0", "error: invalid system metadata structure", $ffid);
	}
	
	my $stats = $sysmeta->{'hyper'}{'stats'};
	my $sys_id = $stats->{'id'}{'id'} || 'unknown';
	
	# validate stats structure
	unless ($sys_id && $sys_id ne 'unknown') {
		log_error($ffid, "invalid system ID in metadata");
		return packet_build_encode("0", "error: invalid system ID in metadata", $ffid);
	}

	log_info($ffid, "received updated metadata for system migration");
	log_info_json($ffid, "incoming system metadata", $sysmeta);
	
	$return = "$ffid success: vm metadata updated";
	$status = 1;
		
	log_debug_json($ffid, "verbose system metadata details", $sysmeta);
	
	$stats = $sysmeta->{'hyper'}{'stats'};
	$sys_id = $stats->{'id'}{'id'};
	
	log_info($ffid, "system meta pre-merge for system ID: $sys_id");
	log_debug_json($ffid, "current hypervisor stats before merge", $hyperdb->{'stats'}{$sys_id});
	
	$hyperdb->{'stats'}{$sys_id} =  $stats;
	hyper_system_cdb_meta_set($sys_id, $stats);
	
	log_info($ffid, "system meta post-merge for system ID: $sys_id");
	log_debug_json($ffid, "updated hypervisor stats after merge", $hyperdb->{'stats'}{$sys_id});
	
	$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $sys_id);
	$hyperdb->{'vm'}{'async'}{$sys_id} = $hyperdb->{'async'};
	
	$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'state'} = "0";
	$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'status'} = "completed";
	
	$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $sys_id);
		
	$hyperdb->{'vm'}{'async'}{$sys_id}{'date'} = date_get();
	$hyperdb->{'vm'}{'async'}{$sys_id}{'timeout'} = "3600";
	$hyperdb->{'vm'}{'async'}{$sys_id}{'on_timeout'} = "wait";
	$hyperdb->{'vm'}{'async'}{$sys_id}{'status'} = "system migration completed";
	$hyperdb->{'vm'}{'async'}{$sys_id}{'active'} = "0";
	$hyperdb->{'vm'}{'async'}{$sys_id}{'request'} = "migrate";
	$hyperdb->{'vm'}{'async'}{$sys_id}{'result'} = "migraton successful";
	$hyperdb->{'vm'}{'async'}{$sys_id}{'id'} = $sys_id;
	
	$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'end_time'} = date_get();
	
	hyper_db_obj_set("hyper", $hyperdb);

	my $system = $hyperdb->{'db'}{$sys_id};
	
	$stats = $hyperdb->{'stats'}{$sys_id};
	$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$sys_id};
	$stats->{'updated'} = date_get();
	
	hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	

	log_info($ffid, "system metadata update completed for system: $sys_id");
	return packet_build_encode($status, $return, $ffid);
}

#
# pull vmm info from hypervisor [JSON-STR]
#
sub hyper_pull($json){
	my $fid = "[hyper_pull]";
	my $ffid = "HYPER|PULL";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;
	
	log_info($ffid, "vm id [$json->{'hyper'}{'id'}]");
	
	# check if vm in db
	if(index_find($hyperdb->{'vm'}{'index'}, $json->{'hyper'}{'id'})){
		$result = packet_build_noencode("1", "success: returning vm data", $fid);
		$result->{'request'} = $json;
		$result->{'vm'} = $hyperdb->{'db'}{$json->{'hyper'}{'id'}};
	}
	else{
		# vm not in db
		log_warn($ffid, "warning: vm [$json->{'hyper'}{'id'}] not in db");
		$result = packet_build_noencode("0", "error: unknown vm id", $fid);
		$result->{'request'} = $json;
	}
	
	hyper_db_obj_set("hyper", $hyperdb);
	return json_encode($result);
}

#
# get hypervisor db [JSON-STR]
#
sub hyper_getdb(){
	my $fid = "[hyper_getdb]";
	my $hyperdb = hyper_db_obj_get("hyper");
	return $hyperdb;
}

#
#  hypervisor vm load [JSON-STR]
#
sub hyper_load($json){
	my $fid = "[hyper_load]";
	my $ffid = "HYPER|LOAD";
	my ($result, $response, $netresp, $frameresp);
	my $hyperdb = hyper_db_obj_get("hyper");
	my $id = $json->{'hyper'}{'id'};
	my $status = 0;

	# validate operation preconditions
	my $preconditions = hyper_validate_operation_preconditions("LOAD", $id, "unlocked");
	unless ($preconditions->{valid}) {
		log_error($ffid, "Load operation preconditions failed: " . 
		         join(", ", @{$preconditions->{errors}}));
		return packet_build_encode("0", "error: preconditions not met for load: " . 
		         join(", ", @{$preconditions->{errors}}), $ffid);
	}

	my $frameresult = api_framework_local_ping(env_serv_sock_get("framework"));
	my $netresult = api_network_local_ping(env_serv_sock_get("network"));

	# continue on success
	if(($frameresult->{'proto'}{'result'} eq "1") && ($netresult->{'proto'}{'result'} eq "1")){
		log_info($ffid, "framework and network responded. continuing.. hyperdb index: [$hyperdb->{'vm'}{'index'}], id [$json->{'hyper'}{'id'}]");
		
		# check if VM in db
		if(index_find($hyperdb->{'vm'}{'index'}, $json->{'hyper'}{'id'})){
			# vm is in db
			
			# extract vm from db
			my $vm = $hyperdb->{'db'}{$json->{'hyper'}{'id'}};	
			
			# check hypervisor limits
			hyper_limits_check($vm);

			# check if vm is locked
			if(!index_find($hyperdb->{'vm'}{'lock'}, $json->{'hyper'}{'id'})){
			
				# check system state
				if((!$vm->{'meta'}{'vmm'}{'state'} || $vm->{'meta'}{'migrate'}) || !index_find($hyperdb->{'vm'}{'lock'}, $json->{'hyper'}{'id'})){
					
					# network calls
					log_info($ffid, "executing network calls");
					my $netstatus = api_network_local_vm_nic_add(env_serv_sock_get("network"), $vm);
					
					if(env_verbose()){ json_encode_pretty($netstatus); };
					
					if($netstatus->{'proto'}{'result'} eq "1"){
						# update vm data
						$vm = $netstatus->{'vm'};
						
						# network init completed
						log_info($ffid, "network init completed");
						if(env_verbose()){ json_encode_pretty($vm); };

						# load vmm
						my $vmmresult = hyper_load_vmm($hyperdb, $vm);
						
						if(env_verbose()){
							log_info($ffid, "hypervisor vmm load result");
							json_encode_pretty($vmmresult);
						}
						
						if($vmmresult->{'proto'}{'result'} eq "1"){
							# vmm spawn successful
							log_info($ffid, "successful vmm spawn");
							
							# update vm status
							$vmmresult->{'vm'}{'state'}{'vm_status'} = "init";
							
							# update cluster
							hyper_cdb_system_sync($vmmresult->{'vm'});

							# update result
							$result = $vmmresult;
							$result = json_encode($result);		
						}
						else{
							# vmm spawn failed
							log_warn($ffid, "error: failed to spawn vmm container!");
							$result = packet_build_noencode("0", "error: failed to spawn vmm container", $fid);
							$result->{'vmmstatus'} = $vmmresult;
							
							# cleanup networking
							my $netstatus = hyper_net_nic_del($vm);
							$result->{'netstatus'} = $netstatus;
							json_encode_pretty($vmmresult);
							$result = json_encode($result);
						}
					}
					else{
						# network operation failed
						log_info($ffid, "error: network operation failed!");
						$result = packet_build_noencode("0", "error: network operation failed", $fid);
						$result->{'netstatus'} = $netstatus;
						json_encode_pretty($netstatus);
						$result = json_encode($result);
					}
				}
				else{
					# system state is online
					log_warn($ffid, "error: system id [$id] is already active!");
					$result = packet_build_encode("0", "error: system id [$id] is already active!", $ffid);
				}
			}
			else{
				# system state is locked (equal to loaded)
				log_warn($ffid, "error: system id [$id] is marked as locked!");
				$result = packet_build_encode("0", "error: system id [$id] is marked as locked!", $ffid);
			}
		}
		else{
			# system not in db
			log_warn($ffid, "error: vm not in db");
			$result = packet_build_encode("0", "error: vm not in db", $ffid);
		}
	}
	else{
		# build response		
		log_warn($ffid, "error: required service failed to respond");
		$result = packet_build_noencode("0", "error: required service failed to respond", $fid);	
		$result->{'frameping'} = $frameresult;
		$result->{'netping'} = $netresult;
		$result = json_encode($result);
	}
	
	# ensure we always return a JSON string
	unless (ref($result) eq '') {
		# If result is a reference (hash or array), encode it to JSON
		$result = json_encode($result);
	}
	
	# double-check: if result is still a reference, encode it
	if (ref($result)) {
		log_warn($ffid, "Warning: result is still a reference after encoding attempt. Type: " . ref($result));
		$result = json_encode($result);
	}
	
	# final check: ensure we return a string
	if (ref($result)) {
		log_error($ffid, "Error: result is still a reference. Type: " . ref($result) . ". Returning error packet instead.");
		return packet_build_encode("0", "error: internal JSON encoding failure", $ffid);
	}
	
	# additional safety: if result is not defined, return error
	unless (defined $result) {
		log_error($ffid, "Error: result is undefined. Returning error packet.");
		return packet_build_encode("0", "error: undefined result from hyper_load", $ffid);
	}
	
	# ensure it's a string (not a number or other scalar)
	# but first, if it's a reference, encode it to JSON
	if (ref($result)) {
		$result = json_encode($result);
	}
	else {
		$result = "$result";
	}
	
	return $result;
}

#
# load vmm
#
sub hyper_load_vmm($hyperdb, $vm){
	my $fid = "[hyper_load_vmm]";
	my $ffid = "HYPER|LOAD|VMM";
	my $id = $vm->{'id'}{'id'};
	my $host = "127.0.0.1";
	my $result;
	
	# allocate vmm identity (LEGACY)
	my $socket = "vmm." . $hyperdb->{'db'}{$id}{'id'}{'name'} . "." . $hyperdb->{'db'}{$id}{'id'}{'id'} . ".sock";
	log_info($ffid, "allocated vmm socket [$socket]");
		
	# find free vnc port... PORT OFFSET STATIC TODO
	my $vnc = index_free($hyperdb->{'net'}{'vnc'}, 100);
	$vnc = portcheck_index_find_free($host, $vnc, 5900, $hyperdb->{'net'}{'vnc'});
	$hyperdb->{'net'}{'vnc'} = index_add($hyperdb->{'net'}{'vnc'}, $vnc);
	$vm->{'meta'}{'vnc'} = $vnc;
	log_info($ffid, "reserved vnc port [$vnc]");
				
	# find free monitor port... PORT OFFSET STATIC TODO
	my $monitor = index_free($hyperdb->{'net'}{'monitor'}, 5555);
	$monitor = portcheck_index_find_free($host, $monitor, 0, $hyperdb->{'net'}{'monitor'});
	$hyperdb->{'net'}{'monitor'} = index_add($hyperdb->{'net'}{'monitor'}, $monitor);
	$vm->{'monitor'}{'port'} = $monitor;
	$vm->{'monitor'}{'addr'} = $host;
	$vm->{'monitor'}{'proto'} = "tcp";
	log_info($ffid, "reserved monitor port [$monitor]");

	# find free novnc port... PORT OFFSET STATIC TODO
	my $novnc = index_free($hyperdb->{'net'}{'novnc_port'}, 7000);
	$novnc = portcheck_index_find_free($host, $novnc, 0, $hyperdb->{'net'}{'novnc_port'});
	$hyperdb->{'net'}{'novnc'} = 1;
	$hyperdb->{'net'}{'novnc_port'} = index_add($hyperdb->{'net'}{'novnc_port'}, $novnc);
	$vm->{'meta'}{'novnc_port'} = $novnc;
	log_info($ffid, "reserved novnc port [$novnc]");
	
	# spawn novnc
	$vm = system_novnc_spawn($vm);
	
	my $config = hyper_db_obj_get("config");
	
	# configure identity
	$vm->{'meta'}{'node'} = config_node_name_get();
	$vm->{'meta'}{'agent'} = config_node_id_get();
	$vm->{'meta'}{'node_name'} = config_node_name_get();
	$vm->{'meta'}{'node_id'} = config_node_id_get();
	$vm->{'meta'}{'date'} = date_get();
			
	# migration activated (receiveing end)
	if($vm->{'meta'}{'migrate'}){	
		# configure migration port
		$vm->{'migrate'}{'host'} = $config->{'addr'};
		my $migrate = index_free($hyperdb->{'net'}{'migrate'}, 9000);
		$migrate = portcheck_index_find_free($host, $migrate, 0, $hyperdb->{'net'}{'migrate'});
		$hyperdb->{'net'}{'migrate'} = index_add($hyperdb->{'net'}{'migrate'}, $migrate);
		$vm->{'migrate'}{'port'} = $migrate;
		log_info($ffid, "migrate host [$vm->{'migrate'}{'host'}] port [$vm->{'migrate'}{'port'}] proto [$vm->{'migrate'}{'proto'}]");
	}
				
	# spawn vmm container
	my $vmmjson = api_framework_local_vmm_start(env_serv_sock_get("framework"), $vm);
	
	if($vmmjson->{'proto'}{'result'} eq "1"){
		# vmm spawn successful
		log_info($ffid, "successful vmm spawn");
		
		$vm = $vmmjson->{'vm'};
		
		if(env_verbose()){ 
			print "[" . date_get() . "] $fid vmm container result\n";
			json_encode_pretty($vmmjson); 
		};
		
		# wait for vmm container to settle
		sleep 1;
		
		# ping vmm
		my $vmmsock = $vm->{'meta'}{'vmm'}{'vmmsock'};
		log_info($ffid, "vmm socket [$vmmsock]");
		my $vmmping = api_vmm_local_ping($vmmsock);
		
		if(env_debug()){
			print "[" . date_get() . "] $fid vmm ping result\n";
			json_encode_pretty($vmmping);
		}

		# check ping result
		if($vmmping->{'proto'}{'result'}){
			log_info($ffid, "success. vmm container responded");
			$result = hyper_load_system($hyperdb, $vm);
		}
		else{
			# failed to contact vmm container
			log_warn($ffid, "error: failed to contact vmm container! cleaning up..");
			my $netstatus = hyper_net_nic_del($vm);
			my $vmmkill = api_framework_local_vmm_stop(env_serv_sock_get("framework"), $vm->{'id'}{'id'});
			
			# return status
			$result = packet_build_noencode("0", "error: failed to contact vmm container", $fid);
			$result->{'vmmping'} = $vmmping;
			$result->{'netstatus'} = $netstatus;
			$result->{'vmmkill'} = $vmmkill;
		}	
	}
	else{
		# vmm spawn successful
		log_warn($ffid, "error: failed to spawn vmm container!");
		if(env_verbose()){ json_encode_pretty($vmmjson); };
		$result = packet_build_noencode("0", "error: failed to spawn vmm container", $fid);
		$result->{'vmmspawn'} = $vmmjson;
	}	
	
	return $result;
}

#
# load system [JSON-OBJ]
#
sub hyper_load_system($hyperdb, $vm){
	my $fid = "[hyper_load_system]";
	my $ffid = "HYPER|SYSTEM|LOAD";
	my $result;
		
	my $id = $vm->{'id'}{'id'};
	log_info($ffid, "id [$id] vnc [$vm->{'meta'}{'vnc'}] monitor [$vm->{'monitor'}{'port'}] vmmsock [$vm->{'meta'}{'vmm'}{'vmmsock'}]");

	if(env_verbose()){ json_encode_pretty($vm); };	
	$vm->{'meta'}{'node'} = config_node_name_get();
	$vm->{'meta'}{'agent'} = config_node_id_get();
	
	# NEW
	$vm->{'meta'}{'node_name'} = config_node_name_get();
	$vm->{'meta'}{'node_id'} = config_node_id_get();

	# push vm config to vmm
	my $vmmpushresult = api_vmm_local_push($vm);
	
	# wait to settle
	sleep 1;

	# request vmm to load vm
	my $vmmloadresult = api_vmm_local_load($vm);
	
	# check system load result
	if($vmmloadresult->{'proto'}{'result'}){

		# update index and resources
		$hyperdb->{'vm'}{'lock'} = index_add($hyperdb->{'vm'}{'lock'}, $id);
		$hyperdb->{'vm'}{'cpualloc'} = ($hyperdb->{'vm'}{'cpualloc'} + $hyperdb->{'db'}{$id}{'hw'}{'cpu'}{'core'});
		$hyperdb->{'vm'}{'memalloc'} = ($hyperdb->{'vm'}{'memalloc'} + $hyperdb->{'db'}{$id}{'hw'}{'mem'}{'mb'});
		$hyperdb->{'vm'}{'systems'} = ($hyperdb->{'vm'}{'systems'} + 1);
		log_info($ffid, "allocated cpu [$hyperdb->{'vm'}{'cpualloc'}] allocated memory [$hyperdb->{'vm'}{'memalloc'}]");
		
		# pull updated system configuration from node
		my $vmminfo = api_vmm_local_pull($vm->{'meta'}{'vmm'}{'vmmsock'});
		
		log_info($ffid, "updating hyperdb");
		
		if($vmminfo->{'proto'}{'result'} eq "1"){
			# success
			$hyperdb->{'db'}{$id} = $vmminfo->{'vm'};
		}
		else{
			# failed
			$hyperdb->{'db'}{$id} = $vm;
			$hyperdb->{'db'}{$id}{'meta'}{'state'} = $vmminfo->{'meta'}{'state'};
			$hyperdb->{'db'}{$id}{'meta'}{'pid'} = $vmminfo->{'meta'}{'pid'};
			$hyperdb->{'db'}{$id}{'meta'}{'agent'} = config_node_id_get();
			$hyperdb->{'db'}{$id}{'meta'}{'node'} = config_node_name_get();
			$hyperdb->{'db'}{$id}{'meta'}{'node_id'} = config_node_id_get();
			$hyperdb->{'db'}{$id}{'meta'}{'node_name'} = config_node_name_get();
		}
			
		# load completed
		log_info($ffid, "success: loaded system id [$id]");
		$result = packet_build_noencode("1", "success: loaded system id [$id]", $fid);
		$result->{'vm'} = $hyperdb->{'db'}{$id};
		$result->{'vmmstatus'} = $vmmloadresult;
	}
	else{
		# clear system reservations
		log_warn($ffid, "failed to load system id [$id], clearing reservations...");
		json_encode_pretty($vmmloadresult);
		
		# remove network reservations
		my $netstatus = hyper_net_nic_del($vm);
									
		# destroy vmm container
		my $vmmkill = api_framework_local_vmm_stop(env_serv_sock_get("framework"), $vm->{'id'}{'id'});
		log_info($ffid, "vmm kill status [$vmmkill]");
		
		# failed, clear reservations
		$hyperdb->{'net'}{'vnc'} = index_del($hyperdb->{'net'}{'vnc'}, $vm->{'meta'}{'vnc'});
		$hyperdb->{'net'}{'monitor'} = index_del($hyperdb->{'net'}{'monitor'}, $vm->{'monitor'}{'port'});
		
		# return result
		$result = packet_build_noencode("0", "failed to load system id [$id]", $fid);
		$result->{'vmmstatus'} = $vmmloadresult;
		$result->{'netstatus'} = $netstatus;
	}					

	hyper_db_obj_set("hyper", $hyperdb);
	return $result;
}

#
# unload virtual machine [JSON-STR]
#
sub hyper_unload($json){
	my $fid = "[hyper_unload]";
	my $ffid = "HYPER|UNLOAD";
	my $result;	
	my $force = 1;

	# validate operation preconditions
	my $id = $json->{'hyper'}{'id'};
	my $preconditions = hyper_validate_operation_preconditions("UNLOAD", $id, "locked");
	unless ($preconditions->{valid}) {
		log_error($ffid, "Unload operation preconditions failed: " . 
		         join(", ", @{$preconditions->{errors}}));
		return packet_build_encode("0", "error: preconditions not met for unload: " . 
		         join(", ", @{$preconditions->{errors}}), $ffid);
	}

	# get data
	my $vmmstatus = hyper_vmm_check($json);
	my $hyperdb = hyper_db_obj_get("hyper");
	my $vm = $hyperdb->{'db'}{$id};
	$id = $vm->{'id'}{'id'};

	my $frameresult = api_framework_local_ping(env_serv_sock_get("framework"));
	my $netresult = api_network_local_ping(env_serv_sock_get("network"));
	
	# continue on success
	if(($frameresult->{'proto'}{'result'} eq "1") && ($netresult->{'proto'}{'result'} eq "1")){

		# check result
		if($vmmstatus->{'proto'}{'result'} eq "1" || ($vmmstatus->{'proto'}{'result'} eq "0" && $force eq "1")){
			
			# request vmm unload
			my $unloadresult = api_vmm_local_unload($vm);
			
			if(env_verbose()){ json_encode_pretty($unloadresult); };
			log_info($ffid, "vmm unload result [$unloadresult->{'proto'}{'result'}]");
			json_encode_pretty($unloadresult);
		
			if($unloadresult->{'proto'}{'result'} || $vmmstatus->{'proto'}{'string'} eq "error: resource unlocked. no vm is running."){
				# success
				log_info($ffid, "vmm container unloaded cleanly");
				my $vmmresult = packet_build_noencode("1", "success: vmm container unloaded cleanly", $fid);

				# cleanup reservations
				my $cleanupresult = hyper_unload_cleanup($vm);
				if(env_verbose()){ json_encode_pretty($cleanupresult); };
				
				$cleanupresult->{'vmmstatus'} = $unloadresult;
				$cleanupresult->{'vmmresult'} = $vmmresult;
				
				# update cleanup result
				$vm = $cleanupresult->{'vm'};
				
				$result = json_encode($cleanupresult);
				
				$vm->{'state'}{'vm_status'} = "unloaded";
				$vm->{'meta'}{'state'} = 0;
				
				hyper_cdb_system_sync($vm);
			}
			else{
				
				# check force flag 
				if($force){
					log_warn($ffid, "warning: destroying vmm by force");
					my $vmmresult = packet_build_noencode("1", "warning: vmm destroyed by force", $fid);

					# kill container
					my $vmmkill = api_framework_local_vmm_stop(env_serv_sock_get("framework"), $vm->{'id'}{'id'});
					log_warn($ffid, "vmm kill status [$vmmkill]");
					if(env_verbose()){ json_encode_pretty($vmmkill); };
				
					# cleanup reservations
					my $cleanupresult = hyper_unload_cleanup($vm);
					if(env_verbose()){ json_encode_pretty($cleanupresult); };
					
					$cleanupresult->{'vmmstatus'} = $unloadresult;
					$cleanupresult->{'vmmresult'} = $vmmresult;
					$result = json_encode($cleanupresult);
					
					# update cleanup result
					$vm = $cleanupresult->{'vm'};
					
					$vm->{'state'}{'vm_status'} = "unloaded_force";
					$vm->{'meta'}{'state'} = 0;

					hyper_cdb_system_sync($vm);
				}
				else{
					# unload failed
					$result = packet_build_noencode("0", "error: vmm container did not unload cleanly!", $fid);
					$result->{'vmmstatus'} = $vmmstatus;
					$result->{'vmmresult'} = $unloadresult;
					$result = json_encode($result);			
					log_warn($ffid, "error: vmm container did not unload cleanly!");
					
					$vm->{'state'}{'vm_status'} = "unloaded_dirty";
					$vm->{'meta'}{'state'} = 0;
					hyper_cdb_system_sync($vm);
				}
			}			
		}
		else{
			# vmm failed to respond
			log_warn($ffid, "error: vmm container did not respond!");
			$result = packet_build_noencode("0", "error: vmm container did not respond", $fid);
			$result->{'vmmstatus'} = $vmmstatus;
			$result = json_encode($result);	
		}
	}
	else{
		# build response
		log_warn($ffid, "error: required service failed to respond");
		$result = packet_build_noencode("0", "error: required service failed to respond", $fid);	
		$result->{'frameping'} = $frameresult;
		$result->{'netping'} = $netresult;
		$result = json_encode($result);
	}

	# ensure we always return a JSON string
	unless (ref($result) eq '') {
		# If result is a reference (hash or array), encode it to JSON
		$result = json_encode($result);
	}
	
	return $result;
}

#
# delete network taps [JSON-OBJ]
#
sub hyper_net_nic_del($vm){
	my $fid = "[hyper_net_nic_del]";
	my $ffid = "HYPER|NET|NIC|DEL";
	my $result;
	
	my $netstatus = api_network_local_vm_nic_del(env_serv_sock_get("network"), $vm);
	if(env_verbose()){ json_encode_pretty($netstatus); };
		
	if($netstatus->{'proto'}{'result'} eq "1"){
		log_info($ffid, "success: network operation succeeded");
		$result->{'netstatus'} = $netstatus;
	}
	else{
		log_warn($ffid, "error: network operation failed!");
		$result = packet_build_noencode("0", "error: network operation failed", $fid);
		json_encode_pretty($netstatus);
		$result->{'netstatus'} = $netstatus;
	}	

	return $result;
}

#
# cleanup vm reservations
#
sub hyper_unload_cleanup($vmdata){
	my $fid = "[hyper_unload_cleanup]";
	my $ffid = "HYPER|UNLOAD|CLEANUP";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $id = $vmdata->{'id'}{'id'};
	my $vm = $hyperdb->{'db'}{$id};
	my $result;
		
	# clear system reservations
	log_info($ffid, "unloading system id [$vm->{'id'}{'id'}], clearing reservations");
	
	# network
	my $netstatus = hyper_net_nic_del($vm);

	if(env_verbose()){ 
		print "$fid network unload result\n";
		json_encode_pretty($netstatus); 
	};
	
	if($netstatus->{'netstatus'}{'proto'}{'result'} eq "1"){
		# update vm information
		$vm = $netstatus->{'netstatus'}{'vm'};
		if(env_verbose()){ json_encode_pretty($vm); };
	}
						
	# destroy vmm container
	my $vmmkill = api_framework_local_vmm_stop(env_serv_sock_get("framework"), $vm->{'id'}{'id'});
	if(env_verbose()){ json_encode_pretty($vmmkill); };
	
	# delete vnc reservation
	$hyperdb->{'net'}{'vnc'} = index_del($hyperdb->{'net'}{'vnc'}, $vm->{'meta'}{'vnc'});
	log_info($ffid, "reserved vnc port [$vm->{'meta'}{'vnc'}] cleared");

	# delete novnc reservation
	$hyperdb->{'net'}{'novnc'} = 0;
	$hyperdb->{'net'}{'novnc_port'} = index_del($hyperdb->{'net'}{'novnc_port'}, $vm->{'meta'}{'novnc_port'});
	$vm = system_novnc_kill($vm);
	
	# vnc reservation
	$hyperdb->{'net'}{'vnc'} = index_del($hyperdb->{'net'}{'vnc'}, $vm->{'meta'}{'vnc'});
	log_info($ffid, "reserved vnc port [$vm->{'meta'}{'vnc'}] cleared");

	# delete monitor port reservation
	$hyperdb->{'net'}{'monitor'} = index_del($hyperdb->{'net'}{'monitor'}, $vm->{'monitor'}{'port'});
	log_info($ffid, "cleared reserved monitor port [$vm->{'monitor'}{'port'}] cleared");

	# clear vmm id lock			
	$hyperdb->{'vm'}{'lock'} = index_del($hyperdb->{'vm'}{'lock'}, $id);
	
	# add cpu and memory allocation
	$hyperdb->{'vm'}{'cpualloc'} = ($hyperdb->{'vm'}{'cpualloc'} - $hyperdb->{'db'}{$id}{'hw'}{'cpu'}{'core'});
	$hyperdb->{'vm'}{'memalloc'} = ($hyperdb->{'vm'}{'memalloc'} - $hyperdb->{'db'}{$id}{'hw'}{'mem'}{'mb'});
	$hyperdb->{'vm'}{'systems'} = ($hyperdb->{'vm'}{'systems'} - 1);
	
	log_info($ffid, "updated cpu allocation [$hyperdb->{'vm'}{'cpualloc'}] memory allocation [$hyperdb->{'vm'}{'memalloc'}");

	# clear migration ports
	if($vm->{'meta'}{'migrate'} eq "1"){
		print "$fid migrated: clearing port reservations\n";
		$hyperdb->{'net'}{'migrate'} = index_del($hyperdb->{'net'}{'migrate'}, $vm->{'migrate'}{'port'});
	}
	
	# clean vmm settings
	$vm->{'meta'}{'state'} = 0;
	$vm->{'meta'}{'migrate'} = 0;
	delete $vm->{'meta'}{'pid'};
	delete $vm->{'meta'}{'vnc'};
	delete $vm->{'meta'}{'vmmsock'};
	delete $vm->{'meta'}{'vmm'};
	#delete $vm->{'meta'}{'stats'};
	delete $vm->{'monitor'};
	delete $vm->{'state'};
	
	# sync updated staste to cluster
	hyper_cdb_system_sync($vm);
		
	# save vm data
	$hyperdb->{'db'}{$id} = $vm;

	# success, return result
	log_info($ffid, "success: system id [$id] unloaded!");
	$result = packet_build_noencode("1", "success: system id [$id] unloaded!", $fid);
	$result->{'netstatus'}{'proto'} = $netstatus->{'netstatus'}{'proto'};
	$result->{'vm'} = $vm;
	
	# save data
	hyper_db_obj_set("hyper", $hyperdb);
	if(env_debug()){ json_encode_pretty($hyperdb); };
	return $result;
}

#
# reset virtual machine [JSON-STR]
#
sub hyper_reset($json){
	my $fid = "[hyper_reset]";
	my $ffid = "HYPER|RESET";
	my $result;
	
	# validate operation preconditions
	my $id = $json->{'hyper'}{'id'};
	my $preconditions = hyper_validate_operation_preconditions("RESET", $id, "online");
	unless ($preconditions->{valid}) {
		log_error($ffid, "Reset operation preconditions failed: " . 
		         join(", ", @{$preconditions->{errors}}));
		return packet_build_encode("0", "error: preconditions not met for reset: " . 
		         join(", ", @{$preconditions->{errors}}), $ffid);
	}
	
	# gather status
	my $vmmstatus = hyper_vmm_check($json);
	my $hyperdb = hyper_db_obj_get("hyper");
	my $vm = $hyperdb->{'db'}{$id};

	# check result
	if($vmmstatus->{'proto'}{'result'}){
		
		# unload vmm
		my $unloadresult = api_vmm_local_reset($vm);
		log_info($ffid, "vmm unload result [$unloadresult]");
	
		if($unloadresult->{'proto'}{'result'} eq 1){
			# success
			log_info($ffid, "success: vmm container reset");
			$result = packet_build_noencode("1", "success: vmm container reset", $fid);
			$result->{'vmmstatus'} = $unloadresult;
			$result = json_encode($result);
		}
		else{
			# unload failed
			log_warn($ffid, "failed: vmm container did not reset!");
			$result = packet_build_noencode("0", "error: vmm container did not reset!", $fid);
			$result->{'vmmstatus'} = $unloadresult;
			$result = json_encode($result);					
		}				
	}
	else{
		# vmm failed to respond
		log_warn($ffid, "failed: vmm container did not respond!");
		$result = packet_build_noencode("0", "error: vmm container did not respond", $fid);
		$result->{'vmmstatus'} = $vmmstatus;
		$result = json_encode($result);	
	}

	return $result;
}

#
# shutdown virtual machine [JSON-STR]
#
sub hyper_shutdown($json){
	my $fid = "[hyper_shutdown]";
	my $ffid = "HYPER|SHUTDOWN";
	my $result;
	
	# validate operation preconditions
	my $id = $json->{'hyper'}{'id'};
	my $preconditions = hyper_validate_operation_preconditions("SHUTDOWN", $id, "online");
	unless ($preconditions->{valid}) {
		log_error($ffid, "Shutdown operation preconditions failed: " . 
		         join(", ", @{$preconditions->{errors}}));
		return packet_build_encode("0", "error: preconditions not met for shutdown: " . 
		         join(", ", @{$preconditions->{errors}}), $ffid);
	}
	
	# gather status
	my $vmmstatus = hyper_vmm_check($json);
	my $hyperdb = hyper_db_obj_get("hyper");
	my $vm = $hyperdb->{'db'}{$id};

	my $frameresult = api_framework_local_ping(env_serv_sock_get("framework"));
	my $netresult = api_network_local_ping(env_serv_sock_get("network"));
	
	if(env_debug()){
		print "[" . date_get() . "] $fid framework ping\n";
		json_encode_pretty($frameresult);
		
		print "[" . date_get() . "] $fid network ping\n";
		json_encode_pretty($netresult);
	}

	# continue on success
	if(($frameresult->{'proto'}{'result'} eq "1") && ($netresult->{'proto'}{'result'} eq "1")){

		# check result
		if($vmmstatus->{'proto'}{'result'}){
			
			# shutdown vmm
			my $unloadresult = api_vmm_local_shutdown($vm);
			
			log_info_json($ffid, "shutdown successful. vmm unload result", $unloadresult);
			
			if($unloadresult->{'proto'}{'result'} eq 1){
				# success
				log_info($ffid, "success: vmm container shut down");
				$result = packet_build_noencode("1", "success: vmm container shut down", $fid);
				$result->{'vmmstatus'} = $unloadresult;
				$result = json_encode($result);
				
				log_info_json($ffid, "system shutdown successful", $result);
			}
			else{
				# unload failed
				log_warn($ffid, "error: vmm container did not shut down!");
				$result = packet_build_noencode("0", "error: vmm container did not shut down!", $fid);
				$result->{'vmmstatus'} = $unloadresult;
				$result = json_encode($result);					
			}			
		}
		else{
			# vmm failed to respond
			log_warn($ffid, "error: vmm container did not respond!");
			$result = packet_build_noencode("0", "error: vmm container did not respond", $fid);
			$result->{'vmmstatus'} = $vmmstatus;
			$result = json_encode($result);	
		}
	}
	else{
		# build response
		log_warn($ffid, "error: required service failed to respond!");
		$result = packet_build_noencode("0", "error: required service failed to respond", $fid);	
		$result->{'frameping'} = $frameresult;
		$result->{'netping'} = $netresult;
		$result = json_encode($result);	
	}

	return $result;
}

#
# request info from vmm container
#
sub hyper_proxy_info($json){
	my $fid = "[hyper_proxy_info]";
	my $ffid = "HYPER|PROXY|INFO";
	my $result;
	
	# gather systems
	my $vmmstatus = hyper_vmm_check($json);
	my $hyperdb = hyper_db_obj_get("hyper");
	my $vm = $hyperdb->{'db'}{$json->{'hyper'}{'id'}};
	my $vmmsock = $vm->{'meta'}{'vmm'}{'vmmsock'};

	if($vmmstatus->{'proto'}{'result'}){
		# get info
		my $json = api_vmm_local_info($vmmsock); 
		$result = json_encode($json);		
	}
	else{
		# vmm failed to respond
		$result = packet_build_noencode("0", "error: vmm container did not respond", $fid);
		$result->{'vmmstatus'} = $vmmstatus;
		$result = json_encode($result);	
	}

	return $result;
}

#
# check vmm container status
#
sub hyper_vmm_check($req){
	my $fid = "[hyper_vmm_check]";
	my $ffid = "HYPER|VMM|CHECK";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;

	if(env_debug()){ json_encode_pretty($req); };
	
	# check if VM in db
	if(index_find($hyperdb->{'vm'}{'index'}, $req->{'hyper'}{'id'})){
		
		# vm is in db
		my $vm = $hyperdb->{'db'}{$req->{'hyper'}{'id'}};	
		$result = json_encode($vm);
		
		# check if vm is locked
		if(index_find($hyperdb->{'vm'}{'lock'}, $req->{'hyper'}{'id'})){
		
			if($vm->{'meta'}{'state'}){
				# system state is online
			
				# ping vmm container
				my $vmmsock = $vm->{'meta'}{'vmm'}{'vmmsock'};
				my $vmmping = api_vmm_local_ping($vmmsock);

				# check ping result
				if($vmmping->{'proto'}{'result'}){
					log_info($ffid, "success. vmm container [$vmmsock] responded");
					$result = packet_build_noencode("1", "success: vmm container responded", $fid);
					$result->{'vmmstatus'} = $vmmping;			
				}
				else{
					# failed to contact vmm container
					log_info($ffid, "success. vmm container [$vmmsock] failed to respond!");
					$result = packet_build_noencode("0", "error: failed to contact vmm container!", $fid);
					$result->{'vmmstatus'} = $vmmping;
				}				
			}
			else{
				# system state is online
				$result = packet_build_noencode("0", "error: system id [" . $req->{'hyper'}{'id'} . "] is not active!", $fid);
			}
		}
		else{
			# system state is locked
			$result = packet_build_noencode("0", "error: system id [" . $req->{'hyper'}{'id'} . "] is not locked!", $fid);
		}	
	}
	else{
		# vm not in db
		$result = packet_build_noencode("0", "error: vm id [" . $req->{'hyper'}{'id'} . "] not in database", $fid);
	}
	
	return $result;
}

#
# check vmm container resource constraints [JSON-OBJ]
#
sub hyper_limits_check($vm){
	my $fid = "[hyper_resource_check]";
	my $ffid = "HYPER|RESOURCE|CHECK";
	my $host_mem_res = "8192";
	
	my $result = {};
	$result->{'valid'} = 1;

	my $hyperdb = hyper_db_get();
	json_encode_pretty($hyperdb);
	json_encode_pretty($vm);

	my $mem_free = $hyperdb->{'hw'}{'mem'}{'mb'};
	my $mem_res = $hyperdb->{'hyper'}{'vm'}{'memalloc'};
	my $mem_req = $vm->{'hw'}{'mem'}{'mb'};
	
	my $cpu_core_avail = $hyperdb->{'hw'}{'cpu'}{'core'};
	my $cpu_sock_avail = $hyperdb->{'hw'}{'cpu'}{'sock'};
	my $cpu_alloc = $hyperdb->{'hyper'}{'vm'}{'cpualloc'};
	
	my $cpu_core_req = $vm->{'hw'}{'cpu'}{'core'};
	my $cpu_sock_req = $vm->{'hw'}{'cpu'}{'sock'};
	
	# add sockets
	my $host_core_tot = $cpu_sock_avail * $cpu_core_avail;
	my $vm_core_tot = $cpu_sock_req * $cpu_core_req;
	
	log_info($ffid, "cpu cores [$host_core_tot] reserved [$cpu_alloc] requested [$vm_core_tot]");
	log_info($ffid, "memory [$mem_free] reserved [$host_mem_res] allocated [$mem_res] requested [$mem_req]");

	# check cpu
	if($host_core_tot >= $vm_core_tot){
		$result->{'cpu'}{'ratio'} = ($vm_core_tot / $host_core_tot) * 100;
		$result->{'cpu'}{'valid'} = 1;
	}
	else{
		$result->{'cpu'}{'ratio'} = ($vm_core_tot / $host_core_tot) * 100;
		$result->{'cpu'}{'valid'} = 0;
		$result->{'valid'} = 0;
	}

	# check memory
	if(($mem_free - $host_mem_res - $mem_res) > $mem_req){
		$result->{'mem'}{'ratio'} = ($mem_req / ($mem_free - $host_mem_res - $mem_res)) * 100;
		$result->{'mem'}{'valid'} = 1;
	}
	else{
		$result->{'mem'}{'ratio'} = ($mem_req / ($mem_free - $host_mem_res - $mem_res)) * 100;
		$result->{'mem'}{'valid'} = 0;
		$result->{'valid'} = 0;
	}

	json_encode_pretty($result);
	return $result;
}

#
# unload virtual machine [JSON-STR]
#
sub hyper_destroy($request){
	my $fid = "[hyper_destroy]";
	my $ffid = "HYPER|DESTROY";
	my $result;	
	my $force = 1;

	# validate operation preconditions
	my $vm = $request->{'hyper'}{'vm'};
	my $id = $vm->{'id'}{'id'};
	
	# for destroy, we need to check if VM exists and is locked (since destroy can work on locked VMs)
	my $preconditions = hyper_validate_operation_preconditions("DESTROY", $id, "locked");
	unless ($preconditions->{valid}) {
		log_error($ffid, "Destroy operation preconditions failed: " . 
		         join(", ", @{$preconditions->{errors}}));
		# For destroy, we might still proceed if VM doesn't exist but we have the VM data
		# So we'll log but continue with caution
		log_warn($ffid, "Destroy preconditions not met, but continuing with provided VM data");
	}

	my $hyperdb = hyper_db_obj_get("hyper");

	my $frameresult = api_framework_local_ping(env_serv_sock_get("framework"));
	my $netresult = api_network_local_ping(env_serv_sock_get("network"));

	log_warn_json($ffid, "### STARTING SYSTEM DESTROY ### system id [$id]data", $vm);
	
	$result = packet_build_noencode("1", "initializing system destroy for vm [" . $id . "]", $fid);
	
	# check if VM is in database
	if(index_find($hyperdb->{'vm'}{'index'}, $id)){
		#log_info($ffid, "VM [$id] is in the database. using internal dataset");
		$vm = $hyperdb->{'db'}{$id};
		log_info_json($ffid, "VM [$id] is in the database. using internal dataset", $vm);
		
		$result->{'hyperdb'} = packet_build_noencode("1", "system [$id] is known by the hypervisor", $fid);
				
		# check if vm is locked
		if(index_find($hyperdb->{'vm'}{'lock'}, $id)){
			log_info($ffid, "SYSTEM [$id] is locked!");
			$result->{'hyperlock'} = packet_build_noencode("1", "system [$id] is locked by the hypervisor", $fid);
			
			if($vm->{'meta'}{'state'}){
				# system state is online
				log_info($ffid, "SYSTEM [$id] is online!");
				$result->{'hyperstate'} = packet_build_noencode("1", "system [$id] is marked online!", $fid);
			}
			else{
				# system state is not online
				log_info($ffid, "SYSTEM [$id] is NOT online!");
				$result->{'hyperstate'} = packet_build_noencode("1", "system [$id] is NOT marked online!", $fid);
			}
		}
		else{
			# system state is locked
			log_info($ffid, "SYSTEM [$id] is NOT locked!");
			$result->{'hyperlock'} = packet_build_noencode("1", "system [$id] is not locked", $fid);
		}	
	}
	else{
		# vm not in db
		log_info($ffid, "SYSTEM [$id] is NOT in the database!");
		$result->{'hyperdb'} = packet_build_noencode("1", "system [$id] is not known by the hypervisor", $fid);
	}
	
	# build VMM socket path
	my $vmmsock = env_base_get() . "socket/" . "vmm." . $vm->{'id'}{'name'} . "." . $vm->{'id'}{'id'} . ".sock";
	log_info($ffid, "VMM socket [$vmmsock]");
	
	#
	# check for QEMU PID
	#
	
	my $childpid;
	
	# check for pid
	if(defined $vm->{'meta'}{'pid'}){
		log_info($ffid, "using defined pid [$vm->{'meta'}{'pid'}]");
		$childpid = $vm->{'meta'}{'pid'};
	}
	else{
		my $vmstr = '"' . 'system \[' . $vm->{'id'}{'name'} . '\] id \[' . $vm->{'id'}{'id'} . '\]' . '"'; 
		log_info($ffid, "attempting to find system pid [$vmstr]");
		$childpid = execute('pgrep -f ^qemu-system-x86_64.*' . $vmstr);
		chomp($childpid);
		log_info($ffid, "found pids [$childpid]");
	}
	
	my $qemu_running = 0;
	
	log_info($ffid, "checking if pids [$childpid] is running...");
	
	# if childpid
	if($childpid){
	
		if (kill 0, $childpid) {
			log_info($ffid, "process [$childpid] exists and is running");
			$qemu_running = 1;
		} else {
			if ($! == Errno::ESRCH) {
				log_info($ffid, "process [$childpid] not found");
			} else {
				log_warn($ffid, "Permission denied to check process [$childpid] error [" . $! . "]");
			}
		}
		
		if($qemu_running){
			log_info($ffid, "qemu is running with pid [$childpid]!");
			
			# kill it here
			my $killresult = killer($childpid);
			log_info($ffid, "killed qemu process with result [$killresult]");
			
			$result->{'qemukill'} = packet_build_noencode("1", "system [$id] qemu online and killed", $fid);
			$result->{'qemukill_result'} = $killresult;
			
			sleep 2;
		}
		else{
			log_info($ffid, "qemu is not running");
			$result->{'qemukill'} = packet_build_noencode("1", "system [$id] qemu not running", $fid);
		}
	
	}
	else{
		log_info($ffid, "qemu pid not found");
		$result->{'qemukill'} = packet_build_noencode("1", "system [$id] qemu pid not found", $fid);
	}
	
	# check if the VMM is running
	my $vmmpid = execute('pgrep -f ' . "vmm." . $vm->{'id'}{'name'} . "." . $vm->{'id'}{'id'} . "." . "sock");
	chomp($vmmpid);
	
	if($vmmpid){
		log_info($ffid, "vmm is running with pid [$vmmpid]!");
		
		# destroy it
		my $killresult = killer($vmmpid);
		log_info($ffid, "vmm killed with result [$killresult]");
		
		$result->{'vmmkill'} = packet_build_noencode("1", "system [$id] vmm online and killed", $fid);
		$result->{'vmmkill_result'} = $killresult;
	}
	else{
		log_info($ffid, "VMM IS NOT RUNNING!");
		$result->{'vmmkill'} = packet_build_noencode("1", "system [$id] vmm not running", $fid);
	}	
	
	#
	# FRAMEWORK
	#
	my $framemeta = api_framework_local_meta(env_serv_sock_get("framework"));
	
	if($framemeta->{'proto'}{'result'}){
		# success
		log_info($ffid, "successfully got framework metadata");
		
		my $vmm_index = $framemeta->{'meta'}{'vmm'}{'index'};
		
		if(index_find($vmm_index, $id)){
			log_info($ffid, "success: VMM is known by framework");
			
			$result->{'framework'} = packet_build_noencode("1", "system [$id] is known by framework", $fid);
			
			# pull vmm info
			my $vmframedata = api_framework_local_vmm_info(env_serv_sock_get("framework"), $id);
			json_encode_pretty($vmframedata);
			
			# request framework to kill the VMM
			my $unloadresult = api_framework_local_vmm_stop(env_serv_sock_get("framework"), $vm->{'id'}{'id'});
			$result->{'framework_unload'} = $unloadresult;
		}
		else{
			# vmm not known by framework
			log_info($ffid, "error: VMM not known by framework");
			$result->{'framework'} = packet_build_noencode("1", "system [$id] is NOT known by framework", $fid);
		}
	}
	else{
		# failed to get framemwork metadata
		log_info($ffid, "failed to get framework meta!");
		$result->{'framework'} = packet_build_noencode("1", "failed to get framework meta", $fid);
	}
	
	#
	# NETWORK
	#
	my $netmeta = api_network_local_meta(env_serv_sock_get("network"));
	
	if($netmeta->{'proto'}{'result'}){
		
		if(index_find($netmeta->{'net'}{'vm_index'}, $vm->{'id'}{'name'})){
			log_info($ffid, "success: VM is known by network");
			
			$result->{'network'} = packet_build_noencode("1", "network knows this VM", $fid);
			
			# need a function in network to pull network data from network here
			my $netvm = api_network_local_vm_get(env_serv_sock_get("network"), $vm->{'id'}{'name'});
			$result->{'network_cleanup'} = hyper_net_nic_del($netvm->{'vmdata'});
		}
		else{
			# VMM not known by framework
			log_info($ffid, "error: VM is NOT known by network");
			$result->{'network'} = packet_build_noencode("1", "network does not know this VM", $fid);
		}
	}
	else{
		# failure
		log_info($ffid, "error: failed to get network meta!");
	}
	
	# try to cleanup the vm
	hyper_unload_cleanup_dirty($vm);
	
	return json_encode($result);
}

#
# cleanup vm reservations
#
sub hyper_unload_cleanup_dirty($vmdata){
	my $fid = "[hyper_unload_cleanup]";
	my $ffid = "HYPER|UNLODAD|CLEANUP";
	my $hyperdb = hyper_db_obj_get("hyper");
	
	my $id = $vmdata->{'id'}{'id'};
	my $vm = $vmdata;
	
	my $result;
		
	# clear system reservations
	log_info($ffid, "unloading system id [$vm->{'id'}{'id'}], clearing reservations");
		
	# delete vnc reservation
	$hyperdb->{'net'}{'vnc'} = index_del($hyperdb->{'net'}{'vnc'}, $vm->{'meta'}{'vnc'});
	log_info($ffid, "vnc port [$vm->{'meta'}{'vnc'}] reservation cleared");

	# delete novnc reservation
	$hyperdb->{'net'}{'novnc'} = 0;
	$hyperdb->{'net'}{'novnc_port'} = index_del($hyperdb->{'net'}{'novnc_port'}, $vm->{'meta'}{'novnc_port'});
	$vm = system_novnc_kill($vm);
	
	# vnc reservation
	$hyperdb->{'net'}{'vnc'} = index_del($hyperdb->{'net'}{'vnc'}, $vm->{'meta'}{'vnc'});
	log_info($ffid, "reserved vnc port [$vm->{'meta'}{'vnc'}] cleared");

	# delete monitor port reservation
	$hyperdb->{'net'}{'monitor'} = index_del($hyperdb->{'net'}{'monitor'}, $vm->{'monitor'}{'port'});
	log_info($ffid, "cleared reserved monitor port [$vm->{'monitor'}{'port'}] cleared");

	# clear vmm id lock			
	$hyperdb->{'vm'}{'lock'} = index_del($hyperdb->{'vm'}{'lock'}, $id);
	
	# add cpu and memory allocation
	$hyperdb->{'vm'}{'cpualloc'} = ($hyperdb->{'vm'}{'cpualloc'} - $hyperdb->{'db'}{$id}{'hw'}{'cpu'}{'core'});
	$hyperdb->{'vm'}{'memalloc'} = ($hyperdb->{'vm'}{'memalloc'} - $hyperdb->{'db'}{$id}{'hw'}{'mem'}{'mb'});
	$hyperdb->{'vm'}{'systems'} = ($hyperdb->{'vm'}{'systems'} - 1);
	
	log_info($ffid, "cpualloc [$hyperdb->{'vm'}{'cpualloc'}] memalloc [$hyperdb->{'vm'}{'memalloc'}]");

	# clear migration ports
	if($vm->{'meta'}{'migrate'} eq "1"){
		log_info($ffid, "clearing migration port reservations");
		$hyperdb->{'net'}{'migrate'} = index_del($hyperdb->{'net'}{'migrate'}, $vm->{'migrate'}{'port'});
	}
	
	# clean vmm settings
	$vm->{'meta'}{'state'} = 0;
	$vm->{'meta'}{'migrate'} = 0;
	delete $vm->{'meta'}{'pid'};
	delete $vm->{'meta'}{'vnc'};
	delete $vm->{'meta'}{'vmmsock'};
	delete $vm->{'meta'}{'vmm'};
	#delete $vm->{'meta'}{'stats'};
	delete $vm->{'monitor'};
	delete $vm->{'state'};
	
	# sync updated staste to cluster
	hyper_cdb_system_sync($vm);
		
	# save vm data
	$hyperdb->{'db'}{$id} = $vm;

	# success, return result
	log_info($ffid, "success: system id [$id] unloaded!");
	$result = packet_build_noencode("1", "success: system id [$id] unloaded!", $fid);
	$result->{'vm'} = $vm;
	
	# save data
	hyper_db_obj_set("hyper", $hyperdb);
	return $result;
}

#
# shutdown virtual machine [JSON-STR]
#
sub hyper_validate($json){
	my $fid = "[hyper_validate]";
	my $ffid = "HYPER|VALIDATE";
	my $result;
	
	log_info($ffid, "received request");
	json_encode_pretty($json);
	
	my $stor_valid = 1;
	my $iso_valid = 1;
	my $net_valid = 1;
	my $res_valid = 1;
	
	my $system = $json->{'hyper'}{'vm'};
	
	# enhanced validation: use comprehensive VM structure validation
	my $structure_validation = hyper_validate_vm_structure($system);
	unless ($structure_validation->{valid}) {
		log_error($ffid, "VM structure validation failed: " . 
		         join(", ", @{$structure_validation->{errors}}));
		$result = packet_build_noencode("0", "error: invalid vm structure: " . 
		         join(", ", @{$structure_validation->{errors}}), $fid);
		$result->{'vm'}{'valid'}{'structure'} = 0;
		$result->{'vm'}{'valid'}{'structure_errors'} = $structure_validation->{errors};
		$result->{'vm'}{'valid'}{'structure_warnings'} = $structure_validation->{warnings};
		return json_encode($result);
	}
	
	if (@{$structure_validation->{warnings}}) {
		log_warn($ffid, "VM structure validation warnings: " . 
		        join(", ", @{$structure_validation->{warnings}}));
		$result->{'vm'}{'valid'}{'structure_warnings'} = $structure_validation->{warnings};
	}
	
	$result = packet_build_noencode("1", "validating system", $fid);
	$result->{'vm'}{'valid'}{'structure'} = 1;
	
	#
	# resources
	#
	my $limits = hyper_limits_check($system);
	
	# check if limits are valid
	if($limits->{'valid'}){
		# limits valid
		log_info($ffid, "[resource check] success");
		$result->{'vm'}{'resource'}{'valid'} = 1;
		$result->{'vm'}{'resource'}{'limits'} = $limits;
		$res_valid = 1;
	}
	else{
		# limits failed
		log_warn_json($ffid, "[resource check] failed!", $limits);
		$result->{'vm'}{'resource'}{'valid'} = 0;
		$result->{'vm'}{'resource'}{'limits'} = $limits;
		$res_valid = 0;
	}
	
	#
	# storage
	#
	my @stor_index = index_split($system->{'stor'}{'disk'});
	
	foreach my $dev (@stor_index){
		
		# check storage type
		if(defined $system->{'stor'}{$dev}{'backing'}){
		
			if($system->{'stor'}{$dev}{'backing'} eq "pool"){
				# pool
				my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
			
				# validate image
				if(file_check($file)){
					log_warn($ffid, "storage [$dev] backing [pool] path [$system->{'stor'}{$dev}{'dev'}] image [$system->{'stor'}{$dev}{'image'}]: EXISTS");
					
					$result->{'vm'}{'storage'}{$dev}{'valid'} = 1;
					$result->{'vm'}{'storage'}{$dev}{'result'} = "storage exists";
					$result->{'vm'}{'storage'}{$dev}{'locked'} = system_lockfile_check($system->{'stor'}{$dev});
					
					my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
					$result->{'vm'}{'storage'}{$dev}{'size'} = format_bytes(-s $file);
				}
				else{
					log_warn($ffid, "storage [$dev] [pool] path [$system->{'stor'}{$dev}{'dev'}] image [$system->{'stor'}{$dev}{'image'}]: DOES NOT EXIST");
					$result->{'vm'}{'storage'}{$dev}{'valid'} = 0;
					$result->{'vm'}{'storage'}{$dev}{'result'} = "storage does not exist";
					$result->{'vm'}{'storage'}{$dev}{'locked'} = system_lockfile_check($system->{'stor'}{$dev});
					$stor_valid = 0;
				}
				
			}
			else{
				# legacy
				my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
			
				# validate image
				if(file_check($file)){
					log_info($ffid, "storage [$dev] backing [other] path [$system->{'stor'}{$dev}{'dev'}] image [$system->{'stor'}{$dev}{'image'}]: DOES NOT EXIST");
					$result->{'vm'}{'storage'}{$dev}{'valid'} = 1;
					$result->{'vm'}{'storage'}{$dev}{'result'} = "storage exists";
					$result->{'vm'}{'storage'}{$dev}{'locked'} = system_lockfile_check($system->{'stor'}{$dev});
					
					my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
					$result->{'vm'}{'storage'}{$dev}{'size'} = format_bytes(-s $file);
				}
				else{
					log_warn($ffid, "storage [$dev] backing [other] path [$system->{'stor'}{$dev}{'dev'}] image [$system->{'stor'}{$dev}{'image'}]: DOES NOT EXIST");
					$result->{'vm'}{'storage'}{$dev}{'valid'} = 0;
					$result->{'vm'}{'storage'}{$dev}{'result'} = "storage does not exist";
					$result->{'vm'}{'storage'}{$dev}{'locked'} = system_lockfile_check($system->{'stor'}{$dev});
					$stor_valid = 0;
				}
				
			}
		}
		else{
			# legacy
			my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
			
			# validate image
			if(file_check($file)){
				log_warn($ffid, "storage [$dev] backing [legacy] path [$system->{'stor'}{$dev}{'dev'}] image [$system->{'stor'}{$dev}{'image'}]: EXIST");
				
				$result->{'vm'}{'storage'}{$dev}{'valid'} = 1;
				$result->{'vm'}{'storage'}{$dev}{'result'} = "storage exists";
				$result->{'vm'}{'storage'}{$dev}{'locked'} = system_lockfile_check($system->{'stor'}{$dev});
				
				my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
				$result->{'vm'}{'storage'}{$dev}{'size'} = format_bytes(-s $file);
			}
			else{
				log_warn($ffid, "storage [$dev] backing [legacy] path [$system->{'stor'}{$dev}{'dev'}] image [$system->{'stor'}{$dev}{'image'}]: DOES NOT EXIST");
				$result->{'vm'}{'storage'}{$dev}{'valid'} = 0;
				$result->{'vm'}{'storage'}{$dev}{'result'} = "storage does not exist";
				$result->{'vm'}{'storage'}{$dev}{'locked'} = system_lockfile_check($system->{'stor'}{$dev});
				$stor_valid = 0;
				
			}
			
		}
	}

	#
	# storage
	#
	my @iso_index = index_split($system->{'stor'}{'iso'});
	
	foreach my $iso (@iso_index){
		
		my $iso_path = $system->{'stor'}{$iso}{'dev'} . $system->{'stor'}{$iso}{'image'};
		
		if(file_check($iso_path)){
			log_info($ffid, "iso [$iso] dir [$system->{'stor'}{$iso}{'dev'}] img [$system->{'stor'}{$iso}{'image'}]: VALID");
			$result->{'vm'}{'storage'}{$iso}{'valid'} = 1;
			$result->{'vm'}{'storage'}{$iso}{'result'} = "iso exists";
		}
		else{
			log_info($ffid, "iso [$iso] dir [$system->{'stor'}{$iso}{'dev'}] img [$system->{'stor'}{$iso}{'image'}]: NOT VALID");
			$result->{'vm'}{'storage'}{$iso}{'valid'} = 0;
			$result->{'vm'}{'storage'}{$iso}{'result'} = "iso does not exist";
			$iso_valid = 0;
		}
		
	}
	
	#
	# network
	#
	
	# get network meta
	my $net_meta = api_network_local_meta(env_serv_sock_get("network"));
	my $net_index = $net_meta->{'net'}{'net_index'};
	my @net_index = index_split($system->{'net'}{'dev'});
	
	foreach my $dev (@net_index){
		
		# check if network exists
		if(index_find($net_meta->{'net'}{'net_index'}, $system->{'net'}{$dev}{'net'}{'id'})){
			log_info($ffid, "netdev [$dev] net id [$system->{'net'}{$dev}{'net'}{'id'}]: EXISTS");
			$result->{'vm'}{'net'}{$dev}{'valid'} = 1;
			$result->{'vm'}{'net'}{$dev}{'result'} = "network [$system->{'net'}{$dev}{'net'}{'id'}] exist";
		}
		else{
			log_info($ffid, "netdev [$dev] net id [$system->{'net'}{$dev}{'net'}{'id'}]: DOES NOT EXIST");
			$result->{'vm'}{'net'}{$dev}{'valid'} = 0;
			$result->{'vm'}{'net'}{$dev}{'result'} = "network [$system->{'net'}{$dev}{'net'}{'id'}] does not exist";
			$net_valid = 0;
		}
		
	}
	
	#
	# check if system is marked as valid or not
	#
	if($system->{'object'}{"init"} eq "1"){
		$result->{'vm'}{'init'}{'state'} = 1;		
	}
	else{
		$result->{'vm'}{'init'}{'state'} = 0;
	}
	
	# check if storage is valid
	if($stor_valid){		
		$result->{'vm'}{'init'}{'storage'} = 1;
	}
	else{
		$result->{'vm'}{'init'}{'storage'} = 0;
	}
	
	#
	# validation report
	#
	$result->{'vm'}{'valid'}{'storage'} = $stor_valid;
	$result->{'vm'}{'valid'}{'iso'} = $iso_valid;
	$result->{'vm'}{'valid'}{'network'} = $net_valid;
	$result->{'vm'}{'valid'}{'resource'} = $res_valid;
	
	if($stor_valid && $iso_valid && $net_valid && $res_valid){
		$result->{'vm'}{'valid'}{'state'} = 1;
		$result->{'vm'}{'valid'}{'status'} = "Validation successful";
	}
	else{
		$result->{'vm'}{'valid'}{'state'} = 0;
		$result->{'vm'}{'valid'}{'status'} = "Validation failed";
	}
	
	#
	# check resources
	#
	log_info($ffid, "validation results");
	json_encode_pretty($result);
		
	return json_encode($result);
}

#
# delete and remove system [JSON-STR]
#
sub hyper_delete($json){
	my $fid = "[hyper_delete]";
	my $ffid = "HYPER|DELETE";
	my $result;
	my $execute = 1;	
	my $vm_state = 1;
	my $success = 1;
	my $system = $json->{'hyper'}{'vm'};
	
	$result = packet_build_noencode("1", "success: reached delete function", $fid);
	
	# check if system has access to the storage
	if($system->{'meta'}{'state'} || ($system->{'state'}{'vm_state'} eq "1") || ($system->{'state'}{'vm_running'}) || ($system->{'state'}{'vmm_state'} eq "1") || ($system->{'state'}{'vm_lock'} eq "1")){
		log_info($ffid, "system is marked online!");
		$result->{'vm'}{'running'} = 1;
		$result->{'vm'}{'status'} = "VM IS MARKED RUNNING! CANNOT DELETE!";
		$success = 0;
	}
	else{
		log_info($ffid, "system is NOT marked online!");
		$result->{'vm'}{'running'} = 0;
		$result->{'vm'}{'status'} = "VM IS NOT MARKED RUNNING! CAN DELETE!";
		$vm_state = 0;
	}

	#
	# validate storage
	#
	my @stor_index = index_split($system->{'stor'}{'disk'});
	
	foreach my $dev (@stor_index){
		my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
		
		# check for valid format
		if($file =~ ".qcow2" || $file =~ ".raw"){
			log_info($ffid, "checking storage [$dev] path [$file]: success: file format is supported");
		}
		else{
			log_info($ffid, "checking storage [$dev] path [$file]: success: file format is not supported");
			$success = 0;
		}
		
		# check if storage exist
		if(file_check($file)){
			# exists
			
			if(system_lockfile_check($system->{'stor'}{$dev})){
				# storage is locked
				log_info($ffid, "checking storage [$dev] path [$file]: lockfile exists!");
				$success = 0;
				
				$result->{'vm'}{'storage'}{$dev}{'check'}{'valid'} = 1;
				$result->{'vm'}{'storage'}{$dev}{'check'}{'result'} = "error: storage [$dev] lockfile exists!";
			}
			else{
				# storage is not locked
				log_info($ffid, "checking storage [$dev] path [$file]: lockfile does not exist!");
				
				$result->{'vm'}{'storage'}{$dev}{'check'}{'valid'} = 1;
				$result->{'vm'}{'storage'}{$dev}{'check'}{'result'} = "success: storage [$dev] exists. not locked.";
			}
			
		}
		else{
			# storage device does not exist
			log_info($ffid, "checking storage [$dev] path [$file]: does not exist!");
			
			$result->{'vm'}{'storage'}{$dev}{'check'}{'valid'} = 0;
			$result->{'vm'}{'storage'}{$dev}{'check'}{'result'} = "warning: storage [$dev] does not exist!";
		}
	}

	# handle multiple dirs
	my $dir_index = "";

	#
	# check for success
	#
	if($success){
		# sanity passed. can delete.

		#
		# remove files
		#
		my @stor_index = index_split($system->{'stor'}{'disk'});
		
		foreach my $dev (@stor_index){
			log_warn($ffid, "deleting storage dev [$dev]: dir [$system->{'stor'}{$dev}{'dev'}] file [$system->{'stor'}{$dev}{'image'}]");
			
			$result->{'vm'}{'delete'}{$dev}{'dir'} = $system->{'stor'}{$dev}{'dev'};
			$result->{'vm'}{'delete'}{$dev}{'file'} = $system->{'stor'}{$dev}{'image'};
			
			# add dir to index
			$dir_index = index_add($dir_index, $system->{'stor'}{$dev}{'dev'});
			
			my $file = $system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'};
			#print "  PATH [$file]\n\n";
			log_info($ffid, "path [$file]");
			
			if($execute){
				log_warn($ffid, "attempting to delete file [$file]!");
				my $del_result = file_del($file);
				
				if($del_result){
					log_info($ffid, "file [$file] remove failed! result [$del_result]");
					$result->{'vm'}{'delete'}{$dev}{'result'} = "remove failed!";
					$result->{'vm'}{'delete'}{$dev}{'error'} = $del_result;
				}
				else{
					log_info($ffid, "file [$file] remove successfully");
					$result->{'vm'}{'delete'}{$dev}{'result'} = "removed successfully"
				}
			
			}
		}
		
		#
		# delete system dir
		#
		log_info($ffid, "directory index [$dir_index]");
		my @dirs = index_split($dir_index);
		
		# process direcotires
		foreach my $dir (@dirs){
			
			# check if dir is emplty
			my @files = file_list($dir, "*");
			log_info($ffid, "attempting to remove dir [$dir] - file list:");
			print "@files\n";
			
			my $warn = 0;
			 
			my $file_num = @files;
			log_info($ffid, "dir file number [$file_num]");
			$result->{'vm'}{'storage'}{'dir'}{'check'}{'file_num'} = $file_num;

			# cfg file
			my $cfg_file = $dir . $system->{'id'}{'name'} . "." . $system->{'id'}{'id'} . ".cfg";
			
			# only cfg file should remain
			if($file_num <= 1){
				log_info($ffid, "expected number of files in system direcotry. continuing..");
				
				# make sure config file is last file remaining
				foreach my $file (@files){
					log_info($ffid, "analyzing file [$file]");
					
					if($file eq $cfg_file){
						$result->{'vm'}{'delete'}{'dir'} = "success: system directory remove successfully.";
						$result->{'vm'}{'storage'}{'dir'}{'check'}{'expected_files'} = 1;
						$result->{'vm'}{'storage'}{'dir'}{'check'}{'will_remove'} = 1;
						
						# remove config file
						log_info($ffid, "cfg file [$file] is expected. removing..");
						
						if($execute){
						
							my $del_result = file_del($file);
							
							if($del_result){
								log_warn($ffid, "file [$file] remove failed! result [$del_result]");
								$result->{'vm'}{'delete'}{'cfg'}{'result'} = "remove failed!";
								$result->{'vm'}{'delete'}{'cfg'}{'error'} = $del_result;
								
							}
							else{
								log_info($ffid, "file [$file] remove successfully");
								$result->{'vm'}{'delete'}{'cfg'}{'result'} = "removed successfully";
							}
						
							log_info($ffid, "directory to remove [$dir]");
						
							# remove the directory (non recursive!)
							my $dir_del_result = dir_remove($dir);
							
							log_info($ffid, "directory delete result [$dir_del_result]");
							
							if($dir_del_result == 1){
								log_info($ffid, "success: removed directory [$dir]");
								$result->{'vm'}{'delete'}{'directory'}{'result'} = "removed successfully";
							}
							else{
								log_info($ffid, "error: failed to remove directory [$dir]");
								$result->{'vm'}{'delete'}{'directory'}{'result'} = "removed failed";
							}

						}
					}
					else{
						$result->{'vm'}{'storage'}{'dir'}{'check'}{'expected_files'} = 0;
						$result->{'vm'}{'storage'}{'dir'}{'check'}{'will_remove'} = 0;
						
						log_warn($ffid, "WARNING FILE [$file] is not expected. cancelling dir removal!");
						$result->{'vm'}{'delete'}{'dir'} = "warning: unexpected files in system directory. cancelling dir removal.";
					}
				}
			}
			else{
				log_warn($ffid, "warning: more files in dir than expected. cancelling removal");
				$result->{'vm'}{'delete'}{'dir'} = "warning: more files in dir than expected. cancelling dir removal.";
			}
			
		}
		
		$result->{'vm'}{'delete'}{'result'} = 1;
		$result->{'vm'}{'delete'}{'status'} = "System [$system->{'id'}{'name'}] deleted successfully";
	}	
	else{
		# requirements failed.
		$result->{'vm'}{'delete'}{'result'} = 0;
		$result->{'vm'}{'delete'}{'status'} = "System [$system->{'id'}{'name'}] delete failed!";
	}
	
	return json_encode($result);
}

#
# get qemu version
#
sub hyper_qemu_version(){
    my $fid = "[hypervisor_qemu_version]";
    my $ffid = "QEMU|VERSION";
    my $exec = 'qemu-system-x86_64 --version | grep version';

	my $hyperdb = hyper_db_obj_get("hyper");
	$hyperdb->{'qemu'}{'enabled'} = 0;
	$hyperdb->{'qemu'}{'version'} = "";	
    
    # execute qemu version command
    my $result = execute($exec);
    
    if($result){
		chomp($result);
		
		if($result =~ "QEMU emulator version"){
			$result =~ s/QEMU emulator version //g;
			
			log_info($ffid, "qemu version [$result]");
			my $hyperdb = hyper_db_obj_get("hyper");
			$hyperdb->{'qemu'}{'enabled'} = 1;
			$hyperdb->{'qemu'}{'version'} = $result;
		}
		else{
			log_warn($ffid, "error: failed to get qemu version [$result]");
		}	
	}
	else{
		log_warn($ffid, "error: failed to execute command");
	}

	hyper_db_obj_set("hyper", $hyperdb);
}

#
# validate vm structure [JSON-OBJ]
#
sub hyper_validate_vm_structure($vm_data) {
    my $fid = "hypervisor_validate_vm_structure";
    my $ffid = "HYPERVISOR|VALIDATION|VM|STRUCTURE";
    my $validation_result = {
        valid => 1,
        errors => [],
        warnings => [],
        details => {}
    };
    
    log_debug($ffid, "starting VM structure validation");
    
    # basic existence check
    unless ($vm_data) {
        push @{$validation_result->{errors}}, "VM data is undefined";
        $validation_result->{valid} = 0;
        log_error($ffid, "VM data is undefined");
        return $validation_result;
    }
    
    # ID section validation
    unless ($vm_data->{'id'}) {
        push @{$validation_result->{errors}}, "Missing 'id' section";
        $validation_result->{valid} = 0;
    } else {
        # validate ID fields
        unless ($vm_data->{'id'}{'id'}) {
            push @{$validation_result->{errors}}, "Missing 'id.id' field";
            $validation_result->{valid} = 0;
        } else {
            my $vm_id = $vm_data->{'id'}{'id'};
            $validation_result->{details}{id} = $vm_id;
            
            # ID format validation
            unless ($vm_id =~ /^[a-zA-Z0-9\-_\.]+$/) {
                push @{$validation_result->{errors}}, "Invalid VM ID format: $vm_id (only alphanumeric, dash, underscore, dot allowed)";
                $validation_result->{valid} = 0;
            }
            
            # ID length validation
            if (length($vm_id) > 64) {
                push @{$validation_result->{warnings}}, "VM ID is very long: $vm_id (length: " . length($vm_id) . ")";
            }
        }
        
        # name field (optional but recommended)
        unless ($vm_data->{'id'}{'name'}) {
            push @{$validation_result->{warnings}}, "Missing 'id.name' field (optional but recommended)";
            $vm_data->{'id'}{'name'} = $vm_data->{'id'}{'id'} || 'unknown';
        }
    }
    
    # hardware section validation
    unless ($vm_data->{'hw'}) {
        push @{$validation_result->{warnings}}, "Missing 'hw' section (will use defaults)";
        $vm_data->{'hw'} = {};
    } else {
        # CPU validation
        if ($vm_data->{'hw'}{'cpu'}) {
            unless (looks_like_number($vm_data->{'hw'}{'cpu'}{'core'})) {
                push @{$validation_result->{errors}}, "Invalid CPU core count: " . ($vm_data->{'hw'}{'cpu'}{'core'} || 'undefined');
                $validation_result->{valid} = 0;
            } else {
                my $cpu_cores = $vm_data->{'hw'}{'cpu'}{'core'};
                if ($cpu_cores < 1) {
                    push @{$validation_result->{errors}}, "CPU core count must be at least 1, got: $cpu_cores";
                    $validation_result->{valid} = 0;
                }
                if ($cpu_cores > 128) {
                    push @{$validation_result->{warnings}}, "CPU core count is very high: $cpu_cores";
                }
            }
            
            # socket validation (optional)
            if (exists $vm_data->{'hw'}{'cpu'}{'sock'}) {
                unless (looks_like_number($vm_data->{'hw'}{'cpu'}{'sock'})) {
                    push @{$validation_result->{warnings}}, "Invalid CPU socket count, using default";
                    $vm_data->{'hw'}{'cpu'}{'sock'} = 1;
                }
            } else {
                $vm_data->{'hw'}{'cpu'}{'sock'} = 1;
            }
        } else {
            push @{$validation_result->{warnings}}, "Missing 'hw.cpu' section (will use defaults)";
            $vm_data->{'hw'}{'cpu'} = { core => 1, sock => 1 };
        }
        
        # memory validation
        if ($vm_data->{'hw'}{'mem'}) {
            unless (looks_like_number($vm_data->{'hw'}{'mem'}{'mb'})) {
                push @{$validation_result->{errors}}, "Invalid memory size (MB): " . ($vm_data->{'hw'}{'mem'}{'mb'} || 'undefined');
                $validation_result->{valid} = 0;
            } else {
                my $mem_mb = $vm_data->{'hw'}{'mem'}{'mb'};
                if ($mem_mb < 128) {
                    push @{$validation_result->{warnings}}, "Memory size is very low: ${mem_mb}MB (minimum 128MB recommended)";
                }
                if ($mem_mb > 1048576) { # 1TB
                    push @{$validation_result->{warnings}}, "Memory size is very high: ${mem_mb}MB (1TB+)";
                }
            }
        } else {
            push @{$validation_result->{warnings}}, "Missing 'hw.mem' section (will use defaults)";
            $vm_data->{'hw'}{'mem'} = { mb => 1024 }; # 1GB default
        }
    }
    
    # storage section validation
    unless ($vm_data->{'stor'}) {
        push @{$validation_result->{warnings}}, "Missing 'stor' section (no storage devices)";
        $vm_data->{'stor'} = {};
    } else {
        # disk index validation
        if ($vm_data->{'stor'}{'disk'}) {
            my @disk_index = index_split($vm_data->{'stor'}{'disk'});
            $validation_result->{details}{disk_count} = scalar @disk_index;
            
            foreach my $dev (@disk_index) {
                unless ($vm_data->{'stor'}{$dev}) {
                    push @{$validation_result->{errors}}, "Missing storage device definition for: $dev";
                    $validation_result->{valid} = 0;
                    next;
                }
                
                # device path validation
                unless ($vm_data->{'stor'}{$dev}{'dev'}) {
                    push @{$validation_result->{errors}}, "Missing 'dev' path for storage device: $dev";
                    $validation_result->{valid} = 0;
                }
                
                # image file validation
                unless ($vm_data->{'stor'}{$dev}{'image'}) {
                    push @{$validation_result->{errors}}, "Missing 'image' filename for storage device: $dev";
                    $validation_result->{valid} = 0;
                }
                
                # format validation (optional)
                if ($vm_data->{'stor'}{$dev}{'format'} && 
                    $vm_data->{'stor'}{$dev}{'format'} !~ /^(qcow2|raw|vmdk|vdi)$/) {
                    push @{$validation_result->{warnings}}, "Unusual storage format for $dev: " . $vm_data->{'stor'}{$dev}{'format'};
                }
            }
        }
        
        # ISO index validation
        if ($vm_data->{'stor'}{'iso'}) {
            my @iso_index = index_split($vm_data->{'stor'}{'iso'});
            $validation_result->{details}{iso_count} = scalar @iso_index;
            
            foreach my $iso (@iso_index) {
                unless ($vm_data->{'stor'}{$iso}) {
                    push @{$validation_result->{warnings}}, "Missing ISO definition for: $iso";
                    next;
                }
                
                # ISO path validation
                unless ($vm_data->{'stor'}{$iso}{'dev'}) {
                    push @{$validation_result->{warnings}}, "Missing 'dev' path for ISO: $iso";
                }
                
                unless ($vm_data->{'stor'}{$iso}{'image'}) {
                    push @{$validation_result->{warnings}}, "Missing 'image' filename for ISO: $iso";
                }
            }
        }
    }
    
    # network section validation
    unless ($vm_data->{'net'}) {
        push @{$validation_result->{warnings}}, "Missing 'net' section (no network interfaces)";
        $vm_data->{'net'} = {};
    } else {
        # network device index validation
        if ($vm_data->{'net'}{'dev'}) {
            my @net_index = index_split($vm_data->{'net'}{'dev'});
            $validation_result->{details}{network_count} = scalar @net_index;
            
            foreach my $dev (@net_index) {
                unless ($vm_data->{'net'}{$dev}) {
                    push @{$validation_result->{warnings}}, "Missing network device definition for: $dev";
                    next;
                }
                
                # Network type validation
                unless ($vm_data->{'net'}{$dev}{'type'}) {
                    push @{$validation_result->{warnings}}, "Missing 'type' for network device: $dev";
                    $vm_data->{'net'}{$dev}{'type'} = 'bridge'; # default
                }
                
                # Network ID validation
                unless ($vm_data->{'net'}{$dev}{'net'} && $vm_data->{'net'}{$dev}{'net'}{'id'}) {
                    push @{$validation_result->{warnings}}, "Missing network ID for device: $dev";
                }
                
                # MAC address validation (optional)
                if ($vm_data->{'net'}{$dev}{'mac'}) {
                    my $mac = $vm_data->{'net'}{$dev}{'mac'};
                    unless ($mac =~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) {
                        push @{$validation_result->{warnings}}, "Invalid MAC address format for $dev: $mac";
                    }
                }
            }
        }
    }
    
    # meta section validation (optional)
    if ($vm_data->{'meta'}) {
        # state validation
        if (exists $vm_data->{'meta'}{'state'}) {
            unless ($vm_data->{'meta'}{'state'} =~ /^[01]$/) {
                push @{$validation_result->{warnings}}, "Invalid meta.state value: " . $vm_data->{'meta'}{'state'};
                $vm_data->{'meta'}{'state'} = 0;
            }
        }
        
        # migration validation
        if (exists $vm_data->{'meta'}{'migrate'}) {
            unless ($vm_data->{'meta'}{'migrate'} =~ /^[01]$/) {
                push @{$validation_result->{warnings}}, "Invalid meta.migrate value: " . $vm_data->{'meta'}{'migrate'};
                $vm_data->{'meta'}{'migrate'} = 0;
            }
        }
    } else {
        $vm_data->{'meta'} = {};
    }
    
    # object section validation (optional)
    if ($vm_data->{'object'}) {
        # init state validation
        if (exists $vm_data->{'object'}{'init'}) {
            unless ($vm_data->{'object'}{'init'} =~ /^[01]$/) {
                push @{$validation_result->{warnings}}, "Invalid object.init value: " . $vm_data->{'object'}{'init'};
                $vm_data->{'object'}{'init'} = 0;
            }
        }
    }
    
    # log validation results
    if ($validation_result->{valid}) {
        if (@{$validation_result->{errors}}) {
            log_error($ffid, "VM structure validation completed with errors: " . 
                     join(", ", @{$validation_result->{errors}}));
        } elsif (@{$validation_result->{warnings}}) {
            log_warn($ffid, "VM structure validation completed with warnings: " . 
                    join(", ", @{$validation_result->{warnings}}));
        } else {
            log_info($ffid, "VM structure validation passed successfully");
        }
    } else {
        log_error($ffid, "VM structure validation failed: " . 
                 join(", ", @{$validation_result->{errors}}));
    }
    
    # add summary to details
    $validation_result->{details}{error_count} = scalar @{$validation_result->{errors}};
    $validation_result->{details}{warning_count} = scalar @{$validation_result->{warnings}};
    
    return $validation_result;
}

#
# validate vm operation preconditions [JSON-OBJ]
#
sub hyper_validate_operation_preconditions($operation, $vm_id, $expected_state) {
    my $fid = "hypervisor_validate_operation_preconditions";
    my $ffid = "HYPERVISOR|VALIDATION|PRECONDITIONS|$operation";
    my $validation_result = {
        valid => 1,
        operation => $operation,
        vm_id => $vm_id,
        expected_state => $expected_state,
        errors => [],
        details => {}
    };
    
    log_debug($ffid, "validating preconditions for operation: $operation, VM: $vm_id, expected state: $expected_state");
    
    my $hyperdb = hyper_db_obj_get("hyper");
    
    # check VM exists in database (except for certain operations)
    my $vm_exists = index_find($hyperdb->{'vm'}{'index'}, $vm_id);
    $validation_result->{details}{in_database} = $vm_exists ? 1 : 0;
    
    # for operations that can work with new VMs (like ASYNC_LOAD), don't require VM to exist
    my @operations_allowing_new_vms = qw(ASYNC_LOAD LOAD PUSH);
    
    if (!$vm_exists && !grep { $_ eq $operation } @operations_allowing_new_vms) {
        push @{$validation_result->{errors}}, "VM $vm_id not found in database";
        $validation_result->{valid} = 0;
        log_error($ffid, "Precondition failed: VM $vm_id not in database");
        return $validation_result;
    }
    
    # if VM exists, get it for further validation
    my $vm = $vm_exists ? $hyperdb->{'db'}{$vm_id} : undef;
    
    # check lock state if required
    # we can check lock state even if VM doesn't exist in database yet
    my $is_locked = index_find($hyperdb->{'vm'}{'lock'}, $vm_id) ? 1 : 0;
    $validation_result->{details}{locked} = $is_locked;
    
    if ($expected_state eq "locked" || $expected_state eq "online") {
        unless ($is_locked) {
            push @{$validation_result->{errors}}, "VM $vm_id is not locked (expected: $expected_state)";
            $validation_result->{valid} = 0;
            log_error($ffid, "Precondition failed: VM $vm_id not locked");
        }
    } elsif ($expected_state eq "unlocked") {
        if ($is_locked) {
            push @{$validation_result->{errors}}, "VM $vm_id is locked (expected: $expected_state)";
            $validation_result->{valid} = 0;
            log_error($ffid, "Precondition failed: VM $vm_id is locked (expected: unlocked)");
        }
    }
    
    # Check online state if required (only if VM exists)
    if ($vm) {
        if ($expected_state eq "online") {
            unless ($vm->{'meta'}{'state'}) {
                push @{$validation_result->{errors}}, "VM $vm_id not online (expected: online)";
                $validation_result->{valid} = 0;
                $validation_result->{details}{online} = 0;
                log_error($ffid, "Precondition failed: VM $vm_id not online");
            } else {
                $validation_result->{details}{online} = 1;
            }
        } elsif ($expected_state eq "offline") {
            if ($vm->{'meta'}{'state'}) {
                push @{$validation_result->{errors}}, "VM $vm_id is online (expected: offline)";
                $validation_result->{valid} = 0;
                $validation_result->{details}{online} = 1;
                log_error($ffid, "Precondition failed: VM $vm_id is online (expected: offline)");
            } else {
                $validation_result->{details}{online} = 0;
            }
        }
        
        # Check migration state if required
        if ($expected_state eq "migrating") {
            unless ($vm->{'meta'}{'migrate'}) {
                push @{$validation_result->{errors}}, "VM $vm_id not migrating (expected: migrating)";
                $validation_result->{valid} = 0;
                $validation_result->{details}{migrating} = 0;
                log_error($ffid, "Precondition failed: VM $vm_id not migrating");
            } else {
                $validation_result->{details}{migrating} = 1;
            }
        }
    } else {
        # VM doesn't exist yet, can't check online/migration state
        if ($expected_state eq "online" || $expected_state eq "offline" || $expected_state eq "migrating") {
            # For new VMs, these states don't apply yet
            $validation_result->{details}{online} = 0;
            $validation_result->{details}{migrating} = 0;
        }
    }
    
    # log validation results
    if ($validation_result->{valid}) {
        log_info($ffid, "Precondition validation passed for operation: $operation, VM: $vm_id");
    } else {
        log_error($ffid, "Precondition validation failed for operation: $operation, VM: $vm_id - " . 
                 join(", ", @{$validation_result->{errors}}));
    }
    
    return $validation_result;
}

1;
