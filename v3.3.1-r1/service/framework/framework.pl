#
# ETHER|AAPEN|FRAMEWORK - MAIN
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
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN );
use IO::Socket::INET;
use JSON::MaybeXS;
use Expect;
use TryCatch;
use threads;
use threads::shared;
use Time::HiRes qw(usleep nanosleep);
use Scalar::Util qw(looks_like_number);	
use Number::Bytes::Human qw(format_bytes);


# ROOT
my $root;
BEGIN { 
	$root = `/bin/cat ../../env/root.cfg | tr -d '\n'`;
	print "[init] root [$root]\n";
};
use lib $root . "lib/";

# LIBS
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
use aapen::proto::ssl;

use aapen::api::protocol;
use aapen::api::vmm::local;
use aapen::api::cluster::local;

# REQ
require './lib/db.lib.pm';
require './lib/frame.lib.pm';
require './lib/vmm.lib.pm';
require './lib/service.lib.pm';
require './lib/cluster.lib.pm';

# ENV
env_init();
env_sid_set("framework");
env_version_set("v3.3.1");
env_root_set($root);

# CONFIG
my $cluster_config = config_init();
json_encode_pretty($cluster_config);

# SOCKET
my $socket_path = env_serv_sock_get("framework");
$| = 1;

# VARS
my $s_id = 0;
my $tick = 5;
my $tick_us = 10000;
my $fid = "framework";
my $clean = 0;


log_info($fid, "AAPEN Framework [" . env_version() . "] initializing socket [$socket_path]");

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
	if($flags eq "boot"){ $clean = 1; frame_boot(); };
}


# load hypervisor state
my $db = config_state_load("framework");

if($db && !$clean){
	log_info("INIT|DB|STATE", "recovering state");
	frame_db_set($db->{'framework'});
	json_encode_pretty($db->{'framework'});
	
}
else{
	log_info("INIT|DB|CLEAN", "initializing clean database");
	frame_db_init();
}


# INIT
main();

#
# main thread
#
sub main(){
	my $fid = "MAIN";
	
	# check for socket
	if(!$socket_path){
		log_fatal($fid, "no socket defined!");
		die "$fid error: no socket defined!\n";
	}
	
	# spawn threads
	my $sockthr = threads->create( \&socket_thread );
	my $syncthr = threads->create( \&sync_thread );

	# init main loop
	log_info($fid, "initializing...");

	do{	
		thread_monitor($sockthr, \&socket_thread, "SOCKET");
		thread_monitor($syncthr, \&sync_thread, "SYNC");
		sleep $tick;		
	}while(1);
}

#
# socket thread
#
sub socket_thread(){
	my $fid = "SOCKET";
	log_info($fid, "initializing...");
	my $socket;
	
	unlink($socket_path);
	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $socket_path,
		Listen => SOMAXCONN,
	)
	or die("$fid fatal: socket failed init! [$!]\n");
	
	socket_set_perm($socket_path);
	
	while(1)
	{
		my $return;
		
		$socket = $listener->accept()
			or die("$fid session id [$s_id] fatal: listener failed! [$!]\n");
	
		# rececive
		my $data = <$socket>;
		
		# analyze
		if($data){
			chomp($data);
			
			log_debug($fid, "session id [$s_id] packet [$data]");
			
			# authenticate
			$return = auth($data, $s_id);
	
			if($return->{'proto'}{'result'} eq "1"){
				$return = protocol(json_decode($data));
			}
			
			print $socket "$return\n";
			usleep($tick_us);
		}
		else{
			log_warn($fid, "session id [$s_id] error: no data received!");
		}
		
		# close session
		log_debug($fid, "session id [$s_id] completed");
		$s_id++;
	}

	$socket->close();
}

#
# sync thread
#
sub sync_thread(){
	my $fid = "SYNC";
	log_info($fid, "initializing...");
	
	# counters
	my $counter = 0;
	my $timer = 0;
	my $keepalive = 3;

	sleep 2;
	frame_cdb_sync();

	while(1)
	{
		# sleep
		usleep($tick_us * 10);
		
		# keepalive
		if(($counter % 100) eq 1){ 
			$timer += 1;
		};
		$counter += 1;
		
		# keepalive
		if($timer == $keepalive){
			log_debug($fid, "synchronizing @ [" . $timer * 10 . "] sec");
			
			frame_cdb_sync();
			$counter = 0;
			$timer = 0;
		}
		
	}
}

#
# protocol [JSON-STR]
#
sub protocol($packet){
	my $fid = "PROTOCOL";
	my $err = "";
	my $result = 0;

	try{
		if(env_verbose()){
			print "[" . date_get() . "] $fid packet\n";
			json_encode_pretty($packet);
		}
		
		my $request = $packet->{'frame'}{'req'};
		if(env_debug()){ json_encode_pretty($packet); };
		print "[" . date_get() . "] $fid request [$request]\n";
		
		# ping pong
		if(($request eq "ping")){
			$result = packet_build_encode("1", "pong", "[ping]");
			
			my $frame = frame_db_get();
			json_encode_pretty($frame);
			
		};

		# framework meta
		if(($request eq "meta")){
			$result = frame_db_meta_get();
		};

		# environment
		if(($request eq "env")){
			$result = env_update($packet->{'frame'});
			json_encode_pretty($result);
		};

		# environment
		if(($request eq "shutdown")){
			$result = frame_shutdown($packet);
		};

		# vmm actions
		if(($request eq "vmm")){
			log_info($fid, "vmm req [" . $packet->{'vmm'}{'req'} . "]");

			if($packet->{'vmm'}{'req'} eq "info"){ $result = frame_vmm_info($packet); };
			if($packet->{'vmm'}{'req'} eq "start"){ $result = frame_vmm_start($packet); };
			if($packet->{'vmm'}{'req'} eq "stop"){ $result = frame_vmm_stop($packet); };
		};

		# service actions
		if(($request eq "srv")){
			log_info($fid, "srv req [" . $packet->{'srv'}{'req'} . "] srv [" . $packet->{'srv'}{'id'} . "]");

			if($packet->{'srv'}{'req'} eq "info"){ $result = frame_srv_info($packet); };
			if($packet->{'srv'}{'req'} eq "start"){ $result = frame_srv_start($packet); };
			if($packet->{'srv'}{'req'} eq "stop"){ $result = frame_srv_stop($packet); };
			if($packet->{'srv'}{'req'} eq "restart"){ $result = frame_srv_restart($packet); };
			if($packet->{'srv'}{'req'} eq "clear_state"){ $result = frame_srv_clear_state($packet); };
			if($packet->{'srv'}{'req'} eq "log_clear"){ $result = frame_srv_log_clear($packet); };
		};		

		if(!$result){
			log_warn($fid, "failed to process command");
			$result = packet_build_encode("0", "error: failed to process command", $fid);
		}
	}	
	catch{
		log_error($fid, "fatal error during processing!");
		$result = packet_build_encode("0", "error: fatal error during processing!", $fid);
	}	 
	
	return $result;
}

#
# return root
#
sub get_root(){
	return $root;
}
