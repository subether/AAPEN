#
# ETHER|AAPEN|VMM - LIB|VMM
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
# push data to vmm [JSON-STR]
#
sub vmm_push($json){
	my $fid = "[vmm_push]";
	my $ffid = "VMM|PUSH";
	my $result;
		
	# check lock status
	if(!lock_state()){
		log_info_json($ffid, "received VM configuration", $json);
		
		# update data
		my $db = vmm_db_get_new();
		$db->{'vm'} = $json->{'vm'};
		$db->{'vm_data'} = 1;
		vmm_db_set_new($db);
		
		log_info($ffid, "updating vm data state [$db->{'vm_data'}]");
		$result = packet_build_encode("1", "success: push completed", $fid);
	}
	else{
		log_warn($ffid, "error: resource locked. vm running.");
		$result = packet_build_encode("0", "error: resource locked. vm running.", $fid);
	}
	
	return $result;		
}

#
# pull vmm info from db [JSON-STR]
#
sub vmm_pull($json){
	my $fid = "[vmm_pull]";
	my $ffid = "VMM|PULL";
	my $result;
	my $db = vmm_db_get_new();

	if($db->{'vm_data'}){
		$result = packet_build_noencode("1", "succes: returning vm data", $fid);
		$result->{'vm'} = $db->{'vm'};
	}
	else{
		# vm not in db
		log_warn($ffid, "error: vm not in db");
		$result = packet_build_noencode("0", "error: vm not in database", $fid);
	}
	
	return json_encode($result);
}

#
# load vm [JSON-STR]
#
sub vmm_load($json){
	my $fid = "[vmm_load]";
	my $ffid = "VMM|LOAD";
	my ($result, $string, $status);
	my $db = vmm_db_get_new();
	
	# check lock state
	if(!lock_state()){

		if($db->{'vm_data'}){

			log_info($ffid, "preparing system load");
			
			($status, $string, $db->{'vm'}) = kvm_load($db->{'vm'});

			log_info($ffid, "load state [$db->{'vm'}{'meta'}{'state'}] status [$status] string [$string]");
			
			vmm_db_vm_set($db->{'vm'});
			vmmdb_cluster_update();
			$result = packet_build_encode($status, $string, $fid);
		}
		else{
			log_warn($ffid, "error: no vm data present");
			$result = packet_build_encode("0", "error: no vm data present.", $fid);		
		}
	}
	else{
		log_warn($ffid, "error: resource locked. vm running");
		$result = packet_build_encode("0", "error: resource locked. vm running.", $fid);
	}
	
	return $result;
}

#
# unload vm [JSON-STR]
#
sub vmm_unload(){
	my $fid = "[vmm_unload]";
	my $ffid = "VMM|UNLOAD";
	my $result;
	my $status;
	my $db = vmm_db_get_new();
	
	log_info($ffid, "vmdata [$db->{'vm_data'}] vm state [$db->{'vm'}{'meta'}{'state'}]");

	if(lock_state()){
		
		if($db->{'vm'}{'meta'}{'state'}){
			
			log_info($ffid, "preparing system unload.. checking locks");
			log_info($ffid, "killing pid [$db->{'vm'}{'meta'}{'pid'}]");
			
			my $childpid = kill 0, $db->{'vm'}{'meta'}{'pid'};

			if($childpid){
				# pid exists and is live! destroying it
				log_warn($ffid, "WARNING: system pid [$childpid] exists, destroying it..");
				execute("/bin/kill -15 " . $db->{'vm'}{'meta'}{'pid'});
				sleep 2;
			}

			# send unload
			($result, $db->{'vm'}) = kvm_unload($db->{'vm'});

			# update data
			log_info($ffid, "unload status [$db->{'vm'}{'meta'}{'state'}]");
			vmm_db_vm_set($db->{'vm'});
			
			# debug
			print "$fid UNLOAD RESULT\n";
			json_decode_pretty($result);
		}
		else{
			log_warn($ffid, "error: no vm data present");
			$result = packet_build_encode("0", "error: no vm data present.", $fid);		
		}
	}
	else{
		log_warn($ffid, "error: resource unlocked. no vm is running");
		$result = packet_build_encode("2", "warning: resource unlocked. no vm is running.", $fid);	
	}
	
	return $result;
}

#
# show vmm information [JSON-STR]
#
sub vmm_info_get(){
	my $fid = "[vmm_info_get]";
	my $ffid = "VMM|INFO|GET";

	my $result = packet_build_noencode("1", "success: returning vm data.", $fid);
	$result->{'vm'} = vmm_info_new();

	return json_encode($result);
}

