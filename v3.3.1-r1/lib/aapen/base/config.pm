#
# ETHER|AAPEN|LIBS - BASE|CONFIG
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
use Term::ANSIColor qw(:constants);
use JSON::MaybeXS;
use Sys::Hostname;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


my $base_config = {};
my $node_config = {};

my $base_obj_index = "system;node;network;container;storage;service;element;config";
my $base_srv_index = "hypervisor;network;framework;monitor;storage;api;agent;element;cdb";

#
# BASE CONFIG
#

#
# validate id [BOOL]
#
sub config_validate_id($id){
	if(defined $id && $id =~ /^\d+$/){ return 1; }
	else{ return 0; };
}

#
# validate name [BOOL]
#
sub config_validate_name($name){
	if(defined $name && length($name) <= 16){ return 1; }
	else{ return 0; };
}

#
# get base services [STRING]
#
sub config_base_service_get(){
	return $base_srv_index;
}

#
# get base objects [STRING]
#
sub config_base_object_get(){
	return $base_obj_index;
}

#
# validate service name [BOOL]
#
sub config_base_service_validate($service){
	if(index_find($base_srv_index, $service)){ return 1; }
	else{ return 0; };
} 

#
# validate object type [BOOL]
#
sub config_base_object_validate($object){
	if(index_find($base_obj_index, $object)){ return 1; }
	else{ return 0; };
} 

#
# return base config [JSON-OBJ]
#
sub config_base_get(){
	return $base_config;
}

#
# SSL
#
sub config_base_ssl_ca_get(){
	return env_base_get() . "config/cert/" . $base_config->{'base'}{'ssl'}{'ca'};
}
sub config_base_ssl_cert_get(){
	return env_base_get() . "config/cert/" . $base_config->{'base'}{'ssl'}{'cert'};
}
sub config_base_ssl_key_get(){
	return env_base_get() . "config/cert/" . $base_config->{'base'}{'ssl'}{'key'};
}

#
# API
#
sub config_base_api_key(){
	return $base_config->{'base'}{'api'}{'key'};
}
sub config_base_api_port(){
	return $base_config->{'base'}{'ports'}{'api'}{'port'};
}
sub config_base_api_address(){
	#return $base_config->{'base'}{'ports'}{'api'}{'address'};
	return "127.0.0.1";
}

#
#
#
sub config_base_rest_api_port(){
	return $base_config->{'base'}{'ports'}{'rest'}{'port'};
}
sub config_base_rest_api_listen(){
	return $base_config->{'base'}{'ports'}{'rest'}{'listen'};
}
sub config_base_rest_api_proto(){
	return $base_config->{'base'}{'ports'}{'rest'}{'proto'};
}

#
# get agent port
#
sub config_base_agent_port(){
	return $base_config->{'base'}{'ports'}{'agent'}{'port'};
}

#
# initialize base config [BOOL]
#
sub config_base_init(){
	#my $fid = "[config_base_init]";
	my $fid = "BASE|CONFIG|BASE|INIT";
	my $host = hostname_get();
	my $base = env_base_get();
	
	my $base_config_file = env_base_get() . "config/base/base.cfg.json";
	
	# check for config file
	if(file_check($base_config_file)){
		log_debug($fid, "base config [$base_config_file] exists");
		
		my $base_config_tmp = json_file_load($base_config_file);
		
		# validate config
		if(config_base_validate($base_config_tmp)){
			# base config valid
			$base_config = $base_config_tmp;
		}
		else{
			# base config invalid
			log_error($fid, "base config [$base_config_file] invalid!");
			die;
		}
	}
	else{
		# base config exists
		log_error($fid, "base config [$base_config_file] not found!");
		return 0;
	}
}

