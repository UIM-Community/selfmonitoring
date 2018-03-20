use strict;
use warnings;
use HTTP::Request;
use LWP::UserAgent;

package perluim::ump;

sub new {
    my ($class,@ump_servers) = @_;
    my $this = {
        active => undef,
        pool => \@ump_servers
    };
    my $blessed = bless($this,ref($class) || $class);
    return $blessed;
}

sub checkPool {
    my ($self,$login,$password) = @_;
    my $RC = 1;
    if(scalar $self->{pool} == 1) {
        $self->{active} = @{$self->{pool}}[0];
    }
    elsif(scalar $self->{pool} == 0) {
        return 0;
    }
    else {
        foreach my $umpAddr (@{$self->{pool}}) {
            my $request = HTTP::Request->new(GET => "$umpAddr/rest/version-info");
            $request->authorization_basic( $login, $password );
            my $ua = LWP::UserAgent->new( ssl_opts => {
                verify_hostname => 0,
                SSL_verify_mode => 0x00
            });
            $ua->timeout(15);
            my $response = $ua->request($request);
            if($response->{"_rc"} == 200) {
                $RC = 1;
                $self->{active} = "$umpAddr";
                last;
            }
        }
    }
    return $RC;
}

sub isConnected {
    my ($self) = @_;
    return defined($self->{active}) ? 1 : 0;
}

1;
