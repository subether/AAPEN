#
# ETHER|AAPEN|CLI - LIB|SYSTEM|REST
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
# load system config [NULL]
#
sub system_rest_config_load($system_name){
	my $fid = "system_rest_config_load";
	my $ffid = "SYSTEM|CONFIG|LOAD";
	#print "$fid SYSTEM NAME [" . @system_name[0] . "]";
	my $result = rest_post_request("/system/config/load", {name => $system_name});
	api_rest_response_print($ffid, $result, "system rest config load");
}

#
# save system config [NULL]
#
sub system_rest_config_save($system_name){
	my $fid = "system_rest_config_save";
	my $ffid = "SYSTEM|CONFIG|SAVE";
	my $result = rest_post_request("/system/config/save", {name => $system_name});
	api_rest_response_print($ffid, $result, "system rest config save");
}

#
# delete system config [NULL]
#
sub system_rest_config_del($system_name){
	my $fid = "system_rest_config_del";
	my $ffid = "SYSTEM|CONFIG|DEL";
	my $result = rest_post_request("/system/config/del", {name => $system_name});
	api_rest_response_print($ffid, $result, "system rest config del");
}

#
# set system config via REST [NULL]
#
sub system_rest_config_set($system_name){
	my $fid = "system_rest_config_set";
	my $ffid = "SYSTEM|CONFIG|SET";
	
	if(defined $system_name && string_validate($system_name)){
			
		# get system config
		my $result = rest_get_request("/system/get?name=" . $system_name);
		
		if($result->{'proto'}{'result'} eq "1"){
			json_encode_pretty($result);	
						
			# check if system is online
			if($result->{'response'}{'system'}{'meta'}{'state'} eq "1"){
				api_print_error($ffid, "system is online. cannot update.");
			}
			else{
				my $result = rest_post_request("/system/config/set", {name => $system_name, system => $result->{'response'}{'system'}});
				api_rest_response_print($ffid, $result, "system rest config set");
			}

		}
		else{
			api_print_success($ffid, "failed to fetch system data", $result);
		}
		
	}
	else{
		api_print_error($ffid, "system name invalid!");
	}

}

#
# return system data [JSON-OBJ]
#
sub system_rest_get($system_name){
	return rest_get_request("/system/get?name=" . $system_name);
}

#
# return system metadata [JSON-OBJ]
#
sub system_rest_meta(){
	return rest_get_request("/system/meta");
}

