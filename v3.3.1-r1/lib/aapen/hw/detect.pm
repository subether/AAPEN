#
# ETHER|AAPEN|LIBS - HW|DETECT
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
use Exporter::Auto;
use Term::ANSIColor qw(:constants);
use JSON::MaybeXS;
use Sys::Hostname;
use Linux::Cpuinfo;
use Linux::MemInfo;
use Sys::Load qw/getload uptime/;
use Proc::ProcessTable;

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);


#
# detect hardware [JSON-OBJ]
#
sub hw_detect_new(){
	my $db;
	my $fid = "[hw_detect]";
	
	my ($cores, $socket, $speed, $type, $arch) = hw_cpu_info();
	my $kvm = hw_kvm_info($type);
	my $kvmstat = hw_kvm_stat($kvm);
	my $ram = hw_mem_info();
	my $numa = hw_numa_info();
	my $top = hw_top_stats();
	
	# save configuration
	$db->{'cpu'}{'type'} = $type;
	$db->{'cpu'}{'speed'} = $speed;
	$db->{'cpu'}{'arch'} = $arch;
	$db->{'cpu'}{'core'} = $cores;
	$db->{'cpu'}{'sock'} = $socket;
	$db->{'cpu'}{'kvm'} = $kvm;
	$db->{'cpu'}{'kvmstate'} = $kvmstat;
	$db->{'mem'}{'mb'} = $ram;
	$db->{'numa'} = $numa->{'numa'};
	$db->{'stats'} = $top;
	
	return $db;
}

#
# detect hardware brief format [JSON-OBJ]
#
sub hw_detect_brief(){
	my $db;
	my $fid = "[hw_detect]";
	
	my $top = hw_top_stats_brief();
	my $cpuinfo = Linux::Cpuinfo->new();
	my $arch = hw_cpu_arch();
	
	if($arch eq "aarch64"){
		$db->{'cpu'}{'type'} = $arch;
	}
	else{
		$db->{'cpu'}{'type'} = $cpuinfo->model_name();
	}
	
	$db->{'cpu'}{'type'} = $cpuinfo->model_name();
	$db->{'cpu'}{'core'} = $cpuinfo->num_cpus();
	$db->{'cpu'}{'arch'} = $arch;
	$db->{'stats'} = $top;
	
	return $db;
}

#
# top stats [JKSON-OBJ]
#
sub hw_top_stats(){
	my $fid = "[hw_top_stats]";
	my $top = {};

	# uptime
	my $seconds = int uptime();
	my @parts = gmtime($seconds);
	$top->{'uptime'} = $parts[7] . " day, " . $parts[2] . " hrs, " . $parts[1] . " min, " . $parts[0] . " sec";
	
	# load
	$top->{'load'}{'1'} = (getload())[0];
	$top->{'load'}{'5'} = (getload())[1];
	$top->{'load'}{'15'} = (getload())[2];

	$top->{'tasks'} = hw_process_stats();
	#$top->{'tasks'} = hw_process_stats_statsgrab();
		
	$top->{'cpu'} = hw_cpu_stats();
	$top->{'mem'} = hw_mem_stats_meminfo();

	return $top;
}

#
# top stats brief format [JSON-OBJ]
#
sub hw_top_stats_brief(){
	my $fid = "[hw_top_stats]";
	my $top = {};

	my $seconds = int uptime();
	my @parts = gmtime($seconds);
	$top->{'uptime'} = $parts[7] . " day, " . $parts[2] . " hrs, " . $parts[1] . " min, " . $parts[0] . " sec";

	# load
	$top->{'load'}{'1'} = (getload())[0];
	$top->{'load'}{'5'} = (getload())[1];
	$top->{'load'}{'15'} = (getload())[2];

	$top->{'cpu'} = hw_cpu_stats();
	$top->{'mem'} = hw_mem_stats_meminfo();
	
	return $top;
}


#
# detect hardware
#
sub hw_detect($db){
	my $fid = "[hw_detect]";
	
	print "\n[detecting hardware]\n";
	my ($cores, $socket, $speed, $type, $arch) = hw_cpu_info();
	my $kvm = hw_kvm_info($type);
	my $kvmstat = hw_kvm_stat($kvm);
	my $ram = hw_mem_info();
	
	my $numa = hw_numa_info();
	
	# save configuration
	$db->{'hw'}{'cpu'}{'type'} = $type;
	$db->{'hw'}{'cpu'}{'speed'} = $speed;
	$db->{'hw'}{'cpu'}{'arch'} = $arch;
	$db->{'hw'}{'cpu'}{'core'} = $cores;
	$db->{'hw'}{'cpu'}{'sock'} = $socket;
	$db->{'hw'}{'cpu'}{'kvm'} = $kvm;
	$db->{'hw'}{'cpu'}{'kvmstate'} = $kvmstat;
	$db->{'hw'}{'mem'}{'mb'} = $ram;
	$db->{'hw'}{'numa'} = $numa->{'numa'};
	print "\n";
	
	return $db;
}

