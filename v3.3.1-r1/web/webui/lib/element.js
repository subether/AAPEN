/**
 * ETHER|AAPEN|WEB - LIB|ELEMENT
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

// Device type configuration
const DEVICE_TYPES = {
  firewall: {
    menuId: 'firewall',
    icon: 'bi-bricks',
    label: 'Firewall'
  },
  router: {
    menuId: 'router', 
    icon: 'bi-shield-shaded',
    label: 'Router'
  },
  internet: {
    menuId: 'internet',
    icon: 'bi-cloud',
    label: 'Internet'
  },
  core: {
    menuId: 'core',
    icon: 'bi-diagram-2',
    label: 'Core'
  },
  distribution: {
    menuId: 'dist',
    icon: 'bi-diagram-3',
    label: 'Distribution'
  },
  access: {
    menuId: 'access',
    icon: 'bi-ethernet',
    label: 'Access'
  },
  loadbalancer: {
    menuId: 'lbr',
    icon: 'bi-share',
    label: 'Loadbalancer'
  },
  wireless: {
    menuId: 'wifi',
    icon: 'bi-wifi',
    label: 'Wireless'
  },
  storage: {
    menuId: 'storage',
    icon: 'bi-server',
    label: 'Storage'
  },
  power: {
    menuId: 'power',
    icon: 'bi-lightning',
    label: 'Power'
  },
  other: {
    menuId: 'other',
    icon: 'bi-router',
    label: 'Other'
  }
};

// ======================
// INITIALIZATION FUNCTIONS
// ======================

function element_ov_show(){
	element_device_group_accordion("device", true);
	element_service_group_accordion("service", true);
}

function element_device_ov_show() {
    element_device_group_accordion("device", true);
}

function element_service_ov_show() {
    element_service_group_accordion("service", true);
}

function element_db_process_rest_new(db){
	let fid = "[element_db_process_rest_new]";
	
	let serviceNum = 0;
	let deviceNum = 0;
	let groupServiceNum = 0
	let groupDeviceNum = 0;
	
	var elementIndex = db.element.index;
	var elementList = elementIndex.split(';');
	elementList = sort_alpha(elementList);

	//console.log(elementList);

	elementList.forEach((element) => {
		//console.log(fid + " element [" + element + "] type [" + db.element.db[element].object.type + "] model [" + db.element.db[element].object.class + "] type [" + db.element.db[element].object.model + "] group [" + db.element.db[element].id.group + "]");
		
		if(db.element.db[element].object.model == "device"){
			dbnew_element_index_device_add(element);
			dbnew_element_index_device_group_add(db.element.db[element].id.group);
			deviceNum++;
		}
		
		if(db.element.db[element].object.model == "service"){
			dbnew_element_index_service_add(element);
			dbnew_element_index_service_group_add(db.element.db[element].id.group);
			serviceNum++;
		}

	});

	let deviceGroups = dbnew_element_index_device_group_get();
	let deviceGroupNum = 0;
	let serviceGroups = dbnew_element_index_service_group_get();
	let serviceGroupNum = 0;
	
	if(deviceGroups){ deviceGroupNum = deviceGroups.length; };
	if(serviceGroups){ serviceGroupNum = serviceGroups.length; };
	
	//console.log("DEVICE NUM [" + deviceNum + "] DEVICE GROUPS [" + deviceGroupNum + "]");
	//console.log("SERVICE NUM [" + serviceNum + "] DEVICE GROUPS [" + serviceGroupNum + "]");	
	
	document.getElementById('menu-element-device').innerHTML = "Devices (" + deviceNum + ")";
	document.getElementById('menu-element-service').innerHTML = "Services (" + serviceNum + ")";
	document.getElementById("main-card-elements").innerHTML = "Devices [<b>" + deviceNum + "</b>] Groups [<b>" + deviceGroupNum + "</b>]</br>Services [<b>" + serviceNum + "</b>] Groups [<b>" + serviceGroupNum + "</b>]";
	
}

//
// element device menu clear
//
function element_device_menu_remove_all() {
    // Clear all device menu sections using DEVICE_TYPES
    Object.values(DEVICE_TYPES).forEach(type => {
        const menu = document.getElementById(`collapse-dev-${type.menuId}`);
        if(menu){
            menu.innerHTML = "";
        }
    });
}

//
//
//
//function element_device_menu_add(elementname) {
	//const func = function() { cluster_async_show(nodename) };
//	menu_add_item(nodename, 'collapse-element-online', "node_cluster_" + elementname, "bi-view-stacked", func);
//}


//
// create device group element accordion
//
function element_device_group_accordion(type, init) {
	var search = document.getElementById("element-ov-search");

	document.getElementById("accordionElementService").innerHTML = "";
	var root = document.getElementById('accordionElementService');
	root.innerHTML = "";
	
	var header = document.getElementById('accordionElementHeader');
	header.innerHTML = "<h5>Devices</h5>";
	
	var deviceGroup = dbnew_element_index_device_group_get();

	//console.log(deviceGroup);

	var deviceNum = 0;
	var deviceTotal = 0;
	
	// initialize view
	if(init){
		search.value = "";
	}
	
	//
	//
	//
	deviceGroup.forEach((group) => {
		
		var groupNum = 0;
		var accordion = view_accordion_build("accordionElementGroup" + group, "collapseElementGroup" + group, "bi-diagram-3", "Group [<b>" + group + "</b>]");
		var divElmGroup = view_accordion_element_build("collapseElementGroup" + group, "headingXYZ", "accordionElementGroup" + group);
		
		// create table and add it to the view
		var row = document.createElement("div");
		row.innerHTML += '<table id="deviceGrpTbl_' + group + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 8%">[ name ]</th><th style="width: 5%">[ id ]</th><th style="width: 5%">[ group ]</th><th style="width: 5%">[ make ]</th><th style="width: 5%">[ model ]</th><th style="width: 8%">[ address ]</th><th style="width: 5%">[ api enabled ]</th><th style="width: 5%">[ api stats ]</th><th style="width: 5%">[ ssh ]</th><th style="width: 8%">[ web ]</th><th style="width: 5%">[ show ]</th></tr></thead><tbody></tbody></table>';

		// add items
		divElmGroup.appendChild(row);
		accordion.appendChild(divElmGroup);
		root.appendChild(accordion);
		
		//get devices in this group
		var deviceIndex = dbnew_element_index_device_get();
		
		//console.log(deviceIndex);
		
		deviceIndex.forEach((deviceName) => {
			var elementData = dbnew_element_get(deviceName);
			
			//console.log(elementData.id.name);
					
			if(elementData.id.group == group){
				
				if(search.value == ""){
					element_device_table_build(elementData, group);
					groupNum++;
				}
				else{
					if(newSearch(elementData, search.value)){
						element_device_table_build(elementData, group);
						groupNum++;
						$("#collapseElementGroup" + group).collapse('toggle');
					}
				}
				
				deviceTotal++;
			}

		});
		
		// update header
		document.getElementById("accordionElementGroup" + group + "btn").innerHTML += " devices [<b>" + groupNum + "</b>]";
		
		deviceNum += groupNum;
	});
	
	// init element search
	search.addEventListener("keypress", function(eventElementOv) {
		if(eventElementOv.key === "Enter"){
			eventElementOv.preventDefault();
			element_device_group_accordion("device", false);
		}
	}); 
	
	
	document.getElementById('main-element-dev-total').innerHTML = "<b>" + deviceTotal + "</b>";
	document.getElementById('main-element-dev-shown').innerHTML = "<b>" + deviceNum + "</b>";
	
	main_element_overview_show();
	
}	

//
// element table item build
//
function element_device_table_build(elementData, group){
	// create table
	var address = "";
	var ssh = "";
	var web = "";
	
	// address
	if((typeof elementData.device.access.addr !== 'undefined')){
		address = elementData.device.access.addr;
	}

	// web
	if((typeof elementData.device.access.web !== 'undefined')){
		web = elementData.device.access.web.url;
	}

	// ssh
	if((typeof elementData.device.access.web !== 'undefined')){
		ssh = '<b style="color:#0040ff"><a id="tempbtn_ssh" class="btn btn-link tablebtn">' + "[ssh]</a></b>";
	}	
	
	var apiEnabled = "false";
	var apiStats = "false";
	
	if(elementData.api && elementData.api.enabled){
		apiEnabled = "true";
		
		if(elementData.meta && elementData.meta.stats){
			apiStats = "true";
		}
	}
	
	var tbodyElement = $('#deviceGrpTbl_' + group + " tbody");
	//tbodyElement.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_show" class="btn btn-link tablebtn">' + elementData.id.name + "</a></b></td><td>" + elementData.id.id + "</td><td>" + elementData.id.group + "</td><td>" + elementData.device.model.make + "</td><td>" + elementData.device.model.name + "</td><td>" + address + "</td><td>" + apiEnabled + "</td><td>" + apiStats + "</td><td>" + ssh + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_web" class="btn btn-link tablebtn">' + web + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_json" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");	
	tbodyElement.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_show" class="btn btn-link tablebtn">' + elementData.id.name + "</a></b></td><td>" + elementData.id.id + "</td><td>" + elementData.id.group + "</td><td><b>" + elementData.device.model.make + "</b></td><td><b>" + elementData.device.model.name + "</b></td><td>" + address + "</td><td>" + view_color_boolean(apiEnabled) + "</td><td>" + view_color_boolean(apiStats) + "</td><td>" + ssh + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_web" class="btn btn-link tablebtn">' + web + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_json" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");	
	
	// show
	document.getElementById("tempbtn_show").id = "btn_elm_group_show" + elementData.id.name;
	document.getElementById("btn_elm_group_show" + elementData.id.name).onclick = function() { element_device_show(elementData.id.name) };
	
	// json
	document.getElementById("tempbtn_json").id = "btn_elm_group_json" + elementData.id.name;
	document.getElementById("btn_elm_group_json" + elementData.id.name).onclick = function() { json_show("[ " + elementData.id.name + " ]", elementData.id.name, "element_dev_ov", elementData) };

	
	// web
	if(typeof elementData.device.access.web !== 'undefined'){
		document.getElementById("tempbtn_web").id = "btn_elm_group_web" + elementData.id.name;
		document.getElementById("btn_elm_group_web" + elementData.id.name).onclick = function() { main_open_url(elementData.device.access.web.url) }; 
	}
	
	// ssh
	if(typeof elementData.device.access.ssh !== 'undefined'){
		//document.getElementById("tempbtn_ssh").id = "btn_elm_ssh" + elementData.id.name;
		//document.getElementById("btn_elm_ssh" + elementData.id.name).onclick = function() { main_open_url(elementData.device.access.web.url) }; 
	}	
	
}

//
// create device group element accordion
//
function element_service_group_accordion(type, init) {
	var search = document.getElementById("element-ov-search");

	document.getElementById("accordionElementService").innerHTML = "";
	var root = document.getElementById('accordionElementService');
	root.innerHTML = "";
	
	var header = document.getElementById('accordionElementHeader');
	header.innerHTML = "<h5>Services</h5>";
	
	var serviceGroup = dbnew_element_index_service_group_get();

	var serviceNum = 0;
	var serviceTotal = 0;
	
	// initialize view
	if(init){
		search.value = "";
	}
	
	//
	//
	//
	serviceGroup.forEach((group) => {
		//console.log(group);
		
		var groupNum = 0;
		var accordion = view_accordion_build("accordionElementGroup" + group, "collapseElementGroup" + group, "bi-diagram-3", "Group [<b>" + group + "</b>]");
		var divElmGroup = view_accordion_element_build("collapseElementGroup" + group, "headingXYZ", "accordionElementGroup" + group);
		
		// create table and add it to the view
		var row = document.createElement("div");
		row.innerHTML += '<table id="serviceGrpTbl_' + group + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 8%">[ name ]</th><th style="width: 5%">[ id ]</th><th style="width: 7%">[ group ]</th><th style="width: 7%">[ system ]</th><th style="width: 15%">[ web ]</th><th style="width: 5%">[ show ]</th></tr></thead><tbody></tbody></table>';

		// add items
		divElmGroup.appendChild(row);
		accordion.appendChild(divElmGroup);
		root.appendChild(accordion);
		
		//get devices in this group
		var serviceIndex = dbnew_element_index_service_get();
		
		serviceIndex.forEach((serviceName) => {
			var elementData = dbnew_element_get(serviceName);
						
			if(elementData.id.group == group){

				if(search.value == ""){
					element_service_table_build(elementData, group);
					groupNum++;
				}
				else{
					if(newSearch(elementData, search.value)){
						element_service_table_build(elementData, group);
						groupNum++;
						$("#collapseElementGroup" + group).collapse('toggle');
					}
				}
				
				serviceTotal++;
			}
			
		});
		
		// update header
		document.getElementById("accordionElementGroup" + group + "btn").innerHTML += " devices [<b>" + groupNum + "</b>]";
		
		serviceNum += groupNum;
	});
	
	// init element search
	search.addEventListener("keypress", function(eventElementOv) {
		if(eventElementOv.key === "Enter"){
			eventElementOv.preventDefault();
			element_service_group_accordion("service", false);
		}
	}); 
	
	
	document.getElementById('main-element-dev-total').innerHTML = "<b>" + serviceTotal + "</b>";
	document.getElementById('main-element-dev-shown').innerHTML = "<b>" + serviceNum + "</b>";
	
	main_element_overview_show();
	
}	

//
// element table item build
//
function element_service_table_build(elementData, group){
	var web = "";
	var systemName = "";
	
	// web
	if((typeof elementData.service.web !== 'undefined')){
		web = elementData.service.web.url;
	}

		// address
	if((typeof elementData.service.system !== 'undefined') && (typeof elementData.service.system.name !== 'undefined')){
		systemName = elementData.service.system.name;
	}

	var tbodyElement = $('#serviceGrpTbl_' + group + " tbody");
	tbodyElement.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_show" class="btn btn-link tablebtn">' + elementData.id.name + "</a></b></td><td>" + elementData.id.id + "</td><td>" + elementData.id.group + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_system" class="btn btn-link tablebtn">' + systemName + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_web" class="btn btn-link tablebtn">' + web + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_json" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");	
	
	// show
	document.getElementById("tempbtn_show").id = "btn_elm_group_show" + elementData.id.name;
	document.getElementById("btn_elm_group_show" + elementData.id.name).onclick = function() { element_service_show(elementData.id.name) };
	
	// json
	document.getElementById("tempbtn_json").id = "btn_elm_group_json" + elementData.id.name;
	document.getElementById("btn_elm_group_json" + elementData.id.name).onclick = function() { json_show("[ " + elementData.id.name + " ]", elementData.id.name, "element_srv_ov", elementData) };

	// web
	if(typeof elementData.service.web !== 'undefined'){
		document.getElementById("tempbtn_web").id = "btn_elm_group_web" + elementData.id.name;
		document.getElementById("btn_elm_group_web" + elementData.id.name).onclick = function() { main_open_url(elementData.service.web.url) }; 
	}
	
	// address
	if((typeof elementData.service.system !== 'undefined') && (typeof elementData.service.system.name !== 'undefined')){
		document.getElementById("tempbtn_system").id = "btn_elm_system" + systemName;
		document.getElementById("btn_elm_system" + systemName).onclick = function() { system_show(systemName); }; 
		
	}
	
}

//
//
//
function element_device_show_clean(){
	
	document.getElementById("main-element-device-header").innerHTML = "[n/a]";
	document.getElementById("main-element-device-id-header").innerHTML = "Device [n/a]";
	document.getElementById("main-element-device-model-header").innerHTML = "Make [n/a]";
	
	document.getElementById("main-element-device-uid").value = "";
	document.getElementById("main-element-device-name").value = "";
	document.getElementById("main-element-device-desc").value = "";
	document.getElementById("main-element-device-group").value = "";
	
	document.getElementById("main-element-device-make").value = "";
	document.getElementById("main-element-device-model").value = "";
	document.getElementById("main-element-device-serial").value = "";
	
	// asset
	document.getElementById("main-element-device-date").value = "";
	document.getElementById("main-element-device-vendor").value = "";
	document.getElementById("main-element-device-warranty").value = "";
	document.getElementById("main-element-device-receipt").value = "";
	
	// API
	
	document.getElementById("main-elm-dev-api-mt-dev-header").innerHTML = "Device [n/a]";
	document.getElementById("main-element-device-mt-interface-wifi").innerHTML = "Wireless [n/a]";
	document.getElementById("main-element-device-mt-interface-bridge").innerHTML = "Bridges [n/a]";
	
	
	$("#elementDevMtTableHw tbody tr").remove();
	$("#elementDevMtTableRes tbody tr").remove();	
	$("#elementDevMtTableHealth tbody tr").remove();
	$("#elementDevMtTableIpAddr tbody tr").remove();
	$("#elementDevMtTableIpVRF tbody tr").remove();
	$("#elementDevMtTableIpRoute tbody tr").remove();
	
	$("#elementDevMtTableEthBri tbody tr").remove();
	$("#elementDevMtTableEth tbody tr").remove();
	$("#elementDevMtTableBond tbody tr").remove();
	$("#elementDevMtTableEthLo tbody tr").remove();
	$("#elementDevMtTableEthVrrp tbody tr").remove();
	$("#elementDevMtTableEthVlan tbody tr").remove();
	$("#elementDevMtTableEthWg tbody tr").remove();
	$("#elementDevMtTableEthVlanIf tbody tr").remove();
	$("#elementDevMtTableWifiCap tbody tr").remove();
	
	//$("#elementMlagBridgeHeaderTbl tbody tr").remove();
	
	//"elementMlagBridgeHeaderTbl"
	
	document.getElementById("main-element-device-mt-ip-routes-header").innerHTML = "Routes [n/a] VRF [n/a]";
	document.getElementById("main-element-device-mt-interface").innerHTML = "Interfaces [n/a]";
	
	document.getElementById("elementCpuProgress").style.width = parseInt(0) + "%";
	document.getElementById("elementRamProgress").style.width = parseInt(0) + "%";
	document.getElementById("elementHddProgress").style.width = parseInt(0) + "%";
	
	
	document.getElementById('accordionDeviceApiMtInterfaceBridge').innerHTML = "";
	
	
	
	document.getElementById('accordionDeviceApiMtVdevBond').innerHTML = "";
	document.getElementById('accordionDeviceApiMtVdevVrrp').innerHTML = "";
	
	
	document.getElementById("main-element-device-mt-bond-vdev").innerHTML = "MLAG [<b>" + "UNKNOWN" + "</b>]";
	document.getElementById("main-element-device-mt-vrrp-vdev").innerHTML = "VRRP [<b>" + "UNKNOWN" + "</b>]";
}

// 
// show device lemeents
//
function element_device_show(deviceName){
	
	element_device_show_clean();
	main_element_device_show();
	
	log_write_json("element_device_show", "success", deviceName);
	
	document.getElementById("main-element-device-header").innerHTML = "[ " + deviceName + " ]";
	
	var deviceData = dbnew_element_get(deviceName);
	
	//document.getElementById("main-element-device-btn-api").onclick = function() { main_element_mt_device_show() };
	//document.getElementById("main-element-device-btn-api").onclick = function() { element_device_mikrotik_show(deviceData) };
	document.getElementById("main-element-device-btn-json").onclick = function() { json_show("[ " + deviceName + " ]", deviceName, "element_dev", deviceData) };
	
	
	// header
	log_write_json("element_device_show", "data", deviceData);
	
	document.getElementById("main-element-device-btn-web").onclick = function() { window.open(deviceData.device.access.web.url, '_blank'); };

	// Device config
	document.getElementById("main-element-device-id-header").innerHTML = "Device [<b>" + deviceName + "</b>] id [<b>" + deviceData.id.id + "</b>] group [<b>" + deviceData.id.group + "</b>] desc [<b>" + deviceData.id.desc + "</b>]";
	
	// identity
	document.getElementById("main-element-device-uid").value = deviceData.id.id;
	document.getElementById("main-element-device-name").value = deviceData.id.name;
	document.getElementById("main-element-device-desc").value = deviceData.id.desc;
	document.getElementById("main-element-device-group").value = deviceData.id.group;
	
	document.getElementById("main-element-device-model-header").innerHTML = "Make [<b>" + deviceData.device.model.make + "</b>] model [<b>" + deviceData.device.model.name + "</b>]";
	
	// model
	document.getElementById("main-element-device-make").value = deviceData.device.model.make;
	document.getElementById("main-element-device-model").value = deviceData.device.model.name;
	document.getElementById("main-element-device-serial").value = deviceData.device.model.serial;
	
	// asset
	document.getElementById("main-element-device-date").value = deviceData.device.asset.date;
	document.getElementById("main-element-device-vendor").value = deviceData.device.asset.vendor;
	document.getElementById("main-element-device-warranty").value = deviceData.device.asset.warranty;
	document.getElementById("main-element-device-receipt").value = deviceData.device.asset.receipt;
	
	
	// access ssh
	//document.getElementById("main-element-device-ssh-header").innerHTML = "SSH Address [<b>" + deviceData.device.access.ssh.addr + "</b>] port [<b>" + deviceData.device.access.ssh.port + "</b>] user [<b>" + deviceData.device.access.ssh.user + "</b>]";
	
	//document.getElementById("main-element-device-ssh-addr").value = deviceData.device.access.ssh.addr;
	//document.getElementById("main-element-device-ssh-port").value = deviceData.device.access.ssh.port;
	
	//document.getElementById("main-element-device-ssh-user").value = deviceData.device.access.ssh.user;
	//document.getElementById("main-element-device-ssh-opts").value = deviceData.device.access.ssh.opts;
	
	//document.getElementById("main-element-device-ssh-key-file").value = deviceData.device.access.ssh.key.file;
	//document.getElementById("main-element-device-ssh-key-dir").value = deviceData.device.access.ssh.key.dir;
	
	
	// access web
	//document.getElementById("main-element-device-web-header").innerHTML = "Web Interface [<b>" + deviceData.device.access.web.url + "</b>]";
	
	//document.getElementById("main-element-device-web-url").value = deviceData.device.access.web.url;
	
	//
	// check for element 
	//
	// the device object itself does not contain the elements... TODO..
	
	// hack
	if(deviceData.api && deviceData.api.enabled){

		if(deviceData.meta && deviceData.meta.stats){

			if(deviceData.api.type == "mikrotik"){
				element_device_mikrotik_show(deviceData);
			}
		}
	}
	
}

//
//
//
function element_device_mikrotik_show(deviceData){
	main_element_mt_device_show();
	
	//console.log(deviceData);
	
	if(deviceData.meta && deviceData.meta.stats){
		//console.log("DEVICE DOES HAVE STATS");
		
		// platform
		if(deviceData.meta.stats.system && deviceData.meta.stats.system.resource){
			//console.log("DEVICE DOES HAVE STATS: SYSTEM");

			var diff = date_str_diff_now(deviceData.meta.stats.updated);
			
			document.getElementById("main-elm-dev-api-mt-dev-header").innerHTML = "Device [<b>" + deviceData.meta.stats.system.resource.platform + "</b>] model [<b>" + deviceData.meta.stats.system.resource['board-name'] + "</b>] uptime [<b>" + deviceData.meta.stats.system.resource.uptime + "</b>] delta [<b>" + diff + "</b>]";
			
			var tbodyElementMtTableHw = $("#elementDevMtTableHw tbody");
			tbodyElementMtTableHw.append("<tr><td><b>" + deviceData.meta.stats.system.resource.platform + "</b></td><td><b>" + deviceData.meta.stats.system.resource['board-name'] + "</b></td><td>" + deviceData.meta.stats.system.routerboard['serial-number'] + "</td><td>" + deviceData.meta.stats.system.resource.version + "</td><td>" + deviceData.meta.stats.system.resource.uptime + "</td><td>" + deviceData.meta.stats.updated + "</td><td>" + diff + "</td></tr>");	
	
			var usedPercMem = (parseInt(deviceData.meta.stats.system.resource['free-memory']) /  parseInt(deviceData.meta.stats.system.resource['total-memory'])) * 100;
			var usedPercHdd = (parseInt(deviceData.meta.stats.system.resource['free-hdd-space']) / parseInt(deviceData.meta.stats.system.resource['total-hdd-space'])) * 100;
	
			var tbodyElementMtTableRes = $("#elementDevMtTableRes tbody");
			tbodyElementMtTableRes.append("<tr><td>" + deviceData.meta.stats.system.resource.cpu + "</td><td>" + deviceData.meta.stats.system.resource['cpu-count'] + "</td><td>" + deviceData.meta.stats.system.resource['cpu-frequency'] + "</td><td>" + deviceData.meta.stats.system.resource['cpu-load'] + "</td><td>" + niceBytes(deviceData.meta.stats.system.resource['total-memory']) + "</td><td>" + niceBytes(deviceData.meta.stats.system.resource['free-memory']) + "</td><td>" + (100 - usedPercMem.toFixed(0)) + "%</td><td>" + niceBytes(deviceData.meta.stats.system.resource['total-hdd-space']) + "</td><td>" + niceBytes(deviceData.meta.stats.system.resource['free-hdd-space']) + "</td><td>" + (100 - usedPercHdd.toFixed(0)) + "%</td></tr>");	
	
			document.getElementById("elementCpuProgress").style.width = parseInt(deviceData.meta.stats.system.resource['cpu-load']) + "%";
			document.getElementById("elementCpuProgress").innerHTML = "<b>" + parseInt(deviceData.meta.stats.system.resource['cpu-load']) + "%</b>";
			
			document.getElementById("elementRamProgress").style.width = parseInt((100 - usedPercMem.toFixed(0))) + "%";
			document.getElementById("elementRamProgress").innerHTML = "<b>" + parseInt((100 - usedPercMem.toFixed(0))) + "%</b>";
			
			document.getElementById("elementHddProgress").style.width = parseInt((100 - usedPercHdd.toFixed(0))) + "%";
			document.getElementById("elementHddProgress").innerHTML = "<b>" + parseInt((100 - usedPercHdd.toFixed(0))) + "%</b>";
		}
		
		// sensors
		if(deviceData.meta.stats.system && deviceData.meta.stats.system.health){
			//console.log("DEVICE DOES HAVE STATS: HEALTH");
			var elementHealthIndex = deviceData.meta.stats.system.health.index;
			var elementHealthList = elementHealthIndex.split(';');
			var tbodyElementMtTableHealth = $("#elementDevMtTableHealth tbody");

			var healthHeader = "Health";
			var healthStatus = 0;

			elementHealthList.forEach((sensor) => {
				//console.log("SENSOR: " + sensor);
				tbodyElementMtTableHealth.append("<tr><td>" + deviceData.meta.stats.system.health[sensor].name + "</td><td>" + deviceData.meta.stats.system.health[sensor].value + " " + deviceData.meta.stats.system.health[sensor].type + "</td></tr>");
				
				// temp
				//var temp = "n/a";
				if(deviceData.meta.stats.system.health[sensor].name == "temperature"){
					healthHeader += " - HW temp [<b>" + view_health_color_temp(deviceData.meta.stats.system.health[sensor].value) + " C</b>]";
					healthStatus = 1;
				}
							
				// cpu
				//var cpuTemp = "n/a";
				if(deviceData.meta.stats.system.health[sensor].name == "cpu-temperature"){
					//cpuTemp = deviceData.meta.stats.system.health[sensor]['cpu-temperature'];
					healthHeader += " - CPU temp [<b>" + view_health_color_temp(deviceData.meta.stats.system.health[sensor].value) + " C</b>]";
					healthStatus = 1;
				}
				
				// psu 1
				var psu1 = "n/a";
				if(deviceData.meta.stats.system.health[sensor].name == "psu1-state"){
					//cpuTemp = deviceData.meta.stats.system.health[sensor]['psu1-state'];
					healthHeader += " - PSU-1 [<b>" + view_health_color_status(deviceData.meta.stats.system.health[sensor].value) + "</b>]";
					healthStatus = 1;
				}			
				
				// psu 1
				var psu2 = "n/a";
				if(deviceData.meta.stats.system.health[sensor].name == "psu2-state"){
					healthHeader += " - PSU-2 [<b>" + view_health_color_status(deviceData.meta.stats.system.health[sensor].value) + "</b>]";
					healthStatus = 1;
				}	

				// psu 1
				var psu2 = "n/a";
				if(deviceData.meta.stats.system.health[sensor].name == "fan-state"){
					healthHeader += " - Fans [<b>" + view_health_color_status(deviceData.meta.stats.system.health[sensor].value) + "</b>]";
					healthStatus = 1;
				}
					
			});

			if(healthStatus){
				//console.log("YES HEALTH STATUS!!");
				document.getElementById("main-elm-dev-api-mt-health-header").innerHTML = healthHeader;
			}
			else{
				//console.log("NO HEALTH STATUS!!");
			}	

			
			//document.getElementById("main-element-device-mt-ip-routes-header").innerHTML = "Routes [<b>" + routeNum + "</b>] VRF [<b>" + vrfNum + "</b>]";
		}		
		
		// address
		if(deviceData.meta.stats.ip && deviceData.meta.stats.ip.addr){
			//console.log("DEVICE DOES HAVE STATS: ADDR");
			var elementIpAddrIndex = deviceData.meta.stats.ip.addr.index;
			var elementIpAddrList = elementIpAddrIndex.split(';');
			var tbodyElementMtTableIpAddr = $("#elementDevMtTableIpAddr tbody");

			elementIpAddrList.forEach((address) => {
				//console.log("ADDRESS: " + address);
				tbodyElementMtTableIpAddr.append("<tr><td><b>" + deviceData.meta.stats.ip.addr[address]['interface'] + "</b></td><td><b>" + deviceData.meta.stats.ip.addr[address]['actual-interface'] + "</b></td><td>" + (deviceData.meta.stats.ip.addr[address]['comment'] || "") + "</td><td>" + view_color_boolean_inv(deviceData.meta.stats.ip.addr[address]['disabled']) + "</td><td>" + view_color_boolean_inv(deviceData.meta.stats.ip.addr[address]['invalid']) + "</td><td>" + deviceData.meta.stats.ip.addr[address]['dynamic'] + "</td><td>" + deviceData.meta.stats.ip.addr[address]['slave'] + "</td><td><b>" + deviceData.meta.stats.ip.addr[address]['address'] + "</b></td><td><b>" + deviceData.meta.stats.ip.addr[address]['network'] + "</b></td></tr>");
			});
			
			
		}

		var vrfNum = ""

		// vrf
		if(deviceData.meta.stats.ip && deviceData.meta.stats.ip.vrf){
			//console.log("DEVICE DOES HAVE STATS: VRF");
			var elementIpVRFIndex = deviceData.meta.stats.ip.vrf.index;
			var elementIpVRFList = elementIpVRFIndex.split(';');
			var tbodyElementMtTableIpVRF = $("#elementDevMtTableIpVRF tbody");

			elementIpVRFList.forEach((vrf) => {
				//console.log("VRF: " + vrf);
				tbodyElementMtTableIpVRF.append("<tr><td><b>" + deviceData.meta.stats.ip.vrf[vrf].name + "</b></td><td>" + (deviceData.meta.stats.ip.vrf[vrf].builtin || "") + "</td><td>" + deviceData.meta.stats.ip.vrf[vrf].disabled + "</td><td>" + deviceData.meta.stats.ip.vrf[vrf].interfaces + "</td></tr>");
			});
			
			vrfNum = elementIpVRFList.length;
		}

		var routeNum = "";

		// routes
		if(deviceData.meta.stats.ip && deviceData.meta.stats.ip.route){
			//console.log("DEVICE DOES HAVE STATS: ROUTE");
			var elementIpRouteIndex = deviceData.meta.stats.ip.route.index;
			var elementIpRouteList = elementIpRouteIndex.split(';');
			var tbodyElementMtTableIpRoute = $("#elementDevMtTableIpRoute tbody");
			
			elementIpRouteList.forEach((route) => {
				//console.log("ROUTE: " + route);
				tbodyElementMtTableIpRoute.append("<tr><td><b>" + (deviceData.meta.stats.ip.route[route]['routing-table'] || "") + "</b></td><td>" + (view_color_boolean(deviceData.meta.stats.ip.route[route]['active']) || "") + "</td><td>" + (deviceData.meta.stats.ip.route[route]['dynamic'] || "") + "</td><td>" + (deviceData.meta.stats.ip.route[route]['distance'] || "") + "</td><td><b>" + deviceData.meta.stats.ip.route[route]['gateway'] + "</b></td><td>" + (deviceData.meta.stats.ip.route[route]['immediate-gw'] || "") + "</td><td><b>" + deviceData.meta.stats.ip.route[route]['dst-address'] + "</b></td><td>" + (deviceData.meta.stats.ip.route[route]['local-address'] || "") + "</td></tr>");
			});
			
			routeNum = elementIpRouteList.length;
		}
		
		
		document.getElementById("main-element-device-mt-ip-routes-header").innerHTML = "Routes [<b>" + routeNum + "</b>] VRF [<b>" + vrfNum + "</b>]";
		
		// process interfaces
		if(deviceData.meta.stats.interface && deviceData.meta.stats.interface.index){
			var bridgeNum = 0;
			var etherNum = 0;
			var bondNum = 0;
			var loNum = 0;
			var vlanNum = 0;
			var vrrpNum = 0;
			var wgNum = 0;
			var capNum = 0;
		
			// 
			var elementEthTypeIndex = deviceData.meta.stats.interface.index;
			var elementEthTypeList = elementEthTypeIndex.split(';');
		
			// iterate interface categories
			elementEthTypeList.forEach((ethType) => {
				//console.log("ETHTYPE: " + ethType);
				
				// bridge
				if(ethType == "bridge"){
					var elementEthBridgeIndex = deviceData.meta.stats.interface.bridge.index;
					var elementEthBridgeList = elementEthBridgeIndex.split(';');
					
					elementEthBridgeList.forEach((bridge) => {
						//console.log("BRIDGE: " + bridge);
						var tbodyElementMtTableEthBri = $("#elementDevMtTableEthBri tbody");
						tbodyElementMtTableEthBri.append("<tr><td><b>" + deviceData.meta.stats.interface.bridge[bridge].name + "</b></td><td>" + view_color_boolean(deviceData.meta.stats.interface.bridge[bridge].running) + "</td><td>" + deviceData.meta.stats.interface.bridge[bridge].disabled + "</td><td>" + (deviceData.meta.stats.interface.bridge[bridge]['actual-mtu'] || "") + "</td><td>" + deviceData.meta.stats.interface.bridge[bridge]['mac-address'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.bridge[bridge]['rx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.bridge[bridge]['rx-drop'] + "</td><td>" + deviceData.meta.stats.interface.bridge[bridge]['rx-error'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.bridge[bridge]['tx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.bridge[bridge]['tx-drop'] + "</td><td>" + deviceData.meta.stats.interface.bridge[bridge]['tx-error'] + "</td></tr>");
					});
					
					bridgeNum = elementEthBridgeList.length;
				}
				
				// ether
				if(ethType == "ether"){
					var elementEthIndex = deviceData.meta.stats.interface.ether.index;
					var elementEthList = elementEthIndex.split(';');
					
					elementEthList.forEach((ether) => {
						//console.log("ETHER: " + ether);
						var tbodyElementMtTableEth = $("#elementDevMtTableEth tbody");
						tbodyElementMtTableEth.append("<tr><td><b>" + deviceData.meta.stats.interface.ether[ether].name + "</b></td><td><b>" + (deviceData.meta.stats.interface.ether[ether].comment || "") + "</b></td><td>" + view_color_boolean(deviceData.meta.stats.interface.ether[ether].running) + "</td><td>" + deviceData.meta.stats.interface.ether[ether].disabled + "</td><td><b>" + (deviceData.meta.stats.interface.ether[ether].slave || "") + "</b></td><td>" + deviceData.meta.stats.interface.ether[ether]['actual-mtu'] + "</td><td>" + deviceData.meta.stats.interface.ether[ether]['mac-address'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.ether[ether]['rx-byte']) + "</b></td><td><b>" + niceBytes(deviceData.meta.stats.interface.ether[ether]['tx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.ether[ether]['link-downs'] + "</td></tr>");
					});
					
					etherNum = elementEthList.length;
				}
				
				// bond
				if(ethType == "bond"){
					var elementEthBondIndex = deviceData.meta.stats.interface.bond.index;
					var elementEthBondList = elementEthBondIndex.split(';');
					
					elementEthBondList.forEach((bond) => {
						//console.log("BOND: " + bond);
						var tbodyElementMtTableEthBond = $("#elementDevMtTableBond tbody");
						tbodyElementMtTableEthBond.append("<tr><td><b>" + deviceData.meta.stats.interface.bond[bond].name + "</b></td><td><b>" + (deviceData.meta.stats.interface.bond[bond].comment || "") + "</b></td><td>" + view_color_boolean(deviceData.meta.stats.interface.bond[bond].running) + "</td><td>" + deviceData.meta.stats.interface.bond[bond].disabled + "</td><td>" + deviceData.meta.stats.interface.bond[bond].mtu + "</td><td>" + deviceData.meta.stats.interface.bond[bond]['mac-address'] + "</td><td>" + deviceData.meta.stats.interface.bond[bond].mode + "</td><td>" + deviceData.meta.stats.interface.bond[bond]['transmit-hash-policy'] + "</td><td>" + deviceData.meta.stats.interface.bond[bond]['lacp-mode'] + "</td><td><b>" + deviceData.meta.stats.interface.bond[bond]['slaves'] + "</b></td><td>" + (deviceData.meta.stats.interface.bond[bond]['mlag-id'] || "") + "</td></tr>");
					});
					
					bondNum = elementEthBondList.length;
				}		
				
				// loopback
				if(ethType == "loopback"){
					var elementEthLoIndex = deviceData.meta.stats.interface.loopback.index;
					var elementEthLoList = elementEthLoIndex.split(';');
					
					elementEthLoList.forEach((loopback) => {
						//console.log("LOOPBACK: " + loopback);
						//elementDevMtTableEthLo
						var tbodyElementMtTableEthLo = $("#elementDevMtTableEthLo tbody");
						tbodyElementMtTableEthLo.append("<tr><td><b>" + deviceData.meta.stats.interface.loopback[loopback].name + "</b></td><td>" + view_color_boolean(deviceData.meta.stats.interface.loopback[loopback].running) + "</td><td>" + deviceData.meta.stats.interface.loopback[loopback].disabled + "</td><td>" + deviceData.meta.stats.interface.loopback[loopback].mtu + "</td><td>" + deviceData.meta.stats.interface.loopback[loopback]['mac-address'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.loopback[loopback]['rx-byte']) + "</b></td><td></b>" + deviceData.meta.stats.interface.loopback[loopback]['rx-drop'] + "</td><td>" + deviceData.meta.stats.interface.loopback[loopback]['rx-error'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.loopback[loopback]['tx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.loopback[loopback]['tx-drop'] + "</td><td>" + deviceData.meta.stats.interface.loopback[loopback]['tx-error'] + "</td></tr>");
					});
					
					loNum = elementEthLoList.length;
				}
				
				// vlan interface
				if(ethType == "vlan"){
					var elementEthVlanIndex = deviceData.meta.stats.interface.vlan.index;
					var elementEthVlanList = elementEthVlanIndex.split(';');
					
					elementEthVlanList.forEach((vlan) => {
						//console.log("VLAN: " + vlan);
						var tbodyElementMtTableEthVlanIf = $("#elementDevMtTableEthVlanIf tbody");
						tbodyElementMtTableEthVlanIf.append("<tr><td><b>" + deviceData.meta.stats.interface.vlan[vlan].name + "</b></td><td>" + (deviceData.meta.stats.interface.vlan[vlan].comment || "") + "</td><td>" + view_color_boolean(deviceData.meta.stats.interface.vlan[vlan].running) + "</td><td>" + deviceData.meta.stats.interface.vlan[vlan].disabled + "</td><td>" + deviceData.meta.stats.interface.vlan[vlan].mtu + "</td><td>" + deviceData.meta.stats.interface.vlan[vlan]['mac-address'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.vlan[vlan]['rx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.vlan[vlan]['rx-drop'] + "</td><td>" + deviceData.meta.stats.interface.vlan[vlan]['rx-error'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.vlan[vlan]['tx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.vlan[vlan]['tx-drop'] + "</td><td>" + deviceData.meta.stats.interface.vlan[vlan]['tx-error'] + "</td></tr>");
					});
					
					vlanNum = elementEthVlanList.length;
				}
				
				// vrrp
				if(ethType == "vrrp"){
					var elementEthVrrpIndex = deviceData.meta.stats.interface.vrrp.index;
					var elementEthVrrpList = elementEthVrrpIndex.split(';');
					
					elementEthVrrpList.forEach((vrrp) => {
						//console.log("VRRP: " + vrrp);
						var tbodyElementMtTableEthVrrp = $("#elementDevMtTableEthVrrp tbody");
						tbodyElementMtTableEthVrrp.append("<tr><td><b>" + deviceData.meta.stats.interface.vrrp[vrrp].name + "</b></td><td>" + (deviceData.meta.stats.interface.vrrp[vrrp].comment || "") + "</td><td>" + view_color_boolean(deviceData.meta.stats.interface.vrrp[vrrp].running) + "</td><td>" + deviceData.meta.stats.interface.vrrp[vrrp].disabled + "</td><td>" + deviceData.meta.stats.interface.vrrp[vrrp].mtu + "</td><td>" + deviceData.meta.stats.interface.vrrp[vrrp]['mac-address'] + "</td><td>" + niceBytes(deviceData.meta.stats.interface.vrrp[vrrp]['rx-byte']) + "</td><td>" + deviceData.meta.stats.interface.vrrp[vrrp]['rx-drop'] + "</td><td>" + deviceData.meta.stats.interface.vrrp[vrrp]['rx-error'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.vrrp[vrrp]['tx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.vrrp[vrrp]['tx-drop'] + "</td><td>" + deviceData.meta.stats.interface.vrrp[vrrp]['tx-error'] + "</td><td>" + deviceData.meta.stats.interface.vrrp[vrrp]['link-downs'] + "</td></tr>");
					});
					
					vrrpNum = elementEthVrrpList.length;
				}	
				
				// wg
				if(ethType == "wg"){
					var elementEthWgIndex = deviceData.meta.stats.interface.wg.index;
					var elementEthWgList = elementEthWgIndex.split(';');
					
					elementEthWgList.forEach((wg) => {
						//console.log("WG: " + wg);
						var tbodyElementMtTableEthWg = $("#elementDevMtTableEthWg tbody");
						tbodyElementMtTableEthWg.append("<tr><td><b>" + deviceData.meta.stats.interface.wg[wg].name + "</b></td><td>" + (deviceData.meta.stats.interface.wg[wg].comment || "") + "</td><td>" + view_color_boolean(deviceData.meta.stats.interface.wg[wg].running) + "</td><td>" + deviceData.meta.stats.interface.wg[wg].disabled + "</td><td>" + deviceData.meta.stats.interface.wg[wg].mtu + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.wg[wg]['rx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.wg[wg]['rx-drop'] + "</td><td>" + deviceData.meta.stats.interface.wg[wg]['rx-error'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.wg[wg]['tx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.wg[wg]['tx-drop'] + "</td><td>" + deviceData.meta.stats.interface.wg[wg]['tx-error'] + "</td></tr>");
					});
					
					wgNum = elementEthWgList.length;
				}			
				
				// vrrp
				if(ethType == "cap"){
					var elementEthCapIndex = deviceData.meta.stats.interface.cap.index;
					var elementEthCapList = elementEthCapIndex.split(';');
					
					elementEthCapList.forEach((cap) => {
						//console.log("VRRP: " + vrrp);
						var tbodyElementMtTableWifiCap = $("#elementDevMtTableWifiCap tbody");
						tbodyElementMtTableWifiCap.append("<tr><td><b>" + deviceData.meta.stats.interface.cap[cap].name + "</b></td><td>" + deviceData.meta.stats.interface.cap[cap].type + "</td><td>" + view_color_boolean(deviceData.meta.stats.interface.cap[cap].running) + "</b></td><td>" + deviceData.meta.stats.interface.cap[cap].disabled + "</td><td>" + deviceData.meta.stats.interface.cap[cap]['actual-mtu'] + "</td><td>" + deviceData.meta.stats.interface.cap[cap]['mac-address'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.cap[cap]['rx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.cap[cap]['rx-drop'] + "</td><td>" + deviceData.meta.stats.interface.cap[cap]['rx-error'] + "</td><td><b>" + niceBytes(deviceData.meta.stats.interface.cap[cap]['tx-byte']) + "</b></td><td>" + deviceData.meta.stats.interface.cap[cap]['tx-drop'] + "</td><td>" + deviceData.meta.stats.interface.cap[cap]['tx-error'] + "</td><td>" + deviceData.meta.stats.interface.cap[cap]['link-downs'] + "</td></tr>");
					});
					
					capNum = elementEthCapList.length;
				}	
				
				document.getElementById("main-element-device-mt-interface-wifi").innerHTML = "Wireless CAP [<b>" + capNum + "</b>]";
				
			});
		
			
			document.getElementById("main-element-device-mt-interface").innerHTML = "Interfaces [<b>" + etherNum + "</b>] Loopbacks [<b>" + loNum + "</b>] Bridges [<b>" + bridgeNum + "</b>] Bonds [<b>" + bondNum + "</b>] Vlans [<b>" + vlanNum + "</b>] Vrrp [<b>" + vrrpNum + "</b>] Wireguard [<b>" + wgNum + "</b>]";
		}
		
		// process interface vlans
		if(deviceData.meta.stats.vlan && deviceData.meta.stats.vlan.index){
			//console.log("VLAN INTERFACE DATA IS PRESENT!");
			
			var elementVlanIndex = deviceData.meta.stats.vlan.index;
			var elementVlanList = elementVlanIndex.split(';');
			
			elementVlanList.forEach((vlan) => {
				//console.log("VLAN: " + vlan);
				var tbodyElementMtTableVlan = $("#elementDevMtTableEthVlan tbody");
				tbodyElementMtTableVlan.append("<tr><td><b>" + deviceData.meta.stats.vlan[vlan]['vlan-id'] + "</b></td><td><b>" + deviceData.meta.stats.vlan[vlan].name + "</b></td><td><b>" + (deviceData.meta.stats.vlan[vlan].comment || "") + "</b></td><td>" + view_color_boolean(deviceData.meta.stats.vlan[vlan].running) + "</td><td>" + deviceData.meta.stats.vlan[vlan].disabled + "</td><td>" + deviceData.meta.stats.vlan[vlan].mtu + "</td><td>" + deviceData.meta.stats.vlan[vlan]['mac-address'] + "</td><td><b>" + deviceData.meta.stats.vlan[vlan].interface + "</b></td></tr>");
			});
			
			
		}
		
		
		/*
		// process interfaces
		if(deviceData.meta.stats.bridge && deviceData.meta.stats.bridge.index){
			console.log("BRIDGE DATA IS PRESENT!");
			
			// process bridges
			var elementBriIndex = deviceData.meta.stats.bridge.index;
			var elementBriList = elementBriIndex.split(';');
					
			elementBriList.forEach((bridge) => {
				console.log("PROCESSING BRIDGE [" + bridge + "]");
				
				
			});
			
		}
		*/
		
	}
	else{
		console.log("DEVICE DOES NOT HAVE STATS");
	}
	
	// generate bridge elements
	element_device_mikrotik_bridge_generate(deviceData);
	
	// generate redundancy elements
	element_device_mikrotik_redundancy(deviceData);
	
}

