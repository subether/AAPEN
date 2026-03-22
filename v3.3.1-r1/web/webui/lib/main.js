/**
 * ETHER|AAPEN|WEB - LIB|MAIN
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

const currentView = {};

/**
 * Refresh all data
 */
function mainRefreshAllViews() {
	api_rest_db_get();
	//api_rest_init_all();
	

}

/**
 * Utility wait function
 */
async function wait() {
	console.log('start timer');
	await new Promise(resolve => setTimeout(resolve, 1000));
	console.log('after 1 second');
}

/**
 * Show a view element
 * @param {string} element - ID of element to show
 */
function main_show(element) {
	const myCollapse = document.getElementById(element);
	const bsCollapse = new bootstrap.Collapse(myCollapse, {
		toggle: false
	});
	bsCollapse.show();
}

/**
 * Hide a view element
 * @param {string} element - ID of element to hide
 */
function main_hide(element) {
	const myCollapse = document.getElementById(element);
	const bsCollapse = new bootstrap.Collapse(myCollapse, {
		toggle: false
	});
	bsCollapse.hide();
}

/**
 * Hide all views
 */
function main_hide_all() {
	main_init_hide();
	main_cluster_hide();
	main_api_hide();
	main_log_hide();
	main_system_hide();
	main_system_overview_hide();
	main_system_overview_res_hide();
	main_node_hide();
	main_node_overview_hide();
	main_node_resources_hide();
	main_net_hide();
	main_net_overview_hide();
	main_net_sys_overview_hide();
	main_json_hide();
	main_text_hide();
	main_cluster_health_hide();
	main_search_hide();
	main_api_hide();
	main_about_hide();
	main_storage_overview_hide();
	main_storage_device_hide();
	main_storage_iso_hide();
	main_storage_pool_hide();
	main_system_config_hide();
	main_element_device_hide();
	main_element_service_hide();
	main_element_overview_hide();
	main_element_mt_device_hide();
	main_health_overview_hide();
	main_view_set('null', 'null', 'null');
}

/**
 * Set current view parameters
 * @param {string} view - View type
 * @param {string} key - View key
 * @param {string} id - View ID
 */
function main_view_set(view, key, id) {
	currentView.view = view;
	currentView.key = key;
	currentView.id = id;
}

/**
 * Get current view parameters
 * @returns {Object} Current view object
 */
function main_view_get() {
	return currentView;
}

/**
 * Process view changes based on currentView
 */
function main_view_process() {
	let handler = 0;
	
	// Node views
	if(currentView.view === "node_show"){
		node_show(currentView.key);
		toast_show("API | REST", "bi-activity", "API", `Refreshed node [<b>${currentView.key}</b>]`);
		handler = 1;
	} 
	else if(currentView.view === "node_overview"){
		node_overview_show();
		toast_show("API | REST", "bi-activity", "API", "Refreshed [<b>node</b>] configuration");
		handler = 1;
	} 
	else if(currentView.view === "node_resources"){
		node_resources_show();
		toast_show("API | REST", "bi-activity", "API", "Refreshed [<b>node</b>] configuration");
		handler = 1;
	}
	// System views
	else if(currentView.view === "system_show"){
		system_show(currentView.key);
		toast_show("API | REST", "bi-activity", "System", `Refreshed system [<b>${currentView.key}</b>]`);
		handler = 1;
	}
	else if(currentView.view === "system_overview"){
		system_overview_show();
		toast_show("API | REST", "bi-activity", "API", "Refreshed [<b>system</b>] configuration");
		handler = 1;
	} 
	else if(currentView.view === "system_resources"){
		system_resources_show();
		toast_show("API | REST", "bi-activity", "API", "Refreshed [<b>system</b>] configuration");
		handler = 1;
	}
	// Storage views
	else if(currentView.view === "storage_overview"){
		stor_overview_show();
		toast_show("API | REST", "bi-activity", "API", "Refreshed [<b>storage</b>] configuration");
		handler = 1;
	}
	else if(currentView.view === "storage_device_show"){
		stor_show_device(currentView.key);
		toast_show("API | REST", "bi-activity", "Storage", `Refreshed device [<b>${currentView.key}</b>]`);
		handler = 1;
	} 
	else if(currentView.view === "storage_pool_show"){
		stor_show_pool(currentView.key);
		toast_show("API | REST", "bi-activity", "Storage", `Refreshed pool [<b>${currentView.key}</b>]`);
		handler = 1;
	}
	// Network views
	else if(currentView.view === "network_show"){
		net_show(currentView.key);
		toast_show("API | REST", "bi-activity", "Network", `Refreshed network [<b>${currentView.key}</b>]`);
		handler = 1;
	} 
	else if(currentView.view === "cluster_health_show"){
		cluster_health_node_show(currentView.key);
		toast_show("API | REST", "bi-activity", "Health", "Refreshed [<b>cluster</b>] configuration");
		handler = 1;
	}
	else if(currentView.view === "cluster_node_show"){
		//cluster_health_node_show(currentView.key);
		cluster_async_show(currentView.key);
		toast_show("API | REST", "bi-activity", "Health", "Refreshed [<b>cluster</b>] configuration");
		handler = 1;
	} 
	else if(currentView.view === "network_sysview"){
		net_sys_overview_show();
		toast_show("API | REST", "bi-activity", "Network", "Refreshed [<b>network</b>] configuration");
		handler = 1;
	}
	
	// Generic handler
	if(handler !== 1){
		toast_show("API | REST", "bi-activity", "API", "Updated [<b>cluster</b>] configuration");
	}
}