#
# detect cpu [STRING]
#
sub hw_cpu_info(){
	my $fid = "[gathering cpu info]";

	# cpuinfo
	my ($cores, $speed, $type, $arch, $socket);
	my $cpuinfo = Linux::Cpuinfo->new();
 	$cores = $cpuinfo->num_cpus();
  	$speed = $cpuinfo->cpu_mhz();
  	$type = $cpuinfo->model_name();

	# sockets
	$socket = execute('grep -i "physical id" /proc/cpuinfo | sort -u | wc -l');  
	chomp($socket); 

	# arch
	$arch = hw_cpu_arch();
  
	if(env_debug()){
		print "[cpu] type [$type], arch [$arch]\n";	
		print "[cpu] sockets [$socket], cores [$cores], speed [$speed] MHz\n";
	}

	return ($cores, $socket, $speed, $type, $arch);
}

#
# cpu arch [STRING]
#
sub hw_cpu_arch(){
	my $fid = "[hw_cpu_arch]";
  	my $arch = execute("uname -m");
	chomp($arch); 
	return $arch;
}

#
# detect cpu [JSON-OBJ]
#
sub hw_cpu_info_brief(){
	my $fid = "[gathering cpu info]";

	# cpuinfo
	my ($cores, $speed, $type, $arch, $socket);
	my $cpuinfo = Linux::Cpuinfo->new();
 	$cores = $cpuinfo->num_cpus();
  	$speed = $cpuinfo->cpu_mhz();
  	$type = $cpuinfo->model_name();
  	
	return ($cores, $socket, $speed, $type, $arch);
}

#
# detect kvm arch [STRING]
#
sub hw_kvm_info($type){
	my $fid = "[kvm info]";	
	my $kvm = 0;

	# check for Intel
	if($type =~ "Intel"){
		if(env_debug()){ print "$fid cpu vendor [Intel]"; };
		
		# Intel kvm extensions
		if(execute("grep -e vmx /proc/cpuinfo")){
			$kvm = "kvm_intel";
			if(env_debug()){ print "hardware kvm [$kvm] detected.\n" };
		}
	}
	elsif($type =~ "AMD"){
		if(env_verbose()){ print "$fid cpu vendor [AMD]"; };
		
		# AMD kvm extensions
		if(execute("grep -e svm /proc/cpuinfo")){
			$kvm = "kvm_amd";
			if(env_debug()){ print ", hardware kvm [$kvm] detected.\n" };
		}
	}
	elsif($type =~ "QEMU"){
		if(env_debug()){ print "$fid cpu vendor [QEMU], "; };
	}	
	else{
		if(env_debug()){ print "$fid cpu vendor [$type] unknown,"; };
	}

	if(!$kvm){
		if(env_debug()){ print "no hardware virtualization extensions detected.\n"; };
	}

	return $kvm;
}

#
# detect kvm status [BOOLEAN]
#
sub hw_kvm_stat($kvm){
	my $fid = "[kvm state]";
	my $status;
	
	# check if module is loaded
	my $kvmstat = execute("lsmod | grep $kvm");  
	chomp($kvmstat); 

	if($kvmstat){
		if(env_debug()){ print "$fid kvm [$kvm] loaded.\n"; };
		$status = 1;
	}
	else{
		if(env_debug()){ print "$fid kvm [$kvm] not loaded.\n"; };
		$status = 0;
	}

	return $status;
}

#
# detect memory [FLOAT]
#
sub hw_mem_info(){
	my $fid = "[memory]";
	my %mem = get_mem_info; 
	my $tot = $mem{"MemTotal"};
	my $size = sprintf("%.0f", ($tot / 1000 ));
	return $size;
}

