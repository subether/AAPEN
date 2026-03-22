#
# ETHER|AAPEN|API - LIB|PROTOCOL|REST
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
use Term::ANSIColor qw(:constants);

my $rest_api_port = 3001;

# Helper to generate request IDs
sub _generate_request_id {
    return sprintf("%08X", rand(0xFFFFFFFF));
}

#
# REST PROTOCOL
#
sub rest_api(){
	#
	# Define Mojolicious routes
	#

	###########
	# GENERAL #
	###########
	
	# ping
	app->routes->get('/ping' => sub ($c) {
		my $req_id = _generate_request_id();
		log_info("API Request", "[$req_id] GET /ping");
		
		my $packet = {
			proto => {
				req => 'ping',
				req_id => $req_id
			}
		};
		
		my $result = api_rest_ping($packet);
		$result->{'proto'}{'req_id'} = $req_id;
		
		log_info("API Response", "[$req_id] GET /ping completed");
		$c->render(json => $result);
	});

	# db metadata
	app->routes->get('/db/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'db_meta'
			}
		};
		$c->render(json => api_rest_db_meta($packet));
	});

	# get db
	app->routes->get('/db/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'db_get',
			}
		};
		$c->render(json => api_rest_db_get($packet));
	});


	########
	# NODE #
	########

	# get node metadata
	app->routes->get('/node/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'node_meta',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_meta_get('node', $packet));
	});

	# get node config
	app->routes->get('/node/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'node_get',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_get('node', $packet));
	});

	# get node db
	app->routes->get('/node/db' => sub ($c) {
		my $packet = {
			proto => {
				req => 'node_db',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_db_get('node', $packet));
	});

	# ping node
	app->routes->get('/node/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'node_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_ping($packet));
	});

	# load node config
	app->routes->post('/node/config/load' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'node_config_load',
				name => $json->{name}
			}
		};

		my $result = node_rest_config_load($packet);
		$c->render(json => $result);
	});

	# save node config
	app->routes->post('/node/config/save' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'node_config_save',
				name => $json->{name}
			}
		};

		my $result = node_rest_config_save($packet);
		$c->render(json => $result);
	});


	##########
	# SYSTEM #
	##########

	# get system metadata
	app->routes->get('/system/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'system_meta',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_meta_get('system', $packet));
	});

	# get system config
	app->routes->get('/system/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'system_get',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_get('system', $packet));
	});

	# get system db
	app->routes->get('/system/db' => sub ($c) {
		my $packet = {
			proto => {
				req => 'system_db',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_db_get('system', $packet));
	});

	# load system config
	app->routes->post('/system/config/load' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'system_config_load',
				name => $json->{name}
			}
		};

		my $result = system_rest_config_load($packet);
		$c->render(json => $result);
	});

	# save system config
	app->routes->post('/system/config/save' => sub ($c) {
		my $json = $c->req->json;
		#return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
		#	unless $json && defined $json->{name} && defined $json->{system};
			#unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'system_config_save',
				name => $json->{name}
				#system => $json->{system}
			}
		};

		my $result = system_rest_config_save($packet);
		$c->render(json => $result);
	});

	# save system config
	app->routes->post('/system/config/set' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name} && defined $json->{system};

		my $packet = {
			proto => {
				req => 'system_config_set',
				name => $json->{name},
				system => $json->{system}
			}
		};

		my $result = system_rest_config_set($packet);
		$c->render(json => $result);
	});

	# delete system config
	app->routes->post('/system/config/del' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'system_config_del',
				name => $json->{name}
			}
		};

		my $result = system_rest_config_del($packet);
		$c->render(json => $result);
	});

	# clone system config
	app->routes->post('/system/config/clone' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing requred params"}}) 
			unless $json && defined $json->{'srcname'} && defined $json->{'dstname'} && defined $json->{'dstid'} && defined $json->{'dstpool'} && defined $json->{'dsrgroup'};

		my $packet = {
			proto => {
				req => 'system_config_clone',
				srcname => $json->{'srcname'},
				dstname => $json->{'dstname'},
				dstid => $json->{'dstid'},
				dstgroup => $json->{'dstgroup'},
				dstpool => $json->{'dstpool'}
			}
		};

		my $result = system_rest_config_clone($packet);
		$c->render(json => $result);
	});

	# load system (start system)
	app->routes->post('/system/load' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or node"}}) 
			unless $json && defined $json->{name} && defined $json->{node};

		my $packet = {
			proto => {
				req => 'system_load',
				name => $json->{name},
				node => $json->{node}
			}
		};

		my $result = system_rest_load($packet);
		$c->render(json => $result);
	});

	# unload system
	app->routes->post('/system/unload' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'system_unload',
				name => $json->{name}
			}
		};

		my $result = system_rest_unload($packet);
		$c->render(json => $result);
	});

	# shutdown system
	app->routes->post('/system/shutdown' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'system_shutdown',
				name => $json->{name}
			}
		};

		my $result = system_rest_shutdown($packet);
		$c->render(json => $result);
	});

	# reset system
	app->routes->post('/system/reset' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'system_reset',
				name => $json->{name}
			}
		};

		my $result = system_rest_reset($packet);
		$c->render(json => $result);
	});

	# system validate
	app->routes->post('/system/validate' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or node"}}) 
			unless $json && defined $json->{name} && defined $json->{node};

		my $packet = {
			proto => {
				req => 'system_validate',
				name => $json->{name},
				node => $json->{node},
			}
		};

		my $result = system_rest_validate($packet);
		$c->render(json => $result);
	});

	# system create
	app->routes->post('/system/create' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or node"}}) 
			unless $json && defined $json->{name} && defined $json->{node};

		my $packet = {
			proto => {
				req => 'system_create',
				name => $json->{name},
				node => $json->{node},
			}
		};

		my $result = system_rest_create($packet);
		$c->render(json => $result);
	});	

	# clone system config
	app->routes->post('/system/clone' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing requred params"}}) 
			unless $json && defined $json->{'srcname'} && defined $json->{'dstname'} && defined $json->{'dstid'} && defined $json->{'dstpool'} && defined $json->{'dsrgroup'};

		my $packet = {
			proto => {
				req => 'system_clone',
				srcname => $json->{'srcname'},
				dstname => $json->{'dstname'},
				dstid => $json->{'dstid'},
				dstgroup => $json->{'dstgroup'},
				dstpool => $json->{'dstpool'}
			}
		};

		my $result = system_rest_clone($packet);
		$c->render(json => $result);
	});

	# system delete
	app->routes->post('/system/delete' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or node"}}) 
			unless $json && defined $json->{name} && defined $json->{node};

		my $packet = {
			proto => {
				req => 'system_delete',
				name => $json->{name},
				node => $json->{node},
			}
		};

		my $result = system_rest_delete($packet);
		$c->render(json => $result);
	});	

	# system migrate
	app->routes->post('/system/migrate' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name, srcnode or dstnode"}}) 
			unless $json && defined $json->{name} && defined $json->{srcnode} && defined $json->{dstnode};

		my $packet = {
			proto => {
				req => 'system_migrate',
				name => $json->{name},
				srcnode => $json->{srcnode},
				dstnode => $json->{dstnode},
			}
		};

		my $result = system_rest_migrate($packet);
		$c->render(json => $result);
	});

	# system move
	app->routes->post('/system/move' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or node"}}) 
			unless $json && defined $json->{name} && defined $json->{node};

		my $packet = {
			proto => {
				req => 'system_move',
				name => $json->{name},
				node => $json->{node},
			}
		};

		my $result = system_rest_move($packet);
		$c->render(json => $result);
	});
	
	# system storage add
	app->routes->post('/system/storage/add' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing node, system or storage"}}) 
			unless $json && defined $json->{'node'} && defined $json->{'name'} && defined $json->{'storage'};

		my $packet = {
			proto => {
				req => 'system_storage_add',
				node => $json->{'node'},
				name => $json->{'name'},
				storage => $json->{'storage'}
			}
		};

		my $result = system_rest_storage_add($packet);
		$c->render(json => $result);
	});
	
	# system storage expand
	app->routes->post('/system/storage/expand' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing node, system or storage"}}) 
			unless $json && defined $json->{'node'} && defined $json->{'name'} && defined $json->{'storage'};

		my $packet = {
			proto => {
				req => 'system_storage_expand',
				node => $json->{'node'},
				name => $json->{'name'},
				storage => $json->{'storage'}
			}
		};

		my $result = system_rest_storage_expand($packet);
		$c->render(json => $result);
	});


	###########
	# NETWORK #
	###########

	# get network metadata
	app->routes->get('/network/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'network_meta',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_meta_get('network', $packet));
	});

	# get network config
	app->routes->get('/network/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'network_get',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_get('network', $packet));
	});

	# get network db
	app->routes->get('/network/db' => sub ($c) {
		my $packet = {
			proto => {
				req => 'network_db',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_db_get('network', $packet));
	});

	# load network config
	app->routes->post('/network/config/load' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'network_config_load',
				name => $json->{name}
			}
		};

		my $result = network_rest_config_load($packet);
		$c->render(json => $result);
	});

	# save network config
	app->routes->post('/network/config/save' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'network_config_save',
				name => $json->{name}
			}
		};

		my $result = network_rest_config_save($packet);
		$c->render(json => $result);
	});


	###########
	# STORAGE #
	###########

	# get storage metadata
	app->routes->get('/storage/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_meta',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_meta_get('storage', $packet));
	});

	# get storage config
	app->routes->get('/storage/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_get',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_get('storage', $packet));
	});

	# get storage db
	app->routes->get('/storage/db' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_db',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_db_get('storage', $packet));
	});

	# load storage config
	app->routes->post('/storage/config/load' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'storage_config_load',
				name => $json->{name}
			}
		};

		my $result = storage_rest_config_load($packet);
		$c->render(json => $result);
	});

	# save storage config
	app->routes->post('/storage/config/save' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{name};

		my $packet = {
			proto => {
				req => 'storage_config_save',
				name => $json->{name}
			}
		};

		my $result = storage_rest_config_save($packet);
		$c->render(json => $result);
	});


	###########
	# ELEMENT #
	###########

	# get element metadata
	app->routes->get('/element/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'element_meta',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_meta_get('element', $packet));
	});

	# get element config
	app->routes->get('/element/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'element_get',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_get('element', $packet));
	});

	# get element db
	app->routes->get('/element/db' => sub ($c) {
		my $packet = {
			proto => {
				req => 'element_db',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_db_get('element', $packet));
	});

	# load element config
	app->routes->post('/element/config/load' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{'name'};

		my $packet = {
			proto => {
				req => 'element_config_load',
				name => $json->{'name'}
			}
		};

		my $result = element_rest_config_load($packet);
		$c->render(json => $result);
	});

	# save element config
	app->routes->post('/element/config/save' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name"}}) 
			unless $json && defined $json->{'name'};

		my $packet = {
			proto => {
				req => 'element_config_save',
				name => $json->{'name'}
			}
		};

		my $result = element_rest_config_save($packet);
		$c->render(json => $result);
	});


	###########
	# SERVICE #
	###########

	# get service metadata
	app->routes->get('/service/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'service_meta',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_srv_meta_get('all', $packet));
	});

	# get service db
	app->routes->get('/service/db' => sub ($c) {
		my $packet = {
			proto => {
				req => 'service_db',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_obj_db_get('service', $packet));
	});


	#####################
	# FRAMEWORK SERVICE #
	#####################

	# ping framework service
	app->routes->get('/service/framework/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'hypervisor_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_framework_ping($packet));
	});

	# framework service env
	app->routes->post('/service/framework/env' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or env"}}) 
			unless $json && defined $json->{'name'} && defined $json->{'env'};

		my $packet = {
			proto => {
				req => 'env',
				name => $json->{'name'},
				env => $json->{'env'}
			}
		};

		my $result = api_rest_node_service_env_set('framework', $packet);
		$c->render(json => $result);
	});
	
	app->routes->get('/service/framework/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'framework_meta',
				name => $c->param('name') // '',
			}
		};

		$c->render(json => api_rest_node_framework_meta($packet));
	});

	app->routes->get('/service/framework/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'framework_get',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_srv_get('framework', $packet));
	});

	# framework service shutdown
	app->routes->post('/service/framework/shutdown' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or flag"}}) 
			unless $json && defined $json->{name} && defined $json->{flag};

		my $packet = {
			proto => {
				req => 'env',
				name => $json->{name},
				flag => $json->{flag}
			}
		};

		my $result = api_rest_node_framework_shutdown($packet);
		$c->render(json => $result);
	});

	# framework service shutdown
	app->routes->post('/service/framework/service/start' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or flag"}}) 
			unless $json && defined $json->{'name'} && defined $json->{'service'};

		my $packet = {
			proto => {
				req => 'framework_service_start',
				name => $json->{'name'},
				service => $json->{service}
			}
		};

		my $result = api_rest_node_framework_service_start($packet);
		$c->render(json => $result);
	});

	# framework service shutdown
	app->routes->post('/service/framework/service/stop' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or flag"}}) 
			unless $json && defined $json->{'name'} && defined $json->{'service'};

		my $packet = {
			proto => {
				req => 'framework_service_stop',
				name => $json->{'name'},
				service => $json->{'service'}
			}
		};

		my $result = api_rest_node_framework_service_stop($packet);
		$c->render(json => $result);
	});

	# framework service shutdown
	app->routes->post('/service/framework/service/restart' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or flag"}}) 
			unless $json && defined $json->{'name'} && defined $json->{'service'};

		my $packet = {
			proto => {
				req => 'framework_service_restart',
				name => $json->{'name'},
				service => $json->{'service'}
			}
		};

		my $result = api_rest_node_framework_service_restart($packet);
		$c->render(json => $result);
	});

	# framework service shutdown
	app->routes->post('/service/framework/service/logclear' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or flag"}}) 
			unless $json && defined $json->{'name'} && defined $json->{'service'};

		my $packet = {
			proto => {
				req => 'framework_service_log_clear',
				name => $json->{'name'},
				service => $json->{'service'}
			}
		};

		my $result = api_rest_node_framework_service_log_clear($packet);
		$c->render(json => $result);
	});

	# get service info from framework
	app->routes->get('/service/framework/service/info' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or service"}}) 
			unless $json && defined $json->{'name'} && defined $json->{'service'};
		
		my $packet = {
			proto => {
				req => 'framework_service_info',
				name => $json->{'name'},
				service => $json->{'service'}
			}
		};
		$c->render(json => api_rest_node_framework_service_info($packet));
	});

	app->routes->get('/service/framework/vmm/info' => sub ($c) {
		my $packet = {
			proto => {
				req => 'framework_vmm_info',
				name => $c->param('name') // '',
				vmmid => $c->param('vmmid') // '',
			}
		};
		$c->render(json => api_rest_node_framework_vmm_info($packet));
	});


	######################
	# HYPERVISOR SERVICE #
	######################

	# ping hypervisor service
	app->routes->get('/service/hypervisor/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'hypervisor_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_hypervisor_ping($packet));
	});

	# hypervisor service env
	app->routes->post('/service/hypervisor/env' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or env"}}) 
			unless $json && defined $json->{name} && defined $json->{env};

		my $packet = {
			proto => {
				req => 'env',
				name => $json->{name},
				env => $json->{env}
			}
		};

		my $result = api_rest_node_service_env_set('hypervisor', $packet);
		$c->render(json => $result);
	});
	
	app->routes->get('/service/hypervisor/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'hypervisor_meta',
				name => $c->param('name') // '',
			}
		};

		$c->render(json => api_rest_node_hypervisor_meta($packet));
	});

	app->routes->get('/service/hypervisor/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'hypervisor_get',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_srv_get('hypervisor', $packet));
	});

	# hypervisor system destroy
	app->routes->post('/service/hypervisor/system/destroy' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing node or system"}}) 
			unless $json && defined $json->{node} && defined $json->{system};

		my $packet = {
			proto => {
				req => 'hypervisor_system_destroy',
				node => $json->{node},
				system => $json->{system}
			}
		};

		my $result = api_rest_node_cluster_service_hypervisor_system_destroy($packet);
		$c->render(json => $result);
	});


	###################
	# NETWORK SERVICE #
	###################

	# ping network service
	app->routes->get('/service/network/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'network_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_network_ping($packet));
	});
	
	# get network service metadata
	app->routes->get('/service/network/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'network_meta',
				name => $c->param('name') // '',
			}
		};

		$c->render(json => api_rest_node_network_meta($packet));
	});

	# network service env
	app->routes->post('/service/network/env' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or env"}}) 
			unless $json && defined $json->{name} && defined $json->{env};

		my $packet = {
			proto => {
				req => 'env',
				name => $json->{name},
				env => $json->{env}
			}
		};

		my $result = api_rest_node_service_env_set('network', $packet);
		$c->render(json => $result);
	});

	
	###################
	# STORAGE SERVICE #
	###################

	# ping storage service
	app->routes->get('/service/storage/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_storage_ping($packet));
	});

	# storage service env 
	app->routes->post('/service/storage/env' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or env"}}) 
			unless $json && defined $json->{name} && defined $json->{env};

		my $packet = {
			proto => {
				req => 'env',
				name => $json->{name},
				env => $json->{env}
			}
		};

		my $result = api_rest_node_service_env_set('storage', $packet);
		$c->render(json => $result);
	});
	
	app->routes->get('/service/storage/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_meta',
				name => $c->param('name') // '',
			}
		};

		$c->render(json => api_rest_node_storage_meta($packet));
	});

	app->routes->get('/service/storage/pool/set' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_pool_set',
				name => $c->param('name') // '',
				pool => $c->param('pool') // '',
			}
		};
		$c->render(json => api_rest_node_storage_pool_set($packet));
	});

	app->routes->get('/service/storage/pool/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_pool_get',
				name => $c->param('name') // '',
				pool => $c->param('pool') // '',
			}
		};
		$c->render(json => api_rest_node_storage_pool_get($packet));
	});

	app->routes->get('/service/storage/device/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'storage_device_get',
				name => $c->param('name') // '',
				device => $c->param('device') // '',
			}
		};
		$c->render(json => api_rest_node_storage_device_get($packet));
	});


	###################
	# MONITOR SERVICE #
	###################

	# ping monitor service
	app->routes->get('/service/monitor/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'monitor_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_monitor_ping($packet));
	});

	# monitor service env
	app->routes->post('/service/monitor/env' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or env"}}) 
			unless $json && defined $json->{name} && defined $json->{env};

		my $packet = {
			proto => {
				req => 'env',
				name => $json->{name},
				env => $json->{env}
			}
		};

		my $result = api_rest_node_service_env_set('monitor', $packet);
		$c->render(json => $result);
	});
	
	# get monitor service metadata
	app->routes->get('/service/monitor/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'monitor_meta',
				name => $c->param('name') // '',
			}
		};

		$c->render(json => api_rest_node_monitor_meta($packet));
	});


	###################
	# CLUSTER SERVICE #
	###################

	# ping cluster service
	app->routes->get('/service/cluster/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'cluster_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_cluster_ping($packet));
	});

	# cluster service env
	app->routes->post('/service/cluster/env' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or env"}}) 
			unless $json && defined $json->{name} && defined $json->{env};

		my $packet = {
			proto => {
				req => 'cluster_env',
				name => $json->{name},
				env => $json->{env}
			}
		};

		my $result = api_rest_node_service_env_set('cluster', $packet);
		$c->render(json => $result);
	});

	app->routes->get('/service/cluster/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'cluster_meta',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_cluster_service_meta($packet));
	});

	app->routes->get('/service/cluster/db' => sub ($c) {
		my $packet = {
			proto => {
				req => 'cluster_db',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_cluster_service_db($packet));
	});

	app->routes->get('/service/cluster/object/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'cluster_obj_get',
				name => $c->param('name') // '',
				obj_type => $c->param('obj_type') // '',
				obj_name => $c->param('obj_name') // ''
			}
		};
		$c->render(json => api_rest_node_cluster_service_obj_get($packet));
	});

	app->routes->get('/service/cluster/service/get' => sub ($c) {
		my $packet = {
			proto => {
				req => 'cluster_srv_get',
				name => $c->param('name') // '',
				obj_type => $c->param('obj_type') // '',
				srv_name => $c->param('srv_name') // '',
				srv_node => $c->param('srv_node') // ''
			}
		};
		$c->render(json => api_rest_node_cluster_service_srv_get($packet));
	});


	###################
	# CDB SERVICE     #
	###################

	app->routes->get('/service/cdb/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'cdb_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_node_cdb_ping($packet));
	});

	# cdb service env
	app->routes->post('/service/cdb/env' => sub ($c) {
		my $json = $c->req->json;
		return $c->render(status => 400, json => {proto => {result => 0, error => "Missing name or env"}}) 
			unless $json && defined $json->{name} && defined $json->{env};

		my $packet = {
			proto => {
				req => 'env',
				name => $json->{name},
				env => $json->{env}
			}
		};

		my $result = api_rest_node_service_env_set('cdb', $packet);
		$c->render(json => $result);
	});


	###################
	# ELEMENT SERVICE #
	###################

	# ping element service
	app->routes->get('/service/element/ping' => sub ($c) {
		my $packet = {
			proto => {
				req => 'element_ping',
				name => $c->param('name') // '',
			}
		};
		$c->render(json => api_rest_element_ping($packet));
	});
	
	# get element service metadata
	app->routes->get('/service/element/meta' => sub ($c) {
		my $packet = {
			proto => {
				req => 'element_meta',
				name => $c->param('name') // '',
			}
		};

		$c->render(json => api_rest_node_element_meta($packet));
	});


	###################
	# TEST	TEST TEST #
	###################

	app->routes->get('/file/get' => sub ($c) {
		my $request_packet = {
			proto => {
				req => 'file_get',
				name => $c->param('name') // '',
			}
		};

		my ($response_packet, $file_data) = api_rest_file_get($request_packet);

		#my $file_path = path('/aapen/docs/lost.pl');

		$c->render(json => {
			proto => $response_packet->{'proto'},
			file_data => $file_data,
			#filename => $file_path->basename
			#file_content => $file_path->slurp,
			#filename => $file_path->basename
		});

		#my $file_path = path('/home/sri/.vimrc');

		#$c->render(json => api_rest_srv_get('element', $packet));
	});


	my $rest_url = config_base_rest_api_proto() . "://" . config_base_rest_api_listen() . ":" . config_base_rest_api_port();

	# Start the server
	my $mojo_pid = fork();
	if ($mojo_pid == 0) {
		#app->start('daemon', '-l', 'http://*:' . $rest_api_port);
		app->start('daemon', '-l', $rest_url);
		exit;
	} elsif ($mojo_pid == -1) {
		die "Failed to fork Mojolicious process: $!";
	}

}

1;