// View toggle functions
function main_init_show() {
	mainRefreshAllViews();
	//main_refresh_all();
	main_hide_all();
	main_show('main_init');
}

function main_init_hide() {
	main_hide('main_init');
}

function main_search_show() {
	main_hide_all();
	main_show('main_search_view');
}

function main_search_hide() {
	main_hide('main_search_view');
}

function main_api_show() {
	main_hide_all();
	main_show('main_api_view');
	api_view();
}

function main_api_hide() {
	main_hide('main_api_view');
}

function main_about_show() {
	main_hide_all();
	main_show('main_about_view');
}

function main_about_hide() {
	main_hide('main_about_view');
}

function main_cluster_show() {
	main_hide_all();
	main_show('main_cluster');
}

function main_cluster_hide() {
	main_hide('main_cluster');
}

function main_cluster_health_show() {
	main_hide_all();
	main_show('main_cluster_health_view');
}

function main_cluster_health_hide() {
	main_hide('main_cluster_health_view');
}

function main_log_show() {
	main_hide_all();
	main_show('main_log');
}

function main_log_hide() {
	main_hide('main_log');
}

function main_system_show() {
	main_hide_all();
	main_show('main_system');
}

function main_system_hide() {
	main_hide('main_system');
}

function main_system_overview_show() {
	main_hide_all();
	main_view_set('system_overview', '', '');
	system_overview_show();
	main_show('main_system_overview');
}

function main_system_overview_hide() {
	main_hide('main_system_overview');
}

function main_system_overview_res_show() {
	main_hide_all();
	main_show('main_system_res_overview');
	system_resources_show();
}

function main_system_overview_res_hide() {
	main_hide('main_system_res_overview');
}

function main_system_config_show() {
	main_hide_all();
	main_show('main_system_config');
}

function main_system_config_hide() {
	main_hide('main_system_config');
}

function main_node_show() {
	main_hide_all();
	main_show('main_node');
}

function main_node_hide() {
	main_hide('main_node');
}

function main_node_overview_show() {
	main_hide_all();
	main_view_set('node_overview', '', '');
	main_show('main_node_overview');
	node_overview_show();
}

function main_node_overview_hide() {
	main_hide('main_node_overview');
}

function main_node_resources_show() {
	main_hide_all();
	main_view_set('node_resources', '', '');
	main_show('main_node_resources');
	node_resources_show();
}

function main_node_resources_hide() {
	main_hide('main_node_resources');
}

function main_net_show() {
	main_hide_all();
	main_show('main_net');
}

function main_net_hide() {
	main_hide('main_net');
}

function main_net_overview_show() {
	main_hide_all();
	main_show('main_net_overview');
}

function main_net_overview_hide() {
	main_hide('main_net_overview');
}

function main_net_sys_overview_show() {
	main_hide_all();
	main_show('main_net_sys_overview');
	net_sys_overview_show();
}

function main_net_sys_overview_hide() {
	main_hide('main_net_sys_overview');
}

