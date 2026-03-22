#
# ETHER|AAPEN|VMM - LIB|KVM
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
# Get comprehensive NVMe device information [JSON-OBJ]
#
sub nvme_info($device) {
    my $fid = "DEVICE|NVME|INFO";
    my $info = {};

    # Validate input
    unless (defined $device && ref($device) eq 'HASH' &&
            exists $device->{'device'} && exists $device->{'device'}{'dev'}) {
        log_warn($fid, "error: invalid device parameters");
        return $info;
    }

    my $dev = $device->{'device'}{'dev'};
    log_debug($fid, "getting device info for [$dev]");

    # Execute nvme command with error handling
    my $exec = 'nvme list --output-format=json';
    my $result = `$exec 2>&1`;
    
    unless ($result) {
        log_warn($fid, "error: failed to execulte nvme list command");
        return $info;
    }

    # Parse JSON with validation
    my $stats;
    eval {
        $stats = json_decode($result);
        1;
    } or do {
        log_warn($fid, "error: invalid json from nvme list command");
        return $info;
    };

    # Validate stats structure
    unless (ref($stats) eq 'HASH' && exists $stats->{'Devices'}) {
        log_warn($fid, "error: invalid device list structure");
        return $info;
    }

    # Find matching device
    foreach my $d (@{$stats->{'Devices'}}) {
        if ($d->{'DevicePath'} eq $dev) {
            $info = $d;
            last;
        }
    }

    unless (%$info) {
        log_warn($fid, "warning: no matching device found for [$dev]");
        return {};
    }

    # Set default values for critical fields
    $info->{'ModelNumber'} //= "unknown";
    $info->{'SerialNumber'} //= "unknown";
    $info->{'Firmware'} //= "unknown";
    $info->{'UsedBytes'} //= 0;
    $info->{'MaximumLBA'} //= 0;

    if (env_debug()) {
        log_debug($fid, "collected info for [$dev]");
        json_encode_pretty($info);
    }

    return $info;
}

#
# Collect comprehensive NVMe performance statistics [JSON-OBJ]
#
sub nvme_stats($device) {
    my $fid = "STORAGE|NVME|STATS";
    my $stats = {};

    # Validate input
    unless (defined $device && ref($device) eq 'HASH' &&
            exists $device->{'device'} && exists $device->{'device'}{'dev'}) {
        log_warn($fid, "error: invalid device parameters");
        return $stats;
    }

    my $dev = $device->{'device'}{'dev'};
    log_debug($fid, "collecting stats for device [$dev]");

    # Execute nvme command with error handling
    my $exec = 'nvme smart-log --output-format=json ' . $dev;
    my $result = `$exec 2>&1`;
    
    unless ($result) {
        log_warn($fid, "error: failed to execute nvme command for [$dev]");
        return $stats;
    }

    # Parse JSON with validation
    eval {
        $stats = json_decode($result);
        1;
    } or do {
        log_warn($fid, "error: invalid json from nvme command for [$dev]");
        return {};
    };

    # Validate stats structure
    unless (ref($stats) eq 'HASH') {
        log_warn($fid, "error: invalid stats structure for [$dev]");
        return {};
    }

    # Set default values for critical metrics if missing
    $stats->{'temperature'} //= 0;
    $stats->{'avail_spare'} //= 100;
    $stats->{'media_errors'} //= 0;
    $stats->{'num_err_log_entries'} //= 0;
    $stats->{'critical_warning'} //= 0;

    if (env_debug()) {
        log_debug($fid, "error: collected stats for [$dev]");
        json_encode_pretty($stats);
    }

    return $stats;
}

#
# Get comprehensive NVMe SMART information [JSON-OBJ]
#
sub nvme_smart_info($dev) {
    my $fid = "DEVICE|NVME|SMART|INFO";
    my $stats = {
        date => date_get(),
        form_factor => "m.2"
    };

    # Validate input
    unless (defined $dev && $dev =~ /^\/dev\/nvme/) {
        log_warn($fid, "error: invalid device path for [$dev]");
        return $stats;
    }

    log_debug($fid, "getting SMART info for [$dev]");

    # Execute smartctl with error handling
    my $exec = 'smartctl -a -j ' . $dev;
    my $smart_json = `$exec 2>&1`;
    
    unless ($smart_json) {
        log_warn($fid, "error: failed to execute smartctl for [$dev]");
        return $stats;
    }

    # Parse JSON with validation
    my $smart;
    eval {
        $smart = json_decode($smart_json);
        1;
    } or do {
        log_warn($fid, "error: invalid json from smartctl for [$dev]");
        return $stats;
    };

    # Validate required SMART data exists
    unless (ref($smart) eq 'HASH') {
        log_warn($fid, "error: invalid SMART data structure for [$dev]");
        return $stats;
    }

    # Extract and validate SMART data
    $stats->{'firmware'} = $smart->{'firmware_version'} || "unknown";
    $stats->{'model_name'} = $smart->{'model_name'} || "unknown";

    # SMART status
    if (exists $smart->{'smart_status'} && ref($smart->{'smart_status'}) eq 'HASH') {
        $stats->{'smart_passed'} = $smart->{'smart_status'}{'passed'} ? "true" : "false";
    } else {
        $stats->{'smart_passed'} = "false";
        log_warn($fid, "missing SMART status for [$dev]");
    }

    # Power statistics
    $stats->{'power_cycles'} = $smart->{'power_cycle_count'} || 0;
    $stats->{'power_on_hours'} = $smart->{'power_on_time'}{'hours'} || 0;

    # Temperature
    if (exists $smart->{'temperature'} && ref($smart->{'temperature'}) eq 'HASH') {
        $stats->{'temperature'} = $smart->{'temperature'}{'current'} || 0;
    } else {
        $stats->{'temperature'} = 0;
    }

    # Self-test status (compatibility)
    $stats->{'self_test_passed'} = $stats->{'smart_passed'};

    if (env_debug()) {
        log_debug($fid, "collected SMART info for [$dev]");
        json_encode_pretty($stats);
    }

    return $stats;
}

