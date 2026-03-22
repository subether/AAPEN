/**
 * ETHER|AAPEN|WEB - LIB|SYSTEM
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

var systemRefresh = 0;


//function system_rest_refresh(){
//	console.log("SYSTEM REST REFRESH");	
//	api_get_request_callback_new('api_new', '/db/get', 'api_rest_system_refresh');
//	
//}

//
//
//
function system_rest_fetch(systemName){
	//console.log("SYSTEM REST FETCH");
	api_get_request_callback_new('api_new', '/system/get?name=' + systemName, 'api_rest_system_get');
	
}

//function system_rest_validate(systemName, nodeName){
	//console.log("SYSTEM REST FETCH");
//	api_post_request_callback_new('api_new', '/system/validate?name=' + systemName + "&node=" + nodeName, 'node_hyper_sys_validate');
	
//}

//
//
//
function system_rest_validate(systemName, nodeName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/validate';
	packet['name'] = systemName;
	packet['node'] = nodeName;
	packet['caller'] = 'system_validate';
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_reset(systemName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/reset';
	packet['name'] = systemName;
	packet['caller'] = 'system_reset';
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_load(systemName, nodeName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/load';
	packet['name'] = systemName;
	packet['node'] = nodeName;
	packet['caller'] = 'system_load';
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_unload(systemName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/unload';
	packet['name'] = systemName;
	packet['caller'] = 'system_unload';
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_shutdown(systemName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/shutdown';
	packet['name'] = systemName;
	packet['caller'] = 'system_shutdown';
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_clone_config(sourceName, destName, destId, groupName, poolName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/config/clone';
	packet['caller'] = 'system_clone_conf';
	packet['srcname'] = sourceName;
	packet['dstname'] = destName;
	packet['dstid'] = destId;
	packet['dstgroup'] = groupName;
	packet['dstpool'] = poolName;
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_clone_full(sourceName, destName, destId, nodeName, groupName, poolName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/clone';
	packet['caller'] = 'system_clone_full';
	packet['srcname'] = sourceName;
	packet['dstname'] = destName;
	packet['node'] = nodeName;
	packet['dstid'] = destId;
	packet['dstgroup'] = groupName;
	packet['dstpool'] = poolName;
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_create_full(systemName, nodeName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/create';
	packet['caller'] = 'system_create_full';
	packet['name'] = systemName;
	packet['node'] = nodeName;
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_delete(systemName, nodeName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/delete';
	packet['caller'] = 'system_delete';
	packet['name'] = systemName;
	packet['node'] = nodeName;
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_move_full(sourceName, destName, destId, nodeName, groupName, poolName){
	//console.log("SYSTEM REST FETCH");

	var packet = {};
	packet['url'] = '/system/move';
	packet['caller'] = 'system_move_full';
	packet['name'] = sourceName;
	packet['dstname'] = destName;
	packet['node'] = nodeName;
	packet['dstid'] = destId;
	packet['dstgroup'] = groupName;
	packet['dstpool'] = poolName;
	
	console.log(packet);
	
	api_post_request_callback_new(packet);
	
}

//
//
//
function system_rest_save(systemName, systemData){
	var packet = {};
	packet['url'] = '/system/config/save';
	packet['name'] = systemName;
	packet['system'] = systemData;
	packet['caller'] = 'system_save';
	
	console.log(packet);
	
	api_post_request_callback_new(packet);	
	
}



//function system_move_full(sourceSystem, destinationSystem, destuid, nodeName, groupName, poolName) {
	
//	var clone = {};
//	clone['dest_id'] = destuid;
//	clone['dest_name'] = destinationSystem;
//	clone['group'] = groupName;
//	clone['pool'] = poolName;
	
//	api_request_callback_extended('sys_move_full', 'system', sourceSystem, nodeName, 'system_move_full', 'clone', clone);
//}


//function system_clone_full(sourceSystem, destinationSystem, destuid, nodeName, groupName, poolName) {
	
//	var clone = {};
//	clone['dest_id'] = destuid;
//	clone['dest_name'] = destinationSystem;
//	clone['group'] = groupName;
//	clone['pool'] = poolName;
//	
//	api_request_callback_extended('sys_clone_full', 'system', sourceSystem, nodeName, 'system_clone_full', 'clone', clone);
//}


//function system_create_full(sourceSystem, nodeName) {
//	api_request_service_callback('node_hyper_sys_create', 'aa', sourceSystem, 'bb', nodeName, 'system_create_full');
//}

//function system_clone_config(sourceSystem, destinationSystem, destuid, groupname, poolName) {
	
//	var clone = {};
//	clone['dest_id'] = destuid;
//	clone['dest_name'] = destinationSystem;
//	clone['group'] = groupname;
//	clone['pool'] = poolName;
//	
//	api_request_callback_extended('sys_clone_conf', 'system', sourceSystem, 'node', 'system_clone_conf', 'clone', clone);
//}


/**
 * Processes system metadata from REST response
 * @param {Object} systemMetadata - System metadata object from REST response
 * @description Updates system menu with online/offline/template systems
 * and populates system database with received data
 */
//function sys_conf_meta_process_rest(systemMetadata){
function system_db_process_rest_new(db){
	var fid = "[<b>system_db_process_rest_new</b>]";
	
	var onlineSystemCount = 0;
	var offlineSystemCount = 0;
	var templateSystemCount = 0;
	
	// clean menu
	system_menu_remove_online();
	system_menu_remove_offline();
	system_menu_remove_template();
	
    // process nodes
    const system_index = db.system.index;
    var systemList = system_index.split(';');
    systemList = sort_alpha(systemList);
    
	systemList.forEach((systemName) => {
		
		// check state of system		
		if(db.system.db[systemName].meta && db.system.db[systemName].meta.state){
			
			// check state
			if(db.system.db[systemName].meta.state == 1){
				system_menu_add_online(systemName);
				dbnew_system_online_index_add(systemName);
				onlineSystemCount++;
			}
			else{
				system_menu_add_offline(systemName);
				dbnew_system_offline_index_add(systemName);
				offlineSystemCount++;
			}
		}
		else{
			system_menu_add_offline(systemName);
			dbnew_system_offline_index_add(systemName);
			offlineSystemCount++;
		}
		
		// check for templates and groups
		if(db.system.db[systemName].id.group == "template"){
			system_menu_add_template(systemName);
			templateSystemCount++;
		}
		else{
			dbnew_system_group_add(db.system.db[systemName].id.group)
		}
		
		
		dbnew_system_index_add(systemName);
	});	
	
	document.getElementById('menu-system-online').innerHTML = "Online (" + onlineSystemCount + ")";
	document.getElementById('menu-system-offline').innerHTML = "Offline (" + offlineSystemCount + ")";
	document.getElementById('menu-system-template').innerHTML = "Template (" + templateSystemCount + ")";
	
	document.getElementById('main-card-system').innerHTML = "Online Systems [<b>" + onlineSystemCount + "</b>]<br/>Offline Systems [<b>" + offlineSystemCount + "</b>]";
}

/**
 * Opens system console
 * @param {string} systemName - System name
 * @description Makes API request to open system console
 */
function system_console(systemName){
	api_request('sys_console', 'system', systemName, 'node');
}

/**
 * Opens SSH connection to system
 * @param {string} systemName - System name
 * @description Makes API request to open SSH connection
 */
function system_ssh(systemName){
	api_request('sys_ssh', 'system', systemName, 'node');
}

/**
 * Shuts down system hypervisor
 * @param {string} systemName - System name
 * @description Makes API request to shutdown system hypervisor
 */
//function system_hyper_shutdown(systemName){
//	api_request('sys_hyper_shutdown', 'system', systemName, 'node');
//}

/**
 * Unloads system from hypervisor
 * @param {string} systemName - System name
 * @description Makes API request to unload system from hypervisor
 */
//function system_hyper_unload(systemName){
//	api_request('sys_hyper_unload', 'system', systemName, 'node');
//}

/**
 * Resets system
 * @param {string} systemName - System name
 * @description Makes API request to reset system
 */
//function system_reset(systemName){
//	api_request('sys_reset', 'system', systemName, 'node');
//}

/**
 * Loads system onto hypervisor
 * @param {string} systemName - System name
 * @param {string} nodeName - Node name to load system onto
 * @description Makes API request to load system onto specified node
 */
//function system_hyper_load(systemName, nodeName){
//	log_write_json("system_hyper_load", "[system_hyper_load]", "system [" + systemName + "] node [" + nodeName + "]");
//	api_request_callback('sys_hyper_load', 'system', systemName, nodeName, 'sys_hyper_load');
//}

//
//
//
//function system_hyper_validate(systemName, nodeName){
//	log_write_json("system_hyper_load", "[system_hyper_load]", "system [" + systemName + "] node [" + nodeName + "]");
//	api_request_callback('sys_hyper_validate', 'system', systemName, nodeName, 'node_hyper_sys_validate');
//}


/**
 * Clones system configuration
 * @param {string} sourceSystem - Source system name
 * @param {string} destinationSystem - Destination system name
 * @param {string} destuid - Destination system UID
 * @param {string} groupname - Group name
 * @param {string} poolname - Storage pool name
 * @description Makes API request to clone system configuration
 */


/**
 * Fully clones a system
 * @param {string} sourceSystem - Source system name
 * @param {string} destinationSystem - Destination system name
 * @param {string} destuid - Destination system UID
 * @param {string} nodeName - Node name
 * @param {string} group - Group name
 * @param {string} pool - Storage pool name
 * @description Makes API request to fully clone a system including storage
 */
//function system_clone_full(sourceSystem, destinationSystem, destuid, nodeName, groupName, poolName) {
	
//	var clone = {};
//	clone['dest_id'] = destuid;
//	clone['dest_name'] = destinationSystem;
//	clone['group'] = groupName;
//	clone['pool'] = poolName;
	
//	api_request_callback_extended('sys_clone_full', 'system', sourceSystem, nodeName, 'system_clone_full', 'clone', clone);
//}

/**
 * Moves a system to new location
 * @param {string} sourceSystem - Source system name
 * @param {string} destinationSystem - Destination system name
 * @param {string} destuid - Destination system UID
 * @param {string} nodeName - Node name
 * @param {string} group - Group name
 * @param {string} pool - Storage pool name
 * @description Makes API request to move system to new location
 */
