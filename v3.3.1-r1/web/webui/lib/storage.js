/**
 * ETHER|AAPEN|WEB - LIB|STORAGE
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

var size_total = 0
var size_used = 0;
var size_avail = 0;
var size_hdd = 0;
var size_ssd = 0;

var device_ssd = 0;
var device_hdd = 0;

var device_offline = 0;
var device_online = 0;


/**
 * Processes storage metadata from REST API response
 * @param {Object} stormeta - The storage metadata object from API
 * @param {Object} stormeta.response - The API response data
 * @param {Object} stormeta.response.meta - Metadata about storage devices
 * @returns {void} Processes data but returns nothing
 * @throws Will log errors to console if metadata is invalid
 */
 
 function storage_db_process_rest_new(db) {
 
	var storDevNum = 0;
	var storPoolNum = 0;
	var storIsoNum = 0;
  
	storage_menu_remove_device();
	storage_menu_remove_pool();
	storage_menu_remove_iso();
	
	var storIndex = db.storage.index;
	
	var storList = storIndex.split(';');
	storList = sort_alpha(storList);
	
	storList.forEach((storObj) => {
		
		// DEVICE
		if(db.storage.db[storObj].object.model == "device"){
			dbnew_storage_index_device_add(storObj);
			storage_menu_add_device(storObj);
			storDevNum++;
		}

		document.getElementById('menu-storage-device').innerHTML = "Devices (" + storDevNum + ")";

		// POOL
		if(db.storage.db[storObj].object.model == "pool"){
			dbnew_storage_index_pool_add(storObj);
			storage_menu_add_pool(storObj);
			storPoolNum++;
		}
		
		document.getElementById('menu-storage-pool').innerHTML = "Pools (" + storPoolNum + ")";
		
		// ISO
		if(db.storage.db[storObj].object.model == "iso"){
			dbnew_storage_index_iso_add(storObj);
			storage_menu_add_iso(storObj);
			storIsoNum++;
		}
		
		document.getElementById('menu-storage-iso').innerHTML = "ISOs (" + storIsoNum + ")";
		
	});	
	
 
	document.getElementById('main-card-storage').innerHTML = "Online Devices [<b>" + storDevNum + "</b>]<br/>Pools [<b>" + storPoolNum + "</b>] Shares [<b>" + "0" + "</b>] ISOs [<b>" + storIsoNum + "</b>]";
}

/**
 * Displays ISO storage details in the UI
 * @param {string} isoname - Name of the ISO to display
 * @returns {void} Updates UI but returns nothing
 * @throws Will log errors and abort if isoname is invalid or data not found
 */
function stor_show_iso(isoName) {
    var isoData = dbnew_storage_get(isoName);
    
    if(!isoData){
        console.error('ISO data not found for:', isoName);
        return;
    }

    main_storage_iso_show();

	$("#storisoNameTable tbody tr").remove();
	$("#storisoIsoTable tbody tr").remove();
	
	if(isoData){
		document.getElementById("main-storiso-header").textContent = "[ " + isoData.id.name + " ]";	
		document.getElementById("main-storiso-btn-json").onclick = function() { json_show("[ " + isoData.id.name + " ]", isoData.id.name, "isoData", isoData) };
		
		//
		// name
		//
		document.getElementById("main-isodev-name").innerHTML = "Name [<b>" + isoData.id.name + "</b>] id [<b>" + isoData.id.id + "</b>] group [<b>" + isoData.id.group + "</b>] desc [<b>" + isoData.id.desc + "</b>]";	
		
		var tbodyIsoName = $("#storisoNameTable tbody");
		tbodyIsoName.append("<tr><td>" + isoData.id.name + "</td><td>" + isoData.id.id + "</td><td>" + isoData.id.group + "</td><td>" + isoData.id.desc + "</td></tr>");
		
		//
		// iso
		//
		document.getElementById("main-isodev-image").innerHTML = "Image [<b>" + isoData.iso.image + "</b>]";	
		
		var tbodyIso = $("#storisoIsoTable tbody");
		tbodyIso.append("<tr><td><b>" + isoData.iso.image + "</b></td><td>" + isoData.iso.source + "</td><td>" + isoData.iso.dev + "</td></tr>");
		
	}
	else{
		console.log("ISO UNDEFINED!");
	}
}

/**
 * Displays storage pool details in the UI
 * @param {string} poolname - Name of the storage pool to display
 * @returns {void} Updates UI but returns nothing
 * @throws Will log errors and abort if poolname is invalid or data not found
 */
