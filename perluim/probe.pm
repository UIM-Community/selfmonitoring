use strict;
use warnings;

# Namespace
package perluim::probe;

# Nimsoft librairies !
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

sub new {
    my ($class,$name,$o,$addr) = @_;
    my @addrArray = split("/",$addr);
    my $this = {
        name            => $o->{$name}{"name"},
        addr            => $addr,
        robotname       => $addrArray[3],
        description     => $o->{$name}{"description"}  || "",
        group           => lc $o->{$name}{"group"}  || "",
        active          => $o->{$name}{"active"},
        type            => $o->{$name}{"type"},
        command         => $o->{$name}{"command"},
        config          => lc $o->{$name}{"config"},
        logfile         => lc $o->{$name}{"logfile"},
        workdir         => lc $o->{$name}{"workdir"},
        arguments       => $o->{$name}{"arguments"} || "",
        pid             => $o->{$name}{"pid"},
        times_started   => $o->{$name}{"times_started"},
        last_started    => $o->{$name}{"last_started"} || 0,
        pkg_name        => $o->{$name}{"pkg_name"} || "",
        pkg_version     => $o->{$name}{"pkg_version"} || "",
        pkg_build       => $o->{$name}{"pkg_build"} || "",
        process_state   => $o->{$name}{"process_state"} || "unknown",
        port            => $o->{$name}{"port"},
        times_activated => $o->{$name}{"times_activated"},
        timespec        => $o->{$name}{"timespec"},
        last_action     => $o->{$name}{"last_action"},
        is_marketplace  => $o->{$name}{"is_marketplace"},
        local_cfg       => undef
    };
    return bless($this,ref($class) || $class);
}

sub getCfg {
    my ($self,$filepath) = @_;
    my $directory   = "probes/$self->{group}/$self->{name}/";

    if($self->{name} eq "hub") {
        $directory = "hub";
    }
    elsif($self->{name} eq "controller" || $self->{name} eq "spooler" || $self->{name} eq "robot") {
        $directory = "robot";
    }
    elsif($self->{name} eq "hdb") {
        return 1;
    }
    elsif($self->{name} eq "distsrv") {
        $directory = "probes/service/distsrv";
    }
    elsif($self->{name} eq "nas") {
        $directory = "probes/service/$self->{name}/";
    }

    my $PDS = pdsCreate();
    pdsPut_PCH ($PDS,"directory",$directory);
    pdsPut_PCH ($PDS,"file","$self->{name}.cfg");
    pdsPut_INT ($PDS,"buffer_size",10000000);

    my ($RC, $RES) = nimRequest("$self->{robotname}",48000, "text_file_get", $PDS,5);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $CFG_Handler;

        unless(open($CFG_Handler,">>","$filepath/$self->{name}.cfg")) {
            return 1;
        }
        my @ARR_CFG_Config = Nimbus::PDS->new($RES)->asHash();
        print $CFG_Handler $ARR_CFG_Config[0]{'file_content'};
        close $CFG_Handler;
    }
    return $RC;

}

sub getLog {
    my ($self,$filepath) = @_;

    my $directory = "probes/$self->{group}/$self->{name}/";
    if($self->{name} eq "hub") {
        $directory = "hub";
    }
    elsif($self->{name} eq "controller" || $self->{name} eq "spooler") {
        $directory = "robot";
    }
    elsif($self->{name} eq "nas") {
        $directory = "probes/service/nas";
    }
    elsif($self->{name} eq "hdb") {
        $directory = "probes/service/hdb";
    }
    elsif($self->{name} eq "distsrv") {
        $directory = "probes/service/distsrv";
    }

    my $PDS = pdsCreate();
    pdsPut_PCH ($PDS,"directory",$directory);
    pdsPut_PCH ($PDS,"file","$self->{name}.log");
    pdsPut_INT ($PDS,"buffer_size",10000000);

    my ($RC, $RES) = nimRequest("$self->{robotname}","48000", "text_file_get", $PDS,3);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $CFG_Handler;
        unless(open($CFG_Handler,">>","$filepath/$self->{name}.log")) {
            return 1;
        }
        my @ARR_CFG_Config = Nimbus::PDS->new($RES)->asHash();
        print $CFG_Handler $ARR_CFG_Config[0]{'file_content'};
        close $CFG_Handler;
    }
    return $RC;
}

sub setKey {
    my ($self,$section,$key,$value) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$self->{name}");
    pdsPut_PCH ($PDS_args,"section","$section");
    pdsPut_PCH ($PDS_args,"key","$key");
    pdsPut_PCH ($PDS_args,"value","$value");
    pdsPut_PCH ($PDS_args,"robot","1");

    my ($RC, $O) = nimNamedRequest("$self->{addr}/controller", "probe_config_set", $PDS_args,3);
    pdsDelete($PDS_args);

    return $RC;
}

sub local_setKey {
    my ($self,$section,$key,$value) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$self->{name}");
    pdsPut_PCH ($PDS_args,"section","$section");
    pdsPut_PCH ($PDS_args,"key","$key");
    pdsPut_PCH ($PDS_args,"value","$value");
    pdsPut_PCH ($PDS_args,"robot","1");

    my ($RC, $O) = nimRequest("$self->{robotname}",48000, "probe_config_set", $PDS_args,3);
    pdsDelete($PDS_args);

    return $RC;
}

sub getKey {
    my ($self,$var) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$self->{name}");
    if(defined($var)) {
        pdsPut_PCH ($PDS_args,"var","$var");
    }

    my ($RC, $RES) = nimNamedRequest("$self->{addr}/controller", "probe_config_get", $PDS_args,3);
    pdsDelete($PDS_args);

    if($RC == NIME_OK) {
        if(defined($var)) {
            my $value = (Nimbus::PDS->new($RES))->get("value");
            return $RC,$value;
        }
        else {
            my $Hash = Nimbus::PDS->new($RES)->asHash();
            return $RC,$Hash;
        }
    }
    return $RC,undef;
}

sub local_getKey {
    my ($self,$var) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$self->{name}");
    if(defined($var)) {
        pdsPut_PCH ($PDS_args,"var","$var");
    }

    my ($RC, $RES) = nimRequest("$self->{robotname}", 48000, "probe_config_get", $PDS_args,3);
    pdsDelete($PDS_args);

    if($RC == NIME_OK) {
        if(defined($var)) {
            my $value = (Nimbus::PDS->new($RES))->get("value");
            return $RC,$value;
        }
        else {
            my $Hash = Nimbus::PDS->new($RES)->asHash();
            return $RC,$Hash;
        }
    }
    return $RC,undef;
}


1;
