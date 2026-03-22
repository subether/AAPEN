#
# ETHER|AAPEN|LIBS - BASE|FILE
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
use Filesys::DiskUsage::Fast qw(du);
use Data::Dumper;
use File::Find;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# dir file list [ARRAY]
#
sub file_list($path, $type){
	my $ffid = "BASE|FILE|LIST";
	my @files = glob( $path . $type );
	log_debug($ffid, "path [$path] type [$type] files [@files]");
	return @files;
}

#
# delete file [STRING/BOOLEAN]
#
sub file_del($filename){
	my $ffid = "BASE|FILE|DEL";
	
	# remove file
	log_warn($ffid, "removing file [$filename]");
	
	my $exec = "rm $filename";
	my $return = `$exec`;
	return $return;
}

#
# check for file [BOOLEAN]
#
sub file_check($file){
	my $ffid = "BASE|FILE|CHECK";
	my $result = 0;

	if (-e $file) {
		log_debug($ffid, "file [$file] exists");
		$result = 1;
	} else {
		log_debug($ffid, "file [$file] does not exist");
	}	
	return $result;
}

#
# check for file [BOOLEAN]
#
sub file_size($file){
	my $fid = "BASE|FILE|SIZE";
	my $result = 0;

	if(file_check($file)){
		return (-s $file);
	}
	else{
		return 0;
	}
}

#
# tail file
#
sub file_tail($file, $num){
	my $exec = "tail -n $num $file";
	my $result = execute($exec);
	return $result;
}

#
# check for dir [BOOLEAN]
# 
sub dir_check($dir){
	my $ffid = "BASE|DIR|CHECK";
	
	my $result = 0;
	if (-d $dir) {
		log_debug($ffid, "dir [$dir] exists");
		$result = 1;
	} else {
		log_debug($ffid, "dir [$dir] does not exist");
	}	
	return $result;
}

#
# create dir [BOOLEAN]
#
sub dir_create($dir){
	my $fid = "BASE|DIR|CREATE";
	my $result = 0;
	
	# execute
	my $exec = "mkdir -p $dir";
	log_debug($fid, "exec [$exec]");
	my $return = execute($exec);

	# check result
	if($return){
		log_error($fid, "operation failed. result [$return]");
	}
	else{
		log_debug($fid, "operation successful. result [$return]");
		$result = 1;
	}
	
	return $result;
}

#
# create dir [BOOLEAN]
#
sub dir_remove($dir){
	my $fid = "BASE|DIR|REMOVE";
	my $result = 0;
	
	# execute
	my $exec = "rmdir $dir";
	log_warn($fid, "removing diretory [$dir]");
	my $return = execute($exec);

	# check result
	if($return){
		log_debug($fid, "operation failed. dir [$dir] removed. result [$return]");
	}
	else{
		log_debug($fid, "operation successful. dir [$dir] removed. result [$return]");
		$result = 1;
	}
	
	return $result;
}

#
# append slash 
#
sub dir_slash($dir){
	my $fid = "BASE|DIR|SLASH";
	my $end = substr($dir, -1);
	log_debug($fid, "dir [$dir] end char [$end]");
	
	if($end ne "/"){ $dir = $dir . "/"; };	
	return $dir;
}

#
# directory size bytes [INT]
#
sub dir_size($dir){
	my $fid = "BASE|DIR|SIZE";
	my $size = du($dir);
	log_debug($fid, "dir [$dir] size [$size]");
	return $size;	
}

#
# directory size kb [INT]
#
sub dir_size_kb($dir){
	my $size = dir_size($dir);
	return $size >> 10;
}

#
# directory size mb [INT]
#
sub dir_size_mb($dir){
	my $size = dir_size_kb($dir);
	return $size >> 10;
}

#
# directory size gb [INT]
#
sub dir_size_gb($dir){
	my $size = dir_size_mb($dir);
	return $size >> 10;
}

1;