//function system_move_full(sourceSystem, destinationSystem, destuid, nodeName, groupName, poolName) {
//	
//	var clone = {};
//	clone['dest_id'] = destuid;
//	clone['dest_name'] = destinationSystem;
//	clone['group'] = groupName;
//	clone['pool'] = poolName;
	
//	api_request_callback_extended('sys_move_full', 'system', sourceSystem, nodeName, 'system_move_full', 'clone', clone);
//}

/**
 * Migrates system between nodes
 * @param {string} sys - System name
 * @param {string} srcnode - Source node name
 * @param {string} destnode - Destination node name
 * @description Makes API request to migrate system between nodes
 */
function system_migrate(systemName, sourceNode, destNode) {
	
	var migrate = {};
	migrate['dest_node'] = destNode;
	migrate['src_node'] = srcNode;
	migrate['sys_id'] = systemName;

	api_request_callback_extended('node_hyper_sys_migrate', destNode, systemName, srcNode, 'system_migrate', 'migrate', migrate);
}

/**
 * Original system clone function (legacy)
 * @param {string} sourceSystem - Source system name
 * @param {string} destinationSystem - Destination system name
 * @param {string} destuid - Destination system UID
 * @param {string} nodeName - Node name
 * @description Legacy API request to clone system
 */
//function system_clone_full_orig(sourceSystem, destinationSystem, destuid, nodeName) {
//	api_request_service_callback('sys_clone_full', destinationSystem, sourceSystem, destuid, nodeName, 'system_clone_full');
//}

/**
 * Creates a new system
 * @param {string} sourceSystem - Source system name
 * @param {string} nodeName - Node name
 * @description Makes API request to create new system
 */
//function system_create_full(sourceSystem, nodeName) {
//	api_request_service_callback('node_hyper_sys_create', 'aa', sourceSystem, 'bb', nodeName, 'system_create_full');
//}

/**
 * Creates storage device for system
 * @param {string} systemName - System name
 * @param {string} storageDevice - Storage device name
 * @param {string} nodeName - Node name
 * @description Makes API request to create storage device for system
 */
function system_async_stordev_create(systemName, storageDevice, nodeName) {
	api_request_callback('node_hyper_sys_stor_add', storageDevice, systemName, nodeName, 'system_create_stordev');
}

/**
 * Cleans up system view
 * @description Resets system view UI elements to default state
 */
function system_view_cleanup(){
	
	$('#main-system-btn-load').prop('disabled', true);
	$('#main-system-btn-reset').prop('disabled', true);
	$('#main-system-btn-shutdown').prop('disabled', true);
	$('#main-system-btn-unload').prop('disabled', true);
	
	$('#main-system-btn-migrate').prop('disabled', true);
	$('#main-system-btn-livemig').prop('disabled', true);
	
	$('#main-system-btn-console').prop('disabled', true);
	$('#main-system-btn-webconsole').prop('disabled', true);
	$('#main-system-btn-ssh').prop('disabled', true);
	
	$('#main-system-btn-clone').prop('disabled', true);
	$('#main-system-btn-copycfg').prop('disabled', false);
	$('#main-system-btn-create').prop('disabled', true);
	
	$('#main-system-btn-move').prop('disabled', true);
	
	$('#main-system-btn-save').prop('disabled', true);
	
	$("#sysResourceTable tbody tr").remove();
	$("#sysResourceNetTable tbody tr").remove();
	$("#sysResourceStorTable tbody tr").remove();
	
	$("#sysStatusHyper tbody tr").remove();
	$("#sysStatusVMM tbody tr").remove();
	$("#sysStatusState tbody tr").remove();
	
	$("#sysStatusMessage tbody tr").remove();
	
	
	document.getElementById("systemCpuProgress").style.width = 0 + "%";
	document.getElementById("systemCpuProgress").innerHTML = "<b>" + "0" + " %</b>";

	document.getElementById("systemCpuTotProgress").style.width = 0 + "%";
	document.getElementById("systemCpuTotProgress").innerHTML = "<b>" + "0" + " %</b>";
	
	document.getElementById("systemRamProgress").style.width = 0 + "%";
	document.getElementById("systemRamProgress").innerHTML = "<b>" + "0" + " %</b>";
	
	document.getElementById("sysResourceStorDiv").innerHTML = "";
	
	document.getElementById("systemRamTotProgress").style.width = 0 + "%";
	document.getElementById("systemRamTotProgress").innerHTML = "";
	
	document.getElementById("main-system-state-header").innerHTML = "State [<b>OFFLINE</b>]";	
	document.getElementById("main-system-resource-header").innerHTML = "Resouces [<b>n/a</b>]";
	
	
	document.getElementById("systemCpuConsumed").innerHTML = "CPU Usage vs Cores";
	document.getElementById("systemRamConsumed").innerHTML = "Memory Consumption";
}

/**
 * Refreshes system data
 * @param {string} systemName - System name
 * @description Refreshes system data and shows toast notification
 */
function system_refresh(systemName) {
	mainRefreshAllViews();
}


/**
 * Shows system details view
 * @param {string} systemName - System name
 * @description Main function to display system details view
 */
