#
# ETHER|AAPEN|HYPERVISOR - LIB|ASYNC
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
# process async jobs [JSON-OBJ]
#
sub async_job_check(){
	my $fid = "[async_job_check]";
	my $ffid = "ASYNC|JOB|CHECK";
	my $result = 0;
	
	my $hyperdb = hyper_db_obj_get("hyper");
	my @async_index = index_split($hyperdb->{'vm'}{'async'}{'index'});
	
	#
	# process job index
	#
	foreach my $async (@async_index){
		if($hyperdb->{'vm'}{'async'}{$async}{'active'} eq "1"){
			my $diff = date_str_diff_now($hyperdb->{'vm'}{'async'}{$async}{'date'});
			
			log_info("ASYNC|JOB", "jobs waiting - id [$async] req [$hyperdb->{'vm'}{'async'}{$async}{'request'}] status [$hyperdb->{'vm'}{'async'}{$async}{'status'}] result [$hyperdb->{'vm'}{'async'}{$async}{'result'}] delta [$diff]");
			json_encode_pretty($hyperdb->{'vm'}{'async'}{$async});
			$result = 1;
		}
	}
	
	return $result;
}

#
# hypervisor info [JSON-STR]
#
sub async_system_load($req){
	my $fid = "[async_system_load]";
	my $ffid = "ASYNC|SYSTEM|LOAD";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;
	
	if(env_debug()){
		print "[" . date_get() . "] $fid received request\n";
		json_encode_pretty($req);
	}
	
	# get system id and data
	my $id = $req->{'hyper'}{'id'};
	my $sysdata = $req->{'hyper'}{'vm'};
	
	# validate VM structure if VM data is provided
	if ($sysdata) {
		my $validation = hyper_validate_vm_structure($sysdata);
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
	}
	
	# validate operation preconditions
	my $preconditions = hyper_validate_operation_preconditions("ASYNC_LOAD", $id, "unlocked");
	unless ($preconditions->{valid}) {
		log_error($ffid, "Async load operation preconditions failed: " . 
		         join(", ", @{$preconditions->{errors}}));
		return packet_build_encode("0", "error: preconditions not met for async load: " . 
		         join(", ", @{$preconditions->{errors}}), $ffid);
	}

	# check if system online
	if(!index_find($hyperdb->{'vm'}{'lock'}, $id)){
		# not found
	
		my $pushtmp = hyper_push($req);
		my $pushresult = json_decode($pushtmp);
		
		if(env_debug()){
			print "[" . date_get() . "] $fid push result\n";
			json_encode_pretty($pushresult);
		}
		
		if($pushresult->{'proto'}{'result'} eq "1"){
		
			# update database
			my $hyperdb = hyper_db_obj_get("hyper");
		
			$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $id);
			
			$hyperdb->{'vm'}{'async'}{$id}{'request'} = "load";
			$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
			$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "120";
			$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "give_up";
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "init";
			$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
			$hyperdb->{'vm'}{'async'}{$id}{'result'} = "waiting";
			$hyperdb->{'vm'}{'async'}{$id}{'id'} = $id;
			
			hyper_db_obj_set("hyper", $hyperdb);
			$result = packet_build_encode("1", "success: system id [$id] load requested", $fid);
		}
		else{
			$result = packet_build_encode("0", "failed: system id [$id] failed to push", $fid);
			$result->{'pushresult'} = $pushresult;
		}
	}
	else{
		# found
		log_error($fid, "error: system already loaded");
		$result = packet_build_encode("0", "error: system id [$id] already loaded", $fid);
	}
	
	return $result;
}

