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
# ping framework service on node [JSON-OBJ]
#
sub node_rest_framework_ping($node_name){
	my $fid = "node_rest_storage_ping";
	my $ffid = "NODE|FRAMEWORK|PING";
	my $result = rest_get_request("/service/framework/ping?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node framework ping");
}

#
# get framework service meta from node [JSON-OBJ]
#
sub node_rest_framework_meta($node_name){
	my $fid = "node_rest_framework_meta";
	my $ffid = "NODE|FRAMEWORK|META";
	my $result = rest_get_request("/service/framework/meta?name=" . $node_name);
	api_rest_response_print($ffid, $result, "node framework meta");
}

#
# start service on node [JSON-OBJ]
#
sub node_rest_framework_service_start($node_name, $service_name){
	my $fid = "node_rest_framework_service_start";
	my $ffid = "NODE|FRAMEWORK|SERVICE|START";
	my $result = rest_post_request("/service/framework/service/start", {name => $node_name, service => $service_name});
	api_rest_response_print($ffid, $result, "node framework service start");
}

#
# stop service on node [JSON-OBJ]
#
sub node_rest_framework_service_stop($node_name, $service_name){
	my $fid = "node_rest_framework_service_stop";
	my $ffid = "NODE|FRAMEWORK|SERVICE|STOP";
	my $result = rest_post_request("/service/framework/service/stop", {name => $node_name, service => $service_name});
	api_rest_response_print($ffid, $result, "node framework service stop");
}

#
# restart service on node [JSON-OBJ]
#
sub node_rest_framework_service_restart($node_name, $service_name){
	my $fid = "node_rest_framework_service_restart";
	my $ffid = "NODE|FRAMEWORK|SERVICE|RESTART";
	my $result = rest_post_request("/service/framework/service/restart", {name => $node_name, service => $service_name});
	api_rest_response_print($ffid, $result, "node framework service restart");
}

#
# clear log for service on node [JSON-OBJ]
#
sub node_rest_framework_service_log_clear($node_name, $service_name){
	my $fid = "node_rest_framework_service_stop";
	my $ffid = "NODE|FRAMEWORK|SERVICE|STOP";
	my $result = rest_post_request("/service/framework/service/logclear", {name => $node_name, service => $service_name});
	api_rest_response_print($ffid, $result, "node framework service log clear");
}

#
# get service info from node [JSON-OBJ]
#
sub node_rest_framework_service_info($node_name, $service_name){
	my $fid = "node_rest_framework_service_info";
	my $ffid = "NODE|FRAMEWORK|SERVICE|INFO";
	my $result = rest_get_request("/service/framework/service/info?name=" . $node_name . "&service=" . $service_name);
	api_rest_response_print($ffid, $result, "node framework service info");
}

#
# reset system via REST [NULL]
#
sub node_rest_framework_shutdown($flag, $node_name){
	my $fid = "node_rest_framework_shutdown";
	my $ffid = "NODE|FRAMEWORK|SHUTDOWN";
	
	print "\nShutdown node [$node_name] with flag [$flag]\n\n";
	
	if(cli_verify("SHUTDOWN")){
		print "\n *** Node shutdown initialized ***\n\n";
		my $result = rest_post_request("/service/framework/shutdown", {name => $node_name, flag => $flag});
		api_rest_response_print($fid, $result, "node framework shutdown");
		json_encode_pretty($result);
	}
	else{
		print "\nNode shutdown cancelled\n";
	}
}

#
# list services on node [NULL]
#
sub node_rest_framework_service_list($node_name){
	my $fid = "node_rest_framework_service_list";
	my $ffid = "NODE|FRAMEWORK|SERVICE|LIST";
	
	my $frame_meta = rest_get_request("/service/framework/meta?name=" . $node_name);

	if($frame_meta->{'response'}{'proto'}{'result'}){
		my @service_index = index_split($frame_meta->{'response'}{'meta'}{'service'}{'index'});
		
		foreach my $service (@service_index){

			if($frame_meta->{'response'}{'meta'}{'service'}{$service}{'state'}){
				if($frame_meta->{'response'}{'meta'}{'service'}{$service}{'state'} eq "1"){
					print " SERVICE [", BOLD BLUE, $service, RESET, "] state [", BOLD GREEN, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'state'}, RESET, "] pid [$frame_meta->{'response'}{'meta'}{'service'}{$service}{'pid'}] date [", BOLD BLACK, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'date'}, RESET, "] status [", BOLD GREEN, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'status'}, RESET, "]\n";
				}
				else{
					print " SERVICE [", BOLD BLUE, $service, RESET, "] state [", BOLD MAGENTA, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'state'}, RESET, "] pid [$frame_meta->{'response'}{'meta'}{'service'}{$service}{'pid'}] date [", BOLD BLACK, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'date'}, RESET, "] status [", BOLD MAGENTA, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'status'}, RESET, "]\n";
				}
			}
			else{
				print " SERVICE [", BOLD BLUE, $service, RESET, "] state [", BOLD RED, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'state'}, RESET, "] date [", BOLD BLACK, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'date'}, RESET, "] status [", BOLD, $frame_meta->{'response'}{'meta'}{'service'}{$service}{'status'}, RESET, "]\n";
			}
		}
		
	}
	
}

# 
# get vmm info from node [JSON-OBJ]
# 
sub node_rest_framework_vmm_info($node_name, $vmm_id){
	my $fid = "node_rest_framework_vmm_info";
	my $ffid = "NODE|FRAMEWORK|VMM|INFO";
	my $result = rest_get_request("/service/framework/vmm/info?name=" . $node_name . "&vmmid=" . $vmm_id);
	api_rest_response_print($fid, $result, "node framework vmm info");
}

#
# list vmms on onde [JSON-OBJ]
#
sub node_rest_framework_vmm_list($node_name){
	my $fid = "node_rest_framework_vmm_list";
	my $ffid = "NODE|FRAMEWORK|VMM|LIST";
	
	my $frame_meta = rest_get_request("/service/framework/meta?name=" . $node_name);

	if($frame_meta->{'response'}{'proto'}{'result'}){
		my @vmm_index = index_split($frame_meta->{'response'}{'meta'}{'vmm'}{'index'});
		
		foreach my $vmm_id (@vmm_index){
		
			# get vmm from node
			my $vmm_data = rest_get_request("/service/framework/vmm/info?name=" . $node_name . "&vmmid=" . $vmm_id);

			if($vmm_data->{'proto'}{'result'}){
				print " VMM [$vmm_id] system [", BOLD BLUE, $vmm_data->{'vm'}{'id'}{'name'}, RESET, "] id [$vmm_data->{'vm'}{'id'}{'id'}] pid [$vmm_data->{'vm'}{'meta'}{'vmm'}{'pid'}] state [$vmm_data->{'vm'}{'meta'}{'vmm'}{'state'}]\n";
			}
			else{
				print "$fid failed to get vmm id [$vmm_id] data\n";
			}	
			
			

		}
		
	}
	
}

1;
