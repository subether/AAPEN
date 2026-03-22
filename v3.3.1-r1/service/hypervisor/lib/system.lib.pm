#
# ETHER|AAPEN|HYPERVISOR - LIB|SYSTEM
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
use Term::ANSIColor qw(:constants);


#
# recover missing systems from cluster [NULL]
#
sub system_cluster_recover(){
	my $fid = "[system_cluster_recover]";
	my $ffid = "SYSTEM|CLUSTER|RECOVER";
	my $result = api_cluster_local_db_get(env_serv_sock_get("cluster"));
	my $hyperdb = hyper_db_obj_get("hyper");
	my $recovered = 0;
	
	# get remote system
	#
	my $sys_idx = $result->{'db'}{'system'}{'index'};
	my @sys_index = index_split($sys_idx);
	my @vm_index = index_split($hyperdb->{'vm'}{'lock'});
	
	#
	# process remote index
	#
	foreach my $sysname (@sys_index){
		my $system = $result->{'db'}{'system'}{'db'}{$sysname};
		
		
		if(defined($system->{'meta'}{'state'})){
	
			# online
			if($system->{'meta'}{'state'} eq "1"){
				# online

				# TODO: CHANGE TO node_name
				if($system->{'meta'}{'node'} eq config_node_name_get()){
					
					# check if system is in local index
					if(index_find($hyperdb->{'vm'}{'lock'}, $system->{'id'}{'id'})){
						log_info($ffid, "[SELF] [OK] system [$system->{'id'}{'name'}] id [$system->{'id'}{'id'}] is known");
					}
					else{
						my $log = "WARNING: system [$sysname] state [", BOLD GREEN, "ONLINE", RESET, "] node [", BOLD, $system->{'meta'}{'node'}, RESET, "] - status [", BOLD RED, "UNKNOWN", RESET, "] - ADDING";
						log_info($ffid, $log);
						my $id = $system->{'id'}{'id'};
						
						# system initializing
						$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
						$hyperdb->{'vm'}{'async'}{$id}{'result'} = "init";
						$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system recovery";
						$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
						
						$hyperdb->{'vm'}{'async'}{$id}{'request'} = "recovery";
						$hyperdb->{'vm'}{'async'}{$id}{'id'} = $id;
						$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "n/a";
						$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "n/a";

						#$hyperdb->{$id} = $system;
						$hyperdb->{'db'}{$id} = $system;
						$hyperdb->{'stats'}{$id} =  $system->{'meta'}{'stats'}{'hypervisor'};

						$hyperdb->{'vm'}{'index'} = index_add($hyperdb->{'vm'}{'index'}, $id);
						$hyperdb->{'vm'}{'lock'} = index_add($hyperdb->{'vm'}{'lock'}, $id);
						
						$hyperdb->{'vm'}{'systems'}++;
						$hyperdb->{'vm'}{'cpualloc'} += $system->{'hw'}{'cpu'}{'core'};
						$hyperdb->{'vm'}{'memalloc'} += $system->{'hw'}{'mem'}{'mb'};
						
						# vnc
						$hyperdb->{'net'}{'vnc'} = index_add($hyperdb->{'net'}{'vnc'}, $system->{'meta'}{'vnc'});
						$hyperdb->{'net'}{'novnc_port'} = index_add($hyperdb->{'net'}{'novnc_port'}, $system->{'meta'}{'novnc_port'});
						$hyperdb->{'net'}{'novnc'} = 1;
						$hyperdb->{'net'}{'monitor'} = index_add($hyperdb->{'net'}{'monitor'}, $system->{'monitor'}{'port'});
						
						$recovered = 1;
					}					
				}
			}
			elsif($system->{'meta'}{'state'} eq "0"){
				# system is offline
			}
		}
	}
	
	# if recovered
	if($recovered){
		hyper_db_obj_set("hyper", $hyperdb);
	}

}

#
#
#
sub system_orphan_check(){
	my $fid = "[system_orphan_check]";
	my $ffid = "SYSTEM|ORPHAN|CHECK";
	my $hyperdb = hyper_db_obj_get("hyper");
	my @vm_index = index_split($hyperdb->{'vm'}{'lock'});

	return system_orphan_check_ps($fid, $hyperdb, @vm_index);
}

#
# check for orphans [NULL]
#
sub system_orphan_check_ps($fid, $hyperdb, @vm_index) {
	my $ffid = "SYSTEM|ORPHAN|CHECK";
	
	log_debug($ffid, "searching for orphans (using ps)");
	
	open my $PS, '-|', 'ps -eo pid,args' or do {
		log_error($ffid, "error: could not run ps command!");
		return 0;
	};
	
	while (my $line = <$PS>) {
		next unless $line =~ /^\s*(\d+)\s+(.+)/;
		my ($pid, $cmdline) = ($1, $2);
		
		system_check_process($fid, $hyperdb, $cmdline, $pid);
	}
	
	close $PS;
	return 0;
}

#
# check for system process [NULL]
#
sub system_check_process_OLD($fid, $hyperdb, $cmdline, $pid) {
	my $ffid = "SYSTEM|PROCESS|CHECK";
	
	# check if vmm
	if($cmdline =~ /vmm\.pl/) {

		if(system_vmm_pid_find($pid)) {
			log_debug($ffid, "found vmm with pid [$pid] - status [HEALTHY]");
		}
		else {
			log_warn($ffid, "found vmm with pid [$pid] - status [ORPHANED]");
		}
	}
	
	# check if qemu
	if($cmdline =~ /qemu-system-x86_64/ && substr($cmdline, 0, 5) ne 'sh -c') {
		
		if(system_vm_pid_find($pid)) {
			log_debug($ffid, "found vm with pid [$pid] - status [HEALTHY]");
		}
		else {
			log_warn($ffid, "found vm with pid [$pid] - status [ORPHANED]");
		}
	}
}

#
# check for system process [NULL]
#
sub system_check_process($fid, $hyperdb, $cmdline, $pid) {
	my $ffid = "SYSTEM|PROCESS|CHECK";
	
	my $orphan = {};
	$orphan->{'found'} = 0;
	
	# check if vmm
	if($cmdline =~ /vmm\.pl/) {

		if(system_vmm_pid_find($pid)) {
			log_debug($ffid, "found vmm with pid [$pid] - status [HEALTHY]");
		}
		else {
			log_warn($ffid, "found vmm with pid [$pid] - status [ORPHANED]");
			$orphan->{'found'} = 1;
			$orphan->{'vmm'}{'pid'} = $pid;
			$orphan->{'vmm'}{'cmdline'} = $cmdline;
			$orphan->{'vmm'}{'found'} = 1;
		}
	}
	
	# check if qemu
	if($cmdline =~ /qemu-system-x86_64/ && substr($cmdline, 0, 5) ne 'sh -c') {
		
		if(system_vm_pid_find($pid)) {
			log_debug($ffid, "found vm with pid [$pid] - status [HEALTHY]");
		}
		else {
			log_warn($ffid, "found vm with pid [$pid] - status [ORPHANED]");
			$orphan->{'found'} = 1;
			$orphan->{'vm'}{'pid'} = $pid;
			$orphan->{'vm'}{'cmdline'} = $cmdline;
			$orphan->{'vm'}{'found'} = 1;
		}
	}
	
	if($orphan->{'found'}){
		system_orphan_analyze($orphan);
	}
	
}

