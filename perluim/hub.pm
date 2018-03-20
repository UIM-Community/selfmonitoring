use strict;
use warnings;

# Namespace
package perluim::hub;

# Nimsoft librairies !
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

# perluim packages
use perluim::robot;
use perluim::package;
use perluim::archive;
use perluim::probe;
use perluim::queue;

sub new {
    my ($class,$o) = @_;
    my @addrArray;
    if($o->get("hubaddr")) {
        @addrArray = split("/",$o->get("hubaddr"));
    }
    my $this = {
        name        => $o->get("name") || $o->get("hubname"),
        robotname   => $o->get("robotname") || $addrArray[3],
        addr        => $o->get("addr") || $o->get("hubaddr"),
        domain      => $o->get("domain"),
        ip          => $o->get("ip") || $o->get("hubip"),
        port        => $o->get("port"),
        status      => $o->get("status"),
        version     => $o->get("version"),
        origin      => $o->get("origin"),
        source      => $o->get("source"),
        last        => $o->get("last"),
        license     => $o->get("license"),
        sec_on      => $o->get("sec_on"),
        sec_ver     => $o->get("sec_ver"),
        ssl_mode    => $o->get("ssl_mode"),
        ldap        => $o->get("ldap"),
        ldap_version => $o->get("ldap_version"),
        tunnel      => $o->get("tunnel") || "no",
        uptime      => $o->get("uptime") || 0,
        started     => $o->get("started") || 0
    };
    my $blessed = bless($this,ref($class) || $class);
    $blessed->{clean_addr} = substr($blessed->{addr},0,-4);
    return $blessed;
}

sub removeRobot {
	my ($self,$robotName) = @_;
	my $PDS = pdsCreate();
	pdsPut_PCH ($PDS,"name",$robotName);
	pdsPut_PCH ($PDS,"name","controller");

	my ($RC, $O) = nimNamedRequest("$self->{addr}", "removerobot", $PDS);
	pdsDelete($PDS);
    return $RC;
}

sub local_removeRobot {
	my ($self,$robotName) = @_;
	my $PDS = pdsCreate();
	pdsPut_PCH ($PDS,"name",$robotName);
	pdsPut_PCH ($PDS,"name","controller");
	my ($RC, $O) = nimRequest("$self->{robotname}",48002, "removerobot", $PDS);
	pdsDelete($PDS);
    return $RC;
}

sub getRobots {
    my ($self,$robotname) = @_;
    my $PDS = pdsCreate();
    if(defined($robotname)) {
        pdsPut_PCH($PDS,"name","$robotname");
    }
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}","getrobots",$PDS,10);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        return $RC,Nimbus::PDS->new($NMS_RES);
    }
    else {
        return $RC,undef;
    }
}

#
# => Get an Array of robots in the instanciate HUB!
#
sub robotsArray {
    my ($self) = @_;
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}","getrobots",$PDS,10);
    pdsDelete($PDS);

    my @RobotsList = ();
    if($RC == NIME_OK) {
        my $ROBOTS_PDS = Nimbus::PDS->new($NMS_RES);
        for( my $count = 0; my $ROBOTNFO = $ROBOTS_PDS->getTable("robotlist",PDS_PDS,$count); $count++) {
            my $ROBOT = new perluim::robot($ROBOTNFO);
            push(@RobotsList,$ROBOT);
        }
    }
    return $RC,@RobotsList;
}

sub local_robotsArray {
    my ($self) = @_;
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimRequest("$self->{robotname}",48002,"getrobots",$PDS);
    pdsDelete($PDS);

    my @RobotsList = ();
    if($RC == NIME_OK) {
        my $ROBOTS_PDS = Nimbus::PDS->new($NMS_RES);
        for( my $count = 0; my $ROBOTNFO = $ROBOTS_PDS->getTable("robotlist",PDS_PDS,$count); $count++) {
            my $ROBOT = new perluim::robot($ROBOTNFO);
            push(@RobotsList,$ROBOT);
        }
    }
    return $RC,@RobotsList;
}

