#
# ETHER|AAPEN|AGENT - LIB|PROTOCOL
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
# protocol handler [JSON-STR]
#
sub protocol($packet, $stream, $s_id){
	my $fid = "[protocol]";
	my $ffid = "PROTOCOL";
	my $err = "";
	my $result = 0;

	# Basic packet validation
	unless (ref $packet eq 'HASH' && exists $packet->{'proto'}) {
		log_error($ffid, "invalid packet structure");
		$stream->write("error: invalid packet structure\n");
		return 0;
	}

	my $request = $packet->{'proto'}{'packet'};

	my $req = "";
	if (exists $packet->{$request} && ref $packet->{$request} eq 'HASH') {
		$req = $packet->{$request}{'req'} // "";
	}

	log_info($ffid, "session [$s_id] service [$request] req [$req]");
	
	if(env_debug()){
		print "[" . date_get() . "] $fid request [" . $packet->{'proto'}{'packet'} . "]\n";
		json_encode_pretty($packet);
	};
	

	# agent ping
	if($request eq "ping"){ $result = packet_build_encode("1", "pong", "[agent]"); };

	# hypervisor
	if($request eq "hyper"){ $result = service_socket_send(env_serv_sock_get("hypervisor"), $packet); };
	if($request eq "hypervisor"){ $result = service_socket_send(env_serv_sock_get("hypervisor"), $packet); };

	# network
	if($request eq "net"){ $result = service_socket_send(env_serv_sock_get("network"), $packet); };
	if($request eq "network"){ $result = service_socket_send(env_serv_sock_get("network"), $packet); };

	# storage
	if($request eq "storage"){ $result = service_socket_send(env_serv_sock_get("storage"), $packet); };

	# frame
	if($request eq "frame"){ $result = service_socket_send(env_serv_sock_get("framework"), $packet); };
	if($request eq "framework"){ $result = service_socket_send(env_serv_sock_get("framework"), $packet); };
	
	# cluster
	if($request eq "cluster"){ $result = service_socket_send(env_serv_sock_get("cluster"), $packet); };

	# monitor
	if($request eq "monitor"){ $result = service_socket_send(env_serv_sock_get("monitor"), $packet); };

	# element
	if($request eq "element"){ $result = service_socket_send(env_serv_sock_get("element"), $packet); };

	# element
	if($request eq "cdb"){ $result = service_socket_send(env_serv_sock_get("cdb"), $packet); };

	# TODO: NEED TO ADD HMAC

	# check result
	if(!$result){
		log_warn($ffid, "failed to process command");
		$result = packet_build_encode("0", "error: failed to process command", $fid);

	}

	$stream->write( $result . "\n" );
	return $result;
}

#
# process packet data [STRING]
#
sub process_ssl($packet, $stream, $s_id){
	my $fid = "[process]";
	my $ffid = "PROCESS";
	my $err = "";
	my $result = 0;

	log_debug($ffid, "initializing session [$s_id]");

	try{
		# analyze input data 
		my ($analyze, $json) = analyze($packet);
		if($analyze){

			# check authentication header
			my ($auth) = authenticate($json);			
			if($auth){
				# authenticated, pass to protocol
				$result = protocol($json, $stream, $s_id);
			}
			else{
				# authentication failed, but data is valid..
				log_warn($ffid, "s_id [$s_id] error: packet valid, but unauthorized!");
				$result = "error: client unahuthrized!";
				$stream->close_now();
			}
		}
		else{
			# packet analyze failed, invalid or corrupt data
			log_warn($ffid, "s_id [$s_id] error: packet analyzing failed!");
			$result = "error: packet analyzing failed!";
			$stream->close_now();
		}
	}
	catch{
		# processing failed entirely, likely garbage
		log_error($ffid, "s_id [$s_id] error: packet preprocessing failed!");
		$result = "error: packet preprocessing failed!";
		$stream->close_now();
	}
	
	return $result;
}

#
# storage socket send [JSON-STR]
#
sub service_socket_send($socket, $packet){
	my $fid = "[service_socket_send]";
	my $ffid = "SOCKET|SEND";
	
	my $result = socket_encode_send($socket, $packet);
	my $json = socket_return_check($socket, $result);
	log_debug_json($ffid, "result", $result);
	
	return $json;
}

1;
