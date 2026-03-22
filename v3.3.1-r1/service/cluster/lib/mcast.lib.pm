#
# ETHER|AAPEN|CLUSTER - LIB|MULTICAST
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
use IO::Socket::Multicast;
use Time::HiRes qw( clock );

my $max_fragment_size = 400;
my $max_buffer_queue = 128;
my $packet_timeout = 10;
my $tx_interval = 5000;
my $fragment_delay = 1000;
my $msgbuf = {};

#
# Multicast receive [NULL]
#
sub mc_rx(){
	my $fid = "[mc_rx]";
	my $ffid = "MC|RX";
	
	my $data;
	my $counter = 0;
	my $updated = date_get();
	my $result;
	
	my $config = config_get();
	my $mc_group = $config->{'base'}{'ports'}{'multicast'}{'group'};
	my $mc_port = $config->{'base'}{'ports'}{'multicast'}{'port'};
	
	# stats
	$msgbuf->{'stats'}{'nonfrags'} = 0;
	$msgbuf->{'stats'}{'frags'} = 0;
	$msgbuf->{'stats'}{'invalid'} = 0;
	
	log_info($ffid, "Multicast RX thread init: group [$mc_group] port [$mc_port]");
	
	my $sock = IO::Socket::Multicast->new(Proto=>'udp',LocalPort=>$mc_port);
	$sock->mcast_add($mc_group) || die "[" . date_get() . "] $fid error: Couldn't set group: $!\n";
	$sock->mcast_loopback(0);

	do{
		next unless $sock->recv($data, 1024);
		chomp($data);

		$msgbuf = packet_process($data, $msgbuf, "mc");
		
		# refresh mc membership (events..)
		if(date_str_diff_now($updated) > 120){
			log_debug($ffid, "updating MC membership [$mc_group]");
			$sock->mcast_drop($mc_group) || warn "[" . date_get() . "] $fid error: Couldn't drop group: $!\n";
			$sock->mcast_add($mc_group) || warn "[" . date_get() . "] $fid error: Couldn't set group: $!\n";
			$updated = date_get();
			$msgbuf = mc_msgbuf_clean($msgbuf);
		}

	}while(1);
}

#
# Multicast transmit [NULL]
#
sub mc_tx(){
	my $fid = "[mc_tx]";
	my $ffid = "MC|TX";
	
	mc_delta_buffer_init();
	my $counter = 0;
	
	my $config = config_get();
	my $mc_group = $config->{'base'}{'ports'}{'multicast'}{'group'};
	my $mc_port = $config->{'base'}{'ports'}{'multicast'}{'port'};
	
	log_info($ffid, "Multicast TX thread init: group [$mc_group] port [$mc_port]");
	
	my $mc_dest = $mc_group . ":" . $mc_port;
	my $sock = IO::Socket::Multicast->new(Proto=>'udp',PeerAddr=>$mc_dest);
	$sock->mcast_loopback(0);
	
	do{
		mc_sync_delta($sock);
		usleep($tx_interval);	
	}while(1);
}

#
# sync delta [NULL]
# 
sub mc_sync_delta($sock){
	my $fid = "[mc_sync_delta]";
	my $packet = mc_delta_buffer_get();
	
	if($packet->{'data'}{'index'} ne ""){
		log_debug($fid, "packet buffer [$packet->{'data'}{'index'}]");
		mc_client_send($sock, $packet);
	}
	else{
		log_debug($fid, "packet buffer [$packet->{'data'}{'index'}] is empty");
	}
}

#
# send packets [NULL]
#
sub mc_client_send($sock, $packet){
	my $fid = "[mc_client_send]";
	my $ffid = "MC|CLIENT|SEND";

	if(cluster_packet_need_frag($packet, $max_fragment_size)){
		log_debug($ffid, "[TX] useq [$packet->{'proto'}{'useq'}] req [$packet->{'cluster'}{'req'}] flags: [$packet->{'cluster'}{'pub'}]: [FRAG]");
		mc_client_send_frag($sock, $packet)
	}
	else{
		log_debug($ffid, "[TX] useq [$packet->{'proto'}{'useq'}] req [$packet->{'cluster'}{'req'}] flags: [$packet->{'cluster'}{'pub'}]: [NOT FRAG]");
		$sock->send(json_encode($packet)) || warn "Couldn't send: $!";
	}
}

