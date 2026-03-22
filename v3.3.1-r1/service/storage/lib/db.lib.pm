#
# ETHER - AAPEN - STORAGE - DATABASE LIB (IMPROVED)
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

use TryCatch;

#
# initialize device config [NULL]
#
sub device_config_init() {
    my $fid = "[device_config_init]";
    my $ffid = "DEVICE|CONFIG|INIT";
    
    my $devdb = storage_db_obj_get("device");
    my $host = hostname_get();
    my $storcfgbase = base_storage_cfg_get();
    
    log_info_json($ffid, "storage config base", $storcfgbase);
    
    my $i = 0;
    
    my $device_dir_base = $storcfgbase->{'device'}{'dir'};
    my $device_cfg_type = "*" . $storcfgbase->{'device'}{'type'};
    
    # Validate directory path for security
    unless ($device_dir_base && -d $device_dir_base) {
        log_error($ffid, "Invalid device directory: $device_dir_base");
        return;
    }
    
    # iterate the objects in the directory
    my @file_list = file_list($device_dir_base, $device_cfg_type);
    
    log_debug($fid, "DIR BASE [$device_dir_base]");
    log_debug($fid, "CFG TYPE [$device_cfg_type]");
    log_debug($fid, "FILE LIST [" . scalar(@file_list) . " files]");
    
    foreach my $dev_config_file (@file_list) {
        log_info($ffid, "loading device config [$dev_config_file]");
        
        try {
            my $dev_config = json_file_load($dev_config_file);
            
            # Validate device configuration structure
            unless (_validate_device_config($dev_config)) {
                log_warn($ffid, "Invalid device config structure in $dev_config_file");
                next;
            }
            
            if ($dev_config->{'node'}{'name'} eq config_node_name_get() && 
                $dev_config->{'node'}{'id'} eq config_node_id_get()) {
                
                log_info_json($ffid, "loading device [$dev_config->{'id'}{'name'}] context [LOCAL]", $dev_config);
                
                $devdb->{'index'} = index_add($devdb->{'index'}, $dev_config->{'id'}{'name'});
                $devdb->{'data'}{$dev_config->{'id'}{'name'}} = $dev_config;
                $i++;
            }
            else {
                log_info($fid, "device [$dev_config->{'id'}{'name'}] context [REMOTE]");
            }
        }
        catch {
            log_error($ffid, "Failed to load device config $dev_config_file: $_");
        }
    }
    
    storage_db_obj_set("device", $devdb);
    log_info($ffid, "loaded [$i] device configurations");
}

#
# initialize pool config [NULL]
#
sub pool_config_init() {
    my $fid = "[pool_config_init]";
    my $ffid = "POOL|CONFIG|INIT";
    
    my $pooldb = storage_db_obj_get("pool");
    my $host = hostname_get();
    my $storcfgbase = base_storage_cfg_get();
    
    log_info_json($ffid, "storage config base", $storcfgbase);
    
    my $i = 0;
    
    my $pool_dir_base = $storcfgbase->{'pool'}{'dir'};
    my $pool_cfg_type = "*" . $storcfgbase->{'pool'}{'type'};
    
    # Validate directory path for security
    unless ($pool_dir_base && -d $pool_dir_base) {
        log_error($ffid, "Invalid pool directory: $pool_dir_base");
        return;
    }
    
    # iterate the objects in the directory
    my @file_list = file_list($pool_dir_base, $pool_cfg_type);
    
    log_debug($fid, "DIR BASE [$pool_dir_base]");
    log_debug($fid, "CFG TYPE [$pool_cfg_type]");
    log_debug($fid, "FILE LIST [" . scalar(@file_list) . " files]");
    
    foreach my $pool_config_file (@file_list) {
        log_info($ffid, "loading pool config [$pool_config_file]");
        
        try {
            my $pool_config = json_file_load($pool_config_file);
            
            # Validate pool configuration structure
            unless (_validate_pool_config($pool_config)) {
                log_warn($ffid, "Invalid pool config structure in $pool_config_file");
                next;
            }
            
            # check for owner
            if ($pool_config->{'owner'}{'name'} eq config_node_name_get() && 
                $pool_config->{'owner'}{'id'} eq config_node_id_get()) {
                
                log_info($ffid, "pool [$pool_config->{'owner'}{'name'}] context [LOCAL]");
                
                # check if already known
                if (index_find($pooldb->{'index'}, $pool_config->{'id'}{'name'})) {
                    log_info($ffid, "pool [$pool_config->{'owner'}{'name'}] is [KNOWN] - updating");
                    
                    # Update existing pool configuration
                    delete $pool_config->{'meta'}{'stats'};
                    $pooldb->{'data'}{$pool_config->{'id'}{'name'}} = $pool_config;
                    
                    # Update metadata
                    $pooldb->{'meta'}{$pool_config->{'id'}{'name'}}{'state'} = "1";
                    $pooldb->{'meta'}{$pool_config->{'id'}{'name'}}{'date'} = date_get();
                }
                else {
                    log_info($fid, "pool [$pool_config->{'owner'}{'name'}] is [UNKNOWN] - adding");
                    
                    # add pool to db
                    delete $pool_config->{'meta'}{'stats'};
                    
                    $pooldb->{'data'}{$pool_config->{'id'}{'name'}} = $pool_config;
                    $pooldb->{'index'} = index_add($pooldb->{'index'}, $pool_config->{'id'}{'name'});
                    
                    # metadata
                    $pooldb->{'meta'}{$pool_config->{'id'}{'name'}}{'state'} = "0";
                    $pooldb->{'meta'}{$pool_config->{'id'}{'name'}}{'init'} = "0";
                    $pooldb->{'meta'}{$pool_config->{'id'}{'name'}}{'date'} = date_get();
                    
                    # commit to database
                    storage_db_obj_set("pool", $pooldb);
                    
                    log_info($ffid, "pool [$pool_config->{'id'}{'name'}] added to database");
                }
            }
            else {
                log_info($ffid, "pool [$pool_config->{'id'}{'name'}] context [REMOTE]");
            }
        }
        catch {
            log_error($ffid, "Failed to load pool config $pool_config_file: $_");
        }
    }
    
    log_info($ffid, "loaded [$i] pool configurations");
}