#
# validate base config [BOOL]
#
sub config_base_validate($base_config){
	my $fid = "[config_base_validate]";
	my $ffid = "BASE|CONFIG|VALIDATE";
	my $valid = 1;

	# ssl
	if(!defined $base_config->{'base'}{'ssl'}{'ca'} || $base_config->{'base'}{'ssl'}{'ca'} eq ""){ $valid = 0; print "$fid SSL CA INVALID\n";  };
	if(!defined $base_config->{'base'}{'ssl'}{'cert'} || $base_config->{'base'}{'ssl'}{'cert'} eq ""){ $valid = 0; print "$fid SSL CERT INVALID\n";};
	if(!defined $base_config->{'base'}{'ssl'}{'key'} || $base_config->{'base'}{'ssl'}{'key'} eq ""){ $valid = 0; print "$fid SSL KEY INVALID\n"; };
	
	# api
	if(!defined $base_config->{'base'}{'api'}{'key'} || $base_config->{'base'}{'api'}{'key'} eq ""){ $valid = 0; print "$fid API KEY\n";};
	
	# socket perms
	if(!defined $base_config->{'base'}{'perms'}{'socket'}{'group'} || $base_config->{'base'}{'perms'}{'socket'}{'group'} eq ""){ $valid = 0; print "$fid SOCKET GROUP PERMS INVALID\n"; };
	if(!defined $base_config->{'base'}{'perms'}{'socket'}{'user'} || $base_config->{'base'}{'perms'}{'socket'}{'user'} eq ""){ $valid = 0; print "$fid SOCKET GROUP PERMS INVALID\n"; };
	
	# vmm perms
	if(!defined $base_config->{'base'}{'perms'}{'vmm'}{'group'} || $base_config->{'base'}{'perms'}{'vmm'}{'group'} eq ""){ $valid = 0; print "$fid PERMS VMM GROUP INVALID\n"; };
	if(!defined $base_config->{'base'}{'perms'}{'vmm'}{'user'} || $base_config->{'base'}{'perms'}{'vmm'}{'user'} eq ""){ $valid = 0; print "$fid PERMS VMM USER INVALID\n"; };
	
	# env
	if(!defined $base_config->{'base'}{'env'}{'debug'} || $base_config->{'base'}{'env'}{'debug'} eq ""){ $valid = 0; print "$fid ENV DEBUG INVALID\n"; };
	if(!defined $base_config->{'base'}{'env'}{'verbose'} || $base_config->{'base'}{'env'}{'verbose'} eq ""){ $valid = 0; print "$fid ENV VERBOSE INVALID\n"; };
	if(!defined $base_config->{'base'}{'env'}{'info'} || $base_config->{'base'}{'env'}{'info'} eq ""){ $valid = 0; print "$fid ENV INFO INVALID\n"; };
	
	# rest
	if(!defined $base_config->{'base'}{'rest'}{'dir'} || $base_config->{'base'}{'rest'}{'dir'} eq ""){ $valid = 0; print "$fid REST DIR INVALID\n"; };
	
	# ports multicast
	if(!defined $base_config->{'base'}{'ports'}{'multicast'}{'port'} || $base_config->{'base'}{'ports'}{'multicast'}{'port'} eq ""){ $valid = 0; print "$fid MC PORT INVALID\n"; };
	if(!defined $base_config->{'base'}{'ports'}{'multicast'}{'group'} || $base_config->{'base'}{'ports'}{'multicast'}{'group'} eq ""){ $valid = 0; print "$fid MC PORT INVALID\n"; };
	
	# ports agent
	if(!defined $base_config->{'base'}{'ports'}{'agent'}{'port'} || $base_config->{'base'}{'ports'}{'agent'}{'port'} eq ""){ $valid = 0; print "$fid AGENT PORT INVALID\n"; };
	
	# ports zmq
	if(!defined $base_config->{'base'}{'ports'}{'zmq'}{'port'} || $base_config->{'base'}{'ports'}{'zmq'}{'port'} eq ""){ $valid = 0; print "$fid ZMQ PORT INVALID\n"; };
	if(!defined $base_config->{'base'}{'ports'}{'zmq'}{'pub'} || $base_config->{'base'}{'ports'}{'zmq'}{'pub'} eq ""){ $valid = 0; print "$fid ZMQ PUBLISHER INVALID\n"; };
	if(!defined $base_config->{'base'}{'ports'}{'zmq'}{'sync'} || $base_config->{'base'}{'ports'}{'zmq'}{'sync'} eq ""){ $valid = 0; print "$fid ZMQ SYNC INVALID\n"; };
	
	#print "$fid valid [$valid]\n";
	log_info($ffid, "configuration validation checks successful");
	return $valid;
}

