package perluim::utils;
use strict;
use warnings;
use Exporter qw(import);

use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::Session;
use Nimbus::CFG;
use Nimbus::PDS;

our @EXPORT_OK = qw(minIndex getTerminalInput getDate rndStr createDirectory doSleep generateAlarm nimId strBeginWith);

sub doSleep {
    my ($self,$sleepTime) = @_;
    while($sleepTime--) {
        sleep(1);
    }
}


sub createDirectory {
    my ($path) = @_;
    my @dir = split("/",$path);
    my $track = "";
    foreach(@dir) {
        my $path = $track.$_;
        if( !(-d $path) ) {
            mkdir($path) or die "Unable to create $_ directory!";
        }
        $track .= "$_/";
    }
}

sub minIndex {
	my( $aref, $idx_min ) = ( shift, 0 );
	$aref->[$idx_min] < $aref->[$_] or $idx_min = $_ for 1 .. $#{$aref};
	return $idx_min;
}

sub getTerminalInput {
    my $input;
    while(<>) {
        s/\s*$//;
        $input = $_;
        if(defined $input && $input ne "") {
            return $input;
        }
    }
}

sub getDate {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timestamp   = sprintf ( "%04d%02d%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	$timestamp     =~ s/\s+/_/g;
	$timestamp     =~ s/://g;
    return $timestamp;
}

sub rndStr { 
    return join'', @_[ map{ rand @_ } 1 .. shift ] 
}

sub nimId {
    my $A = rndStr(10,'A'..'Z',0..9);
    my $B = rndStr(5,0..9);
    return "$A-$B";
}

sub strBeginWith {
    return substr($_[0], 0, length($_[1])) eq $_[1];
}

sub generateAlarm {
    my ($subject,$hashRef) = @_;

    my $PDS = Nimbus::PDS->new(); 
    my $nimid = nimId();

    $PDS->string("nimid",$nimid);
    $PDS->number("nimts",time());
    $PDS->number("tz_offset",0);
    $PDS->string("subject","$subject");
    $PDS->string("md5sum","");
    $PDS->string("user_tag_1",$hashRef->{usertag1} || "");
    $PDS->string("user_tag_2",$hashRef->{usertag2} || "");
    $PDS->string("source",$hashRef->{source} || $hashRef->{robot} || "");
    $PDS->string("robot",$hashRef->{robot} || "");
    $PDS->string("prid",$hashRef->{probe} || "");
    $PDS->number("pri",$hashRef->{severity} || 0);
    $PDS->string("dev_id",$hashRef->{dev_id} || "");
    $PDS->string("met_id",$hashRef->{met_id} || "");
    if ($hashRef->{supp_key}) { $PDS->string("supp_key",$hashRef->{supp_key}) };
    $PDS->string("suppression",$hashRef->{suppression} || "");
    $PDS->string("origin",$hashRef->{origin} || "");
    $PDS->string("domain",$hashRef->{domain} || "");

    my $AlarmPDS = Nimbus::PDS->new(); 
    $AlarmPDS->number("level",$hashRef->{severity} || 0);
    $AlarmPDS->string("message",$hashRef->{message});
    $AlarmPDS->string("subsys",$hashRef->{subsystem} || "1.1.");
    if(defined $hashRef->{token}) {
        $AlarmPDS->string("token",$hashRef->{token});
    }

    $PDS->put("udata",$AlarmPDS,PDS_PDS);

    return ($PDS,$nimid);
}    

sub postRaw {
    my ($alarmHashRef) = @_;
    if(not defined $alarmHashRef->{robot}) {
        return undef,undef;
    }
    else {
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

    my ($PDS,$alarmid) = generateAlarm('alarm',$alarmHashRef);
    my ($rc_alarm,$res) = nimRequest("$alarmHashRef->{robot}",48001,"post_raw",$PDS);
    return $rc_alarm,$alarmid;
}

1;