#
# initialize database [JSON-OBJ]
#
sub storage_db_init() {
    my $fid = "[storage_db_init]";
    my $ffid = "STORAGE|DB|INIT";
    my $db;
    
    $db->{'config'}{'id'} = config_node_id_get();
    $db->{'config'}{'name'} = config_node_name_get();
    $db->{'config'}{'addr'} = config_node_addr_get();
    
    $db->{'version'} = env_version();
    $db->{'self'}{'init'} = "1";
    $db->{'device'}{'index'} = "";
    $db->{'pool'}{'index'} = "";
    
    # Initialize metadata structures
    $db->{'device'}{'meta'} = {};
    $db->{'device'}{'db'} = {};
    $db->{'pool'}{'meta'} = {};
    $db->{'pool'}{'db'} = {};
    
    storage_db_set($db);
    
    log_info($ffid, "storage database initialized");
}

#
# get database [JSON-STR]
#
sub storage_db_get() {
    my %vmshare = dbshare_get();
    my $db_str = $vmshare{'db'};
    
    unless ($db_str) {
        log_warn("[storage_db_get]", "No database in shared memory");
        return {};
    }
    
    my $db = json_decode($db_str);
    return $db;
}

#
# set database
#
sub storage_db_set($db) {
    my $fid = "[storage_db_set]";
    my $ffid = "STORAGE|DB|SET";
    my %vmshare = dbshare_get();
    
    # encode
    my $data = json_encode($db);
    
    # validate
    if (json_decode_validate($data)) {
        $vmshare{'db'} = $data;
        $vmshare{'db_state'} = 1;
        dbshare_set(%vmshare);
        
        # save state
        log_info($ffid, "saving config state");
        config_state_save("storage", $db);
        
        return 1;
    }
    else {
        log_error($ffid, "failed to validate JSON!");
        return 0;
    }
}

#
# get object [JSON-OBJ]
# 
sub storage_db_obj_get($obj) {
    my $db = storage_db_get();
    
    unless (exists $db->{$obj}) {
        # Initialize object if it doesn't exist
        $db->{$obj} = {
            'index' => "",
            'meta' => {},
            'db' => {}
        };
        storage_db_set($db);
    }
    
    return $db->{$obj};
}

#
# set object [NULL]
# 
sub storage_db_obj_set($obj, $data) {
    my $db = storage_db_get();
    $db->{$obj} = $data;
    storage_db_set($db);
}

#
# print database [NULL]
#
sub storage_db_print() {
    my $fid = "[storage_db_print]";
    my $ffid = "STORAGE|DB|PRINT";
    my $db = storage_db_get();
    
    log_info($ffid, "printing database contents");
    json_encode_pretty($db);
}

