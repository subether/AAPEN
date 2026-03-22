/**
 * ETHER|AAPEN|WEB - LIB|API
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

/**
 * API host URL
 * @type {string}
 */
var apiHost = "";

/**
 * API port
 * @type {string}
 */
var apiPort = "";

/**
 * API username (currently unused)
 * @type {string}
 */
var apiUser = "";

/**
 * API authentication key
 * @type {string}
 */
var apiPass = "";

/**
 * Master node for API monitoring
 * @type {string}
 */
var apiMonitorMaster = "";

/**
 * Socket.io connection instance
 * @type {Socket}
 */
var socket;

/**
 * API initialization status flag
 * @type {number}
 */
var api_init = 0;

/**
 * API session ID
 * @type {number}
 */
var aid;

/**
 * Sets the API master node
 * @param {string} master - The master node URL
 */
function api_master_set(master){
    apiMonitorMaster = master;
}

/**
 * Gets the current API master node
 * @returns {string} The current master node URL
 */
function api_master_get(){
    return apiMonitorMaster;
}

/**
 * Gets the current API host node
 * @returns {string} The current API host URL
 */
function api_host_get(){
    return apiHost;
}

/**
 * Shows the API interface view
 */
function api_show(){
    main_hide_all();
    main_api_show();
}

/**
 * Hides the API interface view
 */
function api_hide(){
    main_api_hide();
}

/**
 * Generates a new API session ID
 * @returns {number} The generated session ID
 */
function api_generate_id(){
    var min = 10000;
    var max = 99999;
    aid = Math.floor(Math.random() * (max - min + 1) + min);
    log_write_json("api_generate_id", "[SUCCESS]", "Generated API client key [" + aid +"]");
    return aid;
}

/**
 * Regenerates and displays a new API session ID
 */
function api_regenerate_id(){
    api_generate_id();
    api_show_id();
}

/**
 * Displays the current API session ID in the UI
 */
function api_show_id(){
    document.getElementById("main-card-api-uid").innerHTML = 
        "Regenerate API session ID<br/>API ID [<b>" + aid + "</b>]";
}

/**
 * Sends a ping request to the API
 * @returns {boolean} Always returns false to prevent default form behavior
 */
function api_ping(){
    api_request('ping', 'null', 'null', 'null');
    return false;
}

/**
 * Shows the API login modal and handles connection
 */
function api_login(){
	
	// login box
    var divConnectNode = view_textbox_build("api_connect_node", "API host", "localhost");
    var divConnectPort = view_textbox_build("api_connect_port", "API port", "3000");
    var divConnectPass = view_textbox_build("api_connect_pass", "API key", "letmein");

    document.getElementById("mainModalLabel").innerHTML = "Connect to API";
    document.getElementById("mainModalBody").innerHTML = "<b>API Connection Details</b>";
    document.getElementById("mainModalBody").appendChild(divConnectNode);
    document.getElementById("mainModalBody").appendChild(divConnectPort);
    document.getElementById("mainModalBody").appendChild(divConnectPass);

    document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-cloud-lightning-rain");
    document.getElementById("mainModalBtnAccept").innerHTML = "Connect";
        
    document.getElementById("mainModalBtnAccept").onclick = function() {
        apiHost = document.getElementById("api_connect_node").value;
        apiPort = document.getElementById("api_connect_port").value;
        apiPass = document.getElementById("api_connect_pass").value;
        
        // Connect with explicit WebSocket URL and fallback options
        const wsProtocol = window.location.protocol === 'https:' ? 'wss://' : 'ws://';
        const connectionOptions = {
          path: '/socket.io',
          withCredentials: true,
          secure: window.location.protocol === 'https:',
          transports: ['websocket'],
          upgrade: false,
          forceNew: true,
          reconnection: true,
          reconnectionAttempts: 10,
          reconnectionDelay: 2000,
          timeout: 30000,
          perMessageDeflate: false,
          rejectUnauthorized: false,
          pingTimeout: 25000,
          pingInterval: 30000,
          rememberUpgrade: true,
          randomizationFactor: 0.5
        };

        console.log(`Attempting WebSocket connection to ${wsProtocol}${apiHost}:${apiPort}`);
        socket = io.connect(`${wsProtocol}${apiHost}:${apiPort}`, connectionOptions);

        // Fallback to IP if hostname fails
        socket.on('connect_error', (err) => {
          console.error('Connection failed using hostname, trying IP...', err);
          socket.io.opts.hostname = '127.0.0.1'; // try localhost
          socket.connect();
        });
        
        mainRefreshAllViews();
		
        document.getElementById("main_api_node").innerHTML = "<b>[ " + apiHost + ":" + apiPort + "]</b>";
        $('#mainModal').modal('hide');
    };
    
    $('#mainModal').modal('show');
}

