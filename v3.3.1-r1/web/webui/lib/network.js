/**
 * ETHER|AAPEN|WEB - LIB|NETOWRK
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

/**
 * Removes all network menu items from bridge, trunk and VPP sections
 * @returns {void}
 */
function net_menu_remove_all() {
	document.getElementById("collapse-net-bridge").innerHTML = "";
	document.getElementById("collapse-net-trunk").innerHTML = "";
	document.getElementById("collapse-net-vpp").innerHTML = "";
}

/**
 * Removes all online network menu items
 * @returns {void}
 */
function net_menu_remove_online() {
	document.getElementById("collapse-net-online").innerHTML = "";
}

/**
 * Adds a network bridge item to the menu
 * @param {string} netName - Name of the network bridge to add
 * @returns {void}
 */
function net_menu_add_bridge(netName) {
	const func = function() { net_show(netName) };
	menu_add_item(netName, 'collapse-net-bridge', "net_" + netName, "bi-diagram-3", func);
}

/**
 * Adds a network trunk item to the menu  
 * @param {string} netName - Name of the network trunk to add
 * @returns {void}
 */
function net_menu_add_trunk(netName) {
	const func = function() { net_show(netName) };
	menu_add_item(netName, 'collapse-net-trunk', "net_" + netName, "bi-diagram-3", func);
}

/**
 * Adds a VPP network item to the menu
 * @param {string} netName - Name of the VPP network to add  
 * @returns {void}
 */
function net_menu_add_vpp(netName) {
	const func = function() { net_show(netName) };
	menu_add_item(netName, 'collapse-net-vpp', "net_" + netName, "bi-diagram-3", func);
}

