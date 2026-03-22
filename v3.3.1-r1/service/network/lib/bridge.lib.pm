#
# ETHER|AAPEN|NETWORK - LIB|BRIDGE
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
# validate interface name [STRING]
#
sub validate_interface_name($name) {
    return $name =~ /^[a-z0-9\._-]{1,15}$/i;
}

#
# validate vlan id [INT]
#
sub validate_vlan_id($vlan) {
    return $vlan =~ /^\d{1,4}$/ && $vlan >= 1 && $vlan <= 4094;
}

#
# validate bridge options [HASHREF]
#
sub validate_bridge_options($options) {
    return 1 if !defined $options; # No options is valid
    my $valid = 1;
    $valid &&= $options->{'stp'} =~ /^(on|off)$/i if exists $options->{'stp'};
    $valid &&= $options->{'hairpin'} =~ /^(on|off)$/i if exists $options->{'hairpin'};
    return $valid;
}

#
# add untagged bridge [JSON-STR]
#
sub bri_add($network){
	my $fid = "[bri_add]";
	my $ffid = "BRI|ADD";
	my ($exec, $status, $result);
	
	my $id = config_node_id_get();
	my $name = config_node_name_get();

	# validate network card
	if(!validate_interface_name($network->{'node'}{$id})){
		log_error($ffid, "network device [$network->{'node'}{$id}] name invalid!");
		return packet_build_encode("0", "error: network device [$network->{'node'}{$id}] name invalid!", $fid);
	}
	
	# allow floating bridges.. bridges without physical interfaces
	if($network->{'node'}{$id} eq "NULL" || $network->{'node'}{$id} eq "null"){
		log_info($ffid, "skipping interface checking. NULL interface [$network->{'node'}{$id}]");
	}
	else{
	
		# check interface exists using iproute2
		$exec = "ip -j link show $network->{'node'}{$id} 2>/dev/null";
		$result = execute($exec);
		
		if($? != 0) {
			log_error($ffid, "net [$name] id [$id] interface [$network->{'node'}{$id}] not found!");
			return packet_build_encode("0", "error: net [$name] id [$id] interface [$network->{'node'}{$id}] not found", $fid);
		}
	}
	
	# initialize bridge
	if($network->{'meta'}{'type'} eq "trunk"){
		log_info($fid, "adding untagged bridge");
		
		my $bridge;
		$bridge = $network;
		$bridge->{'bri'}{'type'} = $network->{'meta'}{'type'};
		$bridge->{'bri'}{'brdev'} = $network->{'trunk'}{'bridge'};
		$bridge->{'bri'}{'ethdev'} = $network->{'node'}{$id};
		$bridge->{'bri'}{'netid'} = $network->{'id'}{'id'};
		
		($status, $result) = bri_add_trunk_iproute2($bridge);
		$result = packet_build_encode($result, $status, $fid);	
	}
	elsif($network->{'meta'}{'type'} eq "vlan"){
		log_info($fid, "adding vlan tagged bridge");
		
		my $bridge;
		$bridge = $network;
		$bridge->{'bri'}{'brdev'} = $network->{'vlan'}{'bridge'};
		$bridge->{'bri'}{'ethdev'} = $network->{'node'}{$id};
		$bridge->{'bri'}{'type'} = $network->{'meta'}{'type'};
		$bridge->{'bri'}{'vlan'} = $network->{'vlan'}{'tag'};
		$bridge->{'bri'}{'netid'} = $network->{'id'}{'id'};		
		
		($status, $result) = bri_add_tagged_iproute2($bridge);
		$result = packet_build_encode($result, $status, $fid);	
	}
	else{
		# unknown bridge type
		log_error($ffid, "unknown bridge type!");
		$result = packet_build_encode("0", "error: unknown bridge type!", $fid);	
	}

	return $result;
}

#
# return bridge data [JSON-OBJ]
#
sub bri_info(){
	my $bridb = net_db_obj_get("bri");
	my $fid = "[bri_info]";
	return $bridb;
}

