# AAPEN - Adaptive Array of Power Efficient Nodes

**Version: 3.3.1** | **Status: EXPERIMENTAL**

## AAPEN | Overview

**AAPEN** is a comprehensive virtualization, infrastructure, network, storage, network device (cluster elements), server, hardware and cloud management platform designed for enterprise-grade infrastructure automation and abstraction.
Built with Perl, NodeJS, JavaScript (and more recently in RUST...) 

It provides robust management of virtual resources, networks (TUN-TAP and DPDK/VPP), storage systems, network devices, and distributed clusters (**L2/L3 | Multicast/ZeroMQ | cluser sync**)
through a modular, socket-based and micro-service centric architecture. The framework has a comprehensive REST API, a modern HTML5 Bootstrap based web interface with a NodeJS back-end, as well as a robust REST/Native API based Command Line Interface (CLI).

-----

**AAPEN**, for short, or "**Adaptive Arrray of Power Efficient Nodes**", was originally built as part of a Masters (MSc) project where the goal was to develop an adaptive, flexible and dynamic clustering platform framework that would allow research
into deeper topics related to clustering; networking, virtualization and other relevant topics that otherwise might muse me. Using the **AAPEN** cluster framework as an underlay and glue to achieve this flexibility.
The original framework was written primarily in C with the front end (**CLI**) and management layer (**API**) was written in Perl. The framework has seen many iterations since then. This concept is still today reflected in the code which retains its "C syntax" (using Perl Experimental to replicate this..).. even though the original C code has been merged to Perl...
And now as the needs evolve the project is slowly migrating assorted components to RUST (where it makes sense)... such is time and the bane of progress... I guess...

Just as large parts of the front-end was once written in Java and using Swift for GUI elements, and the native API protocol; the modern front end has long since been migrated to HTML5, Javascript, Bootstrap, and a modern and easy-to use and quite feature-full and feature-complete REST API (absolutely everything that can be done via the Web interface and the CLI can be done using simple REST requests.. there is even a fully featured native API abstraction layer for these requests..)..
Yet, the **AAPEN** cluster framework, in its essence and purpose still somehow remains, though. As the project has been useful and served its purposes it has slowly evolved, and has remained the framework that I have used to manage my computing resources.

And in this manner the project is now released under an **Open Source** license (**GPL/AGPL**) in the hopes that either the framework, or at least some parts of it, may be somewhat useful to others as well. Open Source is what brings the world forard.. However, the **Catch 22** here is that as the framework is only used internally the 'need' to make it useful in such a matter has never been such a goal..

None the less... in a working condition (given its installed).. AAPEN matches even Proxmox, Nutanix and other more commercial solutions in complexity and functionaliy. As an individual that is both heavily certified and have worked, designed and implemented such solutions with many of these software solutions, this might even be an understatement..
Being certified and working professionally at a large scale with vmWare and Nutanix, as well as being certified and working with Cisco and DNA Center (more recently Catalyst Center) in large scale critical networks, and network automation via such SDN and SD-WAN solutions, the **AAPEN** framework provides very much similar functionaly via the "**Cluster Elements**" and the more recent and fully cloud-aware "**Cluster Instance**" micro-services..

However, keep in mind, **AAPEN** is developed on limited resources; internal functionality and my muses generally comes first; however, want some features or functionality? I'll do my very best to accomodate..


---
**AI and Vibe Coding disclaimer:** This project has existed long before LLM and Vibe Coding became a thing. I do try to use the various models as much as possible (I even pay for a number of them... the model curretly used is DeepSeek and CLINE), even hosting locally (the AAPEN framework has great IOMMU support, GPU accelerated system support for both AI LLM and VDI usage, already...), as well as using the large commercial models.