function main_storage_overview_show() {
	main_hide_all();
	main_view_set('storage_overview', '', '');
	main_show('main_storage_overview');
}

function main_storage_overview_hide() {
	main_hide('main_storage_overview');
}

function main_storage_device_show() {
	main_hide_all();
	main_show('main_storage_dev_view');
}

function main_storage_device_hide() {
	main_hide('main_storage_dev_view');
}

function main_storage_iso_show() {
	main_hide_all();
	main_show('main_storage_iso_view');
}

function main_storage_iso_hide() {
	main_hide('main_storage_iso_view');
}

function main_storage_pool_show() {
	main_hide_all();
	main_show('main_storage_pool_view');
}

function main_storage_pool_hide() {
	main_hide('main_storage_pool_view');
}

function main_element_device_show() {
	main_hide_all();
	main_show('main_element_device_view');
}

function main_element_device_hide() {
	main_hide('main_element_device_view');
}

function main_element_mt_device_show() {
	main_show('main_element_device_mt_view');
}

function main_element_mt_device_hide() {
	main_hide('main_element_device_mt_view');
}

function main_element_service_show() {
	main_hide_all();
	main_show('main_element_service_view');
}

function main_element_service_hide() {
	main_hide('main_element_service_view');
}

function main_element_overview_show() {
	main_hide_all();
	main_show('main_element_overview');
}

function main_element_overview_hide() {
	main_hide('main_element_overview');
}

function main_health_overview_show() {
	main_hide_all();
	main_show('main_health_overview');
}

function main_health_overview_hide() {
	main_hide('main_health_overview');
}

function main_json_show() {
	main_hide_all();
	main_show('main_json_view');
}

function main_json_hide() {
	main_hide('main_json_view');
}

function main_text_show() {
	main_hide_all();
	main_show('main_text_view');
}

function main_text_hide() {
	main_hide('main_text_view');
}

/**
 * Show JSON viewer
 * @param {string} string - Header string
 * @param {string} name - Object name
 * @param {string} object - Object type
 * @param {Object} json - JSON data
 */
function json_show(string, name, object, json) {
	main_hide_all();
	main_json_show();
	
	const configBtn = document.getElementById("main-json-btn-config");
	
	switch (object) {
		case "node":
			configBtn.onclick = () => node_show(name);
			break;
		case "net":
			configBtn.onclick = () => net_show(name);
			break;
		case "system":
			configBtn.onclick = () => system_show(name);
			break;
		case "cluster":
			configBtn.onclick = () => cluster_async_show(name);
			break;
		case "cluster_health":
			configBtn.onclick = () => cluster_health_show();
			break;
		case "stordev":
			configBtn.onclick = () => stor_show_device(name);
			break;
		case "pooldev":
			configBtn.onclick = () => stor_show_pool(name);
			break;
		case "isodev":
			configBtn.onclick = () => stor_show_iso(name);
			break;
		case "element_dev_ov":
			configBtn.onclick = () => element_device_ov_show();
			break;
		case "element_srv_ov":
			configBtn.onclick = () => element_device_srv_show();
			break;
		case "element_dev":
			configBtn.onclick = () => element_device_show(name);
			break;
	}

	document.getElementById('main-json-header').innerHTML = `<h3>${string}</h3>`;
	document.getElementById('json_view').innerHTML = '<pre id="json-renderer"></pre>';
	$('#json_view').jsonViewer(json);
}