#
# add vlan tagged bridge using iproute2 [STRING],[BOOLEAN]
#
sub bri_add_tagged_iproute2($bridge) {
    my $fid = "[bri_add_tagged_iproute2]";
    my $ffid = "BRI|ADD|TAGGED";
    my ($exec, $return, $status, $result);
    my $bridb = net_db_obj_get("bri");

    # validate inputs using helper functions
    if (!validate_interface_name($bridge->{'bri'}{'brdev'})) {
		log_error($ffid, "invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)");
        return ("error: invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
    }
    if (!validate_interface_name($bridge->{'bri'}{'ethdev'})) {
		log_error($ffid, "invalid interface name - only alphanumeric, ., - and _ allowed (max 15 chars)");
        return ("error: invalid interface name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
    }
    if (!validate_vlan_id($bridge->{'bri'}{'vlan'})) {
		log_error($ffid, "invalid vlan id - must be numeric between 1-4094");
        return ("error: invalid vlan id - must be numeric between 1-4094", 0);
    }

    # check interface state exists and is up
    $exec = "ip -j link show $bridge->{'bri'}{'ethdev'} 2>/dev/null";
    $result = execute($exec);
    if($? != 0) {
        log_error($ffid, "interface $bridge->{'bri'}{'ethdev'} does not exist");
		return ("error: interface $bridge->{'bri'}{'ethdev'} does not exist", 0);
    }
    my $iface_state = decode_json($result)->[0]->{'operstate'};
    if($iface_state ne 'UP'){
		log_error($ffid, "interface $bridge->{'bri'}{'ethdev'} is not UP ($iface_state)");
        return ("error: interface $bridge->{'bri'}{'ethdev'} is not UP ($iface_state)", 0);
    }

    # check if bridge is locked
    if( !index_find($bridb->{'index'}, $bridge->{'bri'}{'brdev'}) ) {

        # check if bridge exists
        $exec = "ip link show $bridge->{'bri'}{'brdev'} 2>/dev/null";
        $result = execute($exec);

        if($? != 0) {  # Bridge doesn't exist
            # create bridge with STP/hairpin options
            my $stp = $bridge->{'bri'}{'stp'} || 'on';  # Default STP on
            my $hairpin = $bridge->{'bri'}{'hairpin'} || 'off';  # Default hairpin off
            
            #$exec = "ip link add name $bridge->{'bri'}{'brdev'} type bridge stp_state $stp hairpin_mode $hairpin";
            $exec = "ip link add name $bridge->{'bri'}{'brdev'} type bridge";
            if(env_debug()){ 
                print "$fid exec [$exec]\n";
                print "$fid STP options: on|off (default: on)\n";
                print "$fid Hairpin options: on|off (default: off)\n"; 
            }
            $result = execute($exec);
            if($?) {
				log_error($fid, "failed to create bridge (invalid STP/hairpin options?)");
                return ("error: failed to create bridge - valid STP options: on/off, hairpin options: on/off", 0);
            }

            # setup cleanup on failure
            my $cleanup_needed = 1;

            # bring up physical interface
            $exec = "ip link set $bridge->{'bri'}{'ethdev'} up";
            log_debug($fid, "exec [$exec]");
            execute($exec);

            # create VLAN interface
            $exec = "ip link add link $bridge->{'bri'}{'ethdev'} " .
                    "name $bridge->{'bri'}{'ethdev'}.$bridge->{'bri'}{'vlan'} " .
                    "type vlan id $bridge->{'bri'}{'vlan'}";
			log_error($ffid, "exec [$exec]");
            $result = execute($exec);
            if($?) {
				log_error($fid, "failed to create VLAN interface");
                return ("error: failed to create VLAN interface", 0);
            }

            # set promiscuous mode
            $exec = "ip link set $bridge->{'bri'}{'ethdev'}.$bridge->{'bri'}{'vlan'} promisc on";
            log_debug($ffid, "exec [$exec]");
            execute($exec);

            # bring up VLAN interface
            $exec = "ip link set $bridge->{'bri'}{'ethdev'}.$bridge->{'bri'}{'vlan'} up";
            log_error($fid, "exec [$exec]");
            $result = execute($exec);
            if($?) {
				log_error($ffid, "failed to bring up VLAN interface");
                return ("error: failed to bring up VLAN interface", 0);
            }

            # add VLAN interface to bridge
            $exec = "ip link set $bridge->{'bri'}{'ethdev'}.$bridge->{'bri'}{'vlan'} master $bridge->{'bri'}{'brdev'}";
            log_debug($fid, "exec [$exec]");
            $result = execute($exec);
            if($?) {
				log_error($ffid, "failed to add interface to bridge");
                return ("error: failed to add interface to bridge", 0);
            }

            # bring up bridge
            $exec = "ip link set $bridge->{'bri'}{'brdev'} up";
            log_error($fid, "exec [$exec]");
            if (execute($exec)) {
                if ($cleanup_needed) {
                    execute("ip link del $bridge->{'bri'}{'brdev'}");
                }
				log_error($ffid, "failed to bring up bridge");
                return ("error: failed to bring up bridge", 0);
            }

            # success - no cleanup needed
            $cleanup_needed = 0;

            # Update bridge database
            $bridb->{'index'} = index_add($bridb->{'index'}, $bridge->{'bri'}{'brdev'});
            delete $bridge->{'proto'};
            $bridge->{'bri'}{'meta'}{'lock'} = 1;
            $bridge->{'bri'}{'meta'}{'state'} = 1;
            $bridb->{$bridge->{'bri'}{'brdev'}} = $bridge;

			log_info($ffid, "bridge [$bridge->{'bri'}{'brdev'}] created");
            $return = "bridge [$bridge->{'bri'}{'brdev'}] created";
            $status = 1;
            net_db_obj_set("bri", $bridb);
        }
        else {
			log_warn($ffid, "bridge [$bridge->{'bri'}{'brdev'}] exists");
            $return = "bridge [$bridge->{'bri'}{'brdev'}] exists";
            $status = 1;
            
            # Update bridge database
            $bridb->{'index'} = index_add($bridb->{'index'}, $bridge->{'bri'}{'brdev'});
            delete $bridge->{'proto'};
            $bridge->{'bri'}{'meta'}{'lock'} = 1;
            $bridge->{'bri'}{'meta'}{'state'} = 1;
            $bridb->{$bridge->{'bri'}{'brdev'}} = $bridge;
            net_db_obj_set("bri", $bridb);

        }
    }
    else {
		log_warn($ffid, "bridge [$bridge->{'bri'}{'brdev'}] already marked online");
        $return = "bridge [$bridge->{'bri'}{'brdev'}] already marked online";
        $status = 1;
    }

    #net_db_obj_set("bri", $bridb);
    return ($return, $status);
}

#
# add trunked bridge using iproute2 [STRING],[BOOLEAN]
#
sub bri_add_trunk_iproute2($bridge) {
    my $fid = "[bri_add_trunk_iproute2]";
    my $ffid = "BRI|ADD|TRUNK";
    my ($exec, $return, $status, $result);
    my $bridb = net_db_obj_get("bri");

    # validate inputs using helper functions
    if (!validate_interface_name($bridge->{'bri'}{'brdev'})) {
		log_error($ffid, "invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)");
        return ("error: invalid bridge name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
    }
    if (!validate_interface_name($bridge->{'bri'}{'ethdev'})) {
		log_error($ffid, "invalid interface name - only alphanumeric, ., - and _ allowed (max 15 chars)");
        return ("error: invalid interface name - only alphanumeric, ., - and _ allowed (max 15 chars)", 0);
    }

    if(env_debug()){ json_encode_pretty($bridge); }
    
    # check if bridge is locked
    if(!index_find($bridb->{'index'}, $bridge->{'bri'}{'brdev'})) {

        # check if bridge exists
        $exec = "ip link show $bridge->{'bri'}{'brdev'} 2>/dev/null";
        $result = execute($exec);

        if($? != 0) {  # Bridge doesn't exist
            # Create bridge
            $exec = "ip link add name $bridge->{'bri'}{'brdev'} type bridge";
            log_debug($ffid, "exec [$exec]");
            $result = execute($exec);
            if($?) {
				log_error($fid, "failed to create bridge");
                return ("error: failed to create bridge", 0);
            }

            # setup cleanup on failure
            my $cleanup_needed = 1;

			# allow floating bridges.. bridges without physical interfaces
			if($bridge->{'bri'}{'ethdev'} eq "NULL" || $bridge->{'bri'}{'ethdev'} eq "null"){
				log_info($ffid, "initializing floating bridge. interface [$bridge->{'bri'}{'ethdev'}]");
				
				# add dummy interface
				#ip link add name br0-dummy type dummy
				#ip link set br0-dummy master br0
				#ip link set br0-dummy up
				
				# configure dummy interface
				my $dummy = $bridge->{'bri'}{'brdev'} . "-dummy";
				
				# create dummy interface
				$exec = "ip link add name $dummy type dummy";
				log_debug($ffid, "exec [$exec]");
				if (execute($exec)) {
					log_error($fid, "failed to create dummy interface");
					return ("error: failed to create dummy interface", 0);
				}
				
				
				# add interface to bridge
				$exec = "ip link set $dummy master $bridge->{'bri'}{'brdev'}";
				log_debug($ffid, "exec [$exec]");
				$result = execute($exec);
				if($?) {
					if ($cleanup_needed) {
						execute("ip link del $bridge->{'bri'}{'brdev'}");
					}
					log_error($fid, "failed to add dummy interface to bridge");
					return ("error: failed to add dummy interface to bridge", 0);
				}			
				
				# bring up dummy interface
				$exec = "ip link set $dummy up";
				log_debug($ffid, "exec [$exec]");
				if (execute($exec)) {
					if ($cleanup_needed) {
						execute("ip link del $dummy");
					}
					log_error($fid, "failed to bring up dummy interface");
					return ("error: failed to bring up dummy interface", 0);
				}		
				
			}
			else{
				#log_info($ffid, "");

				# bring up physical interfacea
				$exec = "ip link set $bridge->{'bri'}{'ethdev'} up";
				log_debug($ffid, "exec [$exec]");
				if (execute($exec)) {
					if ($cleanup_needed) {
						execute("ip link del $bridge->{'bri'}{'brdev'}");
					}
					log_error($fid, "failed to bring up interface");
					return ("error: failed to bring up interface", 0);
				}

				# set promiscuous mode
				$exec = "ip link set $bridge->{'bri'}{'ethdev'} promisc on";
				log_debug($ffid, "exec [$exec]");
				if (execute($exec)) {
					if ($cleanup_needed) {
						execute("ip link del $bridge->{'bri'}{'brdev'}");
					}
					log_error($fid, "failed to set promiscuous mode");
					return ("error: failed to set promiscuous mode", 0);
				}

				# add interface to bridge
				$exec = "ip link set $bridge->{'bri'}{'ethdev'} master $bridge->{'bri'}{'brdev'}";
				log_debug($ffid, "exec [$exec]");
				$result = execute($exec);
				if($?) {
					if ($cleanup_needed) {
						execute("ip link del $bridge->{'bri'}{'brdev'}");
					}
					log_error($fid, "failed to add interface to bridge");
					return ("error: failed to add interface to bridge", 0);
				}

			}

            # bring up bridge
            $exec = "ip link set $bridge->{'bri'}{'brdev'} up";
            log_debug($ffid, "exec [$exec]");
            if (execute($exec)) {
                if ($cleanup_needed) {
                    execute("ip link del $bridge->{'bri'}{'brdev'}");
                }
				log_error($fid, "failed to bring up bridge");
                return ("error: failed to bring up bridge", 0);
            }

            # success - no cleanup needed
            $cleanup_needed = 0;

            # update bridge database
            $bridb->{'index'} = index_add($bridb->{'index'}, $bridge->{'bri'}{'brdev'});
            delete $bridge->{'proto'};
            $bridge->{'bri'}{'meta'}{'lock'} = 1;
            $bridge->{'bri'}{'meta'}{'state'} = 1;
            $bridb->{$bridge->{'bri'}{'brdev'}} = $bridge;

			log_info($ffid, "bridge [$bridge->{'bri'}{'brdev'}] created");
            $return = "bridge [$bridge->{'bri'}{'brdev'}] created";
            $status = 1;
        }
        else {
			log_warn($ffid, "bridge [$bridge->{'bri'}{'brdev'}] exists");
			
			# update bridge database
            $bridb->{'index'} = index_add($bridb->{'index'}, $bridge->{'bri'}{'brdev'});
            delete $bridge->{'proto'};
            $bridge->{'bri'}{'meta'}{'lock'} = 1;
            $bridge->{'bri'}{'meta'}{'state'} = 1;
            $bridb->{$bridge->{'bri'}{'brdev'}} = $bridge;
            
            $return = "bridge [$bridge->{'bri'}{'brdev'}] exists";
            $status = 1;
        }
    }
    else {
		log_warn($ffid, "bridge [$bridge->{'bri'}{'brdev'}] already marked online");
        $return = "bridge [$bridge->{'bri'}{'brdev'}] already marked online";
        $status = 1;
    }

    net_db_obj_set("bri", $bridb);
    return ($return, $status);
}

1;
