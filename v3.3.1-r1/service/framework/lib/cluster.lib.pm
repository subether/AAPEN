#
# ETHER|AAPEN|FRAMEWORK - LIB|CLUSTER
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


#
# sync framework with cluster [NULL]
#
sub frame_cdb_sync(){
	my $fid = "[frame_cdb_sync]";
	my $ffid = "CLUSTER|SYNC";

	my $db = frame_db_get();
	my $meta = {};
	frame_health_check();
	
	# config
	$meta->{'config'} = $db->{'config'};
	$meta->{'config'}{'id'} = config_node_id_get();
	$meta->{'config'}{'name'} = config_node_name_get();
	$meta->{'config'}{'service'} = "framework";
	$meta->{'updated'} = date_get();
	
	# vmm
	$meta->{'vmm'}{'index'} = $db->{'vmm'}{'index'};
	my @vmm_index = index_split($db->{'vmm'}{'index'});
	
	#
	# THIS DOES NOT ACTUALLY PUBLISH THE HEALTH CHECK STUFF - TODO
	#
	
	foreach my $vmm (@vmm_index){
		log_info($ffid, "vmm [$vmm] id [$db->{'vmm'}{$vmm}{'id'}{'id'}] name [$db->{'vmm'}{$vmm}{'id'}{'name'}] pid [$db->{'vmm'}{$vmm}{'meta'}{'vmm'}{'pid'}]");
		$meta->{'vmm'}{$vmm} = $db->{'vmm'}{$vmm}{'meta'}{'vmm'};
		if(env_debug()){ json_encode_pretty($db->{'vmm'}{$vmm}{'meta'}{'vmm'}); };
	}	
	
	# services
	$meta->{'service'} = $db->{'service'};
	if(env_debug()){ json_encode_pretty($meta); };
	my $result = api_cluster_local_service_set(env_serv_sock_get("cluster"), $meta);
}

#
# framework health check [NULL]
#
sub frame_health_check(){
	my $fid = "[frame_health_check]";
	my $ffid = "FRAME|HEALTH";
	
	# check VMM's
	frame_health_vmm_check();
	
	# check services
	frame_health_srv_check();
}

#
# framwork vmm health check [NULL]
#
sub frame_health_vmm_check(){
	my $fid = "[frame_health_vmm_check]";
	my $ffid = "HEALTH|VMM|CHECK";
	my $vmmdb = frame_db_obj_get("vmm");
	
	# check VMM's
	my @vmm_list = index_split($vmmdb->{'index'});
	
	# process vmms
	foreach my $vmm (@vmm_list){

		# check if the VMM is running
		my $vmmpid = execute('pgrep -f ' . $vmmdb->{$vmm}{'meta'}{'vmm'}{'vmmsock'});
		chomp($vmmpid);
		
		if($vmmpid){
			# pid found
			
			if($vmmpid eq $vmmdb->{$vmm}{'meta'}{'vmm'}{'pid'}){
				# pid matches

				# get data from cluster
				my $sysdata = api_cluster_local_obj_get(env_serv_sock_get("cluster"), "system", $vmmdb->{$vmm}{'id'}{'name'});				
				
				# get date
				if(defined $sysdata->{'system'}{'meta'}{'date'}){
					my $date = $sysdata->{'system'}{'meta'}{'date'};
					my $diff = date_str_diff_now($date);

					# check delta
					if($diff < 180){
						# normal delta
						log_info($ffid, "vmm [$vmm] id [$vmmdb->{$vmm}{'id'}{'id'}] name [$vmmdb->{$vmm}{'id'}{'name'}] pid [$vmmdb->{$vmm}{'meta'}{'vmm'}{'pid'}] delta [$diff] - [HEALTHY]");
					}
					elsif($diff < 480){
						# delta warning
						log_warn($ffid, "vmm [$vmm] id [$vmmdb->{$vmm}{'id'}{'id'}] name [$vmmdb->{$vmm}{'id'}{'name'}] pid [$vmmdb->{$vmm}{'meta'}{'vmm'}{'pid'}] delta [$diff] - [WARNING]");
					}
					else{
						# delta timeout
						log_warn($ffid, "vmm [$vmm] id [$vmmdb->{$vmm}{'id'}{'id'}] name [$vmmdb->{$vmm}{'id'}{'name'}] pid [$vmmdb->{$vmm}{'meta'}{'vmm'}{'pid'}] delta [$diff] - [ERROR]");
					}
					
				}
				else{
					# date missing!
					log_warn($ffid, "vmm [$vmm] id [$vmmdb->{$vmm}{'id'}{'id'}] name [$vmmdb->{$vmm}{'id'}{'name'}] pid [$vmmdb->{$vmm}{'meta'}{'vmm'}{'pid'}] - [DATE MISSING]");
				}
				
			}
			else{
				# pid does not match!
				log_warn($ffid, "vmm [$vmm] id [$vmmdb->{$vmm}{'id'}{'id'}] name [$vmmdb->{$vmm}{'id'}{'name'}] pid [$vmmdb->{$vmm}{'meta'}{'vmm'}{'pid'}] - [PID MISMATCH]");
			}
			
		}
		else{
			# VMM not found!
			log_warn($ffid, "vmm [$vmm] id [$vmmdb->{$vmm}{'id'}{'id'}] name [$vmmdb->{$vmm}{'id'}{'name'}] pid [$vmmdb->{$vmm}{'meta'}{'vmm'}{'pid'}] - [VMM NOT FOUND]");
		}
		
	}
}

#
# framework service health check [NULL]
#
sub frame_health_srv_check(){
	my $fid = "[frame_health_srv_check]";
	my $ffid = "HEALTH|SERVICE|CHECK";
	
	frame_srv_detect();
	my $srvdb = frame_db_obj_get("service");
	
	# check services
	my @srv_list = index_split($srvdb->{'index'});
	
	# process services
	#foreach my $service (@srv_list){
	#	if($srvdb->{$service}{'state'}){
	#		log_info($ffid, "SERVICE [$service] state [" . $srvdb->{$service}{'state'} . "] pid [" . $srvdb->{$service}{'pid'} . "] status [" . $srvdb->{$service}{'status'} . "]");
	#	}
	#	else{
	#		log_info($ffid, "SERVICE [$service] state [" . $srvdb->{$service}{'state'} . "] pid [" . "N/A" . "] status [" . $srvdb->{$service}{'status'} . "]\n");
	#	}
	#}
	
	return $srvdb;
}

1;
