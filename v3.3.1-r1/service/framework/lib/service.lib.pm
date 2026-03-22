#
# ETHER|AAPEN|FRAMEWORK - LIB|SERVICE
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

# 5MB
my $log_file_max = 2000000;

#
# get service info [JSON-OBJ]
#
sub frame_srv_info($req){
    my $fid = "[frame_srv_info]";
	my $ffid = "SERVICE|INFO";
    my $srvdb = frame_db_obj_get("service");
    my $return;

    # check for valid service
    if(index_find($srvdb->{'index'}, $req->{'srv'}{'id'})){
        # service found
        $return = packet_build_noencode("1", "success: returning service info", $fid);
        $return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
    }
    else{
        # unknown service
        $return = packet_build_noencode("0", "failed: unknown service", $fid);
    }

    return json_encode($return);
}

#
# initialize services [JSON-OBJ]
#
sub frame_srv_init($req){
    my $fid = "[frame_service_init]";
    my $return = packet_build_noencode("1", "success: reached service init", $fid);
    return $return;
}

#
# check service pids [JSON-OBJ]
#
sub frame_srv_pid_check($srvpid) {
    my $fid = "[frame_srv_pid_check]";
	my $ffid = "SERVICE|PID|CHECK";

    my $result = {
        status => 'empty',
        count => 0,
        pids => []
    };

    # Remove any trailing whitespace/newlines
    $srvpid =~ s/\s+$//;

    if (!$srvpid) {
        if(env_debug()) { print "$fid no PIDs found\n"; }
        return $result;
    }

    # Split by whitespace/newlines
    my @pids = split(/\s+/, $srvpid);
    
    if (@pids == 1) {
        $result->{status} = 'single';
        $result->{count} = 1;
        $result->{pids} = \@pids;
        if(env_debug()) { print "$fid single PID found: $pids[0]\n"; }
    } 
    elsif (@pids > 1) {
        $result->{status} = 'multiple'; 
        $result->{count} = scalar @pids;
        $result->{pids} = \@pids;
        if(env_debug()) { print "$fid multiple PIDs found: " . join(', ', @pids) . "\n"; }
    }

    return $result;
}

