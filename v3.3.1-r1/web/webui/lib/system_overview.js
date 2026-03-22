/**
 * ETHER|AAPEN|WEB - LIB|SYSTEM|OVERVIEW
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/


/**
 * Asynchronously displays the system overview
 * @description Initializes and displays the main system overview table
 */
function system_overview_show() {
	if(document.getElementById("switchSysSortId").checked){
		system_overview_id("");
	}
	else{
		system_overview_name("");
	}
	
}

//
// TODO new overview
//
function system_overview_sort(sorting) {

	var sysArray = [];

	sysList = dbnew_system_index_get();	

	sysList.forEach((sysName) => {
		var systemData = dbnew_system_get(sysName);
		
		// add stats
		sysArray.push({
			key: systemData.id.name,
			id: systemData.id.id,
			name: systemData.id.name,
			group: systemData.id.group,
		});
		
	});

	if(sorting == "id"){
		sysArray.sort(function (x, y) {
			return x.id - y.id;
		});
	}	
	
	// cpu utilization
	if(sorting == "name"){
		sysArray.sort(function (x, y) {
			return y.name - x.name;
		});
	}

	return sysArray;
}

//
//
//
function system_overview_id(query) {
	document.getElementById("switchSysSortId").checked = true;
	document.getElementById("switchSysSortName").checked = false;
	system_overview_group_select_build();
	system_overview_generate(query, "id", "");
}

//
//
//
function system_overview_name(query) {
	document.getElementById("switchSysSortId").checked = false;
	document.getElementById("switchSysSortName").checked = true;
	system_overview_group_select_build();
	system_overview_generate(query, "name", "");
}

//
//
//
function system_overview_group_select_build() {
	var sysGroupList = dbnew_system_group_get();
	sysGroupList = sort_alpha(sysGroupList);

	// clear selector
	var sysGroupSelect = document.getElementById("systemOvGroupSelect");
	sysGroupSelect.innerHTML = "";
	
	// all option
	var option = document.createElement("option");
	option.value = "All";
	option.innerHTML = "All";
	sysGroupSelect.appendChild(option);
	
	// group options
	sysGroupList.forEach((group) => {
		var option = document.createElement("option");
		option.value = group;
		option.innerHTML = group;
		sysGroupSelect.appendChild(option);
	});
	
	sysGroupSelect.onchange = function() { system_overview_group_select_change() };
}

//
//
//
function system_overview_group_select_change() {
	var sysGroupSelect = document.getElementById("systemOvGroupSelect");
	
	var sortType = "id";
	if(document.getElementById("switchSysSortName").checked){
		sortType = "name";
	}
	
	var searchboxSysOv = document.getElementById("system-ov-search-bar");
	
	system_overview_generate(searchboxSysOv.value, sortType, sysGroupSelect.value);
}

/**
 * Adds systems to the overview table based on search query
 * @param {string} query - Search query to filter systems
 * @description Populates the system overview table with matching systems, 
 * including their status, resource usage, and node information
 */