function system_show(systemName) {
	main_hide_all();
	main_system_show();
	system_view_cleanup();
	
	// get system
	var systemData = dbnew_system_get(systemName);

	if(systemData){

		main_view_set('system_show', systemName, '');

		document.getElementById("main-system-btn-json").onclick = function() { json_show("[ " + systemName + " ]", systemName, "system", systemData) };

		// refresh
		document.getElementById("main-system-btn-refresh").onclick = function() { system_refresh(systemName) };
		
		//
		// header
		//
		document.getElementById("main-system-header").textContent = "[ " + systemName + " ]";
		
		//
		// identity
		//
		document.getElementById("main-system-uid").value = systemData.id.id;
		$('#main-system-uid').prop('disabled', true);
		
		document.getElementById("main-system-name").value = systemData.id.name;
		$('#main-system-name').prop('disabled', true);
		
		document.getElementById("main-system-desc").value = systemData.id.desc;
		document.getElementById("main-system-group").value = systemData.id.group;
		
		//
		// hardware
		//
		document.getElementById("main-system-cpu-sock").value = systemData.hw.cpu.sock;
		document.getElementById("main-system-cpu-core").value = systemData.hw.cpu.core;
		//document.getElementById("main-system-cpu-nest").value = system.hw.cpu.nest;
		document.getElementById("main-system-cpu-arch").value = systemData.hw.cpu.arch;
		$('#main-system-cpu-arch').prop('disabled', true);
		
		// cpu model
		if((typeof systemData.hw.cpu.model !== 'undefined')){
			document.getElementById("main-system-cpu-model").value = systemData.hw.cpu.model;
		}
		else{
			document.getElementById("main-system-cpu-model").value = "";
		}

		// cpu model
		if((typeof systemData.hw.cpu.nest !== 'undefined')){
			document.getElementById("main-system-cpu-nest").value = systemData.hw.cpu.nest;
		}
		else{
			document.getElementById("main-system-cpu-nest").value = 0;
		}

		// bios
		if((typeof systemData.hw.bios !== 'undefined') && (typeof systemData.hw.bios.mode !== 'undefined')){
			document.getElementById("main-system-bios-sel").value = systemData.hw.bios.mode;
			
			if((typeof systemData.hw.bios.mode !== 'undefined')){
				document.getElementById("main-system-bios-model").value = systemData.hw.bios.model;
			}
			else{
				document.getElementById("main-system-bios-model").value = "";
			}
			
		}
		else{
			document.getElementById("main-system-bios-sel").value = "legacy";
			document.getElementById("main-system-bios-model").value = "";
		}
		
		// tags
		if((typeof systemData.id.tags !== 'undefined')){
			document.getElementById("main-system-tags").value = systemData.id.tags;
		}
		else{
			document.getElementById("main-system-tags").value = "";
			
		}

		// tags
		if((typeof systemData.hw.extra !== 'undefined')){
			document.getElementById("main-system-extra").value = systemData.hw.extra;
		}
		else{
			document.getElementById("main-system-extra").value = "";
			
		}
		
		
		document.getElementById("main-system-mem-mb").value = systemData.hw.mem.mb;
		document.getElementById("main-system-mem-numa").value = systemData.hw.mem.numa;
		$('#main-system-mem-numa').prop('disabled', true);
		
		// identity header
		document.getElementById("main-system-id-header").innerHTML = "Name [" + '<b style="color:#0040ff">' + systemData.id.name + "</b>] id [<b>" + systemData.id.id + "</b>] group [<b>" + systemData.id.group + "</b>] description [<b>" + systemData.id.desc + "</b>]";
		
		// hardware header
		document.getElementById("main-system-hw-header").innerHTML = "CPU type [<b>" + systemData.hw.cpu.type + "</b>] arch [<b>" + systemData.hw.cpu.arch + "</b>] sockets [<b>" + systemData.hw.cpu.sock + "</b>] cores [<b>" + systemData.hw.cpu.core + "</b>] memory [<b>" + systemData.hw.mem.mb + " MB</b>]";
		
		$("#systemAsyncTable tbody tr").remove();
		document.getElementById("main-system-async-header").innerHTML = "Async Jobs [" +  "n/a" + "]";
		
		var hasAsyncJobs = false;
		
		if(systemData.meta.state == "1"){
			//
			// clear buttons
			//
			$('#main-system-btn-load').prop('disabled', true);
			$('#main-system-btn-load-dropdown').prop('disabled', true);
			$('#main-system-btn-reset').prop('disabled', false);
			$('#main-system-btn-shutdown').prop('disabled', false);
			$('#main-system-btn-unload').prop('disabled', false);
			$('#main-system-btn-validate').prop('disabled', true);
			$('#main-system-btn-delete').prop('disabled', true);
			
			$('#main-system-btn-migrate').prop('disabled', false);
			$('#main-system-btn-livemig').prop('disabled', false);
			
			$('#main-system-btn-console').prop('disabled', false);
			$('#main-system-btn-ssh').prop('disabled', false);
			
			$('#main-system-btn-save').prop('disabled', true);
			$('#main-system-btn-clone').prop('disabled', true);
			$('#main-system-btn-copycfg').prop('disabled', false);
			$('#main-system-btn-create').prop('disabled', true);
			
			//
			// init buttons
			//
			document.getElementById("main-system-btn-console").onclick = function() { system_console(systemName); }; 
			document.getElementById("main-system-btn-webconsole").onclick = function() { system_novnc_open(systemName); }; 
			
			if((typeof systemData.meta.novnc_port !== 'undefined')){
				$('#main-system-btn-webconsole').prop('disabled', false);
			}
			
			document.getElementById("main-system-btn-ssh").onclick = function() { system_ssh(systemName); }; 
			document.getElementById("main-system-btn-reset").onclick = function() { system_reset_accept(systemName); }; 
			document.getElementById("main-system-btn-shutdown").onclick = function() { system_shutdown_accept(systemName); };
			document.getElementById("main-system-btn-unload").onclick = function() { system_unload_accept(systemName); };
			document.getElementById("main-system-btn-clone").onclick = function() { system_clone_full_accept(systemName, systemData.id.group); };
			document.getElementById("main-system-btn-copycfg").onclick = function() { system_clone_config_accept(systemName, systemData.id.group); };
			
			// compat with older API
			if((typeof systemData.meta.stats !== 'undefined')){
			
				if((typeof systemData.object.meta !== 'undefined')){
					var diff = date_str_diff_now(systemData.object.meta.date);
					//document.getElementById("main-system-state-header").innerHTML = 'State [<b style="color:#24be14">ONLINE</b>] status [<b>' + system.state.vm_status + "</b>] ver [<b>" + system.object.meta.ver + "</b>] updated [<b>" + system.object.meta.date + "</b>] delta [<b>" + system.object.meta.delta + "</b>] node [<b>" + system.meta.node_name + "</b>] id [<b>" + system.meta.node_id + "</b>]";
					document.getElementById("main-system-state-header").innerHTML = 'State [<b style="color:#24be14">ONLINE</b>] status [<b>' + systemData.state.vm_status + "</b>] ver [<b>" + systemData.object.meta.ver + "</b>] updated [<b>" + systemData.object.meta.date + "</b>] delta [<b>" + diff + "</b>] node [<b>" + systemData.meta.node_name + "</b>] id [<b>" + systemData.meta.node_id + "</b>]";
				}
				else{
					document.getElementById("main-system-state-header").innerHTML = 'State [<b style="color:#24be14">ONLINE</b>] status [<b>' + systemData.state.vm_status + "</b>] not in cluster";
				}
			
				
				if((typeof systemData.meta.stats.hypervisor !== 'undefined')){
					document.getElementById("main-system-resource-header").innerHTML = "System uptime [<b>" + systemData.meta.stats.hypervisor.uptime + "</b>] booted [<b>" + systemData.meta.stats.hypervisor.boot + "</b>] cpu [<b> " + systemData.meta.stats.hypervisor.cpu + "% </b>] ";

					document.getElementById("systemCpuProgress").style.width = parseInt(systemData.meta.stats.hypervisor.cpu) + "%";
					document.getElementById("systemCpuProgress").innerHTML = "<b>" + systemData.meta.stats.hypervisor.cpu + " %</b>";

					// cpu
					var totalCpuPercentage = parseInt(systemData.hw.cpu.core) * 100;
					var cpuPercentage = (100 * parseInt(systemData.meta.stats.hypervisor.cpu)) / totalCpuPercentage;

					document.getElementById("systemCpuConsumed").innerHTML = "CPU Usage vs Cores - Allocated cores [<b>" + systemData.hw.cpu.core + "</b>]";
					
					//progress
					document.getElementById("systemCpuTotProgress").style.width = cpuPercentage + "%";
					document.getElementById("systemCpuTotProgress").innerHTML = "<b>" + cpuPercentage.toFixed(1) + " %</b>";
				
				}
				
				var memoryUsed = 0;
				var memoryPercentage = 0;
				
				// check for hypervisor stats
				if((typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.meta.stats.hypervisor.rss !== 'undefined')){
				
					if(systemData.meta.stats.hypervisor.rss.includes('M')){
						memoryInGb = parseInt(systemData.hw.mem.mb);
						memoryPercentage = (100 * parseFloat(systemData.meta.stats.hypervisor.rss)) / memoryInGb;
						
						document.getElementById("systemRamProgress").style.width = memoryPercentage + "%";
						document.getElementById("systemRamProgress").innerHTML = "<b>" + memoryPercentage.toFixed(1) + " %</b>";
						document.getElementById("systemRamConsumed").innerHTML = "Memory Consumption - Reserved [<b>" + memoryInGb + "M</b>] used [<b>" + systemData.meta.stats.hypervisor.rss + "</b>]";
						
						memoryUsed = memoryInGb + "M";
					}
					
					if(systemData.meta.stats.hypervisor.rss.includes('G')){
						memoryInGb = parseInt(systemData.hw.mem.mb / 1024);
						memoryPercentage = (100 * parseFloat(systemData.meta.stats.hypervisor.rss)) / memoryInGb;
					
						document.getElementById("systemRamProgress").style.width = memoryPercentage + "%";
						document.getElementById("systemRamProgress").innerHTML = "<b>" + memoryPercentage.toFixed(1) + " %</b>";
						document.getElementById("systemRamConsumed").innerHTML = "Memory Consumption - Reserved [<b>" + memoryInGb + "G</b>] used [<b>" + systemData.meta.stats.hypervisor.rss + "</b>]";
						
						memoryUsed = memoryInGb + "G";
					}
					
					document.getElementById("systemRamTotProgress").style.width = parseInt(systemData.meta.stats.hypervisor.mem) + "%";
					document.getElementById("systemRamTotProgress").innerHTML = "<b>" + systemData.meta.stats.hypervisor.mem + " %</b>";
					document.getElementById("main-system-resource-header").innerHTML += "memory [<b> " + systemData.meta.stats.hypervisor.rss + " / " + memoryUsed + "</b> ] used [<b> " + memoryPercentage.toFixed(0) + "% </b>]";

					//hypervisor
					var tbodyHyper = $("#sysStatusHyper tbody");
					tbodyHyper.append("<tr><td>" + systemData.meta.stats.hypervisor.pid + "</td><td>" + systemData.meta.stats.hypervisor.boot + "</td><td>" + systemData.meta.stats.hypervisor.uptime + "</td><td>" + systemData.meta.stats.hypervisor.updated + "</td><td><b>" + systemData.meta.stats.hypervisor.cpu + " %</b></td><td><b>" + systemData.meta.stats.hypervisor.mem + " %</b></td><td><b>" + memoryPercentage.toFixed(1) + " %</b></td><td><b>" + systemData.meta.stats.hypervisor.rss + "</b></td><tr>");

					//VMM
					var tbodyVMM = $("#sysStatusVMM tbody");
					tbodyVMM.append("<tr><td>" + systemData.meta.vmm.system_id + "</td><td>" + systemData.meta.vmm.system_name + "</td><td>" + systemData.meta.vmm.node_id + "</td><td>" + systemData.meta.vmm.node_name + "</td><td>" + systemData.meta.vmm.pid + "</td><td>" + systemData.meta.vmm.date + "</td><td>" + systemData.meta.vmm.socket + "</td><td>" + systemData.meta.vmm.log + "</td><td>" + systemData.meta.vmm.state + "</td></tr>");
					
					var tbodyState = $("#sysStatusState tbody");
					tbodyState.append("<tr><td>" + systemData.state.vmm_pid + "</td><td>" + systemData.state.vmm_proc + "</td><td>" + systemData.state.vmm_error + "</td><td>" + systemData.state.vmm_state + "</td><td>" + systemData.state.vmm_status + "</td><td>" + systemData.state.vm_lock + "</td><td>" + systemData.state.vm_state + "</td><td>" + systemData.state.vm_running + "</td><td><b>" + systemData.state.vm_status + "</b></td><tr>");
					
					// resource
					var tbodyResource = $("#sysResourceTable tbody");
					tbodyResource.append("<tr><td>" + systemData.meta.stats.hypervisor.pid + "</td><td>" + systemData.meta.stats.hypervisor.boot + "</td><td>" + systemData.meta.stats.hypervisor.uptime + "</td><td>" + systemData.meta.stats.hypervisor.updated + "</td><td><b>" + systemData.meta.stats.hypervisor.cpu + " %</b></td><td><b>" + systemData.meta.stats.hypervisor.mem + " %</b><td><b>" + memoryPercentage.toFixed(1) + " %</b></td></td><td><b>" + systemData.meta.stats.hypervisor.rss + "</b></td><tr>");
					
				}
				
				if((typeof systemData.meta !== 'undefined') && (typeof systemData.meta.stats !== 'undefined') && (typeof systemData.meta.stats.hypervisor !== 'undefined')){
					
					var tbodyAsyncTable = $("#systemAsyncTable tbody");
					
					if(typeof systemData.meta.stats.hypervisor.async !== 'undefined'){
						
						var tbodyAsyncTable = $("#systemAsyncTable tbody");
						tbodyAsyncTable.append("<tr><td><b>" + systemData.meta.stats.hypervisor.async.id + "</b></td><td><b>" + systemData.meta.stats.hypervisor.async.request + "</b></td><td>" + systemData.meta.stats.hypervisor.async.on_timeout + "</td><td>" + systemData.meta.stats.hypervisor.async.timeout + "</td><td><b>" + systemData.meta.stats.hypervisor.async.active + "</b></td><td>" + systemData.meta.stats.hypervisor.async.date + "</td><td><b>" + systemData.meta.stats.hypervisor.async.status + "</b></td><td><b>" + systemData.meta.stats.hypervisor.async.result + "</b></td><tr>");
						
						if(systemData.meta.stats.hypervisor.async.active == "1"){
							document.getElementById("main-system-async-header").innerHTML = "Async Jobs ["+ '<b style="color:#24be14">' + "ACTIVE</b>] request [<b>" + systemData.meta.stats.hypervisor.async.request + "</b>] status [<b>" + systemData.meta.stats.hypervisor.async.status + "</b>] result [<b>" + systemData.meta.stats.hypervisor.async.result + "</b>]";
						}
						else{
							document.getElementById("main-system-async-header").innerHTML = "Async Jobs [<b>INACTIVE</b>] request [<b>" + systemData.meta.stats.hypervisor.async.request + "</b>] status [<b>" + systemData.meta.stats.hypervisor.async.status + "</b>] result [<b>" + systemData.meta.stats.hypervisor.async.result + "</b>]";
						}
					}
			
				}
				else{
					//log_write_json("SYSTEM SERVICE", "SYSLIST", "NO DATA!!");
				}
				
				document.getElementById("main-system-btn-migrate").onclick = function() { system_migrate_accept(systemData); };
				
			}
			else{
				// legacy handling
				//document.getElementById("main-system-state-header").innerHTML = 'State [<b style="color:#24be14">ONLINE</b>] status [<b>' + system.state.vm_status + "</b>] updated [<b>" + system.stats.updated + "</b>] ";
			}
		}
		else{
			
			//
			// check for metadata
			//
			if((typeof systemData.meta !== 'undefined') && (typeof systemData.meta.stats !== 'undefined') && (typeof systemData.state !== 'undefined') && (typeof systemData.state.vm_status !== 'undefined')){
				
				if((typeof systemData.object.meta !== 'undefined')){
					
					if(systemData.state.vm_status == "init"){
						document.getElementById("main-system-state-header").innerHTML = 'State [<b style="color:#9400D3">INITIALIZING</b>] status [<b>' + systemData.state.vm_status + "</b>] ver [<b>" + systemData.object.meta.ver + "</b>] updated [<b>" + systemData.object.meta.date + "</b>]";
						$('#main-system-btn-load').prop('disabled', true);
					}
					else if(systemData.state.vm_status == "ended"){
						document.getElementById("main-system-state-header").innerHTML = 'State [<b style="color:#9400D3">ENDED</b>] status [<b>' + systemData.state.vm_status + "</b>] ver [<b>" + systemData.object.meta.ver + "</b>] updated [<b>" + systemData.object.meta.date + "</b>]";
						$('#main-system-btn-load').prop('disabled', true);
					}
					else{
						document.getElementById("main-system-state-header").innerHTML = 'State [<b>UNLOADED</b>] status [<b>' + systemData.state.vm_status + "</b>] ver [<b>" + systemData.object.meta.ver + "</b>] updated [<b>" + systemData.object.meta.date + "</b>]";
					}
					
				}
				else{
					document.getElementById("main-system-state-header").innerHTML = 'State [<b>UNLOADED</b>] status [<b>' + systemData.state.vm_status + "</b>]";
				}
				
				var tbodyState = $("#sysStatusState tbody");
				tbodyState.append("<tr><td>" + systemData.state.vmm_pid + "</td><td>" + systemData.state.vmm_proc + "</td><td>" + systemData.state.vmm_error + "</td><td>" + systemData.state.vmm_state + "</td><td>" + systemData.state.vmm_status + "</td><td>" + systemData.state.vm_lock + "</td><td>" + systemData.state.vm_state + "</td><td>" + systemData.state.vm_running + "</td><td><b>" + systemData.state.vm_status + "</b></td><tr>");
				
				if(typeof systemData.state.vmm_out !== 'undefined'){
					var tbodyMessage = $("#sysStatusMessage tbody");
					tbodyMessage.append("<tr><td>" + '<b style="color:#D2042D">' +  systemData.state.vmm_out +"</b></td><tr>");
				}
			}
			else{
				document.getElementById("main-system-state-header").innerHTML = "State [<b>OFFLINE</b>]";
				
				// check for additional vm status
				if((typeof systemData.state !== 'undefined') && (typeof systemData.state.vm_status !== 'undefined')){
					document.getElementById("main-system-state-header").innerHTML += " status [<b>" + systemData.state.vm_status + "</b>]";
					
					if(systemData.state.vm_status == "init"){
						$('#main-system-btn-load').prop('disabled', true);
					}
				}
				
				document.getElementById("main-system-async-header").innerHTML = "Async Jobs [<b>" +  "n/a" + "</b>]";
			}
			
			
			//
			// check for system lock
			//
			if((typeof systemData.meta !== 'undefined') && (typeof systemData.meta.lock !== 'undefined') && (systemData.meta.lock == '1')){
					$('#main-system-btn-load').prop('disabled', true);
					$('#main-system-btn-clone').prop('disabled', true);
					$('#main-system-btn-save').prop('disabled', true);
					$('#main-system-btn-copycfg').prop('disabled', true);
					$('#main-system-btn-validate').prop('disabled', true);
					$('#main-system-btn-delete').prop('disabled', true);
					
					document.getElementById("main-system-state-header").innerHTML += " - [" + '<b style="color:#D2042D">' + "system is locked" + "</b>]";
			}
			else{
				$('#main-system-btn-load').prop('disabled', false);
				$('#main-system-btn-clone').prop('disabled', false);
				$('#main-system-btn-save').prop('disabled', false);
				$('#main-system-btn-copycfg').prop('disabled', false);
				$('#main-system-btn-validate').prop('disabled', false);
				$('#main-system-btn-delete').prop('disabled', false);
				
				$('#main-system-btn-move').prop('disabled', false);
			}
			
			//
			// check for system init flag
			//
			if((typeof systemData.object !== 'undefined') && (typeof systemData.object.init !== 'undefined') && (systemData.object.init == '0')){
				$('#main-system-btn-create').prop('disabled', false);
				document.getElementById("main-system-btn-create").onclick = function() { system_create_full_accept(systemName); };
				
				$('#main-system-btn-load').prop('disabled', true);
				$('#main-system-btn-clone').prop('disabled', true);
				$('#main-system-btn-validate').prop('disabled', false);
				$('#main-system-btn-delete').prop('disabled', false);
				
				document.getElementById("main-system-state-header").innerHTML += " - [" + '<b style="color:#D2042D">' + "system not initialized" + "</b>]";
			}

			//
			// check for extra async data
			//
			if((typeof systemData.meta !== 'undefined') && (typeof systemData.meta.stats !== 'undefined') && (systemData.meta.stats !== null) && (typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.meta.stats.hypervisor.async !== 'undefined')){
				var tbodyAsyncTable = $("#systemAsyncTable tbody");
				var asyncData = systemData.meta.stats.hypervisor.async;
				tbodyAsyncTable.append("<tr><td><b>" + asyncData.id + "</b></td><td><b>" + asyncData.request + "</b></td><td>" + asyncData.on_timeout + "</td><td>" + asyncData.timeout + "</td><td><b>" + asyncData.active + "</b></td><td>" + asyncData.date + "</td><td><b>" + asyncData.status + "</b></td><td><b>" + asyncData.result + "</b></td><tr>");
				
				if(asyncData.active == "1"){
					document.getElementById("main-system-async-header").innerHTML = "Async Jobs [" + '<b style="color:#24be14">ACTIVE</b>' + "] request [<b>" + asyncData.request + "</b>] status [<b>" + asyncData.status + "</b>] result [<b>" + asyncData.result + "</b>]";
				}
				else{
					document.getElementById("main-system-async-header").innerHTML = "Async Jobs [<b>INACTIVE</b>] request [<b>" + asyncData.request + "</b>] status [<b>" + asyncData.status + "</b>] result [<b>" + asyncData.result + "</b>]";
				}
			}
			else{
				//$('#main-system-btn-load').prop('disabled', true);
			}

			
			$('#main-system-btn-reset').prop('disabled', true);
			$('#main-system-btn-shutdown').prop('disabled', true);
			$('#main-system-btn-unload').prop('disabled', true);
			
			$('#main-system-btn-migrate').prop('disabled', true);
			$('#main-system-btn-livemig').prop('disabled', true);
			
			$('#main-system-btn-console').prop('disabled', true);
			$('#main-system-btn-ssh').prop('disabled', true);
					
			document.getElementById("main-system-btn-save").onclick = function() { system_save_config(systemName, systemData) };
			document.getElementById("main-system-btn-clone").onclick = function() { system_clone_full_accept(systemName, systemData.id.group); };
			document.getElementById("main-system-btn-copycfg").onclick = function() { system_clone_config_accept(systemName, systemData.id.group); };
			document.getElementById("main-system-btn-move").onclick = function() { system_move_full_accept(systemData); };
			
			document.getElementById("main-system-btn-delete").onclick = function() { system_delete_accept(systemName); };
			document.getElementById("main-system-btn-validate").onclick = function() { system_validate_accept(systemName); };
			
			
			document.getElementById("main-system-btn-load").onclick = function() { system_load_accept(systemData, systemName) };

		}
		
		//
		// initialize storage
		//
		system_storage_view_init(systemData);
		
		//
		// initialize network
		// 
		system_network_view_init(systemData);
	
	}
	else{
		console.log("ERROR: failed to fetch system data!");
		toast_show("SYSTEM | ERROR", "bi-exclamation-diamond", "SYSTEM", "Failed to get system data!");
	}

}

