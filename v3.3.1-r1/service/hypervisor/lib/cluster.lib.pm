#
# ETHER|AAPEN|HYPERVISOR - LIB|CLUSTER
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
# sync cluster system [NONE]
#
sub cluster_node_sync(){
	my $fid = "[cluster_node_sync]";
	my $ffid = "CLUSTER|SYNC|NODE";

	log_info($ffid, "getting cluster metadata...");
	my $metadata = api_loc_cluster_meta_get();

	if($metadata->{'proto'}{'result'}){
	
		# build index
		my @remote_index = index_split($metadata->{'meta'}{'node'}{'index'});
		
		foreach my $node (@remote_index){
			my $nodedata = api_loc_cluster_obj_get("node", $node);
			
			if($nodedata->{'proto'}{'result'} eq "1"){
				
				if((defined $nodedata->{'node'}{'id'}{'id'}) && (defined $nodedata->{'node'}{'id'}{'name'})){
					log_info($ffid, "processing node id [$nodedata->{'node'}{'id'}{'id'}] name [$nodedata->{'node'}{'id'}{'name'}]");
				}
				else{
					log_warn_json($ffid, "warning: node id [$nodedata->{'node'}{'id'}{'id'}] name [$nodedata->{'node'}{'id'}{'name'}] dataset contains invalid data!", $nodedata->{'node'});
				}
			}
			else{
				log_warn($ffid, "warning: failed to process node id [$nodedata->{'node'}{'id'}{'id'}] name [$nodedata->{'node'}{'id'}{'name'}]");
			}
		}
	}
}

# rename cdb to SYNC: TODO

#
# push system to cluster database [NULL]
#
sub hyper_cdb_system_sync($vmdata){
	my $fid = "[hyper_cdb_system_sync]";
	my $ffid = "CLUSTER|SYNC|SYSTEM";
	my $result = api_cluster_local_system_set(env_serv_sock_get("cluster"), $vmdata);
}

#
# sync with cluster database [NULL]
#
sub hyper_cdb_sync(){
	my $fid = "[hyper_cdb_sync]";
	my $ffid = "CLUSTER|SYNC";
	my $state = hyper_info();
	my $meta = json_decode($state);
	$meta->{'updated'} = date_get();
	$meta->{'config'}{'service'} = "hypervisor";

	log_info($ffid, "id [$meta->{'config'}{'id'}] name [$meta->{'config'}{'name'}] - cpu idle [$meta->{'hw'}{'stats'}{'cpu'}{'idle'}%] - sys [$meta->{'hyper'}{'systems'}] cpualloc [$meta->{'hyper'}{'cpualloc'}] memalloc [$meta->{'hyper'}{'memalloc'}MB]");
	
	api_cluster_local_service_set(env_serv_sock_get("cluster"), $meta);
}

#
# get system stats
#
sub hyper_system_stats(){
	my $fid = "[hyper_system_stats]";
	my $ffid = "HYPER|SYSTEM|STATS";
	my $hyperdb = hyper_db_obj_get("hyper");
	my @system_index = index_split($hyperdb->{'vm'}{'lock'});

	# clear stats
	$hyperdb->{'vm'}{'systems'} = 0;
	$hyperdb->{'vm'}{'cpualloc'} = 0;
	$hyperdb->{'vm'}{'memalloc'} = 0;
	
	#log_info($ffid, "processing system stats");
	
	#
	# process system index
	#
	foreach my $system (@system_index){	
		$hyperdb = hyper_system_stats_sys($system, $hyperdb);
		$hyperdb->{'vm'}{'systems'}++;
	}
	
	# commit database
	hyper_db_obj_set("hyper", $hyperdb);	
}

