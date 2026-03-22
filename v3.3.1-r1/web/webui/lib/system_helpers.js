/**
 * ETHER|AAPEN|WEB - LIB|SYSTEM|HELPERS
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/


/**
 * Handles ISO device changes for a system
 * @param {string} systemName - Name of the system
 * @param {string} storDev - Storage device name
 * @description Updates ISO configuration when a new ISO is selected
 */
function system_stor_iso_change(systemName, storDev){
	var isoSelected = document.getElementById("sysIsoSel_" + systemName + storDev).value;
	
	log_write_json("system_stor_iso_change", systemName, isoSelected);

	var isodata = dbnew_storage_get(isoSelected);

	if(typeof isodata !== 'undefined'){
	
		log_write_json("system_stor_iso_change", "ISODATA", isodata);

		document.getElementById("sysIsoName_" + systemName + storDev).value = isodata.id.name;
		document.getElementById("sysIsoDesc_" + systemName + storDev).value = isodata.id.desc;

		document.getElementById("sysIsoImg_" + systemName + storDev).value = isodata.iso.image;
		document.getElementById("sysIsoPath_" + systemName + storDev).value = isodata.iso.dev;
		
	}
	else{
		log_write_json("system_stor_iso_change", "error", "iso data not loaded!");
	}
}

/**
 * Changes the boot device for a system
 * @param {string} systemName - Name of the system
 * @description Updates the boot device configuration and saves to database
 */
function system_boot_change(systemName){
	
	var bootdev = document.getElementById("sysBootSelect" + systemName).value;
	log_write_json("system_boot_change", "boot changed", "system [" + systemName + "] bootdev [" + bootdev + "]");
	
	var systemData = dbnew_system_get(systemName);
	systemData.stor.boot = bootdev;
	dbnew_system_set(systemName, systemData)
}

/**
 * Adds a network device to a system
 * @param {string} systemName - Name of the system
 * @param {string} nicName - Name of the network interface
 * @param {string} netType - Type of network (bri-tap/dpdk-vpp)
 * @param {string} netName - Name of the network to attach to
 * @description Validates and adds a new network interface to the system
 */
function system_netdev_add(systemName, nicName, netType, netName){
	
	systemData = dbnew_system_get(systemName);
	
	var valid = 1;
	
	if(nicName == ""){ nicName = "eth0"; };
	
	var nics = systemData.net.dev;
	nic_index = nics.split(';');
	
	nic_index.forEach((nicdev) => {
		if(nicName == nicdev){
			valid = 0;
			log_write_json("system_nicdev_add", "failed", "Device with name [" + nicName + "] already exists on system [" + systemName + "]");
		}
	});
	
	if(!string_check_alphanum(nicName)){
		valid = 0;
		log_write_json("system_nicdev_add", "failed", "Device name [" + nicName + "] contains invalid characters");
	}
	
	if(nicName.length > 16){
		valid = 0;
		log_write_json("system_nicdev_add", "failed", "Device name [" + nicName + "] too long (>16)");
	}	
	
	if(valid){
		var network = dbnew_network_get(netName);
		
		niccfg = {};
		
		niccfg.net = {};
		niccfg.net['name'] = network.id.name;
		niccfg.net['id'] = network.id.id;
		niccfg.net['type'] = netType;
		
		niccfg.driver = "virtio-net";
		niccfg.ip = "unknown"
		niccfg.mac = generate_mac();
		
		// add config
		systemData.net[nicName] = niccfg;
		
		if(systemData.net.dev == ""){
			systemData.net.dev = nicName;
		}
		else{
			systemData.net.dev += ";" + nicName;
		}
		
		systemData.object['unsaved'] = 1;
		
		dbnew_system_set(systemName, systemData);

		system_network_device_add(nicName, systemData);
		
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Successfully added nic [" + nicName + "] on [<b>" + systemName + "</b>]");
	}
	else{
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Failed to add nic [" + nicName + "] on [<b>" + systemName + "</b>]. Check logs.");
	}
	
}

/**
 * Removes a storage device from a system
 * @param {string} systemName - Name of the system
 * @param {string} storName - Name of the storage device to remove
 * @description Handles storage device removal including boot device checks
 */
function system_stordev_del(systemName, storName){
	
	var systemData = dbnew_system_get(systemName);
	
	if(systemData.stor.boot == storName){
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Cannot remove boot device [" + storName + "] on [<b>" + systemName + "</b>]. Check logs.");
		log_write_json("system_stordev_del", "failed", "Device name [" + storName + "] is designated boot device on system [" + systemName + "]. Select a different boot device and try again.");
	}
	else{
		
		var stor = systemData.stor.disk;
		stor_index = stor.split(';');
		new_dev_index = "";
	
		// rebuild index
		stor_index.forEach((stordev) => {
			if(storName !== stordev){
				
				if(new_dev_index == ""){
					new_dev_index = stordev;
				}
				else{
					new_dev_index += ";" + stordev;
				}
			}
		});
		
		var stor = systemData.stor.iso;
		stor_index = stor.split(';');
		new_iso_index = "";
	
		// rebuild index
		stor_index.forEach((stordev) => {
			if(storName !== stordev){
				
				if(new_iso_index == ""){
					new_iso_index = stordev;
				}
				else{
					new_iso_index += ";" + stordev;
				}
			}
		});
		
		systemData.stor.disk = new_dev_index;
		systemData.stor.iso = new_iso_index;
		
		delete systemData.stor[storName];
		
		dbnew_system_set(systemName, systemData);
		
		system_show(systemName);
	}
	
}

/**
 * Adds a storage device to a system
 * @param {string} systemName - Name of the system
 * @param {string} storName - Name of the storage device
 * @param {string} storPool - Storage pool to use
 * @param {number} storSize - Size of storage in GB
 * @description Validates and adds new storage device to the system
 */