#
# Get NUMA information [JSON-OBJ]
#
sub hw_numa_info(){
    my $fid = "[hw_numa_info]";
    my $numajson = {'numa' => {}};
    
    # Try with timeout and retries
    my $max_retries = 3;
    my $retry_delay = 1;
    my $attempt = 0;
    my $success = 0;
    my @numa_output;

    while ($attempt < $max_retries && !$success) {
        $attempt++;
        
        eval {
            # Set timeout
            local $SIG{ALRM} = sub { die "Timeout getting NUMA info\n" };
            alarm(5);
            
            my $result = `numactl -H 2>&1`;
            @numa_output = split /\n/, $result;
            
            unless (@numa_output && $numa_output[0] =~ /available:/) {
                die "Invalid NUMA output format\n";
            }
            
            $success = 1;
            alarm(0);
        };
        
        if ($@) {
            warn "$fid Attempt $attempt failed: $@";
            if ($attempt < $max_retries) {
                sleep $retry_delay;
                $retry_delay *= 2;
            }
        }
    }

    unless ($success) {
        warn "$fid Error: Failed to get NUMA info after $max_retries attempts\n";
        return $numajson;
    }

    # Parse NUMA info
    if ($numa_output[0] =~ /available:\s+(\d+)\s+nodes/) {
        $numajson->{'numa'}{'nodes'} = $1;
    }

    foreach my $line (@numa_output) {
        # Parse node cores
        if ($line =~ /node\s+(\d+)\s+cpus:\s+(.+)/) {
            my $node_id = $1;
            my @cores = grep { $_ ne '' } split(/\s+/, $2);
            
            $numajson->{'numa'}{'index'} = index_add($numajson->{'numa'}{'index'}, $node_id);
            $numajson->{'numa'}{$node_id}{'core'}{'num'} = scalar @cores;
            
            foreach my $core (@cores){
				$numajson->{'numa'}{$node_id}{'core'}{'index'} = index_add($numajson->{'numa'}{$node_id}{'core'}{'index'}, $core);
			}
        }
        # Parse node memory
        elsif ($line =~ /node\s+(\d+)\s+size:\s+(\d+)\s+MB/) {
            $numajson->{'numa'}{$1}{'mem'}{'tot'} = $2;
        }
        # Parse free memory
        elsif ($line =~ /node\s+(\d+)\s+free:\s+(\d+)\s+MB/) {
            $numajson->{'numa'}{$1}{'mem'}{'free'} = $2;
        }
    }

    if (env_debug()) {
        print "$fid NUMA info:\n";
        json_encode_pretty($numajson);
    }

    return $numajson;
}