#
# Collect detailed statistics for a single system
#
sub hyper_system_stats_sys($system, $hyperdb) {
    my $fid = "[hyper_system_stats_sys]";
	my $ffid = "HYPER|SYSTEM|STATS";
    
    unless (defined $system) {
        log_warn($ffid, "error: missing system parameter");
        return;
    }

    unless (exists $hyperdb->{'db'}{$system} && 
            exists $hyperdb->{'db'}{$system}{'meta'}{'pid'} &&
            looks_like_number($hyperdb->{'db'}{$system}{'meta'}{'pid'})) {
        log_warn($ffid, "warning: Invalid system or PID for [$system]");
        return;
    }

    my $pid = $hyperdb->{'db'}{$system}{'meta'}{'pid'};
    my $stats = {
        'pid'     => $pid,
        'updated' => date_get(),
        'date'    => date_get()
    };

    # Collect process stats with error handling
    eval {
		$stats->{'cpu'} = process_stats_cpu($pid);
		$stats->{'mem'} = process_stats_mem($pid);
 		$stats->{'rss'} = process_stats_rss($pid);
        1;
    } or do {
        log_warn($ffid, "error collecting process stats: [$@]");
        $stats->{'cpu'} = $stats->{'mem'} = $stats->{'rss'} = "error";
    };

    # Get uptime if available
    if (exists $hyperdb->{'db'}{$system}{'meta'}{'vmm'}{'date'}) {
        $stats->{'uptime'} = date_str_uptime_short($hyperdb->{'db'}{$system}{'meta'}{'vmm'}{'date'});
    }

    # Get disk stats
    $stats->{'disk'} = hyper_system_disk_stats($hyperdb->{'db'}{$system});

    # Check for async jobs
    if (exists $hyperdb->{'vm'}{'async'}{$hyperdb->{'db'}{$system}{'id'}{'id'}}) {
        $stats->{'async'} = $hyperdb->{'vm'}{'async'}{$hyperdb->{'db'}{$system}{'id'}{'id'}};
    }

    # update stats
    $hyperdb->{'stats'}{$system} = $stats;
    $hyperdb->{'stats'}{$system}{'id'} = $hyperdb->{'db'}{$system}{'id'};
    $hyperdb->{'stats'}{$system}{'boot'} = $hyperdb->{'db'}{$system}{'meta'}{'vmm'}{'date'};

	# update resource counters
	$hyperdb->{'vm'}{'cpualloc'} += $hyperdb->{'db'}{$system}{'hw'}{'cpu'}{'core'};
	$hyperdb->{'vm'}{'memalloc'} += $hyperdb->{'db'}{$system}{'hw'}{'mem'}{'mb'};

	log_info($ffid, "vm [$stats->{'id'}{'id'}] name [$stats->{'id'}{'name'}] pid [$stats->{'pid'}] cpu [$stats->{'cpu'}%] mem [$stats->{'rss'}] async [$stats->{'async'}{'active'}]");

	# push to cluster
    hyper_system_cdb_meta_set($stats->{'id'}{'name'}, $stats);

	# return hyperdb
    return $hyperdb;
}

#
# system disk stats [JSON-OBJ]
#
sub hyper_system_disk_stats($system){
	my $fid = "[hyper_system_disk_stats]";
	my $ffid = "HYPER|SYSTEM|STATS|DISK";
	my $diskstat;
	
	log_debug($ffid, "disk index [$system->{'stor'}{'disk'}]");
	my @disks = index_split($system->{'stor'}{'disk'});
	
	foreach my $disk (@disks){
		my $file = $system->{'stor'}{$disk}{'dev'} . $system->{'stor'}{$disk}{'image'};
		my $size = format_bytes(-s $file);		
		log_debug($ffid, "disk [$disk size [$size]");
		$diskstat->{$disk}{'size'} = $size;
	}
	
	return $diskstat;
}

#
# set system metadata [NULL]
#
sub hyper_system_cdb_meta_set($system, $meta){
	my $fid = "[hyper_system_cdb_meta_set]";
	my $ffid = "HYPER|SYSTEM|META|SET";
	
	my $packet;
	$packet->{'cluster'}{'obj'} = "system";
	$packet->{'cluster'}{'key'} = $system;
	$packet->{'cluster'}{'id'} = "hypervisor";
	$packet->{'data'} = $meta;
	
	api_cluster_local_obj_meta_set(env_serv_sock_get("cluster"), $packet);
}

#
# TODO
#
sub hyper_stats_io(){
	my $fid = "[hyper_stats_io]";
	my $exec = 'iostat';
	my $top = {};
	my @line;
	
	my $result = `$exec`;
	my @top = split /\n/, $result;
	@line = split /\s+/, $top[0];
}

1;