function system_stordev_add(systemName, storName, storPool, storSize){

	var systemData = dbnew_system_get(systemName);
	
	var valid = 1;
	
	if(storName == ""){ storName = "sda"; };
	if(storSize == ""){ storSize = 10; };
	
	var stor = systemData.stor.disk;
	stor_index = stor.split(';');
	
	// storage devices
	stor_index.forEach((stordev) => {
		if(storName == stordev){
			valid = 0;
			log_write_json("system_stordev_add", "failed", "Device with name [" + storName + "] already exists on system [" + systemName + "]");
		}
	});
	
	// only letters and numbers
	if(!string_check_alphanum(storName)){
		valid = 0;
		log_write_json("system_stordev_add", "failed", "Device name [" + storName + "] contains invalid characters");
	}
	
	if(storName.length > 16){
		valid = 0;
		log_write_json("system_stordev_add", "failed", "Device name [" + storName + "] too long (>16)");
	}
	
	if(!string_check_num(storSize)){
		valid = 0;
		log_write_json("system_stordev_add", "failed", "Device size [" + storSize + "] not integer");
	}

	if(storSize == 0 || storSize > 1000 || storSize < 0){
		valid = 0;
		log_write_json("system_stordev_add", "failed", "Device size [" + storSize + "] invalid");
	}
	
	if(storName == "iso" || storName == "disk" || storName == "index" || storName == "boot"){
		valid = 0;
		log_write_json("system_isodev_add", "failed", "Device name [" + isoDevName + "] invalid");
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Device name [" + isoDevName + "] invalid");
	}
	
	if(valid){
		
		// get pool
		var poolData = dbnew_storage_get(storPool);
				
		// 
		if(typeof poolData.id.name !== 'undefined'){
			toast_show("SYSTEM | Storage", "bi-activity", "API", "Device [" + storName + "] added successfully to [<b>" + systemName + "</b>]");
			
			// size too
			var storcfg = {};
			
			// pool
			storcfg.pool = {};
			storcfg.pool['id'] = poolData.id.id;
			storcfg.pool['name'] = poolData.id.name;
			storcfg.pool['type'] = poolData.object.class;
			
			storcfg['driver'] = "virtio";
			storcfg['type'] = "qcow2";
			storcfg['backing'] = "pool";
			storcfg['media'] = "disk";
			storcfg['cache'] = "writeback";
			
			storcfg['size'] = storSize;
			storcfg['image'] = systemName + "." + storName + ".qcow2";
			
			storcfg['dev'] = poolData.pool.path + systemData.id.group + "/" + systemData.id.name + "/";
			
			log_write_json("system_stordev_add", "data", storcfg);
			
			
			// add config
			systemData.stor[storName] = storcfg;
			
			if(systemData.stor.disk == ""){
				systemData.stor.disk = storName;
			}
			else{
				systemData.stor.disk += ";" + storName;
			}
			
			systemData.object['unsaved'] = 1;
			
			dbnew_system_set(systemName, systemData);
			system_show(systemName);
			
		}
		else{
			toast_show("SYSTEM | Storage", "bi-activity", "API", "Device [" + storName + "] on [<b>" + systemName + "</b>] failed to fetch storage pool");
		}
		
	}
	else{
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Failed to add device [" + storName + "] on [<b>" + systemName + "</b>]. Check logs.");
	}
	
}

/**
 * Adds an ISO device to a system
 * @param {string} systemName - Name of the system
 * @param {string} isoDevName - Name of the ISO device
 * @param {string} isoName - Name of the ISO image to attach
 * @description Validates and adds new ISO device to the system
 */
function system_isodev_add(systemName, isoDevName, isoName){
	
	var systemData = dbnew_system_get(systemName);
	
	var valid = 1;
	
	if(isoDevName == ""){ storDevName = "dvd"; };
	
	var iso = systemData.stor.iso;
	iso_index = iso.split(';');
	
	// storage devices
	iso_index.forEach((isoDev) => {
		if(isoDevName == isoDev){
			valid = 0;
			log_write_json("system_isodev_add", "failed", "Device with name [" + isoDevName + "] already exists on system [" + systemName + "]");
			toast_show("SYSTEM | Storage", "bi-activity", "API", "Device with name [" + isoDevName + "] on [<b>" + systemName + "</b>] already exists");
		}
	});
	
	// only letters and numbers
	if(!string_check_alphanum(isoDevName)){
		valid = 0;
		log_write_json("system_isodev_add", "failed", "Device name [" + isoDevName + "] contains invalid characters");
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Device name [" + isoDevName + "] contains invalid characters");
	}
	
	if(isoDevName.length > 16){
		valid = 0;
		log_write_json("system_isodev_add", "failed", "Device name [" + isoDevName + "] too long (>16)");
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Device name [" + isoDevName + "] too long");
	}

	if(isoDevName == "iso" || isoDevName == "disk" || isoDevName == "index" || isoDevName == "boot"){
		valid = 0;
		log_write_json("system_isodev_add", "failed", "Device name [" + isoDevName + "] invalid");
		toast_show("SYSTEM | Storage", "bi-activity", "API", "Device name [" + isoDevName + "] invalid");
	}
	
	
	if(valid){
		
		// get pool
		var isodata = dbnew_storage_get(isoName);
				
		// 
		if(typeof isodata !== 'undefined'){
			toast_show("SYSTEM | Storage", "bi-activity", "API", "ISO device [" + isoDevName + "] added successfully to [<b>" + systemName + "</b>]");
			
			// size too
			var isocfg = {};
			
			isocfg.name = isodata.id.name;
			isocfg.desc = isodata.id.desc;
			
			isocfg.dev = isodata.iso.dev;
			isocfg.image = isodata.iso.image;
			
			// add config
			systemData.stor[isoDevName] = isocfg;
			
			if(systemData.stor.iso == ""){
				systemData.stor.iso = isoDevName;
			}
			else{
				systemData.stor.iso += ";" + isoDevName;
			}
			
			systemData.object['unsaved'] = 1;
			
			dbnew_system_set(systemName, systemData);
			system_show(systemName);
			
		}
		else{
			toast_show("SYSTEM | Storage", "bi-activity", "API", "ISO [" + isoDevName + "] on [<b>" + systemName + "</b>] failed to fetch storage pool");
		}
		
	}
	else{
		//toast_show("SYSTEM | Storage", "bi-activity", "API", "Failed to add device [" + isoDevName + "] on [<b>" + systemName + "</b>]. Check logs.");
	}
	
}

/**
 * Enumerates available boot options for a system
 * @param {Object} system - System object
 * @returns {string} - Semicolon-separated list of boot devices
 * @description Gathers all storage and ISO devices that can be booted from
 */
function system_bootopts_enumerate(system){

	var bootopts = "";

	// devices
	var stor = system.stor.disk;
	stor_index = stor.split(';');
	
	stor_index.forEach((stordev) => {
		if(bootopts == ""){
			bootopts = stordev;
		}
		else{
			bootopts += ";" + stordev;
		}
	});
	
	// iso
	if(system.stor.iso !== ""){	
		var iso = system.stor.iso;
		iso_index = iso.split(';');

		iso_index.forEach((isodev) => {
			if(bootopts == ""){
				bootopts = isodev;
			}
			else{
				bootopts += ";" + isodev;
			}
		});
	}	
	
	return bootopts;
}

/**
 * Updates storage pool path for a device
 * @param {string} systemName - Name of the system
 * @param {string} stordev - Storage device name
 * @param {string} poolName - Name of the storage pool
 * @description Updates the path configuration when storage pool changes
 */
function system_stor_pool_path_update(systemName, stordev, poolName){
	
	var pooldata = dbnew_storage_get(poolName);
	
	log_write_json("system_save", "pooldata", pooldata);
		
	if(string_check_alphanum(document.getElementById("main-system-group").value)){
		var group = document.getElementById("main-system-group").value;
		
		if((typeof pooldata !== 'undefined')){
			var path = pooldata.pool.path + group + "/" + systemName + "/";
			document.getElementById("sysDiskPath_" + systemName + stordev).value = path;
		}
		else{
			toast_show("SYSTEM | Error", "bi-activity", "API", "Pool data for pool [" + poolName + "] is invalid!");
			valid = 0;
		}
		
	}
	else{
		toast_show("SYSTEM | Error", "bi-activity", "API", "System group name [" + document.getElementById("main-system-group").value + "] is invalid!");
		valid = 0;
	}	
	
}

/**
 * Creates a storage usage bar for system views
 * @param {string} barname - Name to display for the bar
 * @param {string} barid - Unique ID for the bar element
 * @param {number} usedPerc - Percentage used (0-100)
 * @returns {HTMLElement} - The created progress bar element
 * @description Generates a visual progress bar for storage usage
 */
