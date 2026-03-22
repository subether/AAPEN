/**
 * ETHER|AAPEN|WEB - LIB|NODE
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

// Global state variables
let node_dev_hdd = 0;
let node_dev_ssd = 0;
let node_ssd_size = 0;
let node_hdd_size = 0;
let node_dev_tot = 0;
let node_dev_raid = 0;
let node_dev_disk = 0;

let node_pool_num = 0;
let node_pool_owner = 0;
let node_pool_subs = 0;
let node_pool_size_tot = 0;
let node_pool_size_used = 0;
let node_pool_size_free = 0;

// Resource tracking variables
let resCpuCoreTotal = 0;
let resCpuCoreAlloc = 0;
let resCpuLoadTotal = 0;
let resCpuAgg = 0;
let resCpuLoad1 = 0;
let resCpuLoad5 = 0;
let resCpuLoad15 = 0;

let resMemAvailTotal = 0;
let resMemUsedTotal = 0;
let resMemFreeTotal = 0;
let resHyperCpuAlloc = 0;
let resHyperMemAlloc = 0;
let resNodeOnlineTotal = 0;
let resNodeOfflineTotal = 0;


//
//
//
function node_service_start(nodeName, serviceName){
	var packet = {};
	packet['url'] = '/service/framework/service/start';
	packet['name'] = nodeName;
	packet['service'] = serviceName;
	packet['caller'] = 'node_service_start';
	
	console.log(packet);
	api_post_request_callback_new(packet);
}

//
//
//
function node_service_stop(nodeName, serviceName){
	var packet = {};
	packet['url'] = '/service/framework/service/stop';
	packet['name'] = nodeName;
	packet['service'] = serviceName;
	packet['caller'] = 'node_service_stop';
	
	console.log(packet);
	api_post_request_callback_new(packet);
}

//
//
//
function node_check_master_new(db, nodeName) {

	if(db.service.monitor && db.service.monitor !== "" && db.service.monitor.db[nodeName] && db.service.monitor.db[nodeName] !== ""){
		
		if(db.service.monitor.db[nodeName].config.master == 1){
			console.log("MONITOR [" + nodeName + "] IS MASTER");
			api_master_set(nodeName);
		}
	}
}

//
//
//
function node_db_process_rest_new(db) {
    const fid = "node_conf_process_rest_new";
    
	let nodeNumOnline = 0;
	let nodeNumOffline = 0;
    
    // clear menu
    node_menu_remove_online();
    node_menu_remove_offline();
    cluster_menu_remove_nodes();
    
    // process nodes
    const node_index = db.node.index;
    var nodeList = node_index.split(';');
    nodeList = sort_alpha(nodeList);
    
	nodeList.forEach((nodeName) => {        
        dbnew_node_index_add(nodeName);
         
        // check node state
        if(db.node.db[nodeName].meta && db.node.db[nodeName].meta.state !== ""){

			if(db.node.db[nodeName].meta.state == 1){
				// online nodes
				dbnew_node_index_online_add(nodeName);
				node_menu_add_online(nodeName);
                node_menu_add_clusternode_online(nodeName);
				nodeNumOnline++;
				
				node_check_master_new(db, nodeName);
			}
			else{
				// offline nodes
				dbnew_node_index_offline_add(nodeName);
				node_menu_add_offline(nodeName);
				nodeNumOffline++;
			}
			
		}
		else{
			console.log("NODE STATE FAILURE!");
		}

	});   
    
    // add the node headers
	document.getElementById('main-card-node').innerHTML = `Online Nodes [<b>${nodeNumOnline}</b>]<br/>Offline Nodes [<b>${nodeNumOffline}</b>]`;
	document.getElementById('menu-node-online').innerHTML = `Online (${nodeNumOnline})`;
	document.getElementById('menu-node-offline').innerHTML = `Offline (${nodeNumOffline})`;
	document.getElementById('menu-cluster-online').innerHTML = `Nodes (${nodeNumOnline})`;
    
    cluster_health_find();
    
}

/**
 * Shows the main node view
 */
/**
 * Shows the main node view
 * @returns {void}
 */
function node_show() {
    main_hide_all();
    main_node_show();
}

/**
 * Refreshes node data via API
 * @param {string} nodeName - Name of node to refresh
 * @returns {void}
 */
function node_refresh(nodeName) {
    mainRefreshAllViews();
}

/**
 * Initializes node view UI elements
 */
function init_node_view_ui() {
	// Clear all progress bars
	document.getElementById("nodeCpuProgress").style.width = "0%";
	document.getElementById("nodeCpuProgress").innerHTML = "<b>0 %</b>";
	document.getElementById("nodeMemProgress").style.width = "0%";
	document.getElementById("nodeMemProgress").innerHTML = "<b>0 %</b>";
	document.getElementById("nodeSwapProgress").style.width = "0%";
	document.getElementById("nodeSwapProgress").innerHTML = "<b>0 %</b>";
	document.getElementById("nodeHyperCoreProgress").style.width = "0%";
	document.getElementById("nodeHyperCoreProgress").innerHTML = "<b>0 %</b>";
	document.getElementById("nodeHyperMemProgress").style.width = "0%";
	document.getElementById("nodeHyperMemProgress").innerHTML = "<b>0 %</b>";
	document.getElementById("nodeHyperCpuLoadProgress").style.width = "0%";
	document.getElementById("nodeHyperCpuLoadProgress").innerHTML = "<b>0 %</b>";
	document.getElementById("nodeHyperMemLoadProgress").style.width = "0%";
	document.getElementById("nodeHyperMemLoadProgress").innerHTML = "<b>0 %</b>";

	// Clear all table data
	$("#nodeSystemTable tbody tr").remove();
	$("#nodeCpuExtendedTable tbody tr").remove();
	$("#nodeCpuLoadTable tbody tr").remove();
	$("#nodeCpuSensorTable tbody tr").remove();
	$("#nodeMemTable tbody tr").remove();
	$("#nodeSwapTable tbody tr").remove();
	$("#nodeHyperTable tbody tr").remove();
	$("#nodeVMMTable tbody tr").remove();
	$("#nodeFrameworkTable tbody tr").remove();
	$("#nodeNumaTable tbody tr").remove();
	$("#nodeNetStatsTable tbody tr").remove();
	$("#nodeNetworkTable tbody tr").remove();
	$("#nodeStorageServiceTable tbody tr").remove();
	$("#nodeStorageDeviceTable tbody tr").remove();
	$("#nodeStoragePoolTable tbody tr").remove();
	$("#nodeFrameworkServiceTable tbody tr").remove();
	

	// Reset headers to default state
	document.getElementById("node-network-status-header").innerHTML = "Network [<b>OFFLINE</b>]";
	document.getElementById("node-network-infiniband-header").innerHTML = "Infiniband [<b>n/a</b>]";
	document.getElementById("node-network-header").innerHTML = "Networks [<b>n/a</b>]";
	document.getElementById("node-network-device-header").innerHTML = "Devices [<b>n/a</b>]";
	document.getElementById("node-hyper-header").innerHTML = "Hypervisor [<b>OFFLINE</b>]";
	document.getElementById("node-hypervisor-system-header").innerHTML = "Systems [<b>n/a</b>]";
	document.getElementById("node-framework-header").innerHTML = "Framework [<b>OFFLINE</b>]";
	document.getElementById("node-vmm-header").innerHTML = "VMMs [<b>n/a</b>]";
	document.getElementById("node-vmm-header").innerHTML = "Services [<b>n/a</b>]";
	document.getElementById("node-hypervisor-async-header").innerHTML = "System Async Jobs [<b>n/a</b>]";
	document.getElementById("node-storage-header").innerHTML = "Storage [<b>n/a</b>]";
	document.getElementById("node-storage-device-header").innerHTML = "Devices [<b>n/a</b>]";
	document.getElementById("node-storage-pool-header").innerHTML = "Pools [<b>n/a</b>]";
}

/**
 * Resets node statistics counters
 */
function reset_node_stats() {
	node_dev_hdd = 0;
	node_dev_ssd = 0;
	node_ssd_size = 0;
	node_hdd_size = 0;
	node_dev_tot = 0;
	node_dev_raid = 0;
	node_dev_disk = 0;
	
	node_pool_num = 0;
	node_pool_size_owner = 0;
	node_pool_size_subs = 0;
	node_pool_size_tot = 0;
	node_pool_size_used = 0;
	node_pool_size_free = 0;
}

