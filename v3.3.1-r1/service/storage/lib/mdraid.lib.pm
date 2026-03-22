#
# ETHER - AAPEN - STORAGE - MDRAID LIB
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
# get mdraid stats [JSON-OBJ]
#
sub mdraid_stats($device){
	my $fid = "[mdraid_stats]";
	my $ffid = "MDRAID|STATS";
	
	my @dev_index = index_split($device->{'mdraid'}{'devices'});
	
	foreach my $dev (@dev_index){
        log_info($ffid, "device [$dev] dev [$device->{'mdraid'}{$dev}{'dev'}]");
		
		if($device->{'mdraid'}{'smart_check'} eq "1" || !$device->{'meta'}{'mdraid'}{'smart_init'}){
			$device->{'meta'}{'smart'}{$dev} = dev_smart_info($device->{'mdraid'}{$dev}{'dev'});
			$device->{'meta'}{'smart'}{$dev}{'date'} = date_get();
		}
	}
	
	$device->{'meta'}{'mdraid'} = mdraid_info($device->{'mdraid'}{'node'});
	$device->{'meta'}{'mdraid'}{'date'} = date_get();
	$device->{'meta'}{'mdraid'}{'smart_init'} = 1;
	
	$device->{'meta'}{'iostat'} = dev_iostat($device->{'mdraid'}{'dev'});
	
	$device->{'meta'}{'date'} = date_get();
	
    # TODO: fix status and state flag 
    $device->{'meta'}{'state'} = "1";
	$device->{'meta'}{'status'} = "healthy";
	
	#json_encode_pretty($device);
	return $device;
}

