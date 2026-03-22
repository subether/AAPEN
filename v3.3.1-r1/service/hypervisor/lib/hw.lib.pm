#
# ETHER|AAPEN|HYPERVISOR - LIB|HW
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
# Collect and process hardware temperature data
#
sub hardware_stats(){
    my $fid = "[hardware temp]";
    my $ffid = "HW|SENSOR";
    my $exec = 'sensors -j';

    # Execute sensors command
    my $result = execute_supresserr($exec);
    unless ($result) {
		log_warn($ffid, "error: failed to execute sensors command");
        return;
    }

    # Parse JSON output
    my $json;
    eval {
        $json = decode_json $result;
        1;
    } or do {
        log_warn($ffid, "error: invalid JSON output from sensors");
        return;
    };

    unless (ref($json) eq 'HASH') {
        log_warn($ffid, "error: Unexpected sensor data format");
        return;
    }

    my $sensors = {};
    my $sensor_count = 0;

    # Process each detected sensor type
    foreach my $key (keys %$json) {
		log_debug($ffid, "found sensor type [$key]");
		
        if ($key =~ /coretemp/) {
            $sensors->{'coretemp'} = hw_coretemp($json->{$key}, $sensors->{'coretemp'} || {});
            $sensors->{'sensors'} = index_add($sensors->{'sensors'}, "coretemp");
            $sensor_count++;
        }
        elsif ($key =~ /acpitz/) {
            $sensors->{'acpitz'} = hw_acpitz($json->{$key});
            $sensors->{'sensors'} = index_add($sensors->{'sensors'}, "acpitz");
            $sensor_count++;
        }
        
        # additional sensors
    }

    # Update database with collected data
    my $db = hyper_db_get();
    $db->{'hw'} = hw_detect_new();
    $db->{'hw'}{'sensors'} = $sensors;
    
    hyper_db_set($db);
}

#
# Process coretemp sensor data and track temperature statistics
#
sub hw_coretemp($coretemp, $result){
    my $fid = "[hw_coretemp]";
    my $ffid = "HW|CORETEMP";
    my $package = 0;
    
    unless (ref($coretemp) eq 'HASH') {
        log_warn($ffid, "error: invalid coretemp data structure");
        return $result;
    }

    # Process each sensor group
    foreach my $pkg (keys %$coretemp) {
		 
        # Handle package sensors
        if ($pkg =~ /Package\s*(\d+)/) {
            $package = $1;
            $result->{'index'} = index_add($result->{'index'}, $package);
            
            # Initialize package stats if not present
            $result->{$package}{'temps'} ||= [];
            $result->{$package}{'count'} ||= 0;
            $result->{$package}{'sum'}   ||= 0;
        }
        
        # Handle core sensors
        elsif ($pkg =~ /Core\s*(\d+)/) {
            my $core_num = $1;
            my $sensors = $coretemp->{$pkg};
            
            unless (ref($sensors) eq 'HASH') {
				log_warn($ffid, "error: invalid sensor data for core [$core_num]");
                next;
            }

			$result->{'index'} = index_add($result->{'index'}, $package);

            # Process temperature readings
            foreach my $temp (keys %$sensors) {
                if ($temp =~ /input/) {
                    my $temp_value = $sensors->{$temp};
                    
                    # Store core temperature
                    $result->{$package}{$core_num} = $temp_value;
                    $result->{$package}{'index'} = index_add($result->{$package}{'index'}, $core_num);
                    
                    # Track for stats calculation
                    push @{$result->{$package}{'temps'}}, $temp_value;
                    $result->{$package}{'count'}++;
                    $result->{$package}{'sum'} += $temp_value;
                    
                    # Update min/max
                    if (!defined $result->{$package}{'max'} || 
                        $temp_value > $result->{$package}{'max'}) {
                        $result->{$package}{'max'} = $temp_value;
                    }
                    
                    if (!defined $result->{$package}{'min'} || 
                        $temp_value < $result->{$package}{'min'}) {
                        $result->{$package}{'min'} = $temp_value;
                    }
                }
            }
        }
    }
    
    # Calculate average for each package
    foreach my $pkg (keys %$result) {
        next unless $pkg =~ /^\d+$/;  # Skip non-package keys
        
        if ($result->{$pkg}{'count'} > 0) {
            $result->{$pkg}{'avg'} = $result->{$pkg}{'sum'} / $result->{$pkg}{'count'};
        }
    }
    
    return $result;
}

#
# Process ACPI thermal zone sensor data
#
sub hw_acpitz($acpitz) {
    my $fid = "[hw_acpitz]";
    my $ffid = "HW|ACPITZ";
    my $result = {};
    
    unless (ref($acpitz) eq 'HASH') {
        log_warn($ffid, "error: invalid ACPI thermal zone data structure");
        return $result;
    }

    # Check all possible temperature sensors (temp1, temp2, etc.)
    foreach my $sensor (keys %$acpitz) {
        if ($sensor =~ /^temp\d+$/) {
            my $sensor_data = $acpitz->{$sensor};
            
            if (ref($sensor_data) eq 'HASH' && 
                defined $sensor_data->{"${sensor}_input"}) {
                
                my $temp = $sensor_data->{"${sensor}_input"};
                # Return first valid temperature found
                return $temp;
            }
        }
    }

    log_warn($ffid, "warning: no valid ACPI thermal zone data found");
    
    return $result;
}

1;