#
#
#
sub system_orphan_analyze($orphan){
	my $fid = "[system_orphan_analyze]";
	
	# check if both the vmm and vm exists
	print "$fid processing orphan...";
	
	# check if both vmm and vm orphans exist
	if($orphan->{'vmm'}{'found'} && $orphan->{'vm'}{'found'}){
		my $vmmexec = substr $orphan->{'vmm'}{'cmdline'}, 0, 12;
		my $vmmsock = substr $orphan->{'vmm'}{'cmdline'}, 13;
	}
	else{
		# mismatch
		
		if($orphan->{'vmm'}{'found'}){
			print "$fid VMM IS ORPHAN\n";
		}
		
		if($orphan->{'vm'}{'found'}){
			print "$fid VM IS ORPHAN\n";			
			# this might be valid...
		}
		
	}
	
}
	
#
# find vmm pid [BOOLEAN]
#
sub system_vmm_pid_find($pid){
	my $fid = "[system_vmm_pid_find]";
	my $ffid = "SYSTEM|VMM|PID|FIND";
	my $hyperdb = hyper_db_obj_get("hyper");
	my @vm_index = index_split($hyperdb->{'vm'}{'lock'});
	
	foreach my $vm (@vm_index){
		if($hyperdb->{'db'}{$vm}{'meta'}{'vmm'}{'pid'} eq $pid){
			return 1;
		}
	}
	
	return 0;
}

#
# find vm pid [BOOLEAN]
#
sub system_vm_pid_find($pid){
	my $fid = "[system_vm_pid_find]";
	my $ffid = "SYSTEM|VM|PID|FIND";
	my $hyperdb = hyper_db_obj_get("hyper");
	my @vm_index = index_split($hyperdb->{'vm'}{'lock'});
	
	foreach my $vm (@vm_index){
		if($hyperdb->{'db'}{$vm}{'meta'}{'pid'} eq $pid){
			return 1;
		}
	}
	
	return 0;
}

#
# check system health and clean broken ones [NULL]
#
sub system_health_check(){
	my $fid = "[system_health_check]";
	my $ffid = "SYSTEM|HEALTH|CHECK";
	
	my $hyperdb = hyper_db_obj_get("hyper");
	my $result;

	log_info($ffid, "------ [ system health check ] ------");

	my @vm_index = index_split($hyperdb->{'vm'}{'lock'});
	
	foreach my $vm (@vm_index){
		my $id = $vm;
		my $vmmsock = $hyperdb->{'db'}{$id}{'meta'}{'vmm'}{'vmmsock'};
		my $vmmdata = api_vmm_local_info_new($vmmsock);
	
		if(env_debug()){
			print "$fid vmm socket [$vmmsock] response\n";
			json_encode_pretty($vmmdata);
		}
	
		#json_encode_pretty($vmmdata);
	
		if($vmmdata->{'vm'}{'state'}{'vm_running'} eq "0"){
			
			if($vmmdata->{'vm'}{'state'}{'vm_status'} eq "shutdown" || $vmmdata->{'vm'}{'state'}{'vm_status'} eq "poweroff"){
				log_info($ffid, "system id [$id] marked as offline but part of a job. deferring.");
			}
			else{
				log_info($ffid, "system id [$id] marked as offline without job flag. starting unload.");
				system_async_unload("[health_check]", $id);
			}
		}
		else{
			# TODO - more system checks
			#log_info($ffid, "vm [" . $hyperdb->{$id}{'id'}{'id'} . "] name [" . $hyperdb->{$id}{'id'}{'name'} . "] - running [" . $vmmdata->{'vm'}{'state'}{'vm_running'} . "] state [" . $vmmdata->{'vm'}{'state'}{'vm_state'} . "] status [" . $vmmdata->{'vm'}{'state'}{'vm_status'} . "] - [HEALTHY]");
		}
	}
}

#
# async check [NULL]
#
sub system_async_check(){
	my $fid = "[system_async_check]";
	my $ffid = "SYSTEM|ASYNC|CHECK";
	my $hyperdb = hyper_db_obj_get("hyper");
	
	# process async jobs
	my @async_index = index_split($hyperdb->{'vm'}{'async'}{'index'});

	log_info($ffid, "------ [ async job check ] ------");

	foreach my $id (@async_index){

		if($hyperdb->{'vm'}{'async'}{$id}{'active'} eq "1"){
			log_info_json($ffid, "async job [$id] is active", $hyperdb->{'vm'}{'async'}{$id});

			# check age
			my $diff = date_str_diff_now($hyperdb->{'vm'}{'async'}{$id}{'date'});

			if($diff > $hyperdb->{'vm'}{'async'}{$id}{'timeout'}){
				log_info($ffid, "async job [$id] status [ACTIVE] age [$diff]: aged out!");
				
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "Timed out: waited $diff seconds";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "request aged out after $diff seconds";
				hyper_db_obj_set("hyper", $hyperdb);
			}
			else{
				log_info($ffid, "async job [$id] status [ACTIVE] age [$diff]: request is active");
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "Not timed out: waited $diff seconds";

				#
				# async unload
				#
				if($hyperdb->{'vm'}{'async'}{$id}{'request'} eq "unload"){
					log_info($ffid, "job type is unload");
					system_async_unload($diff, $id);
				}
				
				#
				# async unload
				#
				if($hyperdb->{'vm'}{'async'}{$id}{'request'} eq "shutdown"){
					log_info($ffid, "job type is shutdown");
					system_async_shutdown($diff, $id);
				}
				
				#
				# async load
				#
				if($hyperdb->{'vm'}{'async'}{$id}{'request'} eq "load"){
					log_info($ffid, "job type is load");
					system_async_load($diff, $id);
				}

				#
				# async clone
				#
				if($hyperdb->{'vm'}{'async'}{$id}{'request'} eq "clone"){
					log_info($ffid, "job type is clone");
					system_async_clone($diff, $id);
				}

				#
				# async clone
				#
				if($hyperdb->{'vm'}{'async'}{$id}{'request'} eq "move"){
					log_info($ffid, "job type is move");
					system_async_move($diff, $id);
				}

				#
				# async clone
				#
				if($hyperdb->{'vm'}{'async'}{$id}{'request'} eq "migrate"){
					log_info($ffid, "job type is migrate");
					system_async_migrate($diff, $id);
				}
				
			}

		}
		else{
			log_debug($ffid, "async request [$id] is not active anymore");
		}
	}
}

