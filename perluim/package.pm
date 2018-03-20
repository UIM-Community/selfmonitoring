use strict;
use warnings;

# Namespace
package perluim::package;

# Nimsoft librairies !
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

sub new {
    my ($class,$o) = @_;
    my $this = {
        name            => $o->get("name"),
        description     => $o->get("description") || "",
        version         => $o->get("version") || "",
        build           => $o->get("build") || "",
        date            => $o->get("date") || "",
        install_date    => $o->get("install_date"),
        valid           => 1
    };
    return bless($this,ref($class) || $class);
}

sub setValid {
    my ($self,$vInt) = @_;
    $self->{valid} = $vInt;
}


1;
