#
# ETHER - AAPEN - CLUSTER - MAIN
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
use Cpanel::JSON::XS;
use JSON::MaybeXS;
use Expect;
use TryCatch;
use threads;
use threads::shared;
use Time::HiRes qw(usleep nanosleep);

use IO::Socket::SSL;
use IO::Async::Loop;
use IO::Async::Function;
use IO::Async::Timer::Periodic;


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

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;

use aapen::api::cluster::lib;
use aapen::api::cdb::local;

use aapen::hw::detect;

# REQ
require './lib/db.lib.pm';
require './lib/cluster.lib.pm';
require './lib/packet.lib.pm';
require './lib/sync.lib.pm';
require './lib/mcast.lib.pm';
require './lib/zmq.server.lib.pm';
require './lib/zmq.client.lib.pm';
require './lib/zmq.sync.lib.pm';


# ENV
env_init();
env_sid_set("cluster");
env_version_set("v3.3.1");
env_root_set($root);
my $cluster_uid = int(rand(100000));

# SOCKET
my $socket_path = env_serv_sock_get("cluster");
$| = 1;

# CONFIG
my $cluster_config = config_init();
json_encode_pretty($cluster_config);

# tickrate 1000 usec / 0.01 sec
my $tick_us = 10000;
my %vmshare :shared;

# VARS
my $cluster_type;
my $zmq_enable = 0;
my $mc_enable = 1;
my $s_id = 0;
my $tick = 5;


#
# Initialize flags
#
foreach my $flags (@ARGV){

	if($flags eq "mc_disable"){
		log_info("INIT", "[DISABLING MULTICAST]");
		$mc_enable = 0;
	}	
	
	if($flags eq "mc_enable"){
		log_info("INIT", "[ENABLING MULTICAST]");
		$cluster_type = "multicast";
		$mc_enable = 1;
	}
	
	if($flags eq "server"){
		log_info("INIT", "[INITIALIZING SERVER]");
		$cluster_type = "server";
		$zmq_enable = 1;
	}
	
	if($flags eq "client"){
		log_info("INIT", "[INITIALIZING CLIENT]");
		$cluster_type = "client";
		$zmq_enable = 1;
	}
	
	if($flags eq "sync"){
		log_info("INIT", "[INITIALIZING SYNC SERVER]");
		$cluster_type = "sync";
		$zmq_enable = 1;
	}
	
	if($flags eq "verbose"){ env_verbose_on() };
	if($flags eq "info"){ env_info_on() };
	if($flags eq "debug"){ env_debug_on() };
	if($flags eq "silent"){ env_silent_on() };
	if($flags eq "daemon"){ env_daemon_on() };
}

# default cluster (multicast client)
if(!$cluster_type){
	log_info("INIT", "[DEFAULT] [INITIALIZING MULTICAST CLIENT]");
	$cluster_type = "client";
	$mc_enable = 1;
}

log_info("INIT", "AAPEN Cluster [" . env_version_get() . "] initializing");


# INIT
cluster_cdb_check();
cluster_db_init();
cluster_db_cdb_meta_sync();

main();

