# use dependencies
use strict;
use warnings;
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Data::Dumper;
use Nimbus::API;
use Nimbus::CFG;
use Nimbus::PDS;
use perluim::log;
use perluim::main;
use perluim::alarmsmanager;
use perluim::utils;
use perluim::file;
use perluim::dtsrvjob;
use POSIX qw( strftime );
use Time::Piece;

#
# Declare default script variables & declare log class.
#
my $time = time();
my $version = "1.0";
my ($Console,$SDK,$Execution_Date,$Final_directory);
$Execution_Date = perluim::utils::getDate();
$Console = new perluim::log('selfmonitoring.log',5,0,'yes');

# Handle critical errors & signals!
$SIG{__DIE__} = \&trap_die;
$SIG{INT} = \&breakApplication;

# Start logging
$Console->print('---------------------------------------',5);
$Console->print('Selfmonitoring started at '.localtime(),5);
$Console->print("Version $version",5);
$Console->print('---------------------------------------',5);

#
# Open and append configuration variables
#
my $CFG                 = Nimbus::CFG->new("selfmonitoring.cfg");
my $Domain              = $CFG->{"setup"}->{"domain"} || undef;
my $Cache_delay         = $CFG->{"setup"}->{"output_cache_time"} || 432000;
my $Audit               = $CFG->{"setup"}->{"audit"} || 0;
my $Output_directory    = $CFG->{"setup"}->{"output_directory"} || "output";
my $retry_count         = $CFG->{"setup"}->{"callback_retry_count"} || 3;
my $Login               = $CFG->{"setup"}->{"nim_login"} || undef;
my $Password            = $CFG->{"setup"}->{"nim_password"} || undef;
my $GO_Intermediate     = $CFG->{"configuration"}->{"alarms"}->{"intermediate"} || 0;
my $GO_Spooler          = $CFG->{"configuration"}->{"alarms"}->{"spooler"} || 0;
my $Check_NisBridge     = $CFG->{"configuration"}->{"check_nisbridge"} || "no";
my $Overwrite_HA        = $CFG->{"configuration"}->{"priority_on_ha"} || "no";
my $Checkuptime         = $CFG->{"configuration"}->{"check_hubuptime"} || "no";
my $Uptime_value        = $CFG->{"configuration"}->{"uptime_seconds"} || 600;
my $probes_mon          = 0;
my $ump_mon             = 0;
my @UMPServers;
my $ump_alarm_callback;
my $ump_alarm_probelist;
if(defined $CFG->{"ump_monitoring"}) {
    @UMPServers          = split(',',$CFG->{"ump_monitoring"}->{"servers"});
    $ump_alarm_callback  = $CFG->{"ump_monitoring"}->{"alarm_callback"} || "ump_failcallback";
    $ump_alarm_probelist = $CFG->{"ump_monitoring"}->{"alarm_probelist"} || "ump_probelist_fail";
    if(scalar @UMPServers > 0) {
        $ump_mon = 1;
    }
}
my $deployment_mon = "no";
my $deployment_maxtime;
my $deployment_maxjobs;
if(defined $CFG->{"deployment_monitoring"}) {
    $deployment_mon = "yes"; 
    $deployment_maxtime = $CFG->{"deployment_monitoring"}->{"job_time_threshold"} || 600; 
    $deployment_maxjobs = $CFG->{"deployment_monitoring"}->{"max_jobs"} || 2000;
}

# Declare alarms_manager
my $alarm_manager = new perluim::alarmsmanager($CFG,"alarm_messages");

# Check if domain is correctly configured
if(not defined($Domain)) {
    trap_die('Domain is not declared in the configuration file!');
    exit(1);
}

#
# Print configuration file
#
$Console->print("Print configuration setup section : ",5);
foreach($CFG->getKeys($CFG->{"setup"})) {
    $Console->print("Configuration : $_ => $CFG->{setup}->{$_}",5);
}
$Console->print('---------------------------------------',5);

