#
# ETHER - AAPEN - STORAGE SERVICE
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
use Expect;
use Sys::Hostname;
use Filesys::Df;
use Filesys::DiskUsage::Fast;


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
use aapen::base::config;
use aapen::base::thread;
use aapen::base::dbshare;

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;
use aapen::proto::ssl;

use aapen::api::cluster::local;

# REQ
require './lib/db.lib.pm';
require './lib/mount.lib.pm';
require './lib/device.lib.pm';
require './lib/mdraid.lib.pm';
require './lib/pool.lib.pm';
require './lib/nvme.lib.pm';
require './lib/cluster.lib.pm';

# ENV
env_init();
env_sid_set("storage");
env_version_set("v3.3.1");
env_root_set($root);
env_verbose_on();

# SOCKET
my $socket_path = env_serv_sock_get("storage");
$| = 1;

# CONFIG
my $storage_config = config_init();
json_encode_pretty($storage_config);

# VARS 
my $s_id = 0;
my $tick = 5;
my $tick_us = 50000;
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

# NEW DB
my $db = {};

# load storage state
$db = config_state_load("storage");

if($db && !$clean){
	log_info("INIT", "[STATE] recovering service state");
	storage_db_set($db->{'storage'});
	json_encode_pretty($db->{'storage'});

}
else{
	log_info("INIT", "[STATE] initializing clean state");
	$db = {};
	storage_db_init();
}

# initialize device and pool config
device_config_init();
pool_config_init();

print "\n\nAAPEN Storage [" . env_version() .  "] id [" . config_node_id_get() . "] name [" . config_node_name_get() . "] socket [$socket_path]\n\n";

main();


#
# main thread
#
sub main(){
	my $fid = "MAIN";
	
	# check for socket
	if(!$socket_path){
		die "$fid error: no socket defined!\n";
	}

	log_info($fid, "initializing threads...");
	
	# spawn threads
	my $sockthr = threads->create( \&socket_thread );
	my $syncthr = threads->create( \&sync_thread );
	
	log_info($fid, "initializing thread monitors...");

	do{	
		thread_monitor($sockthr, \&socket_thread, "SOCKET");
		thread_monitor($syncthr, \&sync_thread, "SYNC");
		sleep $tick;
	}while(1);
}

#
# socket listener
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
			log_warn($fid, "session id [$s_id] error: no data received");
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
	storage_cdb_sync();

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
			
			storage_cdb_sync();
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
		json_encode_pretty($packet);
		my $request = $packet->{'storage'}{'req'};
		
		# ping pong
		if($request eq "ping"){ 
			$result = packet_build_encode("1", "pong", "[ping]");
		};

		# ping pong
		if($request eq "meta"){ 
			$result = storage_db_meta($request);
			storage_db_print();
		};

		# environment
		if(($request eq "env")){
			$result = env_update($packet->{'storage'});
		};

		# ping pong
		if($request eq "pool_set"){ 
			$result = storage_pool_set($packet);
		};

		# ping pong
		if($request eq "pool_get"){ 
			$result = storage_pool_get($packet);
		};

		if(!$result){
			$result = packet_build_encode("0", "error: failed to process command", $fid);
		}

	}	
	catch{
		log_error($fid, "error: fatal error during processing");
		$result = packet_build_encode("0", "error: fatal error during processing!", $fid);
	}	 
	
	return $result;
}

#
# return root [PATH]
#
sub get_root(){
	return $root;
}

