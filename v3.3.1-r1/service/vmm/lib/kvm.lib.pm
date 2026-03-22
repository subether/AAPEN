#
# ETHER|AAPEN|VMM - LIB|KVM
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#

use warnings;
use strict;
use experimental 'signatures';

# process id
my $vm_proc;


sub check_dangerous_strings($str){
	my $fid = "[check_dangerous_strings]";
	my $ffid = "CHECK|STRINGS";
	
	# Check for shell metacharacters
	if($str =~ /[;\|&`\$<>]/) {
		log_error($ffid, "warning: locked dangerous shell metacharacters");
		return 0;
    }
    
    return 1;
}

#
# unload vm [JSON-STR]
#
sub kvm_unload($vm){
	my $fid = "[kvm_unload]";
	my $ffid = "KVM|UNLOAD";
	my $result;
	
	log_info_json($ffid, "preparing vm unload, vmm lock state [" . lock_state() . "]", $vm);
	
	# check lock and vm state
	if(lock_state() && $vm->{'meta'}{'state'}){
		log_info($ffid, "vm is online. resource locked. continuing...");
	
		# get shared data
		my %vmshare = vmshare_get();
		my $lockfile = $vmshare{'vmmlock'};
		
		log_info($ffid, "checking lockfile [$lockfile.lock]");
		
		if(lockfile_check($lockfile)){
			# can continue, check process id
			log_info($ffid, "vm lockfile [$lockfile] present. process id [$vm_proc] vmproc [$vm->{'meta'}{'vmproc'}]");
			
			#############
			# threading #
			#############
			
			# update shared database
			my %vmshare = vmshare_get();
			
			log_info($ffid, "shared data:");
			log_info($ffid, "exec [$vmshare{'vmmexec'}]");
			log_info($ffid, "lock [$vmshare{'vmmlock'}]");
			log_info($ffid, "pid [$vmshare{'vmmpid'}]");
			log_info($ffid, "out [$vmshare{'vmmout'}]");
			log_info($ffid, "err [$vmshare{'vmmerr'}]");
			log_info($ffid, "proc [$vmshare{'vmmproc'}]");
			log_info($ffid, "stat [$vmshare{'vmmstat'}]");
			
			$vmshare{'vm_state'} = "0";
			$vmshare{'vm_status'} = "unloaded";
			$vmshare{'vm_lock'} = "0";
			$vmshare{'vm_running'} = "0";
			
			vmshare_set(%vmshare);
				
			# close vm and clear locks
			my $status = 1;
			lock_clear();
			
			# update metadata
			$vm->{'meta'}{'vmproc'} = "";
			$vm->{'meta'}{'state'} = 0;
			$vm->{'meta'}{'state'} = 0;
			$vm->{'meta'}{'pid'} = "";
			
			# remove lockfile
			my $lockfile_state = lockfile_del($lockfile);
			log_info($ffid, "removed lockfile [$lockfile.lock] status [$lockfile_state]");

			# clear migration flag on unload
			if($vm->{'meta'}{'migrate'}){
				$vm->{'meta'}{'migrate'} = 0;
				log_info($ffid, "clearing migration flag [$vm->{'meta'}{'migrate'}]");
			}
			
			# display results
			log_info($ffid, "lock_state [". lock_state() . "]");
			log_info($ffid, "vm_proc: [$vm_proc]");
			log_info($ffid, "meta:state: [$vm->{'meta'}{'state'}]");
			log_info($ffid, "meta:pid: [$vm->{'meta'}{'pid'}]");
			
			# unload succeeded
			log_info($ffid, "sucess: system unload completed");
			$result = packet_build_encode("1", "success: system unload completed", $fid);
		}
		else{
			# no lockfile present
			log_warn($ffid, "error: no vm lockfile [$lockfile] present!");
			$result = packet_build_encode("0", "error: no vm lockfile [$lockfile] present!", $fid);
		}
	}
	else{
		# vm is not loaded
		log_error($ffid, "error: vm is offline. unload failed.");
		$result = packet_build_encode("0", "error: vm is offline. unload failed", $fid);
	}
	return ($result, $vm);
}

#
# kvm disk info [JSON-OBJ]
#
sub kvm_disk_info($vm) {
    my $fid = "[kvm_disk_info]";
    my $ffid = "KVM|DISK|INFO";
    my $info = {};
    
    log_info($ffid, "disk devices [$vm->{'stor'}{'disk'}]");
    my @disks = index_split($vm->{'stor'}{'disk'});
    
    foreach my $disk (@disks) {

        if($vm->{'stor'}{$disk}{'type'} eq "qcow2") {
            my $disk_path = $vm->{'stor'}{$disk}{'dev'} . $vm->{'stor'}{$disk}{'image'};
            
            # Use JSON output format for more reliable parsing
            my $exec = "qemu-img info --output=json $disk_path 2>&1";
            my $result = `$exec`;
            
            if($? != 0) {
				log_warn($ffid, "failed to get disk info for [$disk_path] result [$result]");
                next;
            }
            
            eval {
                my $disk_data = decode_json($result);
                
                $info->{$disk} = {
                    'format'         => $disk_data->{'format'} || 'unknown',
                    'virt_size'      => $disk_data->{'virtual-size'} || 0,
                    'virt_unit'      => 'bytes',
                    'disk_size'      => $disk_data->{'actual-size'} || 0,
                    'disk_unit'      => 'bytes',
                    'cluster_size'   => $disk_data->{'cluster-size'} || 0,
                    'compat'         => $disk_data->{'format-specific'}{'data'}{'compat'} || 'unknown',
                    'compression'    => $disk_data->{'format-specific'}{'data'}{'compression-type'} || 'none',
                    'refcounts'      => $disk_data->{'format-specific'}{'data'}{'refcount-bits'} ? 'enabled' : 'disabled',
                    'refcount_bits'  => $disk_data->{'format-specific'}{'data'}{'refcount-bits'} || 0,
                    'corrupt'        => $disk_data->{'corrupt'} ? 'yes' : 'no'
                };
                
                # Convert sizes to human-readable units if needed
                foreach my $size_type (qw(virt_size disk_size)) {
                    if($info->{$disk}{$size_type} > 1024*1024*1024) {
                        $info->{$disk}{$size_type} = sprintf("%.2f", $info->{$disk}{$size_type}/(1024*1024*1024));
                        $info->{$disk}{$size_type.'_unit'} = 'GB';
                    } elsif($info->{$disk}{$size_type} > 1024*1024) {
                        $info->{$disk}{$size_type} = sprintf("%.2f", $info->{$disk}{$size_type}/(1024*1024));
                        $info->{$disk}{$size_type.'_unit'} = 'MB';
                    } elsif($info->{$disk}{$size_type} > 1024) {
                        $info->{$disk}{$size_type} = sprintf("%.2f", $info->{$disk}{$size_type}/1024);
                        $info->{$disk}{$size_type.'_unit'} = 'KB';
                    }
                }
            };
            
            if($@) {
                log_warn($ffid, "failed to parse disk info for [$disk_path] error [$@]");
                next;
            }
        }
    }
    
    $vm->{'meta'}{'disk'} = $info;
    return $vm;
}

#
# load vm
#
sub kvm_load($vm){
	my $fid = "[kvm_load]";
	my $ffid = "KVM|LOAD";
	my $string; 
	my $result = 0;
	
	# print header
	log_info_json($ffid, "preparing vm load, vmm lock state [" . lock_state() . "]", $vm);
	
	# check for lock and vm state
	if((!lock_state() && !$vm->{'meta'}{'state'}) || (!lock_state() && $vm->{'meta'}{'migrate'})){
	
		# check for lockfile, or if migration container ensure it is present
		my $lockfile = kvm_disk_lock_prep($vm);
		log_info($ffid, "checking lockfile [$lockfile]");
	
		if(!lockfile_check($lockfile) || (lockfile_check($lockfile) && $vm->{'meta'}{'migrate'})){
		
			# add lockfile
			my $lockfile_state = lockfile_add($lockfile);
			log_info($ffid, "added lockfile [$lockfile] status [$lockfile_state]");
		
			$vm = kvm_disk_info($vm);
		
			# load vm
			log_info($ffid, "preparing vm configuration");
			my $exec = kvm_prep($vm);
			
			# load
			log_info($ffid, "spawning vm..");
			
			#############
			# threading #
			#############
			
			# shared database
			my %vmshare = vmshare_get();
			
			# set exec
			$vmshare{'vmmexec'} = $exec;
			
			# identity
			$vmshare{'vm_name'} = $vm->{'id'}{'name'};
			$vmshare{'vm_id'} = $vm->{'id'}{'id'};
			
			$vmshare{'node_name'} = $vm->{'meta'}{'node'};
			$vmshare{'node_id'} = $vm->{'meta'}{'agent'};
			
			$vmshare{'vm_state'} = "1";
			$vmshare{'vm_status'} = "loaded";
			
			# update paths
			$vmshare{'vmmlock'} = $lockfile;
			$vmshare{'vmmoutfile'} = env_base_get() . "log/" . "vmm." . $vm->{'id'}{'name'} . "." . $vm->{'id'}{'id'} . ".out";
			
			# broadcast init flag
			$vmshare{'vmminit'} = 1;
			
			log_info($ffid, "local exec [$exec]");
			log_info($ffid, "shared exec [$vmshare{'vmmexec'}]");

			# commit
			vmshare_set(%vmshare);
			vmm_db_vm_set($vm);
			
			# wait for exec to complete
			do{
				sleep 2;
				log_info($ffid, "waitning for status... updating shared data");
				%vmshare = vmshare_get();
			}while(!$vmshare{'vmmstat'});
			
			# check error flag
			log_info($ffid, "vmmstat [$vmshare{'vmmstat'}], error [$vmshare{'vmmerr'}], output [$vmshare{'vmmout'}]");
			
			# if no errors, continue
			if(!$vmshare{'vmmerr'}){
						
				# update pid
				my $proc_id = $vmshare{'vmmproc'};
				my $pid = $vmshare{'vmmpid'}; 
				
				##########################
				# thread model completed #			
				##########################
	
				log_info($ffid, "spawned pid [$pid] proccess id [$proc_id]");
				
				# wait for qemu to settle
				sleep 2;
				
				# check qemu status
				my $exec = "ps aux | grep $pid | head -1 | awk " . '\'{ print $12 }\'';
				my $qemustat = execute($exec);
				chomp($qemustat);

				log_info($ffid, "qemu status [$qemustat]");
				
				# ensure qemu is not live yet defunct
				if($qemustat ne "<defunct>"){
					log_info($ffid, "qemu spawned successfully");
				
					# we are live, lock self
					lock_set();
					$vm_proc = $proc_id;
					
					# add metadata
					$vm->{'meta'}{'vmproc'} = $proc_id;
					$vm->{'meta'}{'state'} = 1;
					$vm->{'meta'}{'pid'} = $pid;
					$vm->{'meta'}{'date'} = date_get();
					
					log_info($ffid, "lock state [" . lock_state() . "] vm proc [$vm_proc] meta state: [$vm->{'meta'}{'state'}] meta pid [$vm->{'meta'}{'pid'}");
					
					$string = "$fid vmm: loaded [$vm->{'id'}{'name'}] pid [$pid]";
					$result = 1;
				
					if($vm->{'meta'}{'migrate'}){
						log_warn($ffid, "VMM IS A MIGRATION CONTAINER!");
					}
					
					# save config to vmdir
					my $cfgfile = vmm_cfg_file($vm);
					json_file_save($cfgfile, $vm);
					
					%vmshare = vmshare_get();
					$vmshare{'vm_state'} = "1";
					$vmshare{'vm_status'} = "running";
					$vmshare{'vm_lock'} = "1";
					$vmshare{'vm_running'} = "1";
					vmshare_set(%vmshare);
					
				}
				else{
					# loading failed, qemu is defunct. killing it.. 
					$vm_proc = $proc_id;
					
					# add metadata
					$vm->{'meta'}{'vmproc'} = $proc_id;
					$vm->{'meta'}{'state'} = 1;
					$vm->{'meta'}{'pid'} = $pid;
					$string = "$fid error: qemu failed to load! destroying it. check vmm logs!\n";
					
					# clear lock
					lock_clear();
					$lockfile_state = lockfile_del($lockfile);
					log_info($ffid, "removed lockfile [$lockfile] status [$lockfile_state]");
					
					%vmshare = vmshare_get();
					$vmshare{'vm_state'} = "2";
					$vmshare{'vm_status'} = "error";
					$vmshare{'vm_lock'} = "0";
					$vmshare{'vm_running'} = "0";
					vmshare_set(%vmshare);
					
				}
			}
			else{
				# threading caused errors
		
				# add metadata
				$vm->{'meta'}{'vmproc'} = 0;
				$vm->{'meta'}{'state'} = 0;
				$vm->{'meta'}{'pid'} = 0;
				
				# unloading no longer needed
				$string = "$fid error: hypervisor thread failed to spawn qemu.\n";
				
				# clear lock
				lock_clear();
				$lockfile_state = lockfile_del($lockfile);
				log_info($ffid, "removed lockfile [$lockfile] status [$lockfile_state]");
				
				%vmshare = vmshare_get();
				$vmshare{'vm_state'} = "2";
				$vmshare{'vm_status'} = "error";
				$vmshare{'vm_lock'} = "0";
				$vmshare{'vm_running'} = "0";
				vmshare_set(%vmshare);
				
			}
		}
		else{
			log_error($ffid, "error: vm lockfile [$lockfile] present!");
			$string = "$fid error: vm lockfile [$lockfile] present!";			
		}
	}
	else{
		log_error($ffid, "error: vm is online. resource locked.");
		$string = "$fid error: vm is online. resource locked.";
	}
	
	return ($result, $string, $vm);
}

#
# prepare load
#
sub kvm_prep($vm){
	my $fid = "[kvm_prep]";
	my $ffid = "KVM|PREP";

	# prepare data
	#print "$fid compiling load string\n";
	my $machine = kvm_machine_prep($vm);
	my $id = kvm_id_prep($vm);
	my $bios = kvm_bios_prep($vm);
	my $opts = kvm_opts_prep($vm);
	my $network = kvm_net_prep($vm);
	my $disk = kvm_disk_prep($vm);
	my $iso = kvm_iso_prep($vm);
	my $monitor = kvm_monitor_prep($vm);
	my $migrate = kvm_migrate_prep($vm);
	my $extra = kvm_extra_prep($vm);
	
	log_info($ffid, "compiling load string");
	log_info($ffid, "machine [$machine]");
	log_info($ffid, "id [$id]");
	log_info($ffid, "bios [$bios]");
	log_info($ffid, "opts [$opts]");
	log_info($ffid, "network [$network]");
	log_info($ffid, "disk [$disk]");
	log_info($ffid, "iso [$iso]");
	log_info($ffid, "monitor [$monitor]");
	log_info($ffid, "migrate [$migrate]");
	log_info($ffid, "extra [$extra]");

	# build exec
	my $exec = "qemu-system-x86_64 " . $id . $machine . $bios . $opts . $network . $disk . $iso . $monitor . $migrate . $extra;
	
	# return
	log_debug($ffid, "exec [$exec]");
	return $exec;
}

#
# prepare bios config [STRING]
#
sub kvm_bios_prep($vm){
	my $fid = "[kvm_bios_prep]";
	my $ffid = "KVM|BIOS|PREP";
	my $bios = "";
	my $edk_path = "/usr/share/edk2-ovmf-x64/";
		
	if(defined($vm->{'hw'}{'bios'})){
		
		if(defined($vm->{'hw'}{'bios'}{'mode'}) && $vm->{'hw'}{'bios'}{'mode'} eq "uefi"){
			log_info($ffid, "bios is UEFI mode [$vm->{'hw'}{'bios'}{'mode'}]");
			
			# check for defaults or custom uefi edk
			if(defined($vm->{'hw'}{'bios'}{'model'}) && ($vm->{'hw'}{'bios'}{'model'} ne "default" && $vm->{'hw'}{'bios'}{'model'} ne "")){
				log_info($ffid, "UEFI model is defined [$vm->{'hw'}{'bios'}{'model'}]");
				$bios = " -smbios type=0,uefi=on -bios " . $edk_path . $vm->{'hw'}{'bios'}{'model'} . " ";
			}
			else{
				log_info($ffid, "EFI default mode [$vm->{'hw'}{'bios'}{'model'}]");
				$bios = " -smbios type=0,uefi=on -bios " . $edk_path . "OVMF_CODE.fd ";
			}
		}
		else{
			log_info($ffid, "bios is legacy mode [$vm->{'hw'}{'bios'}{'mode'}]");
		}
		
	}
	else{
		log_info($ffid, "no bios option selected. defaulting to legacy");
	}
	
	return $bios;
}

#
# prepare network config [STRING]
#
sub kvm_extra_prep($vm){
	my $fid = "[kvm_extra_prep]";
	my $ffid = "KVM|EXTRA|PREP";
	my $extra = "";
	
	
	if(defined($vm->{'hw'}{'extra'})){
		log_info($ffid, "adding extra options [$vm->{'hw'}{'extra'}]");
		$extra = " " . $vm->{'hw'}{'extra'};
	}
	else{
		log_info($ffid, "no extra options");
	}
	
	return $extra;
}

#
# prepare network config [STRING]
#
sub kvm_net_prep($vm){
	my $fid = "[kvm_net_prep]";
	my $ffid = "KVM|NET|PREP";
	my $net_id = 0;
	my ($network, $bridge, $interface, $net_if);
	
	# network metadata
	log_info($ffid, "network devices [$vm->{'net'}{'dev'}]");
	my @nics = index_split($vm->{'net'}{'dev'});
	
	# process interfaces
	foreach $net_if (@nics){

		log_info($ffid, "id [$net_id] dev [$net_if] driver [$vm->{'net'}{$net_if}{'driver'}] mac [$vm->{'net'}{$net_if}{'mac'}]");
		
		# handle legacy driver spec
		if($vm->{'net'}{$net_if}{'driver'} eq "virtio"){
			$vm->{'net'}{$net_if}{'driver'} = "virtio-net";
		}
		
		# handle types
		if($vm->{'net'}{$net_if}{'net'}{'type'} eq "dpdk-vpp"){
			log_info($ffid, "network type is [DPDK-VPP]");
			$vm->{'net'}{$net_if}{'driver'} = "virtio-net-pci";
			$interface = kvm_net_dpdk_prep($vm, $net_if, $interface, $net_id);
			
		}
		elsif($vm->{'net'}{$net_if}{'net'}{'type'} eq "bri-tap"){
			log_info($ffid, "network type is [TUNTAP]");
			$interface = kvm_net_tuntap_prep($vm, $net_if, $interface, $net_id);
		}
		else{
			log_info($ffid, "network type undefined. defaulting to [TUNTAP]");
			$interface = kvm_net_tuntap_prep($vm, $net_if, $interface, $net_id);
		}
		
		# next net
		$net_id++;
	}
	
	return $interface; 
}

#
# configure DPDK network [STRING]
#
sub kvm_net_dpdk_prep($vm, $net_if, $interface, $net_id){
	my $fid = "[kvm_net_dpdk_prep]";
	my $ffid = "KVM|NET|DPDK|PREP";
	
	my $chardev = " -chardev socket,id=char_" . $net_if . ",path=" . $vm->{'net'}{$net_if}{'vpp'}{'socket'};
	my $netdev = " -netdev type=vhost-user,id=dev_" . $net_if . ",chardev=char_" . $net_if;
	my $device = " -device " . $vm->{'net'}{$net_if}{'driver'} . ",mac=" . $vm->{'net'}{$net_if}{'mac'} . ",netdev=dev_" . $net_if;
	my $object = " -object memory-backend-file,id=mem,size=" . $vm->{'hw'}{'mem'}{'mb'} . "M,mem-path=/dev/huge_" .  $vm->{'id'}{'name'} . "-" . $vm->{'id'}{'id'} . ",share=on -numa node,memdev=mem -mem-prealloc ";
	$interface = $chardev . $netdev . $device . $object;	

	return $interface;
}

#
# configure TUNTAP network [STRING]
#
sub kvm_net_tuntap_prep($vm, $net_if, $interface, $net_id){
	my $fid = "[kvm_net_tuntap_prep]";
	my $ffid = "KVM|NET|TUNTAP|PREP";
	
	my $network = " -device " . $vm->{'net'}{$net_if}{'driver'} . ",mac=" . $vm->{'net'}{$net_if}{'mac'} . ",netdev=dev" . $net_id;
	my $bridge = " -netdev tap,id=dev" . $net_id . ",ifname=tap" . $vm->{'net'}{$net_if}{'tap'}{'tap'}{'dev'} . ",script=no,downscript=no";
	$interface = $interface . $network . $bridge;
	
	return $interface;
}

#
# prepare disk config [STRING]
#
sub kvm_disk_prep($vm){
	my $fid = "[kvm_disk_prep]";
	my $ffid = "KVM|DISK|PREP";
	my $disk_id = 0;
	my ($disk, $file, $image);
	
	# network metadata
	log_info($ffid, "disk devices [$vm->{'stor'}{'disk'}]");
	my @disks = index_split($vm->{'stor'}{'disk'});
	
	# process disks
	foreach $disk (@disks){

		log_info($ffid, "id [$disk_id] dev [$disk] device [$vm->{'stor'}{$disk}{'dev'}]");
		log_info($ffid, "id [$disk_id] dev [$disk] device [$vm->{'stor'}{$disk}{'image'}]");
		log_info($ffid, "id [$disk_id] dev [$disk] device [$vm->{'stor'}{$disk}{'type'}]");
		log_info($ffid, "id [$disk_id] dev [$disk] device [$vm->{'stor'}{$disk}{'size'}]");
		log_info($ffid, "id [$disk_id] dev [$disk] device [$vm->{'stor'}{$disk}{'media'}]");
		log_info($ffid, "id [$disk_id] dev [$disk] device [$vm->{'stor'}{$disk}{'cache'}]");
		log_info($ffid, "id [$disk_id] dev [$disk] device [$vm->{'stor'}{$disk}{'driver'}]");
		
		# process string
		$file = $vm->{'stor'}{$disk}{'dev'} . $vm->{'stor'}{$disk}{'image'};
		$image = $image . " -drive file=$file,if=$vm->{'stor'}{$disk}{'driver'},format=$vm->{'stor'}{$disk}{'type'},media=$vm->{'stor'}{$disk}{'media'},cache=$vm->{'stor'}{$disk}{'cache'},index=$disk_id ";
		
		# next disk
		$disk_id++;
	}
	
	return $image; 
}

#
# prepare disk lock files [STRING]
#
sub kvm_disk_lock_prep($vm){
	my $fid = "[kvm_disk_lock_prep]";
	my $ffid = "KVM|DISK|LOCK|PREP";
	my $disk_id = 0;
	my ($disk, $file, $image);
	my $lockdir = get_root() . "lock/";
	my $lockfile;
		
	# network metadata
	log_info($ffid, "disk devices [$vm->{'stor'}{'disk'}]");
	my @disks = index_split($vm->{'stor'}{'disk'});

	# only lock first disk for now... TODO
	$disk = $disks[0];
	
	# build locking string
	if($vm->{'stor'}{$disk}{'lock_type'} eq "local"){
		log_info($ffid, "using local locking");
		$lockfile = $lockdir . $vm->{'stor'}{$disk}{'image'};
	}
	elsif($vm->{'stor'}{$disk}{'lock_type'} eq "linked"){
		# link lock with diskfile (for nfs)
		log_info($ffid, "using linked locking");
		$lockfile = $vm->{$disk}{'dev'} . $vm->{'stor'}{$disk}{'image'};
	}
	else{
		# fall back to old locking if #undef
		log_info($ffid, "undefined. defaulting to local");
		$lockfile = $vm->{'stor'}{$disk}{'dev'} . $vm->{'stor'}{$disk}{'image'};
	}
	
	# return lockfile
	log_info($ffid, "lock file defined as [$lockfile]");
	return $lockfile;
}

#
# prepare machine config [STRING]
#
sub kvm_machine_prep($vm){
	my $fid = "[kvm_machine_prep]";
	my $ffid = "KVM|MACHINE|PREP";
	my $nest = " ";
	my $machine;
	#my $default_cpu = "Opteron_G3";
	my $default_cpu = "";
	
	# check for nested support
	if($vm->{'hw'}{'cpu'}{'nest'}){
		log_info($ffid, "enabling nested CPU support");
		$nest = "-cpu host ";
	}
	elsif(exists($vm->{'hw'}{'cpu'}{'model'})){
		log_info($ffid, "cpu type configured [$vm->{'hw'}{'cpu'}{'model'}]");
		$nest = "-cpu  " . $vm->{'hw'}{'cpu'}{'model'};
		
		if($vm->{'hw'}{'cpu'}{'hugepages'} eq "1"){
			log_info($ffid, "enabling 1GB hugepage support");
			$nest = $nest . ",+pdpe1gb ";
		}
		else{
			$nest = $nest . " ";
		}
	}
	else{
		if($default_cpu ne ""){
			log_info($ffid, "no cpu type defined. defaulting to [$default_cpu]");
			$nest = "-cpu  " . $default_cpu . " ";			
		}
	}
	
	# compile machine string
	$machine = " -smp $vm->{'hw'}{'cpu'}{'core'},cores=$vm->{'hw'}{'cpu'}{'core'} -m $vm->{'hw'}{'mem'}{'mb'} " . $nest;
	
	return $machine;
}

#
# identity config [STRING]
#
sub kvm_id_prep($vm){
	my $fid = "[kvm_name_prep]";
	my $name = "-name " . '"' . "AAPEN [" . env_version() . "] system [$vm->{'id'}{'name'}] id [$vm->{'id'}{'id'}] @ node [$vm->{'meta'}{'node'}] id [$vm->{'meta'}{'agent'}]" . '"';
	return $name;
}

#
# options config [STRING]
#
sub kvm_opts_prep($vm){
	my $fid = "[kvm_opts_prep]";
	my $ffid = "KVM|OPTS|PREP";
	
	if(exists($vm->{'meta'}{'keyboard'})){
		# exists
	}
	else{
		$vm->{'meta'}{'keyboard'} = "en-us";
	}
	
	my $options = "-enable-kvm -machine hpet=off -vnc :$vm->{'meta'}{'vnc'} -vga virtio";
	return $options;
}

#
# monitor config [STRING]
#
sub kvm_monitor_prep($vm){
	my $fid = "[kvm_mon_prep]";
	my $ffid = "KVM|MON|PREP";
	my $monitor = "";
	
	log_info($ffid, "monitor addr [$vm->{'monitor'}{'addr'}] port [$vm->{'monitor'}{'proto'}] proto [$vm->{'monitor'}{'proto'}]");
	$monitor = " -monitor " . $vm->{'monitor'}{'proto'} . ":" . $vm->{'monitor'}{'addr'} . ":" . $vm->{'monitor'}{'port'} . ",server,nowait";
	return $monitor;
}

#
# migration config [STRING]
#
sub kvm_migrate_prep($vm){
	my $fid = "[kvm_migrate_prep]";
	my $ffid = "KVM|MIGRATE|PREP";
	my $migrate = "";
	
	log_info($ffid, "meta migrate [$vm->{'meta'}{'migrate'}]");
	
	# migration enabled
	if($vm->{'meta'}{'migrate'}){
		log_info($ffid, "host [$vm->{'migrate'}{'host'}] port [$vm->{'migrate'}{'port'}] proto [$vm->{'migrate'}{'proto'}]");
		$migrate = " -incoming " . $vm->{'migrate'}{'proto'} . ":" . $vm->{'migrate'}{'host'} . ":" . $vm->{'migrate'}{'port'};
	}

	return $migrate;
}

#
# iso config [STRING]
#
sub kvm_iso_prep($vm){
	my $fid = "[kvm_boot_prep]";
	my $ffid = "KVM|BOOT|PREP";
	my $image = "";
	
	log_info($ffid, "boot [$vm->{'stor'}{'boot'}] iso [$vm->{'stor'}{'iso'}]");
	
	if($vm->{'stor'}{'iso'} ne ""){
		my $iso = $vm->{'stor'}{'iso'};
		my $boot = $vm->{'stor'}{'boot'};
		
		log_info($ffid, "iso [$iso] dev [$vm->{'stor'}{$iso}{'dev'}]");
		log_info($ffid, "iso [$iso] img [$vm->{'stor'}{$iso}{'image'}]");
		log_info($ffid, "iso [$iso] name [$vm->{'stor'}{$iso}{'name'}]");

		$image = "-cdrom " . $vm->{'stor'}{$iso}{'dev'} . $vm->{'stor'}{$iso}{'image'};
		
		# boot from iso
		if($boot eq $iso){
			log_info($ffid, "configure [$iso] as boot device");
			$image = $image . " -boot d";
		}
	}
	
	return $image;
}


1;