#
# main thread
#
sub main(){
	my $fid = "MAIN";
	
	my $mc_init = 0;
	my $zmq_client_init = 0;
	my $zmq_server_init = 0;
	my $zmq_sync_init = 0;
	
	# threads
	my $mc_txthr;
	my $mc_rxthr;
	my $zmq_txthr;
	my $zmq_rxthr;
	my $zmq_pubthr;
	my $zmq_subthr;
	my $zmq_sync_pubthr;
	my $zmq_sync_subthr;

	log_info($fid, "initializing threads...");
	
	# check for socket
	if(!$socket_path){
		log_fatal($fid, "no socket defined!");
		die "$fid error: no socket defined!\n";
	}
	
	# spawn threads
	my $sockthr = threads->create( \&socket_thread );
	my $dbthr = threads->create( \&db_thread );
	my $syncthr = threads->create( \&sync_thread );
	
	# ZMQ server
	if($cluster_type eq "server" && $zmq_enable){
		$zmq_server_init = 1;
		$zmq_rxthr = threads->create( \&zmq_server );
		$zmq_pubthr = threads->create( \&zmq_publisher );
	}
	
	# ZMQ client
	if($cluster_type eq "client" && $zmq_enable){
		$zmq_client_init = 1;
		$zmq_txthr = threads->create( \&zmq_client );
		$zmq_subthr = threads->create( \&zmq_subscriber );
	}

	# ZMQ sync
	if($cluster_type eq "sync" && $zmq_enable){
		$zmq_server_init = 1;
		$zmq_sync_init = 1;
		$zmq_rxthr = threads->create( \&zmq_server );
		$zmq_pubthr = threads->create( \&zmq_publisher );
		$zmq_sync_pubthr = threads->create( \&zmq_sync_publisher );
		$zmq_sync_subthr = threads->create( \&zmq_sync_subscriber );		
	}

	# multicast
	if($mc_enable){
		$mc_init = 1;
		$mc_txthr = threads->create( \&mc_tx );
		$mc_rxthr = threads->create( \&mc_rx );
	}

	# init main loop
	log_info($fid, "initializing thread monitors...");

	do{		
		# common threads
		thread_monitor($sockthr, \&socket_thread, "SOCKET");
		thread_monitor($dbthr, \&db_thread, "DB");
		thread_monitor($syncthr, \&sync_thread, "SYNC");
		
		# Multicast
		if($mc_init){
			thread_monitor($mc_rxthr, \&mc_rx, "MC_RX");
			thread_monitor($mc_txthr, \&mc_tx, "MC_TX");
		}
		
		# ZMQ client
		if($zmq_client_init){
			thread_monitor($zmq_txthr, \&zmq_client, "ZMQ_TX");
			thread_monitor($zmq_subthr, \&zmq_subscriber, "ZMQ_SUB");	
		}

		# ZMQ server
		if($zmq_server_init){
			thread_monitor($zmq_rxthr, \&zmq_server, "ZMQ_RX");
			thread_monitor($zmq_pubthr, \&zmq_publisher, "ZMQ_PUB");
		}

		# ZMQ sync
		if($zmq_sync_init){
			thread_monitor($zmq_sync_pubthr, \&zmq_sync_publisher, "ZMQ_SYNC_PUB");
			thread_monitor($zmq_sync_subthr, \&zmq_sync_subscriber, "ZMQ_SYNC_SUB");
		}
		
		sleep $tick;
	}while(1);
}

#
# socket listener
#
sub socket_thread(){
	my $fid = "SOCKET";
	log_info($fid, "thread initiallizing...");
	my $socket;
	
	unlink($socket_path);
	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $socket_path,
		Listen => SOMAXCONN,
	)
	or die("$fid fatal: socket failed init! [$!]\n");
	
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
# protocol handler [JSON-STR]
#
sub protocol($packet){
	my $fid = "PROTOCOL";
	my $err = "";
	my $result = 0;
	
	# 10000 usec * 20 = 0.5 second
	my $tick_warn = 50;
	# 10000 usec * 100 = 1.0 seconds
	my $timeout = 100;

	try{
		my $request = $packet->{'proto'}{'packet'};
		
		if(env_debug()){ 
			log_debug($fid, "request [$request]");
			json_encode_pretty($packet) 
		};

		#
		# ping pong
		#
		if($packet->{'cluster'}{'req'} eq "ping"){
			$result = packet_build_encode("1", "pong", "[ping]");
		}
		else{
			$result = request_process($packet->{'cluster'}{'req'}, $packet);
		}

		#
		# invalid request
		#
		if(!$result){
			$result = packet_build_encode("0", "error: failed to process command", $fid);
			
		}
	}	
	catch{
		log_error($fid, "fatal error during processing!");

		$result = packet_build_noencode("0", "error: fatal error during processing!", $fid);
		$result->{'request'}{'proto'} = $packet->{'proto'};
		$result->{'request'}{'cluster'} = $packet->{'cluster'};
		
		json_encode_pretty($result);
		$result = json_encode($result);
	}
	
	return $result;
}

#
# process request [JSON-STR]
#		
sub request_process($req, $packet){
	my $fid = "[request_process]";
	my $ffid = "REQ|PROCESS";
	my $result;
	
	my $tick_warn = 100;
	# 1000 usec * 200 = 0.2 seconds
	my $timeout = 200;
		
	# encode request
	$vmshare{$req . '_req'} = json_encode($packet);
	$vmshare{$req} = 1;
	
	my $timer = 0;
	do{
		usleep($tick_us);
		$timer++;
		
		if($timer > $tick_warn){ log_warn($ffid, "[$ffid|$req] waited > [$tick_warn] ticks [$timer]..."); };
		if($timer >= $timeout){
			$vmshare{$req} = 0;
			log_warn($fid, "req [$req] timed out waiting for response");
			$result = packet_build_encode("0", "error: [$req] timed out waiting for response", $fid);
		};
	}while($vmshare{$req});
	
	$result = $vmshare{$req .'_ret'};
	$result = protocol_add_time($result, ($timer * $tick_us));
	return $result;
}