#
# detect service status [NULL]
#
sub frame_srv_detect(){
    my $fid = "[frame_srv_detect]";
    my $ffid = "SERVICE|DETECT";

	log_info($ffid, "detecting services");

    my $srvdb = frame_db_obj_get("service");
    my @srv_index = index_split($srvdb->{'index'});
    
    foreach my $service (@srv_index){
		
		# check if service state
		if($srvdb->{$service}{'state'}){
			# service has state
			
			# get service config
			my $srvconf = frame_srv_conf_get($service);
			
			my $srvpid = execute('pgrep -f ' . '"' . $srvconf->{'exec'} . '"');
			chomp($srvpid);
			
			# check for multiple or single pids
			my $result = frame_srv_pid_check($srvpid);
			
			my $pidstr = "";

			if($result->{'status'} eq "single"){
				log_debug($ffid, "service [$service] has a single PID");
				$srvdb->{$service}{'stats'}{'cpu'} = process_stats_cpu($srvpid);
				$srvdb->{$service}{'stats'}{'mem'} = process_stats_mem($srvpid);
				$srvdb->{$service}{'stats'}{'log_size'} = frame_srv_logfile_check($service);
				$pidstr = $srvpid;
			}
			else{
				
				# API multiple threads expected
				if($service eq "api"){
				
					$srvdb->{$service}{'stats'}{'cpu'} = 0;
					$srvdb->{$service}{'stats'}{'mem'} = 0;
				
					foreach my $spid (@{$result->{pids}}){
						#log_debug($ffid, "service [$service] has multiple PIDs [$spid]");
						
						# add mem and cpu aggregates
						$srvdb->{$service}{'stats'}{'cpu'} += process_stats_cpu($spid);
						$srvdb->{$service}{'stats'}{'mem'} += process_stats_mem($spid);
						$pidstr = index_add($pidstr, $spid);
					}
					
					$srvdb->{$service}{'stats'}{'log_size'} = frame_srv_logfile_check($service);
				}
				else{
					log_warn($ffid, "warning: service [$service] has multiple pids!");
				}
			}

			log_info($ffid, "service [$service] state [$srvdb->{$service}{'state'}] status [$srvdb->{$service}{'status'}] pid [$pidstr] cpu [$srvdb->{$service}{'stats'}{'cpu'}%] mem [$srvdb->{$service}{'stats'}{'mem'}]");

			if($srvdb->{$service}{'state'} == 1){
				# could use greater than zero here

				# check if service exists
				if($pidstr eq $srvdb->{$service}{'pid'}){
					log_debug($ffid, "pid for service [$service] matches");
					$srvdb->{$service}{'date'} = date_get();
					frame_db_obj_set("service", $srvdb);
				}
				else{
					log_warn($ffid, "pid for service [$service] has changed! was [$srvdb->{$service}{'pid'}] is now [$srvpid]");
					
					if($srvpid){
						$srvdb->{$service}{'state'} = 1;
						$srvdb->{$service}{'status'} = "internal";
						$srvdb->{$service}{'date'} = date_get();
						$srvdb->{$service}{'pid'} = $pidstr;

						frame_db_obj_set("service", $srvdb);
					}
					else{
						log_warn($ffid, "service [$service] has changed to stopped!");
						
						# need to restart service here!
						$srvdb->{$service}{'state'} = 0;
						$srvdb->{$service}{'status'} = "stopped";
						$srvdb->{$service}{'date'} = date_get();
						$srvdb->{$service}{'pid'} = "";

						frame_db_obj_set("service", $srvdb);
					}
				}			
			}
			else{

				# check if service exists
				if($pidstr eq $srvdb->{$service}{'pid'}){
					log_debug($ffid, "pid for service [$service] matches");
					$srvdb->{$service}{'date'} = date_get();
					frame_db_obj_set("service", $srvdb);
				}
				else{
					log_warn($ffid, "pid for service [$service] has changed! was [$srvdb->{$service}{'pid'}] is now [$srvpid]");
					
					if($srvpid){
						$srvdb->{$service}{'state'} = 2;
						$srvdb->{$service}{'status'} = "running_external";
						$srvdb->{$service}{'date'} = date_get();
						$srvdb->{$service}{'pid'} = $pidstr;

						frame_db_obj_set("service", $srvdb);
					}
					else{
						log_warn($ffid, "service [$service] has changed to stopped!");
						
						$srvdb->{$service}{'state'} = 0;
						$srvdb->{$service}{'status'} = "stopped";
						$srvdb->{$service}{'date'} = date_get();
						$srvdb->{$service}{'pid'} = "";

						frame_db_obj_set("service", $srvdb);
					}					
				}				
			}			
		}
		else{
			# service does not have pervious state
			
			my $srvconf = frame_srv_conf_get($service);

			# check for pids
			my $srvpid = execute('pgrep -f ' . '"' . $srvconf->{'exec'} . '"');
			chomp($srvpid);	
			my $pidstr = "";
			
			if($srvpid){
				log_debug($ffid, "service [$service] running with pid [$srvpid] found");
				
				my $result = frame_srv_pid_check($srvpid);

				# fetch cpu and mem stats
				if($result->{'status'} eq "single"){
					log_debug($ffid, "service [$service] has a single PID");
					$srvdb->{$service}{'stats'}{'cpu'} = process_stats_cpu($srvpid);
					$srvdb->{$service}{'stats'}{'mem'} = process_stats_mem($srvpid);
					$srvdb->{$service}{'stats'}{'log_size'} = frame_srv_logfile_check($service);
					$pidstr = $srvpid;
				}
				else{
					if($service eq "api"){
					
						$srvdb->{$service}{'stats'}{'cpu'} = 0;
						$srvdb->{$service}{'stats'}{'mem'} = 0;
					
						foreach my $spid (@{$result->{pids}}){
							
							# add mem and cpu aggregates
							$srvdb->{$service}{'stats'}{'cpu'} += process_stats_cpu($spid);
							$srvdb->{$service}{'stats'}{'mem'} += process_stats_mem($spid);
							$pidstr = index_add($pidstr, $spid);
						}
					}
					else{
						log_warn($ffid, "warning: service [$service] has multiple pids!");
					}
					
				}

				log_info($ffid, "service [$service] state [$srvdb->{$service}{'state'}] status [$srvdb->{$service}{'status'}] pid [$pidstr] cpu [$srvdb->{$service}{'stats'}{'cpu'}%] mem [$srvdb->{$service}{'stats'}{'mem'}]");

				# check if it is running interally or externally
				$srvdb->{$service}{'state'} = 2;
				$srvdb->{$service}{'status'} = "running_external";
				$srvdb->{$service}{'date'} = date_get();
				$srvdb->{$service}{'pid'} = $pidstr;

				frame_db_obj_set("service", $srvdb);
			}
			else{
				log_info($ffid, "service [$service] not running");
				
				# check if it is expected to run!
				$srvdb->{$service}{'state'} = 0;
				$srvdb->{$service}{'status'} = "stopped";
				$srvdb->{$service}{'date'} = date_get();
				$srvdb->{$service}{'pid'} = $pidstr;
				
				frame_db_obj_set("service", $srvdb);			
			}
		}
		
	}

}