#
# Retrieve all probes with the callback
#
my %ProbeCallback   = (); 
if(defined($CFG->{"probes_monitoring"}) and scalar keys $CFG->{"probes_monitoring"} > 0) {
    $probes_mon = 1;
    foreach my $key (keys $CFG->{"probes_monitoring"}) {
        my $callback        = $CFG->{"probes_monitoring"}->{"$key"}->{"callback"};
        my $find            = $CFG->{"probes_monitoring"}->{"$key"}->{"check_keys"};
        my $alarms          = $CFG->{"probes_monitoring"}->{"$key"}->{"alarm_on_probe_deactivated"} || 0;
        my $ha_superiority  = $CFG->{"probes_monitoring"}->{"$key"}->{"ha_superiority"} || "yes";
        my $check_alarmName;
        if(defined($find)) {
            $check_alarmName = $CFG->{"probes_monitoring"}->{"$key"}->{"check_alarm_name"};
        }
        $ProbeCallback{"$key"} = { 
            callback => $callback,
            alarms => $alarms,
            ha_superiority => $ha_superiority,
            find => $find,
            check_alarmName => $check_alarmName
        };
    }
}

#
# nimLogin if login and password are defined in the configuration!
#
nimLogin($Login,$Password) if defined($Login) && defined($Password);

#
# Declare framework, create / clean output directory.
# 
$SDK                = new perluim::main("$Domain");
$Final_directory    = "$Output_directory/$Execution_Date";
perluim::utils::createDirectory("$Output_directory/$Execution_Date");
$Console->cleanDirectory("$Output_directory",$Cache_delay);

#
# Main method to call for the script ! 
# main();
# executed at the bottom of this script.
# 
sub main {

    my ($RC,$hub) = $SDK->getLocalHub();
    if($RC == NIME_OK) {
        $Console->print("Start processing $hub->{name} !!!",5);
        $Console->print('---------------------------------------',5);

        if($Checkuptime eq "yes") {
            $Console->print("Check hub uptime !");
            if($hub->{uptime} <= $Uptime_value) {
                $Console->print("Uptime is under the threshold of $Uptime_value",2);
                my $hub_restart = $alarm_manager->get('hub_restart');
                my ($RC,$AlarmID) = $hub_restart->call({ 
                    second => "$Uptime_value",
                    hubName => "$hub->{name}"
                });

                if($RC == NIME_OK) {
                    $Console->print("Alarm generated : $AlarmID - [$hub_restart->{severity}] - $hub_restart->{subsystem}");
                }
                else {
                    $Console->print("Failed to create alarm!",1);
                }
            }
            $Console->print('---------------------------------------',5);
        }

        #
        # local_probeList(); , retrive all probes from remote hub.
        #
        { # Memory optimization 
            my $trycount = $retry_count; # Get configuration max_retry for probeList method.
            my $success = 0;

            # Retry to execute probeList multiple times if RC != NIME_OK.
            WH: while($trycount--) {
                my $echotry = 3 - $trycount; # Reverse number
                $Console->print("Execute local_probeList() , try n'$echotry");
                if( checkProbes($hub) ) {
                    $success = 1;
                    last WH; # Kill retry while.
                }
                $| = 1; # Buffer I/O fix
                $SDK->doSleep(3); # Pause script for 3 seconds.
            }

            # Final success condition (if all try are failed!).
            $Console->print("Failed to execute local_probeList()",1) if not $success;
        }

        #
        # getLocalRobots() , retrieve all robots from remote hub.
        #
        if($GO_Intermediate or $GO_Spooler) { # Memory optimization

            my $trycount = $retry_count; # Get configuration max_retry for probeList method.
            my $success = 0;

            WH: while($trycount--) {
                my $echotry = 3 - $trycount; # Reverse number
                $Console->print("Execute getLocalRobots() , try n'$echotry");
                if( checkRobots($hub) ) {
                    $success = 1;
                    last WH; # Kill retry while.
                }
                $| = 1; # Buffer I/O fix
                $SDK->doSleep(3); # Pause script for 3 seconds.
            }

            # Final success condition (when all callback are failed).
            $Console->print("Failed to execute getLocalRobots()",1) if not $success;
        }

        # UMP Monitoring
        if($ump_mon) {
            $Console->print("Start monitoring of UMP Servers.."); 
            $Console->print("Servers to check : @UMPServers");
            checkUMP($hub);
        }
         
        return 1;
    }
    else {
        $Console->print('Failed to get hub',0);
        return 0;
    }
}