#
# system async load [NULL]
#
sub system_async_load($diff, $id){
	my $fid = "[system_async_load]";
	my $ffid = "SYSTEM|ASYNC|LOAD";
	my $hyperdb = hyper_db_obj_get("hyper");
	
	my $req;
	$req->{'hyper'}{'id'} = $id;

	# system initializing
	$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
	$hyperdb->{'vm'}{'async'}{$id}{'result'} = "init";
	$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system initializing";
	$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();

	$hyperdb->{'db'}{$id}{'state'}{'vm_status'} = "init";
			
	hyper_db_obj_set("hyper", $hyperdb);
		
	api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});
		
	my $stats = $hyperdb->{'stats'}{$id};
	$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
	$stats->{'updated'} = date_get();
	
	hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
		
	# load system
	my $loadtmp = hyper_load($req);
	my $loadresult = json_decode($loadtmp);

	if(env_verbose()){ json_encode_pretty($loadresult); };

	if($loadresult->{'proto'}{'result'} eq "1"){
		# sucesss
		log_info($ffid, "system [$id] load succeeded");
		
		$hyperdb = hyper_db_obj_get("hyper");
			
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "System load took $diff seconds";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "System load successful";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
		$hyperdb->{'db'}{$id}{'state'}{'vm_status'} = "loaded";
		
		hyper_db_obj_set("hyper", $hyperdb);
		
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
		
		sleep 1;
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});
	}
	else{
		# failed
		log_info($ffid, "system [$id] load failed! check logs!");
			
		$hyperdb = hyper_db_obj_get("hyper");
			
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system load failed after $diff seconds";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system load failed. check logs";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();

		$hyperdb->{'db'}{$id}{'state'}{'vm_error'} = $loadresult;
		$hyperdb->{'db'}{$id}{'state'}{'vm_status'} = "failed";
		
		hyper_db_obj_set("hyper", $hyperdb);
		
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
		
		sleep 1;
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});
	}		
}

#
# system async shutdown [NULL]
#
sub system_async_shutdown($diff, $id){
	my $fid = "[system_async_unload]";
	my $ffid = "SYSTEM|ASYNC|SHUTDOWN";
	my $hyperdb = hyper_db_obj_get("hyper");

	my $vmmsock = $hyperdb->{'db'}{$id}{'meta'}{'vmm'}{'vmmsock'};
	my $vmmdata = api_vmm_local_info_new($vmmsock);
	
	json_encode_pretty($vmmsock);
	
	if($vmmdata->{'proto'}{'result'} eq "1"){
		log_info_json($ffid, "async unload vm [" . $hyperdb->{'db'}{$id}{'id'}{'id'} . "] name [" . $hyperdb->{'db'}{$id}{'id'}{'name'} . "] - RUNNING [" . $vmmdata->{'vm'}{'state'}{'vm_running'} . "] - STATE [" . $vmmdata->{'vm'}{'state'}{'vm_state'} . "] - STATUS [" . $vmmdata->{'vm'}{'state'}{'vm_status'} . "]", $vmmdata);
		
		if($vmmdata->{'vm'}{'state'}{'vm_running'} eq "0"){
			log_info($ffid, "system id [$id] is marked as offline. starting unload.");

			my $req;
			$req->{'hyper'}{'id'} = $id;
			
			my $result_tmp = hyper_unload($req);
			my $result = json_decode($result_tmp);

			if($result->{'proto'}{'result'} eq "1"){
				log_info($ffid, "system [$id] unload successful");
				
				# update database
				$hyperdb = hyper_db_obj_get("hyper");
				
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "shutdown successful after $diff seconds";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "shutdown completed successfully";
				$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
				
				$hyperdb->{'db'}{$id}{'meta'}{'stats'}{'hypervisor'}{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$hyperdb->{'db'}{$id}{'meta'}{'state'} = "0";
				
				$hyperdb->{'db'}{$id}{'state'}{'vm_status'} = "shutdown";
				
				hyper_db_obj_set("hyper", $hyperdb);
				
				my $stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();
				hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);		
				
				sleep 1;
				
				# update state
				delete $hyperdb->{'db'}{$id}{'state'};
				$hyperdb->{'db'}{$id}{'state'}{'vm_status'} = "shutdown";
				
				$stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();

				# commit to cluster
				sleep 2;
				api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});
				hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
			}
			else{
				log_info($ffid, "system [$id] unload failed! check logs.");
				
				
				# update database
				$hyperdb = hyper_db_obj_get("hyper");
				
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "error: shutdown failed.";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "error: shutdown failed. check logs!";
				$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
				
				hyper_db_obj_set("hyper", $hyperdb);
				
				log_warn_json($ffid, "shutdown failed!", $result);
							
				my $stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();
				
				hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
				api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});
			}
			
		}
		else{
			log_info($ffid, "system [$id] still not marked offline. waited [$diff] of [$hyperdb->{'vm'}{'async'}{$id}{'timeout'}] sec");
			
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "Shutdown: Waited for $diff seconds";
			
			# check for timeout
			if($diff > $hyperdb->{'vm'}{'async'}{$id}{'timeout'}){
				log_warn($ffid, "system [$id] vmm did complete within timeout. destroying it!");
				
				# do a destroy
				my $destroypacket = api_proto_packet_build("hyper", "destroy");
				$destroypacket->{'hyper'}{'vm'} = $hyperdb->{'db'}{$id};

				my $destroyresult = hyper_destroy($destroypacket);
				json_encode_pretty($destroyresult);
				
			}
			
			hyper_db_obj_set("hyper", $hyperdb);
			
			# metadata
			my $stats = $hyperdb->{'stats'}{$id};
			$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
			$stats->{'updated'} = date_get();
			
			hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
			api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});
		}
	
	}
	else{
		log_warn($ffid, "system [$id] vmm did not respond! attempting destroy");

		my $destroypacket = api_proto_packet_build("hyper", "destroy");
		$destroypacket->{'hyper'}{'vm'} = $hyperdb->{'db'}{$id};

		my $destroyresult = hyper_destroy($destroypacket);
		json_encode_pretty($destroyresult);
		
	}
	
}

