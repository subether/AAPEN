#
# ETHER|AAPEN|FRAMEWORK - LIB|DATABASE
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
use JSON::MaybeXS;


#
# get framework config [JSON-OBJ] 
# MIGRATE TO BASE CONFIG!
#
sub frame_srv_conf_get($service){
	my $srvdata = {};

	if($service eq "cluster"){ 
		$srvdata->{'socket'} = env_serv_sock_get("cluster");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "cdb"){ 
		$srvdata->{'socket'} = env_serv_sock_get("cdb");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'state'} = "";
		$srvdata->{'valid'} = 1;
	}	
	elsif($service eq "agent"){ 
		$srvdata->{'socket'} = "";
		$srvdata->{'port'} = 9932;
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "hypervisor"){ 
		$srvdata->{'socket'} = env_serv_sock_get("hypervisor");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'state'} = "hyperstate.json";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "network"){ 
		$srvdata->{'socket'} = env_serv_sock_get("network");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'state'} = "netstate.json";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "storage"){ 
		$srvdata->{'socket'} = env_serv_sock_get("storage");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'state'} = "storstate.json";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "framework"){ 
		$srvdata->{'socket'} = env_serv_sock_get("framework");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'state'} = "framestate.json";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "monitor"){
		$srvdata->{'socket'} = env_serv_sock_get("monitor");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "element"){
		$srvdata->{'socket'} = env_serv_sock_get("element");
		$srvdata->{'path'} = get_root() . "service/" . $service . "/";
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "api"){
		$srvdata->{'socket'} = "";
		$srvdata->{'path'} = get_root() . $service . "/";
		$srvdata->{'port'} = config_base_agent_port();
		$srvdata->{'exec'} = "perl " . $service . ".pl";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'valid'} = 1;
	}
	elsif($service eq "webapi"){
		$srvdata->{'socket'} = "";
		$srvdata->{'path'} = get_root() . $service . "/";
		$srvdata->{'port'} = 3001;
		$srvdata->{'exec'} = "node " . $service . ".js";
		$srvdata->{'flags'} = "";
		$srvdata->{'log'} = env_base_get() . "log/" . $service . ".log";
		$srvdata->{'valid'} = 1;
	}
	else{
		$srvdata->{'valid'} = 0;
	}
	
	return $srvdata;
}

#
# initialize database [NULL]
#
sub frame_db_init(){
	my $fid = "[frame_db_init]";
	my $ffid = "DB|INIT";
	my $db = {};

	log_info($ffid, "initializing framework configuration");

	$db->{'config'}{'id'} = config_node_id_get();
	$db->{'config'}{'name'} = config_node_name_get();
	$db->{'config'}{'addr'} = config_node_addr_get();

	$db->{'meta'}{'lock'} = '0';
	$db->{'meta'}{'version'} = env_version();
	$db->{'self'}{'init'} = "1";
	
	# vmm
	$db->{'vmm'} = {};
	$db->{'vmm'}{'index'} = "";
	
	# service
	$db->{'service'}{'index'} = "agent;cdb;cluster;hypervisor;network;storage;monitor;element;api;webapi";
	my @srv_index = index_split($db->{'service'}{'index'});
	
	# generate database
	foreach my $service (@srv_index){
		print "SERVICE [$service]\n";

		$db->{'service'}{$service}{'state'} = 0;
		$db->{'service'}{$service}{'status'} = "not running";
		$db->{'service'}{$service}{'date'} = date_get();
	}

	frame_db_set($db);
}

#
# get database metadata [JSON-OBJ]
#
sub frame_db_meta_get(){
	my $fid = "[cluster_db_meta_get]";
	my $db = frame_db_get();
	my $return = packet_build_noencode("1", "success: returning metadata", $fid);
	
	# built metadata
	my $meta;
	$meta->{'vmm'}{'index'} = $db->{'vmm'}{'index'};
	$meta->{'service'} = $db->{'service'};
	$return->{'meta'} = $meta;
	return json_encode($return);
}

#
# get database
#
sub frame_db_get(){
	my %vmshare = dbshare_get();
	return json_decode($vmshare{'db'});
}

#
# set database [NULL]
#
sub frame_db_set($db){
	my %vmshare = dbshare_get();	
	$vmshare{'db'} = json_encode($db);
	dbshare_set(%vmshare);
	config_state_save("framework", $db);
}

#
# get object [JSON-OBJ]
# 
sub frame_db_obj_get($obj){
	my $db = frame_db_get();
	return $db->{$obj};
}

#
# set object [NULL]
# 
sub frame_db_obj_set($obj, $data){
	my $db = frame_db_get();
	$db->{$obj} = $data;
	frame_db_set($db);
}

#
# print database [NULL]
#
sub frame_db_print(){
	print "[" . date_get() . "] [frame_db_print]\n";
	my $db = frame_db_get();
	json_encode_pretty($db);
}

1;
