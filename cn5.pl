#!/user/bin/perl

use strict;
use POSIX qw(strftime);
use Time::Local;

if ($#ARGV != 1) {
	print "usage: cn4.pl <DATA FILE> <ALPHA FILE>\n";
	exit 1;
}

# population
# Japan
my $N = 100000000;
# Tokyo
#my $N = 10000000;

# data number - epoch offset
my $epochOffset;

my $m = 10; # days to detection from infection.
my $n = 14; # days to heal from infection without sickness.
my $o = 28; # days to heal from detection.

my $infected = 50; # daily number of hidden infected in the town. let initial value be 5.
my $c_infected = $infected; # cummulative number of infected persons on this day.

my $rdetection = 0.025; # ratio of illness (and then isolated) to all infected.

my $detected = 0; # daily number of those newly diagnosed positive.


# mhl data
my %data;
my @serDate;

&readData($ARGV[0]);

my $alpharef = &readAlpha($ARGV[1]);

#
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
		
	# mass immunity factor
	my $r = ($N - $c_infected) / $N;
	if ($r < 0) {
		$r = 0;
	}
	
	# today's new infection
	my $infected_0 = $infected;
	my $infection = $infected * $alpha * $r;
	$infected += $infection;
	$c_infected += $infection;
	
	# number of those expected to be tested and found infected and isolated
	$toBeDetected[$i + $m] = $infection * $rdetection;
	
	# number of those who stay asymptomatic and are axpected to be healed.
	$toBeHealed[$i + $n] = $infection * (1 - $rdetection);

	# today's reduction of infected
	my $red = 0;
	
	# today's new detection
	my $detected = 0;
	if (defined $toBeDetected[$i]) {
		$detected = $toBeDetected[$i];
		$c_detected += $detected;
		$infected -= $detected;
		$isolated += $detected;
		$toRecover[$i + $o] = $detected;
		$red += $detected;
	}
	
	# this many infected and not isolated are healed, $n days after infection.
	if (defined $toBeHealed[$i]) {
		$infected -= $toBeHealed[$i];
		$red += $toBeHealed[$i];
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
	
	my $r0 = 0;
	if ($red > 0) {
		$r0 = $alpha * $r / ($red / $infected_0);
	}
	
	printf "%5.3f,%d,%s,%s,%d,%d,%d,%d,%d,%d,%6.4f,%6.4f\n",
	 $alpha, $i, $datestr, $mhl, $infected, $detected, $c_detected, $isolated, $infection, $c_infected, $r,$r0;

	$i++;
}

1;

# 24/01/2020 1579827522
sub serNo2Date() {
	my $n = shift;
	if (defined $serDate[$n]) {
		return $serDate[$n];
	}
	my $epoch = $epochOffset + $n * 86400;
	my $datestr = strftime("%d/%m/%Y",localtime($epoch));
    return $datestr;            	                 
}

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

sub readData() {
	my $file = shift;
	
	open HF, $file or die "Can't open data file, $file\n";
	
	my $i = 0;
	while (<HF>) {
		#print;
		if (/^#/) {
			next;
		}
		if (/population=(\d+) /) {
			$N = $1;
		} elsif (/incubation_period=(\d+) /) {
			$m = $1;
		} elsif (/days_to_heel_1=(\d+) /) {
			$n = $1;
		} elsif (/days_to_heel_2=(\d+) /) {
			$o = $1;
		} elsif (/rate_of_detection=([\d\.]+) /) {
			$rdetection = $1;
		} elsif (/infected=(\d+) /) {
			$infected = $1;
		} else {
			chomp;
			my @a = split ",";
			$data{$a[0]} = $a[1];
			$serDate[$i] = $a[0];
			
			if (!defined $epochOffset) {
				my @b = split "/", $a[0]; 
				$epochOffset = timelocal(0,0,0,$b[0],$b[1]-1,$b[2]);
			}
		}

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