#
# check service status [NULL]
#
sub frame_srv_logfile_check($service){
    my $fid = "[frame_service_log]";
	my $ffid = "SERVICE|LOG|SIZE";

    my $conf = frame_srv_conf_get($service);
    my $file = $conf->{'log'};
	my $size = file_size($file);
    
    log_debug($ffid, "service [$service] logfile [$file] size [$size]");
    
    if($size > $log_file_max){
		log_warn($ffid, "log file [$file] size [$size] above [$log_file_max].. truncating!");
		
		# truncate log file
		my $exec = 'echo "" > ' . $file;
		my $result = forker($exec);
		$size = 0;
	}
	
	return $size;
}

#
# start service [JSON-STR]
#
sub frame_srv_start($req){
    my $fid = "[frame_srv_start]";
	my $ffid = "SERVICE|START";
    my $srvdb = frame_db_obj_get("service");
    my $config = frame_db_obj_get("config");
    my $return;

    # check for valid service
    if(index_find($srvdb->{'index'}, $req->{'srv'}{'id'})){
        # service found
        my $service = $req->{'srv'}{'id'};
    
        # check service state
        if(!$srvdb->{$service}{'state'}){
			$return = packet_build_noencode("1", "success: starting service", $fid);
			$return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
			
			my $srvdata = frame_srv_conf_get($service);
			
			log_info_json($ffid, "service start requested", $srvdata);
			
			# spawn process
			#my $exec = "cd " . $srvdata->{'path'} . "; " . $srvdata->{'exec'} . " > " . $srvdata->{'log'} . " 2>&1 &";
			my $exec = "cd " . $srvdata->{'path'} . "; " . $srvdata->{'exec'} . " &";
			my $pid = forker($exec);
			
			if($pid){
				
				# init
				$srvdb->{$service}{'state'} = 1;
				$srvdb->{$service}{'status'} = "running";
				$srvdb->{$service}{'date'} = date_get();
				$srvdb->{$service}{'pid'} = $pid;
				frame_db_obj_set("service", $srvdb);
				
				log_info_json($ffid, "service [$service] spawned successfully", $srvdb->{$service});
			}
			else{
				# service failed to spawn
				log_warn($ffid, "service [$service] failed to spawn!");
				$return = packet_build_noencode("0", "failed: service failed to spawn", $fid);
				$return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
			}
		}
		else{
			# service already running
			log_warn($ffid, "service [$service] is already running!");
			$return = packet_build_noencode("0", "failed: service is already running", $fid);
			$return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
		}
		
    }
    else{
        # unknown service
        log_warn($ffid, "unknown service [$req->{'srv'}{'id'}]");
        $return = packet_build_noencode("0", "failed: unknown service [$req->{'srv'}{'id'}]", $fid);
    }

    return json_encode($return);
}

#
# stop service [JSON-STR]
#
sub frame_srv_stop($req){
    my $fid = "[frame_srv_stop]";
	my $ffid = "SERVICE|STOP";
    my $srvdb = frame_db_obj_get("service");
    my $return;

    # check for valid service
    if(index_find($srvdb->{'index'}, $req->{'srv'}{'id'})){
        # service found
        my $service = $req->{'srv'}{'id'};
        
        # check service state
        if($srvdb->{$service}{'state'}){
			$return = packet_build_noencode("1", "success: stopping service", $fid);
			$return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
			
			my $srvdata = frame_srv_conf_get($service);
			
			if($srvdb->{$service}{'pid'}){
				# pid registered
				
				my $result = killer($srvdb->{$service}{'pid'});
				
				if(!$result){
					$srvdb->{$service}{'state'} = 0;
					$srvdb->{$service}{'status'} = "stopped";
					$srvdb->{$service}{'date'} = date_get();
					$srvdb->{$service}{'pid'} = "";
					frame_db_obj_set("service", $srvdb);
				}
				else{
					# failed to kill pid
					log_error($ffid, "service [$service] kill returned [$result]");
					$return = packet_build_noencode("0", "error: killer returned [" . $result . "]", $fid);
					$return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
				}
			}
			else{
				# no pid registered
				log_warn($ffid, "service [$service] pid is missing!");
				$return = packet_build_noencode("0", "failed: service pid is missing", $fid);
				$return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
			}
		}
		else{
			# service not running
			log_warn($ffid, "service [$req->{'srv'}{'id'}] is not running");
			$return = packet_build_noencode("0", "failed: service is not running", $fid);
			$return->{'srvdata'} = $srvdb->{$req->{'srv'}{'id'}};
		}
    }
    else{
        # unknown service
		log_warn($ffid, "unknown service [$req->{'srv'}{'id'}]");
        $return = packet_build_noencode("0", "failed: unknown service", $fid);
    }

    return json_encode($return);
}

