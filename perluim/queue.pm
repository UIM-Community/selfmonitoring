use strict;
use warnings;
package perluim::queue;

sub new {
    my ($class,$o) = @_;
    my $this = {
        section => $o->{"__section"},
        active => $o->{"active"},
        type => $o->{"type"},
        subject => $o->{"subject"},
        addr => $o->{"addr"},
        bulk_size => $o->{"bulk_size"}
    };
    return bless($this,ref($class) || $class);
}

1;
