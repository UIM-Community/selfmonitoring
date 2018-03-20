package perluim::alarmstask;

# Nimsoft librairies !
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;
use perluim::utils;

use Data::Dumper;

sub new {
    my ($class,$name,$arr) = @_;
    my $this = {
        name => $name,
        message => @$arr[0],
        severity => @$arr[2] || 1,
        token => @$arr[1] || undef,
        supkey => undef,
        subsystem => @$arr[3] || "1."
    };
    return bless($this,ref($class) || $class);
}

sub getMessage {
    my ($self,$hashRef) = @_;
    my $finalMsg = $self->{message};
    my $CopyMsg = $self->{message};
    my @matches = ( $CopyMsg =~ /\$([A-Za-z0-9]+)/g );
    foreach (@matches) {
        if(exists($hashRef->{"$_"})) {
            $finalMsg =~ s/\$\Q$_/$hashRef->{$_}/g;
        }
    }
    return $finalMsg;
}

sub call {
    my ($self,$hashRef) = @_;
    my $finalMsg = $self->getMessage($hashRef);
    my ($rc,$alarmid) = nimAlarm($self->{severity},$finalMsg,$self->{subsystem},$self->{supkey});
    return $rc,$alarmid;
}

sub customCall {
    my ($self,$alarmHashRef,$type) = @_;
    if(not defined $type) {
        $type = "alarm";
    }
    
    if(defined $alarmHashRef->{robot}) {
        my $robot = $alarmHashRef->{robot}; 
        if(not defined $alarmHashRef->{origin}) {
            $alarmHashRef->{origin} = $robot->{origin};
        }
        
        if(not defined $alarmHashRef->{usertag1}) {
            $alarmHashRef->{usertag1} = $robot->{os_user1};
        }

        if(not defined $alarmHashRef->{usertag2}) {
            $alarmHashRef->{usertag2} = $robot->{os_user2};
        }

        if(not defined $alarmHashRef->{dev_id}) {
            $alarmHashRef->{dev_id} = $robot->{device_id};
        }

        if(not defined $alarmHashRef->{met_id}) {
            $alarmHashRef->{met_id} = $robot->{metric_id};
        }

        if(not defined $alarmHashRef->{source}) {
            $alarmHashRef->{source} = $robot->{ip};
        }

        $alarmHashRef->{robot} = $robot->{name};
    }

    if(defined $alarmHashRef->{robotname}) {
        $alarmHashRef->{robot} = $robot->{robotname};
    }

    if(not defined $alarmHashRef->{severity}) {
        $alarmHashRef->{severity} = $self->{severity}
    }

    if(not defined $alarmHashRef->{subsystem}) {
        $alarmHashRef->{subsystem} = $self->{subsystem}
    }

    if(not defined $alarmHashRef->{message}) {
        $alarmHashRef->{message} = $self->getMessage($alarmHashRef);
    }

    my ($PDS,$alarmid) = perluim::utils::generateAlarm("$type",$alarmHashRef);
    my ($rc_alarm,$res) = nimRequest("$alarmHashRef->{robot}",48001,"post_raw",$PDS->data);
    return $rc_alarm,$alarmid;
}

package perluim::alarmsmanager;

use Data::Dumper;

sub new {
    my ($class,$CFG,$section) = @_;
    my %Alarms = ();
    foreach my $key (keys $CFG->{"$section"}) {
        my @Arr = (
            $CFG->{"$section"}->{$key}->{"message"},
            $CFG->{"$section"}->{$key}->{"i18n_token"},
            $CFG->{"$section"}->{$key}->{"severity"},
            $CFG->{"$section"}->{$key}->{"subsystem"}
        );
        $Alarms{$key} = new perluim::alarmstask($key,\@Arr);
    }
    my $this = {
        alarms => \%Alarms
    };
    return bless($this,ref($class) || $class);
}

sub call {
    my $self = shift;
    my $alarmName = shift;
    my $hash = shift;
    if( defined($self->{alarms}->{$alarmName}) ) {
        return $self->{alarms}->{$alarmName}->call($hash);
    }
    return 1,undef;
}

sub get {
    my ($self,$alarmName) = @_;
    if( defined($self->{alarms}->{$alarmName}) ) {
        return $self->{alarms}->{$alarmName};
    }
    return undef;
}


1;
