#!/user/bin/perl

use strict;
use POSIX qw(strftime);
use Time::Local;

if ($#ARGV != 1) {
	print "usage: plain.pl <PARAM_FILE> <INFECTION DATA FILE>\n";
	exit 1;
}

# population
# Japan
my $N = 125000000;

# day number - epoch offset
my $epochOffset;

# below are read from <ALPHA FILE>
my $m; # days to detection from infection.
my $n; # days to heal from infection without sickness.
my $o; # days to heal from detection.
my $r; # fraction detection in all infected.

my $infected; # daily number of infected in the town.

my $detected; # daily number of those newly diagnosed positive.
my $c_detected = 0; # cummulative number of detected positive.

# mhl data for daily  $detected
my %data;

# day number - date string table
my @serDate;
my %dateStr2Ser;
my %serVaccinationHash;
my @alpha;
my $alphalast;
# fill %data
# $initial value of $infected is assigned there.
&readData($ARGV[0]);

# cummulative number of infected persons.
my $c_infected = $infected;
# for initial value compensation 
my $infected0 = $infected;

# read assumed ratio of detection.
my $rref = &readparams($ARGV[1]);

#
my $isolated = 0; # number of isolated persons on the day.

# table used to handle time delay
my @infectionlog; # day-infection table;
my @isolationlog;
my @C; # carriers in the town

my $rdetection; # ratio of test positive to infected

# parameters and start up values
=pod
print "m = ", $m, "\n";
print "n = ", $n, "\n";
print "o = ", $o, "\n";
print "r = ", $r, "\n";
print "infected = ", $infected, "\n";
=cut
$rdetection = $r;

my $i = 0; # day
# set up initial status
while ($i < $o) {
	$infectionlog[$i] = 1;
	if ($i>0) {
		$C[$i] = $C[$i-1] + $infectionlog[$i];
	} else {
		$C[$i] = $infectionlog[$i];
	}
	$alpha[$i] = 0.1;
	$i++;
}

my $ilast = 0;
while ($i < 800) {
	
	# figures of today
	
	my $datestr = &serNo2Date($i);

	# observed daily detection is given as dd/mm/yyyy,detection
	my $mhl = $data{$datestr};
	if (!defined $mhl) {
		$infectionlog[$i-$m] = $C[$i-$m]*$alphalast;
		$mhl = $infectionlog[$i-$m]*$rdetection;
		$data{$datestr} = $mhl;
		if ($ilast == 0) {
			$ilast = $i;
		}
	} else {
		$infectionlog[$i-$m] = $mhl / $rdetection;
	}
	
	$alpha[$i-$m] = $infectionlog[$i-$m]/$C[$i-$m];
	
	$C[$i-$m+1] = $C[$i-$m] + $infectionlog[$i-$m] - $mhl - $infectionlog[$i-$n]*(1-$rdetection);
	
	
	#printf("%s,%d,%5.2f\n", $datestr, $mhl, $alpha[$i-$m]);
		
	$i++;
}
=pod
while ($i < $ilast+26) {
	my $datestr = &serNo2Date($i);
	
	$alpha[$i-$m] = $alphalast;
	$infectionlog[$i-$m+1] = $C[$i-$m]*$alphalast;
	$data{$datestr} = $infectionlog[$i-$m+1]*$rdetection;
	if (!defined $infectionlog[$i-$m]) {
		printf '$infectionlog[$i-$m] is undefined. $i=%d, %s\n', $i, $datestr;
	}
	if (!defined $infectionlog[$i-$n]) {
		printf '$infectionlog[$i-$n] is undefined. $i=%d, %s\n', $i, $datestr;
	}
	$C[$i-$m+1] = $C[$i-$m] + $infectionlog[$i-$m+1] - $infectionlog[$i-$m]*$rdetection - $infectionlog[$i-$n]*(1-$rdetection);
	$i++;
}
=cut
for ($i = 0; $i < $ilast+7; $i++) {
	my $datestr = &serNo2Date($i);

	# observed daily detection is given as dd/mm/yyyy,detection
	my $mhl = $data{$datestr};
	if ($i < $ilast - $m) {
		if (defined $alpha[$i]) {
			printf("%s,%d,%5.3f,,,%d %d\n", $datestr, $mhl, $alpha[$i], $C[$i], $infectionlog[$i]);
		} else {
			printf("%s,%d,,\n", $datestr, $mhl);
		}
	} elsif ($i < $ilast) {
		if (defined $alpha[$i]) {
			printf("%s,%d,,,%5.3f,%d %d\n", $datestr, $mhl, $alpha[$i], $C[$i], $infectionlog[$i]);
		} else {
			printf("%s,%d,,\n", $datestr, $mhl);
		}		
	} else {
		if (defined $alpha[$i] && defined $C[$i]) {
			if (defined $infectionlog[$i]) {
				printf("%s,,,%d,%5.3f,%d %d\n", $datestr, $mhl, $alpha[$i], $C[$i], $infectionlog[$i]);
			} else {
				printf("%s,,,%d,%5.3f,%d %d\n", $datestr, $mhl, $alpha[$i], $C[$i], 0);
			}
		} else {
			printf("%s,,,%d,,\n", $datestr, $mhl);
		}
		
	}
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

=pod
# simulation parameters
population=125000000 # 100 millions. Population of Japan
incubation_period=5 # days from infection to detection
days_to_heel_1=10    # days to heal without detection and isolation
days_to_heel_2=20    # days to heal in isolation
ratio_of_detection=0.1 # ratio of detected to infected
infected=5      # initial number of infected
=cut
sub readparams() {
	my $pfile = shift;
	open HF, $pfile or die "Can't open parameter file, $pfile\n";
	while(<HF>){
		if ($_=~ /incubation_period=(\d+)/) {
			$m = $1;
		} elsif ($_=~ /days_to_heal_1=(\d+)/) {
			$n = $1;
		} elsif ($_=~ /days_to_heal_2=(\d+)/) {
			$o = $1;
		} elsif ($_=~ /ratio_of_detection=(0\.\d+)/) {
			$r = $1;
		} elsif ($_=~ /infected=(\d+)/) {
			$infected = $1;
		} elsif ($_ =~ /last_alpha=(0\.\d+)/) {
			$alphalast = $1;
		}
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
		if (!defined $a[1]) {
			@a = split " ";
			if (!defined $a[1]) {
				next;
			}
			# 2021/10/4 100
			my @b = split "/", $a[0];
			if (length($b[2]) == 1) {
				$b[2] = "0" . $b[2];
			}
			$a[0] = $b[2] . "/" . $b[1] . "/" . $b[0];
		}
		$data{$a[0]} = $a[1];
		$serDate[$i] = $a[0];
		$dateStr2Ser{$a[0]} = $i;
				
		if (!defined $epochOffset) {
			my @b = split "/", $a[0]; 
			$epochOffset = timelocal(0,0,0,$b[0],$b[1]-1,$b[2]);
		}

		$i++;
	}
	close HF;
}

sub reversedatestr {
	my $str = shift;
	my @a = split "/", $str;
	if (length($a[1]) == 1) {
		$a[1] = "0" . $a[1]
	}
	if (length($a[2]) == 1) {
		$a[2] = "0" . $a[2];
	}
	return $a[2] . "/" . $a[1] . "/" . $a[0]; 
}
