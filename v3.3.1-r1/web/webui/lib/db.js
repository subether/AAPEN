/**
 * ETHER|AAPEN|WEB - LIB|DB
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: aapen@ether.no
 * Version: 3.3.1
 **/


var dbnew = {};
var index = {};

// node
index.node = [];
index.node_online = [];
index.node_offline = [];

// system
index.system = [];
index.system_groups = [];
index.system_online = [];
index.system_offline = [];

// network
index.network = [];
index.network_tuntap = [];
index.network_vpp = [];

// storage
index.storage_device = [];
index.storage_pool = [];
index.storage_iso = [];

// element
index.element_device = [];
index.element_service = [];
index.element_device_group = [];
index.element_service_group = [];

//
// NEW DB
//

// set database
function dbnew_set(dbData){
	dbnew = dbData;
}

// get database
function dbnew_get(){
	//if((dbnew && dbnew !== "") && typeof db == 'object'){
	if(dbnew){	
		return dbnew;	
	}
	else{
		return false;
	}
}

//
// NODE
//

function dbnew_node_get(nodeName){
	if(dbnew.db.node.db[nodeName] && dbnew.db.node.db[nodeName] !== ""){
		return dbnew.db.node.db[nodeName];
	}
	else{
		return false;
	}
}

function dbnew_service_node_get(serviceName, nodeName){
	if((dbnew.db.service[serviceName] && dbnew.db.service[serviceName] !== "") && 
	   (dbnew.db.service[serviceName].db[nodeName] && dbnew.db.service[serviceName].db[nodeName] !== "")){
		return dbnew.db.service[serviceName].db[nodeName];
	}
	else{
		return false;
	}
}

function dbnew_node_index_add(nodeName){
	if(!index.node.includes(nodeName)){
		index.node.push(nodeName);
	}
}
function dbnew_node_index_get() {
	return index.node;
}

function dbnew_node_index_online_add(nodeName){
	if(!index.node_online.includes(nodeName)){
		index.node_online.push(nodeName);
	}
}
function dbnew_node_index_online_get() {
	return index.node_online;
}

function dbnew_node_index_offline_add(nodeName){
	if(!index.node_offline.includes(nodeName)){
		index.node_offline.push(nodeName);
	}
}
function dbnew_node_index_offline_get(){
	return index.node_offline;
}

function dbnew_node_id_to_name(nodeId){
	let nodeName = "";
	let nodeList = dbnew_node_index_get();
	
	nodeList.forEach((node) => {
		if(dbnew.db.node.db[node].id.id === nodeId){
			nodeName = dbnew.db.node.db[node].id.name;
		}
	});

	return nodeName;
}

//
// SYSTEM
//
function dbnew_system_get(systemName){
	if(dbnew.db.system.db[systemName] && dbnew.db.system.db[systemName] !== ""){
		return dbnew.db.system.db[systemName];
	}
	else{
		return false;
	}
}

function dbnew_system_set(systemName, systemData){
	dbnew.db.system.db[systemName] = systemData;
	dbnew_system_index_add(systemName);
	dbnew_system_offline_index_add(systemName);
}

function dbnew_system_group_add(groupName){
	if(!index.system_groups.includes(groupName)){
		index.system_groups.push(groupName);
	}
}
function dbnew_system_group_get() {
	return index.system_groups;
}

function dbnew_system_index_add(systemName){
	if(!index.system.includes(systemName)){
		index.system.push(systemName);
	}
}
function dbnew_system_index_get() {
	return index.system;
}

function dbnew_system_online_index_add(systemName){
	if(!index.system_online.includes(systemName)){
		index.system_online.push(systemName);
	}
}
function dbnew_system_online_index_get() {
	return index.system_online;
}

function dbnew_system_offline_index_add(systemName){
	if(!index.system_offline.includes(systemName)){
		index.system_offline.push(systemName);
	}
}
function dbnew_system_offline_index_get(){
	return index.system_offline;
}

//
// NETWORK
//
function dbnew_network_get(netName){
	if(dbnew.db.network.db[netName] && dbnew.db.network.db[netName] !== ""){
		return dbnew.db.network.db[netName];
	}
	else{
		return false;
	}
}

function dbnew_network_index_add(netName){
	if(!index.network.includes(netName)){
		index.network.push(netName);
	}
}
function dbnew_network_index_get(){
	return index.network;
}

function dbnew_network_tuntap_index_add(netName){
	if(!index.network_tuntap.includes(netName)){
		index.network_tuntap.push(netName);
	}
}
function dbnew_network_tuntap_index_get() {
	return index.network_tuntap;
}

function dbnew_network_vpp_index_add(netName){
	if(!index.network_vpp.includes(netName)){
		index.network_vpp.push(netName);
	}
}
function dbnew_network_vpp_index_get() {
	return index.network_vpp;
}

//
// STORAGE
//
function dbnew_storage_get(objName){
	if(dbnew.db.storage.db[objName] && dbnew.db.storage.db[objName] !== ""){
		return dbnew.db.storage.db[objName];
	}
	else{
		return false;
	}
}

function dbnew_storage_index_device_add(devName){
	if(!index.storage_device.includes(devName)){
		index.storage_device.push(devName);
	}
}
function dbnew_storage_index_device_get(){
	return index.storage_device;
}

function dbnew_storage_index_pool_add(poolName){
	if(!index.storage_pool.includes(poolName)){
		index.storage_pool.push(poolName);
	}
}
function dbnew_storage_index_pool_get() {
	return index.storage_pool;
}

function dbnew_storage_index_iso_add(isoName){
	if(!index.storage_iso.includes(isoName)){
		index.storage_iso.push(isoName);
	}
}
function dbnew_storage_index_iso_get() {
	return index.storage_iso;
}

//
// ELEMENT
//
function dbnew_element_get(elementName){
	if(dbnew.db.element.db[elementName] && dbnew.db.element.db[elementName] !== ""){
		return dbnew.db.element.db[elementName];
	}
	else{
		return false;
	}
}

function dbnew_element_index_device_add(elementName){
	if(!index.element_device.includes(elementName)){
		index.element_device.push(elementName);
	}
}
function dbnew_element_index_device_get() {
	return index.element_device;
}

function dbnew_element_index_device_group_add(deviceGroupName){
	if(!index.element_device_group.includes(deviceGroupName)){
		index.element_device_group.push(deviceGroupName);
	}
}
function dbnew_element_index_device_group_get() {
	return index.element_device_group;
}

function dbnew_element_index_service_add(serviceName){
	if(!index.element_service.includes(serviceName)){
		index.element_service.push(serviceName);
	}
}
function dbnew_element_index_service_get(){
	return index.element_service;
}

function dbnew_element_index_service_group_add(serviceGroupName){
	if(!index.element_service_group.includes(serviceGroupName)){
		index.element_service_group.push(serviceGroupName);
	}
}
function dbnew_element_index_service_group_get(){
	return index.element_service_group;
}