#
# Method to check all the robots from a specific hub object.
# checkRobots($hub);
# used in main() method.
# 
sub checkRobots {
    my ($hub) = @_;

    my ($RC,@RobotsList) = $hub->getLocalRobots();
    if($RC == NIME_OK) {

        # Create array 
        my @Arr_intermediateRobots = ();
        my @Arr_spooler = (); 
        my %Stats = (
            intermediate => 0,
            spooler => 0
        );

        $Console->print("Starting robots with Intermediate => $GO_Intermediate and Spooler => $GO_Spooler",5);
        $Console->print('---------------------------------------',5);

        # Foreach robots
        foreach my $robot (@RobotsList) {
            next if "$robot->{status}" eq "2";

            if("$robot->{status}" eq "1") {
                push(@Arr_intermediateRobots,"$robot->{name}");
                $Stats{intermediate}++;

                if($GO_Intermediate && not $Audit) {
                    # Create new alarm!
                    my $intermediate_robot = $alarm_manager->get('intermediate_robot');
                    my ($RC_ALARM,$AlarmID) = $intermediate_robot->call({ 
                        robotname => "$robot->{name}", 
                        hubname => "$hub->{name}"
                    });

                    if($RC_ALARM == NIME_OK) {
                        $Console->print("Alarm generated : $AlarmID - [$intermediate_robot->{severity}] - $intermediate_robot->{subsystem}");
                    }
                    else {
                        $Console->print("Failed to create alarm!",1);
                    }
                }
            }

            if($GO_Spooler) {
                # Callback spooler!
                my $S_RC = spoolerCallback($robot->{name});
                if($S_RC != NIME_OK) {
                    push(@Arr_spooler,"$robot->{name}");
                    $Stats{spooler}++;

                    if(not $Audit) {
                        # Generate alarm!
                        my $spooler_fail = $alarm_manager->get('spooler_fail');
                        my ($RC_ALARM,$AlarmID) = $spooler_fail->call({ 
                            robotname => "$robot->{name}", 
                            rc => "$S_RC"
                        });

                        if($RC_ALARM == NIME_OK) {
                            $Console->print("Alarm generated : $AlarmID - [$spooler_fail->{severity}] - $spooler_fail->{subsystem}");
                        }
                        else {
                            $Console->print("Failed to create alarm!",1);
                        }
                    }
                }
            }

        }

        $Console->print('---------------------------------------',5);
        $Console->print('Final statistiques :',5);
        foreach(keys %Stats) {
            $Console->print("$_ => $Stats{$_}");
        }

        # Write file to the disk.
        $Console->print("Write output files to the disk..");
        new perluim::file()->save("output/$Execution_Date/intermediate_servers.txt",\@Arr_intermediateRobots);
        new perluim::file()->save("output/$Execution_Date/failedspooler_servers.txt",\@Arr_spooler);

        $Console->print('---------------------------------------',5);

        return 1;
    }
    else {
        $Console->print('Failed to get robotslist from hub',0);
        return 0;
    }
}

#
# send get_info callback to spooler probe.
# spoolerCallback($robotname);
# used in checkRobots() method.
# 
sub spoolerCallback {
    my $robot_name = shift;
    my $PDS = pdsCreate();
    $Console->print("nimRequest : $robot_name - 48001 - get_info",4);
    my ($RC,$RES) = nimRequest("$robot_name",48001,"get_info",$PDS);
    pdsDelete($PDS);
    return $RC;
}