function stor_show_pool(poolName) {
    main_storage_pool_show();
    main_view_set('storage_pool_show', poolName, '');

    var poolData = dbnew_storage_get(poolName);

	$("#storpoolNameTable tbody tr").remove();
	$("#storpoolTable tbody tr").remove();
	$("#storpoolSubsTable tbody tr").remove();
	$("#storpoolStatusTable tbody tr").remove();
	$("#storpoolStateTable tbody tr").remove();
	$("#storpoolSizeTable tbody tr").remove();
	$("#storpoolNodeInfoTable tbody tr").remove();
	
	
	var size_total = 0;
	var size_avail = 0;
	var size_used = 0;
	var size_perc = 0;
	
	document.getElementById("main-storpool-state").innerHTML = "State [" + '<b>UNKNOWN</b>' + "]";
	document.getElementById("main-storpool-subs").innerHTML = "Subscribers [" + '<b>n/a</b>' + "]";
	document.getElementById("main-pooldev-obj-system").innerHTML = 'Systems [<b>UNKNOWN</b>]';
	document.getElementById("main-storpool-subs").innerHTML = "Subscribers [<b>UNKNOWN</b>]";
	

	if(poolData){

		document.getElementById("main-storpool-header").textContent = "[ " + poolData.id.name + " ]";			
		document.getElementById("main-storpool-btn-json").onclick = function() { json_show("[ " + poolData.id.name + " ]", poolData.id.name, "pooldev", poolData) };
		
		//
		// name
		//
		document.getElementById("main-pooldev-name").innerHTML = "Name [<b>" + poolData.id.name + "</b>] id [<b>" + poolData.id.id + "</b>] group [<b>" + poolData.id.group + "</b>] desc [<b>" + poolData.id.desc + "</b>]";	
		
		var tbodyPoolName = $("#storpoolNameTable tbody");
		tbodyPoolName.append("<tr><td>" + poolData.id.name + "</td><td>" + poolData.id.id + "</td><td>" + poolData.id.group + "</td><td>" + poolData.id.desc + "</td></tr>");
		
		//
		// node
		//
		document.getElementById("main-pooldev-node").innerHTML = "Host node [<b>" + poolData.owner.name + "</b>] id [<b>" + poolData.owner.id + "</b>] - device [<b>" + poolData.device.name + "</b>]";	
		
		//
		//
		//
		document.getElementById("main-pooldev-pool").innerHTML = "Pool [<b>" + poolData.id.name + "</b>] backing [<b>" + poolData.pool.backing + "</b>] shared [<b>" + poolData.pool.shared + "</b>] path [<b>" + poolData.pool.path + "</b>]";	
		
		var tbodyPool = $("#storpoolTable tbody");
		tbodyPool.append("<tr><td><b>" + poolData.id.name + "</b></td><td><b>" + poolData.pool.shared + "</td><td><b>" + poolData.pool.path + "</b></td><td>" + poolData.pool.check + "</td><td>" + poolData.pool.backing + "</td><td><b>" + poolData.device.name + "</b></td><td>" + poolData.device.id + "</td></tr>");
		
		var tbodyNodeInfo = $("#storpoolNodeInfoTable tbody");
		
		if(poolData.object.class == "local"){
			tbodyNodeInfo.append("<tr><td><b>" + poolData.owner.name + "</b></td><td><b>" + poolData.owner.id + "</td><td><b>" + poolData.id.name + "</b></td><td><b>" + poolData.id.id + "</b></td><td>" + poolData.owner.mount_on_owner + "</td><td><b>" + poolData.local.mount + "</b></td></tr>");
		}
		
		if(poolData.object.class == "nfs"){
			tbodyNodeInfo.append("<tr><td><b>" + poolData.owner.name + "</b></td><td><b>" + poolData.owner.id + "</td><td><b>" + poolData.id.name + "</b></td><td><b>" + poolData.id.id + "</b></td><td>" + poolData.owner.mount_on_owner + "</td><td><b>" + poolData.pool.path + "</b></td></tr>");
		}
		
		
		//
		// check if online
		//
		if((typeof poolData.meta !== 'undefined') && (typeof poolData.meta.stats !== 'undefined')){
			var nodelist_online = dbnew_node_index_online_get();
			log_write_json("stor_show_pool", nodelist_online);

			var tbodyPoolSubs = $("#storpoolSubsTable tbody");
			
			var subs = "";
			var subnum = 0;
	
			nodelist_online.forEach((node) => {
				log_write_json("stor_show_pool", node);
				
				if((poolData.meta.stats[node] !== null) && (typeof poolData.meta.stats[node] !== 'undefined') && (typeof poolData.meta.stats[node].size !== 'undefined') && (typeof poolData.meta.stats[node].size.total !== 'undefined')){
					tbodyPoolSubs.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_stordevtbl" class="btn btn-link tablebtn">' + node  + "</a></b>" + "</td><td>" + poolData.meta.stats[node].mounted + "</td><td>" + poolData.meta.stats[node].init + "</td><td>" + poolData.meta.stats[node].state + "</td><td>" + poolData.meta.stats[node].updated + "</td><td><b>" + poolData.meta.stats[node].size.total.gb + " GB</b></td><td><b>" + poolData.meta.stats[node].size.used.gb + " GB</b></td><td><b>" + poolData.meta.stats[node].size.free.gb + " GB</b></td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><tr>");
					
					// stats
					if(subs == ""){ subs = node; }
					else{ subs += ";" + node; }
					subnum++;
				}

			});
	
			document.getElementById("main-storpool-subs").innerHTML = "Subscribers [<b>" + subnum + "</b>] nodes [<b>" + subs + "</b>]";
		
			if(subnum > 0){
				document.getElementById("main-storpool-subs").innerHTML = "Subscribers [<b>" + subnum + "</b>] nodes [<b>" + subs + "</b>]";
			}


			if((typeof poolData.meta.stats[poolData.owner.name] !== 'undefined') && (typeof poolData.meta.stats[poolData.owner.name].size !== 'undefined')){
				
				var updated = poolData.object.meta.date;
				if((typeof poolData.object.meta.delta !== 'undefined')){
					updated = poolData.object.meta.delta;
				}
				
				document.getElementById("main-storpool-state").innerHTML = "Status [" + '<b style="color:#24be14">ONLINE</b>' + "] state [<b>" + "healthy" + "</b>] owner [<b>" + poolData.owner.name + "</b>] updated [<b>" + poolData.meta.stats[poolData.owner.name].updated + "</b>] delta [<b>" + updated + "</b>]";
				
				var tbodyPoolState = $("#storpoolStateTable tbody");
				tbodyPoolState.append("<tr><td>" + poolData.owner.name + "</td><td>" + poolData.meta.stats[poolData.owner.name].state + "<td>" + poolData.meta.stats[poolData.owner.name].init +  "</td><td>" + poolData.meta.stats[poolData.owner.name].mounted +  "</td><td><b>" + poolData.meta.stats[poolData.owner.name].updated +  "</b></td><td><b>" + updated +  "</b></td><tr>");
				
				//size
				size_total += parseInt(poolData.meta.stats[poolData.owner.name].size.total.gb);
				size_avail += parseInt(poolData.meta.stats[poolData.owner.name].size.free.gb);
				size_used += parseInt(poolData.meta.stats[poolData.owner.name].size.used.gb);
				size_perc = (parseInt(size_used) / parseInt(size_total)) * 100;
				document.getElementById("storpoolSizeProgress").style.width = size_perc.toFixed(1) + "%";
				document.getElementById("storpoolSizeProgress").innerHTML = "<b>" + size_perc.toFixed(1) + " %</b>";
				
				document.getElementById("main-storpool-size").innerHTML = "Size [<b>" + poolData.meta.stats[poolData.owner.name].size.total.gb + " GB</b>] used [<b>" + poolData.meta.stats[poolData.owner.name].size.used.gb + " GB</b>] available [<b>" + poolData.meta.stats[poolData.owner.name].size.avail.gb + " GB</b>] consumed [<b>" + size_perc.toFixed(1) + " %</b>]";
			}
			
			//
			// get systems
			//
			var sysnum = 0;
			var sys_online = 0;
			var sys_offline = 0;
			var sys_size_tot = 0;
			
			$("#storpoolSystemTable tbody tr").remove();
			var tbodyPoolSystems = $("#storpoolSystemTable tbody");
			document.getElementById("main-pooldev-obj-system").innerHTML = 'Systems [<b>UNKNOWN</b>]';
			
			var sysList = dbnew_system_index_get();
			
			sysList.forEach((sysName) => {	
				
				var systemData = dbnew_system_get(sysName);
				//const nodename = systemData.meta.node_name;
				const sysname = systemData.id.name;
				
				//
				// enumerate storage devs
				//
				if(systemData.stor.disk !== ""){	
					var stor = systemData.stor.disk;
					storIndex = stor.split(';');
					
					// storage devices
					storIndex.forEach((stordev) => {
						
						if((typeof systemData.stor[stordev].backing !== 'undefined')){
	
							if(systemData.stor[stordev].pool.name == poolData.id.name){
								
								if(systemData.stor[stordev].backing == "pool"){
									var size_on_disk = "N/A";
									var size_alloc = "N/A";
									
									//check if metadata present
									if((typeof systemData.meta !== 'undefined') && (typeof systemData.meta.disk !== 'undefined') && (typeof systemData.meta.disk[stordev] !== 'undefined') && (typeof systemData.meta.disk[stordev].disk_size !== 'undefined')){
										size_alloc = "<b>" + systemData.meta.disk[stordev].virt_size + " " +  systemData.meta.disk[stordev].virt_size_unit + "</b>";
									}
									
									if((typeof systemData.meta.stats !== 'undefined') && (typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk[stordev] !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk[stordev].size !== 'undefined')){
										size_on_disk = "<b>" + systemData.meta.stats.hypervisor.disk[stordev].size + "</b>";
									}
									
									// check if online
									if((typeof systemData.state !== 'undefined') && (typeof systemData.state.vm_status !== 'undefined') && (typeof systemData.meta !== 'undefined') && (systemData.meta.state == 1)){
										tbodyPoolSystems.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_poolsysbl" class="btn btn-link tablebtn">' + sysname  + "</a></b></td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><td><b>" + stordev + "</b></td><td>" + systemData.stor[stordev].size + " GB</td><td>" + size_alloc + "</td><td>" + size_on_disk + "</td><td>" + systemData.stor[stordev].image + "</td><tr>");
										sys_online++;
									}
									else{
										tbodyPoolSystems.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_poolsysbl" class="btn btn-link tablebtn">' + sysname  + "</a></b></td><td><b>" + "OFFLINE" + "</b></td><td><b>" + stordev + "</b></td><td>" + systemData.stor[stordev].size + " GB</td><td>" + size_alloc + "</td><td>" + size_on_disk + "</td><td>" + systemData.stor[stordev].image + "</td><tr>");
										sys_offline++;
									}

									document.getElementById("tempbtn_poolsysbl").id = "tempbtn_poolsysbl_" + sysname + stordev;
									document.getElementById("tempbtn_poolsysbl_" + sysname + stordev).onclick = function() { system_show(sysname) };
									
									sys_size_tot += parseInt(systemData.stor[stordev].size);
								}

								// this one counts devices not systems -- FIXME
								sysnum++;
							}
						}
					});
				}
			});
			
			document.getElementById("main-pooldev-obj-system").innerHTML = 'Systems [<b>' + sysnum + '</b>] online [<b>' + sys_online + '</b>] offline [<b>' + sys_offline + '</b>] allocated [<b>' + sys_size_tot + ' GB</b>]';

			//size allocated
			var size_perc_alloc = (parseInt(sys_size_tot) / parseInt(size_total)) * 100;
			document.getElementById("storpoolSizeAllocProgress").style.width = size_perc_alloc.toFixed(1) + "%";
			document.getElementById("storpoolSizeAllocProgress").innerHTML = "<b>" + size_perc_alloc.toFixed(1) + " %</b>";

			if((typeof poolData.meta !== 'undefined') && (typeof poolData.meta.stats[poolData.owner.name] !== 'undefined') && (typeof poolData.meta.stats[poolData.owner.name].size !== 'undefined')){
				// overview table
				var tbodyPoolSize = $("#storpoolSizeTable tbody");
				tbodyPoolSize.append("<tr><td><b>" + poolData.meta.stats[poolData.owner.name].size.total.gb +  " GB</b></td><td><b>" + poolData.meta.stats[poolData.owner.name].size.used.gb +  " GB</b></td><td><b>" + poolData.meta.stats[poolData.owner.name].size.avail.gb +  " GB</b></td><td><b>" + poolData.meta.stats[poolData.owner.name].size.free.gb +  " GB</b></td><td><b>" + size_perc.toFixed(1) +  " %</b></td><td><b>" + sys_size_tot +  " GB</b></td><td><b>" + size_perc_alloc.toFixed(1) +  " %</b></td><tr>");
			}
		}
		else{
			log_write_json("stor_show_pool", "[FAILURE]", "pool data processing failed");
		}
	}
	else{
		log_write_json("stor_show_pool", "[FAILURE]", "pool data invalid");
	}
}

