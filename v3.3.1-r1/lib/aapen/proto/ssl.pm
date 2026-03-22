#
# ETHER|AAPEN|LIBS - PROTO|SSL
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
use Exporter::Auto;
use JSON::MaybeXS;
use IO::Socket::UNIX qw( SOCK_STREAM );

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);

use IO::Async::Loop;
use IO::Async::SSL;
use IO::Async::SSLStream;
use IO::Socket::SSL;

#$IO::Socket::SSL::DEBUG = 1;


#
# send ssl packet
#
sub ssl_send_json($payload, $node){
	my $fid = "[ssl_send_json]";
	my $ffid = "SSL|SEND|JSON";
	
	# address and port
	my $addr = $node->{'agent'}{'address'};
	my $port = $node->{'agent'}{'port'} // config_base_agent_port();
	
	# SSL cert
	my $ca = config_base_ssl_ca_get();
	my $cert = config_base_ssl_cert_get();
	my $key = config_base_ssl_key_get();
	
	# validate config
	if(!defined $addr){
		log_warn($ffid, "error: address not defined!");
		return packet_build_encode("0", "error: address not defined!", $fid);
	}
	
	if(!defined $port){
		log_warn($ffid, "error: port not defined!");
		return packet_build_encode("0", "error: port not defined!", $fid);
	}

	if(!defined $ca || !defined $cert || !defined $key){
		log_warn($ffid, "SSL configuration missing or invalid!");
		return packet_build_encode("0", "error: SSL configuration missing or invalid", $fid);
	}
	
	log_info($ffid, "address [$addr] port [$port]");
	
	# encode packet and send
	my $packet = json_encode($payload);
	my $return = ssl_client($packet, $addr, $port, $cert, $key, $ca);
	return $return;
}

#
# ssl client
#
sub ssl_client($packet, $addr, $port, $cert, $key, $ca){
	my $fid = "[ssl_client]";
	my $ffid = "SSL|CLIENT";
	
	my $client;
	my $response;
	
	eval{
		local $SIG{ALRM} = sub { log_error($fid, "error [write_timeout]"); };
		alarm(10); # 10 second timeout
		
		$client = IO::Socket::SSL->new(
			PeerHost => $addr,
			PeerPort => $port,
			SSL_ca_file => $ca,
			SSL_key_file  => $key,
			SSL_cert_file => $cert,
			# certificate verification - VERIFY_PEER
			SSL_verify_mode => SSL_VERIFY_NONE,
		) or log_error($fid, "failed connect or SSL handshake [$!] error [$SSL_ERROR]");
		 
		# send data
		print $client $packet . "\n";

		# get response
		$response = <$client>;

		# graceful SSL shutdown
		$client->close(SSL_ctx_free => 1) or do {
			$client->stop_SSL();
			$client->close();
		};

		alarm(0);
	};
	
	if ($@) {
		$client->stop_SSL();
		$client->close();
		log_error($fid, "SSL command timed out!");
		$response = packet_build_encode("0", "error: SSL command timed out", $fid);
	}
	
	return $response;
}

#
# ssl client
#
sub ssl_client_ORIG($packet, $addr, $port, $cert, $key, $ca){
	my $fid = "[ssl_client]";
		
	my $client = IO::Socket::SSL->new(
		PeerHost => $addr,
		PeerPort => $port,
		SSL_ca_file => $ca,
		SSL_key_file  => $key,
		SSL_cert_file => $cert,
		# certificate verification - VERIFY_PEER
		SSL_verify_mode => SSL_VERIFY_NONE,
	) or print "$fid failed connect or ssl handshake: $!, $SSL_ERROR";
	 
	# send data
	print $client $packet . "\n";

	# SSL shutdown sequence
	my $response;
	eval {
		# Set read timeout
		local $SIG{ALRM} = sub { warn "$fid error [read_timeout]" };
		alarm(10); # 10 second read timeout
		$response = <$client>;
		alarm(0);
		
		# Graceful SSL shutdown
		$client->close(SSL_ctx_free => 1) or do {
			$client->stop_SSL();
			$client->close();
		};
	};
	if ($@) {
		# Handle timeout or errors
		$client->stop_SSL();
		$client->close();
		die "SSL operation failed: $@";
	}
	
	return $response;
}

1;
