#
# ETHER|AAPEN|LIBS - BASE|THREAD
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
use threads;
use threads::shared;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# monitor thread [NULL]
#
sub thread_monitor($thread, $id, $name){
	my $fid = "BASE|THREAD|MONITOR";
	
	# thread running
	if($thread->is_running()){
		if(env_debug()){ print "[" . date_get() . "] $fid [$fid|$name] thread is running\n"; };
		log_debug($fid, "thread id [$id] name [$name] is running");
	}
	# thread ended 
	if($thread->is_joinable()){
		log_warn($fid, "thread id [$id] name [$name] is joinable");
		$thread->join();
		
		sleep 2;
		$thread = threads->create( $id );
	}
	# thread error
	if($thread->error()){
		log_warn($fid, "thread id [$id] name [$name] error! attempting recovery...");
		
		# Clean up failed thread
		if($thread->is_running()) {
			$thread->kill('TERM')->detach();
		} elsif($thread->is_joinable()) {
			$thread->join();
		}
		
		# Wait before restarting
		sleep 1;
		
		# Create new thread instance
		$thread = threads->create($id);
		log_warn($fid, "thread id [$id] name [$name] restarted");
	}
}

1;
