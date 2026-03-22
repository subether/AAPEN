#
# ETHER|AAPEN|CLUSTER - LIB|PACKET
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
# process packets, assemble fragments [JSON-OBJ]
#
sub packet_process($msg, $msgbuf, $caller){
	my $fid = "[packet_process]";
	my $ffid = "PACKET|PROCESS";
	my $result;
	
	try{
		my $message = json_decode($msg);	
	
		# handle fragments
		if(defined($message->{'data'}) && $message->{'data'}{'fragged'}){
			
			if(defined $message->{'proto'}{'useq'}){
				# handle unique segment (useq) buffers
				if(defined($msgbuf->{$message->{'proto'}{'useq'}})){
					# packet useq already in buffer
					log_debug($ffid, "[FRAG] seq [$message->{'data'}{'frag'}{'seq_num'}]/[$message->{'data'}{'frag'}{'seq_tot'}]: [BUFFER ADD]");
					$msgbuf->{$message->{'proto'}{'useq'}}{$message->{'data'}{'frag'}{'seq_num'}} = $message->{'data'}{'frag'}{$message->{'data'}{'frag'}{'seq_num'}};
					$msgbuf->{$message->{'proto'}{'useq'}}{'seq_ctr'}++;
				}
				else{
					# packet useq not in buffer, create packet buffer
					log_debug($ffid, "[FRAG] seq [$message->{'data'}{'frag'}{'seq_num'}]/[$message->{'data'}{'frag'}{'seq_tot'}]: [BUFFER INIT]");
					$msgbuf->{$message->{'proto'}{'useq'}}{$message->{'data'}{'frag'}{'seq_num'}} = $message->{'data'}{'frag'}{$message->{'data'}{'frag'}{'seq_num'}};
					$msgbuf->{$message->{'proto'}{'useq'}}{'seq_ctr'} = 0;
					$msgbuf->{$message->{'proto'}{'useq'}}{'date'} = date_get();
					$msgbuf->{$message->{'proto'}{'useq'}}{'src'} = $message->{'cluster'}{'src'};
				}
				
				# last fragment received
				if($msgbuf->{$message->{'proto'}{'useq'}}{'seq_ctr'} eq $message->{'data'}{'frag'}{'seq_tot'}){
					log_debug($ffid, "[FRAG] seq [$message->{'data'}{'frag'}{'seq_num'}]/[$message->{'data'}{'frag'}{'seq_tot'}]: [BUFFER COMPLETE]");

					# assemble fragments
					my $payload = cluster_packet_frag_asm($message, $msgbuf);

					# clean multicast buffers
					if($caller eq "mc"){ mc_msgbuf_del_useq($message->{'proto'}{'useq'}) };
					
					# process payload
					$result = cluster_packet_protocol($payload);
					$msgbuf->{'stats'}{'frags'}++;
				}
			}
			else{
				log_warn($ffid, "useq missing from packet!");
			}
		}
		else{			
			# non fragged packet
			$result = cluster_packet_protocol($message);
			$msgbuf->{'stats'}{'nonfrags'}++;
		}
	}	
	catch{
		log_error($ffid, "fatal error during packet preprocessing!");
		$result = packet_build_encode("0", "error: fatal error during packet preprocessing!", $fid);
	}	

	return $msgbuf;
}

#
# packet protocol [JSON-OBJ]
#
sub cluster_packet_protocol($message){
	my $fid = "[cluster_packet_protocol]";
	my $ffid = "PACKET|PROTO";
	my $result;
	
	log_debug($ffid, "[RX] src [$message->{'cluster'}{'src'}{'name'}] id [$message->{'cluster'}{'src'}{'id'}] uid [$message->{'cluster'}{'src'}{'uid'}] useq [$message->{'proto'}{'useq'}] req [$message->{'cluster'}{'req'}]");

	# process request
	if(defined $message->{'cluster'}{'req'}){

		# cluster db full update
		if($message->{'cluster'}{'req'} eq "cdb_full"){
			log_info($ffid, "received [cdb_full] request");
			$result = packet_build_encode("1", "success: cdb received", $fid);
			#cluster_rx_sync_full($message);
		}

		# cluster db delta update
		if($message->{'cluster'}{'req'} eq "cdb_delta"){
			log_debug($ffid, "received [cdb_delta] request");
			$result = packet_build_encode("1", "success: cdb_delta received", $fid);
			cluster_rx_sync_delta($message);
		}
		
		if(!$result){
			log_warn($ffid, "unhandled request [$message->{'cluster'}{'req'}]");
			$result = packet_build_noencode("0", "error: unhandled request [$message->{'cluster'}{'req'}]", $fid);
		}
	}
	else{
		log_error($ffid, "no parseable request received");
		$result = packet_build_noencode("0", "error: no parseable request received", $fid);
	}

	return $result;
}

