#
# ETHER|AAPEN|API - LIB|REST|SERVICE
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


#
# ping services [JSON-OBJ]
#
sub api_rest_node_framework_ping($request){
	return api_rest_node_service_ping('frame', $request);
}

sub api_rest_node_hypervisor_ping($request){
	return api_rest_node_service_ping('hyper', $request);
}		

sub api_rest_node_storage_ping($request){
	return api_rest_node_service_ping('storage', $request);
}

sub api_rest_node_network_ping($request){
	return api_rest_node_service_ping('network', $request);
}
	
sub api_rest_node_monitor_ping($request){
	return api_rest_node_service_ping('monitor', $request);
}	

sub api_rest_node_element_ping($request){
	return api_rest_node_service_ping('element', $request);
}	

sub api_rest_node_cluster_ping($request){
	return api_rest_node_service_ping('cluster', $request);
}	

sub api_rest_node_cdb_ping($request){
	return api_rest_node_service_ping('cdb', $request);
}	


#
# service ping handler [JSON-OBJ]
#		
sub api_rest_node_service_ping($service, $request){
	my $fid = "[api_node_service_ping]";
	my $ffid = "NODE|SERVICE|PING";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		my $result = packet_build_noencode("1", "success: pinging node [$request->{'proto'}{'name'}] service [$service]", $fid);
		$result->{'request'} = $request;

		my $packet = api_proto_packet_build($service, "ping");
		$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
		return $result;
	}
	else{
		return $node_data;
	}
	
}

#
# ping services [JSON-OBJ]
#
sub api_rest_node_framework_meta($request){
	return api_rest_node_service_meta('frame', $request);
}

sub api_rest_node_hypervisor_meta($request){
	return api_rest_node_service_info('hyper', $request);
}		

sub api_rest_node_storage_meta($request){
	return api_rest_node_service_meta('storage', $request);
}

sub api_rest_node_network_meta($request){
	return api_rest_node_service_meta('network', $request);
}
	
sub api_rest_node_monitor_meta($request){
	return api_rest_node_service_meta('monitor', $request);
}	

sub api_rest_node_element_meta($request){
	return api_rest_node_service_meta('element', $request);
}

# service ping handler [JSON-OBJ]
sub api_rest_node_service_meta($service, $request){
	my $fid = "[api_node_service_meta]";
	my $ffid = "NODE|SERVICE|META";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	log_info($ffid, "SERVICE [$service]");
	
	if($node_data->{'proto'}{'result'} eq "1"){
		my $result = packet_build_noencode("1", "success: node [$request->{'proto'}{'name'}] service [$service] metadata", $fid);
		$result->{'request'} = $request;

		my $packet = api_proto_packet_build($service, "meta");
		$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
		return $result;
	}
	else{
		return $node_data;
	}
}

#
# network rest config save
#
sub api_rest_node_service_env_set($service, $request){
	my $fid = "[api_node_service_env_set]";
	my $ffid = "NODE|SERVICE|ENV";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		my $result = packet_build_noencode("1", "success: node [$request->{'proto'}{'name'}] service [$service] env [$request->{'proto'}{'env'}]", $fid);
		$result->{'request'} = $request;

		# COMPAT FOR SERVICE CALLERS
		if($service eq "network"){ $service = "net" };
		if($service eq "storage"){ $service = "stor" };
		if($service eq "framework"){ $service = "frame" };
		if($service eq "hypervisor"){ $service = "hyper" };

		my $packet = api_proto_packet_build($service, "env");
		$packet->{$service}{'env'} = $request->{'proto'}{'env'};

		$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
		return $result;
	}
	else{
		return $node_data;
	}
}


#
# service ping handler [JSON-OBJ]
#		
sub api_rest_node_ping($request){
	my $fid = "[api_node_ping]";
	my $ffid = "NODE|PING";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		my $result = packet_build_noencode("1", "success: pinging node", $fid);
		$result->{'request'} = $request;

		my $packet = api_proto_packet_build("ping", "ping");
		$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
		return $result;
	}
	else{
		return $node_data;
	}
	
}