//
// node resource accordion
//
function element_device_mikrotik_bridge_generate(deviceData) {
	
	var root = document.getElementById('accordionDeviceApiMtInterfaceBridge');
	var header;
	var bridgeDiv = document.createElement("div");
	bridgeDiv.setAttribute("class", "row row-space g-1 mt-1 ms-1 mb-3 me-1");
	
	// header
	//bridgeDiv.innerHTML = "hello world! TOP MARKER";
		
	// bridge main table	
	bridgeDiv.innerHTML += '<table id="elementBridgeHeaderTbl" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 8%">[ name ]</th><th style="width: 5%">[ id ]</th><th style="width: 7%">[ group ]</th><th style="width: 7%">[ system ]</th><th style="width: 15%">[ web ]</th><th style="width: 5%">[ show ]</th></tr></thead><tbody></tbody></table>';
	

	var elementBridgeIndex = deviceData.meta.stats.bridge.index;
	var elementBridgeList = elementBridgeIndex.split(';');


	// iterate bridges
	elementBridgeList.forEach((bridge) => {
		//console.log("BRIDGE: " + bridge);
		
		var accordion = view_accordion_build("accordionElementMtBridge" + bridge, "collapseMtBridge" + bridge, "bi-diagram-3", "Bridge [<b>" + bridge + "</b>]");
		var collapse = view_accordion_element_build("collapseMtBridge" + bridge, "headingMtBridge", "accordionElementMtBridge" + bridge);
		
		var row = document.createElement("div");
		row.setAttribute("id", "nodeResViewTEST");
		row.setAttribute("class", "row row-space g-1 mt-1 ms-1 mb-3 me-2");

		// check for hosts
		if(deviceData.meta.stats.bridge[bridge].host && deviceData.meta.stats.bridge[bridge].host.index){
			var elementBridgeHostIndex = deviceData.meta.stats.bridge[bridge].host.index;
			var elementBridgeHostList = elementBridgeHostIndex.split(';');
			
			// iterate hosts on bridge
			elementBridgeHostList.forEach((host) => {
				//console.log("HOST: " + host);

				var accordionHost = view_accordion_build("accordionElementMtBridgeHost" + bridge + host, "collapseMtBridgeHost" + bridge + host, "bi-diagram-3", "Port [<b>" + host + "</b>]");
				var collapseHost = view_accordion_element_build("collapseMtBridgeHost" + bridge + host, "headingMtBridge", "accordionElementMtBridgeHost" + bridge + host);
				
				var row2 = document.createElement("div");
				row2.setAttribute("id", "nodeResViewTEST2");
				row2.setAttribute("class", "row row-space g-1 mt-2 ms-1 mb-3 me-2");
				
				row2.innerHTML = "<b>Hosts<b>";
				
				//var row = document.createElement("div");
				row2.innerHTML += '<table id="elementBridgeHostTbl_' + bridge + host + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 10%">[ mac ]</th><th style="width: 10%">[ bridge ]</th><th style="width: 10%">[ interface ]</th><th style="width: 10%">[ disabled ]</th><th style="width: 10%">[ invalid ]</th><th style="width: 10%">[ dynamic ]</th><th style="width: 10%">[ external ]</th><th style="width: 10%">[ vlan id ]</th></tr></thead><tbody></tbody></table>';
				
				collapseHost.appendChild(row2);
				accordionHost.appendChild(collapseHost);
				row.appendChild(accordionHost);
								
			});
		}
		
		//
		// add host to main row
		//
		collapse.appendChild(row);
		accordion.appendChild(collapse);
		bridgeDiv.appendChild(accordion);
		
	});
	
	root.appendChild(bridgeDiv);
	
	
	//
	// Populate tables and elements
	//
	elementBridgeList.forEach((bridge) => {
		if(deviceData.meta.stats.bridge[bridge].host && deviceData.meta.stats.bridge[bridge].host.index){
			var elementBridgeHostIndex = deviceData.meta.stats.bridge[bridge].host.index;
			var elementBridgeHostList = elementBridgeHostIndex.split(';');

			elementBridgeHostList.forEach((host) => {
		
				// macs
				if(deviceData.meta.stats.bridge[bridge].host[host] && deviceData.meta.stats.bridge[bridge].host[host].index){
					var elementBridgeHostMacIndex = deviceData.meta.stats.bridge[bridge].host[host].index;
					var elementBridgeHostMacList = elementBridgeHostMacIndex.split(';');
				
					var hostNum = 0;
				
					elementBridgeHostMacList.forEach((mac) => {
						//console.log("MAC: " + mac);
						
						var tbodyElementMtTableBridgeHost = $("#elementBridgeHostTbl_" + bridge + host + " tbody");
						tbodyElementMtTableBridgeHost.append("<tr><td><b>" + mac +"</b></td><td>" + deviceData.meta.stats.bridge[bridge].host[host][mac].bridge + "</td><td>" + deviceData.meta.stats.bridge[bridge].host[host][mac].interface + "</td><td>" + deviceData.meta.stats.bridge[bridge].host[host][mac].disabled + "</td><td>" + deviceData.meta.stats.bridge[bridge].host[host][mac].invalid + "</td><td>" + deviceData.meta.stats.bridge[bridge].host[host][mac].dynamic + "</td><td>" + deviceData.meta.stats.bridge[bridge].host[host][mac].external + "</td><td><b>" + (deviceData.meta.stats.bridge[bridge].host[host][mac].vid || "") + "</b></td></tr>");
						
						hostNum++;
					});
				

				}
		
			});
		
		}
			
	});		
	
	document.getElementById("main-element-device-mt-interface-bridge").innerHTML = "Bridges [<b>" + elementBridgeList + "</b>]";

}

