use strict;
use warnings;

package perluim::robot;

# Nimsoft librairies !
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

# perluim librairies
use perluim::probe;
use perluim::package;

sub new {
    my ($class,$o) = @_;
    my $this = {
        name            => $o->get("name") || $o->get("robotname") ,
        origin          => $o->get("origin"),
        addr            => $o->get("addr") || "/".$o->get("domain")."/".$o->get("hubname")."/".$o->get("robotname"),
        port            => $o->get("port") || "48000",
        version         => $o->get("version"),
        ip              => $o->get("ip") || $o->get("robotip"),
        status          => $o->get("status") || 0,
        os_major        => $o->get("os_major"),
        os_minor        => $o->get("os_minor"),
        os_user1        => $o->get("os_user1"),
        os_user2        => $o->get("os_user2"),
        os_description  => $o->get("os_description"),
        ssl_mode        => $o->get("ssl_mode"),
        device_id       => $o->get("device_id") || $o->get("robot_device_id"),
        metric_id       => $o->get("metric_id"),
        probe_list      => {},
        hubname         => "",
        hubip           => "",
        domain          => "",
        robotip         => "",
        hubrobotname    => "",
        uptime          => 0,
        started         => 0,
        os_version      => "",
        workdir         => "",
        log_level       => 0,
        source          => ""

    };
    return bless($this,ref($class) || $class);
}

#
# => Get robot information !
#
sub getInfo {
    my ($self) = @_;
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}/controller","get_info",$PDS,1);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        $self->{hubname}        = $RobotNFO->{hubname};
        $self->{hubip}          = $RobotNFO->{hubip};
        $self->{domain}         = $RobotNFO->{domain};
        $self->{robotip}        = $RobotNFO->{robotip};
        $self->{hubrobotname}   = $RobotNFO->{hubrobotname};
        $self->{uptime}         = $RobotNFO->{uptime};
        $self->{started}        = $RobotNFO->{started};
        $self->{os_version}     = $RobotNFO->{os_version};
        $self->{workdir}        = $RobotNFO->{workdir};
        $self->{log_level}      = $RobotNFO->{log_level};
        $self->{source}         = $RobotNFO->{source};
    }
    return $RC;
}

sub local_getInfo {
    my ($self) = @_;
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimRequest("$self->{name}",48000,"get_info",$PDS,1);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        $self->{hubname}        = $RobotNFO->{hubname};
        $self->{hubip}          = $RobotNFO->{hubip};
        $self->{domain}         = $RobotNFO->{domain};
        $self->{robotip}        = $RobotNFO->{robotip};
        $self->{hubrobotname}   = $RobotNFO->{hubrobotname};
        $self->{uptime}         = $RobotNFO->{uptime};
        $self->{started}        = $RobotNFO->{started};
        $self->{os_version}     = $RobotNFO->{os_version};
        $self->{workdir}        = $RobotNFO->{workdir};
        $self->{log_level}      = $RobotNFO->{log_level};
        $self->{source}         = $RobotNFO->{source};
    }
    return $RC;
}

sub getHub {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}/controller","gethub",$PDS,1);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        $self->{phub_domain}        = $RobotNFO->{phub_domain} || "NMS-PROD";
        $self->{phub_name}          = $RobotNFO->{phub_name} || "";
        $self->{phub_robotname}     = $RobotNFO->{phub_robotname} || "";
        $self->{phub_ip}            = $RobotNFO->{phub_ip} || "";
        $self->{phub_dns_name}      = $RobotNFO->{phub_dns_name} || $RobotNFO->{phub_name} || "";
        $self->{phub_port}          = $RobotNFO->{phub_port} || 48002;
        $self->{shub_domain}        = $RobotNFO->{shub_domain} || "NMS-PROD";
        $self->{shub_name}          = $RobotNFO->{shub_name} || "";
        $self->{shub_robotname}     = $RobotNFO->{shub_robotname} || "";
        $self->{shub_ip}            = $RobotNFO->{shub_ip} || "";
        $self->{shub_dns_name}      = $RobotNFO->{shub_dns_name} || $RobotNFO->{shub_name} || "";
        $self->{shub_port}          = $RobotNFO->{shub_port} || 48002;
    }
    return $RC,undef;
}