#
# return system cfg params [JSON-OBJ]
#		
sub base_system_cfg_get(){
	my $cfg = {};
	$cfg->{'dir'} = env_base_get() . "config/object/system/";
	$cfg->{'type'} = ".sys.json";
	return $cfg;
}
	
#
# return node cfg params [JSON-OBJ]
#		
sub base_node_cfg_get(){
	my $cfg = {};
	$cfg->{'dir'} = env_base_get() . "config/object/node/";
	$cfg->{'type'} = ".node.json";
	return $cfg;
}

#
# return node cfg params [JSON-OBJ]
#		
sub base_network_cfg_get(){
	my $cfg = {};
	$cfg->{'dir'} = env_base_get() . "config/object/network/";
	$cfg->{'type'} = ".net.json";
	return $cfg;
}

#
# return node cfg params [JSON-OBJ]
#		
sub base_storage_cfg_get(){
	my $cfg = {};
	$cfg->{'dir'} = env_base_get() . "config/object/storage/";
	
	$cfg->{'iso'}{'dir'} = $cfg->{'dir'} . "iso/";
	$cfg->{'iso'}{'type'} = ".iso.json";
	
	$cfg->{'device'}{'dir'} = $cfg->{'dir'} . "device/";
	$cfg->{'device'}{'type'} = ".dev.json";
	
	$cfg->{'pool'}{'dir'} = $cfg->{'dir'} . "pool/";
	$cfg->{'pool'}{'type'} = ".pool.json";

	return $cfg;
}

#
# return node cfg params [JSON-OBJ]
#		
sub base_element_cfg_get(){
	my $cfg = {};
	$cfg->{'dir'} = env_base_get() . "config/object/element/";
	
	$cfg->{'device'}{'dir'} = $cfg->{'dir'} . "device/";
	$cfg->{'device'}{'type'} = ".device.json";

	$cfg->{'service'}{'dir'} = $cfg->{'dir'} . "service/";
	$cfg->{'service'}{'type'} = ".service.json";
	
	return $cfg;
}

#
# return node cfg params [JSON-OBJ]
#		
sub base_cluster_cfg_get(){
	my $cfg = {};
	$cfg->{'dir'} = env_base_get() . "config/object/cluster/";
	$cfg->{'type'} = ".cluster.json";
	return $cfg;
}

#
# return node cfg params [PATH]
#		
sub base_log_dir_get(){
    #my $logdir = env_base_get() . "log/" . env_hostname() . "/";
    my $logdir = env_base_get() . "log/";
    return $logdir;
}

#
# return node cfg params [PATH]
#		
sub base_log_file_get(){
    my $logdir = base_log_dir_get();
	my $logfile = $logdir . lc(env_sid_get()) . ".log";
    return $logfile;
}

#
# NODE
#

#
# return base name [STRING]
#
sub config_node_name_get(){
	return $node_config->{'node'}{'id'}{'name'};
}

#
# return base id [INT]
#
sub config_node_id_get(){
	return $node_config->{'node'}{'id'}{'id'};
}

#
# get node config [JSON-OBJ]
#
sub config_node_get(){
	return $node_config->{'node'};
}

#
# get node config [JSON-OBJ]
#
sub config_node_network_get(){
	return $node_config->{'node'}{'network'};
}

#
# get node config [JSON-OBJ]
#
sub config_node_addr_get(){
	return $node_config->{'node'}{'host'}{'address'};
}

#
# get config [JSON-OBJ]
#
sub config_get(){
	my $config;
	$config->{'base'} = $base_config->{'base'};
	$config->{'node'} = $node_config->{'node'};
	return $config;
}