#
# show vmm information [JSON-STR]
#
sub vmm_info(){
	my $fid = "[vmm_info]";
	my $ffid = "VMM|INFO";

	# get shared data
	my %vmshare = vmshare_get();

	my $result = packet_build_noencode("1", "success: returning vm data.", $fid);
	$result->{'vm'} = vmm_info_new();
	
	my %vmmdb;
	$vmmdb{'vmshare'} = \%vmshare;	
	$result->{'vmshare'} = \%vmshare;
	
	return json_encode($result);
}

#
# migration handler [JSON-STR]
#
sub vmm_migrate($migrate){
	my $fid = "[vmm_migrate]";
	my $ffid = "VMM|MIGRATE";
	my ($result, $status, $unloadstatus);
	my $db = vmm_db_get_new();
	my $failed = 0;

	# update shared data
	my %vmshare = vmshare_get();
	$vmshare{'vm'} = json_encode($db->{'vm'});
	$vmshare{'migdata'} = json_encode($migrate);
	$vmshare{'miginit'} = 1;
	vmshare_set(%vmshare);
	
	# set timeout
	my $timeout = 120;
	
	# wait for main loop to finish
	do{
		sleep 2;
		log_info($ffid, "waiting for return code... timeout [$timeout]");
		$timeout--;
		%vmshare = vmshare_get();
	}while(!$vmshare{'migstarted'} || $timeout <= 0);
		
	
	if($failed){
		# migration failed to init
		log_info($ffid, "failed: timed out waiting for vm migration init");
		$vmshare{'miginit'} = 0;
		$result = packet_build_encode($status, "failed: migration timed out.", $fid);
	}
	else{
		# migration is active
		log_info($ffid, "succes: vm migration initiated by main thread");
		$result = packet_build_encode($status, "success: migration started.", $fid);
	}
	return $result;
}

#
# initialize vmm migration [JSON-STR]
#	
sub vmm_migrate_init($vm, $migrate){
	my $fid = "[vmm_migrate_init]";
	my $ffid = "VMM|MIGRATE|INIT";
	my ($data, $result, $return);
	my ($socket,$client_socket);

	# handle errors and flush
	local $@;
	$| = 1;

	log_info($ffid, "[SOURCE] addr [$vm->{'monitor'}{'addr'}] port [$vm->{'monitor'}{'port'}] proto [$vm->{'monitor'}{'proto'}]");
	log_info($ffid, "[DEST] addr [$migrate->{'dest'}{'addr'}], port [$migrate->{'dest'}{'port'}], proto [$migrate->{'dest'}{'proto'}]");

	# handle errors
	eval{
		log_info($ffid, "establishing connection.. addr [$vm->{'monitor'}{'addr'}] port [$vm->{'monitor'}{'port'}]");
	
		# connect to vm monitor
		$socket = new IO::Socket::INET (
			PeerHost => $vm->{'monitor'}{'addr'},
			PeerPort => $vm->{'monitor'}{'port'},
			Proto => $vm->{'monitor'}{'proto'},
			#Blocking => '0',
		) or die "$fid ERROR in Socket Creation : $!\n";

		# settle
		sleep (1);	
		
		# read monitor socket
		$data = <$socket>;
		print "[" . date_get() . "] $fid vm responded: [$data]\n";
		log_info($ffid, "vm responded [$data]... initializing vm migration");
		
		# initiate migration request
		my $packet = "migrate -d " . $migrate->{'dest'}{'proto'} . ":" . $migrate->{'dest'}{'addr'} . ":" . $migrate->{'dest'}{'port'}; 
		log_debug($fid, "migration packet [$packet]");
		print $socket "$packet\n";

		# wait for data
		log_info($ffid, "waiting for data to become ready...");
		sleep (1);

		# read data
     	$data = <$socket>;
		log_info($ffid, "QEMU QMP [$data]");

		# settle and close
		sleep (1);
		$socket->close();

		# optimize speed
		my $migspeed = vmm_migrate_speed();

		# process initiated
		log_info($ffid, "initiated migration...");

		$return = vmm_migrate_stat($vm);
	};			

	# error
	if($@){
		# connection failed
		log_error($ffid, "FATAL ERROR: Connection failed!");
		$return = packet_build_encode("0", "error: connection failed", $fid);
		#$return = 3;
	}
	
	return $return;
}