/**
 * Initializes the API socket connection and sets up event handlers
 * @returns {void}
 * @throws {Error} If socket initialization fails
 */
function api_socket_init(){
    const fid = "[api_socket_init]";
    
    if(api_init !== 0) return;

    try {
        // Generate new API ID
        api_generate_id();
        
        // Setup socket event handlers
        api_setup_socket_handlers();
        
    } catch (error) {
        log_write_json(fid, "[INIT_FAILED]", error.message);
        throw new Error(`API socket initialization failed: ${error.message}`);
    }
}

/**
 * Sets up all socket.io event handlers
 * @private
 * @returns {void}
 */
function api_setup_socket_handlers(){
    // Main API message handler
    socket.on('api', api_handle_message);
    
    // Connection status handlers
    socket.on('connect', api_handle_socket_connect);
    socket.on('connect_error', api_handle_socket_error);
    socket.on('connect_failed', api_handle_socket_error);
    socket.on('disconnect', api_handle_socket_disconnect);
}

/**
 * Handles incoming API messages
 * @private
 * @param {string} msg - Raw message from API
 * @returns {void}
 */
function api_handle_message(msg){
    //try {
        const response = JSON.parse(msg);
        
        if(typeof response.proto === 'undefined') {
            api_handle_invalid_response(response);
            return;
        }

        if(!api_init) {
            api_update_connection_status(true);
            api_init = 1;
        }

        api_response(response);
        
   //} catch (error) {
   //    log_write_json("api_failure", "PARSE_ERROR", msg);
   //    toast_show("API | ERROR", "bi-exclamation-diamond", "API", "API response failed to parse!");
   // }
}

/**
 * Handles successful socket connection
 * @private
 * @returns {void}
 */
function api_handle_socket_connect(){
    log_write_json("api_socket", "[CONNECTED]", "API connection established");
}

/**
 * Handles socket connection errors
 * @private
 * @param {string} msg - Error message
 * @returns {void}
 */
function api_handle_socket_error(msg){
    log_write_json("api_socket", "[CONNECT_ERROR]", msg);
    api_update_connection_status(false, "CONNECTION_ERROR");
    toast_show("API | ERROR", "bi-exclamation-diamond", "API", "Failed to connect to API");
}

/**
 * Handles socket disconnection
 * @private
 * @param {string} msg - Disconnect message
 * @returns {void}
 */
function api_handle_socket_disconnect(msg){
    log_write_json("api_socket", "[DISCONNECTED]", msg);
    api_update_connection_status(false, "DISCONNECTED");
    toast_show("API | DISCONNECTED", "bi-exclamation-diamond", "API", "Lost connection to API");
}

/**
 * Handles invalid API responses
 * @private
 * @param {Object} response - Invalid API response
 * @returns {void}
 */
function api_handle_invalid_response(response){
    api_init = 0;
    const errorMsg = response.string || "Unknown API error";
    
    log_write_json("api_error", "INVALID_RESPONSE", errorMsg);
    toast_show("API | ERROR", "bi-activity", "API", `API ERROR [<b>${errorMsg}</b>]`);
}

