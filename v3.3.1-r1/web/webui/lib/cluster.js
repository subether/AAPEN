/**
 * ETHER|AAPEN|WEB - LIB|CLUSTER
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/


let monitorHost = "";


function api_node_cluster_meta(node){
	api_request('node_cluster_meta_get', 'node', node, node);
	return false;
}


function node_cluster_rest_meta(nodeName){
	api_get_request_callback_new('api_new', '/service/cluster/meta?name=' + nodeName, 'node_cluster_meta_get');
}

function node_cluster_rest_obj_get(nodeName, objType, objName){
	api_get_request_callback_new('api_new', '/service/cluster/object/get?name=' + nodeName + "&obj_type=" + objType + "&obj_name=" + objName, 'node_cluster_object_get');
}

/**
 * Shows the main cluster view and fetches cluster metadata for the default monitor host
 * @throws {Error} If no monitor host is defined
 */
function cluster_show(){
    if(!monitorHost || typeof monitorHost !== 'string'){
        throw new Error('No valid monitor host defined');
    }
    try {
        main_cluster_show();
        node_cluster_rest_meta(monitorHost);
    } catch (error) {
        console.error('Failed to show cluster:', error);
        throw error;
    }
}

/**
 * Shows the main cluster view and fetches cluster metadata for a specific node
 * @param {string} node - The node to fetch cluster metadata for
 * @throws {Error} If node parameter is invalid or API call fails
 */
function cluster_async_show(node){
    if(!node || typeof node !== 'string'){
        throw new Error('Invalid node parameter: must be non-empty string');
    }
    try {
        main_cluster_show();
        node_cluster_rest_meta(node);
    } catch (error) {
        console.error(`Failed to show cluster for node ${node}:`, error);
        throw error;
    }
}

/**
 * Removes all nodes from the cluster online menu
 * @returns {boolean} True if nodes were removed, false if element not found
 */
function cluster_menu_remove_nodes(){
    const element = document.getElementById("collapse-cluster-online");
    if(!element){
        console.warn('Cluster online menu element not found');
        return false;
    }
    element.innerHTML = "";
    return true;
}

/**
 * Removes all nodes from the cluster monitor menu
 * @returns {boolean} True if nodes were removed, false if element not found
 */
function cluster_monitor_menu_remove_nodes(){
    const element = document.getElementById("collapse-cluster-monitor");
    if(!element){
        console.warn('Cluster monitor menu element not found');
        return false;
    }
    element.innerHTML = "";
    return true;
}


/**
 * Shows the cluster node view and processes node data
 * @param {string} nodeName - Name of the node to show
 * @throws {Error} If node name is invalid or node data cannot be retrieved
 */
function cluster_node_show(nodeName){
    if(!nodeName || typeof nodeName !== 'string'){
        throw new Error('Invalid node name parameter');
    }

    try {
        const node = db_node_get(nodeName);
        if(!node){
            throw new Error(`Node ${nodeName} not found`);
        }

        main_cluster_show();
        main_view_set('cluster_node_show', nodeName, '');
        cluster_node_view_process(node);

    } catch (error) {
        console.error(`Failed to show node ${nodeName}:`, error);
        throw error;
    }
}


/**
 * Processes and displays cluster metadata from a node
 * @param {Object} data - The cluster metadata response object
 * @param {Object} data.request - The request metadata
 * @param {string} data.request.node - The node name
 * @param {Object} data.response - The response data
 * @param {Object} data.response.meta - The cluster metadata
 * @param {string} data.response.proto.result - The result status ("1" for success)
 */
