#
# ETHER|AAPEN|CLUSTER - LIB|ZMQ|SYNC
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
# ZMQ publisher (TX)
#
sub zmq_sync_publisher(){
	my $fid = "[zmq_sync_publisher]";
	my $ffid = "ZMQ|SYNC|PUB";
	
	my $config = config_get();
	my $zmq_sync_pub = $config->{'node'}{'cluster'}{'zmq'}{'server'};
	my $zmq_sync_port = $config->{'base'}{'ports'}{'zmq'}{'sync'};
	my $server = 'tcp://' . $zmq_sync_pub . ':' . $zmq_sync_port;
	my $i = 0;

	# init sync buffer
	zmq_sync_delta_buffer_init();

	log_info($ffid, "[INIT] Starting SYNC publisher on [$zmq_sync_pub] port [$zmq_sync_port]");
	my $ctx = ZMQ::FFI->new();
	my $pub = $ctx->socket(ZMQ_PUB);
	$pub->bind($server);

	while(1){
		zmq_sync_delta($pub);		
		sleep 2;
		$i++;
		
		# should still push full sync at some intervals
		if($i >= 360){
			log_info($ffid, "$ffid [SYNC|FULL] publishing full cluster sync");
			my $cdb = cluster_db_full_generate();
			$pub->send(json_encode($cdb));
			$i = 0;
		}
	}
}

#
# sync delta [NULL]
#
sub zmq_sync_delta($pub){
	my $fid = "[zmq_sync_delta]";
	my $ffid = "ZMQ|SYNC|DELTA";
	
	my $packet = zmq_sync_delta_buffer_get();
	
	if($packet->{'data'}{'index'} ne ""){
		log_debug($fid, "[ZMQ|SYNC|PUB] [SYNC|DELTA] syncing deltas [$packet->{'data'}{'index'}]");
		$pub->send(json_encode($packet));
	}
	else{
		log_debug($fid, "packet buffer [$packet->{'data'}{'index'}] is empty");
	}
}

#
# ZMQ subscriber (broadcast rx)
#
sub zmq_sync_subscriber(){
	my $fid = "[zmq_sync_subscriber]";
	my $ffid = "ZMQ|SYNC|SUB";
	
	my $config = config_get();
	my $zmq_sync_sub = $config->{'node'}{'cluster'}{'zmq'}{'sync'};
	my $zmq_sync_port = $config->{'base'}{'ports'}{'zmq'}{'sync'};
	my $pub = 'tcp://' . $zmq_sync_sub . ':' . $zmq_sync_port;
	
	log_info($ffid, "[INIT] connecting to SYNC publisher [$pub]");

	my $ctx = ZMQ::FFI->new();
	my $sub = $ctx->socket(ZMQ_SUB);

	$sub->connect($pub);
	$sub->subscribe('');

	while(1){
		usleep 1000;
		my $recv = $sub->recv();
		zmq_sync_packet_process($recv);
	}
}

