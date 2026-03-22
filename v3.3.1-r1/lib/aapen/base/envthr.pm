#
# ETHER|AAPEN|LIBS - BASE|ENVTHR
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
use JSON::MaybeXS;
use Exporter::Auto;
use Sys::Hostname;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);

my %envthr: shared;
my $root = "../env/root.cfg";


#
# env init 
#
sub env_init(){
	my $fid = "[env_init]";
	
	$envthr{'version'} = "v3.3.1";
	$envthr{'debug'} = 0;
	$envthr{'verbose'} = 0;
	$envthr{'info'} = 1;
	$envthr{'log'} = 0;
	$envthr{'quote'} = 1;
	$envthr{'daemon'} = 0;
	$envthr{'maintenance'} = 0;
	$envthr{'timezone'} = "UTC";
	$envthr{'sid'} = "env";
	$envthr{'root'} = $root;
}

#
# env get
#
sub env_get(){
	my $fid = "[env_get]";
	my $env = {};
	
	$env->{'version'} = $envthr{'version'};
	$env->{'debug'} = $envthr{'debug'};
	$env->{'verbose'} = $envthr{'verbose'};
	$env->{'info'} = $envthr{'info'};
	$env->{'log'} = $envthr{'log'};
	$env->{'daemon'} = $envthr{'daemon'};
	$env->{'quote'} = $envthr{'quote'};
	$env->{'maintenance'} = $envthr{'maintenance'} ;
	$env->{'timezone'} = $envthr{'timezone'};
	$env->{'sid'} = $envthr{'sid'};
	$env->{'root'} = $envthr{'root'};
	
	return $env;
}

#
# quote
#
sub env_quote(){ return $envthr{'quote'} }
sub env_quote_on(){ $envthr{'quote'} = 1; }
sub env_quote_off(){ $envthr{'quote'} = 0; }
#
# info
#
sub env_info(){ return $envthr{'info'}; };
sub env_info_on(){ $envthr{'info'} = 1; };
sub env_info_off(){ $envthr{'info'} = 0; };

#
# verbose
#
sub env_verbose(){ return $envthr{'verbose'}; };
sub env_verbose_on(){ $envthr{'verbose'} = 1; };
sub env_verbose_off(){ $envthr{'verbose'} = 0; };

#
# debug
#
sub env_debug(){ return $envthr{'debug'}; };
sub env_debug_on(){ $envthr{'debug'} = 1; };
sub env_debug_off(){ $envthr{'debug'} = 0; };

#
# silent mode
#
sub env_silent_on(){
	 env_info_off();
	 env_verbose_off();
	 env_debug_off();
};

#
# daemon mode
#
sub env_daemon(){ return $envthr{'daemon'}; };
sub env_daemon_on(){
	$envthr{'daemon'} = 1;
};

#
# maintenance
#
sub env_maintenance(){ return $envthr{'maintenance'}; };
sub env_maintenance_on(){ $envthr{'maintenance'} = 1; };
sub env_maintenance_off(){ $envthr{'maintenance'} = 0; };

#
# version
#
sub env_version(){ return $envthr{'version'}; }
sub env_version_get(){ return $envthr{'version'}; }
sub env_version_set($ver){ $envthr{'version'} = $ver; }

#
# timezone
#
sub env_timezone_get(){ return $envthr{'timezone'}; }
sub env_timezone_set($tz){ $envthr{'timezone'} = $tz; }

#
# sid
#
sub env_sid(){ return $envthr{'sid'}; }
sub env_sid_get(){ return $envthr{'sid'}; }
sub env_sid_set($sid){ $envthr{'sid'} = $sid; }

#
# root
#
sub env_root(){ return $envthr{'root'}; }
sub env_root_get(){ return $envthr{'root'}; }
sub env_root_set($rootenv){ $envthr{'root'} = $rootenv; }

sub env_get_root(){
	return `/bin/cat $root | tr -d '\n'`;
}

#
# get hostname [STRING]
#
sub env_hostname(){
	return hostname();
}

#
# return base root [PATH]
#
sub env_base_get(){
	return "/aapen/";
}

#
# reutnr service sockets [STRING]
#
sub env_serv_sock_get($service){
	my $fid = "[env_serv_sock_get]";
	my $root = "/aapen/socket/";

	if($service eq "cdb"){ return $root . "cdb.sock" };
	if($service eq "cluster"){ return $root . "cluster.sock" };
	if($service eq "element"){ return $root . "element.sock" };
	if($service eq "hypervisor"){ return $root . "hypervisor.sock" };
	if($service eq "framework"){ return $root . "framework.sock" };
	if($service eq "monitor"){ return $root . "monitor.sock" };
	if($service eq "network"){ return $root . "network.sock" };
	if($service eq "storage"){ return $root . "storage.sock" };
}

#
# update cluster env encoded [JSON]
#
sub env_update_encode($req){
	my $env = json_decode($req);
	my $result = env_update($env);
	return json_encode($result);
}

#
# update cluster env [JSON]
#
sub env_update($req){
	my $fid = "[env_update]";

	if($req->{'env'} eq "silent"){
		print "$fid silent requested\n";
		env_debug_off();
		env_verbose_off();
		env_info_off();
	}

	if($req->{'env'} eq "info"){
		print "$fid info requested\n";
		env_info_on();
	}
	
	if($req->{'env'} eq "verbose"){
		print "$fid verbose requested\n";
		env_info_on();
		env_verbose_on();
	}
	
	if($req->{'env'} eq "debug"){
		print "$fid debug requested\n";
		env_info_on();
		env_verbose_on();
		env_debug_on();
	}

	if($req->{'env'} eq "maintenance_on"){
		print "$fid maintenance on requested\n";
		env_maintenance_on;
	}

	if($req->{'env'} eq "maintenance_off"){
		print "$fid maintenance off requested\n";
		env_maintenance_off;
	}
	
	my $return = packet_build_noencode("1", "success: cluster env updated", $fid);
	$return = env_get();
	
	# this one should not encode! TODO
	return json_encode($return);
}

1;
