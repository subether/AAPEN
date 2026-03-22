#
# ETHER|AAPEN|HYPERVISOR - MAIN
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
use IO::Socket::INET;
use JSON::MaybeXS;
use TryCatch;
use Term::ANSIColor qw(:constants);
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN );
use Scalar::Util qw(looks_like_number);	
use Time::HiRes qw(usleep nanosleep);
use threads;
use threads::shared;
use File::Copy;
use File::Remove;
use Number::Bytes::Human qw(format_bytes);

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
use aapen::base::string;
use aapen::base::exec;
use aapen::base::config;
use aapen::base::dbshare;
use aapen::base::thread;

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;
use aapen::proto::ssl;

use aapen::net::port;

use aapen::hw::detect;

use aapen::api::protocol;
use aapen::api::vmm::local;
use aapen::api::network::local;
use aapen::api::framework::local;
use aapen::api::hypervisor::lib;
use aapen::api::cluster::local;
use aapen::api::cluster::lib;
use aapen::api::storage::local;

# REQ
require './lib/db.lib.pm';
require './lib/hyper.lib.pm';
require './lib/cluster.lib.pm';
require './lib/system.lib.pm';
require './lib/storage.lib.pm';
require './lib/async.lib.pm';
require './lib/hw.lib.pm';

# ENV
env_init();
env_sid_set("hypervisor");
env_version_set("v3.3.1");
env_root_set($root);

# CONFIG
my $hypervisor_config = config_init();
#json_encode_pretty($hypervisor_config);

# SOCKET
my $socket_path = env_serv_sock_get("hypervisor");
$| = 1;

# VARS
my $s_id = 0;
share($s_id);
my $tick = 5;
my $tick_us = 50000;
my $db = {};
my $clean = 0;

#
# init flags
#
foreach my $flags (@ARGV){
	if($flags eq "verbose"){ env_verbose_on() };
	if($flags eq "info"){ env_info_on() };
	if($flags eq "debug"){ env_debug_on() };
	if($flags eq "silent"){ env_silent_on() };
	if($flags eq "daemon"){ env_daemon_on() };
	if($flags eq "clean"){ $clean = 1; };
}


# load hypervisor state
$db = config_state_load("hypervisor");

if($db && !$clean){
	log_info("INIT", "[STATE] recovering service state");
	hyper_db_set($db->{'hypervisor'});
	hardware_stats();
}
else{
	log_info("INIT", "[STATE] initializing clean state");
	hyper_db_init();
	hardware_stats();
}


# HEADER
log_info("AAPEN", "Hypervisor [" . env_version() .  "] id [" . config_node_id_get() . "] name [" . config_node_name_get() . "] socket [$socket_path]");


# INIT
hyper_qemu_version();
cluster_node_sync();
main();


#
# MAIN THREAD
#
sub main(){
	my $fid = "hypervisor_main";
	my $ffid = "HYPERVISOR|MAIN";
	
	# check for socket
	if(!$socket_path){
		die "$ffid error: no socket defined!\n";
	}
	
	log_info($ffid, "initializing threads");

	# spawn threads
	my $sockthr = threads->create( \&socket_thread );
	my $syncthr = threads->create( \&sync_thread );
	my $workerthr = threads->create( \&worker_thread );

	# init main loop
	log_info($ffid, "initializing thread monitors");

	do{	
		thread_monitor($sockthr, \&socket_thread, "SOCKET");
		thread_monitor($syncthr, \&sync_thread, "SYNC");
		thread_monitor($workerthr, \&worker_thread, "WORKER");
		sleep $tick;
	}while(1);
}