function cluster_node_meta_process(data){
    if(!data || !data.request || !data.response){
        console.error('Invalid cluster metadata data');
        return;
    }

	var nodeName = monitorHost;
	//console.log(data);

    // Clear all UI elements
    const clearElements = [
        'main-cluster-header', 'main-cluster-state', 'main-cluster-nodes',
        'main-cluster-services', 'main-cluster-networks', 'main-cluster-service-framework',
        'main-cluster-service-network', 'main-cluster-service-hypervisor',
        'main-cluster-service-storage', 'main-cluster-service-monitor'
    ];

    clearElements.forEach(id => {
        const el = document.getElementById(id);
        if(el) el.innerHTML = id.includes('service') ? 
            `<b>${id.split('-').pop().toUpperCase()}</b> objects [n/a]` : 
            'Cluster state [<b>unknown</b>]';
    });

	
	// handle new node header
	if(data.response.proto.node){
		nodeName = data.response.proto.node;
	}

    // Set main header
    const headerEl = document.getElementById('main-cluster-header');
    if(headerEl){
        //headerEl.innerHTML = `Cluster [ <b>lithium</b> ] node context [<b> ${data.request.node} </b>]`;
        headerEl.innerHTML = "Cluster [ <b>lithium</b> ] node context [<b> " + nodeName  + " </b>]";
    }
	
    // Clear all tables
    const tablesToClear = [
        'clusterStatusNodeTable', 'clusterNodeTable', 'clusterNodeContextTable',
        'clusterSystemTable', 'clusterSystemContextTable', 'clusterNetworkTable',
        'clusterNetworkContextTable', 'clusterStorageTable', 'clusterStorageContextTable',
        'clusterServiceFrameworkTable', 'clusterServiceNetworkTable', 
        'clusterServiceHypervisorTable', 'clusterServiceStorageTable',
        'clusterServiceMonitorTable', 'clusterStatusMasterTable'
    ];

    tablesToClear.forEach(table => {
        $(`#${table} tbody tr`).remove();
    });

    // Set JSON viewer button
    const jsonBtn = document.getElementById('main-cluster-btn-json');
    if(jsonBtn && data.response.meta && data.response.meta.cluster && data.response.meta.cluster.local){
        jsonBtn.onclick = function() { 
            json_show(`Cluster [<b> lithium </b>] node context [<b> ${data.response.meta.cluster.local.name} </b>]`, nodeName, "cluster", data );
        };
    }

	if(data.response.proto.result == "1"){

		// master
		if((typeof data.response.meta.cluster !== 'undefined')){
			var tbodyClusterMaster = $("#clusterStatusMasterTable tbody");
			tbodyClusterMaster.append("<tr><td>" + data.response.meta.cluster.local.id + "</td><td>" + data.response.meta.cluster.local.name + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + "n/a" + "</td><td>" + data.response.meta.cluster.updated + "</td></tr>");
		}
		
		// process nodes
		if((typeof data.response.meta.node !== 'undefined') || (typeof data.response.meta.node.index !== 'undefined')){	
			cluster_object_populate(nodeName, data.response.meta.node, "node", "", "clusterNodeTable", "clusterNodeContextTable", "main-cluster-nodes", "Node");
			
			var nodes = data.response.meta.node.index.split(';');
			document.getElementById("main-cluster-state").innerHTML = 'State [<b style="color:#24be14">ONLINE</b>]' +  " active nodes [<b>" + nodes.length + "</b>] updated [<b>" + data.response.proto.date + "</b>]";
		}

		// process systems
		if((typeof data.response.meta.system !== 'undefined') || (typeof data.response.meta.system.index !== 'undefined')){
			cluster_object_populate(nodeName, data.response.meta.system, "system", "", "clusterSystemTable", "clusterSystemContextTable", "main-cluster-systems", "System");
			
		}
	
		// process networks
		if((typeof data.response.meta.network !== 'undefined') || (typeof data.response.meta.network.index !== 'undefined')){
			cluster_object_populate(nodeName, data.response.meta.network, "network", "", "clusterNetworkTable", "clusterNetworkContextTable", "main-cluster-networks", "Network");
		}

		// process devices
		if((typeof data.response.meta.storage !== 'undefined') || (typeof data.response.meta.storage.index !== 'undefined')){
			cluster_object_populate(nodeName, data.response.meta.storage, "storage", "", "clusterStorageTable", "clusterStorageContextTable", "main-cluster-storage", "Storage");
		}

		
		// Process cluster services - these represent the core service components of the cluster
		if(typeof data.response.meta.service !== 'undefined'){
			var services = "";
			
			// Framework Service - core orchestration and management layer
			if(typeof data.response.meta.service.framework !== 'undefined'){
				cluster_object_populate(nodeName, data.response.meta.service.framework, "service", "framework", "clusterServiceFrameworkTable", "", "main-cluster-service-framework", "Framework");
				services += "Framework";
			}

			// Network Service - handles all network virtualization and connectivity
			if(typeof data.response.meta.service.network !== 'undefined') {
				cluster_object_populate(nodeName, data.response.meta.service.network, "service", "network", "clusterServiceNetworkTable", "", "main-cluster-service-network", "Network");
				services += ";Network";
			}

			// Hypervisor Service - manages virtual machine lifecycle
			if(typeof data.response.meta.service.hypervisor !== 'undefined'){
				cluster_object_populate(nodeName, data.response.meta.service.hypervisor, "service", "hypervisor", "clusterServiceHypervisorTable", "", "main-cluster-service-hypervisor", "Hypervisor");
				services += ";Hypervisor";
			}

			// Storage Service - handles persistent storage and volumes
			if(typeof data.response.meta.service.storage !== 'undefined'){
				cluster_object_populate(nodeName, data.response.meta.service.storage, "service", "storage", "clusterServiceStorageTable", "", "main-cluster-service-storage", "Storage");
				services += ";Storage";
			}

			// Monitor Service - provides health monitoring and metrics
			if(typeof data.response.meta.service.monitor !== 'undefined'){
				cluster_object_populate(nodeName, data.response.meta.service.monitor, "service", "monitor", "clusterServiceMonitorTable", "", "main-cluster-service-monitor", "Monitor");
				log_write_json("cluster_node_meta_process", "[MONITOR]", data.response.meta.service.monitor);
				services += ";Monitor";
			}
			
			document.getElementById("main-cluster-services").innerHTML = "<b>Service</b>" + " objects [<b>" + services + "</b>]";
		}
		
	}
	else{
		log_write_json("cluster_node_meta_process", "[FAILED]", "error: operation failed");
	}
	
}

