#
# ETHER|AAPEN|FRAMEWORK - LIB|VMM
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#


use warnings;
use strict;
use experimental 'signatures';


#
# start vmm [JSON-STR]
#
sub frame_vmm_info($packet){
	my $fid = "[frame_vmm_info]";
	my $ffid = "VMM|INFO";
	my $vmmdb = frame_db_obj_get("vmm");
	my $return;

	log_info($ffid, "[" . date_get() . "] $fid received vm id [" . $packet->{'vmm'}{'id'} . "] data");

	# check if vm is known
	if(index_find($vmmdb->{'index'}, $packet->{'vmm'}{'id'})){
		$return = packet_build_noencode("1", "success: vmm id [$packet->{'vmm'}{'id'}] in index", $fid);
		$return->{'vm'} = $vmmdb->{$packet->{'vmm'}{'id'}};
	}
	else{
		# not found
		$return = packet_build_noencode("0", "error: vmm id [$packet->{'vmm'}{'id'}] not in index", $fid);
	}
	
	return json_encode($return);
}

#
# start vmm [JSON-STR]
#
sub frame_vmm_start($packet){
	my $fid = "[frame_vmm_start]";
	my $ffid = "VMM|START";
	my $vmmdb = frame_db_obj_get("vmm");

	if(env_debug()){
		log_debug($ffid, "received packet");
		json_encode_pretty($packet);
	}

	my $return;
	
	my $id = $packet->{'vmm'}{'vm'}{'id'}{'id'};
	my $name = $packet->{'vmm'}{'vm'}{'id'}{'name'};
	log_info($ffid, "received vm  [" . $name ."] id [" . $id . "] data");

	#sleep 2;

	my $vmmsock = env_base_get() . "socket/" . "vmm." . $name . "." . $id . ".sock";
	log_info($ffid, "vmm socket [$vmmsock]");
	log_debug($ffid, "trying to ping vmm container [$vmmsock] (should fail unless orphaned!)");
	my $vmmping = api_vmm_local_ping($vmmsock);
	
	# check if vm is known
	if(index_find($vmmdb->{'index'}, $id)){
		log_info($ffid, "vmm id [$id] already in index");
		
		if($vmmping->{'proto'}{'result'}){
			log_info($ffid, "success. vmm container [$id] responded.");
			$return = packet_build_noencode("0", "warn: vmm [$id] already started and responds", $fid);
		}
		else{
			log_warn($ffid, "vmm [$id] already started but does not respond");
			$return = packet_build_noencode("0", "warn: vmm [$id] already started but does not respond", $fid);
		}
	}
	else{
		
		# check ping result
		if($vmmping->{'proto'}{'result'}){
			# vmm responded!
			log_warn($ffid, "warning: vmm container responded.");
			$return = packet_build_noencode("0", "error: vmm [$id] responded yet not in index!", $fid);
		}
		else{
			# no response from vmm and not in index. can start
			log_info($ffid, "vmm [$id] not in index");
			my $initresult = frame_vmm_init($packet->{'vmm'}{'vm'});
			
			if(env_debug()){ 
				log_debug($ffid, "vmm id [$id] init result");
				json_encode_pretty($initresult);
			}
			
			if($initresult->{'proto'}{'result'} eq "1"){
				# success
				$return = packet_build_noencode("1", "success: started vmm [$id]", $fid);
				$return->{'vm'} = $initresult->{'vm'};
				
				$vmmdb->{'index'} = index_add($vmmdb->{'index'}, $id);
				$vmmdb->{$id} = $initresult->{'vm'};
				
				frame_db_obj_set("vmm", $vmmdb);
				
				log_info($ffid, "vmm id [$id] started successfully");
			}
			else{
				# failure
				$return = packet_build_noencode("0", "error: failed to start vmm", $fid);
				log_warn($ffid, "vmm id [$id] failed to start");
				$return->{'vmminit'} = $initresult;
			}
		}
	}
	
	return json_encode($return);
}

