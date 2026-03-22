#
# ETHER|AAPEN|LIBS - BASE|DBSHARE
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
use threads::shared;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);

# shared data
my %dbshare :shared;


#
# get dbshare
#
sub dbshare_get(){
	{
		lock(%dbshare);
		return %dbshare;
	}
}

#
# set dbshare
#
sub dbshare_set(%db){
	{
		lock(%dbshare);
		%dbshare = %db;
	}
}

1;