#
# system async unload [NULL]
#
sub system_async_unload($diff, $id){
	my $fid = "[system_async_shutdown]";
	my $ffid = "SYSTEM|ASYNC|UNLOAD";
	my $hyperdb = hyper_db_obj_get("hyper");

	my $vmmsock = $hyperdb->{'db'}{$id}{'meta'}{'vmm'}{'vmmsock'};
	my $vmmdata = local_vmm_info_new($vmmsock);
	
	log_info($ffid, "unloading vm [" . $hyperdb->{'db'}{$id}{'id'}{'id'} . "] name [" . $hyperdb->{'db'}{$id}{'id'}{'name'} . "] - RUNNING [" . $vmmdata->{'vm'}{'state'}{'vm_running'} . "] - STATE [" . $vmmdata->{'vm'}{'state'}{'vm_state'} . "] - STATUS [" . $vmmdata->{'vm'}{'state'}{'vm_status'} . "]");

	my $req;
	$req->{'hyper'}{'id'} = $id;
	
	my $result_tmp = hyper_unload($req);
	my $result = json_decode($result_tmp);
	
	if($result->{'proto'}{'result'} eq "1"){
		log_info($ffid, "system [$id] unload successful");
		
		# update database
		$hyperdb = hyper_db_obj_get("hyper");
		
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "poweoff successful after $diff seconds";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "poweroff completed successfully";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
		$hyperdb->{'db'}{$id}{'meta'}{'stats'}{'hypervisor'}{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$hyperdb->{'db'}{$id}{'meta'}{'state'} = "0";
		
		$hyperdb->{'db'}{$id}{'state'}{'vm_status'} = "poweroff";
		
		hyper_db_obj_set("hyper", $hyperdb);
		
		log_info($ffid, "system [$id] poweroff successful");

		#
		# metadata
		#
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
		
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});

	}
	else{
		log_warn_json($ffid, "system [$id] unload failed. check logs!", $result);
		
		# update database
		$hyperdb = hyper_db_obj_get("hyper");
		
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "error: shutdown failed.";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "error: shutdown failed. check logs!";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
		hyper_db_obj_set("hyper", $hyperdb);
		
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		
		hyper_system_cdb_meta_set($hyperdb->{'db'}{$id}{'id'}{'name'}, $stats);
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $hyperdb->{'db'}{$id});
	}

}

#
# system async clone [NULL]
#
sub system_async_clone($diff, $id){
	my $fid = "[system_async_clone]";
	my $ffid = "SYSTEM|ASYNC|CLONE";
	my $hyperdb = hyper_db_obj_get("hyper");
	
	# get systems	
	my $src_system = $hyperdb->{'vm'}{'async'}{$id}{'src'};
	my $dst_system = $hyperdb->{'vm'}{'async'}{$id}{'dst'};
	
	$hyperdb = hyper_db_obj_get("hyper");

	# push system to cluster
	$dst_system->{'state'}{'vm_status'} = "cloning_started";
	$dst_system->{'meta'}{'lock'} = "1";
		
	api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);

	sleep 1;
	
	# update state
	$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
	$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system cloning started";
	$hyperdb->{'vm'}{'async'}{$id}{'status'} = "cloning initialized";
	$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
	my $stats = $hyperdb->{'stats'}{$id};
	$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
	$stats->{'updated'} = date_get();
	delete $stats->{'async'}{'src'};
	delete $stats->{'async'}{'dst'};
	
	hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
	api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
	
	log_info_json($ffid, "source system config", $src_system);
	log_info_json($ffid, "destination system config", $dst_system);
		
	my $start = date_get();
	
	my $pool_check_src = hyper_storage_pool_check($src_system);
	
	if($pool_check_src->{'proto'}{'result'} eq "1"){

		my $pool_check_dst = hyper_storage_pool_check($dst_system);
		
		if($pool_check_dst->{'proto'}{'result'} eq "1"){
			
			#
			# create dirs
			#
			my $dir_create = system_storage_dir_create($dst_system);
			
			if($dir_create->{'proto'}{'result'} eq "1"){

				# iterate disks
				my @stor_index = index_split($src_system->{'stor'}{'disk'});

				foreach my $dev (@stor_index){
					log_info($ffid, "DEV [$dev] SOURCE DIR [$src_system->{'stor'}{$dev}{'dev'}] IMG [$src_system->{'stor'}{$dev}{'image'}]");
					log_info($ffid, "DEV [$dev] DEST DIR [$dst_system->{'stor'}{$dev}{'dev'}] IMG [$dst_system->{'stor'}{$dev}{'image'}]");
				
					my $src = $src_system->{'stor'}{$dev}{'dev'} . $src_system->{'stor'}{$dev}{'image'};
					my $dst = $dst_system->{'stor'}{$dev}{'dev'} . $dst_system->{'stor'}{$dev}{'image'};
				
					# copy data
					copy($src, $dst) or do {
						
						my $diff = date_str_diff_now($start);
						
						$hyperdb = hyper_db_obj_get("hyper");
					
						$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
						$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system cloning failed after $diff sec";
						$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system cloning failed. check logs";
						$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
						
						delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
						delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
						
						hyper_db_obj_set("hyper", $hyperdb);
						
						$dst_system->{'state'}{'vm_status'} = "cloning_failed";
				
						# update the VM
						my $stats = $hyperdb->{'stats'}{$id};
						$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
						$stats->{'updated'} = date_get();
						
						hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
						api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
						return;
					}
				 
			   };

				#
				# successful
				#
				my $diff = date_str_diff_now($start);
					
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "cloning completed after $diff seconds";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system cloning completed";
				$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
				
				delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
				delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
									
				$dst_system->{'state'}{'vm_status'} = "cloning_complete";
				$dst_system->{'meta'}{'lock'} = "0";
				$dst_system->{'object'}{'init'} = "1";
				
				hyper_db_obj_set("hyper", $hyperdb);

				# update the VM
				my $stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();
				
				hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);
				api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
			}
			else{
				#
				# failed to create dirs
				#
				
				my $diff = date_str_diff_now($start);
					
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system mkdir create failed after $diff seconds";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system mkdir failed. check logs";
				$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
				
				delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
				delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
					
				hyper_db_obj_set("hyper", $hyperdb);	
				
				$dst_system->{'state'}{'vm_status'} = "cloning_error";
				
				# update the VM
				my $stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();
				
				hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);
				api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
			}

		}
		else{
			#
			# system dest pool not available
			#
			
			my $diff = date_str_diff_now($start);
				
			$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
			$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system destination pool not available";
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system cloning failed. check logs";
			$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
			
			delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
			delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
				
			hyper_db_obj_set("hyper", $hyperdb);	
			
			$dst_system->{'state'}{'vm_status'} = "cloning_error";

			sleep 1;
			
			# update the VM
			my $stats = $hyperdb->{'stats'}{$id};
			$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
			$stats->{'updated'} = date_get();
			
			hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
			api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
		}	

	}
	else{
		#
		# system src pool not available
		#
		
		my $diff = date_str_diff_now($start);
			
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system soruce pool not available";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system cloning failed. check logs";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
		delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
		delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
			
		hyper_db_obj_set("hyper", $hyperdb);	
		
		$dst_system->{'state'}{'vm_status'} = "cloning_error";
		
		# update the VM
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		
		hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
	}	
}

