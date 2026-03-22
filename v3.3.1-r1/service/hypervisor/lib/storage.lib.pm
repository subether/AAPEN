#
# ETHER|AAPEN|HYPERVISOR - LIB|STORAGE
#
# Licensed under AGPLv3+
# (c) 2010-2025 | ETHER.NO
# Author: Frode Moseng Monsson
# Contact: aapen@ether.no
# Version: 3.3.1
#


use strict;
use warnings;
use experimental 'signatures';


#
# expand existing storage dev [JSON-OBJ]
#
sub hyper_system_storage_expand($system, $dev){
	my $fid = "[system_storage_expand]";
	my $ffid = "SYSTEM|STORAGE|EXPAND";
	my $result;

	print "[" . date_get() . "] $fid checking pools\n";
	my $pool_check = hyper_storage_pool_check($system);
	
	if($pool_check->{'proto'}{'result'} eq "1"){

		if(file_check($system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'})){
			
			my $image_validate = system_storage_image_validate($system);
		
			if($image_validate->{'proto'}{'result'} eq "1"){
				
				my $image_grow = system_storage_image_grow($system, $dev);
				
				log_info($ffid, "storage expand result:", $image_grow);
				
				if($image_grow->{'proto'}{'result'} eq "1"){
					# image expand successful
					$result = packet_build_noencode("1", "success: system image expand successfully", $fid);
					$result->{'image_grow'} = $image_grow;
				}
				else{
					# image expand failed
					$result = packet_build_noencode("0", "error: image expand failed", $fid);
					$result->{'image_grow'} = $image_grow;
				}
			}
			else{
				# unsupported image type
				$result = packet_build_noencode("0", "error: unsupported image types", $fid);
				$result->{'image_validate'} = $image_validate;
			}
		}
		else{
			# device image does not exist
			log_warn($ffid, "device image [$system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'}] does not exist!");
			$result = packet_build_noencode("0", "failed: device image does not exist", $fid);
		}
	}
	else{
		# pool requirements failed
		log_warn_json($ffid, "pool requirements failed", $pool_check);
		$result = packet_build_noencode("0", "failed: pool requirements failed", $fid);
		$result->{'pool_check'} = $pool_check;
	}
	
	return $result;
}

#
# add storage device to existing system [JSON-OBJ]
#
sub hyper_system_storage_add($system, $dev){
	my $fid = "[system_storage_add]";
	my $ffid = "SYSTEM|STORAGE|ADD";
	my $result;
	
	log_info($ffid, "checking pools");
	my $pool_check = hyper_storage_pool_check($system);
	
	if($pool_check->{'proto'}{'result'} eq "1"){

		if(!file_check($system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'})){
			$result = packet_build_noencode("1", "success: system images are unique", $fid);
			
			# generate directories
			my $dir_create = system_storage_dir_create($system);
		
			if($dir_create->{'proto'}{'result'} eq "1"){
				
				# verify image types
				my $image_validate = system_storage_image_validate($system);
			
				if($image_validate->{'proto'}{'result'} eq "1"){
					
					# create qcow2 file
					my $image_create = system_image_qcow2_create($system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'}, $system->{'stor'}{$dev}{'size'});
					
					log_info_json($ffid, "image creation result", $image_create);
					
					if($image_create->{'proto'}{'result'} eq "1"){
						# image creation successful
						$result = packet_build_noencode("1", "success: system image created successfully", $fid);
						$result->{'image_create'} = $image_create;
					}
					else{
						# image creation failed
						$result = packet_build_noencode("0", "error: image creation failed", $fid);
						$result->{'image_create'} = $image_create;
					}
				}
				else{
					# unsupported image type
					log_warn_json($ffid, "unsupported image type", $image_validate);
					$result = packet_build_noencode("0", "error: unsupported image type", $fid);
					$result->{'image_validate'} = $image_validate;
				}
			}
			else{
				# failed to create dir
				log_warn($ffid, "failed to create required dir [$dir_create]");
				$result = packet_build_noencode("0", "error: failed to create required dir", $fid);
				$result->{'dir_result'} = $dir_create;
			}
		}
		else{
			# system image already exists
			log_warn($ffid, "system image [$system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'}] already exists!");
			$result = packet_build_noencode("0", "failed: system image already exists!", $fid);
		}
	}
	else{
		# pool requirements failed
		log_warn_json($ffid, "pool requirements failed", $pool_check);
		$result = packet_build_noencode("0", "failed: pool requirements failed", $fid);
		$result->{'pool_check'} = $pool_check;
	}
	
	return $result;
}

#
# create new system [JSON-OBJ]
#
sub hyper_system_storage_create($system){
	my $fid = "[system_storage_create]";
	my $ffid = "SYSTEM|STORAGE|CREATE";
	my $result;
	
	print "[" . date_get() . "] $fid checking pools\n";
	my $pool_check = hyper_storage_pool_check($system);
	
	if($pool_check->{'proto'}{'result'} eq "1"){

		# check if files already exists
		my $file_check = system_storage_file_check($system);

		if($file_check->{'proto'}{'result'} eq "1"){
			$result = packet_build_noencode("1", "success: system images are unique", $fid);
			
			# generate directories
			my $dir_create = system_storage_dir_create($system);
		
			if($dir_create->{'proto'}{'result'} eq "1"){
				
				# verify image types
				my $image_validate = system_storage_image_validate($system);
			
				if($image_validate->{'proto'}{'result'} eq "1"){
					
					my $image_create = system_storage_image_create($system);
					
					log_info_json($ffid, "image creation result", $image_create);
					
					if($image_create->{'proto'}{'result'} eq "1"){
						# image creation successful
						$result = packet_build_noencode("1", "success: system image created successfully", $fid);
						$result->{'image_create'} = $image_create;
					}
					else{
						# image creation failed
						$result = packet_build_noencode("0", "error: image creation failed", $fid);
						$result->{'image_create'} = $image_create;
					}

				}
				else{
					# unsupported image type
					log_warn_json($ffid, "unsupported image type", $image_validate);
					$result = packet_build_noencode("0", "error: unsupported image type", $fid);
					$result->{'image_validate'} = $image_validate;
				}
			}
			else{
				# failed to create dir
				log_warn_json($ffid, "failed to create required directories", $dir_create);
				$result = packet_build_noencode("0", "error: failed to create required dir", $fid);
				$result->{'dir_result'} = $dir_create;
			}
		}
		else{
			# system image already exists
			log_warn_json($ffid, "system file checks failed", $file_check);
			$result = packet_build_noencode("0", "failed: system images already exists!", $fid);
			$result->{'file_check'} = $file_check;
		}
	}
	else{
		# pool requirements failed
		log_warn_json($ffid, "pool requirements failed", $pool_check);
		$result = packet_build_noencode("0", "failed: pool requirements failed", $fid);
		$result->{'pool_check'} = $pool_check;
	}
	
	return $result;
}

#
# ensure all storage types are valid [JSON-OBJ]
#
sub system_storage_image_validate($system){
	my $fid = "[system_storage_image_validate]";
	my $ffid = "SYSTEM|STORAGE|IMAGE|VALIDATE";
	my @stor_index = index_split($system->{'stor'}{'disk'});
	
	foreach my $dev (@stor_index){
		print "[" . date_get() . "] $fid type [$system->{'stor'}{$dev}{'type'}]\n";
	
		if($system->{'stor'}{$dev}{'type'} ne "qcow2"){
			print "[" . date_get() . "] $fid image type is not supported!\n";
			return packet_build_noencode("0", "failed: unsupported image type [$system->{'stor'}{$dev}{'type'}]", $fid);
		}
	}

	return packet_build_noencode("1", "success: all storage types are supported", $fid);
}

#
# expand qcow2 [JSON-OBJ]
#
sub system_storage_image_grow($system, $dev){
	my $fid = "[system_storage_image_grow]";
	my $ffid = "SYSTEM|STORAGE|IMAGE|GROW";
	my $result;
	my $dev_result;
	
	# suport more types in the future..
	if($system->{'stor'}{$dev}{'type'} eq "qcow2"){
		$dev_result = system_image_qcow2_grow($system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'}, $system->{'stor'}{$dev}{'size'});
		
		if($dev_result->{'proto'}{'result'} eq "1"){
			# image expand successful
			$result = packet_build_noencode("1", "success: image grow succeeded", $fid);
			$result->{'dev_result'} = $dev_result;
		}
		else{
			# image expand failed
			$result = packet_build_noencode("0", "failed: image grow failed", $fid);
			$result->{'dev_result'} = $dev_result;
		}
	}
	
	return $result;
}

#
# create system image [JSON-OBJ]
#
sub system_storage_image_create($system){
	my $fid = "[system_storage_image_create]";
	my $ffid = "SYSTEM|STORAGE|IMAGE|CREATE";
	my $result;
	my $dev_result;
	
	my @stor_index = index_split($system->{'stor'}{'disk'});
	
	foreach my $dev (@stor_index){	
	
		# process qcow2 images
		if($system->{'stor'}{$dev}{'type'} eq "qcow2"){
			$dev_result->{$dev} = system_image_qcow2_create($system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'}, $system->{'stor'}{$dev}{'size'});
			
			if($dev_result->{$dev}{'proto'}{'result'} eq "1"){
				# image creation successful
				$result = packet_build_noencode("1", "success: image creation succeeded", $fid);
				$result->{'dev_result'} = $dev_result;
			}
			else{
				# image creation failed
				$result = packet_build_noencode("0", "failed: image creation failed", $fid);
				$result->{'dev_result'} = $dev_result;
			}
		}
		
		# future image support - TODO..
	}
	
	return $result;
}

#
# create qcow2 image [JSON-OBJ]
#
sub system_image_qcow2_create($image, $size){
	my $fid = "[system_image_qcow2_create]";
	my $ffid = "SYSTEM|STORAGE|QCOW2|CREATE";
	my $result;
	
	my $exec = "qemu-img create -f qcow2 " . $image . " " . $size . "G";
	#print "[" . date_get() . "] $fid exec [$exec]\n";#
	log_debug($fid, "exec [$exec]");
	
	my $create_result = execute_reterr($exec);
	
	if($create_result =~ "Formatting "){
		# sucessfully created qcow2 image
		log_info($ffid, "success: image [$image] created successfully");
		$result = packet_build_noencode("1", "success: image created successfully", $fid);
		
	}
	else{
		# failed to create qcow2 image
		log_warn($ffid, "failed: image [$image] creation failed [$create_result]");
		$result = packet_build_noencode("0", "failed: image creation failed", $fid);
		$result->{'image_result'} = $create_result;
	}
	
	return $result;
}

#
# expand qcow2 [JSON-OBJ]
#
sub system_image_qcow2_grow($image, $size){
	my $fid = "[system_image_qcow2_grow]";
	my $ffid = "SYSTEM|STORAGE|QCOW2|GROW";
	my $result;
	
	my $exec = "qemu-img resize " . $image . " " . $size . "G";
	log_debug($fid, "exec [$exec]");
	
	my $create_result = execute_reterr($exec);
	
	if($create_result =~ "Image resized."){
		log_info($ffid, "success: image [$image] resized successfully");
		$result = packet_build_noencode("1", "success: image expanded successfully", $fid);
		
	}
	else{
		log_warn($ffid, "failed: image [$image] resize failed [$create_result]");
		$result = packet_build_noencode("0", "failed: image expansion failed", $fid);
		$result->{'image_result'} = $create_result;
	}
	
	return $result;
}

#
# create storage dir [JSON-OBJ]
#
sub system_storage_dir_create($system){
	my $fid = "[system_storage_dir_create]";
	my $ffid = "SYSTEM|STORAGE|DIR|CREATE";
	
	my @stor_index = index_split($system->{'stor'}{'disk'});
	
	foreach my $dev (@stor_index){
		
		if(!dir_check($system->{'stor'}{$dev}{'dev'})){
			log_info($ffid, "directory [$system->{'stor'}{$dev}{'dev'}] does not exist. creating it");
			my $exec = "mkdir -p " . $system->{'stor'}{$dev}{'dev'};
			log_debug($fid, "exec [$exec]");
			my $exec_result = execute_reterr($exec);
			
			if($exec_result){
				# failed to create directory
				my $result = packet_build_noencode("0", "failed: directory creation failed", $fid);
				$result->{'dir_create'} = $exec_result;		
				return $result;
			}
		}
	}
	
	return packet_build_noencode("1", "success: all directories exist or were created", $fid);;
}

#
# verify storage files [JSON-OBJ]
#
sub system_storage_file_check($system){
	my $fid = "[system_storage_file_check]";
	my $ffid = "SYSTEM|STORAGE|FILE|CHECK";
	my $success = 1;

	my @stor_index = index_split($system->{'stor'}{'disk'});

	foreach my $dev (@stor_index){
		
		if(defined $system->{'stor'}{$dev}{'image'} && defined $system->{'stor'}{$dev}{'dev'}){
			
			if(file_check($system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'})){
				# image already exists
				return packet_build_noencode("0", "$fid storage image [$system->{'stor'}{$dev}{'image'}] already exists!", $fid);
			}
		}
		else{
			# image or device not configured
			return packet_build_noencode("0", "$fid storage image or device not configured", $fid);
		}
	}
	
	return packet_build_noencode("1", "$fid all system storage images are unique", $fid);
}

#
# verify storage files [JSON-OBJ] 
#
sub system_storage_file_check_exist($system){
	my $fid = "[system_storage_file_check]";
	my $ffid = "SYSTEM|STORAGE|FILE|CHECK";
	my $success = 1;

	my @stor_index = index_split($system->{'stor'}{'disk'});

	foreach my $dev (@stor_index){
		
		if(defined $system->{'stor'}{$dev}{'image'} && defined $system->{'stor'}{$dev}{'dev'}){
			
			if(!file_check($system->{'stor'}{$dev}{'dev'} . $system->{'stor'}{$dev}{'image'})){
				return packet_build_noencode("0", "$fid storage image [$system->{'stor'}{$dev}{'image'}] does not exist!", $fid);
			}
		}
		else{
			# storage image or device not configured
			return packet_build_noencode("0", "$fid storage image or device not configured", $fid);
		}
	}
	
	return packet_build_noencode("1", "$fid all system storage images found", $fid);
}

#
# check and validate storage pool [JSON-OBJ]
#
sub hyper_storage_pool_check($vm){
	my $fid = "[hyper_storage_pool_check]";
	my $ffid = "SYSTEM|STORAGE|POOL|CHECK";
	my $success = 1;
	my $result;
	
	# check disks
	my @disks = index_split($vm->{'stor'}{'disk'});
	
	foreach my $disk (@disks){
		log_info($ffid, "processing disk [$disk] for vm [$vm->{'id'}{'name'}]");
		#print "[" . date_get() . "] $fid disk [$disk]\n";
	
		if($vm->{'stor'}{$disk}{'backing'} eq "pool"){
			# storage pool mode

			log_info($ffid, "pool [$vm->{'stor'}{$disk}{'pool'}{'name'}]");
			my $pool = $vm->{'stor'}{$disk}{'pool'}{'name'};
			
			my $pool_result = api_storage_local_pool_get(env_serv_sock_get("storage"), $pool);
			
			if($pool_result->{'proto'}{'result'} eq "1"){
				log_info($ffid, "disk [$disk] pool [$pool] available");
				
				# check if metadata available
				if($pool_result->{'poolmeta'}{'state'} eq "1" && $pool_result->{'poolmeta'}{'mounted'} eq "1"){
					
					# check if storage reqs satisfied
					if($pool_result->{'poolmeta'}{'size'}{'avail'}{'gb'} > $vm->{'stor'}{$disk}{'size'}){
						# pool is available and ready
						log_info($ffid, "pool [$pool] for disk [$disk] is available and ready");
						$result =  packet_build_noencode("1", "success: pool for disk [$disk] availble and ready", $fid);
						$result->{'pool_result'} = $pool_result->{'proto'};
					}
					else{
						# pool has insufficient space
						log_warn($ffid, "pool for disk [$disk] has insufficient space. requested [$vm->{'stor'}{$disk}{'size'}]. available [$pool_result->{'poolmeta'}{'size'}{'avail'}{'gb'}]");
						$result =  packet_build_noencode("0", "failed: pool for disk [$disk] has insufficient space", $fid);
						$success = 0;
					}
				}
				else{
					# pool not online
					log_warn_json($ffid, "checks for [$disk] pool [$pool] failed. pool not online", $pool_result->{'poolmeta'});
					$result =  packet_build_noencode("0", "failed: pool for disk [$disk] not online", $fid);
					$result->{'pool_state'} = $pool_result->{'poolmeta'};
					$success = 0;
				}			
			}
			else{
				# pool not available
				log_warn_json($ffid, "checks for [$disk] pool [$pool] failed. pool not available", $pool_result);
				$result =  packet_build_noencode("0", "error: pool for disk [$disk] not availble", $fid);
				$result->{'pool_result'}{$disk} = $pool_result;
				$success = 0;
			}
		}
		else{
			# static backing
			log_info($ffid, "storage is statically configured. deferring checks.");
		}	
	}

	# check result
	if($success){
		$result =  packet_build_noencode("1", "success: all storage pools available", $fid);
	}
	
	return $result;
}

#
# pre cloning sanity checks [JSON-OBJ]
#
sub system_stoarge_clone_checks($src_system, $dst_system){
	my $fid = "[system_storage_clone_checks]";
	my $ffid = "SYSTEM|STORAGE|CLONE|CHECKS";
	my $result;
	
	my $src_pool_check = hyper_storage_pool_check($src_system);
	
	if($src_pool_check->{'proto'}{'result'} eq "1"){

		# check if source system files exists
		my $src_file_check = system_storage_file_check_exist($src_system);

		if($src_file_check->{'proto'}{'result'} eq "1"){
			
			#
			# DESTINATION SYSTEM
			#
			my $dst_pool_check = hyper_storage_pool_check($dst_system);
	
			if($dst_pool_check->{'proto'}{'result'} eq "1"){
				
				my $dst_file_check = system_storage_file_check($dst_system);
				
				if($dst_file_check->{'proto'}{'result'} eq "1"){
					# pool checks successful
					$result = packet_build_noencode("1", "success: all checks successful", $fid);					
				}
				else{
					# destination image exists
					$result = packet_build_noencode("0", "failed: dest system images exists", $fid);
					$result->{'dst_file_check'} = $dst_file_check;
				}
			}
			else{
				# dest pool requirements failed
				$result = packet_build_noencode("0", "failed: dest pool requirements failed", $fid);
				$result->{'dst_pool_check'} = $dst_pool_check;
			}
		}
		else{
			# source image not found
			$result = packet_build_noencode("0", "failed: source system images not found", $fid);
			$result->{'src_file_check'} = $src_file_check;
		}
	}
	else{
		# pool requirements failed
		$result = packet_build_noencode("0", "failed: source pool requirements failed", $fid);
		$result->{'src_pool_check'} = $src_pool_check;
	}
	
	return $result;
}

1;
