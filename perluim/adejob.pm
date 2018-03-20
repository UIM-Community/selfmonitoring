#
# PERLUIM ADEJOB.PM
# ADE Job class.
#

use strict;
use warnings;

package perluim::adejob;

use Nimbus::API;
use Nimbus::PDS;

sub new {
    my ($class,$jobID,$AdeADDR,$JobName) = @_;
    my $this = {
        name => $JobName,
        id => $jobID,
        addr => $AdeADDR,
        taskid => undef,
        status => "",
        description => "",
        error => ""
    };
    return bless($this,ref($class) || $class);
}

sub getTask {
    my ($self) = @_;
    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"JobID","$self->{id}");
    my ($RC,$OBJ) = nimNamedRequest("$self->{addr}","get_job_summary",$PDS,10);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my $JobPDS = Nimbus::PDS->new($OBJ);
        my $JobHash = $JobPDS->getTable("Tasks",PDS_PDS,0);
        $self->{taskid} = $JobHash->get("TaskId");
    }
    return $RC;
}

sub check {
    my ($self) = @_;
    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"JobID","$self->{id}");
    pdsPut_INT($PDS,"TaskID","$self->{taskid}");
    my ($RC,$OBJ) = nimNamedRequest("$self->{addr}","get_task_status",$PDS,10);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my $JOBHash = Nimbus::PDS->new($OBJ)->asHash();
        $self->{status} = $JOBHash->{Status} || "N.A";
        $self->{description} = $JOBHash->{Description} || "";
        $self->{error} = $JOBHash->{Error} || "";
    }
    return $RC;
}

sub cancel {
    my ($self) = @_;
    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"JobID","$self->{id}");
    my ($RC,$OBJ) = nimNamedRequest("$self->{addr}","remove_job",$PDS,10);
    pdsDelete($PDS);
    return $RC;
}

1;