#
# get cpu stats [JSON-OBJ]
#
sub hw_cpu_stats(){
    my $fid = "[hw_cpu_stats]";
    my $stats = {
        user => 0,
        nice => 0,
        system => 0,
        idle => 0,
        iowait => 0,
        irq => 0,
        softirq => 0,
        steal => 0
    };

    # Try with timeout and retries
    my $max_retries = 3;
    my $retry_delay = 1;
    my $attempt = 0;
    my $success = 0;
    my @mpstat_output;

    while ($attempt < $max_retries && !$success) {
        $attempt++;
        
        eval {
            # Set timeout
            local $SIG{ALRM} = sub { die "Timeout getting CPU stats\n" };
            alarm(5);
            
            my $result = `mpstat -o JSON 1 1 2>&1`;
            @mpstat_output = split /\n/, $result;
            
            unless (@mpstat_output && $mpstat_output[0] =~ /{/) {
                die "Invalid mpstat output format\n";
            }
            
            $success = 1;
            alarm(0);
        };
        
        if ($@) {
            warn "$fid Attempt $attempt failed: $@";
            if ($attempt < $max_retries) {
                sleep $retry_delay;
                $retry_delay *= 2;
            }
        }
    }

    unless ($success) {
        warn "$fid Error: Failed to get CPU stats after $max_retries attempts\n";
        return $stats;
    }

    # Parse JSON output
    my $mpstat_json = decode_json(join("\n", @mpstat_output));
    
    # Extract overall CPU stats
    if ($mpstat_json->{'sysstat'}->{'hosts'}[0]->{'statistics'}[0]->{'cpu-load'}[0]) {
        my $cpu = $mpstat_json->{'sysstat'}->{'hosts'}[0]->{'statistics'}[0]->{'cpu-load'}[0];
        $stats->{'user'} = $cpu->{'usr'} || 0;
        $stats->{'nice'} = $cpu->{'nice'} || 0;
        $stats->{'system'} = $cpu->{'sys'} || 0;
        $stats->{'idle'} = $cpu->{'idle'} || 0;
        $stats->{'iowait'} = $cpu->{'iowait'} || 0;
        $stats->{'wait'} = $cpu->{'iowait'} || 0;
        $stats->{'irq'} = $cpu->{'irq'} || 0;
        $stats->{'softirq'} = $cpu->{'soft'} || 0;
        $stats->{'steal'} = $cpu->{'steal'} || 0;
    }

    #if (env_debug()) {
    #    print "$fid CPU stats:\n";
    #    json_encode_pretty($stats);
    #}

    return $stats;
}

#
# Get memory statistics using Linux::MemInfo [JSON-OBJ]
#
# Returns same format as hw_mem_stats():
#   - total: Total memory in MB
#   - free: Free memory in MB  
#   - available: Available memory in MB
#   - buffers: Buffer memory in MB
#   - cached: Cached memory in MB
#   - swap_total: Total swap in MB
#   - swap_free: Free swap in MB
#   - swap_used: Used swap in MB
#
sub hw_mem_stats_meminfo(){
    my $fid = "[hw_mem_stats_meminfo]";
    my $stats = {
        total => 0,
        free => 0,
        available => 0,
        buffers => 0,
        cached => 0,
        swap_total => 0,
        swap_free => 0,
        swap_used => 0
    };

    eval {
        my %mem = get_mem_info;
        
        $stats->{unit} = "MB";
        $stats->{total} = sprintf("%.1f", $mem{MemTotal} / 1024);
        $stats->{free} = sprintf("%.1f", $mem{MemFree} / 1024);
        $stats->{available} = sprintf("%.1f", $mem{MemAvailable} / 1024);
        $stats->{buffers} = sprintf("%.1f", $mem{Buffers} / 1024);
        $stats->{cached} = sprintf("%.1f", $mem{Cached} / 1024);
        $stats->{cache} = sprintf("%.1f", $mem{Cached} / 1024);
        $stats->{used} = sprintf("%.1f", ($mem{MemTotal} - $mem{MemFree} - $mem{Buffers} - $mem{Cached}) / 1024);
        $stats->{swap_total} = sprintf("%.1f", $mem{SwapTotal} / 1024);
        $stats->{swap_free} = sprintf("%.1f", $mem{SwapFree} / 1024);
        $stats->{swap_used} = sprintf("%.1f", ($mem{SwapTotal} - $mem{SwapFree}) / 1024);
    };

    if ($@) {
        warn "$fid Error getting memory stats: $@";
    }

    if (env_debug()) {
        print "$fid Memory stats (Linux::MemInfo):\n";
        json_encode_pretty($stats);
    }

    return $stats;
}

#
# Get system uptime in formatted string [STRING]
#
sub hw_uptime_get(){
    my $fid = "[hw_uptime_get]";
    
    my $uptime_seconds = int uptime();
    
    my $days = int($uptime_seconds / 86400);
    my $hours = int(($uptime_seconds % 86400) / 3600);
    my $minutes = int(($uptime_seconds % 3600) / 60);
    my $seconds = $uptime_seconds % 60;
    
    my $formatted = sprintf("%d day%s, %d hour%s, %d minute%s, %d second%s",
        $days, $days != 1 ? 's' : '',
        $hours, $hours != 1 ? 's' : '',
        $minutes, $minutes != 1 ? 's' : '',
        $seconds, $seconds != 1 ? 's' : '');

    if (env_debug()) {
        print "$fid Uptime: $formatted\n";
    }

    return $formatted;
}

#
# Get process statistics using Proc::ProcessTable [JSON-OBJ]
#
sub hw_process_stats(){
    my $fid = "[hw_process_stats]";
    my $stats = {
        total => 0,
        running => 0,
        sleeping => 0,
        stopped => 0,
        zombie => 0
    };

    eval {
        my $pt = Proc::ProcessTable->new();
        foreach my $proc (@{$pt->table}) {
            $stats->{total}++;
            if ($proc->state eq 'R') {
                $stats->{running}++;
            } elsif ($proc->state eq 'S') {
                $stats->{sleeping}++;
            } elsif ($proc->state eq 'T') {
                $stats->{stopped}++;
            } elsif ($proc->state eq 'Z') {
                $stats->{zombie}++;
            }
        }
    };

    if ($@) {
        warn "$fid Error getting process stats: $@";
    }

    if (env_debug()) {
        print "$fid Process stats:\n";
        json_encode_pretty($stats);
    }

    return $stats;
}


1;
