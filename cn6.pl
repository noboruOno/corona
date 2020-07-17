#!/user/bin/perl

use strict;
use POSIX qw(strftime);
use Time::Local;

if ($#ARGV != 2) {
	print "usage: cn4.pl <DATA FILE> <ALPHA FILE> <RFILE>\n";
	exit 1;
}

# population
# Japan
my $N = 100000000;

# day number - epoch offset
my $epochOffset;

# below are read from <ALPHA FILE>
my $m; # days to detection from infection.
my $n; # days to heal from infection without sickness.
my $o; # days to heal from detection.

my $infected; # daily number of infected in the town.

my $detected; # daily number of those newly diagnosed positive.
my $c_detected = 0; # cummulative number of detected positive.

# mhl data for daily  $detected
my %data;

# day number - date string table
my @serDate;

# fill %data
# $initial value of $infected is assigned there.
&readData($ARGV[0]);

# read assumed infection probability table.
my $alpharef = &readAlpha($ARGV[1]);

# cummulative number of infected persons.
my $c_infected = $infected;
# for initial value compensation 
my $infected0 = $infected;

# read assumed ratio of detection.
my $rref = &readr($ARGV[2]);

#
my $isolated = 0; # number of isolated persons on the day.

# table used to handle time delay
my @infectionlog; # day-infection table;
my @isolationlog;

my $alpha;
my $rdetection; # ratio of test positive to infected

# parameters and start up values
print "m = ", $m, "\n";
print "n = ", $n, "\n";
print "o = ", $o, "\n";
print "infected = ", $infected, "\n";

my $i = 0; # day
while ($i < 200) {

	# figures of today

	# infection probability
	$alpha = &getAlpha($alpha, $i);

	# detection rate
	$rdetection = &getR($rdetection, $i);
		
	# mass immunity factor
	my $r = ($N - $c_infected) / $N;
	if ($r < 0) {
		$r = 0;
	}
	
	# today's new infection
	my $tni = $infected * $alpha * $r;
	
	$c_infected += $tni;
	# store it for delay handling
	$infectionlog[$i] = $tni; 

	# today's reduction of infected
	my $red = 0;
	
	# today's detection
	my $detected = 0;
	# those infected $m bays before are detected and isolated.
	my $j = $i - $m;
	if ($j >= 0) {
		
		$detected = $rdetection * $infectionlog[$j];
		
		$c_detected += $detected;
		$isolated += $detected;
		$isolationlog[$i] = $detected;
		$red += $detected;
	} else {
		# until $j >= 0, no data to get $detected in this calculation. 
	}
	
	# this many infected and not isolated are healed, $n days after infection.
	$j = $i - $n;
	if ($j >= 0) {
		$red += (1 - $rdetection) * $infectionlog[$j];
	} else {
		# for $j < 0, use the classical recovery rate.
		$red += $infected0/$n;
	}
	
	# today's change in infected.
	$infected = $infected + $tni - $red;
	if ($infected < 0) {
		print "BUG\n";
	}
		
	# count exit from isolation to evaluate number of patients
	my $p = $i - $o;
	if ($p > 0 && defined $isolationlog[$p]) {
		$isolated -= $isolationlog[$p];
	}
	
	# observed daily detection is given as dd/mm/yyyy,detection
	my $datestr = &serNo2Date($i);
	my $mhl = $data{$datestr};
	if (!defined $mhl) {
		$mhl = "";
	}
	
	# my excel needs yyyy/mm/dd for date	
	my $datestr_excel = &reversedatestr($datestr);
	
	printf "%5.3f,%5.3f,%d,%s,%s,%d,%d,%d,%d,%d,%d,%6.4f,%6.4f,%6.4f\n",
	 $alpha, $rdetection, $i, $datestr_excel, $mhl, $infected, $detected, $c_detected, $isolated, $infectionlog[$i], $c_infected, $r, $tni, $red;

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
	my $datestr = &serNo2Date($ser);
	if (defined $datestr && defined $alpharef->{$datestr}) {
		return $alpharef->{$datestr}
	} else {
		return $alpha0;
	}
}

# ditection ratio map
sub getR() {
	my $r0 = shift;
	my $ser = shift;
	my $datestr = $serDate[$ser];
	if (defined $datestr && defined $rref->{$datestr}) {
		return $rref->{$datestr}
	} else {
		return $r0;
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
		chomp;
		my @a = split ",";
		if (!defined $a[0]) {
			next;
		}
		if (!defined $a[1] || $a[1] eq "") {
			next;
		}
		$data{$a[0]} = $a[1];
		$serDate[$i] = $a[0];
		
		if (!defined $epochOffset) {
			my @b = split "/", $a[0]; 
			$epochOffset = timelocal(0,0,0,$b[0],$b[1]-1,$b[2]);
		}

		$i++;
	}
	close HF;
}

sub readAlpha() {
	my $file = shift;
	
	my $first = 1;
	
	open HF, $file or die "Can't open alpha file, $file\n";
	my %alpha;
	while (<HF>) {
		if (/^#/) {
			next;
		}
		chomp;
		my @a = split ",", $_;
		if ($#a == 1) {
			$alpha{$a[0]} = $a[1];
			if ($first) {
				$first = 0;
				$alpha = $a[1];
			}
		} else {
			if ($_ =~ /([\w_]+)=([\d\.]+) /) {
				if ($1 eq "population") {
					$N = $2;
					#print "population=" . $N . "\n";
				} elsif ($1 eq "incubation_period") {
					$m = $2;
					#print "incubation period=" . $m . "\n";
				} elsif ($1 eq "days_to_heel_1") {
					$n = $2;
					#print "days to heal=" . $n . "\n";
				} elsif ($1 eq "days_to_heel_2") {
					$o = $2;
					#print "days of isolation=" . $o . "\n";
				} elsif ($1 eq "infected") {
					$infected = $2;
					#print "initial infected=" . $infected . "\n";
				}
			}
		}		
	}
	
	return \%alpha;
}

sub readr() {
	my $file = shift;
	
	my $first = 1;
	
	open HF, $file or die "Can't open r file, $file\n";
	my %r;
	while (<HF>) {
		if (/^#/) {
			next;
		}
		chomp;
		my @a = split ",", $_;
		if ($#a == 1) {
			$r{$a[0]} = $a[1];
			if ($first) {
				$first = 0;
				$rdetection = $a[1];
			}
		} else {
			# shouldn't be here
		}		
	}
	
	return \%r;
}

sub reversedatestr {
	my $str = shift;
	my @a = split "/", $str;
	return $a[2] . "/" . $a[1] . "/" . $a[0]; 
}