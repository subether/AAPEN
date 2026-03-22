#
# ETHER|AAPEN|LIBS - BASE|INDEX
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
# add to index [INDEX]
#
sub index_add($index, $value){
	my $fid = "[index_add]";	
	my $idx;
	my $dup = 0;
	my @index_ar = index_split($index);

	# check for duplicates
	 foreach my $index_id (@index_ar){
		if($index_id eq $value){ 
			$dup = 1;
		}
	}
	
	# check for empty index
	if(!$index && $index ne "0"){
		$idx = $value;
	}
	else{
		if($value eq ""){
			if(env_verbose()){ print "$fid warning: received empty value [$value]!\n"; };
		}
		else{
			# index is defined
			if($dup){
				if(env_debug()){ print "$fid warning: duplicate entry for [$value] found!\n"; };
				$idx = $index;
			}
			else{
				$idx = $index . ";" . $value;
			}
		}
	}	
	
	return $idx;
}

#
# delete from index [INDEX]
#
sub index_del($idxlist, $value){
	my $fid = "[index_del]";
	my $i = 0;
	my $index_buf = "";
	my @index_ar = index_split($idxlist);
		
	# search index for matching value
	foreach my $index (@index_ar){	
		if($value eq $index) { 
			if(env_debug()){ print " $fid found value [$value], pos [$index], count [$i]\n"; }; }
		else{
			if(!$index_buf && $index_buf ne "0"){
				$index_buf = $index;			
			} 
			else{
				# index is undefined
				$index_buf = $index_buf . ";" . $index;
			};
		}
		$i++;		
	}	
	
	return $index_buf;
}

#
# find in index [BOOLEAN]
#
sub index_find($index, $value){
	my $fid = "[index_find]";
	my $result = 0;
	my $idx;

	# check if index is empty
	if(!$index && $index ne "0"){
		$result = 0;
	}
	else{
		# index is defined
		my @index_ar = index_split($index);
		
		# search index for value
		foreach $idx (@index_ar){	
			if($value eq $idx) {
				$result = 1; 
			};
		}	
	}	
	
	return $result;	
}

#
# get next free index [NUMBER]
#	
sub index_free($index, $offset){
	my $fid = "[index_free]";
	my $i = $offset;

	# check for empty index
	if(!$index && $index ne "0"){
		$i = $offset;
	}
	else{
		# find a free index
		while(&index_find($index, $i)){
			$i++;
		}
	}	
	
	return $i;
}

#
# return index array [STRING]
#
sub index_split($index_str){
	my $fid = "[index_split]";
	my @index = split(/;/, $index_str);
	return @index;
}

1;