#
# service ping handler [JSON-OBJ]
#		
sub api_rest_node_storage_pool_set($request){
	my $fid = "[api_node_storage_pool_set]";
	my $ffid = "NODE|STORAGE|POOL|SET";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		# get the storage pool
		my $pool_data = api_cluster_local_obj_get(env_serv_sock_get('cluster'), 'storage', $request->{'proto'}{'pool'});
		
		if($pool_data->{'proto'}{'result'} eq "1"){
			
			# send the request to the node
			my $packet = api_proto_packet_build("storage", "pool_set");
			$packet->{'pooldata'} = $pool_data->{'storage'};

			my $response = ssl_send_json($packet, $node_data->{'node'});			
			return json_decode($response);
		}
		else{
			return packet_build_noencode("0", "error: failed to get pool [$request->{'proto'}{'pool'}]", $fid);
		}
		
	}
	else{
		return $node_data;
	}
	
}

# service ping handler [JSON-OBJ]
sub api_rest_node_storage_pool_get($request){
	my $fid = "[api_node_storage_pool_get]";
	my $ffid = "NODE|STORAGE|POOL|GET";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		# get the storage pool
		my $pool_data = api_cluster_local_obj_get(env_serv_sock_get('cluster'), 'storage', $request->{'proto'}{'pool'});
		
		log_info($ffid, "POOL DATA");
		json_encode_pretty($pool_data);
		
		if($pool_data->{'proto'}{'result'} eq "1"){
			# send the request to the node
			my $packet = api_proto_packet_build("storage", "get");
			$packet->{'storage'} = $request->{'proto'}{'pool'};
			my $response = ssl_send_json($packet, $node_data->{'node'});
			
			json_decode_pretty($response);
			return json_decode($response);
		}
		else{
			return packet_build_noencode("0", "error: failed to get pool [$request->{'proto'}{'pool'}]", $fid);
		}
	}
	else{
		return $node_data;
	}
}