/**
 * Opens noVNC console for system
 * @param {string} systemName - System name
 * @description Opens new window with noVNC console for system
 */
function system_novnc_open(systemName){
	var systemData = dbnew_system_get(systemName);
	var nodeData = dbnew_node_get(systemData.meta.node_name);
	
	if(nodeData.host.address){
		console.log("node address [" + nodeData.host.address + "]");
		
		if((typeof systemData.meta.novnc_port !== 'undefined')){
			var connect_str = "http://" + api_host_get() + "/aapen/novnc/vnc.html?host=" + nodeData.host.address + "&port=" + systemData.meta.novnc_port + "&autoconnect=true&resize=scale";
			window.open(connect_str, '_blank');
		}
		else{
			console.log("failed to get system novnc port!");
		}
		
	}
	else{
		console.log("failed to get node address!");
	}
	
}

/**
 * Shows network statistics for system
 * @param {string} systemName - System name
 * @param {string} networkName - Network name
 * @description Displays network statistics table for system
 */
function system_network_stats(systemName, networkName){
	//var system = db_system_get(systemName);
	var systemData = dbnew_system_get(systemName);

	log_write_json("system_network_stats", "[top::syslist]", systemData);

	if((typeof systemData !== 'undefined') ){

		var tbody = $("#netSystemTable tbody");
		var networkDevices = systemData.net.dev;
		networkIndex = networkDevices.split(';');
		
		// network devices
		networkIndex.forEach((networkDevice) => {
			
			// check if networkDevice is actually part of this vlan
			if(systemData.net[networkDevice].net.name == networkName){
				var sysState = "<b>OFFLINE</b>";
					
				if((typeof systemData.meta.state !== 'undefined') && systemData.meta.state == 1){
					sysState = view_color_healthy("ONLINE");
				}
			
				if(systemData.net[networkDevice].net.type == "bri-tap"){
	
					if((typeof systemData.meta.stats !== 'undefined')){
						//tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemName  + "</a></b></td><td><b>" + networkDevice + "</b></td><td>" + sysState + "</td><td><b>" + systemData.meta.stats.network[networkDevice].tx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].tx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].tx.errors.errors + "</td><td>" + systemData.meta.stats.network[networkDevice].tx.errors.dropped + "</td><td><b>" + systemData.meta.stats.network[networkDevice].rx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].rx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].rx.errors.errors + "</td><td>" + systemData.meta.stats.network[networkDevice].rx.errors.dropped + "</td></tr>");
						tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemName  + "</a></b></td><td><b>" + networkDevice + "</b></td><td>" + sysState + "</td><td><b>" + systemData.meta.stats.network[networkDevice].tx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].tx.packets + "</td><td>" + (systemData.meta.stats.network[networkDevice].tx.errors.errors || "0") + "</td><td>" + (systemData.meta.stats.network[networkDevice].tx.errors.dropped || "0") + "</td><td><b>" + systemData.meta.stats.network[networkDevice].rx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].rx.packets + "</td><td>" + (systemData.meta.stats.network[networkDevice].rx.errors.errors || "0") + "</td><td>" + (systemData.meta.stats.network[networkDevice].rx.errors.dropped || "0") + "</td></tr>");
					}
					else{
						tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemName  + "</a></b></td><td><b>" + networkDevice + "</b></td><td>" + sysState + "</td><td><b>" + "n/a" + "</b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td><b>" + "n/a" + "</b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td></tr>");	
					}
				}
				
				if(systemData.net[networkDevice].net.type == "dpdk-vpp"){

					if((typeof systemData.meta.stats !== 'undefined')){
						tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemName  + "</a></b></td><td><b>" + networkDevice + "</b></td><td>" + sysState + "</td><td><b>" + systemData.meta.stats.network[networkDevice].tx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].tx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].tx.errors + "</td><td>" + systemData.meta.stats.network[networkDevice].drops + "</td><td><b>" + systemData.meta.stats.network[networkDevice].rx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].rx.packets + "</td><td>" + "0" + "</td><td>" + systemData.meta.stats.network[networkDevice].drops + "</td></tr>");
					}
					else{
						tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemName  + "</a></b></td><td><b>" + networkDevice + "</b></td><td>" + sysState + "</td><td><b>" + "n/a" + "</b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td><b>" + "n/a" + "</b></td><td>" + "n/a" + "</td><td>" + "0" + "</td><td>" + "n/a" + "</td></tr>");
					}
				}
				
				document.getElementById("tempbtn_netsysbl").id = "tempbtn_netsysbl_" + systemName;
				document.getElementById("tempbtn_netsysbl_" + systemName).onclick = function() { system_show(systemName) };
			}
		});	
		
	}
}

