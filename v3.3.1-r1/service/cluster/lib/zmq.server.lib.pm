#
# ETHER|AAPEN|CLUSTER - LIB|ZMQ|SERVER
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
use Time::HiRes q(usleep);
use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REP);
use ZMQ::FFI qw(ZMQ_PUB ZMQ_SUB);

my $max_buffer_queue = 512;


#
# ZMQ receiver (RX)
#
sub zmq_server(){
	my $fid = "[zmq_server]";
	my $ffid = "ZMQ|SERVER";
	my $config = config_get();
	my $zmq_server = $config->{'node'}{'cluster'}{'zmq'}{'server'};
	my $zmq_port = $config->{'base'}{'ports'}{'zmq'}{'port'};
	
	log_info($ffid, "[INIT] Starting server on [$zmq_server] port [$zmq_port]");

	my $context = ZMQ::FFI->new();
	my $server = $context->socket(ZMQ_REP);
	$server->bind('tcp://' . $zmq_server . ':' . $zmq_port);

	while (1) {
		my $msg = $server->recv();		
		chomp($msg);
		
		zmq_server_packet_process($msg);
		
		# TODO: better response...
		$server->send("SUCCESS");
	}
}

#
# ZMQ publisher (TX)
#
sub zmq_publisher(){
	my $fid = "[zmq_publisher]";
	my $ffid = "ZMQ|PUB";
	
	my $config = config_get();
	my $zmq_server = $config->{'node'}{'cluster'}{'zmq'}{'server'};
	my $zmq_pubport = $config->{'base'}{'ports'}{'zmq'}{'pub'};
	my $server = 'tcp://' . $zmq_server . ':' . $zmq_pubport;
	my $i = 0;

	# init bufer
	zmq_server_delta_buffer_init();

	log_info($ffid, "[INIT] Starting publisher on [$zmq_server] port [$zmq_pubport]");

	my $ctx = ZMQ::FFI->new();
	my $pub = $ctx->socket(ZMQ_PUB);
	$pub->bind($server);

	while(1){
		zmq_server_sync_delta($pub);
		usleep 10000;
		$i++;
		
		if($i >= 6000){
			log_info($ffid, "[TX|FULL] publishing full cluster sync");
			my $cdb = cluster_db_full_generate();
			$pub->send(json_encode($cdb));
			$i = 0;
		}	
	}
}

#
# sync delta [NULL]
#
sub zmq_server_sync_delta($pub){
	my $fid = "[zmq_server_sync_delta]";
	my $ffid = "ZMQ|SERVER|SYNC|DELTA";
	
	my $packet = zmq_server_delta_buffer_get();
	
	if($packet->{'data'}{'index'} ne ""){
		log_debug($ffid, "syncing deltas [$packet->{'data'}{'index'}]");
		$pub->send(json_encode($packet));
	}
	else{
		log_debug($ffid, "packet buffer [$packet->{'data'}{'index'}] is empty");
	}
}

#
# server packet process [NULL]
#
sub zmq_server_packet_process($msg){
	my $fid = "[zmq_server_packet_proc]";
	my $ffid = "ZMQ|SRV|PROCESS";

	try{	
		my $message = json_decode($msg);
		log_debug($ffid, "[RX] useq [$message->{'proto'}{'useq'}] src [$message->{'cluster'}{'src'}{'name'}] uid [$message->{'cluster'}{'src'}{'uid'}] pub [$message->{'cluster'}{'pub'}] req [$message->{'cluster'}{'req'}]");

		# check for broadcast packet
		if($message->{'cluster'}{'pub'} eq "bcast"){
			log_debug($ffid, "[RX] [BCAST] src [$message->{'cluster'}{'src'}{'name'}] id [$message->{'cluster'}{'src'}{'id'}] req [$message->{'cluster'}{'req'}]");
			cluster_packet_protocol($message);
		}
		if($message->{'cluster'}{'pub'} eq "ucast"){
			log_debug($ffid, "[RX] [UNICAST] src [$message->{'cluster'}{'src'}{'name'}] id [$message->{'cluster'}{'src'}{'id'}] req [$message->{'cluster'}{'req'}]: UNHANDLED!");
		}
	}	
	catch{
		log_error($fid, "fatal error during packet preprocessing!");
	}
}

#
# set delta buffer [NULL]
#
sub zmq_server_delta_buffer_set($message){
	my $fid = "[zmq_server_delta_buffer_set]";
	my $ffid = "ZMQ|SERVER|DELTA|SET";
	
	my %zmqbuf = zmq_server_buf_get();
	my $buffer_id = index_free($zmqbuf{'index'}, 0);
	$zmqbuf{'index'} = index_add($zmqbuf{'index'}, $buffer_id);
	$zmqbuf{$buffer_id} = json_encode($message);
	
	if($buffer_id > $max_buffer_queue){
		# should really do FIFO style instead. todo.
		log_warn($fid, "buffer size exceeded. flushing buffers");
		%zmqbuf = ();
		$zmqbuf{'index'} = "";
	}
	
	zmq_server_buf_set(%zmqbuf);
}

#
# get zmq delta buffer [JSON-OBJ]
#
sub zmq_server_delta_buffer_get(){
	my $fid = "[zmq_server_delta_buffer_get]";
	my $ffid = "ZMQ|SERVER|DELTA|GET";
	
	my %zmqbuf = zmq_server_buf_get();
	my @index = index_split($zmqbuf{'index'});
	my $packet = cluster_packet_build('cdb_delta', 'bcast');
	$packet->{'data'}{'index'} = $zmqbuf{'index'};
	
	foreach my $bufid (@index){
		$packet->{'data'}{$bufid} = json_decode($zmqbuf{$bufid});
		delete $zmqbuf{$bufid};
	}
	
	%zmqbuf = ();
	$zmqbuf{'index'} = "";
	zmq_server_buf_set(%zmqbuf);
	
	return $packet;
}

#
# init zmq delta buffer [NULL]
#
sub zmq_server_delta_buffer_init(){
	my $fid = "[zmq_server_delta_buffer_init]";
	my %zmqbuf = zmq_server_buf_get();	
	$zmqbuf{'index'} = "";
	zmq_server_buf_set(%zmqbuf);
}

1;
