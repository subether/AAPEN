#
# ETHER|AAPEN|CLI - LIB|NODE|FRAMEWORK
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
use JSON::MaybeXS;

#
# ping cdb service on node [JSON-OBJ]
#
sub node_rest_cdb_ping($node_name){
	my $fid = "node_rest_cdb_ping";
	my $ffid = "NODE|CDB|PING";
	my $result = rest_get_request("/service/cdb/ping?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node cdb ping");
}

1;
