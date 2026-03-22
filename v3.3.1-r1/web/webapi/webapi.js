/**
 * ETHER|AAPEN - WEB|API
 * Licensed under AGPLv3+
 * (c) 2010-2025 | ETHER.NO
 * Author: Frode Moseng Monsson
 * Contact: frode.monsson@ether.no
 * version: 3.3.1
 **/

import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import fs from 'fs';
import net from 'net';
import fetch from 'node-fetch';
import crypto from 'crypto';
import dotenv from 'dotenv';
import os from 'os';

const app = express();

// Production CORS configuration
const allowedDomains = [
	'http://127.0.0.1',
	'http://localhost'
];

app.use((req, res, next) => {
	const origin = req.headers.origin;
	if (allowedDomains.some(domain => origin && origin.startsWith(domain))) {
		res.header('Access-Control-Allow-Origin', origin);
		res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
		res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
		res.header('Access-Control-Allow-Credentials', 'true');
	}
	next();
});

const http = createServer(app);
const io = new Server(http, {
	cors: {
		origin: (origin, callback) => {
			if (!origin || allowedDomains.some(domain => origin.startsWith(domain))) {
				callback(null, true);
			} else {
				callback(new Error('Not allowed by CORS'));
			}
		},
		methods: ['GET', 'POST'],
		credentials: true
	},
	path: '/socket.io',
	transports: ['websocket'],
	allowUpgrades: false,
	perMessageDeflate: false,
	pingTimeout: 20000,
	pingInterval: 25000,
	cookie: false,
	serveClient: false,
	allowEIO3: true
});
let obj;

// Load environment variables
dotenv.config();

// API Configuration
const api_pass = process.env.API_PASS || (() => {
	console.error('API_PASS environment variable not set!');
	process.exit(1);
})();

// version
const version = "v3.3.1";

// WebSocket API
const ws_port = parseInt(process.env.WS_PORT) || 3000;
const ws_addr = parseInt(process.env.WS_ADDRESS) || "0.0.0.0";

// REST API
const rest_port = parseInt(process.env.REST_PORT) || 3001;
const rest_addr = parseInt(process.env.REST_ADDRESS) || "localhost";

// connection limit
http.maxSockets = parseInt(process.env.MAX_SOCKETS) || 30;

//
// validate message
//
const validateMessage = (msg) => {
	if (!msg || typeof msg !== 'object') return false;
	if (!msg.pass || typeof msg.pass !== 'string') return false;
	if (!msg.aid || typeof msg.aid !== 'number') return false;
	if (!msg.req || typeof msg.req !== 'string') return false;
	return true;
};

//
// on connection
//
io.on('connection', function(socket){
	// rate limiting
	let requestCount = 0;
	const requestLimit = 500;
	const windowMs = 60000; // 1 minute
  
	socket.on('api', function(msg){
		
		// input validation
		if (!validateMessage(msg)) {
			console.warn('[webapi] Invalid message format');
			return socket.disconnect(true);
		}

		// rate limiting
		requestCount++;
		if (requestCount > requestLimit) {
			console.warn('[webapi] Rate limit exceeded for client [' + socket.id + ']');
			return socket.disconnect(true);
		}

		// secure password comparison (timing-safe)
		let passMatch;
		try {
			passMatch = crypto.timingSafeEqual(
				Buffer.from(msg.pass),
				Buffer.from(api_pass)
			);
		} catch (err) {
			console.error('[webapi] Password comparison error', err);
			return socket.emit('api_error', { 
				code: 500, 
				message: 'Internal server error' 
			});
		}

		// process request
		try {
			if (passMatch) {
				console.log('[webapi] client [' + socket.id + '] id [' + msg.aid + '] req [' + msg.req + ']');

				if(msg.req == "api_new"){
					api_proto_new(msg);
				}
				else{
					console.log('[webapi] unkonwn request type!');
					io.emit("api", api_access_denied());
				}

			}
			else{
				console.log('[webapi] authentication failed!');
				io.emit("api", api_access_denied());
			}
		} catch (err) {
			console.error('[webapi] api fatal error', err);
			return socket.emit('api_error', { 
				code: 500, 
				message: 'Internal server error' 
			});
		}
	});

	socket.on('disconnect', function(){
		console.log('[webapi] client [' + socket.id + '] disconnect');
	});
	
});

//
// listener
//
http.listen(ws_port, ws_addr, function(){
	console.log('AAPEN [nodejs] version [' + version + '] listening on [' + ws_addr + ':' + ws_port + ']');

	try {
		const nets = os.networkInterfaces();
		Object.entries(nets).forEach(([name, addresses]) => {
			addresses.forEach(addr => {
				if (addr.family === 'IPv4' && !addr.internal) {
					console.log('[webapi] interface [' + name + '] addr [' + addr.address + ']');
				}
			});
		});
	} catch (err) {
		console.error('Failed to log network interfaces:', err.message);
	}
});

//
// access denied response
//
function api_access_denied(){
	const packet = {
		version: version,
		fid: "aapen_nodejs",
		result: 0,
		string: "ACCESS_DENIED"
	};
	
	return JSON.stringify(packet);
};

//
// build version
//
function api_ver_build_noencode(){
	const packet = {};
	packet.version = version;
	packet.fid = "aapen_nodejs";
	
	return packet;
}

//
// build response header
//
function api_proto_response_build_noencode(){
	const obj = {};
	const packet = {};
	
	packet.result = 1;
	packet.string = "success: returning system rest data";
	packet.hash = "abcdef";
	packet.fid = "api_proto";
	packet.version = version;
	packet.service = "[webapi]";

	return packet;
};

//
// new api protocol
//
function api_proto_new(req){
	console.log("[webapi] received request");
	console.log(req);
	
	if(req.type == "get"){
		api_rest_get(req);
	}
	else if(req.type == "post"){
		api_rest_post(req);
	}
	else{
		console.log("[webapi] error: unknown request type!");
	}	
}

function api_rest_url(){
	
	return 'http://' + rest_addr + ':' + rest_port;
}

//
// api rest get
//
function api_rest_get(req){
	let url = api_rest_url() + req.url;
	
	const settings = { method: "Get" };

	fetch(url, settings)
		.then(res => res.json())
		.then((json) => {
			const result = {};

			result.proto = api_proto_response_build_noencode();			
			result.request = req;
			result.webapi = api_ver_build_noencode();
			result.response = json;
			
			io.emit("api", JSON.stringify(result));
		});	
	
}

//
// api rest post
//
function api_rest_post(req){
	let url = api_rest_url() + req.url;

	const settings = { 
		method: "POST",
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(req)
	};
	
	fetch(url, settings)
		.then(res => res.json())
		.then((json) => {
			var result = {};

			result.proto = api_proto_response_build_noencode();			
			result.request = req;
			result.webapi = api_ver_build_noencode();
			result.response = json;

			io.emit("api", JSON.stringify(result));
		});

}