sub local_getHub {
    my ($self) = @_;
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimRequest("$self->{name}",48000,"gethub",$PDS,1);
    pdsDelete($PDS);
    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        $self->{phub_domain}        = $RobotNFO->{phub_domain} || "NMS-PROD";
        $self->{phub_name}          = $RobotNFO->{phub_name} || "";
        $self->{phub_robotname}     = $RobotNFO->{phub_robotname} || "";
        $self->{phub_ip}            = $RobotNFO->{phub_ip} || "";
        $self->{phub_dns_name}      = $RobotNFO->{phub_dns_name} || $RobotNFO->{phub_name} || "";
        $self->{phub_port}          = $RobotNFO->{phub_port} || 48002;
        $self->{shub_domain}        = $RobotNFO->{shub_domain} || "NMS-PROD";
        $self->{shub_name}          = $RobotNFO->{shub_name} || "";
        $self->{shub_robotname}     = $RobotNFO->{shub_robotname} || "";
        $self->{shub_ip}            = $RobotNFO->{shub_ip} || "";
        $self->{shub_dns_name}      = $RobotNFO->{shub_dns_name} || $RobotNFO->{shub_name} || "";
        $self->{shub_port}          = $RobotNFO->{shub_port} || 48002;
    }
    return $RC;
}

sub getHub_asHash {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}/controller","gethub",$PDS);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        return $RC,$RobotNFO;
    }
    return $RC,undef;
}

sub local_getHub_asHash {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimRequest("$self->{name}",48000,"gethub",$PDS);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $RobotNFO = Nimbus::PDS->new($NMS_RES)->asHash();
        return $RC,$RobotNFO;
    }
    return $RC,undef;
}

sub packagesArray {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}/controller","inst_list_summary",$PDS,1);
    pdsDelete($PDS);

    my @PackagesList = ();
    if($RC == NIME_OK) {
        my $PACKAGE_PDS = Nimbus::PDS->new($NMS_RES);
        for( my $count = 0; my $PACKAGENFO = $PACKAGE_PDS->getTable("pkg",PDS_PDS,$count); $count++) {
            my $Package = new perluim::package($PACKAGENFO);
            push(@PackagesList,$Package);
        }
    }
    return $RC,@PackagesList;
}

sub local_packagesArray {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimRequest("$self->{name}",48000,"inst_list_summary",$PDS,1);
    pdsDelete($PDS);

    my @PackagesList = ();
    if($RC == NIME_OK) {
        my $PACKAGE_PDS = Nimbus::PDS->new($NMS_RES);
        for( my $count = 0; my $PACKAGENFO = $PACKAGE_PDS->getTable("pkg",PDS_PDS,$count); $count++) {
            if( $PACKAGENFO->get("name") ) {
                my $Package = new perluim::package($PACKAGENFO);
                push(@PackagesList,$Package);
            }
        }
    }
    return $RC,@PackagesList;
}

sub probesArray {
    my ($self) = @_;

    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{addr}/controller","probe_list",$PDS,1);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my @ProbesArray = ();
        my $ProbeCFG = Nimbus::PDS->new($NMS_RES)->asHash();
        foreach my $ProbeName (keys $ProbeCFG) {
            my $Iprobe = new perluim::probe($ProbeName,$ProbeCFG,$self->{addr});
            $Iprobe->{robotname} = $self->{name};
            push(@ProbesArray,$Iprobe);
        }
        return $RC,@ProbesArray;
    }
    return $RC,undef;
}

sub local_probesArray {
    my ($self) = @_;

    my @ProbesArray = ();
    my $PDS = pdsCreate();
    my ($RC,$NMS_RES) = nimRequest("$self->{name}",48000,"probe_list",$PDS,1);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $ProbeCFG = Nimbus::PDS->new($NMS_RES)->asHash();
        foreach my $ProbeName (keys $ProbeCFG) {
            my $Iprobe = new perluim::probe($ProbeName,$ProbeCFG,$self->{addr});
            $Iprobe->{robotname} = $self->{name};
            push(@ProbesArray,$Iprobe);
        }
    }
    return $RC,@ProbesArray;
}

sub getRobotCFG {
    my ($self,$filepath) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"directory","robot");
    pdsPut_PCH ($PDS_args,"file","robot.cfg");
    pdsPut_INT ($PDS_args,"buffer_size",10000000);

    my ($RC, $ProbePDS_CFG) = nimNamedRequest("$self->{addr}/controller", "text_file_get", $PDS_args,3);
    pdsDelete($PDS_args);

    if($RC == NIME_OK) {
        my $CFG_Handler;
        unless(open($CFG_Handler,">","$filepath/robot_$self->{name}_.cfg")) {
            warn "\nUnable to create configuration file for robot probe on path $filepath\n";
            return 1;
        }
        my @ARR_CFG_Config = Nimbus::PDS->new($ProbePDS_CFG)->asHash();
        print $CFG_Handler $ARR_CFG_Config[0]{'file_content'};
        close $CFG_Handler;
        return $RC;
    }
    return $RC;
}

