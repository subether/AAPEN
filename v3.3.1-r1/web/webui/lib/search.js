/**
 * ETHER|AAPEN|WEB - LIB|NODE
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

let nodeSearched = 0;
let systemSearched = 0;
let networkSearched = 0;
let matches = 0;

/**
 * Show search results for a query
 * @param {string} query - Search query string
 */
function search_show(query) {
	if(query === "") return;

	main_search_show();
	document.getElementById("main-search-header").innerHTML = `[ Search ] query [<b>${query}</b>]`;
	
	// Reset counters
	nodeSearched = 0;
	systemSearched = 0;
	networkSearched = 0;
	
	// Clear existing results
	$("#searchNodeTable tbody tr").remove();
	$("#searchSystemTable tbody tr").remove();
	$("#searchNetworkTable tbody tr").remove();
	
	// Process searches
	search_node_process();
	search_system_process();
	search_network_process();
}

/**
 * Search through nodes
 */
function search_node_process() {
	const nodeList = dbnew_node_index_get();
	matches = 0;
	
	nodeList.forEach((nodeName) => {
		const nodeData = dbnew_node_get(nodeName);
		const query = document.getElementById("main-search-bar").value.toLowerCase();
		
		const show = () => node_show(value);
		searchObject("searchNodeTable", nodeData, nodeData, query, show);
		
		nodeSearched++;
		document.getElementById("main-search-node-header").innerHTML = 
			`Nodes - processed [${nodeSearched}] - string matches [${matches}]`;
	});
}

/**
 * Search through systems
 */
 function search_system_process() {
	sysList = dbnew_system_index_get();
	matches = 0;

	sysList.forEach((sysName) => {
		var systemData = dbnew_system_get(sysName);
		const query = document.getElementById("main-search-bar").value.toLowerCase();
		const show = () => system_show(value);
		searchObject("searchSystemTable", systemData, systemData, query, show);
		
		systemSearched++;
		document.getElementById("main-search-system-header").innerHTML = 
			`Systems - processed [${systemSearched}] - string matches [${matches}]`;
	});
}

/**
 * Search through networks
 */
function search_network_process() {
	const netList = dbnew_network_index_get();
	matches = 0;

	netList.forEach((netName) => {
		const netData = dbnew_network_get(netName);
		const query = document.getElementById("main-search-bar").value.toLowerCase();
		const show = () => net_show(value);
		searchObject("searchNetworkTable", netData, netData, query, show);
		
		networkSearched++;
		document.getElementById("main-search-network-header").innerHTML = 
			`Networks - processed [${networkSearched}] - string matches [${matches}]`;
	});
}

/**
 * Recursively search through an object for matches
 * @param {string} table - Table ID to append results to
 * @param {Object} object - Object to search through
 * @param {Object} data - Data object containing the actual values
 * @param {string} query - Search query
 * @param {Function} call - Callback function when match is found
 */
function searchObject(table, object, data, query, call) {
	for (const key in data) {
		if(!data.hasOwnProperty(key)) continue;
		
		const value = data[key];
		
		if(value !== null && typeof value === 'object'){
			searchObject(table, object, value, query, call);
			continue;
		}

		const displayValue = value || "Empty";
		
		if(object.id && object.id.id && object.id.name && String(displayValue).toLowerCase().includes(query)){
			
			log_write_json("keydata contains query", query, displayValue);
			
			const row = `
				<tr>
					<td>${object.id.id}</td>
					<td>${object.id.name}</td>
					<td><b>${key}</b></td>
					<td><b style="color:#BF00FF">${displayValue}</b></td>
					<td>
						<b style="color:#0040ff">
							<a id="tempbtn_search_obj" class="btn btn-link tablebtn">[ show ]</a>
						</b>
					</td>
				</tr>
			`;
			
			$("#" + table + " tbody").append(row);
			
			const btnId = `btn_srch_obj_${object.id.name}_${object.id.id}_${key}`;
			document.getElementById("tempbtn_search_obj").id = btnId;
			document.getElementById(btnId).onclick = call;
			
			matches++;
		}
	}
}

/**
 * Alternative search implementation (memory efficient)
 * @param {Object} object - Object to search through
 * @param {string} query - Search query
 * @returns {boolean} True if match found
 */
function newSearch(object, query) {
	for (const key in object) {
		if(!object.hasOwnProperty(key)) continue;
		
		const value = object[key];
		
		if(value !== null && typeof value === 'object'){
			if(newSearch(value, query)){
				return true;
			}
		} 
		else if(String(value).toLowerCase().includes(query.toLowerCase())){
			return true;
		}
	}
	
	return false;
}