#
# hypervisor info [JSON-STR]
#
sub async_system_unload($req){
	my $fid = "[async_system_unload]";
	my $ffid = "ASYNC|SYSTEM|UNLOAD";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;
	
	# get system id
	my $id = $req->{'hyper'}{'id'};
	
	# validate operation preconditions
	my $preconditions = hyper_validate_operation_preconditions("ASYNC_UNLOAD", $id, "locked");
	unless ($preconditions->{valid}) {
		log_error($ffid, "Async unload operation preconditions failed: " . 
		         join(", ", @{$preconditions->{errors}}));
		return packet_build_encode("0", "error: preconditions not met for async unload: " . 
		         join(", ", @{$preconditions->{errors}}), $ffid);
	}

	# check if system online
	if(index_find($hyperdb->{'vm'}{'lock'}, $id)){
		
		# check vmm health
		my $vmmcheck = hyper_vmm_check($req);
		
		if($vmmcheck->{'proto'}{'result'} eq "1"){
			# vmm responded
			
			$result = packet_build_noencode("1", "success: system id [$id] checks succeeded", $fid);
			$result->{'vmcheck'} = $vmmcheck;
			
			$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $id);
			
			$hyperdb->{'vm'}{'async'}{$id}{'request'} = "unload";
			$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
			$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "120";
			$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "wait";
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "init";
			$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
			$hyperdb->{'vm'}{'async'}{$id}{'result'} = "waiting";
			$hyperdb->{'vm'}{'async'}{$id}{'id'} = $id;

			hyper_db_obj_set("hyper", $hyperdb);
		}
		else{
			$result = packet_build_noencode("0", "error: system id [$id] checks failed", $fid);
			$result->{'vmcheck'} = $vmmcheck;
		}
	}
	else{
		$result = packet_build_noencode("0", "error: system id [$id] not online", $fid);
	}

	return json_encode($result);
}

#
# hypervisor info [JSON-STR]
#
sub async_system_shutdown($req){
	my $fid = "[async_system_shutdown]";
	my $ffid = "ASYNC|SYSTEM|SHUTDOWN";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;
	
	if(env_verbose()){
		print "[" . date_get() . "] $fid received request\n";
		json_encode_pretty($req);
	}
	
	# get system id
	my $id = $req->{'hyper'}{'id'};

	# check if system online
	if(index_find($hyperdb->{'vm'}{'lock'}, $id)){
		
		# check vmm health
		my $vmmcheck = hyper_vmm_check($req);
		
		if($vmmcheck->{'proto'}{'result'} eq "1"){
			# vmm responded
			
			$result = packet_build_noencode("1", "success: system id [$id] checks succeeded", $fid);
			$result->{'vmcheck'} = $vmmcheck;
			
			my $unloadresult = api_vmm_local_shutdown($hyperdb->{'db'}{$id});
			
			$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $id);
			
			$hyperdb->{'vm'}{'async'}{$id}{'request'} = "shutdown";
			$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
			$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "600";
			$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "wait";
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "init";
			$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
			$hyperdb->{'vm'}{'async'}{$id}{'result'} = "waiting";
			$hyperdb->{'vm'}{'async'}{$id}{'id'} = $id;
			
			hyper_db_obj_set("hyper", $hyperdb);
		}
		else{
			$result = packet_build_noencode("0", "error: system id [$id] checks failed", $fid);
			$result->{'vmcheck'} = $vmmcheck;
		}
	}
	else{
		$result = packet_build_noencode("0", "error: system id [$id] not online", $fid);
	}

	return json_encode($result);
}

#
# hypervisor info [JSON-STR]
#
sub async_system_clone($req){
	my $fid = "[async_system_clone]";
	my $ffid = "ASYNC|SYSTEM|CLONE";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;
	
	if(env_verbose()){
		print "[" . date_get() . "] $fid received request\n";
		json_encode_pretty($req);
	}
	
	my $src_system = $req->{'hyper'}{'src'};
	my $dst_system = $req->{'hyper'}{'dst'};
	
	log_info($fid, "source image:");
	json_encode_pretty($src_system);
	log_info($fid, "destination image:");
	json_encode_pretty($dst_system);
	
	# run clone checks
	my $clone_stor_checks = system_stoarge_clone_checks($src_system, $dst_system);
	
	if($clone_stor_checks->{'proto'}{'result'} eq "1"){
								
		$result = packet_build_noencode("1", "success: cloning initializing", $fid);
		$result->{'clone_checks'} = $clone_stor_checks;
					
		my $id = $dst_system->{'id'}{'id'};
		
		$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $id);
			
		$hyperdb->{'vm'}{'async'}{$id}{'request'} = "clone";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "3600";
		$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "wait";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system cloning initialized";
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "waiting for async to complete";
		$hyperdb->{'vm'}{'async'}{$id}{'id'} = $id;
		
		$hyperdb->{'vm'}{'async'}{$id}{'src'} = $src_system;
		$hyperdb->{'vm'}{'async'}{$id}{'dst'} = $dst_system;
		
		hyper_db_obj_set("hyper", $hyperdb);				
	}
	else{
		$result = packet_build_noencode("0", "failed: storage requirements failed", $fid);
		$result->{'clone_checks'} = $clone_stor_checks;
	}	

	return json_encode($result);
}

