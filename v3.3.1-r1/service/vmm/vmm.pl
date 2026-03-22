#
# ETHER|AAPEN|VMM - MAIN
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#

use warnings;
#use strict; # threading breaks strict
use experimental 'signatures';
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN );
use JSON::MaybeXS;
use Expect;
use TryCatch;
use threads;
use threads::shared;
use Time::HiRes qw(usleep nanosleep);
use Hash::Merge qw(merge);
use IO::Socket::INET;
use IO::Select;	

# ROOT
my $root;
BEGIN { 
	$root = `/bin/cat ../../env/root.cfg | tr -d '\n'`;
	print "[init] root [$root]\n";
};
use lib $root . "lib/";

# LIB
use aapen::base::log;
use aapen::base::envthr;
use aapen::base::date;
use aapen::base::json;
use aapen::base::file;
use aapen::base::index;
use aapen::base::exec;
use aapen::base::lock;
use aapen::base::config;
use aapen::base::string;
use aapen::base::dbshare;
use aapen::base::thread;

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;

use aapen::api::cluster::local;


# REQ
require './lib/kvm.lib.pm';
require './lib/vmm.lib.pm';
require './lib/db.lib.pm';

# SOCKET
my $socket_path = $ARGV[0];
$| = 1;

# ENV
env_init();
env_sid_set("vmm");
env_version_set("v3.3.1");
env_root_set($root);
w
my $sid = "[vmm]";

# protocol counters 
my $s_id = 0;
my $tick_us = 50000;

# network
my $data;
my $socket;

# threading 
my %vmshare :shared;
my $vmmstatus = 0; 
my $vmmthr;

# migration
my $migstatus = 0;
my $migthr;

# thread flag
my $vmmflag = 0;

# cdb init
my $cdb_init = 0;


# INIT
config_init();
vmm_db_init();
main();

#
# main thread handler
#
sub main(){
	my $fid = "[MAIN]";
	my $ffid = "VMM|MAIN";

	# check for socket
	if(!$socket_path){
		die "$fid error: no socket defined!\n";
	}
	
	my $sockthr = threads->create( vmm_socket );

	my $cdb_ref = 0;
	
	try{
		# initialize main loop
		log_info($ffid, "initializing main loop");
		do{
			threads->yield();
			
			#
			# monitor socket thread
			#
			if($sockthr->is_running()){
				log_debug($ffid, "[THREAD|SOCK] thread is running");
			}
			if($sockthr->is_joinable()){
				log_warn($ffid, "[THREAD|SOCK] thread is joinable!");
				$sockthr->join();
			}
			if($sockthr->error()){
				log_warn($ffid, "[THREAD|SOCK] thread error!");
			}

			#
			# monitor vmm threads
			#
			if($vmshare{'vmminit'}){			
				# check status
				if($vmmstatus){
		
					# monitor socket thread
					if($vmmthr->is_running()){
						$vmshare{'vmmstatus'} = 1;
						$vmshare{'vm_running'} = 1;
					}
					if($vmmthr->is_joinable()){
						log_warn($ffid, "[THREAD|VMM] thread is joinable!");
						$vmmthr->join();
						
						# update shared data
						$vmshare{'vmmstatus'} = 0;
						$vmshare{'vm_running'} = 0;
						
						if($vmshare{'vm_shutdown'}){
							$vmshare{'vm_status'} = "shutdown";
							log_info($ffid, "[THREAD|VMM] vm status is [SHUTDOWN]");
						}
						else{
							$vmshare{'vm_status'} = "ended";
							log_info($ffid, "[THREAD|VMM] vm status is [ENDED]");
						}
						
						vmmdb_cluster_update();
					}
					if($vmmthr->error()){
						log_warn($ffid, "[THREAD|VMM] thread error!");
						$vmshare{'vmmstatus'} = 2;
						$vmshare{'vm_running'} = 0;
						
						if($vmshare{'vm_shutdown'}){
							$vmshare{'vm_status'} = "shutdown";
							log_info($ffid, "[THREAD|VMM] vm status is [SHUTDOWN]");
						}
						else{
							$vmshare{'vm_status'} = "error";
							log_info($ffid, "[THREAD|VMM] vm status is [ENDED]");
						}
						
						vmmdb_cluster_update();
					}
				}
				else{
					# spawn 
					log_info($ffid, "[THREAD|VMM] spawming container - exec [$vmshare{'vmmexec'}]");
					vmm_hyper();
					
					# return - TODO better error handling
					$vmmstatus = 1;
					log_info($ffid, "[THREAD|VMM] returned to main loop. status [$vmmstatus]");
				}
			}
			else{
				# vmm thread not yet initialized
				if(!$vmmflag){
					log_info($ffid, "[THREAD|VMM] thread not initialized");
					if(!env_debug()){ $vmmflag = 1; };
				}
			}

			#
			# monitor migration thread
			# 
			if($vmshare{'miginit'}){
				log_info($ffid, "[THREAD|MIGRATE] migration initialized!");
			
				# check status
				if($migstatus){
		
					# monitor socket thread
					if($migthr->is_running()){
						# migration active
						log_info($ffid, "[THREAD|MIGRATE] thread is running");
						$vmshare{'migactive'} = 1;
						$vmshare{'migstarted'} = 1;
					}
					if($migthr->is_joinable()){
						# migration completed
						log_warn($ffid, "[THREAD|MIGRATE] thread is joinable");
						$migthr->join();
						$vmshare{'migactive'} = 0;
						$vmshare{'migstarted'} = 0;
					}
					if($migthr->error()){
						# migration thread failed
						log_warn($ffid, "[THREAD|MIGRATE] thread error");
						$vmshare{'migactive'} = 0;
						$vmshare{'migerr'} = 1;
						$vmshare{'migerrmsg'} = "thread error!";
					}
				}
				else{
					# spawn migration thread
					log_warn($ffid, "[THREAD|MIGRATE] spawning vmm migration thread");
					my $result = vmm_migrate_handler();
					
					# return - TODO better error handling
					$migstatus = 1;
					log_warn($ffid, "[THREAD|MIGRATE] vmm migration returned to main loop. status [$migstatus]");
				}
			}
			else{
				log_debug($ffid, "[THREAD|MIGRATE] vmm not initialized");
			}

			sleep 2;

			# update every 30 sec
			if($cdb_ref == 15){
				vmmdb_cluster_update();
				$cdb_ref = 0;
			}
			$cdb_ref++;
				
		}while(1);
	}
	catch{
		log_error($ffid, "error: main thread failed!");
	}
}