//
//
//
function node_show(nodeName) {
	main_hide_all();
	main_node_show();
	
	reset_node_stats();
	init_node_view_ui();
	
	var nodeData = dbnew_node_get(nodeName);
	
	main_view_set('node_show', nodeName, '');
	
	document.getElementById("main-node-btn-json").onclick = function() { json_show("[ " + nodeName + " ]", nodeName, "node", nodeData) };
	
	document.getElementById("main-node-header").textContent = `[${nodeName}]`;

	document.getElementById("main-node-identity").innerHTML = `
		Node [<b style="color:#0040ff">${nodeData.id.name}</b>]
		id [<b>${nodeData.id.id}</b>]
		group [<b>${nodeData.id.group}</b>]
		cluster [<b>${nodeData.id.cluster}</b>]
		desc [<b>${nodeData.id.desc}</b>]`;

	// Populate node config table
	$("#nodeConfigTable tbody tr").remove();	
	var tbodyNodeConfig = $("#nodeConfigTable tbody");
	tbodyNodeConfig.append(
		`<tr>
			<td>${nodeData.id.id}</td>
			<td><b>${nodeData.id.name}</b></td>
			<td>${nodeData.id.group}</td>
			<td>${nodeData.id.cluster}</td>
			<td>${nodeData.id.desc}</td>
			<td>${nodeData.agent.address}</td>
			<td>${nodeData.agent.port}</td>
		</tr>`
	);

	// cpu table
	$("#nodeCpuTable tbody tr").remove();	
	var tbodyCpu = $("#nodeCpuTable tbody");	
	
	// service table
	$("#nodeStatusServiceTable tbody tr").remove();	
	var tbodyService = $("#nodeStatusServiceTable tbody");
	
	
	// ipmi
	if(nodeData.access && nodeData.access.ipmi){
		document.getElementById("main-node-btn-ipmi").onclick = function() { main_open_url(nodeData.access.ipmi.url) };
		$('#main-node-btn-ipmi').prop('disabled', false);
	}
	else{
		$('#main-node-btn-ipmi').prop('disabled', true);
	}

	

	// state
	if(nodeData.meta.state == 1 || nodeData.meta.state == 2){
		document.getElementById("main-node-btn-refresh").onclick = function() { node_refresh(nodeName); };

		var diff = date_str_diff_now(nodeData.object.meta.date);
	
		if(typeof nodeData.object.meta !== 'undefined' && nodeData.meta.state == 1){
			var status = view_color_healthy("ONLINE");
			document.getElementById("main-node-state").innerHTML = 'State [' + status + ']' + " ver [<b>" + nodeData.object.meta.ver + "</b>] updated [<b>" + nodeData.object.meta.date + "</b>] delta [<b>" + diff + "</b>]";
		}
		else if(typeof nodeData.object.meta !== 'undefined' && nodeData.meta.state == 2){
			var status = view_color_warning(node.config.meta.status);
			document.getElementById("main-node-state").innerHTML = 'State [' + status + ']' + " ver [<b>" + nodeData.object.meta.ver + "</b>] updated [<b>" + nodeData.object.meta.date + "</b>] delta [<b>" + diff + "</b>]";
		}
		else{
			var status = view_color_warning("WARNING");
			document.getElementById("main-node-state").innerHTML = 'State [' + status + ']';
		}
		
		// simple hardware header (replaced by hypervisor if present)
		if(typeof nodeData.object.meta !== 'undefined'){
			var load_1 = parseFloat(nodeData.hw.stats.load[1]).toFixed(2);
			var load_5 = parseFloat(nodeData.hw.stats.load[5]).toFixed(2);
			var load_15 = parseFloat(nodeData.hw.stats.load[15]).toFixed(2);
			
			// processor
			var cpu = "Processor [<b>" + nodeData.hw.cpu.type + "</b>] cores [<b>" + nodeData.hw.cpu.core + "</b>]";
			var load = " - load [<b>" + load_1 + " / " + load_5 + " / " + load_15 + "</b>]";
			document.getElementById("node-hardware-header").innerHTML = cpu + load;
			
			var cpuUsePerc = 100 - parseFloat(nodeData.hw.stats.cpu.idle)
			document.getElementById("nodeCpuProgress").style.width = cpuUsePerc + "%";
			document.getElementById("nodeCpuProgress").innerHTML = "<b>" + cpuUsePerc.toFixed(1) + " %</b>";
			
			// memory
			var mem = "Memory [<b>" + niceMBytes(nodeData.hw.stats.mem.total) + "</b>]";
			var memstats = " - used [<b>" + niceMBytes(nodeData.hw.stats.mem.used) + "</b>] free [<b>" + niceMBytes(nodeData.hw.stats.mem.free) + "</b>]"
			document.getElementById("node-hardware-stats").innerHTML = mem + memstats;
			
			//
			// MEMORY
			//
			var memUsedPerc = parseInt(nodeData.hw.stats.mem.used) / parseInt(nodeData.hw.stats.mem.total) * 100;
			document.getElementById("nodeMemProgress").style.width = memUsedPerc + "%";
			document.getElementById("nodeMemProgress").innerHTML = "<b>" + memUsedPerc.toFixed(1) + " %</b>";

			// uptime
			document.getElementById("main-node-state").innerHTML += " uptime [<b>" + nodeData.hw.stats.uptime + "</b>]"
			
			// cpu table
			tbodyCpu.append("<tr><td><b>" + nodeData.hw.cpu.type + "</b></td><td>" +  nodeData.hw.cpu.core + "</td><td>" +  nodeData.hw.stats.cpu.wait + " %</td><td>" +  nodeData.hw.stats.cpu.idle + " %</td><td><b>" + load_1 + " / " + load_5 + " / " + load_15 + "</b></td><td>" + nodeData.hw.stats.uptime + "</td></tr>");
			
			// cluster service
			tbodyService.append("<tr><td><b>" + "cluster" + "</b></td><td>" +  nodeData.object.meta.ver + "</td><td>" +  nodeData.object.meta.date + "</td><td>" +  diff + "</td></tr>");
			
			//
			// SERVICES
			//
			
			//hypervisor
			var serviceHypervisorData = dbnew_service_node_get("hypervisor", nodeName);
			if(serviceHypervisorData){
				var diff = date_str_diff_now(serviceHypervisorData.updated);
				tbodyService.append("<tr><td><b>" + "hypervisor" + "</b></td><td>" +  serviceHypervisorData.object.meta.ver + "</td><td>" +  serviceHypervisorData.object.meta.date + "</td><td>" +  diff + "</td></tr>");
				node_view_service_hypervisor(nodeName, serviceHypervisorData);
			}
			
			//network
			var serviceNetworkData = dbnew_service_node_get("network", nodeName);
			if(serviceNetworkData){
				var diff = date_str_diff_now(serviceNetworkData.updated);
				tbodyService.append("<tr><td><b>" + "network" + "</b></td><td>" +  serviceNetworkData.object.meta.ver + "</td><td>" +  serviceNetworkData.object.meta.date + "</td><td>" +  diff + "</td></tr>");
				node_view_service_network(nodeName, serviceNetworkData)
			}

			//storage
			var serviceStorageData = dbnew_service_node_get("storage", nodeName);
			if(serviceStorageData){
				var diff = date_str_diff_now(serviceStorageData.updated);
				tbodyService.append("<tr><td><b>" + "storage" + "</b></td><td>" +  serviceStorageData.object.meta.ver + "</td><td>" +  serviceStorageData.object.meta.date + "</td><td>" +  diff + "</td></tr>");
				node_view_service_storage(nodeName, serviceStorageData)
			}
			
			//framework
			var serviceFrameworkData = dbnew_service_node_get("framework", nodeName);
			if(serviceFrameworkData){
				var diff = date_str_diff_now(serviceFrameworkData.updated);
				tbodyService.append("<tr><td><b>" + "framework" + "</b></td><td>" +  serviceFrameworkData.object.meta.ver + "</td><td>" +  serviceFrameworkData.object.meta.date + "</td><td>" +  diff + "</td></tr>");
				node_view_service_framework(nodeName, serviceFrameworkData);
			}
			
			// there are more services...
			
		}
		
	}
	else{
		document.getElementById("main-node-state").innerHTML = "State [<b>OFFLINE</b>]";
		document.getElementById("main-node-btn-refresh").onclick = function() { node_show(nodeName); };
	}
	
}

