#
# ETHER|AAPEN|LIBS - BASE|STRING
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
use Scalar::Util qw(looks_like_number);	

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# strip \r\n [STRING]
#
sub string_strip($string){
	chomp($string);
	$string =~ s/\r|\n//g;
	return $string
}

#
# trim leading/trailing whitespace [STRING]
#
sub string_trim($string){
	$string =~ s/^\s+|\s+$//g;
	return $string;
}

#
#
#
sub string_clean($string){
	return string_trim(string_strip($string));
}

#
# check for unsafe characters [BOOL]
#
sub string_unsafe($string){
	my $fid = "[string_unsafe]";
	
	# only allow
	if($string ne ""){
		if ($string =~ m/^[A-Za-z0-9_\-,.:\/\\(\\) ]+$/) {
			return 0;
		}
		else{
			print "$fid UNSAFE PARAMETERS [$string]\n";
			return 1;
		}
	}
	else{
		return 0;
	}
	
	# unsafe chars
	#"\, ', ", `, *, ?, [, ], {, }, ~, $, !, &, ;, (, ), <, >, |, #, @, 0x0a"
}

sub string_validate_number($number){

	# check if number
	if(looks_like_number($number)){
		if($number >= 0 && $number < 1000000){
			return 1;
		}
	}
	else{
		log_error("VALIDATE|NUMBER", "value [$number] is not a number!");
		return 0;
	}
}

#
# validate string [STRING]
#
sub string_validate($string){
    if($string =~ /^[a-z0-9\._-]{1,32}$/i){
		return 1;
	}
	else{
		return 0;
	}
}

1;