#
# hypervisor info [JSON-STR]
#
sub async_system_move($req){
	my $fid = "[async_system_move]";
	my $ffid = "ASYNC|SYSTEM|MOVE";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;
	
	if(env_verbose()){
		print "[" . date_get() . "] $fid received request\n";
		json_encode_pretty($req);
	}
	
	my $src_system = $req->{'hyper'}{'src'};
	my $dst_system = $req->{'hyper'}{'dst'};
	
	if(env_debug()){
		print "[" . date_get() . "] $fid source image\n";
		json_encode_pretty($src_system);
	
		print "[" . date_get() . "] $fid destination image\n";
		json_encode_pretty($dst_system);
	}

	# run storage checks
	my $clone_stor_checks = system_stoarge_clone_checks($src_system, $dst_system);
	
	if($clone_stor_checks->{'proto'}{'result'} eq "1"){
					
		$result = packet_build_noencode("1", "success: move initializing", $fid);
		$result->{'clone_checks'} = $clone_stor_checks;
					
		my $id = $dst_system->{'id'}{'id'};
			
		$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $id);
			
		$hyperdb->{'vm'}{'async'}{$id}{'request'} = "move";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "3600";
		$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "wait";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system move initialized";
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "waiting for async to complete";
		$hyperdb->{'vm'}{'async'}{$id}{'id'} = $id;
		
		$hyperdb->{'vm'}{'async'}{$id}{'src'} = $src_system;
		$hyperdb->{'vm'}{'async'}{$id}{'dst'} = $dst_system;
		
		hyper_db_obj_set("hyper", $hyperdb);				
	}
	else{
		$result = packet_build_noencode("0", "failed: storage requirements failed", $fid);
		$result->{'clone_checks'} = $clone_stor_checks;
	}	

	return json_encode($result);
}

#
# hypervisor info [JSON-STR]
#
sub async_system_migrate($req){
	my $fid = "[async_system_migrate]";
	my $ffid = "ASYNC|SYSTEM|MIGRATE";
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;
	
	if(env_debug()){
		print "[" . date_get() . "] $fid received request\n";
		json_encode_pretty($req);
	}
	
	# get system id and data
	my $sys_id = $req->{'hyper'}{'sys_id'};
	my $src_node_id = $req->{'hyper'}{'src_node_id'};
	my $dest_node_id = $req->{'hyper'}{'dest_node_id'};
	
	# check if system online
	if(index_find($hyperdb->{'vm'}{'lock'}, $sys_id)){
		# system loaded

		if($src_node_id eq config_node_id_get()){
			$result = packet_build_noencode("1", "success: migration initializing", $fid);
				
			$hyperdb->{'vm'}{'async'}{'index'} = index_add($hyperdb->{'vm'}{'async'}{'index'}, $sys_id);
				
			$hyperdb->{'vm'}{'async'}{$sys_id}{'request'} = "migrate";
			$hyperdb->{'vm'}{'async'}{$sys_id}{'date'} = date_get();
			$hyperdb->{'vm'}{'async'}{$sys_id}{'timeout'} = "3600";
			$hyperdb->{'vm'}{'async'}{$sys_id}{'on_timeout'} = "wait";
			$hyperdb->{'vm'}{'async'}{$sys_id}{'status'} = "system migration initialized";
			$hyperdb->{'vm'}{'async'}{$sys_id}{'active'} = "1";
			$hyperdb->{'vm'}{'async'}{$sys_id}{'result'} = "waiting for async to complete";
			$hyperdb->{'vm'}{'async'}{$sys_id}{'id'} = $sys_id;
			
			$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'src_node_id'} = $src_node_id;
			$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'dest_node_id'} = $dest_node_id;
			$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'start_time'} = date_get();
			$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'state'} = "1";
			$hyperdb->{'vm'}{'async'}{$sys_id}{'migrate'}{'status'} = "initializing";
			
			hyper_db_obj_set("hyper", $hyperdb);
			$result = packet_build_encode("0", "success: system id [$sys_id] migration initialized", $fid);
		}
		else{
			# found
			log_error($fid, "error: source node [$src_node_id] and [" . config_node_id_get() . "] mismatch");
			$result = packet_build_encode("0", "error: source node id [$src_node_id] and id [" . config_node_id_get() . "] mismatch!", $fid);	
		}
	}
	else{
		# found
		log_error($fid, "error: system already loaded!");
		$result = packet_build_encode("0", "error: system id [$sys_id] not loaded", $fid);
	}
	
	return $result;
}

1;
