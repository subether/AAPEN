#
# ETHER|AAPEN|LIBS - BASE|LOG
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
use Fcntl qw(:flock);

our $VERSION = 3.5.0;
our @ISA     = qw(Exporter);


#
# initialize log dir [NULL]
#
sub log_init(){
	my $fid = "[log_init]";
	my $log_dir = base_log_dir_get();
	
	if(!dir_check($log_dir)){
		print "$fid log dir [$log_dir] does not exist. creating it..\n";
		dir_create($log_dir);
	}
}

#
# log message [NULL]
#
sub log_msg($fid, $level, $msg){
	if(log_level_check($level)){
		print "[", BOLD BLACK, date_get(), RESET, "] [", BOLD BLUE, env_sid_get(), RESET, "|", BOLD MAGENTA, $fid, RESET, "] ", BOLD, uc($level), RESET, " | " . $msg . "\n";
	}
	
	# write to file
	log_write($fid, $level, $msg);
}

#
# log message with json [NULL]
#
sub log_msg_json($fid, $level, $msg, $json){
	my $timestamp = date_get();
	
	if(log_level_check($level)){
		my $log_line = "[$timestamp] [" . env_sid_get() . "|$fid] $level | $msg";
		print "[", BOLD BLACK, $timestamp, RESET, "] [", BOLD BLUE, env_sid_get(), RESET, "|", BOLD MAGENTA, $fid, RESET, "] ", BOLD, $level, RESET, " | " . $msg . "\n";
		json_encode_pretty($json);
	}
	
	# write to file
	log_write_json($fid, $level, $msg, $json);
}

#
# check log level [BOOLEAN]
#
sub log_level_check($level){
	my $fid = "[log_level_check]";
		
	# parse log levels
	if($level eq "WARN" || $level eq "ERROR" || $level eq "FATAL"){ return 1; }
	elsif(env_daemon()){ return 0; }
	elsif($level eq "INFO" && env_info()){ return 1; }
	elsif($level eq "DEBUG" && env_debug()){ return 1; }
	else{ return 0; };
	
}

#
# check log level [BOOLEAN]
#
sub log_level_write_check($level){
	my $fid = "[log_level_write_check]";
		
	# parse log levels
	if($level eq "WARN" || $level eq "ERROR" || $level eq "FATAL"){ return 1; }
	elsif($level eq "INFO" && env_info()){ return 1; }
	elsif($level eq "DEBUG" && env_debug()){ return 1; }
	else{ return 0; };
	
}

#
# write to logfile [NULL]
#
sub log_write($fid, $level, $msg){

	if(log_level_write_check($level)){
		my $log_file = base_log_file_get();
		my $msg_write = "[" . date_get() . "] [" . env_sid_get() . "|" . $fid . "] " . uc($level) . " | " . $msg . "\n";
		
		# thread-safe file writing
		open(my $fh, '>>', $log_file) or return;
		flock($fh, LOCK_EX);
		print $fh $msg_write;
		flock($fh, LOCK_UN);
		close($fh);
	}
	
}

#
# write to logfile [NULL]
#
sub log_write_json($fid, $level, $msg, $json){

	if(log_level_write_check($level)){
		my $log_file = base_log_file_get();
		my $msg_write = "[" . date_get() . "] [" . env_sid_get() . "|" . $fid . "] " . uc($level) . " | " . $msg . "\n";
		
		# thread-safe file writing
		open(my $fh, '>>', $log_file) or return;
		flock($fh, LOCK_EX);
		print $fh $msg_write;
		print $fh json_encode_pretty($json);
		flock($fh, LOCK_UN);
		close($fh);
	}
	
}

#
# log wrappers
#
sub log_debug($fid, $msg) { log_msg($fid, 'DEBUG', $msg) }
sub log_info($fid, $msg)  { log_msg($fid, 'INFO',  $msg) }
sub log_warn($fid, $msg)  { log_msg($fid, 'WARN',  $msg) }
sub log_error($fid, $msg) { log_msg($fid, 'ERROR', $msg) }
sub log_fatal($fid, $msg) { log_msg($fid, 'FATAL', $msg); exit 1 }

sub log_debug_json($fid, $msg, $json) { log_msg_json($fid, 'DEBUG', $msg, $json) }
sub log_info_json($fid, $msg, $json)  { log_msg_json($fid, 'INFO',  $msg, $json) }
sub log_warn_json($fid, $msg, $json)  { log_msg_json($fid, 'WARN',  $msg, $json) }
sub log_error_json($fid, $msg, $json) { log_msg_json($fid, 'ERROR', $msg, $json) }
sub log_fatal_json($fid, $msg, $json) { log_msg_json($fid, 'FATAL', $msg, $json); exit 1 }

1;