#
# restart service [JSON-STR]
#
sub frame_srv_restart($req){
    my $fid = "[frame_srv_restart]";
	my $ffid = "SERVICE|RESTART";
    my $srvdb = frame_db_obj_get("service");
    my $return;

	$return = packet_build_noencode("1", "restarting service [$req->{'srv'}{'id'}]", $fid);
	
	log_info($ffid, "stopping service [$req->{'srv'}{'id'}]");
	$return->{'srvstop'} = json_decode(frame_srv_stop($req));
	
	sleep 2;
	log_info($ffid, "stopping service [$req->{'srv'}{'id'}]");
	$return->{'srvstart'} = json_decode(frame_srv_start($req));
	
	return json_encode($return);    
}

#
# clear logfile for service [JSON-STR]
#
sub frame_srv_log_clear($req){
    my $fid = "[frame_srv_log_clear]";
	my $ffid = "SERVICE|LOG|CLEAR";
    my $srvdb = frame_db_obj_get("service");
    my $return;

	$return = packet_build_noencode("1", "clearing logs for service [$req->{'srv'}{'id'}]", $fid);
	
	# get service config
	my $srvdata = frame_srv_conf_get($req->{'srv'}{'id'});
			
	log_info_json($ffid, "service log clear requested", $srvdata);
			
	# clear logs
	my $exec = 'echo "" > ' . $srvdata->{'log'};
	my $result = forker($exec);

	return json_encode($return);   
}

#
# clear service state [JSON-STR]
#
sub frame_srv_clear_state($req){
    my $fid = "[frame_srv_clear_state]";
	my $ffid = "SERVICE|CLEAR";
    my $srvdb = frame_db_obj_get("service");
    
    my $return;

	# check for valid service
    if(index_find($srvdb->{'index'}, $req->{'srv'}{'id'})){
        # service found
        my $service = $req->{'srv'}{'id'};
        my $srvcfg = frame_srv_conf_get($service);
        
        # check service state
        if($srvdb->{$service}{'state'}){
			# unknown service
			$return = packet_build_noencode("0", "failed: service is running", $fid);	
		}
		else{
			# get service config 
			log_info_json($ffid, "service details", $srvcfg);
			
			if(defined $srvcfg->{'state'}){
				my $statefile = $srvcfg->{'path'} . $srvcfg->{'state'};
				
				# check for statefile
				if(file_check($statefile)){
					log_info($ffid, "service state file [$statefile] is present. removing...");
					
					my $del_result = file_del($statefile);
					log_debug($ffid, "removed state file with result [$del_result]");
					
					if($del_result){
						# failed to remove state file
						log_warn($ffid, "failed to remove statefile [$statefile]!");
						$return = packet_build_noencode("0", "error: failed to remove statefile!", $fid);
					}
					else{
						# successfully removed state file
						log_info($ffid, "statefile [$statefile] remove successfully");
						$return = packet_build_noencode("1", "success: statefile removed successfully", $fid);
					}
				}
				else{
					# state file not present
					log_warn($ffid, "statefile [$statefile] not present!");
					$return = packet_build_noencode("0", "failed: service statefile not present", $fid);
				}
			}
			else{
				# service has no state file
				log_warn($ffid, "service has no statefile");
				$return = packet_build_noencode("0", "failed: service does not use statefile", $fid);
			}			
		}		
	}
	else{
		  # unknown service
        $return = packet_build_noencode("0", "failed: unknown service", $fid);
	}

	return json_encode($return);
}

1;
