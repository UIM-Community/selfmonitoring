use strict;
use warnings;
package perluim::tunnels;

sub new {
    my ($class,$o) = @_;
    my $this = {
        passive => $o->{"passive"},
        alive => $o->{"alive"},
        id => $o->{"id"},
        tid => $o->{"tid"},
        host => $o->{"host"},
        port => $o->{"port"},
        heartbeat => $o->{"heartbeat"},
        inactive_timeout => $o->{"inactive_timeout"},
        domain => $o->{"domain"},
        hub => $o->{"hub"},
        hubport => $o->{"hubport"},
        started => $o->{"started"},
        last => $o->{"last"},
        connections_outer => $o->{"connections_outer"},
        connections => $o->{"connections"},
        session_cnt => $o->{"session_cnt"},
        active_sessions_config => $o->{"active_sessions_config"},
        passive_sessions_config => $o->{"passive_sessions_config"},
        active_sessions_inuse => $o->{"active_sessions_inuse"},
        passive_sessions_inuse => $o->{"lapassive_sessions_inusest"},
        active_sessions_avail => $o->{"active_sessions_avail"},
        passive_sessions_avail => $o->{"passive_sessions_avail"},
        active_sessions_highpoint => $o->{"active_sessions_highpoint"},
        passive_sessions_highpoint => $o->{"passive_sessions_highpoint"},
        bytes_in => $o->{"bytes_in"},
        bytes_out => $o->{"bytes_out"},
        cpu_usage_ctrl => $o->{"cpu_usage_ctrl"},
        cpu_usage_tsess => $o->{"cpu_usage_tsess"},
        connection_avg => $o->{"connection_avg"},
        connection_min => $o->{"connection_min"},
        connection_max => $o->{"connection_max"},
        connection_cnt => $o->{"connection_cnt"},
        ssl_session_new => $o->{"ssl_session_new"},
        ssl_session_reused => $o->{"ssl_session_reused"},
        ssl_session_timeout => $o->{"ssl_session_timeout"},
        ssl_session_cache_size => $o->{"ssl_session_cache_size"},
        sess_hits => $o->{"sess_hits"},
        sess_misses => $o->{"sess_misses"},
        sess_timeouts => $o->{"sess_timeouts"},
        sess_connect => $o->{"sess_connect"},
        sess_connect_good => $o->{"sess_connect_good"},
        sess_connect_renegotiate => $o->{"sess_connect_renegotiate"},
        sess_accept => $o->{"sess_accept"},
        sess_accept_good => $o->{"sess_accept_good"},
        sess_accept_renegotiate => $o->{"sess_accept_renegotiate"}
    };
    return bless($this,ref($class) || $class);
}

1;