#
# client packet process [NULL]
#
sub zmq_sync_packet_process($msg){
	my $fid = "[zmq_sync_packet_process]";
	my $ffid = "ZMQ|SYNC|PROCESS";

	try{	
		my $message = json_decode($msg);

		# only process sync broadcasts
		if($message->{'cluster'}{'pub'} eq "bcast" && $message->{'cluster'}{'req'} eq "cdb_sync"){
			
			# unwrap delta index
			my @delta_index = index_split($message->{'data'}{'index'});
			
			# iterate deltas
			foreach my $delta (@delta_index){
	
				# check for local or remote sync origin
				if(defined $message->{'data'}{$delta}{'cluster'}{'src'}){
					# delta received from a different node (remote to sync origin)
					
					log_info($ffid, "delta [$delta] [RELAY] src [$message->{'data'}{$delta}{'cluster'}{'src'}{'name'}] id [$message->{'data'}{$delta}{'cluster'}{'src'}{'id'}] req [$message->{'data'}{$delta}{'cluster'}{'req'}] pub [$message->{'data'}{$delta}{'cluster'}{'pub'}]");
					
					# unwrap inner deltas
					my @inner_delta_index = index_split($message->{'data'}{$delta}{'data'}{'index'});
					
					foreach my $inner_delta (@inner_delta_index){

						# object set
						if($message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'req'} eq "obj_set"){
							log_info($ffid, "[OBJ_SET] delta [$delta] src [$message->{'data'}{$delta}{'cluster'}{'src'}{'name'}] inner delta [$inner_delta] src [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'key'}] id [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'id'}] obj [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'obj'}] req [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'req'}] ver [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'meta'}{'ver'}]");							
							cluster_obj_set($message->{'data'}{$delta}{'data'}{$inner_delta}, 0, "remote");
						}
						
						# object meta set
						if($message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'req'} eq "obj_meta_set"){
							log_info($ffid, "[OBJ_META_SET] delta [$delta] src [$message->{'data'}{$delta}{'cluster'}{'src'}{'name'}] inner delta [$inner_delta] src [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'key'}] id [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'id'}] obj [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'obj'}] req [$message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'req'}]");
							cluster_obj_meta_set($message->{'data'}{$delta}{'data'}{$inner_delta}, 0, "remote");
						}
						
						# object meta set
						if($message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'}{'req'} eq "obj_del"){
							log_info($ffid, "OBJECT DELETE RECEIVED!");
							json_encode_pretty($message->{'data'}{$delta}{'data'}{$inner_delta}{'cluster'});
							cluster_obj_meta_set($message->{'data'}{$delta}{'data'}{$inner_delta}, 0, "remote");
						}
					}
				}
				else{
					# origin is remote sync node
					
					# object set
					if($message->{'data'}{$delta}{'cluster'}{'req'} eq "obj_set"){
						log_debug($ffid, "[OBJ_SET] [LOCAL] src [$message->{'data'}{$delta}{'cluster'}{'key'}] id [$message->{'data'}{$delta}{'cluster'}{'id'}] obj [$message->{'data'}{$delta}{'cluster'}{'obj'}] req [$message->{'data'}{$delta}{'cluster'}{'req'}]");
						cluster_obj_set($message->{'data'}{$delta}, 0, "remote");
					}
					
					# object meta set
					if($message->{'data'}{$delta}{'cluster'}{'req'} eq "obj_meta_set"){
						log_debug($ffid, "[OBJ_META_SET] [LOCAL] src [$message->{'data'}{$delta}{'cluster'}{'key'}] id [$message->{'data'}{$delta}{'cluster'}{'id'}] obj [$message->{'data'}{$delta}{'cluster'}{'obj'}] req [$message->{'data'}{$delta}{'cluster'}{'req'}]");
						cluster_obj_meta_set($message->{'data'}{$delta}, 0, "remote");
					}
					
					# object del
					if($message->{'data'}{$delta}{'cluster'}{'req'} eq "obj_del"){
						# TODO: must delete from CDB
						log_debug($ffid, "[OBJ_SET] [LOCAL] src [$message->{'data'}{$delta}{'cluster'}{'key'}] id [$message->{'data'}{$delta}{'cluster'}{'id'}] obj [$message->{'data'}{$delta}{'cluster'}{'obj'}] req [$message->{'data'}{$delta}{'cluster'}{'req'}]");
						json_encode_pretty($message->{'data'}{$delta}{'cluster'});
					}		
				}
			}	
		}
		
		if($message->{'cluster'}{'pub'} eq "bcast" && $message->{'cluster'}{'req'} eq "cdb_full"){
			log_debug($ffid, "received CDB full sync request!");
			#cdb_rx_sync_full($message);
		}

	}	
	catch{
		log_error($fid, "fatal error during packet preprocessing");
	}
}

#
# set delta buffer [NULL]
#
sub zmq_sync_delta_buffer_set($message){
	my $fid = "[zmq_sync_delta_buffer_set]";
	my $ffid = "ZMQ|SYNC|DELTA|SET";
	
	my %zmqbuf = zmq_sync_buf_get();
	my $buffer_id = index_free($zmqbuf{'index'}, 0);
	$zmqbuf{'index'} = index_add($zmqbuf{'index'}, $buffer_id);
	$zmqbuf{$buffer_id} = json_encode($message);
	
	if($buffer_id > $max_buffer_queue){
		# should really do LILO style instead. todo.
		log_warn($fid, "buffer size exceeded. flushing buffers");
		%zmqbuf = ();
		$zmqbuf{'index'} = "";
	}
	
	zmq_sync_buf_set(%zmqbuf);
}

#
# get zmq delta buffer [JSON-OBJ]
#
sub zmq_sync_delta_buffer_get(){
	my $fid = "[zmq_sync_delta_buffer_get]";
	my $ffid = "ZMQ|SYNC|DELTA|GET";
	
	my %zmqbuf = zmq_sync_buf_get();
	my @index = index_split($zmqbuf{'index'});
	my $packet = cluster_packet_build('cdb_sync', 'bcast');
	$packet->{'data'}{'index'} = $zmqbuf{'index'};
	
	foreach my $bufid (@index){
		$packet->{'data'}{$bufid} = json_decode($zmqbuf{$bufid});
		delete $zmqbuf{$bufid};
	}

	%zmqbuf = ();
	$zmqbuf{'index'} = "";
	zmq_sync_buf_set(%zmqbuf);
	
	return $packet;
}

#
# init zmq delta buffer [NULL]
#
sub zmq_sync_delta_buffer_init(){
	my $fid = "[zmq_sync_delta_buffer_init]";
	my %zmqbuf = zmq_sync_buf_get();
	$zmqbuf{'index'} = "";
	zmq_sync_buf_set(%zmqbuf);
}

1;