#
# => Get an Hash of robots in the instanciate HUB!
#
sub robotsHash {
    my ($self) = @_;
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}","getrobots",$PDS,10);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $ROBOTS_PDS = Nimbus::PDS->new($NMS_RES);
        my %RobotsList = ();
        for( my $count = 0; my $ROBOTNFO = $ROBOTS_PDS->getTable("robotlist",PDS_PDS,$count); $count++) {
            my $ROBOT = new perluim::robot($ROBOTNFO);
            $RobotsList{$ROBOT->{name}} = $ROBOT;
        }
        return $RC,%RobotsList;
    }
    else {
        return $RC,undef;
    }
}

sub local_robotsHash {
    my ($self) = @_;
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimRequest("$self->{robotname}",48002,"getrobots",$PDS,10);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $ROBOTS_PDS = Nimbus::PDS->new($NMS_RES);
        my %RobotsList = ();
        for( my $count = 0; my $ROBOTNFO = $ROBOTS_PDS->getTable("robotlist",PDS_PDS,$count); $count++) {
            my $ROBOT = new perluim::robot($ROBOTNFO);
            $RobotsList{$ROBOT->{name}} = $ROBOT;
        }
        return $RC,%RobotsList;
    }
    else {
        return $RC,undef;
    }
}

sub getEnv {
    my ($self,$var) = @_;

    my $PDS = pdsCreate();
    if(defined($var)) {
        pdsPut_PCH ($PDS,"variable","$var");
    }
    my ($RC,$RES) = nimNamedRequest("$self->{clean_addr}/controller","get_environment",$PDS);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($RES)->asHash();
        return $RC,$Hash;
    }
    return $RC,undef;
}

sub local_getEnv {
    my ($self,$var) = @_;

    my $PDS = pdsCreate();
    if(defined($var)) {
        pdsPut_PCH ($PDS,"variable","$var");
    }
    my ($RC,$RES) = nimRequest("$self->{robotname}",48000,"get_environment",$PDS);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($RES)->asHash();
        return $RC,$Hash;
    }
    return $RC,undef;
}

sub getInfo {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$RES) = nimNamedRequest("$self->{clean_addr}/controller","get_info",$PDS);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($RES)->asHash();
        return $RC,$Hash;
    }
    return $RC,undef;
}

sub local_getInfo {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$RES) = nimRequest("$self->{robotname}",48000,"get_info",$PDS);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($RES)->asHash();
        return $RC,$Hash;
    }
    return $RC,undef;
}

sub archive {
    my ($self,$probePort) = @_;
    return new perluim::archive($self,$probePort);
}

sub tunnelsList {
    my ($self) = @_; 

    my $PDS = pdsCreate();
    my ($RC,$RES) = nimNamedRequest("$self->{addr}","tunnel_get_info",$PDS,5);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my @Tunnels = ();
        my $TunnelPDS = Nimbus::PDS->new($RES);
        for( my $count = 0; my $T = $TunnelPDS->getTable("tunnels",PDS_PDS,$count); $count++) {
            my $TunnelObject = new perluim::tunnels($T);
            push(@Tunnels,$TunnelObject);
        }
        return $RC,@Tunnels;
    }
    
    return $RC,undef;
}

sub local_tunnelsList {
    my ($self) = @_; 

    my $PDS = pdsCreate();
    my ($RC,$RES) = nimRequest("$self->{robotname}",48002,"tunnel_get_info",$PDS,5);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my @Tunnels = ();
        my $TunnelPDS = Nimbus::PDS->new($RES);
        for( my $count = 0; my $T = $TunnelPDS->getTable("tunnels",PDS_PDS,$count); $count++) {
            my $TunnelObject = new perluim::tunnels($T);
            push(@Tunnels,$TunnelObject);
        }
        return $RC,@Tunnels;
    }
    
    return $RC,undef;
}

