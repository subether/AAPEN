#
# ETHER|AAPEN|AGENT - MAIN
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
use JSON::MaybeXS;
use TryCatch;
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Async::SSLStream;
use IO::Async::Timer::Periodic;
use Sys::Hostname;

# root
my $root;
BEGIN { 
	$root = `/bin/cat ../../env/root.cfg | tr -d '\n'`;
	print "[init] root [$root]\n";
};
use lib $root . "lib/";

use aapen::base::log;
use aapen::base::envthr;
use aapen::base::date;
use aapen::base::json;
use aapen::base::file;
use aapen::base::index;
use aapen::base::exec;
use aapen::base::config;

use aapen::proto::socket;
use aapen::proto::packet;
use aapen::proto::protocol;
use aapen::proto::ssl;

use aapen::api::cluster::local;

require './lib/protocol.pm';

my $fid = "[agent]";
my $ffid = "SERVER";
my $s_id = 0;
my $version = "v3.3.1";
env_init();
env_version_set($version);
env_sid_set("agent");

# init config
my $config = config_init();

log_info($ffid, "SSL CA [" . config_base_ssl_ca_get() . "]");
log_info($ffid, "SSL CERT [" . config_base_ssl_cert_get() . "]");
log_info($ffid, "SSL KEY [" . config_base_ssl_key_get() . "]");

# Session state manager
my %sessions;
my $MAX_SESSIONS = 5;
my $SESSION_TIMEOUT = 30; # seconds


#
# init flags
#
foreach my $flags (@ARGV){
	if($flags eq "verbose"){ env_verbose_on() };
	if($flags eq "info"){ env_info_on() };
	if($flags eq "debug"){ env_debug_on() };
	if($flags eq "silent"){ env_silent_on() };
	if($flags eq "daemon"){ env_daemon_on() };
}

# Helper function to create new session
sub _create_session($stream) {
	my $sid = ++$s_id;
	$sessions{$sid} = {
		stream => $stream,
		data => '',
		created => time(),
		last_active => time(),
		bytes_received => 0,
		packets_processed => 0
	};
	return $sid;
}

# Helper function to update session activity
sub _update_session_activity($sid) {
	if (exists $sessions{$sid}) {
		$sessions{$sid}{last_active} = time();
	}
}

# Helper function to cleanup stale sessions
sub _cleanup_stale_sessions() {
	my $now = time();
	my $cleaned = 0;
	
	for my $sid (keys %sessions) {
		if ($now - $sessions{$sid}{last_active} > $SESSION_TIMEOUT) {
			if ($sessions{$sid}{stream}) {
				$sessions{$sid}{stream}->close;
			}
			delete $sessions{$sid};
			log_warn($ffid, "cleaned up stale session [$sid]");
			$cleaned++;
		}
	}
	
	return $cleaned;
}

# Configure event loop
my $loop = IO::Async::Loop->new(
    max_connections => $MAX_SESSIONS,
    idle_timeout    => 60,
);

# Session cleanup timer
$loop->add(
    IO::Async::Timer::Periodic->new(
        interval => 10,
        first_interval => 10,
        notifier_name => 'session_cleanup',
        on_tick => sub {
            my $cleaned = _cleanup_stale_sessions();
            if ($cleaned > 0) {
                log_info($ffid, "session cleanup: removed $cleaned stale sessions");
            }
        }
    )
);

# Initialize SSL server
my $server = $loop->SSL_listen(
	host     => $config->{'node'}{'agent'}{'address'},
	socktype => 'stream',
	service  => $config->{'base'}{'ports'}{'agent'}{'port'},

	# ssl cetificates
	SSL_ca_file => config_base_ssl_ca_get(),
	SSL_key_file  => config_base_ssl_key_get(),
	SSL_cert_file => config_base_ssl_cert_get(),
	SSL_verify_mode => SSL_VERIFY_NONE,

	# stream handler
	on_stream => sub ($stream) {
		# Create new session using helper
		my $sid = _create_session($stream);

		$stream->configure(
			on_read => sub ($self, $buffer, $eof) {
				# Update session activity
				_update_session_activity($sid);
				$sessions{$sid}{bytes_received} += length($$buffer);

				my $end = 0;
				
				# only handle completed lines
				while( $$buffer =~ s/^(.*\n)// ) {
					
					$sessions{$sid}{data} .= $1;
					$sessions{$sid}{data} =~ s/\R//g;

					# process data
					my $result = process_ssl($sessions{$sid}{data}, $self, $sid);
					log_info($ffid, "session [$sid] result [$result]");

					$end = 1;
					$sessions{$sid}{data} = "";
					$sessions{$sid}{packets_processed}++;
					$self->close;
				}
				
				if(!$end){
					log_debug($ffid, "session [$sid] jumbo packet");
					$sessions{$sid}{packets_processed}++;
					$sessions{$sid}{data} .= $$buffer;
				}
				
				$$buffer = '';
				return 0;
			},

			on_closed => sub {
				if (exists $sessions{$sid}) {
					my $duration = time() - $sessions{$sid}{created};
					log_info($ffid, "session [$sid] closed after [$duration] sec, processed [$sessions{$sid}{packets_processed}] packets, received [$sessions{$sid}{bytes_received}] bytes");
					delete $sessions{$sid};
				}
			},
		);
		
		$loop->add( $stream );
	},

	# error handler
	on_ssl_error     => sub { 
		log_warn($ffid, "session [$s_id] error: cannot negotiate SSL - $_[-1]");
	},
	on_resolve_error => sub {
		log_fatal($ffid, "session [$s_id] error: cannot resolve - $_[1]"); 
	},
	on_listen_error  => sub { 
		log_fatal($ffid, "session [$s_id] error: Cannot listen - $_[1]")
	},
	
	# listener
	on_listen => sub ($s) {
		log_info("$ffid", "version [" . $version ."] listening on [" . $s->sockhost . '] port [' . $s->sockport . "]");
	},
	
);

# run loop
$loop->run;