//
//
//
function net_show(netName) {
	main_hide_all();
	main_net_show();
	
	// get network
	var netData = dbnew_network_get(netName);
	
	main_view_set('network_show', netName, '');
	
	// refresh
	document.getElementById("main-net-btn-json").onclick = function() { json_show("[ " + netName + " ]", netName, "net", netData) };
	
	// process metadata			
	if(typeof netData.object.meta !== 'undefined'){
		document.getElementById("main-net-state").innerHTML = 'State [<b style="color:#24be14">ONLINE</b>]' + " ver [<b>" + netData.object.meta.ver + "</b>] owner [<b>" + netData.object.meta.owner_name + "</b>] updated [<b>" + netData.object.meta.date + "</b>]"
	}
	else{
		document.getElementById("main-net-state").innerHTML = "Status [<b>" + "LOCAL" +"</b>]"
	}
	
	//
	// header
	//
	document.getElementById("main-net-header").textContent = "[ " + netName + " ]";
	document.getElementById("main-net-identity").innerHTML = "Name [" + '<b style="color:#0040ff">' + netData.id.name + "</b>] id [<b>" + netData.id.id + "</b>] desc [<b>" + netData.id.desc + "</b>]";
	document.getElementById("net-type-header").innerHTML = "Type [<b>" + netData.meta.type + "</b>] model [<b>" + netData.object.model + "</b>] class [<b>" + netData.object.class + "</b>]";

	//new
	document.getElementById("main-network-name").value = netData.id.name;
	document.getElementById("main-network-uid").value = netData.id.id;
	document.getElementById("main-network-desc").value = netData.id.desc;

	document.getElementById("main-network-class").value = netData.object.class;
	document.getElementById("main-network-model").value = netData.object.model;
	document.getElementById("main-network-type").value = netData.object.type;

	
	if(netData.object.class === "trunk"){
		document.getElementById("main-network-opt0-label").innerHTML = "TRUNK bridge";
		document.getElementById("main-network-opt0-input").value = netData.trunk.bridge;
		
		document.getElementById("main-network-opt1-label").innerHTML = "TRUNK driver";
		document.getElementById("main-network-opt1-input").value = netData.trunk.driver;
		
		document.getElementById("main-network-opt2-label").innerHTML = "TRUNK mode";
		document.getElementById("main-network-opt2-input").value = "BRI-TAP";
		
		document.getElementById("main-network-addr").value = "n/a";
		document.getElementById("main-network-mask").value = "n/a";
		document.getElementById("main-network-dhcp").value = "n/a";
		
		document.getElementById("main-net-address").innerHTML = "Address [<b>" + "n/a" + "</b>] mask [<b>" + "n/a" + "</b>] dhcp [<b>" + "n/a" + "</b>]";
	}
	
	if(netData.object.model === "tap" && netData.object.class === "vlan"){
		document.getElementById("main-network-opt0-label").innerHTML = "VLAN tag";
		document.getElementById("main-network-opt0-input").value = netData.vlan.tag;
		
		document.getElementById("main-network-opt1-label").innerHTML = "VLAN bridge";
		document.getElementById("main-network-opt1-input").value = netData.vlan.bridge;
		
		document.getElementById("main-network-opt2-label").innerHTML = "VLAN driver";
		document.getElementById("main-network-opt2-input").value = netData.vlan.driver;
		
		document.getElementById("main-network-addr").value = netData.addr.ip;
		document.getElementById("main-network-mask").value = netData.addr.mask;
		document.getElementById("main-network-dhcp").value = netData.addr.dhcp;
		
		document.getElementById("main-net-address").innerHTML = "Address [<b>" + netData.addr.ip + "</b>] mask [<b>" + netData.addr.mask + "</b>] dhcp [<b>" + netData.addr.dhcp + "</b>]";
	}

	if(netData.object.model === "vpp"){
		document.getElementById("main-network-opt0-label").innerHTML = "VLAN tag";
		document.getElementById("main-network-opt0-input").value = netData.vpp.tag;
		
		document.getElementById("main-network-opt1-label").innerHTML = "VLAN bridge";
		document.getElementById("main-network-opt1-input").value = netData.vpp.bridge;
		
		document.getElementById("main-network-opt2-label").innerHTML = "VLAN driver";
		document.getElementById("main-network-opt2-input").value = "8021q";
		
		document.getElementById("main-network-addr").value = netData.addr.ip;
		document.getElementById("main-network-mask").value = netData.addr.mask;
		document.getElementById("main-network-dhcp").value = netData.addr.dhcp;
		
		document.getElementById("main-net-address").innerHTML = "Address [<b>" + netData.addr.ip + "</b>] mask [<b>" + netData.addr.mask + "</b>] dhcp [<b>" + netData.addr.dhcp + "</b>]";			
	}

	//
	// process nodes
	//
	var nodeIndex = netData.node.index;
	nodeList = nodeIndex.split(';');
	nodeList = sort_alpha(nodeList);
	//nodeList.sort(function(a, b){ return a - b });

	$("#netNodeTable tbody tr").remove();
	var tbody = $("#netNodeTable tbody");

	nodeList.forEach((node) => {
		tbody.append("<tr><td><b>" + node + "</b></td><td><b>" + node + "</b></td><td>" + netData.node[node] + "</td></tr>");
	});
	
	//
	// stats
	//
	$("#netNodeStatsTable tbody tr").remove();
	var tbody = $("#netNodeStatsTable tbody");
	
	$("#netSystemTable tbody tr").remove();
	var tbodysys = $("#netSystemTable tbody");
	
	var nodeListOnline = dbnew_node_index_online_get();
	var systemOnlineNum = 0;
	var nodeActiveNum = 0;
	
	nodeListOnline = sort_alpha(nodeListOnline);
	//nodeListOnline.sort(function(a, b){ return a - b });

	document.getElementById("main-network-node-config-header").innerHTML = "Configuration - Nodes [<b>" + nodeListOnline.length + "</b>]";
	
	nodeListOnline.forEach((nodeName) => {
		
		if(typeof netData.meta.stats !== 'undefined' && typeof netData.meta.stats[nodeName] !== 'undefined' && netData.meta.stats[nodeName] !== null){
	
			if(netData.object.model === "tap"){
				
				if(typeof netData.meta.stats[nodeName].vm !== 'undefined' && netData.meta.stats[nodeName].vm !== null){
					tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netnodetbl" class="btn btn-link tablebtn">' + nodeName  + "</a></b></td><td><b>" + "BRI-TAP" + "</b></td><td><b>" + netData.meta.stats[nodeName].netdev + "</b></td><td><b>" + netData.meta.stats[nodeName].brdev + "</b></td><td><b>" + netData.meta.stats[nodeName].vm.name + "</b></td><td><b>" + netData.meta.stats[nodeName].tx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].rx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].updated + "</b></td></tr>");
					document.getElementById("tempbtn_netnodetbl").id = "tempbtn_netnodetbl_" + nodeName;
					document.getElementById("tempbtn_netnodetbl_" + nodeName).onclick = function() { node_show(nodeName) };
					
				}
				else{
					tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netnodetbl" class="btn btn-link tablebtn">' + nodeName  + "</a></b></td><td><b>" + "BRI-TAP" + "</b></td><td><b>" + netData.meta.stats[nodeName].netdev + "</b></td><td><b>" + netData.meta.stats[nodeName].brdev + "</b></td><td><b>" + "" + "</b></td><td><b>" + netData.meta.stats[nodeName].tx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].rx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].updated + "</b></td></tr>");
					document.getElementById("tempbtn_netnodetbl").id = "tempbtn_netnodetbl_" + nodeName;
					document.getElementById("tempbtn_netnodetbl_" + nodeName).onclick = function() { node_show(nodeName) };
				}
					
				nodeActiveNum++;
			}

			if(netData.object.model === "vpp"){
				
				if(typeof netData.meta.stats[nodeName] !== 'undefined' && typeof netData.meta.stats[nodeName].vm !== 'undefined' && netData.meta.stats[nodeName].vm !== null){
					tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netnodetbl" class="btn btn-link tablebtn">' + nodeName  + "</a></b></td><td><b>" + "VPP" + "</b></td><td><b>" + netData.meta.stats[nodeName].interface + "</b></td><td><b>" + netData.meta.stats[nodeName].if_idx + "</b></td><td><b>" + netData.meta.stats[nodeName].vm.name + "</b></td><td><b>" + netData.meta.stats[nodeName].tx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].rx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].updated + "</b></td></tr>");
					document.getElementById("tempbtn_netnodetbl").id = "tempbtn_netnodetbl_" + nodeName;	
					document.getElementById("tempbtn_netnodetbl_" + nodeName).onclick = function() { node_show(nodeName) };
					nodeActiveNum++;
				}
				else{
					// fix vpp bug
					if(typeof netData.meta.stats[nodeName].tx !== 'undefined'){
						tbody.append("<tr><td>" + '<b style="color:#0040ff"><a id="tempbtn_netnodetbl" class="btn btn-link tablebtn">' + nodeName  + "</a></b></td><td><b>" + "VPP" + "</b></td><td><b>" + netData.meta.stats[nodeName].interface + "</b></td><td><b>" + netData.meta.stats[nodeName].if_idx + "</b></td><td><b>" + "" + "</b></td><td><b>" + netData.meta.stats[nodeName].tx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].rx.data + "</b></td><td><b>" + netData.meta.stats[nodeName].updated + "</b></td></tr>");
						document.getElementById("tempbtn_netnodetbl").id = "tempbtn_netnodetbl_" + nodeName;
						document.getElementById("tempbtn_netnodetbl_" + nodeName).onclick = function() { node_show(nodeName) };
						nodeActiveNum++;
					}
				}
			}

			//
			// systems
			//
			
			// active systems
			document.getElementById("main-network-system-header").innerHTML = "Statistics - Systems [<b>0</b>]";
			
			if(typeof netData.meta.stats[nodeName].vm !== 'undefined' && netData.meta.stats[nodeName].vm !== null){
				var syslist = netData.meta.stats[nodeName].vm.name.split(';');
				syslist.sort(function(a, b){ return a - b });
				systemOnlineNum += syslist.length;

				syslist.forEach((system) => {
					system_network_stats(system, netName);
				});	
			}

		}
		
	});
	
	document.getElementById("main-network-system-header").innerHTML = "Statistics - Systems [<b>" + systemOnlineNum + "</b>]";
	document.getElementById("main-network-node-stats-header").innerHTML = "Statistics - Active Nodes [<b>" + nodeActiveNum + "</b>]";	
}