#
# Comprehensive NVMe health checking [JSON-OBJ]
#
sub nvme_health($device) {
    my $fid = "DEVICE|NVME|HEALTH";
    
    # Validate input
    unless (defined $device && ref($device) eq 'HASH' &&
            exists $device->{'device'} && exists $device->{'device'}{'dev'}) {
        #warn "$fid Error: Invalid device parameter\n";
        log_warn($fid, "error: invalid device parameters");
        return $device;
    }

    my $dev = $device->{'device'}{'dev'};
    my $healthy = 1;
    my @warnings;
    
    # Threshold configuration
    my $thresholds = {
        temp_warn      => 45,    # °C
        temp_critical  => 70,    # °C
        media_errors   => 0,     # Any media errors are bad
        avail_spare    => 100,   # Percentage
        spare_thresh   => 10,    # Percentage
        percent_used   => 0,     # Percentage
        err_log_entries=> 0      # Count
    };

    if (env_debug()) {
        log_debug($fid, "checking health for device [$dev]");
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

    # Check NVMe temperature
    if (exists $device->{'meta'}{'nvme'}{'health'}{'temperature'}) {
        my $temp = kelvin_to_celcius($device->{'meta'}{'nvme'}{'health'}{'temperature'});
        
        if ($temp >= $thresholds->{'temp_critical'}) {
            push @warnings, "CRITICAL TEMPERATURE [$temp°C]";
            log_warn($fid, "CRITICAL TEMPERATURE [$temp°C] for [$dev]");
            $device->{'meta'}{'health'}{'temperature'} = "CRITICAL [$temp°C]";
            $healthy = 0;
        }
        elsif ($temp >= $thresholds->{'temp_warn'}) {
            push @warnings, "HIGH TEMPERATURE [$temp°C]";
            log_warn($fid, "HIGH TEMPERATURE [$temp°C] for [$dev]");
            $device->{'meta'}{'health'}{'temperature'} = "HIGH [$temp°C]";
            $healthy = 0;
        }
    }

    # Check SMART temperature
    if (exists $device->{'meta'}{'smart'}{'temperature'}) {
        my $temp = $device->{'meta'}{'smart'}{'temperature'};
        
        if ($temp >= $thresholds->{'temp_critical'}) {
            push @warnings, "CRITICAL SMART TEMPERATURE [$temp°C]";
            log_warn($fid, "CRITICAL SMART TEMPERATURE [$temp°C] for [$dev]");
            $device->{'meta'}{'health'}{'temperature'} = "CRITICAL [$temp°C]";
            $healthy = 0;
        }
        elsif ($temp >= $thresholds->{'temp_warn'}) {
            push @warnings, "HIGH SMART TEMPERATURE [$temp°C]";
            log_warn($fid, "HIGH SMART TEMPERATURE [$temp°C] for [$dev]");
            $device->{'meta'}{'health'}{'temperature'} = "HIGH [$temp°C]";
            $healthy = 0;
        }
    }

    # Check other health indicators
    my @health_checks = (
        { field => 'warning_temp_time',  test => '>',  value => 0,           msg => "Temperature warning time: %d" },
        { field => 'media_errors',       test => '>',  value => $thresholds->{'media_errors'}, msg => "Media errors: %d" },
        { field => 'avail_spare',       test => '!=', value => $thresholds->{'avail_spare'}, msg => "Available spare: %d%%" },
        { field => 'spare_thresh',      test => '!=', value => $thresholds->{'spare_thresh'}, msg => "Spare threshold: %d%%" },
        { field => 'percent_used',      test => '!=', value => $thresholds->{'percent_used'}, msg => "Percent used: %d%%" },
        { field => 'num_err_log_entries', test => '>', value => $thresholds->{'err_log_entries'}, msg => "Error log entries: %d" }
    );

    foreach my $check (@health_checks) {
        if (exists $device->{'meta'}{'nvme'}{'health'}{$check->{'field'}}) {
            my $value = $device->{'meta'}{'nvme'}{'health'}{$check->{'field'}};
            my $expr = "\$value $check->{'test'} \$check->{'value'}";
            
            if (eval $expr) {
                my $msg = sprintf($check->{'msg'}, $value);
                push @warnings, $msg;
                $healthy = 0;
                
                if (env_debug()) {
                    print "$fid DEVICE [$dev] $msg\n";
                }
            }
        }
    }

    # Set final status
    my $warning_str = join('; ', @warnings);
    if ($healthy) {
        if (env_debug()) {
            print "[" . date_get() . "] $fid device [$dev] is healthy\n";
        }
        $device->{'meta'}{'status'} = "HEALTHY";
        $device->{'meta'}{'warning'} = "";
    } 
    else {
		log_warn($fid, "device [$dev] has warnings: [$warning_str]");
        $device->{'meta'}{'status'} = "WARNING";
        $device->{'meta'}{'warning'} = $warning_str;
    }

    $device->{'meta'}{'health'}{'status'} = $device->{'meta'}{'status'};
    $device->{'meta'}{'health'}{'warning'} = $device->{'meta'}{'warning'};

    return $device;
}

#
# convert kelvin to celcius [INT]
#
sub kelvin_to_celcius($kelvin){
	my $celcius = $kelvin - 273.15;
	return int($celcius);
}

1;