/**
 * Initializes system network view
 * @param {Object} system - System object
 * @description Sets up network configuration UI for system
 */
function system_network_view_init(systemData){
	
	var networkDevices = systemData.net.dev;
	networkIndex = networkDevices.split(';');

	var networkAccordionContainer = document.getElementById('accordionSystemNetwork');	
	networkAccordionContainer.innerHTML = "";

	var heading = "Configure - Devices [<b>" + networkIndex + "</b>]";
	var accordionNetSettings = view_accordion_build("accordionSystemNetSettings", "collapseNetSettings", "bi-gear", heading);
	var networkSettingsContainer = view_accordion_element_build("collapseNetSettings", "headingSystemNetSet", "accordionSystemNetSettings");
	
	var networkSettingsRow = document.createElement("div");
	networkSettingsRow.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2");
	
	//
	// Options
	//
	var networkManagementColumn = document.createElement("div");
	networkManagementColumn.setAttribute("class", "col-lg-2 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");	
	
	var header = view_header_build("Manage Network", "bi-tools");
	networkManagementColumn.appendChild(header);
	
	var btnAddNic = view_btn_type1_build("btnSysAddNic", "bi-ethernet", "Add NIC");
	btnAddNic.onclick = function() { system_netdev_add_accept(systemData.id.name) };
	networkManagementColumn.appendChild(btnAddNic);
	
	var btnDelNic = view_btn_type1_build("btnSysDelNic", "bi-x-square", "Remove NIC");
	btnDelNic.onclick = function() { system_netdev_remove_accept(systemData.id.name) };
	networkManagementColumn.appendChild(btnDelNic);

	networkSettingsRow.appendChild(networkManagementColumn);
	
	networkSettingsContainer.appendChild(networkSettingsRow);
	
	accordionNetSettings.appendChild(networkSettingsContainer);
	
	networkAccordionContainer.appendChild(accordionNetSettings);
		
	//
	// settings
	//	
	if(systemData.net.dev !== ""){
		// network devices
		networkIndex.forEach((networkDevice) => {
			system_network_device_add(networkDevice, systemData);
		});	
	}
}

/**
 * Initializes system storage view
 * @param {Object} system - System object
 * @description Sets up storage configuration UI for system
 */
function system_storage_view_init(systemData){

	// clear view
	var storageAccordionContainer = document.getElementById('accordionSystemStorage');	
	storageAccordionContainer.innerHTML = "";
	
	var heading = "Configure - Devices [<b>" + systemData.stor.disk + "</b>] ISO [<b>" + systemData.stor.iso + "</b>] - Boot device [<b>" + systemData.stor.boot + "</b>]";
	var accordionStorSettings = view_accordion_build("accordionSystemStorageSettings", "collapseStorSettings", "bi-gear", heading);
	var storageSettingsContainer = view_accordion_element_build("collapseStorSettings", "headingSystemStorSet", "accordionSystemStorageSettings");
	
	var storageSettingsRow = document.createElement("div");
	storageSettingsRow.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2");
	

	//
	// Boot
	//
	var bootDeviceColumn = document.createElement("div");
	bootDeviceColumn.setAttribute("class", "col-lg-2 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Boot Device", "bi-braces-asterisk");
	bootDeviceColumn.appendChild(header);
	
	var bootList = system_bootopts_enumerate(systemData);
	var divBoot = view_selector_build("sysBootSelect" + systemData.id.name, "Boot", bootList, systemData.stor.boot);
	divBoot.onchange = function() { system_boot_change(systemData.id.name) };
	bootDeviceColumn.appendChild(divBoot);
	
	storageSettingsRow.appendChild(bootDeviceColumn);
	

	//
	// Options
	//
	var storageManagementColumn = document.createElement("div");
	storageManagementColumn.setAttribute("class", "col-lg-9 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");	
	
	var header = view_header_build("Manage Storage", "bi-tools");
	storageManagementColumn.appendChild(header);
	
	var btnAddDev = view_btn_type1_build("btnSysAddDev", "bi-hdd", "Add Device");
	btnAddDev.onclick = function() { system_stordev_add_accept(systemData.id.name, systemData) };	
	storageManagementColumn.appendChild(btnAddDev);
	
	var btnAddIso = view_btn_type1_build("btnSysAddDev", "bi-vinyl", "Add Iso");
	btnAddIso.onclick = function() { system_storiso_add_accept(systemData.id.name) };	
	storageManagementColumn.appendChild(btnAddIso);
	
	var btnDevCheck = view_btn_type1_build("btnSyDevCheck", "bi-heart-pulse", "Check Storage");	
	btnDevCheck.setAttribute("disabled", "true");
	storageManagementColumn.appendChild(btnDevCheck);

	var btnDevGrow = view_btn_type1_build("btnSyDevGrow", "bi-plus-square-dotted", "Expand Device");	
	btnDevGrow.setAttribute("disabled", "true");
	storageManagementColumn.appendChild(btnDevGrow);

	var btnDevSnap = view_btn_type1_build("btnSyDevGrow", "bi-bezier2", "Snapshot Device");	
	btnDevSnap.setAttribute("disabled", "true");
	storageManagementColumn.appendChild(btnDevSnap);

	var btnDevCreate = view_btn_type1_build("btnSyDevCreate", "bi-plus-square", "Create Storage");	
	btnDevCreate.onclick = function() { system_stordev_create_accept(systemData, systemData.id.name) };
	storageManagementColumn.appendChild(btnDevCreate);

	var btnDevCopy = view_btn_type1_build("btnSyDevGrow", "bi-files", "Copy Device");	
	btnDevCopy.setAttribute("disabled", "true");
	storageManagementColumn.appendChild(btnDevCopy);
	
	var btnStorMove = view_btn_type1_build("btnSyDevGrow", "bi-box-arrow-in-right", "Move Storage");	
	btnStorMove.onclick = function() { system_storage_move_accept(systemData.id.name) };	
	storageManagementColumn.appendChild(btnStorMove);

	var btnDevRemove = view_btn_type1_build("btnSyDevGrow", "bi-x-square", "Delete Device");	
	btnDevRemove.onclick = function() { system_stordev_remove_accept(systemData.id.name); };
	storageManagementColumn.appendChild(btnDevRemove);
	
	
	storageSettingsRow.appendChild(storageManagementColumn);
	
	storageSettingsContainer.appendChild(storageSettingsRow);
	
	accordionStorSettings.appendChild(storageSettingsContainer);
	
	storageAccordionContainer.appendChild(accordionStorSettings);
	
	
	//
	// enumerate storage devs
	//
	if(systemData.stor.disk !== ""){	
		var stor = systemData.stor.disk;
		stor_index = stor.split(';');
		
		// storage devices
		stor_index.forEach((stordev) => {
			system_storage_item_add(stordev, systemData);
		});
	}	
	
	// iso
	if(systemData.stor.iso !== ""){	
		var iso = systemData.stor.iso;
		iso_index = iso.split(';');

		iso_index.forEach((isodev) => {
			system_storage_iso_add(isodev, systemData);
		});
	}

}

/**
 * Shows hypervisor data for system
 * @param {Object} hyperdata - Hypervisor data object
 * @description Displays hypervisor async job data
 */