//
// process system metadata
//
function network_db_process_rest_new(db){
	var fid = "[<b>net_conf_meta_rest_process</b>]";

	net_menu_remove_all();
	
	vlanNum = 0;
	trunkNum = 0;
	vppNum = 0;

    // process networks
    const netIndex = db.network.index;
    let netList = netIndex.split(';');
    //netList.sort((a, b) => a - b);
	netList = sort_alpha(netList);
	//nodeListOnline.sort(function(a, b){ return a - b });

	netList.forEach((netName) => {

		if(db.network.db[netName].object.model == "tap"){
			
			if(db.network.db[netName].object.class == "vlan"){
				net_menu_add_bridge(netName);
				vlanNum++;
			}
			
			if(db.network.db[netName].object.class == "trunk"){
				net_menu_add_trunk(netName);
				trunkNum++;
			}
			
			dbnew_network_tuntap_index_add(netName);
		}
		
		if(db.network.db[netName].object.model == "vpp"){
			net_menu_add_vpp(netName);
			dbnew_network_vpp_index_add(netName);
			vppNum++;
		}
		
		
		dbnew_network_index_add(netName);
		
	});

	document.getElementById('menu-net-vlan').innerHTML = "Vlan (" + vlanNum + ")";
	document.getElementById('menu-net-trunk').innerHTML = "Trunk (" + trunkNum + ")";
	document.getElementById('menu-net-vpp').innerHTML = "VPP (" + vppNum + ")";

	document.getElementById('main-card-network').innerHTML = "VLANs [<b>" + vlanNum + "</b>] Trunks [<b>" + trunkNum + "</b>]<br/>VPP Networks [<b>" + vppNum + "</b>]";

	// generate overview
	net_overview_generate(db.network);

}

