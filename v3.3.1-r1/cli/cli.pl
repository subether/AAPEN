#
# ETHER|AAPEN|CLI - MAIN
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
use Term::ShellUI;
use Term::ANSIColor qw(:constants);

# ROOT
my $root;
BEGIN { 
	$root = `/bin/cat ../../../env/root.cfg | tr -d '\n'`;
	print "[init] root [$root]\n";
};
use lib $root . "lib/";

# LIB
use aapen::base::envthr;
use aapen::base::date;
use aapen::base::json;
use aapen::base::file;
use aapen::base::exec;
use aapen::base::index;
use aapen::base::string;
use aapen::base::config;
use aapen::base::log;

use aapen::proto::socket;
use aapen::proto::packet;

use aapen::net::mac;

use aapen::api::external::mikrotik;

use aapen::api::cdb::local;
use aapen::api::cluster::local;
use aapen::api::storage::local;
use aapen::api::element::local;

# Helper function to build CLI error responses
sub _build_cli_error($fid, $ffid, $message) {
	print BOLD RED, "error: $message", RESET, "\n";
	log_warn($ffid, $message);
	return 0;
}

# Helper function to build CLI success responses
sub _build_cli_success($message) {
	print BOLD GREEN, "success: $message", RESET, "\n";
	return 1;
}

# Helper function to print CLI info
sub _cli_info($ffid, $message) {
	print BOLD BLUE, "info: $message", RESET, "\n";
	log_info($ffid, $message);
}

# api
require './lib/api/api.cmd.pm';
require './lib/api/api.lib.pm';

# system
require './lib/system/system.cmd.pm';
require './lib/system/system.rest.lib.pm';

# legacy
#require './lib/system/sys.lib.pm';

# node
require './lib/node/node.cmd.pm';
require './lib/node/node.lib.pm';
require './lib/node/node.rest.lib.pm';

require './lib/node/node.monitor.lib.pm';
require './lib/node/node.storage.lib.pm';
require './lib/node/node.framework.lib.pm';
require './lib/node/node.network.lib.pm';
require './lib/node/node.hypervisor.lib.pm';
require './lib/node/node.cluster.lib.pm';
require './lib/node/node.cdb.lib.pm';

# network
require './lib/network/network.cmd.pm';
require './lib/network/network.rest.lib.pm';

# storage
require './lib/storage/storage.cmd.pm';
require './lib/storage/storage.rest.pm';

# cluster
require './lib/cluster/cluster.cmd.pm';
require './lib/cluster/cluster.lib.pm';

# cdb
require './lib/cdb/cdb.cmd.pm';
require './lib/cdb/cdb.lib.pm';

# storage
require './lib/element/element.cmd.pm';
require './lib/element/element.rest.pm';

# monitor
require './lib/monitor/monitor.cmd.pm';
require './lib/monitor/monitor.lib.pm';

# rest common
require './lib/rest/rest.lib.pm';

# ENV
env_sid_set("CLI");
env_version_set("v3.3.1");
log_init();

# CONFIG
my $cli_config = config_init();
#json_encode_pretty($cli_config);

# VARS
my $interrupt = 1;
my $term;

# INIT
initialize();


#
# init cli
#
sub cli_init(){
	
	# initialize base cli
	$term = new Term::ShellUI(
		commands => {
			"quote" => {
				desc => "Show a fortune.",
				proc => sub {&quote()}
			},	
		},
		
		# configure history      
		history_file => ".history",
	);

	# catch interrupts
	if($interrupt){$SIG{'INT'} = sub {&cli_interrupt()}}
	else{$SIG{'INT'} = sub {die;}};
}

#
# populate cli
#
sub cli(){
	
	$term->prompt(['AAPEN> ']);
	quote();
	
	$term->commands(cli_base($term));

	$term->add_commands(api_cmd());

	$term->add_commands(system_cmd());

	$term->add_commands(node_cmd());
	
	$term->add_commands(net_cmd());

	$term->add_commands(stor_cmd());
	
	$term->add_commands(cluster_cmd());

	$term->add_commands(cdb_cmd());

	$term->add_commands(element_cmd());

	$term->add_commands(monitor_cmd());

	$term->add_commands(rest_cmd());

	version();
 	$term->run();	 	
}

sub version(){
	print BOLD BLACK, "Infected Technologies AAPEN Command Line Interface", RESET, "\n";
	print BOLD BLUE, "infectedtech <.no><.com>.net><.org><.info> || ether.no", RESET, "\n\n";
	print "Software Version [" . env_version() . "]\n\n";
	print "AAPEN licensed under the GNU AGPL Version 3+\n";
	print "Copyright (c) Infected Technologies 2010 - 2025\n\n"; 
}

sub help(){
	print "AAPEN CLI help screen:\n";
	print "<TAB> autocompletes, <ENTER> shows sub-menu and action descriptions\n";
	print "For more information maybe try readme.txt (if it exists) or consult software user manual (if its written)\n\n";
}

sub quote(){
	my $quote = `fortune 2>&1`;
	print "\n$quote\n";
}

sub quit($term){
	print BOLD, "cli received quit!", RESET, "\n\n";
	quote();
	$term->exit_requested(1);
}

sub cli_interrupt(){
	print BOLD RED, " caught interrupt!", RESET, " press enter to resume, or enter 'die' to die.\n";
	my $input = <>;
	if ($input =~ "die" ){	die;}; 
}

sub cli_verify($phrase){
	my $true = 0;
	print BOLD,  "\nThis action requires verification!", RESET, " enter [$phrase] to execute: ";
	my $answer = <>;
	chomp($answer);
	if($answer eq $phrase) {print "  \n"; $true = 1};
	return $true;
}

#
# command line base commands
#
sub cli_base($term){
	
	return {
		"quote" => {
			desc => "Show a fortune.",
			proc => sub { quote() }
		},	
		
		"version" => {
			desc => "Show version information.",
			proc => sub { version() }
		},
		
		"quit" => {
			desc => "Quit this program", maxargs => 0,
			method => sub { quit($term) },
		},
		
		"help" => {
			desc => "Show help.",
			proc => sub { help() }
		},
		
		"reload" => {
			desc => "Reload CLI",
			proc => sub { cli() }
		},
		
		"initialize" => {
			desc => "Initialize databases",
			proc => sub { initialize() }
		},
		
		"history" => { 
			desc => "Prints the command history",
			doc => "Specify a number to list the last N lines of history" .
			"Pass -c to clear the command history, " .
			"-d NUM to delete a single item\n",
			args => "[-c] [-d] [number]",
			method => sub { shift->history_call(@_) },
		},			
	};
}

#
# set prompt
#
sub cli_prompt($string){
	$term->prompt($string);
	$term->run();
}

#
# reinitialize cli
#
sub cli_reinit(){
	cli_base($term);
	cli();	
}

#
# return terminal
#
sub cli_term(){
	return $term;
}

#
# initialize configuration
#
sub initialize(){
	print BOLD, "[initializing]", RESET, "\n\n";
	cli_init();
	cli();
}
