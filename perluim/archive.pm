package perluim::archive;

# Nimsoft librairies !
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

use perluim::package;

sub new {
    my ($class,$hub,$probePort) = @_;
    my $this = {
        hub => $hub,
        cleanAddr => substr($hub->{addr},0,-4),
        cb_support => "ade",
        robotname => $hub->{robotname},
        probePort => $probePort
    };
    return bless($this,ref($class) || $class);
}

sub getPackages {
    my ($self,$name,$version,$distsrv) = @_;
    my $PDS = pdsCreate();
    if(defined($name)) {
        pdsPut_PCH($PDS,"name","$name");
    }
    if(defined($version)) {
        pdsPut_PCH($PDS,"version","$version");
    }
    if($self->{cb_support} eq "distsrv" or $distsrv) {
        pdsPut_INT($PDS,"detail_level",1);
    }
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{cleanAddr}/automated_deployment_engine","archive_list",$PDS);
    pdsDelete($PDS);

    my %PackagesList = ();
    if($RC == NIME_OK) {
        my $PKG_PDS = Nimbus::PDS->new($NMS_RES);
        for( my $count = 0; my $PKG_INFO = $PKG_PDS->getTable("entry",PDS_PDS,$count); $count++) {
            my $PKG = new perluim::package($PKG_INFO);
            if(defined($PKG->{version}) && $PKG->{version} ne "") {
                $PackagesList{"$PKG->{name}_$PKG->{version}_$PKG->{build}"} = $PKG;
            }
            else {
                $PKG->setValid(0);
                $PackagesList{"$PKG->{name}_NV"} = $PKG;
            }
        }
        return $RC,%PackagesList;
    }
    else {
        return $RC,%PackagesList;
    }
}

sub local_getPackages {
    my ($self,$name,$version,$distsrv) = @_;
    if(defined $self->{probePort}) {
        my $PDS = pdsCreate();
        if(defined($name)) {
            pdsPut_PCH($PDS,"name","$name");
        }
        if(defined($version)) {
            pdsPut_PCH($PDS,"version","$version");
        }
        if($self->{cb_support} eq "distsrv" or $distsrv) {
            pdsPut_INT($PDS,"detail_level",1);
        }
        my ($RC,$NMS_RES) = nimRequest("$self->{robotname}",$self->{probePort},"archive_list",$PDS);
        pdsDelete($PDS);

        my %PackagesList = ();
        if($RC == NIME_OK) {
            my $PKG_PDS = Nimbus::PDS->new($NMS_RES);
            for( my $count = 0; my $PKG_INFO = $PKG_PDS->getTable("entry",PDS_PDS,$count); $count++) {
                my $PKG = new perluim::package($PKG_INFO);
                if(defined($PKG->{version}) && $PKG->{version} ne "") {
                    $PackagesList{"$PKG->{name}_$PKG->{version}_$PKG->{build}"} = $PKG;
                }
                else {
                    $PKG->setValid(0);
                    $PackagesList{"$PKG->{name}_NV"} = $PKG;
                }
            }
            return $RC,%PackagesList;
        }
        else {
            return $RC,%PackagesList;
        }
    }
    return 1,undef;
}

sub ade_addPackageSyncRule {
    my ($self,$pkg) = @_;
    my $PDS = pdsCreate();
    pdsPut_PCH ($PDS,"name",$pkg->{name});
    pdsPut_PCH ($PDS,"rule_type","ALL");
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{cleanAddr}/automated_deployment_engine","add_package_sync_rule",$PDS);
    pdsDelete($PDS);
    return $RC;
}

sub local_ade_addPackageSyncRule {
    my ($self,$pkg) = @_;
    if(defined $self->{probePort}) {
        my $PDS = pdsCreate();
        pdsPut_PCH ($PDS,"name",$pkg->{name});
        pdsPut_PCH ($PDS,"rule_type","ALL");
        my ($RC,$NMS_RES) = nimRequest("$self->{robotname}",$self->{probePort},"add_package_sync_rule",$PDS);
        pdsDelete($PDS);
        return $RC;
    }
    return 1;
}

sub deletePackage {
    my ($self,$pkg) = @_;
    my $PDS = pdsCreate();
    pdsPut_PCH($PDS,"name","$pkg->{name}");
    pdsPut_PCH($PDS,"version","$pkg->{version}");
    my ($RC,$NMS_RES) = nimNamedRequest("$self->{cleanAddr}/automated_deployment_engine","archive_delete",$PDS);
    pdsDelete($PDS);
    return $RC;
}

sub local_deletePackage {
    my ($self,$pkg) = @_;
     if(defined $self->{probePort}) {
         my $PDS = pdsCreate();
        pdsPut_PCH($PDS,"name","$pkg->{name}");
        pdsPut_PCH($PDS,"version","$pkg->{version}");
        my ($RC,$NMS_RES) = nimNamedRequest("$self->{cleanAddr}/automated_deployment_engine","archive_delete",$PDS);
        pdsDelete($PDS);
        return $RC;
    }
    return 1;
}

1;
