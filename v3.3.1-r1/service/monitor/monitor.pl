#
# ETHER|AAPEN|MONITOR - MAIN
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
use Term::ANSIColor qw(:constants);
use JSON::MaybeXS;
use Expect;
use TryCatch;
use threads;
use threads::shared;
use Time::HiRes qw(usleep nanosleep);


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
use aapen::base::dbshare;
use aapen::base::config;
use aapen::base::thread;

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;
use aapen::proto::ssl;

use aapen::api::protocol;
use aapen::api::cluster::lib;
use aapen::api::cluster::local;

use aapen::api::external::mikrotik;

# REQ
require './lib/cluster.lib.pm';
require './lib/system.lib.pm';
require './lib/hypervisor.lib.pm';
require './lib/network.lib.pm';
require './lib/framework.lib.pm';
require './lib/node.lib.pm';
require './lib/storage.lib.pm';
require './lib/alarm.lib.pm';
require './lib/db.lib.pm';

# ENV
env_init();
env_sid_set("monitor");
env_version_set("v3.3.1");
env_root_set($root);
env_verbose_on();

# SOCKET
my $socket_path = env_serv_sock_get("monitor");
$| = 1;

# CONFIG
my $monitor_config = config_init();
json_encode_pretty($monitor_config);

# VARS
my $s_id = 0;
my $tick_us = 50000;
my $tick = 5;

#
# init flags
#
foreach my $flags (@ARGV){
	if($flags eq "verbose"){ env_verbose_on() };
	if($flags eq "info"){ env_info_on() };
	if($flags eq "debug"){ env_debug_on() };
	if($flags eq "silent"){ env_silent_on() };
	if($flags eq "daemon"){ env_daemon_on() };
}

# INIT
monitor_db_init();
main();


#
# main thread
#
sub main(){
	my $fid = "MAIN";
	
	# spawn socket thread
	print "[" . date_get() . "] $fid  spawning monitor thread\n";
	my $monthr = threads->create( \&monitor_thread );
	my $sockthr = threads->create( \&socket_thread );

	# init main loop
	print "[" . date_get() . "] $fid initializing main loop\n";
	do{
		thread_monitor($sockthr, \&socket_thread, "SOCKET");
		thread_monitor($monthr, \&monitor_thread, "MONITOR");
		sleep $tick;
	}while(1);
}

#
# monitor thread
#
sub monitor_thread(){
	my $fid = "MONITOR";

	# initialize
	print "\nAAPEN Cluster Monitor [" . env_version() . "] \n\n";
	
	do{
		if(env_debug()){ print "[" . date_get() . "] $fid monitor thread is running\n"; };
		mon_cluster_get_meta();
		sleep 10;
	}while(1);
}

#
# socket thread
#
sub socket_thread(){
	my $fid = "SOCKET";
	
	log_info($fid, "thread initializing");
	
	unlink($socket_path);
	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $socket_path,
		Listen => SOMAXCONN,
	)
	or die("$fid fatal: socket failed init! [$!]\n");
	
	my $socket;
	
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
			
			if(env_debug()){ print "[" . date_get() . "] $fid session id [$s_id] packet [$data]\n"; };
			
			# authenticate
			$return = auth($data, $s_id);
	
			if($return->{'proto'}{'result'} eq "1"){
				$return = protocol(json_decode($data));
			}
			
			print $socket "$return\n";
			usleep($tick_us);
		}
		else{
			if(env_verbose()){ print "[" . date_get() . "] $fid session id [$s_id] error: no data received!\n";};
		}
		
		# close session
		print "[" . date_get() . "] $fid session id [$s_id] completed\n";
		$s_id++;
	}

	$socket->close();
}

#
# protocol [JSON-STR]
#
sub protocol($packet) {
	my $fid = "monitor_protocol";
	my $ffid = "MONITOR Protocol";
	my $result = 0;

	try {
		if (env_debug()) {
			json_encode_pretty($packet);
		}
		
		my $request = $packet->{'monitor'}{'req'} // "";
		
		if ($request eq "ping") {
			$result = _build_monitor_response("[ping]", "pong");
		}

		if ($request eq "env") {
			$result = env_update($packet->{'monitor'});
		}

		if (!$result) {
			log_warn($fid, "failed to process command");
			$result = packet_build_encode("0", "error: failed to process command", $fid);
		}

	}	
	catch {
		log_error($fid, "fatal error during processing!");
		$result = packet_build_encode("0", "error: fatal error during processing!", $fid);
	}	 
	
	return $result;
}