#
# Method to check all the probes from a specific hub object.
# checkProbes($hub);
# used in main() method.
# 
sub checkProbes {
    my ($hub) = @_;
    my ($RC,@ProbesList) = $hub->local_probeList();
    if($RC == NIME_OK) {
        $Console->print("hub->ProbeList() has been executed successfully!");
        my $find_nas = 0;
        my $find_ha = 0;
        my $find_distsrv = 0;
        my $distsrv_port; 
        my $ha_port;

        #
        # First while to find NAS and HA Probe
        #
        foreach my $probe (@ProbesList) {
            if($probe->{name} eq "nas") {
                $find_nas = 1;
            }
            elsif($probe->{name} eq "HA") {
                $find_ha = 1;
                $ha_port = $probe->{port}; # Get HA port because it's dynamic
            }
            elsif($probe->{name} eq "distsrv") {
                $find_distsrv = 1; 
                $distsrv_port = $probe->{port};
            }   
        }

        #
        # If HA is here, find the status
        #
        my $ha_value;
        if($find_ha) {
            my $PDS = pdsCreate();
            $Console->print("nimRequest : $hub->{robotname} - HA - get_status",4);
            my ($RC,$RES) = nimRequest("$hub->{robotname}",$ha_port,"get_status",$PDS);
            pdsDelete($PDS);

            if($RC == NIME_OK) {
                $ha_value = (Nimbus::PDS->new($RES))->get("connected");
                $Console->print("Successfully retrived HA connected value => $ha_value");
            }
            else {
                $Console->print("Failed to get HA status!",1);
                $find_ha = 0;
            }
        }
        undef $ha_port;


        if($probes_mon) {
            # While all probes retrieving 
            foreach my $probe (@ProbesList) {

                # Verify if we have to check this probe or not!
                if(exists( $ProbeCallback{$probe->{name}} )) {

                    $Console->print('---------------------------------------',5);
                    $Console->print("Prepare checkup for $probe->{name}, Active => $probe->{active}");
                    my $callback        = $ProbeCallback{$probe->{name}}{callback};
                    my $callAlarms      = $ProbeCallback{$probe->{name}}{alarms};
                    my $ha_superiority  = $ProbeCallback{$probe->{name}}{ha_superiority};
                    my $find            = $ProbeCallback{$probe->{name}}{find};
                    my $check_alarmName = $ProbeCallback{$probe->{name}}{check_alarmName};

                    # Verify if the probe is active or not!
                    if($probe->{active} == 1) {
                        if(defined($callback)) {
                            doCallback($hub->{robotname},$hub->{name},$probe->{name},$probe->{port},$callback,$find,$check_alarmName) if not $Audit;
                        }
                        else {
                            $Console->print("Callback is not defined!");
                        }
                    }
                    else {

                        # Verify we have the right to launch a alarm.
                        # Note, if Overwrite_HA is set to yes and we are on a HA situation, the alarms key is overwrited.
                        if(not $Audit and $callAlarms or ($find_ha and $Overwrite_HA eq "yes" and "$ha_value" eq "0" and $ha_superiority eq "yes" ) ) {
                            $Console->print("Probe is inactive, generate new alarm!",2);
                            my $probe_offline = $alarm_manager->get('probe_offline');
                            my ($RC_ALARM,$AlarmID) = $probe_offline->call({ 
                                probe => "$probe->{name}", 
                                hubname => "$hub->{name}"
                            });

                            if($RC_ALARM == NIME_OK) {
                                $Console->print("Alarm generated : $AlarmID - [$probe_offline->{severity}] - $probe_offline->{subsystem}");
                            }
                            else {
                                $Console->print("Failed to create alarm!",1);
                            }
                            
                        }
                        else {
                            $Console->print("Probe is inactive !");
                        }

                    }

                }
            }
        }

        if($find_nas && $Check_NisBridge eq "yes") {
            $Console->print('---------------------------------------',5);
            $Console->print('Checkup NisBridge configuration');
            checkNisBridge($hub->{robotname},$hub->{name},$find_ha,$ha_value);
        }

        if($find_distsrv && $deployment_mon eq "yes") {
            $Console->print('---------------------------------------',5);
            $Console->print('Checkup Distsrv jobs!');
            checkDistsrv($hub,$distsrv_port);
            $Console->print('---------------------------------------',5);
        }

        return 1;
    }
    return 0;
}