#
# reset system via REST [NULL]
#
sub system_rest_boot_set($system_name, $bootdev){
	my $fid = "system_rest_boot_set";
	my $ffid = "SYSTEM|BOOT|SET";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# fetch system data
		my $result = system_rest_get($system_name);
		
		if($result->{'proto'}{'result'} eq "1"){
			api_print_success($ffid, "system [$system_name] current boot device [$result->{'response'}{'system'}{'stor'}{'boot'}]");

			# check if system is online
			if(defined $result->{'response'}{'system'}{'meta'}{'state'} && $result->{'response'}{'system'}{'meta'}{'state'} eq "0"){
				# system is not loaded
				
				my $match = 0;
				
				# check if the boot disk exists
				my @stor_disk_index = index_split($result->{'response'}{'system'}{'stor'}{'disk'});
				
				foreach my $stordev (@stor_disk_index){
					if($stordev eq $bootdev){
						$match = 1;
					}
				}

				# check if boot iso exists
				my @stor_iso_index = index_split($result->{'response'}{'system'}{'stor'}{'iso'});

				foreach my $isodev (@stor_iso_index){
					if($isodev eq $bootdev){
						$match = 1;
					}
				}
				
				# match found
				if($match){
					# write to cluster
					api_print_success($ffid, "storage device [$bootdev] exists. updating boot para");
					$result->{'response'}{'system'}{'stor'}{'boot'} = $bootdev;
					
					my $result = rest_post_request("/system/config/save", {name => $system_name, system => $result->{'response'}{'system'}});
					api_rest_response_print($ffid, $result, "system rest boot set");
				}
				else{
					api_print_error($ffid, "storage device [$bootdev] does not exist");
				}

			}
			else{
				api_print_error($ffid, "system is online. cannot modify");
			}
			
		}
		else{
			api_print_success($ffid, "failed to fetch system data", $result);
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_boot_list($system_name){
	my $fid = "system_rest_boot_list";
	my $ffid = "SYSTEM|BOOT|LIST";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# fetch system data
		my $result = rest_get_request("/system/get?name=" . $system_name);
		
		if($result->{'proto'}{'result'} eq "1"){
			print "\nsystem [$system_name] current boot device [", BOLD BLUE, $result->{'response'}{'system'}{'stor'}{'boot'}, RESET, "]\n\n";

			# check if the boot disk exists
			my @stor_disk_index = index_split($result->{'response'}{'system'}{'stor'}{'disk'});
			
			foreach my $stordev (@stor_disk_index){
				print " device [$stordev] image [$result->{'response'}{'system'}{'stor'}{$stordev}{'image'}]\n";
			}

			# check if boot iso exists
			my @stor_iso_index = index_split($result->{'response'}{'system'}{'stor'}{'iso'});

			foreach my $isodev (@stor_iso_index){
				print " iso [$isodev] image [$result->{'response'}{'system'}{'stor'}{$isodev}{'image'}]\n";
			}

		}
		else{
			api_print_success($ffid, "failed to fetch system data", $result);
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_reset($system_name){
	my $fid = "system_reset";
	my $ffid = "SYSTEM|RESET";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){
		# send REST post request
		my $result = rest_post_request("/system/reset", {name => $system_name});
		api_rest_response_print($ffid, $result, "system reset");
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_shutdown($system_name){
	my $fid = "system_shutdown";
	my $ffid = "SYSTEM|SHTDOWN";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){
		# send REST post request
		my $result = rest_post_request("/system/shutdown", {name => $system_name});
		api_rest_response_print($ffid, $result, "system shutdown");
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_unload($system_name){
	my $fid = "system_unload";
	my $ffid = "SYSTEM|UNLOAD";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){
		# send REST post request
		my $result = rest_post_request("/system/unload", {name => $system_name});
		api_rest_response_print($ffid, $result, "system unload");
	}	
	else{
		#print "$ffid error: system name invalid!\n"
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_load($system_name, $node_name){
	my $fid = "system_load";
	my $ffid = "SYSTEM|LOAD";
	
	#print "$ffid system name [$system_name] node name [$node_name]\n";
	api_print_success($ffid, "system name [$system_name] node name [$node_name]");
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $system_name && string_validate($system_name)){
			# send REST post request
			my $result = rest_post_request("/system/load", {name => $system_name, node => $node_name});
			api_rest_response_print($ffid, $result, "system load");
		}
		else{
			api_print_error($ffid, "node name invalid!");
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_validate($system_name, $node_name){
	my $fid = "system_validate";
	my $ffid = "SYSTEM|VALIDATE";
	
	api_print_success($ffid, "system name [$system_name] node name [$node_name]");
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $system_name && string_validate($system_name)){
			# send REST post request
			my $result = rest_post_request("/system/validate", {name => $system_name, node => $node_name});
			api_rest_response_print($ffid, $result, "system validate");
		}
		else{
			api_print_error($ffid, "node name invalid!");
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL] - TODO
#
sub system_rest_migrate($system_name, $dst_node_name){
	my $fid = "system_migrate";
	my $ffid = "SYSTEM|MIGRATE";
	
	api_print_success($ffid, "system name [$system_name] destination node name [$dst_node_name]");
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $system_name && string_validate($system_name)){
			# send REST post request
			my $result = rest_post_request("/system/migrate", {name => $system_name, dstnode => $dst_node_name});
			api_rest_response_print($ffid, $result, "system migrate");
		}
		else{
			api_print_error($ffid, "node name invalid!");
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL] - TODO
#
sub system_rest_move($system_name, $node_name){
	my $fid = "system_move";
	my $ffid = "SYSTEM|MOVE";
	
	api_print_success($ffid, "system name [$system_name] node name [$node_name]");
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $system_name && string_validate($system_name)){
			# send REST post request
			my $result = rest_post_request("/system/move", {name => $system_name, node => $node_name});
			api_rest_response_print($ffid, $result, "system move");
		}
		else{
			api_print_error($ffid, "node name invalid!");
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_clone_config($src_system_name, $dst_system_name, $dst_system_id, $dst_system_group, $storage_pool_name){
	my $fid = "system_clone_config";
	my $ffid = "SYSTEM|CLONE|CONFIG";
	
	print "$ffid cloning system configuration\n";
	print "SRC SYSTEM NAME [$src_system_name]\n";
	print "DST SYSTEM NAME [$dst_system_name]\n";
	print "DST SYSTEM ID [$dst_system_id]\n";
	print "DST SYSTEM GROUP [$dst_system_group]\n";
	print "DST SYSTEM POOL [$storage_pool_name]\n";
	
	# validate source system name
	if(!defined $src_system_name || !string_validate($src_system_name)){
		api_print_error($ffid, "source system name [$src_system_name] invalid");
		return;
	}

	# validate source system name
	if(!defined $dst_system_name || !string_validate($dst_system_name)){
		api_print_error($ffid, "destination system name [$dst_system_name] invalid");
		return;
	}

	# validate source system name
	if(!defined $dst_system_id || !string_validate($dst_system_id)){
		api_print_error($ffid, "destination system id [$dst_system_id] invalid");
		return;
	}
	
	# validate source system name
	if(!defined $dst_system_group || !string_validate($dst_system_group)){
		api_print_error($ffid, "destination system group [$dst_system_group] invalid");
		return;
	}	

	# validate source system name
	if(!defined $storage_pool_name || !string_validate($storage_pool_name)){
		api_print_error($ffid, "destination storage pool [$storage_pool_name] invalid");
		return;
	}		
	
	api_print_success($ffid, "validation successful");
	
	my $result = rest_post_request("/system/config/clone", {srcname => $src_system_name, dstname => $dst_system_name, dstid => $dst_system_id, dstgroup => $dst_system_group, dstpool => $storage_pool_name});
	api_rest_response_print($ffid, $result, "system config clone");
}

#
# reset system via REST [NULL]
#
sub system_rest_clone_full($src_system_name, $dst_system_name, $dst_system_id, $dst_system_group, $storage_pool_name, $node_name){
	my $fid = "system_clone_full";
	my $ffid = "SYSTEM|CLONE|FULL";
	
	print "$fid cloning system configuration\n";
	print "SRC SYSTEM NAME [$src_system_name]\n";
	print "DST SYSTEM NAME [$dst_system_name]\n";
	print "DST SYSTEM ID [$dst_system_id]\n";
	print "DST SYSTEM GROUP [$dst_system_group]\n";
	print "DST SYSTEM POOL [$storage_pool_name]\n";
	
	# validate source system name
	if(!defined $src_system_name || !string_validate($src_system_name)){
		api_print_error($ffid, "source system name [$src_system_name] invalid");
		return;
	}

	# validate source system name
	if(!defined $dst_system_name || !string_validate($dst_system_name)){
		api_print_error($ffid, "destination system name [$dst_system_name] invalid");
		return;
	}

	# validate source system name
	if(!defined $dst_system_id || !string_validate($dst_system_id)){
		api_print_error($ffid, "destination system id [$dst_system_id] invalid");
		return;
	}
	
	# validate source system name
	if(!defined $dst_system_group || !string_validate($dst_system_group)){
		api_print_error($ffid, "destination storage pool [$storage_pool_name] invalid");
		return;
	}	

	# validate source system name
	if(!defined $storage_pool_name || !string_validate($storage_pool_name)){
		api_print_error($ffid, "destination storage pool [$storage_pool_name] invalid");
		return;
	}		

	# validate source system name
	if(!defined $node_name || !string_validate($node_name)){
		api_print_error($ffid, "node name [$node_name] invalid");
		return;
	}	

	api_print_success($ffid, "validation successful");
	
	my $result = rest_post_request("/system/clone", {srcname => $src_system_name, dstname => $dst_system_name, dstid => $dst_system_id, dstgroup => $dst_system_group, dstpool => $storage_pool_name, node => $node_name});
	api_rest_response_print($ffid, $result, "system config clone");
}

#
# reset system via REST [NULL]
#
sub system_rest_create($system_name, $node_name){
	my $fid = "system_create";
	my $ffid = "SYSTEM|CREATE";
	
	api_print_success($ffid, "system name [$system_name] node name [$node_name]");
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $node_name && string_validate($node_name)){
			# send REST post request
			my $result = rest_post_request("/system/create", {name => $system_name, node => $node_name});
			api_rest_response_print($ffid, $result, "system create");
		}
		else{
			api_print_error($ffid, "node name invalid!");
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_storage_add($system_name, $storage_name, $node_name){
	my $fid = "system_rest_storage_add";
	my $ffid = "SYSTEM|STORAGE|ADD";

	api_print_success($ffid, "system name [$system_name] storage name [$storage_name] node name [$node_name]");
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $node_name && string_validate($node_name)){
			# send REST post request
			my $result = rest_post_request("/system/storage/add", {name => $system_name, storage => $storage_name, node => $node_name});
			api_rest_response_print($ffid, $result, "storage add");
		}
		else{
			api_print_error($ffid, "node name invalid!");
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_storage_expand($system_name, $storage_name, $node_name){
	my $fid = "system_rest_storage_expand";
	my $ffid = "SYSTEM|STORAGE|EXPAND";
	
	api_print_success($ffid, "system name [$system_name] storage name [$storage_name] node name [$node_name]");
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# validate node name
		if(defined $node_name && string_validate($node_name)){
			# send REST post request
			my $result = rest_post_request("/system/storage/expand", {name => $system_name, storage => $storage_name, node => $node_name});
			api_rest_response_print($ffid, $result, "storage expand");
		}
		else{
			api_print_error($ffid, "node name invalid!");
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_delete($system_name, $node_name){
	my $fid = "system_delete";
	my $ffid = "SYSTEM|DELETE";
	
	print "\n *** WARNING: THIS ACTION CANNOT BE UNDONE! ***\n";
	print "\n *** DELETE system [$system_name] using node [$node_name]? ***\n";
	print "\n *** WARNING: SYSTEM WILL BE DELETED PERMANENTLY FROM DISK ***\n";
	
	if(cli_verify("DELETE")){
	# validate system name
		if(defined $system_name && string_validate($system_name)){

			# validate node name
			if(defined $system_name && string_validate($system_name)){
				# send REST post request
				my $result = rest_post_request("/system/delete", {name => $system_name, node => $node_name});
				api_rest_response_print($ffid, $result, "system delete");
			}
			else{
				api_print_error($ffid, "node name invalid!");
			}
		}	
		else{
			api_print_error($ffid, "system name invalid!");
		}
	}
	else{
		api_print_error($ffid, "system delete operation cancelled!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_info($system_name){
	my $fid = "system_info";
	my $ffid = "SYSTEM|INFO";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){
		# send rest get request
		my $result = rest_get_request("/system/get?name=" . $system_name);
		api_rest_response_print($ffid, $result, "system info");
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# reset system via REST [NULL]
#
sub system_rest_console($system_name){
	my $fid = "system_console";
	my $ffid = "SYSTEM|CONSOLE";
	
	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# fetch system data
		my $result = rest_get_request("/system/get?name=" . $system_name);
		
		if($result->{'proto'}{'result'} eq "1"){

			# check if system is online
			if(defined $result->{'response'}{'system'}{'meta'}{'state'} && $result->{'response'}{'system'}{'meta'}{'state'} eq "1"){
				
				# fetch the node
				my $node_result = rest_get_request("/node/get?name=" . $result->{'response'}{'system'}{'meta'}{'node_name'});
				
				if($node_result->{'proto'}{'result'} eq "1"){
					
					# VNC - STATIC PORT RANGE USE CONFIG BASE - TODO
					my $vnc = ($result->{'response'}{'system'}{'meta'}{'vnc'} + 5900);
					my $node_addr = $node_result->{'response'}{'node'}{'agent'}{'address'};
					
					# EXEC
					my $exec = "vncviewer --shared " . $node_addr . ":" . $vnc  . " > /dev/null 2>&1 &";
					my $pid = forker($exec);
					
					api_print_success($ffid, "VNC [" . $result->{'response'}{'system'}{'meta'}{'vnc'} . "] PORT [$vnc] ADDRESS [$node_addr] PID [$pid]");
				}
				else{
					api_print_error_json($ffid, "failed to fetch node data", $result);
				}
			}
			else{
				api_print_error($ffid, "system is offline!");
			}
			
		}
		else{
			api_print_error_json($ffid, "failed to fetch system data", $result);
		}
	}	
	else{
		api_print_error($ffid, "system name invalid!");
	}
}

#
# list systems [NULL]
#
sub system_rest_list($option, $string){
	my $ffid = "SYSTEM|LIST";

	my $system_db = rest_get_request("/system/db");

	if($system_db->{'proto'}{'result'}){
		
		# build index
		my @sys_index = index_split($system_db->{'response'}{'db'}{'system'}{'index'});
		@sys_index = sort @sys_index;
		
		my $length = @sys_index;
		print "\n[", BOLD BLUE, "systems", RESET, "] [$length]\n\n";
		my $count = 0;
		
		# iterate systems
		foreach my $system_name (@sys_index){
			my $system = $system_db->{'response'}{'db'}{'system'}{'db'}{$system_name};
			
			# list all systems
			if($option eq "all"){
				system_rest_list_print($system);
				$count++;
			}
			
			# list online systems
			if($option eq "online" && $system->{'meta'}{'state'} eq "1"){
				system_rest_list_print($system);
				$count++;
			}
			
			# list offline systems
			if($option eq "offline" && (!(defined $system->{'meta'}{'state'}) || $system->{'meta'}{'state'} eq "0")){
				system_rest_list_print($system);
				$count++;
			}		
			
			# search for systems
			if($option eq "find" && $system->{'id'}{'name'} =~ $string){
				system_rest_list_print($system);
				$count++;
			}
			
			# list systems in group
			if($option eq "group" && $system->{'id'}{'group'} =~ $string){
				system_rest_list_print($system);
				$count++;
			}
			
			# list systems on node
			if($option eq "node" && (defined $system->{'meta'}{'node_name'} && $system->{'meta'}{'node_name'} =~ $string)){
				system_rest_list_print($system);
				$count++;
			}
			
			# list systems with network
			if($option eq "network"){
				my @nics = index_split($system->{'net'}{'dev'});
				foreach my $nic (@nics){
					if($system->{'net'}{$nic}{'net'}{'id'} eq $string || $system->{'net'}{$nic}{'net'}{'name'} eq $string){
						system_rest_list_print($system);
						$count++;
					}
				}
			}
			
			# search for mac
			if($option eq "mac"){
				my @nics = index_split($system->{'net'}{'dev'});
				foreach my $nic (@nics){
					if($system->{'net'}{$nic}{'mac'} =~ $string){
						system_rest_list_print($system);
						$count++;
					}
				}
			}
			
			# search for address
			if($option eq "addr"){
				my @nics = index_split($system->{'net'}{'dev'});
				foreach my $nic (@nics){
					if($system->{'net'}{$nic}{'ip'} =~ $string){
						system_rest_list_print($system);
						$count++;
					}
				}
			}	
			
			# systems in cluster
			if($option eq "cluster"){
				if(defined($system->{'object'}{'meta'})){
					system_rest_list_print($system);
					$count++;
				}
			}
			
			# list local systems
			if($option eq "local"){
				if(!defined($system->{'object'}{'meta'})){
					system_rest_list_print($system);
					$count++;
				}
			}
			
			# systems with tag
			if($option eq "tag"){
				if($system->{'id'}{'tags'} =~ $string){
					system_rest_list_print($system);
					$count++;
				}
			}

			# systems with tag
			#if($option eq "cluster"){
			#	if($system->{'id'}{'cluster'} eq $string){
			#		system_rest_list_print($system);
			#		$count++;
			#	}
			#}

			# systems not initialized
			if($option eq "init"){
				if(defined($system->{'object'}{'init'}) && !$system->{'object'}{'init'}){
					system_rest_list_print($system);
					$count++;
				}
			}
			
		}
		
		print "\nListed [$count] systems with filter [$option]\n";
		
	}
	else{
		api_print_error($ffid, "failed to fetch system db");
	}
	
}

#
# system list [NULL]
#
sub system_rest_list_print($system){
	print " id [", BOLD BLUE, $system->{'id'}{'id'}, RESET, "] name [", BOLD, $system->{'id'}{'name'}, RESET, "] ";
	
	if($system->{'meta'}{'state'} eq "1"){
		# online
		print "- state [", BOLD GREEN, "ONLINE", RESET, "] node [", BOLD, $system->{'meta'}{'node'}, RESET, "] "; 
	}
	elsif($system->{'meta'}{'state'} eq "0"){
		# offline
		if(defined($system->{'state'}{'vm_status'})){
			if($system->{'state'}{'vm_status'} eq "ended"){
				print "state [", BOLD RED, "VM STOPPED", RESET, "] "; 
			}
			else{
				print "state [", BOLD RED, "OFFLINE", RESET, "] ";
			}
		}
		else{
			# legacy support
			print "state [", BOLD RED, "OFFLINE", RESET, "] "; 
		}
	}
	else{
		print "state [", BOLD BLACK, "UNKNOWN", RESET, "] "; 
	}
	
	if(defined($system->{'object'}{'init'})){
		if(!$system->{'object'}{'init'}){
			print "[", BOLD MAGENTA, "NOT INITIALIZED", RESET, "] "; 
		}
	}
	
	if(defined($system->{'object'}{'meta'}{'ver'})){
		print "ver [", BOLD BLACK, $system->{'object'}{'meta'}{'ver'}, RESET,"] ";
	}
	
	if(defined($system->{'state'}{'vm_status'})){
		print "status [", BOLD,  $system->{'state'}{'vm_status'} , RESET, "] ";
		
		if(defined($system->{'object'}{'meta'}) && ($system->{'state'}{'vm_status'} ne "unloaded") && ($system->{'state'}{'vm_status'} ne "offline") && ($system->{'state'}{'vm_status'} ne "unloaded_force") && ($system->{'state'}{'vm_status'} ne "poweroff") && ($system->{'state'}{'vm_status'} ne "shutdown") && ($system->{'state'}{'vm_status'} ne "move_complete") && ($system->{'state'}{'vm_status'} ne "cloning_complete")){
			print "updated [", BOLD, $system->{'object'}{'meta'}{'date'}, RESET, "] ";
			my $diff = date_str_diff_now($system->{'object'}{'meta'}{'date'});
			print "delta [", BOLD BLACK, $diff, RESET, "] ";
			
			if($diff < 180){
				print "- [", BOLD GREEN, "HEALTHY", RESET, "] "; 
			}
			elsif($diff < 320){
				print "- [", BOLD MAGENTA, "WARNING", RESET, "] "; 
			}
			elsif($diff < 480){
				print "- [", BOLD RED, "ERROR", RESET, "] "; 
			}
			else{
				print "- [", BOLD RED, "FAILURE", RESET, "] "; 
			}
		}		
	}
	
	if(defined($system->{'object'}{'meta'}{'ver'})){
		print "- [", BOLD BLUE, "CLUSTER", RESET, "] "; 
	}
	else{
		print "- [", BOLD, "LOCAL", RESET, "] "; 
	}
	
	print "\n";	
}

#
# migrate storage pool config for system [NULL]
#
sub system_rest_storage_pool_migrate_config($system_name, $stordev, $storpool){
	my $fid = "[system_rest_storage_pool_migrate_config]";
	my $ffid = "SYSTEM|STORAGE|POOL|MIGRATE|CONFIG";
	
	api_print_success($ffid, "system [$system_name] storage device [$stordev] storpool [$storpool]");

	# validate system name
	if(defined $system_name && string_validate($system_name)){

		# fetch system data
		my $result = rest_get_request("/system/get?name=" . $system_name);

		if($result->{'proto'}{'result'} eq "1"){
			api_print_success($ffid, "successfully got system config");
			#print "$fid GOT SYSTEM\n";

			# check if system is online
			if(defined $result->{'response'}{'system'}{'meta'}{'state'} && $result->{'response'}{'system'}{'meta'}{'state'} eq "0"){
				api_print_success($ffid, "system state is offline.. continuing..");
				
				# check the storage device
				api_print_success($ffid, "system storage index [$result->{'response'}{'system'}{'stor'}{'disk'}]");
				
				if(index_find($result->{'response'}{'system'}{'stor'}{'disk'}, $stordev)){
					api_print_success($ffid, "storage device configured.. continuing..");
					
					my $stor = storage_rest_get($storpool);
					if($stor->{'proto'}{'result'} eq "1"){ 
						api_print_success_json($ffid, "successfully fetched storage pool config", $stor->{'response'}{'pooldata'});
						
						# get path
						api_print_success($ffid, "pool path [$stor->{'response'}{'pooldata'}{'pool'}{'path'}] system group [$result->{'response'}{'system'}{'id'}{'group'}]");
						
						# calculate new path
						api_print_success($ffid, "old path [$result->{'response'}{'system'}{'stor'}{$stordev}{'dev'}]");
						
						my $newpath = $stor->{'response'}{'pooldata'}{'pool'}{'path'} . $result->{'response'}{'system'}{'id'}{'group'} . "/" . $result->{'response'}{'system'}{'id'}{'name'} . "/";
						api_print_success($ffid, "new path [$newpath]");
						
						api_print_success_json($ffid, "old config for [$stordev] system [$system_name]", $result->{'response'}{'system'}{'stor'}{$stordev});
						
						# update pool stuff
						$result->{'response'}{'system'}{'stor'}{$stordev}{'backing'} = "pool";
						$result->{'response'}{'system'}{'stor'}{$stordev}{'pool'}{'id'} = $stor->{'response'}{'pooldata'}{'id'}{'id'};
						$result->{'response'}{'system'}{'stor'}{$stordev}{'pool'}{'name'} = $stor->{'response'}{'pooldata'}{'id'}{'name'};
						$result->{'response'}{'system'}{'stor'}{$stordev}{'pool'}{'type'} = $stor->{'response'}{'pooldata'}{'object'}{'class'};
						$result->{'response'}{'system'}{'stor'}{$stordev}{'dev'} = $newpath;
						
						#print "NEW CONFIG FOR [$stordev] SYSTEM [$system_name]\n";
						api_print_success_json($ffid, "new config for [$stordev] system [$system_name]", $result->{'response'}{'system'}{'stor'}{$stordev});
						
						
						print "\nCOMMIT NEW CONFIG?\n";
						if(cli_verify("YES")){
							api_print_success($ffid, "operation accepted!");
							my $result = rest_post_request("/system/config/set", {name => $system_name, system => $result->{'response'}{'system'}});
							api_rest_response_print($fid, $result, "system rest config set");
							
						}
						else{
							api_print_success($ffid, "operation cancelled!");
						}
						
					}	
					else{
						api_print_error_json($ffid, "failed to fetch pool data", $stor);
					};
					
				}
				else{
					api_print_error($ffid, "storage device not found!");
				}
				
			}
			else{
				api_print_error($ffid, "system marked online or unknown state");
			}
		}
		else{
			api_print_error_json($ffid, "failed to fetch system data!", $result);
		}
	}
	else{
		api_print_error($ffid, "system name invalid!");
	}
	
}


1;
