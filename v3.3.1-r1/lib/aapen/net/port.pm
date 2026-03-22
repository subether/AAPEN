#
# ETHER|AAPEN|LIBS - NETWORK|PORT
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
use Term::ANSIColor qw(:constants);
use JSON::MaybeXS;
use IO::Socket::PortState qw(check_ports);

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# find free port from range and index [INT]
#
sub portcheck_index_find_free($host, $port, $offset, $index){
	my $fid = "[portcheck_index_find_free]";
	my $success = 0;
	
	log_debug($fid, "index [$index] offset [$offset] port [$port]");
	my $newport = ($port + $offset);
	
	do{
		# find a port
		$newport = index_free($index, $newport);
		log_debug($fid, "found free port [$port]");

		# validate port
		$newport = portcheck_find_free($host, $newport);
		log_debug($fid, "port [$newport] is available");
			
		# check index
		if(!index_find($index, $newport)){
			log_debug($fid, "success: port [$newport] is free and not in index");
			$success = 1;
		}
		else{
			log_warn($fid, "failure: port [" . $newport . "] is free but in index!");
			$port++;
		}
		
	}while(!$success);
	
	return ($newport - $offset);
}

#
# find free port from range [INT]
#
sub portcheck_find_free($host, $start){
	my $fid = "[portcheck_find_free]";
	my $port = $start;
	
	while(!portcheck_tcp_avail($host, $port)){
		$port++;
		sleep 0.1;
	}
	
	log_debug($fid, "found free port [$port]");
	return $port;
}

#
# check for open port [BOOLEAN]
#
sub portcheck_tcp_avail($host, $port){
	my $timeout = "5";
	my %porthash = ( tcp => {} );
	$porthash{'tcp'}{$port} = {};
	
	my $check = check_ports($host, $timeout, \%porthash);
	
	if($check->{'tcp'}{$port}{'open'}){
		return 0;
	}
	else{
		return 1;
	}
}

1;