#
# system async migrate [NULL]
#
sub system_async_migrate($diff, $id){
	my $fid = "[system_async_migrate]";
	my $ffid = "SYSTEM|ASYNC|MIGRATE";
	my $hyperdb = hyper_db_obj_get("hyper");
	
	my $system = $hyperdb->{'db'}{$id};
	my $start = date_get();
	
	#
	# ping local vmm
	#
	log_info($ffid, "pinging local vmm");
	my $vmmsock = $system->{'meta'}{'vmm'}{'vmmsock'};
	my $vmmping = api_vmm_local_ping($vmmsock);

	log_info_json($ffid, "vmm ping result", $vmmping);

	# check ping result
	if($vmmping->{'proto'}{'result'}){
		# source vmm responded
		log_info($ffid, "success. source vmm container responded.");
		
		my $diff = date_str_diff_now($start);
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "success: dest vmm container initialized";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "migration in progress";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
		$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "1";
		$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "success: source vmm container responded";
		
		hyper_db_obj_set("hyper", $hyperdb);	
		
		$system->{'state'}{'vm_status'} = "migration";
		$system->{'state'}{'date'} = date_get();
		my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
		
		# update the VM
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
		
		#
		# ping destination node hypervisor
		#
		log_info($ffid, "attempting to ping destination hypervisor");
		my $hyperping = api_hypervisor_ping($hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'dest_node_id'});

		if($hyperping->{'proto'}{'result'} eq "1"){
			# remote hypervisor responded
			log_info($ffid, "success. remote hypervisor responded.");
			
			my $diff = date_str_diff_now($start);
			$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
			$hyperdb->{'vm'}{'async'}{$id}{'result'} = "success: remote hypervisor responded";
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "migration in progress";
			$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
			$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "1";
			$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "success: dest hypervisor responded";	
			hyper_db_obj_set("hyper", $hyperdb);	
			
			sleep 1;
			
			# update the VM
			my $stats = $hyperdb->{'stats'}{$id};
			$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
			$stats->{'updated'} = date_get();
			hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
			
			#
			# pull system config from cluster
			#
			log_info($ffid, "destination node info");
			my $dest_node = nodedb_node_get($hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'dest_node_id'});
			json_encode_pretty($dest_node);
			
			# pull system from cluster
			my $sysdata = api_cluster_local_obj_get(env_serv_sock_get("cluster"), "system", $system->{'id'}{'name'});
			
			log_info($ffid, "updated system data");
			json_encode_pretty($sysdata);
			
			if($sysdata->{'proto'}{'result'} eq "1"){
				#print "[" . date_get() . "] $fid success: fetched updated system configuration from cluster.\n";
				log_info($ffid, "success: fetched updated system configuration from cluster");
				
				my $syscfg = $sysdata->{'system'};
				
				# add system migration metadata
				$syscfg->{'meta'}{'migrate'} = "1";
				$syscfg->{'meta'}{'migration'}{'src_node_id'} = config_node_id_get();
				$syscfg->{'meta'}{'migration'}{'src_node_name'} = config_node_name_get();
				$syscfg->{'meta'}{'migration'}{'dest_node_id'} = $dest_node->{'id'}{'id'};
				$syscfg->{'meta'}{'migration'}{'dest_node_name'} = $dest_node->{'id'}{'name'};
				$syscfg->{'meta'}{'migration'}{'state'} = 1;
				$syscfg->{'meta'}{'migration'}{'status'} = "migration in progress";
				$syscfg->{'meta'}{'migration'}{'date'} = date_get();
								
				#
				# push system configuration to destination
				#
				log_info($ffid, "pushing system config to destination");
				my $pushresult = api_hypervisor_push($dest_node->{'id'}{'id'}, $syscfg);
				
				if(env_debug()){ 
					print "[" . date_get() . "] $fid destination config push result\n";
					json_encode_pretty($pushresult); 
				};
				
				if($sysdata->{'proto'}{'result'} eq "1"){
					# destination push successful
				
					log_info($ffid, "success: pushed system config to destination node");
		
					my $diff = date_str_diff_now($start);			
					$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
					$hyperdb->{'vm'}{'async'}{$id}{'result'} = "success: pushed system to dest vmm";
					$hyperdb->{'vm'}{'async'}{$id}{'status'} = "migration in progres";
					$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
					
					$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
					$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "success: pushed system to dest";	
					
					# update the VM
					my $stats = $hyperdb->{'stats'}{$id};
					$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
					$stats->{'updated'} = date_get();
					hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
					
					#
					# request remote hypervisor load
					#
					log_info($ffid, "requesting destination hypervisor system load");
					my $loadpacket = api_proto_packet_build("hyper", "load");
					$loadpacket->{'hyper'}{'id'} = $id;
					
					my $destloadresult = api_proto_ssl_send($dest_node->{'id'}{'id'}, $loadpacket, $fid);
					
					log_info_json($ffid, "destination load result", $destloadresult);

					if($destloadresult->{'proto'}{'result'} eq "1"){
						log_info($ffid, "success: destination load successful. waiting for destination container to respond...");
						sleep 5;
						
						# pull destination container info
						my $vmminfo = api_proto_packet_build("hyper", "proxyinfo");
						$vmminfo->{'hyper'}{'id'} = $id;
						my $vmmresponse = api_proto_ssl_send($dest_node->{'id'}{'id'}, $vmminfo, $fid);
						
						#
						# initialize migration
						#
						if($vmmresponse->{'proto'}{'result'} eq "1" && $vmmresponse->{'vmshare'}{'vm_running'}){
							# success
							log_info($ffid, "success: destination vmm responded. initializing migration..");
							
							my $migresult = api_vmm_local_migrate($syscfg, $vmmresponse->{'vm'}{'migrate'});
						
							json_encode_pretty($migresult);
							
							my $interval = 3;
							my $timer = 0;
							my $vmmstat;
							
							do{
								sleep $interval;
								my $vmminfo = api_proto_packet_build("hyper", "proxyinfo");
								$vmminfo->{'hyper'}{'id'} = $id;
								$vmmstat = api_proto_ssl_send(config_node_id_get(), $vmminfo, $fid);
								
								log_info($ffid, "migration in progress. vmm status:");
								json_encode_pretty($vmmstat);
								
								my $diff = date_str_diff_now($start);			
								$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
								$hyperdb->{'vm'}{'async'}{$id}{'result'} = "migration in progress";
								$hyperdb->{'vm'}{'async'}{$id}{'status'} = "migration in progress";
								$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();

								$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "1";
								$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "system migration in progress";
								$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'speed'} = $vmmstat->{'vmshare'}{'migspeed'};
								$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'migramrem'} = $vmmstat->{'vmshare'}{'migramrem'};
								$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'migramtot'} = $vmmstat->{'vmshare'}{'migramtot'};
								$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'migstat'} = $vmmstat->{'vmshare'}{'migstat'};
								$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'migcomplete'} = $vmmstat->{'vmshare'}{'migcomplete'};
									
								$system->{'state'}{'vm_status'} = "migrating";
								my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
								
								# update the VM
								my $stats = $hyperdb->{'stats'}{$id};
								$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
								$stats->{'updated'} = date_get();
								hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
								
								$timer += $interval;
							}while(!$vmmstat->{'vmshare'}{'migcomplete'});
						
							my $diff = date_str_diff_now($start);			
							$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
							$hyperdb->{'vm'}{'async'}{$id}{'result'} = "migration successful";
							$hyperdb->{'vm'}{'async'}{$id}{'status'} = "migration cleanup in progress";
							$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();							
							$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
							
							$system->{'state'}{'vm_status'} = "migration_complete";
							my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
							
							# update the VM
							my $stats = $hyperdb->{'stats'}{$id};
							$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
							$stats->{'updated'} = date_get();
							hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
							hyper_db_obj_set("hyper", $hyperdb);
						
							#
							# cleanup on source
							#
							log_info($ffid, "migration cleanup. cleaning up source");
		
							$diff = date_str_diff_now($start);
							$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
							$hyperdb->{'vm'}{'async'}{$id}{'result'} = "migration completed";
							$hyperdb->{'vm'}{'async'}{$id}{'status'} = "migration completed";
							$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
							$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
							
							# shut down source
							my $unloadresult = api_vmm_local_unload($syscfg);
							if(env_debug()){ json_encode_pretty($unloadresult); };
			
							# cleanup reservations
							my $cleanupresult = hyper_unload_cleanup($syscfg);
							if(env_debug()){ json_encode_pretty($cleanupresult); };
							
							# fetch system from remote here
							my $destreq = api_proto_packet_build("hyper", "pull");
							$destreq->{'hyper'}{'id'} = $id;
							my $destsys = api_proto_ssl_send($dest_node->{'id'}{'id'}, $destreq, $fid);
							
							if(env_debug()){ 
								print "[" . date_get() . "] $fid pulled destination system config\n";
								json_encode_pretty($destsys); 
							};
							
							if($destsys->{'proto'}{'result'} eq "1"){
								log_info($ffid, "success: fetched destinatino system config");
								my $destcfg = $destsys->{'vm'};
								
								# update system
								$destsys->{'meta'}{'hypervisor'}{'async'} = $hyperdb->{'vm'}{'async'}{$id};
								$destsys->{'state'}{'date'} = date_get();
								my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $destsys);
							}
							else{
								log_error($ffid, "error: failed to fetch destination config!");
							}

							# update the VM metadata
							$stats = $hyperdb->{'stats'}{$id};
							$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
							$stats->{'updated'} = date_get();
							$stats->{'date'} = date_get();
							hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);
							
							# push status to destination
							log_info($ffid, "updating system metadata to destination");
							my $destmeta = api_proto_packet_build("hyper", "sys_migrate_meta");
							$destmeta->{'hyper'}{'stats'} = $stats;
							my $destmetaresponse = api_proto_ssl_send($dest_node->{'id'}{'id'}, $destmeta, $fid);
							if(env_debug()){ json_encode_pretty($destmetaresponse); };
							
							log_info($ffid, "success: migration completed");
						}
						else{
							# destination vmm not responding
							
							log_warn_json($ffid, "failure: destination vmm is not responding. destroying it", $vmmresponse);
							
							my $unloadpacket = api_proto_packet_build("hyper", "unload");
							$unloadpacket->{'hyper'}{'id'} = $id;
							
							my $destunloadresult = api_proto_ssl_send($dest_node->{'id'}{'id'}, $unloadpacket, $fid);

							log_warn_json($ffid, "destination container unload result", $destunloadresult);
						}
					}
					else{
						# vmm init on dest failed
						log_error($ffid, "failure: failed to spawn destination vmm");
		
						my $diff = date_str_diff_now($start);			
						$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
						$hyperdb->{'vm'}{'async'}{$id}{'result'} = "error: failed to spawn destination vmm";
						$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system migration failed. check logs";
						$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
						
						$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
						$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "failed: failed to spawn destination vmm";	
						hyper_db_obj_set("hyper", $hyperdb);	
						
						$system->{'state'}{'vm_status'} = "running";
						my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
						
						# update the VM
						my $stats = $hyperdb->{'stats'}{$id};
						$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
						$stats->{'updated'} = date_get();
						hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
					}
				}
				else{
					# push failed
					log_error($ffid, "failure: failed to fetch updated system from cluster");
		
					my $diff = date_str_diff_now($start);			
					$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
					$hyperdb->{'vm'}{'async'}{$id}{'result'} = "error: failed to push system to destination";
					$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system migration failed. check logs";
					$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
					
					$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
					$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "failed: failed to push system to destination";	
					hyper_db_obj_set("hyper", $hyperdb);	
					
					$system->{'state'}{'vm_status'} = "running";
					my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
					
					# update the VM
					my $stats = $hyperdb->{'stats'}{$id};
					$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
					$stats->{'updated'} = date_get();
					hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
				}
			}
			else{
				# failed to fetch updated system config
				log_error($ffid, "failure: failed to fetch updated system from cluster");
		
				my $diff = date_str_diff_now($start);			
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "error: failed to fetch updated system from cluster";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system migration failed. check logs";
				$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
				
				$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "failed: failed to fetch updated system from cluster";
				hyper_db_obj_set("hyper", $hyperdb);	
				
				$system->{'state'}{'vm_status'} = "running";
				my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
				
				# update the VM
				my $stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();
				hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
			}
		}
		else{
			# destination hypervisor failed to respond
			log_error_json($ffid, "failure: destination hypervisor failed to respond", $hyperping);
		
			my $diff = date_str_diff_now($start);			
			$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
			$hyperdb->{'vm'}{'async'}{$id}{'result'} = "error: no response from dest hypervisor";
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system migration failed. check logs";
			$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
			
			$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
			$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "failed: no response from dest hypervisor";
			hyper_db_obj_set("hyper", $hyperdb);	
			
			$system->{'state'}{'vm_status'} = "running";
			my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);

			# update the VM
			my $stats = $hyperdb->{'stats'}{$id};
			$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
			$stats->{'updated'} = date_get();
			hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
		}
	}
	else{
		# source vmm failed to respond
		log_error($ffid, "error: source vmm container failed to respond");
		
		my $diff = date_str_diff_now($start);
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "error: source vmm did not respond";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system migration failed. check logs";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
		$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'state'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'migrate'}{'status'} = "failed: no response from source vmm";
		hyper_db_obj_set("hyper", $hyperdb);	
		
		$system->{'state'}{'vm_status'} = "running_error";
		my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
		
		# update the VM
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);	
	}
}

