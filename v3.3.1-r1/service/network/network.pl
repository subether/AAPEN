#
# ETHER|AAPEN|NETWORK - MAIN
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
use Time::HiRes qw(usleep nanosleep);
use threads;
use threads::shared;
use Sys::Hostname;
use Number::Bytes::Human qw(format_bytes);
use Net::Int::Stats;
use Net::Ifconfig::Wrapper;
use File::Slurp;


# ROOT
my $root;
BEGIN { 
	$root = `/bin/cat ../../../../env/root.cfg | tr -d '\n'`;
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
use aapen::base::string;
use aapen::base::dbshare;
use aapen::base::thread;

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;
use aapen::proto::ssl;

use aapen::api::cluster::local;


# REQ
require './lib/protocol.pm';
require './lib/db.lib.pm';
require './lib/cluster.lib.pm';
require './lib/device.lib.pm';
require './lib/infiniband.lib.pm';
require './lib/net.lib.pm';
require './lib/vm.lib.pm';
require './lib/tap.lib.pm';
require './lib/bridge.lib.pm';
require './lib/vpp.lib.pm';


# ENV
env_init();
env_sid_set("network");
env_version_set("v3.3.1");
env_root_set($root);


# SOCKET
my $socket_path = env_serv_sock_get("network");
$| = 1;

# CONFIG
my $network_config = config_init();
#json_encode_pretty($network_config);


# counters 
my $s_id = 0;
my $tick_us = 50000;
my $tick = 5;
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

# load storage state
my $db = config_state_load("network");

if($db && !$clean){
	log_info("INIT", "[STATE] recovering service state");
	net_db_set($db->{'network'});
}
else{
	log_info("INIT", "[STATE] initializing clean state");
	net_db_init();
}


#  HEADER
log_info("AAPEN", "Network [" . env_version() .  "] id [" . config_node_id_get() . "] name [" . config_node_name_get() . "] socket [$socket_path]");


# INIT
dev_conf_init();
dev_stats();
net_config_init();
net_check_status();
vpp_check_state();
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
# socket listener
#
sub socket_thread(){
	my $fid = "SOCKET";
	log_info($fid, "initializing socket [$socket_path]");
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
	my $keepalive = 2;

	sleep 2;
	dev_stats();
	network_stats();
	network_cdb_vm_check();
	network_cdb_sync();
	network_cdb_check();
	sleep 2;

	while(1)
	{
		# sleep
		usleep($tick_us * 10);
		
		# keepalive
		if(($counter % 100) eq 1){ 
			#if(env_verbose()){ print "#"; };
			$timer += 1;
		};
		$counter += 1;
		
		# keepalive
		if($timer == $keepalive){
			log_debug($fid, "synchronizing @ [" . $timer * 10 . "] sec");

			dev_stats();
			
			network_stats();				
			network_cdb_vm_check();
						
			network_cdb_sync();				
			network_cdb_check();

			$counter = 0;
			$timer = 0;
		}
	}
}

sub get_root(){
	return $root;
}

#
# ping pong
#
sub ping(){
	my $pong = packet_build_encode("1", "pong", "[ping]");
	return $pong;
}

#
# info (warning: buffers)
#
sub info(){
	my $packet;
	$packet->{'net'}{'version'} = env_version();
	$packet->{'net'}{'bridb'} = bri_info();
	$packet->{'net'}{'tapdb'} = tap_info();
	$packet->{'net'}{'netdb'} = net_info();
	$packet->{'net'}{'vppdb'} = vpp_info();
	$packet->{'net'}{'vnetdb'} = vnet_info();
	return json_encode($packet);
}

#
# metadata
#
sub meta(){
	my $fid = "[meta]";
	my $packet = packet_build_noencode("1", "success: returning metadata", $fid);
	
	$packet->{'net'}{'version'} = env_version();
	$packet->{'net'}{'net_index'} = net_meta();
	$packet->{'net'}{'tap_index'} = tap_meta();
	$packet->{'net'}{'vpp_index'} = vpp_meta();
	$packet->{'net'}{'vnet_index'} = vnet_meta();
	$packet->{'net'}{'vm_index'} = vm_meta();

	if(env_verbose()){ 
		print "[" . date_get() . "] $fid network metadata\n";
		json_encode_pretty($packet); 
	};
	
	return json_encode($packet);
}


