#
# ETHER|AAPEN|CLI - LIB|REST
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
use Term::ANSIColor qw(:constants);

use LWP::UserAgent;
use HTTP::Request;

# Create UserAgent instance
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;


#
# return API path [STRING]
#
sub rest_api_path_get() {
	return config_base_rest_api_proto() . "://" . config_base_rest_api_listen() . ":" . config_base_rest_api_port();
}

#
# rest result print handler [NULL]
#
sub api_rest_response_print($fid, $result, $string) {

	# print result
	print "\n[", BOLD BLUE, $fid, RESET, "] request [", BOLD, $string , RESET, "] result\n";
	json_encode_pretty($result);
	
	# process result
	if ($result->{'proto'}{'result'}) {
		print "[", BOLD BLUE, $fid, RESET, "]", GREEN, " success: ", RESET, "API request [", BOLD, $string, RESET, "] successful", RESET, "\n";
	}
	else {
		print "[", BOLD BLUE, $fid, RESET, "]", BOLD RED, " error: ", RESET, "API request [", BOLD, $string, RESET, "] failed", RESET, "\n";
	}	
}	

#
# general print handlers [NULL]
#
sub api_print_success($fid, $string) {
	print "[", BOLD BLUE, $fid, RESET, "]", GREEN, " success: ", RESET, $string, RESET, "\n";
}	
sub api_print_success_json($fid, $string, $json) {
	api_print_success($fid, $string);
	json_encode_pretty($json);
}	

sub api_print_error($fid, $string) {
	print "[", BOLD BLUE, $fid, RESET, "]", BOLD RED, " failure: ", RESET, $string, RESET, "\n";
}	
sub api_print_error_json($fid, $string, $json) {
	api_print_error($fid, $string);
	json_encode_pretty($json);
}

#
# ping REST API [NULL]
#
sub rest_api_ping() {
	my $fid = "cli_rest_api_ping";
	my $ffid = "REST|PING";
	
	my $result = rest_get_request("/ping");
	api_rest_response_print($ffid, $result, "api ping");
}

#
# api get request [JSON-OBJ]
#
sub rest_get_request($url) {
	my $fid = "cli_rest_get_request";
	my $ffid = "REST|GET|REQUEST";

	# send request
	my $response = $ua->get(rest_api_path_get() . $url);

	# evaluate result
	if ($response->is_success) {
		return json_decode($response->decoded_content);
	}
	else {
		return packet_build_noencode("0", "error: request failed [" . $response->status_line . "]", $fid);
	}
}

#
# api post request [JSON-OBJ]
#
sub rest_post_request($url, $data) {
	my $fid = "cli_rest_post_request";
	my $ffid = "REST|POST|REQUEST";

	# build request
	my $req = HTTP::Request->new(POST => rest_api_path_get() . $url);
	$req->header('Content-Type' => 'application/json');
	$req->content(encode_json($data));

	# send request
	my $response = $ua->request($req);

	# evaluate result
	if ($response->is_success) {
		return json_decode($response->decoded_content);
	}
	else {
		return packet_build_noencode("0", "error: request failed [" . $response->status_line . "]", $fid);
	}

}

#
# fetch file via REST [NULL]
#
sub rest_file_get() {
	my $fid = "cli_rest_file_get";
	my $ffid = "CLI|REST|FILE|GET";
	
	my $result = rest_get_request("/file/get");
	api_rest_response_print("file_get", $result, "file get");
	
	print "$fid ---- FILE DATA START ---\n";
	print $result->{'file_data'};
	print "$fid ---- FILE DATA END ---\n";
	
}

1;
