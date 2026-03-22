/**
 * ETHER|AAPEN|WEB - LIB|SYSTEM|HELPERS
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/


/**
 * Shows shutdown confirmation modal
 * @param {string} systemName - Name of the system
 * @description Displays confirmation dialog for system shutdown
 */
function node_service_start_accept(nodeName, serviceName){
	
	document.getElementById("mainModalLabel").innerHTML = "Service Start";
	document.getElementById("mainModalBody").innerHTML = "Are you sure you want to start service [<b> " + serviceName + " </b>] on node [<b>" + nodeName + "</b>]?";
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-boxes"); 
	document.getElementById("mainModalBtnAccept").innerHTML = "Start";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		//system_hyper_shutdown(systemName);
		//system_rest_shutdown(systemName);
		node_service_start(nodeName, serviceName);
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows shutdown confirmation modal
 * @param {string} systemName - Name of the system
 * @description Displays confirmation dialog for system shutdown
 */
function node_service_stop_accept(nodeName, serviceName){
	
	document.getElementById("mainModalLabel").innerHTML = "Service Start";
	document.getElementById("mainModalBody").innerHTML = "Are you sure you want to stop service [<b> " + serviceName + " </b>] on node [<b>" + nodeName + "</b>]?";
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-boxes"); 
	document.getElementById("mainModalBtnAccept").innerHTML = "Stop";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		//system_hyper_shutdown(systemName);
		//system_rest_shutdown(systemName);
		node_service_stop(nodeName, serviceName);
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}

/**
 * Shows shutdown confirmation modal
 * @param {string} systemName - Name of the system
 * @description Displays confirmation dialog for system shutdown
 */
function node_service_restart_accept(nodeName, serviceName){
	
	document.getElementById("mainModalLabel").innerHTML = "Service Restart";
	document.getElementById("mainModalBody").innerHTML = "Are you sure you want to restart service [<b> " + serviceName + " </b>] on node [<b>" + nodeName + "</b>]?";
	document.getElementById("mainModalIcon").setAttribute("class", "system-load-btn bi bi-boxes"); 
	document.getElementById("mainModalBtnAccept").innerHTML = "Restart";
	document.getElementById("mainModalBtnAccept").onclick = function() { 
		//system_hyper_shutdown(systemName);
		//system_rest_shutdown(systemName);
		//node_service_stop
		$('#mainModal').modal('hide');
	};
	
	$('#mainModal').modal('show');
	
}
