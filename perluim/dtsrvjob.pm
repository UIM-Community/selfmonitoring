use strict;
use warnings;

package perluim::dtsrvjob;

sub new {
    my ($class,$pds) = @_;
    my $this = {
        job_id => $pds->get('job_id'),
        job_description => $pds->get('job_description'),
        package_name => $pds->get('package_name'),
        package_version => $pds->get('package_version'),
        robot => $pds->get('robot'),
        time_entered => $pds->get('time_entered'),
        time_started => $pds->get('time_started'),
        time_scheduled => $pds->get('time_scheduled'),
        time_last_attempt_finished => $pds->get('time_last_attempt_finished'),
        time_finished => $pds->get('time_finished'),
        expire => $pds->get('expire'),
        result_code => $pds->get('result_code'),
        result_string => $pds->get('result_string'),
        remote_reported => $pds->get('remote_reported'),
        attempts => $pds->get('attempts'),
        retry_attempts => $pds->get('retry_attempts'),
        remote => $pds->get('remote'),
        source => $pds->get('source'),
        update => $pds->get('update'),
        status => $pds->get('status')
    };
    return bless($this,ref($class) || $class);
}

1;
