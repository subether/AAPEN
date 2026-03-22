#
# ETHER|AAPEN|MONITOR - LIB|FRAMEWORK
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#


use warnings;
use strict;
use experimental 'signatures';
use JSON::MaybeXS;
use TryCatch;


#
# monitor framework service [NULL]
#
sub monitor_frame_serv($metadata){
	my $fid = "[monitor_framework]";
	my @frame_index = index_split($metadata->{'index'});
	my $length = @frame_index;
	my $result;
	
	if(env_verbose()){ print "\n\n[", BOLD BLUE, "service|framework", RESET, "] [$length] ----------------------------------------------------------------------------------------------------------------------------\n\n"; };

	#
	# process remote index
	#
	foreach my $frame (@frame_index){

		my $framedata = $metadata->{'db'}{$frame};
		my $framemeta = $metadata->{'meta'}{$frame};
		
		if(env_verbose()){
			print "  [", BOLD BLUE, $frame, RESET, "] id [", BOLD, $framedata->{'config'}{'id'} , RESET,"] ";
			print "vmm index [", BOLD, $framedata->{'vmm'}{'index'} , RESET,"]";
			print " ver [", BOLD BLACK, $framemeta->{'ver'} , RESET, "]";
		}

		my $diff = date_str_diff_now($framemeta->{'date'});
		if(env_verbose()){ 
			print " delta [", BOLD BLACK, $diff, RESET, "]";
			print " updated [", BOLD,  $framemeta->{'date'} , RESET, "] - ";
		}
		
		# check delta
		if($diff < 180){
			if(env_verbose()){ print "[", BOLD GREEN, "HEALTHY", RESET, "]\n"; };
			$result->{$frame}{'status'} = "HEALTHY";
			$result->{$frame}{'state'} = "ACTIVE";
			$result->{$frame}{'delta'} = $diff;
			$result->{$frame}{'updated'} = date_get();
		}
		else{
			if(env_verbose()){ print "[", BOLD RED, "ERROR", RESET, "]\n"; };
			$result->{$frame}{'status'} = "ERROR";
			$result->{$frame}{'state'} = "UNKNOWN";
			$result->{$frame}{'delta'} = $diff;
			$result->{$frame}{'updated'} = date_get();
		}		

		#
		# SERVICE
		#
		my @srv_index = index_split($framedata->{'service'}{'index'});
		
		foreach my $service (@srv_index){

			if(env_verbose()){
				print "    '- service [", BOLD, $service, RESET, "]";
				print " pid [", BOLD BLACK, $framedata->{'service'}{$service}{'pid'} , RESET, "]";
				print " state [", BOLD BLACK, $framedata->{'service'}{$service}{'state'} , RESET, "]";
				print " status [", BOLD BLACK, $framedata->{'service'}{$service}{'status'} , RESET, "]";
				print "\n"
			}
		}
		
		#
		# VMMs
		#
		my @vmm_index = index_split($framedata->{'vmm'}{'index'});
		
		foreach my $vmm (@vmm_index){
			my $up = date_str_uptime_short($framedata->{'vmm'}{$vmm}{'date'});
			
			if(env_verbose()){
				print "    '- vmm [", BOLD, $vmm, RESET, "]";
				print " system [", BOLD BLUE, $framedata->{'vmm'}{$vmm}{'system_name'} , RESET, "]";
				print " id [", BOLD BLACK, $framedata->{'vmm'}{$vmm}{'system_id'} , RESET, "]";
				print " socket [", BOLD BLACK, $framedata->{'vmm'}{$vmm}{'socket'} , RESET, "]";
				print " pid [", BOLD BLACK, $framedata->{'vmm'}{$vmm}{'pid'} , RESET, "]";
				print " up [", BOLD BLACK, $up, RESET, "]\n";				
			}
		}

		if(env_verbose()){ print "\n"; };
	}
	
	return $result;
}

1;



