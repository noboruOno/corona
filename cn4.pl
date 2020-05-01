#!/user/bin/perl

use strict;
use POSIX qw(strftime);

if ($#ARGV != 1) {
	print "usage: cn4.pl <DATA FILE> <ALPHA FILE>\n";
	exit 1;
}

# mhl data
my %data;
my @serDate;

&readData($ARGV[0]);

my $alpharef = &readAlpha($ARGV[1]);

# population
my $N = 10000000;

# policy index map
sub getAlpha() {
	my $alpha0 = shift;
	my $ser = shift;
	my $datestr = $serDate[$ser];
	if (defined $datestr && defined $alpharef->{$datestr}) {
		return $alpharef->{$datestr}
	} else {
		return $alpha0;
	}
}

# infection probability. persons/(infected*day) for each policy index.

my $m = 10; # days to detection from infection.
my $n = 14; # days to heal from infection without sickness.
my $o = 21; # days to heal from detection.

my $infected = 5; # daily number of hidden infected in the town. let initial value be 5.
my $c_infected = $infected; # cummulative number of infected persons on this day.

my $rdetection = 0.1; # ratio of illness (and then isolated) to all infected.

my $detected = 0; # daily number of those newly diagnosed positive.
my $c_detected = 0; # cummulative number of detected positive.

my $isolated = 0; # number of isolated persons on the day.
 
my @toBeHealed; # future number of those healed on the day.
my @toBeDetected; # future number of those detedted on the day.
my @toRecover; # future number of those recover on the day.

my $alpha = 0;
my $i = 0; # day
while ($i < 200) {

	# figures of the day

	$alpha = &getAlpha($alpha, $i);
	
	
	$i++;
		
	# mass immunity factor
	my $r = ($N - $c_infected) / $N;
	if ($r < 0) {
		$r = 0;
	}
	
	# today's new infection
	my $infection = $infected * $alpha * $r;
	$infected += $infection;
	$c_infected += $infection;
	
	# number of those expected to be tested and found infected and isolated
	$toBeDetected[$i + $m] = $infection * $rdetection;
	
	# number of those who stay asymptomatic and are axpected to be healed.
	$toBeHealed[$i + $n] = $infection * (1 - $rdetection);

	# today's new detection
	my $detected = 0;
	if (defined $toBeDetected[$i]) {
		$detected = $toBeDetected[$i];
		$c_detected += $detected;
		$infected -= $detected;
		$isolated += $detected;
		$toRecover[$i + $o] = $detected;
	}
	
	# this many infected and not isolated are healed, $n days after infection.
	if (defined $toBeHealed[$i]) {
		$infected -= $toBeHealed[$i];
	}
		
	# exit from isolation
	if (defined $toRecover[$i]) {
		$isolated -= $toRecover[$i];
	}
	
	my $datestr = &serNo2Date($i);
	my $mhl = $data{$datestr};
	if (!defined $mhl) {
		$mhl = "";
	} 
	printf "%5.3f,%d,%s,%s,%d,%d,%d,%d,%d,%6.4f\n",
	 $alpha, $i, $datestr, $mhl, $infected, $detected, $c_detected, $isolated, $c_infected, $r;
}

sub serNo2Date() {
	my $n = shift;
	my $epoch = 1579996800 + $n * 86400;
	my $datestr = strftime("%d/%m/%Y",localtime($epoch));
    return $datestr;            	                 
}

1;

sub readData() {
	my $file = shift;
	
	open HF, $file or die "Can't open data file, $file\n";
	
	my $i = 0;
	while (<HF>) {
		#print;
		if (/^#/) {
			next;
		}
		chomp;
		my @a = split ",";
		$data{$a[0]} = $a[1];
		$serDate[$i] = $a[0];

		$i++;
	}
	close HF;
}

sub readAlpha() {
	my $file = shift;
	
	open HF, $file or die "Can't open alpha file, $file\n";
	my %alpha;
	while (<HF>) {
		if (/^#/) {
			next;
		}
		chomp;
		my @a = split ",", $_;
		$alpha{$a[0]} = $a[1];		
	}
	
	return \%alpha;
}