#
# system async move [NULL]
#
sub system_async_move($diff, $id){
	my $fid = "[system_async_move]";
	my $ffid = "SYSTEM|ASYNC|MOVE";
	my $hyperdb = hyper_db_obj_get("hyper");
	
	# get systems	
	my $src_system = $hyperdb->{'vm'}{'async'}{$id}{'src'};
	my $dst_system = $hyperdb->{'vm'}{'async'}{$id}{'dst'};
			
	$hyperdb = hyper_db_obj_get("hyper");

	# push system to cluster
	$dst_system->{'state'}{'vm_status'} = "move_started";
	$dst_system->{'meta'}{'lock'} = "1";
	api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);

	sleep 1;
	
	# update state
	$hyperdb->{'vm'}{'async'}{$id}{'active'} = "1";
	$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system move started";
	$hyperdb->{'vm'}{'async'}{$id}{'status'} = "move initialized";
	$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
	my $stats = $hyperdb->{'stats'}{$id};
	$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
	$stats->{'updated'} = date_get();
	delete $stats->{'async'}{'src'};
	delete $stats->{'async'}{'dst'};
	
	hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
	api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);

	log_info_json($ffid, "source system config", $src_system);
	log_info_json($ffid, "destination system config", $dst_system);
	
	my $start = date_get();
	
	my $pool_check_src = hyper_storage_pool_check($src_system);
	
	if($pool_check_src->{'proto'}{'result'} eq "1"){
		my $pool_check_dst = hyper_storage_pool_check($dst_system);
		
		if($pool_check_dst->{'proto'}{'result'} eq "1"){
			my $dir_create = system_storage_dir_create($dst_system);
			
			if($dir_create->{'proto'}{'result'} eq "1"){

				# iterate disks
				my @stor_index = index_split($src_system->{'stor'}{'disk'});

				foreach my $dev (@stor_index){
					log_info($ffid, "DEV [$dev] SOURCE DIR [$src_system->{'stor'}{$dev}{'dev'}] IMG [$src_system->{'stor'}{$dev}{'image'}]");
					log_info($ffid, "DEV [$dev] DEST DIR [$dst_system->{'stor'}{$dev}{'dev'}] IMG [$dst_system->{'stor'}{$dev}{'image'}]");
				
					my $src = $src_system->{'stor'}{$dev}{'dev'} . $src_system->{'stor'}{$dev}{'image'};
					my $dst = $dst_system->{'stor'}{$dev}{'dev'} . $dst_system->{'stor'}{$dev}{'image'};
				
					# start move
					move($src, $dst) or do {
						my $diff = date_str_diff_now($start);
						
						$hyperdb = hyper_db_obj_get("hyper");
					
						$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
						$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system move failed after $diff sec";
						$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system move failed. check logs";
						$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
						
						delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
						delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
						
						hyper_db_obj_set("hyper", $hyperdb);
						$dst_system->{'state'}{'vm_status'} = "move_failed";
						#api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
						
						#sleep 1;
						
						# update the VM
						my $stats = $hyperdb->{'stats'}{$id};
						$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
						$stats->{'updated'} = date_get();
						
						hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
						api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
						
						return;
					}

				};
					
				# remove system source dirs
				foreach my $dev (@stor_index){
					dir_remove($src_system->{'stor'}{$dev}{'dev'});
				}

				# successful
				my $diff = date_str_diff_now($start);
					
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "move completed after $diff seconds";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system move completed";
				$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
				
				delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
				delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
					
				$dst_system->{'state'}{'vm_status'} = "move_complete";
				$dst_system->{'meta'}{'lock'} = "0";
				$dst_system->{'object'}{'init'} = "1";
				
				hyper_db_obj_set("hyper", $hyperdb);

				# update the VM
				my $stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();
				
				hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);
				api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);	
			}
			else{
				# successful
				my $diff = date_str_diff_now($start);
					
				$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
				$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system mkdir create failed after $diff seconds";
				$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system mkdir failed. check logs";
				$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
				
				delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
				delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
					
				hyper_db_obj_set("hyper", $hyperdb);	
				$dst_system->{'state'}{'vm_status'} = "move_error";

				# update the VM
				my $stats = $hyperdb->{'stats'}{$id};
				$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
				$stats->{'updated'} = date_get();
				
				hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
				api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
			}

		}
		else{
			# system src pool not available
			
			my $diff = date_str_diff_now($start);	
			$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
			$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system destination pool not available";
			$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system cloning failed. check logs";
			$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
			
			delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
			delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
				
			hyper_db_obj_set("hyper", $hyperdb);	
			$dst_system->{'state'}{'vm_status'} = "move_error";

			# update the VM
			my $stats = $hyperdb->{'stats'}{$id};
			$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
			$stats->{'updated'} = date_get();
			
			hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
			api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
		}	
	}
	else{
		# system src pool not available
		
		my $diff = date_str_diff_now($start);	
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system soruce pool not available";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system cloning failed. check logs";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();
		
		delete $hyperdb->{'vm'}{'async'}{$id}{'src'};
		delete $hyperdb->{'vm'}{'async'}{$id}{'dst'};
			
		hyper_db_obj_set("hyper", $hyperdb);	

		# update the VM
		my $stats = $hyperdb->{'stats'}{$id};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		
		hyper_system_cdb_meta_set($dst_system->{'id'}{'name'}, $stats);	
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $dst_system);
	}	
}