#
# get mdraid info [JSON-OBJ]
#
sub mdraid_info($node) {
    my $fid = "[mdraid_info]";
    my $ffid = "MDRAID|INFO";
    my $stats = {};
    my $max_retries = 3;
    my $retry_delay = 1; # seconds
    
    # Validate input format
    unless (defined $node && $node =~ /^md\d+$/) {
        log_warn($ffid, "invalid node parameter [$node]");
        return $stats;
    }
	
    # Try with retries and timeout
    my $attempt = 0;
    my @text;
    my $success = 0;
    
    while ($attempt < $max_retries && !$success) {
        $attempt++;
        
        eval {
            # Set alarm for timeout
            local $SIG{ALRM} = sub { die "Timeout reading /proc/mdstat\n" };
            alarm(5); # 5 second timeout
            
            if (open(my $mdstat, "<", "/proc/mdstat")) {
                @text = <$mdstat>;
                close($mdstat);
                $success = 1;
            } else {
                die "Failed to open /proc/mdstat: $!\n";
            }
            
            alarm(0); # Disable alarm if we got here
        };
        
        if ($@) {
            warn "$fid Attempt $attempt failed: $@";
            if ($attempt < $max_retries) {
                sleep $retry_delay;
                $retry_delay *= 2; # Exponential backoff
            }
        }
    }
    
    unless ($success) {
        log_warn($ffid, "failed to read [/proc/mdstat] after [$max_retries] attempts");
        return $stats;
    }
	 
    # Analyze with improved structure and error handling
    eval {
        while (my $line = shift @text) {
            next unless $line =~ /$node/;
            
            # Parse array info line
            chomp($line);
            my @array = split(/\s+/, $line);
            
            unless (@array >= 4) {
                die "Invalid array info line format - expected at least 4 fields\n";
            }
            
            # Extract array metadata using named positions
            $stats->{$node} = {
                mddev => $array[0],
                state => $array[2],
                raid  => $array[3],
                devices => {
                    map { 
                        $_ => $array[$_ + 4] 
                    } (0..$#array - 4)
                }
            };
            
            # Add device indexes
            $stats->{$node}{'devices'}{'index'} = "";
            my $device_count = scalar(@array) - 4; # First 4 fields are metadata
            for my $idx (0..$device_count-1) {
                $stats->{$node}{'devices'}{'index'} = index_add($stats->{$node}{'devices'}{'index'}, $idx);
            }
            
            # Parse device state line
            unless (@text) {
                die "Missing device state line after array info\n";
            }
            
            my $state_line = shift @text;
            chomp($state_line);
            my @state = split(/\s+/, $state_line);
            
            unless (@state >= 13) {
                die "Invalid device state line - expected at least 13 fields\n";
            }
            
            # Extract state information
            $stats->{$node}{'disk_online'} = $state[11];
            $stats->{$node}{'disk_status'} = $state[12];
            
            last; # Found our array, no need to continue
        }
        
        unless (exists $stats->{$node}) {
            die "No matching RAID array found for $node in /proc/mdstat\n";
        }
    };
    
    if ($@) {
        warn "$fid Error parsing mdstat: $@";
        return $stats;
    }
	
	if(env_debug()){
		print "$fid mdraid stats\n";
		json_encode_pretty($stats);
	}
	
	return $stats;
}

#
# process mdraid health [JSON-OBJ]
#
sub mdraid_health($device) {
    my $fid = "[mdraid_health]";
    
    # Validate input
    unless (defined $device && ref($device) eq 'HASH' &&
            exists $device->{'mdraid'} && exists $device->{'mdraid'}{'node'}) {
        warn "$fid Error: Invalid device parameter\n";
        return $device;
    }

    my $dev = $device->{'mdraid'}{'node'};
    my $healthy = 1;
    my @warnings;
    
    # Threshold configuration
    my $thresholds = {
        temp_warn      => 45,    # °C
        temp_critical  => 70,    # °C
        degraded_state => 0      # Allow degraded state (0 = no)
    };

    if (env_debug()) {
        print "[" . date_get() . "] $fid Checking health for RAID [$dev]\n";
        print "$fid Using thresholds:\n";
        json_encode_pretty($thresholds);
    }

    # Initialize health status
    $device->{'meta'}{'health'} = {
        temperature => "NORMAL",
        smart       => "HEALTHY",
        device      => "HEALTHY",
        status      => "HEALTHY",
        warning     => ""
    };

    # Check array state
    unless (exists $device->{'meta'}{'mdraid'}{$dev}{'state'}) {
        warn "$fid Error: Missing array state for $dev\n";
        return $device;
    }

    if ($device->{'meta'}{'mdraid'}{$dev}{'state'} ne "active") {
        my $msg = "Array state: $device->{'meta'}{'mdraid'}{$dev}{'state'}";
        push @warnings, $msg;
        $healthy = 0;
        print "[" . date_get() . "] $fid WARNING: $msg\n";
    }

    # Check disk status
    if (exists $device->{'meta'}{'mdraid'}{$dev}{'disk_status'}) {
        if ($device->{'meta'}{'mdraid'}{$dev}{'disk_status'} =~ /_/) {
            my $msg = "Degraded disk status: $device->{'meta'}{'mdraid'}{$dev}{'disk_status'}";
            unless ($thresholds->{'degraded_state'}) {
                push @warnings, $msg;
                $healthy = 0;
            }
            print "[" . date_get() . "] $fid WARNING: $msg\n";
        }
    } else {
        warn "$fid Warning: Missing disk status for $dev\n";
    }

    # Check member disks
    my @dev_index = index_split($device->{'mdraid'}{'devices'});
    
    foreach my $raiddev (@dev_index) {
        my $disk_healthy = 1;
        my @disk_warnings;
        
        unless (exists $device->{'meta'}{'smart'}{$raiddev}) {
            warn "$fid Warning: Missing SMART data for $raiddev\n";
            next;
        }

        # Check SMART tests
        if ($device->{'meta'}{'smart'}{$raiddev}{'self_test_passed'} ne "true") {
            push @disk_warnings, "Self-test failed";
            $device->{'meta'}{'health'}{'device'} = "ERROR";
            $disk_healthy = 0;
        }

        if ($device->{'meta'}{'smart'}{$raiddev}{'smart_passed'} ne "true") {
            push @disk_warnings, "SMART test failed";
            $device->{'meta'}{'health'}{'smart'} = "ERROR";
            $disk_healthy = 0;
        }

        # Check temperature
        if (exists $device->{'meta'}{'smart'}{$raiddev}{'temperature'}) {
            my $temp = $device->{'meta'}{'smart'}{$raiddev}{'temperature'};
            
            if ($temp >= $thresholds->{'temp_critical'}) {
                push @disk_warnings, "Critical temperature: ${temp}°C";
                $device->{'meta'}{'health'}{'temperature'} = "CRITICAL";
                $disk_healthy = 0;
            }
            elsif ($temp >= $thresholds->{'temp_warn'}) {
                push @disk_warnings, "High temperature: ${temp}°C";
                $device->{'meta'}{'health'}{'temperature'} = "WARNING";
                $disk_healthy = 0;
            }
        }

        # Update disk status
        if ($disk_healthy) {
            if (env_debug()) {
                print "[" . date_get() . "] $fid Disk $raiddev is healthy\n";
            }
            $device->{'meta'}{'mdraid'}{$dev}{'health'}{$raiddev} = {
                status => "HEALTHY",
                warning => ""
            };
        } else {
            my $disk_warning = join('; ', @disk_warnings);
            print "[" . date_get() . "] $fid Disk $raiddev has issues: $disk_warning\n";
            $device->{'meta'}{'mdraid'}{$dev}{'health'}{$raiddev} = {
                status => "WARNING",
                warning => $disk_warning
            };
            $healthy = 0;
            push @warnings, "Disk $raiddev: $disk_warning";
        }
    }

    # Set final status
    my $warning_str = join('; ', @warnings);
    if ($healthy) {
        if (env_debug()) {
            print "[" . date_get() . "] $fid RAID $dev is healthy\n";
        }
        $device->{'meta'}{'status'} = "HEALTHY";
        $device->{'meta'}{'warning'} = "";
        $device->{'meta'}{'health'}{'status'} = "HEALTHY";
    } else {
        print "[" . date_get() . "] $fid RAID $dev has issues: $warning_str\n";
        $device->{'meta'}{'status'} = "WARNING";
        $device->{'meta'}{'warning'} = $warning_str;
        $device->{'meta'}{'health'}{'status'} = "WARNING";
    }

    $device->{'meta'}{'health'}{'warning'} = $warning_str;
    return $device;
}

1;
