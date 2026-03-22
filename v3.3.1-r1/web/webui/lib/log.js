/**
 * ETHER|AAPEN|WEB - LIB|LOG
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/

var logevents = 0;

//
//
//
function log_show(){
	main_hide_all();
	main_log_show();
}

function log_hide(){
	main_log_hide();
}

//
// write to log
//
function log_write_json(id, fid, json){
	var pretty = JSON.stringify(json, null, 2);
	var tbody = $("#logTable tbody");
	tbody.append("<tr><td><b>" + id + "</b></td><td><b>" + fid + "</b></td><td>" + '<pre id="json">' + pretty + '</pre>' + "</td></tr>");
	
	logevents++;
	document.getElementById("main-card-log").innerHTML = "Show framework log events<br/>Events logged [<b>" + logevents + "</b>]";
}