#
# return packet size in bytes [INT]
#
sub cluster_packet_size($packet){
	use bytes;
	return length( json_encode($packet) );
}

#
# check if packet needs fragmentation [BOOL]
#
sub cluster_packet_need_frag($packet, $max_fragment_size){
	if(cluster_packet_size($packet) > $max_fragment_size){ return 1; }
	else{ return 0; };	
}

#
# build ws packets [JSON-OBJ]
#
sub cluster_packet_build($req, $pub){
	my $fid = "[cluster_packet_build]";
		
	my $packet = packet_build_noencode("1", "cluster req [$req]", $fid);
	$packet->{'cluster'}{'req'} = $req;
	$packet->{'cluster'}{'pub'} = $pub;
	$packet->{'cluster'}{'src'}{'name'} = config_node_name_get();
	$packet->{'cluster'}{'src'}{'id'} = config_node_id_get();
	$packet->{'cluster'}{'src'}{'uid'} = get_cluster_uid();
	
	return $packet;
}

#
# create packet fragments [JSON-OBJ]
#
sub cluster_packet_frag_create($packet, $max_fragment_size){
	my $fid = "[cluster_packet_frag_create]";
	my $size = cluster_packet_size($packet);
	
	# preserve header and request
	my $fragged = {};
	$fragged->{'proto'} = $packet->{'proto'};
	$fragged->{'cluster'} = $packet->{'cluster'};
	
	# calculate fragments - split JSON at safe boundaries
	my $str = json_encode($packet->{'data'});
	my @parts;
	my $pos = 0;
	my $len = length($str);
	
	while ($pos < $len) {
		# try to split at a comma, closing brace, or closing bracket if possible
		my $chunk_size = $max_fragment_size;
		if ($pos + $chunk_size < $len) {
			# look for a safe split point near the end of the chunk
			my $search_pos = $pos + $chunk_size - 1;
			my $search_limit = $pos + $chunk_size - 100; # Look back up to 100 chars
			$search_limit = $pos if $search_limit < $pos;
			
			for (my $i = $search_pos; $i >= $search_limit; $i--) {
				my $char = substr($str, $i, 1);
				if ($char eq ',' || $char eq '}' || $char eq ']' || $char eq '"') {
					# check if this quote is not escaped
					if ($char eq '"') {
						my $backslash_count = 0;
						for (my $j = $i - 1; $j >= 0 && substr($str, $j, 1) eq '\\'; $j--) {
							$backslash_count++;
						}
						# if even number of backslashes, this quote is not escaped
						if ($backslash_count % 2 == 0) {
							$chunk_size = $i - $pos + 1;
							last;
						}
					} else {
						$chunk_size = $i - $pos + 1;
						last;
					}
				}
			}
		} else {
			$chunk_size = $len - $pos;
		}
		
		push @parts, substr($str, $pos, $chunk_size);
		$pos += $chunk_size;
	}
	
	my $ctr = 0;
	
	# compile fragments
	foreach my $part (@parts){
		$fragged->{'data'}{'frag'}{$ctr} = $part;
		$fragged->{'data'}{'frag'}{'frags'} = $ctr;
		$fragged->{'data'}{'frag'}{'fragged'} = 1;
		$ctr++;
	}

	log_debug($fid, "frags [$fragged->{'data'}{'frag'}{'frags'}] size [$size] chunks [".scalar(@parts)."]");	
	return $fragged;
}

#
# assemble fragmented packets [JSON-OBJ]
#
sub cluster_packet_frag_asm($message, $msgbuf){
	my $fid = "[cluster_packet_frag_asm]";
	my $data = "";
	
	# assemble headers
	my $payload->{'proto'} = $message->{'proto'};
	$payload->{'cluster'} = $message->{'cluster'};
	
	my @ctr = (0..$msgbuf->{$message->{'proto'}{'useq'}}{'seq_ctr'});
	my $num = 0;
	
	# compile fragments
	for my $f (@ctr){	
		$data = $data . $msgbuf->{$message->{'proto'}{'useq'}}{$f};
		$num++;
	}
	
	# decode and return payload
	$payload->{'data'} = json_decode($data);
	return $payload;
}

1;