//
// process mikrotik redundancy elements
//
function element_device_mikrotik_redundancy(deviceData){
	
	// check for metadevices
	if(deviceData.redundancy){
		console.log("REDUNDANCY FIELD EXISTS");
		
		var elementRedundancyList = deviceData.redundancy.type.split(';');
			
		elementRedundancyList.forEach((rtype) => {
			console.log("REDUNDANCY TYPE: " + rtype);
			
			if(deviceData.redundancy.id.name){
				console.log("REDUNDANCY NAME [" + deviceData.redundancy.id.name + "]");
				
				//fetch the metadevice
				var elementMetaDeviceData = dbnew_element_get(deviceData.redundancy.id.name);
				
				if(elementMetaDeviceData){
					console.log("SUCCESSFULLY FETCHED METADEVICE!");
					
					//json_show("[ " + deviceData.redundancy.id.name + " ]", deviceData.redundancy.id.name, "metadevice", elementMetaDeviceData);
					
					if(rtype == "mlag"){
						element_device_mikrotik_redundancy_mlag_generate(deviceData, elementMetaDeviceData);
					}
					
					if(rtype == "vrrp"){
						console.log("VRRP HANDLER NOT IMPLEMENTED!!");
						element_device_mikrotik_redundancy_vrrp_generate(deviceData, elementMetaDeviceData);
					}
					
					//console.log(elementMetaDeviceData);
				}
				else{
					//console.log("FAILED TO FETCH METADEVICE!");
				}
				
			}
			else{
				//console.log("REDUNDANCY NAME NOT DEFINED");
			}
			
		});
		
	}
	else{
		//console.log("REDUNDANCY FIELD DOES NOT EXIST");
	}	
	
}