/**
 * Updates the UI with current connection status
 * @private
 * @param {boolean} connected - Whether connected to API
 * @param {string} [status] - Status message if not connected
 * @returns {void}
 */
function api_update_connection_status(connected, status){
    const statusElement = document.getElementById('main-card-api');
    
    if(connected) {
        statusElement.innerHTML = `Status [<b>Connected</b>] ver [<b>3.3.1</b>]<br/> UID [<b>${aid}</b>] @ [<b>${apiHost}</b>]`;
        toast_show("API | Connected", "bi-activity", "API", "Successfully connected to API");
    } 
    else{
        statusElement.innerHTML = `Status [<b>${status || "DISCONNECTED"}</b>]<br/> Version [<b>n/a</b>]`;
    }
}

/**
 * Builds an API request packet
 * @param {string} req - The request type
 * @param {string} obj - The target object
 * @param {string} id - The object ID
 * @param {string} key - The security key
 * @param {string} node - The target node
 * @param {string} caller - The calling function
 * @returns {Object} The constructed API packet
 */
function api_packet_build(req, obj, id, key, node, caller){
	var fid = "[api_packet_build]";
	
	//api_socket_init();
	
	var packet = {};
	packet['aid'] = aid;
	packet['pass'] = apiPass;

	packet['req'] = req;
	packet['obj'] = obj;
	packet['id'] = id;
	packet['node'] = node;
	packet['key'] = key;
	packet['caller'] = caller;

	//socket.emit('api', packet);
	return packet;
}

/**
 * Sends a basic API request
 * @param {string} req - The request type
 * @param {string} obj - The target object
 * @param {string} id - The object ID
 * @param {string} node - The target node
 * @returns {void}
 */
function api_request(req, obj, id, node){
	var fid = "[api_request]";
	
	api_socket_init();
	var packet = api_packet_build(req, obj, id, "", node, "");
	socket.emit('api', packet);
}

/**
 * Sends an API request with callback handling
 * @param {string} req - The request type
 * @param {string} obj - The target object
 * @param {string} id - The object ID
 * @param {string} node - The target node
 * @param {string} caller - The calling function
 * @returns {void}
 */
function api_request_callback(req, obj, id, node, caller){
	var fid = "[api_request_callback]";
	
	api_socket_init();
	var packet = api_packet_build(req, obj, id, "", node, caller);
	socket.emit('api', packet);
}

/**
 * Sends an API service request with callback handling
 * @param {string} req - The request type
 * @param {string} obj - The target object
 * @param {string} id - The object ID
 * @param {string} key - The security key
 * @param {string} node - The target node
 * @param {string} caller - The calling function
 * @returns {void}
 */
function api_request_service_callback(req, obj, id, key, node, caller){
	var fid = "[api_request_service_callback]";
	
	api_socket_init();
	var packet = api_packet_build(req, obj, id, key, node, caller);
	socket.emit('api', packet);
}

/**
 * Sends an extended API request with additional payload
 * @param {string} req - The request type
 * @param {string} obj - The target object
 * @param {string} id - The object ID
 * @param {string} node - The target node
 * @param {string} caller - The calling function
 * @param {string} extended - The extended field name
 * @param {*} payload - The additional payload data
 * @returns {void}
 */
function api_request_callback_extended(req, obj, id, node, caller, extended, payload){
	var fid = "[api_request_callback_extended]";
	
	api_socket_init();
	
	var packet = {};
	packet['aid'] = aid;
	packet['pass'] = apiPass;
	
	packet['req'] = req;
	packet['obj'] = obj;
	packet['id'] = id;
	packet['node'] = node;
	
	packet['key'] = "null";

	packet['caller'] = caller;
	packet['payload'] = extended;
	packet[extended] = payload;
	
	socket.emit('api', packet);
}

/**
 * Central error handler for API responses
 * @typedef {Object} ApiError
 * @property {string} errorType - Type of error ('invalid_aid', 'request_failed', etc.)
 * @property {Object} response - The full API response object
 * 
 * @param {string} errorType - Type of error being handled
 * @param {Object} response - The API response object
 * @returns {void}
 */
