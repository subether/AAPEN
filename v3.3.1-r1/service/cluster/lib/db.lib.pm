#
# ETHER|AAPEN|CLUSTER - LIB|DB
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

# internal db
my $vmdb :shared;


# shared buffers
my %mcbuf :shared;
my %zmq_server_buf :shared;
my %zmq_client_buf :shared;
my %zmq_sync_buf :shared;

# shared metadata
my $db_meta :shared;

# object and service index
my $obj_index = "system;node;network;container;storage;service;element;group";
my $srv_index = "hypervisor;network;framework;monitor;storage";


#
# initialize database [NULL]
#
sub cluster_db_init(){

	my $meta = {};
	$meta->{'srv_index'} = $srv_index;
	$meta->{'obj_index'} = $obj_index;
	$meta->{'cluster'}{'local'}{'name'} = config_node_name_get();
	$meta->{'cluster'}{'local'}{'id'} = config_node_id_get();	
	$meta->{'cluster'}{'local'}{'version'} = env_version();

	my @srv_index = index_split($srv_index);
	my @obj_index = index_split($obj_index);
	
	# generate database
	foreach my $object (@obj_index){
		if($object eq "service"){
			# services
			foreach my $service (@srv_index){
				#index
				$meta->{'service'}{$service}{'index'} = "";
				$meta->{'service'}{$service}{'local'} = "";
				$meta->{'service'}{$service}{'remote'} = "";
				$meta->{'service'}{$service}{'meta'} = {};
			}
		}
		else{
			# index
			$meta->{$object}{'index'} = "";
			$meta->{$object}{'remote'} = "";
			$meta->{$object}{'local'} = "";
			$meta->{$object}{'meta'} = {};
		}
	}

	db_meta_set($meta);
}

#
# sync metadata with CDB [JSON-OBJ]
#
sub cluster_db_cdb_meta_sync(){
	my $fid = "[cluster_db_cdb_meta_sync]";	
	my $return = {};
	
	# fetch cdb and local metadata
	my $cdbmeta = api_cdb_local_meta_get(env_serv_sock_get("cdb"));	
	my $meta = db_meta_get();
	
	if($cdbmeta->{'proto'}{'result'} eq "1"){
		my @srv_index = index_split($srv_index);
		my @obj_index = index_split($obj_index);
		
		# generate database
		foreach my $object (@obj_index){
			if($object eq "service"){
				# services
				foreach my $service (@srv_index){
					# copy meta
					$meta->{'service'}{$service} = $cdbmeta->{'meta'}{'service'}{$service};
				}
			}
			else{
				# copy meta
				$meta->{$object} = $cdbmeta->{'meta'}{$object};
			}
		}		
		
		db_meta_set($meta);
	}
	else{
		log_warn($fid, "failed to fetch CDB");
		$return = packet_build_noencode("0", "failed: failed to fetch cdb", $fid);
	}

}

#
# get database [JSON-OBJ]
#
sub cluster_db_get(){
	{
		lock($vmdb);
		return json_decode($vmdb);
	}
}

#
# set database [NULL]
#
sub cluster_db_set($db){
	{
		lock($vmdb);	
		$vmdb = json_encode($db);
	}
}

#
# get database [JSON-STR]
#
sub cluster_db_get_full(){
	my $fid = "[cluster_db_get_full]";	
	my $return = {};
	
	my $cdbdb = api_cdb_local_db_get(env_serv_sock_get("cdb"));
	
	if($cdbdb->{'proto'}{'result'} eq "1"){
		$return = packet_build_noencode("1", "success: returning cdb", $fid);
		$return->{'db'} = $cdbdb->{'db'};
		
	}
	else{
		log_warn($fid, "failed to fetch CDB");
		$return = packet_build_noencode("0", "failed: failed to fetch cdb", $fid);
	}
	
	return json_encode($return);
}