sub setQueue_state {
    my ($self,$queueName,$state) = @_; # State equal 1/0

    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"queue","$queueName");
    pdsPut_INT($PDS,"active",$state);
    my ($RC,$RES) = nimNamedRequest("$self->{addr}","queue_active",$PDS);
    pdsDelete($PDS);

    return $RC;
}

sub local_setQueue_state {
    my ($self,$queueName,$state) = @_; # State equal 1/0

    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"queue","$queueName");
    pdsPut_INT($PDS,"active",$state);
    my ($RC,$RES) = nimRequest("$self->{robotname}",48002,"queue_active",$PDS);
    pdsDelete($PDS);

    return $RC;
}

sub queueDelete {
    my ($self,$queueName) = @_;
    if(not defined $queueName) {
        return 1;
    }

    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"queue","$queueName");
    my ($RC,$RES) = nimNamedRequest("$self->{addr}","queue_delete",$PDS,5);
    pdsDelete($PDS);

    return $RC;
}

sub local_queueDelete {
    my ($self,$queueName) = @_;
    if(not defined $queueName) {
        return 1;
    }
    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"queue","$queueName");
    my ($RC,$RES) = nimNamedRequest("$self->{addr}","queue_delete",$PDS,5);
    pdsDelete($PDS);

    return $RC;
}

sub queueList {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$RES) = nimNamedRequest("$self->{addr}","queue_list",$PDS);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my @Queue = ();
        my $Queue_PDS = Nimbus::PDS->new($RES);
        for( my $count = 0; my $Q = $Queue_PDS->getTable("sections",PDS_PDS,$count); $count++) {
            my $QueueObject = new perluim::queue($Q);
            push(@Queue,$QueueObject);
        }
        return $RC,@Queue;
    }
    return $RC,undef;

}

sub local_queueList {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$RES) = nimRequest("$self->{robotname}",48002,"queue_list",$PDS);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my @Queue = ();
        my $Queue_PDS = Nimbus::PDS->new($RES);
        for( my $count = 0; my $Q = $Queue_PDS->getTable("sections",PDS_PDS,$count); $count++) {
            my $QueueObject = new perluim::queue($Q);
            push(@Queue,$QueueObject);
        }
        return $RC,@Queue;
    }
    return $RC,undef;

}

sub probeVerify {
    my ($self,$probeName) = @_;
    if(not defined $probeName) {
        return 1;
    }
    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"name","automated_deployment_engine");
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{clean_addr}/controller","probe_verify",$PDS);
    pdsDelete($PDS);
    return $RC;
}

sub local_probeVerify {
    my ($self,$probeName) = @_;
    if(not defined $probeName) {
        return 1;
    }
    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"name","automated_deployment_engine");
    my ($RC,$NMS_RES) = nimRequest("$self->{robotname}",48000,"probe_verify",$PDS);
    pdsDelete($PDS);
    return $RC;
}

sub probeList {
    my ($self,$probeName) = @_;
    my $PDS = pdsCreate();
    if(defined($probeName)) {
        pdsPut_PCH($PDS,"name","$probeName");
    }
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{clean_addr}/controller","probe_list",$PDS,10);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($NMS_RES)->asHash();
        my @Probes;
        foreach my $probe (keys %{$Hash}) {
            my $Iprobe = new perluim::probe($probe,$Hash,$self->{addr});
            push(@Probes,$Iprobe);
        }
        return $RC,@Probes
    }
    return $RC,undef;
}

sub local_probeList {
    my ($self,$probeName) = @_;
    my $PDS = pdsCreate();
    if(defined($probeName)) {
        pdsPut_PCH($PDS,"name","$probeName");
    }
    my ($RC,$NMS_RES) = nimRequest("$self->{robotname}",48000,"probe_list",$PDS,10);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($NMS_RES)->asHash();
        my @Probes;
        foreach my $probe (keys %{$Hash}) {
            my $Iprobe = new perluim::probe($probe,$Hash,$self->{addr});
            push(@Probes,$Iprobe);
        }
        return $RC,@Probes
    }
    return $RC,undef;
}

1;