#
# vmm migration status [BOOLEAN]
#
sub vmm_migrate_stat($vm){
	my $fid = "[vmm_migrate_stat]";
	my $ffid = "VMM|MIGRATE|STATS";
	my ($socket,$client_socket);
	my ($data, $status);
	my @migrate;
	my $result = 0;
	my $i = 0;
	my %vmshare = vmshare_get();
	my $speedflag = 1;

	# flush
	$| = 1;
	local $@;
		
	# header
	log_info($ffid, "monitor addr [$vm->{'monitor'}{'addr'}] port [$vm->{'monitor'}{'port'}] proto [$vm->{'monitor'}{'proto'}]");
	
	# until result
	do{
		eval{
			$socket = new IO::Socket::INET (
				PeerHost => $vm->{'monitor'}{'addr'},
				PeerPort => $vm->{'monitor'}{'port'},
				Proto => $vm->{'monitor'}{'proto'},
				#Blocking => '0',
			) or die "$fid ERROR in Socket Creation : $!\n";
			log_info($ffid, "TCP Connection Success");

			# read socket header
			$data = <$socket>;
			log_info($ffid, "received from Server [$data]");

			# write request to socket
			$data = "info migrate";
			print $socket "$data\n";

			# process input
			for($i = 0; $i <= 23; $i++){
				$data = <$socket>;
				chomp($data);
				#print " $fid [$i]: $data\n";
				$migrate[$i] = $data;
			
				# check for failed status
				if($migrate[$i] =~ "Migration status: failed"){				
					$result = 1;
					last;
				}
				else{
					$vmshare{'migstarted'} = 1;
				}
				
				# process header
				if($i == 7){ $vmshare{'migglob'} = $data; };						
				if($i == 8){ $vmshare{'migstat'} = $data; };
				if($i == 9){ $vmshare{'migtime'} = $data; };		
				if($i == 10){ $vmshare{'migdown'} = $data; };
				if($i == 11){ $vmshare{'migsetup'} = $data; };				
				if($i == 12){ $vmshare{'migramtrs'} = $data; };
				if($i == 13){ $vmshare{'migspeed'} = $data; };
				if($i == 14){ $vmshare{'migramrem'} = $data; };
				if($i == 15){ $vmshare{'migramtot'} = $data; };
				if($i == 16){ $vmshare{'migramdup'} = $data; };
				
			}
			
			sleep 1;
			
			# set speed limit
			if($speedflag){
				my $speedlimit = "migrate_set_speed 10G";
				print $socket "$speedlimit\n";
				$speedflag = 0;					
				my $speedstat = <$socket>;
				log_info($ffid, "[speedlimit] status [$speedstat]");
			}
	
			$socket->close();
		};
		
		# handle events/errors
		if($@){
			# connection failed / error
			log_error($ffid, "FATAL ERROR: Connection failed!");		
			$status = 2;
			$result = 1;
			
			# shared data
			$vmshare{'migstatus'} = 2;
			$vmshare{'migerr'} = 1;
			$vmshare{'migerrmsg'} = "FATAL ERROR: Connection failed";
		}  
		if($vmshare{'migstat'} =~ "Migration status: completed"){
			# migration successful
			log_info($ffid, "migration completed successfully");
			$status = 1;
			$result = 1;
			
			# shared data
			$vmshare{'migstatus'} = 1;
			$vmshare{'migcomplete'} = 1;
		}
		if($vmshare{'migstat'} =~ "Migration status: failed"){
			# migration failed
			log_error($ffid, "migration failed!");
			$status = 0;
			$result = 1;
			
			# shared data
			$vmshare{'migstatus'} = 0;
			$vmshare{'migerr'} = 1;
			$vmshare{'migerrmsg'} = "Migration failed.";
		}		

		# save data and wait
		vmshare_set(%vmshare);
		sleep 2;
		
	}while(!$result);

	return $status;	
}

#
# request vm shutdown [JSON-STR]
#	
sub vmm_migrate_speed(){
	my $fid = "[vmm_migrate_speed]";
	my $ffid = "VMM|MIGRATE|SPEED";
	my ($data, $result, $return);
	my ($socket,$client_socket);
	my $db = vmm_db_get_new();

	local $@;
	$| = 1;

	# handle errors
	eval{
		# connect to vm monitor
		log_info($ffid, "establishing connection.. addr [$db->{'vm'}{'monitor'}{'addr'}] port [$db->{'vm'}{'monitor'}{'port'}]");

		$socket = new IO::Socket::INET (
			PeerHost => $db->{'vm'}{'monitor'}{'addr'},
			PeerPort => $db->{'vm'}{'monitor'}{'port'},
			Proto => $db->{'vm'}{'monitor'}{'proto'},

			#Blocking => '0',
		) or warn "$fid ERROR in Socket Creation : $!\n";

		# settle
		sleep (1);	
		
		# read monitor socket
		$data = <$socket>;
		log_info($ffid, "qemu responded [$data]");
		
		# initiate migration request
		log_info($ffid, "configuring migrate speed [10G]");
		my $packet = "migrate_set_speed 10G"; 
		print $socket "$packet\n";

		# wait for data
		sleep (1);

		# read data
     	$data = <$socket>;
		log_info($ffid, "QEMU QMP [$data]");

		# settle and close
		sleep (1);
		$socket->close();

		# process initiated
		log_info($ffid, "success: migration speed configured");
		$return = packet_build_encode("1", "success: command completed", $fid);
	};			

	# error
	if($@){
		# connection failed
		log_warn($ffid, "FATAL ERROR: Connection failed!");
		$return = packet_build_encode("0", "error: connection failed", $fid);
		#$return = 2;
	}
	
	return $return;
}