#
# SOCKET LISTENER
#
sub socket_thread(){
	my $fid = "hypervisor_socket_thread";
	my $ffid = "HYPERVISOR|SOCKET";
	my $socket;

	log_info($ffid, "thread initializing");

	unlink($socket_path);
	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $socket_path,
		Listen => SOMAXCONN,
	)
	or die("$ffid fatal: socket failed init! [$!]\n");
	
	socket_set_perm($socket_path);
	
	while(1)
	{
		my $return;
		
		$socket = $listener->accept()
			or die("$ffid session id [$s_id] fatal: listener failed! [$!]\n");
	
		# receive
		my $data = <$socket>;
		
		# analyze
		if($data){
			chomp($data);
			
			# Conservative validation: check data length (prevent DoS)
			if (length($data) > 10_485_760) { # 10MB limit - conservative size
				log_error($ffid, "session id [$s_id] data too large: " . length($data) . " bytes");
				print $socket packet_build_encode("0", "error: data too large", $ffid);
				$socket->close();
				next;
			}
			
			# Conservative validation: basic JSON structure check
			unless (is_valid_json($data)) {
				log_error($ffid, "session id [$s_id] invalid JSON received");
				print $socket packet_build_encode("0", "error: invalid JSON", $ffid);
				$socket->close();
				next;
			}
			
			log_debug($ffid, "session id [$s_id] packet [$data]");
			
			# authenticate
			$return = auth($data, $s_id);
	
			if($return->{'proto'}{'result'} eq "1"){
				$return = protocol(json_decode($data));
			}
			
			print $socket "$return\n";
			usleep($tick_us);
		}
		else{
			log_warn($ffid, "session id [$s_id] error: no data received!");
		}
		
		# close session
		log_info($ffid, "session [$s_id] completed");
		$s_id++;
	}

	$socket->close();
}

#
# SYNC THREAD
#
sub sync_thread(){
	my $fid = "hypervisor_sync_thread";
	my $ffid = "HYPERVISOR|SYNC";
	log_info($ffid, "thread initializing");

	# counters
	my $counter = 0;
	my $timer = 0;
	my $keepalive = 2;

	# recover systems
	sleep 1;
	system_cluster_recover();
	#hardware_stats();
	
	sleep 2;
	system_health_check();
	hyper_system_stats();
	hyper_cdb_sync();
	system_orphan_check();
	
	
	while(1)
	{
		# sleep
		usleep($tick_us * 10);
		
		# keepalive
		if(($counter % 100) eq 1){ 
			if(env_verbose()){ print "#"; };
			#print "*";
			$timer += 1;
		};
		$counter += 1;
		
		# keepalive
		if($timer == $keepalive){
			log_info($ffid, "reached keepalive");		
			hyper_system_stats();
			system_health_check();
			hyper_cdb_sync();
			system_orphan_check();

			$counter = 0;
			$timer = 0;
		}
	}
}

#
# WORKER THREAD
#
sub worker_thread(){
	my $fid = "hypervisor_worker_thread";
	my $ffid = "HYPERVISOR|WORKER";
	log_info($ffid, "thread initializing");
	
	# counters
	my $counter = 0;
	my $timer = 0;
	my $keepalive = 2;

	sleep 2;
	
	hardware_stats();
	system_async_check();

	# decouple from sync
	sleep 13;


	while(1)
	{
		# sleep
		usleep($tick_us * 10);
		
		
		# keepalive
		if(($counter % 100) eq 1){ 
			$timer += 1;
			#print "#";
		};
		$counter += 1;
		
		if(async_job_check()){ 
			system_async_check();
		};
		
		# keepalive
		if($timer == $keepalive){
			log_info($ffid, "reached keepalive");
			system_async_check();
			hardware_stats();
			
			$counter = 0;
			$timer = 0;	
		}
	}
}