#
# send fragmented packets [NULL]
#
sub mc_client_send_frag($sock, $packet){
	my $fid = "[mc_client_send_frag]";
	
	$packet = cluster_packet_frag_create($packet, $max_fragment_size);
	my @fragctr = (0..$packet->{'data'}{'frag'}{'frags'});
	log_debug($fid, "[TX] useq [$packet->{'proto'}{'useq'}] sending [" . cluster_packet_size($packet) . "] bytes over [$packet->{'data'}{'frag'}{'frags'}] fragments");

	for my $f (@fragctr){
		my $fragment->{'proto'} = $packet->{'proto'};
		$fragment->{'cluster'} = $packet->{'cluster'};
		$fragment->{'data'}{'frag'}{$f} = $packet->{'data'}{'frag'}{$f};
		$fragment->{'data'}{'frag'}{'seq_num'} = $f;
		$fragment->{'data'}{'frag'}{'seq_tot'} = $packet->{'data'}{'frag'}{'frags'};
		$fragment->{'data'}{'fragged'} = 1;
		
		log_debug($fid, "[TX] useq [$packet->{'proto'}{'useq'}] fragment [$f] size [" . cluster_packet_size($fragment) . "]");
		$sock->send(json_encode($fragment)) || warn "Couldn't send: $!";
		usleep($fragment_delay);
	}
	if(env_debug()){ print "\n"; };
}

#
# set delta buffer [NULL]
#
sub mc_delta_buffer_set($message){
	my $fid = "[mc_delta_buffer_set]";
	my $ffid = "MC|BUF|SET";
	
	my %mcbuf = mcbuf_get();
	my $buffer_id = index_free($mcbuf{'index'}, 0);
	$mcbuf{'index'} = index_add($mcbuf{'index'}, $buffer_id);
	$mcbuf{$buffer_id} = json_encode($message);
	
	log_debug($ffid, "buffers used [$buffer_id] of [$max_buffer_queue]");
	
	if($buffer_id > $max_buffer_queue){
		# better buffer overflow handling.. TODO..
		log_warn($ffid, "buffer size exceeded! flushing buffers");
		%mcbuf = ();
		$mcbuf{'index'} = "";
	}
	
	mcbuf_set(%mcbuf);
}

#
# get delta buffer [JSON-OBJ]
#
sub mc_delta_buffer_get(){
	my $fid = "[mc_delta_buffer_get]";
	my $ffid = "MC|BUF|GET";
	
	my %mcbuf = mcbuf_get();
	my @index = index_split($mcbuf{'index'});
	my $packet = cluster_packet_build('cdb_delta', 'bcast');
	$packet->{'data'}{'index'} = $mcbuf{'index'};
	
	foreach my $bufid (@index){
		$packet->{'data'}{$bufid} = json_decode($mcbuf{$bufid});
		delete $mcbuf{$bufid};
	}

	%mcbuf = ();
	$mcbuf{'index'} = "";
	mcbuf_set(%mcbuf);
	
	return $packet;
}

#
# init delta buffer [NULL]
#
sub mc_delta_buffer_init(){
	my $fid = "[mc_delta_buffer_init]";
	my %mcbuf = mcbuf_get();	
	$mcbuf{'index'} = "";
	mcbuf_set(%mcbuf);
}

#
# remove useq from message buffer [NULL]
#
sub mc_msgbuf_del_useq($useq){
	delete $msgbuf->{$useq};
}

#
# clean message buffers [NULL]
#
sub mc_msgbuf_clean($msgbuf){
	my $fid = "[mc_msgbuf_clean]";
	my $ffid = "MC|BUF|CLEAN";
	
	foreach my $useq (keys %$msgbuf){
		
		# ignore stats
		if($useq ne "stats"){
		
			# check if date is defined
			if(defined $msgbuf->{$useq}{'date'}){
				
				# remove useq if more than timeout sec old
				my $delta = date_str_diff_now($msgbuf->{$useq}{'date'});
				if($delta > $packet_timeout){
					log_warn($ffid, "useq [$useq] src [$msgbuf->{$useq}{'src'}{'name'}] date [$msgbuf->{$useq}{'date'}] age [$delta]: cleaning");
					delete $msgbuf->{$useq};
					$msgbuf->{'stats'}{'invalid'}++;
				}
			}
			else{
				log_warn($ffid, "buffer useq [$useq] missing datestamp: cleaning");
				delete $msgbuf->{$useq};
				$msgbuf->{'stats'}{'invalid'}++;
			}
		}
		
	}
	
	# Calculate error rate with divide-by-zero protection
	my $total_packets = $msgbuf->{"stats"}{'frags'} + $msgbuf->{"stats"}{'nonfrags'};
	my $perc = 0;
	if ($total_packets > 0) {
		$perc = ($msgbuf->{"stats"}{'invalid'} / $total_packets * 100);
	}
	
	log_info($ffid, "packets [$total_packets] invalid [" . $msgbuf->{"stats"}{'invalid'} . "] error rate [" . sprintf("%.4f", $perc) . "%] buffers used [" . (keys %$msgbuf) . "] of [$max_buffer_queue]");
	
	return $msgbuf;
}

1;