//
// mikrotik redundancy vrrp view generate
//
function element_device_mikrotik_redundancy_vrrp_generate(deviceData, elementMetaDeviceData) {
	

	var root = document.getElementById('accordionDeviceApiMtVdevVrrp');
	var header;
	var vrrpDiv = document.createElement("div");
	vrrpDiv.setAttribute("class", "row row-space g-1 mt-1 ms-1 mb-3 me-1");
	
	// header
	//vrrpDiv.innerHTML = "hello world! VRRP TOP MARKER AAA";
	
	vrrpDiv.innerHTML += '<table id="elementVrrpHeaderTbl" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 10%">[ id ]</th><th style="width: 10%">[ name ]</th><th style="width: 10%">[ devices ]</th><th style="width: 10%">[ vrrp interfaces ]</th><th style="width: 10%">[ updated ]</th><th style="width: 10%">[ delta ]</th><th style="width: 10%">[ show ]</th></tr></thead><tbody></tbody></table>';
	
	//console.log(elementMetaDeviceData);
	
	
	if(elementMetaDeviceData.index && elementMetaDeviceData.index !== ""){
		
		// generate device index
		var elementVrrpDeviceIndex = elementMetaDeviceData.index;
		var elementVrrpDeviceList = elementVrrpDeviceIndex.split(';');
		elementVrrpDeviceList = sort_num(elementVrrpDeviceList);

		// generate bridge index
		var elementVrrpIndex = elementMetaDeviceData.vrrp.index;
		var elementVrrpList = elementVrrpIndex.split(';');
		elementVrrpList = sort_num(elementVrrpList);
		//console.log("VDEV MLAGS: " + elementVrrpIndex);

		// iterate mlags
		elementVrrpList.forEach((vrrp) => {
			//console.log("VVRP: " + vrrp);
			
			var accordion = view_accordion_build("accordionElementMtVrrp" + vrrp, "collapseMtVrrp" + vrrp, "bi-diagram-3", "VRRP interface [<b>" + vrrp + "</b>] devices [<b>" + elementVrrpDeviceIndex + "</b>]");
			var collapse = view_accordion_element_build("collapseMtVrrp" + vrrp, "headingMtVrrp", "accordionElementMtVdedBridge" + vrrp);
			
			// add elements
			var row = document.createElement("div");
			row.setAttribute("id", "elementVrrpView_" + vrrp);
			row.setAttribute("class", "row row-space g-1 mt-1 ms-1 mb-1 me-2");
		
			row.innerHTML = "Interface";
			row.innerHTML += '<table id="elementVrrpTblState_' + vrrp + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 5%">[ interface ]</th><th style="width: 10%">[ active ]</th><th style="width: 10%">[ standby ]</th></tr></thead><tbody></tbody></table>';
		
			row.innerHTML += "Devices";
			row.innerHTML += '<table id="elementVrrpDevTbl_' + vrrp + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 7%">[ device ]</th><th style="width: 10%">[ interface ]</th><th style="width: 10%">[ running ]</th><th style="width: 10%">[ infactive ]</th><th style="width: 10%">[ disabled ]</th><th style="width: 10%">[ link-up ]</th><th style="width: 10%">[ link-down ]</th><th style="width: 10%">[ linkdowns ]</th><th style="width: 10%">[ vrrp mac ]</th><th style="width: 10%">[ rx-byte ]</th><th style="width: 10%">[ tx-byte ]</th></tr></thead><tbody></tbody></table>';
			
			collapse.appendChild(row);

			//
			accordion.appendChild(collapse);
			vrrpDiv.appendChild(accordion);
			root.appendChild(vrrpDiv);
		});		
		
		// populate vrrp tables
		elementVrrpList.forEach((vrrp) => {
			var tbodyElementMtTableVrrpState = $("#elementVrrpTblState_" + vrrp + " tbody");
			var tbodyElementMtTableVrrpDev = $("#elementVrrpDevTbl_" + vrrp + " tbody");
			
			tbodyElementMtTableVrrpState.append("<tr><td><b>" + vrrp +"</b></td><td><b>" + view_color_healthy(string_undefined(elementMetaDeviceData.vrrp.meta[vrrp].active)) +"</b></td><td><b>" + string_undefined(elementMetaDeviceData.vrrp.meta[vrrp].standby) +"</b></td></tr>");
			
			// iterate devices
			elementVrrpDeviceList.forEach((device) => {
				//console.log("VRRP if [" + vrrp + "] device [" + device + "]");	
				tbodyElementMtTableVrrpDev.append("<tr><td><b>" + device +"</b></td><td><b>" + vrrp +"</b></td><td><b>" + view_color_boolean(elementMetaDeviceData.vrrp.db[vrrp][device].running) + "</b></td><td><b>" + view_color_boolean_inv(elementMetaDeviceData.vrrp.db[vrrp][device].inactive) + "</b></td><td><b>" + view_color_boolean_inv(elementMetaDeviceData.vrrp.db[vrrp][device].disabled) +"</b></td><td><b>" + string_undefined(elementMetaDeviceData.vrrp.db[vrrp][device]['last-link-up-time']) + "</b></td><td><b>" + string_undefined(elementMetaDeviceData.vrrp.db[vrrp][device]['last-link-down-time']) + "</b></td><td><b>" + elementMetaDeviceData.vrrp.db[vrrp][device]['link-downs'] + "</b></td><td><b>" + elementMetaDeviceData.vrrp.db[vrrp][device]['mac-address'] + "</b></td><td><b>" + niceBytes(elementMetaDeviceData.vrrp.db[vrrp][device]['rx-byte']) + "</b></td><td><b>" + niceBytes(elementMetaDeviceData.vrrp.db[vrrp][device]['tx-byte']) + "</b></td></tr>");
			});
			
		});
		
		document.getElementById("main-element-device-mt-vrrp-vdev").innerHTML = 'VRRP [<b style="color:#24be14">ACTIVE</b>] members [<b>' + elementVrrpDeviceIndex + "</b>] ports [<b>" + elementVrrpList.length + "</b>]";
		
		var diff = "n/a";
		
		if((typeof elementMetaDeviceData.meta.date !== 'undefined')){
			diff = date_str_diff_now(elementMetaDeviceData.meta.date);
		};
		
		var tbodyElementMtTableVrrp = $("#elementVrrpHeaderTbl tbody");
		tbodyElementMtTableVrrp.append("<tr><td><b>" + elementMetaDeviceData.id.id +"</b></td><td><b>" + elementMetaDeviceData.id.name +"</b></td><td><b>" + elementMetaDeviceData.index +"</b></td><td><b>" + elementVrrpList.length +"</b></td><td><b>" + elementMetaDeviceData.meta.date +"</b></td><td><b>" + diff +"</b></td><td>" + '<b style="color:#0040ff"><a id="btn_mt_mlag_show" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");
		
		document.getElementById("btn_mt_mlag_show").onclick = function() { json_show("[ " + deviceData.id.name + " | " + elementMetaDeviceData.id.name + " ]", deviceData.id.name, "element_dev", elementMetaDeviceData) }; 
	}
	
}


//
// mikrotik redundancy mlag generate
//
function element_device_mikrotik_redundancy_mlag_generate(deviceData, elementMetaDeviceData) {
	
	var root = document.getElementById('accordionDeviceApiMtVdevBond');
	var header;
	var mlagDiv = document.createElement("div");
	mlagDiv.setAttribute("class", "row row-space g-1 mt-1 ms-1 mb-3 me-1");
	
	// bridge main table	
	mlagDiv.innerHTML += '<table id="elementMlagBridgeHeaderTbl" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 10%">[ id ]</th><th style="width: 10%">[ name ]</th><th style="width: 10%">[ devices ]</th><th style="width: 10%">[ mlags ]</th><th style="width: 10%">[ updated ]</th><th style="width: 10%">[ delta ]</th><th style="width: 10%">[ show ]</th></tr></thead><tbody></tbody></table>';
	
	if(elementMetaDeviceData.index && elementMetaDeviceData.index !== ""){
	
		// generate device index
		var elementMlagDeviceIndex = elementMetaDeviceData.index;
		var elementMlagDeviceList = elementMlagDeviceIndex.split(';');
		elementMlagDeviceList = sort_num(elementMlagDeviceList);

		// generate bridge index
		var elementMlagBridgeIndex = elementMetaDeviceData.mlag.index;
		var elementMlagBridgeList = elementMlagBridgeIndex.split(';');
		elementMlagBridgeList = sort_num(elementMlagBridgeList);
		//console.log("VDEV MLAGS: " + elementMlagBridgeIndex);

		// iterate mlags
		elementMlagBridgeList.forEach((mlag) => {
			var accordion = view_accordion_build("accordionElementMtMlagBridge" + mlag, "collapseMtMlagBridge" + mlag, "bi-diagram-3", "MLAG id [<b>" + mlag + "</b>] devices [<b>" + elementMlagDeviceIndex + "</b>]");
			var collapse = view_accordion_element_build("collapseMtMlagBridge" + mlag, "headingMtMlagBridge", "accordionElementMtVdedBridge" + mlag);
			
			// add elements
			var row = document.createElement("div");
			row.setAttribute("id", "elementMlagInterfaceView_" + mlag);
			row.setAttribute("class", "row row-space g-1 mt-1 ms-1 mb-3 me-2");
		
			row.innerHTML = "Interface";	
			row.innerHTML += '<table id="elementMlagBridgeInterfaceTbl_' + mlag + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 5%">[ device ]</th><th style="width: 10%">[ interface ]</th><th style="width: 10%">[ bond ]</th><th style="width: 10%">[ comment ]</th><th style="width: 10%">[ bridge ]</th><th style="width: 10%">[ disabled ]</th><th style="width: 10%">[ forwarding ]</th><th style="width: 10%">[ status ]</th><th style="width: 10%">[ hw-offload ]</th><th style="width: 10%">[ hw-group ]</th></tr></thead><tbody></tbody></table>';
			
			row.innerHTML += "VLANs";
			row.innerHTML += '<table id="elementMlagBridgeVlanTbl_' + mlag + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 8%">[ device ]</th><th style="width: 8%">[ VLANs ]</th><th style="width: 85%">[ VLAN index ]</th><th style="width: 10%">[ VLAN mismatch ]</th></tr></thead><tbody></tbody></table>';
			
			collapse.appendChild(row);

			//
			accordion.appendChild(collapse);
			mlagDiv.appendChild(accordion);
		});
		
		root.appendChild(mlagDiv);
		
		// 
		// populate tables
		//
		elementMlagBridgeList.forEach((mlag) => {
			
			elementMlagDeviceList.forEach((device) => {
				
				// interface
				var tbodyElementMtTableIf = $("#elementMlagBridgeInterfaceTbl_" + mlag + " tbody");
				tbodyElementMtTableIf.append("<tr><td><b>" + device +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].interface.index +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].bond.index +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].port.comment +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].port.bridge +"</b></td><td><b>" + view_color_boolean_inv(elementMetaDeviceData.mlag[mlag][device].port.disabled) +"</b></td><td><b>" + view_color_boolean(elementMetaDeviceData.mlag[mlag][device].port.forwarding) +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].port.status +"</b></td><td><b>" + view_color_boolean(elementMetaDeviceData.mlag[mlag][device].port['hw-offload']) +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].port['hw-offload-group'] +"</b></td></tr>");
				
				// vlans
				var tbodyElementMtTableVlan = $("#elementMlagBridgeVlanTbl_" + mlag + " tbody");
				tbodyElementMtTableVlan.append("<tr><td><b>" + device +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].vlan.num +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].vlan.index +"</b></td><td><b>" + elementMetaDeviceData.mlag[mlag][device].vlan.mismatch || "" +"</b></td></tr>");

			});
			
		});
		
		//main-element-device-mt-bond-vdev
		document.getElementById("main-element-device-mt-bond-vdev").innerHTML = 'MLAG [<b style="color:#24be14">ACTIVE</b>] members [<b>' + elementMlagDeviceIndex + "</b>] ports [<b>" + elementMlagBridgeList.length + "</b>]";
		
		var diff = "n/a";
		
		if((typeof elementMetaDeviceData.meta.date !== 'undefined')){
			diff = date_str_diff_now(elementMetaDeviceData.meta.date);
		};
		
		var tbodyElementMtTableIf = $("#elementMlagBridgeHeaderTbl tbody");
		tbodyElementMtTableIf.append("<tr><td><b>" + elementMetaDeviceData.id.id +"</b></td><td><b>" + elementMetaDeviceData.id.name +"</b></td><td><b>" + elementMetaDeviceData.index +"</b></td><td><b>" + elementMlagBridgeList.length +"</b></td><td><b>" + elementMetaDeviceData.meta.date +"</b></td><td><b>" + diff +"</b></td><td>" + '<b style="color:#0040ff"><a id="btn_mt_mlag_show" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");
	
	
		document.getElementById("btn_mt_mlag_show").onclick = function() { json_show("[ " + deviceData.id.name + " | " + elementMetaDeviceData.id.name + " ]", deviceData.id.name, "element_dev", elementMetaDeviceData) }; 
		//json_show("[ " + deviceName + " ]", deviceName, "element", deviceData)
	
	}

}

//
// show service elements
//
function element_service_show(serviceName){
	
	main_element_service_show();
	
	var servicedata = db_element_service_get(serviceName);
	
	log_write_json("element_service_show", "success", servicedata);
	
	document.getElementById("main-element-service-header").innerHTML = "[ " + serviceName + " ]";
	
	document.getElementById("main-element-service-btn-web").onclick = function() { window.open(servicedata.service.web.url, '_blank'); };
	
	document.getElementById("main-element-service-id-header").innerHTML = "Service [<b>" + serviceName + "</b>] id [<b>" + servicedata.id.id + "</b>] group [<b>" + servicedata.id.group + "</b>] desc [<b>" + servicedata.id.desc + "</b>]";
	
	// identity
	document.getElementById("main-element-service-uid").value = servicedata.id.id;
	document.getElementById("main-element-service-name").value = servicedata.id.name;
	document.getElementById("main-element-service-desc").value = servicedata.id.desc;
	document.getElementById("main-element-service-group").value = servicedata.id.group;
	
	// access web
	document.getElementById("main-element-service-web-header").innerHTML = "Web Interface [<b>" + servicedata.service.web.url + "</b>]";
	
	document.getElementById("main-element-service-web-url").value = servicedata.service.web.url;
		
}