#
# storage db meta [JSON-STR]
# 
sub storage_db_meta($req) {
    my $fid = "storage_db_meta";
    my $ffid = "STORAGE|DB|META";  # Fixed: pipe-separated
    my $db = storage_db_get();
    
    my $packet = packet_build_noencode("1", "success: returning metadata", $fid);
    $packet->{'storage'}{'version'} = env_version();
    $packet->{'storage'}{'device'}{'index'} = $db->{'device'}{'index'} // "";
    $packet->{'storage'}{'pool'}{'index'} = $db->{'pool'}{'index'} // "";
    
    # Add counts
    $packet->{'storage'}{'device'}{'count'} = 
        $db->{'device'}{'index'} ? scalar(index_split($db->{'device'}{'index'})) : 0;
    $packet->{'storage'}{'pool'}{'count'} = 
        $db->{'pool'}{'index'} ? scalar(index_split($db->{'pool'}{'index'})) : 0;
    
    # Add database size information
    $packet->{'storage'}{'db_size'} = length(json_encode($db));
    
    return json_encode($packet);
}

#
# Validate device configuration structure
#
sub _validate_device_config($config) {
    return 0 unless ref($config) eq 'HASH';
    
    # Check required fields
    unless (exists $config->{'object'} && ref($config->{'object'}) eq 'HASH') {
        return 0;
    }
    
    unless ($config->{'object'}{'type'} eq 'storage' && 
            $config->{'object'}{'model'} eq 'device') {
        return 0;
    }
    
    unless (exists $config->{'id'} && ref($config->{'id'}) eq 'HASH' &&
            exists $config->{'id'}{'name'}) {
        return 0;
    }
    
    # Validate device name
    my $device_name = $config->{'id'}{'name'};
    unless ($device_name =~ /^[a-zA-Z0-9_-]+$/) {
        return 0;
    }
    
    # Check for required node information
    unless (exists $config->{'node'} && ref($config->{'node'}) eq 'HASH') {
        return 0;
    }
    
    return 1;
}

#
# Validate pool configuration structure
#
sub _validate_pool_config($config) {
    return 0 unless ref($config) eq 'HASH';
    
    # Check required fields
    unless (exists $config->{'object'} && ref($config->{'object'}) eq 'HASH') {
        return 0;
    }
    
    unless ($config->{'object'}{'type'} eq 'storage' && 
            $config->{'object'}{'model'} eq 'pool') {
        return 0;
    }
    
    unless (exists $config->{'id'} && ref($config->{'id'}) eq 'HASH' &&
            exists $config->{'id'}{'name'}) {
        return 0;
    }
    
    # Validate pool name
    my $pool_name = $config->{'id'}{'name'};
    unless ($pool_name =~ /^[a-zA-Z0-9_-]+$/) {
        return 0;
    }
    
    # Check for required owner information
    unless (exists $config->{'owner'} && ref($config->{'owner'}) eq 'HASH') {
        return 0;
    }
    
    return 1;
}

#
# Get database statistics [JSON-OBJ]
#
sub storage_db_stats() {
    my $fid = "[storage_db_stats]";
    my $ffid = "STORAGE|DB|STATS";
    
    my $db = storage_db_get();
    
    my $stats = {
        timestamp => date_get(),
        version => env_version(),
        objects => {
            device => {
                count => $db->{'device'}{'index'} ? scalar(index_split($db->{'device'}{'index'})) : 0,
                index_size => length($db->{'device'}{'index'} // ""),
            },
            pool => {
                count => $db->{'pool'}{'index'} ? scalar(index_split($db->{'pool'}{'index'})) : 0,
                index_size => length($db->{'pool'}{'index'} // ""),
            }
        },
        memory_usage => {
            estimated_bytes => length(json_encode($db)),
            objects => scalar(keys %$db),
        }
    };
    
    return $stats;
}

#
# Clear database [NULL]
#
sub storage_db_clear() {
    my $fid = "[storage_db_clear]";
    my $ffid = "STORAGE|DB|CLEAR";
    
    log_info($ffid, "clearing storage database");
    
    my $empty_db = {
        'config' => {
            'id' => config_node_id_get(),
            'name' => config_node_name_get(),
            'addr' => config_node_addr_get(),
        },
        'version' => env_version(),
        'self' => {'init' => "1"},
        'device' => {'index' => "", 'meta' => {}, 'db' => {}},
        'pool' => {'index' => "", 'meta' => {}, 'db' => {}},
    };
    
    storage_db_set($empty_db);
    
    log_info($ffid, "storage database cleared");
    return 1;
}

1;