**However**, for AI LLM to be useful it needs to undersand (and buffer..) the full picture of the project, including libraries and underlying logic, and in its current state this is complicated.
Thus, LLM and AI has been used, however minor. Maybe as the models improve this usage can increase, there is always a trade-off. However, if your contribution to the project is solely LLM and Vibe coded additions without sanity these changes may not be added.
As the author of the project I am fully able to "vibe code" additions using purchased tokens for commercial LLM coding models myself. All other help what-so-wever, however, is very much appreciated!!

---

> **⚠️ Important Notes**: This is a code release. Critical functionality is missing, security mechanisms are present at best.. and bugs...


## AAPEN | Architecture
![AAPEN | Architecture](https://syn.ether.no:8080/aapen-release/aapen_architecture_00.drawio.png)

## AAPEN | Demo
![Watch the demo](https://img.youtube.com/vi/0lMvCLUGjkI/hqdefault.jpg)](https://www.youtube.com/watch?v=0lMvCLUGjkI)


![YouTube | AAPEN | Demo](https://www.youtube.com/watch?v=0lMvCLUGjkI)

## AAPEN | Key Features

### AAPEN | Core Capabilities
- **Virtual Machine Management**: QEMU/KVM hypervisor integration. VM life-cycle management, monitoring and live-migration support.
- **Network Automation**: Bridge, VLAN, DPDK/VPP and InfiniBand integration. Dynamic network initialization and monitoring.
- **Storage Management**: Dynamic storage pool discovery and management. With device, mdraid and NVME support -- with monitoring.
- **Cluster Coordination**: Multi-node synchronization and high availability. Cluster Health monitoring and integrated node voting.
- **REST API**: Modern JSON-based REST API interface. Easy integration with simple intuitive REST queries.
- **Web Interface**: REST based Bootstrap interface with integrated noVNC for VM console access, web-based SSH client, and NodeJS back-end.

### AAPEN | Architecture

- Secure API socket-based communication with SSL/TLS
- JSON protocol for all internal communications
- Simple and comprehensive REST API for easy integration
- Comprehensive logging and error handling
- Centralized configuration management
- Cluster node sync using Multicast and ZeroMQ

- Modular micro-service architecture:
	- **Framework**: Handles services, workers, VMMs, and node bootstrapping
	- **Agent**: Handles external to internal API communications. (TLS/SSL)
	- **CDB**: In-memory object and cluster database
	- **API**: Node API gateway and proxy. Also provides REST interface (Mojolicious)
	- **Cluster**: Handles cluster and node synchrnoization (Multicast, ZeroMQ)
	- **Hypervisor**: Manages virtual resources running on a node
	- **Network**: Handles network operations for the node as well as virtual resources
	- **Storage**: Handles storage operations for the node as well as virtual resources
	- **Monitor**: Monitors local as well as remote node and services, reports status to cluster
	- **WebAPI**: Handles and proxies communication between the API and the browser (NodeJS)   
	- **WebUI**: Modern Bootstrap based Web Interface
	- **CLI**: Interactive Command Line Interface with tab-completion
	


### AAPEN | Mostly Working Features
- Core virtualization management
- Network bridge and device configuration
- Storage pool operations
- Cluster synchronization
- Basic REST API endpoints
- Command-line interface
- Bootstrap based Web interface

### AAPEN | In Progress
- Configuration migration to new model (v3.3.3)
- Enhanced REST API development and migrate WebUI - mostly completed
- Improved threading for async jobs and operations - TODO
- Web interface improvements
- Installation automation
- Ability to create more objects without needing an editor..


### AAPEN | Known Limitations
- Complex installation process
- Manual dependency resolution
- Limited to no automated testing
- Evolving documentation
- Creating and boostrapping configuration
- No turn-key node config and init methods

### AAPEN | Advanced Cluster Features
- Hardware accelerated InfiniBand networking and **InfiniBand based RDMA** (Remote Direct Memory Access) cluster features...
- Hardware accelerated Networking features based on **VPP (Vector Packet Processor) and DPDK (Data Plane Development Kit)** via **SRV-IO**
- Support for various accelerators such as **GPU's, RNG's, PCI devices**, as well as USB devices to resources running in the cluster fabric


### AAPEN | Future
- An effort to rewrite services and components, at least the resource hungry ones, of the framework into RUST code is in progress...

## ⚠️ Disclaimer

This is beta software intended for technical evaluation and development. Not recommended for production - or pretty much any use, at current state.

---

## AAPEN | HELP, SUPPORT & WARNINGS

**Do you want to help the project? In any way? This would be very much appreciated!**

This project is primarily made for internal use, and has been continously developed and used in production since 2010; and within given contstraints - is actually amazingly stable, secure, and reliable.
However, many pieces of the software is still relatively fragile (and will definitively require debugging and manual error resolution at its current state). Using this software in any meaningful way, requires both adequate coding and debugging skills.. 


To use this software also requires adequate networking and security skills, **this software does not currently yet have even close to anything remotely adequate level of security at the management plane...** the system ("data") plane however, is relatively secure and sound..
If you have the experience, knowledge and understanding required to separate and adequately **secure the 'management' and separate the 'data' plane** - this software might be surprisingly useful and even actually nearly close to production worthy...

Fortunately; as there is no currently workable and usable installer, this should not pose too much of a problem...

**If you would like to help the project, this would be very much appreciated; perhaps the most pressing elements at present:**
- Installer and installation documentation
- Web interface debugging, improvements and development
- General code review, sanity and improvements
- This list is not complete..
- If there is anything else you would be willing to assist or help this project, in any way, please do not hesitate..

**For any queries, or questions, please contact: aapen@ether.no**


---

## AAPEN | Installation

The closest things to install this thing looks as following:

### AAPEN | Alpine Linux:
	- Install Alpine Linux Standard (Tested on Alpine 3.22.2)
	- Enable community repos: setup-apkrepos -c
	# apk add gcc
	# apk add make
	# apk add build-base
	# apk add linux-headers
	# apk add musl-obstack
	# apk add musl-obstack-dev
	# apk add openssl
	# apk add openssl-dev
	# apk add zlib
	# apk add zlib-dev
	# apk add perl
	# apk add perl-dev
	# apk add czmq
	
	# apk add apache
	# apk add git
	# apk add qemu-system-x86_64
	
	# apk add perl-io-socket-ssl
	# apk add perl-json
	# apk add perl-json-maybexs
	# apk add perl-xml-parserquit
	
	# get the latest version of AAPEN
	# tar xvzf (make sure to extract to root directory /aapen)
		- to change native root directory, modify 'env/root.cfg' and update paths
	# cd /aapen/install/
	# sh cpan_install.sh
	


### AAPEN | Slackware Linux (v15 and Current):
The main development and production platform for this framework has been Slackware Linux... this might be the easiest path to make it work...


	- Install Slackware Linux version 15 or -current
		- Configure disks and swap as needed..
		- Install A, AP, D, L, N, T, X, XAP, Y
			(feel free to strip unneeded and optimize as needed...)
			(for a more lean install consider using Alpine)
			(Slackware is reccomended for devel and admin nodes, and use Alpine for Hypervisors and Storage nodes)
		
	# If running -current, execute 'export PERL_MM_USE_DEFAULT=1' before running CPAN...
	# get the latest version of AAPEN
	# tar xvzf (make sure to extract to root directory /aapen)
		- to change native root directory, modify 'env/root.cfg' and update paths
	# cd /aapen/install/
	# sh cpan_install.sh
	
	# get qemu from slackpkg.org (tested with 9.2.4 and 10.0.2)
		- run with "TARGETS=x86_64-softmmu KVMGROUP=users  AUDIODRIVERS="alsa,oss" ./qemu.SlackBuild"

It should however work on most Linux distributions with a fair amount of tweaking given some basic requirements..
The software has succesfully been run for a long time on Ubuntu, OpenSuse, Suse Linux Enterprise Server (SLES), Arch and Gentoo Linux..

### AAPEN | Ubuntu Linux:
The AAPEN cluster framework runs fine on Ubuntu... most cloud instances of AAPEN currently runs on Ubuntu..
- UBUNTU INSTALLER TODO


## AAPEN | INTRODUCTION

**Be warned. There be bugs. lots and lots of bugs.. really dumb bugs. dangerous bugs :)**


### OVERVIEW VIEW

**[ Cluster | Login ]** Navigate to the management node (here 'http://plateau.eth/aapen') using the API key and port
![picture](https://syn.ether.no:8080/aapen-release/web-login-00.jpg)

**[ Cluster | Overview ]** The web interface cluster overview
![picture](https://syn.ether.no:8080/aapen-release/aapen-overview-00.jpg)

### AAPEN | NODE VIEW

**[ Node | Overview ]** The node overview shows a simple table based view of the nodes in the cluster
![picture](https://syn.ether.no:8080/aapen-release/node-overview-00.jpg)

**[ Node | Resources ]** The node resource view gives a quick overview of the node resource usage
![picture](https://syn.ether.no:8080/aapen-release/node-resource-00.jpg)

**[ Node | View ]** The node view gives a detailed view of the node
![picture](https://syn.ether.no:8080/aapen-release/node-view-00.jpg)

---

**[ Node View | Network ]** The status of the network service for a node
![picture](https://syn.ether.no:8080/aapen-release/node-network-00.jpg)

**[ Node View | Hypervisor ]** The status of the hypervisor service for a node
![picture](https://syn.ether.no:8080/aapen-release/node-hypervisor-00.jpg)

**[ Node View | Hyperivsor | Async ]** The status and result of async jobs
![picture](https://syn.ether.no:8080/aapen-release/node-hypervisor-01.jpg)



### AAPEN | SYSTEM VIEW

**[ System | Overview ]** The system overview
![picture](https://syn.ether.no:8080/aapen-release/system-overview-00.jpg)

**[ System | Resource View ]** The system resource overview
![picture](https://syn.ether.no:8080/aapen-release/system-resource-00.jpg)


### AAPEN | NETWORK VIEW

**[ Network | System Overview ]** The system view here with the statistics expanded
![picture](https://syn.ether.no:8080/aapen-release/network-system-view-00.jpg)

**[ Network | View ]** The network object view
![picture](https://syn.ether.no:8080/aapen-release/network-view-00.jpg)


### AAPEN | STORAGE VIEW

**[ Storage | Overview ]** The storage overview gives the following list
![picture](https://syn.ether.no:8080/aapen-release/storage-overview-00.jpg)

**[ Storage | Pool View ]** The following picture shows the storage overview
![picture](https://syn.ether.no:8080/aapen-release/storage-pool-view-00.jpg)


### AAPEN | HEALTH VIEW

**[ Cluster | Health ]** The Health 'Overview' option selects the main cluster node by default (here plateau)**
![picture](https://syn.ether.no:8080/aapen-release/cluster-health-00.jpg)

**[ Cluster | Health ]**  The 'Overview' Health and Alarm view drawers expanded
![picture](https://syn.ether.no:8080/aapen-release/cluster-health-01.jpg)

**[ Cluster | Health ]** The Node 'Overview' Node Monitor view
![picture](https://syn.ether.no:8080/aapen-release/cluster-health-02.jpg)

**[ Cluster | health ]** The 'Overview' Object Service view**
![picture](https://syn.ether.no:8080/aapen-release/cluster-health-03.jpg)


### AAPEN |  CLI

**[ CLI | Overall ]** The overall CLI functionality
![picture](https://syn.ether.no:8080/aapen-release/cli-00.jpg)

**[ CLI | System ]** Show command example
![picture](https://syn.ether.no:8080/aapen-release/cli-01.jpg)


### AAPEN | Cluster Monitor

**[ Cluster | Health Monitor ]** Monitors the cluster health and publishes the state to the cluster
![picture](https://syn.ether.no:8080/aapen-release/service-monitor-00.jpg)

---

**Infected Technologies** | **ether.no** | **© 2010-2025**
