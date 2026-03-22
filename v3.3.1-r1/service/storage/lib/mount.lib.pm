#
# ETHER - AAPEN - STORAGE - MOUNT LIB
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
# check if mounted [BOOL]
#
sub mount_check($mount){
	my $fid = "MOUNT|CHECK";
	
	log_debug($fid, "mount [$mount]");
	my $exec = 'mount | grep "' . $mount . '"';	
	my $exec_result = `$exec`;
	
	if($exec_result){ return 1; }
	else{ return 0; }
}

#
# device size info [JSON-OBJ]
#
sub mount_size_info($mount){
	my $fid = "MOUNT|SIZE|INFO";
	my $size = {};
	
	# get df output
	my $ref = df($mount); # 1K blocks
	
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
		log_debug($fid, "sizedata");
		json_encode_pretty($size);
	}
	
	return $size;
}

1;
