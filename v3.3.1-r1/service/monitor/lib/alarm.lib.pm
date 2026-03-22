#
# ETHER|AAPEN|MONITOR - LIB|ALARM
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

my $alarmdb = {};

#
# set alarm [NULL]
#
sub alarm_set($object, $name, $state, $status){
	my $fid = "[alarm_set]";
	
	my $alarm = monitor_db_obj_get("alarm");

	# alarm index for an object
	if(defined $alarm->{$object}{$name}{'index'}){
		# an alarm index exists
		print "$fid previous alarms exist for [$object] name [$name]: [$alarm->{$object}{$name}{'index'}]\n";
		
		if($alarm->{$object}{$name}{'alarm'}){
			# alarm is active
			print "$fid alarm for [$object] name [$name]: [$alarm->{$object}{$name}{'index'}] is active\n";
			my $alarm_id = $alarm->{$object}{$name}{'alarm_id'};
			
			# update alarm
			$alarm->{$object}{$name}{$alarm_id} = alarm_update($alarm->{$object}{$name}{$alarm_id}, $state, $status, 1);
		}
		else{
			# add new alarm to index
			my $alarm_id = index_free($alarm->{$object}{$name}{'index'}, 0);
			
			$alarm->{$object}{$name}{'alarm_id'} = $alarm_id;
			$alarm->{$object}{$name}{'alarm'} = 1;
			
			# index
			$alarm->{$object}{$name}{'index'} = index_add($alarm->{$object}{$name}{'index'}, $alarm_id);
			$alarm->{$object}{$name}{'index'} = index_add($alarm->{$object}{$name}{'index'}, $alarm_id);
			$alarm->{$object}{'index'} = index_add($alarm->{$object}{'index'}, $name);
			$alarm->{'index'} = index_add($alarm->{'index'}, $object);
			
			print "$fid alarm for [$object] name [$name]: [$alarm->{$object}{$name}{'index'}] is not active. adding alarm id [$alarm_id]\n";
			
			# update alarm
			$alarm->{$object}{$name}{$alarm_id} = alarm_update($alarm->{$object}{$name}{$alarm_id}, $state, $status, 1);
			
			# generate SMS
			#if(monitor_is_master() && !env_maintenance() && $conf->{'sms'}{'enabled'} eq "1"){
			#	print "$fid --- MONITOR IS MASTER SENDING ALERT SMS ---\n";
			#	my $msg = "ALARM: mon [$conf->{'name'}] obj [$object] name [$name] alarm id [$alarm_id]: state [$alarm->{$object}{$name}{$alarm_id}{'state'}] status [$alarm->{$object}{$name}{$alarm_id}{'status'}]";
			#	if(env_debug()){ print "$fid MSG: [$msg]\n"; };
			#	api_mt_send_sms($conf->{'sms'}, $msg);
			#}
		}

	}
	else{
		# alarm index does not exist
		print "$fid no previous alarms for [$object] name [$name] adding..\n";
		my $alarm_id = 0;
		
		# add new alarm to index
		$alarm->{$object}{$name}{'index'} = index_add($alarm->{$object}{$name}{'index'}, $alarm_id);
		$alarm->{$object}{$name}{'alarm_id'} = $alarm_id;
		$alarm->{$object}{$name}{'alarm'} = 1;
		
		# index
		$alarm->{$object}{$name}{'index'} = index_add($alarm->{$object}{$name}{'index'}, $alarm_id);
		$alarm->{$object}{$name}{'index'} = index_add($alarm->{$object}{$name}{'index'}, $alarm_id);
		$alarm->{$object}{'index'} = index_add($alarm->{$object}{'index'}, $name);
		$alarm->{'index'} = index_add($alarm->{'index'}, $object);
		
		# update alarm
		$alarm->{$object}{$name}{$alarm_id} = alarm_update($alarm->{$object}{$name}{0}, $state, $status, 1);
		
		# generate SMS
		#if(monitor_is_master() && !env_maintenance() && $conf->{'sms'}{'enabled'} eq "1"){
		#	print "$fid --- MONITOR IS MASTER SENDING ALERT SMS ---\n";
		#	my $msg = "ALARM: mon [$conf->{'name'}] obj [$object] name [$name]  alarm id [$alarm_id]: state [$alarm->{$object}{$name}{$alarm_id}{'state'}] status [$alarm->{$object}{$name}{$alarm_id}{'status'}]";
		#	if(env_debug()){ print "$fid MSG: [$msg]\n"; };
		#	api_mt_send_sms($conf->{'sms'}, $msg);
		#}
	}
	
	monitor_db_obj_set("alarm", $alarm);
	#json_encode_pretty($alarm);
}