#
# socket listener
#
sub vmm_socket(){
	my $fid = "[SOCKET]";
	my $ffid = "VMM|SOCKET";

	# initialize
	log_info($ffid, "initializing socket [$socket_path]");
	
	# create listener
	unlink($socket_path);
	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $socket_path,
		Listen => SOMAXCONN,
	)
	or die("$fid fatal: socket failed init! [$!]\n");
	
	# init listener
	while(1)
	{
		try{
			$socket = $listener->accept()
				or warn("$fid session id [$s_id] fatal: listener failed! [$!]\n");
		
			# rececive data
			$data = <$socket>;
			
			# analyze
			if($data){
				chomp($data);
				
				log_debug($ffid, "session id [$s_id] packet [$data]");
				
				# authenticate
				my $return = auth($data, $s_id);
		
				if($return->{'proto'}{'result'} eq "1"){
					$return = protocol(json_decode($data));
				}
				
				print $socket "$return\n";
				usleep($tick_us);
			}
			else{
				log_warn($ffid, "error session id [$s_id] error: no data received!");
			}
			
			# close session
			log_info($ffid, "session id [$s_id] completed");
			$s_id++;
		
		}
		catch{
			log_warn($ffid, "operation failed");
		}
	}
	
	$socket->close();
}

#
# vmm hypervisor
#
sub vmm_hyper(){
	my $fid = "[HYPERVISOR]";
	my $ffid = "VMM|HYPERVISOR";

	# get thread id
	log_info($ffid, "exec [$vmshare{'vmmexec'}]");
	log_info($ffid, "lock [$vmshare{'vmmlock'}]");
		
	# spawn thread
	$vmmthr = threads->create( vmm_spawn );
	$vmmstatus = 1;
	my $sync_timer = 0;
	
	# wait for process to settle
	sleep 2;
	
	try{
		# do some preliminary tests on thread
		if($vmmthr->is_running()){
			# thread is running
			log_debug($ffid, "thread is running");
					
			# get pid
			$childpid = execute('pgrep -f ^qemu-system-x86_64.*' . $vmshare{'vmmlock'});
			chomp($childpid);
			
			# get output
			my $output = file_tail($vmshare{'vmmoutfile'}, "1"); 
			chomp($output);
			log_info($ffid, "thread is running. pid [$childpid] output [$output]");
			
			# export data
			$vmshare{'vmmpid'} = $childpid;
			$vmshare{'vmmout'} = $output;
			$vmshare{'vmmerr'} = 0;
			$vmshare{'vmmproc'} = 1;
			$vmshare{'vmmstat'} = 1;
			
			if(!$cdb_init){
				sleep 5;
				log_info($ffid, "initial CDB update");
				vmmdb_cluster_update();
				$cdb_init = 1;
			}
		}
		if($vmmthr->is_joinable()){
			# thread ended 	
			log_warn($ffid, "thread is joinable!");
			my $result = $vmmthr->join();

			# get output
			my $output = file_tail($vmshare{'vmmoutfile'}, "1"); 
			chomp($output);	
			log_warn($ffid, "thread ended with result [$result], output [$output]");
			
			# export data
			$vmshare{'vmmpid'} = 0;
			$vmshare{'vmmout'} = $output;
			$vmshare{'vmmerr'} = 1;
			$vmshare{'vmmproc'} = 1;
			$vmshare{'vmmstat'} = 1;
			
			$vmshare{'vm_running'} = "0";
			$vmshare{'vm_status'} = "ended_failure";
			$vmshare{'vm_state'} = "0";
			
			vmmdb_cluster_update();
		}
		if($vmmthr->error()){
			# thread error
			
			# get output
			my $output = file_tail($vmshare{'vmmoutfile'}, "1"); 
			chomp($output);
			log_error($ffid, "thread error! output [$output]");
			
			# export data
			$vmshare{'vmmpid'} = 0;
			$vmshare{'vmmout'} = $output;
			$vmshare{'vmmerr'} = 2;
			$vmshare{'vmmproc'} = 1;
			$vmshare{'vmmstat'} = 1;
			
			# new
			$vmshare{'vm_running'} = "0";
			$vmshare{'vm_status'} = "thread_error";
			$vmshare{'vm_state'} = "0";
			
			vmmdb_cluster_update();
		}
	}
	catch{
		log_error($ffid, "thread error!");
	}
}

