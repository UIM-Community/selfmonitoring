package perluim::log;
use strict;
use warnings;
use File::Copy;
use File::Stat;
use File::Path 'rmtree';
use IO::Handle;

our %Log_level = (
	0 => "[CRITICAL]",
	1 => "[ERROR]   ",
	2 => "[WARNING] ",
	3 => "[INFO]    ",
	4 => "[DEBUG]   ",
	5 => "          "
);

sub new {
    my ($class,$logfile,$loglevel,$logsize,$logrewrite) = @_;
    my $this = {
		logfile => $logfile,
		loglevel => $loglevel || 3,
		logsize => $logsize || 0,
		logrewrite => $logrewrite || 'yes',
		fh => undef
    };
    my $blessed = bless($this,ref($class) || $class);
	my $rV = $blessed->{logrewrite} eq "yes" ? ">" : ">>";
	if($blessed->{logsize} != 0) {
		my $fileSize = (stat $blessed->{logfile})[7];
		if($fileSize >= $blessed->{logsize}) {
			copy("$blessed->{logfile}","_$blessed->{logfile}") or warn "Failed to copy logfile!";
			$rV = ">";
		}
	}
	open ($this->{fh},"$rV","$logfile");
	$blessed->print("New console class created with logfile as => $logfile!",5);
	return $blessed;
}

sub setLevel {
	my ($self,$level) = @_;
	$self->{loglevel} = $level || 5;
}

sub close {
	my ($self) = @_;
	close($self->{fh});
}

sub dateLog {
	my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	my @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timetwoDigits = sprintf("%02d %02d:%02d:%02d",$mday,$hour,$min,$sec);
	return "$months[$mon] $timetwoDigits";
}

sub print {
	my ($self,$logmsg,$loglevel) = @_;
	if(not defined($loglevel)) {
		$loglevel = 3;
	}
	if($loglevel <= $self->{loglevel} || $loglevel == 5 || $loglevel == 4) {
		my $date = dateLog();
		my $filehandler = $self->{fh};
		print $filehandler "$date $Log_level{$loglevel} - $logmsg\n";
		print "$date $Log_level{$loglevel} - $logmsg\n";
		$filehandler->autoflush;
	}
}

sub cleanDirectory {
	my ($self,$directory,$maxAge) = @_;

	opendir(DIR,"$directory");
	my @directory = readdir(DIR);
	my @removeDirectory = ();
	foreach my $file (@directory) {
		next if ($file =~ m/^\./);
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$directory/$file");
		push(@removeDirectory,$file) if(time() - $ctime > $maxAge);
	}

	foreach(@removeDirectory) {
		$self->print("Remove old directory $directory => $_",2);
		rmtree("$directory/$_");
	}
}

sub finalTime {
	my ($self,$timer) = @_;
	my $FINAL_TIME  = sprintf("%.2f", time() - $timer);
    my $Minute      = sprintf("%.2f", $FINAL_TIME / 60);
	$self->print('---------------------------------------',5);
    $self->print("Execution time = $FINAL_TIME second(s) [$Minute minutes]!",5);
	$self->print('---------------------------------------',5);
}

sub copyTo {
	my ($self,$path) = @_;
	copy("$self->{logfile}","$path/$self->{logfile}") or warn "Failed to copy logfile!";
}

1;