/**
 * Displays storage device details in the UI
 * @param {string} storname - Name of the storage device to display
 * @returns {void} Updates UI but returns nothing
 * @throws Will log errors and abort if storname is invalid or data not found
 */
function stor_show_device(deviceName){
    main_storage_device_show();
    main_view_set('storage_device_show', deviceName, '');
    
    var deviceData = dbnew_storage_get(deviceName);
    	
	if((typeof deviceData !== 'undefined')){
	
		log_write_json("stor_show_device_new", "[TOP]", deviceData);

		$("#stordevStatusObjTable tbody tr").remove();
		$("#stordevStatusTable tbody tr").remove();
		$("#stordevStatusHealth tbody tr").remove();
		$("#stordevStatusHealthTable tbody tr").remove();
		$("#stordevDevTable tbody tr").remove();
		$("#stordevStatusSizeTable tbody tr").remove();
		$("#stordevStatusSmartTable tbody tr").remove();
		$("#stordevStatusIOTable tbody tr").remove();
		$("#stordevRaidTable tbody tr").remove();
		$("#stordevRaidDevsTable tbody tr").remove();
		$("#stordevNvmeStatusTable tbody tr").remove();
		$("#stordevNvmeHealthTable tbody tr").remove();
		
		document.getElementById("stordevSizeProgress").style.width = 0 + "%";
		document.getElementById("stordevSizeProgress").innerHTML = "<b>" + "0" + " %</b>";
		
		
		var size_total = 0;
		var size_avail = 0;
		var size_used = 0;
		var size_perc = 0;
		
		var size_hdd = 0;
		var size_ssd = 0;
		
		var device_ssd = 0;
		var device_hdd = 0; 
		
		var device_offline = 0;
		var device_online = 0;

		document.getElementById("main-stordev-header").textContent = "[ " + deviceData.id.name + " ]";	
		document.getElementById("main-stordev-btn-json").onclick = function() { json_show("[ " + deviceData.id.name + " ]", deviceData.id.name, "stordev", deviceData) };
		document.getElementById("main-stordev-node").innerHTML = " Node [<b>" + deviceData.node.name + "</b>] id [" + deviceData.node.id + "]";	
		document.getElementById("main-stordev-name").innerHTML = " Storage [<b>" + deviceData.id.name + "</b>] id [" + deviceData.id.id + "]";	
		document.getElementById("main-stordev-type").innerHTML = " Type [<b>" + deviceData.object.class + "</b>]";
		
		var backing = "unknown";
		
		var tbodyObj = $("#stordevStatusObjTable tbody");
		
		var tbodyDev = $("#stordevDevTable tbody");
		var tbodyStatus = $("#stordevStatusTable tbody");
		var tbodyHealth = $("#stordevStatusHealthTable tbody");
		var tbodySize = $("#stordevStatusSizeTable tbody");
		var tbodySmart = $("#stordevStatusSmartTable tbody");
		var tbodyIO = $("#stordevStatusIOTable tbody");
		var tbodyRaid = $("#stordevRaidTable tbody");
		var tbodyRaidDevs = $("#stordevRaidDevsTable tbody");
		var tbodyNvmeStatus = $("#stordevNvmeStatusTable tbody");
		var tbodyNvmeHealth = $("#stordevNvmeHealthTable tbody");

		// cluster object
		if((typeof deviceData.object !== 'undefined') && (typeof deviceData.object.meta !== 'undefined')){
			tbodyObj.append("<tr><td>" + deviceData.object.model + "</td><td>" + deviceData.object.type + "</td><td>" + deviceData.object.class + "</td><td><b>" + deviceData.object.meta.owner_name + "</b></td><td><b>" + deviceData.object.meta.owner_id + "</b></td><td>" + deviceData.object.meta.ver + "</td><td>" + deviceData.object.meta.date + "</td></tr>");
		}

		// object state
		if((typeof deviceData.meta !== 'undefined') && (typeof deviceData.meta.stats !== 'undefined') && ((deviceData.meta.state == "1") || (deviceData.meta.state == "2"))){

			var state;
			var status = "n/a";
			
			if((typeof deviceData.meta.status !== 'undefined')){
				status = view_health_color_status(deviceData.meta.status);
			}
			
			if((deviceData.meta.state == 1)){
				state = view_color_healthy("ONLINE");
			}
			
			if((deviceData.meta.state == 2)){
				state = view_health_color_status(deviceData.meta.status);
				status = view_health_color_status(deviceData.meta.warning);
			}
			
			var updated = deviceData.object.meta.date;
			if((typeof deviceData.object.meta.delta !== 'undefined')){
				updated = deviceData.object.meta.delta;
			}

			document.getElementById("main-stordev-state").innerHTML = 'State [' + state + ']' + " status [" + status + "] updated [<b>" + deviceData.meta.date + "</b>] delta [<b>" + updated + "</b>]";
			
			if((typeof deviceData.meta.health !== 'undefined') && (typeof deviceData.meta.warning !== 'undefined') && (typeof deviceData.meta.health !== 'undefined') && (typeof deviceData.meta.health.status !== 'undefined')){
				
				// compat until cluster merged
				var statusHealth = view_health_color_status("N/A");
				if((typeof deviceData.meta.status !== 'undefined')){
					statusHealth = view_health_color_status(deviceData.meta.health.status);
				}

				var smartHealth = view_health_color_status(deviceData.meta.health.smart);
				var devHealth = view_health_color_status(deviceData.meta.health.device);
				var tempHealth = view_health_color_status(deviceData.meta.health.temperature);
				
				document.getElementById("main-stordev-status").innerHTML = '<b>Health</b> state [' + status + ']' + " - SMART status [<b>" + smartHealth + "</b>] - Self check [<b>" + devHealth + "</b>] - Temperature [<b>" + tempHealth + "</b>]";
				
				tbodyHealth.append("<tr><td>" + status + "</td><td>" + statusHealth + "</td><td>" + smartHealth + "</td><td>" + devHealth + "</td><td>" + tempHealth + "</td><td>" + deviceData.meta.warning + "</b></td></tr>");
			}
			else{
				document.getElementById("main-stordev-status").innerHTML = '<b>Health</b> state [' + status + ']' + " - SMART status [<b>n/a</b>] - Self check [<b>n/a</b>] - Temperature [<b>n/a</b>]";
			}
		}
		else{
			document.getElementById("main-stordev-state").innerHTML = "State [<b>UNKNOWN</b>]";
			document.getElementById("main-stordev-status").innerHTML = '<b>Health</b> state [<b>' + "UNKNOWN" + '</b>' + "]";
		}
		
		
		// health monitors
		if((typeof deviceData.meta !== 'undefined')){
			var healthSmart = 0;
			var healthSize = 0;
			var healthIostat = 0;
			var healthStatus = "unknown";
			var healthState = "unknown";
		
			// check for smart
			if((typeof deviceData.meta.smart !== 'undefined')){
				healthSmart = 1;
			}

			if((typeof deviceData.meta.size !== 'undefined')){
				healthSize = 1;
			}

			if((typeof deviceData.meta.iostat !== 'undefined')){
				healthIostat = 1;
			}

			if((typeof deviceData.meta.status !== 'undefined')){
				healthStatus = deviceData.meta.status;
			}
			
			if((typeof deviceData.meta.state !== 'undefined') && (deviceData.meta.state == 1)){
				healthState = "online";
			}
			else{
				healthState = "offline";
			}
			
			tbodyStatus.append("<tr><td>" + healthState + "</td><td>" + healthStatus + "</td><td>" + healthSmart + "</td><td>" + healthIostat + "</td><td>" + healthSize + "</b></td><td>" + deviceData.meta.date + "</td></tr>");
		}
		
		let unicodeDegCel = '℃'.codePointAt(0);
		
		//
		// disk
		//
		if(deviceData.object.class == "disk"){
			backing = deviceData.device.type;
			
			if((typeof deviceData.meta !== 'undefined') && (typeof deviceData.meta !== 'undefined') && (deviceData.meta.state == "1")){
				
				// size
				size_total += parseInt(deviceData.meta.size.total.gb);
				size_avail += parseInt(deviceData.meta.size.free.gb);
				size_used += parseInt(deviceData.meta.size.used.gb);
				size_perc = (parseInt(size_used) / parseInt(size_total)) * 100;
				
				document.getElementById("stordevSizeProgress").style.width = size_perc.toFixed(1) + "%";
				document.getElementById("stordevSizeProgress").innerHTML = "<b>" + size_perc.toFixed(1) + " %</b>";
		
				document.getElementById("main-stordev-size").innerHTML = " <b>Size</b> configured [<b>" + deviceData.device.size + "</b>] actual [<b>" + deviceData.meta.size.total.gb + " GB</b>] used [<b>" + deviceData.meta.size.used.gb + " GB</b>] available [<b>" + deviceData.meta.size.avail.gb + " GB</b>] consumed [<b>" + size_perc.toFixed(1) + " %</b>] ";
				
				// device
				tbodySize.append("<tr><td>" + deviceData.device.size + "</td><td><b>" + deviceData.meta.size.total.gb + " GB</b></td><td>" + deviceData.meta.size.used.gb + " GB</td><td>" + deviceData.meta.size.avail.gb + " GB</td><td><b>" + deviceData.meta.size.free.gb + " GB</b></td><td>" + size_perc.toFixed(1) + " %</td><td>" + deviceData.meta.size.inode.tot + "</td><td>" + deviceData.meta.size.inode.free + "</td><td>" + deviceData.meta.size.inode.perc + " %</td></td>");
				
				// smart
				tbodySmart.append("<tr><td><b>" + deviceData.meta.smart.model_name + "</b></td><td>" + deviceData.meta.smart.firmware + "</td><td>" + deviceData.meta.smart.form_factor + "</td><td><b>" + deviceData.meta.smart.smart_passed + "</b></td><td><b>" + deviceData.meta.smart.self_test_passed + "</b></td><td>" + deviceData.meta.smart.power_cycles + "</td><td>" + deviceData.meta.smart.power_on_hours + "</td><td><b>" + deviceData.meta.smart.temperature + "</b></td></tr>");
				
				// iostat
				tbodyIO.append("<tr><td><b>" + deviceData.meta.iostat.device + "</b></td><td>" + deviceData.meta.iostat.kb_read_tot + "</td><td>" + deviceData.meta.iostat.kb_write_tot + "</td><td><b>" + deviceData.meta.iostat.kb_read_sec + "</b></td><td><b>" + deviceData.meta.iostat.kb_write_sec + "</b></td></tr>");				
				// partitions
				tbodyDev.append("<tr><td>" + deviceData.device.dev + "</td><td>" + deviceData.device.part + "</td><td>" + deviceData.device.mount + "</td><td><b>" + deviceData.device.type + "</b></td><td><b>" + deviceData.device.size + "</b></td><td>" + deviceData.device.smart_check + "</td></tr>");
			}
			else{
				document.getElementById("main-stordev-size").innerHTML = " <b>Size</b> configured [<b>" + deviceData.device.size + "</b>]";
				
				document.getElementById("stordevSizeProgress").style.width = 0 + "%";
				document.getElementById("stordevSizeProgress").innerHTML = "<b>" + "n/a" + " %</b>";

				tbodyDev.append("<tr><td>" + deviceData.device.dev + "</td><td>" + deviceData.device.part + "</td><td>" + deviceData.device.mount + "</td><td><b>" + deviceData.device.type + "</b></td><td><b>" + deviceData.device.size + "</b></td><td>" + deviceData.device.smart_check + "</td></tr>");
			}
		}

		//
		// nvme
		//
		if(deviceData.object.class == "nvme"){
			backing = deviceData.device.type;
			
			if((typeof deviceData.meta !== 'undefined') && (typeof deviceData.meta.stats !== 'undefined') && (deviceData.meta.stats[deviceData.node.name].state === "1")){
				
				// size
				size_total += parseInt(deviceData.meta.size.total.gb);
				size_avail += parseInt(deviceData.meta.size.free.gb);
				size_used += parseInt(deviceData.meta.size.used.gb);
				size_perc = (parseInt(size_used) / parseInt(size_total)) * 100;
				
				document.getElementById("stordevSizeProgress").style.width = size_perc.toFixed(1) + "%";
				document.getElementById("stordevSizeProgress").innerHTML = "<b>" + size_perc.toFixed(1) + " %</b>";
				
				document.getElementById("main-stordev-size").innerHTML = " <b>Size</b> configured [<b>" + deviceData.device.size + "</b>] actual [<b>" + deviceData.meta.size.total.gb + " GB</b>] used [<b>" + deviceData.meta.size.used.gb + " GB</b>] available [<b>" + deviceData.meta.size.avail.gb + " GB</b>] consumed [<b>" + size_perc.toFixed(1) + " %</b>] ";
				
				tbodySize.append("<tr><td>" + deviceData.device.size + "</td><td><b>" + deviceData.meta.size.total.gb + " GB</b></td><td>" + deviceData.meta.size.used.gb + " GB</td><td>" + deviceData.meta.size.avail.gb + " GB</td><td><b>" + deviceData.meta.size.free.gb + " GB</b></td><td>" + size_perc.toFixed(1) + " %</td><td>" + deviceData.meta.size.inode.tot + "</td><td>" + deviceData.meta.size.inode.free + "</td><td>" + deviceData.meta.size.inode.perc + " %</td></td>");
				
				// smart
				tbodySmart.append("<tr><td><b>" + deviceData.meta.smart.model_name + "</b></td><td>" + deviceData.meta.smart.firmware + "</td><td>" + deviceData.meta.smart.form_factor + "</td><td><b>" + deviceData.meta.smart.smart_passed + "</b></td><td><b>" + deviceData.meta.smart.self_test_passed + "</b></td><td>" + deviceData.meta.smart.power_cycles + "</td><td>" + deviceData.meta.smart.power_on_hours + "</td><td><b>" + deviceData.meta.smart.temperature + "</b></td></tr>");
				
				// iostat
				tbodyIO.append("<tr><td><b>" + deviceData.meta.iostat.device + "</b></td><td>" + deviceData.meta.iostat.kb_read_tot + "</td><td>" + deviceData.meta.iostat.kb_write_tot + "</td><td><b>" + deviceData.meta.iostat.kb_read_sec + "</b></td><td><b>" + deviceData.meta.iostat.kb_write_sec + "</b></td></tr>");
				
				// raid header
				document.getElementById("main-stordev-nvme").innerHTML = " NVME [<b>" + deviceData.meta.nvme.info.ModelNumber + "</b>] dev [<b>" + deviceData.meta.nvme.info.DevicePath + "</b>]";
				tbodyNvmeStatus.append("<tr><td><b>" + deviceData.meta.nvme.info.ModelNumber + "</b></td><td>" + deviceData.meta.nvme.info.DevicePath + "</td><td>" + deviceData.meta.nvme.info.Firmware + "</td><td>" + deviceData.meta.nvme.info.SectorSize + "</td><td>" + deviceData.meta.nvme.info.PhysicalSize + "</td></tr>");
				tbodyNvmeHealth.append("<tr><td><b>" + deviceData.meta.nvme.health.avail_spare + " %</b></td><td>" + deviceData.meta.nvme.health.spare_thresh + "</td><td>" + deviceData.meta.nvme.health.media_errors + "</td><td>" + deviceData.meta.nvme.health.power_cycles + "</td><td>" + deviceData.meta.nvme.health.num_err_log_entries + "</td><td>" + deviceData.meta.nvme.health.critical_warning + "</td></tr>");
				
				tbodyDev.append("<tr><td>" + deviceData.device.dev + "</td><td>" + deviceData.device.part + "</td><td>" + deviceData.device.mount + "</td><td><b>" + deviceData.device.type + "</b></td><td><b>" + deviceData.device.size + "</b></td><td>" + deviceData.device.smart_check + "</td></tr>");
			}
			else{
				document.getElementById("main-stordev-size").innerHTML = " <b>Size</b> configured [<b>" + deviceData.device.size + "</b>]";
				
				document.getElementById("stordevSizeProgress").style.width = 0 + "%";
				document.getElementById("stordevSizeProgress").innerHTML = "<b>" + "n/a" + " %</b>";

				tbodyDev.append("<tr><td>" + deviceData.device.dev + "</td><td>" + deviceData.device.part + "</td><td>" + deviceData.device.mount + "</td><td><b>" + deviceData.device.type + "</b></td><td><b>" + deviceData.device.size + "</b></td><td>" + deviceData.device.smart_check + "</td></tr>");
			}
		}
		else{
			document.getElementById("main-stordev-nvme").innerHTML = " NVME [<b>" + "n/a" + "</b>]";
		}
		
		//
		// mdraid
		//
		if(deviceData.object.class == "mdraid"){
			backing = deviceData.mdraid.type;
			
			if((typeof deviceData.meta !== 'undefined') && (typeof deviceData.meta.iostat !== 'undefined') && (typeof deviceData.meta.size !== 'undefined')){
			
				size_total += parseInt(deviceData.meta.size.total.gb);
				size_avail += parseInt(deviceData.meta.size.free.gb);
				size_used += parseInt(deviceData.meta.size.used.gb);
				size_perc = (parseInt(size_used) / parseInt(size_total)) * 100;
				
				document.getElementById("stordevSizeProgress").style.width = size_perc.toFixed(1) + "%";
				document.getElementById("stordevSizeProgress").innerHTML = "<b>" + size_perc.toFixed(1) + " %</b>";
				
				document.getElementById("main-stordev-size").innerHTML = " <b>Size</b> configured [<b>" + deviceData.mdraid.size + "</b>] actual [<b>" + deviceData.meta.size.total.gb + " GB</b>] used [<b>" + deviceData.meta.size.used.gb + " GB</b>] available [<b>" + deviceData.meta.size.avail.gb + " GB</b>] consumed [<b>" + size_perc.toFixed(1) + " %</b>] ";
				
				tbodySize.append("<tr><td>" + deviceData.mdraid.size + "</td><td><b>" + deviceData.meta.size.total.gb + " GB</b></td><td>" + deviceData.meta.size.used.gb + " GB</td><td>" + deviceData.meta.size.avail.gb + " GB</td><td><b>" + deviceData.meta.size.free.gb + " GB<b></td><td>" + size_perc.toFixed(1) + " %</td><td>" + deviceData.meta.size.inode.tot + "</td><td>" + deviceData.meta.stats[deviceData.node.name].size.inode.free + "</td><td>" + deviceData.meta.stats[deviceData.node.name].size.inode.perc + " %</td></td>");
				
				document.getElementById("main-stordev-raid").innerHTML = " <b>Raid</b> device [<b>" + deviceData.mdraid.node + "</b>] level [" + deviceData.mdraid.raid + "] active [<b>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].raid + "</b>] state [<b>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].state + "</b>] online " + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].disk_online + " status " +  deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].disk_status + "";

				// smart
				var dev_lst = deviceData.mdraid.devices;
				var mdraid_dev = dev_lst.split(';');
				
				var dev_lst_mdraid = deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].devices.index;
				var mdraid_devstate = dev_lst_mdraid.split(';');
				
				mdraid_dev.forEach((dev) => {
					tbodySmart.append("<tr><td><b>" + deviceData.meta.stats[deviceData.node.name].smart[dev].model_name + "</b></td><td>" + deviceData.meta.stats[deviceData.node.name].smart[dev].firmware + "</td><td>" + deviceData.meta.stats[deviceData.node.name].smart[dev].form_factor + "</td><td><b>" + deviceData.meta.stats[deviceData.node.name].smart[dev].smart_passed + "</b></td><td><b>" + deviceData.meta.stats[deviceData.node.name].smart[dev].self_test_passed + "</b></td><td>" + deviceData.meta.stats[deviceData.node.name].smart[dev].power_cycles + "</td><td>" + deviceData.meta.stats[deviceData.node.name].smart[dev].power_on_hours + "</td><td><b>" + deviceData.meta.stats[deviceData.node.name].smart[dev].temperature + "</b></td></tr>");
					
					mdraid_devstate.forEach((mddev) => {
						if(deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].devices[mddev].includes(dev)){
							var diskStatus = view_health_color_status(deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].health[dev].status);
							tbodyRaidDevs.append("<tr><td><b>" + dev + "</b></td><td>" + deviceData.mdraid[dev].dev + "</td><td>" + deviceData.mdraid[dev].part + "</td><td><b>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].devices[mddev] + "</b></td><td><b>" + diskStatus + "</b></td><td><b>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].health[dev].warning + "</b></td></tr>");
						}
					})
					
				});
				
				// iostat
				tbodyIO.append("<tr><td><b>" + deviceData.meta.stats[deviceData.node.name].iostat.device + "</b></td><td>" + deviceData.meta.stats[deviceData.node.name].iostat.kb_read_tot + "</td><td>" + deviceData.meta.stats[deviceData.node.name].iostat.kb_write_tot + "</td><td><b>" + deviceData.meta.stats[deviceData.node.name].iostat.kb_read_sec + "</b></td><td><b>" + deviceData.meta.stats[deviceData.node.name].iostat.kb_write_sec + "</b></td></tr>");
				
				// mdraid
				var raidState = view_health_color_status(deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].state);
				tbodyRaid.append("<tr><td><b>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].mddev + "</b></td><td>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].raid + "</td><td><b>" + raidState + "</b></td><td>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].disk_online + "</td><td>" + deviceData.meta.stats[deviceData.node.name].mdraid[deviceData.mdraid.node].disk_status + "</td></tr>");
				
				tbodyDev.append("<tr><td>" + deviceData.mdraid.dev + "</td><td>" + deviceData.mdraid.part + "</td><td>" + deviceData.mdraid.mount + "</td><td><b> RAID " + deviceData.mdraid.raid + "</b></td><td><b>" + deviceData.mdraid.size + "</b></td><td>" + deviceData.mdraid.smart_check + "</td></tr>");
			}
			else{
				// no metadata
				var dev_lst = deviceData.mdraid.devices;
				var mdraid_dev = dev_lst.split(';');
				
				mdraid_dev.forEach((dev) => {
					tbodyRaidDevs.append("<tr><td><b>" + dev + "</b></td><td>" + deviceData.mdraid[dev].dev +  "</td><td>" + deviceData.mdraid[dev].part +  "</td><td>" + "n/a" +  "</td></tr>");
						
				});
				
				tbodyRaid.append("<tr><td><b>" + deviceData.mdraid.node + "</b></td><td><b>" + deviceData.mdraid.raid + "</b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td></tr>");
				
				document.getElementById("main-stordev-raid").innerHTML = "<b>Raid</b> device [<b>" + deviceData.mdraid.node + "</b>] level [" + deviceData.mdraid.raid + "] devices [" + mdraid_dev.length + "]";
				document.getElementById("main-stordev-size").innerHTML = " <b>Size</b> configured [<b>" + deviceData.mdraid.size + "</b>]";
				
				document.getElementById("stordevSizeProgress").style.width = 0 + "%";
				document.getElementById("stordevSizeProgress").innerHTML = "<b>" + "n/a" + " %</b>";
				
				tbodyDev.append("<tr><td>" + deviceData.mdraid.dev + "</td><td>" + deviceData.mdraid.part + "</td><td>" + deviceData.mdraid.mount + "</td><td><b> RAID " + deviceData.mdraid.raid + "</b></td><td><b>" + deviceData.mdraid.size + "</b></td><td>" + deviceData.mdraid.smart_check + "</td></tr>");
			}

		}
		else{
			document.getElementById("main-stordev-raid").innerHTML = " Raid [<b>" + "n/a" + "</b>]";
		}
		
		document.getElementById("main-stordev-type").innerHTML = " Type [<b>" + deviceData.object.class + "</b>] backing [<b>" + backing + "</b>]";
	}
}

