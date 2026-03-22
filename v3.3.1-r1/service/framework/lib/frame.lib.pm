#
# ETHER|AAPEN|FRAMEWORK - LIB|FRAMEWORK
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


#
# startup the framework 
#
sub frame_boot(){
	my $fid = "[frame_boot]";
	my $ffid = "FRAME|BOOT";
	
	log_info($ffid, "initializing framework boot...");
	
	my $nodecfg = config_get();
	
	json_encode_pretty($nodecfg);
	
	if(exists($nodecfg->{'node'}{'framework'})){
		log_info($ffid, "node framework configuration present");
		
		if(exists $nodecfg->{'node'}{'framework'}{'init'}{'index'}){
			log_info($ffid, "node framework boot list present");
			
			my @init_index = index_split($nodecfg->{'node'}{'framework'}{'init'}{'index'});
	
			foreach my $init_service (@init_index){
				log_info($ffid, "init service [$init_service]");
				
				# TODO
			}
		
		}
		else{
			log_warn($ffid, "node framework service boot list missing!");
		}
		
	}
	else{
		log_warn($ffid, "node framework configuration missing!");
	}
	
}

#
# shutdown node
#
sub frame_shutdown($request){
	my $fid = "[frame_shutdown]";
	my $ffid = "FRAME|SHUTDOWN";

	my $result;
	
	print "$fid received request\n";
	json_encode_pretty($request);
	
	if($request->{'frame'}{'shutdown'} eq "graceful"){
		# graceful shutdown
		
		# shutdown vm's
		# shutdown services
		# TODO
		
		#
		# shutdown node gracefully
		#
		#execute('shutdown -h now');
		
		$result = packet_build_encode("1", "success: reached graceful shutdown", $fid);	
	}
	elsif($request->{'frame'}{'shutdown'} eq "force"){
		# forceful shutdown
		$result = packet_build_encode("1", "success: reached forceful shutdown", $fid);	
		
		#
		# shutdown node (force)
		#
		#execute('shutdown -h -P now');
		
	}
	elsif($request->{'frame'}{'shutdown'} eq "reboot"){
		# forceful shutdown
		$result = packet_build_encode("1", "success: reached node reboot", $fid);	
		
		#
		# reboot node
		#
		#execute('reboot');
		
	}
	else{
		$result = packet_build_encode("0", "failed: unknown shutdown request", $fid);	
		
		#
		# unknown request
		#
	}
	
	return $result;
}


1;