/**
 * Populates cluster object tables with metadata
 * @param {Object} objMeta - The object metadata
 * @param {string} objMeta.index - Semicolon-delimited list of object names
 * @param {string} objMeta.remote - Semicolon-delimited list of remote objects
 * @param {string} objMeta.local - Semicolon-delimited list of local objects
 * @param {Object} objMeta.meta - Metadata for individual objects
 * @param {string} objType - The object type (node, system, network, etc)
 * @param {string} objSub - The object subtype (framework, network, etc)
 * @param {string} tableObj - ID of the main object table
 * @param {string} tableCtx - ID of the context table (optional)
 * @param {string} header - ID of the header element to update
 * @param {string} headerText - Text to display in the header
 */
function cluster_object_populate(nodeName, objMeta, objType, objSub, tableObj, tableCtx, header, headerText) {
    if(!objMeta || !objType || !tableObj || !header || !headerText){
        console.error('Invalid parameters to cluster_object_populate');
        return;
    }

    // Process object counts
    const objIndex = objMeta.index ? objMeta.index.split(';') : [];
    const objRemote = objMeta.remote ? objMeta.remote.split(';') : [];
    const objLocal = objMeta.local ? objMeta.local.split(';') : [];
    
    const counts = {
        index: objIndex.length,
        remote: objRemote.length,
        local: objLocal.length
    };

    // Update header
    const headerEl = document.getElementById(header);
    if(headerEl){
        headerEl.innerHTML = `<b>${headerText}</b> objects [<b>${counts.index}</b>] - ` + `local [<b>${counts.local}</b>] remote [<b>${counts.remote}</b>]`;
    }

    // Update context table if provided
    if(tableCtx){
        const tbody = $(`#${tableCtx} tbody`);
        if(tbody.length){
            tbody.empty();
            
            const addRow = (label, count, items) => {
                tbody.append(`<tr><td><b>${label}</b></td><td>${count}</td>` + `<td>${cluster_object_index_split(items)}</td></tr>`);
            };

            addRow('INDEX', counts.index, objMeta.index || '');
            addRow('REMOTE', counts.remote, objMeta.remote || '');
            addRow('LOCAL', counts.local, objMeta.local || '');
        }
    }
		
    // Populate main object table
    const tbodyObj = $(`#${tableObj} tbody`);
    if(tbodyObj.length){
        tbodyObj.empty();

        const addObjectRow = (obj, location) => {
            if(!objMeta.meta?.[obj]) return;

            const meta = objMeta.meta[obj];
            const color = location === 'LOCAL' ? '#BF00FF' : '';
            const locationHtml = `<b style="color:${color}">${location}</b>`;
            
            tbodyObj.append(`
                <tr>
                    <td><b>${obj}</b></td>
                    <td><b>${objType}</b></td>
                    <td><b>${objSub}</b></td>
                    <td>${meta.ver || 'n/a'}</td>
                    <td>${meta.date || 'n/a'}</td>
                    <td>${locationHtml}</td>
                    <td>
                        <b style="color:#0040ff">
                            <a id="btn_cdb_obj_${objType}_${objSub}_${obj}" 
                               class="btn btn-link tablebtn">[show]</a>
                        </b>
                    </td>
                </tr>
            `);

            $(`#btn_cdb_obj_${objType}_${objSub}_${obj}`).click(() => {
				//main_view_set('cluster_node_show', nodeName, '');
                cluster_object_show_async(nodeName, obj, objType, objSub);
                //node_cluster_rest_obj_get(obj, objType, objSub);
            });
        };

        // Add local objects
        objLocal.forEach(obj => addObjectRow(obj, 'LOCAL'));
        
        // Add remote objects
        objRemote.forEach(obj => addObjectRow(obj, 'REMOTE'));
    }
}

/**
 * Splits a semicolon-delimited index string into a space-separated string
 * @param {string} index - The semicolon-delimited string to split
 * @returns {string} Space-separated version of the input string
 */
function cluster_object_index_split(index){
    if(!index || typeof index !== 'string'){
        return "";
    }
    return index.split(';').join(' ');
}

/**
 * Asynchronously shows cluster object details by making an API request
 * @param {string} obj - The object name/identifier
 * @param {string} objType - The object type (system, node, network, storage, service)
 * @param {string} objSub - The object subtype (only used for service type)
 */
function cluster_object_show_async(nodeName, obj, objType, objSub){
    
    main_view_set('cluster_object_show', nodeName, '');
    
    // Special handling for service type which uses objSub
    if(objType === 'service'){
        api_get_request_callback_new('api_new', '/service/cluster/service/get?name=' + nodeName + "&obj_type=" + objType + "&srv_name=" + objSub + "&srv_node=" + obj, 'cluster_obj_show_async');
    } 
    else{
        api_get_request_callback_new('api_new', '/service/cluster/object/get?name=' + nodeName + "&obj_type=" + objType + "&obj_name=" + obj, 'cluster_obj_show_async');
    }

}