function system_storage_bar_add(barname, barid, usedPerc){

	var storbar = document.createElement("div");
	storbar.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2 me-2");
	
	var colOne = document.createElement("div");
	colOne.setAttribute("class", "col-lg-4 rounded-3 p-2 col-md-offset-2");
	colOne.innerHTML += "[<b> " + barname + " </b>]";
	
	storbar.appendChild(colOne);
	
	var sizebardiv = document.createElement("div");
	sizebardiv.setAttribute("class", "progress");
	
	var sizebar = document.createElement("div");
	sizebar.setAttribute("id", "sizebar_" + barid + barname);
	sizebar.setAttribute("class", "progress-bar");
	sizebar.setAttribute("role", "progressbar");
	sizebar.setAttribute("aria-valuenow", usedPerc);
	sizebar.setAttribute("aria-valuemin", 0);
	sizebar.setAttribute("aria-valuemax", 100);
	
	sizebar.setAttribute("style", "width:" + usedPerc + "%");
	sizebar.innerHTML = usedPerc + "%";
	
	sizebardiv.appendChild(sizebar);
	
	storbar.appendChild(sizebardiv);

	return storbar;	
}

/**
 * Generates a random MAC address for a network interface
 * @param {string} systemName - Name of the system
 * @param {string} netDev - Network device name
 * @description Creates and populates a random MAC address for the interface
 */
function system_network_gen_mac(systemName, netDev){
	
	var sysNicMac = document.getElementById("sysNetMac" + systemName + netDev);
	
	var mac = generate_mac()
	
	sysNicMac.setAttribute("placeholder", mac);
	sysNicMac.value = mac;
}

/**
 * Handles network type changes for an interface
 * @param {string} systemName - Name of the system
 * @param {string} netDev - Network device name
 * @description Updates available networks when interface type changes
 */
function system_network_type_change_new(systemName, netDev){
	
	var netType = document.getElementById("sysNetTypeSel" + systemName + netDev).value;
	
	var netNameSelect = document.getElementById("sysNetSel" + systemName + netDev);
	netNameSelect.innerHTML = "";
	netNameSelect = network_select_enumerate_new(netType, netNameSelect);
		
}

/**
 * Handles network selection changes for an interface
 * @param {string} systemName - Name of the system
 * @param {string} netDev - Network device name
 * @description Updates interface details when network selection changes
 */
function system_network_net_change(systemName, netDev){
	var netName = document.getElementById("sysNetSel" + systemName + netDev).value;
	var network = dbnew_network_get(netName);
	
	if((typeof network !== 'undefined') && (typeof network.id.name !== 'undefined')){
		var isDHCP = document.getElementById("sysNetIsDHCP" + systemName + netDev);
		if(network.addr.dhcp == "1"){ isDHCP.innerHTML = '<b style="color:#24be14">DHCP</b>'; }
		else{ isDHCP.innerHTML = '<b style="color:#ebeb4">STATIC</b>'; };
		
		var netAddr = document.getElementById("sysNetNetAddr" + systemName + netDev);
		
		if(typeof network.addr !== 'undefined'){ netAddr.innerHTML = network.addr.ip + "/24"; }
		else{ netAddr.innerHTML = '<b style="color:#ebeb4">0.0.0.0</b>'; };
	}
	
}

/**
 * Enumerates available networks by type
 * @param {string} model - Network model type (bri-tap/dpdk-vpp)
 * @returns {string} - Semicolon-separated list of network names
 * @description Gets all networks of the specified type
 */
function network_option_enumerate_new(model){

	if(model == "bri-tap"){
		return dbnew_network_tuntap_index_get();
	}

	if(model == "dpdk-vpp"){
		return dbnew_network_vpp_index_get();
	}

}

/**
 * Populates a select element with available networks
 * @param {string} model - Network model type (bri-tap/dpdk-vpp)
 * @param {HTMLSelectElement} netSelect - Select element to populate
 * @returns {HTMLSelectElement} - The populated select element
 * @description Fills a dropdown with networks of the specified type
 */
function network_select_enumerate_new(model, netSelect){

	var netList;

	if(model == "bri-tap"){
		netList = dbnew_network_tuntap_index_get();
	}
	
	if(model == "dpdk-vpp"){
		netList = dbnew_network_vpp_index_get();
	}

	netlist = sort_alpha(netList);
	
	netList.forEach((netName) => {
		
		var netOpt = document.createElement('option');
		netOpt.value = netName;
		netOpt.innerHTML = netName;
		netSelect.appendChild(netOpt);
		
		
	});

	return netSelect;
}

/**
 * Clears the online systems menu
 * @description Removes all items from the online systems accordion
 */
function system_menu_remove_online() {
	document.getElementById("collapse-system-online").innerHTML = "";
}

/**
 * Clears the offline systems menu
 * @description Removes all items from the offline systems accordion
 */
function system_menu_remove_offline() {
	document.getElementById("collapse-system-offline").innerHTML = "";
}


/**
 * Clears the template systems menu
 * @description Removes all items from the template systems accordion
 */
function system_menu_remove_template() {
	document.getElementById("collapse-system-template").innerHTML = "";
}


/**
 * Adds a system to the online menu
 * @param {string} systemName - Name of the system to add
 * @description Creates a menu item linking to the system view
 */
function system_menu_add_online(systemName) {
	const func = function() { system_show(systemName) };
	menu_add_item(systemName, 'collapse-system-online', "sys_" + systemName, "bi-display", func);
}

/**
 * Adds a system to the offline menu
 * @param {string} systemName - Name of the system to add
 * @description Creates a menu item linking to the system view
 */
function system_menu_add_offline(systemName) {
	const func = function() { system_show(systemName) };
	menu_add_item(systemName, 'collapse-system-offline', "sys_" + systemName, "bi-display", func);
}

/**
 * Adds a system to the template menu
 * @param {string} systemName - Name of the system to add
 * @description Creates a menu item linking to the system view
 */
function system_menu_add_template(systemName) {
	const func = function() { system_show(systemName) };
	menu_add_item(systemName, 'collapse-system-template', "sys_" + systemName, "bi-display", func);
}

/**
 * Adds a node option to the system load dropdown
 * @param {string} systemName - Name of the system
 * @param {string} nodeName - Name of the node
 * @description Creates a dropdown item for loading system on node
 */
function node_system_load_add(systemName, nodeName) {

	var ul = document.getElementById('main-system-btn-load-dropdown');
	
	var li = document.createElement("li");
	li.setAttribute("id", "node_power_" + nodeName);
	li.className = "btn btn-sm btn-outline-secondary w-100";
	
	// icon
	var span = document.createElement("i");
	span.setAttribute("class", "system-load-btn bi bi-view-stacked");
	
	var but = document.createElement("button");
	but.setAttribute("id", "node_power_" + nodeName);
	but.className = "btn btn-sm";
	but.appendChild(span);
	but.innerHTML += nodeName;
	but.value = "test";
	but.id = "test";
	but.onclick = function() { system_load_accept(systemName, nodeName) };  
	
	// build
	li.appendChild(but);
	ul.appendChild(li);
}

/**
 * Enumerates available ISO images
 * @param {HTMLSelectElement} isoSelect - Select element to populate
 * @returns {HTMLSelectElement} - The populated select element
 * @description Fills a dropdown with available ISO images
 */