//
//
//
function text_show(text){

	console.log(text);

	const mytext = text.response['file_data'];

	/*
		
		$('#editor').trumbowyg({ btns: [['strong', 'em'], ['link', 'insertImage'], ['viewHTML']] });
		//$('#editor').trumbowyg({ btns: [] });
		
		var mytext = '\n------------------------------------------------------------------------\nFRAMEWORK\n------------------------------------------------------------------------\n\n\n\t- implement element in framework\n\t\n\t- add framework support to rest\n\t\t- start and stop services\n\t\t- more sophisticated monitoring\n\t\t- add metadata to the services\n\t\t\n\t- framework to node monitor\n\t\t- framework has the data,... it is not not exposed in the WebUI\n\t\t\n\t- should also make some rest CLI stuff more exposed here\n\t\t- node service list\n\t\t- node service stop\n\t\t- node service info\n\t\t- node service meta\n\t\t\n\t\t\n\t\t\n\n------------------------------------------------------------------------\nOTHER\n------------------------------------------------------------------------\n\n\t- finish migrating to log_ functions\n\t\nSystem indexes does not match the systems\n\n    cpualloc: 10,\n    async: {11 items},\n    lock: \"303;603;604\",\n    systems: 2,\n    memalloc: 36864,\n    index: \"603;604;601;303;4000;4004\"\n    \n    \n- node view resource view is not cleared \n\t- add to cleanup functions\n\n\n- monitor should monitor other services\n\t- create a service summary object \n\t\n- monitor has bug for systems in cluster without object dates set\n\n- storage: pull unknown\tpools from cluster \n\n- framework: handle multiple api pids (mojo)\n- framework: fetch service resource stats\n- framework: add support for element service\n\n\n';
		
		const formattedText = mytext
		  .replace(/&/g, '&amp;')
		  .replace(/</g, '&lt;')
		  .replace(/>/g, '&gt;')
		  .replace(/\n/g, '<br>');

		$('#editor').trumbowyg('html', formattedText);
		
		//$('#editor').trumbowyg('html', );



	  main_hide_all();
	  main_text_show();
	*/

	/*
	//const formattedText = text
	  .replace(/&/g, '&amp;')
	  .replace(/</g, '&lt;')
	  .replace(/>/g, '&gt;')
	  .replace(/\n/g, '<br>');
	*/

	const $editor = $('#editor');

	$editor.trumbowyg({
		  btns: [],
		  fixedBtnPane: false
	});

	// Set content with line breaks preserved
	//const mytext = `...your text...`;
	//const formattedText = mytext.replace(/\n/g, '<br>');
	const formattedText = mytext.replace(/\n/g, '<br>');
	$editor.trumbowyg('html', formattedText);	
  
  	main_hide_all();
	main_text_show();
}

function file_show(fileName, fileData){
	main_hide_all();
	main_json_show();
	
	document.getElementById('main-json-header').innerHTML = `<h3>${fileName}</h3>`;
	document.getElementById('json_view').innerHTML = fileData;
}

/**
 * Show toast notification
 * @param {string} header - Toast header
 * @param {string} icon - Icon class
 * @param {string} caller - Caller information
 * @param {string} message - Toast message
 */
function toast_show(header, icon, caller, message) {
	const toastContainer = document.getElementById('main-toast-container');
	
	document.getElementById("toast-container-icon").className = `rounded me-2 bi ${icon}`;
	document.getElementById("toast-container-header").textContent = header;
	document.getElementById("toast-container-caller").textContent = caller;
	document.getElementById("toast-container-body").innerHTML = message;
	
	const toast = new bootstrap.Toast(toastContainer);
	toast.show();
}

/**
 * Show modal dialog
 */
function modal_show() {
	const header = "modal template header";
	const body = "modal template body";
	const icon = "system-load-btn bi bi-badge-ar";
	const button = "modal template button";

	document.getElementById("mainModalLabel").textContent = header;
	document.getElementById("mainModalBody").textContent = body;
	document.getElementById("mainModalIcon").className = icon;
	document.getElementById("mainModalBtnAccept").textContent = button;
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		action;
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
}

/**
 * Show loading spinner
 */
function spinner_show() {
	$('#mainSpinner').modal('show');
}

/**
 * Hide loading spinner
 */
function spinner_hide() {
	$('#mainSpinner').modal('hide');
}

/**
 * Spawn CLI terminal
 */
function cli_spawn() {
	const connect_str = `http://${api_host_get()}:2222/ssh/host/localhost`;
	log_write_json("cli_spawn", "connect str", connect_str);
	window.open(connect_str, '_blank');
}

/**
 * Spawn CLI terminal for specific node
 * @param {string} node - Node name
 */
function cli_spawn_node(node) {
	const connect_str = `http://${api_host_get()}:2222/ssh/host/${node}`;
	log_write_json("cli_spawn", "connect str", connect_str);
	window.open(connect_str, '_blank');
}

/**
 * Open URL in new tab
 * @param {string} connect_str - URL to open
 */
function main_open_url(connect_str) {
	log_write_json("cli_spawn", "connect str", connect_str);
	window.open(connect_str, '_blank');
}
