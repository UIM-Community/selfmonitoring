use strict;
use warnings;
package perluim::alarms;

sub new {
    my ($class,$o) = @_;
    my $this = {
        id              => $o->{"id"},
        assignedBy      => $o->{"assignedBy"},
        assignedTo      => $o->{"assignedTo"},
        message         => $o->{"message"},
        custom1         => $o->{"custom1"},
        custom2         => $o->{"custom2"},
        custom3         => $o->{"custom3"},
        custom4         => $o->{"custom4"},
        custom5         => $o->{"custom5"},
        domain          => $o->{"domain"},
        devId           => $o->{"devId"},
        hostname        => $o->{"hostname"} || "Undefined",
        hub             => shift $o->{"hub"},
        origin_arr      => $o->{"origin"},
        origin          => shift ($o->{"origin"}),
        robot           => shift $o->{"robot"},
        prevLevel       => $o->{"prevLevel"},
        level           => $o->{"level"},
        probe           => $o->{"probe"},
        subsystem       => $o->{"subsystem"},
        subsystemId     => $o->{"subsystemId"},
        severity        => $o->{"severity"},
        source          => $o->{"source"},
        suppressionCount  => $o->{"suppressionCount"},
        suppressionKey  => $o->{"suppressionKey"},
        timeArrival     => $o->{"timeArrival"},
        timeLast        => $o->{"timeLast"},
        timeOrigin      => $o->{"timeOrigin"},
        userTag1        => $o->{"userTag1"},
        userTag2        => $o->{"userTag2"},
        visible         => $o->{"visible"}
    };
    return bless($this,ref($class) || $class);
}

sub originExist {
    my ($self,$focus) = @_;
    my %params = map { $_ => 1 } $self->{origin_arr};
    if(exists($params{$focus})) {
        return $focus;
    }
    return "";
}

1;