#
# create system [JSON-STR]
#
sub system_create($req){
	my $fid = "[system_create]";
	my $ffid = "SYSTEM|CREATE";
	my $result;
	
	log_info_json($ffid, "received system create request", $req);
	
	my $system = $req->{'hyper'}{'vm'};
	my $id = $system->{'id'}{'id'};
	
	# Validate VM structure
	my $validation = hyper_validate_vm_structure($system);
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
	
	# process storage
	my $storage_result = hyper_system_storage_create($system);
	
	# storage result
	if($storage_result->{'proto'}{'result'} eq "1"){
		log_info($ffid, "system create succeeded");
		$result =  packet_build_noencode("1", "success: system create completed", $fid);
		$result->{'storage_result'} = $storage_result;
		
		my $hyperdb = hyper_db_obj_get("hyper");
		$hyperdb->{'vm'}{'async'}{$id}{'request'} = "create";
		$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "end";
		$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "60";
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system create successful";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system create completed";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();

		$system->{'object'}{'init'} = "1";			
		hyper_db_obj_set("hyper", $hyperdb);

		my $stats = {};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		
		hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
	}
	else{
		log_error($ffid, "system storage create failed!", $storage_result);
		
		$result =  packet_build_noencode("0", "failed: system create failed", $fid);
		#if(env_verbose()){ json_encode_pretty($storage_result); };
		$result->{'storage_result'} = $storage_result;
		
		my $hyperdb = hyper_db_obj_get("hyper");
		
		$hyperdb->{'vm'}{'async'}{$id}{'request'} = "create";
		$hyperdb->{'vm'}{'async'}{$id}{'on_timeout'} = "end";
		$hyperdb->{'vm'}{'async'}{$id}{'timeout'} = "60";
	
		$hyperdb->{'vm'}{'async'}{$id}{'active'} = "0";
		$hyperdb->{'vm'}{'async'}{$id}{'result'} = "system create failed";
		$hyperdb->{'vm'}{'async'}{$id}{'status'} = "system create failed";
		$hyperdb->{'vm'}{'async'}{$id}{'date'} = date_get();

		hyper_db_obj_set("hyper", $hyperdb);		

		my $stats = {};
		$stats->{'async'} = $hyperdb->{'vm'}{'async'}{$id};
		$stats->{'updated'} = date_get();
		
		hyper_system_cdb_meta_set($system->{'id'}{'name'}, $stats);
		api_cluster_local_system_set(env_serv_sock_get("cluster"), $system);
	}
	
	if(env_debug()){ json_encode_pretty($result); };
	return json_encode($result);
}