#
# unset alarm [NULL]
#
sub alarm_unset($object, $name){
	my $fid = "[alarm_unset]";
	
	my $alarm = monitor_db_obj_get("alarm");

	# alarm index for an object
	if(defined $alarm->{$object}{$name}){
		if(defined $alarm->{$object}{$name}{'alarm'} && $alarm->{$object}{$name}{'alarm'}){
			# an alarm index exists
			print "$fid previous alarms exist for [$object] name [$name]: [$alarm->{$object}{$name}{'index'}]\n";
			
			# check for active alarm
			if($alarm->{$object}{$name}{'alarm'}){
				# alarm is active
				print "$fid alarm for [$object] name [$name]: [$alarm->{$object}{$name}{'index'}] is active - clearing\n";
				my $alarm_id = $alarm->{$object}{$name}{'alarm_id'};
				$alarm->{$object}{$name}{'alarm'} = 0;
				
				# update alarm
				$alarm->{$object}{$name}{$alarm_id} = alarm_update($alarm->{$object}{$name}{$alarm_id}, $alarm->{$object}{$name}{$alarm_id}{'state'}, $alarm->{$object}{$name}{$alarm_id}{'status'}, 0);
				
				#if(monitor_is_master() && !env_maintenance() && $conf->{'sms'}{'enabled'} eq "1"){
				#	print "$fid --- MONITOR IS MASTER SENDING ALARM CLEARED SMS ---\n";
				#	my $msg = "ALARM CLEARED: mon [$conf->{'name'}] obj [$object] name [$name] alarm id [$alarm_id]: state [$alarm->{$object}{$name}{$alarm_id}{'state'}] status [$alarm->{$object}{$name}{$alarm_id}{'status'}] - timer [$alarm->{$object}{$name}{$alarm_id}{'timer'}]";
				#	if(env_debug()){ print "$fid MSG: [$msg]\n"; };
				#	api_mt_send_sms($conf->{'sms'}, $msg);
				#}
				
				#db_obj_set("alarm", $alarm);
				monitor_db_obj_set("alarm", $alarm);
				json_encode_pretty($alarm);
			}
		}
	}
}

#
# update alarm [JSON-OBJ]
#
sub alarm_update($alarm, $state, $status, $active){
	
	# check if new alarm
	if(!defined $alarm->{'date'}){
		# alarm does not exist
		$alarm->{'active'} = $active;
		$alarm->{'date'} = date_get();
		$alarm->{'state'} = $state;
		$alarm->{'status'} = $status;
		$alarm->{'triggered'} = date_get();
		$alarm->{'events'} = 1;
		$alarm->{'timer'} = 0;
		$alarm->{'alarm'} = 1;
	}
	else{
		# alarm exists
		$alarm->{'active'} = $active;
		$alarm->{'date'} = date_get();
		$alarm->{'state'} = $state;
		$alarm->{'status'} = $status;
		$alarm->{'events'}++;
		$alarm->{'timer'} = date_str_diff_now($alarm->{'triggered'});
		
		# check if alarm is being cleared
		if(!$active){
			# alarm is active
			$alarm->{'cleared'} = date_get();
			$alarm->{'alarm'} = 0;
			$alarm->{'timer'} = date_str_diff_now($alarm->{'triggered'});
		}
	}

	return $alarm;
}

#
# return alarm db [JSON-STR]
#
sub alarm_db_get($request){
	my $fid = "[alarm_get]";
	my $alarm = monitor_db_obj_get("alarm");
	
	print "$fid alarmdb\n";
	json_encode_pretty($alarm);
	
	my $result = packet_build_noencode("1", "success: reuturning alarm database", $fid);
	$result->{'alarm'} = $alarm;
	
	return json_encode($result);
}

1;