//
//
//
function node_view_service_hypervisor(nodeName, serviceHypervisorData){

	//
	// CPU
	//
	var cpu = "Processor [<b>" + serviceHypervisorData.hw.cpu.type + "</b>] sockets [<b>" + serviceHypervisorData.hw.cpu.sock + "</b>] cores [<b>" + serviceHypervisorData.hw.cpu.core + "</b>]";
    
    // Load averages
    var load = " - load [<b>" + parseFloat(serviceHypervisorData.hw.stats.load[1].toFixed(2)) + " / " + parseFloat(serviceHypervisorData.hw.stats.load[5]).toFixed(2) + " / " + parseFloat(serviceHypervisorData.hw.stats.load[15]).toFixed(2) + "</b>]";
    
    // CPU stats
    var cpustats = " wait [<b>" + serviceHypervisorData.hw.stats.cpu.wait + "%</b>] idle [<b>" + serviceHypervisorData.hw.stats.cpu.idle + "%</b>]";
    
    // Update header
    document.getElementById("node-hardware-header").innerHTML = cpu + load + cpustats;
    
    // Update CPU usage progress bar
    var cpuUsePerc = 100 - parseFloat(serviceHypervisorData.hw.stats.cpu.idle);
    document.getElementById("nodeHyperCpuLoadProgress").style.width = cpuUsePerc + "%";
    document.getElementById("nodeHyperCpuLoadProgress").innerHTML = "<b>" + cpuUsePerc.toFixed(1) + " %</b>";
	
	//
	// MEMORY
	//
	
    var mem = "Memory [<b>" + niceMBytes(serviceHypervisorData.hw.mem.mb) + "</b>]";
    
    var memstats;
    
    var swap;
    
    if(typeof serviceHypervisorData.hw.stats.mem.swap_used !== 'undefined'){
		swap = " - Swap total [<b>" + serviceHypervisorData.hw.stats.mem.swap_total + " " + 
               serviceHypervisorData.hw.stats.mem.unit + "</b>] used [<b>" + 
               serviceHypervisorData.hw.stats.mem.swap_used + " " + serviceHypervisorData.hw.stats.mem.unit + 
               "</b>] free [<b>" + serviceHypervisorData.hw.stats.mem.swap_free + " " + 
               serviceHypervisorData.hw.stats.mem.unit + "</b>]";
               
			   memstats = " - used [<b>" + serviceHypervisorData.hw.stats.mem.used + " MB</b>] free [<b>" + serviceHypervisorData.hw.stats.mem.free + " MB</b>]";
	}
	else{
		swap = " - Swap total [<b>" + serviceHypervisorData.hw.stats.swap.total + " " + 
               serviceHypervisorData.hw.stats.swap.unit + "</b>] used [<b>" + 
               serviceHypervisorData.hw.stats.swap.used + " " + serviceHypervisorData.hw.stats.swap.unit + 
               "</b>] free [<b>" + serviceHypervisorData.hw.stats.swap.free + " " + 
               serviceHypervisorData.hw.stats.swap.unit + "</b>]";
	
	    memstats = " - used [<b>" + niceMBytes(serviceHypervisorData.hw.stats.mem.used) + "</b>] free [<b>" + niceMBytes(serviceHypervisorData.hw.stats.mem.free) + "</b>]";
	}
    
    // Update stats display
    document.getElementById("node-hardware-stats").innerHTML = mem + memstats + swap;	

	// hypervisor header
	var hyper = " - model [<b>" + "QEMU/KVM" + "</b>] kvm [<b>" + serviceHypervisorData.hw.cpu.kvm + "</b>] active [<b>" + serviceHypervisorData.hw.cpu.kvmstate + "</b>]";

	var diff = date_str_diff_now(serviceHypervisorData.updated);
	
	var hyperstats = " - ver [<b>" + serviceHypervisorData.object.meta.ver + "</b>] updated [<b>" + serviceHypervisorData.updated + "</b>] delta [<b>" + diff + "</b>]";
	
	document.getElementById("node-hyper-header").innerHTML = 'Hypervisor [<b style="color:#24be14">ONLINE</b>]' + hyper + hyperstats;
	
	
	// cpu info table
	var tbodyCpuExt = $("#nodeCpuExtendedTable tbody");
	tbodyCpuExt.append("<tr><td><b>" + serviceHypervisorData.hw.cpu.type + "</b></td><td>" + serviceHypervisorData.hw.cpu.arch + "</td><td>" + serviceHypervisorData.hw.cpu.sock + "</td><td>" + serviceHypervisorData.hw.cpu.core + "</td><td>" + serviceHypervisorData.hw.cpu.speed + "</td><td>" + serviceHypervisorData.hw.cpu.kvm + "</td><td>" + serviceHypervisorData.hw.cpu.kvmstate + "</td><tr>");
	
	// cpu load table
	var tbodyCpuLoadTable = $("#nodeCpuLoadTable tbody");
	//tbodyCpuLoadTable.append("<tr><td>" + data.hw.stats.cpu.user + "</td><td>" + data.hw.stats.cpu.system + "</td><td>" + data.hw.stats.cpu.nice + '</td><td><b style="color:#24be14">' + data.hw.stats.cpu.idle + "</b></td><td><b>" + data.hw.stats.cpu.wait + "</b></td><td>" + data.hw.stats.cpu.steal + "</td><td>" + data.hw.stats.cpu.soft + "</td><td>" + data.hw.stats.cpu.hard + "</td><td>" + data.hw.stats.tasks.total + "</td><td>" + data.hw.stats.tasks.running + "</td><td>" + data.hw.stats.tasks.sleeping + "</td><td>" + data.hw.stats.tasks.stopped + "</td><td>" + data.hw.stats.tasks.zombie + "</td><tr>");
	tbodyCpuLoadTable.append("<tr><td>" + serviceHypervisorData.hw.stats.cpu.user + "</td><td>" + serviceHypervisorData.hw.stats.cpu.system + "</td><td>" + serviceHypervisorData.hw.stats.cpu.nice + '</td><td><b style="color:#24be14">' + serviceHypervisorData.hw.stats.cpu.idle + "</b></td><td><b>" + serviceHypervisorData.hw.stats.cpu.wait + "</b></td><td>" + serviceHypervisorData.hw.stats.cpu.steal + "</td><td>" + serviceHypervisorData.hw.stats.tasks.total + "</td><td>" + serviceHypervisorData.hw.stats.tasks.running + "</td><td>" + serviceHypervisorData.hw.stats.tasks.sleeping + "</td><td>" + serviceHypervisorData.hw.stats.tasks.stopped + "</td><td>" + serviceHypervisorData.hw.stats.tasks.zombie + "</td><tr>");

	// memory table
	var tbodyNodeMem = $("#nodeMemTable tbody");
	tbodyNodeMem.append("<tr><td><b>" + serviceHypervisorData.hw.mem.mb + " MB</b></td><td>" + serviceHypervisorData.hw.stats.mem.total + " " + serviceHypervisorData.hw.stats.mem.unit + "</td><td>" + serviceHypervisorData.hw.stats.mem.used + " " + serviceHypervisorData.hw.stats.mem.unit + "</td><td>" + serviceHypervisorData.hw.stats.mem.cache + " " + serviceHypervisorData.hw.stats.mem.unit + "</td><td><b>" + serviceHypervisorData.hw.stats.mem.free + " " + serviceHypervisorData.hw.stats.mem.unit + "</b></td><tr>");
	
	// swap table
	var tbodyNodeSwap = $("#nodeSwapTable tbody");
	
	if(typeof serviceHypervisorData.hw.stats.mem.swap_used !== 'undefined'){
		tbodyNodeSwap.append("<tr><td><b>" + serviceHypervisorData.hw.stats.mem.swap_total + " " + serviceHypervisorData.hw.stats.mem.unit + "</b></td><td>" + serviceHypervisorData.hw.stats.mem.swap_used + " " + serviceHypervisorData.hw.stats.mem.unit + "</td><td><b>" + serviceHypervisorData.hw.stats.mem.swap_free + " " + serviceHypervisorData.hw.stats.mem.unit + "</b></td><tr>");
	}
	else{
		tbodyNodeSwap.append("<tr><td><b>" + serviceHypervisorData.hw.stats.swap.total + " " + serviceHypervisorData.hw.stats.swap.unit + "</b></td><td>" + serviceHypervisorData.hw.stats.swap.used + " " + serviceHypervisorData.hw.stats.swap.unit + "</td><td><b>" + serviceHypervisorData.hw.stats.swap.free + " " + serviceHypervisorData.hw.stats.swap.unit + "</b></td><tr>");
	}

	// fix undefines (todo backend)
	var cpualloc = 0;
	var memalloc = 0;
	var syslist = "";
	var syslock = ""

	// fix undefined values
	if(typeof serviceHypervisorData.hyper == 'undefined'){
		serviceHypervisorData.hyper = {};
		serviceHypervisorData.hyper.cpualloc = 0;
		serviceHypervisorData.hyper.memalloc = 0;
		serviceHypervisorData.hyper.systems = 0;
		serviceHypervisorData.hyper.lock = 0;
	}
	

	// hypervisor table
	var tbodyNodeHyper = $("#nodeHyperTable tbody");
	tbodyNodeHyper.append("<tr><td>" + serviceHypervisorData.config.id + "</td><td>" + serviceHypervisorData.config.name + "</td><td>" + serviceHypervisorData.config.addr + "</td><td><b>" + serviceHypervisorData.hyper.cpualloc + "</b></td><td><b>" + serviceHypervisorData.hyper.memalloc + " MB</b></td><td>" + serviceHypervisorData.hyper.systems + "</td><td>" + serviceHypervisorData.hyper.lock + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_hyper_show" class="btn btn-link tablebtn">' + "[show]" + "</a></b></td><tr>");
	
	// service json show
	document.getElementById("tempbtn_hyper_show").id = "btn_node_hypertbl_" + serviceHypervisorData.config.name;
	document.getElementById("btn_node_hypertbl_" + serviceHypervisorData.config.name).onclick = function() { json_show("[ " + nodeName + " | hypervisor ]", nodeName, "node", serviceHypervisorData) };
	
	//
	// NUMA
	//
	if((typeof serviceHypervisorData.hw.numa !== 'undefined') && (serviceHypervisorData.hw.numa != null)){
		var numa_index = serviceHypervisorData.hw.numa.index;
		numaList = numa_index.split(';');
		numaList.sort(function(a, b){ return a - b });
	
		var tbodyNuma = $("#nodeNumaTable tbody");
	
		numaList.forEach((numa) => {
			tbodyNuma.append("<tr><td><b>" + numa + "</b></td><td><b>" + serviceHypervisorData.hw.numa[numa].core.num + "</b></td><td>" + serviceHypervisorData.hw.numa[numa].core.index + "</td><td><b>" + serviceHypervisorData.hw.numa[numa].mem.tot + " MB" + "</b></td><td><b>" + serviceHypervisorData.hw.numa[numa].mem.free + " MB" + "</b></td><tr>");
			
		});				
	}

	//
	// MEMORY
	//
	var memLoadPerc = parseInt(serviceHypervisorData.hw.stats.mem.used) / parseInt(serviceHypervisorData.hw.stats.mem.total) * 100;
	document.getElementById("nodeHyperMemLoadProgress").style.width = memLoadPerc + "%";
	document.getElementById("nodeHyperMemLoadProgress").innerHTML = "<b>" + memLoadPerc.toFixed(1) + " %</b>";

	var memFree = serviceHypervisorData.hw.stats.mem.total;
	var memFreePerc = 100;
	var memUsedPerc = 0;

	if((typeof serviceHypervisorData.hyper !== 'undefined') && serviceHypervisorData.hyper !== null){
		memFree = parseInt(serviceHypervisorData.hw.stats.mem.total) - parseInt(serviceHypervisorData.hyper.memalloc);
		memFreePerc = (100 * memFree) / parseInt(serviceHypervisorData.hw.stats.mem.total);
		memUsedPerc = (100 - memFreePerc);
	}

		
	var swapUsedPerc = 0;
	
	if(typeof serviceHypervisorData.hw.stats.mem.swap_used !== 'undefined'){
		swapUsedPerc = parseInt(serviceHypervisorData.hw.stats.mem.swap_used) /  parseInt(serviceHypervisorData.hw.stats.mem.swap_total) * 100;
	}
	else{
		swapUsedPerc = parseInt(serviceHypervisorData.hw.stats.swap.used) /  parseInt(serviceHypervisorData.hw.stats.swap.total) * 100;	
	}
	
	document.getElementById("nodeSwapProgress").style.width = swapUsedPerc + "%";
	document.getElementById("nodeSwapProgress").innerHTML = "<b>" + swapUsedPerc.toFixed(1) + " %</b>";
	
	//
	// CPU
	//
	var cpuHyperAlloc = 0;
	var cpuHyperAllocPerc = 0;
	
	if((typeof serviceHypervisorData.hyper !== 'undefined') && serviceHypervisorData.hyper !== null){
	
		cpuHyperAlloc =  parseInt(serviceHypervisorData.hyper.cpualloc) / (parseInt(serviceHypervisorData.hw.cpu.core) * parseInt(serviceHypervisorData.hw.cpu.sock));
		cpuHyperAllocPerc = cpuHyperAlloc * 100;
	
	}
	
	document.getElementById("nodeHyperCoreProgress").style.width = cpuHyperAllocPerc + "%";
	document.getElementById("nodeHyperCoreProgress").innerHTML = "<b>" + cpuHyperAllocPerc.toFixed(1) + " %</b>";
	
	document.getElementById("nodeHyperMemProgress").style.width = memUsedPerc + "%";
	document.getElementById("nodeHyperMemProgress").innerHTML = "<b>" + memUsedPerc.toFixed(1) + " %</b>";
	
	//
	// HYPERVISOR
	//
	$("#nodeSystemTable tbody tr").remove();
	var tbody = $("#nodeSystemTable tbody");

	if((serviceHypervisorData.hyper !== null) && (typeof serviceHypervisorData.hyper.lock !== 'undefined') && (typeof serviceHypervisorData.hyper.lock !== "")){
		
		document.getElementById("node-hypervisor-system-header").innerHTML = "Systems [<b>" + serviceHypervisorData.hyper.systems + "</b>] - cores allocated [<b>" + serviceHypervisorData.hyper.cpualloc + "</b>] - memory allocated [<b>" + serviceHypervisorData.hyper.memalloc + " MB</b>] / [<b>" + Math.trunc(memUsedPerc) + "%</b>] - memory available [<b>" + memFree + " MB</b>] / [<b>" + Math.trunc(memFreePerc) + "%</b>]";

		var sys_index = serviceHypervisorData.hyper.lock;
		systemList = sys_index.split(';');
		systemList.sort(function(a, b){ return a - b });
		
		var sysnum = 0;
		
		systemList.forEach((system) => {
			
			if((serviceHypervisorData.stats[system] !== null) && (typeof serviceHypervisorData.stats[system] !== 'undefined')){
				
				//calculate delta
				var diff = date_str_diff_now(serviceHypervisorData.stats[system].updated);
				
				tbody.append("<tr><td><b>" + system + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_system" class="btn btn-link tablebtn">' + serviceHypervisorData.stats[system].id.name + "</a></b></td><td>" + serviceHypervisorData.stats[system].id.group + "</td><td>" + serviceHypervisorData.stats[system].pid + "</td><td>" + serviceHypervisorData.stats[system].uptime + "</td><td>" + serviceHypervisorData.stats[system].updated + "</td><td>" + diff + "</td><td><b>" + serviceHypervisorData.stats[system].cpu + "%</b></td><td><b>" + serviceHypervisorData.stats[system].mem + "%</b></td><td><b>" + serviceHypervisorData.stats[system].rss + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_reset" class="btn btn-link tablebtn">' + "[reset]" + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_shutdown" class="btn btn-link tablebtn">' + "[shutdown]" + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_unload" class="btn btn-link tablebtn">' + "[unload]" + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_console" class="btn btn-link tablebtn">' + "[console]" + "</a></b></td><tr>");
				
				// system show
				document.getElementById("tempbtn_system").id = "btn_node_systbl_" + serviceHypervisorData.stats[system].id.name;
				document.getElementById("btn_node_systbl_" + serviceHypervisorData.stats[system].id.name).onclick = function() { system_show(serviceHypervisorData.stats[system].id.name) };
				
				// system console
				document.getElementById("tempbtn_console").id = "btn_node_systbl_console_" + serviceHypervisorData.stats[system].id.name;
				document.getElementById("btn_node_systbl_console_" + serviceHypervisorData.stats[system].id.name).onclick = function() { system_novnc_open(serviceHypervisorData.stats[system].id.name); };

				// system reset
				document.getElementById("tempbtn_reset").id = "btn_node_systbl_reset_" + serviceHypervisorData.stats[system].id.name;
				document.getElementById("btn_node_systbl_reset_" + serviceHypervisorData.stats[system].id.name).onclick = function() { system_reset_accept(serviceHypervisorData.stats[system].id.name); };
				
				// system unload
				document.getElementById("tempbtn_unload").id = "btn_node_systbl_unload_" + serviceHypervisorData.stats[system].id.name;
				document.getElementById("btn_node_systbl_unload_" + serviceHypervisorData.stats[system].id.name).onclick = function() { system_unload_accept(serviceHypervisorData.stats[system].id.name); };
				
				// system reset
				document.getElementById("tempbtn_shutdown").id = "btn_node_systbl_shutdown_" + serviceHypervisorData.stats[system].id.name;
				document.getElementById("btn_node_systbl_shutdown_" + serviceHypervisorData.stats[system].id.name).onclick = function() { system_shutdown_accept(serviceHypervisorData.stats[system].id.name); };
				
				//TODO
				// CONSOLE RESTART SHUTDOWN AND ETC HERE
				
				sysnum++;
			}
			else{
				//
			}

		});
		
	}
	else{
		document.getElementById("node-hypervisor-system-header").innerHTML = "Systems [<b>Ready, no active systems</b>]";
	}	
	
	//
	// ASYNC
	//
	$("#nodeAsyncTable tbody tr").remove();
	var tbodyAsyncTable = $("#nodeAsyncTable tbody");


	if((serviceHypervisorData.hyper !== null) && (typeof serviceHypervisorData.hyper.async !== 'undefined') && (typeof serviceHypervisorData.hyper.async.index !== 'undefined')){

		var active = 0;
		var async_index = serviceHypervisorData.hyper.async.index;
		document.getElementById("node-hypervisor-async-header").innerHTML = "System Async Jobs [<b>" + async_index + "</b>]";
		asyncList = async_index.split(';');
		
		asyncList.forEach((job) => {
			if(serviceHypervisorData.hyper.async[job].active == "1"){
				tbodyAsyncTable.append("<tr><td><b>" + job + "</b></td><td>" +  job + "</a></b></td><td><b>" + serviceHypervisorData.hyper.async[job].request + "</b></td><td>" + serviceHypervisorData.hyper.async[job].on_timeout + "</td><td>" + serviceHypervisorData.hyper.async[job].timeout + "</td><td>" + '<b style="color:#0040ff">' + "ACTIVE" + "</b></td><td>" + serviceHypervisorData.hyper.async[job].date + "</td><td><b>" + serviceHypervisorData.hyper.async[job].status + "</b></td><td><b>" + serviceHypervisorData.hyper.async[job].result + "</b></td><tr>");
				active++;
			}
			else{
				tbodyAsyncTable.append("<tr><td><b>" + job + "</b></td><td>" +  job + "</a></b></td><td><b>" + serviceHypervisorData.hyper.async[job].request + "</b></td><td>" + serviceHypervisorData.hyper.async[job].on_timeout + "</td><td>" + serviceHypervisorData.hyper.async[job].timeout + "</td><td><b>INACTIVE</b></td><td>" + serviceHypervisorData.hyper.async[job].date + "</td><td><b>" + serviceHypervisorData.hyper.async[job].status + "</b></td><td><b>" + serviceHypervisorData.hyper.async[job].result + "</b></td><tr>");
			}

		});
		
		document.getElementById("node-hypervisor-async-header").innerHTML = "System Async Jobs [<b>" + async_index + "</b>] active [<b>" + active + "</b>]";
	}
	else{
		document.getElementById("node-hypervisor-async-header").innerHTML = "System Async Jobs [<b>" + "Inactive" + "</b>]";
		
	}

	//
	// coretemp
	//
	if((typeof serviceHypervisorData.hw !== 'undefined') && (typeof serviceHypervisorData.hw.sensors !== 'undefined') && (typeof serviceHypervisorData.hw.sensors.coretemp !== 'undefined')){
		var tbodySeonsorTable = $("#nodeCpuSensorTable tbody");

		var socketList = index_to_array(serviceHypervisorData.hw.sensors.coretemp.index);		
		socketList = sort_num(socketList);
		socketList.forEach((socket) => {
			var cores = "";
			var temps = "";
			var max = "";
			var min = "";
			
			var coreList = index_to_array(serviceHypervisorData.hw.sensors.coretemp[socket].index);
			coreList = sort_num(coreList);
			coreList.forEach((core) => {
				cores = cores + " " + core + " ";
				temps = temps + " " + serviceHypervisorData.hw.sensors.coretemp[socket][core] + " ";
			});
			
			if(parseInt(serviceHypervisorData.hw.sensors.coretemp[socket].max) < 60){
				max = view_color_healthy(serviceHypervisorData.hw.sensors.coretemp[socket].max);
			}
			else{
				max = view_color_error(serviceHypervisorData.hw.sensors.coretemp[socket].max);
			}
			
			if(parseInt(serviceHypervisorData.hw.sensors.coretemp[socket].min) < 60){
				min = view_color_healthy(serviceHypervisorData.hw.sensors.coretemp[socket].min);
			}
			else{
				min = view_color_error(serviceHypervisorData.hw.sensors.coretemp[socket].min);
			}				
			
			tbodySeonsorTable.append("<tr><td><b>" + socket + "</b></td><td>" +  cores + "</a></b></td><td><b>" + temps + "</b></td><td>" + min + "</td><td>" + max + "</td><tr>");
		});
		
	}	
	
}

//
// node service network view
//
function node_view_service_network(nodeName, serviceNetworkData){

	$("#nodeNetworkBondTable tbody tr").remove();
	$("#nodeNetworkDeviceTable tbody tr").remove();	

	$("#nodeNetworkIbHcaTable tbody tr").remove();
	$("#nodeNetworkIbPortTable tbody tr").remove();	

	var tbodyNetStatsTable = $("#nodeNetStatsTable tbody");
	
	// metadata
	var meta = "";
	if(typeof serviceNetworkData.object.meta !== 'undefined'){
		var diff = date_str_diff_now(serviceNetworkData.updated);
		meta = " - ver [<b>" + serviceNetworkData.object.meta.ver + "</b>] updated [<b>" + serviceNetworkData.updated + "</b>] delta [<b>" + diff + "</b>]";
		document.getElementById("node-network-status-header").innerHTML = 'Network [<b style="color:#24be14">ONLINE</b>]' + meta;
	}	


	if((typeof serviceNetworkData.net.index !== 'undefined') && (typeof serviceNetworkData.net.index.name !== 'undefined')){
	
		var tap = 0;
		var vlan = 0;
		var trunk = 0;
		var vpp = 0;
	
		// get index of systems
		var net_index = serviceNetworkData.net.index.name;			
		var networkList = net_index.split(';');
		networkList = sort_num(networkList);
		
		var tbody = $("#nodeNetworkTable tbody");
		
		document.getElementById("node-network-header").innerHTML = "Networks [<b>" + networkList.length + "</b>]";
		
		networkList.forEach((net) => {
			if(serviceNetworkData.net[net].model == "tap"){ tap++; };
			if(serviceNetworkData.net[net].model == "vpp"){ vpp++; };
			if(serviceNetworkData.net[net].class == "vlan"){ vlan++; };
			if(serviceNetworkData.net[net].class == "trunk"){ trunk++; };
			
			if((typeof serviceNetworkData.net[net] !== 'undefined') && (typeof serviceNetworkData.net[net].stats !== 'undefined')){
				
				if(typeof serviceNetworkData.net[net].vm !== 'undefined'){
					//tbody.append("<tr><td><b>" + serviceNetworkData.net[net].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + net + "</a></b></td><td>" + netdata.node[serviceNetworkData.config.id.id] + "</td><td>" + serviceNetworkData.net[net].model + "</td><td>" + serviceNetworkData.net[net].class + "</td><td>" + serviceNetworkData.net[net].vm.index + "</td><td><b>" + serviceNetworkData.net[net].stats.rx + "</b></td><td><b>" + serviceNetworkData.net[net].stats.tx + "</b></td><td>" + '<b style="color:#24be14">' + "CLUSTER" + "</b></td><tr>");
					tbody.append("<tr><td><b>" + serviceNetworkData.net[net].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + net + "</a></b></td><td>" + "n/a" + "</td><td>" + serviceNetworkData.net[net].model + "</td><td>" + serviceNetworkData.net[net].class + "</td><td>" + serviceNetworkData.net[net].vm.index + "</td><td><b>" + serviceNetworkData.net[net].stats.rx + "</b></td><td><b>" + serviceNetworkData.net[net].stats.tx + "</b></td><td>" + '<b style="color:#24be14">' + "CLUSTER" + "</b></td><tr>");
				}
				else{
					if(typeof netdata !== 'undefined'){
						tbody.append("<tr><td><b>" + serviceNetworkData.net[net].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + net + "</a></b></td><td>" + "n/a" + "</td><td>" + serviceNetworkData.net[net].model + "</td><td>" + serviceNetworkData.net[net].class + "</td><td>" + "" + "</td><td><b>" + serviceNetworkData.net[net].stats.rx + "</b></td><td><b>" + serviceNetworkData.net[net].stats.tx + "</b></td><td>" + '<b style="color:#24be14">' + "CLUSTER" + "</b></td><tr>");
					}
					else{
						tbody.append("<tr><td><b>" + serviceNetworkData.net[net].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + net + "</a></b></td><td>" + "n/a" + "</td><td>" + serviceNetworkData.net[net].model + "</td><td>" + serviceNetworkData.net[net].class + "</td><td>" + "" + "</td><td><b>" + serviceNetworkData.net[net].stats.rx + "</b></td><td><b>" + serviceNetworkData.net[net].stats.tx + "</b></td><td>" + '<b style="color:#24be14">' + "CLUSTER" + "</b></td><tr>");
					}

				}
				
				document.getElementById("tempbtn").id = "btn_node_netbl_" + net;
				document.getElementById("btn_node_netbl_" + net).onclick = function() { net_show(net) }; 
			}
			
		});
		
		var vppstate = "VPP [<b>disabled</b>]";
		
		// check for vpp
		if(typeof serviceNetworkData.config.vpp !== 'undefined'){
			
			if((typeof serviceNetworkData.config.vpp !== 'undefined')){
				if(serviceNetworkData.config.vpp.enabled == '1' && serviceNetworkData.config.vpp.state == '1'){
					vppstate = "VPP [<b>enabled</b>]";
					tbodyNetStatsTable.append("<tr><td>" + serviceNetworkData.config.id + "</td><td><b>" + serviceNetworkData.config.name + "</b></td><td>" + '<b style="color:#24be14">enabled</b>' + "</b></td><td>" + tap + "</td><td>" + trunk + "</td><td>" + '<b style="color:#24be14">enabled</b>' + "</b></td><td><b>" + "active" + "</b></td><td>" + vpp + "</td><td>" + serviceNetworkData.object.meta.ver + "</td><td>" + serviceNetworkData.object.meta.date + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsrv_show" class="btn btn-link tablebtn">' + "[show]" + "</a></b></td><tr>");
				}
				else{
					tbodyNetStatsTable.append("<tr><td>" + serviceNetworkData.config.id + "</td><td><b>" + serviceNetworkData.config.name + "</b></td><td>" + '<b style="color:#24be14">enabled</b>' + "</b></td><td>" + tap + "</td><td>" + trunk + "</td><td>" + '<b>enabled</b>' + "</b></td><td><b>" + "inactive" + "</b></td><td>" + "0" + "</td><td>" + serviceNetworkData.object.meta.ver + "</td><td>" + serviceNetworkData.object.meta.date + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsrv_show" class="btn btn-link tablebtn">' + "[show]" + "</a></b></td><tr>");
				}
			}
			else{
				tbodyNetStatsTable.append("<tr><td>" + serviceNetworkData.config.id + "</td><td><b>" + serviceNetworkData.config.name + "</b></td><td>" + '<b style="color:#24be14">enabled</b>' + "</b></td><td>" + tap + "</td><td>" + trunk + "</td><td><b>" + "disabled" + "</b></td><td>" + "inactive" + "</td><td>" + "0" + "</td><td>" + serviceNetworkData.object.meta.ver + "</td><td>" + serviceNetworkData.object.meta.date + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsrv_show" class="btn btn-link tablebtn">' + "[show]" + "</a></b></td><tr>");
			}
			
			// service json show
			document.getElementById("tempbtn_netsrv_show").id = "btn_node_netsrvtbl_" + serviceNetworkData.config.name;
			document.getElementById("btn_node_netsrvtbl_" + serviceNetworkData.config.name).onclick = function() { json_show("[ " + nodeName + " | network ]", nodeName, "node", serviceNetworkData) };
		}
		
		document.getElementById("node-network-status-header").innerHTML = 'Network [<b style="color:#24be14">ONLINE</b>]' + " - Bridging [<b>enabled</b>] " + vppstate + meta;
		document.getElementById("node-network-header").innerHTML = "Networks [<b>" + networkList.length + "</b>] - Bridges [<b>" + tap + "</b>] Trunks [<b>" + trunk + "</b>] - VPP [<b>" + vpp + "</b>]";	
		
	}
	
	//
	// devices
	//
	if(typeof serviceNetworkData.interface !== 'undefined'){
		
		var netHeaderString = "Devices [<b>Inactive</b>]";
		var netIbHeaderString = "InfiniBand [<b>Inactive</b>]";
		var netBondString = "";
		var netInterfaceString = "";
		var bondNum = 0;
		var devNum = 0;

		// get index of systems
		var dev_index = serviceNetworkData.interface.index;
		var devList = dev_index.split(';');
		
		devList.forEach((dev) => {
			
			if((typeof serviceNetworkData.interface[dev] !== 'undefined')){
				var devData = serviceNetworkData.interface[dev];
				
				var tbodyBond = $("#nodeNetworkBondTable tbody");
				var tbodyNetdev = $("#nodeNetworkDeviceTable tbody");
				
				//
				// bond
				//
				if(devData.type == "bond"){
					var bondSpeed = "n/a";

					if((typeof devData.meta !== 'undefined') && (typeof devData.meta.speed !== 'undefined')){
						tbodyBond.append("<tr><td>" + devData.id.id + "</td><td><b>" + devData.id.name + "</b></td><td><b>" + dev + "</b></td><td><b>" + devData.bond.type + "</b></td><td><b>" + devData.bond.hash + "</b></td><td><b>" + devData.meta.mtu + "</b></td><td><b>" + devData.meta.hwaddr + "</b></td><td><b>" + devData.bond.member + "</b></td><td><b>" + devData.meta.speed + "</b></td><td><b>" + devData.meta.duplex + "</b></td></tr>");
						bondSpeed = devData.meta.speed;
					}
					else{
						tbodyBond.append("<tr><td>" + devData.id.id + "</td><td><b>" + devData.id.name + "</b></td><td><b>" + dev + "</b></td><td><b>" + devData.bond.type + "</b></td><td><b>" + devData.bond.hash + "</b></td><td><b>" + devData.bond.member + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + devData.bond.member + "</b></td><td><b>" + "n/a" + "</b></td></tr>");
					}
					
					bondNum++;
					
					// bond members
					var mem_index = devData.bond.member;
					var memList = mem_index.split(';');
					
					memList.forEach((ifdev) => {

						if((typeof devData.meta[ifdev] !== 'undefined')){
							tbodyNetdev.append("<tr><td>" + ifdev + "</td><td><b>" + dev + ":" + ifdev + "</b></td><td><b>" + dev + "</b></td><td><b>" + devData.bond.type + "</b></td><td><b>" + devData.meta[ifdev].driver + "</b></td><td><b>" + devData.meta[ifdev].mtu + "</b></td><td><b>" + devData.meta[ifdev].hwaddr + "</b></td><td><b>" + devData.meta[ifdev].port + "</b></td><td><b>" + devData.meta[ifdev].speed + "</b></td><td><b>" + devData.meta[ifdev].duplex + "</b></td></tr>");
						}
						else{
							tbodyNetdev.append("<tr><td>" + ifdev + "</td><td><b>" + dev + ":" + ifdev + "</b></td><td><b>" + dev + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td></tr>");
						}
						
						devNum++;
						
					});
					
					netBondString += " - bond [<b>" + dev + "</b>] speed [<b>" + bondSpeed + "</b>]";
				}
				
				//
				// interface
				//
				if(devData.type == "interface"){
					var ethSpeed = "n/a";
					
					if((typeof devData.meta !== 'undefined') && (typeof devData.meta.speed !== 'undefined')){
						tbodyNetdev.append("<tr><td>" + devData.id.id + "</td><td><b>" + devData.id.name + "</b></td><td><b>" + dev + "</b></td><td><b>" + devData.type + "</b></td><td><b>" + devData.meta.driver + "</b></td><td><b>" + devData.meta.mtu + "</b></td><td><b>" + devData.meta.hwaddr + "</b></td><td><b>" + devData.meta.port + "</b></td><td><b>" + devData.meta.speed + "</b></td><td><b>" + devData.meta.duplex + "</b></td></tr>");
						ethSpeed = devData.meta.speed;
					}
					else{
						tbodyNetdev.append("<tr><td>" + devData.id.id + "</td><td><b>" + devData.id.name + "</b></td><td><b>" + dev + "</b></td><td><b>" + devData.type + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td><td><b>" + "n/a" + "</b></td></tr>");
					}
					
					netInterfaceString += " - nic [<b>" + dev + "</b>] speed [<b>" + ethSpeed + "</b>]";
					devNum++;
				}
				
				//
				// infiniband
				//
				if(devData.type == "infiniband"){
					netIbHeaderString = "";
					var ibPortString = "";
					var ibPortNum = 0;
					
					var tbodyNetIbHcaTable = $("#nodeNetworkIbHcaTable tbody");
					var tbodyNetIbPortTable = $("#nodeNetworkIbPortTable tbody");
					
					//var ethSpeed = "n/a";
					if((typeof devData.meta !== 'undefined') && (typeof devData.meta.hca_model !== 'undefined')){
						
						tbodyNetIbHcaTable.append("<tr><td>" + devData.id.id + "</td><td><b>" + devData.id.name + "</b></td><td><b>" + dev + "</b></td><td><b>" + devData.dev + "</b></td><td><b>" + devData.ports + "</b></td><td><b>" + devData.type + "</b></td><td><b>" + devData.meta.hca_model + "</b></td><td><b>" + devData.meta.hca_fw + "</b></td><td><b>" + devData.meta.hca_guid + "</b></td></tr>");
						
						// bond members
						var ib_ports = devData.ports;
						var portList = ib_ports.split(';');
					
						portList.forEach((ibport) => {
							tbodyNetIbPortTable.append("<tr><td><b>" + dev + ":" + ibport  + "</b></td><td><b>" + devData.dev  + "</b></td><td><b>" + devData.meta.port[ibport].link + "</b></td><td><b>" + devData.meta.port[ibport].state + "</b></td><td><b>" + devData.meta.port[ibport].phys + "</b></td><td><b>" + devData.meta.port[ibport].speed + "</b></td></tr>");
							
							ibPortNum++;
							ibPortString += " - port [<b>" + dev + ":" + ibport + "</b>] speed [<b>" + devData.meta.port[ibport].speed + "</b>]";
							
						});
						
					}
					
					netIbHeaderString += "InfiniBand [<b>" + dev + "</b>] " + ibPortString;

				}					
									
			}
		});

		document.getElementById("node-network-infiniband-header").innerHTML = netIbHeaderString;
		document.getElementById("node-network-device-header").innerHTML = "Ethernet [<b>" + devNum + "</b>]" + netBondString + netInterfaceString;

	}

}

//
// node service framework view
//
function node_view_service_framework(nodeName, serviceFrameworkData){
	var tbodyFramework = $("#nodeFrameworkTable tbody");
	var vmmindex = "";
	
	var diff = date_str_diff_now(serviceFrameworkData.updated);
	
	document.getElementById("node-framework-header").innerHTML = 'Framework [<b style="color:#24be14">ONLINE</b>]' + " - ver [<b>" + serviceFrameworkData.object.meta.ver + "</b>] updated [<b>" + serviceFrameworkData.updated + "</b>] delta [<b>" + diff + "</b>]";
	
	//
	// VMM
	//
	var tbody = $("#nodeVMMTable tbody");

	if((typeof serviceFrameworkData.vmm.index !== 'undefined')){
	
		// get index of systems
		var vmm_index = serviceFrameworkData.vmm.index;
		
		if(vmm_index && vmm_index !== ""){
		
			var vmmList = vmm_index.split(';');
			vmmList = sort_num(vmmList);
			vmmindex = vmm_index;
			
			document.getElementById("node-vmm-header").innerHTML = "VMMs [<b>" + vmmList.length + "</b>]";
			
			vmmList.forEach((vmm) => {
				
				if(typeof serviceFrameworkData.vmm[vmm] !== 'undefined'){
				
					if(serviceFrameworkData.vmm[vmm].state == "1"){
						tbody.append("<tr><td><b>" + vmm + "</b></td><td><b>" + serviceFrameworkData.vmm[vmm].system_name + "</b></td><td>" + '<b style="color:#24be14">' + "RUNNING" + "</b></td><td>" + serviceFrameworkData.vmm[vmm].pid + "</td><td><b>" + serviceFrameworkData.vmm[vmm].date + "</b></td><td>" + serviceFrameworkData.vmm[vmm].socket + "</td><td>" + serviceFrameworkData.vmm[vmm].log + "</td><tr>");
					}
					else if(serviceFrameworkData.vmm[vmm].state == "0"){
						tbody.append("<tr><td><b>" + vmm + "</b></td><td><b>" + serviceFrameworkData.vmm[vmm].system_name + "</b></td><td>" + "NOT RUNNING" + "</td><td>" + serviceFrameworkData.vmm[vmm].pid + "</td><td><b>" + serviceFrameworkData.vmm[vmm].date + "</b></td><td>" + serviceFrameworkData.vmm[vmm].socket + "</td><td>" + serviceFrameworkData.vmm[vmm].log + "</td><tr>");
					}
					else{
						tbody.append("<tr><td><b>" + vmm + "</b></td><td><b>" + serviceFrameworkData.vmm[vmm].system_name + "</b></td><td><b>" + serviceFrameworkData.vmm[vmm].state + "</b></td><td>" + serviceFrameworkData.vmm[vmm].pid + "</td><td><b>" + serviceFrameworkData.vmm[vmm].date + "</b></td><td>" + serviceFrameworkData.vmm[vmm].socket + "</td><td>" + serviceFrameworkData.vmm[vmm].log + "</td><tr>");
					}
				}
				
			});
		}
		else{
			document.getElementById("node-vmm-header").innerHTML = "VMMs [<b>" + "Inactive" + "</b>]";
		}
	}
	else{
		// failed
	}	
	
	tbodyFramework.append("<tr><td><b>" + serviceFrameworkData.config.id + "</b></td><td><b>" + serviceFrameworkData.config.name + "</b></td><td>" + "inactive" + "</td><td><b>" + vmmindex + "</b></td><td>" + "inactive" + "</td><td>" + serviceFrameworkData.updated + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_framesrv_show" class="btn btn-link tablebtn">' + "[show]" + "</a></b></td><tr>");
	
	// service json show
	document.getElementById("tempbtn_framesrv_show").id = "btn_node_framesrvtbl_" + serviceFrameworkData.config.name;
	document.getElementById("btn_node_framesrvtbl_" + serviceFrameworkData.config.name).onclick = function() { json_show("[ " + nodeName + " | framework ]", nodeName, "node", serviceFrameworkData) };
	
	//
	// SERVICE
	//

	var tbodyService = $("#nodeFrameworkServiceTable tbody");

	if(serviceFrameworkData.service && (typeof serviceFrameworkData.service.index !== 'undefined')){
		
		var serviceList = serviceFrameworkData.service.index.split(';');

		document.getElementById("node-service-header").innerHTML = "Services [<b>" + serviceList.length + "</b>] index [<b>" + serviceList + "</b>]";
		
		serviceList.forEach((service) => {
			
			if(typeof serviceFrameworkData.service[service].stats !== 'undefined' && (serviceFrameworkData.service[service].state == 1 || serviceFrameworkData.service[service].state == 2)){
				
				var diff = date_str_diff_now(serviceFrameworkData.service[service].date);
				
				tbodyService.append("<tr><td><b>" + service + "</b></td><td>" + serviceFrameworkData.service[service].state + "</td><td><b>" + serviceFrameworkData.service[service].status + "</b></td><td>" + serviceFrameworkData.service[service].pid + "</td><td>" + serviceFrameworkData.service[service].date + "</td><td><b>" + diff + "</b></td><td><b>" + serviceFrameworkData.service[service].stats.cpu + "%</b></td><td><b>" + serviceFrameworkData.service[service].stats.mem + "%</b></td><td></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stop" class="btn btn-link tablebtn">' + "[stop]" + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_restart" class="btn btn-link tablebtn">' + "[restart]" + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_clear_log" class="btn btn-link tablebtn">' + "[clear log]" + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_show_log" class="btn btn-link tablebtn">' + "[show log]" + "</a></b></td></tr>");
				
				// stop service
				document.getElementById("tempbtn_stop").id = "tempbtn_stop_" + nodeName + service;
				document.getElementById("tempbtn_stop_" + nodeName + service).onclick = function() { node_service_stop_accept(nodeName, service) };
				
				// restart service
				document.getElementById("tempbtn_restart").id = "tempbtn_restart_" + nodeName + service;
				document.getElementById("tempbtn_restart_" + nodeName + service).onclick = function() { node_service_restart_accept(nodeName, service) };
			}
			else{
				var diff = date_str_diff_now(serviceFrameworkData.service[service].date);
				
				tbodyService.append("<tr><td><b>" + service + "</b></td><td>" + serviceFrameworkData.service[service].state + "</td><td><b>" + serviceFrameworkData.service[service].status + "</b></td><td>" + "" + "</td><td>" + serviceFrameworkData.service[service].date + "</b></td><td><b>" + diff + "</b></b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_start" class="btn btn-link tablebtn">' + "[start]" + "</a></b></td><td></td><td></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_clear_log" class="btn btn-link tablebtn">' + "[clear log]" + "</a></b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_show_log" class="btn btn-link tablebtn">' + "[show log]" + "</a></b></td></tr>");
				
				// start service
				document.getElementById("tempbtn_start").id = "tempbtn_start_" + nodeName + service;
				document.getElementById("tempbtn_start_" + nodeName + service).onclick = function() { node_service_start_accept(nodeName, service) };
			}
			
		});
	}
	else{
		// undefined
	}	
	
}

//
// node service storage view
//
function node_view_service_storage(nodeName, serviceStorageData){
	
	var tbodyStorage = $("#nodeStorageServiceTable tbody");

	var diff = date_str_diff_now(serviceStorageData.updated);

	document.getElementById("node-storage-header").innerHTML = 'Storage [<b style="color:#24be14">ONLINE</b>]' + " - ver [<b>" + serviceStorageData.object.meta.ver + "</b>] updated [<b>" + serviceStorageData.updated + "</b>] delta [<b>" + diff + "</b>]";
	tbodyStorage.append("<tr><td>" + serviceStorageData.config.id + "</td><td>" + serviceStorageData.config.name + "</td><td>" + serviceStorageData.object.meta.ver + "</td><td>" + serviceStorageData.updated + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storsrv_show" class="btn btn-link tablebtn">' + "[show]" + "</a></b></td><tr/>");
	
	// service json show
	document.getElementById("tempbtn_storsrv_show").id = "btn_node_storsrvtbl_" + serviceStorageData.config.name;
	document.getElementById("btn_node_storsrvtbl_" + serviceStorageData.config.name).onclick = function() { json_show("[ " + nodeName + " | storage ]", nodeName, "node", serviceStorageData) };
	
	if((typeof serviceStorageData.device.index !== 'undefined')){
		
		var devList = serviceStorageData.device.index.split(';');
		
		devList.forEach((dev) => {
			if((typeof serviceStorageData.device.data !== 'undefined') && (typeof serviceStorageData.device.data[dev] !== 'undefined')){
				node_view_storage_device_process(serviceStorageData.device.data[dev]);
			}
			else{
				//console.log("STORAGE DEVICE NOT FOUND");
			}
		});
		
	};	
	
	if((typeof serviceStorageData.pool !== 'undefined') && (typeof serviceStorageData.pool.index !== 'undefined')){
		
		var poolList = serviceStorageData.pool.index.split(';');
		
		poolList.forEach((pool) => {
			if((typeof serviceStorageData.pool.data !== 'undefined') && (typeof serviceStorageData.pool.data[pool] !== 'undefined') && (typeof serviceStorageData.pool.meta !== 'undefined') && (typeof serviceStorageData.pool.meta[pool] !== 'undefined')){
				node_view_storage_pool_process(serviceStorageData.pool.data[pool], serviceStorageData.pool.meta[pool], nodeName);
			}
		});
		
	};
	
	
}

//
// node storage view pool process
//
function node_view_storage_pool_process(poolData, meta, nodeName){
	var tbodyPool = $("#nodeStoragePoolTable tbody");
		
	if((typeof poolData !== 'undefined') && (typeof poolData.pool !== 'undefined') && (typeof meta !== 'undefined') && (typeof meta.size !== 'undefined') && (typeof meta.size.total !== 'undefined')){
		var state = "n/a";
		var owner = "n/a";
		var mounted = "n/a";
		
		//check if owner
		if(poolData.owner.name == nodeName){
			owner = view_color_healthy("TRUE");
			node_pool_owner++;
		}
		else{
			owner = "<b>FALSE</b>";
			node_pool_subs++;
		}

		//check if owner
		if(meta.mounted == 1){
			mounted = view_color_healthy("TRUE");
		}
		else{
			mounted = view_color_warning("FALSE");
		}
		
		// check state
		if(meta.state == 1){
			state = view_health_color_status("ONLINE");
		}
		else{
			state = view_health_color_status("OFFLINE");
		}
		
		tbodyPool.append("<tr><td>" + poolData.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_storpooltbl" class="btn btn-link tablebtn">' + poolData.id.name  + "</a></b>" + "</td><td><b>" + owner + "</b></td><td><b>" + state + "</b></td><td><b>" + mounted + "</b></td><td>" + meta.date + "</td><td><b>" + meta.size.total.gb + " GB</b></td><td><b>" + meta.size.used.gb + " GB</b></td><td><b>" + meta.size.free.gb + " GB</b></td><tr>");
		document.getElementById("tempbtn_storpooltbl").id = "tempbtn_storpooltbl_" + poolData.id.name;
		document.getElementById("tempbtn_storpooltbl_" + poolData.id.name).onclick = function() { stor_show_pool(poolData.id.name) };
		
		node_pool_num++;
		node_pool_size_tot += parseInt(meta.size.total.gb);
		node_pool_size_used += parseInt(meta.size.used.gb);
		node_pool_size_free += parseInt(meta.size.free.gb);
		
		document.getElementById("node-storage-pool-header").innerHTML = "Pools [<b>" + node_pool_num + "</b>] - owner [<b>" + node_pool_owner + "</b>] subscriber [<b>" + node_pool_subs + "</b>] - total size [<b>" + niceGBytes(node_pool_size_tot) + "</b>] used [<b>" + niceGBytes(node_pool_size_used) + "</b>] available [<b>" + niceGBytes(node_pool_size_free) + "</b>]";
	}
	else{
		//console.log("POOL NOT DEFINED\n");
	}
		
}

//
// node storage view device process
//
function node_view_storage_device_process(deviceData){
	
		var tbody = $("#nodeStorageDeviceTable tbody");
	
		if((typeof deviceData !== 'undefined')){
			//var stordev = deviceData;
			
			var storType = "n/a";
			
			if(deviceData.object.class === "disk" || deviceData.object.class === "nvme"){
				storType = deviceData['device'].type;
				node_dev_disk++;
				
				if((typeof deviceData.meta.size !== 'undefined')){
				
					if(storType === "hdd"){
						node_dev_hdd++;
						node_hdd_size += parseInt(deviceData.meta.size.total.gb);
					}
					
					if(storType === "ssd" || storType === "nvme"){
						node_dev_ssd++;
						node_ssd_size += parseInt(deviceData.meta.size.total.gb);
					}
				}
			}
			
			if(deviceData.object.class === "mdraid"){
				storType = deviceData['mdraid'].type;
				node_dev_raid++;
				
				if((typeof deviceData.meta !== 'undefined') && (typeof deviceData.meta.size !== 'undefined') && (typeof deviceData.meta.size.total !== 'undefined')){
				
					if(storType === "hdd"){
						node_dev_hdd++;
						node_hdd_size += parseInt(deviceData.meta.size.total.gb);
					}
					
					if(storType === "ssd"){
						node_dev_ssd++;
						node_ssd_size += parseInt(deviceData.meta.size.total.gb);
					}
				
				}
			}
			
			if((typeof deviceData.meta !== 'undefined') && (typeof deviceData.meta.state !== 'undefined') && (deviceData.meta.state == 1) && (typeof deviceData.meta !== 'undefined') && (typeof deviceData.meta.size !== 'undefined') && (typeof deviceData.meta.size.total !== 'undefined')){
				
				//
				// not all nodes migrated to new health structure
				//
				var healthy = "n/a";
				if((typeof deviceData.meta.health !== 'undefined') && (typeof deviceData.meta.health.status !== 'undefined')){
					healthy = view_health_color_status(deviceData.meta.health.status);
				}
				else if((typeof deviceData.meta.status !== 'undefined')){
					healthy = view_health_color_status(deviceData.meta.status);
				}
				else{
					healthy = "n/a";
				}
				
				tbody.append("<tr><td>" + deviceData.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stordevtbl" class="btn btn-link tablebtn">' + deviceData.id.name  + "</a></b>" + "</td><td><b>" + deviceData.object.class + "</b></td><td><b>" + storType + "</b></td><td>" + deviceData.meta.date + "</td><td><b>" + deviceData.meta.size.total.gb + " GB</b></td><td><b>" + deviceData.meta.size.used.gb + " GB</b></td><td><b>" + deviceData.meta.size.free.gb + " GB</b></td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><td>" + healthy + "</td><td>" + '<b style="color:#24be14">CLUSTER</b>' + "</td><tr>");
				document.getElementById("tempbtn_stordevtbl").id = "tempbtn_stordevtbl_" + deviceData.id.name;
				document.getElementById("tempbtn_stordevtbl_" + deviceData.id.name).onclick = function() { stor_show_device(deviceData.id.name) };
			}
			else{
				tbody.append("<tr><td>" + deviceData.id.id + "</td><td>" + '<b style="color:#0040ff"><a id="tempbtn_stordevtbl" class="btn btn-link tablebtn">' + deviceData.id.name  + "</a></b>" + "</td><td><b>" + deviceData.object.class + "</b></td><td><b>" + storType + "</b></td><td>n/a</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + '<b>LOCAL</b>' + "</td><tr>");
				document.getElementById("tempbtn_stordevtbl").id = "tempbtn_stordevtbl_" + deviceData.id.name;
				document.getElementById("tempbtn_stordevtbl_" + deviceData.id.name).onclick = function() { stor_show_device(deviceData.id.name) };
			}
		
			node_dev_tot++;
			
			document.getElementById("node-storage-device-header").innerHTML = "Devices [<b>" + node_dev_tot + "</b>] - RAID [<b>" + node_dev_raid + "</b>] disks [<b>" + node_dev_disk + "</b>] - SSD [<b>" + node_dev_ssd + "</b>] size [<b>" + niceGBytes(node_ssd_size) + "</b>] - HDD [<b>" + node_dev_hdd + "</b>] size [<b>" + niceGBytes(node_hdd_size) + "</b>]";
		}
		else{
			log_write_json("node_view_storage_process", "failed inner", deviceData);
		}
		
}

// ==============================================
// NODE MENU FUNCTIONS
// ==============================================
function node_menu_remove_all() {
	node_menu_remove_online;
	node_menu_remove_offline;
}

function node_menu_remove_online() {
	document.getElementById("collapse-node-online").innerHTML = "";
}

function node_menu_remove_offline() {
	document.getElementById("collapse-node-offline").innerHTML = "";
}

/**
 * Adds a node to the cluster online menu
 * @param {string} nodeName - Name of node to add
 * @returns {void}
 */
function node_menu_add_clusternode_online(nodeName) {
    if(!nodeName || typeof nodeName !== 'string'){
        console.error('Invalid node name provided');
        return;
    }
    const func = () => cluster_async_show(nodeName);
    menu_add_item(nodeName, 'collapse-cluster-online', `node_cluster_${nodeName}`, "bi-view-stacked", func);
}
function node_menu_add_cluster_object(nodeName) {
	const func = function() { cluster_node_show(nodeName) };
	menu_add_item(nodeName, 'collapse-cluster-online', "node_cluster_" + nodeName, "bi-view-stacked", func);
}
function node_menu_add_clusternode_monitor(nodeName) {
	const func = function() { cluster_health_node_show(nodeName) };
	menu_add_item(nodeName, 'collapse-cluster-monitor', "node_monitor_" + nodeName, "bi-heart-pulse", func);
}

/**
 * Adds a node to the online nodes menu
 * @param {string} nodeName - Name of node to add
 * @returns {void}
 */
function node_menu_add_online(nodeName) {
    if(!nodeName || typeof nodeName !== 'string'){
        console.error('Invalid node name provided');
        return;
    }
    const func = () => node_show(nodeName);
    menu_add_item(nodeName, 'collapse-node-online', `node_${nodeName}`, "bi-view-stacked", func);
}

/**
 * Adds a node to the offline nodes menu
 * @param {string} nodeName - Name of node to add
 * @returns {void}
 */
function node_menu_add_offline(nodeName) {
    if(!nodeName || typeof nodeName !== 'string'){
        console.error('Invalid node name provided');
        return;
    }
    const func = () => node_show(nodeName);
    menu_add_item(nodeName, 'collapse-node-offline', `node_${nodeName}`, "bi-view-stacked", func);
}

// ==============================================
// NODE OVERVIEW FUNCTIONS
// ==============================================
//function node_overview_show() {
//	node_overview_nodeadd();
//}

//
// node overview
//
function node_overview_show() {
	let nodeList = dbnew_node_index_get();
	
	$("#nodeTable tbody tr").remove();	
	var tbodyNodeTable = $("#nodeTable tbody");

	var cores = 0;
	var mem_use = 0;
	var mem_free = 0;
	var mem_tot = 0;
	var load_1 = 0;
	var load_5 = 0;
	var load_15 = 0;
	var online = 0;
	var offline = 0;	
	
	nodeList.forEach((node) => {
		var nodeData = dbnew_node_get(node);
		const nodeName = nodeData.id.name;

		if(nodeData.meta.state == "1" || nodeData.meta.state == "2"){
			
			//convert memory to GB
			mem_tot_node = (parseInt(nodeData.hw.stats.mem.total) / 1000).toFixed(0);
			mem_free_node = (parseInt(nodeData.hw.stats.mem.free) / 1000).toFixed(0);
			mem_use_node = (parseInt(nodeData.hw.stats.mem.used) / 1000).toFixed(0);

			if(nodeData.meta.state == "1"){
				var diff = date_str_diff_now(nodeData.object.meta.date);
				
				//tbodyNodeTable.append("<tr><td><b>" + nodeData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_nodetbl" class="btn btn-link tablebtn">' + nodeData.id.name  + "</a></b></td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><td><b>" + nodeData.object.meta.ver + "</b></td><td><b>" + nodeUpdated + "</b></td><td>" + nodeData.hw.stats.uptime + "</td><td>" + nodeData.hw.cpu.type + "</td><td>" + nodeData.hw.cpu.core + "</td><td><b> " + nodeData.hw.stats.load[1].toFixed(2) + " / " + nodeData.hw.stats.load[5].toFixed(2) + " / " + nodeData.hw.stats.load[15].toFixed(2) + " </b></td><td><b>" + mem_tot_node + " GB</b></td><td><b>" + mem_use_node + " GB</b></td><td><b>" + mem_free_node  + " GB</b></td><tr>");
				tbodyNodeTable.append("<tr><td><b>" + nodeData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_nodetbl" class="btn btn-link tablebtn">' + nodeData.id.name  + "</a></b></td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><td><b>" + nodeData.object.meta.ver + "</b></td><td><b>" + diff + "</b></td><td>" + nodeData.hw.stats.uptime + "</td><td>" + nodeData.hw.cpu.type + "</td><td>" + nodeData.hw.cpu.core + "</td><td><b> " + nodeData.hw.stats.load[1].toFixed(2) + " / " + nodeData.hw.stats.load[5].toFixed(2) + " / " + nodeData.hw.stats.load[15].toFixed(2) + " </b></td><td><b>" + mem_tot_node + " GB</b></td><td><b>" + mem_use_node + " GB</b></td><td><b>" + mem_free_node  + " GB</b></td><tr>");
			}
			else{
				tbodyNodeTable.append("<tr><td><b>" + nodeData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_nodetbl" class="btn btn-link tablebtn">' + nodeData.id.name  + "</a></b></td><td>" + '<b style="color:#F08000">' + nodeData.meta.status + '</b>' + "</td><td><b>" + nodeData.object.meta.ver + "</b></td><td>" + nodeData.object.meta.date + "</td><td>" + nodeData.hw.stats.uptime + "</td><td>" + nodeData.hw.cpu.type + "</td><td>" + nodeData.hw.cpu.core + "</td><td><b> " + nodeData.hw.stats.load[1].toFixed(2) + " / " + nodeData.hw.stats.load[5].toFixed(2) + " / " + nodeData.hw.stats.load[15].toFixed(2) + " </b></td><td><b>" + mem_tot_node + " GB</b></td><td><b>" + mem_use_node + " GB</b></td><td><b>" + mem_free_node  + " GB</b></td><tr>");
			}

			cores += parseInt(nodeData.hw.cpu.core);
			load_1 += parseFloat(nodeData.hw.stats.load[1]);
			load_5 += parseFloat(nodeData.hw.stats.load[5]);
			load_15 += parseFloat(nodeData.hw.stats.load[15]);		

			mem_tot += parseInt(nodeData.hw.stats.mem.total);
			mem_free += parseInt(nodeData.hw.stats.mem.free);
			mem_use += parseInt(nodeData.hw.stats.mem.used);			

			online++;
		}
		else{
			tbodyNodeTable.append("<tr><td><b>" + nodeData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_nodetbl" class="btn btn-link tablebtn">' + nodeData.id.name  + "</a></b></td><td>" + '<b>OFFLINE</b>' + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><tr>");
			offline++;
		}


		document.getElementById("tempbtn_nodetbl").id = "btn_nodetbl_" + nodeName;
		document.getElementById("btn_nodetbl_" + nodeName).onclick = function() { node_show(nodeName) };

	});	
	
	document.getElementById("main-node-overview-online").innerHTML = "<b>" + online + "</b>";
	document.getElementById("main-node-overview-offline").innerHTML = "<b>" + offline + "</b>";
	
	document.getElementById("main-node-overview-cores").innerHTML = "<b>" + cores + "</b>";
	document.getElementById("main-node-overview-load").innerHTML = "<b>" + load_1.toFixed(2) + " / " + load_5.toFixed(2) + " / " + load_15.toFixed(2) + "</b>";
	
	mem_tot = niceMBytesMem(mem_tot);
	mem_use = niceMBytesMem(mem_use);
	mem_free = niceMBytesMem(mem_free);
	
	document.getElementById("main-node-overview-mem-tot").innerHTML = "<b>" + mem_tot + "</b>";
	document.getElementById("main-node-overview-mem-used").innerHTML = "<b>" + mem_use + "</b>";

}

// ==============================================
// NODE MONITORING FUNCTIONS
// ==============================================

// NOT MIGRATED
function node_view_service_monitor(nodeName, data){
	//console.log("NODE HEALTH MONITOR HERE [" + nodeName +"]");

	$("#nodeStatusHealthTable tbody tr").remove();	
	var tbodyNodeHealthTable = $("#nodeStatusHealthTable tbody");

	if((typeof data !== 'undefined')){
		
		if(typeof data.config.service.meta.monitor !== 'undefined'){

			
			if(typeof data.config.service.data.monitor !== 'undefined'){
				
				
				if((typeof data.config.service.data.monitor.data !== 'undefined') && (typeof data.config.service.data.monitor.data.service !== 'undefined')){
					
					// check framework
					if((typeof data.config.service.data.monitor.data.service.framework !== 'undefined') && (typeof data.config.service.data.monitor.data.service.framework[nodeName] !== 'undefined')){
						tbodyNodeHealthTable.append("<tr><td><b>" + "framework" + "</b></td><td><b>" + data.config.service.data.monitor.data.service.framework[nodeName].updated + "</b></td><td><b>" + data.config.service.data.monitor.data.service.framework[nodeName].delta + "</b></td><td><b>" + data.config.service.data.monitor.data.service.framework[nodeName].state + "</b></td><td><b>" + data.config.service.data.monitor.data.service.framework[nodeName].status + "</b></td><tr>");
					}
					
					// check network
					if((typeof data.config.service.data.monitor.data.service.network !== 'undefined') && (typeof data.config.service.data.monitor.data.service.network[nodeName] !== 'undefined')){
						tbodyNodeHealthTable.append("<tr><td><b>" + "network" + "</b></td><td><b>" + data.config.service.data.monitor.data.service.network[nodeName].updated + "</b></td><td><b>" + data.config.service.data.monitor.data.service.network[nodeName].delta + "</b></td><td><b>" + data.config.service.data.monitor.data.service.network[nodeName].state + "</b></td><td><b>" + data.config.service.data.monitor.data.service.network[nodeName].status + "</b></td><tr>");
					}

					// check storage
					if((typeof data.config.service.data.monitor.data.service.storage !== 'undefined') && (typeof data.config.service.data.monitor.data.service.storage[nodeName] !== 'undefined')){
						tbodyNodeHealthTable.append("<tr><td><b>" + "storage" + "</b></td><td><b>" + data.config.service.data.monitor.data.service.storage[nodeName].updated + "</b></td><td><b>" + data.config.service.data.monitor.data.service.storage[nodeName].delta + "</b></td><td><b>" + data.config.service.data.monitor.data.service.storage[nodeName].state + "</b></td><td><b>" + data.config.service.data.monitor.data.service.storage[nodeName].status + "</b></td><tr>");
					}

					// check hypervisor
					if((typeof data.config.service.data.monitor.data.service.hypervisor !== 'undefined') && (typeof data.config.service.data.monitor.data.service.hypervisor[nodeName] !== 'undefined')){
						tbodyNodeHealthTable.append("<tr><td><b>" + "hypervisor" + "</b></td><td><b>" + data.config.service.data.monitor.data.service.hypervisor[nodeName].updated + "</b></td><td><b>" + data.config.service.data.monitor.data.service.hypervisor[nodeName].delta + "</b></td><td><b>" + data.config.service.data.monitor.data.service.hypervisor[nodeName].state + "</b></td><td><b>" + data.config.service.data.monitor.data.service.hypervisor[nodeName].status + "</b></td><tr>");
					}
					
				}
				
			}
			
		}
	}
	
}

//
// node resources show 
//
function node_resources_show(){
	
	var nodeList = dbnew_node_index_get();

	$("#nodeResOverviewTable tbody tr").remove();
	$("#nodeResOverviewMemTable tbody tr").remove();

	resCpuCoreTotal = 0;
	resCpuLoadTotal = 0;

	resCpuAgg = 0;

	resMemUsedTotal = 0;
	resMemAvailTotal = 0;
	resMemFreeTotal = 0;
	
	resNodeOfflineTotal = 0;
	resNodeOnlineTotal = 0;
	
	resCpuLoad1 = 0;
	resCpuLoad5 = 0;
	resCpuLoad15 = 0;

	resHyperCpuAlloc = 0;
	resHyperMemAlloc = 0;
	
	document.getElementById('accordionNodeResource').innerHTML = "";
	
	nodeList.forEach((node) => {
		var nodeData = dbnew_node_get(node);
		//console.log(nodeData);
		const nodeName = nodeData.id.name;
		node_resource_accordion(nodeData, nodeName);
	});
	
	// resources
	resMemFreeTotal = resMemAvailTotal - resMemUsedTotal;
	var resCpuAggregate = (resHyperMemAlloc / resMemAvailTotal) * 100;
	
	// cpu load
	var resCpuLoadPerc = (resCpuCoreTotal / resCpuLoad1);
	document.getElementById("nodeResCpuLoadTotBar").style.width = resCpuLoadPerc + "%";
	document.getElementById("nodeResCpuLoadTotBar").innerHTML = "<b>" + resCpuLoadPerc.toFixed(1) + " %</b>";

	// cpu aclloc
	var resCpuAllocPerc = (resHyperCpuAlloc / resCpuCoreTotal) * 100;
	document.getElementById("nodeResCpuAllocBar").style.width = resCpuAllocPerc + "%";
	document.getElementById("nodeResCpuAllocBar").innerHTML = "<b>" + resCpuAllocPerc.toFixed(1) + " %</b>";

	// memory aggregate
	var resMemLoadPerc = (resMemUsedTotal / resMemAvailTotal) * 100;
	document.getElementById("nodeResMemLoadTotBar").style.width = resMemLoadPerc + "%";
	document.getElementById("nodeResMemLoadTotBar").innerHTML = "<b>" + resMemLoadPerc.toFixed(1) + " %</b>";

	// memory aggregate
	var resMemLoadPerc2 = (resHyperMemAlloc / resMemAvailTotal) * 100;
	document.getElementById("nodeResMemResBar").style.width = resMemLoadPerc2 + "%";
	document.getElementById("nodeResMemResBar").innerHTML = "<b>" + resMemLoadPerc2.toFixed(1) + " %</b>";
	
	// tiles
	document.getElementById("main-node-resview-online").innerHTML = "<b>" + resNodeOnlineTotal + " </b>";
	document.getElementById("main-node-resview-offline").innerHTML = "<b>" + resNodeOfflineTotal + " </b>";
	
	document.getElementById("main-node-resview-cores").innerHTML = "<b>" + resCpuCoreTotal + " </b>";
	document.getElementById("main-node-resview-load").innerHTML = "<b>" +resCpuLoad1.toFixed(2) + " / " + resCpuLoad5.toFixed(2) + " / " + resCpuLoad15.toFixed(2) + " </b>";
	
	document.getElementById("main-node-resview-cores").innerHTML = "<b>" + resCpuCoreTotal + " </b>";
	document.getElementById("main-node-resview-cores").innerHTML = "<b>" + resCpuCoreTotal + " </b>";
	
	document.getElementById("main-node-resview-mem-tot").innerHTML = "<b>" + niceMBytesMem(resMemAvailTotal) + "</b>";
	document.getElementById("main-node-resview-mem-used").innerHTML = "<b>" + niceMBytesMem(resMemUsedTotal) + "</b>";

	
	// overview
	var tbody = $("#nodeResOverviewTable tbody");
	tbody.append("<tr><td><b>" + resNodeOnlineTotal + "</b></td><td><b>" + resCpuCoreTotal + "</b></td><td><b>" + resHyperCpuAlloc + "</b></td><td><b>" + resCpuLoadPerc.toFixed(1) + "%</b></td><td><b>" + resCpuLoad1.toFixed(2) + " / " + resCpuLoad5.toFixed(2) + " / " + resCpuLoad15.toFixed(2) + "</b></td></tr>");	
	
	var tbodyMem = $("#nodeResOverviewMemTable tbody");
	tbodyMem.append("<tr><td><b>" + niceMBytesMem(resMemAvailTotal) + "</b></td><td><b>" + niceMBytesMem(resMemUsedTotal) + "</b></td><td><b>" + niceMBytesMem(resMemFreeTotal) + "</b></td><td><b>" + niceMBytesMem(resHyperMemAlloc) + "</b></td><td><b>" + resMemLoadPerc.toFixed(1) + "%</b></td></tr>");	
	
	document.getElementById("main-node-resview-header").innerHTML = "Cluster [<b>Lithium</b>] - Nodes Online [<b>" + resNodeOnlineTotal + "</b>] - Available cpu cores [<b>" + resCpuCoreTotal + "</b>] use [<b>" + resCpuLoadPerc.toFixed(1) + "%</b>] - Available memory [<b>" + (resMemAvailTotal / 1000).toFixed(1) + " GB</b>] use [<b>" + resMemLoadPerc.toFixed(1) + "%</b>]";

}

//
// node resource accordion
//
function node_resource_accordion(nodeData, nodeName) {
	
	var root = document.getElementById('accordionNodeResource');
	var header;
	var headerDiv = document.createElement("div");

	// check node state
	if(nodeData.meta.state == "1" || nodeData.state == "2"){
		var status = "";
		
		if(nodeData.meta.state == "1"){
			status = view_color_healthy("ONLINE");
		}
		else{
			status = view_color_warning(nodeData.meta.status);
		}
		
		header = "Node [<b>" + nodeName + "</b>] - " + 'state [' + status + '] ver [' + nodeData.object.meta.ver + "] - ";
		header += " [<b>" + nodeData.hw.cpu.type + "</b>] core [<b>" + nodeData.hw.cpu.core + "</b>] ram [<b>" + ( parseInt(nodeData.hw.stats.mem.total) / 1000).toFixed(0) + " GB</b>] -";

		var cpuLoad = 100 - parseFloat(nodeData.hw.stats.cpu.idle);
		header += " cpu [<b> " + cpuLoad.toFixed(1) + "%</b>]";

		var memFree =  (parseInt(nodeData.hw.stats.mem.used)  / parseInt(nodeData.hw.stats.mem.total)) * 100;
		header += " ram [<b> " + memFree.toFixed(1) + "%</b>]";
		
		resCpuCoreTotal += parseInt(nodeData.hw.cpu.core);
		
		resMemAvailTotal += parseInt(nodeData.hw.stats.mem.total);
		resMemUsedTotal += parseInt(nodeData.hw.stats.mem.used);

		resCpuLoad1 += parseFloat(nodeData.hw.stats.load[1]);
		resCpuLoad5 += parseFloat(nodeData.hw.stats.load[5]);
		resCpuLoad15 += parseFloat(nodeData.hw.stats.load[15]);
		
		resNodeOnlineTotal++;
		
		var accordion = view_accordion_build("accordionNodeRes" + nodeName, "collapseNodeRes" + nodeName, "bi-view-stacked", header);
		var divNodeRes = view_accordion_element_build("collapseNodeRes" + nodeName, "headingSystemStorage", "accordionNodeRes" + nodeName);
		
		if((typeof nodeData.hw !== 'undefined') && (typeof nodeData.hw.stats !== 'undefined')){
			var row = document.createElement("div");
			row.setAttribute("id", "nodeResView");
			row.setAttribute("class", "row row-space g-1 mt-2 ms-1 mb-3 me-5");
			
			var cpuLoad = 100 - parseInt(nodeData.hw.stats.cpu.idle);
			header += " load [ <b>" + cpuLoad + " </b>]";
			
			var cpuloadbar = view_bar_add("cpu", "load [<b>" + cpuLoad + " %</b>] idle [<b>" + nodeData.hw.stats.cpu.idle + " %</b>] io wait [<b>" + nodeData.hw.stats.cpu.wait + " %</b>]", "noderesbar_cpuload", cpuLoad);
			row.appendChild(cpuloadbar);
			
			var memFree =  (parseInt(nodeData.hw.stats.mem.used)  / parseInt(nodeData.hw.stats.mem.total)) * 100;

			var memNodeTotalPretty = niceMBytesMem(nodeData.hw.stats.mem.total);
			var memNodeUsedPretty = niceMBytesMem(nodeData.hw.stats.mem.used);
			var memNodeFreePretty = niceMBytesMem(nodeData.hw.stats.mem.free);
			var memNodeCachedPretty = niceMBytesMem(nodeData.hw.stats.mem.cache);

			var memloadbar = view_bar_add("memory", "total [<b>" + memNodeTotalPretty + "</b>] used [<b>" + memNodeUsedPretty + "</b>] cached [<b>" + memNodeCachedPretty + "</b>] free [<b>" + memNodeFreePretty + "</b>]", "noderesbar_memload", memFree.toFixed(1));
			row.appendChild(memloadbar);


			// get hypervisor
			var serviceData = dbnew_service_node_get("hypervisor", nodeName);
			
			if(serviceData){
				//console.log("success getting hypervisor for: " + nodeName);
				//console.log(serviceData);

				var cpualloc = 0;
				if((serviceData.hyper !== null) && (serviceData.hyper.cpualloc !== undefined)){
					cpualloc = serviceData.hyper.cpualloc;
				}

				var cpuHyperAlloc =  parseInt(cpualloc) / (parseInt(serviceData.hw.cpu.core) * parseInt(serviceData.hw.cpu.sock));
				var cpuHyperAllocPerc = cpuHyperAlloc * 100;
					
				var cpuresbar = view_bar_add("cpu reserved", "cores allocated [<b>" + cpualloc + "</b>] ratio [<b>" + cpuHyperAllocPerc.toFixed(1) + "%</b>]", "noderesbar_cpures", cpuHyperAllocPerc.toFixed(1));
				row.appendChild(cpuresbar);	

				var memalloc = 0;
				if((serviceData.hyper !== null) && (serviceData.hyper.memalloc !== undefined)){
					memalloc = serviceData.hyper.memalloc;
				}

				resHyperCpuAlloc += parseInt(cpualloc);
				resHyperMemAlloc += parseInt(memalloc);

				var memFree = parseInt(serviceData.hw.stats.mem.total) - parseInt(memalloc);
				var memFreePerc = (100 * memFree) / parseInt(serviceData.hw.stats.mem.total);
				var memUsedPerc = (100 - memFreePerc);

				var memAllocPretty = niceMBytesMem(memalloc);
				var memTotPretty = niceMBytesMem(serviceData.hw.stats.mem.total);

				var memresbar = view_bar_add("memory reserved", "memory available [<b>" + memTotPretty + "</b>] allocated [<b>" + memAllocPretty + "</b>] reserved [<b>" + memUsedPerc.toFixed(1) + "%</b>]", "noderesbar_memres", memUsedPerc.toFixed(1));
				row.appendChild(memresbar);	
				
				row.innerHTML += "<br/>";
				
			}
			else{
				console.log("failed to get hypervisor for: " + nodeName);
			}
			
			divNodeRes.appendChild(row);
			accordion.appendChild(divNodeRes);
		}
		else{
			console.log("FAILED!!");
		}
		
		root.appendChild(accordion);
	}
	else{
		resNodeOfflineTotal++;
	}

}