#
# initialize vmm [JSON-OBJ]
#
sub frame_vmm_init($vm){
	my $fid = "[frame_vmm_init]";
	my $ffid = "VMM|INIT";
	my $vmmdb = frame_db_obj_get("vmm");
	my $result;
	
	my $socket = "vmm." . $vm->{'id'}{'name'} . "." . $vm->{'id'}{'id'} . ".sock";
	my $log = "vmm." . $vm->{'id'}{'name'} . "." . $vm->{'id'}{'id'} . ".log";
	log_info($ffid, "socket path [$socket] log path [$log]");

	# exec
	my $exec = "cd " . get_root() . "service/vmm/" . "; " . "perl vmm.pl " . env_base_get() . "socket/" . $socket . " > " . env_base_get() . "log/" . $log . " 2>&1 &";
	log_debug($ffid, "exec [$exec]");
	
	# fork process
	my $pid = forker($exec);
	log_info($ffid, "forked vmm [$vm->{'id'}{'name'}] id [$vm->{'id'}{'id'}] with pid [$pid]");
	
	# let VMM settle
	sleep 2;
		
	my $childpid = execute('pgrep -f ' . $socket);
	chomp($childpid);
	$pid = $childpid;
	
	# socket
	my $vmmsock = env_base_get() . "socket/" . $socket;
	log_info($ffid, "vmm socket [$vmmsock]");

	# vmm ping
	my $vmmping = api_vmm_local_ping($vmmsock);
	
	# check ping result
	if($vmmping->{'proto'}{'result'}){
		log_info($ffid, "vmm container responded. updating permissions..");
		my $perm = vmm_perm($vmmsock);

		# update stats
		$vm->{'meta'}{'vmm'}{'socket'} = $socket;
		$vm->{'meta'}{'vmm'}{'vmmsock'} = $vmmsock;
		$vm->{'meta'}{'vmm'}{'log'} = $log;
		$vm->{'meta'}{'vmm'}{'state'} = 1;
		$vm->{'meta'}{'vmm'}{'date'} = date_get();
		$vm->{'meta'}{'vmm'}{'node_id'} = config_node_id_get();
		$vm->{'meta'}{'vmm'}{'node_name'} = config_node_name_get();
		$vm->{'meta'}{'vmm'}{'pid'} = $pid;
		$vm->{'meta'}{'vmm'}{'system_id'} = $vm->{'id'}{'id'};
		$vm->{'meta'}{'vmm'}{'system_name'} = $vm->{'id'}{'name'};

		$result = packet_build_noencode("1", "success: vmm container spawned", $fid);
		$result->{'vm'} = $vm;
	}
	else{
		# failed to contact vmm container
		log_warn($ffid, "error: vmm container failed to spawn");
		$result = packet_build_noencode("0", "failed: vmm container failed to spawn", $fid);
	}	
	
	return $result;
}