//
// network overview add
//
function net_overview_generate(dbNet) {

	$("#netTable tbody tr").remove();	
	var tbody = $("#netTable tbody");
	
	var cluster = 0;
	var local = 0;
	var vlan = 0;
	var trunk = 0;
	var tuntap = 0
	var vpp = 0;
	
    // process networks
    const netIndex = dbNet.index;
    let netList = netIndex.split(';');
    //netList.sort((a, b) => a - b);
    netList = sort_alpha(netList);

	netList.forEach((netName) => {

		// node index
		var nodeIndex = dbNet.db[netName].node.index.split(";");
		var nodeNetList = "";
		
		nodeIndex.forEach((nodeId) => {
			var nodeName = dbnew_node_id_to_name(nodeId);

			if(nodeName){
				var nodeBtn = '<b style="color:#0040ff"><a id="tempbtn_node_netov" class="btn btn-link tablebtn">' + nodeName + "</a></b>";
				nodeNetList += nodeBtn + " ";
			}
			
		});
		
		// TUNTAP
		if(dbNet.db[netName].object.model == "tap"){
			
			// VLAN
			if(dbNet.db[netName].object.class == "vlan"){
				if((typeof dbNet.db[netName].object.meta !== 'undefined')){
					tbody.append("<tr><td><b>" + dbNet.db[netName].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netov" class="btn btn-link tablebtn">' + dbNet.db[netName].id.name + "</a></b></td><td><b>" + "TAP" + "</b></td><td>" + dbNet.db[netName].object.class + "</td><td><b>" + dbNet.db[netName].vlan.tag + "</b></td><td>" + nodeNetList + "</td><td>" + dbNet.db[netName].addr.ip + "</td><td>" + dbNet.db[netName].addr.mask + "</td><td>" + '<b style="color:#24be14">CLUSTER</b>' + "</td><tr>");
					cluster++;
				}
				else{
					tbody.append("<tr><td><b>" + dbNet.db[netName].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netov" class="btn btn-link tablebtn">' + dbNet.db[netName].id.name + "</a></b></td><td><b>" + "TAP" + "</b></td><td>" + dbNet.db[netName].object.class + "</td><td><b>" + dbNet.db[netName].vlan.tag + "</b></td><td>" + nodeNetList + "</td><td>" + dbNet.db[netName].addr.ip + "</td><td>" + dbNet.db[netName].addr.mask + "</td><td><b>" + "LOCAL" + "</b><tr>");
					local++;
				}
				
				vlan++;
			}
			
			// TRUNK
			if(dbNet.db[netName].object.class == "trunk"){
				if(typeof dbNet.db[netName].object.meta !== 'undefined'){
					tbody.append("<tr><td><b>" + dbNet.db[netName].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netov" class="btn btn-link tablebtn">' + dbNet.db[netName].id.name + "</a></b></td><td><b>" + "TAP" + "</b></td><td>" + dbNet.db[netName].object.class + "</td><td><b>" + "TRUNK" + "</b></td><td>" + nodeNetList + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + '<b style="color:#24be14">CLUSTER</b>' + "<tr>");
					cluster++;
				}
				else{
					tbody.append("<tr><td><b>" + dbNet.db[netName].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netov" class="btn btn-link tablebtn">' + dbNet.db[netName].id.name + "</a></b></td><td><b>" + "TAP" + "</b></td><td>" + dbNet.db[netName].object.class + "</td><td><b>" + "TRUNK" + "</b></td><td>" + nodeNetList + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td><b>" + "LOCAL" + "</b><tr>");
					local++;
				}
				
				trunk++;
			}
			
			tuntap++;
		}		
		
		// VPP
		if(dbNet.db[netName].object.model == "vpp"){
			if(typeof dbNet.db[netName].object.meta !== 'undefined'){
				tbody.append("<tr><td><b>" + dbNet.db[netName].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netov" class="btn btn-link tablebtn">' + dbNet.db[netName].id.name + "</a></b></td><td><b>" + "VPP" + "</b></td><td>" + dbNet.db[netName].object.class + "</td><td><b>" + dbNet.db[netName].vpp.tag + "</b></td><td>" + nodeNetList + "</td><td>" + dbNet.db[netName].addr.ip + "</td><td>" + dbNet.db[netName].addr.mask + "</td><td>" + '<b style="color:#24be14">CLUSTER</b>' + "</td><tr>");	
				cluster++;
			}
			else{
				tbody.append("<tr><td><b>" + dbNet.db[netName].id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netov" class="btn btn-link tablebtn">' + dbNet.db[netName].id.name + "</a></b></td><td><b>" + "VPP" + "</b></td><td>" + dbNet.db[netName].object.class + "</td><td><b>" + dbNet.db[netName].vpp.tag + "</b></td><td>" + nodeNetList + "</td><td>" + dbNet.db[netName].addr.ip + "</td><td>" + dbNet.db[netName].addr.mask + "</td><td><b>" + "LOCAL" + "</td><tr>");
				local++;
			}
				
			vlan++;
			vpp++;
		}
		
		// generate network buttons
		document.getElementById("tempbtn_netov").id = "btn_netov_" + netName;
		document.getElementById("btn_netov_" + netName).onclick = function() { net_show(netName) };
	
		/*
		// add function to node
		nodeIndex.forEach((nodeName) => {
			//var nodeName = dbnew_node_id_to_name(node);
			
			if((typeof nodeName !== 'undefined') && nodeName !== ""){
				document.getElementById('tempbtn_node_netov').id = 'btn_node_netov_' + nodeName + netName;
				document.getElementById('btn_node_netov_' + nodeName + netName).onclick = function() { node_show(nodeName) };
			}	
			
		});
		*/
	
	});
	
	document.getElementById("main-net-overview-tapnet").innerHTML = "<b>" + tuntap + "</b>";
	document.getElementById("main-net-overview-vppnet").innerHTML = "<b>" + vpp + "</b>";
	
	document.getElementById("main-net-overview-vlannet").innerHTML = "<b>" + vlan + "</b>";
	document.getElementById("main-net-overview-trunknet").innerHTML = "<b>" + trunk + "</b>";

	document.getElementById("main-net-overview-cluster").innerHTML = "<b>" + cluster + "</b>";
	document.getElementById("main-net-overview-local").innerHTML = "<b>" + local + "</b>";
}

//
// network system overview show
//
function net_sys_overview_show() {

	var cluster = 0;
	var local = 0;
	var vlan = 0;
	var trunk = 0;
	var tuntap = 0
	var vpp = 0;
	
	var onlineTot = 0;
	var offlineTot = 0;
	
	document.getElementById('accordionNetworkSystemVlan').innerHTML = "";
	document.getElementById('accordionNetworkSystemTrunk').innerHTML = "";
	document.getElementById('accordionNetworkSystemVpp').innerHTML = "";
	
	main_view_set('network_sysview', '', '');
	
	netList = dbnew_network_index_get();
	
	netList.forEach((netName) => {
		//console.log("NET SYS OVERVIEW [" + netName + "]");
		var netData = dbnew_network_get(netName);
		
		$('#networkSystemTbl_' + netName + " tbody tr").remove();
		
		var onlineNum = 0;
		var offlineNum = 0;
		
		// get systems
		sysList = dbnew_system_index_get();
		
		sysList.forEach((sysName) => {
			
			var systemData = dbnew_system_get(sysName);
			
			// get network cards
			var netIndex = systemData.net.dev;
			netDevs = netIndex.split(';');
			
			netDevs.forEach((netDev) => {
				
				// check if registered to network
				if(systemData.net[netDev].net.name == netName){
					//console.log("SYSTEM [" + sysName +"] NETWORK [" + netName + "] DEVICE [" + netDev +"]");
					
					if(systemData.meta.state == "1"){
						onlineNum++;
					}
					else{
						offlineNum++;
					}
				}
				
			});
				
		});
		
		// standard
		if(netData.object.model == "tap"){
			
			if(netData.object.class == "vlan"){
				
				if((typeof netData.object.meta !== 'undefined')){
					cluster++;
				}
				else{
					local++;
				}
				
				vlan++;
				
				network_system_accordion("Vlan", netName, onlineNum, offlineNum);
			}
			
			if(netData.object.class == "trunk"){
				
				if(typeof netData.object.meta !== 'undefined'){
					cluster++;
				}
				else{
					local++;
				}
				
				trunk++;
				
				network_system_accordion("Trunk", netName, onlineNum, offlineNum);
			}
			
			tuntap++;
		}
		
		// vpp
		if(netData.object.model == "vpp"){
			if(typeof netData.object.meta !== 'undefined'){
				cluster++;
			}
			else{
				local++;
			}

			vpp++;
			
			network_system_accordion("Vpp", netName, onlineNum, offlineNum);
		}
		
		network_system_accordion_add(netData, netName);
		
		onlineTot = onlineTot + onlineNum;
		offlineTot = offlineTot + offlineNum;
		
	});
	

	document.getElementById("main-net-sys-ov-online").innerHTML = "<b>" + onlineTot + "</b>";
	document.getElementById("main-net-sys-ov-offline").innerHTML = "<b>" + offlineTot + "</b>";
	
	document.getElementById("main-net-sys-ov-bri").innerHTML = "<b>" + vlan + "</b>";
	document.getElementById("main-net-sys-ov-vpp").innerHTML = "<b>" + vpp + "</b>";
	
}

//
// network system accordion process
//
function network_system_accordion_add(netData, netName){
	var tbodyNetSys = $("#networkSystemTbl_" + netName + " tbody");
	
	// get systems
	sysList = dbnew_system_index_get();
	
	sysList.forEach((sysName) => {
		var systemData = dbnew_system_get(sysName);

		var netIndex = systemData.net.dev;
		netDevs = netIndex.split(';');

		netDevs.forEach((netDev) => {
			
			if(systemData.net[netDev].net.name == netName){
				var state = "";
				const sysname = systemData.id.name;
				
				if(systemData.meta.state == "1"){
					state = '<b style="color:#24be14">ONLINE</b>';			
				}
				else{
					state = "<b>OFFLINE</b>";
				}
				
				// check for stats
				if((typeof systemData.meta !== 'undefined') && (typeof systemData.meta.stats !== 'undefined') && (systemData.meta.stats !== null) && (typeof systemData.meta.stats.network !== 'undefined') && (typeof systemData.meta.stats.network[netDev] !== 'undefined')){
				
					if((systemData.meta.state == 1 && $('#switchNetSysShowOnline').prop('checked')) || (systemData.meta.state == 0 && $('#switchNetSysShowOffline').prop('checked'))){
				
						if(systemData.net[netDev].net.type === "bri-tap"){
							tbodyNetSys.append("<tr><td><b>" + systemData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemData.id.name + "</b></td><td><b>" + state + "</b></td><td><b>" + netDev + "</b></td><td><b>" + systemData.meta.stats.network[netDev].tx.data + "</b></td><td>" + systemData.meta.stats.network[netDev].tx.packets + "</td><td><b>" + systemData.meta.stats.network[netDev].rx.data + "</b></td><td>" + systemData.meta.stats.network[netDev].rx.packets + "</td><td>" + systemData.meta.stats.network.updated + "</td></tr>");
						}
						
						if(systemData.net[netDev].net.type === "dpdk-vpp"){
							tbodyNetSys.append("<tr><td><b>" + systemData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemData.id.name + "</b></td><td><b>" + state + "</b></td><td><b>" + netDev + "</b></td><td><b>" + systemData.meta.stats.network[netDev].tx.data + "</b></td><td>" + systemData.meta.stats.network[netDev].tx.packets + "</td><td><b>" + systemData.meta.stats.network[netDev].rx.data + "</b></td><td>" + systemData.meta.stats.network[netDev].rx.packets + "</td><td>" + systemData.meta.stats.network.updated + "</td></tr>");
						}
						
						document.getElementById("tempbtn_netsysbl").id = "tempbtn_netsysov_" + sysName + netDev;
						document.getElementById("tempbtn_netsysov_" + sysName + netDev).onclick = function() { system_show(sysName) }; 
					
					}

				}
				else{
					
					if((systemData.meta.state == 1 && $('#switchNetSysShowOnline').prop('checked')) || (systemData.meta.state == 0 && $('#switchNetSysShowOffline').prop('checked'))){
					
						if(systemData.net[netDev].net.type === "bri-tap"){
							tbodyNetSys.append("<tr><td><b>" + systemData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemData.id.name + "</b></td><td><b>" + state + "</b></td><td><b>" + netDev + "</b></td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><tr>");
						}
						
						if(systemData.net[netDev].net.type === "dpdk-vpp"){
							tbodyNetSys.append("<tr><td><b>" + systemData.id.id + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn_netsysbl" class="btn btn-link tablebtn">' + systemData.id.name + "</b></td><td><b>" + state + "</b></td><td><b>" + netDev + "</b></td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><td>" + "N/A" + "</td><tr>");
						}
						
						document.getElementById("tempbtn_netsysbl").id = "tempbtn_netsysov_" + sysName + netDev;
						document.getElementById("tempbtn_netsysov_" + sysName + netDev).onclick = function() { system_show(sysName) }; 
					
					}
					
				}
			}
		});
			
	});
	
}

//
// network system accordion build
//
function network_system_accordion(type, netName, onlineNum, offlineNum) {
	
	var root = document.getElementById('accordionNetworkSystem' + type);
	
	var onlineStr = "";
	
	if(onlineNum !== 0){
		onlineStr = '<b style="color:#24be14">' + onlineNum + "</b>";
	}
	else{
		onlineStr = '<b>' + onlineNum + "</b>";
	}
	
	var accordion = view_accordion_build("accordionNetSys" + netName, "collapseNetSys" + netName, "bi-diagram-3", "Network [<b>" + netName + "</b>] - Systems online [" + onlineStr + "] offline [<b>" + offlineNum + "</b>]");
	var divNetSys = view_accordion_element_build("collapseNetSys" + netName, "headingSystemStorage", "accordionNetSys" + netName);
	
	$("#sysStatusMessage tbody tr").remove();
	
	var row = document.createElement("div");
	row.setAttribute("class", "row row-space g-1 mt-2 ms-3 mb-2 me-2");
	row.innerHTML = '<table id="networkSystemTbl_' + netName + '" class="table table-outline table-striped table-hover"><thead><tr><th style="width: 5%">[ id ]</th><th style="width: 7%">[ name ]</th><th style="width: 5%">[ state ]</th><th style="width: 5%">[ nic ]</th><th style="width: 8%">[ tx data ]</th><th style="width: 8%">[ tx pkts ]</th><th style="width: 8%">[ rx data ]</th><th style="width: 8%">[ rx pkts ]</th><th style="width: 10%">[ updated ]</th></tr></thead><tbody></tbody></table>';
	
	divNetSys.appendChild(row);
	
	accordion.appendChild(divNetSys);
	
	root.appendChild(accordion);
}