#
# PROTOCOL [JSON-STR]
#
sub protocol($packet){
	my $fid = "hypervisor_protocol";
	my $ffid = "HYPERVISOR|PROTOCOL";
	my $err = "";
	my $result = 0;

	try{
		my $request = $packet->{'hyper'}{'req'};
		log_debug($ffid, "request [$request]");
		
		# ping pong
		if($request eq "ping"){ $result = packet_build_encode("1", "pong", $ffid); };

		# service environment
		if($request eq "env"){ $result = env_update($packet->{'hyper'}); };
		
		# hypervisor info
		if($request eq "info"){ $result = hyper_info(); };
		
		# load vm (sync)
		if($request eq "load"){ $result = hyper_load($packet); };
		
		# unload vm (sync)
		if($request eq "unload"){ $result = hyper_unload($packet); }
		
		# destroy vm
		if($request eq "destroy"){ $result = hyper_destroy($packet); }
		
		# push vm config
		if($request eq "push"){ $result = hyper_push($packet); };
		
		# pull vm config
		if($request eq "pull"){ $result = hyper_pull($packet); };	
		
		# reset vm
		if($request eq "reset"){ $result = hyper_reset($packet); };
		
		# shutdown vm (graceful)
		if($request eq "shutdown"){ $result = hyper_shutdown($packet); };
		
		# proxy vmm info
		if($request eq "proxyinfo"){ $result = hyper_proxy_info($packet); };

		# delete system
		if($request eq "delete"){ $result = hyper_delete($packet); };	
		
		# validate system
		if($request eq "validate"){ $result = hyper_validate($packet); };

		# async system load
		if($request eq "sys_load_async"){ $result = async_system_load($packet); };

		# async system unload
		if($request eq "sys_unload_async"){ $result = async_system_unload($packet); };
		
		# async system shutdown
		if($request eq "sys_shutdown_async"){ $result = async_system_shutdown($packet); };

		# async system migration
		if($request eq "sys_migrate_async"){ $result = async_system_migrate($packet); };

		# migrate system metadata
		if($request eq "sys_migrate_meta"){ $result = hyper_system_meta_migrate($packet); };

		# async system clone
		if($request eq "sys_clone_async"){ $result = async_system_clone($packet); };

		# async system move
		if($request eq "sys_move_async"){ $result = async_system_move($packet); };

		# create system
		if($request eq "sys_create"){ $result = system_create($packet); };
		
		# add storage to system
		if($request eq "sys_stor_add"){ $result = system_storage_add($packet); };
		
		# expand storage on system
		if($request eq "sys_stor_expand"){ $result = system_storage_expand($packet); };

		
		if(!$result){
			$result = packet_build_encode("0", "error: failed to process command!", $ffid);
		}
		
	}	
	catch{
		log_error($ffid, "error: fatal error during processing!");
		$result = packet_build_encode("0", "error: fatal error during processing!", $ffid);
	}	 
	
	return $result;
}

#sub get_root(){
#	return $root;
#}

#
# get cluster metadata [JSON-OBJ]
#
sub api_loc_cluster_meta_get(){
	my $fid = "hypervisor_api_loc_cluster_meta_get";
	my $ffid = "HYPERVISOR|API|CLUSTER|META|GET";	
	my $result = api_cluster_local_meta_get(env_serv_sock_get("cluster"));
	return $result;
}

#
# get object from cluster [JSON-OBJ]
#
sub api_loc_cluster_obj_get($object, $key){
	my $fid = "hypervisor_api_loc_cluster_obj_get";
	my $ffid = "HYPERVISOR|API|CLUSTER|OBJ|GET";
	my $result = api_cluster_local_obj_get(env_serv_sock_get("cluster"), $object, $key);
	return $result;
}

#
# Conservative validation: JSON validation helper
#
sub is_valid_json($data) {
	my $fid = "hypervisor_is_valid_json";
	my $ffid = "HYPERVISOR|VALIDATION|JSON";
	
	try {
		# Quick syntax check - ensure it's valid JSON
		decode_json($data);
		return 1;
	}
	catch {
		# Conservative approach: log at debug level to avoid noise
		log_debug($ffid, "JSON validation failed: $_");
		return 0;
	}
}
