#
# ETHER|AAPEN|LIBS - BASE|EXEC
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

our $VERSION     = 3.3.1;
our @ISA         = qw(Exporter);

#
# exec and return info [STRING]
#
sub execute($exec){
	my $fid = "[execute]";
	return '' unless defined $exec && $exec =~ /\S/;
	
	local $SIG{__WARN__} = sub {
		my $warning = shift;
		print "$fid WARNING: $warning";
	};
	
	my $result = eval { `$exec` };
	if($@) {
		print "$fid ERROR: Failed to execute command: $@\n";
		return '';
	}
	
	return $result // '';
}

#
# exec and return errors [STRING]
#
sub execute_reterr($exec){
	my $fid = "[execute_reterr]";
	return '' unless defined $exec && $exec =~ /\S/;
	
	local $SIG{__WARN__} = sub {
		my $warning = shift;
		print "$fid WARNING: $warning";
	};
	
	my $result = eval { `$exec 2>&1` };
	if($@) {
		print "$fid ERROR: Failed to execute command: $@\n";
		return '';
	}
	
	return $result // '';
}

#
# exec and supress errors [STRING]
#
sub execute_supresserr($exec){
	my $fid = "[execute_supresserr]";
	return '' unless defined $exec && $exec =~ /\S/;
	
	local $SIG{__WARN__} = sub {
		my $warning = shift;
		print "$fid WARNING: $warning";
	};
	
	my $result = eval { `$exec 2>/dev/null` };
	if($@) {
		print "$fid ERROR: Failed to execute command: $@\n";
		return '';
	}
	
	return $result // '';
}

#
# fork process [STRING]
#
sub forker($cmd){
	my $fid = "[forker]";
	return 0 unless defined $cmd && $cmd =~ /\S/;
	
	local $SIG{__WARN__} = sub {
		my $warning = shift;
		print "$fid WARNING: $warning";
	};
	
	my $pid = fork;
	if(!defined $pid) {
		print "$fid ERROR: Fork failed: $!\n";
		return 0;
	}
	
	if ($pid) {
		# Parent process
		wait;
		return $pid + 1;
	} else {
		# Child process
		eval {
			setpgrp;
			exec $cmd;
		};
		if($@) {
			print "$fid ERROR: exec failed: $@\n";
			exit 1;
		}
	}
	
	return 0; # Should never reach here
}

#
# kill pid [STRING]
#
sub killer($pid){
	my $fid = "[killer]";
	return '' unless defined $pid && $pid =~ /^\d+$/;
	
	local $SIG{__WARN__} = sub {
		my $warning = shift;
		print "$fid WARNING: $warning";
	};
	
	my $result = eval { `kill -15 $pid 2>&1` };
	if($@) {
		print "$fid ERROR: kill failed: $@\n";
		return '';
	}
	
	print "$fid status [$result]\n";
	return $result // '';
}

#
# kill pid [STRING]
#
sub killer_force($pid){
	my $fid = "[killer_force]";
	return '' unless defined $pid && $pid =~ /^\d+$/;
	
	local $SIG{__WARN__} = sub {
		my $warning = shift;
		print "$fid WARNING: $warning";
	};
	
	my $result = eval { `kill -9 $pid 2>&1` };
	if($@) {
		print "$fid ERROR: kill -9 failed: $@\n";
		return '';
	}
	
	print "$fid status [$result]\n";
	return $result // '';
}

#
# check for pid [BOOL]
#
sub pid_check($pid){
	my $fid = "[pid_check]";
	return 0 unless defined $pid && $pid =~ /^\d+$/;

	my $processes;
	eval {
		use Proc::ProcessTable;
		my $t = Proc::ProcessTable->new;
		unless (defined $t) {
			die "Failed to create ProcessTable object";
		}

		my $table = $t->table;
		unless (defined $table) {
			die "Failed to get process table";
		}

		# Create deep copy of process data before destroying table
		my @process_copy;
		foreach my $proc (@$table) {
			push @process_copy, {
				pid => $proc->pid ? $proc->pid+0 : 0,
				cmndline => defined $proc->cmndline ? "$proc->cmndline" : ''
			};
		}
		undef $t; # Explicitly destroy immediately
		\@process_copy;
	} or do {
		my $error = $@ || 'Unknown error';
		print "$fid ERROR: $error\n";
		return 0;
	};

	foreach my $p (@$processes) {
		next unless defined $p->{pid};
		if($p->{pid} == $pid) { # Numeric comparison
			print "$fid PID [$p->{pid}] EXEC [$p->{cmndline}]\n";
			return 1;
		}
	}
	
	return 0;
}

#
# find process and return pid [INT]
#
sub pid_find($string){
	my $fid = "[pid_find]";
	return 0 unless defined $string && length $string;

	my $processes;
	eval {
		use Proc::ProcessTable;
		my $t = Proc::ProcessTable->new;
		unless (defined $t) {
			die "Failed to create ProcessTable object";
		}

		my $table = $t->table;
		unless (defined $table) {
			die "Failed to get process table";
		}

		# Create deep copy of process data before destroying table
		my @process_copy;
		foreach my $proc (@$table) {
			push @process_copy, {
				pid => $proc->pid ? $proc->pid+0 : 0,
				cmndline => defined $proc->cmndline ? "$proc->cmndline" : ''
			};
		}
		undef $t; # Explicitly destroy immediately
		\@process_copy;
	} or do {
		my $error = $@ || 'Unknown error';
		print "$fid ERROR: $error\n";
		return 0;
	};

	foreach my $p (@$processes) {
		next unless defined $p->{pid} && defined $p->{cmndline};
		if($p->{cmndline} =~ $string) {
			print "$fid PID [$p->{pid}] EXEC [$p->{cmndline}]\n";
			return $p->{pid}+0; # Ensure numeric return
		}
	}
	
	return 0;
}

#
# return cpu usage for pid[STRING]
#
sub process_stats_cpu($pid){
        my $cpustat = `ps -p $pid -o %cpu= 2>&1`;
        return $cpustat ? string_clean($cpustat) : "n/a";
}     

#
# return mem usage for pid [STRING]
#
sub process_stats_mem($pid){
	my $memstat = `ps -p $pid -o %mem= 2>&1`;
	return $memstat ? string_clean($memstat) : "n/a";
}

#
# return rss for pid [STRING]
#
sub process_stats_rss($pid){
	my $rssexec = `ps -p $pid -o rss= 2>&1`;

	if($rssexec && looks_like_number($rssexec)){
		return format_bytes(($rssexec * 1024));
	} 
	else{
		return "n/a";
	}
}

1;
