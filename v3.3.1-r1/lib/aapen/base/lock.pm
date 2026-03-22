#
# ETHER|AAPEN|LIBS - BASE|LOCK
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

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# check lockfile [BOOLEAN]
#
sub lockfile_check($filename){
	my $fid = "[lockfile_check]";
	my $lock;	
	
	# check for lockfile
	if(env_verbose()){ print "$fid lockfile [$filename.lock] "; };
	if( -e "$filename.lock"){	
		if(env_verbose()){print "found!\n";};
		$lock = 1;
	}
	else{
		if(env_verbose()){print "not found.\n";};
		$lock = 0;
	}
	
	return $lock;	
}

#
# add lockfile [BOOLEAN]
#
sub lockfile_add($filename){
	my $fid = "[lockfile_add]";
	
	# create lockfile
	log_info($fid, "adding lockfile [$filename].lock");
	my $exec = "touch $filename.lock";
	my $return = `$exec`;
	return $return;	
}

#
# remove lockfile [BOOLEAN]
#
sub lockfile_del($filename){
	my $fid = "[lockfile_del]";
	
	# delete lockfile
	log_info($fid, "removing lockfile [$filename].lock");
	my $exec = "rm $filename.lock";
	my $return = `$exec`;
	return $return;
}

1;
