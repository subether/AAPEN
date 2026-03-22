#
# ETHER|AAPEN|LIBS - PROTO|PROTOCOL
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
use Exporter::Auto;
use JSON::MaybeXS;
use TryCatch;
use IO::Socket::UNIX qw( SOCK_STREAM );

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# processing [JSON-OBJ]
#
sub auth($packet, $s_id){
	my $fid = "[auth]";
	my $err = "";
	my $result = 0;

	log_debug($fid, "authenticating session [$s_id]");
   
	try{
		# analyze input data 
		my ($analyze, $data) = analyze($packet);
		if($analyze){
			
			# check authentication header
			my $auth = authenticate($data);	
					
			if($auth){
				# authenticated, pass to protocol
				$result = packet_build_noencode("1", "success: client authorized", $fid);
			}
			else{
				# authentication failed, but data is valid..
				log_warn($fid, "warning: s_id [$s_id] error: packet valid, but unauthorized!");
				$result = packet_build_noencode("0", "error: client unauthorized!", $fid);
			}
		}
		else{
			# packet analyze failed, invalid or corrupt data
			log_warn($fid, "warning: s_id [$s_id] error: packet analyzing failed!");
			$result = packet_build_noencode("0", "error: packet analyzing failed!", $fid);
		}
	}
	catch{
		# preprocessing failed, likely garbage
		log_warn($fid, "warning: s_id [$s_id] error: packet preprocessing failed!");
		$result = packet_build_noencode("0", "error: packet preprocessing failed!", $fid);
	}
	
	return $result;
}

#
# authenticate packet [JSON-OBJ]
#
sub authenticate($packet){
    my $fid = "[authenticate]";
    my $result = 0;
    
    # Legacy authentication
    if($packet->{'proto'}{'pass'} eq config_base_api_key()) {
        $result = 1;
    }
    else{
        print "$fid authentication failed!\n";
    }
    
    return $result;
}

#
# authenticate packet [JSON-OBJ]
#
sub authenticate_hmac($packet){
    my $fid = "[authenticate]";
    my $result = 0;
    
    # First validate HMAC if present
    if(exists $packet->{'proto'}{'hmac'}) {
		if(packet_validate_hmac($packet)){
			 print "$fid success: HMAC validation successful\n";
		}
		else{
			 print "$fid error: HMAC validation failed\n";
		}
		
        unless(packet_validate_hmac($packet)) {
            print "$fid error: HMAC validation failed\n";
            return 0;
        }
    }
    
    # Legacy authentication fallback
    if($packet->{'proto'}{'pass'} eq config_base_api_key()) {
        $result = 1;
    }
    elsif(env_debug()) {
        print "$fid authentication failed\n";
    }

    return $result;
}

#
# analyze packet [JSON-OBJ]
#
sub analyze($string){
    my $fid = "[analyze]";
    my $result = 0;
    my $json;

    # attempt to process input
    if(env_debug()){ print "$fid processing [$string]\n"; };
    try{
        # strip input terminators
        $string =~ s/\R//g;
    
        # decode json
        $json = decode_json($string);
        
        # Validate basic packet structure
        unless(ref $json eq 'HASH' && exists $json->{'proto'}) {
            print "$fid error: invalid packet structure";
			$result = 0;
        }

        if(env_debug()){ print "$fid json payload decoded successfully\n"; };
        $result = 1;
    }
    catch{
        if(env_debug()){ print "$fid error: $_\n"; };
        $result = 0;
    }
    
    return ($result, $json);
}

#
# analyze packet [JSON-OBJ]
#
sub analyze_hmac($string){
    my $fid = "[analyze]";
    my $result = 0;
    my $json;

    # attempt to process input
    if(env_debug()){ print "$fid processing [$string]\n"; };
    try{
        # strip input terminators
        $string =~ s/\R//g;
    
        # decode json: TODO
        $json = decode_json($string);
        
        # Validate basic packet structure
        unless(ref $json eq 'HASH' && exists $json->{'proto'}) {
            print "$fid error: invalid packet structure";
			$result = 0;
        }

        # Additional validation for new HMAC packets
        if(exists $json->{'proto'}{'hmac'}) {
			print "$fid success: packet contains HMAC fields\n";
			
			if(exists $json->{'proto'}{'timestamp'} && exists $json->{'proto'}{'nonce'}) {
				print "$fid success: packet contains all HMAC requires fields!\n";
			}
			else{
				#print "$fid error: packet missing required HMAC fields\n";
			}
			
            #unless(exists $json->{'proto'}{'timestamp'} && exists $json->{'proto'}{'nonce'}) {
             #   print "$fid error: missing required HMAC fields\n";
				#$result = 0;
            #}
        }
        else{
			#print "$fid error: packet missing HMAC fields\n";
		}

        if(env_debug()){ print "$fid json payload decoded successfully\n"; };
        $result = 1;
    }
    catch{
        if(env_debug()){ print "$fid error: $_\n"; };
        $result = 0;
    }
    
    return ($result, $json);
}

#
# add timer [JSON-STR]
#
sub protocol_add_time($json, $time){
	my $fid = "[protocol_add_time]";
	my $result = json_decode($json);
	$result->{'time_us'} = $time;
	return json_encode($result);
}

1;
