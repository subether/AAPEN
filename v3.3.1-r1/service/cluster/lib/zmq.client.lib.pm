#
# ETHER|AAPEN|CLUSTER - LIB|ZMQ|CLIENT
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

use EV;
use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ);
use ZMQ::FFI qw(ZMQ_PUB ZMQ_SUB);

my $max_buffer_queue = 512;

#
# ZMQ transmitter (client)
#
sub zmq_client(){
	my $fid = "[zmq_client]";
	my $ffid = "ZMQ|CLIENT";

	my $config = config_get();
	my $zmq_server = $config->{'node'}{'cluster'}{'zmq'}{'server'};
	my $zmq_port = $config->{'base'}{'ports'}{'zmq'}{'port'};
	
	# init client buffer
	zmq_client_delta_buffer_init();
	
	my $counter = 0;
	my $REQUEST_TIMEOUT = 250000; # msecs
	my $REQUEST_RETRIES = 3; # Before we abandon
	my $sleep_us = 1000000;
	my $server = 'tcp://' . $zmq_server . ':' . $zmq_port;
	my $ctx = ZMQ::FFI->new();

	log_info($ffid, "[INIT] conneting to server [$server]");

	my $client = $ctx->socket(ZMQ_REQ);
	$client->connect($server);

	my $retries_left = $REQUEST_RETRIES;

	# request loop
	while ($retries_left) {
		
		my $delta = zmq_client_delta_buffer_get();
		
		if($delta->{'data'}{'index'} ne ""){
			log_info($ffid, "[TX] publishing deltas. index [$delta->{'data'}{'index'}]");
			
			$client->send(json_encode($delta));
			
			my $expect_reply = 1;

			# retry loop
			while ($expect_reply) {
				# Poll socket for a reply, with timeout
				EV::once $client->get_fd, EV::READ, $REQUEST_TIMEOUT / 1000, sub {
					my ($revents) = @_;

					# Here we process a server reply and exit our loop if the
					# reply is valid. If we didn't get a reply we close the client
					# socket and resend the request. We try a number of times
					# before finally abandoning:

					if ($revents == EV::READ) {
						while ($client->has_pollin) {
							# We got a reply from the server, must match sequence
							my $reply = $client->recv();

							if ($reply eq "OKI") {
								$retries_left = $REQUEST_RETRIES;
								$expect_reply = 0;
							}
							else {
								log_warn($ffid, "error: malformed response from server");
							}
						}
					}
					elsif (--$retries_left == 0) {
						log_warn($ffid, "error: server is offline [$server]");
						#sleep 5;
					}
					else {
						log_warn($ffid, "warning: no response from server [$server]");
						
						# Old socket is confused; close it and open a new one
						$client->close;

						log_warn($ffid, "reconnecting to server [$server]");
						$client = $ctx->socket(ZMQ_REQ);
						$client->connect($server);
						
						# Send request again, on new socket
						$client->send(json_encode($delta));
					}
				};

				#last RETRY_LOOP if $retries_left == 0;
				EV::run;
			}
		}

		usleep $sleep_us;
		$counter++;
	}
}

#
# ZMQ subscriber (broadcast rx)
#
sub zmq_subscriber(){
	my $fid = "[zmq_subscriber]";
	my $ffid = "ZMQ|SUB";
	
	my $config = config_get();
	my $zmq_server = $config->{'node'}{'cluster'}{'zmq'}{'server'};
	my $zmq_pubport = $config->{'base'}{'ports'}{'zmq'}{'pub'};
	my $pub = 'tcp://' . $zmq_server . ':' . $zmq_pubport;
	
	log_info($ffid, "[INIT] connecting to publisher [$pub]");

	my $ctx = ZMQ::FFI->new();
	my $sub = $ctx->socket(ZMQ_SUB);

	$sub->connect($pub);
	$sub->subscribe('');

	while(1){	
		usleep 1000;
		my $recv = $sub->recv();
		zmq_client_packet_process($recv);
	}
}

#
# client packet process [NULL]
#
sub zmq_client_packet_process($msg){
	my $fid = "[zmq_client_packet_process]";
	my $ffid = "ZMQ|CLIENT|PROCESS";

	try{
		my $message = json_decode($msg);
		
		# check for broadcast packet
		if($message->{'cluster'}{'pub'} eq "bcast"){
			log_debug($ffid, "[BCAST] src [$message->{'cluster'}{'src'}{'name'}] id [$message->{'cluster'}{'src'}{'id'}] req [$message->{'cluster'}{'req'}]");
			cluster_packet_protocol($message);
			
		}

		# check for unicast packets
		if($message->{'cluster'}{'pub'} eq "ucast"){
			log_info($ffid, "[UCAST] src [$message->{'cluster'}{'src'}{'name'}] id [$message->{'cluster'}{'src'}{'id'}] req [$message->{'cluster'}{'req'}]");
			# TODO: unicast handler
		}	
	}	
	catch{
		log_error($ffid, "fatal error during packet preprocessing!");
	}
}

#
# set delta buffer [NULL]
#
sub zmq_client_delta_buffer_set($message){
	my $fid = "[zmq_client_delta_buffer_set]";
	my $ffid = "ZMQ|CLIENT|DELTA|SET";
	
	my %zmqbuf = zmq_client_buf_get();
	my $buffer_id = index_free($zmqbuf{'index'}, 0);
	$zmqbuf{'index'} = index_add($zmqbuf{'index'}, $buffer_id);
	$zmqbuf{$buffer_id} = json_encode($message);
	
	if($buffer_id > $max_buffer_queue){
		log_warn($ffid, "buffer size exceeded. flushing buffers.");
		%zmqbuf = ();
		$zmqbuf{'index'} = "";
	}
	
	zmq_client_buf_set(%zmqbuf);
}

#
# get zmq delta buffer [JSON-OBJ]
#
sub zmq_client_delta_buffer_get(){
	my $fid = "[zmq_client_delta_buffer_get]";
	my $ffid = "ZMQ|CLIENT|DELTA|GET";
	
	my %zmqbuf = zmq_client_buf_get();
	my @index = index_split($zmqbuf{'index'});
	my $packet = cluster_packet_build('cdb_delta', 'bcast');
	$packet->{'data'}{'index'} = $zmqbuf{'index'};
	
	foreach my $bufid (@index){
		$packet->{'data'}{$bufid} = json_decode($zmqbuf{$bufid});
		delete $zmqbuf{$bufid};
	}
	
	%zmqbuf = ();
	$zmqbuf{'index'} = "";
	zmq_client_buf_set(%zmqbuf);
	
	return $packet;
}

#
# init zmq delta buffer [NULL]
#
sub zmq_client_delta_buffer_init(){
	my $fid = "[zmq_client_delta_buffer_init]";
	my %zmqbuf = zmq_client_buf_get();	
	$zmqbuf{'index'} = "";
	zmq_client_buf_set(%zmqbuf);
}

1;