#
# request vm shutdown [JSON-STR]
#	
sub vmm_shutdown($packet){
	my $fid = "[vmm_shutdown]";
	my $ffid = "VMM|SHUTDOWN";
	my ($data, $result, $return);
	my ($socket,$client_socket);
	my $db = vmm_db_get_new();
	my %vmshare = vmshare_get();

	local $@;
	$| = 1;

	# handle errors
	eval{
		# connect to vm monitor
		log_info($ffid, "establishing connection.. addr [$db->{'vm'}{'monitor'}{'addr'}] port [$db->{'vm'}{'monitor'}{'port'}]");

		$socket = new IO::Socket::INET (
			PeerHost => $db->{'vm'}{'monitor'}{'addr'},
			PeerPort => $db->{'vm'}{'monitor'}{'port'},
			Proto => $db->{'vm'}{'monitor'}{'proto'},

		) or die "$fid ERROR in Socket Creation : $!\n";

		# settle
		sleep (1);	
		
		# read monitor socket
		$data = <$socket>;
		
		log_info($ffid, "qemu responded [$data]. initializing VM shutdown");
		my $packet = "system_powerdown"; 
		print $socket "$packet\n";

		# wait for data
		sleep (1);

		# read data
     	$data = <$socket>;
     	
		log_info($ffid, "QEMU QMP [$data]");

		# settle and close
		sleep (1);
		$socket->close();

		# get vmshare and update status
		%vmshare = vmshare_get();
		$vmshare{'vm_shutdown'} = 1;
		vmshare_set(%vmshare);

		# process initiated
		log_info($ffid, "success: system shutdown request completed");
		$return = packet_build_encode("1", "success: system shutdown request completed", $fid);
	};			

	# error
	if($@){
		# connection failed
		log_error($ffid, "FATAL ERROR: Connection failed!");
		$return = packet_build_encode("2", "error: connection failed", $fid);
	}
	
	return $return;
}

#
# request vm sreboot [JSON-STR]
#	
sub vmm_reboot($packet){
	my $fid = "[vmm_reboot]";
	my $ffid = "VMM|REBOOT";
	my ($data, $result, $return);
	my ($socket,$client_socket);
	my $db = vmm_db_get_new();

	local $@;
	$| = 1;

	# handle errors
	eval{
		log_info($ffid, "establishing connection.. addr [$db->{'vm'}{'monitor'}{'addr'}] port [$db->{'vm'}{'monitor'}{'port'}]");
	
		# connect to vm monitor
		$socket = new IO::Socket::INET (
			PeerHost => $db->{'vm'}{'monitor'}{'addr'},
			PeerPort => $db->{'vm'}{'monitor'}{'port'},
			Proto => $db->{'vm'}{'monitor'}{'proto'},
		) or die "$fid ERROR in Socket Creation : $!\n";

		# settle
		sleep (1);	
		
		# read monitor socket
		$data = <$socket>;
		print "$fid vm responded: [$data]\n";	
		
		# initiate migration request
		print "[" . date_get() . "] $fid initiating vm reboot\n";
		my $packet = "system_reset"; 
		print "[" . date_get() . "] $fid packet [$packet]\n";
		print $socket "$packet\n";

		# wait for data
		print "[" . date_get() . "] $fid waiting for data to become ready..\n";
		sleep (1);

		# read data
     	$data = <$socket>;
		print "[" . date_get() . "] $fid QMP: $data\n";

		# settle and close
		sleep (1);
		$socket->close();

		# process initiated
		print "[" . date_get() . "] $fid initiated system reboot";
		$return = packet_build_encode("1", "success: command completed", $fid);
	};			

	# error
	if($@){
		# connection failed
		print "[" . date_get() . "] $fid FATAL ERROR: Connection failed!\n";
		$return = packet_build_encode("0", "error: connection failed", $fid);
		#$return = 2;
	}
	
	return $return;
}

1;
