#
# ETHER|AAPEN|LIBS - NETWORK|MAC
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
use Net::Ifconfig::Wrapper;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# generate random mac
#
sub net_mac_generate(){
	my $fid = "[net_mac_generate]";
	my $oid = "52:54:13:";
	my $mac = (sprintf "%0.2X",rand(256)) . ":" . (sprintf "%0.2X",rand(256)) . ":" . (sprintf "%0.2X",rand(256));
	return $oid . $mac;
}

1;