#
# stop vmm [JSON-OBJ]
#
sub frame_vmm_stop($packet){
	my $fid = "[frame_vmm_stop]";
	my $ffid = "VMM|STOP";
	my $vmmdb = frame_db_obj_get("vmm");	
	my $return;
	my $status = 0;

	log_info($ffid, "received vm id [" . $packet->{'vmm'}{'id'} . "] data");

	# check if vm is known
	if(index_find($vmmdb->{'index'}, $packet->{'vmm'}{'id'})){
		log_info($ffid, "vmm [$packet->{'vmm'}{'id'}] in index");
		my $id = $packet->{'vmm'}{'id'};

		my $sysid = $vmmdb->{$id}{'id'}{'id'};
		my $name = $vmmdb->{$id}{'id'}{'name'};

		# socket
		my $vmmsock = $vmmdb->{$id}{'meta'}{'vmm'}{'vmmsock'};
		
		# ping vmm
		my $vmmping = api_vmm_local_ping($vmmsock);
		
		# check for response
		if($vmmping->{'proto'}{'result'}){
			log_info($ffid, "success. vmm container [$id] responded");
		
			$return = packet_build_noencode("1", "success: stopping vmm id [$packet->{'vmm'}{'id'}]", $fid);

			# pid
			log_info($ffid, "vmm pid [$vmmdb->{$id}{'meta'}{'vmm'}{'pid'}]");
		
			# try to
			my $killresult = 0;
			my $killcount = 0;
		
			do{
				# clean up
				my $killstat = killer($vmmdb->{$id}{'meta'}{'vmm'}{'pid'});	
				log_info($ffid, "pid [" . $vmmdb->{$id}{'meta'}{'vmm'}{'pid'} . "] killstat [$killstat] attempt [$killcount]");
			
				if($killstat eq ""){
					print "[" . date_get() . "] $fid pid [" . $vmmdb->{$id}{'meta'}{'vmm'}{'pid'} . "] killed successfully\n";
					log_info($ffid, "pid [" . $vmmdb->{$id}{'meta'}{'vmm'}{'pid'} . "] killed successfully");
					$killresult = 1;
				}
				
				# try using force
				if($killcount > 2){
					log_warn($ffid, "pid [" . $vmmdb->{$id}{'meta'}{'vmm'}{'pid'} . "] kill failed 3 attempts! using force!");
					$killstat = killer_force($vmmdb->{$id}{'meta'}{'vmm'}{'pid'});	
					
					if($killstat eq ""){
						log_info($ffid, "pid [" . $vmmdb->{$id}{'meta'}{'vmm'}{'pid'} . "] killed successfully (force)");
						$killresult = 1;
					}
					else{
						log_info($ffid, "error: failed to kill pid [$vmmdb->{$id}{'meta'}{'vmm'}{'pid'}]!");
					}
				}

				# check if PID is alive				
				if(pid_check($vmmdb->{$id}{'meta'}{'vmm'}{'pid'})){
					log_info($ffid, "warning: pid [$vmmdb->{$id}{'meta'}{'vmm'}{'pid'}] still alive!");
					$killstat = killer_force($vmmdb->{$id}{'meta'}{'vmm'}{'pid'});
				}
				else{
					log_info($ffid, "pid [$vmmdb->{$id}{'meta'}{'vmm'}{'pid'}] killed successfully");
				}

				# let it settle
				$killcount++;
				sleep 2;
						
			}while(!$killresult);

			# remove socket
			file_del($vmmsock);
			
			# clean up index and db
			$vmmdb->{'index'} = index_del($vmmdb->{'index'}, $packet->{'vmm'}{'id'});
			delete $vmmdb->{$id};
		}
		else{
			# vmm container is dead... unmarking it
			log_info($ffid, "error: vmm container [$packet->{'vmm'}{'id'}] is dead. cleaning up..");
			$return = packet_build_noencode("1", "warn: cleaning up dead vmm container [$packet->{'vmm'}{'id'}]", $fid);
			
			# remove socket
			file_del($vmmsock);
			
			# clean up index and db
			$vmmdb->{'index'} = index_del($vmmdb->{'index'}, $packet->{'vmm'}{'id'});
			delete $vmmdb->{$id};
		}
			
		frame_db_obj_set("vmm", $vmmdb);
	}
	else{
		log_warn($ffid, "vmm container [$packet->{'vmm'}{'id'}] not started.");
		# not found
		$return = packet_build_noencode("0", "error: vmm id [$packet->{'vmm'}{'id'}] not started", $fid);
	}
	
	return json_encode($return);
}

#
# set vmm permission [BOOL]
#
sub vmm_perm($socket){
	my $fid = "[vmm_perm]";
	my $ffid = "VMM|PERM";
	my $result;

	my $confdb = frame_db_obj_get("config");
	log_info($ffid, "vmm user [" . $confdb->{'vmm'}{'uid'} . "] group [" . $confdb->{'vmm'}{'gid'} . "]");

	# exec
	my $exec = "/usr/bin/chown " . $confdb->{'vmm'}{'uid'} . ":" . $confdb->{'vmm'}{'gid'}  . " " . $socket;
	log_debug($ffid, "exec [$exec]");
	
	# execute
	system($exec);
	
	# check result
	if($? == -1){ 
		log_warn($ffid, "command [$exec] failed!");
	}
	else{
		log_info($ffid, "command [$exec] successful");
		$result = 1;
	}
	
	return $result;
}

1;