function system_show_hypervisor(hyperData){
	
	if(hyperData.proto.result == "1"){
		
		if(typeof hyperData.response.service !== 'undefined'){
			
			var tbodyAsyncTable = $("#systemAsyncTable tbody");
			
			if(typeof hyperData.response.service.hypervisor[hyperData.request.node].hyper.async !== 'undefined'){
				
				if(typeof hyperData.response.service.hypervisor[hyperData.request.node].hyper.async[hyperData.request.id] !== 'undefined'){
					document.getElementById("main-system-async-header").innerHTML = "Async Jobs [" +  "DATA DATA DATA!!" + "]";
					
					var asyncData = hyperData.response.service.hypervisor[hyperData.request.node].hyper.async[hyperData.request.id];
					
					var tbodyAsyncTable = $("#systemAsyncTable tbody");
					tbodyAsyncTable.append("<tr><td><b>" + asyncData.id + "</b></td><td><b>" + asyncData.request + "</b></td><td>" + asyncData.on_timeout + "</td><td>" + asyncData.timeout + "</td><td><b>" + asyncData.active + "</b></td><td>" + asyncData.date + "</td><td><b>" + asyncData.status + "</b></td><td><b>" + asyncData.result + "</b></td><tr>");
					
					if(asyncData.active === "1"){
						document.getElementById("main-system-async-header").innerHTML = "Async Jobs ["+ '<b style="color:#24be14">' + "ACTIVE</b>] request [<b>" + asyncData.request + "</b>] status [<b>" + asyncData.status + "</b>] result [<b>" + asyncData.result + "</b>]";
					}
					else{
						document.getElementById("main-system-async-header").innerHTML = "Async Jobs [<b>INACTIVE</b>] request [<b>" + asyncData.request + "</b>] status [<b>" + asyncData.status + "</b>] result [<b>" + asyncData.result + "</b>]";
					}
				}
			}
		}
	}
	else{
		log_write_json("system_show_hypervisor", "[system_show_ypervisor] FAILED", hyperData);
	}
}

/**
 * Adds storage device to view
 * @param {string} storageDevice - Storage device name
 * @param {Object} system - System object
 * @description Creates UI elements for storage device
 */
function system_storage_item_add(storageDevice, systemData) {

	var storageAccordionContainer = document.getElementById('accordionSystemStorage');
	var storageDeviceContainer = view_accordion_element_build("collapseStorDev" + storageDevice, "headingSystemStorage", "accordionSystemStorage");
	var sysStorHeader = "Device [<b>" + storageDevice + "</b>] - size [<b>" + systemData.stor[storageDevice].size + "GB</b>] type [<b>" + systemData.stor[storageDevice].type + "</b>] image [<b>" + systemData.stor[storageDevice].image + "</b>]";

	// check for stats
	if((typeof systemData.meta !== 'undefined') && (typeof systemData.meta.disk !== 'undefined') && (typeof systemData.meta.disk[storageDevice] !== 'undefined')){
		
		sysStorHeader += " - size [<b>" + systemData.meta.disk[storageDevice].virt_size + " " + systemData.meta.disk[storageDevice].virt_size_unit + "</b>] used [<b>" + systemData.meta.disk[storageDevice].disk_size + " " + systemData.meta.disk[storageDevice].disk_size_unit + "</b>]";
		
		var usedPerc = 0;
		
		//var virt_unit = "N/A";
		var virt_unit = systemData.meta.disk[storageDevice].virt_size_unit;
		
		var virt_size = 0;
		var disk_size = 0;
		
		// validate and add data
		if((typeof systemData.meta.stats !== 'undefined') && (typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk[storageDevice] !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk[storageDevice].size !== 'undefined')){
			var curr_unit = systemData.meta.stats.hypervisor.disk[storageDevice].size.match(/[^0-9]/g);
			var curr_size = systemData.meta.stats.hypervisor.disk[storageDevice].size.match(/\d+/g);
		
			virt_unit = niceUnits(systemData.meta.disk[storageDevice].virt_size_unit);
			disk_unit = niceUnits(systemData.meta.disk[storageDevice].disk_size_unit);
		
			if(systemData.meta.disk[storageDevice].disk_unit.includes("GiB") || systemData.meta.disk[storageDevice].disk_size_unit.includes("GB")){
				disk_size = parseInt(systemData.meta.disk[storageDevice].disk_size);
			}
			
			if(systemData.meta.disk[storageDevice].disk_unit.includes("TiB") && systemData.meta.disk[storageDevice].disk_size_unit.includes("TB")){
				disk_size = parseFloat(systemData.meta.disk[storageDevice].disk_size) * 1000;
			}
			
			if(curr_unit == "T"){
				curr_size = curr_size * 1000;
			}
			
			if(curr_unit == "K"){
				curr_size = curr_size / 1000;
			}

			if(systemData.meta.disk[storageDevice].virt_unit.includes("MiB") || systemData.meta.disk[storageDevice].virt_unit.includes("MB")){
				virt_size = parseInt(systemData.meta.disk[storageDevice].virt_size);
				//virt_unit = "MB";
			}
			
			
			if(systemData.meta.disk[storageDevice].virt_unit.includes("GiB") || systemData.meta.disk[storageDevice].virt_unit.includes("GB")){
				virt_size = parseInt(systemData.meta.disk[storageDevice].virt_size);
				//virt_unit = "GB";
			}
			
			if(systemData.meta.disk[storageDevice].virt_unit.includes("TiB") || systemData.meta.disk[storageDevice].virt_unit.includes("TB")){
				virt_size = parseFloat(systemData.meta.disk[storageDevice].virt_size) * 1000;
				//virt_unit = "TB";
			}	
			
			disk_size = curr_size;
			
		}
		else{
			var disk_unit = "n/a";
			var virt_unit = "n/a";
			
			virt_unit = niceUnits(systemData.meta.disk[storageDevice].virt_size_unit);
			disk_unit = niceUnits(systemData.meta.disk[storageDevice].disk_size_unit);
		
			if(systemData.meta.disk[storageDevice].disk_unit.includes("GiB") || systemData.meta.disk[storageDevice].disk_size_unit.includes("GB")){
				disk_size = parseInt(systemData.meta.disk[storageDevice].disk_size);
			}
			
			if(systemData.meta.disk[storageDevice].disk_unit.includes("TiB")  || systemData.meta.disk[storageDevice].disk_size_unit.includes("TB")){
				disk_size = parseFloat(systemData.meta.disk[storageDevice].disk_size) * 1000;
			}

			if(systemData.meta.disk[storageDevice].virt_unit.includes("MiB")  || systemData.meta.disk[storageDevice].disk_size_unit.includes("MB")){
				virt_size = parseInt(systemData.meta.disk[storageDevice].virt_size);
			}
			
			if(systemData.meta.disk[storageDevice].virt_unit.includes("GiB") || systemData.meta.disk[storageDevice].disk_size_unit.includes("GB")){
				virt_size = parseInt(systemData.meta.disk[storageDevice].virt_size);
			}
			
			if(systemData.meta.disk[storageDevice].virt_unit.includes("TiB") || systemData.meta.disk[storageDevice].disk_size_unit.includes("TB")){
				virt_size = parseFloat(systemData.meta.disk[storageDevice].virt_size) * 1000;
			}		
		
		}

		// parse device size in percs
		usedPerc = parseInt(systemData.meta.disk[storageDevice].disk_size)  / parseInt(systemData.meta.disk[storageDevice].virt_size) * 100;
		
		sysStorHeader += " consumed [<b>" + usedPerc.toFixed(1) + "%</b>]";
		
		var storbar1 = view_bar_add_nomb(storageDevice, " size [<b>" + systemData.meta.disk[storageDevice].virt_size + " " + systemData.meta.disk[storageDevice].virt_size_unit + "</b>] used [<b>" + disk_size + " " + systemData.meta.disk[storageDevice].disk_size_unit + "</b>]", "sys_disksize", usedPerc.toFixed(1));
		var storbar2 = view_bar_add_nomb(storageDevice, " size [<b>" + systemData.meta.disk[storageDevice].virt_size + " " + systemData.meta.disk[storageDevice].virt_size_unit + "</b>] used [<b>" + disk_size + " " + systemData.meta.disk[storageDevice].disk_size_unit + "</b>]", "sys_disksize", usedPerc.toFixed(1));
				
		// disk view
		var sizebar = system_storage_bar_add(storageDevice, "dev", usedPerc.toFixed(1));
		storageDeviceContainer.appendChild(storbar1);
		
		// main view
		var sizebar2 = system_storage_bar_add(storageDevice, "res", usedPerc.toFixed(1));
		sizebar2.setAttribute("class", "");
		document.getElementById('sysResourceStorDiv').appendChild(storbar2);
	}

	//
	// overview
	//
	var tbodyResourceStorage = $("#sysResourceStorTable tbody");
	
	if((typeof systemData.meta.disk !== 'undefined') && (typeof systemData.meta.stats !== 'undefined') && (systemData.meta.stats !== null) && (typeof systemData.meta.disk[storageDevice] !== 'undefined') && (typeof systemData.meta.stats.hypervisor !== 'undefined')){
		
		if((typeof systemData.meta.stats.hypervisor.disk !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk[storageDevice].size !== 'undefined')){
			//tbodyResourceStorage.append("<tr><td><b>" + storageDevice + "</b></td><td>" + systemData.stor[storageDevice].driver + "</td><td>" + systemData.stor[storageDevice].cache + "</td><td>" + systemData.stor[storageDevice].type + "</td><td><b>" + systemData.stor[storageDevice].size + " GB</b></td><td><b>" + systemData.meta.stats.hypervisor.disk[storageDevice].size + "</b></td><td><b>" + systemData.meta.disk[storageDevice].virt_size +  " " + niceUnits(systemData.meta.disk[storageDevice].virt_unit) + "</b></td><td><b>" + systemData.meta.disk[storageDevice].disk_size +  " " + niceUnits(systemData.meta.disk[storageDevice].disk_unit) + "</b></td><td>" + systemData.meta.disk[storageDevice].format + "</td><td>" + systemData.meta.disk[storageDevice].corrupt + "</td></tr>");
			tbodyResourceStorage.append("<tr><td><b>" + storageDevice + "</b></td><td>" + systemData.stor[storageDevice].driver + "</td><td>" + systemData.stor[storageDevice].cache + "</td><td>" + systemData.stor[storageDevice].type + "</td><td><b>" + systemData.stor[storageDevice].size + " GB</b></td><td><b>" + systemData.meta.stats.hypervisor.disk[storageDevice].size + "</b></td><td><b>" + systemData.meta.disk[storageDevice].virt_size +  " " + niceUnits(systemData.meta.disk[storageDevice].virt_size_unit) + "</b></td><td><b>" + systemData.meta.disk[storageDevice].disk_size +  " " + niceUnits(systemData.meta.disk[storageDevice].disk_size_unit) + "</b></td><td>" + systemData.meta.disk[storageDevice].format + "</td><td>" + systemData.meta.disk[storageDevice].corrupt + "</td></tr>");
			sysStorHeader += " on disk [<b>" + systemData.meta.stats.hypervisor.disk[storageDevice].size + "</b>]";
		}
		else{
			//tbodyResourceStorage.append("<tr><td><b>" + storageDevice + "</b></td><td>" + systemData.stor[storageDevice].driver + "</td><td>" + systemData.stor[storageDevice].cache + "</td><td>" + systemData.stor[storageDevice].type + "</td><td><b>" + systemData.stor[storageDevice].size + " GB</b></td><td><b>" + systemData.stor[storageDevice].size + " GB</b></td><td>" + "n/a" + "</td><td><b>" + systemData.meta.disk[storageDevice].disk_size +  " " + niceUnits(systemData.meta.disk[storageDevice].disk_unit) + "</b></td><td>" + systemData.meta.disk[storageDevice].format + "</td><td>" + systemData.meta.disk[storageDevice].corrupt + "</td></tr>");
			tbodyResourceStorage.append("<tr><td><b>" + storageDevice + "</b></td><td>" + systemData.stor[storageDevice].driver + "</td><td>" + systemData.stor[storageDevice].cache + "</td><td>" + systemData.stor[storageDevice].type + "</td><td><b>" + systemData.stor[storageDevice].size + " GB</b></td><td><b>" + systemData.stor[storageDevice].size + " GB</b></td><td>" + "n/a" + "</td><td><b>" + systemData.meta.disk[storageDevice].disk_size +  " " + niceUnits(systemData.meta.disk[storageDevice].disk_size_unit) + "</b></td><td>" + systemData.meta.disk[storageDevice].format + "</td><td>" + systemData.meta.disk[storageDevice].corrupt + "</td></tr>");
		}
	}
	else{
		tbodyResourceStorage.append("<tr><td><b>" + storageDevice + "</b></td><td>" + systemData.stor[storageDevice].driver + "</td><td>" + systemData.stor[storageDevice].cache + "</td><td>" + systemData.stor[storageDevice].type + "</td><td><b>" + systemData.stor[storageDevice].size + " GB</b></td><td>" + "n/a" + "</td><td>" + "n/a" +  "</td><td>" + "n/a" +  "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td></tr>");
	}

	//
	// build storage view
	//

	var accordion = view_accordion_build("accordionStorDev", "collapseStorDev" + storageDevice, "bi-hdd", sysStorHeader);
	
	var row = document.createElement("div");
	row.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2");
	
	
	//
	// Image
	//
	var colId = document.createElement("div");
	colId.setAttribute("class", "col-lg-4 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Image", "bi-braces");
	colId.appendChild(header);
	
	var divImage = view_textbox_build("sysDiskImage_" + systemData.id.name + storageDevice, "Image", systemData.stor[storageDevice].image);
	colId.appendChild(divImage);

	var divPath = view_textbox_build("sysDiskPath_" + systemData.id.name + storageDevice, "Path", systemData.stor[storageDevice].dev);

	colId.appendChild(divPath);
	
	row.appendChild(colId);
	

	//
	// Size
	//
	var colSize = document.createElement("div");
	colSize.setAttribute("class", "col-lg-2 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Size", "bi-code");
	colSize.appendChild(header);

	var divSize = view_textbox_build("sysDiskSize_" + systemData.id.name + storageDevice, "Image Size", systemData.stor[storageDevice].size);
	var span2 = document.createElement("span");
	span2.setAttribute("class", "input-group-text");
	span2.innerHTML = "GiB";
	divSize.appendChild(span2);
	
	colSize.appendChild(divSize);
			
	var divImageType = view_selector_build("sysDiskType_" + systemData.id.name + storageDevice, "Image Type", "qcow2;raw;qcow;vmdk", systemData.stor[storageDevice].type);	
	colSize.appendChild(divImageType);
	
	row.appendChild(colSize);
	
	
	//
	// Driver 
	//
	var colDriver = document.createElement("div");
	colDriver.setAttribute("class", "col-lg-2 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Driver", "bi-gear");
	colDriver.appendChild(header);
	
	var divDriver = view_selector_build("sysDiskDriver_" + systemData.id.name + storageDevice, "Driver", "virtio;scsi;ide", systemData.stor[storageDevice].driver);	
	colDriver.appendChild(divDriver);
	
	var divCache = view_selector_build("sysDiskCache_" + systemData.id.name + storageDevice, "Cache", "writeback;writethrough;none;unsafe;directsync", systemData.stor[storageDevice].cache);
	colDriver.appendChild(divCache);
	
	row.appendChild(colDriver);
	

	//
	// Pool
	//
	var colDriver = document.createElement("div");
	colDriver.setAttribute("class", "col-lg-3 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Backing", "bi-server");
	colDriver.appendChild(header);
	
	if((typeof systemData.stor[storageDevice].backing !== 'undefined')){
		
		if(systemData.stor[storageDevice].backing == "pool"){
			// pool
			var divDriver = view_selector_build("sysDiskBackingType_" + systemData.id.name + storageDevice, "Type", "pool;path;legacy", "pool");	
			colDriver.appendChild(divDriver);
			
			//var poolList = db_storage_index_pool_get();
			var poolList = dbnew_storage_index_pool_get();
			var divCache = view_selector_build_array("sysDiskBackingPool_" + systemData.id.name + storageDevice, "Pool", poolList, systemData.stor[storageDevice].pool.name);
			colDriver.appendChild(divCache);		
		}
		else{
			// absolute path
			var divDriver = view_selector_build("sysDiskBackingType_" + systemData.id.name + storageDevice, "Type", "pool;path;legacy", "path");	
			colDriver.appendChild(divDriver);
		
			var poolList = "n/a";
			var divCache = view_selector_build("sysDiskBackingType_" + systemData.id.name + storageDevice, "Pool", poolList, "");
			colDriver.appendChild(divCache);	
		}	
	}
	else{
		// legacy
		var divDriver = view_selector_build("sysDiskBackingType_" + systemData.id.name + storageDevice, "Type", "pool;path;legacy", "legacy");	
		colDriver.appendChild(divDriver);
	
		var poolList = "n/a";
		var divCache = view_selector_build("sysDiskBackingType_" + systemData.id.name + storageDevice, "Pool", poolList, "");
		colDriver.appendChild(divCache);
	}
	
	
	//
	// add to view
	//
	row.appendChild(colDriver);
	
	storageDeviceContainer.appendChild(row);
	
	accordion.appendChild(storageDeviceContainer);
	
	storageAccordionContainer.appendChild(accordion);
	
	// handle read only
	if((typeof systemData.stor[storageDevice].backing !== 'undefined') && (systemData.stor[storageDevice].backing == "pool")){
		document.getElementById("sysDiskPath_" + systemData.id.name + storageDevice).setAttribute("disabled", "true");
		document.getElementById("sysDiskImage_" + systemData.id.name + storageDevice).setAttribute("disabled", "true");
		document.getElementById("sysDiskType_" + systemData.id.name + storageDevice).setAttribute("disabled", "true");
	}
}				

