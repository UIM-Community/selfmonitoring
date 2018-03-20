use strict;
use warnings;
use Data::Dumper;
use 5.010;
use Time::Piece;

# Namespace
package perluim::nimdate;

# Nimsoft librairies !
use lib "D:/apps/Nimsoft/perllib";
use lib "D:/apps/Nimsoft/Perl64/lib/Win32API";
use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

sub new {
    my ($class,$dateString) = @_;
    my $this = {
        originalString => $dateString,
        year => undef,
        month => undef,
        day => undef,
        hour => undef,
        min => undef,
        sec => undef,
        diff => undef,
        finalFormat => undef
    };
    my $blessed = bless($this,ref($class) || $class);
    $blessed->parse();
    return $blessed;
}

sub parse {
    my ($self) = @_;
    $self->{year}  = substr($self->{originalString},0,4);
    $self->{month} = substr($self->{originalString},5,2);
    $self->{day}   = substr($self->{originalString},8,2);
    $self->{hour}  = substr($self->{originalString},11,2);
    $self->{min}   = substr($self->{originalString},14,2);
    $self->{sec}   = substr($self->{originalString},17,2);

    my $date1 = sprintf("%02d:%02d:%02d %02d:%02d:%02d",$self->{year},$self->{month},$self->{day},$self->{hour},$self->{min},$self->{sec});
    my $date2;
    {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        $year+= 1900;
        $date2 = sprintf("%02d:%02d:%02d %02d:%02d:%02d",$year,($mon+1),$mday,$hour,$min,$sec);
    }
    my $format = '%Y:%m:%d %H:%M:%S';
    $self->{finalFormat} = "$date2 <> $date1";
    $self->{diff} = Time::Piece->strptime($date2, $format) - Time::Piece->strptime($date1, $format);
}

1;