#
# protocol handler [JSON-STR]
#
sub protocol($packet){
	my $fid = "[PROTOCOL]";
	my $ffid = "VMM|PROTOCOL";
	my $err = "";
	my $result = 0;

	try{
		log_info_json($ffid, "request [$packet->{'vmm'}{'req'}]", $packet);
		
		my $request = $packet->{'vmm'}{'req'};
	
		# ping pong
		if($request eq "ping"){ $result = ping(); };
		
		# vmm information
		if($request eq "info"){ $result = vmm_info(); };
		
		# vmm information
		if($request eq "info_new"){ $result = vmm_info_get(); };
		
		# receive vm data
		if($request eq "push"){ $result = vmm_push($packet); };
		
		# return vm data
		if($request eq "pull"){ $result = vmm_pull($packet); };
		
		# load vm
		if($request eq "load"){ $result = vmm_load($packet); };
		
		# unload vm
		if($request eq "unload"){ $result = vmm_unload(); };
		
		# migrate vm
		if($request eq "migrate"){ $result = vmm_migrate($packet); };
		
		# reset vm
		if($request eq "reset"){ $result = vmm_reboot($packet); };
		
		# shutdown vm
		if($request eq "shutdown"){ $result = vmm_shutdown($packet); };
		
		# general error
		if(!$result){
			log_warn($ffid, "error: failed to process command");
			$result = packet_build_encode("0", "error: failed to process command", $fid);
		}
	}	
	catch{
		log_error($ffid, "error: fatal error during processing");
		$result = packet_build_encode("0", "error: fatal error during processing!", $fid);
	}
	
	return $result;
}

#
# ping pong
#
sub ping(){
	my $pong = packet_build_encode("1", "pong", "[ping]");
	return $pong;
}

#
# spawn vmm thread
#
sub vmm_spawn(){
	my $fid = "[vmm_spawn]";
	my $ffid = "VMM|SPAWN";
	
	log_info($ffid, "exec [$vmshare{'vmmexec'}]");
	my $return = execute($vmshare{'vmmexec'} . " > " . $vmshare{'vmmoutfile'} . " 2>&1");
	log_info($ffid, "vmm spawn ended, result [$return]");
	return $return;
}

#
# spawn vmm thread
#
sub vmm_novnc_spawn(){
	my $fid = "[vmm_novnc_spawn]";
	my $ffid = "VMM|NOVNC|SPAWN";
	
	log_info($ffid, "novnc exec [$vmshare{'novncexec'}]");
	my $return = execute($vmshare{'novncexec'});
	return $return;
}

#
# vmm migration handler
#
sub vmm_migrate_handler(){
	my $fid = "[vmm_migrate_handler]";
	my $ffid = "VMM|MIGRATE|HANDLER";

	$migthr = threads->create( vmm_migrate_thread );
	sleep 1;

	if($migthr->is_running()){
		# thread is running
		log_info($ffid, "thread is running");

		$vmshare{'migstarted'} = 1;
		$vmshare{'migcomplete'} = 0;
	}
	if($migthr->is_joinable()){
		# thread ended 	
		log_warn($ffid, "thread is joinable!");
		my $result = $migthr->join();
	}
	if($migthr->error()){
		# thread error
		log_error($ffid, "thread error!");
	}
}

#
# spawn vmm migration thread
#
sub vmm_migrate_thread(){
	my $fid = "[vmm_migrate_thread]";
	my $ffid = "VMM|MIGRATE|THREAD";
	
	log_info($ffid, "initializing migration thread..");

	# get shared data
	my %vmshare = vmshare_get();

	log_info_json($ffid, "local vm data", $vmshare{'vm'});
	log_info_json($ffid, "migration data", $vmshare{'migdata'});

	# call migration init
	my $result = vmm_migrate_init($vmshare{'vm'}, $vmshare{'migdata'});

	return $result;
}

sub get_root(){
	return $root;
}

# TODO: migrate to new sharedb

#
# get shared db
#
sub vmshare_get(){
	{
		lock(%vmshare);
		return %vmshare;
	}
}

#
# set shared db
#
sub vmshare_set(%share){
	{
		lock(%vmshare);
		%vmshare = %share;
	}
}
