#
# ETHER|AAPEN|CDB - MAIN
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
use JSON::MaybeXS;
use TryCatch;
use threads;
use threads::shared;
use Time::HiRes qw(usleep nanosleep);


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
use aapen::base::index;
use aapen::base::dbshare;
use aapen::base::thread;
use aapen::base::config;
use aapen::base::file;

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;

# REQ
require './lib/db.lib.pm';

# ENV
env_init();
env_sid_set("cdb");
env_version_set("v3.3.1");
env_root_set($root);

my $config = config_init();

# SOCKET
my $socket_path = env_serv_sock_get("cdb");
$| = 1;

# VARS
my $s_id = 0;
my $tick = 5;
my $tick_us = 1000;
my %cdbshare :shared;

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
main();

#
# main thread
#
sub main(){
	my $fid = "MAIN";
	
	log_info($fid, "thread initializing");
	
	# check for socket
	if(!$socket_path){
		log_fatal($fid, "error: no socket defined!");
	}
	
	# spawn threads
	my $sockthr = threads->create( \&socket_thread );
	my $dbthr = threads->create( \&db_thread );
	
	# init main loop
	log_info($fid, "initializing thred monitors");

	do{
		thread_monitor($sockthr, \&socket_thread, "SOCKET");
		thread_monitor($dbthr, \&db_thread, "DB");
		sleep $tick;
	}while(1);
}

#
# socket listener
#
sub socket_thread(){
	my $fid = "SOCKET";
	log_info($fid, "thread initializing...");
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
			
			log_debug($fid, " session id [$s_id] packet [$data]");
			
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
	my $result;
	
	try{
		my $request = $packet->{'proto'}{'packet'};

		# process request
		if($packet->{'cdb'}{'req'} eq "ping"){
			$result = packet_build_encode("1", "pong", "[ping]");
		}
		else{
			$result = request_process($packet->{'cdb'}{'req'}, $packet);	
		}

		if(!$result){
			log_warn($fid, "failed to process command");
			$result = packet_build_encode("0", "error: failed to process command", $fid);
		}
	}	
	catch{
		log_error($fid, "fatal error during processing!");

		$result = packet_build_noencode("0", "error: fatal error during processing!", $fid);
		$result->{'request'}{'proto'} = $packet->{'proto'};
		$result->{'request'}{'cdb'} = $packet->{'cdb'};
		$result = json_encode($result);
	}
	
	return $result;
}

#
# process request [JSON-STR]
#		
sub request_process($req, $packet){
	my $fid = "REQ|PROCESS";
	my $result;
	
	my $tick_warn = 100;
	# 1000 usec * 200 = 0.2 seconds
	my $timeout = 200;
	
	# encode packet
	$cdbshare{$req . '_req'} = json_encode($packet);
	$cdbshare{$req} = 1;	
	
	my $timer = 0;
	do{		
		usleep($tick_us);
		$timer++;
		
		if($timer > $tick_warn){ 
			log_warn($fid, "req [$req]: waited > [$tick_warn] ticks [$timer]");
		};
		if($timer >= $timeout){
			$cdbshare{$req} = 0;
			log_error($fid, "req [$req]: timed out waiting for response");
			$result = packet_build_encode("0", "error: [$req] timed out waiting for response", $fid);
		};
	}while($cdbshare{$req});
	
	$result = $cdbshare{$req .'_ret'};
	$result = protocol_add_time($result, ($timer * $tick_us));	
	return $result;
}

#
# db thread
#
sub db_thread(){
	my $fid = "DB";
	log_info($fid, "thread initializing...");

	# init db
	cdb_init();

	# goto start
	START:

	try{
	
		while(1)
		{
			# get metadata
			if($cdbshare{'meta_get'}){
				log_debug($fid, "received [meta_get] request");
				$cdbshare{'meta_get_ret'} = cdb_meta_get();
				$cdbshare{'meta_get'} = 0;
			}
			
			# get db
			if($cdbshare{'db_get'}){
				log_debug($fid, "received [db_get] request");
				$cdbshare{'db_get_ret'} = cdb_get();
				$cdbshare{'db_get'} = 0;
			}

			# get db
			if($cdbshare{'db_flush'}){
				log_debug($fid, "received [db_flush] request");
				$cdbshare{'db_flush_ret'} = cdb_flush();
				$cdbshare{'db_flush'} = 0;
			}

			# get object
			if($cdbshare{'obj_get'}){
				log_debug($fid, "received [obj_get] request");
				$cdbshare{'obj_get_ret'} = cdb_obj_get(json_decode($cdbshare{'obj_get_req'}));
				$cdbshare{'obj_get'} = 0;
			}

			# get all objects
			if($cdbshare{'obj_get_all'}){
				log_debug($fid, "received [obj_get_all] request");
				$cdbshare{'obj_get_all_ret'} = cdb_obj_get_all(json_decode($cdbshare{'obj_get_all_req'}));
				$cdbshare{'obj_get_all'} = 0;
			}
					
			# set object
			if($cdbshare{'obj_set'}){
				log_debug($fid, "received [obj_set] request");
				$cdbshare{'obj_set_ret'} = cdb_obj_set(json_decode($cdbshare{'obj_set_req'}));
				$cdbshare{'obj_set'} = 0;
			}

			# delete object
			if($cdbshare{'obj_del'}){
				log_debug($fid, "received [obj_del] request");
				$cdbshare{'obj_del_ret'} = cdb_obj_del(json_decode($cdbshare{'obj_del_req'}));
				$cdbshare{'obj_del'} = 0;
			}

			# update env
			if($cdbshare{'env_update'}){
				log_debug($fid, "received [env_update] request");
				$cdbshare{'env_update_ret'} = cdb_env_update($cdbshare{'env_update_req'});
				$cdbshare{'env_update'} = 0;
			}

			# sleep
			usleep($tick_us);
		}
	}
	catch{
		log_error($fid, "fatal error during processing");
		goto START;
	}
}

#
#
#
sub cdb_env_update($req){
	my $fid = "[cdb_env_update]";
	my $env = json_decode($req);
	
	log_info_json($fid, "received ENV update request", $env);
	
	return env_update($env->{'cdb'});
}