#
# db thread
#
sub db_thread(){
	my $fid = "DB";
	log_info($fid, "thread initializing...");
	
	# counters
	my $counter = 0;
	my $timer = 0;
	my $keepalive = 120;

	while(1)
	{
		# get key
		if($vmshare{'meta_get'}){
			log_debug($fid, "received [meta_get] request");
			$vmshare{'meta_get_ret'} = cluster_meta_get();
			$vmshare{'meta_get'} = 0;
		}
		
		# get full db
		if($vmshare{'db_get'}){
			log_debug($fid, "received [db_get] request");
			$vmshare{'db_get_ret'} = cluster_db_get_full();
			$vmshare{'db_get'} = 0;
		}

		# get object
		if($vmshare{'obj_get'}){
			log_debug($fid, "received [obj_get] request");
			$vmshare{'obj_get_ret'} = cluster_obj_get(json_decode($vmshare{'obj_get_req'}));
			$vmshare{'obj_get'} = 0;
		}
	
		# set object
		if($vmshare{'obj_set'}){
			log_debug($fid, "received [obj_set] request");
			$vmshare{'obj_set_ret'} = cluster_obj_set(json_decode($vmshare{'obj_set_req'}), 1, "local");
			$vmshare{'obj_set'} = 0;
		}

		# delete object
		if($vmshare{'obj_del'}){
			log_debug($fid, "received [obj_del] request");
			$vmshare{'obj_del_ret'} = cluster_obj_del(json_decode($vmshare{'obj_del_req'}), 1, "local");
			$vmshare{'obj_del'} = 0;
		}

		# set object metadata
		if($vmshare{'obj_meta_set'}){
			log_debug($fid, "received [obj_meta_set] request");
			$vmshare{'obj_meta_set_ret'} = cluster_obj_meta_set(json_decode($vmshare{'obj_meta_set_req'}), 1, "local");
			$vmshare{'obj_meta_set'} = 0;
		}

		# update environment
		if($vmshare{'env_update'}){
			log_debug($fid, "received [env_update] request");
			$vmshare{'env_update_ret'} = cluster_env_update(json_decode($vmshare{'env_update_req'}));
			$vmshare{'env_update'} = 0;
		}

		usleep($tick_us);
	}
}

#
# sync thread
#
sub sync_thread(){
	my $fid = "SYNC";
	log_info($fid, "thread initializing...");
	
	my $timer = 0;
	my $keepalive = 5;

	# publish node
	cluster_node_config();

	while(1)
	{
		# sleep
		sleep 1;

		# keepalive
		if($timer == $keepalive){
			log_debug($fid, "synchronizing cluster @ [" . $timer . "] sec");
			cluster_node_config();
			$timer = 0;
		}
		
		$timer++;
	}
}

#
# reuturn root [STRING] 
#
sub get_root(){
	return $root;
}

#
# return cluster UID [STRING]
#
sub get_cluster_uid(){
	return $cluster_uid;
}

#
# return cluster type [STRING]
#
sub get_cluster_type(){
	return $cluster_type;
}

#
# check if Mulitcast is enabled [BOOL]
#
sub get_mc_enabled(){
	return $mc_enable;
}

#
# check if cluster is ZeroMQ server [BOOL]
#
sub get_zmq_server(){
	if((get_cluster_type() eq "server" || (get_cluster_type() eq "sync"))){ return 1; }
	else{ return 0; };	
}

#
# check if cluster is ZeroMQ client [BOOL]
#
sub get_zmq_client(){
	if((get_cluster_type() eq "client") && $zmq_enable){ return 1; }
	else{ return 0; };	
}

#
# check if cluster is a ZeroMQ sync server [BOOL]
#
sub get_zmq_sync(){
	if(get_cluster_type() eq "sync"){ return 1; }
	else{ return 0; };	
}

#
# push node config to clusters [JSON-OBJ]
#
sub cluster_node_config(){
	my $ffid = "NODE|CONFIG";
	my $packet;
	my $config = db_obj_get("config");
	
	# build skeleton
	$packet->{'cluster'}{'req'} = "obj_set";
	$packet->{'cluster'}{'obj'} = "node";
	$packet->{'cluster'}{'key'} = config_node_name_get();
	$packet->{'cluster'}{'id'} = config_node_id_get();
	$packet->{'cluster'}{'version'} = env_version();

	# update meta
	my $node_config = config_node_get();
	$node_config->{'meta'}{'state'} = 1;
	$node_config->{'meta'}{'status'} = "online";
	$node_config->{'meta'}{'hw'} = hw_detect_brief();

	$packet->{'data'} = $node_config;
	$packet->{'data'}{'hw'} = hw_detect_brief();
	
	# publish
	cluster_obj_set($packet, 1, "local");
	
	log_debug($ffid, "update completed");
}