function system_storage_iso_enumerate(isoSelect){
	var isoList = dbnew_storage_index_iso_get();

	isolist.forEach((iso) => {
		log_write_json("storage_iso_enum", iso, iso);
		
		var isoOpt = document.createElement('option');
		isoOpt.value = iso;
		isoOpt.innerHTML = iso;
		isoSelect.appendChild(isoOpt);
	});	
	
	return isoSelect;
}

/**
 * Shows shutdown confirmation modal
 * @param {string} systemName - Name of the system
 * @description Displays confirmation dialog for system shutdown
 */
function system_shutdown_accept(systemName){
	
	document.getElementById("mainModalLabel").innerHTML = "System Shutdown";
	document.getElementById("mainModalBody").innerHTML = "Are you sure you want to initiate shutdown for system [<b> " + systemName + " </b>]?";
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-power"); 
	document.getElementById("mainModalBtnAccept").innerHTML = "Shutdown";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		system_rest_shutdown(systemName);
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows reset confirmation modal
 * @param {string} systemName - Name of the system
 * @description Displays confirmation dialog for system reset
 */
function system_reset_accept(systemName){
	
	document.getElementById("mainModalLabel").innerHTML = "System Reset";
	document.getElementById("mainModalBody").innerHTML = "Are you sure you want to initiate a system reset for [<b> " + systemName + " </b>]?";
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-arrow-counterclockwise");
	document.getElementById("mainModalBtnAccept").innerHTML = "Reset";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		system_rest_reset(systemName);
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows unload confirmation modal
 * @param {string} systemName - Name of the system
 * @description Displays confirmation dialog for system unload
 */
function system_unload_accept(systemName){
	
	document.getElementById("mainModalLabel").innerHTML = "System Poweroff";
	document.getElementById("mainModalBody").innerHTML = "Are you sure you want to initiate poweroff for system [<b> " + systemName + " </b>]?";
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-power");
	document.getElementById("mainModalBtnAccept").innerHTML = "Poweroff";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		//system_hyper_unload(systemName);
		system_rest_unload(systemName);
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows clone configuration modal
 * @param {string} systemName - Name of the source system
 * @param {string} group - System group name
 * @description Displays dialog for configuring system clone
 */
function system_clone_config_accept(systemName, group){
	
	var divCloneName = view_textbox_build("clone_cfg_input_name_" + systemName, "System Name", systemName + "-clone");
	var divCloneId = view_textbox_build("clone_cfg_input_uid_" + systemName, "System UID", "1000");
	var divCloneGroup = view_textbox_build("clone_cfg_input_group_" + systemName, "System Group", group);
	
	var poolList = dbnew_storage_index_pool_get();
	
	var divClonePool = view_selector_build_array("sysStorPoolCloneCfg" + systemName, "Storage Pool", poolList, "original");
	
	document.getElementById("mainModalLabel").innerHTML = "Clone System Configuration";
	document.getElementById("mainModalBody").innerHTML = "Source system for cloning is [<b> " + systemName + " </b>]</br>Configure <b>name</b> and <b>UID</b> for the destination system:";
	document.getElementById("mainModalBody").appendChild(divCloneName);
	document.getElementById("mainModalBody").appendChild(divCloneId);
	document.getElementById("mainModalBody").appendChild(divCloneGroup);
	document.getElementById("mainModalBody").appendChild(divClonePool);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-files");
	document.getElementById("mainModalBtnAccept").innerHTML = "Clone";
	
	document.getElementById("mainModalBtnAccept").onclick = function() { 

		var destid = document.getElementById("clone_cfg_input_uid_" + systemName).value;
		var destname = document.getElementById("clone_cfg_input_name_" + systemName).value;
		var groupname = document.getElementById("clone_cfg_input_group_" + systemName).value;
		var poolName = document.getElementById("sysStorPoolCloneCfg" + systemName).value;
		
		// get pool id
		var pooldata = dbnew_storage_get(poolName);
		log_write_json("system_clone_config_accept", "pooldata", pooldata);
		log_write_json("system_clone", "top", "dest uid [" + destid + "] name [" + destname + "] group [" + groupname + "] pool [" + poolName + "]");
		system_rest_clone_config(systemName, destname, destid, groupname, poolName);
		
		$('#mainModal').modal('hide');		
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows full clone confirmation modal
 * @param {string} systemName - Name of the source system
 * @param {string} groupname - System group name
 * @description Displays dialog for full system clone
 */
function system_clone_full_accept(systemName, groupname){
	
	//
	var divCloneName = view_textbox_build("clone_input_name_" + systemName, "System Name", systemName + "-clone");
	var divCloneId = view_textbox_build("clone_input_uid_" + systemName, "System UID", "1000");
	var divCloneGroup = view_textbox_build("clone_input_group_" + systemName, "System Group", groupname);

	var poolList = dbnew_storage_index_pool_get();
	var divClonePool = view_selector_build_array("sysStorPoolCloneFull" + systemName, "Storage Pool", poolList, "");
	
	var nodeList = dbnew_node_index_online_get();
	
	var divCloneNode = view_selector_build_array("clone_input_node_" + systemName, "Select Node", nodeList, "");
	
	document.getElementById("mainModalLabel").innerHTML = "Clone System";
	document.getElementById("mainModalBody").innerHTML = "Source system for cloning is [<b> " + systemName + " </b>]</br>Configure <b>name</b> and <b>UID</b> for the destination system.<br>Select the node to be used for the cloning process.";
	document.getElementById("mainModalBody").appendChild(divCloneName);
	document.getElementById("mainModalBody").appendChild(divCloneId);
	document.getElementById("mainModalBody").appendChild(divCloneGroup);
	document.getElementById("mainModalBody").appendChild(divClonePool);
	document.getElementById("mainModalBody").appendChild(divCloneNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-plus-square");
	document.getElementById("mainModalBtnAccept").innerHTML = "Clone";
	
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var destid = document.getElementById("clone_input_uid_" + systemName).value;
		var destname = document.getElementById("clone_input_name_" + systemName).value;
		var node = document.getElementById("clone_input_node_" + systemName).value;
		var group = document.getElementById("clone_input_group_" + systemName).value;
		var pool = document.getElementById("sysStorPoolCloneFull" + systemName).value;
		
		log_write_json("system_clone_full", "top", "dest uid [" + destid + "] name [" + destname + "] node [" + node + "] group [" + group + "] pool [" + pool + "]");
		system_rest_clone_full(systemName, destname, destid, node, group, pool);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows system creation modal
 * @param {string} systemName - Name of the system to create
 * @description Displays dialog for system creation
 */
function system_create_full_accept(systemName){
		
	// build a div
	var divNode = document.createElement("div");
	divNode.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var nodeList = dbnew_node_index_online_get();
	var divNodeSel = view_selector_build_array("create_input_node_" + systemName, "Select Node", nodeList, "");
	
	divNode.appendChild(divNodeSel);
		
	document.getElementById("mainModalLabel").innerHTML = "Create System";
	document.getElementById("mainModalBody").innerHTML = "System to create is [<b> " + systemName + " </b>]<br>Select the node to be used for the creation process.";
	document.getElementById("mainModalBody").appendChild(divNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-check-square");
	document.getElementById("mainModalBtnAccept").innerHTML = "Create";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var node = document.getElementById("create_input_node_" + systemName).value;
		
		log_write_json("system_create_full", "top", "host node [" + node + "]");
		system_rest_create_full(systemName, node);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows system move modal
 * @param {Object} system - System object to move
 * @description Displays dialog for moving system to new node/pool
 */
function system_move_full_accept(system){
	
	var systemName = system.id.name;
	
	// name
	var divCloneName = view_textbox_build("move_input_name_" + systemName, "System Name", systemName);

	// id
	var divCloneId = view_textbox_build("move_input_uid_" + systemName, "System UID", system.id.id);

	// group
	var divCloneGroup = view_textbox_build("move_input_group_" + systemName, "System Group", system.id.group);

	// devices
	var stor = system.stor.disk;
	stor_index = stor.split(';');
	
	var bootpool = "";
	
	stor_index.forEach((stordev) => {
		bootpool = system.stor[stordev].pool.name;
	});

	// pool
	var poolList = dbnew_storage_index_pool_get();
	var divClonePool = view_selector_build_array("sysStorPoolMoveFull" + systemName, "Storage Pool", poolList, bootpool);

	var nodeList = dbnew_node_index_online_get();
	var divCloneNode = view_selector_build_array("move_input_node_" + systemName, "Select Node", nodeList, "");
	
	document.getElementById("mainModalLabel").innerHTML = "Move System";
	document.getElementById("mainModalBody").innerHTML = "Move system [<b> " + systemName + " </b>]</br>Configure <b>name</b> and <b>UID</b> for the destination system.<br>Select the node to be used for the cloning process.";
	document.getElementById("mainModalBody").appendChild(divCloneName);
	document.getElementById("mainModalBody").appendChild(divCloneId);
	document.getElementById("mainModalBody").appendChild(divCloneGroup);
	document.getElementById("mainModalBody").appendChild(divClonePool);
	document.getElementById("mainModalBody").appendChild(divCloneNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-plus-square");
	document.getElementById("mainModalBtnAccept").innerHTML = "Move";
	
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var destid = document.getElementById("move_input_uid_" + systemName).value;
		var destname = document.getElementById("move_input_name_" + systemName).value;
		var node = document.getElementById("move_input_node_" + systemName).value;
		var group = document.getElementById("move_input_group_" + systemName).value;
		var pool = document.getElementById("sysStorPoolMoveFull" + systemName).value;
		
		log_write_json("system_clone_full", "top", "dest uid [" + destid + "] name [" + destname + "] node [" + node + "] group [" + group + "] pool [" + pool + "]");
		system_rest_move_full(systemName, destname, destid, node, group, pool);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows live migration modal
 * @param {Object} system - System object to migrate
 * @description Displays dialog for live system migration
 */
function system_migrate_accept(system){
	
	var systemName = system.id.name;
	
	var divMigrateName = view_textbox_build("migrate_input_name_" + systemName, "System Name", systemName);
	var divMigrateId = view_textbox_build("migrate_input_uid_" + systemName, "System UID", system.id.id);
	var divMigrateSrcNode = view_textbox_build("migrate_input_source_" + systemName, "Source Node", system.meta.node_name);

	var nodeList = dbnew_node_index_online_get();
	var divMigrateDestNode = view_selector_build_array("migrate_input_dest_" + systemName, "Destination Node", nodeList, "");

	document.getElementById("mainModalLabel").innerHTML = "Live Migrate System";
	document.getElementById("mainModalBody").innerHTML = "Migrate system [<b> " + systemName + " </b>]<br>Select the destination node";
	document.getElementById("mainModalBody").appendChild(divMigrateName);
	document.getElementById("mainModalBody").appendChild(divMigrateId);
	document.getElementById("mainModalBody").appendChild(divMigrateSrcNode);
	document.getElementById("mainModalBody").appendChild(divMigrateDestNode);
	
	$("#migrate_input_name_" + systemName).prop('disabled', true);
	$("#migrate_input_uid_" + systemName).prop('disabled', true);
	$("#migrate_input_source_" + systemName).prop('disabled', true);
	
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-chevron-double-right");
	document.getElementById("mainModalBtnAccept").innerHTML = "Migrate";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var destNode = document.getElementById("migrate_input_dest_" + systemName).value;
		log_write_json("system_migrate", "top", "system name [" + system.id.name + "] id [" + system.id.id + "] src node [" + system.meta.node_name + "] dest node [" + destNode + "]");
		system_migrate(system.id.name, system.meta.node_name, destNode);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows storage move modal
 * @param {Object} system - System object
 * @param {string} systemName - Name of the system
 * @description Displays dialog for moving system storage
 */
function system_storage_move_accept(system, systemName){
		
	// build a div
	var divNode = document.createElement("div");
	divNode.setAttribute("class", "input-group input-group-sm mb-2 mt-2");

	var nodeList = dbnew_node_index_online_get();
	var divNodeSel = view_selector_build_array("move_input_node_" + systemName, "Select Node", nodeList, "");
	
	divNode.appendChild(divNodeSel);
	
	var poolList = dbnew_storage_index_pool_get();
	var divStorPool = view_selector_build("sysStorPool" + systemName, "Storage Pool", poolList, "");
	
	document.getElementById("mainModalLabel").innerHTML = "Move System Storage";
	document.getElementById("mainModalBody").innerHTML = "System to move is [<b> " + systemName + " </b>]<br>Select the node to be used for the move process.<br>Select destination storage pool";
	document.getElementById("mainModalBody").appendChild(divNode);
	document.getElementById("mainModalBody").appendChild(divStorPool);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-box-arrow-in-right");
	document.getElementById("mainModalBtnAccept").innerHTML = "Move Storage";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var node = document.getElementById("move_input_node_" + systemName).value;
		var pool = document.getElementById("sysStorPool" + systemName).value;
		
		log_write_json("system_move_full", "top", "dest uid [" + system.id.id + "] name [" + system.id.name + "] node [" + node + "] group [" + system.id.group + "] pool [" + pool + "]");
		system_rest_move_full(systemName, destname, destid, node, group, pool);

		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows storage move modal
 * @param {Object} system - System object
 * @param {string} systemName - Name of the system
 * @description Displays dialog for moving system storage
 */
function system_load_accept(system, systemName){
		
	// build a div
	var divNode = document.createElement("div");
	divNode.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var nodeList = dbnew_node_index_online_get();
	var divNodeSel = view_selector_build_array("load_input_node_" + systemName, "Select Node", nodeList, "");
	
	divNode.appendChild(divNodeSel);
	
	document.getElementById("mainModalLabel").innerHTML = "Load System";
	document.getElementById("mainModalBody").innerHTML = "System [<b> " + systemName + " </b>]<br>Select the node load the system";
	document.getElementById("mainModalBody").appendChild(divNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-box-arrow-in-right");
	document.getElementById("mainModalBtnAccept").innerHTML = "Load System";
	document.getElementById("mainModalBtnAccept").onclick = function() {
		
		var nodeName = document.getElementById("load_input_node_" + systemName).value;
		console.log("system load. system [" + system.id.name + "] node [" + nodeName + "]");
		
		log_write_json("system_load", "top", "dest uid [" + system.id.id + "] name [" + system.id.name + "] node [" + nodeName + "]");
		system_rest_load(system.id.name, nodeName);

		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows storage device removal modal
 * @param {string} systemName - Name of the system
 * @description Displays dialog for removing storage device
 */
function system_stordev_remove_accept(systemName){
	
	var divNode = document.createElement("div");
	divNode.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var systemData = dbnew_system_get(systemName);
	var devices = system_bootopts_enumerate(systemData);
	
	var divNodeSel = view_selector_build("sys_dev_remove_" + systemName, "Remove Device", devices, "");
	
	divNode.appendChild(divNodeSel);
	
	document.getElementById("mainModalLabel").innerHTML = "Remove System Storage";
	document.getElementById("mainModalBody").innerHTML = "System [<b> " + systemName + " </b>]<br>Select the device to remove:";
	document.getElementById("mainModalBody").appendChild(divNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-x-square");
	document.getElementById("mainModalBtnAccept").innerHTML = "Remove Device";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var device = document.getElementById("sys_dev_remove_" + systemName).value;
		
		log_write_json("system_device_remove", "top", "device [" + device + "]");
		system_stordev_del(systemName, device);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows storage device add modal
 * @param {string} systemName - Name of the system
 * @param {Object} system - System object
 * @description Displays dialog for adding storage device
 */
function system_stordev_add_accept(systemName, system){
	
	// build a div
	var div = document.createElement("div");
	div.setAttribute("class", "input-group input-group-sm mb-2 mt-3");
	
	var divStorName = view_textbox_build("sysStorName" + systemName, "Device Name", "sda");
	
	var divStorSize = view_textbox_build("sysStorSize" + systemName, "Device Size", "10");
	var span2 = document.createElement("span");
	span2.setAttribute("class", "input-group-text");
	span2.innerHTML = "GiB";
	divStorSize.appendChild(span2);
	
	var poolList = dbnew_storage_index_pool_get();
	var divStorPool = view_selector_build_array("sysStorPool" + systemName, "Storage Pool", poolList, "");
	
	div.appendChild(divStorName);
	div.appendChild(divStorSize);
	div.appendChild(divStorPool);
	
	document.getElementById("mainModalLabel").innerHTML = "Add Storage Device";
	document.getElementById("mainModalBody").innerHTML = "Configure storage device on system [<b> " + systemName + " </b>]</br>";
	document.getElementById("mainModalBody").appendChild(div);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-hdd");
	document.getElementById("mainModalBtnAccept").innerHTML = "Create";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var storname = document.getElementById("sysStorName" + systemName).value;
		var storpool = document.getElementById("sysStorPool" + systemName).value;
		var storsize = document.getElementById("sysStorSize" + systemName).value;
		log_write_json("system_add_stordev", "top", "device name [" + storname + "] pool [" + storpool + "] size [" + storsize + "]");
		system_stordev_add(systemName, storname, storpool, storsize);
		
		$('#mainModal').modal('hide');
		
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows storage device creation modal
 * @param {Object} system - System object
 * @param {string} systemName - Name of the system
 * @description Displays dialog for creating storage device
 */
function system_stordev_create_accept(system, systemName){
	
	// build a div
	var divNode = document.createElement("div");
	divNode.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var nodeList = dbnew_node_index_online_get();
	var divNodeSel = view_selector_build_array("create_input_node_" + systemName, "Select Node", nodeList, "");
	
	divNode.appendChild(divNodeSel);
	
	var systemData = dbnew_system_get(systemName);
	var devices = system_bootopts_enumerate(systemData);
	
	var divDevSel = view_selector_build("sys_dev_create_" + systemName, "Create Device", devices, "");
	
	divNode.appendChild(divDevSel);
	
	document.getElementById("mainModalLabel").innerHTML = "Create System Storage";
	document.getElementById("mainModalBody").innerHTML = "System [<b> " + systemName + " </b>]<br>Select the device to create, and node to execute the operation";
	document.getElementById("mainModalBody").appendChild(divNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-x-square");
	document.getElementById("mainModalBtnAccept").innerHTML = "Create Device";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var device = document.getElementById("sys_dev_create_" + systemName).value;
		var node = document.getElementById("create_input_node_" + systemName).value;
		
		log_write_json("system_device_create", "top", "system [" + systemName + "] device [" + device + "] node [" + node + "]");
		system_async_stordev_create(systemName, device, node);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows ISO device add modal
 * @param {string} systemName - Name of the system
 * @description Displays dialog for adding ISO device
 */
function system_storiso_add_accept(systemName){
	
	var div = document.createElement("div");
	div.setAttribute("class", "input-group input-group-sm mb-2 mt-3");
	
	var divIsoName = view_textbox_build("sysIsoNameWiz_" + systemName, "ISO Name", "dvd");
	div.appendChild(divIsoName);
	
	var isoList = dbnew_storage_index_iso_get();
	var divIsoSel = view_selector_build_array("sysIsoSelWiz_" + systemName, "ISO", isoList, "");

	div.appendChild(divIsoName);
	div.appendChild(divIsoSel);
	
	document.getElementById("mainModalLabel").innerHTML = "Add ISO Device";
	document.getElementById("mainModalBody").innerHTML = "Add ISO device on system [<b> " + systemName + " </b>]</br>";
	document.getElementById("mainModalBody").appendChild(div);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-vinyl");
	document.getElementById("mainModalBtnAccept").innerHTML = "Add";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var isoname = document.getElementById("sysIsoNameWiz_" + systemName).value;
		var iso = document.getElementById("sysIsoSelWiz_" + systemName).value;
		
		system_isodev_add(systemName, isoname, iso);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows network device add modal
 * @param {string} systemName - Name of the system
 * @description Displays dialog for adding network device
 */
function system_netdev_add_accept(systemName){

	var div = document.createElement("div");
	div.setAttribute("class", "input-group input-group-sm mb-2 mt-3");
	
	var divNicName = view_textbox_build("sysNicNameWiz" + systemName, "Device Name", "eth0");
	div.appendChild(divNicName);
	
	var divNetType = view_selector_build("sysNetTypeWiz" + systemName, "Nework Type", "dpdk-vpp;bri-tap", "bri-tap");
	divNetType.onchange = function() { 
		
		var type = document.getElementById("sysNetTypeWiz" + systemName).value;
		var netNameSelect = document.getElementById("sysNetSelWiz" + systemName);
		netNameSelect.innerHTML = "";
		netNameSelect = network_select_enumerate_new(type, netNameSelect);
		
	};
	div.appendChild(divNetType);
	
	var netList = dbnew_network_tuntap_index_get();
	var divNet = view_selector_build_array("sysNetSelWiz" + systemName, "Network", netList, "");
	div.appendChild(divNet);
	
	document.getElementById("mainModalLabel").innerHTML = "Add Network Device";
	document.getElementById("mainModalBody").innerHTML = "Configure network device on system [<b> " + systemName + " </b>]</br>";
	document.getElementById("mainModalBody").appendChild(div);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-hdd");
	document.getElementById("mainModalBtnAccept").innerHTML = "Create";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var nicname = document.getElementById("sysNicNameWiz" + systemName).value;
		var nettype = document.getElementById("sysNetTypeWiz" + systemName).value;
		var netname = document.getElementById("sysNetSelWiz" + systemName).value;
		log_write_json("system_add_netdev", "top", "device name [" + nicname + "]");
		system_netdev_add(systemName, nicname, nettype, netname);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows network device removal modal
 * @param {string} systemName - Name of the system
 * @description Displays dialog for removing network device
 */
function system_netdev_remove_accept(systemName){
	
	var systemData = dbnew_system_get(systemName);
	
	var div = document.createElement("div");
	div.setAttribute("class", "input-group input-group-sm mb-2 mt-3");
	
	var divNicSel = view_selector_build("sysNicDelWiz_" + systemName, "Select NIC", systemData.net.dev, "");
	
	div.appendChild(divNicSel);	
	
	document.getElementById("mainModalLabel").innerHTML = "Remove Network Device";
	document.getElementById("mainModalBody").innerHTML = "System [<b> " + systemName + " </b>]<br>Select the device to remove:";
	document.getElementById("mainModalBody").appendChild(div);
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-x-square");
	document.getElementById("mainModalBtnAccept").innerHTML = "Remove Device";
	
	document.getElementById("mainModalBtnAccept").onclick = function() { 

		var nic = document.getElementById("sysNicDelWiz_" + systemName).value;
	
		var nics = systemData.net.dev;
		nic_index = nics.split(';');
		
		var new_nic_index = "";
		
		// rebuild index
		nic_index.forEach((nicdev) => {
			if(nic !== nicdev){
				
				if(new_nic_index == ""){
					new_nic_index = nicdev;
				}
				else{
					new_nic_index += ";" + nicdev;
				}
			}
		});
		
		delete systemData.net[nic];
		
		systemData.net.dev = new_nic_index;
		
		dbnew_system_set(systemName, systemData);
		
		system_show(systemName);
		
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
}

/**
 * Shows storage device creation modal
 * @param {Object} system - System object
 * @param {string} systemName - Name of the system
 * @description Displays dialog for creating storage device
 */
function system_delete_accept(systemName){

	// build a div
	var divNode = document.createElement("div");
	divNode.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var nodeList = dbnew_node_index_online_get();
	var divNodeSel = view_selector_build_array("create_input_node_" + systemName, "Select Node", nodeList, "");
	
	divNode.appendChild(divNodeSel);
	
	var systemData = dbnew_system_get(systemName);

	document.getElementById("mainModalLabel").innerHTML = "Delete System";
	document.getElementById("mainModalBody").innerHTML = "System [<b> " + systemName + " </b>]<br>Select the node to execute the operation<br><br><b>** WARNING: THIS OPERATION CANNOT BE UNDONE!! **</b>";
	document.getElementById("mainModalBody").appendChild(divNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-delete-btn bi bi-x-square");
	document.getElementById("mainModalBtnAccept").innerHTML = "Delete System";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var nodeName = document.getElementById("create_input_node_" + systemName).value;
		log_write_json("system_delete", "top", "system [" + systemName + "] node [" + nodeName + "]");
		system_rest_delete(systemName, nodeName);
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows storage device creation modal
 * @param {Object} system - System object
 * @param {string} systemName - Name of the system
 * @description Displays dialog for creating storage device
 */
function system_validate_accept(systemName){

	// build a div
	var divNode = document.createElement("div");
	divNode.setAttribute("class", "input-group input-group-sm mb-2 mt-2");
	
	var nodeList = dbnew_node_index_online_get();
	var divNodeSel = view_selector_build_array("create_input_node_" + systemName, "Select Node", nodeList, "");
	
	divNode.appendChild(divNodeSel);

	var systemData = dbnew_system_get(systemName);

	document.getElementById("mainModalLabel").innerHTML = "Validate System";
	document.getElementById("mainModalBody").innerHTML = "System [<b> " + systemName + " </b>]<br>Select the node to execute the operation";
	document.getElementById("mainModalBody").appendChild(divNode);
	document.getElementById("mainModalIcon").setAttribute("class", "system-validate-btn bi bi-file-earmark-check");
	document.getElementById("mainModalBtnAccept").innerHTML = "Validate System";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		var nodeName = document.getElementById("create_input_node_" + systemName).value;
		log_write_json("system_validate", "top", "system [" + systemName + "] node [" + nodeName + "]");
		system_rest_validate(systemName, nodeName);
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Validates and saves system configuration
 * @param {string} systemName - Name of the system
 * @param {Object} system - System object to save
 * @description Validates all fields and saves system configuration
 */
function system_save_config(systemName, systemData){
	log_write_json("system_save", "save", "system name [" + systemName + "]");
	toast_show("SYSTEM | Save", "bi-activity", "API", "Saving system [<b>" + systemName + "</b>]");
	
	var valid = 1;
	
	//
	// id
	//
	
	// UID
	if(string_check_num(document.getElementById("main-system-uid").value)){
		systemData.id.id = document.getElementById("main-system-uid").value;
	}
	else{
		toast_show("SYSTEM | Error", "bi-activity", "API", "System UID [" + document.getElementById("main-system-uid").value + "] invalid!");
		valid = 0;
	}	
	
	// name
	if(string_check_name(document.getElementById("main-system-name").value)){
		systemData.id.name = document.getElementById("main-system-name").value;
	}
	else{
		toast_show("SYSTEM | Error", "bi-activity", "API", "System name [" + document.getElementById("main-system-name").value + "] is invalid!");
		valid = 0;
	}
	
	// desc
	systemData.id.desc = document.getElementById("main-system-desc").value;
	
	// group
	if(string_check_alphanum(document.getElementById("main-system-group").value)){
		systemData.id.group = document.getElementById("main-system-group").value;
	}
	else{
		toast_show("SYSTEM | Error", "bi-activity", "API", "System group name [" + document.getElementById("main-system-group").value + "] is invalid!");
		valid = 0;
	}
	
	//
	// hardware
	//
	
	// sockets
	if(string_check_num(document.getElementById("main-system-cpu-sock").value) && (parseInt(document.getElementById("main-system-cpu-sock").value) <= 4) && (parseInt(document.getElementById("main-system-cpu-sock").value) > 0)){
		systemData.hw.cpu.sock = document.getElementById("main-system-cpu-sock").value;
	}
	else{
		toast_show("SYSTEM | Error", "bi-activity", "API", "System CPU sockets [" + document.getElementById("main-system-cpu-sock").value + "] is invalid!");
		valid = 0;
	}	

	// cores
	if(string_check_num(document.getElementById("main-system-cpu-core").value) && (parseInt(document.getElementById("main-system-cpu-core").value) <= 16) && (parseInt(document.getElementById("main-system-cpu-core").value) > 0)){
		systemData.hw.cpu.core = document.getElementById("main-system-cpu-core").value;
	}
	else{
		toast_show("SYSTEM | Error", "bi-activity", "API", "System CPU cores [" + document.getElementById("main-system-cpu-core").value + "] is invalid!");
		valid = 0;
	}
	
	// group
	if(string_check_num(document.getElementById("main-system-mem-mb").value) && (parseInt(document.getElementById("main-system-mem-mb").value) <= 131072) && (parseInt(document.getElementById("main-system-mem-mb").value) > 128)){
		systemData.hw.mem.mb = document.getElementById("main-system-mem-mb").value;
	}
	else{
		toast_show("SYSTEM | Error", "bi-activity", "API", "System memory amount [" + document.getElementById("main-system-mem-mb").value + "] is invalid!");
		valid = 0;
	}

	//
	// bios
	//
	if(document.getElementById("main-system-bios-sel").value !== "legacy"){
		
		if(document.getElementById("main-system-bios-model").value == "" || document.getElementById("main-system-bios-model").value == "default"){
			//console.log("UEFI DEFAULT");
			systemData.hw.bios = {};
			systemData.hw.bios.mode = document.getElementById("main-system-bios-sel").value;
			systemData.hw.bios.model = "";
		}
		else{
			//console.log("UEFI NOT DEFAULT!");
			systemData.hw.bios = {};
			systemData.hw.bios.mode = document.getElementById("main-system-bios-sel").value;
			systemData.hw.bios.model = document.getElementById("main-system-bios-model").value;
		}
		
	}
	else{
		systemData.hw.bios = {};
		systemData.hw.bios.mode = "legacy";
		systemData.hw.bios.model = "";
	}


	//
	// storage
	//
	
	// for now just handle boot
	systemData.stor.boot = document.getElementById("sysBootSelect" + systemName).value;
	systemData.hw.cpu.core = document.getElementById("main-system-cpu-core").value;
	
	// cpu model
	if(document.getElementById("main-system-cpu-model").value !== ""){
		systemData.hw.cpu.model = document.getElementById("main-system-cpu-model").value;
	}
	
	// cpu nested
	if(document.getElementById("main-system-cpu-nest").value == 1){
		systemData.hw.cpu.nest = "1";
	}
	else{
		systemData.hw.cpu.nest = "0";
	}
	

	//
	// network
	//
	var nic = systemData.net.dev;
	nic_index = nic.split(';');
	
	// network devices
	nic_index.forEach((nicDev) => {
		
		var netType = document.getElementById("sysNetTypeSel" + systemName + nicDev).value;
		var netName = document.getElementById("sysNetSel" + systemName + nicDev).value;
		
		log_write_json("system_save", "network", "system name [" + systemName + "] nic [" + nicDev + "] network [" + netName + "] type [" + netType + "]");
		
		var network = dbnew_network_get(netName);
		log_write_json("system_save", nicDev, network);
		
		systemData.net[nicDev].net = {};
		
		systemData.net[nicDev].net.id = network.id.id;
		systemData.net[nicDev].net.name = network.id.name;
		systemData.net[nicDev].net.type = netType;
		
		systemData.net[nicDev].mac = document.getElementById("sysNetMac" + systemName + nicDev).value;
		
		systemData.net[nicDev].driver = document.getElementById("sysNetDriverSel" + systemName + nicDev).value;
		
		systemData.net[nicDev].ip = document.getElementById("sysNetIP" + systemName + nicDev).value;
		
		systemData.net[nicDev].desc = document.getElementById("sysNetDesc" + systemName + nicDev).value;
		
		log_write_json("system_save", nicDev, systemData.net);
	});	
	
	//
	// iso
	//
	if(systemData.stor.iso !== ""){
	
		var iso = systemData.stor.iso;
		iso_index = iso.split(';');
		
		// network devices
		iso_index.forEach((isoDev) => {
			
			if(document.getElementById("sysIsoName_" + systemName + isoDev).value !== ""){
				systemData.stor[isoDev].name = document.getElementById("sysIsoName_" + systemName + isoDev).value;
			}
			
			if(document.getElementById("sysIsoDesc_" + systemName + isoDev).value !== ""){
				systemData.stor[isoDev].desc = document.getElementById("sysIsoDesc_" + systemName + isoDev).value;
			}
			
			systemData.stor[isoDev].image = document.getElementById("sysIsoImg_" + systemName + isoDev).value;
			systemData.stor[isoDev].dev = document.getElementById("sysIsoPath_" + systemName + isoDev).value;
			
		})	
	}
	
	//
	// disk
	//
	var disk = systemData.stor.disk;
	disk_index = disk.split(';');
	
	// network devices
	disk_index.forEach((diskDev) => {
		
		if(document.getElementById("sysDiskImage_" + systemName + diskDev).value !== ""){
			systemData.stor[diskDev].image = document.getElementById("sysDiskImage_" + systemName + diskDev).value;
		}
		
		if(document.getElementById("sysDiskPath_" + systemName + diskDev).value !== ""){
			systemData.stor[diskDev].dev = document.getElementById("sysDiskPath_" + systemName + diskDev).value;
		}
		
		if(document.getElementById("sysDiskSize_" + systemName + diskDev).value !== ""){
			systemData.stor[diskDev].size = document.getElementById("sysDiskSize_" + systemName + diskDev).value;
		}
		
		if(document.getElementById("sysDiskType_" + systemName + diskDev).value !== ""){
			systemData.stor[diskDev].type = document.getElementById("sysDiskType_" + systemName + diskDev).value;
		}
		
		if(document.getElementById("sysDiskDriver_" + systemName + diskDev).value !== ""){
			systemData.stor[diskDev].driver = document.getElementById("sysDiskDriver_" + systemName + diskDev).value;
		}
		
		if(document.getElementById("sysDiskCache_" + systemName + diskDev).value !== ""){
			systemData.stor[diskDev].cache = document.getElementById("sysDiskCache_" + systemName + diskDev).value;
		}
		
		if((document.getElementById("sysDiskBackingType_" + systemName + diskDev).value !== "") && (document.getElementById("sysDiskBackingType_" + systemName + diskDev).value == "pool")){
			
			var poolName = document.getElementById("sysDiskBackingPool_" + systemName + diskDev).value;
			log_write_json("system_save", "poolname", poolName);
			
			var pooldata = dbnew_storage_get(poolName);
			
			log_write_json("system_save", "pooldata", pooldata);
			
			systemData.stor[diskDev].pool = {};
			
			systemData.stor[diskDev].pool.name = pooldata.id.name;
			systemData.stor[diskDev].pool.id = pooldata.id.id;
			systemData.stor[diskDev].pool.type = pooldata.object.class;
			
			// update the path
			
		}

	})	
	
	if(valid){
		json_show("[ " + systemName + " ]", systemName, "system", systemData);
		system_rest_save(systemName, systemData);
	}
	
}

/**
 * Sets system auto-refresh interval
 * @param {string} time - Refresh interval (disabled/3/5/10)
 * @description Configures automatic refresh of system view
 */
function system_refresh_time(time){
	var mainView = main_view_get();
	
	console.log("SYSTEM REFRESH TIME SET TO [" + time + "] SYSTEM [" + mainView.key + "]");
	
	if(time == "disabled"){
		document.getElementById("main-system-refresh-time").innerHTML = "Not Refreshing";
	}

	if(time == "3"){
		document.getElementById("main-system-refresh-time").innerHTML = "3s";
		system_refresh_wait("3000", mainView.key);
	}
	
	if(time == "5"){
		document.getElementById("main-system-refresh-time").innerHTML = "5s";
		system_refresh_wait("5000", mainView.key);
	}
	
	if(time == "10"){
		document.getElementById("main-system-refresh-time").innerHTML = "10s";
		system_refresh_wait("10000", mainView.key);
	}	
	
	
}

/**
 * Waits then refreshes system view
 * @param {number} timeout - Timeout in milliseconds
 * @param {string} systemName - Name of the system to refresh
 * @description Waits specified time then refreshes system view
 */
async function system_refresh_wait(timeout, systemName) {
  system_refresh(systemName);
}

