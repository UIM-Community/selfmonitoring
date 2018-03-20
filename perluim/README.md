# Perluim
CA UIM perl object-oriented framework.

> Warning : Think to update librairies path in each .pm file.

This framework has been created to help developer to work with the Perl SDK of CA UIM. It bring to you a default OO structure with a lot of callback or generic and useful methods.

# Probes 

##### R2.0
- Selfmonitoring    - [Link](https://github.com/fraxken/selfmonitoring)
- Archive_cleaner   - [Link](https://github.com/fraxken/archive_cleaner)
- Robots_checker    - [Link](https://github.com/fraxken/robots_checker/tree/master)
- Alarms_management - [Link](https://github.com/fraxken/Alarms_management)
- Netconnect_ha     - [Link](https://github.com/fraxken/netconnect_ha)
- Archive_inventory - [Link](https://github.com/fraxken/archive_inventory)
- ump_management    - [Link](https://github.com/fraxken/ump_management) (Rework of UMP_ha 3). 

> Warning : Use the release R2.0, dont use latest commits that correspond to the release 3.0

##### R3.0 (pre-release) 

- Keyreplacer - [Link](https://github.com/fraxken/keyreplacer)

# Probes comming 

- ADE_Deployment (automatic deployment with ADE) 
- Checkconfig3 - Rework with perluim.
- Checkconfig4 - Rework of checkconfig2 with perluim. 

# Introduction 

```perl
use perluim::main;
use perluim::log;

my ($Console,$ScriptExecutionTime,$SDK,Execution_Date);

$Console = new perluim::log("test_probe.log");
$ScriptExecutionTime = time();
$Console->print("Execution start at ".localtime(),5);
$Console->setLevel(3);

$Console->print("Instanciating perluim framework!",3);
$SDK = new perluim::main("DOMAIN-PROD");
$SDK->setLog($Console);
$Console->print("Create output directory.");
$Execution_Date = $SDK->getDate();
$SDK->createDirectory("output/$Execution_Date");
```

### Get robots or hubs 
```perl
my ($RC,@Hubs) = $SDK->getArrayHubs();
if($RC == NIME_OK) {
    foreach my $hub (@Hubs) {
        # Hub is perluim:hub class
        my @Robots $hub->getArrayRobots();
    }
}


# Or if you need directly all robots 
my %Robots = $SDK->getAllRobots(); # Key = robotname, value = class robot
```

### Get archive packages from hubs 
```perl
my ($RC,@Hubs) = $SDK->getArrayHubs();
if($RC == NIME_OK) {
    foreach my $hub (@Hubs) {
        # Hub is perluim:hub class
        my $archive = $hub->archive();
        my ($RC,@Packages) = $archive->getPackages();
        if($RC == NIME_OK) {
            # Exploit packages class here!
            # Delete package ?
            foreach my $pkg (@Packages) {
                my $rc_deleted = $archive->deletePackage($pkg);
                if($rc_deleted == NIME_OK) {
                    $Console->print("$pkg->{name} successfully deleted from hub $hub->{name}");
                }
            }
        }
    }
}
```

Find documentation API [Here](https://github.com/fraxken/perluim/wiki)

# Features 

- Default structure (need to work on deamon)
- Actions on hubs/robots/probes/packages
- First step to work with UIM Rest (Need more work on this part..) 
- Better logs

> Feel free to pull-request a new class etc...

# Roadmap for next releases

- Support bridge for session probe
- Starter guide (P1)
- Implement latest missing features.
