#
# ETHER - AAPEN - STORAGE - DEVICE LIB
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
# gather device stats [NULL]
#
sub device_stats(){
	my $fid = "[device_stats]";
	my $ffid = "DEVICE|STATS";
	my $devdb = storage_db_obj_get("device");
	my @dev_index = index_split($devdb->{'index'});
	
	#
	# process remote index
	#
	foreach my $device (@dev_index){
		log_info($ffid, "device [$device] type [" . $devdb->{'data'}{$device}{'object'}{'class'} . "] model [" . $devdb->{'data'}{$device}{'object'}{'type'} . "]");

		if($devdb->{'data'}{$device}{'object'}{'model'} eq "device"){
			
			#
			# disk
			#
			if($devdb->{'data'}{$device}{'object'}{'class'} eq "disk"){
				$devdb->{'data'}{$device}{'meta'}{'size'} = dev_size_info($devdb->{'data'}{$device}{'device'}{'mount'});
				
				if($devdb->{'data'}{$device}{'device'}{'smart_check'} eq "1"){
					$devdb->{'data'}{$device}{'meta'}{'smart'} = dev_smart_info($devdb->{'data'}{$device}{'device'}{'dev'});
					$devdb->{'data'}{$device}{'meta'}{'smart'}{'date'} = date_get();
					$devdb->{'data'}{$device}{'meta'}{'iostat'} = dev_iostat($devdb->{'data'}{$device}{'device'}{'part'});
					$devdb->{'data'}{$device} = dev_health($devdb->{'data'}{$device});
				}
			}
			
			#
			# mdraid
			#
			if($devdb->{'data'}{$device}{'object'}{'class'} eq "mdraid"){
				$devdb->{'data'}{$device}{'meta'}{'size'} = dev_size_info($devdb->{'data'}{$device}{'mdraid'}{'mount'});
				$devdb->{'data'}{$device} = mdraid_stats($devdb->{'data'}{$device});
				$devdb->{'data'}{$device} = mdraid_health($devdb->{'data'}{$device});
			}
			
			#
			# nvme
			#
			if($devdb->{'data'}{$device}{'object'}{'class'} eq "nvme"){
				$devdb->{'data'}{$device}{'meta'}{'size'} = dev_size_info($devdb->{'data'}{$device}{'device'}{'mount'});
				$devdb->{'data'}{$device}{'meta'}{'iostat'} = dev_iostat($devdb->{'data'}{$device}{'device'}{'part'});
				$devdb->{'data'}{$device}{'meta'}{'smart'} = nvme_smart_info($devdb->{'data'}{$device}{'device'}{'dev'});
				$devdb->{'data'}{$device}{'meta'}{'nvme'}{'info'} = nvme_info($devdb->{'data'}{$device});
				$devdb->{'data'}{$device}{'meta'}{'nvme'}{'health'} = nvme_stats($devdb->{'data'}{$device});
				$devdb->{'data'}{$device} = nvme_health($devdb->{'data'}{$device});
				json_encode_pretty($devdb->{'data'}{$device});
			}
			
			#
			# publish
			#
			$devdb->{'data'}{$device}{'meta'}{'date'} = date_get();
			$devdb->{'data'}{$device}{'meta'}{'state'} = "1";
			
			log_info($ffid, "device [$device] updated");
			storage_db_obj_set("device", $devdb);
		}
	}
}

#
# device size info [JSON-OBJ]
#
sub dev_size_info($mount){
	my $fid = "[dev_size_info]";
	my $size = {};
	
	my $ref = df($mount);  # 1K blocks
	
	if(defined($ref)) {	
		$size->{'total'}{'gb'} = conv_kb_mb(conv_kb_mb($ref->{blocks}));
		$size->{'free'}{'gb'} = conv_kb_mb(conv_kb_mb($ref->{bfree}));
		$size->{'used'}{'gb'} = conv_kb_mb(conv_kb_mb($ref->{used}));
		$size->{'avail'}{'gb'} = conv_kb_mb(conv_kb_mb($ref->{bavail}));

		# inodes
		if(exists($ref->{files})) {
			$size->{'inode'}{'tot'} = $ref->{files};
			$size->{'inode'}{'free'} = $ref->{ffree};
			$size->{'inode'}{'perc'} = $ref->{fper};
		}
	}
	
	if(env_debug()){ 
		log_debug($fid, "size info for mount [$mount]");
		json_encode_pretty($size);
	};
	
	return $size;
}

#
# get iostat
#
sub dev_iostat($dev){
	my $fid = "[dev_iostat]";
	my $ffid = "DEVICE|IOSTAT";
	my $stats = {};
	
	my $exec = 'iostat -o JSON -p ' . $dev;
	my $result = `$exec`;
	my $iostat = json_decode($result);
	
	$stats->{'device'} = $iostat->{'sysstat'}{'hosts'}[0]{'statistics'}[0]{'disk'}[0]{'disk_device'};
	$stats->{'kb_read_tot'} = $iostat->{'sysstat'}{'hosts'}[0]{'statistics'}[0]{'disk'}[0]{'kB_read'};
	$stats->{'kb_write_tot'} = $iostat->{'sysstat'}{'hosts'}[0]{'statistics'}[0]{'disk'}[0]{'kB_wrtn'};
	$stats->{'kb_read_sec'} = $iostat->{'sysstat'}{'hosts'}[0]{'statistics'}[0]{'disk'}[0]{'kB_read/s'};
	$stats->{'kb_write_sec'} = $iostat->{'sysstat'}{'hosts'}[0]{'statistics'}[0]{'disk'}[0]{'kB_wrtn/s'};

	return $stats;
}

