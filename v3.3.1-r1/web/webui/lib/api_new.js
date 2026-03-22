/**
 * ETHER|AAPEN|WEB - LIB|API|NEW
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/


//
// NEW REST API
//
function api_get_request_callback_new(req, url, caller){
	var fid = "[api_get_request_callback_new]";
	
	api_socket_init();
	
	var packet = {};
	packet['aid'] = aid;
	packet['pass'] = apiPass;
	
	packet['req'] = req;
	packet['type'] = "get";
	packet['url'] = url;

	packet['caller'] = caller;

	socket.emit('api', packet);
}

function api_post_request_callback_new_ORIG(req, url, post, caller){
	var fid = "[api_post_request_callback_new]";
	
	api_socket_init();
	
	var packet = {};
	packet['aid'] = aid;
	packet['pass'] = apiPass;
	
	packet['req'] = req;
	packet['type'] = "post";
	packet['url'] = url;
	packet['post'] = post;

	packet['caller'] = caller;

	socket.emit('api', packet);
}


function api_post_request_callback_new(packet){
	var fid = "[api_post_request_callback_new]";
	
	api_socket_init();
	
	//var packet = {};
	packet['aid'] = aid;
	packet['pass'] = apiPass;
	
	packet['req'] = 'api_new';
	packet['type'] = "post";
	//packet['url'] = url;
	//packet['post'] = post;

	//packet['caller'] = caller;

	console.log("EMITTING PACKET!")
	console.log(packet)

	socket.emit('api', packet);
}


//
// NEW REST HANDLER
//
function api_rest_new(){
	api_rest_db_get();
}

//
// Get full DB from REST API
//
function api_rest_db_get(){
	api_get_request_callback_new('api_new', '/db/get', 'api_rest_new_db_full');
	
}

//
// show the new database
//
function api_show_newdb(){
	let newdb = dbnew_get();
	json_show("[ " + "DB_FULL" + " ]", "DB_FULL", "DB_FULL", newdb);	
}

function api_rest_file_get(fileName){
	api_get_request_callback_new('api_new', '/file/get?name=' + fileName, 'api_rest_file_get');
	
}

//
//
//
function api_db_process_full(response){
	var fid = "[api_db_process_full]";
	
	if(response.response.proto.result == "1"){
		toast_show("API | REST", "bi-activity", "API", "Successfully fetched cluster data");

		// set database
		dbnew_set(response.response.response);
		
		// node process
		node_db_process_rest_new(response.response.response.db);
		
		// system process
		system_db_process_rest_new(response.response.response.db);

		// network process
		network_db_process_rest_new(response.response.response.db);

		// network process
		storage_db_process_rest_new(response.response.response.db);

		// network process
		element_db_process_rest_new(response.response.response.db);
		
		
		document.getElementById('main-card-rest').innerHTML = "REST API [<b>Enabled</b>] ver [<b>" + response.proto.version + "</b>]<br/>Last Updated [<b>" + date_get_simple() + "</b>]";
	}
	else{
		console.log("FAILURE!");
		document.getElementById('main-card-rest').innerHTML = "</b>REST API FAILURE</b>";
	}	

}