function system_overview_generate(query, sorting, group) {

	var searchboxSysOv = document.getElementById("system-ov-search-bar");
	var match = 0;
	
	$("#sysTable tbody tr").remove();
	var tbody = $("#sysTable tbody");
	
	var memory = 0;
	var cores = 0;
	var online = 0;
	var offline = 0;
	
	var sysList = dbnew_system_index_get();
	
	main_view_set('system_overview', '', '');
	
	//clear search on new init
	if(query == ""){
		searchboxSysOv.value = "";
	}
	
	let sysArray = system_overview_sort(sorting);
	
	sysArray.forEach((element, index, array) => {

		var sysName = element.key;
	
		var match = 0;
		var groupMatch = 1;
		var systemData = dbnew_system_get(sysName);
		
		// search
		if(searchboxSysOv.value !== ""){
			match = newSearch(systemData, searchboxSysOv.value);
		}

		// group sort
		if(group !== ""){
			if(systemData.id.group == group){
				groupMatch = 1;
			}
			else if(group == "All"){
				groupMatch = 1;
			}
			else{
				groupMatch = 0;
			}
		}

		// process systems
		if(((searchboxSysOv.value == "") || match) && groupMatch){

			if(systemData.meta.state == "1"){
				const nodeName = systemData.meta.node_name;
			
				if($('#switchSysShowOnline').prop('checked')){
					
					if((typeof systemData.meta.stats !== 'undefined') &&  (typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.hw !== 'undefined')){
						var diff = date_str_diff_now(systemData.object.meta.date);
						tbody.append("<tr><td><b>" + systemData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_systbl" class="btn btn-link tablebtn">' + systemData.id.name  + "</a></b></td><td>" + systemData.id.group + "</td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><td><b>" + systemData.hw.cpu.core + "</b></td><td><b>" + systemData.hw.mem.mb + " MB</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_systbl_node" class="btn btn-link tablebtn">' + systemData.meta.node_name  + "</a></b></td><td>" + systemData.object.meta.ver + "</td><td><b>" + diff + "</b></td><td>" + systemData.meta.stats.hypervisor.uptime + "</td><td><b>" + systemData.meta.stats.hypervisor.cpu + "%</b></td><td><b>" + systemData.meta.stats.hypervisor.mem + "%</b></td><td><b>" + systemData.meta.stats.hypervisor.rss + "</b></td><tr>");
					}
					else{
						if((typeof system.hw !== 'undefined')){
							tbody.append("<tr><td><b>" + system.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_systbl" class="btn btn-link tablebtn">' + systemData.id.name  + "</a></b></td><td>" + systemData.id.group + "</td><td>" + '<b style="color:#24be14">ONLINE</b>' + "</td><td><b>" + systemData.hw.cpu.core + "</b></td><td><b>" + systemData.hw.mem.mb + " MB</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_systbl_node" class="btn btn-link tablebtn">' + systemData.meta.node_name  + "</a></b><</td><td>" + systemData.object.meta.ver + "</td><td>" + systemData.object.meta.date + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><tr>");
						}
						else{
							console.log(sysName);
						}
					}
				
					// node button
					document.getElementById("tempbtn_systbl_node").id = "btn_systbl_node_" + sysName;
					document.getElementById("btn_systbl_node_" + sysName).onclick = function() { node_show(nodeName) };
				
					// system button
					document.getElementById("tempbtn_systbl").id = "btn_systbl_sys_" + sysName;	
					document.getElementById("btn_systbl_sys_" + sysName).onclick = function() { system_show(sysName) };
				}
				
				cores += parseInt(systemData.hw.cpu.core);
				memory += parseInt(systemData.hw.mem.mb);
				online++;
				
			}
			else{
				
				if($('#switchSysShowOffline').prop('checked')){
				
					tbody.append("<tr><td><b>" + systemData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_systbl" class="btn btn-link tablebtn">' + systemData.id.name  + "</a></b></td><td>" + systemData.id.group + "</td><td>" + "<b>OFFLINE</b>" + "</td><td><b>" + systemData.hw.cpu.core + "</b></td><td><b>" + systemData.hw.mem.mb + " MB</b></td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><tr>");
					
					document.getElementById("tempbtn_systbl").id = "btn_systbl_sys_" + sysName;
					document.getElementById("btn_systbl_sys_" + sysName).onclick = function() { system_show(sysName) }; 	
				}
				
				offline++;

			}
		}
		
	});
	
	//convert memory to GB
	memory = (memory / 1024);
	
	// stats
	document.getElementById("main-system-overview-sys-offline").innerHTML = "<b>" + offline + "</b>";
	document.getElementById("main-system-overview-sys-online").innerHTML = "<b>" + online + "</b>";
	document.getElementById("main-system-overview-mem-online").innerHTML = "<b>" + memory.toFixed(0) + " GB</b>";
	document.getElementById("main-system-overview-core-online").innerHTML = "<b>" + cores + "</b>";
	

	// init system search
	searchboxSysOv.addEventListener("keypress", function(eventSysOv) {
		if(eventSysOv.key === "Enter") {
			eventSysOv.preventDefault();
			log_write_json("sys_ov_search_bar", "[system-ov-search-bar]", "query [" + searchboxSysOv.value + "]");
			if(document.getElementById("switchSysSortName").checked){
				system_overview_generate(searchboxSysOv.value, "name", group);
			}
			else{
				system_overview_generate(searchboxSysOv.value, "id", group);
			}
		}
	}); 
	
}

//
//
//
function system_resources_show() {
	
	document.getElementById("accordionSystemResource").innerHTML = "";
	document.getElementById("systemResSortSelect").onchange = function() { system_resources_show() };
	
	$("#systemResOverviewTable tbody tr").remove();

	sysList = dbnew_system_index_get();	
	
	main_view_set('system_resources', '', '');

	var sysResArray = [];
	
	var totSys = 0;
	
	var totCpuCore = 0;
	var totCpuPerc = 0;
	
	var totMemAlloc = 0;
	var totMemUse = 0;
	
	var totStorAlloc = 0;
	var totStorUse = 0;
	
	var totNetPackets = 0
	var totNetBytes = 0;
	
	sysList.forEach((sysName) => {
		var systemData = dbnew_system_get(sysName);
		
		if(systemData.meta.state == "1"){
						
			var cpuPerc = 0;
			var cpuPercTot = 0;
			
			var memUsed = 0;
			var memPerc = 0;
			var memUsedMB = 0;
			
			var netTotPackets = 0;
			var netTotBytes = 0;
			
			var diskCfgSize = 0;
			//var diskSize = 0;
			var diskUsage = 0;
	
			// check for hypervisor stats
			if((typeof systemData.meta.stats !== 'undefined') && (typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.meta.stats.hypervisor.rss !== 'undefined') && (typeof systemData.hw !== 'undefined')) {
		
				// cpu
				cpuPercTot = parseInt(systemData.hw.cpu.core) * 100;
				cpuPerc = (100 * parseInt(systemData.meta.stats.hypervisor.cpu)) / cpuPercTot;
		
				totCpuCore += parseInt(systemData.hw.cpu.core);
				totCpuPerc += parseInt(systemData.meta.stats.hypervisor.cpu);
		
				// memory
				if(systemData.meta.stats.hypervisor.rss.includes('M')){
					memGB = parseInt(systemData.hw.mem.mb);
					memPerc = (100 * parseFloat(systemData.meta.stats.hypervisor.rss)) / memGB;
					memUsed = memGB + "M";
					memUsedMB = parseFloat(systemData.meta.stats.hypervisor.rss);
				}
			
				if(systemData.meta.stats.hypervisor.rss.includes('G')){
					memGB = parseInt(systemData.hw.mem.mb / 1024);
					memPerc = (100 * parseFloat(systemData.meta.stats.hypervisor.rss)) / memGB;
					memUsed = memGB + "G";
					memUsedMB = parseFloat(systemData.meta.stats.hypervisor.rss) * 1024;
				}
				
				totMemAlloc += parseInt(systemData.hw.mem.mb);
				totMemUse += memUsedMB;
				
				// network devices
				var nic = systemData.net.dev;
				nicIndex = nic.split(';');
	
				nicIndex.forEach((nicDev) => {
					var netTxPackets = 0;
					var netTxBytes = 0;
					var netRxPackets = 0;
					var netRxBytes = 0;
				
					if((typeof systemData.meta.stats.network !== 'undefined') && (typeof systemData.meta.stats.network[nicDev] !== 'undefined')) {
					
						// tx
						if((typeof systemData.meta.stats.network[nicDev].tx.bytes !== 'undefined') && (typeof systemData.meta.stats.network[nicDev].tx.packets !== 'undefined')) {
							netTxBytes += parseInt(systemData.meta.stats.network[nicDev].tx.bytes);
							netTxPackets += parseInt(systemData.meta.stats.network[nicDev].tx.packets);
						}
					
						// rx
						if((typeof systemData.meta.stats.network[nicDev].rx.bytes !== 'undefined') && (typeof systemData.meta.stats.network[nicDev].rx.packets !== 'undefined')) {
							netRxBytes += parseInt(systemData.meta.stats.network[nicDev].rx.bytes);
							netRxPackets += parseInt(systemData.meta.stats.network[nicDev].rx.packets);
						}
					
						netTotBytes += netRxBytes + netTxBytes;
						netTotPackets += netRxBytes + netRxPackets;
					}
				});
				
				// convert to MB
				netTotData = niceBytes(netTotBytes);

				totNetPackets += netTotPackets;
				totNetBytes += netTotBytes;

				// storage devices
				var stor = systemData.stor.disk;
				storIndex = stor.split(';');
	
				storIndex.forEach((storDev) => {
			
					if((typeof systemData.stor[storDev].size !== 'undefined')) {
						diskCfgSize += parseInt(systemData.stor[storDev].size);
					}
			
					if((typeof systemData.meta.stats.hypervisor !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk[storDev] !== 'undefined') && (typeof systemData.meta.stats.hypervisor.disk[storDev].size !== 'undefined')) {
						diskUsage += parseInt(systemData.meta.stats.hypervisor.disk[storDev].size);
					}
			
				});
				
				totStorAlloc += diskCfgSize;
				totStorUse += diskUsage;
				
				// add stats
				sysResArray.push({
					key: systemData.id.name,
					cpuNum: parseInt(systemData.hw.cpu.core) * parseInt(systemData.hw.cpu.sock),
					cpuLoad: systemData.meta.stats.hypervisor.cpu,
					cpuPerc: cpuPerc,
					memNum: systemData.hw.mem.mb,
					memUsedMB: memUsedMB.toFixed(0),
					memPerc: memPerc.toFixed(0),
					memUsed: systemData.meta.stats.hypervisor.rss,
					netTotPackets: netTotPackets,
					netTotData: netTotData,
					netTotBytes: netTotBytes,
					diskCfgSize: diskCfgSize,
					diskUsage: diskUsage,
				});
				
			}
		}
		
		totSys++;			
	});		
			

	var totNetData = niceBytes(totNetBytes);
	totMemUse = niceMBytes(totMemUse);
	totMemAlloc = niceMBytes(totMemAlloc);

	// update header
	var header2 = "Systems [ <b> " + totSys + " </b> ] cpus allocated [ <b>" + totCpuCore + "</b> ] memory allocated [ <b> " + totMemAlloc +  " </b> ]";
	document.getElementById('main-system-resview-header').innerHTML = header2;


	//systemResOverviewTable
	var tbody = $("#systemResOverviewTable tbody");
	tbody.append("<tr><td>" + totSys + "</td><td>" + totCpuCore + "</td><td>" + totMemAlloc + "</td><td>" + totMemUse + "</td><td>" + totStorAlloc + " GB</td><td>" + totStorUse + " GB</td><td>" + totNetData + "</td></tr>");	


	// find sorting 
	var sorting = document.getElementById("systemResSortSelect").value;
	
	// cpu utilization
	if(sorting == "cpu-util-abs"){
		sysResArray.sort(function (x, y) {
			return y.cpuLoad - x.cpuLoad;
		});
	}
	
	// cpu utilization
	if(sorting == "cpu-util-rel"){
		sysResArray.sort(function (x, y) {
			return y.cpuPerc - x.cpuPerc;
		});
	}	

	// cpu utilization
	if(sorting == "cpu-core-alloc"){
		sysResArray.sort(function (x, y) {
			return y.cpuNum - x.cpuNum;
		});
	}

	// cpu utilization
	if(sorting == "ram-util"){
		sysResArray.sort(function (x, y) {
			return y.memPerc - x.memPerc;
		});
	}
	
	// cpu utilization
	if(sorting == "ram-alloc"){
		sysResArray.sort(function (x, y) {
			return y.memNum - x.memNum;
		});
	}
	
	// cpu utilization
	if(sorting == "ram-used"){
		sysResArray.sort(function (x, y) {
			return y.memUsedMB - x.memUsedMB;
		});
	}	
	
	// cpu utilization
	if(sorting == "net-packets"){
		sysResArray.sort(function (x, y) {
			return y.netTotPackets - x.netTotPackets;
		});
	}	

	// cpu utilization
	if(sorting == "net-data"){
		sysResArray.sort(function (x, y) {
			return y.netTotBytes - x.netTotBytes;
		});
	}	

	if(sorting == "stor-alloc"){
		sysResArray.sort(function (x, y) {
			return y.diskCfgSize - x.diskCfgSize;
		});
	}	

	if(sorting == "stor-used"){
		sysResArray.sort(function (x, y) {
			return y.diskUsage - x.diskUsage;
		});
	}	
	

	// build view
	sysResArray.forEach((element, index, array) => {
		system_resource_accordion(element.key, element);
	});
	
}

//
//
// 
function system_resource_accordion(systemName, sysRes) {

	var header;
	var root = document.getElementById('accordionSystemResource');
	var headerDiv = document.createElement("div");
	
	header = "System [<b> " + systemName + " </b>] - ";
	header += " cpus [<b> " + sysRes.cpuNum + " </b>] cpu load [<b>" + sysRes.cpuLoad + " %</b>] cpu util [<b>" + sysRes.cpuPerc + " %</b>]";
	header += " ram [<b> " + sysRes.memNum + " MB </b>] ram use [<b>" + sysRes.memUsedMB + " MB </b>] mem util [<b>" + sysRes.memPerc + " %</b>]";
	
	var accordion = view_accordion_build("accordionSystemRes" + systemName, "collapseSystemRes" + systemName, "bi-display", header);

	var divSystemRes = view_accordion_element_build("collapseSystemRes" + systemName, "headingSystemResource", "accordionSystemRes" + systemName);
	
	var row = document.createElement("div");
	row.setAttribute("id", "sysResView");
	row.setAttribute("class", "row row-space g-1 mt-2 ms-1 mb-3 me-5");

	// cpu load
	var cpuloadbar = view_bar_add("cpu", " cores [<b> " + sysRes.cpuNum + " </b>] load [<b> " + sysRes.cpuLoad  + " % </b>] utilization [<b> " + sysRes.cpuPerc  + " % </b>]", "sysres_cpuload", sysRes.cpuPerc);
	row.appendChild(cpuloadbar);
	
	var ramloadbar = view_bar_add("ram", " total [<b> " + sysRes.memNum + " MB </b>] used [<b> " + sysRes.memUsedMB + " MB </b>] utilization [<b> " + sysRes.memPerc + " % </b>]", "sysres_ramload", sysRes.memPerc);
	row.appendChild(ramloadbar);
	
	
	// 
	// storage
	//
	var storPerc = (100 * parseInt(sysRes.diskUsage)) / parseInt(sysRes.diskCfgSize);
	var storloadbar = view_bar_add("storage", " total [<b> " + sysRes.diskCfgSize + " GB </b>] used [<b> " + sysRes.diskUsage + " GB </b>] utilization [<b> " + storPerc.toFixed(0) + " % </b>]", "sysres_ramload", storPerc.toFixed(0));
	row.appendChild(storloadbar);
	
	
	var network = document.createElement("div");
	network.setAttribute("class", "g-2 ms-4 mb-2");
	network.innerHTML = "[ <b> network </b> ] total packets [ <b>" + sysRes.netTotPackets + "</b> ] data [ <b>" + sysRes.netTotData + "</b> ]";
	
	row.appendChild(network);
			
	row.innerHTML += "<br/>";

	divSystemRes.appendChild(row);
	accordion.appendChild(divSystemRes);

	root.appendChild(accordion);	
}