#
# system storage add [JSON-STR]
#
sub system_storage_add($req){
	my $fid = "[system_storage_add]";
	my $ffid = "SYSTEM|STORAGE|ADD";
	my $result;
	
	log_info($ffid, "received request:");
	json_encode_pretty($req);
	
	my $system = $req->{'hyper'}{'vm'};
	my $device = $req->{'hyper'}{'dev'};
	
	# Validate VM structure
	my $validation = hyper_validate_vm_structure($system);
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
	
	# check if device exists on system
	my $found = 0;
	
	my @stor_index = index_split($system->{'stor'}{'disk'});
	
	foreach my $dev (@stor_index){	
		if($dev eq $device){
			$found = 1;
		}
	}
	
	if($found){		
		# process storage
		my $storage_result = hyper_system_storage_add($system, $device);
		
		# storage result
		if($storage_result->{'proto'}{'result'} eq "1"){
			log_info($ffid, "system create succeeded");
			$result =  packet_build_noencode("1", "success: system storage add completed", $fid);
			$result->{'storage_result'} = $storage_result;
		}
		else{
			log_info($ffid, "system create failed!");
			$result =  packet_build_noencode("0", "failed: system storage add failed", $fid);
			$result->{'storage_result'} = $storage_result;
		}
	}
	else{
		log_warn($ffid, "error: unknown storage device [$device]!");
		$result =  packet_build_noencode("0", "failed: unknown storage device [$device]", $fid);
	}
	
	if(env_debug()){ json_encode_pretty($result); };
	return json_encode($result);
}

#
# expand system storage [JSON-STR]
#
sub system_storage_expand($req){
	my $fid = "[system_storage_expand]";
	my $ffid = "SYSTEM|STORAGE|EXPAND";
	my $result;
	
	if(env_debug()){
		print "[" . date_get() . "] $fid request\n";
		json_encode_pretty($req);
	}
	
	my $system = $req->{'hyper'}{'vm'};
	my $device = $req->{'hyper'}{'dev'};
	
	# Validate VM structure
	my $validation = hyper_validate_vm_structure($system);
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
	
	# check if device exists on system
	my $found = 0;	
	my @stor_index = index_split($system->{'stor'}{'disk'});
	
	foreach my $dev (@stor_index){	
		if($dev eq $device){
			$found = 1;
		}
	}
	
	if($found){
		# process storage
		my $storage_result = hyper_system_storage_expand($system, $device);
		
		# storage result
		if($storage_result->{'proto'}{'result'} eq "1"){
			log_info($ffid, "system storage expand succeeded");
			$result =  packet_build_noencode("1", "success: system storage expand completed", $fid);
			$result->{'storage_result'} = $storage_result;
		}
		else{
			log_error_json($ffid, "system storage expand failed!", $storage_result);
			$result =  packet_build_noencode("0", "failed: system storage expand failed", $fid);
			$result->{'storage_result'} = $storage_result;
		}
	}
	else{
		log_error($ffid, "failed: unknown storage device [$device]");
		$result =  packet_build_noencode("0", "failed: unknown storage device [$device]", $fid);
	}
	
	if(env_debug()){ json_encode_pretty($result); };
	return json_encode($result);
}

#
# spawn novnc proxy [JSON-OBJ]
#
sub system_novnc_spawn($vm){
	my $fid = "[novnc_spawn]";
	my $ffid = "SYSTEM|NOVNC|SPAWN";

	# build novnc init - TODO static offset
	my $vnc_port = 5900 + $vm->{'meta'}{'vnc'};
	my $log = env_base_get() . "log/vmm." . $vm->{'id'}{'name'} . "." .  $vm->{'id'}{'id'} . ".novnc.out";
	my $vnc_exec = env_base_get() . "utils/novnc/novnc_proxy --vnc 127.0.0.1:" . $vnc_port . " --listen 0.0.0.0:" . $vm->{'meta'}{'novnc_port'} . " > " . $log . " 2>/dev/null &";
	log_debug($ffid, "novnc exec [$vnc_exec]");

	# fork
	my $pid = forker($vnc_exec);
	# TODO HANDLE ZERO PID
	log_info($ffid, "logfile [$log] vnc port [$vnc_port] novnc port [$vm->{'meta'}{'novnc_port'}] forked pid [$pid]");
	$vm->{'meta'}{'novnc_pid'} = $pid;
	
	return $vm;
}

#
# kill novnc [JSON-OBJ]
#
sub system_novnc_kill($vm){
	my $fid = "[novnc_kill]";
	my $ffid = "SYSTEM|NOVNC|KILL";

	log_info($ffid, "killing novnc pid [$vm->{'meta'}{'novnc_pid'}]");
	
	if(defined $vm->{'meta'}{'novnc_pid'}){
		my $result = killer($vm->{'meta'}{'novnc_pid'});
	}
	
	return $vm;
}

#
# check for lockfile
#
sub system_lockfile_check($dev){
	my $fid = "[system_lockfile_check]";
	my $ffid = "HYPER|LOCKFILE|CHECK";
		
	# check for lockfile
	my $lockfile = $dev->{'dev'} . $dev->{'image'} . ".lock";
	if(file_check($lockfile)){
		return 1;
	}
	else{
		return 0;
	}
	
}

1;