sub local_getRobotCFG {
    my ($self,$filepath) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"directory","robot");
    pdsPut_PCH ($PDS_args,"file","robot.cfg");
    pdsPut_INT ($PDS_args,"buffer_size",10000000);

    my ($RC, $ProbePDS_CFG) = nimRequest("$self->{name}",48000, "text_file_get", $PDS_args,3);
    pdsDelete($PDS_args);

    if($RC == NIME_OK) {
        my $CFG_Handler;
        unless(open($CFG_Handler,">","$filepath/robot_$self->{name}_.cfg")) {
            warn "\nUnable to create configuration file for robot probe on path $filepath\n";
            return 1;
        }
        my @ARR_CFG_Config = Nimbus::PDS->new($ProbePDS_CFG)->asHash();
        print $CFG_Handler $ARR_CFG_Config[0]{'file_content'};
        close $CFG_Handler;
        return $RC;
    }
    return $RC;
}

sub scanRobotCFG {
    my ($self,$filepath,$key,$expected_value) = @_;

    my $CFG = Nimbus::CFG->new("$filepath/robot_$self->{name}_.cfg");
    if(defined($CFG->{'controller'}->{"$key"})) {
        my $cfg_hubdomain_value = $CFG->{'controller'}->{"$key"};
        if($cfg_hubdomain_value ne $expected_value) {
            return 1;
        }
    }
    return 0;
}

sub probeConfig_set {
    my ($self,$probeName,$section,$key,$value) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$probeName");
    pdsPut_PCH ($PDS_args,"section","$section");
    pdsPut_PCH ($PDS_args,"key","$key");
    pdsPut_PCH ($PDS_args,"value","$value");
    pdsPut_PCH ($PDS_args,"robot","1");

    my ($RC, $O) = nimNamedRequest("$self->{addr}/controller", "probe_config_set", $PDS_args,3);
    pdsDelete($PDS_args);

    return $RC;
}

sub local_probeConfig_set {
    my ($self,$probeName,$section,$key,$value) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$probeName");
    pdsPut_PCH ($PDS_args,"section","$section");
    pdsPut_PCH ($PDS_args,"key","$key");
    pdsPut_PCH ($PDS_args,"value","$value");
    pdsPut_PCH ($PDS_args,"robot","1");

    my ($RC, $O) = nimRequest("$self->{name}",48000, "probe_config_set", $PDS_args,3);
    pdsDelete($PDS_args);

    return $RC;
}