function api_handle_error(errorType, response){
    const errorMap = {
        'invalid_aid': `Invalid API ID - expected ${aid} received ${response.request.aid}`,
        'request_failed': `Request failed - ${response.proto.string || 'Unknown error'}`,
        'parse_error': 'Failed to parse API response',
        'connection_error': 'API connection error'
    };
    
    const message = errorMap[errorType] || 'Unknown API error';
    log_write_json("api_error", errorType.toUpperCase(), message);
    toast_show("API Error", "bi-exclamation-diamond", "API", message);
}

/**
 * Main API response handler
 * @typedef {Object} ApiResponse
 * @property {Object} proto - Response protocol data
 * @property {string} proto.result - '1' for success, '0' for failure
 * @property {string} [proto.string] - Error message if result is '0'
 * @property {Object} request - Original request data
 * @property {string} request.req - Request type
 * @property {string} request.obj - Target object
 * @property {string} request.id - Object ID
 * @property {string} request.node - Target node
 * @property {string} [request.caller] - Calling function name
 * 
 * @param {ApiResponse} response - The API response object
 * @returns {void}
 */
function api_response(response){
    var fid = "[<b>api_response</b>]";

    if(response.proto.result == "1"){
        if(response.request.aid === aid) {
            log_write_json("api_response", "[REQUEST]", response.request);
            //console.log(response);
			

			// ping api
			if(response.request.req == "ping"){
				log_write_json("ping", "[PONG]", response);
			}
		
			// cluster metadata
			//if(response.request.req == "node_cluster_meta_get"){
			//	log.console("node_cluster_meta_get!!");
			//	cluster_node_meta_process(response);
			//}	
			
			// get object from API
			if(response.request.req == "obj_get"){

				// cluster object viewer
				if(response.request.caller == "cluster_obj_show_async"){
					cluster_object_show(response);
				}

			}	
			
			// clone system config
			if(response.request.caller == "system_clone_conf"){
				log_write_json("sys_clone", "[RESPONSE]", response);
			}


			// system console
			if(response.request.req == "sys_console"){
				log_write_json("sys_console", "[RESPONSE]", response);
			}

			// system ssh
			if(response.request.req == "sys_ssh"){
				log_write_json("sys_ssh", "[RESPONSE]", response);
			}


			// system clone config
			if(response.request.caller == "system_clone_conf"){
				log_write_json("sys_clone_conf", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Clone", "bi-activity", "API", "System clone request for [<b>" + response.request.id  + "</b>] successful");
					mainRefreshAllViews();
				}
			}

			//system console
			if(response.request.caller == "system_clone_full"){
				log_write_json("sys_clone_full", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Clone", "bi-activity", "API", "System clone request for [<b>" + response.request.id  + "</b>] successful");
					mainRefreshAllViews();
				}
			}

			// system create callback
			if(response.request.caller == "system_create_full"){
				log_write_json("sys_clone_full", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Create", "bi-activity", "API", "System create request for [<b>" + response.request.id  + "</b>] successful");
				}
				else{
					toast_show("SYSTEM | Create", "bi-activity", "API", "System create request for [<b>" + response.request.id  + "</b>] failed");
				}
				
			}

			// system move callback
			if(response.request.caller == "system_move_full"){
				log_write_json("sys_move_full", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Move", "bi-activity", "API", "System move request for [<b>" + response.request.id  + "</b>] successful");
					mainRefreshAllViews();	
				}
				else{
					toast_show("SYSTEM | Move", "bi-activity", "API", "System move request for [<b>" + response.request.id  + "</b>] failed");
				}
			}

			// system load callback
			if(response.request.req == "sys_hyper_load"){
				log_write_json("sys_hyper_load", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Load", "bi-activity", "API", "System load request for [<b>" + response.request.id  + "</b>] successful");
				}
				else{
					toast_show("SYSTEM | Load", "bi-activity", "API", "System load request for [<b>" + response.request.id + "</b>] failed");
				}
				
			}

			// system shutdown callback
			if(response.request.req == "sys_hyper_shutdown"){
				log_write_json("sys_hyper_shutdown", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Shutdown", "bi-activity", "API", "System shutdown request for [<b>" + response.request.id + "</b>] successful");
				}
				else{
					toast_show("SYSTEM | Shutdown", "bi-activity", "API", "System shutdown request for [<b>" + response.request.id  + "</b>] failed");
				}
				
			}
				
			// system migrate callback
			if(response.request.req == "node_hyper_sys_migrate"){
				log_write_json("sys_hyper_migrate", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Migrate", "bi-activity", "API", "System migration request for [<b>" + response.request.id  + "</b>] successful");
				}
				else{
					toast_show("SYSTEM | Migrate", "bi-activity", "API", "System migration request for [<b>" + response.request.id + "</b>] failed");
				}
			}

			// sytstem storage add callback
			if(response.request.req == "node_hyper_sys_stor_add"){
				log_write_json("node_hyper_sys_stor_add", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					
					if(response.response.proto.result == "1"){
						toast_show("SYSTEM | Create", "bi-activity", "API", "System device create operation for [<b>" + response.request.id  + "</b>] successful");
					}
					else{
						toast_show("SYSTEM | Create", "bi-activity", "API", "System device create operation for [<b>" + response.request.id + "</b>] failed");
					}

				}
				else{
					toast_show("SYSTEM | Create", "bi-activity", "API", "System device create request for [<b>" + response.request.id + "</b>] failed");
				}
			}

			//
			// NEW CALLBACKS
			//

			// system validate callback
			if(response.request.caller == "system_validate"){
				log_write_json("system_validate", "[RESPONSE]", response);
				
				if(response.proto.result == "1"){
					toast_show("SYSTEM | Validate", "bi-activity", "API", "System validation [<b>" + response.request.id  + "</b>] completed");
					//json_show("System [<b>" + response.request.id + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.id, "system", response);
					json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				}
				else{
					//toast_show("SYSTEM | Validate", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
					toast_show("SYSTEM | Validate", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
					//json_show("test", "test", "system", response);
					json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				}
			}

			// system validate callback
			if(response.request.caller == "system_load"){
				log_write_json("system_load", "[RESPONSE]", response);
				
				json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] Load result" , response.request.name, "system", response);
				
				//if(response.proto.result == "1"){
				//	toast_show("SYSTEM | Load", "bi-activity", "API", "System load [<b>" + response.request.id  + "</b>] completed");
					//json_show("System [<b>" + response.request.id + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.id, "system", response);
				//	json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				//}
				//else{
				//	//toast_show("SYSTEM | Validate", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
				//	toast_show("SYSTEM | Load", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
				//	//json_show("test", "test", "system", response);
				//	json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				//}
			}

			// system validate callback
			if(response.request.caller == "system_save"){
				log_write_json("system_save", "[RESPONSE]", response);
				
				json_show("System [<b>" + response.request.name + "</b>] Save result" , response.request.name, "system", response);
				
				//if(response.proto.result == "1"){
				//	toast_show("SYSTEM | Load", "bi-activity", "API", "System load [<b>" + response.request.id  + "</b>] completed");
					//json_show("System [<b>" + response.request.id + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.id, "system", response);
				//	json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				//}
				//else{
				//	//toast_show("SYSTEM | Validate", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
				//	toast_show("SYSTEM | Load", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
				//	//json_show("test", "test", "system", response);
				//	json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				//}
			}

			// system validate callback
			if(response.request.caller == "system_create_full"){
				log_write_json("system_create", "[RESPONSE]", response);
				
				json_show("System [<b>" + response.request.name + "</b>] Create result" , response.request.name, "system", response);
				
				//if(response.proto.result == "1"){
				//	toast_show("SYSTEM | Load", "bi-activity", "API", "System load [<b>" + response.request.id  + "</b>] completed");
					//json_show("System [<b>" + response.request.id + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.id, "system", response);
				//	json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				//}
				//else{
				//	//toast_show("SYSTEM | Validate", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
				//	toast_show("SYSTEM | Load", "bi-activity", "API", "System validate for [<b>" + response.request.id + "</b>] failed");
				//	//json_show("test", "test", "system", response);
				//	json_show("System [<b>" + response.request.name + "</b>] node [<b>" + response.request.node + "</b>] validation result" , response.request.name, "system", response);
				//}
			}

			
			//
			// fetch response handlers - NEW API
			//
			if(response.request.req == "api_new"){
				// TODO

				console.log("RESPONSE FOR CALLER [" + response.request.caller + "]");

				if(response.request.caller == "api_rest_new_db_full"){
					api_db_process_full(response);
				}

				if(response.request.caller == "node_cluster_meta_get"){
					console.log("node_cluster_meta_get!!");
					cluster_node_meta_process(response);					
				}

				// get object from API
				//if(response.request.req == "obj_get"){

				// cluster object viewer
				if(response.request.caller == "cluster_obj_show_async"){
					cluster_object_show(response);
				}

				if(response.request.caller == "api_rest_file_get"){
					//cluster_object_show(response);
					//json_show("TEST" , "test1", "test2", response);
					text_show(response);
					//file_show("HELLO WORLD", response['file_data']);
				}

				//}

				//if(response.request.caller == "api_rest_system_get"){
					//api_db_process_full(response);
				//	json_show("bah", "bah", "bah", response);
				//}
				
				//if(response.request.caller == "api_rest_system_validate"){
					//api_rest_system_process(response);
				//	console.log(response);
					//json_show("[ " + systemName + " ]", systemName, "system", systemData)
					
				//}
				
				//if(response.request.caller == "api_rest_network_fetch"){
				//	api_rest_network_process(response);
				//}

				//if(response.request.caller == "api_rest_storage_fetch"){
				//	api_rest_storage_process(response);
				//}

				//if(response.request.caller == "api_rest_node_fetch"){
					//api_rest_node_process(response);
				//	api_rest_new_callback(response);
				//}

				//if(response.request.caller == "api_rest_new_fetch"){
					//api_rest_element_process(response);
					//toast_show("RECEIVED CALLBACK FOR NEW REST HANDLER!");
				//	toast_show("REST | API", "bi-activity", "API", "NEW REST CALLBACK");
					
				//	api_rest_new_callback(response);
				//}

				// handle view callbacks
				main_view_process();
				
			}
			
        } 
        else{
            api_handle_error('invalid_aid', response);
        }
    }
	else{
		//
		// process failed requests
		//
		if(response.proto.result == "0"){
			
			if((typeof response.request !== 'undefined')){
				
				if(response.request.caller == "system_clone_conf"){
					toast_show("SYSTEM | Clone", "bi-activity", "API", "System clone request for [<b>" + response.request.id + "</b>] failed. Error [<b>" + response.proto.string + "</b>]");
				}
				else if(response.request.caller == "system_clone_full"){
					toast_show("SYSTEM | Clone", "bi-activity", "API", "System clone request for [<b>" + response.request.id + "</b>] failed. Error [<b>" + response.proto.string + "</b>]");
				}
				else{
					toast_show("FAILURE | " + response.request.req, "bi-activity", "API", "Error [<b>" + response.proto.string + "</b>]");
				}
				
				log_write_json("api_response", "[REQUEST_FAILED]", response);
			}
			else{
				log_write_json("api_response", "[API_FAILURE]", response);	
			}
		}
		
		
	}
}

//
// BASIC API CALLS
//

/**
 * Requests cluster metadata for a specific node
 * @param {string} node - The node to get metadata for
 * @returns {boolean} Always returns false to prevent default form behavior
 */

/**
 * Displays the API view with current session ID
 * @returns {void}
 */
function api_view(){
	api_show_id();
}