#
# service ping handler [JSON-OBJ]
#		
sub api_rest_node_storage_device_get($request){
	my $fid = "[api_node_storage_device_get]";
	my $ffid = "NODE|STORAGE|DEVICE|GET";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){

		# send the request to the node
		my $packet = api_proto_packet_build("storage", "get");
		$packet->{'storage'} = $request->{'proto'}{'device'};
		my $response = ssl_send_json($packet, $node_data->{'node'});
		
		json_decode_pretty($response);
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# node framework service start [JSON-OBJ]
#		
sub api_rest_node_framework_service_start($request){
	my $fid = "[api_node_framework_service_start]";
	my $ffid = "NODE|FRAMEWORK|SERVICE|START";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		my $packet = api_proto_packet_build("frame", "srv");
		$packet->{'srv'}{'id'} = $request->{'proto'}{'service'};
		$packet->{'srv'}{'req'} = "start";
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# node framework service stop [JSON-OBJ]
#		
sub api_rest_node_framework_service_stop($request){
	my $fid = "[api_node_framework_service_stop]";
	my $ffid = "NODE|FRAMEWORK|SERVICE|STOP";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		my $packet = api_proto_packet_build("frame", "srv");
		$packet->{'srv'}{'id'} = $request->{'proto'}{'service'};
		$packet->{'srv'}{'req'} = "stop";
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# node framework service restart [JSON-OBJ]
#		
sub api_rest_node_framework_service_restart($request){
	my $fid = "[api_node_framework_service_restart]";
	my $ffid = "NODE|FRAMEWORK|SERVICE|RESTART";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		my $packet = api_proto_packet_build("frame", "srv");
		$packet->{'srv'}{'id'} = $request->{'proto'}{'service'};
		$packet->{'srv'}{'req'} = "restart";
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# node framework service restart [JSON-OBJ]
#		
sub api_rest_node_framework_service_log_clear($request){
	my $fid = "[api_node_framework_service_log_clear]";
	my $ffid = "NODE|FRAMEWORK|SERVICE|LOGCLEAR";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		my $packet = api_proto_packet_build("frame", "srv");
		$packet->{'srv'}{'id'} = $request->{'proto'}{'service'};
		$packet->{'srv'}{'req'} = "log_clear";
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# node framework service info [JSON-OBJ]
#		
sub api_rest_node_framework_service_info($request){
	my $fid = "[api_node_framework_service_info]";
	my $ffid = "NODE|FRAMEWORK|SERVICE|INFO";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		my $packet = api_proto_packet_build("frame", "srv");
		$packet->{'srv'}{'id'} = $request->{'proto'}{'service'};
		$packet->{'srv'}{'req'} = "info";
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# sframework shutdown [JSON-OBJ]
#		
sub api_rest_node_framework_shutdown($request){
	my $fid = "[api_node_framework_shutdown]";
	my $ffid = "NODE|FRAMEWORK|SHUTDOWN";

	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($request);
		
		my $packet = api_proto_packet_build("frame", "shutdown");
		$packet->{'frame'}{'shutdown'} = $request->{'proto'}{'flag'};
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return packet_build_noencode("1", "success: reached framework shutdown", $fid);
	}
	else{
		return $node_data;
	}
	
}

#
# sframework shutdown [JSON-OBJ]
#		
sub api_rest_node_framework_vmm_info($request){
	my $fid = "[api_node_framework_vmm_info]";
	my $ffid = "NODE|FRAMEWORK|VMM|INFO";

	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($request);
		
		my $packet = api_proto_packet_build("frame", "vmm");
		$packet->{'vmm'}{'req'} = "info";
		$packet->{'vmm'}{'id'} = $request->{'proto'}{'vmmid'};
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# service ping handler [JSON-OBJ]
#		
sub api_rest_node_cluster_service_db($request){
	my $fid = "[api_node_cluster_service_db]";
	my $ffid = "NODE|CLUSTER|DB";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		my $packet = api_proto_packet_build("cluster", "db_get");
		my $response = ssl_send_json($packet, $node_data->{'node'});
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# service ping handler [JSON-OBJ]
#		
sub api_rest_node_cluster_service_meta($request){
	my $fid = "[api_node_cluster_service_meta]";
	my $ffid = "NODE|CLUSTER|META";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		json_encode_pretty($node_data);
		
		my $packet = api_proto_packet_build("cluster", "meta_get");
		my $response = ssl_send_json($packet, $node_data->{'node'});
		
		return json_decode($response);
	}
	else{
		return $node_data;
	}
	
}

#
# service ping handler [JSON-OBJ]
#
sub api_rest_node_cluster_service_obj_get($request){
	my $fid = "[api_node_cluster_service_obj_get]";
	my $ffid = "NODE|CLUSTER|OBJ|GET";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		my $packet = api_proto_packet_build("cluster", "obj_get");
		$packet->{'cluster'}{'obj'} = $request->{'proto'}{'obj_type'};
		$packet->{'cluster'}{'key'} = $request->{'proto'}{'obj_name'};
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		
		return json_decode($response);
	}
	else{
		return $node_data;
	}
}

#
# service ping handler [JSON-OBJ]
#
sub api_rest_node_cluster_service_srv_get($request){
	my $fid = "[api_node_service_srv_get]";
	my $ffid = "NODE|CLUSTER|SERVICE|GET";
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'name'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		my $packet = api_proto_packet_build("cluster", "obj_get");
		$packet->{'cluster'}{'obj'} = $request->{'proto'}{'obj_type'};
		$packet->{'cluster'}{'key'} = $request->{'proto'}{'srv_name'};
		$packet->{'cluster'}{'id'} = $request->{'proto'}{'srv_node'};
		
		my $response = ssl_send_json($packet, $node_data->{'node'});
		
		return json_decode($response);
	}
	else{
		return $node_data;
	}
}

#
# service ping handler [JSON-OBJ]
#
sub api_rest_node_cluster_service_hypervisor_system_destroy($request){
	my $fid = "[api_node_cluster_service_hypervisor_system_destroy]";
	my $ffid = "NODE|HYPERVISOR|SYSTEM|DESTROY";
	
	json_encode_pretty($request);
	
	# validate node
	my $node_data = node_rest_validate_get($request->{'proto'}{'node'});
	
	if($node_data->{'proto'}{'result'} eq "1"){
		my $packet = api_proto_packet_build("hyper", "destroy");
		
		# fetch system
		my $system_data = system_rest_validate_get($request->{'proto'}{'system'});
		
		# validate system
		if($system_data->{'proto'}{'result'} eq "1"){	
			my $result = packet_build_noencode("1", "success: system destroy funciton reached", $fid);
			
			my $packet = api_proto_packet_build("hyper", "destroy");
			$packet->{'hyper'}{'id'} = $system_data->{'system'}{'id'}{'id'};
			$packet->{'hyper'}{'vm'} = $system_data->{'system'};
			
			log_info($fid, "DESTROY PACKET");
			json_encode_pretty($packet);
			
			$result->{'response'} = json_decode(ssl_send_json($packet, $node_data->{'node'}));
			
			return $result;		
		}
		else{
			return packet_build_noencode("0", "error: failed to fetch system from cluster", $fid);
		}
	}
	else{
		return $node_data;
	}
}

1;