# 
# String strBeginWith($str,$expected);
# used in doCallback();
#
sub strBeginWith {
    return substr($_[0], 0, length($_[1])) eq $_[1];
}

#
# Method to do a callback on a specific probe.
# doCallback($robotname,$probeName,$probePort,$callback,$find)
# used in checkProbes() method.
# 
sub doCallback {
    my ($robotname,$hubname,$probeName,$probePort,$callback,$check_keys,$check_alarmName) = @_;
    my $PDS = pdsCreate();

    # Special rule for NAS only!
    if(uc $probeName eq "NAS") {
        pdsPut_INT($PDS,"detail",1);
    }

    $Console->print("nimRequest : $robotname - $probePort - $callback",4);
    my ($CALLBACK_RC,$RES) = nimRequest("$robotname",$probePort,"$callback",$PDS);
    pdsDelete($PDS);

    $Console->print("Return code : $CALLBACK_RC",4);
    if($CALLBACK_RC != NIME_OK) {

        $Console->print("Return code is not OK ! Generating a alarm.",2);
        my $callback_fail = $alarm_manager->get('callback_fail');
        my ($RC,$AlarmID) = $callback_fail->call({ 
            callback => "$callback", 
            probe => "$probeName", 
            hubname => "$hubname",
            port => "$probePort"
        });

        if($RC == NIME_OK) {
            $Console->print("Alarm generated : $AlarmID - [$callback_fail->{severity}] - $callback_fail->{subsystem}");
        }
        else {
            $Console->print("Failed to create alarm!",1);
        }
    }
    else {
        if(defined($check_keys)) {
            $Console->print("doCallback: Entering into check_keys");
            my $key_ok = 0;
            my $object_value;
            my $expected_value;
            foreach (keys $check_keys) {
                my $type = ref($check_keys->{$_});

                if($type eq "HASH") {
                    my $PDS = Nimbus::PDS->new($RES);
                    my $count = 0;
                    WONE: for(; my $OInfo = $PDS->getTable("$_",PDS_PDS,$count); $count++) {

                        foreach my $id (keys $check_keys->{$_}) {

                            my $match_all_key = 1;
                            WTWO: foreach my $sec_key (keys $check_keys->{$_}->{$id}) {
                                $object_value    = $OInfo->get("$sec_key");
                                $expected_value  = $check_keys->{$_}->{$id}->{$sec_key};
                                next if not defined($object_value);

                                my $strBegin = strBeginWith($expected_value,"<<");
                                my $condition = $strBegin ? $object_value <= substr($expected_value,2) : $object_value eq $expected_value;

                                if(not $condition) {
                                    $match_all_key = 0;
                                    last WTWO;
                                }

                            }

                            if($match_all_key) {
                                $key_ok = 1;
                                last WONE;
                            }

                        }
                        
                    }
                }
                else {
                    my $value = (Nimbus::PDS->new($RES))->get("$_");
                    if(defined($value) and $value == $check_keys->{$_}) {
                        $key_ok = 1;
                    }
                }

            }
            $Console->print("doCallback: exit check_keys with RC => $key_ok",2);

            if(not $key_ok and not $Audit && defined($check_alarmName)) {
                # Generate alarm!
                $Console->print("doCallback: Generate a new check_configuration alarm!");
                my $customAlarm = $alarm_manager->get("$check_alarmName");
                my ($RC,$AlarmID) = $customAlarm->call({ 
                    robotname => "$robotname",
                    hubname => "$hubname"
                });

                if($RC == NIME_OK) {
                    $Console->print("Alarm generated : $AlarmID - [$customAlarm->{severity}] - $customAlarm->{subsystem}");
                }
                else {
                    $Console->print("Failed to create alarm!",1);
                }
            }
        }
    }
}