/**
 * Displays cluster object data in JSON viewer
 * @param {Object} data - Cluster object data to display
 * @param {Object} data.request - Request metadata
 * @param {string} data.request.id - Object identifier
 * @param {string} data.request.obj - Object type
 * @param {string} data.request.node - Node context
 * @throws {Error} If data is invalid or display fails
 */
function cluster_object_show(data){
    if(!data || !data.request){
        throw new Error('Invalid cluster object data');
    }

    try {
        log_write_json("cluster_object_show", "[RECEIVED_DATA]", data);
        
		// handle new node header
		var nodeName = monitorHost;
		if(data.response.proto.node){
			nodeName = data.response.proto.node;
		}
        
        main_view_set('cluster_node_show', nodeName, '');
        
        json_show(`Cluster object from node [ <b>${nodeName}</b> ]`, nodeName, "cluster", data);
        
             
    } catch (error) {
        console.error('Failed to show cluster object:', error);
        throw error;
    }
}

/**
 * Shows the main cluster health view by finding available monitors and showing the default monitor host
 * @throws {Error} If no monitor host is defined or health data cannot be retrieved
 */
function cluster_health_show(){
    if(!monitorHost || typeof monitorHost !== 'string'){
        throw new Error('No valid monitor host defined');
    }

    try {
        cluster_health_find();
        cluster_health_node_show(monitorHost);
    } catch (error) {
        console.error('Failed to show cluster health:', error);
        throw error;
    }
}

/**
 * Shows the health monitor view for a specific node
 * @param {string} nodeName - Name of the node to show health data for
 * @throws {Error} If node name is invalid or health data cannot be processed
 */
function cluster_health_node_show(nodeName) {
    if(!nodeName || typeof nodeName !== 'string'){
        throw new Error('Invalid node name parameter');
    }

    try {
        main_cluster_health_show();
        main_view_set('cluster_health_show', nodeName, '');
        cluster_health_node_process(nodeName);
    } catch (error) {
        console.error(`Failed to show health for node ${nodeName}:`, error);
        throw error;
    }
}

/**
 * Finds and processes nodes with health monitor data, updates the monitor menu
 * @throws {Error} If node data cannot be retrieved or processed
 */
function cluster_health_find(){
	var monitorNum = 0;
	var masterNode = "";
	
	var nodeList = dbnew_node_index_online_get();
	
	cluster_monitor_menu_remove_nodes();
	
	nodeList.forEach((nodeName) => {

		var nodeData = dbnew_node_get(nodeName);
		
		if(nodeData.meta.state == "1"){

			// need to fetch the services here
			nodeServiceData = dbnew_service_node_get("monitor", nodeName);

			if(nodeServiceData){
				if(api_master_get() == nodeName){
					cluster_health_node_process(nodeName);
					monitorHost = nodeName;
					//console.log(nodeName);
				}
				
				node_menu_add_clusternode_monitor(nodeName);
				monitorNum++;
				document.getElementById('menu-cluster-monitor').innerHTML = "Monitors (" + monitorNum + ")";
				
			}

		}
	});
	
}

/**
 * Processes and displays health data for a specific node
 * @param {string} nodeName - Name of the node to process health data for
 * @throws {Error} If node name is invalid or health data cannot be processed
 */
