#
# ETHER|AAPEN|LIBS - PROTO|PACKET
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
use IO::Socket::UNIX qw( SOCK_STREAM );

use Crypt::URandom qw(urandom);
use Crypt::Mac::HMAC qw(hmac);
use Crypt::KeyDerivation qw(pbkdf2);
use Crypt::PBKDF2;


# Shared secret key (should be configured externally)
my $pbkdf2 = Crypt::PBKDF2->new(
    hash_class => 'HMACSHA2',
    hash_args => {
        sha_size => 256,
    },
    iterations => 10000,
    output_len => 32
);
our $HMAC_KEY = $pbkdf2->PBKDF2('letmein', urandom(16));

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# packet header [JSON-OBJ]
#
sub packet_head_build($caller){
	my $packet;
	$packet->{'proto'}{'pass'} = config_base_api_key();
	$packet->{'proto'}{'date'} = date_get();
	$packet->{'proto'}{'packet'} = $caller;
	return $packet
}

#
# build and encode packet [JSON-STR]
#
sub packet_build_encode($result, $string, $module){
	my $fid = "[packet_build]";
	my $packet = packet_build_noencode($result, $string, $module);	
	return json_encode($packet);
}

#
# build packet with no encoding [JSON-OBJ]
#
sub packet_generate_hmac($data){
    my $fid = "[packet_generate_hmac]";
    my $hmac_bin = hmac('SHA256', $HMAC_KEY, json_encode($data));
    return unpack("H*", $hmac_bin);
}

#
# validate packet HMAC [BOOL]
#
sub packet_validate_hmac($packet){
    my $fid = "[packet_validate_hmac]";
    print "$fid validating packet HMAC\n";
    
    # extract received HMAC
    my $received_hmac = delete $packet->{'proto'}{'hmac'};
    unless($received_hmac) {
        log_error($fid, "missing HMAC in packet!");
        return 0;
    }

    # compute hmac
    my $computed_hmac = packet_generate_hmac($packet);
    
    # convert hex to binary
    my $received_bin = pack("H*", $received_hmac);
    my $computed_bin = pack("H*", $computed_hmac);
    
    # constant-time comparison
    if(hmac('SHA256', $HMAC_KEY, $received_bin) ne 
       hmac('SHA256', $HMAC_KEY, $computed_bin)) {
        log_error($fid, "HMAC validation failed");
        return 0;
    }
    else{
        log_debug($fid, "HMAC validation successful");
	}

    # check timestamp
    my $current_time = time();
    if(abs($current_time - $packet->{'proto'}{'timestamp'}) > 10) {
        log_error($fid, "timestamp mismatch!");
        return 0;
    }
    else{
        log_info($fid, "timestamp match sucessful");
		print "$fid success:: timestamp match succcsess\n";
	}

    return 1;
}

#
# build packet without encoding [JSON-OBJ]
#
sub packet_build_noencode($result, $string, $module){
    my $fid = "[packet_build]";

    my $packet;
    $packet->{'proto'}{'timestamp'} = time();
    $packet->{'proto'}{'date'} = date_get();
    $packet->{'proto'}{'useq'} = int(rand(10000000));
    $packet->{'proto'}{'version'} = env_version();
    $packet->{'proto'}{'fid'} = $module;
    $packet->{'proto'}{'result'} = $result;
    $packet->{'proto'}{'string'} = $string;
    $packet->{'proto'}{'service'} = env_sid();
    $packet->{'proto'}{'node'} = config_node_name_get();
    return $packet;
}


1;