#
# convert Kb to Mb [INT]
#
sub conv_kb_mb($kb){
	return $kb >> 10;	
}
#
# convert Mb to Gb [INT]
#
sub conv_mb_gb($mb){
	return $mb >> 10;	
}

#
# get device smart info [JSON-OBJ]
#
sub dev_smart_info($dev){
	my $fid = "[dev_smart_info]";
	my $ffid = "DEVICE|SMART|INFO";

	my $exec = 'smartctl -a -j ' . $dev;	
	my $smart_json = `$exec`;

	my $stats = {};
	$stats->{'date'} = date_get();
	
	my $smart = json_decode($smart_json);

	# device
	$stats->{'speed'}{'max'} = $smart->{'interface_speed'}{'max'}{'string'};
	$stats->{'speed'}{'current'} = $smart->{'interface_speed'}{'current'}{'string'};
	$stats->{'firmware'} = $smart->{'firmware_version'};
	$stats->{'form_factor'} = $smart->{'form_factor'}{'name'};
	$stats->{'model_name'} = $smart->{'model_name'};

	# power
	$stats->{'power_cycles'} = $smart->{'power_cycle_count'};
	$stats->{'power_on_hours'} = $smart->{'power_on_time'}{'hours'};
	
	# temp
	$stats->{'temperature'} = $smart->{'temperature'}{'current'};
	
	# smart test
	if($smart->{'smart_status'}{'passed'}){
		$stats->{'smart_passed'} = "true";
	}
	else{
		$stats->{'smart_passed'} = "false";
	}

	# sct
	if($smart->{'ata_sct_capabilities'}{'error_recovery_control_supported'}){
		$stats->{'sct_support'} = "true";
	}
	else{
		$stats->{'sct_support'} = "false";
	}

	# self test
	if($smart->{'ata_smart_data'}{'self_test'}{'status'}{'passed'}){
		$stats->{'self_test_passed'} = "true";
	}
	else{
		$stats->{'self_test_passed'} = "false";
	}

	return $stats;
}

#
# get iostat
#
sub dev_health($device){
	my $fid = "[dev_health]";
	my $ffid = "DEVICE|HEALTH";
	my $stats = {};
	my $healthy = 1;
	my $dev = $device->{'device'}{'dev'};
	my $warning = "";
	
	log_info($ffid, "checking device [$dev] health");

	$device->{'meta'}{'health'}{'temperature'} = "NORMAL";
	$device->{'meta'}{'health'}{'smart'} = "HEALTHY";
	$device->{'meta'}{'health'}{'device'} = "HEALTHY";
	
	if($device->{'meta'}{'smart'}{'self_test_passed'} ne "true"){
		log_warn($ffid, "WARNING: DISK [$dev] SELF TEST FAILED");
		$device->{'meta'}{'health'}{'device'} = "ERROR";
		$warning = "SELF TEST FAILED";
		
		$device->{'meta'}{'health'}{'device'} = "ERROR";
		$healthy = 0;
	}
	
	if($device->{'meta'}{'smart'}{'smart_passed'} ne "true"){
		log_warn($ffid, "WARNING: DISK [$dev] SMART TEST FAILED");
		$device->{'meta'}{'health'}{'smart'} = "ERROR";
		$warning = "SMART TEST FAILED";
		
		$device->{'meta'}{'health'}{'smart'} = "ERROR";
		$healthy = 0;
	}
	
	if((defined $device->{'meta'}{'smart'}{'temperature'}) && ($device->{'meta'}{'smart'}{'temperature'} > 45)){
		log_warn($ffid, "WARNING: DISK [$dev] TEMPERATURE [$device->{'meta'}{'smart'}{'temperature'}] HIGH!");
		$warning = "TEMP HIGH [$device->{'meta'}{'smart'}{'temperature'}]";
		$device->{'meta'}{'health'}{'temperature'} = "HIGH [$device->{'meta'}{'smart'}{'temperature'}]";
		$healthy = 0;
	}
	
	
	if($healthy){
		log_info($ffid, "device [$dev] is healthy");
		$device->{'meta'}{'status'} = "HEALTHY";
		$device->{'meta'}{'warning'} = "";
		
		$device->{'meta'}{'health'}{'status'} = "HEALTHY";
		$device->{'meta'}{'health'}{'warning'} = "";
	}
	else{
		log_info($ffid, "device [$dev] has warnings!");
		$device->{'meta'}{'status'} = "WARNING";
		$device->{'meta'}{'warning'} = $warning;
		
		$device->{'meta'}{'health'}{'status'} = "WARNING";
		$device->{'meta'}{'health'}{'warning'} = $warning;
	}
	
	return $device;
}

1;