//function cluster_health_node_process(nodeData, nodeServiceData, nodeName){
function cluster_health_node_process(nodeName){
	var nodeData = dbnew_node_get(nodeName);
	var nodeServiceData = dbnew_service_node_get("monitor", nodeName);
	
	document.getElementById("main-health-node").innerHTML = "Nodes [<b>n/a</b>]";
	document.getElementById("main-health-system").innerHTML = "Systems [<b>n/a</b>]";
	document.getElementById("main-cluster-health-alarm").innerHTML = "Alarms [<b>n/a</b>]";
	
	$("#healthStatusSystemTable tbody tr").remove();
	$("#healthStatusNodeTable tbody tr").remove();
	$("#healthStatusStorageTable tbody tr").remove();
	$("#healthStatusNetworkTable tbody tr").remove();
	$("#healthStatusOverviewTable tbody tr").remove();	
	$("#healthAlarmActiveOverviewTable tbody tr").remove();	
	$("#healthAlarmInactiveOverviewTable tbody tr").remove();	
	$("#healthStatusServiceTable tbody tr").remove();	
	
	document.getElementById("main-cluster-health-btn-json").onclick = function() { json_show("[ Cluster Health ] monitor [<b> " + nodeData.id.name + " </b>]", "monitor", "cluster_health", nodeServiceData) };
	
	document.getElementById("main-health-header").innerHTML = "[ Cluster Health ] monitor [<b> " + nodeData.id.name + " </b>]";
		
	//
	// systems
	//
	var sysHealthy = "";
	var sysWarning = "";
	var sysHealthRate = 100;
	var sysTotal = 0;

	if(nodeServiceData.data.systems.index.healthy !== ""){
		sysHealthy = nodeServiceData.data.systems.index.healthy.split(';');
	}
	
	if(nodeServiceData.data.systems.index.warning !== ""){
		sysWarning = nodeServiceData.data.systems.index.warning.split(';');
	}
	
	cluster_object_table_build("healthStatusSystemTable", nodeServiceData.data.systems.meta, sysHealthy, sysWarning);
	
	sysTotal = sysHealthy.length + sysWarning.length;
	var sysTotal = sysHealthy.length + sysWarning.length;
	sysHealthRate = (parseInt(sysHealthy.length) / parseInt(sysTotal)) * 100;
	
	document.getElementById("main-health-system").innerHTML = "<b>Systems</b> Total [<b>" + sysTotal +  "</b>] - Healthy [<b>"+ sysHealthy.length + "</b>] Warnings [<b>" + sysWarning.length + "</b>] - Score [<b>" + sysHealthRate.toFixed(1) +"</b>]";
	document.getElementById("main-cluster-system-health-state").innerHTML = "System health [<b>" + sysHealthRate.toFixed(1) + "</b>]";	

	//
	// nodes
	//
	var nodeHealthy = "";
	var nodeWarning = "";

	if(nodeServiceData.data.nodes.index.healthy !== ""){
		nodeHealthy = nodeServiceData.data.nodes.index.healthy.split(';');
	}

	if(nodeServiceData.data.nodes.index.warning !== ""){
		nodeWarning = nodeServiceData.data.nodes.index.warning.split(';');
	}		
	
	var nodeTotal = nodeHealthy.length + nodeWarning.length;
	var nodeHealthRate = (parseInt(nodeHealthy.length) / parseInt(nodeTotal)) * 100;
	
	document.getElementById("main-health-node").innerHTML = "<b>Nodes</b> Total [<b>" + nodeTotal +  "</b>] - Healthy [<b>"+ nodeHealthy.length + "</b>] Warnings [<b>" + nodeWarning.length + "</b>] - Score [<b>" + nodeHealthRate.toFixed(1) +"</b>]";
	document.getElementById("main-cluster-node-health-state").innerHTML = "Node health [<b>" + nodeHealthRate.toFixed(1) + "</b>]";
	
	cluster_object_table_build("healthStatusNodeTable", nodeServiceData.data.nodes.meta, nodeHealthy, nodeWarning);		
	
	//
	// storage
	//
	var storHealthy = "";
	var storWarning = "";

	if(nodeServiceData.data.storage.index.healthy !== ""){
		storHealthy = nodeServiceData.data.storage.index.healthy.split(';');
	}

	if(nodeServiceData.data.storage.index.warning !== ""){
		storWarning = nodeServiceData.data.storage.index.warning.split(';');
	}		
	
	var storTotal = storHealthy.length + storWarning.length;
	var storHealthRate = (parseInt(storHealthy.length) / parseInt(storTotal)) * 100;
	
	document.getElementById("main-health-storage").innerHTML = "<b>Storage</b> Total [<b>" + storTotal +  "</b>] - Healthy [<b>"+ storHealthy.length + "</b>] Warnings [<b>" + storWarning.length + "</b>] - Score [<b>" + storHealthRate.toFixed(1) +"</b>]";
	document.getElementById("main-cluster-storage-health-state").innerHTML = "Storage health [<b>" + storHealthRate.toFixed(1) + "</b>]";

	cluster_object_table_build("healthStatusStorageTable", nodeServiceData.data.storage.meta, storHealthy, storWarning);		
	
	//
	// network
	//
	var netHealthy = 0;
	var netWarning = 0;
	var netTotal = 0;
	var netHealthRate = 100;
	
	var netIdx = nodeServiceData.data.networks.index;
	var netIndex = netIdx.split(';');
	
	netIndex.forEach((network) => {
		var netData = nodeServiceData.data.networks[network];
		var status;
		var state;

		// state
		if(netData.state == "ACTIVE"){
			state = view_color_healthy(netData.state);
		}
		else if(netData.state == "INACTIVE"){
			state = '<b>' + "INACTIVE</b>";
		}
		else if(netData.state == "ONLINE"){
			state = view_color_healthy(netData.state);
		}
		else{
			state = view_color_warning(netData.state);
		}
	
		// status
		if(netData.status == "HEALTHY"){
			status = view_color_healthy(netData.status);
			netHealthy++;
		}
		else{
			status = view_color_warning(netData.status);
			netWarning++;
		}
		
		$("#healthStatusNetworkTable tbody").append("<tr><td><b>" + network + "</b></td><td><b>" + netData.node.index + "</b></td><td><b>" + netData.vm.index + "</b></td><td><b>" + netData.errors + "</b></td><td><b>" + nodeServiceData.data.networks.updated + "</b></td><td><b>" + state + "</b></td><td><b>" + status + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");
		
		const netName = network;
		document.getElementById("tempbtn").id = "btn_cdb_obj_" + netName;
		document.getElementById("btn_cdb_obj_" + netName).onclick = function() { json_show("[ " + netName + " ]", "monitor", "cluster_health", netData) }; 
	});
	
	netTotal = netIndex.length;
	var netStatus = nodeServiceData.data.networks.status;
	netHealthRate = (parseInt(netHealthy) / parseInt(netTotal)) * 100;
	
	document.getElementById("main-health-network").innerHTML = "<b>Networks</b> Total [<b>" + netTotal +  "</b>] - Healthy [<b>"+ netHealthy + "</b>] - Warnings [<b>" + netWarning + "</b>] - Score [<b>" + netHealthRate.toFixed(1) +"</b>]";
	
	//
	// services
	//
	var serviceHealthy = 0;
	var serviceWarning = 0;
	var serviceTotal = 0;
	var serviceNodeTotal = 0;
	var serviceHealthRate = 100;


	// healthy nodes
	if(nodeServiceData.data.nodes.index.healthy !== ""){
		nodeHealthyIndex = nodeServiceData.data.nodes.index.healthy.split(';');
		
		// process healthy nodes
		nodeHealthyIndex.forEach((srvnodename) => {
			 serviceNodeTotal++;

			// framework
			if((typeof nodeServiceData.data.service.framework !== 'undefined') && (typeof nodeServiceData.data.service.framework[srvnodename] !== 'undefined')){
				var serviceMeta = nodeServiceData.data.service.framework[srvnodename];

				if(serviceMeta.state == "ACTIVE" && serviceMeta.status == "HEALTHY"){
					serviceHealthy++;
					serviceTotal++;
				}
				else{
					serviceWarning++;
					serviceTotal++;
				}
				
				$("#healthStatusServiceTable tbody").append("<tr><td><b>" + srvnodename + "</b></td><td><b>" + "framework" + "</b></td><td><b>" + serviceMeta.updated + "</b></td><td><b>" + serviceMeta.delta + "</b></td><td><b>" + view_health_color_status(serviceMeta.state) + "</b></td><td><b>" + view_health_color_status(serviceMeta.status) + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");	
			}
			
			// hypervisor
			if((typeof nodeServiceData.data.service.hypervisor !== 'undefined') && (typeof nodeServiceData.data.service.hypervisor[srvnodename] !== 'undefined')){
				var serviceMeta = nodeServiceData.data.service.hypervisor[srvnodename];
				
				if(serviceMeta.state == "ACTIVE" && serviceMeta.status == "HEALTHY"){
					serviceHealthy++;
					serviceTotal++;
				}
				else{
					serviceWarning++;
					serviceTotal++;
				}
				
				$("#healthStatusServiceTable tbody").append("<tr><td><b>" + srvnodename + "</b></td><td><b>" + "hypervisor" + "</b></td><td><b>" + serviceMeta.updated + "</b></td><td><b>" + serviceMeta.delta + "</b></td><td><b>" + view_health_color_status(serviceMeta.state) + "</b></td><td><b>" + view_health_color_status(serviceMeta.status) + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");
			}

			// network
			if((typeof nodeServiceData.data.service !== 'undefined') && (typeof nodeServiceData.data.service.network !== 'undefined') && (typeof nodeServiceData.data.service.network[srvnodename] !== 'undefined')){
				var serviceMeta = nodeServiceData.data.service.network[srvnodename];
				
				if(serviceMeta.state == "ACTIVE" && serviceMeta.status == "HEALTHY"){
					serviceHealthy++;
					serviceTotal++;
				}
				else{
					serviceWarning++;
					serviceTotal++;
				}
				
				$("#healthStatusServiceTable tbody").append("<tr><td><b>" + srvnodename + "</b></td><td><b>" + "network" + "</b></td><td><b>" + serviceMeta.updated + "</b></td><td><b>" + serviceMeta.delta + "</b></td><td><b>" + view_health_color_status(serviceMeta.state) + "</b></td><td><b>" + view_health_color_status(serviceMeta.status) + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");
			}

		});
			
		
		var serviceHealthRate = (parseInt(serviceHealthy) / parseInt(serviceTotal)) * 100;

		document.getElementById("main-health-service").innerHTML = "<b>Services</b> Total [<b>" + serviceTotal + "</b>] - Nodes [<b>" + serviceNodeTotal + "</b>] - Healthy [<b>" + serviceHealthy + "</b>] Warnings [<b>" + serviceWarning + "</b>] - Score [<b>" + serviceHealthRate.toFixed(1) + "</b>]";

	}

	//
	// alarms
	//
	var alarmTotal = 0;
	
	if((typeof nodeServiceData.data.alarm !== 'undefined') && (nodeServiceData.data.alarm !== null)){
		var alarms = 0;
		var alarmHeader = "";
		
		if((typeof nodeServiceData.data.alarm.index !== 'undefined') && nodeServiceData.data.alarm.index !== ""){
		
			var alarmObjIndex = nodeServiceData.data.alarm.index.split(';');
			
			// process objects
			alarmObjIndex.forEach((alarmObj) => {
				
				// object index
				var alarmObjElmIndex = nodeServiceData.data.alarm[alarmObj].index.split(';');

				// process elements of object
				alarmObjElmIndex.forEach((alarmObjElm) => {
					var alarmObjElmAlarmIdx = nodeServiceData.data.alarm[alarmObj][alarmObjElm].index;
					
					var alarmObjElmAlarmIndex = alarmObjElmAlarmIdx.toString().split(';');
					
					alarmObjElmAlarmIndex.forEach((alarmObjElmAlarmNum) => {

						
						if((typeof nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].cleared !== 'undefined')){
							//console.log("OBJECT [" + alarmObj + "] ELM [" + alarmObjElm + "] ID [" + alarmObjElmAlarmNum + "] cleared [" + node.config.service.data.monitor.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].cleared + "]");
						}

						if((nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].alarm == 1)){
							// alarm active
							console.log("ALARM: OBJECT [" + alarmObj + "] ELM [" + alarmObjElm + "] ID [" + alarmObjElmAlarmNum + "] IS ACTIVE");
							$("#healthAlarmActiveOverviewTable tbody").append("<tr><td><b>" + alarmObj + "</b></td><td>" + alarmObjElm + "</td><td>" + alarmObjElmAlarmNum + "</td><td><b>" + 
							nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].alarm + "</td><td>" 
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].date + "</td><td>"
							+ view_color_error(nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].state) + "</td><td>"
							+ view_color_error(nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].status) + "</td><td>"
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].events + "</td><td>"
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].timer + "</td><td>"
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].triggered + "<td></tr>");
							
							alarms++;
							alarmHeader = alarmHeader + " - object [<b>" + alarmObj + "</b>] name [<b>" + alarmObjElm + "</b>] state [<b>" + view_color_error(nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].state) + "</b>] status [<b>" + view_color_error(nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].status) + "</b>] timer [<b>" + nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].timer + " sec</b>]";
							alarmTotal++;
							
						}
						else{
							// alarm cleared
							
							//console.log("OBJECT [" + alarmObj + "] ELM [" + alarmObjElm + "] ID [" + alarmObjElmAlarmNum + "] IS NOT ACTIVE");
							$("#healthAlarmInactiveOverviewTable tbody").append("<tr><td><b>" + alarmObj + "</b></td><td>" + alarmObjElm + "</td><td>" + alarmObjElmAlarmNum + "</td><td><b>" + 
							nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].alarm + "</td><td>" 
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].date + "</td><td>"
							+ view_color_warning(nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].state) + "</td><td>"
							+ view_color_warning(nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].status) + "</td><td>"
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].events + "</td><td>"
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].timer + "</td><td>"
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].triggered + "</td><td>"
							+ nodeServiceData.data.alarm[alarmObj][alarmObjElm][alarmObjElmAlarmNum].cleared + "<td></tr>");
						}
						
					});
			
				});

			});
		
		}
		
		if(alarms > 0){
			var alarmStr = view_color_error(alarms.toString());
			document.getElementById("main-cluster-health-alarm").innerHTML = "Alarms [" + alarmStr + "]" + alarmHeader;
		}
		else{
			var alarmStr = view_color_healthy("No active alarms");
			document.getElementById("main-cluster-health-alarm").innerHTML = "Alarms [" + alarmStr + "]" + alarmHeader;
		}
	}
	else{
		document.getElementById("main-cluster-health-alarm").innerHTML = "Alarms [" + view_color_healthy("No alarms") + "]";
	}
	
	//
	// overview
	//
	
	// calculate cluster health score
	var objTotal = sysTotal + nodeTotal + storTotal + netTotal + serviceTotal;
	var objWarnings = 0;
	
	if(sysWarning != ""){
		objWarnings += sysWarning.length;
	}
	
	if(nodeWarning != ""){
		objWarnings += nodeWarning.length;
	}

	if(storWarning != ""){
			objWarnings += storWarning.length;
	}

	if(netWarning != ""){
			objWarnings += netWarning;
	}
	
	//service
	objWarnings += serviceWarning;
	
	// overview
	$("#healthStatusOverviewTable tbody").append("<tr><td><b>" + "node" + "</b></td><td>" + nodeTotal + "</td><td>" + nodeHealthy.length + "</td><td>" + nodeWarning.length + "</td><td>" + "0" + "</td><td>" + "100" + "</td><td><b>" + nodeHealthRate.toFixed(1) + "</b></td></tr>");
	$("#healthStatusOverviewTable tbody").append("<tr><td><b>" + "system" + "</b></td><td>" + sysTotal + "</td><td>" + sysHealthy.length + "</td><td>" + sysWarning.length + "</td><td>" + "0" + "</td><td>" + "100" + "</td><td><b>" + sysHealthRate.toFixed(1) + "</b></td></tr>");
	$("#healthStatusOverviewTable tbody").append("<tr><td><b>" + "storage" + "</b></td><td>" + storTotal + "</td><td>" + storHealthy.length + "</td><td>" + storWarning.length + "</td><td>" + "0" + "</td><td>" + "100" + "</td><td><b>" + storHealthRate.toFixed(1) + "</b></td></tr>");
	$("#healthStatusOverviewTable tbody").append("<tr><td><b>" + "network" + "</b></td><td>" + netTotal + "</td><td>" + netHealthy + "</td><td>" + netWarning + "</td><td>" + "0" + "</td><td>" + "100" + "</td><td><b>" + netHealthRate.toFixed(1) + "</b></td></tr>");
	$("#healthStatusOverviewTable tbody").append("<tr><td><b>" + "services" + "</b></td><td>" + serviceTotal + "</td><td>" + serviceHealthy + "</td><td>" + serviceWarning + "</td><td>" + "0" + "</td><td>" + "100" + "</td><td><b>" + netHealthRate.toFixed(1) + "</b></td></tr>");
	
	var objHealthRate = (parseInt(nodeHealthRate) + parseInt(sysHealthRate) + parseInt(storHealthRate) + parseInt(netHealthRate) + parseInt(serviceHealthRate)) / 5;

	var health = "";
	
	// warnings (health score)
	if(objHealthRate > 90){
		health = view_color_healthy("HEALTHY");
	}
	else if(objHealthRate > 70){
		health = view_color_warning("WARN");
	}
	else{
		health = view_color_warning("ERROR");
	}

	// alarms
	if(alarmTotal > 0){
		health = view_color_error("ALARM");
	}

	var diff = date_str_diff_now(nodeServiceData.updated);
	document.getElementById("main-card-health").innerHTML = "Status [" + health + "] Score [<b>" + objHealthRate.toFixed(1) + "</b>]</br>Monitors [<b>" + objTotal + "</b>] -  Alarms [<b>" + alarmTotal + "</b>] Warn [<b>" + objWarnings + "</b>]";
	document.getElementById("main-cluster-health-state").innerHTML = "Status [" + health + "] updated [<b>" + nodeServiceData.data.meta.updated + "</b>] delta [<b>" + diff + "</b>] - Cluster health Score [<b>" + objHealthRate.toFixed(1) + "</b>]";
	
}