#
# get database metadata [JSON-OBJ]
#
sub cluster_meta_get(){
	my $fid = "[cluster_db_meta_get]";
	my $meta = db_meta_get();
	
	# build packet
	my $return = packet_build_noencode("1", "success: returning metadata", $fid);
	
	$meta->{'cluster'}{'local'}{'name'} = config_node_name_get();
	$meta->{'cluster'}{'local'}{'id'} = config_node_id_get();	
	$meta->{'cluster'}{'local'}{'version'} = env_version();
	
	# handle new and old date flags (v3.1.x API compat!)
	$meta->{'cluster'}{'updated'} = date_get();
	$meta->{'cluster'}{'date'} = date_get();

	# get cdb metadata
	my $cdbmeta = api_cdb_local_meta_get(env_serv_sock_get("cdb"));
	
	if($cdbmeta->{'proto'}{'result'} eq "1"){		
		my @srv_index = index_split($srv_index);
		my @obj_index = index_split($obj_index);
		
		# process metadata for objects and services
		foreach my $object (@obj_index){
			if($object eq "service"){
				foreach my $service (@srv_index){
					if(defined $cdbmeta->{'meta'}{'service'}{$service}){
						$meta->{'service'}{$service}{'meta'} = $cdbmeta->{'meta'}{'service'}{$service}{'meta'};
					}
				}
			}
			else{
				if(defined $cdbmeta->{'meta'}{$object}){
					$meta->{$object}{'meta'} = $cdbmeta->{'meta'}{$object}{'meta'};
				}
			}
		}
	}
	else{
		log_warn($fid, "failed to get CDB metadata");
	}
	
	$return->{'meta'} = $meta;
	return json_encode($return);
}

#
# check for valid object [JSON-OBJ]
#
sub cluster_obj_check($obj){
	my $fid = "[cdb_obj_check]";

	if(index_find($obj_index, $obj)){
		return packet_build_noencode("1", "success: valid object type", $fid);
	}
	else{
		return packet_build_noencode("0", "error: object [$obj] not a valid object type", $fid);
	}
}

#
# check for valid object [BOOL]
#
sub cluster_obj_check_bool($obj){
	my $fid = "[cdb_obj_check]";

	if(index_find($obj_index, $obj)){
		return 1;
	}
	else{
		return 0;
	}
}

#
# generate full cdb [JSON-OBJ]
#
sub cluster_db_full_generate(){
	my $fid = "[cluster_db_full_generate]";
	my $ffid = "DB|FULL|GENERATE";
	
	my $packet = cluster_packet_build('cdb_full', 'bcast');
	$packet->{'cluster'}{'obj'} = "cdb";
	$packet->{'cluster'}{'id'} = config_node_name_get();
	$packet->{'cluster'}{'key'} = "bcast";
	$packet->{'data'} = json_decode(cluster_db_get_full());
	
	my $size = cluster_packet_size($packet);
	log_info($ffid, "source [$packet->{'cluster'}{'id'}] type [BCAST] database size [$size] bytes");
	
	return $packet;
}

#
# db meta get
#
sub db_meta_get(){
	{
		lock($db_meta);
		return json_decode($db_meta);
	}
}

#
# db meta get
#
sub db_meta_set($meta){
	{
		lock($db_meta);
		$db_meta = json_encode($meta);
	}
}

#
# multicast buffer get
#
sub mcbuf_get(){
	{
		lock(%mcbuf);
		return %mcbuf;
	}
}

#
# multicast buffer set
#
sub mcbuf_set(%buf){
	{
		lock(%mcbuf);
		%mcbuf = %buf;
	}
}

#
# ZMQ server buffer get
#
sub zmq_server_buf_get(){
	{
		lock(%zmq_server_buf);
		return %zmq_server_buf;
	}
}

#
# ZMQ server buffer set
#
sub zmq_server_buf_set(%buf){
	{
		lock(%zmq_server_buf);
		%zmq_server_buf = %buf;
	}
}

#
# ZMQ client buffer get
#
sub zmq_client_buf_get(){
	{
		lock(%zmq_client_buf);
		return %zmq_client_buf;
	}
}

#
# ZMQ client buffer set
#
sub zmq_client_buf_set(%buf){
	{
		lock(%zmq_client_buf);
		%zmq_client_buf = %buf;
	}
}

#
# ZMQ sync buffer get
#
sub zmq_sync_buf_get(){
	{
		lock(%zmq_sync_buf);
		return %zmq_sync_buf;
	}
}

#
# ZMQ sync buffer set
#
sub zmq_sync_buf_set(%buf){
	{
		lock(%zmq_sync_buf);
		%zmq_sync_buf = %buf;
	}
}

1;
