#
# ETHER|AAPEN|LIBS - BASE|JSON
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
use Cpanel::JSON::XS;
use JSON::MaybeXS;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# string to json object [BOOL]
#
sub json_decode_validate($string){
	my $fid = "[json_decode_validate]";
	my $json;
	
	eval{
		$json = decode_json($string);
		return 1;
	} or do {
		print "$fid error: failed to decode string\n";
		print "$string\n";
		return 0;
	};
}

#
# validate json [BOOL]
#
sub json_encode_validate($string){
	my $fid = "[json_encode_validate]";
	my $json;
	
	if($string){
		try{
			my $json_str = encode_json($string);
			return json_decode_validate($json_str);
		}	
		catch{
			print "[" . date_get() . "] $fid error: failed to encode string [$string]\n";
			return 0;
		}
	}
	else{
		# string is empty
		return 0;
	}
}

#
# string to json object [JSON-OBJ]
#
sub json_decode($string){
	my $fid = "[json_decode]";
	my $json;
	
	eval{
		$json = decode_json($string);
	} or do {
		print "$fid error: failed to decode string\n";
		print "$fid string [$string]\n";
		$json = packet_build_noencode("0", "error: failed to decode string", $fid);
	};
	
	return $json;
}

#
# string to json object [JSON-OBJ]
#
sub json_decode_orig($string){
	my $fid = "[json_decode]";
	return decode_json($string);
}

#
# json object to string [JSON-STR]
#
sub json_encode($json){
	my $fid = "[json_encode]";
	my $json_temp = JSON->new->allow_nonref;
	my $json_str = $json_temp->encode($json);
	return $json_str;
}
#
# json object to pretty [JSON-STR]
#
sub json_encode_pretty($json){
	my $fid = "[json_encode_pretty]";
	my $json_temp = JSON->new->allow_nonref;
	my $json_pretty = $json_temp->pretty->encode($json);
	print BOLD BLACK,$json_pretty, RESET, "\n";
	return $json_pretty;
}

#
# json object to pretty [JSON-STR]
#
sub json_encode_pretty_silent($json){
	my $fid = "[json_encode_pretty]";
	my $json_temp = JSON->new->allow_nonref;
	my $json_pretty = $json_temp->pretty->encode($json);
	return $json_pretty;
}

#
# json string to pretty [JSON-STR]
#
sub json_decode_pretty($jsonstr){
	my $fid = "[json_decode_pretty]";
	my $json = json_decode($jsonstr);
	my $json_temp = JSON->new->allow_nonref;
	my $json_pretty = $json_temp->pretty->encode($json);
	print BOLD BLACK,$json_pretty, RESET, "\n";
	return $json_pretty;
}

#
# load json from file [JSON-OBJ]
#
sub json_file_load($json_file){
	my $fid = "[json_file_load]";
	
	# open file
	my $file;
	{
	  local $/; # enable 'slurp' mode
	  open my $fh, "<", $json_file;
	  $file = <$fh>;
	  close $fh;
	}
	
	return json_decode($file)
}

#
# save json to file [JSON-OBJ]
#
sub json_file_save($json_file, $json){
	my $fid = "[json_file_save]";
	
	# open file
	my $data = json_encode_pretty_silent($json);
	open my $fh, ">", $json_file;
	print $fh $data;
	close $fh;
	
	return $json;
}

#
# check for unsafe chars [BOOL]
#
sub json_check_unsafe($json){
	my $result = 0;
	return json_check_unsafe_iterate($result, $json);
}

#
# iterate json and check for unsafe chars [BOOL]
#
sub json_check_unsafe_iterate($result, $json){

	# iterate json keys
	for my $k (keys %$json) {
		# check for value or hash
		if(ref($json->{$k}) eq 'HASH'){
			if(json_check_unsafe_iterate($result, $json->{$k})){ return 1; };
		}
		else{
			if(string_unsafe($json->{$k})){ return 1; };
		}
	}
	
	return $result;
}

1;