#
# retrieve nis_bridge key in NAS and return it.
# checkNisBridge($robotname,$hubname,$ha,$ha_value)
# used in checkProbes() method
#
sub checkNisBridge {
    my ($robotname,$hubname,$ha,$ha_value) = @_; 
    my $nis_value;

    # Generate alarm variable!
    my $generate_alarm = 1;
    {
        $Console->print("nimRequest : $robotname - 48000 - probe_config_get",4);
        my $pds = new Nimbus::PDS();
        $pds->put('name','nas',PDS_PCH);
        $pds->put('var','/setup/nis_bridge',PDS_PCH);
        my ($RC,$RES) = nimRequest("$robotname",48000,"probe_config_get",$pds->data());

        if($RC == NIME_OK) {
            $nis_value = (Nimbus::PDS->new($RES))->get("value");
            if($ha) {
                if ( (not $ha_value and $nis_value eq "yes") || ($ha_value and $nis_value eq "no") ) {
                    $generate_alarm = 0;
                }
            }
            else {
                if($nis_value eq "yes") {
                    $generate_alarm = 0;
                }
            }
        }
        else {
            # TODO : Generate another alarm ?
            $Console->print("Failed to get nis_bridge configuration with RC $RC!",1);
            return;
        }
    }

    # Generate alarm
    if($generate_alarm) {
        $Console->print("Generating new alarm for NIS_Bridge",2);
        $Console->print("Nis_bridge => $nis_value",4);
        $Console->print("HA connected => $ha_value",4);
        my $nis_alarm = $alarm_manager->get('nisbridge');
        my ($RC,$AlarmID) = $nis_alarm->call({ 
            robotname => "$robotname", 
            hubname => "$hubname",
            nis => "$nis_value",
            ha => "$ha_value"
        });

        if($RC == NIME_OK) {
            $Console->print("Alarm generated : $AlarmID - [$nis_alarm->{severity}] - $nis_alarm->{subsystem}");
        }
        else {
            $Console->print("Failed to create alarm!",1);
        }
    }
    else {
        $Console->print("Nis_bridge ... OK!");
    }
}

# 
# Check all distsrv jobs !
# checkDistsrv($hub)
# used in main() method
#
sub checkDistsrv {
    my ($hub,$distsrv_port) = @_; 

    my $pds = pdsCreate(); 
    my ($RC,$RES) = nimRequest($hub->{robotname},$distsrv_port,"job_list",$pds);
    pdsDelete($pds); 

    if($RC == NIME_OK) {

        my $JOB_PDS = Nimbus::PDS->new($RES);
        my $count;
        for( $count = 0; my $JobNFO = $JOB_PDS->getTable("entry",PDS_PDS,$count); $count++) {
            my $Job = new perluim::dtsrvjob($JobNFO);
            $Console->print("Processing Job number $count");
            next if $Job->{status} eq "finished";

            my $date1;
            {
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($Job->{time_started});
                $year+= 1900;
                $date1 = sprintf("%02d:%02d:%02d %02d:%02d:%02d",$year,($mon+1),$mday,$hour,$min,$sec);
            }

            my $date2;
            {
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
                $year+= 1900;
                $date2 = sprintf("%02d:%02d:%02d %02d:%02d:%02d",$year,($mon+1),$mday,$hour,$min,$sec);
            }
            my $format = '%Y:%m:%d %H:%M:%S';
            my $diff = Time::Piece->strptime($date2, $format) - Time::Piece->strptime($date1, $format);
            if($diff > $deployment_maxtime and not $Audit) {
                my $distsrv_deployment = $alarm_manager->get("distsrv_deployment");
                my ($RC_ALARM,$AlarmID) = $distsrv_deployment->call({ 
                    jobid => "$Job->{job_id}",
                    pkgName => "$Job->{package_name}",
                    started => "$Job->{time_started}",
                    diff => "$diff",
                    probe => "distsrv",
                    hubname => "$hub->{name}",
                    robotName => "$hub->{robotname}"
                });

                if($RC_ALARM == NIME_OK) {
                    $Console->print("Alarm generated : $AlarmID - [$distsrv_deployment->{severity}] - $distsrv_deployment->{subsystem}");
                }
                else {
                    $Console->print("Failed to create alarm!",1);
                }
            }
        }

        if($count >= $deployment_maxjobs and not $Audit) {
            $Console->print("Max jobs count reached!");
            my $distsrv_maxjobs = $alarm_manager->get("distsrv_maxjobs");
            my ($RC_ALARM,$AlarmID) = $distsrv_maxjobs->call({ 
                max => "$deployment_maxjobs",
                count => "$count",
                probe => "distsrv",
                hubname => "$hub->{name}",
                robotName => "$hub->{robotname}"
            });

            if($RC_ALARM == NIME_OK) {
                $Console->print("Alarm generated : $AlarmID - [$distsrv_maxjobs->{severity}] - $distsrv_maxjobs->{subsystem}");
            }
            else {
                $Console->print("Failed to create alarm!",1);
            }
        }

    }
    else {
        if(not $Audit) {
            my $callback_fail = $alarm_manager->get("callback_fail");
            my ($RC_ALARM,$AlarmID) = $callback_fail->call({ 
                callback => "job_list",
                probe => "distsrv",
                hubname => "$hub->{name}"
            });

            if($RC_ALARM == NIME_OK) {
                $Console->print("Alarm generated : $AlarmID - [$callback_fail->{severity}] - $callback_fail->{subsystem}");
            }
            else {
                $Console->print("Failed to create alarm!",1);
            }
        }
    }
}