/**
 * Asynchronously displays the storage system overview
 * Gathers and displays summary of all storage devices and pools
 * @returns {void} Updates UI but returns nothing
 */
function stor_overview_show() {
	main_storage_overview_show();
	
	$("#storageDeviceTable tbody tr").remove();
	$("#storagePoolTable tbody tr").remove();
	
	size_total = 0
	size_used = 0;
	size_avail = 0;
	size_hdd = 0;
	size_ssd = 0;

	device_ssd = 0;
	device_hdd = 0;

	device_offline = 0;
	device_online = 0;
	
	// devices
	var devList = dbnew_storage_index_device_get();
	
	log_write_json("stor_overview_show", "[devIndex]", devList);
	
	devList.forEach((dev) => {
		log_write_json("stor_overview_show", "[dev]", dev);
		var device = dbnew_storage_get(dev);
		stor_conf_device_process(device);
	});

	// pools
	var poolList = dbnew_storage_index_pool_get();

	log_write_json("stor_overview_show", "[poolIndex]", poolList);
	
	poolList.forEach((pool) => {
		log_write_json("stor_overview_show", "[pool]", pool);
		var pool = dbnew_storage_get(pool);
		stor_conf_pool_process(pool);
	});	
	
}

//
//
//
function stor_conf_device_process(device){
	var tbody = $("#storageDeviceTable tbody");

	var stortype = "n/a";

	if((typeof device !== 'undefined')){
		
		const nodeName = device.node.name;
		const devName = device.id.name;
		var stortype = "n/a";
		
		if(device.object.class == "disk" || device.object.class == "nvme"){
			stortype = device['device'].type;
			
			if(stortype == "hdd"){
				device_hdd++;
				
				if(typeof device.meta !== 'undefined' && typeof device.meta.size !== 'undefined'){
					size_hdd += parseInt(device.meta.size.total.gb);
				}
			}
			
			if(stortype === "ssd" || stortype == "nvme"){
				device_ssd++;
				
				if(typeof device.meta !== 'undefined' && typeof device.meta.size !== 'undefined'){
					size_ssd += parseInt(device.meta.size.total.gb);
				}
			}
		}
		
		if(device.object.class == "mdraid"){
			stortype = device['mdraid'].type;
			
			if(stortype == "hdd"){
				device_hdd++;
				
				if(typeof device.meta !== 'undefined' && typeof device.meta.size !== 'undefined'){
					size_hdd += parseInt(device.meta.size.total.gb);
				}
			}
			
			if(stortype == "ssd" || stortype == "nvme"){
				device_ssd++;
				
				if(typeof device.meta !== 'undefined' && typeof device.meta.size !== 'undefined'){
					size_ssd += parseInt(device.meta.size.total.gb);
				}
			}
		}
		
		if((typeof device.meta !== 'undefined') && (device.meta.state == 1)){
			log_write_json("stor_conf_device_process_new", "[ONLINE]", device.id.name);

			device_online++;
			
			// stats
			if((typeof device.object !== 'undefined') && (typeof device.object.meta !== 'undefined') && (typeof device.meta.size !== 'undefined')){
				var healthy = "n/a";
				if((typeof device.meta.health !== 'undefined') && (typeof device.meta.health.status !== 'undefined')){
					healthy = view_health_color_status(device.meta.health.status);
				}
				else if((typeof device.meta.status !== 'undefined')){
					healthy = view_health_color_status(device.meta.status);
				}
				else{
					healthy = "n/a";
				}
				
				var diff = date_str_diff_now(device.object.meta.date);

				if($('#switchStorShowOnline').prop('checked')){
					
					tbody.append("<tr><td>" + device.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stordevtbl" class="btn btn-link tablebtn">' + device.id.name  + "</a></b>" + "</td><td><b>" + device.object.class + "</b></td><td><b>" + stortype + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stornodetbl" class="btn btn-link tablebtn">' + device.node.name  + "</a></b>" + "</td><td>" + device.object.meta.ver + "</td><td><b>" + diff + "</b></td><td><b>" + device.meta.size.total.gb + " GB</b></td><td><b>" + device.meta.size.used.gb + " GB</b></td><td><b>" + device.meta.size.free.gb + " GB</b></td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><td>" + healthy + "</td><td>" + '<b style="color:#24be14">CLUSTER</b>' + "</td><tr>");
					
					document.getElementById("tempbtn_stordevtbl").id = "btn_stordevtbl_" + devName;
					document.getElementById("btn_stordevtbl_" + devName).onclick = function() { stor_show_device(devName) };
						
					document.getElementById("tempbtn_stornodetbl").id = "btn_stornodetbl_" + devName;
					document.getElementById("btn_stornodetbl_" + devName).onclick = function() { node_show(nodeName) };
			
				}
				
				size_total += parseInt(device.meta.size.total.gb);
				size_avail += parseInt(device.meta.size.free.gb);
				size_used += parseInt(device.meta.size.used.gb);
			}
			else{
				
				if($('#switchStorShowOnline').prop('checked')){
					tbody.append("<tr><td>" + device.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stordevtbl" class="btn btn-link tablebtn">' + device.id.name  + "</a></b>" + "</td><td><b>" + device.object.class + "</b></td><td><b>" + stortype + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stornodetbl" class="btn btn-link tablebtn">' + device.node.name  + "</a></b>" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + 'n/a' + "</td><td>" + 'n/a' + "</td><td>" + '<b>LOCAL</b>' + "</td><tr>");
				}
				
			}
		}
		else{
			
			device_offline++;
			
			if($('#switchStorShowOffline').prop('checked')){
			
				// metadata present
				if((typeof device.object.meta !== 'undefined') && (typeof device.object.meta.ver !== 'undefined') && (typeof device.object.meta.date !== 'undefined')){
					tbody.append("<tr><td>" + device.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stordevtbl" class="btn btn-link tablebtn">' + device.id.name  + "</a></b>" + "</td><td><b>" + device.object.class + "</b></td><td><b>" + stortype + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stornodetbl" class="btn btn-link tablebtn">' + device.node.name  + "</a></b>" + "</td><td>" + device.object.meta.ver + "</td><td>" + device.object.meta.date + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + 'n/a' + "</td><td>" + 'n/a' + "</td><td>" + '<b>LOCAL</b>' + "</td><tr>");
				}
				else{
					tbody.append("<tr><td>" + device.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stordevtbl" class="btn btn-link tablebtn">' + device.id.name  + "</a></b>" + "</td><td><b>" + device.object.class + "</b></td><td><b>" + stortype + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stornodetbl" class="btn btn-link tablebtn">' + device.node.name  + "</a></b>" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + 'n/a' + "</td><td>" + 'n/a' + "</td><td>" + '<b>LOCAL</b>' + "</td><tr>");
				}
				
				document.getElementById("tempbtn_stordevtbl").id = "btn_stordevtbl_" + devName;
				document.getElementById("btn_stordevtbl_" + devName).onclick = function() { stor_show_device(devName) };
						
				document.getElementById("tempbtn_stornodetbl").id = "btn_stornodetbl_" + devName;
				document.getElementById("btn_stornodetbl_" + devName).onclick = function() { node_show(nodeName) }; 
			
			}
		}
		
		var niceSizeHDD = niceGBytes(size_hdd);
		var niceSizeSSD = niceGBytes(size_ssd);
		
		var niceSizeTotal = niceGBytes(size_total);
		var niceSizeUsed = niceGBytes(size_used);
		var niceSizeAvail = niceGBytes(size_avail);
		
		document.getElementById("main-storage-size-total").innerHTML = "<b>" + niceSizeTotal + "</b>";
		document.getElementById("main-storage-size-used").innerHTML = "<b>" + niceSizeUsed + "</b>";
		document.getElementById("main-storage-size-avail").innerHTML = "<b>" + niceSizeAvail + "</b>";

		document.getElementById("main-storage-dev-tot").innerHTML = "<b>" + (device_hdd + device_ssd) + "</b>";
		document.getElementById("main-storage-dev-hdd").innerHTML = "<b>" + device_hdd + " / " + niceSizeHDD + "</b>";
		document.getElementById("main-storage-dev-ssd").innerHTML = "<b>" + device_ssd + " / " + niceSizeSSD + "</b>";

		document.getElementById("main-storage-dev-online").innerHTML = "<b>" + device_online + "</b>";
		document.getElementById("main-storage-dev-offline").innerHTML = "<b>" + device_offline + "</b>";
	}
	else{
		log_write_json("stor_conf_device_process_new", "[EMPTY]", device);
	}

}

//
//
//
function stor_conf_pool_process(pool){
	log_write_json("stor_conf_pool_process_new", "[TOP]", pool);
	
	var tbody = $("#storagePoolTable tbody");
	
	if((typeof pool !== 'undefined')){
		const poolName = pool.id.name;
		const poolHost = pool.owner.name;
		const poolDev = pool.device.name
		
		// check if in cluster
		if((typeof pool.object.meta !== 'undefined') && (typeof pool.object.meta.ver !== 'undefined')){
			log_write_json("stor_conf_pool_process_new", "[TOP]", "POOL [" + poolName + "] IN CLUSTER\n");
			
			var poolOnline = view_health_color_status("ONLINE");
			var poolHealth = "";
			
			//check for owner stats
			if(((typeof pool.meta !== 'undefined') &&  typeof pool.meta.stats !== 'undefined') && (typeof pool.meta.stats[poolHost] !== 'undefined')){
				log_write_json("stor_conf_pool_process_new", "[TOP]", "POOL [" + poolName + "] HAS OWNER STATS\n");
				poolHealth = view_health_color_status("HEALTHY");
			}
			else{
				log_write_json("stor_conf_pool_process_new", "[TOP]", "POOL [" + poolName + "] HAS NO OWNER STATS\n");
				poolHealth = view_health_color_status("WARNING");
			}
			
			var diff = date_str_diff_now(pool.object.meta.date);

			if($('#switchStorShowOnline').prop('checked')){
			
				tbody.append("<tr><td>" + pool.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storpooltbl" class="btn btn-link tablebtn">' + poolName  + "</a></b>" + "</td><td><b>" + pool.object.class + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storpoolhosttbl" class="btn btn-link tablebtn">' + poolHost  + "</a></b>" + "</td><td><b>" + view_color_boolean(pool.pool.shared) + "</b></td><td>" + pool.pool.backing + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storpooldevtbl" class="btn btn-link tablebtn">' + poolDev  + "</a></b>" + "</td><td>" + pool.object.meta.ver + "</td><td><b>" + diff + "</b></td><td>" + poolOnline + "</td><td>" + poolHealth + "</td><td>" + '<b style="color:#24be14">CLUSTER</b>' + "</td><tr>");
				
				document.getElementById("tempbtn_storpooltbl").id = "btn_storpool_" + poolName;
				document.getElementById("btn_storpool_" + poolName).onclick = function() { stor_show_pool(poolName) }; 			
				
				document.getElementById("tempbtn_storpoolhosttbl").id = "btn_storpoolhost_" + poolName;
				document.getElementById("btn_storpoolhost_" + poolName).onclick = function() { node_show(poolHost) };
			
				document.getElementById("tempbtn_storpooldevtbl").id = "btn_storpooldev_" + poolName + "_" + poolDev;
				document.getElementById("btn_storpooldev_" + poolName + "_" + poolDev).onclick = function() { stor_show_device(poolDev) };
			
			}
			
		}
		else{
			log_write_json("stor_conf_pool_process_new", "[TOP]", "POOL [" + poolName + "] NOT IN CLUSTER\n");
			
			if($('#switchStorShowOffline').prop('checked')){
			
				tbody.append("<tr><td>" + pool.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storpooltbl" class="btn btn-link tablebtn">' + poolName  + "</a></b>" + "</td><td><b>" + pool.object.class + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storpoolhosttbl" class="btn btn-link tablebtn">' + poolHost  + "</a></b>" + "</td><td><b>" + view_color_boolean(pool.pool.shared) + "</b></td><td>" + pool.pool.backing + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storpooldevtbl" class="btn btn-link tablebtn">' + poolDev  + "</a></b>" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td><b>" + "LOCAL" + "</b></td><tr>");
				
				document.getElementById("tempbtn_storpooltbl").id = "btn_storpool_" + poolName;		
				document.getElementById("btn_storpool_" + poolName).onclick = function() { stor_show_pool(poolName) }; 
				
				document.getElementById("tempbtn_storpoolhosttbl").id = "btn_storpoolhost_" + poolName;
				document.getElementById("btn_storpoolhost_" + poolName).onclick = function() { node_show(poolHost) }; 
			
				document.getElementById("tempbtn_storpooldevtbl").id = "btn_storpooldev_" + poolName + "_" + poolDev;
				document.getElementById("btn_storpooldev_" + poolName + "_" + poolDev).onclick = function() { stor_show_device(poolDev) };
			}
		}
		
	}
	else{
		log_write_json("stor_conf_pool_process_new", "[EMPTY]", pool);
	}

}

function storage_menu_add_device(devname) {
	const func = function() { stor_show_device(devname) };
	menu_add_item(devname, 'collapse-storage-device', "stordev_" + devname, "bi-hdd", func);
}

function storage_menu_add_pool(devname) {
	const func = function() { stor_show_pool(devname) };
	menu_add_item(devname, 'collapse-storage-pool', "storpool_" + devname, "bi-server", func);
}

function storage_menu_add_iso(devname) {
	const func = function() { stor_show_iso(devname) };
	menu_add_item(devname, 'collapse-storage-iso', "storiso_" + devname, "bi-vinyl", func);
}

//
// clear storage menu
//
function storage_menu_remove_all() {
	storage_menu_remove_devices;
	storage_menu_remove_iso;
	storage_menu_remove_pool;
}

function storage_menu_remove_device() {
	document.getElementById("collapse-storage-device").innerHTML = "";
}

function storage_menu_remove_iso() {
	document.getElementById("collapse-storage-iso").innerHTML = "";
}

function storage_menu_remove_pool() {
	document.getElementById("collapse-storage-pool").innerHTML = "";
}
