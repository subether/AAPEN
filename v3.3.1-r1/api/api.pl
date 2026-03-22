#
# ETHER|AAPEN|API - MAIN
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
use IO::Socket::INET;
use JSON::MaybeXS;
use TryCatch;
use Term::ANSIColor qw(:constants);
use Time::HiRes qw(usleep nanosleep);
use File::Copy;
use Mojolicious::Lite;
use Mojo::File qw(path);

# ROOT
my $root;
BEGIN { 
	$root = `/bin/cat ../env/root.cfg | tr -d '\n'`;
	print "[init] root [$root]\n";
};
use lib $root . "lib/";

# base
use aapen::base::envthr;
use aapen::base::date;
use aapen::base::json;
use aapen::base::file;
use aapen::base::exec;
use aapen::base::index;
use aapen::base::string;
use aapen::base::config;
use aapen::base::log;

use aapen::net::mac;

# protocol
use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;
use aapen::proto::ssl;

use aapen::api::protocol;

# hypervisor
use aapen::api::hypervisor::lib;

# cluster
use aapen::api::cluster::lib;
use aapen::api::cluster::local;

# protocol
require './lib/protocol_rest.pm';

# rest
require './lib/rest/rest.lib.pm';
require './lib/rest/rest.system.lib.pm';
require './lib/rest/rest.node.lib.pm';
require './lib/rest/rest.network.lib.pm';
require './lib/rest/rest.storage.lib.pm';
require './lib/rest/rest.element.lib.pm';
require './lib/rest/rest.service.lib.pm';


# ENV
env_init();
env_sid_set("api");
env_version_set("v3.3.1");

# CONFIG
my $api_config = config_init();
json_encode_pretty($api_config);

# VARS
my $round = 0;
my $tick_us = 10000;
my $cluster_enabled = 1;


#
# init flags
#
foreach my $flags (@ARGV){
	if($flags eq "verbose"){ env_verbose_on() };
	if($flags eq "info"){ env_info_on() };
	if($flags eq "debug"){ env_debug_on() };
	if($flags eq "silent"){ env_silent_on() };
}

print "AAPEN API version [", BOLD BLACK, env_version(), RESET, "] ", BOLD BLACK, "REST", RESET, " listening on [", BOLD BLACK, config_base_rest_api_proto() . "://" . config_base_rest_api_listen() . ":" . config_base_rest_api_port(), RESET, "]\n";


# INIT REST
rest_api();

while(1){
	sleep 5;
}