# 
# Check all Wasp probes from UMP Servers.
# checkUMP($hub)
# used in main() method
#
sub checkUMP {
    my ($hub) = @_;
    foreach(@UMPServers) {
        $Console->print("Processing check on ump $_"); 

        my $ERR = 0;
        my $pds = new Nimbus::PDS();
        $pds->put('name','wasp',PDS_PCH);
        my ($RC,$RES) = nimRequest("$_",48000,"probe_list",$pds->data());
        if($RC == NIME_OK) {
            $Console->print("Callback probe_list executed succesfully!");
            my $hash = Nimbus::PDS->new($RES)->asHash();

            my $pds_ump = new Nimbus::PDS();
            ($RC,$RES) = nimRequest("$_",$hash->{"wasp"}->{"port"},"get_info",$pds_ump->data());
            if($RC != NIME_OK && not $Audit) {
                $Console->print("Failed to execute callback get_info on wasp probe on $_",1);
                my $ump_failcallback = $alarm_manager->get("$ump_alarm_callback");
                my ($RC_ALARM,$AlarmID) = $ump_failcallback->call({ 
                    umpName => "$_"
                });

                if($RC_ALARM == NIME_OK) {
                    $Console->print("Alarm generated : $AlarmID - [$ump_failcallback->{severity}] - $ump_failcallback->{subsystem}");
                }
                else {
                    $Console->print("Failed to create alarm!",1);
                }
            }
            else {
                $Console->print("Callback get_info return ok...");
            }
        }
        else {
            $Console->print("Failed to execute callback probe_list on ump $_",1);
            if(not $Audit) {
                my $ump_probelist_fail = $alarm_manager->get("$ump_alarm_probelist");
                my ($RC_ALARM,$AlarmID) = $ump_probelist_fail->call({ 
                    umpName => "$_"
                });

                if($RC_ALARM == NIME_OK) {
                    $Console->print("Alarm generated : $AlarmID - [$ump_probelist_fail->{severity}] - $ump_probelist_fail->{subsystem}");
                }
                else {
                    $Console->print("Failed to create alarm!",1);
                }
            }
        }

    }
}

#
# Die method
# trap_die($error_message)
# 
sub trap_die {
    my ($err) = @_;
	$Console->print("Program is exiting abnormally : $err",0);
    $| = 1; # Buffer I/O fix
    sleep(2);
    $Console->copyTo("output/$Execution_Date");
}

#
# When application is breaked with CTRL+C
#
sub breakApplication { 
    $Console->print("\n\n Application breaked with CTRL+C \n\n",0);
    $| = 1; # Buffer I/O fix
    sleep(2);
    $Console->copyTo("output/$Execution_Date");
    exit(1);
}

# Call the main method 
main();

$Console->finalTime($time);
$| = 1; # Buffer I/O fix
sleep(2);
$Console->copyTo($Final_directory);
$Console->close();