#
# initialize base config [BOOL]
#
sub config_node_init(){
	my $fid = "[config_node_init]";
	my $ffid = "BASE|CONFIG|NODE|INIT";
	my $host = hostname_get();
	my $base = env_base_get();
	
	my $node_config_file = env_base_get() . "config/base/" . hostname_get() . "/node.cfg.json";
	
	# check for config file
	if(file_check($node_config_file)){
		log_debug($ffid, "node config [$node_config_file] exists");
		
		my $node_config_tmp = json_file_load($node_config_file);
		
		if(config_validate_id($node_config_tmp->{'node'}{'id'}{'id'}) && config_validate_name($node_config_tmp->{'node'}{'id'}{'name'})){
			$node_config = $node_config_tmp;
			log_info($ffid, "success: node config [$node_config_file] initialized");
			return 1;
		}
		else{
			log_error($ffid, "failed: node config [$node_config_file] failed validation");
			die;
			return 0;
			
		}
	}
	else{
		# base config exists
		log_error($ffid, "failed: node config [$node_config_file] not found");
		die;
		return 0;
		
	}
}

#
# NODE CONFIGURATION
#

#
# initialize config [JSON-OBJ]
#
sub config_init(){
	my $fid = "[config_init]";
	my $ffid = "BASE|CONFIG|INIT";
	
	log_info($ffid, "initializing configuration...");
	
	config_base_init();
	config_node_init();
	
	return config_get();
}

#
# initialize config [JSON-OBJ]
#
sub config_state_init($service){
	my $fid = "[config_state_init]";
	my $ffid = "BASE|CONFIG|STATE|INIT";
	config_init();

	# check for state
	my $state_file = config_state_file_get($service);
	log_info($ffid, "initializing state config for [$service]. state file [$state_file]");
	
	# check for state config file
	if(config_state_file_check($service)){
		log_info($ffid, "state file present. initializing...");
		return config_state_load($service);
	}
	else{
		return 0;
	}
}

#
# STATE
#

#
# state config
#
sub config_state_file_get($service){
	my $base = env_base_get();
	my $host = hostname_get();
	return $base . "state/" . $host . "/". $service . ".state.json";
}
sub config_state_dir_get($service){
	my $base = env_base_get();
	my $host = hostname_get();
	return $base . "state/" . $host . "/";
}
sub config_state_file_check($service){
	my $state_file = config_state_file_get($service);
	if(file_check($state_file)){
		return 1;
	}
	else{
		return 0;
	}
	
}

#
# save config state [BOOL]
#
sub config_state_save($service, $state){
	my $fid = "[config_state_save]";
	my $ffid = "BASE|CONFIG|STATE|SAVE";
	
	if(config_base_service_validate($service)){
		my $state_dir = config_state_dir_get($service);
		my $state_file = config_state_file_get($service);
		
		# check and create directory
		if(!dir_check($state_dir)){
			dir_create($state_dir);
		}
		
		my $state_tmp;
		$state_tmp->{$service} = $state;
		json_file_save($state_file, $state_tmp);
	}
	else{
		log_error($ffid, "service [$service] is invalid!");
		return 0;
	}
}

#
# load config state [BOOL], [JSON-OBJ]
#
sub config_state_load($service){
	my $fid = "[config_state_load]";
	my $ffid = "BASE|CONFIG|STATE|LOAD";
	
	if(config_base_service_validate($service)){
		my $state_file = config_state_file_get($service);
		log_info($ffid, "service [$service] state file [$state_file]");
		
		# check if file exists
		if(file_check($state_file)){
			log_info($ffid, "service [$service] state file exists");
			my $state = json_file_load($state_file);
			json_encode_pretty($state);
			return $state;
		}
		else{
			log_info($ffid, "service [$service] state file does not exist");
			return 0;
		}
		
	}
	else{
		log_error($ffid, "service [$service] is invalid!");
		return 0;
	}
}

#
# configuration baseline checks
#
sub conf_baseline_checks($config){
	my $fid = "[conf_baseline_checks]";
	
	if(defined $config->{'id'} && defined $config->{'name'}){
		return 1;
	}
	else{
		print "\n$fid error: config baseline checks failed\n";
		print "$fid error: program is exiting now.\n";
		exit;
	}
}

#
# get hostname [STRING]
#
sub hostname_get(){
	return hostname();
}

1;