/**
 * Builds a table displaying cluster object health status
 * @param {string} table - ID of the table element to populate
 * @param {Object} meta - Metadata containing object health information
 * @param {Array} objHealthy - Array of healthy object names
 * @param {Array} objWarning - Array of warning object names
 * @throws {Error} If parameters are invalid or table cannot be populated
 */
function cluster_object_table_build(table, meta, objHealthy, objWarning) {
	
	if(objWarning !== ""){
		objWarning.forEach((warnObj) => {
			var objdata = meta[warnObj];
			var objState = view_health_color_status(objdata.state);
			
			var objStatus = "N/A";
			if((typeof objdata.status !== 'undefined')){
				objStatus = view_health_color_status(objdata.status);
			}

			$("#" + table + " tbody").append("<tr><td><b>" + warnObj + "</b></td><td>" + objdata.ver + "</td><td>" + objdata.updated + "</td><td><b>" + string_undefined(objdata.delta) + "</b></td><td>" + objState + "</td><td>" + '<b style="color:#FF0000">' + objStatus + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");
			
			const oName = warnObj;
			const oData = objdata;				
			document.getElementById("tempbtn").id = table + "_" + oName;
			document.getElementById(table + "_" + oName).onclick = function() { json_show("[ " + oName + " ]", "monitor", "cluster_health", oData) }; 
		});	
	}
	
	if(objHealthy !== ""){
		objHealthy.forEach((healthyObj) => {
			var objdata = meta[healthyObj];
			var objState = view_health_color_status(objdata.state);
			var objStatus = view_health_color_status(objdata.status);
			
			$("#" + table + " tbody").append("<tr><td><b>" + healthyObj + "</b></td><td>" + objdata.ver + "</td><td>" + objdata.updated + "</td><td><b>" + string_undefined(objdata.delta) + "</b></td><td>" + objState + "</td><td>" + '<b style="color:#24be14">' + objStatus + "</b></td><td>" + '<b style="color:#0040ff"><a id="tempbtn" class="btn btn-link tablebtn">' + "[show]</a></b></td></tr>");
			
			const oName = healthyObj;
			const oData = objdata;				
			document.getElementById("tempbtn").id = table + "_" + oName;
			document.getElementById(table + "_" + oName).onclick = function() { json_show("[ " + oName + " ]", "monitor", "cluster_health", oData) }; 
			
		});
	}	
	
}

/**
 * Shows the main monitor health overview view
 */
function cluster_health_ov_show() {
	main_health_overview_show();
	
}
