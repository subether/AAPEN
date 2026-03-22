#
# ETHER|AAPEN|LIBS - PROTO|SOCKET
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
use IO::Socket::UNIX qw( SOCK_STREAM );

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);

my $socket_timeout = 60;



#
# send without encoding [JSON-STR]
#
sub socket_send($socket_path, $data){
	my $fid = "[socket_send]";
	log_debug($fid, "socket path [$socket_path]");
	
	# build socket
	my $socket = IO::Socket::UNIX->new(
	   Type => SOCK_STREAM,
	   Peer => $socket_path,
	)
	or do {
		my $error = "error: socket [$socket_path] error [$!]";
		log_warn($fid, $error);
		return packet_build_encode("0", $error, $fid);
	};
	
	my $response;
	
	eval{
		log_debug_json($fid, "sending request. socket [$socket_path]", $data);
		
		# set timeout
		my $timeout = $socket_timeout;
		
		# check if socket is writable
		my $win = '';
		vec($win, fileno($socket), 1) = 1;
		my $nfound = select(undef, my $wout = $win, undef, $timeout);
		
		if ($nfound == 0) {
			die "socket write timeout after ${socket_timeout}s";
		} elsif ($nfound < 0) {
			die "select write error: $!";
		}
		
		# Socket is writable, send data
		print $socket "$data\n";
		
		# Wait for response with timeout
		my $rin = '';
		vec($rin, fileno($socket), 1) = 1;
		$nfound = select(my $rout = $rin, undef, undef, $timeout);
		
		if ($nfound == 0) {
			die "socket read timeout after ${socket_timeout}s";
		} elsif ($nfound < 0) {
			die "select read error: $!";
		}
		
		# Data is available, read it
		chomp( $response = <$socket> );
	};
	
	# Always close the socket
	close($socket) if $socket;
	
	if ($@) {
		# Handle timeout or errors
		my $error = $@;
		if ($error =~ /socket timeout/) {
			log_warn($fid, "socket [$socket_path] operation timeout after [${socket_timeout}] sec");
			$response = packet_build_encode("0", "error: socket [$socket_path] operation timeout after [${socket_timeout} sec]", $fid);
		} else {
			log_warn($fid, "socket [$socket_path] operation error [$error]");
			$response = packet_build_encode("0", "error: socket [$socket_path] operation error [$error]", $fid);
		}
	}
	
	return $response;
}

#
# encode and send packet [JSON-STR]
#
sub socket_encode_send($socket_path, $packet){
	my $fid = "[socket_encode_send]";
	my $data = json_encode($packet);
	return socket_send($socket_path, $data);
}

#
# check return codes [JSON-OBJ]
#
sub socket_return_check($socket, $response){
	my $fid = "[socket_return_check]";
	my $result;

	if(!$response){
		log_warn($fid, "error: socket [$socket] returned NULL");
		$result = packet_build_encode("0", "error: socket [$socket] returned NULL", $fid);
	}
	elsif($response eq "error: Permission denied"){
		log_warn($fid, "error: socket [$socket] returned [$response]");
		$result = packet_build_encode("0", "error: socket [$socket] returned [$response]", $fid);
	}
	elsif($response eq "error: No such file or directory"){
		log_warn($fid, "error: socket [$socket] returned [$response]");
		$result = packet_build_encode("0", "error: socket [$socket] returned [$response]", $fid);		
	}
	elsif($response eq "error: Connection refused"){
		log_warn($fid, "error: socket [$socket] returned [$response]");
		$result = packet_build_encode("0", "error: socket [$socket] returned [$response]", $fid);
	}
	else{
		$result = $response;
	}
	return $result;
}

#
# set socket permissions [NULL]
#
sub socket_set_perm($socket_path){
	my $fid = "[socket_set_perm]";
	my $base_config = config_base_get();
	my $socket_user = $base_config->{'base'}{'perms'}{'socket'}{'user'};
	my $socket_group = $base_config->{'base'}{'perms'}{'socket'}{'group'}; 
	
	if((defined $socket_path && $socket_path ne "") || (defined $socket_user && $socket_user ne "") || (defined $socket_group && $socket_group ne "")){
		# TODO: run string check for escape sequences here!
		my $perm = "/usr/bin/chown " . $socket_user . ":" .  $socket_group . " " . $socket_path;
		log_debug($fid, "exec [$perm]");
		execute($perm);
	}
	else{
		log_warn($fid, "error: no socket defined!");
	}
}

1;
