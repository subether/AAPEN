#
# ETHER|AAPEN|LIBS - BASE|DATE
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
use DateTime;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);

# TODO: env or base should set timezone
my $timezone = 'UTC';

#
# return date string [STRING]
#
sub date_get(){
	my $dt = DateTime->now;
	return $dt->strftime( '%d-%m-%Y-%H-%M-%S' );
}

#
# simple date [STRING]
#
sub date_get_simp(){
	my $dt = DateTime->now;
	return $dt->strftime( '%d%m%Y%H%M%S' );
}

#
# simple date [STRING]
#
sub date_get_ftype(){
	my $dt = DateTime->now;
	return $dt->strftime( '%m-%d-%Y--%H-%M-%S' );
}

#
# iso date [STRING]
#
sub date_get_iso(){
	my $dt = DateTime->now;
	return $dt->strftime( '%m-%d-%Y--%H-%M-%S' );
}

#
# convert date to datetime [DATETIME]
#
sub date_str_to_obj($datestr){	
	my $dateobj;

	if(defined $datestr && $datestr ne ""){
		# build date object
		my ($day, $month, $year, $hour, $minute, $second) = split /-/, $datestr;
		$dateobj =  DateTime->new(
			  year       => $year,
			  month      => $month,
			  day        => $day,
			  hour       => $hour,
			  minute     => $minute,
			  second     => $second,
			  time_zone  => $timezone,
		);
	}
	else{
		# build default date object
		$dateobj =  DateTime->new(
			  year       => 2000,
			  month      => 1,
			  day        => 1,
			  hour       => 00,
			  minute     => 00,
			  second     => 00,
			  time_zone  => $timezone,
		);
	}
	
	return $dateobj;
}

#
# datetime delta now [STRING]
#	
sub date_str_diff_now($datestr){
	my $datecmp = date_str_to_obj($datestr);
	my $datenow = date_str_to_obj(date_get());
	my $diff = $datenow->epoch - $datecmp->epoch;
	return $diff;
}

#
# calculate uptime short [STRING]
#
sub date_str_uptime_short($datestr){
	my $uptime = date_str_diff_now($datestr);
	my @parts = gmtime($uptime);
	my $up = $parts[7] . "d," . $parts[2] . "h," . $parts[1] . "m," . $parts[0] . "s";
	return $up;
}

#
# calculate uptime long [STRING]
#
sub date_str_uptime_long($datestr){
	my $uptime = date_str_diff_now($datestr);
	my @parts = gmtime($uptime);
	my $up = $parts[7] . " days, " . $parts[2] . " hours, " . $parts[1] . " min, " . $parts[0] . " sec";
	return $up;
}

1;