sub probeConfig_get {
    my ($self,$probeName,$var) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$probeName");
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

sub local_probeConfig_get {
    my ($self,$probeName,$var) = @_;

    my $PDS_args = pdsCreate();
    pdsPut_PCH ($PDS_args,"name","$probeName");
    if(defined($var)) {
        pdsPut_PCH ($PDS_args,"var","$var");
    }

    my ($RC, $RES) = nimRequest("$self->{name}",48000, "probe_config_get", $PDS_args);
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

sub probeExist {
    my ($self,$probeName) = @_;

    my $PDS = pdsCreate();
	pdsPut_PCH($PDS,"name",$probeName);
	my ($RC,$RES) = nimNamedRequest( "$self->{addr}/controller", "probe_list",$PDS,5);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($RES)->asHash();
        return $RC,$Hash->{"$probeName"};
    }
    return $RC,undef;
}

sub local_probeExist {
    my ($self,$probeName) = @_;

    my $PDS = pdsCreate();
	pdsPut_PCH($PDS,"name",$probeName);
	my ($RC,$RES) = nimRequest( "$self->{name}",48000, "probe_list",$PDS,5);
    pdsDelete($PDS);

    if($RC == NIME_OK) {
        my $Hash = Nimbus::PDS->new($RES)->asHash();
        return $RC,$Hash->{"$probeName"};
    }
    return $RC,undef;
}


sub probeRestart {
    my ($self,$probeName) = @_;
	my $RC = nimNamedRequest( "$self->{addr}/$probeName", "_restart");
	return $RC;
}

sub local_probeRestart {
    my ($self,$probePort) = @_;
	my $RC = nimRequest( "$self->{name}",$probePort, "_restart");
	return $RC;
}

sub probeDeactivate {
	my ($self,$probeName) = @_;

	my $PDS = pdsCreate();
	pdsPut_PCH($PDS,"name",$probeName);
	pdsPut_INT($PDS,"noforce",1);
	my ($RC,$OBJ) = nimNamedRequest( "$self->{addr}/controller", "probe_deactivate",$PDS,5);
    pdsDelete($PDS);

	return $RC;
}

sub local_probeDeactivate {
	my ($self,$probeName) = @_;

	my $PDS = pdsCreate();
	pdsPut_PCH($PDS,"name",$probeName);
	pdsPut_INT($PDS,"noforce",1);
	my ($RC,$OBJ) = nimRequest( "$self->{name}",48000, "probe_deactivate",$PDS,5);
    pdsDelete($PDS);

	return $RC;
}

sub removeProbe {
	my ($self,$packageName,$probeName) = @_;

	my $args = pdsCreate();
    pdsPut_PCH($args, "package", $packageName);
    pdsPut_PCH($args, "probe", $probeName);
    my ($RC, $RES) = nimNamedRequest("$self->{addr}/controller", "inst_pkg_remove", $args, 10);
    pdsDelete($args);

	return $RC;
}

sub local_removeProbe {
	my ($self,$packageName,$probeName) = @_;

	my $args = pdsCreate();
    pdsPut_PCH($args, "package", $packageName);
    pdsPut_PCH($args, "probe", $probeName);
    my ($RC, $RES) = nimRequest("$self->{name}",48000, "inst_pkg_remove", $args, 10);
    pdsDelete($args);

	return $RC;
}

sub probeActivate {
	my ($self,$probeName) = @_;

	my $PDS = pdsCreate();
	pdsPut_PCH($PDS,"name",$probeName);
	my ($RC,$OBJ) = nimNamedRequest( "$self->{addr}/controller", "probe_activate",$PDS,5);
    pdsDelete($PDS);

	return $RC;
}

sub local_probeActivate {
	my ($self,$probeName) = @_;

	my $PDS = pdsCreate();
	pdsPut_PCH($PDS,"name",$probeName);
	my ($RC,$OBJ) = nimRequest( "$self->{name}", 48000 , "probe_activate",$PDS);
    pdsDelete($PDS);

	return $RC;
}

sub updateOrigin {
	my ($self, $value) = @_;
	my $PDS = pdsCreate();

    # Prepare PDS
	pdsPut_PCH ($PDS,"name","spooler");
	pdsPut_PCH ($PDS,"section","spooler");
	pdsPut_PCH ($PDS,"key","origin");
	pdsPut_PCH ($PDS,"value",$value);

	my ($RC, $OBJ) = nimNamedRequest("$self->{addr}/controller", "probe_config_set", $PDS,2);
	pdsDelete($PDS);

	return $RC;
}

sub updateDomain {
	my ($self, $value) = @_;
    # Prepare PDS
	my $PDS = pdsCreate();
	my $PDS_OPTION = pdsCreate();

    # Prepare PDS
	pdsPut_PCH ($PDS_OPTION,"/controller/domain",$value) ;
	pdsPut_PCH ($PDS,"name","controller");
	pdsPut_PDS ($PDS,"as_pds",$PDS_OPTION);

	my ($RC, $OBJ) = nimNamedRequest("$self->{addr}/controller", "probe_config_set", $PDS,2);
	pdsDelete($PDS);

	return $RC;
}

sub updateUsertag2 {
	my ($self, $value) = @_;
	my $PDS = pdsCreate();
	my $PDS_OPTION = pdsCreate();

    # Prepare PDS
	pdsPut_PCH ($PDS_OPTION,"/controller/os_user2",$value) ;
	pdsPut_PCH ($PDS,"name","controller");
	pdsPut_PDS ($PDS,"as_pds",$PDS_OPTION);

	my ($RC, $OBJ) = nimNamedRequest("$self->{addr}/controller", "probe_config_set", $PDS,2);
	pdsDelete($PDS_OPTION);
	pdsDelete($PDS);

	return $RC;
}

sub updateSecondary {
	my ($self,$domain,$hubname,$hubrobot_name) = @_;

	my $PDS_CONFIG = pdsCreate();
	pdsPut_PCH($PDS_CONFIG, "/controller/secondary_domain", "$domain");
	pdsPut_PCH($PDS_CONFIG, "/controller/secondary_hub", "$hubname");
	pdsPut_PCH($PDS_CONFIG, "/controller/secondary_hubrobotname", "$hubrobot_name");
	pdsPut_PCH($PDS_CONFIG, "/controller/temporary_hub_broadcast","no");
	pdsPut_PCH($PDS_CONFIG, "/controller/secondary_hubip", "$hubrobot_name");
	pdsPut_PCH($PDS_CONFIG, "/controller/secondary_hubport", "48002");

	my $PDS = pdsCreate();
	pdsPut_PCH ($PDS,"name","controller");
	pdsPut_PDS ($PDS,"as_pds",$PDS_CONFIG);

	my ($RC, $O) = nimNamedRequest("$self->{addr}/controller", "probe_config_set", $PDS);
	pdsDelete($PDS);
	pdsDelete($PDS_CONFIG);

	return $RC;
}

sub setMaintenance {
	my ($self,$state,$time) = @_;
    my $OK = "no";
    if($state eq "actif" || $state eq "inactif") {
        $OK = "yes";
    }

    if($OK eq "yes") {
        if ($state eq "inactif") {
            my $PDS = pdsCreate();
            pdsPut_INT ($PDS,"for",$time || 31536000) ;
            pdsPut_INT ($PDS,"until",0) ;
            pdsPut_PCH ($PDS,"comment","AssetState = Not In Use");
            my ($RC, $OBJ) = nimNamedRequest("$self->{addr}/controller", "maint_until", $PDS);
            pdsDelete($PDS);
            return $RC;
        }
        elsif ($state eq "actif") {
            my $PDS = pdsCreate();
            pdsPut_INT ($PDS,"for",0) ;
            pdsPut_INT ($PDS,"until",0) ;
            pdsPut_PCH ($PDS,"comment","AssetState = In Use");
            my ($RC, $OBJ) = nimNamedRequest("$self->{addr}/controller", "maint_until", $PDS);
            pdsDelete($PDS);
            return $RC;
        }
    }
    else {
        return 1;
    }
}

sub moveRobot {
	my ($self,$domain,$source_hubname,$source_robot, $primary_hub, $primary_servername, $secondary_hub, $secondary_servername) = (@_);

    # Step 1
    {
        my $PDS_OPTION = pdsCreate();
        pdsPut_PCH($PDS_OPTION, "/controller/secondary_domain", $domain);
        pdsPut_PCH($PDS_OPTION, "/controller/secondary_hub", $secondary_hub);
        pdsPut_PCH($PDS_OPTION, "/controller/secondary_hubrobotname", $secondary_servername);
        pdsPut_PCH($PDS_OPTION, "/controller/temporary_hub_broadcast","no");
        pdsPut_PCH($PDS_OPTION, "/controller/secondary_hubip", $secondary_servername);
        pdsPut_PCH($PDS_OPTION, "/controller/secondary_hubport", "48002");
        pdsPut_PCH($PDS_OPTION, "/controller/secondary_hub_dns_name","");

        my $PDS_ARGS = pdsCreate();
        pdsPut_PCH ($PDS_ARGS,"name","controller");
        pdsPut_PDS ($PDS_ARGS,"as_pds",$PDS_OPTION);

        my ($RC, $O) = nimNamedRequest("/$domain/$source_hubname/$source_robot/controller", "probe_config_set", $PDS_ARGS);
        pdsDelete($PDS_OPTION);
        pdsDelete($PDS_ARGS);

        return $RC if $RC != NIME_OK;
    }

    # Step 2
    {
        my $PDS_ARGS = pdsCreate();
        pdsPut_PCH ($PDS_ARGS,"hubdomain",$domain);
        pdsPut_PCH ($PDS_ARGS,"hubname",$primary_hub);
        pdsPut_PCH ($PDS_ARGS, "hubip", $primary_servername);
        pdsPut_PCH ($PDS_ARGS, "hubport", "");
        pdsPut_PCH ($PDS_ARGS, "hub_dns_name",$primary_servername);
        pdsPut_PCH ($PDS_ARGS, "robotip_alias", "");

        my ($RC, $OBJ) = nimNamedRequest("/$domain/$source_hubname/$source_robot/controller", "sethub", $PDS_ARGS);

        return $RC;
    }
}

sub cacheClean {
    my ($self) = @_;
    my $PDS = pdsCreate();
    pdsPut_PCH ($PDS,"robot",$self->{name});
    my ($RC,$OBJ) = nimNamedRequest( "$self->{addr}/controller", "_nis_cache_clean",$PDS,2);
    pdsDelete($PDS);
    return $RC;
}

sub local_cacheClean {
    my ($self) = @_;
    my $PDS = pdsCreate();
    pdsPut_PCH ($PDS,"robot",$self->{name});
    my ($RC,$OBJ) = nimRequest( "$self->{name}",48000, "_nis_cache_clean",$PDS);
    pdsDelete($PDS);
    return $RC;
}

1;
