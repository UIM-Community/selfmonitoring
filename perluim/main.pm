use strict;
use warnings;
package perluim::main;

# Nimsoft packages
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::CFG;
use Nimbus::PDS;

# perluim packages
use perluim::hub;
use perluim::robot;

use Term::ANSIColor qw(:constants);
use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;
use XML::Simple;
$Data::Dumper::Indent = 1;

sub new {
    my ($class,$domain) = @_;
    my $this = {
        domain => $domain
    };
    return bless($this,ref($class) || $class);
}

sub getLocalRobot {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("controller","get_info",$PDS,1);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        my $PDS = new Nimbus::PDS();
        foreach my $key (keys $RobotNFO) {
            $PDS->put($key,$RobotNFO->{$key},PDS_PCH);
        }
        return $RC,new perluim::robot($PDS);
    }
    else {
        return $RC,undef;
    }
}

sub getAllRobots {
    my ($self) = @_;
    my ($RC_Hub,@LIST_HUB) = $self->getArrayHubs();
    if($RC_Hub == NIME_OK) {
        my %LIST_ROBOTS     = ();
        foreach my $hub (@LIST_HUB) {
            my ($RC,@ROBOTS) = $hub->robotsArray();
            next if $RC != NIME_OK;
            foreach my $robot (@ROBOTS) {
                $LIST_ROBOTS{lc $robot->{name}} = $robot;
            }
        }
        return $RC_Hub,%LIST_ROBOTS;
    }
    return $RC_Hub,undef;
}

sub getLocalHub {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("hub","get_info",$PDS,1);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        my $PDS = new Nimbus::PDS();
        foreach my $key (keys $RobotNFO) {
            $PDS->put($key,$RobotNFO->{$key},PDS_PCH);
        }
        return $RC,new perluim::hub($PDS);
    }
    else {
        return $RC,undef;
    }
}

sub getArrayHubs {
    my ($self,$hubADDR) = @_;
    my $focus_hubADDR = $hubADDR || "hub";
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$focus_hubADDR","gethubs",$PDS,10);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my $HUBS_PDS = Nimbus::PDS->new($NMS_RES);
        my @Hubslist = ();
        for( my $count = 0; my $HUBNFO = $HUBS_PDS->getTable("hublist",PDS_PDS,$count); $count++) {
            my $HUB = new perluim::hub($HUBNFO);
            push(@Hubslist,$HUB);
        }
        return $RC,@Hubslist;
    }
    else {
        return $RC,undef;
    }
}

sub getHashHubs {
    my ($self,$hubADDR) = @_;
    my $focus_hubADDR = $hubADDR || "hub";
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$focus_hubADDR","gethubs",$PDS,10);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my $HUBS_PDS = Nimbus::PDS->new($NMS_RES);
        my %Hubslist = ();
        for( my $count = 0; my $HUBNFO = $HUBS_PDS->getTable("hublist",PDS_PDS,$count); $count++) {
            my $HUB = new perluim::hub($HUBNFO);
            $Hubslist{$HUB->{name}} = $HUB;
        }
        return $RC,%Hubslist;
    }
    else {
        return $RC,undef;
    }
}

sub getHashRobots {
    my ($self,$hubname,$hubserver) = @_;
    my $addr = "/$self->{domain}/$hubname/$hubserver/hub";
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$addr","getrobots",$PDS,10);
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

sub getArrayRobots {
    my ($self,$hubname,$hubserver) = @_;
    my $addr = "/$self->{domain}/$hubname/$hubserver/hub";
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$addr","getrobots",$PDS,10);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $ROBOTS_PDS = Nimbus::PDS->new($NMS_RES);
        my @RobotsList = ();
        for( my $count = 0; my $ROBOTNFO = $ROBOTS_PDS->getTable("robotlist",PDS_PDS,$count); $count++) {
            my $ROBOT = new perluim::robot($ROBOTNFO);
            push(@RobotsList,$ROBOT);
        }
        return $RC,@RobotsList;
    }
    else {
        return $RC,undef;
    }
}

1;