/**
 * Adds ISO device to view
 * @param {string} storageDevice - Storage device name
 * @param {Object} systemData - System object
 * @description Creates UI elements for ISO device
 */
function system_storage_iso_add(storageDevice, systemData) {
	
	var root = document.getElementById('accordionSystemStorage');
	var accordion = view_accordion_build("accordionStorIso", "collapseStor" + storageDevice, "bi-vinyl", "Iso [<b>" + storageDevice + "</b>] - image [<b>" + systemData.stor[storageDevice].image + "</b>]");
	var divISO = view_accordion_element_build("collapseStor" + storageDevice, "headingSystemStorage", "accordionStorIso");
	
	//
	// root
	//
	var row = document.createElement("div");
	row.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2");

	//
	// Driver 
	//
	var colDriver = document.createElement("div");
	colDriver.setAttribute("class", "col-lg-3 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Select ISO", "bi-code");
	colDriver.appendChild(header);
	
	//
	// try to get iso
	//
	var isodata = dbnew_storage_get(systemData.stor[storageDevice].image);
	
	var isoName = "";
	var isoDesc = "";
	
	if(typeof systemData.stor[storageDevice].desc !== 'undefined'){
		isoDesc = systemData.stor[storageDevice].desc;
	}
	
	if(typeof systemData.stor[storageDevice].name !== 'undefined'){
		isoName = systemData.stor[storageDevice].name;
	}
	else{
		isoName = systemData.stor[storageDevice].image;
	}

	if(typeof systemData.stor[storageDevice].desc !== 'undefined'){
		isoDesc = systemData.stor[storageDevice].desc;
	}


	//var isoList = db_storage_index_iso_get();
	var isoList = dbnew_storage_index_iso_get()
	
	var divIsoSel = view_selector_build_array("sysIsoSel_" + systemData.id.name + storageDevice, "ISO", isoList, isoName);
	divIsoSel.onclick = function() { system_stor_iso_change(systemData.id.name, storageDevice) };
	colDriver.appendChild(divIsoSel);
	
	row.appendChild(colDriver);
	
	//
	// Image
	//
	var colId = document.createElement("div");
	colId.setAttribute("class", "col-lg-3 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Image", "bi-braces");
	colId.appendChild(header);
	
	var divIsoName = view_textbox_build("sysIsoName_" + systemData.id.name + storageDevice, "Name", isoName);
	divIsoName.setAttribute("disabled", "true");
	colId.appendChild(divIsoName);

	var divIsoDesc = view_textbox_build("sysIsoDesc_" + systemData.id.name + storageDevice, "Desc", isoDesc);
	divIsoDesc.setAttribute("disabled", "true");
	colId.appendChild(divIsoDesc);
	row.appendChild(colId);


	//
	// ISO
	//
	var colIsoDesc = document.createElement("div");
	colIsoDesc.setAttribute("class", "col-lg-3 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("ISO", "bi-vinyl");
	colIsoDesc.appendChild(header);
	
	var divImage = view_textbox_build("sysIsoImg_" + systemData.id.name + storageDevice, "Image", systemData.stor[storageDevice].image);
	colIsoDesc.appendChild(divImage);

	var divPath = view_textbox_build("sysIsoPath_" + systemData.id.name + storageDevice, "Path", systemData.stor[storageDevice].dev);
	colIsoDesc.appendChild(divPath);
	
	row.appendChild(colIsoDesc);
	
	divISO.appendChild(row);
	
	accordion.appendChild(divISO);
	
	root.appendChild(accordion);	
	
	
	//
	// lock elements
	//
	document.getElementById("sysIsoName_" + systemData.id.name + storageDevice).setAttribute("disabled", "true");
	document.getElementById("sysIsoDesc_" + systemData.id.name + storageDevice).setAttribute("disabled", "true");

	document.getElementById("sysIsoImg_" + systemData.id.name + storageDevice).setAttribute("disabled", "true");
	document.getElementById("sysIsoPath_" + systemData.id.name + storageDevice).setAttribute("disabled", "true");

}

/**
 * Adds network device to view
 * @param {string} networkDevice - Network device name
 * @param {Object} systemData - System object
 * @description Creates UI elements for network device
 */
function system_network_device_add(networkDevice, systemData) {

	// root
	var networkAccordionContainer = document.getElementById('accordionSystemNetwork');
	
	var heading = "";
	if(typeof systemData.net[networkDevice].net !== 'undefined'){
		heading = "Device [<b>" + networkDevice + "</b>] - type [<b>" + systemData.net[networkDevice].net.type + "</b>] network [<b>" + systemData.net[networkDevice].net.name + "</b>] id [<b>" + systemData.net[networkDevice].net.id + "</b>] mac [<b>" + systemData.net[networkDevice].mac + "</b>] address [<b>" + systemData.net[networkDevice].ip + "</b>]";
	}
	else{
		// legacy systemData
		heading = "LEGACY SYSTEM";
	}
	
	var accordion = view_accordion_build("accordionNetDev", "collapseNetDev" + networkDevice, "bi-ethernet", heading);	
	var networkDeviceDiv = view_accordion_element_build("collapseNetDev" + networkDevice, "headingSystemNetwork", "accordionNetDev");
	
	var tbodyResourceNetwork = $("#sysResourceNetTable tbody");
	
	if(systemData.net[networkDevice].net.type === "bri-tap"){
		
		if((typeof systemData.meta.stats !== 'undefined') && (systemData.meta.stats !== null) && (typeof systemData.meta.stats.network !== 'undefined') && (typeof systemData.meta.stats.network[networkDevice] !== 'undefined')){
			if((typeof systemData.meta.stats.network[networkDevice].rx.errors !== 'undefined') && (typeof systemData.meta.stats.network[networkDevice].tx.errors !== 'undefined')){
				
				// handle V3.2.4 and above model
				if((typeof systemData.meta.stats.network[networkDevice].tx.errors.errors !== 'undefined')){
					tbodyResourceNetwork.append("<tr><td><b>" + networkDevice + "</b></td><td>" + systemData.net[networkDevice].net.type + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_sysnet" class="btn btn-link tablebtn">' + systemData.net[networkDevice].net.name + "</a></b></td><td><b>" + systemData.meta.stats.network[networkDevice].tx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].tx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].tx.errors.errors + "</td><td>" + systemData.meta.stats.network[networkDevice].tx.errors.dropped + "</td><td><b>" + systemData.meta.stats.network[networkDevice].rx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].rx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].rx.errors.errors + "</td><td>" + systemData.meta.stats.network[networkDevice].rx.errors.dropped + "</td></tr>");
				}
				else{
					// NEW
					tbodyResourceNetwork.append("<tr><td><b>" + networkDevice + "</b></td><td>" + systemData.net[networkDevice].net.type + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_sysnet" class="btn btn-link tablebtn">' + systemData.net[networkDevice].net.name + "</a></b></td><td><b>" + systemData.meta.stats.network[networkDevice].tx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].tx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].tx.errors + "</td><td>" + systemData.meta.stats.network[networkDevice].tx.dropped + "</td><td><b>" + systemData.meta.stats.network[networkDevice].rx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].rx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].rx.errors + "</td><td>" + systemData.meta.stats.network[networkDevice].rx.dropped + "</td></tr>");
				}
				
			}
			else{
				tbodyResourceNetwork.append("<tr><td><b>" + networkDevice + "</b></td><td>" + systemData.net[networkDevice].net.type + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_sysnet" class="btn btn-link tablebtn">' + systemData.net[networkDevice].net.name + "</a></b></td><td><b>" + systemData.meta.stats.network[networkDevice].tx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].tx.packets + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td><b>" + systemData.meta.stats.network[networkDevice].rx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].rx.packets + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td></tr>");
			}

		}
		else{
			tbodyResourceNetwork.append("<tr><td><b>" + networkDevice + "</b></td><td>" + systemData.net[networkDevice].net.type + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_sysnet" class="btn btn-link tablebtn">' + systemData.net[networkDevice].net.name + "</a></b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td></tr>");
		}
		
		
		document.getElementById("tempbtn_sysnet").id = "btn_sysnet_" + systemData.net[networkDevice].net.name;
		document.getElementById("btn_sysnet_" + systemData.net[networkDevice].net.name).onclick = function() { net_show(systemData.net[networkDevice].net.name) };
	}
	
	
	if(systemData.net[networkDevice].net.type === "dpdk-vpp"){
		
		if((typeof systemData.meta.stats !== 'undefined') && (typeof systemData.meta.stats.network !== 'undefined') && (typeof systemData.meta.stats.network[networkDevice] !== 'undefined')){
			tbodyResourceNetwork.append("<tr><td><b>" + networkDevice + "</b></td><td>" + systemData.net[networkDevice].net.type + "</td><td><b>" + systemData.net[networkDevice].net.name + "</b></td><td><b>" + systemData.meta.stats.network[networkDevice].tx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].tx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].errors + "</td><td>" + systemData.meta.stats.network[networkDevice].drops + "</td><td><b>" + systemData.meta.stats.network[networkDevice].rx.data + "</b></td><td>" + systemData.meta.stats.network[networkDevice].rx.packets + "</td><td>" + systemData.meta.stats.network[networkDevice].errors + "</td><td>" + systemData.meta.stats.network[networkDevice].drops + "</td></tr>");
		}
		else{
			tbodyResourceNetwork.append("<tr><td><b>" + networkDevice + "</b></td><td>" + systemData.net[networkDevice].net.type + "</td><td><b>" + systemData.net[networkDevice].net.name + "</b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td></tr>");
		}
	}

	//
	// root
	//
	var row = document.createElement("div");
	row.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2");

	//
	// Network
	//
	var colNetwork = document.createElement("div");
	colNetwork.setAttribute("class", "col-lg-3 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Network", "bi-code");
	colNetwork.appendChild(header);

	var divNetType = view_selector_build("sysNetTypeSel" + systemData.id.name + networkDevice, "Network Type", "dpdk-vpp;bri-tap", systemData.net[networkDevice].net.type);
	divNetType.onchange = function() { system_network_type_change_new(systemData.id.name, networkDevice) };
	colNetwork.appendChild(divNetType);
	
	var netList = network_option_enumerate_new(systemData.net[networkDevice].net.type);
	var divNet = view_selector_build_array("sysNetSel" + systemData.id.name + networkDevice, "Network", netList, systemData.net[networkDevice].net.name);
	divNet.onchange = function() { system_network_net_change(systemData.id.name, networkDevice) };
	colNetwork.appendChild(divNet);
	
	row.appendChild(colNetwork);
	
	//
	// Driver
	//
	var colNic = document.createElement("div");
	colNic.setAttribute("class", "col-lg-3 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Interface", "bi-pci-card");
	colNic.appendChild(header);
	
	var divNicDriver = view_selector_build("sysNetDriverSel" + systemData.id.name + networkDevice, "Driver", "virtio;virtio-net;virtio-net-pci;e1000;rtl8139;pcnet", systemData.net[networkDevice].driver);
	colNic.appendChild(divNicDriver);
	
	var divNicMac = view_textbox_build("sysNetMac" + systemData.id.name + networkDevice, "MAC", systemData.net[networkDevice].mac);
	
	var btn = document.createElement("button");
	btn.setAttribute("class", "btn btn-outline-secondary");
	btn.innerHTML = "[generate]";
	btn.onclick = function() { system_network_gen_mac(systemData.id.name, networkDevice); };  
	
	divNicMac.appendChild(btn);
	
	colNic.appendChild(divNicMac);
	
	row.appendChild(colNic);
	
	//
	// Image
	//
	var colId = document.createElement("div");
	colId.setAttribute("class", "col-lg-4 border rounded-3 p-2 bg-light col-md-offset-2 mt-2 mb-2 ms-2");
	
	var header = view_header_build("Information", "bi-braces");
	colId.appendChild(header);
	
	var divAddress = view_textbox_build("sysNetIP" + systemData.id.name + networkDevice, "Address", systemData.net[networkDevice].ip);

	var network = dbnew_network_get(systemData.net[networkDevice].net.name);

	var isDHCP = document.createElement("span");
	isDHCP.setAttribute("id", "sysNetIsDHCP" + systemData.id.name + networkDevice);
	isDHCP.setAttribute("class", "input-group-text");

	var netAddr = document.createElement("span");
	netAddr.setAttribute("id", "sysNetNetAddr" + systemData.id.name + networkDevice);
	netAddr.setAttribute("class", "input-group-text");

	if((typeof network !== 'undefined') && (typeof network.id.name !== 'undefined') && (typeof network.addr !== 'undefined')){

		if(network.addr.dhcp == "1"){ isDHCP.innerHTML = '<b style="color:#24be14">DHCP</b>'; }
		else{ isDHCP.innerHTML = '<b style="color:#ebeb4">STATIC</b>'; };

		if(typeof network.addr !== 'undefined'){ netAddr.innerHTML = network.addr.ip + "/24"; }
		else{ netAddr.innerHTML = '<b style="color:#ebeb4">0.0.0.0</b>'; };
	}
	
	divAddress.appendChild(isDHCP);
	divAddress.appendChild(netAddr);
	
	colId.appendChild(divAddress);

	var divPath = view_textbox_build("sysNetDesc" + systemData.id.name + networkDevice, "Desc", systemData.net[networkDevice].desc);
	colId.appendChild(divPath);
	
	row.appendChild(colId);
	
	networkDeviceDiv.appendChild(row);
	
	accordion.appendChild(networkDeviceDiv);
	
	networkAccordionContainer.appendChild(accordion);
}
